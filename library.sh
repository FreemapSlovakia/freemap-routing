#!/bin/bash
# library file for sh scripts

if [ `ps ax| grep freemap-routing/do.sh | grep bash | grep -v grep | wc -l` -gt 2 ]; then
 echo "script already running `ps ax| grep freemap-routing/do.sh|grep -v grep `";
 exit;
fi


dbname='mapnik';
prefix='osrm_osm';
datadir='/home/ssd/osrm'
osrmdir='/home/vseobecne/ine/osrmv5'
planetdir='/home/extra/tmp'

small=1000

update_planet() {
	cd $planetdir
	/usr/bin/pyosmium-up-to-date -v --server https://planet.osm.org/replication/day/ planet-latest.osm.pbf
}

upgrade_osrm() {
	profile=$1;
	f="bigslovakia"
	if [ "$profile" = "test" ]; then 
		f="bratislava";
	fi
	echo $profile $f
	cd $osrmdir
	out="$out,$profile profile $f:\t`date`"
	mkdir -p $datadir/tmp-$profile;
	if [ ! -r $datadir/tmp-$profile/$f.pbf ]; then
		cp $datadir/$f.pbf $datadir/tmp-$profile/
	fi
	osrm-extract -p oma-$profile.lua --small-component-size $small $datadir/tmp-$profile/$f.pbf && osrm-contract $datadir/tmp-$profile/$f.osrm && rm $datadir/$profile/* && mv $datadir/tmp-$profile/$f.osrm* $datadir/$profile/ && cp -f /usr/local/bin/osrm-routed /usr/local/bin/osrm-routed-$profile && killall osrm-routed-$profile
	if [ $? -ne 0 ]; then exit; fi
	stat -c %y $datadir/$profile/$f.osrm |sed 's/\..*//' > /home/izsk/weby/epsilon.sk/routing/last-mod-$profile
    rm $datadir/tmp-$profile/*pbf
	echo 'ok'
	# copy do live server
	scp $datadir/$profile/* 10.9.0.1:$datadir/tmp-$profile/
	scp /usr/local/bin/osrm-routed-$profile 10.9.0.1:
	ssh 10.9.0.1 "rm $datadir/$profile/* && mv $datadir/tmp-$profile/* $datadir/$profile/ && cp -f ~/osrm-routed-$profile /usr/local/bin/ && killall osrm-routed-$profile";
	oma f epsilon.sk/routing
}

SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

cp *lua $osrmdir
cp $osrmdir/osrm-backend/profiles/car.lua $osrmdir/oma-car.lua
cp $osrmdir/oma-foot.lua $osrmdir/oma-test.lua

crop_bigslovakia() {
	bbox=` echo "select concat('', round(st_xmin(w)::numeric,3), ',', round(st_ymin(w)::numeric,3), ',', round(st_xmax(w)::numeric,3), ',', round(st_ymax(w)::numeric,3)) from (select st_collect(geometry(p)) as w from t_elevation) as t ;" | psql -t $dbname`
	rm $datadir/bigslovakia.pbf
	osmium extract -b $bbox $planetdir/planet-latest.osm.pbf -o $datadir/bigslovakia.pbf
	osmium fileinfo --no-progress -e $datadir/bigslovakia.pbf |grep Last| sed 's/.*: //' > /home/izsk/weby/epsilon.sk/routing/last-mod-data
}

test_file() {
	rm $datadir/bratislava.pbf
	osmium extract -b 16.9,47.96,17.33,48.3 $datadir/bigslovakia.pbf -o $datadir/bratislava.pbf
}

postgis_import() {
	out="$out,import into postgis: `date`"
	osm2pgsql --create --slim --latlong --style osrm.style --database $dbname --prefix $prefix $datadir/bigslovakia.pbf > /dev/null 2>&1
	echo "SELECT 'vacuum analyze ' || table_name ||';' FROM information_schema.tables WHERE table_name like '${prefix}_%' limit 20" | psql -t $dbname| psql -q $dbname
	# highways that are defined only by relation tags
	echo "select 'route_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', highway, '\"' ), ', ') || '};' from (select highway,unnest(parts) as parts from (select osm_id, highway from ${prefix}_polygon where highway is not null union select osm_id, highway from ${prefix}_line where highway is not null) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t;" | psql -t $dbname > $osrmdir/route_rels.lua
	# bike routes to avoid addfmreltags
	echo "select 'bicycle_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', name, '\"' ), ', ') || '};' from ( select first(name order by dlzka desc) as name, parts from (select name,unnest(parts) as parts, dlzka from (select osm_id, replace(name, '\"', '') as name, round(st_length(way::geography)) as dlzka from ${prefix}_line where route in ('bicycle','mtb' )) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t group by parts) as tt ;" | psql -t $dbname >> $osrmdir/route_rels.lua
	echo "select 'foot_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', colour, '\"' ), ', ') || '};' from ( select first(colour order by col2 asc) as colour, parts from (select unnest(parts) as parts, case when colour is not null then colour else 'other' end as colour, col2 from (select osm_id, colour,  case when colour='red' then 1 when colour = 'blue' then 2 when colour='green' then 3 else 4 end as col2 from ${prefix}_line where route in ('hiking','foot' )) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t group by parts) as tt ;" | psql -t $dbname >> $osrmdir/route_rels.lua
	echo "select 'public_transport_ways={'|| string_agg(distinct concat('[', parts::text, ']=true' ), ', ') || '};' from (select unnest(parts) as parts from (select osm_id from ${prefix}_line where route in ('bus','trolleybus')) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t;" | psql -t $dbname >> $osrmdir/route_rels.lua
	cp *lua $osrmdir/
	echo "delete from ${prefix}_line where highway not in ('motorway','motorway_link','trunk','trunk_link','primary','primary_link','secondary','secondary_link', 'tertiary','tertiary_link') or \"natural\" != 'tree_row'" |psql $dbname
	echo "delete from ${prefix}_line where highway is null and \"natural\" is null" | psql $dbname
	echo "delete from ${prefix}_polygon where osm_id not in (select osm_id from ${prefix}_polygon where landuse in ('industrial', 'garages', 'construction','brownfield','landfill', 'quary',  'village_green','grass','meadow', 'forest', 'vineyard', 'orchard') or \"natural\" in ('wood') or leisure in ('park') )" |psql $dbname
	vacuumdb --full -t ${prefix}_line -t ${prefix}_polygon $dbname
}

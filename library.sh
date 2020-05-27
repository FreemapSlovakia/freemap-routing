#!/bin/bash
# library file for sh scripts

if [ `ps ax| grep freemap-routing/do.sh | grep bash | grep -v grep | wc -l` -gt 2 ]; then
 echo "script already running `ps ax| grep freemap-routing/do.sh|grep -v grep `";
 exit;
fi


dbname='mapnik';
prefix='osrm_osm';
if [ `hostname` == "freemap-ng" ]; then
	datadir='/home/freemap/routing/data'; osrmdir='/home/ssd/osrm/osrm';
else
	datadir='/home/ssd/osrm/data'; osrmdir='/home/vseobecne/ine/osrmv5'
fi

planetdir='/home/ssd/osrm'
f='bigslovakia'

export osrmdir;

small=1000

update_planet() {
	cd $planetdir
	rm tmp*pbf
	/usr/bin/pyosmium-up-to-date -v --server https://planet.openstreetmap.org/replication/hour/ planet-latest.osm.pbf
	rm tmp*pbf
}

upgrade_remote() {
	profile=$1;
	# copy do live server
	if [ -z "$2" ]; then server='routing.epsilon.sk';
	else server=$2;
	fi
	echo "remote $profile $server -$2-";
	ssh -q $server "mkdir -p $planetdir/$profile/; mkdir -p $planetdir/tmp-$profile/";
    scp -q -l 2900 $planetdir/$profile/* $server:$planetdir/tmp-$profile/
    if [ $? -ne 0 ]; then return 1; fi
    scp -q /usr/local/bin/osrm-routed-$profile $server:
    if [ $? -ne 0 ]; then return 1; fi
    ssh -q $server "rm $planetdir/$profile/* && mv $planetdir/tmp-$profile/* $planetdir/$profile/ && cp -f ~/osrm-routed-$profile /usr/local/bin/ && pkill -f osrm-routed-$profile";
    oma f epsilon.sk/routing
}

upgrade_local() {
	profile=$1;
	#f='bigslovakia';
	a=osrm-routed-$profile
	touch $planetdir/$profile/dummy
	rm $planetdir/$profile/* && mv $planetdir/tmp-$profile/*.osrm* $planetdir/$profile/ && sudo -u root /usr/local/bin/osrm-upgrade-profile $profile
	#${a:0:15}
	if [ $? -ne 0 ]; then return 1; fi
	osmium fileinfo --no-progress -e $planetdir/tmp-$profile/$f.pbf |grep Last| sed 's/.*: //' > $datadir/last-mod-$profile && rm $planetdir/tmp-$profile/*pbf
}

upgrade_osrm() {
	profile=$1;
	echo "doing profile $profile";
	cd $osrmdir
	out="$out,$profile profile $f:\t`date`"
	mkdir -p $planetdir/tmp-$profile; mkdir -p $planetdir/$profile ;
	if [ ! -r "$planetdir/tmp-$profile/$f.pbf" ]; then
		cp $datadir/$f.pbf $planetdir/tmp-$profile/
	fi
	osrm-extract --verbosity ERROR -t 3 -p oma-$profile.lua --small-component-size $small $planetdir/tmp-$profile/$f.pbf && osrm-contract --verbosity ERROR -t 3 $planetdir/tmp-$profile/$f.osrm && upgrade_local $profile
	if [ $? -ne 0 ]; then return 1; fi
	upgrade_remote $profile $2
}

cp *lua $osrmdir

crop_bigslovakia() {
	touch $datadir/tmp/carslovakia.pbf
	bbox=` echo "select concat('', round(st_xmin(w)::numeric,3), ',', round(st_ymin(w)::numeric,3), ',', round(st_xmax(w)::numeric,3), ',', round(st_ymax(w)::numeric,3)) from (select geometry(st_buffer(geography(box2d(st_collect(geometry(p)))), 295000)) as w from t_elevation) as t;" | psql -t $dbname` && rm $datadir/tmp/carslovakia.pbf && osmium extract -b $bbox $planetdir/planet-latest.osm.pbf -o $datadir/tmp/carslovakia.pbf
	bbox=` echo "select concat('', round(st_xmin(w)::numeric,3), ',', round(st_ymin(w)::numeric,3), ',', round(st_xmax(w)::numeric,3), ',', round(st_ymax(w)::numeric,3)) from (select geometry(st_buffer(geography(box2d(st_collect(geometry(p)))), 1000)) as w from t_elevation) as t;" | psql -t $dbname` && rm $datadir/bigslovakia.pbf && osmium extract -b $bbox $datadir/tmp/carslovakia.pbf -o $datadir/bigslovakia.pbf
	osmium fileinfo --no-progress -e $datadir/bigslovakia.pbf |grep Last| sed 's/.*: //' > $datadir/last-mod-data
	if [ ! -s $datadir/last-mod-data ]; then
		echo "empty bigslovakia"
		exit;
	fi
}

crop_freemap() {
	cd $datadir
	osmium extract -p /home/freemap/freemap-mapnik/limit.geojson $planetdir/planet-latest.osm.pbf -o bigslovakia2.pbf && mv bigslovakia2.pbf bigslovakia.pbf
	rm bigslovakia2.pbf
	osmium fileinfo --no-progress -e $datadir/bigslovakia.pbf |grep Last| sed 's/.*: //' > /home/freemap/routing/last-mod-data
	if [ ! -s /home/freemap/routing/last-mod-data ]; then
		echo "empty bigslovakia"
		exit;
	fi
}

crop_slovakia() {
	# mimic behaviour of download.geofabric
	cd $datadir
	#wget http://download.geofabrik.de/europe/slovakia.poly
	mv slovakia.pbf slovakia.pbf-old
	osmium extract -p $SCRIPTPATH/slovakia.poly bigslovakia.pbf -o slovakia.pbf
}
crop_oma() {
	# crop pbf for oma.sk
	cd $datadir
	mv oma.pbf oma.pbf-old
	osmium extract -p $SCRIPTPATH/oma.poly bigslovakia.pbf -o oma.pbf
}

crop_bikesharing() {
	cd $datadir
	echo '{"type": "Feature","properties": {"name":"world bikesharing"}, "geometry": ' > bikesharing.json
	echo "select st_asgeojson(st_union(w)) from (select geometry(st_buffer(geography(box2d(st_collect(geometry(p)))), 4000)) as w from t_elevation union select st_union(geometry(st_buffer(way, 1000))) from bikesharing_stations) as a" | psql -tA $dbname >> bikesharing.json
	echo "}" >> bikesharing.json
}

test_file() {
	rm $datadir/bratislava.pbf
	osmium extract -b 16.9,47.96,17.33,48.3 $datadir/bigslovakia.pbf -o $datadir/bratislava.pbf
}

postgis_import() {
	out="$out,import into postgis: `date`"
	osm2pgsql --create --slim --latlong --style osrm.style --database $dbname --prefix $prefix $datadir/bigslovakia.pbf > /dev/null #2>&1
	echo "SELECT 'vacuum analyze ' || table_name ||';' FROM information_schema.tables WHERE table_name like '${prefix}_%' limit 20" | psql -t $dbname| psql -q $dbname
	# highways that are defined only by relation tags
	echo "select 'route_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', highway, '\"' ), ', ') || '};' from (select highway,unnest(parts) as parts from (select osm_id, highway from ${prefix}_polygon where highway is not null union select osm_id, highway from ${prefix}_line where highway is not null) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t;" | psql -t $dbname > $osrmdir/route_rels.lua
	# bike routes to avoid addfmreltags
	echo "select 'bicycle_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', name, '\"' ), ', ') || '};' from ( select first(name order by dlzka desc) as name, parts from (select name,unnest(parts) as parts, dlzka from (select osm_id, replace(name, '\"', '') as name, round(st_length(way::geography)) as dlzka from ${prefix}_line where route in ('bicycle','mtb' )) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t group by parts) as tt ;" | psql -t $dbname >> $osrmdir/route_rels.lua
	echo "select 'foot_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', colour, '\"' ), ', ') || '};' from ( select first(colour order by col2 asc) as colour, parts from (select unnest(parts) as parts, case when colour is not null then colour else 'other' end as colour, col2 from (select osm_id, colour,  case when colour='red' then 1 when colour = 'blue' then 2 when colour='green' then 3 else 4 end as col2 from ${prefix}_line where route in ('hiking','foot' )) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t group by parts) as tt ;" | psql -t $dbname >> $osrmdir/route_rels.lua
	echo "select 'public_transport_ways={'|| string_agg(distinct concat('[', parts::text, ']=true' ), ', ') || '};' from (select unnest(parts) as parts from (select osm_id from ${prefix}_line where route in ('bus','trolleybus')) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t;" | psql -t $dbname >> $osrmdir/route_rels.lua
	cp *lua $osrmdir/
	# in park
	echo "drop table if exists ${prefix}_t_in_park; create table ${prefix}_t_in_park as select case when landuse in ('industrial', 'garages', 'construction','brownfield','landfill', 'quary') then -1 when landuse in ('village_green','grass','meadow') then 0.7 else 1 end as coef, st_makevalid(way)::geography as way from ${prefix}_polygon where landuse in ('industrial', 'garages', 'construction','brownfield','landfill', 'quary', 'village_green','grass','meadow', 'forest', 'vineyard', 'orchard') or \"natural\" in ('wood') or leisure in ('park'); " |psql $dbname
	# major roads
	echo "drop table if exists ${prefix}_t_major; create table ${prefix}_t_major as select case when highway in ('motorway','motorway_link','trunk','trunk_link','primary','primary_link') then 2.0 when highway in ('secondary','secondary_link', 'tertiary','tertiary_link') then 1.5 when  \"natural\" = 'tree_row' then -1.0 end as coef, way::geography as way from ${prefix}_line where highway in ('motorway','motorway_link','trunk','trunk_link','primary','primary_link','secondary','secondary_link', 'tertiary','tertiary_link') and tunnel is null or \"natural\" = 'tree_row';" |psql $dbname
	# view places...
	echo "drop table if exists ${prefix}_t_nature; create table ${prefix}_t_nature as select way from poi where typy && '{pramen,vodopad,jaskyna,prepadlina,vrch,sedlo,kamen,vyhlad}';" | psql $dbname
	for t in in_park major nature; do
        echo "create index on ${prefix}_t_$t using gist(way); analyze ${prefix}_t_$t;" |psql $dbname
	done
}

no_srtm_data() {
	# lon je x
	from="from (select geometry(st_buffer(geography(box2d(st_collect(geometry(p)))), 1000)) as w from t_elevation) as t"
	func1=`echo "select concat('if segment.source.lon < ', round(st_xmin(w)::numeric,3), ' or segment.target.lon < ', round(st_xmin(w)::numeric,3), ' then return true; end;' ) $from;" | psql -At $dbname`
	func2=`echo "select concat('if segment.source.lon > ', round(st_xmax(w)::numeric,3), ' or segment.target.lon > ', round(st_xmax(w)::numeric,3), ' then return true; end;' ) $from;" | psql -At $dbname`
	func3=`echo "select concat('if segment.source.lat < ', round(st_ymin(w)::numeric,3), ' or segment.target.lat < ', round(st_ymin(w)::numeric,3), ' then return true; end;' ) $from;" | psql -At $dbname`
    func4=`echo "select concat('if segment.source.lat > ', round(st_ymax(w)::numeric,3), ' or segment.target.lat > ', round(st_ymax(w)::numeric,3), ' then return true; end;' ) $from;" | psql -At $dbname`

	echo "$func1  $func2  $func3  $func4  return false; ";
}

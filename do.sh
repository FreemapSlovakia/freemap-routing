#!/bin/bash
# prefix used by osm2pgsql --slim

if [ `ps ax| grep freemap-routing/do.sh | grep bash | grep -v grep | wc -l` -gt 2 ]; then
 echo "script already running `ps ax| grep freemap-routing/do.sh|grep -v grep `";
 exit;
fi


dbname='mapnik';
prefix='osrm_osm';
datadir='/home/ssd/osrm'
osrmdir='/home/vseobecne/ine/osrmv5'

upgrade_osrm() {
	profile=$1;
	f="bigslovakia"
	if [ "$profile" = "test" ]; then 
		f="bratislava";
	fi
	echo $profil $f
	cd $osrmdir
	out="$out,$profile profile $f:\t`date`"
	mkdir -p $datadir/tmp-$profile; cp $datadir/$f.pbf $datadir/tmp-$profile/
#	STXXLCFG="stxxl-$profile"; echo "disk=/tmp/stxxl-$profile,2G,memory" > $STXXLCFG
	osrm-extract -p oma-$profile.lua $datadir/tmp-$profile/$f.pbf && osrm-contract $datadir/tmp-$profile/$f.osrm && rm $datadir/$profile/* && mv $datadir/tmp-$profile/$f.osrm* $datadir/$profile/ && cp -f /usr/local/bin/osrm-routed /usr/local/bin/osrm-routed-$profile && killall osrm-routed-$profile
	if [ $? -ne 0 ]; then exit; fi
	stat -c %y $datadir/$profile/$f.osrm |sed 's/\..*//' > /home/izsk/weby/epsilon.sk/routing/last-mod-$profile
    rm $datadir/tmp-$profile/*pbf
	echo 'ok'
	# copy do live server
	scp $datadir/$profile/* 10.9.0.1:$datadir/tmp-$profile/
	scp /usr/local/bin/osrm-routed-$profile 10.9.0.1:
	ssh 10.9.0.1 "rm $datadir/$profile/* && mv $datadir/tmp-$profile/* $datadir/$profile/ && cp -f ~/osrm-routed-$profile /usr/local/bin/ && killall osrm-routed-$profile";
}

date
out=" starting:\t`date`"

SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

cp *lua $osrmdir
cp $osrmdir/oma-foot.lua $osrmdir/oma-test.lua

#upgrade_osrm car; exit;
#upgrade_osrm test; exit;


# todo: preferuj cervenu pred modrou
#echo "select 'bicycle_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', name, '\"' ), ', ') || '};' from ( select first(name order by dlzka desc) as name, parts from (select name,unnest(parts) as parts, dlzka from (select osm_id, replace(name, '\"', '') as name, round(st_length(way)) as dlzka from trasy where typ='cyklotrasa' ) as f,${prefix}rels where osm_id*-1 = id and osm_id < 0) as t group by parts) as tt ;" | psql -t mapnik > tmp/route_bicycle.lua

#echo "select 'crossings={' || string_agg(distinct concat('[', id::text, '] = TRUE'), ', ') || '};' from (select nodes.id, (unnest(ways.tags)) as tags from fresh_osm_nodes as nodes, fresh_osm_ways as ways where nodes.tags && array['crossing'] and ways.nodes && array[nodes.id]) as t where array[tags] && array['primary','secondary','tertiary'] ;"| psql -t mapnik > tmp/crossing.lua

d=`date --date="today" +"%g%m%d"`
scp -p -P 21122 92.240.244.41:/freemap/datastore.fm/httpd/dev/tmp/osmosis/planet/bigslovakia$d.pbf $datadir/ttt.pbf
stat -c %y $datadir/ttt.pbf |sed 's/\..*//' > /home/izsk/weby/epsilon.sk/routing/last-mod-data

bbox=`echo "select concat('bottom=', round(st_ymin(w)::numeric,3), ' left=', round(st_xmin(w)::numeric,3), ' top=', round(st_ymax(w)::numeric,3), ' right=', round(st_xmax(w)::numeric,3)) from (select st_collect(geometry(p)) as w from t_elevation) as t ;" | psql -t $dbname`
osmosis --read-pbf file="$datadir/ttt.pbf" --bounding-box $bbox --write-pbf file="$datadir/bigslovakia.pbf"
#rm $datadir/ttt.pbf
osmosis --read-pbf file="$datadir/bigslovakia.pbf" --bounding-box bottom=47.96 left=16.9 top=48.3 right=17.33 --write-pbf file="$datadir/bratislava.pbf"

out="$out,import into postgis: `date`"
osm2pgsql --create --slim --latlong --style osrm.style --database $dbname --prefix $prefix $datadir/ttt.pbf > /dev/null 2>&1
echo "SELECT 'vacuum analyze ' || table_name ||';' FROM information_schema.tables WHERE table_name like '$prefix_%' limit 20" | psql -t $dbname| psql -q $dbname

# highways that are defined only by relation tags
echo "select 'route_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', highway, '\"' ), ', ') || '};' from (select highway,unnest(parts) as parts from (select osm_id, highway from ${prefix}_polygon where highway is not null union select osm_id, highway from ${prefix}_line where highway is not null) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t;" | psql -t $dbname > $osrmdir/route_rels.lua
# bike routes to avoid addfmreltags
echo "select 'bicycle_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', name, '\"' ), ', ') || '};' from ( select first(name order by dlzka desc) as name, parts from (select name,unnest(parts) as parts, dlzka from (select osm_id, replace(name, '\"', '') as name, round(st_length(way::geography)) as dlzka from ${prefix}_line where route in ('bicycle','mtb' )) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t group by parts) as tt ;" | psql -t $dbname >> $osrmdir/route_rels.lua
echo "select 'foot_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', colour, '\"' ), ', ') || '};' from ( select first(colour order by col2 asc) as colour, parts from (select unnest(parts) as parts, case when colour is not null then colour else 'other' end as colour, col2 from (select osm_id, colour,  case when colour='red' then 1 when colour = 'blue' then 2 when colour='green' then 3 else 4 end as col2 from ${prefix}_line where route in ('hiking','foot' )) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t group by parts) as tt ;" | psql -t $dbname >> $osrmdir/route_rels.lua

echo "select 'public_transport_ways={'|| string_agg(distinct concat('[', parts::text, ']=true' ), ', ') || '};' from (select unnest(parts) as parts from (select osm_id from ${prefix}_line where route in ('bus','trolleybus')) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t;" | psql -t $dbname >> $osrmdir/route_rels.lua

# cat main-roads.sql | psql -q $dbname # hopefully obsolete

cp *lua $osrmdir

cd $osrmdir
cp osrm-backend/profiles/car.lua oma-car.lua

cp oma-foot.lua oma-test.lua
upgrade_osrm test

upgrade_osrm bicycle
upgrade_osrm car
upgrade_osrm foot

out="$out,end: `date`"
echo $out
echo $out | sed 's/,/\n/g'

#!/bin/sh
date
out="starting: `date`"
cd /home/vseobecne/projekty/osm/oma/odberatelia/routing
# prefix used by osm2pgsql --slim
dbname='mapnik';
prefix='osrm_osm';
datadir='/home/zaloha/db/tmp'
osrmdir='/home/vseobecne/ine/osrmv5'

# todo: preferuj cervenu pred modrou
#echo "select 'bicycle_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', name, '\"' ), ', ') || '};' from ( select first(name order by dlzka desc) as name, parts from (select name,unnest(parts) as parts, dlzka from (select osm_id, replace(name, '\"', '') as name, round(st_length(way)) as dlzka from trasy where typ='cyklotrasa' ) as f,${prefix}rels where osm_id*-1 = id and osm_id < 0) as t group by parts) as tt ;" | psql -t mapnik > tmp/route_bicycle.lua

#echo "select 'crossings={' || string_agg(distinct concat('[', id::text, '] = TRUE'), ', ') || '};' from (select nodes.id, (unnest(ways.tags)) as tags from fresh_osm_nodes as nodes, fresh_osm_ways as ways where nodes.tags && array['crossing'] and ways.nodes && array[nodes.id]) as t where array[tags] && array['primary','secondary','tertiary'] ;"| psql -t mapnik > tmp/crossing.lua


cp *lua $osrmdir
out="$out\nstarting to download: `date`"
d=`date --date="today" +"%g%m%d"`
scp -p -P 21122 92.240.244.41:/freemap/datastore.fm/httpd/dev/tmp/osmosis/planet/bigslovakia$d.pbf $datadir/bigslovakia.pbf

out="$out\nimport into postgis: `date`"
osm2pgsql --create --slim --latlong --style osrm.style --database $dbname --prefix "osrm_osm" --multi-geometry $datadir/bigslovakia.pbf > /dev/null 2>&1

echo "SELECT 'vacuum analyze ' || table_name ||';' FROM information_schema.tables WHERE table_name like '$prefix_%' limit 20" | psql -t $dbname| psql -q $dbname

out="$out\ncreate postgis tables: `date`"
# highways that are defined only by relation tags
echo "select 'route_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', highway, '\"' ), ', ') || '};' from (select highway,unnest(parts) as parts from (select osm_id, highway from ${prefix}_polygon where highway is not null union select osm_id, highway from ${prefix}_line where highway is not null) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t;" | psql -t $dbname > $osrmdir/route_rels.lua
# bike routes to avoid addfmreltags
echo "select 'bicycle_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', name, '\"' ), ', ') || '};' from ( select first(name order by dlzka desc) as name, parts from (select name,unnest(parts) as parts, dlzka from (select osm_id, replace(name, '\"', '') as name, round(st_length(way::geography)) as dlzka from ${prefix}_line where route in ('bicycle','mtb' )) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t group by parts) as tt ;" | psql -t $dbname >> $osrmdir/route_rels.lua
echo "select 'foot_ways={' || string_agg(distinct concat('[', parts::text, ']=\"', colour, '\"' ), ', ') || '};' from ( select first(colour order by col2 asc) as colour, parts from (select unnest(parts) as parts, case when colour is not null then colour else 'other' end as colour, col2 from (select osm_id, colour,  case when colour='red' then 1 when colour = 'blue' then 2 when colour='green' then 3 else 4 end as col2 from ${prefix}_line where route in ('hiking','foot' )) as f,${prefix}_rels where osm_id*-1 = id and osm_id < 0) as t group by parts) as tt ;" | psql -t $dbname >> $osrmdir/route_rels.lua

# cat main-roads.sql | psql -q $dbname # hopefully obsolete

osmosis --read-pbf file="$datadir/bigslovakia.pbf" --bounding-box bottom=47.96 left=16.9 top=48.3 right=17.33 --write-pbf file="$datadir/bratislava.pbf"

f="bigslovakia"
cd $osrmdir
echo "FOOT routing"
out="$out\nfoot profile: `date`"
f="bratislava";
rm $datadir/$f.osrm*
osrm-extract -p oma-foot.lua $datadir/$f.pbf && osrm-contract $datadir/$f.osrm && mv $datadir/$f.osrm* $datadir/osrm && killall osrm-routed

echo "BICYCLE routing"
out="$out\nbicycle profile: `date`"

f="bigslovakia"
rm $datadir/$f.osrm*
osrm-extract -p oma-bicycle.lua $datadir/$f.pbf && osrm-contract $datadir/$f.osrm && mv $datadir/$f.osrm* $datadir/bicycle-osrm/
killall osrm-routed


#    while :; do osrm-routed /home/zaloha/db/tmp/osrm/bigslovakia-fmrel.osrm ; done 

#    while :; do osrm-routed -p 5001 /home/zaloha/db/tmp/bicycle-osrm/bigslovakia-fmrel.osrm ; done 

#export JAVACMD_OPTIONS="-Djava.io.tmpdir=. -Xms2280m -Xmx5560m"
#osmosis --read-pbf file="/home/zaloha/db/tmp/bigslovakia-fmrel.pbf" --bounding-box bottom=47.96 left=16.9 top=48.3 right=17.33 --write-pbf file="/home/zaloha/db/tmp/bratislava.osm.pbf" > /dev/null
#osrm-extract -p foot.lua /home/zaloha/db/tmp/bratislava.osm.pbf >/dev/null
#osrm-contract /home/zaloha/db/tmp/bratislava.osrm>/dev/null


#killall osrm-routed
out="$out\nend: `date`"
echo $out

#!/bin/bash
SCRIPT=$(readlink -f "$0"); SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

. $SCRIPTPATH/library.sh

datadir='/home/freemap/routing/data'; osrmdir='/home/ssd/osrm/osrm';
upgrade_remote() {
	echo "no remote";
}
cp *lua $osrmdir

date
out=" starting: `date`"

update_planet > /dev/null
#update_planet > /dev/null # just in case, the first one fails


crop_freemap > /dev/null
crop_slovakia > /dev/null

rm $planetdir/tmp-bus/* $planetdir/tmp-train/*
cat $osrmdir/osrm-backend/profiles/car.lua |grep -v area > $osrmdir/oma-car.lua
upgrade_osrm car > /dev/null
upgrade_osrm bus > /dev/null
upgrade_osrm bicycle > /dev/null

if [ -r $datadir/ski-world.pbf ]; then rm $datadir/ski-world.pbf; fi
out="$out,get pistes: `date`"
osmium tags-filter $planetdir/planet-latest.osm.pbf wr/route=ski wr/piste:type wr/aerialway -o $datadir/ski-world.pbf > /dev/null
cp $datadir/ski-world.pbf $planetdir/tmp-ski/bigslovakia.pbf
cp $datadir/ski-world.pbf $planetdir/tmp-nordic/bigslovakia.pbf
ls -lh $planetdir/tmp-nordic/bigslovakia.pbf

small=10
cat master-ski.lua | grep -v 'grep nordic' > $osrmdir/oma-ski.lua
upgrade_osrm ski > /dev/null
cat master-ski.lua | grep -v 'grep piste' > $osrmdir/oma-nordic.lua
upgrade_osrm nordic > /dev/null

small=100
upgrade_osrm train > /dev/null

small=10
upgrade_osrm canoe > /dev/null


# extract borders of europe
rm $datadir/borders*.pbf
osmium tags-filter $planetdir/planet-latest.osm.pbf r/boundary=administrative -o $datadir/borders1.pbf; 
osmium extract $datadir/borders1.pbf -p europe.poly -o $datadir/borders.pbf
rm $datadir/borders1.pbf

out="$out,end: `date`"
#echo $out
echo $out | sed 's/,/\n/g'

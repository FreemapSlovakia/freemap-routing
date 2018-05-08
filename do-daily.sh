#!/bin/bash
SCRIPT=$(readlink -f "$0"); SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

. $SCRIPTPATH/library.sh

date
out=" starting: `date`"

update_planet > /dev/null
update_planet > /dev/null # just in case, the first one fails


crop_bigslovakia > /dev/null
crop_slovakia > /dev/null
cp -p $datadir/slovakia.pbf /home/izsk/bigweby/epsilon/routing
cp -p $datadir/bigslovakia.pbf /home/izsk/bigweby/epsilon/routing


rm $datadir/bikesharing.pbf
osmium extract -p $datadir/bikesharing.json $datadir/planet-latest.osm.pbf -o $datadir/bikesharing.pbf

test_file > /dev/null
cp $datadir/carslovakia.pbf $datadir/tmp-car/bigslovakia.pbf
rm $datadir/tmp-bus/*; rm $datadir/tmp-train/*
upgrade_osrm car > /dev/null
upgrade_osrm bus > /dev/null

if [ -r $datadir/tmp-ski/bigslovakia.pbf ]; then rm $datadir/tmp-ski/bigslovakia.pbf; fi
out="$out,get pistes: `date`"
osmium tags-filter $planetdir/planet-latest.osm.pbf wr/route=ski wr/piste:type wr/aerialway -o $datadir/tmp-ski/bigslovakia.pbf > /dev/null
cp $datadir/tmp-ski/bigslovakia.pbf $datadir/tmp-nordic/bigslovakia.pbf
ls -lh $datadir/tmp-nordic/bigslovakia.pbf

small=10
cat master-ski.lua | grep -v 'grep nordic' > $osrmdir/oma-ski.lua
upgrade_osrm ski > /dev/null
cat master-ski.lua | grep -v 'grep piste' > $osrmdir/oma-nordic.lua
upgrade_osrm nordic > /dev/null

small=100
upgrade_osrm train > /dev/null

out="$out,end: `date`"
#echo $out
echo $out | sed 's/,/\n/g'

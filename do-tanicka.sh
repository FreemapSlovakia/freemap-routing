#!/bin/bash
SCRIPT=$(readlink -f "$0"); SCRIPTPATH=$(dirname "$SCRIPT")

date
out=" starting: `date`"

cd $datadir
rm bigslovakia.pbf
wget -q https://routing.freemap.sk/data/bigslovakia.pbf

cd $SCRIPTPATH
. $SCRIPTPATH/library.sh

crop_slovakia > /dev/null

test_file > /dev/null
rm $planetdir/tmp-bus/* $planetdir/tmp-train/*
cat $osrmdir/osrm-backend/profiles/car.lua |grep -v area > $osrmdir/oma-car.lua
upgrade_osrm bus > /dev/null

small=100
upgrade_osrm train > /dev/null

out="$out,end: `date`"
#echo $out
echo $out | sed 's/,/\n/g'

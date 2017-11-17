#!/bin/bash
SCRIPT=$(readlink -f "$0"); SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

. $SCRIPTPATH/library.sh

date
out=" starting: `date`"

update_planet > /dev/null
crop_bigslovakia > /dev/null
upgrade_osrm car > /dev/null

rm $datadir/tmp-ski/bigslovakia.pbf
out="$out,get pistes: `date`"
osmium tags-filter $planetdir/planet-latest.osm.pbf wr/route=ski wr/piste:type wr/aerialway -o $datadir/tmp-ski/bigslovakia.pbf > /dev/null

small=10
upgrade_osrm ski > /dev/null
small=100
upgrade_osrm train > /dev/null


out="$out,end: `date`"
#echo $out
echo $out | sed 's/,/\n/g'

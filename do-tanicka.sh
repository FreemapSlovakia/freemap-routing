#!/bin/bash
SCRIPT=$(readlink -f "$0"); SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH
. $SCRIPTPATH/library.sh

date
out=" starting: `date`"

cd $datadir
rm bratislava.pbf
wget -q https://routing.freemap.sk/data/bratislava.pbf
mv slovakia.pbf slovakia.pbf-old; wget -O slovakia.pbf -q https://routing.freemap.sk/data/oma.pbf

cd $SCRIPTPATH

#crop_slovakia > /dev/null

# if bigslovakia is big enough

cp $datadir/bratislava.pbf $planetdir/tmp-bus/bigslovakia.pbf
upgrade_osrm bus

small=100
cp $datadir/bratislava.pbf $planetdir/tmp-train/bigslovakia.pbf

upgrade_osrm train > /dev/null

out="$out,end: `date`"
#echo $out
echo $out | sed 's/,/\n/g'

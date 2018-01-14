#!/bin/bash
SCRIPT=$(readlink -f "$0"); SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

. $SCRIPTPATH/library.sh

out=" starting: `date`"

out="$out,get pistes: `date`"

cat master-ski.lua | grep -v 'grep nordic' > $osrmdir/oma-ski.lua
#small=10; upgrade_osrm ski
cp *lua $osrmdir/
cp $osrmdir/oma-foot.lua $osrmdir/oma-test.lua
cp $datadir/bratislava.pbf $datadir/tmp-test/bigslovakia.pbf && upgrade_osrm test
#cp $datadir/bigslovakia.pbf $datadir/tmp-bus/bigslovakia.pbf && upgrade_osrm bus


out="$out,end: `date`"
#echo $out
echo $out | sed 's/,/\n/g'

#!/bin/bash
SCRIPT=$(readlink -f "$0"); SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

. $SCRIPTPATH/library.sh

date
out=" starting:\t`date`"

#download data - done by daily script
# cca 28 hours
postgis_import;
#cp $datadir/bikesharing.pbf $planetdir/tmp-foot/bigslovakia.pbf;
upgrade_osrm foot
# probably there are new data available
cd $SCRIPTPATH
# cca 9 hours
#date; postgis_import; cp $datadir/bikesharing.pbf $planetdir/tmp-bicycle/bigslovakia.pbf; upgrade_osrm bicycle

out="$out,end:\t`date`"
echo $out | sed 's/,/\n/g'

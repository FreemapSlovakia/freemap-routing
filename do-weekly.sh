#!/bin/bash
SCRIPT=$(readlink -f "$0"); SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

. $SCRIPTPATH/library.sh

date
out=" starting:\t`date`"

#download data - done by daily script
# cca 7.5 hours
postgis_import; cp $datadir/bikesharing.pbf $datadir/tmp-bicycle/bigslovakia.pbf; upgrade_osrm bicycle
# probably there are new data available
cd $SCRIPTPATH
# cca 22 hours
postgis_import; cp $datadir/bikesharing.pbf $datadir/tmp-foot/bigslovakia.pbf; upgrade_osrm foot

out="$out,end:\t`date`"
echo $out | sed 's/,/\n/g'

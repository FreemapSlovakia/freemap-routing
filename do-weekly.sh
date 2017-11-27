#!/bin/bash
SCRIPT=$(readlink -f "$0"); SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

. $SCRIPTPATH/library.sh

date
out=" starting:\t`date`"

#download data - done by daily script
postgis_import; upgrade_osrm bicycle
# probably there are new data available
postgis_import; upgrade_osrm foot

out="$out,end:\t`date`"
echo $out | sed 's/,/\n/g'

#!/bin/bash
SCRIPT=$(readlink -f "$0"); SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

. $SCRIPTPATH/library.sh

date
out=" starting:\t`date`"

#download data - done by daily script
postgis_import;
test_file; upgrade_osrm test
upgrade_osrm bicycle
upgrade_osrm foot

out="$out,end:\t`date`"
echo $out | sed 's/,/\n/g'

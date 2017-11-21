#!/bin/bash
SCRIPT=$(readlink -f "$0"); SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

. $SCRIPTPATH/library.sh

out=" starting: `date`"

out="$out,get pistes: `date`"

small=10
upgrade_osrm ski


out="$out,end: `date`"
#echo $out
echo $out | sed 's/,/\n/g'

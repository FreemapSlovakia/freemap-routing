#nejak blbne kopirovanie na freemap, budto na tmp albo z tmp na ostru
#plus treba pouzit  /usr/local/bin/osrm-upgrade-profile foot


#!/bin/bash
SCRIPT=$(readlink -f "$0"); SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

. $SCRIPTPATH/library.sh

date
out=" starting:\t`date`"

#download data - done by daily script
# cca 28 hours
#cp $datadir/bikesharing.pbf $planetdir/tmp-foot/bigslovakia.pbf;

cd $datadir; rm bigslovakia.pbf; wget -q https://routing.freemap.sk/data/bigslovakia.pbf
cd $SCRIPTPATH; postgis_import;

cd $SCRIPTPATH

upgrade_osrm foot routing.epsilon.sk
#upgrade_remote foot routing.freemap.sk
# probably there are new data available
cd $SCRIPTPATH
# cca 9 hours
#date; postgis_import; cp $datadir/bikesharing.pbf $planetdir/tmp-bicycle/bigslovakia.pbf; upgrade_osrm bicycle

out="$out,end:\t`date`"
echo $out | sed 's/,/\n/g'

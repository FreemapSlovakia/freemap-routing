#!/bin/sh
cd /home/vseobecne/projekty/osm/oma/odberatelia/freemap-routing
date
#cat bicycle-functions.sql | psql mapnik

. ./library.sh
postgis_import; 
cp $datadir/bikesharing.pbf $planetdir/tmp-bicycle/bigslovakia.pbf; upgrade_osrm bicycle

cd /home/vseobecne/projekty/osm/oma/odberatelia/freemap-routing
#cat bicycle-post.sql | psql mapnik
date

# freemap-routing
Routing engine used in freemap

## install 
run `upgrade.sh` in your $osrmdir (the last step needs to run as root)
create a PostGIS database, with access to schema public for a user
after you've built the data, run `deploy` from `daemon-scripts` as root (it will install rc script for the daemon)

## build
adapt `do.sh` to download your region from server, like http://download.geofabrik.de



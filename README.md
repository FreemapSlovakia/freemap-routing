# freemap-routing
Routing engine used in freemap. It is a OSRM with custom foot and bicycle profiles. Currently it is available at `http://pesi.routing.epsilon.sk` port 80. 

To use at your website, have a look at https://github.com/perliedman/leaflet-routing-machine/

## install 
- run `upgrade.sh` in your $osrmdir (the last step needs to run as root)
- create a PostGIS database, with access to schema public for a user
- after you've built the data, run `deploy` from `daemon-scripts` as root (it will install rc script for the daemon)
- for your convenience, set up reverse proxy in your http daemon

## build
- adapt `do.sh` to download your region from server, like http://download.geofabrik.de



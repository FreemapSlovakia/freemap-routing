# freemap-routing
Routing engine used in freemap. It is a OSRM with custom foot and bicycle profiles. Demo is available at [freemap.epsilon.sk](http://freemap.epsilon.sk/#page=navigacia&map=C/13/48.13659/17.13172)

Backend is currently available at `http://pesi.routing.epsilon.sk` and `http://mtb-bike.routing.epsilon.sk` port 80. 

To use at your website, have a look at [LRM](https://github.com/perliedman/leaflet-routing-machine/)

## install 
- run `upgrade.sh` in your $osrmdir (the last step needs to run as root)
- create a PostGIS database, with access to schema public for a user
  - create a PostGIS function getz(point), which returns elevation of the point
- after you've built the data, run `deploy` from `daemon-scripts` as root (it will install rc script for the daemon)
- for your convenience, set up reverse proxy in your http daemon

## build
- adapt `do.sh` to download your region from server, like http://download.geofabrik.de
- change directories in `do.sh`

# Features

## profiles
- foot profile: for urban walking and rural hiking
- bicycle: city and trekking bicycle
- car: default OSRM configuration

## common features
- all standard features done by OSRM plus:
- take elevation into account (uphill is slower than downhill; uphill is avoided if possible)
- route over highways that are relations only
- preference of hiking/cycle routes: prefer ways that are a part of relations

## foot profile features
- avoid footways close to major roads (this makes generation of graf data very slow)
- avoid ways in industrial areas
- prefer ways in forrest
- prefer ways close to touristic attractions

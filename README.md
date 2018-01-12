# freemap-routing
Routing engine used in freemap. It is a OSRM with custom foot and bicycle profiles. Homepage is [routing.epsilon.sk](https://routing.epsilon.sk/) and it can be used at [www.freemap.sk](https://www.freemap.sk/?map=10/49.13905/19.58588&layers=T&transport=foot&points=49.10265/18.77563,49.17632/20.13657)

Backend is currently available at `https://routing.epsilon.sk` port 443. 

To use at your website, have a look at [LRM](https://github.com/perliedman/leaflet-routing-machine/)

## install 
- run `upgrade.sh` in your $osrmdir (the last step needs to run as root)
- create a PostGIS database, with access to schema public for a user
  - create a PostGIS function getz(point), which returns elevation of the point
- after you've built the data, run `deploy` from `daemon-scripts` as root (it will install rc script for the daemon)
- for your convenience, set up reverse proxy in your http daemon

## build
- adapt `library.sh` to download your region from server, like http://download.geofabrik.de
- change directories in `library.sh`

# Features

## profiles
- foot profile: for urban walking and rural hiking
- bicycle: city and trekking bicycle
- car: default OSRM configuration
- train, bus: special profiles for public transport routing
- ski: downhill skiing using skilifts, gondolas and pistes
- nordic: nordic skiing on `piste:type=nordic`

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

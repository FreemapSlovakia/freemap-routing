<?php

/* 
 rm mapbox-gl*; wget https://api.tiles.mapbox.com/mapbox-gl-js/v0.45.0/mapbox-gl.js; wget https://api.tiles.mapbox.com/mapbox-gl-js/v0.45.0/mapbox-gl.css
  */
include('/home/izsk/weby/oma.sk/spolocne.php');
include('maps.php');
$typ = getcgi('profil','bike');
$sp = getcgi('speed', 'speed');

echo "<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8' />
    <title>routing $typ $sp</title>
    <meta name='viewport' content='initial-scale=1,maximum-scale=1,user-scalable=no' />
    <script src='mapbox-gl.js'></script>
    <link href='mapbox-gl.css' rel='stylesheet' />
    <style>
        body { margin:0; padding:0; }
        #map { position:absolute; top:0; bottom:0; width:100%; }
    </style>
</head>
<body>

<div id='map'></div>
<script>";

$spee = $$sp;
$speeds = getcgi('speeds', $spee[$typ]['speeds']); if(!is_array($speeds)) $speeds = explode(',', $speeds); 
$colors = getcgi('colors', $spee[$typ]['colors']); if(!is_array($colors)) $colors = explode(',', $colors);
$exclude = getcgi('exclude',''); if(strlen($exclude)>2) $exclude="?exclude=$exclude"; else $exclude='';
$speeds[] = 100000;
$speeds[-1] = 0;
echo 'var simple = {
    "version": 8,
    "sources": {
        "osm": {
            "type": "vector",
            "tiles": ["https://routing.freemap.sk/tile/v1/'.$typ.'/tile({x},{y},{z}).mvt'.$exclude.'"]
        }
    },
    "layers": [
        {
            "id": "background",
            "type": "background",
            "paint": { "background-color": "white" }
		}';
foreach($colors as $id => $col) echo ', {
            "id": "'.$sp.'s < '.$speeds[$id].' and '.$sp.'s >= '.$speeds[$id-1].'", "type": "line", "source": "osm", "source-layer": "speeds",
            "filter": [  "all", [ "==", "$type", "LineString" ], [ "all", [ "<", "'.$sp.'", '.$speeds[$id].' ], [ ">=", "'.$sp.'", '.$speeds[$id-1].' ] ] ],
            "paint": { "line-color": "'.$col.'" }
        }';
echo ']
};

var map = new mapboxgl.Map({
    container: "map",
    style: simple,
    zoom: '.getcgi('zoom',15).',
    center: ['.getcgi('lon',17.1180).', '.getcgi('lat', 48.1451).']
});
';
?>
//map.addControl(new mapboxgl.Navigation());
</script>

</body>
</html>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="sk" lang="sk" dir="ltr">
	<head>
		<title>status routing - &epsilon; epsilon </title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />	
		<link rel="stylesheet" type="text/css" href="https://epsilon.sk/normal.css" />
		<link rel="shortcut icon" href="https://epsilon.sk/favicon.ico" />
</head>
<body>
<h1>status routing.epsilon.sk</h1>
<p><a href='/'>spať</a>, použite na <a href='https://www.freemap.sk/'>www.freemap.sk</a>, (prípadne na <a href='https://freemap.epsilon.sk/#page=navigacia&amp;map=T/11/48.12187/17.20734'>demo</a>), je založené na OSRM a <a href="https://github.com/FreemapSlovakia/freemap-routing">tu sú zdrojové kódy</a></p>
<h2>služby/profily:</h2><ul>
<?php
include('maps.php');

echo '<li>posledné OSM dáta sú z '.file_get_contents('last-mod-data').' (ale niektoré profily môžu byť spracované skôr), <a href="status.php">status servera</a>, dáta sú spracovné za SR a okolie</li>';
foreach($names as $k => $v) echo "<li>$k - $v".(is_array($classes[$k]) ? ' ('.implode($classes[$k], ', ').')':'').", posledné dáta z ".file_get_contents("last-mod-$k")."</li>\n";

echo '</ul>
<h2>Funkčnosť servera</h2><ul>
<li>vzdialenosť v sekundách z BA do Pezinskej baby, BB a KE</li>
';

foreach($speed as $typ => $c) {
	$url="routing.epsilon.sk/table/v1/$typ/17.109404,48.164482;17.18811,48.33229;19.157,48.74;21.27689,48.71772?sources=0";
	echo "<li>speed profil $typ: "; 
	$t = json_decode(file_get_contents("https://$url"));
	foreach($t->durations[0] as $k => $v) if($k != 0) echo round($v)."s (".round($v/3600,2)."h), ";
	//if(is_array($classes[$typ])) foreach($classes[$typ] as $class) echo "<a href='$url&amp;exclude=$class'>exclude $class</a>, ";
	echo "[tanicka: ";
	$t = json_decode(file_get_contents("http://local.$url")); foreach($t->durations[0] as $k => $v) if($k != 0) echo round($v)."s (".round($v/3600,2)."h), ";
	echo "]";
	echo "</li>\n";
}
// ci bezi https://routing.epsilon.sk/table/v1/foot/17.1,48.144;19.157,48.74;21.25,48.71?sources=0 - ba : bb -ke

?>
<li><a href="https://routing.epsilon.sk/debug.php?profil=ski&speed=speed&speeds=10,20&colors=blue,green,red&lat=48.94276&lon=19.59249">ski chopok</a></li>
</ul>
<h2>Download dát</h2><ul>
<li><a href="/data/slovakia.pbf">slovakia.pbf</a> - cca 180mb</li>
<li><a href="/data/bigslovakia.pbf">bigslovakia.pbf</a> - cca 380mb + bounding box</li>
<li><a href="/data/carslovakia.pbf">carslovakia.pbf</a> - cca 610mb + 30km</li>
</ul>



</body></html>

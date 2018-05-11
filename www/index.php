<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="sk" lang="sk" dir="ltr">
	<head>
		<title>routing - &epsilon; epsilon </title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />	
		<link rel="stylesheet" type="text/css" href="https://epsilon.sk/normal.css" />
		<link rel="shortcut icon" href="https://epsilon.sk/favicon.ico" />
</head>
<body>
<h1>routing.epsilon.sk</h1>
<p>použite na <a href='https://www.freemap.sk/'>www.freemap.sk</a>, (prípadne na <a href='https://freemap.epsilon.sk/#page=navigacia&amp;map=T/11/48.12187/17.20734'>demo</a>), je založené na OSRM a <a href="https://github.com/FreemapSlovakia/freemap-routing">tu sú zdrojové kódy</a></p>
<h2>služby/profily:</h2><ul>
<?php
include('maps.php');

echo '<li><a href="status.php">status servera</a>, dáta sú spracovné za SR a okolie, <a href="stats.php">štatistiky</a></li>';
foreach($names as $k => $v) echo "<li>$k - $v".(is_array($classes[$k]) ? ' ('.implode($classes[$k], ', ').')':'').", posledné dáta z ".file_get_contents("last-mod-$k")."</li>\n";
echo '</ul>
<h2>Legenda debugu</h2><ul>
';

foreach($speed as $typ => $c) {
	$url="debug.php?profil=$typ&amp;speed=speed&amp;speeds=".implode(',', $c['speeds'])."&amp;colors=".implode(',', $c['colors'])."";
	echo "<li><a href='$url'>speed profil $typ</a>: "; 
	foreach($c['colors'] as $id => $col) echo "<span style='color: $col;'>".(isset($c['speeds'][$id]) ? "&lt; ".$c['speeds'][$id]."&nbsp;km/h" : "viac ").": $col</span>, ";
	//if(is_array($classes[$typ])) foreach($classes[$typ] as $class) echo "<a href='$url&amp;exclude=$class'>exclude $class</a>, ";
	echo "</li>\n";
}
foreach($rate as $typ => $c) {
    echo "<li><a href='debug.php?profil=$typ&amp;speed=rate&amp;speeds=".implode(',', $c['speeds'])."&amp;colors=".implode(',', $c['colors'])."'>rate profil $typ</a>: ";
    foreach($c['colors'] as $id => $col) echo "<span style='color: $col;'>".(isset($c['speeds'][$id]) ? "&lt; ".$c['speeds'][$id]:"viac").": $col</span>, ";
    echo "</li>\n";
}

?>
<li>speed: rýchlosť v km/h, na základe ktorej sa vypočítava čas dojazdu</li>
<li>rate: "rýchlosť" zhruba v m/s, na základe ktorej sa vyhľadáva trasa (napr. na rušnej ceste je pre peších rate iná ako speed)</li>
<li><a href="bikesharing.php">bikesharing</a></li>
</ul>
</body></html>

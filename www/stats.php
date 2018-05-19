<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="sk" lang="sk" dir="ltr">
	<head>
		<title>routing stats - &epsilon; epsilon </title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />	
		<link rel="stylesheet" type="text/css" href="https://epsilon.sk/normal.css" />
		<link rel="shortcut icon" href="https://epsilon.sk/favicon.ico" />
</head>
<body>
<h1>štatistiky routing.epsilon.sk</h1>
<p><a href='/'>spať</a>, použite na <a href='https://www.freemap.sk/'>www.freemap.sk</a>, (prípadne na <a href='https://freemap.epsilon.sk/#page=navigacia&amp;map=T/11/48.12187/17.20734'>demo</a>), je založené na OSRM a <a href="https://github.com/FreemapSlovakia/freemap-routing">tu sú zdrojové kódy</a></p>
<p>Mapy ukazujú, kde ľudia najviac vyhľadávajú trasy.</p>
<?php
foreach(array('foot','bike','car') as $foot) { echo "<h2>$foot</h2><img src='https://routing.epsilon.sk/nosync/$foot.png' alt='stats for $foot' style='max-width: 90%;'/> "; }

?>


</body></html>

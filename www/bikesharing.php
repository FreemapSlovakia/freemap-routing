<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="sk" lang="sk" dir="ltr">
        <head>
                <title>bikesharing routing for the world- &epsilon; epsilon </title>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />        
                <link rel="stylesheet" type="text/css" href="https://epsilon.sk/normal.css" />
                <link rel="shortcut icon" href="https://epsilon.sk/favicon.ico" />
</head>
<body>
<h1>bikesharing routing</h1>
<p>You can use <a href='https://www.freemap.sk/'>www.freemap.sk</a> for routing/navigation among bikesharing stations.</p>
<?php
include("/home/izsk/weby/oma.sk/connect.php");

$numshar=0; $numbikes=0; $numracks=0;

$ret= "<h2>Available bikesharing systems:</h2><ul>\n";
$q = "select * from bikesharing_operators, (select operator, st_x(geometry(first(way))) as lon, st_y(geometry(first(way))) as lat, sum(free_bikes) as free_bikes, sum(free_racks) as free_racks from bikesharing_stations group by operator) as a where bikesharing_operators.id=a.operator order by hotline";
$res = pg_query($q);
while($r = pg_fetch_assoc($res)) {
	$ret.= "<li><a href='https://www.freemap.sk/?map=14/".$r['lat']."/".$r['lon']."' target='_BLANK'><b>".$r['name']."</b></a>: ".$r['free_bikes']." bicycles and ".$r['free_racks']." free racks (<a href='".$r['website']."' target='_BLANK'>web</a>).</li>\n";
	$numshar++; $numbikes=$numbikes+$r['free_bikes']; $numracks = $numracks +$r['free_racks'];
	}

echo "<p>Currently, we provide routing for bikesharing systems for $numshar systems around the world which have $numbikes bicycles available for rent and ".($numbikes+$numracks)." racks to return them. Your bikesharing is missing? If you run <a href='https://github.com/cyklokoalicia/OpenSourceBikeShare'>OpenSourceBikeShare</a>, let us know. </p>\n";

echo $ret;
?>
</ul>
<p><a href='/'>Back to routing.epsilon.sk main page</a>.<p>
</body></html>

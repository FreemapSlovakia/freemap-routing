<?php
pg_connect("dbname=mapnik");
$ny=1000; $xdec=1000;
//$nx = 100; $ydec=10;
$pdec=1;
$out = "";

$qq = "select st_xmin(tt), st_xmax(tt), st_ymin(tt), st_ymax(tt) from (select(st_envelope(st_union(geometry(p)))) as tt from t_elevation) as t ";
$qq = "select st_xmin(tt), st_xmax(tt), st_ymin(tt), st_ymax(tt) from (select (st_envelope(waym)) as tt from oblasti where name_asci='bratislava') as t ";
$res = pg_query($qq); $row = pg_fetch_assoc($res); 
$xmin = $row['st_xmin'];$xmax = $row['st_xmax'];$ymin = $row['st_ymin'];$ymax = $row['st_ymax'];
//$xmin = 16.7116666666667; $xmax = 22.69; $ymin = 47.65; $ymax = 49.6933333333333; 


for($y=0; $y <= $ny; $y++) {
	$yy = ($ymax - $ymin)/$ny*$y+ $ymin;
	$q = "select getz(st_makepoint(1.0*x/$xdec, $yy)) as ele, 1.0*x/$xdec as x from generate_series(".round($xmin*$xdec).", ".round($xmax*$xdec).", 1) as x(x) order by x";
	//echo $q;
	$res = pg_query($q); $rr = array();$rrr= array();
	while($r = pg_Fetch_assoc($res)) {
		if($r['ele'] == NULL) $rr[] = '-9999'; else $rr[] = round($pdec*$r['ele']);
		$rrr[]=$r['x'];
	}
	$out .= implode($rr, " ")."\r\n";
}

$f = "/home/vseobecne/ine/osrmv5/srtm/dem4.asc";
file_put_contents($f, $out);
//echo $out;

$ret = "
LAT_MIN = $ymin;
LAT_MAX = $ymax;
LON_MIN = ".$rrr[0].";
LON_MAX = ".$rrr[count($rrr)-1].";
ele_presnost= $pdec;

function source_function ()
  raster_source = sources:load(
    '$f', 
    LON_MIN,    -- longitude min
    LON_MAX,  -- longitude max
    LAT_MIN,    -- latitude min
    LAT_MAX,  -- latitude max
    $y,    -- number of rows
    ".count($rr)."    -- number of cols
  )
end";

file_put_contents("tmp/my-dem.lua", $ret);
echo $ret;

?>

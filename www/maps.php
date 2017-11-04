<?php

//speed
$speed['bike'] = array('speeds' => array(5,10), 'colors' => array('blue','green','red') );
$speed['car'] = array('speeds' => array(30,50), 'colors' => array('red','blue', 'green') );
$speed['foot'] = array('speeds' => array(3,7), 'colors' => array('blue','green','red') );
$speed['test'] = array('speeds' => array(3,7), 'colors' => array('blue','green','red') );


//rate
$rate['bike'] = array('speeds' => array(5*3.6,10*3.6), 'colors' => array('blue','green','red') );
$rate['car'] = array('speeds' => array(30*3.6,50*3.6), 'colors' => array('red','blue', 'green') );
$rate['foot'] = array('speeds' => array(3*4,7*4), 'colors' => array('blue','green','red') );

// exclude
$classes['car'] = array('motorway','toll');
// $classes['bike'] = array('night','mud','major'); - not implemented yet
$classes['foot'] = array('stroller','mud','night');


?>

--
drop table if exists osrm_bicycle;
create table osrm_bicycle (
	point_from geography,
	point_to geography,
	weight float, duration float, distance float
--	,vyjazdy int[]
);

drop table if exists tmp_mtbiker;
create table tmp_mtbiker as
select vyjazd, geography(ST_SimplifyPreserveTopology((st_dump(geometry(povodny))).geom, 0.0001)) as way
 from mtbiker_tracks where vyjazd > 0 and povodny is not null and pridany >= '2016-01-01' and typ=2;
create index on tmp_mtbiker using gist(way); vacuum analyze tmp_mtbiker;

-- function to get data and insert start-end into table
create or replace function public.osrm_bicycle_1(point_from geography, point_to geography, weight1 float, duration1 float, distance1 float, 
	OUT weight float, OUT duration float) 
LANGUAGE plpgsql volatile STRICT AS $$
declare
    ele_gain float; slope float; extra float;
    line geometry; next_to_major float; pocet int; vyjazdy int[];
begin
 weight:=weight1; duration:=duration1;
 execute 'select getz($1) - getz($2)' into ele_gain using point_from, point_to;
 if ele_gain is not null and distance1 > 0.2 then
  slope := 100*ele_gain/distance1;
  if slope > 9 then slope := 9; end if;
  if slope <= -9 then slope := -9; end if;
  extra := 3.6*distance1*(-1/17.1 + 1/(17.1 -3.797210*slope +0.212318*slope*slope +0.015032*slope*slope*slope -0.001251*slope*slope*slope*slope));
  if slope > 0.1 then weight:= weight+extra*2; end if;
  duration := duration + extra;
 end if;
 execute 'select geometry(st_buffer(geography(st_makeline(geometry($1),geometry($2))), 25))' into line using point_from, point_to;
 execute '(select sum(case when highway in (''motorway'',''motorway_link'',''trunk'',''trunk_link'',''primary'',''primary_link'') then 1.0*st_length(st_intersection($1, way)::geography) when "natural" = ''tree_row'' then -0.5*st_length(st_intersection($1, way)::geography) end)/(0.01+ st_length($1::geography)) from osrm_osm_line where st_dwithin($1, way, 0.005) and (highway in (''motorway'',''motorway_link'',''trunk'',''trunk_link'',''primary'',''primary_link'') and tunnel is null or "natural" = ''tree_row''))' into next_to_major using line;
 if next_to_major is not null then
  if next_to_major > 1.5 then weight:=weight*2.5; 
  elsif next_to_major > 0 then weight:=weight*(1+next_to_major);
  elsif next_to_major < -0.5 then weight:=weight/2;
  elsif next_to_major < 0 then weight:=weight/(1+next_to_major);
  end if;
 end if;
/* execute 'select array_agg(vyjazd) from tmp_mtbiker where st_dwithin(way, $1, 5) and st_dwithin(way, $2, 5) and $1 && way' into vyjazdy using point_from, point_to; pocet:=array_upper(vyjazdy,1);
 if pocet is not null and pocet != 0 then
  if pocet = 1 then weight:=weight*0.99;
  elsif pocet = 2 then weight:=weight*0.95;
  elsif pocet < 10 then weight:=weight*(1-ln(pocet)/10);
  else weight:=weight*0.74;
  end if;
 end if; */
 --execute 'insert into osrm_bicycle values($1,$2, $3, $4, $5)' using point_from, point_to, weight, duration, distance1;
 --execute 'insert into osrm_bicycle values($1,$2, $3, $4, $5, $6)' using point_from, point_to, weight, duration, distance1, vyjazdy;
end
$$;


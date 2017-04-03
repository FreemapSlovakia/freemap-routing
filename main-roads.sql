-- stable
-- create temporary tables that store major roads with penalization

drop table if exists osrm_major;
create table osrm_major as
select  3::smallint as par, (the_geom).geom as way
from (select st_dump(st_union(geometry(st_buffer(geography(way), 35)))) as the_geom
    from osrm_osm_line where highway in ('trunk','motorway','motorway_link','trunk_link') and tunnel is null
) as d ;
create index on osrm_major using gist(way);
analyze osrm_major;

drop table if exists osrm_tmp_major; create table osrm_tmp_major as select st_collect(way) as way from osrm_major; create index on osrm_tmp_major using gist(way); analyze osrm_tmp_major;

insert into osrm_major
select 2.5, st_difference((the_geom).geom, way ) as way
from (select st_dump(st_union(geometry(st_buffer(geography(way), 25)))) as the_geom
    from osrm_osm_line where highway in ('primary', 'primary_link') and tunnel is null
) as d, osrm_tmp_major ;
analyze osrm_major;

drop table if exists osrm_tmp_major; create table osrm_tmp_major as select st_collect(way) as way from osrm_major; create index on osrm_tmp_major using gist(way); analyze osrm_tmp_major;

insert into osrm_major select 2, st_difference((the_geom).geom, way) as way
from (select st_dump(st_union(geometry(st_buffer(geography(way), 15)))) as the_geom
    from osrm_osm_line where highway in ('secondary', 'secondary_link') and tunnel is null
) as d, osrm_tmp_major ;
analyze osrm_major;

drop table if exists osrm_tmp_major; create table osrm_tmp_major as select st_collect(way) as way from osrm_major; create index on osrm_tmp_major using gist(way); analyze osrm_tmp_major;

insert into osrm_major select 1, st_difference((the_geom).geom, way ) as way
from (select st_dump(st_union(geometry(st_buffer(geography(way), 15)))) as the_geom
    from osrm_osm_line where highway in ('tertiary', 'tertiary_link') and tunnel is null
) as d, osrm_tmp_major ;
analyze osrm_major;

drop table if exists osrm_tmp_major;


insert into osrm_major select -1::smallint as par, (the_geom).geom as way
from (select st_dump(st_union(way)) as the_geom from osrm_osm_polygon where  landuse in ('forest', 'vineyard', 'orchard') or "natural" in ('wood') or leisure in ('park')
) as d;
insert into osrm_major select 1::smallint as par, (the_geom).geom as way
from (select st_dump(st_union(way)) as the_geom from osrm_osm_polygon where landuse in ('industrial', 'garages', 'construction','brownfield','landfill', 'quary') 
) as d;

analyze osrm_major;

drop table if exists osrm_tmp_major;


-- drop table api_t; create table api_t as 
-- select par, st_intersection(cast(ST_SetSRID(ST_MakeBox2D(st_point(x/10, y/10), st_point(x/10+1, y/10+1)), 4326) as geometry), way) as way
-- from osrm_major, generate_series(160, 230, 01) as x(x), generate_series(470, 500, 01) as y(y);
-- create index on api_t using gist(way); analyze api_t;



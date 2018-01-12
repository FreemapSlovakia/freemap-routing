-- Open PostGIS connection
lua_sql = require "luasql.postgres"           -- we will connect to a postgresql database
sql_env = assert( lua_sql.postgres() )
sql_con = assert( sql_env:connect("mapnik") ) -- you can add db user/password here if needed
print("PostGIS connection opened")
--

function out_of_data(segment) 
if segment.source.lon < 16.698 or segment.target.lon < 16.698 then return true; end;  if segment.source.lon > 22.704 or segment.target.lon > 22.704 then return true; end;  if segment.source.lat < 47.641 or segment.target.lat < 47.641 then return true; end;  if segment.source.lat > 49.702 or segment.target.lat > 49.702 then return true; end;  return false; 
end

function segment_function (segment)
	if out_of_data(segment) then return; end
    local line = "st_makeline(ST_SetSRID(st_makepoint(" .. segment.source.lon .. "," .. segment.source.lat .. "), 4326), ST_SetSRID(st_makepoint(" .. segment.target.lon .. "," .. segment.target.lat .. "), 4326))";
	local sql_query = "select (getz(ST_SetSRID(st_makepoint(" .. segment.target.lon .. "," .. segment.target.lat .. "), 4326)::geography) " .. 
		" - getz(ST_SetSRID(st_makepoint(" .. segment.source.lon .. "," .. segment.source.lat .. "), 4326)::geography)) as ele_gain" 
		.. ", (select sum(case when highway in ('motorway','motorway_link','trunk','trunk_link','primary','primary_link') then 1.0*st_length(st_intersection(geometry(st_buffer(geography("..line.."), 25)), way)::geography) when \"natural\" = 'tree_row' then -0.5*st_length(st_intersection(geometry(st_buffer(geography("..line.."), 15)), way)::geography) end)/(0.01+ st_length("..line.."::geography)) from osrm_osm_line where st_dwithin("..line..", way, 0.005) and (highway in ('motorway','motorway_link','trunk','trunk_link','primary','primary_link') and tunnel is null or \"natural\" = 'tree_row')) as next_to_major"
	--	.. ", ";
	local cursor = assert( sql_con:execute(sql_query) )   -- execute querty
	local row = cursor:fetch( {}, "a" )                   -- fetch first (and only) row
	--print(segment.distance .. " " .. segment.weight)
	if row and row.ele_gain then
		local slope = 100*tonumber(row.ele_gain)/segment.distance
		--if slope > 4 then print(slope .. " " .. segment.weight .. " " ..segment.duration .. " speed:" .. segment.distance/segment.duration) end
		if slope > 9 then slope=9 end
		if slope < -9 then slope=-9 end
		local extra = 3.6*segment.distance*(-1/17.1 + 1/(17.1 -3.797210*slope +0.212318*slope*slope +0.015032*slope*slope*slope -0.001251*slope*slope*slope*slope)); 
		-- extra is in seconds due to elevation gain
        if slope > 0.1 then
            segment.weight=segment.weight + 0.7*extra--*segment.weight/segment.duration;
        end
        -- time in seconds
		segment.duration = segment.duration + extra;
	end
    if row and row.next_to_major then
        if tonumber(row.next_to_major) > 1.5 then segment.weight = segment.weight * 2.5
        elseif tonumber(row.next_to_major) > 0 then segment.weight = segment.weight * (1+tonumber(row.next_to_major))
        elseif tonumber(row.next_to_major) < 0 then segment.weight = segment.weight / (1+tonumber(row.next_to_major)) end
    end
	cursor:close();
end
		
-- bike speed formula is from http://www.kreuzotter.de/english/espeed.htm

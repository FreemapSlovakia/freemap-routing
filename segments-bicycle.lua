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
    local sql_query = "select osrm_bicycle_1(ST_SetSRID(st_makepoint(" .. segment.source.lon .. "," .. segment.source.lat .. "), 4326)::geography, ST_SetSRID(st_makepoint(" .. segment.target.lon .. "," .. segment.target.lat .. "), 4326)::geography, "..segment.weight ..", ".. segment.duration ..","..segment.distance..")";
	local cursor = sql_con:execute(sql_query)   -- execute querty
	if cursor then
		local row = cursor:fetch( {}, "a" )                   -- fetch first (and only) row
		--print(segment.distance .. " " .. segment.weight)
		if row and row.weight then
			segment.weight=row.weight;
		end
		if row and row.duration then
			segment.duration = row.duration
		end
		cursor:close();
	end
end
		
-- bike speed formula is from http://www.kreuzotter.de/english/espeed.htm

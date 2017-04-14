-- Open PostGIS connection
lua_sql = require "luasql.postgres"           -- we will connect to a postgresql database
sql_env = assert( lua_sql.postgres() )
sql_con = assert( sql_env:connect("mapnik") ) -- you can add db user/password here if needed
print("PostGIS connection opened")
--

function segment_function (segment)
	local sql_query = "select (getz(ST_SetSRID(st_makepoint(" .. segment.target.lon .. "," .. segment.target.lat .. "), 4326)::geography) " .. 
		" - getz(ST_SetSRID(st_makepoint(" .. segment.source.lon .. "," .. segment.source.lat .. "), 4326)::geography)) as ele_gain" 
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
		--if math.abs(slope) > 4 then print(slope .. " " .. extra .. " " .. segment.weight .. " " ..segment.duration .. "dist: " .. segment.distance .." speed:" .. segment.distance/segment.duration) end
		--if slope < -2 then segment.duration = segment.duration /3 end
	end
	cursor:close();
end
		
-- bike speed formula is from http://www.kreuzotter.de/english/espeed.htm

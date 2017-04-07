-- Open PostGIS connection
lua_sql = require "luasql.postgres"           -- we will connect to a postgresql database
sql_env = assert( lua_sql.postgres() )
sql_con = assert( sql_env:connect("mapnik") ) -- you can add db user/password here if needed
print("PostGIS connection opened")
--

function segment_function (segment)
	local sql_query = "select (getz(ST_SetSRID(st_makepoint(" .. segment.target.lon .. "," .. segment.target.lat .. "), 4326)::geography) " .. 
		" - getz(ST_SetSRID(st_makepoint(" .. segment.source.lon .. "," .. segment.source.lat .. "), 4326)::geography)) as prevysenie" 
	--	.. ", ";
	local cursor = assert( sql_con:execute(sql_query) )   -- execute querty
	local row = cursor:fetch( {}, "a" )                   -- fetch first (and only) row
	--print(segment.distance .. " " .. segment.weight)
	if row and row.prevysenie then
		local slope = tonumber(row.prevysenie)/segment.distance
		--if slope < 0.005 then segment.weight = segment.weight; else segment.weight=segment.weight*math.max(0, (1+20*slope)); end
		local ele_gain = tonumber(row.prevysenie);
		local extra = (ele_gain*0.028 + 0.00036*ele_gain*ele_gain/(segment.distance/1000) )*60 ; -- extra in seconds due to elevation gain
        if slope > 0.01 then
            segment.weight=segment.weight + 0.7*extra--*segment.weight/segment.duration;
        end
        -- time in seconds
		segment.duration = segment.duration + extra;
		--print(slope .. " " .. segment.weight .. " " ..segment.duration)
	end
	cursor:close();
end
		
-- pre turistov: t = 14 . d  + 0,028 . h + 0,00036 . h2 / d
-- kde: t - je čas chôdze v minútach, d - je dĺžka úseku s rovnakým sklonom v km, h - je rozdiel nadmorských výšok konca a začiatku úseku v m (+ alebo - )
-- alebo http://www.pohora.cz/16139-jak-odhadnout-dobu-trvani-tury/
-- bicykel: http://www.kreuzotter.de/english/espeed.htm


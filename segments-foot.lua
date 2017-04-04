-- Open PostGIS connection
lua_sql = require "luasql.postgres"           -- we will connect to a postgresql database
sql_env = assert( lua_sql.postgres() )
sql_con = assert( sql_env:connect("mapnik") ) -- you can add db user/password here if needed
print("PostGIS connection opened")

function segment_function (segment)
	local line = "st_makeline(ST_SetSRID(st_makepoint(" .. segment.source.lon .. "," .. segment.source.lat .. "), 4326), ST_SetSRID(st_makepoint(" .. segment.target.lon .. "," .. segment.target.lat .. "), 4326))";
	local sql_query = "select getz(ST_SetSRID(st_makepoint(" .. segment.source.lon .. "," .. segment.source.lat .. "), 4326)::geography) as ele_first" 
		.. ", getz(ST_SetSRID(st_makepoint(" .. segment.target.lon .. "," .. segment.target.lat .. "), 4326)::geography) as ele_last" 
		.. ", (select count(*) from poi where st_dwithin(".. line .." ::geography, way, 50) and kategoria(typy, 'priroda')) as number_poi"
	--	.. ", (select sum(0.5*par*st_length(st_intersection(" .. line ..", way)::geography))/(0.01+ st_length("..line.."::geography)) from osrm_major where st_dwithin("..line..", way, 0)) as pri_hlavnej"
		.. ", (select sum(2*st_length(st_intersection(geometry(st_buffer(geography("..line.."), 15)), way)::geography))/(0.01+ st_length("..line.."::geography)) from osrm_osm_line where st_dwithin("..line..", way, 0.005) and highway in ('motorway','motorway_link','trunk','trunk_link','primary','primary_link','secondary','secondary_link', 'tertiary','tertiary_link') and tunnel is null ) as next_to_major"
		.. ", (select sum(st_length(st_intersection("..line..", way)::geography)*(case when landuse in ('industrial', 'garages', 'construction','brownfield','landfill', 'quary') then -1 else 1 end))/(0.01+ st_length("..line.."::geography)) from osrm_osm_polygon where st_dwithin("..line..", way, 0.005) and (landuse in ('industrial', 'garages', 'construction','brownfield','landfill', 'quary',  'forest', 'vineyard', 'orchard') or \"natural\" in ('wood') or leisure in ('park') ) ) as in_park"
	local cursor = assert( sql_con:execute(sql_query) )   -- execute querty
	local row = cursor:fetch( {}, "a" )                   -- fetch first (and only) row
	--print(segment.distance .. " " .. segment.weight)
    --print("povodne: ".. segment.distance .. " " .. segment.weight .. " " ..segment.duration)
	if row and row.ele_first and row.ele_last then
		local ele_gain = tonumber(row.ele_last) - tonumber(row.ele_first)
		local slope = ele_gain/segment.distance
        local extra = (ele_gain*0.028 + 0.00036*ele_gain*ele_gain/(segment.distance/1000) )*60 ; -- extra in seconds due to elevation gain
		if slope > 0.01 then
			segment.weight=segment.weight + 0.7*(extra*segment.weight/segment.duration);
        end
		-- time in seconds
		segment.duration = segment.duration + extra;
		--if prevysenie>15 or prevysenie < -15 then print("s:".. segment.source.lon .. " t:".. segment.target.lon.. " d: " ..segment.distance .." ".. segment.weight .. " " ..segment.duration .." prevysenie: ".. prevysenie .." extra:" ..extra) end
	end
	-- prefer segments close to viewpoints/castles/... - weight is lower by 10 "seconds"
	if row and row.number_poi then
		if tonumber(row.number_poi) > 0 then segment.weight = math.max(0, segment.weight - 10) ; end
	end
	-- penalize footways close to major roads
	if row and row.next_to_major then 
		if tonumber(row.next_to_major) > 0 then segment.weight = segment.weight * (1+tonumber(row.next_to_major)) end
	end
	-- prefer footways in forrest/park/..., todo: avoid ways in industrial areas.
	if row and row.in_park then
		if tonumber(row.in_park) > 0 then segment.weight = segment.weight / (1+tonumber(row.in_park)) end
        if tonumber(row.in_park) < 0 then segment.weight = segment.weight / (1+math.abs(tonumber(row.in_park))) end
	end
	--print("nove:    " .. segment.distance .. " " .. segment.weight .. " " ..segment.duration)
	cursor:close();
end
		
-- pre turistov: t = 14 . d  + 0,028 . h + 0,00036 . h2 / d
-- kde: t - je čas chôdze v minútach, d - je dĺžka úseku s rovnakým sklonom v km, h - je rozdiel nadmorských výšok konca a začiatku úseku v m (+ alebo - )
-- alebo http://www.pohora.cz/16139-jak-odhadnout-dobu-trvani-tury/
-- bicykel: http://www.kreuzotter.de/english/espeed.htm


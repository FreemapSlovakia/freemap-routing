-- Open PostGIS connection
lua_sql = require "luasql.postgres"           -- we will connect to a postgresql database
sql_env = assert( lua_sql.postgres() )
sql_con = assert( sql_env:connect("mapnik") ) -- you can add db user/password here if needed
print("PostGIS connection opened")
--

function segment_function (segment)
	local line = "st_makeline(ST_SetSRID(st_makepoint(" .. segment.source.lon .. "," .. segment.source.lat .. "), 4326), ST_SetSRID(st_makepoint(" .. segment.target.lon .. "," .. segment.target.lat .. "), 4326))";
	local sql_query = "select getz(ST_SetSRID(st_makepoint(" .. segment.source.lon .. "," .. segment.source.lat .. "), 4326)::geography) as ele_prvy" 
		.. ", getz(ST_SetSRID(st_makepoint(" .. segment.target.lon .. "," .. segment.target.lat .. "), 4326)::geography) as ele_posledny" 
		.. ", (select count(*) from poi where st_dwithin(".. line .." ::geography, way, 50) and kategoria(typy, 'priroda')) as pocet_poi"
		.. ", (select sum(0.5*par*st_length(st_intersection(" .. line ..", way)::geography))/(0.01+ st_length("..line.."::geography)) from osrm_major where st_dwithin("..line..", way, 0)) as pri_hlavnej"
	local cursor = assert( sql_con:execute(sql_query) )   -- execute querty
	local row = cursor:fetch( {}, "a" )                   -- fetch first (and only) row
	--print(segment.distance .. " " .. segment.weight)
    --print("povodne: ".. segment.distance .. " " .. segment.weight .. " " ..segment.duration)
	if row and row.ele_prvy and row.ele_posledny then
		local prevysenie = tonumber(row.ele_posledny) - tonumber(row.ele_prvy)
		local slope = prevysenie/segment.distance
        local extra = (prevysenie*0.028 + 0.00036*prevysenie*prevysenie/(segment.distance/1000) )*60 ; -- dodatok v sekundach
		if slope > 0.01 then
			segment.weight=segment.weight + 0.7*(extra*segment.weight/segment.duration);
        end
		-- cas v sekundach
		segment.duration = segment.duration + extra;
		--if prevysenie>15 or prevysenie < -15 then print("s:".. segment.source.lon .. " t:".. segment.target.lon.. " d: " ..segment.distance .." ".. segment.weight .. " " ..segment.duration .." prevysenie: ".. prevysenie .." extra:" ..extra) end
	end
	-- prefer segments close to viewpoints/castles/...
	if row and row.pocet_poi then
		if tonumber(row.pocet_poi) > 0 then segment.weight = math.max(0, segment.weight - 10) ; end
	end
	-- penalize footways close to major roads
	if row and row.pri_hlavnej then 
		if tonumber(row.pri_hlavnej) > 0 then segment.weight = segment.weight * (1+tonumber(row.pri_hlavnej)) end
		if tonumber(row.pri_hlavnej) < 0 then segment.weight = segment.weight / (1+math.abs(tonumber(row.pri_hlavnej))) end
		--print("pri hlavnej: " .. row.pri_hlavnej);
	end
	--print("nove:    " .. segment.distance .. " " .. segment.weight .. " " ..segment.duration)
	cursor:close();
end
		
-- pre turistov: t = 14 . d  + 0,028 . h + 0,00036 . h2 / d
-- kde: t - je čas chôdze v minútach, d - je dĺžka úseku s rovnakým sklonom v km, h - je rozdiel nadmorských výšok konca a začiatku úseku v m (+ alebo - )
-- alebo http://www.pohora.cz/16139-jak-odhadnout-dobu-trvani-tury/
-- bicykel: http://www.kreuzotter.de/english/espeed.htm


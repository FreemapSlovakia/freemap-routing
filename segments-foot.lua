-- Open PostGIS connection
lua_sql = require "luasql.postgres"           -- we will connect to a postgresql database
sql_env = assert( lua_sql.postgres() )
sql_con = assert( sql_env:connect("mapnik") ) -- you can add db user/password here if needed
print("PostGIS connection opened")

local line = "$1";
local prepare = "select "
   .."(select count(*) from osrm_osm_t_nature where st_dwithin(".. line ..", way, 50)) as number_poi, "
   .."(select sum(st_length(st_intersection(st_buffer("..line..", coef*10), way))*coef) from osrm_osm_t_major where st_dwithin("..line..", way, 30)) as next_to_major,"
   .."(select sum(st_length(st_intersection("..line..", way))*coef) from osrm_osm_t_in_park where way && "..line..") as in_park"
local cursor = assert( sql_con:execute("PREPARE osrm_foot_segment(geography) AS "..prepare) )


function out_of_data(segment)
if segment.source.lon < 16.698 or segment.target.lon < 16.698 then return true; end;  
if segment.source.lon > 22.704 or segment.target.lon > 22.704 then return true; end;  
if segment.source.lat < 47.641 or segment.target.lat < 47.641 then return true; end;  
if segment.source.lat > 49.702 or segment.target.lat > 49.702 then return true; end;  
return false;
end

function segment_function (profile, segment)
    if out_of_data(segment) then return; end
	local sql_query = "EXECUTE osrm_foot_segment(geography(st_makeline(st_makepoint(" .. segment.source.lon .. "," .. segment.source.lat .. "),st_makepoint(" .. segment.target.lon .. "," .. segment.target.lat .. "))))";
	local cursor = assert( sql_con:execute(sql_query))
	local row = cursor:fetch( {}, "a" )                   -- fetch first (and only) row
	if row and row.ele_first and row.ele_last and segment.distance > 2 then
		local ele_gain = tonumber(row.ele_last) - tonumber(row.ele_first)
		local slope = ele_gain/segment.distance
        local extra = (ele_gain*0.028 + 0.00036*ele_gain*ele_gain/(segment.distance/1000) )*60 ; -- extra in seconds due to elevation gain
		if extra > segment.duration then extra=segment.duration; end
		if slope > 0.01 then
			segment.weight=segment.weight + 0.7*(extra*segment.weight/segment.duration);
        end
		-- time in seconds
		segment.duration = segment.duration + extra;
		--if prevysenie>15 or prevysenie < -15 then print("s:".. segment.source.lon .. " t:".. segment.target.lon.. " d: " ..segment.distance .." ".. segment.weight .. " " ..segment.duration .." prevysenie: ".. prevysenie .." extra:" ..extra) end
	end
	local sourceData = raster:query(profile.raster_source, segment.source.lon, segment.source.lat)
	local targetData = raster:query(profile.raster_source, segment.target.lon, segment.target.lat)
	if sourceData.datum > 0 and targetData.datum > 0 then
		local ele_gain = targetData.datum - sourceData.datum
		local slope = 100*(targetData.datum - sourceData.datum) / segment.distance
		local extra = (ele_gain*0.028 + 0.00036*ele_gain*ele_gain/(segment.distance/1000) )*60 ; -- extra in seconds due to elevation gain
        if extra > segment.duration then extra=segment.duration; end
        if slope > 0.01 then
            segment.weight=segment.weight + 0.7*(extra*segment.weight/segment.duration);
        end
		segment.duration = segment.duration + extra;
	end

	-- prefer segments close to viewpoints/castles/... - weight is lower by 10 "seconds"
	if row and row.number_poi then
		if tonumber(row.number_poi) > 0 then segment.weight = math.max(0, segment.weight - 10) ; end
	end
	-- penalize footways close to major roads
	if row and row.next_to_major then 
		local ne=tonumber(row.next_to_major)/(0.01+segment.distance)/2;
		if ne > 3 then segment.weight = segment.weight * 4
		elseif ne > 0 then segment.weight = segment.weight * (1+ne)
		elseif ne < 0 then segment.weight = segment.weight / (1+ne) end
	end
	-- prefer footways in forrest/park/..., todo: avoid ways in industrial areas.
	if row and row.in_park then
		local ip = tonumber(row.in_park)/(0.01+segment.distance);
		if ip > 1 then segment.weight = segment.weight / 2
		elseif ip > 0 then segment.weight = segment.weight / (1+ip) end
        if ip < -1 then segment.weight = segment.weight * 2
        elseif ip < 0 then segment.weight = segment.weight * (1+math.abs(ip)) end
	end
	--print("nove:    " .. segment.distance .. " " .. segment.weight .. " " ..segment.duration)
	cursor:close();
end
		
-- pre turistov: t = 14 . d  + 0,028 . h + 0,00036 . h2 / d
-- kde: t - je čas chôdze v minútach, d - je dĺžka úseku s rovnakým sklonom v km, h - je rozdiel nadmorských výšok konca a začiatku úseku v m (+ alebo - )
-- alebo http://www.pohora.cz/16139-jak-odhadnout-dobu-trvani-tury/
-- bicykel: http://www.kreuzotter.de/english/espeed.htm


api_version = 1
-- duration je v sekundach, weight je v "sekundach"
-- Foot profile
--  select 'local '||highway || '={[' || string_agg(distinct parts::text, ']=true,['::text)||']=true}; if ' || highway ||'[way:id()] then highway="'|| highway || '"; end' from (select highway,unnest(parts) as parts from (select osm_id, highway from fresh_osm_polygon union select osm_id, highway from fresh_osm_line ) as f,fresh_osm_rels  where osm_id*-1 = id and osm_id < 0 and highway is not null) as t group by highway;
local Set = require('lib/set')
require("route_rels")
--require("route_colour")
--require("crossing");
local find_access_tag = require("osrm-backend/profiles/lib/access").find_access_tag
require("segments-foot");

properties.weight_name = 'rate'
-- Begin of globals
barrier_whitelist = { [""] = true, ["cycle_barrier"] = true, ["bollard"] = true, ["entrance"] = true, ["cattle_grid"] = true, ["border_control"] = true, ["toll_booth"] = true, ["sally_port"] = true, ["gate"] = true, ["no"] = true, ["block"] = true, ["kerb"] = true, ["swing_gate"] = true, ["rope"] = true, ["stile"] = true, ["chain"] = true}
barrier_blacklist = Set { 'yes', 'wall','fence'}
access_tag_whitelist = { ["yes"] = true, ["foot"] = true, ["permissive"] = true, ["designated"] = true  }
access_tag_blacklist = { ["no"] = true, ["private"] = true, ["agricultural"] = true, ["forestry"] = true, ["delivery"] = true }
access_tag_restricted = { ["destination"] = true, ["delivery"] = true }
access_tags_hierarchy = { "foot", "access" }
service_tag_restricted = { ["parking_aisle"] = true }
ignore_in_grid = { ["ferry"] = true }
restriction_exception_tags = { "foot" }
ignore_areas = false
walking_speed = 6

speeds = {
  ["primary"] = walking_speed,
  ["primary_link"] = walking_speed,
  ["secondary"] = walking_speed,
  ["secondary_link"] = walking_speed,
  ["tertiary"] = walking_speed,
  ["tertiary_link"] = walking_speed,
  ["unclassified"] = walking_speed,
  ["residential"] = walking_speed,
  ["road"] = walking_speed,
  ["living_street"] = walking_speed,
  ["service"] = walking_speed,
  ["track"] = walking_speed,
  ["path"] = walking_speed,
  ["steps"] = 2, ["cycleway"] = 4,
  ["pedestrian"] = walking_speed,
  ["footway"] = walking_speed,
  ["pier"] = walking_speed,
  ["default"] = walking_speed
}
unsafe_highway = { ['primary'] = true,['primary_link'] = true,['secondary'] = true, ['secondary_link'] = true, ['tertiary'] = true, ['tertiary_link'] = true, ['unclassified']=true }
medium_highway = { ['residential'] = true, ['road'] = true, ['service']=true }

route_speeds = {
  ["ferry"] = 5
}

platform_speeds = {
  ["platform"] = walking_speed
}

amenity_speeds = {
--  ["parking"] = walking_speed,  ["parking_entrance"] = walking_speed
}

man_made_speeds = {
  ["pier"] = walking_speed
}

surface_speeds = {
  ["fine_gravel"] =  0.75,
  ["gravel"] =       0.75,
  ["pebblestone"] =  0.75,
  ["mud"] =          0.5,
  ["sand"] =         0.5,
	["cobblestone:flatenned"] =  0.7,
    ["cobblestone"] =  0.5,
}

leisure_speeds = {
  ["track"] = walking_speed
}

properties.traffic_signal_penalty        = 2
properties.u_turn_penalty                = 2
properties.use_turn_restrictions         = false
properties.continue_straight_at_waypoint = false
--properties.force_split_edges = true

local fallback_names     = true

function get_exceptions(vector)
  for i,v in ipairs(restriction_exception_tags) do
    vector:Add(v)
  end
end

function node_function (node, result)
  local barrier = node:get_value_by_key("barrier")
  local access = find_access_tag(node, access_tags_hierarchy)
  local traffic_signal = node:get_value_by_key("highway")

  -- flag node if it carries a traffic light
  if traffic_signal and traffic_signal == "traffic_signals" then
    result.traffic_lights = true
  end

  -- parse access and barrier tags
  if access and access ~= "" then
    if access_tag_blacklist[access] then
      result.barrier = true
    else
      result.barrier = false
    end
  elseif barrier and barrier ~= "" then
    if barrier_blacklist[barrier] then
      result.barrier = true
    else
      result.barrier = false
    end
  end
  --if crossings[node.id] then result.duration = result.duration + 120; result.weight = result.weight +100; end
  return 1
end

function way_function (way, result)
  -- initial routability check, filters out buildings, boundaries, etc
  local highway = way:get_value_by_key("highway")
	if route_ways[way:id()] then local highway=route_ways[way:id()]; end

  local leisure = way:get_value_by_key("leisure")
  local route = way:get_value_by_key("route")
  local man_made = way:get_value_by_key("man_made")
  local railway = way:get_value_by_key("railway")
  local amenity = way:get_value_by_key("amenity")
  local public_transport = way:get_value_by_key("public_transport")
  if (not highway or highway == '') and
    (not leisure or leisure == '') and
    (not route or route == '') and
    (not railway or railway=='') and
    (not amenity or amenity=='') and
    (not man_made or man_made=='') and
    (not public_transport or public_transport=='')
    then
    return
  end

  -- don't route on ways that are still under construction
  if highway=='construction' or highway=='proposed' then
      return
  end

  -- access
  local access = find_access_tag(way, access_tags_hierarchy)
  if access_tag_blacklist[access] then
    return
  end

  result.forward_mode = mode.walking
  result.backward_mode = mode.walking
  local name = way:get_value_by_key("name");

  local ref = way:get_value_by_key("ref")
  local junction = way:get_value_by_key("junction")
  local onewayClass = way:get_value_by_key("oneway:foot")
  local duration  = way:get_value_by_key("duration")
  local service  = way:get_value_by_key("service")
  local area = way:get_value_by_key("area")
  local foot = way:get_value_by_key("foot")
  local surface = way:get_value_by_key("surface")

   -- name
  if way:get_value_by_key("name:sk") and "" ~= way:get_value_by_key("name:sk") then
	result.name = way:get_value_by_key("name:sk")
  elseif name and "" ~= name then
    result.name = name
  elseif foot_ways[way:id()] == "red" then result.name= "červenú značku"
  elseif foot_ways[way:id()] == "green" then result.name= "zelenú značku"
  elseif foot_ways[way:id()] == "blue" then result.name= "modrú značku"
  elseif foot_ways[way:id()] == "yellow" then result.name= "žltú značku"
-- probably safe to delete
  elseif way:get_value_by_key("fmrelhikingred") then result.name= "červenú značkuuu"
  elseif way:get_value_by_key("fmrelhikinggreen") then result.name= "zelenú značkuuu"
  elseif way:get_value_by_key("fmrelhikingblue") then result.name= "modrú značkuuu"
  elseif way:get_value_by_key("fmrelhikingyellow") then result.name= "žltú značkuuu"
--  elseif hiking_ways[way:id()] then 
--	result.name = hiking_ways[way:id()];
  elseif highway and highway == "track" then result.name = "lesnú cestu";
  elseif highway and highway == "path" then result.name = "lesný chodník";
  elseif highway and highway == "footway" then result.name = "chodník";
  elseif highway and highway == "pedestrian" then result.name = "chodník";
  elseif highway and highway == "steps" then result.name = "schody";
  elseif highway and highway == "cycleway" then result.name = "cyklochodník";
  elseif highway and highway == "living_street" then result.name = "obytnú cestu";
  elseif highway and medium_highway[highway] then result.name = "vedlajšiu cestu";
  elseif highway and unsafe_highway[highway] then result.name = "hlavnú cestu";
  elseif highway and fallback_names then
    result.name = "{highway:"..highway.."}"  -- if no name exists, use way type
  end

    -- roundabouts
  if "roundabout" == junction then
    result.roundabout = true
  end

    -- speed
  if route_speeds[route] then
    -- ferries (doesn't cover routes tagged using relations)
    --result.ignore_in_grid = true
	if duration and durationIsValid(duration) then
    	result.duration = math.max( 1, parseDuration(duration) )
	else
    	result.forward_speed = route_speeds[route]
	    result.backward_speed = route_speeds[route]
	end
    result.forward_mode = mode.ferry
    result.backward_mode = mode.ferry
  elseif railway and platform_speeds[railway] then
    -- railway platforms (old tagging scheme)
    result.forward_speed = platform_speeds[railway]
    result.backward_speed = platform_speeds[railway]
  elseif platform_speeds[public_transport] then
    -- public_transport platforms (new tagging platform)
    result.forward_speed = platform_speeds[public_transport]
    result.backward_speed = platform_speeds[public_transport]
  elseif amenity and amenity_speeds[amenity] then
    -- parking areas
    result.forward_speed = amenity_speeds[amenity]
    result.backward_speed = amenity_speeds[amenity]
  elseif leisure and leisure_speeds[leisure] then
    -- running tracks
    result.forward_speed = leisure_speeds[leisure]
    result.backward_speed = leisure_speeds[leisure]
  elseif speeds[highway] then
    -- regular ways
    result.forward_speed = speeds[highway]
    result.backward_speed = speeds[highway]
  elseif access and access_tag_whitelist[access] then
      -- unknown way, but valid access tag
    result.forward_speed = walking_speed
    result.backward_speed = walking_speed
  end

  -- oneway
  if onewayClass == "yes" or onewayClass == "1" or onewayClass == "true" then
    result.backward_mode = mode.inaccessible
  elseif onewayClass == "no" or onewayClass == "0" or onewayClass == "false" then
    -- nothing to do
  elseif onewayClass == "-1" then
    result.forward_mode = mode.inaccessible
  end

  -- surfaces
  if surface then
    surface_speed = surface_speeds[surface]
    if surface_speed then
      result.forward_speed = math.max(result.forward_speed*surface_speed, 0)
      result.backward_speed  = math.max(result.backward_speed*surface_speed, 0)
    end
  end

  result.forward_rate = math.max(result.forward_speed, 0)*3.6;
  result.backward_rate = math.max(result.backward_speed, 0)*3.6;
  if way:get_value_by_key("segregated") == "no" and way:get_value_by_key("bicycle") or highway=="cycleway" then
	 result.forward_rate = result.forward_rate*0.5; result.backward_rate = result.backward_rate*0.5;
  end
  if unsafe_highway[highway] then
	result.forward_rate = result.forward_rate*0.3; result.backward_rate = result.backward_rate*0.3;
  end
  if medium_highway[highway] then
    result.forward_rate = result.forward_rate*0.6; result.backward_rate = result.backward_rate*0.6;
  end
  if foot_ways[way:id()] == "red" then
	result.forward_rate = result.forward_rate*1.9; result.backward_rate = result.backward_rate*1.9;
  elseif foot_ways[way:id()] == "blue" or foot_ways[way:id()] == "green" then
	result.forward_rate = result.forward_rate*1.7; result.backward_rate = result.backward_rate*1.7;
  elseif foot_ways[way:id()]  then 
	result.forward_rate = result.forward_rate*1.5; result.backward_rate = result.backward_rate*1.5;
  end
  -- hack to keep backward routes
  result.backward_rate=result.backward_rate*1.001
  result.backward_speed=result.backward_speed*1.001
  -- todo: chodnik blizko hlavnej cesty, vedla hlavnej cesty, penalizovat
end

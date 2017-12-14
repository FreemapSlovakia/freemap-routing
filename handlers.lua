--unsafe_highway = Set { 'primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary', 'tertiary_link', 'unclassified' }
--medium_highway = Set { 'residential', 'road', 'service' }


-- handles name, including ref and pronunciation
function WayHandlers.footnames(profile,way,result,data)
  -- parse the remaining tags
  local name = way:get_value_by_key("name")
  local pronunciation = way:get_value_by_key("name:pronunciation")
  local ref = way:get_value_by_key("ref")
  local exits = way:get_value_by_key("junction:ref")
  local highway =  way:get_value_by_key("highway")

  if way:get_value_by_key("name:sk") and "" ~= way:get_value_by_key("name:sk") then result.name = way:get_value_by_key("name:sk")
  elseif name and "" ~= name then result.name = name
  elseif foot_ways[way:id()] == "red" then result.name= "červenú značku"
  elseif foot_ways[way:id()] == "green" then result.name= "zelenú značku"
  elseif foot_ways[way:id()] == "blue" then result.name= "modrú značku"
  elseif foot_ways[way:id()] == "yellow" then result.name= "žltú značku"
  elseif highway and highway == "track" then result.name = "lesnú cestu";
  elseif highway and highway == "path" then result.name = "lesný chodník";
  elseif highway and highway == "footway" then result.name = "chodník";
  elseif highway and highway == "pedestrian" then result.name = "chodník";
  elseif highway and highway == "steps" then result.name = "schody";
  elseif highway and highway == "cycleway" then result.name = "cyklochodník";
  elseif highway and highway == "living_street" then result.name = "obytnú cestu";
  elseif highway and profile.medium_highway[highway] then result.name = "vedlajšiu cestu";
  elseif highway and profile.unsafe_highway[highway] then result.name = "hlavnú cestu";
  elseif highway then result.name = "{highway:"..highway.."}"  -- if no name exists, use way type
  end

  if ref then
    result.ref = canonicalizeStringList(ref, ";")
  end

  if pronunciation then
    result.pronunciation = pronunciation
  end

  if exits then
    result.exits = canonicalizeStringList(exits, ";")
  end
end

function WayHandlers.footrate(profile,way,result,data)
  result.forward_rate = math.max(result.forward_speed, 0)*3.6;
  result.backward_rate = math.max(result.backward_speed, 0)*3.6;
  if way:get_value_by_key("segregated") == "no" and way:get_value_by_key("bicycle") or highway=="cycleway" then
    result.forward_rate = result.forward_rate*0.5; result.backward_rate = result.backward_rate*0.5;
  end
  if profile.unsafe_highway[data.highway] then
    result.forward_rate = result.forward_rate*0.3; result.backward_rate = result.backward_rate*0.3;
  end
  if profile.medium_highway[data.highway] and way:get_value_by_key("maxspeed") and tonumber(way:get_value_by_key("maxspeed")) <= 30 then
    result.forward_rate = result.forward_rate*0.8; result.backward_rate = result.backward_rate*0.8;
  elseif profile.medium_highway[data.highway] then
    result.forward_rate = result.forward_rate*0.6; result.backward_rate = result.backward_rate*0.6;
  end
  if foot_ways[way:id()] == "red" then
    result.forward_rate = result.forward_rate*1.9; result.backward_rate = result.backward_rate*1.9;
  elseif foot_ways[way:id()] == "blue" or foot_ways[way:id()] == "green" then
    result.forward_rate = result.forward_rate*1.7; result.backward_rate = result.backward_rate*1.7;
  elseif foot_ways[way:id()] then
    result.forward_rate = result.forward_rate*1.5; result.backward_rate = result.backward_rate*1.5;
  end
end

function WayHandlers.footclassnight(profile,way,result,data)
  -- test: pouzitie parametra "exclude=night" v url, vyhodi cesty co nie su osvetlene a pod.
  if way:get_value_by_key("lit") == "no" or way:get_value_by_key("lit") == "disused" then
        result.forward_classes['night'] = true; result.backward_classes['night'] = true;
  end
end

function WayHandlers.footclassstroller(profile,way,result,data)
  -- stroller: vyhodi uzke cesty, schody, ...
  local width = tonumber(way:get_value_by_key("width"))
  if width and width ~= "" and tonumber(width) < 1 or way:get_value_by_key("highway") == 'steps' then
        result.forward_classes['stroller'] = true; result.backward_classes['stroller'] = true;
  end
end

function WayHandlers.footclassmud(profile,way,result,data)
  muddy = Set { 'ground','dirt','earth','mud' }
  local surface = way:get_value_by_key("surface")
  if surface == nil and way:get_value_by_key("highway") == 'path' then surface='dirt'; end
  local grade = way:get_value_by_key("tracktype")
  if surface and muddy[surface] or grade == 'grade5' or grade == 'grade4' then
	result.forward_classes['mud'] = true; result.backward_classes['mud'] = true;
  end
end

function WayHandlers.classunsafe(profile,way,result,data)
  if profile.unsafe_highway[data.highway] and (profile.unsafe_highway[data.highway] == true or profile.unsafe_highway[data.highway] < 0.7) then
       result.forward_classes['unsafe'] = true; result.backward_classes['unsafe'] = true;
  end
  if profile.unsafe_highway[data.highway] then
       result.forward_classes['medium'] = true; result.backward_classes['medium'] = true;
  end
end

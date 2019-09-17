--unsafe_highway = Set { 'primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary', 'tertiary_link', 'unclassified' }
--medium_highway = Set { 'residential', 'road', 'service' }

function get_from_rel(relations, way, key, value, ret, forward)
        -- if any of way's relation have key=value, return tag ret; else return NULL
        if not forward then forward = 'forward'; end -- ignored at the moment
        local rel_id_list = relations:get_relations(way)
        for i, rel_id in ipairs(rel_id_list) do
                local rel = relations:relation(rel_id);
                local p = rel:get_value_by_key(key);
                if value == '*' and p then return rel:get_value_by_key(ret); end
                if p == value then return rel:get_value_by_key(ret); end
        end
        return nil;
end

MyHandlers = {}

-- handles name, including ref and pronunciation
function MyHandlers.footnames(profile,way,result,data)
  -- parse the remaining tags
  local name = way:get_value_by_key("name")
  local pronunciation = way:get_value_by_key("name:pronunciation")
  local ref = way:get_value_by_key("ref")
  local exits = way:get_value_by_key("junction:ref")
  local highway = way:get_value_by_key("highway")

  if way:get_value_by_key("name:sk") and "" ~= way:get_value_by_key("name:sk") then result.name = way:get_value_by_key("name:sk")
  elseif name and "" ~= name then result.name = name
  elseif foot_ways[way:id()] == "red" then result.name= "červenú značku"
  elseif foot_ways[way:id()] == "green" then result.name= "zelenú značku"
  elseif foot_ways[way:id()] == "blue" then result.name= "modrú značku"
  elseif foot_ways[way:id()] == "yellow" then result.name= "žltú značku"
  elseif highway and highway == "track" then result.name = "lesnú cestu";
  elseif highway and highway == "path" then result.name = "lesný chodník";
  elseif highway and highway == "steps" then
    if way:get_value_by_key('step_count') then result.name = way:get_value_by_key('step_count').." schodov";
    else result.name = "schody"; end
  elseif highway and highway == "footway" then result.name = "chodník";
  elseif highway and highway == "pedestrian" then result.name = "pešiu zónu";
  elseif highway and highway == "cycleway" then result.name = "cyklochodník";
  elseif highway and highway == "living_street" then result.name = "obytnú cestu";
  elseif highway and profile.medium_highway[highway] then result.name = "vedlajšiu cestu";
  elseif highway and profile.unsafe_highway[highway] then result.name = "hlavnú cestu";
  elseif way:get_value_by_key('step_count') then result.name = "{highway:"..highway..", steps:"..way:get_value_by_key('step_count').."}"
  elseif highway then result.name = "{highway:"..highway.."}"  -- if no name exists, use way type
  end

  if ref then
    result.ref = canonicalizeStringList(ref, ";")
  end
  if way:get_value_by_key('step_count') then
--    result.name=" "..way:get_value_by_key('step_count').." schodov";
    print (way:get_value_by_key('step_count')..highway.."steps ");
  end

  if pronunciation then
    result.pronunciation = pronunciation
  end

  if exits then
    result.exits = canonicalizeStringList(exits, ";")
  end
end

function MyHandlers.footrate(profile,way,result,data)
  result.forward_rate = math.max(result.forward_speed, 0)*3.6;
  result.backward_rate = math.max(result.backward_speed, 0)*3.6;
  local maxspeed=tonumber(way:get_value_by_key("maxspeed"));
  if maxspeed == nil or maxspeed == "" then maxspeed=50; end
  if way:get_value_by_key("segregated") == "no" and way:get_value_by_key("bicycle") or highway=="cycleway" then
    result.forward_rate = result.forward_rate*0.5; result.backward_rate = result.backward_rate*0.5;
  end
  if profile.unsafe_highway[data.highway] then
    result.forward_rate = result.forward_rate*0.3; result.backward_rate = result.backward_rate*0.3;
  end
  if profile.medium_highway[data.highway] and maxspeed and maxspeed ~= "" and tonumber(maxspeed) <= 30 then
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

function MyHandlers.footclassnight(profile,way,result,data)
  -- test: pouzitie parametra "exclude=night" v url, vyhodi cesty co nie su osvetlene a pod.
  if way:get_value_by_key("lit") == "no" or way:get_value_by_key("lit") == "disused" then
        result.forward_classes['night'] = true; result.backward_classes['night'] = true;
  end
end

function MyHandlers.footclassstroller(profile,way,result,data)
  -- stroller: vyhodi uzke cesty, schody, ...
  local width = tonumber(way:get_value_by_key("width"))
  if width and width ~= "" and tonumber(width) < 1 or way:get_value_by_key("highway") == 'steps' then
        result.forward_classes['stroller'] = true; result.backward_classes['stroller'] = true;
  end
end

function MyHandlers.footclasshiking(profile,way,result,data)
  -- add class based on color of hiking route
  if foot_ways[way:id()] == "red" then result.forward_classes['red'] = true; result.backward_classes['red'] = true;
  elseif foot_ways[way:id()] == "green" then result.forward_classes['green'] = true; result.backward_classes['green'] = true;
  elseif foot_ways[way:id()] == "blue" then result.forward_classes['blue'] = true; result.backward_classes['blue'] = true;
  elseif foot_ways[way:id()] == "yellow" then result.forward_classes['yellow'] = true; result.backward_classes['yellow'] = true;
  end
end


function MyHandlers.footclassmud(profile,way,result,data)
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
function MyHandlers.classunsafe2(profile,way,result,data)
  if profile.unsafe_highway[data.highway] then
       result.forward_classes['unsafe'] = true; result.backward_classes['unsafe'] = true;
  end
end

function MyHandlers.resetspeed(profile,way,result,data)
  -- reset forward/backward speed to be at least 1km/h
  if result.forward_speed > 0 and result.forward_speed < 1 then result.forward_speed=1; end
  if result.backward_speed > 0 and result.backward_speed < 1 then result.backward_speed=1; end
end

function MyHandlers.platform(profile,way,result,data)
  if data.public_transport and data.public_transport == 'platform' then
       result.forward_speed=profile.default_speed; result.backward_speed=profile.default_speed;
  end
end


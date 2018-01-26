function MyHandlers.segregated(profile,way,result,data)
  -- set speed to normal on a footway that has segregated bikelane
  if way:get_value_by_key("segregated") == "yes" and data.bicycle and profile.access_tag_whitelist[data.bicycle] then
        result.forward_speed = default_speed
    result.backward_speed = default_speed
    result.forward_mode = mode.cycling
    result.backward_mode = mode.cycling
  end
end

function MyHandlers.cycleways(profile,way,result,data)
 -- higher rates on cycleways
 if data.highway == 'cycleway' then
   if way:get_value_by_key("segregated") == "no" then
     result.forward_rate = result.forward_rate*1.2
     result.backward_rate = result.backward_rate*1.2
   else
      result.forward_rate = result.forward_rate*1.4
      result.backward_rate = result.backward_rate*1.4
   end
  end
  if data.highway == 'cycleway' and foot ~= 'yes' and foot ~= 'designated' then
    result.forward_rate = result.forward_rate*1.5
    result.backward_rate = result.backward_rate*1.5
  end
end

function MyHandlers.bicycleways(profile,way,result,data)
  -- higher rate on sharrows or lanes
  if data.bicycle and profile.cycleway_tags[bicycle] and data.highway ~= 'cycleway' then
    if result.forward_mode == mode.cycling then result.forward_rate = result.forward_rate*1.2 end
    if result.backward_mode == mode.cycling then result.backward_rate = result.backward_rate*1.2 end
  end
end

function MyHandlers.bicyclerelations(profile,way,result,data, relations)
  -- higher rate on ways that are a part of bicycle relation
  local rels = get_from_rel(relations, way, "route", 'bicycle', "route")
  if rels and rels == 'bicycle' then
    if result.forward_mode == mode.cycling then result.forward_rate = result.forward_rate*1.4 end
    if result.backward_mode == mode.cycling then result.backward_rate = result.backward_rate*1.4 end
  end
end

function MyHandlers.penaltymajorroads(profile,way,result,data, relations)
  -- penalty if maxspeed 
  local bus = get_from_rel(relations, way, "route", 'bus', "route")
  local trolleybus = get_from_rel(relations, way, "route", 'bus', "route")
  local lanes = tonumber(way:get_value_by_key("lanes"));
  local maxspeed = tonumber(way:get_value_by_key("maxspeed"));
  if bus and bus== 'bus' or trolleybus and trolleybus == 'trolleybus' or lanes and lanes >= 2 or maxspeed and maxspeed >= 60 then
    result.forward_rate = result.forward_rate * 0.5;
    result.backward_rate = result.backward_rate * 0.5
  end
end

  


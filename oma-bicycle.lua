api_version = 1
-- cat cut_n30e000.asc |grep -v n |grep -v cell |grep -v NO > central.asc 

-- Bicycle profile
local find_access_tag = require("lib/access").find_access_tag
local Set = require('lib/set')
Sequence = require('lib/sequence')
Handlers = require("lib/handlers")
aaa = require('bicycle_handlers');

local next = next       -- bind to local for speed
local limit = require("lib/maxspeed").limit
require("segments-bicycle");
require("route_rels");
--require("handlers");
require("bicycle_handlers");

-- these need to be global because they are accesed externaly
properties.max_speed_for_map_matching    = 110/3.6 -- kmph -> m/s
properties.use_turn_restrictions         = false
properties.continue_straight_at_waypoint = false
--properties.weight_name                   = 'duration'
properties.weight_name                   = 'cyclability'
properties.force_split_edges = true

function source_function()
 raster_source = sources:load(
      'srtm/central.asc',
      30,    -- lon_min
      30+36023*0.00083333335351199,  -- lon_max
      0,    -- lat_min
      36024*0.00083333335351199,  -- lat_max
      36023,    -- nrows
      36024     -- ncols
)
end

local default_speed = 17
local walking_speed = 6

local profile = {
  default_mode              = mode.cycling,
  default_speed             = 15,
  oneway_handling           = true,
  traffic_light_penalty     = 2,
  u_turn_penalty            = 20,
  turn_penalty              = 3,
  turn_bias                 = 1.4,

  -- reduce the driving speed by 30% for unsafe roads
  safety_penalty            = 0.6,
  use_public_transport      = false,

  allowed_start_modes = Set {
    mode.cycling,
    mode.pushing_bike
  },

  barrier_blacklist = Set { 'yes', 'wall','fence'},

  access_tag_whitelist = Set {
  	'yes',
  	'permissive',
   	'designated'
  },

  access_tag_blacklist = Set {
  	'no',
   	'private',
   	'agricultural',
   	'forestry',
   	'delivery'
  },
  service_access_tag_blacklist = Set {
    'private'
  },
  restricted_access_tag_list = Set { },

  restricted_highway_whitelist = Set { },

  access_tags_hierarchy = Sequence {
  	'bicycle',
  	'vehicle',
  	'access'
  },

  restrictions = Set {
  	'bicycle'
  },

  cycleway_tags = Set {
  	'track',
  	'lane',
  	'opposite',
  	'opposite_lane',
  	'opposite_track',
  	'share_busway',
  	'sharrow','shared_lane',
  	'shared'
  },

  unsafe_highway = { 
	primary = 0.4, primary_link = 0.5, 
	secondary= 0.6, secondary_link = 0.6, 
	tertiary = 0.7, tertiary_link = 0.7, 
	unclassified = 0.7 
  },
  classes = Sequence {
        'unsafe', 'medium', 'mud'
    },

    excludable = Sequence {
        Set {'unsafe'},
        Set {'medium'},
        Set {'unsafe', 'medium'},
        Set {'mud'}
    },


  bicycle_speeds = {
    cycleway = default_speed,
    primary = default_speed,
    primary_link = default_speed,
    secondary = default_speed,
    secondary_link = default_speed,
    tertiary = default_speed,
    tertiary_link = default_speed,
    residential = default_speed,
    unclassified = default_speed,
    living_street = default_speed,
    road = default_speed,
    service = default_speed,
    track = default_speed,
    path = default_speed
  },

  pedestrian_speeds = {
    footway = walking_speed,
    pedestrian = walking_speed,
    steps = 2
  },

  railway_speeds = {
    train = 10,
    railway = 10,
    subway = 10,
    light_rail = 10,
    monorail = 10,
    tram = 10
  },

  platform_speeds = {
    platform = walking_speed
  },

  man_made_speeds = {
    pier = walking_speed
  },

  route_speeds = {
    ferry = 5
  },

  bridge_speeds = {
    movable = 5
  },

  surface_speeds = {
    asphalt = default_speed,
    ["cobblestone:flattened"] = 10,
    paving_stones = 10,
    compacted = 10,
    cobblestone = 6,
    unpaved = 6,
    fine_gravel = 6,
    gravel = 6,
    pebblestone = 6,
    ground = 6,
    dirt = 6,
    earth = 6,
    grass = 6,
    mud = 3,
    sand = 3,
    sett = 10
  },

  tracktype_speeds = {
  },

  smoothness_speeds = {
  },

  avoid = Set {
    'impassable',
    'construction'
  },
  construction_whitelist = {}
}


local function parse_maxspeed(source)
    if not source then
        return 0
    end
    local n = tonumber(source:match("%d*"))
    if not n then
        n = 0
    end
    if string.match(source, "mph") or string.match(source, "mp/h") then
        n = (n*1609)/1000
    end
    return n
end

function get_restrictions(vector)
  for i,v in ipairs(profile.restrictions) do
    vector:Add(v)
  end 
end

function node_function (node, result)
  -- parse access and barrier tags
  local highway = node:get_value_by_key("highway")
  local is_crossing = highway and highway == "crossing"

  local access = find_access_tag(node, profile.access_tags_hierarchy)
  if access and access ~= "" then
    -- access restrictions on crossing nodes are not relevant for
    -- the traffic on the road
    if profile.access_tag_blacklist[access] and not is_crossing then
      result.barrier = true
    end
  else
    local barrier = node:get_value_by_key("barrier")
    if barrier and "" ~= barrier and profile.barrier_blacklist[barrier] then
      result.barrier = true
    end
  end

  -- check if node is a traffic light
  local tag = node:get_value_by_key("highway")
  if tag and "traffic_signals" == tag then
    result.traffic_lights = true
  end
end

function way_function (way, result)
  -- the intial filtering of ways based on presence of tags
  -- affects processing times significantly, because all ways
  -- have to be checked.
  -- to increase performance, prefetching and intial tag check
  -- is done in directly instead of via a handler.

  -- in general we should  try to abort as soon as
  -- possible if the way is not routable, to avoid doing
  -- unnecessary work. this implies we should check things that
  -- commonly forbids access early, and handle edge cases later.

  -- data table for storing intermediate values during processing

  local data = {
    -- prefetch tags
    highway = way:get_value_by_key('highway'),
  }

  local handlers = Sequence {
    -- set the default mode for this profile. if can be changed later
    -- in case it turns we're e.g. on a ferry
    'handle_default_mode',

    -- check various tags that could indicate that the way is not
    -- routable. this includes things like status=impassable,
    -- toll=yes and oneway=reversible
    'handle_blocked_ways',
  }

  if Handlers.run(handlers,way,result,data,profile) == false then
    return
  end
  if route_ways[way:id()] then data.highway=route_ways[way:id()]; end

  -- initial routability check, filters out buildings, boundaries, etc
  local route = way:get_value_by_key("route")
  local man_made = way:get_value_by_key("man_made")
  local railway = way:get_value_by_key("railway")
  local amenity = way:get_value_by_key("amenity")
  local public_transport = way:get_value_by_key("public_transport")
  local bridge = way:get_value_by_key("bridge")
  local railway = way:get_value_by_key("railway")
  if railway == 'tram' and  way:get_value_by_key("bicycle") then
	data.highway='tram'
  end

  if (not data.highway or data.highway == '') and
  (not route or route == '') and
  (not profile.use_public_transport or not railway or railway=='') and
  (not amenity or amenity=='') and
  (not man_made or man_made=='') and
  (not public_transport or public_transport=='') and
  (not bridge or bridge=='')
  then
    return
  end

  -- access
  if bicycleaccess(profile,way) == false then
	  return
  end
  --local access = find_access_tag(way, profile.access_tags_hierarchy)
  --if access and profile.access_tag_blacklist[access] then
  --  return
  --end

  -- other tags
  local junction = way:get_value_by_key("junction")
  local maxspeed = parse_maxspeed(way:get_value_by_key ( "maxspeed") )
  local maxspeed_forward = parse_maxspeed(way:get_value_by_key( "maxspeed:forward"))
  local maxspeed_backward = parse_maxspeed(way:get_value_by_key( "maxspeed:backward"))
  local barrier = way:get_value_by_key("barrier")
  local oneway = way:get_value_by_key("oneway")
  local onewayClass = way:get_value_by_key("oneway:bicycle")
  local cycleway = way:get_value_by_key("cycleway")
  local cycleway_left = way:get_value_by_key("cycleway:left")
  local cycleway_right = way:get_value_by_key("cycleway:right")
  local duration = way:get_value_by_key("duration")
  local service = way:get_value_by_key("service")
  local foot = way:get_value_by_key("foot")
  local foot_forward = way:get_value_by_key("foot:forward")
  local foot_backward = way:get_value_by_key("foot:backward")
  local bicycle = way:get_value_by_key("bicycle")


  -- speed
  local bridge_speed = profile.bridge_speeds[bridge]
  if (bridge_speed and bridge_speed > 0) then
    data.highway = bridge
    if duration and durationIsValid(duration) then
      result.duration = math.max( parseDuration(duration), 1 )
    end
    result.forward_speed = bridge_speed
    result.backward_speed = bridge_speed
  elseif profile.route_speeds[route] then
    -- ferries (doesn't cover routes tagged using relations)
    result.forward_mode = mode.ferry
    result.backward_mode = mode.ferry
    if duration and durationIsValid(duration) then
      result.duration = math.max( 1, parseDuration(duration) )
    else
       result.forward_speed = profile.route_speeds[route]
       result.backward_speed = profile.route_speeds[route]
    end
  -- railway platforms (old tagging scheme)
  elseif railway and profile.platform_speeds[railway] then
    result.forward_speed = profile.platform_speeds[railway]
    result.backward_speed = profile.platform_speeds[railway]
  -- public_transport platforms (new tagging platform)
  elseif public_transport and profile.platform_speeds[public_transport] then
    result.forward_speed = profile.platform_speeds[public_transport]
    result.backward_speed = profile.platform_speeds[public_transport]
  elseif data.highway == 'tram' and bicycle and profile.access_tag_whitelist[bicycle] then
	result.forward_speed = default_speed
    result.backward_speed = default_speed
  -- railways
  elseif profile.use_public_transport and railway and profile.railway_speeds[railway] and profile.access_tag_whitelist[access] then
    result.forward_mode = mode.train
    result.backward_mode = mode.train
    result.forward_speed = profile.railway_speeds[railway]
    result.backward_speed = profile.railway_speeds[railway]
  elseif profile.bicycle_speeds[data.highway] then
    -- regular ways
    result.forward_speed = profile.bicycle_speeds[data.highway]
    result.backward_speed = profile.bicycle_speeds[data.highway]
  elseif access and profile.access_tag_whitelist[access]  then
    -- unknown way, but valid access tag
    result.forward_speed = default_speed
    result.backward_speed = default_speed
  else
    -- biking not allowed, maybe we can push our bike?
    -- essentially requires pedestrian profiling, for example foot=no mean we can't push a bike
    if foot ~= 'no' and (junction ~= "roundabout" and junction ~= "circular") then
	  local width = tonumber(way:get_value_by_key("width"))
	  if data.highway == 'steps' then
		result.forward_speed = 2; result.backward_speed = 2
	  elseif profile.pedestrian_speeds[data.highway] and width and width ~= "" and tonumber(width) >= 5 then
		result.forward_speed = default_speed
        result.backward_speed = default_speed
      elseif profile.pedestrian_speeds[data.highway] then
        -- pedestrian-only ways and areas
        result.forward_speed = profile.pedestrian_speeds[data.highway]
        result.backward_speed = profile.pedestrian_speeds[data.highway]
        result.forward_mode = mode.pushing_bike
        result.backward_mode = mode.pushing_bike
      elseif man_made and profile.man_made_speeds[man_made] then
        -- man made structures
        result.forward_speed = profile.man_made_speeds[man_made]
        result.backward_speed = profile.man_made_speeds[man_made]
        result.forward_mode = mode.pushing_bike
        result.backward_mode = mode.pushing_bike
      elseif foot == 'yes' then
        result.forward_speed = walking_speed
        result.backward_speed = walking_speed
        result.forward_mode = mode.pushing_bike
        result.backward_mode = mode.pushing_bike
      elseif foot_forward == 'yes' then
        result.forward_speed = walking_speed
        result.forward_mode = mode.pushing_bike
        result.backward_mode = mode.inaccessible
      elseif foot_backward == 'yes' then
        result.forward_speed = walking_speed
        result.forward_mode = mode.inaccessible
        result.backward_mode = mode.pushing_bike
      end
    end
  end
  -- way:get_value_by_key("segregated") == "yes"
  if bicycle and profile.access_tag_whitelist[bicycle] then
	result.forward_speed = default_speed
    result.backward_speed = default_speed
    result.forward_mode = mode.cycling
    result.backward_mode = mode.cycling
  end
  -- direction
  local impliedOneway = false
  if junction == "roundabout" or junction == "circular" or data.highway == "motorway" then
    impliedOneway = true
  end
  if oneway == "yes" then impliedOneway = true; end

  if onewayClass == "yes" or onewayClass == "1" or onewayClass == "true" then
    result.backward_mode = mode.inaccessible
  elseif onewayClass == "no" or onewayClass == "0" or onewayClass == "false" or onewayClass == "tolerated" then
    -- prevent implied oneway
  elseif onewayClass == "-1" then
    result.forward_mode = mode.inaccessible
  elseif oneway == "no" or oneway == "0" or oneway == "false" then
    -- prevent implied oneway
  elseif cycleway and string.find(cycleway, "opposite") == 1 then
    if impliedOneway then
      result.forward_mode = mode.inaccessible
      result.backward_mode = mode.cycling
      result.backward_speed = profile.bicycle_speeds["cycleway"]
    end
  elseif cycleway_left and profile.cycleway_tags[cycleway_left] and cycleway_right and profile.cycleway_tags[cycleway_right] then
    -- prevent implied
  elseif cycleway_left and profile.cycleway_tags[cycleway_left] then
    if impliedOneway then
      result.forward_mode = mode.inaccessible
      result.backward_mode = mode.cycling
      result.backward_speed = profile.bicycle_speeds["cycleway"]
    end
  elseif cycleway_right and profile.cycleway_tags[cycleway_right] then
    if impliedOneway then
      result.forward_mode = mode.cycling
      result.backward_speed = profile.bicycle_speeds["cycleway"]
      result.backward_mode = mode.inaccessible
    end
  elseif oneway == "-1" then
    result.forward_mode = mode.inaccessible
  elseif oneway == "yes" or oneway == "1" or oneway == "true" or impliedOneway then
    result.backward_mode = mode.inaccessible
  end

  -- pushing bikes
  if profile.bicycle_speeds[data.highway] or profile.pedestrian_speeds[data.highway] then
    if foot ~= "no" and junction ~= "roundabout" and junction ~= "circular" then
      if result.backward_mode == mode.inaccessible then
        result.backward_speed = walking_speed/2
        result.backward_mode = mode.pushing_bike
      elseif result.forward_mode == mode.inaccessible then
        result.forward_speed = walking_speed/2
        result.forward_mode = mode.pushing_bike
      end
    end
  end

  -- cycleways
--  if cycleway and profile.cycleway_tags[cycleway] then result.forward_speed = profile.bicycle_speeds["cycleway"]; result.backward_speed = profile.bicycle_speeds["cycleway"]
--  elseif cycleway_left and profile.cycleway_tags[cycleway_left] then result.forward_speed = profile.bicycle_speeds["cycleway"]; result.backward_speed = profile.bicycle_speeds["cycleway"]
--  elseif cycleway_right and profile.cycleway_tags[cycleway_right] then result.forward_speed = profile.bicycle_speeds["cycleway"]; result.backward_speed = profile.bicycle_speeds["cycleway"]
--  end

  -- dismount
  if bicycle == "dismount" then
    result.forward_mode = mode.pushing_bike
    result.backward_mode = mode.pushing_bike
    result.forward_speed = walking_speed
    result.backward_speed = walking_speed
  end


  -- maxspeed
  limit( result, maxspeed, maxspeed_forward, maxspeed_backward )

  -- convert duration into cyclability
  local lanes = way:get_value_by_key("lanes")
  if result.forward_speed > 0 then
    -- convert from km/h to m/s
    result.forward_rate = result.forward_speed / 3.6;
	if tonumber(maxspeed) >= 60 or tonumber(maxspeed) > 30 and tonumber(lanes) and tonumber(lanes) >= 2 or public_transport_ways[way:id()] then
	  result.forward_rate = result.forward_rate * 0.5 end
    if profile.unsafe_highway[data.highway] then
      result.forward_rate = result.forward_rate * profile.unsafe_highway[data.highway]
    end
  end
  if result.backward_speed > 0 then
    -- convert from km/h to m/s
    result.backward_rate = result.backward_speed / 3.6;
	if tonumber(maxspeed) >= 60 or tonumber(maxspeed) > 30 and tonumber(lanes) and tonumber(lanes) >= 2 or public_transport_ways[way:id()] then
	  result.backward_rate = result.backward_rate * 0.5; end
    if profile.unsafe_highway[data.highway] then
      result.backward_rate = result.backward_rate * profile.unsafe_highway[data.highway]
    end
  end
  if data.highway == 'cycleway' or (data.highway == 'path' or data.highway == 'footway') and bicycle=='designated' then
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

  if bicycle and profile.cycleway_tags[bicycle] and data.highway ~= 'cycleway' then
    if result.forward_mode == mode.cycling then result.forward_rate = result.forward_rate*1.2 end
    if result.backward_mode == mode.cycling then result.backward_rate = result.backward_rate*1.2 end
  end 
  if bicycle_ways[way:id()]  then
    if result.forward_mode == mode.cycling then result.forward_rate = result.forward_rate*1.4 end
    if result.backward_mode == mode.cycling then result.backward_rate = result.backward_rate*1.4 end
  end

 -- if result.duration > 0 then
 --   result.weight = result.duration;
 --   if is_unsafe then
 --     result.weight = result.weight * (1+profile.safety_penalty)
 --   end
 -- end



  local handlers = Sequence {
    -- compute speed taking into account way type, maxspeed tags, etc.
    'handle_surface',

    -- handle turn lanes and road classification, used for guidance
    'handle_classification',

    -- handle various other flags
    'handle_roundabouts',
    --'handle_startpoint',

    -- set name, ref and pronunciation
    'handle_names',
--	MyHandlers.incline,

--    'classunsafe', 'footclassmud'
  }

  Handlers.run(handlers,way,result,data,profile)

end

function turn_function(turn)
  -- compute turn penalty as angle^2, with a left/right bias
  local normalized_angle = turn.angle / 90.0
  if normalized_angle >= 0.0 then
    turn.duration = normalized_angle * normalized_angle * profile.turn_penalty / profile.turn_bias
  else
    turn.duration = normalized_angle * normalized_angle * profile.turn_penalty * profile.turn_bias
  end

  if turn.direction_modifier == direction_modifier.uturn then
    turn.duration = turn.duration + profile.u_turn_penalty
  end

  if turn.has_traffic_light then
     turn.duration = turn.duration + profile.traffic_light_penalty
  end
  if properties.weight_name == 'cyclability' then
      -- penalize turns from non-local access only segments onto local access only tags
      if not turn.source_restricted and turn.target_restricted then
          turn.weight = turn.weight + 3000
      end
	  if normalized_angle >= 0.0 then
	    turn.weight = turn.weight+normalized_angle * normalized_angle * profile.turn_penalty / profile.turn_bias
  	  else
    	turn.weight = turn.weight+normalized_angle * normalized_angle * profile.turn_penalty * profile.turn_bias
  	  end
  end
end

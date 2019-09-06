api_version = 4

Sequence = require('lib/sequence')
Handlers = require("lib/way_handlers")


function setup()
  return {
    properties = {
 --     max_speed_for_map_matching      = 8/3.6, -- 180kmph -> m/s
      -- For routing based on duration, but weighted for preferring certain roads
      },
      weight_name                     = 'routability',
	default_mode              = mode.driving,
    default_speed             = 6,
    up_speed = 0.005,
    }
end

function process_way(profile, way, result, relations)
 local data = {
	waterway = way:get_value_by_key('waterway')
 }
 if (not data.waterway or data.waterway == '') 
 then
  return
 end
 if data.waterway == 'stream'
 then
   return
 end
 local handlers = Sequence {
	WayHandlers.default_mode,
    WayHandlers.names,

 }
 WayHandlers.run(profile, way, result, data, handlers, relations)

 result.forward_speed= profile.default_speed;
 result.backward_speed= profile.up_speed;

 result.forward_rate = result.forward_speed;
 result.backward_rate = result.backward_speed;
end

return {
  setup = setup,
  process_way = process_way,
}

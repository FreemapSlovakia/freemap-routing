-- OSRM tran and tram profile

api_version = 3
Set = require('lib/set')
Sequence = require('lib/sequence')
Handlers = require("lib/way_handlers")
--Relations = require("lib/relations")
require("handlers");

function WayHandlers.bus(profile,way,result,data)
        result.forward_speed=profile.default_speed; result.forward_rate=profile.default_speed;
    result.backward_speed=profile.default_speed; result.backward_rate=profile.default_speed;
end


function setup()
  return {
    properties = {
		weight_name = 'routability',
		--force_split_edges = true
    }, 
    default_mode = mode.driving,
    default_speed = 30,
    classes = Sequence {
        'tram', 'train'
    },
    -- classes to support for exclude flags
    excludable = Sequence {
        Set {'tram'},
        Set {'train'}
    },
    relation_types = Sequence { "route" }
  }
end

function process_way(profile, way, result, relations)
    local data = {
		highway = way:get_value_by_key('highway'),
		trolley = get_from_rel(relations, way, "route", 'trolleybus', "route"),
		bus = get_from_rel(relations, way, "route", 'bus', "route"),
	}
	
	if ( not data.bus ) and ( not data.trolley ) then
		return false;
	end
	handlers = Sequence {
		WayHandlers.default_mode,
		WayHandlers.names,
		WayHandlers.oneway,
		WayHandlers.bus,
--		WayHandlers.maxspeed,
	}
	WayHandlers.run(profile, way, result, data, handlers, relations)
end

return {
  setup = setup,
  process_way = process_way
}

-- OSRM tran and tram profile

api_version = 4
Set = require('lib/set')
Sequence = require('lib/sequence')
Handlers = require("lib/way_handlers")
--Relations = require("lib/relations")

function WayHandlers.train(profile,way,result,data, relations)
	if not data.railway or data.railway =='' or data.railway == 'platform' then
		return;
	end
	local service = way:get_value_by_key('service');
	if service == 'siding' or service == 'yard' or service == 'spur' then return false; end
	result.forward_speed=profile.default_speed; result.forward_rate=profile.default_speed;
	result.backward_speed=profile.default_speed; result.backward_rate=profile.default_speed;
	if way:get_value_by_key('usage') == 'main' then
		result.forward_rate=result.forward_rate*2;
		result.backward_rate=result.backward_rate*2;
	end
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
		railway = way:get_value_by_key('railway'),
    }

	if ( not data.railway or data.railway =='') then
		return false;
	end
	handlers = Sequence {
		WayHandlers.default_mode,
		WayHandlers.names,
		WayHandlers.train,
		WayHandlers.oneway,
--		WayHandlers.maxspeed,
	}
	WayHandlers.run(profile, way, result, data, handlers, relations)
end

return {
  setup = setup,
  process_way = process_way
}

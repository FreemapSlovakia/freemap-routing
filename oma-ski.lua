-- exclude: ski lifts

api_version = 3
Set = require('lib/set')
Sequence = require('lib/sequence')
Handlers = require("lib/way_handlers")
Relations = require("lib/relations")

function WayHandlers.skiaerialway(profile,way,result,data)
    if not data.aerialway or data.aerialway =='' then 
		return;
    end
    -- station, goods
    if data.aerialway == 'gondola' or data.aerialway == 'cable_car' or data.aerialway == 'mixed_lift' then
		result.forward_classes['gondola'] = true;
    elseif data.aerialway == 'chair_lift' then
        result.forward_classes['chairlift'] = true;
    elseif data.aerialway == 't-bar' or data.aerialway == 'j-bar' or data.aerialway == 'platter' or data.aerialway == 'drag_lift' then
        result.forward_classes['platter'] = true;
	elseif data.aerialway == 'rope_tow' or data.aerialway == 'zip_line' or data.aerialway == 'magic_carpet' then 
		result.forward_classes['child'] = true;
    else 
		-- remaining: goods, station, pilon, yes
		print(data.aerialway);
    end
    result.forward_speed=15;
    result.forward_rate=15;
    result.forward_mode = mode.ferry;
	-- todo: add duration tag from way data
    result.backward_mode = mode.inaccessible;
end

function WayHandlers.skipiste(profile,way,result,data)
	-- piste: downhill, foot (for foot transfer between stations)
    if not data.piste or data.piste =='' then
        return;
    end
	-- remove piste that are areas, ususally not good for routing
    if way:get_value_by_key('area') == 'yes' then
		return false;
    end
    result.forward_speed=30;
    result.forward_rate=30;
    result.forward_mode = mode.driving;
	if data.piste == 'foot' then
		result.forward_speed=3; result.forward_rate=3;
		result.backward_mode = mode.driving;
	else
	    result.backward_mode = mode.inaccessible;
	end
end


function setup()
  return {
    properties = {
	 weight_name = 'duration',
    }, 
    default_mode = mode.ferry,
    default_speed = 30,
    classes = Sequence {
        'gondola', 'chairlift', 'platter', 'child', 'nordic'
    },
    -- classes to support for exclude flags
    excludable = Sequence {
        Set {'gondola'},
        Set {'chairlift'},
        Set {'platter'},
		Set {'child'},
		Set {'gondola','chairlift','platter','child'},
		Set {'nordic'}
    },
    relation_types = Sequence {
      "route"
    }
  }
end

function process_way(profile, way, result, relations)
    local data = {
	aerialway = way:get_value_by_key('aerialway'),
	piste = way:get_value_by_key('piste:type')
    }
    if ( not data.aerialway or data.aerialway =='') and ( not data.piste or data.piste == '') then
	return
    end
    handlers = Sequence {
	WayHandlers.default_mode,
	WayHandlers.names,
	--WayHandlers.oneway,
	WayHandlers.skiaerialway,
	WayHandlers.skipiste
    }
    WayHandlers.run(profile, way, result, data, handlers, relations)
end

return {
  setup = setup,
  process_way = process_way
}

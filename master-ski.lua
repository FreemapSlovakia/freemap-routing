-- exclude: ski lifts

api_version = 3
Set = require('lib/set')
Sequence = require('lib/sequence')
Handlers = require("lib/way_handlers")
Relations = require("lib/relations")
--require("segments-ski");

function WayHandlers.skiaerialway(profile,way,result,data)
	if not data.aerialway or data.aerialway =='' then 
		return;
	end
	result.forward_speed=15; result.forward_rate=15;
	result.backward_mode = mode.inaccessible;
	-- duration of gondolas
	local duration  = way:get_value_by_key("duration")
	if duration and durationIsValid(duration) then
		result.duration = math.max( parseDuration(duration), 1 )
	end
	-- station, goods
	if data.aerialway == 'gondola' or data.aerialway == 'cable_car' or data.aerialway == 'mixed_lift' then
		result.forward_classes['gondola'] = true; result.backward_classes['gondola'] = true;
		result.backward_mode = mode.ferry;
		result.backward_speed=result.forward_speed; result.backward_rate=result.forward_rate/10;
	elseif data.aerialway == 'chair_lift' then
		result.forward_classes['chairlift'] = true;
	elseif data.aerialway == 't-bar' or data.aerialway == 'j-bar' or data.aerialway == 'platter' or data.aerialway == 'drag_lift' then
		result.forward_classes['platter'] = true;
		result.forward_rate=result.forward_speed/4;
	elseif data.aerialway == 'rope_tow' or data.aerialway == 'zip_line' or data.aerialway == 'magic_carpet' then 
		result.forward_classes['child'] = true;
		result.forward_rate=result.forward_speed/4;
	else 
		-- remaining: goods, station, pilon, yes
		--print(data.aerialway);
		result.forward_mode = mode.inaccessible;
		return false;
	end
	result.forward_mode = mode.ferry;
	result.name = result.name .. ' 🚡';
end

function WayHandlers.skipiste(profile,way,result,data)
	-- piste: downhill, foot (for foot transfer between stations)
	if not data.piste or data.piste == '' then
		return;
	end
	-- remove piste that are areas, ususally not good for routing
	if way:get_value_by_key('area') == 'yes' or  way:get_value_by_key('leisure') == 'sports_centre' then
		return false;
	end
	if data.piste == 'foot' then
                result.forward_speed=3; result.forward_rate=3;
                result.backward_speed=3; result.backward_rate=3;
                result.backward_mode = mode.walking; result.forward_mode = mode.walking;
		result.name = result.name .. ' 🚶';
		return result;
	end
	if data.piste == 'downhill' then
		result.forward_speed=30; result.forward_rate=30;
		result.forward_mode = mode.driving;
		result.name = result.name .. ' ⛷';
		result.backward_ref = '🚶';
		result.backward_speed = 1/10; result.backward_rate = 1/100;
		result.backward_mode = mode.walking;
		-- todo: class dificulty
		return result;
	end
end

function WayHandlers.skinordic(profile,way,result,data)
	if not data.piste or not data.piste == 'nordic' then
		return
	end
	if data.piste == 'nordic' then
	result.forward_speed=5; result.forward_rate=5;
	result.backward_speed=5; result.backward_rate=5;
	result.backward_mode = mode.driving; result.forward_mode = mode.driving;
	result.forward_classes['nordic'] = true; result.backward_classes['nordic'] = true;
	end
end

function WayHandlers.namesfromrelations(profile,way,result,data,relations)
	if not result.name or result.name == '' then result.name = get_from_rel(relations, way, "piste:type", '*', "name"); end
	if not result.name or result.name == '' then result.name = get_from_rel(relations, way, "piste:type", '*', "ref"); end
	if not result.name or result.name == '' then result.name = get_from_rel(relations, way, "route", 'ski', "name"); end
end


function setup()
  return {
    properties = {
		weight_name = 'routability',
		--force_split_edges = true
    }, 
    default_mode = mode.ferry,
    default_speed = 1,
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
      "route", "piste:type"
    }
  }
end

function get_from_rel(relations, way, key, value, ret)
	-- if any of way's relation have key=value, return tag ret; else return NULL
	local rel_id_list = relations:get_relations(way)
	for i, rel_id in ipairs(rel_id_list) do
		local rel = relations:relation(rel_id);
		local p = rel:get_value_by_key(key);
		if value == '*' and p then return rel:get_value_by_key(ret); end
		if p == value then return rel:get_value_by_key(ret); end
	end
	return nil;
end

function process_way(profile, way, result, relations)
    local data = {
	aerialway = way:get_value_by_key('aerialway'),
	piste = way:get_value_by_key('piste:type')
    }
	if way:get_value_by_key('railway') == 'funicular' then
		data.aerialway = 'gondola'
	end
	-- data.piste from relation's piste:type
	if not data.piste then data.piste = get_from_rel(relations, way, "piste:type", '*', "piste:type"); end
	-- if data.piste is still not set, every way in route=ski is piste:type=nordic
	if not data.piste and get_from_rel(relations, way, "route", 'ski', "route") then data.piste='nordic'; end

	if ( not data.aerialway or data.aerialway =='') and ( not data.piste or data.piste == '') then
		return
	end
	handlers = Sequence {
		WayHandlers.default_mode,
		WayHandlers.names,
		WayHandlers.namesfromrelations,
		--WayHandlers.oneway,
		WayHandlers.skiaerialway, WayHandlers.skipiste, -- grep piste
		WayHandlers.skinordic, -- grep nordic
	}
	WayHandlers.run(profile, way, result, data, handlers, relations)
end

return {
  setup = setup,
  process_way = process_way
}

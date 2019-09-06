-- 

function segment_function (segment)
	local sourceData = sources:interpolate(raster_source, segment.source.lon, segment.source.lat)
	local targetData = sources:interpolate(raster_source, segment.target.lon, segment.target.lat)
	local distance1=segment.distance;
	if sourceData.datum > 0 and targetData.datum > 0 then
		local slope = 100*(targetData.datum - sourceData.datum) / segment.distance
		if slope > 9 then slope=9; end
		if slope <-9 then slope=-9; end
		local extra = 3.6*distance1*(-1/17.1 + 1/(17.1 -3.797210*slope +0.212318*slope*slope +0.015032*slope*slope*slope -0.001251*slope*slope*slope*slope));
		if slope > 0.1 then segment.weight = segment.weight+extra*2; end;
		segment.duration = segment.duration + extra;
	end
end
		
-- bike speed formula is from http://www.kreuzotter.de/english/espeed.htm

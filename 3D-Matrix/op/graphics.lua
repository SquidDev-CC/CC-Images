
local function rgb(r, g, b)
	return r * 256^2 + g * 256 + b
end

local function rgbD(r, g, b)
	return math.floor(r * 255) * 256^2 +math.floor(g * 255) * 256 + math.floor(b * 255)
end

local function hsv(h, s, v)
	if s <= 0.0 then
		return rgbD(v, v, v)
	end

	local hh = h * 360;
	if hh >= 360.0 then hh = 0.0 end
	hh = hh / 60.0;
	local i = hh;
	local ff = hh % 1;

	local p = v * (1.0 - s);
	local q = v * (1.0 - (s * ff));
	local t = v * (1.0 - (s * (1.0 - ff)));

	if i < 1 then
		return rgbD(v, t, p)
	elseif i < 2 then
		return rgbD(q, v, p)
	elseif i < 3 then
		return rgbD(p, v, t)
	elseif i < 4 then
		return rgbD(p, q, v)
	elseif i < 5 then
		return rgbD(t, p, v)
	else
		return rgbD(v, p, q)
	end
end

return function(graphics, width, height)
	local function normalise(coord)
		return {
			(coord[1] + 1) * width / 2,
			(coord[2] + 1) * height / 2,
		}
	end

	local function drawPoint(a, colour, opacity, size)
		graphics.addPoint(normalise(a), colour, opacity).setSize(size or 5)
	end

	local function drawLine(a, b, colour, opacity, width)
		local line = graphics.addLine(normalise(a), normalise(b), colour, opacity)
		if width then line.setWidth(width) end
	end

	local function drawPolygon(points, colour, opacity)
		for i = 1, #points do points[i] = normalise(points[i]) end
		graphics.addPolygon(colour, opacity, unpack(points))
	end

	local function drawPolygonOutline(points, colour, opacity, width)
		for i = 1, #points do points[i] = normalise(points[i]) end
		local line = graphics.addLineList(colour, opacity, unpack(points))
		if width then line.setWidth(width) end
	end

	return {
		rgb = rgb,
		rgbD = rgbD,
		hsv = hsv,

		normalise = normalise,
		drawPoint = drawPoint,
		drawLine = drawLine,
		drawPolygon = drawPolygon,
		drawPolygonOutline = drawPolygonOutline
	}
end

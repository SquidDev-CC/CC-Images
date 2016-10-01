local graphics, glasses = ...

local clip = require "clip"
local counter = 0
return function(mvp)
	counter = (counter + 0.005) % 1

	clip.polygon(
		mvp,
		{
			{ 0, 0, 0, 1 },
			{ 0, 0, 3, 1 },
			{ 3, 0, 0, 1 }
		},
		graphics.drawPolygon,
		graphics.hsv(counter, 0.6, 1), 0.5
	)
end

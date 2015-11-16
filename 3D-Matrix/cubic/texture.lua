-- This is included in a rather wacky way in the build script.
-- It handles UV texture mapping

local floor = math.floor
local pixel = buffer.pixel
local function shader(x, y, z, u, v, texture)
	local u, v = floor(u * 8), floor(v * 8)

	if u > 8 then u = 8 elseif u < 1 then u = 1 end
	if v > 8 then v = 8 elseif v < 1 then v = 1 end

	pixel(x, y, z, texture[u + (v - 1) * 8])
end

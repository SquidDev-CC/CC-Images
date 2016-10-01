local graphics, glasses = ...

local clip = require "clip"
local matrix = require "matrix"
local transform = require "transform"

local verticies = {
	{  3,  3, -3, 1 },
	{  3, -3, -3, 1 },
	{ -3, -3, -3, 1 },
	{ -3,  3, -3, 1 },
	{  3,  3,  3, 1 },
	{  3, -3,  3, 1 },
	{ -3, -3,  3, 1 },
	{ -3,  3,  3, 1 },
}

for i = 1, #verticies do
	verticies[i][2] = verticies[i][2] - 5
end

local colours = {
	{ 255, 0,   0,   255 },
	{ 0,   255, 0,   255 },
	{ 0,   0,   255, 255 },
	{ 0,   255, 255, 255 },
	{ 255, 255, 0,   255 },
	{ 255, 0,   255, 255 },
	{ 255, 128, 0,   255 },
	{ 128, 255, 0,   255 },
}

for i = 1, #colours do colours[i] = graphics.rgb(unpack(colours[i])) end

local indexes = {
	{1,2,3, 1},
	{1,3,4, 1},
	{7,6,8, 2},
	{8,6,5, 2},

	{3,7,4, 3}, -- Left
	{4,7,8, 3},
	{5,6,2, 4},
	{2,1,5, 4},

	{5,1,4, 5}, -- Top
	{4,8,5, 5},
	{2,6,3, 6},
	{6,7,3, 6},
}

for i = 1, #indexes do
	local tri = indexes[i]

	local a = verticies[tri[1]]
	local b = verticies[tri[2]]
	local c = verticies[tri[3]]

	tri[5] = {
		(a[1] + b[1] + c[1]) / 3,
		(a[2] + b[2] + c[2]) / 3,
		(a[3] + b[3] + c[3]) / 3,
	}
end


local function sortDistance(a, b)
	return a[6] >= b[6]
end

local counter = 0
return function(mvp, pData, x, y, z)
	counter = (counter + 0.005) % 1

	for i = 1, #indexes do
		local tri = indexes[i]
		local mid = tri[5]
		tri[6] = (mid[1] - x)^2 + (mid[2] - y)^2 + (mid[3] - z)^2
	end
	table.sort(indexes, sortDistance)
	for i = 1, #indexes do
		local tri = indexes[i]

		clip.polygon(
			mvp,
			{verticies[tri[1]],
			verticies[tri[2]],
			verticies[tri[3]]},
			graphics.drawPolygon,
			colours[tri[4]], 0.6
		)
	end

	glasses.addText(5, 5, (textutils.serialize(pData.living.lookingAt):gsub("%s+", " ")))
	glasses.addText(5, 15, (textutils.serialize(pData.position):gsub("%s+", " ")))
	glasses.addText(5, 25, (textutils.serialize({yaw = pData.living.yaw, pitch = pData.living.pitch}):gsub("%s+", " ")))
end

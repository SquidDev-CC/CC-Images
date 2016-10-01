local graphics, glasses = ...

local clip = require "clip"
local matrix = require "matrix"
local transform = require "transform"

local verticies = {
	{  0.25,  0.25, -0.25, 1 },
	{  0.25, -0.25, -0.25, 1 },
	{ -0.25, -0.25, -0.25, 1 },
	{ -0.25,  0.25, -0.25, 1 },
	{  0.25,  0.25,  0.25, 1 },
	{  0.25, -0.25,  0.25, 1 },
	{ -0.25, -0.25,  0.25, 1 },
	{ -0.25,  0.25,  0.25, 1 },
}

local colour = graphics.rgb(0, 255, 0)

local indexes = {
	{1,2,3},
	{1,3,4},
	{7,6,8},
	{8,6,5},

	{3,7,4}, -- Left
	{4,7,8},
	{5,6,2},
	{2,1,5},

	{5,1,4}, -- Top
	{4,8,5},
	{2,6,3},
	{6,7,3},
}

for i = 1, #indexes do
	local tri = indexes[i]

	local a = verticies[tri[1]]
	local b = verticies[tri[2]]
	local c = verticies[tri[3]]

	tri[4] = {
		(a[1] + b[1] + c[1]) / 3,
		(a[2] + b[2] + c[2]) / 3,
		(a[3] + b[3] + c[3]) / 3,
	}
end

local function sortDistance(a, b) return a[5] >= b[5] end

local posX, posZ

local counter = 0
local score = 0

return function(mvp, pData, x, y, z)
	counter = (counter + 0.1) % (math.pi * 2)

	if posX and (posX - x)^2 + (posZ - z)^2 < 0.5^2 then
		posX = nil
		score = score + 1
	end

	if not posX then
		posX = math.random(1, 10)
		posZ = math.random(1, 10)
	end

	local cube = matrix.compose(
		mvp,
		transform.translate(posX, math.sin(counter) * 0.1 - 1, posZ),
		-- transform.rotateY(counter),
		transform.rotateZ(math.pi / 4),
		transform.rotateX(math.pi / 4)
	)

	for i = 1, #indexes do
		local tri = indexes[i]
		local mid = tri[4]
		tri[5] = (mid[1] - x)^2 + (mid[2] - y)^2 + (mid[3] - z)^2
	end
	table.sort(indexes, sortDistance)
	for i = 1, #indexes do
		local tri = indexes[i]

		clip.polygon(
			cube,
			{verticies[tri[1]],
			verticies[tri[2]],
			verticies[tri[3]]},
			graphics.drawPolygon,
			colour, 0.3
		)

		clip.polygon(
			cube,
			{verticies[tri[1]],
			verticies[tri[2]],
			verticies[tri[3]]},
			graphics.drawPolygonOutline,
			colour,
			0.1,
			10
		)
	end

	glasses.addText(5, 5, "Current score: " .. score)
end

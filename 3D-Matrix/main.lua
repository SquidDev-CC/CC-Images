local matrix, transform = require('matrix'), require('transform')
local graphics = require('graphics')

local verticies = {
	-- { 0,            -3, 0, 1},
	-- { 0,             3, 4.5, 1},
	-- {-3.89711431703, 3, -2.25, 1},
	-- { 3.89711431703, 3, -2.25, 1}
	{3,3,-3, 1},
	{3,-3,-3, 1},
	{-3,-3,-3, 1},
	{-3,3,-3, 1},
	{3,3,3, 1},
	{3,-3,3, 1},
	{-3,-3,3, 1},
	{-3,3,3, 1},

	-- {0, 0, 0, 1}, {1, 0, 0, 1},
	-- {0, 0, 0, 1}, {0, 1, 0, 1},
	-- {0, 0, 0, 1}, {0, 0, 1, 1},
}

local colours = {
	{255, 0, 0, 255},
	{0, 255, 0, 255},
	{0, 0, 255, 255},
	{0, 255, 255, 255},
	{255, 255, 0, 255},
	{255, 0, 255, 255},
	{255, 128, 0, 255},
	{128, 255, 0, 255},

	{255, 0, 0, 255}, {255, 0, 0, 255},
	{0, 255, 0, 255}, {0, 255, 0, 255},
	{0, 0, 255, 255}, {0, 0, 255, 255},
}

local indexes = {
	-- {1,2,3},
	-- {1,3,4},
	-- {7,6,8},
	-- {8,6,5},

	{3,7,4}, -- Left
	-- {4,7,8},
	-- {5,6,2},
	-- {2,1,5},

	-- {5,1,4}, -- Top
	-- {4,8,5},
	-- {2,6,3},
	-- {6,7,3},
}

local lines = {
	-- {9, 10},
	-- {11, 12},
	-- {13, 14},
}
local dispWidth, dispHeight = 300, 300
local mulpMat, mulpVer = matrix.createMultiply(4, 4, 4, 4), matrix.createMultiply(4, 4, 4, 1)

local projection = transform.perspective(math.pi / 2, 1, 0.1, 6.0)
-- projection = transform.orthographic(-1, 1, -1, 1, -1, 1)

local function compose(...)
	local result, items = ..., {select(2, ...)}
	for _, item in pairs(items) do
		result = mulpMat(result, item)
	end

	return result
end

local function normalise(coord)
	coord[1] = (coord[1] + 1) * dispWidth / 2
	coord[2] = (coord[2] + 1) * dispHeight / 2
	coord[3] = (coord[3] + 1) / 2

	return coord
end

local function draw(g, v, group)
	local a, b, c = v[group[1]], v[group[2]], v[group[3]]
	if true then
		g.triangleBlended(
			a[1], a[2], a[3],
			b[1], b[2], b[3],
			c[1], c[2], c[3],
			colours[group[1]], colours[group[2]], colours[group[3]]
		)
	else
		g.lineBlended(
			a[1], a[2], a[3],
			b[1], b[2], b[3],
			colours[group[1]], colours[group[2]]
		)

		g.lineBlended(
			a[1], a[2], a[3],
			c[1], c[2], c[3],
			colours[group[1]], colours[group[3]]
		)

		g.lineBlended(
			b[1], b[2], b[3],
			c[1], c[2], c[3],
			colours[group[2]], colours[group[3]]
		)
	end
end

local function drawLine(g, v, group)
	local a, b = v[group[1]], v[group[2]]
	g.lineBlended(
		a[1], a[2], a[3],
		b[1], b[2], b[3],
		colours[group[1]], colours[group[2]]
	)
end
matrix.print(projection)


local rotX, rotY = 0, 0
local x, y, z = 0, 0, 8

local g

local function refreshMatrix()
	local view = compose(unpack {
		transform.scale(1/20, 1/20, 1/20),
		transform.translate(-x, -y, -z),
		transform.rotateX(rotX),
		transform.rotateY(rotY),
	})
	local mvp = compose(projection, view)
	-- matrix.print(mvp)
	-- print(x, y, z)

	g = graphics(dispWidth, dispHeight)
	local p = {}
	print("###########################")
	for k, v in pairs(verticies) do
		local coord = mulpVer(mvp, v)
		if coord[4] == 0 then coord[4] = 1 print("SOMETHING IS 0", coord[3]) end
		coord[1] = coord[1] / coord[4]
		coord[2] = coord[2] / coord[4]
		p[k] = coord
	end

	for k, _ in pairs(verticies) do
		p[k] = normalise(p[k])
	end

	for _, group in pairs(indexes) do
		draw(g, p, group)
	end

	for _, group in pairs(lines) do
		drawLine(g, p, group)
	end
end

refreshMatrix()
function love.keypressed(key)
	if key == "a" then
		rotY = (rotY + 0.1) % (2 * math.pi)
	elseif key == "d" then
		rotY = (rotY - 0.1) % (2 * math.pi)
	elseif key == "w" then
		rotX = (rotX + 0.1) % (2 * math.pi)
	elseif key == "s" then
		rotX = (rotX - 0.1) % (2 * math.pi)
	elseif key == "u" then
		z = z + 1
	elseif key == "p" then
		z = z - 1
	elseif key == "j" then
		x = x + 1
	elseif key == "l" then
		x = x - 1
	elseif key == "i" then
		y = y + 1
	elseif key == "k" then
		y = y - 1
	elseif key == "r" then
		rotY = 0
		rotX = 0
	end

	refreshMatrix()
end

function love.draw()
	g.love(love)
end


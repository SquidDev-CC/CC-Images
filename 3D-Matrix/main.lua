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

local colours = {
	{ 255, 0,   0,   100 },
	{ 0,   255, 0,   100 },
	{ 0,   0,   255, 100 },
	{ 0,   255, 255, 100 },
	{ 255, 255, 0,   100 },
	{ 255, 0,   255, 100 },
	{ 255, 128, 0,   100 },
	{ 128, 255, 0,   100 },
}

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


local g = graphics
local dispWidth, dispHeight = g.size()
local projection = transform.perspective(math.pi / 2, 1, 0.1, 6.0)

local function compose(...)
	local result, items = ..., {select(2, ...)}
	for _, item in pairs(items) do
		result = matrix.matrix(result, item)
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
			a[1], a[2], a[3], colours[group[1]],
			b[1], b[2], b[3], colours[group[2]],
			c[1], c[2], c[3], colours[group[3]]
		)
	else
		g.lineBlended(
			a[1], a[2], a[3], colours[group[1]],
			b[1], b[2], b[3], colours[group[2]]
		)

		g.lineBlended(
			a[1], a[2], a[3], colours[group[1]],
			c[1], c[2], c[3], colours[group[3]]
		)

		g.lineBlended(
			b[1], b[2], b[3], colours[group[2]],
			c[1], c[2], c[3], colours[group[3]]
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
local rotX, rotY = 0, 0
local x, y, z = 0, 0, 8

local function refreshMatrix()
	local view = compose(unpack {
		transform.scale(1/20, 1/20, 1/20),
		transform.translate(-x, -y, -z),
		transform.rotateX(rotX),
		transform.rotateY(rotY),
	})
	local mvp = compose(projection, view)

	g.clear()
	local p = {}

	for k, v in pairs(verticies) do
		local coord = matrix.vector(mvp, v)
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
end

refreshMatrix()
local function pressed(key)
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

if term then
	g.silica(term.native())
	while true do
		local _, key = os.pullEvent("char")
		pressed(key)
		g.silica(term.native())
	end
elseif love then
	love.keypressed = pressed

	function love.draw()
		g.love(love)
		g.loveDepth(love, dispWidth)
	end
else
	error("Requires running in silica of Love")
end

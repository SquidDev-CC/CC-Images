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


local g = graphics
local debug = cclite and cclite.log or print
local clock, format = os.clock, string.format
local function profile(section, time) debug(format("[%.2f] %s: %.5f", clock(), section, time)) end

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
	g.triangle(
		a[1], a[2], a[3], -- colours[group[1]],
		b[1], b[2], b[3], -- colours[group[2]],
		c[1], c[2], c[3], colours[group[4]]
	)
end

local rotX, rotY = 0, 0
local x, y, z = 0, 0, 8

local function refreshMatrix()
	local start

	start = clock()
	local view = compose(unpack {
		transform.scale(1/20, 1/20, 1/20),
		transform.translate(-x, -y, -z),
		transform.rotateX(rotX),
		transform.rotateY(rotY),
	})
	local mvp = compose(projection, view)
	profile("Preparing MVP", clock() - start)

	g.clear()

	start = clock()
	local p = {}
	for k, v in pairs(verticies) do
		local coord = matrix.vector(mvp, v)
		if coord[4] == 0 then coord[4] = 1 print("SOMETHING IS 0", coord[3]) end
		coord[1] = coord[1] / coord[4]
		coord[2] = coord[2] / coord[4]
		p[k] = normalise(coord)
	end
	profile("Preparing Verticies", clock() - start)

	start = clock()
	for _, group in pairs(indexes) do
		draw(g, p, group)
	end
	profile("Drawing", clock() - start)
end

refreshMatrix()
local rotSpeed, speed = 0.01, 0.1

local changed = false
local function pressed(key)
	if key == "a" then
		rotY = (rotY + rotSpeed) % (2 * math.pi)
	elseif key == "d" then
		rotY = (rotY - rotSpeed) % (2 * math.pi)
	elseif key == "w" then
		rotX = (rotX + rotSpeed) % (2 * math.pi)
	elseif key == "s" then
		rotX = (rotX - rotSpeed) % (2 * math.pi)
	elseif key == "u" then
		z = z + speed
	elseif key == "p" then
		z = z - speed
	elseif key == "j" then
		x = x + speed
	elseif key == "l" then
		x = x - speed
	elseif key == "i" then
		y = y + speed
	elseif key == "k" then
		y = y - speed
	elseif key == "r" then
		rotY = 0
		rotX = 0
	end

	changed = true
end

if term then
	g.silica(term.native())
	local fps = 30
	local id = os.startTimer(1 / fps)
	while true do
		local e, arg = os.pullEvent()
		if e == "char" then
			pressed(arg)
		elseif e == "timer" and arg == id then
			if changed then
				local vStart = clock()
				refreshMatrix()
				changed = false

				local start = clock()
				g.silica(term.native())
				profile("Blitting", clock() - start)
				profile("TOTAL", clock() - start)
			end
			id = os.startTimer(1 / fps)
		end
	end
elseif love then
	love.keypressed = pressed

	function love.draw()
		if changed then
			refreshMatrix()
			changed = false
		end
		g.love(love)
		g.loveDepth(love, dispWidth)
	end
else
	error("Requires running in silica of Love")
end

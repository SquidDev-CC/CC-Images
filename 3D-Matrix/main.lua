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

local pairs, clock = pairs, os.clock
local project, draw = runner.project, runner.draw

local width, height = graphics.size()
local projection = transform.perspective(math.pi / 2, width / height, 0.01, 1000.0)

local rotX, rotY = 0, 0
local x, y, z = 0, 0, 8

local function refreshMatrix()
	local start = clock()

	local view = runner.compose(
		transform.scale(1/20, 1/20, 1/20),
		transform.translate(-x, -y, -z),
		transform.rotateX(rotX),
		transform.rotateY(rotY)
	)
	local mvp = runner.compose(projection, view)

	graphics.clear()
	graphics.clearColour({255, 0, 0, 0, 255})

	local p = {}
	for k, v in pairs(verticies) do
		p[k] = project(matrix.vector(mvp, v))
	end

	local sorted = {}
	for i, group in pairs(indexes) do
		local a, b, c = p[group[1]], p[group[2]], p[group[3]]
		sorted[i] = {group, a[3] + b[3] + c[3]}
	end
	table.sort(sorted, function(a, b) return a[2] > b[2] end)
	runner.profile("Prepare", clock() - start)

	start = clock()
	for _, group in pairs(sorted) do
		group = group[1]
		draw(p, group, colours[group[4]])
	end
	runner.profile("Drawing", clock() - start)
end

local rotSpeed, speed = 0.01, 0.1

local function pressed(event, key)
	if event ~= "char" then return false end

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
	else
		return false
	end

	return true
end

runner.setup(pressed, refreshMatrix, false)
runner.run(20)

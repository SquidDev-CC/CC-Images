local thisChunk = generation
local world = {['0.0.0'] = thisChunk}

local pairs, clock = pairs, os.clock

local width, height = graphics.size()
local projection = transform.perspective(math.pi / 2, width / height, 0.1, 6.0)

local rotX, rotY = 0.01, 0.8
local x, y, z = -0.2, 3.1, 9.7

local function refreshMatrix()
	local start

	start = clock()
	local view = runner.compose(
		transform.scale(1/5, 1/5, 1/5),
		transform.rotateY(-rotY),
		transform.rotateX(-rotX),
		transform.translate(-x, -y, -z)
	)
	local mvp = runner.compose(projection, view)
	runner.profile("Preparing MVP", clock() - start)

	graphics.clear()

	start = clock()
	chunk(world, mvp, x, y, z)
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
runner.run(10)

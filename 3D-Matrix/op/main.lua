local folder
if shell then
	folder = fs.getDir(shell.getRunningProgram())
else
	folder = "CC-Images/3D-Matrix/op"
end

local cache, env = {}, setmetatable({}, { __index = _ENV or getfenv()})
local function require(file)
	local cached = cache[file]
	if cached ~= nil then return cached end

	local func, msg = loadfile(fs.combine(folder, file .. ".lua"), env)
	if not func then error(msg, 2) end

	cached = func()
	cache[file] = cached
	return cached
end
env.require = require

local matrix = require "matrix"
local transform = require "transform"
local clip = require "clip"

local graphics = peripheral.wrap("left")
local sensor = peripheral.wrap("right")

local width, height = 430, 240
local fov = 70
local chunkDistance = 4
local projection = transform.perspective(math.rad(fov), width / height, 0.05, chunkDistance * 16 * 2)

local function compose(...)
	local result, items = ..., {select(2, ...)}
	for i = 1, #items do
		result = matrix.multiply4(result, items[i])
	end

	return result
end

local function normalise(coord)
	return {
		(coord[1] + 1) * width / 2,
		(coord[2] + 1) * height / 2,
	}
end

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

local function drawPoint(a, ...) graphics.addPoint(normalise(a), ...).setSize(5) end

local function drawLine(a, b, colour, opacity, width)
	local line = graphics.addLine(normalise(a), normalise(b), colour, opacity)
	if width then line.setWidth(width) end
end

local function drawTriangle(points, colour, opacity)
	for i = 1, #points do points[i] = normalise(points[i]) end
	graphics.addPolygon(colour, opacity, unpack(points))
end

local function drawTriangleOutline(points, colour, opacity, width)
	for i = 1, #points do points[i] = normalise(points[i]) end
	local line = graphics.addLineList(colour, opacity, unpack(points))
	if width then line.setWidth(width) end
end

local rotX, rotY = 0, 0
local x, y, z = 0, 0, 8

local player = sensor.getPlayerByName("ThatVeggie") or error("Cannot find")

local initialPosition = { x = 0.5, y = 0.5, z = 0.5 }


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

for i = 1, #colours do colours[i] = rgb(unpack(colours[i])) end

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
while true do
	counter = (counter + 0.005) % 1

	local pData = player.all()
	rotX = math.rad(pData.living.pitch)
	rotY = math.rad(pData.living.yaw)

	x = initialPosition.x - pData.position.x
	y = initialPosition.y - pData.position.y - 1.7
	z = initialPosition.z - pData.position.z

	local view = compose(
		transform.rotateX(-rotX),
		transform.rotateY(-rotY),
		transform.translate(-x, -y, -z)
	)

	local mvp = compose(projection, view)

	graphics.clear()
	-- byzanz-record --duration=15 --x=200 --y=300 --width=700 --height=400 out.gif
	--
	-- clip.line(
	-- 	mvp,
	-- 	{ -2, 0, 0, 1 },
	-- 	{ -2, 0, 4, 1 },
	-- 	drawLine,
	-- 	hsv(counter, 0.6, 1), 0.25, 3
	-- )
	--
	-- clip.line(
	-- 	mvp,
	-- 	{ -2, 0, 0, 1 },
	-- 	{ -2, 0, 4, 1 },
	-- 	drawLine,
	-- 	hsv(counter, 0.6, 1), 1, 1
	-- )

	clip.triangle(
		mvp,
		{ 0, 0, 0, 1 },
		{ 0, 0, 3, 1 },
		{ 3, 0, 0, 1 },
		drawTriangle,
		hsv(counter, 0.6, 1), 0.5
	)

	for i = 1, #indexes do
		local tri = indexes[i]
		local mid = tri[5]
		tri[6] = (mid[1] - x)^2 + (mid[2] - y)^2 + (mid[3] - z)^2
	end
	table.sort(indexes, sortDistance)
	for i = 1, #indexes do
		local tri = indexes[i]

		clip.triangle(
			mvp,
			verticies[tri[1]],
			verticies[tri[2]],
			verticies[tri[3]],
			drawTriangle,
			colours[tri[4]], 0.6
		)
	end

	graphics.addText(5, 5, (textutils.serialize(pData.living.lookingAt):gsub("%s+", " ")))
	graphics.addText(5, 15, (textutils.serialize(pData.position):gsub("%s+", " ")))
	graphics.addText(5, 25, (textutils.serialize({yaw = pData.living.yaw, pitch = pData.living.pitch}):gsub("%s+", " ")))

	graphics.sync()

	os.queueEvent("junk")
	while true do
		local e, arg = os.pullEvent()
		if e == "junk" then
			break
		elseif e == "key" and arg == keys.enter then
			graphics.clear()
			graphics.sync()
			return
		end
	end
end

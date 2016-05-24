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
local function drawLine(a, b, color, opacity, width)
	local line = graphics.addLine(normalise(a), normalise(b), color, opacity or 1)
	if width then
		line.setWidth(width)
	end
end
local function drawTriangle(a, b, c, ...) graphics.addTriangle(normalise(a), normalise(b), normalise(c), ...) end

local function triangleOutline(m, a, b, c, ...)
	clip.line(m, a, b, drawLine, ...)
	clip.line(m, a, c, drawLine, ...)
	clip.line(m, b, c, drawLine, ...)
end

local rotX, rotY = 0, 0
local x, y, z = 0, 0, 8

local player = sensor.getPlayerByName("ThatVeggie") or error("Cannot find")

local initialPosition = { x = 0.5, y = 0.5, z = 0.5 }

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

	clip.point(mvp, {0, 0, 0, 1}, drawPoint, rgb(255, 0, 0))

	clip.line(
		mvp,
		{ -2, 0, 0, 1 },
		{ -2, 0, 4, 1 },
		drawLine,
		hsv(counter, 0.6, 1), 0.25, 3
	)

	clip.line(
		mvp,
		{ -2, 0, 0, 1 },
		{ -2, 0, 4, 1 },
		drawLine,
		hsv(counter, 0.6, 1), 1, 1
	)

	triangleOutline(
		mvp,
		{ 0, 0, 0, 1 },
		{ 0, 0, 3, 1 },
		{ 3, 0, 0, 1 },
		rgb(0, 0, 255)
	)

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

local folder = fs.getDir(shell.getRunningProgram())
local function require(file)
	return dofile(fs.combine(folder, file .. ".lua"))
end

local matrix = require "matrix"
local transform = require "transform"
local clip = require "clip"

local graphics = peripheral.wrap("left")
local sensor = peripheral.wrap("right")

local width, height = 450, 250
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

local draw = clip(
	function(a, color) graphics.addPoint(normalise(a), color).setSize(5) end,
	function(a, b, color) graphics.addLine(normalise(a), normalise(b), color) end,
	function(a, b, c, color) graphics.addTriangle(normalise(a), normalise(b), normalise(c), color) end,
	matrix.multiply1
)

function draw.triangleOutline(m, a, b, c, col)
	draw.line(m, a, b, col)
	draw.line(m, a, c, col)
	draw.line(m, b, c, col)
end

local rotX, rotY = 0, 0
local x, y, z = 0, 0, 8

local player = sensor.getPlayerByName("ThatVeggie") or error("Cannot find")

local initialPosition = { x = 0.5, y = 0.5, z = 0.5 }

while true do
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

	draw.point(mvp, {0, 0, 0, 1}, rgb(255, 0, 0))

	draw.triangleOutline(
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

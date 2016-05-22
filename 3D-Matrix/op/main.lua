local folder = fs.getDir(shell.getRunningProgram())
local function require(file)
	return dofile(fs.combine(folder, file .. ".lua"))
end

local matrix = require "matrix"
local transform = require "transform"


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
	coord[1] = (coord[1] + 1) * width / 2
	coord[2] = (coord[2] + 1) * height / 2
	return coord
end

local function rgb(r, g, b)
	return r * 256^2 + g * 256 + b
end

local abs = math.abs
local function project(coord)
	if abs(coord[4]) < 1e-2 then
		local orig = coord[4]
		if coord[4] < 0 then
			coord[4] = -1e-2
		else
			coord[4] = 1e-2
		end
		-- debug("Resetting a coordinate", coord[1], coord[2], coord[3], coord[4], orig)
	end
	coord[1] = coord[1] / coord[4]
	coord[2] = coord[2] / coord[4]

	return normalise(coord)
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
		transform.scale(1/20, 1/20, 1/20),
		transform.rotateX(-rotX),
		transform.rotateY(-rotY),
		transform.translate(-x, -y, -z)
	)

	local mvp = compose(projection, view)

	graphics.clear()

	-- graphics.addLine({a[1], a[2]}, {b[1], b[2]}, colours[tri[4]])

	local p = project(matrix.multiply1(mvp, {0, 0, 0, 1}))
	graphics.addBox(p[1] - 50, p[2] - 50, 100, 50, rgb(20, 20, 20), 0.7)
	graphics.addPoint({p[1], p[2]}, rgb(255, 0, 0)).setSize(10)

	textutils.serialize(pData.living.lookingAt)
	graphics.addText(5, 5, (textutils.serialize(pData.living.lookingAt):gsub("%s+", " ")))
	graphics.addText(5, 15, (textutils.serialize(pData.position):gsub("%s+", " ")))
	graphics.addText(5, 25, (textutils.serialize({yaw = pData.living.yaw, pitch = pData.living.pitch}):gsub("%s+", " ")))
	graphics.sync()

	--[[
	local id = os.startTimer(0)
	while true do
		local e, x = os.pullEvent()
		if e == "timer" and x == id then
			break
		elseif e == "key" and x == keys.enter then
			graphics.clear()
			graphics.sync()
			return
		end
	end
	]]
end

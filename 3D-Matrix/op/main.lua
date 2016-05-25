-- Require utils
local folder = shell and fs.getDir(shell.getRunningProgram()) or "CC-Images/3D-Matrix/op"
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

-- Various settings
local width, height = 430, 240
local fov = 70
local chunkDistance = 4
local player = "ThatVeggie"

-- Get peripheral/player
local glasses = assert(peripheral.find("openperipheral_bridge"), "Cannot find glasses")
local sensor = assert(peripheral.find("openperipheral_sensor"), "Cannot find sensor")
local player = sensor.getPlayerByName(player) or error("Cannot find")

-- Load libraries
local matrix = require "matrix"
local transform = require "transform"
local clip = require "clip"

local projection = transform.perspective(math.rad(fov), width / height, 0.05, chunkDistance * 16 * 2)
local rotX, rotY = 0, 0
local x, y, z = 0, 0, 8

local graphics = require "graphics"(glasses, width, height)
local offset = { x = 0.5, y = 0.5, z = 0.5 }

local counter = 0
while true do
	counter = (counter + 0.005) % 1

	local pData = player.all()
	rotX = math.rad(pData.living.pitch)
	rotY = math.rad(pData.living.yaw)

	x = offset.x - pData.position.x
	y = offset.y - pData.position.y - 1.7
	z = offset.z - pData.position.z

	local view = matrix.compose(
		transform.rotateX(-rotX),
		transform.rotateY(-rotY),
		transform.translate(-x, -y, -z)
	)

	local mvp = matrix.compose(projection, view)

	glasses.clear()

	clip.polygon(
		mvp,
		{
			{ 0, 0, 0, 1 },
			{ 0, 0, 3, 1 },
			{ 3, 0, 0, 1 }
		},
		graphics.drawPolygon,
		graphics.hsv(counter, 0.6, 1), 0.5
	)

	glasses.sync()
end

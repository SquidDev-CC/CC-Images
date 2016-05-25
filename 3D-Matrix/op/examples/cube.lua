-- Require utils
local folder = shell and fs.getDir(fs.getDir(shell.getRunningProgram())) or "CC-Images/3D-Matrix/op"
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

for i = 1, #colours do colours[i] = graphics.rgb(unpack(colours[i])) end

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

	for i = 1, #indexes do
		local tri = indexes[i]
		local mid = tri[5]
		tri[6] = (mid[1] - x)^2 + (mid[2] - y)^2 + (mid[3] - z)^2
	end
	table.sort(indexes, sortDistance)
	for i = 1, #indexes do
		local tri = indexes[i]

		clip.polygon(
			mvp,
			{verticies[tri[1]],
			verticies[tri[2]],
			verticies[tri[3]]},
			graphics.drawPolygon,
			colours[tri[4]], 0.6
		)
	end

	glasses.addText(5, 5, (textutils.serialize(pData.living.lookingAt):gsub("%s+", " ")))
	glasses.addText(5, 15, (textutils.serialize(pData.position):gsub("%s+", " ")))
	glasses.addText(5, 25, (textutils.serialize({yaw = pData.living.yaw, pitch = pData.living.pitch}):gsub("%s+", " ")))

	glasses.sync()
end

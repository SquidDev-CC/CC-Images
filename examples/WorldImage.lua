--[[
	Renders an image to the screen
]]

local function resolve(path)
	return fs.combine(fs.getDir(shell.getRunningProgram()), path)
end

local function loadAPI(name)
	local env = setmetatable({}, {__index = getfenv()})

	local result = setfenv(loadfile(resolve("../" .. name .. ".lua")), env)()
	for k,v in pairs(result or {}) do return result end
	return env
end

-- Load the Graphics and CommandGraphics API
local Graphics = loadAPI("build/Graphics")
local CommandGraphics = loadAPI("Command-Graphics/build/CommandGraphics")

local parser = Graphics.ImageHelpers.parseFile(resolve("../data/CC.bmp"))

-- Create the Command block API
local commands = CommandGraphics.CommandGraphics("minecraft:redstone_block")
local pixel, clear, blockType = commands.setBlock, commands.clearBlocks, commands.setBlockType

local findClosest = Graphics.Colors.findClosestColor
-- local colors = Graphics.Colors.termSets
local colors = CommandGraphics.CommandColors

local unpack = unpack

local last = nil
-- Start a tranformation chain
local transform = CommandGraphics.TransformationChain(function(x, y, z, color)
	if color ~= last then
		-- blockType("minecraft:wool " .. math.log(findClosest(colors, unpack(color))) / math.log(2))
		blockType(findClosest(colors, unpack(color)))
		last = color
	end
	pixel(x, y, z)
end)
transform.scale(1, -1, 1) -- Flip on Y Axis
transform.translate(0, 3 + parser.height, -10) -- Offset positions

Graphics.ImageHelpers.drawImage(parser, transform.pixel2d)

print("Press any key to clear")
os.pullEvent("key")
-- We cache which blocks we placed so we don't place it more
-- than once, so it is trivial to clean up again.
clear()

-- Gobble char events
os.queueEvent("ignore") coroutine.yield("ignore")

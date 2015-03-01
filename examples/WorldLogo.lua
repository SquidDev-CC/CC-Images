--[[
	Renders the Computer Craft logo in the world
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

-- Create the Command block API
local commands = CommandGraphics.CommandGraphics("minecraft:wool 15")
local pixel, clear, blockType = commands.setBlock, commands.clearBlocks, commands.setBlockType

local offsetY = 3
local offsetZ = -10
local padding = 3

do -- Render the font
	local font = Graphics.FontHelpers.loadFont(loadAPI("data/ComicSans"))

	local transform = CommandGraphics.TransformationChain(pixel)

	-- Create a drawing API using the transformation chain's pixel
	local drawing  = Graphics.DrawingAPI(transform.pixel2d)


	do -- Main ComputerCraft
		local lines = Graphics.FontHelpers.createLines(font, "Computer\nCraft")

		local height = 20
		local scale = height / lines.maxHeight
		transform.scale(scale)
		transform.translate(0, offsetY, offsetZ)

		for yLine, line in ipairs(lines) do
			local y = ((#lines - yLine) * (height + 5))

			-- We will centre align the text
			local x = 0

			for _, glyph in ipairs(line) do
				-- We want to start a transformation section
				transform.push()
				transform.translate(x, y, 0) -- Translate to the glyph's position

				-- Draw the node list
				Graphics.FontHelpers.drawSVG(glyph.svg, drawing, height * 5)

				transform.pop()

				-- Move onto the next character. The translations happen after the scale so need to be scaled too.
				x = x + (glyph.width * scale) + padding

				-- Bezier curves take a long time. Lets yield quickly
				os.queueEvent("ignore")
				coroutine.yield()
			end
		end
	end

end

do -- Render the image
	local parser = Graphics.ImageHelpers.parseFile(resolve("../data/CC-Large.bmp"))

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

		if x == 1 then
			os.queueEvent("ignore")
			coroutine.yield()
		end
	end)
	transform.scale(1, -1, 1) -- Flip on Y Axis
	transform.translate(- padding - parser.width, offsetY + parser.height, offsetZ) -- Offset positions

	Graphics.ImageHelpers.drawImage(parser, transform.pixel2d)
end

print("Press any key to clear")
os.pullEvent("key")
-- We cache which blocks we placed so we don't place it more
-- than once, so it is trivial to clean up again.
clear()

-- Gobble char events
os.queueEvent("ignore") coroutine.yield("ignore")

--[[
	Renders a font to the world using the Command Graphics API and Font API
]]

local function loadAPI(name)
	name = fs.combine(fs.getDir(shell.getRunningProgram()), "../" .. name .. ".lua")
	local env = setmetatable({}, {__index = getfenv()})

	local result = setfenv(loadfile(name), env)()
	for k,v in pairs(result or {}) do return result end
	return env
end

-- Load the Graphics and CommandGraphics API
local Graphics = loadAPI("build/Graphics")
local CommandGraphics = loadAPI("Command-Graphics/build/CommandGraphics")

local args = {...}

-- We load a font with some data. This could easily be applied inline instead
local font = Graphics.FontHelpers.loadFont(loadAPI("data/ComicSans"))

local message, height, blockType
do -- Read with a prompt in front
	local function readPrompt(prompt)
		write(prompt .. "> ")
		return read()
	end

	-- Load some arguments. Allows "\n" in message as a literal "\n"
	message = (args[1] or readPrompt("Message")):gsub("\\n", "\n") .. "\n"
	height = assert(tonumber(args[2] or readPrompt("Max height")), "Invalid number")
	blockType = args[3] or "minecraft:wool 15"
end

-- Add padding between lines
local yPadding = 2
local xPadding =  1

-- Offset for drawing things
local xOffset = 0
local yOffset = 30
local zOffset = -10

-- We need to create the lines of text
local lines = Graphics.FontHelpers.createLines(font, message)

-- We have the max height, create a scale factor to translate letters
local scale = height / lines.maxHeight

-- Create the Command block API
local commands = CommandGraphics.CommandGraphics(blockType)
local pixel, clear = commands.setBlock, commands.clearBlocks

-- Start a tranformation chain
local transform = CommandGraphics.TransformationChain(pixel)
transform.scale(scale) -- This will scale everything input into it

-- Create a drawing API using the transformation chain's pixel
local drawing  = Graphics.DrawingAPI(transform.pixel2d)

-- Now we draw the lines
for yLine, line in ipairs(lines) do
	print("Line " .. string.format("%q", line.contents))

	--[[
		We have the number of lines. As each line is written above, the earlier lines
		need to be written higher up. Each line is height + yPadding tall
	]]
	local y = ((#lines - yLine) * (height + yPadding))

	-- We will centre align the text
	local x = -(line.width * scale) / 2

	for _, glyph in ipairs(line) do
		-- We want to start a transformation section
		transform.push()
		transform.translate(x, y, 0) -- Translate to the glyph's position
		transform.rotate(-45, 30, -10) -- Rotate it so it looks groovy

		--[[
			Offset the entire text by a set ammount.
			We do this afterwards so the rotation doesn't happen around the computer but around the offsets
		]]
		transform.translate(xOffset, yOffset, zOffset)

		-- Draw the node list
		Graphics.FontHelpers.drawSVG(glyph.svg, drawing, height * 5)

		transform.pop()

		-- Move onto the next character. The translations happen after the scale so need to be scaled too.
		x = x + (glyph.width * scale) + xPadding

		-- Bezier curves take a long time. Lets yield quickly
		os.queueEvent("ignore")
		coroutine.yield()
	end
end

print("Press any key to clear")
os.pullEvent("key")
-- We cache which blocks we placed so we don't place it more
-- than once, so it is trivial to clean up again.
clear()

-- Gobble char events
os.queueEvent("ignore") coroutine.yield("ignore")

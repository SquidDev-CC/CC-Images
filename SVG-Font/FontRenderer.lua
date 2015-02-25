local args = {...}

local font = FontHelpers.loadFont(FontData)
local message, height, blockType

do
	--- Read with a prompt in front
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

local lines = FontHelpers.createLines(font, message)

-- We have the max height, create a scale factor to translate letters
local scale = height / lines.maxHeight

-- Create the Command block API
local commands = CommandGraphics(blockType)
local pixel, clear = commands.setBlock, commands.clearBlocks

local transform = TransformationChain(pixel)
transform.scale(scale)

-- Create a drawing API
local drawing  = DrawingAPI(transform.pixel2d)
local drawLine, drawBezier = drawing.line, drawing.bezier

for yLine, line in ipairs(lines) do
	print("Line " .. string.format("%q", line.contents))
	local y = ((#lines - yLine) * (height + yPadding))

	-- We will centre align the drawing
	local x = -(line.width * scale) / 2

	for _, glyph in ipairs(line) do
		transform.push()
		transform.translate(x, y, 0)
		transform.rotate(-45, 30, -10)
		transform.translate(xOffset, yOffset, zOffset)

		-- Draw the node list
		for _, node in ipairs(glyph.svg) do
			local nodeType = node[1]
			local nodeArgs = node[2]

			if nodeType == "L" then -- Lines
				drawLine(unpack(nodeArgs))
			else -- If C or Q then bezier line
				drawBezier(nodeArgs, height * 10)
			end
		end

		transform.pop()

		-- Move onto the next character
		x = x + (glyph.width * scale) + xPadding

		os.queueEvent("test")
		coroutine.yield("test")
	end
end

print("Press any key to clear")
os.pullEvent("key")
-- We cache which blocks we placed so we don't place it more
-- than once, so it is trivial to clean up again.
clear()


-- Gobble char events
os.queueEvent("test")
coroutine.yield("test")

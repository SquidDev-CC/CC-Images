local args = {...}

local ipairs, unpack = ipairs, unpack

--- Read with a prompt in front
local function readPrompt(prompt)
	write(prompt .. "> ")
	return read()
end

-- Load some arguments. Allows "\n" in message as a literal "\n"
local message = (args[1] or readPrompt("Message")):gsub("\\n", "\n")
local height = assert(tonumber(args[2] or readPrompt("Max height")), "Invalid number")
local blockType = args[3] or "minecraft:wool 15"

-- Add padding between lines
local yPadding = 2
local xPadding =  -10

-- Offset for drawing things
local xOffset = 0
local yOffset = 20
local zOffset = -20

-- Load SVG and set characters
for character, glyph in pairs(FontData) do
	glyph.svg = SVGParser(glyph.svg)
	glyph.character = character
end

local maxHeight = 0 -- Max height of the text

local line = {width = 0, contents = ""}
local lines = {line} -- Number of lines to write
local maxWidth = 0

for i = 1, #message do
	local character = message:sub(i, i)

	-- Start a new line if \n
	if character == "\n" then
		line = {width = 0, contents = ""}
		lines[#lines + 1] = line
	else
		local glyph = FontData[character]
		-- Support numbers in lookup table
		if not glyph and tonumber(glyph) then
			glyph = FontData[tonumber(glyph)]
		end

		-- Still can't find glyph
		if not glyph then
			error("Unexpected character " .. string.format("%q", character))
		end

		-- Find max glyph height
		maxHeight = math.max(maxHeight, glyph.height)
		line[#line + 1] = glyph

		-- Calculate some line data
		line.width = line.width + glyph.width
		line.contents = line.contents .. character
	end
end

-- We have the max height, create a scale factor to translate letters
local scale = height / maxHeight

local clearItems = {}

-- Create the Command block API
local commands = CommandGraphics(blockType)
local pixel, clear = commands.setBlock, commands.clearBlocks

--- XOff and YOff are offsets in block scale
local xOff, yOff

-- We want to scale the pixel to prevent having 2000 block high letters
local function scalePixel(x, y)
	pixel(x * scale + xOff + xOffset, y * scale + yOff + yOffset, zOffset)
end

-- Create a drawing API
local drawing  = DrawingAPI(scalePixel)
local drawline, drawBezier = drawing.line, drawing.bezier

for yLine, line in ipairs(lines) do
	yOff = ((#lines - yLine) * (height + yPadding))
	xOff = -(line.width * scale) / 2

	print("Line " .. string.format("%q", line.contents))

	for _, glyph in ipairs(line) do
		-- Draw the node list
		for _, node in ipairs(glyph.svg) do
			local nodeType = node[1]
			local nodeArgs = node[2]

			if nodeType == "L" then -- Lines
				drawline(unpack(nodeArgs))
			else -- If C or Q then bezier line
				drawBezier(nodeArgs)
			end
		end

		-- Move onto the next character
		xOff = xOff + (glyph.width * scale) + xPadding
	end
end

print("Press any key to clear")
os.pullEvent("char")
-- We cache which blocks we placed so we don't place it more
-- than once, so it is trivial to clean up again.
clear()


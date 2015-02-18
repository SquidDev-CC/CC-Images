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
local xPadding =  1

-- Offset for drawing things
local xOffset = 0
local yOffset = 20
local zOffset = -20

-- Load SVG and set characters
for character, glyph in pairs(ComicSans) do
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
		local glyph = ComicSans[character]
		-- Support numbers in lookup table
		if not glyph and tonumber(glyph) then
			glyph = ComicSans[tonumber(glyph)]
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

-- Create a drawing API
local drawing  = DrawingAPI()
local drawline, drawBezier, drawSetPixel = drawing.line, drawing.bezier, drawing.setPixel

for yLine, line in ipairs(lines) do
	local y = ((#lines - yLine) * (height + yPadding))
	local x = -(line.width * scale) / 2

	print("Line " .. string.format("%q", line.contents))

	for _, glyph in ipairs(line) do
		-- Construct a new CommandGraphics instance for drawing this one letter
		local commands = CommandGraphics(blockType, x + xOffset, y + yOffset, zOffset)
		local pixel, clear = commands.pixel, commands.clear

		-- We want to scale the pixel to prevent having 2000 block high letters
		local function scalePixel(x, y)
			pixel(x * scale, y * scale)
		end

		-- Create a new DrawingAPI
		drawSetPixel(scalePixel)

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
		x = x + (glyph.width * scale) + xPadding

		-- Add a handler to clear the character
		clearItems[#clearItems + 1] = clear
	end
end

print("Press any key to clear")
os.pullEvent("char")

local len = #clearItems
if len > 30 then
	print("Clearing " .. len .. " items, this may take some time")
end

-- We cache which blocks we placed so we don't place it more
-- than once, so it is trivial to clean up again.
for _, clear in ipairs(clearItems) do
	clear()
end

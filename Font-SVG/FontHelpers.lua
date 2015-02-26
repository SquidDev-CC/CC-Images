local max, tonumber, setmetatable, unpack, ipairs, pairs = math.max, tonumber, setmetatable, unpack, ipairs, pairs

--- Draw a svg path
-- @tparam table svg List of svg nodes to use
-- @tparam DrawingAPI drawing An instance of the drawing API object
-- @tparam int resolution Resolution of the bezier curves
local function drawSVG(svg, drawing, resolution)
	local drawLine, drawBezier = drawing.line, drawing.bezier

	for _, node in ipairs(svg) do
		local nodeType = node[1]
		local nodeArgs = node[2]

		if nodeType == "L" then -- Lines
			drawLine(unpack(nodeArgs))
		else -- If B then bezier curve
			drawBezier(nodeArgs, resolution)
		end
	end
end

--- Load SVG and set characters
local function loadFont(font)
	for character, glyph in pairs(font) do
		glyph.svg = SVGParser(glyph.svg)
		glyph.character = character
	end

	return font
end

--- Create a line object
local function createLine(font, text)
	local line = {}
	local width = 0
	local height = 0
	local contents = ""

	for i = 1, #text do
		local character = text:sub(i, i)

		local glyph = font[character]

		-- Support numbers in lookup table
		if not glyph and tonumber(character) then
			glyph = font[tonumber(character)]
		end

		-- Still can't find glyph
		if not glyph then
			error("Unexpected character " .. string.format("%q", character))
		end

		line[#line + 1] = glyph

		-- Calculate properties of the line
		width = width + glyph.width
		height = max(height, glyph.height)
		contents = contents .. character
	end

	line.width = width
	line.height = height
	line.contents = contents

	return line
end

local function createLines(font, text)
	local lines = {}
	local maxHeight = 0
	local maxWidth = 0

	text:gsub("([^\n]*)\n?", function(c)
		local line = createLine(font, c)
		lines[#lines + 1] = line
		maxHeight = max(maxHeight, line.height)
		maxWidth = max(maxWidth, line.width)
	end)

	-- Remove last line
	if lines[#lines].contents == "" then
		lines[#lines] = nil
	end

	lines.maxHeight = maxHeight
	lines.maxWidth = maxWidth

	return lines
end


return {
	drawSVG = drawSVG,
	loadFont = loadFont,
	createLine = createLine,
	createLines = createLines,
}

--- Parses SVG path data
-- TODO: Implement relative points

local find, sub, tonumber = string.find, string.sub, tonumber
local error, tostring = error, tostring

-- Consume all the whitespace
local function consumeWhitespace(string, position)
	local startOf, endOf = find(string, "[%s,]+", position)

	if startOf ~= position then
		return position
	end

	return endOf + 1
end

-- Parse a number
local function parseNumber(string, position)
	-- Trim whitespace
	position = consumeWhitespace(string, position)

	local startOf, endOf = find(string, "%-?%d+", position)
	if startOf ~= position then
		if position > #string then
			error("Expected number near <eof>")
		else
			error("Expected number at " .. position .. " near " .. string.format("%q", sub(string, position, position)))
		end
	end

	return tonumber(sub(string, startOf, endOf)), endOf + 1
end

-- Parse a coordinate pair
local function parsePair(string, position)
	local x, y
	x, position = parseNumber(string, position)
	y, position = parseNumber(string, position)

	return x, y, position
end

local allowed = { M=true, L=true, Q = true, C = true, Z = true}
local function parseCommand(string, position)
	local nextCharacter = sub(string, position, position)
	if not allowed[nextCharacter] then
		error("Expected (M/L/Q/C/Z) at " .. position .. " near " .. string.format("%q", nextCharacter))
	end

	return nextCharacter, position + 1
end

-- Parses an SVG string
-- @tparam string string The SVG path to parse
-- @tparam boolean implicitClose Close the current path on a move
local function parseSVG(string, implicitClose)
	local position = 1
	local length = #string

	local SVG = {}
	local SVGNext = 1

	local startX, startY = 0, 0
	local currentX, currentY = 0, 0

	local function close()
		-- If one of the points is different draw a line
		if currentX ~= startX or currentY ~= startY then
			SVG[SVGNext] = {"L", {currentX, currentY, startX, startY}}
			return startX, startY
		end
		return currentX, currentY
	end

	while position <= length do
		-- Consume whitespace
		position = consumeWhitespace(string, position)

		-- Check that didn't break anything
		if position > length then break end

		local nextCharacter
		nextCharacter, position = parseCommand(string, position)

		local x, y = currentX, currentY

		-- Jump drawing point (M <x> <y>)
		if nextCharacter == "M" then
			-- We are moving, and so should close the path
			if implicitClose then
				x, y = close()
			end

			-- We just update the current x/y instead of storing this as an item
			x, y, position = parsePair(string, position)
			startX, startY = x, y

		-- Close path
		elseif nextCharacter == "Z" then
			x, y = close()

		-- Line from current position to x, y (L <x> <y>)
		elseif nextCharacter == "L" then
			x, y, position = parsePair(string, position)

			-- Save to data list
			SVG[SVGNext] = {"L", {currentX, currentY, x, y}}
			SVGNext = SVGNext + 1

			-- Update positions
			currentX = x
			currentY = y

		-- Cubic Bezier from current to x, y with points at <(x/y)(1/2)> (C <x1> <y1>, <x2> <y2>, <x> <y>)
		elseif nextCharacter == "C" then
			local x1, y1, x2, y2
			x1, y1, position = parsePair(string, position)
			x2, y2, position = parsePair(string, position)
			x, y, position = parsePair(string, position)

			-- Save to datalist
			SVG[SVGNext] = {"B", {currentX, currentY, x1, y1, x2, y2, x, y}}
			SVGNext = SVGNext + 1

			-- Update positions
			currentX = x
			currentY = y

		-- Quadratic Bezier from current to x, y with point at <(x/y)1> (C <x1> <y1>, <x> <y>)
		elseif nextCharacter == "Q" then
			local x1, y1
			x1, y1, position = parsePair(string, position)
			x, y, position = parsePair(string, position)

			-- Save to datalist
			SVG[SVGNext] = {"B", {currentX, currentY, x1, y1, x, y}}
			SVGNext = SVGNext + 1

			-- Update positions
			currentX = x
			currentY = y
		else
			error("Totaly unexpected " .. nextCharacter .. " at " .. position)
		end

		-- Update positions
		currentX = x
		currentY = y
	end

	return SVG
end

return parseSVG

local execAsync = commands.native.execAsync
local floor = math.florr

-- Creates a command
return function(block, xOffset, yOffset)
	local drawn = {}

	local function pixel(x, y)
		x, y = floor(x), floor(y)

		local xDrawn = drawn[x]
		if xDrawn then
			-- Prevent drawing overlapping items
			if xDrawn[y] then
				return
			else
				xDrawn[y] = true
			end
		else
			drawn[x] = {[y] = true}
		end

		local command = "setblock ~" .. (x + xOffset) .. " ~" .. (y + yOffset) .. " ~ " .. block
		execAsync(command)
	end

	return pixel
end

local execAsync = commands.native.execAsync
local floor = math.floor

-- Creates a command
return function(block, xOffset, yOffset, zOffset)
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

		local command = "setblock ~" .. (x + xOffset) .. " ~" .. (y + yOffset) .. " ~" .. zOffset .. " " .. block
		execAsync(command)
	end

	local function clear()
		for x, items in pairs(drawn) do
			for y, _ in pairs(items) do
				execAsync( "setblock ~" .. (x + xOffset) .. " ~" .. (y + yOffset) .. " ~" .. zOffset .. " minecraft:air")
			end
		end
		drawn = {}
	end

	return {
		pixel = pixel,
		clear = clear,
	}
end

local heightmap = {
	1, 2, 3, 4, 5, 6, 5, 4,
	1, 1, 2, 3, 4, 5, 7, 7,
	1, 1, 1, 2, 3, 4, 6, 7,
	1, 1, 2, 4, 5, 6, 7, 8,
	1, 1, 2, 4, 7, 7, 8, 8,
	1, 3, 3, 4, 5, 6, 7, 7,
	1, 2, 3, 4, 5, 6, 6, 7,
	1, 2, 3, 4, 5, 6, 6, 7,
}

local colour = {242, 178, 204}
local function fromHeightMap(map)
	local chunk = {}
	for x = 1, 8 do
		for z = 1, 8 do
			local offset = x + (z - 1) * 64
			for height = 1, map[x + (z - 1) * 8] do
				chunk[offset + (height - 1) * 8] = colour
			end
		end
	end

	return chunk
end

return fromHeightMap(heightmap)

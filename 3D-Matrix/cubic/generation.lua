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


local grassSide = {
	"5","5","5","5","5","5","d","d",
	"d","c","5","d","c","5","5","5",
	"c","c","5","c","c","c","c","5",
	"c","c","c","c","c","c","c","c",
	"c","8","c","c","c","c","c","c",
	"c","c","c","c","c","c","8","c",
	"7","c","c","c","c","c","c","c",
	"c","c","c","c","c","c","c","c",
}

local grassTop = {
	"5", "5", "5", "5", "5", "5", "5", "5", "5",
	"5", "5", "5", "5", "5", "5", "5", "5", "5",
	"5", "5", "5", "5", "d", "d", "5", "5", "5",
	"5", "5", "5", "5", "d", "5", "5", "5", "5",
	"5", "5", "5", "5", "5", "5", "d", "d", "5",
	"5", "5", "d", "5", "5", "5", "5", "d", "5",
	"5", "5", "d", "d", "5", "5", "5", "5", "5",
	"5", "5", "5", "5", "5", "5", "5", "5", "5",
}

local dirt = {
	"c", "c", "c", "c", "c", "c", "c", "c",
	"c", "c", "c", "c", "c", "c", "8", "c",
	"c", "c", "c", "7", "c", "c", "c", "c",
	"c", "c", "8", "c", "c", "c", "c", "c",
	"c", "c", "c", "c", "7", "c", "c", "c",
	"c", "c", "7", "c", "c", "c", "c", "c",
	"c", "c", "c", "c", "c", "8", "c", "c",
	"c", "c", "c", "c", "c", "c", "c", "c",
}


local grass = {grassSide, grassSide, grassTop, dirt, grassSide, grassSide}
local dirt = {dirt, dirt, dirt, dirt, dirt, dirt}
local function fromHeightMap(map)
	local chunk = {}
	for x = 1, 8 do
		for z = 1, 8 do
			local offset = x + (z - 1) * 64
			local height = map[x + (z - 1) * 8]
			for y = 1, height do
				local block = dirt
				if y == height then
					block = grass
				end
				chunk[offset + (y - 1) * 8] = block
			end
		end
	end

	return chunk
end

return fromHeightMap(heightmap)
-- return {grass, [9] = grass}

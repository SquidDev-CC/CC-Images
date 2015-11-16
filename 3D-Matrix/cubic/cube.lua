local side = {
	{ -1,  0,  0 }, -- South
	{  1,  0,  0 }, -- North
	{  0,  1,  0 }, -- Top
	{  0, -1,  0 }, -- Bottom
	{  0,  0, -1 }, -- West
	{  0,  0,  1 }, -- East
}

local positions = {
	{ { 0, 0, 0 }, { 0, 0, 1 }, { 0, 1, 0 }, { 0, 1, 1 } },
	{ { 1, 0, 0 }, { 1, 0, 1 }, { 1, 1, 0 }, { 1, 1, 1 } },
	{ { 0, 1, 0 }, { 0, 1, 1 }, { 1, 1, 0 }, { 1, 1, 1 } },
	{ { 0, 0, 0 }, { 0, 0, 1 }, { 1, 0, 0 }, { 1, 0, 1 } },
	{ { 0, 0, 0 }, { 0, 1, 0 }, { 1, 0, 0 }, { 1, 1, 0 } },
	{ { 0, 0, 1 }, { 0, 1, 1 }, { 1, 0, 1 }, { 1, 1, 1 } }
}

local uvs = {
	{ { 1, 1 }, { 0, 1 }, { 1, 0 }, { 0, 0 } },
	{ { 0, 1 }, { 1, 1 }, { 0, 0 }, { 1, 0 } },
	{ { 1, 0 }, { 1, 1 }, { 0, 0 }, { 0, 1 } },
	{ { 1, 1 }, { 1, 0 }, { 0, 1 }, { 0, 0 } },
	{ { 1, 1 }, { 1, 0 }, { 0, 1 }, { 0, 0 } },
	{ { 0, 1 }, { 0, 0 }, { 1, 1 }, { 1, 0 } },
}

local indicies = {
	{ 1, 4, 3, 1, 2, 4 },
	{ 1, 4, 2, 1, 3, 4 },
	{ 1, 4, 3, 1, 2, 4 },
	{ 1, 4, 2, 1, 3, 4 },
	{ 1, 4, 3, 1, 2, 4 },
	{ 1, 4, 2, 1, 3, 4 }
}

local insert = table.insert
local function face(verticies, buffer, x, y, z, side, texture)
	local ind = indicies[side]
	local pos = positions[side]
	local uv = uvs[side]

	local triangle = {}
	local offset = 0
	for i = 1, 6 do
		local j = ind[i]
		local text, ver = uv[j], pos[j]
		insert(triangle, verticies(
			x + ver[1],
			y + ver[2],
			z + ver[3]
		))
		insert(triangle, text[1])
		insert(triangle, text[2])

		if i % 3 == 0 then
			-- Here we could insert the texture
			insert(triangle, texture[side])
			insert(buffer, triangle)
			triangle = {}
		end
	end
end

local function makeVertexCache(cache)
	local lookup, buffer = {}, {}
	local index = 1

	local function add(x, y, z)
		local offset = x + 9 * (y - 1) + 81 * (z - 1)
		local value = lookup[offset]
		if not value then
			buffer[index] = {x, y, z, 1}
			lookup[offset] = index
			value = index
			index = index + 1
		end

		local vec = buffer[lookup[offset]]
		if vec[1] ~= x or vec[2] ~= y or vec[3] ~= z or vec[4] ~= 1 then
			print("Expected:", x, y, z, 1)
			print("Actual:  ", vec[1], vec[2], vec[3], vec[4])
			print("Index:   ", offset, lookup[offset], vec[1] + 9 * (vec[2] - 1) + 81 * (vec[3] - 1))
		end

		return value
	end

	return add, buffer
end

return {
	side = side,
	face = face,
	makeVertexCache = makeVertexCache,
}

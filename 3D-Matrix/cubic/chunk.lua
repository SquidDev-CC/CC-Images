--- Handles universe and chunk interaction: mainly mesh generation/building

--- Get a block, including from neighbouring chunks
local function getBlock(chunk, x, y, z)
	if not chunk then return end

	if x < 1 then
		chunk = chunk.south
		if not chunk then return end
		x = x + 8
	elseif x > 8 then
		chunk = chunk.north
		if not chunk then return end
		x = x - 8
	end

	if y < 1 then
		chunk = chunk.bottom
		if not chunk then return end
		y = y + 8
	elseif y > 8 then
		chunk = chunk.top
		if not chunk then return end
		y = y - 8
	end

	if z < 1 then
		chunk = chunk.west
		if not chunk then return end
		z = z + 8
	elseif z > 8 then
		chunk = chunk.east
		if not chunk then return end
		z = z - 8
	end

	return chunk, chunk[x + (y - 1) * 8 + (z - 1) * 256]
end

--- Should a face be rendered
-- It is only shown if we know that there won't be one there.
local function shouldShowFace(chunk, x, y, z, side)
	x = x + side[1]
	y = y + side[2]
	z = z + side[3]

	local chunk, other = getBlock(chunk, x, y, z)

	-- If we have no neighbouring chunk then we can hide
	if not chunk then return true end -- TODO: Invert me!

	-- Otherwise we should only render if we have a neighbour
	return other == nil
end

local face, side, vertex = cube.face, cube.side, cube.makeVertexCache

--- An rather complicated method of creating the mesh
-- This 'grows' triangles which allows us
local function buildRow(verticies, buffer, chunk, x, y, z, tX, tY, tZ, sideNumber)
	local vector = side[sideNumber]

	for i = 1, 8 do
		local offset = x + 8 * (y - 1) + 64 * (z - 1)
		local block = chunk[offset]

		if block and shouldShowFace(chunk, x, y, z, vector) then
			-- TODO: Add texture
			face(verticies, buffer, x, y, z, sideNumber, block)
		end

		x = x + tX
		y = y + tY
		z = z + tZ
	end
end

local function build(chunk)
	local verticies, vertexBuffer = vertex()
	local indexBuffer = {}

	for y = 1, 8 do
		for z = 1, 8 do
			buildRow(verticies, indexBuffer, chunk, 1, y, z, 1, 0, 0, 3) -- Top and Bottom
			buildRow(verticies, indexBuffer, chunk, 1, y, z, 1, 0, 0, 4)
		end
	end

	for x = 1, 8 do
		for y = 1, 8 do
			buildRow(verticies, indexBuffer, chunk, x, y, 1, 0, 0, 1, 2) -- North and South
			buildRow(verticies, indexBuffer, chunk, x, y, 1, 0, 0, 1, 1)
		end
	end

	for z = 1, 8 do
		for y = 1, 8 do
			buildRow(verticies, indexBuffer, chunk, 1, y, z, 1, 0, 0, 6) -- East and West
			buildRow(verticies, indexBuffer, chunk, 1, y, z, 1, 0, 0, 5)
		end
	end

	chunk.vertex = vertexBuffer
	chunk.index = indexBuffer
	chunk.empty = #indexBuffer == 0
	chunk.changed = false

	-- for k,v in pairs(indexBuffer) do print(v[1], v[2], v[3], v[4], "|", t(vertexBuffer[v[1]]), t(vertexBuffer[v[2]]), t(vertexBuffer[v[3]])) end
end

local line, triangle = graphics.line, graphics.triangle
local function draw(verticies, group)
	local a, b, c = verticies[group[1]], verticies[group[4]], verticies[group[7]]

	if true then
		triangle(
			a[1], a[2], a[3], group[2], group[3],
			b[1], b[2], b[3], group[5], group[6],
			c[1], c[2], c[3], group[8], group[9],
			group[10]
		)
	else
		line(
			a[1], a[2], a[3], group[2], group[3],
			b[1], b[2], b[3], group[5], group[6],
			group[10]
		)
		line(
			a[1], a[2], a[3], group[2], group[3],
			c[1], c[2], c[3], group[8], group[9],
			group[10]
		)
		line(
			c[1], c[2], c[3], group[8], group[9],
			b[1], b[2], b[3], group[5], group[6],
			group[10]
		)
	end
end


local pairs = pairs
local mulpVector = matrix.vector
local normalise = runner.normalise

local abs = math.abs
local function project(coord)
	if abs(coord[4]) < 1e-2 then
		local orig = coord[4]
		if coord[4] < 0 then
			coord[4] = -1e-2
		else
			coord[4] = 1e-2
		end
		-- runner.debug("Resetting a coordinate", coord[1], coord[2], coord[3], coord[4], orig)
	end
	coord[1] = coord[1] / coord[4]
	coord[2] = coord[2] / coord[4]

	return normalise(coord)
end
local function render(chunk, mvp)
	if chunk.changed ~= false then build(chunk) end
	if chunk.empty then return end

	local verticies = {}
	-- TODO: Convert to for number loop?
	for k, v in pairs(chunk.vertex) do
		verticies[k] = project(mulpVector(mvp, v))
	end

	for _, k in pairs(chunk.index) do
		draw(verticies, k)
	end
end

local renderOffsets = {
	0, 0, 0,
	-1, 0, 0,
	0, -1, 0,
	0, 0, -1,
	0, 0, 1,
	0, 1, 0,
	1, 0, 0,
	-1, -1, 0,
	-1, 0, -1,
	-1, 0, 1,
	-1, 1, 0,
	0, -1, -1,
	0, -1, 1,
	0, 1, -1,
	0, 1, 1,
	1, -1, 0,
	1, 0, -1,
	1, 0, 1,
	1, 1, 0,
	-1, -1, -1,
	-1, -1, 1,
	-1, 1, -1,
	-1, 1, 1,
	1, -1, -1,
	1, -1, 1,
	1, 1, -1,
	1, 1, 1,
}

local compose, translate, mulpMatr = runner.compose, transform.translate, matrix.matrix
local center = {4, 4, 4, 1}
local abs, floor = math.abs, math.floor
local function drawUniverse(batch, mvp, x, y, z)
	for i = 1, #renderOffsets, 3 do
		local cX = floor(x / 8) + renderOffsets[i]
		local cY = floor(y / 8) + renderOffsets[i + 1]
		local cZ = floor(z / 8) + renderOffsets[i + 2]
		-- Lazy hash functions!
		local chunk = batch[cX .. "." .. cY .. "." .. cZ]
		if chunk then
			-- local model = mulpMatr(translate(cX * 8, cY * 8, cZ * 8), mvp)
			render(chunk, mvp)
			-- local center = mulpVector(model, center)

			-- print(cX, cY, cZ, chunk)
			-- print(center[1], center[2], center[3], center[4])

			-- if center[3] >= -4 then
			-- 	local w = center[4]
			-- 	center[1] = center[1] / w
			-- 	center[2] = center[2] / w

			-- 	local offset = abs(4 / w) + 1
			-- 	if abs(center[1]) <= offset and abs(center[2]) <= offset then
			-- 		render(chunk, model)
			-- 	end
			-- end
		end
	end
end

return drawUniverse

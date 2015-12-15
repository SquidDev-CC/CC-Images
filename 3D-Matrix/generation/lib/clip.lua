--- Clip a coordinate
-- @tparam number x X coordinate
-- @tparam number y Y coordinate
-- @tparam number z Z coordinate
-- @tparam number w Width to clip to
-- @treturn[1] boolean If the coordinate is within the clip bounds
-- @treturn[2, 3, 4] number For each coordinate. -1 if too small, 1 if too large, 0 if within the bounds
local function makeClip(x, y, z, w)
	-- Slight leeway to avoid rounding
	w = w * 1.00001
	local xC, yC, zC = 0, 0, 0

	local valid = true
	if x < -w then
		xC = -1
		valid = false
	elseif x > w then
		xC = 1
		valid = false
	end

	if y < -w then
		yC = -1
		valid = false
	elseif y > w then
		yC = 1
		valid = false
	end

	if z < -w then
		zC = -1
		valid = false
	elseif z > w then
		zC = 1
		valid = false
	end

	return valid, xC, yC, zC
end

local function clipProject(trans)
	local valid, xC, yC, zC = makeClip(trans[1], trans[2], trans[3], trans[4])

	local clip = {valid, xC, yC, zC}

	local projected
	if valid then
		local inv = 1 / trans[4]
		projected = {trans[1] * inv, trans[2] * inv, trans[3] * inv, trans[4]}
	end

	return trans, clip, projected
end

local function transform(vertex, matrix)
	return clipProject(vector(matrix, vertex))
end

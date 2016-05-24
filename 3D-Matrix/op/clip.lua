local vector = require "matrix".multiply1

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

local function transform(vertex, matrix)
	local trans = vector(matrix, vertex)
	local valid, xC, yC, zC = makeClip(trans[1], trans[2], trans[3], trans[4])

	local clip = {valid, xC, yC, zC}

	local projected
	if valid then
		local inv = 1 / trans[4]
		projected = {trans[1] * inv, trans[2] * inv, trans[3] * inv, trans[4]}
	end

	return trans, clip, projected
end

--- Interpolate between to points
-- @tpram matrix ver1 The first vertex
-- @tparam matrix ver2
local function interpolate(ver_1, ver_2, t)
	local x, y, z, w = ver_1[1], ver_1[2], ver_1[3], ver_1[4]
	local newW = w + (ver_2[4] - w) * t
	local inv = 1 / newW
	return {
		(x + (ver_2[1] - x) * t) * inv,
		(y + (ver_2[2] - y) * t) * inv,
		(z + (ver_2[3] - z) * t) * inv,
		newW
	}
end

local function pointComplete(matrix, vertex_1, drawPoint, ...)
	local trans_1, clip_1, proj_1 = transform(vertex_1, matrix)

	if clip_1[1] then drawPoint(proj_1, ...) end
end

-- Adaptation of https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
-- but using a parametric equation and no loop
local function trimLine(trans_1, clip_1, proj_1, trans_2, clip_2, proj_2)
	if clip_1[1] and clip_2[1] then return proj_1, proj_2
	elseif
		(clip_1[2] ~= 0 and clip_1[2] == clip_2[2]) or
		(clip_1[3] ~= 0 and clip_1[3] == clip_2[3]) or
		(clip_1[4] ~= 0 and clip_1[4] == clip_2[4])
	then
		-- As they are all clipped on at least one side then hide
		-- For example if they are both too far to the left.
		return
	else
		-- Prepare to clip everything

		local x1, y1, z1, w1 = trans_1[1], trans_1[2], trans_1[3], trans_1[4]
		local dx, dy, dz, dw = trans_2[1] - x1, trans_2[2] - y1, trans_2[3] - z1, trans_2[4] - w1

		-- This is auto-generated, hence the fact it is really ugly:
		local tmin, tmax = 0, 1
		local denom, num = dx + dw, -x1 - w1
		if denom > 0 then
			local t = num / denom
			if t > tmax then return elseif t > tmin then tmin = t if tmin == tmax then return end end
		elseif denom < 0 then
			local t = num / denom
			if t < tmin then return elseif t < tmax then tmax = t if tmin == tmax then return end end
		elseif num > 0 then
			return
		end

		denom, num = -dx + dw, x1 - w1
		if denom > 0 then
			local t = num / denom
			if t > tmax then return elseif t > tmin then tmin = t if tmin == tmax then return end end
		elseif denom < 0 then
			local t = num / denom
			if t < tmin then return elseif t < tmax then tmax = t if tmin == tmax then return end end
		elseif num > 0 then
			return
		end
		denom, num = dy + dw, -y1 - w1
		if denom > 0 then
			local t = num / denom
			if t > tmax then return elseif t > tmin then tmin = t if tmin == tmax then return end end
		elseif denom < 0 then
			local t = num / denom
			if t < tmin then return elseif t < tmax then tmax = t if tmin == tmax then return end end
		elseif num > 0 then
			return
		end
		denom, num = -dy + dw, y1 - w1
		if denom > 0 then
			local t = num / denom
			if t > tmax then return elseif t > tmin then tmin = t if tmin == tmax then return end end
		elseif denom < 0 then
			local t = num / denom
			if t < tmin then return elseif t < tmax then tmax = t if tmin == tmax then return end end
		elseif num > 0 then
			return
		end
		denom, num = dz + dw, -z1 - w1
		if denom > 0 then
			local t = num / denom
			if t > tmax then return elseif t > tmin then tmin = t if tmin == tmax then return end end
		elseif denom < 0 then
			local t = num / denom
			if t < tmin then return elseif t < tmax then tmax = t if tmin == tmax then return end end
		elseif num > 0 then
			return
		end
		denom, num = -dz + dw, z1 - w1
		if denom > 0 then
			local t = num / denom
			if t > tmax then return elseif t > tmin then tmin = t if tmin == tmax then return end end
		elseif denom < 0 then
			local t = num / denom
			if t < tmin then return elseif t < tmax then tmax = t if tmin == tmax then return end end
		elseif num > 0 then
			return
		end

		local nproj_1 = interpolate(trans_1, trans_2, tmin)
		local nproj_2 = interpolate(trans_1, trans_2, tmax)
		return nproj_1, nproj_2
	end
end

local function line(trans_1, clip_1, proj_1, trans_2, clip_2, proj_2, drawLine, ...)
	proj_1, proj_2 = trimLine(trans_1, clip_1, proj_1, trans_2, clip_2, proj_2)
	if proj_1 then drawLine(proj_1, proj_2, ...) end
end

local function lineComplete(matrix, vertex_1, vertex_2, drawLine, ...)
	local trans_1, clip_1, proj_1 = transform(vertex_1, matrix)
	local trans_2, clip_2, proj_2 = transform(vertex_2, matrix)
	return line(trans_1, clip_1, proj_1, trans_2, clip_2, proj_2, drawLine, ...)
end

local function triangle(trans_1, clip_1, proj_1, trans_2, clip_2, proj_2, trans_3, clip_3, proj_3, drawTriangle, ...)
	if clip_1[1] and clip_2[1] and clip_3[1] then drawTriangle(proj_1, proj_2, proj_3, ...) end

	local c1_x, c1_y, c1_z = clip_1[2], clip_1[3], clip_1[4]
	local c2_x, c2_y, c2_z = clip_2[2], clip_2[3], clip_2[4]
	local c3_x, c3_y, c3_z = clip_3[2], clip_3[3], clip_3[4]

	if
		(c1_x ~= 0 and c1_x == c2_x and c1_x == c3_x) or
		(c1_y ~= 0 and c1_y == c2_y and c1_y == c3_y) or
		(c1_z ~= 0 and c1_z == c2_z and c1_z == c3_z)
	then return end

end

local function triangleComplete(matrix, vertex_1, vertex_2, vertex_3, uniform_1)
	local trans_1, clip_1, proj_1 = transform(vertex_1, matrix)
	local trans_2, clip_2, proj_2 = transform(vertex_2, matrix)
	local trans_3, clip_3, proj_3 = transform(vertex_3, matrix)
	return triangle(trans_1, clip_1, proj_1, trans_2, clip_2, proj_2, trans_3, clip_3, proj_3, uniform_1)
end

return {
	point = pointComplete,
	line = lineComplete,
	triangle = triangleComplete,
}

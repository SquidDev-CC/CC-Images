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

--- Interpolate between two points and then project them
-- @tpram matrix ver1 The first vertex
-- @tparam matrix ver2 The second vertex
local function interpolate(ver_1, ver_2, t)
	local it = 1 - t
	local newW = ver_1[4] * it + ver_2[4] * t
	local inv = 1 / newW
	return {
		(ver_1[1] * it + ver_2[1] * t) * inv,
		(ver_1[2] * it + ver_2[2] * t) * inv,
		(ver_1[3] * it + ver_2[3] * t) * inv,
		newW
	}
end

--- Interpolate between two points without projecting them
-- @tpram matrix ver1 The first vertex
-- @tparam matrix ver2 The second vertex
local function interpolateNoProject(ver_1, ver_2, t)
	local it = 1 - t
	return {
		ver_1[1] * it + ver_2[1] * t,
		ver_1[2] * it + ver_2[2] * t,
		ver_1[3] * it + ver_2[3] * t,
		ver_1[4] * it + ver_2[4] * t,
	}
end

local function pointComplete(matrix, vertex_1, drawPoint, ...)
	local trans_1, clip_1, proj_1 = transform(vertex_1, matrix)

	if clip_1[1] then drawPoint(proj_1, ...) end
end

-- Adaptation of https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
-- but using a parametric equation and no loop
-- also see https://www.cs.unc.edu/xcms/courses/comp770-s07/Lecture07.pdf page 28
local function line(trans_1, clip_1, proj_1, trans_2, clip_2, proj_2, drawLine, ...)
	if clip_1[1] and clip_2[1] then return drawLine(proj_1, proj_2, ...)
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
		return drawLine(nproj_1, nproj_2, ...)
	end
end

local function lineComplete(matrix, vertex_1, vertex_2, drawLine, ...)
	local trans_1, clip_1, proj_1 = transform(vertex_1, matrix)
	local trans_2, clip_2, proj_2 = transform(vertex_2, matrix)
	return line(trans_1, clip_1, proj_1, trans_2, clip_2, proj_2, drawLine, ...)
end

local function polygon(trans, drawPolygon, ...)
	local out, n, previous
	if #trans < 3 then error("Cannot render polygon with < 3 points", 2) end

	previous, out, n = trans[#trans], {}, 0
	for i = 1, #trans do
		local current = trans[i]
		local cx, cw, px, pw = current[1], current[4], previous[1], previous[4]

		if cx >= -cw * 1.00001 then
			if px < -pw * 1.00001 then
				-- Previous out, current in
				local num = -cw - cx
				local t = num / (num - (-pw - px))

				n = n + 1
				out[n] = interpolateNoProject(current, previous, t)
			end

			n = n + 1
			out[n] = current
		elseif px >= -pw * 1.00001 then
			-- Current out, previous in
			local num = -pw - px
			local t = num / (num - (-cw - cx))

			n = n + 1
			out[n] = interpolateNoProject(previous, current, t)
		end

		previous = current
	end

	if n < 3 then return end
	trans = out

	previous, out, n = trans[#trans], {}, 0
	for i = 1, #trans do
		local current = trans[i]
		local cx, cw, px, pw = current[1], current[4], previous[1], previous[4]

		if cx <= cw * 1.00001 then
			if px > pw * 1.00001 then
				-- Previous out, current in
				local num = cw - cx
				local t = num / (num - (pw - px))

				n = n + 1
				out[n] = interpolateNoProject(current, previous, t)
			end

			n = n + 1
			out[n] = current
		elseif px <= pw * 1.00001 then
			-- Current out, previous in
			local num = pw - px
			local t = num / (num - (cw - cx))

			n = n + 1
			out[n] = interpolateNoProject(previous, current, t)
		end

		previous = current
	end

	if n < 3 then return end
	trans = out

	previous, out, n = trans[#trans], {}, 0
	for i = 1, #trans do
		local current = trans[i]
		local cy, cw, py, pw = current[2], current[4], previous[2], previous[4]

		if cy >= -cw * 1.00001 then
			if py < -pw * 1.00001 then
				-- Previous out, current in
				local num = -cw - cy
				local t = num / (num - (-pw - py))

				n = n + 1
				out[n] = interpolateNoProject(current, previous, t)
			end

			n = n + 1
			out[n] = current
		elseif py >= -pw * 1.00001 then
			-- Current out, previous in
			local num = -pw - py
			local t = num / (num - (-cw - cy))

			n = n + 1
			out[n] = interpolateNoProject(previous, current, t)
		end

		previous = current
	end

	if n < 3 then return end
	trans = out

	previous, out, n = trans[#trans], {}, 0
	for i = 1, #trans do
		local current = trans[i]
		local cy, cw, py, pw = current[2], current[4], previous[2], previous[4]

		if cy <= cw * 1.00001 then
			if py > pw * 1.00001 then
				-- Previous out, current in
				local num = cw - cy
				local t = num / (num - (pw - py))

				n = n + 1
				out[n] = interpolateNoProject(current, previous, t)
			end

			n = n + 1
			out[n] = current
		elseif py <= pw * 1.00001 then
			-- Current out, previous in
			local num = pw - py
			local t = num / (num - (cw - cy))

			n = n + 1
			out[n] = interpolateNoProject(previous, current, t)
		end

		previous = current
	end

	if n < 3 then return end
	trans = out

	previous, out, n = trans[#trans], {}, 0
	for i = 1, #trans do
		local current = trans[i]
		local cz, cw, pz, pw = current[3], current[4], previous[3], previous[4]

		if cz >= -cw * 1.00001 then
			if pz < -pw * 1.00001 then
				-- Previous out, current in
				local num = -cw - cz
				local t = num / (num - (-pw - pz))

				n = n + 1
				out[n] = interpolateNoProject(current, previous, t)
			end

			n = n + 1
			out[n] = current
		elseif pz >= -pw * 1.00001 then
			-- Current out, previous in
			local num = -pw - pz
			local t = num / (num - (-cw - cz))

			n = n + 1
			out[n] = interpolateNoProject(previous, current, t)
		end

		previous = current
	end

	if n < 3 then return end
	trans = out

	previous, out, n = trans[#trans], {}, 0
	for i = 1, #trans do
		local current = trans[i]
		local cz, cw, pz, pw = current[3], current[4], previous[3], previous[4]

		if cz <= cw * 1.00001 then
			if pz > pw * 1.00001 then
				-- Previous out, current in
				local num = cw - cz
				local t = num / (num - (pw - pz))

				n = n + 1
				out[n] = interpolateNoProject(current, previous, t)
			end

			n = n + 1
			out[n] = current
		elseif pz <= pw * 1.00001 then
			-- Current out, previous in
			local num = pw - pz
			local t = num / (num - (cw - cz))

			n = n + 1
			out[n] = interpolateNoProject(previous, current, t)
		end

		previous = current
	end

	if n < 3 then return end
	trans = out

	for i = 1, n do
		local item = trans[i]
		local inv = 1 / item[4]
		item[1] = item[1] * inv
		item[2] = item[2] * inv
		item[3] = item[3] * inv
	end

	drawPolygon(trans, ...)
end

local function polygonComplete(matrix, vertex, drawPolygon, ...)
	local out = {}
	for i = 1, #vertex do
		out[i] = vector(matrix, vertex[i])
	end
	return polygon(out, drawPolygon, ...)
end

return {
	point = pointComplete,
	line = lineComplete,
	polygon = polygonComplete,
}

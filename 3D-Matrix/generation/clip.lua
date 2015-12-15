local insert, concat = table.insert, table.concat

local function clipLine(builder)
	insert(builder, [[
	if denom > 0 then
		local t = num / denom
		if t > tmax then return elseif t > tmin then tmin = t if tmin == tmax then return end end
	elseif denom < 0 then
		local t = num / denom
		if t < tmin then return elseif t < tmax then tmax = t if tmin == tmax then return end end
	elseif num > 0 then
		return
	end
	]])
end

local function writeInterpolate(builder, varying)
	insert(builder, [[
	--- Interpolate between to points
	-- @tpram matrix ver1 The first vertex
	-- @tparam matrix ver2
	]])
	insert(builder, "local function interpolate(")
	utils.declaration(builder, {"ver", "data"}, 0, 0, 2)
	insert(builder, ", t)\n")

	insert(builder, "local x, y, z, w = ver_1[1], ver_1[2], ver_1[3], ver_1[4]\n")
	for i = 1, varying do
		utils.insertWith(builder, "local var1_$1, var2_$1 = data_1[$1], data_2[$1]\n", i)
	end

	insert(builder, "local newW = w + (ver_2[4] - w) * t\n")
	insert(builder, "local inv = 1 / newW\n")

	insert(builder, [[
	return {
		(x + (ver_2[1] - x) * t) * inv,
		(y + (ver_2[2] - y) * t) * inv,
		(z + (ver_2[3] - z) * t) * inv,
		newW
	]])

	if varying > 0 then
		insert(builder, "}, {")
		for i = 1, varying do
			utils.insertWith(builder, "var1_$1 + (var2_$1 - var1_$1) * t,\n", i)
		end
	end

	insert(builder, "}\nend\n")
end

local function line(varying, uniform)
	varying, uniform = varying or 0, uniform or 0
	local builder = {}

	local width, height
	insert(builder, "local drawLine, vector = ...\n")

	insert(builder, clip_lib)

	writeInterpolate(builder, varying)

	do -- Line drawing
		insert(builder, [[
		-- Adaptation of https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
		-- but using a parametric equation and no loop
		]])
		insert(builder, "local function line(")
		utils.declaration(builder, {"trans", "clip", "proj", "data"}, 0, uniform, 2)
		insert(builder, ")\n")

		insert(builder, "if clip_1[1] and clip_2[1] then return drawLine(")
		utils.declaration(builder, {"proj", "data"}, 0, uniform, 2)
		insert(builder, ")\n")

		insert(builder, "elseif\n")
		insert(builder, [[
			(clip_1[2] ~= 0 and clip_1[2] == clip_2[2]) or
			(clip_1[3] ~= 0 and clip_1[3] == clip_2[3]) or
			(clip_1[4] ~= 0 and clip_1[4] == clip_2[4])
		then
			-- As they are all clipped on at least one side then hide
			-- For example if they are both too far to the left.
		else
			-- Prepare to clip everything

			local x1, y1, z1, w1 = trans_1[1], trans_1[2], trans_1[3], trans_1[4]
			local dx, dy, dz, dw = trans_2[1] - x1, trans_2[2] - y1, trans_2[3] - z1, trans_2[4] - w1

			local tmin, tmax = 0, 1
		]])

		insert(builder, "local denom, num = dx + dw, -x1 - w1") clipLine(builder)
		insert(builder, "denom, num = -dx + dw, x1 - w1") clipLine(builder)

		insert(builder, "denom, num = dy + dw, -y1 - w1") clipLine(builder)
		insert(builder, "denom, num = -dy + dw, y1 - w1") clipLine(builder)

		insert(builder, "denom, num = dz + dw, -z1 - w1") clipLine(builder)
		insert(builder, "denom, num = -dz + dw, z1 - w1") clipLine(builder)

		insert(builder, "local nproj_1, ndata_1 = interpolate(trans_1, data_1, trans_2, data_2, tmin)\n")
		insert(builder, "local nproj_2, ndata_2 = interpolate(trans_1, data_1, trans_2, data_2, tmax)\n")
		insert(builder, "return drawLine(nproj_1, ndata_1, nproj_2, ndata_2")
		utils.declaration(builder, {}, 0, uniform, 2)

		insert(builder, ")\nend\nend\n")
	end

	do -- Nice line
		insert(builder, "local function lineComplete(matrix, ")
		utils.declaration(builder, {"vertex", "data"}, 0, uniform, 2)
		insert(builder, ")\n")
		insert(builder, [[
			local trans_1, clip_1, proj_1 = transform(vertex_1, matrix)
			local trans_2, clip_2, proj_2 = transform(vertex_2, matrix)
		]])

		insert(builder, "return line(")
		utils.declaration(builder, {"trans", "clip", "proj", "data"}, 0, uniform, 2)
		insert(builder, ")\nend\n")
	end

	return concat(builder)
end

local directions = {
	{'x', '-', '', 1, -1},
	{'x', '', '-', 1, 1},
	{'y', '-', '', 2, -1},
	{'y', '', '-', 2, 1},
	{'z', '-', '', 3, -1},
	{'z', '', '-', 3, 1},
}

for _, direction in pairs(directions) do
	if direction[5] == -1 then
		direction[6] = direction[1] .. 'min'
	else
		direction[6] = direction[1] .. 'max'
	end
end
local function triangle(varying, uniform)
	varying, uniform = varying or 0, uniform or 0
	local builder = {}

	local width, height
	insert(builder, "local drawTriangle, vector = ...\n")
	insert(builder, clip_lib)

	writeInterpolate(builder, varying)

	do -- Clip functions
		local template = [[
			local function clipTriangle_$1(vec1, vec2)
				local d = vec1[$4] - vec2[$4]
				local w = vec1[4]
				local den = $3d + (w - vec2[4])
				if den == 0 then
					return 0
				else
					return ($2vec1[$4] - w) / den
				end
			end
		]]
		for _, direction in pairs(directions) do
			utils.insertWith(builder, template, direction[6], direction[2], direction[3], direction[4])
		end
	end

	do -- Main drawer
		insert(builder, "local function triangle(")
		utils.declaration(builder, {"trans", "clip", "proj", "data"}, 0, uniform, 3)
		insert(builder, ", direction)\n")

		-- Basic case: All items are clipped
		insert(builder, "if clip_1[1] and clip_2[1] and clip_3[1] then drawTriangle(")
		utils.declaration(builder, {"proj", "data"}, 0, uniform, 3)
		insert(builder, ") end\n")

		for i = 1, 3 do utils.insertWith(builder, "local c$1_x, c$1_y, c$1_z = clip_$1[2], clip_$1[3], clip_$1[4]\n", i) end

		-- If all items are clipped on the same side then it is safe to ignore them
		insert(builder, [[if
			(c1_x ~= 0 and c1_x == c2_x and c1_x == c3_x) or
			(c1_y ~= 0 and c1_y == c2_y and c1_y == c3_y) or
			(c1_z ~= 0 and c1_z == c2_z and c1_z == c3_z)
		then print("Clipping") print(c1_x, c2_x, c3_x, c1_y, c2_y, c3_y, c1_z, c2_z, c3_z) return end]])

		insert(builder, "\ndirection = direction or 0\n")

		insert(builder, "local count, func, index = 0\n")

		insert(builder, "repeat\n") -- Emulated goto
		for index, direction in pairs(directions) do
			--[[
				The logic here is a bit odd, but I think it holds.
				Basically we want three elements, with a count of
					0 => This can be anything
					1 => [ clipped, other 1, other 2]
					2 => [ clipped 1, clipped 2, other ]
					3 => Cannot happen
			]]

			utils.insertWith(builder, [[
			if direction < $1 then
				if c1_$2 == $3 then
					count, index = 1, 1
				end
				if c2_$2 == $3 then
					if count == 0 then
						count, index = 1, 1
					else
						count, index = 2, 3 -- Other index is 3 as 1 and 2 are matched
					end
				end
				if c3_$2 == $3 then
					if count == 0 then
						count, index = 1, 3
					else
						count = 2
						if index == 1 then index = 2 else index = 1 end
					end
				end

				if count ~= 0 then
					func = clip_$4
					direction = $1
					break
				else
					count = 0
				end
			end
			]], index, direction[1], direction[5], direction[6])
		end

		insert(builder, "until false\n")
		insert(builder, "print(count, index)")

		local temp = {}
		for i = 1, uniform do temp[i] = "uniform_" .. i .. ", " end
		utils.insertWith(builder, triangle_lib, concat(temp))

		insert(builder, "\nend\n")
	end


	do -- Nice triangle
		insert(builder, "local function triangleComplete(matrix, ")
		utils.declaration(builder, {"vertex", "data"}, 0, uniform, 3)
		insert(builder, ")\n")
		insert(builder, [[
			local trans_1, clip_1, proj_1 = transform(vertex_1, matrix)
			local trans_2, clip_2, proj_2 = transform(vertex_2, matrix)
			local trans_3, clip_3, proj_3 = transform(vertex_3, matrix)
		]])

		insert(builder, "triangle(")
		utils.declaration(builder, {"trans", "clip", "proj", "data"}, 0, uniform, 3)
		insert(builder, ")\nend\n")
	end

	return concat(builder)
end

return {
	line = line,
	triangle = triangle,
}

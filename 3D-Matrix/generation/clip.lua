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

local function line(varying, uniform)
	varying, uniform = varying or {}, uniform or 0
	local builder = {}

	local width, height
	insert(builder, "local drawLine, vector = ...\n")

	insert(builder, clip_lib)

	do -- Line interpolation
		insert(builder, [[
		--- Interpolate between to points
		-- @tpram matrix ver1 The first vertex
		-- @tparam matrix ver2
		]])
		insert(builder, "local function interpolate(")
		utils.declaration(builder, {"ver", "data"}, {}, 0, 2)
		insert(builder, ", t)\n")

		insert(builder, "local x, y, z, w = ver_1[1], ver_1[2], ver_1[3], ver_1[4]\n")
		for i, count in pairs(varying) do
			utils.insertWith(builder, "local var1_$1, var2_$1 = data_1[$1], data_2[$1]\n", i)
			if count ~= 1 then
				for j = 1, count do
					utils.insertWith(builder, "local var1_$1_$2 = var1_$1[$2]\n", i, j)
				end
			end
		end

		insert(builder, "local newW = w + (ver_2[4] - w) * t\n")
		insert(builder, "local inv = 1 / newW\n")

		insert(builder, [[
		return {
			(x + (ver_2[1] - x) * t) * inv,
			(y + (ver_2[2] - y) * t) * inv,
			(z + (ver_2[3] - z) * t) * inv,
			newW
		},
		{
		]])

		for i, count in pairs(varying) do
			if count == 1 then
				utils.insertWith(builder, "var1_$1 + (var2_$1 - var1_$1) * t,\n", i)
			else
				insert(builder, "{\n")
				for j = 1, count do
					utils.insertWith(builder, "var1_$1_$2 + (var2_$1[$2] - var1_$1_$2) * t,\n", i, j)
				end
				insert(builder, "},\n")
			end
		end

		insert(builder, "}\nend\n")
	end

	do -- Line drawing
		insert(builder, [[
		-- Adaptation of https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
		-- but using a parametric equation and no loop
		]])
		insert(builder, "local function line(")
		utils.declaration(builder, {"trans", "clip", "proj", "data"}, {}, uniform, 2)
		insert(builder, ")\n")

		insert(builder, "if clip_1[1] and clip_2[1] then return drawLine(")
		utils.declaration(builder, {"proj", "data"}, {}, uniform, 2)
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
		utils.declaration(builder, {}, {}, uniform, 2)

		insert(builder, ")\nend\nend\n")
	end

	do -- Nice line
		insert(builder, "local function lineComplete(matrix, ")
		utils.declaration(builder, {"vertex", "data"}, {}, uniform, 2)
		insert(builder, ")\n")
		insert(builder, [[
			local trans_1, clip_1, proj_1 = transform(vertex_1, matrix)
			local trans_2, clip_2, proj_2 = transform(vertex_2, matrix)
		]])

		insert(builder, "return line(")
		utils.declaration(builder, {"trans", "clip", "proj", "data"}, {}, uniform, 2)
		insert(builder, ")\nend\n")
	end

	return concat(builder)
end

return {
	line = line
}

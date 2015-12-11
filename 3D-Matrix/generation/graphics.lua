--[[
	Line and triangle drawing taken from:
		- http://www.sunshine2k.de/coding/java/Bresenham/RasterisingLinesCircles.pdf
		- http://www.sunshine2k.de/coding/java/TriangleRasterization/TriangleRasterization.html
]]

local floor, ceil, abs, inf = math.floor, math.ceil, math.abs, math.huge

local insert, concat = table.insert, table.concat
local pairs, assert, tonumber = pairs, assert, tonumber
local declaration, insertWith = utils.declaration, utils.insertWith

local declaration = function(builder, ...)
	insert(builder, "(")
	declaration(builder, ...)
	insert(builder, ")\n")
end

local function buildBound(builder, value, nargs, comparison, bound)
	insert(builder, "(")
	for i = 1, nargs do
		if i ~= 1 then insert(builder, " and ") end
		insert(builder, value:gsub("%$", i) .. comparison .. bound)
	end
	insert(builder, ")")
end

local function buildBounds(builder, limited, nargs)
	for i, lim in pairs(limited) do
		insert(builder, " or ")
		buildBound(builder, "var$_" .. i, nargs, "<", lim[1])
		insert(builder, " or ")
		buildBound(builder, "var$_" .. i, nargs, ">", lim[2])
	end
end

local function genLimited(varying)
	local limited = {}
	for i, k in pairs(varying) do
		if type(k) == "table" then
			if #k ~= 2 then error("Expected length of bounds based varying to be 2, instead is " .. #k, 3) end
			limited[i] = k
			varying[i] = 1
		end
	end

	return limited
end

local function buildPixel(builder, varying, uniform, str)
	insert(builder, "pixel(x, y")
	for i, count in pairs(varying) do
		if count == 1 then
			insert(builder, ", " .. str:gsub("%$", i))
		else
			insert(builder, ", {")
			for j = 1, count do insert(builder, str:gsub("%$", i .. "_" .. j) .. ", ") end
			insert(builder, "}")
		end
	end
	for i = 1, uniform do insert(builder, ", uniform_" .. i) end
	insert(builder, ")\n")
end

local function line(dimensions, varying, uniform)
	varying, uniform = varying or {}, uniform or 0
	local builder = {}

	local width, height, size
	if dimensions then
		width, height, size = dimensions[1], dimensions[2], dimensions[1] * dimensions[2]
		insert(builder, "local pixel = ...\n")
	else
		width, height, size = "width", "height", "width * height"
		insert(builder, "local pixel, width, height = ...\n")
	end

	insert(builder, "local floor, abs = math.floor, math.abs\n")

	local function insertVars(str)
		str = str:gsub("%${width}", width):gsub("%${height}", height):gsub("\t", "")
		insert(builder, str)
	end

	insert(builder, "return function")
	local limited = genLimited(varying)
	declaration(builder, {"x", "y"}, varying, uniform, 2)

	insertVars [[if (x_1 < 1 and x_2 < 1) or (x_1 > ${width} and x_2 > ${width}) or (y_1 < 1 and y_2 < 1) or (y_1 > ${height} and y_2 > ${height}) ]]
	buildBounds(builder, limited, 2)

	insert(builder, " then return end\n")

	insert(builder, [[
		x_1, x_2 = floor(x_1), floor(x_2)
		y_1, y_2 = floor(y_1), floor(y_2)

		local ndx, ndy = x_2 - x_1, y_2 - y_1
		local dx, dy = abs(ndx), abs(ndy)
		local steep = dy > dx
		if steep then
			dy, dx = dx, dy
		end

		local e = 2 * dy - dx
		local x, y = x_1, y_1

		local signy, signx = 1, 1
		if ndx < 0 then signx = -1 end
		if ndy < 0 then signy = -1 end
	]])

	for i, count in pairs(varying) do
		if count == 1 then
			insertWith(builder, "local var_$1, dvar_$1 = var1_$1, (var2_$1 - var1_$1) / dx\n", i)
		else
			for j = 1, count do
				insertWith(builder, "local var_$1_$2 = var1_$1[$2] local dvar_$1_$2 = (var2_$1[$2] - var_$1_$2) / dx\n", i, j)
			end
		end
	end

	insert(builder, "\nfor i = 1, dx do\n")
	buildPixel(builder, varying, uniform, "var_$")

	insert(builder, [[
	while e >= 0 do
		if steep then
			x = x + signx
		else
			y = y + signy
		end
		e = e - 2 * dx
	end

	if steep then
		y = y + signy
	else
		x = x + signx
	end
	e = e + 2 * dy
	]])

	for i, count in pairs(varying) do
		if count == 1 then
			insertWith(builder, "var_$1 = var_$1 + dvar_$1\n", i)
		else
			for j = 1, count do
			insertWith(builder, "var_$1_$2 = var_$1_$2 + dvar_$1_$2\n", i, j)
			end
		end
	end

	insert(builder, "end\n")

	insert(builder, "pixel(x_2, y_2")
	for i, count in pairs(varying) do insertWith(builder, ", var2_$1", i) end
	for i = 1, uniform do insertWith(builder, ", uniform_$1", i) end
	insert(builder, ")\nend\n")

	return concat(builder)
end

local function buildSwap(builder, varying, from, to)
	for i, _ in pairs(varying) do
		local f, t = "var" .. from .. "_" .. i, "var" .. to .. "_" .. i
		insert(builder, f .. ", " .. t .. " = " .. t .. ", " .. f .. "\n")
	end
end

local function triangle(dimensions, varying, uniform)
	varying, uniform = varying or {}, uniform or 0
	local builder = {}

	local width, height, size
	if dimensions then
		width, height, size = dimensions[1], dimensions[2], dimensions[1] * dimensions[2]
		insert(builder, "local pixel = ...\n")
	else
		width, height, size = "width", "height", "width * height"
		insert(builder, "local pixel, width, height = ...\n")
	end

	insert(builder, "local floor, ceil, abs = math.floor, math.ceil, math.abs\n")

	local function insertVars(str)
		str = str:gsub("%${width}", width):gsub("%${height}", height):gsub("\t", "")
		insert(builder, str)
	end

	local limited = genLimited(varying)

	do -- Bottom triangle
		-- Fills a triangle whose bottom side is perfectly horizontal.
		-- Precondition is that v2 and v3 perform the flat side and that v1.y < v2.y, v3.y.

		insert(builder, "local bottom = function")
		declaration(builder, {"x", "y"}, varying, uniform, 3)

		insert(builder, [[
			local xStart, xEnd = x_1, x_1 + 0.5
			local dy_2, dy_3 = y_2 - y_1, y_3 - y_1
			local dx_2, dx_3 = (x_2 - x_1) / dy_2, (x_3 - x_1) / dy_3
		]])

		for i, count in pairs(varying) do
			if count == 1 then
				insertWith(builder, "local varStart_$1, varEnd_$1 = var1_$1, var1_$1\n", i)
				insertWith(builder, "local dVar2_$1, dVar3_$1 = (var2_$1 - var1_$1) / dy_2, (var3_$1 - var1_$1) / dy_3\n", i)
			else
				for j = 1, count do
					insertWith(builder, "local varStart_$1_$2 = var1_$1[$2] local varEnd_$1_$2 = varStart_$1_$2\n", i, j)
					insertWith(builder, "local dVar2_$1_$2, dVar3_$1_$2 = (var2_$1[$2] - varStart_$1_$2) / dy_2, (var3_$1[$2] - varStart_$1_$2) / dy_3\n", i, j)
				end
			end
		end

		insert(builder, "\nif dx_3 < dx_2 then\ndx_2, dx_3 = dx_3, dx_2\n")

		for i, count in pairs(varying) do
			if count == 1 then
				insertWith(builder, "dVar2_$1, dVar3_$1 = dVar3_$1, dVar2_$1\n", i)
			else
				for j = 1, count do
					insertWith(builder, "dVar2_$1_$2, dVar3_$1_$2 = dVar3_$1_$2, dVar2_$1_$2\n", i, j)
				end
			end
		end

		insert(builder, "end\n\n")

		insertVars [[
			for y = y_1, y_2 do
				if y >= 1 and y <= ${height} then
					for x = ceil(xStart), xEnd do
						local t = (x - xStart) / (xEnd - xStart)
						local tInv = 1 - t
		]]

		buildPixel(builder, varying, uniform, "tInv * varStart_$ + t * varEnd_$")

		insert(builder, "end\nend\n")
		insert(builder, "xStart, xEnd = xStart + dx_2, xEnd + dx_3\n")
		for i, count in pairs(varying) do
			if count == 1 then
				insertWith(builder, "varStart_$1, varEnd_$1 = varStart_$1 + dVar2_$1, varEnd_$1 + dVar3_$1\n", i)
			else
				for j = 1, count do
					insertWith(builder, "varStart_$1, varEnd_$1 = varStart_$1 + dVar2_$1, varEnd_$1 + dVar3_$1\n", i .. "_" .. j)
				end
			end
		end

		insert(builder, "end\nend\n\n")
	end

	do -- Top triangle
		-- Fills a triangle whose top side is perfectly horizontal
		-- v1 and v2 are on the flat side, and v3.y > v1.y, v2.y
		insert(builder, "local top = function")
		declaration(builder, {"x", "y"}, varying, uniform, 3)

		insert(builder, [[
			local xStart, xEnd = x_3, x_3 + 0.5
			local dy_1, dy_2 = y_3 - y_1, y_3 - y_2
			local dx_1, dx_2 = (x_3 - x_1) / dy_1, (x_3 - x_2) / dy_2
		]])

		for i, count in pairs(varying) do
			if count == 1 then
				insertWith(builder, "local varStart_$1, varEnd_$1 = var3_$1, var3_$1\n", i)
				insertWith(builder, "local dVar1_$1, dVar2_$1 = (var3_$1 - var1_$1) / dy_1, (var3_$1 - var2_$1) / dy_2\n", i)
			else
				for j = 1, count do
					insertWith(builder, "local varStart_$1_$2 = var3_$1[$2] local varEnd_$1_$2 = varStart_$1_$2\n", i, j)
					insertWith(builder, "local dVar1_$1_$2, dVar2_$1_$2 = (varStart_$1_$2 - var1_$1[$2]) / dy_1, (varStart_$1_$2 - var2_$1[$2]) / dy_2\n", i, j)
				end
			end
		end

		insert(builder, "\nif dx_1 < dx_2 then\ndx_1, dx_2 = dx_2, dx_1\n")

		for i, count in pairs(varying) do
			if count == 1 then
				insertWith(builder, "dVar1_$1, dVar2_$1 = dVar2_$1, dVar1_$1\n", i)
			else
				for j = 1, count do
					insertWith(builder, "dVar1_$1_$2, dVar2_$1_$2 = dVar2_$1_$2, dVar1_$1_$2\n", i, j)
				end
			end
		end

		insert(builder, "end\n\n")

		insert(builder, "for y = y_3, y_1 + 1, -1 do\n")

		insert(builder, "xStart, xEnd = xStart - dx_1, xEnd - dx_2\n")
		for i, count in pairs(varying) do
			if count == 1 then
				insertWith(builder, "varStart_$1, varEnd_$1 = varStart_$1 - dVar1_$1, varEnd_$1 - dVar2_$1\n", i)
			else
				for j = 1, count do
					insertWith(builder, "varStart_$1, varEnd_$1 = varStart_$1 - dVar1_$1, varEnd_$1 - dVar2_$1\n", i .. "_" .. j)
				end
			end
		end

		insertVars [[
		if y >= 1 and y <= ${height} then
			for x = ceil(xStart), xEnd do
				local t = (x - xStart) / (xEnd - xStart)
				local tInv = 1 - t
		]]
		buildPixel(builder, varying, uniform, "tInv * varStart_$ + t * varEnd_$")

		insert(builder, "end\nend\nend\nend\n")
	end

	do -- Main Renderer
		insert(builder, "return function")
		declaration(builder, {"x", "y"}, varying, uniform, 3)

		insertVars [[if (x_1 < 1 and x_2 < 1) or (x_1 > ${width} and x_2 > ${width}) or (y_1 < 1 and y_2 < 1) or (y_1 > ${height} and y_2 > ${height}) ]]
		buildBounds(builder, limited, 3)

		insert(builder, " then return end\n")

		insert(builder, "x_1, x_2, x_3 = floor(x_1), floor(x_2), floor(x_3)\ny_1, y_2, y_3 = floor(y_1), floor(y_2), floor(y_3)\n")

		insert(builder, "if y_1 > y_2 then\nx_1, x_2 = x_2, x_1\ny_1, y_2 = y_2, y_1\n")
		buildSwap(builder, varying, 1, 2)
		insert(builder, "end\n")

		-- here v1 <= v2
		insert(builder, "if y_1 > y_3 then\nx_1, x_3 = x_3, x_1\ny_1, y_3 = y_3, y_1\n")
		buildSwap(builder, varying, 1, 3)
		insert(builder, "end\n")

		-- here v1.y <= v2.y and v1.y <= v3.y so test v2 vs. v3
		insert(builder, "if y_2 > y_3 then\nx_2, x_3 = x_3, x_2\ny_2, y_3 = y_3, y_2\n")
		buildSwap(builder, varying, 2, 3)
		insert(builder, "end\n")

		-- We really don't need to return, but tail call optimisation.
		-- Though, I'm not sure it really helps
		insert(builder, "if y_2 == y_3 then\n")
		insert(builder, "return bottom")
		declaration(builder, {"x", "y"}, varying, uniform, 3)
		insert(builder, "elseif y_1 == y_2 then\n")
		insert(builder, "return top")
		declaration(builder, {"x", "y"}, varying, uniform, 3)

		insert(builder, "else")
		insert(builder, [[
			local delta = (y_2 - y_1) / (y_3 - y_1)
			local x = floor(x_1 + delta * (x_3 - x_1))
		]])


		for i, count in pairs(varying) do
			if count == 1 then
				insertWith(builder, "local var_$1 = var1_$1 + delta * (var3_$1 - var1_$1)\n", i)
			else
				insertWith(builder, "local var_$1 = {\n", i)
				for j = 1, count do
					insertWith(builder, "var1_$1[$2] + delta * (var3_$1[$2] - var1_$1[$2]),\n", i, j)
				end
				insert(builder, "}\n")
			end
		end

	insert(builder, "bottom(x_1, y_1")
	for j, _ in pairs(varying) do insert(builder, ", var1_" .. j) end
	insert(builder, ", x_2, y_2")
	for j, _ in pairs(varying) do insert(builder, ", var2_" .. j) end
	insert(builder, ", x, y_2")
	for j, _ in pairs(varying) do insert(builder, ", var_" .. j) end

	for i = 1, uniform do insert(builder, ", uniform_" .. i) end
	insert(builder, ")\n")

	insert(builder, "top(x_2, y_2")
	for j, _ in pairs(varying) do insert(builder, ", var2_" .. j) end
	insert(builder, ", x, y_2")
	for j, _ in pairs(varying) do insert(builder, ", var_" .. j) end
	insert(builder, ", x_3, y_3")
	for j, _ in pairs(varying) do insert(builder, ", var3_" .. j) end

	for i = 1, uniform do insert(builder, ", uniform_" .. i) end
	insert(builder, ")\n")
	end

	insert(builder, "end\nend")

	return concat(builder)
end

return {
	line = line,
	triangle = triangle,
}

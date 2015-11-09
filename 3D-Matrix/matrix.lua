--[[
	Dynamically generate methods for matrix calculations.

	This should generate more efficient code than primitive for loops
	If it doesn't, then it is still pretty cool :).
]]

local insert, concat, load = table.insert, table.concat, loadstring
local withDebug = true

local function writeGetters(name, rows, columns, builder)
	local accessor = "local " .. name .. "_"
	for col = 1, columns do
		for row = 1, rows do
			insert(builder, accessor .. row .. "_" .. col .. "=" .. name .. "[" .. (row + (col - 1) * rows) .. "]\n")
		end
	end
end

local function createMultiply(lRows, lColumns, rRows, rColumns)
	if lColumns ~= rRows then error(("Cannot multiply %sx%s with %sx%s"):format(lRows, lColumns, rRows, rColumns)) end
	local builder = {"return function(l, r)\n"}
	writeGetters("l", lRows, lColumns, builder)
	writeGetters("r", rRows, rColumns, builder)

	insert(builder, "return {\n")

	if withDebug then
		insert(builder, "rows=" .. lRows .. ", cols=" .. rColumns .. ",\n")
	end

	for col = 1, rColumns do
		for row = 1, lRows do
			for i = 1, lColumns do
				if i ~= 1 then insert(builder, " + ") end
				insert(builder, "l_" .. row .. "_" .. i .. "*r_" .. i .. "_" .. col)
			end

			insert(builder, ",\n")
		end
	end
	insert(builder, "}\nend")

	return load(concat(builder))()
end

local function createMultiplyScalar(rows, cols)
	local builder = {"return function(m, f)\nreturn{"}
	if withDebug then
		insert(builder, "rows=" .. rows .. ", cols=" .. cols .. ",\n")
	end

	for col = 1, cols do
		for row = 1, rows do
			insert(builder, "m[" .. (row + (col - 1) * rows) .. "] * f,\n")
		end
	end

	insert(builder, "}\nend")
	return load(concat(builder))()
end

local function createTranspose(rows, cols)
	local builder = {"return function(m)\nreturn {\n"}

	if withDebug then
		insert(builder, "rows=" .. cols .. ", cols=" .. rows .. ",\n")
	end

	for row = 1, rows do
		for col = 1, cols do
			insert(builder, "m[" .. (row + (col - 1) * rows) .. "]")
			insert(builder, ",\n")
		end
	end

	insert(builder, "}\nend")
	return load(concat(builder))()
end

local function createIdentity(dim)
	local builder = {"return function()\nreturn {\n"}
	if withDebug then
		insert(builder, "rows=" .. dim .. ", cols=" .. dim .. ",\n")
	end
	for x = 1, dim do
		for y = 1, dim do
			local num = 0
			if x == y then num = 1 end
			insert(builder, num .. ",\n")
		end
	end

	insert(builder, "}\nend")
	return load(concat(builder))()
end

local function printMatrix(matrix, rows, cols)
	rows = assert(rows or matrix.rows, "No rows specified")
	cols = assert(cols or matrix.cols, "No cols specified")
	print("Matrix " .. rows .. "x" .. cols .. ":")
	for row = 1, rows do
		for col = 1, cols do
			if col ~= 1 then io.write("\t") end
			io.write(tostring(matrix[(row + (col - 1) * rows)]))
		end
		print("")
	end
end

return {
	print = printMatrix,
	createIdentity = createIdentity,
	createTranspose = createTranspose,
	createMultiply = createMultiply,
	createMultiplyScalar = createMultiplyScalar,
}
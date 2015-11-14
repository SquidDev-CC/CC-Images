--[[
	Dynamically generate methods for matrix calculations.

	This should generate more efficient code than primitive for loops
	If it doesn't, then it is still pretty cool :).
]]

local insert, concat = table.insert, table.concat

local function writeGetters(name, rows, columns, builder)
	local accessor = "local " .. name .. "_"
	for col = 1, columns do
		for row = 1, rows do
			insert(builder, accessor .. row .. "_" .. col .. "=" .. name .. "[" .. (row + (col - 1) * rows) .. "]\n")
		end
	end
end

local function createMultiply(lRows, lColumns, rRows, rColumns, withDebug)
	if lColumns ~= rRows then error(("Cannot multiply %sx%s with %sx%s"):format(lRows, lColumns, rRows, rColumns)) end
	local builder = {"function(l, r)\n"}
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

	return concat(builder)
end

local function createMultiplyScalar(rows, cols, withDebug)
	local builder = {"function(m, f)\nreturn{"}
	if withDebug then
		insert(builder, "rows=" .. rows .. ", cols=" .. cols .. ",\n")
	end

	for col = 1, cols do
		for row = 1, rows do
			insert(builder, "m[" .. (row + (col - 1) * rows) .. "] * f,\n")
		end
	end

	insert(builder, "}\nend")
	return concat(builder)
end

local function createTranspose(rows, cols, withDebug)
	local builder = {"function(m)\nreturn {\n"}

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
	return concat(builder)
end

local function createIdentity(dim, withDebug)
	local builder = {"function()\nreturn {\n"}
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
	return concat(builder)
end

return {
	createIdentity = createIdentity,
	createTranspose = createTranspose,
	createMultiply = createMultiply,
	createMultiplyScalar = createMultiplyScalar,
}

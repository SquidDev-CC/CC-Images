local assert, load = assert, loadstring

local function loader(func)
	return function(...) return assert(load("return " .. func(...)))() end
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
	multiply = loader(generation.createMultiply),
	multiplyScalar = loader(generation.createMultiplyScalar),
	transpose = loader(generation.createTranspose),
	identity = loader(generation.createIdentity),
}

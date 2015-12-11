local insert, concat = table.insert, table.concat

local function line(dimensions, uniform)
	uniform = uniform or 0

	local builder = {}
	local width, height, size
	if dimensions then
		width, height, size = dimensions[1], dimensions[2], dimensions[1] * dimensions[2]
		insert(builder, "local line = ...\n")
	else
		width, height, size = "width", "height", "width * height"
		insert(builder, "local line, width, height = ...\n")
	end

	insert(builder, "return function(")
	utils.declaration(builder, {"ver", "data"}, {}, uniform, 2)
	insert(builder, ")\n")

	insert(builder, "return line(")
	insert(builder, "(ver_1[1] + 1) * " .. width .. " / 2, (ver_1[2] + 1) * " .. height .. " / 2, ver_1[3],")
	insert(builder, "(ver_2[1] + 1) * " .. width .. " / 2, (ver_2[2] + 1) * " .. height .. " / 2, ver_2[3]")
	for i = 1, uniform do insert(builder, ", uniform_" .. i) end

	insert(builder, ")\nend\n")

	return concat(builder)
end

return {
	line = line
}

local insert, concat = table.insert, table.concat

local function object(dimensions, uniform, nargs)
	uniform = uniform or 0

	local builder = {}
	local width, height, size
	if dimensions then
		width, height, size = dimensions[1], dimensions[2], dimensions[1] * dimensions[2]
		insert(builder, "local delegate = ...\n")
	else
		width, height, size = "width", "height", "width * height"
		insert(builder, "local delegate, width, height = ...\n")
	end

	insert(builder, "return function(")
	utils.declaration(builder, {"ver", "data"}, 0, uniform, nargs)
	insert(builder, ")\n")

	insert(builder, "return delegate(")
	for i = 1, nargs do
		if i ~= 1 then insert(builder, ", ") end
		utils.insertWith(builder, "(ver_$1[1] + 1) * " .. width .. " / 2, (ver_$1[2] + 1) * " .. height .. " / 2, ver_1[3]", i)
	end
	for i = 1, uniform do insert(builder, ", uniform_" .. i) end

	insert(builder, ")\nend\n")

	return concat(builder)
end

return {
	line = function(dimensions, uniform) return object(dimensions, uniform, 2) end,
	triangle = function(dimensions, uniform) return object(dimensions, uniform, 3) end,
	object = object,
}

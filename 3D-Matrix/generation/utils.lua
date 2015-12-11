local insert, pairs = table.insert, pairs

local function declaration(builder, named, varying, uniform, nargs)
	local comma = false
	for i = 1, nargs do
		for _, name in pairs(named) do
			if comma then insert(builder, ", ") else comma = true end
			insert(builder, name .. "_" .. i)
		end
		for j, _ in pairs(varying) do
			if comma then insert(builder, ", ") else comma = true end
			insert(builder, "var" .. i .. "_" .. j)
		end
	end

	for i = 1, uniform do insert(builder, ", uniform_" .. i) end
end

local function call(builder, varying, uniform, str)
	insert(builder, "x, y, z, ")
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
end

local function insertWith(builder, str, ...)
	local rep = {...}
	str = str:gsub("%$(%d%d-)", function(index) return rep[tonumber(index)] end)
	insert(builder, str)
end

return {
	call = call,
	declaration = declaration,
	insertWith = insertWith,
}

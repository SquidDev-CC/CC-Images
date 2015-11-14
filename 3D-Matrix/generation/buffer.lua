local insert, concat = table.insert, table.concat

--- Basic colour
-- @table colour
-- @tfield byte 0 Red
-- @tfield byte 1 Green
-- @tfield byte 2 Blue
-- @tfield byte 3 Alpha

--- Generic buffer interface
-- @table buffer
-- @tfield (x, y, z, colour)->nil pixel Draw a pixel to the buffer with a depth test (if enabled)
-- @tfield (colour)->nil clear Clear all buffers
-- @tfield (colour)->nil clearColour Clear the colour buffer
-- @tfield (colour)->nil|nil clearDepth Clear the depth test. Not set if there if depth test is disabled
-- @tfield (table, int, int)->nil love Render using the specified love table.
-- @tfield (table, int, int)->nil loveDepth Render the depth buffer using the specified love table.

--- Generate a specialised buffer
-- @tparam bool? depthTest Depth test. If none is set it can be configured
-- @tparam bool? blending Alpha blending. If none is set it can be configured
-- @tparam {number, number}? dimensions Width x Height. If none is set it should be passed as an argument
-- @treturn (dimensions)->buffer
return function(depthTest, blending, dimensions)
	--[[ Various TODOs:
		- Stencil buffer: Though this could be simulated with a depth of 1
		- Alpha blending
	]]

	local builder = {}

	local width, height, size
	if dimensions then
		width, height, size = dimensions[1], dimensions[2], dimensions[1] * dimensions[2]
	else
		width, height, size = "width", "height", "width * height"
		insert(builder, "local width, height = ...\n")
	end

	local function insertVars(str)
		str = str:gsub("${width}", width):gsub("${height}", height):gsub("\t", "")
		insert(builder, str)
	end

	-- Setup colour functions
	insert(builder, "local colours, export = {}, {}\n")
	insert(builder, "local function clearColour(colour) colour = colour or {0, 0, 0, 255} for i = 1, " .. size .. " do colours[i] = colour end end\n")
	insert(builder, "export.clearColour = clearColour\n")

	-- Setup colour buffer
	insert(builder, "clearColour({0, 0, 0, 255})\n")

	if depthTest ~= false then
		-- Setup clear functions
		insert(builder, "local depth, testDepth, inf = {}, true, math.huge\n")
		insert(builder, "local function clearDepth(colour) for i = 1, " .. size .. " do depth[i] = inf end end\n")
		insert(builder, "export.clearColour = clearColour\n")

		-- Setup depth buffer
		insert(builder, "clearDepth()\n")

		if depthTest == nil then
			insert(builder, "local function setDepth(depth) testDepth = depth end\n")
			insert(builder, "export.setDepth = setDepth\n")
		end
	end

	insert(builder, "export.clear = function(colour)\nclearColour(colour)\n")
	if depthTest ~= false then insert(builder, "clearDepth()\n") end
	insert(builder, "end\n")

	insert(builder, "local function pixel(x, y, z, colour)\n")
	insert(builder, "if x < 1 or x > " .. width .. " ")
	insert(builder, "or y < 1 or y > " .. height .. " ")
	if depthTest ~= false then
		insert(builder, "or ")
		if depthTest == nil then
			insert(builder, "depthTest and ")
		end
		insert(builder, "(z > 1 or z < -1) ")
	end

	insert(builder, "then return end\n")
	insert(builder, "local index = " .. width .. " * (y - 1) + x\n")

	if depthTest ~= false then
		insert(builder, "if ")
		if depthTest == nil then insert(builder, "depthTest and ") end
		insert(builder, "z < depth[index] then\n")
		insert(builder, "depth[index] = z\n")
	end

	insert(builder, "colours[index] = colour\n")

	if depthTest ~= false then insert(builder, "end\n") end
	insert(builder, "end\nexport.pixel = pixel\n")

	insertVars [[
	export.love = function(love, oX, oY)
		local setPoint, setColour = love.graphics.point, love.graphics.setColor
		oX = oX or 0
		oY = oY or 0

		for y = 1, ${height} do
			local offset = (y - 1) * ${width}
			for x = 1, ${width} do
				local colour = colours[offset + x]
				setColour(colour[1], colour[2], colour[3], colour[4])
				setPoint(oX + x, oY + y)
			end
		end
	end
	]]

	insertVars [[
	local blit_fore = ("0"):rep(${width})
	local blit_text = (" "):rep(${width})
	local closest, cols = colors.findClosestColor, colors.strSets
	local insert, concat = table.insert, table.concat
	export.cc = function(term, x, y)
		local blit, set = term.blit, term.setCursorPos
		for y = 1, ${height} do
			local offset = (y - 1) * ${width}
			local back = {}
			for x = 1 , ${width} do
				local colour = colours[offset + x]
				insert(back, closest(cols, colour[1], colour[2], colour[3]))
			end

			set(1, y)
			blit(blit_text, blit_fore, concat(back))
		end
	end

	export.silica = function(term, x, y)
		local blit, set = term.blit, term.setCursorPos
		for y = 1, ${height} do
			local offset = (y - 1) * ${width}
			local back = {}
			for x = 1 , ${width} do
				local colour = colours[offset + x]
				insert(back, closest(cols, colour[1], colour[2], colour[3]))
			end

			set(1, y)
			blit(concat(back))
		end
	end
	]]

	if depthTest ~= false then
		insertVars [[
		export.loveDepth = function(love, oX, oY)
			local setPoint, setColour = love.graphics.point, love.graphics.setColor
			oX = oX or 0
			oY = oY or 0

			for y = 1, ${height} do
				local offset = (y - 1) * ${width}
				for x = 1, ${width} do
					if depth[offset + x] ~= inf then
						local color = 255 - ((depth[offset + x] + 1) / 2 * 255)
						setColour(color, color, color, 255)
						setPoint(oX + x + ${width}, oY + y)
					end
				end
			end
		end
		]]
	end

	insertVars "export.size = function() return ${width}, ${height} end\n"

	insert(builder, "return export\n")

	return concat(builder)
end

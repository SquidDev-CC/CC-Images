local execAsync = commands.native.execAsync
local floor, setmetatable, ipairs = math.floor, setmetatable, ipairs

--- Collection of tables with default values
local autoGet = {
	__index = function(self, key)
		local value = {}
		self[key] = value
		return value
	end
}

local autoGetParent = {
	__index = function(self, key)
		local value = setmetatable({}, autoGet)
		self[key] = value
		return value
	end
}

-- Creates a command
return function(block)
	--- Create a 3D lookup table
	local drawn = setmetatable({}, autoGetParent)

	local function setBlock(x, y, z)
		x, y, z = floor(x), floor(y), floor(z)

		-- Check we haven't already drawn this
		local xDrawn = drawn[x]
		local yDrawn = xDrawn[y]
		if yDrawn[z] then
			return
		else
			yDrawn[z] = true
		end

		execAsync("setblock ~" .. x .. " ~" .. y .. " ~" .. z .. " " .. block)
	end

	local function clearBlocks()
		for x, row in pairs(drawn) do
			for y, column in pairs(row) do
				for z, _ in pairs(column) do
					execAsync("setblock ~" .. x .. " ~" .. y .. " ~" .. z .. " minecraft:air")
				end
			end
		end
		drawn = setmetatable({}, autoGetParent)
	end

	local function setBlockType(b)
		block = b
	end

	return {
		setBlock = setBlock,
		clearBlocks = clearBlocks,
		setBlockType = setBlockType
	}
end

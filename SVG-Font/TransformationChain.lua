local ipairs = ipairs
local sin, cos, radians = math.sin, math.cos, math.rad

return function(pixel)
	local root = pixel

	local chain = {}
	local bookmarks = {}

	--- Push a bookmark onto the stack.
	--  This is similar to as gl.pushMatrix()
	local function push()
		local chainLength = #chain
		local bookmarkLength = #bookmarks

		-- Can't do anything if nothing is set
		if chainLength == 0 or bookmarks[bookmarkLength] == chainLength then
			return
		end

		bookmarks[bookmarkLength + 1] = chainLength
	end

	--- Pop a bookmark from the stack
	--  This is similar to as gl.popMatrix()
	local function pop()
		local chainLength = #chain
		local bookmarkLength = #bookmarks

		local nextItem = bookmarks[bookmarkLength]
		bookmarks[bookmarkLength] = nil
		for i = chainLength, nextItem + 1, -1 do
			chain[i] = nil
		end
	end

	--- Add a transformation item
	local function add(item)
		chain[#chain + 1] = item
	end

	--- Passes the values through the chain
	local function pixel(x, y, z)
		for _, tranform in ipairs(chain) do
			x, y, z = tranform(x, y, z)
		end

		return root(x, y, z)
	end

	--- Passes the values through the chain
	local function pixel2d(x, y)
		return pixel(x, y, 0)
	end

	--[[
		Transformation factories
	]]
		--- Create a scale transformation
		local function createScale(xScale, yScale, zScale)
			return function(x, y, z)
				return x * xScale, y * yScale, z * zScale
			end
		end

		--- Create a translate transformation
		local function createTranslate(xTranslate, yTranslate, zTranslate)
			return function(x, y, z)
				return x + xTranslate, y + yTranslate, z + zTranslate
			end
		end

		--- Create a rotation transformation
		local function createRotate(xRot, yRot, zRot)
			xSinT = sin(radians(xRot))
			xCosT = cos(radians(xRot))

			ySinT = sin(radians(yRot))
			yCosT = cos(radians(yRot))

			zSinT = sin(radians(zRot))
			zCosT = cos(radians(zRot))

			return function(x, y, z)
				if x == 0 and y ==0 and z == 0 then
					return 0, 0, 0
				end

				-- Handle Z rotation
				if zRot ~= 0 then
					-- Get original x and y
					local xo, yo = x, y

					-- Vertex positions
					x = zCosT * xo - zSinT * yo
					y = zSinT * xo + zCosT * yo
				end

				-- Handle Y rotation
				if y ~= 0 then
					-- Get original x and z
					local xo, zo = x, z

					x = yCosT * xo - ySinT * zo
					z = ySinT * xo + yCosT * zo
				end

				-- Handle X rotation
				if xRot ~= 0 then
					-- Get original y and z
					local yo, zo = y, z

					y = xCosT * yo - xSinT * zo
					z = xSinT * yo + xCosT * zo
				end

				return x, y, z
			end
		end

	--[[
		Tranformation additions
	]]
		--- Add a scale tranformation
		local function scale(x, y, z)
			return add(createScale(x, y or x, z or x))
		end

		--- Add a translate tranformation
		local function translate(x, y, z)
			return add(createTranslate(x, y, z))
		end

		--- Add a rotate tranformation
		local function rotate(x, y, z)
			return add(createRotate(x, y, z))
		end

	--- @export
	return {
		push = push,
		pop = pop,
		pixel = pixel,
		pixel2d = pixel2d,

		add = add,
		scale = scale,
		translate = translate,
		rotate = rotate,
	}
end

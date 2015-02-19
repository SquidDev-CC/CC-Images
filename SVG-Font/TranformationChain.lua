local function transformChain(pixel)
	local root = pixel
	local currentPixel = pixel

	local chain = {}
	local bookmarks = {}

	--- Push a bookmark onto the stack.
	--  This is similar to as gl.pushMatrix()
	local function push()
		local chainLength = #chain
		local bookmarkLength = #bookmarks

		-- Can't do anything if nothing is set
		if chainLength <= 0 or bookmarks[bookmarkLength] == chainLength then
			return
		end

		bookmarks[bookmarkLength + 1] = chainLength
	end

	--- Pop a bookmark from the stack
	--  This is similar to as gl.popMatrix()
	local function pop()
		local chainLength = #chain
		local bookmarkLength = #bookmarks

		bookmarks[bookmarkLength] = nil
		local nextItem = bookmarks[bookmarkLength - 1]
		for i = chainLength, nextItem + 1, -1 do
			chain[i] = nil
		end

		currentPixel = chain[nextItem]
	end

	--- Add a transformation item
	local function add(item)
		chain[#chain + 1] = item
		currentPixel = pixel
	end

	--- Get the current pixel renderer
	local function current()
		return currentPixel
	end

	--- Get a link to the top pixel
	local function latest()
		return function(x, y, z)
			return currentPixel(x, y, z)
		end
	end

	--[[
		Transformation factories
	]]
		--- Create a scale transformation
		-- @tparam function pixel The parent pixel function
		local function createScale(pixel, xScale, yScale, zScale)
			return function(x, y, z)
				return pixel(x * xScale, y * yScale, z * zScale)
			end
		end

		--- Create a translate transformation
		-- @tparam function pixel The parent pixel function
		local function createTranslate(pixel, xTranslate, yTranslate, zTranslate)
			return function(x, y, z)
				return pixel(x + xTranslate, y + yTranslate, z + zTranslate)
			end
		end

	--[[
		Tranformation additions
	]]
		--- Add a scale tranformation
		local function scale(x, y, z)
			return add(createScale(currentPixel, x, y or x, z or y))
		end

		--- Add a translate tranformation
		local function translate(x, y, z)
			return add(createTranslate(currentPixel, x, y, z))
		end

	--- @export
	return {
		push = push,
		pop = pop,
		latest = latest,
		current = current,

		scale = scale,
		translate = translate,
	}
end

return transformChain

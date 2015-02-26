local abs, min = math.abs, math.min

--- A drawing API that takes a pixel as the first argument
return function(pixel)
	assert(pixel, "Pixel function must be specified")

	-- Shamelessly borrowed from cc internal source
	local function line(startX, startY, endX, endY)
		startX = startX
		startY = startY
		endX = endX
		endY = endY

		-- Ignore tiny lines
		if startX == endX and startY == endY then
			pixel(startX, startY)
			return
		end

		local minX = min(startX, endX)
		if minX == startX then
			minY = startY
			maxX = endX
			maxY = endY
		else
			minY = endY
			maxX = startX
			maxY = startY
		end

		local xDiff = maxX - minX
		local yDiff = maxY - minY

		if xDiff > abs(yDiff) then
			local y = minY
			local dy = yDiff / xDiff
			for x = minX, maxX do
				pixel(x, y + 0.5)
				y = y + dy
			end
		else
			local x = minX
			local dx = xDiff / yDiff
			if maxY >= minY then
				for y = minY, maxY do
					pixel(x + 0.5, y)
					x = x + dx
				end
			else
				for y = minY, maxY, -1 do
					pixel(x + 0.5, y)
					x = x - dx
				end
			end
		end
	end

	local bezier
	do
		-- This will probably not be that accurate. Meh
		local factorials = {
			[0] = 1.0,
			1.0,
			2.0,
			6.0,
			24.0,
			120.0,
			720.0,
			5040.0,
			40320.0,
			362880.0,
			3628800.0,
			39916800.0,
			479001600.0,
			6227020800.0,
			87178291200.0,
			1307674368000.0,
			20922789888000.0,
			355687428096000.0,
			6402373705728000.0,
			121645100408832000.0,
			2432902008176640000.0,
			51090942171709440000.0,
			1124000727777607680000.0,
			25852016738884976640000.0,
			620448401733239439360000.0,
			15511210043330985984000000.0,
			403291461126605635584000000.0,
			10888869450418352160768000000.0,
			304888344611713860501504000000.0,
			8841761993739701954543616000000.0,
			265252859812191058636308480000000.0,
			8222838654177922817725562880000000.0,
			263130836933693530167218012160000000.0,
		}
		local function factorial(n)
			return factorials[n] or error("0 <= n <= 32")
		end

		local function Ni(n, i)
			return factorial(n) / (factorial(i) * factorial(n - i));
		end

		local function bernstein(n, i, t)
			return Ni(n, i) * (t ^ i) * ((1 - t) ^ (n - i))
		end


		--- Draw a bezier curve.
		-- @tparam table points in the form {x1, y2, x2, y2, x3, y3, ...}
		-- @tparam int Number of points on the curve needed
		bezier = function(points, pointCount)
			pointCount = pointCount or 500

			local numberPoints = (#points / 2) - 1

			local step = 1 / (pointCount - 1)
			local t = 0

			for point = 1, pointCount do
				-- Prevent infinite loops or something I guess?
				if (1 - t) < 5e-6 then
					t = 1
				end

				local index = 1
				local x, y = 0, 0

				for i = 0, numberPoints do
					-- For each point do things
					local basis = bernstein(numberPoints, i, t)
					x = x + (basis * points[index])
					y = y + (basis * points[index + 1])
					index = index + 2
				end

				pixel(x, y)
				t = t + step
			end
		end
	end

	return {
		line = line,
		bezier = bezier,
	}
end

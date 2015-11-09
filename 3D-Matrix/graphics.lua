--[[
	Line and triangle drawing taken from:
		- http://www.sunshine2k.de/coding/java/Bresenham/RasterisingLinesCircles.pdf
		- http://www.sunshine2k.de/coding/java/TriangleRasterization/TriangleRasterization.html
]]

local floor, ceil, abs, inf = math.floor, math.ceil, math.abs, math.huge

return function(width, height, defColour)
	local colours = {}
	local depth = {}

	-- TODO: Clear and clear colour/depth buffers
	local function clear(colour)
		for i = 1, width * height do
			colours[i] = colour
			depth[i] = inf
		end
	end

	clear(defColour or {0, 0, 0, 255})

	local function pixel(x, y, z, colour)
		-- Culling in all 3 axes
		if x < 1 or x > width or y < 1 or y > height or z > 1 or z < -1 then return end

		-- Only on debug:
		-- if floor(x) ~= x or floor(y) ~= y then error("Invalid coordinate: " .. x .. ", " .. y, 2) end

		local index = width * (y - 1) + x
		if z < depth[index] then
			-- TODO: Alpha blending
			colours[index] = colour
			depth[index] = z
		end
	end

	local function line(x1, y1, z1, x2, y2, z2, colour)
		if -- Apply some basic culling to avoid useless rendering
			(z1 < -1 and z2 < -1) or (z1 > 1 and z2 > 1) or
			(x1 < 1 and x2 < 1) or (x1 > width and x2 > width) or
			(y1 < 1 and y2 < 1) or (y1 > height and y2 > height)
		then return end

		x1 = floor(x1)
		x2 = floor(x2)
		y1 = floor(y1)
		y2 = floor(y2)

		local ndx, ndy = x2 - x1, y2 - y1
		local dx, dy = abs(ndx), abs(ndy)
		local steep = dy > dx
		if steep then
			dy, dx = dx, dy
		end

		local z, dz = z1, (z2 - z1) / dx

		local e = 2 * dy - dx
		local x, y = x1, y1

		local signy, signx = 1, 1
		if ndx < 0 then signx = -1 end
		if ndy < 0 then signy = -1 end

		for i = 1, dx do
			pixel(x, y, z, colour)
			while e >= 0 do
				if steep then
					x = x + signx
				else
					y = y + signy
				end
				e = e - 2 * dx
			end

			-- We could totally get rid of this branch by a normal sign method. Not sure if it would increase performance though.
			if steep then
				y = y + signy
			else
				x = x + signx
			end
			e = e + 2 * dy

			z = z + dz
		end

		-- Draw last point just in case
		pixel(x2, y2, z2, colour)
	end

	local function lineBlended(x1, y1, z1, x2, y2, z2, colour1, colour2)
		if -- Apply some basic culling to avoid useless rendering
			(z1 < -1 and z2 < -1) or (z1 > 1 and z2 > 1) or
			(x1 < 1 and x2 < 1) or (x1 > width and x2 > width) or
			(y1 < 1 and y2 < 1) or (y1 > height and y2 > height)
		then return end

		x1 = floor(x1)
		x2 = floor(x2)
		y1 = floor(y1)
		y2 = floor(y2)

		local ndx, ndy = x2 - x1, y2 - y1
		local dx, dy = abs(ndx), abs(ndy)
		local steep = dy > dx
		if steep then
			dy, dx = dx, dy
		end


		local z = z1
		local dz = (z2 - z1) / dx

		local r, g, b, a = colour1[1], colour1[2], colour1[3], colour1[4]
		local dr, dg, db, da = (colour2[1] - r) / dx, (colour2[2] - g) / dx, (colour2[3] - b) / dx, (colour2[4] - a) / dx

		local e = 2 * dy - dx
		local x, y = x1, y1
		local signy, signx = 1, 1
		if ndx < 0 then signx = -1 end
		if ndy < 0 then signy = -1 end

		for i = 1, dx do
			pixel(x, y, z, {r, g, b, a})
			while e >= 0 do
				if steep then
					x = x + signx
				else
					y = y + signy
				end
				e = e - 2 * dx
			end

			if steep then
				y = y + signy
			else
				x = x + signx
			end
			e = e + 2 * dy

			z = z + dz
			r, g, b, a = r + dr, g + dg, b + db, a + da
		end

		-- Draw last point just in case
		pixel(x2, y2, z2, colour2)
	end

	local triangleBlended, triangle
	do
		local function outline(x1, y1, z1, x2, y2, z2, x3, y3, z3, colour)
			line(x1, y1, z1, x2, y2, z2, colour)
			line(x1, y1, z1, x3, y3, z3, colour)
			line(x2, y2, z2, x3, y3, z3, colour)
		end
		-- Fills a triangle whose bottom side is perfectly horizontal.
		-- Precondition is that v2 and v3 perform the flat side and that v1.y < v2.y, v3.y.
		local function fillBottomTriangle(x1, y1, z1, x2, y2, z2, x3, y3, z3, colour1, colour2, colour3)
			local xStart, xEnd = x1, x1 + 0.5
			local zStart, zEnd = z1, z1
			local rStart, gStart, bStart, aStart = colour1[1], colour1[2], colour1[3], colour1[4]
			local rEnd, gEnd, bEnd, aEnd = rStart, gStart, bStart, aStart

			-- d_2: Changes along edge v2 => v1
			-- d_3: Changes along edge v3 => v1
			-- slope1, slope2
			local dy2, dy3 = y2 - y1, y3 - y1

			local dx2, dx3 = (x2 - x1) / dy2, (x3 - x1) / dy3
			local dz2, dz3 = (z2 - z1) / dy2, (z3 - z1) / dy3
			local dr2, db2, dg2, da2 = (colour2[1] - rStart) / dy2, (colour2[2] - gStart) / dy2, (colour2[3] - bStart) / dy2, (colour2[4] - aStart) / dy2
			local dr3, db3, dg3, da3 = (colour3[1] - rStart) / dy3, (colour3[2] - gStart) / dy3, (colour3[3] - bStart) / dy3, (colour3[4] - aStart) / dy3

			-- X1 must be smaller than X2, so we swap everything round
			if dx3 < dx2 then
				-- Swap coordinates
				dx2, dx3 = dx3, dx2
				dz2, dz3 = dz3, dz2
				-- Swap colours
				dr2, dr3 = dr3, dr2
				dg2, dg3 = dg3, dg2
				db2, db3 = db3, db2
				da2, da3 = da3, da2
			end

			for y = y1, y2 do
				if y >= 1 and y <= height then
					for x = ceil(xStart), xEnd do
						local t = (x - xStart) / (xEnd - xStart)
						local tInv = 1 - t

						pixel(
							x, y, tInv * zStart + t * zEnd,
							{
								tInv * rStart + t * rEnd,
								tInv * gStart + t * gEnd,
								tInv * bStart + t * bEnd,
								tInv * aStart + t * aEnd,
							}
						)
					end
				end

				xStart, xEnd = xStart + dx2, xEnd + dx3
				zStart, zEnd = zStart + dz2, zEnd + dz3

				rStart, rEnd = rStart + dr2, rEnd + dr3
				gStart, gEnd = gStart + dg2, gEnd + dg3
				bStart, bEnd = bStart + db2, bEnd + db3
				aStart, aEnd = aStart + da2, aEnd + da3
			end
		end

		-- Fills a triangle whose top side is perfectly horizontal
		-- v1 and v2 are on the flat side, and v3.y > v1.y, v2.y
		local function fillTopTriangle(x1, y1, z1, x2, y2, z2, x3, y3, z3, colour1, colour2, colour3)
			local xStart, xEnd = x3, x3 + 0.5
			local zStart, zEnd = z3, z3
			local rStart, gStart, bStart, aStart = colour3[1], colour3[2], colour3[3], colour3[4]
			local rEnd, gEnd, bEnd, aEnd = rStart, gStart, bStart, aStart

			-- d_2: Changes along edge v2 => v1
			-- d_3: Changes along edge v3 => v1
			local dy1, dy2 = y3 - y1, y3 - y2

			local dx1, dx2 = (x3 - x1) / dy1, (x3 - x2) / dy2
			local dz1, dz2 = (z3 - z1) / dy1, (z3 - z2) / dy2
			local dr1, db1, dg1, da1 = (rStart - colour1[1]) / dy1, (gStart - colour1[2]) / dy1, (bStart - colour1[3]) / dy1, (aStart - colour1[4]) / dy1
			local dr2, db2, dg2, da2 = (rStart - colour2[1]) / dy2, (gStart - colour2[2]) / dy2, (bStart - colour2[3]) / dy2, (aStart - colour2[4]) / dy2

			if dx1 < dx2 then
				-- Swap coordinates
				dx1, dx2 = dx2, dx1
				dz1, dz2 = dz2, dz1
				-- Swap colours
				dr1, dr2 = dr2, dr1
				dg1, dg2 = dg2, dg1
				db1, db2 = db2, db1
				da1, da2 = da2, da1
			end

			for y = y3, y1, -1 do
				xStart, xEnd = xStart - dx1, xEnd - dx2
				zStart, zEnd = zStart - dz1, zEnd - dz2

				rStart, rEnd = rStart - dr1, rEnd - dr2
				gStart, gEnd = gStart - dg1, gEnd - dg2
				bStart, bEnd = bStart - db1, bEnd - db2
				aStart, aEnd = aStart - da1, aEnd - da2

				if y >= 1 and y <= height then
					for x = ceil(xStart), xEnd do
						local t = (x - xStart) / (xEnd - xStart)
						local tInv = 1 - t

						pixel(
							x, y, tInv * zStart + t * zEnd,
							{
								tInv * rStart + t * rEnd,
								tInv * gStart + t * gEnd,
								tInv * bStart + t * bEnd,
								tInv * aStart + t * aEnd,
							}
						)
					end
				end
			end
		end

		triangleBlended = function(x1, y1, z1, x2, y2, z2, x3, y3, z3, c1, c2, c3)
			if -- Apply some basic culling to avoid useless rendering
				(z1 < -1 and z2 < -1 and z3 < -1) or (z1 > 1 and z2 > 1 and z3 > 1) or
				(x1 < 1 and x2 < 1 and x3 < 1) or (x1 > width and x2 > width and x3 > width) or
				(y1 < 1 and y2 < 1 and y3 < 1) or (y1 > height and y2 > height and y3 > height)
			then return end

			-- TODO: Do we floor now, or in the pixel renderer (or in main triangle method)
			x1, x2, x3 = floor(x1), floor(x2), floor(x3)
			y1, y2, y3 = floor(y1), floor(y2), floor(y3)


			if y1 > y2 then
				x1, x2 = x2, x1
				y1, y2 = y2, y1
				z1, z2 = z2, z1
				c1, c2 = c2, c1
			end
			-- here v1 <= v2
			if y1 > y3 then
				x1, x3 = x3, x1
				y1, y3 = y3, y1
				z1, z3 = z3, z1
				c1, c3 = c3, c1
			end
			-- here v1.y <= v2.y and v1.y <= v3.y so test v2 vs. v3
			if y2 > y3 then
				x2, x3 = x3, x2
				y2, y3 = y3, y2
				z2, z3 = z3, z2
				c2, c3 = c3, c2
			end

			if y2 == y3 then
				return fillBottomTriangle(x1, y1, z1, x2, y2, z2, x3, y3, z3, c1, c2, c3)
			elseif y1 == y2 then
				return fillTopTriangle(x1, y1, z1, x2, y2, z2, x3, y3, z3, c1, c2, c3)
			else
				-- Split coordinates
				local delta = (y2 - y1) / (y3 - y1)
				local x, z = floor(x1 + delta * (x3 - x1)), z1 + delta * (z3 - z1)

				local colour = {
					c1[1] + delta * (c3[1] - c1[1]),
					c1[2] + delta * (c3[2] - c1[2]),
					c1[3] + delta * (c3[3] - c1[3]),
					c1[4] + delta * (c3[4] - c1[4]),
				}

				print(1, x1, y1, z1)
				print(2, x2, y2, z2)
				print(2, x3, y3, z3)
				print(3, x, y2, z)
				print(colour[1], colour[2], colour[3])
				outline(x1, y1, -1, x2, y2, -1, x, y2, -1, colour)
				outline(x2, y2, -1, x, y2, -1, x3, y3, -1, colour)

				fillBottomTriangle(x1, y1, z1, x2, y2, z2, x, y2, z, c1, c2, colour)
				fillTopTriangle(x2, y2, z2, x, y2, z, x3, y3, z3, c2, colour, c3)

			end
		end
	end

	local function love(love, oX, oY)
		oX = oX or 0
		oY = oY or 0

		for y = 1, height do
			local offset = (y - 1) * width
			for x = 1, width do
				local colour = colours[offset + x]
				love.graphics.setColor(colour[1], colour[2], colour[3], colour[4])
				love.graphics.point(oX + x, oY + y)
			end
		end

		for y = 1, height do
			local offset = (y - 1) * width
			for x = 1, width do
				if depth[offset + x] ~= inf then
					local color = 255 - ((depth[offset + x] + 1) / 2 * 255)
					love.graphics.setColor(color, color, color, 255)
					love.graphics.point(oX + x + width, oY + y)
				end
			end
		end
	end

	return {
		love = love,
		clear = clear,

		line = line,
		lineBlended = lineBlended,
		pixel = pixel,
		triangleBlended = triangleBlended,
	}
end





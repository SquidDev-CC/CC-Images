local graphics, glasses = ...

local clip = require "clip"
local matrix = require "matrix"
local transform = require "transform"

local mobCache = {}

-- Background colour of the frame
local frameCol = graphics.rgb(0, 0, 0)

-- Opacity of the frame
local frameOpacity = 0.3

-- Width of the frame
local frameWidth = 60

-- The size to scale everything at
local frameScale = 2

-- Padding around the edges
local framePadding = 2

-- The height of the name
local nameHeightBase = 8

-- Background colour of the bar for health/lack of it
local barCol1 = graphics.rgb(0, 255, 0)
local barCol2 = graphics.rgb(255, 0, 0)

-- The height of the bar
local barHeightBase = 5

-- Padding within the bar
local barPadding = 1

-- Distance to start fading out at
local fadeDistance = 20

-- Distance to hide at
local maxDistance = 30


return function(mvp, pData)
	local x, y, z = pData.position.x, pData.position.y, pData.position.z

	-- Scan for nearby mobs. Attempt to do it in parallel to reduce lag
	-- This will take 2-3 ticks depending on whether we've cached the mob data
	local mobs = peripheral.call("right", "getMobIds")
	if #mobs == 0 then return end

	local data, functions = {}, {}
	for _, id in ipairs(mobs) do
		functions[#functions + 1] = function()
			local mob = mobCache[id]
			if not mob then
				mob = peripheral.call("right", "getMobData", id)
				mobCache[id] = mob
			end
			data[id] = mob.all()
		end
	end

	parallel.waitForAll(unpack(functions))

	for _, id in ipairs(mobs) do
		local mob = data[id]
		local pos = mob.position

		-- Clip the point
		-- Scene coordinates are flipped compared with world coordinates.
		local _, clip, proj = clip.transform({-pos.x + 0.5, -pos.y - 0.5, -pos.z + 0.5, 1}, mvp)

		-- If the point is within the screen
		if mob.living.isAlive and clip[1] then
			-- Don't render if a long way away
			local distance = math.sqrt((x - pos.x)^2 + (y - pos.y)^2 + (z - pos.z)^2)
			if distance < maxDistance then
				local point = graphics.normalise(proj)

				local scale = frameScale / distance
				local width = frameWidth * scale
				local nameHeight = scale * nameHeightBase
				local barHeight = scale * barHeightBase
				local hWidth = width / 2

				local x, y = point[1], point[2]
				local fp = framePadding * scale
				local bp = barPadding * scale

				local barMiddle = y + nameHeight + barHeight/2

				local health = mob.living.health
				local maxHealth = mob.living.maxHealth

				local alpha = 1
				if distance > fadeDistance then
					alpha = alpha / (distance - fadeDistance)
					if alpha > 1 then alpha = 1 end
				end

				-- Render the frame with some padding
				local frame = glasses.addBox(x - hWidth - fp, y - fp, width + 2*fp, nameHeight + barHeight + 2*fp, frameCol)
				frame.setOpacity(alpha * frameOpacity)

				-- Render the text, centered within the frame
				local name = glasses.addText(x, y, mob.name)
				name.setObjectAnchor("middle", "top")
				name.setScale(nameHeight * 0.1)
				name.setAlpha(alpha)

				-- Render the health bar. We split this into start and end
				local barWidth = health / maxHealth * width
				local bar1 = glasses.addBox(x - hWidth, barMiddle, barWidth, barHeight, barCol1)
				bar1.setObjectAnchor("left", "middle")
				bar1.setOpacity(alpha)

				local bar2 = glasses.addBox(x - hWidth + barWidth, barMiddle, width - barWidth, barHeight, barCol2)
				bar2.setObjectAnchor("left", "middle")
				bar2.setOpacity(alpha)

				local hText = glasses.addText(x - hWidth + bp, barMiddle, ("%i"):format(health))
				hText.setScale(barHeight * 0.1)
				hText.setObjectAnchor("left", "middle")
				hText.setAlpha(alpha)

				local mText = glasses.addText(x + hWidth - bp, barMiddle, ("%i"):format(maxHealth))
				mText.setScale(barHeight * 0.1)
				mText.setObjectAnchor("right", "middle")
				mText.setAlpha(alpha)

				local pText = glasses.addText(x, barMiddle, ("%i%%"):format(health / maxHealth * 100))
				pText.setScale(barHeight * 0.1)
				pText.setObjectAnchor("middle", "middle")
				pText.setAlpha(alpha)
			end
		end
	end
end

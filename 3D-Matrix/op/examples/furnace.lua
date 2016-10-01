local graphics, glasses = ...

local clip = require "clip"
local matrix = require "matrix"
local transform = require "transform"

local furnaces = {
	furnace_0 = {  1, -1, 6, 1 },
	furnace_1 = {  2, -1, 6, 1 },
	furnace_2 = {  0, -1, 6, 1 },
	furnace_3 = { -1, -1, 6, 1 },
	furnace_4 = { -2, -1, 6, 1 },
}

return function(mvp, pData, x, y, z)
	local data, functions = {}, {}
	for k, _ in pairs(furnaces) do
		functions[#functions + 1] = function()
			data[k] = peripheral.call(k, "getCookTime")
		end
	end
	parallel.waitForAll(unpack(functions))

	for k, v in pairs(furnaces) do
		local _, clip, proj = clip.transform(v, mvp)
		if clip[1] then
			local point = graphics.normalise(proj)
			local distance = math.sqrt((x - v[1])^2 + (y - v[2])^2 + (z - v[3])^2)

			if distance < 20 then
				local scale = 2.5 / distance
				local alpha = 1 / (distance - 9)
				local width = 60 * scale
				local xPos = point[1] - width / 2
				local p = 2 * scale

				local bg = glasses.addBox(xPos - p, point[2] - p, width + p*2, 15 * scale + p*2, graphics.rgb(150, 150, 150))

				local text = glasses.addText(point[1], point[2], k)
				text.setObjectAnchor("middle", "top")
				text.setScale(scale)

				local box = glasses.addBox(xPos, point[2] + 10 * scale, data[k] / 200 * width, 5 * scale, graphics.rgb(255, 0, 0))

				if distance > 10 then
					text.setAlpha(alpha)
					bg.setOpacity(alpha)
					box.setOpacity(alpha)
				end
			end
			-- for k, v in pairs(x) do if k:find("^set") then print(k, v) end end
		end
	end
end

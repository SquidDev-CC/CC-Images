local pairs, unpack = pairs, unpack

local termSets = {
	[colors.white] = {240, 240, 240},
	[colors.orange] = {242, 178, 51},
	[colors.magenta] = {229, 127, 216},
	[colors.lightBlue] = {153, 178, 242},
	[colors.yellow] = {222, 222, 108},
	[colors.lime] = {127, 204, 25},
	[colors.pink] = {242, 178, 204},
	[colors.gray] = {76, 76, 76},
	[colors.lightGray] = {153, 153, 153},
	[colors.cyan] = {76, 153, 178},
	[colors.purple] = {178, 102, 229},
	[colors.blue] = {37, 49, 146},
	[colors.brown] = {127, 102, 76},
	[colors.green] = {5, 122, 100},
	[colors.red] = {204, 76, 76},
	[colors.black] = {0, 0, 0},
}

local strSets = {
	["0"] = {240, 240, 240},
	["1"] = {242, 178, 51},
	["2"] = {229, 127, 216},
	["3"] = {153, 178, 242},
	["4"] = {222, 222, 108},
	["5"] = {127, 204, 25},
	["6"] = {242, 178, 204},
	["7"] = {76, 76, 76},
	["8"] = {153, 153, 153},
	["9"] = {76, 153, 178},
	["a"] = {178, 102, 229},
	["b"] = {37, 49, 146},
	["c"] = {127, 102, 76},
	["d"] = {5, 122, 100},
	["e"] = {204, 76, 76},
	["f"] = {0, 0, 0},
}


local function colorDiff(r, g, b, r1, g1, b1)
	-- return ((r - r1) * .299)^2 + ((g - g1) * .587)^2 + ((b - b1) * .114)^2
	return (r - r1)^2 + (g - g1)^2 + (b - b1)^2
end

local function findClosestColor(colors, r, g, b)
	local smallestDifference = nil
	local smallestColor = nil
	for id, rgb in pairs(colors) do
		local diff = colorDiff(r, g, b, unpack(rgb))

		if not smallestDifference or diff < smallestDifference then
			smallestColor = id
			smallestDifference = diff
		end
	end

	return smallestColor
end

return {
	findClosestColor = findClosestColor,
	termSets = termSets,
	strSets = strSets,
}

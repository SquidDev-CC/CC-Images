local Cols = {
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
function FindClosestColour(R, G, B)
	local SmallDiff = nil
	local SmallCol = nil
	for K, V in pairs(Cols) do
		local diff = math.abs(V[1] - R) + math.abs(V[2] - G) + math.abs(V[3] - B)

		if SmallDiff == nil or diff < SmallDiff then
			SmallCol = K
			SmallDiff = diff
		end
	end
	return SmallCol
end
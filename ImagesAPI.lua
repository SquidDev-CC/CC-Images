function parseFile(path)
	local BinFile = BinaryFile:new(path)
	return BitmapParser:new(BinFile)
end

function drawImage(parser, redirect)
	redirect = redirect or term
	for y, row in pairs(parser.Pixels) do
		for x, color in pairs(row) do
			redirect.setCursorPos(x, y)
			redirect.setBackgroundColour(color)
			redirect.write(" ")
		end
	end
end

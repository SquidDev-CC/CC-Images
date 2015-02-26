local pairs, unpack = pairs, unpack

function parseFile(path)
	local BinFile = BinaryFile:new(path)
	return BitmapParser:new(BinFile)
end


local closest, termSets = Colors.findClosestColor, Colors.termSets
function createTermPixel(redirect)
	redirect = redirect or term
	return function(x, y, color)
		redirect.setCursorPos(x, y)
		redirect.setBackgroundColour(findClosestColor(termSets, unpack(color)))
		redirect.write(" ")
	end
end

termPixel = createTermPixel()

function drawImage(parser, pixel)
	pixel = pixel or termPixel
	for y, row in pairs(parser.pixels) do
		for x, color in pairs(row) do
			pixel(x, y, color)
		end
	end
end

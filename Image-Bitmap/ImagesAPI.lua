local pairs, unpack = pairs, unpack

function parseFile(path)
	local BinFile = BinaryFile:new(path)
	return BitmapParser:new(BinFile)
end


local closest, termSets = Colours.findClosestColor, Colours.termSets
function createTermPixel(term)
	return function(x, y, color)
		term.setCursorPos(x, y)
		term.setBackgroundColour(findClosestColor(termSets, unpack(color)))
		term.write(" ")
	end
end

termPixel = createTermPixel(term)

function drawImage(parser, pixel)
	pixel = pixel or termPixel
	for y, row in pairs(parser.pixels) do
		for x, color in pairs(row) do
			pixel(x, y, color)
		end
	end
end

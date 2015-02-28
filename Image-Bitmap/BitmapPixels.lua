local BitmapPixels = Class:subClass("BitmapPixels")

function BitmapPixels:init(parser)
	self.parser = parser
	self.pixels = parser.pixels
	self.file = parser.file

	self.width = parser.width
	self.height = parser.height
end

function BitmapPixels:parse()
	local width = self.width
	for Y = self.height, 1, -1 do
		local row = {}
		self.pixels[Y] = row

		local startOffset = self.file.offset
		for X = 1, width, 1 do
			row[X] = self:parsePixel()
		end

		self:finaliseRow()

		local pixelsRemaning = (self.file.offset - startOffset) % 4
		if pixelsRemaning > 0 then
			self.file:discardBytes(4 - pixelsRemaning)
		end
	end

	self.file:close()
end

function BitmapPixels:parsePixel() return 1 end
function BitmapPixels:finaliseRow() end

return BitmapPixels

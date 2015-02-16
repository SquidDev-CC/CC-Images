local BitmapPixels = Class:subClass("BitmapPixels")

function BitmapPixels:init(Parser)
	self.Parser = Parser
	self.Pixels = Parser.Pixels
	self.File = Parser.File

	self.Width = Parser.Width
	self.Height = Parser.Height
end

function BitmapPixels:Parse()
	local Width = self.Width
	for Y = self.Height, 1, -1 do
		local Row = {}
		self.Pixels[Y] = Row

		local StartOffset = self.File.Offset
		for X = 1, Width, 1 do
			Row[X] = self:ParsePixel()
		end

		self:FinaliseRow()

		local RowWidth = self.File.Offset - StartOffset
		self.File:DiscardBytes(4 - (RowWidth % 4))

	end

	self.File:Close()
end

function BitmapPixels:ParsePixel() return 1 end
function BitmapPixels:FinaliseRow() end

return BitmapPixels

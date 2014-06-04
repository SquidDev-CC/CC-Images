--@require Bitmap.lua
--@require Colours.lua

--Monochrome bitmap

BitmapMono = BitmapPixels:subClass("BitmapMono")
function BitmapMono:init(Parser)
	self:super(BitmapPixels).init(Parser)

	self.Byte = nil
	self.BitPosition = 0

	self.File:DiscardBytes(Parser.Starts - self.File.Offset)
end

function BitmapMono:ParsePixel()
	
	if self.Byte == nil then
		local Byte = self.File:ReadByte()

		local ByteT = {}
		local Counter = 1
		while (Counter <= 8) do
			local Last = Byte % 2
			if(Last == 1) then
				ByteT[Counter] = colors.black
			else
				ByteT[Counter] = colors.white
			end
			Byte = (Byte-Last)/2
			Counter = Counter + 1
		end

		self.Byte = ByteT

		self.BitPosition = 9
	end

	self.BitPosition = self.BitPosition - 1
	return self.Byte[self.BitPosition]
end

function BitmapMono:FinaliseRow()
	self.Byte = nil
	self.BitPosition = 0
end

--4 Bit Bitmap
BitmapFour = BitmapPixels:subClass("Bitmap4")
function BitmapFour:init(Parser)
	self:super(BitmapPixels).init(Parser)

	self.Colours = {}
	for I = 0, 15, 1 do
		local B = self.File:ReadByte()
		local G = self.File:ReadByte()
		local R = self.File:ReadByte()

		self.File:ReadByte() -- Should be 0

		self.Colours[I] = FindClosestColour(R, G, B)
	end

	self.Byte = nil
end
function BitmapFour:ParsePixel()
	local ThisColour = nil

	if self.Byte == nil then
		local Byte = self.File:ReadByte()

		ThisColour = math.floor(Byte / 16)
		self.Byte = Byte % 16
	else
		ThisColour = self.Byte
		self.Byte = nil
	end

	return self.Colours[ThisColour]
end

function BitmapFour:FinaliseRow()
	self.Byte = nil
end

--Eight bit bitmap
BitmapEight = BitmapPixels:subClass("Bitmap8")
function BitmapEight:init(Parser)
	self:super(BitmapPixels).init(Parser)

	self.Colours = {}
	for I = 0, 255, 1 do
		local B = self.File:ReadByte()
		local G = self.File:ReadByte()
		local R = self.File:ReadByte()

		self.File:ReadByte() -- Should be 0

		self.Colours[I] = FindClosestColour(R, G, B)
	end
end
function BitmapEight:ParsePixel()
	return self.Colours[self.File:ReadByte()]
end

--24 bit bitmap
BitmapTwentyFour = BitmapPixels:subClass("Bitmap24")
function BitmapTwentyFour:init(Parser)
	self:super(BitmapPixels).init(Parser)

	self.File:DiscardBytes(Parser.Starts - self.File.Offset)
end
function BitmapTwentyFour:ParsePixel()
	local B = self.File:ReadByte()
	local G = self.File:ReadByte()
	local R = self.File:ReadByte()

	return FindClosestColour(R, G, B)
end
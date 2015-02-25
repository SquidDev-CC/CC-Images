local black, white = {0, 0, 0}, {255, 255, 255}

--Monochrome bitmap

local BitmapMono = BitmapPixels:subClass("BitmapMono")

function BitmapMono:init(Parser)
	self:super(BitmapPixels).init(Parser)

	self.byte = nil
	self.bitPosition = 0

	self.file:discardBytes(Parser.Starts - self.file.Offset)
end

function BitmapMono:parsePixel()

	if self.byte == nil then
		local byte = self.file:readByte()

		local byteT = {}
		local counter = 1
		while (counter <= 8) do
			local last = byte % 2
			if(last == 1) then
				byteT[counter] = black
			else
				byteT[counter] = white
			end
			byte = (byte-last)/2
			counter = counter + 1
		end

		self.byte = byteT

		self.bitPosition = 9
	end

	self.bitPosition = self.bitPosition - 1
	return self.byte[self.bitPosition]
end

function BitmapMono:finaliseRow()
	self.byte = nil
	self.bitPosition = 0
end

--4 Bit Bitmap
local BitmapFour = BitmapPixels:subClass("Bitmap4")

function BitmapFour:init(Parser)
	self:super(BitmapPixels).init(Parser)

	self.colors = {}
	for I = 0, 15, 1 do
		local b = self.file:readByte()
		local g = self.file:readByte()
		local r = self.file:readByte()

		self.file:readByte() -- Should be 0

		self.colors[I] = {r, g, b}
	end

	self.byte = nil
end

function BitmapFour:parsePixel()
	local thisColour = nil

	if self.byte == nil then
		local byte = self.file:readByte()

		thisColour = math.floor(byte / 16)
		self.byte = byte % 16
	else
		thisColour = self.byte
		self.byte = nil
	end

	return self.colors[thisColour]
end

function BitmapFour:finaliseRow()
	self.byte = nil
end

--Eight bit bitmap
local BitmapEight = BitmapPixels:subClass("Bitmap8")

function BitmapEight:init(Parser)
	self:super(BitmapPixels).init(Parser)

	self.colors = {}
	for I = 0, 255, 1 do
		local b = self.file:readByte()
		local g = self.file:readByte()
		local r = self.file:readByte()

		self.file:readByte() -- Should be 0

		self.colors[I] = {r, g, b}
	end
end

function BitmapEight:parsePixel()
	return self.colors[self.file:readByte()]
end

--24 bit bitmap
local BitmapTwentyFour = BitmapPixels:subClass("Bitmap24")

function BitmapTwentyFour:init(Parser)
	self:super(BitmapPixels).init(Parser)

	self.file:discardBytes(Parser.Starts - self.file.Offset)
end

function BitmapTwentyFour:parsePixel()
	local b = self.file:readByte()
	local g = self.file:readByte()
	local r = self.file:readByte()

	return {r, g, b}
end

return {
	[1]  = BitmapMono,
	[4]  = BitmapFour,
	[8]  = BitmapEight,
	[24] = BitmapTwentyFour,
}

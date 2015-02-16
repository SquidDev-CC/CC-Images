local BitmapParser = Class:subClass("BitmapParser")

function BitmapParser:init(File)
	self.File = File

	--==================================
	--Bitmap file header
	--==================================
	self.HeaderField = string.char(File:ReadByte()) .. string.char(File:ReadByte())
	self.Size = File:ReadBytes(4)

	--Useless bytes (not useless but kinda are)
	File:DiscardBytes(4)
	self.Starts = File:ReadBytes(4)
	--==================================
	-- BITMAPINFOHEADER (DBI Header)
	--==================================
	self.HeaderSize = File:ReadBytes(4)
	self.Width = File:ReadBytes(4)
	self.Height = File:ReadBytes(4)

	self.ColourPlanes = File:ReadBytes(2)

	self.ColourDepth = File:ReadBytes(2)

	self.Compression = File:ReadBytes(4)

	--More junky stuff
	File:DiscardBytes(4) --the image size. This is the size of the raw bitmap data; a dummy 0 can be given for BI_RGB bitmaps.
	File:DiscardBytes(4) --the horizontal resolution of the image. (pixel per meter, signed integer)
	File:DiscardBytes(4) --the vertical resolution of the image. (pixel per meter, signed integer)
	File:DiscardBytes(4) --the number of colors in the color palette, or 0 to default to 2^n
	File:DiscardBytes(4) --the number of important colors used, or 0 when every color is important; generally ignored

	--Should have an offset of 55

	self.Pixels = {}

	local PixelParser = BitmapDepths[self.ColourDepth]
	if not PixelParser then
		error("Can't find a parser for depth "..tostring(Parser.ColourDepth))
	end

	PixelParser:new(self):Parse()
end

function BitmapParser:Save(Handle, Save)
	if type(Handle) == "string" then
		Handle = fs.open(Handle, "w")
		Save = true
	end

	for Y, Values in pairs(self.Pixels) do
		local Line = ""
		for X, Col in pairs(Values) do
			local Value = math.floor(math.log(Col) / math.log(2)) + 1
			if Value >= 1 and Value <= 16 then
				Line = Line..string.sub("0123456789abcdef", Value, Value)
			end
		end

		Handle.writeLine(Line)
	end

	if Save then
		Handle.close()
	end
end

return BitmapParser

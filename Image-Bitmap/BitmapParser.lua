local floor, log, sub, pairs = math.floor, math.log, string.sub, pairs

local BitmapParser = Class:subClass("BitmapParser")

function BitmapParser:init(file)
	self.file = file

	--==================================
	--Bitmap file header
	--==================================
	self.headerField = string.char(file:readByte()) .. string.char(file:readByte())
	self.size = file:readBytes(4)

	--Useless bytes (not useless but kinda are)
	file:discardBytes(4)
	self.starts = file:readBytes(4)
	--==================================
	-- BITMAPINFOHEADER (DBI Header)
	--==================================
	self.headerSize = file:readBytes(4)
	self.width = file:readBytes(4)
	self.height = file:readBytes(4)

	self.colourPlanes = file:readBytes(2)

	self.colourDepth = file:readBytes(2)

	self.compression = file:readBytes(4)

	--More junky stuff
	file:discardBytes(4) --the image size. This is the size of the raw bitmap data; a dummy 0 can be given for BI_RGB bitmaps.
	file:discardBytes(4) --the horizontal resolution of the image. (pixel per meter, signed integer)
	file:discardBytes(4) --the vertical resolution of the image. (pixel per meter, signed integer)
	file:discardBytes(4) --the number of colors in the color palette, or 0 to default to 2^n
	file:discardBytes(4) --the number of important colors used, or 0 when every color is important; generally ignored

	--Should have an offset of 55

	self.pixels = {}

	local pixelParser = BitmapDepths[self.colourDepth]
	if not pixelParser then
		error("Can't find a parser for depth "..tostring(self.colourDepth))
	end

	pixelParser:new(self):parse()
end

local closest, strSets = Colors.findClosestColor, Colors.strSets
function BitmapParser:save(handle, save)
	if type(handle) == "string" then
		handle = fs.open(handle, "w")
		save = true
	end

	for y, values in pairs(self.pixels) do
		local Line = ""
		for x, col in pairs(values) do
			line = line .. findClosestColor(strSets, unpack(col))
		end

		handle.writeLine(Line)
	end

	if save then
		handle.close()
	end
end

return BitmapParser

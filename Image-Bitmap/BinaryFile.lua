local BinaryFile = Class:subClass("BinaryFile")

function BinaryFile:init(path)
	self.path = path
	self.offset = 0

	self.file = fs.open(path, "rb")
end

function BinaryFile:close()
	self.file.close()
	self.file = nil
end

function BinaryFile:readByte()
	self.offset = self.offset + 1
	return self.file.read()
end
function BinaryFile:readBytes(length)
	local bytes = 0
	for i = 0, length - 1, 1 do
		bytes = bytes + (self:readByte() * (256 ^ i))
	end

	return bytes
end
function BinaryFile:discardBytes(length)
	for i = 1, length, 1 do
		self:readByte()
	end
end

return BinaryFile

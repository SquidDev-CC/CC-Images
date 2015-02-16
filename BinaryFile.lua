local BinaryFile = Class:subClass("BinaryFile")

function BinaryFile:init(Path)
	self.Path = Path
	self.Offset = 0

	self.File = fs.open(Path, "rb")
end

function BinaryFile:Close()
	self.File.close()
	self.File = nil
end

function BinaryFile:ReadByte()
	self.Offset = self.Offset + 1
	return self.File.read()
end
function BinaryFile:ReadBytes(Length)
	local Bytes = 0
	for I = 0, Length - 1, 1 do
		Bytes = Bytes + (self:ReadByte() * (256 ^ I))
	end

	return Bytes
end
function BinaryFile:DiscardBytes(Length)
	for I = 1, Length, 1 do
		self:ReadByte()
	end
end

return BinaryFile

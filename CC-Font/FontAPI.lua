function LoadFont(Path)
	local File = fs.open(Path, "rb")

	local Version = File.read()
	if Version ~= 1 then
		error("Unsupported version" + tostring(Version))
	end

	local CharacterWidth = File.read()
	local CharacterHeight = File.read()

	local Index = 3

	local Characters = {}

	while true do
		local Character = File.read()
		Index = Index + 1

		if Character == nil then
			break
		end

		local Pixels = {}
		local Row = {}

		local X = 1
		local Y = 1

		while true do
			local Byte = File.read()
			Index = Index + 1

			for _=7, 0, -1 do
				--Parse one bit
				local MaxBit = math.pow(2, _)
				local Last = Byte / MaxBit
				local Bit = 0
				if Last >= 1 then
					Bit = 1
				end
				Byte = Byte % MaxBit

				table.insert(Row, Bit)
				X = X + 1

				if X > CharacterWidth then
					table.insert(Pixels, Row)
					Row = {}
					
					X = 1
					Y = Y + 1

					if Y> CharacterHeight then
						break
					end
				end

			end

			if Y > CharacterHeight then
				break
			end
		end

		Characters[string.char(Character)] = Pixels
	end

	File.close()

	return Characters, CharacterWidth, CharacterHeight
end

function CreateObject(Font, Width, Height, Parent)
	if Parent == nil then
		Parent = term.current()
	end

	local NewTerm = {}
	
	local Back = colours.black
	local Front = colours.white

	local CursorX = 1
	local CursorY = 1

	local function GetPosition()
		return (CursorX - 1) * Width, (CursorY - 1) * Height
	end

	function NewTerm.write(Text)
		for _=1, #Text, 1 do
			local Character = Text:sub(_, _)

			local Pixels = Font[Character]
			if Pixels == nil then
				Pixels = Font['?']
			end

			local cX, cY = GetPosition()

			for Y = 1, Height, 1 do
				local Vals = Pixels[Y]
				for X = 1, Width, 1 do
					local Colour = Vals[X]
					term.setCursorPos(cX + X, cY + Y)

					if Colour == 1 then
						term.setBackgroundColour(Back)
					else
						term.setBackgroundColour(Front)
					end

					term.write(" ")
				end
			end

			CursorX = CursorX + 1

		end
	end

	function NewTerm.clearLine()
		local X, Y = GetPosition()

		for _=Y, Y+Height, 1 do
			term.setCursorPos(1, _)
			term.clearLine()
		end
	end

	NewTerm.getCursorPos = GetPosition
	function NewTerm.setCursorPos(X, Y)
		CursorX = X
		CursorY = Y
	end

	function NewTerm.setTextColour(Colour)
		Front = Colour
	end
	NewTerm.setTextColor = NewTerm.setTextColour

	function NewTerm.setBackgroundColour(Colour)
		Back = Colour
	end
	NewTerm.setBackgroundColor = NewTerm.setBackgroundColour


	--Copy across functions
	NewTerm.clear = Parent.clear()
	NewTerm.isColor = Parent.isColor()
	NewTerm.isColour = Parent.isColour()

	--NYI
	function NewTerm.getCursorBlink(CursorBlink) end
	return NewTerm
end
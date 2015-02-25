os.unloadAPI("Images")
if not Images then
	os.loadAPI(fs.combine(fs.getDir(shell.getRunningProgram()), "Images"))
end

local Args = {...}
if #Args < 2 then
	error("BitmapToFont.lua <Bitmap> <Font>")
end

local Version = 1

local function ColoursEqual(A, B)
	return (A[0] == B[0] and A[1] == B[1] and A[2] == B[2])
end

local Parser = Images.parseFile(shell.resolve(Args[1]))

local Characters = {}

local CharacterWidth = 0
local CharacterHeight = 0

local Background = Parser.Pixels[1][1]
local Black = {0, 0, 0}

local LastCharacterCode = 31


local function ParseCharacter(StartX, StartY)
	local Character = {}
	local MaxX = Parser.Width

	for Y = StartY, Parser.Height, 1 do
		if ColoursEqual(Parser.Pixels[Y][StartX], Background) then
			CharacterWidth = math.max(MaxX - StartX, CharacterWidth)
			CharacterHeight = math.max(Y - StartY, CharacterHeight)


			return Character, MaxX - StartX
		end

		local Row = {}

		for X = StartX, MaxX, 1 do
			local Colour = Parser.Pixels[Y][X]

			if ColoursEqual(Colour, Background) then
				MaxX = X
				break
			elseif ColoursEqual(Colour, Black) then
				table.insert(Row, 0)
			else
				table.insert(Row, 1)
			end
		end

		table.insert(Character, Row)
	end
end

local Y = 1
while Y <= Parser.Height do
	local X = 1
	local HadCharacter = false

	while X <= Parser.Width do
		local Colour = Parser.Pixels[Y][X]

		if ColoursEqual(Black, Colour) then
			LastCharacterCode = LastCharacterCode + 1
			local Pix, Width = ParseCharacter(X, Y)

			Characters[LastCharacterCode] = Pix
			X = X + Width

			HadCharacter = true
		end

		X = X + 1
	end

	if HadCharacter then
		Y = Y + CharacterHeight
	end
	Y = Y + 1
end

local Output = fs.open(shell.resolve(Args[2]), "wb")
Output.write(Version)
Output.write(CharacterWidth)
Output.write(CharacterHeight)

for Character, Pixels in pairs(Characters) do
	Output.write(Character)

	local Width = #Pixels[1]
	local Padding = math.floor((CharacterWidth - Width) / 2)

	local Count = 0
	local Byte = 0
	for Y = 1, CharacterHeight, 1 do
		os.queueEvent("a")
		os.pullEvent()

		local Row = Pixels[Y]
		for X = 1, CharacterWidth do
			X = X - Padding

			if Row==nil then
				break
			end
			local Cell = Row[X]

			if Cell == nil then
				Cell = 0
			end

			Byte = (Byte * 2) + Cell
			Count = Count + 1

			if Count == 8 then
				Output.write(Byte)
				Count = 0
				Byte = 0
			end
		end
	end

	if Count ~= 0 then
		Output.write(Byte * math.pow(2, 8 - Count))
	end
end

Output.close()

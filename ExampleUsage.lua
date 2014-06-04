
if not ImagesAPI then
	os.loadAPI(fs.combine(fs.getDir(shell.getRunningProgram()), "ImagesAPI"))
end

local args = {...}
if #args < 1 then
	error("ExampleUsage.lua <File>")
end

term.clear()
term.setCursorPos(1,1)

local BinFile = ImagesAPI.BinaryFile:new(args[1])
local Parser = ImagesAPI.BitmapParser:new(BinFile)

for Y, Values in pairs(Parser.Pixels) do
	for X, Col in pairs(Values) do
		term.setCursorPos(X, Y)
		term.setBackgroundColour(Col)
		term.write(" ")
		--print(tostring(X)..", "..tostring(Y).." ("..tostring(Col)..")")
	end
end

Parser:Save(args[1]..".image")

print("\n")
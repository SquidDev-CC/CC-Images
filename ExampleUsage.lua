local Images = setmetatable({}, {__index = getfenv()})
setfenv(loadfile(fs.combine(fs.getDir(shell.getRunningProgram()), "build/Images.lua")), Images)()

local args = {...}
if #args < 1 then
	error("ExampleUsage.lua <File>")
end

local path = shell.resolve(args[1])

local parser = Images.parseFile(path)
parser:Save(path..".image")

term.clear()
term.setCursorPos(1,1)
Images.drawImage(parser)

print()

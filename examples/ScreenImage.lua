--[[
	Renders an image to the screen
]]

local function resolve(path)
	return fs.combine(fs.getDir(shell.getRunningProgram()), path)
end

local function loadAPI(name)
	local env = setmetatable({}, {__index = getfenv()})

	local result = setfenv(loadfile(resolve("../" .. name .. ".lua")), env)()
	for k,v in pairs(result or {}) do return result end
	return env
end

-- Load the Graphics and CommandGraphics API
local Graphics = loadAPI("build/Graphics")

local parser = Graphics.ImageHelpers.parseFile(resolve("../data/CC.bmp"))

term.clear()
term.setCursorPos(1, 1)
Graphics.ImageHelpers.drawImage(parser)

local w, h = term.getSize()
term.setCursorPos(1, h - 1)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)

print("Press any key to clear")
os.pullEvent("key")

term.setCursorPos(1, 1)
term.clear()

-- Gobble char events
os.queueEvent("ignore") coroutine.yield("ignore")

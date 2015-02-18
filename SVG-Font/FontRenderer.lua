local args = {...}

local function readPrompt(prompt)
	write(prompt .. "> ")
	return read()
end

local message = args[1] or readPrompt("Message")
local size = assert(tonumber(args[1] or readPrompt("Message")), "Invalid number")

local drawing = DrawingAPI()

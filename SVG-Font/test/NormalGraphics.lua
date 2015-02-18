local original = term.current()

term.redirect(term.native())
term.setBackgroundColor(colors.black)
term.clear()

local floor = math.floor
local function pixel(x, y)
	term.setCursorPos(floor(x), floor(y))
	term.write(" ")
end

local drawing = dofile(shell.resolve("DrawingAPI.lua"))(pixel)

-- Wait for click and clear
local function waitReset()
	os.pullEvent("char")

	term.setBackgroundColor(colors.black)
	term.clear()

	term.setCursorPos(1, 1)
end

-- Dynamic mouse callback function
local function onUpdate(callback)
	callback(25, 10)

	while true do
		local name, ignore, x, y = os.pullEvent()
		if name == "char" then
			os.queueEvent("char", ignore)
			return
		elseif name == "mouse_click" or name == "mouse_drag" then
			term.setBackgroundColor(colors.black)
			term.clear()

			callback(x, y)

			term.setBackgroundColor(colors.cyan)
			pixel(x, y)
		end
	end
end

-- Basic lines
do
	term.setBackgroundColor(colors.blue)

	drawing.line(1, 1, 19, 19)
	drawing.line(19, 19, 1, 10)
	drawing.line(1, 1, 1, 10)
end

waitReset()

-- Lines based on cursor position
onUpdate(function(x, y)
	term.setBackgroundColor(colors.yellow)

	drawing.line(1, 1, x, y)
	drawing.line(x, y, 1, 19)
	drawing.line(1, 1, 1, 19)
end)

waitReset()

-- Bezier curves, nice cubic thing
do
	term.setBackgroundColor(colors.green)
	-- M10 80 C 40 10, 65 10, 95 80 C 125 150 150 150, 180 80
	drawing.bezier({
		1, 5,
		1, 1,
		10, 1,
		20, 10,
	})
	drawing.bezier({
		20, 10,
		30, 19,
		40, 19,
		51, 1,
	})
end

waitReset()

-- Dynamic quadratic
onUpdate(function(x, y)
	local x1, y1, x2, y2 = 1, 1, 51, 1

	term.setBackgroundColor(colors.pink)
	drawing.line(x1, y1, x, y)
	drawing.line(x2, y2, x, y)

	term.setBackgroundColor(colors.blue)
	drawing.bezier({x1, y1, x, y, x2, y2})
end)

term.redirect(original)
waitReset()
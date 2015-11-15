local width, height = graphics.size()

local mulpMatrix = matrix.matrix
local pairs, select, unpack = pairs, select, unpack

local handler, update, doProfile = function() return false end, function() end, true

local debug = cclite and cclite.log or print
local clock, format = os.clock, string.format
local function profile(section, time)
	if doProfile then
		debug(format("[%.2f] %s: %.5f", clock(), section, time))
	end
end

local function compose(...)
	local result, items = ..., {select(2, ...)}
	for i = 1, #items do
		result = mulpMatrix(result, items[i])
	end

	return result
end

local function normalise(coord)
	coord[1] = (coord[1] + 1) * width / 2
	coord[2] = (coord[2] + 1) * height / 2
	return coord
end

local function draw(verticies, group, colour)
	local a, b, c = verticies[group[1]], verticies[group[2]], verticies[group[3]]
	-- graphics.triangle(
	-- 	a[1], a[2], a[3],
	-- 	b[1], b[2], b[3],
	-- 	c[1], c[2], c[3], colour
	-- )

	graphics.line(a[1], a[2], a[3], b[1], b[2], b[3], colour)
	graphics.line(c[1], c[2], c[3], b[1], b[2], b[3], colour)
	graphics.line(a[1], a[2], a[3], c[1], c[2], c[3], colour)
end

local function run(fps)
	update()

	if term then
		local buffer = term.native()
		local changed = true
		local delta = 1 / fps
		graphics.silica(buffer)

		local id = os.startTimer(delta)
		while true do
			local event = {os.pullEvent()}
			if e == "timer" and arg == id then
				id = os.startTimer(delta)

				if changed then
					local vStart = clock()
					update()
					changed = false

					local start = clock()
					graphics.silica(buffer)

					profile("Blitting", clock() - start)
					profile("Total", clock() - vStart)
					profile("FPS", (1 / (clock() - vStart)))
				end
			elseif handler(unpack(event)) then
				changed = true
			end
		end
	elseif love then
		local changed = true
		love.keyboard.setKeyRepeat(true)
		function love.keypressed(key)
			if handler("char", key) then
				changed = true
			end
		end

		function love.draw()
			if changed then
				update()
				changed = false
			end
			graphics.love(love)
		end
	else
		error("Requires running in Silica or Love")
	end
end

local function setup(newHandler, refresh, profile)
	handler, update = newHandler, refresh
	if profile ~= nil then
		doProfile = profile
	end
end

return {
	-- Graphics helpers
	compose = compose,
	normalise = normalise,
	draw = draw,

	-- Running
	run = run,
	profile = profile,
	debug = debug,
	setup = setup,
}

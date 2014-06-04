local run = true

function traceback()
	local ok, err, name
	local i = 2

	while true do
		ok, err = pcall(_G.error, '', i)
		name = err:match("^[^:]+")
		if name ~= "bios" then break end
		i = i + 1
	end

	while true do
		ok, err = pcall(_G.error, '', i)
		local name = err:match("^[^:]+")

		if name == "" or name == nil or name == false then break end
		
		--printError("\t"..err)

		local ls = err:find(":")
		if ls then ls = ls + 1 end
		local le = err:find(":", ls)
		if le then le = le - 1 end
		local line = ls and le and err:sub(ls, le)
		local location = ls and err:sub(1, ls - 2) or err
		printError("\t@ line " .. (le and line or "?") .. " in " .. location)
		if (name == "bios" or name == "xpcall" or name == "pcall" or name == "shell") or not err then break end

		i = i + 1
	end
end

function errorHandler(File, Error)
	run = false
	printError("Errored in "..File)
	os.pullEvent("char")

	term.redirect(term.native())
	term.clear()
	term.setCursorPos(1,1)
	printError("Error in "..File)
	printError(Error)
	traceback()

	os.pullEvent("char")	
end

local function RunLocal(File, ...)
	local args = {...}
	local loadedFile, err = loadfile(File)
	if loadedFile then
		local env = {}
		setmetatable( env, { __index = getfenv() } )

		setfenv(loadedFile, env)

		--[[local ok, err = pcall( function()
			loadedFile( unpack( args ) )
		end )
		if not ok then
			if err and err ~= "" and err~=nil then
				os.pullEvent("char")

				term.clear()
				term.setCursorPos(1,1)
				printError("Error in "..File)
				printError(err)
				traceback()
				--print(debug.traceback())
			end
			return false
		end
		--]]
		xpcall(function() loadedFile(unpack(args)) end, function(Error) errorHandler(File, Error) end)
		return true
	end
	if err and err ~= "" then
		printError(err)
	end
	return false
end

--local env = {}
--setmetatable( env, { __index = getfenv() } )

--os.run(env, "Combiner.lua", "Top.lua", "Compile.lua")
RunLocal("Combiner.lua", "Top.lua", "Compile.lua")

--env = {}
--setmetatable( env, { __index = getfenv() } )

--os.run(env, "Compile.lua")
if run then
	RunLocal("Compile.lua")
end

if not run then
	term.clear()
	term.setCursorPos(1,1)
end
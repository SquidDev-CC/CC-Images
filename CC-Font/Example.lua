os.unloadAPI("FontAPI")
if not FontAPI then
	os.loadAPI(fs.combine(fs.getDir(shell.getRunningProgram()), "FontAPI"))
end

term.clear()
local Obj = FontAPI.CreateObject(FontAPI.LoadFont("ComicSans.ftf"))
local Old = term.current()

term.redirect(Obj)

print("We all love Comic Sans")

term.redirect(Old)
term.setCursorPos(1,1)
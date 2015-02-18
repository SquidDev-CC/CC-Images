Options:Default "trace"

Sources:File "SVGParser.lua"
	:Name "SVGParser"

Sources:File "CommandGraphics.lua"
	:Name "CommandGraphics"

Sources:File "DrawingAPI.lua"
	:Name "DrawingAPI"

Sources:File "ComicSans.lua"
	:Name "ComicSans"

Sources:Main "FontRenderer.lua"
	:Depends "CommandGraphics"
	:Depends "DrawingAPI"

	:Depends "ComicSans"
	:Depends "SVGParser"

Sources
	:Export()

Tasks:Clean("clean", "build")
Tasks:Combine("combine", Sources, "build/Font.lua", {"clean"})
	:Verify()

Tasks:Minify("minify", "build/Font.lua", "build/Font.min.lua")
	:Description("Produces a minified version of the code")

Tasks:CreateBootstrap("boot", Sources, "build/Boot.lua", {"clean"})
	:Traceback()

Tasks:Task "build"{"minify", "boot"}
	:Description "Minify and bootstrap"

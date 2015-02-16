Options:Default "trace"

Sources:File "BinaryFile.lua"
	:Name "BinaryFile"
	:Depends "Class"

Sources:File "BitmapParser.lua"
	:Name "BitmapParser"
	:Depends "Class"
	:Depends "BitmapDepths"

Sources:File "BitmapPixels.lua"
	:Name "BitmapPixels"
	:Depends "Class"

Sources:File "BitmapDepths.lua"
	:Name "BitmapDepths"
	:Depends "BitmapPixels"
	:Depends "Colours"

Sources:File "Class.lua"
	:Name "Class"
Sources:File "Colours.lua"
	:Name "Colours"

Sources:Main "ImagesAPI.lua"
	:Depends "BinaryFile"
	:Depends "BitmapParser"

Sources
	:Export()

Tasks:Clean("clean", "build")
Tasks:Combine("combine", Sources, "build/Images.lua", {"clean"})
	:Verify()

Tasks:Minify("minify", "build/Images.lua", "build/Images.min.lua")
	:Description("Produces a minified version of the code")

Tasks:CreateBootstrap("boot", Sources, "build/Boot.lua", {"clean"})
	:Traceback()

Tasks:Task "build"{"minify", "boot"}
	:Description "Minify and bootstrap"

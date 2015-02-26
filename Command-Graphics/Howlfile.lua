Options:Default "trace"

Sources:File "CommandColors.lua"       :Name "CommandColors"
Sources:File "CommandGraphics.lua"     :Name "CommandGraphics"
Sources:File "TransformationChain.lua" :Name "TransformationChain"

Sources:Export()

Tasks:Clean("clean", "build")
Tasks:Combine("combine", Sources, "build/CommandGraphics.lua", {"clean"})
	:Verify()

Tasks:Minify("minify", "build/CommandGraphics.lua", "build/CommandGraphics.min.lua")
	:Description("Produces a minified version of the code")

Tasks:Default "minify"

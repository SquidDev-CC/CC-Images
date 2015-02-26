Options:Default "trace"

do -- Global files
	Sources:File "Utils/Class.lua"
		:Name "Class"
		:Export(false)
	Sources:File "Utils/Colors.lua"
		:Name "Colors"
	Sources:File "Utils/DrawingAPI.lua"
		:Name "DrawingAPI"
end

do -- Image-Bitmap
	Sources:File "Image-Bitmap/BinaryFile.lua"
		:Name "BinaryFile"
		:Depends "Class"

	Sources:File "Image-Bitmap/BitmapParser.lua"
		:Name "BitmapParser"
		:Depends "Class"
		:Depends "BitmapDepths"

	Sources:File "Image-Bitmap/BitmapPixels.lua"
		:Name "BitmapPixels"
		:Depends "Class"
		:Depends "Colors"

	Sources:File "Image-Bitmap/BitmapDepths.lua"
		:Name "BitmapDepths"
		:Depends "BitmapPixels"

	Sources:File "Image-Bitmap/ImageHelpers.lua"
		:Name "ImageHelpers"
		:Depends "BinaryFile"
		:Depends "BitmapParser"
		:Depends "Colors"
end

do -- Font-SVG
	Sources:File "Font-SVG/SVGParser.lua"
		:Name "SVGParser"
	Sources:File "Font-SVG/FontHelpers.lua"
		:Name "FontHelpers"
		:Depends "SVGParser"
end

Sources:Export()

Tasks:Clean("clean", "build")
Tasks:Combine("combine", Sources, "build/Graphics.lua", {"clean"})
	:Verify()

Tasks:Minify("minify", "build/Graphics.lua", "build/Graphics.min.lua")

Tasks:Default "minify"

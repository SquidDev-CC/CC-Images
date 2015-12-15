Options:Default "trace"

do -- Generation files
	local matrix = Dependencies()
	matrix:File "generation/matrix.lua"
		:Name "generation"
	matrix:Main "tools/matrix.lua"
		:Depends "generation"

	Tasks:Combine("matrix", matrix, "build/matrix.lua")
		:Description "Matrix codegen"
end

do -- Matrix
	local insert, concat = table.insert, table.concat

	Tasks:AddTask("matrix4x4", {}, function()
		local builder = {}
		local matrix = dofile(File "generation/matrix.lua")

		insert(builder, "return {\n")

		insert(builder, "matrix = ")
		insert(builder, matrix.createMultiply(4, 4, 4, 4))
		insert(builder, ",\n")

		insert(builder, "vector = ")
		insert(builder, matrix.createMultiply(4, 4, 4, 1))
		insert(builder, ",\n")

		insert(builder, "}")

		assert(loadstring(concat(builder)))
		local handle = fs.open(File "build/matrix4x4.lua", "w")
		handle.write(concat(builder))
		handle.close()
	end)
		:Description("4x4 and 4x1 matrix multiplication")
		:Produces("build/matrix4x4.lua")
end

do -- Graphics gen
	local graphics = Dependencies()

	graphics:File "generation/buffer.lua" :Name "buffer"
	graphics:File "generation/ccBuffer.lua" :Name "ccBuffer"
	graphics:File "generation/clip.lua" :Name "clip" :Depends { "utils", "clip_lib", "triangle_lib" }
	graphics:File "generation/graphics.lua" :Name "graphics" :Depends { "utils" }
	graphics:File "generation/project.lua" :Name "project" :Depends { "utils" }

	graphics:File "generation/utils.lua" :Name "utils" :Export(false)
	graphics:Resource "generation/lib/clip.lua" :Name "clip_lib" :Export(false)
	graphics:Resource "generation/lib/triangle.lua" :Name "triangle_lib" :Export(false)

	Tasks:Combine("graphics", graphics, "build/generator.lua")
		:Description "Graphics generation"
end

do -- Main Script
	local main = Dependencies()
	main:File "../Utils/Colors.lua" :Name "colors"
	main:File "build/graphics.lua"  :Name "graphics" :Depends { "colors", "matrix" }
	main:File "build/matrix4x4.lua" :Name "matrix"
	main:File "tools/transform.lua" :Name "transform"
	main:File "tools/runner.lua"    :Name "runner"   :Depends { "graphics", "matrix" }
	main:Main "main.lua" :Depends {"graphics", "matrix", "transform", "runner"}

	Tasks:Combine("main", main, "build/main.lua")
		:Description "Example program"

	local insert, concat = table.insert, table.concat
	Tasks:AddTask(".mainGraphics", {}, function()
		local builder = {}
		local graphics = dofile(File "build/generator.lua")

		insert(builder, "local width, height if term then width, height = term.getSize() else width, height = 400, 300 end\n")
		insert(builder, "local buffer = (function(...)\n")
		insert(builder, graphics.buffer(true, false))
		insert(builder, "\nend)(width, height)\n")

		insert(builder, "buffer.line = (function(...)\n")
		insert(builder, graphics.graphics.line(nil, {{-1, 1}}, 1))
		insert(builder, "\nend)(buffer.pixel, width, height)\n")

		insert(builder, "buffer.lineBlended = (function(...)\n")
		insert(builder, graphics.graphics.line(nil, {{-1, 1}, 4}))
		insert(builder, "\nend)(buffer.pixel, width, height)\n")

		insert(builder, "buffer.triangle = (function(...)\n")
		insert(builder, graphics.graphics.triangle(nil, {{-1, 1}}, 1))
		insert(builder, "\nend)(buffer.pixel, width, height)\n")

		insert(builder, "buffer.triangleBlended = (function(...)\n")
		insert(builder, graphics.graphics.triangle(nil, {{-1, 1}, 4}))
		insert(builder, "\nend)(buffer.pixel, width, height)\n")

		insert(builder, "local projectLine = (function(...)\n")
		insert(builder, graphics.project.line(nil, 1))
		insert(builder, "\nend)(buffer.line, width, height)\n")

		insert(builder, "buffer.clippedLine = (function(...)\n")
		insert(builder, graphics.clip.line(0, 1))
		insert(builder, "return lineComplete\nend)(projectLine, matrix.vector)\n")

		insert(builder, [[
			local l = buffer.line
			local function pTri(x1, y1, z1, x2, y2, z2, x3, y3, z3, colour)
				l(x1, y1, z1, x2, y2, z3, colour)
				l(x1, y1, z1, x3, y3, z3, colour)
				l(x2, y2, z2, x3, y3, z3, colour)
			end
		]])
		insert(builder, "local projectTriangle = (function(...)\n")
		insert(builder, graphics.project.triangle(nil, 1))
		insert(builder, "\nend)(pTri, width, height)\n")
		insert(builder, "buffer.clippedTriangle = (function(...)\n")
		insert(builder, graphics.clip.triangle(0, 1))
		insert(builder, "return triangleComplete\nend)(projectTriangle, matrix.vector)\n")

		insert(builder, "return buffer\n")

		local handle = fs.open(File "build/graphics.lua", "w")
		handle.write(concat(builder))
		handle.close()
	end)
		:Requires "build/generator.lua"
		:Produces("build/graphics.lua")
		:Description("Basic graphics package")
end

do -- Cubic
	local cubic = Dependencies()
	cubic:File "../Utils/Colors.lua" :Name "colors"
	cubic:File "build/cubic/graphics.lua"  :Name "graphics" :Depends "colors"
	cubic:File "build/matrix4x4.lua" :Name "matrix"
	cubic:File "tools/transform.lua" :Name "transform"
	cubic:File "tools/runner.lua"    :Name "runner"   :Depends { "graphics", "matrix" }

	cubic:File "cubic/chunk.lua"     :Name "chunk" :Depends { "cube", "matrix", "runner", "transform"}
	cubic:File "cubic/cube.lua"      :Name "cube"
	cubic:File "cubic/generation.lua":Name "generation"

	cubic:Main "cubic/main.lua"
		:Depends {"graphics", "matrix", "transform", "runner"}
		:Depends {"chunk", "generation"}

	Tasks:Combine("cubic", cubic, "build/cubic/main.lua")
		:Description "Cubic"

	local insert, concat = table.insert, table.concat
	Tasks:AddTask(".cubicGraphics", {}, function()
		local builder = {}
		local buffer = dofile(File "generation/ccBuffer.lua")
		local graphics = dofile(File "generation/graphics.lua")

		insert(builder, "local width, height if term then width, height = term.getSize() else width, height = 400, 300 end\n")
		insert(builder, "local buffer = (function(...)\n")
		insert(builder, buffer(true, false))
		insert(builder, "\nend)(width, height)\n")

		local h = fs.open(File "cubic/texture.lua", "r")
		local texture = h.readAll()
		h.close()
		insert(builder, texture)
		insert(builder, "\n")

		insert(builder, "buffer.line = (function(...)\n")
		insert(builder, graphics.line(nil, {{-1, 1}, 1, 1}, {1}))
		insert(builder, "\nend)(shader, width, height)\n")
		insert(builder, "buffer.triangle = (function(...)\n")
		insert(builder, graphics.triangle(nil, {{-1, 1}, 1, 1}, {1}))
		insert(builder, "\nend)(shader, width, height)\n")
		insert(builder, "return buffer\n")

		local handle = fs.open(File "build/cubic/graphics.lua", "w")
		handle.write(concat(builder))
		handle.close()
	end)
		:Produces("build/cubic/graphics.lua")
		:Description("Cubic graphics package")
end

Tasks:Clean("clean", "build")

Tasks:MinifyAll()

Tasks:AddTask("build", {"clean"})
	:Requires {"build/main.min.lua", "build/cubic/main.min.lua"}

Tasks:Default "build"

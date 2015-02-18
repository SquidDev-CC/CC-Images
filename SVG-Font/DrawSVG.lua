local ipairs, unpack = ipairs, unpack

--- Draw a SVG list
local function drawSVG(drawing, nodes)
	local line, bezier = drawing.line, drawing.bezier
	for _, node in ipairs(nodes) do
		local nodeType = nodes[1]
		local nodeArgs = nodes[2]

		if nodeType == "L" then
			line(unpack(nodeArgs))
		else
			bezier(nodeArgs)
		end
	end
end

-- Wrap a pixel to flip the y axis
local function wrapPixel(pixel)
	return function(x, y) pixel(x, -y) end
end


return {
	draw = drawSVG,
	wrap = wrapPixel
}

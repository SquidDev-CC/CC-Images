--[[
	Handles matrix transformations

	Several references:
		- https://open.gl/transformations
		- http://www.songho.ca/opengl/gl_transform.html
		- https://github.com/g-truc/glm/blob/master/glm/gtc/matrix_transform.inl
		- http://www.codinglabs.net/article_world_view_projection_matrix.aspx
]]
local matrix = require('matrix')
local identity = matrix.createIdentity(4)
local sin, cos, tan = math.sin, math.cos, math.tan

local function translate(x, y, z)
	return {
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		x, y, z, 1,
	}
end

local function scale(x, y, z)
	return {
		x, 0, 0, 0,
		0, y, 0, 0,
		0, 0, z, 0,
		0, 0, 0, 1,
	}
end

local function rotateX(a)
	local c, s = cos(a), sin(a)
	return {
		1,  0, 0, 0,
		0,  c, s, 0,
		0, -s, c, 0,
		0,  0, 0, 1
	}
end

local function rotateY(a)
	local c, s = cos(a), sin(a)
	return {
		 c, 0, s, 0,
		 0, 1, 0, 0,
		-s, 0, c, 0,
		 0, 0, 0, 1
	}
end

local function rotateZ(a)
	local c, s = cos(a), sin(a)
	return {
		c, -s, 0, 0,
		s,  c, 0, 0,
		0,  0, 1, 0,
		0,  0, 0, 1,
	}
end

local function orthographic(left, right, bottom, top, zNear, zFar)
	local i = identity()
	local invRL, invTB, invFN = 1 / (right - left), 1 / (top - bottom), 1 / (zNear - zFar)

	-- Scaling
	i[1] = 2 * invRL
	i[6] = 2 * invTB
	i[11] = -2 * invFN

	-- Translate everything
	i[13] = -(right + left) * invRL
	i[14] = -(top + bottom) * invTB
	i[15] = -(zFar + zNear) * invFN

	return i
end

local function perspective(fovy, aspect, zNear, zFar)
	local i = identity()
	local tanHalfFovy = tan(fovy / 2)

	-- Diagonals
	i[1] = 1 / (aspect * tanHalfFovy)
	i[6] = 1 / tanHalfFovy
	i[11] = -(zFar + zNear) / (zFar - zNear)

	i[12] = -1
	i[15] = -(2 * zNear * zFar) / (zFar - zNear)
	i[16] = 0
	return i
end

return {
	translate = translate,
	scale = scale,
	rotateX = rotateX,
	rotateY = rotateY,
	rotateZ = rotateZ,

	orthographic = orthographic,
	perspective = perspective,
}
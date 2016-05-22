--[[
	Handles matrix transformations

	Several references:
		- https://open.gl/transformations
		- http://www.songho.ca/opengl/gl_transform.html
		- https://github.com/g-truc/glm/blob/master/glm/gtc/matrix_transform.inl
		- http://www.codinglabs.net/article_world_view_projection_matrix.aspx
		- http://blogs.msdn.com/b/davrous/archive/2013/06/13/tutorial-series-learning-how-to-write-a-3d-soft-engine-from-scratch-in-c-typescript-or-javascript.aspx
		- https://github.com/Steve132/uraster/blob/master/uraster.hpp
]]
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
	local invRL, invTB, invFN = 1 / (right - left), 1 / (top - bottom), 1 / (zNear - zFar)

	return {
		2 * invRL, 0,         0,          0,
		0,         2 * invTB, 0,          0,
		0,         0,         -2 * invFN, 0,

		-- Translate
		(-right + left) * invRL, -(top + bottom) * invTB, -(zFar + zNear) * invFN, 1,
	}
end

local function perspective(fovy, aspect, zNear, zFar)
	local tanHalfFovy = tan(fovy / 2)

	-- Diagonals
	return {
		1 / (aspect * tanHalfFovy), 0, 0, 0,
		0, 1 / tanHalfFovy, 0, 0,
		0, 0, -(zFar + zNear) / (zFar - zNear), -1,
		0, 0, -(2 * zNear * zFar) / (zFar - zNear), 0,
	}
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

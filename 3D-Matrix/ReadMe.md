# 3D Matrix

A 3D engine powered by matricies. Currently supports Love2D and the Silica Emulator.

## Features
 - Efficient matrix implementation
 - Code generation for lines and triangles allowing powerful custom shaders
 - Code generation for buffers, supporting depth testing and alpha blending

## Roadmap
 - Fix near z plane clipping
 - Add support for stencil buffer, and custom buffer read/write modes (read only, write only, read&write, ignore)
 - Back face culling

## References
I may not have used all of these, just useful links for other people.
- https://open.gl/transformations
- http://www.songho.ca/opengl/gl_transform.html
- https://github.com/g-truc/glm/blob/master/glm/gtc/matrix_transform.inl
- http://www.codinglabs.net/article_world_view_projection_matrix.aspx
- http://blogs.msdn.com/b/davrous/archive/2013/06/13/tutorial-series-learning-how-to-write-a-3d-soft-engine-from-scratch-in-c-typescript-or-javascript.aspx
- https://github.com/Steve132/uraster/blob/master/uraster.hpp
- http://bellard.org/TinyGL/

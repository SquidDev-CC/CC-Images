# Image-Bitmap
Parses of `.bmp` files. It is composed of several files:

 - `BinaryFile.lua`: Handles reading values from a binary file
 - `BitmapDepths.lua`: Handles the parsing of 1, 4, 8 and 24 bit bitmaps.
 - `BitmapParser.lua`: Reads the main header of a bitmap
 - `BitmapPixels.lua`: Parent class for those in `BitmapDepths.lua`. Simpifies reading of pixels.
 - `ImageHelpers.lua`: Helper functions for reading images.

See the main project ReadMe for more information

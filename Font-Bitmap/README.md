Font API
========

This API provides fonts for Computer Craft.

Example
-------
You first need to create a font file. This should be a Bitmap (.bmp). I like to use [this](http://xbox.create.msdn.com/en-US/education/catalog/utility/bitmap_font_maker) but it doens't matter how it looks like as long as the individual glyphs are on a black background.

The bitmap should be in 16 colour format (bit depth of 4). You can then run `BitmapToFont.lua MyFont.bmp MyFont.ftf`.

This can then be used:

```lua
term.clear()
local Obj = FontAPI.CreateObject(FontAPI.LoadFont("ComicSans.ftf"))
local Old = term.current()

term.redirect(Obj)

print("We all love Comic Sans")
```

The 'Fake Type Font' Format
---------------------------
The `.ftf` extension follows the following format:


### Header:

* **Byte 1:** Version of the FTF format. _Currently 1_
* **Byte 2:** Width of each glyph
* **Byte 3:** Height of each glyph

### Each character:

* **Byte 1:** ASCII code for character represented

Each bit afterwards stores if that pixel is 'on' (1) or 'off' (0). The pixels go in rows and columns, with the remaining bits of the byte being padded with 0s.
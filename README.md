# ljgraph2d
2D graphics written in pure LuaJIT

This project presents a 2D graphics package written in pure 
LuaJIT.  There are no external dependencies.

The design goal of the 2D Renderer is to have enough features to render graphics
as complex as what is found in the SVG file format.  Bezier curves, transparency,
thick lines, paint, and the like.

As such, there are path and shape objects as primitives, which a parser can leverage
to support SVG graphic objects.  The lowest level handling of drawing is represented
by the Surface object.  In its basic form, the Surface represents a memory back frame
buffer.  It will handle simple tasks such as setting pixels, drawing horizontal lines
and the like.  

At a higher level, there is the Raster2D object.  For regular drawing, this object
deals with drawing state, line clipping, current location and the like. 

The separation of these concerns makes it possible to easily compose modules.
The routines that support SVG shapes, are the same to support True Type Fonts, since
those turn into simple bezier curves, lines and polygons.  Similarly, just about
any graphics API can be supported with an API specific skin, while maintaining 
a small core.

This is obviously a work in progress.  It's not consumable as yet, but there are a 
few test cases along the way.
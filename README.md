# ljgraph2d
2D graphics written in pure LuaJIT

This project presents a 2D graphics package written in pure 
LuaJIT.  There are no external dependencies.

The basic structure is

Surface - Lowest level representation of something to be drawn on.

DrawingContext - Represents the retained state of the Raster2D environment.  This is held as a separate object as it might be
desirable to build a state stack, and thus you want to be able to
easily encapsulate state in a simple object.

Raster2D - An instance of this class represents the public API for drawing.

There are various support objects for dealing with various file formats
such as .bmp and .svg.  This is not a general purpose image viewer,
but these formats are very useful to play with.



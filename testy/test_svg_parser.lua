--test_svg_parser.lua

package.path = "../?.lua;"..package.path

local SVGParser = require("ljgraph2D.SVGParser")

--local parser = SVGParser();
local filename = arg[1] or "08_01.svg"
local image = SVGParser:parseFromFile(filename, "dpi", 96);

print("Image: ", image)
print("  shapes: ", image.shapes, #image.shapes)
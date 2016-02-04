--test_svg_parser.lua

package.path = "../?.lua;"..package.path

local SVGParser = require("ljgraph2D.SVGParser")
local Raster2D = require("ljgraph2D.Raster2D")
local colors = require("ljgraph2D.colors")
local utils = require("utils")

--local parser = SVGParser();
local filename = arg[1] or "images/08_01.svg"
local image = SVGParser:parseFromFile(filename, "px", 96);
print("Image: ", image)


--
local width = 1024;
local height = 768;

local graphPort = Raster2D(width,height);
utils.drawCheckerboard (graphPort.surface, 8, colors.svg.darkgray, colors.svg.lightgray)

graphPort:drawImage(image, 0,0,1.0)

utils.save(graphPort.surface, "test_svg_parser.bmp");


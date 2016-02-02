--test_svg_parser.lua

package.path = "../?.lua;"..package.path

local SVGParser = require("ljgraph2D.SVGParser")
local Raster2D = require("ljgraph2D.Raster2D")
local colors = require("ljgraph2D.colors")
local utils = require("utils")

--local parser = SVGParser();
local filename = arg[1] or "images/08_01.svg"
local image = SVGParser:parseFromFile(filename, "dpi", 96);
print("Image: ", image)


--
local width = 1024;
local graphPort = Raster2D(1024,768);
utils.drawCheckerboard (graphPort.surface, 8, colors.svg.lightgray, colors.svg.white)

--print("  shapes: ", image.shapes, #image.shapes)

for _, shape in ipairs(image.shapes) do
	--print("SHAPE")
	--for k,v in pairs(shape) do
	--	print('  ',k,v)
	--end

	for pidx, path in ipairs(shape.paths) do
		path:draw(graphPort);
--[[		
		print("  PATHS - ", pidx, path.closed)
		for _,pt in ipairs(path.pts) do
			print("    PT: ", pt.x, pt.y)
		end
--]]
	end
end

utils.save(graphPort.surface, "test_svg_parser.bmp");


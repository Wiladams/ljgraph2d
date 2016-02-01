--test_svg_parser.lua

package.path = "../?.lua;"..package.path

local SVGParser = require("ljgraph2D.SVGParser")

--local parser = SVGParser();
local filename = arg[1] or "08_01.svg"
local image = SVGParser:parseFromFile(filename, "dpi", 96);

print("Image: ", image)
--print("  shapes: ", image.shapes, #image.shapes)

for _, shape in ipairs(image.shapes) do
	print("SHAPE")
	for k,v in pairs(shape) do
		print('  ',k,v)
	end

	--for pidx, path in ipairs(shape.paths) do
	--	print("  PATHS - ", pidx, path.closed)
	--	for _,pt in ipairs(path.pts) do
	--		print("    PT: ", pt.x, pt.y)
	--	end
	--end
end

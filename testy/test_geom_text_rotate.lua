--test_svggeometry.lua
-- SETUP --
package.path = "../?.lua;"..package.path

local FileStream = require("filestream")
local SVGStream = require("ljgraph2D.SVGStream")

local SVGGeometry = require("ljgraph2D.SVGGeometry")
local svg = SVGGeometry.Document;
local polygon = SVGGeometry.Polygon;
local rect = SVGGeometry.Rect;
local circle = SVGGeometry.Circle;
local text = SVGGeometry.Text;


-- TEST --
local function test_geom(filename)
	local doc = svg({
		version="1.1", 
		width = "100px", height= "50px", 
		
  		text({x="10",  y="20", transform="rotate(30 20,40)"},
  			"SVG Text Rotation example");
	})

	-- create a file stream to write out the image
	local fs = FileStream.open(filename)
	--local fs = FileStream.new(io.stdout);
	local strm = SVGStream(fs);

	doc:write(strm);
end


test_geom("test_geom_text_rotate.svg");

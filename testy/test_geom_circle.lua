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


--[[
<?xml version="1.0" standalone="no"?>
<svg width="12cm" height="4cm" viewBox="0 0 1200 400"
     xmlns="http://www.w3.org/2000/svg" version="1.1">
  <desc>Example circle01 - circle filled with red and stroked with blue</desc>

  <!-- Show outline of canvas using 'rect' element -->
  <rect x="1" y="1" width="1198" height="398"
        fill="none" stroke="blue" stroke-width="2"/>

  <circle cx="600" cy="200" r="100"
        fill="red" stroke="blue" stroke-width="10"  />
</svg>
--]]

-- TEST --
local function test_geom(filename)
	local doc = svg({
		version="1.1", 
		width = "12cm", height= "4cm", 
		viewBox="0 0 1200 400",
		Shapes = {
			-- Show outline of canvas using 'rect' element
			rect({x = 1;y = 1;width = 1198; height = 398;
				fill = "none";
				stroke = "blue";
				["stroke-width"] = 2;
			});

			circle({
  				fill="red", 
  				stroke="blue", 
  				["stroke-width"]=10, 
        		cx =600;
        		cy = 200;
        		r = 100;
        		});
		}
	})

	-- create a file stream to write out the image
	local fs = FileStream.open(filename)
	--local fs = FileStream.new(io.stdout);
	local strm = SVGStream(fs);

	doc:write(strm);
end


test_geom("test_geom_circle.svg");

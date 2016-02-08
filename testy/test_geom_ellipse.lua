--test_geom_ellipse.lua
-- https://www.w3.org/TR/SVG2/shapes.html

-- SETUP --
package.path = "../?.lua;"..package.path

local FileStream = require("filestream")
local SVGStream = require("ljgraph2D.SVGStream")

local SVGGeometry = require("ljgraph2D.SVGGeometry")
local svg = SVGGeometry.Document;
local rect = SVGGeometry.Rect;
local ellipse = SVGGeometry.Ellipse;
local group = SVGGeometry.Group;


--[[
<?xml version="1.0" standalone="no"?>
<svg width="12cm" height="4cm" viewBox="0 0 1200 400"
     xmlns="http://www.w3.org/2000/svg" version="1.1">
  <desc>Example ellipse01 - examples of ellipses</desc>

  <!-- Show outline of canvas using 'rect' element -->
  <rect x="1" y="1" width="1198" height="398"
        fill="none" stroke="blue" stroke-width="2" />

  <g transform="translate(300 200)">
    <ellipse rx="250" ry="100"
          fill="red"  />
  </g>

  <ellipse transform="translate(900 200) rotate(-30)" 
        rx="250" ry="100"
        fill="none" stroke="blue" stroke-width="20"  />

</svg>
--]]

-- TEST --
local function test_geom(filename)
	local doc = svg({
		version="1.1", 
		width = "12cm", height= "4cm", 
		viewBox="0 0 1200 400",
		
		-- Show outline of canvas using 'rect' element
		rect({x = 1;y = 1;width = 1198; height = 398;
				fill = "none";
				stroke = "blue";
				["stroke-width"] = 2;
		});

		group({
				transform = "translate(300 200)";

				ellipse({fill="red"; rx=250, ry=100});
		});

		ellipse({
				fill = "none";
				stroke = "blue";
				["stroke-width"] = 20;
				transform="translate(900 200) rotate(-30)";
				rx = 250;
				ry = 100;
		});
	})

	-- create a file stream to write out the image
	local fs = FileStream.open(filename)
	--local fs = FileStream.new(io.stdout);
	local strm = SVGStream(fs);

	doc:write(strm);
end


test_geom("test_geom_ellipse.svg");

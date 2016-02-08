--test_svggeometry.lua
-- SETUP --
package.path = "../?.lua;"..package.path

local FileStream = require("filestream")
local SVGStream = require("ljgraph2D.SVGStream")

local SVGGeometry = require("ljgraph2D.SVGGeometry")
local Document = SVGGeometry.Document;
local Line = SVGGeometry.Line;
local Rect = SVGGeometry.Rect;
local Style = SVGGeometry.Style;


-- TEST --
local function test_geom_line()
	local doc = Document({width = "12cm", height= "4cm", viewBox="0 0 1200 400"})

	local r1 = Rect({
		x = 1;
		y = 1;
		width = 1198;
		height = 398;
		fill = "none";
		stroke = "blue";
		["stroke-width"] = 2;

		--style = Style({
		--	["fill"] = "rgb(0,0,255)";
		--	["stroke-width"] = "3";
		--	["stroke"] = "rgb(0,0,0)";
		--});
	});

   local l1 = Line({x1=100, y1=300, x2=300, y2=100, stroke = "green", ["stroke-width"]=5});
   local l2 = Line({x1=300, y1=300, x2=500, y2=100, stroke = "green", ["stroke-width"]=20});
   local l3 = Line({x1=500, y1=300, x2=700, y2=100, stroke = "green", ["stroke-width"]=25});
   local l4 = Line({x1=700, y1=300, x2=900, y2=100, stroke = "green", ["stroke-width"]=20});
   local l5 = Line({x1=900, y1=300, x2=1100, y2=100, stroke = "green", ["stroke-width"]=25});


	doc:addShape(r1);
	doc:addShape(l1);
	doc:addShape(l2);
	doc:addShape(l3);
	doc:addShape(l4);
	doc:addShape(l5);

	-- create a file stream to write out the image
	local fs = FileStream.open("test_geom_line.svg")
	--local fs = FileStream.new(io.stdout);
	local strm = SVGStream(fs);


	doc:write(strm);
end


test_geom_line();


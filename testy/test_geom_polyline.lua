--test_svggeometry.lua
-- SETUP --
package.path = "../?.lua;"..package.path

local FileStream = require("filestream")
local SVGStream = require("ljgraph2D.SVGStream")

local SVGGeometry = require("ljgraph2D.SVGGeometry")
local Document = SVGGeometry.Document;
local Line = SVGGeometry.Line;
local PolyLine = SVGGeometry.PolyLine;
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
	});


  	local pline = PolyLine({
  		fill="none", 
  		stroke="blue", 
  		["stroke-width"]="10", 
        points = {
        	{50,375},
            {150,375}, {150,325}, {250,325}, {250,375},
            {350,375}, {350,250}, {450,250}, {450,375},
            {550,375}, {550,175}, {650,175}, {650,375},
            {750,375}, {750,100}, {850,100}, {850,375},
            {950,375}, {950,25}, {1050,25}, {1050,375},
            {1150,375}}
            });

	doc:addShape(r1);
	doc:addShape(pline);


	-- create a file stream to write out the image
	local fs = FileStream.open("test_geom_polyline.svg")
	--local fs = FileStream.new(io.stdout);
	local strm = SVGStream(fs);


	doc:write(strm);
end


test_geom_line();


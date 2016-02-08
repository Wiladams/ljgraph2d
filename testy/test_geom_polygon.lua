--test_svggeometry.lua
-- SETUP --
package.path = "../?.lua;"..package.path

local FileStream = require("filestream")
local SVGStream = require("ljgraph2D.SVGStream")

local SVGGeometry = require("ljgraph2D.SVGGeometry")
local svg = SVGGeometry.Document;
local polygon = SVGGeometry.Polygon;
local rect = SVGGeometry.Rect;


-- TEST --
local function test_geom()
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

			polygon({
  				fill="red", 
  				stroke="blue", 
  				["stroke-width"]=10, 
        		points = {
        			{350,75},  {379,161}, {469,161}, {397,215},
	        		{423,301}, {350,250}, {277,301}, {303,215},
	        		{231,161}, {321,161}} 
        		});

			polygon({
  				fill="lime", 
  				stroke="blue", 
  				["stroke-width"]=10, 
        		points = {
        			{850,75},  {958,137.5}, {958,262.5}, {850,325}, 
        			{742,262.6}, {742,137.5}} 
        		});
		}
	})

	-- create a file stream to write out the image
	local fs = FileStream.open("test_geom_polygon.svg")
	--local fs = FileStream.new(io.stdout);
	local strm = SVGStream(fs);

	doc:write(strm);
end


test_geom();
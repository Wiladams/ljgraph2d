--test_svggeometry.lua
-- SETUP --
package.path = "../?.lua;"..package.path

local FileStream = require("filestream")
local SVGStream = require("ljgraph2D.SVGStream")

local SVGGeometry = require("ljgraph2D.SVGGeometry")
local Document = SVGGeometry.Document;
local Rect = SVGGeometry.Rect;
local Style = SVGGeometry.Style;


-- TEST --
local function test_Document()
	local doc = Document({width = 400, height= 110})

	local r1 = Rect({
		x = 0;
		y = 0;
		width = 300;
		height = 100;
		style = Style({
			["fill"] = "rgb(0,0,255)";
			["stroke-width"] = "3";
			["stroke"] = "rgb(0,0,0)";
		});
	});

	doc:addShape(r1);

	-- create a file stream to write out the image
	local fs = FileStream.open("test_svggeometry.svg")
	--local fs = FileStream.new(io.stdout);
	local strm = SVGStream(fs);


	doc:write(strm);
end


local function test_Style()
	local s = SVGGeometry.Style();
	--fill:rgb(0,0,255);stroke-width:3;stroke:rgb(0,0,0)
	s:addAttribute("fill", "rgb(0,0,255)");
	s:addAttribute("stroke-width", "3");
	s:addAttribute("stroke", "rgb(0,0,0)");

	print(s);
end

test_Document();
--test_Style();

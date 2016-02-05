--test_svggeometry.lua
-- SETUP --
package.path = "../?.lua;"..package.path

local FileStream = require("filestream")
local SVGStream = require("ljgraph2D.SVGStream")

local SVGGeometry = require("ljgraph2D.SVGGeometry")
local Document = SVGGeometry.Document;
local Rect = SVGGeometry.Rect;


-- TEST --
local doc = Document({width = 320, height= 110})
local r1 = Rect({
	x = 10;
	y = 10;
	width = 300;
	height = 100;
	style = {};
	});

doc:addShape(r1);

-- create a file stream to write out the image
local fs = FileStream.open("test_svggeometry.svg")
--local fs = FileStream.new(io.stdout);
local strm = SVGStream(fs);


doc:write(strm);

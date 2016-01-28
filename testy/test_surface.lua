--test_path2d.lua

package.path = "../?.lua;"..package.path

local ffi = require("ffi")
local Surface = require("ljgraph2D.Surface")
local colors = require("ljgraph2D.colors")
local SVGTypes = require("ljgraph2D.SVGTypes")
local bmp = require("bmpcodec")
local FileStream = require("filestream")
local transform2D = require("ljgraph2D.transform2D")
local utils = require("utils")



local function solidColor(value)
	local color = SVGTypes.SVGCachedPaint();
	color.type = SVGTypes.PaintType.COLOR;
	color.colors[0] = value;

	return color;
end

local function colorLinearGradient(value1, value2)
	local color = SVGTypes.SVGCachedPaint();
	color.type = SVGTypes.PaintType.LINEAR_GRADIENT;
	color.colors[0] = value1;
	color.colors[1] = value2;
	transform2D.xformIdentity(color.xform);

	return color;
end


local surf = Surface(320, 240);
local solidRed = solidColor(colors.RGBA(255,0,0));


local dst = surf.data;
local count = 100;
local cover = ffi.new("uint8_t[256]")
ffi.fill(cover, count, 255);

local x = 10;
local y = 10;
local tx = 0;
local ty = 0;
local scale = 1.0;
local cache = solidRed;

utils.drawCheckerboard (surf,8, colors.svg.lightgray, colors.svg.white)

--[[
local function fillRect(x,y,w,h, value)
	for lineNum = y, y+h-1 do
		surf:hline(x, lineNum, w, value)
	end
end
--]]

local function test_linearGradient()
	utils.fillRect(surf, 50, 50, 100, 180, colors.red);

	local linearBlue = colorLinearGradient(colors.RGBA(0,0,255), colors.RGBA(0,0,127,255));
	local color1 = colors.RGBA(0,0,255)
	local color2 = colors.RGBA(0,0,127)
	
	-- setup the color stops
	for i=0,255 do
		local r = 0;	-- RANGEMAP(i, 0, 255, 0, 125);
		local g = RANGEMAP(i, 0, 255, 0, 255);
		local b = RANGEMAP(i, 0, 255, 255, 0);
		local a = RANGEMAP(i, 0, 255, 255, 64)
		linearBlue.colors[i] = colors.RGBA(r,g,b, a);
	end

	tx = 80
	ty = 50
	scale = 255
	for lineNum = 1, 200 do
		dst = surf.data + (lineNum*surf.width*4)+x*4;
		surf:scanlineSolid(dst, count, cover, x, lineNum, tx, ty, scale, linearBlue);
	end
end

--surf:scanlineSolid(dst, count, cover, x, 100, tx, ty, scale, cache)
--surf:hline(10, 20, 200, colors.green);

test_linearGradient()

-- Write the surface to a .bmp file
local fs = FileStream.open("test_surface.bmp")
bmp.write(fs, surf)
fs:close();

--test_path2d.lua

package.path = "../?.lua;"..package.path

local ffi = require("ffi")
local Surface = require("ljgraph2D.Surface")
local colors = require("ljgraph2D.colors")
local SVGTypes = require("ljgraph2D.SVGTypes")
local transform2D = require("ljgraph2D.transform2D")
local utils = require("utils")



local function solidColor(value)
	local cache = SVGTypes.SVGCachedPaint();
	local paint = SVGTypes.SVGPaint();
	paint.type = SVGTypes.PaintType.COLOR;
	paint.color = value;

	SVGTypes.initPaint(cache, paint, 1.0);

	return cache;
end

local function colorLinearGradient(value1, value2)
	local cache = SVGTypes.SVGCachedPaint();
	cache.type = SVGTypes.PaintType.LINEAR_GRADIENT;
	transform2D.xformIdentity(cache.xform);

	--local paint = SVGTypes.SVGPaint();
	--paint.type = SVGTypes.PaintType.LINEAR_GRADIENT;


	-- setup the linear gradient directly
	--SVGTypes.initPaint(cache, paint, 1.0);

	for i=0,255 do
		local u = RANGEMAP(i, 0, 255, 0, 1.0)
		local c = colors.lerpRGBA(value1, value2, u)
		cache.colors[i] = c;
	end

	return cache;
end


local surf = Surface(320, 240);

local function drawBackground()
	utils.drawCheckerboard (surf,8, colors.svg.lightgray, colors.svg.white)
end


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



local function test_linearGradient()
	utils.fillRect(surf, 50, 50, 100, 180, colors.red);

	local color1 = colors.RGBA(0,0,255, 255)
	local color2 = colors.RGBA(125,255,0, 64)
	--local color2 = colors.RGBA(186, 85, 211, 64);	-- mediumorchid

	local linearBlue = colorLinearGradient(color1, color2);
	
	tx = 80
	ty = 50
	scale = 255
	for lineNum = 1, 200 do
		dst = surf.data + (lineNum*surf.width*4)+x*4;
		surf:scanlineSolid(dst, count, cover, x, lineNum, tx, ty, scale, linearBlue);
	end
end

drawBackground();
test_linearGradient();

utils.save(surf, "test_surface.bmp");

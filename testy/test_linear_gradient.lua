--test_path2d.lua

package.path = "../?.lua;"..package.path

local ffi = require("ffi")
local Surface = require("ljgraph2D.Surface")
local colors = require("ljgraph2D.colors")
local SVGTypes = require("ljgraph2D.SVGTypes")
local transform2D = require("ljgraph2D.transform2D")
local utils = require("utils")
local maths = require("ljgraph2D.maths")

local RGBA = colors.RGBA;
local deg = math.deg;
local rad = math.rad;


--[[
	Given a set of colors, create a table
	of GradientStop object, with an even 
	distribution across the space
--]]
local function colorsToGradientStops(...)
	local nargs = select('#', ...)
	local stops = {}
	for i=1,nargs do
		local u = maths.RANGEMAP(i, 1, nargs, 0, 1)
		table.insert(stops, SVGTypes.SVGGradientStop(select(i,...), u));
	end

	return stops;
end

local function linearGradient(...)
	return SVGTypes.SVGGradient({stops = colorsToGradientStops(...)});
end

local function linearGradientPaint(...)
	local paint = SVGTypes.SVGPaint({
		['type'] = SVGTypes.PaintType.LINEAR_GRADIENT;
		gradient = linearGradient(...);
		});

	return paint;
end

local function solidColor(value)
	local cache = SVGTypes.SVGCachedPaint();
	local paint = SVGTypes.SVGPaint();
	paint.type = SVGTypes.PaintType.COLOR;
	paint.color = value;

	SVGTypes.initPaint(cache, paint, 1.0);

	return cache;
end

local function colorLinearGradient(...)
	local cache = SVGTypes.SVGCachedPaint();

	-- setup the linear gradient
	SVGTypes.initPaint(cache, linearGradientPaint(...), 1.0);

	return cache;
end


local surf = Surface(320, 240);

local function drawBackground()
	utils.drawCheckerboard (surf,8, colors.svg.lightgray, colors.svg.white)
end


--local solidRed = solidColor(colors.RGBA(255,0,0));


local function test_linearGradient()
	utils.fillRect(surf, 50, 50, 100, 180, colors.red);

	--local horizLinear = colorLinearGradient(RGBA(0,0,255, 255), RGBA(125,255,0, 64));
	local horizLinear = colorLinearGradient(RGBA(255,0,0, 200), RGBA(0,255,0,255), RGBA(0,0,255, 200));
	transform2D.xformSetRotation(horizLinear.xform, rad(90));

	local count = 100;
	local cover = ffi.new("uint8_t[256]")
	ffi.fill(cover, 255, 255);
	local x = 10;
	local y = 10;
	local tx = 0;
	local ty = 0;
	local scale = count;	-- what is driving the range of the color change
							-- if it's horizontal, then it should be 'count'
							-- if it's vertical, then it should be number of lines

	for lineNum = 1, 200 do
		local dst = surf.data + (lineNum*surf.width*4)+x*4;
		surf:scanlineSolid(dst, count, cover, x, lineNum, tx, ty, scale, horizLinear);
	end

	transform2D.xformSetRotation(horizLinear.xform, rad(0));
	scale = 100;
	count = 180;
	x = 120;
	y = 100;
	for lineNum = 1, 100 do
		local dst = surf.data + ((y+lineNum)*surf.width*4)+x*4;
		surf:scanlineSolid(dst, count, cover, x, lineNum, tx, ty, scale, horizLinear);
	end
end

drawBackground();
test_linearGradient();

utils.save(surf, "test_surface.bmp");

--[[
	References
	
	http://www.sunshine2k.de/coding/java/TriangleRasterization/TriangleRasterization.html

--]]

local ffi = require("ffi")
local bit = require("bit")
local rshift = bit.rshift

local abs = math.abs;
local floor = math.floor;

local maths = require("ljgraph2D.maths")
local sgn = maths.sgn;
local round = maths.round;

local Surface = require("ljgraph2D.Surface")
local DrawingContext = require("ljgraph2D.DrawingContext")
local SVGTypes = require("ljgraph2D.SVGTypes")


local int16_t = tonumber;
local int32_t = tonumber;
local uint32_t = tonumber;
local int = tonumber;





--[[
	DrawingContext

	Represents the API for doing drawing.  This is a retained interface,
	so it will maintain a current drawing color and various other 
	attributes.
--]]
local Raster2D = {}
setmetatable(Raster2D, {
	__call = function(self, ...)
		return self:new(...)
	end,
})
local Raster2D_mt = {
	__index = Raster2D;
}



function Raster2D.init(self, width, height, data)
	--rowsize = GetAlignedByteCount(width, bitcount, alignment);
    --pixelarraysize = rowsize * math.abs(height);
    local surf = Surface(width, height, data);

	local obj = {
		surface = surf;
		Context = DrawingContext(width, height);
		width = width;
		height = height;
		--bitcount = bitcount;
		--data = data;

		rowsize = rowsize;
		pixelarraysize = pixelarraysize;

		SpanBuffer = ffi.new("int32_t[?]", width);

		tessTol = 0.25;
		distTol = 0.01;

		-- set of points defining current path
		px = 0;		-- Current cursor location
		py = 0;		

		edges = {};
		points = {};

	}
	setmetatable(obj, DrawingContext_mt)

	return obj;
end

function Raster2D.new(self, width, height, data)
	data = data or ffi.new("int32_t[?]", width*height)
	return self:init(width, height, data)
end

function Raster2D.clearAll(self)
	self.surface:clearAll();
end

function Raster2D.clearToWhite(self)
	self.surface:clearToWhite();
end

-- Rectangle drawing
function Raster2D.fillRect(self, x, y, width, height, value)
	local length = width;

	-- fill the span buffer with the specified
	while length > 0 do
		self.SpanBuffer[length-1] = value;
		length = length-1;
	end

	-- use hspan, since we're doing a srccopy, not an 'over'
	while height > 0 do
		self:hspan(x, y+height-1, width, self.SpanBuffer)
		height = height - 1;
	end
end

function Raster2D.frameRect(self, x, y, width, height, value)
	-- two horizontals
	self:hline(x, y, width, value);
	self:hline(x, y+height-1, width, value);

	-- two verticals
	self:vline(x, y, height, value);
	self:vline(x+width-1, y, height, value);
end

-- Text Drawing
function Raster2D.fillText(self, x, y, text, font, value)
	font:scan_str(self.surface, x, y, text, value)
end


-- Line Drawing
-- Arbitrary line using Bresenham
function Raster2D.line(self, x1, y1, x2, y2, value)
	x1 = floor(x1);
	y1 = floor(y1);
	x2 = floor(x2);
	y2 = floor(y2);

	local dx = x2 - x1;      -- the horizontal distance of the line
	local dy = y2 - y1;      -- the vertical distance of the line
	local dxabs = abs(dx);
	local dyabs = abs(dy);
	local sdx = sgn(dx);
	local sdy = sgn(dy);
	local x = rshift(dyabs, 1);
	local y = rshift(dxabs, 1);
	local px = x1;
	local py = y1;

	self.surface:pixel(x1, y1, value);

	if (dxabs >= dyabs) then -- the line is more horizontal than vertical
		for i = 0, dxabs-1 do
			y = y+dyabs;
			if (y >= dxabs) then
				y = y - dxabs;
				py = py + sdy;
			end
			px = px + sdx;
			self.surface:pixel(px, py, value);
		end
	else -- the line is more vertical than horizontal
		for i = 0, dyabs-1 do
			x = x + dxabs;
			if (x >= dyabs) then
				x = x - dyabs;
				px = px + sdx;
			end

			py = py + sdy;
			self.surface:pixel( px, py, value);
		end
	end
end

function Raster2D.setPixel(self, x, y, value)
	self.surface:pixel(x, y, value)
end

-- Optimized vertical lines
function Raster2D.vline(self, x, y, length, value)
	self.surface:vline(x, y, length, value);
end

function Raster2D.hline(self, x, y, length, value)
	self.surface:hline(x, y, length, value);
end

function Raster2D.hspan(self, x, y, length, span)
	self.surface:hspan(x, y, length, span)
end


return Raster2D

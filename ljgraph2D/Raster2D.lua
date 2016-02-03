--[[
	References
	
	http://www.sunshine2k.de/coding/java/TriangleRasterization/TriangleRasterization.html

--]]

local ffi = require("ffi")
local bit = require("bit")
local rshift, lshift = bit.rshift, bit.lshift;
local bor, band = bit.bor, bit.band

local abs = math.abs;
local floor = math.floor;

local maths = require("ljgraph2D.maths")
local sgn = maths.sgn;
local round = maths.round;
local clamp = maths.clamp;

local colors = require("ljgraph2D.colors")
local Surface = require("ljgraph2D.Surface")
local DrawingContext = require("ljgraph2D.DrawingContext")
local SVGTypes = require("ljgraph2D.SVGTypes")


local int16_t = tonumber;
local int32_t = tonumber;
local uint32_t = tonumber;
local int = tonumber;

local SVG__SUBSAMPLES	= 5;
local SVG__FIXSHIFT		= 10;
local SVG__FIX			= lshift(1, SVG__FIXSHIFT);
local SVG__FIXMASK		= (SVG__FIX-1);
local SVG__MEMPAGE_SIZE	= 1024;


local function fillScanline(scanline, len, x0, x1, maxWeight, xmin, xmax)

	local i = rshift(x0, SVG__FIXSHIFT);
	local j = rshift(x1, SVG__FIXSHIFT);
	
	if (i < xmin) then
		xmin = i;
	end

	if (j > xmax) then
		xmax = j;
	end

	if (i < len and j >= 0) then
		if i == j then
			-- x0,x1 are the same pixel, so compute combined coverage
			scanline[i] = scanline[i] + rshift((x1 - x0) * maxWeight, SVG__FIXSHIFT);
		else
			if i >= 0 then-- add antialiasing for x0
				scanline[i] = scanline[i] + rshift(((SVG__FIX - band(x0, SVG__FIXMASK)) * maxWeight), SVG__FIXSHIFT);
			else
				i = -1; -- clip
			end

			if (j < len) then -- add antialiasing for x1
				scanline[j] = scanline[j] + rshift((band(x1, SVG__FIXMASK) * maxWeight), SVG__FIXSHIFT);
			else
				j = len; -- clip
			end

			--for (++i; i < j; ++i) do -- fill pixels between x0 and x1
			i = i + 1;
			while (i < j) do
				scanline[i] = scanline[i] + maxWeight;
				i = i + 1;
			end
		end
	end

	return xmin, xmax;
end

-- note: this routine clips fills that extend off the edges... ideally this
-- wouldn't happen, but it could happen if the truetype glyph bounding boxes
-- are wrong, or if the user supplies a too-small bitmap
local function fillActiveEdges(scanline, len, edges, maxWeight, xmin, xmax, fillRule)
	-- non-zero winding fill
	local x0, w  = 0, 0;

	if fillRule == SVGTypes.FillRule.NONZERO then
		-- Non-zero
		for _, e in ipairs(edges) do
			if w == 0 then
				-- if we're currently at zero, we need to record the edge start point
				x0 = e.x; 
				w = w + e.dir;
			else
				local x1 = e.x; 
				w = w + e.dir;

				-- if we went to zero, we need to draw
				if w == 0 then
					xmin, xmax = fillScanline(scanline, len, x0, x1, maxWeight, xmin, xmax);
				end
			end
		end
	elseif (fillRule == NSVG_FILLRULE_EVENODD) then
		-- Even-odd
		--while (e ~= NULL) do
		for _, e in ipairs(edges) do
			if (w == 0) then
				-- if we're currently at zero, we need to record the edge start point
				x0 = e.x; 
				w = 1;
			else
				local x1 = e.x; 
				w = 0;
				fillScanline(scanline, len, x0, x1, maxWeight, xmin, xmax);
			end
		end
	end
end


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
    local surf = Surface(width, height, data);

	local obj = {
		surface = surf;
		Context = DrawingContext(width, height);
		width = width;
		height = height;

		StrokeColor = colors.black;
		FillColor = colors.white;

		rowsize = rowsize;
		pixelarraysize = pixelarraysize;

		SpanBuffer = ffi.new("int32_t[?]", width);

		--tessTol = 0.25;
		--distTol = 0.01;

		-- set of points defining current path
		px = 0;		-- Current cursor location
		py = 0;		

		--edges = {};
		--points = {};

	}
	setmetatable(obj, Raster2D_mt)

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

-- Drawing Style
function Raster2D.strokeColor(self, value)
	if value then
		self.StrokeColor = value;
		return self;
	end

	return self.StrokeColor;
end

function Raster2D.fillColor(self, value)
	if value then 
		self.FillColor = value;
		return self;
	end

	return self.FillColor;
end

-- Rectangle drawing
function Raster2D.fillRect(self, x, y, width, height, value)
	value = value or self.FillColor;
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
	value = value or self.StrokeColor;
	-- two horizontals
	self:hline(x, y, width, value);
	self:hline(x, y+height-1, width, value);

	-- two verticals
	self:vline(x, y, height, value);
	self:vline(x+width-1, y, height, value);
end

-- Text Drawing
function Raster2D.fillText(self, x, y, text, font, value)
	value = value or self.FillColor;
	font:scan_str(rself.surface, x, y, text, value)
end


-- Line Drawing



-- Arbitrary line using Bresenham
function Raster2D.line(self, x1, y1, x2, y2, value)
--print("Raster2D.line: ", x1, y1, x2, y2)

---[[
	value = value or self.StrokeColor;

	x1 = floor(x1);
	y1 = floor(y1);
	x2 = floor(x2);
	y2 = floor(y2);

	x1 = clamp(x1, 0, self.width);
	x2 = clamp(x2, 0, self.width);
	y1 = clamp(y1, 0, self.height);
	y2 = clamp(y2, 0, self.height);

	--print("line: ", x1, y1, x2, y2)

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
--]]
end

function Raster2D.setPixel(self, x, y, value)
	self.surface:pixel(x, y, value)
end

-- Optimized vertical lines
function Raster2D.vline(self, x, y, length, value)
	value = value or self.StrokeColor;
	self.surface:vline(x, y, length, value);
end

function Raster2D.hline(self, x, y, length, value)
	value = value or self.StrokeColor;
	self.surface:hline(x, y, length, value);
end

function Raster2D.hspan(self, x, y, length, span)
	self.surface:hspan(x, y, length, span)
end

--[[
function Raster2D.cubicBezier(self, x1, y1, x2,y2, x3, y3, x4, y4, value)
	value = value or self.strokeColor;

	self:line(x1, y1, x2,y2, value);
	self:line(x2,y2,  x3,y3, value);
	self:line(x3,y3,  x4, y4, value);
end
--]]

return Raster2D

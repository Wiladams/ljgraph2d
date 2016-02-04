--[[
	Surface - Represents the place where drawing can occur.
	It is basically just a chunk of memory with meta 
	information sufficient for drawing routines to 
	do their drawing.

	Some of the more primitive drawing routines are here
	such as clearAll, vline, hline, hspan, pixel

	The drawing routines that are found here do not do any
	bounds checking, so they can be faster than the drawing
	context that calls them.  It is up to the drawing context
	to do the appropriate clipping, scaling, transformations
	and the like, and then call these routines with parameters
	which are guaranteed to fit.  This way the decision of where
	to impose delays due to error checking go further up 
	into the drawing pipeline, and can thus be optimized
	where needed.
--]]

local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local abs = math.abs;
local floor = math.floor;

local maths = require("ljgraph2D.maths")
local sgn = maths.sgn;
local round = maths.round;
local clamp = maths.clamp;


local div255 = maths.div255;
local GetAlignedByteCount = maths.GetAlignedByteCount;
local colors = require("ljgraph2D.colors")
local colorComponents = colors.colorComponents;

local SVGTypes = require("ljgraph2D.SVGTypes")






local Surface = {}
setmetatable(Surface, {
	__call = function(self, ...)
		return self:new(...)
	end,
})
local Surface_mt = {
	__index = Surface;
}


local bitcount = 32;
local alignment = 4;

function Surface.init(self, width, height, data)
	rowsize = GetAlignedByteCount(width, bitcount, alignment);
    pixelarraysize = rowsize * math.abs(height);

	local obj = {
		width = width;
		height = height;
		bitcount = bitcount;
		data = data;

		rowsize = rowsize;
		pixelarraysize = pixelarraysize;
		SpanBuffer = ffi.new("int32_t[?]", width);
	}
	setmetatable(obj, Surface_mt)

	return obj;
end

function Surface.new(self, width, height, data)
	if not width then
		return nil;
	end

	data = data or ffi.new("uint8_t[?]", width*height*4)
	return self:init(width, height, data)
end

function Surface.clearAll(self)
	ffi.fill(ffi.cast("char *", self.data), self.width*self.height*4)
end

function Surface.clearToWhite(self)
	ffi.fill(ffi.cast("char *", self.data), self.width*self.height*4, 255)
end

function Surface.hline(self, x, y, length, value)
	local offset = y*self.width+x;
	while length > 0 do
		ffi.cast("uint32_t *", self.data)[offset] = value;
		offset = offset + 1;
		length = length-1;
	end
end

function Surface.hspan(self, x, y, length, span)
	local dst = ffi.cast("char *", self.data) + (y*self.width*ffi.sizeof("int32_t"))+(x*ffi.sizeof("int32_t"))
	ffi.copy(dst, span, length*ffi.sizeof("int32_t"))
end

-- set or get a value for a single pixel
function Surface.pixel(self, x, y, value)
	local offset = y*self.width+x;
	if value then
		ffi.cast("uint32_t *",self.data)[offset] = value;
		return self;
	end

	return self.data[offset]
end

-- Line Clipping in preparation for line drawing
local LN_INSIDE = 0; -- 0000
local LN_LEFT = 1;   -- 0001
local LN_RIGHT = 2;  -- 0010
local LN_BOTTOM = 4; -- 0100
local LN_TOP = 8;    -- 1000

-- Compute the bit code for a point (x, y) using the clip rectangle
-- bounded diagonally by (xmin, ymin), and (xmax, ymax)

local function ComputeOutCode(xmin, ymin, xmax, ymax, x, y)

	--double xmin = rct.x;
	--double xmax = rct.x + rct.width - 1;
	--double ymin = rct.y;
	--double ymax = rct.y + rct.height - 1;

	local code = LN_INSIDE;          -- initialised as being inside of clip window

	if (x < xmin) then           -- to the left of clip window
		code = bor(code, LN_LEFT);
	elseif x > xmax then      -- to the right of clip window
		code = bor(code, LN_RIGHT);
	end

	if y < ymin then           -- below the clip window
		code = bor(code, LN_BOTTOM);
	elseif y > ymax then     -- above the clip window
		code = bor(code, LN_TOP);
	end

	return code;
end

-- Cohen–Sutherland clipping algorithm clips a line from
-- P0 = (x0, y0) to P1 = (x1, y1) against a rectangle with 
-- diagonal from (xmin, ymin) to (xmax, ymax).
local function  clipLine(xmin, ymin, xmax, ymax, x0, y0, x1, y1)
	--double xmin = bounds.x;
	--double xmax = bounds.x + bounds.width - 1;
	--double ymin = bounds.y;
	--double ymax = bounds.y + bounds.height - 1;

	-- compute outcodes for P0, P1, and whatever point lies outside the clip rectangle
	local outcode0 = ComputeOutCode(xmin, ymin, xmax, ymax, x0, y0);
	local outcode1 = ComputeOutCode(xmin, ymin, xmax, ymax, x1, y1);

	local accept = false;

	while true do
		if (bor(outcode0, outcode1) == 0) then -- Bitwise OR is 0. Trivially accept and get out of loop
			accept = true;
			break;
		elseif band(outcode0, outcode1) ~= 0 then -- Bitwise AND is not 0. Trivially reject and get out of loop
			break;
		else
			-- failed both tests, so calculate the line segment to clip
			-- from an outside point to an intersection with clip edge
			local x = 0;
			local y = 0;

			-- At least one endpoint is outside the clip rectangle; pick it.
			local outcodeOut = outcode0;
			if outcodeOut == 0 then
				outcodeOut = outcode1;
			end

			-- Now find the intersection point;
			-- use formulas y = y0 + slope * (x - x0), x = x0 + (1 / slope) * (y - y0)
			if band(outcodeOut, LN_TOP) ~= 0 then            -- point is above the clip rectangle
				x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0);
				y = ymax;
			
			elseif band(outcodeOut, LN_BOTTOM) ~= 0 then -- point is below the clip rectangle
				x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0);
				y = ymin;
			
			elseif band(outcodeOut, LN_RIGHT) ~= 0 then  -- point is to the right of clip rectangle
				y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0);
				x = xmax;
			
			elseif band(outcodeOut, LN_LEFT) ~= 0 then   -- point is to the left of clip rectangle
				y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0);
				x = xmin;
			end

			-- Now we move outside point to intersection point to clip
			-- and get ready for next pass.
			if (outcodeOut == outcode0) then
				x0 = x;
				y0 = y;
				outcode0 = ComputeOutCode(xmin, ymin, xmax, ymax, x0, y0);
			
			else 
				x1 = x;
				y1 = y;
				outcode1 = ComputeOutCode(xmin, ymin, xmax, ymax, x1, y1);
			end
		end
	end

	return accept, x0, y0, x1, y1;
end


-- Arbitrary line using Bresenham
function Surface.line(self, x1, y1, x2, y2, value)
	print("Surface.line: ", x1, y1, x2, y2)
	
	local accept, x1, y1, x2, y2 = clipLine(0, 0, self.width-1, self.height-1, x1, y1, x2, y2)
	
	-- don't bother drawing line if outside boundary
	if not accept then 
		return ;
	end

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

	self:pixel(x1, y1, value);

	if (dxabs >= dyabs) then -- the line is more horizontal than vertical
		for i = 0, dxabs-1 do
			y = y+dyabs;
			if (y >= dxabs) then
				y = y - dxabs;
				py = py + sdy;
			end
			px = px + sdx;
			self:pixel(px, py, value);
		end
	else -- the line is more vertical than horizontal
		for i = 0, dyabs-1 do
			x = x + dxabs;
			if (x >= dyabs) then
				x = x - dyabs;
				px = px + sdx;
			end

			py = py + sdy;
			self:pixel( px, py, value);
		end
	end
end

-- Rectangle drawing
function Surface.fillRect(self, x, y, width, height, value)
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

function Surface.frameRect(self, x, y, width, height, value)
	value = value or self.StrokeColor;
	-- two horizontals
	self:hline(x, y, width, value);
	self:hline(x, y+height-1, width, value);

	-- two verticals
	self:vline(x, y, height, value);
	self:vline(x+width-1, y, height, value);
end

-- Text Drawing
function Surface.fillText(self, x, y, text, font, value)
	value = value or self.FillColor;
	font:scan_str(self, x, y, text, value)
end


-- perform a SRCOVER, honoring the color, whether it's 
-- solid, or a linear gradient, or radial gradient
function Surface.scanlineSolid(self, dst, count, cover, x, y, tx, ty, scale, cache)
--print("typeof cover: ", ffi.typeof(cover))
	if (cache.type == SVGTypes.PaintType.COLOR) then
		local cr, cg, cb, ca = colorComponents(cahce.colors[0]);


		for i = 0, count-1 do
			local a = div255(cover[0] * ca);
			local ia = 255 - a;
			-- Premultiply
			local r = div255(cr * a);
			local g = div255(cg * a);
			local b = div255(cb * a);
			-- Blend over
			b = b + div255(ia * dst[0]);
			g = g + div255(ia * dst[1]);
			r = r + div255(ia * dst[2]);
			a = a + div255(ia * dst[3]);

			dst[0] = b;
			dst[1] = g;
			dst[2] = r;
			dst[3] = a;

			cover = cover + 1;
			dst = dst + 4;
		end
	elseif (cache.type == SVGTypes.PaintType.LINEAR_GRADIENT) then
		local t = cache.xform;

		local fx = (x - tx) / scale;
		local fy = (y - ty) / scale;
		local dx = 1.0 / scale;


		for i = 0, count-1 do
			local gy = fx*t[1] + fy*t[3] + t[5];
			local c = cache.colors[clamp(gy*255, 0, 255)];
		
			local cr, cg, cb, ca = colorComponents(c);

			local a = div255(cover[0] * ca);
			local ia = 255 - a;

			-- Premultiply
			local r = div255(cr * a);
			local g = div255(cg * a);
			local b = div255(cb * a);

			-- Blend over
			b = b + div255(ia * dst[0]);
			g = g + div255(ia * dst[1]);
			r = r + div255(ia * dst[2]);
			a = a + div255(ia * dst[3]);

			dst[0] = b;
			dst[1] = g;
			dst[2] = r;
			dst[3] = a;

			cover = cover + 1;
			dst = dst + 4;
			fx = fx + dx;
		end
	elseif (cache.type == SVGTypes.PaintType.RADIAL_GRADIENT) then
		local t = cache.xform;

		local fx = (x - tx) / scale;
		local fy = (y - ty) / scale;
		local dx = 1.0 / scale;

		for i = 0, count-1 do
			local gx = fx*t[0] + fy*t[2] + t[4];
			local gy = fx*t[1] + fy*t[3] + t[5];
			local gd = sqrt(gx*gx + gy*gy);
			local c = cache.colors[clamp(gd*255, 0, 255)];
			local cr, cg, cb, ca = colorComponents(c);

			local a = div255(cover[0] * ca);
			local ia = 255 - a;

			-- Premultiply
			local r = div255(cr * a);
			local g = div255(cg * a);
			local b = div255(cb * a);

			-- Blend over
			b = b + div255(ia * dst[0]);
			g = g + div255(ia * dst[1]);
			r = r + div255(ia * dst[2]);
			a = a + div255(ia * dst[3]);

			dst[0] = b;
			dst[1] = g;
			dst[2] = r;
			dst[3] = a;

			cover = cover + 1;
			dst = dst + 4;
			fx = fx + dx;
		end
	end
end

function Surface.vline(self, x, y, length, value)
	local offset = y*self.width+x;
	while length > 0 do
		self.data[offset] = value;
		offset = offset + self.width;
		length = length - 1;
	end
end

return Surface

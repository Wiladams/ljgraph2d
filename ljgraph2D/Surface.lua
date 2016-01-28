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

local maths = require("ljgraph2D.maths")
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

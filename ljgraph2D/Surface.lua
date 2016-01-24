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


local function GetAlignedByteCount(width, bitsPerPixel, byteAlignment)
    local nbytes = width * (bitsPerPixel/8);
    return nbytes + (byteAlignment - (nbytes % byteAlignment)) % 4
end


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
	data = data or ffi.new("int32_t[?]", width*height)
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
		self.data[offset] = value;
		offset = offset + 1;
		length = length-1;
	end
end

function Surface.hspan(self, x, y, length, span)
	local dst = ffi.cast("char *", self.data) + (y*self.width*ffi.sizeof("int32_t"))+(x*ffi.sizeof("int32_t"))
	ffi.copy(dst, span, length*ffi.sizeof("int32_t"))
end

function Surface.pixel(self, x, y, value)
	local offset = y*self.width+x;
	if value then
		self.data[offset] = value;
		return self;
	end

	return self.data[offset]
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
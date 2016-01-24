local ffi = require("ffi")
local bit = require("bit")
local lshift, rshift = bit.lshift, bit.rshift
local bor, band = bit.bor, bit.band;

local int = ffi.typeof("int")
local uint16_t = ffi.typeof("uint16_t")
local cover_type = ffi.typeof("uint32_t")
local cover_none = 0;
local cover_full = 1;


ffi.cdef[[
struct glyph_rect
{
	int x1, y1, x2, y2;
	double dx, dy;
};
]]
local glyph_rect = ffi.typeof("struct glyph_rect")

ffi.cdef[[
typedef struct glyph {
	size_t width;
	size_t byte_width;

	uint8_t *data;
} glyph_t;
]]
local glyph_t = ffi.typeof("struct glyph")

-- utility function
local function isBigEndian() 
	return ffi.abi("be")
end


local EmbeddedFont = {}
local EmbeddedFont_mt = {
	__index = EmbeddedFont;
}



function EmbeddedFont.init(self, data)
	local obj = {
		data = data;	-- cast of data isn't good enough to anchor it
		bigendian = isBigEndian();
		height = data[0];
		baseline = data[1];
		start_char = data[2];
		num_chars = data[3];
		charbits = ffi.cast("uint8_t *", (data + 4));
	}

	setmetatable(obj, EmbeddedFont_mt)

	return obj;
end

function EmbeddedFont.new(self, data)
	return self:init(data);
end


-- Create a 16-bit value, taking into account
-- the endianness of the host.
-- The data is in little endian format
function EmbeddedFont.readint16(self, p)

	local v = uint16_t();
	
	if (not self.bigendian) then
		v = p[0] + lshift(p[1], 8);	
	else
		v = p[1] + lshift(p[0], 8);
	end

	return v;
end

function EmbeddedFont.glyphPointer(self, glyph)
	return self.charbits + self.num_chars * 2 + self:readint16(self.charbits + (glyph - self.start_char) * 2);
end

-- Prepare a glyph to be written to a specific
-- position
--[[
function EmbeddedFont.glyph_t_prepare(self, ginfo, r, x, y, flip)

	r.x1 = int(x);
	r.x2 = r.x1 + ginfo.width - 1;
	
	if (flip) then
		r.y1 = int(y) - self.height + self.baseline;
		r.y2 = r.y1 + self.height - 1;
	else
		r.y1 = int(y) - self.baseline + 1;
		r.y2 = r.y1 + self.height - 1;
	end

	r.dx = ginfo.width;
	r.dy = 0;
end
--]]

-- Fill in the meta information for the specified glyph
function EmbeddedFont.glyph_t_init(self, ginfo, glyphidx)

	local glyphptr = self:glyphPointer(glyphidx);

	ginfo.width = glyphptr[0];
	ginfo.data = glyphptr + 1;
	ginfo.byte_width = rshift((ginfo.width + 7), 3);

	return ginfo;
end

function EmbeddedFont.glyphWidth(self, glyphidx)

	local ginfo = glyph_t();

	self:glyph_t_init(ginfo, glyphidx);

	return ginfo.width;
end

-- Figure out the width of a string in a given font
function EmbeddedFont.measureText(self, str)
	--print(".stringWidth: ", str, #str)
	local w = 0;

	for idx=1, #str do
		local byte = str:byte(idx)	
		--print("w: ", w, byte)
		w = w + self:glyphWidth(byte);
	end

	return {
		width = tonumber(w);
		height = self.height;
		baseline = self.baseline;
	}

end


-- Create a single scanline of the glyph
function EmbeddedFont.glyph_t_span(self, g, i, m_span)
	--i = self.height - i - 1;
	i = self.height - i;
--print(".glyph_t_span (i): ", i)

	local bits = g.data + i * g.byte_width;
	local val = bits[0];
	local nb = 0;

	for j = 0, tonumber(g.width)-1 do
		--m_span[j] = (band(val, 0x80) ? cover_full : cover_none);
		if band(val, 0x80 )> 0 then
			m_span[j]  = cover_full;
		else
			m_span[j] = cover_none;
		end

		val = lshift(val,1);
		nb = nb + 1;
		if (nb >= 8) then
			bits = bits + 1;
			val = bits[0];
			nb = 0;
		end
	end

	return m_span;
end


function EmbeddedFont.scan_glyph(self, pb, glyph, x, y, color)

	local m_span = ffi.new("uint8_t[32]");
	local line = self.height;

	while (line > 0) do
		self:glyph_t_span(glyph, line, m_span);

		-- transfer the span to the bitmap
		local spanwidth = glyph.width;
		while (spanwidth > 0) do
			if (m_span[spanwidth] == cover_full) then
				-- really we want a 'cover pixel' so we can do anti-aliasing
				-- but it's a bitmap font, so it won't matter
				pb:pixel(x + spanwidth, y + self.height - line, color);
				--pb:frameRect((x + spanwidth)*9, (y + self.height - line)*9, 8, 8, color)
			end

			spanwidth = spanwidth - 1;
		end
		ffi.fill(m_span, 0, 32);

		line = line - 1;
	end

	return glyph.width;
end


function EmbeddedFont.scan_str(self, pb, x, y, chars, color)

	local ginfo = glyph_t();

	local dx = x;
	local dy = y;

	for idx=1, #chars do
		self:glyph_t_init(ginfo, chars:byte(idx,idx));
		self:scan_glyph(pb, ginfo, dx, dy, color);
		dx = dx + ginfo.width;
		idx = idx + 1;
	end

	return dx;
end


return EmbeddedFont
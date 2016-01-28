local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local maths = require("ljgraph2D.maths")
local clamp = maths.clamp
local colors = require("ljgraph2D.colors")
local applyOpacity = colors.applyOpacity;
local lerpRGBA = colors.lerpRGBA;



ffi.cdef[[
typedef struct SVGedge {
	float x0,y0, x1,y1;
	int dir;
	struct SVGedge* next;
} SVGedge_t;
]]
local SVGEdge = ffi.typeof("struct SVGedge");

ffi.cdef[[
typedef struct SVGpoint {
	float x, y;
	float dx, dy;
	float len;
	float dmx, dmy;
	unsigned char flags;
} SVGpoint_t;
]]
local SVGPoint = ffi.typeof("struct SVGpoint");

ffi.cdef[[
typedef struct SVGGradientStop {
	uint32_t color;
	float offset;
} SVGGradientStop_t;
]]

ffi.cdef[[
typedef struct SVGGradient {
	float xform[6];
	char spread;
	float fx, fy;
	int nstops;
	struct SVGGradientStop stops[1];
} SVGGradient_t;
]]

ffi.cdef[[
typedef struct SVGPaint {
	char type;
	union {
		uint32_t color;
		struct SVGGradient* gradient;
	};
} SVGPaint_t;
]]
local SVGPaint = ffi.typeof("struct SVGPaint");

ffi.cdef[[
typedef struct SVGCachedPaint {
	char type;
	char spread;
	float xform[6];
	uint32_t colors[256];
} SVGCachedPaint_t;
]]
local SVGCachedPaint = ffi.typeof("struct SVGCachedPaint")

--[[
	Initialize a SVGCachedPaint_t structure.  Depending
	on whether it's gradient or COLOR, the right
	thing will happen.

cache 	- 	SVGCachedPaint_t
paint 	- 	SVGPaint
opacity - 	float
--]]
local function  initPaint(cache, paint, opacity)

	cache.type = paint.type;

	-- Setup a solid color paint by simply applying
	-- the opacity value and returning it
	if (paint.type == SVGTypes.PaintType.COLOR) then
		cache.colors[0] = applyOpacity(paint.color, opacity);
		return cache;
	end

	-- Setup a gradient value
	local grad = paint.gradient;

	cache.spread = grad.spread;
	ffi.copy(cache.xform, grad.xform, ffi.sizeof("float")*6);

	if grad.nstops == 0 then
		for i = 0, 255 do
			cache.colors[i] = 0;
		end
	elseif (grad.nstops == 1) then
		for i = 0, 255 do
			cache.colors[i] = applyOpacity(grad.stops[0].color, opacity);
		end
	else 
		local cb = 0;
		local ua, ub, du, u = 0,0,0,0;
		local count=0;

		local ca = applyOpacity(grad.stops[0].color, opacity);
		local ua = clamp(grad.stops[0].offset, 0, 1);
		local ub = clamp(grad.stops[grad.nstops-1].offset, ua, 1);
		local ia = ua * 255.0;
		local ib = ub * 255.0;
		
		for i = 0, ia-1 do
			cache.colors[i] = ca;
		end

		for i = 0, grad.nstops-2 do
			ca = applyOpacity(grad.stops[i].color, opacity);
			cb = applyOpacity(grad.stops[i+1].color, opacity);
			ua = clamp(grad.stops[i].offset, 0, 1);
			ub = clamp(grad.stops[i+1].offset, 0, 1);
			ia = ua * 255.0;
			ib = ub * 255.0;
			count = ib - ia;

			if count > 0 then
				u = 0;
				du = 1.0 / count;

				for j = 0, count-1 do
					cache.colors[ia+j] = lerpRGBA(ca,cb,u);
					u = u + du;
				end
			end
		end

		for i = ib, 255 do
			cache.colors[i] = cb;
		end
	end
end


return {
	SVGCachedPaint = SVGCachedPaint;
	SVGEdge = SVGEdge;
	SVGPoint = SVGPoint;

	LineJoin = {
		MITER = 0,
		ROUND = 1,
		BEVEL = 2,
	};
	
	LineCap = {
		BUTT = 0,
		ROUND = 1,
		SQUARE = 2,
	};

	PaintType = {
		NONE = 0,
		COLOR = 1,
		LINEAR_GRADIENT = 2,
		RADIAL_GRADIENT = 3,
	};

	PointFlags = {
		CORNER = 0x01,
		BEVEL = 0x02,
		LEFT = 0x04,
	};
	

	-- functions
	initPaint = initPaint;
}
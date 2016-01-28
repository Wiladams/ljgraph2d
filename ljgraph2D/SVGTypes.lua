local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local maths = require("ljgraph2D.maths")
local clamp = maths.clamp
local transform2D = require("ljgraph2D.transform2D")
local colors = require("ljgraph2D.colors")
local applyOpacity = colors.applyOpacity;
local lerpRGBA = colors.lerpRGBA;


local export = {}

local FillRule = {
	NONZERO = 0,
	EVENODD = 1,
};

local LineJoin = {
		MITER = 0,
		ROUND = 1,
		BEVEL = 2,
	};
	
local LineCap = {
		BUTT = 0,
		ROUND = 1,
		SQUARE = 2,
	};

local PaintType = {
		NONE = 0,
		COLOR = 1,
		LINEAR_GRADIENT = 2,
		RADIAL_GRADIENT = 3,
	};

local PointFlags = {
		CORNER = 0x01,
		BEVEL = 0x02,
		LEFT = 0x04,
	};
	

ffi.cdef[[
typedef struct SVGedge {
	float x0,y0, x1,y1;
	int dir;
	struct SVGedge* next;
} SVGedge_t;
]]
local SVGEdge = ffi.typeof("struct SVGedge");

ffi.cdef[[
typedef struct SVGActiveEdge {
	int x,dx;
	float ey;
	int dir;
	struct SVGActiveEdge *next;
} SVGActiveEdge_t;
]]
local SVGActiveEdge = ffi.typeof("struct SVGActiveEdge");


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
	double offset;	// 0.0 - 1.0
} SVGGradientStop_t;
]]
local SVGGradientStop = ffi.typeof("struct SVGGradientStop");



local SVGGradient = {}
setmetatable(SVGGradient, {
	__call = function(self, ...)
		return self:new(...);
	end,
})

local SVGGradient_mt = {
	__index = SVGGradient;
}

function SVGGradient.init(self, obj)
	local obj = obj or {}
	if not obj.xform then
		obj.xform = ffi.new("double[6]");
		transform2D.xformIdentity(obj.xform);
	end
	obj.stops = obj.stops or {};
	obj.spread = obj.spread or 0;
	obj.fx = obj.fx or 0;
	obj.fy = obj.fy or 0;

	setmetatable(obj, SVGGradient_mt);

	return obj;
end

function SVGGradient.new(self, ...)
	return self:init(...);
end

function SVGGradient.addStop(self, astop)
	table.insert(self.stops, astop);
end

--[=[
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
--]=]
local SVGPaint = {}
setmetatable(SVGPaint, {
	__call = function(self, ...)
		return self:new(...);
	end,
})
local SVGPaint_mt = {
	__index = SVGPaint;
}

function SVGPaint.init(self, obj)
	obj = obj or {}

	setmetatable(obj, SVGPaint_mt);

	return obj;
end

function SVGPaint.new(self, ...)
	return self:init(...);
end

--[=[
ffi.cdef[[
typedef struct SVGCachedPaint {
	char type;
	char spread;
	float xform[6];
	uint32_t colors[256];
} SVGCachedPaint_t;
]]
local SVGCachedPaint = ffi.typeof("struct SVGCachedPaint")
--]=]

---[[
local SVGCachedPaint = {}
setmetatable(SVGCachedPaint, {
	__call = function(self, ...)
		return self:new(...);
	end,
})

local SVGCachedPaint_mt = {
	__index = SVGCachedPaint;
}

function SVGCachedPaint.init(self, obj)
	obj = obj or {}
	if not obj.xform then
		obj.xform = ffi.new("double[6]");
		--transform2D.xformIdentity(obj.xform);
	end
	obj.spread = obj.spread or 0;
	obj.colors = obj.colors or ffi.new("uint32_t[256]");

	setmetatable(obj, SVGCachedPaint_mt)

	return obj;
end

function SVGCachedPaint.new(self, obj)
	return self:init(obj);
end
--]]

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
	if (paint.type == PaintType.COLOR) then
		cache.colors[0] = applyOpacity(paint.color, opacity);
		return cache;
	end

	-- Setup a gradient value
	local grad = paint.gradient;

	cache.spread = grad.spread;
	ffi.copy(cache.xform, grad.xform, ffi.sizeof(grad.xform));

	if #grad.stops == 0 then
		for i = 0, 255 do
			cache.colors[i] = 0;
		end
	elseif #grad.stops == 1 then
		for i = 0, 255 do
			cache.colors[i] = applyOpacity(grad.stops[1].color, opacity);
		end
	else 
		local cb = 0;
		local ua, ub, du, u = 0,0,0,0;
		local count=0;

		local ca = applyOpacity(grad.stops[1].color, opacity);
		local ua = clamp(grad.stops[1].offset, 0, 1);
		local ub = clamp(grad.stops[#grad.stops].offset, ua, 1);
		local ia = ua * 255.0;
		local ib = ub * 255.0;
		
		for i = 0, ia-1 do
			cache.colors[i] = ca;
		end

		for i = 1, #grad.stops-1 do
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


-- Enums
export.FillRule = FillRule;
export.LineJoin = LineJoin;
export.LineCap = LineCap;
export.PointFlags = PointFlags;
export.PaintType = PaintType;

-- Types
export.SVGActiveEdge = SVGActiveEdge;
export.SVGCachedPaint = SVGCachedPaint;
export.SVGEdge = SVGEdge;
export.SVGGradient = SVGGradient;
export.SVGGradientStop = SVGGradientStop;

export.SVGPaint = SVGPaint;
export.SVGPoint = SVGPoint;


	-- functions
export.initPaint = initPaint;


return export

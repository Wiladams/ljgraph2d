local ffi = require("ffi")

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
typedef struct SVGCachedPaint {
	char type;
	char spread;
	float xform[6];
	uint32_t colors[256];
} SVGCachedPaint_t;
]]
local SVGCachedPaint = ffi.typeof("struct SVGCachedPaint")


return {
	SVGCachedPaint = SVGCachedPaint;
	SVGEdge = SVGEdge;
	SVGPoint = SVGPoint;

	PaintType = {
		NONE = 0,
		COLOR = 1,
		LINEAR_GRADIENT = 2,
		RADIAL_GRADIENT = 3,
	};
}
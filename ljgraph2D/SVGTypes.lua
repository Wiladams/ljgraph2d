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

return {
	SVGEdge = SVGEdge;
	SVGPoint = SVGPoint;
}
local ffi = require("ffi")

--[[
typedef struct NSVGpath
{
	float* pts;					// Cubic bezier points: x0,y0, [cpx1,cpx1,cpx2,cpy2,x1,y1], ...
	int npts;					// Total number of bezier points.
	char closed;				// Flag indicating if shapes should be treated as closed.
	float bounds[4];			// Tight bounding box of the shape [minx,miny,maxx,maxy].
	struct NSVGpath* next;		// Pointer to next path, or NULL if last element.
} NSVGpath;
--]]

local SVGPath = {}
local SVGPath_mt = {
	__index = SVGPath;
}

function SVGPath.init(self, ...)
	local obj = {
		pts = {};
		closed = false;
		bounds = ffi.new("double[4]");
	}
	setmetatable(obj, SVGPath_mt);

	return obj;
end

function SVGPath.new(self, ...)
	return self:init(...);
end

return SVGPath;

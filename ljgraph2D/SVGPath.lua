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
setmetatable(SVGPath, {
	__call = function(self, ...)
		return self:new(...)
	end,
	})
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

function SVGPath.draw(self, graphPort)
	--print("SVGPath.draw: ", #self.pts)

	if #self.pts > 1 then
		for i=1, #self.pts-1 do
			graphPort:line(
			self.pts[i+0].x, self.pts[i+0].y, 
			self.pts[i+1].x, self.pts[i+1].y);
		end
	end
end

return SVGPath;

local ffi = require("ffi")
local floor = math.floor

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

-- Very rudimentary drawing
-- primarily usable for test 
-- purposes only
function SVGPath.draw(self, graphPort)
	--print("SVGPath.draw: ", #self.pts)
	--self:dump();

	if #self.pts > 1 then
		for i=1, #self.pts-1 do
			graphPort:line(
			floor(self.pts[i+0].x), floor(self.pts[i+0].y), 
			floor(self.pts[i+1].x), floor(self.pts[i+1].y));
		end

		if self.closed then
			graphPort:line(floor(self.pts[#self.pts].x), floor(self.pts[#self.pts].y), 
				floor(self.pts[1].x), floor(self.pts[1].y));
		end
	end
end

function SVGPath.dump(self)
	print("SVGPath.dump")
	for _, pt in ipairs(self.pts) do
		print(pt.x, pt.y)
	end
end

return SVGPath;

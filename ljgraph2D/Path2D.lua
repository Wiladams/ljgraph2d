--[[
	Path Management
--]]
local ffi = require("ffi")
local bit = require("bit")
local rshift, lshift, bor, band = bit.rshift, bit.lshift, bit.bor, bit.band

local abs = math.abs;
local floor = math.floor;

local maths = require("ljgraph2D.maths")
local sgn = maths.sgn;
local round = maths.round;
local pointsEquals = maths.pointsEquals;

local SVGTypes = require("ljgraph2D.SVGTypes")


local Path2D = {
	SVGpointFlags = {
		SVG_PT_CORNER = 0x01,
		SVG_PT_BEVEL = 0x02,
		SVG_PT_LEFT = 0x04,
	};

}
setmetatable(Path2D, {
	__call = function(self, ...)
		return self:new(...);
	end,
})
local Path2D_mt = {
	__index = Path2D;
}

function Path2D.init(self, ...)
	local obj = {
		points = {};
	}
	setmetatable(obj, Path2D_mt);

	return obj;
end

function Path2D.new(self, ...)
	return self:init(...)
end

function  Path2D.addPathPoint(self, x, y, flags)

	-- If the point is the same as the last point in our
	-- current set of points, then just set a flag on that
	-- point, and don't add a new point
	-- this might be true when your duplicating a point
	-- a number of times for a curve
	if #self.points > 0 then
		local pt = self.points[#self.points];
		if pointsEquals(pt.x,pt.y, x,y, self.distTol) then
			pt.flags = bor(pt.flags, flags);
			return;
		end
	end

	local pt = SVGTypes.SVGPoint()
	pt.x = x;
	pt.y = y;
	pt.flags = flags;
	table.insert(self.points, pt)

	return self;
end

function Path2D.appendPathPoint(self, pt)
	table.insert(self.points, pt)
end


function Path2D.addEdge(self, x0, y0, x1, y1)

	local e = SVGTypes.SVGEdge();

	-- Skip horizontal edges
	if y0 == y1 then
		return;
	end

	if y0 < y1 then
		e.x0 = x0;
		e.y0 = y0;
		e.x1 = x1;
		e.y1 = y1;
		e.dir = 1;
	else 
		e.x0 = x1;
		e.y0 = y1;
		e.x1 = x0;
		e.y1 = y0;
		e.dir = -1;
	end

	table.insert(self.edges, e);
end


function Path2D.flattenCubicBez(self,
								   x1,  y1,  x2,  y2,
								   x3,  y3,  x4,  y4,
								  level, atype)
end
	local x12,y12,x23,y23,x34,y34,x123,y123;
	local x234,y234,x1234,y1234;

	if level > 10 then 
		return;
	end

	local x12 = (x1+x2)*0.5;
	local y12 = (y1+y2)*0.5;
	local x23 = (x2+x3)*0.5;
	local y23 = (y2+y3)*0.5;
	local x34 = (x3+x4)*0.5;
	local y34 = (y3+y4)*0.5;
	local x123 = (x12+x23)*0.5;
	local y123 = (y12+y23)*0.5;

	local dx = x4 - x1;
	local dy = y4 - y1;
	local d2 = abs(((x2 - x4) * dy - (y2 - y4) * dx));
	local d3 = abs(((x3 - x4) * dy - (y3 - y4) * dx));

	if ((d2 + d3)*(d2 + d3) < self.tessTol * (dx*dx + dy*dy)) then
		self:addPathPoint(self, x4, y4, atype);
		return;
	end

	local x234 = (x23+x34)*0.5;
	local y234 = (y23+y34)*0.5;
	local x1234 = (x123+x234)*0.5;
	local y1234 = (y123+y234)*0.5;

	self:flattenCubicBez(x1,y1, x12,y12, x123,y123, x1234,y1234, level+1, 0);
	self:flattenCubicBez(x1234,y1234, x234,y234, x34,y34, x4,y4, level+1, atype);
end




return Path2D

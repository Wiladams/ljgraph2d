--[[
	Path Management
--]]
local ffi = require("ffi")
local bit = require("bit")
local rshift, lshift, bor, band = bit.rshift, bit.lshift, bit.bor, bit.band

local abs = math.abs;
local atan2 = math.atan2;
local floor = math.floor;
local PI = math.pi;

local maths = require("ljgraph2D.maths")
local normalize = maths.normalize;
local sgn = maths.sgn;
local round = maths.round;
local pointsEquals = maths.pointsEquals;

local SVGTypes = require("ljgraph2D.SVGTypes")
local int = ffi.typeof("int")

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
		tessTol = 0.25;
		distTol = 0.01;

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

local function initClosed(left, right, p0, p1, lineWidth)

	local w = lineWidth * 0.5;
	local dx = p1.x - p0.x;
	local dy = p1.y - p0.y;
	local len, dx, dy = normalize(dx, dy);
	local px = p0.x + dx*len*0.5;
	local py = p0.y + dy*len*0.5;
	local dlx = dy;
	local dly = -dx;
	local lx = px - dlx*w; 
	local ly = py - dly*w;
	local rx = px + dlx*w; 
	local ry = py + dly*w;
	
	left.x = lx; 
	left.y = ly;
	right.x = rx; 
	right.y = ry;
end

function Path2D.buttCap(self, left, right, p, dx, dy, lineWidth, connect)

	local w = lineWidth * 0.5;
	local px = p.x;
	local py = p.y;
	local dlx = dy;
	local dly = -dx;
	local lx = px - dlx*w;
	local ly = py - dly*w;
	local rx = px + dlx*w;
	local ry = py + dly*w;

	self:addEdge(lx, ly, rx, ry);

	if connect then
		self:addEdge(left.x, left.y, lx, ly);
		self:addEdge(rx, ry, right.x, right.y);
	end
	
	left.x = lx; 
	left.y = ly;
	right.x = rx; 
	right.y = ry;
end

function Path2D:squareCap(self, left, right, p, dx, dy, lineWidth, connect)

	local w = lineWidth * 0.5;
	local px = p.x - dx*w;
	local py = p.y - dy*w;
	local dlx = dy;
	local dly = -dx;
	local lx = px - dlx*w;
	local ly = py - dly*w;
	local rx = px + dlx*w;
	local ry = py + dly*w;

	self:addEdge(lx, ly, rx, ry);

	if connect then
		self:addEdge(left.x, left.y, lx, ly);
		self:addEdge(rx, ry, right.x, right.y);
	end

	left.x = lx; 
	left.y = ly;
	right.x = rx; 
	right.y = ry;
end

function Path2D.roundCap(self, left, right, p, dx, dy, lineWidth, ncap, connect)

	local w = lineWidth * 0.5;
	local px = p.x;
	local py = p.y;
	local dlx = dy;
	local dly = -dx;
	local lx = 0;
	local ly = 0;
	local rx = 0;
	local ry = 0;
	local prevx = 0;
	local prevy = 0;

	for i = 0, ncap-1 do
		local a = i/(ncap-1)*PI;
		local ax = cos(a) * w;
		local ay = sinf(a) * w;
		local x = px - dlx*ax - dx*ay;
		local y = py - dly*ax - dy*ay;

		if i > 0 then
			self:addEdge(prevx, prevy, x, y);
		end

		prevx = x;
		prevy = y;

		if (i == 0) then
			lx = x; 
			ly = y;
		elseif i == ncap-1 then
			rx = x; 
			ry = y;
		end
	end

	if connect then
		self:addEdge(left.x, left.y, lx, ly);
		self:addEdge(rx, ry, right.x, right.y);
	end

	left.x = lx; 
	left.y = ly;
	right.x = rx; 
	right.y = ry;
end

--[[
	Line Joins
--]]
function Path2D.bevelJoin(self, left, right, p0, p1, lineWidth)

	local w = lineWidth * 0.5;
	local dlx0 = p0.dy;
	local dly0 = -p0.dx;
	local dlx1 = p1.dy;
	local dly1 = -p1.dx;
	local lx0 = p1.x - (dlx0 * w);
	local ly0 = p1.y - (dly0 * w);
	local rx0 = p1.x + (dlx0 * w);
	local ry0 = p1.y + (dly0 * w);
	local lx1 = p1.x - (dlx1 * w);
	local ly1 = p1.y - (dly1 * w);
	local rx1 = p1.x + (dlx1 * w);
	local ry1 = p1.y + (dly1 * w);

	self:addEdge(lx0, ly0, left.x, left.y);
	self:addEdge(lx1, ly1, lx0, ly0);

	self:addEdge(right.x, right.y, rx0, ry0);
	self:addEdge(rx0, ry0, rx1, ry1);

	left.x = lx1; 
	left.y = ly1;
	right.x = rx1; 
	right.y = ry1;
end

function Path2D.miterJoin(self, left, right, p0, p1, lineWidth)

	local w = lineWidth * 0.5;
	local dlx0 = p0.dy;
	local dly0 = -p0.dx;
	local dlx1 = p1.dy;
	local dly1 = -p1.dx;
	local lx0, rx0, lx1, rx1 = 0,0,0,0;
	local ly0, ry0, ly1, ry1 = 0,0,0,0;

	if band(p1.flags, Path2D.SVGpointFlags.NSVG_PT_LEFT) ~= 0 then
		lx0 = p1.x - p1.dmx * w;
		lx1 = lx0;
		ly0 = p1.y - p1.dmy * w;
		ly1 = ly0;
		self:addEdge(lx1, ly1, left.x, left.y);

		rx0 = p1.x + (dlx0 * w);
		ry0 = p1.y + (dly0 * w);
		rx1 = p1.x + (dlx1 * w);
		ry1 = p1.y + (dly1 * w);
		self:addEdge(right.x, right.y, rx0, ry0);
		self:addEdge(rx0, ry0, rx1, ry1);
	else
		lx0 = p1.x - (dlx0 * w);
		ly0 = p1.y - (dly0 * w);
		lx1 = p1.x - (dlx1 * w);
		ly1 = p1.y - (dly1 * w);
		self:addEdge(lx0, ly0, left.x, left.y);
		self:addEdge(lx1, ly1, lx0, ly0);

		rx0 = p1.x + p1.dmx * w;
		rx1 = rx0;

		ry0 = p1.y + p1.dmy * w;
		ry1 = ry0;
		self:addEdge(right.x, right.y, rx1, ry1);
	end

	left.x = lx1; 
	left.y = ly1;
	right.x = rx1; 
	right.y = ry1;
end


function  Path2D.roundJoin(self, left, right, p0, p1, lineWidth, ncap)

	local w = lineWidth * 0.5;
	local dlx0 = p0.dy;
	local dly0 = -p0.dx;
	local dlx1 = p1.dy;
	local dly1 = -p1.dx;
	local a0 = atan2(dly0, dlx0);
	local a1 = atan2(dly1, dlx1);
	local da = a1 - a0;
	local lx, ly, rx, ry = 0,0,0,0;

	if (da < PI) then
		da = da + PI*2;
	end

	if (da > PI) then
		da = da - PI*2;
	end

	local n = ceil((abs(da) / PI) * ncap);
	if n < 2 then
		n = 2;
	end

	if n > ncap then
		n = ncap;
	end


	lx = left.x;
	ly = left.y;
	rx = right.x;
	ry = right.y;

	for i = 0, n-1 do
		local u = i/(n-1);
		local a = a0 + u*da;
		local ax = cos(a) * w;
		local ay = sin(a) * w;
		local lx1 = p1.x - ax;
		local ly1 = p1.y - ay;
		local rx1 = p1.x + ax;
		local ry1 = p1.y + ay;

		self:addEdge(lx1, ly1, lx, ly);
		self:addEdge(rx, ry, rx1, ry1);

		lx = lx1; 
		ly = ly1;
		rx = rx1; 
		ry = ry1;
	end

	left.x = lx; left.y = ly;
	right.x = rx; right.y = ry;
end


function Path2D.straightJoin(self, left, right, p1, lineWidth)

	local w = lineWidth * 0.5;
	local lx = p1.x - (p1.dmx * w);
	local ly = p1.y - (p1.dmy * w);
	local rx = p1.x + (p1.dmx * w);
	local ry = p1.y + (p1.dmy * w);

	self:addEdge(lx, ly, left.x, left.y);
	self:addEdge(right.x, right.y, rx, ry);

	left.x = lx; 
	left.y = ly;
	right.x = rx; 
	right.y = ry;
end



--[[
	Ancillary
--]]

function Path2D.expandStroke(self, NSVGpoint* points, npoints, closed, lineJoin, lineCap, lineWidth)

	local ncap = maths.curveDivs(lineWidth*0.5, PI, self.tessTol);	-- Calculate divisions per half circle.
	NSVGpoint left = {0,0,0,0,0,0,0,0}, 
	right = {0,0,0,0,0,0,0,0}, 
	firstLeft = {0,0,0,0,0,0,0,0}, 
	firstRight = {0,0,0,0,0,0,0,0};
	NSVGpoint* p0, *p1;
	int j, s, e;

	-- Build stroke edges
	if closed then
		-- Looping
		p0 = &points[npoints-1];
		p1 = &points[0];
		s = 0;
		e = npoints;
	else 
		-- Add cap
		p0 = &points[0];
		p1 = &points[1];
		s = 1;
		e = npoints-1;
	end

	if closed then
		initClosed(left, right, p0, p1, lineWidth);
		firstLeft = left;
		firstRight = right;
	else
		-- Add cap
		local dx = p1->x - p0->x;
		local dy = p1->y - p0->y;
		local _, dx, dy = maths.normalize(dx, dy);

		if (lineCap == NSVG_CAP_BUTT)
			nsvg__buttCap(r, &left, &right, p0, dx, dy, lineWidth, 0);
		else if (lineCap == NSVG_CAP_SQUARE)
			nsvg__squareCap(r, &left, &right, p0, dx, dy, lineWidth, 0);
		else if (lineCap == NSVG_CAP_ROUND)
			nsvg__roundCap(r, &left, &right, p0, dx, dy, lineWidth, ncap, 0);
	}

	for (j = s; j < e; ++j) {
		if (p1->flags & NSVG_PT_CORNER) {
			if (lineJoin == NSVG_JOIN_ROUND)
				nsvg__roundJoin(r, &left, &right, p0, p1, lineWidth, ncap);
			else if (lineJoin == NSVG_JOIN_BEVEL || (p1->flags & NSVG_PT_BEVEL))
				nsvg__bevelJoin(r, &left, &right, p0, p1, lineWidth);
			else
				nsvg__miterJoin(r, &left, &right, p0, p1, lineWidth);
		} else {
			nsvg__straightJoin(r, &left, &right, p1, lineWidth);
		}
		p0 = p1++;
	}

	if (closed) then
		-- Loop it
		nsvg__addEdge(r, firstLeft.x, firstLeft.y, left.x, left.y);
		nsvg__addEdge(r, right.x, right.y, firstRight.x, firstRight.y);
	else
		-- Add cap
		local dx = p1.x - p0.x;
		local dy = p1.y - p0.y;
		_, dx, dy = normalize(dx, dy);

		if (lineCap == NSVG_CAP_BUTT) then
			nsvg__buttCap(r, &right, &left, p1, -dx, -dy, lineWidth, 1);
		elseif (lineCap == NSVG_CAP_SQUARE) then
			nsvg__squareCap(r, &right, &left, p1, -dx, -dy, lineWidth, 1);
		elseif (lineCap == NSVG_CAP_ROUND) then
			nsvg__roundCap(r, &right, &left, p1, -dx, -dy, lineWidth, ncap, 1);
		end
	end
end

return Path2D

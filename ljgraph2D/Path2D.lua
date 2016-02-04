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
local pointEquals = maths.pointEquals;

local SVGTypes = require("ljgraph2D.SVGTypes")
local PointFlags = SVGTypes.PointFlags;
local LineJoin = SVGTypes.LineJoin;
local LineCap = SVGTypes.LineCap;


local int = ffi.typeof("int")


local function cmpEdge(a, b)

	--NSVGedge* a = (NSVGedge*)p;
	--NSVGedge* b = (NSVGedge*)q;

	if (a.y0 < b.y0) then
		return -1;
	end

	if (a.y0 > b.y0) then
		return  1;
	end

	return 0;
end


local Path2D = {}
setmetatable(Path2D, {
	__call = function(self, ...)
		return self:new(...);
	end,
})
local Path2D_mt = {
	__index = Path2D;
}

--[[
	float* pts;					// Cubic bezier points: x0,y0, [cpx1,cpx1,cpx2,cpy2,x1,y1], ...
	int npts;					// Total number of bezier points.
	char closed;				// Flag indicating if shapes should be treated as closed.
	float bounds[4];			// Tight bounding box of the shape [minx,miny,maxx,maxy].
	struct NSVGpath* next;		// Pointer to next path, or NULL if last element.
--]]

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

	if band(p1.flags, PointFlags.LEFT) ~= 0 then
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

function Path2D.expandStroke(self, points, npoints, closed, lineJoin, lineCap, lineWidth)

	local ncap = maths.curveDivs(lineWidth*0.5, PI, self.tessTol);	-- Calculate divisions per half circle.
	local left = SVGPoint({0,0,0,0,0,0,0,0}); 
	local right = SVGPoint({0,0,0,0,0,0,0,0});
	local firstLeft = SVGPoint({0,0,0,0,0,0,0,0}); 
	local firstRight = SVGPoint({0,0,0,0,0,0,0,0});
	local p0 = nil;
	local p1 = nil;
	local j, s, e = 0,0,0;

	-- Build stroke edges
	if closed then
		-- Looping
		p0 = points[#points];
		p1 = points[1];
		s = 0;
		e = #points;
	else 
		-- Add cap
		p0 = points[1];
		p1 = points[2];
		s = 1;
		e = #points;
	end

	if closed then
		initClosed(left, right, p0, p1, lineWidth);
		firstLeft = left;
		firstRight = right;
	else
		-- Add cap
		local dx = p1.x - p0.x;
		local dy = p1.y - p0.y;
		local _, dx, dy = maths.normalize(dx, dy);

		if lineCap == Path2D.LineCap.BUTT then
			self:buttCap(left, right, p0, dx, dy, lineWidth, 0);
		elseif lineCap == Path2D.LineCap.SQUARE then
			self:squareCap(left, right, p0, dx, dy, lineWidth, 0);
		elseif lineCap == Path2D.LineCap.ROUND then
			self:roundCap(left, right, p0, dx, dy, lineWidth, ncap, 0);
		end
	end

	for j = s, e-1 do
		if band(p1.flags, PointFlags.CORNER)~=0 then
			if lineJoin == LineJoin.ROUND then
				self:roundJoin(left, right, p0, p1, lineWidth, ncap);
			elseif (lineJoin == LineJoin.BEVEL) or (band(p1.flags, PointFlags.BEVEL)~=0) then
				self:bevelJoin(left, right, p0, p1, lineWidth);
			else
				self:miterJoin(left, right, p0, p1, lineWidth);
			end
		else 
			self:straightJoin(left, right, p1, lineWidth);
		end
		p0 = p1 + 1;
	end

	if closed then
		-- Loop it
		self:addEdge(firstLeft.x, firstLeft.y, left.x, left.y);
		self:addEdge(right.x, right.y, firstRight.x, firstRight.y);
	else
		-- Add cap
		local dx = p1.x - p0.x;
		local dy = p1.y - p0.y;
		_, dx, dy = normalize(dx, dy);

		if (lineCap == LineCap.BUTT) then
			self:buttCap(right, left, p1, -dx, -dy, lineWidth, 1);
		elseif (lineCap == LineCap.SQUARE) then
			self:squareCap(right, left, p1, -dx, -dy, lineWidth, 1);
		elseif (lineCap == LineCap.ROUND) then
			self:roundCap(right, left, p1, -dx, -dy, lineWidth, ncap, 1);
		end
	end
end

function Path2D.prepareStroke(miterLimit, lineJoin)
	local p0idx = #self.points;
	local p1idx = 1;
	local p0 = nil;
	local p1 = nil;

	for i = 1, #self.points do
		p0 = self.points[p0idx];
		p1 = self.points[p1idx];
		
		-- Calculate segment direction and length
		p0.dx = p1.x - p0.x;
		p0.dy = p1.y - p0.y;
		p0.len, p0.dx, p0.dy = normalize(p0.dx, p0.dy);
		
		-- Advance
		p0idx = p1idx;
		p1idx = p1idx + 1;
	end

	-- calculate joins
	p0idx = #self.points;
	p1idx = 1;

	for j = 1, #self.points do
		p0 = self.points[p0idx];
		p1 = self.points[p1idx];

		local dlx0 = p0.dy;
		local dly0 = -p0.dx;
		local dlx1 = p1.dy;
		local dly1 = -p1.dx;
		
		-- Calculate extrusions
		p1.dmx = (dlx0 + dlx1) * 0.5;
		p1.dmy = (dly0 + dly1) * 0.5;
		local dmr2 = p1.dmx*p1.dmx + p1.dmy*p1.dmy;
		
		if dmr2 > 0.000001 then
			local s2 = 1.0 / dmr2;
			if s2 > 600.0 then
				s2 = 600.0;
			end
			p1.dmx = p1.dmx * s2;
			p1.dmy = p1.dmy * s2;
		end

		-- Clear flags, but keep the corner.
		if band(p1.flags, PointFlags.CORNER) ~= 0 then
			p1.flags = PointFlags.CORNER
		else
			p1.flags = 0;
		end

		-- Keep track of left turns.
		local cross = p1.dx * p0.dy - p0.dx * p1.dy;
		if cross > 0.0 then
			p1.flags = bor(p1.flags,PointFlags.LEFT);
		end

		-- Check to see if the corner needs to be beveled.
		if band(p1.flags, PointFlags.CORNER)~= 0 then
			if ((dmr2 * miterLimit*miterLimit) < 1.0 or lineJoin == LineJoin.BEVEL or lineJoin == LineJoin.ROUND) then
				p1.flags = bor(p1.flags,PointFlags.BEVEL);
			end
		end


		-- Advance
		--p0 = p1++;
		p0idx = p1idx;
		p1idx = p1idx + 1;
	end
end


return Path2D

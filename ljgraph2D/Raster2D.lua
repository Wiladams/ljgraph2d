--[[
	References
	
	http://www.sunshine2k.de/coding/java/TriangleRasterization/TriangleRasterization.html

--]]

local ffi = require("ffi")
local bit = require("bit")
local rshift = bit.rshift

local abs = math.abs;
local floor = math.floor;

local maths = require("ljgraph2D.maths")
local sgn = maths.sgn;
local round = maths.round;

local Surface = require("ljgraph2D.Surface")
local DrawingContext = require("ljgraph2D.DrawingContext")
local SVGTypes = require("ljgraph2D.SVGTypes")


local int16_t = tonumber;
local int32_t = tonumber;
local uint32_t = tonumber;
local int = tonumber;


local APolyDda = {}
setmetatable(APolyDda, {
	__call = function(self, ...)
		return self:new(...);
	end,
})

local APolyDda_mt = {
	__index = APolyDda;
}

function APolyDda.init(self, pVerts, numVerts, ivert, dir)
	local obj = {
		vertIndex = 0;
		vertNext = 0;
		numVerts = numVerts;
		x = 0;
		dx = 0;
		ybeg = 0;
		yend = 0;
	};

	setmetatable(obj, APolyDda_mt);

	return obj;
end

function APolyDda.new(self, pVerts, numVerts, ivert, dir)
	return self:init(pVerts, numVerts, ivert, dir);
end


function APolyDda.setupPolyDda(self, pVerts, ivert, dir)
	local numVerts = #pVerts;
	self.vertIndex = ivert;
	self.vertNext = ivert + dir;
	self.numVerts = numVerts;

	if (self.vertNext < 1) then
		self.vertNext = self.numVerts;	
	elseif (self.vertNext == self.numVerts+1) then
		self.vertNext = 1;
	end

	-- set starting/ending ypos and current xpos
	self.ybeg = self.yend;
	self.yend = round(pVerts[self.vertNext][2]);
	self.x = pVerts[self.vertIndex][1];

	-- Calculate fractional number of pixels to step in x (dx)
	local xdelta = pVerts[self.vertNext][1] - pVerts[self.vertIndex][1];
	local ydelta = self.yend - self.ybeg;
	if (ydelta > 0) then
		self.dx = xdelta / ydelta;
	else 
		self.dx = 0;
	end
end


--[[
	Some useful utility routines
--]]
-- given two points, return them in order
-- where the 'y' value is the lowest first
local function order2(pt1, pt2)
	if pt1.y < pt2.y then
		return pt1, pt2;
	end

	return pt2, pt1;
end

-- given three points, reorder them from lowest
-- y value to highest.  Good for drawing triangles
local function order3(a, b, c)
	local a1,b1 = order2(a,b)
	local b1,c = order2(b1,c)
	local a, b = order2(a1, b1)

	return a, b, c
end

-- given a table of vertices for a polygon,
-- return a number which represents the index of the 
-- vertex with the smallest 'y' value, and is thus the topmost vertex
local function findTopmostVertex(verts, numVerts)
	numVerts = numVerts or #verts;

	local ymin = math.huge;
	local vmin = 1;

	for idx=1, numVerts do
		if verts[idx][2] < ymin then
			ymin = verts[idx][2];
			vmin = idx;
		end
	end
	
	return vmin;
end



--[[
	DrawingContext

	Represents the API for doing drawing.  This is a retained interface,
	so it will maintain a current drawing color and various other 
	attributes.
--]]
local Raster2D = {}
setmetatable(Raster2D, {
	__call = function(self, ...)
		return self:new(...)
	end,
})
local Raster2D_mt = {
	__index = Raster2D;
}



function Raster2D.init(self, width, height, data)
	--rowsize = GetAlignedByteCount(width, bitcount, alignment);
    --pixelarraysize = rowsize * math.abs(height);
    local surf = Surface(width, height, data);

	local obj = {
		surface = surf;
		Context = DrawingContext(width, height);
		width = width;
		height = height;
		--bitcount = bitcount;
		--data = data;

		rowsize = rowsize;
		pixelarraysize = pixelarraysize;

		SpanBuffer = ffi.new("int32_t[?]", width);

		tessTol = 0.25;
		distTol = 0.01;

		-- set of points defining current path
		px = 0;		-- Current cursor location
		py = 0;		

		edges = {};
		points = {};

	}
	setmetatable(obj, DrawingContext_mt)

	return obj;
end

function Raster2D.new(self, width, height, data)
	data = data or ffi.new("int32_t[?]", width*height)
	return self:init(width, height, data)
end


--[[
	Path Management
--]]
function  Raster2D.addPathPoint(self, float x, float y, int flags)

	-- If the point is the same as the last point in our
	-- current set of points, then just set a flag on that
	-- point, and don't add a new point
	-- this might be true when your duplicating a point
	-- a number of times for a curve
	if #self.points > 0 then
		local pt = self.points[#self.points];
		if maths.pointsEquals(pt.x,pt.y, x,y, self.distTol) then
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

function Raster2D.appendPathPoint(self, pt)
	table.insert(self.points, pt)
end


function Raster2D.addEdge(self, x0, y0, x1, y1)

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

--[[
	Drawing Routines
--]]
function Raster2D.flattenCubicBez(self,
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


function Raster2D.clearAll(self)
	self.surface:clearAll();
end

function Raster2D.clearToWhite(self)
	self.surface:clearToWhite();
end

-- Fill a convex polygon with counter clockwise winding
-- This implementation is not good, and only holds a 
-- temporary spot
-- We need a version that can render more complex
-- polygons, including non-simple
function  Raster2D.fillPolygon(self, verts, color)
	--const pb_rect &clipRect,
	local nverts = #verts;

	-- find topmost vertex of the polygon
	local vmin = findTopmostVertex(verts, nverts);

	-- set starting line
	local ldda = APolyDda();
	local rdda = APolyDda();

	local y = int(verts[vmin][1]);
	ldda.yend = y;
	rdda.yend = y;

	-- setup polygon scanner for left side, starting from top
	ldda:setupPolyDda(verts, vmin, 1);

	-- setup polygon scanner for right side, starting from top
	rdda:setupPolyDda(verts, vmin, -1);

	while (true) do
		if (y >= ldda.yend) then
			if (y >= rdda.yend) then
				if (ldda.vertNext == rdda.vertNext)	then -- if same vertex, then done
					break;
				end

				local vnext = rdda.vertNext - 1;

				if (vnext < 1) then
					vnext = nverts;
				end

				if (vnext == ldda.vertNext) then
					break;
				end
			end
			ldda:setupPolyDda(verts, ldda.vertNext, 1);	-- reset left side
		end

		-- check for right dda hitting end of polygon side
		-- if so, reset scanner
		if (y >= rdda.yend) then
			rdda:setupPolyDda(verts, rdda.vertNext, -1);
		end

		-- fill span between two line-drawers, advance drawers when
		-- hit vertices
		--if (y >= clipRect.y) then
			print("hline: ", ldda.x, y, rdda.x, round(rdda.x) - round(ldda.x))
			self:hline(round(ldda.x), y, round(rdda.x) - round(ldda.x), color);
		--end

		ldda.x = ldda.x + ldda.dx;
		rdda.x = rdda.x + rdda.dx;

		-- Advance y position.  Exit if run off its bottom
		y = y + 1;
		--[[
		if (y >= clipRect.y + clipRect.height) then
			break;
		end
		--]]
	end
end


-- Rectangle drawing
function Raster2D.fillRect(self, x, y, width, height, value)
	local length = width;

	-- fill the span buffer with the specified
	while length > 0 do
		self.SpanBuffer[length-1] = value;
		length = length-1;
	end

	-- use hspan, since we're doing a srccopy, not an 'over'
	while height > 0 do
		self:hspan(x, y+height-1, width, self.SpanBuffer)
		height = height - 1;
	end
end

function Raster2D.frameRect(self, x, y, width, height, value)
	-- two horizontals
	self:hline(x, y, width, value);
	self:hline(x, y+height-1, width, value);

	-- two verticals
	self:vline(x, y, height, value);
	self:vline(x+width-1, y, height, value);
end

-- Text Drawing
function Raster2D.fillText(self, x, y, text, font, value)
	font:scan_str(self.surface, x, y, text, value)
end


--[[
	Filling a triangle is a specialization of filling a convex
	polygon.  Since we break polygons down into triangles, we
	implement the fillTriangle as the base, rather than implementing
	the triangle as a polygon.
--]]
function Raster2D.fillTriangle(self, x1, y1, x2, y2, x3, y3, color)

	-- sort vertices, such that a == y with lowest number (top)
	local pt1, pt2, pt3 = order3({x=x1,y=y1}, {x=x2,y=y2}, {x=x3,y=y3})


	local a, b, y, last = 0,0,0,0;

	-- Handle the case where points are colinear (all on same line)
	-- could calculate distance of second point to the line formed
	-- from points 1 and 3
	if (pt1.y == pt3.y) then 
		a = pt1.x;
		b = pt1.x;

		if (pt2.x < a)  then 
			a = pt2.x;
		elseif (pt2.x > b) then 
			b = pt2.x;
		end

		if (pt3.x < a) then 
			a = pt3.x;
		elseif (pt3.x > b) then 
			b = pt3.x;
		end

		self.surface:hline(a, pt1.y, b - a + 1, color);

		return;
	end


	local dx01 = int16_t(pt2.x - pt1.x);
	local dy01 = int16_t(pt2.y - pt1.y);
	local dx02 = int16_t(pt3.x - pt1.x);
	local dy02 = int16_t(pt3.y - pt1.y);
	local dx12 = int16_t(pt3.x - pt2.x);
	local dy12 = int16_t(pt3.y - pt2.y);
	
	local sa = int32_t(0);
	local sb = int32_t(0);

	-- For upper part of triangle, find scanline crossings for segments
	-- 0-1 and 0-2. If y1=y2 (flat-bottomed triangle), the scanline y1
	-- is included here (and second loop will be skipped, avoiding a /0
	-- error there), otherwise scanline y1 is skipped here and handled
	-- in the second loop...which also avoids a /0 error here if y0=y1
	-- (flat-topped triangle).
	if (pt2.y == pt3.y) then 
		last = pt2.y; -- Include y1 scanline
	else 
		last = pt2.y - 1; -- Skip it
	end
	
	y = pt1.y;
	while y <= last do 
		a = pt1.x + sa / dy01;
		b = pt1.x + sb / dy02;
		sa = sa + dx01;
		sb = sb + dx02;
		--[[ longhand:
		a = x0 + (x1 - x0) * (y - y0) / (y1 - y0);
		b = x0 + (x2 - x0) * (y - y0) / (y2 - y0);
		--]]
		
		if (a > b) then
			a, b = b, a;
		end

		self.surface:hline(a, y, b - a + 1, color);
		y = y + 1;
	end


	-- For lower part of triangle, find scanline crossings for segments
	-- 0-2 and 1-2. This loop is skipped if y1=y2.
	sa = dx12 * (y - pt2.y);
	sb = dx02 * (y - pt1.y);
	while y < pt3.y do 

		a = pt2.x + sa / dy12;
		b = pt1.x + sb / dy02;
		sa = sa + dx12;
		sb = sb + dx02;
		--[[ longhand:
		a = x1 + (x2 - x1) * (y - y1) / (y2 - y1);
		b = x0 + (x2 - x0) * (y - y0) / (y2 - y0);
		--]]
		if (a > b) then 
			a, b = b, a;
		end

		self.surface:hline(a, y, b - a + 1, color);

		y = y + 1;
	end
end

function Raster2D.frameTriangle(self, x1, y1, x2, y2, x3, y3, color)

	-- sort vertices, such that a == y with lowest number (top)
	local pt1, pt2, pt3 = order3({x=x1,y=y1}, {x=x2,y=y2}, {x=x3,y=y3})

	self:line(pt1.x, pt1.y, pt2.x, pt2.y, color);
	self:line(pt2.x, pt2.y, pt3.x, pt3.y, color);
	self:line(pt3.x, pt3.y, pt1.x, pt1.y, color);
end










-- Line Drawing

-- Bresenham line drawing
function Raster2D.line(self, x1, y1, x2, y2, value)
	x1 = floor(x1);
	y1 = floor(y1);
	x2 = floor(x2);
	y2 = floor(y2);

	local dx = x2 - x1;      -- the horizontal distance of the line
	local dy = y2 - y1;      -- the vertical distance of the line
	local dxabs = abs(dx);
	local dyabs = abs(dy);
	local sdx = sgn(dx);
	local sdy = sgn(dy);
	local x = rshift(dyabs, 1);
	local y = rshift(dxabs, 1);
	local px = x1;
	local py = y1;

	self.surface:pixel(x1, y1, value);

	if (dxabs >= dyabs) then -- the line is more horizontal than vertical
		for i = 0, dxabs-1 do
			y = y+dyabs;
			if (y >= dxabs) then
				y = y - dxabs;
				py = py + sdy;
			end
			px = px + sdx;
			self.surface:pixel(px, py, value);
		end
	else -- the line is more vertical than horizontal
		for i = 0, dyabs-1 do
			x = x + dxabs;
			if (x >= dyabs) then
				x = x - dyabs;
				px = px + sdx;
			end

			py = py + sdy;
			self.surface:pixel( px, py, value);
		end
	end
end

function Raster2D.setPixel(self, x, y, value)
	self.surface:pixel(x, y, value)
end

-- Optimized vertical lines
function Raster2D.vline(self, x, y, length, value)
	self.surface:vline(x, y, length, value);
end

function Raster2D.hline(self, x, y, length, value)
	self.surface:hline(x, y, length, value);
end

function Raster2D.hspan(self, x, y, length, span)
	self.surface:hspan(x, y, length, span)
end


return Raster2D
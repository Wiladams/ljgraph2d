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

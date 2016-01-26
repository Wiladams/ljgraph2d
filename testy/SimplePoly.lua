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

local SimplePoly = {}
setmetatable(SimplePoly, {
	__call = function(self, ...)
		return self:new(...)
	end,
})
local SimplePoly_mt = {
	__index = SimplePoly;
}

function SimplePoly.init(self, verts, color)
	if not verts then return end
	color = color or 0;

	local nverts = #verts;
	local vmin = findTopmostVertex(verts, nverts);

	local obj = {
		verts = verts;
		color = color;
		vmin = vmin;
	}
	setmetatable(obj, SimplePoly_mt);

	return obj
end

function SimplePoly.new(self, verts, color)
	if not verts then return nil end

	return self:init(verts, color);
end

-- Fill a convex polygon with counter clockwise winding
function  SimplePoly.draw(self, rasterizer)

	-- set starting line
	local ldda = APolyDda();
	local rdda = APolyDda();

	local y = int(verts[self.vmin][1]);
	ldda.yend = y;
	rdda.yend = y;

	-- setup polygon scanner for left side, starting from top
	ldda:setupPolyDda(self.verts, self.vmin, 1);

	-- setup polygon scanner for right side, starting from top
	rdda:setupPolyDda(self.verts, self.vmin, -1);

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
			ldda:setupPolyDda(self.verts, ldda.vertNext, 1);	-- reset left side
		end

		-- check for right dda hitting end of polygon side
		-- if so, reset scanner
		if (y >= rdda.yend) then
			rdda:setupPolyDda(self.verts, rdda.vertNext, -1);
		end

		-- fill span between two line-drawers, advance drawers when
		-- hit vertices
		--if (y >= clipRect.y) then
			--print("hline: ", ldda.x, y, rdda.x, round(rdda.x) - round(ldda.x))
			rasterizer:hline(round(ldda.x), y, round(rdda.x) - round(ldda.x), self.color);
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


return SimplePoly

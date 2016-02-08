--[[
	References
	
	http://www.sunshine2k.de/coding/java/TriangleRasterization/TriangleRasterization.html

--]]

local ffi = require("ffi")
local bit = require("bit")
local rshift, lshift = bit.rshift, bit.lshift;
local bor, band = bit.bor, bit.band

local abs = math.abs;
local floor = math.floor;

local maths = require("ljgraph2D.maths")
local sgn = maths.sgn;
local round = maths.round;
local clamp = maths.clamp;
local pointEquals = maths.pointEquals;


local colors = require("ljgraph2D.colors")
local Surface = require("ljgraph2D.Surface")
local DrawingContext = require("ljgraph2D.DrawingContext")
local sort = require("ljgraph2D.sort")
local qsort = sort.qsort;

local SVGTypes = require("ljgraph2D.SVGTypes")
local PaintType = SVGTypes.PaintType;
local FillRule = SVGTypes.FillRule;
local Flags = SVGTypes.Flags;
local initPaint = SVGTypes.initPaint;
local LineCap = SVGTypes.LineCap;
local LineJoin = SVGTypes.LineJoin;
local SVGCachedPaint = SVGTypes.SVGCachedPaint;
local SVGGradientStop = SVGTypes.SVGGradientStop;
local SVGGradient = SVGTypes.SVGGradient;
local SVGPaint = SVGTypes.SVGPaint;
local SVGPoint = SVGTypes.SVGPoint;


local int16_t = tonumber;
local int32_t = tonumber;
local uint32_t = tonumber;
local int = tonumber;

local SVG__SUBSAMPLES	= 5;
local SVG__FIXSHIFT		= 10;
local SVG__FIX			= lshift(1, SVG__FIXSHIFT);
local SVG__FIXMASK		= (SVG__FIX-1);
local SVG__MEMPAGE_SIZE	= 1024;


local function fillScanline(scanline, len, x0, x1, maxWeight, xmin, xmax)

	local i = rshift(x0, SVG__FIXSHIFT);
	local j = rshift(x1, SVG__FIXSHIFT);
	
	if (i < xmin) then
		xmin = i;
	end

	if (j > xmax) then
		xmax = j;
	end

	if (i < len and j >= 0) then
		if i == j then
			-- x0,x1 are the same pixel, so compute combined coverage
			scanline[i] = scanline[i] + rshift((x1 - x0) * maxWeight, SVG__FIXSHIFT);
		else
			if i >= 0 then-- add antialiasing for x0
				scanline[i] = scanline[i] + rshift(((SVG__FIX - band(x0, SVG__FIXMASK)) * maxWeight), SVG__FIXSHIFT);
			else
				i = -1; -- clip
			end

			if (j < len) then -- add antialiasing for x1
				scanline[j] = scanline[j] + rshift((band(x1, SVG__FIXMASK) * maxWeight), SVG__FIXSHIFT);
			else
				j = len; -- clip
			end

			--for (++i; i < j; ++i) do -- fill pixels between x0 and x1
			i = i + 1;
			while (i < j) do
				scanline[i] = scanline[i] + maxWeight;
				i = i + 1;
			end
		end
	end

	return xmin, xmax;
end

-- note: this routine clips fills that extend off the edges... ideally this
-- wouldn't happen, but it could happen if the truetype glyph bounding boxes
-- are wrong, or if the user supplies a too-small bitmap
local function fillActiveEdges(scanline, len, edges, maxWeight, xmin, xmax, fillRule)
	-- non-zero winding fill
	local x0, w  = 0, 0;

	if fillRule == FillRule.NONZERO then
		-- Non-zero
		for _, e in ipairs(edges) do
			if w == 0 then
				-- if we're currently at zero, we need to record the edge start point
				x0 = e.x; 
				w = w + e.dir;
			else
				local x1 = e.x; 
				w = w + e.dir;

				-- if we went to zero, we need to draw
				if w == 0 then
					xmin, xmax = fillScanline(scanline, len, x0, x1, maxWeight, xmin, xmax);
				end
			end
		end
	elseif (fillRule == FillRule.EVENODD) then
		-- Even-odd
		--while (e ~= NULL) do
		for _, e in ipairs(edges) do
			if (w == 0) then
				-- if we're currently at zero, we need to record the edge start point
				x0 = e.x; 
				w = 1;
			else
				local x1 = e.x; 
				w = 0;
				fillScanline(scanline, len, x0, x1, maxWeight, xmin, xmax);
			end
		end
	end

	return xmin, xmax;
end


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
    local surf = Surface(width, height, data);

	local obj = {
		surface = surf;
		Context = DrawingContext(width, height);
		width = width;
		height = height;

		StrokeColor = colors.black;
		FillColor = colors.white;

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
		npoints = 0;

		scanline = ffi.new("uint8_t[?]", width)
	}
	setmetatable(obj, Raster2D_mt)

	return obj;
end

function Raster2D.new(self, width, height, data)
	data = data or ffi.new("int32_t[?]", width*height)
	return self:init(width, height, data)
end

function Raster2D.clearAll(self)
	self.surface:clearAll();
end

function Raster2D.clearToWhite(self)
	self.surface:clearToWhite();
end

-- Drawing Style
function Raster2D.strokeColor(self, value)
	if value then
		self.StrokeColor = value;
		return self;
	end

	return self.StrokeColor;
end

function Raster2D.fillColor(self, value)
	if value then 
		self.FillColor = value;
		return self;
	end

	return self.FillColor;
end




function  Raster2D.addPathPoint(self, x, y, flags)
	--print(".addPathPoint: ", x, y)

	-- If the point is the same as the last point in our
	-- current set of points, then just set a flag on that
	-- point, and don't add a new point
	-- this might be true when your duplicating a point
	-- a number of times for a curve
	if #self.points > 0 then
		local pt = self.points[#self.points];
		if pointEquals(pt.x,pt.y, x,y, self.distTol) then
			pt.flags = bor(pt.flags, flags);
			return;
		end
	end

	local pt = SVGPoint()
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
	print(".addEdge: ", x0, y0, x1, y1)
	
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

function Raster2D.flattenCubicBez(self,
								   x1,  y1,  x2,  y2,
								   x3,  y3,  x4,  y4,
								  level, atype)

print(".flattenCubicBez: ", x1, y1, x2, y2, x3, y3, x4, y4)

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
		self:addPathPoint(x4, y4, atype);
		return;
	end

	local x234 = (x23+x34)*0.5;
	local y234 = (y23+y34)*0.5;
	local x1234 = (x123+x234)*0.5;
	local y1234 = (y123+y234)*0.5;

	self:flattenCubicBez(x1,y1, x12,y12, x123,y123, x1234,y1234, level+1, 0);
	self:flattenCubicBez(x1234,y1234, x234,y234, x34,y34, x4,y4, level+1, atype);
end


function Raster2D.flattenShape(self, shape, scale)

	for _, path in ipairs(shape.paths) do
		self.npoints = 0;
		
		-- Flatten path
		self:addPathPoint(path.pts[1].x*scale, path.pts[1].y*scale, 0);
		for i = 1, #path.pts-1,  3 do
			self:flattenCubicBez(path.pts[i].x*scale,path.pts[i].y*scale, 
				path.pts[i+1].x*scale,path.pts[i+1].y*scale, 
				path.pts[i+2].x*scale,path.pts[i+2].y*scale, 
				path.pts[i+3].x*scale,path.pts[i+3].y*scale, 
				0, 0);
		end

		-- Close path
		self:addPathPoint(path.pts[1].x*scale, path.pts[1].y*scale, 0);

		-- Build edges
		local i = 1;
		local j = #self.points
		while ( i < #self.points) do
			self:addEdge(self.points[j].x, self.points[j].y, self.points[i].x, self.points[i].y);
			j = i;
			i = i + 1;
		end
	end
end


function Raster2D.rasterizeSortedEdges(self, tx, ty, scale, cache, fillRule)

	--NSVGactiveEdge *active = NULL;
	--int y, s;
	local e = 0;
	local maxWeight = (255 / SVG__SUBSAMPLES);  -- weight per vertical scanline

	for y = 0, self.height-2  do

		ffi.fill(self.scanline, 0, self.width);
		local xmin = self.width;
		local xmax = 0;
--[[
		for s = 0, SVG__SUBSAMPLES-1 do
			-- find center of pixel for this scanline
			local scany = y*SVG__SUBSAMPLES + s + 0.5;
			NSVGactiveEdge **step = &active;

			-- update all active edges;
			-- remove all active edges that terminate before the center of this scanline
			while (*step) do
				NSVGactiveEdge *z = *step;
				if (z->ey <= scany) {
					*step = z->next; // delete from list
					freeActive(r, z);
				else
					z->x += z->dx; // advance to position for current scanline
					step = &((*step)->next); // advance through list
				end
			end

			-- resort the list if needed
			while (true) do
				local changed = false;
				step = &active;
				while (*step and (*step)->next) do
					if ((*step).x > (*step).next.x) then
						NSVGactiveEdge* t = *step;
						NSVGactiveEdge* q = t.next;
						t.next = q.next;
						q.next = t;
						*step = q;
						changed = true;
					end
					step = &(*step)->next;
				end
				
				if changed then
					break;
				end
			end

			-- insert all edges that start before the center of this scanline -- omit ones that also end on this scanline
			while (e < r->nedges && r->edges[e].y0 <= scany) do
				if (r->edges[e].y1 > scany) then
					NSVGactiveEdge* z = nsvg__addActive(r, &r->edges[e], scany);
					if (z == NULL) then
						break;
					end

					-- find insertion point
					if (active == NULL) then
						active = z;
					elseif (z->x < active->x) then
						-- insert at front
						z->next = active;
						active = z;
					else
						-- find thing to insert AFTER
						NSVGactiveEdge* p = active;
						while (p->next && p->next->x < z->x) do
							p = p->next;
						end

						-- at this point, p->next->x is NOT < z->x
						z->next = p->next;
						p->next = z;
					end
				end
				e++;
			end

			-- now process all active edges in non-zero fashion
			if (active ~= nil) then
				xmin, xmax = fillActiveEdges(self.scanline, self.width, active, maxWeight, xmin, xmax, fillRule);
			end
		end

		-- Blit
		if (xmin < 0) then
			xmin = 0;
		end
		
		if (xmax > self.width-1) then
			xmax = self.width-1;
		end

		if (xmin <= xmax) then
			--self.surf:scanlineSolid(&r->bitmap[y * r->stride] + xmin*4, xmax-xmin+1, &r->scanline[xmin], xmin, y, tx,ty, scale, cache);
		end
--]]
	end

end

local function cmpEdge(a, b)
	if (a.y0 < b.y0) then
		return -1;
	end

	if (a.y0 > b.y0) then
		return  1;
	end

	return 0;
end


function Raster2D.drawImage(self, image, tx, ty, scale)
print(".drawImage: ", image, image.shapes, #image.shapes)
--				   unsigned char* dst, int w, int h, int stride)

	--NSVGshape *shape = NULL;
	--NSVGedge *e = NULL;
	local cache = SVGCachedPaint();
	--int i;

	--r->bitmap = dst;
	--r->width = w;
	--r->height = h;
	--r->stride = stride;
--[[
	if (w > r->cscanline) {
		r->cscanline = w;
		r->scanline = (unsigned char*)realloc(r->scanline, w);
		if (r->scanline == NULL) return;
	}
--]]
	--for (i = 0; i < h; i++)
	--	memset(&dst[i*stride], 0, w*4);

	for _, shape in ipairs(image.shapes) do
		--if (band(shape.flags, Flags.VISIBLE) == 0)
		--	continue;

--print(".drawImage, shape.fill.type: ", shape.fill.type)
		if shape.fill.type ~= PaintType.NONE then
			--self:resetPool();
			self.freelist = {};

			self:flattenShape(shape, scale);

			-- Scale and translate edges
			for i, e in ipairs(self.edges) do
				e.x0 = tx + e.x0;
				e.y0 = (ty + e.y0) * SVG__SUBSAMPLES;
				e.x1 = tx + e.x1;
				e.y1 = (ty + e.y1) * SVG__SUBSAMPLES;

				-- BUGBUG - just to see something
				--self.surface:line(e.x0, e.y0, e.x1, e.y1, shape.fill.color)
			end

			-- Rasterize edges
			qsort(self.edges,1,#self.edges,cmpEdge)
			--qsort(r->edges, r->nedges, sizeof(NSVGedge), nsvg__cmpEdge);

			-- now, traverse the scanlines and find the intersections on each scanline, use non-zero rule
			cache, shape.fill = initPaint(cache, shape.fill, shape.opacity);

			self:rasterizeSortedEdges(tx,ty,scale, cache, shape.fillRule);
		end

--[[
		if (shape->stroke.type != NSVG_PAINT_NONE && (shape->strokeWidth * scale) > 0.01f) {
			nsvg__resetPool(r);
			r->freelist = NULL;
			r->nedges = 0;

			nsvg__flattenShapeStroke(r, shape, scale);

//			dumpEdges(r, "edge.svg");

			// Scale and translate edges
			for (i = 0; i < r->nedges; i++) {
				e = &r->edges[i];
				e->x0 = tx + e->x0;
				e->y0 = (ty + e->y0) * NSVG__SUBSAMPLES;
				e->x1 = tx + e->x1;
				e->y1 = (ty + e->y1) * NSVG__SUBSAMPLES;
			}

			// Rasterize edges
			qsort(r->edges, r->nedges, sizeof(NSVGedge), nsvg__cmpEdge);

			// now, traverse the scanlines and find the intersections on each scanline, use non-zero rule
			nsvg__initPaint(&cache, &shape->stroke, shape->opacity);

			nsvg__rasterizeSortedEdges(r, tx,ty,scale, &cache, NSVG_FILLRULE_NONZERO);
		}
--]]
	end

	--nsvg__unpremultiplyAlpha(dst, w, h, stride);

	--r->bitmap = NULL;
	--r->width = 0;
	--r->height = 0;
	--r->stride = 0;
end


return Raster2D

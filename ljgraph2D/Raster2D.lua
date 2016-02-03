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

local colors = require("ljgraph2D.colors")
local Surface = require("ljgraph2D.Surface")
local DrawingContext = require("ljgraph2D.DrawingContext")
local SVGTypes = require("ljgraph2D.SVGTypes")


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

	if fillRule == SVGTypes.FillRule.NONZERO then
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
	elseif (fillRule == NSVG_FILLRULE_EVENODD) then
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

		--tessTol = 0.25;
		--distTol = 0.01;

		-- set of points defining current path
		px = 0;		-- Current cursor location
		py = 0;		

		--edges = {};
		--points = {};

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

-- Rectangle drawing
function Raster2D.fillRect(self, x, y, width, height, value)
	value = value or self.FillColor;
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
	value = value or self.StrokeColor;
	-- two horizontals
	self:hline(x, y, width, value);
	self:hline(x, y+height-1, width, value);

	-- two verticals
	self:vline(x, y, height, value);
	self:vline(x+width-1, y, height, value);
end

-- Text Drawing
function Raster2D.fillText(self, x, y, text, font, value)
	value = value or self.FillColor;
	font:scan_str(rself.surface, x, y, text, value)
end


-- Line Drawing


-- Line Clipping in preparation for line drawing
local LN_INSIDE = 0; -- 0000
local LN_LEFT = 1;   -- 0001
local LN_RIGHT = 2;  -- 0010
local LN_BOTTOM = 4; -- 0100
local LN_TOP = 8;    -- 1000

-- Compute the bit code for a point (x, y) using the clip rectangle
-- bounded diagonally by (xmin, ymin), and (xmax, ymax)

local function ComputeOutCode(xmin, ymin, xmax, ymax, x, y)

	--double xmin = rct.x;
	--double xmax = rct.x + rct.width - 1;
	--double ymin = rct.y;
	--double ymax = rct.y + rct.height - 1;

	local code = LN_INSIDE;          -- initialised as being inside of clip window

	if (x < xmin) then           -- to the left of clip window
		code = bor(code, LN_LEFT);
	elseif x > xmax then      -- to the right of clip window
		code = bor(code, LN_RIGHT);
	end

	if y < ymin then           -- below the clip window
		code = bor(code, LN_BOTTOM);
	elseif y > ymax then     -- above the clip window
		code = bor(code, LN_TOP);
	end

	return code;
end

-- Cohen–Sutherland clipping algorithm clips a line from
-- P0 = (x0, y0) to P1 = (x1, y1) against a rectangle with 
-- diagonal from (xmin, ymin) to (xmax, ymax).
local function  clipLine(xmin, ymin, xmax, ymax, x0, y0, x1, y1)
	--double xmin = bounds.x;
	--double xmax = bounds.x + bounds.width - 1;
	--double ymin = bounds.y;
	--double ymax = bounds.y + bounds.height - 1;

	-- compute outcodes for P0, P1, and whatever point lies outside the clip rectangle
	local outcode0 = ComputeOutCode(xmin, ymin, xmax, ymax, x0, y0);
	local outcode1 = ComputeOutCode(xmin, ymin, xmax, ymax, x1, y1);

	local accept = false;

	while true do
		if (bor(outcode0, outcode1) == 0) then -- Bitwise OR is 0. Trivially accept and get out of loop
			accept = true;
			break;
		elseif band(outcode0, outcode1) ~= 0 then -- Bitwise AND is not 0. Trivially reject and get out of loop
			break;
		else
			-- failed both tests, so calculate the line segment to clip
			-- from an outside point to an intersection with clip edge
			local x = 0;
			local y = 0;

			-- At least one endpoint is outside the clip rectangle; pick it.
			local outcodeOut = outcode0;
			if outcodeOut == 0 then
				outcodeOut = outcode1;
			end

			-- Now find the intersection point;
			-- use formulas y = y0 + slope * (x - x0), x = x0 + (1 / slope) * (y - y0)
			if band(outcodeOut, LN_TOP) ~= 0 then            -- point is above the clip rectangle
				x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0);
				y = ymax;
			
			elseif band(outcodeOut, LN_BOTTOM) ~= 0 then -- point is below the clip rectangle
				x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0);
				y = ymin;
			
			elseif band(outcodeOut, LN_RIGHT) ~= 0 then  -- point is to the right of clip rectangle
				y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0);
				x = xmax;
			
			elseif band(outcodeOut, LN_LEFT) ~= 0 then   -- point is to the left of clip rectangle
				y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0);
				x = xmin;
			end

			-- Now we move outside point to intersection point to clip
			-- and get ready for next pass.
			if (outcodeOut == outcode0) then
				x0 = x;
				y0 = y;
				outcode0 = ComputeOutCode(xmin, ymin, xmax, ymax, x0, y0);
			
			else 
				x1 = x;
				y1 = y;
				outcode1 = ComputeOutCode(xmin, ymin, xmax, ymax, x1, y1);
			end
		end
	end

	return accept, x0, y0, x1, y1;
end


-- Arbitrary line using Bresenham
function Raster2D.line(self, x1, y1, x2, y2, value)
	--print("Raster2D.line: ", x1, y1, x2, y2)
	
	local accept, x1, y1, x2, y2 = clipLine(0, 0, self.width-1, self.height-1, x1, y1, x2, y2)
	
	-- don't bother drawing line if outside boundary
	if not accept then 
		return ;
	end

---[[
	value = value or self.StrokeColor;

	x1 = floor(x1);
	y1 = floor(y1);
	x2 = floor(x2);
	y2 = floor(y2);

	x1 = clamp(x1, 0, self.width);
	x2 = clamp(x2, 0, self.width);
	y1 = clamp(y1, 0, self.height);
	y2 = clamp(y2, 0, self.height);

	--print("line: ", x1, y1, x2, y2)

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
--]]
end

function Raster2D.setPixel(self, x, y, value)
	self.surface:pixel(x, y, value)
end

-- Optimized vertical lines
function Raster2D.vline(self, x, y, length, value)
	value = value or self.StrokeColor;
	self.surface:vline(x, y, length, value);
end

function Raster2D.hline(self, x, y, length, value)
	value = value or self.StrokeColor;
	self.surface:hline(x, y, length, value);
end

function Raster2D.hspan(self, x, y, length, span)
	self.surface:hspan(x, y, length, span)
end

--[[
function Raster2D.cubicBezier(self, x1, y1, x2,y2, x3, y3, x4, y4, value)
	value = value or self.strokeColor;

	self:line(x1, y1, x2,y2, value);
	self:line(x2,y2,  x3,y3, value);
	self:line(x3,y3,  x4, y4, value);
end
--]]
--[[
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
		for (i = 0, j = r->npoints-1; i < r->npoints; j = i++) do
			self:addEdge(self.points[j].x, self.points[j].y, self.points[i].x, self.points[i].y);
		end
	end
end
--]]

--[=[
function Raster2D.drawImage(self, image, tx, ty, scale)

--				   unsigned char* dst, int w, int h, int stride)

	--NSVGshape *shape = NULL;
	--NSVGedge *e = NULL;
	--NSVGcachedPaint cache;
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

		if shape.fill.type ~= PaintType.NONE then
			nsvg__resetPool(r);
			self.freelist = nil;
			r.nedges = 0;

			self:flattenShape(shape, scale);

			-- Scale and translate edges
			for (i = 0; i < r->nedges; i++) {
				e = &r->edges[i];
				e->x0 = tx + e->x0;
				e->y0 = (ty + e->y0) * NSVG__SUBSAMPLES;
				e->x1 = tx + e->x1;
				e->y1 = (ty + e->y1) * NSVG__SUBSAMPLES;
			}

			-- Rasterize edges
			qsort(r->edges, r->nedges, sizeof(NSVGedge), nsvg__cmpEdge);

			-- now, traverse the scanlines and find the intersections on each scanline, use non-zero rule
			initPaint(&cache, &shape->fill, shape->opacity);

			self:rasterizeSortedEdges(tx,ty,scale, &cache, shape->fillRule);
		end

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
	}

	nsvg__unpremultiplyAlpha(dst, w, h, stride);

	r->bitmap = NULL;
	r->width = 0;
	r->height = 0;
	r->stride = 0;
end
--]=]

return Raster2D

--[[
typedef struct NSVGshape
{
	char id[64];				// Optional 'id' attr of the shape or its group
	NSVGpaint fill;				// Fill paint
	NSVGpaint stroke;			// Stroke paint
	float opacity;				// Opacity of the shape.
	float strokeWidth;			// Stroke width (scaled).
	float strokeDashOffset;		// Stroke dash offset (scaled).
	float strokeDashArray[8];			// Stroke dash array (scaled).
	char strokeDashCount;				// Number of dash values in dash array.
	char strokeLineJoin;		// Stroke join type.
	char strokeLineCap;			// Stroke cap type.
	char fillRule;				// Fill rule, see NSVGfillRule.
	unsigned char flags;		// Logical or of NSVG_FLAGS_* flags
	float bounds[4];			// Tight bounding box of the shape [minx,miny,maxx,maxy].
	NSVGpath* paths;			// Linked list of paths in the image.
	struct NSVGshape* next;		// Pointer to next shape, or NULL if last element.
} NSVGshape;
--]]

local Shape2D = {}
local Shape2D_mt = {
	__index = Shape2D;
}

local NSVGfillRule {
	NSVG_FILLRULE_NONZERO = 0,
	NSVG_FILLRULE_EVENODD = 1,
};

function Shape2D.init(self, obj)
	obj = obj or {
		--id[64];				-- Optional 'id' attr of the shape or its group
		fill = NSVGpaint();		-- Fill paint
		stroke = NSVGpaint();	-- Stroke paint
		opacity = 0;			-- Opacity of the shape.
		strokeWidth = 1;		-- Stroke width (scaled).
		strokeDashOffset=0;		-- Stroke dash offset (scaled).
		strokeDashArray[8];		-- Stroke dash array (scaled).
		strokeDashCount=0;		-- Number of dash values in dash array.
		strokeLineJoin;			-- Stroke join type.
		strokeLineCap;			-- Stroke cap type.
		fillRule = Path2D.NSVG_FILLRULE_NONZERO;				-- Fill rule, see NSVGfillRule.
		flags = 0;				-- Logical or of NSVG_FLAGS_* flags
		bounds[4];				-- Tight bounding box of the shape [minx,miny,maxx,maxy].
		paths = {};				-- list of paths in the image.
		--struct NSVGshape* next;		-- Pointer to next shape, or NULL if last element.
	}
	setmetatable(obj, Shape2D_mt)

	return obj
end

function Shap2D.new(self, ...)
	return self:init(...);
end

function Shape2D.flattenShapeStroke(NSVGrasterizer* r, NSVGshape* shape, float scale)

	int i, j, closed;
	NSVGpath* path;
	NSVGpoint* p0, *p1;
	float miterLimit = 4;
	int lineJoin = shape->strokeLineJoin;
	int lineCap = shape->strokeLineCap;
	float lineWidth = shape->strokeWidth * scale;

	for (path = shape->paths; path != NULL; path = path->next) then
		-- Flatten path
		r->npoints = 0;
		nsvg__addPathPoint(r, path->pts[0]*scale, path->pts[1]*scale, NSVG_PT_CORNER);
		for (i = 0; i < path->npts-1; i += 3) then
			float* p = &path->pts[i*2];
			nsvg__flattenCubicBez(r, p[0]*scale,p[1]*scale, p[2]*scale,p[3]*scale, p[4]*scale,p[5]*scale, p[6]*scale,p[7]*scale, 0, NSVG_PT_CORNER);
		end
		if (r->npoints < 2) then
			continue;
		end

		closed = path->closed;

		-- If the first and last points are the same, remove the last, mark as closed path.
		p0 = &r->points[r->npoints-1];
		p1 = &r->points[0];
		if (nsvg__ptEquals(p0->x,p0->y, p1->x,p1->y, r->distTol)) then
			r->npoints--;
			p0 = &r->points[r->npoints-1];
			closed = 1;
		end

		if (shape->strokeDashCount > 0) then
			int idash = 0, dashState = 1;
			float totalDist = 0, dashLen, allDashLen, dashOffset;
			NSVGpoint cur;

			if closed then
				nsvg__appendPathPoint(r, r->points[0]);
			end

			-- Duplicate points -> points2.
			nsvg__duplicatePoints(r);

			r->npoints = 0;
 			cur = r->points2[0];
			nsvg__appendPathPoint(r, cur);

			-- Figure out dash offset.
			allDashLen = 0;
			for (j = 0; j < shape->strokeDashCount; j++)
				allDashLen += shape->strokeDashArray[j];
			if (shape->strokeDashCount & 1)
				allDashLen *= 2.0f;
			-- Find location inside pattern
			dashOffset = fmodf(shape->strokeDashOffset, allDashLen);
			if (dashOffset < 0.0f)
				dashOffset += allDashLen;

			while (dashOffset > shape->strokeDashArray[idash]) do
				dashOffset -= shape->strokeDashArray[idash];
				idash = (idash + 1) % shape->strokeDashCount;
			end

			dashLen = (shape->strokeDashArray[idash] - dashOffset) * scale;

			for (j = 1; j < r->npoints2; ) {
				float dx = r->points2[j].x - cur.x;
				float dy = r->points2[j].y - cur.y;
				float dist = sqrtf(dx*dx + dy*dy);

				if ((totalDist + dist) > dashLen) {
					-- Calculate intermediate point
					float d = (dashLen - totalDist) / dist;
					float x = cur.x + dx * d;
					float y = cur.y + dy * d;
					nsvg__addPathPoint(r, x, y, NSVG_PT_CORNER);

					-- Stroke
					if (r->npoints > 1 && dashState) then
						nsvg__prepareStroke(r, miterLimit, lineJoin);
						nsvg__expandStroke(r, r->points, r->npoints, 0, lineJoin, lineCap, lineWidth);
					end

					-- Advance dash pattern
					dashState = !dashState;
					idash = (idash+1) % shape->strokeDashCount;
					dashLen = shape->strokeDashArray[idash] * scale;
					
					-- Restart
					cur.x = x;
					cur.y = y;
					cur.flags = NSVG_PT_CORNER;
					totalDist = 0.0f;
					r->npoints = 0;
					nsvg__appendPathPoint(r, cur);
				else
					totalDist += dist;
					cur = r->points2[j];
					nsvg__appendPathPoint(r, cur);
					j++;
				end
			end
			-- Stroke any leftover path
			if (r->npoints > 1 && dashState)
				nsvg__expandStroke(r, r->points, r->npoints, 0, lineJoin, lineCap, lineWidth);
		else
			nsvg__prepareStroke(r, miterLimit, lineJoin);
			nsvg__expandStroke(r, r->points, r->npoints, closed, lineJoin, lineCap, lineWidth);
		end
	end
end

function Shape2D.flattenShape(self, scale)

	int i, j;

	for _, path in ipairs(shape.paths) do
		self.npoints = 0;
		
		-- Flatten path
		self:addPathPoint(path->pts[0]*scale, path->pts[1]*scale, 0);
		for (i = 0; i < path->npts-1; i += 3) {
			float* p = &path->pts[i*2];
			self:flattenCubicBez(p[0]*scale,p[1]*scale, p[2]*scale,p[3]*scale, p[4]*scale,p[5]*scale, p[6]*scale,p[7]*scale, 0, 0);
		end

		-- Close path
		self:addPathPoint(path.pts[0]*scale, path.pts[1]*scale, 0);
		-- Build edges
		for (i = 0, j = r->npoints-1; i < r->npoints; j = i++) do
			self:addEdge(self.points[j].x, self.points[j].y, self.points[i].x, self.points[i].y);
		end
	end
end

return Shape2D

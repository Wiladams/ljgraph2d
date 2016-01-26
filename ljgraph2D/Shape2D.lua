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

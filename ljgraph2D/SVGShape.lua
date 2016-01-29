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

local SVGShape = {}
local SVGShape_mt = {
	__index = SVGShape;
}



function SVGShape.init(self, obj)
	obj = obj or {
		--id[64];				-- Optional 'id' attr of the shape or its group
		fill 			= SVGpaint();		-- Fill paint
		stroke 			= SVGpaint();	-- Stroke paint
		Opacity 		= 0;			-- Opacity of the shape.
		strokeWidth		= 1;		-- Stroke width (scaled).
		strokeDashOffset= 0;		-- Stroke dash offset (scaled).
		strokeDashArray = ffi.new("double[8]");		-- Stroke dash array (scaled).
		strokeDashCount = 0;		-- Number of dash values in dash array.
		strokeLineJoin	= LineJoin.ROUND;			-- Stroke join type.
		strokeLineCap 	= LineCap.BUTT;			-- Stroke cap type.
		fillRule 		= FillRule.NONZERO;				-- Fill rule, see NSVGfillRule.
		flags 			= Flags.VISIBLE;				-- Logical or of NSVG_FLAGS_* flags
		bounds			= ffi.new("double[4]");				-- Tight bounding box of the shape [minx,miny,maxx,maxy].
		paths = {};				-- list of paths in the image.
	}
	setmetatable(obj, Shape2D_mt)

	return obj
end

function SVGShape.new(self, params)
	return self:init(params);
end

return SVGShape;

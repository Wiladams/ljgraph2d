--[[
typedef struct NSVGimage
{
	float width;				// Width of the image.
	float height;				// Height of the image.
	NSVGshape* shapes;			// Linked list of shapes in the image.
} NSVGimage;
--]]

local Image = {}
setmetatable(Image, {
	__call = function(self, ...)
		return self:new(...);
	end,
})
local Image_mt = {
	__index = Image;
}

function Image.new(self, width, height)
	local obj = {
		width = width or 0;
		height = height or 0;

		shapes = {};
	}
	setmetatable(obj, Image_mt);

	return obj;
end

function Image.init(self, width, height)
	return self:init(width, height);
end

function Image.draw(self, graphPort)
	for _, shape in ipairs(self.shapes) do
		shape:draw(graphPort)
	end
end

return Image
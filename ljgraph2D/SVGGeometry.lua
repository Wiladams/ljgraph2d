--[[
--]]

local Document = {}
setmetatable(Document, {
	__call = function(self, ...)
		return self:new(...);
	end,
	})
local Document_mt = {
	__index = Document;
}

function Document.init(self, params)
	local obj = params or {}
	obj.Shapes = obj.Shapes or {}

	setmetatable(obj, Document_mt);

	return obj;
end

function Document.new(self, ...)
	return self:init(...)
end

function Document.addShape(self, shape)
	table.insert(self.Shapes, shape);
end

function Document.write(self, strm)
	strm:openElement("svg");
	for name, value in pairs(self) do
		if type(value) == "string" or
			type(value) == "number" then
			strm:addAttribute(name, value);
		elseif type(value) == "table" then
			if value == self.Shapes then
				for _, shape in ipairs(value) do
					shape:write(strm);
				end
			end
		end
	end
	strm:closeElement("svg");
end


--[[
	Rect
	x - left
	y - top
	width - how wide
	height - how tall
--]]
local Rect={}
setmetatable(Rect, {
	__call = function(self, ...)
		return self:new(...);
	end,
})
local SVGRect_mt = {
	__index = Rect;
}

function Rect.init(self, params)
	local obj = params or {}
	setmetatable(obj, SVGRect_mt)

	obj.x = obj.x or 0;
	obj.y = obj.y or 0;
	obj.width = obj.width or 0;
	obj.height = obj.height or 0;
	obj.rx = obj.rx or 0;
	obj.ry = obj.rx or obj.rx;

	return obj
end

function Rect.new(self, params)
	return self:init(params)
end

-- write ourself out as an SVG string
function Rect.write(self, strm)
	strm:openElement("rect")
	for name, value in pairs(self) do
		if type(value) == "string" or
			type(value) == "number" then
			strm:addAttribute(name, value);
		end
	end

	strm:closeElement();
end

-- Parse a definition from the stream
function Rect.read(self, strm)
end


return {
	Document = Document;
	Group = Group;
	Stroke = Stroke;
	Fill = Fill;

	Circle = Circle;
	Ellipse = Ellipse;
	Image = Image;
	Line = Line;
	Marker = Marker;
	Polygon = Polygon;
	PolyLine = PolyLine;
	Path = Path;
	Rect = Rect;
	Text = Text;
	TextPath = TextPath;
	TRef = TRef;
	TSpan = TSpan;
}
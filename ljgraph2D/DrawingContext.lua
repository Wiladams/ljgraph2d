local ffi = require("ffi")
local bit = require("bit")
local rshift = bit.rshift

local abs = math.abs;
local floor = math.floor;

local maths = require("ljgraph2D.maths")
local sgn = maths.sgn;
local round = maths.round;

local int16_t = tonumber;
local int32_t = tonumber;
local uint32_t = tonumber;
local int = tonumber;


--[[
	DrawingContext

	Represents the API for doing drawing.  This is a retained interface,
	so it will maintain a current drawing color and various other 
	attributes.
--]]
local DrawingContext = {}
setmetatable(DrawingContext, {
	__call = function(self, ...)
		return self:new(...)
	end,
})
local DrawingContext_mt = {
	__index = DrawingContext;
}


function DrawingContext.init(self, width, height)

	local obj = {
		width = width;
		height = height;
	}
	setmetatable(obj, DrawingContext_mt)

	return obj;
end

function DrawingContext.new(self, width, height)
	return self:init(width, height, data)
end


return DrawingContext
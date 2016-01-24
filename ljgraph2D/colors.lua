local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift


local function RGBA(r, g, b, a)
	a = a or 255;
	return bor(lshift(a,24), lshift(r,16), lshift(g,8), b)
end

local exports = {
	RGBA = RGBA;

	white = RGBA(255, 255, 255);
	black = RGBA(0,0,0);
	blue = RGBA(0,0,255);
	green = RGBA(0,255,0);
	red = RGBA(255, 0, 0);

	yellow = RGBA(255, 255, 0);
	darkyellow = RGBA(127, 127, 0);

	-- grays
	lightgray = RGBA(235, 235, 235);
}

return exports

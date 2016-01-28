local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift; 
local bxor = bit.bxor;
--local math = require("math")
local floor = math.floor;
local bmp = require("bmpcodec")
local FileStream = require("filestream")



local function fillRect(surf, x, y, w, h, color)
	if x >= surf.width or y >= surf.height then return end

	for line = y, y+h-1 do
		surf:hline(x, line, w, color)
	end
end

-- Draw a simple checker board pattern using solid colors
local function drawCheckerboard (surf,check_size, color1, color2)
    local n_checks_x = floor((surf.width + check_size - 1) / check_size);
    local n_checks_y = floor((surf.height + check_size - 1) / check_size);

    for j = 0, n_checks_y-1 do
		for i = 0, n_checks_x-1 do
	    	local src = nil;

	    	if band(bxor(i, j), 1) > 0 then
				src = color1;
	    	else
				src = color2;
			end

			local x = i*check_size;
			local y = j*check_size;
			fillRect(surf, x,y, check_size, check_size, src);
		end
    end
end

local function save(surf, filename)
	-- Write the surface to a .bmp file
	local fs = FileStream.open(filename)
	bmp.write(fs, surf)
	fs:close();
end


return {
	drawCheckerboard = drawCheckerboard;
	fillRect = fillRect;
	save = save;
}
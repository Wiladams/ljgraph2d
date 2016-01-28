-- BmpCodec.lua
-- Write out a Drawing Context into a 
-- stream as a BMP encoded image
local MemoryStream = require("memorystream");
local BinaryStream = require("binarystream");



local ImageBitCount = 32;
local PixelOffset = 54;
local BI_RGB = 0;

--    params.CapturedStream = MemoryStream(streamsize);

local function GetAlignedByteCount(width, bitsPerPixel, byteAlignment)
    local nbytes = width * (bitsPerPixel/8);
    return nbytes + (byteAlignment - (nbytes % byteAlignment)) % byteAlignment
end

local BmpCodec = {}

function BmpCodec.getBmpFileSize(img)
    rowsize = GetAlignedByteCount(img.width, img.bitcount, 4);
    pixelarraysize = rowsize * math.abs(img.height);
    filesize = PixelOffset+pixelarraysize;

    return filesize;
end

function BmpCodec.setup(width, height, bitcount, data)
    rowsize = GetAlignedByteCount(width, bitcount, 4);
    pixelarraysize = rowsize * math.abs(height);
    filesize = PixelOffset+pixelarraysize;

    return {
        width = width;
        height = height;
        bitcount = bitcount;
        data = data;

        pixeloffset = 54;
        rowsize = rowsize;
        pixelarraysize = pixelarraysize;
        filesize = filesize;
        streamsize = GetAlignedByteCount(filesize, 8, 4);
    }
end


function BmpCodec.write(BaseStream, img)
    local bs = BinaryStream:new(BaseStream);

    filesize = PixelOffset+img.pixelarraysize;

	-- Write File Header
    bs:writeByte(string.byte('B'))
    bs:writeByte(string.byte('M'))
    bs:writeInt32(filesize);
    bs:writeInt16(0);
    bs:writeInt16(0);
    bs:writeInt32(PixelOffset);

    -- Bitmap information header
    bs:writeInt32(40);
    bs:writeInt32(img.width);    -- dibsec.Info.bmiHeader.biWidth
    bs:writeInt32(-img.height);   -- dibsec.Info.bmiHeader.biHeight
    bs:writeInt16(1);               -- dibsec.Info.bmiHeader.biPlanes);
    bs:writeInt16(img.bitcount); -- dibsec.Info.bmiHeader.biBitCount);
    bs:writeInt32(BI_RGB);               -- dibsec.Info.bmiHeader.biCompression);
    bs:writeInt32(img.pixelarraysize);               -- dibsec.Info.bmiHeader.biSizeImage);
    bs:writeInt32(0);               -- dibsec.Info.bmiHeader.biXPelsPerMeter);
    bs:writeInt32(0);               -- dibsec.Info.bmiHeader.biYPelsPerMeter);
    bs:writeInt32(0);               -- dibsec.Info.bmiHeader.biClrUsed);
    bs:writeInt32(0);               -- dibsec.Info.bmiHeader.biClrImportant);

    -- Write the actual pixel data
    BaseStream:writeBytes(img.data, img.pixelarraysize, 0);

    return filesize;
end


return BmpCodec;

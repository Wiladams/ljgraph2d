package.path = "../?.lua;"..package.path

local ffi = require("ffi")

local XmlParser = require("ljgraph2D.SVGXmlParser")

local function strdup(s)
	local buf = ffi.new("char [?]", #s+1)
	ffi.copy(buf, ffi.cast("const char *", s), #s)
	buf[#s] = 0;
	return buf, #s;
end

-- Simple path parsing
-- http://stackoverflow.com/questions/16863540/parse-svg-path-definition-d-in-lua
--
function parsePath(input)
    local out = {};

    for instr, vals in input:gmatch("([a-df-zA-DF-Z])([^a-df-zA-DF-Z]*)") do
        local line = { instr };
        for v in vals:gmatch("([+-]?[%deE.]+)") do
            line[#line+1] = v;
        end
        out[#out+1] = line;
    end
    return out;
end




local fd = io.open("nano.svg")
local contents = fd:read("*a")
fd:close();

local input = strdup(contents)



local function test_parsePath()
	local function startelCb(ud, elname, attr)
		print("startelCb: ", elname)

		if elname ~= "path" then
			return
		end

		-- the 'd' attribute contains the path
		local r = parsePath(attr.d);

		for i=1, #r do
    		print("{ "..table.concat(r[i], ", ").." }");
		end
	end

	XmlParser.parseXML(input, startelCb, endelCb, contentCb, ud)
end

local function test_parseXml()
	local function startelCb(ud, el, attr)
		print("START ELEMENT: ", el)
		print("-- ATTRS --")
		for k,v in pairs(attr) do
			print(k,v)
		end
	end

	local function endelCb(ud, el)
		print("END ELEMENT: ", el)
	end

	local function contentCb()
		print("CONTENT")
	end

	XmlParser.parseXML(input, startelCb, endelCb, contentCb, ud)
end


test_parsePath();
--test_parseXml();

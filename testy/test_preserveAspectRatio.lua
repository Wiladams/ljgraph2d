--test_geom_ellipse.lua
-- https://www.w3.org/TR/SVG2/shapes.html

-- SETUP --
package.path = "../?.lua;"..package.path

local FileStream = require("filestream")
local SVGStream = require("ljgraph2D.SVGStream")

local SVGGeometry = require("ljgraph2D.SVGGeometry")
local defs = SVGGeometry.Definitions;
local svg = SVGGeometry.Document;

local circle = SVGGeometry.Circle;
local rect = SVGGeometry.Rect;
local ellipse = SVGGeometry.Ellipse;
local group = SVGGeometry.Group;
local text = SVGGeometry.Text;
local use = SVGGeometry.Use;


--[[
<svg width="450px" height="300px"
     xmlns="http://www.w3.org/2000/svg">
  <desc>Example PreserveAspectRatio - illustrates preserveAspectRatio attribute</desc>
</svg>
--]]
-- TEST --
local function test_geom(filename)
		-- create a file stream to write out the image
	local fs = FileStream.open(filename)
	--local fs = FileStream.new(io.stdout);
	local strm = SVGStream(fs);


	local doc = svg({version="1.1",
		width="450px", height="300px",
		viewBox="0 0 1200 400",

		
		defs({
				group({id="smile";
					rect({x=.5, y=.5, width=29, height=39, fill='black', stroke='red'});
					
					group({
						transform = 'translate(0, 5)';

						circle({cx = 15, cy = 15, r = 10, fill = 'yellow'});
						circle({cx = 12, cy = 12, r = 1.5, fill = 'black'});
						circle({cx = 17, cy = 12, r = 1.5, fill = 'black'});
						--path({d = 'M 10 19 A 8 8 0 0 0 20 19', stroke = 'black', ["stroke-width"] = 2});
					});
				});
		});
		
  		rect({x="1", y="1", width="448", height="298", fill="none", stroke="blue"});

		group({
			["font-size"]="9";
    		text({x= 10, y= 30}, "SVG to fit");

    		group({
    			transform="translate(20,40)";
    			use({href="#smile"});
    		});

    		text({x="10", y="110"}, "Viewport 1");
    		group({transform="translate(10,120)";
    			rect({x='.5', y='.5', width='49', height='29', fill='none', stroke='blue'});
    		});
    		text({x="10", y="180"}, "Viewport 2");
    		group({transform="translate(20,190)";
    			rect({x='.5', y='.5', width='29', height='59', fill='none', stroke='blue'});
    		});
--[[
    		<g id="meet-group-1" transform="translate(100, 60)">
      			<text x="0" y="-30">--------------- meet ---------------</text>
      			<g>
      				<text y="-10">xMin*</text>
      				<rect x='.5' y='.5' width='49' height='29' fill='none' stroke='blue'/>;
        			<svg preserveAspectRatio="xMinYMin meet" viewBox="0 0 30 40"
             			width="50" height="30"><use href="#smile" />
             		</svg>
             	</g>
      			
      			<g transform="translate(70,0)">
      				<text y="-10">xMid*</text>
      				<rect x='.5' y='.5' width='49' height='29' fill='none' stroke='blue'/>;
        			<svg preserveAspectRatio="xMidYMid meet" viewBox="0 0 30 40"
             			width="50" height="30">
             			<use href="#smile" />
             		</svg>
             	</g>
      			
      			<g transform="translate(0,70)">
      				<text y="-10">xMax*</text>
      				<rect x='.5' y='.5' width='49' height='29' fill='none' stroke='blue'/>;
        			<svg preserveAspectRatio="xMaxYMax meet" viewBox="0 0 30 40"
             			width="50" height="30">
             			<use href="#smile" />
             		</svg>
             	</g>
    		</g>

    		<g id="meet-group-2" transform="translate(250, 60)">
      			<text x="0" y="-30">---------- meet ----------</text>
      			<g>
      				<text y="-10">*YMin</text>
      				<rect x='.5' y='.5' width='29' height='59' fill='none' stroke='blue'/>;
        			<svg preserveAspectRatio="xMinYMin meet" viewBox="0 0 30 40"
             			width="30" height="60">
             			<use href="#smile" />
             		</svg>
             	</g>
      			
      			<g transform="translate(50, 0)">
      				<text y="-10">*YMid</text>
      				<rect x='.5' y='.5' width='29' height='59' fill='none' stroke='blue'/>;
        			<svg preserveAspectRatio="xMidYMid meet" viewBox="0 0 30 40"
             			width="30" height="60"><use href="#smile" />
             		</svg>
             	</g>
      			
      			<g transform="translate(100, 0)">
      				<text y="-10">*YMax</text>
      				<rect x='.5' y='.5' width='29' height='59' fill='none' stroke='blue'/>;
        			<svg preserveAspectRatio="xMaxYMax meet" viewBox="0 0 30 40"
             			width="30" height="60">
             			<use href="#smile" />
             		</svg>
             	</g>
    		</g>
--]]
--[[
    		<g id="slice-group-1" transform="translate(100, 220)">
      <text x="0" y="-30">---------- slice ----------</text>
      <g><text y="-10">xMin*</text><rect x='.5' y='.5' width='29' height='59' fill='none' stroke='blue'/>;
        <svg preserveAspectRatio="xMinYMin slice" viewBox="0 0 30 40"
             width="30" height="60"><use href="#smile" /></svg></g>
      <g transform="translate(50,0)"><text y="-10">xMid*</text><rect x='.5' y='.5' width='29' height='59' fill='none' stroke='blue'/>;
        <svg preserveAspectRatio="xMidYMid slice" viewBox="0 0 30 40"
             width="30" height="60"><use href="#smile" /></svg></g>
      <g transform="translate(100,0)"><text y="-10">xMax*</text><rect x='.5' y='.5' width='29' height='59' fill='none' stroke='blue'/>;
        <svg preserveAspectRatio="xMaxYMax slice" viewBox="0 0 30 40"
             width="30" height="60"><use href="#smile" /></svg></g>
    		</g>
--]]

--[[
    		<g id="slice-group-2" transform="translate(250, 220)">
      <text x="0" y="-30">--------------- slice ---------------</text>
      <g><text y="-10">*YMin</text><rect x='.5' y='.5' width='49' height='29' fill='none' stroke='blue'/>;
        <svg preserveAspectRatio="xMinYMin slice" viewBox="0 0 30 40"
             width="50" height="30"><use href="#smile" /></svg></g>
      <g transform="translate(70,0)"><text y="-10">*YMid</text><rect x='.5' y='.5' width='49' height='29' fill='none' stroke='blue'/>;
        <svg preserveAspectRatio="xMidYMid slice" viewBox="0 0 30 40"
             width="50" height="30"><use href="#smile" /></svg></g>
      <g transform="translate(140,0)"><text y="-10">*YMax</text><rect x='.5' y='.5' width='49' height='29' fill='none' stroke='blue'/>;
        <svg preserveAspectRatio="xMaxYMax slice" viewBox="0 0 30 40"
             width="50" height="30"><use href="#smile" /></svg></g>
    		</g>
--]]
  		});



	})



	doc:write(strm);
end


test_geom("test_preserveAspectRatio.svg");

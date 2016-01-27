--test_path2d.lua

package.path = "../?.lua;"..package.path

local Path2D = require("ljgraph2D.Path2D")

local path1 = Path2D();

path1:addPathPoint(10, 10, Path2D.PointFlags.CORNER)
path1:addPathPoint(10, 200, Path2D.PointFlags.CORNER)
path1:addPathPoint(200, 200, Path2D.PointFlags.CORNER)

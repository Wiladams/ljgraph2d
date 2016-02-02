	local percentvaluepatt = "(%d+%%)%s*,%s*(%d+%%)%s*,%s*(%d+%%)"
	local valuepatt = "(%d+)%s*,%s*(%d+)%s*,%s*(%d+)"

local valuestr = "123, 245, 789"
local percentvaluestr = "0.7%, .5%, 0.89%"

local a, b, c = valuestr:match(valuepatt)
print(a,b,c)


local a, b, c = percentvaluestr:match(valuepatt)
print("PERCENT (valuepatt): ", a,b,c)

local a, b, c = percentvaluestr:match(percentvaluepatt)
print("PERCENT (percentvaluepatt): ", a,b,c)
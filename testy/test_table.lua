--test_table.lua
--Let's see what happens when you mix
-- named fields, and enumerants
local tbl = {
--	name1 = "foo", 
--	name2 = "bar";

	-- Now add some basic stuff
	{"my", "fellow", "americans"},
	{"lend", "me", "your", "ears"},
}

print("Count: ", #tbl);
print("== ipairs ==")
for idx, value in ipairs(tbl) do
	print(id, value);
end

print("== pairs ==")
for name, value in pairs(tbl) do
	print(name, value);
end

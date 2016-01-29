local function stack()
	local obj = {}
	setmetatable(obj, {
		__index = obj;
	})
	
	function obj.push(self, value)
		table.insert(self, value);
		return value;
	end

	function obj.pop(self)
		return table.remove(self)
	end

	function obj.top(self)
		if #self < 1 then
			return nil;
		end
		
		return self[#self];
	end

	return obj;
end

local s = stack()
s:push("bottom")
s:push("middle")
s:push("top")

print("top: ", s:top())
print("pop: ", s:pop())
print("pop: ", s:pop())
print("pop: ", s:pop())
print("pop(E): ", s:pop())
print("push: ", s:push("bottom1"))
print("push: ", s:push("bottom2"))

for _, v in ipairs(s) do
	print (v)
end


-- extracted from Programming Pearls, page 110
--[[
  qsort - quick sort algorithm

  x - array of elements
  l - lowest starting point
  u - number of elements in array
  f - function called to compare two values
    -1 - first value smaller
    0 - values equivalent
    1 - first value greater
--]]
local function qsort(x,l,u,f)
    if l<u then
        local m=math.random(u-(l-1))+l-1	-- choose a random pivot in range l..u
        x[l],x[m]=x[m],x[l]			-- swap pivot to first position
        local t=x[l]				-- pivot value
        m=l
        local i=l+1
        
        while i<=u do
        -- invariant: x[l+1..m] < t <= x[m+1..i-1]
            if f(x[i],t) then
                m=m+1
                x[m],x[i]=x[i],x[m]		-- swap x[i] and x[m]
            end
            i=i+1
        end
        
        x[l],x[m]=x[m],x[l]			-- swap pivot to a valid place
        -- x[l+1..m-1] < x[m] <= x[m+1..u]
        qsort(x,l,m-1,f)
        qsort(x,m+1,u,f)
    end
end

local function selectionsort(x,n,f)
 local i=1
 while i<=n do
  local m,j=i,i+1
  while j<=n do
   if f(x[j],x[m]) then m=j end
   j=j+1
  end
 x[i],x[m]=x[m],x[i]			-- swap x[i] and x[m]
 i=i+1
 end
end

return {
  qsort = qsort;
  selectionsort = selectionsort;
}

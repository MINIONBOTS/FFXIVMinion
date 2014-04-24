-- flips a table so keys become values
function table_invert(t)
   local s={}
   for k,v in pairs(t) do
     s[v]=k
   end
   return s
end

-- takes in a % number and gives back a random number near that value, for randomizing skill usage at x% hp
function randomize(val)
	if ( val <= 100 and val > 0) then
		local high,low
		if ( (val + 15) > 100) then
			high = 100			
		else
			high = val + 15
		end
		if ( (val - 15) <= 0) then
			low = 1			
		else
			low = val - 15
		end
		return math.random(low,high)
	end
	return 0
end

function TimeSince(previousTime)
    return ml_global_information.Now - previousTime
end

function PathDistance(posTable)
	if ( TableSize(posTable) > 0) then
		local distance = 0
		local id1, pos1 = next(posTable)
		if (id1 ~= nil and pos1 ~= nil) then
			local id2, pos2 = next(posTable, id1)
			if (id1 ~= nil and pos2 ~= nil) then
				while (id2 ~= nil and pos2 ~= nil) do
					local posDistance = math.sqrt(math.pow(pos2.x-pos1.x,2) + math.pow(pos2.y-pos1.y,2) + math.pow(pos2.z-pos1.z,2))
					distance = distance + posDistance
					pos1 = pos2
					id2, pos2 = next(posTable,id2)
				end
			end
		end
		return distance
	end
end

function FileExists(file)
  local f = fileread(file)
  if ( TableSize(f) > 0) then
    return true
  end
  return false 
end

function LinesFrom(file)
	lines = fileread(file)
	cleanedLines = {}
	--strip any bad line endings
	if (ValidTable(lines)) then
		for i,line in pairs(lines) do
			if line:sub(line:len(),line:len()+1) == "\r" then
				cleanedLines[i] = line:sub(1,line:len()-1)
			else
				cleanedLines[i] = line
			end
		end
	end
	
  return cleanedLines 
end


function StringSplit(s,sep)
	local lasti, done, g = 1, false, s:gmatch('(.-)'..sep..'()')
	return function()
		if done then return end
		local v,i = g()
		if s == '' or sep == '' then done = true return s end
		if v == nil then done = true return s:sub(lasti) end
		lasti = i
		return v
	end
end

function ApproxEqual(num1, num2)
    return math.abs(math.abs(num1) - math.abs(num2)) < .000001
end

function TableContains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function ValidTable(table)
    return table ~= nil and TableSize(table) > 0
end

function TrimString(new_string, count)
	return new_string:sub(1,new_string:len() - count)
end

-- returns a table containing first entry in the list, list of keys, and list of values
function GetComboBoxList(entryTable)
	local firstkey = ""
	local firstvalue = ""
	local keylist = ""
	local valuelist = ""
	
	for key, value in pairs(entryTable) do
		if (type(key) == "string" or type(key) == "number") then
			if (keylist == "") then
				keylist = tostring(key)
				firstkey = tostring(key)
			else
				keylist = keylist..","..tostring(key)
			end
		end
		
		if (type(value) == "string" or type(value) == "number") then
			if (valuelist == "") then
				valuelist = tostring(value)
				firstvalue = tostring(value)
			else
				valuelist = valuelist..","..tostring(value)
			end
		end
	end
	
	return { firstKey = firstkey, firstValue = firstvalue, keyList = keylist, valueList = valuelist}
end

function round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

function findfunction(x)
  assert(type(x) == "string")
  local f=_G
  for v in x:gmatch("[^%.]+") do
    if type(f) ~= "table" then
       return nil, "looking for '"..v.."' expected table, not "..type(f)
    end
    f=f[v]
  end
  if type(f) == "function" then
    return f
  else
    return nil, "expected function, not "..type(f)
  end
end

function table_merge(t1, t2)
    for k,v in pairs(t2) do t1[k] = v end
end

function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
	i = i + 1
	if a[i] == nil then return nil
	else return a[i], t[a[i]]
	end
  end
  return iter
end

function GetRandomTableEntry(t)
    if (ValidTable(t)) then
        local i = math.random(1,TableSize(t))
        local counter = 1
        for key, value in pairs(t) do
            if (counter == i) then
                return value
            else
                counter = counter + 1
            end
        end
    end
    
    ml_debug("Error in GetRandomTableEntry()")
end

--psuedo enum values for task classes
TS_FAILED = 0
TS_SUCCEEDED = 1
TS_PROGRESSING = 2

TP_IMMEDIATE = 0
TP_ASAP = 1

IMMEDIATE_GOAL = 1
REACTIVE_GOAL = 2
LONG_TERM_GOAL = 3
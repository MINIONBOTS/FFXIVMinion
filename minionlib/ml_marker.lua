--ml_marker defines the marker class
ml_marker = inheritsFrom(nil)

-- external API functions
function ml_marker:AddField(fieldType, fieldName, defaultValue)
	if (self.fields[fieldName] == nil) then
		local fieldTable = self:GetLastField()
		local nextOrder = 1
		if (fieldTable) then
			nextOrder = fieldTable["order"] + 1
		end
		
		self.fields[fieldName] = {type = fieldType, name = fieldName, value = defaultValue, order = nextOrder}
	else
		ml_error("Cannot add field "..fieldName.."...another field with same name already exists")
	end
end

function ml_marker:RemoveField(fieldName)
	if (self.fields[fieldName] ~= nil) then
		self.fields[fieldName] = nil
	else
		ml_debug("No field with name "..fieldName.." found in the marker table")
	end
end

function ml_marker:GetFieldValue(fieldName)
	local field_table = self:GetFieldTable(fieldName)
	if (field_table) then
		return field_table["value"]
	else
		ml_debug("No field with name "..filedName.." found in the marker table")
		return nil
	end
end

function ml_marker:GetFieldType(fieldName)
	local field_table = self:GetFieldTable(fieldName)
	if (field_table) then
		return field_table["type"]
	else
		ml_debug("No field with name "..filedName.." found in the marker table")
		return nil
	end
end

function ml_marker:SetFieldValue(fieldName, fieldValue)
	if (self.fields[fieldName]) then
		self.fields[fieldName].value = fieldValue
		return true
	else
		ml_debug("No field with name "..fieldName.." found in the marker table")
		return false
	end
end

-- return list of fields names in order
function ml_marker:GetFieldNames()
	local namesTable = {}
	
	for name, fieldTable in pairs(self.fields) do
		if	(name ~= "x") and
			(name ~= "y") and
			(name ~= "z") and
			(name ~= "h") and
			(name ~= "red") and
			(name ~= "green") and
			(name ~= "blue") and
			(name ~= "type")
		then
			namesTable[fieldTable["order"]] = name
		end
	end
	
	return namesTable
end

function ml_marker:GetLastField()
    local lastField = nil
    
	for name, fieldTable in pairs(self.fields) do
		if (lastField == nil or fieldTable["order"] > lastField["order"]) then
			lastField = fieldTable
		end
	end
    
    return lastField
end

function ml_marker:HasField(fieldName)
	return (self.fields[fieldName] ~= nil)
end

--returns a reference to a new marker with the same fields
function ml_marker:Copy()
	local name = self:GetName()
	if (name) then
		local marker = ml_marker:Create(name)
		for fieldName, fieldTable in pairs(self.fields) do
			if (marker:HasField(fieldName)) then
				marker:SetFieldValue(fieldName, self:GetFieldValue(fieldName))
			else
				marker:AddField(fieldName, self:GetFieldType(fieldName), self:GetFieldValue(fieldName))
			end
		end

		return marker
	end
	
	ml_debug("Error copying marker")
	return nil
end

--convenience accessors
function ml_marker:GetPosition()
	return {x = self:GetFieldValue("x"), y = self:GetFieldValue("y"), z = self:GetFieldValue("z"), h = self:GetFieldValue("h") }
end

function ml_marker:SetPosition(x, y, z, h)
	return self:SetFieldValue("x", x) and self:SetFieldValue("y", y) and self:SetFieldValue("z", z) and self:SetFieldValue("h", h)
end

function ml_marker:GetColor()
	return {red = self:GetFieldValue("red"), green = self:GetFieldValue("green"), blue = self:GetFieldValue("blue") }
end

function ml_marker:SetColor(r, g, b)
	return self:SetFieldValue("red", r) and self:SetFieldValue("green", g) and self:SetFieldValue("blue", b)
end

function ml_marker:GetType()
	return self:GetFieldValue("type")
end

function ml_marker:SetType(markerType)
	return self:SetFieldValue("type", markerType)
end

function ml_marker:GetName()
	return self:GetFieldValue("name")
end

function ml_marker:SetName(markerName)
	return self:SetFieldValue("name", markerName)
end

function ml_marker:GetTime()
	return self:GetFieldValue("time")
end

function ml_marker:SetTime(markerTime)
	return self:SetFieldValue("time", markerTime)
end

function ml_marker:GetMinLevel()
	return self:GetFieldValue("minLevel")
end

function ml_marker:SetMinLevel(minLevel)
	return self:SetFieldValue("minLevel", minLevel)
end

function ml_marker:GetMaxLevel()
	return self:GetFieldValue("maxLevel")
end

function ml_marker:SetMaxLevel()
	return self:SetFieldValue("maxLevel", maxLevel)
end

-- internal functions
function ml_marker:GetFieldTable(fieldName)
	return self.fields[fieldName]
end

function ml_marker:Create(markerName)
	local newMarker = inheritsFrom(ml_marker)
	newMarker.fields = {}
    newMarker.order = 0
	
	-- add default fields
	-- name
	newMarker:AddField("string", "name", markerName)
	
	-- position
	newMarker:AddField("float", "x", 0.0)
	newMarker:AddField("float", "y", 0.0)
	newMarker:AddField("float", "z", 0.0)
	newMarker:AddField("float", "h", 0.0)
	
	-- color
	newMarker:AddField("int", "red", 0)
	newMarker:AddField("int", "green", 0)
	newMarker:AddField("int", "blue", 0)
	
	-- type
	newMarker:AddField("string", "type", "")
	
	-- time
	newMarker:AddField("int", "time", 0)
	
	-- minlevel
	newMarker:AddField("int", "minLevel", 0)
	
	-- maxlevel
	newMarker:AddField("int", "maxLevel", 0)
	
	return newMarker
end
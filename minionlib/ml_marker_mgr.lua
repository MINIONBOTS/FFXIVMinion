--ml_marker_mgr is a gwen GUI for editing general marker information
--it should ALWAYS remain independent from any game-specific data
--
--the game implementation is responsible for the following:
--(1) creating marker templates (see setup example)
--(2) overriding the GetPosition() function so that it returns a valid player position
--(3) setting markerPath to the proper location for reading/writing marker files

ml_marker_mgr = {}
ml_marker_mgr.version = 1.0
ml_marker_mgr.parentWindow = nil
ml_marker_mgr.mainwindow =  { name = strings[gCurrentLanguage].markerManager,    x = 340, y = 50, w = 250, h = 300}
ml_marker_mgr.editwindow =  { name = strings[gCurrentLanguage].editMarker,       w = 250, h = 300}
ml_marker_mgr.markerList = {}
ml_marker_mgr.renderList = {}
ml_marker_mgr.currentMarker = {}		--current marker selected by the GetNextMarker() function
ml_marker_mgr.currentEditMarker = {}	--current marker displayed in the edit window
ml_marker_mgr.markersLoaded = false
--CREATE THIS LIST IN GAME IMPLEMENTATION
ml_marker_mgr.templateList = {}			--list of marker templates for defining marker types and creating new markers
--SET THIS PATH IN GAME IMPLEMENTATION
ml_marker_mgr.markerPath = ""

-- OVERRIDE THIS FUNCTION IN GAME IMPLEMENTATION
function ml_marker_mgr.GetPosition()
	return {x = 0.0, y = 0.0, z = 0.0, h = 0.0}
end

-- OVERRIDE THIS FUNCTION IN GAME IMPLEMENTATION
function ml_marker_mgr.GetLevel()
	return 99
end

-- OVERRIDE THIS FUNCTION IN GAME IMPLEMENTATION
function ml_marker_mgr.DrawMarker(marker)
	return false
end

-- ACCESSORS
-- Global function to get current marker
function GetCurrentMarker()
    return ml_marker_mgr.currentMarker
end

function ml_marker_mgr.GetList(markerType, filterEnabled, filterLevel)
	local list = ml_marker_mgr.markerList[markerType]
	local newlist = {}
	
	if (list) then
		for name, marker in pairs(list) do
			local addMarker = true
			if (filterEnabled and marker.order < 1) then
				addMarker = false
			end
			
			if (filterLevel) then
				local level = ml_marker_mgr.GetLevel()
				if (marker:GetMinLevel() > level or marker:GetMaxLevel() < level) then
					addMarker = false
				end
			end
			
			if (addMarker) then
				newlist[name] = marker
			end
		end
	end
	
	return newlist
end

function ml_marker_mgr.GetListByOrder(markerType, filterLevel)
    local list = ml_marker_mgr.GetList(markerType, true, filterLevel)
    if (ValidTable(list)) then
        local orderedList = {}
        for name, marker in pairs(list) do
            orderedList[marker.order] = marker
        end
        
        if (ValidTable(orderedList)) then
            return orderedList
        end
    end
end

function ml_marker_mgr.GetMarker(markerName)
	for _, list in pairs(ml_marker_mgr.markerList) do
		for name, marker in pairs(list) do
			if (name == markerName) then
				return marker
			end
		end
	end
	
	ml_debug("No marker data for marker name "..markerName.." found in the marker list")
	return nil
end

function ml_marker_mgr.GetMarkerByOrder(type, order)
	local list = ml_marker_mgr.GetList(type, false)
	if (list) then
		for name, marker in pairs(list) do
			if (marker.order == order) then
				return marker
			end
		end
	end
	
	ml_debug("No marker data for marker with order "..tostring(order).." found in the marker list")
	return nil
end

function ml_marker_mgr.GetLastMarker(markerType)
    local lastMarker = nil
    
    local markerList = ml_marker_mgr.GetList(markerType, true)
    if (markerList) then
        for name, marker in pairs(markerList) do
            if (lastMarker == nil or marker.order > lastMarker.order) then
                lastMarker = marker
            end
        end
    end
    
    return lastMarker
end

function ml_marker_mgr.GetNextMarker(markerType, filterLevel)
    if (gMarkerMgrMode == strings[gCurrentLanguage].singleMarker) then
        if (ValidTable(ml_marker_mgr.currentMarker) and
			ml_marker_mgr.currentMarker:GetType() ~= markerType) 
		then
			local markerName = Settings.minionlib.lastSelectedMarker[markerType]
			if (markerName) then
				local marker = ml_marker_mgr.GetMarker(markerName)
				if (marker) then
					ml_marker_mgr.currentMarker = marker
					return marker
				end
			else
				ml_debug("Error in GetNextMarker_SingleMode - nil entry for last marker of type "..markerType)
			end
        else
            local marker = ml_marker_mgr.GetMarker(gMarkerMgrName)
            if (marker) then
                ml_marker_mgr.currentMarker = marker
                return marker
            else
                ml_debug("Error in GetNextMarker_SingleMode - no marker found matching "..gMarkerMgrName)
            end
        end
    elseif (gMarkerMgrMode == strings[gCurrentLanguage].randomMarker) then
        local list = ml_marker_mgr.GetList(markerType, true, filterLevel)
        if (ValidTable(list)) then
            local marker = GetRandomTableEntry(list)
            if (ValidTable(marker)) then
                ml_marker_mgr.currentMarker = marker
                return marker
            end
        end
    elseif (gMarkerMgrMode == strings[gCurrentLanguage].markerList) then
        --lots of repeat code in this conditional. many of these cases could be dumped together but
        --keeping them separate for now in case we decide to handle one differently during testing
        local list = ml_marker_mgr.GetListByOrder(markerType, filterLevel)
        if (ValidTable(list)) then
			-- compress the list indices so that we can iterate through them properly
            local counter = 1
            for order, marker in pairsByKeys(list) do
				--d("Order:"..tostring(order)..",Counter:"..tostring(counter)..",Marker:"..tostring(marker:GetName()))
                list[counter] = marker
                counter = counter + 1
            end
			
			local firstMarker = list[1]
			
            if (ValidTable(ml_marker_mgr.currentMarker)) then
                if (ml_marker_mgr.currentMarker:GetType() == markerType) then
					--d("Marker Type:"..tostring(markerType))
                    --get the next marker in the sequence
					local nextMarker = nil
					for index, marker in pairsByKeys(list) do
						--d("Current Order:"..tostring(ml_marker_mgr.currentMarker.order))
						if (marker.order == ml_marker_mgr.currentMarker.order) then
							d("Returning index:"..tostring(index+1))
							nextMarker = list[index+1]
							break
						end
					end
                    if (nextMarker) then
						--d("nextMarker exists, return it:"..tostring(nextMarker:GetName()))
                        ml_marker_mgr.currentMarker = nextMarker
                        return nextMarker
                    else
                        ml_debug("GetNextMarker end of list - returning first marker for type "..markerType)
						--d("nextMarker doesnt exist, return first:"..tostring(firstMarker:GetName()))
                        ml_marker_mgr.currentMarker = firstMarker
                        return firstMarker
                    end
                else
                    ml_debug("Type "..markerType.." is not the same as current marker type. Returning first marker in list")
					--d("markerType is not equal, return first:"..tostring(firstMarker:GetName()))
                    ml_marker_mgr.currentMarker = firstMarker
                    return firstMarker
                end
            else
				--d("Returning first marker"..firstMarker:GetName())
                ml_marker_mgr.currentMarker = firstMarker
                return firstMarker
            end
        else
			ml_debug("No markers returned for params")
		end
    end
    
    ml_debug("Error in ml_marker_mgr.GetNextMarker()")       
end
function ml_marker_mgr.GetClosestMarker( x, y, z, radius, markertype)
    		
	local closestmarker
	local closestmarkerdistance
	if ( TableSize(ml_marker_mgr.markerList) > 0 ) then
		for mtype,_ in pairs(ml_marker_mgr.markerList) do
			
			if ( not markertype or mtype == markertype ) then
				
				local markerlist = ml_marker_mgr.GetList(mtype, false)
				
				if ( TableSize(markerlist) > 0 ) then
				
					for name, marker in pairs(markerlist) do
						if ( type(marker) == "table" ) then
							mpos = marker:GetPosition()
							if (TableSize(mpos)>0) then
								local dist = Distance3D ( mpos.x, mpos.y, mpos.z, x, y, z) 
								if ( dist < radius and ( closestmarkerdistance == nil or closestmarkerdistance > dist ) ) then
									closestmarkerdistance = dist
									closestmarker = marker				
								end
							end
						else
							d("Error in ml_marker_mgr.GetClosestMarker, type(marker) != table")
						end
					end
				end
			end
		end
	end
    
    return closestmarker
end

--LIST MODIFICATION FUNCTIONS
function ml_marker_mgr.AddMarker(newMarker)
	if (not newMarker:GetName() or not newMarker:GetType()) then
		ml_debug("Invalid marker - No name or type specified")
		return false
	end
		
	local found = false
	
	for _, list in pairs(ml_marker_mgr.markerList) do
		for name, marker in pairs(list) do
			if (name == newMarker:GetName()) then
				ml_debug("Marker "..newMarker:GetName().." cannot be added because another marker with that name already exists")
				return false
			end
		end
	end
	
    -- Set the marker order to be next in the list
    local lastMarker = ml_marker_mgr.GetLastMarker(newMarker:GetType())
    if (lastMarker) then
        newMarker.order = lastMarker.order + 1
    else
        newMarker.order = 1
    end
    
	local markerList = ml_marker_mgr.markerList[newMarker:GetType()]
	if not markerList then
		markerList = {}
		ml_marker_mgr.markerList[newMarker:GetType()] = markerList
	end
	
	markerList[newMarker:GetName()] = newMarker
	ml_marker_mgr.renderList[newMarker:GetName()] = ml_marker_mgr.DrawMarker(newMarker)
	
	return true
end

function ml_marker_mgr.AddMarkerTemplate(templateMarker)
    if (ValidTable(templateMarker)) then
        ml_marker_mgr.templateList[templateMarker:GetType()] = templateMarker
    end
end

function ml_marker_mgr.DeleteMarker(oldMarker)
	if ( ml_marker_mgr.markerPath == "" or not FileExists(ml_marker_mgr.markerPath)) then
		d("ml_marker_mgr.DeleteMarker: Invalid MarkerPath : "..ml_marker_mgr.markerPath)
		return false
	end
	
	if type(oldMarker) == "string" then
		oldMarker = ml_marker_mgr.GetMarker(oldMarker)
	end
	
	if (not oldMarker:GetName()) then
		ml_debug("Invalid marker - No name specified")
		return false
	end
	
	for _, list in pairs(ml_marker_mgr.markerList) do
		for name, marker in pairs(list) do
			if (name == oldMarker:GetName()) then
				list[name] = nil
				--RenderManager:RemoveObject(ml_marker_mgr.renderList[name]) -- this does not work out of some magically unknown reason
				ml_marker_mgr.renderList[name] = nil
				ml_marker_mgr.WriteMarkerFile(ml_marker_mgr.markerPath)
				GUI_WindowVisible(ml_marker_mgr.editwindow.name, false)
				ml_marker_mgr.DrawMarkerList() -- added this for now to refresh the drawn markers after deleting one..seems to do the job fine
				return true
			end
		end
	end
	
	return false
end

function ml_marker_mgr.NewMarker()
	local templateMarker = ml_marker_mgr.currentEditMarker
	local newMarker = nil
	if (ValidTable(templateMarker)) then
		newMarker = templateMarker:Copy()
	else
        templateMarker = ml_marker_mgr.templateList[gMarkerMgrType]
		if (ValidTable(templateMarker)) then
			newMarker = templateMarker:Copy()
			newMarker:SetName(newMarker:GetType())
		else
			ml_error("No Marker Types defined!")			
		end
	end
	
	if (ValidTable(newMarker)) then
		--add a random number onto the name until the string is unique
		local name = ""
		local tries = 0
		repeat
			name = newMarker:GetName()..tostring(math.random(1,99))
			-- just a little check here to ensure we never get stuck in an infinite loop
			-- if somehow some idiot has the same marker name with 1-99 already
			tries = tries + 1
		until ml_marker_mgr.GetMarker(name) == nil or tries > 99
		
		newMarker:SetName(name)
		newMarker:SetPosition(ml_marker_mgr.GetPosition())
		ml_marker_mgr.AddMarker(newMarker)
		ml_marker_mgr.CreateEditWindow(newMarker)
		ml_marker_mgr.RefreshMarkerNames()
	end
end

function ml_marker_mgr.AddMarkerToList()
	local marker = ml_marker_mgr.GetMarker(gMarkerMgrName)
	if (ValidTable(marker) and marker.order == 0) then
		local lastMarker = ml_marker_mgr.GetLastMarker(gMarkerMgrType)
		if (ValidTable(lastMarker)) then
			marker.order = lastMarker.order + 1
			ml_marker_mgr.RefreshMarkerNames()
		else
			marker.order = 1
			ml_marker_mgr.RefreshMarkerNames()
		end
	end
end

-- iterates through marker list with order gaps and compresses the order values
function ml_marker_mgr.CleanMarkerOrder(markerType)
    local list = ml_marker_mgr.GetList(markerType, true)
    if (ValidTable(list)) then
        local orderedList = {}
		
        for name, marker in pairs(list) do
            orderedList[marker.order] = marker
        end
        
        if (ValidTable(orderedList)) then
            local counter = 1
            for order, marker in spairs(orderedList) do
                marker.order = counter
                counter = counter + 1
            end
        end
	
		for name, marker in pairs(ml_marker_mgr.markerList[markerType]) do
			for order, modMarker in pairs(orderedList) do
				if modMarker.name == name then
					marker.order = order
				end
			end
		end
		if ( ml_marker_mgr.markerPath == "" or not FileExists(ml_marker_mgr.markerPath)) then
			d("ml_marker_mgr.CleanMarkerOrder: Invalid MarkerPath : "..ml_marker_mgr.markerPath)
			return false
		end
		ml_marker_mgr.WriteMarkerFile(ml_marker_mgr.markerPath)
    end
end

function ml_marker_mgr.ClearMarkerList()
	ml_marker_mgr.markerList = {}
	ml_marker_mgr.renderList = {}
	RenderManager:RemoveAllObjects()
	ml_marker_mgr.markersLoaded = false
end

function ml_marker_mgr.DrawMarkerList()
    ml_marker_mgr.renderList = {}
    RenderManager:RemoveAllObjects()
    
    --only draw templated markers
    for markerType, marker in pairs(ml_marker_mgr.templateList) do
        local list = ml_marker_mgr.GetList(markerType)
        if (ValidTable(list)) then
            for name, marker in pairs(list) do
                ml_marker_mgr.DrawMarker(marker)
            end
        end
    end
end

--IO FUNCTIONS
function ml_marker_mgr.ReadMarkerFile(path)
	local markerList = persistence.load(path)

	-- needs to be set, else the whole markermanager breaks when a mesh without a .info file is beeing loaded
	if ( ValidString(path) ) then
		ml_marker_mgr.markerPath = path
	end

	if (ValidTable(markerList)) then
		ml_marker_mgr.markerList = markerList
		for type, list in pairs(ml_marker_mgr.markerList) do
			local templateMarker = ml_marker_mgr.templateList[type]
			if (ValidTable(templateMarker)) then
				for name, marker in pairs(list) do
					-- set marker class metatable for each marker
					setmetatable(marker, {__index = ml_marker})
					
					for name, fieldTable in pairs(templateMarker.fields) do
						if (not marker:HasField(name)) then
							marker:AddField(templateMarker:GetFieldType(name), name, templateMarker:GetFieldValue(name))
						end
					end
				end
			end
		end
		
		ml_marker_mgr.markersLoaded = true
	else
		ml_debug("Invalid path specified for marker file")
	end
end

function ml_marker_mgr.WriteMarkerFile(path)
	if ( path == "" ) then
		d("ml_marker_mgr.WriteMarkerFile: Invalid Path : "..path)
		return false
	end
	persistence.store(path, ml_marker_mgr.markerList)
end

--GUI Refresh Functions
function ml_marker_mgr.RefreshMarkerTypes()
	if (ValidTable(ml_marker_mgr.templateList)) then
        local typestring = ""
        local found = false
        local first = nil
		for name, marker in pairs(ml_marker_mgr.templateList) do
            if (typestring == "") then
                typestring = marker:GetType()
                first = typestring
            else
                typestring = typestring..","..marker:GetType()
            end
            
            if (marker:GetType() == gMarkerMgrType) then
                found = true
            end
        end
		
		gMarkerMgrType_listitems = typestring
        
        if (not found or gMarkerMgrType == "") then
            gMarkerMgrType = first
        end
	end
end

function ml_marker_mgr.RefreshMarkerNames()
	if (ValidTable(ml_marker_mgr.markerList)) then
		ml_marker_mgr.CleanMarkerOrder(gMarkerMgrType)
		
		local list = ml_marker_mgr.GetList(gMarkerMgrType, false)
		if (ValidTable(list)) then
			local markerNameList = GetComboBoxList(list)
			local namestring = ""
			if (markerNameList) then
				namestring = markerNameList["keyList"]
				local markerList = ml_marker_mgr.markerList[gMarkerMgrType]
				if (gMarkerMgrName == "" or not markerList or markerList[gMarkerMgrName] == nil) then
					gMarkerMgrName = markerNameList["firstKey"] or ""
					
					--if we've never selected a marker for this type then save the first marker
					if (gMarkerMgrName ~= "") then
						Settings.minionlib.lastSelectedMarker[gMarkerMgrType] = gMarkerMgrName
						Settings.minionlib.lastSelectedMarker = Settings.minionlib.lastSelectedMarker
					elseif (gMarkerMgrName == "") then
						ml_marker_mgr.WipeEditWindow()
					end
				end
			end
			
			gMarkerMgrName_listitems = namestring
			ml_marker_mgr.RefreshMarkerList()
		else
			gMarkerMgrName_listitems = ""
			ml_marker_mgr.RefreshMarkerList()
		end
	end
end

function ml_marker_mgr.RefreshMarkerList()
	if (ValidTable(ml_marker_mgr.markerList)) then
	
		ml_marker_mgr.CleanMarkerOrder(gMarkerMgrType)
		
		local window = GUI_GetWindowInfo(ml_marker_mgr.mainwindow.name)
		GUI_DeleteGroup(ml_marker_mgr.mainwindow.name, strings[gCurrentLanguage].markerList)
		
		local markerTable = {}
		local markerList = ml_marker_mgr.GetList(gMarkerMgrType, true)
		if (markerList) then
			for name, marker in pairs(markerList) do
				markerTable[marker.order] = marker
			end
		end
		
		if (TableSize(markerTable) > 0) then
			for index, marker in pairsByKeys(markerTable) do
				GUI_NewButton(ml_marker_mgr.mainwindow.name,marker:GetName(),"Marker_" .. tostring(marker:GetName()),strings[gCurrentLanguage].markerList)
			end
		end
		
		GUI_UnFoldGroup(ml_marker_mgr.mainwindow.name, strings[gCurrentLanguage].markerList)
		GUI_SizeWindow(ml_marker_mgr.mainwindow.name, window.width, window.height)
	end
end

function ml_marker_mgr.CreateEditWindow(marker)
	if (ValidTable(marker)) then
		ml_marker_mgr.currentEditMarker = marker
		
		local templateMarker = ml_marker_mgr.templateList[gMarkerMgrType]
		for fieldName, fieldTable in pairs(templateMarker.fields) do
			if not (marker:HasField(fieldName)) then
				marker:AddField(marker:GetFieldType(fieldName), fieldName, marker:GetFieldValue(fieldName))
			end
		end
		
		GUI_DeleteGroup(ml_marker_mgr.editwindow.name, strings[gCurrentLanguage].markerFields)
		local fieldNames = marker:GetFieldNames()
		if (ValidTable(fieldNames)) then
			for _, name in pairsByKeys(fieldNames) do
				local fieldType = marker:GetFieldType(name)
				if (fieldType == "float" or fieldType == "string") then
					GUI_NewField(ml_marker_mgr.editwindow.name,name,"Field_"..name, strings[gCurrentLanguage].markerFields)
				elseif (fieldType == "int") then
					GUI_NewNumeric(ml_marker_mgr.editwindow.name,name,"Field_"..name, strings[gCurrentLanguage].markerFields)
				elseif (fieldType == "button") then
					GUI_NewButton(ml_marker_mgr.editwindow.name,name,"Field_"..name, strings[gCurrentLanguage].markerFields)
				elseif (fieldType == "checkbox") then
					GUI_NewCheckbox(ml_marker_mgr.editwindow.name,name,"Field_"..name, strings[gCurrentLanguage].markerFields)
				end
				
				if (fieldType ~= "button") then
					_G["Field_"..name] = marker:GetFieldValue(name)
				end
			end
		end
		
		GUI_UnFoldGroup(ml_marker_mgr.editwindow.name, strings[gCurrentLanguage].markerFields)
		GUI_SizeWindow(ml_marker_mgr.editwindow.name,ml_marker_mgr.editwindow.w,ml_marker_mgr.editwindow.h)
		GUI_WindowVisible(ml_marker_mgr.editwindow.name, true)
	end
end

function ml_marker_mgr.WipeEditWindow()
	ml_marker_mgr.currentEditMarker = nil
	GUI_WindowVisible(ml_marker_mgr.editwindow.name, false)
end

-- GUI/Eventhandler functions
function ml_marker_mgr.HandleInit()
	if (Settings.minionlib.gMarkerMgrMode == nil) then
		Settings.minionlib.gMarkerMgrMode = strings[gCurrentLanguage].markerList
	end
    
    if (Settings.minionlib.lastSelectedMarker == nil) then
        Settings.minionlib.lastSelectedMarker = {}
    end

    -- main window
	GUI_NewWindow(ml_marker_mgr.mainwindow.name,ml_marker_mgr.mainwindow.x,ml_marker_mgr.mainwindow.y,ml_marker_mgr.mainwindow.w,ml_marker_mgr.mainwindow.h)
	GUI_NewComboBox(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].markerMode,"gMarkerMgrMode",strings[gCurrentLanguage].generalSettings,"")
    GUI_NewComboBox(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].markerType,"gMarkerMgrType",strings[gCurrentLanguage].generalSettings,"")
    GUI_NewComboBox(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].markerName,"gMarkerMgrName",strings[gCurrentLanguage].generalSettings,"")
	GUI_NewButton(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].addMarker,"ml_marker_mgr.AddMarkerToList",strings[gCurrentLanguage].generalSettings)
	RegisterEventHandler("ml_marker_mgr.AddMarkerToList",ml_marker_mgr.AddMarkerToList)
	GUI_NewButton(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].newMarker,"ml_marker_mgr.NewMarker",strings[gCurrentLanguage].generalSettings)
	RegisterEventHandler("ml_marker_mgr.NewMarker",ml_marker_mgr.NewMarker)
	
	-- setup marker mode list
	gMarkerMgrMode_listitems = strings[gCurrentLanguage].markerList..","..strings[gCurrentLanguage].singleMarker..","..strings[gCurrentLanguage].randomMarker
	gMarkerMgrMode = Settings.minionlib.gMarkerMgrMode
	
	GUI_UnFoldGroup(ml_marker_mgr.mainwindow.name, strings[gCurrentLanguage].generalSettings)
	GUI_SizeWindow(ml_marker_mgr.mainwindow.name, ml_marker_mgr.mainwindow.w, ml_marker_mgr.mainwindow.h)
    GUI_WindowVisible(ml_marker_mgr.mainwindow.name,false)
    
    -- marker editor window
    GUI_NewWindow(ml_marker_mgr.editwindow.name, ml_marker_mgr.mainwindow.x+ml_marker_mgr.mainwindow.w, ml_marker_mgr.mainwindow.y, ml_marker_mgr.editwindow.w, ml_marker_mgr.editwindow.h)
    GUI_NewField(ml_marker_mgr.editwindow.name, "Placeholder", "gPlaceholder", strings[gCurrentLanguage].markerFields)
    GUI_NewButton(ml_marker_mgr.editwindow.name,strings[gCurrentLanguage].deleteMarker,"ml_marker_mgr.DeleteMarker")
	GUI_NewButton(ml_marker_mgr.editwindow.name,strings[gCurrentLanguage].removeMarker,"ml_marker_mgr.RemoveMarker")
    GUI_NewButton(ml_marker_mgr.editwindow.name,strings[gCurrentLanguage].questDown,"ml_marker_mgr.MarkerDown")	
    GUI_NewButton(ml_marker_mgr.editwindow.name,strings[gCurrentLanguage].questUp,"ml_marker_mgr.MarkerUp")
    GUI_SizeWindow(ml_marker_mgr.editwindow.name,ml_marker_mgr.editwindow.w,ml_marker_mgr.editwindow.h)
    GUI_WindowVisible(ml_marker_mgr.editwindow.name,false)
	
	gMarkerMgrMode = Settings.minionlib.gMarkerMgrMode
end

function ml_marker_mgr.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
		if 	(k == "gMarkerMgrType") then
			ml_marker_mgr.RefreshMarkerNames()
			GUI_WindowVisible(ml_marker_mgr.editwindow.name,false)
			ml_marker_mgr.currentEditMarker = nil
		elseif (string.sub(k,1,6) == "Field_") then
			d("edited field = "..tostring(string.sub(k,7)))
			local name = string.sub(k,7)
			if (ValidTable(ml_marker_mgr.currentEditMarker)) then
				local value = nil
				if (ml_marker_mgr.currentEditMarker:GetFieldType(name) == "string") then
					value = v
				elseif (ml_marker_mgr.currentEditMarker:GetFieldType(name) == "checkbox") then
					d("value is a checkbox type, v ="..tostring(v))
					value = tostring(v)
				else
					value = tonumber(v)
				end
				
				--handle special case when name field is changed
				if (name == "Name") then
					local list = ml_marker_mgr.markerList[gMarkerMgrType]
					if (list) then
						--if another marker with this name exists then don't allow the update
						if(list[value] ~= nil) then
							return
						end
						list[ml_marker_mgr.currentEditMarker:GetFieldValue("Name")] = nil
						list[value] = ml_marker_mgr.currentEditMarker
					end
				end
				ml_marker_mgr.currentEditMarker:SetFieldValue(name, value)
				if (name == "Name") then 
					ml_marker_mgr.RefreshMarkerNames() 
				end
				if ( ml_marker_mgr.markerPath == "" or not FileExists(ml_marker_mgr.markerPath)) then
					d("ml_marker_mgr.GUIVarUpdate: Invalid MarkerPath : "..ml_marker_mgr.markerPath)
				else
					ml_marker_mgr.WriteMarkerFile(ml_marker_mgr.markerPath)
				end				
			end
		elseif (k == "gMarkerMgrName") then
			if (v ~= "") then
				Settings.minionlib.lastSelectedMarker[gMarkerMgrType] = gMarkerMgrName
				Settings.minionlib.lastSelectedMarker = Settings.minionlib.lastSelectedMarker
			end
		elseif (k == "gMarkerMgrMode") then
			Settings.minionlib.gMarkerMgrMode = v
		end
	end
end

function ml_marker_mgr.GUIItem( evnttype , event )
    local tokenlen = string.len("Marker_")
	local writeFile = false
    if (string.sub(event,1,tokenlen) == "Marker_") then
        local name = string.sub(event,tokenlen+1)
        local marker = ml_marker_mgr.GetMarker(name)
        if (marker) then
            ml_marker_mgr.CreateEditWindow(marker)
        end
    elseif (event == "ml_marker_mgr.RemoveMarker") then
		if (ValidTable(ml_marker_mgr.currentEditMarker)) then
			ml_marker_mgr.currentEditMarker.order = 0
            ml_marker_mgr.CleanMarkerOrder(ml_marker_mgr.currentEditMarker:GetType())
			ml_marker_mgr.RefreshMarkerList()
			writeFile = true
		end
	elseif (event == "ml_marker_mgr.MarkerUp") then
		if (ValidTable(ml_marker_mgr.currentEditMarker)) then
			local temp = ml_marker_mgr.currentEditMarker.order
			local tempMarker = ml_marker_mgr.GetMarkerByOrder(gMarkerMgrType, temp - 1)
			if (ValidTable(tempMarker)) then
				tempMarker.order = temp
				ml_marker_mgr.currentEditMarker.order = temp - 1
				ml_marker_mgr.RefreshMarkerList()
				writeFile = true
			end
		end
	elseif (event == "ml_marker_mgr.MarkerDown") then
		if (ValidTable(ml_marker_mgr.currentEditMarker)) then
			local temp = ml_marker_mgr.currentEditMarker.order
			d(temp)
			local tempMarker = ml_marker_mgr.GetMarkerByOrder(gMarkerMgrType, temp + 1)
			if (ValidTable(tempMarker)) then
				tempMarker.order = temp
				ml_marker_mgr.currentEditMarker.order = temp + 1
				ml_marker_mgr.RefreshMarkerList()
				writeFile = true
			end
		end
	elseif (event == "ml_marker_mgr.DeleteMarker") then
		if (ValidTable(ml_marker_mgr.currentEditMarker)) then
			ml_marker_mgr.DeleteMarker(ml_marker_mgr.currentEditMarker)
			ml_marker_mgr.RefreshMarkerTypes()
			ml_marker_mgr.RefreshMarkerNames()
			writeFile = true
		end
	end
	
	if (writeFile) then
		ml_marker_mgr.WriteMarkerFile(ml_marker_mgr.markerPath)
	end
end

function ml_marker_mgr.ToggleMenu()
    if (ml_marker_mgr.visible) then
        GUI_WindowVisible(ml_marker_mgr.mainwindow.name,false)
		GUI_WindowVisible(ml_marker_mgr.editwindow.name,false)
        ml_marker_mgr.visible = false
    else
        local wnd = GUI_GetWindowInfo(ml_marker_mgr.parentWindow.Name)
        if (wnd) then
            GUI_MoveWindow( ml_marker_mgr.mainwindow.name, wnd.x+wnd.width,wnd.y) 
            GUI_WindowVisible(ml_marker_mgr.mainwindow.name,true)
        end
        
        ml_marker_mgr.visible = true
    end
end

function ml_marker_mgr.SetupTest()
	local grindMarker = ml_marker:Create("grindTemplate")
	grindMarker:SetType("Grind Marker")
	grindMarker:AddField("contentID=", string, "")
	grindMarker:AddField("NOTcontentID=", string, "")
	
	local botanyMarker = ml_marker:Create("botanyTemplate")
	botanyMarker:SetType("Botany Marker")
	botanyMarker:AddField("Priority 1 Item", string, "")
	botanyMarker:AddField("Priority 2 Item", string, "")
	
	local miningMarker = botanyMarker:Copy()
	miningMarker:SetName("miningTemplate")
	miningMarker:SetType("Mining Marker")
	
	
	if (TableSize(ml_marker_mgr.markerList) == 0) then
		local testMarker1 = ml_marker:Create("testMarker1")
		testMarker1:SetType("grindMarker")
		
		local testMarker2 = ml_marker:Create("testMarker2")
		testMarker2:SetType("grindMarker")
		
		local testMarker3 = ml_marker:Create("testMarker3")
		testMarker3:SetType("botanyMarker")
		
		--markers to test remove
		local testMarker4 = ml_marker:Create("testMarker4")
		testMarker4:SetType("grindMarker")
		
		local testMarker5 = ml_marker:Create("testMarker5")
		testMarker5:SetType("botanyMarker")
		
		ml_marker_mgr.AddMarker(testMarker1)
		ml_marker_mgr.AddMarker(testMarker2)
		ml_marker_mgr.AddMarker(testMarker3)
		ml_marker_mgr.AddMarker(testMarker4)
		ml_marker_mgr.AddMarker(testMarker5)
		
		-- remove via marker reference
		ml_marker_mgr.DeleteMarker(testMarker4)
		
		-- remove via string
		ml_marker_mgr.DeleteMarker("testMarker5")
		
		-- refresh markers for GUI
		gMarkerMgrType = "grindMarker"
		ml_marker_mgr.RefreshMarkerTypes()
		ml_marker_mgr.RefreshMarkerNames()
		ml_marker_mgr.RefreshMarkerList()
		ml_marker_mgr.WriteMarkerFile(ml_marker_mgr.profilePath)
	end
end

RegisterEventHandler("ToggleMarkerMgr", ml_marker_mgr.ToggleMenu)
RegisterEventHandler("Module.Initalize",ml_marker_mgr.HandleInit)
RegisterEventHandler("GUI.Update",ml_marker_mgr.GUIVarUpdate)
RegisterEventHandler("GUI.Item",ml_marker_mgr.GUIItem)
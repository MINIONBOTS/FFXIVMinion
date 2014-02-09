--ml_marker_mgr is a gwen GUI for editing general marker information
--it should ALWAYS remain independent from any game-specific data

ml_marker_mgr = {}
ml_marker_mgr.mainwindow =  { name = strings[gCurrentLanguage].markerManager,    x = 340, y = 50, w = 250, h = 300}
ml_marker_mgr.editwindow =  { name = strings[gCurrentLanguage].editMarker,       w = 250, h = 300}
ml_marker_mgr.markerList = {}
ml_marker_mgr.version = 1.0
ml_marker_mgr.currentMarker = {}
ml_marker_mgr.parentWindow = nil
--temporary path for testing - will be set by game code 
ml_marker_mgr.markerPath = GetStartupPath()..[[\Navigation\]].."markerTests.txt"

-- backend functions
function ml_marker_mgr.GetList(markerType, filterEnabled)
	local list = ml_marker_mgr.markerList[markerType]
	local newlist = {}
	
	if (list) then
		for name, marker in pairs(list) do
			if (not filterEnabled or marker.order > 0) then
				newlist[name] = marker
			end
		end
	end
	
	return newlist
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
	return true
end

function ml_marker_mgr.DeleteMarker(oldMarker)
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
				return true
			end
		end
	end
	
	return false
end

function ml_marker_mgr.ReadMarkerFile(path)
	local markerList = persistence.load(path)
	if (ValidTable(markerList)) then
		ml_marker_mgr.markerList = markerList
		for type, list in pairs(ml_marker_mgr.markerList) do
			for name, marker in pairs(list) do
				-- set marker class metatable for each marker
				setmetatable(marker, {__index = ml_marker})
			end
		end
	else
		ml_debug("Invalid path specified for marker file")
	end
end

function ml_marker_mgr.WriteMarkerFile(path)
	persistence.store(path, ml_marker_mgr.markerList)
end

function ml_marker_mgr.HandleInit()

	if (Settings.minionlib.gMarkerMgrMode == nil) then
		Settings.minionlib.gMarkerMgrMode = strings[gCurrentLanguage].markerList
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
	
    -- setup marker type list
    local markerTypeList = GetComboBoxList(ml_marker_mgr.markerList)
    gMarkerMgrType_listitems = markerTypeList["keyList"]
    gMarkerMgrType = markerTypeList["firstKey"]
	
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
	
	ml_marker_mgr.ReadMarkerFile(ml_marker_mgr.markerPath)
	ml_marker_mgr.RefreshMarkerTypes()
	ml_marker_mgr.RefreshMarkerNames()
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

function ml_marker_mgr.RefreshMarkerTypes()
	if (ValidTable(ml_marker_mgr.markerList)) then
		local markerTypeList = GetComboBoxList(ml_marker_mgr.markerList)
		local typestring = ""
		if (markerTypeList) then
			typestring = markerTypeList["keyList"]
			if (gMarkerMgrType == "" or ml_marker_mgr[gMarkerMgrType] == nil) then
				gMarkerMgrType = markerTypeList["firstKey"]
			end
		end
		
		gMarkerMgrType_listitems = typestring
	end
end

function ml_marker_mgr.RefreshMarkerNames()
	if (ValidTable(ml_marker_mgr.markerList)) then
		local markerNameList = GetComboBoxList(ml_marker_mgr.markerList[gMarkerMgrType])
		local namestring = ""
		if (markerNameList) then
			namestring = markerNameList["keyList"]
			local markerList = ml_marker_mgr.markerList[gMarkerMgrType]
			if (gMarkerMgrName == "" or markerList[gMarkerMgrName] == nil) then
				gMarkerMgrName = markerNameList["firstKey"]
			end
		end
		
		gMarkerMgrName_listitems = namestring
		
		ml_marker_mgr.RefreshMarkerList()
	end
end

function ml_marker_mgr.RefreshMarkerList()
	if (ValidTable(ml_marker_mgr.markerList)) then
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

function ml_marker_mgr.ToggleMenu()
    if (ml_marker_mgr.visible) then
        GUI_WindowVisible(ml_marker_mgr.mainwindow.name,false)	
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

function ml_marker_mgr.AddMarkerToList()
	local marker = ml_marker_mgr.GetMarker(gMarkerMgrName)
	if (ValidTable(marker) and marker.order == 0) then
		local lastMarker = ml_marker_mgr.GetLastMarker(gMarkerMgrType)
		if (ValidTable(lastMarker)) then
			marker.order = lastMarker.order + 1
			ml_marker_mgr.RefreshMarkerNames()
		end
	end
end

function ml_marker_mgr.NewMarker()
	local templateMarker = ml_marker_mgr.currentMarker
	local newMarker = nil
	if (ValidTable(templateMarker)) then
		newMarker = templateMarker:Copy()
	else
		newMarker = ml_marker:Create("new_marker")
		newMarker:SetType(gMarkerMgrType)
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
		ml_marker_mgr.AddMarker(newMarker)
		ml_marker_mgr.CreateEditWindow(newMarker)
		ml_marker_mgr.RefreshMarkerNames()
	end
end

function ml_marker_mgr.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
		if 	(k == "gMarkerMgrType") then
			ml_marker_mgr.RefreshMarkerNames()
		elseif (string.sub(k,1,6) == "Field_") then
			local name = string.sub(k,7)
			if (ValidTable(ml_marker_mgr.currentMarker)) then
				local value = nil
				if (ml_marker_mgr.currentMarker:GetFieldType(name) == "string") then
					value = v
				else
					value = tonumber(v)
				end
				
				--handle special case when name field is changed
				if (name == "name") then
					local list = ml_marker_mgr.markerList[gMarkerMgrType]
					if (list) then
						d(list[ml_marker_mgr.currentMarker:GetFieldValue("name")])
						list[ml_marker_mgr.currentMarker:GetFieldValue("name")] = nil
						list[value] = ml_marker_mgr.currentMarker
					end
				end
				ml_marker_mgr.currentMarker:SetFieldValue(name, value)
				if (name == "name") then ml_marker_mgr.RefreshMarkerNames() end
				ml_marker_mgr.WriteMarkerFile(ml_marker_mgr.markerPath)
			end
		end
	end
end

function ml_marker_mgr.GUIItem( evnttype , event )
    local tokenlen = string.len("Marker_")
    if (string.sub(event,1,tokenlen) == "Marker_") then
        local name = string.sub(event,tokenlen+1)
        local marker = ml_marker_mgr.GetMarker(name)
        if (marker) then
            ml_marker_mgr.CreateEditWindow(marker)
        end
    elseif (event == "ml_marker_mgr.RemoveMarker") then
		if (ValidTable(ml_marker_mgr.currentMarker)) then
			ml_marker_mgr.currentMarker.order = 0
			ml_marker_mgr.RefreshMarkerList()
		end
	elseif (event == "ml_marker_mgr.MarkerUp") then
		if (ValidTable(ml_marker_mgr.currentMarker)) then
			local temp = ml_marker_mgr.currentMarker.order
			local tempMarker = ml_marker_mgr.GetMarkerByOrder(gMarkerMgrType, temp - 1)
			if (ValidTable(tempMarker)) then
				tempMarker.order = temp
				ml_marker_mgr.currentMarker.order = temp - 1
				ml_marker_mgr.RefreshMarkerList()
			end
		end
	elseif (event == "ml_marker_mgr.MarkerDown") then
		if (ValidTable(ml_marker_mgr.currentMarker)) then
			local temp = ml_marker_mgr.currentMarker.order
			d(temp)
			local tempMarker = ml_marker_mgr.GetMarkerByOrder(gMarkerMgrType, temp + 1)
			if (ValidTable(tempMarker)) then
				tempMarker.order = temp
				ml_marker_mgr.currentMarker.order = temp + 1
				ml_marker_mgr.RefreshMarkerList()
			end
		end
	elseif (event == "ml_marker_mgr.DeleteMarker") then
		if (ValidTable(ml_marker_mgr.currentMarker)) then
			ml_marker_mgr.DeleteMarker(ml_marker_mgr.currentMarker)
			ml_marker_mgr.RefreshMarkerTypes()
			ml_marker_mgr.RefreshMarkerNames()
		end
	end
end

function ml_marker_mgr.CreateEditWindow(marker)
	if (ValidTable(marker)) then
		ml_marker_mgr.currentMarker = marker
		GUI_DeleteGroup(ml_marker_mgr.editwindow.name, strings[gCurrentLanguage].markerFields)

		local fieldNames = marker:GetFieldNames()
		if (ValidTable(fieldNames)) then
			for _, name in pairsByKeys(fieldNames) do
				local fieldType = marker:GetFieldType(name)
				if (fieldType == "float" or fieldType == "string") then
					GUI_NewField(ml_marker_mgr.editwindow.name,name,"Field_"..name, strings[gCurrentLanguage].markerFields)
				elseif (fieldType == "int") then
					GUI_NewNumeric(ml_marker_mgr.editwindow.name,name,"Field_"..name, strings[gCurrentLanguage].markerFields)
				end
				_G["Field_"..name] = marker:GetFieldValue(name)
			end
		end
		
		GUI_UnFoldGroup(ml_marker_mgr.editwindow.name, strings[gCurrentLanguage].markerFields)
		GUI_WindowVisible(ml_marker_mgr.editwindow.name, true)
	end
end

function ml_marker_mgr.SetupTest()
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
RegisterEventHandler("Module.Initalize",ml_marker_mgr.SetupTest)
RegisterEventHandler("GUI.Update",ml_marker_mgr.GUIVarUpdate)
RegisterEventHandler("GUI.Item",ml_marker_mgr.GUIItem)
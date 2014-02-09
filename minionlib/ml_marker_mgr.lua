--ml_marker_mgr is a gwen GUI for editing general marker information

ml_marker_mgr = {}
ml_marker_mgr.mainwindow =  { name = strings[gCurrentLanguage].markerManager,    x = 340, y = 50, w = 335, h = 200}
ml_marker_mgr.editwindow =  { name = strings[gCurrentLanguage].editMarker,       w = 250, h = 550}
ml_marker_mgr.markerList = {}
ml_marker_mgr.markerList.editList = {}
ml_marker_mgr.markerList.editList.editList = {}
ml_marker_mgr.markerList.editList.orderList = {}
ml_marker_mgr.version = 1.0

-- backend functions
function ml_marker_mgr.GetList(markerType, filterEnabled)
	local list = ml_marker_mgr.markerList.editList.editList[markerType]
	
	if filterEnabled then
		-- filter only enabled markers
		local newlist = {}
		for name, marker in pairs(list) do
			if marker.enabled then
				newlist[name] = marker
			end
		end
		
		list = newlist
	end
	
	return list
end

function ml_marker_mgr.GetMarker(markerName)
	for _, list in pairs(ml_marker_mgr.markerList.editList) do
		for name, marker in pairs(list) do
			if (name == markerName) then
				return marker
			end
		end
	end
	
	ml_debug("No marker data for marker name "..markerName.." found in the marker list")
	return nil
end

function ml_marker_mgr.AddMarker(newMarker)
	if (not newMarker:GetName() or not newMarker:GetType()) then
		ml_debug("Invalid marker - No name or type specified")
		return false
	end
		
	local found = false
	
	for _, list in pairs(ml_marker_mgr.markerList.editList) do
		for name, marker in pairs(list) do
			if (name == newMarker:GetName()) then
				ml_debug("Marker "..newMarker:GetName().." cannot be added because another marker with that name already exists")
				return false
			end
		end
	end
	
	local markerList = ml_marker_mgr.markerList.editList[newMarker:GetType()]
	if not markerList then
		markerList = {}
		ml_marker_mgr.markerList.editList[newMarker:GetType()] = markerList
	end
	
	markerList[newMarker:GetName()] = newMarker
	return true
end

function ml_marker_mgr.RemoveMarker(oldMarker)
	if type(oldMarker) == "string" then
		oldMarker = ml_marker_mgr.GetMarker(oldMarker)
	end
	
	if (not oldMarker:GetName()) then
		ml_debug("Invalid marker - No name specified")
		return false
	end
	
	for _, list in pairs(ml_marker_mgr.markerList.editList) do
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
	ml_marker_mgr.markerList = persistence.load(path)
	for type, list in pairs(ml_marker_mgr.markerList.editList) do
		for name, marker in pairs(list) do
			-- set marker class metatable for each marker
			setmetatable(marker, {__index = ml_marker})
		end
	end
end

function ml_marker_mgr.WriteMarkerFile(path)
	persistence.store(path, ml_marker_mgr.markerList)
end

function ml_marker_mgr.HandleInit()
    -- main window
	GUI_NewWindow(ml_marker_mgr.mainwindow.name,ml_marker_mgr.mainwindow.x,ml_marker_mgr.mainwindow.y,ml_marker_mgr.mainwindow.w,ml_marker_mgr.mainwindow.h)
	GUI_NewComboBox(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].markerType,"gMarkerMgrType",strings[gCurrentLanguage].generalSettings,"")
	GUI_NewButton(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].newMarker,"ml_marker_mgr.NewMarker",strings[gCurrentLanguage].generalSettings)
    GUI_NewComboBox(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].markerName,"gMarkerMgrName",strings[gCurrentLanguage].markerList,"")
	GUI_NewButton(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].addMarker,"ml_marker_mgr.AddMarker",strings[gCurrentLanguage].markerList)
    
    -- setup marker type list
    local markerTypeList = GetComboBoxList(ml_marker_mgr.markerList.editList)
    gMarkerMgrType_listitems = markerTypeList["keyList"]
    gMarkerMgrType = markerTypeList["firstKey"]
	
	GUI_UnFoldGroup(ml_marker_mgr.mainwindow.name, strings[gCurrentLanguage].generalSettings)
	GUI_UnFoldGroup(ml_marker_mgr.mainwindow.name, strings[gCurrentLanguage].markerList)
	GUI_SizeWindow(ml_marker_mgr.mainwindow.name, ml_marker_mgr.mainwindow.w, ml_marker_mgr.mainwindow.h)
    GUI_WindowVisible(ml_marker_mgr.mainwindow.name,false)
    
    -- marker editor window
    GUI_NewWindow(ml_marker_mgr.editwindow.name, ml_marker_mgr.mainwindow.x+ml_marker_mgr.mainwindow.w, ml_marker_mgr.mainwindow.y, ml_marker_mgr.editwindow.w, ml_marker_mgr.editwindow.h)
    GUI_NewCheckBox(ml_marker_mgr.editwindow.name, strings[gCurrentLanguage].enabled, "gMarkerEnabled")
    GUI_NewField(ml_marker_mgr.editwindow.name, "Placeholder", "gPlaceholder", strings[gCurrentLanguage].markerFields)
    GUI_NewButton(ml_marker_mgr.editwindow.name,"DELETE","ml_marker_mgr.RemoveMarker")
    GUI_NewButton(ml_marker_mgr.editwindow.name,"DOWN","ml_marker_mgr.MarkerDown")	
    GUI_NewButton(ml_marker_mgr.editwindow.name,"UP","ml_marker_mgr.MarkerUp")
    GUI_SizeWindow(ml_marker_mgr.editwindow.name,ml_marker_mgr.editwindow.w,ml_marker_mgr.editwindow.h)
    GUI_WindowVisible(ml_marker_mgr.editwindow.name,false)
end

function ml_marker_mgr.RefreshMarkers()
	-- refresh markerType and markerName lists
	local markerList = ml_marker_mgr.GetList(gMarkerMgrType,false)
    
    local namestring = ""
    if (markerList) then
        local markerNameList = GetComboBoxList(markerList)
		if namestring == "" then
			namestring = markerNameList["keyList"]
		else
			namestring = namestring..","..markerNameList["keyList"]
		end
    end
	
	gMarkerMgrName_listitems = namestring
end

function ml_marker_mgr.SetupTest()
	local testMarker1 = ml_marker:Create("testMarker1")
	testMarker1:SetType("grindMarker")
	
	local testMarker2 = ml_marker:Create("testMarker2")
	testMarker2:SetType("grindMarker")
	testMarker2.enabled = false
	
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
	ml_marker_mgr.RemoveMarker(testMarker4)
	
	-- remove via string
	ml_marker_mgr.RemoveMarker("testMarker5")
	
	-- refresh markers for GUI
	ml_marker_mgr.RefreshMarkers()
	
	testPath = GetStartupPath()..[[\Navigation\]].."markerTests.txt"
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

RegisterEventHandler("ToggleMarkerMgr", ml_marker_mgr.ToggleMenu)
RegisterEventHandler("Module.Initalize",ml_marker_mgr.HandleInit)
RegisterEventHandler("Module.Initalize",ml_marker_mgr.SetupTest)
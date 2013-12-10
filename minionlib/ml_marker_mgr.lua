--ml_marker_mgr is a gwen GUI for editing general marker information

ml_marker_mgr = {}
ml_marker_mgr.mainwindow = { name = strings[gCurrentLanguage].markerManager, x = 340, y = 50, w = 335, h = 200}
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
	ml_marker_mgr.markerList.editList = persistence.load(path)
	for type, list in pairs(ml_marker_mgr.markerList.editList) do
		for name, marker in pairs(list) do
			-- set marker class metatable for each marker
			setmetatable(marker, {__index = ml_marker})
		end
	end
end

function ml_marker_mgr.WriteMarkerFile(path)
	persistence.store(path, ml_marker_mgr.markerList.editList)
end

function ml_marker_mgr.HandleInit()
	GUI_NewWindow(ml_marker_mgr.mainwindow.name,ml_marker_mgr.mainwindow.x,ml_marker_mgr.mainwindow.y,ml_marker_mgr.mainwindow.w,ml_marker_mgr.mainwindow.h)
	GUI_NewComboBox(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].markerType,"gAddMarkerType",strings[gCurrentLanguage].addMarker,"")
	GUI_NewButton(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].newMarker,"ml_marker_mgr.NewMarker",strings[gCurrentLanguage].addMarker)
	GUI_NewComboBox(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].markerName,"gMarkerName",strings[gCurrentLanguage].editMarker,"")
	GUI_NewButton(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].editMarker,"ml_marker_mgr.EditMarker",strings[gCurrentLanguage].editMarker)
	GUI_NewComboBox(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].markerType,"gListMarkerType",strings[gCurrentLanguage].markerList,"")
	GUI_NewButton(ml_marker_mgr.mainwindow.name,strings[gCurrentLanguage].setupList,"ml_marker_mgr.SetupMarkerList",strings[gCurrentLanguage].markerList)
	
	GUI_UnFoldGroup(ml_marker_mgr.mainwindow.name, strings[gCurrentLanguage].addMarker)
	GUI_UnFoldGroup(ml_marker_mgr.mainwindow.name, strings[gCurrentLanguage].editMarker)
	GUI_UnFoldGroup(ml_marker_mgr.mainwindow.name, strings[gCurrentLanguage].markerList)
	
	GUI_SizeWindow(ml_marker_mgr.mainwindow.name, ml_marker_mgr.mainwindow.w, ml_marker_mgr.mainwindow.h)
end

function ml_marker_mgr.RefreshMarkers()
	-- refresh markerType and markerName lists
	local markerTypeList = GetComboBoxList(ml_marker_mgr.markerList.editList)
	
	local namestring = ""
	for markerType, markerList in pairs(ml_marker_mgr.markerList.editList) do
		local markerNameList = GetComboBoxList(markerList)
		if namestring == "" then
			namestring = markerNameList["keyList"]
		else
			namestring = namestring..","..markerNameList["keyList"]
		end
	end
	
	gAddMarkerType_listitems = markerTypeList["keyList"]
	gListMarkerType_listitems = markerTypeList["keyList"]
	gMarkerName_listitems = namestring
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

RegisterEventHandler("Module.Initalize",ml_marker_mgr.HandleInit)
RegisterEventHandler("Module.Initalize",ml_marker_mgr.SetupTest)
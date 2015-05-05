imp = {}
imp.filesPath = GetStartupPath()..[[\LuaMods\ffxivminion\ImportManagerFiles\]]
imp.globalSettings = imp.filesPath.."ffxiv_global_save.lua"
imp.markerPath = ml_mesh_mgr.navmeshfilepath
imp.winName = GetString("importExport")
imp.lastTick = 0
imp.currentFiles = {}
imp.modules = {
	"FFXIVMINION",
	"minionlib",
	"Dev",
}
imp.structure = {
	FFXIVMINION = {},
	minionlib = {},
	Dev = {},
}

function imp.ModuleInit()
	
	if ( not ffxivminion.Windows) then
		ffxivminion.Windows = {}
	end

	ffxivminion.Windows.Importer = { id = strings["us"].importExport, Name = GetString("importExport"), x=50, y=50, width=260, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Importer)
	
	if not file_exists(imp.globalSettings) then
		persistence.store(imp.globalSettings,imp.structure)
	end
	
	if ( Settings.FFXIVMINION.gExportAutoGlobal  == nil ) then
		Settings.FFXIVMINION.gExportAutoGlobal = "0"
	end
	if ( Settings.FFXIVMINION.gImportFileName  == nil ) then
		Settings.FFXIVMINION.gImportFileName = ""
	end
	if ( Settings.FFXIVMINION.gImportOverwriteMarkers  == nil ) then
		Settings.FFXIVMINION.gImportOverwriteMarkers = ""
	end
	
	local winName = GetString("importExport")
	GUI_NewButton(winName, GetString("autoExport") ,"imp.ToggleAutoExport")
	
	local group = GetString("settings")
	GUI_NewCheckbox(winName,GetString("autoExport"),"gExportAutoGlobal",group)
	
	local group = GetString("basicExport")
	GUI_NewButton(winName,GetString("exportGlobal"),"impExportGlobal",group)
	GUI_NewField(winName,GetString("fileName"),"gExportFileName",group)
	GUI_NewButton(winName,GetString("exportSettings"),"impExportSettingsGeneral",group)
	--GUI_NewButton(winName,"Export Current BotMode Settings","impExportSettingsBotmodeCurrent",group)
	--GUI_NewButton(winName,"Export All BotMode Settings","impExportSettingsBotmodeAll",group)
	--GUI_NewButton(winName,"Export Current Map Markers","impExportMarkersCurrent",group)
	--GUI_NewButton(winName,"Export All Map Markers","impExportMarkersAll",group)
	GUI_NewButton(winName,GetString("gatherLocations"),"impExportGatherLocations",group)
	GUI_NewButton(winName,GetString("huntLocations"),"impExportHuntLocations",group)
	
	group = GetString("basicImport")
	GUI_NewButton(winName,GetString("importGlobal"),"impImportGlobal",group)
	GUI_NewComboBox(winName,GetString("fileName"),"gImportFileName",group,"")
	GUI_NewButton(winName,GetString("importSettings"),"impImportSettingsGeneral",group)
	--GUI_NewButton(winName,"Import Current BotMode Settings","impImportSettingsBotmodeCurrent",group)
	--GUI_NewButton(winName,"Import All BotMode Settings","impImportSettingsBotmodeAll",group)
	--GUI_NewButton(winName,"Import Current Map Markers","impImportMarkersCurrent",group)
	--GUI_NewButton(winName,"Import All Map Markers","impImportMarkersAll",group)
	GUI_NewButton(winName,GetString("gatherLocations"),"impImportGatherLocations",group)
	GUI_NewButton(winName,GetString("huntLocations"),"impImportHuntLocations",group)
	
	group = GetString("markerImport")
	GUI_NewComboBox(winName,GetString("fileName"),"gImportFileName",group,"")
	GUI_NewCheckbox(winName,GetString("overwriteExisting"),"gImportOverwriteMarkers",group)
	GUI_NewButton(winName,GetString("allMarkers"),"impImportMarkersAll",group)
	GUI_NewButton(winName,GetString("unspoiledMarker"),"impImportMarkers"..GetString("unspoiledMarker"),group)
	GUI_NewButton(winName,GetString("miningMarker"),"impImportMarkers"..GetString("miningMarker"),group)
	GUI_NewButton(winName,GetString("botanyMarker"),"impImportMarkers"..GetString("botanyMarker"),group)
	GUI_NewButton(winName,GetString("fishingMarker"),"impImportMarkers"..GetString("fishingMarker"),group)
	GUI_NewButton(winName,GetString("grindMarker"),"impImportMarkers"..GetString("grindMarker"),group)
	GUI_NewButton(winName,GetString("pvpMarker"),"impImportMarkers"..GetString("pvpMarker"),group)
	GUI_NewButton(winName,GetString("huntMarker"),"impImportMarkers"..GetString("huntMarker"),group)
	
	gExportAutoGlobal = Settings.FFXIVMINION.gExportAutoGlobal
	gImportFileName = Settings.FFXIVMINION.gImportFileName
	gImportOverwriteMarkers = Settings.FFXIVMINION.gImportOverwriteMarkers
	
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
end

function imp.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if (gExportAutoGlobal == "1") then
			if not file_exists(imp.globalSettings) then
				persistence.store(imp.globalSettings,imp.structure)
			end
			local importSettings,e = persistence.load(imp.globalSettings)
			
			local modifiedModule = ""
			for _,moduleName in pairs(imp.modules) do
				local moduleSettings = _G[moduleName.."_raw"]
				for settingName,settingValue in pairs(moduleSettings) do
					if (k == settingName) then
						modifiedModule = moduleName
					end
				end
			end
			
			if (modifiedModule ~= "") then
				if (not importSettings[modifiedModule]) then
					importSettings[modifiedModule] = {}
				end
				importSettings[modifiedModule][k] = v
				persistence.store(imp.globalSettings,importSettings)
			end
		end
		if (k == "gImportFileName") then
			SafeSetVar(tostring(k),v)
		end
	end
    --GUI_RefreshWindow(imp.winName)
end

function imp.OnUpdate( event, tickcount )
	if (TimeSince(imp.lastTick) >= 5000) then
		imp.lastTick = tickcount
		imp.UpdateFiles()
	end
end

function imp.ToggleAutoExport()
	gExportAutoGlobal = (gExportAutoGlobal == "0" and "1") or "0"
	Settings.FFXIVMINION.gExportAutoGlobal = gExportAutoGlobal
end

function imp.Import(key)
	if (key and type(key) == "string") then
		if (key == "Global") then
			--Gather all settings from the global_settings and import them.
			local importSettings = persistence.load(imp.globalSettings)
			
			if (ValidTable(importSettings)) then
				--Loop through the 3 settings tables to import all available settings for each one.
				for iModule,iTable in pairs(importSettings) do
					for iKey,iValue in pairs(iTable) do
						_G[iKey] = iValue
						Settings[iModule][iKey] = iValue
						Settings[iModule][iKey] = Settings[iModule][iKey]
					end
				end
				Reload()
			else
				ml_error("Could not read the global settings file, it may be corrupted.")
			end
		elseif (key == "GatherLocations") then
			if (IsNullString(gImportFileName)) then
				ml_error("Must select a file from the list.")
				return
			end
			
			local file = imp.filesPath..gImportFileName..".info"
			local importSettings = persistence.load(file)
			if (ValidTable(importSettings)) then
				local currentLocations = Settings.FFXIVMINION.gGatherLocations
				for locationName,locationData in pairs(importSettings) do
					currentLocations[locationName] = locationData
				end
				
				Settings.FFXIVMINION.gGatherLocations = currentLocations
				gGatherLocations = Settings.FFXIVMINION.gGatherLocations
				Reload()
			else
				ml_error("Import failed. File appears to be malformed or corrupted.")
				return
			end
		elseif (key == "HuntLocations") then
			if (IsNullString(gImportFileName)) then
				ml_error("Must select a file from the list.")
				return
			end
			
			local file = imp.filesPath..gImportFileName..".info"
			local importSettings = persistence.load(file)
			if (ValidTable(importSettings)) then
				local currentLocations = Settings.FFXIVMINION.gHuntLocations
				for locationName,locationData in pairs(importSettings) do
					currentLocations[locationName] = locationData
				end
				
				Settings.FFXIVMINION.gHuntLocations = currentLocations
				gHuntLocations = Settings.FFXIVMINION.gHuntLocations
				Reload()
			else
				ml_error("Import failed. File appears to be malformed or corrupted.")
				return
			end
		elseif (string.find(key,"Markers") ~= nil) then
			local subkey = string.gsub(key,"Markers","")
			
			if (IsNullString(gImportFileName)) then
				ml_error("Must select a file from the list.")
				return
			end
			
			local file = imp.filesPath..gImportFileName..".info"
			local importMarkers = persistence.load(file)
			local currentMarkers = ml_marker_mgr.markerList
			
			for markerType,markerTable in pairs(importMarkers) do
				if (subkey == "All" or subkey == markerType) then
					for markerName,markerData in pairs(markerTable) do
						if (not currentMarkers[markerType]) then
							currentMarkers[markerType] = {}
						end
						if (not currentMarkers[markerType][markerName] or gImportOverwriteMarkers == "1") then
							currentMarkers[markerType][markerName] = markerData
						end
					end
				end
			end

			ml_marker_mgr.WriteMarkerFile(ml_marker_mgr.markerPath)
			Reload()
		end
	end
end

function imp.Export(key)
	if (key and type(key) == "string") then
		if (key == "Global") then
			--Gather all settings from the various modules and export them to the global_settings.
			local ffxivminionSettings = FFXIVMINION_raw
			local minionlibSettings = minionlib_raw
			local devSettings = Dev_raw
			
			local exportTable = {}
			exportTable.FFXIVMINION = ffxivminionSettings
			exportTable.minionlib = minionlibSettings
			exportTable.Dev = devSettings

			persistence.store(imp.globalSettings,exportTable)
		elseif (key == "GatherLocations") then
			local nameString = gExportFileName
			if (IsNullString(nameString)) then
				nameString = "ExportedGatherLocations"
			end
			
			local file = imp.filesPath..nameString..".info"
			local gatherLocations = Settings.FFXIVMINION.gGatherLocations
			persistence.store(file,gatherLocations)
			if (file_exists(file)) then
				d(file.." was created successfully.")
			end
		elseif (key == "HuntLocations") then
			local nameString = gExportFileName
			if (IsNullString(nameString)) then
				nameString = "ExportedHuntLocations"
			end
			
			local file = imp.filesPath..nameString..".info"
			local huntLocations = Settings.FFXIVMINION.gHuntLocations
			persistence.store(file,huntLocations)
			if (file_exists(file)) then
				d(file.." was created successfully.")
			end
		end
	end
end

function imp.UpdateFiles()
	local currentFiles = imp.currentFiles
    local files = ""
	local lastFile = Settings.FFXIVMINION.gImportFileName
    local filelist = dirlist(imp.filesPath,".*info")	
    if ( ValidTable(filelist)) then
		local needsUpdate = false
		local lastFileFound = false
		for i, file in pairs(filelist) do
			local fileString = string.gsub(file, ".info", "")
			if (not ValidTable(currentFiles) or not currentFiles[i] or currentFiles[i] ~= fileString) then
				currentFiles[i] = fileString
				needsUpdate = true
			end
		end
		
		for i, file in pairs(currentFiles) do
			if (i > TableSize(filelist)) then
				currentFiles[i] = nil
				needsUpdate = true
			end
		end
		
		if (needsUpdate) then
			for i, file in pairs(currentFiles) do
				if file == lastFile then
					lastFileFound = true
				end
				
				if files == "" then
					files = file
				else
					files = files..","..file	
				end
			end
			
			gImportFileName_listitems = files
			gImportFileName = (lastFileFound and lastFile) or ""
		end	
	else
		if (TableSize(currentFiles) > 0) then
			imp.currentFiles = nil
			imp.currentFiles = {}
			files = ""
			
			gImportFileName_listitems = files
			gImportFileName = ""
		end
    end
end

function imp.ShowMenu()
	local wnd = GUI_GetWindowInfo(ffxivminion.Windows.Main.Name)
    GUI_MoveWindow( imp.winName, wnd.x+wnd.width,wnd.y) 
	ffxivminion.SizeWindow(imp.winName)
    GUI_WindowVisible( imp.winName, true)	
end

function imp.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" ) then
		if (string.find(Button,"impExport") ~= nil) then
			imp.Export(string.gsub(Button,"impExport",""))
		elseif (string.find(Button,"impImport") ~= nil) then
			imp.Import(string.gsub(Button,"impImport",""))	
		elseif (string.sub(Button,1,4) == "imp.") then
			ExecuteFunction(Button)
		end
	end
end

RegisterEventHandler("ToggleImportMgr", imp.ShowMenu)
RegisterEventHandler("Module.Initalize",imp.ModuleInit)
RegisterEventHandler("GUI.Update",imp.GUIVarUpdate)
RegisterEventHandler("GUI.Item", imp.HandleButtons )
RegisterEventHandler("Gameloop.Update",imp.OnUpdate)
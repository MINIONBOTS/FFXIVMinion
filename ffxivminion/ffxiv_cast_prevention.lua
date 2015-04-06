cp = {}
cp.mainwindow = { name = GetString("castPrevention"), x = 50, y = 50, width = 250, height = 200}

function cp.ModuleInit() 	

	if ( Settings.FFXIVMINION.cpOptions == nil ) then
		Settings.FFXIVMINION.cpOptions = {}
	end
	if ( Settings.FFXIVMINION.cpOption == nil ) then
		Settings.FFXIVMINION.cpOption = ""
	end
	if ( Settings.FFXIVMINION.cpTCastIDs == nil ) then
		Settings.FFXIVMINION.cpTCastIDs = ""
	end
	if ( Settings.FFXIVMINION.cpTBuffs == nil ) then
		Settings.FFXIVMINION.cpTBuffs = ""
	end
	
	GUI_NewWindow(cp.mainwindow.name,cp.mainwindow.x,cp.mainwindow.y,cp.mainwindow.width,cp.mainwindow.height)
    GUI_NewField(cp.mainwindow.name,"Option Name:",			"cpOption","New Option")
	GUI_NewField(cp.mainwindow.name,"Target Has Buffs:",		"cpTBuffs","New Option")
	GUI_NewField(cp.mainwindow.name,"Target Casting IDs:",		"cpTCastIDs","New Option")
	GUI_NewButton(cp.mainwindow.name,"Add Option",				"cpAddCastPrevention",	"New Option")
	GUI_UnFoldGroup(cp.mainwindow.name,"New Option" )
	GUI_SizeWindow(cp.mainwindow.name,200,200)
	GUI_WindowVisible(cp.mainwindow.name, false)
	
	cpOptions = Settings.FFXIVMINION.cpOptions
	cpOption = Settings.FFXIVMINION.cpOption
	cpTCastIDs = Settings.FFXIVMINION.cpTCastIDs
	cpTBuffs = Settings.FFXIVMINION.cpTBuffs
end

function cp.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if (k == "cpOption" or
            k == "cpTCastIDs" or
            k == "cpTBuffs")			
        then
            SafeSetVar(tostring(k),v)
		end
	end
    GUI_RefreshWindow(cp.mainwindow.name)
end

function cp.AddCastPrevention()
	local list = Settings.FFXIVMINION.cpOptions
	local key = TableSize(list) + 1
	
	--Check to make sure that something hasn't gone wrong with the index and reindex the table if necessary.
	if (list[key]) then
		local newKey = 1
		local newList = {}
		for k,v in spairs(list) do
			newList[newKey] = v
			newKey = newKey + 1
		end
		list = newList
		key = TableSize(list) + 1
	end
	
	local option = {
		name = cpOption,
		tbuffs = cpTBuffs,
		castids = cpTCastIDs,
	}
	
	list[tostring(key)] = option
	Settings.FFXIVMINION.cpOptions = list
	cp.RefreshCastPreventions()
end

function cp.RemoveCastPrevention(key)
	local list = Settings.FFXIVMINION.cpOptions
	local newList = {}
	local newKey = 1
	
	list[key] = nil
	for k,v in pairs(list) do
		newList[tostring(newKey)] = v
		newKey = newKey + 1
	end

	Settings.FFXIVMINION.cpOptions = newList
	cp.RefreshCastPreventions()
end

function cp.RefreshCastPreventions()
	
	local winName = cp.mainwindow.name
	local tabName = "Option"
	local list = Settings.FFXIVMINION.cpOptions
	
	GUI_DeleteGroup(winName,tabName)
	if (TableSize(list) > 0) then
		for k,v in pairs(list) do
			GUI_NewButton(winName, v.name,	"cpRemoveCastPrevention"..tostring(k), tabName)
		end
		GUI_UnFoldGroup(winName,tabName)
	end
	
	GUI_SizeWindow(winName,cp.mainwindow.width,cp.mainwindow.height)
	GUI_RefreshWindow(winName)
end

function cp.ShowMenu()
	local wnd = GUI_GetWindowInfo(ffxivminion.Windows.Main.Name)	
    GUI_MoveWindow( "Cast Prevention", wnd.x+wnd.width,wnd.y) 
    GUI_WindowVisible("Cast Prevention",true)	
	cp.RefreshCastPreventions()
end

function cp.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" and string.find(Button,"cp") ~= nil ) then
		if (Button == "cpAddCastPrevention") then
			cp.AddCastPrevention()
		end
		
		if (string.find(Button,"cpRemoveCastPrevention") ~= nil) then
			local key = Button:gsub("cpRemoveCastPrevention","")
			cp.RemoveCastPrevention(key)
		end
	end
end

RegisterEventHandler("GUI.Item",cp.HandleButtons)
RegisterEventHandler("CastPrevention.toggle", cp.ShowMenu)
RegisterEventHandler("Module.Initalize",cp.ModuleInit)
RegisterEventHandler("GUI.Update",cp.GUIVarUpdate)
sck = {}
sck.filterTime1 = 0
sck.filterTime2 = 0
sck.filterTime3 = 0
sck.filterTime4 = 0
sck.filterTime5 = 0
sck.onOffTimer = 0
sck.currentSpeed = 6
sck.psTimer = 0
sck.prevModeTimer = 0
sck.nextModeTimer = 0
sck.ctoggleTimer = 0
sck.trackTargetTimer = 0
sck.followTargetTimer = 0

sck.mainwindow = { name = GetString("shortcutManager"), x = 50, y = 50, width = 250, height = 200}
sck.Shortcuts = {
	["Filter 1"] = 1,
	["Filter 2"] = 2,
	["Filter 3"] = 3,
	["Filter 4"] = 4,
	["Filter 5"] = 5,
	["Start/Stop"] = 6,
	["Speed Hack"] = 7,
	["PermaSprint"] = 8,
	["Previous Mode"] = 9,
	["Next Mode"] = 10,
	["Toggle Companion"] = 11,
	["Follow Target"] = 12,
	["Track Target"] = 13,
}

ffxivminion.Strings.Shortcuts = 
	function ()
		local shortcuts = ""
		local sort_func = function( t,a,b ) return t[a] < t[b] end
		for k,v in spairs(sck.Shortcuts,sort_func) do
			if (shortcuts == "") then
				shortcuts = k
			else
				shortcuts = shortcuts..","..k
			end
		end
		return shortcuts
	end
	
ffxivminion.Strings.ModKeys = 
	function ()
		local modKey = ""
		local sort_func = function( t,a,b ) return t[a] < t[b] end
		for k,v in spairs(sck.ModifierKeys,sort_func) do
			if (modKey == "") then
				modKey = k
			else
				modKey = modKey..","..k
			end
		end
		return modKey
	end
		
ffxivminion.Strings.SCKeys = 
	function ()
		local sKey = ""
		local sort_func = function( t,a,b ) return t[a] < t[b] end
		for k,v in spairs(sck.ShortcutKeys,sort_func) do
			if (sKey == "") then
				sKey = k
			else
				sKey = sKey..","..k
			end
		end
		return sKey
	end

function sck.ModuleInit() 	

	if (Settings.FFXIVMINION.ClickCombo == nil) then
		Settings.FFXIVMINION.ClickCombo = {}
	end
	if ( Settings.FFXIVMINION.gShortcutKey == nil ) then
		Settings.FFXIVMINION.gShortcutKey = "None"
	end
	if ( Settings.FFXIVMINION.gModifierKey == nil ) then
		Settings.FFXIVMINION.gModifierKey = "None"
	end
	if ( Settings.FFXIVMINION.gModifierKey2 == nil ) then
		Settings.FFXIVMINION.gModifierKey2 = "None"
	end
	if ( Settings.FFXIVMINION.gShortcut == nil ) then
		Settings.FFXIVMINION.gShortcut = "Start/Stop"
	end
	
	local winName = sck.mainwindow.name
	GUI_NewWindow(winName,sck.mainwindow.x,sck.mainwindow.y,sck.mainwindow.width,sck.mainwindow.height)
	local group = GetString("settings")
	local funcString = ""
	funcString = ffxivminion.Strings.Shortcuts()
    GUI_NewComboBox(winName,GetString("shortcut"),"gShortcut",group,funcString)
	funcString = ffxivminion.Strings.ModKeys()
	GUI_NewComboBox(winName,GetString("modifierKey"),"gModifierKey",group,funcString)
	funcString = ffxivminion.Strings.ModKeys()
	GUI_NewComboBox(winName,GetString("modifierKey"),"gModifierKey2",group,funcString)
	funcString = ffxivminion.Strings.SCKeys()
	GUI_NewComboBox(winName,GetString("shortcutKey"),"gShortcutKey",group,funcString)
	GUI_UnFoldGroup(winName,group )
	GUI_SizeWindow(winName,200,200)
	GUI_WindowVisible(winName, false)
	
	gShortcut = Settings.FFXIVMINION.gShortcut
	gModifierKey = Settings.FFXIVMINION.gModifierKey
	gModifierKey2 = Settings.FFXIVMINION.gModifierKey2
	gShortcutKey = Settings.FFXIVMINION.gShortcutKey
	
	sck.UpdateShortcutOptions()
end

function sck.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if (k == "gShortcut") then			
			sck.UpdateShortcutChoice()
			SafeSetVar(tostring(k),v)
		end
		if (k == "gShortcutKey") then			
			sck.UpdateShortcut("skey")
            SafeSetVar(tostring(k),v)
		end
		if (k == "gModifierKey") then			
			sck.UpdateShortcut("mkey")
            SafeSetVar(tostring(k),v)
		end
		if (k == "gModifierKey2") then			
			sck.UpdateShortcut("mkey2")
            SafeSetVar(tostring(k),v)
		end
	end
    GUI_RefreshWindow(sck.mainwindow.name)
end

function sck.UpdateShortcutOptions()
	local shortcuts = ""
	local sort_func = function( t,a,b ) return t[a] < t[b] end
	for k,v in spairs(sck.Shortcuts) do
		if (shortcuts == "") then
			shortcuts = k
		else
			shortcuts = shortcuts..","..k
		end
		
		if (Settings.FFXIVMINION.ClickCombo[k] == nil or Settings.FFXIVMINION.ClickCombo[k] == {}) then 
			local combo = {} 
			combo.key1 = "None"
			combo.value1 = 0
			combo.key2 = "None"
			combo.value2 = 0
			combo.key3 = "None"
			combo.value3 = 0
			
			Settings.FFXIVMINION.ClickCombo[k] = combo
		end
	end
end

function sck.UpdateShortcut(key)
	if ( key == "mkey" ) then
		local v = gModifierKey
		local CC = Settings.FFXIVMINION.ClickCombo
		CC[gShortcut].key1 = v
		for key,value in pairs(sck.ModifierKeys) do
			if key == v then 
				CC[gShortcut].value1 = value 
			end
		end
		Settings.FFXIVMINION.ClickCombo = CC
	elseif ( key == "mkey2" ) then
		local v = gModifierKey2
		local CC = Settings.FFXIVMINION.ClickCombo
		CC[gShortcut].key2 = v
		for key,value in pairs(sck.ModifierKeys) do
			if key == v then 
				CC[gShortcut].value2 = value 
			end
		end
		Settings.FFXIVMINION.ClickCombo = CC
	elseif ( key == "skey" ) then
		local v = gShortcutKey
		local CC = Settings.FFXIVMINION.ClickCombo
		CC[gShortcut].key3 = v
		for key,value in pairs(sck.ShortcutKeys) do
			if key == v then 
				CC[gShortcut].value3 = value 
			end
		end
		Settings.FFXIVMINION.ClickCombo = CC
	end
end

function sck.UpdateShortcutChoice()
	local CC = Settings.FFXIVMINION.ClickCombo[gShortcut]
	
	if (CC ~= nil) then
		gModifierKey = CC.key1
		gModifierKey2 = CC.key2
		gShortcutKey = CC.key3
	end
end

function sck.ShowMenu()
	local wnd = GUI_GetWindowInfo(ffxivminion.Windows.Main.Name)	
    GUI_MoveWindow( sck.mainwindow.name, wnd.x+wnd.width,wnd.y) 
    GUI_WindowVisible( sck.mainwindow.name, true)	
	sck.UpdateShortcutChoice()
end

function sck.OnUpdate( event, tickcount )
	local CC = {}
	CC = Settings.FFXIVMINION.ClickCombo["Filter 1"]
	local value1 = CC.value1
	local value2 = CC.value2
	local value3 = CC.value3
	if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
		(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
		(value3 ~= 0 and MeshManager:IsKeyPressed(value3)) and
			TimeSince(sck.filterTime1) >= 750) 
	then
		if ( gAssistFilter1 == "0" ) then
			gAssistFilter1 = "1"
		else
			gAssistFilter1 = "0"
		end
		sck.filterTime1 = tickcount
	end
	
	CC = Settings.FFXIVMINION.ClickCombo["Filter 2"]
	local value1 = CC.value1
	local value2 = CC.value2
	local value3 = CC.value3
	if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
		(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
		(value3 ~= 0 and MeshManager:IsKeyPressed(value3)) and
			TimeSince(sck.filterTime2) >= 750) 
	then
		if ( gAssistFilter2 == "0" ) then
			gAssistFilter2 = "1"
		else
			gAssistFilter2 = "0"
		end
		sck.filterTime2 = tickcount
	end
	
	CC = Settings.FFXIVMINION.ClickCombo["Filter 3"]
	local value1 = CC.value1
	local value2 = CC.value2
	local value3 = CC.value3
	if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
		(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
		(value3 ~= 0 and MeshManager:IsKeyPressed(value3)) and
			TimeSince(sck.filterTime3) >= 750) 
	then
		if ( gAssistFilter3 == "0" ) then
			gAssistFilter3 = "1"
		else
			gAssistFilter3 = "0"
		end
		sck.filterTime3 = tickcount
	end
	
	CC = Settings.FFXIVMINION.ClickCombo["Filter 4"]
	local value1 = CC.value1
	local value2 = CC.value2
	local value3 = CC.value3
	if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
		(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
		(value3 ~= 0 and MeshManager:IsKeyPressed(value3)) and
			TimeSince(sck.filterTime4) >= 750) 
	then
		if ( gAssistFilter4 == "0" ) then
			gAssistFilter4 = "1"
		else
			gAssistFilter4 = "0"
		end
		sck.filterTime4 = tickcount
	end
	
	CC = Settings.FFXIVMINION.ClickCombo["Filter 5"]
	local value1 = CC.value1
	local value2 = CC.value2
	local value3 = CC.value3
	if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
		(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
		(value3 ~= 0 and MeshManager:IsKeyPressed(value3)) and
			TimeSince(sck.filterTime5) >= 750) 
	then
		if ( gAssistFilter5 == "0" ) then
			gAssistFilter5 = "1"
		else
			gAssistFilter5 = "0"
		end
		sck.filterTime5 = tickcount
	end
	
	CC = Settings.FFXIVMINION.ClickCombo["Start/Stop"]
	local value1 = CC.value1
	local value2 = CC.value2
	local value3 = CC.value3
	
	if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
		(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
		(value3 ~= 0 and MeshManager:IsKeyPressed(value3)) and
			TimeSince(sck.onOffTimer) >= 750) 
	then
		d("Both keys are pressed.")
		ml_task_hub.ToggleRun()
		sck.onOffTimer = tickcount
	end	
	
	CC = Settings.FFXIVMINION.ClickCombo["Speed Hack"]
	local value1 = CC.value1
	local value2 = CC.value2
	local value3 = CC.value3
	if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
		(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
		(value3 ~= 0 and MeshManager:IsKeyPressed(value3)) and
			not ml_global_information.Player_InCombat) 
	then
		if ( Player.ismounted and sck.currentSpeed ~= 18 ) then
			Player:SetSpeed(FFXIV.MOVEMENT.FORWARD, 18)
			sck.currentSpeed = 15
		elseif ( not Player.ismounted and sck.currentSpeed ~= 12) then
			Player:SetSpeed(FFXIV.MOVEMENT.FORWARD, 12)
			sck.currentSpeed = 12
		end
	else
		if ( Player.ismounted and sck.currentSpeed ~= 9) then
			Player:SetSpeed(FFXIV.MOVEMENT.FORWARD, 9)
			sck.currentSpeed = 9
		elseif ( not Player.ismounted and sck.currentSpeed ~= 6 ) then
			Player:SetSpeed(FFXIV.MOVEMENT.FORWARD, 6)
			sck.currentSpeed = 6
		end
	end	
	
	CC = Settings.FFXIVMINION.ClickCombo["PermaSprint"]
	local value1 = CC.value1
	local value2 = CC.value2
	local value3 = CC.value3
	if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
		(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
		(value3 ~= 0 and MeshManager:IsKeyPressed(value3)) and
			TimeSince(sck.psTimer) >= 500) 
	then
			GameHacks:SetPermaSprint(not GameHacks.permasprint)
			SetGUIVar("gGatherPS", GameHacks.permasprint and "1" or "0")
			sck.psTimer = tickcount
	end	
	
	CC = Settings.FFXIVMINION.ClickCombo["Previous Mode"]
	local value1 = CC.value1
	local value2 = CC.value2
	local value3 = CC.value3
	if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
		(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
		(value3 ~= 0 and MeshManager:IsKeyPressed(value3)) and
			TimeSince(sck.prevModeTimer) >= 150) 
	then
		local lastMode = ""
		local modeFound = false
		
		local botModes = ""
		if (ValidTable(ffxivminion.modes)) then
			local modes = ffxivminion.modes
			for i,entry in spairs(modes, function(modes,a,b) return a < b end) do
				if (i == gBotMode) then
					modeFound = true
				end
				if (modeFound) then
					break
				end
				lastMode = i
			end				
		end
		
		if (lastMode ~= "") then
			ffxivminion.SwitchMode(lastMode)
			SafeSetVar("gBotMode",lastMode)
		end
		sck.prevModeTimer = tickcount
	end	
	
	CC = Settings.FFXIVMINION.ClickCombo["Next Mode"]
	local value1 = CC.value1
	local value2 = CC.value2
	local value3 = CC.value3
	if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
		(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
		(value3 ~= 0 and MeshManager:IsKeyPressed(value3)) and
			TimeSince(sck.nextModeTimer) >= 150) 
	then
		local nextMode = ""
		local modeFound = false
		
		local botModes = ""
		if (ValidTable(ffxivminion.modes)) then
			local modes = ffxivminion.modes
			for i,entry in spairs(modes, function(modes,a,b) return a < b end) do
				if (modeFound) then
					nextMode = i
					break
				end
				if (i == gBotMode) then
					modeFound = true
				end
			end				
		end
		
		if (nextMode ~= "") then
			ffxivminion.SwitchMode(nextMode)
			SafeSetVar("gBotMode",nextMode)
		end
		sck.nextModeTimer = tickcount
	end	
	
	CC = Settings.FFXIVMINION.ClickCombo["Toggle Companion"]
	local value1 = CC.value1
	local value2 = CC.value2
	local value3 = CC.value3
	if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
		(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
		(value3 ~= 0 and MeshManager:IsKeyPressed(value3)) and
			TimeSince(sck.ctoggleTimer) >= 150) 
	then
		if (gBotMode == GetString("grindMode") or gBotMode == GetString("partyMode")) then
			SetGUIVar("gChocoGrind",gChocoGrind == "0" and "1" or "0")
		elseif (gBotMode == GetString("assistMode")) then
			SetGUIVar("gChocoAssist",gChocoAssist == "0" and "1" or "0")
		elseif (gBotMode == GetString("questMode")) then
			SetGUIVar("gChocoQuest",gChocoQuest == "0" and "1" or "0")
		end
		sck.ctoggleTimer = tickcount
	end	
	
	CC = Settings.FFXIVMINION.ClickCombo["Track Target"]
	local value1 = CC.value1
	local value2 = CC.value2
	local value3 = CC.value3
	if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
		(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
		(value3 ~= 0 and MeshManager:IsKeyPressed(value3)) and
			TimeSince(sck.trackTargetTimer) >= 150) 
	then
		SetGUIVar("gAssistTrackTarget",gAssistTrackTarget == "0" and "1" or "0")
		sck.trackTargetTimer = tickcount
	end	
	
	CC = Settings.FFXIVMINION.ClickCombo["Follow Target"]
	local value1 = CC.value1
	local value2 = CC.value2
	local value3 = CC.value3
	if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
		(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
		(value3 ~= 0 and MeshManager:IsKeyPressed(value3)) and
			TimeSince(sck.followTargetTimer) >= 150) 
	then
		SetGUIVar("gAssistFollowTarget",gAssistFollowTarget == "0" and "1" or "0")
		sck.followTargetTimer = tickcount
	end	
end

sck.ModifierKeys = {
	["None"] = 0,
	["Left SHIFT"] = 160,
	["Right SHIFT"] = 161,
	["Left CONTROL"] = 162,
	["Right CONTROL"] = 163,
	["Left ALT"] = 164,
	["Right ALT"] = 165,
}

sck.ShortcutKeys = {
["None"]=	0,
["Left Mouse"]=	1,
["Right Mouse"]=	2,
["Middle Mouse"]=	4,
["Mouse 4"] = 5,
["Mouse 5"] = 6,
["BACKSPACE"]=	8,
["TAB"]=	9,
["ENTER"]=	13,
["PAUSE"]=	19,
["ESC"]=	27,
["SPACEBAR"]=	32,
["PAGE UP"]=	33,
["PAGE DOWN"]=	34,
["END"]=	35,
["HOME"]=	36,
["LEFT ARROW"]=	37,
["UP ARROW"]=	38,
["RIGHT ARROW"]=	39,
["DOWN ARROW"]=	40,
["PRINT"]=	42,
["INS"]=	45,
["DEL"]=	46,
["0"]=	48,
["1"]=	49,
["2"]=	50,
["3"]=	51,
["4"]=	52,
["5"]=	53,
["6"]=	54,
["7"]=	55,
["8"]=	56,
["9"]=	57,
["A"]=	65,
["B"]=	66,
["C"]=	67,
["D"]=	68,
["E"]=	69,
["F"]=	70,
["G"]=	71,
["H"]=	72,
["I"]=	73,
["J"]=	74,
["K"]=	75,
["L"]=	76,
["M"]=	77,
["N"]=	78,
["O"]=	79,
["P"]=	80,
["Q"]=	81,
["R"]=	82,
["S"]=	83,
["T"]=	84,
["U"]=	85,
["V"]=	86,
["W"]=	87,
["X"]=	88,
["Y"]=	89,
["Z"]=	90,
["NUM 0"]=	96,
["NUM 1"]=	97,
["NUM 2"]=	98,
["NUM 3"]=	99,
["NUM 4"]=	100,
["NUM 5"]=	101,
["NUM 6"]=	102,
["NUM 7"]=	103,
["NUM 8"]=	104,
["NUM 9"]=	105,
["Separator"]=	108,
["Subtract"]=	109,
["Decimal"]=	110,
["Divide"]=	111,
["F1"]=	112,
["F2"]=	113,
["F3"]=	114,
["F4"]=	115,
["F5"]=	116,
["F6"]=	117,
["F7"]=	118,
["F8"]=	119,
["F9"]=	120,
["F10"]=	121,
["F11"]=	122,
["F12"]=	123,
["SCROLL LOCK"]=	145,
["Left SHIFT"] = 160,
["Right SHIFT"] = 161,
["Left CONTROL"] = 162,
["Right CONTROL"] = 163,
["Left ALT"] = 164,
["Right ALT"] = 165,
}

RegisterEventHandler("ShortcutManager.toggle", sck.ShowMenu)
RegisterEventHandler("Gameloop.Update",sck.OnUpdate)
RegisterEventHandler("Module.Initalize",sck.ModuleInit)
RegisterEventHandler("GUI.Update",sck.GUIVarUpdate)
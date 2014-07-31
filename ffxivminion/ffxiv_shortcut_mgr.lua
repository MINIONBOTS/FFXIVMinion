sck = {}
sck.mainwindow = { name = "Shortcut Manager", x = 50, y = 50, width = 250, height = 200}
sck.Shortcuts = {
	["Filter 1"] = true,
	["Filter 2"] = true,
	["Start/Stop"] = true,
}

ffxivminion.Strings.Shortcuts = 
	function ()
		local shortcuts = ""
		for k,v in pairs(sck.Shortcuts) do
			shortcuts = shortcuts..","..k
		end
		return shortcuts
	end
	
ffxivminion.Strings.ModKeys = 
	function ()
		local modKey = ""
		local sort_func = function( t,a,b ) return t[a] < t[b] end
		for k,v in spairs(sck.ModifierKeys,sort_func) do
			modKey = modKey..","..k
		end
		return modKey
	end
		
ffxivminion.Strings.SCKeys = 
	function ()
		local sKey = ""
		local sort_func = function( t,a,b ) return t[a] < t[b] end
		for k,v in spairs(sck.ShortcutKeys,sort_func) do
			sKey = sKey..","..k
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
	if ( Settings.FFXIVMINION.gShortcut == nil ) then
		Settings.FFXIVMINION.gShortcut = "Start/Stop"
	end
	
	ClickCombo = 		{ default = {}, 		cast = "table"},
	gShortcutKey = 		{ default = "None",		cast = "string", onChange = {"ffxivminion.UpdateShortcut", "gShortcutKey"}},
	gModifierKey = 		{ default = "None",		cast = "string", onChange = {"ffxivminion.UpdateShortcut", "gModifierKey"}},
	gShortcut = 		{ default = "Start/Stop",cast = "string", onChange = "ffxivminion.UpdateShortcutChoice"},
	
	local winName = sck.mainwindow.name
	GUI_NewWindow(winName,sck.mainwindow.x,sck.mainwindow.y,sck.mainwindow.width,sck.mainwindow.height)
	local group = GetString("settings")
	local funcString = ""
	funcString = ffxivminion.Strings.Shortcuts()
    GUI_NewComboBox(winName,"Shortcut:",	"gShortcut",group,funcString)
	funcString = ffxivminion.Strings.ModKeys()
	GUI_NewComboBox(winName,"Modifier Key:","gModifierKey",group,funcString)
	funcString = ffxivminion.Strings.SCKeys()
	GUI_NewComboBox(winName,"Shortcut Key:","gShortcutKey",group,funcString)
	GUI_UnFoldGroup(winName,group )
	GUI_SizeWindow(winName,200,200)
	GUI_WindowVisible(winName, false)
	
	cpOptions = Settings.FFXIVMINION.cpOptions
	cpOption = Settings.FFXIVMINION.cpOption
	cpTCastIDs = Settings.FFXIVMINION.cpTCastIDs
	cpTBuffs = Settings.FFXIVMINION.cpTBuffs
	
	sck.UpdateShortcutOptions
end

function sck.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if (k == "gShortcut") then			
			sck.UpdateShortcutChoice()
            Settings.FFXIVMINION[tostring(k)] = v
		end
		 if (k == "gShortcutKey") then			
			sck.UpdateShortcut("skey")
            Settings.FFXIVMINION[tostring(k)] = v
		end
		 if (k == "gModifierKey") then			
			sck.UpdateShortcut("mkey")
            Settings.FFXIVMINION[tostring(k)] = v
		end
	end
    GUI_RefreshWindow(sck.mainwindow.name)
end

function sck.UpdateShortcutOptions()
	local shortcuts = ""
	for k,v in pairs(sck.Shortcuts) do
		shortcuts = shortcuts..","..k
		
		if (Settings.FFXIVMINION.ClickCombo[k] == nil or Settings.FFXIVMINION.ClickCombo[k] == {}) then 
			local combo = {} 
			combo.key1 = "None"
			combo.value1 = 0
			combo.key2 = "None"
			combo.value2 = 0
			
			Settings.FFXIVMINION.ClickCombo[k] = combo
		end
	end
end

function sck.UpdateShortcut(key)
	if ( key == "mkey" ) then
		local v = Settings.FFXIVMINION.gModifierKey
		local CC = Settings.FFXIVMINION.ClickCombo
		CC[gShortcut].key1 = v
		for key,value in pairs(sck.ModifierKeys) do
			if key == v then 
				CC[gShortcut].value1 = value 
			end
		end
		Settings.FFXIVMINION.ClickCombo = CC
	elseif ( key == "skey" ) then
		local v = Settings.FFXIVMINION.gShortcutKey
		local CC = Settings.FFXIVMINION.ClickCombo
		CC[gShortcut].key2 = v
		for key,value in pairs(sck.ShortcutKeys) do
			if key == v then 
				CC[gShortcut].value2 = value 
			end
		end
		Settings.FFXIVMINION.ClickCombo = CC
	end
end

function ffxivminion.UpdateShortcutChoice()
	local CC = Settings.FFXIVMINION.ClickCombo[gShortcut]
	
	if (CC ~= nil) then
		gModifierKey = CC.key1
		gShortcutKey = CC.key2
	end
end

function sck.ShowMenu()
	local wnd = GUI_GetWindowInfo(ffxivminion.Windows.Main.Name)	
    GUI_MoveWindow( sck.mainwindow.name, wnd.x+wnd.width,wnd.y) 
    GUI_WindowVisible( sck.mainwindow.name, true)	
	sck.UpdateShortcutChoice()
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
}

RegisterEventHandler("ShortcutManager.toggle", sck.ShowMenu)
RegisterEventHandler("Module.Initalize",sck.ModuleInit)
RegisterEventHandler("GUI.Update",sck.GUIVarUpdate)
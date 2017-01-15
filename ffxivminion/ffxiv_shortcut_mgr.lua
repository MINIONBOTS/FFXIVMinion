sck = {}
sck.hotkeyThrottle = 0

sck.GUI = {
	name = "Shortcut Manager",
	open = true,
	visible = true,
}

sck.hotkeys = {
	{
		label = "Start / Stop", mod1 = "SCK_StartStop_Mod1", mod2 = "SCK_StartStop_Mod2", key = "SCK_StartStop_Key", 
		event = function() ml_global_information.ToggleRun() end
	},
}

function sck.ModuleInit() 	
	for _,hotkey in pairsByKeys(sck.hotkeys) do
		_G[hotkey.mod1] = ffxivminion.GetSetting(hotkey.mod1,1)
		_G[hotkey.mod2] = ffxivminion.GetSetting(hotkey.mod2,1)
		_G[hotkey.key] = ffxivminion.GetSetting(hotkey.key,1)
	end
end

function sck.DrawCall( event, ticks )
	
	local gamestate;
	if (GetGameState and GetGameState()) then
		gamestate = GetGameState()
	else
		gamestate = 3
	end
	
	-- Switch according to the gamestate
	if (sck.GUI.open) then	
		GUI:SetNextWindowPosCenter(GUI.SetCond_Appearing)
		GUI:SetNextWindowSize(350,300,GUI.SetCond_Always) --set the next window size, only on first ever
		sck.GUI.visible, sck.GUI.open = GUI:Begin(sck.GUI.name, sck.GUI.open)
		if ( sck.GUI.visible ) then 
			for _,hotkey in pairsByKeys(sck.hotkeys) do
				GUI:Text(hotkey.label)
				sck.DrawModKey("##"..hotkey.label.."-hotkeys-mod1",hotkey.mod1); GUI:SameLine();
				sck.DrawModKey("##"..hotkey.label.."-hotkeys-mod2",hotkey.mod2); GUI:SameLine();
				sck.DrawClickKey("##"..hotkey.label.."-hotkeys-click",hotkey.key)
			end
		end
		GUI:End()
	end

	
	local shiftPressed, controlPressed = GUI:IsKeyDown(16), GUI:IsKeyDown(17)
	
	local doThrottle = false
	for _,hotkey in pairsByKeys(sck.hotkeys) do
		local mod1var = _G[hotkey.mod1]
		local mod2var = _G[hotkey.mod2]
		local keyvar = _G[hotkey.key]
		
		local stop = false
		
		if (keyvar ~= 1) then
			local mod1 = sck.ModifierClicksMap[mod1var]
			local mod2 = sck.ModifierClicksMap[mod2var]
			
			local key = sck.ClicksMap[keyvar]
			if (key ~= nil) then
				if (GUI:IsKeyPressed(key) and os.clock() > sck.hotkeyThrottle) then		
				
					local doEvent = true
					if (shiftPressed and mod1 ~= 16 and mod2 ~= 16) or
						(not shiftPressed and (mod1 == 16 or mod2 == 16)) then
						doEvent = false
					end
					if (controlPressed and mod1 ~= 17 and mod2 ~= 17) or
						(not controlPressed and (mod1 == 17 or mod2 == 17)) then
						doEvent = false
					end
					
					if (doEvent) then
						if (hotkey.event ~= nil and type(hotkey.event) == "function") then
							local ret = hotkey.event()
							doThrottle = true
							if (ret == true) then
								stop = true
							end
						end
					end
				end
			end
		end
		if (stop) then 
			break 
		end
	end
	if (doThrottle) then
		profile.hotkeyThrottle = os.clock() + .25
	end
end

function sck.DrawModKey(comboid,varname)
	GUI:PushItemWidth(75)
	local newModifier1 = GUI:Combo(comboid, _G[varname], sck.ModifierClicksDisplay)
	if (newModifier1 ~= _G[varname]) then
		_G[varname] = newModifier1
		Settings.FFXIVMINION[varname] = _G[varname]
	end
	GUI:PopItemWidth()
end

function sck.DrawMouseKey(comboid,varname)
	GUI:PushItemWidth(125)
	local newClick = GUI:Combo(comboid, _G[varname], sck.MouseClicksDisplay)
	if (newClick ~= _G[varname]) then
		_G[varname] = newClick
		Settings.FFXIVMINION[varname] = _G[varname]
	end
	GUI:PopItemWidth()
end

function sck.DrawClickKey(comboid,varname)
	GUI:PushItemWidth(125)
	local newClick = GUI:Combo(comboid, _G[varname], sck.ClicksDisplay)
	if (newClick ~= _G[varname]) then
		_G[varname] = newClick
		Settings.FFXIVMINION[varname] = _G[varname]
	end
	GUI:PopItemWidth()
end

function sck.CreateDisplayMap(boxtable)
	local display = {}
	local map = {}
	local i = 1
	
	if (ValidTable(boxtable)) then
		for k,v in pairsByKeys(boxtable) do
			display[i] = v
			map[i] = k
			i = i + 1
		end
	end
	
	return display,map
end

sck.MouseClicksMap = {
	[1] = 0,
	[2] = 1,
	[3] = 2,
}

sck.MouseClicksDisplay = {
	[1] = "Left Button",
	[2] = "Right Button",
	[3] = "Middle Button",	
}

sck.ModifierClicks = {
	[1] = "None",
	[16] = "Shift",
	[17] = "Control",
	--[18] = "Alt",
}

sck.ModifierClicksDisplay,sck.ModifierClicksMap = sck.CreateDisplayMap(sck.ModifierClicks)

sck.Clicks = {
	[1] = "None",
	[4] = "Middle Mouse",
	[5] = "Mouse 4",
	[6] = "Mouse 5",
	[19] = "PAUSE",
	[32] = "SPACEBAR",
	[33] = "PAGE UP",
	[34] = "PAGE DOWN",
	[35] = "END",
	[36] = "HOME",
	[37] = "LEFT ARROW",
	[38] = "UP ARROW",
	[39] = "RIGHT ARROW",
	[40] = "DOWN ARROW",
	[42] = "PRINT",
	[45] = "INS",
	[46] = "DEL",
	[48] = "0",
	[49] = "1",
	[50] = "2",
	[51] = "3",
	[52] = "4",
	[53] = "5",
	[54] = "6",
	[55] = "7",
	[56] = "8",
	[57] = "9",
	[65] = "A",
	[66] = "B",
	[67] = "C",
	[68] = "D",
	[69] = "E",
	[70] = "F",
	[71] = "G",
	[72] = "H",
	[73] = "I",
	[74] = "J",
	[75] = "K",
	[76] = "L",
	[77] = "M",
	[78] = "N",
	[79] = "O",
	[80] = "P",
	[81] = "Q",
	[82] = "R",
	[83] = "S",
	[84] = "T",
	[85] = "U",
	[86] = "V",
	[87] = "W",
	[88] = "X",
	[89] = "Y",
	[90] = "Z",
	[96] = "NUM 0",
	[97] = "NUM 1",
	[98] = "NUM 2",
	[99] = "NUM 3",
	[100] = "NUM 4",
	[101] = "NUM 5",
	[102] = "NUM 6",
	[103] = "NUM 7",
	[104] = "NUM 8",
	[105] = "NUM 9",
	[108] = "Separator",
	[109] = "Subtract",
	[110] = "Decimal",
	[111] = "Divide",
	[112] = "F1",
	[113] = "F2",
	[114] = "F3",
	[115] = "F4",
	[116] = "F5",
	[117] = "F6",
	[118] = "F7",
	[119] = "F8",
	[120] = "F9",
	[121] = "F10",
	[122] = "F11",
	[123] = "F12",
}

sck.ClicksDisplay,sck.ClicksMap = sck.CreateDisplayMap(sck.Clicks)

RegisterEventHandler("Gameloop.Draw", sck.DrawCall)
RegisterEventHandler("Module.Initalize",sck.ModuleInit)
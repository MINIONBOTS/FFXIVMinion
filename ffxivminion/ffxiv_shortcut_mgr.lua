-- FFXIV-specific actions for minionlib's Shortcut Manager.
-- minionlib owns key capture, persistence, drawing, and input polling.
sck = {}
sck.GUI = ml_input_mgr.mainWindow

-- Keep the legacy catalog shape for addons that extend sck.hotkeys.
sck.hotkeys = {
	{
		label = "Start / Stop", mod1 = "SCK_StartStop_Mod1", mod2 = "SCK_StartStop_Mod2", key = "SCK_StartStop_Key", mouse = "SCK_StartStop_Mouse",
		event = function () ml_global_information.ToggleRun() end
	},
	{
		label = "Unload Bot", mod1 = "SCK_Unload_Mod1", mod2 = "SCK_Unload_Mod2", key = "SCK_Unload_Key", mouse = "SCK_Unload_Mouse",
		event = function () Unload() end
	},
	{
		label = "Toggle Main Menu", mod1 = "SCK_ToggleMainMenu_Mod1", mod2 = "SCK_ToggleMainMenu_Mod2", key = "SCK_ToggleMainMenu_Key", mouse = "SCK_ToggleMainMenu_Mouse",
		event = function () ml_gui.ui_mgr.menu.shown = not ml_gui.ui_mgr.menu.shown end
	},
	{
		label = "Click-to-Move", mod1 = "SCK_ClickMove_Mod1", mod2 = "SCK_ClickMove_Mod2", key = "SCK_ClickMove_Mod3", mouse = "SCK_ClickMove_Mouse",
		event = function ()
			if (Player:IsMoving()) then
				Player:Stop()
				ml_global_information.Await(1500, function () return not Player:IsMoving() end)
			else
				local gameCoords = Hacks:GetGameCoordsFromMapPosition(GUI:GetMousePos())
				if (table.valid(gameCoords)) then
					local y1 = Player.pos.y + 100
					local y2 = Player.pos.y - 100

					for i = y1, y1-500, -1 do
						local trypos = {x = gameCoords.x, y = i, z = gameCoords.z}
						local p = NavigationManager:GetClosestPointOnMesh(trypos)
						if (table.valid(p)) then
							d("1: found meshpos")
							table.print(p)
							Player:MoveTo(p.x,p.y,p.z)
							return true
						end
					end

					for i = y2, y2+500, 1 do
						local trypos = {x = gameCoords.x, y = i, z = gameCoords.z}
						local p = NavigationManager:GetClosestPointOnMesh(trypos)
						if (table.valid(p)) then
							d("2: found meshpos")
							table.print(p)
							Player:MoveTo(p.x,p.y,p.z)
							return true
						end
					end
				end
			end
		end
	},
	{
		label = "Click-to-Teleport", mod1 = "SCK_ClickTeleport_Mod1", mod2 = "SCK_ClickTeleport_Mod2", key = "SCK_ClickTeleport_Mod3", mouse = "SCK_ClickTeleport_Mouse",
		event = function ()
			if (Player:IsMoving()) then
				Player:Stop()
				ml_global_information.Await(1500, function () return not Player:IsMoving() end)
			else
				local gameCoords = Hacks:GetGameCoordsFromMapPosition(GUI:GetMousePos())
				if (table.valid(gameCoords)) then
					local y1 = Player.pos.y + 100
					local y2 = Player.pos.y - 100

					for i = y1, y1-500, -1 do
						local trypos = {x = gameCoords.x, y = i, z = gameCoords.z}
						local p = NavigationManager:GetClosestPointOnMesh(trypos)
						if (table.valid(p)) then
							d("1: found meshpos")
							table.print(p)
							Hacks:TeleportToXYZ(p.x,p.y,p.z,true)
							return true
						end
					end

					for i = y2, y2+500, 1 do
						local trypos = {x = gameCoords.x, y = i, z = gameCoords.z}
						local p = NavigationManager:GetClosestPointOnMesh(trypos)
						if (table.valid(p)) then
							d("2: found meshpos")
							table.print(p)
							Hacks:TeleportToXYZ(p.x,p.y,p.z,true)
							return true
						end
					end
				end
			end
		end
	},
	{
		label = "Click-for-pos", mod1 = "SCK_Clickpos_Mod1", mod2 = "SCK_Clickpos_Mod2", key = "SCK_Clickpos_Mod3", mouse = "SCK_Clickpos_Mouse",
		event = function ()
			local gameCoords = Hacks:GetGameCoordsFromMapPosition(GUI:GetMousePos())
			d(gameCoords)
		end
	},
	{
		label = "SKM Filter 1", mod1 = "SCK_Filter1_Mod1", mod2 = "SCK_Filter1_Mod2", key = "SCK_Filter1_Key", mouse = "SCK_Filter1_Mouse",
		event = function ()
			gAssistFilter1 = not gAssistFilter1
			Settings.FFXIVMINION.gAssistFilter1 = gAssistFilter1
		end
	},
	{
		label = "SKM Filter 2", mod1 = "SCK_Filter2_Mod1", mod2 = "SCK_Filter2_Mod2", key = "SCK_Filter2_Key", mouse = "SCK_Filter2_Mouse",
		event = function ()
			gAssistFilter2 = not gAssistFilter2
			Settings.FFXIVMINION.gAssistFilter2 = gAssistFilter2
		end
	},
	{
		label = "SKM Filter 3", mod1 = "SCK_Filter3_Mod1", mod2 = "SCK_Filter3_Mod2", key = "SCK_Filter3_Key", mouse = "SCK_Filter3_Mouse",
		event = function ()
			gAssistFilter3 = not gAssistFilter3
			Settings.FFXIVMINION.gAssistFilter3 = gAssistFilter3
		end
	},
	{
		label = "SKM Filter 4", mod1 = "SCK_Filter4_Mod1", mod2 = "SCK_Filter4_Mod2", key = "SCK_Filter4_Key", mouse = "SCK_Filter4_Mouse",
		event = function ()
			gAssistFilter4 = not gAssistFilter4
			Settings.FFXIVMINION.gAssistFilter4 = gAssistFilter4
		end
	},
	{
		label = "SKM Filter 5", mod1 = "SCK_Filter5_Mod1", mod2 = "SCK_Filter5_Mod2", key = "SCK_Filter5_Key", mouse = "SCK_Filter5_Mouse",
		event = function ()
			gAssistFilter5 = not gAssistFilter5
			Settings.FFXIVMINION.gAssistFilter5 = gAssistFilter5
		end
	},
	{
		label = "Tank Assist Toggle", mod1 = "SCK_Tank_Mod1", mod2 = "SCK_Tank_Mod2", key = "SCK_Tank_Mod3", mouse = "SCK_Tank_Mouse",
		event = function ()
			if FFXIV_Assist_Mode == GetString("none") then
				FFXIV_Assist_Mode = GetString("tankAssist")
				FFXIV_Assist_ModeIndex = 5
			else
				FFXIV_Assist_Mode = GetString("none")
				FFXIV_Assist_ModeIndex = 1
			end
		end
	},
}

function sck.RegisterShortcut(shortcut)
	if (type(shortcut) ~= "table" or type(shortcut.label) ~= "string"
		or shortcut.label == "" or type(shortcut.event) ~= "function")
	then
		return false
	end
	ml_input_mgr.registerFunction({
		name = shortcut.label,
		func = shortcut.event,
		toggle = shortcut.toggle ~= false,
		trigger = shortcut.trigger == true,
	})
	return true
end

for _,shortcut in pairsByKeys(sck.hotkeys) do
	sck.RegisterShortcut(shortcut)
end

-- Compatibility entry point for addons that used the former manager.
-- Added actions now participate in minionlib's active binding system.
function sck.AddShortcuts(shortcuts)
	if (not table.valid(shortcuts)) then return end
	for _,shortcut in pairs(shortcuts) do
		table.insert(sck.hotkeys, shortcut)
		sck.RegisterShortcut(shortcut)
	end
end

-- The modern manager initializes, draws, and polls through minionlib events.
function sck.ModuleInit()
	sck.GUI = ml_input_mgr.mainWindow
end

function sck.DrawCall()
end

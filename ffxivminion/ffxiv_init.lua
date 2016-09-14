-- Add things to ml_global_information, we no longer create it.
ml_global_information.MainWindow = { Name = GetString("settings"), x=50, y=50 , width=250, height=450 }
ml_global_information.BtnStart = { Name=GetString("startStop"), Event = "GUI_REQUEST_RUN_TOGGLE" }
ml_global_information.BtnPulse = { Name=GetString("doPulse"), Event = "Debug.Pulse" }
	
ml_global_information.path = GetStartupPath()
ml_global_information.Now = 0
ml_global_information.yield = {}
ml_global_information.path = GetStartupPath()
ml_global_information.nextRun = 0
ml_global_information.lastPulseShortened = false
ml_global_information.lastrun2 = 0
ml_global_information.CurrentClass = nil
ml_global_information.CurrentClassID = 0
ml_global_information.AttackRange = 2
ml_global_information.TaskUIInit = false
ml_global_information.MarkerMinLevel = 1
ml_global_information.MarkerMaxLevel = 50
ml_global_information.BlacklistContentID = ""
ml_global_information.WhitelistContentID = ""
ml_global_information.currentMarker = false
ml_global_information.MarkerTime = 0
ml_global_information.afkTimer = 0
ml_global_information.syncTimer = 0
ml_global_information.IsWaiting = false
ml_global_information.UnstuckTimer = 0
ml_global_information.stanceTimer = 0
ml_global_information.summonTimer = 0
ml_global_information.repairTimer = 0
ml_global_information.windowTimer = 0
ml_global_information.disableFlee = false
ml_global_information.updateFoodTimer = 0
ml_global_information.foodCheckTimer = 0
ml_global_information.rootCheckTimer = 0
ml_global_information.lastMode = ""
ml_global_information.itemIDsToEquip = {}
ml_global_information.idlePulseCount = 0
ml_global_information.autoStartQueued = false
ml_global_information.loadCompleted = false
ml_global_information.blacklistedAetherytes = {}
ml_global_information.navObstacles = {}
--ml_global_information.navObstaclesTimer = 0
ml_global_information.suppressRestTimer = 0
ml_global_information.queueSync = nil
ml_global_information.queueSyncForce = false
ml_global_information.queueSyncForced = false
ml_global_information.lastInventorySnapshot = {}
ml_global_information.repairBlacklist = {}
ml_global_information.avoidanceAreas = {}
ml_global_information.lastMeasure = 0
ml_global_information.requiresTransport = {}
ml_global_information.landing = nil
ml_global_information.queueLoader = false
ml_global_information.mainLoaded = false
ml_global_information.needsStealth = false
ml_global_information.gatherid = 0
ml_global_information.targetid = 0
ml_global_information.foods = {}
ml_global_information.mainTask = nil;
ml_global_information.drawMode = 1

--Setup Globals
ml_global_information.lastUpdate = 0
ml_global_information.Player_Aetherytes = {}
ml_global_information.Player_Position = {}
ml_global_information.Player_Map = 0
ml_global_information.Player_HP = {}
ml_global_information.Player_MP = {}
ml_global_information.Player_TP = {}
ml_global_information.Player_InCombat = false

ml_global_information.chocoStance = {
	[GetString("stFollow")] = 3,
	[GetString("stFree")] = 4,
	[GetString("stDefender")] = 5,
	[GetString("stAttacker")] = 6,
	[GetString("stHealer")] = 7,
}

ml_global_information.classes = {}
ml_global_information.blacklistedAetherytes = {}

ml_global_information.chocoItemBuffs = {
	[7894] = { name = "Curiel Root (EXP)", item = 7894, buff1 = 536, buff2 = 537 },
	[7895] = { name = "Sylkis Bud (ATK)", item = 7895, buff1 = 538, buff2 = 539 },
	[7897] = { name = "Mimmet Gourd (Heal)", item = 7897, buff1 = 540, buff2 = 541 },
	[7898] = { name = "Tantalplant (HP)", item = 7898, buff1 = 542, buff2 = 543 },
	[7900] = { name = "Pahsana Fruit (ENM)", item = 7900, buff1 = 544, buff2 = 545 },
}

function ml_global_information.ToggleRun()	
	if ( ml_task_hub.shouldRun ) then
		ml_task_hub.shouldRun = false
		gBotRunning = "0"
		FFXIV_Common_BotRunning = false
	else
		ml_task_hub.shouldRun = true
		gBotRunning = "1"
		FFXIV_Common_BotRunning = true
	end	

	if (ml_task_hub.shouldRun and ml_global_information.UnstuckTimer == 0) then
		ml_global_information.Reset()
	else
		ml_global_information.Stop()
	end
end

function ml_global_information.GetMainIcon()
	local iconPath = ml_global_information.path.."\\GUI\\UI_Textures\\"
	if (ml_global_information.drawMode == 1) then
		return iconPath.."collapse.png"
	else
		return iconPath.."expand.png"
	end
end

function ml_global_information.DrawMarker(marker)

	local markertype = marker:GetType()
	local pos = marker:GetPosition()
	
    local color = 0
    local s = 1 -- size
    local h = 5 -- height
	
    if ( markertype == GetString("grindMarker") ) then
        color = 1 -- red
    elseif ( markertype == GetString("fishingMarker") ) then
        color = 4 --blue
    elseif ( markertype == GetString("miningMarker") ) then
        color = 7 -- yellow	
    elseif ( markertype == GetString("botanyMarker") ) then
        color = 8 -- orange
	elseif ( markertype == GetString("huntMarker") ) then
		color = 2
    end
    --Building the vertices for the object
    local t = { 
        [1] = { pos.x-s, pos.y+s+h, pos.z-s, color },
        [2] = { pos.x+s, pos.y+s+h, pos.z-s, color  },	
        [3] = { pos.x,   pos.y-s+h,   pos.z, color  },
        
        [4] = { pos.x+s, pos.y+s+h, pos.z-s, color },
        [5] = { pos.x+s, pos.y+s+h, pos.z+s, color  },	
        [6] = { pos.x,   pos.y-s+h,   pos.z, color  },
        
        [7] = { pos.x+s, pos.y+s+h, pos.z+s, color },
        [8] = { pos.x-s, pos.y+s+h, pos.z+s, color  },	
        [9] = { pos.x,   pos.y-s+h,   pos.z, color  },
        
        [10] = { pos.x-s, pos.y+s+h, pos.z+s, color },
        [11] = { pos.x-s, pos.y+s+h, pos.z-s, color  },	
        [12] = { pos.x,   pos.y-s+h,   pos.z, color  },
    }
    
    local id = RenderManager:AddObject(t)	
    return id
end

function ml_global_information.NodeNeighbors(self)
	if (ValidTable(self.neighbors)) then
		local validNeighbors = deepcopy(self.neighbors)
		
		for id,entries in pairs(validNeighbors) do
			for i,entrydata in pairs(entries) do
				if (entrydata.requires) then
					local add = true
					local requirements = shallowcopy(entrydata.requires)
					for requirement,value in pairs(requirements) do
						local f = assert(loadstring("return " .. requirement))()
						if (f ~= nil) then
							if (f ~= value) then
								add = false
							end
						end
						if (not add) then
							break
						end
					end
					if (not add) then
						if (TableSize(validNeighbors[id]) > 1) then
							--d("Requirement not met, removing neighbor ["..tostring(id).."], entry # ["..tostring(i).."].")
							validNeighbors[id][i] = nil
						elseif (TableSize(validNeighbors[id]) == 1) then	
							--d("Requirement not met, removing neighbor ["..tostring(id).."] entirely.")
							validNeighbors[id] = nil
						end
					end
				end
			end			
		end
		
		return validNeighbors
	end
    return nil
end

function ml_global_information.NodeClosestNeighbor(self, origin, id)
	local neighbor = self:GetNeighbor(id)
	if (ValidTable(neighbor)) then
		if (TableSize(neighbor) > 1) then
			local bestPos = nil
			local bestDist = math.huge
			for id, posTable in pairs(neighbor) do
				local valid = true
				if (posTable.requires) then
					local requirements = shallowcopy(posTable.requires)
					for requirement,value in pairs(requirements) do
						local f = assert(loadstring("return " .. requirement))()
						if (f ~= nil) then
							if (f ~= value) then
								valid = false
							end
						end
						if (not valid) then
							break
						end
					end
				end
				
				if (valid) then
					local dist = PDistance3D(origin.x, origin.y, origin.z, posTable.x, posTable.y, posTable.z)
					if (dist < bestDist) then
						bestPos = posTable
						bestDist = dist
					end
				end
			end
			
			if (ValidTable(bestPos)) then
				return bestPos
			end
		elseif (TableSize(neighbor == 1)) then
			local i,best = next(neighbor)
			if (i and best) then
				return best
			end
		end
    end
    
    return nil
end

function ml_global_information.CheckboxConvert(newval)
	
end

function ml_global_information.AwaitDo(param1, param2, param3, param4, param5)
	if (param1 and type(param2) == "number" and param2 and type(param2) == "number") then
		ml_global_information.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			dowhile = param4,
			followall = param5,
		}
	else
		ml_global_information.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			dowhile = param3,
			followall = param4,
		}
	end
end

function ml_global_information.Init()
	-- Update default meshes.
	do
		ml_mesh_mgr.averagegameunitsize = 1
		ml_mesh_mgr.useQuaternion = false
		
		-- Set default meshes SetDefaultMesh(mapid, filename)
		ml_mesh_mgr.SetDefaultMesh(134, "Middle La Noscea")
		ml_mesh_mgr.SetDefaultMesh(135, "Lower La Noscea")
		ml_mesh_mgr.SetDefaultMesh(137, "Eastern La Noscea")
		ml_mesh_mgr.SetDefaultMesh(138, "Western La Noscea")
		ml_mesh_mgr.SetDefaultMesh(139, "Upper La Noscea")
		ml_mesh_mgr.SetDefaultMesh(140, "Western Thanalan")
		ml_mesh_mgr.SetDefaultMesh(141, "Central Thanalan")
		ml_mesh_mgr.SetDefaultMesh(145, "Eastern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(146, "Southern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(147, "Northern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(148, "Central Shroud")
		ml_mesh_mgr.SetDefaultMesh(152, "East Shroud")
		ml_mesh_mgr.SetDefaultMesh(153, "South Shroud")
		ml_mesh_mgr.SetDefaultMesh(154, "North Shroud")
		ml_mesh_mgr.SetDefaultMesh(155, "Coerthas")
		ml_mesh_mgr.SetDefaultMesh(156, "Mor Dhona")
		ml_mesh_mgr.SetDefaultMesh(180, "Outer La Noscea")
		ml_mesh_mgr.SetDefaultMesh(337, "Wolves Den")
		ml_mesh_mgr.SetDefaultMesh(336, "Wolves Den")
		ml_mesh_mgr.SetDefaultMesh(175, "Wolves Den")
		ml_mesh_mgr.SetDefaultMesh(352, "Wolves Den")
		ml_mesh_mgr.SetDefaultMesh(186, "Wolves Den")
		
		--ml_mesh_mgr.SetDefaultMesh(431, "Seal Rock")
		
		ml_mesh_mgr.SetDefaultMesh(130, "Ul dah - Steps of Nald")
		ml_mesh_mgr.SetDefaultMesh(182, "Ul dah - Steps of Nald")
		ml_mesh_mgr.SetDefaultMesh(131, "Ul dah - Steps of Thal")
		ml_mesh_mgr.SetDefaultMesh(128, "Limsa (Upper)")
		ml_mesh_mgr.SetDefaultMesh(181, "Limsa (Upper)")
		ml_mesh_mgr.SetDefaultMesh(129, "Limsa (Lower)")
		ml_mesh_mgr.SetDefaultMesh(132, "New Gridania")
		ml_mesh_mgr.SetDefaultMesh(183, "New Gridania")
		ml_mesh_mgr.SetDefaultMesh(133, "Old Gridania")
		ml_mesh_mgr.SetDefaultMesh(376, "Frontlines")
		ml_mesh_mgr.SetDefaultMesh(422, "Frontlines - Slaughter")
		ml_mesh_mgr.SetDefaultMesh(212, "Waking Sands")
		ml_mesh_mgr.SetDefaultMesh(179, "Gridania - Inn")
		ml_mesh_mgr.SetDefaultMesh(178, "Ul dah - Inn")
		ml_mesh_mgr.SetDefaultMesh(177, "Limsa Lominsa - Inn")
		
		ml_mesh_mgr.SetDefaultMesh(210, "Ul dah - Heart of the Sworn")
		ml_mesh_mgr.SetDefaultMesh(205, "Lotus Stand")
		ml_mesh_mgr.SetDefaultMesh(198, "Limsa Lominsa - Command")
		ml_mesh_mgr.SetDefaultMesh(204, "Gridania - First Bow")
		ml_mesh_mgr.SetDefaultMesh(286, "ImOnABoat")
		
		ml_mesh_mgr.SetDefaultMesh(144, "Gold Saucer")
		ml_mesh_mgr.SetDefaultMesh(388, "Gold Saucer - Chocobo Square")
		
		ml_mesh_mgr.SetDefaultMesh(331, "Garuda_Entrance")
		ml_mesh_mgr.SetDefaultMesh(351, "Rising Stones")
		ml_mesh_mgr.SetDefaultMesh(395, "Intercessory")
		ml_mesh_mgr.SetDefaultMesh(397, "Coerthas Western Highlands")
		ml_mesh_mgr.SetDefaultMesh(398, "The Dravanian Forelands")
		ml_mesh_mgr.SetDefaultMesh(399, "The Dravanian Hinterlands")
		ml_mesh_mgr.SetDefaultMesh(400, "The Churning Mists")
		ml_mesh_mgr.SetDefaultMesh(401, "Sea of Clouds")
		ml_mesh_mgr.SetDefaultMesh(402, "Azys Lla")
		ml_mesh_mgr.SetDefaultMesh(418, "Ishgard - Foundation")
		ml_mesh_mgr.SetDefaultMesh(419, "Ishgard - The Pillars")
		ml_mesh_mgr.SetDefaultMesh(427, "Ishgard - Scholasticate")
		ml_mesh_mgr.SetDefaultMesh(439, "Ishgard - Chocobo Proving Grounds")
		ml_mesh_mgr.SetDefaultMesh(433, "Ishgard - Fortempts Manor")
		ml_mesh_mgr.SetDefaultMesh(456, "Ishgard - Ruling Chamber")
		ml_mesh_mgr.SetDefaultMesh(463, "Matoyas Cave")
		ml_mesh_mgr.SetDefaultMesh(478, "Idyllshire") 
		
		-- Dungeons
		ml_mesh_mgr.SetDefaultMesh(435, "[Dungeon]Aery")
		ml_mesh_mgr.SetDefaultMesh(167, "[Dungeon]AmdaporKeep")
		ml_mesh_mgr.SetDefaultMesh(172, "[Dungeon]AurumVale")
		ml_mesh_mgr.SetDefaultMesh(158, "[Dungeon]Brayflox")
		ml_mesh_mgr.SetDefaultMesh(362, "[Dungeon]BrayfloxHM")
		ml_mesh_mgr.SetDefaultMesh(161, "[Dungeon]Copperbell")
		ml_mesh_mgr.SetDefaultMesh(349, "[Dungeon]CopperbellHM")
		ml_mesh_mgr.SetDefaultMesh(170, "[Dungeon]CuttersCry")
		ml_mesh_mgr.SetDefaultMesh(434, "[Dungeon]DuskVigil")
		ml_mesh_mgr.SetDefaultMesh(171, "[Dungeon]DzemaelDarkhold")
		ml_mesh_mgr.SetDefaultMesh(162, "[Dungeon]Halatali")
		ml_mesh_mgr.SetDefaultMesh(360, "[Dungeon]HalataliHM")
		ml_mesh_mgr.SetDefaultMesh(166, "[Dungeon]Haukke")
		ml_mesh_mgr.SetDefaultMesh(350, "[Dungeon]HaukkeHM")
		ml_mesh_mgr.SetDefaultMesh(361, "[Dungeon]HullbreakerIsle")
		ml_mesh_mgr.SetDefaultMesh(150, "[Dungeon]KeepersOfTheLake")
		ml_mesh_mgr.SetDefaultMesh(363, "[Dungeon]LostCity")
		ml_mesh_mgr.SetDefaultMesh(160, "[Dungeon]PharosSirius")
		ml_mesh_mgr.SetDefaultMesh(157, "[Dungeon]Sastasha")
		ml_mesh_mgr.SetDefaultMesh(387, "[Dungeon]SastashaHM")
		ml_mesh_mgr.SetDefaultMesh(371, "[Dungeon]Snowcloak")
		ml_mesh_mgr.SetDefaultMesh(441, "[Dungeon]SohmAl")
		ml_mesh_mgr.SetDefaultMesh(168, "[Dungeon]StoneVigil")
		ml_mesh_mgr.SetDefaultMesh(365, "[Dungeon]StoneVigilHM")
		ml_mesh_mgr.SetDefaultMesh(163, "[Dungeon]SunkenTemple")
		ml_mesh_mgr.SetDefaultMesh(367, "[Dungeon]SunkenTempleHM")
		ml_mesh_mgr.SetDefaultMesh(164, "[Dungeon]TamTara")
		ml_mesh_mgr.SetDefaultMesh(373, "[Dungeon]TamTaraHM")
		ml_mesh_mgr.SetDefaultMesh(169, "[Dungeon]TotoRak")
		ml_mesh_mgr.SetDefaultMesh(421, "[Dungeon]Vault")
		ml_mesh_mgr.SetDefaultMesh(159, "[Dungeon]WanderersPalace")
		ml_mesh_mgr.SetDefaultMesh(332, "[Trial]CapeWestwind")
		ml_mesh_mgr.SetDefaultMesh(426, "[Trial]Chrysalis")
		ml_mesh_mgr.SetDefaultMesh(208, "[Trial]Garuda")
		ml_mesh_mgr.SetDefaultMesh(202, "[Trial]Ifrit")
		ml_mesh_mgr.SetDefaultMesh(281, "[Trial]Leviathan")
		ml_mesh_mgr.SetDefaultMesh(207, "[Trial]MoogleMog")
		ml_mesh_mgr.SetDefaultMesh(374, "[Trial]Ramuh")
		ml_mesh_mgr.SetDefaultMesh(377, "[Trial]Shiva")
		ml_mesh_mgr.SetDefaultMesh(206, "[Trial]Titan")		
	end
		
	
	-- General overrides.
	do
		-- setup marker manager callbacks and vars
		ml_marker_mgr.GetPosition = 	function () return Player.pos end
		ml_marker_mgr.GetLevel = 		function () return Player.level end
		ml_marker_mgr.DrawMarker =		ml_global_information.DrawMarker
		ml_node.ValidNeighbors = 		ml_global_information.NodeNeighbors
		ml_node.GetClosestNeighborPos = ml_global_information.NodeClosestNeighbor
		
		-- setup meshmanager
		if ( ml_mesh_mgr ) then
			--ml_mesh_mgr.parentWindow.Name = ml_global_information.MainWindow.Name
			ml_mesh_mgr.GetMapID = function () return Player.localmapid end
			ml_mesh_mgr.GetMapName = function () return AceLib.API.Map.GetMapName(ml_mesh_mgr.GetMapID()) end  -- didnt we have a mapname somewhere?
			ml_mesh_mgr.GetPlayerPos = function () return Player.pos end
			ml_mesh_mgr.SetEvacPoint = function ()
				if (gmeshname ~= "" and Player.onmesh) then
					ml_marker_mgr.markerList["evacPoint"] = Player.pos
					ml_marker_mgr.WriteMarkerFile(ml_marker_mgr.markerPath)
				end
			end
			
			ml_mesh_mgr.GetAllowedMaps = function (mapname)
				local allowedMaps = {}
				if (FileExists(ml_mesh_mgr.defaultpath.."\\"..mapname..".data")) then					
					local mapdata,e = persistence.load(ml_mesh_mgr.defaultpath.."\\"..mapname..".data")
					if (ValidTable(mapdata)) then
						local maps = mapdata.AllowedMapIDs
						if (ValidTable(maps)) then
							for mapid,duplicate in pairsByKeys(maps) do
								allowedMaps[mapid] = duplicate
							end
						end
					else
						if (e) then
							d("[GetAllowedMaps]: "..e)
						end
					end
				end
				
				return allowedMaps
			end
			
			ml_mesh_mgr.GetString = function (inputString)
				if (ValidString(inputString)) then
					if (not string.find(inputString,'%s%-%s%[.+%]')) then
						local allowedMaps = ml_mesh_mgr.GetAllowedMaps(inputString)
						if (ValidTable(allowedMaps)) then
							local mapid,dup = next(allowedMaps)
							local mapname = AceLib.API.Map.GetMapName(mapid)
							if (mapname and mapname ~= "") then
								return inputString.." - ["..mapname.."]"
							end
						end
					end
				end
				return inputString
			end
				
			ml_mesh_mgr.GetFileName = function (inputString) 
				if (ValidString(inputString)) then
					if (string.find(inputString,'%s%-%s%[.+%]')) then
						inputString = string.gsub(inputString,'%s%-%s%[.+%]',"")
					end
				end
				return inputString 
			end
			
			ml_mesh_mgr.AllowedMapsLookup = function (mapid) 
				local placeid = AceLib.API.Map.GetPlaceID(mapid) or 0
				if (placeid ~= 0) then
					local allowedMaps = AceLib.API.Map.GetValidMaps(placeid)
					if (ValidTable(allowedMaps)) then
						return allowedMaps
					end
				end
				return { [mapid] = mapid }
			end
		end
	end


	local ffxiv_mainmenu = {
		header = { id = "FFXIVMINION##MENU_HEADER", expanded = false, name = "FFXIVMinion", texture = GetStartupPath().."\\GUI\\UI_Textures\\ffxiv_shiny.png"},
		members = {	
			{ id = "FFXIVMINION##MENU_WINDOWS", name = "Windows", sort = true },
			{ id = "FFXIVMINION##MENU_DEV", name = "Dev Tools", onClick = function() Dev.GUI.open = not Dev.GUI.open end, tooltip = "Open the Developer tools." },
		}
	}
	ml_gui.ui_mgr:AddComponent(ffxiv_mainmenu)
end

--[[
ml_gui.ui_mgr:AddMember({ id = "FFXIVMINION##MENU_DEV1", name = "Dev1", onClick = function() Dev.GUI.open = not Dev.GUI.open end, tooltip = "Open the Dev monitor."},"FFXIVMINION##MENU_HEADER")
ml_gui.ui_mgr:AddMember({ id = "FFXIVMINION##MENU_DEV2", name = "Dev2", onClick = function() Dev.GUI.open = not Dev.GUI.open end, tooltip = "Open the Dev monitor."},"FFXIVMINION##MENU_HEADER")
ml_gui.ui_mgr:AddMember({ id = "FFXIVMINION##MENU_DEV3", name = "Dev3", onClick = function() Dev.GUI.open = not Dev.GUI.open end, tooltip = "Open the Dev monitor."},"FFXIVMINION##MENU_HEADER")
ml_gui.ui_mgr:AddMember({ id = "FFXIVMINION##MENU_DEV4", name = "Dev4", onClick = function() Dev.GUI.open = not Dev.GUI.open end, tooltip = "Open the Dev monitor."},"FFXIVMINION##MENU_HEADER")
ml_gui.ui_mgr:AddMember({ id = "FFXIVMINION##MENU_DEV5", name = "Dev5", onClick = function() Dev.GUI.open = not Dev.GUI.open end, sort = true},"FFXIVMINION##MENU_HEADER")
ml_gui.ui_mgr:AddSubMember({ id = "FFXIVMINION##DEV_1", name = "DevA", onClick = function() Dev.GUI.open = not Dev.GUI.open end, tooltip = "Open the Dev monitor."},"FFXIVMINION##MENU_HEADER","FFXIVMINION##MENU_DEV5")
ml_gui.ui_mgr:AddSubMember({ id = "FFXIVMINION##DEV_2", name = "DevE", onClick = function() Dev.GUI.open = not Dev.GUI.open end, tooltip = "Open the Dev monitor."},"FFXIVMINION##MENU_HEADER","FFXIVMINION##MENU_DEV5")
ml_gui.ui_mgr:AddSubMember({ id = "FFXIVMINION##DEV_3", name = "DevM", onClick = function() Dev.GUI.open = not Dev.GUI.open end, tooltip = "Open the Dev monitor."},"FFXIVMINION##MENU_HEADER","FFXIVMINION##MENU_DEV5")
ml_gui.ui_mgr:AddSubMember({ id = "FFXIVMINION##DEV_4", name = "DevC", onClick = function() Dev.GUI.open = not Dev.GUI.open end, tooltip = "Open the Dev monitor."},"FFXIVMINION##MENU_HEADER","FFXIVMINION##MENU_DEV5")
--]]

RegisterEventHandler("Module.Initalize",ml_global_information.Init)
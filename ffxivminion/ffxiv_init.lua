-- Add things to ml_global_information, we no longer create it.	
if (FFXIV.JOBS.VIPER == nil) then
	FFXIV.JOBS.VIPER = 41
end
if (FFXIV.JOBS.PICTOMANCER == nil) then
	FFXIV.JOBS.PICTOMANCER = 42
end

ml_global_information.path = GetStartupPath()
ml_global_information.Now = 0
ml_global_information.yield = {}
ml_global_information.nextRun = 0
ml_global_information.lastPulseShortened = false
ml_global_information.lastrun2 = 0
ml_global_information.CurrentClass = nil
ml_global_information.CurrentClassID = 0
ml_global_information.AttackRange = 2
ml_global_information.MarkerMinLevel = 1
ml_global_information.MarkerMaxLevel = 50
ml_global_information.BlacklistContentID = ""
ml_global_information.WhitelistContentID = ""
ml_global_information.MarkerTime = 0
ml_global_information.afkTimer = 0
ml_global_information.syncTimer = 0
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
ml_global_information.suppressRestTimer = 0
ml_global_information.lastInventorySnapshot = {}
ml_global_information.repairBlacklist = {}
ml_global_information.avoidanceAreas = {}
ml_global_information.lastMeasure = 0
ml_global_information.requiresTransport = {}
ml_global_information.landing = nil
ml_global_information.queueLoader = false
-- Split this into 2 variables to deal with the logic timing.

ml_global_information.gatherid = 0
ml_global_information.targetid = 0
ml_global_information.foods = {}
ml_global_information.mainTask = nil;
ml_global_information.drawMode = 1
ml_global_information.lastEquip = 0
ml_global_information.lastSkipTalk = 0
ml_global_information.buyBlacklist = {}

--Setup Globals
ml_global_information.lastUpdate = 0
ml_global_information.Player_Aetherytes = {}
ml_global_information.Player_Map = 0
ml_global_information.MeshReady = false

ml_global_information.chocoStance = {
	[GetString("stFollow")] = 3,
	[GetString("stFree")] = 4,
	[GetString("stDefender")] = 5,
	[GetString("stAttacker")] = 6,
	[GetString("stHealer")] = 7,
}

ml_global_information.classes = {}
ml_global_information.blacklistedAetherytes = {}

function ml_global_information.ToggleRun()	
	if ( ml_task_hub.shouldRun ) then
		ml_task_hub.shouldRun = false
		FFXIV_Common_BotRunning = false
	else
		if gBotMode ~= "assistMode" then
			ml_global_information.EnsureMeshDefaults()
		end
		ml_task_hub.shouldRun = true
		FFXIV_Common_BotRunning = true
	end	

	if (ml_task_hub.shouldRun) then
		ml_global_information.Reset()
	else
		ml_global_information.yield = {}
		ml_global_information.Stop()
	end
	
	-- Do some resets here.
	ml_marker_mgr.currentMarker = nil
end

function ml_global_information.GetMainIcon()
	local iconPath = ml_global_information.path.."\\GUI\\UI_Textures\\"
	if (ml_global_information.drawMode == 1) then
		return iconPath.."collapse.png"
	else
		return iconPath.."expand.png"
	end
end

function ml_global_information.NavEntryRequirementsMet(entry)
	if not entry or not entry.requires then
		return true
	end
	for requirement, value in pairs(entry.requires) do
		local ok, ret = LoadString("return " .. requirement)
		if not ok or ret ~= value then
			return false
		end
	end
	return true
end

function ml_global_information.NodeNeighbors(self)
	if (table.valid(self.neighbors)) then
		local validNeighbors = deepcopy(self.neighbors)
		
		for id,entries in pairs(validNeighbors) do
			for i,entrydata in pairs(entries) do
				if not ml_global_information.NavEntryRequirementsMet(entrydata) then
					if (TableSize(validNeighbors[id]) > 1) then
						validNeighbors[id][i] = nil
					elseif (TableSize(validNeighbors[id]) == 1) then
						validNeighbors[id] = nil
					end
				end
			end
		end
		
		return validNeighbors
	end
    return nil
end

local _navLogKey = ""
local _navLogTime = 0

function ml_global_information.NodeClosestNeighbor(self, origin, id)
	local neighbor = self:GetNeighbor(id)
	if (table.valid(neighbor)) then
		local nsize = TableSize(neighbor)
		if (nsize > 1) then
			local bestPos = nil
			local bestDist = math.huge
			local skippedReq = 0
			local skippedNil = 0
			for ei, posTable in pairs(neighbor) do
				if not ml_global_information.NavEntryRequirementsMet(posTable) then
					skippedReq = skippedReq + 1
				elseif not posTable.x or not posTable.y or not posTable.z then
					skippedNil = skippedNil + 1
				elseif not origin or not origin.x or not origin.y or not origin.z then
					navd("[Nav] NodeClosestNeighbor: nil origin for dest=" .. tostring(id))
				else
					local dist = PDistance3D(origin.x, origin.y, origin.z, posTable.x, posTable.y, posTable.z)
					if (dist < bestDist) then
						bestPos = posTable
						bestDist = dist
					end
				end
			end
			
			if (table.valid(bestPos)) then
				local ref = bestPos.b or bestPos.g or bestPos.a or "walk"
				local posFrom  = bestPos._pos_source  or "static"
				local destFrom = bestPos._dest_source or "static"
				local key = tostring(id) .. "|" .. tostring(ref)
				local now = Now()
				if ((key ~= _navLogKey and (now - _navLogTime) > 500) or (now - _navLogTime) > 10000) then
					_navLogKey = key
					_navLogTime = now
					navd("[Nav] -> map " .. tostring(id) .. " via " .. tostring(ref)
						.. " | pos=" .. posFrom .. " dest=" .. destFrom
						.. " | (" .. string.format("%.1f, %.1f, %.1f", bestPos.x, bestPos.y, bestPos.z) .. ")")
				end
				return bestPos
			else
				navd("[Nav] NodeClosestNeighbor: NO bestPos for dest=" .. tostring(id)
					.. " entries=" .. nsize .. " skippedReq=" .. skippedReq .. " skippedNil=" .. skippedNil)
			end
		elseif (nsize == 1) then
			local i,best = next(neighbor)
			if (i and best) then
				if not ml_global_information.NavEntryRequirementsMet(best) then
					navd("[Nav] NodeClosestNeighbor: single entry for dest=" .. tostring(id)
						.. " failed requirements")
					return nil
				end
				local ref = best.b or best.g or best.a or "walk"
				local posFrom  = best._pos_source  or "static"
				local destFrom = best._dest_source or "static"
				local key = tostring(id) .. "|" .. tostring(ref)
				local now = Now()
				if ((key ~= _navLogKey and (now - _navLogTime) > 500) or (now - _navLogTime) > 10000) then
					_navLogKey = key
					_navLogTime = now
					navd("[Nav] -> map " .. tostring(id) .. " via " .. tostring(ref)
						.. " | pos=" .. posFrom .. " dest=" .. destFrom
						.. " | (" .. string.format("%.1f, %.1f, %.1f", best.x, best.y, best.z) .. ")")
				end
				return best
			end
		else
			navd("[Nav] NodeClosestNeighbor: unexpected nsize=" .. tostring(nsize) .. " for dest=" .. tostring(id))
		end
    end
    
    return nil
end

function ml_global_information.AwaitDo(param1, param2, param3, param4, param5)
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
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

function ml_global_information.AwaitThen(param1, param2, param3, param4)
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
		if (param4 ~= nil and type(param4) == "function") then
			ml_global_information.yield = {
				mintimer = IIF(param1 ~= 0,Now() + param1,0),
				maxtimer = IIF(param2 ~= 0,Now() + param2,0),
				evaluator = param3,
				followall = param4,
			}
		else
			ml_global_information.yield = {
				mintimer = IIF(param1 ~= 0,Now() + param1,0),
				maxtimer = IIF(param2 ~= 0,Now() + param2,0),
				followall = param3,
			}
		end
	else
		if (param3 ~= nil and type(param3) == "function") then
			ml_global_information.yield = {
				mintimer = 0,
				maxtimer = Now() + param1,
				evaluator = param2,
				followall = param3,
			}
		else
			ml_global_information.yield = {
				mintimer = 0,
				maxtimer = Now() + param1,
				followall = param2,
			}
		end
	end
end

-- code for delayed queueables, use to execute miscellaneous delayed actions/lua
ml_global_information.queueables = {}

-- add a function to be executed after a time specified by delay "timer" in ms, or earlyout function "earlyout"
function ml_global_information.Queue(timer,func,earlyout)
	local queueable = { timer = Now() + timer, executor = func, earlyout = earlyout }
	table.insert(ml_global_information.queueables,queueable)
end

function ml_global_information.Queueables()
	if (table.valid(ml_global_information.queueables)) then
		for k,v in pairsByKeys(ml_global_information.queueables) do
			if (Now() >= v.timer or (v.earlyout and type(v.earlyout) == "function" and v.earlyout() == true)) then
				if (v.executor and type(v.executor) == "function") then
					v.executor()
					ml_global_information.queueables[k] = nil
				end
			end
		end
	end
end

function ml_global_information.TestQueue()
	SendTextCommand("/echo reset")
	ml_global_information.Queue(5000,
		function() 
			SendTextCommand("/echo first") 
			ml_global_information.Queue(1000,
				function() 
					SendTextCommand("/echo second") 
				end
			)
		end
	)
end

function ml_global_information.EnsureMeshDefaults()
	if ml_global_information._meshDefaultsApplied then return true end
	local installer = ffxiv_mesh_defaults and ffxiv_mesh_defaults.ApplyDefaultMappings
	if not ml_mesh_mgr or type(installer) ~= "function" then
		return false
	end

	local migrationEnforce = not Settings.minionlib.newnavsystemlive_3
	local count = installer(function(mapId, meshName, force)
		ml_mesh_mgr.SetDefaultMesh(mapId, meshName, force)
	end, migrationEnforce and true or nil)

	if count > 0 then
		Settings.minionlib.newnavsystemlive_3 = true
		ml_global_information._meshDefaultsApplied = true
		-- This is a one-shot migration/default installer. Releasing its namespace
		-- lets Lua collect the function prototype and temporary closure while
		-- Settings.minionlib.DefaultMaps retains the mappings actually in use.
		ffxiv_mesh_defaults = nil
		return true
	end
	return false
end

function ml_global_information.Init()
	-- Core mesh-manager behavior is initialized immediately; the large default
	-- mapping is registered only when navigation first needs it.
	do
		BehaviorManager:ToggleMenu()
		ml_mesh_mgr.averagegameunitsize = 1
		ml_mesh_mgr.useQuaternion = false
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
			ml_mesh_mgr.GetMapID = function () return Player.localmapid end
			ml_mesh_mgr.GetMapName = function (mapid)
				local mapid = IsNull(mapid,Player.localmapid)
				return GetMapName(mapid) 
			end
			ml_mesh_mgr.GetPlayerPos = function () return Player.pos end
			
			
			ml_global_information.meshTranslations = {}
			local defaultMaps = Settings.minionlib.DefaultMaps
			if (table.valid(defaultMaps)) then
				for mapid,meshname in pairs(defaultMaps) do
					ml_global_information.meshTranslations[meshname] = GetMapName(mapid)
				end
			end
			
			ml_mesh_mgr.GetString = function (meshname)
				local returnstring = meshname
				if (ml_global_information.meshTranslations[meshname]) then
					returnstring = returnstring.." - ["..ml_global_information.meshTranslations[meshname].."]"
				end
				return returnstring
			end
				
			ml_mesh_mgr.GetFileName = function (inputString) 
				if (ValidString(inputString)) then
					if (string.contains(inputString,'%s%-%s%[.+%]')) then
						inputString = string.gsub(inputString,'%s%-%s%[.+%]',"")
					end
				end
				return inputString 
			end
			
			ml_mesh_mgr.AllowedMapsLookup = function (mapid) 
				local placeid = FFXIVLib.API.Map.GetPlaceID(mapid) or 0
				if (placeid ~= 0) then
					local allowedMaps = FFXIVLib.API.Map.GetValidMaps(placeid)
					if (table.valid(allowedMaps)) then
						return allowedMaps
					end
				end
				return { [mapid] = mapid }
			end


			ml_mesh_mgr.GetMapNameByMapID = function (mapid)
				return FFXIVLib.API.Map.GetMapName(mapid, "en")
			end
		end
	end
	
	local ffxiv_mainmenu = {
		header = { id = "FFXIVMINION##MENU_HEADER", expanded = false, name = "FFXIVMinion", texture = GetStartupPath().."\\GUI\\UI_Textures\\ffxiv_shiny.png"},
		members = {	
			{ id = "FFXIVMINION##MENU_MAINMENU", name = GetString("Main Task"), onClick = function() ffxivminion.GUI.main.open = true ml_global_information.drawMode = 1 end, tooltip = "Open the Main Task window." },
			{ id = "FFXIVMINION##MENU_DEV", name = GetString("Dev Tools"), onClick = function() dev.GUI.open = not dev.GUI.open end, tooltip = "Open the Developer tools." },
		}
	}
	ml_gui.ui_mgr:AddComponent(ffxiv_mainmenu)
end

function IsControlOpen(strControl)
	local control = GetControlByName(strControl)
	  if (control) then
		if (control:IsOpen()) then
		  return true
		end
	  end
	return false
end

function GetControlData(strControl,strData)
	local control = GetControlByName(strControl)
	if (control) then
		local data = control:GetData()
		if (data) then
			if (strData == nil) then
				return data
			else
				if (table.valid(data)) then
					for dataid, dataval in pairs(data) do
						if (dataid == strData) then
							return dataval
						end
					end
				end
			end
		end
	end

	return nil
end

function GetControlStrings(strControl,numString)

	local control = GetControlByName(strControl)
	if (control) then
		local strings = control:GetStrings()
		if (table.valid(strings)) then
			if (numString == nil) then
				return strings
			else
				for stringid, stringval in pairs(strings) do
					if (stringid == numString) then
						return stringval
					end
				end
			end
		end
	end

	return nil
end

function GetControlRawData(strControl,index)

	local control = GetControlByName(strControl)
	if (control) then
		local datas = control:GetRawData()
		if (table.valid(datas)) then
			if (index == nil) then
				return datas
			else
				return datas[index]
			end
		end
	end

	return nil
end

function UseControlAction(strControl,strAction,actionArg,preDelay,postDelay)
	local preDelay = IsNull(preDelay,0)
	local postDelay = IsNull(postDelay,0)
	if (preDelay ~= 0) then
		ml_global_information.Queue(preDelay,function () UseControlAction(strControl,strAction,actionArg,0,postDelay) end)
	else
		local actionArg = IsNull(actionArg,0)
		local controls = MGetControls() -- testing?

		local control = GetControlByName(strControl)
		if (control and control:IsOpen()) then
			if (strAction == "Close") then
				control:Close()
			elseif (strAction == "Destroy") then
				control:Destroy()
			else
				local actions = control:GetActions()
				if (table.valid(actions)) then
					for aid, action in pairs(actions) do
						if (action == strAction) then
							if (postDelay ~= 0) then
								ml_global_information.Await(postDelay)
							end
							if (type(actionArg) == "table") then
								-- handle multiple args, min 2, max 3 args, using index 1-3
								if (table.size(actionArg) == 2) then
									control:Action(action,actionArg[1],actionArg[2])
								elseif (table.size(actionArg) == 3) then
									control:Action(action,actionArg[1],actionArg[2],actionArg[3])
								end
							else
								if (control:Action(action,actionArg)) then
									return true
								end
							end
							return false
						end
					end
				end
			end
		end

	end
	return false
end

function OpenControl(strControl)
	local control = GetControlByName(strControl)
	if (control and type(control) == "number") then
		CreateControl(control)
	elseif (control and type(control) == "table") then
		control:Open()
	end
end

function GetControl(strControl,allControls)
	local allControls = IsNull(allControls,false)
	
	local control = GetControlByName(strControl)
	if (control) then
		return control
	end
	
	if (allControls) then
		local controls = GetControlList()
		if (table.valid(controls)) then
			for id, e in pairs(controls) do
				if (e == strControl) then
					return id
				end
			end
		end
	end
	
	return nil
end

function GetPublicProfiles(path,ext)
	local profiles, profilesDisplay = { [GetString("none")] = {} }, { GetString("none") }
	
	local profileList = FolderList(path,ext)
	if (table.valid(profileList)) then
		for i,profile in pairs(profileList) do	
			local profileData, e = persistence.load(path..profile)
			if (table.valid(profileData)) then
				local profileName = string.gsub(profile,"%..+$","")
				if (IsNull(profileName,"") ~= "") then
					if (table.valid(profileData.names) and profileData.names[gCurrentLanguage]) then
						local translatedName = profileData.names[gCurrentLanguage]
						if (profiles[translatedName] == nil) then
							profiles[translatedName] = profileData
							table.insert(profilesDisplay,translatedName)
						end
					else
						if (profiles[profileName] == nil) then
							profiles[profileName] = profileData
							table.insert(profilesDisplay,profileName)
						end
					end
				end
			elseif (e) then
				d(e)
			end
		end		
	end
	
	return profiles,profilesDisplay
end

function ml_global_information.LoadBehaviorFiles()
	-- Load all our local "bot/addon" BTree files
	local path = GetLuaModsPath()  .. "ffxivminion\\Behavior"
	if (not FolderExists(path)) then
		FolderCreate(path)
	end
	BehaviorManager:LoadBehaviorFromFolder(path)
 end
RegisterEventHandler("RefreshBehaviorFiles", ml_global_information.LoadBehaviorFiles,"ml_global_information.LoadBehaviorFiles")

function ml_global_information.CheckPartyInviteYesno(txt)
    if table.valid(txt) then
        for _, b in pairs(txt) do
            if FFXIVLib.API.Strings.Contains(b, FFXIVLib.API.Strings.JOIN_PARTY) then
                return true
            end
        end
    end
end
function ml_global_information.CheckGroupTeleportYesno(txt)
    if table.valid(txt) then
        for _, b in pairs(txt) do
            if FFXIVLib.API.Strings.Contains(b, FFXIVLib.API.Strings.ACCEPT_TELEPORT) then
                return true
            end
        end
    end
end
function PressYesNo(answer)
    local answer = IsNull(answer, true)
    if (answer == true) then
        answer = "Yes"
    elseif (answer == false) then
        answer = "No"
    end

    if (IsControlOpen("SelectYesno")) then
        if (IsControlOpen("_NotificationParty")) and gDeclinePartyInvites then
            return UseControlAction("SelectYesno", "No")
        else
            local txt = GetControlStrings("SelectYesno")
            if not table.valid(txt) and (gDeclinePartyInvites or gDeclinePartyTeleport) then
                d("text info invalid ? (SelectYesno), decline party invite " .. tostring(gDeclinePartyInvites) .. '  decline group teleport ' .. tostring(gDeclinePartyTeleport))
                return false
            end
            if ml_global_information.CheckPartyInviteYesno(txt) and gDeclinePartyInvites then
                d('decline party invite.')
                return UseControlAction("SelectYesno", "No")
            end
            if ml_global_information.CheckGroupTeleportYesno(txt) and gDeclinePartyTeleport then
                d('decline group teleport.')
                return UseControlAction("SelectYesno", "No")
            end
            return UseControlAction("SelectYesno", answer)
        end
    end
    return false
end

function DrawFateListUI(self)
	local vars = self.GUI.vars
	
	ml_gui.DrawTabs(self.GUI.main_tabs)
	
	-- dbk: Edit
	if (self.GUI.main_tabs.tabs[1].isselected) then
		GUI:Columns(4, "##listdetail-view", true)
		GUI:SetColumnOffset(1,60); GUI:SetColumnOffset(2,140); GUI:SetColumnOffset(3,210); GUI:SetColumnOffset(4,280); GUI:SetColumnOffset(5,350); GUI:SetColumnOffset(6,450);
		GUI:Text(GetString("Map")); GUI:NextColumn();
		GUI:Text(GetString("Name")); GUI:NextColumn();
		GUI:Text(GetString("ID")); GUI:NextColumn(); GUI:NextColumn();
		GUI:Separator();
		
		local entries = self.entries
		if (table.valid(entries)) then
			local myMap = Player.localmapid
			for i, entry in pairs(entries) do
				if (entry.mapid == myMap) then
					GUI:Text(entry.mapid); GUI:NextColumn();
					GUI:Text(entry.name); GUI:NextColumn();
					GUI:Text(entry.id); GUI:NextColumn();
					if (GUI:Button(GetString("Delete").."##"..tostring(i))) then
						self:DeleteEntry(i); 
					end
					GUI:NextColumn();
				end
			end
		end
		
		GUI:Columns(1)		
	end
			
	-- dbk: Add
	if (self.GUI.main_tabs.tabs[2].isselected) then
		
		local fateList = {}
		local fateDisplayList = {}
		
		local flist = FFXIVLib.API.Fate.GetActiveFateList()
		if (table.valid(flist)) then
			for id, e in pairs(flist) do
				if (self:Find(e.id,"id") == nil) then
					table.insert(fateDisplayList,e.name)
					table.insert(fateList,{ name = e.name, mapid = Player.localmapid, id = e.id })
				end
			end
		end			
		
		if (table.valid(fateList)) then
			if (FateListComboIndex == nil) then
				FateListComboIndex = 1
				FateListCombo = GetKeyByValue(FateListComboIndex,fateDisplayList)
			end
			
			GUI_Combo("Fates","FateListComboIndex","FateListCombo",fateDisplayList)
			
			GUI:Spacing(); GUI:Spacing();
			
			local fate = fateList[FateListComboIndex]
			GUI:Text(GetString("ID :")); GUI:SameLine(75); GUI:Text(fate.id)
			GUI:Text(GetString("Name :")); GUI:SameLine(75); GUI:Text(fate.name)
			GUI:Text(GetString("Map ID :")); GUI:SameLine(75); GUI:Text(fate.mapid)
			
			GUI:Spacing(); GUI:Spacing();

			if (GUI:Button(GetString("Add Entry"),200,24)) then
				local details = { name = fate.name, mapid = fate.mapid, id = fate.id }
				self:AddEntry(details)
				vars.temptext = "Added ["..tostring(fate.id).." : "..tostring(fate.name).."] to the list."
				vars.temptimer = Now() + 2000
			end

			if (vars.temptimer ~= 0) then
				if (Now() < vars.temptimer) then
					GUI:Text(vars.temptext)
				end
			end
		else
			GUI:Text(GetString("No active fates."))
		end
	end
end

function pd(strOut)
	if (strOut) then
		pcall(d,strOut)
	end
end

RegisterEventHandler("Module.Initalize",ml_global_information.Init, "ml_global_information.Init")

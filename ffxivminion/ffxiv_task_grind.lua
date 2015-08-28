ffxiv_task_grind = inheritsFrom(ml_task)
ffxiv_task_grind.name = "LT_GRIND"
ffxiv_task_grind.inFate = false
ffxiv_task_grind.ticks = 0
ffxiv_task_grind.blTicks = 0
gFateID = 0

ffxiv_task_grind.atmas = {
	["Maiden"] = { name = "Maiden", 			hour = 1,	tele = 3, 	map = 148, item = 7851, mesh = "Central Shroud"},
	["Scorpion"] = { name = "Scorpion", 		hour = 2,	tele = 20, 	map = 146, item = 7852, mesh = "Southern Thanalan"},
	["Waterbearer"] = { name = "Waterbearer",	hour = 3, 	tele = 15, 	map = 139, item = 7853, mesh = "Upper La Noscea - Merged"},
	["Goat"] = { name = "Goat", 				hour = 4, 	tele = 4, 	map = 152, item = 7854, mesh = "East Shroud"},
	["Bull"] = { name = "Bull", 				hour = 5, 	tele = 18, 	map = 145, item = 7855, mesh = "Eastern Thanalan"},
	["Ram"] = { name = "Ram", 					hour = 6, 	tele = 52, 	map = 134, item = 7856, mesh = "Middle La Noscea"},
	["Twins"] = { name = "Twins", 				hour = 7, 	tele = 17, 	map = 140, item = 7857, mesh = "Western Thanalan"},
	["Lion"] = { name = "Lion", 				hour = 8, 	tele = 16, 	map = 180, item = 7858, mesh = "Outer La Noscea"},
	["Fish"] = { name = "Fish", 				hour = 9, 	tele = 10, 	map = 135, item = 7859, mesh = "Lower La Noscea"},
	["Archer"] = { name = "Archer", 			hour = 10, 	tele = 7, 	map = 154, item = 7860, mesh = "North Shroud"},
	["Scales"] = { name = "Scales", 			hour = 11, 	tele = 53, 	map = 141, item = 7861, mesh = "Central Thanalan"},
	["Crab"] = { name = "Crab", 				hour = 12, 	tele = 14, 	map = 138, item = 7862, mesh = "Western La Noscea"},
}

function ffxiv_task_grind.Create()
    local newinst = inheritsFrom(ffxiv_task_grind)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_grind members
    newinst.name = "LT_GRIND"
    newinst.targetid = 0
    newinst.markerTime = 0
    newinst.currentMarker = false
	newinst.filterLevel = true
	newinst.correctMap = Player.localmapid
	newinst.suppressRestTimer = 0
	newinst.safeLevel = false
	ffxiv_task_grind.inFate = false
	ml_global_information.currentMarker = false
    
    --this is the targeting function that will be used for the generic KillTarget task
    newinst.targetFunction = GetNearestGrindAttackable
	newinst.killFunction = ffxiv_task_grindCombat

    return newinst
end

c_nextgrindmarker = inheritsFrom( ml_cause )
e_nextgrindmarker = inheritsFrom( ml_effect )
function c_nextgrindmarker:evaluate()

    if ((gBotMode == GetString("partyMode") and not IsLeader()) or
		(gDoFates == "1" and gFatesOnly == "1") or
		(not ml_marker_mgr.markersLoaded)) 
	then
        return false
    end
	
	if (gMarkerMgrMode == GetString("singleMarker")) then
		ml_task_hub:ThisTask().filterLevel = false
	else
		ml_task_hub:ThisTask().filterLevel = true
	end
    
    if ( ml_task_hub:ThisTask().currentMarker ~= nil and ml_task_hub:ThisTask().currentMarker ~= 0 ) then
        local marker = nil
        
        -- first check to see if we have no initiailized marker
        if (ml_task_hub:ThisTask().currentMarker == false) then --default init value
            marker = ml_marker_mgr.GetNextMarker(GetString("grindMarker"), ml_task_hub:ThisTask().filterLevel)
			
			if (marker == nil) then
				ml_task_hub:ThisTask().filterLevel = false
				marker = ml_marker_mgr.GetNextMarker(GetString("grindMarker"), ml_task_hub:ThisTask().filterLevel)
			end	
		end
        
        --Check level range, this section only executes if marker is in list mode.
		if (gMarkerMgrMode ~= GetString("singleMarker")) then
			if (marker == nil) then
				if (ValidTable(ml_task_hub:ThisTask().currentMarker) and Player:GetSyncLevel() == 0) then
					if 	(ml_task_hub:ThisTask().filterLevel) and
						(Player.level < ml_task_hub:ThisTask().currentMarker:GetMinLevel() or 
						Player.level > ml_task_hub:ThisTask().currentMarker:GetMaxLevel()) 
					then
						marker = ml_marker_mgr.GetNextMarker(GetString("grindMarker"), ml_task_hub:ThisTask().filterLevel)
					end
				end
			end
			
			-- last check if our time has run out
			if (marker == nil) then
				if (ValidTable(ml_task_hub:ThisTask().currentMarker)) then
					local expireTime = ml_task_hub:ThisTask().markerTime
					if (Now() > expireTime) then
						ml_debug("Getting Next Marker, TIME IS UP!")
						marker = ml_marker_mgr.GetNextMarker(GetString("grindMarker"), ml_task_hub:ThisTask().filterLevel)
					else
						return false
					end
				end
			end
		end
        
        if (ValidTable(marker)) then
            e_nextgrindmarker.marker = marker
            return true
        end
    end
    
    return false
end
function e_nextgrindmarker:execute()
	ml_global_information.currentMarker = e_nextgrindmarker.marker
    ml_task_hub:ThisTask().currentMarker = e_nextgrindmarker.marker
    ml_task_hub:ThisTask().markerTime = Now() + (ml_task_hub:ThisTask().currentMarker:GetTime() * 1000)
	ml_global_information.MarkerTime = Now() + (ml_task_hub:ThisTask().currentMarker:GetTime() * 1000)
    ml_global_information.MarkerMinLevel = ml_task_hub:ThisTask().currentMarker:GetMinLevel()
    ml_global_information.MarkerMaxLevel = ml_task_hub:ThisTask().currentMarker:GetMaxLevel()
    ml_global_information.BlacklistContentID = ml_task_hub:ThisTask().currentMarker:GetFieldValue(GetUSString("NOTcontentIDEquals"))
    ml_global_information.WhitelistContentID = ml_task_hub:ThisTask().currentMarker:GetFieldValue(GetUSString("contentIDEquals"))
	gStatusMarkerName = ml_task_hub:ThisTask().currentMarker:GetName()
end

function ffxiv_task_grind:Init()
    --init ProcessOverWatch() elements
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 45 )
    self:add(ke_dead, self.overwatch_elements)
	
	local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 40 )
    self:add(ke_flee, self.overwatch_elements)
	
	local ke_atma = ml_element:create( "NextAtma", c_nextatma, e_nextatma, 30 )
    self:add(ke_atma, self.overwatch_elements)
	
	local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 90 )
    self:add(ke_rest, self.process_elements)
    
	local ke_autoEquip = ml_element:create( "AutoEquip", c_autoequip, e_autoequip, 45 )
    self:add( ke_autoEquip, self.process_elements)
	
	local ke_addHuntlog = ml_element:create( "AddHuntlog", c_grind_addhuntlogtask, e_grind_addhuntlogtask, 40 )
    self:add(ke_addHuntlog, self.process_elements)
	
	local ke_returnToMap = ml_element:create( "ReturnToMap", c_returntomap, e_returntomap, 35 )
    self:add(ke_returnToMap, self.process_elements)
	
	 local ke_addFate = ml_element:create( "AddFate", c_add_fate, e_add_fate, 30 )
    self:add(ke_addFate, self.process_elements)

    local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 25 )
    self:add(ke_returnToMarker, self.process_elements)
    
    local ke_nextMarker = ml_element:create( "NextMarker", c_nextgrindmarker, e_nextgrindmarker, 20 )
    self:add(ke_nextMarker, self.process_elements)
	
    local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_killtarget, e_add_killtarget, 15 )
    self:add(ke_addKillTarget, self.process_elements)
	
    local ke_fateWait = ml_element:create( "FateWait", c_fatewait, e_fatewait, 10 )
    self:add(ke_fateWait, self.process_elements)
  
    self:AddTaskCheckCEs()
end

function ffxiv_task_grind:Process()
	if (IsLoading() or ml_mesh_mgr.meshLoading) then
		return false
	end
	
	if (TableSize(ml_task_hub:CurrentTask().process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(ml_task_hub:CurrentTask().process_elements)
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end

function ffxiv_task_grind.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gDoFates" or
                k == "gFatesOnly" or
                k == "gMinFateLevel" or
                k == "gMaxFateLevel" or              
                k == "gFateWaitPercent" or
				k == "gFateTeleportPercent" or
                k == "gFateBLTimer" or
                k == "gRestInFates" or
                k == "gCombatRangePercent" or
				k == "gAlwaysKillAggro" or
				k == "gClaimFirst" or
				k == "gClaimRange" or
				k == "gClaimed" or
				k == "gDoChainFates" or
				k == "gDoBattleFates" or
				k == "gDoGatherFates" or
				k == "gDoDefenseFates" or
				k == "gDoBossFates" or
				k == "gDoEscortFates" or
				k == "gGrindDoHuntLog" or
				k == "gFateWaitNearEvac" )
        then
            SafeSetVar(tostring(k),v)
		elseif (k == "gFateChainWaitPercent" or
				k == "gFateBattleWaitPercent" or
				k == "gFateBossWaitPercent" or
				k == "gFateGatherWaitPercent" or
				k == "gFateDefenseWaitPercent" or
				k == "gFateEscortWaitPercent" or
				k == "gFateRandomDelayMin" or
				k == "gFateRandomDelayMax")
		then
			SafeSetVar(tostring(k),tonumber(v))
		elseif ( k == "gAtma") then
			if (v == "1") then
				SetGUIVar("gDoFates","1")
				SetGUIVar("gFatesOnly","1")
			end	
			SafeSetVar(tostring(k),v)
        end
    end
    GUI_RefreshWindow(GetString("grindMode"))
end

function ffxiv_task_grind.BlacklistTarget()
    local target = Player:GetTarget()
    if ValidTable(target) then
        ml_blacklist.AddBlacklistEntry(GetString("monsters"), target.contentid, target.name, true)
        ml_debug("Blacklisted "..target.name)
    else
        ml_debug("Invalid target or no target selected")
    end
end

function ffxiv_task_grind.BlacklistAOE()
	if (not IsNullString(gSpellID)) then
		if (IsNullString(gSpellName)) then
			if (HasAction(tonumber(gSpellID))) then
				local action = ActionList:Get(tonumber(gSpellID))
				gSpellName = action.name
			else
				gSpellName = "None"
			end
		end
		ml_blacklist.AddBlacklistEntry(GetString("aoe"), tonumber(gSpellID), gSpellName, true)
	end
end

function ffxiv_task_grind.BlacklistFate(arg)
    if (gFateName ~= "") then
        if (arg == "gBlacklistFateAddEvent") then
            ml_blacklist.AddBlacklistEntry(GetString("fates"), tonumber(gFateID), gFateName, true)
        elseif (arg == "gBlacklistFateRemEvent") then
            ml_blacklist.DeleteEntry(GetString("fates"), tonumber(gFateID))
        end
    else
        ml_debug("No valid fate selected")
    end
end

function ffxiv_task_grind.WhitelistFate(arg)
    if (gFateName ~= "") then
        if (arg == "gWhitelistFateAddEvent") then
            ml_blacklist.AddBlacklistEntry("FATE Whitelist", tostring(gFateMapID).."-"..tostring(gFateID), gFateName, true)
        elseif (arg == "gWhitelistFateRemEvent") then
            ml_blacklist.DeleteEntry("FATE Whitelist", tonumber(gFateID))
        end
    else
        ml_debug("No valid fate selected")
    end
end


function ffxiv_task_grind.BlacklistInitUI()
    GUI_NewField(ml_blacklist_mgr.mainwindow.name, GetString("targetName"), "gTargetName", GetString("addEntry"))
    GUI_NewButton(ml_blacklist_mgr.mainwindow.name, GetString("blacklistTarget"), "ffxiv_task_grind.blacklistTarget",GetString("addEntry"))
    RegisterEventHandler("ffxiv_task_grind.blacklistTarget",ffxiv_task_grind.BlacklistTarget)
end

function ffxiv_task_grind.BlacklistInitAOE()
    GUI_NewField(ml_blacklist_mgr.mainwindow.name, GetString("maMarkerID"), "gSpellID", GetString("addEntry"))
	GUI_NewField(ml_blacklist_mgr.mainwindow.name, GetString("maMarkerName"), "gSpellName", GetString("addEntry"))
    GUI_NewButton(ml_blacklist_mgr.mainwindow.name, GetString("addEntry"), "ffxiv_task_grind.blacklistAOE",GetString("addEntry"))
    RegisterEventHandler("ffxiv_task_grind.blacklistAOE",ffxiv_task_grind.BlacklistAOE)
end

function ffxiv_task_grind.HuntingUI()
	GUI_NewField	(ml_blacklist_mgr.mainwindow.name, GetString("targetName"),"gTargetName", 		GetString("addEntry"))
	GUI_NewButton	(ml_blacklist_mgr.mainwindow.name, GetString("hunt"), 	"ffxivminion.huntTarget",GetString("addEntry"))
	RegisterEventHandler("ffxivminion.huntTarget",ffxiv_task_grind.HuntTarget)
end

function ffxiv_task_grind.HuntTarget()
	local target = Player:GetTarget()
	if ValidTable(target) then
		ml_blacklist.AddBlacklistEntry(GetString("huntMonsters"), target.contentid, target.name, true)
	end
end

-- UI settings etc
function ffxiv_task_grind.UIInit()
	
	--Add it to the main tracking table, so that we can save positions for it.
	ffxivminion.Windows.Grind = { id = strings["us"].grindMode, Name = GetString("grindMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Grind)

	if (Settings.FFXIVMINION.gDoFates == nil) then
        Settings.FFXIVMINION.gDoFates = "0"
    end
    if (Settings.FFXIVMINION.gFatesOnly == nil) then
        Settings.FFXIVMINION.gFatesOnly = "0"
    end
    if (Settings.FFXIVMINION.gMaxFateLevel == nil) then
        Settings.FFXIVMINION.gMaxFateLevel = "5"
    end
    if (Settings.FFXIVMINION.gMinFateLevel == nil) then
        Settings.FFXIVMINION.gMinFateLevel = "0"
    end
	if (Settings.FFXIVMINION.gAtma == nil) then
        Settings.FFXIVMINION.gAtma = "0"
    end
	if (Settings.FFXIVMINION.gClaimFirst == nil) then
        Settings.FFXIVMINION.gClaimFirst = "0"
    end
	if (Settings.FFXIVMINION.gClaimRange == nil) then
        Settings.FFXIVMINION.gClaimRange = "20"
    end
	if (Settings.FFXIVMINION.gClaimed == nil) then
        Settings.FFXIVMINION.gClaimed = "0"
    end
	if (Settings.FFXIVMINION.gAlwaysKillAggro == nil) then
        Settings.FFXIVMINION.gAlwaysKillAggro = "0"
    end
    if (Settings.FFXIVMINION.gCombatRangePercent == nil) then
        Settings.FFXIVMINION.gCombatRangePercent = "75"
    end
    if (Settings.FFXIVMINION.gRestInFates == nil) then
        Settings.FFXIVMINION.gRestInFates = "1"
    end
	if (Settings.FFXIVMINION.gFateTeleportPercent == nil) then
        Settings.FFXIVMINION.gFateTeleportPercent = "0"
    end
    if (Settings.FFXIVMINION.gFateBLTimer == nil) then
        Settings.FFXIVMINION.gFateBLTimer = "120"
    end
	if (Settings.FFXIVMINION.gKillAggroEnemies == nil) then
		Settings.FFXIVMINION.gKillAggroEnemies = "0"
	end
	if (Settings.FFXIVMINION.gDoChainFates == nil) then
        Settings.FFXIVMINION.gDoChainFates = "1"
    end
	if (Settings.FFXIVMINION.gDoBattleFates == nil) then
        Settings.FFXIVMINION.gDoBattleFates = "1"
    end
	if (Settings.FFXIVMINION.gDoBossFates == nil) then
        Settings.FFXIVMINION.gDoBossFates = "1"
    end
	if (Settings.FFXIVMINION.gDoGatherFates == nil) then
        Settings.FFXIVMINION.gDoGatherFates = "1"
    end
	if (Settings.FFXIVMINION.gDoDefenseFates == nil) then
        Settings.FFXIVMINION.gDoDefenseFates = "1"
    end
	if (Settings.FFXIVMINION.gDoEscortFates == nil) then
        Settings.FFXIVMINION.gDoEscortFates = "1"
    end
	if (Settings.FFXIVMINION.gFateChainWaitPercent == nil) then
        Settings.FFXIVMINION.gFateChainWaitPercent = 0
    end
	if (Settings.FFXIVMINION.gFateBattleWaitPercent == nil) then
        Settings.FFXIVMINION.gFateBattleWaitPercent = 0
    end
	if (Settings.FFXIVMINION.gFateBossWaitPercent == nil) then
        Settings.FFXIVMINION.gFateBossWaitPercent = 0
    end
	if (Settings.FFXIVMINION.gFateGatherWaitPercent == nil) then
        Settings.FFXIVMINION.gFateGatherWaitPercent = 0
    end
	if (Settings.FFXIVMINION.gFateDefenseWaitPercent == nil) then
        Settings.FFXIVMINION.gFateDefenseWaitPercent = 0
    end
	if (Settings.FFXIVMINION.gFateEscortWaitPercent == nil) then
        Settings.FFXIVMINION.gFateEscortWaitPercent = 0
    end
	if (Settings.FFXIVMINION.gGrindDoHuntLog == nil) then
        Settings.FFXIVMINION.gGrindDoHuntLog = "0"
    end
	if (Settings.FFXIVMINION.gFateWaitNearEvac == nil) then
        Settings.FFXIVMINION.gFateWaitNearEvac = "1"
    end
	if (Settings.FFXIVMINION.gFateRandomDelayMin == nil) then
        Settings.FFXIVMINION.gFateRandomDelayMin = 0
    end
	if (Settings.FFXIVMINION.gFateRandomDelayMax == nil) then
        Settings.FFXIVMINION.gFateRandomDelayMax = 0
    end
	if (Settings.FFXIVMINION.gFateKillAggro == nil) then
        Settings.FFXIVMINION.gFateKillAggro = "1"
    end
	
	local winName = GetString("grindMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	GUI_NewButton(winName, GetString("markerManager"), "ToggleMarkerMgr")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,GetString("navmesh") ,"gmeshname",group,ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
	GUI_NewField(winName,GetString("markerName"),"gStatusMarkerName",group )
	GUI_NewField(winName,GetString("markerTime"),"gStatusMarkerTime",group )
	GUI_NewButton(winName, GetString("setEvacPoint"), "ml_mesh_mgr.SetEvacPoint", group)
	
	local group = GetString("settings")
	GUI_NewCheckbox(winName, GetString("doHuntingLog"),"gGrindDoHuntLog",group)
	GUI_NewCheckbox(winName, GetString("doAtma"), "gAtma",group)
    GUI_NewCheckbox(winName, GetString("doFates"), "gDoFates",group)
    GUI_NewCheckbox(winName, GetString("fatesOnly"), "gFatesOnly",group)
	GUI_NewCheckbox(winName, GetString("prioritizeClaims"),"gClaimFirst",group)
	GUI_NewNumeric(winName, GetString("claimRange"), "gClaimRange", 	group, "0", "50")
	GUI_NewCheckbox(winName, GetString("attackClaimed"), "gClaimed",	group)
    GUI_NewNumeric(winName, GetString("combatRangePercent"), "gCombatRangePercent", group, "1", "100")
	
	local group = GetString("fates")
	GUI_NewCheckbox(winName, "Kill Non-Fate Aggro", "gFateKillAggro",group)
    GUI_NewCheckbox(winName, GetString("restInFates"), "gRestInFates",group)
    GUI_NewField(winName, GetString("maxFateLevel"), "gMaxFateLevel", group)
    GUI_NewField(winName, GetString("minFateLevel"), "gMinFateLevel", group)
	GUI_NewNumeric(winName, GetString("fateTeleportPercent"), "gFateTeleportPercent", group, "0", "99")
	GUI_NewCheckbox(winName, GetString("waitNearEvac"), "gFateWaitNearEvac",group)
	GUI_NewNumeric(winName, "Min Random Delay (s)", "gFateRandomDelayMin", group, "0", "120")
	GUI_NewNumeric(winName, "Max Random Delay (s)", "gFateRandomDelayMax", group, "0", "240")
	
	local group = "Details"
	GUI_NewCheckbox(winName,"Chain Fates", "gDoChainFates",group)
	GUI_NewNumeric(winName,"Chain Fate Wait %", "gFateChainWaitPercent", group, "0", "99")
	GUI_NewCheckbox(winName,"Battle Fates", "gDoBattleFates",group)
	GUI_NewNumeric(winName,"Battle Fate Wait %", "gFateBattleWaitPercent", group, "0", "99")
	GUI_NewCheckbox(winName,"Boss Fates", "gDoBossFates",group)
	GUI_NewNumeric(winName,"Boss Fate Wait %", "gFateBossWaitPercent", group, "0", "99")
	GUI_NewCheckbox(winName,"Gather Fates", "gDoGatherFates",group)
	GUI_NewNumeric(winName,"Gather Fate Wait %", "gFateGatherWaitPercent", group, "0", "99")
	GUI_NewCheckbox(winName,"Defense Fates", "gDoDefenseFates",group)
	GUI_NewNumeric(winName,"Defense Fate Wait %", "gFateDefenseWaitPercent", group, "0", "99")
	GUI_NewCheckbox(winName,"Escort Fates", "gDoEscortFates",group)
	GUI_NewNumeric(winName,"Escort Fate Wait %", "gFateEscortWaitPercent", group, "0", "99")
	
	
	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gAlwaysKillAggro = Settings.FFXIVMINION.gAlwaysKillAggro
	gAtma = Settings.FFXIVMINION.gAtma
	gClaimFirst = Settings.FFXIVMINION.gClaimFirst
	gClaimRange = Settings.FFXIVMINION.gClaimRange
	gClaimed = Settings.FFXIVMINION.gClaimed
    gDoFates = Settings.FFXIVMINION.gDoFates
    gFatesOnly = Settings.FFXIVMINION.gFatesOnly
    gMaxFateLevel = Settings.FFXIVMINION.gMaxFateLevel
    gMinFateLevel = Settings.FFXIVMINION.gMinFateLevel
    gRestInFates = Settings.FFXIVMINION.gRestInFates
    gCombatRangePercent = Settings.FFXIVMINION.gCombatRangePercent
    gFateWaitPercent = Settings.FFXIVMINION.gFateWaitPercent
	gFateTeleportPercent = Settings.FFXIVMINION.gFateTeleportPercent
    gFateBLTimer = Settings.FFXIVMINION.gFateBLTimer
	gKillAggroEnemies = Settings.FFXIVMINION.gKillAggroEnemies
	gDoChainFates = Settings.FFXIVMINION.gDoChainFates
	gDoBattleFates = Settings.FFXIVMINION.gDoBattleFates
	gDoBossFates = Settings.FFXIVMINION.gDoBossFates
	gDoGatherFates = Settings.FFXIVMINION.gDoGatherFates
	gDoDefenseFates = Settings.FFXIVMINION.gDoDefenseFates
	gDoEscortFates = Settings.FFXIVMINION.gDoEscortFates
	gFateChainWaitPercent = Settings.FFXIVMINION.gFateChainWaitPercent
	gFateBattleWaitPercent = Settings.FFXIVMINION.gFateBattleWaitPercent
	gFateBossWaitPercent = Settings.FFXIVMINION.gFateBossWaitPercent
	gFateGatherWaitPercent = Settings.FFXIVMINION.gFateGatherWaitPercent
	gFateDefenseWaitPercent = Settings.FFXIVMINION.gFateDefenseWaitPercent
	gFateEscortWaitPercent = Settings.FFXIVMINION.gFateEscortWaitPercent
	gGrindDoHuntLog = Settings.FFXIVMINION.gGrindDoHuntLog
	gFateWaitNearEvac = Settings.FFXIVMINION.gFateWaitNearEvac
	gFateRandomDelayMin = Settings.FFXIVMINION.gFateRandomDelayMin
	gFateRandomDelayMax = Settings.FFXIVMINION.gFateRandomDelayMax
	gFateKillAggro = Settings.FFXIVMINION.gFateKillAggro
    
    --add blacklist init function
    ml_blacklist_mgr.AddInitUI(GetString("monsters"),ffxiv_task_grind.BlacklistInitUI)
	ml_blacklist_mgr.AddInitUI(GetString("huntMonsters"),ffxiv_task_grind.HuntingUI)
    ml_blacklist_mgr.AddInitUI(GetString("fates"),ffxiv_task_fate.BlacklistInitUI)
	ml_blacklist_mgr.AddInitUI("FATE Whitelist",ffxiv_task_fate.WhitelistInitUI)
	ml_blacklist_mgr.AddInitUI(GetString("aoe"),ffxiv_task_grind.BlacklistInitAOE)
	
	ffxiv_task_grind.SetupMarkers()
end

function ffxiv_task_grind.SetupMarkers()
    -- add marker templates for grinding
    local grindMarker = ml_marker:Create("grindTemplate")
	grindMarker:SetType(GetString("grindMarker"))
	grindMarker:AddField("int", GetUSString("minContentLevel"), GetString("minContentLevel"), 0)
	grindMarker:AddField("int", GetUSString("maxContentLevel"), GetString("maxContentLevel"), 0)
	grindMarker:AddField("int", GetUSString("maxRadius"), GetString("maxRadius"), 0)
	grindMarker:AddField("string", GetUSString("contentIDEquals"), GetString("contentIDEquals"), "")
	grindMarker:AddField("button", GetUSString("whitelistTarget"), GetString("whitelistTarget"), "")
	grindMarker:AddField("string", GetUSString("NOTcontentIDEquals"), GetString("NOTcontentIDEquals"), "")
    grindMarker:SetTime(300)
    grindMarker:SetMinLevel(1)
    grindMarker:SetMaxLevel(60)
	
    ml_marker_mgr.AddMarkerTemplate(grindMarker)
    
    -- refresh the manager with the new templates
    ml_marker_mgr.RefreshMarkerTypes()
	ml_marker_mgr.RefreshMarkerNames()
end

function ffxiv_task_grind.UpdateBlacklistUI(tickcount)
    if ( tickcount - ffxiv_task_grind.ticks > 500 ) then
        -- update fate name in gui
        ffxiv_task_grind.ticks = tickcount
        local fafound = false
        local falist = MapObject:GetFateList()
        if ( falist ) then
            local f = falist[tonumber(gFateIndex)]
            if ( f ) then
                fafound = true
                gFateName = string.gsub(f.name,",","")
                gFateID = f.id
				gFateMapID = Player.localmapid
            end
        end
        if (not fafound) then
            gFateName = ""
            gFateID = 0
			gFateMapID = 0
        end
        
        local target = Player:GetTarget()
        if target and target.attackable then
            gTargetName = target.name
        else
            gTargetName = GetString("notAttackable")
        end
		
		if ValidTable(target) then
			if (ValidTable(target.castinginfo)) then
				if (target.castinginfo.channelingid ~= 0) then
					gSpellID = target.castinginfo.channelingid
					if (HasAction(tonumber(gSpellID))) then
						local action = ActionList:Get(tonumber(gSpellID))
						gSpellName = action.name
					else
						gSpellName = tostring(gSpellID)
					end
				end
			end
		end
    end
end

RegisterEventHandler("GUI.Update",ffxiv_task_grind.GUIVarUpdate)

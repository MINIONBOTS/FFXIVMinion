ffxiv_task_grind = inheritsFrom(ml_task)
ffxiv_task_grind.addon_process_elements = {}
ffxiv_task_grind.addon_overwatch_elements = {}
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

ffxiv_task_grind.luminous = {
	["Ice"] = 		{ name = "Ice", 		map = 397, item = 13569 },
	["Earth"] = 	{ name = "Earth", 		map = 398, item = 13572 },
	["Water"] = 	{ name = "Water", 		map = 399, item = 13574 },
	["Lightning"] = { name = "Lightning", 	map = 400, item = 13573 },
	["Fire"] = 		{ name = "Fire",		map = 402, item = 13571 },
	["Wind"] = 		{ name = "Wind", 		map = 401, item = 13570 },
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

    if ((gBotMode == GetString("partyMode") and not IsPartyLeader()) or
		(gGrindDoFates and gGrindFatesOnly) or
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
				if (table.valid(ml_task_hub:ThisTask().currentMarker) and Player:GetSyncLevel() == 0) then
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
				if (table.valid(ml_task_hub:ThisTask().currentMarker)) then
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
        
        if (table.valid(marker)) then
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

c_grindisloading = inheritsFrom( ml_cause )
e_grindisloading = inheritsFrom( ml_effect )
function c_grindisloading:evaluate()
	return MIsLoading()
end
function e_grindisloading:execute()
	ml_debug("Character is loading, prevent other actions and idle.")
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_grindislocked = inheritsFrom( ml_cause )
e_grindislocked = inheritsFrom( ml_effect )
function c_grindislocked:evaluate()
	return MIsLocked() and not IsFlying()
end
function e_grindislocked:execute()
	ml_debug("Character is loading, prevent other actions and idle.")
	ml_task_hub:ThisTask().preserveSubtasks = true
end

function ffxiv_task_grind:Init()
    --init ProcessOverWatch() elements
	local ke_isLoading = ml_element:create( "GrindIsLoading", c_grindisloading, e_grindisloading, 250 )
    self:add( ke_isLoading, self.overwatch_elements)
	
	local ke_skipTalk = ml_element:create( "SkipTalk", c_skiptalk, e_skiptalk, 200 )
    self:add(ke_skipTalk, self.overwatch_elements)
	
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 200 )
    self:add(ke_dead, self.overwatch_elements)
	
	local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 150 )
    self:add(ke_flee, self.overwatch_elements)
	
	local ke_luminous = ml_element:create( "NextLuminous", c_nextluminous, e_nextluminous, 40 )
    self:add(ke_luminous, self.overwatch_elements)
	
	local ke_atma = ml_element:create( "NextAtma", c_nextatma, e_nextatma, 30 )
    self:add(ke_atma, self.overwatch_elements)
	
	local ke_isLocked = ml_element:create( "IsLocked", c_grindislocked, e_grindislocked, 180 )
    self:add( ke_isLocked, self.process_elements)

	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 150 )
    self:add( ke_inventoryFull, self.process_elements)
    
	local ke_autoEquip = ml_element:create( "AutoEquip", c_autoequip, e_autoequip, 130 )
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
	
	local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 18 )
    self:add(ke_rest, self.process_elements)
	
    local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_killtarget, e_add_killtarget, 15 )
    self:add(ke_addKillTarget, self.process_elements)
	
    local ke_fateWait = ml_element:create( "FateWait", c_fatewait, e_fatewait, 10 )
    self:add(ke_fateWait, self.process_elements)
	
	self:InitAddon()
	self:InitExtras()
    self:AddTaskCheckCEs()
end

function ffxiv_task_grind:InitAddon()
	--Nothing here, just for extras.
end

function ffxiv_task_grind:InitExtras()
	local overwatch_elements = self.addon_overwatch_elements
	if (table.valid(overwatch_elements)) then
		for i,element in pairs(overwatch_elements) do
			self:add(element, self.overwatch_elements)
		end
	end
	
	local process_elements = self.addon_process_elements
	if (table.valid(process_elements)) then
		for i,element in pairs(process_elements) do
			self:add(element, self.process_elements)
		end
	end
end

function ffxiv_task_grind:Process()
	if (IsLoading()) then
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

function ffxiv_task_grind.SetModeOptions()
	gTeleportHack = Settings.FFXIVMINION.gTeleportHack
	gTeleportHackParanoid = Settings.FFXIVMINION.gTeleportHackParanoid
	gGrindDoHuntlog = Settings.FFXIVMINION.gGrindDoHuntlog
	gGrindDoFates = Settings.FFXIVMINION.gGrindDoFates
	gGrindFatesOnly = Settings.FFXIVMINION.gGrindFatesOnly
	gGrindFatesMinLevel = Settings.FFXIVMINION.gGrindFatesMinLevel
	gGrindFatesMaxLevel = Settings.FFXIVMINION.gGrindFatesMaxLevel
	gGrindDoBattleFates = Settings.FFXIVMINION.gGrindDoBattleFates
	gGrindDoBossFates = Settings.FFXIVMINION.gGrindDoBossFates
	gGrindDoGatherFates = Settings.FFXIVMINION.gGrindDoGatherFates
	gGrindDoDefenseFates = Settings.FFXIVMINION.gGrindDoDefenseFates
	gGrindDoEscortFates = Settings.FFXIVMINION.gGrindDoEscortFates
	gFateGatherWaitPercent = Settings.FFXIVMINION.gFateGatherWaitPercent
	gFateBossWaitPercent = Settings.FFXIVMINION.gFateBossWaitPercent
	gFateDefenseWaitPercent = Settings.FFXIVMINION.gFateDefenseWaitPercent
	gSkipCutscene = Settings.FFXIVMINION.gSkipCutscene
	gSkipTalk = Settings.FFXIVMINION.gSkipTalk
	gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
	Hacks:SkipCutscene(gSkipCutscene)
	Hacks:Disable3DRendering(gDisableDrawing)
	gAvoidAOE = true
	gAutoEquip = Settings.FFXIVMINION.gAutoEquip
end

function ffxiv_task_grind:UIInit()	
	gGrindDoFates = ffxivminion.GetSetting("gGrindDoFates",true)
	gGrindFatesOnly = ffxivminion.GetSetting("gGrindFatesOnly",false)
	gGrindFatesMaxLevel = ffxivminion.GetSetting("gGrindFatesMaxLevel",2)
	gGrindFatesNoMaxLevel = ffxivminion.GetSetting("gGrindFatesNoMaxLevel",false)
	gGrindFatesMinLevel = ffxivminion.GetSetting("gGrindFatesMinLevel",5)
	gGrindFatesNoMinLevel = ffxivminion.GetSetting("gGrindFatesNoMinLevel",false)
	
	gGrindAtmaMode = ffxivminion.GetSetting("gGrindAtmaMode",false)
	gGrindLuminousMode = ffxivminion.GetSetting("gGrindLuminousMode",false)
	gGrindDoHuntlog = ffxivminion.GetSetting("gGrindDoHuntlog",true)
	
	gClaimFirst = ffxivminion.GetSetting("gClaimFirst",false)
	gClaimRange = ffxivminion.GetSetting("gClaimRange",20)
	gClaimed = ffxivminion.GetSetting("gClaimed",false)
	
	--gKillAggroEnemies = ffxivminion.GetSetting("gKillAggroEnemies",false) -- check if needed
	--gAlwaysKillAggro = ffxivminion.GetSetting("gAlwaysKillAggro",false) -- check if needed
	gFateKillAggro = ffxivminion.GetSetting("gFateKillAggro",true) -- check if needed
	gCombatRangePercent = ffxivminion.GetSetting("gCombatRangePercent",75) -- check if needed
	gRestInFates = ffxivminion.GetSetting("gRestInFates",true)
	gFateTeleportPercent = ffxivminion.GetSetting("gFateTeleportPercent",0) -- check if needed
	gFateBLTimer = ffxivminion.GetSetting("gFateBLTimer",120) -- check if needed
	
	gDoChainFates = ffxivminion.GetSetting("gDoChainFates",true)
	gGrindDoBattleFates = ffxivminion.GetSetting("gGrindDoBattleFates",true)
	gGrindDoBossFates = ffxivminion.GetSetting("gGrindDoBossFates",true)
	gGrindDoGatherFates = ffxivminion.GetSetting("gGrindDoGatherFates",true)
	gGrindDoDefenseFates = ffxivminion.GetSetting("gGrindDoDefenseFates",true)
	gGrindDoEscortFates = ffxivminion.GetSetting("gGrindDoEscortFates",true)
	
	gFateChainWaitPercent = ffxivminion.GetSetting("gFateChainWaitPercent",0)
	gFateBattleWaitPercent = ffxivminion.GetSetting("gFateBattleWaitPercent",0)
	gFateBossWaitPercent = ffxivminion.GetSetting("gFateBossWaitPercent",1)
	gFateGatherWaitPercent = ffxivminion.GetSetting("gFateGatherWaitPercent",0)
	gFateDefenseWaitPercent = ffxivminion.GetSetting("gFateDefenseWaitPercent",0)
	gFateEscortWaitPercent = ffxivminion.GetSetting("gFateEscortWaitPercent",0)
	
	gFateWaitNearEvac = ffxivminion.GetSetting("gFateWaitNearEvac",true)
	gFateRandomDelayMin = ffxivminion.GetSetting("gFateRandomDelayMin",0)
	gFateRandomDelayMax = ffxivminion.GetSetting("gFateRandomDelayMax",0)
	
	self.GUI = {}
	self.GUI.main_tabs = GUI_CreateTabs("Status,Settings,Hunting,Tweaks",true)
end

function ffxiv_task_grind:Draw()
	
	GUI_DrawTabs(self.GUI.main_tabs)
	local tabs = self.GUI.main_tabs
	
	if (tabs.tabs[1].isselected) then
		GUI:BeginChild("##header-status",0,GUI_GetFrameHeight(1),true)
		GUI:PushItemWidth(120)					
		
		GUI_Capture(GUI:Checkbox(GetString("botEnabled"),FFXIV_Common_BotRunning),"FFXIV_Common_BotRunning");
		
		GUI:PopItemWidth()
		GUI:EndChild()
	end
	
	if (tabs.tabs[2].isselected) then
		GUI:BeginChild("##header-settings",0,GUI_GetFrameHeight(12),true)
		GUI:PushItemWidth(80)	

		GUI_Capture(GUI:Checkbox(GetString("doHuntingLog"),gGrindDoHuntlog),"gGrindDoHuntlog");
		GUI_Capture(GUI:Checkbox(GetString("doAtma"),gGrindAtmaMode),"gGrindAtmaMode", function () GUI_Set("gGrindDoFates",true) GUI_Set("gGrindFatesOnly",true) GUI_Set("gGrindLuminousMode",false) GUI_Set("gGrindFatesNoMinLevel",true) end)
		GUI_Capture(GUI:Checkbox("Do Luminous",gGrindLuminousMode),"gGrindLuminousMode", function () GUI_Set("gGrindDoFates",true) GUI_Set("gGrindFatesOnly",true) GUI_Set("gGrindAtmaMode",false) GUI_Set("gGrindFatesNoMinLevel",true) end);
		
		GUI_Capture(GUI:Checkbox(GetString("doFates"),gGrindDoFates),"gGrindDoFates"); GUI:SameLine(0,10)
		GUI_Capture(GUI:Checkbox(GetString("fatesOnly"),gGrindFatesOnly),"gGrindFatesOnly", function () GUI_Set("gGrindDoFates",true) end);
		
		GUI_Capture(GUI:Checkbox("Kill Non-Fate Aggro",gFateKillAggro),"gFateKillAggro");
		GUI_Capture(GUI:Checkbox(GetString("restInFates"),gRestInFates),"gRestInFates");
		
		GUI_DrawIntMinMax(GetString("Min Fate Lv."),"gGrindFatesMinLevel",1,2,0,60)
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Number of levels below current Player level.")
		end
		GUI:SameLine(0,10); GUI_Capture(GUI:Checkbox("No Min",gGrindFatesNoMinLevel),"gGrindFatesNoMinLevel");
		GUI_DrawIntMinMax(GetString("Max Fate Lv."),"gGrindFatesMaxLevel",1,2,0,60)
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Number of levels above current Player level.")
		end
		GUI:SameLine(0,10); GUI_Capture(GUI:Checkbox("No Max",gGrindFatesNoMaxLevel),"gGrindFatesNoMaxLevel");
		
		GUI_DrawIntMinMax(GetString("fateTeleportPercent"),"gFateTeleportPercent",1,2,0,99)
		GUI_Capture(GUI:Checkbox(GetString("waitNearEvac"),gFateWaitNearEvac),"gFateWaitNearEvac");
		GUI_DrawIntMinMax("Min Random Delay (s)","gFateRandomDelayMin",10,20,0,120)
		GUI_DrawIntMinMax("Max Random Delay (s)","gFateRandomDelayMax",10,20,0,240)
		
		GUI:PopItemWidth()
		GUI:EndChild()
	end
	
	if (tabs.tabs[3].isselected) then
		GUI:BeginChild("##header-hunting",0,GUI_GetFrameHeight(3),true)
		GUI:PushItemWidth(100)	
		
		GUI_Capture(GUI:Checkbox(GetString("prioritizeClaims"),gClaimFirst),"gClaimFirst");
		GUI_DrawIntMinMax(GetString("claimRange"),"gClaimRange",1,5,0,50)
		GUI_Capture(GUI:Checkbox(GetString("attackClaimed"),gClaimed),"gClaimed");
		
		--GUI_DrawIntMinMax(GetString("combatRangePercent"),"gCombatRangePercent",1,5,25,100)
		
		GUI:PopItemWidth()
		GUI:EndChild()
	end
	
	if (tabs.tabs[4].isselected) then
		GUI:BeginChild("##header-tweaks",0,GUI_GetFrameHeight(12),true)
		GUI:PushItemWidth(100)	
		
		GUI_Capture(GUI:Checkbox(GetString("Chain Fates"),gDoChainFates),"gDoChainFates");
		GUI_DrawIntMinMax(GetString("Chain Fate Wait %"),"gFateChainWaitPercent",1,5,0,99)
		GUI_Capture(GUI:Checkbox(GetString("Battle Fates"),gGrindDoBattleFates),"gGrindDoBattleFates");
		GUI_DrawIntMinMax(GetString("Battle Fate Wait %"),"gFateBattleWaitPercent",1,5,0,99)
		GUI_Capture(GUI:Checkbox(GetString("Boss Fates"),gGrindDoBossFates),"gGrindDoBossFates");
		GUI_DrawIntMinMax(GetString("Boss Fate Wait %"),"gFateBossWaitPercent",1,5,0,99)
		GUI_Capture(GUI:Checkbox(GetString("Gather Fates"),gGrindDoGatherFates),"gGrindDoGatherFates");
		GUI_DrawIntMinMax(GetString("Gather Fate Wait %"),"gFateGatherWaitPercent",1,5,0,99)
		GUI_Capture(GUI:Checkbox(GetString("Defense Fates"),gGrindDoDefenseFates),"gGrindDoDefenseFates");
		GUI_DrawIntMinMax(GetString("Defense Fate Wait %"),"gFateDefenseWaitPercent",1,5,0,99)
		GUI_Capture(GUI:Checkbox(GetString("Escort Fates"),gGrindDoEscortFates),"gGrindDoEscortFates");
		GUI_DrawIntMinMax(GetString("Escort Fate Wait %"),"gFateEscortWaitPercent",1,5,0,99)
	
		GUI:PopItemWidth()
		GUI:EndChild()
	end
end
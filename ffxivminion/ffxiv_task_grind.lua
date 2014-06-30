ffxiv_task_grind = inheritsFrom(ml_task)
ffxiv_task_grind.name = "LT_GRIND"
ffxiv_task_grind.ticks = 0
ffxiv_task_grind.blTicks = 0
gFateID = 0

ffxiv_task_grind.atmas = {
	["Maiden"] = { name = "Maiden", 			hour = 1,	tele = 3, 	map = 148, item = 7851, mesh = "Central Shroud"},
	["Scorpion"] = { name = "Scorpion", 		hour = 2,	tele = 20, 	map = 146, item = 7852, mesh = "Southern Thanalan"},
	["Waterbearer"] = { name = "Waterbearer",	hour = 3, 	tele = 15, 	map = 139, item = 7853, mesh = "Upper La Noscea - Right"},
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
	newinst.startMap = Player.localmapid
    
    --this is the targeting function that will be used for the generic KillTarget task
    newinst.targetFunction = GetNearestGrindAttackable
    
    return newinst
end

c_nextgrindmarker = inheritsFrom( ml_cause )
e_nextgrindmarker = inheritsFrom( ml_effect )
function c_nextgrindmarker:evaluate()
    if ((gBotMode == strings[gCurrentLanguage].partyMode and not IsLeader()) or
		 gDoFates == "1" and gFatesOnly == "1") 
	then
        return false
    end
    
    if ( ml_task_hub:CurrentTask().currentMarker ~= nil and ml_task_hub:CurrentTask().currentMarker ~= 0 ) then
        local marker = nil
        
        -- first check to see if we have no initiailized marker
        if (ml_task_hub:CurrentTask().currentMarker == false) then --default init value
            marker = ml_marker_mgr.GetNextMarker(strings[gCurrentLanguage].grindMarker, ml_task_hub:CurrentTask().filterLevel)
        
			if (marker == nil) then
				ml_task_hub:CurrentTask().filterLevel = false
				marker = ml_marker_mgr.GetNextMarker(strings[gCurrentLanguage].grindMarker, ml_task_hub:CurrentTask().filterLevel)
			end	
		end
        
        -- next check to see if our level is out of range
        if (marker == nil) then
            if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then
                if 	(ml_task_hub:CurrentTask().filterLevel) and
					(Player.level < ml_task_hub:CurrentTask().currentMarker:GetMinLevel() or 
                    Player.level > ml_task_hub:CurrentTask().currentMarker:GetMaxLevel()) 
                then
                    marker = ml_marker_mgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker:GetType(), ml_task_hub:CurrentTask().filterLevel)
                end
            end
        end
        
        -- last check if our time has run out
        if (marker == nil) then
            local time = ml_task_hub:CurrentTask().currentMarker:GetTime()
			if (time and time ~= 0 and TimeSince(ml_task_hub:CurrentTask().markerTime) > time * 1000) then
				--ml_debug("Marker timer: "..tostring(TimeSince(ml_task_hub:CurrentTask().markerTime)) .."seconds of " ..tostring(time)*1000)
                ml_debug("Getting Next Marker, TIME IS UP!")
                marker = ml_marker_mgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker:GetType(), ml_task_hub:CurrentTask().filterLevel)
            else
                return false
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
    ml_task_hub:CurrentTask().currentMarker = e_nextgrindmarker.marker
    ml_task_hub:CurrentTask().markerTime = ml_global_information.Now
	ml_global_information.MarkerTime = ml_global_information.Now
    ml_global_information.MarkerMinLevel = ml_task_hub:CurrentTask().currentMarker:GetMinLevel()
    ml_global_information.MarkerMaxLevel = ml_task_hub:CurrentTask().currentMarker:GetMaxLevel()
    ml_global_information.BlacklistContentID = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].NOTcontentIDEquals)
    ml_global_information.WhitelistContentID = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].contentIDEquals)
	gStatusMarkerName = ml_task_hub:CurrentTask().currentMarker:GetName()
end

function ffxiv_task_grind:Init()
    --init ProcessOverWatch() elements
    
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 25 )
    self:add(ke_dead, self.overwatch_elements)
	
	local ke_atma = ml_element:create( "NextAtma", c_nextatma, e_nextatma, 20 )
    self:add(ke_atma, self.overwatch_elements)
	
	--local ke_avoid = ml_element:create( "Avoid", c_avoid, e_avoid, 19)
	--self:add(ke_avoid, self.overwatch_elements)
    
    local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 15 )
    self:add(ke_flee, self.overwatch_elements)
    
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 14 )
    self:add(ke_rest, self.overwatch_elements)
    
    local ke_addFate = ml_element:create( "AddFate", c_add_fate, e_add_fate, 10 )
    self:add(ke_addFate, self.overwatch_elements)

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

function ffxiv_task_grind:OnSleep()

end

function ffxiv_task_grind:OnTerminate()

end

function ffxiv_task_grind:IsGoodToAbort()

end

function ffxiv_task_grind.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gDoFates" or
                k == "gFatesOnly" or
                k == "gMinFateLevel" or
                k == "gMaxFateLevel" or              
                k == "gRestHP" or
                k == "gRestMP" or
                k == "gFleeHP" or
                k == "gFleeMP" or
                k == "gFateWaitPercent" or
				k == "gFateTeleportPercent" or
                k == "gFateBLTimer" or
                k == "gRestInFates" or
                k == "gCombatRangePercent" or
				k == "gAtma" or
				k == "AlwaysKillAggro" or
				k == "gClaimFirst" or
				k == "gClaimRange" or
				k == "gClaimed" )
        then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

function ffxiv_task_grind.SetEvacPoint()
    if (gmeshname ~= "" and Player.onmesh) then
        ml_marker_mgr.markerList["evacPoint"] = Player.pos
        ml_marker_mgr.WriteMarkerFile(ml_marker_mgr.markerPath)
    end
end

function ffxiv_task_grind.BlacklistTarget()
    local target = Player:GetTarget()
    if ValidTable(target) then
        ml_blacklist.AddBlacklistEntry(strings[gCurrentLanguage].monsters, target.contentid, target.name, true)
        ml_debug("Blacklisted "..target.name)
    else
        ml_debug("Invalid target or no target selected")
    end
end

function ffxiv_task_grind.BlacklistFate(arg)
    if (gFateName ~= "") then
        if (arg == "gBlacklistFateAddEvent") then
            ml_blacklist.AddBlacklistEntry(strings[gCurrentLanguage].fates, tonumber(gFateID), gFateName, true)
        elseif (arg == "gBlacklistFateRemEvent") then
            ml_blacklist.DeleteEntry(strings[gCurrentLanguage].fates, tonumber(gFateID))
        end
    else
        ml_debug("No valid fate selected")
    end
end

function ffxiv_task_grind.BlacklistInitUI()
    GUI_NewField(ml_blacklist_mgr.mainwindow.name, strings[gCurrentLanguage].targetName, "gTargetName", strings[gCurrentLanguage].addEntry)
    GUI_NewButton(ml_blacklist_mgr.mainwindow.name, strings[gCurrentLanguage].blacklistTarget, "ffxiv_task_grind.blacklistTarget",strings[gCurrentLanguage].addEntry)
    RegisterEventHandler("ffxiv_task_grind.blacklistTarget",ffxiv_task_grind.BlacklistTarget)
end

function ffxiv_task_grind.HuntingUI()
	GUI_NewField	(ml_blacklist_mgr.mainwindow.name, strings[gCurrentLanguage].targetName,"gTargetName", 		strings[gCurrentLanguage].addEntry)
	GUI_NewButton	(ml_blacklist_mgr.mainwindow.name, strings[gCurrentLanguage].hunt, 	"ffxivminion.huntTarget",strings[gCurrentLanguage].addEntry)
	RegisterEventHandler("ffxivminion.huntTarget",ffxiv_task_grind.HuntTarget)
end

function ffxiv_task_grind.HuntTarget()
	local target = Player:GetTarget()
	if ValidTable(target) then
		ml_blacklist.AddBlacklistEntry(strings[gCurrentLanguage].huntMonsters, target.contentid, target.name, true)
	end
end

-- UI settings etc
function ffxiv_task_grind.UIInit()
    -- Grind
	--GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].alwaysKillAggro,"gKillAggroAlways",strings[gCurrentLanguage].grindMode)
	GUI_NewCheckbox(GetString("advancedSettings"), strings[gCurrentLanguage].prioritizeClaims,"gClaimFirst",strings[gCurrentLanguage].grindMode)
	GUI_NewNumeric(GetString("advancedSettings"), strings[gCurrentLanguage].claimRange, "gClaimRange", 	strings[gCurrentLanguage].grindMode, "0", "50")
	GUI_NewCheckbox(GetString("advancedSettings"), strings[gCurrentLanguage].attackClaimed, "gClaimed",	strings[gCurrentLanguage].grindMode)
    GUI_NewNumeric(GetString("advancedSettings"), strings[gCurrentLanguage].restHP, "gRestHP", strings[gCurrentLanguage].grindMode, "0", "100")
    GUI_NewNumeric(GetString("advancedSettings"), strings[gCurrentLanguage].restMP, "gRestMP", strings[gCurrentLanguage].grindMode, "0", "100")
    GUI_NewNumeric(GetString("advancedSettings"), strings[gCurrentLanguage].fleeHP, "gFleeHP", strings[gCurrentLanguage].grindMode, "0", "100")
    GUI_NewNumeric(GetString("advancedSettings"), strings[gCurrentLanguage].fleeMP, "gFleeMP", strings[gCurrentLanguage].grindMode, "0", "100")
    GUI_NewNumeric(GetString("advancedSettings"), strings[gCurrentLanguage].combatRangePercent, "gCombatRangePercent", strings[gCurrentLanguage].grindMode, "1", "100")
	
    GUI_NewButton(mm.mainwindow.name, strings[gCurrentLanguage].setEvacPoint, "setEvacPointEvent",GetString("editor"))
    RegisterEventHandler("setEvacPointEvent",ffxiv_task_grind.SetEvacPoint)
    
    -- Fates
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].doAtma, "gAtma",GetString("grindMode"))
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].doFates, "gDoFates",GetString("grindMode"))
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].fatesOnly, "gFatesOnly",GetString("grindMode"))
    GUI_NewCheckbox(GetString("advancedSettings"), strings[gCurrentLanguage].restInFates, "gRestInFates",strings[gCurrentLanguage].fates)
	--GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].killaggrononfateenemies, "gKillAggroEnemies",strings[gCurrentLanguage].fates)
    GUI_NewNumeric(GetString("advancedSettings"), strings[gCurrentLanguage].maxFateLevel, "gMaxFateLevel", strings[gCurrentLanguage].fates, "0", "50")
    GUI_NewNumeric(GetString("advancedSettings"), strings[gCurrentLanguage].minFateLevel, "gMinFateLevel", strings[gCurrentLanguage].fates, "0", "50")
    GUI_NewNumeric(GetString("advancedSettings"), strings[gCurrentLanguage].waitForComplete, "gFateWaitPercent", strings[gCurrentLanguage].fates, "0", "99")
	GUI_NewNumeric(GetString("advancedSettings"), strings[gCurrentLanguage].fateTeleportPercent, "gFateTeleportPercent", strings[gCurrentLanguage].fates, "0", "99")
    --GUI_NewNumeric(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].blacklistTimer, "gFateBLTimer", strings[gCurrentLanguage].fates, "30","600")
    
    GUI_SizeWindow(ml_global_information.MainWindow.Name,250,400)
    
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
    
    if (Settings.FFXIVMINION.gRestHP == nil) then
        Settings.FFXIVMINION.gRestHP = "70"
    end
    
    if (Settings.FFXIVMINION.gRestMP == nil) then
        Settings.FFXIVMINION.gRestMP = "0"
    end
    
    if (Settings.FFXIVMINION.gFleeHP == nil) then
        Settings.FFXIVMINION.gFleeHP = "20"
    end
    
    if (Settings.FFXIVMINION.gFleeMP == nil) then
        Settings.FFXIVMINION.gFleeMP = "0"
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
    
    if (Settings.FFXIVMINION.gFateWaitPercent == nil) then
        Settings.FFXIVMINION.gFateWaitPercent = "0"
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
    gRestHP = Settings.FFXIVMINION.gRestHP
    gRestMP = Settings.FFXIVMINION.gRestMP
    gFleeHP = Settings.FFXIVMINION.gFleeHP
    gFleeMP = Settings.FFXIVMINION.gFleeMP
    gCombatRangePercent = Settings.FFXIVMINION.gCombatRangePercent
    gFateWaitPercent = Settings.FFXIVMINION.gFateWaitPercent
	gFateTeleportPercent = Settings.FFXIVMINION.gFateTeleportPercent
    gFateBLTimer = Settings.FFXIVMINION.gFateBLTimer
	gKillAggroEnemies = Settings.FFXIVMINION.gKillAggroEnemies
    
    --add blacklist init function
    ml_blacklist_mgr.AddInitUI(strings[gCurrentLanguage].monsters,ffxiv_task_grind.BlacklistInitUI)
	ml_blacklist_mgr.AddInitUI(strings[gCurrentLanguage].huntMonsters,ffxiv_task_grind.HuntingUI)
    ml_blacklist_mgr.AddInitUI(strings[gCurrentLanguage].fates,ffxiv_task_fate.BlacklistInitUI)
	
	ffxiv_task_grind.SetupMarkers()
end

function ffxiv_task_grind.SetupMarkers()
    -- add marker templates for grinding
    local grindMarker = ml_marker:Create("grindTemplate")
	grindMarker:SetType(strings[gCurrentLanguage].grindMarker)
	grindMarker:AddField("string", strings[gCurrentLanguage].contentIDEquals, "")
	grindMarker:AddField("string", strings[gCurrentLanguage].NOTcontentIDEquals, "")
    grindMarker:SetTime(300)
    grindMarker:SetMinLevel(1)
    grindMarker:SetMaxLevel(50)
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
                gFateName = f.name
                gFateID = f.id
            end
        end
        if (not fafound) then
            gFateName = ""
            gFateID = 0
        end
        
        local target = Player:GetTarget()
        if target and target.attackable then
            gTargetName = target.name
        else
            gTargetName = strings[gCurrentLanguage].notAttackable
        end
    end
end

RegisterEventHandler("GUI.Update",ffxiv_task_grind.GUIVarUpdate)

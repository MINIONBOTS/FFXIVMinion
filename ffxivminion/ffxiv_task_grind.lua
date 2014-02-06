ffxiv_task_grind = inheritsFrom(ml_task)
ffxiv_task_grind.name = "LT_GRIND"
ffxiv_task_grind.ticks = 0
ffxiv_task_grind.blTicks = 0
ffxiv_task_grind.Mount = 1
ffxiv_task_grind.Stance = 4
gFateID = 0

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
    newinst.previousMarker = false
    
    --this is the targeting function that will be used for the generic KillTarget task
    newinst.targetFunction = GetNearestGrindAttackable
    
    return newinst
end

function ffxiv_task_grind:Init()
    --init ProcessOverWatch() elements
    
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 20 )
    self:add( ke_dead, self.overwatch_elements)
    
    local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 15 )
    self:add( ke_flee, self.overwatch_elements)
    
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 14 )
    self:add( ke_rest, self.overwatch_elements)
    
    local ke_addFate = ml_element:create( "AddFate", c_add_fate, e_add_fate, 10 )
    self:add(ke_addFate, self.overwatch_elements)
    
    --not sure if we need this, taking it out for now
    --init Process() cnes
    --local ke_mobAggro = ml_element:create( "MobAggro", c_mobaggro, e_mobaggro, 35 )
    --self:add(ke_mobAggro, self.process_elements)

    local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 25 )
    self:add( ke_returnToMarker, self.process_elements)
    
    --nextmarker defined in ffxiv_task_gather.lua
    local ke_nextMarker = ml_element:create( "NextMarker", c_nextmarker, e_nextmarker, 20 )
    self:add( ke_nextMarker, self.process_elements)
    
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

	if gChocoStance == "Follow"  then
		ffxiv_task_grind.Stance = 3	
	elseif  gChocoStance == "Free Stance"  then
		ffxiv_task_grind.Stance = 4
	elseif  gChocoStance == "Defender Stance"  then
		ffxiv_task_grind.Stance = 5
	elseif  gChocoStance == "Attacker Stance"  then
		ffxiv_task_grind.Stance = 6	
	elseif  gChocoStance == "Healer Stance"  then
		ffxiv_task_grind.Stance = 7	
	end
	
	--Mounts
	if  gMounts == "Ahriman"  then
		ffxiv_task_grind.Mount  = 9
	elseif  gMounts == "Behemoth"  then
		ffxiv_task_grind.Mount  = 18
	elseif  gMounts == "Cavalry Drake"  then
		ffxiv_task_grind.Mount  = 19
	elseif  gMounts == "Coeurl"  then
		ffxiv_task_grind.Mount  = 8
	elseif  gMounts == "Company Chocobo"  then
		ffxiv_task_grind.Mount  = 1
	elseif  gMounts == "Gilded Magitek Armor"  then
		ffxiv_task_grind.Mount  = 21
	elseif  gMounts == "Goobbue"  then
		ffxiv_task_grind.Mount  = 4
	elseif  gMounts == "Laurel Goobue"  then
		ffxiv_task_grind.Mount  = 20
	elseif  gMounts == "Legacy Chocobo"  then
		ffxiv_task_grind.Mount  = 5
	elseif  gMounts == "Magitek Armor"  then
		ffxiv_task_grind.Mount  = 6
	elseif  gMounts == "Nightmare"  then
		ffxiv_task_grind.Mount  = 22
	elseif  gMounts == "Unicorn"  then
		ffxiv_task_grind.Mount  = 15
	end
	
    for k,v in pairs(NewVals) do
        if ( 	k == "gDoFates" or
                k == "gFatesOnly" or
                k == "gIgnoreGrindLvl" or
                k == "gMinFateLevel" or
                k == "gMaxFateLevel" or
                k == "gMinMobLevel" or
                k == "gMaxMobLevel" or                 
                k == "gRestHP" or
                k == "gRestMP" or
                k == "gFleeHP" or
                k == "gFleeMP" or
                k == "gFateWaitPercent" or
                k == "gFateBLTimer" or
                k == "gRestInFates" or
                k == "gCombatRangePercent" or
				k == "gMounts" or
				k == "gChoco" or			
				k == "gChocoName" or			
				k == "gChocoStance" or
				k == "gClaimFirst" or
				k == "gClaimed" or
				k == "gClaimRange" or
				k == "gKillAggroAlways")
        then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

function ffxiv_task_grind.SetEvacPoint()
    if (gmeshname ~= "" and Player.onmesh) then
        mm.evacPoint = Player.pos
        mm.WriteMarkerList(gmeshname)
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
            ml_blacklist.AddBlacklistEntry("Fates", tonumber(gFateID), gFateName, true)
        elseif (arg == "gBlacklistFateRemEvent") then
            ml_blacklist.DeleteEntry("Fates", tonumber(gFateID))
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

-- UI settings etc
function ffxiv_task_grind.UIInit()
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
    
    if (Settings.FFXIVMINION.gMaxMobLevel == nil) then
        Settings.FFXIVMINION.gMaxMobLevel = "3"
    end
    
    if (Settings.FFXIVMINION.gMinMobLevel == nil) then
        Settings.FFXIVMINION.gMinMobLevel = "3"
    end
    
    if (Settings.FFXIVMINION.gIgnoreGrindLvl == nil) then
        Settings.FFXIVMINION.gIgnoreGrindLvl = "0"
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
    
    if (Settings.FFXIVMINION.gCombatRangePercent == nil) then
        Settings.FFXIVMINION.gCombatRangePercent = "75"
    end
    
    if (Settings.FFXIVMINION.gRestInFates == nil) then
        Settings.FFXIVMINION.gRestInFates = "1"
    end
    
    if (Settings.FFXIVMINION.gFateWaitPercent == nil) then
        Settings.FFXIVMINION.gFateWaitPercent = "0"
    end
    
    if (Settings.FFXIVMINION.gFateBLTimer == nil) then
        Settings.FFXIVMINION.gFateBLTimer = "120"
    end
    
	if (Settings.FFXIVMINION.gKillAggroEnemies == nil) then
		Settings.FFXIVMINION.gKillAggroEnemies = "0"
	end
	--new stuff
	if (Settings.FFXIVMINION.gMounts == nil) then
		Settings.FFXIVMINION.gMounts = "Company Chocobo"
	end
	if (Settings.FFXIVMINION.gChoco == nil) then
		Settings.FFXIVMINION.gChoco = "0"
	end	
	if (Settings.FFXIVMINION.gChocoName == nil) then
		Settings.FFXIVMINION.gChocoName = "0"
	end
	if (Settings.FFXIVMINION.gChocoStance == nil) then
		Settings.FFXIVMINION.gChocoStance = "Free Stance"
	end
	if (Settings.FFXIVMINION.gClaimFirst == nil) then
		Settings.FFXIVMINION.gClaimFirst = "0"
	end
	if (Settings.FFXIVMINION.gClaimed == nil) then
		Settings.FFXIVMINION.gClaimed = "0"
	end
	if (Settings.FFXIVMINION.gClaimRange == nil) then
		Settings.FFXIVMINION.gClaimRange = "37"
	end
	if (Settings.FFXIVMINION.gKillAggroAlways == nil) then
		Settings.FFXIVMINION.gKillAggroAlways = "1"
	end
	
    -- Grind
	GUI_NewComboBox	(ml_global_information.MainWindow.Name, "Mount","gMounts"	,strings[gCurrentLanguage].grindMode,"Ahriman,Behemoth,Cavalry Drake,Coeurl,Company Chocobo,Gilded Magitek Armor,Goobbue,Laurel Goobue,Legacy Chocobo,Magitek Armor,Nightmare,Unicorn");
	GUI_NewCheckbox	(ml_global_information.MainWindow.Name, "Companion", 		"gChoco",			strings[gCurrentLanguage].grindMode)
	GUI_NewField	(ml_global_information.MainWindow.Name, "Companion's Name", "gChocoName",		strings[gCurrentLanguage].grindMode)
	GUI_NewComboBox	(ml_global_information.MainWindow.Name, "Stance",			"gChocoStance",		strings[gCurrentLanguage].grindMode,"Follow,Free Stance,Defender Stance,Attacker Stance,Healer Stance");
	GUI_NewCheckbox	(ml_global_information.MainWindow.Name, "Prioritize Claims", 	"gClaimFirst",		strings[gCurrentLanguage].grindMode)
	GUI_NewNumeric 	(ml_global_information.MainWindow.Name, "Claim Range:", 		"gClaimRange", 		strings[gCurrentLanguage].grindMode, "0", "250")
	GUI_NewCheckbox	(ml_global_information.MainWindow.Name, "Attack Claimed", 		"gClaimed",			strings[gCurrentLanguage].grindMode)
	GUI_NewCheckbox	(ml_global_information.MainWindow.Name, "Always Kill Aggro",	"gKillAggroAlways",		strings[gCurrentLanguage].grindMode)
    GUI_NewNumeric(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].restHP, "gRestHP", strings[gCurrentLanguage].grindMode, "0", "100")
    GUI_NewNumeric(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].restMP, "gRestMP", strings[gCurrentLanguage].grindMode, "0", "100")
    GUI_NewNumeric(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].fleeHP, "gFleeHP", strings[gCurrentLanguage].grindMode, "0", "100")
    GUI_NewNumeric(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].fleeMP, "gFleeMP", strings[gCurrentLanguage].grindMode, "0", "100")
    GUI_NewNumeric(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].combatRangePercent, "gCombatRangePercent", strings[gCurrentLanguage].grindMode, "1", "100")
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].ignoreMarkerLevels, "gIgnoreGrindLvl",strings[gCurrentLanguage].grindMode)
    GUI_NewButton(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].setEvacPoint, "setEvacPointEvent",strings[gCurrentLanguage].grindMode)
    RegisterEventHandler("setEvacPointEvent",ffxiv_task_grind.SetEvacPoint)
    
    -- Fates
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].doFates, "gDoFates","Fates")
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].fatesOnly, "gFatesOnly","Fates")
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].restInFates, "gRestInFates","Fates")
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].killaggrononfateenemies, "gKillAggroEnemies","Fates")
    GUI_NewNumeric(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].maxFateLevel, "gMaxFateLevel", "Fates", "0", "50")
    GUI_NewNumeric(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].minFateLevel, "gMinFateLevel", "Fates", "0", "50")
    GUI_NewNumeric(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].waitForComplete, "gFateWaitPercent", "Fates", "0", "99")
    GUI_NewNumeric(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].blacklistTimer, "gFateBLTimer", "Fates", "30","600")
    
    GUI_SizeWindow(ml_global_information.MainWindow.Name,250,400)
	
    gDoFates = Settings.FFXIVMINION.gDoFates
    gFatesOnly = Settings.FFXIVMINION.gFatesOnly
    gMaxFateLevel = Settings.FFXIVMINION.gMaxFateLevel
    gMinFateLevel = Settings.FFXIVMINION.gMinFateLevel
    gMaxMobLevel = Settings.FFXIVMINION.gMaxMobLevel
    gMinMobLevel = Settings.FFXIVMINION.gMinMobLevel
    gRestInFates = Settings.FFXIVMINION.gRestInFates
    gIgnoreGrindLvl = Settings.FFXIVMINION.gIgnoreGrindLvl
    gRestHP = Settings.FFXIVMINION.gRestHP
    gRestMP = Settings.FFXIVMINION.gRestMP
    gFleeHP = Settings.FFXIVMINION.gFleeHP
    gFleeMP = Settings.FFXIVMINION.gFleeMP
    gCombatRangePercent = Settings.FFXIVMINION.gCombatRangePercent
    gFateWaitPercent = Settings.FFXIVMINION.gFateWaitPercent
    gFateBLTimer = Settings.FFXIVMINION.gFateBLTimer
	gKillAggroEnemies = Settings.FFXIVMINION.gKillAggroEnemies
	
	gMounts = Settings.FFXIVMINION.gMounts
	gChoco =  Settings.FFXIVMINION.gChoco
	gChocoName =  Settings.FFXIVMINION.gChocoName	
	gChocoStance =  Settings.FFXIVMINION.gChocoStance
	gClaimFirst = Settings.FFXIVMINION.gClaimFirst
	gClaimed = Settings.FFXIVMINION.gClaimed
	gClaimRange = Settings.FFXIVMINION.gClaimRange
	gKillAggroAlways = Settings.FFXIVMINION.gKillAggroAlways
    
    --add blacklist init function
    ml_blacklist_mgr.AddInitUI(strings[gCurrentLanguage].monsters,ffxiv_task_grind.BlacklistInitUI)
    ml_blacklist_mgr.AddInitUI("Fates",ffxiv_task_fate.BlacklistInitUI)
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

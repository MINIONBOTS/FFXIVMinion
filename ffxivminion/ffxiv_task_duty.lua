ffxiv_task_duty = inheritsFrom(ml_task)
ffxiv_task_duty.name = "LT_DUTY"
ffxiv_task_duty.dutyInfo = {}
ffxiv_task_duty.dutyPath = GetStartupPath()..[[\LuaMods\ffxivminion\DutyProfiles\]]
ffxiv_task_duty.updateTicks = 0
ffxiv_task_duty.respawnTime = 0
ffxiv_task_duty.leader = ""
ffxiv_task_duty.leaderLastPos = {}
ffxiv_task_duty.leaderSet = false
ffxiv_task_duty.dutySet = false
ffxiv_task_duty.dutyCleared = false
ffxiv_task_duty.joinAttempts = 0
ffxiv_task_duty.independentMode = false
ffxiv_task_duty.lastCompletion = 0
ffxiv_task_duty.preventFail = 0
ffxiv_task_duty.performanceLevels = {
	["Extreme"] = 2;
	["Fast"] = 4;
	["Normal"] = 6;
	["Slow"] = 8;
}

function file_exists(name)
	if (name) then
	   local f=io.open(name,"r")
	   if f~=nil then io.close(f) return true else return false end
	end
end

function ffxiv_task_duty.Create()
    local newinst = inheritsFrom(ffxiv_task_duty)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_duty members
    newinst.name = "LT_DUTY"
    newinst.targetid = 0
    newinst.timer = 0
    newinst.encounter = {}
	newinst.encounterIndex = 0
	newinst.encounterCompleted = true
	newinst.joinTimer = 0
	newinst.leaveTimer = 0
	newinst.resets = {}
	newinst.suppressFollowTimer = 0
	newinst.state = ""
	newinst.pos = {}
	
	ffxiv_task_duty.leader = ""
    
    return newinst
end

c_followleaderduty = inheritsFrom( ml_cause )
e_followleaderduty = inheritsFrom( ml_effect )
c_followleaderduty.rrange = 8
c_followleaderduty.leader = nil
c_followleaderduty.leaderpos = nil
function c_followleaderduty:evaluate()
    if (IsDutyLeader() or not OnDutyMap() or ml_task_hub:CurrentTask().suppressFollow) then
        return false
    end
	
	local leader = GetDutyLeader()
	local leaderPos = GetDutyLeaderPos()
	if (ValidTable(leaderPos) and ValidTable(leader)) then
		local myPos = Player.pos	
		
		local distance = Distance3D(myPos.x, myPos.y, myPos.z, leaderPos.x, leaderPos.y, leaderPos.z)
		if ((distance > c_followleaderduty.rrange and leader.onmesh) or (distance > c_followleaderduty.rrange and distance < 30 and not leader.onmesh) or
			(distance > 1 and gTeleport == "1")) 
		then				
			c_followleaderduty.leaderpos = leaderPos
			c_followleaderduty.leader = leader
			return true
		end
	end
	
    return false
end
function e_followleaderduty:execute()
    if ( c_followleaderduty.leader ~= nil) then
		local leader = c_followleaderduty.leader
		
        if ( leader.onmesh and Player.onmesh and gTeleport == "0") then
            local lpos = c_followleaderduty.leader.pos
            local myPos = Player.pos
            local distance = Distance2D(myPos.x, myPos.z, lpos.x, lpos.z)
            
            ml_debug( "Moving to Leader: "..tostring(Player:MoveTo(tonumber(lpos.x),tonumber(lpos.y),tonumber(lpos.z),tonumber(c_followleaderduty.rrange))))
            if ( not Player:IsMoving()) then
                if ( ml_global_information.AttackRange < 5 ) then
					c_followleaderduty.rrange = math.random(4,6)
                else
					c_followleaderduty.rrange = math.random(4,6)
                end
            end
        else
			local lpos = c_followleaderduty.leaderpos
            local myPos = Player.pos
			if (gTeleport == "1") then
				Player:Stop()
				GameHacks:TeleportToXYZ(lpos.x, lpos.y, lpos.z)
				Player:SetFacingSynced(Player.pos.h)
			else
				ml_debug( "Following Leader: "..tostring(Player:FollowTarget(c_followleaderduty.leader.id)))
			end
        end
    end
end

c_assistleaderduty= inheritsFrom( ml_cause )
e_assistleaderduty = inheritsFrom( ml_effect )
c_assistleaderduty.targetid = nil
function c_assistleaderduty:evaluate()
    --if (IsDutyLeader() or ml_task_hub:CurrentTask().suppressAssist or not OnDutyMap() or ActionList:IsCasting()) then
	if (IsDutyLeader() or ml_task_hub:CurrentTask().suppressAssist or ActionList:IsCasting()) then
        return false
    end
    
    local leader = GetDutyLeader()
    if (leader) then
		local leaderEntity = EntityList:Get(leader.id)
		if (leaderEntity) then
			local leadtarget = leaderEntity.targetid
			if (ml_task_hub:CurrentTask().name == "LT_SM_KILLTARGET" and ml_task_hub:CurrentTask().targetid == leadtarget) then
				return false
			end
			if ( leadtarget and leadtarget ~= 0 ) then			
				local target = EntityList:Get(leadtarget)
				if ( ValidTable(target) and target.alive and target.attackable and (target.type == 2 or target.type == 3) and (target.onmesh or InCombatRange(target.id))) then
					c_assistleaderduty.targetid = target.id
					return true
				end
			end
		end
    end
    
    return false
end
function e_assistleaderduty:execute()
    if ( c_assistleaderduty.targetid ) then
		local entity = EntityList:Get(c_assistleaderduty.targetid)
		SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
		Player:SetFacingSynced(Player.pos.h)
		
        if (gTeleport == "1") then
            local newTask = ffxiv_task_skillmgrAttack.Create()
            newTask.targetid = c_assistleaderduty.targetid
			local pos = {x = Player.pos.x, y = Player.pos.y, z = Player.pos.z, h = Player.pos.h}
			newTask.safePos = pos
            ml_task_hub:CurrentTask():AddSubTask(newTask)
        else        
            local newTask = ffxiv_task_killtarget.Create()
            newTask.targetid = c_assistleaderduty.targetid 
            ml_task_hub:CurrentTask():AddSubTask(newTask)
        end
    else
        ml_debug("Ohboy, something went really wrong : e_assistleaderduty")
    end
end

c_joinduty = inheritsFrom( ml_cause )
e_joinduty = inheritsFrom( ml_effect )
function c_joinduty:evaluate()
	if (IsPartyLeader() and IsFullParty() and not OnDutyMap()) then			
		if (ml_task_hub:ThisTask().state == "DUTY_NEW" and
			Now() > ml_task_hub:ThisTask().joinTimer )
		then
			return true
		end
	end
	
	return false
end
function e_joinduty:execute()
	if (not ControlVisible("ContentsFinder")) then
		SendTextCommand("/dutyfinder")
		ml_task_hub:ThisTask().joinTimer = Now() + (150 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
	elseif (ControlVisible("ContentsFinder") and not ffxiv_task_duty.dutySet and not ffxiv_task_duty.dutyCleared) then
		Duty:ClearDutySelection()
		ffxiv_task_duty.dutyCleared = true
		ml_task_hub:ThisTask().joinTimer = Now() + (500 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
	elseif (ControlVisible("ContentsFinder") and not ffxiv_task_duty.dutySet and ffxiv_task_duty.dutyCleared) then
		local duty = GetDutyFromID(ffxiv_task_duty.mapID)
		if (duty) then
			Duty:SelectDuty(duty.DutyListIndex)
			ffxiv_task_duty.dutySet = true
			ml_task_hub:ThisTask().joinTimer = Now() + (150 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
		end
	elseif (ControlVisible("ContentsFinder") and ffxiv_task_duty.dutySet) then
        ml_task_hub:ThisTask().joinTimer = Now() + (tonumber(gResetDutyTimer) * 1000)
		PressDutyJoin()
		ffxiv_task_duty.dutyCleared = false
		ffxiv_task_duty.dutySet = false
	end
end

--Pushed all reset state stuff for error-catching here.
c_resetstate = inheritsFrom(ml_cause)
e_resetstate = inheritsFrom(ml_effect)
c_resetstate.states = {
	[1] = { timer = 15000, countdown = 0},
	[2] = { timer = 15000, countdown = 0},
}
e_resetstate.task = nil
function c_resetstate:evaluate()
		if (c_resetstate.states[1].test == nil or c_resetstate.states[1].reaction == nil) then
			c_resetstate.states[1].test = function()
				if (not OnDutyMap() and (ml_task_hub:ThisTask().state == "DUTY_NEXTENCOUNTER" or ml_task_hub:ThisTask().state == "DUTY_DOENCOUNTER")) then
					return true
				else
					return false
				end
			end
			c_resetstate.states[1].reaction = function() ml_task_hub:ThisTask().state = "" end
		end
		
		if (c_resetstate.states[2].test == nil or c_resetstate.states[2].reaction == nil) then
			c_resetstate.states[2].test = function()
				if (IsPartyLeader() and IsFullParty() and not OnDutyMap()) then	
					if (ml_task_hub:ThisTask().state == "DUTY_ENTER" and Now() > ml_task_hub:ThisTask().joinTimer) then
						return true
					end
				end
				return false
			end
			c_resetstate.states[2].reaction = function() ml_task_hub:ThisTask().state = "" end
		end
	
	--Do a first pass, check each reset to see if it's test function evaluates true, and set it's timer accordingly.
	if (ValidTable(c_resetstate.states)) then
		for id, condition in pairs(c_resetstate.states) do
			if (condition.test() and condition.countdown == 0) then
				c_resetstate.states[id].countdown = Now() + condition.timer
			end
		end
	end
	
	--Secondary pass, check to see if the test condition has validated, bring us back in compliance, clear the condition.
	if (ValidTable(c_resetstate.states)) then
		for id, condition in pairs(c_resetstate.states) do
			if (not condition.test() and condition.countdown ~= 0 and Now() < condition.countdown) then
				c_resetstate.states[id].countdown = 0
			end
		end
	end
	
	--Final pass, if the allotted time has passed, queue up the reset to perform it's reaction() function.
	if (ValidTable(c_resetstate.states)) then
		for id, condition in pairs(c_resetstate.states) do
			if (condition.test() and condition.countdown ~= 0 and Now() > condition.timer) then
				e_resetstate.id = id
				e_resetstate.task = condition.reaction()
				return true
			end
		end
	end
	
	return false
end
function e_resetstate:execute()
	d("Resetting conditions. ResetCondition = "..tostring(e_resetstate.id))
	e_resetstate.task()
end

c_readyduty = inheritsFrom( ml_cause )
e_readyduty = inheritsFrom( ml_effect )
function c_readyduty:evaluate()
	if (not OnDutyMap() and IsDutyLeader() and Player.revivestate ~= 2 and Player.revivestate ~= 3 and 
		(ml_task_hub:ThisTask().state == "DUTY_EXIT" or ml_task_hub:ThisTask().state == "")) then
		if (IsFullParty()) then
			return true
		end
	end
	
	return false
end
function e_readyduty:execute()
	if (ml_task_hub:ThisTask().state == "DUTY_EXIT") then
		ml_task_hub:ThisTask().joinAttempts = 0
	end
	
	ml_task_hub:ThisTask().state = "DUTY_NEW" 
	ml_task_hub:ThisTask().joinTimer = Now() + (150 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
end

c_leaveduty = inheritsFrom( ml_cause )
e_leaveduty = inheritsFrom( ml_effect )
function c_leaveduty:evaluate()
	if ( OnDutyMap() and not PartyInCombat() and not Inventory:HasLoot() and Now() > ml_task_hub:ThisTask().leaveTimer) then
		if	(DutyLeaderLeft() or
			Quest:IsQuestRewardDialogOpen() or
			(IsDutyLeader() and (ml_task_hub:ThisTask().state == "DUTY_EXIT"))) then
			return true
		end
	end
	
	return false
end
function e_leaveduty:execute()
	if (Quest:IsQuestRewardDialogOpen()) then
		Quest:CompleteQuestReward()
		ml_task_hub:ThisTask().leaveTimer = Now() + (150 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
	else
		if not ControlVisible("ContentsFinder") then
			Player:Stop()
			SendTextCommand("/dutyfinder")
			ml_task_hub:ThisTask().leaveTimer = Now() + (300 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
		elseif ControlVisible("ContentsFinder") and not ControlVisible("SelectYesno") then
			PressDutyJoin()
			ml_task_hub:ThisTask().leaveTimer = Now() + (300 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
		elseif ControlVisible("ContentsFinder") and ControlVisible("SelectYesno") then
			PressYesNo(true)
		end
	end
end

c_changeleader = inheritsFrom( ml_cause )
e_changeleader = inheritsFrom( ml_effect )
e_changeleader.name = ""
function c_changeleader:evaluate()
	if (not IsFullParty()) then
		return false
	end
	
	if (OnDutyMap()) then
		if (ffxiv_task_duty.leader == "") then
			e_changeleader.name = Player.name
			return true
		end
	else
		if ((ml_task_hub:ThisTask().state == "DUTY_EXIT" or ml_task_hub:ThisTask().state == "")) then
			local properLeader = GetPartyLeader()
			if (ffxiv_task_duty.leader ~= properLeader.name) then
				e_changeleader.name = properLeader.name
				return true
			end
		end
	end
	
	return false
end
function e_changeleader:execute()
	ffxiv_task_duty.leader = e_changeleader.name
	if (ffxiv_task_duty.leader == Player.name) then
		if (not OnDutyMap()) then
			ml_task_hub:ThisTask().state = ""
		elseif (OnDutyMap()) then
			ml_task_hub:ThisTask().state = "DUTY_ENTER"
		end
	
		ffxiv_task_duty.leaderSet = true
		ffxiv_task_duty.dutySet = false
		ffxiv_task_duty.dutyCleared = false
	else
		ml_task_hub:ThisTask().state = ""
	end
end

c_lootcheck = inheritsFrom( ml_cause )
e_lootcheck = inheritsFrom( ml_effect )
function c_lootcheck:evaluate()
    if (Inventory:HasLoot()) then
        return true
    end	
	
    return false
end
function e_lootcheck:execute()     
	local newTask = ffxiv_task_lootroll.Create()
	ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
end

function ffxiv_task_duty:ProcessOverWatch()
	if (IsLoading() or ml_mesh_mgr.meshLoading) then
		return false
	end
	
    if (TableSize(self.overwatch_elements) > 0) then
		ml_debug(self.name.."->ProcessOverWatch()")
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(self.overwatch_elements)

		ml_cne_hub.queue_to_execute()
		return ml_cne_hub.execute()
	end
end

c_dutyidle = inheritsFrom( ml_cause )
e_dutyidle = inheritsFrom( ml_effect )
function c_dutyidle:evaluate()
	return (not OnDutyMap()) and (
	ml_global_information.idlePulseCount > 4000 or
	ml_task_hub:ThisTask().state == "DUTY_NEXTENCOUNTER" or 
	ml_task_hub:ThisTask().state == "DUTY_DOENCOUNTER" or
	(IsPartyLeader() and ml_task_hub:ThisTask().state == "DUTY_ENTER" and Now() > ml_task_hub:ThisTask().joinTimer))
end
function e_dutyidle:execute()
	ml_debug("Stuck idle in task "..ml_task_hub:ThisTask().name.." with state "..ml_task_hub:ThisTask().state)
	ml_debug("Attempting to recover from error.")
	ml_task_hub:ThisTask():DeleteSubTasks()
	ml_task_hub:ThisTask().state = ""
end
	
function ffxiv_task_duty:Process()
	if (IsLoading() or ml_mesh_mgr.meshLoading) then
		return false
	end
	
	if (IsDutyLeader() and OnDutyMap() and not Inventory:HasLoot()) then
		if (self.state == "DUTY_ENTER") then
			local encounters = ffxiv_task_duty.dutyInfo["Encounters"]
			if (ValidTable(encounters)) then
				if ( ffxiv_task_duty.dutyInfo["EncounterIndex"] == 0 ) then
					self.encounter = encounters[1]
					ffxiv_task_duty.dutyInfo["EncounterIndex"] = 1
					self.encounterIndex = 1
					persistence.store(ffxiv_task_duty.dutyPath..".info",ffxiv_task_duty.dutyInfo)
				else
					self.encounterIndex = ffxiv_task_duty.dutyInfo["EncounterIndex"]
					self.encounter = encounters[self.encounterIndex]
				end
				
				self.state = "DUTY_NEXTENCOUNTER"
				self.encounterCompleted = false
			end
		elseif (self.state == "DUTY_NEXTENCOUNTER" and not self.encounterCompleted) then
			--Pull the positions, and the acceptable radius.
			local pos = self.encounter.startPos["General"]
			local myPos = Player.pos
			
			--Check if we need to teleport.  Changed the distance and made the non-teleport option explicit.
			if ((gTeleport == "0" and Distance3D(myPos.x, myPos.y, myPos.z, pos.x, pos.y, pos.z) < 6) or
				(gTeleport == "1" and Distance3D(myPos.x, myPos.y, myPos.z, pos.x, pos.y, pos.z) < 3)) then
				
				--Set state to "DO_ENCOUNTER".
				self.state = "DUTY_DOENCOUNTER"
				
				--Pull the taskFunction from the encounter.
				local encounterData = self.encounter
				local encounterTask = findfunction(encounterData.taskFunction)()
				encounterTask.encounterData = encounterData
				
				ml_task_hub:CurrentTask():AddSubTask(encounterTask)
				
				--Moved the delay processing here so that any future tasks don't have to explicitly handle this.
				local delay = 1500
				if (encounterData.waitTime) then
					delay = encounterData.waitTime
				end
				
				--d("CurrentTask is: "..tostring(ml_task_hub:CurrentTask().name))
				ml_task_hub:CurrentTask():SetDelay(delay)
			else
				local gotoPos = pos
				if ValidTable(gotoPos) then
					if (gTeleport == "1") then
						GameHacks:TeleportToXYZ(tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z))
						Player:SetFacingSynced(tonumber(gotoPos.h))
					else
						ml_debug( "Moving to ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")	
						Player:MoveTo( tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z),1.0, false, false)
					end
				end
			end
		elseif (self.state == "DUTY_DOENCOUNTER" and self.encounterCompleted) then
			local encounters = ffxiv_task_duty.dutyInfo["Encounters"]
			self.encounterIndex = self.encounterIndex + 1
			ffxiv_task_duty.dutyInfo["EncounterIndex"] = self.encounterIndex
			local encounter = encounters[self.encounterIndex]
			
			if (ValidTable(encounter)) then
				self.state = "DUTY_NEXTENCOUNTER"
				self.encounter = encounter
				persistence.store(ffxiv_task_duty.dutyPath..".info",ffxiv_task_duty.dutyInfo )
				self.encounterCompleted = false
			else
				ffxiv_task_duty.dutyInfo["EncounterIndex"] = 0
				persistence.store(ffxiv_task_duty.dutyPath..".info",ffxiv_task_duty.dutyInfo )
				self.state = "DUTY_EXIT"
			end
		end
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

function ffxiv_task_duty:Init()
    --init Process() cnes		
	local ke_dutyIdle = ml_element:create( "DutyIdle", c_dutyidle, e_dutyidle, 40 )
    self:add(ke_dutyIdle, self.overwatch_elements)
	
	local ke_deadDuty = ml_element:create( "Dead", c_deadduty, e_deadduty, 35 )
    self:add( ke_deadDuty, self.overwatch_elements)	
	
	local ke_followleaderduty = ml_element:create( "FollowLeader", c_followleaderduty, e_followleaderduty, 25 )--minion only
    self:add( ke_followleaderduty, self.overwatch_elements)
	
	local ke_assistleaderduty = ml_element:create( "AssistLeader", c_assistleaderduty, e_assistleaderduty, 20 )--minion only
    self:add( ke_assistleaderduty, self.overwatch_elements)
	
	local ke_pressConfirm = ml_element:create( "PressConfirm", c_pressconfirm, e_pressconfirm, 15 )
    self:add(ke_pressConfirm, self.overwatch_elements)	
	
	local ke_lootcheck = ml_element:create( "Loot", c_lootcheck, e_lootcheck, 19 )--minion only
    self:add( ke_lootcheck, self.process_elements)
	
	local ke_changeLeader = ml_element:create( "ChangeLeader", c_changeleader, e_changeleader, 17 )
    self:add(ke_changeLeader, self.process_elements)
	
	local ke_readyDuty = ml_element:create( "ReadyDuty", c_readyduty, e_readyduty, 16 )
    self:add(ke_readyDuty, self.process_elements) 
	
	local ke_joinDuty = ml_element:create( "JoinDuty", c_joinduty, e_joinduty, 15 )
    self:add(ke_joinDuty, self.process_elements) 

    local ke_leaveDuty = ml_element:create( "LeaveDuty", c_leaveduty, e_leaveduty, 15 )
    self:add(ke_leaveDuty, self.process_elements)
	
	--local ke_autoEquip = ml_element:create( "AutoEquip", c_autoequip, e_autoequip, 10 )
    --self:add( ke_autoEquip, self.process_elements)
	
	
    self:AddTaskCheckCEs()
end

-- UI settings
function ffxiv_task_duty.UIInit()
	
	if ( not ffxivminion.Windows) then
		ffxivminion.Windows = {}
	end
	ffxivminion.Windows.Duty = { id = strings["us"].dutyMode, Name = GetString("dutyMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Duty)
	
	if (Settings.FFXIVMINION.gLastDutyProfile == nil) then
        Settings.FFXIVMINION.gLastDutyProfile = ""
    end
	if (Settings.FFXIVMINION.gResetDutyTimer == nil) then
        Settings.FFXIVMINION.gResetDutyTimer = 60
    end
	if (Settings.FFXIVMINION.gLootOption == nil or Settings.FFXIVMINION.gLootOption == "All") then
        Settings.FFXIVMINION.gLootOption = "Any"
    end
	if (Settings.FFXIVMINION.gUseTelecast == nil) then
        Settings.FFXIVMINION.gUseTelecast = "1"
    end
	if (Settings.FFXIVMINION.gPerformanceLevel == nil) then
		Settings.FFXIVMINION.gPerformanceLevel = "Normal"
	end
	if (gBotMode == GetString("dutyMode")) then
		ffxiv_task_duty.UpdateProfiles()
	end

	local winName = GetString("dutyMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].botMode,"gBotMode",group,"None")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].profile,"gProfile",group,"None")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].skillProfile,"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
    GUI_NewCheckbox(winName,strings[gCurrentLanguage].botEnabled,"gBotRunning",group)
	GUI_NewComboBox(winName,"Performance","gPerformanceLevel",group,"Extreme,Fast,Normal,Slow")
	local group = GetString("settings")
    GUI_NewComboBox(winName,"Loot Option",			"gLootOption",				group,"Any,Need,Greed,Pass")
	GUI_NewCheckbox(winName,"Use Telecast",			"gUseTelecast",group)
	GUI_NewField(winName,strings[gCurrentLanguage].resetDutyTimer,"gResetDutyTimer",group)
	
	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gLootOption = Settings.FFXIVMINION.gLootOption
	gUseTelecast = Settings.FFXIVMINION.gUseTelecast
	gResetDutyTimer = Settings.FFXIVMINION.gResetDutyTimer
	gPerformanceLevel = Settings.FFXIVMINION.gPerformanceLevel
end

function ffxiv_task_duty.UpdateProfiles()
    local profiles = "None"
    local found = "None"	
    local profilelist = dirlist(GetStartupPath()..[[\LuaMods\ffxivminion\DutyProfiles\]],".*info")
    if ( TableSize(profilelist) > 0) then			
        local i,profile = next ( profilelist)
        while i and profile do				
            profile = string.gsub(profile, ".info", "")
            profiles = profiles..","..profile
            if ( Settings.FFXIVMINION.gLastDutyProfile ~= nil and Settings.FFXIVMINION.gLastDutyProfile == profile ) then
                d("Last Profile found : "..profile)
                found = profile
            end
            i,profile = next ( profilelist,i)
        end		
    else
        d("No duty profiles found")
    end
    gProfile_listitems = profiles
    gProfile = found
	ffxiv_task_duty.LoadProfile(gProfile)
end

function ffxiv_task_duty.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
		if (	k == "gProfile" and gBotMode == GetString("dutyMode")) then
			ffxiv_task_duty.LoadProfile(v)
			SafeSetVar("gLastDutyProfile",v)
        elseif (k == "gResetDutyTimer" or
				k == "gLootOption" or
				k == "gUseTelecast" or
				k == "gPerformanceLevel")
        then
            SafeSetVar(tostring(k),v)
        end
    end
    GUI_RefreshWindow(GetString("dutyMode"))
end

function ffxiv_task_duty.LoadProfile(strName)
	ffxiv_task_duty.dutyInfo, e = persistence.load(ffxiv_task_duty.dutyPath..strName..".info")
	if (ValidTable(ffxiv_task_duty.dutyInfo)) then
		ffxiv_task_duty.mapID = ffxiv_task_duty.dutyInfo.MapID
		if (ffxiv_task_duty.dutyInfo.Independent) then
			ffxiv_task_duty.independentMode = true
		else
			ffxiv_task_duty.independentMode = false
		end
	else
		d("The profile ["..strName.."] is structured incorrectly or does not exist. MapID of -1 will be assumed.")
		ffxiv_task_duty.mapID = -1
		ffxiv_task_duty.independentMode = false
	end
	if (file_exists(ffxiv_task_duty.dutyPath..strName..".lua")) then
		d("loading "..ffxiv_task_duty.dutyPath..strName..".lua")
		persistence.load(ffxiv_task_duty.dutyPath..strName..".lua")
	end
	ffxiv_task_duty.dutyCleared = false
	ffxiv_task_duty.dutySet = false
end

function GetDutyLeaderPos()
	local pos = nil
	
	local leader = GetDutyLeader()
    if (leader) then
		if (leader.pos.x ~= -1000) then
			pos = leader.pos
			local leaderEntity = EntityList:Get(leader.id)
			if (leaderEntity) then
				pos = leaderEntity.pos
			end
		end
	end
	
	return pos
end

function IsDutyLeader()
	if (ffxiv_task_duty.independentMode) then
		return true
	end
	
	local leader = GetDutyLeader()
	if (leader) then
		return Player.name == leader.name
	end
	return false
end

function IsPartyLeader()
	local partyLeader = GetPartyLeader()
	if (partyLeader) then
		return partyLeader.name == Player.name
	end
	return false
end

function IsFullParty()
	local party = EntityList.myparty
	if (ValidTable(party)) then
		if (TableSize(party) == 4 or TableSize(party) == 8) then
			for i,member in pairs(party) do
				if (member.mapid == 0) then
					return false
				end
			end
			return true
		end
	end
	
	return false
end

function OnDutyMap()
	return (Player.localmapid == ffxiv_task_duty.mapID)
end

function PartyInCombat()
	local party = EntityList.myparty
	if (ValidTable(party)) then
		for i, member in pairs(party) do
			if member.incombat then 
				return true 
			end
			
			local el = EntityList("alive,attackable,targeting="..tostring(member.id))
			if (ValidTable(el)) then
				return true
			end
		end
	end
	
	return false
end

function DutyLeaderLeft()
	if (IsDutyLeader()) then
		return false
	end
	
	local party = EntityList.myparty
	if (party and TableSize(party) > 1 ) then
		local leader = GetDutyLeader()
		if (leader) then
			for i, member in pairs(party) do
				if member.name == leader.name then
					return false
				end
			end
		end
    end

	return true
end

function GetDutyLeader()
	if (ffxiv_task_duty.leader == "") then
		if c_changeleader:evaluate() then e_changeleader:execute() end
	end
	
	local party = EntityList.myparty
	if (ValidTable(party)) then
		if (ffxiv_task_duty.leader ~= "") then
			for i, member in pairs(party) do
				if (member.name == ffxiv_task_duty.leader) then
					return member
				end
			end
		end
	end  
	
	return nil
end

c_deadduty = inheritsFrom( ml_cause )
e_deadduty = inheritsFrom( ml_effect )
c_deadduty.leader = {}
e_deadduty.justRevived = false
e_deadduty.originalPos = {}
function c_deadduty:evaluate()
	local leader = GetDutyLeader()
	if (leader) then
		c_deadduty.leader = leader
	end
	
    if (not Player.alive and OnDutyMap()) then --FFXIV.REVIVESTATE.DEAD & REVIVING
        ffxiv_task_duty.preventFail = Now() + 10000
		return true
    end 
	
	if (e_deadduty.justRevived) then
		ffxiv_task_duty.preventFail = Now() + 3000
		return true
	end

    return false
end
function e_deadduty:execute()
    local leader = c_deadduty.leader
	
	if (not Player.alive) then
		-- try raise first
		if(PressYesNo(true)) then
			e_deadduty.originalPos = shallowcopy(Player.pos)
			e_deadduty.justRevived = true
			ml_task_hub:ThisTask():SetDelay(1000)
		end
		-- press ok
		if(PressOK()) then
			e_deadduty.originalPos = shallowcopy(Player.pos)
			e_deadduty.justRevived = true
			ml_task_hub:ThisTask():SetDelay(1000)
		end
	end
	
	if (e_deadduty.justRevived and not IsLoading() and Player.alive) then
		if (gTeleport == "1") then
			local ppos = shallowcopy(Player.pos)
			local opos = e_deadduty.originalPos
			local dist = Distance3D(ppos.x,ppos.y,ppos.z,opos.x,opos.y,opos.z)
			--d("dead, stay close")
			if (dist > 3) then
				GameHacks:TeleportToXYZ(opos.x, opos.y, opos.z)
				Player:SetFacingSynced(Player.pos.h)
			else
				e_deadduty.originalPos = {}
				e_deadduty.justRevived = false
			end
		end
	end
	ml_task_hub:ThisTask().preserveSubtasks = true
end

ffxiv_task_duty_res = inheritsFrom(ml_task)
function ffxiv_task_duty_res.Create()
    local newinst = inheritsFrom(ffxiv_task_duty_res)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetopos members
    newinst.name = "LT_DUTY_RES"
    newinst.pos = 0
	newinst.repositioned = false
    
    return newinst
end

function ffxiv_task_duty_res:Init()	
    self:AddTaskCheckCEs()
end

function ffxiv_task_duty_res:task_complete_eval()
	if (IsLoading() or ml_mesh_mgr.loadingMesh or Player.revivestate == 3 or Player.revivestate == 1 ) then
		return false
	end
	
	local pos = self.pos
	if (not Player.alive and ControlVisible("SelectYesno")) then
		if (PressYesNo(true)) then
			return false
		end
		if (PressOK()) then
			return false
		end 
	end
	
	if (Player.alive and not self.repositioned) then
		GameHacks:TeleportToXYZ(pos.x, pos.y, pos.z)
		Player:SetFacingSynced(pos.h)
	end
	
	if (Player.alive and self.repositioned) then
		return true
	end
	
    return false
end

function ffxiv_task_duty_res:task_complete_execute()
    self.completed = true
end

RegisterEventHandler("GUI.Update",ffxiv_task_duty.GUIVarUpdate)
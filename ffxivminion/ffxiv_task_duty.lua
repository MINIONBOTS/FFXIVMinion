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
ffxiv_task_duty.leavingDuty = false
ffxiv_task_duty.completionCount = 0
ffxiv_task_duty.tempvars = {}
ffxiv_task_duty.category = -1
ffxiv_task_duty.mapID = -1

ffxiv_task_duty.performanceLevels = {
	["Extreme"] = 2;
	["Fast"] = 4;
	["Normal"] = 6;
	["Slow"] = 8;
}
ffxiv_task_duty.dutyRefreshed = false

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
	newinst.leaderSeen = false
	newinst.joinTimer = 0
	newinst.leaveTimer = 0
	newinst.resets = {}
	newinst.suppressFollowTimer = 0
	newinst.suppressTeleport = false
	newinst.state = ""
	newinst.pos = {}
	newinst.refreshed = false
	
	ffxiv_task_duty.leader = ""
    ffxiv_task_duty.leavingDuty = false
	ffxiv_task_duty.completionCount = 0
	
    return newinst
end

c_followleaderduty = inheritsFrom( ml_cause )
e_followleaderduty = inheritsFrom( ml_effect )
c_followleaderduty.rrange = 8
c_followleaderduty.leader = nil
c_followleaderduty.leaderpos = nil
function c_followleaderduty:evaluate()
    if (IsDutyLeader() or not InInstance() or IsLoading() or ml_task_hub:CurrentTask().suppressFollow) then
        return false
    end
	
	local leader = GetDutyLeader()
	local leaderPos = GetDutyLeaderPos()
	if (ValidTable(leaderPos) and ValidTable(leader)) then
		local myPos = Player.pos	
		
		local distance = Distance3D(myPos.x, myPos.y, myPos.z, leaderPos.x, leaderPos.y, leaderPos.z)
		if (gTeleport == "1") then
			if (distance > 2) then	
				c_followleaderduty.leaderpos = leaderPos
				c_followleaderduty.leader = leader
				return true
			end
		else			
			local leaderEntity = EntityList:Get(leader.id)
			if ((ml_task_hub:CurrentTask().name == "LT_DUTY" and distance > 15) or distance > 25 or (leaderEntity and not leaderEntity.targetable)) then	
				c_followleaderduty.leaderpos = leaderPos
				c_followleaderduty.leader = leader
				return true
			end		
		end
	end
	
    return false
end
function e_followleaderduty:execute()
    if ( c_followleaderduty.leader ~= nil) then
		local leader = c_followleaderduty.leader
        if ( leader.onmesh and Player.onmesh and gTeleport == "0") then
			if (leader.onmesh and Player.onmesh) then
				local lpos = c_followleaderduty.leader.pos
				local myPos = Player.pos
				local distance = Distance2D(myPos.x, myPos.z, lpos.x, lpos.z)
				
				ml_debug( "Moving to Leader: "..tostring(Player:MoveTo(tonumber(lpos.x),tonumber(lpos.y),tonumber(lpos.z),math.random(5,10))))
				if ( not Player:IsMoving()) then
					if ( ml_global_information.AttackRange < 5 ) then
						c_followleaderduty.rrange = math.random(4,6)
					else
						c_followleaderduty.rrange = math.random(4,6)
					end
				end
			else
				if ( not Player:IsMoving() ) then
					FollowResult = Player:FollowTarget(leader.id)
					ml_debug( "Following Leader: "..tostring(FollowResult))
				end
			end
        else
			local lpos = c_followleaderduty.leaderpos
            local myPos = Player.pos
			if (gTeleport == "1") then
				Player:Stop()
				d("Teleporting in order to follow leader. Current MapID:"..tostring(Player.localmapid))
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
	if (IsDutyLeader() or not InInstance() or IsLoading() or ml_task_hub:CurrentTask().suppressAssist or ActionList:IsCasting()) then
        return false
    end
    
    local leader = GetDutyLeader()
    if (leader) then
		local leaderEntity = EntityList:Get(leader.id)
		if (leaderEntity) then
			local leadtarget = leaderEntity.targetid
			if ((ml_task_hub:CurrentTask().name == "LT_SM_KILLTARGET" or ml_task_hub:CurrentTask().name == "GRIND_COMBAT") and 
				ml_task_hub:CurrentTask().targetid == leadtarget) then
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
		if (entity) then			
			if (gTeleport == "1") then
				SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
				local newTask = ffxiv_task_skillmgrAttack.Create()
				newTask.targetid = entity.id
				local pos = {x = Player.pos.x, y = Player.pos.y, z = Player.pos.z, h = Player.pos.h}
				newTask.safePos = pos
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			else  
				local newTask = ffxiv_task_grindCombat.Create()
				newTask.targetid = entity.id
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		end
    else
        ml_debug("Ohboy, something went really wrong : e_assistleaderduty")
    end
end

c_joinduty = inheritsFrom( ml_cause )
e_joinduty = inheritsFrom( ml_effect )
function c_joinduty:evaluate()	
	if (not IsLoading() and not Player.incombat and IsPartyLeader() and NotQueued()) then			
		if (Now() > ml_task_hub:ThisTask().joinTimer ) then
			return true
		end
	end
	
	return false
end
function e_joinduty:execute()
	if (ml_task_hub:ThisTask().state == "DUTY_EXIT" or ml_task_hub:ThisTask().state == "") then
		ml_task_hub:ThisTask().state = "DUTY_NEW"
	end
	
	if (not ControlVisible("ContentsFinder")) then
		SendTextCommand("/dutyfinder")
		ml_task_hub:ThisTask().joinTimer = Now() + (150 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
	else
		if (ControlVisible("ContentsFinder") and Duty:SelectFilter(ffxiv_task_duty.category)) then
			if (IsFullParty() or gDutySoloQueue == "1") then
				if (not ffxiv_task_duty.dutySet and not ffxiv_task_duty.dutyCleared) then
					Duty:ClearDutySelection()
					ffxiv_task_duty.dutyCleared = true
					ml_task_hub:ThisTask().joinTimer = Now() + (500 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
				elseif (not ffxiv_task_duty.dutySet and ffxiv_task_duty.dutyCleared) then
					local duty = GetDutyFromID(ffxiv_task_duty.mapID)
					if (duty) then
						Duty:SelectDuty(duty.DutyListIndex)
						ffxiv_task_duty.dutySet = true
						ml_task_hub:ThisTask().joinTimer = Now() + (150 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
					end
				elseif (ffxiv_task_duty.dutySet and ffxiv_task_duty.dutyCleared) then
					ml_task_hub:ThisTask().joinTimer = Now() + (5000 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
					PressDutyJoin()
					ffxiv_task_duty.dutyCleared = false
					ffxiv_task_duty.dutySet = false
				end
			end
		end
	end
end

c_leaveduty = inheritsFrom( ml_cause )
e_leaveduty = inheritsFrom( ml_effect )
function c_leaveduty:evaluate()
	if (InInstance() and not PartyInCombat() and not Inventory:HasLoot() and Now() > ml_task_hub:ThisTask().leaveTimer) then
		if ((DutyLeaderLeft() and ml_task_hub:CurrentTask().leaderSeen) or
			Quest:IsQuestRewardDialogOpen() or
			(IsDutyLeader() and (ml_task_hub:ThisTask().state == "DUTY_EXIT"))) 
		then
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
			ffxiv_task_duty.leavingDuty = true
			ml_task_hub:ThisTask().leaveTimer = Now() + (300 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
		end
	end
end

c_stopduty = inheritsFrom( ml_cause )
e_stopduty = inheritsFrom( ml_effect )
function c_stopduty:evaluate()
	if (not IsLoading() and not Player.incombat and NotQueued()) then
		if (ffxiv_task_duty.leavingDuty) then
			return true
		end
	end
	
	return false
end
function e_stopduty:execute()
	local completeCount = tonumber(gDutyCompleteCount) or 0
	completeCount = completeCount + 1
	gDutyCompleteCount = completeCount
	
	local stopCount = tonumber(gDutyStopCount) or 0
	if (stopCount > 0 and completeCount >= stopCount) then
		d("Bot stopped because enough completions have happened.")
		ml_task_hub.ToggleRun()
	end
	ffxiv_task_duty.leavingDuty = false
end

c_changeleader = inheritsFrom( ml_cause )
e_changeleader = inheritsFrom( ml_effect )
e_changeleader.name = ""
function c_changeleader:evaluate()
	if (gDutySoloQueue == "1") then
		if (ffxiv_task_duty.leader ~= Player.name) then
			e_changeleader.name = Player.name
			return true
		else
			return false
		end
	end
	
	if (not IsFullParty()) then
		return false
	end
	
	if (InInstance()) then
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
		if (not InInstance()) then
			ml_task_hub:ThisTask().state = ""
		elseif (InInstance()) then
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

c_dutyinstancecheck = inheritsFrom( ml_cause )
e_dutyinstancecheck = inheritsFrom( ml_effect )
function c_dutyinstancecheck:evaluate()
    if ((not InInstance() or IsLoading()) and ml_task_hub:CurrentTask().name ~= "LT_DUTY") then
		return true
    end	
	
    return false
end
function e_dutyinstancecheck:execute()     
	ml_debug("Ending all subtasks to prevent accidental teleports.")
end

c_leaderseencheck = inheritsFrom( ml_cause )
e_leaderseencheck = inheritsFrom( ml_effect )
function c_leaderseencheck:evaluate()
    if (InInstance() and not IsDutyLeader() and not PartyInCombat() and not Inventory:HasLoot()) then
		if (not ml_task_hub:CurrentTask().leaderSeen) then
			local party = EntityList.myparty
			if (party) then
				local leader = GetDutyLeader()
				if (leader) then
					for i, member in pairs(party) do
						if member.name == leader.name then
							return true
						end
					end
				end
			end
		end
    end	
	
    return false
end
function e_leaderseencheck:execute()     
	ml_task_hub:CurrentTask().leaderSeen = true
end

c_dutydatacheck = inheritsFrom( ml_cause )
e_dutydatacheck = inheritsFrom( ml_effect )
e_dutydatacheck.timer = 0
function c_dutydatacheck:evaluate()
    if (not IsLoading() and not Player.incombat and NotQueued() and not ml_task_hub:CurrentTask().refreshed) then
		return true
    end	
	
    return false
end
function e_dutydatacheck:execute()     
	if (Now() < e_dutydatacheck.timer) then
		return
	end
	
	if (not ControlVisible("ContentsFinder")) then
		SendTextCommand("/dutyfinder")
		e_dutydatacheck.timer = Now() + 2000
	else
		if (Duty:SelectFilter(ffxiv_task_duty.category)) then
			d("Select filter succeeded, setting task to refreshed.")
			ml_task_hub:CurrentTask().refreshed = true
			SendTextCommand("/dutyfinder")
			e_dutydatacheck.timer = Now() + 1000
		else
			d("Select filter failed, reattempting in 2 seconds.")
			e_dutydatacheck.timer = Now() + 2000
		end
	end
end

function ffxiv_task_duty:ProcessOverWatch()
	if (IsLoading() or ml_mesh_mgr.meshLoading) then
		return false
	end
	
   if (TableSize(self.overwatch_elements) > 0) then
		ml_debug(self.name.."->ProcessOverWatch()")
		--local process = "overwatch"
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(self.overwatch_elements)
		
		ml_cne_hub.queue_to_execute()
		--return ml_cne_hub.execute(self,process)
		return ml_cne_hub.execute()
	end
end

c_dutyidle = inheritsFrom( ml_cause )
e_dutyidle = inheritsFrom( ml_effect )
function c_dutyidle:evaluate()
	return ((not InInstance() and (
	ml_global_information.idlePulseCount > 4000 or
	ml_task_hub:ThisTask().state == "DUTY_NEXTENCOUNTER" or 
	ml_task_hub:ThisTask().state == "DUTY_DOENCOUNTER")) or
	(IsPartyLeader() and ml_task_hub:ThisTask().state == "DUTY_ENTER" and NotQueued()))
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
	
	if (IsDutyLeader() and InInstance() and not Inventory:HasLoot()) then
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
		elseif (self.state == "DUTY_NEXTENCOUNTER" and not self.encounterCompleted and OnDutyMap()) then
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
						local msg = "Teleporting to reach next encounter. Current MapID:"..tostring(Player.localmapid).."\n"
						msg = msg.."IsDutyLeader ["..tostring(IsDutyLeader()).."], DutyQueueStatus ["..tostring(Duty:GetQueueStatus()).."]"
						d(msg)
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
    --init ProcessOverWatch() cnes			
	local ke_dutyIdle = ml_element:create( "DutyIdle", c_dutyidle, e_dutyidle, 40 )
    self:add(ke_dutyIdle, self.overwatch_elements)
	
	local ke_instanceCheck = ml_element:create( "InstanceCheck", c_dutyinstancecheck, e_dutyinstancecheck, 38 )
    self:add(ke_instanceCheck, self.overwatch_elements)
	
	local ke_deadDuty = ml_element:create( "Dead", c_deadduty, e_deadduty, 35 )
    self:add( ke_deadDuty, self.overwatch_elements)	
	
	local ke_followleaderduty = ml_element:create( "FollowLeader", c_followleaderduty, e_followleaderduty, 25 )--minion only
    self:add( ke_followleaderduty, self.overwatch_elements)
	
	local ke_assistleaderduty = ml_element:create( "AssistLeader", c_assistleaderduty, e_assistleaderduty, 20 )--minion only
    self:add( ke_assistleaderduty, self.overwatch_elements)
	
	local ke_pressConfirm = ml_element:create( "PressConfirm", c_pressconfirm, e_pressconfirm, 15 )
    self:add(ke_pressConfirm, self.overwatch_elements)	
	
	 --init Process() cnes
	local ke_dutyDataCheck = ml_element:create( "DutyDataCheck", c_dutydatacheck, e_dutydatacheck, 40 )
    self:add(ke_dutyDataCheck, self.process_elements)
	
	local ke_lootcheck = ml_element:create( "Loot", c_lootcheck, e_lootcheck, 19 )--minion only
    self:add( ke_lootcheck, self.process_elements)
	
	local ke_changeLeader = ml_element:create( "ChangeLeader", c_changeleader, e_changeleader, 17 )
    self:add(ke_changeLeader, self.process_elements)
	
	local ke_stopDuty = ml_element:create( "StopDuty", c_stopduty, e_stopduty, 16 )
    self:add(ke_stopDuty, self.process_elements)
	
	local ke_joinDuty = ml_element:create( "JoinDuty", c_joinduty, e_joinduty, 15 )
    self:add(ke_joinDuty, self.process_elements) 
	
	local ke_leaderSeen = ml_element:create( "LeaderSeen", c_leaderseencheck, e_leaderseencheck, 13 )
    self:add(ke_leaderSeen, self.process_elements)

    local ke_leaveDuty = ml_element:create( "LeaveDuty", c_leaveduty, e_leaveduty, 10 )
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
	if (Settings.FFXIVMINION.gLootOption == nil or Settings.FFXIVMINION.gLootOption == "All") then
        Settings.FFXIVMINION.gLootOption = GetString("need")
    end
	if (Settings.FFXIVMINION.gDutyStopCount == nil) then
        Settings.FFXIVMINION.gDutyStopCount = 0
    end
	if (Settings.FFXIVMINION.gUseTelecast == nil) then
        Settings.FFXIVMINION.gUseTelecast = "1"
    end
	if (Settings.FFXIVMINION.gPerformanceLevel == nil) then
		Settings.FFXIVMINION.gPerformanceLevel = GetString("normal")
	end
	if (gBotMode == GetString("dutyMode")) then
		ffxiv_task_duty.UpdateProfiles()
	end

	local winName = GetString("dutyMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("profile"),"gProfile",group,"None")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
    GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
	GUI_NewField(winName,"Complete Count","gDutyCompleteCount",group)
	GUI_NewComboBox(winName,GetString("performance"),"gPerformanceLevel",group,GetStringList("extreme,fast,normal,slow",","))
	
	local group = GetString("settings")
    GUI_NewComboBox(winName,GetString("loot"),"gLootOption",group,GetStringList("need,greed,pass",","))
	GUI_NewCheckbox(winName,GetString("telecast"),"gUseTelecast",group)
	GUI_NewNumeric(winName,"Stop Count","gDutyStopCount",group,"0","100")
	GUI_NewCheckbox(winName,"Solo Queue","gDutySoloQueue",group)

	GUI_UnFoldGroup(winName,GetString("status"))
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gLootOption = ffxivminion.SafeComboBox(Settings.FFXIVMINION.gLootOption,gLootOption_listitems,GetString("need"))
	gDutyStopCount = Settings.FFXIVMINION.gDutyStopCount
	gUseTelecast = Settings.FFXIVMINION.gUseTelecast
	gPerformanceLevel = ffxivminion.SafeComboBox(Settings.FFXIVMINION.gPerformanceLevel,gPerformanceLevel_listitems,GetString("normal"))
	gDutySoloQueue = "0"
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
		elseif (k == "gLootOption" or
				k == "gUseTelecast" or
				k == "gPerformanceLevel")
        then
            SafeSetVar(tostring(k),v)
		elseif (k == "gDutySoloQueue") then
			if (v == "1") then
				local message = {}
				message[1] = "You must have the in-game option for undersized party enabled."
				message[2] = "Failure to do so could result in unwanted teleport hacking."
				ffxiv_dialog_manager.IssueNotice("FFXIV_Duty_SoloQueueNotify", message)
			end
			SafeSetVar(tostring(k),v)
        end
    end
    GUI_RefreshWindow(GetString("dutyMode"))
end

function ffxiv_task_duty.LoadProfile(strName)
	ffxiv_task_duty.dutyInfo,e = persistence.load(ffxiv_task_duty.dutyPath..strName..".info")
	if (ValidTable(ffxiv_task_duty.dutyInfo)) then
		ffxiv_task_duty.mapID = ffxiv_task_duty.dutyInfo.MapID
		ffxiv_task_duty.category = ffxiv_task_duty.dutyInfo.Category
		
		local categoryCheck = IsValidCategory(ffxiv_task_duty.category)
		if (categoryCheck) then
			if (ffxiv_task_duty.dutyInfo.Independent) then
				ffxiv_task_duty.independentMode = true
			else
				ffxiv_task_duty.independentMode = false
			end
		else
			ffxiv_task_duty.mapID = -1
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
	
    if (not Player.alive and InInstance()) then --FFXIV.REVIVESTATE.DEAD & REVIVING
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
		--d("PressYesNo(true):"..tostring(PressYesNo(true)))
		if(PressYesNo(true)) then
			e_deadduty.originalPos = shallowcopy(Player.pos)
			e_deadduty.justRevived = true
			ml_task_hub:ThisTask():SetDelay(1000)
		end
		
		-- press ok
		--d("PressOK():"..tostring(PressOK()))
		if(PressOK()) then
			e_deadduty.originalPos = shallowcopy(Player.pos)
			e_deadduty.justRevived = true
			ml_task_hub:ThisTask():SetDelay(1000)
		end
		
		-- if no res options available, teleport to a healer in the party
		--[[
		if (gTeleport == "1") then
			d("teleport option is on and player is dead.")
			local leader = GetDutyLeader()
			local leaderPos = GetDutyLeaderPos()
			if (ValidTable(leaderPos) and ValidTable(leader)) then
				if (leader.name ~= Player.name) then
					d("leader and leaderpos is valid.")
					local myPos = Player.pos	
					
					local distance = Distance3D(myPos.x, myPos.y, myPos.z, leaderPos.x, leaderPos.y, leaderPos.z)
					if (distance > 5) then
						d("teleporting to the leader.")
						GameHacks:TeleportToXYZ(leaderPos.x, leaderPos.y, leaderPos.z)
						Player:SetFacingSynced(myPos.h)
						return
					end
				end
			end
		end
		--]]
	end
	
	if (e_deadduty.justRevived and not IsLoading() and Player.alive) then
		if (gTeleport == "1") then
			local ppos = shallowcopy(Player.pos)
			local opos = e_deadduty.originalPos
			local dist = Distance3D(ppos.x,ppos.y,ppos.z,opos.x,opos.y,opos.z)
			--d("dead, stay close")
			if (dist > 3 and InInstance()) then
				d("Teleporting back to original location due to death. Current MapID:"..tostring(Player.localmapid))
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

RegisterEventHandler("GUI.Update",ffxiv_task_duty.GUIVarUpdate)
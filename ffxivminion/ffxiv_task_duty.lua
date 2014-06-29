ffxiv_task_duty = inheritsFrom(ml_task)
ffxiv_task_duty.name = "LT_DUTY"
ffxiv_task_duty.dutyInfo = {}
ffxiv_task_duty.dutyPath = GetStartupPath()..[[\LuaMods\ffxivminion\DutyProfiles\]]
ffxiv_task_duty.updateTicks = 0
ffxiv_task_duty.respawnTime = 0
ffxiv_task_duty.leader = ""
ffxiv_task_duty.leaderSet = false
ffxiv_task_duty.dutySet = false
ffxiv_task_duty.dutyCleared = false
ffxiv_task_duty.joinAttempts = 0

if(Settings.FFXIVMINION.gDutyMapID == nil) then
	Settings.FFXIVMINION.gDutyMapID = 0
end
ffxiv_task_duty.mapID = Settings.FFXIVMINION.gDutyMapID

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
	if (Player.localmapid == ffxiv_task_duty.mapID) then
		newinst.state = "DUTY_ENTER"
	else
		newinst.state = "DUTY_NEW"
	end
	newinst.pos = {}
    
    return newinst
end

c_followleaderduty = inheritsFrom( ml_cause )
e_followleaderduty = inheritsFrom( ml_effect )
c_followleaderduty.rrange = math.random(5,15)
e_followleaderduty.leader = nil
function c_followleaderduty:evaluate()
    if (IsDutyLeader() or Player.localmapid ~= ffxiv_task_duty.mapID or ml_task_hub:CurrentTask().suppressFollow) then
        return false
    end
    
    local leader = GetDutyLeader()
    if ( leader ~= nil ) then
		c_followleaderduty.leaderpos = leader.pos
		if ( c_followleaderduty.leaderpos.x ~= -1000 ) then 			
			local myPos = Player.pos				
			local distance = Distance3D(myPos.x, myPos.y, myPos.z, c_followleaderduty.leaderpos.x, c_followleaderduty.leaderpos.y, c_followleaderduty.leaderpos.z)
			if ((distance > c_followleaderduty.rrange and leader.onmesh) or (distance > c_followleaderduty.rrange and distance < 30 and not leader.onmesh) or
				(distance > 1 and gTeleport == "1")) 
			then				
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
            local lpos = c_followleaderduty.leader.pos
            local myPos = Player.pos
            local distance = Distance2D(myPos.x, myPos.z, lpos.x, lpos.z)
            
            ml_debug( "Moving to Leader: "..tostring(Player:MoveTo(tonumber(lpos.x),tonumber(lpos.y),tonumber(lpos.z),tonumber(c_followleader.rrange))))
            if ( not Player:IsMoving()) then
                if ( ml_global_information.AttackRange < 5 ) then
					c_followleaderduty.rrange = math.random(4,8)
                else
					c_followleaderduty.rrange = math.random(8,20)
                end
            end
        else
			local lpos = leader.pos
            local myPos = Player.pos
			if (gTeleport == "1") then
				Player:Stop()
				GameHacks:TeleportToXYZ(lpos.x+1, lpos.y, lpos.z)
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
    if (IsDutyLeader() or ml_task_hub:CurrentTask().suppressAssist or ml_task_hub:CurrentTask().name == "LT_SM_KILLTARGET"
		or Player.localmapid ~= ffxiv_task_duty.mapID) then
        return false
    end
    
    local leader = GetDutyLeader()
    if (leader ~= nil) then
        local entity = EntityList:Get(leader.id)
        if ( entity ~= nil and entity ~= 0 ) then
            local leadtarget = entity.targetid
            if ( leadtarget ~= nil and leadtarget ~= 0 ) then
                local target = EntityList:Get(leadtarget)
                if ( ValidTable(target) and target.alive and (target.onmesh or InCombatRange(target.id))) then
					c_assistleaderduty.targetid = target.id
					return true
                end
            end
		else
			Player:SetFacingSynced(leader.pos.x, leader.pos.y, leader.pos.z)
		end
    end
    
    return false
end
function e_assistleaderduty:execute()
    if ( c_assistleaderduty.targetid ) then
		local entity = EntityList:Get(c_assistleaderduty.targetid)
		Player:SetFacingSynced(entity.pos.x,entity.pos.y,entity.pos.z)
		if (ml_task_hub:CurrentTask().name == "LT_SM_KILLTARGET") then
			ml_task_hub:CurrentTask():Terminate()
		end
		
        if (gTeleport == "1") then
            local newTask = ffxiv_task_skillmgrAttack.Create()
            newTask.targetid = c_assistleaderduty.targetid
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
	if (not Quest:IsLoading() and
		Player.localmapid ~= ffxiv_task_duty.mapID and
        IsDutyLeader() and
		(ml_global_information.Now > ml_task_hub:CurrentTask().joinTimer or ml_task_hub:CurrentTask().joinTimer == 0) and
		(TableSize(EntityList.myparty) == 4 or
		TableSize(EntityList.myparty) == 8)) 
	then
		return true
	end

	return false
end
function e_joinduty:execute()
	if (not ControlVisible("ContentsFinder")) then
		ActionList:Cast(33,0,10)
	elseif (ControlVisible("ContentsFinder") and not ffxiv_task_duty.dutySet and not ffxiv_task_duty.dutyCleared) then
		Duty:ClearDutySelection()
		ffxiv_task_duty.dutyCleared = true
		ml_task_hub:CurrentTask().timer = Now() + 1500 + (1500 * ml_task_hub:CurrentTask().joinAttempts)
	elseif (ControlVisible("ContentsFinder") and not ffxiv_task_duty.dutySet and ffxiv_task_duty.dutyCleared and Now() > ml_task_hub:CurrentTask().timer) then
		local duty = GetDutyFromID(ffxiv_task_duty.mapID)
		if (duty) then
			Duty:SelectDuty(duty.DutyListIndex)
			ffxiv_task_duty.dutySet = true
			ml_task_hub:CurrentTask().timer = Now() + 1500 + (1500 * ml_task_hub:CurrentTask().joinAttempts)
		end
	elseif (ControlVisible("ContentsFinder") and ffxiv_task_duty.dutySet and Now() > ml_task_hub:CurrentTask().timer) then
        ml_task_hub:CurrentTask().joinTimer = ml_global_information.Now + (tonumber(gResetDutyTimer) * 1000)
		ml_task_hub:CurrentTask().joinAttempts = ml_task_hub:CurrentTask().joinAttempts + 1
		PressDutyJoin()
		ffxiv_task_duty.dutyCleared = false
		ffxiv_task_duty.dutySet = false
	end
end
			
c_leaveduty = inheritsFrom( ml_cause )
e_leaveduty = inheritsFrom( ml_effect )
function c_leaveduty:evaluate()	
	return (	Player.localmapid == ffxiv_task_duty.mapID and not Player.incombat and
				(DutyLeaderLeft() or  
				(IsDutyLeader()  and ml_task_hub:CurrentTask().state == "DUTY_EXIT") or 
				(TableSize(EntityList.myparty) ~= 4 and TableSize(EntityList.myparty) ~= 8)))
end
function e_leaveduty:execute()
	if not ControlVisible("ContentsFinder") then
		Player:Stop()
        ActionList:Cast(33,0,10)
    elseif ControlVisible("ContentsFinder") and not ControlVisible("SelectYesno") then
        PressDutyJoin()
	elseif ControlVisible("ContentsFinder") and ControlVisible("SelectYesno") then
        PressYesNo(true)
		ml_task_hub:CurrentTask().state = "DUTY_NEW" 
		ml_task_hub:CurrentTask().joinTimer = 0
		ml_task_hub:CurrentTask().joinAttempts = 0
    end
end

c_changeleader = inheritsFrom( ml_cause )
e_changeleader = inheritsFrom( ml_effect )
function c_changeleader:evaluate()
	if ((ml_task_hub:CurrentTask().state == "DUTY_NEW" or ffxiv_task_duty.leader == "")
		and not Quest:IsLoading()) then
		local Plist = EntityList.myparty
		if (TableSize(Plist) > 0 ) then
			local i,member = next (Plist)
			while (i~=nil and member~=nil ) do
				if ( member.isleader ) then
					if (member.name ~= ffxiv_task_duty.leader and member.name ~= "") then
						e_changeleader.name = member.name
						return true
					else
						return false
					end
				end
				i,member = next (Plist,i)
			end
		end
	end
	
	return false
end
function e_changeleader:execute()
	ffxiv_task_duty.leader = e_changeleader.name
	if (IsDutyLeader()) then
		ffxiv_task_duty.leaderSet = true
		ffxiv_task_duty.dutySet = false
		ffxiv_task_duty.dutyCleared = false
	end
end

c_lootcheck = inheritsFrom( ml_cause )
e_lootcheck = inheritsFrom( ml_effect )
function c_lootcheck:evaluate()
    if (IsDutyLeader() or Inventory:HasLoot()==false) then
        return false
    end	
	
    return true
end
function e_lootcheck:execute()     
	local newTask = ffxiv_task_loot.Create()
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end
	
function ffxiv_task_duty:Process()
	if ((IsDutyLeader() and ml_global_information.Now < ml_task_hub:CurrentTask().timer and not Player.incombat)
		or Quest:IsLoading()) then
		return false
	end
	
	local state = ml_task_hub:CurrentTask().state
	
	if (IsDutyLeader()) then
		if (state == "DUTY_ENTER" and OnDutyMap()) then
			local encounters = ffxiv_task_duty.dutyInfo["Encounters"]
			if (ValidTable(encounters)) then
				if ( ffxiv_task_duty.dutyInfo["EncounterIndex"] == 0 ) then
					ml_task_hub:CurrentTask().encounter = encounters[1]
					ffxiv_task_duty.dutyInfo["EncounterIndex"] = 1
					ml_task_hub:CurrentTask().encounterIndex = 1
					persistence.store(ffxiv_task_duty.dutyPath..".info",ffxiv_task_duty.dutyInfo)
				else
					ml_task_hub:CurrentTask().encounter = encounters[ffxiv_task_duty.dutyInfo["EncounterIndex"]]
					ml_task_hub:CurrentTask().encounterIndex = ffxiv_task_duty.dutyInfo["EncounterIndex"]
				end
				
				ml_task_hub:CurrentTask().state = "DUTY_NEXTENCOUNTER"
				ml_task_hub:CurrentTask().encounterCompleted = false
			end
		elseif (state == "DUTY_NEXTENCOUNTER" and not ml_task_hub:CurrentTask().encounterCompleted) then
			local pos = ml_task_hub:CurrentTask().encounter.startPos["General"]
			local myPos = Player.pos
			local posRadius = (ml_task_hub:CurrentTask().encounter.positionRadius ~= nil and ml_task_hub:CurrentTask().encounter.positionRadius or ml_task_hub:CurrentTask().encounter.radius)
			if (Distance2D(myPos.x, myPos.z, pos.x, pos.z) < posRadius or
				(gTeleport == "1" and Distance2D(myPos.x, myPos.z, pos.x, pos.z) < 3)) then
				ml_task_hub:CurrentTask().state = "DUTY_DOENCOUNTER"
				local encounterTask = findfunction(ml_task_hub:CurrentTask().encounter.taskFunction)()
				encounterTask.encounterData = ml_task_hub:CurrentTask().encounter
				ml_task_hub:CurrentTask():AddSubTask(encounterTask)
				ml_task_hub:CurrentTask().timer = ml_global_information.Now + 3000
				return false
			else
				local gotoPos = pos
				if ValidTable(gotoPos) then
					if (gTeleport == "1") then
						GameHacks:TeleportToXYZ(tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z))
						Player:SetFacingSynced(tonumber(gotoPos.h))
					else
						ml_debug( "Moving to ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")	
						Player:MoveTo( tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z),1.0, 
						ml_task_hub:CurrentTask().useFollowMovement or false,gRandomPaths=="1")
					end
				end
			end
		elseif (ml_task_hub:CurrentTask().state == "DUTY_DOENCOUNTER" and ml_task_hub:CurrentTask().encounterCompleted) then
			local encounters = ffxiv_task_duty.dutyInfo["Encounters"]
			ml_task_hub:CurrentTask().encounterIndex = ml_task_hub:CurrentTask().encounterIndex + 1
			local encounter = encounters[ml_task_hub:CurrentTask().encounterIndex]
			if (ValidTable(encounter)) then
				ml_task_hub:CurrentTask().state = "DUTY_NEXTENCOUNTER"
				ml_task_hub:CurrentTask().encounter = encounter
				ffxiv_task_duty.dutyInfo["EncounterIndex"] = ml_task_hub:CurrentTask().encounterIndex
				persistence.store(ffxiv_task_duty.dutyPath..".info",ffxiv_task_duty.dutyInfo )
				ml_task_hub:CurrentTask().encounterCompleted = false
			else
				if (IsDutyLeader()) then
					ffxiv_task_duty.dutyInfo["EncounterIndex"] = 0
					persistence.store(ffxiv_task_duty.dutyPath..".info",ffxiv_task_duty.dutyInfo )
					ml_task_hub:CurrentTask().state = "DUTY_EXIT"
				end
			end
		end
	end

	if (TableSize(ml_task_hub:CurrentTask().process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(ml_task_hub:CurrentTask().process_elements)
		if (ml_task_hub:CurrentTask():superClass() and TableSize(ml_task_hub:CurrentTask():superClass().process_elements) > 0) then
			ml_cne_hub.eval_elements(ml_task_hub:CurrentTask():superClass().process_elements)
		end
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		
		if state ~= ml_task_hub:CurrentTask().state then
			--d(state)
		end
		
		return false
	else
		ml_debug("no elements in process table")
	end
end

function ffxiv_task_duty:Init()
    --init Process() cnes
	local ke_deadDuty = ml_element:create( "Dead", c_deadduty, e_deadduty, 35 )
    self:add( ke_deadDuty, self.overwatch_elements)	
	
	local ke_followleaderduty = ml_element:create( "FollowLeader", c_followleaderduty, e_followleaderduty, 25 )--minion only
    self:add( ke_followleaderduty, self.overwatch_elements)
	
	local ke_assistleaderduty = ml_element:create( "AssistLeader", c_assistleaderduty, e_assistleaderduty, 20 )--minion only
    self:add( ke_assistleaderduty, self.overwatch_elements)
	
	local ke_lootcheck = ml_element:create( "Loot", c_lootcheck, e_lootcheck, 20 )--minion only
    self:add( ke_lootcheck, self.process_elements)
	
	local ke_changeLeader = ml_element:create( "ChangeLeader", c_changeleader, e_changeleader, 17 )
    self:add(ke_changeLeader, self.process_elements)
	
	local ke_joinDuty = ml_element:create( "JoinDuty", c_joinduty, e_joinduty, 15 )
    self:add(ke_joinDuty, self.process_elements) 

    local ke_leaveDuty = ml_element:create( "LeaveDuty", c_leaveduty, e_leaveduty, 15 )
    self:add(ke_leaveDuty, self.process_elements)
	
	local ke_pressConfirm = ml_element:create( "PressConfirm", c_pressconfirm, e_pressconfirm, 10 )
    self:add(ke_pressConfirm, self.process_elements)
	
    self:AddTaskCheckCEs()
end

-- UI settings
function ffxiv_task_duty.UIInit()
	GUI_NewField(GetString("advancedSettings"),strings[gCurrentLanguage].resetDutyTimer,"gResetDutyTimer",strings[gCurrentLanguage].dutyMode);

	if (Settings.FFXIVMINION.gLastDutyProfile == nil) then
        Settings.FFXIVMINION.gLastDutyProfile = ""
    end
	
	if (Settings.FFXIVMINION.gResetDutyTimer == nil) then
        Settings.FFXIVMINION.gResetDutyTimer = 60
    end
	
	if(gBotMode == GetString("dutyMode")) then
		ffxiv_task_duty.UpdateProfiles()
	end
    
    GUI_SizeWindow(ml_global_information.MainWindow.Name,178,357)
	
	gResetDutyTimer = Settings.FFXIVMINION.gResetDutyTimer
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
	ffxiv_task_duty.dutyInfo = persistence.load(ffxiv_task_duty.dutyPath..gProfile..".info")
	if (ValidTable(ffxiv_task_duty.dutyInfo)) then
		ffxiv_task_duty.mapID = ffxiv_task_duty.dutyInfo.MapID
	end
  if (file_exists(ffxiv_task_duty.dutyPath..gProfile..".lua")) then
    d("loading"..ffxiv_task_duty.dutyPath..gProfile..".lua")
    dofile(ffxiv_task_duty.dutyPath..gProfile..".lua")
  end
  ffxiv_task_duty.dutySet = false
end

function ffxiv_task_duty.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
		if (	k == "gProfile" and gBotMode == GetString("dutyMode")) then
			ffxiv_task_duty.dutyInfo = persistence.load(ffxiv_task_duty.dutyPath..v..".info")
			if (ValidTable(ffxiv_task_duty.dutyInfo)) then
				ffxiv_task_duty.mapID = ffxiv_task_duty.dutyInfo.MapID
			end
			d(loadfile(ffxiv_task_duty.dutyPath..v..".lua"))
			Settings.FFXIVMINION["gLastDutyProfile"] = v
			ffxiv_task_duty.dutySet = false
        elseif (k == "gResetDutyTimer")
        then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

function IsDutyLeader()
	return Player.name == ffxiv_task_duty.leader
end

function OnDutyMap()
	return (Player.localmapid == ffxiv_task_duty.mapID)
end

function DutyLeaderLeft()
	if (ffxiv_task_duty.leader == "" or IsDutyLeader() or not OnDutyMap()) then
		return false
	end
	
	local partymemberlist= EntityList.myparty
	if ( partymemberlist) then
		local i,entity = next(partymemberlist)
		while (i~=nil and entity ~=nil) do
			if (entity.name == ffxiv_task_duty.leader) then
				return false
			end
			i,entity  = next(partymemberlist,i)
		end
    end

	return true
end

function GetDutyLeader()	
	local partymemberlist= EntityList.myparty
        if ( partymemberlist) then
        local i,entity = next(partymemberlist)
        while (i~=nil and entity ~=nil) do 
			if (entity.name == ffxiv_task_duty.leader) then
				return entity
			end
            i,entity  = next(partymemberlist,i)
        end  
    end
	
	return nil
end

c_deadduty = inheritsFrom( ml_cause )
e_deadduty = inheritsFrom( ml_effect )
function c_deadduty:evaluate()
    if (Player.revivestate == 2 or Player.revivestate == 3) then --FFXIV.REVIVESTATE.DEAD & REVIVING
        return true
    end 
    return false
end
function e_deadduty:execute()
	ml_task_hub:ThisTask().state = "DUTY_NEXTENCOUNTER"
    local leader = GetDutyLeader()
	local lpos = leader.pos
	if (gTeleport == "1") then
		--d("dead, stay close")
		if (not IsDutyLeader()) then
			GameHacks:TeleportToXYZ(lpos.x+1, lpos.y, lpos.z)
		else
			GameHacks:TeleportToXYZ(lpos.x, lpos.y, lpos.z)
		end
	end
	
	local target = EntityList:Get(leadtarget)
	if (target~=nil) then
		Player:SetFacingSynced(target.pos.x, target.pos.y, target.pos.z)
	end

	-- try raise first
    if(PressYesNo(true)) then
		return
    end
	-- press ok
    if(PressOK()) then
		return
    end
end

RegisterEventHandler("GUI.Update",ffxiv_task_duty.GUIVarUpdate)

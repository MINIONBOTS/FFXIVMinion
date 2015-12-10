ffxiv_task_assist = inheritsFrom(ml_task)
ffxiv_task_assist.name = "LT_ASSIST"

function ffxiv_task_assist.Create()
    local newinst = inheritsFrom(ffxiv_task_assist)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_assist members
    newinst.name = "LT_ASSIST"
    newinst.targetid = 0
	newinst.movementDelay = 0
    
    return newinst
end

function ffxiv_task_assist:Init()
    --init Process() cnes
	local ke_pressConfirm = ml_element:create( "ConfirmDuty", c_pressconfirm, e_pressconfirm, 25 )
    self:add(ke_pressConfirm, self.process_elements)
	
	local ke_acceptQuest = ml_element:create( "AcceptQuest", c_acceptquest, e_acceptquest, 23 )
    self:add(ke_acceptQuest, self.process_elements)
	
	local ke_handoverQuest = ml_element:create( "HandoverQuestItem", c_handoverquest, e_handoverquest, 23 )
    self:add(ke_handoverQuest, self.process_elements)
	
	local ke_completeQuest = ml_element:create( "CompleteQuest", c_completequest, e_completequest, 23 )
    self:add(ke_completeQuest, self.process_elements)
	
	local ke_yesnoAssist = ml_element:create( "QuestYesNo", c_assistyesno, e_assistyesno, 23 )
    self:add(ke_yesnoAssist, self.process_elements)
	
	local ke_avoid = ml_element:create( "Avoid", c_avoid, e_avoid, 20)
	self:add(ke_avoid, self.process_elements)
	
	local ke_autoPotion = ml_element:create( "AutoPotion", c_autopotion, e_autopotion, 19)
	self:add(ke_autoPotion, self.process_elements)
	
	local ke_companion = ml_element:create( "Companion", c_companion, e_companion, 18 )
    self:add( ke_companion, self.process_elements)
	
	local ke_stance = ml_element:create( "Stance", c_stance, e_stance, 17 )
    self:add( ke_stance, self.process_elements)
  
    self:AddTaskCheckCEs()
	self:InitAddon()
end

function ffxiv_task_assist:InitAddon()
	--nothing
end

function ffxiv_task_assist:GetHealingTarget()
    local target = nil
    if ( gAssistMode == GetString("lowestHealth")) then	
        local target = GetBestHealTarget()		
    elseif ( gAssistMode == GetString("nearest") ) then	
        local target = GetClosestHealTarget()	
    end
    
    if ( target and target.hp.percent < SkillMgr.GetHealSpellHPLimit() ) then
        return target
    end
	
    return nil
end

function ffxiv_task_assist:GetAttackTarget()
	local maxDistance = (ml_global_information.AttackRange < 5 ) and 8 or ml_global_information.AttackRange
    local target = nil
    if ( gAssistMode == GetString("lowestHealth")) then	
        local el = EntityList("lowesthealth,alive,attackable,maxdistance="..tostring(maxDistance))
        if ( ValidTable(el) ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                target = e
            end
        end
    elseif ( gAssistMode == GetString("nearest") ) then	
        local el = EntityList("nearest,alive,attackable,maxdistance="..tostring(maxDistance))
        if ( ValidTable(el) ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                target = e
            end
        end	
	 elseif ( gAssistMode == GetString("tankAssist") ) then
		local party = EntityList("myparty")
		if (ValidTable(party)) then
			local tanks = {}
			for i,member in pairs(party) do
				if (IsTank(member.job) and member.id ~= Player.id) then
					table.insert(tanks,member)
				end
			end
			
			if (ValidTable(tanks)) then
				local closest = nil
				local closestDistance = 999
				for i,tank in pairs(tanks) do
					if (not closest or (closest and tank.distance < closestDistance)) then
						closest = tank
						closestDistance = tank.distance
					end
				end
				
				if (closest) then
					if (closest.targetid ~= 0) then
						local targeted = EntityList:Get(closest.targetid)
						if (targeted and targeted.attackable and targeted.alive) then
							target = targeted
						end
					end
				end
			end
		end
    end
    
    return target
end


function ffxiv_task_assist:Process()

	if (Player.alive) then
		local target = Player:GetTarget()
		
		if ( gAssistMode ~= GetString("none") ) then
			local newTarget = nil
			
			if ( gAssistPriority == GetString("healer") ) then
				newTarget = ffxiv_task_assist:GetHealingTarget()
				if ( newTarget == nil ) then
					newTarget = ffxiv_task_assist:GetAttackTarget()				
				end		

			elseif ( gAssistPriority == GetString("dps") ) then
				newTarget = ffxiv_task_assist:GetAttackTarget()
				if ( newTarget == nil ) then
					newTarget = ffxiv_task_assist:GetHealingTarget()				
				end			
			end
			
			if ( newTarget ~= nil and (not target or newTarget.id ~= target.id)) then
				target = newTarget
				Player:SetTarget(target.id)  
			end
		end
		
		local casted = false
		if ( target and (target.chartype ~= 0 and target.chartype ~= 7) and (target.distance <= 35 or gAssistFollowTarget == "1")) then
			if (gStartCombat == "1" or (gStartCombat == "0" and ml_global_information.Player_InCombat)) then
				
				if (gAssistFollowTarget == "1") then
					local ppos = ml_global_information.Player_Position
					local pos = target.pos
					--local dist = Distance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
					
					if (ml_global_information.AttackRange > 5) then
						if ((not InCombatRange(target.id) or (not target.los and not CanAttack(target.id))) and not ml_global_information.Player_IsCasting) then
							if (Now() > self.movementDelay) then
								local path = Player:MoveTo(pos.x,pos.y,pos.z, (target.hitradius + 1), false, false)
								self.movementDelay = Now() + 1000
							end
						end
						if (InCombatRange(target.id)) then
							if (Player.ismounted) then
								Dismount()
							end
							if (Player:IsMoving(FFXIV.MOVEMENT.FORWARD) and (target.los or CanAttack(target.id))) then
								Player:Stop()
								if (IsCaster(Player.job)) then
									return
								end
							end
							if (not EntityIsFrontTight(target)) then
								Player:SetFacing(pos.x,pos.y,pos.z) 
							end
						end
						if (InCombatRange(target.id) and target.attackable and target.alive) then
							SkillMgr.Cast( target )
						end
					else
						if (not InCombatRange(target.id) or (not target.los and not CanAttack(target.id))) then
							Player:MoveTo(pos.x,pos.y,pos.z, 2, false, false)
						end
						if (target.distance <= 15) then
							if (Player.ismounted) then
								Dismount()
							end
						end
						if (InCombatRange(target.id)) then
							Player:SetFacing(pos.x,pos.y,pos.z) 
							if (Player:IsMoving(FFXIV.MOVEMENT.FORWARD) and (target.los or CanAttack(target.id))) then
								Player:Stop()
							end
						end
						if (SkillMgr.Cast( target )) then
							Player:Stop()
						end
					end
					
				elseif (gAssistFollowTarget == "1") then
					Player:SetFacing(target.pos.x,target.pos.y,target.pos.z)
				end
				
				if (SkillMgr.Cast( target )) then
					casted = true
				elseif (InCombatRange(target.id) and target.attackable and target.alive) then
					casted = true
				end
			end
		end
		
		if (not casted) then
			SkillMgr.Cast( Player, true )
		end
	end

    if (TableSize(self.process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(self.process_elements)
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end

function ffxiv_task_assist.UIInit()
	--Add it to the main tracking table, so that we can save positions for it.
	ffxivminion.Windows.Assist = { id = strings["us"].assistMode, Name = GetString("assistMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Assist)

	if (Settings.FFXIVMINION.gAssistMode == nil) then
        Settings.FFXIVMINION.gAssistMode = GetString("none")
    end
    if (Settings.FFXIVMINION.gAssistPriority == nil) then
        Settings.FFXIVMINION.gAssistPriority = GetString("dps")
    end
	if (Settings.FFXIVMINION.gStartCombat == nil) then
        Settings.FFXIVMINION.gStartCombat = "1"
    end
	if (Settings.FFXIVMINION.gConfirmDuty == nil) then
        Settings.FFXIVMINION.gConfirmDuty = "0"
    end
	if (Settings.FFXIVMINION.gQuestHelpers == nil) then
		Settings.FFXIVMINION.gQuestHelpers = "0"
	end
	if (Settings.FFXIVMINION.gAssistFilter1 == nil) then
        Settings.FFXIVMINION.gAssistFilter1 = "0"
    end
	if (Settings.FFXIVMINION.gAssistFilter2 == nil) then
		Settings.FFXIVMINION.gAssistFilter2 = "0"
	end
	if (Settings.FFXIVMINION.gAssistFilter3 == nil) then
        Settings.FFXIVMINION.gAssistFilter3 = "0"
    end
	if (Settings.FFXIVMINION.gAssistFilter4 == nil) then
		Settings.FFXIVMINION.gAssistFilter4 = "0"
	end
	if (Settings.FFXIVMINION.gAssistFilter5 == nil) then
        Settings.FFXIVMINION.gAssistFilter5 = "0"
    end
	if (Settings.FFXIVMINION.gAssistUseAutoFace == nil) then
        Settings.FFXIVMINION.gAssistUseAutoFace = "0"
    end
	
	local winName = GetString("assistMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	GUI_NewButton(winName, "Teleport Nearest Current (HACK)", "ffxiv_task_assist.TeleportAetherCurrent")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,GetString("navmesh") ,"gmeshname",group,ffxivminion.Strings.Meshes())
	GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
	GUI_NewCheckbox(winName,"Follow Target","gAssistFollowTarget",group)
	GUI_NewCheckbox(winName,"Track Target","gAssistTrackTarget",group)
	
	local group = "Filters"
	GUI_NewCheckbox(winName,GetString("filter1"),"gAssistFilter1",group)
	GUI_NewCheckbox(winName,GetString("filter2"),"gAssistFilter2",group)
	GUI_NewCheckbox(winName,GetString("filter3"),"gAssistFilter3",group)
	GUI_NewCheckbox(winName,GetString("filter4"),"gAssistFilter4",group)
	GUI_NewCheckbox(winName,GetString("filter5"),"gAssistFilter5",group)
    
	local group = GetString("settings")
    GUI_NewComboBox(winName,GetString("assistMode"),"gAssistMode", group,GetStringList("none,lowestHealth,nearest,tankAssist",","))
    GUI_NewComboBox(winName,GetString("assistPriority"),"gAssistPriority",group,GetStringList("dps,healer",","))
	GUI_NewCheckbox(winName,"Use Autoface","gAssistUseAutoFace",group)
    GUI_NewCheckbox(winName,GetString("startCombat"),"gStartCombat",group)
    GUI_NewCheckbox(winName,GetString("confirmDuty"),"gConfirmDuty",group) 
    GUI_NewCheckbox(winName,GetString("questHelpers"),"gQuestHelpers",group)
	
	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gAssistMode = ffxivminion.SafeComboBox(Settings.FFXIVMINION.gAssistMode,gAssistMode_listitems,GetString("none"))
	gAssistPriority = ffxivminion.SafeComboBox(Settings.FFXIVMINION.gAssistPriority,gAssistPriority_listitems,GetString("dps"))
	gStartCombat = Settings.FFXIVMINION.gStartCombat
	gConfirmDuty = Settings.FFXIVMINION.gConfirmDuty
	gQuestHelpers = Settings.FFXIVMINION.gQuestHelpers
	gAssistFilter1 = Settings.FFXIVMINION.gAssistFilter1
	gAssistFilter2 = Settings.FFXIVMINION.gAssistFilter2
	gAssistFilter3 = Settings.FFXIVMINION.gAssistFilter3
	gAssistFilter4 = Settings.FFXIVMINION.gAssistFilter4
	gAssistFilter5 = Settings.FFXIVMINION.gAssistFilter5
	gAssistUseAutoFace = Settings.FFXIVMINION.gAssistUseAutoFace
	
	RegisterEventHandler("GUI.Update",ffxiv_task_assist.GUIVarUpdate)
end

function ffxiv_task_assist.TeleportAetherCurrent()
	local el = EntityList("type=7,targetable")
	if (ValidTable(el)) then
		for i,entity in pairs(el) do
			if (entity.name == "Aether Current") then
				local coord = entity.pos
				GameHacks:TeleportToXYZ(coord.x,coord.y,coord.z)
				Player:SetFacingSynced(coord.x,coord.y,coord.z)
				return true
			end
		end
	end
	
	d("Found no nearby currents")
	return false
end

c_assistyesno = inheritsFrom( ml_cause )
e_assistyesno = inheritsFrom( ml_effect )
function c_assistyesno:evaluate()
	if ((gBotMode == GetString("assistMode") and gQuestHelpers == "0") or
		ControlVisible("_NotificationParty") or
		ControlVisible("_NotificationTelepo") or
		ControlVisible("_NotificationFcJoin") or
		not Player.alive)
	then
		return false
	end
	return ControlVisible("SelectYesno")
end
function e_assistyesno:execute()
	PressYesNo(true)
	ml_task_hub:ThisTask().preserveSubtasks = true
end
_G["c_questyesno"] = c_questyesno
_G["e_questyesno"] = e_questyesno

function ffxiv_task_assist.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if 	( 	k == "gAssistMode" or
				k == "gAssistPriority" or
				k == "gStartCombat" or
				k == "gConfirmDuty" or
				k == "gAssistFilter1" or
				k == "gAssistFilter2" or 
				k == "gAssistFilter3" or
				k == "gAssistFilter4" or 
				k == "gAssistFilter5" or
				k == "gAssistTrackTarget") 
		then
			SafeSetVar(tostring(k),v)
		elseif (k == "gAssistFollowTarget") then
			SafeSetVar(tostring(k),v)
			if (v == "0") then
				Player:Stop()
			end
		elseif (k == "gQuestHelpers") then
			if (v == "1") then
				local message = {}
				message[1] = "Quest helpers are beta functionality, and should be used with caution."
				message[2] = "It is not advisable to use this feature on a main account at this time."
				ffxiv_dialog_manager.IssueNotice("FFXIV_Assist_QuestHelpersNotify", message)
			end
			SafeSetVar(tostring(k),v)
		elseif (k == "gAssistUseAutoFace") then
			if (v == "1") then
				local message = {}
				message[1] = "You must have the in-game option for automatic face target."
				message[2] = "Failure to do so could result in strange combat behavior and/or error messages."
				message[3] = "This feature is considered beta functionality as this time, please report issues."
				ffxiv_dialog_manager.IssueNotice("FFXIV_Assist_AutoFaceNotify", message)
			end
			SafeSetVar(tostring(k),v)
        end
    end
    GUI_RefreshWindow(GetString("assistMode"))
end

function ffxiv_task_assist.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" ) then
		if (string.find(Button,"ffxiv_task_assist%.")) then
			ExecuteFunction(Button)
		end
	end
end

RegisterEventHandler("GUI.Item", ffxiv_task_assist.HandleButtons)
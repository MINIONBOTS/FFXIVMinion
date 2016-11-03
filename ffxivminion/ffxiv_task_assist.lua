ffxiv_assist = {}
ffxiv_assist.strings = {}

ffxiv_task_assist = inheritsFrom(ml_task)
ffxiv_task_assist.name = "LT_ASSIST"
ffxiv_task_assist.autoRolled = {}
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
	--[[
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
	--]]
	
    self:AddTaskCheckCEs()
	self:InitAddon()
end

function ffxiv_task_assist:InitAddon()
end

function ffxiv_task_assist:Process()

	if (Player.alive) then
		local target = Player:GetTarget()
		
		if ( FFXIV_Assist_Mode ~= GetString("none") ) then
			local newTarget = nil
			
			if ( FFXIV_Assist_Priority == GetString("healer") ) then
				newTarget = ffxiv_assist.GetHealingTarget()
				if ( newTarget == nil ) then
					newTarget = ffxiv_assist.GetAttackTarget()				
				end		

			elseif ( FFXIV_Assist_Priority == GetString("dps") ) then
				newTarget = ffxiv_assist.GetAttackTarget()
				if ( newTarget == nil ) then
					newTarget = ffxiv_assist.GetHealingTarget()				
				end			
			end
			
			if ( newTarget ~= nil and (not target or newTarget.id ~= target.id)) then
				target = newTarget
				Player:SetTarget(target.id)  
			end
		end
		
		local casted = false
		if ( target and (target.chartype ~= 0 and target.chartype ~= 7) and (target.distance <= 35 or gAssistFollowTarget )) then
			if (FFXIV_Assist_StartCombat or (not FFXIV_Assist_StartCombat and Player.incombat)) then
				
				if (gAssistFollowTarget ) then
					local ppos = Player.pos
					local pos = target.pos
					--local dist = Distance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
					
					if (ml_global_information.AttackRange > 5) then
						if ((not InCombatRange(target.id) or not target.los) and not MIsCasting()) then
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
						if (not InCombatRange(target.id) or not target.los) then
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
					
				elseif (gAssistFollowTarget ) then
					Player:SetFacing(target.pos.x,target.pos.y,target.pos.z)
				end
				
				if (SkillMgr.Cast( target )) then
					casted = true
				--elseif (InCombatRange(target.id) and target.attackable and target.alive) then
					--casted = true
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

-- New GUI.
function ffxiv_task_assist:UIInit()
	FFXIV_Assist_StartCombat = ffxivminion.GetSetting("FFXIV_Assist_StartCombat",true)
	FFXIV_Assist_ConfirmDuty = ffxivminion.GetSetting("FFXIV_Assist_ConfirmDuty",false)
	FFXIV_Assist_QuestHelpers = ffxivminion.GetSetting("FFXIV_Assist_QuestHelpers",false)
	FFXIV_Assist_AutoFace = ffxivminion.GetSetting("FFXIV_Assist_AutoFace",false)
	FFXIV_Assist_FollowTarget = ffxivminion.GetSetting("FFXIV_Assist_FollowTarget",false)
	FFXIV_Assist_TrackTarget = ffxivminion.GetSetting("FFXIV_Assist_TrackTarget",false)
	
	FFXIV_Assist_Mode = ffxivminion.GetSetting("FFXIV_Assist_Mode", GetString("none"))
	FFXIV_Assist_Modes = { GetString("none"), GetString("lowestHealth"), GetString("nearest"), GetString("tankAssist") }
	FFXIV_Assist_ModeIndex = GetKeyByValue(FFXIV_Assist_Mode,FFXIV_Assist_Modes)
	
	FFXIV_Assist_Priority = ffxivminion.GetSetting("FFXIV_Assist_Priority", GetString("dps"))
	FFXIV_Assist_Priorities = { GetString("dps"), GetString("healer") }
	FFXIV_Assist_PriorityIndex = GetKeyByValue(FFXIV_Assist_Priority,FFXIV_Assist_Priorities)
	
	self.GUI.main_tabs = GUI_CreateTabs("status,settings",true)
end

ffxiv_task_assist.GUI = {
	x = 0,
	y = 0, 
	height = 0,
	width = 0,
}

function ffxiv_task_assist:Draw()
	local fontSize = GUI:GetWindowFontSize()
	local windowPaddingY = ml_gui.style.current.windowpadding.y
	local framePaddingY = ml_gui.style.current.framepadding.y
	local itemSpacingY = ml_gui.style.current.itemspacing.y
	
	GUI_DrawTabs(self.GUI.main_tabs)
	local tabs = self.GUI.main_tabs
	
	if (tabs.tabs[1].isselected) then
		GUI:BeginChild("##header-status",0,GUI_GetFrameHeight(5),true)
		GUI:PushItemWidth(120)					
		
		--GUI_Capture(GUI:Combo(GetString("skillProfile"), FFXIV_Common_SkillProfile, FFXIV_Common_SkillProfileList ),"FFXIV_Common_SkillProfile")		
		GUI_Capture(GUI:Checkbox(GetString("botEnabled"),FFXIV_Common_BotRunning),"FFXIV_Common_BotRunning");
		GUI_Capture(GUI:Checkbox("Follow Target",FFXIV_Assist_FollowTarget),"FFXIV_Assist_FollowTarget");
		GUI_Capture(GUI:Checkbox("Face Target",FFXIV_Assist_TrackTarget),"FFXIV_Assist_TrackTarget");
		
		if (GUI:Button("Show Filters",0,20)) then
			--SkillMgr.ShowFilterWindow()
		end
		
		GUI:PopItemWidth()
		GUI:EndChild()
	end
	
	if (tabs.tabs[2].isselected) then
		GUI:BeginChild("##header-settings",0,GUI_GetFrameHeight(6),true)
		GUI:PushItemWidth(120)					
		
		GUI_Combo(GetString("assistMode"), "FFXIV_Assist_ModeIndex", "FFXIV_Assist_Mode", FFXIV_Assist_Modes)
		GUI_Combo(GetString("assistPriority"), "FFXIV_Assist_PriorityIndex", "FFXIV_Assist_Priority", FFXIV_Assist_Priorities)		
		GUI_Capture(GUI:Checkbox("Use Autoface",FFXIV_Assist_AutoFace),"FFXIV_Assist_AutoFace");
		GUI_Capture(GUI:Checkbox(GetString("startCombat"),FFXIV_Assist_StartCombat),"FFXIV_Assist_StartCombat");
		GUI_Capture(GUI:Checkbox(GetString("confirmDuty"),FFXIV_Assist_ConfirmDuty),"FFXIV_Assist_ConfirmDuty");
		GUI_Capture(GUI:Checkbox(GetString("questHelpers"),FFXIV_Assist_QuestHelpers),"FFXIV_Assist_QuestHelpers", 
			function ()
				local message = {
					[1] = "Quest helpers are beta functionality, and should be used with caution.",
					[2] = "It is not advisable to use this feature on a main account at this time.",
				}
				ffxiv_dialog_manager.IssueNotice("FFXIV_Assist_QuestHelpersNotify", message)
			end
		);
		
		GUI:PopItemWidth()
		GUI:EndChild()
	end
end

c_assistyesno = inheritsFrom( ml_cause )
e_assistyesno = inheritsFrom( ml_effect )
function c_assistyesno:evaluate()
	if ((gBotMode == GetString("assistMode") and not FFXIV_Assist_QuestHelpers) or
		IsControlOpen("_NotificationParty") or
		IsControlOpen("_NotificationTelepo") or
		IsControlOpen("_NotificationFcJoin") or
		not Player.alive)
	then
		return false
	end
	return IsControlOpen("SelectYesno")
end
function e_assistyesno:execute()
	PressYesNo(true)
	ml_task_hub:ThisTask().preserveSubtasks = true
end

function ffxiv_assist.GetHealingTarget()
    local target = nil
    if ( FFXIV_Assist_Mode == GetString("lowestHealth")) then	
        local target = GetBestHealTarget()		
    elseif ( FFXIV_Assist_Mode == GetString("nearest") ) then	
        local target = GetClosestHealTarget()	
    end
    
    if ( target and target.hp.percent < SkillMgr.GetHealSpellHPLimit() ) then
        return target
    end
	
    return nil
end

function ffxiv_assist.GetAttackTarget()
	local maxDistance = (ml_global_information.AttackRange < 5 ) and 8 or ml_global_information.AttackRange
    local target = nil
    if ( FFXIV_Assist_Mode == GetString("lowestHealth")) then	
        local el = EntityList("lowesthealth,alive,attackable,maxdistance="..tostring(maxDistance))
        if ( table.valid(el) ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                target = e
            end
        end
    elseif ( FFXIV_Assist_Mode == GetString("nearest") ) then	
        local el = EntityList("nearest,alive,attackable,maxdistance="..tostring(maxDistance))
        if ( table.valid(el) ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                target = e
            end
        end	
	 elseif ( FFXIV_Assist_Mode == GetString("tankAssist") ) then
		local party = EntityList("myparty")
		if (table.valid(party)) then
			local tanks = {}
			for i,member in pairs(party) do
				if (IsTank(member.job) and member.id ~= Player.id) then
					table.insert(tanks,member)
				end
			end
			
			if (table.valid(tanks)) then
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
ffxiv_assist = {}
ffxiv_assist.strings = {}

ffxiv_task_assist = inheritsFrom(ml_task)
ffxiv_task_assist.name = "LT_ASSIST"
ffxiv_task_assist.autoRolled = {}
ffxiv_task_assist.lastTarget = 0
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
	
	local ke_eat = ml_element:create( "Eat", c_eat, e_eat, 16 )
    self:add( ke_eat, self.process_elements)
	
    local ke_roleset = ml_element:create( "RoleSet", c_roleautoset, e_roleautoset, 100 )
    self:add( ke_roleset, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_assist:Process()
	--if (not gACRBypass) then
		if (Player.alive and not MIsLoading()) then
			
			local autoface, movemode = ml_global_information.GetMovementInfo(false)
			
			local target = Player:GetTarget()
			
			if ( FFXIV_Assist_Mode ~= GetString("none") ) then
				local newTarget = nil
				
				if (FFXIV_Assist_Mode == GetString("Highest HP (AOE Only)")) then
					if (not target or TimeSince(ffxiv_task_assist.lastTarget) > 1000) then
						--local clustered = 
					end			
				elseif ( FFXIV_Assist_Priority == GetString("healer") ) then
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
			if ( target and (target.chartype ~= 0 and target.chartype ~= 7) and (target.distance2d <= 30 or gAssistFollowTarget )) then
				if (gStartCombat or (not gStartCombat and Player.incombat)) then
					
					if (gAssistFollowTarget ) then
						local ppos = Player.pos
						local pos = target.pos
						
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
							if (target.distance2d <= 15) then
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
						
					elseif (gAssistTrackTarget ) then
						Player:SetFacing(target.pos.x,target.pos.y,target.pos.z)
					end
					
					if (SkillMgr.Cast( target )) then
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
	--else
		--SkillMgr.Cast()
	--end
end

-- New GUI.
function ffxiv_task_assist:UIInit()
	gStartCombat = ffxivminion.GetSetting("gStartCombat",true)
	gAssistConfirmDuty = ffxivminion.GetSetting("gAssistConfirmDuty",false)
	gQuestHelpers = ffxivminion.GetSetting("gQuestHelpers",false)
	gAssistUseAutoFace = ffxivminion.GetSetting("gAssistUseAutoFace",false)
	gAssistUseLegacy = ffxivminion.GetSetting("gAssistUseLegacy",false)
	gAssistFollowTarget = ffxivminion.GetSetting("gAssistFollowTarget",false)
	gAssistTrackTarget = ffxivminion.GetSetting("gAssistTrackTarget",false)
	
	FFXIV_Assist_Mode = ffxivminion.GetSetting("FFXIV_Assist_Mode", GetString("none"))
	FFXIV_Assist_Modes = { GetString("none"), GetString("lowestHealth"), GetString("highestHealth"), GetString("nearest"), GetString("tankAssist") }
	FFXIV_Assist_ModeIndex = GetKeyByValue(FFXIV_Assist_Mode,FFXIV_Assist_Modes)
	
	FFXIV_Assist_Priority = ffxivminion.GetSetting("FFXIV_Assist_Priority", GetString("dps"))
	FFXIV_Assist_Priorities = { GetString("dps"), GetString("healer") }
	FFXIV_Assist_PriorityIndex = GetKeyByValue(FFXIV_Assist_Priority,FFXIV_Assist_Priorities)
	
	self.GUI.main_tabs = GUI_CreateTabs("settings",true)
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
	
	GUI:BeginChild("##header-status",0,GUI_GetFrameHeight(9),true)
	GUI:PushItemWidth(120)					
	GUI:Columns(2)
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Targeting Assist"))
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("None: Use manual targetting.\
Lowest Health: Targets the lowest health target within range.\
Highest Health: Targets the highest health target within range.\
Nearest: Targets the closest target within range.\
Tank Assist: Targets whatever your tank is targetting.")) end
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Priority"))
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Prioritize Damage or Healing.")) end
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Follow Target"))
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Attempts to continually follow the target (useful in PvP).")) end
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Face Target"))
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Attempts to continually face the target.\
		Warning:  Dangerous if using Standard movement mode.")) end
		
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use Client Autoface"))
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("This option should be turned on if you are using the game client's [Face Target on Attack] options.")) end
	
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Set Legacy Movement"))
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("This option sets Legacy movement mode.")) end
	
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Start Combat"))
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("If this option is off, the bot will not attack a mob that is not in combat already.")) end
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Auto-Confirm Duty"))
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Auto accepts Duty Queue.")) end
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("questHelpers"))
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Performs some tasks automatically, like quest accept, turn-ins, quest completions.")) end
	
	GUI:NextColumn()
	
	--GUI_Capture(GUI:Combo(GetString("skillProfile"), FFXIV_Common_SkillProfile, FFXIV_Common_SkillProfileList ),"FFXIV_Common_SkillProfile")		
	
	local assistcolumn2width = GUI:GetContentRegionAvailWidth()
	GUI:PushItemWidth(assistcolumn2width)
	GUI_Combo("##"..GetString("assist"), "FFXIV_Assist_ModeIndex", "FFXIV_Assist_Mode", FFXIV_Assist_Modes)
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("None: Use manual targetting.\nLowest Health: Targets the lowest health target within range.\nHighest Health: Targets the highest health target within range.\nNearest: Targets the closest target within range.\nTank Assist: Targets whatever your tank is targetting.")) end
	GUI_Combo("##"..GetString("Priority"), "FFXIV_Assist_PriorityIndex", "FFXIV_Assist_Priority", FFXIV_Assist_Priorities)
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Prioritize Damage or Healing.")) end
	GUI:PopItemWidth()
	GUI_Capture(GUI:Checkbox("##"..GetString("Follow Target"),gAssistFollowTarget),"gAssistFollowTarget")
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Attempts to continually follow the target (useful in PvP).")) end
	GUI_Capture(GUI:Checkbox("##"..GetString("Face Target"),gAssistTrackTarget),"gAssistTrackTarget")
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Attempts to continually face the target.\nWarning:  Dangerous if using Standard movement mode.")) end
	
	
	GUI_Capture(GUI:Checkbox("##"..GetString("Use Client Autoface"),gAssistUseAutoFace),"gAssistUseAutoFace")
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("This option will set the game client's [Face Target on Attack] option on and also turn on Legacy movement mode.")) end
	
	GUI_Capture(GUI:Checkbox("##"..GetString("Set Legacy Movement"),gAssistUseLegacy),"gAssistUseLegacy")
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Sets Legacy movement mode automatically when using assist.")) end
	
	GUI_Capture(GUI:Checkbox("##"..GetString("Start Combat"),gStartCombat),"gStartCombat")
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("If this option is off, the bot will not attack a mob that is not in combat already.")) end
	GUI_Capture(GUI:Checkbox("##"..GetString("Auto-Confirm Duty"),gAssistConfirmDuty),"gAssistConfirmDuty")
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Auto accepts Duty Queue.")) end
	GUI_Capture(GUI:Checkbox("##"..GetString("questHelpers"),gQuestHelpers),"gQuestHelpers")
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Performs some tasks automatically, like quest accept, turn-ins, quest completions.")) end
	GUI:Columns()
	GUI:PopItemWidth()
	GUI:EndChild()
end

c_assistyesno = inheritsFrom( ml_cause )
e_assistyesno = inheritsFrom( ml_effect )
function c_assistyesno:evaluate()
	if ((gBotMode == GetString("assistMode") and not gQuestHelpers) or
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
    elseif ( FFXIV_Assist_Mode == GetString("highestHealth")) then	
        local el = EntityList("highesthealth,alive,attackable,maxdistance="..tostring(maxDistance))
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
					if (not closest or (closest and tank.distance2d < closestDistance)) then
						closest = tank
						closestDistance = tank.distance2d
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
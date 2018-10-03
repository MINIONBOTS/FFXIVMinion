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
	local ke_pressConfirm = ml_element:create( "ConfirmDuty", c_pressconfirm, e_pressconfirm, 150 )
    self:add(ke_pressConfirm, self.process_elements)
	
	local ke_acceptQuest = ml_element:create( "AcceptQuest", c_acceptquest, e_acceptquest, 140 )
    self:add(ke_acceptQuest, self.process_elements)
	
	local ke_handoverQuest = ml_element:create( "HandoverQuestItem", c_handoverquest, e_handoverquest, 130 )
    self:add(ke_handoverQuest, self.process_elements)
	
	local ke_completeQuest = ml_element:create( "CompleteQuest", c_completequest, e_completequest, 120 )
    self:add(ke_completeQuest, self.process_elements)
	
	local ke_yesnoAssist = ml_element:create( "QuestYesNo", c_assistyesno, e_assistyesno, 110 )
    self:add(ke_yesnoAssist, self.process_elements)
	
	local ke_avoid = ml_element:create( "Avoid", c_avoid, e_avoid, 100)
	self:add(ke_avoid, self.process_elements)
	
	local ke_roleset = ml_element:create( "RoleSet", c_roleautoset, e_roleautoset, 90 )
    self:add( ke_roleset, self.process_elements)
	
	local ke_autoPotion = ml_element:create( "AutoPotion", c_autopotion, e_autopotion, 80)
	self:add(ke_autoPotion, self.process_elements)
	
	local ke_fateSync = ml_element:create( "FateSync", c_assistsyncfatelevel, e_assistsyncfatelevel, 70 )
    self:add( ke_fateSync, self.process_elements)
	
	local ke_companion = ml_element:create( "Companion", c_companion, e_companion, 60 )
    self:add( ke_companion, self.process_elements)
	
	local ke_stance = ml_element:create( "Stance", c_stance, e_stance, 50 )
    self:add( ke_stance, self.process_elements)
	
	local ke_eat = ml_element:create( "Eat", c_eat, e_eat, 40 )
    self:add( ke_eat, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_assist:Process()
	--if (not gACRBypass) then
		if (Player.alive and not MIsLoading()) then
			
			local autoface, movemode = ml_global_information.GetMovementInfo(false)
			
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
			if ( target and (target.chartype ~= 0 and target.chartype ~= 7) and (target.distance2d <= 30 or gAssistFollowTarget )) then
				if (gStartCombat or (not gStartCombat and Player.incombat)) then
					
					if (gAssistFollowTarget) then
						local ppos = Player.pos
						local pos = target.pos
						
						if (ml_global_information.AttackRange > 5) then
							if ((not InCombatRange(target.id) or not target.los) and not MIsCasting()) then
								if (Now() > self.movementDelay) then
									local path = Player:MoveTo(pos.x,pos.y,pos.z, (target.hitradius + 1),  0, 0, target.id)
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
								local pathLength = Player:MoveTo(pos.x,pos.y,pos.z, (target.hitradius + 1), 0, 1, target.id)
								if (pathLength <= 0) then
									Player:MoveTo(pos.x,pos.y,pos.z, (target.hitradius + 1), 0, 0, target.id)
								end
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
	gAssistSyncFate = ffxivminion.GetSetting("gAssistSyncFate",true)
	
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

function ffxiv_task_assist.StartElement(strText)
	GUI:BeginGroup()
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString(strText))
	GUI:SameLine(160)
end

function ffxiv_task_assist.EndElement(strTooltip)
	GUI:EndGroup()
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString(strTooltip)) end
	
end

function ffxiv_task_assist:Draw()
	local fontSize = GUI:GetWindowFontSize()
	local windowPaddingY = GUI:GetStyle().windowpadding.y
	local framePaddingY = GUI:GetStyle().framepadding.y
	local itemSpacingY = GUI:GetStyle().itemspacing.y
	
	GUI:BeginChild("##header-status",0,GUI_GetFrameHeight(10),true)
	GUI:PushItemWidth(120)
	
	ffxiv_task_assist.StartElement("Targeting Assist")
	GUI_Combo("##"..GetString("assist"), "FFXIV_Assist_ModeIndex", "FFXIV_Assist_Mode", FFXIV_Assist_Modes)
	ffxiv_task_assist.EndElement("None: Use manual targetting.\
Lowest Health: Targets the lowest health target within range.\
Nearest: Targets the closest target within range.\
Tank Assist: Targets whatever your tank is targetting.")

	ffxiv_task_assist.StartElement("Priority")
	GUI_Combo("##"..GetString("Priority"), "FFXIV_Assist_PriorityIndex", "FFXIV_Assist_Priority", FFXIV_Assist_Priorities)
	ffxiv_task_assist.EndElement("Prioritize Damage or Healing.")
	
	ffxiv_task_assist.StartElement("Follow Target")
	GUI_Capture(GUI:Checkbox("##"..GetString("Follow Target"),gAssistFollowTarget),"gAssistFollowTarget")
	ffxiv_task_assist.EndElement("Attempts to continually follow the target (useful in PvP).")
	
	ffxiv_task_assist.StartElement("Face Target")
	GUI_Capture(GUI:Checkbox("##"..GetString("Face Target"),gAssistTrackTarget),"gAssistTrackTarget")

	ffxiv_task_assist.EndElement("Attempts to continually face the target.\
		Warning:  Dangerous if using Standard movement mode.")
	
	ffxiv_task_assist.StartElement("Use Client Autoface")
	GUI_Capture(GUI:Checkbox("##"..GetString("Use Client Autoface"),gAssistUseAutoFace),"gAssistUseAutoFace", function () ml_global_information.GetMovementInfo(false) end)
	ffxiv_task_assist.EndElement("This option enables the client auto-face option.")
	
	ffxiv_task_assist.StartElement("Set Legacy Movement")
	GUI_Capture(GUI:Checkbox("##"..GetString("Set Legacy Movement"),gAssistUseLegacy),"gAssistUseLegacy", function () ml_global_information.GetMovementInfo(false) end)
	ffxiv_task_assist.EndElement("This option sets Legacy movement mode.")
	
	ffxiv_task_assist.StartElement("Start Combat")
	GUI_Capture(GUI:Checkbox("##"..GetString("Start Combat"),gStartCombat),"gStartCombat")
	ffxiv_task_assist.EndElement("If this option is off, the bot will not attack a mob that is not in combat already.")
	
	ffxiv_task_assist.StartElement("Auto-Confirm Duty")
	GUI_Capture(GUI:Checkbox("##"..GetString("Auto-Confirm Duty"),gAssistConfirmDuty),"gAssistConfirmDuty")
	ffxiv_task_assist.EndElement("Auto accepts Duty confirmation.")
	
	ffxiv_task_assist.StartElement("Auto FATE Sync")
	GUI_Capture(GUI:Checkbox("##"..GetString("Auto FATE Sync"),gAssistSyncFate),"gAssistSyncFate")
	ffxiv_task_assist.EndElement("Automatically sync to FATE if necessary, requires a target.")
	
	ffxiv_task_assist.StartElement("Quest Helpers")
	GUI_Capture(GUI:Checkbox("##"..GetString("Quest Helpers"),gQuestHelpers),"gQuestHelpers")
	ffxiv_task_assist.EndElement("Performs some tasks automatically, like quest accept, turn-ins, quest completions.")
	
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

c_assistsyncfatelevel = inheritsFrom( ml_cause )
e_assistsyncfatelevel = inheritsFrom( ml_effect )
function c_assistsyncfatelevel:evaluate()
    if (not gAssistSyncFate or Player:GetSyncLevel() ~= 0 or Now() < ml_global_information.syncTimer) then
        return false
    end
	
	local target = MGetTarget()
	if (target and target.fateid ~= 0 and not Player.ismounted) then
		local myPos = Player.pos
		local fateID = target.fateid
		local fate = MGetFateByID(fateID)
		if ( table.valid(fate)) then
			if (fate.maxlevel < Player.level) then
			--if (AceLib.API.Fate.RequiresSync(fate.id)) then
				local distance = Distance2D(myPos.x, myPos.z, fate.x, fate.z)
				if (distance <= fate.radius) then
					Player:SyncLevel()
					return true
				end
			end
		end
	end
    return false
end
function e_assistsyncfatelevel:execute()
	ml_task_hub:ThisTask().preserveSubtasks = true
	ml_global_information.syncTimer = Now() + 1000
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
	local maxDistance = (ml_global_information.AttackRange < 5 ) and 8 or 25
    local target = nil
    if ( FFXIV_Assist_Mode == GetString("lowestHealth")) then	
        local el = MEntityList("los,lowesthealth,alive,attackable,maxdistance2d="..tostring(maxDistance))
        if ( table.valid(el) ) then
            local i,e = next(el)
			if (i and e) then
				if (e.hp.percent == 100) then
					el = MEntityList("los,nearest,alive,attackable,maxdistance2d="..tostring(maxDistance))
					if ( table.valid(el) ) then
						i,e = next(el)
						if (i and e) then
							target = e
						end
					else
						el = MEntityList("nearest,alive,attackable,maxdistance2d="..tostring(maxDistance))
						if ( table.valid(el) ) then
							i,e = next(el)
							if (i and e) then
								target = e
							end
						end
					end	
				else
					target = e
				end
			end
		else
			el = MEntityList("lowesthealth,alive,attackable,maxdistance2d="..tostring(maxDistance))
			if ( table.valid(el) ) then
				local i,e = next(el)
				if (i and e) then
					if (e.hp.percent == 100) then
						el = MEntityList("los,nearest,alive,attackable,maxdistance2d="..tostring(maxDistance))
						if ( table.valid(el) ) then
							i,e = next(el)
							if (i and e) then
								target = e
							end
						else
							el = MEntityList("nearest,alive,attackable,maxdistance2d="..tostring(maxDistance))
							if ( table.valid(el) ) then
								i,e = next(el)
								if (i and e) then
									target = e
								end
							end
						end	
					else
						target = e
					end
				end
			end
        end
    elseif ( FFXIV_Assist_Mode == GetString("highestHealth")) then	
        local el = MEntityList("los,highesthealth,alive,attackable,maxdistance2d="..tostring(maxDistance))
        if ( table.valid(el) ) then
            local i,e = next(el)
            if (i and e) then
                if (e.hp.percent == 100) then
					el = MEntityList("los,nearest,alive,attackable,maxdistance2d="..tostring(maxDistance))
					if ( table.valid(el) ) then
						i,e = next(el)
						if (i and e) then
							target = e
						end
					else
						el = MEntityList("nearest,alive,attackable,maxdistance2d="..tostring(maxDistance))
						if ( table.valid(el) ) then
							i,e = next(el)
							if (i and e) then
								target = e
							end
						end
					end	
				else
					target = e
				end
            end
		else
			el = MEntityList("highesthealth,alive,attackable,maxdistance2d="..tostring(maxDistance))
			if ( table.valid(el) ) then
				local i,e = next(el)
				if (i and e) then
					if (e.hp.percent == 100) then
						el = MEntityList("los,nearest,alive,attackable,maxdistance2d="..tostring(maxDistance))
						if ( table.valid(el) ) then
							i,e = next(el)
							if (i and e) then
								target = e
							end
						else
							el = MEntityList("nearest,alive,attackable,maxdistance2d="..tostring(maxDistance))
							if ( table.valid(el) ) then
								i,e = next(el)
								if (i and e) then
									target = e
								end
							end
						end	
					else
						target = e
					end
				end
			end
        end
    elseif ( FFXIV_Assist_Mode == GetString("nearest") ) then	
        local el = MEntityList("los,nearest,alive,attackable,maxdistance2d="..tostring(maxDistance))
        if ( table.valid(el) ) then
            local i,e = next(el)
            if (i and e) then
                target = e
            end
		else
			el = MEntityList("nearest,alive,attackable,maxdistance2d="..tostring(maxDistance))
			if ( table.valid(el) ) then
				local i,e = next(el)
				if (i and e) then
					target = e
				end
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
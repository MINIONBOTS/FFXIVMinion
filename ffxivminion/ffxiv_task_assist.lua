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
	
	local ke_yesnoQuest = ml_element:create( "QuestYesNo", c_questyesno, e_questyesno, 23 )
    self:add(ke_yesnoQuest, self.process_elements)
	
	local ke_avoid = ml_element:create( "Avoid", c_avoid, e_avoid, 20)
	self:add(ke_avoid, self.process_elements)
	
	local ke_autoPotion = ml_element:create( "AutoPotion", c_autopotion, e_autopotion, 19)
	self:add(ke_autoPotion, self.process_elements)
	
	local ke_companion = ml_element:create( "Companion", c_companion, e_companion, 18 )
    self:add( ke_companion, self.process_elements)
	
	local ke_stance = ml_element:create( "Stance", c_stance, e_stance, 17 )
    self:add( ke_stance, self.process_elements)
  
    self:AddTaskCheckCEs()
end

function ffxiv_task_assist:GetHealingTarget()
    local target = nil
    if ( gAssistMode == GetString("lowestHealth")) then	
        local target = GetBestHealTarget()		
    
    elseif ( gAssistMode == GetString("nearest") ) then	
        local target = GetClosestHealTarget()	
    end
    
    if ( target~=nil and target.hp.percent < SkillMgr.GetHealSpellHPLimit() ) then
        return target
    end
    return nil
end

function ffxiv_task_assist:GetAttackTarget()
	local maxDistance = (ml_global_information.AttackRange < 5 ) and 8 or ml_global_information.AttackRange
    local target = nil
    if ( gAssistMode == GetString("lowestHealth")) then	
        local el = EntityList("lowesthealth,alive,attackable,maxdistance="..tostring(maxDistance))
        if ( el ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                target = e
            end
        end	
    
    elseif ( gAssistMode == GetString("nearest") ) then	
        local el = EntityList("nearest,alive,attackable,maxdistance="..tostring(maxDistance))
        if ( el ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                target = e
            end
        end	
    end
    
    return target
end


function ffxiv_task_assist:Process()

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

    if ( target and target.alive and (target.attackable or target.chartype==2 or target.chartype==5 or target.chartype==4) and target.distance <= 35 ) then
		if (gStartCombat == "1" or (gStartCombat == "0" and Player.incombat)) then
			SkillMgr.Cast( target )
		end
    end
	
	if ( target == nil and not ActionList:IsCasting()) then
		SkillMgr.Cast( Player, true )
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

	if ( Settings.FFXIVMINION.gAssistMode == nil ) then
        Settings.FFXIVMINION.gAssistMode = GetString("none")
    end
    if ( Settings.FFXIVMINION.gAssistPriority == nil ) then
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
	
	local winName = GetString("assistMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, "Teleport Nearest Current (HACK)", "ffxiv_task_assist.TeleportAetherCurrent")
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,GetString("navmesh") ,"gmeshname",group,ffxivminion.Strings.Meshes())
	GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
	
	local group = "Filters"
	GUI_NewCheckbox(winName,GetString("filter1"),"gAssistFilter1",group)
	GUI_NewCheckbox(winName,GetString("filter2"),"gAssistFilter2",group)
	GUI_NewCheckbox(winName,GetString("filter3"),"gAssistFilter3",group)
	GUI_NewCheckbox(winName,GetString("filter4"),"gAssistFilter4",group)
	GUI_NewCheckbox(winName,GetString("filter5"),"gAssistFilter5",group)
    
	local group = GetString("settings")
    GUI_NewComboBox(winName,GetString("assistMode"),"gAssistMode", group,GetStringList("none,lowestHealth,nearest",","))
    GUI_NewComboBox(winName,GetString("assistPriority"),"gAssistPriority",group,GetStringList("dps,healer",","))
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

function ffxiv_task_assist.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if 	( 	k == "gAssistMode" or
				k == "gAssistPriority" or
				k == "gStartCombat" or
				k == "gConfirmDuty" or
				k == "gQuestHelpers" or
				k == "gAssistFilter1" or
				k == "gAssistFilter2" or 
				k == "gAssistFilter3" or
				k == "gAssistFilter4" or
				k == "gAssistFilter5") 
		then
			SafeSetVar(tostring(k),v)
        end
    end
    GUI_RefreshWindow(GetString("assistMode"))
end

function ffxiv_task_assist.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" ) then
		if (string.find(Button,"ffxiv_task_assist.")) then
			ExecuteFunction(Button)
		end
	end
end

RegisterEventHandler("GUI.Item", ffxiv_task_assist.HandleButtons)
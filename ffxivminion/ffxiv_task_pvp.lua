ffxiv_task_pvp = inheritsFrom(ml_task)
ffxiv_task_pvp.name = "LT_PVP"

function ffxiv_task_pvp.Create()
    local newinst = inheritsFrom(ffxiv_task_pvp)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_pvp members
    newinst.name = "LT_PVP"
    newinst.targetid = 0
    newinst.queueTimer = 0
    newinst.windowTimer = 0
	newinst.afkTimer = 0
	newinst.lastPos = {}
	newinst.fleeing = false
	newinst.targetPrio = ""
    newinst.leaveTimer = 0
	
	-- set the correct starting state in case we're already in a pvp map and reload lua
	if (Player.localmapid == 337 or Player.localmapid == 175 or Player.localmapid == 336) then
		newinst.state = "DUTY_STARTED"
	else
		newinst.state = ""
	end
	newinst.targetTimer = 0
	newinst.startTimer = 0
    
    --this is the targeting function that will be used for the generic KillTarget task
    newinst.targetFunction = GetPVPTarget
    
    return newinst
end

c_joinqueuepvp = inheritsFrom( ml_cause )
e_joinqueuepvp = inheritsFrom( ml_effect )
function c_joinqueuepvp:evaluate() 
    return ((   Player.localmapid ~= 337 and Player.localmapid ~= 175 and Player.localmapid ~= 336) and 
                TimeSince(ml_task_hub:CurrentTask().queueTimer) > math.random(30000,35000) and
                (ml_task_hub:CurrentTask().state == "COMBAT_ENDED" or
				ml_task_hub:CurrentTask().state == ""))
end
function e_joinqueuepvp:execute()
    if not ControlVisible("ContentsFinder") then
        ActionList:Cast(33,0,10)
        ml_task_hub:CurrentTask().windowTimer = ml_global_information.Now
    elseif (TimeSince(ml_task_hub:CurrentTask().windowTimer) > math.random(4000,5000)) then
        PressDutyJoin()
        ml_task_hub:CurrentTask().state = "WAITING_FOR_DUTY"
    end
end

c_pressleave = inheritsFrom( ml_cause )
c_pressleave.throttle = 1000
e_pressleave = inheritsFrom( ml_effect )
function c_pressleave:evaluate() 
    return ((Player.localmapid == 337 or Player.localmapid == 336 or Player.localmapid == 175) and ControlVisible("ColosseumRecord"))
end
function e_pressleave:execute()
	-- reset pvp task state since it doesn't get terminated/reinstantiated
    if (gPVPDelayLeave == "1" and ml_task_hub:CurrentTask().leaveTimer == 0) then
        ml_task_hub:CurrentTask().leaveTimer = ml_global_information.Now + math.random(8000,13000)
    elseif (gPVPDelayLeave == "0" or ml_global_information.Now > ml_task_hub:CurrentTask().leaveTimer) then
        ml_task_hub:CurrentTask().state = "COMBAT_ENDED"
        ml_task_hub:CurrentTask().targetid = 0
        ml_task_hub:CurrentTask().startTimer = 0
        ml_task_hub:CurrentTask().leaveTimer = 0
        ml_task_hub:CurrentTask().lastPos = {}
        ml_task_hub:CurrentTask().afkTimer = ml_global_information.Now + math.random(300000,600000)
        ml_task_hub:CurrentTask().queueTimer = ml_global_information.Now
        Player:Stop()
        PressLeaveColosseum()
    end
end

c_startcombat = inheritsFrom( ml_cause )
e_startcombat = inheritsFrom( ml_effect )
function c_startcombat:evaluate()
	-- make sure we don't go back into combat state after the leave button is pressed
	if ml_task_hub:CurrentTask().state == "COMBAT_ENDED"  or ml_task_hub:CurrentTask().state == "COMBAT_STARTED" then return false end
	
    -- just in case we restart lua while in pvp combat
    if ((Player.localmapid == 337 or Player.localmapid == 336 or Player.localmapid == 175) and (Player.incombat or InCombatRange(ml_task_hub:CurrentTask().targetid))) then
        return true
    end

    if ((Player.localmapid == 337 or Player.localmapid == 336 or Player.localmapid == 175) and ml_task_hub:CurrentTask().state == "DUTY_STARTED") then
        local party = EntityList("myparty")
        local maxdistance = 0
        if (ValidTable(party)) then
			local myPos = Player.pos
            local i, e = next(party)
            while i ~= nil and e ~= nil do
				-- if any party members are in combat then start combat
                if e.incombat then return true end
				
				-- otherwise check to see if any party members have crossed the gate and set a random timer
                if 	(myPos.x > 33 and e.pos.x < 33) or
					(myPos.x < -33 and e.pos.x > -33) 
				then
					if (ml_task_hub:CurrentTask().startTimer == 0) then
						ml_task_hub:CurrentTask().startTimer = ml_global_information.Now + math.random(500,1500)
					elseif (ml_global_information.Now > ml_task_hub:CurrentTask().startTimer) then
						return true
					end
                end
            i, e = next(party, i)
            end
        end
            
        return false
    end
    
    return false
end
function e_startcombat:execute()
    ml_task_hub:CurrentTask().state = "COMBAT_STARTED"
end

c_movetotargetpvp = inheritsFrom( ml_cause )
e_movetotargetpvp = inheritsFrom( ml_effect )
function c_movetotargetpvp:evaluate()
    if (ml_task_hub:CurrentTask().targetid and ml_task_hub:CurrentTask().targetid ~= 0 
		and Player.alive and not ml_task_hub:CurrentTask().fleeing and not HasBuff(Player.id,3)
		and not HasBuff(Player.id,280) and not HasBuff(Player.id,13))
	then
        local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
        return ValidTable(target) and not InCombatRange(target.id)
    end
    
    return false
end
function e_movetotargetpvp:execute()
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
    if ValidTable(target) then
        local gotoPos = target.pos
        ml_debug( "Moving to ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")	
        local PathSize = Player:MoveTo( tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z),1.0, 
                                        true,gRandomPaths=="1")
    end
end

c_attargetpvp = inheritsFrom( ml_cause )
e_attargetpvp = inheritsFrom( ml_effect )
function c_attargetpvp:evaluate()
    if (Player:IsMoving() and not ml_task_hub:CurrentTask().fleeing) then
        if ml_global_information.AttackRange > 20 then
            local target = EntityList:Get(ml_task_hub:ThisTask().targetid)
            if ValidTable(target) then
                local rangePercent = tonumber(gCombatRangePercent) * 0.01
                return InCombatRange(ml_task_hub:ThisTask().targetid) and target.distance2d < (ml_global_information.AttackRange * rangePercent)
            end
        else
            return InCombatRange(ml_task_hub:ThisTask().targetid)
        end
    end
    return false
end
function e_attargetpvp:execute()
    Player:Stop()
end

c_fleepvp = inheritsFrom( ml_cause )
e_fleepvp = inheritsFrom( ml_effect )
function c_fleepvp:evaluate()
	if (gPVPFlee == "0" or Player:IsMoving()) then
		return false
	end

	local enemy = GetNearestAggro()
	if (ValidTable(enemy)) then
		if (IsRanged(Player.job) and InCombatRange(enemy.id)) then
			ml_task_hub:CurrentTask().fleeing = true
			return true
		end
	end
	
	gPVPTargetOne = ml_task_hub:CurrentTask().targetPrio
	ml_task_hub:CurrentTask().fleeing = false
	return false
end
function e_fleepvp:execute()
	-- temporarily target nearest regardless of actual priority
	ml_task_hub:CurrentTask().targetPrio = gPVPTargetOne
	gPVPTargetOne = strings[gCurrentLanguage].nearest
	ml_task_hub:CurrentTask().targetid = 0
	local myPos = Player.pos
	local newPos = NavigationManager:GetRandomPointOnCircle(myPos.x, myPos.y, myPos.z,10,20)
	if (ValidTable(newPos)) then
		Player:MoveTo(newPos.x, newPos.y, newPos.z, 0.5)
	end
end

c_afkmove = inheritsFrom( ml_cause )
e_afkmove = inheritsFrom( ml_effect )
function c_afkmove:evaluate()
	return 	(gAFKMove == "1" and 
			ml_global_information.Now > ml_task_hub:CurrentTask().afkTimer and
			( Player.localmapid == 337 or Player.localmapid == 175 or Player.localmapid == 336) and
			(TableSize(ml_task_hub:CurrentTask().lastPos) == 0 or
			Distance2D(Player.pos.x, Player.pos.y, ml_task_hub:CurrentTask().lastPos.x, ml_task_hub:CurrentTask().lastPos.y) < 1))
end
function e_afkmove:execute()
	local myPos = Player.pos
	local newPos = NavigationManager:GetRandomPointOnCircle(myPos.x, myPos.y, myPos.z,0.5,1)
	local betterPos,dist = NavigationManager:GetClosestPointOnMesh(newPos)
	
	if (ValidTable(betterPos) and dist <= 5) then
		Player:MoveTo(betterPos.x, betterPos.y, betterPos.z, 0.5)
		ml_task_hub:CurrentTask().afkTimer = ml_global_information.Now + math.random(15000,25000)
		ml_task_hub:CurrentTask().lastPos = betterPos
	end
end

function ffxiv_task_pvp:Init()
    --init Process() cnes	
	local ke_pressConfirm = ml_element:create( "ConfirmDuty", c_pressconfirm, e_pressconfirm, 10 )
    self:add(ke_pressConfirm, self.process_elements)
	
	local ke_pressLeave = ml_element:create( "LeaveColosseum", c_pressleave, e_pressleave, 10 )
    self:add(ke_pressLeave, self.process_elements)
    
    local ke_pressJoin = ml_element:create( "JoinDutyFinder", c_joinqueuepvp, e_joinqueuepvp, 10 )
    self:add(ke_pressJoin, self.process_elements)
    
    local ke_startCombat = ml_element:create( "StartCombat", c_startcombat, e_startcombat, 5 )
    self:add(ke_startCombat, self.process_elements)
	
	local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 5 )
    self:add( ke_dead, self.process_elements)
	
	local ke_afkMove = ml_element:create( "AFKMove", c_afkmove, e_afkmove, 5 )
    self:add( ke_afkMove, self.process_elements)
  
    self:AddTaskCheckCEs()
end

-- custom process function for optimal performance
function ffxiv_task_pvp:Process()
    -- only perform combat logic when we are in the wolves den
    if ((Player.localmapid == 337 or Player.localmapid == 336 or Player.localmapid == 175) and Player.alive) then
        if (ml_task_hub:CurrentTask().state == "COMBAT_STARTED") then
			-- if we got slept then stop any current movement attempts
			if (HasBuff(Player.id,3) or HasBuff(Player.id,280) or HasBuff(Player.id,13)) then
				Player:Stop()
			end

          -- first check for an optimal target
			local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
			if (	TimeSince(ml_task_hub:CurrentTask().targetTimer) > 1000 or
					ml_task_hub:CurrentTask().targetid == 0 or
					(target ~= nil and (not target.alive or HasBuff(target.id,3) or HasBuff(target.id,390) or HasBuff(397)))) 
			then
				local newTarget = GetPVPTarget()
				if ValidTable(newTarget) and newTarget.id ~= ml_task_hub:CurrentTask().targetid then
					ml_task_hub:CurrentTask().targetid = newTarget.id
				end
				ml_task_hub:CurrentTask().targetTimer = ml_global_information.Now
			end
			
            -- second try to cast if we're within range or a healer
			local maxRange = GetMaxAttackRange()
			target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
			if ValidTable(target) then
				local pos = target.pos
				Player:SetTarget(target.id)
				Player:SetFacing(pos.x,pos.y,pos.z)
				SkillMgr.Cast( target )
				
				if Player.role ~= 4 then
					local dist = Distance2D(Player.pos.x,Player.pos.z,pos.x,pos.z)
					if (ml_global_information.AttackRange > 5) then
						if InCombatRange(target.id) then
							Player:SetFacing(pos.x,pos.y,pos.z)
							SkillMgr.Cast( target )
						else
							if (Distance2D(Player.pos.x,Player.pos.z,pos.x,pos.z) > 1) then
								local PathSize = Player:MoveTo(pos.x,pos.y,pos.z, 1, false, false)
							end
							Player:SetFacing(pos.x,pos.y,pos.z)
							SkillMgr.Cast( target )
						end
					else
						if (dist > 10 or target.los) then
							local path = Player:MoveTo(pos.x,pos.y,pos.z, 1, false, false)
						elseif (dist > 1) then
							local PathSize = Player:MoveTo(pos.x,pos.y,pos.z, 1, true, false)
						end
						Player:SetFacing(pos.x,pos.y,pos.z)
						SkillMgr.Cast( target )
					end
				else
					if InCombatRange(target.id) then
						local cast = false
						if (Player.hp.percent < 75 ) then
							cast = SkillMgr.Cast( Player, false, true )
						end
						if not cast then		
							Player:SetFacing(pos.x,pos.y,pos.z)
							SkillMgr.Cast( target )
						end
					else
						if (Distance3D(Player.pos.x,Player.pos.y,Player.pos.z,pos.x,pos.y,pos.z) > maxRange) then
							local PathSize = Player:MoveTo( tonumber(pos.x),tonumber(pos.y),tonumber(pos.z),tonumber(maxRange * .90),false,gRandomPaths=="0")
						else
							Player:SetFacing(pos.x,pos.y,pos.z)
							SkillMgr.Cast(Player)
						end
					end
				end
			elseif Player.role == 4 then
				SkillMgr.Cast( Player )
			end
        else
           SkillMgr.Cast( Player , true )
        end
    end
      
    -- last run the regular cne elements

    if (TableSize(self.process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(self.process_elements)
		if (self:superClass() and TableSize(self:superClass().process_elements) > 0) then
			ml_cne_hub.eval_elements(self:superClass().process_elements)
		end
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end

function ffxiv_task_pvp:OnSleep()

end

function ffxiv_task_pvp:OnTerminate()

end

function ffxiv_task_pvp:IsGoodToAbort()

end

-- UI settings etc
function ffxiv_task_pvp.UIInit()
    GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].pvpTargetOne,"gPVPTargetOne",strings[gCurrentLanguage].pvpMode,"")
    GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].pvpTargetTwo,"gPVPTargetTwo",strings[gCurrentLanguage].pvpMode,"")
	GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].pvpTargetThree,"gPVPTargetThree",strings[gCurrentLanguage].pvpMode,"")
	GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].pvpTargetFour,"gPVPTargetFour",strings[gCurrentLanguage].pvpMode,"")
	GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].pvpTargetFive,"gPVPTargetFive",strings[gCurrentLanguage].pvpMode,"")
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].prioritizeRanged, "gPrioritizeRanged",strings[gCurrentLanguage].pvpMode)
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].antiAFKMove, "gAFKMove",strings[gCurrentLanguage].pvpMode)
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].delayLeave, "gPVPDelayLeave",strings[gCurrentLanguage].pvpMode)
	--GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].pvpFlee, "gPVPFlee",strings[gCurrentLanguage].pvpMode)

    --init combo boxes
    local targetTypeList = strings[gCurrentLanguage].healer..","..strings[gCurrentLanguage].dps..","..strings[gCurrentLanguage].tank
	targetTypeList = targetTypeList..","..strings[gCurrentLanguage].sleeper..","..strings[gCurrentLanguage].caster..","..strings[gCurrentLanguage].ranged
	targetTypeList = targetTypeList..","..strings[gCurrentLanguage].nearDead..","..strings[gCurrentLanguage].nearest..","..strings[gCurrentLanguage].lowestHealth
    
	gPVPTargetOne_listitems = targetTypeList
    gPVPTargetTwo_listitems = targetTypeList
	gPVPTargetThree_listitems = targetTypeList
	gPVPTargetFour_listitems = targetTypeList
	gPVPTargetFive_listitems = targetTypeList
    
    if (Settings.FFXIVMINION.gPVPTargetOne == nil) then
        Settings.FFXIVMINION.gPVPTargetOne = "Healer"
    end
    
    if (Settings.FFXIVMINION.gPVPTargetTwo == nil) then
        Settings.FFXIVMINION.gPVPTargetTwo = "Lowest Health"
    end
	
	if (Settings.FFXIVMINION.gPVPTargetThree == nil) then
        Settings.FFXIVMINION.gPVPTargetThree = "Lowest Health"
    end
	
	if (Settings.FFXIVMINION.gPVPTargetFour == nil) then
        Settings.FFXIVMINION.gPVPTargetFour = "Lowest Health"
    end
	
	if (Settings.FFXIVMINION.gPVPTargetFive == nil) then
        Settings.FFXIVMINION.gPVPTargetFive = "Lowest Health"
    end
    
    if (Settings.FFXIVMINION.gPrioritizeRanged == nil) then
        Settings.FFXIVMINION.gPrioritizeRanged = "0"
    end
	
	if (Settings.FFXIVMINION.gAFKMove == nil) then
        Settings.FFXIVMINION.gAFKMove = "1"
    end
    
    if (Settings.FFXIVMINION.gPVPDelayLeave == nil) then
        Settings.FFXIVMINION.gPVPDelayLeave = "0"
    end
	
	--if (Settings.FFXIVMINION.gPVPFlee == nil) then
        --Settings.FFXIVMINION.gPVPFlee = "0"
    --end
    
    GUI_SizeWindow(ml_global_information.MainWindow.Name,250,400)
	
    gPVPTargetOne = Settings.FFXIVMINION.gPVPTargetOne
    gPVPTargetTwo = Settings.FFXIVMINION.gPVPTargetTwo
	gPVPTargetThree = Settings.FFXIVMINION.gPVPTargetThree
	gPVPTargetFour = Settings.FFXIVMINION.gPVPTargetFour
	gPVPTargetFive = Settings.FFXIVMINION.gPVPTargetFive
    gPrioritizeRanged = Settings.FFXIVMINION.gPrioritizeRanged
    gAFKMove = Settings.FFXIVMINION.gAFKMove
    gPVPDelayLeave = Settings.FFXIVMINION.gPVPDelayLeave
	--gPVPFlee = Settings.FFXIVMINION.gPVPFlee
end

function ffxiv_task_pvp.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gPVPTargetOne" or
                k == "gPVPTargetTwo" or
				k == "gPVPTargetThree" or
				k == "gPVPTargetFour" or
				k == "gPVPTargetFive" or
                k == "gPrioritizeRanged" or
                k == "gAFKMove" or
                k == "gPVPFlee" or
                k == "gPVPDelayLeave")
        then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

RegisterEventHandler("GUI.Update",ffxiv_task_pvp.GUIVarUpdate)

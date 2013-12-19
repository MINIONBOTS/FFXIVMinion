ffxiv_task_pvp = inheritsFrom(ml_task)
ffxiv_task_pvp.name = "LT_PVP"

function ffxiv_task_pvp:Create()
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
    newinst.combatStarted = false
    newinst.queued = false
    newinst.queueTimer = 0
    newinst.windowTimer = 0
    
    --this is the targeting function that will be used for the generic KillTarget task
    newinst.targetFunction = GetPVPTarget
    
    return newinst
end

c_joinqueue = inheritsFrom( ml_cause )
e_joinqueue = inheritsFrom( ml_effect )
function c_joinqueue:evaluate() 
    return ((   Player.localmapid ~= 337 and Player.localmapid ~= 175 and Player.localmapid ~= 336) and 
                TimeSince(ml_task_hub:CurrentTask().queueTimer) > math.random(10000,15000) and not 
                ml_task_hub:CurrentTask().queued)
end
function e_joinqueue:execute()
	d("Combat started = "..tostring(ml_task_hub:CurrentTask().combatStarted))
    if not ControlVisible("ContentsFinder") then
        ActionList:Cast(33,0,10)
        ml_task_hub:CurrentTask().windowTimer = ml_global_information.Now
    elseif (TimeSince(ml_task_hub:CurrentTask().windowTimer) > math.random(4000,5000)) then
        PressDutyJoin()
        ml_task_hub:CurrentTask().queued = true
    end
end

c_pressconfirm = inheritsFrom( ml_cause )
c_pressconfirm.throttle = 10000
e_pressconfirm = inheritsFrom( ml_effect )
function c_pressconfirm:evaluate() 
    return ((Player.localmapid ~= 337 and Player.localmapid ~= 175 and Player.localmapid ~= 336) and ControlVisible("ContentsFinderConfirm"))
end
function e_pressconfirm:execute()
    PressDutyConfirm(true)
end

c_pressleave = inheritsFrom( ml_cause )
c_pressleave.throttle = 10000
e_pressleave = inheritsFrom( ml_effect )
function c_pressleave:evaluate() 
    return ((Player.localmapid == 337 or Player.localmapid == 336 or Player.localmapid == 175) and ControlVisible("ColosseumRecord"))
end
function e_pressleave:execute()
    ml_task_hub:CurrentTask().combatStarted = false
    ml_task_hub:CurrentTask().queued = false
	ml_task_hub:CurrentTask().targetid = 0
    ml_task_hub:CurrentTask().queueTimer = ml_global_information.Now
    Player:Stop()
    PressLeaveColosseum()
end

c_startcombat = inheritsFrom( ml_cause )
e_startcombat = inheritsFrom( ml_effect )
function c_startcombat:evaluate()
    --ml_debug("startcombat eval - combat started = "..tostring(ml_task_hub:CurrentTask().combatStarted).."; startTime = "..tostring(ml_task_hub:CurrentTask().startTime).."; timesince = "..tostring(TimeSince(ml_task_hub:CurrentTask().startTime)))
    -- just in case we restart lua while in pvp combat
    if ((Player.localmapid == 337 or Player.localmapid == 336 or Player.localmapid == 175) and (Player.incombat or InCombatRange(ml_task_hub:CurrentTask().targetid))) then
        return true
    end

    if ((Player.localmapid == 337 or Player.localmapid == 336 or Player.localmapid == 175) and not ml_task_hub:CurrentTask().combatStarted) then
        local party = EntityList("myparty")
        local maxdistance = 0
        if (ValidTable(party)) then
            local i, e = next(party)
            while i ~= nil and e ~= nil do
                if e.incombat then return true end
                if e.distance > maxdistance then
                    maxdistance = e.distance
                end
            i, e = next(party, i)
            end
        end
        
        if maxdistance > 30 then
            return true
        end
            
        return false
    end
    
    return false
end
function e_startcombat:execute()
    ml_task_hub:CurrentTask().combatStarted = true
end

c_movetotargetpvp = inheritsFrom( ml_cause )
e_movetotargetpvp = inheritsFrom( ml_effect )
function c_movetotargetpvp:evaluate()
    if (ml_task_hub:CurrentTask().targetid and ml_task_hub:CurrentTask().targetid ~= 0 and Player.alive) then
        local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
        return ValidTable(target) and not InCombatRange(target.id)
    end
    
    return false

    -- will we need this?
    --if (ActionList:IsCasting()) then
    --    return false
    --end
end
function e_movetotargetpvp:execute()
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
    if ValidTable(target) then
        local gotoPos = target.pos
        ml_debug( "Moving to ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")	
        local PathSize = Player:MoveTo( tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z),1.0, 
                                        ml_task_hub.CurrentTask().useFollowMovement or false,gRandomPaths=="1")
    end
end

c_attarget = inheritsFrom( ml_cause )
e_attarget = inheritsFrom( ml_effect )
function c_attarget:evaluate()
    if (Player:IsMoving()) then
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
function e_attarget:execute()
    Player:Stop()
end

function ffxiv_task_pvp:Init()
    --init Process() cnes
    local ke_atTarget = ml_element:create( "AtTarget", c_attarget, e_attarget, 15 )
    self:add(ke_atTarget, self.process_elements)
    
    local ke_moveToTargetPVP = ml_element:create( "MoveToTargetPVP", c_movetotargetpvp, e_movetotargetpvp, 10 )
    self:add(ke_moveToTargetPVP, self.process_elements)
	
	local ke_pressConfirm = ml_element:create( "ConfirmDuty", c_pressconfirm, e_pressconfirm, 10 )
    self:add(ke_pressConfirm, self.process_elements)
	
	local ke_pressLeave = ml_element:create( "LeaveColosseum", c_pressleave, e_pressleave, 10 )
    self:add(ke_pressLeave, self.process_elements)
    
    local ke_pressJoin = ml_element:create( "JoinDutyFinder", c_joinqueue, e_joinqueue, 10 )
    self:add(ke_pressJoin, self.process_elements)
    
    local ke_startCombat = ml_element:create( "StartCombat", c_startcombat, e_startcombat, 5 )
    self:add(ke_startCombat, self.process_elements)
  
    self:AddTaskCheckCEs()
end

-- custom process function for optimal performance
function ffxiv_task_pvp:Process()
    -- only perform combat logic when we are in the wolves den
    if ((Player.localmapid == 337 or Player.localmapid == 336 or Player.localmapid == 175) and ml_task_hub.CurrentTask().combatStarted and Player.alive) then
        -- first check for an optimal target
        local target = GetPVPTarget()
        if ValidTable(target) and target.id ~= self.targetid then
            ml_task_hub.CurrentTask().targetid = target.id
        end
        
        -- second try to cast if we're within range or a healer
        if ((InCombatRange(ml_task_hub.CurrentTask().targetid) or Player.role == 4) and ValidTable(target)) then
            local pos = target.pos
            
            if not HasBuff(Player.id,3) then
                Player:SetFacing(pos.x,pos.y,pos.z)
            end
            Player:SetTarget(ml_task_hub:CurrentTask().targetid)
            
            local cast = false
        
            if (Player.hp.percent < 75 )then
                cast = SkillMgr.Cast( Player )
            end
            if not cast then			
                SkillMgr.Cast( target )
            end	
        end
    else
		Player:Stop()
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
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].prioritizeRanged, "gPrioritizeRanged",strings[gCurrentLanguage].pvpMode)

    --init combo boxes
    local targetTypeList = strings[gCurrentLanguage].healer..","..strings[gCurrentLanguage].dps..","..strings[gCurrentLanguage].tank..","..strings[gCurrentLanguage].nearest..","..strings[gCurrentLanguage].lowestHealth
    gPVPTargetOne_listitems = targetTypeList
    gPVPTargetTwo_listitems = targetTypeList
    
    if (Settings.FFXIVMINION.gPVPTargetOne == nil) then
        Settings.FFXIVMINION.gPVPTargetOne = "Healer"
    end
    
    if (Settings.FFXIVMINION.gPVPTargetTwo == nil) then
        Settings.FFXIVMINION.gPVPTargetTwo = "Lowest Health"
    end
    
    if (Settings.FFXIVMINION.gPrioritizeRanged == nil) then
        Settings.FFXIVMINION.gPrioritizeRanged = "0"
    end
    
    GUI_SizeWindow(ml_global_information.MainWindow.Name,250,400)
	
    gPVPTargetOne = Settings.FFXIVMINION.gPVPTargetOne
    gPVPTargetTwo = Settings.FFXIVMINION.gPVPTargetTwo
    gPrioritizeRanged = Settings.FFXIVMINION.gPrioritizeRanged
end

function ffxiv_task_pvp.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gPVPTargetOne" or
                k == "gPVPTargetTwo" or
                k == "gPrioritizeRanged" )
        then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

RegisterEventHandler("GUI.Update",ffxiv_task_pvp.GUIVarUpdate)

---------------------------------------------------------------------------------------------
--LONGTERM GOALS--
--These are strategy level tasks which incorporate multiple layers of subtasks and reactive
--tasks to complete a specific action. They should generally be placed near the root level
--of task in the LONGTERM task queue
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--TASK_KILLTARGET: LongTerm Goal - Kill the specified target
---------------------------------------------------------------------------------------------
ffxiv_task_killtarget = inheritsFrom(ml_task)

function ffxiv_task_killtarget:Create()
    local newinst = inheritsFrom(ffxiv_task_killtarget)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_grind members
    newinst.name = "LT_KILLTARGET"
    newinst.targetid = 0
    newinst.targetFunction = 0
    
    return newinst
end

function ffxiv_task_killtarget:Init()
	--init ProcessOverWatch() cnes
	local ke_moveToTarget = ml_element:create( "AddMoveToTarget", c_add_movetotarget, e_add_movetotarget, 5 )
	self:add( ke_moveToTarget, self.overwatch_elements)
	
    --Process() cnes
	local ke_combat = ml_element:create( "AddCombat", c_add_combat, e_add_combat, ml_effect.priorities.interrupt )
	self:add( ke_combat, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_killtarget:OnSleep()

end

function ffxiv_task_killtarget:OnTerminate()

end

function ffxiv_task_killtarget:IsGoodToAbort()

end

function ffxiv_task_killtarget:task_complete_eval()
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
    if (not target or (target and not target.alive)) then
		return true
    end
    
    return false
end

function ffxiv_task_killtarget:task_complete_execute()
    self.completed = true
end

---------------------------------------------------------------------------------------------
--TASK_FATE: Longterm Goal - Complete a fate event successfully
---------------------------------------------------------------------------------------------
ffxiv_task_fate = inheritsFrom(ml_task)

function ffxiv_task_fate:Create()
    local newinst = inheritsFrom(ffxiv_task_fate)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_fate members
    newinst.name = "LT_FATE"
    newinst.fateid = 0
    newinst.targetFunction = GetNearestFateAttackable
    
    return newinst
end

function ffxiv_task_fate:Init()
    --init processoverwatch 
    local ke_moveToFate = ml_element:create( "AddMoveToFate", c_add_movetofate, e_add_movetofate, 10 )
	self:add( ke_moveToFate, self.overwatch_elements)
    
    --init process
	local ke_noTarget = ml_element:create( "NoTarget", c_notarget, e_notarget, 10 )
	self:add(ke_noTarget, self.process_elements)
	
    local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_killtarget, e_add_killtarget, 5 )
	self:add(ke_addKillTarget, self.process_elements)
    
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_fate:task_complete_eval()
    local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
	if (fate ~= nil and fate ~= {}) then
		return fate.completion > 95
    elseif (fate == nil) then
		return true
	end
	
    return false
end

function ffxiv_task_fate:task_complete_execute()
    self.completed = true
end

function ffxiv_task_fate:task_fail_eval()

end

function ffxiv_task_fate:task_fail_execute()
    self.valid = false
end

function ffxiv_task_fate:OnSleep()

end

function ffxiv_task_fate:OnTerminate()

end

function ffxiv_task_fate:IsGoodToAbort()

end

---------------------------------------------------------------------------------------------
--REACTIVE GOALS--
--These are tasks which may be called in reaction to changes in the game state, such as
--mob movement/aggro. They should be placed in the REACTIVE queue and continue to pulse 
--there until they are completed and control returns to the LONGTERM queue rootTask. 
--They are generally placed in the ProcessOverWatch element list of a strategy level
--task since they need to monitor game state changes continually.
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--TASK_MOVETOPOS: Reactive Goal - Move to the specified position
--This task moves the player to a specified position, and contains overwatch checks for
--both gathering and combat. When used for grinding/questing, it should check for mob
--aggro and either kill the mob or flee. When used for gathering, it should check for
--mobs BEFORE aggro range and stealth to avoid combat.
---------------------------------------------------------------------------------------------
ffxiv_task_movetopos = inheritsFrom(ml_task)

function ffxiv_task_movetopos:Create()
    local newinst = inheritsFrom(ffxiv_task_movetopos)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_grind members
    newinst.name = "RE_MOVETOPOS"
    newinst.pos = 0
	newinst.range = 0
	newinst.doFacing = 0
    newinst.pauseTimer = 0
	
    return newinst
end

function ffxiv_task_movetopos:Init()
	local ke_stealth = ml_element:create( "Stealth", c_stealth, e_stealth, 15 )
	self:add( ke_stealth, self.overwatch_elements)

	local ke_moveToPos = ml_element:create( "MoveToPos", c_movetopos, e_movetopos, 10 )
	self:add( ke_moveToPos, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetopos:task_complete_eval()
	if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= {} ) then
		local myPos = Player.pos
		local gotoPos = ml_task_hub:CurrentTask().pos
		local distance = Distance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
		if (distance < self.range+0.1) then
			return true
		end
    end
    
    return false
end

function ffxiv_task_movetopos:task_complete_execute()
	ml_task_hub:CurrentTask().completed = true
end

function ffxiv_task_movetopos:OnSleep()

end

function ffxiv_task_movetopos:OnTerminate()

end

function ffxiv_task_movetopos:IsGoodToAbort()

end

---------------------------------------------------------------------------------------------
--TASK_MOVETOTARGET: Reactive Goal - Move to the position of the (possibly moving) target
--This task varies slightly from the MOVETOPOS task as it continually updates the MoveTo
--command based on the position of the target in order to properly track mobs over longer
--distances. It should be used both when moving to engage mobs in combat and placed in the
--ProcessOverWatch element list so that it will automatically follow a mob who moves out
--of combat range.
---------------------------------------------------------------------------------------------
ffxiv_task_movetotarget = inheritsFrom(ml_task)

function ffxiv_task_movetotarget:Create()
    local newinst = inheritsFrom(ffxiv_task_movetotarget)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_grind members
    newinst.name = "RE_MOVETOTARGET"
    newinst.targetid = 0
	newinst.range = 0
	
    return newinst
end

function ffxiv_task_movetotarget:Init()
	local ke_moveToTarget = ml_element:create( "MoveToTarget", c_movetotarget, e_movetotarget, 10 )
	self:add( ke_moveToTarget, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetotarget:task_complete_eval()
	if ( ml_task_hub:CurrentTask().targetid ~= nil and ml_task_hub:CurrentTask().targetid ~= 0 ) then
        local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
        if (target == nil) then
			return true
		else
            if (target.distance <= self.range + target.hitradius +0.1 or not target.alive) then
                return true
            end
        end
    end
    
    return false
end

function ffxiv_task_movetotarget:task_complete_execute()
    ml_task_hub:CurrentTask().completed = true
end

function ffxiv_task_movetotarget:OnSleep()

end

function ffxiv_task_movetotarget:OnTerminate()

end

function ffxiv_task_movetotarget:IsGoodToAbort()

end

---------------------------------------------------------------------------------------------
--TASK_MOVETOFATE: Reactive - Move to the position of the fate specified by fateid
--This task moves to the position of the current fate target. It differs from the other
--MoveTo tasks by continually checking for closer fates so that it will stop if a new
--fate spawns during travel rather than skipping it. It should also contain overwatch
--checks for aggro and check a user variable to determine whether to stop and fight
--or ignore aggro and continue on to the current fate location.
---------------------------------------------------------------------------------------------

ffxiv_task_movetofate = inheritsFrom(ml_task)

function ffxiv_task_movetofate:Create()
    local newinst = inheritsFrom(ffxiv_task_movetofate)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetofate members
    newinst.name = "RE_MOVETOFATE"
    newinst.fateid = 0
	
    return newinst
end

function ffxiv_task_movetofate:Init()
	local ke_moveToFate = ml_element:create( "MoveToFate", c_movetofate, e_movetofate, 10 )
	self:add( ke_moveToFate, self.process_elements)
	
	local ke_betterFate = ml_element:create( "BetterFateSearch", c_betterfatesearch, e_betterfatesearch, 15 )
	self:add( ke_betterFate, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetofate:task_complete_eval()
	if ( ml_task_hub:CurrentTask().fateid ~= nil and ml_task_hub:CurrentTask().fateid ~= 0 ) then
        local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
        if (fate ~= nil and fate ~= {}) then
			local myPos = Player.pos
			local distance = Distance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z)
            if (distance < 0.5 * (fate.radius)) then
                return true
            end
        else
			return true
		end
    end
    
    return false
end

function ffxiv_task_movetofate:task_complete_execute()
    ml_task_hub:CurrentTask().completed = true
end

function ffxiv_task_movetofate:OnSleep()

end

function ffxiv_task_movetofate:OnTerminate()

end

function ffxiv_task_movetofate:IsGoodToAbort()

end
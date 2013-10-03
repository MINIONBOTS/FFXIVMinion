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
	
	local ke_attarget = ml_element:create("ATTarget", c_attarget, e_attarget, 10)
	self:add( ke_attarget, self.overwatch_elements)
	
	local ke_updateTarget = ml_element:create("UpdateTarget", c_updatetarget, e_updatetarget, 5)
	self:add( ke_updateTarget, self.overwatch_elements)
		
    --Process() cnes		    
	local ke_moveToTarget = ml_element:create( "MoveToTarget", c_movetotarget, e_movetotarget, 10 )
	self:add( ke_moveToTarget, self.process_elements)
	
	local ke_combat = ml_element:create( "AddCombat", c_add_combat, e_add_combat, 5 )
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
	local ke_betterFate = ml_element:create( "BetterFateSearch", c_betterfatesearch, e_betterfatesearch, 15 )
	self:add( ke_betterFate, self.overwatch_elements)
	
    --init process
	local ke_moveToFate = ml_element:create( "MoveToFate", c_movetofate, e_movetofate, 15 )
	self:add( ke_moveToFate, self.process_elements)
	
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
--This task moves the player to a specified position, the partent of this task needs to make sure
--that this movetopos task has up2date positions and is still valid.
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
    
    --ffxiv_task_movetopos members
    newinst.name = "MOVETOPOS"
    newinst.pos = 0
	newinst.range = 1.5
	newinst.doFacing = 0
    newinst.pauseTimer = 0
	
    return newinst
end

function ffxiv_task_movetopos:Init()
	-- TODO: Chocobo, Sprint n waypoint usage goes here
	-- The parent needs to take care of checking and updating the position of this task!!	
	local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 10 )
	self:add( ke_walkToPos, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetopos:task_complete_eval()
	if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= {} ) then
		local myPos = Player.pos
		local gotoPos = ml_task_hub:CurrentTask().pos
		local distance = Distance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
		if (distance <= self.range + 1) then
			return true
		end
    end    
    return false
end

function ffxiv_task_movetopos:task_complete_execute()
	Player:Stop()
	ml_task_hub:CurrentTask().completed = true
end

function ffxiv_task_movetopos:OnSleep()

end

function ffxiv_task_movetopos:OnTerminate()

end

function ffxiv_task_movetopos:IsGoodToAbort()

end

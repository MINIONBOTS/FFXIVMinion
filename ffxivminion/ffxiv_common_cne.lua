---------------------------------------------------------------------------------------------
--ADD_TASK CNEs
--These are cnes which are used to check the current game state and add a new task/subtask
--based on the needs of the parent task they are assigned to. They differ from the task
--completion CNEs since they don't perform any action other than to queue a new task. 
--Every task must have a CNE like this to queue it when appropriate. They can be placed
--in either the process elements or the overwatch elements for a task based on the priority
--of the task they queue. MOVETOTARGET, for instance, should be placed in the overwatch
--list since it needs to be checked continually for moving targets; COMBAT can be placed
--into the process list since there is no need to queue another combat task until the
--previous combat task is completed and control returns to the parent task.
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--ADD_KILLTARGET: If (current target hp > 0) Then (add longterm killtarget task)
--Adds a killtarget task if target hp > 0
---------------------------------------------------------------------------------------------
c_add_killtarget = inheritsFrom( ml_cause )
e_add_killtarget = inheritsFrom( ml_effect )
function c_add_killtarget:evaluate()
	if (ml_task_hub:CurrentTask().name == "LT_GRIND" and gFatesOnly == "1") then
		return false
	end
	
	local target = ml_task_hub:CurrentTask().targetFunction()
	if (target ~= nil and target ~= {}) then
		if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0) then
			c_add_killtarget.targetid = target.id
			return true
		end
	end
    
    return false
end
function e_add_killtarget:execute()
	Player:SetTarget(c_add_killtarget.targetid)
	local newTask = ffxiv_task_killtarget:Create()
    newTask.targetFunction = ml_task_hub:CurrentTask().targetFunction
    newTask.targetid = c_add_killtarget.targetid
	ml_task_hub.CurrentTask():AddSubTask(newTask)
end

---------------------------------------------------------------------------------------------
--ADD_MOVETOTARGET: If (current target distance > combat range) Then (add movetotarget task)
--Adds a MoveToTarget task 
---------------------------------------------------------------------------------------------
c_add_movetotarget = inheritsFrom( ml_cause )
e_add_movetotarget = inheritsFrom( ml_effect )
function c_add_movetotarget:evaluate()
	if ( ml_task_hub.CurrentTask().targetid ~= nil and ml_task_hub.CurrentTask().targetid ~= 0 ) then
		local target = EntityList:Get(ml_task_hub.CurrentTask().targetid)
		if (target ~= nil and target ~= {}) then
			if (target.distance > ml_global_information.AttackRange + target.hitradius or not target.los) then				
				return true
			end
		end
	end
    
    return false
end
function e_add_movetotarget:execute()
	--ml_debug( "Moving to within combat range of target" )
	local target = EntityList:Get(ml_task_hub.CurrentTask().targetid)
	if (target ~= nil and target.pos ~= nil) then
		local newTask = ffxiv_task_movetotarget:Create()
		newTask.targetid = target.id
		newTask.range = (ml_global_information.AttackRange-1) + target.hitradius
		newTask.losrange = newTask.range
		ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_ASAP)
	end
end

---------------------------------------------------------------------------------------------
--ADD_COMBAT: If (target hp > 0) Then (add combat task)
--Adds a task to use a combat routine to attack/kill target 
---------------------------------------------------------------------------------------------
c_add_combat = inheritsFrom( ml_cause )
e_add_combat = inheritsFrom( ml_effect )
function c_add_combat:evaluate()
	local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
	if target ~= nil and target ~= {} then
		local targetPos = target.pos
		Player:SetFacing(targetPos.x,targetPos.y,targetPos.z)
		Player:SetTarget(ml_task_hub:CurrentTask().targetid)
		local target = Player:GetTarget()
		if(target ~= nil) then
			if (target.id == ml_task_hub:CurrentTask().targetid) then			
				if(target.hp.current > 0) then
					return true
				end
			end
		end
	end
		
    return false
end
function e_add_combat:execute()
	if ( gSMactive == "1" ) then
		local newTask = ffxiv_task_skillmgrAttack:Create()
		newTask.targetid = ml_task_hub:CurrentTask().targetid
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	else
		local newTask = ml_global_information.CurrentClass:Create()
		newTask.targetid = ml_task_hub:CurrentTask().targetid
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	end
end

---------------------------------------------------------------------------------------------
--ADD_FATE: If (fate of proper level is on mesh) Then (add longterm fate task)
--Adds a fate task if there is a fate on the mesh
---------------------------------------------------------------------------------------------
c_add_fate = inheritsFrom( ml_cause )
e_add_fate = inheritsFrom( ml_effect )
function c_add_fate:evaluate()
	if (gDoFates == "1") then
		local myPos = Player.pos
		local fateID = GetClosestFateID(myPos, true, true)
		if (fateID ~= 0) then
			return true
		end
	end
	
    return false
end
function e_add_fate:execute()
	local newTask = ffxiv_task_fate:Create()
	local myPos = Player.pos
    newTask.fateid = GetClosestFateID(myPos, true, true)
	ml_task_hub.CurrentTask():AddSubTask(newTask)
end

---------------------------------------------------------------------------------------------
--ADD_MOVETOFATE: If (current fate distance > combat range) Then (add movetofate task)
--Moves within range of fate specified by ml_task_hub.CurrentTask().fateid
---------------------------------------------------------------------------------------------
c_add_movetofate = inheritsFrom( ml_cause )
e_add_movetofate = inheritsFrom( ml_effect )
function c_add_movetofate:evaluate()
	if ( ml_task_hub:CurrentTask().fateid ~= nil and ml_task_hub:CurrentTask().fateid ~= 0 ) then
		local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
		if (fate ~= nil and fate ~= {}) then
			local myPos = Player.pos
			local distance = Distance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z)
			if (distance > fate.radius) then				
				return true
			end
		end
	end
    
    return false
end
function e_add_movetofate:execute()
	--ml_debug( "Moving to fate" )
	local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
	if (fate ~= nil and fate ~= {}) then
		local newTask = ffxiv_task_movetofate:Create()
		newTask.fateid = fate.id
		ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_ASAP)
	end
end

---------------------------------------------------------------------------------------------
--Task Completion CNEs
--These are cnes which are added to the process element list for a task and exist only to
--complete the specified task. They should be specific to the task which contains them...
--their only purpose should be to check the current game state and adjust the behavior of 
--the task in order to ensure its completion. 
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--MOVETOTARGET: If (distance to target > range) Then (move to target pos)
--Updates continually with new positions every 500 ticks
---------------------------------------------------------------------------------------------
c_movetotarget = inheritsFrom( ml_cause )
e_movetotarget = inheritsFrom( ml_effect )
c_movetotarget.throttle = 500
function c_movetotarget:evaluate()
	if ( ml_task_hub:CurrentTask().targetid ~= nil and ml_task_hub:CurrentTask().targetid ~= 0 ) then
        local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
        if (target ~= nil) then
			--d("target.distance = "..tostring(target.distance))
			--d("ml_task_hub:CurrentTask().range =  "..tostring(ml_task_hub:CurrentTask().range))
			--d("target.hitradius = "..tostring(target.hitradius))
            if (target.distance > ml_task_hub:CurrentTask().range) then
                ml_task_hub:CurrentTask().pos = target.pos
                return true
			end
        end
    end
    
    return false
end
function e_movetotarget:execute()
	local gotoPos = ml_task_hub:CurrentTask().pos
	ml_debug( "Moving to ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")
	Player:MoveTo(gotoPos.x,gotoPos.y,gotoPos.z)
end

---------------------------------------------------------------------------------------------
--MOVETOPOS: If (distance to pos > range) Then (move to pos)
--Moves to position specified by ml_task_hub.CurrentTask().pos
---------------------------------------------------------------------------------------------
c_movetopos = inheritsFrom( ml_cause )
e_movetopos = inheritsFrom( ml_effect )
c_movetopos.throttle = 1000
function c_movetopos:evaluate()
	if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= {} ) then
		local myPos = Player.pos
		local gotoPos = ml_task_hub:CurrentTask().pos
		local distance = Distance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
		if (distance > ml_task_hub:CurrentTask().range+0.5) then
			return true
		end
    end
    
    return false
end
function e_movetopos:execute()
	local gotoPos = ml_task_hub:CurrentTask().pos
	ml_debug( "Moving to ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")
    Player:MoveTo(gotoPos.x,gotoPos.y,gotoPos.z,ml_task_hub.CurrentTask().range)
end


---------------------------------------------------------------------------------------------
--MOVETOFATE: If (current fate distance > combat range) Then (add movetopos task)
--Moves within range of fate specified by ml_task_hub.CurrentTask().fateid
---------------------------------------------------------------------------------------------
c_movetofate = inheritsFrom( ml_cause )
e_movetofate = inheritsFrom( ml_effect )
function c_movetofate:evaluate()
	if (Player:IsMoving()) then
		return false
	end
	
	if ( ml_task_hub:CurrentTask().fateid ~= nil and ml_task_hub:CurrentTask().fateid ~= 0 ) then
		local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
		if (fate ~= nil and fate ~= {}) then
			local myPos = Player.pos
			local distance = Distance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z)
			if (distance > fate.radius) then				
				return true
			end
		end
	end
    
    return false
end
function e_movetofate:execute()
	--ml_debug( "Moving to fate" )
	local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
	if (fate ~= nil and fate ~= {}) then
		local gotoPos = {x = fate.x, y = fate.y, z = fate.z}
		ml_debug( "Moving to ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")
		Player:MoveTo(gotoPos.x,gotoPos.y,gotoPos.z)
	end
end

---------------------------------------------------------------------------------------------
--REACTIVE/IMMEDIATE Game State CNEs
--These are cnes which are used to check the current game state and perform some kind of
--emergency action. They should generally be placed in the overwatch element list at an
--appropriate level in the subtask tree so that they can monitor all subtasks below them
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--NOTARGET: If (no current target) Then (find the nearest fate mob)
--Gets a new target using the targeting function of the parent task
---------------------------------------------------------------------------------------------
c_notarget = inheritsFrom( ml_cause )
e_notarget = inheritsFrom( ml_effect )
function c_notarget:evaluate()
	if ( ml_task_hub.CurrentTask().targetid == nil or ml_task_hub.CurrentTask().targetid == 0 ) then
		return true
    end
    
    local target = EntityList:Get(ml_task_hub.CurrentTask().targetid)
    if (target ~= nil) then
        if (not target.alive) then
            return true
        end
    elseif (target == nil) then
        return true
    end
    
    return false
end
function e_notarget:execute()
	ml_debug( "Getting new target" )
	local target = ml_task_hub:CurrentTask().targetFunction()
	if (target ~= nil) then
		Player:SetFacing(target.pos.x, target.pos.y, target.pos.z)
		Player:SetTarget(target.id)
		ml_task_hub.CurrentTask().targetid = target.id
	end
end

---------------------------------------------------------------------------------------------
--FLEE: If (aggolist.size > 1 and health.percent < 50) Then (run to a random point)
--Attempts to shake aggro by running away and resting
---------------------------------------------------------------------------------------------
c_flee = inheritsFrom( ml_cause )
e_flee = inheritsFrom( ml_effect )
e_flee.throttle = 1000
c_flee.fleeing = false
function c_flee:evaluate()
	if (not self.fleeing) then
		if (Player.hasaggro and Player.hp.percent < 30) then
			d("test2")
			self.fleeing = true
			return true
		end
	else
		d("test3")
		if (not Player.hasaggro) then
			d("test4")
			Player:Stop()
			self.fleeing = false
		end
	end
    
    return false
end
function e_flee:execute()
	ml_debug( "Fleeing combat" )
	d("flee execute")
	local fleePos = ffxiv_task_grind.evacPoint
	if (fleePos ~= {}) then
		Player:SetFacing(fleePos.x, fleePos.y, fleePos.z)
		Player:MoveTo(fleePos.x, fleePos.y, fleePos.z)
	end
end

---------------------------------------------------------------------------------------------
--REST: If (not player.hasAggro and player.hp.percent < 50) Then (do nothing)
--Blocks all subtask execution until player hp has increased
---------------------------------------------------------------------------------------------
c_rest = inheritsFrom( ml_cause )
e_rest = inheritsFrom( ml_effect )
function c_rest:evaluate()
	if (self.resting ~= nil) then
		if (self.resting == true) then
			if (Player.hp.percent > 90) then
				self.resting = false
				return false
			else
				self.resting = true
				return true
			end
		else
			if (Player.hp.percent < 50 and not Player.hasaggro) then
				self.resting = true
				return true
			end
		end
	elseif (Player.hp.percent < 50 and not Player.hasaggro) then
		self.resting = true
		return true
	end
    
	self.resting = false
    return false
end
function e_rest:execute()
	--do nothing, we will simply abort the current subtask
end

---------------------------------------------------------------------------------------------
--BETTERFATESEARCH: If (fate with < distance than current target exists) Then (select new fate)
--Clears the current fate and adds a new one if it finds a better match along the route
---------------------------------------------------------------------------------------------
c_betterfatesearch = inheritsFrom( ml_cause )
e_betterfatesearch = inheritsFrom( ml_effect )
function c_betterfatesearch:evaluate()
	local currentFate = GetFateByID(ml_task_hub:CurrentTask().fateid)
	if (currentFate ~= nil and currentFate ~= {}) then
		local myPos = Player.pos
		local closestFate = GetFateByID(GetClosestFateID(myPos, true, true))
		if (closestFate ~= nil and closestFate ~= {}) then
			
			local currentFateDist = Distance3D(myPos.x, myPos.y, myPos.z, currentFate.x, currentFate.y, currentFate.z)
			local newFateDist = Distance3D(myPos.x, myPos.y, myPos.z, closestFate.x, closestFate.y, closestFate.z)
			if (newFateDist < currentFateDist) then
				ml_task_hub:CurrentTask().fateid = closestFate.id
				return true
			end
		end
	end
    
    return false
end
function e_betterfatesearch:execute()
	--ml_debug( "Closer fate found" )
	local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
	if (fate ~= nil and fate ~= {}) then
		-- add new subtask for LT_GRIND
		if (ml_task_hub.queues[QUEUE_LONG_TERM]:HasOrders()) then
			local grindTask = ml_task_hub.queues[QUEUE_LONG_TERM].rootTask
			grindTask:DeleteSubTasks()
			local newTask = ffxiv_task_fate:Create()
			newTask.fateid = ml_task_hub:CurrentTask().fateid
			grindTask:AddSubTask(newTask)
		end
		
		if (ml_task_hub.queues[QUEUE_REACTIVE]:HasOrders()) then
			local moveToFateTask = ml_task_hub.queues[QUEUE_LONG_TERM].rootTask
			moveToFateTask:Terminate()
			
			local newTask = ffxiv_task_movetofate:Create()
			newTask.fateid = fate.id
			ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_ASAP)
		end
	end
end
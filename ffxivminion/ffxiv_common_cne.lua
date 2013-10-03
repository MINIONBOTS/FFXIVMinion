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
	-- this will block the fatetask from wroking if I'm not mistaken ...since it never picks a target to attack
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
	local newTask = ffxiv_task_killtarget:Create()
    newTask.targetFunction = ml_task_hub:CurrentTask().targetFunction
    newTask.targetid = c_add_killtarget.targetid
	ml_task_hub.CurrentTask():AddSubTask(newTask)
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
        return InCombatRange(target.id) and target.alive
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
--ADD_MOVETOTARGET: If (current target distance > combat range) Then (add movetotarget task)
--Adds a MoveToTarget task 
---------------------------------------------------------------------------------------------
c_movetotarget = inheritsFrom( ml_cause )
e_movetotarget = inheritsFrom( ml_effect )
function c_movetotarget:evaluate()
	if ( ml_task_hub.CurrentTask().targetid ~= nil and ml_task_hub.CurrentTask().targetid ~= 0 ) then
		local target = EntityList:Get(ml_task_hub.CurrentTask().targetid)
		if (target ~= nil and target ~= {} and target.alive) then
			return not InCombatRange(target.id)
		end
	end
    
    return false
end
function e_movetotarget:execute()
	ml_debug( "Moving within combat range of target" )
	local target = EntityList:Get(ml_task_hub.CurrentTask().targetid)
	if (target ~= nil and target.pos ~= nil) then
		local newTask = ffxiv_task_movetopos:Create()
		newTask.pos = target.pos
		newTask.targetid = target.id
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	end
end

-----------------------------------------------------------------------------------------------
--ADD_MOVETOFATE: If (current fate distance > fate.radius) Then (add movetofate task)
--Moves within range of fate specified by ml_task_hub.CurrentTask().fateid
---------------------------------------------------------------------------------------------
c_movetofate = inheritsFrom( ml_cause )
e_movetofate = inheritsFrom( ml_effect )
function c_movetofate:evaluate()
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
	ml_debug( "Moving to fate" )
	local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
	if (fate ~= nil and fate ~= {}) then
		local newTask = ffxiv_task_movetopos:Create()
		--TODO: Randomize position
		newTask.pos = {x = fate.x, y = fate.y, z = fate.z}
		newTask.range = math.random(1.5,fate.radius)
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	end
end

---------------------------------------------------------------------------------------------
--Task Completion CNEs
--These are cnes which are added to the process element list for a task and exist only to
--complete the specified task. They should be specific to the task which contains them...
--their only purpose should be to check the current game state and adjust the behavior of 
--the task in order to ensure its completion. 
---------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
--WALKTOPOS: If (distance to target > task.range) Then (move to pos)
---------------------------------------------------------------------------------------------
c_walktopos = inheritsFrom( ml_cause )
e_walktopos = inheritsFrom( ml_effect )
function c_walktopos:evaluate()
	if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0 ) then
        local myPos = Player.pos
		local tPos = ml_task_hub:CurrentTask().pos
		local distance = Distance3D(myPos.x, myPos.y, myPos.z, tPos.x, tPos.y, tPos.z)
		if (distance > ml_task_hub:CurrentTask().range) then				
			return true
		end
    end
    
    return false
end
function e_walktopos:execute()
	local gotoPos = ml_task_hub:CurrentTask().pos
	ml_debug( "Moving to ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")
    ml_debug( "Moving to Pathresult: "..tostring(Player:MoveTo(gotoPos.x,gotoPos.y,gotoPos.z,ml_task_hub.CurrentTask().range)))
end

-- The movetotask in the killtask needs to always have up2date data since the targt is also moving away sometimes. Therefore giving the movetopos task the data and let 
-- it handle the (dynamic) movement of enemies is better than just doing a "is in range, terminate movetopos", since it doesnt account for moving enemies if I haven't missed 
-- stuff so far. Also this way we can terminate the killtask when the enemy died meanwhile.
c_updatetarget = inheritsFrom( ml_cause )
e_updatetarget = inheritsFrom( ml_effect )
function c_updatetarget:evaluate()	
	if (ml_task_hub:ThisTask().targetid~=nil and ml_task_hub:ThisTask().targetid~=0)then
		local target = EntityList:Get(ml_task_hub.ThisTask().targetid)
		if (target ~= nil) then
			if (target.alive and target.targetable) then
				if (ml_task_hub:CurrentTask().name == "MOVETOPOS" ) then
					-- MOVETOPOS is moving to a static pos, the enemy moves, either update the MOVETOPOS.pos or create a new movetopos task with teh new positoon, I choose a)
					ml_task_hub:CurrentTask().pos = target.pos					
				end
				return false
			end
		end
	end	
	-- our target which we moveto (in order to kill) is not there anymore/dead/not selectable, we can kill the current killtask
	return true
end
function e_updatetarget:execute()
	Player:Stop()
	ml_task_hub:ThisTask():Terminate()
end

c_attarget = inheritsFrom( ml_cause )
e_attarget = inheritsFrom( ml_effect )
function c_attarget:evaluate()
	if (ml_task_hub:CurrentTask().name == "MOVETOPOS") then
		return InCombatRange(ml_task_hub:ThisTask().targetid)
	end
	return false
end
function e_attarget:execute()
	Player:Stop()
	ml_task_hub:CurrentTask():Terminate()
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
        if (not target.alive or not target.targetable) then
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
		ml_task_hub.CurrentTask().targetid = target.id
	end
end

---------------------------------------------------------------------------------------------
--FLEE: If (aggolist.size > 0 and health.percent < 50) Then (run to a random point)
--Attempts to shake aggro by running away and resting
---------------------------------------------------------------------------------------------
c_flee = inheritsFrom( ml_cause )
e_flee = inheritsFrom( ml_effect )
e_flee.throttle = 1000
function c_flee:evaluate()
    if (Player.hasaggro and Player.hp.percent < 50 or self.fleeing) then
        return true
	end
    
    return false
end
function e_flee:execute()
    if (self.fleeing) then
        if (not Player.hasaggro) then
			Player:Stop()
			self.fleeing = false
            return
		end
    else
        local fleePos = ffxiv_task_grind.evacPoint
        if (fleePos ~= {}) then
            ml_debug( "Fleeing combat" )
            Player:SetFacing(fleePos.x, fleePos.y, fleePos.z)
            Player:MoveTo(fleePos.x, fleePos.y, fleePos.z)
            self.fleeing = true
        end
    end
end

---------------------------------------------------------------------------------------------
--DEAD: Checks Revivestate of player and revives at nearest aetheryte, homepoint, favpoint or we shall see 
--Blocks all subtask execution until player is alive 
---------------------------------------------------------------------------------------------
c_dead = inheritsFrom( ml_cause )
e_dead = inheritsFrom( ml_effect )
function c_dead:evaluate()
	if (Player.revivestate == 2 or Player.revivestate == 3) then --FFXIV.REVIVESTATE.DEAD & REVIVING
		return true
	end 
    return false
end
function e_dead:execute()
	ml_debug("Respawning...")
	Player:Respawn()
end

---------------------------------------------------------------------------------------------
--REST: If (not player.hasAggro and player.hp.percent < 50) Then (do nothing)
--Blocks all subtask execution until player hp has increased
---------------------------------------------------------------------------------------------
c_rest = inheritsFrom( ml_cause )
e_rest = inheritsFrom( ml_effect )
function c_rest:evaluate()
	if (Player.hasaggro) then
		self.resting = false
		return false
	end
	
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
			if (Player.hp.percent < 60 and not Player.hasaggro) then
				self.resting = true
				return true
			end
		end
	elseif (Player.hp.percent < 60 and not Player.hasaggro) then
		self.resting = true
		return true
	end
    
	self.resting = false
    return false
end
function e_rest:execute()	
	if ( gSMactive == "1" ) then
		local newTask = ffxiv_task_skillmgrHeal:Create()
		newTask.targetid = Player.id
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	else
		--do nothing, we will simply abort the current subtask
	end
end

---------------------------------------------------------------------------------------------
--BETTERFATESEARCH: If (fate with < distance than current target exists) Then (select new fate)
--Clears the current fate and adds a new one if it finds a better match along the route
---------------------------------------------------------------------------------------------
c_betterfatesearch = inheritsFrom( ml_cause )
e_betterfatesearch = inheritsFrom( ml_effect )
c_betterfatesearch.throttle = 1000
function c_betterfatesearch:evaluate()
    if (ml_task_hub:CurrentTask().name ~= "MOVETOPOS") then
        return false
    end
    
    local myPos = Player.pos
	local fateID = GetClosestFateID(myPos,true,true)
    if (fateID ~= ml_task_hub:ThisTask().fateid) then
        return true
    end
    
    return false
end
function e_betterfatesearch:execute()
	ml_debug( "Closer fate found" )
    ml_task_hub:ThisTask():Terminate()
	d("TEEEEEEEEEST CLOSER FATE CURRENT TASK "..tostring(ml_task_hub:CurrentTask().name) .." "..tostring(ml_task_hub:CurrentTask().completed))
end
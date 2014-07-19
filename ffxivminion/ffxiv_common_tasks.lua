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

function ffxiv_task_killtarget.Create()
    local newinst = inheritsFrom(ffxiv_task_killtarget)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_killtarget members
    newinst.name = "LT_KILLTARGET"
    newinst.targetid = 0
	newinst.targetRank = ""
	newinst.failTimer = nil
	newinst.waitTimer = Now()
	newinst.canEngage = true
    newinst.safeDistance = 30
	
    return newinst
end

function ffxiv_task_killtarget:Init()
	
	local ke_attarget = ml_element:create("AtTarget", c_attarget, e_attarget, 15)
	self:add( ke_attarget, self.overwatch_elements)
	
	local ke_bettertargetsearch = ml_element:create("SearchBetterTarget", c_bettertargetsearch, e_bettertargetsearch, 10)
	self:add( ke_bettertargetsearch, self.overwatch_elements)
	
	local ke_updateTarget = ml_element:create("UpdateTarget", c_updatetarget, e_updatetarget, 5)
	self:add( ke_updateTarget, self.overwatch_elements)
	
	local ke_companion = ml_element:create( "Companion", c_companion, e_companion, 3 )
    self:add( ke_companion, self.overwatch_elements)
	
	local ke_stance = ml_element:create( "Stance", c_stance, e_stance, 1 )
    self:add( ke_stance, self.overwatch_elements)
		
	--Process() cnes
	local ke_moveToTargetSafe = ml_element:create( "MoveToTargetSafe", c_movetotargetsafe, e_movetotargetsafe, 11 )
	self:add( ke_moveToTargetSafe, self.process_elements)
	
	local ke_moveToTarget = ml_element:create( "MoveToTarget", c_movetotarget, e_movetotarget, 10 )
	self:add( ke_moveToTarget, self.process_elements)
	
	local ke_huntQuit = ml_element:create( "HuntQuit", c_huntquit, e_huntquit, 9 )
	self:add( ke_huntQuit, self.process_elements)
	
	local ke_combat = ml_element:create( "AddCombat", c_add_combat, e_add_combat, 5 )
	self:add( ke_combat, self.process_elements)
	
	self:AddTaskCheckCEs()
end

function ffxiv_task_killtarget:task_complete_eval()	
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
    if (not target or not target.attackable or (target and not target.alive) or (target and not target.onmesh and not InCombatRange(target.id))) then
        d("Kill target exiting in the eval()")
		return true
    end
    
    return false
end

function ffxiv_task_killtarget:task_complete_execute()
    self.completed = true
	d("Task_Complete:Setting hasTarget to false.")
	ffxiv_task_hunt.hasTarget = false
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

function ffxiv_task_movetopos.Create()
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
    newinst.doFacing = false
    newinst.pauseTimer = 0
    newinst.gatherRange = 0.0
    newinst.remainMounted = false
    newinst.useFollowMovement = false
	newinst.obstacleTimer = 0
	newinst.use3d = false
	newinst.useTeleport = false	-- this is for hack teleport, not in-game teleport spell
	newinst.reason = ""
    
    return newinst
end


function ffxiv_task_movetopos:Init()
    local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 20 )
    self:add( ke_mount, self.process_elements)
    
    local ke_sprint = ml_element:create( "Sprint", c_sprint, e_sprint, 15 )
    self:add( ke_sprint, self.process_elements)
    
    -- The parent needs to take care of checking and updating the position of this task!!	
    local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 10 )
    self:add( ke_walkToPos, self.process_elements)
	
	local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 10 )
    self:add( ke_teleportToPos, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetopos:Process()
	if (ml_task_hub:ThisTask():ParentTask().name == "LT_KILLTARGET") then
		local target = Player:GetTarget()
		
		if 	( target and target.alive ) then
			if (not target.los or not InCombatRange(target.id)) then
				ml_task_hub:ThisTask().useFollowMovement = false
			else
				ml_task_hub:ThisTask().useFollowMovement = true
			end
			if (target.type < 3 and not Player.ismounted) then
				SkillMgr.Cast( target )
			end
		else
			ml_task_hub:ThisTask().useFollowMovement = false
		end
	end
	
	if (ml_task_hub:ThisTask():ParentTask().name == "LT_FATE" and TimeSince(ml_task_hub:ThisTask().obstacleTimer) > 5000) then
		NavigationManager:ClearAvoidanceAreas()
		local el = EntityList("attackable,aggressive,notincombat,maxdistance=100,fateid=0")
		
		local dirty = false
		local obst = {}
		local count = 1
	  
		for i,e in pairs(el) do
			if (e.targetable and e.level >= Player.level) then
				local pos = deepcopy(e.pos);
				pos.r = 15.0
				obst[count] = pos
				count = count +1
			end
		end
		NavigationManager:SetAvoidanceAreas(obst)
		ml_task_hub:ThisTask().obstacleTimer = Now()
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

function ffxiv_task_movetopos:task_complete_eval()
	if (Quest:IsLoading() or
		mm.reloadMeshPending )
	then
		return true
	end

    if ( ml_task_hub:CurrentTask().pos ~= nil and TableSize(ml_task_hub:CurrentTask().pos) > 0 ) then
        local myPos = Player.pos
		
		local gotoPos
		if(ml_task_hub:CurrentTask().gatePos) then
			gotoPos = ml_task_hub:CurrentTask().gatePos
		else
			gotoPos = ml_task_hub:CurrentTask().pos
		end
		
		local distance = 0.0
		
		if(ml_task_hub:CurrentTask().use3d) then
			distance = Distance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
		else
			distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
		end 
		
        ml_debug("Bot Position: ("..tostring(myPos.x)..","..tostring(myPos.y)..","..tostring(myPos.z)..")")
        ml_debug("MoveTo Position: ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")
        ml_debug("Task Range: "..tostring(self.range))
        ml_debug("Current Distance: "..tostring(distance))
        ml_debug("Completion Distance: "..tostring(self.range + self.gatherRange))
        
        if (distance <= self.range + self.gatherRange) then
            return true
        end
    else
        ml_error(" ERROR: no valid position in ffxiv_task_movetopos ")
    end    
    return false
end

function ffxiv_task_movetopos:task_complete_execute()
    Player:Stop()
	NavigationManager:ClearAvoidanceAreas()
    
    if (ml_task_hub:CurrentTask().doFacing) then
        Player:SetFacingSynced(ml_task_hub:CurrentTask().pos.h)
    end
	
	if (ml_task_hub:ThisTask():ParentTask().name == "LT_KILLTARGET") then
		local target = Player:GetTarget()
		
		if 	( target and target.alive ) then
			local tpos = target.pos
			Player:SetFacing(tpos.x, tpos.y, tpos.z)
		end
	end
    
    ml_task_hub:CurrentTask().completed = true
end

----------------------------------------------------------------------------------------------------------

ffxiv_task_movetomap = inheritsFrom(ml_task)
function ffxiv_task_movetomap.Create()
    local newinst = inheritsFrom(ffxiv_task_movetomap)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetomap members
    newinst.name = "MOVETOMAP"
    newinst.destMapID = 0
    newinst.tryTP = true
   
    return newinst
end

function ffxiv_task_movetomap:Init()
    local ke_teleportToMap = ml_element:create( "TeleportToMap", c_teleporttomap, e_teleporttomap, 15 )
    self:add( ke_teleportToMap, self.process_elements)

    local ke_moveToGate = ml_element:create( "MoveToGate", c_movetogate, e_movetogate, 10 )
    self:add( ke_moveToGate, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetomap:task_complete_eval()
    return Player.localmapid == ml_task_hub:CurrentTask().destMapID
end

ffxiv_task_summonchoco = inheritsFrom(ml_task)
function ffxiv_task_summonchoco.Create()
    local newinst = inheritsFrom(ffxiv_task_summonchoco)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_killtarget members
    newinst.name = "LT_SUMMON_CHOCOBO"
    
    return newinst
end

function ffxiv_task_summonchoco:Init()    
    self:AddTaskCheckCEs()
end

function ffxiv_task_summonchoco:task_complete_eval()	
	local al = ActionList("type=6")
	local dismiss = al[2]
	local acDismiss = ActionList:Get(dismiss.id,6)
	local item = Inventory:Get(4868)	
	
	if ( acDismiss.isready or item.isready) then
		return true
	end
	
	return false
end

function ffxiv_task_summonchoco:task_complete_execute()
    self.completed = true
	ml_global_information.summonTimer = ml_global_information.Now
end

ffxiv_task_teleport = inheritsFrom(ml_task)
function ffxiv_task_teleport.Create()
    local newinst = inheritsFrom(ffxiv_task_teleport)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    newinst.name = "TELEPORT"
    newinst.mapID = 0
	newinst.mesh = nil
    newinst.loadTime = 14000
	newinst.landTime = 0
    newinst.started = ml_global_information.Now
    
    return newinst
end

function ffxiv_task_teleport:Init()    
    self:AddTaskCheckCEs()
end

function ffxiv_task_teleport:task_complete_eval()		
	if (	(TableSize(Player.castinginfo) == 0 or 
			Player.castinginfo.channelingid ~= 5) 
				and ml_task_hub:ThisTask().landTime == 0 
				and Player.localmapid == ml_task_hub:ThisTask().mapID) then
			ml_task_hub:CurrentTask().landTime = ml_global_information.Now
	end
	
	
	local ppos = Player.pos
	if (ml_task_hub:CurrentTask().landTime ~= 0 and 
		TimeSince(ml_task_hub:CurrentTask().landTime) > ml_task_hub:CurrentTask().loadTime and
		not NavigationManager:IsOnMesh(ppos.x,ppos.y,ppos.z) and
		gmeshname ~= ml_task_hub:CurrentTask().mesh) then
		ml_debug("Landed in a new zone, but the default mesh is wrong, attempting to correct.")
		gmeshname = ml_task_hub:CurrentTask().mesh
		ml_task_hub:CurrentTask().landTime = ml_global_information.Now
	end
	
	if (ml_task_hub:CurrentTask().landTime ~= 0 and 
		TimeSince(ml_task_hub:CurrentTask().landTime) > ml_task_hub:CurrentTask().loadTime and
		NavigationManager:IsOnMesh(ppos.x,ppos.y,ppos.z)) then
		return true
	end
	
	if (ml_task_hub:CurrentTask().landTime ~= 0 and 
		TimeSince(ml_task_hub:CurrentTask().landTime) > (ml_task_hub:CurrentTask().loadTime * 2) and
		not NavigationManager:IsOnMesh(ppos.x,ppos.y,ppos.z) and
		gmeshname == ml_task_hub:CurrentTask().mesh) then
		ml_error("Attempted to load a proper navmesh for you, but something went wrong.")
		ml_error("You will need to verify your navmeshes and re-start the bot.")
		return true
	end
	
	if (TimeSince(ml_task_hub:ThisTask().started) > 30000) then
		return true
	end
	
    return false
end

function ffxiv_task_teleport:task_complete_execute()  
	self.completed = true
end

--=======================AVOID TASK=========================-

ffxiv_task_avoid = inheritsFrom(ml_task)
function ffxiv_task_avoid.Create()
    local newinst = inheritsFrom(ffxiv_task_avoid)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetopos members
    newinst.name = "AVOID"
    newinst.pos = 0
    newinst.range = 1.5
	newinst.maxTime = 0
    newinst.started = ml_global_information.Now
    
    return newinst
end

function ffxiv_task_avoid:Init()

    local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 10 )
    self:add( ke_walkToPos, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_avoid:task_complete_eval()
	if TimeSince(ml_task_hub:ThisTask().started) > (ml_task_hub:ThisTask().maxTime * 1000) then
		return true
	end
	
	if TimeSince(ml_task_hub:ThisTask().started) > 5000 then
		return true
	end
	
    if ( ml_task_hub:CurrentTask().pos ~= nil and TableSize(ml_task_hub:CurrentTask().pos) > 0 ) then
        local myPos = Player.pos
        local gotoPos = ml_task_hub:CurrentTask().pos  
        local distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
        
        if (distance <= self.range) then
            return true
        end
    else
        ml_debug(" ERROR: no valid position in ffxiv_task_movetopos ")
    end    
    return false
end

function ffxiv_task_avoid:task_complete_execute()
	self.completed = true
	
    Player:Stop()
    
	local target = Player:GetTarget()
	if (target ~= nil) then
		local pos = target.pos
		Player:SetFacing(pos.x,pos.y,pos.z)
	end
end
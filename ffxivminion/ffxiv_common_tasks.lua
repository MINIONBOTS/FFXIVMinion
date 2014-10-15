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
	newinst.failTimer = 0
	newinst.waitTimer = Now()
	newinst.canEngage = true
    newinst.safeDistance = 30
	
    return newinst
end

function ffxiv_task_killtarget:Init()
	local ke_avoidance = ml_element:create( "Avoidance", c_avoid, e_avoid, 20 )
    self:add( ke_avoidance, self.overwatch_elements)
	
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
    if 	((target and not target.attackable) or 
		(target and not target.alive) or 
		(target and not target.onmesh and not InCombatRange(target.id) and ml_task_hub:CurrentTask().canEngage)) 
	then
		return true
    end
    
    return false
end

function ffxiv_task_killtarget:task_complete_execute()
    self.completed = true
	ffxiv_task_hunt.hasTarget = false
end

function ffxiv_task_killtarget:task_fail_eval()
	local target = EntityList:Get(ml_task_hub:ThisTask().targetid)
	return not ValidTable(target)
end

function ffxiv_task_killtarget:task_fail_execute()
	ffxiv_task_hunt.hasTarget = false
	self:Terminate()
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
	newinst.usePathDistance = false
	newinst.objectid = 0
	newinst.useTeleport = false	-- this is for hack teleport, not in-game teleport spell
	newinst.postDelay = 0
	newinst.dismountTimer = 0
	newinst.dismountDistance = 0
    
    return newinst
end

function ffxiv_task_movetopos:Init()	
	local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 25 )
    self:add( ke_teleportToPos, self.process_elements)
	
	local ke_useNavInteraction = ml_element:create( "UseNavInteraction", c_usenavinteraction, e_usenavinteraction, 22 )
    self:add( ke_useNavInteraction, self.process_elements)
	
	local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 20 )
    self:add( ke_mount, self.process_elements)
    
    local ke_sprint = ml_element:create( "Sprint", c_sprint, e_sprint, 15 )
    self:add( ke_sprint, self.process_elements)
    
    -- The parent needs to take care of checking and updating the position of this task!!	
    local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 10 )
    self:add( ke_walkToPos, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetopos:Process()
	local parentTask = self:ParentTask()
	if(ValidTable(parentTask)) then
		if (self:ParentTask().name == "LT_FATE" and TimeSince(self.obstacleTimer) > 10000) then
			NavigationManager:ClearAvoidanceAreas()
			local el = EntityList("attackable,aggressive,notincombat,maxdistance=100,fateid=0")
	
			local dirty = false
			local obst = {}
			local count = 1
			local plvl = Player:GetSyncLevel() ~= 0 and Player:GetSyncLevel() or Player.level
		  
			for i,e in pairs(el) do
				local pos = shallowcopy(e.pos)
				pos.r = 20.0
				obst[count] = pos
				count = count + 1
			end
			NavigationManager:SetAvoidanceAreas(obst)
			self.obstacleTimer = Now()
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
end

function ffxiv_task_movetopos:task_complete_eval()
	if (IsLoading() or ml_mesh_mgr.loadingMesh ) then
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
		
		if (ml_task_hub:CurrentTask().use3d) then
			distance = Distance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
		else
			distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
		end 
		
		local pathdistance = 0
		if (self.usePathDistance and self.objectid ~= 0) then
			local object = EntityList:Get(self.objectid)
			if (ValidTable(object)) then
				pathdistance = object.pathdistance
			end
		end
		
        ml_debug("Bot Position: ("..tostring(myPos.x)..","..tostring(myPos.y)..","..tostring(myPos.z)..")")
        ml_debug("MoveTo Position: ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")
        ml_debug("Task Range: "..tostring(self.range))
        ml_debug("Current Distance: "..tostring(distance))
		ml_debug("Path Distance: "..tostring(pathdistance))
        ml_debug("Completion Distance: "..tostring(self.range + self.gatherRange))

		if (self.usePathDistance) then
			if (distance <= (self.range + self.gatherRange) and pathdistance < 10) then
				return true
			end
		else	
			if (self.dismountDistance > 0 and distance <= self.dismountDistance and Player.ismounted and Now() > self.dismountTimer) then
				Dismount()
				self.dismountTimer = Now() + 1500
			end
				
			if (distance <= (self.range + self.gatherRange)) then
				return true
			end
		end
    else
        ml_error(" ERROR: no valid position in ffxiv_task_movetopos ")
    end    
    return false
end

function ffxiv_task_movetopos:task_complete_execute()
    Player:Stop()
	if (self.doFacing) then
		Player:SetFacing(ml_task_hub:CurrentTask().pos.h)
    end
	
	if (not self.remainMounted) then
		Dismount()
	end
	NavigationManager:ClearAvoidanceAreas()
	
	if (self:ParentTask() and self:ParentTask().name == "LT_KILLTARGET") then
		local target = Player:GetTarget()
		
		if 	( target and target.alive ) then
			local tpos = target.pos
			Player:SetFacing(tpos.x, tpos.y, tpos.z)
		end
	end
    ml_task_hub:CurrentTask().completed = true
	if (self.postDelay > 0) then
		self:ParentTask():SetDelay(self.postDelay)
	end
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
	newinst.pos = nil
   
    return newinst
end

function ffxiv_task_movetomap:Init()
    local ke_teleportToMap = ml_element:create( "TeleportToMap", c_teleporttomap, e_teleporttomap, 15 )
    self:add( ke_teleportToMap, self.process_elements)
	
	local ke_transportGate = ml_element:create( "TransportGate", c_transportgate, e_transportgate, 12 )
    self:add( ke_transportGate, self.process_elements)
	
	local ke_interactGate = ml_element:create( "InteractGate", c_interactgate, e_interactgate, 11 )
    self:add( ke_interactGate, self.process_elements)

    local ke_moveToGate = ml_element:create( "MoveToGate", c_movetogate, e_movetogate, 10 )
    self:add( ke_moveToGate, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetomap:task_complete_eval()
    return Player.localmapid == ml_task_hub:CurrentTask().destMapID
end

--=======================SUMMON CHOCO TASK=========================-

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

--=======================TELEPORT TASK=========================-

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
    
    newinst.name = "LT_TELEPORT"
    newinst.mapID = 0
	newinst.mesh = nil
    newinst.started = Now()
    
    return newinst
end

function ffxiv_task_teleport:Init()    
    self:AddTaskCheckCEs()
end

function ffxiv_task_teleport:task_complete_eval()
	if (TimeSince(self.started) < 1500) then
		return false
	end
	
	if (	(TableSize(Player.castinginfo) == 0 or 
			Player.castinginfo.channelingid ~= 5) and
			not ml_mesh_mgr.loadingMesh	and 
			Player.localmapid == self.mapID and 
			not IsLoading()) 
	then
		if (Player.onmesh) then
			ffxiv_task_grind.SetEvacPoint()
			return true
		else
			if (NavigationManager:GetNavMeshName() ~= self.mesh) then
				ml_mesh_mgr.LoadNavMesh(self.mesh)
				return false
			end
		end
	end
	
	if (TimeSince(self.started) > 30000) then
		return true
	end
	
    return false
end

function ffxiv_task_teleport:task_complete_execute()  
	self.completed = true
end

--=======================STEALTH TASK=========================-
--This is a blocking task to prevent anything else from happening
--while stealth is being added or removed.

ffxiv_task_stealth = inheritsFrom(ml_task)
function ffxiv_task_stealth.Create()
    local newinst = inheritsFrom(ffxiv_task_stealth)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_killtarget members
    newinst.name = "LT_STEALTH"
	newinst.droppingStealth = false
	newinst.addingStealth = false
	newinst.timer = 0
    
    return newinst
end

function ffxiv_task_stealth:Init()    
    self:AddTaskCheckCEs()
end

function ffxiv_task_stealth:task_complete_eval()
	if (self.droppingStealth) then
		if (Player:IsMoving()) then
			Player:Stop()
			return false
		end
	end
	
	if (self.addingStealth) then
		if (Player.ismounted) then
			Player:Stop()
			Dismount()
			return false
		end
	end
	
	local action = nil
    if (Player.job == FFXIV.JOBS.BOTANIST) then
        action = ActionList:Get(212)
    elseif (Player.job == FFXIV.JOBS.MINER) then
        action = ActionList:Get(229)
    elseif (Player.job == FFXIV.JOBS.FISHER) then
        action = ActionList:Get(298)
    end

	if (self.droppingStealth) then
		if (MissingBuffs(Player,"47")) then
			return true
		end
	end
	
	if (self.addingStealth) then
		if (HasBuffs(Player,"47")) then
			return true
		end
	end
	
	if (action and not action.isoncd and Now() > self.timer) then
        action:Cast()
		self.timer = Now() + 1000
    end
	
	return false
end

function ffxiv_task_stealth:task_complete_execute()
    self.completed = true
end

--=======================USEITEM TASK=========================-

ffxiv_task_useitem = inheritsFrom(ml_task)
function ffxiv_task_useitem.Create()
    local newinst = inheritsFrom(ffxiv_task_useitem)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_killtarget members
    newinst.name = "LT_USEITEM"
	newinst.itemid = 0
	newinst.timer = 0
	newinst.useTime = 0
	newinst.dismountDelay = 0
    
    return newinst
end

function ffxiv_task_useitem:Init()    
    self:AddTaskCheckCEs()
end

function ffxiv_task_useitem:task_complete_eval()
	
	if (Now() < self.dismountDelay) then
		return false
	end
	
	if (Player.ismounted) then
		Dismount()
		self.dismountDelay = Now() + 2500
		return false
	end
	
	if (Player:IsMoving()) then
		Player:Stop()
	end
	
	if (self.timer == 0) then
		local item = Inventory:Get(self.itemid)
		if (item and item.isready) then
			item:Use()
			self.timer = (self.useTime > 0) and self.useTime or 1500
		end
	end
	
	if (self.timer > 0 and Now() > self.timer) then
		return true
	end
	
	return false
end

function ffxiv_task_useitem:task_complete_execute()
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
	newinst.targetid = 0
    newinst.pos = 0
	newinst.maxTime = 0
    newinst.started = Now()
    
    return newinst
end

function ffxiv_task_avoid:Init()
	Player:MoveTo(self.pos.x,self.pos.y,self.pos.z, 1, false, false)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_avoid:task_complete_eval()
	if TimeSince(self.started) > (self.maxTime * 1000) then
		return true
	end
	
	local target = EntityList:Get(self.targetid)
	if (not target or not target.alive or target.castinginfo.channelingid == 0) then
		return true
	end
	
	if TimeSince(ml_task_hub:ThisTask().started) > 5000 then
		return true
	end

    return false
end

function ffxiv_task_avoid:task_complete_execute()
    Player:Stop()
    
	local target = Player:GetTarget()
	if (target ~= nil) then
		local pos = target.pos
		Player:SetFacing(pos.x,pos.y,pos.z)
	end
	self.completed = true
end

function ffxiv_task_avoid:task_fail_eval()
    return (not Player.alive)
end
function ffxiv_task_avoid:task_fail_execute()
    self.valid = false
end

--=======================REST TASK=========================-
--This is a blocking task to prevent anything else from happening
--while stealth is being added or removed.

ffxiv_task_rest = inheritsFrom(ml_task)
function ffxiv_task_rest.Create()
    local newinst = inheritsFrom(ffxiv_task_rest)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "LT_REST"
	newinst.timer = 0
    
    return newinst
end

function ffxiv_task_rest:Init()
	self.timer = Now() + 120000
    self:AddTaskCheckCEs()
end

function ffxiv_task_rest:task_complete_eval()
	--Try to cast self-heals if we have them.
	SkillMgr.Cast( Player, true )
	
    if ((Player.hp.percent == 100 or tonumber(gRestHP) == 0) and (Player.mp.percent == 100 or tonumber(gRestMP) == 0)) then
		return true
	end
	
	if (Player.hp.percent == 100 and Now() > self.timer) then
		return true
	end
	
	return false
end
function ffxiv_task_rest:task_complete_execute()
	d("Completed resting, resuming normal task actions.")
    self.completed = true
end

function ffxiv_task_rest:task_fail_eval()
    if (Player.hasaggro or Player.incombat or not Player.alive) then
		return true
	end
	
	return false
end
function ffxiv_task_rest:task_fail_execute()
	d("Forced out of resting state, resuming normal task actions.")
    self.valid = false
end

---------------------------------------------------------------------------------------------
--TASK_MOVETOPOS: Reactive Goal - Move to the specified position
--This task moves the player to a specified position, the partent of this task needs to make sure
--that this movetopos task has up2date positions and is still valid.
---------------------------------------------------------------------------------------------
ffxiv_task_flee = inheritsFrom(ml_task)
function ffxiv_task_flee.Create()
    local newinst = inheritsFrom(ffxiv_task_flee)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetopos members
    newinst.name = "LT_FLEE"
    newinst.pos = 0
    newinst.range = 1.5
	newinst.useTeleport = false	-- this is for hack teleport, not in-game teleport spell
    
    return newinst
end

function ffxiv_task_flee:Init()	
	local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 11 )
    self:add( ke_teleportToPos, self.process_elements)
	
    local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 10 )
    self:add( ke_walkToPos, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_flee:task_complete_eval()
	if (IsLoading() or ml_mesh_mgr.loadingMesh ) then
		return true
	end

    if ( ml_task_hub:CurrentTask().pos ~= nil and TableSize(ml_task_hub:CurrentTask().pos) > 0 ) then
        local myPos = Player.pos
		
		local gotoPos
		gotoPos = ml_task_hub:CurrentTask().pos
		
		local distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
		
        ml_debug("Bot Position: ("..tostring(myPos.x)..","..tostring(myPos.y)..","..tostring(myPos.z)..")")
        ml_debug("MoveTo Position: ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")
        ml_debug("Task Range: "..tostring(self.range))
        ml_debug("Current Distance: "..tostring(distance))
		ml_debug("Path Distance: "..tostring(pathdistance))
        ml_debug("Completion Distance: "..tostring(self.range + self.gatherRange))

		if (distance <= self.range) then
			return true
		end
    else
        ml_error("Missing position in flee task, killing the task.")
		self.valid = false
    end    
    return false
end

function ffxiv_task_flee:task_complete_execute()
    Player:Stop()
	NavigationManager:ClearAvoidanceAreas()
    self.completed = true
end

function ffxiv_task_flee:task_fail_eval()
	return not Player.alive 
end

function ffxiv_task_flee:task_fail_execute()
	self:Terminate()
end

--=======================GRIND COMBAT TASK=========================-

ffxiv_task_grindCombat = inheritsFrom(ml_task)
function ffxiv_task_grindCombat.Create()
    local newinst = inheritsFrom(ffxiv_task_grindCombat)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetopos members
    newinst.name = "GRIND_COMBAT"
	newinst.targetid = 0
    
    return newinst
end

function ffxiv_task_grindCombat:Init()
    local ke_avoidance = ml_element:create( "Avoidance", c_avoid, e_avoid, 20 )
	self:add( ke_avoidance, self.overwatch_elements)
	
	local ke_attarget = ml_element:create("AtTarget", c_attarget, e_attarget, 15)
	self:add( ke_attarget, self.overwatch_elements)

	local ke_bettertargetsearch = ml_element:create("SearchBetterTarget", c_bettertargetsearch, e_bettertargetsearch, 10)
	self:add( ke_bettertargetsearch, self.overwatch_elements)
	
	local ke_companion = ml_element:create( "Companion", c_companion, e_companion, 3 )
	self:add( ke_companion, self.overwatch_elements)
	
	local ke_stance = ml_element:create( "Stance", c_stance, e_stance, 1 )
	self:add( ke_stance, self.overwatch_elements)
		
	local ke_moveCloser = ml_element:create( "MoveCloser", c_movecloser, e_movecloser, 10 )
	self:add( ke_moveCloser, self.process_elements)
	
	self:AddTaskCheckCEs()
end

function ffxiv_task_grindCombat:Process()
	target = EntityList:Get(self.targetid)
	if ValidTable(target) then
		local pos = shallowcopy(target.pos)
		local ppos = shallowcopy(Player.pos)
		local range = ml_global_information.AttackRange
		Player:SetTarget(target.id)
		Player:SetFacing(pos.x,pos.y,pos.z)
		SkillMgr.Cast( target )
		
		local dist = Distance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
		if (ml_global_information.AttackRange > 5) then
			if not InCombatRange(target.id) then
				if (target.los) then
					local path = Player:MoveTo(pos.x,pos.y,pos.z, 5, true, false)
				else
					local path = Player:MoveTo(pos.x,pos.y,pos.z, 5, false, false)
				end
			else
				if (Player.ismounted) then
					Dismount()
				end
				if (Player:IsMoving()) then
					Player:Stop()
				end
			end
			Player:SetFacing(pos.x,pos.y,pos.z)
			SkillMgr.Cast( target )
		else
			if not InCombatRange(target.id) then
				if (target.los) then
					local path = Player:MoveTo(pos.x,pos.y,pos.z, 1, true, false)
				else
					local path = Player:MoveTo(pos.x,pos.y,pos.z, 1, false, false)
				end
			else
				if (Player.ismounted) then
					Dismount()
				end
				if (Player:IsMoving()) then
					Player:Stop()
				end
			end
			Player:SetFacing(pos.x,pos.y,pos.z)
			SkillMgr.Cast( target )
		end
	end
      
    --Process regular elements.
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

function ffxiv_task_grindCombat:task_complete_eval()
	target = EntityList:Get(self.targetid)
    if (not target or not target.alive or target.hp.percent == 0 or not target.attackable) then
        return true
    end
end

function ffxiv_task_grindCombat:task_complete_execute()
    Player:Stop()
	self.completed = true
end

ffxiv_mesh_interact = inheritsFrom(ml_task)
function ffxiv_mesh_interact.Create()
    local newinst = inheritsFrom(ffxiv_mesh_interact)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "MESH_INTERACT"
	
	newinst.uniqueid = 0
	newinst.interact = 0
    newinst.lastinteract = 0
	newinst.pos = false
	newinst.range = 1.5
	
    return newinst
end

function ffxiv_mesh_interact:Init()
	local ke_questYesNo = ml_element:create( "QuestYesNo", c_questyesno, e_questyesno, 20 )
    self:add( ke_questYesNo, self.overwatch_elements)
	
	if (self.pos and ValidTable(self.pos)) then		
		local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 10 )
		self:add( ke_walkToPos, self.process_elements)
	end

	self:AddTaskCheckCEs()
end

function ffxiv_mesh_interact:task_complete_eval()	
	if (self.pos and ValidTable(self.pos)) then
		local ppos = shallowcopy(Player.pos)
		if (Distance2D(ppos.x,ppos.z,self.pos.x,self.pos.z) > (self.range)) then
			return false
		elseif (Player:IsMoving()) then
			Player:Stop()
			return false
		end
	end
	
	if (self.interact == 0) then
		if (self.uniqueid ~= 0) then
			local interacts = EntityList("nearest,contentid="..tostring(self.uniqueid)..",maxdistance=5")
			if (interacts) then
				local i, interact = next(interacts)
				if (interact and interact.id and interact.id ~= 0) then
					self.interact = interact.id
				end
			end
		else
			local interacts = EntityList("nearest,type=7,chartype=0,maxdistance=4")
			if (interacts) then
				local i, interact = next(interacts)
				if (interact and interact.id and interact.id ~= 0) then
					self.interact = interact.id
				end
			end
		end
	end
	
	if (self.interact ~= 0 and TimeSince(self.lastinteract) > 4000) then
		Player:Interact(self.interact)
		self.lastinteract = Now()
	end
	
	local interact = EntityList:Get(tonumber(self.interact))
	if (not interact or not interact.targetable or IsLoading() or interact.distance > 4) then
		return true
	end
end

function ffxiv_mesh_interact:task_complete_execute()
    Player:Stop()
	self.completed = true
end

function ffxiv_mesh_interact:task_fail_eval()
    if (Player.hasaggro or Player.incombat or not Player.alive) then
		return true
	end
	
	return false
end

function ffxiv_mesh_interact:task_fail_execute()
    self.valid = false
end

--=====USE BOAT====

ffxiv_nav_interact = inheritsFrom(ml_task)
function ffxiv_nav_interact.Create()
    local newinst = inheritsFrom(ffxiv_nav_interact)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "NAV_INTERACT"
	
	newinst.uniqueid = 0
	newinst.interact = 0
    newinst.lastinteract = 0
	newinst.conversationIndex = 0
	newinst.pos = false
	newinst.range = 1.5
	newinst.areaChanged = false
	newinst.addedMoveElement = false
	
    return newinst
end

function ffxiv_nav_interact:Init()
	local ke_questYesNo = ml_element:create( "QuestYesNo", c_questyesno, e_questyesno, 20 )
    self:add( ke_questYesNo, self.overwatch_elements)
	
	local ke_convIndex = ml_element:create( "ConversationIndex", c_selectconvindex, e_selectconvindex, 19 )
    self:add( ke_convIndex, self.overwatch_elements)

	self:AddTaskCheckCEs()
end

function ffxiv_nav_interact:task_complete_eval()		
	if (IsLoading() and not self.areaChanged) then
		for i, element in pairs(self.process_elements) do
			if (element.name == "WalkToPos" or element.name == "Mount") then
				table.remove(self.process_elements,i)
			end
		end
		self.areaChanged = true
	end
	
	if (not IsLoading() and self.areaChanged and not ml_mesh_mgr.meshLoading and Player.onmesh) then
		return true
	end
	
	if (self.pos and ValidTable(self.pos)) then
		if (not self.addedMoveElement) then
			
			local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 20 )
			self:add( ke_mount, self.process_elements)
			
			local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 10 )
			self:add( ke_walkToPos, self.process_elements)
			self.addedMoveElement = true
		end
		
		local ppos = shallowcopy(Player.pos)
		if (Distance2D(ppos.x,ppos.z,self.pos.x,self.pos.z) > (self.range)) then
			return false
		elseif (Player:IsMoving()) then
			Player:Stop()
			return false
		end
	end
	
	if (self.interact == 0) then
		if (self.uniqueid ~= 0) then
			local interacts = EntityList("nearest,contentid="..tostring(self.uniqueid)..",maxdistance=5")
			if (interacts) then
				local i, interact = next(interacts)
				if (interact and interact.id and interact.id ~= 0) then
					Player:SetTarget(interact.id)
					self.interact = interact.id
				end
			end
		end
	end
	
	if (Player.ismounted) then
		Dismount()
		self.lastinteract = Now() + 2000
		return false
	end
	
	if (self.interact ~= 0 and Now() > self.lastinteract) then
		Player:Interact(self.interact)
		self.lastinteract = Now() + 4000
		return false
	end
	
	local interact = EntityList:Get(tonumber(self.interact))
	if (not interact or not interact.targetable or interact.distance > 5) then
		return true
	end
	
	return false
end

function ffxiv_nav_interact:task_complete_execute()
    Player:Stop()
	self.completed = true
end

function ffxiv_nav_interact:task_fail_eval()
    if (Player.hasaggro or Player.incombat or not Player.alive) then
		return true
	end
	
	return false
end

function ffxiv_nav_interact:task_fail_execute()
    self.valid = false
end

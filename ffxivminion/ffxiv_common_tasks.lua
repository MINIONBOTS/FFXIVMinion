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
	
	local ke_autoPotion = ml_element:create( "AutoPotion", c_autopotion, e_autopotion, 19)
	self:add(ke_autoPotion, self.process_elements)
	
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
	newinst.customSearch = ""
	newinst.customSearchCompletes = false
	newinst.useTeleport = false	-- this is for hack teleport, not in-game teleport spell
	newinst.dismountTimer = 0
	newinst.dismountDistance = 15
	newinst.failTimer = 0
	
	newinst.distanceCheckTimer = 0
	newinst.lastPosition = nil
	newinst.lastDistance = 0
    
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
	
	local ke_falling = ml_element:create( "Falling", c_falling, e_falling, 10 )
    self:add( ke_falling, self.process_elements)
	
	--local ke_clearAggressive = ml_element:create( "ClearAggressive", c_clearaggressive, e_clearaggressive, 8 )
    --self:add( ke_clearAggressive, self.process_elements)
    
    -- The parent needs to take care of checking and updating the position of this task!!	
    local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 5 )
    self:add( ke_walkToPos, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetopos:task_complete_eval()
	if (IsPositionLocked() or IsLoading() or ml_mesh_mgr.loadingMesh ) then
		return true
	end

    if (ValidTable(self.pos)) then
        local myPos = Player.pos
		local gotoPos = self.gatePos or self.pos
		
		local distance = 0.0
		if (self.use3d) then
			distance = Distance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
		else
			distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
		end 
		local pathdistance = GetPathDistance(myPos,gotoPos)
		
		if (distance < 40 and self.customSearch ~= "") then
			local el = EntityList(self.customSearch)
			if (ValidTable(el)) then
				local id,entity = next(el)
				if (ValidTable(entity)) then
					if (self.customSearchCompletes) then
						if (InCombatRange(entity.id)) then
							d("Ending movetopos, found the target.")
							return true
						end
					end
					local p,dist = NavigationManager:GetClosestPointOnMesh(entity.pos,false)
					if (ValidTable(p)) then
						if (not deepcompare(self.pos,p,true)) then
							self.pos = p
							d("Using target's exact coordinate : [x:"..tostring(self.pos.x)..",y:"..tostring(self.pos.y)..",z:"..tostring(self.pos.z).."]")
						end
					end
				end
			end
		end
		
        ml_debug("Bot Position: ("..tostring(myPos.x)..","..tostring(myPos.y)..","..tostring(myPos.z)..")")
        ml_debug("MoveTo Position: ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")
        ml_debug("Task Range: "..tostring(self.range))
        ml_debug("Current Distance: "..tostring(distance))
		ml_debug("Path Distance: "..tostring(pathdistance))
        ml_debug("Completion Distance: "..tostring(self.range + self.gatherRange))

		if (not self.remainMounted and self.dismountDistance > 0 and distance <= self.dismountDistance and Player.ismounted and not IsDismounting() and Now() > self.dismountTimer) then
			SendTextCommand("/mount")
			self.dismountTimer = Now() + 500
		end
		
		if (ValidTable(self.params)) then
			local params = self.params
			if (params.type == "useitem") then
				if (ValidTable(params.usepos)) then
					local usepos = params.usepos
					local usedist = Distance3D(myPos.x,myPos.y,myPos.z,usepos.x,usepos.y,usepos.z)
					if (usedist > self.range) then
						return false
					end
				elseif (params.id) then
					local el = EntityList("nearest,targetable,contentid="..tostring(params.id))
					if (ValidTable(el)) then
						local i,entity = next(el)
						if (ValidTable(entity)) then
							local epos = entity.pos
							local usedist = Distance3D(myPos.x,myPos.y,myPos.z,epos.x,epos.y,epos.z)
							if (usedist > self.range) then
								return false
							end
						end
					end
				end
			end
		end
		
		if (distance <= (self.range + self.gatherRange)) then
			return true
		--elseif (distance <= 4 and not Player:IsMoving()) then
			--return true
		end
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
    self.completed = true
end

function ffxiv_task_movetopos:task_fail_eval()
	if (not c_walktopos:evaluate() and not Player:IsMoving()) then
		if (self.failTimer == 0) then
			self.failTimer = Now() + 1500
		end
	else
		if (self.failTimer ~= 0) then
			self.failTimer = 0
		end
	end
	
	return (not Player.alive or (self.failTimer ~= 0 and Now() > self.failTimer))
end
function ffxiv_task_movetopos:task_fail_execute()
	Player:Stop()
    self.valid = false
end

--++MOVE_TO_INTERACT
ffxiv_task_movetointeract = inheritsFrom(ml_task)
function ffxiv_task_movetointeract.Create()
    local newinst = inheritsFrom(ffxiv_task_movetointeract)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "MOVETOINTERACT"
	
	newinst.started = Now()
	newinst.uniqueid = 0
	newinst.interact = 0
    newinst.lastinteract = 0
	newinst.delayTimer = 0
	newinst.pos = false
	newinst.adjustedPos = false
	newinst.range = nil
	newinst.areaChanged = false
	newinst.addedMoveElement = false
	newinst.use3d = true
	newinst.lastDistance = nil
	newinst.useTeleport = true
	newinst.dataUnpacked = false
	newinst.failTimer = 0
	newinst.forceLOS = false
	newinst.pathRange = nil
	newinst.interactRange = nil
	
	GameHacks:SkipDialogue(true)
	
    return newinst
end

function ffxiv_task_movetointeract:Init()
	local ke_unpackData = ml_element:create( "UnpackData", c_unpackdata, e_unpackdata, 50 )
	self:add( ke_unpackData, self.process_elements)

	local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 25 )
    self:add( ke_teleportToPos, self.process_elements)
	
	local ke_useNavInteraction = ml_element:create( "UseNavInteraction", c_usenavinteraction, e_usenavinteraction, 22 )
    self:add( ke_useNavInteraction, self.process_elements)
	
	local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 20 )
    self:add( ke_mount, self.process_elements)
    
    local ke_sprint = ml_element:create( "Sprint", c_sprint, e_sprint, 15 )
    self:add( ke_sprint, self.process_elements)
	
	local ke_falling = ml_element:create( "Falling", c_falling, e_falling, 10 )
    self:add( ke_falling, self.process_elements)
	
	local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 5 )
    self:add( ke_walkToPos, self.process_elements)
	
	self:AddTaskCheckCEs()
end

function ffxiv_task_movetointeract:task_complete_eval()
	if (IsPositionLocked() or IsLoading() or ControlVisible("SelectString") or ControlVisible("SelectIconString") or IsShopWindowOpen()) then
		return true
	end
	
	if (self.interact ~= 0) then
		local interact = EntityList:Get(tonumber(self.interact))
		if (not interact or not interact.targetable or (self.lastDistance and interact.distance > (self.lastDistance * 1.5))) then
			return true
		end
	else
		local ppos = Player.pos
		local epos = self.pos
		local dist = Distance3DT(ppos,epos)
		if (dist <= 10) then
			local interacts = EntityList("targetable,contentid="..tostring(self.uniqueid)..",maxdistance=20")
			if (not ValidTable(interacts)) then
				return true
			end
		end			
	end
	
	if (Player.ismounted and Now() > self.delayTimer) then
		local requiresDismount = false
		if (self.interact == 0) then
			local interacts = EntityList("nearest,contentid="..tostring(self.uniqueid)..",maxdistance=10")
			if (ValidTable(interacts)) then
				requiresDismount = true
			end
		else
			local interact = EntityList:Get(tonumber(self.interact))
			if (interact and interact.distance < 10) then
				requiresDismount = true
			end
		end
		if (requiresDismount) then
			Dismount()
			self.delayTimer = 1000
			return false
		end
	end
	
	if (self.interact == 0) then
		if (self.uniqueid ~= 0) then
			local interacts = EntityList("contentid="..tostring(self.uniqueid)..",maxdistance=15")
			if (interacts) then
				local best = {}
				for i,interact in pairs(interacts) do
					if (interact.targetable) then
						best[i] = interact
					end
				end
				if (best) then
					local nearest = nil
					local nearestDistance = 20
					for i,interact in pairs(best) do
						if (not nearest or (nearest and interact.distance < nearestDistance)) then
							nearest = interact
							nearestDistance = interact.pathdistance
						end
					end
					if (nearest) then
						self.interact = nearest.id
					end
				end
			end
		end
	end
	
	if (not Player:GetTarget() and self.interact ~= 0) then
		local interact = EntityList:Get(tonumber(self.interact))
		if (interact and interact.targetable and interact.distance < 10) then
			Player:SetTarget(interact.id)
			local ipos = shallowcopy(interact.pos)
			local p,dist = NavigationManager:GetClosestPointOnMesh(ipos,false)
			if (ValidTable(p)) then
				if (not deepcompare(self.pos,p,true)) then
					self.pos = p
				end
			end
		end
	end
	
	if (Player:GetTarget() and self.interact ~= 0 and Now() > self.lastinteract) then
		if (not IsLoading() and not IsPositionLocked()) then
			local interact = EntityList:Get(tonumber(self.interact))
			local radius = (interact.hitradius >= 1 and interact.hitradius) or 1.25
			local pathRange = self.pathRange or 10
			local forceLOS = self.forceLOS
			local range = self.interactRange or (radius * 4)
			if (not forceLOS or (forceLOS and interact.los)) then
				if (interact and interact.distance <= range and (interact.pathdistance < pathRange or interact.type == 5)) then
					Player:SetFacing(interact.pos.x,interact.pos.y,interact.pos.z)
					Player:Interact(interact.id)
					self.lastDistance = interact.pathdistance
					self.lastinteract = Now() + 500
				end
			end
		end
	end
	
	--[[
	if (ValidTable(self.adjustedPos)) then
		Player:MoveTo(self.adjustedPos.x,self.adjustedPos.y,self.adjustedPos.z)
	elseif (ValidTable(self.pos)) then
		Player:MoveTo(self.pos.x,self.pos.y,self.pos.z)
	end
	--]]
	
	return false
end

function ffxiv_task_movetointeract:task_complete_execute()
    Player:Stop()
	GameHacks:SkipDialogue(gSkipDialogue == "1")
	if (ml_task_hub:ThisTask():ParentTask() and ml_task_hub:ThisTask():ParentTask().params) then
		local params = ml_task_hub:ThisTask():ParentTask().params
		if (params.type) then
			if (params["type"] == "interact" and not
				params["itemturnin"] and not
				params["conversationindex"])
			then
				ml_task_hub:ThisTask():ParentTask().stepCompleted = true
				ml_task_hub:ThisTask():ParentTask().stepCompletedTimer = Now() + 1000
			end
		end
	end
	self.completed = true
end

function ffxiv_task_movetointeract:task_fail_eval()
	if (not c_walktopos:evaluate() and not Player:IsMoving()) then
		if (self.failTimer == 0) then
			self.failTimer = Now() + 3000
		end
	else
		if (self.failTimer ~= 0) then
			self.failTimer = 0
		end
	end
	
	return (not Player.alive or (self.failTimer ~= 0 and Now() > self.failTimer))
end

function ffxiv_task_movetointeract:task_fail_execute()
	GameHacks:SkipDialogue(gSkipDialogue == "1")
    self.valid = false
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
	newinst.setHomepoint = false
	newinst.pos = nil
   
    return newinst
end

function ffxiv_task_movetomap:Init()
	local ke_yesnoQuest = ml_element:create( "QuestYesNo", c_questyesno, e_questyesno, 23 )
    self:add(ke_yesnoQuest, self.overwatch_elements)
	
    local ke_teleportToMap = ml_element:create( "TeleportToMap", c_teleporttomap, e_teleporttomap, 15 )
    self:add( ke_teleportToMap, self.overwatch_elements)
	
	local ke_transportGate = ml_element:create( "TransportGate", c_transportgate, e_transportgate, 12 )
    self:add( ke_transportGate, self.process_elements)
	
	local ke_interactGate = ml_element:create( "InteractGate", c_interactgate, e_interactgate, 11 )
    self:add( ke_interactGate, self.process_elements)

    local ke_moveToGate = ml_element:create( "MoveToGate", c_movetogate, e_movetogate, 10 )
    self:add( ke_moveToGate, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetomap:task_complete_eval()
    return Player.localmapid == ml_task_hub:ThisTask().destMapID
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
	newinst.aetheryte = 0
    newinst.mapID = 0
	newinst.mesh = nil
    newinst.started = Now()
	newinst.setEvac = false
	newinst.setHomepoint = false
	newinst.conversationIndex = 0
    
    return newinst
end

function ffxiv_task_teleport:Init() 
	local ke_setHomepoint = ml_element:create( "SetHomepoint", c_sethomepoint, e_sethomepoint, 50 )
	self:add( ke_setHomepoint, self.process_elements)
	
    self:AddTaskCheckCEs()
end

c_sethomepoint = inheritsFrom( ml_cause )
e_sethomepoint = inheritsFrom( ml_effect )
e_sethomepoint.aethid = 0
e_sethomepoint.aethpos = {}
function c_sethomepoint:evaluate()    
	e_sethomepoint.aethid = 0
	e_sethomepoint.aethpos = {}
	
    local currentTask = ml_task_hub:CurrentTask()
	if (not currentTask.setHomepoint or IsLoading() or ActionList:IsCasting() or 
		IsPositionLocked() or ml_mesh_mgr.loadingMesh or Player.localmapid ~= currentTask.mapID or 
		ControlVisible("SelectString") or ControlVisible("SelectIconString") or IsCityMap(Player.localmapid)) 
	then
		return false
	end
	
	local homepoint = GetHomepoint()
	if (homepoint ~= 0) then
		if (homepoint ~= currentTask.mapID) then
			local location = GetAetheryteLocation(currentTask.aetheryte)
			if (ValidTable(location)) then
				e_sethomepoint.aethid = currentTask.aetheryte
				e_sethomepoint.aethpos = {x = location.x, y = location.y, z = location.z}
				currentTask.conversationIndex = 1
				return true
			end
		end
	end
    
    return false
end
function e_sethomepoint:execute()
    local newTask = ffxiv_task_movetointeract.Create()
	newTask.uniqueid = e_sethomepoint.aethid
	newTask.pos = e_sethomepoint.aethpos
	newTask.use3d = true
	
	if (gTeleport == "1") then
		newTask.useTeleport = true
	end
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

function ffxiv_task_teleport:task_complete_eval()
	if (TimeSince(self.started) < 1500) then
		return false
	end

	if (self.conversationIndex ~= 0 and (ControlVisible("SelectIconString") or ControlVisible("SelectString"))) then
		SelectConversationIndex(tonumber(self.conversationIndex))
	end
	
	if (ControlVisible("SelectYesno")) then
		PressYesNo(true)
	end
	
	if (IsLoading() or ActionList:IsCasting() or IsPositionLocked() or ml_mesh_mgr.loadingMesh or Player.localmapid ~= self.mapID) then
		return false
	end
	
	if (self.setHomepoint and not IsCityMap(Player.localmapid)) then
		local homepoint = GetHomepoint()
		if (homepoint ~= self.mapID) then
			return false
		end
	end
	
	if (Player.onmesh) then
		if (self.setEvac) then
			ml_mesh_mgr.SetEvacPoint()
		end
		return true
	else
		if (self.mesh and NavigationManager:GetNavMeshName() ~= self.mesh) then
			ml_mesh_mgr.LoadNavMesh(self.mesh)
			return false
		end
	end
	
    return false
end
function ffxiv_task_teleport:task_complete_execute()  
	self.completed = true
end

function ffxiv_task_teleport:task_fail_eval()
	if (TimeSince(self.started) > 30000) then
		return true
	end
end
function ffxiv_task_teleport:task_fail_execute()  
	self.valid = false
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
	newinst.failTimer = Now() + 6000

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
		if (action and action.isoncd and Player:IsMoving()) then
			Player:Stop()
		end
	end
	
	if (action and not action.isoncd) then
		if (Now() > self.timer) then
			action:Cast()
			self.timer = Now() + 2500
		end
    end
	
	return false
end
function ffxiv_task_stealth:task_complete_execute()
    self.completed = true
end

function ffxiv_task_stealth:task_fail_eval()
	local list = Player:GetGatherableSlotList()
	local fs = tonumber(Player:GetFishingState())
	if (ValidTable(list) or fs ~= 0) then
		return true
	end
	
	if (Now() > self.failTimer) then
		return true
	end
	
	return false
end
function ffxiv_task_stealth:task_fail_execute()
	self.valid = false
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
	newinst.targetid = 0
	newinst.pos = {}
	newinst.timer = 0
	newinst.useTime = 0
	newinst.startingCount = ItemCount(itemid)
	newinst.dismountDelay = 0
	newinst.maxTime = Now() + 12000
	newinst.useAttempts = 0
    
    return newinst
end

function ffxiv_task_useitem:Init()    
    self:AddTaskCheckCEs()
end

function ffxiv_task_useitem:task_complete_eval()
	local itemcount = ItemCount(self.itemid) or 0
	if (self.startingCount == 0) then
		self.startingCount = itemcount
	end
	
	if (itemcount < self.startingCount or itemcount == 0 or self.useAttempts > 3) then
		return true
	end
	
	if (Now() > self.maxTime) then
		return true
	end
	
	if (Player.ismounted) then
		Dismount()
		ml_task_hub:CurrentTask():SetDelay(500)
		return false
	end
	
	if (Player:IsMoving()) then
		Player:Stop()
	end
	
	if (ActionList:IsCasting()) then
		ml_task_hub:CurrentTask():SetDelay(500)
		return false 
	end
	
	local item = Inventory:Get(self.itemid)
	if (item and item.isready) then
		if (self.targetid == 0) then
			item:Use()
			self.useAttempts = self.useAttempts + 1
			ml_task_hub:CurrentTask():SetDelay(1000)
			return false
		elseif (self.targetid ~= 0) then
			item:Use(self.targetid)
			self.useAttempts = self.useAttempts + 1
			ml_task_hub:CurrentTask():SetDelay(1000)
			return false
		elseif (ValidTable(self.pos)) then
			item:Use(self.pos.x, self.pos.y, self.pos.z)
			self.useAttempts = self.useAttempts + 1
			ml_task_hub:CurrentTask():SetDelay(1000)
			return false
		end
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
    Player:MoveTo(self.pos.x,self.pos.y,self.pos.z)
    self:AddTaskCheckCEs()
end

function ffxiv_task_avoid:task_complete_eval()
	if (self.maxTime > 0) then
		if TimeSince(self.started) > (self.maxTime * 1000) then
			return true
		end
	else
		local ppos = shallowcopy(Player.pos)
		local topos = self.pos
		local dist = Distance3D(ppos.x,ppos.y,ppos.z,topos.x,topos.y,topos.z)
		if (dist < 1) then
			return true
		end
	end
	
	local target = EntityList:Get(self.targetid)
	if (not target or not target.alive or target.castinginfo.channelingid == 0) then
		return true
	end
	
	if TimeSince(ml_task_hub:ThisTask().started) > 5000 then
		return true
	end

	Player:MoveTo(self.pos.x,self.pos.y,self.pos.z)
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
	newinst.timer = Now()
	newinst.failTimer = 0
    
    return newinst
end

function ffxiv_task_rest:Init()
    self:AddTaskCheckCEs()
end

function ffxiv_task_rest:task_complete_eval()
	--Try to cast self-heals if we have them.
	SkillMgr.Cast( Player, true )
	
	if (gTeleport == "1" and TimeSince(self.timer) < 5000) then
		return false
	end
	
    if ((Player.hp.percent > math.random(90,95) or tonumber(gRestHP) == 0) and (Player.mp.percent > math.random(90,95) or tonumber(gRestMP) == 0)) then
		return true
	end
	
	if (Player.hp.percent > math.random(90,95) and TimeSince(self.timer) > 120000) then
		return true
	end
	
	return false
end
function ffxiv_task_rest:task_complete_execute()
	d("Completed resting, resuming normal task actions.")
    self.completed = true
end

function ffxiv_task_rest:task_fail_eval()
    if (not Player.alive) then
		return true
	end
	
	if (Player.incombat) then
		local el = EntityList("alive,attackable,targetingme,maxdistance=25")
		if(ValidTable(el)) then
			return true
		end
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
	newinst.failTimer = 0
    
    return newinst
end

function ffxiv_task_flee:Init()	
	local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 11 )
    self:add( ke_teleportToPos, self.process_elements)
	
	local ke_falling = ml_element:create( "Falling", c_falling, e_falling, 10 )
    self:add( ke_falling, self.process_elements)
	
    local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 5 )
    self:add( ke_walkToPos, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_flee:task_complete_eval()
	if (IsLoading() or ml_mesh_mgr.loadingMesh ) then
		return true
	end
	
	if not HasBuff(Player.id, 50) and Player:IsMoving() then
        local skills = ActionList("type=1")
        local skill = skills[3]
        if (skill and skill.isready) then
			skill:Cast()
        end
    end
	
	return not Player.incombat or (Player.hp.percent > tonumber(gRestHP) and Player.mp.percent > tonumber(gRestMP))
end

function ffxiv_task_flee:task_complete_execute()
	d("Flee task completed properly.")
    Player:Stop()
	NavigationManager:ClearAvoidanceAreas()
    self.completed = true
	ml_task_hub:CurrentTask():SetDelay(2000)
end

function ffxiv_task_flee:task_fail_eval()
	if (((not c_walktopos:evaluate() and not Player:IsMoving()) and Player.incombat)) then
		if (self.failTimer == 0) then
			self.failTimer = Now() + 5000
		end
	else
		if (self.failTimer ~= 0) then
			self.failTimer = 0
		end
	end
	return (not Player.alive or (self.failTimer ~= 0 and Now() > self.failTimer))
end

function ffxiv_task_flee:task_fail_execute()
	self.valid = false
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
    newinst.noTeleport = false
	newinst.noFateSync = false
	newinst.teleportThrottle = 0
	newinst.targetPos = nil
	newinst.movementDelay = 0
	newinst.lastMovement = 0
	newinst.attackThrottle = false
	newinst.attackThrottleTimer = 0
	
	newinst.attemptPull = false
	newinst.pullTimer = 0
	newinst.pullPos1 = Player.pos
	newinst.pullPos2 = Player.pos
	
    return newinst
end

function ffxiv_task_grindCombat:Init()
    local ke_avoidance = ml_element:create( "Avoidance", c_avoid, e_avoid, 20 )
	self:add( ke_avoidance, self.overwatch_elements)
	
	local ke_autoPotion = ml_element:create( "AutoPotion", c_autopotion, e_autopotion, 19)
	self:add(ke_autoPotion, self.overwatch_elements)
	
	local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 15 )
	self:add( ke_rest, self.process_elements)
	
	local ke_companion = ml_element:create( "Companion", c_companion, e_companion, 8 )
	self:add( ke_companion, self.process_elements)
	
	local ke_stance = ml_element:create( "Stance", c_stance, e_stance, 6 )
	self:add( ke_stance, self.process_elements)
	
	self:AddTaskCheckCEs()
end

function ffxiv_task_grindCombat:Process()	
	target = EntityList:Get(self.targetid)
	if ValidTable(target) then
	
		local currentTarget = Player:GetTarget()
		if (not currentTarget or (currentTarget and currentTarget.id ~= target.id)) then
			Player:SetTarget(target.id)
		end
		
		--Check to see if we would need to sync to attack this target, and do it if we are allowed to.
		if (target.fateid ~= 0 and Player:GetSyncLevel() == 0 and Now() > ml_global_information.syncTimer) then
			if (not self.noFateSync) then
				local fateID = target.fateid
				local fate = GetFateByID(fateID)
				if ( fate and fate.completion < 99 and fate.status == 2) then
					local plevel = Player.level
					if (fate.level < (plevel - 5)) then
						local myPos = Player.pos
						local distance = Distance2D(myPos.x, myPos.z, fate.x, fate.z)
						if (distance <= fate.radius) then				
							Player:SyncLevel()
						end
					end
				end
			end
		end
		
		local teleport = ShouldTeleport(target.pos)
		local pos = shallowcopy(target.pos)
		local ppos = shallowcopy(Player.pos)
		local pullpos1 = self.pullPos1
		local pullpos2 = self.pullPos2
		local range = ml_global_information.AttackRange
		local eh = ConvertHeading(pos.h)
		local mobRear = ConvertHeading((eh - (math.pi)))%(2*math.pi)
		local nearbyMobs = TableSize(EntityList("alive,aggressive,attackable,distanceto="..tostring(target.id)..",maxdistance=8"))
		
		local dist = Distance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
		if (ml_global_information.AttackRange > 5) then
			if ((not InCombatRange(target.id) or (not target.los and not CanAttack(target.id))) and not ActionList:IsCasting()) then
				if (teleport and dist > 60 and Now() > self.teleportThrottle) then
					local telePos = GetPosFromDistanceHeading(pos, 20, mobRear)
					local p,dist = NavigationManager:GetClosestPointOnMesh(telePos,false)
					if (dist < 5) then
						GameHacks:TeleportToXYZ(tonumber(p.x),tonumber(p.y),tonumber(p.z))
						self.teleportThrottle = Now() + 1500
					end
				else
					if (Now() > self.movementDelay) then
						local path = Player:MoveTo(pos.x,pos.y,pos.z, (target.hitradius + 1), false, false)
						self.movementDelay = Now() + 1000
					end
				end
			end
			if (InCombatRange(target.id)) then
				if (Player.ismounted) then
					Dismount()
				end
				if (Player:IsMoving() and (target.los or CanAttack(target.id))) then
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
				if (not self.attackThrottle or Now() > self.attackThrottleTimer) then
					SkillMgr.Cast( target )
					if (self.attackThrottle) then
						if (Player.level > target.level) then
							self.attackThrottleTimer = Now() + 2900
						end
					end
				end
			end
		else
			if (not InCombatRange(target.id) or (not target.los and not CanAttack(target.id))) then
				if (not self.attemptPull or nearbyMobs == 0 or (self.attemptPull and (self.pullTimer == 0 or Now() > self.pullTimer))) then
					if (teleport and not self.attemptPull and dist > 60 and Now() > self.teleportThrottle) then
						local telePos = GetPosFromDistanceHeading(pos, 2, mobRear)
						local p,dist = NavigationManager:GetClosestPointOnMesh(telePos,false)
						if (dist < 5) then
							GameHacks:TeleportToXYZ(tonumber(p.x),tonumber(p.y),tonumber(p.z))
							self.teleportThrottle = Now() + 1500
						end
					else
						Player:MoveTo(pos.x,pos.y,pos.z, 2, false, false)
					end
					local dist1 = Distance3D(ppos.x,ppos.y,ppos.z,pullpos1.x,pullpos1.y,pullpos1.z)
					local dist2 = Distance3D(ppos.x,ppos.y,ppos.z,pullpos2.x,pullpos2.y,pullpos2.z)
					if (dist1 > 10) then
						self.pullPos2 = self.pullPos1
						self.pullPos1 = {x = ppos.x, y = ppos.y, z = ppos.z}
					end
					ml_task_hub:CurrentTask().lastMovement = Now()
				end
			end
			if (target.distance <= 15) then
				if (Player.ismounted) then
					Dismount()
				end
			end
			if (InCombatRange(target.id)) then
				Player:SetFacing(pos.x,pos.y,pos.z) 
				if (target.los or CanAttack(target.id)) then
					Player:Stop()
				end
			end
			if (not self.attackThrottle or Now() > self.attackThrottleTimer) then
				if (SkillMgr.Cast( target ) and self.attemptPull and self.pullTimer == 0 and nearbyMobs > 0) then
					Player:Stop()
					local pullPos = nil
					local dist1 = Distance3D(ppos.x,ppos.y,ppos.z,self.pullPos1.x,self.pullPos1.y,self.pullPos1.z)
					if (dist1 > 6) then
						d("using pullpos 1")
						pullPos = self.pullPos1
					else
						d("using pullpos 2")
						pullPos = self.pullPos2
					end
					Player:MoveTo(pullPos.x,pullPos.y,pullPos.z, 1, false, false)
					self.pullTimer = Now() + 5000
				end
				if (self.attackThrottle) then
					if (Player.level > target.level) then
						self.attackThrottleTimer = Now() + 2900
					end
				end
			end
		end
	else
		if (not ml_task_hub:CurrentTask():ParentTask() or ml_task_hub:CurrentTask():ParentTask().name ~= "LT_FATE" and Now() > ml_global_information.syncTimer) then
			if (ml_task_hub:CurrentTask():ParentTask()) then
				d("ParentTask:["..ml_task_hub:CurrentTask():ParentTask().name.."] is not valid for sync, Player will be unsynced.")
			end
			if (Player:GetSyncLevel() ~= 0) then
				Player:SyncLevel()
				ml_global_information.syncTimer = Now() + 1000
			end
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
	local target = EntityList:Get(self.targetid)
    if (not target or not target.alive or target.hp.percent == 0 or not target.attackable) then
		d("[GrindCombat]: Task complete due to no target, target not alive, or target not attackable.")
        return true
    end
end
function ffxiv_task_grindCombat:task_complete_execute()
	if (not ml_task_hub:CurrentTask():ParentTask() or ml_task_hub:CurrentTask():ParentTask().name ~= "LT_FATE" and Now() > ml_global_information.syncTimer) then
		if (Player:GetSyncLevel() ~= 0) then
			if (ml_task_hub:CurrentTask():ParentTask()) then
				d("ParentTask:["..ml_task_hub:CurrentTask():ParentTask().name.."] is not valid for sync, Player will be unsynced.")
			end
			Player:SyncLevel()
			ml_global_information.syncTimer = Now() + 1000
		end
	end
    Player:Stop()
	self.completed = true
end

function ffxiv_task_grindCombat:task_fail_eval()
	local target = EntityList:Get(self.targetid)
	if (target) then
		if (target.fateid ~= 0) then
			local fateID = target.fateid
			local fate = GetFateByID(fateID)
			if (not fate or fate.completion > 99) then
				d("[GrindCombat]: Task complete due fate target and fate ending.")
				return true
			end
		end
	end
	
	if (not Player.alive or Player.hp.percent < GetFleeHP() or Player.mp.percent < tonumber(gFleeMP)) then
		d("[GrindCombat]: Task failure due to death or need to flee.")
		return true
	end
	
	return false
end
function ffxiv_task_grindCombat:task_fail_execute()
	Player:Stop()
	self.valid = false
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
	
	newinst.interact = 0
    newinst.interactLatency = 0
	
	GameHacks:SkipDialogue(true)
	
	d("Mesh interact task created.")
	
    return newinst
end

function ffxiv_mesh_interact:Init()
	local ke_detectYesNo = ml_element:create( "DetectYesNo", c_detectyesno, e_detectyesno, 25 )
    self:add( ke_detectYesNo, self.overwatch_elements)

	self:AddTaskCheckCEs()
end

function ffxiv_mesh_interact:task_complete_eval()		
	if (self.interact == 0) then
		local interacts = EntityList("nearest,targetable,type=7,chartype=0,maxdistance=6")
		if (ValidTable(interacts)) then
			local i, interact = next(interacts)
			if (interact and interact.id and interact.id ~= 0) then
				self.interact = interact.id
			end
		end
		
		local interacts = EntityList("nearest,targetable,type=3,chartype=0,maxdistance=6")
		if (ValidTable(interacts)) then
			local i, interact = next(interacts)
			if (interact and interact.id and interact.id ~= 0) then
				self.interact = interact.id
			end
		end
	end
	
	if (self.interact ~= 0) then
		local target = Player:GetTarget()
		if (not target or (target and target.id ~= self.interact)) then
			local interact = EntityList:Get(tonumber(self.interact))
			if (interact and interact.targetable) then
				Player:SetTarget(self.interact)
				d("Setting target for interact.")
			end		
		end
		
		if (target and target.id == self.interact and Now() > self.interactLatency) then
			if (not IsLoading() and not IsPositionLocked()) then
				local interact = EntityList:Get(tonumber(self.interact))
				local radius = (interact.hitradius >= 1 and interact.hitradius) or 1
				if (interact and interact.distance < (radius * 4)) then
					Player:SetFacing(interact.pos.x,interact.pos.y,interact.pos.z)
					Player:Interact(interact.id)
					self.lastDistance = interact.distance
					self.interactLatency = Now() + 1000
				end
			end
		end
	end
	
	local interact = EntityList:Get(tonumber(self.interact))
	if (not interact or not interact.targetable or IsLoading() or interact.distance > 6) then
		return true
	end
end

function ffxiv_mesh_interact:task_complete_execute()
	d("Mesh interact task completed normally.")
	GameHacks:SkipDialogue(gSkipDialogue == "1")
	ml_mesh_mgr.ResetOMC()
	self.completed = true
end

function ffxiv_mesh_interact:task_fail_eval()
    if (Player.incombat or not Player.alive) then
		return true
	end
	
	return false
end

function ffxiv_mesh_interact:task_fail_execute()
	d("Mesh interact task failed.")
    GameHacks:SkipDialogue(gSkipDialogue == "1")
	ml_mesh_mgr.ResetOMC()
    self.valid = false
end

--=====USE BOAT====

c_detectyesno = inheritsFrom( ml_cause )
e_detectyesno = inheritsFrom( ml_effect )
function c_detectyesno:evaluate()
	if (ControlVisible("_NotificationParty")) then
		return false
	end
	return ControlVisible("SelectYesno")
end
function e_detectyesno:execute()
	PressYesNo(true)
	ml_task_hub:ThisTask().preserveSubtasks = true
end

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
	newinst.delayTimer = 0
	newinst.conversationIndex = 0
	newinst.pos = false
	newinst.range = 1.5
	newinst.areaChanged = false
	newinst.addedMoveElement = false
	newinst.use3d = true
	
	GameHacks:SkipDialogue(true)
	
    return newinst
end

function ffxiv_nav_interact:Init()
	local ke_detectYesNo = ml_element:create( "DetectYesNo", c_detectyesno, e_detectyesno, 20 )
    self:add( ke_detectYesNo, self.overwatch_elements)
	
	local ke_convIndex = ml_element:create( "ConversationIndex", c_selectconvindex, e_selectconvindex, 19 )
    self:add( ke_convIndex, self.overwatch_elements)
	
	local ke_falling = ml_element:create( "Falling", c_falling, e_falling, 10 )
    self:add( ke_falling, self.process_elements)

	self:AddTaskCheckCEs()
end

function ffxiv_nav_interact:task_complete_eval()
	if (IsPositionLocked() and self.addedMoveElement) then
		for i, element in pairs(self.process_elements) do
			if (element.name == "TeleportToPos" or element.name == "Mount") then
				table.remove(self.process_elements,i)
			end
		end
	end
	
	if (IsLoading() and not self.areaChanged) then
		self.areaChanged = true
	end
	
	if (not IsLoading() and self.areaChanged and not ml_mesh_mgr.meshLoading and Player.onmesh) then
		return true
	end

	if (self.pos and ValidTable(self.pos)) then
		if (not self.addedMoveElement) then
			local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 25 )
			self:add( ke_teleportToPos, self.process_elements)
			
			local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 20 )
			self:add( ke_mount, self.process_elements)
			self.addedMoveElement = true
		end
	end
	
	if (IsPositionLocked() or IsLoading() or ControlVisible("SelectYesno")) then
		Player:Stop()
		return false
	end	
	
	if (Player.ismounted and Now() > self.delayTimer) then
		local interacts = EntityList("nearest,targetable,contentid="..tostring(self.uniqueid)..",maxdistance=10")
		if (ValidTable(interacts)) then
			Dismount()
			self.delayTimer = 1000
		end
	end
	
	if (self.interact == 0) then
		if (self.uniqueid ~= 0) then
			local interacts = EntityList("nearest,targetable,contentid="..tostring(self.uniqueid)..",maxdistance=10")
			if (ValidTable(interacts)) then
				local i,interact = next(interacts)
				if (interact) then
					self.interact = interact.id
				end
			end
		end
	end
	
	if (not Player:GetTarget() and self.interact ~= 0) then
		local interact = EntityList:Get(tonumber(self.interact))
		if (interact and interact.targetable) then
			Player:SetTarget(self.interact)
			local ipos = shallowcopy(interact.pos)
			if (not deepcompare(ipos,self.pos)) then
				self.pos = shallowcopy(ipos)
			end
		end
	end
	
	if (Player:GetTarget() and self.interact ~= 0 and Now() > self.lastinteract) then
		if (not IsLoading() and not IsPositionLocked()) then
			local interact = EntityList:Get(tonumber(self.interact))
			local radius = (interact.hitradius >= 1 and interact.hitradius) or 1
			if (interact and interact.distance < (radius * 4)) then
				Player:SetFacing(interact.pos.x,interact.pos.y,interact.pos.z)
				Player:Interact(interact.id)
				self.lastDistance = interact.distance
				self.lastinteract = Now() + 500
			end
		end
	end
	
	if (ValidTable(self.pos)) then
		Player:MoveTo(self.pos.x,self.pos.y,self.pos.z)
	end

	return false
end

function ffxiv_nav_interact:task_complete_execute()
    Player:Stop()
	GameHacks:SkipDialogue(gSkipDialogue == "1")
	self.completed = true
end

function ffxiv_nav_interact:task_fail_eval()
    if (Player.incombat or not Player.alive) then
		return true
	end
	
	return false
end

function ffxiv_nav_interact:task_fail_execute()
	GameHacks:SkipDialogue(gSkipDialogue == "1")
    self.valid = false
end

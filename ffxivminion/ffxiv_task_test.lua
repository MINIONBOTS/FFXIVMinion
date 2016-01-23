ffxiv_task_test = inheritsFrom(ml_task)
ffxiv_task_test.lastTick = 0
ffxiv_task_test.lastPathCheck = 0
ffxiv_task_test.flightMesh = {}
ffxiv_task_test.lastTaskSet = {}
ffxiv_task_test.lastRect = {}
ffxiv_task_test.cubePath = GetStartupPath() .. [[\Navigation\]] .. "cube.test"
ffxiv_task_test.storageCube = {}
ffxiv_task_test.courseFlight = {}

ffxiv_task_test.flyMounts = {
	[1] = true,
	[5] = true,
	[25] = true,
	[44] = true,
	[45] = true,
	[50] = true,
	[54] = true,
	[55] = true,
	[58] = true,
	[59] = true,
	[62] = true,
}

local INF = 1/0
local cachedPaths = nil
local insert = table.insert
local atan2 = math.atan2
local asin = math.asin
local dist_3d = PDistance3D

function ffxiv_task_test.Create()
    local newinst = inheritsFrom(ffxiv_task_test)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetomap members
    newinst.name = "TEST"
	newinst.taskCreated = false
	newinst.moveCreated = false
   
    return newinst
end

c_gotomaptest = inheritsFrom( ml_cause )
e_gotomaptest = inheritsFrom( ml_effect )
function c_gotomaptest:evaluate()
	local mapID = tonumber(gTestMapID)
	if (Player.localmapid ~= mapID) then
		if (CanAccessMap(mapID)) then
			return true
		end
	end
	
	return false
end
function e_gotomaptest:execute()
	local mapID = tonumber(gTestMapID)
	local task = ffxiv_task_movetomap.Create()
	local pos = {}
	pos.x = tonumber(gTestMapX) or 0
	pos.y = tonumber(gTestMapY) or 0
	pos.z = tonumber(gTestMapZ) or 0
	
	task.pos = pos
	task.destMapID = mapID
	ml_task_hub:CurrentTask():AddSubTask(task)
end

c_gotopostest = inheritsFrom( ml_cause )
e_gotopostest = inheritsFrom( ml_effect )
c_gotopostest.pos = {}
c_gotopostest.path = {}
function c_gotopostest:evaluate()
	c_gotopostest.pos = {}
	c_gotopostest.path = {}

	local mapID = tonumber(gTestMapID)
	if (Player.localmapid == mapID) then
		local ppos = Player.pos
		local pos = {}
		pos.x = tonumber(gTestMapX)
		pos.y = tonumber(gTestMapY)
		pos.z = tonumber(gTestMapZ)
		
		local dist = PDistance3D(ppos.x, ppos.y, ppos.z, pos.x, pos.y, pos.z)
		if (dist > 3) then
			--local path = ffxiv_task_test.GetPath(ppos,pos)
			--if (ValidTable(path)) then
				c_gotopostest.pos = pos
				--c_gotopostest.path = path
				return true
			--end
		end
	end
	return false
end
function e_gotopostest:execute()
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = c_gotopostest.pos 
	--newTask.path = c_gotopostest.path
	newTask.range = 3
	newTask.remainMounted = true
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_flighttest = inheritsFrom( ml_cause )
e_flighttest = inheritsFrom( ml_effect )
e_flighttest.pos = nil
e_flighttest.path = nil
function c_flighttest:evaluate()
	if (true) then
		return false
	end
	
	e_flighttest.pos = nil
	e_flighttest.path = nil
	
	local pos = {}
	pos.x = tonumber(gTestMapX)
	pos.y = tonumber(gTestMapY)
	pos.z = tonumber(gTestMapZ)
	
	local ppos = ml_global_information.Player_Position
	if (Distance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z) > 10) then
		--local path = ffxiv_task_test.GetPath()
		--if (ValidTable(path)) then
			e_flighttest.pos = pos
			--e_flighttest.path = path
			return true
		--end
	end
	return false
end
function e_flighttest:execute()
	ml_global_information.landing = nil
	local newTask = ffxiv_task_movetopos2.Create()
	newTask.pos = e_flighttest.pos
	newTask.remainMounted = true
	ml_task_hub:CurrentTask():AddSubTask(newTask)
	--[[
	local newTask = ffxiv_task_movewithflight.Create()
	newTask.path = e_flighttest.path
	newTask.remainMounted = true
	newTask.pos = e_flighttest.pos
	ml_task_hub:CurrentTask():AddSubTask(newTask)
	--]]
end

c_movetopos = inheritsFrom( ml_cause )
e_movetopos = inheritsFrom( ml_effect )
function c_movetopos:evaluate()
	if ((MIsLocked() and not IsFlying()) or 
		MIsLoading() or
		IsMounting() or
		ControlVisible("SelectString") or ControlVisible("SelectIconString") or 
		IsShopWindowOpen() or
		(MIsCasting() and not IsNull(ml_task_hub:CurrentTask().interruptCasting,false))) 
	then
		return false
	end
	
    if (ValidTable(ml_task_hub:CurrentTask().pos) or ValidTable(ml_task_hub:CurrentTask().gatePos)) then		
		local myPos = ml_global_information.Player_Position
		local gotoPos = nil
		if (ml_task_hub:CurrentTask().gatePos) then
			gotoPos = ml_task_hub:CurrentTask().gatePos
			ml_debug("[c_walktopos]: Position adjusted to gate position.", "gLogCNE", 2)
		else
			gotoPos = ml_task_hub:CurrentTask().pos
			ml_debug("[c_walktopos]: Position left as original position.", "gLogCNE", 2)
		end
		
		if (ValidTable(gotoPos)) then
			
			-- If we're very close to an interactable
			local target = MGetTarget()
			if (target) then
				local tpos = target.pos
				local distFromGoal = PDistance3D(tpos.x,tpos.y,tpos.z,gotoPos.x,gotoPos.y,gotoPos.z)
				if (distFromGoal <= 5) then
					if (target.distance < 2.5 and target.los) then
						if (Player:IsMoving()) then
							--d("Stopped because we are very close to the target.")
							Player:Stop()
						end
						return false
					end
				end
			end
			
			local range = ml_task_hub:CurrentTask().range or 0
			if (range > 0) then
				local distance = 0.0
				if (ml_task_hub:CurrentTask().use3d) then
					distance = PDistance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
				else
					distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
				end
			
				if (distance > ml_task_hub:CurrentTask().range) then
					e_movetopos.pos = gotoPos
					return true
				end
			else
				e_movetopos.pos = gotoPos
				return true
			end
		end
    end
	
    return false
end
function e_movetopos:execute()	
	local self = ml_task_hub:ThisTask()
	local myPos = Player.pos
	local gotoPos = self.pos
	
	local path = self.path
	if (ValidTable(path)) then		
		local currentPoint = nil
		if (self.pathIndex == 0) then
			currentPoint = Player.pos
		else
			currentPoint = path[self.pathIndex]
		end
		
		if (currentPoint) then
			local travelPoint = nil
			if ((self.pathIndex+1) > TableSize(self.path)) then
				travelPoint = gotoPos
				--local p,dist = NavigationManager:GetClosestPointOnMesh(gotoPos)
				--if (p and dist ~= 0) then
					--travelPoint = p
				--end
			else
				--d("Setting to next path index ["..tostring(self.pathIndex).."].")
				travelPoint = path[self.pathIndex+1]
			end
			
			if (travelPoint) then
				local distNext = PDistance3D(myPos.x, myPos.y, myPos.z, travelPoint.x, travelPoint.y, travelPoint.z)
				--SmartTurn(travelPoint)
				Player:SetFacing(travelPoint.x,travelPoint.y,travelPoint.z)
				if (IsFlying()) then
					local pitch = math.atan2((myPos.y - travelPoint.y), distNext)
					if (GetPitch() ~= pitch) then
						Player:SetPitch(pitch)
					end
				end
				
				if (travelPoint.type == "CUBE" and not IsFlying()) then
					
					local ydist = math.abs(travelPoint.y - Player.pos.y)
					d("ydist:"..tostring(ydist))
					
					if (ydist > 10) then
						local instructions = {
							{"Stop", {}},
							{"Ascend", {}},
							{"Wait", { 500 }},
							{"Stop", {}},
						}
						ml_mesh_mgr.ParseInstructions(instructions)
					else
						local instructions = {
							{"Stop", {}},
							{"QuickAscend", {}},
							{"Wait", { 500 }},
							{"Stop", {}},
						}
						ml_mesh_mgr.ParseInstructions(instructions)

					end	
					return
				end
				
				if (travelPoint.type == nil and currentPoint.type == nil and IsFlying()) then
					local instructions = {
						{"Stop", {}},
						{"Descend", {}},
						{"Wait", { 1000 }},
						{"Stop", {}},
					}
					ml_mesh_mgr.ParseInstructions(instructions)
					return
				end
				
				if (not Player:IsMoving()) then
					Player:Move(FFXIV.MOVEMENT.FORWARD)
					return
				end
				
				local distFactor;
				if (Player:IsMoving()) then
					distFactor = 5
				else
					distFactor = 3
				end
				
				if (distNext <= distFactor) then
					d("distNext:"..tostring(distNext))
					self.pathIndex = self.pathIndex+1
					return false
				end
			else
				local distFactor;
				if (Player:IsMoving()) then
					distFactor = 5
				else
					distFactor = 3
				end
				
				local distCurrent = PDistance3D(myPos.x,myPos.y,myPos.z,currentPoint.x,currentPoint.y,currentPoint.z)
				if (distCurrent <= distFactor) then
					--d("No travel point and we are close to the current point.")
					return true
				end
			end
		end
	end  
end

c_refreshpath = inheritsFrom( ml_cause )
e_refreshpath = inheritsFrom( ml_effect )
c_refreshpath.path = nil
function c_refreshpath:evaluate()
	local ppos = Player.pos
	local pos = ml_task_hub:CurrentTask().pos
	
	if (ml_task_hub:CurrentTask().path == nil) then
		local path = ffxiv_task_test.GetPath(ppos,pos)
		if (ValidTable(path)) then
			ml_task_hub:CurrentTask().path = path
			ml_task_hub:CurrentTask().pathIndex = 0
			return true
		end
	end
	
    return false
end
function e_refreshpath:execute()
	d("Path was refreshed, new path has ["..tostring(TableSize(ml_task_hub:CurrentTask().path)).."] points.")
end

ffxiv_task_movetopos2 = inheritsFrom(ml_task)
function ffxiv_task_movetopos2.Create()
    local newinst = inheritsFrom(ffxiv_task_movetopos2)
    
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
	newinst.use3d = true
	newinst.customSearch = ""
	newinst.customSearchCompletes = false
	newinst.useTeleport = false	-- this is for hack teleport, not in-game teleport spell
	newinst.dismountTimer = 0
	newinst.dismountDistance = 5
	newinst.failTimer = 0
	
	newinst.startMap = Player.localmapid
	
	newinst.distanceCheckTimer = 0
	newinst.lastPosition = nil
	
	newinst.flightPath = nil
	newinst.noFlight = false
	newinst.stealthFunction = nil
	
	newinst.abortFunction = nil
	ml_global_information.monitorStuck = true
	
	newinst.destMapID = 0
	newinst.alwaysMount = false
	newinst.pathIndex = 0
	
	table.insert(tasktracking, newinst)
    
    return newinst
end

function ffxiv_task_movetopos2:Init()
	local ke_stuck = ml_element:create( "Stuck", c_stuck, e_stuck, 150 )
    self:add( ke_stuck, self.overwatch_elements)
	
	local ke_teleportToMap = ml_element:create( "TeleportToMap", c_teleporttomap, e_teleporttomap, 140 )
    self:add( ke_teleportToMap, self.process_elements)
			
	local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 130 )
    self:add( ke_teleportToPos, self.process_elements)
	
	local ke_stealth = ml_element:create( "Stealth", c_stealthupdate, e_stealthupdate, 100 )
    self:add( ke_stealth, self.process_elements)
	
	local ke_useNavInteraction = ml_element:create( "UseNavInteraction", c_usenavinteraction, e_usenavinteraction, 90 )
    self:add( ke_useNavInteraction, self.process_elements)
	
	local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 80 )
    self:add( ke_mount, self.process_elements)
	
    local ke_sprint = ml_element:create( "Sprint", c_sprint, e_sprint, 70 )
    self:add( ke_sprint, self.process_elements)
	
	local ke_falling = ml_element:create( "Falling", c_falling, e_falling, 60 )
    self:add( ke_falling, self.process_elements)
    
	local ke_refreshPath = ml_element:create( "RefreshPath", c_refreshpath, e_refreshpath, 50 )
    self:add( ke_refreshPath, self.process_elements)	
		
	local ke_moveToPos = ml_element:create( "MoveToPos", c_movetopos, e_movetopos, 40 )
    self:add( ke_moveToPos, self.process_elements)
	
    --local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 50 )
    --self:add( ke_walkToPos, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetopos2:task_complete_eval()
	if ((MIsLocked() and not IsFlying()) or MIsLoading() or self.startMap ~= Player.localmapid) then
		ml_debug("[MOVETOPOS]: Completing due to locked, loading, mesh loading.")
		return true
	end
	
	if (self.destMapID and ml_global_information.Player_Map == self.destMapID) then
		return true
	end
	
	if (self.abortFunction) then
		if (type(self.abortFunction) == "function") then
			local retval = self.abortFunction()
			if (retval == true) then
				return true
			end
		elseif (type(self.abortFunction) == "table") then
			local abortFunctions = self.abortFunction
			for i,fn in pairs(abortFunctions) do
				if (type(fn) == "function") then
					local retval = fn()
					if (retval == true) then
						return true
					end
				end
			end
		end
	end

    if (ValidTable(self.pos)) then
        local myPos = ml_global_information.Player_Position
		local gotoPos = self.gatePos or self.pos
		
		local distance = 0.0
		local distance2d = 0.0
		if (self.use3d) then
			distance = PDistance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
			distance2d = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
		else
			distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
			distance2d = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
		end 
		
        ml_debug("Bot Position: ("..tostring(myPos.x)..","..tostring(myPos.y)..","..tostring(myPos.z)..")")
        ml_debug("MoveTo Position: ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")
        ml_debug("Task Range: "..tostring(self.range))
        ml_debug("Current Distance: "..tostring(distance))
        ml_debug("Completion Distance: "..tostring(self.range + self.gatherRange))

		if (not self.remainMounted and self.dismountDistance > 0 and distance <= self.dismountDistance and Player.ismounted and not IsDismounting() and Now() > self.dismountTimer) then
			Dismount()
			self.dismountTimer = Now() + 500
		end
		
		if (ValidTable(self.params)) then
			local params = self.params
			if (params.type == "useitem") then
				if (ValidTable(params.usepos)) then
					local usepos = params.usepos
					local usedist = PDistance3D(myPos.x,myPos.y,myPos.z,usepos.x,usepos.y,usepos.z)
					if (usedist > self.range) then
						return false
					end
				elseif (params.id) then
					local el = EntityList("nearest,targetable,contentid="..tostring(params.id))
					if (ValidTable(el)) then
						local i,entity = next(el)
						if (ValidTable(entity)) then
							local epos = entity.pos
							local usedist = PDistance3D(myPos.x,myPos.y,myPos.z,epos.x,epos.y,epos.z)
							if (usedist > (self.range + entity.hitradius)) then
								return false
							end
						end
					end
				end
			end
		end
		
		if (distance < (self.range + self.gatherRange)) then
			d("[MOVETOPOS]: Completing @ 3D range ["..tostring(distance).."].")
			d("[MOVETOPOS]: Completing @ 2D range ["..tostring(distance2d).."].")
			d("[MOVETOPOS]: Completing due to range ["..tostring(self.range + self.gatherRange).."] reached.")
			return true
		else
			-- For extremely small distances, allow to execute early if it's reasonably close.
			if (not Player:IsMoving() and self.range < 1 and distance < 1) then
				d("[MOVETOPOS]: Completing due to range reached.")
				return true
			end
		end
    end    
    return false
end

function ffxiv_task_movetopos2:task_complete_execute()
    Player:Stop()
	if (self.doFacing) then
		Player:SetFacing(ml_task_hub:CurrentTask().pos.h)
    end
	if (not self.remainMounted) then
		Dismount()
	end
    self.completed = true
	ml_debug("[MOVETOPOS]: Task completing.")
end

function ffxiv_task_movetopos2:task_fail_eval()
	if (not c_movetopos:evaluate() and not Player:IsMoving()) then
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
function ffxiv_task_movetopos2:task_fail_execute()
	Player:Stop()
    self.valid = false
	ml_debug("[MOVETOPOS]: Failing.")
end

ffxiv_task_movetointeract2 = inheritsFrom(ml_task)
function ffxiv_task_movetointeract2.Create()
    local newinst = inheritsFrom(ffxiv_task_movetointeract2)
    
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
    newinst.lastInteract = 0
	newinst.lastDismountCheck = 0
	newinst.lastInteractableSearch = 0
	newinst.pos = false
	newinst.adjustedPos = false
	newinst.range = nil
	newinst.areaChanged = false
	newinst.addedMoveElement = false
	newinst.use3d = true
	newinst.useTeleport = true
	newinst.dataUnpacked = false
	newinst.failTimer = 0
	newinst.forceLOS = false
	newinst.pathRange = nil
	newinst.interactRange = nil
	newinst.dismountDistance = 5
	newinst.killParent = false
	newinst.interactDelay = 500
	newinst.startMap = Player.localmapid
	newinst.moveWait = 0
	
	newinst.stealthFunction = nil
	
	GameHacks:SkipDialogue(true)
	ml_global_information.monitorStuck = true
	newinst.alwaysMount = false
	newinst.pathIndex = 0
	
	table.insert(tasktracking, newinst)
	
    return newinst
end

function ffxiv_task_movetointeract2:Init()
	local ke_stuck = ml_element:create( "Stuck", c_stuck, e_stuck, 150 )
    self:add( ke_stuck, self.overwatch_elements)
	
	local ke_stealth = ml_element:create( "Stealth", c_stealthupdate, e_stealthupdate, 110 )
    self:add( ke_stealth, self.process_elements)

	local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 100 )
    self:add( ke_teleportToPos, self.process_elements)
	
	local ke_useNavInteraction = ml_element:create( "UseNavInteraction", c_usenavinteraction, e_usenavinteraction, 95 )
    self:add( ke_useNavInteraction, self.process_elements)
	
	local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 90 )
    self:add( ke_mount, self.process_elements)
    
    local ke_sprint = ml_element:create( "Sprint", c_sprint, e_sprint, 70 )
    self:add( ke_sprint, self.process_elements)
	
	local ke_falling = ml_element:create( "Falling", c_falling, e_falling, 60 )
    self:add( ke_falling, self.process_elements)
	
	local ke_refreshPath = ml_element:create( "RefreshPath", c_refreshpath, e_refreshpath, 50 )
    self:add( ke_refreshPath, self.process_elements)	
		
	local ke_moveToPos = ml_element:create( "MoveToPos", c_movetopos, e_movetopos, 40 )
    self:add( ke_moveToPos, self.process_elements)
	
	self:AddTaskCheckCEs()
end

function ffxiv_task_movetointeract2:task_complete_eval()
	if ((MIsLocked() and not IsFlying()) or MIsLoading() or ControlVisible("SelectString") or ControlVisible("SelectIconString") or IsShopWindowOpen() or self.startMap ~= Player.localmapid) then
		return true
	end
	
	local myTarget = MGetTarget()
	local ppos = ml_global_information.Player_Position
	
	if (self.interact ~= 0) then
		local interact = EntityList:Get(tonumber(self.interact))
		if (not interact or not interact.targetable) then
			return true
		end
	else
		local epos = self.pos
		local dist = Distance3DT(ppos,epos)
		if (dist <= 10) then
			local interacts = EntityList("targetable,contentid="..tostring(self.uniqueid)..",maxdistance=20")
			if (not ValidTable(interacts)) then
				return true
			end
		end			
	end
	
	local interactable = nil
	if (self.interact == 0 and TimeSince(self.lastInteractableSearch) > 500) then
		if (self.uniqueid ~= 0) then
			local interacts = nil
			interacts = EntityList("shortestpath,targetable,contentid="..tostring(self.uniqueid)..",maxdistance=30")
			if (ValidTable(interacts)) then
				local i,interact = next(interacts)
				if (i and interact) then
					self.interact = interact.id
				end
			end
			
			interacts = EntityList("nearest,targetable,contentid="..tostring(self.uniqueid)..",maxdistance=30")
			if (ValidTable(interacts)) then
				local i,interact = next(interacts)
				if (i and interact) then
					self.interact = interact.id
				end
			end
			self.lastInteractableSearch = Now()
		end
	end
	
	if (self.interact ~= 0) then
		interactable = EntityList:Get(self.interact)
	else
		return false
	end
	
	if (Player.ismounted and TimeSince(self.lastDismountCheck) > 500) then
		local requiresDismount = false
		if (interactable and interactable.distance < self.dismountDistance) then
			local isflying = IsFlying()
			if (not isflying or (isflying and not Player:IsMoving())) then
				Dismount()
			end
		end
		self.lastDismountCheck = Now()
	end
	
	if (IsDismounting()) then
		return false
	end
	
	if (not myTarget) then
		if (interactable and interactable.targetable and interactable.distance < 10) then
			Player:SetTarget(interactable.id)
			--[[
			local ipos = interactable.pos
			local p,dist = NavigationManager:GetClosestPointOnMesh(ipos,false)
			if (p and dist ~= 0) then
				if (not deepcompare(self.pos,p,true)) then
					self.pos = p
				end
			end
			--]]
		end
	end

	if (not IsFlying()) then
		--if (myTarget and TimeSince(self.lastInteract) > 500) then
		if (myTarget) then
			if (ValidTable(interactable)) then			
				if (interactable.type == 5) then
					if (interactable.distance <= 7.5) then
						Player:SetFacing(interactable.pos.x,interactable.pos.y,interactable.pos.z)
						Player:Interact(interactable.id)
						self.lastInteract = Now()
						return false
					end
				end
				
				local radius = (interactable.hitradius >= 1 and interactable.hitradius) or 1.25
				local pathRange = self.pathRange or 10
				local forceLOS = self.forceLOS
				local range = self.interactRange or (radius * 3.5)
				if (not forceLOS or (forceLOS and interactable.los)) then
					if (interactable and interactable.distance <= range) then
						local ydiff = math.abs(ppos.y - interactable.pos.y)
						if (ydiff < 3.5 or interactable.los) then
							Player:SetFacing(interactable.pos.x,interactable.pos.y,interactable.pos.z)
							Player:Interact(interactable.id)
							self.lastInteract = Now()
						end
					end
				end
			end
		end
	end
	
	return false
end

function ffxiv_task_movetointeract2:task_complete_execute()
    Player:Stop()
	GameHacks:SkipDialogue(gSkipDialogue == "1")
	if (self.killParent) then
		ml_task_hub:ThisTask():ParentTask().stepCompleted = true
		ml_task_hub:ThisTask():ParentTask().stepCompletedTimer = Now() + 1000
	end
	self.completed = true
end

function ffxiv_task_movetointeract2:task_fail_eval()
	if (not c_movetopos:evaluate() and not Player:IsMoving()) then
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

function ffxiv_task_movetointeract2:task_fail_execute()
	GameHacks:SkipDialogue(gSkipDialogue == "1")
    self.valid = false
end

ffxiv_task_movewithflight = inheritsFrom(ml_task)
function ffxiv_task_movewithflight.Create()
    local newinst = inheritsFrom(ffxiv_task_movewithflight)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movewithflight members
    newinst.name = "MOVE_WITH_FLIGHT"
    newinst.pos = 0
    newinst.range = 1.5
	newinst.obstacleTimer = 0
	
	newinst.path = {}
	newinst.pathIndex = 0
	newinst.movementStarted = false
	newinst.lastDistance = math.huge
	newinst.stuckTicks = 0
    
    return newinst
end

function ffxiv_task_movewithflight:Init()	
	local ke_takeOff = ml_element:create( "TakeOff", c_flighttakeoff, e_flighttakeoff, 80 )
    self:add( ke_takeOff, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_movewithflight:task_complete_eval()
    if (ValidTable(self.pos)) then
        local myPos = ml_global_information.Player_Position
		local gotoPos = self.pos
		
		local distance = PDistance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)		
		if (distance <= 4) then
			d("Close to the destination, we can stop now.")
			return true
		else
			local path = self.path
			if (ValidTable(path)) then
				if (IsFlying()) then	
					
					if (not Player:IsMoving()) then
						d("starting forward movement.")
						Player:Move(FFXIV.MOVEMENT.FORWARD)
						ml_task_hub:CurrentTask():SetDelay(500)
						return false
					end
					
					local currentPoint = nil
					if (self.pathIndex == 0) then
						currentPoint = Player.pos
					else
						currentPoint = path[self.pathIndex]
					end
					
					if (currentPoint) then
						--d("have current point. x = "..tostring(currentPoint.x)..", y = "..tostring(currentPoint.y)..", z = "..tostring(currentPoint.z))
						local travelPoint = nil
						if ((self.pathIndex+1) > TableSize(self.path)) then
							travelPoint = gotoPos
							local p,dist = NavigationManager:GetClosestPointOnMesh(gotoPos)
							if (p and dist ~= 0) then
								travelPoint = p
							end
						else
							d("Setting to next path index ["..tostring(self.pathIndex).."].")
							travelPoint = path[self.pathIndex+1]
						end
						
						if (travelPoint) then
							d("have travel point. x = "..tostring(travelPoint.x)..", y = "..tostring(travelPoint.y)..", z = "..tostring(travelPoint.z))
							local distNext = PDistance3D(myPos.x, myPos.y, myPos.z, travelPoint.x, travelPoint.y, travelPoint.z)
							d("distnext:"..tostring(distNext))
							if (distNext == self.lastDistance) then
								self.stuckTicks = self.stuckTicks + 1
								d("Adding one stuck tick, total now ["..tostring(self.stuckTicks).."].")
							end
							
							--[[
							if (self.stuckTicks >= 2) then
								Player:Move(FFXIV.MOVEMENT.FORWARD)
								self.lastDistance = math.huge
								self.stuckTicks = 0
								return false
							end
							--]]
							
							self.lastDistance = distNext
							
							if (distNext <= 4) then
								--d("Switching at a distance of ["..tostring(distNext).."].")
								self.pathIndex = self.pathIndex+1
								--d("Moving forward in the path to index ["..tostring(self.pathIndex).."].")
								self.lastDistance = math.huge
								self.stuckTicks = 0
								return false
							end
							
							SmartTurn(travelPoint)
							local pitch = math.atan2((myPos.y - travelPoint.y), distNext)
							--local pitch = math.asin((myPos.y - travelPoint.y)/distNext)
							if (GetPitch() ~= pitch) then
								--d("Adjusting pitch to ["..tostring(pitch).."].")
								Player:SetPitch(pitch)
							end

							ml_global_information.idlePulseCount = 0
						else
							local distCurrent = PDistance3D(myPos.x,myPos.y,myPos.z,currentPoint.x,currentPoint.y,currentPoint.z)
							if (distCurrent <= 4) then
								d("No travel point and we are close to the current point.")
								return true
							end
						end
					end
				end
			else
				d("Path wasn't valid, we should quit now.")
				return true
			end
		end
    end    
    return false
end

function ffxiv_task_movewithflight:task_complete_execute()
	d("Quitting flight task.")
    --Player:Stop()
	--Dismount()
	--ml_task_hub:CurrentTask():SetDelay(1000)
	--ml_global_information.landing = { expiration = Now() + 3000 }
	if (not self.remainMounted) then
		local myPos = ml_global_information.Player_Position
		local raycast,hitX,hitY,hitZ = MeshManager:RayCast(myPos.x, myPos.y, myPos.z, myPos.x, (myPos.y - 75), myPos.z)
		if (raycast == nil) then
			d("We were sent somewhere we cannot land, not good.. just wait for the user I guess.")
		elseif (raycast == true) then
			local connectDist = PDistance3D(myPos.x, myPos.y, myPos.z, hitX, hitY, hitZ)
			local descentTime = math.floor(connectDist / 10) * 1000
			d("Estimate a time of 10 units per second to descend.")
			local instructions = {
				{"Descend", {}},
				{"Wait", { descentTime }},
				--{"CheckIfLocked",{}},
				{"Stop", {}},
			}
			ml_mesh_mgr.ParseInstructions(instructions)
		end
	else
		Player:Stop()
	end
		
    self.completed = true
end
function ffxiv_task_movewithflight:task_fail_eval()
	if (MIsLoading()) then
		return true
	end
	
	if (not IsFlying() and not Player.ismounted and not IsMounting()) then
		if (Player.incombat) then
			d("Quitting flight attempt, in combat.")
			return true
		end
	end
	
	return false
end
function ffxiv_task_movewithflight:task_fail_execute()
	Player:Stop()
    self.valid = false
end


function ffxiv_task_test.GetFlightPoints(basePos)
	local thisPos = renderpos or Player.pos
	local heading = thisPos.h
	
	local playerForward = ConvertHeading(heading)%(2*math.pi)
	local playerRight = ConvertHeading((heading - (math.pi/2)))%(2*math.pi)
	local playerLeft = ConvertHeading((heading + (math.pi/2)))%(2*math.pi)
	local playerRear = ConvertHeading((heading - (math.pi)))%(2*math.pi)
	
	--Wing,Cube,Matrix,Laser,LaserX
	
	local points = {}
	if (IsNull(gTestRecordPattern,"Basic") == "Basic") then
		points = {
			thisPos
		}
	elseif (gTestRecordPattern == "Cube") then
		local container = {}
		container.base = {
			f = GetPosFromDistanceHeading(thisPos, tonumber(gTestRecordTolerance) or 5, playerForward),
			r = GetPosFromDistanceHeading(thisPos, tonumber(gTestRecordTolerance) or 5, playerRight),
			l = GetPosFromDistanceHeading(thisPos, tonumber(gTestRecordTolerance) or 5, playerLeft),
			b = GetPosFromDistanceHeading(thisPos, tonumber(gTestRecordTolerance) or 5, playerRear),
		}
		container.top = {
			f = { x = container.base.f.x, y = container.base.f.y + tonumber(gTestRecordTolerance) or 5, z = container.base.f.z },
			r = { x = container.base.r.x, y = container.base.r.y + tonumber(gTestRecordTolerance) or 5, z = container.base.r.z },
			l = { x = container.base.l.x, y = container.base.l.y + tonumber(gTestRecordTolerance) or 5, z = container.base.l.z },
			b = { x = container.base.b.x, y = container.base.b.y + tonumber(gTestRecordTolerance) or 5, z = container.base.b.z },
		}
		
		for i,vertices in pairs(container) do
			for k,v in pairs(vertices) do
				local raycast = MeshManager:RayCast(thisPos.x,thisPos.y,thisPos.z,v.x,v.y,v.z)
				if (raycast == nil) then
					table.insert(points,v)
				end
			end
		end
	elseif (gTestRecordPattern == "Matrix") then
		local container = {}
		container.base = {
			f = GetPosFromDistanceHeading(thisPos, tonumber(gTestRecordTolerance) or 5, playerForward),
			r = GetPosFromDistanceHeading(thisPos, tonumber(gTestRecordTolerance) or 5, playerRight),
			l = GetPosFromDistanceHeading(thisPos, tonumber(gTestRecordTolerance) or 5, playerLeft),
			b = GetPosFromDistanceHeading(thisPos, tonumber(gTestRecordTolerance) or 5, playerRear),
		}
		container.basex = {
			f = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * 2), playerForward),
			r = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * 2), playerRight),
			l = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * 2), playerLeft),
			b = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * 2), playerRear),
		}
		container.basex2 = {
			f = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * 3), playerForward),
			r = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * 3), playerRight),
			l = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * 3), playerLeft),
			b = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * 3), playerRear),
		}
		container.mid = {
			f = { x = container.base.f.x, y = container.base.f.y + (tonumber(gTestRecordTolerance) or 5), z = container.base.f.z },
			r = { x = container.base.r.x, y = container.base.r.y + (tonumber(gTestRecordTolerance) or 5), z = container.base.r.z },
			l = { x = container.base.l.x, y = container.base.l.y + (tonumber(gTestRecordTolerance) or 5), z = container.base.l.z },
			b = { x = container.base.b.x, y = container.base.b.y + (tonumber(gTestRecordTolerance) or 5), z = container.base.b.z },
		}
		container.midx = {
			f = { x = container.basex.f.x, y = container.basex.f.y + (tonumber(gTestRecordTolerance) or 5), z = container.basex.f.z },
			r = { x = container.basex.r.x, y = container.basex.r.y + (tonumber(gTestRecordTolerance) or 5), z = container.basex.r.z },
			l = { x = container.basex.l.x, y = container.basex.l.y + (tonumber(gTestRecordTolerance) or 5), z = container.basex.l.z },
			b = { x = container.basex.b.x, y = container.basex.b.y + (tonumber(gTestRecordTolerance) or 5), z = container.basex.b.z },
		}
		container.midx2 = {
			f = { x = container.basex2.f.x, y = container.basex2.f.y + (tonumber(gTestRecordTolerance) or 5), z = container.basex2.f.z },
			r = { x = container.basex2.r.x, y = container.basex2.r.y + (tonumber(gTestRecordTolerance) or 5), z = container.basex2.r.z },
			l = { x = container.basex2.l.x, y = container.basex2.l.y + (tonumber(gTestRecordTolerance) or 5), z = container.basex2.l.z },
			b = { x = container.basex2.b.x, y = container.basex2.b.y + (tonumber(gTestRecordTolerance) or 5), z = container.basex2.b.z },
		}
		container.top = {
			f = { x = container.mid.f.x, y = container.mid.f.y + (tonumber(gTestRecordTolerance) or 5), z = container.mid.f.z },
			r = { x = container.mid.r.x, y = container.mid.r.y + (tonumber(gTestRecordTolerance) or 5), z = container.mid.r.z },
			l = { x = container.mid.l.x, y = container.mid.l.y + (tonumber(gTestRecordTolerance) or 5), z = container.mid.l.z },
			b = { x = container.mid.b.x, y = container.mid.b.y + (tonumber(gTestRecordTolerance) or 5), z = container.mid.b.z },
		}
		container.topx = {
			f = { x = container.midx.f.x, y = container.midx.f.y + (tonumber(gTestRecordTolerance) or 5), z = container.midx.f.z },
			r = { x = container.midx.r.x, y = container.midx.r.y + (tonumber(gTestRecordTolerance) or 5), z = container.midx.r.z },
			l = { x = container.midx.l.x, y = container.midx.l.y + (tonumber(gTestRecordTolerance) or 5), z = container.midx.l.z },
			b = { x = container.midx.b.x, y = container.midx.b.y + (tonumber(gTestRecordTolerance) or 5), z = container.midx.b.z },
		}
		container.topx2 = {
			f = { x = container.midx2.f.x, y = container.midx2.f.y + (tonumber(gTestRecordTolerance) or 5), z = container.midx2.f.z },
			r = { x = container.midx2.r.x, y = container.midx2.r.y + (tonumber(gTestRecordTolerance) or 5), z = container.midx2.r.z },
			l = { x = container.midx2.l.x, y = container.midx2.l.y + (tonumber(gTestRecordTolerance) or 5), z = container.midx2.l.z },
			b = { x = container.midx2.b.x, y = container.midx2.b.y + (tonumber(gTestRecordTolerance) or 5), z = container.midx2.b.z },
		}
		
		for i,vertices in pairs(container) do
			for k,v in pairs(vertices) do
				local raycast = MeshManager:RayCast(thisPos.x,thisPos.y,thisPos.z,v.x,v.y,v.z)
				if (raycast == nil) then
					table.insert(points,v)
				end
			end
		end
	elseif (gTestRecordPattern == "Laser") then
		for i = 1,20 do
			local f = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * i), playerForward)
			local r = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * i), playerRight)
			local l = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * i), playerLeft)
			
			table.insert(points,f)
			table.insert(points,r)
			table.insert(points,l)
		end
	elseif (gTestRecordPattern == "LaserX") then
		local recordTolerance = tonumber(gTestRecordTolerance) or 5
		
		local f = GetPosFromDistanceHeading(thisPos, recordTolerance, playerForward)
		local r = GetPosFromDistanceHeading(thisPos, recordTolerance, playerRight)
		local l = GetPosFromDistanceHeading(thisPos, recordTolerance, playerLeft)
		
		for i = 1,25 do
			local f = GetPosFromDistanceHeading(f, (recordTolerance * i), playerForward)
			local r = GetPosFromDistanceHeading(r, (recordTolerance * i), playerForward)
			local l = GetPosFromDistanceHeading(l, (recordTolerance * i), playerForward)
			
			local raycast = MeshManager:RayCast(thisPos.x,thisPos.y,thisPos.z,f.x,f.y,f.z)
			if (raycast == nil) then
				table.insert(points,f)
			end
			
			local raycast = MeshManager:RayCast(thisPos.x,thisPos.y,thisPos.z,r.x,r.y,r.z)
			if (raycast == nil) then
				table.insert(points,r)
			end
			
			local raycast = MeshManager:RayCast(thisPos.x,thisPos.y,thisPos.z,l.x,l.y,l.z)
			if (raycast == nil) then
				table.insert(points,l)
			end
		end
	end		
	
	return points
end

function ffxiv_task_test.RenderPoints(points,altcolor,altsize,altheight)
	d("Received a points collection with ["..tostring(TableSize(points)).."] to render.")
	for i,pos in pairs(points) do
		local color = altcolor or 0
		local s = altsize or .2 -- size
		local h = altheight or .2 -- height
		
		local t = { 
			[1] = { pos.x-s, pos.y+s+h, pos.z-s, color },
			[2] = { pos.x+s, pos.y+s+h, pos.z-s, color },	
			[3] = { pos.x,   pos.y-s+h,   pos.z, color },
			
			[4] = { pos.x+s, pos.y+s+h, pos.z-s, color },
			[5] = { pos.x+s, pos.y+s+h, pos.z+s, color },	
			[6] = { pos.x,   pos.y-s+h,   pos.z, color },
			
			[7] = { pos.x+s, pos.y+s+h, pos.z+s, color },
			[8] = { pos.x-s, pos.y+s+h, pos.z+s, color },	
			[9] = { pos.x,   pos.y-s+h,   pos.z, color },
			
			[10] = { pos.x-s, pos.y+s+h, pos.z+s, color },
			[11] = { pos.x-s, pos.y+s+h, pos.z-s, color },	
			[12] = { pos.x,   pos.y-s+h,   pos.z, color },
		}
		
		RenderManager:AddObject(t)	
	end
end

function ffxiv_task_test.RenderPoint(pos,altcolor,altsize,altheight)
	RenderManager:RemoveAllObjects()
	
	local color = altcolor or 0
	local s = altsize or .2 -- size
	local h = altheight or .2 -- height
	
	local t = { 
		[1] = { pos.x-s, pos.y+s+h, pos.z-s, color },
		[2] = { pos.x+s, pos.y+s+h, pos.z-s, color },	
		[3] = { pos.x,   pos.y-s+h,   pos.z, color },
		
		[4] = { pos.x+s, pos.y+s+h, pos.z-s, color },
		[5] = { pos.x+s, pos.y+s+h, pos.z+s, color },	
		[6] = { pos.x,   pos.y-s+h,   pos.z, color },
		
		[7] = { pos.x+s, pos.y+s+h, pos.z+s, color },
		[8] = { pos.x-s, pos.y+s+h, pos.z+s, color },	
		[9] = { pos.x,   pos.y-s+h,   pos.z, color },
		
		[10] = { pos.x-s, pos.y+s+h, pos.z+s, color },
		[11] = { pos.x-s, pos.y+s+h, pos.z-s, color },	
		[12] = { pos.x,   pos.y-s+h,   pos.z, color },
	}
	
	RenderManager:AddObject(t)	
end

function ffxiv_task_test.CreateStorage()
	ffxiv_task_test.storageCube = {	size = 2000, x = 0, y = 0, z = 0, children = {} }
	quadrasectCube(ffxiv_task_test.storageCube,1,5,0)
	
	--persistence.store(ffxiv_task_test.cubePath,ffxiv_task_test.storageCube)
end

function ffxiv_task_test.HasJunction(pos)
	local neighbors = findNeighbors(ffxiv_task_test.storageCube,pos,true,false,nil,4)
	if (ValidTable(neighbors)) then
		return true
	end
	
	return false
end

function ffxiv_task_test.GetNearestFlightJunction(pos)
	local neighbors = findNeighbors(ffxiv_task_test.storageCube,pos,true,false,nil,4)
	if (ValidTable(neighbors)) then
		local closest = nil
		local closestDistance = 9999
			
		for i,neighbor in pairs(neighbors) do
			local dist = PDistance3D(pos.x,pos.y,pos.z,neighbor.x,neighbor.y,neighbor.z)
			if (not closest or (closest and dist < closestDistance)) then
				closest,closestDistance = neighbor,dist
			end
		end
		
		return closest
	end
	
	return nil
end

function ffxiv_task_test.PruneFlightMesh()
	local prunedPoints = 0
	local allowedPoints = 0
	
	local mesh = ffxiv_task_test.flightMesh
	if (ValidTable(mesh)) then
		for k,v in pairs(mesh) do
			allowedPoints = 0
			local neighbors = findNeighbors(ffxiv_task_test.storageCube,v,false)
			if (ValidTable(neighbors)) then
				--d("Found ["..tostring(TableSize(neighbors)).."] neighbors for point.")
				for i,neighbor in pairs(neighbors) do
					local dist = PDistance3D(neighbor.x,neighbor.y,neighbor.z,v.x,v.y,v.z)
					if (dist < 5) then
						table.remove(mesh,k)
						removeFromCube(ffxiv_task_test.storageCube,v)
						prunedPoints = prunedPoints + 1
						break
					else
						allowedPoints = allowedPoints + 1
					end
				end
				--d("Allowed ["..tostring(allowedPoints).."] neighbors.")
			end
		end
	end
	
	if (prunedPoints > 0) then
		d("Pruned ["..tostring(prunedPoints).."].")
		ffxiv_task_test.SaveFlightMesh()
	end
end

function ffxiv_task_test.ReadFlightMesh()
	local file = Player.localmapid .. ".flight"
	local path = GetStartupPath() .. [[\Navigation\]]
	local fullPath = path .. file
	
	ffxiv_task_test.CreateStorage()
	
	local info = {}
	local requiresUpdate = false
	if (FileExists(fullPath)) then
		info = persistence.load(fullPath)
		if (ValidTable(info) and ValidTable(info.mesh)) then
			ffxiv_task_test.flightMesh = info.mesh
			
			local renderNonJunction = {}
			local renderJunction = {}
			
			local mesh = ffxiv_task_test.flightMesh
			if (ValidTable(mesh)) then
				for k,v in pairs(mesh) do
					insertIntoCube(ffxiv_task_test.storageCube,v)
					if (v.isjunction == true) then
						renderJunction[#renderJunction+1] = v
					else
						renderNonJunction[#renderNonJunction+1] = v
					end
				end
			end
			
			--ffxiv_task_test.RenderPoints(renderNonJunction)
			--ffxiv_task_test.RenderPoints(renderJunction,4)
			
			--[[
			ffxiv_task_test.RenderPoints(ffxiv_task_test.courseMesh,4)
			local mesh = ffxiv_task_test.courseMesh
			if (ValidTable(mesh)) then
				for k,v in pairs(mesh) do
					if (v.isjunction == nil) then
						v = isJunction(v)
						mesh[k] = v
						requiresUpdate = true
					end
					insertIntoCube(ffxiv_task_test.storageCube,v)
					if (v.isjunction == true) then
						insertIntoCube(ffxiv_task_test.junctionCube,v)
					end
				end
			end
			--]]
			
			if (requiresUpdate) then
				ffxiv_task_test.SaveFlightMesh()
			end
			return true
		end
	end
	
	ffxiv_task_test.flightMesh = {}
	return false
end

function ffxiv_task_test.SaveFlightMesh()
	local file = Player.localmapid .. ".flight"
	local path = GetStartupPath() .. [[\Navigation\]]
	local fullPath = path .. file
	
	d("Attempting to save flight mesh at path :"..tostring(fullPath))
	d("Mesh contains "..tostring(TableSize(ffxiv_task_test.flightMesh)).." points.")
	
	local info = {}
	
	local newmesh = {}
	local newsize = 0
	
	for k,v in pairsByKeys(ffxiv_task_test.flightMesh) do
		newsize = #newmesh+1
		newmesh[newsize] = v
		newmesh[newsize].id = newsize
		newmesh[newsize].neighbors = nil
		newmesh[newsize].h = nil
	end
	
	info.mesh = newmesh
	ffxiv_task_test.flightMesh = newmesh
	
	persistence.store(fullPath,info)
end

function ffxiv_task_test.GetPath()
	RenderManager:RemoveAllObjects()
	local ppos = Player.pos
	
	--local ppos = { x = 135.76, y = 68.85, z = 63.45 }
	
	--local pos = {}
	--pos.x = tonumber(gTestMapX)
	--pos.y = tonumber(gTestMapY)
	--pos.z = tonumber(gTestMapZ)
	
	--local pos = { x = 247.84, y = 77.166, z = 120.45 }
	local pos = ml_task_hub:CurrentTask().pos
	
	local timeS = os.clock()
	local recastPoints = {}
	local cubePoints = {}
	
	local path = NavigationManager:GetPath(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
	if (ValidTable(path)) then
		d("Path contains ["..tostring(TableSize(path)).."] points.")
		for k,v in pairs(path) do
			if (v.type and v.type == "CUBE") then
				table.insert(cubePoints,v)
			else
				table.insert(recastPoints,v)
			end
			--d("k = ["..tostring(k).."], v.x = ["..tostring(v.x).."], v.y = ["..tostring(v.y).."], v.z = ["..tostring(v.z).."], v.type = ["..tostring(v.type).."].")
		end
	end
	
	ffxiv_task_test.RenderPoints(recastPoints,1)
	ffxiv_task_test.RenderPoints(cubePoints,4)
	
	local timeF = os.clock()
	d(timeF - timeS)
	
	return path
end

function ffxiv_task_test.InsertIntoTree()
	local mesh = ffxiv_task_test.flightMesh
	if (ValidTable(mesh)) then
		for k,v in pairs(mesh) do
			insertIntoCube(ffxiv_task_test.storageCube,v)
		end
	end
	
	--persistence.store(ffxiv_task_test.cubePath,ffxiv_task_test.storageCube)
end

function ffxiv_task_test.FindNeighbors()
	local renderedPoints = {}
	
	local neighbors = findNeighbors(ffxiv_task_test.storageCube,Player.pos)
	if (ValidTable(neighbors)) then
		for i,neighbor in pairs(neighbors) do
			table.insert(renderedPoints,neighbor)
		end
	end
	
	if (ValidTable(renderedPoints)) then
		ffxiv_task_test.RenderPoints(renderedPoints,1)
	end
end

function ffxiv_task_test.TestInstructions()
	local instructions = {
		{"Action", {2263, 1, Player.id}},
		{"Wait", { 100 }},
		{"Action", {2261, 1, Player.id}},
		{"Wait", { 100 }},
		{"Action", {2259, 1, Player.id}},
		{"Wait", { 100 }},
		{"Action", {2260, 1, Player.id}},
	}
	ml_mesh_mgr.ParseInstructions(instructions)
end

function addGhost(pos)

end

function removeGhosts()

end

function insertIntoCube(cube,pos)
	local storageUnit = findContainer(cube,pos)
	if (storageUnit.points == nil) then storageUnit.points = {} end
	storageUnit.points[#storageUnit.points+1] = pos
end

function removeFromCube(cube,pos)
	local storageUnit = findContainer(cube,pos)
	if (ValidTable(storageUnit.points)) then
		for k,v in pairs(points) do
			if (v.id == pos.id) then
				storageUnit.points[k] = nil
			end
		end
	end
end

function findNeighbors(cube,pos,validonly,goal,maxpathlength)
	local maxpathlength = tonumber(maxpathlength) or 2
	local validonly = IsNull(validonly,true)
	local neighbors = {}

	local storageUnit,storageUnitParent = findClosestChild(cube,pos)
	local nearestVertex = nil
	if (goal) then
		nearestVertex = getNearestVertex(storageUnit.vertices,goal)
	else
		nearestVertex = getNearestVertex(storageUnit.vertices,pos)
	end
	local neighborUnits = findAllContainers(cube,nearestVertex)
	
	local neighborSubset = {}
	for i,neighborUnit in pairs(neighborUnits) do
		local points = getAllPoints(neighborUnit)
		if (ValidTable(points)) then
			for j,point in pairs(points) do
				neighborSubset[#neighborSubset+1] = point
			end
		end
	end
	
	local insert = table.insert
	local atan2 = math.atan2
	local dist_between = dist_between
	
	local MIN_DIST = 5
	local MAX_DIST = 40
	
	local neighbors = {}
	if (validonly) then
		for _, node in pairs(neighborSubset) do
			local nodedist = dist_between(pos,node)
			if (nodedist >= MIN_DIST and nodedist <= MAX_DIST) then
				local pitch = atan2((pos.y - node.y),nodedist)
				if (pitch >= -.785 and pitch <= 1.377) then
					local path = NavigationManager:GetPath(pos.x,pos.y,pos.z,node.x,node.y,node.z)
					local tsize = TableSize(path)
					if (tsize >= 2 and tsize <= maxpathlength) then
						neighbors[#neighbors+1] = node
					else
						--d("node had ["..tostring(TableSize(path)).."] path points.")
					end
				end
			end
		end
	else
		for _, node in pairs(neighborSubset) do
			local nodedist = dist_between(pos,node)
			if (nodedist > 0) then
				neighbors[#neighbors+1] = node
			end
		end
	end
	
	return neighbors
end

function getNearestVertex(vertices,pos)
	local nearest = nil
	local nearestDistance = math.huge
		
	if (ValidTable(vertices)) then
		for i,vertex in pairs(vertices) do
			local dist = PDistance3D(vertex.x,vertex.y,vertex.z,pos.x,pos.y,pos.z)
			if (not nearest or (nearest and dist < nearestDistance)) then
				nearest = vertex
				nearestDistance = dist
			end
		end
	end
	return nearest
end

function getVertices(cube)
	local vertices = {}
	local size = cube.size
	local half = size * 0.5

	-- Upper Right - Positive Axis
	vertices[1] = { x = (cube.x + half), y = (cube.y + half), z = (cube.z + half) }
	-- Upper Left - Positive Axis
	vertices[2] = { x = (cube.x - half), y = (cube.y + half), z = (cube.z + half) }
	-- Lower Right - Positive Axis
	vertices[3] = { x = (cube.x + half), y = (cube.y + half), z = (cube.z - half) }
	-- Lower Left - Positive Axis
	vertices[4] = { x = (cube.x - half), y = (cube.y + half), z = (cube.z - half) }
	-- Upper Right - Negative Axis
	vertices[5] = { x = (cube.x + half), y = (cube.y - half), z = (cube.z + half) }
	-- Upper Left - Positive Axis
	vertices[6] = { x = (cube.x - half), y = (cube.y - half), z = (cube.z + half) }
	-- Lower Right - Negative Axis
	vertices[7] = { x = (cube.x + half), y = (cube.y - half), z = (cube.z - half) }
	-- Lower Left - Positive Axis
	vertices[8] = { x = (cube.x - half), y = (cube.y - half), z = (cube.z - half) }
	
	return vertices
end

function getBoundaries(cube)
	local size = cube.size
	local half = size * 0.5
	
	local boundaries = {
		xmin = cube.x - half, xmax = cube.x + half,
		ymin = cube.y - half, ymax = cube.y + half,
		zmin = cube.z - half, zmax = cube.z + half,
	}
	
	return boundaries
end

function bisectionalSearch(cube,pos)
	local nearest = nil
	local secondary = nil
	local nearestDist = math.huge
	local secondaryDist = math.huge
	
	for i,child in pairs(cube.children) do
		local dist = PDistance3D(pos.x,pos.y,pos.z,child.x,child.y,child.z)
		if (not nearest or (nearest and dist < nearestDist)) then
			nearestDist = dist
			nearest = child
		else
			if (not secondary or (secondary and dist < secondaryDist)) then
				secondaryDist = dist
				secondary = child
			end
		end
	end
	
	local closestChild,closestChildParent = findClosestChild(nearest,pos)
	local secondaryChild,secondaryChildParent = findClosestChild(secondary,pos)
	
	return closestChildParent,secondaryChildParent
end

function findContainer(cube,pos)
	local container = nil
	for i,child in pairs(cube.children) do
		if (child.boundaries.xmin <= pos.x and pos.x <= child.boundaries.xmax) then
			if (child.boundaries.ymin <= pos.y and pos.y <= child.boundaries.ymax) then
				if (child.boundaries.zmin <= pos.z and pos.z <= child.boundaries.zmax) then
					container = child
				end
			end
		end
		
		if (container) then
			break
		end
	end
	
	if (ValidTable(container.children)) then
		return findContainer(container,pos)
	else
		return container
	end
end

function findAllContainers(cube,pos)
	local returnables = {}
	local containers = findContainers(cube,pos)
	
	if (ValidTable(containers)) then
		local open = containers
		local closed = {}
	 
		while TableSize(open) > 0 do
			local i,container = next(open)
			
			if (ValidTable(container.children)) then
				local newcontainers = findContainers(container,pos)
				if (ValidTable(newcontainers)) then
					for j,child in pairs(newcontainers) do
						table.insert(open,child)
					end
				end
			else
				table.insert(closed,container)
			end
			table.remove(open,i)
		end
		
		return closed
	end
	return nil
end

function findContainers(cube,pos)
	local containers = {}
	for i,child in pairs(cube.children) do
		if (child.boundaries.xmin <= pos.x and pos.x <= child.boundaries.xmax) then
			if (child.boundaries.ymin <= pos.y and pos.y <= child.boundaries.ymax) then
				if (child.boundaries.zmin <= pos.z and pos.z <= child.boundaries.zmax) then
					table.insert(containers,child)
				end
			end
		end
	end
	
	return containers
end

function findClosestChild(cube,pos)
	local nearest = nil
	local nearestDist = math.huge
	
	for i,child in pairs(cube.children) do
		local dist = PDistance3D(pos.x,pos.y,pos.z,child.x,child.y,child.z)
		if (not nearest or (nearest and dist < nearestDist)) then
			nearestDist = dist
			nearest = child
		end
	end
	
	if (ValidTable(nearest.children)) then
		return findClosestChild(nearest,pos)
	else
		-- Return the child and the parent for easy access
		return nearest,cube
	end
end

function findCloseChildren(cube,pos,returnables)
	returnables = IsNull(returnables,{})
	
	local nearest = nil
	local nearestDist = math.huge
	
	for i,child in pairs(cube.children) do
		local dist = PDistance3D(pos.x,pos.y,pos.z,child.x,child.y,child.z)
		if (not nearest or (nearest and dist < nearestDist)) then
			nearestDist = dist
			nearest = child
		elseif (nearest and dist == nearestDist) then
			returnables[#returnables+1] = child
		end
	end
	
	if (ValidTable(nearest.children)) then
		return findCloseChildren(nearest,pos)
	else
		-- Return the child and the parent for easy access
		return nearest,cube
	end
end

function getAllPoints(cube)
	local points = {}
	if (ValidTable(cube.points)) then
		for _,point in pairs(cube.points) do
			points[#points+1] = point
		end
	end
	
	return points
end

function isJunction(point)
	local raycast = MeshManager:RayCast(point.x,point.y,point.z,point.x,point.y - 10,point.z)
	if (raycast == true) then
		local raycast2,hitX,hitY,hitZ = MeshManager:RayCast(point.x,point.y,point.z,point.x,point.y - 4,point.z)
		if (raycast2 == nil) then
			point.isjunction = true
			return point
		elseif (raycast2 == true) then
			local dist = PDistance3D(point.x,point.y,point.z,hitX,hitY,hitZ)
			point.y = point.y + (4 - dist)
			point.isjunction = true
			return point
		end		
	end
	
	point.isjunction = false
	return point
end

function ffxiv_task_test:Init()
	local ke_startMapTest = ml_element:create( "GoToMapTest", c_gotomaptest, e_gotomaptest, 20 )
    self:add(ke_startMapTest, self.process_elements)
	
	local ke_startMoveTest = ml_element:create( "GoToPosTest", c_gotopostest, e_gotopostest, 15 )
    self:add(ke_startMoveTest, self.process_elements)
	
	local ke_flightTest = ml_element:create( "FlightTest", c_flighttest, e_flighttest, 15 )
    self:add(ke_flightTest, self.process_elements)
end

function ffxiv_task_test.UIInit()
	if ( not ffxivminion.Windows) then
		ffxivminion.Windows = {}
	end
    ffxivminion.Windows.Test = { id = "Test", Name = "NavTest", x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Test)
	
	if (Settings.FFXIVMINION.gTestRecordPattern == nil) then
		Settings.FFXIVMINION.gTestRecordPattern = "Basic"
	end
	if (Settings.FFXIVMINION.gTestRecordTolerance == nil) then
		Settings.FFXIVMINION.gTestRecordTolerance = 5
	end
	if (Settings.FFXIVMINION.gTestRecordPadding == nil) then
		Settings.FFXIVMINION.gTestRecordPadding = 7
	end
	if (Settings.FFXIVMINION.gTestRecordThrottle == nil) then
		Settings.FFXIVMINION.gTestRecordThrottle = 1500
	end
	if (Settings.FFXIVMINION.gTestMapID == nil) then
		Settings.FFXIVMINION.gTestMapID = ""
	end
	if (Settings.FFXIVMINION.gTestMapX == nil) then
		Settings.FFXIVMINION.gTestMapX = ""
	end
	if (Settings.FFXIVMINION.gTestMapY == nil) then
		Settings.FFXIVMINION.gTestMapY = ""
	end
	if (Settings.FFXIVMINION.gTestMapZ == nil) then
		Settings.FFXIVMINION.gTestMapZ = ""
	end
	
	local winName = "NavTest"
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
    GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
	
	GUI_NewCheckbox(winName,"Record Flight Points","gTestRecordFlight","FlightMesh")
	GUI_NewCheckbox(winName,"Delete Flight Points","gTestDeleteFlight","FlightMesh")
	GUI_NewCheckbox(winName,"Update Flight Points","gTestUpdateFlight","FlightMesh")
	GUI_NewComboBox(winName,"Record Pattern","gTestRecordPattern","FlightMesh","Basic,Cube,Matrix,Laser,LaserX")
	GUI_NewField(winName,"Tolerance","gTestRecordTolerance","FlightMesh")
	GUI_NewField(winName,"Padding","gTestRecordPadding","FlightMesh")
	GUI_NewField(winName,"Throttle","gTestRecordThrottle","FlightMesh")
	
	GUI_NewButton(winName, 	"Save Mesh", 	"ffxiv_task_test.SaveFlightMesh", "FlightMesh")
	GUI_NewButton(winName, 	"Read Mesh", 	"ffxiv_task_test.ReadFlightMesh", "FlightMesh")
	GUI_NewButton(winName, 	"Prune Mesh", 	"ffxiv_task_test.PruneFlightMesh", "FlightMesh")
	GUI_NewButton(winName, 	"Get Path", 	"ffxiv_task_test.GetPath", "FlightMesh")
	
	GUI_NewButton(winName, "Face Next Path", "ffxiv_task_test.FaceNextPath", "FlightMesh")
	--GUI_NewButton(winName, "Nearest Mesh Point", "ffxiv_task_test.NearestMeshPoint", "FlightMesh")
	GUI_NewButton(winName, "Insert Into Tree", "ffxiv_task_test.InsertIntoTree", "FlightMesh")
	GUI_NewButton(winName, "Find Neighbors", "ffxiv_task_test.FindNeighbors", "FlightMesh")
	GUI_NewButton(winName, 	"Test Instructions", 	"ffxiv_task_test.TestInstructions", "FlightMesh")
	
    GUI_NewField(winName, "MapID:", "gTestMapID","NavTest")
	GUI_NewField(winName, "X:", "gTestMapX","NavTest")
	GUI_NewField(winName, "Y:", "gTestMapY","NavTest")
	GUI_NewField(winName, "Z:", "gTestMapZ","NavTest")
	GUI_NewButton(winName, "Get Current Position", "ffxiv_navtestGetPosition", "NavTest")
	GUI_NewButton(winName, "Test Shop Vendor", "ffxiv_task_test.TestShopVendor", "NavTest")
	GUI_NewButton(winName, "Press Mouse", "ffxiv_task_test.PressMouse", "NavTest")
	GUI_NewButton(winName, "Face Position", "ffxiv_task_test.FacePosition", "NavTest")
	GUI_NewButton(winName, "Draw Rectangle", "ffxiv_task_test.DrawRectangle", "NavTest")
	GUI_NewButton(winName, "Inside Rectangle", "ffxiv_task_test.IsInsideRect", "NavTest")
	
	gTestRecordTolerance = Settings.FFXIVMINION.gTestRecordTolerance
	gTestRecordPattern = Settings.FFXIVMINION.gTestRecordPattern
	gTestRecordPadding = Settings.FFXIVMINION.gTestRecordPadding
	gTestRecordThrottle = Settings.FFXIVMINION.gTestRecordThrottle
	gTestMapID = Settings.FFXIVMINION.gTestMapID
	gTestMapX = Settings.FFXIVMINION.gTestMapX
	gTestMapY = Settings.FFXIVMINION.gTestMapY
	gTestMapZ = Settings.FFXIVMINION.gTestMapZ
	
	GUI_UnFoldGroup(winName,GetString("status"))
	GUI_UnFoldGroup(winName,"FlightMesh")
	GUI_UnFoldGroup(winName,"NavTest")
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
end

function ffxiv_task_test.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
		if (k == "gTestMapX" or
			k == "gTestMapY" or
			k == "gTestMapZ" or 
			k == "gTestRecordTolerance" or
			k == "gTestRecordPattern" or
			k == "gTestRecordPadding" or
			k == "gTestRecordThrottle") 
		then
			Settings.FFXIVMINION[tostring(k)] = v
		elseif (k == "gTestRecordFlight") then
			if (v == "1") then
				ffxiv_task_test.RenderPoints(ffxiv_task_test.flightMesh)
				gTestDeleteFlight = "0"
				gTestUpdateFlight = "0"
			end
		elseif (k == "gTestDeleteFlight") then
			if (v == "1") then
				ffxiv_task_test.RenderPoints(ffxiv_task_test.flightMesh)
				gTestRecordFlight = "0"
				gTestUpdateFlight = "0"
			end
		elseif (k == "gTestUpdateFlight") then
			if (v == "1") then
				ffxiv_task_test.RenderPoints(ffxiv_task_test.flightMesh)
				gTestDeleteFlight = "0"
				gTestRecordFlight = "0"
			end
		end
	end
end

function ffxiv_task_test.DrawRectangle()
	local rectangle = AceLib.API.Math.ComputeRectangle(Player.pos,5,3)
	if (ValidTable(rectangle)) then
		ffxiv_task_test.RenderPoints(rectangle)
		ffxiv_task_test.lastRect = rectangle
	end
end

function ffxiv_task_test.IsInsideRect()
	d(AceLib.API.Math.IsInsideRectangle(Player.pos,ffxiv_task_test.lastRect))
end

function ffxiv_task_test.OnUpdate( event, tickcount )
	local recordSpeed = tonumber(gTestRecordThrottle) or 1000
	if (TimeSince(ffxiv_task_test.lastTick) >= recordSpeed) then
		ffxiv_task_test.lastTick = Now()
		
		if (gTestRecordFlight == "1") then
			local mesh = ffxiv_task_test.flightMesh
			local newPoints = ffxiv_task_test.GetFlightPoints()
			local ppos = Player.pos
			local renderedPoints = {}
			local recordPadding = tonumber(gTestRecordPadding) or 8
			
			if (ValidTable(newPoints)) then
				--d("Have new points to check.")
				for k,v in pairs(newPoints) do
					local allowed = true
					
					local neighbors = findNeighbors(ffxiv_task_test.storageCube,v,false)
					if (ValidTable(neighbors)) then
						for i,neighbor in pairs(neighbors) do
							local dist = PDistance3D(neighbor.x,neighbor.y,neighbor.z,v.x,v.y,v.z)
							if (dist < recordPadding) then
								allowed = false
								break
							end
						end
					end

					if (allowed) then
						local raycast = MeshManager:RayCast(ppos.x,ppos.y,ppos.z,v.x,v.y,v.z)
						if (raycast == nil) then
							v.id = TableSize(mesh)+1
							table.insert(mesh,v)
							insertIntoCube(ffxiv_task_test.storageCube,v)
							table.insert(renderedPoints,v)
						end
						
						--d("Passed first check.")
						--local p,dist = NavigationManager:GetClosestPointOnMesh(v)
						--if (not p or (p and (dist > 2 or dist == 0))) then
							--v.id = TableSize(mesh)+1
							--table.insert(mesh,v)
							--table.insert(renderedPoints,v)
							--d("Adding a new point.")
						--end
					end
				end
				
				if (ValidTable(renderedPoints)) then
					--d("Rendering new points.")
					ffxiv_task_test.RenderPoints(renderedPoints)
				end
			end
		end

		if (gTestDeleteFlight == "1") then
			local mesh = ffxiv_task_test.flightMesh
			local renderedPoints = {}
			
			local v = ml_global_information.Player_Position
			
			for i,j in pairs(mesh) do
				local dist = PDistance3D(j.x,j.y,j.z,v.x,v.y,v.z)
				if (dist < 8) then
					mesh[i] = nil
					table.insert(renderedPoints,j)
				end
			end
			
			if (ValidTable(renderedPoints)) then
				--d("Rendering new points.")
				ffxiv_task_test.RenderPoints(renderedPoints,1)
			end
		end		

		if (gTestUpdateFlight == "1") then		
			local mesh = ffxiv_task_test.flightMesh
			local renderedPoints = {}
			
			local v = ml_global_information.Player_Position
			local neighbors = findNeighbors(ffxiv_task_test.storageCube,v,false)
			if (ValidTable(neighbors)) then
				for i,neighbor in pairs(neighbors) do
					neighbor = isJunction(neighbor)
					if (neighbor.isjunction == true) then
						table.insert(renderedPoints,neighbor)
					end
					--d("altering id ["..tostring(neighbor.id).."].")
					mesh[neighbor.id] = neighbor
				end
			end
			
			if (ValidTable(renderedPoints)) then
				ffxiv_task_test.RenderPoints(renderedPoints,4)
			end
		end
	end
	
	--[[
	if (gBotRunning == "1") then
		if (TimeSince(ffxiv_task_test.lastTick) >= 1000) then
			ffxiv_task_test.lastTick = Now()
			
			local tasks = {}
			local level = 1
			
			if (ml_task_hub:RootTask()) then
				local task = ml_task_hub:RootTask()
				currTask = nil
				while (task ~= nil) do
					tasks[level] = task.name
					currTask = task
					task = task.subtask
					level = level + 10
				end
			end
			
			if (not deepcompare(tasks,ffxiv_task_test.lastTaskSet,true)) then
				local winName = "NavTest"
				GUI_DeleteGroup(winName,"Tasks")
				if (TableSize(tasks) > 0) then
					for k,v in spairs(tasks) do
						GUI_NewButton(winName, tostring(k).."("..v..")", "TestViewTask"..tostring(k), "Tasks")
					end
					GUI_UnFoldGroup(winName,"Tasks")
				end
				ffxiv_task_test.lastTaskSet = tasks
				
				ffxivminion.SizeWindow(winName)
				GUI_RefreshWindow(winName)
			end
		end
	end
	--]]
end

function ffxiv_task_test.GetCurrentPosition()
	local mapid = Player.localmapid
	local pos = Player.pos
	
	gTestMapX = pos.x
	gTestMapY = pos.y
	gTestMapZ = pos.z
	gTestMapID = mapid
	
	Settings.FFXIVMINION.gTestMapID = gTestMapID
	Settings.FFXIVMINION.gTestMapX = gTestMapX
	Settings.FFXIVMINION.gTestMapY = gTestMapY
	Settings.FFXIVMINION.gTestMapZ = gTestMapZ
end

function ffxiv_task_test.TestShopVendor()
	local vendor = AceLib.API.Items.FindNearestPurchaseLocation(2586)
	if (vendor) then
		local mapid = vendor.mapid
		local pos = vendor.pos
		
		gTestMapX = pos.x
		gTestMapY = pos.y
		gTestMapZ = pos.z
		gTestMapID = mapid
		
		Settings.FFXIVMINION.gTestMapID = gTestMapID
		Settings.FFXIVMINION.gTestMapX = gTestMapX
		Settings.FFXIVMINION.gTestMapY = gTestMapY
		Settings.FFXIVMINION.gTestMapZ = gTestMapZ
		
		local newTask = ffxiv_task_test.Create()
		ml_task_hub:ClearQueues()
		ml_task_hub.shouldRun = true
		gBotRunning = "1"
		ml_task_hub:Add(newTask, LONG_TERM_GOAL, TP_ASAP)
	else
		d("Did not find a vendor for the item.")
	end
end

function ffxiv_task_test.FacePosition()
	Player:SetFacingSynced(tonumber(gTestMapX),tonumber(gTestMapY),tonumber(gTestMapZ))
end

function ffxiv_task_test.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item") then
		if (Button == "ffxiv_navtestGetPosition") then
			ffxiv_task_test.GetCurrentPosition()
		elseif (Button == "ffxiv_navtestTestRender") then
			ffxiv_task_test.RenderPoints()
		elseif (string.find(Button,"ffxiv_task_test%.")) then
			ExecuteFunction(Button)
		end
	end
end

RegisterEventHandler("GUI.Update",ffxiv_task_test.GUIVarUpdate)
RegisterEventHandler("GUI.Item",ffxiv_task_test.HandleButtons)
RegisterEventHandler("Gameloop.Update",ffxiv_task_test.OnUpdate)

----------------------------------------------------------------
-- A* Implementation Library
----------------------------------------------------------------

local INF = 1/0
local cachedPaths = nil
local insert = table.insert
local atan2 = math.atan2
local asin = math.asin
local dist_3d = PDistance3D

function dist ( x1, y1, z1, x2, y2, z2 )
	return dist_3d(x1,y1,z1,x2,y2,z2)
end

function dist_between ( nodeA, nodeB )
	return dist( nodeA.x, nodeA.y, nodeA.z, nodeB.x, nodeB.y, nodeB.z )
end

function heuristic_cost_estimate ( nodeA, nodeB )
	return dist(nodeA.x, nodeA.y, nodeA.z, nodeB.x, nodeB.y, nodeB.z )
end

function is_valid_node ( node, neighbor )
	local MIN_DIST = 5
	local MAX_DIST = 30		
	local nodedist = dist_between(node,neighbor)
	if (nodedist >= MIN_DIST and nodedist <= MAX_DIST) then
		--local pitch = atan2((node.y - neighbor.y),nodedist)
		local pitch = asin((node.y - neighbor.y)/nodedist)
		if (pitch >= -.785 and pitch <= 1.38) then
			return true
		end
	end
	return false
end

function lowest_f_score ( set, f_score )

	local lowest, bestNode = INF, nil
	for _, node in pairs ( set ) do
		local score = f_score [ node ]
		if score < lowest then
			lowest, bestNode = score, node
		end
	end
	return bestNode
end

function neighbor_nodes(thisNode, goal)
	local neighbors = findNeighbors(ffxiv_task_test.storageCube,{x = thisNode.x, y = thisNode.y, z = thisNode.z},true,goal,2)
	return neighbors
end

--[[function neighbor_nodes ( theNode, nodes )
	local insert = table.insert
	local atan2 = math.atan2
	local dist_between = dist_between
	
	local MIN_DIST = 7
	local MAX_DIST = 30	
	
	local neighbors = {}
	for _, node in pairs ( nodes ) do
		if theNode ~= node then
			local nodedist = dist_between(theNode,node)
			if (nodedist >= MIN_DIST and nodedist <= MAX_DIST) then
				local raycast = MeshManager:RayCast(theNode.x,theNode.y,theNode.z,node.x,node.y,node.z)
				if (raycast == nil) then
					local pitch = atan2((theNode.y - node.y),nodedist)
					if (pitch >= -.785 and pitch <= 1.38) then
						insert( neighbors, node )
					end
				end
			end
		end
	end
	
	return neighbors
end
--]]

function not_in ( set, theNode )
	for _, node in pairs ( set ) do
		if node == theNode then return false end
	end
	return true
end

function remove_node ( set, theNode )
	for i, node in pairs ( set ) do
		if node == theNode then 
			set [ i ] = set [ #set ]
			set [ #set ] = nil
			break
		end
	end	
end

function unwind_path ( flat_path, map, current_node )
	if map [ current_node ] then
		insert( flat_path, 1, map [ current_node ] ) 
		return unwind_path ( flat_path, map, map [ current_node ] )
	else
		return flat_path
	end
end

----------------------------------------------------------------
-- pathfinding functions
----------------------------------------------------------------

function a_star ( start, goal, nodes, valid_node_func )
	local closedset = {}
	local openset = { start }
	local came_from = {}

	if valid_node_func then is_valid_node = valid_node_func end
	
	local g_score, f_score = {}, {}
	g_score [ start ] = 0
	f_score [ start ] = g_score [ start ] + heuristic_cost_estimate ( start, goal )

	while #openset > 0 do
	
		local current = lowest_f_score ( openset, f_score )
		if current == goal then
			local path = unwind_path ( {}, came_from, goal )
			insert( path, goal )
			return path
		end

		remove_node( openset, current )		
		insert( closedset, current )
		
		local neighbors = neighbor_nodes ( current, goal )
		if (ValidTable(neighbors)) then
			for _, neighbor in pairs ( neighbors ) do 
				if not_in ( closedset, neighbor ) then
				
					--local tentative_g_score = g_score [ current ] + (dist_between(current,neighbor )*.05)
					local tentative_g_score = g_score [ current ] + 1
					
					if not_in ( openset, neighbor ) or tentative_g_score < g_score [ neighbor ] then 
						came_from 	[ neighbor ] = current
						g_score 	[ neighbor ] = tentative_g_score
						f_score 	[ neighbor ] = g_score [ neighbor ] + heuristic_cost_estimate ( neighbor, goal )
						if not_in( openset, neighbor ) then
							insert( openset, neighbor )
						end
					end
				end
			end
		--else
			--local unavailable = {}
			--table.insert(unavailable,current)
			--ffxiv_task_test.RenderPoints(unavailable,4)
			--d("node has no neighbors")
		end
	end
	return nil
end

----------------------------------------------------------------
-- exposed functions
----------------------------------------------------------------

function clear_cached_paths ()
	cachedPaths = nil
end

function path ( start, goal, nodes, ignore_cache, valid_node_func )

	if not cachedPaths then cachedPaths = {} end
	if not cachedPaths [ start ] then
		cachedPaths [ start ] = {}
	elseif cachedPaths [ start ] [ goal ] and not ignore_cache then
		return cachedPaths [ start ] [ goal ]
	end
	
	return a_star ( start, goal, nodes, valid_node_func )
end


local base = {	size = 2000, x = 0, y = 0, z = 0, children = {} }
--local base = { size = 20, x = Player.pos.x, y = Player.pos.y, z = Player.pos.z }
local count = 0
local insert = table.insert
local courseFlight = ffxiv_task_test.courseFlight

function quadrasectCube(cube,depth,maxdepth,raylevel)
	local depth = depth or 1
	local maxdepth = maxdepth or 6
	local raylevel = raylevel or 5
	local newcube = {}
	
	local courseFlight = ffxiv_task_test.courseFlight
	
	if (IsTable(cube)) then
		local size = cube.size * 0.5
		local half = size * 0.5
		for x = 1,8 do
			newcube = {}
			if (x == 1) then
				-- Upper Right - Positive Axis
				newcube = { size = size, x = (cube.x + half), y = (cube.y + half), z = (cube.z + half), children = {} }
			elseif (x == 2) then
				-- Upper Left - Positive Axis
				newcube = { size = size, x = (cube.x - half), y = (cube.y + half), z = (cube.z + half), children = {} }
			elseif (x == 3) then
				-- Lower Right - Positive Axis
				newcube = { size = size, x = (cube.x + half), y = (cube.y + half), z = (cube.z - half), children = {} }
			elseif (x == 4) then
				-- Lower Left - Positive Axis
				newcube = { size = size, x = (cube.x - half), y = (cube.y + half), z = (cube.z - half), children = {} }
			elseif (x == 5) then
				-- Upper Right - Negative Axis
				newcube = { size = size, x = (cube.x + half), y = (cube.y - half), z = (cube.z + half), children = {} }
			elseif (x == 6) then
				-- Upper Left - Positive Axis
				newcube = { size = size, x = (cube.x - half), y = (cube.y - half), z = (cube.z + half), children = {} }
			elseif (x == 7) then
				-- Lower Right - Negative Axis
				newcube = { size = size, x = (cube.x + half), y = (cube.y - half), z = (cube.z - half), children = {} }
			elseif (x == 8) then
				-- Lower Left - Positive Axis
				newcube = { size = size, x = (cube.x - half), y = (cube.y - half), z = (cube.z - half), children = {} }
			end
			if (newcube.y >= -500 and newcube.y <= 500) then
				if (cube.children == nil) then cube.children = {} end
				if (raylevel ~= 0 and depth == raylevel) then
					local raycast = MeshManager:RayCast(newcube.x,newcube.y,newcube.z,newcube.x,newcube.y - 150,newcube.z)
					if (raycast == true) then
						table.insert(ffxiv_task_test.courseFlight,{x = newcube.x, y = newcube.y, newcube.z})
					end
				end
				newcube.vertices = getVertices(newcube)
				newcube.boundaries = getBoundaries(newcube)
				insert(cube.children,newcube)
			end
		end
	end
	
	if (IsTable(cube.children) and depth < maxdepth) then
		for k,child in pairs(cube.children) do
			quadrasectCube(child,depth+1,maxdepth)
		end
	end
end

function quadrasectTest()
	local renderedPoints = {}
	
	quadrasectCube(base,1,5)
	
	--table.insert(renderedPoints,{x = Player.pos.x, y = Player.pos.y, z = Player.pos.z })
	for a,b in pairs(base.children) do
		--table.insert(renderedPoints,{ x = b.x, y = b.y, z = b.z })
		--d("level = 1")
		--d("size = "..tostring(v.size))
		--d("xyz = "..tostring(v.x)..","..tostring(v.y)..","..tostring(v.z))
		for c,e in pairs(b.children) do
			--table.insert(renderedPoints,{ x = d.x, y = d.y, z = d.z })
			--d("level = 2")
			--d("size = "..tostring(e.size))
			--d("xyz = "..tostring(e.x)..","..tostring(e.y)..","..tostring(e.z))
			if (IsTable(e.children)) then
				for f,g in pairs(e.children) do
					--table.insert(renderedPoints,{ x = f.x, y = f.y, z = f.z })
					--d("level = 3")
					--d("size = "..tostring(i.size))
					--d("xyz = "..tostring(i.x)..","..tostring(i.y)..","..tostring(i.z))
					if (IsTable(g.children)) then
						for h,i in pairs(g.children) do
							--d("level = 4")
							--d("size = "..tostring(i.size))
							--d("xyz = "..tostring(i.x)..","..tostring(i.y)..","..tostring(i.z))
							if (IsTable(i.children)) then
								for j,k in pairs(i.children) do
									table.insert(renderedPoints,{ x = k.x, y = k.y, z = k.z })
									--d("level = 5")
									--d("size = "..tostring(k.size))
									--d("xyz = "..tostring(i.x)..","..tostring(i.y)..","..tostring(i.z))
								end
							end
						end
					end
				end
			end
		end
	end
	
	if (renderedPoints) then
		d("Rendering points.")
		ffxiv_task_test.RenderPoints(renderedPoints,4,2,2)
	end
end

Vector = {}
Vector.__index = Vector
function Vector.Create(posA,posB)
    local newinst = {}
    
	newinst.origin = posA
	newinst.goal = posB
	newinst.x = IIF(posA.x ~= nil and posB.x ~= nil,(posB.x - posA.x),0)
	newinst.y = IIF(posA.y ~= nil and posB.y ~= nil,(posB.y - posA.y),0)
	newinst.z = IIF(posA.z ~= nil and posB.z ~= nil,(posB.z - posA.z),0)

	setmetatable( newinst, Vector )
    return newinst
end

function Vector:DotProduct(vectorB)
	return (self.x * vectorB.x) + (self.z * vectorB.z)	
end

function Vector:CrossProduct(vectorB)
	return (self.x * vectorB.z) - (self.z * vectorB.x)
end

function Vector:AngleBetween(vectorB)
	local atan2 = math.atan2
	return (atan2(self:CrossProduct(vectorB),self:DotProduct(vectorB)))
end

function ToDegrees(ANGLE)
	return ANGLE * (180 / math.pi)
end

function ToRadians(ANGLE)
	return ANGLE * (math.pi / 180)
end

function Vector:Magnitude()
	local sqrt = math.sqrt
	return sqrt((self.x * self.x) + (self.y * self.y) + (self.z * self.z))
end

function Vector:Rotate(degrees)
	local newinst = deepcopy(self)
	
	local radians = ToRadians(degrees)
	local ca = math.cos(radians)
	local sa = math.sin(radians)
	
	local newX = ((ca * newinst.x) - (sa * newinst.z))
	local newZ = ((sa * newinst.x) + (ca * newinst.z))
	
	newinst.goal = { x = (newX + newinst.origin.x), y = IsNull(newinst.origin.y,0), z = (newZ + newinst.origin.z) }
	
	newinst.x = newX
	newinst.z = newZ

    return newinst
end

function Vector:Normalize()
	local newinst = deepcopy(self)
	
	local magnitude = self:Magnitude()
	newinst.x = IIF(newinst.x ~= 0,newinst.x / magnitude,0)
	newinst.y = IIF(newinst.y ~= 0,newinst.y / magnitude,0)
	newinst.z = IIF(newinst.z ~= 0,newinst.z / magnitude,0)
	
	newinst.goal = { x = (newinst.x + newinst.origin.x), y = (newinst.y  + newinst.origin.y), z = (newinst.z + newinst.origin.z) }
end

function Vector:RatioAdjust(ratio)		
	local newinst = deepcopy(self)
	
	local newX = (newinst.x * ratio)
	local newY = (newinst.y * ratio)
	local newZ = (newinst.z * ratio)
	
	newinst.goal = { x = (newX + newinst.origin.x), y = (newY + newinst.origin.y), z = (newZ + newinst.origin.z) }
	
	newinst.x = newX
	newinst.y = newY
	newinst.z = newZ
	
	return newinst
end

function Vector:RayCast()
	local raycast_b,hitX,hitY,hitZ = MeshManager:RayCast(self.origin.x,self.origin.y,self.origin.z,self.goal.x,self.goal.y,self.goal.z)
	if (raycast_b == true) then
		return { x = hitX, y = hitY, z = hitZ }
	end
	
	return nil
end

function vector(posA,posB)
	return { x = (posB.x - posA.x), y = (posB.y - posA.y), z = (posB.z - posA.z) }	
end

function dot(vectorA,vectorB)
	return (vectorA.x *vectorB.x) + (vectorA.z * vectorB.z)		
end

function cross(vectorA,vectorB)
	return (vectorA.x * vectorB.z) - (vectorA.z * vectorB.x)	
end

function angle(vectorA,vectorB)
	return (math.atan2(cross(vectorA,vectorB),dot(vectorA,vectorB)))
end

function toDegrees(angleA)
	return angleA * (180 / math.pi)
end

function toRadians(angleA)
	return angleA * (math.pi / 180)
end

function rotateVector(vector, degrees)
	local radians = toRadians(degrees)
	local ca = math.cos(radians)
	local sa = math.sin(radians)
	return { x = ((ca * vector.x) - (sa * vector.z)), z = ((sa * vector.x) + (ca * vector.z)) }
end

function pointFromVector(vector,pos)
	return { x = (vector.x + pos.x), z = (vector.z + pos.z) }
end

--[[
function ffxiv_task_test.FaceNextPath()
	local myPos = ml_global_information.Player_Position
	local forwardPos = GetPosFromDistanceHeading(Player.pos, 8, Player.pos.h)
	local newPos = IIF(math.random(1,2) == 1,testPosC,testPosE)
	
	local currentVector = Vector.Create(ml_global_information.Player_Position,forwardPos)
	local goalVector = Vector.Create(myPos,newPos)
	local differenceAngle = ToDegrees(currentVector:AngleBetween(goalVector))
	
	if (math.abs(differenceAngle) > 60) then
		if (differenceAngle < 0) then
			local rotatedVector = currentVector:Rotate(-60)
			local newPoint = rotatedVector.goal
			Player:SetFacing(newPoint.x,0,newPoint.z)
		else
			local rotatedVector = currentVector:Rotate(60)
			local newPoint = rotatedVector.goal
			Player:SetFacing(newPoint.x,0,newPoint.z)
		end
	else
		Player:SetFacing(newPos.x,newPos.y,newPos.z)
	end
end
-]]

--[[
function ffxiv_task_test.FaceNextPath()
	local newPoints = {}
	
	local myPos = ml_global_information.Player_Position
	local forwardPos = GetPosFromDistanceHeading(myPos, 15, myPos.h)
	table.insert(newPoints,forwardPos)
	
	local currentVector = Vector.Create(myPos,forwardPos)
	local reducedVector = currentVector:RatioAdjust(.80)
	local magnifiedVector = currentVector:RatioAdjust(1.20)
	
	table.insert(newPoints,reducedVector.goal)
	table.insert(newPoints,magnifiedVector.goal)
	
	ffxiv_task_test.RenderPoints(newPoints)
end--]]

function ffxiv_task_test.FaceNextPath()	
	local newPoints = {}
	
	local target = Player:GetTarget()
	if (target ~= nil) then
	
		local myPos = ml_global_information.Player_Position
		myPos = { x = myPos.x, y = myPos.y + 1.60, z = myPos.z }
		local epos = target.pos
		
		local currentVector = Vector.Create(myPos,epos)
		local reducedVector = currentVector:RatioAdjust(.80)
		local magnifiedVector = currentVector:RatioAdjust(1.20)
		
		table.insert(newPoints,magnifiedVector.goal)
		local hitPoint = magnifiedVector:RayCast()
		
		if (hitPoint ~= nil) then
			table.insert(newPoints,hitPoint)
			
			local dist = PDistance3D(hitPoint.x,hitPoint.y,hitPoint.z,epos.x,epos.y,epos.z)
			d("distance from entity:"..tostring(dist))
			d("hitradius:"..tostring(target.hitradius))
			
			dist = PDistance3D(hitPoint.x,hitPoint.y,hitPoint.z,myPos.x,myPos.y,myPos.z)
			d("distance from wall:"..tostring(dist))
		end
		
		ffxiv_task_test.RenderPoints(newPoints)
	end
end

function SmartTurn(newPos)
	local originalPos = newPos
	local myPos = Player.pos
	local forwardPos = GetPosFromDistanceHeading(myPos, 8, myPos.h)
	
	local currentVector = Vector.Create(myPos,forwardPos)
	local goalVector = Vector.Create(myPos,newPos)
	local differenceAngle = ToDegrees(currentVector:AngleBetween(goalVector))
	
	if (math.abs(differenceAngle) > 60) then
		if (differenceAngle < 0) then
			local rotatedVector = currentVector:Rotate(-60)
			local newPos = rotatedVector.goal
		else
			local rotatedVector = currentVector:Rotate(60)
			local newPos = rotatedVector.goal
		end
	end
	
	Player:SetFacing(newPos.x,newPos.y,newPos.z)
end
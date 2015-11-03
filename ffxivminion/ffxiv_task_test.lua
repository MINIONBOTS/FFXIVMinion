ffxiv_task_test = inheritsFrom(ml_task)
ffxiv_task_test.lastTick = 0
ffxiv_task_test.flightMesh = {}
ffxiv_task_test.lastTaskSet = {}
ffxiv_task_test.lastRect = {}

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
	if (gTestUseFlight == "1") then
		return false
	end
	
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
e_gotopostest.pos = nil
function c_gotopostest:evaluate()
	if (gTestUseFlight == "1") then
		return false
	end
	
	local mapID = tonumber(gTestMapID)
	if (Player.localmapid == mapID) then
		local ppos = shallowcopy(Player.pos)
		local pos = {}
		pos.x = tonumber(gTestMapX)
		pos.y = tonumber(gTestMapY)
		pos.z = tonumber(gTestMapZ)
		if (Distance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z) > 10) then
			e_gotopostest.pos = pos
			return true
		end
	end
	return false
end
function e_gotopostest:execute()
	local newTask = ffxiv_task_movetopos.Create()
	if (gTeleport == "1") then
		newTask.useTeleport = true
	end
	newTask.remainMounted = true
	newTask.clearAggressive = true
	newTask.pos = e_gotopostest.pos
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_flighttest = inheritsFrom( ml_cause )
e_flighttest = inheritsFrom( ml_effect )
e_flighttest.pos = nil
e_flighttest.path = nil
function c_flighttest:evaluate()
	if (gTestUseFlight == "0") then
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

c_flighttakeoff = inheritsFrom( ml_cause )
e_flighttakeoff = inheritsFrom( ml_effect )
function c_flighttakeoff:evaluate()
	if (not Player.flying.isflying and Player.flying.canflyinzone and Player.ismounted) then

		local ppos = ml_global_information.Player_Position
		local nearestJunction = ffxiv_task_test.GetNearestFlightJunction(ppos)
		if (nearestJunction) then
			local dist = Distance3D(ppos.x,ppos.y,ppos.z,nearestJunction.x,nearestJunction.y,nearestJunction.z)
			if (dist < 10) then
				return true
			else
				d("Attempt to take off.")
			end
		end	
	end
	return false
end
function e_flighttakeoff:execute()
	Player:Jump()
	Player:Jump()
end

c_walktotakeoff = inheritsFrom( ml_cause )
e_walktotakeoff = inheritsFrom( ml_effect )
e_walktotakeoff.pos = nil
function c_walktotakeoff:evaluate()
	if (not Player.flying.isflying and Player.flying.canflyinzone and Player.ismounted) then
		
		e_walktotakeoff.pos = nil
		
		local ppos = ml_global_information.Player_Position
		local nearestJunction = ffxiv_task_test.GetNearestFlightJunction(ppos)
		if (nearestJunction) then
			local dist = Distance3D(ppos.x,ppos.y,ppos.z,nearestJunction.x,nearestJunction.y,nearestJunction.z)
			if (dist >= 10) then
				e_walktotakeoff.pos = nearestJunction
				return true
			end
		end
	end
	
	return false
end
function e_walktotakeoff:execute()
	local newTask = ffxiv_task_movetopos.Create()
	if (gTeleport == "1") then
		newTask.useTeleport = true
	end
	newTask.remainMounted = true
	newTask.pos = e_walktotakeoff.pos
	newTask.range = 5
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_flytopos = inheritsFrom( ml_cause )
e_flytopos = inheritsFrom( ml_effect )
c_flytopos.pos = nil
c_flytopos.path = nil
function c_flytopos:evaluate()
	if (not Player.flying.canflyinzone) then
		return false
	end
	
	if (ml_global_information.landing == true) then
		if (not ml_global_information.Player_IsLocked) then
			ml_global_information.landing = false
		else
			d("Currently landing and locked, do not attempt to fly again.")
			return false
		end
	end
	
	c_flytopos.pos = nil
	c_flytopos.path = nil
	
    if (ValidTable(ml_task_hub:CurrentTask().pos) or ValidTable(ml_task_hub:CurrentTask().gatePos)) then
		
		local myPos = ml_global_information.Player_Position
		local gotoPos = nil
		if (ml_task_hub:CurrentTask().gatePos) then
			gotoPos = ml_task_hub:CurrentTask().gatePos
		else
			gotoPos = ml_task_hub:CurrentTask().pos
			local p,dist = NavigationManager:GetClosestPointOnMesh(gotoPos)
			if (p and dist < 10) then
				gotoPos = p
			end
		end
		
		local path = ffxiv_task_test.GetPath(myPos,gotoPos)
		if (ValidTable(path)) then
			c_flytopos.pos = gotoPos
			c_flytopos.path = path
			return true
		end
    end
    return false
end
function e_flytopos:execute()
	local newTask = ffxiv_task_movewithflight.Create()
	newTask.path = c_flytopos.path
	newTask.remainMounted = true
	newTask.pos = c_flytopos.pos
	ml_task_hub:CurrentTask():AddSubTask(newTask)
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
    
    --ffxiv_task_movetopos2 members
    newinst.name = "MOVETOPOS2"
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
	newinst.dismountDistance = 15
	newinst.failTimer = 0
	
	newinst.distanceCheckTimer = 0
	newinst.lastPosition = nil
	newinst.lastDistance = 0
	
	newinst.abortFunction = nil
	ml_global_information.monitorStuck = true
    
    return newinst
end

function ffxiv_task_movetopos2:Init()
	--local ke_stuck = ml_element:create( "Stuck", c_stuck, e_stuck, 50 )
    --self:add( ke_stuck, self.overwatch_elements)
			
	--local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 25 )
    --self:add( ke_teleportToPos, self.process_elements)
	
	--local ke_useNavInteraction = ml_element:create( "UseNavInteraction", c_usenavinteraction, e_usenavinteraction, 22 )
    --self:add( ke_useNavInteraction, self.process_elements)
	
	local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 100 )
    self:add( ke_mount, self.process_elements)
	
	local ke_flyToPos = ml_element:create( "FlyToPos", c_flytopos, e_flytopos, 80 )
    self:add( ke_flyToPos, self.process_elements)
    
    --local ke_sprint = ml_element:create( "Sprint", c_sprint, e_sprint, 15 )
    --self:add( ke_sprint, self.process_elements)
	
	--local ke_falling = ml_element:create( "Falling", c_falling, e_falling, 10 )
    --self:add( ke_falling, self.process_elements)
    	
    local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 5 )
    self:add( ke_walkToPos, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetopos2:task_complete_eval()
	if (ml_global_information.Player_IsLoading) then
		d("[MOVETOPOS]: Completing due to locked, loading, mesh loading.")
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
			distance = Distance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
			distance2d = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
		else
			distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
			distance2d = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
		end 
		local pathdistance = GetPathDistance(myPos,gotoPos)
		
		if (distance < 40 and self.customSearch ~= "") then
			local el = EntityList(self.customSearch)
			if (ValidTable(el)) then
				local id,entity = next(el)
				if (ValidTable(entity)) then
					if (entity.alive) then
						if (self.customSearchCompletes) then
							if (InCombatRange(entity.id)) then
								ml_debug("[MOVETOPOS]: Ending movetopos, found the target.")
								return true
							end
						end
						local p,dist = NavigationManager:GetClosestPointOnMesh(entity.pos)
						if (p) then
							if (not deepcompare(self.pos,p,true)) then
								self.pos = p
								gotoPos = self.pos
								ml_debug("[MOVETOPOS]: Using target's exact coordinate : [x:"..tostring(self.pos.x)..",y:"..tostring(self.pos.y)..",z:"..tostring(self.pos.z).."]")
								
								if (self.use3d) then
									distance = Distance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
									distance2d = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
								else
									distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
									distance2d = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
								end 
								pathdistance = GetPathDistance(myPos,gotoPos)
							end
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
			if (not ml_global_information.Player_IsMoving and self.range < 1 and distance < 1) then
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
	d("[MOVETOPOS]: Task completing.")
end

function ffxiv_task_movetopos2:task_fail_eval()
	if (not c_walktopos:evaluate() and not ml_global_information.Player_IsMoving) then
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
	d("[MOVETOPOS]: Failing.")
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
    newinst.doFacing = false
    newinst.pauseTimer = 0
    newinst.gatherRange = 0.0
    newinst.remainMounted = false
    newinst.useFollowMovement = false
	newinst.obstacleTimer = 0
	
	newinst.distanceCheckTimer = 0
	newinst.lastPosition = nil
	newinst.lastDistance = 0
	newinst.path = {}
	newinst.pathThrottle = 0
	newinst.pathIndex = 1
	newinst.movementStarted = false
    
    return newinst
end

function ffxiv_task_movewithflight:Init()	
	local ke_takeOff = ml_element:create( "TakeOff", c_flighttakeoff, e_flighttakeoff, 80 )
    self:add( ke_takeOff, self.process_elements)
	
	local ke_moveToTakeOff = ml_element:create( "MoveToTakeOff", c_walktotakeoff, e_walktotakeoff, 75 )
    self:add( ke_moveToTakeOff, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_movewithflight:task_complete_eval()
    if (ValidTable(self.pos)) then
        local myPos = ml_global_information.Player_Position
		local gotoPos = self.pos
		
		local distance = Distance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)		
		if (distance <= 10) then
			return true
		else
			local path = self.path
			if (ValidTable(path)) then
				if (Player.flying.isflying) then
					if (not self.movementStarted) then
						Player:Move(FFXIV.MOVEMENT.FORWARD)
						self.movementStarted = true
					end
					
					local currentPoint = path[self.pathIndex]
					if (currentPoint) then
						local travelPoint = path[self.pathIndex+1]
						if (travelPoint) then
						
							local distNext = Distance3D(myPos.x,myPos.y,myPos.z,travelPoint.x,travelPoint.y,travelPoint.z)
							if (distNext <= 4) then
								self.pathIndex = self.pathIndex+1
								--d("Moving forward in the path to index ["..tostring(self.pathIndex).."].")
								return false
							end
							
							Player:SetFacing(travelPoint.x,travelPoint.y,travelPoint.z)
							local pitch = math.atan2((myPos.y - travelPoint.y), distNext)
							if (Player.flying.pitch ~= pitch) then
								Player:SetPitch(pitch)
							end
						else
							local distCurrent = Distance3D(myPos.x,myPos.y,myPos.z,currentPoint.x,currentPoint.y,currentPoint.z)
							if (distCurrent <= 4) then
								return true
							end
						end
					end
				end
			else
				return true
			end
		end
    end    
    return false
end

function ffxiv_task_movewithflight:task_complete_execute()
    Player:Stop()
	Dismount()
	ml_task_hub:CurrentTask():SetDelay(500)
	ml_global_information.landing = true
    self.completed = true
end

--[[
function ffxiv_task_test.GetFlightPoints(basePos)
	local thisPos = renderpos or Player.pos
	local heading = thisPos.h
	
	local playerForward = ConvertHeading(heading)%(2*math.pi)
	local playerRight = ConvertHeading((heading - (math.pi/2)))%(2*math.pi)
	local playerLeft = ConvertHeading((heading + (math.pi/2)))%(2*math.pi)
	local playerRear = ConvertHeading((heading - (math.pi)))%(2*math.pi)
	
	local points = {
		GetPosFromDistanceHeading(thisPos, 0.75, playerForward),
		GetPosFromDistanceHeading(thisPos, 0.75, playerRight),
		GetPosFromDistanceHeading(thisPos, 0.75, playerLeft),
		GetPosFromDistanceHeading(thisPos, 0.75, playerRear),
	}
	return points
end
--]]

function ffxiv_task_test.GetFlightPoints(basePos)
	local thisPos = renderpos or Player.pos
	local heading = thisPos.h
	
	local playerForward = ConvertHeading(heading)%(2*math.pi)
	local playerRight = ConvertHeading((heading - (math.pi/2)))%(2*math.pi)
	local playerLeft = ConvertHeading((heading + (math.pi/2)))%(2*math.pi)
	local playerRear = ConvertHeading((heading - (math.pi)))%(2*math.pi)
	
	--Wing,Cube,Matrix,Laser,LaserX
	
	local points = {}
	if (gTestRecordPattern == "Basic") then
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
				table.insert(points,v)
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
				table.insert(points,v)
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
		--[[
		for i = 1,20 do
			local f = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * i), playerForward)
			local r = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * i), playerRight),
			local l = GetPosFromDistanceHeading(thisPos, ((tonumber(gTestRecordTolerance) or 5) * i), playerLeft),
			
			table.insert(points,f)
			table.insert(points,r)
			table.insert(points,l)
		end
		
		local container = {}
		container.base = {
			f = GetPosFromDistanceHeading(thisPos, tonumber(gTestRecordTolerance) or 5, playerForward),
			r = GetPosFromDistanceHeading(thisPos, tonumber(gTestRecordTolerance) or 5, playerRight),
			l = GetPosFromDistanceHeading(thisPos, tonumber(gTestRecordTolerance) or 5, playerLeft,
			b = GetPosFromDistanceHeading(thisPos, tonumber(gTestRecordTolerance) or 5, playerRear),
		}
		for i,vertices in pairs(container) do
			for k,v in pairs(vertex) do
				table.insert(points,v)
			end
		end
		--]]
	end		
	
	return points
end

function ffxiv_task_test.RenderPoints(points)	
	for i,pos in pairs(points) do
		local color = 0
		local s = .3 -- size
		local h = .5 -- height
		
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

function ffxiv_task_test.ReadFlightMesh()
	local file = Player.localmapid .. ".flight"
	local path = GetStartupPath() .. [[\Navigation\]]
	local fullPath = path .. file
	
	local info = {}
	if (FileExists(fullPath)) then
		info = persistence.load(fullPath)
		if (ValidTable(info) and ValidTable(info.mesh)) then
			ffxiv_task_test.flightMesh = info.mesh
			ffxiv_task_test.RenderPoints(ffxiv_task_test.flightMesh)
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
	info.mesh = ffxiv_task_test.flightMesh
	persistence.store(fullPath,info)
end

function ffxiv_task_test.GetPath(from,to)
	if (ValidTable(from) and ValidTable(to)) then	
		local allowed = false
		local point1 = from
		local point2 = ffxiv_task_test.GetNearestFlightJunction(to)
		
		if (Player.flying.isflying) then
			allowed = true
		else
			local nearestJunction = ffxiv_task_test.GetNearestFlightJunction(from)
			local farJunction = point2
			local myPos = ml_global_information.Player_Position
			
			local myDist = Distance3D(myPos.x,myPos.y,myPos.z,to.x,to.y,to.z)
			local nearDist = Distance3D(nearestJunction.x,nearestJunction.y,nearestJunction.z,to.x,to.y,to.z)
			--local farDist = Distance3D(farJunction.x,farJunction.y,farJunction.z,to.x,to.y,to.z)
			
			if (myDist > 100) then
				point1 = nearestJunction
				allowed = true
			end
		end
		
		if (allowed) then
			local path = path( point1, point2, ffxiv_task_test.flightMesh, true)
			if (path ~= nil and type(path) == "table") then
				d("Returning path.")
				return path,nearestJunction,farJunction
			end
		end
	end
	
	d("No path.")
	return nil,nil,nil
end

--[[
function ffxiv_task_test.GetPath(dest)
	local ppos = Player.pos
	local pos = {}
	pos.x = tonumber(gTestMapX)
	pos.y = tonumber(gTestMapY)
	pos.z = tonumber(gTestMapZ)
	
	local pos1 = ffxiv_task_test.GetNearestFlightPoint(ppos)
	local pos2 = ffxiv_task_test.GetNearestFlightPoint(pos)
		
	local path = path( pos1, pos2, ffxiv_task_test.flightMesh, true, is_valid_node )
	if not path then
		--d( "No valid path found" )
		return nil
	else
		for i, node in ipairs ( path ) do
			--d( "Step " .. i .. " >> " .. node.id )
		end
		return path
	end
end
--]]

function ffxiv_task_test.FaceNextPath()
	local myPos = ml_global_information.Player_Position
	local pos = {}
	pos.x = tonumber(gTestMapX)
	pos.y = tonumber(gTestMapY)
	pos.z = tonumber(gTestMapZ)

	local path = ffxiv_task_test.GetPath(myPos,pos)
	if (ValidTable(path)) then
		local nearestPoint = path[1]
		local nextPoint = path[2]
		
		local dist = Distance3D(myPos.x,myPos.y,myPos.z,nextPoint.x,nextPoint.y,nextPoint.z)
		Player:SetFacing(nextPoint.x,nextPoint.y,nextPoint.z)
		local pitch = math.atan2((myPos.y - nextPoint.y), dist)
		d("pitch value:"..tostring(pitch))
		Player:SetPitch(pitch)
		
		--pitch = asin(V.y / length(V));
	--yaw = asin( V.x / (cos(pitch)*length(V)) ); //Beware cos(pitch)==0, catch this exception!
	--roll = 0;
		
		--[[
			-.785 (up)
			0 (level)
			1.38 (down)
		
		]]
	end
end

Player:SetFacing(Player.pos.x,Player.pos.y+5,Player.pos.z+5)

function ffxiv_task_test.TowardPath()
	local path = ffxiv_task_test.GetPath()
	if (ValidTable(path)) then
		local nearestPoint = path[1]
		local nextPoint = path[2]
		
		Player:Move(FFXIV.MOVEMENT.FORWARD)
	end
end

function ffxiv_task_test.GetNearestFlightJunction(pos)
	local mesh = ffxiv_task_test.flightMesh
	
	if (ValidTable(mesh)) then
		if (ValidTable(pos)) then
			local closest = nil
			local closestDistance = 9999
			for k,v in pairs(mesh) do
				local vpos = {x = v.x, y = v.y, z = v.z }
				local p,dist = NavigationManager:GetClosestPointOnMesh(vpos)
				if (p and dist < 15) then
					local dist = Distance3D(pos.x,pos.y,pos.z,v.x,v.y,v.z)
					if (not closest or (closest and dist < closestDistance)) then
						closest = v
						closestDistance = dist
					end
				end
			end
			
			return closest
		end
	end
	return nil
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
	if (Settings.FFXIVMINION.gTestFlyHeight == nil) then
		Settings.FFXIVMINION.gTestFlyHeight = 200
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
	if (Settings.FFXIVMINION.gTestUseFlight == nil) then
		Settings.FFXIVMINION.gTestUseFlight = "0"
	end

	local winName = "NavTest"
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
    GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
	
	GUI_NewCheckbox(winName,"Record Flight Points","gTestRecordFlight","FlightMesh")
	GUI_NewComboBox(winName,"Record Pattern","gTestRecordPattern",group,"Basic,Cube,Matrix,Laser,LaserX")
	GUI_NewField(winName,"Tolerance","gTestRecordTolerance","FlightMesh")
	GUI_NewField(winName,	"Fly Height",	"gTestFlyHeight","FlightMesh")
	GUI_NewButton(winName, 	"Save Mesh", 	"ffxiv_task_test.SaveFlightMesh", "FlightMesh")
	GUI_NewButton(winName, 	"Read Mesh", 	"ffxiv_task_test.ReadFlightMesh", "FlightMesh")
	GUI_NewButton(winName, 	"Get Path", 	"ffxiv_task_test.GetPath", "FlightMesh")
	
	GUI_NewButton(winName, "Face Next Path", "ffxiv_task_test.FaceNextPath", "FlightMesh")
	GUI_NewButton(winName, "Drive Toward Path", "ffxiv_task_test.TowardPath", "FlightMesh")
	
    GUI_NewField(winName, "MapID:", "gTestMapID","NavTest")
	GUI_NewField(winName, "X:", "gTestMapX","NavTest")
	GUI_NewField(winName, "Y:", "gTestMapY","NavTest")
	GUI_NewField(winName, "Z:", "gTestMapZ","NavTest")
	GUI_NewCheckbox(winName,"Use Flight","gTestUseFlight","NavTest")
	GUI_NewButton(winName, "Get Current Position", "ffxiv_navtestGetPosition", "NavTest")
	GUI_NewButton(winName, "Press Mouse", "ffxiv_task_test.PressMouse", "NavTest")
	GUI_NewButton(winName, "Face Position", "ffxiv_task_test.FacePosition", "NavTest")
	GUI_NewButton(winName, "Draw Rectangle", "ffxiv_task_test.DrawRectangle", "NavTest")
	GUI_NewButton(winName, "Inside Rectangle", "ffxiv_task_test.IsInsideRect", "NavTest")
	
	gTestRecordTolerance = Settings.FFXIVMINION.gTestRecordTolerance
	gTestRecordPattern = Settings.FFXIVMINION.gTestRecordPattern
	gTestFlyHeight = Settings.FFXIVMINION.gTestFlyHeight
	gTestMapID = Settings.FFXIVMINION.gTestMapID
	gTestMapX = Settings.FFXIVMINION.gTestMapX
	gTestMapY = Settings.FFXIVMINION.gTestMapY
	gTestMapZ = Settings.FFXIVMINION.gTestMapZ
	gTestUseFlight = Settings.FFXIVMINION.gTestUseFlight
	
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
			k == "gTestUseFlight" or
			k == "gTestRecordTolerance" or
			k == "gTestRecordPattern") 
		then
			Settings.FFXIVMINION[tostring(k)] = v
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
	if (TimeSince(ffxiv_task_test.lastTick) >= 1000) then
		ffxiv_task_test.lastTick = Now()
		
		if (gTestRecordFlight == "1") then
			local mesh = ffxiv_task_test.flightMesh
			local newPoints = ffxiv_task_test.GetFlightPoints()
			local renderedPoints = {}
			
			if (ValidTable(newPoints)) then
				--d("Have new points to check.")
				for k,v in pairs(newPoints) do
					local allowed = true
					for i,j in pairs(mesh) do
						local dist = Distance3D(j.x,j.y,j.z,v.x,v.y,v.z)
						if (dist < 7) then
							allowed = false
							break
						end
					end
					
					if (allowed) then
						--d("Passed first check.")
						local p,dist = NavigationManager:GetClosestPointOnMesh(v)
						if (not p or (p and (dist > 5 or dist == 0))) then
							v.id = TableSize(mesh)
							table.insert(mesh,v)
							table.insert(renderedPoints,v)
							--d("Adding a new point.")
						end
					end
				end
				
				if (ValidTable(renderedPoints)) then
					--d("Rendering new points.")
					ffxiv_task_test.RenderPoints(renderedPoints)
				end
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
local dist_3d = Distance3D

function dist ( x1, y1, z1, x2, y2, z2 )
	return dist_3d(x1,y1,z1,x2,y2,z2)
end

function dist_between ( nodeA, nodeB )
	return dist( nodeA.x, nodeA.y, nodeA.z, nodeB.x, nodeB.y, nodeB.z )
end

function heuristic_cost_estimate ( nodeA, nodeB )
	return dist( nodeA.x, nodeA.y, nodeA.z, nodeB.x, nodeB.y, nodeB.z )
end

function is_valid_node ( node, neighbor )
	local MIN_DIST = 7
	local MAX_DIST = 30
	local nodedist = dist_between(node,neighbor)
	if (nodedist >= MIN_DIST and nodedist < MAX_DIST) then
		local pitch = atan2((node.y - neighbor.y),nodedist)
		if (pitch >= -.785 and pitch <= 1.38) then
			return true
		end
	end
	return false
end

--[[function is_valid_node ( node, neighbor )
	local neighbors = node.neighbors
	if (ValidTable(neighbors)) then
		for id,neighbor in pairs(neighbors) do
			if (id == neighbor.id) then
				return true
			end
		end
	end
	
	return false
end]]

function lowest_f_score ( set, f_score )

	local lowest, bestNode = INF, nil
	for _, node in ipairs ( set ) do
		local score = f_score [ node ]
		if score < lowest then
			lowest, bestNode = score, node
		end
	end
	return bestNode
end

function neighbor_nodes ( theNode, nodes )

	local neighbors = {}
	for _, node in ipairs ( nodes ) do
		if theNode ~= node and is_valid_node ( theNode, node ) then
			insert( neighbors, node )
		end
	end
	return neighbors
end

function not_in ( set, theNode )
	for _, node in ipairs ( set ) do
		if node == theNode then return false end
	end
	return true
end

function remove_node ( set, theNode )
	for i, node in ipairs ( set ) do
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
		
		local neighbors = neighbor_nodes ( current, nodes )
		for _, neighbor in ipairs ( neighbors ) do 
			if not_in ( closedset, neighbor ) then
			
				local tentative_g_score = g_score [ current ] + dist_between ( current, neighbor )
				 
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
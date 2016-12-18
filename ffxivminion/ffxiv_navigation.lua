-- Extends minionlib's ml_navigation.lua by adding the game specific navigation handler
ffnav = {}
ffnav.lastTick = 0
ffnav.lastPitchTick = 0
ffnav.lastPathTick = 0
ffnav.lastPathDistance = 0
ffnav.newPathThrottle = 1000
ffnav.currentPath = {}
ffnav.renderPath = {}
ffnav.currentPathIndex = 0
ffnav.currentPathGoal = {}
ffnav.currentPathEntity = 0
ffnav.currentPathType = ""
ffnav.showNavPath = true
ffnav.pathRenderObject = nil
ffnav.pathRenderObject2 = nil
ffnav.pathRenderObject3 = nil
ffnav.pathRenderObject4 = nil
ffnav.pathRenderObject5 = nil
ffnav.nodedist = {
	["3dwalk"] = 2,
	["2dwalk"] = 0.3,
	["3dmount"] = 5,
	["2dmount"] = 0.4,
	["3dfly"] = 5,
	["2dfly"] = 1,
	["3dflysc"] = 5,
	["2dflysc"] = 3,
}
ffnav.yield = {}
ffnav.process = {}

function ffnav.IsProcessing()
	if (ffnav.IsYielding()) then
		--d("still yielding")
		return true
	end
	
	if (table.valid(ffnav.process)) then
		local process = ffnav.process
		
		local successTimer = false
		local successEval = false
		
		if (process.mintimer and process.mintimer ~= 0) then
			if (Now() < process.mintimer) then
				return true
			end
		end
		
		if (process.evaluator ~= nil and type(process.evaluator) == "function") then
			local ret = process.evaluator()
			if (ret == true) then
				successEval = true
			end
		end		
		if (process.maxtimer and process.maxtimer ~= 0 and Now() >= process.maxtimer) then
			successTimer = true
		end
		if (successTimer or successEval) then
			ffnav.process = {}
			
			if (successEval and process.followsuccess ~= nil and type(process.followsuccess) == "function") then
				process.followsuccess()
			end
			if (successTimer and process.followfail ~= nil and type(process.followfail) == "function") then
				process.followfail()
			end
			if (process.followall ~= nil and type(process.followall) == "function") then
				process.followall()
			end
		end
		return true
	end
	return false
end

function ffnav.IsYielding()
	if (table.valid(ffnav.yield)) then
		local yield = ffnav.yield
		
		local successTimer = false
		local successEval = false
		
		if (yield.dowhile ~= nil and type(yield.dowhile) == "function") then
			yield.dowhile()
		end
		
		if (yield.mintimer ~= 0) then
			if (Now() < yield.mintimer) then
				return true
			end
		end
		
		if (yield.evaluator ~= nil and type(yield.evaluator) == "function") then
			local ret = yield.evaluator()
			if (ret == true) then
				successEval = true
			end
		end
		if (yield.maxtimer ~= 0 and Now() >= yield.maxtimer) then
			successTimer = true
		end
		
		if (successTimer or successEval) then		
			ffnav.yield = {}
			
			if (successEval and yield.followsuccess ~= nil and type(yield.followsuccess) == "function") then
				yield.followsuccess()
				return true
			end
			
			if (successTimer and yield.followfail ~= nil and type(yield.followfail) == "function") then
				yield.followfail()
				return true
			end
			
			if (yield.followall ~= nil and type(yield.followall) == "function") then
				yield.followall()
				return true
			end
			
			return false
		end
		
		return true
	end
	return false
end

function ffnav.Await(param1, param2, param3, param4, param5)
	if (param1 and type(param2) == "number" and param2 and type(param2) == "number") then
		ffnav.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			followall = param4,
			both = IsNull(param5,false),
		}
	else
		ffnav.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			followall = param3,
			both = IsNull(param4,false),
		}
	end
end

function ffnav.AwaitDo(param1, param2, param3, param4, param5)
	if (param1 and type(param2) == "number" and param2 and type(param2) == "number") then
		ffnav.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			dowhile = param4,
			followall = param5,
		}
	else
		ffnav.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			dowhile = param3,
			followall = param4,
		}
	end
end

function ffnav.SetNodeDistances(vals)
	if (table.valid(vals)) then
		for k,v in pairs(vals) do
			ffnav.nodedist[k] = v
		end
	else
		ffnav.nodedist = {
			["3dwalk"] = 2,
			["2dwalk"] = 0.4,
			["3dmount"] = 3,
			["2dmount"] = 0.5,
			["3dfly"] = 5,
			["2dfly"] = 0.75,
		}
	end
end

function ffnav.ResetPath()
	d("Path was reset.")
	ffnav.newPathThrottle = 1000
	ffnav.currentPath = {}
	ffnav.currentPathIndex = 0
	ffnav.currentPathGoal = {}
	ffnav.currentPathEntity = 0
	ffnav.currentPathType = ""
end

function ffnav.IsGoalClose(goal)
	
	local goaldist,goaldist2d = ffnav.GetNodeDistance(Player.pos,goal)
	if (not Player.ismounted) then
		if (goaldist <= ffnav.nodedist["3dwalk"] and goaldist2d <= ffnav.nodedist["2dwalk"]) then
			return true
		end
	else
		if (Player.flying.isflying) then
			--d("currentPathIndex:"..tostring(ffnav.currentPathIndex))
			--d("checking flying dist")
			--d("index:"..tostring(ffnav.currentPathIndex)..",goaldist:"..tostring(goaldist)..", goaldist2d:"..tostring(goaldist2d)..",from [ "..tostring(math.round(Player.pos.x,2)).." / "..tostring(math.round(Player.pos.y,2)).." / "..tostring(math.round(Player.pos.z,2)).."] - to - [".. tostring(math.round(goal.x,2)).. " / "..tostring(math.round(goal.y,2)).." / "..tostring(math.round(goal.z,2)).."]")
			if (goaldist <= ffnav.nodedist["3dfly"] and goaldist2d <= ffnav.nodedist["2dfly"]) then
				return true
			end
		else
			if (goaldist <= ffnav.nodedist["3dmount"] and goaldist2d <= ffnav.nodedist["2dmount"]) then
				return true
			end
		end
	end
	return false
end

function ffnav.IsEntityClose(entity)
	if (table.valid(entity)) then
		local goaldist2d = entity.distance2d
		if (not Player.ismounted) then
			if (goaldist2d <= ffnav.nodedist["2dwalk"]) then
				return true
			end
		else
			if (Player.flying.isflying) then
				if (goaldist2d <= ffnav.nodedist["2dfly"]) then
					return true
				end
			else
				if (goaldist2d <= ffnav.nodedist["2dmount"]) then
					return true
				end
			end
		end
	end
	return false
end

-- Look for a new index to fast forward to that isn't the next one to make flying behave a bit less awkwardly.
function ffnav.CanFastForward()
	if (table.valid(ffnav.currentPath)) then
		local currentNode = ffnav.currentPath[ffnav.currentPathIndex]
		local nextNode = ffnav.currentPath[ffnav.currentPathIndex+1]
		
		if (currentNode and nextNode) then
			local currentdist,currentdist2d = ffnav.GetNodeDistance(Player.pos,{currentNode.x, currentNode.y, currentNode.z})
			local interdist,interdist2d = ffnav.GetNodeDistance({currentNode.x, currentNode.y, currentNode.z},{nextNode.x, nextNode.y, nextNode.z})
			local nextdist,nextdist2d = ffnav.GetNodeDistance(Player.pos,{nextNode.x, nextNode.y, nextNode.z})
			
			if (ffnav.IsPathClear({currentNode.x, currentNode.y, currentNode.z},{nextNode.x, nextNode.y, nextNode.z})) then
				if (currentDist < 10 and currentDist2d < 8 and interdist < 10 and interdist2d < 8) then
					d("okay to fastforward to next node")
					return true
				end
			end
		end
	end
	return false
end

function ffnav.GetPath(px, py, pz, x, y, z, randomizedpath)
	if ( NavigationManager:GetNavMeshState() ~= GLOBAL.MESHSTATE.MESHREADY ) then
		d("[Navigation] - MESH_NOT_READY - State : "..tostring(NavigationManager:GetNavMeshState() ))
		return -8		
	end
	
	-- Generate a new Path only if...
	if (not table.valid(ffnav.currentPath) or not ffnav.IsPosSame(ffnav.currentPathGoal,{x = x, y = y, z = z})) then
		ffnav.lastPathTick = Now() -- tiny throttle, else it can go a bit nutz when the target moves too fast
		
		-- We create a new path
		local tmp = NavigationManager:GetPath(px, py, pz, x, y, z)
		if ( not table.valid(tmp) ) then
			if ( type(tmp) == "number") then
				if ( tmp == -6 ) then 
					d("[Navigation] - NO_RANDOM_PATH_FOUND - From [ "..tostring(math.round(px,2)).." / "..tostring(math.round(py,2)).." / "..tostring(math.round(pz,2)).."] - To - [".. tostring(math.round(x,2)).. " / "..tostring(math.round(y,2)).." / "..tostring(math.round(z,2)).."]")
				elseif( tmp == -5 ) then 
					d("[Navigation] - NO_STRAIGHT_PATH_FOUND - From [ "..tostring(math.round(px,2)).." / "..tostring(math.round(py,2)).." / "..tostring(math.round(pz,2)).."] - To - [".. tostring(math.round(x,2)).. " / "..tostring(math.round(y,2)).." / "..tostring(math.round(z,2)).."]")
				elseif( tmp == -4 ) then 
					d("[Navigation] - NO_POLY_PATH_FOUND - From [ "..tostring(math.round(px,2)).." / "..tostring(math.round(py,2)).." / "..tostring(math.round(pz,2)).."] - To - [".. tostring(math.round(x,2)).. " / "..tostring(math.round(y,2)).." / "..tostring(math.round(z,2)).."]")
				elseif( tmp == -3 ) then 
					d("[Navigation] - NO_POLY_FOUND - From [ "..tostring(math.round(px,2)).." / "..tostring(math.round(py,2)).." / "..tostring(math.round(pz,2)).."] - To - [".. tostring(math.round(x,2)).. " / "..tostring(math.round(y,2)).." / "..tostring(math.round(z,2)).."]")
				elseif( tmp == -2 ) then 
					d("[Navigation] - END_NOT_ON_MESH - From [ "..tostring(math.round(px,2)).." / "..tostring(math.round(py,2)).." / "..tostring(math.round(pz,2)).."] - To - [".. tostring(math.round(x,2)).. " / "..tostring(math.round(y,2)).." / "..tostring(math.round(z,2)).."]")
				elseif( tmp == -1 ) then 
					d("[Navigation] - START_NOT_ON_MESH - From [ "..tostring(math.round(px,2)).." / "..tostring(math.round(py,2)).." / "..tostring(math.round(pz,2)).."] - To - [".. tostring(math.round(x,2)).. " / "..tostring(math.round(y,2)).." / "..tostring(math.round(z,2)).."]")			
				end
			end
			return tmp
			-- Cancel the old path ?
		else
			-- We received a valid path table 
			ffnav.currentPath = tmp
			ffnav.currentPathIndex = 0
			ffnav.currentPathGoal = { x = x, y = y, z = z }
			ffnav.AddPathRender()
			--d("returned a new path.")
			return table.size(tmp)
		end
	else
		--d("returned an existing path.")
		return table.size(ffnav.currentPath)
	end
end

-- Tries to use RayCast to determine the exact floor height from Player and Node, and uses that to calculate the correct distance.
function ffnav.GetNodeDistance(ppos,nodepos)
	-- Raycast from "top to bottom" @PlayerPos and @NodePos
	local P_hit, P_hitx, P_hity, P_hitz = RayCast(ppos.x,ppos.y+3,ppos.z,ppos.x,ppos.y-3,ppos.z) 
	--d("nodepos:"..tostring(nodepos))
	local N_hit, N_hitx, N_hity, N_hitz = RayCast(nodepos.x,nodepos.y+3,nodepos.z,nodepos.x,nodepos.y-3,nodepos.z) 
	local dist = math.distance3d(ppos,nodepos)
	local dist2d = math.distance2d(ppos,nodepos)
	if (P_hit and N_hit and not IsFlying()) then 
		local raydist = math.distance3d(P_hitx, P_hity, P_hitz , N_hitx, N_hity, N_hitz)
		local raydist2d = math.distance2d(P_hitx, P_hitz , N_hitx, N_hitz)
		if (raydist < dist) then 
			dist = raydist
		end
		if (raydist2d < dist2d) then
			dist2d = raydist2d
		end
	end
	return dist,dist2d
end

function ffnav.IsPathClear(pos1,pos2)
	local hit, hitx, hity, hitz = RayCast(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z) 
	return (hit == nil)
end

function ffnav.TurnAngle(pos)
	local ppos = Player.pos
	return math.angle({x = math.sin(ppos.h), y = 0,  z =math.cos(ppos.h)}, {x = pos.x-ppos.x, y = 0, z = pos.z-ppos.z})
end

function ffnav.IsPosSame(pos1,pos2)
	if (type(pos1) == "table" and type(pos2) == "table") then
		if (pos1.x and pos1.y and pos1.z and pos2.x and pos2.y and pos2.z) then
			if (math.round(pos1.x,1) == math.round(pos2.x,1) and math.round(pos1.y,1) == math.round(pos2.y,1) and math.round(pos1.z,1) == math.round(pos2.z,1)) then
				return true
			end
		end
	end
	return false
end

function ffnav.IsWalking()
	return Player:IsMoving()
end

function ffnav.IsRiding()
	return Player:IsMoving()
end

function ffnav.IsFlying()
	return (Player:GetSpeed(FFXIV.MOVEMENT.FORWARD) > 0)
end

-- Creates / Updates the current Path, this usually gets spam-called by the bot
function ffnav.MoveTo(x, y, z, randomnodes, smoothturns)		
	local ppos = Player.pos
	local pathSize = ffnav.GetPath(ppos.x,ppos.y,ppos.z,x,y,z)
	return pathSize
end

-- Creates / Updates the current Path, this usually gets spam-called by the bot
function ffnav.MoveToEntity(entityid)		
	local ppos = Player.pos
	local pathSize = ffnav.GetPath(ppos.x,ppos.y,ppos.z,x,y,z)
	return pathSize
end

function ffnav.WalkTo(pos)
	local myPos = Player.pos
	local previousGoal = ffnav.currentPath[0]
	if (ffnav.currentPathIndex > 0) then
		previousGoal = ffnav.currentPath[ffnav.currentPathIndex-1]
	end
	
	local dist2d,dist3d = math.distance2d(myPos,pos), math.distance3d(myPos,pos)
	local pdist2d,pdist3d = math.distance2d(previousGoal,pos), math.distance3d(previousGoal,pos)
	local mdist2d,mdist3d = math.distance2d(previousGoal,myPos), math.distance3d(previousGoal,myPos)
	
	if (ffnav.IsGoalClose(pos) or mdist2d > pdist2d) then
		
		ffnav.currentPathIndex = ffnav.currentPathIndex + 1
		
		--d("walk from ["..tostring(previousGoal.x)..","..tostring(previousGoal.y)..","..tostring(previousGoal.z))
		--d("mypos ["..tostring(myPos.x)..","..tostring(myPos.y)..","..tostring(myPos.z))
		--d("walk to ["..tostring(pos.x)..","..tostring(pos.y)..","..tostring(pos.z))
		
		--d("mdist2d:"..tostring(mdist2d)..",pdist2d:"..tostring(pdist2d))
		--d("goalclose?:"..tostring(ffnav.IsGoalClose(pos))..", further than original distance?:"..tostring(mdist2d > pdist2d)..", newindex:"..tostring(ffnav.currentPathIndex))
		
		local newPos = ffnav.currentPath[ffnav.currentPathIndex]
		if (table.valid(newPos)) then
			local turnDegrees = ffnav.TurnAngle(newPos)
			if (turnDegrees > 75 and dist3d > 8) then
				Player:SetFacing(newPos.x,newPos.y,newPos.z,true)
			else
				Player:SetFacing(newPos.x,newPos.y,newPos.z)
			end
		end		
		return false
	end
	
	local turnDegrees = ffnav.TurnAngle(pos)
	if (turnDegrees > 75 and dist3d > 8) then
		Player:SetFacing(pos.x,pos.y,pos.z,true)
	else
		Player:SetFacing(pos.x,pos.y,pos.z)
	end
	if (not Player:IsMoving()) then
		Player:Move(FFXIV.MOVEMENT.FORWARD)	
		ml_global_information.Await(2000, function () return Player:IsMoving() end)
	end
end

-- D = "walk from [-48.799991607666,18.250001907349,49.35001373291"
--  D = "mypos [-48.544151306152,18,49.401268005371"
--  D = "walk to [-48.799991607666,18.25,56.350009918213"

--d(math.distance2d({x = -48.799991607666, z = 49.35001373291},{x = -48.799991607666,z = 56.350009918213}))

function ffnav.FlyTo(pos)
	
	local myPos = Player.pos
	local previousGoal = ffnav.currentPath[0]
	if (ffnav.currentPathIndex > 0) then
		previousGoal = ffnav.currentPath[ffnav.currentPathIndex-1]
	end
	local dist2d,dist3d = math.distance2d(myPos,pos), math.distance3d(myPos,pos)
	local pdist2d,pdist3d = math.distance2d(previousGoal,pos), math.distance3d(previousGoal,pos)
	
	if (false) then
	--if (ffnav.CanFastForward()) then
		ffnav.currentPathIndex = ffnav.currentPathIndex + 2
		return false
	elseif (ffnav.IsGoalClose(pos)) then
		ffnav.currentPathIndex = ffnav.currentPathIndex + 1
		ffnav.lastPathDistance = 0
		return false
	end
	
	local distFromPath = 0
	if (ffnav.currentPathIndex > 0) then 
		distFromPath = math.distancepointline(ffnav.currentPath[ffnav.currentPathIndex-1],ffnav.currentPath[ffnav.currentPathIndex],myPos)
	end
	
	local turnDegrees = ffnav.TurnAngle(pos)
	if (turnDegrees > 60) then
		Player:SetFacing(pos.x,pos.y,pos.z,true)
	else
		Player:SetFacing(pos.x,pos.y,pos.z)
	end
	
	local currentPitch = math.round(Player.flying.pitch,3)
	--local pitch = math.round(math.atan2((myPos.y - pos.y), dist2d),3)
	--local pitch = math.round(math.atan((myPos.y - pos.y)/dist2d),3)
	local minVector = math.normalize(math.vectorize(myPos,pos))
	local pitch = math.asin(-1 * minVector.y)
	--local previousPitch = math.round(math.atan2((previousGoal.y - pos.y), pdist2d),3)
	
	--sqrt(x^2 + y^2)/
	--d("necessary pitch:"..tostring(pitch)..", "..tostring(myPos.y).." - "..tostring(pos.y)..", dist2d:"..tostring(dist2d))
	--d("previous pitch:"..tostring(pitch)..", "..tostring(previousGoal.y).." - "..tostring(pos.y)..", dist2d:"..tostring(pdist2d))
	--d("current pitch:"..tostring(currentPitch)..", distFromPath:"..tostring(distFromPath))
	
	--[[
	if (distFromPath > 1 and ffnav.lastPathDistance >= distFromPath) then
		if (pitch < 0) then
			if (pitch < currentPitch) then
				d("adjust pitch up, heading up already")
				pitch = pitch + 0.1
			elseif (pitch > currentPitch) then
				d("adjust pitch down, heading up already")
				pitch = pitch - 0.2
			end
		elseif (pitch > 0) then
			if (pitch < currentPitch) then
				d("adjust pitch down, heading down already")
				pitch = pitch - 0.1
			elseif (pitch > currentPitch) then
				d("adjust pitch up, heading down already")
				pitch = pitch + 0.1
			end
		end
	end
	--]]
	
	--[[
	if (pitch < -0.785) then
		d("adjusting pitch to highest value")
		pitch = -0.785
	elseif (pitch > 1.377) then
		d("adjusting pitch to lowest value")
		pitch = 1.377
	end
	--]]
	
	Player:SetPitch(pitch)
	--ffnav.Await(200, function () return math.round(Player.flying.pitch,3) == pitch end)
	
	if (not Player:IsMoving()) then
		Player:Move(FFXIV.MOVEMENT.FORWARD)	
		ml_global_information.Await(2000, function () return Player:IsMoving() end)
	end
	
	ffnav.lastPathDistance = distFromPath
end

function ffnav.Ascend()
	ffnav.process = {
		mintime = 150, maxtime = 10000, 
		evaluator = function ()
			local ppos = Player.pos
			if (IsFlying()) then
				if (Player:IsMoving(FFXIV.MOVEMENT.UP)) then
					local hceiling, hceilingx, hceilingy, hceilingz = RayCast(ppos.x,ppos.y,ppos.z,ppos.x,ppos.y+4,ppos.z)
					local hfloor, hfloorx, hfloory, hfloorz = RayCast(ppos.x,ppos.y+3,ppos.z,ppos.x,ppos.y-8,ppos.z)
					if (not hfloor or math.distance3d(hfloorx, hfloory, hfloorz, ppos.x, ppos.y, ppos.z) > 8 or 
						(hceiling and math.distance3d(hceilingx, hceilingy, hceilingz, ppos.x, ppos.y, ppos.z) > 8)) 
					then
						Player:StopMovement()
						ffnav.Await(1000, function () return (not Player:IsMoving(FFXIV.MOVEMENT.UP)) end)
						return true
					end
					return false
				else
					Player:Move(FFXIV.MOVEMENT.UP) 
					ffnav.Await(150, 5000, function () return Player:IsMoving(FFXIV.MOVEMENT.UP) end)
					return false
				end
			else
				Player:Jump()
				Player:Move(FFXIV.MOVEMENT.UP) 
				ffnav.Await(math.random(50,150))
				return false
			end
		end, 
		followsuccess = function ()
			ffnav.ResetPath()
			--ffnav.MoveTo(ffnav.currentPathGoal.x, ffnav.currentPathGoal.y, ffnav.currentPathGoal.z) 
		end
	}
end

-- Resets all OMC related variables
function ml_navigation:ResetOMCHandler()
	self.omc_id = nil
	self.omc_traveltimer = nil
	self.ensureposition = nil
	self.ensureheading = nil
	self.ensurepositionstarttime = nil
	self.omc_starttimer = 0
	self.omc_startheight = nil	
end
	
-- for replacing the original c++ navi with our lua version
function Player:MoveTo(x, y, z, randomnodes, smoothturns)
	if (not ffnav.IsGoalClose({x = x, y = y, z = z})) then
		--d("goal was not close enough")
		--if (not table.valid(ffnav.currentPathGoal) or not ffnav.IsPosSame(ffnav.currentPathGoal,{x = x, y = y, z = z})) then
			return ffnav.MoveTo(x, y, z, randomnodes, smoothturns)
		--end
	else
		--d("goal was too close")
	end
	return 0
end

function Player:MoveToEntity(entityid)
	if (ffnav.currentPathEntity ~= entityid) then
		local entity = EntityList:Get(entityid)
		if (table.valid(entity)) then
			if (not ffnav.IsEntityClose(entity)) then
				return ffnav.MoveToEntity(entity.id)
			end
		end
	end
	return false
end

function Player:Stop()
	d("Player Stop()")
	ffnav.ResetPath()
	--ffnav.ResetOMCHandler()
	ffnav.yield = {}
	ffnav.process = {}
	Player:StopMovement()
end

-- Handles the Navigation along the current Path. Is not supposed to be called manually.
function ffnav.Navigate(event, ticks )	
	
	if ((ticks - ffnav.lastTick) >= 25) then 
		ffnav.lastTick = ticks
				
		if ( FFXIV.GAMESTATE.INGAME ) then
			if (not ffnav.IsProcessing()) then
				local ppos = Player.pos
				
				if ( table.valid(ffnav.currentPath) and table.size(ffnav.currentPath) > ffnav.currentPathIndex ) then	
					local nextnode = ffnav.currentPath[ffnav.currentPathIndex]
					if (table.valid(nextnode)) then
						
						local nextpos = { x = nextnode.x, y = nextnode.y, z = nextnode.z }
					
						-- OffMeshConnection Navigation
						if (nextnode.type == "OMC_END") then
						
							--[[
							if ( nextnode.id == nil ) then ml_error("[Navigation] - No OffMeshConnection ID received!") return end
							local omc = ml_mesh_mgr.offmeshconnections[nextnode.id]
							if( not omc ) then ml_error("[Navigation] - No OffMeshConnection Data found for ID: "..tostring(nextnode.id)) return end
								
							-- A general check, for the case that the player never reaches either OMC END
							if ( not ml_navigation.omc_id or ml_navigation.omc_id ~= nextnode.id ) then	-- Update the currently tracked omc_id and variables
								ml_navigation.omc_id = nextnode.id
								ml_navigation.omc_traveltimer = ticks
								ml_navigation.omc_traveldist = math.distance3d(ppos,nextnode)
							else	-- We are still pursuing the same omc, check if we are getting closer over time
								local timepassed = ticks - ml_navigation.omc_traveltimer
								if ( timepassed < 3000) then 
									local dist = math.distance3d(ppos,nextnode)
									if ( timepassed > 2000 and ml_navigation.omc_traveldist > dist) then
										ml_navigation.omc_traveldist = dist
										ml_navigation.omc_traveltimer = ticks
									end
								else
									d("[Navigation] - Not getting closer to OMC END node. We are most likely stuck.")
									ml_navigation.StopMovement()
									return
								end								
							end
								
							-- Max Timer Check in case something unexpected happened
							if ( ml_navigation.omc_starttimer ~= 0 and ticks - ml_navigation.omc_starttimer > 10000 ) then
								d("[Navigation] - Could not read OMC END in ~10 seconds, something went wrong..")
								ml_navigation.StopMovement()
								return
							end
									
							-- OMC Handling by Type
							if ( omc.type == 1 ) then
								-- OMC JUMP										
								local movementstate = Player:GetMovementState()	
								
								if ( movementstate == GW2.MOVEMENTSTATE.Jumping) then
									if ( not ml_navigation.omc_startheight ) then ml_navigation.omc_startheight = ppos.z end
									-- Additionally check if we are "above" the target point already, in that case, stop moving forward
									local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(ppos,nextnode)
									if ( nodedist < ml_navigation.OMCREACHEDDISTANCE) then
										d("[Navigation] - We are above the OMC_END Node, stopping movement. ("..tostring(math.round(nodedist,2)).." < "..tostring(ml_navigation.OMCREACHEDDISTANCE)..")")
										Player:Stop()
										if ( omc.precise ) then
											ml_navigation:SetEnsurePosition(nextnode)
										end									
									else									
										Player:Move(FFXIV.MOVEMENT.FORWARD)
										Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
									end
									
								elseif ( movementstate == GW2.MOVEMENTSTATE.Falling and ml_navigation.omc_startheight) then
									-- If Playerheight is lower than 4*omcreached dist AND Playerheight is lower than 4* our Startposition -> we fell below the OMC START & END Point
									if (( ppos.z > (nextnode.z + 4*ml_navigation.OMCREACHEDDISTANCE)) and ( ppos.z > ( ml_navigation.omc_startheight + 4*ml_navigation.OMCREACHEDDISTANCE))) then
										if ( ml_navigation.omcteleportallowed and math.distance3d(ppos,nextnode) < ml_navigation.OMCREACHEDDISTANCE*10) then
											ml_navigation:SetEnsurePosition(nextnode) 
										else
											d("[Navigation] - We felt below the OMC start & END height, missed our goal...")
											ml_navigation.StopMovement()
										end
									else
										-- Additionally check if we are "above" the target point already, in that case, stop moving forward
										local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(ppos,nextnode)
										if ( nodedist < ml_navigation.OMCREACHEDDISTANCE) then
											d("[Navigation] - We are above the OMC END Node, stopping movement. ("..tostring(math.round(nodedist,2)).." < "..tostring(ml_navigation.OMCREACHEDDISTANCE)..")")
											Player:Stop()
											if ( omc.precise ) then
												ml_navigation:SetEnsurePosition(nextnode)											
											end									
										else									
											Player:Move(FFXIV.MOVEMENT.FORWARD)
											Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
										end
									end
									
								else	 
									-- We are still before our Jump
									if ( not ml_navigation.omc_startheight ) then
										if ( Player:CanMove() and ml_navigation.omc_starttimer == 0 ) then
											ml_navigation.omc_starttimer = ticks
											Player:Move(FFXIV.MOVEMENT.FORWARD)
											Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
										elseif ( Player:IsMoving() and ticks - ml_navigation.omc_starttimer > 100 ) then
											Player:Jump()
										end
										
									else
										-- We are after the Jump and landed already
										local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(ppos,nextnode)
										if ( nodedist < ml_navigation.OMCREACHEDDISTANCE) then
											d("[Navigation] - We reached the OMC END Node. ("..tostring(math.round(nodedist,2)).." < "..tostring(ml_navigation.OMCREACHEDDISTANCE)..")")
											if ( omc.precise ) then
												ml_navigation:SetEnsurePosition(nextnode)
											end
											ml_navigation.pathindex = ml_navigation.pathindex + 1
										else									
											Player:Move(FFXIV.MOVEMENT.FORWARD)
											Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
										end
									end
								end								
										
							elseif ( omc.type == 2 ) then
								ml_navigation:NavigateToNode(ppos,nextnode,10)
											
							elseif ( omc.type == 3 ) then
							-- OMC Teleport
								Hacks:Teleport(nextnode.x,nextnode.y,nextnode.z)
								ml_navigation.pathindex = ml_navigation.pathindex + 1
								
							elseif ( omc.type == 4 ) then
							-- OMC Interact
								Player:Interact()
								ml_navigation.lastupdate = ml_navigation.lastupdate + 1000
								ml_navigation.pathindex = ml_navigation.pathindex + 1
							
							elseif ( omc.type == 5 ) then
							-- OMC Portal
								ml_navigation:NavigateToNode(ppos,nextnode,20)
							
							elseif ( omc.type == 6 ) then
							-- OMC Lift
								ml_navigation:NavigateToNode(ppos,nextnode,15)						
																	
							end						
							--]]
						elseif (string.contains(nextnode.type,"CUBE") or IsFlying()) then
							if (not Player.ismounted) then
								d("[Navigation] - Mount for flight.")
								Mount()
								ffnav.Await(5000, function () return Player.ismounted end)
							else
								if (not IsFlying()) then
									if (Player:IsMoving()) then
										Player:StopMovement()
										ffnav.Await(3000, function () return not Player:IsMoving() end)
									else
										d("[Navigation] - Ascend for flight.")
										ffnav.Ascend()
									end
								else
									ffnav.FlyTo(nextpos)
								end
							end
						else
							--d("walk to ["..tostring(nextpos.x)..","..tostring(nextpos.y)..","..tostring(nextpos.z))
							ffnav.WalkTo(nextpos)
						end
					else
						d("[Navigation] - Something went wrong, the node is invalid.")
					end
				else
					if (table.valid(ffnav.currentPath)) then
						d("[Navigation] - Path end reached.")
						Player:Stop()
					end
				end
			end
		end
	end
end

function ffnav.IsStillOnPath()
	if ( ffnav.currentPathIndex > 0 ) then
		local ppos = Player.pos
		d("[Navigation] - Distance to Path: "..tostring(math.distancepointline(ffnav.currentPath[ffnav.currentPathIndex-1],ffnav.currentPath[ffnav.currentPathIndex],ppos)).." > "..tostring(3))
		if ( math.distancepointline(ffnav.currentPath[ffnav.currentPathIndex-1],ffnav.currentPath[ffnav.currentPathIndex],ppos) > 3) then			
			--ml_navigation.StopMovement()
			return false
		end
	end
	return true
end

function ffnav.AddPathRender()
	--d("checking path rendering")
	local vertices = {}
	local vertices2 = {}
	local vertices3 = {}
	local vertices4 = {}
	local vertices5 = {}
	
	--d("type:"..tostring(type(ffnav.currentPath)))
	for idx, node in pairsByKeys(ffnav.currentPath) do
		if (idx > 0 ) then
			-- from "last node"
			table.insert(vertices, {x=ffnav.currentPath[idx-1].x, y=ffnav.currentPath[idx-1].y, z=ffnav.currentPath[idx-1].z, r=0.12, g=1.0, b=0.165, a=1.0})
			table.insert(vertices2, {x=ffnav.currentPath[idx-1].x, y=ffnav.currentPath[idx-1].y+1, z=ffnav.currentPath[idx-1].z, r=0.12, g=1.0, b=0.165, a=1.0})
			table.insert(vertices3, {x=ffnav.currentPath[idx-1].x, y=ffnav.currentPath[idx-1].y-1, z=ffnav.currentPath[idx-1].z, r=0.12, g=1.0, b=0.165, a=1.0})
			table.insert(vertices4, {x=ffnav.currentPath[idx-1].x, y=ffnav.currentPath[idx-1].y+0.5, z=ffnav.currentPath[idx-1].z, r=0.12, g=1.0, b=0.165, a=1.0})
			table.insert(vertices5, {x=ffnav.currentPath[idx-1].x, y=ffnav.currentPath[idx-1].y-0.5, z=ffnav.currentPath[idx-1].z, r=0.12, g=1.0, b=0.165, a=1.0})
			-- to "current node"
			table.insert(vertices, {x=node.x, y=node.y, z=node.z, r=0.12, g=1.0, b=0.165, a=1.0})
			table.insert(vertices2, {x=node.x, y=node.y+1, z=node.z, r=0.12, g=1.0, b=0.165, a=1.0})
			table.insert(vertices3, {x=node.x, y=node.y-1, z=node.z, r=0.12, g=1.0, b=0.165, a=1.0})
			table.insert(vertices4, {x=node.x, y=node.y+0.5, z=node.z, r=0.12, g=1.0, b=0.165, a=1.0})
			table.insert(vertices5, {x=node.x, y=node.y-0.5, z=node.z, r=0.12, g=1.0, b=0.165, a=1.0})
		end
	end
	
	if (ffnav.pathRenderObject == nil) then
		ffnav.pathRenderObject = RenderManager:AddObject("NavPath", vertices, 1)
		ffnav.pathRenderObject2 = RenderManager:AddObject("NavPath", vertices2, 1)
		ffnav.pathRenderObject3 = RenderManager:AddObject("NavPath", vertices3, 1)
		ffnav.pathRenderObject4 = RenderManager:AddObject("NavPath", vertices4, 1)
		ffnav.pathRenderObject5 = RenderManager:AddObject("NavPath", vertices5, 1)
		--d("add new render object.")
	else
		ffnav.pathRenderObject = RenderManager:GetObject(ffnav.pathRenderObject.id)
		if (table.valid(ffnav.pathRenderObject)) then
			ffnav.pathRenderObject:SetVertices(vertices)
			ffnav.pathRenderObject2:SetVertices(vertices2)
			ffnav.pathRenderObject3:SetVertices(vertices3)
			ffnav.pathRenderObject4:SetVertices(vertices4)
			ffnav.pathRenderObject5:SetVertices(vertices5)
			--d("update render object.")
		else
			ffnav.pathRenderObject = RenderManager:AddObject("NavPath", vertices, 1)
			ffnav.pathRenderObject2 = RenderManager:AddObject("NavPath", vertices2, 1)
			ffnav.pathRenderObject3 = RenderManager:AddObject("NavPath", vertices3, 1)
			ffnav.pathRenderObject4 = RenderManager:AddObject("NavPath", vertices4, 1)
			ffnav.pathRenderObject5 = RenderManager:AddObject("NavPath", vertices5, 1)
			--d("fix render object render object.")
		end
	end	
end

--Player:MoveTo(-304.2,96.06,24.99)
--Player:MoveTo(-224.2,127.38,-85.89)

RegisterEventHandler("Gameloop.Draw", ffnav.Navigate)
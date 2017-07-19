--*** ALL 4 LISTS BELOW ARE USED / MODIFY-ABLE IN THE NAVIGATION->MESHMANAGER MINIONLIB UI
-- Distance to the next node in the path at which the ml_navigation.pathindex is iterated 
ml_navigation.NavPointReachedDistances = { 	
	["3dwalk"] = 2,		
	["2dwalk"] = 1,
	["3dmount"] = 5,
	["2dmount"] = 1,
	["3dfly"] = 5,
	["2dfly"] = 1.5,
}
--[[ Distance required basic task goals. A little softer than nav points.
Using this vs the ones above results in inconstent logic ... whne for ex e_walktopos uses different values than the actual navigation here, then A sais "walk" while B sais "already there" 
ml_navigation.PointReachedDistances = { 	
	["3dwalk"] = 2,		
	["2dwalk"] = 1,
	["3dmount"] = 5,
	["2dmount"] = 1,
	["3dfly"] = 5,
	["2dfly"] = 1.5,	
} clutter ? not used anywhere]]

-- Distance to the next node in the path, in case it is an OffMeshConnection, at which the ml_navigation.pathindex is iterated 
ml_navigation.OMCReachedDistances = { 			
	["3dwalk"] = 2,		
	["2dwalk"] = 0.4,
	["3dmount"] = 5,
	["2dmount"] = 0.6,
	["3dfly"] = 5,
	["2dfly"] = 1,
} 
-- We have a path already and a new one is requested, if the distance between old and new target position is larger than this one, a new path is being build.
ml_navigation.NewPathDistanceThresholds = { 	
	["3dwalk"] = 1.0,		
	["2dwalk"] = 0.4,
	["3dmount"] = 3.0,
	["2dmount"] = 0.6,
	["3dfly"] = 3.0,
	["2dfly"] = 1.0,
}
-- The max. distance the playerposition can be away from the current path. (The Point-Line distance between player and the last & next pathnode)
ml_navigation.PathDeviationDistances = { 		
	["3dwalk"] = 4,		
	["2dwalk"] = 2,
	["3dmount"] = 5,
	["2dmount"] = 5,
	["3dfly"] = 10,
	["2dfly"] = 8,
}

ml_navigation.receivedInstructions = {}
ml_navigation.instructionThrottle = 0
function ml_navigation.ParseInstructions(data)
	d("Received instruction set.")
	ml_navigation.receivedInstructions = {}
	
	if (ValidTable(data)) then
		local itype,iparams = nil,nil
		for i,instruction in pairsByKeys(data) do
			itype,iparams = instruction[1],instruction[2]
			if (itype == "Ascend") then
				table.insert(ml_navigation.receivedInstructions,
					function ()
						if (IsFlying()) then
							if (Player:IsMoving(FFXIV.MOVEMENT.UP)) then
								return true
							else
								Player:Move(128) 
								ml_global_information.Await(math.random(300,500))
								return false
							end
						else
							Player:Jump()
							ml_global_information.Await(math.random(50,150))
							return false
						end
					end
				)
			elseif (itype == "QuickAscend") then
				table.insert(ml_navigation.receivedInstructions, 
					function ()
						if (IsFlying()) then
							return true
						else
							Player:Jump()
							ml_global_information.Await(math.random(50,150))
							return false
						end
					end
				)
			elseif (itype == "Descend") then
				table.insert(ml_navigation.receivedInstructions, 
					function () 
						if (IsFlying()) then
							Player:SetPitch(1.377) 
							if (not Player:IsMoving()) then
								Player:Move(FFXIV.MOVEMENT.FORWARD)
								ml_global_information.Await(3000, function () return Player:IsMoving() end)
							end
							ml_global_information.Await(300)
							return false
						else
							return true
						end
					end
				)
			elseif (itype == "StraightDescend") then
				table.insert(ml_navigation.receivedInstructions, 
					function () 
						if (IsFlying()) then
							if (not Player:IsMoving(FFXIV.MOVEMENT.DOWN)) then
								Dismount()
							end
							ml_global_information.Await(1000, function () return not IsFlying() end)
							return false
						else
							return true
						end
					end
				)
			elseif (itype == "Stop") then
				table.insert(ml_navigation.receivedInstructions, 
					function () 
						if (Player:IsMoving()) then
							Player:Stop()
							ml_global_information.Await(1000, function () return not Player:IsMoving() end)
							return false
						else
							return true
						end
					end
				)
			elseif (itype == "Mount") then
				table.insert(ml_navigation.receivedInstructions, 
					function () 
						if (not Player.ismounted) then
							Mount()
							return false
						else
							return true
						end
					end
				)
			elseif (itype == "Dismount") then
				table.insert(ml_navigation.receivedInstructions, 
					function () 
						if (Player.ismounted) then
							Dismount()
							ml_global_information.Await(1000, function () return not Player.ismounted end)
							return false
						else
							return true
						end
					end
				)
			elseif (itype == "Wait") then
				local length = tonumber(iparams[1]) or 150
				table.insert(ml_navigation.receivedInstructions, 
					function () 
						ml_global_information.Await(length)
						return true						
					end
				)
			elseif (itype == "Interact") then
				local interactid = tonumber(iparams[1]) or 0
				local complete = tonumber(iparams[2]) or ""
				table.insert(ml_navigation.receivedInstructions, 
					function ()
						if (interactid ~= 0) then
							local interacts = EntityList("targetable,contentid="..tostring(interactid)..",maxdistance=15")
							if (table.valid(interacts)) then
								local i,interactable = next(interacts)
								if (table.valid(interactable) and interactable.interactable) then
									Player:SetFacing(interactable.pos.x,interactable.pos.y,interactable.pos.z)
									
									local currentTarget = Player:GetTarget()
									if (not currentTarget or currentTarget.id ~= interactable.id) then
										Player:SetTarget(interactable.id)
										return false
									end
									
									if (Player:IsMoving()) then
										Player:Stop()
										ml_global_information.Await(1000, function () return not Player:IsMoving() end)
										return false
									end
									
									Player:Interact(interactable.id)
									if (string.valid(complete)) then
										local f = assert(loadstring("return " .. complete))()
										if (f ~= nil) then
											return f
										end
									end
								end		
							end
						end
						return true				
					end
				)
			elseif (itype == "Jump") then
				table.insert(ml_navigation.receivedInstructions, 
					function () 
						Player:Jump()
						ml_global_information.Await(2000, function () return Player:IsJumping() end)
						return true						
					end
				)
			elseif (itype == "FacePosition") then
				local pos = { x = iparams[1] or nil, y = iparams[2] or nil, z = iparams[3] or nil}
				if (pos.x ~= nil) then
					if (pos.y ~= nil and pos.z ~= nil) then
						table.insert(ml_navigation.receivedInstructions, 
							function () 
								Player:SetFacing(pos.x,pos.y,pos.z) 
								return true
							end
						)
					else
						table.insert(ml_navigation.receivedInstructions, 
							function () 
								Player:SetFacing(pos.x) 
								ml_global_information.Await(1000, function () return Player.pos.h == pos.x end)
								return true
							end
						)
					end
				end
			elseif (itype == "MoveForward") then
				table.insert(ml_navigation.receivedInstructions, 
					function () 
						Player:Move(FFXIV.MOVEMENT.FORWARD) 
						ml_global_information.Await(3000, function () return Player:IsMoving() end)
						return true
					end
				)
			elseif (itype == "CheckIfLocked") then
				table.insert(ml_navigation.receivedInstructions, 
					function () 
						return IsPositionLocked()
					end
				)
			elseif (itype == "CheckIfMoveable") then
				table.insert(ml_navigation.receivedInstructions, 
					function () 
						return not IsPositionLocked()
					end
				)
			elseif (itype == "Action") then
				local actionid = iparams[1] or 0
				local actiontype = iparams[2] or 0 
				local targetid = iparams[3] or 0
				
				table.insert(ml_navigation.receivedInstructions, 
					function () 						
						if (action) then
							if (action.isoncd and ((action.cd - action.cdmax) > 2.5)) then
								return true
							else
								if (action:Cast(targetid)) then
									return true
								end
							end
						end
						return false
					end
				)
			elseif (itype == "Teleport") then
				local aetheryteid = iparams[1] or 0
				table.insert(ml_navigation.receivedInstructions, 
					function () 	
						if (not Player:IsMoving()) then
							if (Player:Teleport(aetheryteid)) then
								ml_global_information.Await(10000, function () return Quest:IsLoading() end)
								return true
							end
						else
							Player:Stop()
							ml_global_information.Await(3000, function () return (not Player:IsMoving()) end)
						end
						return false
					end
				)
			elseif (itype == "Return") then
				table.insert(ml_navigation.receivedInstructions, 
					function () 	
						if (not Player:IsMoving()) then
							local casting = Player.castinginfo.channelingid
							local returnHome = ActionList:Get(6)
							
							if (returnHome and returnHome.isready) then
								if (returnHome:Cast()) then
									ml_global_information.Await(10000, function () return Quest:IsLoading() end)
									return true
								end		
							elseif (not returnHome) then
								return true
							end
						else
							Player:Stop()
							ml_global_information.Await(3000, function () return (not Player:IsMoving()) end)
						end
						return false
					end
				)
			elseif (itype == "CheckIfNear") then
				local pos = { x = iparams[1] or nil, y = iparams[2] or nil, z = iparams[3] or nil }
				local dist3d = ((iparams[4] and iparams[4] ~= 0) and iparams[4]) or 2
				local dist2d = ((iparams[5] and iparams[5] ~= 0) and iparams[5]) or 0.55
				
				if (pos.x ~= nil and pos.y ~= nil and pos.z ~= nil) then
					table.insert(ml_navigation.receivedInstructions, 
						function ()
							local myPos = Player.pos
							return (Distance3DT(pos,myPos) <= dist3d and Distance2DT(pos,myPos) <= dist2d)
						end
					)
				end	
			elseif (itype == "MoveStraightTo") then
				local pos = { x = iparams[1] or nil, y = iparams[2] or nil, z = iparams[3] or nil }
				local dist3d = ((iparams[4] and iparams[4] ~= 0) and iparams[4]) or 2
				local dist2d = ((iparams[5] and iparams[5] ~= 0) and iparams[5]) or 0.55
				
				local jumps = {}
				if (TableSize(iparams) > 5) then
					for i = 6,TableSize(iparams) do
						if (table.valid(iparams[i])) then
							table.insert(jumps,iparams[i])
						end
					end
				end
				
				if (pos.x ~= nil and pos.y ~= nil and pos.z ~= nil) then
					table.insert(ml_navigation.receivedInstructions, 
						function ()
							local myPos = Player.pos
							Player:SetFacing(pos.x,pos.y,pos.z)
							Player:Move(FFXIV.MOVEMENT.FORWARD)
							ml_global_information.AwaitDo(100, 120000, 
								function ()
									if (not Player:IsMoving()) then
										return true
									end
									local myPos = Player.pos
									return (Distance3DT(pos,myPos) <= dist3d and Distance2DT(pos,myPos) <= dist2d)
								end,
								function ()
									Player:SetFacing(pos.x,pos.y,pos.z)
									if (not Player:IsJumping()) then
										if (table.valid(jumps)) then
											for i,jump in pairs(jumps) do
												if (Distance3DT(pos,myPos) <= 2 and Distance2DT(pos,myPos) <= 0.55) then
													Player:Jump()
												end
											end
										end
									end
								end,
								function ()
									if (Player:IsMoving()) then
										Player:Stop()
										ml_global_information.Await(1000, function () return (not Player:IsMoving()) end)
									end
								end
							)
							return true
						end
					)
				end	
			elseif (itype == "MoveStraightToContinue") then
				local pos = { x = iparams[1] or nil, y = iparams[2] or nil, z = iparams[3] or nil }
				local dist3d = ((iparams[4] and iparams[4] ~= 0) and iparams[4]) or 2
				local dist2d = ((iparams[5] and iparams[5] ~= 0) and iparams[5]) or 0.4
				
				local jumps = {}
				if (TableSize(iparams) > 5) then
					for i = 6,TableSize(iparams) do
						if (table.valid(iparams[i])) then
							table.insert(jumps,iparams[i])
						end
					end
				end
				
				if (pos.x ~= nil and pos.y ~= nil and pos.z ~= nil) then
					table.insert(ml_navigation.receivedInstructions, 
						function ()
							local myPos = Player.pos
							Player:SetFacing(pos.x,pos.y,pos.z)
							if (not Player:IsMoving()) then
								Player:Move(FFXIV.MOVEMENT.FORWARD)
							end
							ml_global_information.AwaitDo(100, 120000, 
								function ()
									if (not Player:IsMoving()) then
										return true
									end
									local myPos = Player.pos
									return (Distance3DT(pos,myPos) <= dist3d and Distance2DT(pos,myPos) <= dist2d)
								end,
								function ()
									Player:SetFacing(pos.x,pos.y,pos.z)
									if (not Player:IsJumping()) then
										if (table.valid(jumps)) then
											for i,jump in pairs(jumps) do
												if (Distance3DT(pos,myPos) <= 2 and Distance2DT(pos,myPos) <= 0.5) then
													Player:Jump()
												end
											end
										end
									end
								end
							)
							return true
						end
					)
				end	
			elseif (itype == "FlyStraightTo") then
				local pos = { x = iparams[1] or nil, y = iparams[2] or nil, z = iparams[3] or nil }
				local dist3d = ((iparams[4] and iparams[4] ~= 0) and iparams[4]) or 5
				local dist2d = ((iparams[5] and iparams[5] ~= 0) and iparams[5]) or 0.75
				
				if (pos.x ~= nil and pos.y ~= nil and pos.z ~= nil) then
					table.insert(ml_navigation.receivedInstructions, 
						function ()
							Player:SetFacing(pos.x,pos.y,pos.z)
							Player:Move(FFXIV.MOVEMENT.FORWARD)
							ml_global_information.AwaitDo(100, 120000, 
								function ()
									if (not Player:IsMoving()) then
										return true
									end
									local myPos = Player.pos
									d("3D:"..tostring(Distance3DT(pos,myPos))..", 2D:"..tostring(Distance2DT(pos,myPos)))
									return (Distance3DT(pos,myPos) <= dist3d and Distance2DT(pos,myPos) <= dist2d)
								end,
								function ()
									local myPos = Player.pos
									Player:SetFacing(pos.x,pos.y,pos.z,true)

									local currentPitch = math.round(Player.flying.pitch,3)
									local minVector = math.normalize(math.vectorize(myPos,pos))
									local pitch = math.asin(-1 * minVector.y)
									Player:SetPitch(pitch)
								end,
								function ()
									if (Player:IsMoving()) then
										Player:Stop()
										ml_global_information.Await(1000, function () return (not Player:IsMoving()) end)
									end
								end
							)
							return true
						end
					)
				end	
			elseif (itype == "FlyStraightToContinue") then
				local pos = { x = iparams[1] or nil, y = iparams[2] or nil, z = iparams[3] or nil }
				local dist3d = ((iparams[4] and iparams[4] ~= 0) and iparams[4]) or 5
				local dist2d = ((iparams[5] and iparams[5] ~= 0) and iparams[5]) or 0.75
				
				if (pos.x ~= nil and pos.y ~= nil and pos.z ~= nil) then
					table.insert(ml_navigation.receivedInstructions, 
						function ()
							Player:SetFacing(pos.x,pos.y,pos.z)
							Player:Move(FFXIV.MOVEMENT.FORWARD)
							ml_global_information.AwaitDo(100, 120000, 
								function ()
									if (not Player:IsMoving()) then
										return true
									end
									local myPos = Player.pos
									d("3D:"..tostring(Distance3DT(pos,myPos))..", 2D:"..tostring(Distance2DT(pos,myPos)))
									return (Distance3DT(pos,myPos) <= dist3d and Distance2DT(pos,myPos) <= dist2d)
								end,
								function ()
									local myPos = Player.pos
									Player:SetFacing(pos.x,pos.y,pos.z,true)
									
									local currentPitch = math.round(Player.flying.pitch,3)
									local minVector = math.normalize(math.vectorize(myPos,pos))
									local pitch = math.asin(-1 * minVector.y)
									Player:SetPitch(pitch)
								end
							)
							return true
						end
					)
				end	
			end
		end
	end
end	

-- Return the EXACT NAMES you used above in the 4 tables for movement type keys
function ml_navigation.GetMovementType()
	if ( not Player.ismounted ) then 
		return "2dwalk" 
	elseif ( Player.flying.isflying ) then
		return "3dmount"
	else
		return "2dmount"
	end
end

function ml_navigation.GetNewPathThresholds()
	if ( not Player.ismounted ) then 
		return ml_navigation.NewPathDistanceThresholds["2dwalk"],ml_navigation.NewPathDistanceThresholds["3dwalk"]
	elseif ( Player.flying.isflying ) then
		return ml_navigation.NewPathDistanceThresholds["2dfly"],ml_navigation.NewPathDistanceThresholds["3dfly"]
	else
		return ml_navigation.NewPathDistanceThresholds["2dmount"],ml_navigation.NewPathDistanceThresholds["3dmount"]
	end
end

function ml_navigation.GetMovementThresholds()
	if ( not Player.ismounted ) then 
		return ml_navigation.NavPointReachedDistances["2dwalk"],ml_navigation.NavPointReachedDistances["3dwalk"]
	elseif ( Player.flying.isflying ) then
		return ml_navigation.NavPointReachedDistances["2dfly"],ml_navigation.NavPointReachedDistances["3dfly"]
	else
		return ml_navigation.NavPointReachedDistances["2dmount"],ml_navigation.NavPointReachedDistances["3dmount"]
	end
end

-- New setup, split path building and movement so that calls aren't duplicated and re-checked unnecessarily.
-- [canPath] flag allows .Navigate() to run, this is necessary to that simply building a path does not necessarily mean it will be used.
-- in ffxiv_common_cne, walktopos will be split into getmovementpath and walktopos.
-- this is mostly because many things like stealth, mount, flight, etc, require not only knowing if they are needed but if they are possible (mesh exists, path exists, etc)


ml_navigation.canPath = false
ml_navigation.CanRun = function() 
	return (GetGameState() == FFXIV.GAMESTATE.INGAME and ml_navigation.canPath)
end 	-- Return true here, if the current GameState is "ingame" aka Player and such values are available

ml_navigation.EnablePathing = function (self)
	if (not self.canPath) then
		self.canPath = true
		return true
	end
	return false
end

ml_navigation.DisablePathing = function (self)
	if (self.canPath) then
		self.canPath = false
		return true
	end
	return false
end

ml_navigation.HasPath = function (self)
	return (table.valid(self.path) and self.path[self.pathindex] ~= nil)
end

ml_navigation.StopMovement = function() Player:Stop() end				 		-- Stop the navi + Playermovement
ml_navigation.IsMoving = function() return Player:IsMoving() end				-- Take a wild guess											
ml_navigation.avoidanceareasize = 2
ml_navigation.GUI = {
	pathHops = 0,
	currentIndex = 0,
	nextNodeDistance = 0,
	lastAction = "",
}

-- Tries to use RayCast to determine the exact floor height from Player and Node, and uses that to calculate the correct distance.
function ml_navigation:GetRaycast_Player_Node_Distance(ppos,nodepos)	
	local dist = math.distance3d(ppos,nodepos)
	local dist2d = math.distance2d(ppos,nodepos)
	if ( not IsFlying() ) then
		-- Raycast from "top to bottom" @PlayerPos and @NodePos	
		local P_hit, P_hitx, P_hity, P_hitz = RayCast(ppos.x,ppos.y+3,ppos.z,ppos.x,ppos.y-3,ppos.z) 
		--d("nodepos:"..tostring(nodepos))
		local N_hit, N_hitx, N_hity, N_hitz = RayCast(nodepos.x,nodepos.y+3,nodepos.z,nodepos.x,nodepos.y-3,nodepos.z) 

		if (P_hit and N_hit ) then 
			local raydist = math.distance3d(P_hitx, P_hity, P_hitz , N_hitx, N_hity, N_hitz)
			local raydist2d = math.distance2d(P_hitx, P_hitz , N_hitx, N_hitz)
			if (raydist < dist) then 
				dist = raydist
			end
			if (raydist2d < dist2d) then
				dist2d = raydist2d
			end
		end
	end
	return dist,dist2d
end

function ml_navigation.GetClearance(nodepos)
	local ppos = Player.pos
	
	local posBase = { x = ppos.x, y = ppos.y + 0.5, z = ppos.z }
	local posMid = { x = ppos.x, y = ppos.y + 1.5, z = ppos.z }
	local posHigh = { x = ppos.x, y = ppos.y + 2.5, z = ppos.z }
	
	local nodeMid = { x = nodepos.x, y = nodepos.y + 1.5, z = nodepos.z }
	local nodeHigh = { x = nodepos.x, y = nodepos.y + 2.5, z = nodepos.z }
	
	local castBaseHit, castBaseHitX, castBaseHitY, castBaseHitZ = RayCast(posBase.x,posBase.y,posBase.z,nodeHigh.x,nodeHigh.y,nodeHigh.z) 
	local castMidHit, castMidHitX, castMidHitY, castMidHitZ = RayCast(posMid.x,posMid.y,posMid.z,nodeMid.x,nodeMid.y,nodeMid.z) 
	local castHighHit, castHighHitX, castHighHitY, castHighHitZ = RayCast(posHigh.x,posHigh.y,posHigh.z,nodeHigh.x,nodeHigh.y,nodeHigh.z) 
	
	local lowest2d, lowest3d = 1000,1000
	if (castBaseHit) then
		lowest2d = math.distance2d(posBase.x, posBase.z , castBaseHitX, castBaseHitZ)
		lowest3d = math.distance3d(posBase.x, posBase.y, posBase.z , castBaseHitX, castBaseHitY, castBaseHitZ)
	end
	
	if (castMidHit) then
		local dist2d = math.distance2d(posMid.x, posMid.z , castMidHitX, castMidHitZ)
		local dist3d = math.distance3d(posMid.x, posMid.y, posMid.z , castMidHitX, castMidHitY, castMidHitZ)
		if (dist2d < lowest2d) then
			lowest2d = dist2d
		end
		if (dist3d < lowest3d) then
			lowest3d = dist3d
		end
	end
	
	if (castHighHit) then
		local dist2d = math.distance2d(posHigh.x, posHigh.z , castHighHitX, castHighHitZ)
		local dist3d = math.distance3d(posHigh.x, posHigh.y, posHigh.z , castHighHitX, castHighHitY, castHighHitZ)
		if (dist2d < lowest2d) then
			lowest2d = dist2d
		end
		if (dist3d < lowest3d) then
			lowest3d = dist3d
		end
	end

	return lowest3d,lowest2d
end

function ml_navigation:IsDestinationClose(ppos,goal)
	local goaldist,goaldist2d = ml_navigation:GetRaycast_Player_Node_Distance(ppos,goal)
	if (not Player.ismounted) then
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dwalk"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
			return true
		end
	else
		if (Player.flying.isflying) then
			if (goaldist <= ml_navigation.NavPointReachedDistances["3dfly"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dfly"]) then
				return true
			end
		else
			if (goaldist <= ml_navigation.NavPointReachedDistances["3dmount"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dmount"]) then
				return true
			end
		end
	end
	return false
end

function ml_navigation:CheckPath(pos,pos2,usecubes)
	local usecubes = IsNull(usecubes,true)
	if (not table.valid(pos) or not table.valid(pos2)) then
		return false
	end

	local t2d, t3d = ml_navigation.GetNewPathThresholds()
	if (table.valid(ffnav.lastStart) and table.valid(ffnav.lastGoal) and TimeSince(ffnav.lastGoalCheck) < 10000) then
		local start2d = math.distance2d(pos,ffnav.lastStart)
		local start3d = math.distance3d(pos,ffnav.lastStart)
		local goal2d = math.distance2d(pos2,ffnav.lastGoal)
		local goal3d = math.distance3d(pos2,ffnav.lastGoal)
		
		if (start2d <= t2d and goal2d <= t2d and start3d <= t3d and goal3d <= t3d) then
			return ffnav.lastGoalResult
		end
	end

	if ((Player.incombat and not Player.ismounted) or not usecubes) then
		NavigationManager:UseCubes(false)
	else
		NavigationManager:UseCubes(true)
	end
	
	local reachable = NavigationManager:IsReachable(pos2)
	--local length = self:GetPath(pos.x,pos.y,pos.z,pos2.x,pos2.y,pos2.z)
	--local reachable = (length > 0)
	NavigationManager:UseCubes(true)
	
	ffnav.lastStart = { x = pos.x, y = pos.y, z = pos.z }
	ffnav.lastGoal = { x = pos2.x, y = pos2.y, z = pos2.z }
	ffnav.lastGoalResult = reachable
	ffnav.lastGoalCheck = Now()
	
	return reachable
end

-- Often  used function to determine if the next node in the path is reached
function ml_navigation:IsGoalClose(ppos,node)
	local goaldist,goaldist2d = ml_navigation:GetRaycast_Player_Node_Distance(ppos,node)
	local clear3d,clear2d = ml_navigation.GetClearance(node)
	
	--d("[Navigation]: Goal 3D ["..tostring(goaldist).."] , 2D ["..tostring(goaldist2d).."]")
	--d("[Navigation]: Clearance 3D ["..tostring(clear3d).."] , 2D ["..tostring(clear2d).."]")
	
	if (goaldist2d < 4 and goaldist < 6) then
		if (clear3d < goaldist) then
			--d("[Navigation]: Using clearance 3D distance.")
			goaldist = clear3d
		end
		if (clear2d < goaldist2d) then
			--d("[Navigation]: Using clearance 2D distance.")
			goaldist2d = clear2d
		end
	end
	
	if (not Player.ismounted) then
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dwalk"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
			return true
		end
	else
		if (Player.flying.isflying) then
			--d("goaldist "..tostring(goaldist).. " < = "..tostring(ml_navigation.NavPointReachedDistances["3dfly"]).." and " ..tostring(goaldist2d).." < = " ..tostring(ml_navigation.NavPointReachedDistances["2dfly"]))
			if (goaldist <= ml_navigation.NavPointReachedDistances["3dfly"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dfly"]) then
				return true
			end
		else
			if (goaldist <= ml_navigation.NavPointReachedDistances["3dmount"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dmount"]) then
				return true
			end
		end
	end
	return false
end

-- MoveTo will now only build a path if one does not exist or the one it wants to use is not compatible.
-- Ideally, BuildPath should be called before this but there maybe legacy situations/tasks not updated where we don't want to just break them.
-- Added misc debug codes to more easily help identify debug messages.
function Player:MoveTo(x, y, z, navpointreacheddistance, randompath, smoothturns, navigationmode, cubesoff, newpathdistance, pathdeviationdistance)
	
	local buildNewPath = false
	local newGoal = { x = x, y = y, z = z }
	local newPath2d, newPath3d = ml_navigation.GetNewPathThresholds()
	if (not table.valid(ffnav.currentGoal)) then
		buildNewPath = true
		d("[NAVIGATION]: Need to build a new path, no current goal [MOVETO1].")
	else
		local dist2d = math.distance2d(ffnav.currentGoal,newGoal)
		local dist3d = math.distance3d(ffnav.currentGoal,newGoal)
		
		if (dist2d > newPath2d or dist3d > newPath3d) then
			buildNewPath = true
			d("[NAVIGATION]: Need to build a new path, current goal not appropriate [MOVETO2].")
		end
	end
	
	local ret;
	if (buildNewPath) then
		ret = Player:BuildPath(x, y, z, navpointreacheddistance, randompath, smoothturns, navigationmode, cubesoff)
	end
	
	if (ml_navigation:HasPath()) then
		if (ml_navigation:EnablePathing()) then
			d("[NAVIGATION: Started pathing [MOVETO3].")
		end
		return true
	else
		if (ml_navigation:DisablePathing()) then
			d("[NAVIGATION: Stopped pathing, path not valid [MOVETO4].")
		end
		return false
	end
	
	d("[NAVIGATION: Something went wrong, path result ["..tostring(ret).."], returned false as default [MOVETO5].")
	return ret
end

-- for replacing the original c++ Player:MoveTo with our lua version.  Every argument behind x,y,z is optional and the default values from above's tables will be used depending on the current movement type ! 
function Player:BuildPath(x, y, z, navpointreacheddistance, randompath, smoothturns, navigationmode, cubesoff, newpathdistance, pathdeviationdistance)
	-- Catching it trying to use cubes incombat still.
	-- Seems to originate from the fact that if a path can only be built with cubes that it will include them.
	-- Need something to build a partial path for walking only, to get it out of danger.
	
	local navigationmode = 1
	local cubesoff = IsNull(cubesoff,false)
	local randompath = IsNull(randompath,false)
	local smoothturns = IsNull(smoothturns,false)
	
	if ((Player.incombat and not Player.ismounted) or cubesoff) then
		NavigationManager:UseCubes(false)
	else
		NavigationManager:UseCubes(true)
	end
	
	if (x == nil or y==nil or z==nil ) then -- yes this happens regularly inside fates, because some of the puzzle code calls moveto nil/nil/nil
		d("[NAVIGATION]: Invalid Move To Position :["..tostring(x)..","..tostring(y)..","..tostring(z).."]")
		return 0
	end
	
	local newGoal = { x = x, y = y, z = z }
	
	ffnav.currentGoal = newGoal
	ffnav.currentParams = { navmode = navigationmode, range = navpointreacheddistance, randompath = randompath, smoothturns = smoothturns}
	
	local ppos = Player.pos
	--d("[64][NAVIGATION]: Move To ["..tostring(math.round(x,0))..","..tostring(math.round(y,0))..","..tostring(math.round(z,0)).."], From ["..tostring(math.round(ppos.x,0))..","..tostring(math.round(ppos.y,0))..","..tostring(math.round(ppos.z,0)).."], MapID "..tostring(Player.localmapid))
	local ret = ml_navigation:MoveTo(x, y, z, navigationmode, randompath, smoothturns, navpointreacheddistance, newpathdistance, pathdeviationdistance)
	
	ffnav.lastStart = { x = ppos.x, y = ppos.y, z = ppos.z }
	ffnav.lastGoal = { x = newGoal.x, y = newGoal.y, z = newGoal.z }
	ffnav.lastPathTime = Now()
	ffnav.lastGoalResult = (ret > 0)
	return ret
end

-- Overriding  the (old) c++ Player:Stop(), to handle the additionally needed navigation functions
function Player:Stop()
	--ml_navigation.ResetRenderPath()
	ml_navigation:ResetCurrentPath()
	ml_navigation:ResetOMCHandler()
	ml_navigation.canPath = false
	ffnav.lastStart = {}
	ffnav.currentGoal = {}
	ffnav.currentParams = {}
	ffnav.yield = {}
	ffnav.process = {}
	Player:StopMovement()	-- The "new" c++ sided STOP which stops the player's movement completely
end

function ml_navigation.IsHandlingInstructions(tickcount)
	if (ValidTable(ml_navigation.receivedInstructions)) then
		--d("Running instruction set.")
		if (Now() > ml_navigation.instructionThrottle) then
			ffxivminion.UpdateGlobals()
			
			local newInstruction = ml_navigation.receivedInstructions[1]
			if (newInstruction and type(newInstruction) == "function") then
				local retval = newInstruction()
				if (retval == true) then
					table.remove(ml_navigation.receivedInstructions,1)
				end
			end			
		end
		return true
	end
	return false
end

function ml_navigation.IsHandlingOMC(tickcount)
	if ( table.valid(ml_navigation.path) and ml_navigation.path[ml_navigation.pathindex] ~= nil) then	
		local nextnode = ml_navigation.path[ ml_navigation.pathindex ]
		if (nextnode.type == "OMC_END") then
			return true
		end
	end
	return false
end

-- Handles the actual Navigation along the current Path. Is not supposed to be called manually! 
-- Also handles OMCs
function ml_navigation.Navigate(event, ticks )		
	if ((ticks - (ml_navigation.lastupdate or 0)) > 50) then 
		ml_navigation.lastupdate = ticks
				
		if ( ml_navigation.CanRun() ) then				
			local ppos = Player.pos
			
			ml_navigation.GUI = {
				pathHops = 0,
				currentIndex = 0,
				nextNodeDistance = 0,
				lastAction = "",
			}
			
			--d("ml_navigation.pathsettings.navigationmode:"..tostring(ml_navigation.pathsettings.navigationmode))
			--d("is not processing:"..tostring(not ffnav.IsProcessing()))
			
			-- Normal Navigation Mode			
			if ( ml_navigation.pathsettings.navigationmode == 1 and not ffnav.IsProcessing()) then
				if ( table.valid(ml_navigation.path) and ml_navigation.path[ml_navigation.pathindex] ~= nil) then	
					if (ml_navigation.IsPathInvalid() and table.valid(ffnav.currentGoal)) then
						d("[Navigation]: Resetting path, need to pull a non-cube path.")
						-- Calling Stop() wasn't enough here, had to completely pull a new path otherwise it keeps trying to use the same path.
						Player:Stop()	-- calling stop first and then creating a new path would be the more logical order eh ;)
						NavigationManager:UseCubes(false)
						Player:MoveTo(ffnav.currentGoal.x,ffnav.currentGoal.y,ffnav.currentGoal.z)
						NavigationManager:UseCubes(true)
						--Player:Stop()
						return
					end
					
					if IsControlOpen("Talk") then
						UseControlAction("Talk","Click")
						ml_navigation.lastupdate = ml_navigation.lastupdate + 1500
						return
					end
					
					if (IsControlOpen("SelectYesno")) then
						PressYesNo(true)
						ml_navigation.lastupdate = ml_navigation.lastupdate + 1500
						return
					end
				
					local nextnode = ml_navigation.path[ ml_navigation.pathindex ]
					local nextnextnode = ml_navigation.path[ml_navigation.pathindex + 1]
					
					ml_navigation.GUI.pathHops = table.size(ml_navigation.path)
					ml_navigation.GUI.currentIndex = ml_navigation.pathindex			
					ml_navigation.GUI.nextNodeDistance = math.distance3d(ppos,nextnode)
					
			-- Ensure Position: Takes a second to make sure the player is really stopped at the wanted position (used for precise OMC bunnyhopping and others where the player REALLY has to be on the start point & facing correctly)
					if ( table.valid (ml_navigation.ensureposition) and ml_navigation:EnsurePosition() ) then						
						return
					end
					
		-- OffMeshConnection Navigation
					if (nextnode.type == "OMC_END") then
					
						ml_navigation.GUI.lastAction = "Ending OMC"
						
						if ( nextnode.id == nil ) then ml_error("[Navigation] - No OffMeshConnection ID received!") return end
						local omc = ml_mesh_mgr.offmeshconnections[nextnode.id]
						if( not omc ) then ml_error("[Navigation] - No OffMeshConnection Data found for ID: "..tostring(nextnode.id)) return end
							
						-- A general check, for the case that the player never reaches either OMC END
						if ( not ml_navigation.omc_id or ml_navigation.omc_id ~= nextnode.id ) then	-- Update the currently tracked omc_id and variables
							ml_navigation.omc_id = nextnode.id
							ml_navigation.omc_traveltimer = ticks
							ml_navigation.omc_traveldist = math.distance3d(ppos,nextnode)
							
						else	-- We are still pursuing the same omc, check if we are getting closer over time
							if (not MIsLocked()) then
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
							
							ml_navigation.GUI.lastAction = "Jump OMC"
							
							if ( Player:IsJumping()) then
								d("[Navigation]: Jumping for OMC.")
								ffnav.Await(10000, function () return (not Player:IsJumping()) end, function () Player:Stop() end)
							else	 
								-- We are still before our Jump
								if ( not ml_navigation.omc_startheight ) then
									local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})
									if ( anglediff > 0.3 ) then
										
										Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
										
									elseif ( ml_navigation.omc_starttimer == 0 ) then
										ml_navigation.omc_starttimer = ticks	
										if (not Player:IsMoving()) then
											Player:Move(FFXIV.MOVEMENT.FORWARD)
											ffnav.Await(1000, function () return Player:IsMoving() end)
										end
										
									elseif ( Player:IsMoving() and ticks - ml_navigation.omc_starttimer > 100 ) then	
										ml_navigation.omc_startheight = ppos.y
										Player:Jump()
										d("[Navigation]: Jump for OMC.")
									end
								else
									d("-- We are after the Jump and landed already")
									local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(ppos,nextnode)
									if ( nodedist < ml_navigation.NavPointReachedDistances["2dwalk"]) then
										d("[Navigation] - We reached the OMC END Node. ("..tostring(math.round(nodedist,2)).." < "..tostring(ml_navigation.NavPointReachedDistances["2dwalk"])..")")
										if ( omc.precise == nil or omc.precise == true ) then
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
							-- OMC Walk							
							ml_navigation.GUI.lastAction = "Walk OMC"
							ml_navigation:NavigateToNode(ppos,nextnode,1000)
										
						elseif ( omc.type == 3 ) then
							-- OMC Teleport
							ml_navigation.GUI.lastAction = "Teleport OMC"
							
							if (gTeleportHack) then
								Hacks:TeleportToXYZ(nextnode.x,nextnode.y,nextnode.z,true)
							else
								ffxiv_dialog_manager.IssueStopNotice("Teleport OMC","Teleport OMC's exist on this mesh.\nPlease enable the Teleport (Hack) usage in Advanced Settings or remove them.")
							end
							ml_navigation.pathindex = ml_navigation.pathindex + 1
							
						elseif ( omc.type == 4 ) then
							-- OMC Interact  I AM SO UNSURE IF THAT IS WORKING OR EVEN USED ANYMORE :D:D:D:D
							ml_navigation.GUI.lastAction = "Interact OMC"
							
							if (Player:IsMoving()) then
								Player:StopMovement()
								ffnav.Await(1000, function () return not Player:IsMoving() end)
								return
							end
							
							if (Player.ismounted) then
								Dismount()
								ffnav.Await(2000, function () return not Player.ismounted end)
								return
							end
							
							if (MIsLoading()) then
								ml_navigation.lastupdate = ml_navigation.lastupdate + 1500
								ml_navigation.pathindex = ml_navigation.pathindex + 1
								return
							end
							
							if (IsControlOpen("SelectString") or IsControlOpen("SelectIconString")) then
								SelectConversationIndex(1)
								ml_navigation.lastupdate = ml_navigation.lastupdate + 1000
								return
							end
							
							if (IsPositionLocked()) then
								ml_navigation.lastupdate = ml_navigation.lastupdate + 500
								return
							end
							
							-- We got moved to the End already, finish this.
							local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(ppos,nextnode)
							if ( nodedist < ml_navigation.NavPointReachedDistances["2dwalk"] or (ppos.y > nextnode.y and math.distance2d(ppos,nextnode) < ml_navigation.NavPointReachedDistances["2dwalk"]) ) then
								d("[Navigation] - OMC_END - Interact Node reached")
								ml_navigation.pathindex = ml_navigation.pathindex + 1								
							end
							
							-- Find a target to interact with
							local interactnpc
							local EList = EntityList("nearest,targetable,type=7,chartype=0,maxdistance=5")								
							if ( table.valid(EList)) then interactnpc = select(2,next(EList)) end
							
							if ( not interactnpc ) then 
								EList = EntityList("nearest,targetable,type=3,chartype=0,maxdistance=5")								
								if ( table.valid(EList)) then interactnpc = select(2,next(EList)) end
							end
							
							if ( not interactnpc ) then 
								EList = EntityList("nearest,targetable,maxdistance=7")								
								if ( table.valid(EList)) then interactnpc = select(2,next(EList)) end
							end
							
							if ( interactnpc ) then
								local target = MGetTarget()
								local interactid = interactnpc.id
								if (not target or (target and target.id ~= interactid)) then
									d("Setting target for interaction : "..interactnpc.name)
									Player:SetTarget(interactid)
									ml_navigation.omc_traveltimer = ticks + 1500
									ffnav.Await(1500, function () return (Player:GetTarget() and Player:GetTarget().id == interactid) end)
								elseif (target.interactable) then
									local npcpos = interactnpc.pos
									Player:SetFacing(npcpos.x,npcpos.y,npcpos.z)
									Player:Interact(interactnpc.id)
									d("Interacting with target : "..interactnpc.name)
									ml_navigation.omc_traveltimer = ticks + 2000
									ffnav.Await(2000, function () return (MIsLoading() or IsControlOpen("SelectYesno") or table.valid(GetConversationList())) end)
								end
							end
						
						elseif ( omc.type == 5 ) then
							-- OMC Portal
							ml_navigation.GUI.lastAction = "Portal OMC"
							ml_navigation:NavigateToNode(ppos,nextnode,2000)
						
						elseif ( omc.type == 6 ) then
							-- OMC Lift
							ml_navigation.GUI.lastAction = "Lift OMC"
							ml_navigation:NavigateToNode(ppos,nextnode,1500)						
																
						end	
		-- Cube Navigation
					elseif (IsFlying()) then -- we are in the air or our last node which was reached was a cube node, now continuing to the next node which can be either CUBE or POLY node
						--d("[Navigation]: Flying navigation.")
						
						ml_navigation.GUI.lastAction = "Flying to Node"
						local hit, hitx, hity, hitz = RayCast(nextnode.x,nextnode.y+5,nextnode.z,nextnode.x,nextnode.y-3,nextnode.z) 
						if (hit) then
							ml_debug("[Navigation]: Next node ground clearance:"..tostring(math.distance3d(nextnode.x, nextnode.y, nextnode.z, hitx, hity, hitz)))
						end
						
						-- Check if we left our path
						if ( not ffnav.isascending and not ml_navigation:IsStillOnPath(ppos,ml_navigation.pathsettings.pathdeviationdistance) ) then return end
														
						-- Check if the next node is reached:
						local dist3D = math.distance3d(nextnode,ppos)
						if ( ml_navigation:IsGoalClose(ppos,nextnode) and (string.contains(nextnode.type,"CUBE") or (hit and math.distance3d(ppos.x, ppos.y, ppos.z, hitx, hity, hitz) <= 5 ))) then
							-- We reached the node
							d("[Navigation] - Cube Node reached. ("..tostring(math.round(dist3D,2)).." < "..tostring(ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()])..")")
							ffnav.isascending = nil	-- allow the isstillonpath again after we reached our 1st node after ascending to fly
							
							-- We are flying and the last node was a cube-node. This next one now is a "floor-node", so we need to land now asap
							if (not string.contains(nextnode.type,"CUBE") ) then
								d("[Navigation]: Next node is not a flying node.")
								
								if (not table.valid(nextnextnode) or not string.contains(nextnextnode.type,"CUBE") ) then
									d("[Navigation]: Next next node is also not a flying node.")
									d("[Navigation] - Landing...")
								
									--Player:Move(FFXIV.MOVEMENT.DOWN)
									--SendTextCommand("/mount")			
									Player:SetFacing(nextnode.x,nextnode.y,nextnode.z) -- facing it, in case we run over it while descending, it would turn around again.
									Player:SetPitch(1.377) 
									if (not Player:IsMoving()) then
										Player:Move(FFXIV.MOVEMENT.FORWARD)
										ffnav.Await(3000, function () return Player:IsMoving() end)
										return false
									end
									ffnav.Await(5000, function () return not IsFlying() end)
									return false									
								end
							end
							ml_navigation.pathindex = ml_navigation.pathindex + 1		
						else			
							ml_debug("[Navigation]: Moving to next node")
							-- We have not yet reached our node
							-- Face next node
							local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})
							if ( anglediff < 35 and dist3D > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
								Player:SetFacing(nextnode.x,nextnode.y,nextnode.z, true) -- smooth facing
							else
								Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
							end
							
							-- Set Pitch							
							local currentPitch = math.round(Player.flying.pitch,3)
							local minVector = math.normalize(math.vectorize(ppos,nextnode))
							local pitch = math.asin(-1 * minVector.y)
							Player:SetPitch(pitch)
							
							-- Move
							if (not Player:IsMoving()) then
								Player:Move(FFXIV.MOVEMENT.FORWARD)	
								ffnav.Await(2000, function () return Player:IsMoving() end)
							end
						end
		-- Normal Navigation
					else
						--d("[Navigation]: Normal navigation..")
						
						if (string.contains(nextnode.type,"CUBE")) then
							d("nextnode : "..tostring(nextnode.x).." - "..tostring(nextnode.y).." - " ..tostring(nextnode.z))
							ml_navigation.GUI.lastAction = "Walk to Cube Node"
							
							-- Make sure the player has enough space above his head to start flying, casting a ray above his head to check space, if fail, it will walk towards the next cube node we are aiming at and keep checking until it has enough space...let's hope it never gets stuck :D
							--[[local hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y+5,ppos.z,ppos.x,ppos.y,ppos.z) -- top to bottom							
							if ( not hit ) then
								hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y+1,ppos.z, ppos.x,ppos.y+5,ppos.z) -- bottom to top  /raycast works often only into one direction of geometry
							end
							if (hit) then
								ml_debug("[Navigation]: Next node ground clearance distance:"..tostring(math.distance3d(nextnode.x, nextnode.y, nextnode.z, hitx, hity, hitz)))
							end]]
							if (not IsFlying() and (not hit or (hit and math.distance3d(nextnode.x, nextnode.y, nextnode.z, hitx, hity, hitz) > 5))) then	-- it will start flying if we have enough space above our head, if not, it keels wwalking on the poly mesh towards the next cube node in the air until it has space to fly
								if (not Player.ismounted) then
									d("[Navigation] - Mount for flight.")
									if (Player:IsMoving()) then
											Player:StopMovement()
											ffnav.Await(3000, function () return not Player:IsMoving() end)
											return -- need to return here, else  NavigateToNode below continues to move it ;)
									else
										Mount()
										ffnav.Await(5000, function () return Player.ismounted end)
										return
									end							
								else
									if (Player:IsMoving()) then
										Player:StopMovement()
										ffnav.Await(3000, function () return not Player:IsMoving() end)
										return -- need to return here, else  NavigateToNode below continues to move it ;)
									else
										d("[Navigation] - Ascend for flight.")
										ffnav.Ascend()
										ffnav.isascending = true
									end
								end
							end						
						end

-- TODO: ADD UNSTUCK HERE !!

						--d("[Navigation]: Navigate to node.")
						ml_navigation:NavigateToNode(ppos,nextnode)
										
					end
				
				else
					d("[Navigation] - Path end reached.")
					
					ffnav.lastGoalReachedFrom = ppos
					ffnav.lastGoalReached = ffnav.currentGoal
					
					ml_navigation.StopMovement()
					Player:Stop()							-- this literally makes no sense...both functions are the SAME but if I remove this one, the bot doesnt stop ..yeah right ...fuck you ffxiv 

				end	
			
			elseif (ml_navigation.pathsettings.navigationmode == 2 ) then
				d("[ml_navigation.Navigate] - Addd  other navmode type 2 ...is that used...?")
			end
		end		
	end
end
RegisterEventHandler("Gameloop.Draw", ml_navigation.Navigate)

function ml_navigation.DebugDraw(event, ticks )
	if ( table.valid(ml_navigation.path) and false) then	
		GUI:Begin("Nav-Monitor")
		
		GUI:Text("Path Hops:"); GUI:SameLine(150); GUI:Text(ml_navigation.GUI.pathHops)
		GUI:Text("Current Index:"); GUI:SameLine(150); GUI:Text(ml_navigation.GUI.currentIndex)
		GUI:Text("Next Node Distance:"); GUI:SameLine(150); GUI:Text(ml_navigation.GUI.nextNodeDistance)
		GUI:Text("Last Action:"); GUI:SameLine(150); GUI:Text(ml_navigation.GUI.lastAction)
		
		GUI:End()
	end			
end

RegisterEventHandler("Gameloop.Draw", ml_navigation.DebugDraw)

-- Used by multiple places in the Navigate() function above, so I'll put it here ...no redudant code...
function ml_navigation:NavigateToNode(ppos, nextnode, stillonpaththreshold)

	-- Check if we left our path
	if ( stillonpaththreshold ) then
		if ( not ml_navigation:IsStillOnPath(ppos,stillonpaththreshold) ) then return end	
	else
		if ( not ml_navigation:IsStillOnPath(ppos,ml_navigation.pathsettings.pathdeviationdistance) ) then return end	
	end
				
	-- Check if the next node is reached
	local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(ppos,nextnode)
	if ( ml_navigation:IsGoalClose(ppos,nextnode) ) then
		d("[Navigation] - Node reached. ("..tostring(math.round(nodedist,2)).." < "..tostring(ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()])..")")
							
		-- We arrived at an OMC Node
		if ( string.contains(nextnode.type,"OMC")) then
			ml_navigation:ResetOMCHandler()
			if ( nextnode.id == nil ) then ml_error("[Navigation] - No OffMeshConnection ID received!") return end
			local omc = ml_mesh_mgr.offmeshconnections[nextnode.id]
			if( not omc ) then ml_error("[Navigation] - No OffMeshConnection Data found for ID: "..tostring(nextnode.id)) return end
			if ( omc.precise == nil or omc.precise == true ) then	
				ml_navigation:SetEnsurePosition(nextnode) 
			end			
		end
		ml_navigation.pathindex = ml_navigation.pathindex + 1
	else						
		ml_navigation.GUI.lastAction = "Walk to Node"
		
		-- We have not yet reached our node
		local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})														
		if ( ml_navigation.pathsettings.smoothturns and anglediff < 35 and nodedist > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
			Player:SetFacing(nextnode.x,nextnode.y,nextnode.z,true)
		else
			Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
		end
		
		if (not Player:IsMoving() and not MIsLocked()) then
			Player:Move(FFXIV.MOVEMENT.FORWARD)
			ffnav.Await(2000, function () return Player:IsMoving() end)
		end
	end
end

function ml_navigation.IsPathInvalid()
	if (table.valid(ml_navigation.path)) then
		if (Player.incombat and not Player.ismounted) then
			for i, node in pairs(ml_navigation.path) do
				if (node.type == "CUBE") then
					return true
				end
			end		
		end		
	end
	return false
end

function ml_navigation:IsStillOnPath(ppos,deviationthreshold)	
	if ( ml_navigation.pathindex > 1 ) then
		local treshold = deviationthreshold or ml_navigation.PathDeviationDistances[ml_navigation.GetMovementType()]
		if ( not Player:IsJumping()) then
			-- measuring the distance from player to the straight line from navnode A to B  works only when we use the 2D distance, since it cuts obvioulsy through height differences. Only when flying it should use 3D.
			if (IsFlying()) then
				if (math.distancepointline(ml_navigation.path[ml_navigation.pathindex-1],ml_navigation.path[ml_navigation.pathindex],ppos) > treshold) then			
					d("[Navigation] - Player not on Path anymore. - Distance to Path: "..tostring(math.distancepointline(ml_navigation.path[ml_navigation.pathindex-1],ml_navigation.path[ml_navigation.pathindex],ppos)).." > "..tostring(treshold))
					Player:Stop()
					return false
				end
			else
				-- only use 2D 
				local from = { x = ml_navigation.path[ml_navigation.pathindex-1].x, y = 0, z = ml_navigation.path[ml_navigation.pathindex-1].z }
				local to = { x = ml_navigation.path[ml_navigation.pathindex].x, y = 0, z = ml_navigation.path[ml_navigation.pathindex].z }
				local ppos2d = { x = ppos.x, y = 0, z = ppos.z }
				if (math.distancepointline(from, to, ppos2d) > treshold) then			
					d("[Navigation] - Player not on Path anymore. - Distance to Path: "..tostring(math.distancepointline(ml_navigation.path[ml_navigation.pathindex-1],ml_navigation.path[ml_navigation.pathindex],ppos)).." > "..tostring(treshold))
					Player:Stop()
					return false
				end				
			end
		end
	end
	return true
end

-- Sets the position and heading which the main navigation call will make sure that it has "arrived", before continuing the movement
function ml_navigation:SetEnsurePosition(node, isstartnode)
	Player:StopMovement() -- stop just the player, not hte navpath!
	ml_navigation.ensureposition = {x = node.x, y = node.y, z = node.z}										
	if ( table.size(ml_navigation.path) > ml_navigation.pathindex+1 ) then
		node = ml_navigation.path[ ml_navigation.pathindex+1 ]		
		ml_navigation.ensureheading = {x = node.x, y = node.y, z = node.z}	-- Face Next Node
	else
		ml_navigation.ensureheading = {x = node.x, y = node.y, z = node.z}	-- Fallback case
	end
	ml_navigation:EnsurePosition()
end

-- Ensures that the player is really at a specific position, stopped and facing correctly
function ml_navigation:EnsurePosition()
	if ( not ml_navigation.ensurepositionstarttime ) then ml_navigation.ensurepositionstarttime = ml_global_information.Now end
	if ( (ml_global_information.Now - ml_navigation.ensurepositionstarttime) < 750 ) then		
		if ( Player:IsMoving () ) then Player:StopMovement() end
		local ppos = Player.pos
		local dist = ml_navigation:GetRaycast_Player_Node_Distance(ppos,ml_navigation.ensureposition)
						
		if ( dist > 0.5 and ml_navigation.omcteleportallowed ) then
			Hacks:TeleportToXYZ(ml_navigation.ensureposition.x,ml_navigation.ensureposition.y,ml_navigation.ensureposition.z,true)
		end
		local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = ml_navigation.ensureposition.x-ppos.x, y = 0, z = ml_navigation.ensureposition.z-ppos.z})
		if ( anglediff > 5 ) then 
			Player:SetFacing(ml_navigation.ensureheading.x,ml_navigation.ensureheading.y,ml_navigation.ensureheading.z) -- face hard
		end
		return true
	else	-- We waited long enough
		ml_navigation.ensureposition = nil
		ml_navigation.ensureheading = nil
		ml_navigation.ensurepositionstarttime = nil
	end
	return false
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

ffnav = {}
ffnav.yield = {}
ffnav.process = {}
ffnav.alteredGoal = {}
ffnav.lastStart = {}
ffnav.lastGoal = {}
ffnav.currentGoal = {}
ffnav.currentParams = {}
ffnav.lastGoalResult = false
ffnav.lastGoalCheck = 0
ffnav.lastGoalReachedFrom = {}
ffnav.lastGoalReached = {}
ffnav.lastPathTime = 0
ffnav.ascendTime = 0

function ffnav.IsProcessing()
	if (ffnav.IsYielding()) then
		--d("still yielding")
		return true
	end
	
	if (table.valid(ffnav.process)) then
		local process = ffnav.process
		
		local successTimer = false
		local successEval = false
		
		if (process.dowhile ~= nil and type(process.dowhile) == "function") then
			process.dowhile()
		end
		if (process.mintimer and process.mintimer ~= 0) then
			if (Now() < process.mintimer) then
				return true
			end
		end
		if (process.maxtimer and process.maxtimer ~= 0 and Now() >= process.maxtimer) then
			successTimer = true
		end
		
		if (process.evaluator ~= nil and type(process.evaluator) == "function") then
			local ret = process.evaluator()
			if (ret == true) then
				ffnav.process = {}
				
				if (process.followsuccess ~= nil and type(process.followsuccess) == "function") then
					process.followsuccess()
					return true
				end
				
				if (process.followall ~= nil and type(process.followall) == "function") then
					process.followall()
					return true
				end
			end
		end		
		
		local failed = false
		if (process.failure ~= nil and type(process.failure) == "function") then
			local ret = process.failure()
			if (ret == true) then
				failed = true
			end
		end
		
		if (successTimer or failed) then
			ffnav.process = {}
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
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
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
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
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

function ffnav.AwaitFail(param1, param2, param3, param4, param5)
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
		ffnav.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			both = IsNull(param4,false),
			followfail = param5,
		}
	else
		ffnav.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			followfail = param3,
			both = IsNull(param4,false),
		}
	end
end

function ffnav.AwaitSuccess(param1, param2, param3, param4, param5)
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
		ffnav.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			followsuccess = param4,
			both = IsNull(param5,false),
		}
	else
		ffnav.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			followsuccess = param3,
			both = IsNull(param4,false),
		}
	end
end

function ffnav.AwaitSuccessFail(param1, param2, param3, param4, param5, param6)
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
		ffnav.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			failure = param4,
			followsuccess = param5,
			followfail = param6,
		}
	else
		ffnav.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			failure = param3,
			followsuccess = param4,
			followfail = param5,
		}
	end
end

function ffnav.Ascend()	
	ml_navigation.GUI.lastAction = "Ascend"
	
	ffnav.process = {
		mintime = 150, maxtime = 10000, 
		evaluator = function ()
			local ppos = Player.pos
			if (IsFlying()) then
				local hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y,ppos.z,ppos.x,ppos.y-5,ppos.z) 
				if (not hit or (os.clock() - ffnav.ascendTime) > 3 ) then
					Player:StopMovement()
					ffnav.Await(1000, function () return (not Player:IsMoving(FFXIV.MOVEMENT.UP)) end)
					return true
				else
					if (not Player:IsMoving(FFXIV.MOVEMENT.UP)) then
						Player:Move(FFXIV.MOVEMENT.UP) 
						ffnav.Await(150, 5000, 
							function () 
								ffnav.ascendTime = os.clock()
								return Player:IsMoving(FFXIV.MOVEMENT.UP) 
							end
						)
						return false
					end
				end
			else
				if (not Player.ismounted)then
					d("[Navigation]: WE SHOULD NEVER BE HERE, REPORT THIS TO US PLEASE WITH A SCREENSHOT IF POSSIBLE")
					Player:StopMovement()
					return true
				else
					d("[Navigation]: Jump to Ascend.")
					Player:Jump()
					Player:Move(FFXIV.MOVEMENT.UP) 
					ffnav.Await(math.random(50,150))
					return false
				end
			end
		end, 
		failure = function ()
			--local fail = Player.incombat and not Player.ismounted		-- for what cases is this player.incombat ? afaik we are already mounted or we are not (no clue how we got in this ascend() wiuthout being mounted though), and once we are moutned we can fly always  even while being in combat ?
			local fail = not Player.ismounted
			if ( fail ) then
				d("[Navigation]: Player is not mounted to Ascend...")
				Player:StopMovement()  -- need to stop here, else it will keep flying up and do the weirdest movements when in combat while ascending.				
			end
			return fail
		end,
	}
end









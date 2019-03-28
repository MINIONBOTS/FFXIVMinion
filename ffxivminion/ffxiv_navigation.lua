--*** ALL 4 LISTS BELOW ARE USED / MODIFY-ABLE IN THE NAVIGATION->MESHMANAGER MINIONLIB UI
-- Distance to the next node in the path at which the ml_navigation.pathindex is iterated 
ml_navigation.NavPointReachedDistances = { 	
	["3dwalk"] = 2,		
	["2dwalk"] = .5,
	["3dmount"] = 5,
	["2dmount"] = 1,
	["3dswim"] = 5,
	["2dswim"] = .75,
	["3ddive"] = 5,
	["2ddive"] = 1.25,
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
	["3dswim"] = 5,
	["2dswim"] = 0.5,
	["3ddive"] = 5,
	["2ddive"] = 1,
	["3dfly"] = 5,
	["2dfly"] = 1,
} 
-- We have a path already and a new one is requested, if the distance between old and new target position is larger than this one, a new path is being build.
ml_navigation.NewPathDistanceThresholds = { 	
	["3dwalk"] = 1.0,		
	["2dwalk"] = 0.4,
	["3dmount"] = 3.0,
	["2dmount"] = 0.6,
	["3dswim"] = 3.0,
	["2dswim"] = 0.5,
	["3ddive"] = 3,
	["2ddive"] = 1,
	["3dfly"] = 3.0,
	["2dfly"] = 1.0,
}
-- We have a path already and a new one is requested, if the distance between old and new target position is larger than this one, a new path is being build, else it tries to adjust just the tail of the current path to save cpu power
ml_navigation.NewPathMaxDistanceThresholds = { 	
	["3dwalk"] = 10.0,		
	["2dwalk"] = 10.0,
	["3dmount"] = 10.0,
	["2dmount"] = 10.0,
	["3dswim"] = 10.0,
	["2dswim"] = 10.0,
	["3ddive"] = 10,
	["2ddive"] = 10,
	["3dfly"] = 10.0,
	["2dfly"] = 10.0,
}	
-- The max. distance the playerposition can be away from the current path. (The Point-Line distance between player and the last & next pathnode)
ml_navigation.PathDeviationDistances = { 		
	["3dwalk"] = 6,		
	["2dwalk"] = 3,
	["3dmount"] = 5,
	["2dmount"] = 5,
	["3dswim"] = 6,
	["2dswim"] = 3,
	["3ddive"] = 10,
	["2ddive"] = 8,
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
							Player:SetPitch(1.4835) 
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
								--Dismount()
								Player:Move(FFXIV.MOVEMENT.DOWN)
								ml_global_information.Await(1000, function () return Player:IsMoving(FFXIV.MOVEMENT.DOWN) end)
							end
							ml_global_information.Await(500, function () return not IsFlying() end)
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
							Player:PauseMovement()
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
			elseif (itype == "Dive") then
				table.insert(ml_navigation.receivedInstructions, 
					function () 
						if (Player.diving.isswimming) then
							Player:Dive()
							ml_global_information.Await(1000, function () return not Player.diving.isswimming end)
							return false
						else
							return true
						end
					end
				)
			elseif (itype == "RefreshMesh") then
				table.insert(ml_navigation.receivedInstructions, 
					function () 
						ml_mesh_mgr.lastmapid = 0
						return true
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
										Player:PauseMovement()
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
						if (Player:IsJumping()) then
							--Player:PauseMovement()
							return true	
						else
							Player:Jump()
							ml_global_information.Await(500, 2000, function () return Player:IsJumping() end)
							return false
						end											
					end
				)
			elseif (itype == "FacePosition") then
				local pos = { x = iparams[1] or nil, y = iparams[2] or nil, z = iparams[3] or nil}
				if (pos.x ~= nil) then
					if (pos.y ~= nil and pos.z ~= nil) then
						table.insert(ml_navigation.receivedInstructions, 
							function () 
								local ppos = Player.pos
								local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = pos.x-ppos.x, y = 0, z = pos.z-ppos.z})
								if (anglediff <= 1) then
									return true
								else						
									Player:SetFacing(pos.x,pos.y,pos.z) 
									return false
								end
							end
						)
					else
						table.insert(ml_navigation.receivedInstructions, 
							function () 
								if (math.abs(Player.pos.h - pos.x) < 0.01) then
									return true
								else
									Player:SetFacing(pos.x) 
									ml_global_information.Await(1000, function () return math.abs(Player.pos.h - pos.x) < 0.01 end)
									return false
								end
							end
						)
					end
				end
			elseif (itype == "MoveForward") then
				table.insert(ml_navigation.receivedInstructions, 
					function () 
						if (not Player:IsMoving()) then
							Player:Move(FFXIV.MOVEMENT.FORWARD) 
							ml_global_information.Await(3000, function () return Player:IsMoving() end)
							return false
						else
							return true
						end
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
								ml_global_information.Await(10000, function () return MIsLoading() end)
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
									ml_global_information.Await(10000, function () return MIsLoading() end)
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
										Player:PauseMovement()
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
										Player:PauseMovement()
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
	if ( Player.flying.isflying ) then
		return "3dfly"
	elseif (Player.diving.isdiving) then
		return "3ddive"
	elseif (Player.diving.isswimming) then
		return "3dswim"
	elseif (Player.ismounted) then
		return "2dmount"
	else	
		return "2dwalk" 
	end
end

function ml_navigation.GetNewPathThresholds()
	if ( Player.flying.isflying ) then
		return ml_navigation.NewPathDistanceThresholds["2dfly"],ml_navigation.NewPathDistanceThresholds["3dfly"]
	elseif (Player.diving.isdiving) then
		return ml_navigation.NewPathDistanceThresholds["2ddive"],ml_navigation.NewPathDistanceThresholds["3ddive"]
	elseif (Player.diving.isswimming) then
		return ml_navigation.NewPathDistanceThresholds["2dswim"],ml_navigation.NewPathDistanceThresholds["3dswim"]
	elseif (Player.ismounted) then
		return ml_navigation.NewPathDistanceThresholds["2dmount"],ml_navigation.NewPathDistanceThresholds["3dmount"]
	else
		return ml_navigation.NewPathDistanceThresholds["2dwalk"],ml_navigation.NewPathDistanceThresholds["3dwalk"]
	end
end

function ml_navigation.GetMovementThresholds()
	if ( Player.flying.isflying ) then
		return ml_navigation.NavPointReachedDistances["2dfly"],ml_navigation.NavPointReachedDistances["3dfly"]
	elseif (Player.diving.isdiving) then
		return ml_navigation.NavPointReachedDistances["2ddive"],ml_navigation.NavPointReachedDistances["3ddive"]
	elseif (Player.diving.isswimming) then
		return ml_navigation.NavPointReachedDistances["2dswim"],ml_navigation.NavPointReachedDistances["3dswim"]
	elseif (Player.ismounted) then
		return ml_navigation.NavPointReachedDistances["2dmount"],ml_navigation.NavPointReachedDistances["3dmount"]
	else
		return ml_navigation.NavPointReachedDistances["2dwalk"],ml_navigation.NavPointReachedDistances["3dwalk"]
	end
end

function ml_navigation.GetDeviationThresholds()
	if (Player.flying.isflying) then
		return ml_navigation.PathDeviationDistances["2dfly"],ml_navigation.PathDeviationDistances["3dfly"]
	elseif (Player.diving.isdiving) then
		return ml_navigation.PathDeviationDistances["2ddive"],ml_navigation.PathDeviationDistances["3ddive"]
	elseif (Player.diving.isswimming) then
		return ml_navigation.PathDeviationDistances["2dswim"],ml_navigation.PathDeviationDistances["3dswim"]
	elseif (Player.ismounted) then
		return ml_navigation.PathDeviationDistances["2dmount"],ml_navigation.PathDeviationDistances["3dmount"]
	else
		return ml_navigation.PathDeviationDistances["2dwalk"],ml_navigation.PathDeviationDistances["3dwalk"]
	end
end

-- New setup, split path building and movement so that calls aren't duplicated and re-checked unnecessarily.
-- [canPath] flag allows .Navigate() to run, this is necessary to that simply building a path does not necessarily mean it will be used.
-- in ffxiv_common_cne, walktopos will be split into getmovementpath and walktopos.
-- this is mostly because many things like stealth, mount, flight, etc, require not only knowing if they are needed but if they are possible (mesh exists, path exists, etc)

ml_navigation.CanRun = function() 
	return (GetGameState() == FFXIV.GAMESTATE.INGAME and not MIsLoading() and Player.alive)
end 	-- Return true here, if the current GameState is "ingame" aka Player and such values are available

ml_navigation.canPath = false
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
		Player:Stop() -- how about we actually stop then :P else endless running happens...
		return true
	end
	return false
end

ml_navigation.HasPath = function (self)
	--return (table.valid(self.path) and self.path[self.pathindex] ~= nil)
	return (table.valid(self.path))
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
		local P_hit, P_hitx, P_hity, P_hitz = RayCast(ppos.x,ppos.y+3,ppos.z,ppos.x,ppos.y-3,ppos.z) 
		local N_hit, N_hitx, N_hity, N_hitz = RayCast(nodepos.x,nodepos.y+3,nodepos.z,nodepos.x,nodepos.y-3,nodepos.z) 

		if (P_hit and N_hit) then 
			local raydist = math.distance3d(P_hitx, P_hity, P_hitz , N_hitx, N_hity, N_hitz)
			local raydist2d = math.distance2d(P_hitx, P_hitz , N_hitx, N_hitz)
			if (raydist < dist) then 
				dist = raydist
				--d("raydist3d:"..tostring(dist))
			end
			if (raydist2d < dist2d) then
				dist2d = raydist2d
				--d("raydist2d:"..tostring(dist2d))
			end
		end
	end
	return dist,dist2d
end

-- Just some table for tracking misc shit, might use later.
ml_navigation.tracking = {}

-- So, basic, theory, try to steer VERY slightly left or right to avoid obstacles.
ml_navigation.lastObstacleCheck = 0
function ml_navigation.CheckObstacles()
	
	--if (TimeSince(ml_navigation.lastObstacleCheck) > 150) then
		local ppos = Player.pos
		local nextNode = ml_navigation.path[ml_global_information.pathindex]
		
		if (false and table.isa(nextNode)) then
		
			local h = ppos.h
			
			-- Using node heading to make sure we're following the path and not some wild correction vector.
			local angle = AngleFromPos(Player.pos, nextNode)
			local nodeHeading = DegreesToHeading(angle)
			
			local leftBaseHeading = ConvertHeading(nodeHeading + (math.pi/2))%(2*math.pi)
			local rightBaseHeading = ConvertHeading(nodeHeading - (math.pi/2))%(2*math.pi)
			local forwardHeading = ConvertHeading(nodeHeading)%(2*math.pi)
			
			local slightLeft = ConvertHeading(nodeHeading + (math.pi * .04))%(2*math.pi)
			local slightRight = ConvertHeading(nodeHeading - (math.pi * .04))%(2*math.pi)
			
			local leftBase = GetPosFromDistanceHeading(ppos, 0.5, leftBaseHeading)
			local rightBase = GetPosFromDistanceHeading(ppos, 0.5, rightBaseHeading)
			local leftBaseExtended = GetPosFromDistanceHeading(ppos, 2, leftBaseHeading)
			local rightBaseExtended = GetPosFromDistanceHeading(ppos, 2, rightBaseHeading)	
			local leftTest = GetPosFromDistanceHeading(leftBase, 1, nodeHeading)
			local rightTest = GetPosFromDistanceHeading(rightBase, 1, nodeHeading)
			local straightTest = GetPosFromDistanceHeading(ppos, 1, nodeHeading)
		
			local lbe_hit, lbe_hitx, lbe_hity, lbe_hitz = RayCast(ppos.x,ppos.y+0.5,ppos.z,leftBaseExtended.x,leftBaseExtended.y+0.5,leftBaseExtended.z) 
			local rbe_hit, rbe_hitx, rbe_hity, rbe_hitz = RayCast(ppos.x,ppos.y+0.5,ppos.z,rightBaseExtended.x,rightBaseExtended.y+0.5,rightBaseExtended.z) 
			local lblt_hit, lblt_hitx, lblt_hity, lblt_hitz = RayCast(leftBase.x,leftBase.y+0.5,leftBase.z,leftTest.x,leftTest.y+0.5,leftTest.z) 
			local rbrt_hit, rbrt_hitx, rbrt_hity, rbrt_hitz = RayCast(rightBase.x,rightBase.y+0.5,rightBase.z,rightTest.x,rightTest.y+0.5,rightTest.z) 
			local st_hit, st_hitx, st_hity, st_hitz = RayCast(ppos.x,ppos.y+0.5,ppos.z,straightTest.x,straightTest.y+0.5,straightTest.z) 
			local lbst_hit, lbst_hitx, lbst_hity, lbst_hitz = RayCast(leftBase.x,leftBase.y+0.5,leftBase.z,straightTest.x,straightTest.y+0.5,straightTest.z) 
			local rbst_hit, rbst_hitx, rbst_hity, rbst_hitz = RayCast(rightBase.x,rightBase.y+0.5,rightBase.z,straightTest.x,straightTest.y+0.5,straightTest.z) 
			
			if (st_hit) then
				if (lbst_hit or lblt_hit) then
					d("slight left")
					return slightLeft	
				elseif (rbst_hit or rbrt_hit) then
					d("slight right")
					return slightRight
				end			
			elseif (lbe_hit and lblt_hit) then
				d("slight left")
				return slightLeft	
			elseif (rbe_hit and rbrt_hit) then
				d("slight right")
				return slightRight
			end
		end
		ml_navigation.lastObstacleCheck = Now()
	--end
	
	return 0
end

-- Performs some raycasting for awkward-edge encounters.
function ml_navigation.GetClearance(nodepos)
	local ppos = Player.pos
	
	--local posBase = { x = ppos.x, y = ppos.y + 0.5, z = ppos.z }
	local posMid = { x = ppos.x, y = ppos.y + 1.5, z = ppos.z }
	local posHigh = { x = ppos.x, y = ppos.y + 2.5, z = ppos.z }
	
	local nodeMid = { x = nodepos.x, y = nodepos.y + 1.5, z = nodepos.z }
	local nodeHigh = { x = nodepos.x, y = nodepos.y + 2.5, z = nodepos.z }
	
	local castMidHit, castMidHitX, castMidHitY, castMidHitZ = RayCast(posMid.x,posMid.y,posMid.z,nodeMid.x,nodeMid.y,nodeMid.z) 
	local castHighHit, castHighHitX, castHighHitY, castHighHitZ = RayCast(posHigh.x,posHigh.y,posHigh.z,nodeHigh.x,nodeHigh.y,nodeHigh.z) 
	
	local lowest2d, lowest3d = 1000,1000
	
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

-- This is more of a one-off check, only here as a utility, not actively used in normal navigation.
function ml_navigation:IsDestinationClose(ppos,goal)
	local goaldist,goaldist2d = ml_navigation:GetRaycast_Player_Node_Distance(ppos,goal)
	if (Player.flying.isflying) then
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dfly"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dfly"]) then
			return true
		end
	elseif (Player.diving.isdiving) then
		if (goaldist <= ml_navigation.NavPointReachedDistances["3ddive"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2ddive"]) then
			return true
		end
	elseif (Player.diving.isswimming) then
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dswim"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dswim"]) then
			return true
		end
	elseif (Player.ismounted) then
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dmount"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dmount"]) then
			return true
		end
	else
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dwalk"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
			return true
		end
	end
	
	return false
end

-- Often  used function to determine if the next node in the path is reached
function ml_navigation:IsGoalClose(ppos,node)
	local goaldist,goaldist2d = ml_navigation:GetRaycast_Player_Node_Distance(ppos,node)
	local clear3d,clear2d = ml_navigation.GetClearance(node)
	
	--d("[Navigation]: Goal 3D ["..tostring(goaldist).."] , 2D ["..tostring(goaldist2d).."]")
	--d("[Navigation]: Clearance 3D ["..tostring(clear3d).."] , 2D ["..tostring(clear2d).."]")
	
	if (goaldist2d < 2 and goaldist < 6) then
		if (clear3d < goaldist) then
			--d("[Navigation]: Using clearance 3D distance.")
			goaldist = clear3d
		end
		if (clear2d < goaldist2d) then
			--d("[Navigation]: Using clearance 2D distance.")
			goaldist2d = clear2d
		end
	end
	
	-- Floor2Cube connections have a radius inwhich the player (as soon as he is inside it) is allowed to traverse to the "other side" of the connection instead of walking to the same middle point each time ( this is ofc only for the connections that have not yet been removed due to stringpulling/shortening of the path
	--type = 0: disabled, 1: cube-cube, 2: floor-floor, 3: floor-cube, 4: custom omc, 5: macromesh
	
	local nc
	local ncsubtype
	local ncdirectionFromA
	if (node.navconnectionid and node.navconnectionid ~= 0) then
		-- 'live nav' vs 'new nav'
		if (NavigationManager.ShowCells == nil ) then	
			if (table.valid(ml_mesh_mgr.navconnections)) then
				nc = ml_mesh_mgr.navconnections[node.navconnectionid]
			end
			ncsubtype = nc.subtype
		else
			nc = NavigationManager:GetNavConnection(node.navconnectionid)
			ncsubtype = nc.details.subtype
		end
		if (nc and nc.type ~= 5) then -- Type 5 == MacroMesh
			local ncradius
			if(node.navconnectionsideA ~= nil ) then -- new nav code, NCs have sideA and sideB which can have different radii				
				d("YES "..tostring(node.navconnectionsideA))
				if(node.navconnectionsideA == true) then
					ncradius = nc.sideA.radius
					ncdirectionFromA =  true
				else
					ncradius = nc.sideB.radius
					ncdirectionFromA =  false
				end
			else
				ncradius = nc.radius
			end
			
			if (nc.type == 3 and Player.flying.isflying) then
				goaldist2d = goaldist2d - ncradius
				if (math.abs(ppos.y-node.y) < 3) then -- some of the connection radius' are too big, don't want a full on sphere
					goaldist = goaldist - ncradius
				end
			else
				--d("substracing the radius from the remaining distance")
				goaldist = goaldist - ncradius
				goaldist2d = goaldist2d - ncradius
			end
		end
	end
	
	if (Player.flying.isflying) then
		--d("index = "..tostring(ml_navigation.pathindex)..", y = "..tostring(node.y)..",goaldist "..tostring(goaldist).. " < = "..tostring(ml_navigation.NavPointReachedDistances["3dfly"]).." and " ..tostring(goaldist2d).." < = " ..tostring(ml_navigation.NavPointReachedDistances["2dfly"]))
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dfly"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dfly"]) then
			self:ResetOMCHandler()
			if ( nc and In(ncsubtype,1,2,3,4)) then				
				self.omc_id = nc.id
				self.omc_details = nc
				if(ncdirectionFromA~=nil) then
					self.omc_direction = ncdirectionFromA == true and 1 or 2
				end
			end
			--d("close enough, flying")
			return true
		end
	elseif (Player.diving.isdiving) then
		--d("diving goaldist 3d:"..tostring(goaldist).. " < = "..tostring(ml_navigation.NavPointReachedDistances["3ddive"]).." and 2d:" ..tostring(goaldist2d).." < = " ..tostring(ml_navigation.NavPointReachedDistances["2ddive"]))
		if (goaldist <= ml_navigation.NavPointReachedDistances["3ddive"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2ddive"]) then
			self:ResetOMCHandler()
			if ( nc and In(ncsubtype,1,2,3,4)) then				
				self.omc_id = nc.id
				self.omc_details = nc
				if(ncdirectionFromA~=nil) then
					self.omc_direction = ncdirectionFromA == true and 1 or 2
				end
			end
			return true
		end
	elseif (Player.diving.isswimming) then
		--d("swimming goaldist 3d:"..tostring(goaldist).. " < = "..tostring(ml_navigation.NavPointReachedDistances["3dswim"]).." and 2d:" ..tostring(goaldist2d).." < = " ..tostring(ml_navigation.NavPointReachedDistances["2dswim"]))
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dswim"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dswim"]) then
			self:ResetOMCHandler()
			if ( nc and In(ncsubtype,1,2,3,4)) then				
				self.omc_id = nc.id
				self.omc_details = nc
				if(ncdirectionFromA~=nil) then
					self.omc_direction = ncdirectionFromA == true and 1 or 2
				end
			end
			return true
		end
	elseif (Player.ismounted) then
		--d("goaldist "..tostring(goaldist).. " < = "..tostring(ml_navigation.NavPointReachedDistances["3dmount"]).." and " ..tostring(goaldist2d).." < = " ..tostring(ml_navigation.NavPointReachedDistances["2dmount"]))
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dmount"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dmount"]) then
			self:ResetOMCHandler()
			if ( nc and In(ncsubtype,1,2,3,4)) then	
				self.omc_id = nc.id
				self.omc_details = nc
				if(ncdirectionFromA~=nil) then
					self.omc_direction = ncdirectionFromA == true and 1 or 2
				end
			end
			--d("close enough, mounted")
			return true
		end
	else
		--d("goaldist "..tostring(goaldist).. " < = "..tostring(ml_navigation.NavPointReachedDistances["3dwalk"]).." and " ..tostring(goaldist2d).." < = " ..tostring(ml_navigation.NavPointReachedDistances["2dwalk"]))
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dwalk"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
			self:ResetOMCHandler()
			if ( nc and In(ncsubtype,1,2,3,4)) then	
				self.omc_id = nc.id
				self.omc_details = nc
				if(ncdirectionFromA~=nil) then
					self.omc_direction = ncdirectionFromA == true and 1 or 2
				end
			end
			--d("close enough, walking")
			return true
		end
	end
	self.omc_direction = 0
	return false
end

-- Are there more flying nodes so we can continue flying instead of landing uselessly?
function ml_navigation:CanContinueFlying()
	if (table.valid(self.path)) then
		local pathsize = table.size(self.path)
		for index,node in pairsByKeys(self.path) do
			if (index > self.pathindex and (node.type == GLOBAL.NODETYPE.CUBE) and (node.flags and bit.band(node.flags, GLOBAL.CUBE.AIR) ~= 0)) then
				local dist = math.distance3d(Player.pos,ml_navigation.targetposition)
				if (dist > 15) then
					return true
				end
			end
		end
	end
	return false
end

-- Get connection details for a specific node, maybe with some helper tagging.
function ml_navigation:GetConnection(node)
	local navcon
	if (node.navconnectionid and node.navconnectionid ~= 0) then
		-- 'live nav' vs 'new nav'
		if (NavigationManager.ShowCells == nil ) then		
			navcon = ml_mesh_mgr.navconnections[node.navconnectionid]
		else
			navcon = NavigationManager:GetNavConnection(node.navconnectionid)
		end
	end
	
	-- type = 0: disabled, 1: cube-cube, 2: floor-floor, 3: floor-cube, 4: custom omc, 5: macromesh
	-- subtype = 1: jump, 2: walk, 3: teleport, 4: interact, 5: portal, 6: custom code
	
	return navcon
end

-- Are we using a connection?
function ml_navigation:IsUsingConnection()
	local lastnode = self.path[self.pathindex - 1]
	if (table.valid(lastnode)) then
		local nc
		if (lastnode.navconnectionid ~= 0) then			
			-- 'live nav' vs 'new nav'
			if (NavigationManager.ShowCells == nil ) then			
				if (table.valid(ml_mesh_mgr.navconnections)) then
					nc = ml_mesh_mgr.navconnections[lastnode.navconnectionid]
				end
			else
				nc = NavigationManager:GetNavConnection(lastnode.navconnectionid)
			end
				-- Type 1 is cube-cube, this is needed bcause there's a loading transition when going from diving->water or vice versa.
			if ( nc and nc.type == 1 ) then
				return true
			end			
		end
	end
	return false
end

function ml_navigation:CheckPath(pos2,floorfilters,cubefilters)
	local pos = Player.pos
	if (not table.valid(pos2)) then
		return false
	end
	
	local floorfilters = IsNull(floorfilters,0,true)
	local cubefilters = IsNull(cubefilters,0,true)
	
	if (not IsFlying() and not IsDiving() and ((Player.incombat and (not Player.ismounted or not Player.mountcanfly)) or IsTransporting())) then
		cubefilters = bit.bor(cubefilters, GLOBAL.CUBE.AIR)
	end
	NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.CUBE, cubefilters)
	NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.FLOOR, floorfilters)
	
	local reachable = NavigationManager:IsReachable(pos2)
	if (not reachable) then
		local transportFunction = _G["Transport"..tostring(Player.localmapid)]
		if (transportFunction ~= nil and type(transportFunction) == "function") then
			local retval = transportFunction(pos,pos2)
			if (retval == true) then
				reachable = true
			end
		end
	end
	
	return reachable
end

-- MoveTo will now only build a path if one does not exist or the one it wants to use is not compatible.
-- Ideally, BuildPath should be called before this but there maybe legacy situations/tasks not updated where we don't want to just break them.
-- Added misc debug codes to more easily help identify debug messages.
-- Added targetid since that is totally needed for any moving enemy, espeically in pvp. Else the bot likes to move backwards the path he came from, due to cached paths.
function Player:MoveTo(x, y, z, dist, floorfilters, cubefilters, targetid)	
	local floorfilters = IsNull(floorfilters,0,true)
	local cubefilters = IsNull(cubefilters,0,true)
	
	if (MPlayerDriving()) then
		d("[NAVIGATION]: Releasing control to Player..")
		ml_navigation:ResetCurrentPath()
		return -1337
	end
	
	local ret = Player:BuildPath(x, y, z, floorfilters, cubefilters, targetid)	
	if (ml_navigation:HasPath()) then
		if (ml_navigation:EnablePathing()) then
			--d("[NAVIGATION: Started pathing [MOVETO3].")
		end
	else
		if (ml_navigation:DisablePathing()) then
			--d("[NAVIGATION: Stopped pathing, path not valid [MOVETO4].")			
		end
	end
	return ret
end

ml_navigation.lastPathUpdate = 0
ml_navigation.pathchanged = false
function Player:BuildPath(x, y, z, floorfilters, cubefilters, targetid)
	ml_navigation.debug = nil -- this is just for being able to click "Get Path to target" in the navmanager, so you see the current path and can check  the nodes / manually optimize that path without actually start flying
	local floorfilters = IsNull(floorfilters,0,true)
	local cubefilters = IsNull(cubefilters,0,true)
	if (targetid == 0) then
		targetid = nil
	end

	if (MPlayerDriving()) then
		d("[NAVIGATION]: Releasing control to Player..")
		ml_navigation:ResetCurrentPath()
		return -1337
	end
	
	if (x == nil or y == nil or z == nil ) then -- yes this happens regularly inside fates, because some of the puzzle code calls moveto nil/nil/nil
		d("[NAVIGATION]: Invalid Move To Position :["..tostring(x)..","..tostring(y)..","..tostring(z).."]")
		return 0
	end
	
	local ppos = Player.pos	
	local newGoal = { x = x, y = y, z = z }
	
	local hasCurrentPath = table.valid(ml_navigation.path)
	local currentPathSize = table.size(ml_navigation.path)
	
	local sametarget = ml_navigation.lasttargetid and targetid and ml_navigation.lasttargetid == targetid -- needed, so it doesnt constantly pull a new path n doing a spinny dance on the navcon startpoint when following a moving target 
	local hasPreviousPath = hasCurrentPath and table.valid(newGoal) and table.valid(ml_navigation.targetposition) and ( (not sametarget and math.distance3d(newGoal,ml_navigation.targetposition) < 1) or sametarget )
	--if (hasPreviousPath and (ml_navigation.lastconnectionid ~= 0 or ffnav.isascending or ffnav.isdescending or TimeSince(ml_navigation.lastPathUpdate) < 2000)) then
	if (hasPreviousPath and (ml_navigation.lastconnectionid ~= 0 or ffnav.isascending or ffnav.isdescending)) then
		d("[NAVIGATION]: We are currently using a Navconnection / ascending / descending, wait until we finish to pull a new path.")
		return currentPathSize
	end
	
	-- Filter things for special tasks/circumstances
	if ((not IsFlying() and not IsDiving() and ((Player.incombat and (not Player.ismounted or not Player.mountcanfly)) or IsTransporting())) or 
		not CanFlyInZone() or (Player.ismounted and ml_task_hub:CurrentTask() and ml_task_hub:CurrentTask().remainMounted and not Player.mountcanfly))
	then
		cubefilters = bit.bor(cubefilters, GLOBAL.CUBE.AIR)
	end
	if (not CanDiveInZone()) then
		cubefilters = bit.bor(cubefilters, GLOBAL.CUBE.WATER)
	end
	
	-- Unfilter things that we need or nav will complain and do nothing
	if (IsDiving() and bit.band(cubefilters, GLOBAL.CUBE.WATER) ~= 0) then
		cubefilters = bit.bxor(cubefilters, GLOBAL.CUBE.WATER)
	elseif (IsFlying() and bit.band(cubefilters, GLOBAL.CUBE.AIR) ~= 0) then
		cubefilters = bit.bxor(cubefilters, GLOBAL.CUBE.AIR)
	end
	
	NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.CUBE, cubefilters)
	NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.FLOOR, floorfilters)
	
	local ret = ml_navigation:MoveTo(newGoal.x,newGoal.y,newGoal.z, targetid)
	ml_navigation.lastPathUpdate = Now()
	
	if (ret <= 0) then
		if ((IsFlying() or IsDiving()) and hasPreviousPath) then
			d("[NAVIGATION]: Encountered an issue on path pull, using previous path, errors may be encountered here.")
			return currentPathSize
		else
			ml_navigation:ResetCurrentPath()
		end
		ml_navigation.targetposition = { x=0, y=0, z=0 }
		ml_navigation.lasttargetid = nil
		
	else
		ml_navigation.targetposition = newGoal
		ml_navigation.lasttargetid = targetid	
	end
	
	if (ret > 0 and hasCurrentPath) then
		for _,node in pairs(ml_navigation.path) do
			ml_navigation.TagNode(node)
		end
	end
	
	--table.print(ml_navigation.path)
	return ret
end

-- Overriding  the (old) c++ Player:Stop(), to handle the additionally needed navigation functions
function Player:Stop(resetpath)
	--local resetpath = IsNull(resetpath,true)
	-- Resetting the path can cause some problems with macro nodes.
	-- On occassion it will enter a circular loop if something in the path calls a stop (like mounting).
	
	ffnav.isascending = false
	ffnav.isdescending = false	
	ml_navigation.lastconnectionid = 0
	ml_navigation.lasttargetid = nil
	NavigationManager:ResetPath()
	ml_navigation:ResetCurrentPath()
	ml_navigation.receivedInstructions = {}
	ml_navigation:ResetOMCHandler()
	ml_navigation.canPath = false
	ffnav.yield = {}
	ffnav.process = {}
	Player:StopMovement()	-- The "new" c++ sided STOP which stops the player's movement completely
end

-- This should be used instead of Stop() if the path and all of it's info should remain and we are only stopping to perform a task en-route (like mounting).
-- This ensures that the navigation pathfinder doesn't do a loopback incase a macro node is a bit off course.
function Player:PauseMovement(param1, param2, param3, param4, param5)
	local param1 = IsNull(param1, 1500)
	local param2 = IsNull(param2, function () return not Player:IsMoving() end)
	
	ml_navigation.canPath = false
	Player:StopMovement()
	
	ffnav.Await(param1, param2, param3, param4, param5)
end

function ml_navigation.IsHandlingInstructions(tickcount)
	if (MPlayerDriving()) then
		ml_navigation.receivedInstructions = {}
	end
	
	if (ValidTable(ml_navigation.receivedInstructions)) then
		--d("Running instruction set.")
		if (Now() > ml_navigation.instructionThrottle) then
			ffxivminion.UpdateGlobals()
			
			local newInstruction = ml_navigation.receivedInstructions[1]
			if (newInstruction and type(newInstruction) == "function") then
				local retval = newInstruction()
				if (retval == true) then
					table.remove(ml_navigation.receivedInstructions,1)
					--d("[NAVIGATION]: ["..tostring(table.size( ml_navigation.receivedInstructions)).."] more instructions left to process.")
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
		if (ml_navigation.omc_id ~= nil) then
			return true
		end
	end
	return false
end

function ml_navigation.TagNode(node)
	if (table.valid(node) and not node.is_tagged) then
		node.is_start = (bit.band(node.type2, 1) ~= 0)
		node.is_end = (bit.band(node.type2, 2) ~= 0)
		node.is_omc = (bit.band(node.type2, 4) ~= 0)
		
		node.is_floor = (node.type == GLOBAL.NODETYPE.FLOOR)
		node.is_cube = (node.type == GLOBAL.NODETYPE.CUBE)
		
		local flags = node.flags
		
		node.ground, node.ground_water, node.ground_border, node.ground_avoid, node.air, node.water, node.air_avoid = false, false, false, false, false, false, false
		if (node.is_floor) then
			--node.ground = (bit.band(flags, GLOBAL.FLOOR.GROUND) ~= 0)  -- doesn't work, due to flags sometimes returning 0, needs c++ fix
			node.ground = (bit.band(flags, GLOBAL.FLOOR.GROUND) ~= 0 or (flags == 0 and (not node.is_start or not IsFlying())))
			node.ground_water = (bit.band(flags, GLOBAL.FLOOR.WATER) ~= 0)
			node.ground_border = (bit.band(flags, GLOBAL.FLOOR.BORDER) ~= 0)
			node.ground_avoid = (bit.band(flags, GLOBAL.FLOOR.AVOID) ~= 0)
		elseif (node.is_cube) then
			--node.air = (bit.band(flags, GLOBAL.CUBE.AIR) ~= 0)   -- doesn't work, due to flags sometimes returning 0, needs c++ fix
			node.air = (bit.band(flags, GLOBAL.CUBE.AIR) ~= 0 or flags == 0)
			node.water = (bit.band(flags, GLOBAL.CUBE.WATER) ~= 0)
			node.air_avoid = (bit.band(flags, GLOBAL.CUBE.AVOID) ~= 0)
		end
		node.is_tagged = true
	end
end

-- Handles the actual Navigation along the current Path. Is not supposed to be called manually! 
-- Also handles OMCs
ml_navigation.lastconnectionid = 0
ml_navigation.lasttargetid = nil
ml_navigation.path = {}
ml_navigation.pathindex = 0
ml_navigation.lastindexgoal = {}
function ml_navigation.Navigate(event, ticks )	
	local self = ml_navigation
	if ((ticks - (ml_navigation.lastupdate or 0)) > 50) then 
		ml_navigation.lastupdate = ticks
				
		if ( ml_navigation.CanRun() and ml_navigation.canPath and not ml_navigation.debug) then	
		
			local ppos = Player.pos
			
			ml_navigation.GUI = {
				pathHops = 0,
				currentIndex = 0,
				nextNodeDistance = 0,
				lastAction = "",
			}
			
			-- Normal Navigation Mode			
			if (not ffnav.IsProcessing()) then
						
								
				ml_navigation.pathindex = NavigationManager.NavPathNode
								
				if ( table.valid(ml_navigation.path) and ml_navigation.path[ml_navigation.pathindex] ~= nil) then
				
					ml_global_information.GetMovementInfo(true) -- force standard movement for nav
					
					if (not ml_navigation:IsUsingConnection()  and TimeSince(ml_navigation.lastPathUpdate) >= 2000) then
						Player:BuildPath(ml_navigation.targetposition.x, ml_navigation.targetposition.y, ml_navigation.targetposition.z, NavigationManager:GetExcludeFilter(GLOBAL.NODETYPE.FLOOR), NavigationManager:GetExcludeFilter(GLOBAL.NODETYPE.CUBE), ml_navigation.lasttargetid)
						ml_navigation.lastPathUpdate = Now()
						return -- needed here, or you can check again for navpath / index valid ...your choice
					end
					
					local adjustedHeading = ml_navigation.CheckObstacles()
					if (adjustedHeading ~= 0) then
						d("[Navigation]: Found an obstacle, adjust heading to ["..tostring(adjustedHeading).."].")
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
				
					local nextnode = ml_navigation.path[ml_navigation.pathindex]
					local nextnextnode = ml_navigation.path[ml_navigation.pathindex + 1]
					
					ml_navigation.TagNode(nextnode)
					ml_navigation.TagNode(nextnextnode)
					
					ml_navigation.GUI.pathHops = table.size(ml_navigation.path)
					ml_navigation.GUI.currentIndex = ml_navigation.pathindex			
					ml_navigation.GUI.nextNodeDistance = math.distance3d(ppos,nextnode)
					
			-- Ensure Position: Takes a second to make sure the player is really stopped at the wanted position (used for precise NavConnection bunnyhopping and others where the player REALLY has to be on the start point & facing correctly)
					if (adjustedHeading == 0 and table.valid (ml_navigation.ensureposition) and (ml_navigation:EnsurePosition(ppos) )) then
						return
					end
					
					
					
					local nc = self.omc_details
					if ( self.omc_id ) then
						-- Our current 'nextnode' is the END of the NavConnection !!
						-- Find out which side of the NavCon we are at
						-- Figure out the OMC direction, one time, reset by ResetOMCHandler.
						local from_pos
						local to_pos
						if (self.omc_direction == 0) then
							if (math.distance3d(ppos, nc.sideA) < math.distance3d(ppos, nc.sideB)) then
								self.omc_direction = 1
							else
								self.omc_direction = 2
							end
						end
						
						local ncradius
						local ncsubtype
						local from_heading
						if(nc.sideA ~= nil) then
							if (self.omc_direction == 1) then -- From sideA to  side B
								from_pos = nc.sideA
								to_pos = nc.sideB
								ncradius = nc.sideA.radius
								from_heading = nc.details.headingA_x
							else
								from_pos = nc.sideB
								to_pos = nc.sideA
								ncradius = nc.sideB.radius
								from_heading = nc.details.headingB_x
							end
							ncsubtype = nc.details.subtype
						else
							if (self.omc_direction == 1) then
								from_pos = nc.from
								to_pos = nc.to
							else
								from_pos = nc.to
								to_pos = nc.from
							end
							ncradius = nc.radius
							ncsubtype = nc.subtype
						end
						
						if (not MIsLocked()) then
							if (ml_navigation.omc_traveltimer == nil) then
								ml_navigation.omc_traveltimer = ticks
							end
							
							local timepassed = ticks - ml_navigation.omc_traveltimer
							if ( timepassed < 3000) then 
								local dist = math.distance3d(ppos,nextnode)
								if ( timepassed > 2000 and ml_navigation.omc_traveldist > dist) then
									ml_navigation.omc_traveldist = dist
									ml_navigation.omc_traveltimer = ticks
								end
							else
								d("[Navigation] - Not getting closer to NavConnection END node. We are most likely stuck.")
								ml_navigation.StopMovement()
								return
							end
						end
							
						-- Max Timer Check in case something unexpected happened
						if ( ml_navigation.omc_starttimer ~= 0 and ticks - ml_navigation.omc_starttimer > 10000 ) then
							d("[Navigation] - Could not read NavConnection END in ~10 seconds, something went wrong..")
							ml_navigation.StopMovement()
							return							
						end
								
						-- NavConnection JUMP
						if ( ncsubtype == 1 ) then
							
							ml_navigation.GUI.lastAction = "Jump NavConnection"
																					
							-- Before the jump
								if ( not ml_navigation.omc_startheight ) then
									-- Adjust facing
									if ( ncradius <= 0.5  ) then											
										if ( ml_navigation:SetEnsureStartPosition(from_pos, ppos, nc, from_pos, to_pos, from_heading) ) then											
											return
										end
									else
										local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = to_pos.x-ppos.x, y = 0, z = to_pos.z-ppos.z})
										if ( anglediff > 0.3 ) then
											Player:SetFacing(to_pos.x,to_pos.y,to_pos.z)
										end
									end
									
									if ( ml_navigation.omc_starttimer == 0 ) then
										ml_navigation.omc_starttimer = ticks	
										if (not Player:IsMoving()) then
											Player:Move(FFXIV.MOVEMENT.FORWARD)											
											ffnav.Await(1000, function () return Player:IsMoving() end)
										end
									elseif ( Player:IsMoving() and ticks - ml_navigation.omc_starttimer > 100 ) then	
										ml_navigation.omc_startheight = ppos.y										
		                                Player:Jump()
										d("[Navigation]: Starting to Jump for NavConnection.")
									end
									
									
								else
									local todist,todist2d = ml_navigation:GetRaycast_Player_Node_Distance(ppos,to_pos)
									--d("[Navigation]: Jumping towards Targetpos, Dist2d:"..tostring(todist2d).." - " ..tostring(ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()]))
									if ( todist2d <= ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()]) then
										-- We reached our target node...
										
										if ( ncradius <= 0.5 ) then
											-- let's cheat for precission :D											
											if (Player:IsMoving() or Player:IsJumping() ) then
												Player:StopMovement()
												ffnav.Await(1000, function () return not Player:IsMoving() and not Player:IsJumping() end)
												return
											else
												Hacks:TeleportToXYZ(to_pos.x, to_pos.y, to_pos.z)
												ml_navigation.lastupdate = ml_navigation.lastupdate + math.random(500,1500)
												if (nextnextnode) then
													Player:SetFacing(nextnextnode.x,nextnextnode.y,nextnextnode.z)
												end
												ml_navigation.pathindex = ml_navigation.pathindex + 1
												NavigationManager.NavPathNode = ml_navigation.pathindex
												ml_navigation:ResetOMCHandler()												
												d("[Navigation]: [Jumping] - Landed at End of Navconnection.")
											end
										else
											Player:StopMovement()
											if (nextnextnode) then
												Player:SetFacing(nextnextnode.x,nextnextnode.y,nextnextnode.z)
											end
											ml_navigation.pathindex = ml_navigation.pathindex + 1
											NavigationManager.NavPathNode = ml_navigation.pathindex
											ml_navigation:ResetOMCHandler()	
											d("[Navigation]: [Jumping] - Landed at End of Navconnection.")
										end
																														
									else
										-- if we felt below start and landing pos, we will never make it to the goal anyway now
										if ( from_pos.y > (ppos.y + 1)  and to_pos.y > (ppos.y + 1) ) then
											if ( ncradius <= 0.5 ) then
												-- let's cheat for precission :D											
												if (Player:IsMoving() or Player:IsJumping() ) then
													Player:StopMovement()
													ffnav.Await(1000, function () return not Player:IsMoving() and not Player:IsJumping() end)
													return
												else
													Hacks:TeleportToXYZ(to_pos.x, to_pos.y, to_pos.z)
													ml_navigation.lastupdate = ml_navigation.lastupdate + math.random(500,1500)
													if (nextnextnode) then
														Player:SetFacing(nextnextnode.x,nextnextnode.y,nextnextnode.z)
													end
													ml_navigation.pathindex = ml_navigation.pathindex + 1
													NavigationManager.NavPathNode = ml_navigation.pathindex
													ml_navigation:ResetOMCHandler()
													d("[Navigation]: [Jumping] - Landed at End of Navconnection.")
												end
											else
												d("[Navigation]: [Jumping] - Failed to Reach End of Navconnection.")
												Player:Stop()
												
											end
											
										else
										
											Player:Move(FFXIV.MOVEMENT.FORWARD)
											Player:SetFacing(to_pos.x,to_pos.y,to_pos.z)
										end
									end
								end
							return
						end
						
						-- OMC Walk								
						if ( ncsubtype == 2 ) then
							if (ml_navigation.omc_starttimer == 0 ) then
								ml_navigation.omc_starttimer = ticks
							end
							ml_navigation.GUI.lastAction = "Walk NavConnection"
							ml_navigation:NavigateToNode(ppos,nextnode,1000)
							return
						end
						
						-- OMC Teleport						
						if ( ncsubtype == 3 ) then							
							ml_navigation.GUI.lastAction = "Teleport NavConnection"
							if (Player:IsMoving() or Player:IsJumping() ) then
								Player:StopMovement()
								Player:SetFacing(to_pos.x,to_pos.y,to_pos.z)
								ffnav.Await(1000, function () return not Player:IsMoving() and not Player:IsJumping() end)
								return
							else							
								Hacks:TeleportToXYZ(to_pos.x, to_pos.y, to_pos.z)
								if (nextnextnode) then
									Player:SetFacing(nextnextnode.x,nextnextnode.y,nextnextnode.z)
								end
								ml_navigation.lastupdate = ml_navigation.lastupdate + math.random(500,1500)
								d(GetTickCount())
								--ffxiv_dialog_manager.IssueStopNotice("Teleport NavConnection","Teleport NavConnection exist on this mesh.\nPlease enable the Teleport (Hack) usage in Advanced Settings or remove them.")
							end
							ml_navigation.pathindex = ml_navigation.pathindex + 1
							NavigationManager.NavPathNode = ml_navigation.pathindex	
							ml_navigation:ResetOMCHandler()							
							return
						end
						
						-- OMC Interact	
						if ( ncsubtype == 4 ) then
							-- OMC Interact  I AM SO UNSURE IF THAT IS WORKING OR EVEN USED ANYMORE :D:D:D:D
							ml_navigation.GUI.lastAction = "Interact NavConnection"
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
								NavigationManager.NavPathNode = ml_navigation.pathindex
								ml_navigation:ResetOMCHandler()
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
							local todist,todist2d = ml_navigation:GetRaycast_Player_Node_Distance(ppos,nextnode)
							if ( todist <= ml_navigation.NavPointReachedDistances["3dwalk"] and todist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
								d("[Navigation] - OMC_END - Interact Node reached")
								ml_navigation.pathindex = ml_navigation.pathindex + 1			
								NavigationManager.NavPathNode = ml_navigation.pathindex	
								ml_navigation:ResetOMCHandler()								
							end
							
							-- Find a target to interact with
							local interactnpc
							local elist = MEntityList("nearest,targetable,type=7,chartype=0,maxdistance=5")								
							if ( table.valid(elist)) then interactnpc = select(2,next(elist)) end
							
							if ( not interactnpc ) then 
								elist = MEntityList("nearest,targetable,type=3,chartype=0,maxdistance=5")								
								if ( table.valid(elist)) then interactnpc = select(2,next(elist)) end
							end
							
							if ( not interactnpc ) then 
								elist = MEntityList("nearest,targetable,maxdistance=7")								
								if ( table.valid(elist)) then interactnpc = select(2,next(elist)) end
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
							return
						end
						
						-- OMC Portal
						if ( ncsubtype == 5 ) then
							
							ml_navigation.GUI.lastAction = "Portal OMC"
							ml_navigation:NavigateToNode(ppos,nextnode,2000)
							return
						end
						
						-- OMC Custom
						if ( ncsubtype == 6 ) then
							
							ml_navigation.GUI.lastAction = "Custom OMC"
							ml_navigation:NavigateToNode(ppos,nextnode,1500)	
							return							
						end
					end
					
					if (MIsLocked()) then
						return
					end
					
			-- Cube Navigation
					if (IsDiving()) then
						--d("[Navigation]: Underwater navigation.")
						
						local target = Player:GetTarget()						
						if (target and target.los and target.distance2d < 15) then
							if (target.interactable) and (target.distance < 2.5) then
								Player:Stop()
								return false
							end

							-- If we're close, we need to just fly directly.  The cubes make it an impossible task to try to do this via the actual path.
							local tpos = target.pos
							local dist3D = math.distance3d(tpos,ppos)
							
							if (adjustedHeading ~= 0) then
								Player:SetFacing(adjustedHeading)
							else
								local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = tpos.x-ppos.x, y = 0, z = tpos.z-ppos.z})
								if ( anglediff < 35 and dist3D > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
									Player:SetFacing(tpos.x,tpos.y,tpos.z, true) -- smooth facing
								else
									Player:SetFacing(tpos.x,tpos.y,tpos.z)
								end
							end
							
							local modifiedNode = { type = nextnode.type, type2 = nextnode.type2, flags = nextnode.flags, x = tpos.x, y = (tpos.y - 2), z = tpos.z }
							-- modifying position down helps mostly here, but do a quick raycheck to make sure we aren't hitting a low obstacle
							local hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y,ppos.z,modifiedNode.x,modifiedNode.y,modifiedNode.z)
							if (hit) then
								modifiedNode = { type = nextnode.type, type2 = nextnode.type2, flags = nextnode.flags, x = tpos.x, y = tpos.y, z = tpos.z }
							end
							
							-- Set Pitch							
							local currentPitch = math.round(Player.flying.pitch,3)
							local minVector = math.normalize(math.vectorize(ppos,modifiedNode))
							local pitch = math.asin(-1 * minVector.y)
							Player:SetPitch(pitch)
							
							-- Move
							if (not Player:IsMoving()) then
								Player:Move(FFXIV.MOVEMENT.FORWARD)	
								ffnav.Await(150, function () return Player:IsMoving() end)
							end
						else
							ml_navigation.GUI.lastAction = "Swimming underwater to Node"
							-- Check if we left our path
							if (not ml_navigation:IsStillOnPath(ppos,"3ddive")) then 
								--d("we have left the path")
								return 
							end
															
							-- Check if the next node is reached:
							local dist3D = math.distance3d(nextnode,ppos)
							if ( ml_navigation:IsGoalClose(ppos,nextnode)) then
								-- We reached the node
								--d("[Navigation] - Cube Node reached. ("..tostring(math.round(dist3D,2)).." < "..tostring(ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()])..")")	
								
								-- C++ is already optimizing / shortening the path wherever possible. You tried to do here the same thing with just one recast, where c++ has full access to cube n recast data and uses about 6 raycasts around the player object.
								-- C++ can suck it, lua4eva
								
								--[[local originalIndex = ml_navigation.pathindex + 1
								
								local newIndex = originalIndex
								if (FFXIV_Common_SmoothPathing and ml_navigation.lastconnectionid == 0 and nextnode.navconnectionid == 0) then
									for i = ml_navigation.pathindex + 2, ml_navigation.pathindex + 10 do
										local node = ml_navigation.path[i]
										if (node) then
											local nc = ml_navigation:GetConnection(node)
											if (not nc or not In(nc.type,0,5)) then
												local dist3d = math.distance3d(node,ppos)
												if (dist3d < 100 and (node.type == GLOBAL.NODETYPE.CUBE) and node.flags and bit.band(node.flags, GLOBAL.CUBE.WATER) ~= 0) then
													local hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y,ppos.z,node.x,node.y,node.z)
													if (not hit) then
														--d("Bumped index to [" .. i .. "]")
														newIndex = i
													end
												end
											end
										end
									end
									if (newIndex > originalIndex) then
										--d("Need to compact path.")
										for i = ml_navigation.pathindex + 2, ml_navigation.pathindex + 10 do
											if (newIndex > i) then
												 ml_navigation.path[i] = nil
												 --d("Removing skipped node [" .. i .. "] from path.")
											end
										end
										ffnav.CompactPath()
									end
								end
								
								ml_navigation.lastconnectionid = nextnode.navconnectionid
								ml_navigation.pathindex = originalIndex	
								NavigationManager.NavPathNode = ml_navigation.pathindex
								]]
								
								ml_navigation.lastconnectionid = nextnode.navconnectionid
								ml_navigation.pathindex = ml_navigation.pathindex + 1
								NavigationManager.NavPathNode = ml_navigation.pathindex
								
								
							else			
								--d("[Navigation]: Moving to next node")
								-- We have not yet reached our node
								-- Face next node
								if (adjustedHeading ~= 0) then
									Player:SetFacing(adjustedHeading)
								else
									local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})
									if ( anglediff < 35 and dist3D > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
										Player:SetFacing(nextnode.x,nextnode.y,nextnode.z, true) -- smooth facing
									else
										Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
									end
								end
								
								local modifiedNode = { type = nextnode.type, type2 = nextnode.type2, flags = nextnode.flags, x = nextnode.x, y = (nextnode.y - 2), z = nextnode.z }
								-- modifying position down helps mostly here, but do a quick raycheck to make sure we aren't hitting a low obstacle
								local hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y,ppos.z,modifiedNode.x,modifiedNode.y,modifiedNode.z)
								if (hit) then
									modifiedNode = nextnode
								end
								
								-- Set Pitch							
								local currentPitch = math.round(Player.flying.pitch,3)
								local minVector = math.normalize(math.vectorize(ppos,modifiedNode))
								local pitch = math.asin(-1 * minVector.y)
								Player:SetPitch(pitch)
								
								-- Move
								if (not Player:IsMoving()) then
									Player:Move(FFXIV.MOVEMENT.FORWARD)	
									ffnav.Await(150, function () return Player:IsMoving() end)
								end
							end
						end
					end
						
			-- Cube Navigation		
					if (IsFlying()) then -- we are in the air or our last node which was reached was a cube node, now continuing to the next node which can be either CUBE or POLY node
						--d("[Navigation]: Flying navigation.")
						
						ml_navigation.GUI.lastAction = "Flying to Node"
						-- Check if we left our path
						if (not ml_navigation:IsStillOnPath(ppos,"3dfly")) then return end
														
						-- Check if the next node is reached:
						local dist2D = math.distance2d(nextnode,ppos)
						local dist3D = math.distance3d(nextnode,ppos)
						
						--ml_debug("[Navigation]: Moving to next node")
						-- We have not yet reached our node
						-- Face next node
						if (adjustedHeading ~= 0) then
							Player:SetFacing(adjustedHeading)
						else
							local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})
							if ( anglediff < 35 and dist3D > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
								Player:SetFacing(nextnode.x,nextnode.y,nextnode.z, true) -- smooth facing
							else
								Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
							end
						end
						
						local targetnode = shallowcopy(nextnode)
						if (not nextnode.is_cube and ml_navigation:CanContinueFlying()) then
							targetnode.y = targetnode.y + 1.5
						end
						
						local pitch = GetRequiredPitch(targetnode)
						Player:SetPitch(pitch)
						
						-- Move
						if (not Player:IsMoving()) then
							Player:Move(FFXIV.MOVEMENT.FORWARD)	
							ffnav.Await(2000, function () return Player:IsMoving() end)
						end
						
						if ( ml_navigation:IsGoalClose(ppos,nextnode)) then																					
							local canLand = true
							local hit, hitx, hity, hitz = RayCast(nextnode.x,nextnode.y+1,nextnode.z,nextnode.x,nextnode.y-.5,nextnode.z)
							if (not hit) then
								canLand = false
							end	
							if (not canLand) then
								if (nextnode.is_end and nextnode.ground and dist2D < 2 and dist3D < 4) then
									canLand = true
								end
							end
					
							if (canLand and not nextnode.is_cube and nextnode.ground and (nextnode.is_end or not ml_navigation:CanContinueFlying())) then
								
								Descend(true)
								return false
							end

							-- We landed now and can continue our path..
							ml_navigation.lastconnectionid = nextnode.navconnectionid		
							ml_navigation.pathindex = ml_navigation.pathindex + 1
							NavigationManager.NavPathNode = ml_navigation.pathindex	
						end
		-- Normal Navigation
					end
					
					if (not IsFlying() and not IsDiving()) then
						ffnav.isascending = false
						ffnav.isdescending = false
						
						--d("[Navigation]: Normal navigation..")
						local navcon = ml_navigation:GetConnection(nextnode)
						local isCubeCon = (navcon and navcon.type == 3 and ml_navigation:IsGoalClose(ppos,nextnode))
						if (nextnode.type == GLOBAL.NODETYPE.CUBE or isCubeCon) then -- next node is a cube node OR is a navconnection floor/cube and we reached nextnode
						
							--d("isCubeCon:"..tostring(isCubeCon))
							-- We reached the nextnode that hodls a navconnection, here we want to always iterate our path so path[1] holds the navconnection
							if ( navcon ) then
								ml_navigation.lastconnectionid = nextnode.navconnectionid
							end
							
							ml_navigation.GUI.lastAction = "Walk to Cube Node"
							
							if ((IsSwimming() or nextnode.water) and nextnode.y < ppos.y) then	-- We need to differ between the player standing ontop of the water and wanting to dive and the player standing on the seafloor and wanting to ascend to water cubes above
								if (IsSwimming()) then
									d("[Navigation] - Dive into water (swimming), using connection ["..tostring(isCubeCon).."].")
								else
									d("[Navigation] - Dive into water (node position), using connection ["..tostring(isCubeCon).."].")
								end

								ffnav.isdescending = isCubeCon
								if (Player:IsMoving()) then
									Player:StopMovement()
									return false
								end
								Dive()
								return
								
							elseif (nextnode.water or (navcon and navcon.type == 3 and (nextnextnode and nextnextnode.water))) then
								
								-- For connecting to the weird tunnel exists in underwater towns.
								ml_navigation:NavigateToNode(ppos,nextnode)	
								return
								
							elseif (not IsFlying() and CanFlyInZone()) then
								if (Player.ismounted and not Player.mountcanfly and (nextnode.air or nextnode.air_avoid)) then
									d("[Navigation] - Our mount cannot fly, dismount it.")
									Dismount()
									return
									
								elseif (not Player.ismounted) then
									d("[Navigation] - Mount for flight.")
									if (Player:IsMoving()) then
										Player:StopMovement()
										ffnav.AwaitDo(3000, function () return not Player:IsMoving() end, function () Player:StopMovement() end)
										ml_global_information.Await(10000, function () return not ffnav.IsYielding() end)
										return -- need to return here, else  NavigateToNode below continues to move it ;)
										
									else
										if (Mount()) then
											ffnav.AwaitSuccess(500, 
												function () 
													return (IsMounting() or UsingBattleItem())
												end,
												function ()
													ffnav.Await(3000, function () return Player.ismounted end)
												end
											)
											ml_global_information.Await(10000, function () return not ffnav.IsYielding() end)
										end
										return
									end
									
								else
									if (Player:IsMoving()) then
										Player:StopMovement()
										ffnav.AwaitDo(3000, function () return not Player:IsMoving() end, function () Player:StopMovement() end)
										return -- need to return here, else  NavigateToNode below continues to move it ;)
										
									else
										d("[Navigation] - Ascend for flight, using connection ["..tostring(isCubeCon).."].")
										ffnav.isascending = isCubeCon 
										Player:Jump()
										ffnav.AwaitSuccess(500, 2000, function () 
											local ascended = Player:IsJumping() or IsFlying()
											if (ffnav.isascending and ascended) then-- we are using a navconnection , therefore have to iterate the currentindex to the navconnection end-cube-node. If the next node is 'only' a cube instead, we don't iterate, we ascend and move towards it where then the index is iterated
												ffnav.isascending = false
												ml_navigation.pathindex = ml_navigation.pathindex + 1
												NavigationManager.NavPathNode = ml_navigation.pathindex
												d("[Navigation]: finished ascending, newpathindex ["..tostring(NavigationManager.NavPathNode).."]")
											end
											return ascended
										end, function () Player:TakeOff() end)
										
										return
									end
								end
							end
						else
							--d("[Navigation]: Navigate to node, backup.")
							ml_navigation:NavigateToNode(ppos,nextnode)	
						end
					end
				
				else
					--d("[Navigation] - Path end reached.")
					ml_navigation.StopMovement()
					Player:Stop()							-- this literally makes no sense...both functions are the SAME but if I remove this one, the bot doesnt stop ..yeah right ...fuck you ffxiv 
				end	
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
function ml_navigation:NavigateToNode(ppos, nextnode, stillonpaththreshold, adjustedHeading)
	local adjustedHeading = IsNull(adjustedHeading,0)
	
	-- Check if we left our path
	if ( stillonpaththreshold ) then
		if ( not ml_navigation:IsStillOnPath(ppos,stillonpaththreshold) ) then return end	
	else
		-- One path may contain all thresholds, so the static path deviation setting is useless for FF.
		local threshold2d, threshold3d = ml_navigation.GetDeviationThresholds()
		if ( not ml_navigation:IsStillOnPath(ppos,threshold3d) ) then return end	
	end
				
	-- Check if the next node is reached
	local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(ppos,nextnode)
	if ( ml_navigation:IsGoalClose(ppos,nextnode)) then
		--d("[Navigation] - Node reached. ("..tostring(math.round(nodedist,2)).." < "..tostring(ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()])..")")
		
		ml_navigation.lastconnectionid = nextnode.navconnectionid		
		ml_navigation.pathindex = ml_navigation.pathindex + 1
		NavigationManager.NavPathNode = ml_navigation.pathindex
		
	else						
		ml_navigation.GUI.lastAction = "Walk to Node"
		
		-- We have not yet reached our node
		if (adjustedHeading ~= 0) then
			Player:SetFacing(adjustedHeading)
		else
			local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})											
			if ( anglediff < 35 and nodedist > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
				Player:SetFacing(nextnode.x,nextnode.y,nextnode.z,true)
			else
				Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
			end
		end
		
		if (IsDiving()) then
			-- Set Pitch							
			local currentPitch = math.round(Player.flying.pitch,3)
			local minVector = math.normalize(math.vectorize(ppos,nextnode))
			local pitch = math.asin(-1 * minVector.y)
			Player:SetPitch(pitch)
		end
		
		if (not Player:IsMoving() and not MIsLocked()) then
			Player:Move(FFXIV.MOVEMENT.FORWARD)
			ffnav.Await(2000, function () return Player:IsMoving() end)
		end
	end
end

function ml_navigation.IsPathInvalid()
	if (table.valid(ml_navigation.path)) then
		if (not IsDiving() and not IsSwimming() and Player.incombat and (not Player.ismounted or not Player.mountcanfly)) then
			for i, node in pairs(ml_navigation.path) do
				if (node.type == GLOBAL.NODETYPE.CUBE) then
					return true
				end
			end		
		end		
	end
	return false
end

function ml_navigation:IsStillOnPath(ppos,deviationthreshold)	
	if ( ml_navigation.pathindex > 1 and not ml_navigation.omc_details) then -- disable the isstillonpath for navcons , it keeps resetting the path / movement sometimes .. ?
		local threshold = ml_navigation.PathDeviationDistances[ml_navigation.GetMovementType()]
		if (type(deviationthreshold) == "number") then
			threshold = deviationthreshold
		elseif (type(deviationthreshold) == "string") then
			threshold = ml_navigation.PathDeviationDistances[deviationthreshold]
		end
		
		local lastnode = ml_navigation.path[ml_navigation.pathindex - 1]
		local nextnode = ml_navigation.path[ml_navigation.pathindex]
		
		local radius = 0
		if (self.lastconnectionid ~= 0) then
			-- 'live nav' vs 'new nav'
			local navcon
			if (NavigationManager.ShowCells == nil ) then
				 navcon = ml_mesh_mgr.navconnections[self.lastconnectionid]
				 if (navcon) then -- Type 5
					radius = navcon.radius
					threshold = threshold + radius
				end
			else
				navcon = NavigationManager:GetNavConnection(self.lastconnectionid)
				 if (navcon) then -- Type 5
					if(self.omc_direction == 1) then
						radius = navcon.sideA.radius
					else
						radius = navcon.sideB.radius
					end
					threshold = threshold + radius
				end
			end
			
		end
		
		if (lastnode and nextnode) then
			ml_navigation.TagNode(nextnode)
			if ( not Player:IsJumping()) then
				-- measuring the distance from player to the straight line from navnode A to B  works only when we use the 2D distance, since it cuts obvioulsy through height differences. Only when flying it should use 3D.
				if ((IsFlying() or IsDiving()) and nextnode.is_cube) then --if the node we goto is on the floor (underwater!) use 2D, it happens that recast just points to the next node which is pathing through U or A shaped terrain.
					local distline = math.distancepointline(lastnode,nextnode,ppos)
					if (distline > threshold) then			
						d("[Navigation] - Player not on path anymore (3D). - Distance to Path: "..tostring(distline).." > "..tostring(threshold))
						d("[Navigation] - Last Node ["..tostring(ml_navigation.pathindex - 1).."]: x = "..tostring(lastnode.x)..",y = "..tostring(lastnode.y)..",z = "..tostring(lastnode.z))
						d("[Navigation] - Next Node ["..tostring(ml_navigation.pathindex).."]: x = "..tostring(nextnode.x)..",y = "..tostring(nextnode.y)..",z = "..tostring(nextnode.z))
						
						--NavigationManager:UpdatePathStart()  -- this seems to cause some weird twitching loops sometimes..not sure why
						--NavigationManager:ResetPath()
						Player:Stop()
						--ml_navigation:MoveTo(ml_navigation.targetposition.x, ml_navigation.targetposition.y, ml_navigation.targetposition.z, ml_navigation.targetid)
						return false
					end
				else
					-- only use 2D 
					local from = { x = lastnode.x, y = 0, z = lastnode.z }
					local to = { x = nextnode.x, y = 0, z = nextnode.z }
					local ppos2d = { x = ppos.x, y = 0, z = ppos.z }
					local distline = math.distancepointline(from, to, ppos2d)
					if (distline > threshold) then			
						d("[Navigation] - Player not on path anymore (2D). - Distance to Path: "..tostring(distline).." > "..tostring(threshold))
						d("[Navigation] - Last Node ["..tostring(ml_navigation.pathindex - 1).."]: x = "..tostring(lastnode.x)..",y = "..tostring(lastnode.y)..",z = "..tostring(lastnode.z))
						d("[Navigation] - Next Node ["..tostring(ml_navigation.pathindex).."]: x = "..tostring(nextnode.x)..",y = "..tostring(nextnode.y)..",z = "..tostring(nextnode.z))
						
						--NavigationManager:UpdatePathStart()  -- this seems to cause some weird twitching loops sometimes..not sure why
						--NavigationManager:ResetPath()
						Player:Stop()
						--ml_navigation:MoveTo(ml_navigation.targetposition.x, ml_navigation.targetposition.y, ml_navigation.targetposition.z, ml_navigation.targetid)
						return false
					end				
				end
			end
		end
	end
	return true
end

-- Sets the position and heading which the main call will make sure that it has before continuing the movement. Used for NavConnections / OMC
function ml_navigation:SetEnsureStartPosition(nextnode, playerpos, navconnection, nearsidepos, farsidepos, nearheading)	
		
	-- Find out which side of the NavCon we are at	
	local nearside, farside
	if( not nearsidepos ) then -- old live nav
		if (math.distance3d(playerpos, navconnection.from) < math.distance3d(playerpos, navconnection.to) ) then
			nearside = navconnection.from
			farside = navconnection.to
		else
			nearside = navconnection.to
			farside = navconnection.from
		end
	else
		nearside = nearsidepos
		nearside.hx = nearheading
		farside = farsidepos
	end
	
	self.ensureposition = {x = nearside.x, y = nearside.y, z = nearside.z}
		
	if(nearside.hx ~= 0 ) then
		self.ensureheading = nearside
	else	
		self.ensureheading = nil
		self.ensureheadingtargetpos = {x = farside.x, y = farside.y, z = farside.z}
	end	
	return self:EnsurePosition(playerpos)
end

-- Ensures that the player is really at a specific position, stopped and facing correctly. Used for NavConnections / OMC
function ml_navigation:EnsurePosition(ppos)
	if ( not self.ensurepositionstarttime ) then self.ensurepositionstarttime = ml_global_information.Now end
	
	local dist = self:GetRaycast_Player_Node_Distance(ppos,self.ensureposition)
	
	if ( (ml_global_information.Now - self.ensurepositionstarttime) < 1000) then
	
		if ( not Player:IsMoving () and dist > 0.5 and dist < 3.0 ) then	-- teleport while jumping results in a crippled state afterwards
			if ( Player:IsJumping() ) then
				return true
			else
				Hacks:TeleportToXYZ(self.ensureposition.x,self.ensureposition.y,self.ensureposition.z)
				d("[Navigation:EnsurePosition]: TP to correct Start Position.")
			end
		end
		
		-- update pos after teleport
		local ppos = Player.pos
		local anglediff = self.ensureheading and (ppos.h - self.ensureheading.hx)
		local anglediff2= self.ensureheadingtargetpos and math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = self.ensureheadingtargetpos.x-ppos.x, y = 0, z = self.ensureheadingtargetpos.z-ppos.z})
		
		--d(tostring(anglediff).. " - " ..tostring(anglediff2))
		if ( (self.ensureheading and (anglediff > 0.003 or anglediff < -0.003) ) or (self.ensureheadingtargetpos and (anglediff2 > 2 or anglediff2 < -2))) then
			if ( Player:IsMoving () ) then Player:StopMovement() end			
			local dist = ml_navigation:GetRaycast_Player_Node_Distance(ppos,self.ensureposition)
							
			if ( dist > 0.5 ) then
				if ( Player:IsJumping() ) then
					return true
				else
					Hacks:TeleportToXYZ(self.ensureposition.x,self.ensureposition.y,self.ensureposition.z)
					d("[Navigation]: [EnsurePosition] - TP to correct location.")
				end		
			end
			
			if ( anglediff and (anglediff > 0.003 or anglediff < -0.003) ) then
				Player:SetFacing(self.ensureheading.hx) -- face hard
				d("[Navigation]: [EnsurePosition] - Hard facing towards Heading.")
								
			elseif (anglediff2 and (anglediff2 > 2 or anglediff2 < -2)) then 
				Player:SetFacing(self.ensureheadingtargetpos.x,self.ensureheadingtargetpos.y,self.ensureheadingtargetpos.z) -- face hard
				d("[Navigation]: [EnsurePosition] - Hard facing towards Target position.")
			end
			return true
		end
		
	else	-- We waited long enough
		d("[Navigation]: [EnsurePosition] - ResetOMCHandler, we waited longer than 2 seconds..")
		self:ResetOMCHandler()
		return false
	end
	
	-- Lets wait at least 250ms on each jump
	if ( (ml_global_information.Now - self.ensurepositionstarttime) < 400) then
		return true	-- we are 'handling it still'
	else
		self.ensureposition = nil
		return false -- bot can continue
	end
end

-- Resets all OMC related variables
function ml_navigation:ResetOMCHandler()
	self.ensureposition = nil
	self.ensureheading = nil
	self.ensureheadingtargetpos = nil
	self.ensurepositionstarttime = nil
	self.omc_id = nil
	self.omc_traveltimer = nil
	self.omc_starttimer = 0
	self.omc_startheight = nil
	self.omc_details = {}
	self.omc_traveldist = 0
	self.omc_traveltimer = nil
	self.omc_direction = 0
	self.lastupdate = 0
end

ffnav = {}
ffnav.yield = {}
ffnav.process = {}
ffnav.alteredGoal = {}
ffnav.lastGoal = {}
ffnav.currentParams = {}
ffnav.lastGoalResult = false
ffnav.lastGoalCheck = 0
ffnav.lastPathTime = 0
ffnav.ascendTime = 0
ffnav.lastCubeSwap = 0
ffnav.lastTrim = 0
ffnav.forceDescent = 0
ffnav.descentPos = {}
ffnav.isascending = false
ffnav.isdescending = false

function ffnav.CompactPath()
	local newPath = {}
	if (table.valid(ml_navigation.path)) then
		for i,node in pairsByKeys(ml_navigation.path) do
			if (table.size(newPath) > 0) then
				table.insert(newPath,node)
			else
				newPath[0] = node
			end
		end
	end
	ml_navigation.path = newPath
end

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
	if (param1 and type(param1) == "number") then
		if (param2 and type(param2) == "number") then
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

function ffnav.AwaitThen(param1, param2, param3, param4)
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
		if (param4 ~= nil and type(param4) == "function") then
			ffnav.yield = {
				mintimer = IIF(param1 ~= 0,Now() + param1,0),
				maxtimer = IIF(param2 ~= 0,Now() + param2,0),
				evaluator = param3,
				followall = param4,
			}
		else
			ffnav.yield = {
				mintimer = IIF(param1 ~= 0,Now() + param1,0),
				maxtimer = IIF(param2 ~= 0,Now() + param2,0),
				followall = param3,
			}
		end
	else
		if (param3 ~= nil and type(param3) == "function") then
			ffnav.yield = {
				mintimer = 0,
				maxtimer = Now() + param1,
				evaluator = param2,
				followall = param3,
			}
		else
			ffnav.yield = {
				mintimer = 0,
				maxtimer = Now() + param1,
				followall = param2,
			}
		end
	end
end

function ml_navigation.DrawObstacleFinder(event, ticks)
	-- testing code
	if (false) then 
		local maxWidth, maxHeight = GUI:GetScreenSize()
		GUI:SetNextWindowPos(0, 0, GUI.SetCond_Always)
		GUI:SetNextWindowSize(maxWidth,maxHeight,GUI.SetCond_Always) --set the next window size
		local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
		GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], 0)
		flags = (GUI.WindowFlags_NoInputs + GUI.WindowFlags_NoBringToFrontOnFocus + GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
		GUI:Begin("Show Nav Space", true, flags)
		
		local ppos = Player.pos
		if (IsFlying()) then
			ppos.y = ppos.y + 0.65
		else
			ppos.y = ppos.y + 0.10
		end
		local h = ppos.h
		local forwardHeading = ConvertHeading(h)%(2*math.pi)
		local straightTest = GetPosFromDistanceHeading(ppos, 1, forwardHeading)
		local straightTestAngled = GetPosFromDistanceHeading({x = ppos.x, y = ppos.y + .5, z = ppos.z}, 1, forwardHeading)
				
		-- Using node heading to make sure we're following the path and not some wild correction vector.
		local angle = AngleFromPos(Player.pos, straightTest)
		local nodeHeading = DegreesToHeading(angle)
				
		local leftBaseHeading = ConvertHeading(nodeHeading + (math.pi/2))%(2*math.pi)
		local rightBaseHeading = ConvertHeading(nodeHeading - (math.pi/2))%(2*math.pi)
				
		local slightLeft = ConvertHeading(nodeHeading + (math.pi * .04))%(2*math.pi)
		local slightRight = ConvertHeading(nodeHeading - (math.pi * .04))%(2*math.pi)
				
		local leftBase = GetPosFromDistanceHeading(ppos, 1, leftBaseHeading)
		local rightBase = GetPosFromDistanceHeading(ppos, 1, rightBaseHeading)
		local leftBaseExtended = GetPosFromDistanceHeading(ppos, 1, leftBaseHeading)
		local rightBaseExtended = GetPosFromDistanceHeading(ppos, 1, rightBaseHeading)	
		local leftTest = GetPosFromDistanceHeading(leftBase, 1, nodeHeading)
		local leftTestAngled = GetPosFromDistanceHeading({x = leftBase.x, y = leftBase.y + .5, z = leftBase.z}, 1, nodeHeading)
		local rightTest = GetPosFromDistanceHeading(rightBase, 1, nodeHeading)
		local rightTestAngled = GetPosFromDistanceHeading({x = rightBase.x, y = rightBase.y + .5, z = rightBase.z}, 1, nodeHeading)
		--local straightTest = GetPosFromDistanceHeading(ppos, 1, nodeHeading)
		
		local nodeCircles = {}
		
		local rPos = RenderManager:WorldToScreen({ x = ppos.x, y = ppos.y, z = ppos.z })
		if (table.valid(rPos)) then
			GUI:AddCircleFilled(rPos.x,rPos.y,7,GUI:ColorConvertFloat4ToU32(.2,1,.2,1))
			table.insert(nodeCircles,rPos)
		end
		
		local stPos = RenderManager:WorldToScreen({ x = straightTest.x, y = straightTest.y, z = straightTest.z })
		if (table.valid(stPos)) then
			GUI:AddCircleFilled(stPos.x,stPos.y,7,GUI:ColorConvertFloat4ToU32(.2,1,.2,1))
			table.insert(nodeCircles,stPos)
		end
		
		local staPos = RenderManager:WorldToScreen({ x = straightTestAngled.x, y = straightTestAngled.y, z = straightTestAngled.z })
		if (table.valid(staPos)) then
			GUI:AddCircleFilled(staPos.x,staPos.y,7,GUI:ColorConvertFloat4ToU32(.2,1,.2,1))
			table.insert(nodeCircles,staPos)
		end
		
		local ltPos = RenderManager:WorldToScreen({ x = leftBase.x, y = leftBase.y, z = leftBase.z })
		if (table.valid(ltPos)) then
			GUI:AddCircleFilled(ltPos.x,ltPos.y,7,GUI:ColorConvertFloat4ToU32(.2,1,.2,1))
			table.insert(nodeCircles,ltPos)
		end
		
		local lt2Pos = RenderManager:WorldToScreen({ x = leftTest.x, y = leftTest.y, z = leftTest.z })
		if (table.valid(lt2Pos)) then
			GUI:AddCircleFilled(lt2Pos.x,lt2Pos.y,7,GUI:ColorConvertFloat4ToU32(.2,1,.2,1))
			table.insert(nodeCircles,lt2Pos)
		end
		
		local lt2aPos = RenderManager:WorldToScreen({ x = leftTestAngled.x, y = leftTestAngled.y, z = leftTestAngled.z })
		if (table.valid(lt2aPos)) then
			GUI:AddCircleFilled(lt2aPos.x,lt2aPos.y,7,GUI:ColorConvertFloat4ToU32(.2,1,.2,1))
			table.insert(nodeCircles,lt2aPos)
		end
		
		local rtPos = RenderManager:WorldToScreen({ x = rightBase.x, y = rightBase.y, z = rightBase.z })
		if (table.valid(rtPos)) then
			GUI:AddCircleFilled(rtPos.x,rtPos.y,7,GUI:ColorConvertFloat4ToU32(.2,1,.2,1))
			table.insert(nodeCircles,rtPos)
		end
		
		local rt2Pos = RenderManager:WorldToScreen({ x = rightTest.x, y = rightTest.y, z = rightTest.z })
		if (table.valid(rt2Pos)) then
			GUI:AddCircleFilled(rt2Pos.x,rt2Pos.y,7,GUI:ColorConvertFloat4ToU32(.2,1,.2,1))
			table.insert(nodeCircles,rt2Pos)
		end
		
		local rt2aPos = RenderManager:WorldToScreen({ x = rightTestAngled.x, y = rightTestAngled.y, z = rightTestAngled.z })
		if (table.valid(rt2aPos)) then
			GUI:AddCircleFilled(rt2aPos.x,rt2aPos.y,7,GUI:ColorConvertFloat4ToU32(.2,1,.2,1))
			table.insert(nodeCircles,rt2aPos)
		end
		
		local connections = {
			{ a = rPos, b = stPos, ad = ppos, bd = straightTest},
			{ a = rPos, b = staPos, ad = ppos, bd = straightTestAngled},
			{ a = rPos, b = ltPos, ad = ppos, bd = leftBase },
			{ a = rPos, b = rtPos, ad = ppos, bd = rightBase },
			{ a = rPos, b = lt2Pos, ad = ppos, bd = leftTest },
			{ a = rPos, b = rt2Pos, ad = ppos, bd = rightTest },
			{ a = rPos, b = lt2aPos, ad = ppos, bd = leftTestAngled },
			{ a = rPos, b = rt2aPos, ad = ppos, bd = rightTestAngled },
		}
		
		for _,connection in pairs(connections) do
			if (connection and table.valid(connection.a) and table.valid(connection.b) and table.valid(connection.ad) and table.valid(connection.bd)) then
				local a, b, ad, bd = connection.a, connection.b, connection.ad, connection.bd
				local hit, hitx, hity, hitz = RayCast(ad.x,ad.y,ad.z,bd.x,bd.y,bd.z)
				if (not hit) then
					GUI:AddLine(a.x, a.y, b.x, b.y, GUI:ColorConvertFloat4ToU32(.2,1,.2,1), 6)
				else
					local bPos = RenderManager:WorldToScreen({ x = hitx, y = hity, z = hitz })
					if (table.valid(bPos)) then
						GUI:AddLine(a.x, a.y, bPos.x, bPos.y, GUI:ColorConvertFloat4ToU32(1,.2,.2,1), 6)
						GUI:AddCircleFilled(bPos.x,bPos.y,7,GUI:ColorConvertFloat4ToU32(1,.2,.2,1))
					end
				end
			end
		end

		GUI:End()
		GUI:PopStyleColor()
	end
end

function ml_navigation.DrawPath(event, ticks)
	--if ( ml_navigation.CanRun() ) then
		-- Draw the Navpath in 3D
		if ( gNavShowPath and table.size(ml_navigation.path) > 1 ) then
			
			local maxWidth, maxHeight = GUI:GetScreenSize()
			GUI:SetNextWindowPos(0, 0, GUI.SetCond_Always)
			GUI:SetNextWindowSize(maxWidth,maxHeight,GUI.SetCond_Always) --set the next window size
			local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
			GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], 0)
			flags = (GUI.WindowFlags_NoInputs + GUI.WindowFlags_NoBringToFrontOnFocus + GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
			GUI:Begin("Show Nav Space", true, flags)

			-- Build the 3d object table	
			-- The table is built in this way so that the draw is not dependent on keys being in order.  
			-- Could use pairsByKeys too I guess, overall effect is probably non-existent.
			local nodemap = {}
			for id, node in pairsByKeys(ml_navigation.path) do	
				local nodePos = RenderManager:WorldToScreen({ x = node.x, y = node.y, z = node.z })
				if (table.valid(nodePos)) then
					GUI:AddCircleFilled(nodePos.x,nodePos.y,7,GUI:ColorConvertFloat4ToU32(1,.2,.2,1))
					table.insert(nodemap,nodePos)
				end
			end
			
			for i = 1,#nodemap do
				local thisnode = nodemap[i]
				local nextnode = nodemap[i+1]
				if (thisnode and nextnode) then
					GUI:AddLine(thisnode.x, thisnode.y, nextnode.x, nextnode.y, GUI:ColorConvertFloat4ToU32(.2,1,.2,1), 6)
				end
			end	
		
			GUI:End()
			GUI:PopStyleColor()
		end
	--end
end
--RegisterEventHandler("Gameloop.Draw", ml_navigation.DrawPath)
RegisterEventHandler("Gameloop.Draw", ml_navigation.DrawObstacleFinder)









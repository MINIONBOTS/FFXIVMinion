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
	return (GetGameState() == FFXIV.GAMESTATE.INGAME and not MIsLoading())
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
	
	local nc, nc_close = nil, false
	if (node.navconnectionid ~= 0) then
		if (table.valid(ml_mesh_mgr.navconnections)) then
			nc = ml_mesh_mgr.navconnections[node.navconnectionid]
		end
	end
	
	if (nc and In(nc.subtype,1,2,3,4)) then
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dwalk"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
			self:ResetOMCHandler(nc)
			return true
		end
	elseif (Player.flying.isflying) then
		--d("goaldist "..tostring(goaldist).. " < = "..tostring(ml_navigation.NavPointReachedDistances["3dfly"]).." and " ..tostring(goaldist2d).." < = " ..tostring(ml_navigation.NavPointReachedDistances["2dfly"]))
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dfly"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dfly"]) then
			return true
		end
	elseif (Player.diving.isdiving) then
		--d("diving goaldist 3d:"..tostring(goaldist).. " < = "..tostring(ml_navigation.NavPointReachedDistances["3ddive"]).." and 2d:" ..tostring(goaldist2d).." < = " ..tostring(ml_navigation.NavPointReachedDistances["2ddive"]))
		if (goaldist <= ml_navigation.NavPointReachedDistances["3ddive"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2ddive"]) then
			return true
		end
	elseif (Player.diving.isswimming) then
		--d("swimming goaldist 3d:"..tostring(goaldist).. " < = "..tostring(ml_navigation.NavPointReachedDistances["3dswim"]).." and 2d:" ..tostring(goaldist2d).." < = " ..tostring(ml_navigation.NavPointReachedDistances["2dswim"]))
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dswim"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dswim"]) then
			return true
		end
	elseif (Player.ismounted) then
		--d("goaldist "..tostring(goaldist).. " < = "..tostring(ml_navigation.NavPointReachedDistances["3dmount"]).." and " ..tostring(goaldist2d).." < = " ..tostring(ml_navigation.NavPointReachedDistances["2dmount"]))
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dmount"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dmount"]) then
			return true
		end
	else
		--d("goaldist "..tostring(goaldist).. " < = "..tostring(ml_navigation.NavPointReachedDistances["3dwalk"]).." and " ..tostring(goaldist2d).." < = " ..tostring(ml_navigation.NavPointReachedDistances["2dwalk"]))
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dwalk"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
			return true
		end
	end
	return false
end

function ml_navigation:CheckPath(pos2,floorfilters,cubefilters)
	local pos = Player.pos
	if (not table.valid(pos2)) then
		return false
	end
	
	local floorfilters = IsNull(floorfilters,0)
	local cubefilters = IsNull(cubefilters,0)
	
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
function Player:MoveTo(x, y, z, dist, floorfilters, cubefilters)
	local floorfilters = IsNull(floorfilters,0)
	local cubefilters = IsNull(cubefilters,0)
	
	if (MPlayerDriving()) then
		d("[NAVIGATION]: Releasing control to Player..")
		ml_navigation.path = {}
		ml_navigation.pathindex = 0
		NavigationManager.NavPathNode = ml_navigation.pathindex
		return false
	end
	
	local ret = Player:BuildPath(x, y, z, floorfilters, cubefilters)	
	if (ml_navigation:HasPath()) then
		if (ml_navigation:EnablePathing()) then
			--d("[NAVIGATION: Started pathing [MOVETO3].")
		end
		return true
	else
		if (ml_navigation:DisablePathing()) then
			--d("[NAVIGATION: Stopped pathing, path not valid [MOVETO4].")			
		end
		return false
	end
end

function Player:BuildPath(x, y, z, floorfilters, cubefilters)
	local floorfilters = IsNull(floorfilters,0)
	local cubefilters = IsNull(cubefilters,0)
	
	d("buildPath:"..tostring(floorfilters)..","..tostring(cubefilters))

	if (MPlayerDriving()) then
		d("[NAVIGATION]: Releasing control to Player..")
		ml_navigation.path = {}
		ml_navigation.pathindex = 0
		NavigationManager.NavPathNode = ml_navigation.pathindex
		return -1337
	end
	
	if (x == nil or y == nil or z == nil ) then -- yes this happens regularly inside fates, because some of the puzzle code calls moveto nil/nil/nil
		d("[NAVIGATION]: Invalid Move To Position :["..tostring(x)..","..tostring(y)..","..tostring(z).."]")
		return 0
	end
	
	local ppos = Player.pos	
	local newGoal = { x = x, y = y, z = z }
	ml_navigation.targetposition = newGoal

	local dist = math.distance3d(ppos,newGoal)
	if (not IsFlying() and not IsDiving() and ((Player.incombat and (not Player.ismounted or not Player.mountcanfly)) or IsTransporting())) then
		cubefilters = bit.bor(cubefilters, GLOBAL.CUBE.AIR)
	end
	NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.CUBE, cubefilters)
	NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.FLOOR, floorfilters)
	
	local ret = 0;
	if (NavigationManager:IsReachable(newGoal)) then
		ret = ml_navigation:MoveTo(newGoal.x,newGoal.y,newGoal.z)
		return ret
	else
		ret = -11
	end
	
	if (ret <= 0) then
		ml_navigation.path = {}
		ml_navigation.pathindex = 0
		NavigationManager.NavPathNode = ml_navigation.pathindex
		return ret
	end
end

-- Overriding  the (old) c++ Player:Stop(), to handle the additionally needed navigation functions
function Player:Stop(resetpath)
	--local resetpath = IsNull(resetpath,true)
	-- Resetting the path can cause some problems with macro nodes.
	-- On occassion it will enter a circular loop if something in the path calls a stop (like mounting).
	
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
	if (table.valid(node)) then
		node.is_start = (bit.band(node.type2, 1) ~= 0)
		node.is_end = (bit.band(node.type2, 2) ~= 0)
		node.is_omc = (bit.band(node.type2, 4) ~= 0)
		
		node.is_floor = (node.type == GLOBAL.NODETYPE.FLOOR)
		node.is_cube = (node.type == GLOBAL.NODETYPE.CUBE)
		
		local flags = node.flags
		
		node.ground, node.ground_water, node.ground_border, node.ground_avoid, node.air, node.water, node.air_avoid = false, false, false, false, false, false, false
		if (node.is_floor) then
			node.ground = (bit.band(flags, GLOBAL.FLOOR.GROUND) ~= 0)
			node.ground_water = (bit.band(flags, GLOBAL.FLOOR.WATER) ~= 0)
			node.ground_border = (bit.band(flags, GLOBAL.FLOOR.BORDER) ~= 0)
			node.ground_avoid = (bit.band(flags, GLOBAL.FLOOR.AVOID) ~= 0)
		elseif (node.is_cube) then
			node.air = (bit.band(flags, GLOBAL.CUBE.AIR) ~= 0)
			node.water = (bit.band(flags, GLOBAL.CUBE.WATER) ~= 0)
			node.air_avoid = (bit.band(flags, GLOBAL.CUBE.AVOID) ~= 0)
		end
	end
end

-- Handles the actual Navigation along the current Path. Is not supposed to be called manually! 
-- Also handles OMCs
function ml_navigation.Navigate(event, ticks )	
	local self = ml_navigation
	if ((ticks - (ml_navigation.lastupdate or 0)) > 50) then 
		ml_navigation.lastupdate = ticks
				
		if ( ml_navigation.CanRun() and ml_navigation.canPath) then	
		
			--d("Can Path.")
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
				
					if (ml_navigation.IsPathInvalid() and table.valid(ml_navigation.targetposition)) then
						--d("[Navigation]: Resetting path, need to pull a non-cube path.")
						-- Calling Stop() wasn't enough here, had to completely pull a new path otherwise it keeps trying to use the same path.
						
						--Player:Stop()	-- calling stop first and then creating a new path would be the more logical order eh ;)
						--NavigationManager:UseCubes(false)
						--Player:MoveTo(ffnav.currentGoal.x,ffnav.currentGoal.y,ffnav.currentGoal.z)
						--NavigationManager:UseCubes(true)
						
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
					
					ml_navigation.TagNode(nextnode)
					ml_navigation.TagNode(nextnextnode)
					
					--table.print(nextnode)
					
					ml_navigation.GUI.pathHops = table.size(ml_navigation.path)
					ml_navigation.GUI.currentIndex = ml_navigation.pathindex			
					ml_navigation.GUI.nextNodeDistance = math.distance3d(ppos,nextnode)
					
			-- Ensure Position: Takes a second to make sure the player is really stopped at the wanted position (used for precise OMC bunnyhopping and others where the player REALLY has to be on the start point & facing correctly)
					if ( table.valid (ml_navigation.ensureposition) and ml_navigation:EnsurePosition() ) then						
						return
					end
					
					local nc = self.omc_details
					if ( self.omc_id ) then
					
						local from_pos = nc.from
						local to_pos = nc.to
						
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
								d("[Navigation] - Not getting closer to OMC END node. We are most likely stuck.")
								ml_navigation.StopMovement()
								return
							end
						end
							
						-- Max Timer Check in case something unexpected happened
						if (self.omc_starttimer == 0) then
							self.omc_starttimer = ticks
						else
							if ( self.omc_starttimer ~= 0 and ticks - self.omc_starttimer > 10000 ) then
								d("[Navigation] - Could not read OMC END in ~10 seconds, something went wrong..")
								ml_navigation.StopMovement()
								return
							end
						end
								
						-- OMC JUMP
						if ( nc.subtype == 1 ) then
							
							ml_navigation.GUI.lastAction = "Jump OMC"
							
							if ( Player:IsJumping()) then
								d("[Navigation]: Jumping for OMC.")
								ffnav.Await(10000, function () return (not Player:IsJumping()) end, function () Player:StopMovement() end)
							else	 
								if ( not ml_navigation.omc_startheight ) then
									local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = to_pos.x-ppos.x, y = 0, z = to_pos.z-ppos.z})
									if ( anglediff > 0.3 ) then
										Player:SetFacing(to_pos.x,to_pos.y,to_pos.z)
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
									local todist,todist2d = ml_navigation:GetRaycast_Player_Node_Distance(ppos,to_pos)
									d("todist2d:"..tostring(todist2d))
									if ( todist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
										if (nextnextnode) then
											Player:SetFacing(nextnextnode.x,nextnextnode.y,nextnextnode.z)
										end
										ml_navigation.pathindex = ml_navigation.pathindex + 1
										NavigationManager.NavPathNode = ml_navigation.pathindex		
										ml_navigation:ResetOMCHandler()
									else									
										Player:Move(FFXIV.MOVEMENT.FORWARD)
										Player:SetFacing(to_pos.x,to_pos.y,to_pos.z)
									end
								end
							end
							return
						end
						
						-- OMC Walk								
						if ( nc.subtype == 2 ) then
						
							ml_navigation.GUI.lastAction = "Walk OMC"
							ml_navigation:NavigateToNode(ppos,nextnode,1000)
							return
						end
						
						-- OMC Teleport						
						if ( nc.subtype == 3 ) then
							
							ml_navigation.GUI.lastAction = "Teleport OMC"
							
							if (gTeleportHack) then
								Hacks:TeleportToXYZ(to.x,to.y,to.z,true)
							else
								ffxiv_dialog_manager.IssueStopNotice("Teleport OMC","Teleport OMC's exist on this mesh.\nPlease enable the Teleport (Hack) usage in Advanced Settings or remove them.")
							end
							ml_navigation.pathindex = ml_navigation.pathindex + 1
							NavigationManager.NavPathNode = ml_navigation.pathindex	
							ml_navigation:ResetOMCHandler()
							return
						end
						
						-- OMC Interact	
						if ( nc.subtype == 4 ) then
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
								NavigationManager.NavPathNode = ml_navigation.pathindex		
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
						if ( nc.subtype == 5 ) then
							
							ml_navigation.GUI.lastAction = "Portal OMC"
							ml_navigation:NavigateToNode(ppos,nextnode,2000)
							return
						end
						
						-- OMC Custom
						if ( nc.subtype == 6 ) then
							
							ml_navigation.GUI.lastAction = "Custom OMC"
							ml_navigation:NavigateToNode(ppos,nextnode,1500)	
							return							
						end
					end
					
			-- Cube Navigation
					if (IsDiving()) then
						d("[Navigation]: Underwater navigation.")
						
						local target = Player:GetTarget()
						if (target and target.los and target.distance2d < 15) then
							if (target.distance2d < 1) then
								Player:Stop()
								return false
							end

							-- If we're close, we need to just fly directly.  The cubes make it an impossible task to try to do this via the actual path.
							local tpos = target.pos
							local dist3D = math.distance3d(tpos,ppos)
							local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = tpos.x-ppos.x, y = 0, z = tpos.z-ppos.z})
							if ( anglediff < 35 and dist3D > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
								Player:SetFacing(tpos.x,tpos.y,tpos.z, true) -- smooth facing
							else
								Player:SetFacing(tpos.x,tpos.y,tpos.z)
							end
							
							local modifiedNode = { type = nextnode.type, type2 = nextnode.type2, flags = nextnode.flags, x = tpos.x, y = (tpos.y - 2), z = tpos.z }
							
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
							if ( not ml_navigation:IsStillOnPath(ppos,"3ddive") ) then 
								d("we have left the path")
								return 
							end
															
							-- Check if the next node is reached:
							local dist3D = math.distance3d(nextnode,ppos)
							if ( ml_navigation:IsGoalClose(ppos,nextnode)) then
								-- We reached the node
								--d("[Navigation] - Cube Node reached. ("..tostring(math.round(dist3D,2)).." < "..tostring(ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()])..")")	
								local originalIndex = ml_navigation.pathindex + 1
								--[[
								local newIndex = originalIndex
								if (FFXIV_Common_SmoothPathing) then
									for i = ml_navigation.pathindex + 2, ml_navigation.pathindex + 10 do
										local node = ml_navigation.path[i]
										if (node) then
											local dist3d = math.distance3d(node,ppos)
											if (dist3d < 100 and string.contains(node.type,"CUBE")) then
												local hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y,ppos.z,node.x,node.y,node.z)
												if (not hit) then
													--d("Bumped index to [" .. i .. "]")
													newIndex = i
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
										ml_navigation.ResetRenderPath()
									end
								end
								--]]
								
								ml_navigation.pathindex = originalIndex	
								NavigationManager.NavPathNode = ml_navigation.pathindex								
							else			
								--d("[Navigation]: Moving to next node")
								-- We have not yet reached our node
								-- Face next node
								local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})
								if ( anglediff < 35 and dist3D > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
									Player:SetFacing(nextnode.x,nextnode.y,nextnode.z, true) -- smooth facing
								else
									Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
								end
								
								local modifiedNode = { type = nextnode.type, type2 = nextnode.type2, flags = nextnode.flags, x = nextnode.x, y = (nextnode.y - 2), z = nextnode.z }
								
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
						
			-- Cube Navigation		
					elseif (IsFlying()) then -- we are in the air or our last node which was reached was a cube node, now continuing to the next node which can be either CUBE or POLY node
						--d("[Navigation]: Flying navigation.")
						
						ml_navigation.GUI.lastAction = "Flying to Node"
						-- Check if we left our path
						if ( not ffnav.isascending and not ml_navigation:IsStillOnPath(ppos,"3dfly") ) then return end
														
						-- Check if the next node is reached:
						local dist3D = math.distance3d(nextnode,ppos)
						if ( ml_navigation:IsGoalClose(ppos,nextnode)) then
						
							ffnav.isascending = nil
							
							if (not nextnode.is_cube and nextnode.ground) then
							
								d("[Navigation]: Next node is not a flying node.")
								local modifiedNode = { type = nextnode.type, type2 = nextnode.type2, flags = nextnode.flags, x = nextnode.x, y = (nextnode.y - 2), z = nextnode.z }
								local hit, hitx, hity, hitz = RayCast(nextnode.x,nextnode.y,nextnode.z,nextnode.x,nextnode.y-5,nextnode.z)
								if (hit) then
									if (hity < modifiedNode.y) then
										modifiedNode.y = hity - 1
									end
								end		
																	
								Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
								local pitch = GetRequiredPitch(modifiedNode) -- Pitch down a little further.
								Player:SetPitch(pitch)
								
								if (not Player:IsMoving()) then
									Player:Move(FFXIV.MOVEMENT.FORWARD)
									ffnav.Await(3000, function () return Player:IsMoving() end)
									return false
								end
								ffnav.AwaitSuccess(5000, function () return (not IsFlying() or GetDiveHeight() == 0) end, function () Player:Stop() end)
								return false									
							end
							
							local originalIndex = ml_navigation.pathindex + 1
							--[[
							local newIndex = originalIndex
							if (FFXIV_Common_SmoothPathing) then
								for i = ml_navigation.pathindex + 2, table.size(ml_navigation.path) do
									local node = ml_navigation.path[i]
									if (node) then
										local dist3d = math.distance3d(node,ppos)
										if (dist3d < 100 and string.contains(node.type,"CUBE")) then
										--if (dist3d < 75) then
											local hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y,ppos.z,node.x,node.y,node.z)
											if (not hit) then
												--d("Bumped index to [" .. i .. "]")
												newIndex = i
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
									ml_navigation.ResetRenderPath()
								end
							end
							--]]
							
							ml_navigation.pathindex = originalIndex	
							NavigationManager.NavPathNode = ml_navigation.pathindex		
						else			
							--ml_debug("[Navigation]: Moving to next node")
							-- We have not yet reached our node
							-- Face next node
							local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})
							if ( anglediff < 35 and dist3D > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
								Player:SetFacing(nextnode.x,nextnode.y,nextnode.z, true) -- smooth facing
							else
								Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
							end
							
							local pitch = GetRequiredPitch(nextnode)
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
						if (nextnode.type == GLOBAL.NODETYPE.CUBE) then
							--d("nextnode : "..tostring(nextnode.x).." - "..tostring(nextnode.y).." - " ..tostring(nextnode.z))
							
							ml_navigation.GUI.lastAction = "Walk to Cube Node"
							
							if (IsSwimming() or bit.band(nextnode.flags, GLOBAL.CUBE.WATER) ~= 0) then
								Player:StopMovement()
								Player:Dive()
								ffnav.Await(3000, function () return (MIsLoading() or IsDiving()) end)
								return
							elseif (not IsFlying() and CanFlyInZone()) then
								if (Player.ismounted and not Player.mountcanfly and bit.band(nextnode.flags, GLOBAL.CUBE.AIR) ~= 0) then
									d("our mount cannot fly, dismount it.")
									Dismount()
									ffnav.Await(5000, function () return not Player.ismounted end)
									return
								elseif (not Player.ismounted) then
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
										Player:TakeOff()
										ffnav.isascending = true
										return
									end
								end
							end						
						end
						
						--d("[Navigation]: Navigate to node.")
						ml_navigation:NavigateToNode(ppos,nextnode)	
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
function ml_navigation:NavigateToNode(ppos, nextnode, stillonpaththreshold)

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
		ml_navigation.pathindex = ml_navigation.pathindex + 1
		NavigationManager.NavPathNode = ml_navigation.pathindex		
	else						
		ml_navigation.GUI.lastAction = "Walk to Node"
		
		-- We have not yet reached our node
		local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})														
		if ( anglediff < 35 and nodedist > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
			Player:SetFacing(nextnode.x,nextnode.y,nextnode.z,true)
		else
			Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
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
	if ( ml_navigation.pathindex > 1 ) then
		local threshold = ml_navigation.PathDeviationDistances[ml_navigation.GetMovementType()]
		if (type(deviationthreshold) == "number") then
			threshold = deviationthreshold
		elseif (type(deviationthreshold) == "string") then
			threshold = ml_navigation.PathDeviationDistances[deviationthreshold]
		end
		
		if ( not Player:IsJumping()) then
			-- measuring the distance from player to the straight line from navnode A to B  works only when we use the 2D distance, since it cuts obvioulsy through height differences. Only when flying it should use 3D.
			if ((IsFlying() or IsDiving()) and string.contains(ml_navigation.path[ml_navigation.pathindex],"CUBE")) then --if the node we goto is on the floor (underwater!) use 2D, it happens that recast just points to the next node which is pathing through U or A shaped terrain.
				if (math.distancepointline(ml_navigation.path[ml_navigation.pathindex-1],ml_navigation.path[ml_navigation.pathindex],ppos) > threshold) then			
					d("[Navigation] - Player not on Path anymore. - Distance to Path: "..tostring(math.distancepointline(ml_navigation.path[ml_navigation.pathindex-1],ml_navigation.path[ml_navigation.pathindex],ppos)).." > "..tostring(threshold))
					
					NavigationManager:UpdatePathStart()
					ml_navigation:MoveTo(ml_navigation.targetposition.x, ml_navigation.targetposition.y, ml_navigation.targetposition.z, ml_navigation.targetid)
					return false
				end
			else
				-- only use 2D 
				local from = { x = ml_navigation.path[ml_navigation.pathindex-1].x, y = 0, z = ml_navigation.path[ml_navigation.pathindex-1].z }
				local to = { x = ml_navigation.path[ml_navigation.pathindex].x, y = 0, z = ml_navigation.path[ml_navigation.pathindex].z }
				local ppos2d = { x = ppos.x, y = 0, z = ppos.z }
				if (math.distancepointline(from, to, ppos2d) > threshold) then			
					d("[Navigation] - Player not on Path anymore. - Distance to Path: "..tostring(math.distancepointline(ml_navigation.path[ml_navigation.pathindex-1],ml_navigation.path[ml_navigation.pathindex],ppos)).." > "..tostring(threshold))
					
					NavigationManager:UpdatePathStart()
					ml_navigation:MoveTo(ml_navigation.targetposition.x, ml_navigation.targetposition.y, ml_navigation.targetposition.z, ml_navigation.targetid)
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
function ml_navigation:ResetOMCHandler(nc)
	self.omc_id = nil
	self.omc_traveltimer = nil
	self.ensureposition = nil
	self.ensureheading = nil
	self.ensurepositionstarttime = nil
	self.omc_starttimer = 0
	self.omc_startheight = nil	
	self.omc_details = {}
	self.omc_traveldist = 0
	self.omc_traveltimer = nil
	
	if (nc) then
		self.omc_id = nc.id
		self.omc_details = nc
	end
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









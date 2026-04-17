--*** ALL 4 LISTS BELOW ARE USED / MODIFY-ABLE IN THE NAVIGATION->MESHMANAGER MINIONLIB UI
-- Distance to the next node in the path at which the ml_navigation.pathindex is iterated 
ml_navigation.NavPointReachedDistances = { 	
	["3dwalk"] = 2,		
	["2dwalk"] = .5,
	["3dmount"] = 5,
	["2dmount"] = 1,
	["3dswim"] = 5,
	["2dswim"] = .75,
	["3ddive"] = 2.5,
	["2ddive"] = 1.25,
	["3dfly"] = 5,
	["2dfly"] = 1.5,
}

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

-- MoveToExact: separate lightweight state machine for precise combat movement
ml_navigation_exact = {
	path = {},
	pathindex = 0,
	targetposition = nil,
	active = false,
	pending = false,
	pendingGoal = nil,
	pendingCacheId = nil,
	threshold = 0.2,
	omc_id = nil,
	omc_details = nil,
	omc_direction = 0,
	omc_starttimer = 0,
	omc_traveltimer = nil,
	omc_traveldist = 0,
	omc_startheight = nil,
	ensureposition = nil,
	ensurepositionstarttime = nil,
	lastupdate = 0,
	autoFollowNodeKey = nil,
	autoFollowLastSet = 0,
	autoFollowRefreshMs = 200,
	autoFollowEnableRetryMs = 250,
	autoFollowLastEnableAttempt = 0,
	maxDispatchYDelta = 8,
	verticalThreshold = 1.5,
	autoFollowBrakeWaitLogged = false,
	reachedLogged = false,
	completed = false,
	lastOptimize = 0,
	requestSeq = 0,
	lastRequestId = nil,
}

local function BuildMoveToExactCacheId(startPos, goalPos)
	ml_navigation_exact.requestSeq = (ml_navigation_exact.requestSeq or 0) + 1
	local mapId = (Player and Player.localmapid) and tostring(Player.localmapid) or "0"
	local key = string.format("exact|%s|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%d",
		mapId,
		startPos.x, startPos.y, startPos.z,
		goalPos.x, goalPos.y, goalPos.z,
		ml_navigation_exact.requestSeq)
	local hash = 5381
	for i = 1, #key do
		hash = ((hash * 33) + string.byte(key, i)) % 2147483647
	end
	if (hash <= 0) then hash = 1 end
	return hash
end

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
								if (ml_navigation:UseAutoFollowPathing()) then
									return true
								end
								local ppos = Player.pos
								local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = pos.x-ppos.x, y = 0, z = pos.z-ppos.z})
								if (anglediff <= 1) then
									return true
								else						
									ml_navigation:TryFaceTarget(pos.x,pos.y,pos.z, 1)
									return false
								end
							end
						)
					else
						table.insert(ml_navigation.receivedInstructions, 
							function () 
								if (ml_navigation:UseAutoFollowPathing()) then
									return true
								end
								if (ml_navigation:IsFacingHeading(pos.x, 0.01)) then
									return true
								else
									ml_navigation:TryFaceHeading(pos.x, 0.01)
									ml_global_information.Await(1000, function () return ml_navigation:IsFacingHeading(pos.x, 0.01) end)
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
			elseif (itype == "MoveForward2") then
                table.insert(ml_navigation.receivedInstructions, 
                    function () 
                        if (not Player:IsMoving()) then
                            KeyDown(69) 
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
							if (ml_navigation:UseAutoFollowPathing()) then
								ml_navigation:DispatchAutoFollowNode(pos, true)
							else
								ml_navigation:TryFaceTarget(pos.x,pos.y,pos.z)
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
									if (not ml_navigation:UseAutoFollowPathing()) then
										ml_navigation:TryFaceTarget(pos.x,pos.y,pos.z)
									end
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
							if (ml_navigation:UseAutoFollowPathing()) then
								ml_navigation:DispatchAutoFollowNode(pos, true)
							elseif (not Player:IsMoving()) then
								ml_navigation:TryFaceTarget(pos.x,pos.y,pos.z)
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
									if (not ml_navigation:UseAutoFollowPathing()) then
										ml_navigation:TryFaceTarget(pos.x,pos.y,pos.z)
									end
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
							if (ml_navigation:UseAutoFollowPathing()) then
								ml_navigation:DispatchAutoFollowNode(pos, true)
							else
								ml_navigation:TryFaceTarget(pos.x,pos.y,pos.z)
								Player:Move(FFXIV.MOVEMENT.FORWARD)
							end
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
									ml_navigation.SmoothFaceTarget(pos.x,pos.y,pos.z)

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
							if (ml_navigation:UseAutoFollowPathing()) then
								ml_navigation:DispatchAutoFollowNode(pos, true)
							else
								ml_navigation:TryFaceTarget(pos.x,pos.y,pos.z)
								Player:Move(FFXIV.MOVEMENT.FORWARD)
							end
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
									ml_navigation.SmoothFaceTarget(pos.x,pos.y,pos.z)
									
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
-- this is mostly because many things like mount, flight, etc, require not only knowing if they are needed but if they are possible (mesh exists, path exists, etc)

ml_navigation.CanRun = function() 
	return (GetGameState() == FFXIV.GAMESTATE.INGAME and not MIsLoading() and Player.alive)
end 	-- Return true here, if the current GameState is "ingame" aka Player and such values are available

ml_navigation.canPath = false
ml_navigation.useAutoFollowPath = false
ml_navigation.autoFollowRefreshMs = 350
ml_navigation.autoFollowNodeKey = nil
ml_navigation.autoFollowLastSet = 0
ml_navigation.lastEnablePathingTime = 0
ml_navigation.EnablePathing = function (self)
	if (not self.canPath) then
		self.canPath = true
		self.lastEnablePathingTime = Now()
		navDebug("[NAV_DEBUG] EnablePathing called. canPath=true")
		return true
	end
	return false
end

ml_navigation.DisablePathing = function (self)
	if (self.canPath) then
		self.canPath = false
		navDebug("[NAV_DEBUG] DisablePathing called. canPath=false")
		Player:Stop() -- how about we actually stop then :P else endless running happens...
		return true
	end
	return false
end

ml_navigation.HasPath = function (self)
	return (table.valid(self.path))
end

ml_navigation.StopMovement = function() Player:Stop() end				 		-- Stop the navi + Playermovement
ml_navigation.IsMoving = function() return Player:IsMoving() end				-- Take a wild guess											
ml_navigation.avoidanceareasize = 2
ml_navigation.flightFollowCam = true
ml_navigation.flightFollowCamRatio = 0.015
ml_navigation.flightFollowCamPitch = -0.50
ml_navigation.flightFollowCamPitchDownRatio = 0.50
ml_navigation.followCamPitchReleaseUntil = 0
ml_navigation.followCamLastCameraPitch = nil
ml_navigation.followCamLastTargetPitch = nil
ml_navigation._lastCamApplyTime = 0

function ml_navigation:UseAutoFollowPathing()
	if (gUseAutoFollowPath ~= nil) then
		return gUseAutoFollowPath
	end
	return self.useAutoFollowPath
end

function ml_navigation:UseFlightFollowCam()
	local flightFollowCamEnabled = (gFlightFollowCam ~= nil and gFlightFollowCam) or self.flightFollowCam
	return (flightFollowCamEnabled and IsFlying())
end

function ml_navigation:UseFollowCamPitch()
	local followCamEnabled = (gFlightFollowCam ~= nil and gFlightFollowCam) or self.flightFollowCam
	return followCamEnabled
end

function ml_navigation:ApplyFollowCamPitch(targetY)
	if (not (Player and self:UseFollowCamPitch())) then
		return false
	end

	local isGround = (not IsFlying() and not IsDiving())
	local targetPitch = ml_navigation.flightFollowCamPitch or -0.50
	local pitchDownRatio = ml_navigation.flightFollowCamPitchDownRatio or 0.0
	if ((not isGround) and pitchDownRatio ~= 0 and Player and Player.flying and Player.flying.pitch and Player.pos and Player.pos.y and targetY ~= nil and targetY < Player.pos.y) then
		local downwardFlightPitch = math.abs(Player.flying.pitch)
		targetPitch = targetPitch - (downwardFlightPitch * pitchDownRatio)
	end
	targetPitch = math.max(-1.5, math.min(0.20, targetPitch))

	local cam = Player.camera
	local now = Now()
	if (isGround and table.valid(cam) and cam.pitch ~= nil) then
		local activeTargetPitch = targetPitch

		-- deduplicate: Update and Draw both call this; skip if already applied this frame
		if (self._lastCamApplyTime and (now - self._lastCamApplyTime) < 14) then
			return true
		end

		local currentPitch = cam.pitch
		local lastWrittenPitch = self.followCamLastCameraPitch
		-- detect user manual pitch input: camera deviated from what we last wrote
		if (lastWrittenPitch ~= nil and math.abs(currentPitch - lastWrittenPitch) > 0.015) then
			self.followCamPitchReleaseUntil = now + 400
		end

		if (self.followCamPitchReleaseUntil > now) then
			-- user is controlling camera: track position but don't override
			self.followCamLastCameraPitch = currentPitch
			self.followCamLastTargetPitch = activeTargetPitch
			self._lastCamApplyTime = now
			return true
		end

		-- lerp toward target each frame for smooth transition
		-- (SetCamPitchSmooth does not drive grounded camera pitch)
		local lerpedPitch = currentPitch + (activeTargetPitch - currentPitch) * 0.12
		if (Player.SetCamPitch) then
			Player:SetCamPitch(lerpedPitch)
		end
		self.followCamLastCameraPitch = lerpedPitch
		self.followCamLastTargetPitch = activeTargetPitch
		self._lastCamApplyTime = now
		return true
	end

	-- flight / diving: smooth cam handles it natively
	if (Player.SetCamPitchSmooth) then
		Player:SetCamPitchSmooth(targetPitch)
		return true
	end
	if (Player.SetCamPitch) then
		Player:SetCamPitch(targetPitch)
		return true
	end
	return true
end

function ml_navigation:ApplyFlightFollowCam(targetX, targetY, targetZ)
	if (not (Player and Player.SetCamHSmooth)) then
		return false
	end
	local cam = Player.camera
	if (not table.valid(cam) or cam.x == nil or cam.z == nil or cam.h == nil) then
		return false
	end

	local targetHeading = math.atan2((targetX - cam.x), (targetZ - cam.z))
	if (targetHeading == nil) then
		return false
	end
	targetHeading = ConvertHeading(targetHeading + math.pi) % (2 * math.pi)
	Player:SetCamHSmooth(targetHeading)

	if (Player.SetCamPitchSmooth and cam.y ~= nil) then
		local dx = (targetX - cam.x)
		local dz = (targetZ - cam.z)
		local horizontal = math.sqrt((dx * dx) + (dz * dz))
		if (horizontal > 0.001) then
			self:ApplyFollowCamPitch(targetY)
		end
	end
	return true
end

function ml_navigation:CancelFlightFollowCam()
	self.followCamPitchReleaseUntil = 0
	self.followCamLastCameraPitch = nil
	self.followCamLastTargetPitch = nil
	self._lastCamApplyTime = 0
	if (not Player) then
		return
	end
	if (Player.SetCamHSmooth) then
		Player:SetCamHSmooth(false)
	end
	if (Player.SetCamPitchSmooth) then
		Player:SetCamPitchSmooth(false)
	end
end

function ml_navigation:ResetAutoFollowState()
	self.autoFollowNodeKey = nil
	self.autoFollowLastSet = 0
end

function ml_navigation:IsAutoFollowActive()
	return (self:UseAutoFollowPathing() and Player and Player.IsAutoFollowOn and Player:IsAutoFollowOn())
end

function ml_navigation:DisableAutoFollow(force, source)
	navDebug("[NAV_DEBUG] DisableAutoFollow force=" .. tostring(force) .. " source=" .. tostring(source))
	-- Always disable autofollow if it's actually active, regardless of UseAutoFollowPathing.
	-- The setting gates whether normal navigation *dispatches* autofollow, but cleanup
	-- must always work — autofollow may have been enabled by MoveToExact or other code.
	if (Player and Player.SetAutoFollowOn) then
		if (force or (Player.IsAutoFollowOn and Player:IsAutoFollowOn())) then
			Player:SetAutoFollowOn(false)
		end
	end
	self:ResetAutoFollowState()
end

function ml_navigation:DispatchAutoFollowNode(node, force)
	if (not self:UseAutoFollowPathing()) then
		return false
	end
	if (not node or not Player or not Player.SetAutoFollowPos or not Player.SetAutoFollowOn) then
		return false
	end

	local now = Now()
	local key = tostring(math.round(node.x, 2)) .. ":" .. tostring(math.round(node.y, 2)) .. ":" .. tostring(math.round(node.z, 2)) .. ":" .. tostring(self.pathindex)
	if (force or key ~= self.autoFollowNodeKey or TimeSince(self.autoFollowLastSet) >= self.autoFollowRefreshMs) then
		local autoFollowY = node.y
		if (not IsFlying() and not IsDiving() and Player and Player.pos and Player.pos.y ~= nil) then
			autoFollowY = Player.pos.y
		end
		Player:SetAutoFollowPos(node.x, autoFollowY, node.z)
		self.autoFollowNodeKey = key
		self.autoFollowLastSet = now
	end

	if (not IsFlying() and not IsDiving()) then
		self:ApplyFollowCamPitch()
	end

	if (not Player.IsAutoFollowOn or not Player:IsAutoFollowOn()) then
		Player:SetAutoFollowOn(true)
	end
	return true
end

function ml_navigation:GetHeadingDeltaAbs(currentHeading, targetHeading)
	if (currentHeading == nil or targetHeading == nil) then
		return math.huge
	end
	local diff = targetHeading - currentHeading
	while (diff > math.pi) do
		diff = diff - (2 * math.pi)
	end
	while (diff < -math.pi) do
		diff = diff + (2 * math.pi)
	end
	return math.abs(diff)
end

function ml_navigation:IsFacingHeading(targetHeading, epsilon)
	if (not Player or not Player.pos or targetHeading == nil) then
		return false
	end
	return self:GetHeadingDeltaAbs(Player.pos.h, targetHeading) <= (epsilon or 0.01)
end

function ml_navigation:IsFacingTarget(targetX, targetY, targetZ, angleEpsilon)
	if (not Player or not Player.pos) then
		return false
	end
	local ppos = Player.pos
	local dx = targetX - ppos.x
	local dz = targetZ - ppos.z
	if (math.abs(dx) < 0.001 and math.abs(dz) < 0.001) then
		return true
	end
	local angleDiff = math.angle({x = math.sin(ppos.h), y = 0, z = math.cos(ppos.h)}, {x = dx, y = 0, z = dz})
	return angleDiff <= (angleEpsilon or 2)
end

function ml_navigation:TryFaceHeading(targetHeading, epsilon)
	if (self:IsAutoFollowActive() or targetHeading == nil) then
		return false
	end
	if (self:IsFacingHeading(targetHeading, epsilon)) then
		return false
	end
	Player:SetFacing(targetHeading)
	return true
end

function ml_navigation:TryFaceTarget(targetX, targetY, targetZ, angleEpsilon)
	if (self:IsAutoFollowActive()) then
		return false
	end
	if (self:IsFacingTarget(targetX, targetY, targetZ, angleEpsilon)) then
		return false
	end
	Player:SetFacing(targetX, targetY, targetZ)
	return true
end

function ml_navigation.SmoothFaceTarget(targetX, targetY, targetZ)
	if (ml_navigation:UseFlightFollowCam()) then
		ml_navigation:ApplyFlightFollowCam(targetX, targetY, targetZ)
		return
	end
	if (not IsFlying() and not IsDiving()) then
		ml_navigation:ApplyFollowCamPitch()
	end
	if (ml_navigation:UseAutoFollowPathing()) then
		return
	end
	if (ml_navigation:IsFacingTarget(targetX, targetY, targetZ, 2)) then
		return
	end
	Player:SetFacing(targetX, targetY, targetZ, true)
end

function ml_navigation:EnforceGroundFollowCamPitch()
	if (not self:UseFollowCamPitch() or IsFlying() or IsDiving()) then
		return
	end
	if (not self.canPath or self.debug or not table.valid(self.path)) then
		return
	end
	local nextnode = self.path[self.pathindex]
	if (nextnode and nextnode.y ~= nil) then
		self:ApplyFollowCamPitch()
	end
end

function ml_navigation.SyncFlightFollowCamSettings()
	if gFlightFollowCam ~= nil then
		ml_navigation.flightFollowCam = gFlightFollowCam
	end
	if gFlightFollowCamRatio ~= nil then
		ml_navigation.flightFollowCamRatio = gFlightFollowCamRatio
		if (Player and Player.SetSmoothCamRatio) then
			Player:SetSmoothCamRatio(gFlightFollowCamRatio)
		end
	end
	if gFlightFollowCamPitch ~= nil then
		ml_navigation.flightFollowCamPitch = gFlightFollowCamPitch
	end
	if gFlightFollowCamPitchDownRatio ~= nil then
		ml_navigation.flightFollowCamPitchDownRatio = gFlightFollowCamPitchDownRatio
	end
end
RegisterEventHandler("Module.Initalize", ml_navigation.SyncFlightFollowCamSettings, "ml_navigation.SyncFlightFollowCamSettings")

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
	return 0
end

-- Performs some raycasting for awkward-edge encounters.
function ml_navigation.GetClearance(nodepos)
	local ppos = Player.pos
	
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
function ml_navigation:IsGoalClose(ppos,node,lastnode)
	local goaldist,goaldist2d = ml_navigation:GetRaycast_Player_Node_Distance(ppos,node)
	local lastdist,lastdist2d,lastgoal,lastgoal2d;
	if (table.valid(lastnode)) then
		lastdist,lastdist2d = ml_navigation:GetRaycast_Player_Node_Distance(lastnode,ppos)
		lastgoal,lastgoal2d = ml_navigation:GetRaycast_Player_Node_Distance(lastnode,node)
	end
	local isLast = (ml_navigation.path[ml_navigation.pathindex+1]==nil)
	local clear3d,clear2d = ml_navigation.GetClearance(node)
	
if (goaldist2d < 2 and goaldist < 6) then
		if (clear3d < goaldist) then
			goaldist = clear3d
		end
		if (clear2d < goaldist2d) then
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
			if (nc.details and nc.details.subtype) then
				ncsubtype = nc.details.subtype
			end
		end
		if (nc and nc.type ~= 5) then -- Type 5 == MacroMesh
			local ncradius
			if(node.navconnectionsideA ~= nil ) then -- new nav code, NCs have sideA and sideB which can have different radii				
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
			
			if (nc.type == 3) then
				-- Floor-cube connections: use height-gated radius to prevent premature 3D sphere trigger
				-- Applies whether flying, mounted (about to fly), or on foot approaching flight transition
				goaldist2d = goaldist2d - ncradius
				if (math.abs(ppos.y-node.y) < 3) then -- some of the connection radius' are too big, don't want a full on sphere
					goaldist = goaldist - ncradius
				end
			else
				goaldist = goaldist - ncradius
				goaldist2d = goaldist2d - ncradius
			end
		end
	end
	
	if (Player.flying.isflying) then
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dfly"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dfly"]) then
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
			if (isLast or lastdist == nil or lastdist >= lastgoal or goaldist <= 1.0) then
				--d("lastdist2d ["..tostring(lastdist2d).."] >= ["..tostring(lastgoal2d).."]")
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
		end
	else
		--d("goaldist "..tostring(goaldist).. " < = "..tostring(ml_navigation.NavPointReachedDistances["3dwalk"]).." and " ..tostring(goaldist2d).." < = " ..tostring(ml_navigation.NavPointReachedDistances["2dwalk"]))
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dwalk"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
			if (isLast or lastdist == nil or lastdist >= lastgoal or goaldist <= 1.0) then
				--d("lastdist2d ["..tostring(lastdist2d).."] >= ["..tostring(lastgoal2d).."]")
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
		end
	end
	self.omc_direction = 0
	return false
end

-- Are there more flying nodes so we can continue flying instead of landing uselessly?
function ml_navigation:CanContinueFlying()
	if (table.valid(self.path)) then
		local dist = math.distance3d(Player.pos,ml_navigation.targetposition)
		local pathsize = table.size(self.path)
		if (dist > 15) then
			for index,node in pairsByKeys(self.path) do
				if (index > self.pathindex and (node.type == GLOBAL.NODETYPE.CUBE) and 
					(dist > 30 or IsNull(node.flags,0) == 0 or (node.flags and bit.band(node.flags, GLOBAL.CUBE.AIR) ~= 0))) 
				then
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
	-- Active OMC in progress (any type, including floor-cube type 3)
	if (self.omc_id and self.omc_details) then
		return true
	end
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
				-- Type 1 is cube-cube (diving->water transitions), type 3 is floor-cube (flight transitions)
			if ( nc and (nc.type == 1 or nc.type == 3) ) then
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
	
	if (not IsFlying() and not IsDiving() and ((Player.incombat and not Player.ismounted) or IsTransporting())) then
		cubefilters = bit.bor(cubefilters, GLOBAL.CUBE.AIR)
	end
	NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.CUBE, cubefilters)
	NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.FLOOR, floorfilters)
	if In(Player.localmapid,1237) then
		local retval = Transport1237(pos,pos2)
		if (retval == true) then
			reachable = true
		end
	end
		
	local _t0 = os.clock() * 1000
	local reachable = NavigationManager:IsReachable(pos2)
	local _dt = os.clock() * 1000 - _t0
	if (_dt > 1) then
		--d("[QPerf] CheckPath->IsReachable: " .. string.format("%.2f", _dt) .. "ms result=" .. tostring(reachable))
	end
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
ml_navigation.lastMoveToPos = nil
ml_navigation.lastMoveToExactPos = nil

function Player:MoveTo(x, y, z, dist, floorfilters, cubefilters, targetid)	
	local floorfilters = IsNull(floorfilters,0,true)
	local cubefilters = IsNull(cubefilters,0,true)
	
	-- Cancel any active MoveToExact when normal MoveTo is called
	if (ml_navigation_exact.active) then
		Player:StopExact()
	end
	
	if (MPlayerDriving()) then
		d("[NAVIGATION]: Releasing control to Player..")
		ml_navigation:ResetCurrentPath()
		return -1337
	end
	
	-- Spam guard: skip redundant path build if destination hasn't changed
	local lastPos = ml_navigation.lastMoveToPos
	if (lastPos and lastPos.x == x and lastPos.y == y and lastPos.z == z and ml_navigation:HasPath()) then
		return table.size(ml_navigation.path)
	end
	ml_navigation.lastMoveToPos = { x = x, y = y, z = z }
	
	--d("moveto: path to ["..tostring(x)..","..tostring(y)..","..tostring(z)..",floor:"..tostring(floorfilters)..",cube:"..tostring(cubefilters)..",tid:"..tostring(targetid))
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
ml_navigation.lastBuildCall = 0
ml_navigation.lastpos = {x=0, y=0, z=0}
function Player:BuildPath(x, y, z, floorfilters, cubefilters, targetid, force)
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
	
	if (x == nil or y == nil or z == nil) then -- yes this happens regularly inside fates, because some of the puzzle code calls moveto nil/nil/nil
		d("[NAVIGATION]: Invalid Move To Position :["..tostring(x)..","..tostring(y)..","..tostring(z).."]")
		return 0
	end
	
	local ppos = Player.pos	
	local newGoal = { x = x, y = y, z = z }
	
	local hasCurrentPath = table.valid(ml_navigation.path)
	local currentPathSize = table.size(ml_navigation.path)
	local sametarget = ml_navigation.lasttargetid and targetid and ml_navigation.lasttargetid == targetid -- needed, so it doesnt constantly pull a new path n doing a spinny dance on the navcon startpoint when following a moving target 
	local hasPreviousPath = hasCurrentPath and table.valid(newGoal) and table.valid(ml_navigation.targetposition) and ( (not sametarget and math.distance3d(newGoal,ml_navigation.targetposition) < 1) or sametarget )
	if (hasPreviousPath and (ml_navigation.lastconnectionid ~= 0 or ffnav.isascending or ffnav.isdescending) and (TimeSince(ml_navigation.lastconnectiontimer) < 5000)) then
		d("[NAVIGATION]: We are currently using a Navconnection / ascending / descending, wait until we finish to pull a new path.")
		return currentPathSize
	end
	if not force and (((newGoal.x == ml_navigation.lastpos.x and newGoal.z == ml_navigation.lastpos.z) or ((IsFlying() or IsDiving()) and targetid ~= nil and targetid == ml_navigation.lasttargetid))
		 and (hasPreviousPath and (TimeSince(ml_navigation.lastBuildCall) < 2000))) then
		--d("[NAVIGATION]: We have a recent path, dont call again. (causes double backs)")
		return currentPathSize
	end
	
	local distanceToGoal = math.distance2d(newGoal.x,newGoal.z,ppos.x,ppos.z)
	
	-- Landing clearance: if a fallback is active, redirect the path goal.
	-- The actual clearance probe runs in the nav loop at descent time.
	if (ffnav.landingFallbackActive and ffnav.landingFallbackPos) then
		if (ffnav.landingFallbackOrigin and math.distance3d(ffnav.landingFallbackOrigin, newGoal) < 3) then
			newGoal = { x = ffnav.landingFallbackPos.x, y = ffnav.landingFallbackPos.y, z = ffnav.landingFallbackPos.z }
			x, y, z = newGoal.x, newGoal.y, newGoal.z
		elseif (math.distance3d(ffnav.landingFallbackPos, newGoal) < 1) then
			-- Already targeting fallback
		else
			-- Destination changed, clear stale fallback
			ffnav.landingFallbackActive = false
			ffnav.landingFallbackPos = nil
			ffnav.landingFallbackOrigin = nil
		end
	end
	
	-- Filter things for special tasks/circumstances
	if ((not IsFlying() and not IsDiving() and ((Player.incombat and (not Player.ismounted)) or IsTransporting())) or 
		not CanFlyInZone()) 
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
	
	--d("building path to ["..tostring(newGoal.x)..","..tostring(newGoal.y)..","..tostring(newGoal.z)..",floor:"..tostring(floorfilters)..",cube:"..tostring(cubefilters)..",tid:"..tostring(targetid))
	local ret = ml_navigation:MoveTo(newGoal.x,newGoal.y,newGoal.z, targetid)

	ml_navigation.lastPathUpdate = Now()
	ml_navigation.lastconnectionid = 0
	ml_navigation.lastconnectiontimer = 0
	
	if (ret <= 0) then
		if ((IsFlying() or IsDiving()) and hasPreviousPath) then
			d("[NAVIGATION]: Encountered an issue on path pull, using previous path, errors may be encountered here.")
			return currentPathSize
		else
			ml_navigation:ResetCurrentPath()
		end
		local ppos = Player.pos
		ml_navigation.startposition = { x=0, y=0, z=0 }
		ml_navigation.targetposition = { x=0, y=0, z=0 }
		ml_navigation.lasttargetid = nil
	else
		ml_navigation.startposition = { x=ppos.x, y=ppos.y, z=ppos.z }
		ml_navigation.targetposition = newGoal
		ml_navigation.lasttargetid = targetid	
	end
	
	if (ret > 0 and hasCurrentPath) then
		for _,node in pairs(ml_navigation.path) do
			ml_navigation.TagNode(node)
		end
	end
	
	--table.print(ml_navigation.path)
	ml_navigation.lastBuildCall = Now()
	ml_navigation.lastpos = newGoal
	return ret
end

-- MoveToExact: Precise combat-oriented movement. Ground-only, autofollow-only, tight threshold, no path rebuilding.
-- Returns: positive number = path node count (immediate), 0 = path pending (async), -1 = failure
function Player:MoveToExact(x, y, z, threshold)
	if (not x or not y or not z) then return -1 end
	
	local thresh = threshold or 0.2
	
	local ep = ml_navigation_exact
	if (ep.active and ep.path ~= nil) then
		local enddata = ep.path[#ep.path]
		if (enddata~=nil) then
			local endpos = {x=enddata.x,y=enddata.y,z=enddata.z}
			if (math.distance3d(endpos,{x=x,y=y,z=z})<= thresh) then
				d("path requested for same destination, ignore request and keep naving")
				return
			end
		end
	end

	-- Ensure no stale autofollow/brake state is carried into a restart.
	if (ml_navigation and ml_navigation.DisableAutoFollow) then
		ml_navigation:DisableAutoFollow(true, "MoveToExact start")
	end
	
	-- Cancel any active normal navigation
	if (ml_navigation.canPath) then
		ml_navigation:DisablePathing()
	end
	
	-- Reset any prior exact state
	ml_navigation_exact.Reset()
	
	local ppos = Player.pos
	if (not ppos) then return -1 end
	local goal = { x = x, y = y, z = z }
	local cacheId = BuildMoveToExactCacheId(ppos, goal)
	
	-- Exclude AIR and WATER cubes — ground only
	if (GLOBAL and GLOBAL.CUBE) then
		local cubeExclude = 0
		if (GLOBAL.CUBE.AIR) then cubeExclude = bit.bor(cubeExclude, GLOBAL.CUBE.AIR) end
		if (GLOBAL.CUBE.WATER) then cubeExclude = bit.bor(cubeExclude, GLOBAL.CUBE.WATER) end
		if (cubeExclude ~= 0) then
			NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.CUBE, cubeExclude)
		end
	end
	
	d("[MoveToExact]: Requesting fresh path. cacheId=" .. tostring(cacheId))
	local result = NavigationManager:GetPathAsync(ppos.x, ppos.y, ppos.z, x, y, z, cacheId, false, true)
	
	if (type(result) == "table" and table.valid(result)) then
		-- Cache hit — path available immediately
		ml_navigation_exact.path = result
		ml_navigation_exact.pathindex = 1
		ml_navigation_exact.active = true
		ml_navigation_exact.pending = false
		ml_navigation_exact.pendingCacheId = nil
		ml_navigation_exact.threshold = thresh
		ml_navigation_exact.targetposition = goal
		ml_navigation_exact.lastRequestId = cacheId
		for _, node in pairs(ml_navigation_exact.path) do
			ml_navigation.TagNode(node)
		end
		-- Optimize path: remove skippable intermediate nodes via raycast shortcuts
		ml_navigation_exact.OptimizeCachedPath(ppos)
		return table.size(ml_navigation_exact.path)
	elseif (type(result) == "number" and result > 0) then
		-- Request enqueued — path will arrive on a subsequent tick
		ml_navigation_exact.active = true
		ml_navigation_exact.pending = true
		ml_navigation_exact.pendingGoal = goal
		ml_navigation_exact.pendingCacheId = cacheId
		ml_navigation_exact.threshold = thresh
		ml_navigation_exact.targetposition = goal
		ml_navigation_exact.lastRequestId = cacheId
		d("[MoveToExact]: Path queued. cacheId=" .. tostring(cacheId))
		return 0
	else
		-- Failure
		d("[MoveToExact]: Path request failed. cacheId=" .. tostring(cacheId))
		return -1
	end
end

function Player:StopExact()
	navDebug("[NAV_DEBUG] Player:StopExact called")
	local wasActive = ml_navigation_exact.active
	ml_navigation_exact.Reset()
	ml_navigation.lastMoveToPos = nil
	if (wasActive) then
		Player:StopMovement()
		local brakePending = (Player.IsAutoFollowBrakePending and Player:IsAutoFollowBrakePending())
		if (not brakePending) then
			ml_navigation:DisableAutoFollow(true, "StopExact")
		end
	end
end

function Player:IsExactMoving()
	return ml_navigation_exact.active
end

function ml_navigation_exact.Reset()
	ml_navigation_exact.path = {}
	ml_navigation_exact.pathindex = 0
	ml_navigation_exact.targetposition = nil
	ml_navigation_exact.active = false
	ml_navigation_exact.pending = false
	ml_navigation_exact.pendingGoal = nil
	ml_navigation_exact.pendingCacheId = nil
	ml_navigation_exact.threshold = 0.2
	ml_navigation.lastMoveToExactPos = nil
	ml_navigation_exact.omc_id = nil
	ml_navigation_exact.omc_details = nil
	ml_navigation_exact.omc_direction = 0
	ml_navigation_exact.omc_starttimer = 0
	ml_navigation_exact.omc_traveltimer = nil
	ml_navigation_exact.omc_traveldist = 0
	ml_navigation_exact.omc_startheight = nil
	ml_navigation_exact.ensureposition = nil
	ml_navigation_exact.ensurepositionstarttime = nil
	ml_navigation_exact.lastupdate = 0
	ml_navigation_exact.autoFollowNodeKey = nil
	ml_navigation_exact.autoFollowLastSet = 0
	ml_navigation_exact.autoFollowLastEnableAttempt = 0
	ml_navigation_exact.autoFollowBrakeWaitLogged = false
	ml_navigation_exact.reachedLogged = false
	ml_navigation_exact.completed = false
	ml_navigation_exact.lastOptimize = 0
	ml_navigation_exact.lastRequestId = nil
end

function ml_navigation_exact.ResetOMCState()
	ml_navigation_exact.omc_id = nil
	ml_navigation_exact.omc_details = nil
	ml_navigation_exact.omc_direction = 0
	ml_navigation_exact.omc_starttimer = 0
	ml_navigation_exact.omc_traveltimer = nil
	ml_navigation_exact.omc_traveldist = 0
	ml_navigation_exact.omc_startheight = nil
	ml_navigation_exact.ensureposition = nil
	ml_navigation_exact.ensurepositionstarttime = nil
end

function ml_navigation_exact.ResetAutoFollowState()
	ml_navigation_exact.autoFollowNodeKey = nil
	ml_navigation_exact.autoFollowLastSet = 0
end

-- Run C++ OptimizePath on the cached path and update our Lua path table.
-- This removes skippable intermediate nodes via raycast shortcuts.
-- Only safe to call on initial path receipt (pathindex <= 1) because the C++
-- OptimizePath relies on m_Path_CurrentIndex which MoveToExact doesn't control.
-- Returns true if the path was updated.
function ml_navigation_exact.OptimizeCachedPath(ppos)
	local self = ml_navigation_exact
	local tp = self.targetposition
	if (not tp or not ppos or not table.valid(self.path)) then return false end
	
	local optimized = NavigationManager:OptimizePath(ppos.x, ppos.y, ppos.z, tp.x, tp.y, tp.z)
	if (type(optimized) ~= "table" or not table.valid(optimized)) then return false end
	
	-- Tag all nodes in the new path
	for _, node in pairs(optimized) do
		ml_navigation.TagNode(node)
	end
	
	self.path = optimized
	self.pathindex = 1
	self.lastOptimize = Now()
	return true
end

-- Dispatch autofollow for MoveToExact with guarded Y targeting.
function ml_navigation_exact.GetDispatchTargetY(node, ppos)
	if (not node) then
		return (ppos and ppos.y) or nil
	end
	local targetY = node.y or (ppos and ppos.y)
	if (targetY and ppos and ppos.y and math.abs(targetY - ppos.y) > (ml_navigation_exact.maxDispatchYDelta or 8)) then
		targetY = ppos.y
	end
	return targetY
end

-- Dispatch autofollow for MoveToExact with guarded Y targeting.
function ml_navigation_exact.DispatchAutoFollow(node, ppos, force)
	if (not node or not Player or not Player.SetAutoFollowPos or not Player.SetAutoFollowOn) then
		return false
	end
	local now = Now()
	local key = tostring(math.round(node.x, 2)) .. ":" .. tostring(math.round(node.z, 2)) .. ":" .. tostring(ml_navigation_exact.pathindex)
	local targetY = ml_navigation_exact.GetDispatchTargetY(node, ppos)
	if (force or key ~= ml_navigation_exact.autoFollowNodeKey or TimeSince(ml_navigation_exact.autoFollowLastSet) >= ml_navigation_exact.autoFollowRefreshMs) then
		Player:SetAutoFollowPos(node.x, targetY, node.z)
		ml_navigation_exact.autoFollowNodeKey = key
		ml_navigation_exact.autoFollowLastSet = now
	end
	
	local brakePending = (Player.IsAutoFollowBrakePending and Player:IsAutoFollowBrakePending())
	if (brakePending) then
		if (not ml_navigation_exact.autoFollowBrakeWaitLogged) then
			d("[MoveToExact]: Waiting for AutoFollow brake to clear before enabling.")
			ml_navigation_exact.autoFollowBrakeWaitLogged = true
		end
		return true
	end
	
	if (ml_navigation_exact.autoFollowBrakeWaitLogged) then
		ml_navigation_exact.autoFollowBrakeWaitLogged = false
		d("[MoveToExact]: AutoFollow brake cleared.")
	end
	
	-- Only turn autofollow on as needed, but throttle retries to avoid enable spam.
	if ((not Player.IsAutoFollowOn or not Player:IsAutoFollowOn()) and TimeSince(ml_navigation_exact.autoFollowLastEnableAttempt) >= ml_navigation_exact.autoFollowEnableRetryMs) then
		Player:SetAutoFollowPos(node.x, targetY, node.z)
		ml_navigation_exact.autoFollowNodeKey = key
		ml_navigation_exact.autoFollowLastSet = now
		Player:SetAutoFollowOn(true)
		ml_navigation_exact.autoFollowLastEnableAttempt = now
	end
	return true
end

-- Overriding  the (old) c++ Player:Stop(), to handle the additionally needed navigation functions
function Player:Stop(resetpath)
	-- Protect freshly-enabled pathing from being immediately killed by external callers
	if (ml_navigation.canPath and ml_navigation.lastEnablePathingTime > 0 and TimeSince(ml_navigation.lastEnablePathingTime) < 200) then
		navDebug("[NAV_DEBUG] Player:Stop BLOCKED - path protection window (" .. tostring(TimeSince(ml_navigation.lastEnablePathingTime)) .. "ms since EnablePathing)")
		return
	end
	navDebug("[NAV_DEBUG] Player:Stop called")
	--local resetpath = IsNull(resetpath,true)
	-- Resetting the path can cause some problems with macro nodes.
	-- On occassion it will enter a circular loop if something in the path calls a stop (like mounting).
	ml_navigation:CancelFlightFollowCam()
	
	-- StopMovement MUST run before DisableAutoFollow so C++ sees AutoFollow still active
	-- and properly halts the player (including flight momentum). If AutoFollow is already
	-- off when StopMovement runs, it only clears keystates and the player keeps gliding.
	Player:StopMovement()	-- The "new" c++ sided STOP which stops the player's movement completely
	local brakePending = (Player.IsAutoFollowBrakePending and Player:IsAutoFollowBrakePending())
	if (brakePending) then
		ml_navigation:ResetAutoFollowState()
	else
		ml_navigation:DisableAutoFollow(true, "Stop")
	end
	
	ffnav.isascending = false
	ffnav.isdescending = false	
	ffnav.descentAttempts = 0
	ffnav.landingProbeCache = {}
	ffnav.landingFallbackActive = false
	ffnav.landingFallbackPos = nil
	ffnav.landingFallbackOrigin = nil
	ml_navigation.lastconnectionid = 0
	ml_navigation.lastconnectiontimer = 0
	ml_navigation:ResetFlightActionThrottle(true)
	ml_navigation.lasttargetid = nil
	NavigationManager:ResetPath()
	ml_navigation:ResetCurrentPath()
	ml_navigation.receivedInstructions = {}
	ml_navigation:ResetOMCHandler()
	navDebug("[NAV_DEBUG] canPath=false via Player:Stop")
	ml_navigation.canPath = false
	ffnav.yield = {}
	ffnav.process = {}
end

-- This should be used instead of Stop() if the path and all of it's info should remain and we are only stopping to perform a task en-route (like mounting).
-- This ensures that the navigation pathfinder doesn't do a loopback incase a macro node is a bit off course.
function Player:PauseMovement(param1, param2, param3, param4, param5)
	local param1 = IsNull(param1, 1500)
	local param2 = IsNull(param2, function () return not Player:IsMoving() end)
	
	navDebug("[NAV_DEBUG] canPath=false via Player:PauseMovement")
	ml_navigation.canPath = false
	ml_navigation:CancelFlightFollowCam()
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

			node.air = false
			node.water = false
			node.air_avoid = false
		elseif (node.is_cube) then
			--node.air = (bit.band(flags, GLOBAL.CUBE.AIR) ~= 0)   -- doesn't work, due to flags sometimes returning 0, needs c++ fix
			node.air = (bit.band(flags, GLOBAL.CUBE.AIR) ~= 0 or IsNull(flags,0) == 0)
			node.water = (bit.band(flags, GLOBAL.CUBE.WATER) ~= 0)
			node.air_avoid = (bit.band(flags, GLOBAL.CUBE.AVOID) ~= 0)

			node.ground = false
			node.ground_water = false
			node.ground_border = false
			node.ground_avoid = false
		end

		node.cubecube = false
		node.floorfloor = false
		node.floorcube = false

		if (node.navconnectionid and node.navconnectionid ~= 0) then
			local navcon = NavigationManager:GetNavConnection(node.navconnectionid)
			if (navcon) then
				node.cubecube = (navcon.type == 1)
				node.floorfloor = (navcon.type == 2)
				node.floorcube = (navcon.type == 3)
			end
		end

		node.is_tagged = true
	end
end

function ml_navigation:GetFlightTransitionKey(pathindex, nextnode, nextnextnode)
	local n1 = nextnode or {}
	local n2 = nextnextnode or {}
	local n1tags = string.format("fc:%d,a:%d,g:%d,c:%d", n1.floorcube and 1 or 0, n1.air and 1 or 0, n1.ground and 1 or 0, n1.is_cube and 1 or 0)
	local n2tags = string.format("fc:%d,a:%d,g:%d,c:%d", n2.floorcube and 1 or 0, n2.air and 1 or 0, n2.ground and 1 or 0, n2.is_cube and 1 or 0)
	return tostring(pathindex) .. "|" .. tostring(n1.navconnectionid or 0) .. "|" .. tostring(n2.navconnectionid or 0) .. "|" .. n1tags .. "|" .. n2tags
end

function ml_navigation:IsUnstableFlightTransition(nextnode, nextnextnode)
	if (not nextnode) then
		return false
	end

	local nextAir = (nextnode.air == true)
	local nextGround = (nextnode.ground == true)
	local nextFloorCube = (nextnode.floorcube == true)

	local n2Air = (nextnextnode and nextnextnode.air == true) or false
	local n2Ground = (nextnextnode and nextnextnode.ground == true) or false
	local n2FloorCube = (nextnextnode and nextnextnode.floorcube == true) or false

	-- Avoid flight actions when the immediate window looks like an air->ground snap.
	if (nextFloorCube and nextAir and nextGround) then
		return true
	end

	if (nextFloorCube and nextAir and n2FloorCube and n2Ground and not n2Air) then
		return true
	end

	return false
end

function ml_navigation:IsFlightActionThrottled(action, pathindex, nextnode, nextnextnode)
	if (not ffnav.flightLoopGuard) then
		ffnav.flightLoopGuard = { key = nil, lastAction = nil, lastTime = 0, count = 0, lockUntil = 0 }
	end

	local guard = ffnav.flightLoopGuard
	local now = Now()
	if (now < (guard.lockUntil or 0)) then
		return true
	end

	local key = self:GetFlightTransitionKey(pathindex, nextnode, nextnextnode)
	if (guard.key == key and TimeSince(guard.lastTime or 0) < 3500) then
		if (guard.lastAction ~= action or action == "mount_fail") then
			guard.count = (guard.count or 0) + 1
		end
	else
		guard.count = 0
	end

	guard.key = key
	guard.lastAction = action
	guard.lastTime = now

	if ((guard.count or 0) >= 4) then
		guard.lockUntil = now + 2500
		guard.count = 0
		d("[Navigation] - Flight transition loop detected, throttling actions for 2500ms.")
		return true
	end

	return false
end

function ml_navigation:ResetFlightActionThrottle(clearLock)
	if (not ffnav.flightLoopGuard) then
		ffnav.flightLoopGuard = { key = nil, lastAction = nil, lastTime = 0, count = 0, lockUntil = 0 }
		return
	end

	ffnav.flightLoopGuard.key = nil
	ffnav.flightLoopGuard.lastAction = nil
	ffnav.flightLoopGuard.lastTime = 0
	ffnav.flightLoopGuard.count = 0
	if (clearLock) then
		ffnav.flightLoopGuard.lockUntil = 0
	end
end

-- Handles the actual Navigation along the current Path. Is not supposed to be called manually! 
-- Also handles OMCs
ml_navigation.lastconnectionid = 0
ml_navigation.lastconnectiontimer = 0
ml_navigation.lasttargetid = nil
ml_navigation.path = {}
ml_navigation.pathindex = 0
ml_navigation.lastindexgoal = {}
function ml_navigation.Navigate(event, ticks )	
	-- MoveToExact priority guard — when exact movement is active, run its handler instead
	if (ml_navigation_exact.active) then
		ml_navigation_exact.Navigate(event, ticks)
		return
	end
	
	local self = ml_navigation
	if ((ticks - (ml_navigation.lastupdate or 0)) > 50) then 
		ml_navigation.lastupdate = ticks
		if (not (ml_navigation.CanRun() and ml_navigation.canPath and not ml_navigation.debug)) then
			return
		end
				
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
						ml_navigation._refreshPrefetched = false
						return -- needed here, or you can check again for navpath / index valid ...your choice
					end
					-- Prefetch path ~1s before the 2s refresh so BuildPath hits warm cache
					if (not ml_navigation:IsUsingConnection() and TimeSince(ml_navigation.lastPathUpdate) >= 1000 and not ml_navigation._refreshPrefetched) then
						ml_navigation._refreshPrefetched = true
						local tp = ml_navigation.targetposition
						if (tp) then
							NavigationManager:GetPathAsync(ppos.x, ppos.y, ppos.z, tp.x, tp.y, tp.z, 0, true)
						end
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
					
					local lastnode = ml_navigation.path[ml_navigation.pathindex - 1]
					if (lastnode == nil) then 
						lastnode = ml_navigation.startposition 
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
						local from_pos = nc.from
						local to_pos = nc.to
						local ncradius
						local ncsubtype
						local from_heading
						
						if (nc.sideA ~= nil) then
							from_pos = nc.sideA
							to_pos = nc.sideB
						end
						
						if (self.omc_direction == 0) then
							if (math.distance3d(ppos, from_pos) < math.distance3d(ppos, to_pos)) then
								self.omc_direction = 1
							else
								self.omc_direction = 2
							end
						end
						
						if (nc.sideA ~= nil) then
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
							local dist = math.distance3d(ppos,nextnode)
							-- Capture initial distance on first entry so progress detection works
							if (ml_navigation.omc_traveldist == 0) then
								ml_navigation.omc_traveldist = dist
							end
							if ( timepassed < 3000) then
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
									elseif (not ml_navigation:UseAutoFollowPathing()) then
										local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = to_pos.x-ppos.x, y = 0, z = to_pos.z-ppos.z})
										if ( anglediff > 0.3 ) then
											ml_navigation:TryFaceTarget(to_pos.x,to_pos.y,to_pos.z)
										end
									end
									
									if ( ml_navigation.omc_starttimer == 0 ) then
										ml_navigation.omc_starttimer = ticks	
										if (not Player:IsMoving()) then
											if (not ml_navigation:DispatchAutoFollowNode(to_pos, true)) then
												Player:Move(FFXIV.MOVEMENT.FORWARD)
											end
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
												if (nextnextnode and not ml_navigation:UseAutoFollowPathing()) then
													ml_navigation:TryFaceTarget(nextnextnode.x,nextnextnode.y,nextnextnode.z)
												end
												ml_navigation.pathindex = ml_navigation.pathindex + 1
												NavigationManager.NavPathNode = ml_navigation.pathindex
												ml_navigation:ResetAutoFollowState()
												ml_navigation:ResetOMCHandler()												
												d("[Navigation]: [Jumping] - Landed at End of Navconnection.")
											end
										else
											Player:StopMovement()
											if (nextnextnode and not ml_navigation:UseAutoFollowPathing()) then
												ml_navigation:TryFaceTarget(nextnextnode.x,nextnextnode.y,nextnextnode.z)
											end
											ml_navigation.pathindex = ml_navigation.pathindex + 1
											NavigationManager.NavPathNode = ml_navigation.pathindex
											ml_navigation:ResetAutoFollowState()
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
													if (nextnextnode and not ml_navigation:UseAutoFollowPathing()) then
														ml_navigation:TryFaceTarget(nextnextnode.x,nextnextnode.y,nextnextnode.z)
													end
													ml_navigation.pathindex = ml_navigation.pathindex + 1
													NavigationManager.NavPathNode = ml_navigation.pathindex
													ml_navigation:ResetAutoFollowState()
													ml_navigation:ResetOMCHandler()
													d("[Navigation]: [Jumping] - Landed at End of Navconnection.")
												end
											else
												d("[Navigation]: [Jumping] - Failed to Reach End of Navconnection.")
												Player:Stop()
												
											end
											
										else
										
											if (not ml_navigation:DispatchAutoFollowNode(to_pos, true)) then
												Player:Move(FFXIV.MOVEMENT.FORWARD)
												if (not ml_navigation:UseAutoFollowPathing()) then
													ml_navigation:TryFaceTarget(to_pos.x,to_pos.y,to_pos.z)
												end
											end
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
							ml_navigation:NavigateToNode(ppos,nextnode,lastnode,1000)
							return
						end
						
						-- OMC Teleport						
						if ( ncsubtype == 3 ) then							
							ml_navigation.GUI.lastAction = "Teleport NavConnection"
							d("[EXACT-DBG] NAV:Teleport-OMC SetEnsureStartPosition")
							if ( ml_navigation:SetEnsureStartPosition(from_pos, ppos, nc, from_pos, to_pos, from_heading) ) then
								return
							end
							if (Player:IsMoving() or Player:IsJumping() ) then
								Player:StopMovement()
								if (not ml_navigation:UseAutoFollowPathing()) then
									ml_navigation:TryFaceTarget(to_pos.x,to_pos.y,to_pos.z)
								end
								ffnav.Await(1000, function () return not Player:IsMoving() and not Player:IsJumping() end)
								return
							else	
								if gTeleportHack then
									Hacks:TeleportToXYZ(to_pos.x, to_pos.y, to_pos.z)
									if (nextnextnode and not ml_navigation:UseAutoFollowPathing()) then
										ml_navigation:TryFaceTarget(nextnextnode.x,nextnextnode.y,nextnextnode.z)
									end
									ml_navigation.lastupdate = ml_navigation.lastupdate + math.random(500,1500)
									d(GetTickCount())
									--ffxiv_dialog_manager.IssueStopNotice("Teleport NavConnection","Teleport NavConnection exist on this mesh.\nPlease enable the Teleport (Hack) usage in Advanced Settings or remove them.")
								else 
									NavigationManager:DisableNavConnection(nc.id)
								end
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
							d("[EXACT-DBG] NAV:Portal-OMC SetEnsureStartPosition")
							if ( ml_navigation:SetEnsureStartPosition(from_pos, ppos, nc, from_pos, to_pos, from_heading) ) then
								return
							end
							ml_navigation:NavigateToNode(ppos,nextnode,lastnode,2000)
							return
						end
						
						-- OMC Custom
						if ( ncsubtype == 6 ) then
							
							ml_navigation.GUI.lastAction = "Custom OMC"
							ml_navigation:NavigateToNode(ppos,nextnode,lastnode,1500)	
							return							
						end
					end
					
					if (MIsLocked()) then
						ml_navigation:DisableAutoFollow(true, "MIsLocked")
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
							
							if (not ml_navigation:UseAutoFollowPathing()) then
								if (adjustedHeading ~= 0) then
									ml_navigation:TryFaceHeading(adjustedHeading)
								else
									local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = tpos.x-ppos.x, y = 0, z = tpos.z-ppos.z})
									if ( anglediff < 35 and dist3D > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
										ml_navigation.SmoothFaceTarget(tpos.x,tpos.y,tpos.z)
									else
										ml_navigation:TryFaceTarget(tpos.x,tpos.y,tpos.z)
									end
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
							local autoFollow = ml_navigation:DispatchAutoFollowNode(modifiedNode, true)
							if (not autoFollow and not Player:IsMoving()) then
								Player:Move(FFXIV.MOVEMENT.FORWARD)
								ffnav.Await(150, function () return Player:IsMoving() end)
							end
						else
							ml_navigation.GUI.lastAction = "Swimming underwater to Node"
							-- Check if we left our path
							if (not ml_navigation:IsStillOnPath(ppos,"3ddive")) then 
								ml_navigation:DisableAutoFollow(true, "dive-deviation")
								--d("we have left the path")
								return 
							end
															
							-- Check if the next node is reached:
							local dist3D = math.distance3d(nextnode,ppos)
							if ( ml_navigation:IsGoalClose(ppos,nextnode,lastnode)) then
								-- We reached the node
								--d("[Navigation] - Cube Node reached. ("..tostring(math.round(dist3D,2)).." < "..tostring(ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()])..")")	
								
								-- C++ is already optimizing / shortening the path wherever possible. You tried to do here the same thing with just one recast, where c++ has full access to cube n recast data and uses about 6 raycasts around the player object.
								-- C++ can suck it, lua4eva
								
								ml_navigation.lastconnectionid = nextnode.navconnectionid
								ml_navigation.lastconnectiontimer = Now()
								ml_navigation.pathindex = ml_navigation.pathindex + 1
								NavigationManager.NavPathNode = ml_navigation.pathindex
								ml_navigation:ResetAutoFollowState()
								
								
							else			
								--d("[Navigation]: Moving to next node")
								-- We have not yet reached our node
								-- Face next node
								if (not ml_navigation:UseAutoFollowPathing()) then
									if (adjustedHeading ~= 0) then
										ml_navigation:TryFaceHeading(adjustedHeading)
									else
										local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})
										if ( anglediff < 35 and dist3D > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
											ml_navigation.SmoothFaceTarget(nextnode.x,nextnode.y,nextnode.z)
										else
											ml_navigation:TryFaceTarget(nextnode.x,nextnode.y,nextnode.z)
										end
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
								local autoFollow = ml_navigation:DispatchAutoFollowNode(modifiedNode, true)
								if (not autoFollow and not Player:IsMoving()) then
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
						if (not ml_navigation:IsStillOnPath(ppos,"3dfly")) then
							ml_navigation:DisableAutoFollow(true, "fly-deviation")
							return
						end
														
						-- Check if the next node is reached:
						local dist2D = math.distance2d(nextnode,ppos)
						local dist3D = math.distance3d(nextnode,ppos)
						local height = 0
						local navcon = ml_navigation:GetConnection(nextnode)
						if (Player and Player.meshpos and Player.meshpos.meshdistance) then
							height = Player.meshpos.meshdistance
						end
						--ml_debug("[Navigation]: Moving to next node")
						-- We have not yet reached our node
						-- Face next node
						if (not ml_navigation:UseAutoFollowPathing()) then
							if (adjustedHeading ~= 0) then
								ml_navigation:TryFaceHeading(adjustedHeading)
							else
								local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})
								if ( anglediff < 35 and dist3D > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
									ml_navigation.SmoothFaceTarget(nextnode.x,nextnode.y,nextnode.z)
								else
									ml_navigation:TryFaceTarget(nextnode.x,nextnode.y,nextnode.z)
								end
							end
						elseif (ml_navigation:UseFlightFollowCam()) then
							ml_navigation.SmoothFaceTarget(nextnode.x,nextnode.y,nextnode.z)
						end
						
						local targetnode = shallowcopy(nextnode)
						local nextnextGround = (nextnextnode and nextnextnode.ground == true) or false
						local isDescentCon = (nextnode.floorcube == true and (nextnode.ground == true or nextnextGround))
						local unstableTransition = ml_navigation:IsUnstableFlightTransition(nextnode, nextnextnode)

						if ((not isDescentCon or not ml_navigation:IsGoalClose(ppos,targetnode,lastnode)) and not nextnode.is_cube and ml_navigation:CanContinueFlying()) then
							for i = 3,5,1 do
								-- modifying position down helps mostly here, but do a quick raycheck to make sure we aren't hitting a low obstacle
								local hit, hitx, hity, hitz = RayCast(targetnode.x,targetnode.y+i+1,targetnode.z,targetnode.x,targetnode.y+i-2,targetnode.z)
								if (not hit) then
									--d("Aiming "..tostring(i).." units higher with clearance check.")
									targetnode.y = (targetnode.y + i)
									break
								end
							end	
						end
						
						local pitch = GetRequiredPitch(targetnode)
						Player:SetPitch(pitch)
						
						-- Move
						local autoFollow = ml_navigation:DispatchAutoFollowNode(targetnode, true)
						if (not autoFollow and not Player:IsMoving()) then
							Player:Move(FFXIV.MOVEMENT.FORWARD)
							ffnav.Await(2000, function () return Player:IsMoving() end)
						end
						
						-- Early landing-zone lookahead: scan ahead for the first fly-to-walk
						-- transition node and probe CheckLandingZone while still far out so that
						-- any fallback reroute produces a smooth flight arc instead of a last-second jerk.
						if (not ffnav.landingFallbackActive) then
							local lookaheadIdx = nil
							local lookaheadNode = nil
							for li = ml_navigation.pathindex, ml_navigation.pathindex + 15 do
								local ln = ml_navigation.path[li]
								if (not ln) then break end
								local lnNext = ml_navigation.path[li + 1]
								local lnNextGround = (lnNext and lnNext.ground == true) or false
								local lnIsFlyToWalk = (ln.floorcube == true and (ln.ground == true or lnNextGround))
									or (ln.is_end and ln.ground)
								if (lnIsFlyToWalk) then
									lookaheadIdx = li
									lookaheadNode = ln
									break
								end
							end
							if (lookaheadNode and not ffnav.landingProbeCache[lookaheadIdx]) then
								local distToLanding = math.distance3d(lookaheadNode, ppos)
								if (distToLanding <= ffnav.landingLookaheadDist and distToLanding > 5) then
									local mountRadius = math.max((Player and Player.hitradius) or 0.5, 3)
									local clear, fbX, fbY, fbZ = CheckLandingZone(
										lookaheadNode.x, lookaheadNode.y, lookaheadNode.z, mountRadius)
									ffnav.landingProbeCache[lookaheadIdx] = true -- mark probed
									if (not clear and fbX) then
										d("[Navigation] Lookahead: landing blocked at node " .. lookaheadIdx
											.. ", rerouting early to ("
											.. string.format("%.1f, %.1f, %.1f", fbX, fbY, fbZ) .. ")"
											.. " dist=" .. string.format("%.0f", distToLanding))
										-- Adjust the transition node in-place instead of rebuilding the
										-- entire path (BuildPath from sky→ground produces wild cube routes).
										lookaheadNode.x = fbX
										lookaheadNode.y = fbY
										lookaheadNode.z = fbZ
										lookaheadNode.is_end = true
										-- Remove all nodes after the adjusted landing node so the
										-- flight path goes straight there without stale ground nodes.
										for ri = lookaheadIdx + 1, lookaheadIdx + 50 do
											if (ml_navigation.path[ri] == nil) then break end
											ml_navigation.path[ri] = nil
										end
										-- Track fallback so BuildPath redirect keeps the adjusted
										-- destination if the outer task re-requests a path.
										ffnav.landingFallbackPos = { x = fbX, y = fbY, z = fbZ }
										ffnav.landingFallbackOrigin = ml_navigation.targetposition and
											{ x = ml_navigation.targetposition.x,
											  y = ml_navigation.targetposition.y,
											  z = ml_navigation.targetposition.z } or nil
										ffnav.landingFallbackActive = true
									end
								end
							end
						end
						
						if ( ml_navigation:IsGoalClose(ppos,targetnode,lastnode) or ml_navigation:IsGoalClose(ppos,nextnode,lastnode)) then	
							local canLand = ((dist2D < 2 or dist3D < 3) and height < 7 and height > 0)
							local isFlyToWalk = (isDescentCon or (nextnode.is_end and nextnode.ground))
							
							-- If hovering directly above a ground goal but too high for normal
							-- canLand, force descent so the bot doesn't sit in an AutoFollow loop.
							if (not canLand and isFlyToWalk and dist2D < 2 and height > 0) then
								canLand = true
							end

							if (ffnav.descentAttempts < 3) then
								if (canLand and isFlyToWalk and not unstableTransition and (not nextnode.is_cube or nextnode.ground or (nextnode.floorcube and (nextnode.is_end or nextnextGround))) and (nextnode.is_end or not ml_navigation:CanContinueFlying())) then
									-- Landing clearance: check via C++ CheckLandingZone.
									-- If blocked, find a nearby open spot and rebuild the path there.
									if (not ffnav.landingFallbackActive) then
										local mountRadius = math.max((Player and Player.hitradius) or 0.5, 3)
										local clear, fbX, fbY, fbZ = CheckLandingZone(nextnode.x, nextnode.y, nextnode.z, mountRadius)
										if (not clear) then
											if (fbX) then
												d("[Navigation] Landing blocked, rerouting to ("
													.. string.format("%.1f, %.1f, %.1f", fbX, fbY, fbZ) .. ")")
												ffnav.landingFallbackPos = { x = fbX, y = fbY, z = fbZ }
												ffnav.landingFallbackOrigin = ml_navigation.targetposition and { x = ml_navigation.targetposition.x, y = ml_navigation.targetposition.y, z = ml_navigation.targetposition.z } or nil
												ffnav.landingFallbackActive = true
												Player:BuildPath(fbX, fbY, fbZ, 0, 0, 0)
											else
												d("[Navigation] Landing blocked, no open spot found, descending anyway")
											end
											return false
										end
									end
									-- Descent cooldown: prevent rapid re-descent attempts
									if (TimeSince(ffnav.lastDescentTime) < 2000) then
										if (not ffnav._lastDescentCooldownLog or TimeSince(ffnav._lastDescentCooldownLog) > 2000) then
											d("[Navigation] Descent gated: cooldown (" .. tostring(2000 - TimeSince(ffnav.lastDescentTime)) .. "ms remaining)")
											ffnav._lastDescentCooldownLog = Now()
										end
										return false
									end
									if (ml_navigation:IsFlightActionThrottled("descend", ml_navigation.pathindex, nextnode, nextnextnode)) then
										return false
									end
									ffnav.descentAttempts = ffnav.descentAttempts + 1
									ffnav.lastDescentTime = Now()
									ml_navigation.lastconnectiontimer = Now()
									d("Attempt descent.")
									Descend(true)
									return false
								end
							end

							-- We landed now and can continue our path..
							ffnav.descentAttempts = 0
							ml_navigation.lastconnectionid = nextnode.navconnectionid		
							ml_navigation.lastconnectiontimer = Now()
							ml_navigation.pathindex = ml_navigation.pathindex + 1
							NavigationManager.NavPathNode = ml_navigation.pathindex	
							ml_navigation:ResetFlightActionThrottle(false)
							ml_navigation:ResetAutoFollowState()
						end
		-- Normal Navigation
					end
					
					if (not IsFlying() and not IsDiving()) then
						ffnav.isascending = false
						ffnav.isdescending = false
						ffnav.descentAttempts = 0
						ffnav.landingFallbackActive = false
						ffnav.landingFallbackPos = nil
						ffnav.landingFallbackOrigin = nil
						ffnav.landingProbeCache = {}
						
						--d("[Navigation]: Normal navigation..")
						local navcon = ml_navigation:GetConnection(nextnode)
						local isGoalCloseForCon = (navcon ~= nil and navcon.type == 3 and ml_navigation:IsGoalClose(ppos,nextnode,lastnode))
						local isCubeCon = isGoalCloseForCon
						
						if (nextnode.type == GLOBAL.NODETYPE.CUBE or isCubeCon) then -- next node is a cube node OR is a navconnection floor/cube and we reached nextnode
						
							--d("isCubeCon:"..tostring(isCubeCon))
							-- We reached the nextnode that hodls a navconnection, here we want to always iterate our path so path[1] holds the navconnection
							if ( navcon ) then
								ml_navigation.lastconnectionid = nextnode.navconnectionid
								ml_navigation.lastconnectiontimer = Now()
							end
							
							ml_navigation.GUI.lastAction = "Walk to Cube Node"
							
							if (IsSwimming() and (nextnode.y < (ppos.y - 15))) then	-- We need to differ between the player standing ontop of the water and wanting to dive and the player standing on the seafloor and wanting to ascend to water cubes above
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
								ml_navigation:NavigateToNode(ppos,nextnode,lastnode)	
								return
								
							elseif (not IsFlying() and CanFlyInZone()) then
								if (not Player.ismounted) then

									if (Player:IsMoving()) then
										d("[Navigation] - Mount for flight, stopping first.")
										Player:StopMovement()
										ffnav.AwaitDo(3000, function () return not Player:IsMoving() end, function () Player:StopMovement() end)
										ml_global_information.Await(10000, function () return not ffnav.IsYielding() end)
										return -- need to return here, else  NavigateToNode below continues to move it ;)

									else
										if (ml_navigation:IsFlightActionThrottled("mount", ml_navigation.pathindex, nextnode, nextnextnode)) then
											return
										end
										if (Mount()) then
											d("[Navigation] - Mount for flight.")
											ffnav.AwaitSuccess(1000,
												function ()
													return (IsMounting() or UsingBattleItem())
												end,
												function ()
													ffnav.Await(3000, function () return Player.ismounted end)
												end
											)
											ml_global_information.Await(10000, function () return not ffnav.IsYielding() end)
										else
											ml_navigation:IsFlightActionThrottled("mount_fail", ml_navigation.pathindex, nextnode, nextnextnode)
											d("[Navigation] - Mount for flight failed, retrying...")
											d("[Navigation] - Is next node close? ["..tostring(ml_navigation:IsGoalClose(ppos,nextnode,lastnode)).."].")
											d("[Navigation] - Cube? ["..tostring(nextnode.type == GLOBAL.NODETYPE.CUBE).."], Connection ["..tostring(navcon ~= nil and navcon.type == 3).."]")
											d("[Navigation] - Node tags - floor ["..tostring(nextnode.is_floor).."], cube ["..tostring(nextnode.is_cube).."], ground ["..tostring(nextnode.ground).."], ground_water ["..tostring(nextnode.ground_water).."], ground_border ["..tostring(nextnode.ground_border).."], ground_avoid ["..tostring(nextnode.ground_avoid).."], air ["..tostring(nextnode.air).."], water ["..tostring(nextnode.water).."], air_avoid ["..tostring(nextnode.air_avoid).."].")
											ffnav.Await(1000)
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
										local nextnextAir = (nextnextnode and nextnextnode.air == true) or false
										local isFlightCon = (nextnode.floorcube == true and (nextnode.air == true or nextnextAir) and not ml_navigation:IsUnstableFlightTransition(nextnode, nextnextnode))
										-- Plain CUBE nodes (no navconnection) are unambiguously airborne targets — treat as flyable
										-- but keep isFlightCon false so we don't advance the path index past the cube node
										local shouldAscend = isFlightCon or (nextnode.is_cube and not nextnode.floorcube)
										if (not shouldAscend) then
											ml_navigation:NavigateToNode(ppos,nextnode,lastnode,nil,adjustedHeading)
											return
										end
										if (ml_navigation:IsFlightActionThrottled("ascend", ml_navigation.pathindex, nextnode, nextnextnode)) then
											return
										end
										local targetnode = shallowcopy({x = nextnode.x, y = nextnode.y + 1.5, z = nextnode.z})
										local pitch = GetRequiredPitch(targetnode)

										d("[Navigation] - Ascend for flight, using connection ["..tostring(isFlightCon).."].")
										ffnav.isascending = isFlightCon 
										Player:Jump()
										ffnav.AwaitSuccess(500, 2000, function () 
											local ascended = Player:IsJumping() or IsFlying()
											if (ffnav.isascending and ascended) then-- we are using a navconnection , therefore have to iterate the currentindex to the navconnection end-cube-node. If the next node is 'only' a cube instead, we don't iterate, we ascend and move towards it where then the index is iterated
												ffnav.isascending = false
												-- Only advance past the connection node if the player is
												-- close to it (vertical ascent). If the node is far away
												-- horizontally, let the flying branch navigate to it.
												local ppos2 = Player.pos
												local cnode = ml_navigation.path[ml_navigation.pathindex]
												if (cnode and math.distance2d(ppos2, cnode) < 10) then
													ml_navigation.pathindex = ml_navigation.pathindex + 1
													NavigationManager.NavPathNode = ml_navigation.pathindex
													ml_navigation:ResetFlightActionThrottle(false)
													d("[Navigation]: finished ascending near connection, newpathindex ["..tostring(NavigationManager.NavPathNode).."]")
												else
													d("[Navigation]: finished ascending, flying toward connection node ["..tostring(ml_navigation.pathindex).."]")
												end
											end
											return ascended
										end, function () 
											Player:TakeOff() 
											Player:SetPitch(pitch)
										end)
										
										return
									end
								end
							end
						else

							--d("[Navigation]: Navigate to node, backup.")
							ml_navigation:NavigateToNode(ppos,nextnode,lastnode)	
						end
					end
				else
					ml_navigation.StopMovement()
					Player:Stop()							-- this literally makes no sense...both functions are the SAME but if I remove this one, the bot doesnt stop ..yeah right ...fuck you ffxiv 
				end	
			end
		end		
	end
end

--need this wrapped to allow hooks for testing updates
function ml_navigation.NavWrapper(event, ticks )	
	ml_navigation:EnforceGroundFollowCamPitch()
	ml_navigation.Navigate(event,ticks)
end
RegisterEventHandler("Gameloop.Draw", ml_navigation.NavWrapper, "ml_navigation.NavWrapper")

function ml_navigation.GroundFollowCamWrapper(event, ticks)
	ml_navigation:EnforceGroundFollowCamPitch()
end
RegisterEventHandler("Gameloop.Update", ml_navigation.GroundFollowCamWrapper, "ml_navigation.GroundFollowCamWrapper")

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
RegisterEventHandler("Gameloop.Draw", ml_navigation.DebugDraw, "ml_navigation.DebugDraw")

-- Used by multiple places in the Navigate() function above, so I'll put it here ...no redudant code...
function ml_navigation:NavigateToNode(ppos, nextnode, lastnode, stillonpaththreshold, adjustedHeading)
	local adjustedHeading = IsNull(adjustedHeading,0)
	
	-- Check if we left our path
	if ( stillonpaththreshold ) then
		if ( not ml_navigation:IsStillOnPath(ppos,stillonpaththreshold) ) then
			ml_navigation:DisableAutoFollow(true, "NavToNode-threshold")
			return
		end	
	else
		-- One path may contain all thresholds, so the static path deviation setting is useless for FF.
		local threshold2d, threshold3d = ml_navigation.GetDeviationThresholds()
		if ( not ml_navigation:IsStillOnPath(ppos,threshold3d) ) then
			ml_navigation:DisableAutoFollow(true, "NavToNode-deviation")
			return
		end	
	end
				
	-- Check if the next node is reached
	local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(ppos,nextnode)
	if ( ml_navigation:IsGoalClose(ppos,nextnode,lastnode)) then
		ml_navigation.lastconnectionid = nextnode.navconnectionid		
		ml_navigation.lastconnectiontimer = Now()
		ml_navigation.pathindex = ml_navigation.pathindex + 1
		NavigationManager.NavPathNode = ml_navigation.pathindex
		ml_navigation:ResetAutoFollowState()
		
	else						
		ml_navigation.GUI.lastAction = "Walk to Node"
		if (ml_navigation:UseAutoFollowPathing()) then
			ml_navigation:DispatchAutoFollowNode(nextnode, true)
			if (IsDiving()) then
				local minVector = math.normalize(math.vectorize(ppos,nextnode))
				local pitch = math.asin(-1 * minVector.y)
				Player:SetPitch(pitch)
			end
			return
		end
		
		-- We have not yet reached our node
		if (not IsFlying() and not IsDiving()) then
			ml_navigation:ApplyFollowCamPitch()
		end
		if (adjustedHeading ~= 0) then
			ml_navigation:TryFaceHeading(adjustedHeading)
		else
			local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})											
			if ( anglediff < 35 and nodedist > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
				ml_navigation.SmoothFaceTarget(nextnode.x,nextnode.y,nextnode.z)
			else
				ml_navigation:TryFaceTarget(nextnode.x,nextnode.y,nextnode.z)
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
		if (not IsDiving() and not IsSwimming() and Player.incombat and (not Player.ismounted)) then
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
	if ( ml_navigation.pathindex > 1) then
		-- During active OMC: skip deviation checking for the first 2 seconds (grace period),
		-- then use relaxed thresholds. This replaces the old blanket bypass that hid all drift.
		if (ml_navigation.omc_details) then
			if (ml_navigation.omc_starttimer and ml_navigation.omc_starttimer ~= 0 and (Now() - ml_navigation.omc_starttimer) < 2000) then
				return true -- grace period: don't interrupt early OMC execution
			end
		end
		local threshold = ml_navigation.PathDeviationDistances[ml_navigation.GetMovementType()]
		if (type(deviationthreshold) == "number") then
			threshold = deviationthreshold
		elseif (type(deviationthreshold) == "string") then
			threshold = ml_navigation.PathDeviationDistances[deviationthreshold]
		end
		-- Relax threshold during active OMC to avoid false resets while still catching real drift
		if (ml_navigation.omc_details) then
			threshold = threshold * 2
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
					-- Relax threshold during final approach to a landing-eligible node.
					-- Within 20y 2D of a fly-to-walk transition, altitude offsets during descent
					-- alignment cause the 3D point-line distance to hover near the threshold
					-- (e.g. 10.0-10.4 vs 10). Doubling the threshold in this zone prevents
					-- the orbit loop from repeated path resets.
					local finalApproach = false
					if (IsFlying()) then
						local d2d = math.distance2d(ppos, nextnode)
						local isLandingNode = (nextnode.ground or (nextnode.floorcube and nextnode.ground) or nextnode.is_end)
						if (d2d < 20 and isLandingNode) then
							finalApproach = true
						end
					end
					local effectiveThreshold = threshold
					if (finalApproach) then
						effectiveThreshold = threshold * 2
					end
					
					local distline = math.distancepointline(lastnode,nextnode,ppos)
					if (distline > effectiveThreshold) then			
						d("[Navigation] - Player not on path anymore (3D). - Distance to Path: "..tostring(distline).." > "..tostring(effectiveThreshold) .. (finalApproach and " (relaxed)" or ""))
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

	-- In auto-follow mode we keep the position correction, but skip heading enforcement to avoid camera pull.
	if (self:UseAutoFollowPathing()) then
		self.ensureheading = nil
		self.ensureheadingtargetpos = nil
	elseif(nearside.hx ~= 0 ) then
		self.ensureheading = nearside
		self.ensureheadingtargetpos = nil
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
		if (self:UseAutoFollowPathing()) then
			self.ensureheading = nil
			self.ensureheadingtargetpos = nil
		end
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
	self.omc_details = nil
	self.omc_traveldist = 0
	self.omc_traveltimer = nil
	self.omc_direction = 0
	self.lastupdate = 0
end

------------------------------------------------------------
-- MoveToExact Navigation Tick Handler
------------------------------------------------------------
function ml_navigation_exact.Navigate(event, ticks)
	if (not ml_navigation_exact.active) then return end
	
	-- 16ms tick throttle for faster combat response
	if ((ticks - ml_navigation_exact.lastupdate) < 16) then return end
	ml_navigation_exact.lastupdate = ticks
	
	local ppos = Player.pos
	if (not ppos) then return end
	
	-- Handle pending async path
	if (ml_navigation_exact.pending) then
		local goal = ml_navigation_exact.pendingGoal
		local cacheId = ml_navigation_exact.pendingCacheId
		if (not goal) then
			Player:StopExact()
			return
		end
		if (not cacheId or cacheId <= 0) then
			cacheId = BuildMoveToExactCacheId(ppos, goal)
			ml_navigation_exact.pendingCacheId = cacheId
			d("[MoveToExact]: Missing pending cacheId, regenerated id=" .. tostring(cacheId))
		end
		local result = NavigationManager:GetPathAsync(ppos.x, ppos.y, ppos.z, goal.x, goal.y, goal.z, cacheId, false, true)
		if (type(result) == "table" and table.valid(result)) then
			ml_navigation_exact.path = result
			ml_navigation_exact.pathindex = 1
			ml_navigation_exact.pending = false
			ml_navigation_exact.pendingGoal = nil
			ml_navigation_exact.pendingCacheId = nil
			for _, node in pairs(ml_navigation_exact.path) do
				ml_navigation.TagNode(node)
			end
			-- Optimize path: remove skippable intermediate nodes via raycast shortcuts
			ml_navigation_exact.OptimizeCachedPath(ppos)
			d("[MoveToExact]: Path resolved. cacheId=" .. tostring(cacheId) .. ", nodes=" .. tostring(table.size(ml_navigation_exact.path)))
		elseif (type(result) == "number" and result > 0) then
			return -- still pending, wait another tick
		else
			d("[MoveToExact]: Path request failed during pending poll. cacheId=" .. tostring(cacheId))
			Player:StopExact()
			return
		end
	end
	
	local self = ml_navigation_exact
	local nextnode = self.path[self.pathindex]
	
	-- No more nodes — destination reached
	if (not nextnode) then
		if (not self.reachedLogged) then
			d("[MoveToExact]: Destination reached.")
			self.reachedLogged = true
			self.active = false
			self.completed = true
			ml_navigation:DisableAutoFollow(true, "MoveToExact complete")
		end
		return
	end
	
	-- OMC handling
	if (self.omc_id and self.omc_details) then
		ml_navigation_exact.HandleOMC(ppos, ticks)
		return
	end
	
	-- Check if current node is reached
	local dist2d = math.distance2d(ppos, nextnode)
	local yDelta = (nextnode.y and ppos.y) and math.abs(ppos.y - nextnode.y) or 0
	local withinVertical = (nextnode.y == nil or ppos.y == nil or yDelta <= (self.verticalThreshold or 1.5))
	
	-- MoveToExact is ground-only; require both horizontal and vertical proximity when Y is known.
	if (dist2d <= self.threshold and withinVertical) then
		-- Node reached — check for OMC setup
		if (nextnode.navconnectionid and nextnode.navconnectionid ~= 0) then
			local nc = NavigationManager:GetNavConnection(nextnode.navconnectionid)
			if (nc and nc.type ~= 5 and nc.details and In(nc.details.subtype, 1, 2, 3, 4)) then
				self.omc_id = nc.id
				self.omc_details = nc
				-- Determine direction
				if (nc.sideA ~= nil) then
					if (nextnode.navconnectionsideA == true) then
						self.omc_direction = 1
					else
						self.omc_direction = 2
					end
				else
					if (math.distance3d(ppos, nc.from) < math.distance3d(ppos, nc.to)) then
						self.omc_direction = 1
					else
						self.omc_direction = 2
					end
				end
			end
		end
		
		self.pathindex = self.pathindex + 1
		ml_navigation_exact.ResetAutoFollowState()
		
		-- Check if that was the last node
		if (not self.path[self.pathindex]) then
			if (not self.reachedLogged) then
				d("[MoveToExact]: Destination reached.")
				self.reachedLogged = true
				self.active = false
				self.completed = true
				ml_navigation:DisableAutoFollow(true, "MoveToExact complete")
			end
			return
		end
		-- Immediately dispatch autofollow to the next node so C++ doesn't
		-- turn autofollow off between ticks (it auto-disables on arrival).
		ml_navigation_exact.DispatchAutoFollow(self.path[self.pathindex], ppos, true)
		return
	end
	
	-- Not reached — dispatch autofollow toward next node
	ml_navigation_exact.DispatchAutoFollow(nextnode, ppos, false)
end

------------------------------------------------------------
-- MoveToExact OMC Handler
------------------------------------------------------------
function ml_navigation_exact.HandleOMC(ppos, ticks)
	local self = ml_navigation_exact
	local nc = self.omc_details
	local nextnode = self.path[self.pathindex]
	local nextnextnode = self.path[self.pathindex + 1]
	
	if (not nc or not nextnode) then
		ml_navigation_exact.ResetOMCState()
		return
	end
	
	-- Resolve direction and positions
	local from_pos, to_pos, ncradius, ncsubtype, from_heading
	
	if (nc.sideA ~= nil) then
		if (self.omc_direction == 1) then
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
	
	-- Stuck detection: 3s progress check + 10s max timeout
	if (not MIsLocked()) then
		if (self.omc_traveltimer == nil) then
			self.omc_traveltimer = ticks
		end
		local timepassed = ticks - self.omc_traveltimer
		local dist = math.distance3d(ppos, nextnode)
		if (self.omc_traveldist == 0) then
			self.omc_traveldist = dist
		end
		if (timepassed < 3000) then
			if (timepassed > 2000 and self.omc_traveldist > dist) then
				self.omc_traveldist = dist
				self.omc_traveltimer = ticks
			end
		else
			d("[MoveToExact]: OMC stuck — not getting closer.")
			Player:StopExact()
			return
		end
	end
	
	if (self.omc_starttimer ~= 0 and ticks - self.omc_starttimer > 10000) then
		d("[MoveToExact]: OMC timeout (10s).")
		Player:StopExact()
		return
	end
	
	-- OMC Jump (subtype 1)
	if (ncsubtype == 1) then
		if (not self.omc_startheight) then
			-- Face target before jumping
			if (self.omc_starttimer == 0) then
				self.omc_starttimer = ticks
				if (not Player:IsMoving()) then
					ml_navigation_exact.DispatchAutoFollow(to_pos, ppos, true)
				end
			elseif (Player:IsMoving() and ticks - self.omc_starttimer > 100) then
				self.omc_startheight = ppos.y
				Player:Jump()
				d("[MoveToExact]: OMC Jump started.")
			end
		else
			local todist2d = math.distance2d(ppos, to_pos)
			if (todist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
				-- Reached jump target
				self.pathindex = self.pathindex + 1
				ml_navigation_exact.ResetAutoFollowState()
				ml_navigation_exact.ResetOMCState()
				d("[MoveToExact]: OMC Jump landed.")
			else
				-- Still in air / approaching
				if (from_pos.y > (ppos.y + 1) and to_pos.y > (ppos.y + 1)) then
					d("[MoveToExact]: OMC Jump failed — fell below both endpoints.")
					Player:StopExact()
					return
				end
				ml_navigation_exact.DispatchAutoFollow(to_pos, ppos, true)
			end
		end
		return
	end
	
	-- OMC Walk (subtype 2)
	if (ncsubtype == 2) then
		if (self.omc_starttimer == 0) then
			self.omc_starttimer = ticks
		end
		local todist2d = math.distance2d(ppos, nextnode)
		if (todist2d <= self.threshold) then
			self.pathindex = self.pathindex + 1
			ml_navigation_exact.ResetAutoFollowState()
			ml_navigation_exact.ResetOMCState()
			d("[MoveToExact]: OMC Walk complete.")
		else
			ml_navigation_exact.DispatchAutoFollow(nextnode, ppos, true)
		end
		return
	end
	
	-- OMC Teleport (subtype 3)
	if (ncsubtype == 3) then
		if (Player:IsMoving() or Player:IsJumping()) then
			Player:StopMovement()
			return
		end
		if (gTeleportHack) then
			Hacks:TeleportToXYZ(to_pos.x, to_pos.y, to_pos.z)
			d("[MoveToExact]: OMC Teleport.")
		else
			NavigationManager:DisableNavConnection(nc.id)
		end
		self.pathindex = self.pathindex + 1
		ml_navigation_exact.ResetAutoFollowState()
		ml_navigation_exact.ResetOMCState()
		return
	end
	
	-- OMC Interact (subtype 4)
	if (ncsubtype == 4) then
		if (Player:IsMoving()) then
			Player:StopMovement()
			return
		end
		
		if (MIsLoading()) then
			self.lastupdate = self.lastupdate + 1500
			self.pathindex = self.pathindex + 1
			ml_navigation_exact.ResetAutoFollowState()
			ml_navigation_exact.ResetOMCState()
			return
		end
		
		if (IsControlOpen("SelectString") or IsControlOpen("SelectIconString")) then
			SelectConversationIndex(1)
			self.lastupdate = self.lastupdate + 1000
			return
		end
		
		if (IsPositionLocked()) then
			self.lastupdate = self.lastupdate + 500
			return
		end
		
		-- Check if we already arrived at the OMC end
		local todist = math.distance3d(ppos, nextnode)
		local todist2d = math.distance2d(ppos, nextnode)
		if (todist <= ml_navigation.NavPointReachedDistances["3dwalk"] and todist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
			self.pathindex = self.pathindex + 1
			ml_navigation_exact.ResetAutoFollowState()
			ml_navigation_exact.ResetOMCState()
			d("[MoveToExact]: OMC Interact node reached.")
			return
		end
		
		-- Find a target to interact with
		local interactnpc
		local elist = MEntityList("nearest,targetable,type=7,chartype=0,maxdistance=5")
		if (table.valid(elist)) then interactnpc = select(2, next(elist)) end
		
		if (not interactnpc) then
			elist = MEntityList("nearest,targetable,type=3,chartype=0,maxdistance=5")
			if (table.valid(elist)) then interactnpc = select(2, next(elist)) end
		end
		
		if (not interactnpc) then
			elist = MEntityList("nearest,targetable,maxdistance=7")
			if (table.valid(elist)) then interactnpc = select(2, next(elist)) end
		end
		
		if (interactnpc) then
			if (not Player:IsInteracting()) then
				Player:Interact(interactnpc.id)
				self.lastupdate = self.lastupdate + 1000
			end
		end
		return
	end
	
	-- Unknown subtype — skip
	d("[MoveToExact]: Unknown OMC subtype " .. tostring(ncsubtype) .. ", skipping.")
	self.pathindex = self.pathindex + 1
	ml_navigation_exact.ResetAutoFollowState()
	ml_navigation_exact.ResetOMCState()
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
ffnav.descentAttempts = 0
ffnav.lastDescentTime = 0
ffnav.landingProbeCache = {}  -- keyed by pathindex for fly-to-walk transitions
ffnav.landingFallbackActive = false  -- true while rerouted to a landing fallback
ffnav.landingFallbackPos = nil       -- {x,y,z} of the fallback landing spot
ffnav.landingFallbackOrigin = nil    -- {x,y,z} of the original destination (to detect target changes)
ffnav.landingLookaheadDist = 40      -- distance (units) at which to pre-probe the landing zone
ffnav.flightLoopGuard = { key = nil, lastAction = nil, lastTime = 0, count = 0, lockUntil = 0 }

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

-- MoveToExact path drawing (cyan nodes, yellow lines)
function ml_navigation_exact.DrawPath(event, ticks)
	if (not table.valid(ml_navigation_exact.path)) then return end
	local ppos = Player.pos
	
	local maxWidth, maxHeight = GUI:GetScreenSize()
	GUI:SetNextWindowPos(0, 0, GUI.SetCond_Always)
	GUI:SetNextWindowSize(maxWidth, maxHeight, GUI.SetCond_Always)
	local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
	GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], 0)
	local flags = (GUI.WindowFlags_NoInputs + GUI.WindowFlags_NoBringToFrontOnFocus + GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
	GUI:Begin("Show Exact Nav Space", true, flags)
	
	-- Build screen positions keyed by path index
	local screenNodes = {}
	local drawKeys = {}
	local pathindex = ml_navigation_exact.pathindex or 1
	local orderedKeys = {}
	for id in pairsByKeys(ml_navigation_exact.path) do
		table.insert(orderedKeys, id)
	end
	for order, id in ipairs(orderedKeys) do
		local node = ml_navigation_exact.path[id]
		local shouldDraw = true
		-- MoveToExact paths may include a synthetic start anchor at player feet.
		-- Hide leading near-player anchor stubs so the overlay starts at the first travel node.
		if (order <= 2 and ppos and node) then
			local nearPlayer2D = math.distance2d(ppos, node) <= 0.35
			local nearPlayerY = (not node.y or not ppos.y or math.abs(node.y - ppos.y) <= 1.5)
			if ((node.is_start or nearPlayer2D) and nearPlayer2D and nearPlayerY) then
				shouldDraw = false
			end
		end
		local nodePos = RenderManager:WorldToScreen({ x = node.x, y = node.y + 0.15, z = node.z })
		if (shouldDraw and table.valid(nodePos)) then
			screenNodes[id] = nodePos
			table.insert(drawKeys, id)
			local alpha = (id >= pathindex) and 1 or 0.3
			GUI:AddCircleFilled(nodePos.x, nodePos.y, 7, GUI:ColorConvertFloat4ToU32(0, .9, .9, alpha))
		end
	end

	-- Visualize the active dispatch target separately without altering raw path rendering.
	local activeNode = ml_navigation_exact.path[pathindex]
	if (activeNode and ppos) then
		local dispatchY = ml_navigation_exact.GetDispatchTargetY(activeNode, ppos)
		if (dispatchY) then
			local dispatchPos = RenderManager:WorldToScreen({ x = activeNode.x, y = dispatchY + 0.2, z = activeNode.z })
			if (table.valid(dispatchPos)) then
				GUI:AddCircle(dispatchPos.x, dispatchPos.y, 9, GUI:ColorConvertFloat4ToU32(1, .5, 0, 1), 24, 2)
			end
		end
	end
	
	-- Draw lines between consecutive path nodes (only when both endpoints are on screen)
	for i = 1, #drawKeys - 1 do
		local thisId = drawKeys[i]
		local nextId = drawKeys[i + 1]
		local thisScreen = screenNodes[thisId]
		local nextScreen = screenNodes[nextId]
		local thisNode = ml_navigation_exact.path[thisId]
		local nextNode = ml_navigation_exact.path[nextId]
		local skipAnchorStub = false
		if (thisNode and nextNode) then
			local seg2d = math.distance2d(thisNode, nextNode)
			local segY = (thisNode.y and nextNode.y) and math.abs(thisNode.y - nextNode.y) or 0
			-- Path results can include tiny XZ anchor adjustments that render as a vertical spike.
			-- Suppress only micro-segments; keep normal path edges intact.
			if (seg2d <= 0.30 and segY <= 1.25) then
				skipAnchorStub = true
			end
		end
		if (thisScreen and nextScreen and not skipAnchorStub) then
			GUI:AddLine(thisScreen.x, thisScreen.y, nextScreen.x, nextScreen.y, GUI:ColorConvertFloat4ToU32(1, 1, .2, 1), 3)
		end
	end
	
	GUI:End()
	GUI:PopStyleColor()
end
RegisterEventHandler("Gameloop.Draw", ml_navigation_exact.DrawPath, "ml_navigation_exact.DrawPath")









-- Extends the ml_mesh_mgr.lua
-- Game specific OffMeshConnection Handling
-- Handler for different OMC types
function ml_mesh_mgr.HandleOMC( ... )
	if (Now() > ml_mesh_mgr.OMCThrottle and not ml_mesh_mgr.OMCStartPositionReached) then
		local args = {...}
		local OMCType = args[2]	
		local OMCStartPosition,OMCEndposition,OMCFacingDirection = ml_mesh_mgr.UnpackArgsForOMC( args )
		d("OMC REACHED : "..tostring(OMCType))
		
		if ( ValidTable(OMCStartPosition) and ValidTable(OMCEndposition) and ValidTable(OMCFacingDirection) ) then
			ml_mesh_mgr.OMCStartPosition = OMCStartPosition
			ml_mesh_mgr.OMCEndposition = OMCEndposition
			ml_mesh_mgr.OMCFacingDirection = OMCFacingDirection
			ml_mesh_mgr.OMCType = OMCType
			ml_mesh_mgr.OMCIsHandled = true -- Turn on omc handler
		end
	end
end

ml_mesh_mgr.OMCStartPosition = nil
ml_mesh_mgr.OMCEndposition = nil
ml_mesh_mgr.OMCFacingDirection = nil
ml_mesh_mgr.OMCType = nil
ml_mesh_mgr.OMCIsHandled = false
ml_mesh_mgr.OMCStartPositionReached = false
ml_mesh_mgr.OMCJumpStartedTimer = 0
ml_mesh_mgr.OMCFlightStarted = 0
ml_mesh_mgr.OMCFlightJumps = 0
ml_mesh_mgr.OMCAltitudeReached = 0
ml_mesh_mgr.OMCFlightAscend = 0
ml_mesh_mgr.OMCFlightForward = 0
ml_mesh_mgr.OMCFlightStopped = 0
ml_mesh_mgr.OMCMinAltitude = 0
ml_mesh_mgr.OMCMounted = 0
ml_mesh_mgr.OMCThrottle = 0
ml_mesh_mgr.OMCLastDistance = 0
ml_mesh_mgr.OMCStartingDistance = 0
ml_mesh_mgr.OMCMeshDistance = 0
ml_mesh_mgr.OMCTarget = 0
function ml_mesh_mgr.OMC_Handler_OnUpdate( tickcount ) 
	if ( ml_mesh_mgr.OMCIsHandled ) then	
		ml_global_information.lastrun = Now()
		
		if (Now() > ml_mesh_mgr.OMCThrottle) then
			-- Update IsMoving with exact data
			ml_global_information.Player_IsMoving = Player:IsMoving() or false
			ml_global_information.Player_Position = Player.pos
			-- Set all position data, pPos = Player pos, sPos = start omc pos and heading, ePos = end omc pos
			local pPos = ml_global_information.Player_Position
			local mPos,mDist = NavigationManager:GetClosestPointOnMesh(pPos)
			local sPos = {
							x = tonumber(ml_mesh_mgr.OMCStartPosition[1]), y = tonumber(ml_mesh_mgr.OMCStartPosition[2]), z = tonumber(ml_mesh_mgr.OMCStartPosition[3]),
							h = tonumber(ml_mesh_mgr.OMCFacingDirection[1]),
						}
			local ePos = {
							x = tonumber(ml_mesh_mgr.OMCEndposition[1]), y = tonumber(ml_mesh_mgr.OMCEndposition[2]), z = tonumber(ml_mesh_mgr.OMCEndposition[3]),
						}
			
			if ( ml_mesh_mgr.OMCStartPositionReached == false ) then
				if ( ValidTable(sPos) ) then
					if (ml_mesh_mgr.OMCType == "OMC_INTERACT") then						
						Player:Stop()
						-- Check for inanimate objects, use those as first guess.
						if (ml_mesh_mgr.OMCTarget == 0) then
							local interacts = EntityList("nearest,targetable,type=7,chartype=0,maxdistance=5")
							d("Scanning for type 7 objects to interact with.")
							if (interacts) then
								local i, interact = next(interacts)
								if (interact and interact.id and interact.id ~= 0) then
									d("Chose object : "..interact.name)
									ml_mesh_mgr.OMCTarget = interact.id
								end
							end
						end
						
						-- Check for NPC's, use those as a backup guess.
						if (ml_mesh_mgr.OMCTarget == 0) then
							local interacts = EntityList("nearest,targetable,type=3,chartype=0,maxdistance=5")
							d("Scanning for type 3 NPCs to interact with.")
							if (interacts) then
								local i, interact = next(interacts)
								if (interact and interact.id and interact.id ~= 0) then
									d("Chose NPC : "..interact.name)
									ml_mesh_mgr.OMCTarget = interact.id
								end
							end
						end
						
						if (ml_mesh_mgr.OMCTarget == 0) then
							local interacts = EntityList("nearest,targetable,maxdistance=7")
							d("Scanning for anything nearby that's targetable to interact with.")
							if (interacts) then
								local i, interact = next(interacts)
								if (interact and interact.id and interact.id ~= 0) then
									d("Chose NPC : "..interact.name)
									ml_mesh_mgr.OMCTarget = interact.id
								end
							end
						end
						
						-- If our target isn't 0 anymore, select it, and attempt to interact with it.
						if (ml_mesh_mgr.OMCTarget ~= 0) then
							local target = Player:GetTarget()
							if (not target or (target and target.id ~= ml_mesh_mgr.OMCTarget)) then
								local interact = EntityList:Get(tonumber(ml_mesh_mgr.OMCTarget))
								if (interact and interact.targetable) then
									d("Setting target for interaction : "..interact.name)
									Player:SetTarget(ml_mesh_mgr.OMCTarget)
									ml_mesh_mgr.OMCStartingDistance = interact.distance
									ml_mesh_mgr.OMCThrottle = Now() + 100
									return
								end		
							end
							
							ml_mesh_mgr.OMCStartPositionReached = true
							d("Starting state reached for INTERACT OMC.")
							ml_mesh_mgr.OMCThrottle = Now() + 100
						end
					elseif (ml_mesh_mgr.OMCType == "OMC_LIFT") then
						local meshdist = Distance3D(sPos.x,sPos.y,sPos.z,mPos.x,mPos.y,mPos.z)
						ml_mesh_mgr.OMCMeshDistance = meshdist
						if ((not Player.ismounted and meshdist < 0.75) or (Player.ismounted and meshdist < 1)) then
							Player:SetFacing(sPos.h) -- Set heading
							ml_mesh_mgr.OMCStartingDistance = meshdist
							ml_mesh_mgr.OMCStartPositionReached = true
							
							if ( not ml_global_information.Player_IsMoving ) then
								Player:Move(FFXIV.MOVEMENT.FORWARD)
							end
							
							d("Starting state reached for : " .. ml_mesh_mgr.OMCType)
							return
						end
					elseif (ml_mesh_mgr.OMCType == "OMC_PORTAL") then
						local meshdist = Distance3D(sPos.x,sPos.y,sPos.z,mPos.x,mPos.y,mPos.z)
						ml_mesh_mgr.OMCMeshDistance = meshdist
						if ((not Player.ismounted and meshdist < 1.7) or (Player.ismounted and meshdist < 2.5)) then
							ml_mesh_mgr.OMCStartingDistance = meshdist
							ml_mesh_mgr.OMCStartPositionReached = true
							
							d("Starting state reached for : " .. ml_mesh_mgr.OMCType)
							return
						end
					else
						local meshdist = Distance3D(sPos.x,sPos.y,sPos.z,mPos.x,mPos.y,mPos.z)
						ml_mesh_mgr.OMCMeshDistance = meshdist
						if ((ml_global_information.Player_IsMoving and ((not Player.ismounted and meshdist < 0.75) or (Player.ismounted and meshdist < 1))) or
							(not ml_global_information.Player_IsMoving and ((not Player.ismounted and meshdist < 1.5) or (Player.ismounted and meshdist < 1.75))))
						then
							Player:SetFacing(sPos.h) -- Set heading
							ml_mesh_mgr.OMCStartingDistance = meshdist
							ml_mesh_mgr.OMCStartPositionReached = true
							
							if ( not ml_global_information.Player_IsMoving ) then
								Player:Move(FFXIV.MOVEMENT.FORWARD)
							end
						
							--ml_mesh_mgr.OMCThrottle = Now() + 100
							d("Starting state reached for : " .. ml_mesh_mgr.OMCType)
							return
						end
					end
				end
			else
				local meshdist = ml_mesh_mgr.OMCMeshDistance
				if ( ml_mesh_mgr.OMCType == "OMC_JUMP" ) then
					ml_mesh_mgr.OMCThrottle = Now() + 100
					
					if ( ValidTable(ml_mesh_mgr.OMCEndposition) ) then
						-- We are at our start OMC point and are facing the correct direction, now start moving forward and jump
						local h = (math.floor(sPos.h * 100) / 100)
						local ph = (math.floor(Player.pos.h * 100) / 100)
						
						if (ml_mesh_mgr.OMCJumpStartedTimer == 0) then
							if (not Player:IsJumping()) then
								if (ph ~= h) then
									Player:SetFacing(sPos.h)
									return
								end
								
								local hasStealth = HasBuffs(Player,"47")
							
								if ((not Player.ismounted and Player:GetSpeed(FFXIV.MOVEMENT.FORWARD) < 6) or 
									(Player.ismounted and Player:GetSpeed(FFXIV.MOVEMENT.FORWARD) < 7))
								then
									return
								end
								
								Player:Jump()
							else
								ml_mesh_mgr.OMCJumpStartedTimer = Now()
							end
							return
						end
						
						if (ml_mesh_mgr.OMCJumpStartedTimer ~= 0) then
							ml_mesh_mgr.OMCThrottle = Now() + 100
							if (Player:IsJumping()) then
								Player:Stop()
								return
							elseif (not Player:IsJumping()) then
								ml_mesh_mgr.ResetOMC()
							end
						end
					end
				
				elseif ( ml_mesh_mgr.OMCType == "OMC_WALK" ) then
					ml_mesh_mgr.OMCThrottle = Now() + 150
					
					if ( ValidTable(ml_mesh_mgr.OMCEndposition) ) then								
						local facingPos = {x = ePos.x,y = ePos.y,z = ePos.z}
						Player:SetFacing(facingPos)
					
						if ( not ml_global_information.Player_IsMoving ) then 
							Player:Move(FFXIV.MOVEMENT.FORWARD) 
						end
						
						if (Player:IsJumping() and (pPos.y < (ePos.y - 3))) then
							Player:Stop()
							ml_mesh_mgr.ResetOMC()
						end
						
						if (not Player:IsJumping()) then
							local dist = Distance3D(ePos.x,ePos.y,ePos.z,pPos.x,pPos.y,pPos.z)
							if ((not Player.ismounted and dist < 1.7) or (Player.ismounted and dist < 2.7)) then
								Player:Stop()
								ml_mesh_mgr.ResetOMC()
							end
						end
					end
				
				elseif ( ml_mesh_mgr.OMCType == "OMC_LIFT" ) then
					ml_mesh_mgr.OMCThrottle = Now() + 100
					
					if (Player:IsJumping()) then
						if (ml_mesh_mgr.OMCJumpStartedTimer == 0 ) then
							ml_mesh_mgr.OMCJumpStartedTimer = Now()
						end
						
						Player:Stop()
						return
					end
					
					if (not Player:IsJumping() and ml_mesh_mgr.OMCJumpStartedTimer ~= 0) then
						ml_mesh_mgr.ResetOMC()
					end

				elseif ( ml_mesh_mgr.OMCType == "OMC_TELEPORT" ) then
					if ( ValidTable(ml_mesh_mgr.OMCEndposition) ) then
						if ( ml_global_information.Player_IsMoving ) then Player:Stop() end
						-- Add playerdetection when distance to OMCEndposition is > xxx
						local enddist = Distance3D(ePos.x,ePos.y,ePos.z,pPos.x,pPos.y,pPos.z)
						if ( enddist > 2.20 ) then
							--if ( TableSize(EntityList("nearest,player,maxdistance=15"))>0 ) then
								--ml_log("Need to teleport but players are nearby..waiting..")
								--ml_mesh_mgr.OMCThrottle = tickcount + 2000
								--ml_global_information.Lasttick = ml_global_information.Lasttick + 2000
								--Player:Stop()
								--return
							--end
						end
						GameHacks:TeleportToXYZ(ePos.x, ePos.y, ePos.z)
						d("OMC Endposition reached..")
						ml_mesh_mgr.ResetOMC()
						Player:Stop()
						ml_mesh_mgr.OMCThrottle = Now() + 2000
					end
				
				elseif ( ml_mesh_mgr.OMCType == "OMC_INTERACT" ) then
					ml_mesh_mgr.OMCThrottle = Now() + 100
					
					if (ControlVisible("SelectYesno")) then
						PressYesNo(true)
						ml_mesh_mgr.OMCThrottle = Now() + 500
						return
					end
					
					if (IsLoading()) then
						ml_mesh_mgr.OMCThrottle = Now() + 500
						ml_mesh_mgr.ResetOMC()
						return
					end
					
					if (IsPositionLocked()) then
						ml_mesh_mgr.OMCThrottle = Now() + 500
						return
					end
					
					-- If we're now not on the starting spot, we were moved somewhere.
					local movedDistance = Distance3D(sPos.x,sPos.y,sPos.z,mPos.x,mPos.y,mPos.z)
					if (movedDistance > 3) then
						ml_mesh_mgr.OMCThrottle = Now() + 100
						ml_mesh_mgr.ResetOMC()
						return
					end
					
					local target = Player:GetTarget()
					if (target and target.id == ml_mesh_mgr.OMCTarget) then						
						local interact = EntityList:Get(tonumber(ml_mesh_mgr.OMCTarget))
						local radius = (interact.hitradius >= 1 and interact.hitradius) or 1
						if (interact and interact.distance < (radius * 4)) then
							Player:SetFacing(interact.pos.x,interact.pos.y,interact.pos.z)
							Player:Interact(interact.id)
							ml_mesh_mgr.OMCThrottle = Now() + 500
						end
					end
					
					if (not target or not target.targetable or target.distance > 5) then
						ml_mesh_mgr.OMCThrottle = Now() + 100
						ml_mesh_mgr.ResetOMC()
						return
					end

				elseif ( ml_mesh_mgr.OMCType == "OMC_PORTAL" ) then
					ml_mesh_mgr.OMCThrottle = Now() + 100
					
					if ( ValidTable(ml_mesh_mgr.OMCEndposition) ) then						
						if (ml_mesh_mgr.OMCMounted == 0) then
							if (Player.ismounted) then
								local facingPos = {x = ePos.x,y = ePos.y,z = ePos.z}
								if ( not ml_mesh_mgr.IsFacing(facingPos)) then
									d("We are not facing the endpoint, face it now.")
									d("Current position: x ["..tostring(pPos.x).."] y ["..tostring(pPos.y).."] z ["..tostring(pPos.z).."]")
									d("End position: x ["..tostring(ePos.x).."] y ["..tostring(ePos.y).."] z ["..tostring(ePos.z).."]")
									Player:SetFacing(ePos.x,ePos.y,ePos.z)
								else
									ml_mesh_mgr.OMCMounted = 1
								end
								
								ml_mesh_mgr.OMCThrottle = Now() + 200
								return
							else
								if (not IsMounting()) then
									if (not Player.incombat) then								
										local mountID = GetMountID()
										if (mountID ~= nil) then
											if (Player:IsMoving()) then
												d("Throwing Stop() in mount block.")
												Player:Stop()
												ml_mesh_mgr.OMCThrottle = Now() + 100
												return
											else
												Mount(mountID)
												ml_mesh_mgr.OMCThrottle = Now() + 1000
												return
											end
										end
									else
										d("Throwing Stop() in combat detection, mount block.")
										Player:Stop()
										ml_mesh_mgr.ResetOMC()
										return
									end
								end
							end
							
							ml_mesh_mgr.OMCThrottle = Now() + 100
							return
						end
						
						if (ml_mesh_mgr.OMCFlightStarted == 0) then
							d("Flight not yet started.")
							if (ml_mesh_mgr.OMCFlightJumps < 2) then
								d("Doing takeoff jumps.")
								Player:Jump()
								ml_mesh_mgr.OMCFlightJumps = ml_mesh_mgr.OMCFlightJumps + 1
								ml_mesh_mgr.OMCThrottle = Now() + 200
								return
							else
								ml_mesh_mgr.OMCFlightStarted = Now()
							end
							
							ml_mesh_mgr.OMCThrottle = Now() + 100
							return
						end
						
						if (ml_mesh_mgr.OMCAltitudeReached == 0) then
							d("Minimum altitude is not yet reached.")
							
							if (ml_mesh_mgr.OMCMinAltitude == 0) then
								local minaltitudes = {
									[-1] = 200,
									[397] = 200,
								}
							
								local minaltitude = minaltitudes[Player.localmapid] or minaltitudes[-1]
								if (Player.pos.y > minaltitude) then
									ml_mesh_mgr.OMCMinAltitude = Player.pos.y + 20
									d("Setting min altitude to "..tostring(Player.pos.y + 20))
								else
									ml_mesh_mgr.OMCMinAltitude = minaltitude
									d("Setting min altitude to "..tostring(minaltitude))
								end
								return
							end
							
							if (Player.pos.y < ml_mesh_mgr.OMCMinAltitude) then
								if (ml_mesh_mgr.OMCFlightAscend == 0) then
									d("Setting ascend.")
									Player:Move(128)
									ml_mesh_mgr.OMCFlightAscend = Now()
								end
								ml_mesh_mgr.OMCThrottle = Now() + 200
								return
							else
								d("Minimum altitude is reached.")
								ml_mesh_mgr.OMCAltitudeReached = Now()
								d("Throwing Stop() in altitude block.")
								Player:Stop()
								ml_mesh_mgr.OMCThrottle = Now() + 250
								return
							end
							
							ml_mesh_mgr.OMCThrottle = Now() + 200
							return
						end
						
						local dist3D = Distance3D(pPos.x,pPos.y,pPos.z,ePos.x,ePos.y,ePos.z)
						if (dist3D < 8) then
							d("We are close enough to the endpoint to reset.")
							Player:Stop()
							ml_mesh_mgr.ResetOMC()
							return
						else
							d("We are not close enough to the endpoint to reset yet, distance is "..tostring(dist3D))
						end
						
						if (ml_mesh_mgr.OMCAltitudeReached ~= 0) then
							local dist = Distance2D(pPos.x,pPos.z,ePos.x,ePos.z)
							if (dist > 7) then
								if (ml_mesh_mgr.OMCFlightForward == 0) then
									d("Initiating forward movement.")
									Player:MoveToStraight(ePos.x,ePos.y,ePos.z)
									ml_mesh_mgr.OMCFlightForward = {x = pPos.x, z = pPos.z}
								else
									if (ValidTable(ml_mesh_mgr.OMCFlightForward)) then
										local diststart = Distance2D(pPos.x,pPos.z,ml_mesh_mgr.OMCFlightForward.x,ml_mesh_mgr.OMCFlightForward.z)
										if (diststart < 1) then
											Player:MoveToStraight(ePos.x,ePos.y,ePos.z)
										end
									end
								end
								
								d("Current 2D distance from endpoint, "..tostring(dist))
								ml_mesh_mgr.OMCThrottle = Now() + 200
								return
							else
								if (ml_mesh_mgr.OMCFlightStopped == 0) then
									d("Stopping flight, reached x,z.")
									Player:Move(348)
									Player:Stop()
									ml_mesh_mgr.OMCFlightStopped = Now()
									ml_mesh_mgr.OMCThrottle = Now() + 200
									return
								else
									d("Dismounting to land.")
									Dismount()
									ml_mesh_mgr.OMCThrottle = Now() + 500
									return
								end
							end
						end
					end
				end
			end
		end
	end
end

function ml_mesh_mgr.ResetOMC()
	d("OMC was reset.")
	ml_mesh_mgr.OMCStartPosition = nil
	ml_mesh_mgr.OMCEndposition = nil
	ml_mesh_mgr.OMCFacingDirection = nil
	ml_mesh_mgr.OMCType = nil
	ml_mesh_mgr.OMCIsHandled = false
	ml_mesh_mgr.OMCStartPositionReached = false
	ml_mesh_mgr.OMCJumpStartedTimer = 0
	ml_mesh_mgr.OMCFlightStarted = 0
	ml_mesh_mgr.OMCFlightJumps = 0
	ml_mesh_mgr.OMCAltitudeReached = 0
	ml_mesh_mgr.OMCFlightAscend = 0
	ml_mesh_mgr.OMCFlightForward = 0
	ml_mesh_mgr.OMCMounted = 0
	ml_mesh_mgr.OMCThrottle = 0
	ml_mesh_mgr.OMCLastDistance = 0
	ml_mesh_mgr.OMCStartingDistance = 0
	ml_mesh_mgr.OMCTarget = 0
end

function ml_mesh_mgr.IsFacing(pos)
	local ppos = Player.pos
	local epos = pos
	local playerHeading = ConvertHeading(ppos.h)
	
	local playerAngle = math.atan2(epos.x - ppos.x, epos.z - ppos.z) 
	local deviation = playerAngle - playerHeading
	local absDeviation = math.abs(deviation)
	local leftover = math.abs(absDeviation - math.pi)
	
	if (leftover > (math.pi * .99) and leftover < (math.pi * 1.01)) then
		return true
	else
		d("Leftover return was :"..tostring(leftover))
	end
    return false
end

function ml_mesh_mgr.UnpackArgsForOMC( args )
	if ( tonumber(args[3]) ~= nil and tonumber(args[4]) ~= nil and tonumber(args[5]) ~= nil -- OMC Start point
	 and tonumber(args[6]) ~= nil and tonumber(args[7]) ~= nil and tonumber(args[8]) ~= nil -- OMC END point
	 and tonumber(args[9]) ~= nil and tonumber(args[10]) ~= nil and tonumber(args[11]) ~= nil -- OMC Start point-Facing direction
	) then
		return {tonumber(args[3]),tonumber(args[4]),tonumber(args[5]) },{ tonumber(args[6]),tonumber(args[7]),tonumber(args[8])},{tonumber(args[9]),tonumber(args[10]),tonumber(args[11])}
	 else
		d("No valid positions for OMC reveived! ")
	 end
end


RegisterEventHandler("Gameloop.OffMeshConnectionReached",ml_mesh_mgr.HandleOMC)
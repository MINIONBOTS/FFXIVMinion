-- Extends the ml_mesh_mgr.lua
-- Game specific OffMeshConnection Handling
-- Handler for different OMC types
function ml_mesh_mgr.HandleOMC( ... )
	if (Now() > ml_mesh_mgr.OMCThrottle and not ml_mesh_mgr.OMCStartPositionReached) then
		local args = {...}
		local OMCType = args[2]	
		local OMCStartPosition,OMCEndposition,OMCFacingDirection = ml_mesh_mgr.UnpackArgsForOMC( args )
		d("OMC REACHED : "..tostring(OMCType))
		
		if ( table.valid(OMCStartPosition) and table.valid(OMCEndposition) and table.valid(OMCFacingDirection) ) then
			if (not IsFlying()) then
				ml_mesh_mgr.OMCStartPosition = OMCStartPosition
				ml_mesh_mgr.OMCEndposition = OMCEndposition
				ml_mesh_mgr.OMCFacingDirection = OMCFacingDirection
				ml_mesh_mgr.OMCType = OMCType
				ml_mesh_mgr.OMCIsHandled = true
				d("OMC ["..tostring(OMCType).."] accepted and handler initiated.")
			else
				d("OMC ["..tostring(OMCType).."] rejected due to flight.")
				ml_mesh_mgr.OMCIsHandled = false
			end
		else
			d("OMC ["..tostring(OMCType).."] rejected due to invalid setup.")
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

ml_mesh_mgr.receivedInstructions = {}
function ml_mesh_mgr.ParseInstructions(data)
	d("Received instruction set.")
	ml_mesh_mgr.receivedInstructions = {}
	
	if (table.valid(data)) then
		local itype,iparams = nil,nil
		for i,instruction in pairsByKeys(data) do
			itype,iparams = instruction[1],instruction[2]
			if (itype == "Ascend") then
				table.insert(ml_mesh_mgr.receivedInstructions,
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
				table.insert(ml_mesh_mgr.receivedInstructions, 
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
				table.insert(ml_mesh_mgr.receivedInstructions, 
					function () 
						if (IsFlying()) then
							Player:SetPitch(1.377) 
							if (not Player:IsMoving()) then
								Player:Move(FFXIV.MOVEMENT.FORWARD)
								ml_global_information.Await(3000, function () return Player:IsMoving() end)
							end
							ml_mesh_mgr.AddThrottleTime(300)
							return false
						else
							return true
						end
					end
				)
			elseif (itype == "StraightDescend") then
				table.insert(ml_mesh_mgr.receivedInstructions, 
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
				table.insert(ml_mesh_mgr.receivedInstructions, 
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
				table.insert(ml_mesh_mgr.receivedInstructions, 
					function () 
						if (not Player.ismounted) then
						
							local mountlist = ActionList("type=13")
							if (table.valid(mountlist)) then
								--First pass, look for our named mount.
								for k,v in pairsByKeys(mountlist) do
									if (v.name == gMountName) then
										local acMount = ActionList:Get(v.id,13)
										if (acMount and acMount.isready) then
											acMount:Cast()
											ml_global_information.Await(5000, function () return Player.ismounted end)
											return false
										end
									end
								end
								
								local acChocobo = ActionList:Get(1,13)
								if (acChocobo and acChocobo.isready) then
									acChocobo:Cast()
									ml_global_information.Await(5000, function () return Player.ismounted end)
									return false
								end
							end
							
							return false
						else
							return true
						end
					end
				)
			elseif (itype == "Dismount") then
				table.insert(ml_mesh_mgr.receivedInstructions, 
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
				table.insert(ml_mesh_mgr.receivedInstructions, 
					function () 
						ml_mesh_mgr.AddThrottleTime(length)
						return true						
					end
				)
			elseif (itype == "Interact") then
				local interactid = tonumber(iparams[1]) or 0
				local complete = tonumber(iparams[2]) or ""
				table.insert(ml_mesh_mgr.receivedInstructions, 
					function ()
						if (interactid ~= 0) then
							local interacts = EntityList("targetable,contentid="..tostring(interactid)..",maxdistance=15")
							if (table.valid(interacts)) then
								local i,interactable = next(interacts)
								if (table.valid(interactable) and interactable.targetable) then
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
				table.insert(ml_mesh_mgr.receivedInstructions, 
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
						table.insert(ml_mesh_mgr.receivedInstructions, 
							function () 
								Player:SetFacing(pos.x,pos.y,pos.z) 
								return true
							end
						)
					else
						table.insert(ml_mesh_mgr.receivedInstructions, 
							function () 
								Player:SetFacing(pos.x) 
								ml_global_information.Await(1000, function () return Player.pos.h == pos.x end)
								return true
							end
						)
					end
				end
			elseif (itype == "MoveForward") then
				table.insert(ml_mesh_mgr.receivedInstructions, 
					function () 
						Player:Move(FFXIV.MOVEMENT.FORWARD) 
						ml_global_information.Await(3000, function () return Player:IsMoving() end)
						return true
					end
				)
			elseif (itype == "CheckIfLocked") then
				table.insert(ml_mesh_mgr.receivedInstructions, 
					function () 
						return IsPositionLocked()
					end
				)
			elseif (itype == "CheckIfMoveable") then
				table.insert(ml_mesh_mgr.receivedInstructions, 
					function () 
						return not IsPositionLocked()
					end
				)
			elseif (itype == "Action") then
				local actionid = iparams[1] or 0
				local actiontype = iparams[2] or 0 
				local targetid = iparams[3] or 0
				
				table.insert(ml_mesh_mgr.receivedInstructions, 
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
				table.insert(ml_mesh_mgr.receivedInstructions, 
					function () 	
						if (not Player:IsMoving()) then
							if (Player:Teleport(aetheryteid)) then
								ml_global_information.Await(10000, function () return IsControlOpen("NowLoading") end)
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
				table.insert(ml_mesh_mgr.receivedInstructions, 
					function () 	
						if (not Player:IsMoving()) then
							local casting = Player.castinginfo.channelingid
							local returnHome = ActionList:Get(6)
							
							if (returnHome and returnHome.isready) then
								if (returnHome:Cast()) then
									ml_global_information.Await(10000, function () return IsControlOpen("NowLoading") end)
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
				local dist2d = ((iparams[5] and iparams[5] ~= 0) and iparams[5]) or 0.4
				
				if (pos.x ~= nil and pos.y ~= nil and pos.z ~= nil) then
					table.insert(ml_mesh_mgr.receivedInstructions, 
						function ()
							local myPos = Player.pos
							return (Distance3DT(pos,myPos) <= dist3d and Distance2DT(pos,myPos) <= dist2d)
						end
					)
				end	
			elseif (itype == "MoveStraightTo") then
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
					table.insert(ml_mesh_mgr.receivedInstructions, 
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
												if (Distance3DT(pos,myPos) <= 2 and Distance2DT(pos,myPos) <= 0.5) then
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
					table.insert(ml_mesh_mgr.receivedInstructions, 
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
					table.insert(ml_mesh_mgr.receivedInstructions, 
						function ()
							Player:SetFacing(pos.x,pos.y,pos.z)
							Player:Move(FFXIV.MOVEMENT.FORWARD)
							ml_global_information.AwaitDo(100, 120000, 
								function ()
									if (Player:GetSpeed(FFXIV.MOVEMENT.FORWARD) == 0) then
										return true
									end
									local myPos = Player.pos
									d("3D:"..tostring(ml_mesh_mgr.Distance3DT(pos,myPos))..", 2D:"..tostring(Distance2DT(pos,myPos)))
									return (ml_mesh_mgr.Distance3DT(pos,myPos) <= dist3d and Distance2DT(pos,myPos) <= dist2d)
								end,
								function ()
									local myPos = Player.pos
									SmartTurn(pos)
									--local distNext = ml_mesh_mgr.Distance2DT(myPos,pos)
									local distNext = Distance2DT(myPos,pos)
									local pitch = math.atan2((myPos.y - pos.y), distNext)
									
									if (GetPitch() ~= pitch) then
										Player:SetPitch(pitch)
									end
								end,
								function ()
									if (Player:GetSpeed(FFXIV.MOVEMENT.FORWARD) > 0) then
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
					table.insert(ml_mesh_mgr.receivedInstructions, 
						function ()
							Player:SetFacing(pos.x,pos.y,pos.z)
							Player:Move(FFXIV.MOVEMENT.FORWARD)
							ml_global_information.AwaitDo(100, 120000, 
								function ()
									if (Player:GetSpeed(FFXIV.MOVEMENT.FORWARD) == 0) then
										return true
									end
									local myPos = Player.pos
									d("3D:"..tostring(ml_mesh_mgr.Distance3DT(pos,myPos))..", 2D:"..tostring(Distance2DT(pos,myPos)))
									return (ml_mesh_mgr.Distance3DT(pos,myPos) <= dist3d and Distance2DT(pos,myPos) <= dist2d)
								end,
								function ()
									local myPos = Player.pos
									SmartTurn(pos)
									--local distNext = ml_mesh_mgr.Distance3DT(myPos,pos)
									local distNext = Distance2DT(myPos,pos)
									local pitch = math.atan2((myPos.y - pos.y), distNext)
									if (GetPitch() ~= pitch) then
										Player:SetPitch(pitch)
									end
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

function ml_mesh_mgr.AddThrottleTime(t)
	ml_mesh_mgr.OMCThrottle = Now() + t
end

function ml_mesh_mgr.OMC_Handler_OnUpdate( tickcount )
	if (table.valid(ml_mesh_mgr.receivedInstructions)) then
		--d("Running instruction set.")
		--ml_global_information.lastrun = Now()
		ml_global_information.nextRun = Now() + 1
		
		if (Now() > ml_mesh_mgr.OMCThrottle) then
			ffxivminion.UpdateGlobals()
			
			local newInstruction = ml_mesh_mgr.receivedInstructions[1]
			if (newInstruction and type(newInstruction) == "function") then
				local retval = newInstruction()
				if (retval == true) then
					table.remove(ml_mesh_mgr.receivedInstructions,1)
				end
			end			
		end
		return
	end
 
	if ( ml_mesh_mgr.OMCIsHandled ) then	
		
		--ml_global_information.lastrun = Now()
		ml_global_information.nextRun = Now() + 1
		
		if (not Player.alive) then
			Player:Stop()
			ml_mesh_mgr.ResetOMC()
			return
		end
		
		if (Now() > ml_mesh_mgr.OMCThrottle) then
			ffxivminion.UpdateGlobals()
			
			-- Set all position data, pPos = Player pos, sPos = start omc pos and heading, ePos = end omc pos
			local pPos = Player.pos
			local mPos,mDist = NavigationManager:GetClosestPointOnMesh(pPos)
			local sPos = {
							x = tonumber(ml_mesh_mgr.OMCStartPosition[1]), y = tonumber(ml_mesh_mgr.OMCStartPosition[2]), z = tonumber(ml_mesh_mgr.OMCStartPosition[3]),
							h = tonumber(ml_mesh_mgr.OMCFacingDirection[1]),
						}
			local ePos = {
							x = tonumber(ml_mesh_mgr.OMCEndposition[1]), y = tonumber(ml_mesh_mgr.OMCEndposition[2]), z = tonumber(ml_mesh_mgr.OMCEndposition[3]),
						}
			
			if ( ml_mesh_mgr.OMCStartPositionReached == false ) then
				if ( table.valid(sPos) ) then
					-- obk: START-INTERACT
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
							local target = MGetTarget()
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
					
					-- obk: START-LIFT
					elseif (ml_mesh_mgr.OMCType == "OMC_LIFT") then
						local meshdist = PDistance3D(sPos.x,sPos.y,sPos.z,mPos.x,mPos.y,mPos.z)
						ml_mesh_mgr.OMCMeshDistance = meshdist
						if ((not Player.ismounted and meshdist < 0.75) or (Player.ismounted and meshdist < 1)) then
							Player:SetFacing(sPos.h) -- Set heading
							ml_mesh_mgr.OMCStartingDistance = meshdist
							ml_mesh_mgr.OMCStartPositionReached = true
							
							if ( not Player:IsMoving() ) then
								Player:Move(FFXIV.MOVEMENT.FORWARD)
							end
							
							d("Starting state reached for : " .. ml_mesh_mgr.OMCType)
							return
						end
					
					-- obk: START-PORTAL
					elseif (ml_mesh_mgr.OMCType == "OMC_PORTAL") then
						local meshdist = PDistance3D(sPos.x,sPos.y,sPos.z,mPos.x,mPos.y,mPos.z)
						ml_mesh_mgr.OMCMeshDistance = meshdist
						if ((not Player.ismounted and meshdist < 1.7) or (Player.ismounted and meshdist < 2.5)) then
							ml_mesh_mgr.OMCStartingDistance = meshdist
							ml_mesh_mgr.OMCStartPositionReached = true
							
							d("Starting state reached for : " .. ml_mesh_mgr.OMCType)
							return
						end
					
					-- obk: START-OTHERS
					else
						local meshdist = PDistance3D(sPos.x,sPos.y,sPos.z,mPos.x,mPos.y,mPos.z)
						ml_mesh_mgr.OMCMeshDistance = meshdist
						if ((Player:IsMoving() and ((not Player.ismounted and meshdist < 0.75) or (Player.ismounted and meshdist < 1))) or
							(not Player:IsMoving() and ((not Player.ismounted and meshdist < 1.5) or (Player.ismounted and meshdist < 1.75))))
						then
							Player:SetFacing(sPos.h) -- Set heading
							ml_mesh_mgr.OMCStartingDistance = meshdist
							ml_mesh_mgr.OMCStartPositionReached = true
							
							if ( not Player:IsMoving() ) then
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
				
				-- obk: PROCESS-JUMP
				if ( ml_mesh_mgr.OMCType == "OMC_JUMP" ) then
					ml_mesh_mgr.OMCThrottle = Now() + 100
					
					if ( table.valid(ml_mesh_mgr.OMCEndposition) ) then
						-- We are at our start OMC point and are facing the correct direction, now start moving forward and jump
						local h = (math.floor(sPos.h * 100) / 100)
						local ph = (math.floor(pPos.h * 100) / 100)
						
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
				
				-- obk: PROCESS-WALK
				elseif ( ml_mesh_mgr.OMCType == "OMC_WALK" ) then
					ml_mesh_mgr.OMCThrottle = Now() + 150
					
					if ( table.valid(ml_mesh_mgr.OMCEndposition) ) then								
						local facingPos = {x = ePos.x,y = ePos.y,z = ePos.z}
						Player:SetFacing(facingPos)
					
						if ( not Player:IsMoving() ) then 
							Player:Move(FFXIV.MOVEMENT.FORWARD) 
						end
						
						if (c_stuck:evaluate()) then
							e_stuck:execute()
							return
						end
						
						if (Player:IsJumping() and (pPos.y < (ePos.y - 3))) then
							Player:Stop()
							ml_mesh_mgr.ResetOMC()
						end
						
						if (not Player:IsJumping()) then
							local dist = PDistance3D(ePos.x,ePos.y,ePos.z,pPos.x,pPos.y,pPos.z)
							if ((not Player.ismounted and dist < 1.7) or (Player.ismounted and dist < 2.7)) then
								Player:Stop()
								ml_mesh_mgr.ResetOMC()
							end
						end
					end
				
				-- obk: PROCESS-LIFT
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
				
				-- obk: PROCESS-TELEPORT
				elseif ( ml_mesh_mgr.OMCType == "OMC_TELEPORT" ) then
					if ( table.valid(ml_mesh_mgr.OMCEndposition) and gTeleportHack) then
						if ( Player:IsMoving() ) then Player:Stop() end
						-- Add playerdetection when distance to OMCEndposition is > xxx
						local enddist = PDistance3D(ePos.x,ePos.y,ePos.z,pPos.x,pPos.y,pPos.z)
						if ( enddist > 2.20 ) then
							--if ( TableSize(EntityList("nearest,player,maxdistance=15"))>0 ) then
								--ml_log("Need to teleport but players are nearby..waiting..")
								--ml_mesh_mgr.OMCThrottle = tickcount + 2000
								--ml_global_information.Lasttick = ml_global_information.Lasttick + 2000
								--Player:Stop()
								--return
							--end
						end
						Hacks:TeleportToXYZ(ePos.x, ePos.y, ePos.z)
						d("OMC Endposition reached..")
						ml_mesh_mgr.ResetOMC()
						Player:Stop()
						ml_mesh_mgr.OMCThrottle = Now() + 2000
					else
						d("Denied a teleport OMC.")
						ml_mesh_mgr.ResetOMC()
					end
				
				-- obk: PROCESS-INTERACT
				elseif ( ml_mesh_mgr.OMCType == "OMC_INTERACT" ) then
					ml_mesh_mgr.OMCThrottle = Now() + 100
					
					if (IsControlOpen("SelectYesno")) then
						if (IsControlOpen("_NotificationParty")) then
							PressYesNo(false)
						else
							PressYesNo(true)
						end
						ml_mesh_mgr.OMCThrottle = Now() + 1500
						return
					end
					
					if (MIsLoading()) then
						ml_mesh_mgr.OMCThrottle = Now() + 1500
						ml_mesh_mgr.ResetOMC()
						return
					end
					
					if (IsControlOpen("SelectString") or IsControlOpen("SelectIconString")) then
						SelectConversationIndex(1)
						ml_mesh_mgr.OMCThrottle = Now() + 1000
						return
					end
					
					if (IsPositionLocked()) then
						ml_mesh_mgr.OMCThrottle = Now() + 500
						return
					end
					
					-- If we're now not on the starting spot, we were moved somewhere.
					local movedDistance = PDistance3D(sPos.x,sPos.y,sPos.z,mPos.x,mPos.y,mPos.z)
					if (movedDistance > 3) then
						ml_mesh_mgr.OMCThrottle = Now() + 100
						ml_mesh_mgr.ResetOMC()
						return
					end
					
					local target = MGetTarget()
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
				
				-- obk: PROCESS-PORTAL
				elseif ( ml_mesh_mgr.OMCType == "OMC_PORTAL" ) then
					ml_mesh_mgr.OMCThrottle = Now() + 100
					
					if ( table.valid(ml_mesh_mgr.OMCEndposition) ) then						
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
										if (Player:IsMoving()) then
											d("Throwing Stop() in mount block.")
											Player:Stop()
											ml_mesh_mgr.OMCThrottle = Now() + 100
											return
										else
											Mount()
											ml_mesh_mgr.OMCThrottle = Now() + 1000
											return
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
								if (pPos.y > minaltitude) then
									ml_mesh_mgr.OMCMinAltitude = pPos.y + 20
									d("Setting min altitude to "..tostring(pPos.y + 20))
								else
									ml_mesh_mgr.OMCMinAltitude = minaltitude
									d("Setting min altitude to "..tostring(minaltitude))
								end
								return
							end
							
							if (pPos.y < ml_mesh_mgr.OMCMinAltitude) then
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
						
						local dist3D = PDistance3D(pPos.x,pPos.y,pPos.z,ePos.x,ePos.y,ePos.z)
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
									if (table.valid(ml_mesh_mgr.OMCFlightForward)) then
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

function ml_mesh_mgr.ResetSpecial()
	d("Special handler was reset.")
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
	
	ml_mesh_mgr.HandlingSpecial = false
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

function ml_mesh_mgr.Distance3D(x1,y1,z1,x2,y2,z2)
	local dx = (x1 - x2)
	local dy = (y1 - y2)
	local dz = (z1 - z2)
	local dist3d = math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
	
	return dist3d
end
function ml_mesh_mgr.Distance3DT(pos1,pos2)
	local distance = ml_mesh_mgr.Distance3D(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z)
	return round(distance,2)
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
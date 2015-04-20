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
			ml_global_information.Player_Position = shallowcopy(Player.pos)
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
							local interacts = EntityList("nearest,type=7,chartype=0,maxdistance=5")
							d("Scanning for objects to interact with.")
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
							local interacts = EntityList("nearest,type=3,chartype=0,maxdistance=5")
							d("Scanning for NPCs to interact with.")
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
						
						if (not Player:IsJumping() and ml_mesh_mgr.OMCJumpStartedTimer == 0 ) then
							if (ph ~= h) then
								Player:SetFacing(sPos.h)
								return
							end
						
							if ((not Player.ismounted and Player:GetSpeed(FFXIV.MOVEMENT.FORWARD) < 4) or 
								(Player.ismounted and Player:GetSpeed(FFXIV.MOVEMENT.FORWARD) < 7))
							then
								return
							end
		
							if (ml_mesh_mgr.OMCJumpStartedTimer == 0 ) then
								Player:Jump()
								ml_mesh_mgr.OMCJumpStartedTimer = Now()
								return
							end
						end
						
						--local dist = Distance3D(ePos.x,ePos.y,ePos.z,pPos.x,pPos.y,pPos.z)										
						--local dist2d = Distance2D(ePos.x,ePos.y,pPos.x,pPos.y)
						--ml_mesh_mgr.OMCLastDistance = dist
						
						if (Player:IsJumping()) then
							if (ml_mesh_mgr.OMCJumpStartedTimer ~= 0 and TimeSince(ml_mesh_mgr.OMCJumpStartedTimer) > 300) then
								Player:Stop()
								ml_mesh_mgr.OMCThrottle = Now() + 100
								return
							end
						end
						
						if (not Player:IsJumping()) then
							ml_mesh_mgr.ResetOMC()
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
						
						if (Player:IsJumping()) then
							Player:Stop()
							ml_mesh_mgr.ResetOMC()
						end
						
						local dist = Distance3D(ePos.x,ePos.y,ePos.z,pPos.x,pPos.y,pPos.z)
						if ((not Player.ismounted and dist < 1) or (Player.ismounted and dist < 1.5)) then
							Player:Stop()
							ml_mesh_mgr.ResetOMC()
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
					if ( ValidTable(ml_mesh_mgr.OMCEndposition) ) then
						if ( not ml_global_information.Player_IsMoving ) then Player:Move(FFXIV.MOVEMENT.FORWARD) end
						local dist = Distance3D(ePos.x,ePos.y,ePos.z,pPos.x,pPos.y,pPos.z)
						if ( dist < 1.00 ) then
							d("OMC Endposition reached..")
							ml_mesh_mgr.ResetOMC()
							Player:Stop()
							ml_mesh_mgr.OMCThrottle = Now() + 2000
						else
							return
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
	ml_mesh_mgr.OMCThrottle = 0
	ml_mesh_mgr.OMCLastDistance = 0
	ml_mesh_mgr.OMCStartingDistance = 0
	ml_mesh_mgr.OMCTarget = 0
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
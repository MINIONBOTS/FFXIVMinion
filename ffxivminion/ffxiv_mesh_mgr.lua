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
					--local dist = Distance3D(sPos.x,sPos.y,sPos.z,pPos.x,pPos.y,pPos.z)
					local meshdist = Distance3D(sPos.x,sPos.y,sPos.z,mPos.x,mPos.y,mPos.z)
					if ((not Player.ismounted and meshdist < 0.75) or (Player.ismounted and meshdist < 1)) then -- Close enough to start
						--d("OMC StartPosition reached..Facing Target Direction..")
						Player:Stop()
						Player:SetFacing(sPos.h) -- Set heading
						
						ml_mesh_mgr.OMCStartPositionReached = true
						ml_mesh_mgr.OMCThrottle = Now() + 100
						return
					end
				else
					ml_error("Invalid/missing start position for OMC_JUMP")
				end
			else
				if ( ml_mesh_mgr.OMCType == "OMC_JUMP" ) then
					if ( ValidTable(ml_mesh_mgr.OMCEndposition) ) then
						-- We are at our start OMC point and are facing the correct direction, now start moving forward and jump
						if ( not ml_global_information.Player_IsMoving ) then
							Player:Move(FFXIV.MOVEMENT.FORWARD)
							
							-- give the bot some time to gain speed before we jump for longer jumps
							local dist = Distance2D(ePos.x,ePos.y,sPos.x,sPos.y)
							local heightdiff = math.abs(ePos.y - pPos.y)
							ml_mesh_mgr.OMCThrottle = Now() + 150
							return
						end
		
						if (ml_mesh_mgr.OMCJumpStartedTimer == 0 ) then
							--d("Initiated jump.")
							Player:Jump()
							ml_mesh_mgr.OMCJumpStartedTimer = Now()
							return
						end
						
						local dist = Distance3D(ePos.x,ePos.y,ePos.z,pPos.x,pPos.y,pPos.z)										
						local dist2d = Distance2D(ePos.x,ePos.y,pPos.x,pPos.y)
						ml_mesh_mgr.OMCLastDistance = dist
						
						--d("DISTCHECK: "..tostring(dist).."  2d: "..tostring(dist2d))
						if (not Player:IsJumping() and ml_mesh_mgr.OMCJumpStartedTimer ~= 0 and TimeSince(ml_mesh_mgr.OMCJumpStartedTimer) > 150) then
							--d("No longer jumping, must have succeeded.")
							Player:Stop()
							ml_mesh_mgr.ResetOMC()
						elseif (Player:IsJumping() and ml_mesh_mgr.OMCJumpStartedTimer ~= 0 and TimeSince(ml_mesh_mgr.OMCJumpStartedTimer) > 1500) then
							--d("We have no ending point, so reset it here since we don't care about accuracy.")
							Player:Stop()
							ml_mesh_mgr.ResetOMC()
						end
						
						
						--[[
						if ( ml_mesh_mgr.OMCJumpStartedTimer > Now() and not Player:IsJumping()) then
							if ( dist < 0.35 or (dist < 0.5 and dist2d < 0.10)) then
								--d("OMC Endposition reached exactly..")
								Player:Stop()
								ml_mesh_mgr.ResetOMC() -- turn off omc handler
								ml_mesh_mgr.OMCThrottle = Now() + 150
								
							elseif(ml_mesh_mgr.OMCJumpStartedTimer ~= 0 and TimeSince(ml_mesh_mgr.OMCJumpStartedTimer) > 350) then
								d("We landed already")
								Player:Stop()
								ml_mesh_mgr.ResetOMC()
								ml_mesh_mgr.OMCThrottle = Now() + 150	
							elseif( dist > 5.00 and  ml_mesh_mgr.OMCJumpStartedTimer ~= 0 and TimeSince(ml_mesh_mgr.OMCJumpStartedTimer) > 1500)then
								d("We failed to land on the enposition..use teleport maybe?")
								Player:Stop()
								ml_mesh_mgr.ResetOMC()
												
							elseif(ePos.y < sPos.y and pPos.y < ePos.y and math.abs(ePos.y - pPos.y) > 1 and ml_mesh_mgr.OMCJumpStartedTimer ~= 0 and TimeSince(ml_mesh_mgr.OMCJumpStartedTimer) > 500 ) then
								d("We felt below the OMCEndpoint height..means we missed the landingpoint..")
								Player:Stop()
								ml_mesh_mgr.ResetOMC()
								ml_global_information.Lasttick = ml_global_information.Lasttick + 500
							
							else
								d("Something else happened in the JUMP OMC.")
								return
							end
						elseif (Player:IsJumping() and ml_mesh_mgr.OMCJumpStartedTimer ~= 0 and TimeSince(ml_mesh_mgr.OMCJumpStartedTimer) > 3000 and (dist > ml_mesh_mgr.OMCLastDistance)) then
							d("We've been falling for a really long time and we're moving away from the goal, maybe resort to teleport here.")
							Player:Stop()
							ml_mesh_mgr.ResetOMC()
							ml_mesh_mgr.OMCThrottle = Now() + 500
						end
						--]]
					end
					
				
				elseif ( ml_mesh_mgr.OMCType == "OMC_WALK" ) then
					if ( ValidTable(ml_mesh_mgr.OMCEndposition) ) then
						if ( not ml_global_information.Player_IsMoving ) then Player:Move(FFXIV.MOVEMENT.FORWARD) end
						Player:SetFacing(ePos.x,ePos.y,ePos.z)
						local dist = Distance3D(ePos.x,ePos.y,ePos.z,pPos.x,pPos.y,pPos.z)
						if ( dist < 0.50 ) then
							d("OMC Endposition reached..")
							ml_mesh_mgr.ResetOMC()
							Player:Stop()
							ml_mesh_mgr.OMCThrottle = Now() + 2000
						else
							return
						end
					end
				
				elseif ( ml_mesh_mgr.OMCType == "OMC_LIFT" ) then
					if ( ValidTable(ml_mesh_mgr.OMCStartPosition) ) then
						if ( not ml_global_information.Player_IsMoving ) then Player:Move(FFXIV.MOVEMENT.FORWARD) end
						local dist = Distance3D(sPos.x,sPos.y,sPos.z,pPos.x,pPos.y,pPos.z)
						if ( dist > 2.50 ) then
							d("OMC Endposition reached..")
							ml_mesh_mgr.ResetOMC()
							Player:Stop()
							ml_mesh_mgr.OMCThrottle = Now() + 2000
						else
							return
						end
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
					Player:Stop()
					d("OMC Endposition reached..")
					ml_mesh_mgr.ResetOMC()
					Player:Interact()
					ml_mesh_mgr.OMCThrottle = Now() + 2000
					
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
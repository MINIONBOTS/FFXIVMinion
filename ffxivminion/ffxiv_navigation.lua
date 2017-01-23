-- Extends minionlib's ml_navigation.lua by adding the game specific navigation handler

--*** ALL 4 LISTS BELOW ARE USED / MODIFY-ABLE IN THE NAVIGATION->MESHMANAGER MINIONLIB UI
-- Distance to the next node in the path at which the ml_navigation.pathindex is iterated 
ml_navigation.NavPointReachedDistances = { 	
	["3dwalk"] = 2,		
	["2dwalk"] = 0.3,
	["3dmount"] = 5,
	["2dmount"] = 0.5,
	["3dfly"] = 5,
	["2dfly"] = 1,
	["3dflysc"] = 5,
	["2dflysc"] = 3,	
}
-- Distance to the next node in the path, in case it is an OffMeshConnection, at which the ml_navigation.pathindex is iterated 
ml_navigation.OMCReachedDistances = { 			
	["3dwalk"] = 2,		
	["2dwalk"] = 0.3,
	["3dmount"] = 5,
	["2dmount"] = 0.5,
	["3dfly"] = 5,
	["2dfly"] = 1,
	["3dflysc"] = 5,
	["2dflysc"] = 3,
} 
-- We have a path already and a new one is requested, if the distance between old and new target position is larger than this one, a new path is being build.
ml_navigation.NewPathDistanceThresholds = { 	
	["3dwalk"] = 0.1,		
	["2dwalk"] = 0.1,
	["3dmount"] = 0.1,
	["2dmount"] = 0.1,
	["3dfly"] = 0.1,
	["2dfly"] = 0.1,
	["3dflysc"] = 0.1,
	["2dflysc"] = 0.1,
}
-- The max. distance the playerposition can be away from the current path. (The Point-Line distance between player and the last & next pathnode)
ml_navigation.PathDeviationDistances = { 		
	["3dwalk"] = 3,		
	["2dwalk"] = 2,
	["3dmount"] = 3,
	["2dmount"] = 2,
	["3dfly"] = 3,
	["2dfly"] = 2,
	["3dflysc"] = 3,
	["2dflysc"] = 2,
}	

-- Return the EXACT NAMES you used above in the 4 tables for movement type keys
ml_navigation.GetMovementType = function() 
	if ( not Player.ismounted ) then 
		return "2dwalk" 
	elseif ( Player.flying.isflying ) then
		return "3dmount"
	else
		return "2dmount"
	end
end
		
ml_navigation.CanRun = function() return GetGameState() == FFXIV.GAMESTATE.INGAME end 			-- Return true here, if the current GameState is "ingame" aka Player and such values are available
ml_navigation.StopMovement = function() Player:Stop() end				 		-- Stop the navi + Playermovement
ml_navigation.IsMoving = function() return Player:IsMoving() end				-- Take a wild guess											
ml_navigation.avoidanceareasize = 2

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

-- Often  used function to determine if the next node in the path is reached
function ml_navigation:IsGoalClose(ppos,node)
	local goaldist,goaldist2d = ml_navigation:GetRaycast_Player_Node_Distance(ppos,node)
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


-- for replacing the original c++ Player:MoveTo with our lua version.  Every argument behind x,y,z is optional and the default values from above's tables will be used depending on the current movement type ! 
function Player:MoveTo(x, y, z, navpointreacheddistance, navigationmode, randomnodes, smoothturns)
		-- ml_navigation:MoveTo(x, y, z, navigationmode, randomnodes, smoothturns, navpointreacheddistance, newpathdistancetreshold, pathdeviationdistance)
	ffnav.currentGoal = { x = x, y = y, z = z }
	ffnav.currentParams = { navmode = navigationmode, range = navpointreacheddistance, randompath = randomnodes, smoothturns = smoothturns}
	return ml_navigation:MoveTo(x, y, z, navigationmode, randomnodes, smoothturns, navpointreacheddistance)
end

-- Overriding  the (old) c++ Player:Stop(), to handle the additionally needed navigation functions
function Player:Stop()
	ml_navigation:ResetCurrentPath()
	ml_navigation:ResetOMCHandler()
	ffnav.currentGoal = {}
	ffnav.currentParams = {}
	ffnav.yield = {}
	ffnav.process = {}
	Player:StopMovement()	-- The "new" c++ sided STOP which stops the player's movement completely
end

-- Handles the actual Navigation along the current Path. Is not supposed to be called manually! 
-- Also handles OMCs
function ml_navigation.Navigate(event, ticks )	
	if ((ticks - (ml_navigation.lastupdate or 0)) > 50) then 
		ml_navigation.lastupdate = ticks
				
		if ( ml_navigation.CanRun() ) then				
			local ppos = Player.pos
			
			-- Normal Navigation Mode
			if ( ml_navigation.pathsettings.navigationmode == 1 and not ffnav.IsProcessing()) then
				
				if ( table.valid(ml_navigation.path) and table.size(ml_navigation.path) > ml_navigation.pathindex ) then					
					local nextnode = ml_navigation.path[ ml_navigation.pathindex ]
			
			-- Ensure Position: Takes a second to make sure the player is really stopped at the wanted position (used for precise OMC bunnyhopping and others where the player REALLY has to be on the start point & facing correctly)
					if ( table.valid (ml_navigation.ensureposition) and ml_navigation:EnsurePosition() ) then						
						return
					end
					
		-- OffMeshConnection Navigation
					if (nextnode.type == "OMC_END") then
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
							
							if ( Player:IsJumping()) then
								if ( not ml_navigation.omc_startheight ) then ml_navigation.omc_startheight = ppos.y end
								-- Additionally check if we are "above" the target point already, in that case, stop moving forward
								local nodedist = ml_navigation:GetRaycast_Player_Node_Distance(ppos,nextnode)
								if ( nodedist < ml_navigation.NavPointReachedDistances["2dwalk"] or (ppos.y > nextnode.y and math.distance2d(ppos,nextnode) < ml_navigation.NavPointReachedDistances["2dwalk"]) ) then
									d("[Navigation] - We are above the OMC_END Node, stopping movement. ("..tostring(math.round(nodedist,2)).." < "..tostring(ml_navigation.NavPointReachedDistances["2dwalk"])..")")
									Player:StopMovement()
									if ( omc.precise == nil or omc.precise == true  ) then
										ml_navigation:SetEnsurePosition(nextnode)
									end
									
								-- If Playerheight is lower than 4*omcreached dist AND Playerheight is lower than 4* our Startposition -> we fell below the OMC START & END Point
								elseif( ( ppos.y+ 4*ml_navigation.NavPointReachedDistances["2dwalk"]) < (nextnode.y) and ( ppos.y + 4*ml_navigation.NavPointReachedDistances["2dwalk"]) <  ml_navigation.omc_startheight) then
									if ( ml_navigation.omcteleportallowed and math.distance3d(ppos,nextnode) < ml_navigation.NavPointReachedDistances["2dwalk"]*10) then										
										d("SetEnsurePosition JUMP ")
										ml_navigation:SetEnsurePosition(nextnode) 
									else
										d("[Navigation] - We felt below the OMC start & END height, missed our goal...")
										ml_navigation.StopMovement()
									end
								
								else
									Player:Move(FFXIV.MOVEMENT.FORWARD)
									Player:SetFacing(nextnode.x,nextnode.y,nextnode.z) -- doesnt do shit afaik, since you cannot steer once in the air..
								end
							
							else	 
								-- We are still before our Jump
								if ( not ml_navigation.omc_startheight ) then
									local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})
									if ( anglediff > 0.3 ) then
										Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
										
									elseif ( ml_navigation.omc_starttimer == 0 ) then
										ml_navigation.omc_starttimer = ticks										
										Player:Move(FFXIV.MOVEMENT.FORWARD)
										
									elseif ( Player:IsMoving() and ticks - ml_navigation.omc_starttimer > 100 ) then										
										Player:Jump()
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
							ml_navigation:NavigateToNode(ppos,nextnode,1000)
										
						elseif ( omc.type == 3 ) then
						-- OMC Teleport
							Hacks:TeleportToXYZ(nextnode.x,nextnode.y,nextnode.z)
							ml_navigation.pathindex = ml_navigation.pathindex + 1
							
						elseif ( omc.type == 4 ) then
						-- OMC Interact  I AM SO UNSURE IF THAT IS WORKING OR EVEN USED ANYMORE :D:D:D:D
							if (IsControlOpen("SelectYesno")) then
								if (IsControlOpen("_NotificationParty")) then
									UseControlAction("SelectYesno","No")
								else
									UseControlAction("SelectYesno","Yes")
								end
								ml_navigation.lastupdate = ml_navigation.lastupdate + 1500
								return
							end
							
							if (MIsLoading()) then
								ml_navigation.lastupdate = ml_navigation.lastupdate + 1500
								ml_mesh_mgr.ResetOMC()
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
								if (not target or (target and target.id ~= interactnpc)) then
									d("Setting target for interaction : "..interactnpc.name)
									Player:SetTarget(interactnpc)
									ml_navigation.lastupdate = ml_navigation.lastupdate + 500
								
								else
									local npcpos = interactnpc.pos
									Player:SetFacing(npcpos.x,npcpos.y,npcpos.z)
									Player:Interact(interactnpc.id)
									ml_navigation.lastupdate = ml_navigation.lastupdate + 500
								end
							end
						
						elseif ( omc.type == 5 ) then
						-- OMC Portal
							ml_navigation:NavigateToNode(ppos,nextnode,2000)
						
						elseif ( omc.type == 6 ) then
						-- OMC Lift
							ml_navigation:NavigateToNode(ppos,nextnode,1500)						
																
						end	
	
					
		-- Cube Navigation
					elseif (string.contains(nextnode.type,"CUBE") or IsFlying()) then
						
						if (not Player.ismounted) then
							d("[Navigation] - Mount for flight.")
							if (Player:IsMoving()) then
									Player:StopMovement()
									ffnav.Await(3000, function () return not Player:IsMoving() end)
							else
								Mount()
								ffnav.Await(5000, function () return Player.ismounted end)
							end							
						
						else
							if (not IsFlying()) then
								if (Player:IsMoving()) then
									Player:StopMovement()
									ffnav.Await(3000, function () return not Player:IsMoving() end)
								else
									d("[Navigation] - Ascend for flight.")
									ffnav.Ascend()
									ffnav.isascending = true
								end
							
							else
	-- TODO: ADD UNSTUCK HERE !!	
								-- Check if we left our path
								if ( not ffnav.isascending and not ml_navigation:IsStillOnPath(ppos,ml_navigation.pathsettings.pathdeviationdistance) ) then return end
																
								-- Check if the next node is reached:
								local dist3D = math.distance3d(nextnode,ppos)
								if ( ml_navigation:IsGoalClose(ppos,nextnode) ) then
									-- We reached the node
									d("[Navigation] - Cube Node reached. ("..tostring(math.round(dist3D,2)).." < "..tostring(ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()])..")")
									ml_navigation.pathindex = ml_navigation.pathindex + 1							
									ffnav.isascending = nil	-- allow the isstillonpath again after we reached our 1st node after ascending to fly
									
									-- We are flying and the last node was a cube-node. This next one now is a "floor-node", so we need to land now asap
									if (not string.contains(nextnode.type,"CUBE") ) then
										d("[Navigation] - Landing...")
										Player:Move(FFXIV.MOVEMENT.DOWN)
									end
									
								else						
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
										ml_global_information.Await(2000, function () return Player:IsMoving() end)
									end
								end
							end
						end
		
		-- Normal Navigation
					else

-- TODO: ADD UNSTUCK HERE !!
						ml_navigation:NavigateToNode(ppos,nextnode)
										
					end
				
				else
					d("[Navigation] - Path end reached.")
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
		-- We have not yet reached our node
		local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = nextnode.x-ppos.x, y = 0, z = nextnode.z-ppos.z})														
		if ( ml_navigation.pathsettings.smoothturns and anglediff < 35 and nodedist > 5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()] ) then
			Player:SetFacing(nextnode.x,nextnode.y,nextnode.z,true)
		else
			Player:SetFacing(nextnode.x,nextnode.y,nextnode.z)
		end
		
		if (not Player:IsMoving()) then
			Player:Move(FFXIV.MOVEMENT.FORWARD)
			ml_global_information.Await(2000, function () return Player:IsMoving() end)
		end
	end
end


function ml_navigation:IsStillOnPath(ppos,deviationthreshold)	
	if ( ml_navigation.pathindex > 0 ) then
		local treshold = deviationthreshold or ml_navigation.PathDeviationDistances[ml_navigation.GetMovementType()]
		if ( not Player:IsJumping() and math.distancepointline(ml_navigation.path[ml_navigation.pathindex-1],ml_navigation.path[ml_navigation.pathindex],ppos) > treshold) then			
			d("[Navigation] - Player not on Path anymore. - Distance to Path: "..tostring(math.distancepointline(ml_navigation.path[ml_navigation.pathindex-1],ml_navigation.path[ml_navigation.pathindex],ppos)).." > "..tostring(treshold))
			Player:Stop()
			return false
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
			Hacks:TeleportToXYZ(ml_navigation.ensureposition.x,ml_navigation.ensureposition.y,ml_navigation.ensureposition.z)
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
ffnav.currentGoal = {}
ffnav.currentParams = {}

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
			ml_navigation:ResetCurrentPath()
			ml_navigation:ResetOMCHandler()
			local goal = ffnav.currentGoal
			local params = ffnav.currentParams
			Player:MoveTo(goal.x, goal.y, goal.z, params.range, params.navmode, params.randompath, params.smoothturns)
		end
	}
end



--*******************************************
--*******************************************
-- NOT USED STUFF BELOW !?!?! , I 'll leave it here in  case you need some CLUTTER :P
--*******************************************
--*******************************************

-- THIS CANNOT WORK, using a single raycast from the bottom of the feet ..what about the rest of the body and it's actual fat ass ?
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
function ffnav.IsPathClear(pos1,pos2)
	local hit, hitx, hity, hitz = RayCast(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z) 
	return (hit == nil)
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
-- Creates / Updates the current Path, this usually gets spam-called by the bot
function ffnav.MoveToEntity(entityid)		
	local ppos = Player.pos
	local pathSize = ffnav.GetPath(ppos.x,ppos.y,ppos.z,x,y,z)
	return pathSize
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
function ffnav.IsWalking()
	return Player:IsMoving()
end
function ffnav.IsRiding()
	return Player:IsMoving()
end
function ffnav.IsFlying()
	return (Player:GetSpeed(FFXIV.MOVEMENT.FORWARD) > 0)
end
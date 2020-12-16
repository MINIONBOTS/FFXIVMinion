ffxiv_unstuck = {}
ffxiv_unstuck.lastTick = 0
ffxiv_unstuck.lastPos = nil
ffxiv_unstuck.diffTotal = 0
ffxiv_unstuck.count = 0
ffxiv_unstuck.lastCorrection = 0
ffxiv_unstuck.firstStuck = true
ffxiv_unstuck.firstStalled = true
ffxiv_unstuck.firstOffmesh = true
ffxiv_unstuck.disabled = false
ffxiv_unstuck.GUI = {
	open = false,
	visable = true,
	name = "Stuck Report",
}

ffxiv_unstuck.coarse = {
	lastMeasure = 0,
	lastPos = {},
	lastDist = 0,
}

ffxiv_unstuck.State = {
	STUCK 	= { id = 0, name = "STUCK" 	 , stats = 0, ticks = 0, safeticks = 0, minsafeticks = 5, minticks = 5, maxticks = 10},
	OFFMESH = { id = 1, name = "OFFMESH" , stats = 0, ticks = 0, safeticks = 0, minsafeticks = 5, minticks = 25, maxticks = 25},
	STALLED = { id = 2, name = "STALLED" , stats = 0, ticks = 0, safeticks = 0, minsafeticks = 10, minticks = 50, maxticks = 50},
}

function ffxiv_unstuck.Reset()
	for name,state in pairs(ffxiv_unstuck.State) do
		state.ticks = 0
	end
end

c_stuck = inheritsFrom( ml_cause )
e_stuck = inheritsFrom( ml_effect )
e_stuck.state = {}
e_stuck.task = ""
e_stuck.lastteleport = 0
e_stuck.lastaeth = 0 
e_stuck.lastfixmeshpos = {x = 0, y = 0, z = 0}
e_stuck.lastfixmeshmap = nil
e_stuck.stuckevacpos = {}
e_stuck.blockOnly = false
function c_stuck:evaluate()
	
	if (NavigationManager.ShowCells == nil ) then
		-- old nav
		gStuckRemesh = nil
	else
		-- new nav
		if ffxiv_unstuck.remeshstate ~= 0 then
			ffxiv_unstuck.AttemptMeshFix()
			return
		end
	end
	if ml_task_hub:CurrentTask() then
		if ml_task_hub:CurrentTask():ParentTask() == "MISC_SHOPPING" then
			return false
		end
	end
	e_stuck.state = {}
	e_stuck.blockOnly = false
	e_stuck.task = ""
	
	if (Busy() or not ffxiv_unstuck.IsPathing() or Player:IsJumping() or HasBuffs(Player, "13") or ffxiv_unstuck.disabled or tonumber(gPulseTime) < 150) then
		--d("[Unstuck]: We're locked, loading, or nav status is not operational.")
		return false
	end
	
	local currentPos = Player.pos
	local lastPos = ffxiv_unstuck.lastPos
	local coarse = ffxiv_unstuck.coarse
	if (not table.valid(lastPos) or not table.valid(coarse.lastPos)) then
		--d("[Unstuck]: Need to set up the original last pos.")
		ffxiv_unstuck.lastPos = { x = currentPos.x, y = currentPos.y, z = currentPos.z }
		coarse.lastPos = { x = currentPos.x, y = currentPos.y, z = currentPos.z }
		return false
	end	

	ffxiv_unstuck.diffTotal = math.distance3d(currentPos,lastPos)	
	ffxiv_unstuck.UpdateState("STUCK",ffxiv_unstuck.IsStuck())
	
	if (TimeSince(coarse.lastMeasure) > 4000 or ffxiv_unstuck.State.STALLED.ticks == 0) then
		coarse.lastPos = { x = currentPos.x, y = currentPos.y, z = currentPos.z }
		coarse.lastMeasure = Now()
	end
	
	coarse.lastDist = math.distance3d(currentPos,coarse.lastPos)
	ffxiv_unstuck.UpdateState("STALLED",ffxiv_unstuck.IsStalled())
	ffxiv_unstuck.UpdateState("OFFMESH",ffxiv_unstuck.IsOffMesh())
	
	for name,state in pairs(ffxiv_unstuck.State) do
		if state.ticks ~= 0 then
			if (state.ticks >= state.maxticks) then
				e_stuck.state = state
				d("Reached a stuck state for ["..tostring(state.name).."]")
				return true
			elseif state.ticks >= state.minticks then
				e_stuck.state = state
				d("name = "..tostring(state.name))
				if (name ~= "OFFMESH") then
					if (not IsFlying() and not IsDiving() and TimeSince(ffxiv_unstuck.lastCorrection) >= 1000) then
						if ffxiv_unstuck.State[state.name].stats >= 3 then	
							local distToRemesh = IsNull(Distance2D(Player.pos.x,Player.pos.z,e_stuck.lastfixmeshpos.x,e_stuck.lastfixmeshpos.z),0)
							local returnHome = ActionList:Get(1,6)
							local aeth = GetAetheryteByMapID(Player.localmapid, Player.pos)
							local evacPoint = GetNearestEvacPoint()
							if gStuckRemesh and (distToRemesh >= 30 and (not e_stuck.lastfixmeshmap or (e_stuck.lastfixmeshmap and e_stuck.lastfixmeshmap == Player.localmapid))) then
								e_stuck.task = "Remesh"
								d("Attempt Remesh")
								if (Player:IsMoving()) then
									Player:PauseMovement()
									ml_global_information.Await(1000, function () return not Player:IsMoving() end)
								end
								e_stuck.lastfixmeshpos = { x = Player.pos.x, y = Player.pos.y, z = Player.pos.z }
								e_stuck.lastfixmeshmap = Player.localmapid
								ffxiv_unstuck.remeshstate = 1

								return true
							elseif gStuckReturn and (returnHome and returnHome:IsReady()) then
								e_stuck.task = "Return"
								return true
							elseif gStuckTeleport and (ActionIsReady(7,5) and aeth) and (e_stuck.lastteleport < Now()) then	
							
								e_stuck.task = "Teleport"
								e_stuck.lastaeth = aeth
								return true
							else				
								if gStuckDisable then
									e_stuck.task = "Disable"
									return true
								end
							end
						end
						d("[Unstuck]: Performing corrective jump.")
						Player:Jump()
						ml_global_information.Await(3000, function () return not Player:IsJumping() end)
						ffxiv_unstuck.lastCorrection = Now()
						ffxiv_unstuck.State[state.name].stats = ffxiv_unstuck.State[state.name].stats + 1
						e_stuck.blockOnly = true
						e_stuck.task = "Jump"						
						return true
					end
				else
					local attemptReturnPos = FindClosestMesh(Player.pos,10,false)
				
					if table.valid(attemptReturnPos) then
						local ppos = Player.pos
						if (Distance3D(ppos.x,ppos.y,ppos.z,attemptReturnPos.x,attemptReturnPos.y,attemptReturnPos.z) < 10) then
							Player:SetFacing(attemptReturnPos.pos.x,attemptReturnPos.pos.y,attemptReturnPos.pos.z)
							local hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y+2,ppos.z,ppos.x,ppos.y-10,ppos.z) 
							if (not hit or (hit and (Distance2D(ppos.x,ppos.z,hitx,hitz) > 10))) then
								Player:Move(FFXIV.MOVEMENT.FORWARD)	
								ml_global_information.Await(3000, function () return NavigationManager:IsOnMesh(ppos) end)
							end
						else
							if (Player:IsMoving()) then
								Player:Stop()
							end
							e_stuck.blockOnly = true
							e_stuck.task = "Disable"
							return true
						end
					else
						if (Player:IsMoving()) then
							Player:Stop()
						end
						e_stuck.blockOnly = true
						e_stuck.task = "Disable"
						return true
					end
				end
			end
		end
	end
	
	ffxiv_unstuck.lastPos = { x = currentPos.x, y = currentPos.y, z = currentPos.z }
end
function e_stuck:execute()
	local state = e_stuck.state
	local task = e_stuck.task
		
	if (e_stuck.blockOnly and ffxiv_unstuck.State[state.name].stats < 3) then
		return
	end
	
	ml_navigation:ResetOMCHandler()
	ml_navigation.lastconnectionid = 0
	ffxiv_unstuck.State.STUCK.ticks = 0
	ffxiv_unstuck.State.STALLED.ticks = 0
	ffxiv_unstuck.State.OFFMESH.ticks = 0
	
	if (not Player.incombat and not MIsCasting() and (ffxiv_unstuck.State[state.name].stats > 2) and not InInstance()) then
		Player:Stop()
		if task == "Disable" then
			
			ml_global_information.ToggleRun()
			ffxiv_unstuck.GUI.open = true
			
			NavigationManager.ShowFloorMesh = true 
			NavigationManager.RenderDistance = 1
			NavigationManager.RenderAlpha = 115
			Settings.minionlib.ShowNavPath = true
			ffxiv_unstuck.State[state.name].stats = 0
			return true
		elseif task == "Teleport" then 
			local aeth = e_stuck.lastaeth
			if (Player:Teleport(aeth.id)) then	
				ffxiv_unstuck.State[state.name].stats = 0
				local newTask = ffxiv_task_teleport.Create()
				newTask.aetheryte = aeth.id
				newTask.mapID = aeth.territory
				ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
				e_stuck.lastteleport = Now() + 600000
				
				newTask.task_complete_eval = function ()
					return MIsLoading()
				end			
			end
		elseif task == "Return" then
		
			ml_global_information.Await(5000, 
				function () return (not Player:IsMoving()) end, 
				function ()
					local returnHome = ActionList:Get(1,6)
					if (returnHome and returnHome:IsReady()) then
						if (returnHome:Cast(Player.id)) then
							ffxiv_unstuck.State[state.name].stats = 0
							ml_global_information.Await(10000, function () return (MIsLoading() and not MIsLocked()) end)
							ffxiv_unstuck.State[state.name].stats = 0
							return true
						end	
					end
				end
			)
		elseif task == "Remesh" then
			ffxiv_unstuck.State[state.name].stats = 0
			e_stuck.lastfixmeshpos = { x = Player.pos.x, y = Player.pos.y, z = Player.pos.z }
			e_stuck.lastfixmeshmap = Player.localmapid
			ffxiv_unstuck.remeshstate = 1
		end
	else
		Player:Stop()
		ml_global_information.Await(5000, function () return not Player:IsMoving() end)
		ffxiv_unstuck.State[state.name].stats = ffxiv_unstuck.State[state.name].stats + 1
	end
end
ffxiv_unstuck.remeshstate = 0
ffxiv_unstuck.AutoFixMeshOn = 0
ffxiv_unstuck.needsSave =  false
function ffxiv_unstuck.AttemptMeshFix()
	Player:Stop()
	
	if NavigationManager.ProcessingFloorMesh then
		ffxiv_unstuck.needsSave =  true
		return 
	end
	if ffxiv_unstuck.remeshstate == 1 then
		ml_mesh_mgr.data.flooreditormode = 10
		NavigationManager.FloorEditorMode = 10
		NavigationManager.RecordDistance = 0
		NavigationManager.PreciseRecordDistance = 10
		NavigationManager.UseMouseEditor = false
		NavigationManager.AutoSaveMesh = false
		ml_mesh_mgr.data.running = true
		d("[AttemptMeshFix] = Deleteing area")
		ml_global_information.Await(10000)
		ffxiv_unstuck.remeshstate = 2
		return
	elseif ffxiv_unstuck.remeshstate == 2 then
		Player:Move(FFXIV.MOVEMENT.BACKWARD)
		--ml_global_information.Await(1000, function () return Player:IsMoving() end)
		ml_mesh_mgr.data.flooreditormode = 3
		NavigationManager.FloorEditorMode = 3
		NavigationManager.RecordDistance = 1
		NavigationManager.UseMouseEditor = false
		NavigationManager.AutoSaveMesh = true
		ml_mesh_mgr.data.running = true
		d("[AttemptMeshFix] = Meshing area")
		ml_global_information.Await(1000)
		ffxiv_unstuck.remeshstate =  3
		return
	elseif ffxiv_unstuck.remeshstate == 3 then
		NavigationManager:SaveNavMesh(ml_mesh_mgr.data.meshfilefolderpath)
		ffxiv_unstuck.AutoFixMeshOn = Now()
		ffxiv_unstuck.remeshstate = 0
		d("[AttemptMeshFix] = Save Changes")
	end
end
function ffxiv_unstuck.IsPathing()
	if (ml_navigation:HasPath() and ml_navigation.CanRun() and ml_navigation.canPath and not ffnav.IsProcessing()) then	
		--d("[Unstuck]: Navigation is pathing.")
		return true
	end
	return false
end

function ffxiv_unstuck.IsStalled()
	local requiredDist = 10
	local hasSlow = HasBuffs(Player, "14,47,67,181,240,436,484,502,567,614,615,623,674,709,967,1939")
	if (hasSlow) then requiredDist = (requiredDist * .3) end
	--if (Player.ismounted) then requiredDist = (requiredDist * 1.2) end
	
	if (ffxiv_unstuck.coarse.lastDist <= requiredDist and ffxiv_unstuck.IsPathing() and not MIsLocked()) then
		--d("[Unstuck_Stalled]: Did not cover the minimum distance necessary, only covered ["..tostring(ffxiv_unstuck.coarse.lastDist).."], but needed ["..tostring(requiredDist).."].")
		return true
	else
		--d("[Unstuck_Stalled]: Covered the minimum distance necessary.")
		return false
	end
end

function ffxiv_unstuck.IsStuck()
	local requiredDist = .7
	local hasSlow = HasBuffs(Player, "14,47,67,181,240,436,484,502,567,614,615,623,674,709,967,1939")
	
	if (hasSlow) then requiredDist = (requiredDist * .5) end
	--if (Player.ismounted) then requiredDist = (requiredDist * 1.2) end
	
	if (ffxiv_unstuck.diffTotal <= requiredDist and ffxiv_unstuck.IsPathing() and not MIsLocked()) then
		--d("[Unstuck_Stuck]: Did not cover the minimum distance necessary, only covered ["..tostring(ffxiv_unstuck.diffTotal).."].")
		return true
	end
	return false
end

function ffxiv_unstuck.IsOffMesh()
	if (IsFlying() or IsDiving() or MIsLocked() or Player.incombat) then
		return false
	end
	if (not FFXIV_Common_NavMesh or FFXIV_Common_NavMesh == "" or FFXIV_Common_NavMesh == GetString("none") or MIsLoading()) then
		return false
	end
	return not Player.onmesh and not MIsCasting()
end

function ffxiv_unstuck.UpdateState(state,failed)
	local failed = IsNull(failed,false)
	
	if failed then
		ffxiv_unstuck.State[state].ticks = ffxiv_unstuck.State[state].ticks + 1
	else
		if (ffxiv_unstuck.State[state].ticks ~= 0) then
			ffxiv_unstuck.State[state].ticks = 0
		end
		if (ffxiv_unstuck.State[state].stats > 0) then
			if (ffxiv_unstuck.State[state].safeticks >= ffxiv_unstuck.State[state].minsafeticks) then
				ffxiv_unstuck.State[state].stats = 0
				ffxiv_unstuck.State[state].safeticks = 0
			else
				ffxiv_unstuck.State[state].safeticks = ffxiv_unstuck.State[state].safeticks + 1
			end
		end
	end
end

ffxiv_unstuck.lastObstacleCheck = 0
function ffxiv_unstuck.GetObstacleAvoidance()
	
	local ppos = Player.pos
	local nextNode = ml_navigation.path[ml_global_information.pathindex]
	
	if (table.isa(nextNode)) then
	
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
	ffxiv_unstuck.lastObstacleCheck = Now()
	
	return 0, 0
end

function ffxiv_unstuck.OnUpdate( event, tickcount )
	local gamestate = MGetGameState()
	
	if (gamestate == FFXIV.GAMESTATE.INGAME and TimeSince(ffxiv_unstuck.lastTick) >= 150) then
		ffxiv_unstuck.lastTick = tickcount
		
		if (Busy() or not ffxiv_unstuck.IsPathing() or Player:IsJumping() or HasBuffs(Player, "13") or ffxiv_unstuck.disabled or tonumber(gPulseTime) < 150) then
			--d("[Unstuck]: We're locked, loading, or nav status is not operational.")
			return false
		end
		
		local currentPos = Player.pos
		local lastPos = ffxiv_unstuck.lastPos
		local coarse = ffxiv_unstuck.coarse
		if (not table.valid(lastPos) or not table.valid(coarse.lastPos)) then
			--d("[Unstuck]: Need to set up the original last pos.")
			ffxiv_unstuck.lastPos = { x = currentPos.x, y = currentPos.y, z = currentPos.z }
			coarse.lastPos = { x = currentPos.x, y = currentPos.y, z = currentPos.z }
			return false
		end	
	
		ffxiv_unstuck.diffTotal = math.distance3d(currentPos,lastPos)	
		ffxiv_unstuck.UpdateState("STUCK",ffxiv_unstuck.IsStuck())
		
		if (TimeSince(coarse.lastMeasure) > 4000 or ffxiv_unstuck.State.STALLED.ticks == 0) then
			coarse.lastPos = { x = currentPos.x, y = currentPos.y, z = currentPos.z }
			coarse.lastMeasure = Now()
		end
		
		coarse.lastDist = math.distance3d(currentPos,coarse.lastPos)
		ffxiv_unstuck.UpdateState("STALLED",ffxiv_unstuck.IsStalled())
		ffxiv_unstuck.UpdateState("OFFMESH",ffxiv_unstuck.IsOffMesh())
	end
end

ffxiv_unstuck_teleport = inheritsFrom(ml_task)
function ffxiv_unstuck_teleport.Create()
    local newinst = inheritsFrom(ffxiv_unstuck_teleport)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    newinst.name = "LT_TELEPORT"
	newinst.aetheryte = 0
    newinst.mapID = 0
	newinst.mesh = nil
    newinst.started = Now()
	newinst.lastActivity = Now()
	newinst.conversationIndex = 0
    
    return newinst
end


function ffxiv_unstuck_teleport:task_complete_eval()
	if (MIsCasting(true)) then
		return true
	end
	if (MIsLoading()) then
		return true
	end		
	
	return true
end
function ffxiv_unstuck_teleport:task_complete_execute()  
	self.completed = true
end

function ffxiv_unstuck_teleport:task_fail_eval()
	if (Player.incombat or not Player.alive) then
		return true
	end
	
	if (Busy()) then
		self.lastActivity = Now()
		return false
	end
	
	if (TimeSince(self.started) > 25000) then
		return true
	elseif (TimeSince(self.lastActivity) > 5000) then
		return true
	end
end
function ffxiv_unstuck_teleport:task_fail_execute()  
	self.valid = false
end

function ml_global_information.DrawStuck()
	local gamestate = MGetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		if (ffxiv_unstuck.GUI.open) then	
			
			GUI:SetNextWindowSize(300,310,GUI.SetCond_Always) --set the next window size, only on first ever	
			GUI:SetNextWindowCollapsed(false,GUI.SetCond_Always)
			
			local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
			GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
			
			local flags = (GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
			ffxiv_unstuck.GUI.visable, ffxiv_unstuck.GUI.open = GUI:Begin(ffxiv_unstuck.GUI.name, ffxiv_unstuck.GUI.open, flags)
			if (ffxiv_unstuck.GUI.visable) then 		
			
				local fontSize = GUI:GetWindowFontSize()
				local windowPaddingY = ml_gui.style.current.windowpadding.y
				local framePaddingY = ml_gui.style.current.framepadding.y
				local itemSpacingY = ml_gui.style.current.itemspacing.y
					
GUI:Text("Provide a full screen picture of the mesh \
This tab and all the info to.. \
'Mesh Stucks' forum or discord channel")
GUI:Separator()

GUI:Spacing();
GUI:Spacing();		

local bugReport = ""

--local currentMesh = IsNull(ml_mesh_mgr.data.meshfiles[ml_mesh_mgr.data.meshfileidx],"")
--if (NavigationManager.ShowCells == nil ) then
	local currentMesh = IsNull(ml_mesh_mgr.currentfilename,"")
--end
bugReport = "Type: "..tostring(e_stuck.state.name).."\n"
bugReport = bugReport.."\n"

bugReport = bugReport.."Navmesh: "..tostring(currentMesh).."\n"
bugReport = bugReport..GetString("MapID: ")..tostring(Player.localmapid).."\n"
GUI:Spacing();
GUI:Spacing();		

bugReport = bugReport.."\n"
bugReport = bugReport.."\n"

bugReport = bugReport.."Stuck position: \n"
bugReport = bugReport.."X: "..tostring(ffxiv_unstuck.lastPos.x).."\n"
bugReport = bugReport.."Y: "..tostring(ffxiv_unstuck.lastPos.y).."\n"
bugReport = bugReport.."Z: "..tostring(ffxiv_unstuck.lastPos.z).."\n"

 GUI:InputTextMultiline("##Stuck Report",bugReport, 285, 170, GUI.InputTextFlags_ReadOnly)	
GUI:Separator()
					
			end
			if (GUI:Button("Close")) then
				ffxiv_unstuck.GUI.open = false
				NavigationManager.ShowFloorMesh = false 
				Settings.minionlib.ShowNavPath = false
				NavigationManager.ShowCells = false
			end

			GUI:End()
			GUI:PopStyleColor()
		end
	end
end
--RegisterEventHandler("Gameloop.Update",ffxiv_unstuck.Draw)

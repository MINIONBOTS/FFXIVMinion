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
c_stuck.state = {}
c_stuck.blockOnly = false
function c_stuck:evaluate()
	c_stuck.state = {}
	c_stuck.blockOnly = false
	
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
				if (name == "STUCK") then
					if (not IsFlying() and not IsDiving() and TimeSince(ffxiv_unstuck.lastCorrection) >= 1000) then
						d("[Unstuck]: Performing corrective jump.")
						Player:Jump()
						ml_global_information.Await(3000, function () return not Player:IsJumping() end)
						ffxiv_unstuck.lastCorrection = Now()
						ffxiv_unstuck.State[state.name].stats = ffxiv_unstuck.State[state.name].stats + 1
					end
					c_stuck.blockOnly = true
					return true
				elseif (name == "OFFMESH") then
					if (Player:IsMoving()) then
						Player:Stop()
					end
					c_stuck.blockOnly = true
					return true
				end
			end
		end
	end
	
	ffxiv_unstuck.lastPos = { x = currentPos.x, y = currentPos.y, z = currentPos.z }
end
function e_stuck:execute()
	local state = e_stuck.state
	
	if (c_stuck.blockOnly and ffxiv_unstuck.State[state.name].stats < 3) then
		return
	end
	
	ffxiv_unstuck.State.STUCK.ticks = 0
	ffxiv_unstuck.State.OFFMESH.ticks = 0
	ffxiv_unstuck.State.STALLED.ticks = 0
	
	if (not Player.incombat and not MIsCasting() and ffxiv_unstuck.State[state.name].stats > 2 and not InInstance()) then
		Player:Stop()
		
		ml_global_information.Await(5000, 
			function () return (not Player:IsMoving()) end, 
			function ()
				local returnHome = ActionList:Get(6)
				if (returnHome and returnHome.isready) then
					if (returnHome:Cast(Player.id)) then
						ml_global_information.Await(10000, function () return (MIsLoading() and not MIsLocked()) end)
						return true
					end	
				end
			end
		)
		ffxiv_unstuck.State[state.name].stats = 0
	else
		Player:Stop()
		ml_global_information.Await(5000, function () return not Player:IsMoving() end)
		ffxiv_unstuck.State[state.name].stats = ffxiv_unstuck.State[state.name].stats + 1
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
	local hasSlow = HasBuffs(Player, "14,47,67,181,240,436,484,502,567,614,615,623,674,709,967")
	if (hasSlow) then requiredDist = (requiredDist * .5) end
	--if (Player.ismounted) then requiredDist = (requiredDist * 1.2) end
	
	if (ffxiv_unstuck.coarse.lastDist <= requiredDist and ffxiv_unstuck.IsPathing() and not MIsLocked()) then
		--d("[Unstuck_Stalled]: Did not cover the minimum distance necessary, only covered ["..tostring(ffxiv_unstuck.coarse.lastDist).."].")
		return true
	else
		--d("[Unstuck_Stalled]: Covered the minimum distance necessary.")
		return false
	end
end

function ffxiv_unstuck.IsStuck()
	local requiredDist = .7
	local hasSlow = HasBuffs(Player, "14,47,67,181,240,436,484,502,567,614,615,623,674,709,967")
	
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

--RegisterEventHandler("Gameloop.Update",ffxiv_unstuck.OnUpdate)

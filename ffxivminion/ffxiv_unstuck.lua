ffxiv_unstuck = {}
ffxiv_unstuck.lastpos = nil
ffxiv_unstuck.diffTotal = 0
ffxiv_unstuck.evaltime = 0
ffxiv_unstuck.count = 0
ffxiv_unstuck.lastCorrection = 0
ffxiv_unstuck.firstAttempt = true

ffxiv_unstuck.coarse = {
	lastMeasure = 0,
	lastPos = {},
	lastDist = 0,
}

ffxiv_unstuck.State = {
	STUCK 	= { id = 0, name = "STUCK" 	, stats = 0, ticks = 0, minticks = 5, maxticks = 10 },
	OFFMESH = { id = 1, name = "OFFMESH" , stats = 0, ticks = 0, minticks = 5, maxticks = 10 },
	STALLED = { id = 2, name = "STALLED" , stats = 0, ticks = 0, minticks = 50, maxticks = 50 },
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
	
	if (not Player.alive or (MIsLocked() and not IsFlying()) or MIsLoading() or Player:GetNavStatus() ~= 1 or HasBuffs(Player, "13")) then
		--d("[Unstuck]: We're locked, loading, or nav status is not operational.")
		return false
	end
	
	local currentPos = Player.pos
	local lastPos = ffxiv_unstuck.lastpos
	if  (not ValidTable(lastPos)) then
		--d("[Unstuck]: Need to set up the original last pos.")
		ffxiv_unstuck.lastpos = { x = currentPos.x, y = currentPos.y, z = currentPos.z }
		return false
	end	
	
	ffxiv_unstuck.diffTotal = PDistance3D(currentPos.x,currentPos.y,currentPos.z,lastPos.x,lastPos.y,lastPos.z)	
	if ffxiv_unstuck.IsStuck() then
		ml_debug("Adding stuck tick:"..tostring(ffxiv_unstuck.State.STUCK.ticks + 1).." total.",nil,3)
		ffxiv_unstuck.State.STUCK.ticks = ffxiv_unstuck.State.STUCK.ticks + 1
	else
		if (ffxiv_unstuck.State.STUCK.ticks ~= 0) then
			ml_debug("Removing stuck ticks.",nil,3)
			ffxiv_unstuck.State.STUCK.ticks = 0
		end
	end
	
	local coarse = ffxiv_unstuck.coarse
	if (not ValidTable(coarse.lastPos) or TimeSince(coarse.lastMeasure) > 4000 or ffxiv_unstuck.State.STALLED.ticks == 0) then
		coarse.lastPos = { x = currentPos.x, y = currentPos.y, z = currentPos.z }
		coarse.lastMeasure = Now()
	end
	
	coarse.lastDist = PDistance3D(currentPos.x,currentPos.y,currentPos.z,coarse.lastPos.x,coarse.lastPos.y,coarse.lastPos.z)	
	if ffxiv_unstuck.IsStalled() then
		ml_debug("Adding stalled tick:"..tostring(ffxiv_unstuck.State.STALLED.ticks + 1).." total.",nil,3)
		ffxiv_unstuck.State.STALLED.ticks = ffxiv_unstuck.State.STALLED.ticks + 1
	else
		if (ffxiv_unstuck.State.STALLED.ticks ~= 0) then
			ml_debug("Removing stalled ticks.",nil,3)
			ffxiv_unstuck.State.STALLED.ticks = 0
		end
	end
	
	if ffxiv_unstuck.IsOffMesh() then
		ffxiv_unstuck.State.OFFMESH.ticks = ffxiv_unstuck.State.OFFMESH.ticks + 1
	else
		if (ffxiv_unstuck.State.OFFMESH.ticks ~= 0) then
			ffxiv_unstuck.State.OFFMESH.ticks = 0
		end
	end
	
	for name,state in pairs(ffxiv_unstuck.State) do
		if state.ticks ~= 0 then
			if (state.ticks >= state.maxticks) then
				e_stuck.state = state
				d("Reached a stuck state for ["..tostring(state.name).."]")
				return true
			elseif state.ticks >= state.minticks then
				if (name == "STUCK") then
					if (TimeSince(ffxiv_unstuck.lastCorrection) >= 1000) then
						d("[Unstuck]: Performing corrective jump.")
						Player:Jump()
						ffxiv_unstuck.lastCorrection = Now()
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
	
	if (not Player:IsJumping()) then
		ffxiv_unstuck.lastpos = { x = currentPos.x, y = currentPos.y, z = currentPos.z }
	end
end
function e_stuck:execute()
	if (c_stuck.blockOnly) then
		return
	end
	
	local state = e_stuck.state
	ffxiv_unstuck.State[state.name].stats = ffxiv_unstuck.State[state.name].stats + 1
	
	ffxiv_unstuck.State.STUCK.ticks = 0
	ffxiv_unstuck.State.OFFMESH.ticks = 0
	ffxiv_unstuck.State.STALLED.ticks = 0
	
	if (not Player.incombat and not MIsCasting() and not ffxiv_unstuck.firstAttempt) then
		local instructions = {
			{"Stop", {}},
			{"Return", {}},
		}
		ml_mesh_mgr.ParseInstructions(instructions)
		ffxiv_unstuck.firstAttempt = true
	else
		Player:Stop()
		ml_global_information.Await(5000, function () return not Player:IsMoving() end)
		ffxiv_unstuck.firstAttempt = false
	end
end

function ffxiv_unstuck.IsStalled()
	local requiredDist = 10
	local hasSlow = HasBuffs(Player, "14,47,67,181,240,436,484,502,567,614,615,623,674,709,967")
	if (hasSlow) then requiredDist = (requiredDist * .5) end
	--if (Player.ismounted) then requiredDist = (requiredDist * 1.2) end
	
	if (ffxiv_unstuck.coarse.lastDist <= requiredDist and Player:IsMoving()) then
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
	
	if (ffxiv_unstuck.diffTotal <= requiredDist and Player:IsMoving() and not MIsLocked() and not IsFlying()) then
		--d("[Unstuck_Stuck]: Did not cover the minimum distance necessary, only covered ["..tostring(ffxiv_unstuck.diffTotal).."].")
		return true
	else
		--d("[Unstuck_Stuck]: Covered the minimum distance necessary.")
		return false
	end
end

function ffxiv_unstuck.IsOffMesh()
	if (IsFlying() or MIsLocked()) then
		return false
	end
	
	if (not gmeshname or gmeshname == "" or gmeshname == GetString("none") or MIsLoading()) then
		return false
	end
	return not Player.onmesh and not MIsCasting()
end

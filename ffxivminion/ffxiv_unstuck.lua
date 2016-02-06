ffxiv_unstuck = {}
ffxiv_unstuck.lastpos = nil
ffxiv_unstuck.diffTotal = 0
ffxiv_unstuck.evaltime = 0
ffxiv_unstuck.count = 0
ffxiv_unstuck.lastCorrection = 0

ffxiv_unstuck.State = {
	STUCK 	= { id = 0, name = "STUCK" 		, stats = 0, ticks = 0, minticks = 3, maxticks = 10 },
	OFFMESH = { id = 1, name = "OFFMESH" 	, stats = 0, ticks = 0, minticks = 3, maxticks = 10 },
}

c_stuck = inheritsFrom( ml_cause )
e_stuck = inheritsFrom( ml_effect )
c_stuck.state = {}
c_stuck.blockOnly = false
function c_stuck:evaluate()

	c_stuck.state = {}
	c_stuck.blockOnly = false
	
	if (MIsLocked() or IsFlying() or MIsGCDLocked() or MIsLoading() or Player:GetNavStatus() ~= 1 or HasBuffs(Player, "13")) then
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
		d("Adding stuck tick:"..tostring(ffxiv_unstuck.State.STUCK.ticks + 1).." total.")
		ffxiv_unstuck.State.STUCK.ticks = ffxiv_unstuck.State.STUCK.ticks + 1
	else
		if (ffxiv_unstuck.State.STUCK.ticks ~= 0) then
			d("Removing stuck ticks.")
			ffxiv_unstuck.State.STUCK.ticks = 0
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
	
	if (not Player.incombat and not MIsCasting()) then
		local instructions = {
			{"Return", {}},
		}
		ml_mesh_mgr.ParseInstructions(instructions)
	else
		local instructions = {
			{"Stop", {}},
		}
	end
end

function ffxiv_unstuck.IsStuck()
	local requiredDist = .7
	local hasSlow = HasBuffs(Player, "14,47,67,181,240,436,484,502,567,614,615,623,674,709,967")
	--local isMounted = Player.ismounted
	
	if (hasSlow) then requiredDist = (requiredDist * .5) end
	--if (isMounted) then requiredDist = (requiredDist * 1.5) end
	
	if (ffxiv_unstuck.diffTotal <= requiredDist) then
		--d("[Unstuck]: Did not cover the minimum distance necessary.")
		return true
	else
		--d("[Unstuck]: Covered the minimum distance necessary.")
		return false
	end
	--return 	(ffxiv_unstuck.diffX >= 0 and ffxiv_unstuck.diffX <= requiredDist) and
			--(ffxiv_unstuck.diffY >= 0 and ffxiv_unstuck.diffY <= requiredDist) and 
			--(ffxiv_unstuck.diffZ >= 0 and ffxiv_unstuck.diffZ <= requiredDist)
end

function ffxiv_unstuck.IsOffMesh()
	if (not gmeshname or gmeshname == "" or gmeshname == "none" or MIsLoading()) then
		return false
	end
	return not Player.onmesh and not MIsCasting()
end

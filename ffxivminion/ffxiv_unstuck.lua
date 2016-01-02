ffxiv_unstuck = {}
ffxiv_unstuck.lastpos = nil
ffxiv_unstuck.diffX = 0
ffxiv_unstuck.diffY = 0
ffxiv_unstuck.diffZ = 0
ffxiv_unstuck.evaltime = 0
ffxiv_unstuck.count = 0
ffxiv_unstuck.lastCorrection = 0


ffxiv_unstuck.State = {
	STUCK 	= { id = 0, name = "STUCK" 		, stats = 0, ticks = 0, minticks = 25, maxticks = 50 },
	OFFMESH = { id = 1, name = "OFFMESH" 	, stats = 0, ticks = 0, minticks = 30, maxticks = 30 },
}

c_stuck = inheritsFrom( ml_cause )
e_stuck = inheritsFrom( ml_effect )
c_stuck.state = {}
c_stuck.blockOnly = false
function c_stuck:evaluate()

	c_stuck.state = {}
	c_stuck.blockOnly = false
	
	if (gDoUnstuck == "0" or IsFlying() or MIsLoading()) then
		return false
	end
	
	if 	(ffxiv_unstuck.lastpos == nil) or
		(ffxiv_unstuck.lastpos and type(ffxiv_unstuck.lastpos) ~= "table")
	then
		ffxiv_unstuck.lastpos = ml_global_information.Player_Position
	end
	
	local currentPos = ml_global_information.Player_Position
	ffxiv_unstuck.diffX = math.abs(IsNull(currentPos.x,0) - IsNull(ffxiv_unstuck.lastpos.x,0))
	--ml_debug("Current diffX:"..tostring(ffxiv_unstuck.diffX))
	ffxiv_unstuck.diffY = math.abs(IsNull(currentPos.y,0) - IsNull(ffxiv_unstuck.lastpos.y,0))
	--ml_debug("Current diffY:"..tostring(ffxiv_unstuck.diffY))
	ffxiv_unstuck.diffZ = math.abs(IsNull(currentPos.z,0) - IsNull(ffxiv_unstuck.lastpos.z,0))
	--ml_debug("Current diffZ:"..tostring(ffxiv_unstuck.diffZ))
	
	if ffxiv_unstuck.IsStuck() then
		ml_debug("Adding stuck tick:"..tostring(ffxiv_unstuck.State.STUCK.ticks + 1).." total.")
		ffxiv_unstuck.State.STUCK.ticks = ffxiv_unstuck.State.STUCK.ticks + 1
	else
		if (ffxiv_unstuck.State.STUCK.ticks ~= 0) then
			ml_debug("Removing stuck ticks.")
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
			if state.ticks >= state.maxticks then
				e_stuck.state = state
				return true
			elseif state.ticks >= state.minticks then
				if (TimeSince(ffxiv_unstuck.lastCorrection) >= 1000) then
					Player:Jump()
					ffxiv_unstuck.lastCorrection = Now()
				end
				c_stuck.blockOnly = true
				return true
			end
		end
	end
	
	ffxiv_unstuck.lastpos = ml_global_information.Player_Position
end
function e_stuck:execute()
	if (c_stuck.blockOnly) then
		return
	end
	
	local state = e_stuck.state
	ffxiv_unstuck.State[state.name].stats = ffxiv_unstuck.State[state.name].stats + 1
	
	local message = {}
	local requireStop = false
	if (ffxiv_unstuck.State[state.name].stats >= 3) then
		message[1] = state.name..": "..tostring(state.maxticks).." ticks reached."
		message[2] = "Assuming player is stuck."
		message[3] = "Player has been stuck "..tostring(ffxiv_unstuck.State[state.name].stats).." this session."
		message[4] = "Bot will be stopped, please report mesh stuck issues with the following details:"
		message[5] = "MapID :"..tostring(ml_global_information.Player_Map)
		message[6] = "X = "..tostring(ml_global_information.Player_Position.x)..",Y = "..tostring(ml_global_information.Player_Position.y)..",Z = "..tostring(ml_global_information.Player_Position.z)
		requireStop = true
	else
		message[1] = state.name..tostring(state.maxticks).." ticks reached."
		message[2] = "Assuming player is stuck."
		message[3] = "Player has been stuck "..tostring(ffxiv_unstuck.State[state.name].stats).." this session."
		message[4] = "Please report mesh stuck issues with the following details:"
		message[5] = "MapID :"..tostring(ml_global_information.Player_Map)
		message[6] = "X = "..tostring(ml_global_information.Player_Position.x)..",Y = "..tostring(ml_global_information.Player_Position.y)..",Z = "..tostring(ml_global_information.Player_Position.z)
	end
	
	if (Player:IsMoving()) then
		Player:Stop()
		return
	end
	
	local teleported = false
	local teleport = ActionList:Get(7,5)
	if (teleport and teleport.isready and Player.castinginfo.channelingid ~= 5) then
		local aetheryte = GetAetheryteByMapID(ml_global_information.Player_Map, ml_global_information.Player_Position)
		if (aetheryte) then
			if (Player:Teleport(aetheryte.id)) then
				teleported = true
			end
		end
	end	
	
	if (teleported) then
		ffxiv_dialog_manager.IssueNotice("Player_Stuck", message)
		ffxiv_unstuck.State.STUCK.ticks = 0
		ffxiv_unstuck.State.OFFMESH.ticks = 0
	end
	
	if (not teleported or requireStop) then
		ffxiv_dialog_manager.IssueStopNotice("Player_Stuck", message)
	end
end

function ffxiv_unstuck.IsStuck()
	local requiredDist = .6
	local hasStealth = HasBuff(Player.id, 47)
	local isMounted = Player.ismounted
	
	if (hasStealth) then requiredDist = (requiredDist * .5) end
	if (isMounted) then requiredDist = (requiredDist * 1.25) end
	
	return 	(ffxiv_unstuck.diffX >= 0 and ffxiv_unstuck.diffX <= requiredDist) and
			--(ffxiv_unstuck.diffY >= 0 and ffxiv_unstuck.diffY <= .6) and 
			(ffxiv_unstuck.diffZ >= 0 and ffxiv_unstuck.diffZ <= requiredDist) and
			not MIsCasting(true) and
			Player:IsMoving() and
			not MIsLocked() and
			not ml_global_information.Player_InCombat and
			not MIsLoading()
end

function ffxiv_unstuck.IsOffMesh()
	if (not gmeshname or gmeshname == "" or gmeshname == "none" or MIsLoading()) then
		return false
	end
	return not Player.onmesh and not MIsCasting()
end

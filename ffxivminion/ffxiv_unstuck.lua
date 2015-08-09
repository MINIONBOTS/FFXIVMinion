ffxiv_unstuck = {}
ffxiv_unstuck.lastpos = nil
ffxiv_unstuck.diffX = 0
ffxiv_unstuck.diffY = 0
ffxiv_unstuck.diffZ = 0
ffxiv_unstuck.evaltime = 0
ffxiv_unstuck.count = 0
ffxiv_unstuck.laststuck = 0

ffxiv_unstuck.State = {
	STUCK 	= { id = 0, name = "STUCK" 		, stats = 0, ticks = 0, maxticks = 25 },
	OFFMESH = { id = 1, name = "OFFMESH" 	, stats = 0, ticks = 0, maxticks = 30 },
}

c_stuck = inheritsFrom( ml_cause )
e_stuck = inheritsFrom( ml_effect )
c_stuck.state = {}
function c_stuck:evaluate()
	c_stuck.state = {}
	
	if (gDoUnstuck == "0") then
		return false
	end
	
	if 	(ffxiv_unstuck.lastpos == nil) or
		(ffxiv_unstuck.lastpos and type(ffxiv_unstuck.lastpos) ~= "table")
	then
		ffxiv_unstuck.lastpos = Player.pos
	end
	
	local currentPos = Player.pos
	ffxiv_unstuck.diffX = math.abs(currentPos.x - ffxiv_unstuck.lastpos.x)
	ml_debug("Current diffX:"..tostring(ffxiv_unstuck.diffX))
	ffxiv_unstuck.diffY = math.abs(currentPos.y - ffxiv_unstuck.lastpos.y)
	ml_debug("Current diffY:"..tostring(ffxiv_unstuck.diffY))
	ffxiv_unstuck.diffZ = math.abs(currentPos.z - ffxiv_unstuck.lastpos.z)
	ml_debug("Current diffZ:"..tostring(ffxiv_unstuck.diffZ))
	
	if ffxiv_unstuck.IsStuck() then
		ml_debug("Adding stuck tick:"..tostring(ffxiv_unstuck.State.STUCK.ticks + 1).." total.")
		ffxiv_unstuck.State.STUCK.ticks = ffxiv_unstuck.State.STUCK.ticks + 1
	else
		ml_debug("Removing stuck ticks.")
		ffxiv_unstuck.State.STUCK.ticks = 0
	end
	
	if ffxiv_unstuck.IsOffMesh() then
		ffxiv_unstuck.State.OFFMESH.ticks = ffxiv_unstuck.State.OFFMESH.ticks + 1
	else
		ffxiv_unstuck.State.OFFMESH.ticks = 0
	end
	
	for i,state in pairs(ffxiv_unstuck.State) do
		if state.ticks ~= 0 then
			if state.ticks >= state.maxticks then
				e_stuck.state = state
				return true
			end
		end
	end
	
	ffxiv_unstuck.lastpos = Player.pos
end
function e_stuck:execute()
	local state = e_stuck.state
	ffxiv_unstuck.State[state.name].stats = ffxiv_unstuck.State[state.name].stats + 1
	
	local message = {}
	local requireStop = false
	if (ffxiv_unstuck.State[state.name].stats >= 3) then
		message[1] = state.name..": "..tostring(state.maxticks).." ticks reached."
		message[2] = "Assuming player is stuck."
		message[3] = "Player has been stuck "..tostring(ffxiv_unstuck.State[state.name].stats).." this session."
		message[4] = "Bot will be stopped, please report mesh stuck issues with the following details:"
		message[5] = "MapID :"..tostring(Player.localmapid)
		message[6] = "X = "..tostring(Player.pos.x)..",Y = "..tostring(Player.pos.y)..",Z = "..tostring(Player.pos.z)
		requireStop = true
	else
		message[1] = state.name..tostring(state.maxticks).." ticks reached."
		message[2] = "Assuming player is stuck."
		message[3] = "Player has been stuck "..tostring(ffxiv_unstuck.State[state.name].stats).." this session."
		message[4] = "Please report mesh stuck issues with the following details:"
		message[5] = "MapID :"..tostring(Player.localmapid)
		message[6] = "X = "..tostring(Player.pos.x)..",Y = "..tostring(Player.pos.y)..",Z = "..tostring(Player.pos.z)
	end
	
	local teleported = false
	local teleport = ActionList:Get(7,5)
	if (teleport and teleport.isready and Player.castinginfo.channelingid ~= 5) then
		local map,aeth = GetAetheryteByMapID(Player.localmapid, Player.pos)
		if (aeth) then
			local aetheryte = GetAetheryteByID(aeth)
			if (ValidTable(aetheryte)) then
				if (GilCount() >= aetheryte.price and aetheryte.isattuned) then
					if (Player:IsMoving()) then
						Player:Stop()
					end
					
					if (ActionIsReady(7,5)) then
						if (Player:Teleport(aeth)) then
							teleported = true
						end
					end
				end
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
			not ActionList:IsCasting() and
			Player:IsMoving() and 
			not IsPositionLocked() and
			not Player.incombat and
			not ml_mesh_mgr.loadingMesh
end

function ffxiv_unstuck.IsOffMesh()
	if (not gmeshname or gmeshname == "" or gmeshname == "none" or ml_mesh_mgr.loadingMesh) then
		return false
	end
	return not Player.onmesh and not ActionList:IsCasting()
end

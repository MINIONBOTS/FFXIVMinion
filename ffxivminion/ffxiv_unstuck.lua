ffxiv_unstuck = {}
ffxiv_unstuck.evaltime = 0
ffxiv_unstuck.count = 0
ffxiv_unstuck.laststuck = 0

ffxiv_unstuck.State = {
	STUCK 	= { id = 0, name = "STUCK" 		, stats = 0, ticks = 0, maxticks = 5 },
	OFFMESH = { id = 1, name = "OFFMESH" 	, stats = 0, ticks = 0, maxticks = 15 },
	IDLE 	= { id = 2, name = "IDLE" 		, stats = 0, ticks = 0, maxticks = 120 },
}

function ffxiv_unstuck.Update()
	if 	(ffxiv_unstuck.lastpos == nil) or
		(ffxiv_unstuck.lastpos and type(ffxiv_unstuck.lastpos) ~= "table")
	then
		ffxiv_unstuck.lastpos = Player.pos
	end
	ffxiv_unstuck.diffX = math.abs(Player.pos.x - ffxiv_unstuck.lastpos.x)
	ffxiv_unstuck.diffY = math.abs(Player.pos.y - ffxiv_unstuck.lastpos.y)
	ffxiv_unstuck.diffZ = math.abs(Player.pos.z - ffxiv_unstuck.lastpos.z)
	ffxiv_unstuck.lastpos = Player.pos
	
	if ffxiv_unstuck.IsStuck() then
		ffxiv_unstuck.State.STUCK.ticks = ffxiv_unstuck.State.STUCK.ticks + 1
	else
		ffxiv_unstuck.State.STUCK.ticks = 0
	end
	
	if ffxiv_unstuck.IsOffMesh() then
		ffxiv_unstuck.State.OFFMESH.ticks = ffxiv_unstuck.State.OFFMESH.ticks + 1
	else
		ffxiv_unstuck.State.OFFMESH.ticks = 0
	end
	
	if ffxiv_unstuck.IsIdle() then
		ffxiv_unstuck.State.IDLE.ticks = ffxiv_unstuck.State.IDLE.ticks + 1
	else
		ffxiv_unstuck.State.IDLE.ticks = 0
	end
	
end

function ffxiv_unstuck.IsStuck()
	return 	ffxiv_unstuck.diffX > 0 and ffxiv_unstuck.diffX <= 5 and
			ffxiv_unstuck.diffY > 0 and ffxiv_unstuck.diffY <= 5 and
			ffxiv_unstuck.diffZ > 0 and ffxiv_unstuck.diffZ <= 5 and
			not ActionList:IsCasting() and
			not Player.incombat and
            not ml_global_information.IsWaiting
end

function ffxiv_unstuck.IsOffMesh()
	return not Player.onmesh and not ActionList:IsCasting()
end

function ffxiv_unstuck.IsIdle()
	return 	ffxiv_unstuck.diffX == 0 and
			ffxiv_unstuck.diffY == 0 and
			ffxiv_unstuck.diffZ == 0 and
			not ActionList:IsCasting() and
			not Player.incombat and
			not ml_global_information.IsWaiting
end

--*************************************************************************************************************
-- Unstuck Stuff
--*************************************************************************************************************

function ffxiv_unstuck.CheckStuck()
	if (gDoUnstuck == "0" or 
		gBotMode == strings[gCurrentLanguage].pvpMode or
		gBotMode == strings[gCurrentLanguage].assistMode) 
	then
		return
	end
	
	for i,state in pairs(ffxiv_unstuck.State) do
		if state.ticks ~= 0 then
			if state.ticks > state.maxticks then
				d(state.name..tostring(state.ticks).." EXCEEDED")
                d(ml_task_hub:CurrentTask().name)
                d(Player.hp.percent)
				if not ffxiv_unstuck.task then
					ffxiv_unstuck.State.STUCK.ticks = 0
					ffxiv_unstuck.State.OFFMESH.ticks = 0
					ffxiv_unstuck.State.IDLE.ticks = 0
					ffxiv_unstuck.State[state.name].stats = ffxiv_unstuck.State[state.name].stats + 1
					if (gDoUnstuck == "1") then
						local id = GetLocalAetheryte()
						if (id) then
							ml_global_information.UnstuckTimer = ml_global_information.Now
							Player:Stop()
							Dismount()
							ml_task_hub:ToggleRun()
							d("Teleporting to aetheryte at index "..tostring(id))
							Player:Teleport(id)
							ffxiv_unstuck.count = ffxiv_unstuck.count + 1
							ffxiv_unstuck.laststuck = ml_global_information.Now
						end
					end
					break
				end
			else
				--d(state.name..tostring(state.ticks))
			end
		end
		
	end

end

--*************************************************************************************************************
-- INITIALIZE
--*************************************************************************************************************

function ffxiv_unstuck.HandleUpdate(ticks)
    if  ticks - ffxiv_unstuck.evaltime > 1000 and
        ml_task_hub.shouldRun
    then
        ffxiv_unstuck.evaltime = ticks
        ffxiv_unstuck:Update() --stuck/idle/mesh stuff.
        ffxiv_unstuck:CheckStuck()
    end
    
    if (ffxiv_unstuck.count > 20) then
        Exit()
    end
end
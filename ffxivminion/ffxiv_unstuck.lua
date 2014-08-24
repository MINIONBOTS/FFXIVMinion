ffxiv_unstuck = {}
ffxiv_unstuck.evaltime = 0
ffxiv_unstuck.count = 0
ffxiv_unstuck.laststuck = 0

ffxiv_unstuck.State = {
	STUCK 	= { id = 0, name = "STUCK" 		, stats = 0, ticks = 0, maxticks = 10 },
	OFFMESH = { id = 1, name = "OFFMESH" 	, stats = 0, ticks = 0, maxticks = 15 },
	IDLE 	= { id = 2, name = "IDLE" 		, stats = 0, ticks = 0, maxticks = 120 },
}

function ffxiv_unstuck.Update()
	if (gDoUnstuck == "0") then
		return
	end
	
	if 	(ffxiv_unstuck.lastpos == nil) or
		(ffxiv_unstuck.lastpos and type(ffxiv_unstuck.lastpos) ~= "table")
	then
		ffxiv_unstuck.lastpos = Player.pos
	end
	local currentPos = Player.pos
	ffxiv_unstuck.diffX = math.abs(currentPos.x - ffxiv_unstuck.lastpos.x)
	ffxiv_unstuck.diffY = math.abs(currentPos.y - ffxiv_unstuck.lastpos.y)
	ffxiv_unstuck.diffZ = math.abs(currentPos.z - ffxiv_unstuck.lastpos.z)
	
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
	return 	ffxiv_unstuck.diffX > 0 and ffxiv_unstuck.diffX <= 3 and
			ffxiv_unstuck.diffY > 0 and ffxiv_unstuck.diffY <= 3 and
			ffxiv_unstuck.diffZ > 0 and ffxiv_unstuck.diffZ <= 3 and
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
		gBotMode == strings[gCurrentLanguage].assistMode or 
		gBotMode == strings[gCurrentLanguage].dutyMode) 
	then
		return
	end
	
	for i,state in pairs(ffxiv_unstuck.State) do
		if state.ticks ~= 0 then
			if state.ticks > state.maxticks then
				d(state.name..tostring(state.ticks).." EXCEEDED")
                d(ml_task_hub:CurrentTask().name)
                d(Player.hp.percent)

				ffxiv_unstuck.State.STUCK.ticks = 0
				ffxiv_unstuck.State.OFFMESH.ticks = 0
				ffxiv_unstuck.State.IDLE.ticks = 0
				ffxiv_unstuck.State[state.name].stats = ffxiv_unstuck.State[state.name].stats + 1
				
				if (gDoUnstuck == "1") then
					local id = GetLocalAetheryte()
					if (id) then
						d("Teleporting to aetheryte at index "..tostring(id))
						ml_global_information.UnstuckTimer = ml_global_information.Now
						ffxiv_unstuck.count = ffxiv_unstuck.count + 1
						ffxiv_unstuck.laststuck = ml_global_information.Now
						
						Player:Stop()
						Dismount()
						
						--Changing this to perform the teleport task, since it's safer.
						if (Player.castinginfo.channelingid ~= 5) then
							Player:Teleport(id)
						elseif (Player.castinginfo.channelingid == 5) then										
							local newTask = ffxiv_task_teleport.Create()
							newTask.mapID = Player.localmapid
							newTask.mesh = Settings.minionlib.DefaultMaps[Player.localmapid]
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_ASAP)
						end
					else
						--If we couldn't find an aetheryte, just stop the bot.
						ml_task_hub.ToggleRun()
					end
				end
				break
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
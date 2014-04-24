---------------------------------------------------------------------------------------------
--ADD_TASK CNEs
--These are cnes which are used to check the current game state and add a new task/subtask
--based on the needs of the parent task they are assigned to. They differ from the task
--completion CNEs since they don't perform any action other than to queue a new task. 
--Every task must have a CNE like this to queue it when appropriate. They can be placed
--in either the process elements or the overwatch elements for a task based on the priority
--of the task they queue. MOVETOTARGET, for instance, should be placed in the overwatch
--list since it needs to be checked continually for moving targets; COMBAT can be placed
--into the process list since there is no need to queue another combat task until the
--previous combat task is completed and control returns to the parent task.
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--ADD_KILLTARGET: If (current target hp > 0) Then (add longterm killtarget task)
--Adds a killtarget task if target hp > 0
---------------------------------------------------------------------------------------------
c_add_killtarget = inheritsFrom( ml_cause )
e_add_killtarget = inheritsFrom( ml_effect )

function c_add_killtarget:evaluate()
    -- block killtarget for grinding when user has specified "Fates Only"
	if ((ml_task_hub:CurrentTask().name == "LT_GRIND" or ml_task_hub:CurrentTask().name == "LT_PARTY" ) and gFatesOnly == "1") then
        return false
    end
    -- block killtarget for fates when user has specified a fate completion % to start
    if (ml_task_hub:CurrentTask().name == "LT_FATE" or ml_task_hub:CurrentTask().name == "MOVETOPOS") then
        if (ml_task_hub:CurrentTask().fateid ~= nil) then
            local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
            if ValidTable(fate) then
                if (fate.completion < tonumber(gFateWaitPercent)) then
                    ml_global_information.IsWaiting = true
                    return false
                else
                    ml_global_information.IsWaiting = false
                end
            end
        end
    end
    if (gBotMode == strings[gCurrentLanguage].partyMode and not IsLeader() ) then
        return false
    end
    
    local target = ml_task_hub:CurrentTask().targetFunction()
    if (ValidTable(target)) then
        if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0) then
            c_add_killtarget.targetid = target.id
            return true
        end
    end
    
    return false
end
function e_add_killtarget:execute()
    --just in case
    Dismount()
    
    local newTask = ffxiv_task_killtarget.Create()
    newTask.targetid = c_add_killtarget.targetid
    newTask.targetFunction = ml_task_hub:CurrentTask().targetFunction
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end



c_killaggrotarget = inheritsFrom( ml_cause )
e_killaggrotarget = inheritsFrom( ml_effect )
function c_killaggrotarget:evaluate()
    if ( gKillAggroEnemies == "0" ) then
		return false
	end
	
	
	-- I'll take these out, I dont see any reason why the bot should not defend itself against aggroed enemies while waiting in a fate
    
	--[[ block killtarget for grinding when user has specified "Fates Only"	
	if ( (ml_task_hub:CurrentTask().name == "LT_GRIND" or ml_task_hub:CurrentTask().name == "LT_PARTY" ) and gFatesOnly == "1") then
		return false
	end]]	
	--[[ block killtarget for fates when user has specified a fate completion % to start
    if (ml_task_hub:CurrentTask().name == "LT_FATE" or ml_task_hub:CurrentTask().name == "MOVETOPOS") then
        if (ml_task_hub:CurrentTask().fateid ~= nil) then
            local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
            if ValidTable(fate) then
                if (fate.completion < tonumber(gFateWaitPercent)) then
                    return false
                end
            end
        end
    end]]
    
    local target = GetNearestAggro()
	if (ValidTable(target)) then
		if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0) then
			c_killaggrotarget.targetid = target.id
			return true
		end
	end
    
    return false
end
function e_killaggrotarget:execute()
	--just in case
	Dismount()
	
	local newTask = ffxiv_task_killtarget.Create()
    newTask.targetid = c_killaggrotarget.targetid
	newTask.targetFunction = ml_task_hub:CurrentTask().targetFunction
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end
---------------------------------------------------------------------------------------------
---- minion attacks the target the leader has
--Adds a task to use a combat routine to attack/kill target 
---------------------------------------------------------------------------------------------
c_assistleader = inheritsFrom( ml_cause )
e_assistleader = inheritsFrom( ml_effect )
c_assistleader.targetid = nil
function c_assistleader:evaluate()
    
    if (gBotMode == strings[gCurrentLanguage].partyMode and IsLeader() ) then
        return false
    end
    leader , isEntity = GetPartyLeader()	
    if (leader ~= nil and leader.id ~= 0) then
        local entity = nil
        if (isEntity) then
          entity = leader
        else
          entity = EntityList:Get(leader.id)
        end
        if ( entity ~= nil and entity ~= 0 ) then
            local leadtarget = entity.targetid
            if ( leadtarget ~= nil and leadtarget ~= 0 ) then
                local target = EntityList:Get(leadtarget)
                if ( target ~= nil and target ~= 0 and target.attackable and target.alive and target.distance2d < 30) then
                    if ( target.onmesh or InCombatRange(target.id)) then
                        c_assistleader.targetid = target.id
                        return true
                    end
                end
            end
        end
    end
    
    return false
end
function e_assistleader:execute()
    if ( c_assistleader.targetid ) then
		if ( Player.ismounted ) then
			Dismount()
		end
        local newTask = ffxiv_task_killtarget.Create()
        newTask.targetFunction = ml_task_hub:CurrentTask().targetFunction
        newTask.targetid = c_assistleader.targetid 
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    else
        wt_debug("Ohboy, something went really wrong : e_assistleader")
    end
end

---------------------------------------------------------------------------------------------
--ADD_COMBAT: If (target hp > 0) Then (add combat task)
--Adds a task to use a combat routine to attack/kill target 
---------------------------------------------------------------------------------------------
c_add_combat = inheritsFrom( ml_cause )
e_add_combat = inheritsFrom( ml_effect )
function c_add_combat:evaluate()
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
    if target ~= nil and target ~= 0 then
        return InCombatRange(target.id) and target.alive
    end
        
    return false
end
function e_add_combat:execute()
    if ( gSMactive == "1" ) then
        local newTask = ffxiv_task_skillmgrAttack.Create()
        newTask.targetid = ml_task_hub:CurrentTask().targetid
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    else
        local newTask = ml_global_information.CurrentClass.Create()
        newTask.targetid = ml_task_hub:CurrentTask().targetid
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

---------------------------------------------------------------------------------------------
--ADD_FATE: If (fate of proper level is on mesh) Then (add longterm fate task)
--Adds a fate task if there is a fate on the mesh
---------------------------------------------------------------------------------------------
c_add_fate = inheritsFrom( ml_cause )
e_add_fate = inheritsFrom( ml_effect )
function c_add_fate:evaluate()    
    if (gBotMode == strings[gCurrentLanguage].partyMode and not IsLeader()) then
		return false
    end
    
    if (gDoFates == "1") then
        if (ml_task_hub:ThisTask().subtask == nil or ml_task_hub:ThisTask().subtask.name ~= "LT_FATE") then
            local myPos = Player.pos
            local fateID = GetClosestFateID(myPos, true, true)
            if (fateID ~= 0) then
                local fate = GetFateByID(fateID)
                if (fate ~= nil and TableSize(fate) > 0) then
					if (fate.status == 2 ) or (fate.status == 7 and Distance2D(myPos.x, myPos.y, fate.x, fate.y) < 50) then
                        ml_global_information.IsWaiting = false
                        return true
                    end
                end
            end
        end
    end
    
    return false
end
function e_add_fate:execute()
    local newTask = ffxiv_task_fate.Create()
    local myPos = Player.pos
    newTask.fateid = GetClosestFateID(myPos, true, true)
    newTask.fateTimer = ml_global_information.Now
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

---------------------------------------------------------------------------------------------
--ADD_MOVETOTARGET: If (current target distance > combat range) Then (add movetotarget task)
--Adds a MoveToTarget task 
---------------------------------------------------------------------------------------------
c_movetotarget = inheritsFrom( ml_cause )
e_movetotarget = inheritsFrom( ml_effect )
function c_movetotarget:evaluate()
    if ( ml_task_hub:CurrentTask().targetid ~= nil and ml_task_hub:CurrentTask().targetid ~= 0 ) then
        local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
        if (target ~= nil and target ~= 0 and target.alive) then
            return not InCombatRange(target.id)
        end
    end
    
    return false
end
function e_movetotarget:execute()
    ml_debug( "Moving within combat range of target" )
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
    if (target ~= nil and target.pos ~= nil) then
        local newTask = ffxiv_task_movetopos.Create()
        newTask.pos = target.pos
        newTask.targetid = target.id
        newTask.useFollowMovement = true
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

---------------------------------------------------------------------------------------------
--ADD_MOVETOMAP
--Adds a MoveToGate task 
---------------------------------------------------------------------------------------------
c_movetogate = inheritsFrom( ml_cause )
e_movetogate = inheritsFrom( ml_effect )
function c_movetogate:evaluate()
    if (ml_task_hub:CurrentTask().destMapID) then
        return 	Player.localmapid ~= ml_task_hub:CurrentTask().destMapID and
				not Quest:IsLoading() and
				not mm.reloadMeshPending
	end
end
function e_movetogate:execute()
    ml_debug( "Moving to gate for next map" )
	
	local pos = ml_nav_manager.GetNextPathPos(	Player.pos,
												Player.localmapid,
												ml_task_hub:CurrentTask().destMapID	)
	if (ValidTable(pos)) then
		local newTask = ffxiv_task_movetopos.Create()
		local newPos = GetPosFromDistanceHeading(pos, 1.5, pos.h)
		newTask.pos = newPos
		--newTask.useFollowMovement = true
		--newTask.range = 0.5
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	end
end

c_teleporttomap = inheritsFrom( ml_cause )
e_teleporttomap = inheritsFrom( ml_effect )
function c_teleporttomap:evaluate()
	if (gUseAetherytes == "0") then
		return false
	end

    if (ml_task_hub:CurrentTask().tryTP and ml_task_hub:CurrentTask().destMapID) then
        local pos = ml_nav_manager.GetNextPathPos(	Player.pos,
                                                    Player.localmapid,
                                                    ml_task_hub:CurrentTask().destMapID	)
    
        if (ValidTable(ml_nav_manager.currPath)) then
            local aethid = nil
            for _, node in pairsByKeys(ml_nav_manager.currPath) do
                if (node.id ~= Player.localmapid) then
                    aethid = GetAetheryteByMapID(node.id)
                end
            end
            
            if (aethid) then
                e_teleporttomap.aethid = aethid
                return true
            end
        end
    end
    
    ml_task_hub:CurrentTask().tryTP = false
    return false
end
function e_teleporttomap:execute()
    ml_global_information.UnstuckTimer = ml_global_information.Now
    Player:Stop()
    Dismount()
    ml_task_hub:ToggleRun()
    d("Teleporting to aetheryte at index "..tostring(e_teleporttomap.aethid))
    Player:Teleport(e_teleporttomap.aethid)
end

c_reactonleaderaction = inheritsFrom( ml_cause )
e_reactonleaderaction= inheritsFrom( ml_effect )
c_reactonleaderaction.Reaction  = 0

function c_reactonleaderaction:evaluate()
    local leader , isEntity = GetPartyLeader()
    if ( leader ~= nil ) then
        local leaderE = nil
        if (isEntity) then
          leaderE = leader
        else
          leaderE = EntityList:Get(leader.id)
        end
        
        if ( leaderE ~= nil and leaderE ~= 0 ) then
          if (leaderE.castinginfo.channelingid==4 or leaderE.action == 166 or leaderE.action == 167
              and gUseMount == "1" and not Player.ismounted and not Player.incombat) then
                c_reactonleaderaction.Reaction = 1
                return true
          end
          
          local distance = Distance2D(Player.pos.x, Player.pos.z, leaderE.pos.x, leaderE.pos.z)
          if (leaderE.action ~= 166 and leaderE.action ~= 167 and Player.ismounted and distance < 20) then
            c_reactonleaderaction.Reaction = 2
            return true
          end
        end
    end
    return false
end

function e_reactonleaderaction:execute()
    if (c_reactonleaderaction.Reaction == 1) then
      if (not ActionList:IsCasting() ) then
        Player:Stop()
        Mount()
      end
    elseif (c_reactonleaderaction.Reaction == 2) then
      if (not ActionList:IsCasting() ) then
        --Player:Stop()
        Dismount()
      end
    end
    

    
end

c_followleader = inheritsFrom( ml_cause )
e_followleader = inheritsFrom( ml_effect )
c_followleader.rrange = math.random(5,10)
c_followleader.leader = nil
function c_followleader:evaluate()
    
    if (gBotMode == strings[gCurrentLanguage].partyMode and IsLeader()) then
        return false
    end
    
    local leader , isEntity = GetPartyLeader()
    if ( leader ~= nil ) then
        if ( (not isEntity and leader.mapid == Player.localmapid) or isEntity  ) then
            c_followleader.leaderpos = leader.pos
            if ( c_followleader.leaderpos.x ~= -1000 ) then 			
                local myPos = Player.pos				
                local distance = Distance2D(myPos.x, myPos.z, c_followleader.leaderpos.x, c_followleader.leaderpos.z)
                if ((distance > c_followleader.rrange and leader.onmesh) or (distance > c_followleader.rrange and distance < 30 and not leader.onmesh)) then					
                    c_followleader.leader = leader
                    return true
                end
            end
        end
    end    
    return false
end

function e_followleader:execute()
    -- honestly I tried to build a new task here, I tried n wasted more than 4  hours, it just doesnt work, gets stuck , doesnt return, repeatly goes into movetask or just doesnt finish it, got enough now
    if ( c_followleader.leader ~= nil) then	
        if ( leader.onmesh and Player.onmesh) then
            local lpos = c_followleader.leader.pos
            local myPos = Player.pos
            local distance = Distance2D(myPos.x, myPos.z, lpos.x, lpos.z)	
            
            -- mount
            if ( gUseMount == "1" and not Player.ismounted and not Player.incombat) then							
                if (c_followleader.leader.castinginfo.channelingid==4 or c_followleader.leader.action == 166 or c_followleader.leader.action == 167 or  distance > tonumber(gMountDist)) then
                    if (not ActionList:IsCasting() ) then
                      Player:Stop()
                      Mount()
                    end
                    return
                end
            end
            
            --sprint
            if ( not HasBuff(Player.id, 50) and not Player.ismounted and gUseSprint == "1") then
                local skill = ActionList:Get(3)
                if (skill.isready) then
                    if (distance > tonumber(gSprintDist)) then		
                        skill:Cast()
                    end
                end
            end
            
            ml_debug( "Moving to Leader: "..tostring(Player:MoveTo(tonumber(lpos.x),tonumber(lpos.y),tonumber(lpos.z),tonumber(c_followleader.rrange),true,false)))	
            if ( not Player:IsMoving()) then
                if ( ml_global_information.AttackRange < 5 ) then
                  c_followleader.rrange = math.random(4,8)
                else
                  c_followleader.rrange = math.random(8,20)
                end
            end
        else
            if ( not Player:IsMoving() ) then
                FollowResult = Player:FollowTarget(c_followleader.leader.id)
                ml_debug( "Following Leader: "..tostring(FollowResult))
            end
        end
    end
end

---------------------------------------------------------------------------------------------
--Task Completion CNEs
--These are cnes which are added to the process element list for a task and exist only to
--complete the specified task. They should be specific to the task which contains them...
--their only purpose should be to check the current game state and adjust the behavior of 
--the task in order to ensure its completion. 
---------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
--WALKTOPOS: If (distance to target > task.range) Then (move to pos)
---------------------------------------------------------------------------------------------
c_walktopos = inheritsFrom( ml_cause )
e_walktopos = inheritsFrom( ml_effect )
c_walktopos.pos = 0
function c_walktopos:evaluate()
    if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0 ) then
        if (ActionList:IsCasting()) then
            return false
        end
        
        local myPos = Player.pos
        local gotoPos = ml_task_hub:CurrentTask().pos
        -- switching to 2d for now, since c++ uses 2d and the movement to points with a small stopping distance just cant work with that 2d-3d difference     
        local distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
        ml_debug("Bot Position: ("..tostring(myPos.x)..","..tostring(myPos.y)..","..tostring(myPos.z)..")")
        ml_debug("MoveTo Position: ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")
        ml_debug("Current Distance: "..tostring(distance))
        ml_debug("Execute Distance: "..tostring(ml_task_hub:CurrentTask().range))
        
        if (distance > ml_task_hub:CurrentTask().range) then		
            c_walktopos.pos = gotoPos
            return true
        end
    end
    return false
end
function e_walktopos:execute()
    if ( c_walktopos.pos ~= 0) then
        local gotoPos = c_walktopos.pos
        ml_debug( "Moving to ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")	
        local PathSize = Player:MoveTo(tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z),tonumber(ml_task_hub:CurrentTask().range *0.75), ml_task_hub:CurrentTask().useFollowMovement or false,gRandomPaths=="1")
    else
        mt_error(" Critical error in e_walktopos, c_walktopos.pos == 0!!")
    end
    c_walktopos.pos = 0
end


-- Checks for a better target while we are engaged in fighting an enemy and switches to it
c_bettertargetsearch = inheritsFrom( ml_cause )
e_bettertargetsearch = inheritsFrom( ml_effect )
function c_bettertargetsearch:evaluate()	
    if (gBotMode == strings[gCurrentLanguage].partyMode and not IsLeader() ) then
        return false
    end
    
    -- this breaks rest because we never finish the current target
    if (Player.hp.percent < tonumber(gRestHP) or Player.mp.percent < tonumber(gRestMP)) then
        return false
    end
    
    if (ml_task_hub:ThisTask().targetid~=nil and ml_task_hub:ThisTask().targetid~=0)then		
        local bettertarget = ml_task_hub:ThisTask().targetFunction()
        if ( bettertarget ~= nil and bettertarget.id ~= ml_task_hub:ThisTask().targetid ) then
            ml_task_hub:ThisTask().targetid = bettertarget.id
            Player:SetTarget(bettertarget.id)
            return true			
        end		
    end	
    return false
end
function e_bettertargetsearch:execute()
    Player:Stop()	
    d("Switching Target to better target")
    
    --ml_task_hub:ThisTask():Terminate()
end



-----------------------------------------------------------------------------------------------
--MOUNT: If (distance to pos > ? or < ?) Then (mount or unmount)
---------------------------------------------------------------------------------------------
c_mount = inheritsFrom( ml_cause )
e_mount = inheritsFrom( ml_effect )
function c_mount:evaluate()
    if (gBotMode == "PVP") or
		Player.localmapid == 130 or
		Player.localmapid == 131 or
		Player.localmapid == 132 or
		Player.localmapid == 133 or
		Player.localmapid == 128 or
		Player.localmapid == 129
	then
        return false
    end

    if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0 and gUseMount == "1" ) then
        if (not Player.ismounted and not ActionList:IsCasting() and not Player.incombat) then
            local myPos = Player.pos
            local gotoPos = ml_task_hub:CurrentTask().pos
            local distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
        
            if (distance > tonumber(gMountDist)) then
                return true
            end
        end
    end
    
    return false
end
function e_mount:execute()
    Player:Stop()
    Mount()
end

-----------------------------------------------------------------------------------------------
--SPRINT: If (distance to pos > ? or < ?) Then (mount or unmount)
---------------------------------------------------------------------------------------------
c_sprint = inheritsFrom( ml_cause )
e_sprint = inheritsFrom( ml_effect )
function c_sprint:evaluate()
    if (gBotMode == "PVP") then
        return false
    end

    if not HasBuff(Player.id, 50) and not Player.ismounted then
        local skills = ActionList("type=1")
        local skill = skills[3]
        if (skill.isready) then
            if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0 and gUseSprint == "1") then
                local myPos = Player.pos
                local gotoPos = ml_task_hub:CurrentTask().pos
                local distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
                
                if (distance > tonumber(gSprintDist)) then		
                    return true
                end
            end
        end
    end
    
    return false
end
function e_sprint:execute()
    ActionList:Get(3):Cast()
end

--minor abuse of the cne system here to update target pos
c_updatetarget = inheritsFrom( ml_cause )
e_updatetarget = inheritsFrom( ml_effect )
function c_updatetarget:evaluate()	
    if (ml_task_hub:ThisTask().targetid~=nil and ml_task_hub:ThisTask().targetid~=0)then
        local target = EntityList:Get(ml_task_hub.ThisTask().targetid)
        if (target ~= nil) then
            if (target.alive and target.attackable) then
                if (ml_task_hub:CurrentTask().name == "MOVETOPOS" ) then
					e_updatetarget.pos = target.pos				
                end
				return false
            end
        end
    end	
end
function e_updatetarget:execute()
end


-- Updates the leaderposition and ID for the partytask - minions, since we have only the position and the leader is not in the Entitylist when he is too far away
c_updateleaderdata = inheritsFrom( ml_cause )
e_updateleaderdata = inheritsFrom( ml_effect )
function c_updateleaderdata:evaluate()	
    local leader = GetPartyLeader()
    if (leader ~=nil and leader.id ~= 0) then	
        if (ml_task_hub:CurrentTask().name == "FOLLOWENTITY" ) then
            local myPos = Player.pos
            if (Distance2D(myPos.x, myPos.z, ml_task_hub:CurrentTask().pos.x, ml_task_hub:CurrentTask().pos.z) > 10 and leader.onmesh) then
                ml_task_hub:CurrentTask().pos = leader.pos
                ml_task_hub:CurrentTask().targetid = leader.id
            end
        end		
    end	
    return false
end
function e_updateleaderdata:execute()

end

c_attarget = inheritsFrom( ml_cause )
e_attarget = inheritsFrom( ml_effect )
function c_attarget:evaluate()
    if (ml_task_hub:CurrentTask().name == "MOVETOPOS") then
        --if ml_task_hub:ThisTask():ParentTask().name == "LT_FATE" and ml_global_information.AttackRange > 20 then
        if ml_global_information.AttackRange > 20 then
            local target = EntityList:Get(ml_task_hub:ThisTask().targetid)
            if ValidTable(target) then
                local rangePercent = tonumber(gCombatRangePercent) * 0.01
                return InCombatRange(ml_task_hub:ThisTask().targetid) and target.distance2d < (ml_global_information.AttackRange * rangePercent)
            end
        else
            return InCombatRange(ml_task_hub:ThisTask().targetid)
        end
    end
    return false
end
function e_attarget:execute()
    Player:Stop()
    ml_task_hub:CurrentTask():task_complete_execute()
    ml_task_hub:CurrentTask():Terminate()
end

---------------------------------------------------------------------------------------------
--REACTIVE/IMMEDIATE Game State CNEs
--These are cnes which are used to check the current game state and perform some kind of
--emergency action. They should generally be placed in the overwatch element list at an
--appropriate level in the subtask tree so that they can monitor all subtasks below them
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--NOTARGET: If (no current target) Then (find the nearest fate mob)
--Gets a new target using the targeting function of the parent task
---------------------------------------------------------------------------------------------
c_notarget = inheritsFrom( ml_cause )
e_notarget = inheritsFrom( ml_effect )
function c_notarget:evaluate()
    
    if ( ml_task_hub:CurrentTask().targetFunction() ~= nil ) then
        if ( ml_task_hub:CurrentTask().targetid == nil or ml_task_hub:CurrentTask().targetid == 0 ) then
            return true
        end
        
        local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
        if (target ~= nil) then
            if (not target.alive or not target.targetable) then
                return true
            end
        elseif (target == nil) then
            return true
        end
    end    
    return false
end
function e_notarget:execute()
    ml_debug( "Getting new target" )
    local target = ml_task_hub:CurrentTask().targetFunction()
    if (target ~= nil and target ~= 0) then
        Player:SetFacing(target.pos.x, target.pos.y, target.pos.z)
        ml_task_hub:CurrentTask().targetid = target.id
    end
end

---------------------------------------------------------------------------------------------
--MOBAGGRO: If (detect new aggro) Then (kill mob)
--
---------------------------------------------------------------------------------------------
c_mobaggro = inheritsFrom( ml_cause )
e_mobaggro = inheritsFrom( ml_effect )
function c_mobaggro:evaluate()
    if ( Player.hasaggro ) then
        local target = GetNearestAggro()
        if (target ~= nil and target ~= 0) then
            e_mobaggro.targetid = target.id
            return true
        end
    end
    
    return false
end
function e_mobaggro:execute()
    ml_debug( "Getting new target" )
    local target = GetNearestAggro()
    if (target ~= nil) then
        local newTask = ffxiv_task_killtarget.Create()
        newTask.targetFunction = ml_task_hub:CurrentTask().targetFunction
        newTask.targetid = e_mobaggro.targetid
        ml_task_hub.Add(newTask, QUEUE_REACTIVE, TP_IMMEDIATE)
    end
end

---------------------------------------------------------------------------------------------
--REST: If (not player.hasAggro and player.hp.percent < 50) Then (do nothing)
--Blocks all subtask execution until player hp has increased
---------------------------------------------------------------------------------------------
c_rest = inheritsFrom( ml_cause )
e_rest = inheritsFrom( ml_effect )
function c_rest:evaluate()
    -- don't rest if we have rest in fates disabled and we're in a fate or FatesOnly is enabled
    if (gRestInFates == "0") then
        if  (ml_task_hub:CurrentTask() ~= nil and ml_task_hub:CurrentTask().name == "LT_FATE") or (gFatesOnly == "1") then
            return false
        end
    end
   
	if ( TableSize(EntityList("shortestpath,alive,incombat,targetingme") == 0 ) and not Player.incombat) then
        if (e_rest.resting or 		
            Player.hp.percent < tonumber(gRestHP) or
            Player.mp.percent < tonumber(gRestMP))
        then
            ml_global_information.IsWaiting = true
            return true
        end
    end
    
    return false
end
function e_rest:execute()
    --[[if ( gSMactive == "1" and Player.hp.percent < tonumber(gRestHP)) then
        local newTask = ffxiv_task_skillmgrHeal.Create()
        newTask.targetid = Player.id
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    end]] --have to fix that
    
    if (e_rest.resting == true) then
        if (Player.hp.percent == 100) and (Player.mp.percent == 100)  then
            e_rest.resting = false
            ml_global_information.IsWaiting = false
            return
        end
    else
        if (Player.hp.percent < tonumber(gRestHP) or
            Player.mp.percent < tonumber(gRestMP)) 
        then
            ml_global_information.IsWaiting = true
            Player:Stop()
            e_rest.resting = true
            return
        end
    end
end

---------------------------------------------------------------------------------------------
--FLEE: If (aggolist.size > 0 and health.percent < 50) Then (run to a random point)
--Attempts to shake aggro by running away and resting
---------------------------------------------------------------------------------------------
c_flee = inheritsFrom( ml_cause )
e_flee = inheritsFrom( ml_effect )
e_flee.fleeing = false
function c_flee:evaluate()
    if (ValidTable(ml_marker_mgr.markerList["evacPoint"]) and (Player.hasaggro and (Player.hp.percent < tonumber(gFleeHP) or Player.mp.percent < tonumber(gFleeMP)))) or e_flee.fleeing
    then
        return true
    end
    
    return false
end
function e_flee:execute()
    if (e_flee.fleeing) then
        if (not Player.hasaggro) then
            Player:Stop()
            e_flee.fleeing = false
            return
        end
    else
        local fleePos = ml_marker_mgr.markerList["evacPoint"]
        if (fleePos ~= nil and fleePos ~= 0) then
            ml_debug( "Fleeing combat" )
            ml_task_hub:ThisTask():DeleteSubTasks()
            Player:MoveTo(fleePos.x, fleePos.y, fleePos.z, 1.5, false, gRandomPaths=="1")
            e_flee.fleeing = true
        else
            ml_error( "Need to flee combat but no evacPoint set!!")
        end
    end
end

---------------------------------------------------------------------------------------------
--DEAD: Checks Revivestate of player and revives at nearest aetheryte, homepoint, favpoint or we shall see 
--Blocks all subtask execution until player is alive 
---------------------------------------------------------------------------------------------
c_dead = inheritsFrom( ml_cause )
e_dead = inheritsFrom( ml_effect )
function c_dead:evaluate()
    if (Player.revivestate == 2 or Player.revivestate == 3) then --FFXIV.REVIVESTATE.DEAD & REVIVING
        return true
    end 
    return false
end
function e_dead:execute()
    ml_debug("Respawning...")
	-- try raise first
    if(PressYesNo(true)) then
      return
    end
	-- press ok
    if(PressOK()) then
      return
    end
end

c_pressconfirm = inheritsFrom( ml_cause )
c_pressconfirm.throttle = 5000
e_pressconfirm = inheritsFrom( ml_effect )
function c_pressconfirm:evaluate() 
    return ((Player.localmapid ~= 337 and Player.localmapid ~= 175 and Player.localmapid ~= 336) and ControlVisible("ContentsFinderConfirm"))
end
function e_pressconfirm:execute()
	PressDutyConfirm(true)
	if (gBotMode == strings[gCurrentLanguage].pvpMode) then
		ml_task_hub:CurrentTask().state = "DUTY_STARTED"
		ml_task_hub:CurrentTask().afkTimer = ml_global_information.Now + math.random(30000,60000)
	elseif (gBotMode == strings[gCurrentLanguage].dutyMode) then
		ml_task_hub:CurrentTask().timer = ml_global_information.Now + tonumber(gEnterDutyTimer)
		ml_task_hub:CurrentTask().state = "DUTY_ENTER"
	end
end

-- more to refactor here later most likely
c_returntomarker = inheritsFrom( ml_cause )
e_returntomarker = inheritsFrom( ml_effect )
function c_returntomarker:evaluate()
    if (gBotMode == strings[gCurrentLanguage].partyMode and not IsLeader() ) then
        return false
    end
	
	-- never switch to a new marker when the gatherableitemselect window is up, happens in some rare occasions
	if gBotMode == strings[gCurrentLanguage].gatherMode then
        local list = Player:GetGatherableSlotList()
        if (list ~= nil) then
            return false
        end
    end
    
	-- right now when randomize markers is active, it first walks to the marker and then checks for levelrange, this should probably get changed, but 
	-- making this will most likely break the behavior on some badly made meshes 
    if (ml_task_hub:CurrentTask().currentMarker ~= false and ml_task_hub:CurrentTask().currentMarker ~= nil) then
        local myPos = Player.pos
        local pos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
        local distance = Distance2D(myPos.x, myPos.z, pos.x, pos.z)
        if  (gBotMode == strings[gCurrentLanguage].grindMode and distance > 200) or
			(gBotMode == strings[gCurrentLanguage].partyMode and distance > 200) or
			(gBotMode == strings[gCurrentLanguage].gatherMode and ml_task_hub:CurrentTask().maxGatherDistance and distance > ml_task_hub:CurrentTask().maxGatherDistance) or
			(gBotMode == strings[gCurrentLanguage].fishMode and distance > 3)
        then
            return true
        end
    end
    
    return false
end
function e_returntomarker:execute()
    local newTask = ffxiv_task_movetopos.Create()
    local markerPos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
    local markerType = ml_task_hub:CurrentTask().currentMarker:GetType()
    newTask.pos = markerPos
    newTask.range = math.random(5,25)
    if (markerType == "Fishing Marker") then
        newTask.pos.h = markerPos.h
        newTask.range = 0.5
        newTask.doFacing = true
    end
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

---------------------------------------------------------------------------------------------
--STEALTH: If (distance to aggro < 18) Then (cast stealth)
--Uses stealth when gathering to avoid aggro
---------------------------------------------------------------------------------------------
c_stealth = inheritsFrom( ml_cause )
e_stealth = inheritsFrom( ml_effect )
function c_stealth:evaluate()
    if  (Player.ismounted or
        (gBotMode == strings[gCurrentLanguage].gatherMode and gDoStealth == "0") or
        (gBotMode == strings[gCurrentLanguage].fishMode and gDoStealthFish == "0"))
    then
        return false
    end
    local action = nil
    if (Player.job == FFXIV.JOBS.BOTANIST) then
        action = ActionList:Get(212)
    elseif (Player.job == FFXIV.JOBS.MINER) then
        action = ActionList:Get(229)
    elseif (Player.job == FFXIV.JOBS.FISHER) then
        action = ActionList:Get(298)
    end
    
    if (action and action.isready) then
    local mobList = EntityList("attackable,aggressive,notincombat,maxdistance=25")
        if(TableSize(mobList) > 0 and not HasBuff(Player.id, 47)) or
          (TableSize(mobList) == 0 and HasBuff(Player.id, 47)) 
        then
            return true
        end
    end
 
    return false
end
function e_stealth:execute()
    local action = nil
    if (Player.job == FFXIV.JOBS.BOTANIST) then
        action = ActionList:Get(212)
    elseif (Player.job == FFXIV.JOBS.MINER) then
        action = ActionList:Get(229)
    elseif (Player.job == FFXIV.JOBS.FISHER) then
        action = ActionList:Get(298)
    end
    if(action and action.isready) then
        if HasBuff(Player.id, 47) then
            Player:Stop()
        end
        action:Cast()
    end
end

c_roll = inheritsFrom( ml_cause )
e_roll = inheritsFrom( ml_effect )
function c_roll:evaluate()	
	if (Inventory:HasLoot() == false) then
		return false
	end
	
	local loot = Inventory:GetLootList()
	if (loot and ml_task_hub:CurrentTask().rollstate ~= "Complete") then
		return true
	end
    
    return false
end
function e_roll:execute()
	local loot = Inventory:GetLootList()
	if (loot) then
		local i,e = next(loot)
		while (i~=nil and e~=nil) do    
			if (ml_task_hub:CurrentTask().rollstate == "Need") then
				e:Need()
				ml_task_hub:CurrentTask().lastroll = ml_global_information.Now
				ml_task_hub:CurrentTask().rollstate = "Greed"
			end
			if (ml_task_hub:CurrentTask().rollstate == "Greed" and TimeSince(ml_task_hub:CurrentTask().lastroll) >= 1000) then
				e:Greed()
				ml_task_hub:CurrentTask().lastroll = ml_global_information.Now
				ml_task_hub:CurrentTask().rollstate = "Pass"
			end
			if (ml_task_hub:CurrentTask().rollstate == "Pass" and TimeSince(ml_task_hub:CurrentTask().lastroll) >= 1000) then
				e:Pass()
				ml_task_hub:CurrentTask().lastroll = ml_global_information.Now
				ml_task_hub:CurrentTask().rollstate = "Complete"
			end
			i,e = next (loot,i)
		end  
	end
end

c_loot = inheritsFrom( ml_cause )
e_loot = inheritsFrom( ml_effect )
c_loot.chestid = nil
function c_loot:evaluate()
	if (Inventory:HasLoot() == false) then
		local chest = nil
		chest = EntityList("type=4,chartype=0,maxdistance=3")
		if ( chest ) then
			local i,e = next(chest)
			if (i~=nil and e~=nil) then
				c_loot.chestid = e.id
				return true
			end
		end
	end
    return false
end
function e_loot:execute()
	Player:Interact(c_loot.chestid)
end

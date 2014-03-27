---------------------------------------------------------------------------------------------
--LONGTERM GOALS--
--These are strategy level tasks which incorporate multiple layers of subtasks and reactive
--tasks to complete a specific action. They should generally be placed near the root level
--of task in the LONGTERM task queue
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--TASK_KILLTARGET: LongTerm Goal - Kill the specified target
---------------------------------------------------------------------------------------------
ffxiv_task_killtarget = inheritsFrom(ml_task)

function ffxiv_task_killtarget.Create()
    local newinst = inheritsFrom(ffxiv_task_killtarget)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_killtarget members
    newinst.name = "LT_KILLTARGET"
    newinst.targetid = 0
    
    return newinst
end

function ffxiv_task_killtarget:Init()
    --init ProcessOverWatch() cnes
    
    local ke_attarget = ml_element:create("AtTarget", c_attarget, e_attarget, 15)
    self:add( ke_attarget, self.overwatch_elements)
    
    --local ke_bettertargetsearch = ml_element:create("SearchBetterTarget", c_bettertargetsearch, e_bettertargetsearch, 10)
    --self:add( ke_bettertargetsearch, self.overwatch_elements)
    
    local ke_updateTarget = ml_element:create("UpdateTarget", c_updatetarget, e_updatetarget, 5)
    self:add( ke_updateTarget, self.overwatch_elements)
        
    --Process() cnes		    
    local ke_moveToTarget = ml_element:create( "MoveToTarget", c_movetotarget, e_movetotarget, 10 )
    self:add( ke_moveToTarget, self.process_elements)
    
    local ke_combat = ml_element:create( "AddCombat", c_add_combat, e_add_combat, 5 )
    self:add( ke_combat, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_killtarget:task_complete_eval()
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
    if (not target or not target.attackable or (target and not target.alive) or (target and not target.onmesh and not InCombatRange(target.id))) then
        return true
    end
    
    return false
end

function ffxiv_task_killtarget:task_complete_execute()
    self.completed = true
end


---------------------------------------------------------------------------------------------
--REACTIVE GOALS--
--These are tasks which may be called in reaction to changes in the game state, such as
--mob movement/aggro. They should be placed in the REACTIVE queue and continue to pulse 
--there until they are completed and control returns to the LONGTERM queue rootTask. 
--They are generally placed in the ProcessOverWatch element list of a strategy level
--task since they need to monitor game state changes continually.
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--TASK_MOVETOPOS: Reactive Goal - Move to the specified position
--This task moves the player to a specified position, the partent of this task needs to make sure
--that this movetopos task has up2date positions and is still valid.
---------------------------------------------------------------------------------------------
ffxiv_task_movetopos = inheritsFrom(ml_task)

function ffxiv_task_movetopos.Create()
    local newinst = inheritsFrom(ffxiv_task_movetopos)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetopos members
    newinst.name = "MOVETOPOS"
    newinst.pos = 0
    newinst.range = 1.0
    newinst.doFacing = false
    newinst.pauseTimer = 0
    newinst.gatherRange = 0.0
    newinst.remainMounted = false
    newinst.useFollowMovement = false
    
    return newinst
end



function ffxiv_task_movetopos:Init()
    local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 20 )
    self:add( ke_mount, self.process_elements)
    
    local ke_sprint = ml_element:create( "Sprint", c_sprint, e_sprint, 15 )
    self:add( ke_sprint, self.process_elements)
    
    -- The parent needs to take care of checking and updating the position of this task!!	
    local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 10 )
    self:add( ke_walkToPos, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetopos:task_complete_eval()
	if (Quest:IsLoading() or
		mm.reloadMeshPending )
	then
		return true
	end

    if ( ml_task_hub:CurrentTask().pos ~= nil and TableSize(ml_task_hub:CurrentTask().pos) > 0 ) then
        local myPos = Player.pos
        local gotoPos = ml_task_hub:CurrentTask().pos
        -- switching to 2d for now, since c++ uses 2d and the movement to points with a small stopping distance just cant work with that 2d-3d difference     
        local distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
        ml_debug("Bot Position: ("..tostring(myPos.x)..","..tostring(myPos.y)..","..tostring(myPos.z)..")")
        ml_debug("MoveTo Position: ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")
        ml_debug("Task Range: "..tostring(self.range))
        ml_debug("Current Distance: "..tostring(distance))
        ml_debug("Completion Distance: "..tostring(self.range + self.gatherRange))
        
        if (distance <= self.range + self.gatherRange) then
            return true
        end
    else
        mt_error(" ERROR: no valid position in ffxiv_task_movetopos ")
    end    
    return false
end

function ffxiv_task_movetopos:task_complete_execute()
    Player:Stop()
    
    if (not ml_task_hub:CurrentTask().remainMounted) then
        Dismount()
    end
    
    if (ml_task_hub:CurrentTask().doFacing) then
        Player:SetFacingSynced(ml_task_hub:CurrentTask().pos.h)
    end
    
    ml_task_hub:CurrentTask().completed = true
end

----------------------------------------------------------------------------------------------------------

ffxiv_task_movetomap = inheritsFrom(ml_task)
function ffxiv_task_movetomap.Create()
    local newinst = inheritsFrom(ffxiv_task_movetomap)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetomap members
    newinst.name = "MOVETOMAP"
    newinst.destMapID = 0
    newinst.tryTP = true
   
    return newinst
end

function ffxiv_task_movetomap:Init()
    local ke_teleportToMap = ml_element:create( "TeleportToMap", c_teleporttomap, e_teleporttomap, 15 )
    self:add( ke_teleportToMap, self.process_elements)

    local ke_moveToGate = ml_element:create( "MoveToGate", c_movetogate, e_movetogate, 10 )
    self:add( ke_moveToGate, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetomap:task_complete_eval()
    return Player.localmapid == ml_task_hub:CurrentTask().destMapID
end

ffxiv_task_loot = inheritsFrom(ml_task)
function ffxiv_task_loot.Create()
    local newinst = inheritsFrom(ffxiv_task_loot)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
   
    newinst.name = "LT_LOOT"
	newinst.lastroll = nil
	newinst.rollstate = "Need"
    
    return newinst
end

function ffxiv_task_loot:Init() 	
	local ke_lootroll = ml_element:create( "Roll", c_roll, e_roll, 10 )
    self:add(ke_lootroll, self.process_elements)
	
    local ke_loot = ml_element:create( "Loot", c_loot, e_loot, 5 )
    self:add(ke_loot, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_loot:task_complete_eval()	
	if (ml_task_hub:CurrentTask().rollstate == "Complete" and
		Inventory:HasLoot() == false) then
		return true
	end

	return false
end

function ffxiv_task_loot:task_complete_execute()
    self.completed = true
	ml_task_hub:CurrentTask():ParentTask().encounterCompleted = true
end

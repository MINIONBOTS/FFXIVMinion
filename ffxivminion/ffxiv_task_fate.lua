---------------------------------------------------------------------------------------------
--TASK_FATE: Longterm Goal - Complete a fate event successfully
---------------------------------------------------------------------------------------------
ffxiv_task_fate = inheritsFrom(ml_task)

function ffxiv_task_fate:Create()
    local newinst = inheritsFrom(ffxiv_task_fate)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_fate members
    newinst.name = "LT_FATE"
    newinst.fateid = 0
    newinst.targetFunction = GetNearestFateAttackable
    newinst.fateTimer = 0
    newinst.fateCompletion = 0
	newinst.started = false
	newinst.moving = false
	newinst.fatePos = {}
    
    return newinst
end

---------------------------------------------------------------------------------------------
--FATEWAIT: If (detect new aggro) Then (kill mob)
---------------------------------------------------------------------------------------------
c_fatewait = inheritsFrom( ml_cause )
e_fatewait = inheritsFrom( ml_effect )
function c_fatewait:evaluate() 
    local myPos = Player.pos
    local gotoPos = mm.evacPoint
    return  gFatesOnly == "1" and gDoFates == "1" and TableSize(gotoPos) > 0 and 
            NavigationManager:IsOnMesh(gotoPos.x, gotoPos.y, gotoPos.z) and
            Distance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z) > 15 -- ? 
end
function e_fatewait:execute()
    local newTask = ffxiv_task_movetopos:Create()
	local newPos = NavigationManager:GetRandomPointOnCircle(mm.evacPoint.x,mm.evacPoint.y,mm.evacPoint.z,1,5)
	if (ValidTable(newPos)) then
		newTask.pos = {x = newPos.x, y = newPos.y, z = newPos.z}
	else
		newTask.pos = {x = mm.evacPoint.x, y = mm.evacPoint.y, z = mm.evacPoint.z}
	end
	
	newTask.remainMounted = true
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

---------------------------------------------------------------------------------------------
--FATEQUIT: If (completion % has not changed over timer) Then (temporarily blacklist)
---------------------------------------------------------------------------------------------
c_fatequit = inheritsFrom( ml_cause )
e_fatequit = inheritsFrom( ml_effect )
function c_fatequit:evaluate()
	if ( ml_task_hub:CurrentTask().fateid ~= nil and ml_task_hub:CurrentTask().fateid ~= 0 ) then
		local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
		if (fate ~= nil and TableSize(fate) > 0) then
            if (ml_task_hub:CurrentTask().fateCompletion ~= nil and ml_task_hub:CurrentTask().fateCompletion == fate.completion) then
                if (ml_task_hub:CurrentTask().fateTimer ~= nil and ml_task_hub:CurrentTask().fateTimer ~= 0) then
                    if (os.difftime(os.time(), ml_task_hub:CurrentTask().fateTimer) > tonumber(gFateBLTimer)) then
                        return true
                    end
                end
            elseif (ml_task_hub:CurrentTask().fateCompletion ~= nil and ml_task_hub:CurrentTask().fateTimer ~= nil) then
                ml_task_hub:CurrentTask().fateCompletion = fate.completion
                ml_task_hub:CurrentTask().fateTimer = os.time()
            end
        end
    end
    
    return false
end
function e_fatequit:execute()
    if ( ml_task_hub:CurrentTask().fateid ~= nil and ml_task_hub:CurrentTask().fateid ~= 0 ) then
        -- blacklist fate for 5 minutes and terminate task
        gFateBlacklist[ml_task_hub:CurrentTask().fateid] = 300
        ml_task_hub:CurrentTask():Terminate()
    end
end

---------------------------------------------------------------------------------------------
--BETTERFATESEARCH: If (fate with < distance than current target exists) Then (select new fate)
--Clears the current fate and adds a new one if it finds a better match along the route
---------------------------------------------------------------------------------------------
c_betterfatesearch = inheritsFrom( ml_cause )
e_betterfatesearch = inheritsFrom( ml_effect )
c_betterfatesearch.throttle = 1000
function c_betterfatesearch:evaluate()
    if (ml_task_hub:CurrentTask().name ~= "MOVETOPOS") then
        return false
    end
    
    local myPos = Player.pos
	local fateID = GetClosestFateID(myPos,true,true)
    if (fateID ~= ml_task_hub:ThisTask().fateid) then
        return true	
    end
    
    return false
end
function e_betterfatesearch:execute()
	ml_debug( "Closer fate found" )
    ml_task_hub:ThisTask():Terminate()
	d("CLOSER FATE CURRENT TASK "..tostring(ml_task_hub:CurrentTask().name) .." "..tostring(ml_task_hub:CurrentTask().completed))
end

-----------------------------------------------------------------------------------------------
--MOVETOFATE: If (current fate distance > fate.radius) Then (add movetofate task)
--Moves within range of fate specified by ml_task_hub.CurrentTask().fateid
---------------------------------------------------------------------------------------------
c_movetofate = inheritsFrom( ml_cause )
e_movetofate = inheritsFrom( ml_effect )
function c_movetofate:evaluate()
	if ( ml_task_hub:CurrentTask().fateid ~= nil and ml_task_hub:CurrentTask().fateid ~= 0 ) then
		local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
		if (fate ~= nil and TableSize(fate) > 0) then
			local myPos = Player.pos
			local distance = Distance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z)
			if ( ml_task_hub:CurrentTask().moving) then
				if (distance > fate.radius/2) then				
					return true
				end
			else
				if (distance > fate.radius) then				
					return true
				end
			end
		end
	end
    
    return false
end
function e_movetofate:execute()
	local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
	if (ValidTable(fate)) then
    	ml_debug( "Moving to location of fate: "..fate.name )
		local newTask = ffxiv_task_movetopos:Create()
		--TODO: Randomize position
		newTask.pos = {x = fate.x, y = fate.y, z = fate.z}
		if ( ml_task_hub:CurrentTask().moving) then
			newTask.range = math.random(5, fate.radius/2)
		else
			newTask.range = math.random(fate.radius * .9, fate.radius)
		end
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	end
end

c_atfate = inheritsFrom( ml_cause )
e_atfate = inheritsFrom( ml_effect )
function c_atfate:evaluate()
	if (ml_task_hub:CurrentTask().name == "MOVETOPOS" and ml_task_hub:ThisTask().subtask == ml_task_hub:CurrentTask()) then
		if ( ml_task_hub:ThisTask().fateid ~= nil and ml_task_hub:ThisTask().fateid ~= 0 ) then
			local fate = GetFateByID(ml_task_hub:ThisTask().fateid)
			if (ValidTable(fate)) then
                -- check for fate targets within combat range and stop if we find one instead of running into fate
                local el = EntityList("nearest,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",fateid="..tostring(fate.id))
                if ( el ) then
                    local i,e = next(el)
                    if (i~=nil and e~=nil) then
                        return fate.completion > tonumber(gFateWaitPercent) and ValidTable(e)
                    end
                end	
			end
		end
	end
	return false
end
function e_atfate:execute()
	Player:Stop()
    -- call the complete logic so that bot will dismount
    ml_task_hub:CurrentTask():task_complete_execute()
	ml_task_hub:CurrentTask():Terminate()
end

---------------------------------------------------------------------------------------------
--SyncFateLevel
---------------------------------------------------------------------------------------------
c_syncfatelevel = inheritsFrom( ml_cause )
e_syncfatelevel = inheritsFrom( ml_effect )
c_syncfatelevel.throttle = 1000
function c_syncfatelevel:evaluate()
    if (ml_task_hub:CurrentTask().name ~= "MOVETOPOS") then
        return false
    end    
    local myPos = Player.pos
	local fateID = GetClosestFateID(myPos,true,true)
    if (fateID == ml_task_hub:ThisTask().fateid) then
        local fate = GetFateByID(fateID)
		if ( fate and TableSize(fate)) then
			local plevel = Player.level
			if ( ( fate.level > plevel +5 or fate.level < plevel -5) and Player:GetSyncLevel() == 0 )then
				local distance = Distance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z)
				if (distance < fate.radius) then				
					return true
				end
			end
		end
    end
    return false
end
function e_syncfatelevel:execute()
	ml_debug( "Curren Sync Fatelevel: "..tostring(Player:GetSyncLevel() ))
	ml_debug( "Syncing Fatelevel Result: "..tostring(Player:SyncLevel()))    
end

c_movingfate = inheritsFrom( ml_cause )
e_movingfate = inheritsFrom( ml_effect )
c_movingfate.throttle = 1000
function c_movingfate:evaluate()
	if ( ml_task_hub:CurrentTask().moving) then
		return false
	end
	
	if ( ml_task_hub:CurrentTask().fateid ~= nil and ml_task_hub:CurrentTask().fateid ~= 0 ) then
		local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
		if (ValidTable(fate)) then
			local fatePos = {x = fate.x, y = fate.y, z = fate.z}
			if ( TableSize(ml_task_hub:CurrentTask().fatePos) == 0 ) then
				ml_task_hub:CurrentTask().fatePos = fatePos
				return false
			else
				local oldFatePos = ml_task_hub:CurrentTask().fatePos
				local distance = Distance3D(oldFatePos.x, oldFatePos.y, oldFatePos.z, fatePos.x, fatePos.y, fatePos.z)
				if (distance > 0) then
					return true
				end
			end
		end
	end
	
	return false
end
function e_movingfate:execute()
	ml_task_hub:CurrentTask().moving = true
end

function ffxiv_task_fate:Init()
    --init processoverwatch 
	local ke_betterFate = ml_element:create( "BetterFateSearch", c_betterfatesearch, e_betterfatesearch, 15 )
	self:add( ke_betterFate, self.overwatch_elements)
    		
	local ke_syncFate = ml_element:create( "SyncFateLevel", c_syncfatelevel, e_syncfatelevel, 10 )
	self:add( ke_syncFate, self.overwatch_elements)
	
    local ke_atFate = ml_element:create( "AtFate", c_atfate, e_atfate, 5 )
	self:add( ke_atFate, self.overwatch_elements)
	
    --init process
	local ke_movingFate = ml_element:create( "SetFateMovingFlag", c_movingfate, e_movingfate, 30 )
	self:add( ke_movingFate, self.process_elements)
	
    local ke_quitFate = ml_element:create( "QuitFate", c_fatequit, e_fatequit, 25 )
    self:add( ke_quitFate, self.process_elements)
    
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 20 )
	self:add( ke_rest, self.process_elements)
		
    local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_killtarget, e_add_killtarget, 15 )
	self:add(ke_addKillTarget, self.process_elements)
    
	local ke_moveToFate = ml_element:create( "MoveToFate", c_movetofate, e_movetofate, 5 )
	self:add( ke_moveToFate, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_fate:task_complete_eval()
    local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
	if (fate ~= nil and TableSize(fate) > 0) then
		return fate.completion > 99
    elseif (fate == nil) then
		return true
	end
	
    return false
end

function ffxiv_task_fate:task_complete_execute()
    self.completed = true
end

function ffxiv_task_fate:task_fail_eval()

end

function ffxiv_task_fate:task_fail_execute()
    self.valid = false
end

function ffxiv_task_fate:OnSleep()

end

function ffxiv_task_fate:OnTerminate()

end

function ffxiv_task_fate:IsGoodToAbort()

end
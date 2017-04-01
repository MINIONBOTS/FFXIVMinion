---------------------------------------------------------------------------------------------
--TASK_FATE: Longterm Goal - Complete a fate event successfully
---------------------------------------------------------------------------------------------
ffxiv_task_fate = inheritsFrom(ml_task)
function ffxiv_task_fate.Create()
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
	newinst.targetid = 0
    newinst.targetFunction = GetNearestFateAttackable
	newinst.killFunction = ffxiv_task_grindCombat
	newinst.waitingForChain = false
	newinst.waitStart = 0
	newinst.nextFate = {}
	newinst.randomDelayCompleted = false
	newinst.specialDelay = 1000
	
    --newinst.fateTimer = 0
	newinst.fateMap = Player.localmapid
    newinst.fateCompletion = 0
    newinst.started = false
    newinst.moving = false
    newinst.fatePos = {}
	ffxiv_task_grind.inFate = false
	
	table.insert(tasktracking, newinst)
    
    return newinst
end

---------------------------------------------------------------------------------------------
--FATEWAIT: If (detect new aggro) Then (kill mob)
---------------------------------------------------------------------------------------------

c_fatewait = inheritsFrom( ml_cause )
e_fatewait = inheritsFrom( ml_effect )
e_fatewait.pos = nil
function c_fatewait:evaluate()
	if (MIsLoading() or MIsCasting()) then
		return false
	end
	
	e_fatewait.pos = nil
	
    local myPos = Player.pos
    local evacPoint = GetNearestEvacPoint()
	if (table.valid(evacPoint)) then
		local gotoPos = evacPoint.pos
		if (gFateWaitNearEvac and gGrindFatesOnly and gGrindDoFates and math.distance2d(myPos, gotoPos) > 15) then
			e_fatewait.pos = gotoPos
			return true
		end
	end
	return false
end
function e_fatewait:execute()
	d("Moving to evac point to wait for next FATE.")
	d("CurrentTask():"..tostring(ml_task_hub:CurrentTask().name))
	
    local newTask = ffxiv_task_movetopos.Create()
	newTask.destination = "FATE_WAIT"
    local evacPos = e_fatewait.pos
    local newPos = NavigationManager:GetRandomPointOnCircle(evacPos.x,evacPos.y,evacPos.z,1,5)
    if (table.valid(newPos)) then
        newTask.pos = {x = newPos.x, y = newPos.y, z = newPos.z}
    else
        newTask.pos = {x = evacPos.x, y = evacPos.y, z = evacPos.z}
    end
    
    newTask.remainMounted = true
	newTask.task_fail_eval = function ()
		return c_add_fate:evaluate()
	end
	newTask.task_fail_execute = function ()
		Player:Stop()
		newTask.valid = false
	end

    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

---------------------------------------------------------------------------------------------
--BETTERFATESEARCH: If (fate with < distance than current target exists) Then (select new fate)
--Clears the current fate and adds a new one if it finds a better match along the route
---------------------------------------------------------------------------------------------
c_betterfatesearch = inheritsFrom( ml_cause )
e_betterfatesearch = inheritsFrom( ml_effect )
c_betterfatesearch.timer = 0
e_betterfatesearch.fateid = 0
function c_betterfatesearch:evaluate()
    if (TimeSince(c_betterfatesearch.timer) < 10000 or ml_task_hub:ThisTask().waitingForChain or Player.incombat) then
        return false
    end
	
	c_betterfatesearch.timer = Now()
	
	local thisFate = MGetFateByID(ml_task_hub:ThisTask().fateid)
	if (table.valid(thisFate)) then
		local fatePos = {x = thisFate.x,y = thisFate.y,z = thisFate.z}
		local myPos = Player.pos
		local dist2d = Distance2D(myPos.x,myPos.z,fatePos.x,fatePos.z)
		
		if (ffxiv_task_fate.IsChain(Player.localmapid,thisFate.id) or ffxiv_task_fate.IsHighPriority(Player.localmapid,thisFate.id)) then
			return false
		end
		
		local closestFate = GetClosestFate(myPos)
		if (table.valid(closestFate) and thisFate.id ~= closestFate.id) then
			if (closestFate.status == 2) then
				if (ffxiv_task_fate.IsChain(Player.localmapid,closestFate.id) or 
					ffxiv_task_fate.IsHighPriority(Player.localmapid,closestFate.id)) 
				then
					e_betterfatesearch.fateid = closestFate.id
					return true	
				else
					local newdist2d = Distance2D(myPos.x,myPos.z,closestFate.x,closestFate.z)
					if ((newdist2d < closestFate.radius + 20) and (newdist2d < dist2d)) then
						e_betterfatesearch.fateid = closestFate.id
						return true	
					end
				end
			end
		end
	end
   
    return false
end
function e_betterfatesearch:execute()
	d("Found a better fate ["..tostring(e_betterfatesearch.fateid).."], switching away from ["..tostring(ml_task_hub:ThisTask().fateid).."].")
	Player:Stop()
    ml_task_hub:ThisTask().fateid = e_betterfatesearch.fateid
end

c_teletofate = inheritsFrom( ml_cause )
e_teletofate = inheritsFrom( ml_effect )
c_teletofate.radius = nil
c_teletofate.pos = nil
c_teletofate.lastTele = 0
function c_teletofate:evaluate()
	if (not gTeleportHack or 
		Now() < c_teletofate.lastTele or 
		ml_task_hub:ThisTask().name ~= "LT_FATE" or 
		not ml_task_hub:ThisTask().randomDelayCompleted) 
	then
		return false
	end	
	
    if ( ml_task_hub:ThisTask().fateid ~= nil and ml_task_hub:ThisTask().fateid ~= 0 ) then
        local fate = MGetFateByID(ml_task_hub:ThisTask().fateid)
        if (table.valid(fate)) then
		
			local percent = tonumber(gFateTeleportPercent)
			if (gTeleportHack and percent == 0) then
				--use a default completion percentage to enable fate teleport to match checkbox
				percent = 5
			end
			
			if fate.completion > percent then
				local myPos = Player.pos
				local fatePos = {x = fate.x, y = fate.y, z = fate.z}
				
				if (gTeleportHackParanoid ) then
					local scanDistance = 50
					local players = EntityList("type=1,maxdistance=".. scanDistance)
					local nearbyPlayers = TableSize(players)
					if nearbyPlayers > 0 then
						return false
					end
					
					local players = EntityList("type=1")
					if (players) then
						for i,entity in pairs(players) do
							local epos = entity.pos
							if (Distance3D(epos.x,epos.y,epos.z,fatePos.x,fatePos.y,fatePos.z) <= 50) then
								return false
							end
						end
					end
				end
	
				local dest = NavigationManager:GetClosestPointOnMesh(fatePos,false)
				if (dest and dest.distance ~= 0 and dest.distance < 10) then
					if Distance2D(myPos.x,myPos.z,dest.x,dest.z) > (fate.radius * 2) then
						c_teletofate.radius = fate.radius
						c_teletofate.pos = dest
						return true
					end
				end
			end
        end
    end
    
    return false
end
function e_teletofate:execute()
	local dest = c_teletofate.pos
	local newPos = NavigationManager:GetRandomPointOnCircle(dest.x,dest.y,dest.z,c_teletofate.radius,(c_teletofate.radius + 15))
	local newdest = NavigationManager:GetClosestPointOnMesh(newPos,false)
	
	Player:Stop()
	if (newdest) then
		Hacks:TeleportToXYZ(newdest.x,newdest.y,newdest.z)
	end
	c_teletofate.lastTele = Now() + 10000
	ffxiv_task_grind.inFate = true
end

c_movetochainlocation = inheritsFrom( ml_cause )
e_movetochainlocation = inheritsFrom( ml_effect )
function c_movetochainlocation:evaluate()
	if ( ml_task_hub:CurrentTask().fateid ~= nil and 
		ml_task_hub:CurrentTask().fateid ~= 0 and 
		ml_task_hub:CurrentTask().waitingForChain and 
		table.valid(ml_task_hub:CurrentTask().nextFate)) 
	then
        local fate = ml_task_hub:CurrentTask().nextFate
		local myPos = Player.pos
		local distance = PDistance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z)
		if (distance > 5) then				
			return true
		end
	end
    
    return false
end
function e_movetochainlocation:execute()
    local fate = ml_task_hub:CurrentTask().nextFate
    if (table.valid(fate)) then
		d("Moving into position for next fate in chain.")
        local newTask = ffxiv_task_movetopos.Create()
		local fatePos = {x = fate.x, y = fate.y, z = fate.z}
        newTask.pos = fatePos
		newTask.remainMounted = true
		
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

c_movewithfate = inheritsFrom( ml_cause )
e_movewithfate = inheritsFrom( ml_effect )
function c_movewithfate:evaluate()
	if ( ml_task_hub:CurrentTask().fateid ~= nil and ml_task_hub:CurrentTask().fateid ~= 0 ) then
	
		local fate = MGetFateByID(ml_task_hub:CurrentTask().fateid)
		if (table.valid(fate)) then
			if (fate.status == 2) then
				local currentFatePos = ml_task_hub:CurrentTask().fatePos
				local newFatePos = {x = fate.x, y = fate.y, z = fate.z}
			
				local tablesEqual = true
				if (table.valid(fate)) then
					if (not table.valid(currentFatePos)) then
						currentFatePos = shallowcopy(newFatePos)
						return false
					elseif (table.valid(currentFatePos) and not Player.incombat) then
						if (not deepcompare(currentFatePos,newFatePos,true)) then
							currentFatePos = shallowcopy(newFatePos)
							return true
						end
					end
				end
			end
		end
	end
    
    return false
end
function e_movewithfate:execute()
    local fate = MGetFateByID(ml_task_hub:CurrentTask().fateid)
    if (table.valid(fate)) then
        local newTask = ffxiv_task_movetofate.Create()
		local fatePos = ml_task_hub:CurrentTask().fatePos
		newTask.fateid = ml_task_hub:CurrentTask().fateid
        newTask.pos = fatePos
		newTask.actualPos = fatePos
		
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

c_movetofatemap = inheritsFrom( ml_cause )
e_movetofatemap = inheritsFrom( ml_effect )
function c_movetofatemap:evaluate()
	if (MIsCasting(true) or (MIsLocked() and not IsFlying()) or MIsLoading()) then
		return false
	end
	
	local mapID = IsNull(ml_task_hub:CurrentTask().fateMap,0)
	if (mapID < 0 and Player.localmapid ~= mapID) then
		e_movetofatemap.mapID = mapID
		return true
	end
	
	return false
end
function e_movetofatemap:execute()
	local newTask = ffxiv_task_movetomap.Create()
	newTask.destMapID = e_movetofatemap.mapID
	newTask.pos = ml_task_hub:CurrentTask().fatePos
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

-----------------------------------------------------------------------------------------------
--MOVETOFATE: If (current fate distance > fate.radius) Then (add movetofate task)
--Moves within range of fate specified by ml_task_hub:CurrentTask().fateid
---------------------------------------------------------------------------------------------
c_movetofate = inheritsFrom( ml_cause )
e_movetofate = inheritsFrom( ml_effect )
function c_movetofate:evaluate()
    if ( ml_task_hub:CurrentTask().fateid ~= nil and ml_task_hub:CurrentTask().fateid ~= 0 ) then
        local fate = MGetFateByID(ml_task_hub:CurrentTask().fateid)
		
        if (table.valid(fate)) then
			if (fate.status == 2) then
				local myPos = Player.pos
				local distance = PDistance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z)
				if (distance > fate.radius) then				
					return true
				end
			end
        end
    end
    
    return false
end
function e_movetofate:execute()
    local fate = MGetFateByID(ml_task_hub:CurrentTask().fateid)
    if (table.valid(fate)) then
        local newTask = ffxiv_task_movetofate.Create()
		local fatePos = {x = fate.x, y = fate.y, z = fate.z}
		newTask.fateid = ml_task_hub:CurrentTask().fateid
		newTask.allowRandomization = false
        newTask.pos = fatePos
		newTask.actualPos = fatePos
		
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

---------------------------------------------------------------------------------------------
--SyncFateLevel
---------------------------------------------------------------------------------------------
c_syncfatelevel = inheritsFrom( ml_cause )
e_syncfatelevel = inheritsFrom( ml_effect )
function c_syncfatelevel:evaluate()
    if (Player:GetSyncLevel() ~= 0 or Now() < ml_global_information.syncTimer) then
        return false
    end
	
    local myPos = Player.pos
	local fateID = ml_task_hub:ThisTask().fateid
	local fate = MGetFateByID(fateID)
	if ( table.valid(fate)) then
		if (fate.maxlevel < Player.level) then
		--if (AceLib.API.Fate.RequiresSync(fate.id)) then
			local distance = Distance2D(myPos.x, myPos.z, fate.x, fate.z)
			if (distance <= fate.radius) then				
				return true
			end
		end
	end
    return false
end
function e_syncfatelevel:execute()
    ml_debug( "Current Sync Fate level: "..tostring(Player:GetSyncLevel() ))
    ml_debug( "Syncing Fate level Result: "..tostring(Player:SyncLevel()))
	ml_task_hub:ThisTask().preserveSubtasks = true
	ml_global_information.syncTimer = Now() + 1000
end

c_updatefate = inheritsFrom( ml_cause )
e_updatefate = inheritsFrom( ml_effect )
function c_updatefate:evaluate()
	local fate = MGetFateByID(ml_task_hub:ThisTask().fateid)
	local fatePos = ml_task_hub:ThisTask().fatePos
	
	local tablesEqual = true
	if (table.valid(fate)) then
		local nearestFateTarget = GetNearestFateAttackable()
		if (fate.status == 2 or table.valid(nearestFateTarget)) then
			if (not fatePos) then
				fatePos = {x = fate.x, y = fate.y, z = fate.z}
			elseif (table.valid(fatePos)) then
				if not deepcompare(fate,fateDetails,true) then
					fateDetails = shallowcopy(fate)
				end
			end
			
			if (ml_task_hub:ThisTask().waitingForChain) then 
				ml_task_hub:ThisTask().waitingForChain = false 
				d("Removing FATE wait flag.")
			end
			if (table.valid(ml_task_hub:ThisTask().nextFate)) then 
				ml_task_hub:ThisTask().nextFate = {} 
				ml_debug("Clearing next FATE.")
			end
		end
	end
	
	return false
end
function e_updatefate:execute()
	ml_debug("Updated FATE details.")
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_resettarget = inheritsFrom( ml_cause )
e_resettarget = inheritsFrom( ml_effect )
function c_resettarget:evaluate()
	local subtask = ml_task_hub:ThisTask().subtask
	local fate = MGetFateByID(ml_task_hub:ThisTask().fateid)
	
	if (table.valid(fate)) then
		if (subtask and subtask.name == "GRIND_COMBAT" and subtask.targetid and subtask.targetid > 0) then
			if (Player:GetSyncLevel() ~= 0) then
				local target = EntityList:Get(subtask.targetid)
				if (table.valid(target)) then
					if (target.fateid == fate.id) then
						local epos = shallowcopy(target.pos)
						local dist = Distance2D(epos.x,epos.z,fate.x,fate.z)
						if (dist > fate.radius) then
							return true
						end
					end
				end
			end
		end
	end
    
    return false
end
function e_resettarget:execute()
	ml_debug("Dropping target outside FATE radius.")
end

c_faterandomdelay = inheritsFrom( ml_cause )
e_faterandomdelay = inheritsFrom( ml_effect )
function c_faterandomdelay:evaluate()
	local fate = MGetFateByID(ml_task_hub:ThisTask().fateid)
	
	if (table.valid(fate) and not ml_task_hub:ThisTask().randomDelayCompleted) then
		local myPos = Player.pos
		local dist = Distance2D(myPos.x,myPos.z,fate.x,fate.z)
		
		if (fate.completion == 0 and dist > (fate.radius + 20)) then
			return true
		else
			ml_task_hub:ThisTask().randomDelayCompleted = true
		end
	end
    
    return false
end
function e_faterandomdelay:execute()
	local minWait = tonumber(gFateRandomDelayMin) * 1000
	local maxWait = tonumber(gFateRandomDelayMax) * 1000
	
	ml_global_information.Await(math.random(minWait,maxWait))
	ml_task_hub:ThisTask().randomDelayCompleted = true
	ml_debug("Random delay commenced.")
end

c_add_fatetarget = inheritsFrom( ml_cause )
e_add_fatetarget = inheritsFrom( ml_effect )
c_add_fatetarget.oocCastTimer = 0
c_add_fatetarget.throttle = 500
function c_add_fatetarget:evaluate()
	if (not Player.incombat) then
		if (SkillMgr.Cast( Player, true)) then
			c_add_fatetarget.oocCastTimer = Now() + 1500
			return false
		end
		
		if (MIsCasting() or Now() < c_add_fatetarget.oocCastTimer) then
			return false
		end
	end
	
	local fate = MGetFateByID(ml_task_hub:CurrentTask().fateid)
	if (table.valid(fate)) then
		if (fate.status == 2) then
			--d("status:"..tostring(fate.status))
			--d("completion:"..tostring(fate.completion))
			--d("name:"..tostring(fate.name))
			
			local myPos = Player.pos
			local fatePos = {x = fate.x, y = fate.y, z = fate.z}
			
			local dist = PDistance3D(myPos.x,myPos.y,myPos.z,fatePos.x,fatePos.y,fatePos.z)
			if (not AceLib.API.Fate.RequiresSync(fate.id) or dist < fate.radius) then
				local target = GetNearestFateAttackable()
				if (table.valid(target)) then
					if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0) then
						c_add_fatetarget.targetid = target.id
						return true
					end
				else
					d("no nearest fate attackable")
				end
			end
		end
	end
    
    return false
end
function e_add_fatetarget:execute()
	d("Adding a new fate target.")
	local newTask = ffxiv_task_grindCombat.Create()
	newTask.betterTargetFunction = GetNearestFateAttackable
	newTask.targetid = c_add_fatetarget.targetid
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

function ffxiv_task_fate:Init()
    --init processoverwatch 
	local ke_fateEnd = ml_element:create( "FateEnd", c_endfate, e_endfate, 100)
    self:add( ke_fateEnd, self.overwatch_elements)
	
	local ke_updateFate = ml_element:create( "UpdateFateDetails", c_updatefate, e_updatefate, 90 )
    self:add( ke_updateFate, self.overwatch_elements)
	
	local ke_teleToFate = ml_element:create( "TeleportToFate", c_teletofate, e_teletofate, 70 )
    self:add( ke_teleToFate, self.overwatch_elements)
	
    local ke_betterFate = ml_element:create( "BetterFateSearch", c_betterfatesearch, e_betterfatesearch, 60 )
    self:add( ke_betterFate, self.overwatch_elements)
            
    local ke_syncFate = ml_element:create( "SyncFateLevel", c_syncfatelevel, e_syncfatelevel, 50 )
    self:add( ke_syncFate, self.overwatch_elements)
	
	--local ke_resetTarget = ml_element:create( "ResetTarget", c_resettarget, e_resettarget, 3 )
	--self:add( ke_resetTarget, self.overwatch_elements)
    
    --init process
	local ke_moveToFateMap = ml_element:create( "MoveToFateMap", c_movetofatemap, e_movetofatemap, 100 )
    self:add( ke_moveToFateMap, self.process_elements)
	
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 90 )
    self:add( ke_rest, self.process_elements)
	
	local ke_fateRandomDelay = ml_element:create( "RandomFateDelay", c_faterandomdelay, e_faterandomdelay, 80 )
    self:add( ke_fateRandomDelay, self.process_elements)
        
    local ke_addKillTarget = ml_element:create( "AddFateTarget", c_add_fatetarget, e_add_fatetarget, 60 )
    self:add(ke_addKillTarget, self.process_elements)
    
	local ke_moveToFate = ml_element:create( "MoveToFate", c_movetofate, e_movetofate, 50 )
    self:add( ke_moveToFate, self.process_elements)
	
    local ke_moveWithFate = ml_element:create( "MoveWithFate", c_movewithfate, e_movewithfate, 45 )
    self:add( ke_moveWithFate, self.process_elements)
	
	local ke_moveChainFate = ml_element:create( "MoveChainFate", c_movetochainlocation, e_movetochainlocation, 40 )
    self:add( ke_moveChainFate, self.process_elements)
end

c_endfate = inheritsFrom( ml_cause )
e_endfate = inheritsFrom( ml_effect )
function c_endfate:evaluate()
	if (ml_task_hub:ThisTask().waitingForChain and 
		(ml_task_hub:ThisTask().waitStart == 0 or TimeSince(ml_task_hub:ThisTask().waitStart) < 45000)) 
	then
		return false
	end
	
	if (Player.localmapid ~= ml_task_hub:ThisTask().fateMap) then
		return false
	end
	
    local fate = MGetFateByID(ml_task_hub:ThisTask().fateid)
    if (not table.valid(fate)) then
		d("Ending fate, fate no longer exists.")
        return true
	elseif (fate and (fate.completion > 99)) then
		d("Ending fate, fate completion:"..tostring(fate.completion))
		return true
	elseif (fate.status ~= 2) then
		local foundTargetable = false
		local el = EntityList("fateid="..tostring(fate.id))
		if (table.valid(el)) then
			for i,e in pairs(el) do
				if (e.targetable) then
					foundTargetable = true
				end
				if (foundTargetable) then
					break
				end
			end
		end        
		
		if (not foundTargetable) then
			return true
		end
	else
		local minFateLevel = tonumber(gGrindFatesMinLevel) or 0
		local maxFateLevel = tonumber(gGrindFatesMaxLevel) or 0
		
		if ((minFateLevel ~= 0 and not gGrindFatesNoMinLevel and (fate.level < (Player.level - minFateLevel))) or 
			(maxFateLevel ~= 0 and not gGrindFatesNoMaxLevel and (fate.level > (Player.level + maxFateLevel))))
		then
			return true
		end
    end
	
	--if (not IsFateApproved(fate.id)) then
		--d("FATE "..tostring(fate.id).." no longer meets its approval requirements, task ending.")
		--return true
	--end
    
    return false
end
function e_endfate:execute()
	local isChain, isFirst, isLast, nextFate = ffxiv_task_fate.IsChain(Player.localmapid,ml_task_hub:ThisTask().fateid)
	if (isChain and not isLast and table.valid(nextFate)) then
		d("Setting FATE to wait for next part of the chain.")
		Player:Stop()
		ml_task_hub:ThisTask().fateid = nextFate.id
		ml_task_hub:ThisTask().waitingForChain = true
		ml_task_hub:ThisTask().waitStart = Now()
		ml_task_hub:ThisTask().nextFate = nextFate
		ml_task_hub:ThisTask().specialDelay = nextFate.specialDelay
	else
		d("Setting FATE to end completely.")
		ffxiv_task_grind.inFate = false
		Player:Stop()
		ml_task_hub:ThisTask().completed = true
		ml_task_hub:ThisTask():DeleteSubTasks()
		ml_global_information.Await(1000)
		ml_global_information.suppressRestTimer = Now() + 10000
	end
end

function ffxiv_task_fate.IsHighPriority(mapid, fateid)
	local mapid = tonumber(mapid) or 0
	local fateid = tonumber(fateid) or 0
	
	local highPriority = {
		[147] = "643,644,645,646",
		[155] = "501,502,503,504",
	}
	
	local mapPriority = highPriority[mapid]
	if (mapPriority) then
		return MultiComp(fateid,mapPriority)
	end
	
	return false
end

function ffxiv_task_fate.IsChain(mapid, fateid)
	local mapid = tonumber(mapid) or 0
	local fateid = tonumber(fateid) or 0
	
	--d("Checking to see if fateid:"..tostring(fateid).." is a chain for mapid:"..tostring(mapid))
	
	local chains = {
		[155] = {
			[1] = {
				{ id = 501, x = 278.2, y = 338.7, z = -505.9 },
				{ id = 502, x = 266.5, y = 360.7, z = -624.6 },
				--{ id = 504, x = 260.5, y = 360.3, z = -624.3 },
				--{ id = 503, x = 225.5, y = 356.1, z = -656.7 },
			},
		},
		[147] = {
			[1] = {
				{ id = 643, x = 255.6, y = 25, z = 45.5 },
				{ id = 644, x = 255.6, y = 25, z = 10 },
				{ id = 645, x = 255.6, y = 25, z = 10 },
				{ id = 646, x = 255.6, y = 25, z = 10 },
			},
		},
		[400] = {
			[1] = {
				{ id = 868, x = -214.5, y = 138.5, z = -644.5 },
				{ id = 869, x = -214.5, y = 138.5, z = -644.5 },
				{ id = 870, x = -214.5, y = 138.5, z = -644.5 },
			},
		},
		[397] = {
			[1] = {
				{ id = 791, x = 391.9, y = 162.4, z = -163.65 },
				{ id = 792, x = 412.26, y = 159.88, z = -94.812 },
			},
		},
	}
	
	local mapChains = chains[mapid]
	if (mapChains) then
		for chainid,chaindata in pairs(mapChains) do
			for order,fatedata in pairs(chaindata) do
				if (fatedata.id == fateid) then
					local firstChain = (order == 1)
					local lastChain = (order == TableSize(chaindata))
					local nextFate = nil
					
					if (not lastChain) then
						if (chaindata[order+1]) then
							nextFate = chaindata[order+1]
						end
					end
					
					ml_debug("IsChain:"..tostring(firstChain)..","..tostring(lastChain)..tostring(nextFate))
					return true, firstChain, lastChain, nextFate
				end
			end
		end
	end
	
	return false, nil, nil, nil
end
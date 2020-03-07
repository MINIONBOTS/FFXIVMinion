---------------------------------------------------------------------------------------------
--TASK_FATE: Longterm Goal - Complete a fate event successfully
---------------------------------------------------------------------------------------------
ffxiv_task_fate = inheritsFrom(ml_task)
ffxiv_task_fate.addon_process_elements = {}
ffxiv_task_fate.addon_overwatch_elements = {}

ffxiv_task_fate.tracking = {
	measurementDelay = 0,
}
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
		if (ml_navigation:CheckPath(gotoPos)) then
			if (gFateWaitNearEvac and gGrindFatesOnly and gGrindDoFates and math.distance2d(myPos, gotoPos) > 10) then
				e_fatewait.pos = gotoPos
				return true
			end
			if ((gGrindFatesOnly) and Player.level <= 10) then
				--d("Player to low to Fate fate grind only")
				return false
			end
		else
			--d("[FateWait]: Evac point @ ["..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z).."] was not reachable.")
		end
	end
	return false
end
function e_fatewait:execute()
	--d("Moving to evac point to wait for next FATE.")
	
    local newTask = ffxiv_task_movetopos.Create()
	newTask.destination = "FATE_WAIT"
    local evacPos = e_fatewait.pos
    local newPos = NavigationManager:GetRandomPointOnCircle(evacPos.x,evacPos.y,evacPos.z,1,8)
    if (table.valid(newPos) and ml_navigation:CheckPath(newPos) and math.distance2d(Player.pos, newPos) > 10) then
        newTask.pos = {x = newPos.x, y = newPos.y, z = newPos.z}
    else
        newTask.pos = {x = evacPos.x, y = evacPos.y, z = evacPos.z}
    end
    
	newTask.range = 5
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
		local fatePos = {x = thisFate.x, y = thisFate.y,z = thisFate.z}
		local myPos = Player.pos
		local dist2d = Distance2D(myPos.x,myPos.z,fatePos.x,fatePos.z)
		
		if (ffxiv_task_fate.IsChain(Player.localmapid,thisFate.id) or ffxiv_task_fate.IsHighPriority(Player.localmapid,thisFate.id)) then
			return false
		end
		
		local closestFate = GetClosestFate(myPos)
		if (table.valid(closestFate) and thisFate.id ~= closestFate.id) then
			local activatable = (table.valid(ffxiv_task_fate.Activateable(Player.localmapid, closestFate.id)))
			if (closestFate.status == 2) or ((closestFate.status == 7) and activatable) then
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
				
				if (gTeleportHackParanoid) then
					local scanDistance = gTeleportHackParanoidDistance
					local players = EntityList("type=1,maxdistance=".. scanDistance)
					local nearbyPlayers = TableSize(players)
					if nearbyPlayers > 0 then
						return false
					end
					
					local players = EntityList("type=1")
					if (players) then
						for i,entity in pairs(players) do
							local epos = entity.pos
							if (Distance3D(epos.x,epos.y,epos.z,fatePos.x,fatePos.y,fatePos.z) <= scanDistance) then
								return false
							end
						end
					end
				end
	
				local dest = FindClosestMesh(fatePos,15,false)
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
	local newdest = FindClosestMesh(newPos,15,false)
	
	Player:Stop()
	if (newdest) then
		Hacks:TeleportToXYZ(newdest.x,newdest.y,newdest.z,true)
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
	if (MIsCasting(true) or CannotMove() or MIsLoading()) then
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
			local activatable = (table.valid(ffxiv_task_fate.Activateable(Player.localmapid, fate.id)))
			if (fate.status == 2) or ((fate.status == 7) and activatable) then
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
    if (Now() < ml_global_information.syncTimer) then
        return false
    end
	
	if (not IsEurekaMap(Player.localmapid) and Player:GetSyncLevel() ~= 0) then
		return false
	end
	
    local myPos = Player.pos
	local fateID = ml_task_hub:ThisTask().fateid
	local fate = MGetFateByID(fateID)
	if ( table.valid(fate)) then
		if ((not IsEurekaMap(Player.localmapid) and fate.maxlevel < Player.level) or (IsEurekaMap(Player.localmapid) and fate.maxlevel < Player.eurekainfo.level)) then
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
			d("[FateRandomDelay]: Delay does not apply, completion is too high.")
			ml_task_hub:ThisTask().randomDelayCompleted = true
		end
	end
    
    return false
end
function e_faterandomdelay:execute()
	local minWait = 1 * 1000
	local maxWait = 5 * 1000
	
	ml_global_information.Await(math.random(minWait,maxWait))
	ml_task_hub:ThisTask().randomDelayCompleted = true
end

--622, 1308  239.30, 11, 191.99, 6559


c_startfate = inheritsFrom( ml_cause )
e_startfate = inheritsFrom( ml_effect )
e_startfate.contentid = 0
e_startfate.npcpos = {}
e_startfate.fateid = 0
function c_startfate:evaluate()
	-- Reset tempvars.
	e_startfate.contentid = 0
	e_startfate.npcpos = {}
	e_startfate.fateid = 0
					
	local fateid = ml_task_hub:CurrentTask().fateid
	local fate = MGetFateByID(fateid)
	if (table.valid(fate)) then
		local mapid = Player.localmapid
		local activatable = ffxiv_task_fate.Activateable(mapid, fateid)
		if (activatable and fate.status == 7) then
			local npcid = activatable.id
			local fatenpc = MEntityList("targetable,type=3,chartype=5,contentid="..tostring(npcid))
			if (table.valid(fatenpc)) then
				local closest,closestDistance = nil,100
				for i,entity in pairs(fatenpc) do
					local dist = math.distance3d(entity.pos,activatable.pos)
					if (not closest or dist < closestDistance) then
						closest = entity
						closestDistance = dist
					end
				end
				if (closest) then
					e_startfate.interact = closest.id
					e_startfate.contentid = closest.contentid
					e_startfate.pos = closest.pos
					e_startfate.fateid = fateid
					return true
				end
			end
		end
	end
	
	return false
end

function e_startfate:execute()
   if (IsControlOpen("SelectYesno")) then
		PressYesNo(true)
		return
	end	
	
	local newTask = ffxiv_task_movetointeract.Create()
	newTask.interact = e_startfate.interact
	newTask.contentid = e_startfate.contentid
	newTask.pos = e_startfate.pos
	newTask.fateid =  e_startfate.fateid
	
	newTask.task_complete_eval = function (self)
		-- Dumbed this down to one helper, lots of conditions already, and I fear more to come, diving doesn't follow the usual rules.
		local fate = MGetFateByID(self.fateid)
		if (not fate or fate.status == 2 or Busy() or self.startMap ~= Player.localmapid) then
			return true
		end
		
		local myTarget = MGetTarget()
		local ppos = Player.pos
		
		local interactable = nil
		if (self.interact ~= 0) then
			interactable = EntityList:Get(self.interact)
		end
		
		local dist2d,dist3d = math.distance2d(ppos,self.pos),math.distance3d(ppos,self.pos)
		if (self.interact ~= 0 and dist2d < 50 and dist2d < fate.radius and dist3d < fate.radius) then
			if (not interactable or not interactable.targetable) then
				return true
			end
		else
			if (dist2d <= 5) then
				local interacts = EntityList("targetable,contentid="..tostring(self.contentid)..",maxdistance=10")
				if (not table.valid(interacts)) then
					return true
				end
			end			
		end
		
		return false
	end
		
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_turninItem = inheritsFrom( ml_cause )
e_turninItem = inheritsFrom( ml_effect )
e_turninItem.contentid = 0
e_turninItem.npcpos = {}
function c_turninItem:evaluate()
	if (Player.incombat) then
		return false
	end
	
	-- Reset tempvars.
	e_turninItem.contentid = 0
	e_turninItem.npcpos = {}

	local fateid = ml_task_hub:ThisTask().fateid
	local fate = MGetFateByID(fateid)
	if (table.valid(fate)) then
		local gatherable = ffxiv_task_fate.Gatherable(Player.localmapid, fateid)
		if (gatherable and In(fate.status,2,8)) then
			local npcid = gatherable.id
			local fatenpc = MEntityList("targetable,type=3,chartype=5,contentid="..tostring(npcid))
			if (table.valid(fatenpc)) then
				local turninid = gatherable.turninid
				local currentcount = ItemCount(turninid,{2004})
				if ((currentcount >= gFateGatherTurnCount) or (currentcount >= 1 and (fate.status == 8 or fate.duration < 120))) then
					local npcpos = gatherable.pos
				
					e_turninItem.contentid = npcid
					e_turninItem.npcpos = npcpos
					return true
				end 
			end 
		end 
	end
	return false
end

function e_turninItem:execute()
	local newTask = ffxiv_task_movetointeract.Create()
	newTask.contentid = e_turninItem.contentid
	newTask.pos = e_turninItem.npcpos
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_handoveritem = inheritsFrom( ml_cause )
e_handoveritem = inheritsFrom( ml_effect )
function c_handoveritem:evaluate()
	if IsControlOpen("Request") then
		return true
	end
	return false
end
function e_handoveritem:execute()
	local inventories = {2004}
	for _,invid in pairs(inventories) do
		local bag = Inventory:Get(invid)
		if (table.valid(bag)) then
			local ilist = bag:GetList()
			if (table.valid(ilist)) then
				for slot, item in pairs(ilist) do 
					local result = item:HandOver()
					if (result and (result == 1 or result == true or result == 65536)) then
						ml_global_information.Await(math.random(800,1200))
						return
					end
				end	
			end
		end
	end
	
	if (UseControlAction("Request","HandOver",1)) then
		ml_global_information.Await(math.random(1200,2000))
	end
end

c_pickupItem = inheritsFrom( ml_cause )
e_pickupItem = inheritsFrom( ml_effect )
e_pickupItem.contentid = 0
e_pickupItem.itempos = {}
function c_pickupItem:evaluate()
	-- Tempvars reset.
	e_pickupItem.contentid = 0
	e_pickupItem.itempos = {}

	local fateid = ml_task_hub:CurrentTask().fateid
	local fate = MGetFateByID(fateid)
    if (table.valid(fate) and fate.status == 2) then
	
		if IsInsideFate() and not Player.incombat then
				
			local nearest,nearestDistance = nil,0
			local el = MEntityList("alive,attackable,onmesh")
			local myPos = Player.pos
			if (table.valid(el)) then
				for i,entity in pairs(el) do
					local efateid = entity.fateid
					if (efateid == fateid or efateid == 0) then
						local epos = entity.pos
						local fatedist = Distance2D(epos.x,epos.z,fate.x,fate.z)
						if (fatedist <= fate.radius) then
							local dist3d = Distance3D(epos.x,epos.y,epos.z,myPos.x,myPos.y,myPos.z)
							if (not nearest or dist3d < nearestDistance) then
								nearest, nearestDistance = entity, dist3d
							end
						end
					end
				end
			end	
			
			local fatenpc = EntityList("targetable,type=3,chartype=5")
			if (table.valid(fatenpc)) then
				for i,entity in pairs(fatenpc) do
					if entity.fateid == fateid then
						local gatherable = ffxiv_task_fate.Gatherable(Player.localmapid, fateid)
						if (gatherable) then
							local pickupitem = MEntityList("nearest,targetable,contentid="..tostring(gatherable.itemid))
							if (table.valid(pickupitem)) then
								for id,item in pairs(pickupitem) do
									local ipos = item.pos
									local dist3d = Distance3D(ipos.x,ipos.y,ipos.z,myPos.x,myPos.y,myPos.z)
									if (not nearest or dist3d < nearestDistance) then
										
										e_pickupItem.contentid = item.contentid
										e_pickupItem.itempos = ipos
										return true
									end
								end
							end
						end
					end
				end	
			end
		end	
	end
	return false
end		

function e_pickupItem:execute()
	local newTask = ffxiv_task_movetointeract.Create()
	newTask.contentid = e_pickupItem.contentid
	newTask.pos = e_pickupItem.itempos
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_add_fatetarget = inheritsFrom( ml_cause )
e_add_fatetarget = inheritsFrom( ml_effect )
c_add_fatetarget.oocCastTimer = 0
c_add_fatetarget.throttle = 500
function c_add_fatetarget:evaluate()
	if not Player.onmesh then
		return false
	end
	if (not Player.incombat) then
		if (SkillMgr.Cast(Player, true)) then
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
			if (Player.level <= fate.maxlevel or dist < fate.radius) then
				local target = GetNearestFateAttackable()
				if (table.valid(target)) then
					c_add_fatetarget.targetid = target.id
					return true
				else
					--d("no nearest fate attackable")
				end
			end
		end
	end
    
    return false
end
function e_add_fatetarget:execute()
	--d("Adding a new fate target.")
	local newTask = ffxiv_task_grindCombat.Create()
	newTask.betterTargetFunction = GetNearestFateAttackable
	newTask.targetid = c_add_fatetarget.targetid
	newTask.fateid = ml_task_hub:CurrentTask().fateid
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
	
	local ke_resetTarget = ml_element:create( "ResetTarget", c_resettarget, e_resettarget, 40 )
	self:add( ke_resetTarget, self.overwatch_elements)
    
    --init process
	local ke_moveToFateMap = ml_element:create( "MoveToFateMap", c_movetofatemap, e_movetofatemap, 100 )
    self:add( ke_moveToFateMap, self.process_elements)
	
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 90 )
    self:add( ke_rest, self.process_elements)
	
	local ke_fateRandomDelay = ml_element:create( "RandomFateDelay", c_faterandomdelay, e_faterandomdelay, 80 )
    self:add( ke_fateRandomDelay, self.process_elements)
        
    local ke_addKillTarget = ml_element:create( "AddFateTarget", c_add_fatetarget, e_add_fatetarget, 60 )
    self:add(ke_addKillTarget, self.process_elements)
    
	local ke_startFate = ml_element:create( "StartFate", c_startfate, e_startfate, 30 )
    self:add( ke_startFate, self.process_elements)
	
	local ke_turninItem = ml_element:create( "TurninItem", c_turninItem, e_turninItem, 100 )
    self:add( ke_turninItem, self.process_elements)
	
	local ke_pickupItem = ml_element:create( "PickupItem", c_pickupItem, e_pickupItem, 60 )
    self:add( ke_pickupItem, self.process_elements)
	
    local ke_handoveritem = ml_element:create( "HandoverItem", c_handoveritem, e_handoveritem, 90 )
    self:add( ke_handoveritem, self.overwatch_elements)
	
	local ke_moveToFate = ml_element:create( "MoveToFate", c_movetofate, e_movetofate, 50 )
    self:add( ke_moveToFate, self.process_elements)
	
    local ke_moveWithFate = ml_element:create( "MoveWithFate", c_movewithfate, e_movewithfate, 45 )
    self:add( ke_moveWithFate, self.process_elements)
	
	local ke_moveChainFate = ml_element:create( "MoveChainFate", c_movetochainlocation, e_movetochainlocation, 40 )
    self:add( ke_moveChainFate, self.process_elements)
	
	self:InitExtras()
end

function ffxiv_task_fate:InitExtras()
	local overwatch_elements = self.addon_overwatch_elements
	if (table.valid(overwatch_elements)) then
		for i,element in pairs(overwatch_elements) do
			self:add(element, self.overwatch_elements)
		end
	end
	
	local process_elements = self.addon_process_elements
	if (table.valid(process_elements)) then
		for i,element in pairs(process_elements) do
			self:add(element, self.process_elements)
		end
	end
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
	local gatherable = false
	local turninitem = 0
	local redeemable = false
    if (table.valid(fate)) then
		gatherable = ffxiv_task_fate.Gatherable(Player.localmapid, fate.id)
		if (gatherable) then
			redeemable = (ItemCount(gatherable.turninid,2004) >= 1)
		end
	end
	
    if (not table.valid(fate)) then
		--d("Ending fate, fate no longer exists.")
        return true
	elseif (not gatherable or not redeemable) and (fate and (fate.completion > 99)) then
		d("Ending fate, fate completion:"..tostring(fate.completion))
		return true
		
	elseif (fate.status ~= 2) and (fate.status ~= 7) then
		local foundTargetable = false
		local el = MEntityList("fateid="..tostring(fate.id))
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
		if gEnableAdvancedGrindSettings then
			minFateLevel = tonumber(gGrindFatesMinLevel) or 0
			maxFateLevel = tonumber(gGrindFatesMaxLevel) or 0
		else
			minFateLevel = 70
			maxFateLevel = 3
		end
		
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
		--d("Setting FATE to wait for next part of the chain.")
		Player:Stop()
		ml_task_hub:ThisTask().fateid = nextFate.id
		ml_task_hub:ThisTask().waitingForChain = true
		ml_task_hub:ThisTask().waitStart = Now()
		ml_task_hub:ThisTask().nextFate = nextFate
		ml_task_hub:ThisTask().specialDelay = nextFate.specialDelay
	else
		--d("Setting FATE to end completely.")
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
		[152] = {
			[1] = {
				{ id = 610, x = 338, y = -4, z = -58 },
				{ id = 611, x = 280, y = -5, z = 12 },
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
		[612] = {
			[1] = {
				{ id = 1112, x = -632.5, y = 117.6, z = -251.6 },
				{ id = 1113, x = -632.5, y = 117.6, z = -251.6 },
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

function ffxiv_task_fate.Activateable(mapid, fateid)
	local mapid = tonumber(mapid) or 0
	local fateid = tonumber(fateid) or 0
	
	local activate = {
		[134] = {
			[225] = { id = 1355, pos = {x = 99, y = 64, z = -147 } },
			[229] = { id = 1320, pos = {x = 12, y = 58, z = -303 } },
		},
			
		[137] = {
			[267] = { id = 1720, pos = {x = 28, y = 54, z = 105 } },
			[271] = { id = 1867, pos = {x = -75, y = 44, z = 403 } },
			[272] = { id = 1855, pos = {x = -49, y = 38, z = 476 } },
			[279] = { id = 1363, pos = {x = 519, y = 9, z = 152 } },
			[334] = { id = 891, pos = {x = 437, y = 16, z = 389 } },
			[562] = { id = 1659, pos = {x = -263, y = 46, z = 304 } },
		},
		
		[140] = {
			[344] = { id = 1322,  pos = {x = -88, y = 52, z = 268 } },
			[346] = { id = 1323,  pos = {x = -204, y = 32, z = 370 } },
		},
			
		[141] = {
			[377] = { id = 1325, pos = {x = 363, y = -17, z = -71 } },
		},
		
		
		[145] = {
			[195] = { id = 1255, pos = {x = 118, y = -3, z = 50 } },
		},
		
		[146] = {
			[434] = { id = 1343, pos = {x = -187, y = 3, z = -181 } },
		},
			
		[147] = {
			[457] = { id = 1726, pos = {x = -95, y = 83, z = -268 } },
			[556] = { id = 1726, pos = {x = 28, y = 35, z = 55 } },
			[642] = { id = 1718, pos = {x = 17, y = 4, z = 397 } },
			[643] = { id = 1512, pos = {x = 214, y = 24, z = 90 } },
			[644] = { id = 1513, pos = {x = 252, y = 25, z = 2 } },
		},
	
		[148] = {
			[601] = { id = 526, pos = {x = -335, y = 62, z = -39 } },
			[603] = { id = 2175, pos = {x = -448, y = 63, z = -249 } },
		},
			
		[152] = {
			[143] = { id = 524, pos = {x = -485, y = 8, z = 158 } },
			[610] = { id = 1729, pos = {x = 338, y = -4, z = -58 } },
		},
		
		[153] = {
			[158] = { id = 526, pos = {x = 232, y = 6, z = -5 } },
			[166] = { id = 529, pos = {x = -200, y = 9, z = -47 } },
			[168] = { id = 526, pos = {x = 371, y = 0, z = 21 } },
			[172] = { id = 520, pos = {x = 291, y = 6, z = -25 } },
		},
		
		[155] = {
			[469] = { id = 1605, pos = {x = 323, y = 345, z = -520 } },
			[482] = { id = 1582, pos = {x = -580.7, y = 225.21, z = -100.3 } },
			[486] = { id = 1603, pos = {x = -549, y = 237, z = 360 } },
			[501] = { id = 1862, pos = {x = 245, y = 302, z = -281 } },
		},
			
		[156] = {
			[512] = { id = 1584, pos = {x = -122, y = -2, z = -628 } },
		},
		
		[397] = {
			[788] = { id = 3976, pos = {x = 451, y = 167, z = 408 } },
			[815] = { id = 4410, pos = {x = 426, y = 183, z = 508 } },
			[817] = { id = 3967, pos = {x = -235, y = 121, z = -26 } },
		},
		
		[398] = {
			[821] = { id = 4254, pos = {x = 519, y = -44, z = -147 } },
		},
		
		[400] = {
			[728] = { id = 3959, pos = {x = 597, y = -9, z = -35 } },
			[744] = { id = 3954, pos = {x = -422, y = 40, z = -20 } },
			[752] = { id = 3952, pos = {x = -177, y = -22, z = 316 } },
			[872] = { id = 3948, pos = {x = -470, y = 40, z = 111 } },
		},
			
		[401] = {
			[852] = { id = 4004, pos = {x = -517, y = -57, z = -524 } }, 
			[853] = { id = 4003, pos = {x = 300, y = 29, z = -602 } },
		},
		
		[402] = {
			[880] = { id = 4025, pos = {x = -208, y = -162, z = -199 } }, 
		},
			
		[612] = {
			[1112] = { id = 6396, pos = {x = -602, y = 115, z = -239 } },
			[1120] = { id = 5660, pos = {x = 360, y = 62, z = -471 } },
			[1122] = { id = 5660, pos = {x = 112, y = 52, z = -512 } },
			[1127] = { id = 6409, pos = {x = -501, y = 53, z = 23 } },
			[1131] = { id = 5791, pos = {x = 509, y = 52, z = 409 } },
			[1133] = { id = 6417, pos = {x = 295, y = 43, z = 191 } },
		},
			
		[613] = {
			[1149] = { id = 6476, pos = {x = 376, y = 0, z = -705 } },
			[1152] = { id = 6479, pos = {x = -46, y = 0, z = 501 } },
			[1167] = { id = 6494, pos = {x = -337, y = 33, z = -819 } },
		},
			
		[614] = {
			[1110] = { id = 6292, pos = {x = -420, y = 32, z = 456 } },
			[1111] = { id = 6291, pos = {x = -76, y = 61, z = -700 } },
			[1118] = { id = 6406, pos = {x = -482, y = 82, z = -243 } },
			[1120] = { id = 5660, pos = {x = 360, y = 62, z = -471 } },
			[1136] = { id = 6735, pos = {x = 647, y = 82, z = 230 } },
			[1208] = { id = 6499, pos = {x = -169, y = 14, z = 507 } },
			[1211] = { id = 6500, pos = {x = 270, y = 14, z = -635 } },
			[1224] = { id = 6508, pos = {x = 230, y = 43, z = 52 } },
			[1225] = { id = 6510, pos = {x = 438, y = 86, z = 40 } },
		},
			
		[620] = {
			[1176] = { id = 6431, pos = {x = -307, y = 60, z = -686 } },
			[1186] = { id = 6439, pos = {x = 211, y = 311, z = 371 } },
			[1195] = { id = 6444, pos = {x = 145, y = 303, z = 653 } },
		},
			
		[622] = {
			[1250] = { id = 6541, pos = {x = 460, y = 11, z = -83 } },
			[1255] = { id = 6543, pos = {x = -210, y = 83, z = -532 } },
			[1261] = { id = 6547, pos = {x = 460, y = -24, z = 586 } },
			[1269] = { id = 6554, pos = {x = 166, y = 34, z = -332 } },
			[1308] = { id = 6559, pos = {x = 239, y = 11, z = -191 } },
		},
	}
	
	local mapActivate = activate[mapid]
	if (mapActivate) then
		for activatefateid,activatefatedata in pairs(mapActivate) do
			if (fateid == activatefateid) then
		
				return activatefatedata
			end
		end
	end
	
	return nil
end

function ffxiv_task_fate.Gatherable(mapid, fateid)
	local mapid = tonumber(mapid) or 0
	local fateid = tonumber(fateid) or 0
	
	local gatherable = {
		--[[
		Npc = id
		Pickup id = itemid
		Turnin item = turninid
		]]
		[137] = {
			[272] = { id = 1855, pos = {x = -49, y = 38, z = 476 }, itemid = 2001226, turninid = 2001054 },
			[279] = { id = 1363, pos = {x = 519, y = 9, z = 152 }, itemid = 2001761, turninid = 2000561 },
			[562] = { id = 1659, pos = {x = -263, y = 46, z = 304 }, itemid = 2001207, turninid = 2001057 },
		},
		
		[140] = {
			[346] = { id = 1323,  pos = {x = -204, y = 32, z = 370 }, itemid = 2001221, turninid = 2000254 },
		},
			
		[147] = {
			[457] = { id = 1726,  pos = {x = -95, y = 83, z = -268 }, itemid = 2001209, turninid = 2001052 },
			[556] = { id = 1726, pos = {x = 28, y = 35, z = 55 }, itemid = 2001221, turninid = 2000254 },
		},
		[148] = {
			[603] = { id = 2175, pos = {x = -448, y = 63, z = -249 }, itemid = 2001228, turninid = 2001056 },
		},
			
		[155] = {
			[472] = { id = 1715, pos = {x = 511, y = 348, z = -695 }, itemid = 2001208, turninid = 2001051 },
		},
			
		[153] = {
			[168] = { id = 526, pos = {x = 371, y = 0, z = 21 }, itemid = 2001213, turninid = 2000251 },
			[172] = { id = 520, pos = {x = 291, y = 6, z = -25 }, itemid = 2001211, turninid = 2002287 }, 
		},
		
		[154] = {
			[180] = { id = 533, pos = {x = -247, y = -31, z = 389 }, itemid = 2001212, turninid = 2000253 } ,
		},
		
		[398] = {
			[821] = { id = 4254, pos = {x = 519, y = -44, z = -147 }, itemid = 2006422, turninid = 2001885 },
		},
		
		[400] = {
			[728] = { id = 3959, pos = {x = 597, y = -9, z = -35 }, itemid = 2006126, turninid = 2001788 },
		},
			
		[401] = {
			[852] = { id = 4004, pos = {x = -517, y = -57, z = -524 }, itemid = 2006356, turninid = 2001877 },
		},
		
		[612] = {
			[1133] = { id = 6417, pos = {x = 295, y = 43, z = 191 }, itemid = 2008390, turninid = 2002234 },
			[1136] = { id = 6735, pos = {x = 647, y = 82, z = 230 }, itemid = 2008959, turninid = 2002235 },
		},
			
		[613] = {
			[1149] = { id = 6476, pos = {x = 376, y = 0, z = -705 }, itemid = 2008954, turninid = 2002268 },
		},
			
		[614] = {
			[1111] = { id = 6291, pos = {x = -76, y = 61, z = -700 }, itemid = 2008613, turninid = 2002389 },
			[1136] = { id = 6735, pos = {x = 647, y = 82, z = 230 }, itemid = 2008959, turninid = 2002235 },
			[1224] = { id = 6508, pos = {x = 230, y = 43, z = 52 }, itemid = 2008751, turninid = 2002270 },
			[1225] = { id = 6510, pos = {x = 438, y = 86, z = 40 }, itemid = 2008752, turninid = 2002271 },
		},
		[620] = {
			[1186] = { id = 6439, pos = {x = 211, y = 311, z = 371 }, itemid = 2008956, turninid = 2002267 },
			
		},
		[622] = {
			[1308] = { id = 6559, pos = {x = 239, y = 11, z = -191 }, itemid = 2008947, turninid = 2002385 },
		}
	}
	
	local mapGatherable = gatherable[mapid]
	if (mapGatherable) then
		for gatherfateid,gatherfatedata in pairs(mapGatherable) do
			if (fateid == gatherfateid) then
		
				return gatherfatedata
			end
		end
	end

	return nil
end
---------------------------------------------------------------------------------------------
--TASK_FATE: Longterm Goal - Complete a fate event successfully
---------------------------------------------------------------------------------------------
ffxiv_task_fate = inheritsFrom(ml_task)
ffxiv_task_fate.addon_process_elements = {}
ffxiv_task_fate.addon_overwatch_elements = {}
ffxiv_task_fate.eventInventories = { 2004 }
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
	newinst.fateMap = Player.localmapid
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

function ffxiv_task_fate.FateWaitFailEval()
	return c_add_fate:evaluate()
end

function ffxiv_task_fate.FateWaitFailExecute(self)
	Player:Stop()
	self.valid = false
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
	newTask.task_fail_eval = ffxiv_task_fate.FateWaitFailEval
	newTask.task_fail_execute = ffxiv_task_fate.FateWaitFailExecute

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
					if table.valid(players) then
						return false
					end
					
					players = EntityList("type=1")
					if (players) then
						for _,entity in pairs(players) do
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
		if (type(myPos) ~= "table" or type(myPos.x) ~= "number" or type(myPos.y) ~= "number" or type(myPos.z) ~= "number" or
			 type(fate.x) ~= "number" or type(fate.y) ~= "number" or type(fate.z) ~= "number")
		then
			return false
		end
		local distance = PDistance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z)
		if (distance > 5) then				
			return true
		end
	end
    
    return false
end
function e_movetochainlocation:execute()
    local fate = ml_task_hub:CurrentTask().nextFate
	if (table.valid(fate) and type(fate.x) == "number" and type(fate.y) == "number" and type(fate.z) == "number") then
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
	local currentTask = ml_task_hub:CurrentTask()
	if (currentTask.fateid ~= nil and currentTask.fateid ~= 0) then
	
		local fate = MGetFateByID(currentTask.fateid)
		if (table.valid(fate)) then
			if (fate.status == 2) then
				local currentFatePos = currentTask.fatePos
				local newFatePos = {x = fate.x, y = fate.y, z = fate.z}
				if (not table.valid(currentFatePos)) then
					currentTask.fatePos = newFatePos
					return false
				elseif (not Player.incombat and not deepcompare(currentFatePos,newFatePos,true)) then
					currentTask.fatePos = newFatePos
					return true
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
	
	local isEureka = IsEurekaMap(Player.localmapid)
	if (not isEureka and Player:GetSyncLevel() ~= 0) then
		return false
	end
	
    local myPos = Player.pos
	local fateID = ml_task_hub:ThisTask().fateid
	local fate = MGetFateByID(fateID)
	if ( table.valid(fate)) then
		if ((not isEureka and fate.maxlevel < Player.level) or (isEureka and fate.maxlevel < Player.eurekainfo.level)) then
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
	local currentTask = ml_task_hub:ThisTask()
	local fate = MGetFateByID(currentTask.fateid)
	if (table.valid(fate)) then
		local nearestFateTarget = GetNearestFateAttackable()
		if (fate.status == 2 or table.valid(nearestFateTarget)) then
			if (currentTask.waitingForChain) then
				currentTask.waitingForChain = false
				d("Removing FATE wait flag.")
			end
			if (table.valid(currentTask.nextFate)) then
				currentTask.nextFate = {}
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
						local epos = target.pos
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
	ml_global_information.Await(math.random(1000,5000))
	ml_task_hub:ThisTask().randomDelayCompleted = true
end

--622, 1308  239.30, 11, 191.99, 6559


c_startfate = inheritsFrom( ml_cause )
e_startfate = inheritsFrom( ml_effect )
e_startfate.contentid = 0
e_startfate.fateid = 0
function c_startfate:evaluate()
	-- Reset tempvars.
	e_startfate.contentid = 0
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
				local closest,closestDistance = nil,IsNull(activatable.range,100)
				for _,entity in pairs(fatenpc) do
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

function ffxiv_task_fate.StartFateCompleteEval(self)
	-- Dumbed this down to one helper, lots of conditions already, and I fear more to come, diving doesn't follow the usual rules.
	local fate = MGetFateByID(self.fateid)
	if (not fate or fate.status == 2 or Busy() or self.startMap ~= Player.localmapid) then
		return true
	end

	local ppos = Player.pos
	local interactable = nil
	if (self.interact ~= 0) then
		interactable = EntityList:Get(self.interact)
	end

	local dist2d,dist3d = math.distance2d(ppos,self.pos),math.distance3d(ppos,self.pos)
	if (self.interact ~= 0 and dist2d < 50 and dist2d < fate.radius and dist3d < fate.radius) then
		if (not interactable or not interactable.targetable) then
			d("[e_startfate] interact not targetable")
			return true
		end
		local npcdist2d = math.distance2d(interactable.pos,self.pos)
		if interactable and npcdist2d > 5 then
			d("[e_startfate] intertactable moved...")
			return true
		end
	else
		if (dist2d <= 5) then
			local interacts = EntityList("targetable,contentid="..tostring(self.contentid)..",maxdistance=10")
			if (not table.valid(interacts)) then
				d("[e_startfate] no valid interacts found")
				return true
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
	
	newTask.task_complete_eval = ffxiv_task_fate.StartFateCompleteEval
		
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
				local currentcount = ItemCount(turninid)
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
	for _,invid in pairs(ffxiv_task_fate.eventInventories) do
		local bag = Inventory:Get(invid)
		if (table.valid(bag)) then
			local ilist = bag:GetList()
			if (table.valid(ilist)) then
				for _,item in pairs(ilist) do
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
				for _,entity in pairs(el) do
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
				for _,entity in pairs(fatenpc) do
					if entity.fateid == fateid then
						local gatherable = ffxiv_task_fate.Gatherable(Player.localmapid, fateid)
						if (gatherable) then
							local pickupitem = MEntityList("nearest,targetable,contentid="..tostring(gatherable.itemid))
							if (table.valid(pickupitem)) then
								for _,item in pairs(pickupitem) do
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
		for _,element in pairs(overwatch_elements) do
			self:add(element, self.overwatch_elements)
		end
	end
	
	local process_elements = self.addon_process_elements
	if (table.valid(process_elements)) then
		for _,element in pairs(process_elements) do
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
	local redeemable = false
    if (table.valid(fate)) then
		gatherable = ffxiv_task_fate.Gatherable(Player.localmapid, fate.id)
		if (gatherable) then
			redeemable = (ItemCount(gatherable.turninid) >= 1)
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
			for _,e in pairs(el) do
				if (e.targetable) then
					foundTargetable = true
					break
				end
			end
		end        
		
		if (not foundTargetable) then
			return true
		end
	else
		local minFateLevel
		local maxFateLevel
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
	return FFXIVMinionFate.IsHighPriority(mapid, fateid)
end

function ffxiv_task_fate.IsChain(mapid, fateid)
	local fateid = tonumber(fateid) or 0

	--d("Checking to see if fateid:"..tostring(fateid).." is a chain for mapid:"..tostring(mapid))
	-- Use FFXIVLib to detect chains via FATEChain field
	local fateData = FFXIVLib.API.Fate.GetFateById(fateid)
	if not fateData then return false, nil, nil, nil end

	-- Check if this FATE is part of a chain
	local chainId = fateData.FATEChain
	local isInChain = (chainId and chainId > 0)

	local followers = nil
	if not isInChain then
		-- Check if any other FATE chains FROM this one
		followers = FFXIVLib.API.Fate.GetFateChain(fateid)
		if followers and #followers > 1 then
			isInChain = true
		end
	end

	if not isInChain then
		return false, nil, nil, nil
	end

	-- Determine chain position
	local firstChain = (not chainId or chainId == 0)

	-- Find the next FATE in the chain (the one whose FATEChain points to us)
	followers = followers or FFXIVLib.API.Fate.GetFateChain(fateid)
	local nextFate = nil
	local lastChain = true

	if followers then
		for _, f in ipairs(followers) do
			if f.FATEChain == fateid then
				lastChain = false
				nextFate = { id = f.id }
				break
			end
		end
	end

	ml_debug("IsChain:"..tostring(firstChain)..","..tostring(lastChain)..tostring(nextFate))
	return true, firstChain, lastChain, nextFate
end

function ffxiv_task_fate.Activateable(mapid, fateid)
	return FFXIVMinionFate.GetActivateable(mapid, fateid)
end

function ffxiv_task_fate.Gatherable(mapid, fateid)
	return FFXIVMinionFate.GetGatherable(mapid, fateid)
end

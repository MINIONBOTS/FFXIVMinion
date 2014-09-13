ffxiv_task_gather = inheritsFrom(ml_task)
ffxiv_task_gather.name = "LT_GATHER"
ffxiv_task_gather.location = 0
ffxiv_task_gather.unspoiledGathered = true
ffxiv_task_gather.gatherStarted = false
ffxiv_task_gather.timer = 0
ffxiv_task_gather.editwindow = {name = GetString("locationEditor"), x = 0, y = 0, width = 250, height = 230}

--unspoiled mining = content id 5
--unspoiled botany = content id 6
--truth of the forests = buff id 221, skill id 221
--truth of the mountains = buff id 222, skill id 238

function ffxiv_task_gather.Create()
    local newinst = inheritsFrom(ffxiv_task_gather)
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_gather members
    newinst.name = "LT_GATHER"
    newinst.gatherid = 0
    newinst.markerTime = 0
    newinst.currentMarker = false
    newinst.gatherTimer = 0
	newinst.gatherDistance = 1.5
	newinst.maxGatherDistance = 100 -- for setting the range when the character is beeing considered "too far away from the gathermarker" where it would make him run back to the marker
	newinst.gatheredMap = false
	newinst.gatheredGardening = false
    newinst.idleTimer = 0
	newinst.filterLevel = true
	newinst.swingCount = 0
	newinst.itemsUncovered = false
	newinst.slotsTried = {}
	newinst.interactTimer = 0
	newinst.changingLocations = false
	newinst.rareCount = -1
	newinst.mapCount = -1
    
    -- for blacklisting nodes
    newinst.failedTimer = 0
    
    return newinst
end

---------------------------------------------------------------------------------------------
--FINDGATHERABLE: If (no current gathering target) Then (find the nearest gatherable target)
--Gets a gathering target by searching entity list for objectType = 6?
---------------------------------------------------------------------------------------------

c_findgatherable = inheritsFrom( ml_cause )
e_findgatherable = inheritsFrom( ml_effect )
function c_findgatherable:evaluate()
	if (gGatherUnspoiled == "1") then
		return false
	end
	
	local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
        return false
    end

    if ( ml_task_hub:CurrentTask().gatherid == nil or ml_task_hub:CurrentTask().gatherid == 0 ) then
        return true
    end
    
    local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
    if (gatherable ~= nil) then
        if (not gatherable.cangather) then
            return true 
        end
    elseif (gatherable == nil) then
        return true
    end
    
    return false
end
function e_findgatherable:execute()
    ml_debug( "Getting new gatherable target" )
    local minlevel = 1
    local maxlevel = 50
    if (ValidTable(ml_task_hub:CurrentTask().currentMarker) and
		gMarkerMgrMode ~= strings[gCurrentLanguage].singleMarker) 
	then
		minlevel = ml_task_hub:CurrentTask().currentMarker:GetMinLevel()
		maxlevel = ml_task_hub:CurrentTask().currentMarker:GetMaxLevel()
    end
    
    local gatherable = GetNearestGatherable(minlevel,maxlevel)
    if (gatherable ~= nil) then
		-- reset blacklist vars for a new node
		ml_task_hub:CurrentTask().failedTimer = 0		
		ml_task_hub:CurrentTask().gatheredMap = false
        ml_task_hub:CurrentTask().gatherid = gatherable.id		
				
		-- setting the maxrange for the "return to marker" check, so we dont have a pingpong navigation between going to node and going back to marker		
		if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then
			local nodePos = gatherable.pos
			local markerPos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
            
			--just for testing
			local distance2d = Distance2D(nodePos.x, nodePos.z, markerPos.x, markerPos.z)
			ml_debug("Distance2D Node <-> current Marker: "..tostring(distance2d))		
			local pathdist = NavigationManager:GetPath(nodePos.x,nodePos.y,nodePos.z,markerPos.x, markerPos.y,markerPos.z)
			if ( pathdist ) then
				local pdist = PathDistance(pathdist)
				ml_debug("Path distance Node <-> current Marker : "..tostring(pdist))
				if ( pdist > 50 ) then
					ml_task_hub:CurrentTask().maxGatherDistance = pdist + 25
					return
				end
			end			
		end
		--default 
		ml_task_hub:CurrentTask().maxGatherDistance = 250
		
    else
		-- no gatherables nearby, try to walk to next gather marker by setting the current marker's timer to "exceeded"
        if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then            
			if ( TimeSince(ml_task_hub:CurrentTask().gatherTimer) > 1500 ) then
                local markerPos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
				local pPos = Player.pos
				-- we are nearby our marker and no nodes are nearby anymore, grab the next one
				if (Distance2D(pPos.x, pPos.z, markerPos.x, markerPos.z) < 15) then
					local t = ml_task_hub:CurrentTask().currentMarker:GetTime()
					ml_task_hub:CurrentTask().markerTime = ml_task_hub:CurrentTask().markerTime - t
				else
					-- walk to the center of our marker first
					if (markerPos ~= nil and markerPos ~= 0) then
						Player:MoveTo(markerPos.x, markerPos.y, markerPos.z, 10, false, gRandomPaths=="1")
                        ml_task_hub:CurrentTask().idleTimer = ml_global_information.Now
					end
				end
            end
        end
    end
	
	--idiotcheck for no usable markers found on this mesh
	if (ml_task_hub:CurrentTask().currentMarker ~= nil and ml_task_hub:CurrentTask().currentMarker ~= 0 and ml_task_hub:CurrentTask().currentMarker == false) then
        ml_error("THE LOADED NAVMESH HAS NO MINING/BOTANY MARKERS IN THE LEVELRANGE OF YOUR PLAYER")	
	end
	return false
end

c_findunspoilednode = inheritsFrom( ml_cause )
e_findunspoilednode = inheritsFrom( ml_effect )
e_findunspoilednode.pos = {}
function c_findunspoilednode:evaluate()
	if (Now() < ffxiv_task_gather.timer) then
		return false
	end
	
	local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
        return false
    end
	
	if (ffxiv_task_gather.unspoiledGathered or gGatherUnspoiled == "0" or not ValidTable(ffxiv_task_gather.location) or ml_task_hub:CurrentTask().name == "LT_STEALTH") then
		return false
	end
	
	if (ffxiv_task_gather.location.isIdle) then
		return false
	end
	
	--Make sure we're within 50 yards of the marker before we start searching for the node.
	if (not ValidTable(ml_task_hub:ThisTask().currentMarker)) then
		return false
	end
	
	local destPos = ml_task_hub:ThisTask().currentMarker:GetPosition()
	local myPos = Player.pos
	local distance = Distance3D(myPos.x, myPos.y, myPos.z, destPos.x, destPos.y, destPos.z)
	if (distance > 100) then
		return false
	end
	
	if (MissingBuffs(Player,"221+222")) then
		ffxiv_task_gather.LocatorBuff(ffxiv_task_gather.location.class)
		return false
	end
	
	if (ml_task_hub:ThisTask().gatherid == 0) then
		local node = GetNearestUnspoiled(Player.job)
		if (ValidTable(node)) then
			ml_task_hub:ThisTask().gatherid = node.id
		end
	end

	if ( ml_task_hub:ThisTask().gatherid ~= nil and ml_task_hub:ThisTask().gatherid ~= 0) then
		local gatherable = EntityList:Get(ml_task_hub:ThisTask().gatherid)
		if (gatherable and gatherable.cangather and (gatherable.distance2d > 3 or gatherable.pathdistance > 10)) then
			if (ml_task_hub:CurrentTask().name == "MOVETOPOS") then
				if (PosIsEqual(ml_task_hub:CurrentTask().pos, gatherable.pos)) then
					return false
				end
			end
			
			e_findunspoilednode.pos = gatherable.pos
            return true
        end
    end

    return false
end
function e_findunspoilednode:execute()
   local pos = e_findunspoilednode.pos
    if (ValidTable(pos)) then
		local newTask = ffxiv_task_movetopos.Create()
		newTask.pos = pos
		newTask.usePathDistance = true
		newTask.objectid = ml_task_hub:ThisTask().gatherid
		newTask.range = 2
		newTask.remainMounted = false
		ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

c_movetounspoiledmarker = inheritsFrom( ml_cause )
e_movetounspoiledmarker = inheritsFrom( ml_effect )
function c_movetounspoiledmarker:evaluate()
	--Check that we have a proper location, that we haven't already gathered here, and that we haven't already found the node and that there is a valid marker.
	if (Now() < ffxiv_task_gather.timer or IsLoading()) then
		return false
	end
	
    if ( ffxiv_task_gather.location == 0 or ffxiv_task_gather.unspoiledGathered or 
		not ValidTable(ffxiv_task_gather.location) or gGatherUnspoiled == "0" or 
		not ValidTable(ml_task_hub:CurrentTask().currentMarker) or ml_task_hub:CurrentTask().gatherid ~= 0 ) 
	then
        return false
    end
	
	--If we're just idling, there should be no marker to move to.
	if (ffxiv_task_gather.location.isIdle) then
		return false
	end
	
	--Do another class and buff check, incase we started on the map and didn't teleport.
	if (Player.job ~= ffxiv_task_gather.location.class) then
		ffxiv_task_gather.SwitchClass(ffxiv_task_gather.location.class)
		return false
	end
	
	if (MissingBuffs(Player,"221+222")) then
		ffxiv_task_gather.LocatorBuff(ffxiv_task_gather.location.class)
		return false
	end
	
	--If we're less greater than 25 away, go to the marker
	local destPos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
	local myPos = Player.pos
	local distance = Distance3D(myPos.x, myPos.y, myPos.z, destPos.x, destPos.y, destPos.z)
	if (distance >= 50) then
		return true
	end
    
    return false
end
function e_movetounspoiledmarker:execute()
    local pos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
    if (ValidTable(pos)) then
		local newTask = ffxiv_task_movetopos.Create()
		newTask.pos = pos
		newTask.range = 1.5
		newTask.use3d = true
		newTask.remainMounted = true
		ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

c_movetogatherable = inheritsFrom( ml_cause )
e_movetogatherable = inheritsFrom( ml_effect )
function c_movetogatherable:evaluate()
	if (gGatherUnspoiled == "1") then
		return false
	end
	
    if ( TimeSince(ml_task_hub:CurrentTask().gatherTimer) < 1500 ) then
        return false
    end
    
    if ( ml_task_hub:CurrentTask().gatherid ~= nil and ml_task_hub:CurrentTask().gatherid ~= 0 ) then
        local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
        if (Player:GetGatherableSlotList() == nil and gatherable ~= nil and gatherable.distance2d > (ml_task_hub:CurrentTask().gatherDistance + 0.5)) then
            return true
        end
    end
    
    return false
end
function e_movetogatherable:execute()
    -- reset idle timer
    ml_task_hub:CurrentTask().idleTimer = 0

    local pos = EntityList:Get(ml_task_hub:CurrentTask().gatherid).pos
    if (pos ~= nil and pos ~= 0) then
        if (gTeleport == "1") then
            GameHacks:TeleportToXYZ(pos.x,pos.y,pos.z)
        else
            local newTask = ffxiv_task_movetopos.Create()
            newTask.pos = pos
            newTask.range = ml_task_hub:CurrentTask().gatherDistance
            newTask.gatherRange = 0.5
            ml_task_hub:CurrentTask():AddSubTask(newTask)
        end
    end
end

c_nextunspoiledmarker = inheritsFrom( ml_cause )
e_nextunspoiledmarker = inheritsFrom( ml_effect )
e_nextunspoiledmarker.marker = nil
function c_nextunspoiledmarker:evaluate()
	if (Now() < ffxiv_task_gather.timer or IsLoading()) then
		return false
	end
	
	--Make sure we're supposed to be gathering unspoiled, and that we have a proper location table, that we haven't already gathered, and that the currentMarker is set to false.
	if (gGatherUnspoiled == "0" or not ValidTable(ffxiv_task_gather.location) or ffxiv_task_gather.unspoiledGathered or 
		ml_task_hub:CurrentTask().currentMarker ~= false or ml_task_hub:CurrentTask().gatherid ~= 0) then
		return false
	end
	
	--If we're just idling, don't look for a marker.
	if (ffxiv_task_gather.location.isIdle) then
		return false
	end
	
	--If we're not on the new location's map yet, don't do anything.
	if (Player.localmapid ~= tonumber(ffxiv_task_gather.location.mapid)) then
		return false
	end
	
	--If we have a gatherable window open, don't do anything. Not sure if we need this or not.
    local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
        return false
    end
	
    local marker = ml_marker_mgr.GetMarker(ffxiv_task_gather.location.marker)
	if (ValidTable(marker) and ml_task_hub:CurrentTask().currentMarker ~= marker) then
		e_nextunspoiledmarker.marker = marker
		return true
	end
    
    return false
end
function e_nextunspoiledmarker:execute()
    ml_task_hub:CurrentTask().currentMarker = e_nextunspoiledmarker.marker
    ml_task_hub:CurrentTask().markerTime = Now()
	ml_global_information.MarkerTime = Now()
    ml_global_information.MarkerMinLevel = ml_task_hub:CurrentTask().currentMarker:GetMinLevel()
    ml_global_information.MarkerMaxLevel = ml_task_hub:CurrentTask().currentMarker:GetMaxLevel()
	ml_global_information.BlacklistContentID = ""
    ml_global_information.WhitelistContentID = ""
	gStatusMarkerName = ml_task_hub:CurrentTask().currentMarker:GetName()
end

c_nextgathermarker = inheritsFrom( ml_cause )
e_nextgathermarker = inheritsFrom( ml_effect )
function c_nextgathermarker:evaluate()
	
	--Check to make sure we have gathered any unspoiled nodes first.
	if (gGatherUnspoiled == "1") then
		return false
	end
	
    local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
        return false
    end
	
	if (gMarkerMgrMode == strings[gCurrentLanguage].singleMarker) then
		ml_task_hub:CurrentTask().filterLevel = false
	end
    
    if ( ml_task_hub:CurrentTask().currentMarker ~= nil and ml_task_hub:CurrentTask().currentMarker ~= 0 ) then
        local marker = nil
        
        -- first check to see if we have no initialized marker
        if (ml_task_hub:CurrentTask().currentMarker == false) then --default init value
            local markerType = ""
            if (Player.job == FFXIV.JOBS.BOTANIST) then
                markerType = strings[gCurrentLanguage].botanyMarker
            else
                markerType = strings[gCurrentLanguage].miningMarker
            end
            marker = ml_marker_mgr.GetNextMarker(markerType, ml_task_hub:CurrentTask().filterLevel)
			
			if (marker == nil) then
				ml_task_hub:CurrentTask().filterLevel = false
				marker = ml_marker_mgr.GetNextMarker(markerType, ml_task_hub:CurrentTask().filterLevel)
			end
        end
        
        -- next check to see if our level is out of range
        if (marker == nil) then
            if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then
                if 	(ml_task_hub:CurrentTask().filterLevel) and
					(Player.level < ml_task_hub:CurrentTask().currentMarker:GetMinLevel() or 
                    Player.level > ml_task_hub:CurrentTask().currentMarker:GetMaxLevel()) 
                then
                    marker = ml_marker_mgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker:GetType(), ml_task_hub:CurrentTask().filterLevel)
                end
            end
        end
        
        -- next check to see if we can't find any gatherables at our current marker
        if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then            
			if ( ml_task_hub:CurrentTask().idleTimer ~= 0 and TimeSince(ml_task_hub:CurrentTask().idleTimer) > 30 * 1000 ) then
                ml_task_hub:CurrentTask().idleTimer = 0
                local markerPos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
				local pPos = Player.pos
				-- we are nearby our marker and no nodes are nearby anymore, grab the next one
				if (Distance2D(pPos.x, pPos.z, markerPos.x, markerPos.z) < 15) then
                    marker = ml_marker_mgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker:GetType(), ml_task_hub:CurrentTask().filterLevel)
				end
            end
        end
        
        -- last check if our time has run out
        if (marker == nil) then
			if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then
				local time = ml_task_hub:CurrentTask().currentMarker:GetTime()
				if (time and time ~= 0 and TimeSince(ml_task_hub:CurrentTask().markerTime) > time * 1000) then
					--ml_debug("Marker timer: "..tostring(TimeSince(ml_task_hub:CurrentTask().markerTime)) .."seconds of " ..tostring(time)*1000)
					ml_debug("Getting Next Marker, TIME IS UP!")
					marker = ml_marker_mgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker:GetType(), ml_task_hub:CurrentTask().filterLevel)
				else
					return false
				end
			end
        end
        
        if (ValidTable(marker)) then
            e_nextgathermarker.marker = marker
            return true
        end
    end
    
    return false
end
function e_nextgathermarker:execute()
    ml_task_hub:CurrentTask().currentMarker = e_nextgathermarker.marker
    ml_task_hub:CurrentTask().markerTime = ml_global_information.Now
	ml_global_information.MarkerTime = ml_global_information.Now
    ml_global_information.MarkerMinLevel = ml_task_hub:CurrentTask().currentMarker:GetMinLevel()
    ml_global_information.MarkerMaxLevel = ml_task_hub:CurrentTask().currentMarker:GetMaxLevel()
	ml_global_information.BlacklistContentID = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].NOTcontentIDEquals)
    ml_global_information.WhitelistContentID = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].contentIDEquals)
	gStatusMarkerName = ml_task_hub:CurrentTask().currentMarker:GetName()
end

c_nextgatherlocation = inheritsFrom( ml_cause )
e_nextgatherlocation = inheritsFrom( ml_effect )
c_nextgatherlocation.location = {}
function c_nextgatherlocation:evaluate()
	if (Now() < ffxiv_task_gather.timer or IsLoading()) then
		return false
	end
	
	local list = Player:GetGatherableSlotList()
	if (ValidTable(list) or gGatherUnspoiled == "0") then
		return false
	end
	
	local node = Player:GetTarget()
	if (ValidTable(node) and node.cangather) then
		return false
	end
	
	if (ValidTable(ffxiv_task_gather.location)) then
		if (not ffxiv_task_gather.unspoiledGathered and not ffxiv_task_gather.location.isIdle) then
		
			--If we haven't yet completed gathering, but we started and there's no longer a node or list, assume we completed.
			--If we haven't yet completed gathering, and the node time was 3 hours ago, it's gone by now, so move on.
			local eTime = EorzeaTime()
			local overdue = SubtractHours(eTime.hour,3)
			--d("reset condition1 = "..tostring(ffxiv_task_gather.gatherStarted))
			d("reset condition2 = "..tostring(overdue == ffxiv_task_gather.location.hour))
			if (ffxiv_task_gather.gatherStarted or overdue == ffxiv_task_gather.location.hour) then
				ffxiv_task_gather.gatherStarted = false
				ffxiv_task_gather.unspoiledGathered = true
				ml_task_hub:CurrentTask().currentMarker = false
				ml_task_hub:CurrentTask().gatherid = 0
				
				local locations = Settings.FFXIVMINION.gGatherLocations
				locations[ffxiv_task_gather.location.name].lastGather = os.time()
				Settings.FFXIVMINION.gGatherLocations = locations
			end
			return false
		end
	end

	local locations = Settings.FFXIVMINION.gGatherLocations
	--If we don't have any locations, just operate normally.
	if (TableSize(locations) == 0) then
		return false
	end
	
	local eTime = EorzeaTime()
	local eHour = eTime.hour
	local eLastHour = nil
	if (eHour == 0) then
		eLastHour = 22
	elseif (eHour == 1) then
		eLastHour = 23
	else
		eLastHour = eHour - 2
	end
	local eLastHour2 = (eHour == 0) and 23 or (eHour - 1)
	local eNextHour = (eHour == 23) and 0 or (eHour + 1)
	local eMin = eTime.minute
	
	--Check to see what locations we have, and find the most appropriate one.
	local bestLocation = nil
	--Start with our starting location if the current location is 0
	if (ffxiv_task_gather.location == 0) then
		local startHour = 0
		for i, location in spairs(locations) do
			if (i == gGatherStartLocation) then
				bestLocation = location
				--d("best location used block 1")
				startHour = location.hour
			end
			if (bestLocation ~= nil) then
				break
			end
		end	
		local lastHour, lastHour2 = SubtractHours(startHour,1), SubtractHours(startHour,2)
		for i, location in pairs(locations) do
			if (location.hour == lastHour or location.hour == lastHour2) then
				location.lastGather = os.time()
			end
		end
		Settings.FFXIVMINION.gGatherLocations = locations
		locations = Settings.FFXIVMINION.gGatherLocations
	end
	
	--Next, try location that has been up for 2 hours already.
	if (bestLocation == nil ) then
		for i, location in spairs(locations) do
			if (not location.isIdle and location.hour == eLastHour and eMin <= 30 and location.enabled and (os.time() > (location.lastGather + 1800))) then
				bestLocation = location
				--d("best location used block 2")
			end
		end
	end
	
	--Next, try location that has been ready for 1 hour.
	if (bestLocation == nil ) then
		for i, location in spairs(locations) do
			if (not location.isIdle and location.hour == eLastHour2 and location.enabled and (os.time() > (location.lastGather + 1800))) then
				bestLocation = location
				--d("best location used block 3")
			end
		end
	end
	
	--Next, try location that has just become ready this hour.
	if (bestLocation == nil ) then
		for i, location in spairs(locations) do
			if (not location.isIdle and location.hour == eHour and location.enabled and (os.time() > (location.lastGather + 1800))) then
				bestLocation = location
				--d("best location used block 4")
			end
		end
	end
	
	--Next, try location that will be ready next hour.
	if (bestLocation == nil) then
		for i, location in spairs(locations) do
			if (not location.isIdle and location.hour == eNextHour and location.enabled and (os.time() > (location.lastGather + 1800))) then
				bestLocation = location
				--d("best location used block 5")
			end
		end
	end
	
	--Last, fall back on our idle location, just to stay out of danger.
	if (bestLocation == nil) then
		if (ffxiv_task_gather.location ~= 0) then
			for i, location in spairs(locations) do
				if (location.isIdle) then
					bestLocation = location
					--d("best location used block 6")
				end
			end	
		end
	end
	
	if (bestLocation ~= nil) then
		if (ValidTable(ffxiv_task_gather.location)) then
			if (bestLocation.name == ffxiv_task_gather.location.name) then
				return false
			end
		end
		
		c_nextgatherlocation.location = bestLocation
		return true
	end
	
	--d("returned default false")
	return false
end
function e_nextgatherlocation:execute()
	local location = c_nextgatherlocation.location
	ml_task_hub:ThisTask().currentMarker = false
	ml_task_hub:ThisTask().gatherid = 0
	
	if (tonumber(location.mapid) ~= Player.localmapid) then
		Player:Stop()
		Dismount()
		
		if (Player.ismounted) then
			return
		end
		
		if (ml_task_hub:CurrentTask().name ~= "LT_TELEPORT" and ActionIsReady(5)) then
			Player:Teleport(location.teleport)
								
			local newTask = ffxiv_task_teleport.Create()
			newTask.mapID = location.mapid
			newTask.mesh = location.mesh
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	end
	
	ffxiv_task_gather.location = location
	gGatherMapLocation = location.name
	ffxiv_task_gather.unspoiledGathered = false
	ffxiv_task_gather.gatherStarted = false
	d("Changing locations to ["..location.name.."]")
end

c_gather = inheritsFrom( ml_cause )
e_gather = inheritsFrom( ml_effect )
function c_gather:evaluate()
    local list = Player:GetGatherableSlotList()
	if (list) then
		return true
	end
	
	local node = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
    if (node and node.cangather and node.distance2d <= 2.5) then
		local markerType = ml_task_hub:ThisTask().currentMarker:GetType()
		if (markerType == GetString("unspoiledMarker") or markerType == GetString("botanyMarker") or markerType == GetString("miningMarker")) then
			local requiredGP = tonumber(ml_task_hub:ThisTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].minimumGP)) or 0
			if (not ffxiv_task_gather.gatherStarted) then
				if (Player.gp.current < requiredGP) then
					if (((requiredGP - Player.gp.current) > 50) and gGatherUseCordials == "1") then
						if (ItemIsReady(6141)) then
							local newTask = ffxiv_task_useitem.Create()
							newTask.itemid = 6141
							ml_task_hub:CurrentTask():AddSubTask(newTask)
						end
					end
					return false
				else
					return true
				end
			else
				return true
			end
		else
			return true
		end
    end
	
    return false
end
function e_gather:execute()
	ffxiv_task_gather.timer = Now() + 2000
	
	if (Player.ismounted) then
		Dismount()
		return
	end
	
    local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
		local node = Player:GetTarget()
		if (not ValidTable(node) or not node.cangather) then
			return
		end
        
		-- reset fail timer
        if (ml_task_hub:CurrentTask().failedTimer ~= 0) then
            ml_task_hub:CurrentTask().failedTimer = 0
        end
		
        if ( gSMactive == "1") then
			if (ActionList:IsCasting()) then return end
            if (SkillMgr.Gather()) then
				ml_task_hub:CurrentTask().failedTimer = Now()
                return
            end
        end
		
		if (Now() > ml_task_hub:CurrentTask().interactTimer) then
			-- make sure items are visible so that we don't waste gather map or gardening attempts on an uncover			
			if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then
			
				--If it's an unspoiled marker, make sure we give plenty of time in between attempts to use skills properly, due to buff lag.
				local markerType = ml_task_hub:CurrentTask().currentMarker:GetType()
				if (markerType == GetString("unspoiledMarker")) then
					if (TimeSince(ml_task_hub:CurrentTask().gatherTimer) < 3000) then
						return
					end
				end
		
				local itemsVisible = ml_task_hub:CurrentTask().itemsUncovered or not IsUnspoiled(node.contentid)
				if (itemsVisible) then
					-- first try to get treasure maps
					local gatherMaps = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].gatherMaps)
					if (gatherMaps ~= "None") then
						if (not ml_task_hub:CurrentTask().gatheredMap) then
							local hasMap = false
							for x=0,3 do
								local inv = Inventory("type="..tostring(x))
								local i, item = next(inv)
								while (i) do
									if (IsMap(item.id)) then
										hasMap = true
										break
									end
									i,item = next(inv, i)
								end
							end
							
							if not hasMap then
								for i, item in pairs(list) do
									if ((gatherMaps == "Any" and IsMap(item.id)) or (gatherMaps == "Peisteskin Only" and item.id == 6692)) then
										local itemCount = CountItemsByID(item.id)
										if (ml_task_hub:CurrentTask().mapCount == -1) then
											ml_task_hub:CurrentTask().mapCount = itemCount
										end
										if (itemCount == ml_task_hub:CurrentTask().mapCount) then
											Player:Gather(item.index)
											return
										elseif (itemCount > ml_task_hub:CurrentTask().mapCount) then
											ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
											ml_task_hub:CurrentTask().gatheredMap = true
											ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
										end
									end
								end
							end
						end
					end
					
					-- second try to get gardening supplies
					local gatherGardening = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].gatherGardening)
					if (not ml_task_hub:CurrentTask().gatheredGardening and gatherGardening == "1") then
						for i, item in pairs(list) do
							if 	(IsGardening(item.id)) then
								local itemCount = CountItemsByID(item.id)
								if (ml_task_hub:CurrentTask().rareCount == -1) then
									ml_task_hub:CurrentTask().rareCount = itemCount
								end
								if (itemCount == ml_task_hub:CurrentTask().rareCount) then
									Player:Gather(item.index)
									return
								elseif (itemCount > ml_task_hub:CurrentTask().rareCount) then
									ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
									ml_task_hub:CurrentTask().gatheredGardening = true
									ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
								end
							end
						end
					end
				end
			
				-- do 2 loops to allow prioritization of first item
				local item1 = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].selectItem1)
				local item2 = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].selectItem2)
				
				if (item1 ~= "") then
					for i, item in pairs(list) do
						local n = tonumber(item1)
						if (n ~= nil) then
							if (item.index == (n-1) and item.id ~= nil) then
								if (IsGardening(item.id) or IsMap(item.id)) then
									ml_error("Use the GatherGardening option for this marker to gather gardening items.")
									ml_error("Use the GatherMaps option for this marker to gather map items.")
									ml_error("Gardening and Map items set to slots will be ignored.")
								end
								if (not IsGardening(item.id) and not IsMap(item.id)) then
									Player:Gather(n-1)
									ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
									ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
									return
								end
							end
						else						
							if (item.name == item1) then
								if (IsGardening(item.id) or IsMap(item.id)) then
									ml_error("Use the GatherGardening option for this marker to gather gardening items.")
									ml_error("Use the GatherMaps option for this marker to gather map items.")
									ml_error("Gardening and Map items set to slots will be ignored.")
								end
								if (not IsGardening(item.id) and not IsMap(item.id)) then
									Player:Gather(item.index)
									ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
									ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
									return
								end
							end
						end
					end
				end
				
				if (item2 ~= "") then
					for i, item in pairs(list) do
						local n = tonumber(item2)
						if (n ~= nil) then
							if (item.index == (n-1) and item.id ~= nil) then
								if (IsGardening(item.id) or IsMap(item.id)) then
									ml_error("Use the GatherGardening option for this marker to gather gardening items.")
									ml_error("Use the GatherMaps option for this marker to gather map items.")
									ml_error("Gardening and Map items set to slots will be ignored.")
								end
								if (not IsGardening(item.id) and not IsMap(item.id)) then
									Player:Gather(n-1)
									ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
									ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
									return
								end
							end
						else
							if (item.name == item2) then
								if (IsGardening(item.id) or IsMap(item.id)) then
									ml_error("Use the GatherGardening option for this marker to gather gardening items.")
									ml_error("Use the GatherMaps option for this marker to gather map items.")
									ml_error("Gardening and Map items set to slots will be ignored.")
								end
								if (not IsGardening(item.id) and not IsMap(item.id)) then
									Player:Gather(item.index)
									ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
									ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
									return
								end
							end
						end
					end
				end
			end
			
			-- just grab a random item otherwise
			for i, item in pairs(list) do
				if item.chance > 50 and not IsGardening(item.id) and not IsMap(item.id) then
					if (Player:Gather(item.index)) then
						ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
						return
					end
				end
			end
		end
    else
        local node = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
        if ( node and node.cangather ) then
            local target = Player:GetTarget()
            if ( not ValidTable(target) or (target.id ~= node.id)) then
                Player:SetTarget(node.id)
            else
				Eat()
				if (ValidTable(ml_task_hub:ThisTask().currentMarker)) then
					local profile = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].skillProfile)
					if (profile and profile ~= "None") then
						SkillMgr.UseProfile(profile)
					end
				end
                Player:Interact(node.id)
				ffxiv_task_gather.gatherStarted = true
				ml_task_hub:CurrentTask().interactTimer = Now() + 1000
				ml_task_hub:CurrentTask().gatheredGardening = false
				ml_task_hub:CurrentTask().gatheredMap = false
				ml_task_hub:CurrentTask().rareCount = -1
				ml_task_hub:CurrentTask().mapCount = -1
				ml_task_hub:CurrentTask().swingCount = 0
				ml_task_hub:CurrentTask().itemsUncovered = false
				SkillMgr.prevSkillList = {}
                -- start fail timer
                if (ml_task_hub:CurrentTask().failedTimer == 0) then
                    ml_task_hub:CurrentTask().failedTimer = Now() + 12000
                elseif (Now() > ml_task_hub:CurrentTask().failedTimer) then
					ml_blacklist.AddBlacklistEntry(strings[gCurrentLanguage].gatherMode, node.id, node.name, Now() + 300*1000)
					ml_task_hub:CurrentTask().gatherid = 0
					ml_task_hub:CurrentTask().failedTimer = 0
				end
            end

            if (gTeleport == "1") then
                Player:MoveToStraight(Player.pos.x+2, Player.pos.y, Player.pos.z+2)
            end
        else
            --ml_debug(" EntityList:Get(ml_task_hub:CurrentTask().gatherid) returned no node!")
        end
    end
end

c_gatherwindow = inheritsFrom( ml_cause )
e_gatherwindow = inheritsFrom( ml_effect )
function c_gatherwindow:evaluate()
	local list = Player:GetGatherableSlotList()
    if (list ~= nil and ml_task_hub:CurrentTask().name ~= "LT_GATHER") then
		return true
	end
end
function e_gatherwindow:execute()
	ml_debug(ml_task_hub:CurrentTask().name.." will be terminated to allow gathering to continue.")
end

function ffxiv_task_gather:Init()
    --init ProcessOverWatch cnes
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 25 )
    self:add( ke_dead, self.overwatch_elements)
    
    local ke_stealth = ml_element:create( "Stealth", c_stealth, e_stealth, 23 )
    self:add( ke_stealth, self.overwatch_elements)
	
	local ke_gatherWindow = ml_element:create( "GatherWindow", c_gatherwindow, e_gatherwindow, 20)
	self:add( ke_gatherWindow, self.overwatch_elements)
	
	local ke_findunspoiledNode = ml_element:create( "FindUnspoiledNode", c_findunspoilednode, e_findunspoilednode, 12 )
    self:add(ke_findunspoiledNode, self.overwatch_elements)
	
    --init Process cnes	
    local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 25 )
    self:add( ke_returnToMarker, self.process_elements)
	
	local ke_nextUnspoiledMarker = ml_element:create( "NextUnspoiledMarker", c_nextunspoiledmarker, e_nextunspoiledmarker, 21 )
    self:add( ke_nextUnspoiledMarker, self.process_elements)
    
    local ke_nextMarker = ml_element:create( "NextMarker", c_nextgathermarker, e_nextgathermarker, 20 )
    self:add( ke_nextMarker, self.process_elements)
	
    local ke_findGatherable = ml_element:create( "FindGatherable", c_findgatherable, e_findgatherable, 15 )
    self:add(ke_findGatherable, self.process_elements)
	
	local ke_moveToUnspoiledMarker = ml_element:create( "MoveToUnspoiledMarker", c_movetounspoiledmarker, e_movetounspoiledmarker, 11 )
    self:add( ke_moveToUnspoiledMarker, self.process_elements)
	
    local ke_moveToGatherable = ml_element:create( "MoveToGatherable", c_movetogatherable, e_movetogatherable, 10 )
    self:add( ke_moveToGatherable, self.process_elements)
    
    local ke_gather = ml_element:create( "Gather", c_gather, e_gather, 5 )
    self:add(ke_gather, self.process_elements)
	
	local ke_nextLocation = ml_element:create( "NextLocation", c_nextgatherlocation, e_nextgatherlocation, 4 )
    self:add(ke_nextLocation, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_gather.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gGatherMapID" or
				k == "gGatherMapHour" or
				k == "gGatherMapClass" or
				k == "gGatherMinerGearset" or
				k == "gGatherBotanistGearset" or
				k == "gDoStealth" or
				k == "gGatherMapMarker" or
				k == "gGatherIdleLocation" ) then
			Settings.FFXIVMINION[tostring(k)] = v
		elseif ( k == "gGatherUnspoiled") then
			if (v == "1") then
				ml_marker_mgr.SetMarkerType(GetString("unspoiledMarker"))
			elseif (Player.job == FFXIV.JOBS.BOTANIST) then
				ml_marker_mgr.SetMarkerType(GetString("botanyMarker"))
			else
				ml_marker_mgr.SetMarkerType(GetString("miningMarker"))
			end
            Settings.FFXIVMINION[tostring(k)] = v
		elseif ( k == "gGatherStartLocation") then
			ffxiv_task_gather.location = 0
			Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(GetString("gatherMode"))
end

-- UI settings etc
function ffxiv_task_gather.UIInit()
	
	--Add it to the main tracking table, so that we can save positions for it.
	ffxivminion.Windows.Gather = { id = strings["us"].gatherMode, Name = GetString("gatherMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Gather)

	if (Settings.FFXIVMINION.gGatherUnspoiled == nil) then
		Settings.FFXIVMINION.gGatherUnspoiled = "0"
	end
	
	Settings.FFXIVMINION.gGatherStartLocation = Settings.FFXIVMINION.gGatherStartLocation or ""
	Settings.FFXIVMINION.gGatherMapIdle = Settings.FFXIVMINION.gGatherMapIdle or "0"
	
	if (Settings.FFXIVMINION.gGatherLocations == nil) then
		Settings.FFXIVMINION.gGatherLocations = {}
	end
	if ( Settings.FFXIVMINION.gGatherMapName == nil ) then
		Settings.FFXIVMINION.gGatherMapName = ""
	end
	if ( Settings.FFXIVMINION.gGatherMapMarker == nil ) then
		Settings.FFXIVMINION.gGatherMapMarker = ""
	end
	if ( Settings.FFXIVMINION.gGatherMapHour == nil ) then
		Settings.FFXIVMINION.gGatherMapHour = ""
	end
	if ( Settings.FFXIVMINION.gGatherMapClass == nil ) then
		Settings.FFXIVMINION.gGatherMapClass = "MINER"
	end
	if ( Settings.FFXIVMINION.gGatherMinerGearset == nil ) then
		Settings.FFXIVMINION.gGatherMinerGearset = "1"
	end
	if ( Settings.FFXIVMINION.gGatherBotanistGearset == nil ) then
		Settings.FFXIVMINION.gGatherBotanistGearset = "1"
	end
	if ( Settings.FFXIVMINION.gGatherUseCordials == nil ) then
		Settings.FFXIVMINION.gGatherUseCordials = "1"
	end
	
	local winName = GetString("gatherMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	GUI_NewButton(winName, strings[gCurrentLanguage].markerManager, "ToggleMarkerMgr")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].botMode,"gBotMode",group,"")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].skillProfile,"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,strings[gCurrentLanguage].navmesh ,"gmeshname",group,ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,strings[gCurrentLanguage].botEnabled,"gBotRunning",group)
	GUI_NewField(winName,strings[gCurrentLanguage].markerName,"gStatusMarkerName",group )
	GUI_NewField(winName,strings[gCurrentLanguage].markerTime,"gStatusMarkerTime",group )
	GUI_NewField(winName,strings[gCurrentLanguage].locationName,"gGatherMapLocation",group)
	
	group = GetString("settings")
	GUI_NewCheckbox(winName,strings[gCurrentLanguage].gatherUnspoiled, "gGatherUnspoiled",group)
	GUI_NewCheckbox(winName,strings[gCurrentLanguage].useCordials, "gGatherUseCordials",group)
	GUI_NewComboBox(winName,strings[gCurrentLanguage].startLocation,"gGatherStartLocation",group,"")
	gGatherStartLocation_listitems = ffxiv_task_gather.GetUnspoiledLocations()
	gGatherIdleLocation_listitems = ffxiv_task_gather.GetUnspoiledLocations()
	GUI_NewField(winName,strings[gCurrentLanguage].minerGearset,"gGatherMinerGearset",group )
	GUI_NewField(winName,strings[gCurrentLanguage].botanistGearset,"gGatherBotanistGearset",group )
	--GUI_NewField(winName,strings[gCurrentLanguage].throttle,"gGatherThrottle",group)
	
	group = GetString("newLocation")
	GUI_NewField(winName,strings[gCurrentLanguage].locationName,"gGatherMapName",group)
	GUI_NewButton(winName,strings[gCurrentLanguage].refreshMap,	"ffxiv_gatherRefreshMap",group)
	GUI_NewNumeric(winName,strings[gCurrentLanguage].hour,"gGatherMapHour",group, "0", "23")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].class,"gGatherMapClass",group, "MINER,BOTANIST")	
	GUI_NewComboBox(winName,strings[gCurrentLanguage].markerName,"gGatherMapMarker",group,"")
	gGatherMapMarker_listitems = ffxiv_task_gather.GetUnspoiledMarkers()
	GUI_NewCheckbox(winName,strings[gCurrentLanguage].isIdle,"gGatherMapIdle",group)
	GUI_NewButton(winName,strings[gCurrentLanguage].addLocation,"ffxiv_gatherAddLocation",group)
	
	GUI_UnFoldGroup(winName,GetString("status"))
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	local editWindow = ffxiv_task_gather.editwindow
	GUI_NewWindow(editWindow.name,editWindow.x,editWindow.y,editWindow.width,editWindow.height,"",true)
	winName = editWindow.name
	group = GetString("settings")
	GUI_NewField(winName,strings[gCurrentLanguage].locationName,		"eGatherMapName",group)
	GUI_NewCheckbox(winName,strings[gCurrentLanguage].enabled, 			"eGatherMapEnabled",group)
	GUI_NewButton(winName,strings[gCurrentLanguage].refreshMap,		"ffxiv_gatherRefreshMap",group)
	GUI_NewNumeric(winName,strings[gCurrentLanguage].hour,			"eGatherMapHour",group, "0", "23")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].class,			"eGatherMapClass",group, "MINER,BOTANIST")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].markerName,			"eGatherMapMarker",group,"")
	gGatherMapMarker_listitems = ffxiv_task_gather.GetUnspoiledMarkers()
	GUI_NewCheckbox(winName,strings[gCurrentLanguage].isIdle, 			"eGatherMapIdle",group)
	GUI_NewButton(winName,strings[gCurrentLanguage].saveLocation,		"ffxiv_gatherSaveLocation")
	GUI_NewButton(winName,strings[gCurrentLanguage].removeLocation,	"ffxiv_gatherRemoveLocation")
	GUI_UnFoldGroup(winName,GetString("settings"))
	GUI_SizeWindow(winName, editWindow.width, editWindow.height)
	GUI_WindowVisible(winName, false)
	
	gGatherUnspoiled = Settings.FFXIVMINION.gGatherUnspoiled
	gGatherStartLocation = Settings.FFXIVMINION.gGatherStartLocation
	gGatherLocations = Settings.FFXIVMINION.gGatherLocations
	gGatherMapName = Settings.FFXIVMINION.gGatherMapName
	gGatherMapHour = Settings.FFXIVMINION.gGatherMapHour
	gGatherMapClass = Settings.FFXIVMINION.gGatherMapClass
	gGatherMapMarker = Settings.FFXIVMINION.gGatherMapMarker
	gGatherMapIdle = Settings.FFXIVMINION.gGatherMapIdle
	gGatherMinerGearset = Settings.FFXIVMINION.gGatherMinerGearset
	gGatherBotanistGearset = Settings.FFXIVMINION.gGatherBotanistGearset
	gGatherMapMarker = Settings.FFXIVMINION.gGatherMapMarker
	gGatherUseCordials = Settings.FFXIVMINION.gGatherUseCordials
	--gGatherThrottle = Settings.FFXIVMINION.gGatherThrottle
	
    ffxiv_task_gather.SetupMarkers()
    ffxiv_task_gather.RefreshGatherLocations()
    RegisterEventHandler("GUI.Update",ffxiv_task_gather.GUIVarUpdate)
end

function ffxiv_task_gather.SwitchClass(class)
	class = tonumber(class) or 0
	if (class ~= FFXIV.JOBS.MINER and class ~= FFXIV.JOBS.BOTANIST) then
		return
	end
	
	local commandString = "/gearset change "
	if (FFXIV.JOBS.MINER == class) then
		commandString = commandString..tostring(gGatherMinerGearset)
	elseif (FFXIV.JOBS.BOTANIST == class) then
		commandString = commandString..tostring(gGatherBotanistGearset)
	end
	
	SendTextCommand(commandString)
	ffxiv_task_gather.timer = Now() + 2000
end

function ffxiv_task_gather.LocatorBuff(class)
	class = tonumber(class) or 0
	if (class ~= FFXIV.JOBS.MINER and class ~= FFXIV.JOBS.BOTANIST) then
		return
	end
	
	if (Player.ismounted) then
		Dismount()
		ffxiv_task_gather.timer = Now() + 1000
		return
	end
	
	local actionid = nil
	if (FFXIV.JOBS.MINER == class) then
		actionid = 238
	elseif (FFXIV.JOBS.BOTANIST == class) then
		actionid = 221
	end
	local action = ActionList:Get(actionid)
	if (action and not action.isoncd) then
		d("locator buff, using ability")
		action:Cast()
	end
	ffxiv_task_gather.timer = Now() + 1000
end

function ffxiv_task_gather.SetupMarkers()
    -- add marker templates for gathering
    local botanyMarker = ml_marker:Create("botanyTemplate")
	botanyMarker:SetType(strings[gCurrentLanguage].botanyMarker)
	botanyMarker:ClearFields()
	botanyMarker:AddField("string", strings[gCurrentLanguage].selectItem1, "")
	botanyMarker:AddField("string", strings[gCurrentLanguage].selectItem2, "")
	botanyMarker:AddField("string", strings[gCurrentLanguage].contentIDEquals, "")
	botanyMarker:AddField("button", "Whitelist Target", "")
	botanyMarker:AddField("string", strings[gCurrentLanguage].NOTcontentIDEquals, "")
	botanyMarker:AddField("checkbox", strings[gCurrentLanguage].useStealth, "0")
	botanyMarker:AddField("combobox", strings[gCurrentLanguage].gatherMaps, "Any", "Any,Peisteskin Only,None")
	botanyMarker:AddField("checkbox", strings[gCurrentLanguage].gatherGardening, "1")
	botanyMarker:AddField("combobox", strings[gCurrentLanguage].skillProfile, "None", ffxivminion.Strings.SKMProfiles())
    botanyMarker:SetTime(300)
    botanyMarker:SetMinLevel(1)
    botanyMarker:SetMaxLevel(50)
    ml_marker_mgr.AddMarkerTemplate(botanyMarker)
	
	local miningMarker = ml_marker:Create("miningTemplate")
	miningMarker:SetType(strings[gCurrentLanguage].miningMarker)
	miningMarker:ClearFields()
	miningMarker:AddField("string", strings[gCurrentLanguage].selectItem1, "")
	miningMarker:AddField("string", strings[gCurrentLanguage].selectItem2, "")
	miningMarker:AddField("string", strings[gCurrentLanguage].contentIDEquals, "")
	miningMarker:AddField("button", "Whitelist Target", "")
	miningMarker:AddField("string", strings[gCurrentLanguage].NOTcontentIDEquals, "")
	miningMarker:AddField("checkbox", strings[gCurrentLanguage].useStealth, "0")
	miningMarker:AddField("combobox", strings[gCurrentLanguage].gatherMaps, "Any", "Any,Peisteskin Only,None")
	miningMarker:AddField("checkbox", strings[gCurrentLanguage].gatherGardening, "1")
	miningMarker:AddField("combobox", strings[gCurrentLanguage].skillProfile, "None", ffxivminion.Strings.SKMProfiles())
    miningMarker:SetTime(300)
    miningMarker:SetMinLevel(1)
    miningMarker:SetMaxLevel(50)
    ml_marker_mgr.AddMarkerTemplate(miningMarker)
	
	local unspoiledMarker = ml_marker:Create("unspoiledTemplate")
	unspoiledMarker:SetType(strings[gCurrentLanguage].unspoiledMarker)
	unspoiledMarker:ClearFields()
	unspoiledMarker:AddField("string", strings[gCurrentLanguage].minimumGP, "0")
	unspoiledMarker:AddField("string", strings[gCurrentLanguage].selectItem1, "")
	unspoiledMarker:AddField("string", strings[gCurrentLanguage].selectItem2, "")
	unspoiledMarker:AddField("checkbox", strings[gCurrentLanguage].useStealth, "0")
	unspoiledMarker:AddField("combobox", strings[gCurrentLanguage].gatherMaps, "Any", "Any,Peisteskin Only,None")
	unspoiledMarker:AddField("checkbox", strings[gCurrentLanguage].gatherGardening, "1")
	unspoiledMarker:AddField("combobox", strings[gCurrentLanguage].skillProfile, "None", ffxivminion.Strings.SKMProfiles())
    unspoiledMarker:SetTime(1800)
    unspoiledMarker:SetMinLevel(50)
    unspoiledMarker:SetMaxLevel(50)
    ml_marker_mgr.AddMarkerTemplate(unspoiledMarker)
	
    -- refresh the manager with the new templates
    ml_marker_mgr.RefreshMarkerTypes()
	ml_marker_mgr.RefreshMarkerNames()
end

function ffxiv_task_gather.GetUnspoiledMarkers()
	local list = ml_marker_mgr.GetList(strings[gCurrentLanguage].unspoiledMarker, false)
	local namestring = ""
	if (ValidTable(list)) then
		local markerNameList = GetComboBoxList(list)
		if (markerNameList) then
			namestring = markerNameList["keyList"]
		end
	end
	
	return namestring
end

function ffxiv_task_gather.GetUnspoiledLocations()
	local list = Settings.FFXIVMINION.gGatherLocations
	local namestring = ""
	local order = function( t,a,b ) return (t[a].hour < t[b].hour or (t[a].hour == t[b].hour and t[a].name < t[b].name)) end			
	for k,v in spairs(list,order) do
		if (namestring == "") then
			namestring = k
		else
			namestring = namestring..","..k
		end
	end
	
	return namestring
end

function ffxiv_task_gather.AddGatherLocation()
	local list = Settings.FFXIVMINION.gGatherLocations
	local key = gGatherMapName
	
	--Check to make sure that something hasn't gone wrong with the index and reindex the table if necessary.
	if (list[key]) then
		d("This location already exists, choose a different name.")
		return
	end
	
	local marker = ml_marker_mgr.GetMarker(gGatherMapMarker)
	local markerPos = nil
	if (ValidTable(marker)) then
		markerPos = marker:GetPosition()
	end
		
	local location = {
		name = key,
		enabled = true,
		mapid = Player.localmapid,
		hour = tonumber(gGatherMapHour) or 0,
		class = FFXIV.JOBS[gGatherMapClass],
		mesh = gmeshname,
		marker = gGatherMapMarker,
		lastGather = 0,
		teleport = GetClosestAetheryteToMapIDPos(Player.localmapid, markerPos),
		isIdle = gGatherMapIdle == "1" and true or false,
	}
	
	list[key] = location
	gGatherLocations = list
	Settings.FFXIVMINION.gGatherLocations = gGatherLocations
	ffxiv_task_gather.RefreshGatherLocations()
end

function ffxiv_task_gather.SaveGatherLocation()
	local list = Settings.FFXIVMINION.gGatherLocations
	local key = eGatherMapName
		
	local marker = ml_marker_mgr.GetMarker(eGatherMapMarker)
	local markerPos = nil
	if (ValidTable(marker)) then
		markerPos = marker:GetPosition()
	end
	
	local location = {
		name = eGatherMapName,
		enabled = eGatherMapEnabled == "1" and true or false,
		mapid = Player.localmapid,
		hour = tonumber(eGatherMapHour) or 0,
		class = FFXIV.JOBS[eGatherMapClass],
		mesh = gmeshname,
		marker = eGatherMapMarker,
		lastGather = 0,
		teleport = GetClosestAetheryteToMapIDPos(Player.localmapid, markerPos),
		isIdle = eGatherMapIdle == "1" and true or false,
	}
	
	list[key] = location
	gGatherLocations = list
	Settings.FFXIVMINION.gGatherLocations = gGatherLocations
	GUI_WindowVisible(ffxiv_task_gather.editwindow.name, false)
	ffxiv_task_gather.RefreshGatherLocations()
end

function ffxiv_task_gather.EditGatherLocation(key)
	local list = Settings.FFXIVMINION.gGatherLocations
	
	--Check to make sure that something hasn't gone wrong with the index and reindex the table if necessary.
	if (not list[key]) then
		d("This location doesn't exist.")
		return
	end
	
	ffxiv_task_gather.RefreshMap()
	
	local location = list[key]
	if (ValidTable(location)) then
		eGatherMapName = location.name
		eGatherMapEnabled = (location.enabled == true) and "1" or "0"
		eGatherMapIdle = (location.isIdle == true) and "1" or "0"
		eGatherMapHour = location.hour
		eGatherMapClass = (location.class == FFXIV.JOBS.MINER) and "MINER" or "BOTANIST"
		eGatherMapMarker = location.marker
	else
		d("Location is corrupted, please remove it and start over.")
		return
	end
	
	local window = ffxiv_task_gather.editwindow
	local base = ffxivminion.GetWindowSize(GetString("gatherMode"))
	GUI_MoveWindow(window.name,base.x + base.width,base.y)
	GUI_WindowVisible(window.name, true)
	GUI_RefreshWindow(window.name)
end

function ffxiv_task_gather.RemoveGatherLocation()
	local list = Settings.FFXIVMINION.gGatherLocations
	local key = eGatherMapName
	list[key] = nil
	
	gGatherLocations = list
	Settings.FFXIVMINION.gGatherLocations = gGatherLocations
	GUI_WindowVisible(ffxiv_task_gather.editwindow.name, false)
	ffxiv_task_gather.RefreshGatherLocations()
end

function ffxiv_task_gather.RefreshGatherLocations()
	local winName = ffxivminion.Windows.Gather.Name
	local tabName = "Locations"
	local list = Settings.FFXIVMINION.gGatherLocations
	
	GUI_DeleteGroup(winName,tabName)
	if (TableSize(list) > 0) then
		local order = function( t,a,b ) return (t[a].hour < t[b].hour or (t[a].hour == t[b].hour and t[a].name < t[b].name)) end			
		for k,v in spairs(list,order) do
			GUI_NewButton(winName, k.."["..tostring(v.hour).."]",	"ffxiv_gatherEditLocation"..tostring(k), tabName)
		end
		GUI_UnFoldGroup(winName,tabName)
	end
	
	ffxivminion.SizeWindow(winName)
	GUI_RefreshWindow(winName)
end

function ffxiv_task_gather.RefreshMap()
	local winName = ffxivminion.Windows.Gather.Name
	gGatherMapID = Player.localmapid
	local markerString = ffxiv_task_gather.GetUnspoiledMarkers()
	gGatherMapMarker_listitems = markerString
	eGatherMapMarker_listitems = markerString
	gGatherStartLocation_listitems = ffxiv_task_gather.GetUnspoiledLocations()
	gGatherIdleLocation_listitems = ffxiv_task_gather.GetUnspoiledLocations()
	GUI_RefreshWindow(winName)
end

function ffxiv_task_gather.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" and string.find(Button,"ffxiv_gather") ~= nil ) then
		if (Button == "ffxiv_gatherAddLocation") then
			ffxiv_task_gather.AddGatherLocation()
		end
		if (Button == "ffxiv_gatherRefreshMap") then
			ffxiv_task_gather.RefreshMap()
		end
		if (Button == "ffxiv_gatherSaveLocation") then
			ffxiv_task_gather.SaveGatherLocation()
		end
		if (Button == "ffxiv_gatherRemoveLocation") then
			ffxiv_task_gather.RemoveGatherLocation()
		end
		if (string.find(Button,"ffxiv_gatherEditLocation") ~= nil) then
			local key = Button:gsub("ffxiv_gatherEditLocation","")
			ffxiv_task_gather.EditGatherLocation(key)
		end
	end
end

ffxiv_task_gather.gardening =
{
	[7754] = true,
	[7757] = true,
	[7756] = true,
	[7755] = true,
	[7752] = true,
	[7745] = true,
	[7748] = true,
	[7751] = true,
	[7747] = true,
	[7750] = true,
	[7753] = true,
	[7746] = true,
	[7749] = true,
	[7724] = true,
	[7734] = true,
	[7733] = true,
	[7760] = true,
	[7763] = true,
	[7766] = true,
	[7732] = true,
	[7731] = true,
	[7744] = true,
	[7759] = true,
	[7762] = true,
	[7765] = true,
	[7730] = true,
	[7743] = true,
	[7742] = true,
	[7741] = true,
	[7758] = true,
	[7761] = true,
	[7764] = true,
	[7723] = true,
	[7722] = true,
	[7721] = true,
	[7739] = true,
	[7740] = true,
	[7738] = true,
	[7729] = true,
	[7720] = true,
	[7728] = true,
	[7727] = true,
	[7737] = true,
	[7718] = true,
	[7717] = true,
	[7719] = true,
	[7736] = true,
	[7716] = true,
	[7735] = true,
	[7715] = true,
	[7726] = true,
	[7725] = true,
	[7767] = true,
	[8024] = true,
}        

RegisterEventHandler("GUI.Item",ffxiv_task_gather.HandleButtons)
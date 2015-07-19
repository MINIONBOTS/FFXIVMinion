ffxiv_task_gather = inheritsFrom(ml_task)
ffxiv_task_gather.lastTick = 0
ffxiv_task_gather.lastLocationLoaded = 0
ffxiv_task_gather.name = "LT_GATHER"
ffxiv_task_gather.location = 0
ffxiv_task_gather.unspoiledGathered = true
ffxiv_task_gather.gatherStarted = false
ffxiv_task_gather.timer = 0
ffxiv_task_gather.awaitingSuccess = false
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
	newinst.gatheruniqueid = 0
    newinst.markerTime = 0
    newinst.currentMarker = false
	ml_global_information.currentMarker = false
	
	newinst.pos = 0
    newinst.gatherTimer = 0
	newinst.gatherDistance = 1.5
	newinst.maxGatherDistance = 100 -- for setting the range when the character is beeing considered "too far away from the gathermarker" where it would make him run back to the marker
	newinst.gatheredMap = false
	newinst.gatheredGardening = false
	newinst.gatheredChocoFood = false
	newinst.gatheredIxaliRare = false
    newinst.idleTimer = 0
	newinst.filterLevel = true
	newinst.swingCount = 0
	newinst.itemsUncovered = false
	newinst.slotsTried = {}
	newinst.interactTimer = 0
	newinst.changingLocations = false
	newinst.rareCount = -1
	newinst.rareCount2 = -1
	newinst.rareCount3 = -1
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
	if (Now() < ffxiv_task_gather.timer) then
		return false
	end
	
	if (gGatherUnspoiled == "1" and not ffxiv_task_gather.IsIdleLocation()) then
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
    if (ValidTable(gatherable)) then
        if (not gatherable.cangather) then
            return true 
        end
    elseif (gatherable == nil) then
        return true
    end
    
    return false
end
function e_findgatherable:execute()
	ffxiv_task_gather.gatherStarted = false    
    local gatherable = GetNearestGatherable(ml_global_information.currentMarker)
    if (ValidTable(gatherable)) then
		-- reset blacklist vars for a new node
		ml_task_hub:CurrentTask().failedTimer = 0		
		ml_task_hub:CurrentTask().gatheredMap = false
        ml_task_hub:CurrentTask().gatherid = gatherable.id
		ml_task_hub:CurrentTask().gatheruniqueid = gatherable.uniqueid
    end
	
	--idiotcheck for no usable markers found on this mesh
	--if (ml_task_hub:CurrentTask().currentMarker ~= nil and ml_task_hub:CurrentTask().currentMarker ~= 0 and ml_task_hub:CurrentTask().currentMarker == false) then
        --if not (gGatherUnspoiled == "1" and ffxiv_task_gather.IsIdleLocation()) then
			--ml_error("THE LOADED NAVMESH HAS NO MINING/BOTANY MARKERS IN THE LEVELRANGE OF YOUR PLAYER")
		--end
	--end
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
    if (list) then
        return false
    end
	
	if (ffxiv_task_gather.unspoiledGathered or gGatherUnspoiled == "0" or not ValidTable(ffxiv_task_gather.location)) then
		return false
	end
	
	if (ffxiv_task_gather.location.isIdle) then
		return false
	end
	
	--Make sure we're within 50 yards of the marker before we start searching for the node.
	if (not ValidTable(ml_task_hub:ThisTask().currentMarker)) then
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
		if (gatherable and gatherable.cangather) then
			e_findunspoilednode.pos = shallowcopy(gatherable.pos)
            return true
        end
    end

    return false
end
function e_findunspoilednode:execute()
   local pos = e_findunspoilednode.pos	
    if (ValidTable(pos)) then
		local ppos = shallowcopy(Player.pos)
		local dist3d = Distance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
		ml_task_hub:ThisTask().pos = pos
		if (gTeleport == "1" and dist3d > 10 and ShouldTeleport(pos)) then
			local eh = ConvertHeading(pos.h)
			local nodeFront = ConvertHeading((eh + (math.pi)))%(2*math.pi)
			local telePos = GetPosFromDistanceHeading(pos, 5, nodeFront)
			local p,dist = NavigationManager:GetClosestPointOnMesh(telePos,false)
			if (dist < 5) then
				GameHacks:TeleportToXYZ(tonumber(p.x),tonumber(p.y),tonumber(p.z))
				Player:SetFacing(pos.x,pos.y,pos.z)
				return
			end
		end
		
		local newTask = ffxiv_task_movetointeract.Create()
		newTask.pos = pos
		newTask.interact = ml_task_hub:CurrentTask().gatherid
		newTask.use3d = true
		newTask.useTeleport = false
		newTask.interactRange = 3
		newTask.pathRange = 5
		newTask.task_complete_execute = function()
			Player:Stop()
			ffxiv_task_gather.gatherStarted = true
			ffxiv_task_gather.timer = Now() + 500
			ml_task_hub:CurrentTask():ParentTask().interactTimer = Now() + 1000
			ml_task_hub:CurrentTask():ParentTask().failedTimer = Now()
			ml_task_hub:CurrentTask():ParentTask().gatheredGardening = false
			ml_task_hub:CurrentTask():ParentTask().gatheredMap = false
			ml_task_hub:CurrentTask():ParentTask().gatheredChocoFood = false
			ml_task_hub:CurrentTask():ParentTask().rareCount = -1
			ml_task_hub:CurrentTask():ParentTask().rareCount2 = -1
			ml_task_hub:CurrentTask():ParentTask().mapCount = -1
			ml_task_hub:CurrentTask():ParentTask().swingCount = 0
			ml_task_hub:CurrentTask():ParentTask().itemsUncovered = false
			SkillMgr.prevSkillList = {}
			ml_task_hub:ThisTask().completed = true
		end
		ml_task_hub:CurrentTask():AddSubTask(newTask)	
    end
end

c_movetounspoiledmarker = inheritsFrom( ml_cause )
e_movetounspoiledmarker = inheritsFrom( ml_effect )
function c_movetounspoiledmarker:evaluate()
	if (Now() < ffxiv_task_gather.timer) then
		return false
	end
	
	--Check that we have a proper location, that we haven't already gathered here, and that we haven't already found the node and that there is a valid marker.
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
		newTask.destination = "UNSPOILED_MARKER"
		newTask.range = 1.5
		newTask.use3d = true
		newTask.remainMounted = true
		ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

c_movetogatherable = inheritsFrom( ml_cause )
e_movetogatherable = inheritsFrom( ml_effect )
function c_movetogatherable:evaluate()
	if (Now() < ffxiv_task_gather.timer) then
		return false
	end
	
	if (gGatherUnspoiled == "1" and not ffxiv_task_gather.IsIdleLocation()) then
		return false
	end
	
	local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
        return false
    end
	
    if ( TimeSince(ml_task_hub:CurrentTask().gatherTimer) < 1500 ) then
        return false
    end
    
    if ( ml_task_hub:CurrentTask().gatherid ~= nil and ml_task_hub:CurrentTask().gatherid ~= 0 ) then
        local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
        if (gatherable and gatherable.cangather) then
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
		--local newTask = ffxiv_task_movetopos.Create()
		local ppos = shallowcopy(Player.pos)
		local dist3d = Distance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
		if (gTeleport == "1" and dist3d > 10 and ShouldTeleport(pos)) then
			local eh = ConvertHeading(pos.h)
			local nodeFront = ConvertHeading((eh + (math.pi)))%(2*math.pi)
			local telePos = GetPosFromDistanceHeading(pos, 5, nodeFront)
			local p,dist = NavigationManager:GetClosestPointOnMesh(telePos,false)
			if (dist < 5) then
				GameHacks:TeleportToXYZ(tonumber(p.x),tonumber(p.y),tonumber(p.z))
				Player:SetFacing(pos.x,pos.y,pos.z)
				return
			end
		end
		
		local newTask = ffxiv_task_movetointeract.Create()
		newTask.pos = pos
		newTask.useTeleport = false
		newTask.interact = ml_task_hub:CurrentTask().gatherid
		newTask.use3d = true
		newTask.interactRange = 3
		newTask.pathRange = 5
		newTask.task_complete_execute = function()
			Player:Stop()
			ffxiv_task_gather.gatherStarted = true
			ffxiv_task_gather.timer = Now() + 500
			ml_task_hub:CurrentTask():ParentTask().interactTimer = Now() + 1000
			ml_task_hub:CurrentTask():ParentTask().failedTimer = Now()
			ml_task_hub:CurrentTask():ParentTask().gatheredGardening = false
			ml_task_hub:CurrentTask():ParentTask().gatheredMap = false
			ml_task_hub:CurrentTask():ParentTask().gatheredChocoFood = false
			ml_task_hub:CurrentTask():ParentTask().rareCount = -1
			ml_task_hub:CurrentTask():ParentTask().rareCount2 = -1
			ml_task_hub:CurrentTask():ParentTask().mapCount = -1
			ml_task_hub:CurrentTask():ParentTask().swingCount = 0
			ml_task_hub:CurrentTask():ParentTask().itemsUncovered = false
			SkillMgr.prevSkillList = {}
			ml_task_hub:ThisTask().completed = true
		end
		ml_task_hub:CurrentTask():AddSubTask(newTask)	
    end
end

c_unspoiledprep = inheritsFrom( ml_cause )
e_unspoiledprep = inheritsFrom( ml_effect )
c_unspoiledprep.switchclass = false
c_unspoiledprep.dobuff = false
c_unspoiledprep.timer = 0
function c_unspoiledprep:evaluate()
	--Reset tempvars.
	c_unspoiledprep.switchclass = false
	c_unspoiledprep.dobuff = false

	if ( ffxiv_task_gather.unspoiledGathered or not ValidTable(ffxiv_task_gather.location) or gGatherUnspoiled == "0") then
        return false
    end
	
	--Do another class and buff check, incase we started on the map and didn't teleport.
	if (Player.job ~= ffxiv_task_gather.location.class) then
		c_unspoiledprep.switchclass = true
		return true
	end
	
	if (not ffxiv_task_gather.IsIdleLocation()) then
		if (MissingBuffs(Player,"221+222")) then
			c_unspoiledprep.dobuff = true
			return true
		end
	end
end
function e_unspoiledprep:execute()
	if (Now() < c_unspoiledprep.timer) then
		return
	end
	
	if (c_unspoiledprep.switchclass) then
		ffxiv_task_gather.SwitchClass(ffxiv_task_gather.location.class)
		c_unspoiledprep.timer = Now() + 1500
	end
	
	if (c_unspoiledprep.dobuff) then
		ffxiv_task_gather.LocatorBuff(ffxiv_task_gather.location.class)
		c_unspoiledprep.timer = Now() + 1500
	end
end

c_nextunspoiledmarker = inheritsFrom( ml_cause )
e_nextunspoiledmarker = inheritsFrom( ml_effect )
e_nextunspoiledmarker.marker = nil
function c_nextunspoiledmarker:evaluate()
	if (Now() < ffxiv_task_gather.timer) then
		return false
	end
	
	--Make sure we're supposed to be gathering unspoiled, and that we have a proper location table, that we haven't already gathered, and that the currentMarker is set to false.
	if (gGatherUnspoiled == "0" or not ValidTable(ffxiv_task_gather.location) or ffxiv_task_gather.unspoiledGathered or 
		ml_task_hub:ThisTask().currentMarker ~= false or ml_task_hub:ThisTask().gatherid ~= 0) then
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
	if (ValidTable(marker) and ml_task_hub:ThisTask().currentMarker ~= marker) then
		e_nextunspoiledmarker.marker = marker
		return true
	end
    
    return false
end
function e_nextunspoiledmarker:execute()
	ml_global_information.currentMarker = e_nextunspoiledmarker.marker
    ml_task_hub:ThisTask().currentMarker = e_nextunspoiledmarker.marker
    ml_task_hub:ThisTask().markerTime = Now() + (ml_task_hub:ThisTask().currentMarker:GetTime() * 1000)
	ml_global_information.MarkerTime = Now() + (ml_task_hub:ThisTask().currentMarker:GetTime() * 1000)
    ml_global_information.MarkerMinLevel = ml_task_hub:ThisTask().currentMarker:GetMinLevel()
    ml_global_information.MarkerMaxLevel = ml_task_hub:ThisTask().currentMarker:GetMaxLevel()
	gStatusMarkerName = ml_task_hub:ThisTask().currentMarker:GetName()
end

c_nextgathermarker = inheritsFrom( ml_cause )
e_nextgathermarker = inheritsFrom( ml_effect )
function c_nextgathermarker:evaluate()
	if (Now() < ffxiv_task_gather.timer or IsLoading() or ml_mesh_mgr.meshLoading) then
		return false
	end
	
	--Check to make sure we have gathered any unspoiled nodes first.
	if (gGatherUnspoiled == "1") then
		if (not ffxiv_task_gather.IsIdleLocation()) then
			return false
		else
			if (Player.job ~= ffxiv_task_gather.location.class) then
				ffxiv_task_gather.SwitchClass(ffxiv_task_gather.location.class)
				return false
			end
		end
	end
	
    local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
        return false
    end
	
	if (gMarkerMgrMode == GetString("singleMarker")) then
		ml_task_hub:ThisTask().filterLevel = false
	else
		ml_task_hub:ThisTask().filterLevel = true
	end
    
    if ( ml_task_hub:ThisTask().currentMarker ~= nil and ml_task_hub:ThisTask().currentMarker ~= 0 ) then
        local marker = nil
        
        -- first check to see if we have no initialized marker
        if (ml_task_hub:ThisTask().currentMarker == false) then --default init value
            local markerType = ""
            if (Player.job == FFXIV.JOBS.BOTANIST) then
                markerType = GetString("botanyMarker")
            else
                markerType = GetString("miningMarker")
            end
            marker = ml_marker_mgr.GetNextMarker(markerType, ml_task_hub:ThisTask().filterLevel)
			
			if (marker == nil) then
				if (gGatherUnspoiled ~= "1") then
					d("Currently no appropriate markers found in our level range.")
					return false
				end
			end
        end
        
        -- next check to see if our level is out of range
		if (gMarkerMgrMode ~= GetString("singleMarker")) then
			if (marker == nil) then
				if (ValidTable(ml_task_hub:ThisTask().currentMarker)) then
					if 	(ml_task_hub:ThisTask().filterLevel) and
						(Player.level < ml_task_hub:ThisTask().currentMarker:GetMinLevel() or 
						Player.level > ml_task_hub:ThisTask().currentMarker:GetMaxLevel()) 
					then
						marker = ml_marker_mgr.GetNextMarker(markerType, ml_task_hub:ThisTask().filterLevel)
					end
				end
			end
			
			if (gMarkerMgrMode == GetString("markerTeam")) then
				local gatherid = ml_task_hub:CurrentTask().gatherid
				if (gatherid == 0) then
					marker = ml_marker_mgr.GetNextMarker(markerType, ml_task_hub:ThisTask().filterLevel)
				end
			end
			
			-- last check if our time has run out
			if (gMarkerMgrMode == GetString("markerList")) then
				if (marker == nil) then
					if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then
						local expireTime = ml_task_hub:ThisTask().markerTime
						if (Now() > expireTime) then
							ml_debug("Getting Next Marker, TIME IS UP!")
							marker = ml_marker_mgr.GetNextMarker(markerType, ml_task_hub:ThisTask().filterLevel)
						else
							return false
						end
					end
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
	Player:Stop()
	ml_global_information.currentMarker = e_nextgathermarker.marker
    ml_task_hub:ThisTask().currentMarker = e_nextgathermarker.marker
    ml_task_hub:ThisTask().markerTime = Now() + (ml_task_hub:ThisTask().currentMarker:GetTime() * 1000)
	ml_global_information.MarkerTime = Now() + (ml_task_hub:ThisTask().currentMarker:GetTime() * 1000)
    ml_global_information.MarkerMinLevel = ml_task_hub:ThisTask().currentMarker:GetMinLevel()
    ml_global_information.MarkerMaxLevel = ml_task_hub:ThisTask().currentMarker:GetMaxLevel()
	ml_global_information.BlacklistContentID = ml_task_hub:ThisTask().currentMarker:GetFieldValue(GetString("NOTcontentIDEquals"))
    ml_global_information.WhitelistContentID = ml_task_hub:ThisTask().currentMarker:GetFieldValue(GetString("contentIDEquals"))
	gStatusMarkerName = ml_task_hub:ThisTask().currentMarker:GetName()
end

c_nextgatherlocation = inheritsFrom( ml_cause )
e_nextgatherlocation = inheritsFrom( ml_effect )
c_nextgatherlocation.location = {}
function c_nextgatherlocation:evaluate()
	if (Now() < ffxiv_task_gather.timer) then
		return false
	end
	
	if (IsPositionLocked()) then
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
			local gatherableWindow = {
				[SubtractHours(ffxiv_task_gather.location.hour,1)] = true,
				[ffxiv_task_gather.location.hour] = true,
				[AddHours(ffxiv_task_gather.location.hour,1)] = true,
				[AddHours(ffxiv_task_gather.location.hour,2)] = true,
			}
			
			local overdue = true
			if (gatherableWindow[eTime.hour]) then
				overdue = false
			end
			
			if (ffxiv_task_gather.gatherStarted or overdue) then
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
		
		local mapID = tonumber(location.mapid)
		local nextMesh = Settings.minionlib.DefaultMaps[mapID]		
		local newMarkerPos = GetOffMapMarkerPos(nextMesh, location.marker)
		
		local newTask = ffxiv_task_movetomap.Create()
		if (newMarkerPos ~= nil) then 
			newTask.pos = newMarkerPos
		end
		newTask.destMapID = mapID
		ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
	else
		ffxiv_task_gather.location = location
		gGatherMapLocation = location.name
		ffxiv_task_gather.unspoiledGathered = false
		ffxiv_task_gather.gatherStarted = false
	end
end

c_gather = inheritsFrom( ml_cause )
e_gather = inheritsFrom( ml_effect )
function c_gather:evaluate()
	if (Now() < ffxiv_task_gather.timer) then
		return false
	end
	
	local closestNode = EntityList("nearest,gatherable,maxdistance=10")
	if (closestNode) then
		local i, node = next(closestNode)
		if (not node) then
			return false
		end
	end
		
    local list = Player:GetGatherableSlotList()
	if (list) then
		if (Player:IsMoving()) then
			Player:Stop()
		end
		return true
	end
	
    return false
end
function e_gather:execute()
	if (Player.ismounted) then
		Dismount()
		return
	end
	
    local list = Player:GetGatherableSlotList()
    if (list ~= nil) then

		local thisNode = nil
		local closestNode = EntityList("nearest,gatherable,maxdistance=10")
		if (closestNode) then
			local i, node = next(closestNode)
			if (node) then
				thisNode = node
			end
		end
		
		if (ActionList:IsCasting()) then return end
		
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
		
				local itemsVisible = ml_task_hub:CurrentTask().itemsUncovered or not IsUnspoiled(thisNode.contentid)
				if (itemsVisible and TimeSince(ml_task_hub:CurrentTask().failedTimer) < 5000) then
					-- first try to get treasure maps
					local gatherMaps = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(GetString("gatherMaps"))
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
										local itemCount = ItemCount(item.id)
										if (ml_task_hub:CurrentTask().mapCount == -1) then
											ml_task_hub:CurrentTask().mapCount = itemCount
										end
										if (itemCount == ml_task_hub:CurrentTask().mapCount) then
											if (SkillMgr.Gather(item)) then
												ml_task_hub:CurrentTask().failedTimer = Now()
												ffxiv_task_gather.timer = Now() + 2000
												return
											end
		
											local result = Player:Gather(item.index)
											if (result == 65536) then
												ffxiv_task_gather.timer = Now() + 300
												ffxiv_task_gather.awaitingSuccess = true
												return
											elseif (result == 0 and ffxiv_task_gather.awaitingSuccess) then
												ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
												ml_task_hub:CurrentTask().gatherTimer = Now()
												ml_task_hub:CurrentTask().failedTimer = Now()
												ffxiv_task_gather.timer = Now() + 750
												ffxiv_task_gather.awaitingSuccess = false
												return
											end
										elseif (itemCount > ml_task_hub:CurrentTask().mapCount) then
											ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
											ml_task_hub:CurrentTask().gatheredMap = true
											ml_task_hub:CurrentTask().gatherTimer = Now()
										end
									end
								end
							end
						end
					end
					
					-- second try to get gardening supplies
					local gatherGardening = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(GetString("gatherGardening"))
					if (not ml_task_hub:CurrentTask().gatheredGardening and gatherGardening == "1") then
						for i, item in pairs(list) do
							if 	(IsGardening(item.id)) then
								local itemCount = ItemCount(item.id)
								if (ml_task_hub:CurrentTask().rareCount == -1) then
									ml_task_hub:CurrentTask().rareCount = itemCount
								end
								if (itemCount == ml_task_hub:CurrentTask().rareCount) then
									if (SkillMgr.Gather(item)) then
										ml_task_hub:CurrentTask().failedTimer = Now()
										ffxiv_task_gather.timer = Now() + 2000
										return
									end
									
									local result = Player:Gather(item.index)
									if (result == 65536) then
										ffxiv_task_gather.timer = Now() + 300
										ffxiv_task_gather.awaitingSuccess = true
									elseif (result == 0 and ffxiv_task_gather.awaitingSuccess) then
										ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
										ml_task_hub:CurrentTask().gatherTimer = Now()
										ml_task_hub:CurrentTask().failedTimer = Now()
										ffxiv_task_gather.timer = Now() + 750
										ffxiv_task_gather.awaitingSuccess = false
									end
									return
								elseif (itemCount > ml_task_hub:CurrentTask().rareCount) then
									ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
									ml_task_hub:CurrentTask().gatheredGardening = true
									ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
								end
							end
						end
					end
					
					-- Check for rare ixali items.
					for i, item in pairs(list) do
						if (IsIxaliRare(item.id)) then
							local itemCount = ItemCount(item.id)
							if (itemCount < 5) then
								if (ml_task_hub:CurrentTask().rareCount3 == -1) then
									ml_task_hub:CurrentTask().rareCount3 = itemCount
								end
								if (itemCount == ml_task_hub:CurrentTask().rareCount) then
									if (SkillMgr.Gather(item)) then
										ml_task_hub:CurrentTask().failedTimer = Now()
										ffxiv_task_gather.timer = Now() + 2000
										return
									end
									
									local result = Player:Gather(item.index)
									ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
									ml_task_hub:CurrentTask().gatherTimer = Now()
									ml_task_hub:CurrentTask().failedTimer = Now()
									ffxiv_task_gather.timer = Now() + 3000
									return
								elseif (itemCount > ml_task_hub:CurrentTask().rareCount3) then
									ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
									ml_task_hub:CurrentTask().gatheredIxaliRare = true
									ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
								end
							end
						end
					end
					
					-- third pass to get chocobo items
					local gatherChocoFood = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(GetString("gatherChocoFood"))
					if (not ml_task_hub:CurrentTask().gatheredChocoFood and gatherChocoFood == "1") then
						for i, item in pairs(list) do
							if (IsChocoboFoodSpecial(item.id)) then
								local itemCount = ItemCount(item.id)
								if (ml_task_hub:CurrentTask().rareCount2 == -1) then
									ml_task_hub:CurrentTask().rareCount2 = itemCount
								end
								if (itemCount == ml_task_hub:CurrentTask().rareCount2) then
									if (SkillMgr.Gather(item)) then
										ml_task_hub:CurrentTask().failedTimer = Now()
										ffxiv_task_gather.timer = Now() + 2000
										return
									end
											
									local result = Player:Gather(item.index)
									if (result == 65536) then
										ffxiv_task_gather.timer = Now() + 300
										ffxiv_task_gather.awaitingSuccess = true
										--return
									elseif (result == 0 and ffxiv_task_gather.awaitingSuccess) then
										ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
										ml_task_hub:CurrentTask().gatherTimer = Now()
										ml_task_hub:CurrentTask().failedTimer = Now()
										ffxiv_task_gather.timer = Now() + 750
										ffxiv_task_gather.awaitingSuccess = false
										--return
									end
									return
								elseif (itemCount > ml_task_hub:CurrentTask().rareCount2) then
									ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
									ml_task_hub:CurrentTask().gatheredChocoFood = true
									ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
								end
							elseif (IsChocoboFood(item.id)) then
								if (SkillMgr.Gather(item)) then
									ml_task_hub:CurrentTask().failedTimer = Now()
									ffxiv_task_gather.timer = Now() + 2000
									return
								end
										
								local result = Player:Gather(item.index)
								if (result == 65536) then
									ffxiv_task_gather.timer = Now() + 300
									ffxiv_task_gather.awaitingSuccess = true
									--return
								elseif (result == 0 and ffxiv_task_gather.awaitingSuccess) then
									ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
									ml_task_hub:CurrentTask().gatherTimer = Now()
									ml_task_hub:CurrentTask().failedTimer = Now()
									ffxiv_task_gather.timer = Now() + 750
									ffxiv_task_gather.awaitingSuccess = false
									--return
								end
								return
							end
						end
					end
				end
				
				-- Gather unknown items to unlock them.
				if (Player.level < 60) then
					for i,item in pairs(list) do
						if (item.isunknown) then
							if ((not IsChocoboFood(item.id) or (IsChocoboFood(item.id) and not ml_task_hub:CurrentTask().gatheredChocoFood)) and
								(not IsMap(item.id) or (IsMap(item.id) and not ml_task_hub:CurrentTask().gatheredMap)) and
								(not IsGardening(item.id) or (IsGardening(item.id) and not ml_task_hub:CurrentTask().gatheredGardening)))
							then
								if (SkillMgr.Gather(item)) then
									ml_task_hub:CurrentTask().failedTimer = Now()
									ffxiv_task_gather.timer = Now() + 2000
									return
								end
										
								local result = Player:Gather(item.index)
								if (result == 65536) then
									ffxiv_task_gather.timer = Now() + 300
									ffxiv_task_gather.awaitingSuccess = true
									--return
								elseif (result == 0 and ffxiv_task_gather.awaitingSuccess) then
									if (IsChocoboFood(item.id)) then
										ml_task_hub:CurrentTask().gatheredChocoFood = true
									elseif (IsGardening(item.id)) then
										ml_task_hub:CurrentTask().gatheredGardening = true
									elseif (IsMap(item.id)) then
										ml_task_hub:CurrentTask().gatheredMap = true
									end
									
									ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
									ml_task_hub:CurrentTask().gatherTimer = Now()
									ml_task_hub:CurrentTask().failedTimer = Now()
									ffxiv_task_gather.timer = Now() + 750
									ffxiv_task_gather.awaitingSuccess = false
									--return
								end
								return
							end
						end
					end
				end
			
				-- do 2 loops to allow prioritization of first item
				local item1 = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(GetString("selectItem1"))
				local item2 = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(GetString("selectItem2"))
				
				if (item1 ~= "") then
					for i, item in pairs(list) do
						local n = tonumber(item1)
						if (n ~= nil) then
							if (n > 8) then
								if (item.id == id) then
									if (IsGardening(item.id) or IsMap(item.id) or IsChocoboFood(item.id)) then
										ml_error("Use the GatherGardening option for this marker to gather gardening items.")
										ml_error("Use the GatherMaps option for this marker to gather map items.")
										ml_error("Gardening and Map items set to slots will be ignored.")
									end
									if (not IsGardening(item.id) and not IsMap(item.id) and not IsChocoboFood(item.id) and 
										(not IsIxaliSemiRare(item.id) or (IsIxaliSemiRare(item.id) and ItemCount(item.id) < 15))) 
									then
										if (SkillMgr.Gather(item)) then
											ml_task_hub:CurrentTask().failedTimer = Now()
											ffxiv_task_gather.timer = Now() + 2000
											return
										end
										
										local result = Player:Gather(item.index)
										ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
										ml_task_hub:CurrentTask().gatherTimer = Now()
										ml_task_hub:CurrentTask().failedTimer = Now()
										ffxiv_task_gather.timer = Now() + 3000
										return
									end
								end
							else
								if (item.index == (n-1) and item.id ~= nil) then
									if (IsGardening(item.id) or IsMap(item.id) or IsChocoboFood(item.id)) then
										ml_error("Use the GatherGardening option for this marker to gather gardening items.")
										ml_error("Use the GatherMaps option for this marker to gather map items.")
										ml_error("Gardening and Map items set to slots will be ignored.")
									end
									if (not IsGardening(item.id) and not IsMap(item.id) and not IsChocoboFood(item.id)) then
										if (SkillMgr.Gather(item)) then
											ml_task_hub:CurrentTask().failedTimer = Now()
											ffxiv_task_gather.timer = Now() + 2000
											return
										end
										
										local result = Player:Gather(n-1)
										if (result == 65536) then
											--d("Gathering item priority 1.")
											ffxiv_task_gather.timer = Now() + 300
											ffxiv_task_gather.awaitingSuccess = true
											--return
										elseif (result == 0 and ffxiv_task_gather.awaitingSuccess) then
											ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
											ml_task_hub:CurrentTask().gatherTimer = Now()
											ml_task_hub:CurrentTask().failedTimer = Now()
											ffxiv_task_gather.timer = Now() + 750
											ffxiv_task_gather.awaitingSuccess = false
											--return
										end
										return
									end
								end
							end
						else						
							if (item.name == item1) then
								if (IsGardening(item.id) or IsMap(item.id) or IsChocoboFood(item.id)) then
									ml_error("Use the GatherGardening option for this marker to gather gardening items.")
									ml_error("Use the GatherMaps option for this marker to gather map items.")
									ml_error("Gardening and Map items set to slots will be ignored.")
								end
								if (not IsGardening(item.id) and not IsMap(item.id) and not IsChocoboFood(item.id)) then
									if (SkillMgr.Gather(item)) then
										ml_task_hub:CurrentTask().failedTimer = Now()
										ffxiv_task_gather.timer = Now() + 2000
										return
									end
							
									local result = Player:Gather(item.index)
									if (result == 65536) then
										--d("Gathering item priority 1.")
										ffxiv_task_gather.timer = Now() + 300
										ffxiv_task_gather.awaitingSuccess = true
										--return
									elseif (result == 0 and ffxiv_task_gather.awaitingSuccess) then
										ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
										ml_task_hub:CurrentTask().gatherTimer = Now()
										ml_task_hub:CurrentTask().failedTimer = Now()
										ffxiv_task_gather.timer = Now() + 750
										ffxiv_task_gather.awaitingSuccess = false
										--return
									end
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
							if (n > 8) then
								if (item.id == id) then
									if (IsGardening(item.id) or IsMap(item.id) or IsChocoboFood(item.id)) then
										ml_error("Use the GatherGardening option for this marker to gather gardening items.")
										ml_error("Use the GatherMaps option for this marker to gather map items.")
										ml_error("Gardening and Map items set to slots will be ignored.")
									end
									if (not IsGardening(item.id) and not IsMap(item.id) and not IsChocoboFood(item.id) and 
										(not IsIxaliSemiRare(item.id) or (IsIxaliSemiRare(item.id) and ItemCount(item.id) < 15))) 
									then
										if (SkillMgr.Gather(item)) then
											ml_task_hub:CurrentTask().failedTimer = Now()
											ffxiv_task_gather.timer = Now() + 2000
											return
										end
								
										local result = Player:Gather(item.index)
										ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
										ml_task_hub:CurrentTask().gatherTimer = Now()
										ml_task_hub:CurrentTask().failedTimer = Now()
										ffxiv_task_gather.timer = Now() + 3000
									end
								end
							else
								if (item.index == (n-1) and item.id ~= nil) then
									if (IsGardening(item.id) or IsMap(item.id) or IsChocoboFood(item.id)) then
										ml_error("Use the GatherGardening option for this marker to gather gardening items.")
										ml_error("Use the GatherMaps option for this marker to gather map items.")
										ml_error("Gardening and Map items set to slots will be ignored.")
									end
									if (not IsGardening(item.id) and not IsMap(item.id) and not IsChocoboFood(item.id)) then
										if (SkillMgr.Gather(item)) then
											ml_task_hub:CurrentTask().failedTimer = Now()
											ffxiv_task_gather.timer = Now() + 2000
											return
										end
								
										local result = Player:Gather(n-1)
										if (result == 65536) then
											--d("Gathering item priority 2.")
											ffxiv_task_gather.timer = Now() + 300
											ffxiv_task_gather.awaitingSuccess = true
											--return
										elseif (result == 0 and ffxiv_task_gather.awaitingSuccess) then
											ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
											ml_task_hub:CurrentTask().gatherTimer = Now()
											ml_task_hub:CurrentTask().failedTimer = Now()
											ffxiv_task_gather.timer = Now() + 750
											ffxiv_task_gather.awaitingSuccess = false
											--return
										end
										return
									end
								end
							end
						else
							if (item.name == item2) then
								if (IsGardening(item.id) or IsMap(item.id) or IsChocoboFood(item.id)) then
									ml_error("Use the GatherGardening option for this marker to gather gardening items.")
									ml_error("Use the GatherMaps option for this marker to gather map items.")
									ml_error("Gardening and Map items set to slots will be ignored.")
								end
								if (not IsGardening(item.id) and not IsMap(item.id) and not IsChocoboFood(item.id)) then
									if (SkillMgr.Gather(item)) then
										ml_task_hub:CurrentTask().failedTimer = Now()
										ffxiv_task_gather.timer = Now() + 2000
										return
									end
							
									local result = Player:Gather(item.index)
									if (result == 65536) then
										--d("Gathering item priority 2.")
										ffxiv_task_gather.timer = Now() + 300
										ffxiv_task_gather.awaitingSuccess = true
										--return
									elseif (result == 0 and ffxiv_task_gather.awaitingSuccess) then
										ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
										ml_task_hub:CurrentTask().gatherTimer = Now()
										ml_task_hub:CurrentTask().failedTimer = Now()
										ffxiv_task_gather.timer = Now() + 750
										ffxiv_task_gather.awaitingSuccess = false
										--return
									end
									return
								end
							end
						end
					end
				end
				
				-- Gather unknown items to unlock them.
				for i,item in pairs(list) do
					if (item.isunknown or (IsUnspoiled(thisNode.contentid) and item.chance == 25 and (item.name == "" or item.name == nil))) then
						if ((not IsChocoboFood(item.id) or (IsChocoboFood(item.id) and not ml_task_hub:CurrentTask().gatheredChocoFood)) and
							(not IsMap(item.id) or (IsMap(item.id) and not ml_task_hub:CurrentTask().gatheredMap)) and
							(not IsGardening(item.id) or (IsGardening(item.id) and not ml_task_hub:CurrentTask().gatheredGardening)))
						then
							if (SkillMgr.Gather(item)) then
								ml_task_hub:CurrentTask().failedTimer = Now()
								ffxiv_task_gather.timer = Now() + 2000
								return
							end
									
							local result = Player:Gather(item.index)
							if (result == 65536) then
								--d("Gathering unknown item after failing item priorities.")
								ffxiv_task_gather.timer = Now() + 300
								ffxiv_task_gather.awaitingSuccess = true
								--return
							elseif (result == 0 and ffxiv_task_gather.awaitingSuccess) then
								if (IsChocoboFood(item.id)) then
									ml_task_hub:CurrentTask().gatheredChocoFood = true
								elseif (IsGardening(item.id)) then
									ml_task_hub:CurrentTask().gatheredGardening = true
								elseif (IsMap(item.id)) then
									ml_task_hub:CurrentTask().gatheredMap = true
								end
								
								ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
								ml_task_hub:CurrentTask().gatherTimer = Now()
								ml_task_hub:CurrentTask().failedTimer = Now()
								ffxiv_task_gather.timer = Now() + 750
								ffxiv_task_gather.awaitingSuccess = false
								--return
							end
							return
						end
					end
				end
			end
			
			-- Gather unknown items to unlock them.
			for i,item in pairs(list) do
				if (item.isunknown or (IsUnspoiled(thisNode.contentid) and item.chance == 25 and (item.name == "" or item.name == nil))) then
					if ((not IsChocoboFood(item.id) or (IsChocoboFood(item.id) and not ml_task_hub:CurrentTask().gatheredChocoFood)) and
						(not IsMap(item.id) or (IsMap(item.id) and not ml_task_hub:CurrentTask().gatheredMap)) and
						(not IsGardening(item.id) or (IsGardening(item.id) and not ml_task_hub:CurrentTask().gatheredGardening)))
					then
						if (SkillMgr.Gather(item)) then
							ml_task_hub:CurrentTask().failedTimer = Now()
							ffxiv_task_gather.timer = Now() + 2000
							return
						end
								
						local result = Player:Gather(item.index)
						if (result == 65536) then
							--d("Gathering unknown item in non-marker section.")
							ffxiv_task_gather.timer = Now() + 300
							ffxiv_task_gather.awaitingSuccess = true
							--return
						elseif (result == 0 and ffxiv_task_gather.awaitingSuccess) then
							if (IsChocoboFood(item.id)) then
								ml_task_hub:CurrentTask().gatheredChocoFood = true
							elseif (IsGardening(item.id)) then
								ml_task_hub:CurrentTask().gatheredGardening = true
							elseif (IsMap(item.id)) then
								ml_task_hub:CurrentTask().gatheredMap = true
							end
							
							ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
							ml_task_hub:CurrentTask().gatherTimer = Now()
							ml_task_hub:CurrentTask().failedTimer = Now()
							ffxiv_task_gather.timer = Now() + 750
							ffxiv_task_gather.awaitingSuccess = false
							--return
						end
						return
					end
				end
			end
				
			-- just grab a random item with good chance
			for i, item in pairs(list) do
				if (item.chance > 50 and not IsGardening(item.id) and not IsMap(item.id) and not IsChocoboFood(item.id)) then
					if (SkillMgr.Gather(item)) then
						ml_task_hub:CurrentTask().failedTimer = Now()
						ffxiv_task_gather.timer = Now() + 2000
						return
					end
							
					local result = Player:Gather(item.index)
					if (result == 65536) then
						--d("Gathering random (change > 50) item because in non-marker section.")
						ffxiv_task_gather.timer = Now() + 300
						ffxiv_task_gather.awaitingSuccess = true
						--return
					elseif (result == 0 and ffxiv_task_gather.awaitingSuccess) then
						ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
						ml_task_hub:CurrentTask().gatherTimer = Now()
						ml_task_hub:CurrentTask().failedTimer = Now()
						ffxiv_task_gather.timer = Now() + 750
						ffxiv_task_gather.awaitingSuccess = false
						--return
					end
					return
				end
			end
			
			-- just grab a random item - last resort
			for i, item in pairs(list) do
				if (not IsGardening(item.id) and not IsMap(item.id) and not IsChocoboFood(item.id)) then
					if (SkillMgr.Gather(item)) then
						ml_task_hub:CurrentTask().failedTimer = Now()
						ffxiv_task_gather.timer = Now() + 2000
						return
					end
							
					local result = Player:Gather(item.index)
					if (result == 65536) then
						--d("Gathering random item because in non-marker section.")
						ffxiv_task_gather.timer = Now() + 300
						ffxiv_task_gather.awaitingSuccess = true
						--return
					elseif (result == 0 and ffxiv_task_gather.awaitingSuccess) then
						ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
						ml_task_hub:CurrentTask().gatherTimer = Now()
						ml_task_hub:CurrentTask().failedTimer = Now()
						ffxiv_task_gather.timer = Now() + 750
						ffxiv_task_gather.awaitingSuccess = false
						--return
					end
					return
				end
			end
		end
    end
end

c_nodeprebuff = inheritsFrom( ml_cause )
e_nodeprebuff = inheritsFrom( ml_effect )
e_nodeprebuff.useCordial = false
function c_nodeprebuff:evaluate()
	if (Now() < ffxiv_task_gather.timer) then
		return false
	end
	
	local list = Player:GetGatherableSlotList()
	if (list) then
		return false
	end
	
	local node = EntityList:Get(ml_task_hub:ThisTask().gatherid)
	if ( node and node.cangather and node.distance < 10 ) then
		if (ShouldEat()) then
			return true
		end
		if (ValidTable(ml_task_hub:ThisTask().currentMarker)) then
			local profile = ml_task_hub:ThisTask().currentMarker:GetFieldValue(GetString("skillProfile"))
			if (profile and profile ~= "None" and profile ~= "" and gSMprofile ~= profile) then
				return true
			end
			
			local markerType = ml_task_hub:ThisTask().currentMarker:GetType()
			if (markerType == GetString("unspoiledMarker")) then
				local requiredGP = tonumber(ml_task_hub:ThisTask().currentMarker:GetFieldValue(GetString("minimumGP"))) or 0
				if (Player.gp.current < requiredGP) then
					if (((requiredGP - Player.gp.current) > 50)) then
						if (gGatherUseCordials == "1" and ItemIsReady(6141)) then
							e_nodeprebuff.useCordial = true
						end
					end
					return true
				end
			elseif (markerType == GetString("botanyMarker") or markerType == GetString("miningMarker")) then
				if (gGatherUseCordials == "1" and Player.gp.percent <= 30 and ItemIsReady(6141)) then
					e_nodeprebuff.useCordial = true
					return true
				end
			end
		end
	end
	return false
end
function e_nodeprebuff:execute()
	if (Player:IsMoving()) then
		Player:Stop()
	end
	if (Player.ismounted) then
		Dismount()
		return
	end
	
	if (ShouldEat()) then
		Eat()
	end
	if (ValidTable(ml_task_hub:ThisTask().currentMarker)) then
		local profile = ml_task_hub:ThisTask().currentMarker:GetFieldValue(GetString("skillProfile"))
		if (profile and profile ~= "None" and profile ~= "" and gSMprofile ~= profile) then
			SkillMgr.UseProfile(profile)
		end
	end
	if (e_nodeprebuff.useCordial) then
		local newTask = ffxiv_task_useitem.Create()
		newTask.itemid = 6141
		--ml_task_hub:CurrentTask():AddSubTask(newTask)
		ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
	end
	e_nodeprebuff.useCordial = false
end

c_gatherwindow = inheritsFrom( ml_cause )
e_gatherwindow = inheritsFrom( ml_effect )
function c_gatherwindow:evaluate()
	local list = Player:GetGatherableSlotList()
    if (list ~= nil and (ml_task_hub:CurrentTask().name ~= "LT_GATHER" and ml_task_hub:CurrentTask().name ~= "LT_QS_GATHER")) then
		return true
	end
end
function e_gatherwindow:execute()
	Player:Stop()
	ml_debug(ml_task_hub:CurrentTask().name.." will be terminated to allow gathering to continue.")
end

c_gatherflee = inheritsFrom( ml_cause )
e_gatherflee = inheritsFrom( ml_effect )
e_gatherflee.fleePos = {}
function c_gatherflee:evaluate()
	if (Player.incombat and ml_task_hub:CurrentTask().name ~= "MOVETOPOS") then
		if (ValidTable(ml_marker_mgr.markerList["evacPoint"])) then
			local fpos = ml_marker_mgr.markerList["evacPoint"]
			local ppos = Player.pos
			if (Distance3D(ppos.x, ppos.y, ppos.z, fpos.x, fpos.y, fpos.z) > 50) then
				e_gatherflee.fleePos = fpos
				return true
			end
		end
		
		local ppos = Player.pos
		local newPos = NavigationManager:GetRandomPointOnCircle(ppos.x,ppos.y,ppos.z,100,200)
		if (ValidTable(newPos)) then
			e_gatherflee.fleePos = newPos
			return true
		end
	end
    
    return false
end
function e_gatherflee:execute()
	local fleePos = e_gatherflee.fleePos
	if (ValidTable(fleePos)) then
		local newTask = ffxiv_task_flee.Create()
		newTask.pos = fleePos
		newTask.useTeleport = (gTeleport == "1")
		newTask.task_complete_eval = 
			function ()
				return not Player.incombat
			end
		newTask.task_fail_eval = 
			function ()
				return not Player.alive or ((not c_walktopos:evaluate() and not Player:IsMoving()) and Player.incombat)
			end
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	else
		ml_error("Need to flee but no evac position defined for this mesh!!")
	end
end

function ffxiv_task_gather:Init()
	--local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 30 )
    --self:add( ke_inventoryFull, self.overwatch_elements)
	
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 25 )
    self:add( ke_dead, self.overwatch_elements)
	
	local ke_flee = ml_element:create( "Flee", c_gatherflee, e_gatherflee, 24 )
    self:add( ke_flee, self.overwatch_elements)
    
    local ke_stealth = ml_element:create( "Stealth", c_stealth, e_stealth, 23 )
    self:add( ke_stealth, self.overwatch_elements)
	
	local ke_nodePreBuff = ml_element:create( "NodePreBuff", c_nodeprebuff, e_nodeprebuff, 21 )
    self:add( ke_nodePreBuff, self.overwatch_elements)
	
	local ke_nextLocation = ml_element:create( "NextLocation", c_nextgatherlocation, e_nextgatherlocation, 4 )
    self:add(ke_nextLocation, self.overwatch_elements)
	
	local ke_autoEquip = ml_element:create( "AutoEquip", c_autoequip, e_autoequip, 50 )
    self:add( ke_autoEquip, self.process_elements)
	
	local ke_unspoiledPrep = ml_element:create( "UnspoiledPrep", c_unspoiledprep, e_unspoiledprep, 200 )
    self:add( ke_unspoiledPrep, self.process_elements)
	
	local ke_findunspoiledNode = ml_element:create( "FindUnspoiledNode", c_findunspoilednode, e_findunspoilednode, 190 )
    self:add(ke_findunspoiledNode, self.process_elements)
	
	local ke_nextUnspoiledMarker = ml_element:create( "NextUnspoiledMarker", c_nextunspoiledmarker, e_nextunspoiledmarker, 180 )
    self:add( ke_nextUnspoiledMarker, self.process_elements)
	
	local ke_moveToUnspoiledMarker = ml_element:create( "MoveToUnspoiledMarker", c_movetounspoiledmarker, e_movetounspoiledmarker, 170 )
    self:add( ke_moveToUnspoiledMarker, self.process_elements)
	
	local ke_findGatherable = ml_element:create( "FindGatherable", c_findgatherable, e_findgatherable, 100 )
    self:add(ke_findGatherable, self.process_elements)
	
	local ke_nextMarker = ml_element:create( "NextMarker", c_nextgathermarker, e_nextgathermarker, 90 )
    self:add( ke_nextMarker, self.process_elements )
	
	local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 80 )
    self:add( ke_returnToMarker, self.process_elements)
	
    local ke_moveToGatherable = ml_element:create( "MoveToGatherable", c_movetogatherable, e_movetogatherable, 70 )
    self:add( ke_moveToGatherable, self.process_elements)
    
    local ke_gather = ml_element:create( "Gather", c_gather, e_gather, 10 )
    self:add(ke_gather, self.process_elements)	
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_gather.OnUpdate(event, ticks)
	if (TimeSince(ffxiv_task_gather.lastTick) > 5000) then
		ffxiv_task_gather.lastTick = ticks
		
		if (not IsLoading() and not ml_mesh_mgr.meshLoading and ffxiv_task_gather.lastLocationLoaded ~= Player.localmapid) then
			local markerNameList = ffxiv_task_gather.GetUnspoiledMarkers(Player.localmapid)
			gGatherMapMarker_listitems = markerNameList
			eGatherMapMarker_listitems = markerNameList
			ffxiv_task_gather.lastLocationLoaded = Player.localmapid
		end
    end  
end

function ffxiv_task_gather:Process()
	if (IsLoading() or ml_mesh_mgr.meshLoading) then
		return false
	end
	
    --Process regular elements.
    if (TableSize(self.process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(self.process_elements)
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end

function ffxiv_task_gather.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gGatherMapHour" or
				k == "gGatherMapClass" or
				k == "gGatherMinerGearset" or
				k == "gGatherBotanistGearset" or
				k == "gGatherMapMarker" or
				k == "gGatherIdleLocation" or	
				k == "gGatherUseCordials" ) then
			SafeSetVar(tostring(k),v)
		elseif ( k == "gGatherUnspoiled") then
			if (v == "1") then
				ml_marker_mgr.SetMarkerType(GetString("unspoiledMarker"))
			elseif (Player.job == FFXIV.JOBS.BOTANIST) then
				ml_marker_mgr.SetMarkerType(GetString("botanyMarker"))
			else
				ml_marker_mgr.SetMarkerType(GetString("miningMarker"))
			end
            SafeSetVar(tostring(k),v)
		elseif ( k == "gGatherStartLocation") then
			ffxiv_task_gather.location = 0
			SafeSetVar(tostring(k),v)
		elseif ( k == "Field_Name") then
			--Capture the marker name changes, incase it affects our marker lists.
			ffxiv_task_gather.RefreshMarkerList(Player.localmapid)
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
	GUI_NewButton(winName, GetString("markerManager"), "ToggleMarkerMgr")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,GetString("navmesh") ,"gmeshname",group,ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
	GUI_NewField(winName,GetString("markerName"),"gStatusMarkerName",group )
	GUI_NewField(winName,GetString("markerTime"),"gStatusMarkerTime",group )
	GUI_NewField(winName,GetString("locationName"),"gGatherMapLocation",group)
	
	group = GetString("settings")
	GUI_NewCheckbox(winName,GetString("gatherUnspoiled"), "gGatherUnspoiled",group)
	GUI_NewCheckbox(winName,GetString("useCordials"), "gGatherUseCordials",group)
	GUI_NewComboBox(winName,GetString("startLocation"),"gGatherStartLocation",group,"")
	gGatherStartLocation_listitems = ffxiv_task_gather.GetUnspoiledLocations()
	GUI_NewField(winName,GetString("minerGearset"),"gGatherMinerGearset",group )
	GUI_NewField(winName,GetString("botanistGearset"),"gGatherBotanistGearset",group )
	
	group = GetString("newLocation")
	GUI_NewField(winName,GetString("locationName"),"gGatherMapName",group)
	GUI_NewNumeric(winName,GetString("hour"),"gGatherMapHour",group, "0", "23")
	GUI_NewComboBox(winName,GetString("class"),"gGatherMapClass",group, "MINER,BOTANIST")	
	GUI_NewComboBox(winName,GetString("markerName"),"gGatherMapMarker",group,"")
	GUI_NewCheckbox(winName,GetString("isIdle"),"gGatherMapIdle",group)
	GUI_NewButton(winName,GetString("addLocation"),"ffxiv_gatherAddLocation",group)
	
	GUI_UnFoldGroup(winName,GetString("status"))
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	local editWindow = ffxiv_task_gather.editwindow
	GUI_NewWindow(editWindow.name,editWindow.x,editWindow.y,editWindow.width,editWindow.height,"",true)
	winName = editWindow.name
	group = GetString("settings")
	GUI_NewField(winName,GetString("locationName"),"eGatherMapName",group)
	GUI_NewField(winName,GetString("questMap"),"eGatherMapID",group)
	GUI_NewCheckbox(winName,GetString("enabled"),"eGatherMapEnabled",group)
	GUI_NewNumeric(winName,GetString("hour"),"eGatherMapHour",group, "0", "23")
	GUI_NewComboBox(winName,GetString("class"),"eGatherMapClass",group, "MINER,BOTANIST")
	GUI_NewComboBox(winName,GetString("markerName"),"eGatherMapMarker",group,"")
	GUI_NewCheckbox(winName,GetString("isIdle"),"eGatherMapIdle",group)
	GUI_NewButton(winName,GetString("saveLocation"),"ffxiv_gatherSaveLocation")
	GUI_NewButton(winName,GetString("moveLocation"),"ffxiv_gatherSaveLocation")
	GUI_NewButton(winName,GetString("removeLocation"),"ffxiv_gatherRemoveLocation")
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
	
    ffxiv_task_gather.SetupMarkers()
    ffxiv_task_gather.RefreshGatherLocations()
    RegisterEventHandler("GUI.Update",ffxiv_task_gather.GUIVarUpdate)
end

function ffxiv_task_gather.SwitchClass(class)
	if (Now() < ffxiv_task_gather.timer) then
		return
	end
	
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
	if (Now() < ffxiv_task_gather.timer) then
		return
	end
	
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
		action:Cast()
	end
	ffxiv_task_gather.timer = Now() + 2000
end

function ffxiv_task_gather.SetupMarkers()
    -- add marker templates for gathering
    local botanyMarker = ml_marker:Create("botanyTemplate")
	botanyMarker:SetType(GetString("botanyMarker"))
	botanyMarker:ClearFields()
	botanyMarker:AddField("int", GetString("minContentLevel"), 0)
	botanyMarker:AddField("int", GetString("maxContentLevel"), 0)
	botanyMarker:AddField("int", GetString("maxRadius"), 0)
	botanyMarker:AddField("string", GetString("selectItem1"), "")
	botanyMarker:AddField("string", GetString("selectItem2"), "")
	botanyMarker:AddField("string", GetString("contentIDEquals"), "")
	botanyMarker:AddField("button", GetString("whitelistTarget"), "")
	botanyMarker:AddField("string", GetString("NOTcontentIDEquals"), "")
	botanyMarker:AddField("combobox", GetString("gatherMaps"), "Any", "Any,Peisteskin Only,None")
	botanyMarker:AddField("checkbox", GetString("gatherGardening"), "1")
	botanyMarker:AddField("checkbox", GetString("gatherChocoFood"), "1")
	botanyMarker:AddField("checkbox", "Rare Items", "1")
	botanyMarker:AddField("checkbox", "Special Rare Items", "1")
	botanyMarker:AddField("checkbox", GetString("useStealth"), "1")
	botanyMarker:AddField("checkbox", GetString("dangerousArea"), "0")
	botanyMarker:AddField("combobox", GetString("skillProfile"), "None", ffxivminion.Strings.SKMProfiles())
    botanyMarker:SetTime(300)
    botanyMarker:SetMinLevel(1)
    botanyMarker:SetMaxLevel(60)
    ml_marker_mgr.AddMarkerTemplate(botanyMarker)
	
	local miningMarker = ml_marker:Create("miningTemplate")
	miningMarker:SetType(GetString("miningMarker"))
	miningMarker:ClearFields()
	miningMarker:AddField("int", GetString("minContentLevel"), 0)
	miningMarker:AddField("int", GetString("maxContentLevel"), 0)
	miningMarker:AddField("int", GetString("maxRadius"), 300)
	miningMarker:AddField("string", GetString("selectItem1"), "")
	miningMarker:AddField("string", GetString("selectItem2"), "")
	miningMarker:AddField("string", GetString("contentIDEquals"), "")
	miningMarker:AddField("button", GetString("whitelistTarget"), "")
	miningMarker:AddField("string", GetString("NOTcontentIDEquals"), "")
	miningMarker:AddField("combobox", GetString("gatherMaps"), "Any", "Any,Peisteskin Only,None")
	miningMarker:AddField("checkbox", GetString("gatherGardening"), "1")
	miningMarker:AddField("checkbox", GetString("gatherChocoFood"), "1")
	miningMarker:AddField("checkbox", "Rare Items", "1")
	miningMarker:AddField("checkbox", "Special Rare Items", "1")
	miningMarker:AddField("checkbox", GetString("useStealth"), "1")
	miningMarker:AddField("checkbox", GetString("dangerousArea"), "0")
	miningMarker:AddField("combobox", GetString("skillProfile"), "None", ffxivminion.Strings.SKMProfiles())
    miningMarker:SetTime(300)
    miningMarker:SetMinLevel(1)
    miningMarker:SetMaxLevel(60)
    ml_marker_mgr.AddMarkerTemplate(miningMarker)
	
	local unspoiledMarker = ml_marker:Create("unspoiledTemplate")
	unspoiledMarker:SetType(GetString("unspoiledMarker"))
	unspoiledMarker:ClearFields()
	unspoiledMarker:AddField("int", GetString("minContentLevel"), 0)
	unspoiledMarker:AddField("int", GetString("maxContentLevel"), 0)
	unspoiledMarker:AddField("int", GetString("maxRadius"), 300)
	unspoiledMarker:AddField("string", GetString("minimumGP"), "0")
	unspoiledMarker:AddField("string", GetString("selectItem1"), "")
	unspoiledMarker:AddField("string", GetString("selectItem2"), "")
	unspoiledMarker:AddField("combobox", GetString("gatherMaps"), "Any", "Any,Peisteskin Only,None")
	unspoiledMarker:AddField("checkbox", GetString("gatherGardening"), "1")
	unspoiledMarker:AddField("checkbox", GetString("gatherChocoFood"), "1")
	unspoiledMarker:AddField("checkbox", "Rare Items", "1")
	unspoiledMarker:AddField("checkbox", "Special Rare Items", "1")
	unspoiledMarker:AddField("checkbox", GetString("useStealth"), "1")
	unspoiledMarker:AddField("checkbox", GetString("dangerousArea"), "0")
	unspoiledMarker:AddField("combobox", GetString("skillProfile"), "None", ffxivminion.Strings.SKMProfiles())
    unspoiledMarker:SetTime(1800)
    unspoiledMarker:SetMinLevel(50)
    unspoiledMarker:SetMaxLevel(60)
    ml_marker_mgr.AddMarkerTemplate(unspoiledMarker)
	
    -- refresh the manager with the new templates
    ml_marker_mgr.RefreshMarkerTypes()
	ml_marker_mgr.RefreshMarkerNames()
end

function ffxiv_task_gather.GetUnspoiledMarkers(mapid)
	local mapid = tonumber(mapid) or 0
	local meshName = Settings.minionlib.DefaultMaps[mapid]
	if (meshName) then
		local markerNameList = GetOffMapMarkerList(meshName, GetString("unspoiledMarker"))
		if (markerNameList) then
			return markerNameList
		else
			ml_debug("Could not find the unspoiled marker name list.")
		end
	else
		ml_debug("Could not find the associated mesh for mapid "..tostring(mapid))
	end
	
	return nil
end

function ffxiv_task_gather.IsIdleLocation()
	if (ValidTable(ffxiv_task_gather.location)) then
		if (ffxiv_task_gather.location.isIdle) then
			return true
		end
	end
	
	return false
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
	
	local location = {
		name = key,
		enabled = true,
		mapid = Player.localmapid,
		hour = tonumber(gGatherMapHour) or 0,
		class = FFXIV.JOBS[gGatherMapClass],
		mesh = gmeshname,
		marker = gGatherMapMarker,
		lastGather = 0,
		isIdle = (gGatherMapIdle == "1") and true or false,
	}
	
	list[key] = location
	gGatherLocations = list
	Settings.FFXIVMINION.gGatherLocations = gGatherLocations
	ffxiv_task_gather.RefreshGatherLocations()
end

function ffxiv_task_gather.SaveGatherLocation()
	local list = Settings.FFXIVMINION.gGatherLocations
	local key = eGatherMapName
	
	local location = list[key]
	local newLocation = {
		name = eGatherMapName,
		mapid = location.mapid,
		enabled = eGatherMapEnabled == "1" and true or false,
		hour = tonumber(eGatherMapHour) or 0,
		class = FFXIV.JOBS[eGatherMapClass],
		marker = eGatherMapMarker,
		lastGather = 0,
		isIdle = eGatherMapIdle == "1" and true or false,
	}
	
	list[key] = newLocation
	gGatherLocations = list
	Settings.FFXIVMINION.gGatherLocations = gGatherLocations
	GUI_WindowVisible(ffxiv_task_gather.editwindow.name, false)
	ffxiv_task_gather.RefreshGatherLocations()
end

function ffxiv_task_gather.MoveGatherLocation()
	local list = Settings.FFXIVMINION.gGatherLocations
	local key = eGatherMapName
	
	local location = list[key]
	location.mapid = Player.localmapid
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
	
	local location = list[key]
	if (ValidTable(location)) then		
		eGatherMapName = location.name
		eGatherMapID = location.mapid
		eGatherMapEnabled = (location.enabled == true) and "1" or "0"
		eGatherMapIdle = (location.isIdle == true) and "1" or "0"
		eGatherMapHour = location.hour
		eGatherMapClass = (location.class == FFXIV.JOBS.MINER) and "MINER" or "BOTANIST"
		
		ffxiv_task_gather.RefreshMarkerList(location.mapid)
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
	
	gGatherStartLocation_listitems = ffxiv_task_gather.GetUnspoiledLocations()
	
	ffxivminion.SizeWindow(winName)
	GUI_RefreshWindow(winName)
end

function ffxiv_task_gather.RefreshMarkerList(mapid)
	local mapid = tonumber(mapid) or 0
	local winName = ffxivminion.Windows.Gather.Name
	local markerString = ""
	if (mapid ~= 0) then
		markerString = ffxiv_task_gather.GetUnspoiledMarkers(mapid)
	end
	gGatherMapMarker_listitems = markerString
	eGatherMapMarker_listitems = markerString
	GUI_RefreshWindow(winName)
end

function ffxiv_task_gather.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" and string.find(Button,"ffxiv_gather") ~= nil ) then
		if (Button == "ffxiv_gatherAddLocation") then
			ffxiv_task_gather.AddGatherLocation()
		end
		--if (Button == "ffxiv_gatherRefreshMap") then
			--ffxiv_task_gather.RefreshMap()
		--end
		if (Button == "ffxiv_gatherMoveLocation") then
			ffxiv_task_gather.MoveGatherLocation()
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

ffxiv_task_gather.chocoboItems = {
	[10094] = true,
	[10095] = true,
	[10096] = true,
	[10097] = true,
	[10098] = true,
}       

RegisterEventHandler("Gameloop.Update",ffxiv_task_gather.OnUpdate)
RegisterEventHandler("GUI.Item",ffxiv_task_gather.HandleButtons)
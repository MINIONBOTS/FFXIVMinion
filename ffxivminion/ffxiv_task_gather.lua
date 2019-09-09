ffxiv_gather = {}
ffxiv_gather.lastTick = 0
ffxiv_gather.timer = 0
ffxiv_gather.lastItemAttempted = 0
ffxiv_gather.editwindow = {name = GetString("locationEditor"), x = 0, y = 0, width = 250, height = 230}
ffxiv_gather.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\GatherProfiles\]]
ffxiv_gather.profiles = {}
ffxiv_gather.profilesDisplay = {}
ffxiv_gather.profileData = {}
ffxiv_gather.currentTask = {}
ffxiv_gather.accessmaplist = {}
ffxiv_gather.currentTaskIndex = 0
ffxiv_gather.collectors = {
	[16] = 4074,
	[17] = 4088,
}

ffxiv_task_gather = inheritsFrom(ml_task)
ffxiv_task_gather.name = "LT_GATHER"
function ffxiv_task_gather.Create()
    if gGatherMarkerOrProfileIndex == 1 then
		if Player.job == 16 then 
			gMarkerType = "Mining"
		elseif Player.job == 17 then 
			gMarkerType = "Botany"
		end
	end
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
    newinst.seriescount = 0
    newinst.gatherid = 0
    newinst.markerTime = 0
    newinst.currentMarker = false
	ml_marker_mgr.currentMarker = nil
	ml_global_information.lastEquip = 0
	
	ffxiv_gather.currentTask = {}
	ffxiv_gather.currentTaskIndex = 0
	newinst.randomDelayCompleted = false
	
	newinst.pos = Player.pos
    newinst.gatherTimer = 0
	newinst.gatherDistance = 1.5
    newinst.idleTimer = 0
	newinst.filterLevel = true
	newinst.failedSearches = 0 
	
	AddEvacPoint()
	
    return newinst
end

function gd(var,level)
	local level = tonumber(level) or 3

	local requiredLevel = gGatherDebugLevel
	if (gBotMode == GetString("questMode") and gQuestDebug) then
		requiredLevel = gQuestDebugLevel
	end
	
	if ( gGatherDebug or (gQuestDebug and gBotMode == GetString("questMode"))) then
		if ( level <= tonumber(requiredLevel)) then
			if (type(var) == "string") then
				d("[L"..tostring(level).."]["..tostring(Now()).."]: "..var)
			elseif (type(var) == "number" or type(var) == "boolean") then
				d("[L"..tostring(level).."]["..tostring(Now()).."]: "..tostring(var))
			elseif (type(var) == "table") then
				outputTable(var)
			end
		end
	end
end

function ffxiv_gather.RandomizePosition(pos, x, y, z)
	local pos = pos or {}
	local x = x or 0
	local y = y or 0
	local z = z or 0
	local h = h or 0
	local newPos = {}
	
	if (table.valid(pos)) then
		for i = 1,10 do
			newPos.x = (pos.x - x) + (math.random() * x * 2)
			newPos.y = (pos.y - y) + (math.random() * y * 2)
			newPos.z = (pos.z - z) + (math.random() * z * 2)
			if (pos.h) then
				newPos.h = pos.h
			end
			
			if (table.valid(newPos)) then
				local randPosition = FindClosestMesh(newPos,10,false)
				if (randPosition) then
					pos = randPosition
					break
				end
			end
		end
	end

	return pos
end
function ffxiv_gather.CanAccessGatherMap(mapid)

	if ffxiv_gather.accessmaplist[mapid] ~= nil then
		return ffxiv_gather.accessmaplist[mapid]
	else
		if CanAccessMap(mapid) then
			ffxiv_gather.accessmaplist[mapid] = true
			return true
		else
		
			ffxiv_gather.accessmaplist[mapid] = false
			return false
		end
	end
end
function ffxiv_gather.GetCurrentTaskPos()
	local pos = {}
	
	
	if (table.valid(ffxiv_gather.currentTask)) then
		local task = ffxiv_gather.currentTask
		local taskPos = task.pos
		local taskFlightPos = task.flightpos
		
		if (task.maxPositions ~= nil) and (task.maxPositions > 0) then
			local currentPosition = task.currentPosition
			if (table.valid(currentPosition)) then
				pos = currentPosition
			else
				local taskMultiPos = task.multipos
				if (table.valid(taskMultiPos)) then
					if (table.valid(taskMultiPos[task.currentPositionIndex])) then
						pos = taskMultiPos[task.currentPositionIndex]
						if (task.mapid == Player.localmapid) then
							currentPosition = ffxiv_gather.RandomizePosition(pos, 5.0, 5.0, 5.0)
							ffxiv_gather.currentTask.currentPosition = currentPosition
							pos = currentPosition
						end
					else
						for i,choice in pairs(taskMultiPos) do
							if (table.valid(choice)) then
								ffxiv_gather.currentTask.currentPositionIndex = i
								pos = choice
								break
							end
						end
					end
				end
			end
		elseif ((table.valid(taskFlightPos)) and (IsOnMap(task.mapid) and CanFlyInZone())) then
				pos = taskFlightPos
		else
			if (table.valid(taskPos)) then
				pos = taskPos
			end
		end
	end
	return pos
end

function GetMinGP()
	local minimumGP = 0
	local task = ffxiv_gather.currentTask
	if (table.valid(task)) then
		minimumGP = IsNull(task.mingp,0)
		if task.mingp == "skillProfileDefined" then
			if IsNull(SkillMgr.ProfileRaw.mingp,0) ~= 0 then
				minimumGP = SkillMgr.ProfileRaw.mingp
				--d("[Gather Information]: Skill profile requires at least ["..tostring(minimumGP).."] GP for optimal performance.")
				ml_global_information.ShowInformation(GetString("[Information]: Selected skill profile requires at least ["..tostring(minimumGP).."] GP."), 4000)
			else
				minimumGP = 0
			end
		end
	elseif (table.valid(marker)) then
		minimumGP = IsNull(marker.mingp,0)
		d("[Gather]: Marker requires at least ["..tostring(minimumGP).."] GP for optimal performance.")
	end
		
	if (type(minimumGP) == "string" and GUI_Get(minimumGP) ~= nil) then
		minimumGP = GUI_Get(minimumGP)
	end
	minimumGP = tonumber(minimumGP)
	
	return minimumGP
end

c_findnode = inheritsFrom( ml_cause )
e_findnode = inheritsFrom( ml_effect )
function c_findnode:evaluate()
	if (MIsLoading() or MIsCasting() or CannotMove() or 
		IsControlOpen("Gathering") or IsControlOpen("GatheringMasterpiece")) then
		return false
	end
	
	local needsUpdate = false
	if ( ml_task_hub:CurrentTask().gatherid == nil or ml_task_hub:CurrentTask().gatherid == 0 ) then
		needsUpdate = true
	else
		local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
		if (table.valid(gatherable)) then
			if (not gatherable.cangather or not gatherable.targetable) then
				needsUpdate = true
			end
		elseif (gatherable == nil) then
			needsUpdate = true
		end
	end
	
	if (needsUpdate) then
		ml_task_hub:CurrentTask().gatherid = 0
		ml_global_information.gatherid = 0
		
		local whitelist = ""
		local radius = 150
		local nodeminlevel = 1
		local nodemaxlevel = 80
		local basePos = {}
		local blacklist = ""
		local includesHighPrio = true;
	
		local task = ffxiv_gather.currentTask
		local marker = ml_marker_mgr.currentMarker
		if (table.valid(task)) then
			whitelist = IsNull(task.whitelist,"")
			radius = IsNull(task.radius,150)
			nodemaxlevel = IsNull(task.nodemaxlevel,80)
			nodeminlevel = IsNull(task.nodeminlevel,1)
			basePos = ffxiv_gather.GetCurrentTaskPos()
			
			if (task.unspoiled and task.unspoiled == false) then
				blacklist = "5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20"
				includesHighPrio = false
			elseif (task.unspoiled and task.unspoiled == true) then
				whitelist = "5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20"
			end
		elseif (table.valid(marker)) then
			whitelist = IsNull(marker.whitelist,"")
			radius = IsNull(marker.maxradius,150)
			if (radius == 0) then radius = 150 end
			nodeminlevel = IsNull(marker.mincontentlevel,1)
			if (nodeminlevel == 0) then nodeminlevel = 1 end
			nodemaxlevel = IsNull(marker.maxcontentlevel,80)
			if (nodemaxlevel == 0) then nodemaxlevel = 80 end
			basePos = marker:GetPosition()
		elseif (gBotMode == GetString("gatherMode") and gGatherMarkerOrProfileIndex == 3) then
			basePos = ml_task_hub:CurrentTask().pos
			nodemaxlevel = IsNull(gQuickstartMaxNodeLvl,80)
			nodeminlevel = IsNull(gQuickstartMinNodeLvl,1)
		else
			return false
		end
		
		if (table.valid(basePos)) then
			local myPos = Player.pos
			local distance = PDistance3D(myPos.x, myPos.y, myPos.z, basePos.x, basePos.y, basePos.z)
			if (distance <= radius) then
			
				if (ml_task_hub:CurrentTask().taskStarted == 0) then
					ml_task_hub:CurrentTask().taskStarted = Now()
				end
			
				local filter = ""
				if (whitelist ~= "") then
					filter = "onmesh,gatherable,targetable,minlevel="..tostring(nodeminlevel)..",maxlevel="..tostring(nodemaxlevel)..",contentid="..whitelist
					--d("Using whitelist filter ["..filter.."].",3)
				elseif (blacklist ~= "") then
					filter = "onmesh,gatherable,targetable,minlevel="..tostring(nodeminlevel)..",maxlevel="..tostring(nodemaxlevel)..",exclude_contentid="..blacklist
					--d("Using blacklist filter ["..filter.."].",3)
				else
					filter = "onmesh,gatherable,targetable,minlevel="..tostring(nodeminlevel)..",maxlevel="..tostring(nodemaxlevel)
					--d("Using filter ["..filter.."].",3)
				end
				
				local gatherable = nil
				local gatherables = MEntityList(filter)
				if (table.valid(gatherables)) then
					for i,potential in pairs(gatherables) do
						if (MultiComp(potential.contentid,"9,10,11,12,17,18,19,20")) then
							gatherable = potential
						end
					end
				end	
				
				if (gatherable == nil) then
					gatherable = GetNearestFromList(filter,basePos,radius)
				end
				
				if (table.valid(gatherable)) then
				
					if (ml_task_hub:CurrentTask().taskFailed ~= 0) then
						ml_task_hub:CurrentTask().taskFailed = 0
					end
				
					gd("Found a gatherable with ID: "..tostring(gatherable.id).." at a distance of ["..tostring(gatherable.distance).."].",3)
					-- reset blacklist vars for a new node	
					ml_task_hub:CurrentTask().gatherid = gatherable.id	
					ml_global_information.gatherid = gatherable.id
					SkillMgr.prevSkillList = {}
					return true
				end
			end
		end
	else
		return false
	end
    
	ml_task_hub:CurrentTask().failedSearches = ml_task_hub:CurrentTask().failedSearches + 1
	
	if (ml_task_hub:CurrentTask().failedSearches > 1) then
		if (ml_task_hub:CurrentTask().taskFailed == 0) then
			ml_task_hub:CurrentTask().taskFailed = Now()
		end
	end
	
    return false
end
function e_findnode:execute()
	gd("Found a new node.",3)
end

c_movetonode = inheritsFrom( ml_cause )
e_movetonode = inheritsFrom( ml_effect )
e_movetonode.blockOnly = false
function c_movetonode:evaluate()
	if (MIsLoading() or MIsCasting() or CannotMove() or 
		IsControlOpen("Gathering") or IsControlOpen("GatheringMasterpiece")) then
		return false
	end
	
	e_movetonode.blockOnly = false
    
    if ( ml_task_hub:CurrentTask().gatherid ~= nil and ml_task_hub:CurrentTask().gatherid ~= 0 ) then
        local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
        if (gatherable and gatherable.cangather and gatherable.targetable) then
			local gpos = gatherable.pos
			local ppos = Player.pos
			local minimumGP = GetMinGP()	
			local touchOnly = false
			local noGPitem = ""
			local task = ffxiv_gather.currentTask
			if (table.valid(task)) then
				touchOnly = IsNull(task.touchonly,false)
				noGPitem = IsNull(task.nogpitem,"")
			end
			
			--local reachable = (IsEntityReachable(gatherable,5) and gatherable.distance2d > 0 and gatherable.distance2d < 2.5)
			local reachable = (gatherable.interactable and gatherable.distance2d <= 2.5 and gatherable.distance <= 4)
			if (not reachable) then
			
				-- Might stop just out of range to wait for GP, don't need to be super accurate
				if not touchOnly and (Player.gp.current < Player.gp.max and Player.gp.current < minimumGP and gatherable.distance2d <= 10) then
					ml_global_information.ShowInformation(GetString("[Information]: Waiting for ["..tostring(minimumGP).."] GP."), 3000)
					ml_global_information.Await(3000)
					e_movetonode.blockOnly = true
				end
				
				--gd("[MoveToNode]: > 2.5 distance, need to move to id ["..tostring(gatherable.id).."].",2)
				return true
			elseif (gatherable.interactable and IsFlying()) then
				Descend()
				return true
			else	
				--gd("[MoveToNode]: <= 2.5 distance, need to move to id ["..tostring(gatherable.id).."].",2)				
				if (Player.gp.current >= minimumGP or noGPitem ~= "" or touchOnly) then
					gd("[MoveToNode]: We have enough GP or a nogpitem  set, set target to id ["..tostring(gatherable.id).."] and try to interact.",2)
					Player:SetTarget(gatherable.id)
					Player:SetFacing(gpos.x,gpos.y,gpos.z)
					
					local myTarget = MGetTarget()
					if (myTarget and myTarget.id == gatherable.id) then
						Player:Interact(gatherable.id)
					end
					
					ml_global_information.Await(500)
					e_movetonode.blockOnly = true
					return true
				elseif (Player.gp.current < minimumGP and Player.gp.current < Player.gp.max) then
					local myTarget = MGetTarget()
					if (myTarget and myTarget.id ~= gatherable.id) then
						Player:SetTarget(gatherable.id)
					end
					
					ml_global_information.ShowInformation(GetString("[Information]: Waiting for ["..tostring(minimumGP).."] GP."), 3000)
					ml_global_information.Await(3000)
					e_movetonode.blockOnly = true
					return true
				end
			end
        end
    end
    
    return false
end
function e_movetonode:execute()
	if (e_movetonode.blockOnly) then
		gd("[MoveToNode]: Blocking execution to interact.",2)
		return
	end

    -- reset idle timer
    ml_task_hub:CurrentTask().idleTimer = 0
	local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
	if (table.valid(gatherable)) then
		local pos = gatherable.pos
		local ppos = Player.pos
		if (table.valid(pos)) then
			gd("[MoveToNode]: Final position x = "..tostring(pos.x)..",y = "..tostring(pos.y)..",z ="..tostring(pos.z),2)
			
			local newTask = ffxiv_task_movetointeract.Create()
			
			local foundPos = false
			if (IsFlying()) then
				local approachPosition = AceLib.API.Math.GetFlightApproach(pos)
				if (approachPosition) then
					local nearestMesh = FindClosestMesh(approachPosition,3,false,false)
					if (nearestMesh) then
						local dist3d = math.distance3d(ppos,nearestMesh)
						if (dist3d > 4 and NavigationManager:IsReachable(nearestMesh)) then
							d("used estimated position 2")
							pos = shallowcopy(nearestMesh)
							foundPos = true
						end
					end
				end
			end
			
			if (not foundPos) then
				local approachPosition = AceLib.API.Math.GetSafestApproach(pos)
				if (approachPosition) then
					local nearestMesh = FindClosestMesh(approachPosition,3,false,false)
					if (nearestMesh) then
						local dist3d = math.distance3d(ppos,nearestMesh)
						if (dist3d > 3 and NavigationManager:IsReachable(nearestMesh)) then
							d("used estimated position 2")
							pos = shallowcopy(nearestMesh)
							foundPos = true
						end
					end
				end
			end
			
			if (not foundPos) then
				local meshpos = gatherable.meshpos
				if (table.valid(meshpos) and NavigationManager:IsReachable(meshpos) and meshpos.meshdistance < 4) then
					d("used estimated position 3, meshdistance is ["..tostring(meshpos.meshdistance).."]")
					pos = shallowcopy(meshpos)
					foundPos = true
				end
			end
			
			if (not foundPos) then
				d("found no estimated position")
			end
			
			newTask.pos = pos
			newTask.useTeleport = false
			
			local dist3d = math.distance3d(ppos,pos)
			local touchOnly = false
			local minimumGP = GetMinGP()
			local task = ffxiv_gather.currentTask
			local noGPitem = ""
			local marker = ml_marker_mgr.currentMarker
			if (table.valid(task)) then
				noGPitem = IsNull(task.nogpitem,"")
				touchOnly = IsNull(task.touchonly,false)
			elseif (table.valid(marker)) then
				noGPitem = IsNull(marker.nogpitem,"")
			end
			
			if (type(useCordials) == "string" and GUI_Get(useCordials) ~= nil) then
				useCordials = GUI_Get(useCordials)
			end
				
			if (Player.gp.current < minimumGP and noGPitem ~= "") then
				newTask.minGP = 0
			else
				newTask.minGP = minimumGP
			end
			
			gd("[MoveToNode]: Setting minGP to ["..tostring(minimumGP).."]")
			if (IsNull(ml_task_hub:ThisTask().gatherid,0) ~= 0 and not MIsLocked()) then
				if CanUseCordial() then
					if (dist3d > 8 or IsFlying() or (dist3d > 2 and IsDiving())) then
						local alternateTask = ffxiv_task_movetopos.Create()
						alternateTask.pos = pos
						alternateTask.useTeleport = (gTeleportHack)
						alternateTask.range = math.random(3,6)
						alternateTask.remainMounted = false
						alternateTask.stealthFunction = ffxiv_gather.NeedsStealth
						ml_task_hub:CurrentTask():AddSubTask(alternateTask)
						d("[MoveToNode]: Starting alternate MOVETOPOS task to use a cordial.")
					end
					d("[MoveToNode]: Need to use cordial. ")
					return
				end
				if CanUseExpManual() then
					if (dist3d > 8 or IsFlying() or (dist3d > 2 and IsDiving())) then
						local alternateTask = ffxiv_task_movetopos.Create()
						alternateTask.pos = pos
						alternateTask.useTeleport = (gTeleportHack)
						alternateTask.range = math.random(3,6)
						alternateTask.remainMounted = false
						alternateTask.stealthFunction = ffxiv_gather.NeedsStealth
						ml_task_hub:CurrentTask():AddSubTask(alternateTask)
						d("[MoveToNode]: Starting alternate MOVETOPOS task to use a cordial, manual, or wait for GP.")
					end
					d("[MoveToNode]: Need to use manual. ")
					return
				end
				if not touchOnly and (Player.gp.current < newTask.minGP and Player.gp.current < Player.gp.max) then
					if (dist3d > 8 or IsFlying() or (dist3d > 2 and IsDiving())) then
						local alternateTask = ffxiv_task_movetopos.Create()
						alternateTask.pos = pos
						alternateTask.useTeleport = (gTeleportHack)
						alternateTask.range = math.random(3,6)
						alternateTask.remainMounted = false
						alternateTask.stealthFunction = ffxiv_gather.NeedsStealth
						ml_task_hub:CurrentTask():AddSubTask(alternateTask)
						d("[MoveToNode]: Starting alternate MOVETOPOS task to wait for GP.")
					end
					d("[MoveToNode]: Need to wait for GP, this task is set to require ["..tostring(newTask.minGP).."]. ")
					return
				end
			end
			
			if (gTeleportHack and dist3d > 8) then
				newTask.useTeleport = true
			end
			
			if IsDiving() then
				newTask.interactRange3d = 2.99
			end
			newTask.touchOnly = touchOnly
			newTask.interact = ml_task_hub:CurrentTask().gatherid
			newTask.navid = ml_task_hub:CurrentTask().gatherid
			newTask.stealthFunction = ffxiv_gather.NeedsStealth
			ml_task_hub:CurrentTask().seriescount = ml_task_hub:CurrentTask().seriescount + 1
			ml_task_hub:CurrentTask():AddSubTask(newTask)	
			gd("Starting alternate MOVETOINTERACT task.",2)
		end
	end
end

c_returntobase = inheritsFrom( ml_cause )
e_returntobase = inheritsFrom( ml_effect )
e_returntobase.pos = {}
function c_returntobase:evaluate()
	if (IsControlOpen("Gathering") or not ffxiv_gather.HasDirective()) then
		return false
	end
	
	e_returntobase.pos = {}
    
    if ( ml_task_hub:CurrentTask().gatherid ~= nil or ml_task_hub:CurrentTask().gatherid ~= 0 ) then
        local basePos = {}
	
		local task = ffxiv_gather.currentTask
		local marker = ml_marker_mgr.currentMarker
		if (table.valid(task)) then
			basePos = ffxiv_gather.GetCurrentTaskPos()
			if (task.mapid ~= Player.localmapid) then
				gd("[ReturnToBase]: Not on correct map yet.",3)
				return false
			end
			if (CanFlyInZone()) then
				local basePosCube = FindClosestMesh(basePos,20,true,true)
				if (basePosCube) then
					--d("using cube pos for marker")
					basePos = basePosCube
				else
					--d("didn't find a cube pos")
				end
			end
		elseif (table.valid(marker)) then
			basePos = marker:GetPosition()
		elseif gGatherMarkerOrProfileIndex == 3 then
			basePos = ml_task_hub:CurrentTask().pos
		end
		
		--local p = FindClosestMesh(basePos)
		--if (p and NavigationManager:IsReachable(p)) then
		--	basePos = p
		--end

		if (table.valid(basePos)) then
			local myPos = Player.pos
			local distance = PDistance3D(myPos.x, myPos.y, myPos.z, basePos.x, basePos.y, basePos.z)
			if (distance >= 30) then
				e_returntobase.pos = basePos
				return true
			else
				gd("[ReturnToBase]: Close to base position already.",3)
			end
		end
    end
    
    return false
end
function e_returntobase:execute()
	local range = 10
	
	local task = ffxiv_gather.currentTask
	ml_task_hub:CurrentTask().failedSearches = 0
	ml_task_hub:CurrentTask().taskFailed = 0
	
	if (table.valid(task)) then
		if (task.range and tonumber(task.range)) then
			range = tonumber(task.range)
		end
	end
	
	local pos = e_returntobase.pos
	
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = pos
	newTask.useTeleport = (gTeleportHack)
	newTask.range = range
	if (CanFlyInZone()) then
		newTask.alwaysMount = true
	end
	newTask.remainMounted = true
	newTask.stealthFunction = ffxiv_gather.NeedsStealth
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_nextgathermarker = inheritsFrom( ml_cause )
e_nextgathermarker = inheritsFrom( ml_effect )
function c_nextgathermarker:evaluate()
	if (Now() < ffxiv_gather.timer or IsControlOpen("Gathering")) then
		--d("Next gather marker, returning false in block1.")
		return false
	end
	if ((gBotMode == GetString("gatherMode")) and gGatherMarkerOrProfileIndex ~= 1) or (gBotMode ~= GetString("gatherMode")) then
		return false
	end
	
	local filter = "mapid="..tostring(Player.localmapid)
	if (gMarkerMgrMode ~= GetString("Single Marker")) then
		filter = filter..",minlevel<="..tostring(Player.level)..",maxlevel>="..tostring(Player.level)
	end
	
	local currentMarker = ml_marker_mgr.currentMarker
	local marker = nil
	local markerType = ""
	if (Player.job == FFXIV.JOBS.BOTANIST) then
		markerType = "Botany"
	else
		markerType = "Mining"
	end
	
	if (currentMarker == nil) then
		marker = ml_marker_mgr.GetNextMarker(markerType,filter)
	end
	
	if (gMarkerMgrMode == GetString("Marker Team")) then
		--d("Checking marker team section.")
		local gatherid = ml_task_hub:CurrentTask().gatherid or 0
		if (gatherid == 0 and ml_task_hub:CurrentTask().failedSearches > 5) then
			marker = ml_marker_mgr.GetNextMarker(markerType, filter)
		end
	end
	
	if (currentMarker) then
		if (marker == nil) then
			if (IsNull(currentMarker.timeout,0) > 0) then
				if (ml_task_hub:CurrentTask().taskFailed > 0 and TimeSince(ml_task_hub:CurrentTask().taskFailed) > currentMarker.timeout) then
			d("Marker Timed Out 1")
					marker = ml_marker_mgr.GetNextMarker(markerType, filter)
				end
			elseif (IsNull(currentMarker.timeout,0) == 0) then
				if (ml_task_hub:CurrentTask().taskFailed > 0 and TimeSince(ml_task_hub:CurrentTask().taskFailed) > 2) then
			d("Marker Timed Out 2")
					marker = ml_marker_mgr.GetNextMarker(markerType, filter)
				end
			end
		end
		
		-- next check to see if our level is out of range
		if (marker == nil) then
			if (not gMarkerMgrMode == GetString("Single Marker")) and (Player.level < currentMarker.minlevel or Player.level > currentMarker.maxlevel) then
				marker = ml_marker_mgr.GetNextMarker(markerType, filter)
			end
		end
		
		-- last check if our time has run out
		if (marker == nil) then
			if (currentMarker.duration > 0) then
				if (currentMarker:GetTimeRemaining() <= 0) then
					ml_debug("Getting Next Marker, TIME IS UP!")
					marker = ml_marker_mgr.GetNextMarker(markerType, filter)
				else
					return false
				end
			end
		end
	end
	
	if (marker ~= nil) then
		e_nextgathermarker.marker = marker
		return true
	end
    
    return false
end
function e_nextgathermarker:execute()
	Player:Stop()
    ml_marker_mgr.currentMarker = e_nextgathermarker.marker
	ml_marker_mgr.currentMarker:StartTimer()
    ml_global_information.MarkerMinLevel = ml_marker_mgr.currentMarker.minlevel
    ml_global_information.MarkerMaxLevel = ml_marker_mgr.currentMarker.maxlevel
	ml_global_information.BlacklistContentID = ml_marker_mgr.currentMarker.blacklist
    ml_global_information.WhitelistContentID = ml_marker_mgr.currentMarker.whitelist
	gStatusMarkerName = ml_marker_mgr.currentMarker:GetName()
	ml_task_hub:CurrentTask().gatherid = 0
	ml_global_information.gatherid = 0
	ml_task_hub:CurrentTask().failedSearches = 0
	ml_task_hub:CurrentTask().taskFailed = 0
end

function DoGathering(item)
	if (ffxiv_gather.CheckBuffs(item)) then
		gd("[Gather]: Running a buff check.",1)
		ml_global_information.Await(1500)
		return 1
	end
	
	if (SkillMgr.Gather(item)) then
		gd("[Gather]: Running a skillmanager process.",1)
		ml_global_information.Await(500)
		return 2
	end	
	
	local gatherindex = (item.index-1)
	gd("[Gather]: Using Gather ["..tostring(gatherindex).."].",1)
	Player:Gather(gatherindex)
	if (HasBuffs(Player,"805")) then
		ml_global_information.AwaitDo(10000, function () return IsControlOpen("GatheringMasterpiece") end, function () Player:Gather(gatherindex) end)
	end
	return 3
end

c_gather = inheritsFrom( ml_cause )
e_gather = inheritsFrom( ml_effect )
function c_gather:evaluate()
	if (IsControlOpen("Gathering")) then
		return true
	end
	
    return false
end
function e_gather:execute()	

	ml_task_hub:ThisTask().randomDelayCompleted = false

	if (Player.action ~= 264 and Player.action ~= 256 and not ActionList:IsReady()) then
		ml_task_hub:CurrentTask().idleTimer = Now()
		ml_debug("Gathering ability is not ready yet.")
		return false
	end
	
	if (Now() < ffxiv_gather.timer) then
		ml_debug("Cannot gather yet, timer still active for another ["..tostring((ffxiv_gather.timer - Now())/1000).."] seconds.")
		return false
	end
	
	local thisNode = MGetEntity(ml_global_information.gatherid)
	if not thisNode and (MGetTarget() and (MGetTarget().distance < 5 and MGetTarget().cangather and MGetTarget().targetable)) then
		thisNode = MGetTarget()
	end
	if (not table.valid(thisNode) or not thisNode.cangather or not thisNode.targetable) then
		return
	else
		if (table.valid(ffxiv_gather.currentTask)) then
			if (IsUnspoiled(thisNode.contentid) or IsNull(ffxiv_gather.currentTask.resetdaily,false)) then
				local profileName = (gBotMode == GetString("questMode") and gQuestProfile) or gGatherProfile
				ffxiv_gather.SetLastGather(profileName,ffxiv_gather.currentTaskIndex)
			end
		end
	end
	
    local list = MGatherableSlotList()
    if (table.valid(list)) then
		if (thisNode.contentid >= 5) then	
			if (TimeSince(ml_task_hub:CurrentTask().gatherTimer) < 500) then
				d("Still under a delay due to this being an unspoiled node.")
				return
			end
		end
		
		local gatherMaps = ""
		local gatherGardening = ""
		local gatherRares = false
		local gatherSuperRares = false
		local touchOnly = false
		local noGPGather = false

		local item1 = ""
		local item2 = ""
		local item3 = ""
		local nogpitem = ""
		local minimumGP = GetMinGP()

		local task = ffxiv_gather.currentTask
		local marker = ml_marker_mgr.currentMarker
		if (table.valid(task)) then
			gatherMaps = IsNull(task.gathermaps,"")
			gatherGardening = IsNull(task.gathergardening,"")
			gatherRares = IsNull(task.gatherrares,false)
			gatherSuperRares = IsNull(task.gatherspecialrares,false)
			gatherChocoFood = IsNull(task.gatherchocofood,false)
			touchOnly = IsNull(task.touchonly,false)
			item1 = IsNull(task.item1,"")
			item2 = IsNull(task.item2,"")
			item3 = IsNull(task.item3,"")
			nogpitem = IsNull(task.nogpitem,"")
			noGPGather = IsNull(task.nogpgather,false)
		elseif (table.valid(marker)) then
			gatherMaps = gQuickstartMaps
			gatherGardening = IsNull(marker.gathergardening,false)
			gatherRares = IsNull(marker.gatherrares,false)
			gatherChocoFood = IsNull(marker.gatherchocofood,false)
			item1 = IsNull(marker.item1,"")
			item2 = IsNull(marker.item2,"")
			item3 = IsNull(marker.item3,"")
		elseif gGatherMarkerOrProfileIndex == 3 then
			gatherMaps = gQuickstartMaps
			gatherGardening = gQuickstartGardening
			gatherRares = gQuickstartRares
			gatherChocoFood = gQuickstartChocoboFood
			item1 = gGatherQuickSlot
		end
		
		if (type(gatherGardening) == "string" and GUI_Get(gatherGardening) ~= nil) then
			gatherGardening = GUI_Get(gatherGardening)
		end
		if (type(gatherMaps) == "string" and GUI_Get(gatherMaps) ~= nil) then
			gatherMaps = GUI_Get(gatherMaps)
		end
		if (type(gatherRares) == "string" and GUI_Get(gatherRares) ~= nil) then
			gatherRares = GUI_Get(gatherRares)
		end
		if (type(gatherSuperRares) == "string" and GUI_Get(gatherSuperRares) ~= nil) then
			gatherSuperRares = GUI_Get(gatherSuperRares)
		end
		if (type(gatherChocoFood) == "string" and GUI_Get(gatherChocoFood) ~= nil) then
			gatherChocoFood = GUI_Get(gatherChocoFood)
		end
		if (type(item1) == "string" and GUI_Get(item1) ~= nil) then
			item1 = GUI_Get(item1)
		end
		if (type(item2) == "string" and GUI_Get(item2) ~= nil) then
			item2 = GUI_Get(item2)
		end
		if (type(item3) == "string" and GUI_Get(item3) ~= nil) then
			item3 = GUI_Get(item3)
		end
	
        if (touchOnly) then
            local gatheringControl = GetControl("Gathering")
            if (gatheringControl and gatheringControl:IsOpen()) then
                gatheringControl:Close()
                ml_global_information.Await(5000, function () return not IsControlOpen("Gathering") end)
				ffxiv_gather.currentTask.touchCompleted = true
				return 3
            end
        end

		-- 1st pass, maps
		if (gatherMaps ~= "" and gatherMaps ~= false and gatherMaps ~= "None") then
			local hasMap = false
			
			
			for i, item in pairs(list) do
				if ((IsMap(item.id)) and ItemCount(item.id) > 0) then
					hasMap = true
					d("Has Map")
				end
				
				if not hasMap then
					if (IsMap(item.id)) then
						local attemptGather = false
						if (gatherMaps == "Any" or gatherMaps == true) then
							attemptGather = true
						elseif (type(gatherMaps) == "string" and string.contains(gatherMaps,",")) then
							for map in StringSplit(gatherMaps,",") do
								if (tonumber(map) ~= nil and tonumber(map) == item.id) then
									attemptGather = true
								end
								if attemptGather then break end
							end
						elseif (tonumber(gatherMaps) ~= nil and tonumber(gatherMaps) == item.id) then
							attemptGather = true
						elseif (gatherMaps == "Gazelleskin Only" and item.id == 17836) then
							attemptGather = true
						elseif (gatherMaps == "Gaganaskin Only" and item.id == 17835) then
							attemptGather = true
						elseif (gatherMaps == "Dragonskin Only" and item.id == 12243) then
							attemptGather = true
						elseif (gatherMaps == "Peisteskin Only" and item.id == 6692) then
							attemptGather = true
						elseif (gatherMaps == "Gliderskin Only" and item.id == 26744) then
							attemptGather = true
						elseif (gatherMaps == "Zonureskin Only" and item.id == 26745) then
							attemptGather = true
						end
					
						if (attemptGather) then
							return DoGathering(item)
						end
					end
				end
			end
		end
			
		gd("Checking gardening section.",2)
			
		-- 2nd pass, gardening supplies
		if (gatherGardening ~= "" and gatherGardening ~= false ) then
			for i, item in pairs(list) do
				local attemptGather = false
				if (gatherGardening ~= "") then
					if ((gatherGardening  or gatherGardening == true) and IsGardening(item.id)) then
						attemptGather = true
					elseif (tonumber(gatherGardening) ~= nil and tonumber(gatherGardening) == item.id) then
						attemptGather = true
					elseif (type(gatherGardening) == "string" and string.contains(gatherGardening,",")) then
						for gardenitem in StringSplit(gatherGardening,",") do
							if (tonumber(gardenitem) ~= nil and tonumber(gardenitem) == item.id) then
								attemptGather = true
							end
							if attemptGather then break end
						end
					end
				end
				
				if (attemptGather) then
					return DoGathering(item)
				end
			end
		end
			
		gd("Checking special rare item section.",2)
			
		-- 3rd pass, try to get special rare items
		if (gatherSuperRares ~= "" and gatherSuperRares ~= false) then
			for i, item in pairs(list) do
				local attemptGather = false
				if (gatherSuperRares ~= "") then
					if ((gatherSuperRares  or gatherSuperRares == true) and IsRareItemSpecial(item.id)) then
						attemptGather = true
					elseif (tonumber(gatherSuperRares) ~= nil and tonumber(gatherSuperRares) == item.id) then
						attemptGather = true
					elseif (type(gatherSuperRares) == "string" and string.contains(gatherSuperRares,",")) then
						for srareitem in StringSplit(gatherSuperRares,",") do
							if (tonumber(srareitem) ~= nil and tonumber(srareitem) == item.id) then
								attemptGather = true
							end
							if attemptGather then break end
						end
					end
				end
				
				if (attemptGather) then
					return DoGathering(item)
				end
			end
		end
			
		gd("Checking ixali rare item section.",2)
						
		-- 5th pass, ixali rare items
		for i, item in pairs(list) do
			if (IsIxaliRare(item.id)) then
				local itemCount = ItemCount(item.id)
				if (itemCount < 5) then
					return DoGathering(item)
				end
			end
		end
		
		gd("Checking ixali semi-rare item section.",2)

		-- 6th pass, semi-rare ixali items
		for i, item in pairs(list) do
			if (IsIxaliSemiRare(item.id)) then
				local itemCount = ItemCount(item.id)
				if (itemCount < 15) then
					return DoGathering(item)
				end
			end
		end
		
		gd("Checking chocobo rare item section.",2)
		
		-- 7th pass to get chocobo rare items
		if (gatherChocoFood ~= "" and gatherChocoFood ~= false) then
			for i, item in pairs(list) do
				local attemptGather = false
				if (IsChocoboFoodSpecial(item.id)) then
					if (gatherChocoFood  or gatherChocoFood == true) then
						attemptGather = true
					elseif (tonumber(gatherChocoFood) ~= nil and tonumber(gatherChocoFood) == item.id) then
						attemptGather = true
					elseif (type(gatherChocoFood) == "string" and string.contains(gatherChocoFood,",")) then
						for chocoitem in StringSplit(gatherChocoFood,",") do
							if (tonumber(chocoitem) ~= nil and tonumber(chocoitem) == item.id) then
								attemptGather = true
							end
							if attemptGather then break end
						end
					end
				end
				
				if (attemptGather) then
					return DoGathering(item)
				end
			end
		end
		
		gd("Checking regular rare item section.",2)
		
		-- 4th pass, regular rare items
		if (gatherRares ~= "" and gatherRares ~= false) then
			for i, item in pairs(list) do
				local attemptGather = false
				if ((gatherRares  or gatherRares == true) and IsRareItem(item.id)) then
					attemptGather = true
				elseif (tonumber(gatherRares) ~= nil and tonumber(gatherRares) == item.id) then
					attemptGather = true
				elseif (type(gatherRares) == "string" and string.contains(gatherRares,",")) then
					for rareitem in StringSplit(gatherRares,",") do
						if (tonumber(rareitem) ~= nil and tonumber(rareitem) == item.id) then
							attemptGather = true
						end
						if attemptGather then break end
					end
				end
				
				if (attemptGather) then
					return DoGathering(item)
				end
			end
		end
		
		gd("Checking chocobo item section.",2)
		
		-- 7th pass to get chocobo items
		if (gatherChocoFood ~= "" and gatherChocoFood ~= false and gatherChocoFood) then
			for i, item in pairs(list) do
				local attemptGather = false
				if (IsChocoboFood(item.id)) then
					if (gatherChocoFood  or gatherChocoFood == true) then
						attemptGather = true
					elseif (tonumber(gatherChocoFood) ~= nil and tonumber(gatherChocoFood) == item.id) then
						attemptGather = true
					elseif (type(gatherChocoFood) == "string" and string.contains(gatherChocoFood,",")) then
						for chocoitem in StringSplit(gatherChocoFood,",") do
							if (tonumber(chocoitem) ~= nil and tonumber(chocoitem) == item.id) then
								attemptGather = true
							end
							if attemptGather then break end
						end
					end
				end
					
				if (attemptGather) then
					return DoGathering(item)
				end
			end
		end
		
		gd("Checking unknown item section.",2)
		
			-- Gather unknown items to unlock them.
		--if (Player.level < 70) then
		if (thisNode.contentid <= 4) then
			for i,item in pairs(list) do
				if (item.chance > 0 and (toboolean(item.isunknown))) then
					return DoGathering(item)
				end
			end
		end
		
		gd("Checking regular item section.",2)
		
		local itemid1 = 0
		local itemid2 = 0
		local itemid3 = 0
		local nogpitemid = 0
		
		local itemslot1 = 0
		local itemslot2 = 0
		local itemslot3 = 0
		local nogpitemslot = 0
		
		--d(AceLib.API.Items.GetIDByName("Silkworm Cocoon"))

		if (Player.gp.current < minimumGP or noGPGather) then
			if (nogpitem and nogpitem ~= "" and nogpitem ~= GetString("none")) then
				nogpitemid = AceLib.API.Items.GetIDByName(nogpitem) or 0
				if (nogpitemid == 0) then
					gd("[Gather]: Could not find a valid item ID for No GP Item - ["..tostring(nogpitem).."].",2)
				else
					ffxiv_gather.currentTask.nogpgather = true
					noGPGather = true
					gd("[Gather]: Setting nogpitemid to ["..tostring(nogpitemid).."]",2)
				end
			end
			if (tonumber(nogpitem) ~= nil) then
				nogpitemslot = tonumber(nogpitem)
				nogpitemid = tonumber(nogpitem)
				ffxiv_gather.currentTask.nogpgather = true
				noGPGather = true
				gd("[Gather]: Using slot for No GP item - ["..tostring(nogpitemslot).."].",2)
			end
		end

		if (item1 and item1 ~= "" and item1 ~= GetString("none")) then
			itemid1 = AceLib.API.Items.GetIDByName(item1) or 0
			if (itemid1 == 0) then
				gd("[Gather]: Could not find a valid item ID for Item 1 - ["..tostring(item1).."].",2)
			else
				gd("[Gather]: Setting itemid1 to ["..tostring(itemid1).."]",2)
			end
		end
		if (type(item1) == "number") then
			itemid1 = item1
		end
		if (tonumber(item1) ~= nil) then
			itemslot1 = tonumber(item1)
			gd("[Gather]: Using slot for item 1 - ["..tostring(itemslot1).."].",2)
		end
		
		if (item2 and item2 ~= "" and item2 ~= GetString("none")) then
			itemid2 = AceLib.API.Items.GetIDByName(item2) or 0
			if (itemid2 == 0) then
				gd("[Gather]: Could not find a valid item ID for Item 2 - ["..tostring(item2).."].",2)
			else
				gd("[Gather]: Setting itemid2 to ["..tostring(itemid2).."]",2)
			end
		end
		if (type(item2) == "number") then
			itemid2 = item2
		end
		if (tonumber(item2) ~= nil) then
			itemslot2 = tonumber(item2)
			gd("[Gather]: Using slot for item 2 - ["..tostring(itemslot2).."].",2)
		end
		
		if (item3 and item3 ~= "" and item3 ~= GetString("none")) then
			itemid3 = AceLib.API.Items.GetIDByName(item3) or 0
			if (itemid3 == 0) then
				gd("[Gather]: Could not find a valid item ID for Item 3 - ["..tostring(item3).."].",2)
			else
				gd("[Gather]: Setting itemid3 to ["..tostring(itemid3).."]",2)
			end
		end
		if (type(item3) == "number") then
			itemid3 = item3
		end
		if (tonumber(item3) ~= nil) then
			itemslot3 = tonumber(item3)
			gd("[Gather]: Using slot for item 3 - ["..tostring(itemslot3).."].",2)
		end
		
		for i, item in pairs(list) do
			if (nogpitemid ~= 0) then
				if (item.id == nogpitemid) then
				gd("gather no gp item")
					return DoGathering(item)
				end
			end

			if (nogpitemslot ~= 0) then
				if (item.index == nogpitemslot and item.id ~= nil) then
					gd("[Gather]: Run gathering procedure for item nogpitemslot ["..item.name.."]",2)
					return DoGathering(item)
				end
			end
		end
		
		for i, item in pairs(list) do
			if (itemid1 ~= 0) then
				if (gBotMode ~= GetString("gatherMode") or (gBotMode == GetString("gatherMode") and gGatherMarkerOrProfileIndex ~= 3)) and (item.id == itemid1) then
					gd("[Gather]: Run gathering procedure for itemid1 ["..item.name.."]",2)
					return DoGathering(item)
				end
			end
					
			if (itemslot1 ~= 0) then
				if (item.index == itemslot1 and item.id ~= nil) then
					gd("[Gather]: Run gathering procedure for itemslot1 ["..item.name.."]",2)
					return DoGathering(item)
				end
			end
		end
		
		for i, item in pairs(list) do
			if (itemid2 ~= 0) then
				if (item.id == itemid2) then
					gd("[Gather]: Run gathering procedure for item itemid2 ["..item.name.."]",2)
					return DoGathering(item)
				end
			end
				
			if (itemslot2 ~= 0) then
				if (item.index == itemslot2 and item.id ~= nil) then
					gd("[Gather]: Run gathering procedure for itemslot2 ["..item.name.."]",2)
					return DoGathering(item)
				end
			end
		end
		
		for i, item in pairs(list) do
			if (itemid3 ~= 0) then
				if (item.id == itemid3) then
					gd("[Gather]: Run gathering procedure for item itemid3 ["..item.name.."]",2)
					return DoGathering(item)
				end
			end
				
			if (itemslot3 ~= 0) then
				if (item.index == itemslot3 and item.id ~= nil) then
					gd("[Gather]: Run gathering procedure for itemslot3 ["..item.name.."]",2)
					return DoGathering(item)
				end
			end
		end
		
		--d("Checking unknown items, couldn't find any regular items.")
			
		-- Gather unknown items to unlock them.
		for i,item in pairs(list) do
			if (toboolean(item.isunknown) or (IsUnspoiled(thisNode.contentid) and item.chance == 25 and (item.name == "" or item.name == nil))) then
				gd("[Gather]: unknown - ["..tostring(item.id).."].",2)
				return DoGathering(item)
			end
		end
		
		--d("Checking random items with good chance.")
			
		-- just grab a random item with good chance
		for i, item in pairs(list) do
			if (not IsMap(item.id)) then
				if (item.chance > 50) then
					gd("[Gather]: chance - ["..tostring(item.id).."].",2)
					return DoGathering(item)
				end
			end
		end
		
		--d("Checking random items.")
		
		-- just grab a random item - last resort
		for i, item in pairs(list) do
			if (not IsMap(item.id)) then
				gd("[Gather]: map - ["..tostring(item.id).."].",2)
				return DoGathering(item)
			end
		end
    end
end

function ffxiv_gather.CheckBuffs(item)
	local canCollect = false

	local valuepairs = {
		[gMinerCollectibleName or ""] = gMinerCollectibleValue or 0,
		[gMinerCollectibleName2 or ""] = gMinerCollectibleValue2 or 0,
		[gMinerCollectibleName3 or ""] = gMinerCollectibleValue3 or 0,
		[gBotanistCollectibleName or ""] = gBotanistCollectibleValue or 0,
		[gBotanistCollectibleName2 or ""] = gBotanistCollectibleValue2 or 0,
		[gBotanistCollectibleName3 or ""] = gBotanistCollectibleValue3 or 0,
	}

	for k,v in pairs(valuepairs) do
		if ((not k or k == "") or
			(not v or not tonumber(v) or tonumber(v) <= 0))
		then
			valuepairs[k] = nil
		end
	end
		
	local idpairs = {}
	for k,v in pairs(valuepairs) do
		local itemid;
		if (type(k) == "string") then
			itemid = AceLib.API.Items.GetIDByName(k)
		else
			itemid = k
		end
		
		if (itemid) then
			idpairs[itemid] = v
		end
	end
		
	local task = ffxiv_gather.currentTask
	local collectCost = 0
		
	if (table.valid(task)) then
		local collectables = task.collectables
		collectCost = IsNull(task.collectGP,0)
		if (task.collectGP and type(task.collectGP) == "string") then
			collectCost = IsNull(tonumber(SkillMgr.ProfileRaw.mingp),0)
		else
			collectCost = IsNull(tonumber(task.collectGP),collectCost)
		end		
		
		if (table.valid(collectables)) then
			for identifier,minvalue in pairs(collectables) do
				local itemid;
				if (type(identifier) == "string") then
					
					if (GUI_Get(identifier) ~= nil) then
						local var = identifier
						identifier = GUI_Get(var)
						d("Converted identifier var ["..var.."] to ["..identifier.."]")
					end
				
					itemid = AceLib.API.Items.GetIDByName(identifier)
				else
					itemid = identifier
				end
				
				if (type(minvalue) == "string") then
					if (GUI_Get(minvalue) ~= nil) then
						local var = minvalue
						minvalue = GUI_Get(minvalue)
						d("Converted value var ["..var.."] to ["..minvalue.."]")
					end
				end
		
				if (itemid) then
					idpairs[itemid] = minvalue
				end
			end
		end
	end
	
	local gatherable = EntityList:Get(ml_task_hub:ThisTask().gatherid)
	local maxAttempts = false
	if (gatherable and gatherable.gatherattempts and gatherable.gatherattemptsmax) then
		if (gatherable.gatherattempts == gatherable.gatherattemptsmax) or (gatherable.contentid > 4) then
			maxAttempts = true
		end
	end
	
	local hasCollect = HasBuffs(Player,"805")
	local isCollectable = ((maxAttempts and Player.gp.current >= collectCost)) and (idpairs[item.id] ~= nil) and not toboolean(item.isunknown)
	if ((hasCollect and not isCollectable) or (not hasCollect and isCollectable)) then
		local collect = ActionList:Get(1,ffxiv_gather.collectors[Player.job])
		if (collect and collect:IsReady(Player.id)) then
			if (collect:Cast()) then
				if (not hasCollect) then
					ml_global_information.Await(2500, function () return HasBuff(Player.id,805) end)
				else
					ml_global_information.Await(2500, function () return MissingBuff(Player.id,805) end)
				end
			end
		end
		return true
	end
	
	return false
end

function ffxiv_gather.GetLowestValue(...)
	local lowestValue = math.huge
	
	local vals = {...}
	if (table.valid(vals)) then
		for k,value in pairs(vals) do
			if (value < lowestValue) then
				lowestValue = value
			end
		end
	end
	
	return lowestValue
end
function CanUseCordialSoon()
	local minimumGP = GetMinGP()
	local useCordials = false
		
	local task = ffxiv_gather.currentTask
	if (table.valid(task)) then
		if (task.usecordials and type(task.usecordials) == "string") then
			local ok, ret = LoadString("return " .. task.usecordials)
			if (ok and ret ~= nil) then
				if (ret == true) then
					useCordials = true
				end
			end
		end
	end
	
	local highGp, normGp, wateredGP = ghighCordialsGP, gnormCordialsGP, gwateredCordialsGP
	if IsFisher(Player.job) then
		highGp = gFishhighCordialsGP
		normGp = gFishnormCordialsGP
		wateredGP = gFishwateredCordialsGP
	end
	
	if (useCordials) then
		local cordialQuick, cordialQuickAction = GetItem(1016911)
		if (not cordialQuick) then
			cordialQuick, cordialQuickAction = GetItem(16911)
		end
		local cordialNormal, cordialNormalAction = GetItem(1006141)
		if (not cordialNormal) then
			cordialNormal, cordialNormalAction = GetItem(6141)
		end
		local cordialHigh, cordialHighAction = GetItem(1012669)
		if (not cordialHigh) then
			cordialHigh, cordialHighAction = GetItem(12669)
		end
		
		local gpDeficit = (Player.gp.max - Player.gp.current)
		local missingNormal = (cordialNormalAction == nil)
		local missingQuick = (cordialQuickAction == nil)
		local lowestRequired = ffxiv_gather.GetLowestValue(highGp,normGp,wateredGP)
		
		if gpDeficit >= lowestRequired then		
			if not IsFisher(Player.job) or (IsFisher(Player.job) and (HasBuff(Player,764,0,40) or HasBuff(Player,762,0,40) or Player.level < 51)) then
				--if cordialHigh and ((gpDeficit >= highGp) or ((missingNormal and (gpDeficit >= normGp)) and (missingQuick and (gpDeficit >= wateredGP)))) then
				if cordialHigh and (gpDeficit >= highGp) then
					if (cordialHigh and cordialHighAction and (cordialHighAction.cdmax - cordialHighAction.cd) < 5) then
						gdd("[CanUseCordialSoon]: Returning Min. High cordial.")
						return true, cordialHigh
					end
				--elseif cordialNormal and ((gpDeficit >= normGp) or (missingQuick and (gpDeficit >= wateredGP))) then
				elseif cordialNormal and (gpDeficit >= normGp) then
					if (cordialNormal and cordialNormalAction and (cordialNormalAction.cdmax - cordialNormalAction.cd) < 5) then
						gdd("[CanUseCordialSoon]: Returning Min. Cordial.")
						return true, cordialNormal
					end
				elseif cordialQuick and (gpDeficit >= wateredGP) then
					if (cordialQuick and cordialQuickAction and (cordialQuickAction.cdmax - cordialQuickAction.cd) < 5) then
						gdd("[CanUseCordialSoon]: Returning Min. Quick cordial.")
						return true, cordialQuick
					end
				end
			end
		end
	else
		--ml_debug("[ffxiv_gather.CanUseCordialSoons]: Can't use cordials on this task.",2)
	end
	
	return false, nil
end

function CanUseCordial()
	local minimumGP = GetMinGP()
	local useCordials = false
			
	local task = ffxiv_gather.currentTask
	if (table.valid(task)) then
		if (task.usecordials and type(task.usecordials) == "string") then
			local ok, ret = LoadString("return " .. task.usecordials)
			if (ok and ret ~= nil) then
				if (ret == true) then
					useCordials = true
				end
			end
		end
	end
	
	local highGp, normGp, wateredGP = ghighCordialsGP, gnormCordialsGP, gwateredCordialsGP
	if IsFisher(Player.job) then
		highGp = gFishhighCordialsGP
		normGp = gFishnormCordialsGP
		wateredGP = gFishwateredCordialsGP
	end
	
	if (useCordials) then
		local cordialQuick, cordialQuickAction = GetItem(1016911)
		if (not cordialQuick) then
			cordialQuick, cordialQuickAction = GetItem(16911)
		end
		local cordialNormal, cordialNormalAction = GetItem(1006141)
		if (not cordialNormal) then
			cordialNormal, cordialNormalAction = GetItem(6141)
		end
		local cordialHigh, cordialHighAction = GetItem(1012669)
		if (not cordialHigh) then
			cordialHigh, cordialHighAction = GetItem(12669)
		end		
		
		local gpDeficit = (Player.gp.max - Player.gp.current)
		local missingNormal = (cordialNormalAction == nil)
		local missingQuick = (cordialQuickAction == nil)
		local lowestRequired = ffxiv_gather.GetLowestValue(highGp,normGp,wateredGP)
		
		if gpDeficit >= lowestRequired then			
			if not IsFisher(Player.job) or (IsFisher(Player.job) and (HasBuff(Player,764,0,40) or HasBuff(Player,762,0,40) or Player.level < 51)) then
				--if cordialHigh and ((gpDeficit >= highGp) or (missingNormal and missingQuick)) then
				if cordialHigh and (gpDeficit >= highGp) then
					if (cordialHigh and cordialHighAction and not cordialHighAction.isoncd) then
						gdd("[CanUseCordial]: Returning High cordial.")
						return true, cordialHigh
					end
				--elseif cordialNormal and ((gpDeficit >= normGp) or (missingQuick)) then
				elseif cordialNormal and (gpDeficit >= normGp) then
					if (cordialNormal and cordialNormalAction and not cordialNormalAction.isoncd) then
						gdd("[CanUseCordial]: Returning Cordial.")
						return true, cordialNormal
					end
				elseif cordialQuick and (gpDeficit >= wateredGP) then
					if (cordialQuick and cordialQuickAction and not cordialQuickAction.isoncd) then
						gdd("[CanUseCordial]: Returning Quick cordial.")
						return true, cordialQuick
					end
				end
			end
		end
	else
		--fd("[ffxiv_gather.CanUseCordials]: Can't use cordials on this task.",1)
	end
	
	return false, nil
end

function CanUseExpManual()
	if (not gUseExpManuals) then
		return false
	end
	
	if (IsGatherer(Player.job) or IsFisher(Player.job)) then
		if (Player.level >= 70 and MissingBuff(Player,46)) then
            local revised, action = GetItem(26553)
            if (revised and action and not action.isoncd) then
                --d("Can use revised manual.")
                return true, revised
            end
        end
		
		if (Player.level >= 60 and MissingBuff(Player,1081)) then
			local squadron, action = GetItem(14949)
			if (squadron and action and not action.isoncd) then
				--d("Can use squadron manual.")
				return true, squadron
			end
		end
		
		if (Player.level >= 15 and Player.level < 80 and MissingBuff(Player,46)) then
			local commercial, action = GetItem(12668)
			local manual2, action2 = GetItem(4635)
			local manual1, action1 = GetItem(4633)
			
			
			if commercial then
				if (commercial and action and not action.isoncd) then
					--d("Can use commercial manual.")
					return true, commercial
				end
			elseif manual2 then 
				if (manual2 and action2 and not action2.isoncd) then
					--d("Can use level 2 manual.")
					return true, manual2
				end
			elseif manual1 then 
				if (manual1 and action1 and not action1.isoncd) then
					return true, manual1
				end
			end
		end
	elseif (IsCrafter(Player.job)) then
		if (Player.level >= 70 and MissingBuff(Player,45)) then
            local revised, action = GetItem(26554)
            if (revised and action and not action.isoncd) then
                --d("Can use revised manual.")
                return true, revised
            end
        end
		
		if (Player.level >= 60 and MissingBuff(Player,1082)) then
			local squadron, action = GetItem(14949)
			if (squadron and action and not action.isoncd) then
				--d("Can use squadron manual.")
				return true, squadron
			end
		end
					
		if (Player.level >= 15 and Player.level < 80 and MissingBuff(Player,45)) then
			local commercial, action = GetItem(12667)
			local manual2, action2 = GetItem(4634)
			local manual1, action1 = GetItem(4632)
			
			if commercial then
				if (commercial and action and not action.isoncd) then
					--d("Can use commercial manual.")
					return true, commercial
				end
			elseif manual2 then 
				if (manual2 and action2 and not action2.isoncd) then
					--d("Can use level 2 manual.")
					return true, manual2
				end
			elseif manual1 then 
				if (manual1 and action1 and not action1.isoncd) then
					return true, manual1
				end
			end
		end
	end
	return false, nil
end

c_nodeprebuff = inheritsFrom( ml_cause )
e_nodeprebuff = inheritsFrom( ml_effect )
e_nodeprebuff.activity = ""
e_nodeprebuff.item = nil
e_nodeprebuff.itemid = 0
e_nodeprebuff.class = nil
e_nodeprebuff.requirestop = false
e_nodeprebuff.requiredismount = false
function c_nodeprebuff:evaluate()
	if (MIsLoading() or MIsCasting() or CannotMove() or 
		IsControlOpen("Gathering") or IsControlOpen("GatheringMasterpiece")) then
		return false
	end
	
	e_nodeprebuff.activity = ""
	e_nodeprebuff.item = nil
	e_nodeprebuff.itemid = 0
	e_nodeprebuff.class = nil
	e_nodeprebuff.requirestop = false
	e_nodeprebuff.requiredismount = false
	
	if (not MIsLocked()) then
		if (ShouldEat()) then
			d("[NodePreBuff]: Need to eat.")
			e_nodeprebuff.activity = "eat"
			e_nodeprebuff.requirestop = false
			e_nodeprebuff.requiredismount = false
			return true
		end
		
		local canUse,manualItem = CanUseExpManual()
		if (canUse and table.valid(manualItem)) then
			d("[NodePreBuff]: Need to use a manual, grabbed item ["..tostring(manualItem.hqid).."]")
			e_nodeprebuff.activity = "usemanual"
			e_nodeprebuff.itemid = manualItem.hqid
			e_nodeprebuff.requirestop = true
			e_nodeprebuff.requiredismount = true
			return true
		end
	end
	
	local skillProfile = ""
	local minimumGP = GetMinGP()
	local useCordials = (gGatherUseCordials )
	local taskType = ""
	local useFavor = 0
	local useFood = 0
	
	local profile = ffxiv_gather.profileData
	local task = ffxiv_gather.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		if (IsNull(task.skillprofile,"") ~= "" and IsNull(task.skillprofile,"") ~= GetString("none")) then
			skillProfile = task.skillprofile
		end
		useCordials = IsNull(task.usecordials,useCordials)
		taskType = IsNull(task.type,"")
		useFavor = IsNull(task.favor,0)
		useFood = IsNull(task.food,0)
	elseif (table.valid(marker)) then
		if (IsNull(marker.skillprofile,"") ~= "" and IsNull(marker.skillprofile,"") ~= GetString("none")) then
			skillProfile = marker.skillprofile
		end
		useCordials = IsNull(marker.usecordials,useCordials)
		taskType = IsNull(marker.type,"x")
		useFavor = IsNull(marker.favor,0)
		useFood = IsNull(marker.food,0)
	end
							
	if (type(skillProfile) == "string" and GUI_Get(skillProfile) ~= nil) then
		skillProfile = GUI_Get(skillProfile)
	end
	if (type(useCordials) == "string" and GUI_Get(useCordials) ~= nil) then
		useCordials = GUI_Get(useCordials)
	end
	if (type(useFavor) == "string" and GUI_Get(useFavor) ~= nil) then
		useFavor = GUI_Get(useFavor)
	end
	if (type(useFood) == "string" and GUI_Get(useFood) ~= nil) then
		useFood = GUI_Get(useFood)
	end
	
	if (taskType == "idle" or taskType == "") then
		return false
	end
	
	if (skillProfile ~= "" and gSkillProfile ~= skillProfile) then -- fix later
		if (SkillMgr.HasProfile(skillProfile)) then
			d("[NodePreBuff]: Need to switch to profile ["..skillProfile.."].")
			SkillMgr.UseProfile(skillProfile)
			e_nodeprebuff.activity = "switchprofile"
			e_nodeprebuff.requirestop = false
			e_nodeprebuff.requiredismount = false
			return true
		else
			if (skillProfile == GetString("none")) then
				d("[NodePreBuff]: Need to switch to profile ["..skillProfile.."].")
				SkillMgr.UseProfile(skillProfile)
				e_nodeprebuff.activity = "switchprofile"
				e_nodeprebuff.requirestop = false
				e_nodeprebuff.requiredismount = false
				return true
			end
			gd("Profile ["..skillProfile.."] was not found.",3)
		end
	end
	
	if (IsNull(ml_task_hub:ThisTask().gatherid,0) ~= 0 and not MIsLocked()) then
        local gatherable = EntityList:Get(ml_task_hub:ThisTask().gatherid)
        if (gatherable and gatherable.cangather and gatherable.targetable) then
			if (gatherable.distance <= 15) then
				if (useCordials) then
					local canUse,cordialItem = CanUseCordial()
					if (canUse and table.valid(cordialItem)) then
						d("[NodePreBuff]: Need to use a cordial.")
						e_nodeprebuff.activity = "usecordial"
						e_nodeprebuff.itemid = cordialItem.hqid
						e_nodeprebuff.requirestop = false
						e_nodeprebuff.requiredismount = false
						return true
					end					
				end
				
				if (useFavor ~= 0) then
					local favors = {
						[10374] = 881,
						[10375] = 883,
						[10376] = 882,
						[10377] = 884,
						[10378] = 885,
						[10379] = 886,
						[10380] = 887,
						[10381] = 889,
						[10382] = 888,
						[10383] = 890,
						[10384] = 891,
						[10385] = 892,
					}
					
					local favorBuff = favors[useFavor]
					if (favorBuff) then
						if (MissingBuff(Player.id, favorBuff)) then
							if (ItemCount(useFavor) > 0) then
								local favor, action = GetItem(useFavor)
								if (favor and action and favor:IsReady(Player.id)) then
									e_nodeprebuff.activity = "usefavor"
									e_nodeprebuff.itemid = favor.hqid
									e_nodeprebuff.requirestop = true
									e_nodeprebuff.requiredismount = true
									return true
								end
							end
						end
					end
				end
			end
			
			if (useFood ~= 0) then
				local food, action = GetItem(useFood)
				if (food and action and food:IsReady(Player.id) and MissingBuffs(Player,"48",60)) then
					e_nodeprebuff.activity = "usefood"
					e_nodeprebuff.itemid = food.hqid
					e_nodeprebuff.requirestop = false
					e_nodeprebuff.requiredismount = false
					return true
				end
			end
        end
    end
	
	if (taskType ~= "") then
		if (taskType == "botany") then
			if (Player.job ~= FFXIV.JOBS.BOTANIST) then
				if (CanSwitchToClass(FFXIV.JOBS.BOTANIST)) then
					if (table.valid(profile) and table.valid(profile.setup) and IsNull(profile.setup.gearsetbotany,0) ~= 0) then
						d("Attempting to change to gearset ["..tostring(profile.setup.gearsetbotany).."]")
						local commandString = "/gs change "..tostring(profile.setup.gearsetbotany)
						SendTextCommand(commandString)
						e_nodeprebuff.activity = "switchclasslegacy"
						e_nodeprebuff.requirestop = true
						e_nodeprebuff.requiredismount = false
						return true
					else
						e_nodeprebuff.activity = "switchclass"
						e_nodeprebuff.class = FFXIV.JOBS.BOTANIST
						e_nodeprebuff.requirestop = true
						e_nodeprebuff.requiredismount = false
						return true
					end
				else
					local gsvar = "gGearset"..tostring(FFXIV.JOBS.BOTANIST)
					if (_G[gsvar] ~= 0) then
						e_nodeprebuff.activity = "switchclass"
						e_nodeprebuff.class = FFXIV.JOBS.BOTANIST
						e_nodeprebuff.requirestop = true
						e_nodeprebuff.requiredismount = false
					else
						d("Cannot swap yet, but we have no choice, wait a second")
						e_nodeprebuff.activity = "switchclasslegacy"
						return true
					end
				end
			end
		elseif (taskType == "mining") then
			if (Player.job ~= FFXIV.JOBS.MINER) then
				if (CanSwitchToClass(FFXIV.JOBS.MINER)) then
					if (table.valid(profile) and table.valid(profile.setup) and IsNull(profile.setup.gearsetmining,0) ~= 0) then
						d("Attempting to change to gearset ["..tostring(profile.setup.gearsetmining).."]")
						local commandString = "/gs change "..tostring(profile.setup.gearsetmining)
						SendTextCommand(commandString)
						e_nodeprebuff.activity = "switchclasslegacy"
						e_nodeprebuff.requirestop = true
						e_nodeprebuff.requiredismount = false
						return true
					else
						e_nodeprebuff.activity = "switchclass"
						e_nodeprebuff.class = FFXIV.JOBS.MINER
						e_nodeprebuff.requirestop = true
						e_nodeprebuff.requiredismount = false
						return true
					end
				else
					local gsvar = "gGearset"..tostring(FFXIV.JOBS.MINER)
					if (_G[gsvar] ~= 0) then
						e_nodeprebuff.activity = "switchclass"
						e_nodeprebuff.class = FFXIV.JOBS.MINER
						e_nodeprebuff.requirestop = true
						e_nodeprebuff.requiredismount = false
					else
						d("Cannot swap yet, but we have no choice, wait a second")
						e_nodeprebuff.activity = "switchclasslegacy"
						return true
					end
				end
			end
		end
	end
	
	if (MissingBuffs(Player,"217+225")) then
		d("[NodePreBuff]: Need to use our locator buff.")
		e_nodeprebuff.activity = "uselocator"
		e_nodeprebuff.requirestop = false
		e_nodeprebuff.requiredismount = false
		return true
	end
	
	if ((Player.job == FFXIV.JOBS.MINER or Player.job == FFXIV.JOBS.BOTANIST) and 
		Player.level >= 46 and 
		MissingBuffs(Player,"221+222"))
	then
		d("[NodePreBuff]: Need to use our unspoiled finder.")
		e_nodeprebuff.activity = "useunspoiledfinder"
		e_nodeprebuff.requirestop = false
		e_nodeprebuff.requiredismount = false
		return true
	end		
	
	return false
end
function e_nodeprebuff:execute()
	local activity = e_nodeprebuff.activity
	local activityclass = e_nodeprebuff.class
	local activityitem = e_nodeprebuff.item
	local activityitemid = e_nodeprebuff.itemid
	local requirestop = e_nodeprebuff.requirestop
	local requiredismount = e_nodeprebuff.requiredismount
	d("activity = "..tostring(activity))
	if (requirestop and Player:IsMoving()) then
		Player:PauseMovement()
		ml_global_information.Await(1500, function () return not Player:IsMoving() end)
		return
	end
	
	if (requiredismount and Player.ismounted) then
		Dismount()
		ml_global_information.Await(2500, function () return (not Player.ismounted) end)
		return
	end
	
	if (activity == "eat") then
		Eat()
		ml_global_information.Await(4000, function () return HasBuff(Player.id, 48) end)
		return
	end
	
	if (activity == "switchprofile") then
		-- Only block execution.
		ml_task_hub:ThisTask().preserveSubtasks = true
		return
	end
	
	if (activity == "usemanual") then
		local manual = GetItem(activityitemid)
		if (manual and manual:IsReady(Player.id)) then
			manual:Cast(Player.id)
			ml_global_information.Await(2000, 4000, function () return HasBuff(Player.id, 46) end)
			return
		end
	end
	
	if (activity == "usefood") then
		local food = GetItem(activityitemid)
		if (food and action and food:IsReady(Player.id)) then
			food:Cast(Player.id)
			ml_global_information.Await(4000, function () return HasBuff(Player.id, 48) end)
			return
		end
	end
	
	if (activity == "usefavor") then
		local favors = {
			[10374] = 881,
			[10375] = 883,
			[10376] = 882,
			[10377] = 884,
			[10378] = 885,
			[10379] = 886,
			[10380] = 887,
			[10381] = 889,
			[10382] = 888,
			[10383] = 890,
			[10384] = 891,
			[10385] = 892,
		}
		
		local favorBuff = favors[activityitemid]
		local favor = GetItem(activityitemid)
		if (favor and favor:IsReady(Player.id)) then
			favor:Cast(Player.id)
			ml_global_information.Await(4000, function () return (HasBuff(Player.id, favorBuff)) end)
			return
		end
	end
	
	if (activity == "usecordial") then
		local cordial, action = GetItem(activityitemid)
		if (cordial and action and not action.isoncd) then
			cordial:Cast(Player.id)
			local castid = action.id
			ml_global_information.Await(5000, function () return Player.castinginfo.lastcastid == castid end)
			return
		end
	end
	
	if (activity == "switchclasslegacy") then
		ml_global_information.Await(2000)
		return
	end
	
	if (activity == "switchclass") then
		local newTask = ffxiv_misc_switchclass.Create()
		newTask.class = activityclass
		ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
		ml_task_hub:ThisTask().preserveSubtasks = true
		return
	end
	
	if (activity == "uselocator") then
		ffxiv_gather.VisibilityBuff(Player.job)
		ml_global_information.Await(2500, function () return HasBuffs(Player,"217,225") end)
		return
	end
	
	if (activity == "useunspoiledfinder") then
		ffxiv_gather.LocatorBuff(Player.job)
		ml_global_information.Await(2500, function () return HasBuffs(Player,"221,222") end)
		return
	end
end

c_gatherflee = inheritsFrom( ml_cause )
e_gatherflee = inheritsFrom( ml_effect )
e_gatherflee.fleePos = {}
function c_gatherflee:evaluate()
	if (IsControlOpen("Gathering")) then
		return false
	end
	
	if (Player.incombat and not Player:IsMoving() and ml_task_hub:CurrentTask().name ~= "MOVETOPOS") then
		local ppos = Player.pos
		
		local evacPoint = GetNearestEvacPoint()
		if (evacPoint) then
			local fpos = evacPoint.pos
			if (Distance3D(ppos.x, ppos.y, ppos.z, fpos.x, fpos.y, fpos.z) > 50) then
				if (ml_navigation:CheckPath(fpos,true)) then
					e_gatherflee.fleePos = fpos
					return true
				end
			end
		end
		
		for i = 1,10 do
			local newPos = NavigationManager:GetRandomPointOnCircle(ppos.x,ppos.y,ppos.z,100,200)
			if (table.valid(newPos)) then
				local p = FindClosestMesh(newPos,30,false)
				if (p and ml_navigation:CheckPath(p,true)) then
					e_gatherflee.fleePos = p
					return true
				end
			end
		end		
	end
    
    return false
end
function e_gatherflee:execute()
	local fleePos = e_gatherflee.fleePos
	if (table.valid(fleePos)) then
		local newTask = ffxiv_task_flee.Create()
		newTask.pos = fleePos
		newTask.useTeleport = (gTeleportHack)
		newTask.task_complete_eval = 
			function ()
				return not Player.incombat
			end
		newTask.task_fail_eval = 
			function ()
				return (not Player.alive) or (Player.incombat and math.distance3d(Player.pos,fleePos) < 2)
			end
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	else
		ml_error("Need to flee but no evac position defined for this mesh!!")
	end
end

--[[
GatheringMasterpiece
.rarity
.raritymax
.wear
.wearmax
.chance
.chancehq
--]]

function SetMasterpieceLocation()

end

function GetMasterpieceLocation()

end

c_collectiblegame = inheritsFrom( ml_cause )
e_collectiblegame = inheritsFrom( ml_effect )
e_collectiblegame.timer = 0
function c_collectiblegame:evaluate()
	if (IsControlOpen("GatheringMasterpiece")) then
		--d("[CollectableGame]: Found the gathering masterpiece addon.")
		return true
	end
	return false
end
function e_collectiblegame:execute()
	if (Now() < e_collectiblegame.timer or MIsCasting()) then
		return 
	end
	
	gd("[CollectableGame]: Checking collectable info.",1)
	local info = GetControlData("GatheringMasterpiece")
	if (table.valid(info)) then
		local valuepairs = {
			[gMinerCollectibleName or ""] = gMinerCollectibleValue or 0,
			[gMinerCollectibleName2 or ""] = gMinerCollectibleValue2 or 0,
			[gMinerCollectibleName3 or ""] = gMinerCollectibleValue3 or 0,
			[gBotanistCollectibleName or ""] = gBotanistCollectibleValue or 0,
			[gBotanistCollectibleName2 or ""] = gBotanistCollectibleValue2 or 0,
			[gBotanistCollectibleName3 or ""] = gBotanistCollectibleValue3 or 0,
		}

		for k,v in pairs(valuepairs) do
			if ((not k or k == "") or
				(not v or not tonumber(v) or tonumber(v) <= 0))
			then
				valuepairs[k] = nil
			end
		end
		
		local idpairs = {}
		for k,v in pairs(valuepairs) do
			local itemid;
			if (type(k) == "string") then
				itemid = AceLib.API.Items.GetIDByName(k)
			else
				itemid = k
			end
			
			if (itemid) then
				idpairs[itemid] = v
			end
		end
		
		local task = ffxiv_gather.currentTask
		if (table.valid(task)) then
			local collectables = task.collectables
			if (table.valid(collectables)) then
				for identifier,minvalue in pairs(collectables) do
					local itemid;
					if (type(identifier) == "string") then
						
						if (GUI_Get(identifier) ~= nil) then
							local var = identifier
							identifier = GUI_Get(var)
							d("Converted identifier var ["..var.."] to ["..identifier.."]")
						end
					
						itemid = AceLib.API.Items.GetIDByName(identifier)
					else
						itemid = identifier
					end
					
					if (type(minvalue) == "string") then
						if (GUI_Get(minvalue) ~= nil) then
							local var = minvalue
							minvalue = GUI_Get(minvalue)
							d("Converted value var ["..var.."] to ["..minvalue.."]")
						end
					end
			
					if (itemid) then
						idpairs[itemid] = minvalue
					end
				end
			end
		end
		
		local requiredRarity = 0
		if (table.valid(idpairs)) then
			for itemid,cval in pairs(idpairs) do
				if (ffxiv_gather.lastItemAttempted == itemid) then
					d("[CollectableGame]: Setting required rarity to ["..tostring(cval).."].")
					requiredRarity = cval
				end
				if (requiredRarity ~= 0) then
					break
				end
			end
		end
					
		gd("Item current rarity ["..tostring(info.rarity).."].",1)
		gd("Item required rarity ["..tostring(requiredRarity).."].",1)
		gd("Item current wear ["..tostring(info.wear).."].",1)
		gd("Item max wear ["..tostring(info.wearmax).."].",1)
				
		if (info.rarity > 0 and (((info.rarity >= tonumber(requiredRarity)) and tonumber(requiredRarity) > 0) or (info.rarity == info.raritymax))) then
			UseControlAction("GatheringMasterpiece","Collect")
			ml_global_information.Await(1000, 2500, function () return IsControlOpen("SelectYesno") or IsControlOpen("SelectYesNoCountItem") end)
			return
		else
			if (SkillMgr.Gather()) then
				gd("[CollectableGame]: Used skill from profile.",3)
				e_collectiblegame.timer = Now() + 2500
				return
			else
				local methodicals = {
					[16] = 4075,
					[17] = 4089,
				}
				local discernings = {
					[16] = 4078,
					[17] = 4092,
				}
							
				gd("[CollectableGame]: Attempting to use auto-skills.",3)
				local methodical = ActionList:Get(1,methodicals[Player.job])
				local discerning = ActionList:Get(1,discernings[Player.job])
				
				if (info.wear == 30) then
					UseControlAction("GatheringMasterpiece","Collect")
					ml_global_information.Await(1000, 2500, function () return IsControlOpen("SelectYesno") or IsControlOpen("SelectYesNoCountItem") end)
					return
				elseif (discerning and discerning:IsReady(Player.id) and info.rarity <= 1) then
					if (not HasBuffs(Player,"757")) then
						discerning:Cast()
						e_collectiblegame.timer = Now() + 2500
						return
					end
					if (HasBuffs(Player,"757") or Player.gp.current < 200) then
						if (methodical and methodical:IsReady(Player.id)) then
							methodical:Cast()
							e_collectiblegame.timer = Now() + 2500
							return
						end
					end
				end
			end
		end
	end
end

c_collectibleaddongather = inheritsFrom( ml_cause )
e_collectibleaddongather = inheritsFrom( ml_effect )
function c_collectibleaddongather:evaluate()
	local addonName = "SelectYesno"
	--if (ffxivminion.gameRegion == 3) then -- maybe
		--addonName = "SelectYesNoCountItem"
	--end
	if (IsControlOpen(addonName)) then
		local info = GetControlData(addonName)
		if (info and info.collectability ~= nil) then
			local validCollectible = false
			if (table.valid(gGatherCollectablePresets)) then
				for i,collectable in pairsByKeys(gGatherCollectablePresets) do
					if (string.valid(collectable.name) and type(collectable.value) == "number") then
						local itemid = AceLib.API.Items.GetIDByName(collectable.name)
						if (itemid) then
							if (string.contains(tostring(info.itemid),tostring(itemid))) then
								if (info.collectability >= tonumber(collectable.value)) then
									d("Collectibility Required is ["..tostring(collectable.value).."].")
									validCollectible = true
								else
									d("Collectibility Required is ["..tostring(collectable.value).."].")
									d("Collectibility was too low ["..tostring(info.collectability).."].")
								end
							end	
						end
					end
					
					if (validCollectible) then
						break
					end
				end
			end
			
			if (not validCollectible) then
				local task = ffxiv_gather.currentTask
				if (table.valid(task)) then
					local collectables = task.collectables
					if (table.valid(collectables)) then
						for identifier,minvalue in pairs(collectables) do
							local itemid;
							if (type(identifier) == "string") then
								if (GUI_Get(identifier) ~= nil) then
									local var = identifier
									identifier = GUI_Get(var)
									d("Converted identifier var ["..var.."] to ["..identifier.."]")
								end
					
								itemid = AceLib.API.Items.GetIDByName(identifier)
							else
								itemid = identifier
							end
							
							if (type(minvalue) == "string") then
								if (GUI_Get(minvalue) ~= nil) then
									local var = minvalue
									minvalue = GUI_Get(minvalue)
									d("Converted value var ["..var.."] to ["..minvalue.."]")
								end
							end
							
							if (itemid) then
								if (string.contains(tostring(info.itemid),tostring(itemid))) then
									if (info.collectability >= tonumber(minvalue)) then
										d("Collectibility Required is ["..tonumber(minvalue).."].")
										validCollectible = true
									else
										d("Collectibility Required is ["..tonumber(minvalue).."].")
										d("Collectibility was too low ["..tostring(info.collectability).."].")
									end
								end	
							end
						end
					end
				end
			end
			
			if (not validCollectible) then
				d("Cannot collect item ["..info.name.."], collectibility rating not approved.")
				UseControlAction(addonName,"No")
			else
				d("Attempting to collect item ["..info.name.."], collectibility rating approved.")
				UseControlAction(addonName,"Yes")
			end
			ml_global_information.Await(3000, function () return not IsControlOpen(addonName) end)				
			return true
		end
	end
	return false
end
function e_collectibleaddongather:execute()
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_gathernexttask = inheritsFrom( ml_cause )
e_gathernexttask = inheritsFrom( ml_effect )
c_gathernexttask.postpone = 0
c_gathernexttask.blockOnly = false
c_gathernexttask.subset = {}
c_gathernexttask.subsetExpiration = 0
function c_gathernexttask:evaluate()
	if (not Player.alive or not table.valid(ffxiv_gather.profileData) or IsControlOpen("Gathering")) then
		return false
	end
	
	if ((gBotMode == GetString("gatherMode") and gGatherMarkerOrProfileIndex ~= 2)) then
		return false
	end
	
	c_gathernexttask.blockOnly = false
	
	local evaluate = false
	local invalid = false
	local completed = false
	local tempinvalid = false
	
	local profileData = ffxiv_gather.profileData
	local currentTask = ffxiv_gather.currentTask
	local currentTaskIndex = ffxiv_gather.currentTaskIndex
	
	local eTime = GetEorzeaTime()
	local eHour = eTime.bell
	local precedingHour = SubtractHours(eHour,1)
	local eMinute = eTime.minute
	local plevel = Player.level
	
	local weatherAll = AceLib.API.Weather.GetAll()
	local shifts = AceLib.API.Weather.GetShifts()
	local lastShift = shifts.lastShift
	local nextShift = shifts.nextShift
	
	local profileName = (gBotMode == GetString("questMode") and gQuestProfile) or gGatherProfile
	
	if (not table.valid(currentTask)) then
		gd("[GatherNextTask]: We have no current task, so set the invalid flag.",3)
		invalid = true
	else
		gd("[GatherNextTask]: We have a current task, check if it should be completed.",3)
		
		-- Pre-compile all the complete checks so we only have to loadstring once.
		if (currentTask.complete) then
			local conditions = currentTask.complete
			local complete = true
			
			for condition,value in pairs(conditions) do
				local ok, ret = LoadString("return " .. condition)
				if (ok and ret ~= nil) then
					if (ret ~= value) then
						complete = false
					end
				end
				if (not complete) then
					break
				end
			end
			
			if (complete) then
				invalid = true
				completed = true
			end
		end
		
		if (IsNull(currentTask.interruptable,false) or IsNull(currentTask.lowpriority,false) or currentTask.type == "idle" or IsNull(currentTask.idlepriority,false)) then
			gd("[GatherNextTask]: Task is interruptable, set the flag.",3)
			evaluate = true
		elseif not (currentTask.weatherlast or currentTask.weathernow or currentTask.weathernext or currentTask.highpriority or
				 currentTask.eorzeaminhour or currentTask.eorzeamaxhour or currentTask.normalpriority)
		then
			gd("[GatherNextTask]: Task is interruptable, set the flag.",3)
			evaluate = true
		end
		
		if (not invalid) then
			local conditions = currentTask.condition
			if (table.valid(conitions)) then
				valid = TestConditions(conditions)
				if (not valid) then
					invalid = true
					gd("Current task ["..tostring(i).."] not valid due to conditions.",3)
				end
			end
		end
		
		if (not invalid) then
			local plevel = Player.level
			if (currentTask.type == "botany") then
				plevel = Player.levels[FFXIV.JOBS.BOTANIST]
			elseif (currentTask.type == "mining") then
				plevel = Player.levels[FFXIV.JOBS.MINER]
			end
			if (currentTask.minlevel and plevel < currentTask.minlevel) then
				gd("[GatherNextTask]: Level is too low for the task, invalidate.",3)
				invalid = true
			elseif (currentTask.maxlevel and plevel > currentTask.maxlevel) then
				gd("[GatherNextTask]: Level is too high for the task, invalidate.",3)
				invalid = true
			end
			if (currentTask.mapid and (not ffxiv_gather.CanAccessGatherMap(currentTask.mapid))) then
				invalid = true
				gd("Task ["..tostring(i).."] not valid due to Map Access.",3)
			end
		end
		
		if (not invalid) then
			local lastGather = ffxiv_gather.GetLastGather(profileName,currentTaskIndex)
			if (lastGather ~= 0) then
				if (TimePassed(GetCurrentTime(), lastGather) < 1400) then
					gd("[GatherNextTask]: Our last gather was only ["..tostring(TimePassed(GetCurrentTime(), lastGather)).."] seconds ago, invalidate.",3)
					invalid = true
				end
			end
		end
			
		if (not invalid) then
			local weather = weatherAll[Player.localmapid] or { last = "", now = "", next = "" }
			local weatherLast = weather.last or ""
			local weatherNow = weather.now or ""
			local weatherNext = weather.next or ""
	
			if (currentTask.weatherlast and currentTask.weatherlast ~= weatherLast) then
				gd("[GatherNextTask]: Last weather needed doesn't match up, invalidate.",3)
				invalid = true
			elseif (currentTask.weathernow and currentTask.weathernow ~= weatherNow) then
				gd("[GatherNextTask]: Current weather needed doesn't match up, invalidate.",3)
				invalid = true
			elseif (currentTask.weathernext and currentTask.weathernext ~= weatherNext) then
				gd("[GatherNextTask]: Next weather needed doesn't match up, invalidate.",3)
				invalid = true
			end
		end
			
		if (not invalid) then
			if (currentTask.lastshiftmin and currentTask.lastshiftmin < lastShift) then
				invalid = true
			elseif (currentTask.lastshiftmax and currentTask.lastshiftmin > lastShift) then
				invalid = true
			elseif (currentTask.nextshiftmin and currentTask.nextshiftmin < nextShift) then
				invalid = true
			elseif (currentTask.nextshiftmax and currentTask.nextshiftmax > nextShift) then
				invalid = true
			end
		end
			
		if (not invalid) then
			if (IsNull(currentTask.maxtime,0) > 0) then
				if (ml_task_hub:CurrentTask().taskStarted > 0 and TimeSince(ml_task_hub:CurrentTask().taskStarted) > currentTask.maxtime) then
					gd("[GatherNextTask]: Task has been ongoing for too long, invalidate.",3)
					invalid = true
				else
					if (ml_task_hub:CurrentTask().taskStarted ~= 0) then
						gd("Max time allowed ["..tostring(currentTask.maxtime).."], time passed ["..tostring(TimeSince(ml_task_hub:CurrentTask().taskStarted)).."].",3)
					end
				end
			end
			if (IsNull(currentTask.timeout,0) > 0) then
				if (ml_task_hub:CurrentTask().taskFailed > 0 and TimeSince(ml_task_hub:CurrentTask().taskFailed) > currentTask.timeout) then
					tempinvalid = true
					invalid = true
					gd("[GatherNextTask]: Task has been idle too long, invalidate.",3)
				else
					if (ml_task_hub:CurrentTask().taskFailed ~= 0) then
						gd("Max time allowed ["..tostring(currentTask.timeout).."], time passed ["..tostring(TimeSince(ml_task_hub:CurrentTask().taskFailed)).."].",3)
					end
				end
			end
			
			if (IsNull(currentTask.eorzeaminhour,-1) ~= -1 and IsNull(currentTask.eorzeamaxhour,-1) ~= -1) then
				local validHour = false
				local i = currentTask.eorzeaminhour
				while (i ~= currentTask.eorzeamaxhour) do
					if (i == eHour or (i == precedingHour and eMinute >= 45)) then
						validHour = true
						i = currentTask.eorzeamaxhour
					else
						i = AddHours(i,1)
					end
				end
				
				if (not validHour) then
					gd("[GatherNextTask]: We are not in a valid time window for this task, invalidate.",3)
					invalid = true
				end
			end
		end

		if (not invalid) then
			if (currentTask.touchCompleted) then
				gd("[GatherNextTask]: Single touch task has been completed, invalidate.",3)
				invalid = true
			end
		end
		if (not invalid) then
			if ((IsNull(currentTask.seriescounter,0) ~= 0) and (ml_task_hub:CurrentTask().seriescount >= IsNull(currentTask.seriescounter,0))) then
				d("[GatherNextTask]: Task node limit has been reached, invalidate.",3)
				invalid = true
			end
		end
		
	end
	
	if (completed) then
		if (currentTask.oncomplete) then
			local oncomplete = currentTask.oncomplete
			if (type(oncomplete) == "function") then
				pcall(oncomplete)
			elseif (type(oncomplete) == "string") then
				pcall(assert(loadstring(oncomplete)))
			end
		end
	end
	
	if (invalid and not tempinvalid and table.valid(ffxiv_gather.currentTask)) then
		profileData.tasks[currentTaskIndex].lockout = Now() + 10000
		gd("[GatherNextTask]: Remove this index from the cached subset.",3)
		c_gathernexttask.subset[currentTaskIndex] = nil
	end

	if (evaluate or invalid) then
		if (table.valid(profileData.tasks)) then
		
			local validTasks = {}
			if (Now() < c_gathernexttask.subsetExpiration) then
				gd("[GatherNextTask]: Check the cached subset of tasks.",3)
				validTasks = c_gathernexttask.subset
			else
				gd("[GatherNextTask]: Check the non-cached subset of tasks.",3)
				validTasks = deepcopy(profileData.tasks,true)
				for i,data in pairs(validTasks) do
					
					local thisIndex = i
					local valid = true

					if (data.enabled and data.enabled ~= "1") then
						valid = false
						gd("Task ["..tostring(i).."] not enabled.",3)
					end
					
					local plevel = Player.level
					if (data.type == "botany") then
						plevel = Player.levels[FFXIV.JOBS.BOTANIST]
					elseif (data.type == "mining") then
						plevel = Player.levels[FFXIV.JOBS.MINER]
					end

					if (data.minlevel and plevel < tonumber(data.minlevel)) then
						valid = false
						gd("Task ["..tostring(i).."] not valid due to min level requirement.",3)
					elseif (data.maxlevel and plevel > tonumber(data.maxlevel)) then
						valid = false
						gd("Task ["..tostring(i).."] not valid due to max level requirement.",3)
					end
					if (data.mapid and (not ffxiv_gather.CanAccessGatherMap(data.mapid))) then
						valid = false
						gd("Task ["..tostring(i).."] not valid due to Map Access.",3)
					end
					if (valid) then
						local lastGather = ffxiv_gather.GetLastGather(profileName,i)
						if (lastGather ~= 0) then
							if (TimePassed(GetCurrentTime(), lastGather) < 1400) then
								valid = false
								gd("Task ["..tostring(i).."] not valid due to last gather.",3)
							end
						end
					end
					
					if (valid) then
						local conditions = data.condition
						if (table.valid(conditions)) then
							valid = TestConditions(conditions)
							if (not valid) then
								gd("Task ["..tostring(i).."] not valid due to conditions.",3)
							end
						end
					end
					
					if (valid) then
						local weather = weatherAll[data.mapid] or { last = "", now = "", next = "" }
						local weatherLast = weather.last or ""
						local weatherNow = weather.now or ""
						local weatherNext = weather.next or ""
			
						if (data.weatherlast and data.weatherlast ~= weatherLast) then
							valid = false
						elseif (data.weathernow and data.weathernow ~= weatherNow) then
							valid = false
						elseif (data.weathernext and data.weathernext ~= weatherNext) then
							valid = false
						end
						if (not valid) then
							gd("Task ["..tostring(i).."] not valid due to weather.",3)
						end
					end
					
					if (valid) then
						if (data.lastshiftmin and data.lastshiftmin < lastShift) then
							valid = false
						elseif (data.lastshiftmax and data.lastshiftmin > lastShift) then
							valid = false
						elseif (data.nextshiftmin and data.nextshiftmin < nextShift) then
							valid = false
						elseif (data.nextshiftmax and data.nextshiftmax > nextShift) then
							valid = false
						end
						if (not valid) then
							gd("Task ["..tostring(i).."] not valid due to shift.",3)
						end
					end
					
					if (valid) then
						if (IsNull(data.eorzeaminhour,-1) ~= -1 and IsNull(data.eorzeamaxhour,-1) ~= -1) then
							local validHour = false
							local i = data.eorzeaminhour
							while (i ~= data.eorzeamaxhour) do
								if (i == eHour or (i == precedingHour and eMinute >= 45)) then
									validHour = true
									i = data.eorzeamaxhour
								else
									i = AddHours(i,1)
								end
							end
							
							if (not validHour) then
								valid = false
							end
						end
						if (not valid) then
							gd("Task ["..tostring(i).."] not valid due to eorzea time.",3)
						end
					end
					
					if (not valid) then
						gd("Removing task ["..tostring(i).."] from valid tasks.",3)
						validTasks[i] = nil
					end
				end
				
				c_gathernexttask.subset = validTasks
				local quarters = { [5] = true, [10] = true, [15] = true, [20] = true, [25] = true, [30] = true, [35] = true, [40] = true, [45] = true, [50] = true, [55] = true, [60] = true }
				local expirationDelay = 0
				for quarter,_ in pairs(quarters) do
					local diff = (quarter - eMinute)
					if (diff <= 5 and diff > 0) then
						expirationDelay = (diff * 2.92) * 1000
						gd("[Gather]: Setting expiration delay of ["..tostring(expirationDelay).."] ms")
						break
					end	
				end
				gd("Buffering task evaluation by ["..tostring(expirationDelay / 1000).."] seconds.")
				c_gathernexttask.subsetExpiration = Now() + expirationDelay
			end
			
			if (table.valid(validTasks)) then
			
				local highPriority = {}
				local normalPriority = {}
				local lowPriority = {}
				local idlePriority = {}
				
				for i,data in pairsByKeys(validTasks) do
					if (not data.lockout or Now() > data.lockout) then
						-- Items with weather requirements go into high priority
						if (data.type == "idle" or data.idlepriority) then
							gd("Added task at ["..tostring(i).."] to the idle priority queue.")
							idlePriority[i] = data
						elseif (data.highpriority) then
							gd("Added task at ["..tostring(i).."] to the high priority queue.")
							highPriority[i] = data
						elseif (data.normalpriority) then
							gd("Added task at ["..tostring(i).."] to the normal priority queue.")
							normalPriority[i] = data
						elseif (data.lowpriority) then
							gd("Added task at ["..tostring(i).."] to the low priority queue.")
							lowPriority[i] = data
						elseif (data.weatherlast or data.weathernow or data.weathernext) then
							gd("Added task at ["..tostring(i).."] to the high priority queue.")
							highPriority[i] = data
						elseif (data.eorzeaminhour or data.eorzeamaxhour) then
							gd("Added task at ["..tostring(i).."] to the normal priority queue.")
							normalPriority[i] = data
						else
							gd("Added task at ["..tostring(i).."] to the low priority queue.")
							lowPriority[i] = data
						end
					end
				end
				
				local lowestIndex = 9999
				local best = nil
				
				-- High priority section.
				
				
				if (not best) then
					if (invalid and currentTask.group) then
						gd("[GatherNextTask]: Check the high priority tasks for grouped tasks.",3)
						lowestIndex = 9999
						for i,data in pairsByKeys(highPriority) do
							if (i > currentTaskIndex and IsNull(data.group,"") == currentTask.group) then
								if (not best or (best and i < lowestIndex)) then
									best = data
									lowestIndex = i
								end
							end
						end
						
						if (not best) then
							lowestIndex = 9999
							for i,data in pairsByKeys(highPriority) do
								if (IsNull(data.group,"") == currentTask.group) then
									if (not best or (best and i < lowestIndex)) then
										best = data
										lowestIndex = i
									end
								end
							end
						end
					end
					if (not best) then
						gd("[GatherNextTask]: Check the high priority tasks for differently grouped tasks.",3)
						for i,data in pairsByKeys(highPriority) do
							if (not currentTask.group or IsNull(data.group,"") ~= currentTask.group) then
								if (not best or (best and i < lowestIndex)) then
									best = data
									lowestIndex = i
								end
							end
						end
					end
				end
				
				-- Normal priority section.
				if (not best and (invalid or currentTask.lowpriority or currentTask.idlepriority or currentTask.type == "idle")) then
					if (not best) then
						gd("[GatherNextTask]: Check the normal priority tasks for matching grouped tasks 1.",3)
						if (invalid and currentTask.group) then
							lowestIndex = 9999
							for i,data in pairsByKeys(normalPriority) do
								if (i > currentTaskIndex and IsNull(data.group,"") == currentTask.group) then
									if (not best or (best and i < lowestIndex)) then
										best = data
										lowestIndex = i
									end
								end
							end
							if (not best) then
								gd("[GatherNextTask]: Check the normal priority tasks for matching grouped tasks 2.",3)
								lowestIndex = 9999	
								for i,data in pairsByKeys(normalPriority) do
									if (IsNull(data.group,"") == currentTask.group) then
										if (not best or (best and i < lowestIndex)) then
											best = data
											lowestIndex = i
										end
									end
								end
							end
						end
							
						if (not best) then
							gd("[GatherNextTask]: Check the normal priority tasks for higher ranked, differently grouped tasks.",3)
							lowestIndex = 9999
							for i,data in pairsByKeys(normalPriority) do
								if (not currentTask.group or IsNull(data.group,"") ~= currentTask.group) then
									if (not best or (best and i < lowestIndex)) then
										best = data
										lowestIndex = i
									end
								end
							end
						end
					end
				end
				
				-- Low priority section.
				if (not best and (invalid or currentTask.type == "idle" or currentTask.idlepriority)) then
					gd("[GatherNextTask]: Check the low priority section since haven't found anything yet.",3)
				
					if (not best) then
						gd("[GatherNextTask]: Check the low priority tasks for matching grouped tasks 1.",3)
						if (invalid and currentTask.group) then
							lowestIndex = 9999
							for i,data in pairsByKeys(lowPriority) do
								if (i > currentTaskIndex and IsNull(data.group,"") == currentTask.group) then
									if (not best or (best and i < lowestIndex)) then
										best = data
										lowestIndex = i
									end
								end
							end
							if (not best) then
								gd("[GatherNextTask]: Check the low priority tasks for matching grouped tasks 2.",3)
								lowestIndex = 9999	
								for i,data in pairsByKeys(lowPriority) do
									if (IsNull(data.group,"") == currentTask.group) then
										if (not best or (best and i < lowestIndex)) then
											best = data
											lowestIndex = i
										end
									end
								end
							end
						end
					end
					if (not best) then
						if (IsNull(currentTask.set,"") ~= "") then
							gd("[GatherNextTask]: Check for the next task in this set.",3)
							lowestIndex = 9999
							for i,data in pairsByKeys(lowPriority) do
								if (IsNull(data.set,"") == currentTask.set) then
									
									if (i > currentTaskIndex) then
										if (not best or (best and i < lowestIndex)) then
											best = data
											lowestIndex = i
										end
									end
								end
							end
							
							if (not best) then
								gd("[GatherNextTask]: Loop back around to check previous tasks in this set.",3)
								lowestIndex = 9999
								for i,data in pairsByKeys(lowPriority) do
									if (IsNull(data.set,"") == currentTask.set) then
										if (not best or (best and i < lowestIndex)) then
											best = data
											lowestIndex = i
										end
									end
								end
							end
						else
							gd("[GatherNextTask]: Check for the next task available for low priority.",3)
							lowestIndex = 9999
							for i,data in pairsByKeys(lowPriority) do
								if (i > currentTaskIndex) then
									if (not best or (best and i < lowestIndex)) then
										best = data
										lowestIndex = i
									end
								end
							end
							
							if (not best) then
								gd("[GatherNextTask]: Still don't have anything, check previous low priority section tasks.",3)
								lowestIndex = 9999
								for i,data in pairsByKeys(lowPriority) do
									if (not best or (best and i < lowestIndex)) then
										best = data
										lowestIndex = i
									end
								end
							end
						end
					end
				end
				
				-- Idle priority section.
				if (not best and invalid and currentTask.type ~= "idle" and not currentTask.idlepriority) then
					gd("[GatherNextTask]: Check the idle priority section since haven't found anything yet.",3)
					if (IsNull(currentTask.set,"") ~= "") then
						gd("[GatherNextTask]: Check for the next task in this set.",3)
						lowestIndex = 9999
						for i,data in pairsByKeys(idlePriority) do
							if (IsNull(data.set,"") == currentTask.set) then
								if (i > currentTaskIndex) then
									if (not best or (best and i < lowestIndex)) then
										best = data
										lowestIndex = i
									end
								end
							end
						end
						
						if (not best) then
							gd("[GatherNextTask]: Loop back around to check previous tasks in this set.",3)
							lowestIndex = 9999
							for i,data in pairsByKeys(idlePriority) do
								if (IsNull(data.set,"") == currentTask.set) then
									if (not best or (best and i < lowestIndex)) then
										best = data
										lowestIndex = i
									end
								end
							end
						end
					else
						gd("[GatherNextTask]: Check for the next task available for idle priority.",3)
						lowestIndex = 9999
						for i,data in pairsByKeys(idlePriority) do
							if (i > currentTaskIndex) then
								if (not best or (best and i < lowestIndex)) then
									best = data
									lowestIndex = i
								end
							end
						end
						
						if (not best) then
							gd("[GatherNextTask]: Still don't have anything, check previous idle priority section tasks.",3)
							lowestIndex = 9999
							for i,data in pairsByKeys(idlePriority) do
								if (not best or (best and i < lowestIndex)) then
									best = data
									lowestIndex = i
								end
							end
						end
					end
					
				end
				
				if (best) then
					if (ffxiv_gather.currentTaskIndex ~= lowestIndex) then
						ffxiv_gather.currentTaskIndex = lowestIndex
						ffxiv_gather.currentTask = best
						d("New task id = "..tostring(lowestIndex))
						return true
					else
						gd("[GatherNextTask]: Found a task, but it is the current task, so do nothing.",3)
					end
				end
			else
				gd("[GatherNextTask]: No valid tasks were found.",3)
			end
		end
	end
					
	return false
end
function e_gathernexttask:execute()
	if (c_gathernexttask.blockOnly) then
		return
	end
	if (Player:IsMoving()) then
		Player:Stop()
	end
	
	local taskName = ffxiv_gather.currentTask.name or ffxiv_gather.currentTaskIndex
	gStatusTaskName = taskName
	
	if (gBotMode == GetString("questMode")) then
		gQuestStepType = "gather - ["..tostring(taskName).."]"
	end
	ml_marker_mgr.currentMarker = nil
	gStatusMarkerName = ""
	ml_task_hub:CurrentTask().gatherid = 0
	ml_global_information.gatherid = 0
	ml_task_hub:CurrentTask().failedSearches = 0
	ml_task_hub:CurrentTask().taskFailed = 0
	ml_task_hub:CurrentTask().taskStarted = 0
	ml_task_hub:CurrentTask().seriescount = 0
	
	ffxiv_gather.currentTask.touchCompleted = false

	ffxiv_gather.currentTask.currentPositionIndex = 0
	ffxiv_gather.currentTask.currentPosition = {}
	ffxiv_gather.currentTask.maxPositions = 0
	if (table.valid(ffxiv_gather.currentTask.multipos)) then
		ffxiv_gather.currentTask.maxPositions = table.size(ffxiv_gather.currentTask.multipos)
		ffxiv_gather.currentTask.currentPositionIndex = math.random(1,ffxiv_gather.currentTask.maxPositions)
		gd("[GatherNextTask] Position selected "..ffxiv_gather.currentTask.currentPositionIndex.." of "..ffxiv_gather.currentTask.maxPositions)
	end

	ml_global_information.lastInventorySnapshot = GetInventorySnapshot()
end

c_gathernextprofilemap = inheritsFrom( ml_cause )
e_gathernextprofilemap = inheritsFrom( ml_effect )
e_gathernextprofilemap.mapid = 0
function c_gathernextprofilemap:evaluate()
    e_gathernextprofilemap.mapid = 0
	
	local task = ffxiv_gather.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		if (task.mapid and Player.localmapid ~= task.mapid) then
			e_gathernextprofilemap.mapid = task.mapid
			return true
		end
	elseif (table.valid(marker)) then
		if (marker.mapid and Player.localmapid ~= marker.mapid) then
			e_gathernextprofilemap.mapid = marker.mapid
			return true
		end
	end
    
    return false
end
function e_gathernextprofilemap:execute()
	local mapID = e_gathernextprofilemap.mapid
	local taskPos = ffxiv_gather.GetCurrentTaskPos()
	local pos = ml_nav_manager.GetNextPathPos(Player.pos,Player.localmapid,mapID)
	if (table.valid(pos)) then		
		local newTask = ffxiv_task_movetomap.Create()
		newTask.destMapID = mapID
		newTask.pos = taskPos
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	else
		if (mapID and taskPos) then
			local aeth = GetAetheryteByMapID(mapID, taskPos)
			if (aeth) then
				if (Player:IsMoving()) then
					Player:Stop()
					return
				end
				
				local noTeleportMaps = { [177] = true, [178] = true, [179] = true }
				if (noTeleportMaps[Player.localmapid]) then
					return
				end
				
				if (ActionIsReady(7,5)) then
					if (Player:Teleport(aeth.id)) then	
						local newTask = ffxiv_task_teleport.Create()
						newTask.setHomepoint = false
						newTask.aetheryte = aeth.id
						newTask.mapID = aeth.territory
						ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
					end
				end
				return
			end
		end
		
		--ffxiv_dialog_manager.IssueStopNotice("Gather_NextTask", "No path found from map "..tostring(Player.localmapid).." to map "..tostring(mapID))
	end
end

c_gatherstealth = inheritsFrom( ml_cause )
e_gatherstealth = inheritsFrom( ml_effect )
e_gatherstealth.timer = 0
function c_gatherstealth:evaluate()
	if (IsFlying() or ml_task_hub:CurrentTask().name == "MOVE_WITH_FLIGHT") then
		return false
	end
	
	local useStealth = false
	local task = ffxiv_gather.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		useStealth = IsNull(task.usestealth,false)
	elseif (table.valid(marker)) then
		useStealth = (marker.usestealth )
	elseif gGatherMarkerOrProfileIndex == 3 then
		useStealth = gSteathQuickMode
	end
	
	if (type(useStealth) == "string" and GUI_Get(useStealth) ~= nil) then
		useStealth = GUI_Get(useStealth)
	end
	
	if (useStealth) then
		if (Player.incombat) then
			return false
		end
		
		if (IsControlOpen("Gathering")) then
			return false
		end
		
		local stealth = nil
		if (Player.job == FFXIV.JOBS.BOTANIST) then
			stealth = ActionList:Get(1,212)
		elseif (Player.job == FFXIV.JOBS.MINER) then
			stealth = ActionList:Get(1,229)
		end
		
		if (stealth) then
			local dangerousArea = false
			local destPos = {}
			local myPos = Player.pos
			local task = ffxiv_gather.currentTask
			local marker = ml_marker_mgr.currentMarker
			if (table.valid(task)) then
				dangerousArea = IsNull(task.dangerousarea,false)
				destPos = ffxiv_gather.GetCurrentTaskPos()
			elseif (table.valid(marker)) then
				dangerousArea = marker.dangerousarea
				destPos = marker:GetPosition()
			elseif gGatherMarkerOrProfileIndex == 3 then
				destPos = ml_task_hub:CurrentTask().pos
				dangerousArea = gSteathDangerousQuickMode
			end
			
			if (type(dangerousArea) == "string" and GUI_Get(dangerousArea) ~= nil) then
				dangerousArea = GUI_Get(dangerousArea)
			end
		
			if (not dangerousArea and ml_task_hub:CurrentTask().name == "MOVETOPOS") then
				local dest = ml_task_hub:CurrentTask().pos
				if (Distance3D(myPos.x,myPos.y,myPos.z,dest.x,dest.y,dest.z) > 30) then
					if (HasBuff(Player.id, 47)) then
						return true
					else
						return false
					end
				end
			end
			
			local gatherid = ml_task_hub:ThisTask().gatherid
			if ( gatherid and gatherid ~= 0 ) then
				local gatherable = EntityList:Get(gatherid)
				if (gatherable and (gatherable.distance < 10) and IsUnspoiled(gatherable.contentid)) then
					local potentialAdds = EntityList("alive,attackable,aggressive,maxdistance="..tostring(tonumber(FFXIV_Common_StealthDetect)*2)..",minlevel="..tostring(Player.level - 10)..",distanceto="..tostring(gatherable.id))
					if (TableSize(potentialAdds) > 0) then
						if (not HasBuff(Player.id, 47)) then
							return true
						else
							return false
						end
					end
				end
				
				if (gatherable) then
					if (gTeleportHack and c_teleporttopos:evaluate()) then
						local potentialAdds = EntityList("alive,attackable,aggressive,maxdistance="..tostring(FFXIV_Common_StealthDetect)..",minlevel="..tostring(Player.level - 10)..",distanceto="..tostring(gatherable.id))
						if (TableSize(potentialAdds) > 0) then
							if (not HasBuff(Player.id, 47)) then
								return true
							else
								return false
							end
						end
					end
				end
			end
			
			
			local addMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(FFXIV_Common_StealthDetect))
			local removeMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(FFXIV_Common_StealthRemove))
			if (TableSize(removeMobList) == 0 and HasBuff(Player.id, 47)) then
				return true
			elseif (table.valid(addMobList)) then
				if (FFXIV_Common_StealthSmart ) then
					local ph = ConvertHeading(Player.pos.h)
					local playerFront = ConvertHeading((ph + (math.pi)))%(2*math.pi)
					local nextPos = IsNull(GetPosFromDistanceHeading(Player.pos, 10, playerFront),Player.pos)
				
					for i,entity in pairs(addMobList) do
						if ((IsFrontSafer(entity) or IsFrontSafer(entity,nextPos)) and entity.targetid == 0) then
							if (not HasBuff(Player.id, 47)) then
								return true
							else
								return false
							end
						end
					end
					if (HasBuff(Player.id, 47)) then
						return true
					end
				else
					if (not HasBuff(Player.id, 47)) then
						return true
					end		
				end
			end
		end
	else
		if (HasBuffs(Player,"47")) then
			return true
		end
	end
 
    return false
end
function e_gatherstealth:execute()
	e_gatherstealth.timer = Now() + 3000
	
	local newTask = ffxiv_task_stealth.Create()
	if (HasBuffs(Player,"47")) then
		newTask.droppingStealth = true
	else
		newTask.addingStealth = true
	end
	ml_task_hub:ThisTask().preserveSubtasks = true
	ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
end

function ffxiv_gather.NeedsStealth()
	if (MIsCasting() or MIsLoading() or IsFlying() or Player.incombat) then
		return false
	end
	if Player.level < 8 then
		return false
	end	

	local useStealth = true
	local task = ffxiv_gather.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		useStealth = IsNull(task.usestealth,true)
	elseif (table.valid(marker)) then
		useStealth = (marker.usestealth )
	elseif gGatherMarkerOrProfileIndex == 3 then
		useStealth = gSteathQuickMode
	end
	
	if (type(useStealth) == "string" and GUI_Get(useStealth) ~= nil) then
		useStealth = GUI_Get(useStealth)
	end
	
	if (useStealth) then	
		local stealth = nil
		if (Player.job == FFXIV.JOBS.BOTANIST) then
			stealth = ActionList:Get(1,212)
		elseif (Player.job == FFXIV.JOBS.MINER) then
			stealth = ActionList:Get(1,229)
		end
		
		if (stealth) then
			local dangerousArea = false
			local destPos = ml_task_hub:CurrentTask().pos
			local myPos = Player.pos
			local task = ffxiv_gather.currentTask
			local marker = ml_marker_mgr.currentMarker
			if (table.valid(task)) then
				dangerousArea = IsNull(task.dangerousarea,false)
			elseif (table.valid(marker)) then
				dangerousArea = marker.dangerousarea
			elseif gGatherMarkerOrProfileIndex == 3 then
				dangerousArea = gSteathDangerousQuickMode
			end
			
			if (type(dangerousArea) == "string" and GUI_Get(dangerousArea) ~= nil) then
				dangerousArea = GUI_Get(dangerousArea)
			end
			
			if (destPos) then
				if (not dangerousArea and ml_task_hub:CurrentTask().name == "MOVETOPOS") then
					local dist = PDistance3D(myPos.x,myPos.y,myPos.z,destPos.x,destPos.y,destPos.z)
					if (dist > 30) then
						--d("Too far from destination to use stealth.")
						return false
					end
				end
			end
			
			local gatherid = ml_global_information.gatherid
			if ( gatherid and gatherid ~= 0 ) then
				local gatherable = EntityList:Get(gatherid)
				if (gatherable and (gatherable.distance < 10) and IsUnspoiled(gatherable.contentid)) then
					local potentialAdds = EntityList("alive,attackable,aggressive,maxdistance="..tostring(tonumber(FFXIV_Common_StealthDetect)*2)..",minlevel="..tostring(Player.level - 10)..",distanceto="..tostring(gatherable.id))
					if (table.valid(potentialAdds)) then
						return true
					end
				end
				
				if (gatherable) then
					if (gTeleportHack and c_teleporttopos:evaluate()) then
						local potentialAdds = EntityList("alive,attackable,aggressive,maxdistance="..tostring(FFXIV_Common_StealthDetect)..",minlevel="..tostring(Player.level - 10)..",distanceto="..tostring(gatherable.id))
						if (table.valid(potentialAdds)) then
							return true
						end
					end
				end
			end
			
			local hasStealth = HasBuff(Player.id,47)
			local addMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(FFXIV_Common_StealthDetect))
			if (table.valid(addMobList)) then
				if (FFXIV_Common_StealthSmart and not dangerousArea) then
					local ph = ConvertHeading(Player.pos.h)
					local playerFront = ConvertHeading((ph + (math.pi)))%(2*math.pi)
					local nextPos = IsNull(GetPosFromDistanceHeading(Player.pos, 10, playerFront),Player.pos)
				
					for i,entity in pairs(addMobList) do
						if (entity.targetid == 0) then
							local epos = entity.pos
							local ray1 = RayCast(epos.x,(epos.y+1.5),epos.z,myPos.x,(myPos.y+1.5),myPos.z)
							local ray2 = RayCast(epos.x,(epos.y+1.5),epos.z,nextPos.x,(nextPos.y+1.5),nextPos.z)
							if ((IsFrontSafer(entity) and ray1 == nil) or 
								(IsFrontSafer(entity,nextPos) and ray2 == nil)) 
							then
								--d("Aggressive enemy within los, need stealth.")
								return true
							end
						end
					end
				else
					--d("Potential adds within our detection distance.")
					return true
				end
			end
			
			if (hasStealth) then
				if (not FFXIV_Common_StealthSmart) then
					local removeMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(FFXIV_Common_StealthRemove))
					if (table.valid(removeMobList)) then
						--d("Still detecting enemies, need to keep stealth.")
						return true
					end
				end
			end
		else
			--d("Could not find stealth action.")
		end
	else
		--d("Task is not set to use stealth.")
	end
	
	--d("Defaulted out of function.")
	return false
end

c_gatherisloading = inheritsFrom( ml_cause )
e_gatherisloading = inheritsFrom( ml_effect )
function c_gatherisloading:evaluate()
	local navmeshstate = NavigationManager:GetNavMeshState()
	return MIsLoading() or In(navmeshstate,GLOBAL.MESHSTATE.MESHLOADING,GLOBAL.MESHSTATE.MESHSAVING,GLOBAL.MESHSTATE.MESHBUILDING)
end
function e_gatherisloading:execute()
	ml_debug("Character is loading, prevent other actions and idle.")
end

c_gatherislocked = inheritsFrom( ml_cause )
e_gatherislocked = inheritsFrom( ml_effect )
function c_gatherislocked:evaluate()
	return CannotMove() or IsControlOpen("Gathering")
end
function e_gatherislocked:execute()
	ml_debug("Character is loading, prevent other actions and idle.")
end

c_gathernoactivity = inheritsFrom( ml_cause )
e_gathernoactivity = inheritsFrom( ml_effect )
function c_gathernoactivity:evaluate()	
	local marker = ml_marker_mgr.currentMarker
	local task = ffxiv_gather.currentTask
	if (not table.valid(task) and not table.valid(marker)) then
		ml_global_information.Await(1000)
		return true
	end
	return false
end
function e_gathernoactivity:execute()
	-- Do nothing here, but there's no point in continuing to process and eat CPU.
end

c_resettask = inheritsFrom( ml_cause )
e_resettask = inheritsFrom( ml_effect )
function c_resettask:evaluate()

	if IsControlOpen("Gathering") then
		return false
	end
	
	local resetTask = false
	local task = ffxiv_gather.currentTask
	local ids = ""
	
	if (table.valid(task)) then
	
		resetTask = IsNull(task.evaluate,false)
		ids = IsNull(task.ids,"")
		if (task.mapid ~= Player.localmapid) then
			--d("[flag reset]: Not on correct map yet.",3)
			return false
		end
	end
	
	if resetTask then
		if (ids ~= "" and FindRadarMarker(ids) ~= nil) then
			if (tonumber(ids) ~= nil and tonumber(ids) == FindRadarMarker(ids).id) then
				d("[flag reset]: Radar Flag, Reset.")
				return true
			end
		end
	end
	
	return false
end

function e_resettask:execute()
	c_gathernexttask:evaluate()
end

c_gatherrandomdelay = inheritsFrom( ml_cause )
e_gatherrandomdelay = inheritsFrom( ml_effect )
function c_gatherrandomdelay:evaluate()
	
	if (not ml_task_hub:ThisTask().randomDelayCompleted) then
d("begin random delay")
		return true
	end
    
    return false
end
function e_gatherrandomdelay:execute()
	local minWait = gGatherRandomDelayMin * 1000
	local maxWait = gGatherRandomDelayMax * 1000
	local waitTime = math.random(minWait,maxWait)
d("delay time = "..tostring(waitTime/1000).." seconds")
	ml_global_information.Await(waitTime)
	ml_task_hub:ThisTask().randomDelayCompleted = true
end
function ffxiv_task_gather:Init()
	--[[ Overwatch Elements ]]
	local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 150 )
    self:add( ke_dead, self.overwatch_elements)
	
	local ke_flee = ml_element:create( "Flee", c_gatherflee, e_gatherflee, 140 )
    self:add( ke_flee, self.overwatch_elements)
	
	local ke_gatherrandomDelay = ml_element:create( "RandomFateDelay", c_gatherrandomdelay, e_gatherrandomdelay, 80 )
    self:add( ke_gatherrandomDelay, self.process_elements)

	--local ke_avoidAggressives = ml_element:create( "AvoidAggressives", c_avoidaggressives, e_avoidaggressives, 130 )
    --self:add( ke_avoidAggressives, self.overwatch_elements)
	
	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 100 )
    self:add( ke_inventoryFull, self.overwatch_elements)
	
	local ke_nodePreBuff = ml_element:create( "NodePreBuff", c_nodeprebuff, e_nodeprebuff, 90 )
    self:add( ke_nodePreBuff, self.overwatch_elements)
	
	local ke_resetTask = ml_element:create( "ResetTask", c_resettask, e_resettask, 180 )
    self:add( ke_resetTask, self.overwatch_elements)
	
	--[[ Process Elements ]]
	
	local ke_isLoading = ml_element:create( "IsLoading", c_gatherisloading, e_gatherisloading, 250 )
    self:add( ke_isLoading, self.process_elements)
	
	--local ke_autoEquip = ml_element:create( "AutoEquip", c_autoequip, e_autoequip, 220 )
    --self:add( ke_autoEquip, self.process_elements)
	
	local ke_recommendEquip = ml_element:create( "RecommendEquip", c_recommendequip, e_recommendequip, 220 )
    self:add( ke_recommendEquip, self.process_elements)
	
	local ke_collectible = ml_element:create( "Collectible", c_collectibleaddongather, e_collectibleaddongather, 210 )
    self:add( ke_collectible, self.process_elements)
	
	local ke_collectibleGame = ml_element:create( "CollectibleGame", c_collectiblegame, e_collectiblegame, 200 )
    self:add( ke_collectibleGame, self.process_elements)
	
	local ke_gather = ml_element:create( "Gather", c_gather, e_gather, 190 )
    self:add(ke_gather, self.process_elements)	
	
	local ke_isLocked = ml_element:create( "IsLocked", c_gatherislocked, e_gatherislocked, 180 )
    self:add( ke_isLocked, self.process_elements)
	
	local ke_nextTask = ml_element:create( "NextTask", c_gathernexttask, e_gathernexttask, 160 )
    self:add( ke_nextTask, self.process_elements)
	
	local ke_nextMarker = ml_element:create( "NextMarker", c_nextgathermarker, e_nextgathermarker, 150 )
    self:add( ke_nextMarker, self.process_elements)
	
	
	--local ke_noActivity = ml_element:create( "NoActivity", c_gathernoactivity, e_gathernoactivity, 145 )
    --self:add( ke_noActivity, self.process_elements)
	
	local ke_moveToNode = ml_element:create( "MoveToNode", c_movetonode, e_movetonode, 140 )
    self:add(ke_moveToNode, self.process_elements)
	
	local ke_nextProfileMap = ml_element:create( "NextProfileMap", c_gathernextprofilemap, e_gathernextprofilemap, 130 )
    self:add( ke_nextProfileMap, self.process_elements)
	
	local ke_findNode = ml_element:create( "FindNode", c_findnode, e_findnode, 50 )
    self:add(ke_findNode, self.process_elements)
	
	local ke_returnToBase = ml_element:create( "ReturnToBase", c_returntobase, e_returntobase, 20 )
    self:add(ke_returnToBase, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_gather.SetModeOptions()
	ffxiv_gather.profileData = {}
	if (table.valid(ffxiv_gather.profiles)) then
		ffxiv_gather.profileData = ffxiv_gather.profiles[gGatherProfile]
	end
	gTeleportHack = Settings.FFXIVMINION.gTeleportHack
	gTeleportHackParanoid = Settings.FFXIVMINION.gTeleportHackParanoid
	gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
	gSkipCutscene = Settings.FFXIVMINION.gSkipCutscene
	gSkipTalk = Settings.FFXIVMINION.gSkipTalk
	Hacks:SkipCutscene(gSkipCutscene)
	Hacks:Disable3DRendering(gDisableDrawing)
	gAvoidAOE = Settings.FFXIVMINION.gAvoidAOE
	gAutoEquip = Settings.FFXIVMINION.gAutoEquip
end

-- UI settings etc
function ffxiv_task_gather:UIInit()
	ffxiv_gather.profiles, ffxiv_gather.profilesDisplay = GetPublicProfiles(ffxiv_gather.profilePath,".*lua")
	
	local uuid = GetUUID()
	if (Settings.FFXIVMINION.gLastGatherProfiles == nil) then
		Settings.FFXIVMINION.gLastGatherProfiles = {}
	end
	if (Settings.FFXIVMINION.gLastGatherProfiles[uuid] == nil) then
		Settings.FFXIVMINION.gLastGatherProfiles[uuid] = {}
	end
	
	_G["gGatherProfile"] = Settings.FFXIVMINION.gLastGatherProfiles[uuid] or ffxiv_gather.profilesDisplay[1]
	_G["gGatherProfileIndex"] = GetKeyByValue(gGatherProfile,ffxiv_gather.profilesDisplay) or 1
	if (ffxiv_gather.profilesDisplay[gGatherProfileIndex] ~= gGatherProfile) then
		_G["gGatherProfile"] = ffxiv_gather.profilesDisplay[gGatherProfileIndex]
	end
	ffxiv_gather.profileData = ffxiv_gather.profiles[gGatherProfile] or {}
	
	gGatherDebug = ffxivminion.GetSetting("gGatherDebug",false)
	local debugLevels = { 1, 2, 3}
	gGatherDebugLevel = ffxivminion.GetSetting("gGatherDebugLevel",1)
	gGatherDebugLevelIndex = GetKeyByValue(gGatherDebugLevel,debugLevels)
	
	--local uistring = IsNull(AceLib.API.Items.BuildUIString(47,120),"")
	--gGatherCollectablesList = { GetString("none") }
	--if (ValidString(uistring)) then
		--for collectable in StringSplit(uistring,",") do
			--table.insert(gGatherCollectablesList,collectable)
		--end
	--end
	
	gGatherRandomDelayMin = ffxivminion.GetSetting("gGatherRandomDelayMin",1)
	gGatherRandomDelayMax = ffxivminion.GetSetting("gGatherRandomDelayMax",5)
	
	gGatherUseCordials = ffxivminion.GetSetting("gGatherUseCordials",true)
	ghighCordialsGP = ffxivminion.GetSetting("ghighCordialsGP",200)
	gnormCordialsGP = ffxivminion.GetSetting("gnormCordialsGP",300)
	gwateredCordialsGP = ffxivminion.GetSetting("gwateredCordialsGP",150)
	
	gFishhighCordialsGP = ffxivminion.GetSetting("gFishhighCordialsGP",200)
	gFishnormCordialsGP = ffxivminion.GetSetting("gFishnormCordialsGP",300)
	gFishwateredCordialsGP = ffxivminion.GetSetting("gFishwateredCordialsGP",150)
	
	gQuickstartMaps = ffxivminion.GetSetting("gQuickstartMaps",false)
	gQuickstartGardening = ffxivminion.GetSetting("gQuickstartGardening",false)
	gQuickstartRares = ffxivminion.GetSetting("gQuickstartRares",false)
	gQuickstartChocoboFood = ffxivminion.GetSetting("gQuickstartChocoboFood",false)
	gSteathQuickMode = ffxivminion.GetSetting("gSteathQuickMode",true)
	gSteathDangerousQuickMode = ffxivminion.GetSetting("gSteathDangerousQuickMode",false)
	gQuickstartMinGp = ffxivminion.GetSetting("gQuickstartMinGp",0)
	gQuickstartMinNodeLvl = ffxivminion.GetSetting("gQuickstartMinNodeLvl",1)
	gQuickstartMaxNodeLvl = ffxivminion.GetSetting("gQuickstartMaxNodeLvl",80)
	
	local quickslot = { 1, 2, 3,4 ,5 ,6, 7, 8}
	gGatherQuickSlot = ffxivminion.GetSetting("gGatherQuickSlot",1)
	gGatherQuickSlotIndex = GetKeyByValue(gGatherQuickSlot,quickslot)
	
	gGatherCollectablePresets = ffxivminion.GetSetting("gGatherCollectablePresets",{})	
	gGatherTaskFilterID = 0
	gGatherTaskFilterAlias = ""
	
	-- New Marker/Profile Settings
	gGatherMarkerOrProfileOptions = { GetString("Markers"), GetString("Profile"), GetString("Quick Start Mode") }
	gGatherMarkerOrProfile = ffxivminion.GetSetting("gGatherMarkerOrProfile",GetString("Markers"))
	gGatherMarkerOrProfileIndex = ffxivminion.GetSetting("gGatherMarkerOrProfileIndex",1)
	
	self.GUI = {}
	-- Load correct tabs for current mode on inital run.
	if gGatherMarkerOrProfileIndex == 1 then
			self.GUI.main_tabs = GUI_CreateTabs("Marker Lists,Settings,Collectable,Debug",true)
		elseif gGatherMarkerOrProfileIndex == 2 then
			self.GUI.main_tabs = GUI_CreateTabs("Settings,Collectable,Debug",true)
		elseif gGatherMarkerOrProfileIndex == 3 then
			self.GUI.main_tabs = GUI_CreateTabs("Quick Start,Settings,Collectable,Debug",true)
		end
	self.GUI.profile = {
		open = false,
		visible = true,
		name = "Gather - Profile Management",
		main_tabs = GUI_CreateTabs("Manage,Add,Edit",true),
	}
end

function ffxiv_task_gather:Draw()
	local tabindex, tabname = GUI_DrawTabs(self.GUI.main_tabs)
	local MarkerOrProfileWidth = (GUI:GetContentRegionAvail() - 10)
	if FFXIV_Common_BotRunning then 
		local currentMarker = ml_marker_mgr.currentMarker
		if (table.valid(currentMarker)) then
			TimeLeft = currentMarker:GetTimeRemaining()
			GUI:Columns(2)
			GUI:Spacing();
			GUI:Text(GetString("Marker Time Remaning (s): "))
			GUI:NextColumn()
			
			GUI:PushItemWidth(150)
			if TimeLeft > 0 then
				GUI:InputText("##TimeLeft",TimeLeft,GUI.InputTextFlags_ReadOnly) 
			else
				GUI:InputText("##TimeLeft","Inf",GUI.InputTextFlags_ReadOnly) 
			end
			GUI:PopItemWidth()
			GUI:Columns()
		end
		local profiletask = ffxiv_gather.currentTask
		if table.valid(profiletask) then
			local TimeLeft = 0
			if profiletask.maxtime ~= nil then
				if (profiletask.maxtime > 0 and profiletask.maxtime ~= nil) then
					local TaskStarted = profiletask.taskStarted
					if TaskStarted then
						local TimeSince = TimeSince(profiletask.taskStarted) or 0
						local MaxTime = profiletask.maxtime
						TimeLeft = math.round(MaxTime-(TimeSince/1000),0)
						if TimeLeft < 0 then TimeLeft = Inf end
					end
				end
			end
			GUI:Columns(2)
			GUI:Spacing();
			GUI:Text(GetString("Task Time Remaning (s): "))
			GUI:Spacing();
			GUI:Text(GetString("Fish Task: "))
			GUI:NextColumn()
			
			GUI:PushItemWidth(150)
			GUI:InputText("##TimeLeft",TimeLeft,GUI.InputTextFlags_ReadOnly) 
			local taskName = ffxiv_gather.currentTask.name or ffxiv_gather.currentTaskIndex
			GUI:InputText("##taskName",taskName,GUI.InputTextFlags_ReadOnly)
			GUI:PopItemWidth()
			GUI:Columns()
		end	
		GUI:Separator()
	end
	
	-- Gather Mode Selections.
	GUI:Separator()
	GUI:AlignFirstTextHeightToWidgets() 
	GUI:Text("Gather Mode")
	GUI:SameLine(110)
	GUI:PushItemWidth(MarkerOrProfileWidth-110)
	local MarkerOrProfile = GUI_Combo("##MarkerOrProfile", "gGatherMarkerOrProfileIndex", "gGatherMarkerOrProfile", gGatherMarkerOrProfileOptions)
	if (MarkerOrProfile) then
		-- Update tabs on change.
		if gGatherMarkerOrProfileIndex == 1 then
			self.GUI.main_tabs = GUI_CreateTabs("Marker Lists,Settings,Collectable,Debug",true)
		elseif gGatherMarkerOrProfileIndex == 2 then
			self.GUI.main_tabs = GUI_CreateTabs("Settings,Collectable,Debug",true)
		elseif gGatherMarkerOrProfileIndex == 3 then
			self.GUI.main_tabs = GUI_CreateTabs("Quick Start,Settings,Collectable,Debug",true)
		end
	end
	GUI:PopItemWidth()
	if gGatherMarkerOrProfileIndex == 1 then -- Marker stuff.
		if gGatherProfileIndex ~= 1 then
			gGatherProfileIndex = 1
		end
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text("Marker Mode")
		GUI:SameLine(110)
		GUI:PushItemWidth(MarkerOrProfileWidth-110)
		local modeChanged = GUI_Combo("##Marker Mode", "gMarkerModeIndex", "gMarkerMode", ml_marker_mgr.modesDisplay)
		if (modeChanged) then
			local uuid = GetUUID()
			if ( string.valid(uuid) ) then
				if  ( Settings.minionlib.gMarkerModes == nil ) then Settings.minionlib.gMarkerModes = {} end
				Settings.minionlib.gMarkerModes[uuid] = ml_marker_mgr.modes[gMarkerModeIndex]
				Settings.minionlib.gMarkerModes = Settings.minionlib.gMarkerModes
			end
		end
	elseif gGatherMarkerOrProfileIndex == 2 then -- Profile stuff.
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text(GetString("Profile"))
		GUI:SameLine(110)
		GUI:PushItemWidth(MarkerOrProfileWidth-110)
		local profileChanged = GUI_Combo("##"..GetString("Profile"), "gGatherProfileIndex", "gGatherProfile", ffxiv_gather.profilesDisplay)
		if (profileChanged) then
			ffxiv_gather.profileData = ffxiv_gather.profiles[gGatherProfile]
			local uuid = GetUUID()
			Settings.FFXIVMINION.gLastGatherProfiles[uuid] = gGatherProfile
			Settings.FFXIVMINION.gLastGatherProfiles = Settings.FFXIVMINION.gLastGatherProfiles
			c_gathernexttask.subsetExpiration = 0
		end
		GUI:PopItemWidth()
		if gGatherProfileIndex == 1 then
			GUI:TextColored(1,.1,.2,1,"No Profile Selected.")
			if (FFXIV_Common_BotRunning) then
				ml_global_information:ToggleRun()
				d("Please select/create a valid profile.")
			end
		end
	end
	-- Settings Tab.
	if (tabname == GetString("Settings")) then
		
		GUI:Columns(2)
		local CordialWidth = GUI:GetContentRegionAvail() - 10
		GUI:Separator()
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text(GetString("Use Exp Manuals"))
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Allow use of Experience boost manuals.")
		end
		GUI:NextColumn()
		GUI:PushItemWidth(CordialWidth)
		GUI_Capture(GUI:Checkbox("##"..GetString("Use Exp Manuals"),gUseExpManuals),"gUseExpManuals")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Allow use of Experience boost manuals.")
		end
		GUI:Columns()
		GUI:Separator()
		GUI:Columns(2)
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text("Cordials")
		GUI:Separator()
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text("Use Cordials")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Allow use of Cordials for GP.")
		end
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text("Missing GP for High Cordial Usage")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Missing GP required before using a High Cordial.")
		end
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text("Missing GP for Cordial Usage")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Missing GP required before using a Cordial.")
		end
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text("Missing GP for Watered Cordial Usage")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Missing GP required before using a Watered Cordial.")
		end
		GUI:NextColumn()
		GUI:PushItemWidth(CordialWidth)
		GUI_Capture(GUI:Checkbox("##Use Cordials",gGatherUseCordials),"gGatherUseCordials");
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Allow use of Cordials for GP.")
		end
		GUI_DrawIntMinMax(GetString("##High Cordial If    <= (Min GP)"),"ghighCordialsGP",10,50,50,700);
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Missing GP required before using a High Cordial.")
		end
		GUI_DrawIntMinMax(GetString("##Cordial If         <= (Min GP)"),"gnormCordialsGP",10,50,50,700);
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Missing GP required before using a Cordial.")
		end
		GUI_DrawIntMinMax(GetString("##Watered Cordial If <= (Min GP)"),"gwateredCordialsGP",10,50,50,700);
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Missing GP required before using a Watered Cordial.")
		end
		GUI:PopItemWidth()
		GUI:Columns()
		--Stealth Settings
		GUI:Separator()
		GUI:Columns(2)
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text("Stealth")
		GUI:Separator()
		GUI:Text("Detect Range")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Enemy range before applying Stealth.")
		end
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text("Remove Range")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Enemy range before removing Stealth.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Smart Stealth")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Smarter Stealth based on players direction and mob.")
		end
		GUI:NextColumn()
		GUI:PushItemWidth(CordialWidth)
		GUI_DrawIntMinMax("##Stealth - Detect Range","FFXIV_Common_StealthDetect",1,10,0,100)
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Enemy range before applying Stealth.")
		end
		GUI_DrawIntMinMax("##Stealth - Remove Range","FFXIV_Common_StealthRemove",1,10,0,100)
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Enemy range before removing Stealth.")
		end
		GUI:PopItemWidth()
		GUI_Capture(GUI:Checkbox("##Smart Stealth",FFXIV_Common_StealthSmart),"FFXIV_Common_StealthSmart")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Smarter Stealth based on players direction and mob.")
		end
		GUI:Columns()
		GUI:Separator()
		GUI:Columns(2)
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text("Random Delay")
		GUI:Separator()
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text("Min Delay")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Minimum time to wait after Gathering a node.")
		end
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text("Max Delay")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Maximum time to wait after Gathering a node.")
		end
		GUI:NextColumn()
		GUI:PushItemWidth(CordialWidth)
		GUI_DrawIntMinMax(GetString("##gGatherRandomDelayMin"),"gGatherRandomDelayMin",1,1,0,5);
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Minimum time to wait after Gathering a node.")
		end
		GUI_DrawIntMinMax(GetString("##gGatherRandomDelayMax"),"gGatherRandomDelayMax",1,1,0,5);
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Maximum time to wait after Gathering a node.")
		end
		GUI:PopItemWidth()
		GUI:Columns()
		GUI:Separator()
	end
	-- Collectable Tab
	if (tabname == GetString("Collectable")) then
		local CollectableFullWidth = GUI:GetContentRegionAvail()-8
		if (GUI:Button("Add Collectable",CollectableFullWidth,20)) then
			local newCollectable = { name = "", value = 0 }
			table.insert(gGatherCollectablePresets,newCollectable)
			GUI_Set("gGatherCollectablePresets",gGatherCollectablePresets)
		end
		GUI:Columns(2)
		local CollectableWidth1 = GUI:GetContentRegionAvail()
		GUI:Text("Item Name")
		GUI:NextColumn()
		local CollectableWidth2 = GUI:GetContentRegionAvail()
		GUI:Text("Min Value")
		GUI:Columns()
		GUI:Separator()
		-- Collectable List
		if (table.valid(gGatherCollectablePresets)) then
			GUI:Columns(2)
			for i,collectable in pairsByKeys(gGatherCollectablePresets) do
				GUI:PushItemWidth(CollectableWidth1-8)
				GUI:AlignFirstTextHeightToWidgets()
				local newName = GUI:InputText("##gather-collectablepair-name"..tostring(i),collectable.name)
				if (newName ~= collectable.name) then
					gGatherCollectablePresets[i].name = newName
					GUI_Set("gGatherCollectablePresets",gGatherCollectablePresets)
				end
				if (GUI:IsItemHovered()) then
					GUI:SetTooltip("Case-sensitive item name for the item to become a collectable.")
				end
				GUI:PopItemWidth()
				GUI:NextColumn()
				GUI:PushItemWidth(CollectableWidth2-28)
				local newValue = GUI:InputInt("##gather-collectablepair-value"..tostring(i),collectable.value,0,0)
				if (newValue ~= collectable.value) then
					gGatherCollectablePresets[i].value = newValue
					GUI_Set("gGatherCollectablePresets",gGatherCollectablePresets)
				end
				if (GUI:IsItemHovered()) then
					GUI:SetTooltip("Minimum collectable value at which the item will be accepted as a collectable.")
				end
				GUI:PopItemWidth()
				GUI:SameLine()
				GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
				--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
				GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
				if (GUI:ImageButton("##gather-collectablepair-delete"..tostring(i),ml_global_information.path.."\\GUI\\UI_Textures\\bt_alwaysfail_fail.png", 14, 14)) then
					gGatherCollectablePresets[i] = nil
					GUI_Set("gGatherCollectablePresets",gGatherCollectablePresets)
				end
				GUI:PopStyleColor(2)
				GUI:NextColumn()
			end
			GUI:Columns()
		end
	end
	-- Marker Tab
	if (tabname == GetString("Marker Lists")) then
		local currentMode = ml_marker_mgr.modes[gMarkerModeIndex]
		local currentType = ml_marker_mgr.templateDisplayMap[gMarkerType]
		local currentMap = ml_marker_mgr.activeMap
		local currentList = ml_marker_mgr.GetList(currentMode,currentType,currentMap)
		GUI:AlignFirstTextHeightToWidgets() 
		GUI:Text("Marker Type")
		GUI:SameLine(110)
		GUI:PushItemWidth(MarkerOrProfileWidth-110)
		local modeChanged = ml_gui.Combo("##Marker Type", "gMarkerTypeIndex", "gMarkerType", ml_marker_mgr.templateDisplay)
		if (modeChanged) then
			ml_marker_mgr.UpdateMarkerSelector()
		end
		GUI:PopItemWidth()
		-- Marker List
		GUI:BeginChild("##header-list",-8,GUI_GetFrameHeight(6),true)
		if table.valid(currentList) then
			for i,marker in pairsByKeys(currentList) do
				if (table.valid(marker)) then
					local MarkerButtonWidth = GUI:GetContentRegionAvail()
					if (GUI:Button(marker.name.." ["..tostring(marker.id).."]",MarkerButtonWidth-50,18)) then
						-- Set this marker as the currently editing marker.
						ml_marker_mgr.GUI.main_window.open = true
						ml_marker_mgr.createMarker = 0
						ml_marker_mgr.editMarker = marker.id
						ml_marker_mgr.addMarker = 0
						ml_marker_mgr.SwitchTab(2)
					end
					GUI:SameLine(0,5)
					if (GUI:Button("UP##"..tostring(i),20,18)) then
						local lists = ml_marker_mgr.lists
						if (table.valid(lists)) then
							if (lists[currentMode]) then
								if (lists[currentMode][currentType]) then
									if (lists[currentMode][currentType][currentMap]) then
										local thisList = lists[currentMode][currentType][currentMap]
										if (table.valid(thisList)) then
											if (i ~= 1) then
												local temp = thisList[i-1]
												thisList[i-1] = thisList[i]
												thisList[i] = temp
												ml_marker_mgr.WriteMarkerFile()
											end
										end
									end
								end
							end
						end							
					end
					GUI:SameLine(0,5)
					if (GUI:Button("DN##"..tostring(i),20,18)) then
						local lists = ml_marker_mgr.lists
						if (table.valid(lists)) then
							if (lists[currentMode]) then
								if (lists[currentMode][currentType]) then
									if (lists[currentMode][currentType][currentMap]) then
										local thisList = lists[currentMode][currentType][currentMap]
										if (table.valid(thisList)) then
											if (i ~= table.size(thisList)) then
												local temp = thisList[i+1]
												thisList[i+1] = thisList[i]
												thisList[i] = temp
												ml_marker_mgr.WriteMarkerFile()
											end
										end
									end
								end
							end
						end				
					end
				end
			end
		else -- No Valid marker list.
			GUI:TextWrapped("No markers exist for "..gMarkerType.." - "..gMarkerMode)
			GUI:TextWrapped("Set Markers and Marker Type Prior to enabling Bot")
			if (FFXIV_Common_BotRunning) then
				d("No markers exist for "..gMarkerType.." - "..gMarkerMode)
				ml_global_information:ToggleRun()
			end
		end
		GUI:EndChild()
	end
	if (tabname == GetString("Quick Start")) then
		
		GUI:BeginChild("##header-QS",-8,GUI_GetFrameHeight(8),true)
		GUI:Columns(2)
		
	
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Gather Slot")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Slot to collect inside Node.")
		end
		
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Maps")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Gather Maps If Available.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Gardening")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Gather Seeds etc If Available.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Rares")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Gather Rare Items If Available.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Chocobo Food")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Gather Chocobo Food Items If Available.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Use Stealth")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Stealth in Quick Start Mode.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Dangerous Area")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Uses Stealth at increased range.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Min GP")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Min GP to interact with node.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Node Min Level")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Min node level to gather.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Node Max Level")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Max node level to gather.")
		end
		
		GUI:NextColumn()
		
		local MarkerTypeWidth = GUI:GetContentRegionAvail()
		GUI:PushItemWidth(MarkerTypeWidth-8)
		
		local quickslot = { 1, 2, 3,4 ,5 ,6, 7, 8}
		gGatherQuickSlotIndex = GetKeyByValue(gGatherQuickSlot,quickslot) or 1
		if (quickslot[gGatherQuickSlotIndex] ~= gGatherQuickSlot) then
			gGatherQuickSlot = quickslot[gGatherQuickSlotIndex]
		end
		GUI_Combo("##quickslot", "gGatherQuickSlotIndex", "gGatherQuickSlot", quickslot)
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Slot to collect inside Node.")
		end
		GUI_Capture(GUI:Checkbox("##gQuickstartMaps",gQuickstartMaps),"gQuickstartMaps")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Gather Maps If Available.")
		end
		GUI_Capture(GUI:Checkbox("##gQuickstartGardening",gQuickstartGardening),"gQuickstartGardening")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Gather Seeds etc If Available.")
		end
		GUI_Capture(GUI:Checkbox("##gQuickstartRares",gQuickstartRares),"gQuickstartRares")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Gather Rare Items If Available.")
		end
		GUI_Capture(GUI:Checkbox("##gQuickstartChocoboFood",gQuickstartChocoboFood),"gQuickstartChocoboFood")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Gather Chocobo Food Items If Available.")
		end
		GUI_Capture(GUI:Checkbox("##QuickStealth",gSteathQuickMode),"gSteathQuickMode")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Stealth in Quick Start Mode.")
		end
		GUI_Capture(GUI:Checkbox("##QuickStealthDangerous",gSteathDangerousQuickMode),"gSteathDangerousQuickMode")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Uses Stealth at increased range.")
		end
		GUI_DrawIntMinMax(GetString("##gQuickstartMinGp"),"gQuickstartMinGp",10,50,0,800);
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Min GP to interact with node.")
		end
		GUI_DrawIntMinMax(GetString("##gQuickstartMinNodeLvl"),"gQuickstartMinNodeLvl",1,5,1,80);
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Min GP to interact with node.")
		end
		GUI_DrawIntMinMax(GetString("##gQuickstartMaxNodeLvl"),"gQuickstartMaxNodeLvl",1,5,1,80);
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Min GP to interact with node.")
		end
		
		GUI:Columns()
		GUI:EndChild()
	end
	-- Debug Tab
	if (tabname == GetString("Debug"))  then
		GUI:BeginChild("##header-debug",-8,GUI_GetFrameHeight(2),true)
		GUI:Columns(2)
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Gather Debug")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Enable Debug messages in console.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Debug Level")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Change the Debug message level. (The higher the number the more detailed the messages)")
		end
		GUI:NextColumn()
		
		
		GUI_Capture(GUI:Checkbox("##Gather Debug",gFishDebug),"gFishDebug")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Enable Debug messages in console.")
		end
		local DebugWidth = GUI:GetContentRegionAvail()
		GUI:PushItemWidth(DebugWidth)
		
		local debugLevels = { 1, 2, 3}
		gGatherDebugLevelIndex = GetKeyByValue(gGatherDebugLevel,debugLevels) or 1
		if (debugLevels[gGatherDebugLevelIndex] ~= gGatherDebugLevel) then
			gGatherDebugLevel = debugLevels[gGatherDebugLevelIndex]
		end
		GUI_Combo("##Debug Level", "gGatherDebugLevelIndex", "gGatherDebugLevel", debugLevels)
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Change the Debug message level. (The higher the number the more detailed the messages)")
		end
		GUI:PopItemWidth()
		GUI:Columns()
		GUI:EndChild()
	end
end

function ffxiv_gather.GetDirective()
	local marker = ml_marker_mgr.currentMarker
	local task = ffxiv_gather.currentTask
	
	if (table.valid(task)) then
		return task, "task"
	elseif (table.valid(marker)) then
		return marker, "marker"
	end
	
	return nil
end

function ffxiv_gather.HasDirective()
	local marker = ml_marker_mgr.currentMarker
	local task = ffxiv_gather.currentTask
	
	return (table.valid(task) or table.valid(marker))
end

function ffxiv_gather.DeleteTask(key)
	local key = (tonumber(key) or tonumber(gGatherTaskEditID) or 0)
	
	local tasks = ffxiv_gather.profileData.tasks
	if (tasks and tasks[key]) then
		if (TableSize(tasks) > 1) then
			ffxiv_gather.profileData.tasks[key] = nil
		else
			ffxiv_gather.profileData.tasks = {}
		end
		ffxiv_gather.SaveProfile()
	end
end

function ffxiv_gather.SaveProfile(strName)
	strName = IsNull(strName,"")
	
	local info = {}
	if (table.valid(ffxiv_gather.profileData.tasks)) then
		info.tasks = ffxiv_gather.profileData.tasks
	else
		info.tasks = {}
	end
	
	if (strName ~= "") then
		persistence.store(ffxiv_gather.profilePath..strName..".lua",info)
	else
		persistence.store(ffxiv_gather.profilePath..gGatherProfile..".lua",info)
	end
	
	ffxiv_gather.profiles, ffxiv_gather.profilesDisplay = GetPublicProfiles(ffxiv_gather.profilePath,".*lua")
end

function ffxiv_gather.SwitchClass(class)
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
end

function ffxiv_gather.LocatorBuff(class)
	class = tonumber(class) or 0
	if (class ~= FFXIV.JOBS.MINER and class ~= FFXIV.JOBS.BOTANIST) then
		return
	end
	
	local actionid = nil
	if (FFXIV.JOBS.MINER == class) then
		actionid = 238
	elseif (FFXIV.JOBS.BOTANIST == class) then
		actionid = 221
	end
	local action = ActionList:Get(1,actionid)
	if (action and not action.isoncd) then
		action:Cast()
	end
end

function ffxiv_gather.VisibilityBuff(class)
	class = tonumber(class) or 0
	if (class ~= FFXIV.JOBS.MINER and class ~= FFXIV.JOBS.BOTANIST) then
		return
	end
	
	local actionid = nil
	if (FFXIV.JOBS.MINER == class) then
		actionid = 227
	elseif (FFXIV.JOBS.BOTANIST == class) then
		actionid = 210
	end
	local action = ActionList:Get(1,actionid)
	if (action and not action.isoncd) then
		action:Cast()
	end
end

function ffxiv_gather.GetUnspoiledMarkers(mapid)
	local mapid = tonumber(mapid) or 0
	local meshName = Settings.minionlib.DefaultMaps[mapid]
	if (meshName) then
		local markerNameList = GetOffMapMarkerList(meshName, GetString("Unspoiled Marker"))
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

--d(ffxiv_gather.GetLastGather("Example",1))
--d(ffxiv_gather.SetLastGather("Example",1))
--d(TimePassed(GetCurrentTime(),1400000))

function ffxiv_gather.GetLastGather(profile,task)
	if (Settings.FFXIVMINION.gLastGather ~= nil) then
		lastGather = Settings.FFXIVMINION.gLastGather
		if (table.valid(lastGather[profile])) then
			return lastGather[profile][task] or 0
		end
	end
	
	return 0
end

function ffxiv_gather.SetLastGather(profile,taskid)
	local profile = IsNull(profile,"placeholder")
	if (Settings.FFXIVMINION.gLastGather == nil or type(Settings.FFXIVMINION.gLastGather) ~= "table") then
		Settings.FFXIVMINION.gLastGather = {}
	end
	
	local lastGather = Settings.FFXIVMINION.gLastGather
	if (lastGather[profile] == nil or type(lastGather[profile]) ~= "table") then
		lastGather[profile] = {}
	end
	
	lastGather[profile][taskid] = GetCurrentTime()
	
	local tasks  = ffxiv_gather.profileData.tasks
	if (table.valid(tasks)) then
		local thisTask = tasks[taskid]
		if (IsNull(thisTask.group,"") ~= "") then
			for i,task in pairs(tasks) do
				if (IsNull(task.group,"") == thisTask.group and i ~= taskid) then
					lastGather[profile][i] = GetCurrentTime()
				end
			end
		end
	end
	
	Settings.FFXIVMINION.gLastGather = lastGather
end

function ffxiv_gather.ResetLastGather()
	Settings.FFXIVMINION.gLastGather = {}
end
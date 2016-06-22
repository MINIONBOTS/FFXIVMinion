ffxiv_gather = {}
ffxiv_gather.lastTick = 0
ffxiv_gather.timer = 0
ffxiv_gather.lastItemAttempted = 0
ffxiv_gather.editwindow = {name = GetString("locationEditor"), x = 0, y = 0, width = 250, height = 230}
ffxiv_gather.editwindow = GetStartupPath()..[[\LuaMods\ffxivminion\GatherProfiles\]]
ffxiv_gather.profileData = {}
ffxiv_gather.currentTask = {}
ffxiv_gather.currentTaskIndex = 0
ffxiv_gather.collectors = {
	[16] = 4074,
	[17] = 4088,
}

ffxiv_task_gather = inheritsFrom(ml_task)
ffxiv_task_gather.name = "LT_GATHER"
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
	ml_global_information.currentMarker = false
	
	ffxiv_gather.currentTask = {}
	ffxiv_gather.currentTaskIndex = 0
	
	newinst.pos = 0
    newinst.gatherTimer = 0
	newinst.gatherDistance = 1.5
    newinst.idleTimer = 0
	newinst.filterLevel = true
	newinst.failedSearches = 0 
	
	table.insert(tasktracking, newinst)
    
    return newinst
end

function gd(var,level)
	local level = tonumber(level) or 3

	if ( gGatherDebug == "1" ) then
		if ( level <= tonumber(gGatherDebugLevel)) then
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

c_findnode = inheritsFrom( ml_cause )
e_findnode = inheritsFrom( ml_effect )
function c_findnode:evaluate()
	if (ControlVisible("Gathering")) then
		return false
	end
	
	local needsUpdate = false
	if ( ml_task_hub:CurrentTask().gatherid == nil or ml_task_hub:CurrentTask().gatherid == 0 ) then
		needsUpdate = true
	else
		local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
		if (ValidTable(gatherable)) then
			if (not gatherable.cangather) then
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
		local nodemaxlevel = 60
		local basePos = {}
		local blacklist = ""
		local includesHighPrio = true;
	
		local task = ffxiv_gather.currentTask
		local marker = ml_global_information.currentMarker
		if (ValidTable(task)) then
			whitelist = IsNull(task.whitelist,"")
			radius = IsNull(task.radius,150)
			nodemaxlevel = IsNull(task.nodemaxlevel,60)
			nodeminlevel = IsNull(task.nodeminlevel,1)
			basePos = task.pos
			
			if (task.unspoiled and task.unspoiled == false) then
				blacklist = "5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20"
				includesHighPrio = false
			elseif (task.unspoiled and task.unspoiled == true) then
				whitelist = "5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20"
			end
		elseif (ValidTable(marker) and not ValidTable(ffxiv_gather.profileData)) then
			whitelist = IsNull(marker:GetFieldValue(GetUSString("contentIDEquals")),"1;2;3;4;9;10;11;12;13;14;15;16;17;18;19;20;21")
			radius = IsNull(marker:GetFieldValue(GetUSString("maxRadius")),150)
			if (radius == 0) then radius = 150 end
			nodeminlevel = IsNull(marker:GetFieldValue(GetUSString("minContentLevel")),1)
			if (nodeminlevel == 0) then nodeminlevel = 1 end
			nodemaxlevel = IsNull(marker:GetFieldValue(GetUSString("maxContentLevel")),60)
			if (nodemaxlevel == 0) then nodemaxlevel = 60 end
			basePos = marker:GetPosition()
		end
		
		if (ValidTable(basePos)) then
			local myPos = ml_global_information.Player_Position
			local distance = PDistance3D(myPos.x, myPos.y, myPos.z, basePos.x, basePos.y, basePos.z)
			if (distance <= radius) then
			
				if (ValidTable(ffxiv_gather.currentTask)) then
					if (ffxiv_gather.currentTask.taskStarted == 0) then
						ffxiv_gather.currentTask.taskStarted = Now()
					end
				end
			
				local filter = ""
				if (whitelist ~= "") then
					filter = "onmesh,gatherable,minlevel="..tostring(nodeminlevel)..",maxlevel="..tostring(nodemaxlevel)..",contentid="..whitelist
					gd("Using whitelist filter ["..filter.."].",3)
				elseif (blacklist ~= "") then
					filter = "onmesh,gatherable,minlevel="..tostring(nodeminlevel)..",maxlevel="..tostring(nodemaxlevel)..",exclude_contentid="..blacklist
					gd("Using blacklist filter ["..filter.."].",3)
				else
					filter = "onmesh,gatherable,minlevel="..tostring(nodeminlevel)..",maxlevel="..tostring(nodemaxlevel)
					gd("Using filter ["..filter.."].",3)
				end
				
				local gatherable = nil
				local gatherables = MEntityList(filter)
				if (ValidTable(gatherables)) then
					for i,potential in pairs(gatherables) do
						if (MultiComp(potential.contentid,"9,10,11,12,17,18,19,20")) then
							gatherable = potential
						end
					end
				end	
				
				if (gatherable == nil) then
					gatherable = GetNearestFromList(filter,basePos,radius)
				end
				
				if (ValidTable(gatherable)) then
					if (ValidTable(ffxiv_gather.currentTask)) then
						if (ffxiv_gather.currentTask.taskFailed ~= 0) then
							ffxiv_gather.currentTask.taskFailed = 0
						end
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
		if (ValidTable(ffxiv_gather.currentTask)) then
			if (ffxiv_gather.currentTask.taskFailed == 0) then
				ffxiv_gather.currentTask.taskFailed = Now()
			end
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
	if (ControlVisible("Gathering")) then
		return false
	end
	
	e_movetonode.blockOnly = false
    
    if ( ml_task_hub:CurrentTask().gatherid ~= nil and ml_task_hub:CurrentTask().gatherid ~= 0 ) then
        local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
        if (gatherable and gatherable.cangather) then
			local gpos = gatherable.pos
			if (gatherable.distance > 3.3) then
				gd("[MoveToNode]: > 3.3 distance, need to move to id ["..tostring(gatherable.id).."].",2)
				return true
			else
				gd("[MoveToNode]: <= 3.3 distance, need to move to id ["..tostring(gatherable.id).."].",2)
				local minimumGP = 0				
				local task = ffxiv_gather.currentTask
				local marker = ml_global_information.currentMarker
				if (ValidTable(task)) then
					minimumGP = IsNull(task.mingp,0)
				elseif (ValidTable(marker)) then
					minimumGP = IsNull(marker:GetFieldValue(GetUSString("minimumGP")),0)
				end
				
				if (Player.gp.current >= minimumGP) then
					gd("[MoveToNode]: We have enough GP, set target to id ["..tostring(gatherable.id).."] and try to interact.",2)
					Player:SetTarget(gatherable.id)
					Player:SetFacing(gpos.x,gpos.y,gpos.z)
					
					local myTarget = MGetTarget()
					if (myTarget and myTarget.id == gatherable.id) then
						Player:Interact(gatherable.id)
					end
					
					ml_task_hub:CurrentTask():SetDelay(500)
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
	if (ValidTable(gatherable)) then
		local gpos = gatherable.pos
		local eh = ConvertHeading(gpos.h)
		local nodeFront = ConvertHeading((eh + (math.pi)))%(2*math.pi)
		local adjustedPos = GetPosFromDistanceHeading(gpos, 1.5, nodeFront)
		
		gd("[MoveToNode]: Original position x = "..tostring(gpos.x)..",y = "..tostring(gpos.y)..",z ="..tostring(gpos.z),2)
		gd("[MoveToNode]: Adjusted position x = "..tostring(adjustedPos.x)..",y = "..tostring(adjustedPos.y)..",z ="..tostring(adjustedPos.z),2)
		
		local pos;
		if (ValidTable(adjustedPos)) then
			pos = NavigationManager:GetClosestPointOnMesh(adjustedPos,false)
		end
		
		if (not ValidTable(pos)) then
			pos = NavigationManager:GetClosestPointOnMesh(gpos,false)
		end

		local ppos = ml_global_information.Player_Position
		if (ValidTable(pos)) then
			gd("[MoveToNode]: Final position x = "..tostring(pos.x)..",y = "..tostring(pos.y)..",z ="..tostring(pos.z),2)
			
			local dist3d = PDistance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
			
			local newTask = ffxiv_task_movetointeract.Create()
			newTask.pos = pos
			
			newTask.useTeleport = false
			
			local minimumGP = 0
			local task = ffxiv_gather.currentTask
			local marker = ml_global_information.currentMarker
			if (ValidTable(task)) then
				minimumGP = IsNull(task.mingp,0)
			elseif (ValidTable(marker)) then
				minimumGP = IsNull(marker:GetFieldValue(GetUSString("minimumGP")),0)
			end
			
			if (CanUseCordial() or CanUseExpManual() or Player.gp.current < minimumGP) then
				if (dist3d > 8 or IsFlying()) then
					local telePos = GetPosFromDistanceHeading(pos, 5, nodeFront)
					local p,dist = NavigationManager:GetClosestPointOnMesh(telePos,false)
					if (p) then
						local alternateTask = ffxiv_task_movetopos.Create()
						alternateTask.pos = p
						alternateTask.useTeleport = (gTeleport == "1")
						alternateTask.range = 3
						alternateTask.remainMounted = true
						alternateTask.stealthFunction = ffxiv_gather.NeedsStealth
						ml_task_hub:CurrentTask():AddSubTask(alternateTask)
						gd("Starting alternate MOVETOPOS task to use a cordial, manual, or wait for GP.",2)
					end
				end
				gd("Need to use cordial, manual, or wait for GP. ",2)
				return
			end
			
			if (gTeleport == "1" and dist3d > 8) then
				local telePos = GetPosFromDistanceHeading(pos, 5, nodeFront)
				local p,dist = NavigationManager:GetClosestPointOnMesh(telePos,false)
				if (p and dist ~= 0) then
					newTask.pos = p
					newTask.useTeleport = true
				end
			end
			
			newTask.interact = ml_task_hub:CurrentTask().gatherid
			newTask.use3d = true
			newTask.interactRange = 3.3
			newTask.pathRange = 5
			newTask.stealthFunction = ffxiv_gather.NeedsStealth
			ml_task_hub:CurrentTask():AddSubTask(newTask)	
			gd("Starting alternate MOVETOINTERACT task.",2)
		end
	end
end

c_returntobase = inheritsFrom( ml_cause )
e_returntobase = inheritsFrom( ml_effect )
e_returntobase.pos = {}
function c_returntobase:evaluate()
	if (ControlVisible("Gathering")) then
		return false
	end
	
	e_returntobase.pos = {}
    
    if ( ml_task_hub:CurrentTask().gatherid ~= nil or ml_task_hub:CurrentTask().gatherid ~= 0 ) then
        local basePos = {}
	
		local task = ffxiv_gather.currentTask
		local marker = ml_global_information.currentMarker
		if (ValidTable(task)) then
			basePos = task.pos
			if (task.mapid ~= ml_global_information.Player_Map) then
				gd("[ReturnToBase]: Not on correct map yet.",3)
				return false
			end
		elseif (ValidTable(marker) and not ValidTable(ffxiv_gather.profileData)) then
			basePos = marker:GetPosition()
		end

		if (ValidTable(basePos)) then
			local myPos = ml_global_information.Player_Position
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
	if (ValidTable(task)) then
		if (task.taskFailed ~= 0) then
			task.taskFailed = 0
		end
		if (task.range and tonumber(task.range)) then
			range = tonumber(task.range)
		end
	end
	
	local pos = e_returntobase.pos
	
	--ffxiv_task_test.RenderPoint(pos,1,5,5)
	
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = pos
	newTask.useTeleport = (gTeleport == "1")
	newTask.range = range
	newTask.alwaysMount = true
	newTask.remainMounted = true
	newTask.stealthFunction = ffxiv_gather.NeedsStealth
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_nextgathermarker = inheritsFrom( ml_cause )
e_nextgathermarker = inheritsFrom( ml_effect )
function c_nextgathermarker:evaluate()
	if (ValidTable(ffxiv_gather.profileData)) then
		return false
	end
	
	if (Now() < ffxiv_gather.timer or ControlVisible("Gathering")) then
		--d("Next gather marker, returning false in block1.")
		return false
	end
	
	if (gMarkerMgrMode == GetString("singleMarker")) then
		ml_task_hub:ThisTask().filterLevel = false
	else
		ml_task_hub:ThisTask().filterLevel = true
	end
    
    if ( ml_task_hub:ThisTask().currentMarker ~= nil and ml_task_hub:ThisTask().currentMarker ~= 0 ) then
		--d("Checking for new markers.")
        local marker = nil
        local markerType = ""
		if (Player.job == FFXIV.JOBS.BOTANIST) then
			markerType = GetString("botanyMarker")
		else
			markerType = GetString("miningMarker")
		end
		
		if (gMarkerMgrType ~= markerType) then
			ml_marker_mgr.SetMarkerType(markerType)
		end
		
        -- first check to see if we have no initialized marker
        if (ml_task_hub:ThisTask().currentMarker == false) then --default init value
            marker = ml_marker_mgr.GetNextMarker(markerType, ml_task_hub:ThisTask().filterLevel)
			
			if (marker == nil) then
				return false
			end
        end
        
        -- next check to see if our level is out of range
		if (gMarkerMgrMode ~= GetString("singleMarker")) then
			--d("Checking secondary sections.")
			if (marker == nil) then
				if (gMarkerMgrMode == GetString("markerTeam")) then
					--d("Checking marker team section.")
					local gatherid = ml_task_hub:CurrentTask().gatherid or 0
					if (gatherid == 0 and ml_task_hub:CurrentTask().failedSearches > 5) then
						marker = ml_marker_mgr.GetNextMarker(markerType, false)
						--if (ValidTable(marker)) then
							--d("Found a valid marker in team section.")
						--end
					end
				end
			end
			
			if (marker == nil) then
				if (ValidTable(ml_global_information.currentMarker)) then
					if 	(ml_task_hub:ThisTask().filterLevel) and
						(Player.level < ml_global_information.currentMarker:GetMinLevel() or 
						Player.level > ml_global_information.currentMarker:GetMaxLevel()) 
					then
						marker = ml_marker_mgr.GetNextMarker(markerType, ml_task_hub:ThisTask().filterLevel)
						--if (ValidTable(marker)) then
							--d("Found a valid marker in level check section.")
						--end
					end
				end
			end
			
			-- last check if our time has run out
			if (gMarkerMgrMode == GetString("markerList")) then
				--d("Checking marker list section.")
				if (marker == nil) then
					if (ValidTable(ml_global_information.currentMarker)) then
						local expireTime = ml_global_information.MarkerTime
						if (Now() > expireTime) then
							ml_debug("Getting Next Marker, TIME IS UP!")
							marker = ml_marker_mgr.GetNextMarker(markerType, ml_task_hub:ThisTask().filterLevel)
						else
							--d("We haven't reached the expire time yet.")
							return false
						end
					else
						--d("Current marker isn't valid so there is no expire time.")
					end
				else
					--d("Already found a replacement marker.")
				end
			end
		end
        
        if (ValidTable(marker)) then
            e_nextgathermarker.marker = marker
            return true
        end
	--else
		--d("Next gather marker, returning false because current marker is still valid.")
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
	ml_global_information.BlacklistContentID = ml_task_hub:ThisTask().currentMarker:GetFieldValue(GetUSString("NOTcontentIDEquals"))
    ml_global_information.WhitelistContentID = ml_task_hub:ThisTask().currentMarker:GetFieldValue(GetUSString("contentIDEquals"))
	gStatusMarkerName = ml_global_information.currentMarker:GetName()
	ml_task_hub:CurrentTask().gatherid = 0
	ml_global_information.gatherid = 0
	ml_task_hub:CurrentTask().failedSearches = 0
end

function DoGathering(item)
	if (ffxiv_gather.CheckBuffs(item)) then
		ml_task_hub:CurrentTask():SetDelay(1500)
		return 1
	end
	
	if (SkillMgr.Gather(item)) then
		ml_task_hub:CurrentTask():SetDelay(500)
		return 2
	end	

	Player:Gather(item.index)
	if (HasBuffs(Player,"805")) then
		ml_global_information.Await(10000, function () return ControlVisible("GatheringMasterpiece") end)
	end
	return 3
end

c_gather = inheritsFrom( ml_cause )
e_gather = inheritsFrom( ml_effect )
function c_gather:evaluate()
	if (ControlVisible("Gathering")) then
		return true
	end
	
    return false
end
function e_gather:execute()	
	if (Player.action ~= 264 and Player.action ~= 256 and not MIsGCDLocked()) then
		ml_task_hub:CurrentTask().idleTimer = Now()
		ml_debug("Gathering ability is not ready yet.")
		return false
	end
	
	if (Now() < ffxiv_gather.timer) then
		ml_debug("Cannot gather yet, timer still active for another ["..tostring((ffxiv_gather.timer - Now())/1000).."] seconds.")
		return false
	end
	
	local thisNode = MGetEntity(ml_global_information.gatherid)
	if (not ValidTable(thisNode) or not thisNode.cangather) then
		return
	else
		if (ValidTable(ffxiv_gather.currentTask)) then
			if (IsUnspoiled(thisNode.contentid) or IsNull(ffxiv_gather.currentTask.resetdaily,false)) then
				ffxiv_gather.SetLastGather(gProfile,ffxiv_gather.currentTaskIndex)
			end
		end
	end
	
    local list = MGatherableSlotList()
    if (ValidTable(list)) then
		if (thisNode.contentid >= 5) then	
			if (TimeSince(ml_task_hub:CurrentTask().gatherTimer) < 500) then
				ml_debug("Still under a delay due to this being an unspoiled node.")
				return
			end
		end
		
		local gatherMaps = ""
		local gatherGardening = ""
		local gatherRares = false
		local gatherSuperRares = false

		local item1 = ""
		local item2 = ""
		local item3 = ""
		
		local task = ffxiv_gather.currentTask
		local marker = ml_global_information.currentMarker
		if (ValidTable(task)) then
			gatherMaps = IsNull(task.gathermaps,"")
			gatherGardening = IsNull(task.gathergardening,"")
			gatherRares = IsNull(task.gatherrares,false)
			gatherSuperRares = IsNull(task.gatherspecialrares,false)
			gatherChocoFood = IsNull(task.gatherchocofood,false)
			item1 = IsNull(task.item1,"")
			item2 = IsNull(task.item2,"")
			item3 = IsNull(task.item3,"")
		elseif (ValidTable(marker)) then
			gatherMaps = IsNull(marker:GetFieldValue(GetUSString("gatherMaps")),"")
			gatherGardening = IsNull(marker:GetFieldValue(GetUSString("gatherGardening")),"0")
			gatherGardening = (gatherGardening == "1")
			gatherRares = IsNull(marker:GetFieldValue("Rare Items"),"0")
			gatherRares = (gatherRares == "1")
			gatherSuperRares = IsNull(marker:GetFieldValue("Special Rare Items"),"0")
			gatherSuperRares = (gatherChocoFood == "1")
			gatherChocoFood = IsNull(marker:GetFieldValue(GetUSString("gatherChocoFood")),"0")
			gatherChocoFood = (gatherChocoFood == "1")
			item1 = IsNull(marker:GetFieldValue(GetUSString("selectItem1")),"")
			item2 = IsNull(marker:GetFieldValue(GetUSString("selectItem2")),"")
		end
		
		-- 1st pass, maps
		if (gatherMaps ~= "" and gatherMaps ~= false and gatherMaps ~= "None") then
			local hasMap = false
			for x=0,3 do
				local inv = Inventory("type="..tostring(x))
				for i,item in pairs(inv) do
					if (IsMap(item.id)) then
						hasMap = true
						break
					end
				end
				if (hasMap) then
					break
				end
			end
				
			if not hasMap then
				for i, item in pairs(list) do
					if (IsMap(item.id)) then
						local attemptGather = false
						if (gatherMaps == "Any" or gatherMaps == true) then
							attemptGather = true
						elseif (type(gatherMaps) == "string" and string.find(gatherMaps,",")) then
							for map in StringSplit(gatherMaps,",") do
								if (tonumber(map) ~= nil and tonumber(map) == item.id) then
									attemptGather = true
								end
								if attemptGather then break end
							end
						elseif (tonumber(gatherMaps) ~= nil and tonumber(gatherMaps) == item.id) then
							attemptGather = true
						elseif (gatherMaps == "Peisteskin Only" and item.id == 6692) then
							attemptGather = true
						end
					
						if (attemptGather) then
							return DoGathering(item)
						end
					end
				end
			end
		end
			
		--d("Checking gardening section.")
			
		-- 2nd pass, gardening supplies
		if (gatherGardening ~= "" and gatherGardening ~= false and gatherGardening ~= "0") then
			for i, item in pairs(list) do
				local attemptGather = false
				if (gatherGardening ~= "") then
					if ((gatherGardening == "1" or gatherGardening == true) and IsGardening(item.id)) then
						attemptGather = true
					elseif (tonumber(gatherGardening) ~= nil and tonumber(gatherGardening) == item.id) then
						attemptGather = true
					elseif (type(gatherGardening) == "string" and string.find(gatherGardening,",")) then
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
			
		--d("Checking special rare item section.")
			
		-- 3rd pass, try to get special rare items
		if (gatherSuperRares ~= "" and gatherSuperRares ~= false and gatherSuperRares ~= "0") then
			for i, item in pairs(list) do
				local attemptGather = false
				if (gatherSuperRares ~= "") then
					if ((gatherSuperRares == "1" or gatherSuperRares == true) and IsRareItemSpecial(item.id)) then
						attemptGather = true
					elseif (tonumber(gatherSuperRares) ~= nil and tonumber(gatherSuperRares) == item.id) then
						attemptGather = true
					elseif (type(gatherSuperRares) == "string" and string.find(gatherSuperRares,",")) then
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
			
		--d("Checking ixali rare item section.")
						
		-- 5th pass, ixali rare items
		for i, item in pairs(list) do
			if (IsIxaliRare(item.id)) then
				local itemCount = ItemCount(item.id,true)
				if (itemCount < 5) then
					return DoGathering(item)
				end
			end
		end
		
		--d("Checking ixali semi-rare item section.")

		-- 6th pass, semi-rare ixali items
		for i, item in pairs(list) do
			if (IsIxaliSemiRare(item.id)) then
				local itemCount = ItemCount(item.id,true)
				if (itemCount < 15) then
					return DoGathering(item)
				end
			end
		end
		
		--d("Checking chocobo rare item section.")
		
		-- 7th pass to get chocobo rare items
		if (gatherChocoFood ~= "" and gatherChocoFood ~= false and gatherChocoFood ~= "0") then
			for i, item in pairs(list) do
				local attemptGather = false
				if (IsChocoboFoodSpecial(item.id)) then
					if (gatherChocoFood == "1" or gatherChocoFood == true) then
						attemptGather = true
					elseif (tonumber(gatherChocoFood) ~= nil and tonumber(gatherChocoFood) == item.id) then
						attemptGather = true
					elseif (type(gatherChocoFood) == "string" and string.find(gatherChocoFood,",")) then
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
		
		--d("Checking regular rare item section.")
		
		-- 4th pass, regular rare items
		if (gatherRares ~= "" and gatherRares ~= false and gatherRares ~= "0") then
			for i, item in pairs(list) do
				local attemptGather = false
				if ((gatherRares == "1" or gatherRares == true) and IsRareItem(item.id)) then
					attemptGather = true
				elseif (tonumber(gatherRares) ~= nil and tonumber(gatherRares) == item.id) then
					attemptGather = true
				elseif (type(gatherRares) == "string" and string.find(gatherRares,",")) then
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
		
		--d("Checking chocobo item section.")
		
		-- 7th pass to get chocobo items
		if (gatherChocoFood ~= "" and gatherChocoFood ~= false and gatherChocoFood ~= "0") then
			for i, item in pairs(list) do
				local attemptGather = false
				if (IsChocoboFood(item.id)) then
					if (gatherChocoFood == "1" or gatherChocoFood == true) then
						attemptGather = true
					elseif (tonumber(gatherChocoFood) ~= nil and tonumber(gatherChocoFood) == item.id) then
						attemptGather = true
					elseif (type(gatherChocoFood) == "string" and string.find(gatherChocoFood,",")) then
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
		
		--d("Checking unknown item section.")
		
			-- Gather unknown items to unlock them.
		if (Player.level < 60) then
			for i,item in pairs(list) do
				if (item.isunknown) then
					return DoGathering(item)
				end
			end
		end
		
		--d("Checking regular item section.")
		
		local itemid1 = 0
		local itemid2 = 0
		local itemid3 = 0
		local itemslot1 = 0
		local itemslot2 = 0
		local itemslot3 = 0
		
		--d(AceLib.API.Items.GetIDByName("Silkworm Cocoon"))
		
		if (item1 and item1 ~= "" and item1 ~= GetString("none")) then
			itemid1 = AceLib.API.Items.GetIDByName(item1) or 0
			if (itemid1 == 0) then
				gd("[Gather]: Could not find a valid item ID for Item 1 - ["..tostring(item1).."].",3)
			end
		end
		if (tonumber(item1) ~= nil) then
			itemslot1 = tonumber(item1)
		end
		
		if (item2 and item2 ~= "" and item2 ~= GetString("none")) then
			itemid2 = AceLib.API.Items.GetIDByName(item2) or 0
			if (itemid2 == 0) then
				gd("[Gather]: Could not find a valid item ID for Item 2 - ["..tostring(item2).."].",3)
			end
		end
		if (tonumber(item2) ~= nil) then
			itemslot2 = tonumber(item2)
		end
		
		if (item3 and item2 ~= "" and item3 ~= GetString("none")) then
			itemid3 = AceLib.API.Items.GetIDByName(item3) or 0
			if (itemid3 == 0) then
				gd("[Gather]: Could not find a valid item ID for Item 2 - ["..tostring(item3).."].",3)
			end
		end
		if (tonumber(item3) ~= nil) then
			itemslot3 = tonumber(item3)
		end
		
		for i, item in pairs(list) do
			if (itemid1 ~= 0) then
				if (item.id == itemid1) then
					return DoGathering(item)
				end
			end
					
			if (itemslot1 ~= 0) then
				if (item.index == (itemslot1-1) and item.id ~= nil) then
					return DoGathering(item)
				end
			end
		end
		
		for i, item in pairs(list) do
			if (itemid2 ~= 0) then
				if (item.id == itemid2) then
					return DoGathering(item)
				end
			end
				
			if (itemslot2 ~= 0) then
				if (item.index == (itemslot2-1) and item.id ~= nil) then
					return DoGathering(item)
				end
			end
		end
		
		for i, item in pairs(list) do
			if (itemid3 ~= 0) then
				if (item.id == itemid3) then
					return DoGathering(item)
				end
			end
				
			if (itemslot3 ~= 0) then
				if (item.index == (itemslot3-1) and item.id ~= nil) then
					return DoGathering(item)
				end
			end
		end
		
		--d("Checking unknown items, couldn't find any regular items.")
			
		-- Gather unknown items to unlock them.
		for i,item in pairs(list) do
			if (item.isunknown or (IsUnspoiled(thisNode.contentid) and item.chance == 25 and (item.name == "" or item.name == nil))) then
				return DoGathering(item)
			end
		end
		
		--d("Checking random items with good chance.")
			
		-- just grab a random item with good chance
		for i, item in pairs(list) do
			if (item.chance > 50) then
				return DoGathering(item)
			end
		end
		
		--d("Checking random items.")
		
		-- just grab a random item - last resort
		for i, item in pairs(list) do
			return DoGathering(item)
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
	if (ValidTable(task)) then
		local collectables = task.collectables
		if (ValidTable(collectables)) then
			for identifier,minvalue in pairs(collectables) do
				local itemid;
				if (type(identifier) == "string") then
					itemid = AceLib.API.Items.GetIDByName(identifier)
				else
					itemid = identifier
				end
		
				if (itemid) then
					idpairs[itemid] = minvalue
				end
			end
		end
	end
	
	local hasCollect = HasBuffs(Player,"805")
	local isCollectable = (idpairs[item.id] ~= nil) and not item.isunknown
	
	if ((hasCollect and not isCollectable) or (not hasCollect and isCollectable)) then
		local collect = MGetAction(ffxiv_gather.collectors[Player.job],1)
		if (collect and collect.isready) then
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

function CanUseCordial()
	local minimumGP = 0
	local useCordials = (gGatherUseCordials == "1")
	
	local profile, task;
	if (IsFisher(Player.job)) then
		profile = ffxiv_fish.profileData
		task = ffxiv_fish.currentTask
	elseif (IsGatherer(Player.job)) then
		profile = ffxiv_gather.profileData
		task = ffxiv_gather.currentTask
	end
	
	local marker = ml_global_information.currentMarker
	if (ValidTable(task)) then
		minimumGP = IsNull(task.mingp,0)
		useCordials = IsNull(task.usecordials,useCordials)
	elseif (ValidTable(marker) and not ValidTable(ffxiv_gather.profileData)) then
		skillProfile = IsNull(marker:GetFieldValue(GetUSString("skillProfile")),"")
		minimumGP = IsNull(marker:GetFieldValue(GetUSString("minimumGP")),0)
	else
		return false
	end
	
	if (useCordials) then
		if (Player.gp.max >= 550 and ((minimumGP - Player.gp.current) >= 400 or Player.gp.percent <= 30)) then
			local hiCordialHQ = MGetItem(1012669)
			if (hiCordialHQ and hiCordial.isready) then
				--d("[CanUseCordial]: Returning hi-cordial.")
				return true, hiCordialHQ
			end
			
			local hiCordial = MGetItem(12669)
			if (hiCordial and hiCordial.isready) then
				--d("[CanUseCordial]: Returning hi-cordial.")
				return true, hiCordial
			end
		end	
		
		if ((minimumGP - Player.gp.current) >= 100 or Player.gp.percent <= 50) then.
			local cordialHQ = MGetItem(1006141)
			if (cordialHQ and cordialHQ.isready) then
				--d("[CanUseCordial]: Returning cordial.")
				return true, cordialHQ
			end
			
			local cordial = MGetItem(6141)
			if (cordial and cordial.isready) then
				--d("[CanUseCordial]: Returning cordial.")
				return true, cordial
			end
		end
	end
	
	return false, nil
end

function CanUseExpManual()
	if (gUseEXPManuals == "0") then
		return false
	end
	
	if (IsGatherer(Player.job) or IsFisher(Player.job)) then
		if (Player.level >= 15 and Player.level < 60 and MissingBuffs(Player,"46")) then
			if (Player.level >= 15 and Player.level < 35) then
				local manual1 = MGetItem(4633)
				if (manual1 and manual1.isready) then
					return true, manual1
				end
			end
			
			if (Player.level >= 35 and Player.level < 50) then
				local manual2 = MGetItem(4635)
				if (manual2 and manual2.isready) then
					return true, manual2
				end
				
				local manual1 = MGetItem(4633)
				if (manual1 and manual1.isready) then
					return true, manual1
				end
			end

			if (Player.level >= 50 and CanAccessMap(397)) then
				local commercial = MGetItem(12668)
				if (commercial and commercial.isready) then
					--d("Can use commercial manual.")
					return true, commercial
				end
				
				local manual2 = MGetItem(4635)
				if (manual2 and manual2.isready) then
					--d("Can use level 2 manual.")
					return true, manual2
				end
			end
		end
	elseif (IsCrafter(Player.job)) then
		if (Player.level >= 15 and Player.level < 60 and MissingBuffs(Player,"45")) then
			if (Player.level >= 15 and Player.level < 35) then
				local manual1 = MGetItem(4632)
				if (manual1 and manual1.isready) then
					return true, manual1
				end
			end
			
			if (Player.level >= 35 and Player.level < 50) then
				local manual2 = MGetItem(4634)
				if (manual2 and manual2.isready) then
					return true, manual2
				end
				
				local manual1 = MGetItem(4632)
				if (manual1 and manual1.isready) then
					return true, manual1
				end
			end

			if (Player.level >= 50 and CanAccessMap(397)) then
				local commercial = MGetItem(12667)
				if (commercial and commercial.isready) then
					return true, commercial
				end
				
				local manual2 = MGetItem(4634)
				if (manual2 and manual2.isready) then
					return true, manual2
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
	if (MIsLoading() or MIsCasting() or (MIsLocked() and not IsFlying()) or 
		ControlVisible("Gathering") or ControlVisible("GatheringMasterpiece")) then
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
			e_nodeprebuff.requirestop = true
			e_nodeprebuff.requiredismount = true
			return true
		end
		
		local canUse,manualItem = CanUseExpManual()
		if (canUse and ValidTable(manualItem)) then
			d("[NodePreBuff]: Need to use a manual, grabbed item ["..tostring(manualItem.hqid).."]")
			e_nodeprebuff.activity = "usemanual"
			e_nodeprebuff.itemid = manualItem.hqid
			e_nodeprebuff.requirestop = true
			e_nodeprebuff.requiredismount = true
			return true
		end
	end
	
	local skillProfile = ""
	local minimumGP = 0
	local useCordials = (gGatherUseCordials == "1")
	local taskType = ""
	local useFavor = 0
	local useFood = 0
	
	local profile = ffxiv_gather.profileData
	local task = ffxiv_gather.currentTask
	local marker = ml_global_information.currentMarker
	if (ValidTable(task)) then
		skillProfile = IsNull(task.skillprofile,"")
		minimumGP = IsNull(task.mingp,0)
		useCordials = IsNull(task.usecordials,useCordials)
		taskType = IsNull(task.type,"")
		useFavor = IsNull(task.favor,0)
		useFood = IsNull(task.food,0)
	elseif (ValidTable(marker) and not ValidTable(ffxiv_gather.profileData)) then
		skillProfile = IsNull(marker:GetFieldValue(GetUSString("skillProfile")),"")
		minimumGP = IsNull(marker:GetFieldValue(GetUSString("minimumGP")),0)
		useFavor = IsNull(marker:GetFieldValue(GetUSString("favor")),0)
	else
		return false
	end
	
	if (skillProfile ~= "" and gSMprofile ~= skillProfile) then
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
	
	if (IsNull(ml_task_hub:ThisTask().gatherid,0) ~= 0 and 
		not MIsLocked()) 
	then
        local gatherable = EntityList:Get(ml_task_hub:ThisTask().gatherid)
        if (gatherable and gatherable.cangather) then
			if (gatherable.distance <= 15) then
				if (useCordials) then
					local canUse,cordialItem = CanUseCordial()
					if (canUse and ValidTable(cordialItem)) then
						d("[NodePreBuff]: Need to use a cordial.")
						e_nodeprebuff.activity = "usecordial"
						e_nodeprebuff.itemid = cordialItem.hqid
						e_nodeprebuff.requirestop = true
						e_nodeprebuff.requiredismount = true
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
								local favor = MGetItem(useFavor)
								if (favor and favor.isready) then
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
				local food = MGetItem(useFood)
				if (food and food.isready and MissingBuffs(Player,"48")) then
					e_nodeprebuff.activity = "usefood"
					e_nodeprebuff.itemid = food.hqid
					e_nodeprebuff.requirestop = true
					e_nodeprebuff.requiredismount = true
					return true
				end
			end
        end
    end
	
	if (taskType ~= "") then
		if (taskType == "botany") then
			if (Player.job ~= FFXIV.JOBS.BOTANIST and CanSwitchToClass(FFXIV.JOBS.BOTANIST)) then
				if (ValidTable(profile) and ValidTable(profile.setup) and IsNull(profile.setup.gearsetbotany,0) ~= 0) then
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
			end
		elseif (taskType == "mining") then
			if (Player.job ~= FFXIV.JOBS.MINER and CanSwitchToClass(FFXIV.JOBS.MINER)) then
				if (ValidTable(profile) and ValidTable(profile.setup) and IsNull(profile.setup.gearsetmining,0) ~= 0) then
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
	
	if (requirestop and Player:IsMoving()) then
		Player:Stop()
		ml_global_information.Await(1500, function () return (not Player:IsMoving()) end)
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
		local manual = MGetItem(activityitemid)
		if (manual and manual.isready) then
			manual:Use()
			ml_global_information.Await(4000, function () return HasBuff(Player.id, 46) end)
			return
		end
	end
	
	if (activity == "usefood") then
		local food = MGetItem(activityitemid)
		if (food and food.isready) then
			food:Use()
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
		local favor = MGetItem(activityitemid)
		if (favor and favor.isready) then
			favor:Use()
			ml_global_information.Await(4000, function () return (HasBuff(Player.id, favorBuff)) end)
			return
		end
	end
	
	if (activity == "usecordial") then
		local cordial = MGetItem(activityitemid)
		if (cordial and cordial.isready) then
			cordial:Use()
			ml_global_information.Await(400, function () return (not ItemReady(activityitemid)) end)
			return
		end
	end
	
	if (activity == "switchclasslegacy") then
		ml_task_hub:ThisTask():SetDelay(2000)
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
	if (ControlVisible("Gathering")) then
		return false
	end
	
	if (ml_global_information.Player_InCombat and not Player:IsMoving() and ml_task_hub:CurrentTask().name ~= "MOVETOPOS") then
		local ppos = ml_global_information.Player_Position
		
		if (ValidTable(ml_marker_mgr.markerList["evacPoint"])) then
			local fpos = ml_marker_mgr.markerList["evacPoint"]
			if (Distance3D(ppos.x, ppos.y, ppos.z, fpos.x, fpos.y, fpos.z) > 50) then
				e_gatherflee.fleePos = fpos
				return true
			end
		end
		
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
				return not ml_global_information.Player_InCombat
			end
		newTask.task_fail_eval = 
			function ()
				return not Player.alive or ((not c_walktopos:evaluate() and not Player:IsMoving()) and ml_global_information.Player_InCombat)
			end
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	else
		ml_error("Need to flee but no evac position defined for this mesh!!")
	end
end

--[[
GatheringMasterpiece
Player:GetCollectableInfo()
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
	if (ControlVisible("GatheringMasterpiece")) then
	--d("[CollectableGame]: Found the gathering masterpiece addon.")
		return true
	end
	return false
end
function e_collectiblegame:execute()
	if (Now() < e_collectiblegame.timer or MIsCasting()) then
		return 
	end
	
	d("[CollectableGame]: Checking collectable info.")
	local info = Player:GetCollectableInfo()
	if (ValidTable(info)) then
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
		if (ValidTable(task)) then
			local collectables = task.collectables
			if (ValidTable(collectables)) then
				for identifier,minvalue in pairs(collectables) do
					local itemid;
					if (type(identifier) == "string") then
						itemid = AceLib.API.Items.GetIDByName(identifier)
					else
						itemid = identifier
					end
			
					if (itemid) then
						idpairs[itemid] = minvalue
					end
				end
			end
		end
		
		local requiredRarity = 0
		if (ValidTable(idpairs)) then
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
					
		d("Item current rarity ["..tostring(info.rarity).."].",3)
		d("Item required rarity ["..tostring(requiredRarity).."].",3)
		d("Item current wear ["..tostring(info.wear).."].",3)
		d("Item max wear ["..tostring(info.wearmax).."].",3)
				
		if (info.rarity > 0 and
			(((info.rarity >= tonumber(requiredRarity)) and tonumber(requiredRarity) > 0) or 
			(info.rarity == info.raritymax) or
			(info.wear == 30)))
		then
			PressCollectReturn(true)
			e_collectiblegame.timer = Now() + 500
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
							
				for prio,skill in pairsByKeys(SkillMgr.SkillProfile) do
					if (tonumber(skill.id) == discernings[Player.job]) then
						gd("[CollectableGame]: Profile is set to handle collectables, do not use auto-skills.",3)
						e_collectiblegame.timer = Now() + 500
						return
					end
				end
							
				gd("[CollectableGame]: Attempting to use auto-skills.",3)
				local methodical = ActionList:Get(methodicals[Player.job])
				local discerning = ActionList:Get(discernings[Player.job])
				
				if (discerning and discerning.isready and info.rarity <= 1) then
					if (not HasBuffs(Player,"757")) then
						discerning:Cast()
						e_collectiblegame.timer = Now() + 2500
						return
					end
				end
							
				if (HasBuffs(Player,"757")) then
					if (methodical and methodical.isready) then
						methodical:Cast()
						e_collectiblegame.timer = Now() + 2500
						return
					end
				end
			end
		end
	end
end

c_collectibleaddongather = inheritsFrom( ml_cause )
e_collectibleaddongather = inheritsFrom( ml_effect )
function c_collectibleaddongather:evaluate()
	if (ControlVisible("SelectYesNoItem")) then
		local info = Player:GetYesNoItemInfo()
		if (ValidTable(info)) then
			local validCollectible = false
			
			if (gMinerCollectibleName and gMinerCollectibleName ~= "" 
				and tonumber(gMinerCollectibleValue) and tonumber(gMinerCollectibleValue) > 0) 
			then
				local itemid = AceLib.API.Items.GetIDByName(gMinerCollectibleName,48)
				if (itemid) then
					if (string.find(tostring(info.itemid),tostring(itemid))) then
						if (info.collectability >= tonumber(gMinerCollectibleValue)) then
							validCollectible = true
						else
							gd("Collectibility was too low ["..tostring(info.collectability).."].",3)
						end
					end	
				end
			end
			
			if (gMinerCollectibleName2 and gMinerCollectibleName2 ~= "" 
				and tonumber(gMinerCollectibleValue2) and tonumber(gMinerCollectibleValue2) > 0) 
			then
				local itemid = AceLib.API.Items.GetIDByName(gMinerCollectibleName2,48)
				if (itemid) then
					if (string.find(tostring(info.itemid),tostring(itemid))) then
						if (info.collectability >= tonumber(gMinerCollectibleValue2)) then
							validCollectible = true
						else
							gd("Collectibility was too low ["..tostring(info.collectability).."].",3)
						end
					end	
				end
			end
			
			if (gMinerCollectibleName3 and gMinerCollectibleName3 ~= "" 
				and tonumber(gMinerCollectibleValue3) and tonumber(gMinerCollectibleValue3) > 0) 
			then
				local itemid = AceLib.API.Items.GetIDByName(gMinerCollectibleName3,48)
				if (itemid) then
					if (string.find(tostring(info.itemid),tostring(itemid))) then
						if (info.collectability >= tonumber(gMinerCollectibleValue3)) then
							validCollectible = true
						else
							gd("Collectibility was too low ["..tostring(info.collectability).."].",3)
						end
					end	
				end
			end
			
			if (gBotanistCollectibleName and gBotanistCollectibleName ~= "" 
				and tonumber(gBotanistCollectibleValue) and tonumber(gBotanistCollectibleValue) > 0) 
			then
				local itemid = AceLib.API.Items.GetIDByName(gBotanistCollectibleName,45)
				if (itemid) then
					if (string.find(tostring(info.itemid),tostring(itemid))) then
						if (info.collectability >= tonumber(gBotanistCollectibleValue)) then
							validCollectible = true
						else
							gd("Collectibility was too low ["..tostring(info.collectability).."].",3)
						end
					end	
				end
			end
			
			if (gBotanistCollectibleName2 and gBotanistCollectibleName2 ~= "" 
				and tonumber(gBotanistCollectibleValue2) and tonumber(gBotanistCollectibleValue2) > 0) 
			then
				local itemid = AceLib.API.Items.GetIDByName(gBotanistCollectibleName2,45)
				if (itemid) then
					if (string.find(tostring(info.itemid),tostring(itemid))) then
						if (info.collectability >= tonumber(gBotanistCollectibleValue2)) then
							validCollectible = true
						else
							gd("Collectibility was too low ["..tostring(info.collectability).."].",3)
						end
					end	
				end
			end
			
			if (gBotanistCollectibleName3 and gBotanistCollectibleName3 ~= "" 
				and tonumber(gBotanistCollectibleValue3) and tonumber(gBotanistCollectibleValue3) > 0) 
			then
				local itemid = AceLib.API.Items.GetIDByName(gBotanistCollectibleName3,45)
				if (itemid) then
					if (string.find(tostring(info.itemid),tostring(itemid))) then
						if (info.collectability >= tonumber(gBotanistCollectibleValue3)) then
							validCollectible = true
						else
							gd("Collectibility was too low ["..tostring(info.collectability).."].",3)
						end
					end	
				end
			end
			
			local task = ffxiv_gather.currentTask
			if (ValidTable(task)) then
				local collectables = task.collectables
				if (ValidTable(collectables)) then
					for identifier,minvalue in pairs(collectables) do
						local itemid;
						if (type(identifier) == "string") then
							itemid = AceLib.API.Items.GetIDByName(identifier)
						else
							itemid = identifier
						end
						
						if (itemid) then
							if (string.find(tostring(info.itemid),tostring(itemid))) then
								if (info.collectability >= tonumber(minvalue)) then
									validCollectible = true
								else
									gd("Collectibility was too low ["..tostring(info.collectability).."].",3)
								end
							end	
						end
					end
				end
			end
			
			if (not validCollectible) then
				PressYesNoItem(false) 
				return true
			else
				PressYesNoItem(true) 
				return true
			end
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
	if (not Player.alive or not ValidTable(ffxiv_gather.profileData) or ControlVisible("Gathering")) then
		return false
	end
	
	c_gathernexttask.blockOnly = false
	
	local evaluate = false
	local invalid = false
	local tempinvalid = false
	
	local currentTask = ffxiv_gather.currentTask
	local currentTaskIndex = ffxiv_gather.currentTaskIndex
	
	if (not ValidTable(currentTask)) then
		gd("[GatherNextTask]: We have no current task, so set the invalid flag.",3)
		invalid = true
	else
		gd("[GatherNextTask]: We have a current task, check if it should be completed.",3)
		if (IsNull(currentTask.interruptable,false) or IsNull(currentTask.lowpriority,false)) then
			gd("[GatherNextTask]: Task is interruptable, set the flag.",3)
			evaluate = true
		elseif not (currentTask.weatherlast or currentTask.weathernow or currentTask.weathernext or currentTask.highpriority or
				 currentTask.eorzeaminhour or currentTask.eorzeamaxhour or currentTask.normalpriority)
		then
			gd("[GatherNextTask]: Task is interruptable, set the flag.",3)
			evaluate = true
		end
		
		if (not invalid) then
			if (currentTask.minlevel and Player.level < currentTask.minlevel) then
				gd("[GatherNextTask]: Level is too low for the task, invalidate.",3)
				invalid = true
			elseif (currentTask.maxlevel and Player.level > currentTask.maxlevel) then
				gd("[GatherNextTask]: Level is too high for the task, invalidate.",3)
				invalid = true
			end
		end
		
		if (not invalid) then
			local lastGather = ffxiv_gather.GetLastGather(gProfile,currentTaskIndex)
			if (lastGather ~= 0) then
				if (TimePassed(GetCurrentTime(), lastGather) < 1400) then
					gd("[GatherNextTask]: Our last gather was only ["..tostring(TimePassed(GetCurrentTime(), lastGather)).."] seconds ago, invalidate.",3)
					invalid = true
				end
			end
		end
			
		if (not invalid) then
			local weather = AceLib.API.Weather.Get(currentTask.mapid)
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
			local shifts = AceLib.API.Weather.GetShifts()
			local lastShift = shifts.lastShift
			local nextShift = shifts.nextShift
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
				if (currentTask.taskStarted > 0 and TimeSince(currentTask.taskStarted) > currentTask.maxtime) then
					gd("[GatherNextTask]: Task has been ongoing for too long, invalidate.",3)
					invalid = true
				else
					if (currentTask.taskStarted ~= 0) then
						gd("Max time allowed ["..tostring(currentTask.maxtime).."], time passed ["..tostring(TimeSince(currentTask.taskStarted)).."].",3)
					end
				end
			end
			if (IsNull(currentTask.timeout,0) > 0) then
				if (currentTask.taskFailed > 0 and TimeSince(currentTask.taskFailed) > currentTask.timeout) then
					tempinvalid = true
					invalid = true
					gd("[GatherNextTask]: Task has been idle too long, invalidate.",3)
				else
					if (currentTask.taskFailed ~= 0) then
						gd("Max time allowed ["..tostring(currentTask.timeout).."], time passed ["..tostring(TimeSince(currentTask.taskFailed)).."].",3)
					end
				end
			end
			if (IsNull(currentTask.eorzeaminhour,-1) ~= -1 and IsNull(currentTask.eorzeamaxhour,-1) ~= -1) then
				local eTime = AceLib.API.Weather.GetDateTime() 
				local eHour = eTime.hour
				
				local validHour = false
				local i = currentTask.eorzeaminhour
				while (i ~= currentTask.eorzeamaxhour) do
					if (i == eHour) then
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
			
		if (currentTask.complete) then
			local conditions = shallowcopy(currentTask.complete)
			for condition,value in pairs(conditions) do
				local f = assert(loadstring("return " .. condition))()
				if (f ~= nil) then
					if (f == value) then
						invalid = true
					end
					conditions[condition] = nil
				end
				if (invalid) then
					gd("[GatherNextTask]: Complete condition has been satisfied, invalidate.",3)
					break
				end
			end
		end
	end
	
	if (invalid and not tempinvalid) then
		gd("[GatherNextTask]: Remove this index from the cached subset.",3)
		c_gathernexttask.subset[currentTaskIndex] = nil
	end

	if (evaluate or invalid) then
		local profileData = ffxiv_gather.profileData
		if (ValidTable(profileData.tasks)) then
			
			local validTasks = {}
			if (Now() < c_gathernexttask.subsetExpiration) then
				gd("[GatherNextTask]: Check the cached subset of tasks.",3)
				validTasks = c_gathernexttask.subset
			else
				validTasks = deepcopy(profileData.tasks,true)
				for i,data in pairs(validTasks) do
				
					local valid = true

					if (data.enabled and data.enabled ~="1") then
						valid = false
						gd("Task ["..tostring(i).."] not enabled.",3)
					end

					if (data.minlevel and Player.level < data.minlevel) then
						valid = false
					elseif (data.maxlevel and Player.level > data.maxlevel) then
						valid = false
					end
					
					if (valid) then
						local lastGather = ffxiv_gather.GetLastGather(gProfile,i)
						if (lastGather ~= 0) then
							if (TimePassed(GetCurrentTime(), lastGather) < 1400) then
								valid = false
								gd("Task ["..tostring(i).."] not valid due to last gather.",3)
							end
						end
					end
					
					if (valid) then
						if (data.condition) then
							local conditions = deepcopy(data.condition,true)
							valid = TestConditions(conditions)
						end
					end
					
					if (valid) then
						local weather = AceLib.API.Weather.Get(data.mapid)
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
						local shifts = AceLib.API.Weather.GetShifts()
						local lastShift = shifts.lastShift
						local nextShift = shifts.nextShift
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
							local eTime = AceLib.API.Weather.GetDateTime() 
							local eHour = eTime.hour
							
							local validHour = false
							local i = data.eorzeaminhour
							while (i ~= data.eorzeamaxhour) do
								if (i == eHour) then
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
				local eTime = AceLib.API.Weather.GetDateTime() 
				local eMinute = eTime.minute
				local quarters = { [15] = true, [30] = true, [45] = true, [60] = true }
				local expirationDelay = 0
				for quarter,_ in pairs(quarters) do
					local diff = (quarter - eMinute)
					if (diff <= 15 and diff > 0) then
						expirationDelay = (diff * 2.92) * 1000
						break
					end	
				end
				d("Buffering task evaluation by ["..tostring(expirationDelay / 1000).."] seconds.")
				c_gathernexttask.subsetExpiration = Now() + expirationDelay
			end
			
			if (ValidTable(validTasks)) then
				local highPriority = {}
				local normalPriority = {}
				local lowPriority = {}
				
				for i,data in pairsByKeys(validTasks) do
					-- Items with weather requirements go into high priority
					if (data.highpriority) then
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
				
				local lowestIndex = 9999
				local best = nil
				
				-- High priority section.
				
				gd("[GatherNextTask]: Check the high priority tasks for differently grouped tasks.",3)
				for i,data in pairsByKeys(highPriority) do
					if (not currentTask.group or IsNull(data.group,"") ~= currentTask.group) then
						if (not best or (best and i < lowestIndex)) then
							best = data
							lowestIndex = i
						end
					end
				end
				
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
				end
				
				-- Normal priority section.
				
				if (not best) then
					if (invalid or evaluate) then
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
					
						if (not best) then
							gd("[GatherNextTask]: Check the normal priority tasks for matching grouped tasks.",3)
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
									gd("[GatherNextTask]: Check the normal priority tasks for differently grouped tasks.",3)
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
					end
				end
				
				-- Low priority section.
				if (invalid and not best) then
					gd("[GatherNextTask]: Check the low priority section since haven't found anything yet.",3)
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
				
				if (best) then
					if (ffxiv_gather.currentTaskIndex ~= lowestIndex) then
						ffxiv_gather.currentTaskIndex = lowestIndex
						ffxiv_gather.currentTask = best
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
	
	ml_global_information.currentMarker = false
	gStatusMarkerName = ""
	ml_task_hub:CurrentTask().gatherid = 0
	ml_global_information.gatherid = 0
	ml_task_hub:CurrentTask().failedSearches = 0
	ffxiv_gather.currentTask.taskStarted = 0
	ffxiv_gather.currentTask.taskFailed = 0
	ml_global_information.lastInventorySnapshot = GetInventorySnapshot()
end

c_gathernextprofilemap = inheritsFrom( ml_cause )
e_gathernextprofilemap = inheritsFrom( ml_effect )
function c_gathernextprofilemap:evaluate()
    if (not ValidTable(ffxiv_gather.profileData)) then
		return false
	end
    
	local task = ffxiv_gather.currentTask
	if (ValidTable(task)) then
		if (ml_global_information.Player_Map ~= task.mapid) then
			return true
		end
	end
    
    return false
end
function e_gathernextprofilemap:execute()
	local index = ffxiv_gather.currentTaskIndex
	local task = ffxiv_gather.currentTask

	local mapID = task.mapid
	local taskPos = task.pos
	local pos = ml_nav_manager.GetNextPathPos(ml_global_information.Player_Position,ml_global_information.Player_Map,mapID)
	if (ValidTable(pos)) then		
		local newTask = ffxiv_task_movetomap.Create()
		newTask.destMapID = mapID
		newTask.pos = task.pos
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
				if (noTeleportMaps[ml_global_information.Player_Map]) then
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
		
		--ffxiv_dialog_manager.IssueStopNotice("Gather_NextTask", "No path found from map "..tostring(ml_global_information.Player_Map).." to map "..tostring(mapID))
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
	local marker = ml_global_information.currentMarker
	if (ValidTable(task)) then
		useStealth = IsNull(task.usestealth,false)
	elseif (ValidTable(marker) and not ValidTable(ffxiv_gather.profileData)) then
		useStealth = (marker:GetFieldValue(GetUSString("useStealth")) == "1")
	else
		return false
	end
	
	if (useStealth) then
		if (Player.incombat) then
			return false
		end
		
		if (ControlVisible("Gathering")) then
			return false
		end
		
		local stealth = nil
		if (Player.job == FFXIV.JOBS.BOTANIST) then
			stealth = ActionList:Get(212)
		elseif (Player.job == FFXIV.JOBS.MINER) then
			stealth = ActionList:Get(229)
		end
		
		if (stealth) then
			local dangerousArea = false
			local destPos = {}
			local myPos = ml_global_information.Player_Position
			local task = ffxiv_gather.currentTask
			local marker = ml_global_information.currentMarker
			if (ValidTable(task)) then
				dangerousArea = IsNull(task.dangerousarea,false)
				destPos = task.pos
			elseif (ValidTable(marker)) then
				dangerousArea = marker:GetFieldValue(GetUSString("dangerousArea")) == "1"
				destPos = marker:GetPosition()
			end
		
			if (not dangerousArea and ml_task_hub:CurrentTask().name == "MOVETOPOS") then
				local dest = ml_task_hub:CurrentTask().pos
				if (Distance3D(myPos.x,myPos.y,myPos.z,dest.x,dest.y,dest.z) > 75) then
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
					local potentialAdds = EntityList("alive,attackable,aggressive,maxdistance="..tostring(tonumber(gAdvStealthDetect)*2)..",minlevel="..tostring(Player.level - 10)..",distanceto="..tostring(gatherable.id))
					if (TableSize(potentialAdds) > 0) then
						if (not HasBuff(Player.id, 47)) then
							return true
						else
							return false
						end
					end
				end
				
				if (gatherable) then
					if (gTeleport == "1" and c_teleporttopos:evaluate()) then
						local potentialAdds = EntityList("alive,attackable,aggressive,maxdistance="..tostring(gAdvStealthDetect)..",minlevel="..tostring(Player.level - 10)..",distanceto="..tostring(gatherable.id))
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
			
			
			local addMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(gAdvStealthDetect))
			local removeMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(gAdvStealthRemove))
			if (TableSize(removeMobList) == 0 and HasBuff(Player.id, 47)) then
				return true
			elseif (ValidTable(addMobList)) then
				if (gAdvStealthRisky == "1") then
					local ph = ConvertHeading(ml_global_information.Player_Position.h)
					local playerFront = ConvertHeading((ph + (math.pi)))%(2*math.pi)
					local nextPos = IsNull(GetPosFromDistanceHeading(ml_global_information.Player_Position, 10, playerFront),ml_global_information.Player_Position)
				
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

	local useStealth = false
	local task = ffxiv_gather.currentTask
	local marker = ml_global_information.currentMarker
	if (ValidTable(task)) then
		useStealth = IsNull(task.usestealth,false)
	elseif (ValidTable(marker)) then
		useStealth = (marker:GetFieldValue(GetUSString("useStealth")) == "1")
	end
	
	if (useStealth) then	
		local stealth = nil
		if (Player.job == FFXIV.JOBS.BOTANIST) then
			stealth = ActionList:Get(212)
		elseif (Player.job == FFXIV.JOBS.MINER) then
			stealth = ActionList:Get(229)
		end
		
		if (stealth) then
			local dangerousArea = false
			local destPos = ml_task_hub:CurrentTask().pos
			local myPos = ml_global_information.Player_Position
			local task = ffxiv_gather.currentTask
			local marker = ml_global_information.currentMarker
			if (ValidTable(task)) then
				dangerousArea = IsNull(task.dangerousarea,false)
			elseif (ValidTable(marker)) then
				dangerousArea = marker:GetFieldValue(GetUSString("dangerousArea")) == "1"
			end
			
			if (destPos) then
				if (not dangerousArea and ml_task_hub:CurrentTask().name == "MOVETOPOS") then
					local dist = PDistance3D(myPos.x,myPos.y,myPos.z,destPos.x,destPos.y,destPos.z)
					if (dist > 75) then
						--d("Too far from destination to use stealth.")
						return false
					end
				end
			end
			
			local gatherid = ml_global_information.gatherid
			if ( gatherid and gatherid ~= 0 ) then
				local gatherable = EntityList:Get(gatherid)
				if (gatherable and (gatherable.distance < 10) and IsUnspoiled(gatherable.contentid)) then
					local potentialAdds = EntityList("alive,attackable,aggressive,maxdistance="..tostring(tonumber(gAdvStealthDetect)*2)..",minlevel="..tostring(Player.level - 10)..",distanceto="..tostring(gatherable.id))
					if (ValidTable(potentialAdds)) then
						return true
					end
				end
				
				if (gatherable) then
					if (gTeleport == "1" and c_teleporttopos:evaluate()) then
						local potentialAdds = EntityList("alive,attackable,aggressive,maxdistance="..tostring(gAdvStealthDetect)..",minlevel="..tostring(Player.level - 10)..",distanceto="..tostring(gatherable.id))
						if (ValidTable(potentialAdds)) then
							return true
						end
					end
				end
			end
			
			local hasStealth = HasBuff(Player.id,47)
			local addMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(gAdvStealthDetect))
			if (ValidTable(addMobList)) then
				if (gAdvStealthRisky == "1" and not dangerousArea) then
					local ph = ConvertHeading(ml_global_information.Player_Position.h)
					local playerFront = ConvertHeading((ph + (math.pi)))%(2*math.pi)
					local nextPos = IsNull(GetPosFromDistanceHeading(ml_global_information.Player_Position, 10, playerFront),ml_global_information.Player_Position)
				
					for i,entity in pairs(addMobList) do
						if (entity.targetid == 0) then
							local epos = entity.pos
							local ray1 = MeshManager:RayCast(epos.x,(epos.y+1.5),epos.z,myPos.x,(myPos.y+1.5),myPos.z)
							local ray2 = MeshManager:RayCast(epos.x,(epos.y+1.5),epos.z,nextPos.x,(nextPos.y+1.5),nextPos.z)
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
				if (gAdvStealthRisky == "0") then
					local removeMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(gAdvStealthRemove))
					if (ValidTable(removeMobList)) then
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
	return MIsLoading()
end
function e_gatherisloading:execute()
	ml_debug("Character is loading, prevent other actions and idle.")
end

c_gatherislocked = inheritsFrom( ml_cause )
e_gatherislocked = inheritsFrom( ml_effect )
function c_gatherislocked:evaluate()
	return MIsLocked() and not IsFlying()
end
function e_gatherislocked:execute()
	ml_debug("Character is loading, prevent other actions and idle.")
end

c_gathernoactivity = inheritsFrom( ml_cause )
e_gathernoactivity = inheritsFrom( ml_effect )
function c_gathernoactivity:evaluate()	
	local marker = ml_global_information.currentMarker
	local task = ffxiv_gather.currentTask
	if (not ValidTable(task) and not ValidTable(marker)) then
		ml_task_hub:CurrentTask():SetDelay(1000)
		return true
	end
	return false
end
function e_gathernoactivity:execute()
	-- Do nothing here, but there's no point in continuing to process and eat CPU.
end

function ffxiv_task_gather:Init()
	--[[ Overwatch Elements ]]
	
	local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 150 )
    self:add( ke_dead, self.overwatch_elements)
	
	local ke_flee = ml_element:create( "Flee", c_gatherflee, e_gatherflee, 140 )
    self:add( ke_flee, self.overwatch_elements)
	
	local ke_avoidAggressives = ml_element:create( "AvoidAggressives", c_avoidaggressives, e_avoidaggressives, 130 )
    self:add( ke_avoidAggressives, self.overwatch_elements)
	
	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 100 )
    self:add( ke_inventoryFull, self.overwatch_elements)
	
	local ke_nodePreBuff = ml_element:create( "NodePreBuff", c_nodeprebuff, e_nodeprebuff, 90 )
    self:add( ke_nodePreBuff, self.overwatch_elements)
	
	--[[ Process Elements ]]
	
	local ke_isLoading = ml_element:create( "IsLoading", c_gatherisloading, e_gatherisloading, 250 )
    self:add( ke_isLoading, self.process_elements)
	
	local ke_autoEquip = ml_element:create( "AutoEquip", c_autoequip, e_autoequip, 220 )
    self:add( ke_autoEquip, self.process_elements)
	
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
	
	
	local ke_noActivity = ml_element:create( "NoActivity", c_gathernoactivity, e_gathernoactivity, 145 )
    self:add( ke_noActivity, self.process_elements)
	
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

function ffxiv_gather.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gGatherUseCordials" or
				k == "gMinerCollectibleName" or
				k == "gMinerCollectibleName2" or
				k == "gMinerCollectibleName3" or
				k == "gMinerCollectibleValue" or
				k == "gMinerCollectibleValue2" or
				k == "gMinerCollectibleValue3" or
				k == "gBotanistCollectibleName" or
				k == "gBotanistCollectibleName2" or
				k == "gBotanistCollectibleName3" or
				k == "gBotanistCollectibleValue" or
				k == "gBotanistCollectibleValue2" or
				k == "gBotanistCollectibleValue3" or
				k == "gGatherDebug" or
				k == "gGatherDebugLevel") then
			SafeSetVar(tostring(k),v)
		elseif ( k == "Field_Name") then
			--Capture the marker name changes, incase it affects our marker lists.
			ffxiv_task_gather.RefreshMarkerList(ml_global_information.Player_Map)
		elseif ( k == "gProfile" and gBotMode == GetString("gatherMode")) then
			d("attempt to load profile.")
			ffxiv_gather.LoadProfile(v)
			Settings.FFXIVMINION["gLastGatherProfile"] = v
        end
    end
    GUI_RefreshWindow(GetString("gatherMode"))
end

-- UI settings etc
function ffxiv_task_gather.UIInit()
	--Add it to the main tracking table, so that we can save positions for it.
	ffxivminion.Windows.Gather = { id = strings["us"].gatherMode, Name = GetString("gatherMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Gather)
	
	if (Settings.FFXIVMINION.gGatherVersion == nil) then
		Settings.FFXIVMINION.gGatherVersion = 2.0
		Settings.FFXIVMINION.gLastGathered = nil
	end
	if (Settings.FFXIVMINION.gLastGatherProfile == nil) then
        Settings.FFXIVMINION.gLastGatherProfile = GetString("none")
    end
	if ( Settings.FFXIVMINION.gGatherUseCordials == nil ) then
		Settings.FFXIVMINION.gGatherUseCordials = "1"
	end
	if (Settings.FFXIVMINION.gMinerCollectibleName == nil) then
		Settings.FFXIVMINION.gMinerCollectibleName = ""
	end
	if (Settings.FFXIVMINION.gMinerCollectibleValue == nil) then
		Settings.FFXIVMINION.gMinerCollectibleValue = 0
	end
	if (Settings.FFXIVMINION.gMinerCollectibleName2 == nil) then
		Settings.FFXIVMINION.gMinerCollectibleName2 = ""
	end
	if (Settings.FFXIVMINION.gMinerCollectibleValue2 == nil) then
		Settings.FFXIVMINION.gMinerCollectibleValue2 = 0
	end
	if (Settings.FFXIVMINION.gMinerCollectibleName3 == nil) then
		Settings.FFXIVMINION.gMinerCollectibleName3 = ""
	end
	if (Settings.FFXIVMINION.gMinerCollectibleValue3 == nil) then
		Settings.FFXIVMINION.gMinerCollectibleValue3 = 0
	end
	if (Settings.FFXIVMINION.gBotanistCollectibleName == nil) then
		Settings.FFXIVMINION.gBotanistCollectibleName = ""
	end
	if (Settings.FFXIVMINION.gBotanistCollectibleValue == nil) then
		Settings.FFXIVMINION.gBotanistCollectibleValue = 0
	end
	if (Settings.FFXIVMINION.gBotanistCollectibleName2 == nil) then
		Settings.FFXIVMINION.gBotanistCollectibleName2 = ""
	end
	if (Settings.FFXIVMINION.gBotanistCollectibleValue2 == nil) then
		Settings.FFXIVMINION.gBotanistCollectibleValue2 = 0
	end
	if (Settings.FFXIVMINION.gBotanistCollectibleName3 == nil) then
		Settings.FFXIVMINION.gBotanistCollectibleName3 = ""
	end
	if (Settings.FFXIVMINION.gBotanistCollectibleValue3 == nil) then
		Settings.FFXIVMINION.gBotanistCollectibleValue3 = 0
	end
	if (Settings.FFXIVMINION.gLastGathered == nil) then
		Settings.FFXIVMINION.gLastGathered = {}
	end
	
	if (Settings.FFXIVMINION.gGatherDebug == nil) then
		Settings.FFXIVMINION.gGatherDebug = "0"
	end
	if (Settings.FFXIVMINION.gGatherDebugLevel == nil) then
		Settings.FFXIVMINION.gGatherDebugLevel = "1"
	end	
	
	local winName = GetString("gatherMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	GUI_NewButton(winName, GetString("markerManager"), "ToggleMarkerMgr")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"")
	GUI_NewComboBox(winName,GetString("profile"),"gProfile",group,"None")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,GetString("navmesh") ,"gmeshname",group, ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
	GUI_NewField(winName,GetString("markerName"),"gStatusMarkerName",group )
	GUI_NewField(winName,GetString("markerTime"),"gStatusMarkerTime",group )
	GUI_NewField(winName,"Current Task","gStatusTaskName",group )
	GUI_NewCheckbox(winName,"Gather Debug","gGatherDebug",group)
	GUI_NewComboBox(winName,"Debug Level","gGatherDebugLevel",group,"1,2,3")
	
	group = GetString("settings")
	GUI_NewCheckbox(winName,GetString("useCordials"), "gGatherUseCordials",group)
	
	group = "Collectible"
	local collectStringMiner = AceLib.API.Items.BuildUIString(48,115)
	local collectStringBotanist = AceLib.API.Items.BuildUIString(45,115)
	GUI_NewComboBox(winName,"Mining","gMinerCollectibleName",group,collectStringMiner)
	GUI_NewField(winName,"Min Value","gMinerCollectibleValue",group)
	GUI_NewComboBox(winName,"Mining","gMinerCollectibleName2",group,collectStringMiner)
	GUI_NewField(winName,"Min Value","gMinerCollectibleValue2",group)
	GUI_NewComboBox(winName,"Mining","gMinerCollectibleName3",group,collectStringMiner)
	GUI_NewField(winName,"Min Value","gMinerCollectibleValue3",group)
	GUI_NewComboBox(winName,"Botany","gBotanistCollectibleName",group,collectStringBotanist)
	GUI_NewField(winName,"Min Value","gBotanistCollectibleValue",group)
	GUI_NewComboBox(winName,"Botany","gBotanistCollectibleName2",group,collectStringBotanist)
	GUI_NewField(winName,"Min Value","gBotanistCollectibleValue2",group)
	GUI_NewComboBox(winName,"Botany","gBotanistCollectibleName3",group,collectStringBotanist)
	GUI_NewField(winName,"Min Value","gBotanistCollectibleValue3",group)
	
	GUI_UnFoldGroup(winName,GetString("status"))
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gGatherUseCordials = Settings.FFXIVMINION.gGatherUseCordials
	gMinerCollectibleName = Settings.FFXIVMINION.gMinerCollectibleName
	gMinerCollectibleValue = Settings.FFXIVMINION.gMinerCollectibleValue
	gMinerCollectibleName2 = Settings.FFXIVMINION.gMinerCollectibleName2
	gMinerCollectibleValue2 = Settings.FFXIVMINION.gMinerCollectibleValue2
	gMinerCollectibleName3 = Settings.FFXIVMINION.gMinerCollectibleName3
	gMinerCollectibleValue3 = Settings.FFXIVMINION.gMinerCollectibleValue3
	gBotanistCollectibleName = Settings.FFXIVMINION.gBotanistCollectibleName
	gBotanistCollectibleValue = Settings.FFXIVMINION.gBotanistCollectibleValue
	gBotanistCollectibleName2 = Settings.FFXIVMINION.gBotanistCollectibleName2
	gBotanistCollectibleValue2 = Settings.FFXIVMINION.gBotanistCollectibleValue2
	gBotanistCollectibleName3 = Settings.FFXIVMINION.gBotanistCollectibleName3
	gBotanistCollectibleValue3 = Settings.FFXIVMINION.gBotanistCollectibleValue3
	gGatherDebug = Settings.FFXIVMINION.gGatherDebug
	gGatherDebugLevel = Settings.FFXIVMINION.gGatherDebugLevel
	
    ffxiv_gather.SetupMarkers()
end
function ffxiv_gather.UpdateProfiles()
    local profiles = GetString("none")
    local found = GetString("none")	
    local profilelist = dirlist(ffxiv_gather.editwindow,".*lua")
    if ( TableSize(profilelist) > 0) then
		for i,profile in pairs(profilelist) do			
            profile = string.gsub(profile, ".lua", "")
            profiles = profiles..","..profile
            if ( Settings.FFXIVMINION.gLastGatherProfile ~= nil and Settings.FFXIVMINION.gLastGatherProfile == profile ) then
                found = profile
            end
        end		
    end
	
    gProfile_listitems = profiles
    gProfile = found
	ffxiv_gather.LoadProfile(gProfile)
end
function ffxiv_gather.LoadProfile(strName)
	if (strName ~= GetString("none")) then
		if (FileExists(ffxiv_gather.editwindow..strName..".lua")) then
			ffxiv_gather.profileData,e = persistence.load(ffxiv_gather.editwindow..strName..".lua")
			if (ValidTable(ffxiv_gather.profileData)) then
				gd("Gathering profile ["..strName.."] loaded successfully.")
			else
				if (e) then
					gd("Encountered error loading gathering profile ["..e.."].")
				end
			end
		end
	else
		ffxiv_gather.profileData = {}
	end
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
	local action = ActionList:Get(actionid)
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
	local action = ActionList:Get(actionid)
	if (action and not action.isoncd) then
		action:Cast()
	end
end

function ffxiv_gather.SetupMarkers()
    -- add marker templates for gathering
    local botanyMarker = ml_marker:Create("botanyTemplate")
	botanyMarker:SetType(GetString("botanyMarker"))
	botanyMarker:ClearFields()
	botanyMarker:AddField("int", GetUSString("minContentLevel"), GetString("minContentLevel"), 0)
	botanyMarker:AddField("int", GetUSString("maxContentLevel"), GetString("maxContentLevel"), 0)
	botanyMarker:AddField("int", GetUSString("maxRadius"), GetString("maxRadius"), 0)
	botanyMarker:AddField("string", GetUSString("selectItem1"), GetString("selectItem1"), "")
	botanyMarker:AddField("string", GetUSString("selectItem2"), GetString("selectItem2"), "")
	botanyMarker:AddField("string", GetUSString("selectItem3"), GetString("selectItem3"), "")
	botanyMarker:AddField("string", GetUSString("contentIDEquals"), GetString("contentIDEquals"), "")
	botanyMarker:AddField("button", GetUSString("whitelistTarget"), GetString("whitelistTarget"), "")
	botanyMarker:AddField("string", GetUSString("NOTcontentIDEquals"), GetString("NOTcontentIDEquals"), "")
	botanyMarker:AddField("combobox", GetUSString("gatherMaps"), GetString("gatherMaps"), "Any", "Any,Peisteskin Only,None")
	botanyMarker:AddField("checkbox", GetUSString("gatherGardening"), GetString("gatherGardening"), "1")
	botanyMarker:AddField("checkbox", GetUSString("gatherChocoFood"), GetString("gatherChocoFood"), "1")
	botanyMarker:AddField("checkbox", "Rare Items", "Rare Items", "1")
	botanyMarker:AddField("checkbox", "Special Rare Items", "Special Rare Items", "1")
	botanyMarker:AddField("int", GetUSString("favor"), GetString("favor"), 0)
	botanyMarker:AddField("checkbox", GetUSString("useStealth"), GetString("useStealth"), "1")
	botanyMarker:AddField("checkbox", GetUSString("dangerousArea"), GetString("dangerousArea"), "0")
	botanyMarker:AddField("combobox", GetUSString("skillProfile"), GetString("skillProfile"), "None", ffxivminion.Strings.SKMProfiles())
    botanyMarker:SetTime(300)
    botanyMarker:SetMinLevel(1)
    botanyMarker:SetMaxLevel(60)
    ml_marker_mgr.AddMarkerTemplate(botanyMarker)
	
	local miningMarker = ml_marker:Create("miningTemplate")
	miningMarker:SetType(GetString("miningMarker"))
	miningMarker:ClearFields()
	miningMarker:AddField("int", GetUSString("minContentLevel"), GetString("minContentLevel"), 0)
	miningMarker:AddField("int", GetUSString("maxContentLevel"), GetString("maxContentLevel"), 0)
	miningMarker:AddField("int", GetUSString("maxRadius"), GetString("maxRadius"), 0)
	miningMarker:AddField("string", GetUSString("selectItem1"), GetString("selectItem1"), "")
	miningMarker:AddField("string", GetUSString("selectItem2"), GetString("selectItem2"), "")
	miningMarker:AddField("string", GetUSString("selectItem3"), GetString("selectItem3"), "")
	miningMarker:AddField("string", GetUSString("contentIDEquals"), GetString("contentIDEquals"), "")
	miningMarker:AddField("button", GetUSString("whitelistTarget"), GetString("whitelistTarget"), "")
	miningMarker:AddField("string", GetUSString("NOTcontentIDEquals"), GetString("NOTcontentIDEquals"), "")
	miningMarker:AddField("combobox", GetUSString("gatherMaps"), GetString("gatherMaps"), "Any", "Any,Peisteskin Only,None")
	miningMarker:AddField("checkbox", GetUSString("gatherGardening"), GetString("gatherGardening"), "1")
	miningMarker:AddField("checkbox", GetUSString("gatherChocoFood"), GetString("gatherChocoFood"), "1")
	miningMarker:AddField("checkbox", "Rare Items", "Rare Items", "1")
	miningMarker:AddField("checkbox", "Special Rare Items", "Special Rare Items", "1")
	miningMarker:AddField("int", GetUSString("favor"), GetString("favor"), 0)
	miningMarker:AddField("checkbox", GetUSString("useStealth"), GetString("useStealth"), "1")
	miningMarker:AddField("checkbox", GetUSString("dangerousArea"), GetString("dangerousArea"), "0")
	miningMarker:AddField("combobox", GetUSString("skillProfile"), GetString("skillProfile"), "None", ffxivminion.Strings.SKMProfiles())
    miningMarker:SetTime(300)
    miningMarker:SetMinLevel(1)
    miningMarker:SetMaxLevel(60)
    ml_marker_mgr.AddMarkerTemplate(miningMarker)
	
	local unspoiledMarker = ml_marker:Create("unspoiledTemplate")
	unspoiledMarker:SetType(GetString("unspoiledMarker"))
	unspoiledMarker:ClearFields()
	unspoiledMarker:AddField("int", GetUSString("minContentLevel"), GetString("minContentLevel"), 0)
	unspoiledMarker:AddField("int", GetUSString("maxContentLevel"), GetString("maxContentLevel"), 0)
	unspoiledMarker:AddField("int", GetUSString("maxRadius"), GetString("maxRadius"), 300)
	unspoiledMarker:AddField("string", GetUSString("minimumGP"), GetString("minimumGP"), "0")
	unspoiledMarker:AddField("string", GetUSString("selectItem1"), GetString("selectItem1"), "")
	unspoiledMarker:AddField("string", GetUSString("selectItem2"), GetString("selectItem2"), "")
	unspoiledMarker:AddField("string", GetUSString("selectItem3"), GetString("selectItem3"), "")
	unspoiledMarker:AddField("combobox", GetUSString("gatherMaps"), GetString("gatherMaps"), "Any", "Any,Peisteskin Only,None")
	unspoiledMarker:AddField("checkbox", GetUSString("gatherGardening"), GetString("gatherGardening"), "1")
	unspoiledMarker:AddField("checkbox", GetUSString("gatherChocoFood"), GetString("gatherChocoFood"), "1")
	unspoiledMarker:AddField("checkbox", "Rare Items", "Rare Items", "1")
	unspoiledMarker:AddField("checkbox", "Special Rare Items", "Special Rare Items", "1")
	unspoiledMarker:AddField("int", GetUSString("favor"), GetString("favor"), 0)
	unspoiledMarker:AddField("checkbox", GetUSString("useStealth"), GetString("useStealth"), "1")
	unspoiledMarker:AddField("checkbox", GetUSString("dangerousArea"), GetString("dangerousArea"), "0")
	unspoiledMarker:AddField("combobox", GetUSString("skillProfile"), GetString("skillProfile"), "None", ffxivminion.Strings.SKMProfiles())
    unspoiledMarker:SetTime(1800)
    unspoiledMarker:SetMinLevel(50)
    unspoiledMarker:SetMaxLevel(60)
    ml_marker_mgr.AddMarkerTemplate(unspoiledMarker)
	
    -- refresh the manager with the new templates
    ml_marker_mgr.RefreshMarkerTypes()
	ml_marker_mgr.RefreshMarkerNames()
end

function ffxiv_gather.GetUnspoiledMarkers(mapid)
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

--d(ffxiv_gather.GetLastGather("Example",1))
--d(ffxiv_gather.SetLastGather("Example",1))
--d(TimePassed(GetCurrentTime(),1400000))

function ffxiv_gather.GetLastGather(profile,task)
	if (Settings.FFXIVMINION.gLastGather ~= nil) then
		lastGather = Settings.FFXIVMINION.gLastGather
		if (ValidTable(lastGather[profile])) then
			return lastGather[profile][task] or 0
		end
	end
	
	return 0
end

function ffxiv_gather.SetLastGather(profile,taskid)
	if (Settings.FFXIVMINION.gLastGather == nil or type(Settings.FFXIVMINION.gLastGather) ~= "table") then
		Settings.FFXIVMINION.gLastGather = {}
	end
	
	local lastGather = Settings.FFXIVMINION.gLastGather
	if (lastGather[profile] == nil or type(lastGather[profile]) ~= "table") then
		lastGather[profile] = {}
	end
	
	lastGather[profile][taskid] = GetCurrentTime()
	
	local tasks  = ffxiv_gather.profileData.tasks
	if (ValidTable(tasks)) then
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

RegisterEventHandler("GUI.Update",ffxiv_gather.GUIVarUpdate)
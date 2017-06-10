ffxiv_grind = {}
ffxiv_grind.lastTick = 0
ffxiv_grind.timer = 0
ffxiv_grind.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\GrindProfiles\]]
ffxiv_grind.profiles = {}
ffxiv_grind.profilesDisplay = {}
ffxiv_grind.profileData = {}
ffxiv_grind.currentTask = {}
ffxiv_grind.currentTaskIndex = 0

ffxiv_task_grind = inheritsFrom(ml_task)
ffxiv_task_grind.addon_process_elements = {}
ffxiv_task_grind.addon_overwatch_elements = {}
ffxiv_task_grind.name = "LT_GRIND"
ffxiv_task_grind.inFate = false
ffxiv_task_grind.ticks = 0
ffxiv_task_grind.blTicks = 0
gFateID = 0

ffxiv_task_grind.atmas = {
	["Maiden"] = { name = "Maiden", 			hour = 1,	tele = 3, 	map = 148, item = 7851, mesh = "Central Shroud"},
	["Scorpion"] = { name = "Scorpion", 		hour = 2,	tele = 20, 	map = 146, item = 7852, mesh = "Southern Thanalan"},
	["Waterbearer"] = { name = "Waterbearer",	hour = 3, 	tele = 15, 	map = 139, item = 7853, mesh = "Upper La Noscea - Merged"},
	["Goat"] = { name = "Goat", 				hour = 4, 	tele = 4, 	map = 152, item = 7854, mesh = "East Shroud"},
	["Bull"] = { name = "Bull", 				hour = 5, 	tele = 18, 	map = 145, item = 7855, mesh = "Eastern Thanalan"},
	["Ram"] = { name = "Ram", 					hour = 6, 	tele = 52, 	map = 134, item = 7856, mesh = "Middle La Noscea"},
	["Twins"] = { name = "Twins", 				hour = 7, 	tele = 17, 	map = 140, item = 7857, mesh = "Western Thanalan"},
	["Lion"] = { name = "Lion", 				hour = 8, 	tele = 16, 	map = 180, item = 7858, mesh = "Outer La Noscea"},
	["Fish"] = { name = "Fish", 				hour = 9, 	tele = 10, 	map = 135, item = 7859, mesh = "Lower La Noscea"},
	["Archer"] = { name = "Archer", 			hour = 10, 	tele = 7, 	map = 154, item = 7860, mesh = "North Shroud"},
	["Scales"] = { name = "Scales", 			hour = 11, 	tele = 53, 	map = 141, item = 7861, mesh = "Central Thanalan"},
	["Crab"] = { name = "Crab", 				hour = 12, 	tele = 14, 	map = 138, item = 7862, mesh = "Western La Noscea"},
}

ffxiv_task_grind.luminous = {
	["Ice"] = 		{ name = "Ice", 		map = 397, item = 13569 },
	["Earth"] = 	{ name = "Earth", 		map = 398, item = 13572 },
	["Water"] = 	{ name = "Water", 		map = 399, item = 13574 },
	["Lightning"] = { name = "Lightning", 	map = 400, item = 13573 },
	["Fire"] = 		{ name = "Fire",		map = 402, item = 13571 },
	["Wind"] = 		{ name = "Wind", 		map = 401, item = 13570 },
}

function ffxiv_task_grind.Create()
    local newinst = inheritsFrom(ffxiv_task_grind)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_grind members
    newinst.name = "LT_GRIND"
    newinst.targetid = 0
    newinst.markerTime = 0
    newinst.currentMarker = false
	newinst.filterLevel = true
	newinst.correctMap = nil
	newinst.correctMapFunction = nil -- Use this to trigger an always updating map.
	
	if (gGrindAutoLevel and gBotMode == GetString("grindMode")) then
		newinst.correctMapFunction = "GetBestGrindMap"
	end
	
	newinst.suppressRestTimer = 0
	ffxiv_task_grind.inFate = false
	ml_marker_mgr.currentMarker = nil
    
    --this is the targeting function that will be used for the generic KillTarget task
    newinst.targetFunction = GetNearestGrindAttackable
	newinst.killFunction = ffxiv_task_grindCombat

    return newinst
end

c_nextgrindmarker = inheritsFrom( ml_cause )
e_nextgrindmarker = inheritsFrom( ml_effect )
function c_nextgrindmarker:evaluate()

	if (table.valid(ffxiv_grind.profileData)) then
		return false
	end

    if ((gBotMode == GetString("partyMode") and not IsPartyLeader()) or
		(gGrindDoFates and gGrindFatesOnly))
	then
        return false
    end
	
	local filter = "mapid="..tostring(Player.localmapid)
	if (gMarkerMgrMode ~= GetString("singleMarker")) then
		filter = filter..",minlevel<="..tostring(Player.level)..",maxlevel>="..tostring(Player.level)
	end
	
	local currentMarker = ml_marker_mgr.currentMarker
	local marker = nil
	
	if (currentMarker == nil) then
		marker = ml_marker_mgr.GetNextMarker("Grind",filter)
	else
		-- next check to see if our level is out of range
		if (marker == nil) then
			if (not gMarkerMgrMode == GetString("singleMarker")) and (Player.level < currentMarker.minlevel or Player.level > currentMarker.maxlevel) then
				marker = ml_marker_mgr.GetNextMarker("Grind", filter)
			end
		end
		
		-- last check if our time has run out
		if (marker == nil) then
			if (currentMarker.duration > 0) then
				if (currentMarker:GetTimeRemaining() <= 0) then
					ml_debug("Getting Next Marker, TIME IS UP!")
					marker = ml_marker_mgr.GetNextMarker("Grind", filter)
				else
					return false
				end
			end
		end
	end
	
	if (marker ~= nil) then
		e_nextgrindmarker.marker = marker
		return true
	end
    
    return false
end
function e_nextgrindmarker:execute()
	ml_marker_mgr.currentMarker = e_nextgrindmarker.marker
	ml_marker_mgr.currentMarker:StartTimer()
    ml_global_information.MarkerMinLevel = ml_marker_mgr.currentMarker.minlevel
    ml_global_information.MarkerMaxLevel = ml_marker_mgr.currentMarker.maxlevel
	ml_global_information.BlacklistContentID = ml_marker_mgr.currentMarker.blacklist
    ml_global_information.WhitelistContentID = ml_marker_mgr.currentMarker.whitelist
	gStatusMarkerName = ml_marker_mgr.currentMarker.name
end

c_nextgrindarea = inheritsFrom( ml_cause )
e_nextgrindarea = inheritsFrom( ml_effect )
function c_nextgrindarea:evaluate()	
	if ((MIsLocked() and not IsFlying()) or not Player.alive or Player.incombat or ffxiv_task_grind.inFate or MIsLoading() or ml_task_hub:ThisTask().doingHuntlog) then
		return false
	end
	
	if (FFXIV_Common_BotRunning and gBotMode == GetString("grindMode")) then
		if (gGrindAutoLevel) then
			if (ml_task_hub:ThisTask().correctMapFunction == nil) then
				ml_task_hub:ThisTask().correctMapFunction = "GetBestGrindMap"
			end
		else
			if (ml_task_hub:ThisTask().correctMapFunction ~= nil) then
				ml_task_hub:ThisTask().correctMapFunction = nil
			end
		end
	end
	
	local autoMapFunction = ml_task_hub:ThisTask().correctMapFunction
	if (autoMapFunction and type(autoMapFunction) == "function") then
		local correctMap = autoMapFunction()
		if (correctMap and type(correctMap) == "number" and correctMap ~= Player.localmapid and CanAccessMap(correctMap)) then			
			ml_task_hub:ThisTask().correctMap = correctMap
			return true
		end
	elseif (autoMapFunction and type(autoMapFunction) == "string") then
		local correctMapFunction = findfunction(autoMapFunction)
		if (correctMapFunction and type(correctMapFunction) == "function") then
			local correctMap = correctMapFunction()
			if (correctMap and type(correctMap) == "number" and correctMap ~= Player.localmapid and CanAccessMap(correctMap)) then			
				ml_task_hub:ThisTask().correctMap = correctMap
				return true
			end
		end
	elseif (ml_task_hub:ThisTask().correctMap and (ml_task_hub:ThisTask().correctMap ~= Player.localmapid)) then
		local mapID = ml_task_hub:ThisTask().correctMap
		if (CanAccessMap(mapID)) then
			e_returntomap.mapID = mapID
			return true
		end
	end
	
	return false
end
function e_nextgrindarea:execute()
	if (Player:IsMoving()) then
		Player:Stop()
		ml_global_information.Await(1500, function () return not Player:IsMoving() end)
	end
	
	d("next grind area, current task is :"..tostring(ml_task_hub:CurrentTask().name))
	
	local task = ffxiv_task_movetomap.Create()
	task.destMapID = ml_task_hub:ThisTask().correctMap
	ml_task_hub:Add(task, REACTIVE_GOAL, TP_IMMEDIATE)
end

c_grindisloading = inheritsFrom( ml_cause )
e_grindisloading = inheritsFrom( ml_effect )
function c_grindisloading:evaluate()
	local navmeshstate = NavigationManager:GetNavMeshState()
	return MIsLoading() or In(navmeshstate,GLOBAL.MESHSTATE.MESHLOADING,GLOBAL.MESHSTATE.MESHSAVING,GLOBAL.MESHSTATE.MESHBUILDING)
end
function e_grindisloading:execute()
	ml_debug("Character is loading, prevent other actions and idle.")
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_grindislocked = inheritsFrom( ml_cause )
e_grindislocked = inheritsFrom( ml_effect )
function c_grindislocked:evaluate()
	return MIsLocked() and not IsFlying()
end
function e_grindislocked:execute()
	ml_debug("Character is loading, prevent other actions and idle.")
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_grindnexttask = inheritsFrom( ml_cause )
e_grindnexttask = inheritsFrom( ml_effect )
c_grindnexttask.postpone = 0
c_grindnexttask.blockOnly = false
c_grindnexttask.subset = {}
c_grindnexttask.subsetExpiration = 0
function c_grindnexttask:evaluate()
	if (not Player.alive or not table.valid(ffxiv_grind.profileData)) then
		return false
	end
	
	c_grindnexttask.blockOnly = false
	
	local evaluate = false
	local invalid = false
	local tempinvalid = false
	
	local currentTask = ffxiv_grind.currentTask
	local currentTaskIndex = ffxiv_grind.currentTaskIndex
	
	if (not table.valid(currentTask)) then
		d("no current task, pick something")
		gd("[GrindNextTask]: We have no current task, so set the invalid flag.",3)
		invalid = true
	else
		gd("[GrindNextTask]: We have a current task, check if it should be completed.",3)
		if (IsNull(currentTask.interruptable,false) or IsNull(currentTask.lowpriority,false)) then
			gd("[GrindNextTask]: Task is interruptable, set the flag.",3)
			evaluate = true
		elseif not (currentTask.weatherlast or currentTask.weathernow or currentTask.weathernext or currentTask.highpriority or
				 currentTask.eorzeaminhour or currentTask.eorzeamaxhour or currentTask.normalpriority)
		then
			gd("[GrindNextTask]: Task is interruptable, set the flag.",3)
			evaluate = true
		end
		
		if (not invalid) then
			if (currentTask.minlevel and Player.level < currentTask.minlevel) then
				gd("[GrindNextTask]: Level is too low for the task, invalidate.",3)
				invalid = true
			elseif (currentTask.maxlevel and Player.level > currentTask.maxlevel) then
				gd("[GrindNextTask]: Level is too high for the task, invalidate.",3)
				invalid = true
			end
		end
		
		if (not invalid) then
			local profileName = (gBotMode == GetString("questMode") and gQuestProfile) or gGrindProfile
			local lastGrind = ffxiv_grind.GetLastGrind(profileName,currentTaskIndex)
			if (lastGrind ~= 0) then
				if (TimePassed(GetCurrentTime(), lastGrind) < 1400) then
					gd("[GrindNextTask]: Our last grind was only ["..tostring(TimePassed(GetCurrentTime(), lastGrind)).."] seconds ago, invalidate.",3)
					invalid = true
				end
			end
		end
			
		if (not invalid) then
			if (IsNull(currentTask.maxtime,0) > 0) then
				if (currentTask.taskStarted > 0 and TimeSince(currentTask.taskStarted) > currentTask.maxtime) then
					gd("[GrindNextTask]: Task has been ongoing for too long, invalidate.",3)
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
					gd("[GrindNextTask]: Task has been idle too long, invalidate.",3)
				else
					if (currentTask.taskFailed ~= 0) then
						gd("Max time allowed ["..tostring(currentTask.timeout).."], time passed ["..tostring(TimeSince(currentTask.taskFailed)).."].",3)
					end
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
					gd("[GrindNextTask]: Complete condition has been satisfied, invalidate.",3)
					break
				end
			end
		end
	end
	
	if (invalid and not tempinvalid) then
		gd("[GrindNextTask]: Remove this index from the cached subset.",3)
		c_grindnexttask.subset[currentTaskIndex] = nil
	end

	if (evaluate or invalid) then
		local profileData = ffxiv_grind.profileData
		if (table.valid(profileData.tasks)) then
			
			local validTasks = {}
			if (Now() < c_grindnexttask.subsetExpiration) then
				gd("[GrindNextTask]: Check the cached subset of tasks.",3)
				validTasks = c_grindnexttask.subset
			else
				gd("[GrindNextTask]: Check the non-cached subset of tasks.",3)
				validTasks = deepcopy(profileData.tasks,true)
				for i,data in pairs(validTasks) do
				
					local valid = true

					if (data.enabled and data.enabled ~="1") then
						valid = false
						gd("Task ["..tostring(i).."] not enabled.",3)
					end

					if (data.minlevel and Player.level < data.minlevel) then
						valid = false
						gd("Task ["..tostring(i).."] not valid due to min level requirement.",3)
					elseif (data.maxlevel and Player.level > data.maxlevel) then
						valid = false
						gd("Task ["..tostring(i).."] not valid due to max level requirement.",3)
					end
					
					if (valid) then
						local profileName = (gBotMode == GetString("questMode") and gQuestProfile) or gGrindProfile
						local lastGrind = ffxiv_grind.GetLastGrind(profileName,i)
						if (lastGrind ~= 0) then
							if (TimePassed(GetCurrentTime(), lastGrind) < 1400) then
								valid = false
								gd("Task ["..tostring(i).."] not valid due to last grind.",3)
							end
						end
					end
					
					if (valid) then
						if (data.condition) then
							local conditions = deepcopy(data.condition,true)
							valid = TestConditions(conditions)
							gd("Task ["..tostring(i).."] not valid due to conditions.",3)
						end
					end
				
					if (not valid) then
						gd("Removing task ["..tostring(i).."] from valid tasks.",3)
						validTasks[i] = nil
					end
				end
				
				c_grindnexttask.subset = validTasks
				local eTime = AceLib.API.Weather.GetDateTime() 
				local eMinute = eTime.minute
				local quarters = { [5] = true, [10] = true, [15] = true, [20] = true, [25] = true, [30] = true, [35] = true, [40] = true, [45] = true, [50] = true, [55] = true, [60] = true }
				local expirationDelay = 0
				for quarter,_ in pairs(quarters) do
					local diff = (quarter - eMinute)
					if (diff <= 5 and diff > 0) then
						expirationDelay = (diff * 2.92) * 1000
						d("[Grind]: Setting expiration delay of ["..tostring(expirationDelay).."] ms")
						break
					end	
				end
				d("Buffering task evaluation by ["..tostring(expirationDelay / 1000).."] seconds.")
				c_grindnexttask.subsetExpiration = Now() + expirationDelay
			end
			
			if (table.valid(validTasks)) then
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
					else
						gd("Added task at ["..tostring(i).."] to the low priority queue.")
						lowPriority[i] = data
					end
				end
				
				local lowestIndex = 9999
				local best = nil
				
				-- High priority section.
				
				gd("[GrindNextTask]: Check the high priority tasks for differently grouped tasks.",3)
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
						gd("[GrindNextTask]: Check the high priority tasks for grouped tasks.",3)
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
						gd("[GrindNextTask]: Check the normal priority tasks for higher ranked, differently grouped tasks.",3)
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
							gd("[GrindNextTask]: Check the normal priority tasks for matching grouped tasks.",3)
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
									gd("[GrindNextTask]: Check the normal priority tasks for differently grouped tasks.",3)
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
					gd("[GrindNextTask]: Check the low priority section since haven't found anything yet.",3)
					if (IsNull(currentTask.set,"") ~= "") then
						gd("[GrindNextTask]: Check for the next task in this set.",3)
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
							gd("[GrindNextTask]: Loop back around to check previous tasks in this set.",3)
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
						gd("[GrindNextTask]: Check for the next task available for low priority.",3)
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
							gd("[GrindNextTask]: Still don't have anything, check previous low priority section tasks.",3)
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
					if (ffxiv_grind.currentTaskIndex ~= lowestIndex) then
						ffxiv_grind.currentTaskIndex = lowestIndex
						ffxiv_grind.currentTask = best
						return true
					else
						gd("[GrindNextTask]: Found a task, but it is the current task, so do nothing.",3)
					end
				end
			else
				gd("[GrindNextTask]: No valid tasks were found.",3)
			end
		end
	end
					
	return false
end
function e_grindnexttask:execute()
	if (c_grindnexttask.blockOnly) then
		return
	end
	
	if (Player:IsMoving()) then
		Player:Stop()
	end
	
	local taskName = ffxiv_grind.currentTask.name or ffxiv_grind.currentTaskIndex
	gStatusTaskName = taskName
	
	if (gBotMode == GetString("questMode")) then
		gQuestStepType = "grind - ["..tostring(taskName).."]"
	end
	
	ml_marker_mgr.currentMarker = nil
	gStatusMarkerName = ""
	
    ml_global_information.BlacklistContentID = ffxiv_grind.currentTask.blacklist
    ml_global_information.WhitelistContentID = ffxiv_grind.currentTask.whitelist
	
	ml_task_hub:CurrentTask().targetid = 0
	ml_global_information.targetid = 0
	ml_task_hub:CurrentTask().failedSearches = 0
	ffxiv_grind.currentTask.taskStarted = 0
	ffxiv_grind.currentTask.taskFailed = 0
	ml_global_information.lastInventorySnapshot = GetInventorySnapshot()
end

function ffxiv_task_grind:Init()
    --init ProcessOverWatch() elements
	local ke_isLoading = ml_element:create( "GrindIsLoading", c_grindisloading, e_grindisloading, 250 )
    self:add( ke_isLoading, self.overwatch_elements)
	
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 200 )
    self:add(ke_dead, self.overwatch_elements)
	
	local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 150 )
    self:add(ke_flee, self.overwatch_elements)
	
	local ke_isLocked = ml_element:create( "IsLocked", c_grindislocked, e_grindislocked, 180 )
    self:add( ke_isLocked, self.process_elements)

	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 150 )
    self:add( ke_inventoryFull, self.process_elements)
    
	--local ke_autoEquip = ml_element:create( "AutoEquip", c_autoequip, e_autoequip, 130 )
    --self:add( ke_autoEquip, self.process_elements)
	
	local ke_recommendEquip = ml_element:create( "RecommendEquip", c_recommendequip, e_recommendequip, 130 )
    self:add( ke_recommendEquip, self.process_elements)
	
	local ke_eat = ml_element:create( "Eat", c_eat, e_eat, 120 )
    self:add( ke_eat, self.process_elements)
	
	local ke_nextTask = ml_element:create( "NextTask", c_grindnexttask, e_grindnexttask, 90 )
    self:add( ke_nextTask, self.process_elements)
	
	local ke_addHuntlog = ml_element:create( "AddHuntlog", c_grind_addhuntlogtask, e_grind_addhuntlogtask, 80 )
    self:add(ke_addHuntlog, self.process_elements)
	
	local ke_luminous = ml_element:create( "NextArea", c_nextgrindarea, e_nextgrindarea, 75 )
    self:add(ke_luminous, self.process_elements)
	
	local ke_luminous = ml_element:create( "NextLuminous", c_nextluminous, e_nextluminous, 70 )
    self:add(ke_luminous, self.process_elements)
	
	local ke_atma = ml_element:create( "NextAtma", c_nextatma, e_nextatma, 65 )
    self:add(ke_atma, self.process_elements)
	
	local ke_addFate = ml_element:create( "AddFate", c_add_fate, e_add_fate, 60 )
    self:add(ke_addFate, self.process_elements)
    
    local ke_nextMarker = ml_element:create( "NextMarker", c_nextgrindmarker, e_nextgrindmarker, 50 )
    self:add(ke_nextMarker, self.process_elements)
	
	local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 25 )
    self:add(ke_returnToMarker, self.process_elements)
	
	local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 18 )
    self:add(ke_rest, self.process_elements)
	
    local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_killtarget, e_add_killtarget, 15 )
    self:add(ke_addKillTarget, self.process_elements)
	
    local ke_fateWait = ml_element:create( "FateWait", c_fatewait, e_fatewait, 10 )
    self:add(ke_fateWait, self.process_elements)
	
	self:InitAddon()
	self:InitExtras()
    self:AddTaskCheckCEs()
end

function ffxiv_task_grind:InitAddon()
	--Nothing here, just for extras.
end

function ffxiv_task_grind:InitExtras()
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

function ffxiv_task_grind:Process()
	if (IsLoading()) then
		return false
	end
	
	if (TableSize(ml_task_hub:CurrentTask().process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(ml_task_hub:CurrentTask().process_elements)
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end

function ffxiv_task_grind.SetModeOptions()
	ffxiv_grind.profileData = {}
	if (table.valid(ffxiv_grind.profiles)) then
		ffxiv_grind.profileData = ffxiv_grind.profiles[gGrindProfile]
	end
	gTeleportHack = Settings.FFXIVMINION.gTeleportHack
	gTeleportHackParanoid = Settings.FFXIVMINION.gTeleportHackParanoid
	gGrindDoHuntlog = Settings.FFXIVMINION.gGrindDoHuntlog
	gGrindDoFates = Settings.FFXIVMINION.gGrindDoFates
	gGrindFatesOnly = Settings.FFXIVMINION.gGrindFatesOnly
	gGrindFatesMinLevel = Settings.FFXIVMINION.gGrindFatesMinLevel
	gGrindFatesMaxLevel = Settings.FFXIVMINION.gGrindFatesMaxLevel
	gGrindDoBattleFates = Settings.FFXIVMINION.gGrindDoBattleFates
	gGrindDoBossFates = Settings.FFXIVMINION.gGrindDoBossFates
	gGrindDoGrindFates = Settings.FFXIVMINION.gGrindDoGrindFates
	gGrindDoDefenseFates = Settings.FFXIVMINION.gGrindDoDefenseFates
	gGrindDoEscortFates = Settings.FFXIVMINION.gGrindDoEscortFates
	gFateGrindWaitPercent = Settings.FFXIVMINION.gFateGrindWaitPercent
	gFateBossWaitPercent = Settings.FFXIVMINION.gFateBossWaitPercent
	gFateDefenseWaitPercent = Settings.FFXIVMINION.gFateDefenseWaitPercent
	gSkipCutscene = Settings.FFXIVMINION.gSkipCutscene
	gSkipTalk = Settings.FFXIVMINION.gSkipTalk
	gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
	Hacks:SkipCutscene(gSkipCutscene)
	Hacks:Disable3DRendering(gDisableDrawing)
	gAvoidAOE = true
	gAutoEquip = Settings.FFXIVMINION.gAutoEquip
end

function ffxiv_task_grind:UIInit()
	ffxiv_grind.profiles, ffxiv_grind.profilesDisplay = GetPublicProfiles(ffxiv_grind.profilePath,".*lua")
	
	local uuid = GetUUID()
	if (Settings.FFXIVMINION.gLastGrindProfiles == nil) then
		Settings.FFXIVMINION.gLastGrindProfiles = {}
	end
	if (Settings.FFXIVMINION.gLastGrindProfiles[uuid] == nil) then
		Settings.FFXIVMINION.gLastGrindProfiles[uuid] = {}
	end
	
	gGrindProfile = Settings.FFXIVMINION.gLastGrindProfiles[uuid] or ffxiv_grind.profilesDisplay[1]
	gGrindProfileIndex = GetKeyByValue(gGrindProfile,ffxiv_grind.profilesDisplay) or 1
	if (ffxiv_grind.profilesDisplay[gGrindProfileIndex] ~= gGrindProfile) then
		gGrindProfile = ffxiv_grind.profilesDisplay[gGrindProfileIndex]
	end
	ffxiv_grind.profileData = ffxiv_grind.profiles[gGrindProfile] or {}
	
	gGrindDebug = ffxivminion.GetSetting("gGrindDebug",false)
	local debugLevels = { 1, 2, 3}
	gGrindDebugLevel = ffxivminion.GetSetting("gGrindDebugLevel",1)
	gGrindDebugLevelIndex = GetKeyByValue(gGrindDebugLevel,debugLevels)
	
	gGrindDoFates = ffxivminion.GetSetting("gGrindDoFates",true)
	gGrindFatesOnly = ffxivminion.GetSetting("gGrindFatesOnly",false)
	gGrindFatesMaxLevel = ffxivminion.GetSetting("gGrindFatesMaxLevel",2)
	gGrindFatesNoMaxLevel = ffxivminion.GetSetting("gGrindFatesNoMaxLevel",false)
	gGrindFatesMinLevel = ffxivminion.GetSetting("gGrindFatesMinLevel",5)
	gGrindFatesNoMinLevel = ffxivminion.GetSetting("gGrindFatesNoMinLevel",false)
	
	gGrindAtmaMode = ffxivminion.GetSetting("gGrindAtmaMode",false)
	gGrindLuminousMode = ffxivminion.GetSetting("gGrindLuminousMode",false)
	gGrindDoHuntlog = ffxivminion.GetSetting("gGrindDoHuntlog",true)
	gGrindAutoLevel = ffxivminion.GetSetting("gGrindAutoLevel",false)
	
	gClaimFirst = ffxivminion.GetSetting("gClaimFirst",false)
	gClaimRange = ffxivminion.GetSetting("gClaimRange",20)
	gClaimed = ffxivminion.GetSetting("gClaimed",false)
	
	--gKillAggroEnemies = ffxivminion.GetSetting("gKillAggroEnemies",false) -- check if needed
	--gAlwaysKillAggro = ffxivminion.GetSetting("gAlwaysKillAggro",false) -- check if needed
	gFateKillAggro = ffxivminion.GetSetting("gFateKillAggro",true) -- check if needed
	gCombatRangePercent = ffxivminion.GetSetting("gCombatRangePercent",75) -- check if needed
	gRestInFates = ffxivminion.GetSetting("gRestInFates",true)
	gFateTeleportPercent = ffxivminion.GetSetting("gFateTeleportPercent",0) -- check if needed
	gFateBLTimer = ffxivminion.GetSetting("gFateBLTimer",120) -- check if needed
	
	gDoChainFates = ffxivminion.GetSetting("gDoChainFates",true)
	gGrindDoBattleFates = ffxivminion.GetSetting("gGrindDoBattleFates",true)
	gGrindDoBossFates = ffxivminion.GetSetting("gGrindDoBossFates",true)
	gGrindDoGrindFates = ffxivminion.GetSetting("gGrindDoGrindFates",true)
	gGrindDoDefenseFates = ffxivminion.GetSetting("gGrindDoDefenseFates",true)
	gGrindDoEscortFates = ffxivminion.GetSetting("gGrindDoEscortFates",true)
	
	gFateChainWaitPercent = ffxivminion.GetSetting("gFateChainWaitPercent",0)
	gFateBattleWaitPercent = ffxivminion.GetSetting("gFateBattleWaitPercent",0)
	gFateBossWaitPercent = ffxivminion.GetSetting("gFateBossWaitPercent",1)
	gFateGrindWaitPercent = ffxivminion.GetSetting("gFateGrindWaitPercent",0)
	gFateDefenseWaitPercent = ffxivminion.GetSetting("gFateDefenseWaitPercent",0)
	gFateEscortWaitPercent = ffxivminion.GetSetting("gFateEscortWaitPercent",0)
	
	gFateWaitNearEvac = ffxivminion.GetSetting("gFateWaitNearEvac",true)
	gFateRandomDelayMin = ffxivminion.GetSetting("gFateRandomDelayMin",0)
	gFateRandomDelayMax = ffxivminion.GetSetting("gFateRandomDelayMax",0)
	
	self.GUI = {}
	self.GUI.main_tabs = GUI_CreateTabs("Settings,Hunting,Tweaks",true)
	self.GUI.profile = {
		open = false,
		visible = true,
		name = "Grind - Profile Management",
		main_tabs = GUI_CreateTabs("Manage,Add,Edit",true),
	}
end

function ffxiv_task_grind:Draw()
	
	GUI_DrawTabs(self.GUI.main_tabs)
	local tabs = self.GUI.main_tabs
	
	if (tabs.tabs[1].isselected) then
		GUI:BeginChild("##header-settings",0,GUI_GetFrameHeight(13),true)
		GUI:PushItemWidth(80)	
		
		GUI_Capture(GUI:Checkbox(GetString("Auto-Level Mode"),gGrindAutoLevel),"gGrindAutoLevel")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Automatically switch maps to continue leveling in an optimal area.")
		end
		GUI:SameLine(0,10)
		if (GUI:Button("Modify Auto-Grind")) then
			ffxivminion.GUI.autogrind.open = true
			ffxivminion.GUI.autogrind.error_text = ""
		end
		
		GUI_Capture(GUI:Checkbox(GetString("doHuntingLog"),gGrindDoHuntlog),"gGrindDoHuntlog");
		GUI_Capture(GUI:Checkbox(GetString("doAtma"),gGrindAtmaMode),"gGrindAtmaMode", 
			function () 
				if (gGrindAtmaMode) then
					GUI_Set("gGrindDoFates",true) GUI_Set("gGrindFatesOnly",true) GUI_Set("gGrindLuminousMode",false) GUI_Set("gGrindFatesNoMinLevel",true) 
				end
			end
		)
		GUI_Capture(GUI:Checkbox("Do Luminous",gGrindLuminousMode),"gGrindLuminousMode", 
			function ()
				if (gGrindLuminousMode) then
					GUI_Set("gGrindDoFates",true) GUI_Set("gGrindFatesOnly",true) GUI_Set("gGrindAtmaMode",false) GUI_Set("gGrindFatesNoMinLevel",true) 
				end
			end
		);
		
		GUI_Capture(GUI:Checkbox(GetString("doFates"),gGrindDoFates),"gGrindDoFates"); GUI:SameLine(0,10)
		GUI_Capture(GUI:Checkbox(GetString("fatesOnly"),gGrindFatesOnly),"gGrindFatesOnly", 
			function () 
				if (gGrindFatesOnly) then 
					GUI_Set("gGrindDoFates",true) 
				end
			end
		);
		
		GUI_Capture(GUI:Checkbox("Kill Non-Fate Aggro",gFateKillAggro),"gFateKillAggro");
		GUI_Capture(GUI:Checkbox(GetString("restInFates"),gRestInFates),"gRestInFates");
		
		GUI_DrawIntMinMax(GetString("Min Fate Lv."),"gGrindFatesMinLevel",1,2,0,60)
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Number of levels below current Player level.")
		end
		GUI:SameLine(0,10); GUI_Capture(GUI:Checkbox("No Min",gGrindFatesNoMinLevel),"gGrindFatesNoMinLevel");
		GUI_DrawIntMinMax(GetString("Max Fate Lv."),"gGrindFatesMaxLevel",1,2,0,60)
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Number of levels above current Player level.")
		end
		GUI:SameLine(0,10); GUI_Capture(GUI:Checkbox("No Max",gGrindFatesNoMaxLevel),"gGrindFatesNoMaxLevel");
		
		GUI_DrawIntMinMax(GetString("fateTeleportPercent"),"gFateTeleportPercent",1,2,0,99)
		GUI_Capture(GUI:Checkbox(GetString("waitNearEvac"),gFateWaitNearEvac),"gFateWaitNearEvac");
		GUI_DrawIntMinMax("Min Random Delay (s)","gFateRandomDelayMin",10,20,0,120)
		GUI_DrawIntMinMax("Max Random Delay (s)","gFateRandomDelayMax",10,20,0,240)
		
		GUI:PopItemWidth()
		GUI:EndChild()
	end
	
	if (tabs.tabs[2].isselected) then
		GUI:BeginChild("##header-hunting",0,GUI_GetFrameHeight(3),true)
		GUI:PushItemWidth(100)	
		
		GUI_Capture(GUI:Checkbox(GetString("prioritizeClaims"),gClaimFirst),"gClaimFirst");
		GUI_DrawIntMinMax(GetString("claimRange"),"gClaimRange",1,5,0,50)
		GUI_Capture(GUI:Checkbox(GetString("attackClaimed"),gClaimed),"gClaimed");
		
		--GUI_DrawIntMinMax(GetString("combatRangePercent"),"gCombatRangePercent",1,5,25,100)
		
		GUI:PopItemWidth()
		GUI:EndChild()
	end
	
	if (tabs.tabs[3].isselected) then
		GUI:BeginChild("##header-tweaks",0,GUI_GetFrameHeight(12),true)
		GUI:PushItemWidth(100)	
		
		GUI_Capture(GUI:Checkbox(GetString("Chain Fates"),gDoChainFates),"gDoChainFates");
		GUI_DrawIntMinMax(GetString("Chain Fate Wait %"),"gFateChainWaitPercent",1,5,0,99)
		GUI_Capture(GUI:Checkbox(GetString("Battle Fates"),gGrindDoBattleFates),"gGrindDoBattleFates");
		GUI_DrawIntMinMax(GetString("Battle Fate Wait %"),"gFateBattleWaitPercent",1,5,0,99)
		GUI_Capture(GUI:Checkbox(GetString("Boss Fates"),gGrindDoBossFates),"gGrindDoBossFates");
		GUI_DrawIntMinMax(GetString("Boss Fate Wait %"),"gFateBossWaitPercent",1,5,0,99)
		GUI_Capture(GUI:Checkbox(GetString("Grind Fates"),gGrindDoGrindFates),"gGrindDoGrindFates");
		GUI_DrawIntMinMax(GetString("Grind Fate Wait %"),"gFateGrindWaitPercent",1,5,0,99)
		GUI_Capture(GUI:Checkbox(GetString("Defense Fates"),gGrindDoDefenseFates),"gGrindDoDefenseFates");
		GUI_DrawIntMinMax(GetString("Defense Fate Wait %"),"gFateDefenseWaitPercent",1,5,0,99)
		GUI_Capture(GUI:Checkbox(GetString("Escort Fates"),gGrindDoEscortFates),"gGrindDoEscortFates");
		GUI_DrawIntMinMax(GetString("Escort Fate Wait %"),"gFateEscortWaitPercent",1,5,0,99)
	
		GUI:PopItemWidth()
		GUI:EndChild()
	end
end


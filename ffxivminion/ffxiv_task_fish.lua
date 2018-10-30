ffxiv_fish = {}
ffxiv_fish.attemptedCasts = 0
ffxiv_fish.biteDetected = 0
ffxiv_fish.firstRun = nil
ffxiv_fish.firstRunCompleted = false
ffxiv_fish.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\FishProfiles\]]
ffxiv_fish.profiles = {}
ffxiv_fish.profilesDisplay = {}

ffxiv_fish.profileData = {}
ffxiv_fish.currentTask = {}
ffxiv_fish.currentTaskIndex = 0
ffxiv_fish.collectibles = {
    { name = AceLib.API.Items.GetNameByID(14211,47), id = 14211, alias = "Amber Salamander", minimum = 900 },
    { name = AceLib.API.Items.GetNameByID(12827,47), id = 12827, alias = "Barreleye", minimum = 923 },
    { name = AceLib.API.Items.GetNameByID(12739,47), id = 12739, alias = "Bubble Eye", minimum = 162 },
    { name = AceLib.API.Items.GetNameByID(12837,47), id = 12837, alias = "Capelin", minimum = 89 },
    { name = AceLib.API.Items.GetNameByID(13729,47), id = 13729, alias = "Dravanian Smelt", minimum = 83 },
    { name = AceLib.API.Items.GetNameByID(12742,47), id = 12742, alias = "Dravanian Squeaker", minimum = 158 },
    { name = AceLib.API.Items.GetNameByID(12724,47), id = 12724, alias = "Glacier Core", minimum = 310 },
    { name = AceLib.API.Items.GetNameByID(12713,47), id = 12713, alias = "Icepick", minimum = 106 },
    { name = AceLib.API.Items.GetNameByID(12804,47), id = 12804, alias = "Illuminati Perch", minimum = 826 },
    { name = AceLib.API.Items.GetNameByID(12830,47), id = 12830, alias = "Loosetongue", minimum = 2441 },
    { name = AceLib.API.Items.GetNameByID(12814,47), id = 12814, alias = "Moogle Spirit", minimum = 1062 },
    { name = AceLib.API.Items.GetNameByID(12768,47), id = 12768, alias = "Noontide Oscar", minimum = 258 },
    { name = AceLib.API.Items.GetNameByID(12726,47), id = 12726, alias = "Sorcerer Fish", minimum = 646 },
    { name = AceLib.API.Items.GetNameByID(12825,47), id = 12825, alias = "Stupendemys", minimum = 1526 },
    { name = AceLib.API.Items.GetNameByID(12828,47), id = 12828, alias = "Thunderbolt Eel", minimum = 813 },
    { name = AceLib.API.Items.GetNameByID(12774,47), id = 12774, alias = "Tiny Axolotl", minimum = 320 },
    { name = AceLib.API.Items.GetNameByID(12834,47), id = 12834, alias = "Vampiric Tapestry", minimum = 1308 },
    { name = AceLib.API.Items.GetNameByID(12767,47), id = 12767, alias = "Warmwater Bichir", minimum = 683 },
    { name = AceLib.API.Items.GetNameByID(12792,47), id = 12792, alias = "Weston Bowfin", minimum = 376 },
    { name = AceLib.API.Items.GetNameByID(12721,47), id = 12721, alias = "Whilom Catfish", minimum = 459 },
	-- SB
    { name = AceLib.API.Items.GetNameByID(20274,47), id = 20274, alias = "Deemster", minimum = 829 },
    { name = AceLib.API.Items.GetNameByID(20234,47), id = 20234, alias = "Wraithfish", minimum = 50 },
    { name = AceLib.API.Items.GetNameByID(20024,47), id = 20024, alias = "Sweatfish", minimum = 0 },
    { name = AceLib.API.Items.GetNameByID(20234,47), id = 20234, alias = "Soul of the Stallion", minimum = 50 },
    { name = AceLib.API.Items.GetNameByID(20019,47), id = 20019, alias = "Ala Mhigan Ribbon", minimum = 40 },
    { name = AceLib.API.Items.GetNameByID(20021,47), id = 20021, alias = "Seraphim", minimum = 49 },
    { name = AceLib.API.Items.GetNameByID(20234,47), id = 20234, alias = "Thousandfang", minimum = 50 },
    { name = AceLib.API.Items.GetNameByID(20230,47), id = 20230, alias = "Fangshi", minimum = 303 },
    { name = AceLib.API.Items.GetNameByID(20239,47), id = 20239, alias = "Mosasaur", minimum = 824 },
    { name = AceLib.API.Items.GetNameByID(20233,47), id = 20233, alias = "Eternal Eye", minimum = 25 },
    { name = AceLib.API.Items.GetNameByID(20210,47), id = 20210, alias = "Mitsuriku Shark", minimum = 819 },
    { name = AceLib.API.Items.GetNameByID(20238,47), id = 20238, alias = "Silken Sunfish", minimum = 767 },
    { name = AceLib.API.Items.GetNameByID(20220,47), id = 20220, alias = "Cherubfish", minimum = 21 },
    { name = AceLib.API.Items.GetNameByID(20104,47), id = 20104, alias = "Daio Squid", minimum = 1034 },
    { name = AceLib.API.Items.GetNameByID(20028,47), id = 20028, alias = "Samurai Fish", minimum = 14 },
    { name = AceLib.API.Items.GetNameByID(20044,47), id = 20044, alias = "Tao Bitterling", minimum = 49 },
    { name = AceLib.API.Items.GetNameByID(20036,47), id = 20036, alias = "Killifish", minimum = 9 },
    { name = AceLib.API.Items.GetNameByID(20118,47), id = 20118, alias = "Yanxian Koi", minimum = 451 },
    { name = AceLib.API.Items.GetNameByID(20098,47), id = 20098, alias = "Butterfly Fish", minimum = 115 },
    { name = AceLib.API.Items.GetNameByID(20087,47), id = 20087, alias = "Velodyna Grass Carp", minimum = 690 },
	
}

ffxiv_fish.GUI = {
	x = 0,
	y = 0, 
	height = 0,
	width = 0,
}

ffxiv_task_fish = inheritsFrom(ml_task)
function ffxiv_task_fish.Create()
    --local newinst = inheritsFrom(ffxiv_task_fish)
    if gFishMarkerOrProfileIndex == 1 then
		gMarkerType = "Fishing"
	end
	
	local newinst = {}
	
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "LT_FISH"
	
    --ffxiv_task_fish members
    newinst.castTimer = 0
    newinst.markerTime = 0
	ml_global_information.lastEquip = 0
	
	newinst.currentMarker = false
	ml_marker_mgr.currentMarker = nil
	
	newinst.filterLevel = true
	newinst.networkLatency = 0
	newinst.requiresAdjustment = false
	newinst.requiresRelocate = false
	
	newinst.snapshot = GetInventorySnapshot({0,1,2,3})
	ffxiv_fish.currentTask = {}
	ffxiv_fish.currentTaskIndex = 0
	ffxiv_fish.attemptedCasts = 0
	ffxiv_fish.biteDetected = 0
	ffxiv_fish.firstRunCompleted = false
	
	AddEvacPoint()
	
	setmetatable(newinst, { __index = ffxiv_task_fish })
    return newinst
end

function fd(var,level)
	local level = tonumber(level) or 3
	
	local requiredLevel = gFishDebugLevel
	if (gBotMode == GetString("questMode") and gQuestDebug) then
		requiredLevel = gQuestDebugLevel
	end
	
	if ( gFishDebug or (gQuestDebug and gBotMode == GetString("questMode"))) then
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

function ffxiv_fish.GetDirective()
	local marker = ml_marker_mgr.currentMarker
	local task = ffxiv_fish.currentTask
	
	if (table.valid(task)) then
		return task, "task"
	elseif (table.valid(marker)) then
		return marker, "marker"
	end
	
	return nil
end

function ffxiv_fish.HasDirective()
	local marker = ml_marker_mgr.currentMarker
	local task = ffxiv_fish.currentTask
	
	return (table.valid(task) or table.valid(marker))
end

function HasBaits(name)
	local inventories = {0,1,2,3}
	local itemid = 0
	local name = name or ""
	
	if (name ~= "") then
		for bait in StringSplit(name,",") do
			if (tonumber(bait) ~= nil) then
				itemid = tonumber(bait)
			else
				--fd("[HasBaits] Searching for bait ID for ["..IsNull(bait,"").."].",3)
				itemid = AceLib.API.Items.GetIDByName(bait)
			end

			if (itemid) then
				local item = GetItem(itemid,inventories)
				if (item) then
					return true
				end
			end
		end
	else
		return false
	end
	
	return false
end

function GetCurrentTaskPos()
	local pos = {}
	
	if (table.valid(ffxiv_fish.currentTask)) then
		local task = ffxiv_fish.currentTask
		if (task.maxPositions > 0) then
			local taskMultiPos = task.multipos
			if (table.valid(taskMultiPos)) then
				if (table.valid(taskMultiPos[task.currentPositionIndex])) then
					pos = taskMultiPos[task.currentPositionIndex]
				else
					for i,choice in pairs(taskMultiPos) do
						if (table.valid(choice)) then
							ffxiv_fish.currentTask.currentPositionIndex = i
							pos = choice
							break
						end
					end
				end
			end
		else
			local taskPos = task.pos
			if (table.valid(taskPos)) then
				pos = taskPos
			end
		end
	end

	return pos
end

function GetNextTaskPos()
	local newIndex,newPos = nil,{}
	
	local multipos = ffxiv_fish.currentTask.multipos
	local attempted = ffxiv_fish.currentTask.attemptedPositions
	local rerollMap = {}
	
	if (table.valid(multipos)) then
		for k,v in pairs(multipos) do
			if (not table.valid(attempted) or not attempted[k]) then
				table.insert(rerollMap,k)
			end
		end
		
		if (table.size(rerollMap) > 0) then
			local actual = rerollMap[math.random(1,table.size(rerollMap))]
			if (actual) then
				newIndex = actual
				newPos = multipos[actual]
			end		
		end
	end

	return newIndex, newPos
end


c_precastbuff = inheritsFrom( ml_cause )
e_precastbuff = inheritsFrom( ml_effect )
c_precastbuff.activity = ""
c_precastbuff.item = nil
c_precastbuff.itemid = 0
c_precastbuff.requirestop = false
c_precastbuff.requirestopfishing = false
c_precastbuff.requiredismount = false
function c_precastbuff:evaluate()
	if (MIsLoading() or MIsCasting() or IsFlying()) then
		return false
	end
	
	c_precastbuff.activity = ""
	c_precastbuff.itemid = 0
	c_precastbuff.requirestop = false
	c_precastbuff.requirestopfishing = false
	c_precastbuff.requiredismount = false
		
	local useCordials = (gFishUseCordials)
	local useFood = 0
	local needsStealth = false
	local taskType = "fishing"
	
	local task = ffxiv_fish.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		needsStealth = IsNull(task.usestealth,false)
		minimumGP = IsNull(task.mingp,0)
		useCordials = IsNull(task.usecordials,useCordials)
		useFood = IsNull(task.food,0)
		taskType = IsNull(task.type,"fishing")
	elseif (table.valid(marker)) then
		needsStealth = IsNull(marker.usestealth,false)
	end
		
	if (type(needsStealth) == "string" and GUI_Get(needsStealth) ~= nil) then
		needsStealth = GUI_Get(needsStealth)
	end
	if (type(useCordials) == "string" and GUI_Get(useCordials) ~= nil) then
		useCordials = GUI_Get(useCordials)
	end
	if (type(minimumGP) == "string" and GUI_Get(minimumGP) ~= nil) then
		minimumGP = GUI_Get(minimumGP)
	end
	if (type(useFood) == "string" and GUI_Get(useFood) ~= nil) then
		useFood = GUI_Get(useFood)
	end
	
	if (taskType == "idle") then
		return false
	end
		
		
	local fs = Player:GetFishingState()
	if (fs == 0 or ((MissingBuff(Player,762) and MissingBuff(Player,763) and MissingBuff(Player,764)) and fs == 4)) then
		if (Player.job ~= FFXIV.JOBS.FISHER) then
			if (CanSwitchToClass(FFXIV.JOBS.FISHER)) then
				c_precastbuff.activity = "switchclass"
				c_precastbuff.requirestop = false
				c_precastbuff.requirestopfishing = true
				c_precastbuff.requiredismount = false
				return true
			else
				d("Cannot swap yet, but we have no choice, wait a second")
				c_precastbuff.activity = "switchclasslegacy"
				return true
			end
		end

		
		local hasStealth = HasBuff(Player.id,47)
		if (not hasStealth and needsStealth) then
			local stealth = SkillMgr.GetAction(298,1)
			if (stealth and stealth:IsReady(Player.id) and Player.action ~= 367) then
				c_precastbuff.activity = "stealth"
				c_precastbuff.requiredismount = true
				return true
			end
		end
		
		if (fs == 4) then
			if (c_mooch2:evaluate()) then
				return false
			end
			if (c_mooch:evaluate()) then
				return false
			end
		end
		
		local canUse,manualItem = CanUseExpManual()
		if (canUse and table.valid(manualItem)) then
			d("[PreCastBuff]: Need to use a manual, grabbed item ["..tostring(manualItem.hqid).."]")
			c_precastbuff.activity = "usemanual"
			c_precastbuff.itemid = manualItem.hqid
			c_precastbuff.requirestop = true
			c_precastbuff.requirestopfishing = true
			c_precastbuff.requiredismount = true
			return true
		end
	else
		
		if (ShouldEat()) then
			c_precastbuff.activity = "eat"
			c_precastbuff.requirestop = false
			c_precastbuff.requiredismount = false
			return true
		end
		
		if (useCordials) then
			local canUse,cordialItem = CanUseCordial()
			if (canUse and table.valid(cordialItem)) then
				d("[PreCastBuff]: Need to use a cordial.")
				c_precastbuff.activity = "usecordial"
				c_precastbuff.itemid = cordialItem.hqid
				c_precastbuff.requirestop = false
				c_precastbuff.requiredismount = false
				return true
			end					
		end
	end
	
	return false
end
function e_precastbuff:execute()
	local activityitemid = c_precastbuff.itemid
	local requirestop = c_precastbuff.requirestop
	local requirestopfishing = c_precastbuff.requirestopfishing
	local requiredismount = c_precastbuff.requiredismount
	local activity = c_precastbuff.activity
	
	local fs = Player:GetFishingState()
	if (fs ~= 0 and requirestopfishing) then
		ffxiv_fish.StopFishing()
		return
	end
	
	if (requirestop) then
		if (Player:IsMoving()) then
			Player:PauseMovement()
			ml_global_information.Await(1500, function () return not Player:IsMoving() end)
			return
		end
	end
	
	if (requiredismount and Player.ismounted) then
		Dismount()
		ml_global_information.Await(2500, function () return (not Player.ismounted) end)
		return
	end
	
	if (activity == "switchclass") then
		local newTask = ffxiv_misc_switchclass.Create()
		newTask.class = FFXIV.JOBS.FISHER
		ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
		ml_task_hub:ThisTask().preserveSubtasks = true
		return
	end
	
	if (activity == "usemanual") then
		local manual, action = GetItem(activityitemid)
		if (manual and manual:IsReady(Player.id)) then
			manual:Cast(Player.id)
			ml_global_information.Await(4000, function () return HasBuff(Player.id, 46) end)
			return
		end
	end
	
	if (activity == "eat") then
		Eat()
		return
	end
	
	if (activity == "stealth") then
		d("started stealth task")
		local newTask = ffxiv_task_stealth.Create()
		newTask.addingStealth = true
		ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
		ml_global_information.Await(2000)
		return
	end
	
	if (activity == "usecordial") then
		local cordial, action = GetItem(activityitemid)
		if (cordial and action and cordial:IsReady(Player.id)) then
			cordial:Cast(Player.id)
			local castid = action.id
			ml_global_information.Await(5000, function () return Player.castinginfo.lastcastid == castid end)
			return
		end
	end
end

c_mooch2 = inheritsFrom( ml_cause )
e_mooch2 = inheritsFrom( ml_effect )
function c_mooch2:evaluate()
	local useMooch2 = false
	local moochWithIntuition = true
	local moochWithoutIntuition = true
	local marker = ml_marker_mgr.currentMarker
	local task = ffxiv_fish.currentTask
	if (table.valid(task)) then
		useMooch2 = IsNull(task.usemooch2,false)
		moochWithIntuition = IsNull(task.moochwithintuition,true)
		moochWithoutIntuition = IsNull(task.moochwithoutintuition,true)
	elseif (table.valid(marker)) then
		useMooch2 = IsNull(marker.usemooch2,false)
	elseif gFishMarkerOrProfileIndex == 3 then
		useMooch2 = gQuickstartMooch2
	else
		useMooch2 = true
	end
	
	if (type(useMooch2) == "string" and GUI_Get(useMooch2) ~= nil) then
		useMooch2 = GUI_Get(useMooch2)
	end
	
	local fs = Player:GetFishingState()
	if (fs == 0 or fs == 4) then
		if (useMooch2 and ((HasBuffs(Player,568) and moochWithIntuition) or (MissingBuffs(Player,568) and moochWithoutIntuition))) then
			local mooch2 = SkillMgr.GetAction(268,1)
			if (mooch2 and mooch2:IsReady(Player.id)) then
				local moochables2 = ""
				if (table.valid(task)) then
					if (task.moochables2) then
						moochables2 = task.moochables2
					end
				elseif (table.valid(marker)) then
					moochables2 = IsNull(marker.moochables2,"")
				end
				
				local lastCatch = GetNewInventory(ml_task_hub:CurrentTask().snapshot)
				if (not lastCatch or moochables2 == "") then
					return true
				elseif (lastCatch and moochables2 ~= "") then
					for moochables2 in StringSplit(moochables2,",") do
						if (AceLib.API.Items.GetIDByName(moochables2,47) == lastCatch) then
							return true
						end
					end
				end
			end
		end
	end
    return false
end
function e_mooch2:execute()
    local mooch2 = SkillMgr.GetAction(268,1)
    if (mooch2 and mooch2:IsReady(Player.id)) then
        if (mooch2:Cast()) then
			fd("Mooch2 Cast",1)
			ml_task_hub:CurrentTask().snapshot = GetInventorySnapshot({0,1,2,3})
		end
		ml_global_information.Await(3000, function () return not In(Player:GetFishingState(),0,4) end)
    end
end

c_mooch = inheritsFrom( ml_cause )
e_mooch = inheritsFrom( ml_effect )
function c_mooch:evaluate()
	local useMooch = false
	local moochWithIntuition = true
	local moochWithoutIntuition = true
	local marker = ml_marker_mgr.currentMarker
	local task = ffxiv_fish.currentTask
	if (table.valid(task)) then
		useMooch = IsNull(task.usemooch,false)
		moochWithIntuition = IsNull(task.moochwithintuition,true)
		moochWithoutIntuition = IsNull(task.moochwithoutintuition,true)
	elseif (table.valid(marker)) then
		useMooch = IsNull(marker.usemooch,false)
	elseif gFishMarkerOrProfileIndex == 3 then
		useMooch = gQuickstartMooch
	else
		useMooch = true
	end
	
	if (type(useMooch) == "string" and GUI_Get(useMooch) ~= nil) then
		useMooch = GUI_Get(useMooch)
	end
	
	local fs = Player:GetFishingState()
	if (fs == 0 or fs == 4) then
		if (useMooch and ((HasBuffs(Player,568) and moochWithIntuition) or (MissingBuffs(Player,568) and moochWithoutIntuition))) then
			local mooch = SkillMgr.GetAction(297,1)
			if (mooch and mooch:IsReady(Player.id)) then
				local moochables = ""
				if (table.valid(task)) then
					if (task.moochables) then
						moochables = task.moochables
					end
				elseif (table.valid(marker)) then
					moochables = IsNull(marker.moochables,"")
				end
				
				local lastCatch = GetNewInventory(ml_task_hub:CurrentTask().snapshot)
				if (not lastCatch or moochables == "") then
					return true
				elseif (lastCatch and moochables ~= "") then
					for moochable in StringSplit(moochables,",") do
						if (AceLib.API.Items.GetIDByName(moochable,47) == lastCatch) then
							return true
						end
					end
				end
			end
		end
	end
    return false
end
function e_mooch:execute()
    local mooch = SkillMgr.GetAction(297,1)
    if (mooch and mooch:IsReady(Player.id)) then
        if (mooch:Cast()) then
			fd("Mooch Cast",1)
			ml_task_hub:CurrentTask().snapshot = GetInventorySnapshot({0,1,2,3})
		end
		ml_global_information.Await(3000, function () return not In(Player:GetFishingState(),0,4) end)
    end
end

c_release = inheritsFrom( ml_cause )
e_release = inheritsFrom( ml_effect )
function c_release:evaluate()
	if (not ffxiv_fish.HasDirective()) then
		return false
	end
	
	local fs = Player:GetFishingState()
	if (fs == 0 or fs == 4) then
		local release = SkillMgr.GetAction(300,1)
		if (release and release:IsReady(Player.id)) then
			
			local whitelist = ""
			local whitelistHQ = ""
			local blacklist = ""
			local blacklistHQ = ""
			
			local task = ffxiv_fish.currentTask
			local marker = ml_marker_mgr.currentMarker
			if (table.valid(task)) then
				whitelist = IsNull(task.whitelist,"")
				whitelistHQ = IsNull(task.whitelisthq,"")
				blacklist = IsNull(task.blacklist,"")
				blacklistHQ = IsNull(task.blacklisthq,"")
			elseif (table.valid(marker)) then
				whitelist = IsNull(marker.whitelist,"")
				whitelistHQ = IsNull(marker.whitelistHQ,"")
				blacklist = IsNull(marker.blacklist,"")
				blacklistHQ = IsNull(marker.blacklistHQ,"")
			end
					
			local lastCatch,hq = GetNewInventory(ml_task_hub:CurrentTask().snapshot)
			if (lastCatch) then
				fd("[Release]: Last Catch :["..tostring(lastCatch).."], HQ: ["..tostring(hq).."].", 3)
				if (hq) then
					if (whitelistHQ and whitelistHQ ~= "") then
						fd("[Release]: HQ Whitelist :["..tostring(whitelistHQ).."].",3)
						local release = true
						for mustkeep in StringSplit(whitelistHQ,",") do
							local mustkeepid = 0
							if (tonumber(mustkeep) ~= nil) then
								mustkeepid = tonumber(mustkeep)
							else
								mustkeepid = AceLib.API.Items.GetIDByName(mustkeep)
							end
							
							if (mustkeepid == lastCatch) then
								release = false
							end
						end
						if (release) then
							return true
						end
					elseif (blacklistHQ and blacklistHQ ~= "") then
						fd("[Release]: HQ Blacklist :["..tostring(blacklistHQ).."].",3)
						for throwaway in StringSplit(blacklistHQ,",") do
							local throwawayid = 0
							if (tonumber(throwaway) ~= nil) then
								throwawayid = tonumber(throwaway)
							else
								throwawayid = AceLib.API.Items.GetIDByName(throwaway)
							end
							
							if (throwawayid == lastCatch) then
								return true
							end
						end
					end
				else
					if (whitelist and whitelist ~= "") then
						fd("[Release]: NQ Whitelist :["..tostring(whitelist).."].",3)
						local release = true
						for mustkeep in StringSplit(whitelist,",") do
							local mustkeepid = 0
							if (tonumber(mustkeep) ~= nil) then
								mustkeepid = tonumber(mustkeep)
							else
								mustkeepid = AceLib.API.Items.GetIDByName(mustkeep)
							end
							
							if (mustkeepid == lastCatch) then
								release = false
							end
						end
						if (release) then
							return true
						end
					elseif (blacklist and blacklist ~= "") then
						fd("[Release]: NQ Blacklist :["..tostring(blacklist).."].",3)
						for throwaway in StringSplit(blacklist,",") do
							local throwawayid = 0
							if (tonumber(throwaway) ~= nil) then
								throwawayid = tonumber(throwaway)
							else
								throwawayid = AceLib.API.Items.GetIDByName(throwaway)
							end
							
							if (throwawayid == lastCatch) then
								return true
							end
						end
					end
				end
			end
        end
    end
    return false
end
function e_release:execute()
    local release = SkillMgr.GetAction(300,1)
    if (release and release:IsReady(Player.id)) then
        if (release:Cast()) then
			ml_task_hub:CurrentTask().snapshot = GetInventorySnapshot({0,1,2,3})
		end
		ml_global_information.Await(1500)
    end
end

c_cast = inheritsFrom( ml_cause )
e_cast = inheritsFrom( ml_effect )
function c_cast:evaluate()
	local currentBait = IsNull(Player:GetBait(),0)
	if (currentBait == 0) then
		return false
	end
	
	local fs = Player:GetFishingState()
	if (fs == 0 or fs == 4) then
		local cast = SkillMgr.GetAction(289,1)
		if (cast and cast:IsReady(Player.id)) then
			return true
		end
	end
    return false
end
function e_cast:execute()
	local cast = SkillMgr.GetAction(289,1)
	if (cast and cast:IsReady(Player.id)) then	
		if (cast:Cast()) then
			ml_task_hub:CurrentTask().snapshot = GetInventorySnapshot({0,1,2,3})
		end
		if (table.valid(ffxiv_fish.currentTask)) then
			if (ffxiv_fish.currentTask.taskStarted == 0) then
				ffxiv_fish.currentTask.taskStarted = Now()
			end
		end
		ffxiv_fish.attemptedCasts = ffxiv_fish.attemptedCasts + 1
		d("[Cast]: Attempt #"..tostring(ffxiv_fish.attemptedCasts))
		ml_global_information.Await(3000, function () return not In(Player:GetFishingState(),0,4) end)
	end
end

function GetNewInventory(snapshot)
	local currentInventory = GetInventorySnapshot({0,1,2,3})

	for itemid,item in pairs(currentInventory) do
		if (snapshot[itemid] == nil) then
			-- Item is new in inventory
			if item.HQcount > 0 then
				fd(item.name.." (HQ) is NEW",3)
				return itemid, true
			else
				fd(item.name.." is NEW",3)
				return itemid, false
			end
		else
			-- Item already existed in inventory
			if item.HQcount > snapshot[itemid].HQcount then
				fd(item.name.." (HQ) has INCREMENTED",3)
				return itemid, true
			elseif item.count > snapshot[itemid].count then
				fd(item.name.." has INCREMENTED",3)
				return itemid, false
			end
		end
	end
	
	return nil, nil
end

-- Has to get called, else the dude issnot moving thanks to "runforward" usage ;)
c_finishcast = inheritsFrom( ml_cause )
e_finishcast = inheritsFrom( ml_effect )
function c_finishcast:evaluate()
	local needsStop = false
	
	local marker = ml_marker_mgr.currentMarker
	local task = ffxiv_fish.currentTask
	if (not table.valid(task) or not table.valid(marker)) then
		needsStop = true
	end
	
	local fs = Player:GetFishingState()
	if (fs ~= 0 and c_returntomarker:evaluate()) then
		return true
	end
    return false
end
function e_finishcast:execute()
    ffxiv_fish.StopFishing()
end

c_bite = inheritsFrom( ml_cause )
e_bite = inheritsFrom( ml_effect )
function c_bite:evaluate()
	local fs = Player:GetFishingState()
	if( fs == 5 ) then -- FISHSTATE_BITE
		return true
	end
    return false
end
function e_bite:execute()
	if (ffxiv_fish.biteDetected == 0) then
		ffxiv_fish.biteDetected = Now() + math.random(250,1000)
		return
	elseif (Now() > ffxiv_fish.biteDetected) then
		local doHook = true
		local task = ffxiv_fish.currentTask
		local marker = ml_marker_mgr.currentMarker
	    local lightTug, medTug, massiveTug = true,true,true
		if (table.valid(task)) then
			lightTug = IsNull(task.lighttug,true)
			medTug = IsNull(task.mediumtug,true)
			massiveTug = IsNull(task.massivetug,true)
		end
		if (type(lightTug) == "string" and GUI_Get(lightTug) ~= nil) then
			lightTug = GUI_Get(lightTug)
		end
		if (type(medTug) == "string" and GUI_Get(medTug) ~= nil) then
			medTug = GUI_Get(medTug)
		end
		if (type(massiveTug) == "string" and GUI_Get(massiveTug) ~= nil) then
			massiveTug = GUI_Get(massiveTug)
		end
		
		if (not lightTug) and Player.status == 36 then
			doHook = false
			d("light dohook false")
		end
		if (not medTug) and Player.status == 37 then
			doHook = false
			d("med dohook false")
		end
		if (not massiveTug) and Player.status == 38 then
			doHook = false
			d("massive dohook false")
		end
		if doHook then
			if (HasBuffs(Player,"764")) then
				local precisionHook = SkillMgr.GetAction(4179,1)
				local powerfulHook = SkillMgr.GetAction(4103,1)
				local status = Player.status
				-- 36 = small tug?
				if (status == 36 and precisionHook and precisionHook:IsReady(Player.id)) then
					precisionHook:Cast()
					return
				elseif ((status == 37 or status == 38) and powerfulHook and powerfulHook:IsReady(Player.id)) then
					powerfulHook:Cast()
					return
				end
			end
			
			local useDoubleHook = false
			if (table.valid(task)) then
				useDoubleHook = IsNull(task.usedoublehook,false)
			elseif (table.valid(marker)) then
				useDoubleHook = IsNull(marker.usedoublehook,false )
			elseif gFishMarkerOrProfileIndex == 3 then
				useDoubleHook = gQuickstartDH
			end
			
			if (type(useDoubleHook) == "string" and GUI_Get(useDoubleHook) ~= nil) then
				useDoubleHook = GUI_Get(useDoubleHook)
			end
			
			if (useDoubleHook) then
				local doubleHook = SkillMgr.GetAction(269,1)
				if (doubleHook and doubleHook:IsReady(Player.id)) then
					doubleHook:Cast()
					return true
				end
			end	
			
			local bite = SkillMgr.GetAction(296,1)
			if (bite and bite:IsReady(Player.id)) then
				bite:Cast()
				return true
			end
		end
	end
end

c_chum = inheritsFrom( ml_cause )
e_chum = inheritsFrom( ml_effect )
function c_chum:evaluate()
	if (not ffxiv_fish.HasDirective() and (not gBotMode == GetString("fishMode") and gFishMarkerOrProfileIndex == 3)) then
		return false
	end
		
	local useChum = false
	local useEyes = false
	local useChumWithIntuition = true
	local useChumWithoutIntuition = true
	local task = ffxiv_fish.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		useChum = IsNull(task.usechum,false )
		useChumWithIntuition = IsNull(task.usechumwithintuition,true)
		useChumWithoutIntuition = IsNull(task.usechumwithoutintuition,true)
	elseif (table.valid(marker)) then
		useChum = IsNull(marker.usechum,false )
		useEyes = IsNull(marker.usefisheyes,false)
	elseif gFishMarkerOrProfileIndex == 3 then
		useChum = gQuickstartChum
		useEyes = gQuickstartFishEyes
	end
	
	if (type(useChum) == "string" and GUI_Get(useChum) ~= nil) then
		useChum = GUI_Get(useChum)
	end
	if (type(useEyes) == "string" and GUI_Get(useEyes) ~= nil) then
		useEyes = GUI_Get(useEyes)
	end
	
	if (useChum) then
		if ((HasBuffs(Player,568) and useChumWithIntuition) or (MissingBuffs(Player,568) and useChumWithoutIntuition)) then
			local chum = SkillMgr.GetAction(4104,1)
			if (chum and chum:IsReady(Player.id)) then	
				if (MissingBuffs(Player,"763") and ((useEyes and HasBuffs(Player,"762")) or not useEyes)) then
					if (chum:Cast()) then
						ml_global_information.Await(3000, function () return (HasBuffs(Player,"763")) end)
						return true
					end
				end
			end
		end
	end
	
    return false
end
function e_chum:execute()
	fd("Chum Cast",1)
end

c_fisheyes = inheritsFrom( ml_cause )
e_fisheyes = inheritsFrom( ml_effect )
function c_fisheyes:evaluate()
	if (not ffxiv_fish.HasDirective() and (not gBotMode == GetString("fishMode") and gFishMarkerOrProfileIndex == 3)) then
		return false
	end

		
	local useBuff = false
	local useEyesWithIntuition = true
	local useEyesWithoutIntuition = true
	local task = ffxiv_fish.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		useBuff = IsNull(task.usefisheyes,false)
		useEyesWithIntuition = IsNull(task.useeyeswithintuition,true)
		useEyesWithoutIntuition = IsNull(task.useeyeswithoutintuition,true)
	elseif (table.valid(marker)) then
		useBuff = IsNull(marker.usefisheyes,false)
	elseif gFishMarkerOrProfileIndex == 3 then
		useBuff = gQuickstartFishEyes
	end
	
	if (type(useBuff) == "string" and GUI_Get(useBuff) ~= nil) then
		useBuff = GUI_Get(useBuff)
	end
	
	if (useBuff and ((HasBuffs(Player,568) and useEyesWithIntuition) or (MissingBuffs(Player,568) and useEyesWithoutIntuition))) then
		local fisheyes = SkillMgr.GetAction(4105,1)
		if (fisheyes and fisheyes:IsReady(Player.id)) then
			if (MissingBuffs(Player,"762")) then
				if (fisheyes:Cast()) then
					ml_global_information.Await(3000, function () return (HasBuffs(Player,"762")) end)
				end
				return true
			end
		end
	end
	
    return false
end
function e_fisheyes:execute()
	fd("Fisheyes Cast",1)
end

c_snagging = inheritsFrom( ml_cause )
e_snagging = inheritsFrom( ml_effect )
function c_snagging:evaluate()
	if (not ffxiv_fish.HasDirective() and (not gBotMode == GetString("fishMode") and gFishMarkerOrProfileIndex == 3)) then
		return false
	end	
		
	local useBuff = false
	local snagWithIntuition = true
	local snagWithoutIntuition = true
	local task = ffxiv_fish.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		useBuff = IsNull(task.usesnagging,false)
		snagWithIntuition = IsNull(task.snagwithintuition,true)
		snagWithoutIntuition = IsNull(task.snagwithoutintuition,true)
	elseif (table.valid(marker)) then
		useBuff = IsNull(marker.usesnagging,false)
	elseif gFishMarkerOrProfileIndex == 3 then
		useBuff = gQuickstartSnagging
	end
	if (type(useBuff) == "string" and GUI_Get(useBuff) ~= nil) then
		useBuff = GUI_Get(useBuff)
	end
	

	local snagging = SkillMgr.GetAction(4100,1)
	if (snagging and snagging:IsReady(Player.id)) then
		if (useBuff and ((HasBuffs(Player,568) and snagWithIntuition) or (MissingBuffs(Player,568) and snagWithoutIntuition))) then
			if (MissingBuffs(Player,"761")) then
				if (snagging:Cast()) then
					ml_global_information.Await(3000, function () return (HasBuffs(Player,"761")) end)
				end
				return true
			end
		else
			if (HasBuffs(Player,"761")) then
				if (snagging:Cast()) then
					ml_global_information.Await(3000, function () return (MissingBuffs(Player,"761")) end)
				end
				return true
			end
		end
	end
	
    return false
end
function e_snagging:execute()
	fd("Snagging Cast",1)
end

c_usecollect = inheritsFrom( ml_cause )
e_usecollect = inheritsFrom( ml_effect )
function c_usecollect:evaluate()
	local useBuff = false
	local task = ffxiv_fish.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		
		local collect = SkillMgr.GetAction(4101,1)
		if (collect and collect:IsReady(Player.id)) then
			useBuff = IsNull(task.usecollect,false)
			if (type(useBuff) == "string" and GUI_Get(useBuff) ~= nil) then
				useBuff = GUI_Get(useBuff)
			end
			if (useBuff) then
				if (MissingBuffs(Player,"805")) then
					if (collect:Cast(Player.id)) then
						ml_global_information.Await(3000, function () return (HasBuffs(Player,"805")) end)
					end						
					return true
				end
			else
				if (HasBuffs(Player,"805")) then
					if (collect:Cast(Player.id)) then
						ml_global_information.Await(3000, function () return (MissingBuffs(Player,"805")) end)
					end						
					return true
				end
			end
		end
	end
	
    return false
end
function e_usecollect:execute()
end

c_patience = inheritsFrom( ml_cause )
e_patience = inheritsFrom( ml_effect )
c_patience.action = 0
function c_patience:evaluate()
	--Reset tempvar.
	c_patience.action = 0
	
	if ((Player.gp.percent < 99 and not ffxiv_fish.NeedsCordialCheck()) or HasBuff(Player,764)) then
		return false
	end
	
		
	local usePatience = false
	local usePatience2 = false
	local patienceWithIntuition = true
	local patienceWithoutIntuition = true
	
	local task = ffxiv_fish.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		local patienceVar = IsNull(task.patiencevar,"")
		if (patienceVar ~= "" and _G[patienceVar] ~= nil) then
			patienceVar = _G[patienceVar]
			if (patienceVar == "Patience") then
				usePatience = true
			elseif (patienceVar == "Patience II") then
				usePatience2 = true
			end
		else
			usePatience = IsNull(task.usepatience,false)
			usePatience2 = IsNull(task.usepatience2,false)
			patienceWithIntuition = IsNull(task.patiencewithintuition,true)
			patienceWithoutIntuition = IsNull(task.patiencewithoutintuition,true)
		end
	elseif (table.valid(marker)) then
		usePatience = IsNull(marker.usepatience,false)
		usePatience2 = IsNull(marker.usepatience2,false)
	elseif gFishMarkerOrProfileIndex == 3 then
		usePatience = gQuickstartPatience
		usePatience2 = gQuickstartPatience2
	end
	
	if (type(usePatience) == "string" and GUI_Get(usePatience) ~= nil) then
		usePatience = GUI_Get(usePatience)
	end
	if (type(usePatience2) == "string" and GUI_Get(usePatience2) ~= nil) then
		usePatience2 = GUI_Get(usePatience2)
	end
	
	if ((HasBuffs(Player,568) and patienceWithIntuition) or (MissingBuffs(Player,568) and patienceWithoutIntuition)) then
		
		if (usePatience2) then
			local patience2 = SkillMgr.GetAction(4106,1)
			if (patience2 and patience2:IsReady(Player.id)) then	
				if (patience2:Cast()) then
					ml_global_information.Await(3000, function () return HasBuff(Player,764) end)
				end
				return true
			end
		end
		
		if (usePatience) then
			local patience = SkillMgr.GetAction(4102,1)
			if (patience and patience:IsReady(Player.id)) then	
				if (patience:Cast()) then
					ml_global_information.Await(3000, function () return HasBuff(Player,764) end)
				end
				return true
			end
		end
	end
	
    return false
end
function e_patience:execute() 
	fd("Patience Cast",1)
end

c_collectibleaddonfish = inheritsFrom( ml_cause )
e_collectibleaddonfish = inheritsFrom( ml_effect )
function c_collectibleaddonfish:evaluate()
	local addonName = "SelectYesno"
	--if (ffxivminion.gameRegion == 3) then -- maybe
		--addonName = "SelectYesNoCountItem"
	--end
	if (IsControlOpen(addonName)) then
		local info = GetControlData(addonName)
		if (info and info.collectability ~= nil) then
			validCollectible = false
			
			if (table.valid(gFishCollectablePresets)) then
				for i,collectable in pairsByKeys(gFishCollectablePresets) do
					if (string.valid(collectable.name) and type(collectable.value) == "number") then
						local itemid = AceLib.API.Items.GetIDByName(collectable.name)
						if (itemid) then
							if (string.contains(tostring(info.itemid),tostring(itemid))) then
								if (info.collectability >= tonumber(collectable.value)) then
									validCollectible = true
								else
									d("Collectibility was too low ["..tostring(info.collectability).."].")
									d("Collectibility Required is ["..tonumber(collectable.value).."].")
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
				local task = ffxiv_fish.currentTask
				if (table.valid(task)) then
					local collectables = task.collectables
					if (table.valid(collectables)) then
						for identifier,minvalue in pairs(collectables) do
							local itemid;
							if (type(identifier) == "string") then
								itemid = AceLib.API.Items.GetIDByName(identifier)
							else
								itemid = identifier
							end
							
							if (itemid) then
								if (string.contains(tostring(info.itemid),tostring(itemid))) then
									if (info.collectability >= tonumber(minvalue)) then
										validCollectible = true
									else
										d("Collectibility was too low ["..tostring(info.collectability).."].")
										d("Collectibility Required is ["..tonumber(minvalue).."].")
									end
								end	
							end
						end
					end
				end
			end
			
			-- needs to be removed
			if (not validCollectible) then
				gd("Cannot collect item ["..info.name.."], collectibility rating not approved.",2)
				UseControlAction(addonName,"No")
			else
				gd("Attempting to collect item ["..info.name.."], collectibility rating approved.",2)
				UseControlAction(addonName,"Yes")
			end
			ml_global_information.Await(3000, function () return not IsControlOpen(addonName) end)	
			return true
		end
	end
	return false
end
function e_collectibleaddonfish:execute()
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_resetidle = inheritsFrom( ml_cause )
e_resetidle = inheritsFrom( ml_effect )
function c_resetidle:evaluate()
	if (ffxiv_fish.attemptedCasts > 0 or ffxiv_fish.biteDetected > 0) then
		local fs = Player:GetFishingState()
		if ( fs == 8 or fs == 9 ) then
			return true
		end
	end
    return false
end
function e_resetidle:execute()
	ml_debug("Resetting idle status, waiting detected.")
	ffxiv_fish.attemptedCasts = 0
	ffxiv_fish.biteDetected = 0
end

c_isfishing = inheritsFrom( ml_cause )
e_isfishing = inheritsFrom( ml_effect )
function c_isfishing:evaluate()
	local fs = Player:GetFishingState()
	if ( not In(fs,0,4) ) then
		return true
	end
    return false
end
function e_isfishing:execute()
	ml_debug("Preventing idle while waiting for bite.")
end

c_buybait = inheritsFrom( ml_cause )
e_buybait = inheritsFrom( ml_effect )
e_buybait.rebuy = {}
function c_buybait:evaluate()
	
	e_buybait.rebuy = {}
	
	local fs = Player:GetFishingState()
    if ((fs == 0 and (not MIsLocked() or IsFlying())) or fs == 4) then
		local baitChoice = ""
		local rebuy = {}
		
		local task = ffxiv_fish.currentTask
		if (table.valid(task) and table.valid(task.rebuy)) then
			local baitVar = IsNull(task.baitvar,"")
			if (baitVar ~= "") then
				if (_G[baitVar] ~= nil) then
					baitChoice = _G[baitVar]
				end
			elseif (HasBuffs(Player,568) and IsNull(task.intuitionbaitname,"") ~= "") then
				baitChoice = task.intuitionbaitname
			else
				baitChoice = IsNull(task.baitname,"")
			end
			rebuy = IsNull(task.rebuy,{})
		else
			return false
		end
		
		local foundSuitable = false
		local baitIDs = {}
		if (baitChoice ~= "") then
			for bait in StringSplit(baitChoice,",") do
				if (tonumber(bait) ~= nil) then
					baitIDs[#baitIDs+1] = tonumber(bait)
					local item = GetItem(tonumber(bait),{0,1,2,3})
					if (item) then
						foundSuitable = true
						break
					end
				else
					local thisID = AceLib.API.Items.GetIDByName(bait)
					if (thisID) then
						baitIDs[#baitIDs+1] = thisID
						local item = GetItem(thisID,{0,1,2,3})
						if (item) then
							foundSuitable = true
							break
						end
					end
				end
			end
		end
		
		if (not foundSuitable) then
			fd("Need to go buy something.",2)
			
			if (table.valid(rebuy)) then
				local rebuyids = {}
				for k,v in pairs(rebuy) do
					if (type(k) == "string") then
						local thisID = AceLib.API.Items.GetIDByName(k)
						if (thisID) then
							rebuyids[thisID] = v
						end
					else
						--if (ItemCount(k) < 1) then
							rebuyids[k] = v
						--end
					end
				end
				
				if (table.valid(rebuyids)) then
					e_buybait.rebuy = rebuyids
					return true
				end
			end
		end
	end
        
    return false
end
function e_buybait:execute()
	if (ffxiv_fish.IsFishing()) then
		ffxiv_fish.StopFishing()
		return
	end
	
	local rebuyids = e_buybait.rebuy
	if (table.valid(rebuyids)) then
		for itemid,buyamount in pairsByKeys(rebuyids) do
			local nearestPurchase = AceLib.API.Items.FindNearestPurchaseLocation(itemid)
			if (nearestPurchase) then
				local newTask = ffxiv_misc_shopping.Create()
				
				newTask["itemid"] = itemid
				newTask["pos"] = nearestPurchase.pos
				newTask["mapid"] = nearestPurchase.mapid
				newTask["id"] = nearestPurchase.id
				newTask["conversationIndex"] = nearestPurchase.index
				newTask["conversationstrings"] = nearestPurchase.indexstrings
				newTask["buyamount"] = buyamount
				
				 ml_task_hub:CurrentTask():AddSubTask(newTask)
				d("Setting up buy task for ["..tostring(itemid).."] @ ["..tostring(nearestPurchase.id).."]")
				d("Nearest Pos:")
				table.print(nearestPurchase.pos)
				table.print(nearestPurchase.indexstrings)
				return true
			end
		end
	end
end

c_setbait = inheritsFrom( ml_cause )
e_setbait = inheritsFrom( ml_effect )
e_setbait.baitid = 0
e_setbait.baitname = ""
function c_setbait:evaluate()
	
	if (Player.ismounted or (not ffxiv_fish.HasDirective() and gFishMarkerOrProfileIndex ~= 3)) then
		return false
	end
	
	local fs = Player:GetFishingState()
    if ((fs == 0 and (not MIsLocked() or IsFlying())) or fs == 4) then
		local baitChoice = ""
		
		local task = ffxiv_fish.currentTask
		local marker = ml_marker_mgr.currentMarker
		if (table.valid(task)) then
			local baitVar = IsNull(task.baitvar,"")
			if (baitVar ~= "") then
				if (_G[baitVar] ~= nil) then
					baitChoice = _G[baitVar]
				end
			elseif (HasBuffs(Player,568) and IsNull(task.intuitionbaitname,"") ~= "") then
				baitChoice = task.intuitionbaitname
			else
				baitChoice = IsNull(task.baitname,"")
			end
		elseif (table.valid(marker)) then
			baitChoice = IsNull(marker.baitname,"")
		elseif gFishMarkerOrProfileIndex == 3 then
			if gFishQuickBait ~= GetString("None") then
				baitChoice = gFishQuickBait
			end
		else
			return false
		end
		
		if (HasBaits(baitChoice)) then
			fd("baitChoice ["..tostring(baitChoice).."].",3)
			local currentBait = IsNull(Player:GetBait(),0)
			if (currentBait == 0) then
				fd("No bait is equipped, need to try to find something.",2)
				return true
			else
				local baitFound = false
				if (ItemCount(currentBait) > 0) then
					fd("Current bait equipped is ["..tostring(currentBait).."].",3)
					
					if (baitChoice ~= "") then
						for bait in StringSplit(baitChoice,",") do
							if (tonumber(bait) ~= nil) then
								if (currentBait == tonumber(bait)) then
									baitFound = true
								end
							else
								fd("Searching for bait ID for ["..IsNull(bait,"").."].",3)
								local thisID = AceLib.API.Items.GetIDByName(bait)
								if (thisID) then
									if (currentBait == thisID) then
										fd("Found the equipped bait, and it is the one we want, and we have at least 1, processing will cease.",3)
										baitFound = true
									end
								end
							end
						end
					else
						fd("No bait choices selected, processing will cease.",3)
						return false
					end
				else
					fd("Current bait equipped is ["..tostring(currentBait).."], but we appear to have used it all, force a re-select.",3)
				end
				
				if (not baitFound) then
					fd("Bait is equipped, but it's not the one we want, need to pick something different.",2)
					return true
				end
			end
		elseif (baitChoice ~= "") then
			d("Problem encountered with fishing task.  Need more bait, but have not set the task up with rebuy ids.")
		end
	end
        
    return false
end
function e_setbait:execute()
	local baitVar = ""
	local baitChoice = ""
	
	local task = ffxiv_fish.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		baitVar = IsNull(task.baitvar,"")
		if (baitVar ~= "") then
			if (_G[baitVar] ~= nil) then
				baitChoice = _G[baitVar]
			end
		elseif (HasBuffs(Player,568) and IsNull(task.intuitionbaitname,"") ~= "") then
			baitChoice = task.intuitionbaitname
		else
			baitChoice = IsNull(task.baitname,"")
		end
	elseif (table.valid(marker)) then
		baitChoice = marker.baitname or ""
	elseif gFishMarkerOrProfileIndex == 3 then
		baitChoice = gFishQuickBait
	end

	local foundSuitable = false
	local baitIDs = {}
	if (baitChoice ~= "") then
		for bait in StringSplit(baitChoice,",") do
			if (tonumber(bait) ~= nil) then
				baitIDs[#baitIDs+1] = tonumber(bait)
				local item = GetItem(tonumber(bait),{0,1,2,3})
				if (item) then
					Player:SetBait(item.id)
					foundSuitable = true
					break
				end
			else
				local thisID = AceLib.API.Items.GetIDByName(bait)
				if (thisID) then
					baitIDs[#baitIDs+1] = thisID
					local item = GetItem(thisID,{0,1,2,3})
					if (item) then
						Player:SetBait(item.id)
						foundSuitable = true
						break
					end
				end
			end
		end
	end
end

c_nextfishingmarker = inheritsFrom( ml_cause )
e_nextfishingmarker = inheritsFrom( ml_effect )
function c_nextfishingmarker:evaluate()
	if (gBotMode ~= GetString("fishMode")) or (gBotMode == GetString("fishMode") and gFishMarkerOrProfileIndex ~= 1) then
		return false
	end
	
	e_nextfishingmarker.marker = nil
	
	local filter = "mapid="..tostring(Player.localmapid)
	if (gMarkerMgrMode ~= GetString("Single Marker")) then
		filter = filter..",minlevel<="..tostring(Player.level)..",maxlevel>="..tostring(Player.level)
	end
	
	local currentMarker = ml_marker_mgr.currentMarker
	local marker = nil
	if (currentMarker == nil) then
		marker = ml_marker_mgr.GetNextMarker("Fishing",filter)
	else
		-- check if we've attempted a lot of casts with no bites
		if (marker == nil) then
			if (ffxiv_fish.attemptedCasts > 2) then
				marker = ml_marker_mgr.GetNextMarker("Fishing",filter)
			end
		end
		
		-- next check to see if our level is out of range
		if (marker == nil) then
			if (not gMarkerMgrMode == GetString("Single Marker")) and (Player.level < currentMarker.minlevel or Player.level > currentMarker.maxlevel) then
				marker = ml_marker_mgr.GetNextMarker("Fishing", filter)
			end
		end
		
		-- last check if our time has run out
		if (marker == nil) then
			if (currentMarker.duration > 0) then
				if (currentMarker:GetTimeRemaining() <= 0) then
					ml_debug("Getting Next Marker, TIME IS UP!")
					marker = ml_marker_mgr.GetNextMarker("Fishing", filter)
				else
					return false
				end
			else
				return false
			end
		end
	end
	
	
	
	if (marker ~= nil) then
		e_nextfishingmarker.marker = marker
		return true
	end
    
    return false
end
function e_nextfishingmarker:execute()
	local fs = Player:GetFishingState()
	if (fs ~= 0) then
		local finishcast = SkillMgr.GetAction(299,1)
		if (finishcast and finishcast:IsReady(Player.id)) then
			finishcast:Cast()
		end
		return
	end
							
	ml_marker_mgr.currentMarker = e_nextfishingmarker.marker
	ml_marker_mgr.currentMarker:StartTimer()
    ml_global_information.MarkerMinLevel = ml_marker_mgr.currentMarker.minlevel
    ml_global_information.MarkerMaxLevel = ml_marker_mgr.currentMarker.maxlevel
	gStatusMarkerName = ml_marker_mgr.currentMarker.name
	ml_task_hub:CurrentTask().requiresAdjustment = true
	ffxiv_fish.attemptedCasts = 0
end

c_fishnexttask = inheritsFrom( ml_cause )
e_fishnexttask = inheritsFrom( ml_effect )
c_fishnexttask.blockOnly = false
c_fishnexttask.postpone = 0
c_fishnexttask.subset = {}
c_fishnexttask.subsetExpiration = 0
function c_fishnexttask:evaluate()
	if (not Player.alive or MIsLoading() or MIsCasting() or not table.valid(ffxiv_fish.profileData)) then
		return false
	end
	
	if ((gBotMode == GetString("fishMode") and gFishMarkerOrProfileIndex ~= 2)) then
		return false
	end
	
	c_fishnexttask.blockOnly = false
	
	local fs = Player:GetFishingState()
	if (fs == 0 or fs == 4) then
	
		fd("Checking if task can be re-evaluated.")
		
		local evaluate = false
		local invalid = false
		local completed = false
		local tempinvalid = false
		local currentTask = ffxiv_fish.currentTask
		local currentTaskIndex = ffxiv_fish.currentTaskIndex
		
		local eTime = GetEorzeaTime()
		local eHour = eTime.bell
		local precedingHour = SubtractHours(eHour,1)
		local eMinute = eTime.minute
		local plevel = Player.level
		
		local weatherAll = AceLib.API.Weather.GetAll()
		local shifts = AceLib.API.Weather.GetShifts()
		local lastShift = shifts.lastShift
		local nextShift = shifts.nextShift
		
		local profileName = (gBotMode == GetString("questMode") and gQuestProfile) or gFishProfile
		
		if (not table.valid(currentTask)) then
			fd("No current task, set invalid flag.")
			invalid = true
		else
			-- Pre-compile all the complete checks so we only have to loadstring once.			
			if (currentTask.complete) then
				d("check currentTask completion")
				local conditions = currentTask.complete
				local complete = false
				
				for condition,value in pairs(conditions) do
					local ok, ret = LoadString("return " .. condition)
					if (ok and ret ~= nil) then
						if (ret == value) then
							d("Task not complete [".. condition .. "] does not meet required value ["..tostring(value).."].")
							complete = true
						end
					end
					if (complete) then
						break
					end
				end
				
				if (complete) then
					invalid = true
					completed = true
					d("Complete")
				end
			end
			
			if (IsNull(currentTask.interruptable,false) or IsNull(currentTask.lowpriority,false) or currentTask.type == "idle" or IsNull(currentTask.idlepriority,false)) then
				d("Task marked interruptable or low priority.")
				evaluate = true
			elseif (not currentTask.weatherlast and not currentTask.weathernow and not currentTask.weathernext and not currentTask.highpriority and
					 not currentTask.eorzeaminhour and not currentTask.eorzeamaxhour and not currentTask.normalpriority)
			then
				d("Task has no high/normal priority markings, allow re-evaluation.")
				evaluate = true
			else
				d("Task didn't fall into an always evaluate.")
			end
			
			if (ffxiv_fish.attemptedCasts > 2) then
				if (table.size(ffxiv_fish.currentTask.attemptedPositions) >= ffxiv_fish.currentTask.maxPositions) then
					ffxiv_fish.SetLockout(profileName,ffxiv_fish.currentTaskIndex)
					invalid = true
				else
					fd("Attempted casts reached 3, check for a new location.")
					local newIndex, newPos = GetNextTaskPos()
					if (newIndex and newPos) then
						ffxiv_fish.currentTask.currentPositionIndex = newIndex
						ffxiv_fish.currentTask.attemptedPositions[newIndex] = true
						ffxiv_fish.attemptedCasts = 0
						ffxiv_fish.currentTask.taskStarted = 0
						ml_task_hub:CurrentTask().requiresRelocate = true
						ml_global_information.lastInventorySnapshot = GetInventorySnapshot()
						c_fishnexttask.blockOnly = true
						return true
					else
						fd("Couldn't find a new location, maybe something went wrong.")
						ffxiv_fish.SetLockout(profileName,ffxiv_fish.currentTaskIndex)
						invalid = true
					end
				end
			end
			
			if (not invalid) then
				if (not table.valid(currentTask.rebuy)) then
					local baitChoice = ""
					local baitVar = IsNull(currentTask.baitvar,"")
					if (baitVar ~= "") then
						if (_G[baitVar] ~= nil) then
							baitChoice = _G[baitVar]
						end
					else
						baitChoice = IsNull(currentTask.baitname,"")
					end
					
					if (not HasBaits(baitChoice)) then
						invalid = true
					end
					
					local intuitionBaitName = IsNull(currentTask.intuitionbaitname,"")
					if intuitionBaitName ~= "" then
						if (not HasBaits(intuitionBaitName)) then
						d("Missing bait for for intuition stage of task")
							invalid = true
						end
					end
				end
			end
			
			if (not invalid) then
				if (currentTask.minlevel and Player.level < currentTask.minlevel) then
					invalid = true
				elseif (currentTask.maxlevel and Player.level > currentTask.maxlevel) then
					invalid = true
				end
			end
			
			if (not invalid) then
				local weather = weatherAll[currentTask.mapid] or { last = "", now = "", next = "" }
				local weatherLast = weather.last or ""
				local weatherNow = weather.now or ""
				local weatherNext = weather.next or ""
			
				if (currentTask.weatherlast) then
					local found = false
					for strWeather in StringSplit(currentTask.weatherlast,",") do
						if (strWeather == weatherLast) then
							found = true
						end
					end
					if (not found) then
						invalid = true
					end
				end
				
				if (currentTask.weathernow) then
					local found = false
					for strWeather in StringSplit(currentTask.weathernow,",") do
						if (strWeather == weatherNow) then
							found = true
						end
					end
					if (not found) then
						invalid = true
					end
				end
				
				if (currentTask.weathernext) then
					local found = false
					for strWeather in StringSplit(currentTask.weathernext,",") do
						if (strWeather == weatherNext) then
							found = true
						end
					end
					if (not found) then
						invalid = true
					end
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
					if (currentTask.taskStarted > 0 and (TimeSince(currentTask.taskStarted)/1000) > currentTask.maxtime) then
						invalid = true
					else
						fd("Max time allowed ["..tostring(currentTask.maxtime).."], time passed ["..tostring(TimeSince(currentTask.taskStarted)).."].")
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
						--d("time range is no longer valid, need to break out of this task.")
						invalid = true
					end
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
		
		if (invalid and not tempinvalid) then
			c_fishnexttask.subset[currentTaskIndex] = nil
		end
		
		if (evaluate or invalid) then
			fd("Evaluating tasks.")
			
			local profileData = ffxiv_fish.profileData
			if (table.valid(profileData.tasks)) then
				
				local validTasks = {}
				if (Now() < c_fishnexttask.subsetExpiration) then
					validTasks = c_fishnexttask.subset
				else
					validTasks = deepcopy(profileData.tasks,true)
				
					for i,data in pairsByKeys(validTasks) do
						local thisIndex = i
						local valid = true
						if (data.minlevel and Player.level < data.minlevel) then
						fd("Player to low",1)
							valid = false
						elseif (data.maxlevel and Player.level > data.maxlevel) then
						fd("Player to high",1)
							valid = false
						end
						
						if (valid) then
							local lockout = ffxiv_fish.GetLockout(profileName,i)
							if (lockout ~= 0) then
								local lockoutTime = data.lockout or 300
								
								if (TimePassed(GetCurrentTime(), lockout) < lockoutTime) then
									d("Task ["..tostring(i).."] not valid due to lockout.",3)
									d("Task ["..tostring(i).."] lockout Current Time = ["..tostring(lockout).."].",3)
									d("Task ["..tostring(i).."] lockoutTime max = ["..tostring(lockoutTime).."].",3)
									valid = false
								end
							end
						end
						
						if (valid) then
							if (not table.valid(data.rebuy)) then
								local baitChoice = ""
								local baitVar = IsNull(data.baitvar,"")
								if (baitVar ~= "") then
									if (_G[baitVar] ~= nil) then
										baitChoice = _G[baitVar]
									end
								else
									baitChoice = IsNull(data.baitname,"")
									fd("Task ["..tostring(i).."] has baitChoice ["..tostring(data.baitname).."] is Bait.",1)
								end
								
								if (not HasBaits(baitChoice)) then
									fd("Task ["..tostring(i).."] is missing bait",1)
									valid = false
								end
								
								local intuitionBaitName = IsNull(currentTask.intuitionbaitname,"")
								if intuitionBaitName ~= "" then
									if (not HasBaits(intuitionBaitName)) then
									d("Task ["..tostring(i).."] is missing bait for intuition stage of fishing")
										valid = false
									end
								end
							end
						end
						
						if (valid) then
							local weather = weatherAll[data.mapid] or { last = "", now = "", next = "" }
							local weatherLast = weather.last or ""
							local weatherNow = weather.now or ""
							local weatherNext = weather.next or ""
			
							if (data.weatherlast) then
								local found = false
								for strWeather in StringSplit(data.weatherlast,",") do
									if (strWeather == weatherLast) then
										found = true
									end
								end
								if (not found) then
									valid = false
								end
							end	
							
							if (data.weathernow) then
								local found = false
								for strWeather in StringSplit(data.weathernow,",") do
									if (strWeather == weatherNow) then
										found = true
									end
								end
								if (not found) then
									valid = false
								end
							end	
							
							if (data.weathernext) then
								local found = false
								for strWeather in StringSplit(data.weathernext,",") do
									if (strWeather == weatherNext) then
										found = true
									end
								end
								if (not found) then
									valid = false
								end
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
						end
						
						if (valid) then
							local conditions = data.condition
							if (table.valid(conditions)) then
								valid = TestConditions(conditions)
								if (not valid) then
									fd("Task ["..tostring(i).."] not valid due to conditions.",3)
								end
							end
						end
						
						if (not valid) then
							validTasks[i] = nil
						end
					end
				
					c_fishnexttask.subset = validTasks
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
					c_fishnexttask.subsetExpiration = Now() + expirationDelay
				end
					
				if (table.valid(validTasks)) then
					local highPriority = {}
					local normalPriority = {}
					local lowPriority = {}
					local idlePriority = {}
					
					for i,data in pairsByKeys(validTasks) do
						-- Items with weather requirements go into high priority
						if (data.type == "idle" or data.idlepriority) then
							fd("Added task at ["..tostring(i).."] to the idle queue.")
							idlePriority[i] = data
						elseif (data.highpriority) then
							fd("Added task at ["..tostring(i).."] to the high priority queue.")
							highPriority[i] = data
						elseif (data.normalpriority) then
							fd("Added task at ["..tostring(i).."] to the normal priority queue.")
							normalPriority[i] = data
						elseif (data.lowpriority) then
							fd("Added task at ["..tostring(i).."] to the low priority queue.")
							lowPriority[i] = data
						elseif (data.weatherlast or data.weathernow or data.weathernext) then
							fd("Added task at ["..tostring(i).."] to the high priority queue.")
							highPriority[i] = data
						elseif (data.eorzeaminhour or data.eorzeamaxhour) then
							fd("Added task at ["..tostring(i).."] to the normal priority queue.")
							normalPriority[i] = data
						else
							fd("Added task at ["..tostring(i).."] to the low priority queue.")
							lowPriority[i] = data
						end
					end
					
					local lowestIndex = 9999
					local best = nil
					for i,data in pairsByKeys(highPriority) do
						if ((not best or (best and i < lowestIndex)) and (data.prioritize)) then
							d("[High] Setting best task to ["..tostring(i).."] due to prioritize flag")
							best = data
							lowestIndex = i
						
						elseif ((not best or (best and i < lowestIndex)) and (Player.localmapid == data.mapid)) then
							d("[High] Setting best task to ["..tostring(i).."] due to same map")
							best = data
							lowestIndex = i
						elseif (not best or (best and i < lowestIndex)) then
						
							d("[High] Setting best task to ["..tostring(i).."]")
							
							best = data
							lowestIndex = i
						end
					end
					
					if (not best and (invalid or currentTask.lowpriority or currentTask.idlepriority or currentTask.type == "idle")) then
						
						for i,data in pairsByKeys(normalPriority) do
							if ((not best or (best and i < lowestIndex)) and (Player.localmapid == data.mapid)) then
							
								d("[Normal] Setting best task to ["..tostring(i).."]")
								
								best = data
								lowestIndex = i
							
							
							elseif (not best or (best and i < lowestIndex)) then
							
								d("[Normal] Setting best task to ["..tostring(i).."]")
								
								best = data
								lowestIndex = i
							end
						end
					end
					
					if (not best and (invalid or currentTask.type == "idle" or currentTask.idlepriority)) then
						
						for i,data in pairsByKeys(lowPriority) do
							if (i > currentTaskIndex) then
								if (not best or (best and i < lowestIndex)) then
									
									d("[Low] Setting best task to ["..tostring(i).."]")
									
									best = data
									lowestIndex = i
								end
							end
						end
						
						if (not best) then
							for i,data in pairsByKeys(lowPriority) do
								if (not best or (best and i < lowestIndex)) then
									
									d("[Low] Setting best task to ["..tostring(i).."]")
									
									best = data
									lowestIndex = i
								end
							end
						end
					end
					
					if (not best and invalid and currentTask.type ~= "idle" and not currentTask.idlepriority) then
						
						for i,data in pairsByKeys(idlePriority) do
							if (i > currentTaskIndex) then
								if (not best or (best and i < lowestIndex)) then
									
									d("[Idle] Setting best task to ["..tostring(i).."]")
									
									best = data
									lowestIndex = i
								end
							end
						end
						
						if (not best) then
							for i,data in pairsByKeys(idlePriority) do
								if (not best or (best and i < lowestIndex)) then
									
									d("[Idle] Setting best task to ["..tostring(i).."]")
									
									best = data
									lowestIndex = i
								end
							end
						end
					end
					
					if (best) then
						if (ffxiv_fish.currentTaskIndex ~= lowestIndex) then
							d("Chose task index ["..tostring(lowestIndex).."] as the next index.",2)
							
							local fs = Player:GetFishingState()
							if (fs ~= 0) then
								local finishcast = SkillMgr.GetAction(299,1)
								if (finishcast and finishcast:IsReady(Player.id)) then
									finishcast:Cast()
								end
								return
							end
	
							
							ffxiv_fish.currentTaskIndex = lowestIndex
							ffxiv_fish.currentTask = best
							d("New task id = "..tostring(lowestIndex))
							return true
						else
							fd("[FishNextTask] Current index is already set to the lowest index.")
						end
					else
						fd("[FishNextTask] Had no better tasks.")
					end
				end
			end
		end
	end
	
	return false
end
function e_fishnexttask:execute()
	if (c_fishnexttask.blockOnly) then
		return
	end
	
	local taskName = ffxiv_fish.currentTask.name or ffxiv_fish.currentTaskIndex
	gStatusTaskName = taskName
	
	if (gBotMode == GetString("questMode")) then
		gQuestStepType = "fish - ["..tostring(taskName).."]"
	end
	
	ml_marker_mgr.currentMarker = nil
	gStatusMarkerName = ""
	
	ffxiv_fish.currentTask.taskStarted = 0
	ffxiv_fish.attemptedCasts = 0
	ffxiv_fish.currentTask.currentPositionIndex = 0
	ffxiv_fish.currentTask.maxPositions = 0
	ffxiv_fish.currentTask.attemptedPositions = {}
	if (table.valid(ffxiv_fish.currentTask.multipos)) then
		ffxiv_fish.currentTask.maxPositions = table.size(ffxiv_fish.currentTask.multipos)
		local newIndex, newPos = GetNextTaskPos()
		if (newIndex and newPos) then
			ffxiv_fish.currentTask.currentPositionIndex = newIndex
			ffxiv_fish.currentTask.attemptedPositions[newIndex] = true
		end
	end
	ml_task_hub:CurrentTask().requiresRelocate = true
	ml_global_information.lastInventorySnapshot = GetInventorySnapshot()
end

c_fishnextprofilemap = inheritsFrom( ml_cause )
e_fishnextprofilemap = inheritsFrom( ml_effect )
e_fishnextprofilemap.mapid = 0
function c_fishnextprofilemap:evaluate()

	e_fishnextprofilemap.mapid = 0
	
	local task = ffxiv_fish.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		if (task.mapid and Player.localmapid ~= task.mapid) then
			e_fishnextprofilemap.mapid = task.mapid
			return true
		end
	elseif (table.valid(marker)) then
		if (marker.mapid and Player.localmapid ~= marker.mapid) then
			e_fishnextprofilemap.mapid = marker.mapid
			return true
		end
	end
	
    return false
end
function e_fishnextprofilemap:execute()
	local fs = Player:GetFishingState()
	if (fs ~= 0) then
		local finishcast = SkillMgr.GetAction(299,1)
		if (finishcast and finishcast:IsReady(Player.id)) then
			finishcast:Cast()
		end
		return
	end

	local mapID = e_fishnextprofilemap.mapid
	local taskPos = GetCurrentTaskPos()
	
	local pos = ml_nav_manager.GetNextPathPos(Player.pos,Player.localmapid,mapID)
	if(table.valid(pos)) then		
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
		
		--ffxiv_dialog_manager.IssueStopNotice("Fish_NextTask", "No path found from map "..tostring(Player.localmapid).." to map "..tostring(mapID))
	end
end

c_fishnextprofilepos = inheritsFrom( ml_cause )
e_fishnextprofilepos = inheritsFrom( ml_effect )
c_fishnextprofilepos.blockOnly = false
c_fishnextprofilepos.distance = 0
function c_fishnextprofilepos:evaluate()
    if (not table.valid(ffxiv_fish.currentTask)) then
		return false
	end
	
	c_fishnextprofilepos.blockOnly = false
	c_fishnextprofilepos.distance = 0
    
	local task = ffxiv_fish.currentTask
	if (task.mapid == Player.localmapid) then
		local pos = GetCurrentTaskPos()
		local myPos = Player.pos
		local dist = math.distance3d(myPos.x, myPos.y, myPos.z, pos.x, pos.y, pos.z)
		if (dist > 3 or ml_task_hub:CurrentTask().requiresRelocate) then
			c_fishnextprofilepos.distance = dist
			return true
		elseif (Player.ismounted) then
			Dismount()
			c_fishnextprofilepos.blockOnly = true
			return true
		end
	end
    
    return false
end
function e_fishnextprofilepos:execute()
	if (c_fishnextprofilepos.blockOnly) then
		return true
	end
	
	local fs = Player:GetFishingState()
	if (fs ~= 0) then
		local finishcast = SkillMgr.GetAction(299,1)
		if (finishcast and finishcast:IsReady(Player.id)) then
			if (finishcast:Cast()) then
				ml_global_information.Await(3000, function () return (Player:GetFishingState() == 0) end)
			end				
		end
		return
	end
	
    local newTask = ffxiv_task_movetopos.Create()
	local task = ffxiv_fish.currentTask
	local taskPos = GetCurrentTaskPos()
	newTask.pos = taskPos
	newTask.range = 1
	newTask.doFacing = true
	
	if (CanFlyInZone() and c_fishnextprofilepos.distance > 40 and not gTeleportHack) then
		local flightApproach, approachDist = AceLib.API.Math.GetFlightApproach(taskPos)
		if (flightApproach and approachDist < 30) then
			newTask.pos = flightApproach
			newTask.range = 5
			newTask.doFacing = false
		end
	end
	
	if (gTeleportHack) then
		newTask.useTeleport = true
	end
	newTask.stealthFunction = ffxiv_fish.NeedsStealth
	
	ml_task_hub:CurrentTask().requiresRelocate = false
	ml_task_hub:CurrentTask().requiresAdjustment = true
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_fishisloading = inheritsFrom( ml_cause )
e_fishisloading = inheritsFrom( ml_effect )
function c_fishisloading:evaluate()
	return MIsLoading()
end
function e_fishisloading:execute()
	ml_debug("Character is loading, prevent other actions and idle.")
end

c_fishfirstrun = inheritsFrom( ml_cause )
e_fishfirstrun = inheritsFrom( ml_effect )
function c_fishfirstrun:evaluate()
	local firstRun = ffxiv_fish.firstRun
	local profileData = ffxiv_fish.profileData
	if (table.valid(profileData) and table.valid(profileData.functions)) then
		if (profileData.functions.firstrun and type(profileData.functions.firstrun) == "function") then
			firstRun = profileData.functions.firstrun
		end
	end
	
	if (firstRun and type(firstRun) == "function" and not ffxiv_fish.firstRunCompleted) then
		local ok, ret = pcall(ffxiv_fish.firstRun)
		if (ok and ret ~= nil) then
			ffxiv_fish.firstRunCompleted = ret
		else
			ffxiv_fish.firstRunCompleted = true
		end
	end
end
function e_fishfirstrun:execute()
	fd("Executing fishing first run tasks.",2)
end

c_fishnoactivity = inheritsFrom( ml_cause )
e_fishnoactivity = inheritsFrom( ml_effect )
function c_fishnoactivity:evaluate()
	if (not ffxiv_fish.HasDirective()) then
		local cast = SkillMgr.GetAction(289,1)
		local fs = Player:GetFishingState()
		if ((not cast or not cast:IsReady(Player.id)) and fs == 0) then
			ml_global_information.Await(1000)
			return true
		end
	end
	return false
end
function e_fishnoactivity:execute()
	-- Do nothing here, but there's no point in continuing to process and eat CPU.
end

function ffxiv_fish.NeedsCordialCheck()
	local useCordials = (gFishUseCordials)
	local task = ffxiv_fish.currentTask
	if (table.valid(task)) then
		useCordials = IsNull(task.usecordials,useCordials)
	end
	
	if (type(useCordials) == "string" and GUI_Get(useCordials) ~= nil) then
		useCordials = GUI_Get(useCordials)
	end

	if (useCordials) then
		local canUse,cordialItem = CanUseCordialSoon()
		if (canUse and table.valid(cordialItem)) then
			return true
		end					
	end
	return false
end

function ffxiv_fish.NeedsPatienceCheck()
	local usePatience = false
	local usePatience2 = false
		local patienceWithIntuition = true
		local patienceWithoutIntuition = true
	
	local task = ffxiv_fish.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		local patienceVar = IsNull(task.patiencevar,"")
		if (patienceVar ~= "" and _G[patienceVar] ~= nil) then
			patienceVar = _G[patienceVar]
			if (patienceVar == "Patience") then
				usePatience = true
			elseif (patienceVar == "Patience II") then
				usePatience2 = true
			end
		else
			usePatience = IsNull(task.usepatience,false)
			usePatience2 = IsNull(task.usepatience2,false)
			patienceWithIntuition = IsNull(task.moochwithintuition,true)
			patienceWithoutIntuition = IsNull(task.moochwithoutintuition,true)
		end
	elseif (table.valid(marker)) then
		usePatience = IsNull(marker.usepatience,false)
		usePatience2 = IsNull(marker.usepatience2,false)
	end
	
	if (type(usePatience) == "string" and GUI_Get(usePatience) ~= nil) then
		usePatience = GUI_Get(usePatience)
	end
	if (type(usePatience2) == "string" and GUI_Get(usePatience2) ~= nil) then
		usePatience2 = GUI_Get(usePatience2)
	end
	if (usePatience or usePatience2) then
		if ((HasBuffs(Player,568) and moochWithIntuition) or (MissingBuffs(Player,568) and moochWithoutIntuition)) then
			return true
		end
	end
			
	return false
end

function ffxiv_fish.NeedsStealth()
	if (MIsCasting() or MIsLoading() or IsFlying() or Player.incombat) then
		return false
	end

	local useStealth = false
	local task = ffxiv_fish.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		useStealth = IsNull(task.usestealth,false)
	elseif (table.valid(marker)) then
		useStealth = IsNull(marker.usestealth,false)
	end
	
	if (type(useStealth) == "string" and GUI_Get(useStealth) ~= nil) then
		useStealth = GUI_Get(useStealth)
	end
	
	if (useStealth) then	
		local stealth = SkillMgr.GetAction(298,1)
		if (stealth) then
			local dangerousArea = false
			local myPos = Player.pos
			local destPos = ml_task_hub:CurrentTask().pos
			local task = ffxiv_fish.currentTask
			local marker = ml_marker_mgr.currentMarker
			if (table.valid(task)) then
				dangerousArea = IsNull(task.dangerousarea,false)
			elseif (table.valid(marker)) then
				dangerousArea = IsNull(marker.dangerousarea,false)
			end
			
			if (type(dangerousArea) == "string" and GUI_Get(dangerousArea) ~= nil) then
				dangerousArea = GUI_Get(dangerousArea)
			end
		
			if (not dangerousArea and ml_task_hub:CurrentTask().name == "MOVETOPOS") then
				local dest = ml_task_hub:CurrentTask().pos
				if (Distance3D(myPos.x,myPos.y,myPos.z,dest.x,dest.y,dest.z) > 75) then
					return false
				end
			end
			
			local distance2d = Distance2D(myPos.x, myPos.z, destPos.x, destPos.z)
			if (distance2d <= 10) then
				local potentialAdds = EntityList("alive,attackable,aggressive,maxdistance=50,minlevel="..tostring(Player.level - 10))
				if (table.valid(potentialAdds)) then
					return true
				end
			end
			
			local addMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(FFXIV_Common_StealthDetect))
			if (table.valid(addMobList)) then
				return true
			end
			
			local hasStealth = HasBuff(Player.id,47)
			if (hasStealth) then
				local removeMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(FFXIV_Common_StealthRemove))
				if (table.valid(removeMobList)) then
					--d("Still detecting enemies, need to keep stealth.")
					return true
				end
			end
		end
	end
	
	return false
end

function ffxiv_fish.IsFishing()
	local fs = Player:GetFishingState()
	if (fs ~= 0) then
		return true
	end
	return false
end

function ffxiv_fish.StopFishing()
	local fs = Player:GetFishingState()
	if (fs ~= 0) then
		local finishcast = SkillMgr.GetAction(299,1)
		if (finishcast and finishcast:IsReady(Player.id)) then
			if (finishcast:Cast()) then
				ml_global_information.Await(3000, function () return (Player:GetFishingState() == 0) end)
			end
		end
	end
end

c_fishstealth = inheritsFrom( ml_cause )
e_fishstealth = inheritsFrom( ml_effect )
e_fishstealth.timer = 0
function c_fishstealth:evaluate()
	if (IsFlying() or ml_task_hub:CurrentTask().name == "MOVE_WITH_FLIGHT") then
		return false
	end

	local useStealth = false
	local task = ffxiv_fish.currentTask
	local marker = ml_marker_mgr.currentMarker
	if (table.valid(task)) then
		useStealth = IsNull(task.usestealth,false)
	elseif (table.valid(marker)) then
		useStealth = IsNull(marker.usestealth,false)
	end
	
	if (type(useStealth) == "string" and GUI_Get(useStealth) ~= nil) then
		useStealth = GUI_Get(useStealth)
	end
	
	if (useStealth) then
		if (Player.incombat) then
			return false
		end
		
		local fs = Player:GetFishingState()
		if (fs ~= 0) then
			return false
		end
		
		local stealth = SkillMgr.GetAction(298,1)
		if (stealth) then
			local dangerousArea = false
			local destPos = {}
			local myPos = Player.pos
			local task = ffxiv_fish.currentTask
			local marker = ml_marker_mgr.currentMarker
			if (table.valid(task)) then
				dangerousArea = IsNull(task.dangerousarea,false)
				destPos = GetCurrentTaskPos()
			elseif (table.valid(marker)) then
				dangerousArea = marker.dangerousarea
				destPos = marker:GetPosition()
			end
		
			if (type(dangerousArea) == "string" and GUI_Get(dangerousArea) ~= nil) then
				dangerousArea = GUI_Get(dangerousArea)
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
			
			local distance = PDistance3D(myPos.x, myPos.y, myPos.z, destPos.x, destPos.y, destPos.z)
			if (distance <= 6) then
				local potentialAdds = EntityList("alive,attackable,aggressive,maxdistance=100,minlevel="..tostring(Player.level - 10))
				if (TableSize(potentialAdds) > 0) then
					if (not HasBuff(Player.id, 47)) then
						return true
					else
						return false
					end
				end
			end
			
			local addMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(FFXIV_Common_StealthDetect))
			local removeMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(FFXIV_Common_StealthRemove))
			
			if(TableSize(addMobList) > 0 and not HasBuff(Player.id, 47)) or
			  (TableSize(removeMobList) == 0 and HasBuff(Player.id, 47)) 
			then
				return true
			end
		end
	else
		if (HasBuffs(Player,"47")) then
			return true
		end
	end
 
    return false
end
function e_fishstealth:execute()
	e_fishstealth.timer = Now() + 3000
	
	local newTask = ffxiv_task_stealth.Create()
	if (HasBuffs(Player,"47")) then
		newTask.droppingStealth = true
	else
		newTask.addingStealth = true
	end
	
	ml_task_hub:ThisTask().preserveSubtasks = true
	ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
end

c_syncadjust = inheritsFrom( ml_cause )
e_syncadjust = inheritsFrom( ml_effect )
function c_syncadjust:evaluate()
	if (Player.ismounted) then
		return false
	end
	
	local cast = SkillMgr.GetAction(289,1)
	if (cast and cast:IsReady(Player.id)) then
		return false
	end
	
	
	
	local fs = Player:GetFishingState()
	if( fs == 0 and ml_task_hub:CurrentTask().requiresAdjustment ) then -- FISHSTATE_BITE
		local currentTask = ffxiv_fish.currentTask
		if currentTask.type ~= "idle" then
			return true
		end
	end
    return false
end
function e_syncadjust:execute()
	local heading;
	local marker = ml_marker_mgr.currentMarker
	local task = ffxiv_fish.currentTask
	if (table.valid(task)) then
		local taskPos = GetCurrentTaskPos()
		heading = taskPos.h
	elseif (table.valid(marker)) then
		local pos = ml_marker_mgr.currentMarker:GetPosition()
		if (pos) then
			heading = pos.h
		end
	end
	
    local newTask = ffxiv_task_syncadjust.Create()
	newTask.heading = heading
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

ffxiv_task_syncadjust = inheritsFrom(ml_task)
function ffxiv_task_syncadjust.Create()
    local newinst = inheritsFrom(ffxiv_task_syncadjust)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_killtarget members
    newinst.name = "SYNC_ADJUSTMENT"
	newinst.timer = 0
	newinst.heading = 0
    
    return newinst
end
function ffxiv_task_syncadjust:Init()	
    self:AddTaskCheckCEs()
end
function ffxiv_task_syncadjust:task_complete_eval()
	Player:SetFacing(self.heading)
	
	if (not Player:IsMoving()) then
		Player:Move(FFXIV.MOVEMENT.FORWARD)
	end
	
	if (self.timer == 0) then
		self.timer = Now() + 300
	elseif (Now() > self.timer) then
		return true
	end

	return false
end
function ffxiv_task_syncadjust:task_complete_execute()
    Player:Stop()
	self:ParentTask().requiresAdjustment = false
	self.completed = true
end

function ffxiv_task_syncadjust:task_fail_eval()
	if (not Player.alive) then
		return true
	end
end

function ffxiv_task_fish:Init()
    --init ProcessOverwatch() cnes
	local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 150 )
    self:add( ke_dead, self.overwatch_elements)
	
	local ke_flee = ml_element:create( "Flee", c_gatherflee, e_gatherflee, 130 )
    self:add( ke_flee, self.overwatch_elements)
	
	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 100 )
    self:add( ke_inventoryFull, self.overwatch_elements)  
	
    --init Process() cnes
	--local ke_autoEquip = ml_element:create( "AutoEquip", c_autoequip, e_autoequip, 250 )
    --self:add( ke_autoEquip, self.process_elements)
	local ke_isLoading = ml_element:create( "IsLoading", c_fishisloading, e_fishisloading, 300 )
    self:add( ke_isLoading, self.process_elements)
	
	local ke_collectible = ml_element:create( "Collectible", c_collectibleaddonfish, e_collectibleaddonfish, 280 )
    self:add( ke_collectible, self.process_elements)
	
	local ke_firstRun = ml_element:create( "FirstRun", c_fishfirstrun, e_fishfirstrun, 260 )
    self:add( ke_firstRun, self.process_elements)
	
	local ke_recommendEquip = ml_element:create( "RecommendEquip", c_recommendequip, e_recommendequip, 250 )
    self:add( ke_recommendEquip, self.process_elements)
	
	local ke_buybait = ml_element:create( "BuyBait", c_buybait, e_buybait, 230 )
	self:add(ke_buybait, self.process_elements)
	
    local ke_resetIdle = ml_element:create( "ResetIdle", c_resetidle, e_resetidle, 200 )
    self:add(ke_resetIdle, self.process_elements)
	
	local ke_nextTask = ml_element:create( "NextTask", c_fishnexttask, e_fishnexttask, 180 )
    self:add( ke_nextTask, self.process_elements)
	
	local ke_nextMarker = ml_element:create( "NextMarker", c_nextfishingmarker, e_nextfishingmarker, 175 )
    self:add( ke_nextMarker, self.process_elements)
	
	--local ke_noActivity = ml_element:create( "NoActivity", c_fishnoactivity, e_fishnoactivity, 150 )
    --self:add( ke_noActivity, self.process_elements)
	
	local ke_nextProfileMap = ml_element:create( "NextProfileMap", c_fishnextprofilemap, e_fishnextprofilemap, 110 )
    self:add( ke_nextProfileMap, self.process_elements)
	
	local ke_nextProfilePos = ml_element:create( "NextProfilePos", c_fishnextprofilepos, e_fishnextprofilepos, 100 )
    self:add( ke_nextProfilePos, self.process_elements)
    
    local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 100 )
    self:add( ke_returnToMarker, self.process_elements)
	
	local ke_setbait = ml_element:create( "SetBait", c_setbait, e_setbait, 90 )
    self:add(ke_setbait, self.process_elements)
	
	local ke_collect = ml_element:create( "Collect", c_usecollect, e_usecollect, 75 )
    self:add(ke_collect, self.process_elements)
	
	local ke_snagging = ml_element:create( "Snagging", c_snagging, e_snagging, 70 )
    self:add(ke_snagging, self.process_elements)
	
	local ke_fisheyes = ml_element:create( "FishEyes", c_fisheyes, e_fisheyes, 65 )
    self:add(ke_fisheyes, self.process_elements)
	
	local ke_chum = ml_element:create( "Chum", c_chum, e_chum, 60 )
    self:add(ke_chum, self.process_elements)
	
	local ke_patience = ml_element:create( "Patience", c_patience, e_patience, 50 )
    self:add(ke_patience, self.process_elements)
	
	local ke_precast = ml_element:create( "PreCast", c_precastbuff, e_precastbuff, 45 )
    self:add(ke_precast, self.process_elements)
		
	local ke_mooch2 = ml_element:create( "Mooch2", c_mooch2, e_mooch2, 42 )
    self:add(ke_mooch2, self.process_elements)
	
	local ke_mooch = ml_element:create( "Mooch", c_mooch, e_mooch, 40 )
    self:add(ke_mooch, self.process_elements)
	
	local ke_release = ml_element:create( "Release", c_release, e_release, 30 )
    self:add(ke_release, self.process_elements)	
	
	local ke_syncadjust = ml_element:create( "SyncAdjust", c_syncadjust, e_syncadjust, 25)
	self:add(ke_syncadjust, self.process_elements)
    
    local ke_cast = ml_element:create( "Cast", c_cast, e_cast, 20 )
    self:add(ke_cast, self.process_elements)
    
    local ke_bite = ml_element:create( "Bite", c_bite, e_bite, 10 )
    self:add(ke_bite, self.process_elements)
	
	local ke_fishing = ml_element:create( "Fishing", c_isfishing, e_isfishing, 1 )
    self:add(ke_fishing, self.process_elements)
   
    self:AddTaskCheckCEs()
end

function ffxiv_task_fish.SetModeOptions()
	ffxiv_fish.profileData = {}
	if (table.valid(ffxiv_fish.profiles)) then
		ffxiv_fish.profileData = ffxiv_fish.profiles[gFishProfile]
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

function ffxiv_task_fish:UIInit()
	ffxiv_fish.profiles, ffxiv_fish.profilesDisplay = GetPublicProfiles(ffxiv_fish.profilePath,".*lua")
	
	local uuid = GetUUID()
	if (Settings.FFXIVMINION.gLastFishProfiles == nil) then
		Settings.FFXIVMINION.gLastFishProfiles = {}
	end
	if (Settings.FFXIVMINION.gLastFishProfiles[uuid] == nil) then
		Settings.FFXIVMINION.gLastFishProfiles[uuid] = {}
	end
	
	_G["gFishProfile"] = Settings.FFXIVMINION.gLastFishProfiles[uuid] or ffxiv_fish.profilesDisplay[1]
	_G["gFishProfileIndex"] = GetKeyByValue(gFishProfile,ffxiv_fish.profilesDisplay) or 1
	if (ffxiv_fish.profilesDisplay[gFishProfileIndex] ~= gFishProfile) then
		_G["gFishProfile"] = ffxiv_fish.profilesDisplay[gFishProfileIndex]
	end
	ffxiv_fish.profileData = ffxiv_fish.profiles[gFishProfile] or {}
	
	
	gFishDebug = ffxivminion.GetSetting("gFishDebug",false)
	local debugLevels = { 1, 2, 3}
	gFishDebugLevel = ffxivminion.GetSetting("gFishDebugLevel",1)
	gFishDebugLevelIndex = GetKeyByValue(gFishDebugLevel,debugLevels)
	
	
	--local uistring = IsNull(AceLib.API.Items.BuildUIString(47,120),"")
	--gFishCollectablesList = { GetString("None") }
	--if (ValidString(uistring)) then
		--for collectable in StringSplit(uistring,",") do
			--table.insert(gFishCollectablesList,collectable)
		--end
	--end
	
	gFishUseCordials = ffxivminion.GetSetting("gFishUseCordials",true)
	gFishCollectablePresets = ffxivminion.GetSetting("gFishCollectablePresets",{})
	
	gFishQuickBait = ffxivminion.GetSetting("gFishQuickBait", GetString("None"))
	local baitKey = { GetString("None"),GetString("Balloon Bug"),GetString("Bass Ball"),GetString("Bladed Steel Jig"),GetString("Bloodworm"),GetString("Blue Bobbit"),GetString("Bream Lure"),GetString("Brute Leech"),GetString("Butterworm"),GetString("Caddisfly Larva"),GetString("Chocobo Fly"),GetString("Crayfish Ball"),GetString("Crow Fly"),GetString("Fiend Worm"),GetString("Floating Minnow"),GetString("Giant Crane Fly"),GetString("Glowworm"),GetString("Goblin Jig"),GetString("Goby Ball"),GetString("Heavy Steel Jig"),GetString("Herring Ball"),GetString("Honey Worm"),GetString("Hoverworm"),GetString("Live Shrimp"),GetString("Lugworm"),GetString("Magma Worm"),GetString("Midge Basket"),GetString("Midge Larva"),GetString("Moth Pupa"),GetString("Nightcrawler"),GetString("Northern Krill"),GetString("Pill Bug"),GetString("Purse Web Spider"),GetString("Rainbow Spoon Lure"),GetString("Rat Tail"),GetString("Red Balloon"),GetString("Salmon Roe"),GetString("Sand Leech"),GetString("Sand Gecko"),GetString("Silkworm"),GetString("Silver Spoon Lure"),GetString("Sinking Minnow"),GetString("Spinner"),GetString("Spinnerbait"),GetString("Spoon Worm"),GetString("Snurble Fly"),GetString("Steel Jig"),GetString("Stem Borer"),GetString("Stonefly Larva"),GetString("Stonefly Nymph"),GetString("Streamer"),GetString("Suspending Minnow"),GetString("Syrphid Basket"),GetString("Topwater Frog"),GetString("Wildfowl Fly"),GetString("Yumizuno")}
	gFishBaitIndex = GetKeyByValue(gFishQuickBait,baitKey)
	
	gQuickstartMooch = ffxivminion.GetSetting("gQuickstartMooch",false)
	gQuickstartMooch2 = ffxivminion.GetSetting("gQuickstartMooch2",false)
	gQuickstartPatience = ffxivminion.GetSetting("gQuickstartPatience",false)
	gQuickstartPatience2 = ffxivminion.GetSetting("gQuickstartPatience2",false)
	gQuickstartSnagging = ffxivminion.GetSetting("gQuickstartSnagging",false)
	gQuickstartFishEyes = ffxivminion.GetSetting("gQuickstartFishEyes",false)
	gQuickstartChum = ffxivminion.GetSetting("gQuickstartChum",false)
	gQuickstartDH = ffxivminion.GetSetting("gQuickstartDH",false)
	
	-- New Marker/Profile Settings
	gFishMarkerOrProfileOptions = { GetString("Markers"), GetString("Profile"), GetString("Quick Start Mode") }
	gFishMarkerOrProfile = ffxivminion.GetSetting("gFishMarkerOrProfile",GetString("Markers"))
	gFishMarkerOrProfileIndex = ffxivminion.GetSetting("gFishMarkerOrProfileIndex",1)	
	self.GUI = {}
	-- Load correct tabs for current mode on inital run.
	if gFishMarkerOrProfileIndex == 1 then
		self.GUI.main_tabs = GUI_CreateTabs("Marker Lists,Settings,Collectable,Debug",true)
	elseif gFishMarkerOrProfileIndex == 2 then
		self.GUI.main_tabs = GUI_CreateTabs("Settings,Collectable,Debug",true)
	elseif gFishMarkerOrProfileIndex == 3 then
		self.GUI.main_tabs = GUI_CreateTabs("Quick Start,Settings,Collectable,Debug",true)
	end
	self.GUI.profile = {
		open = false,
		visible = true,
		name = "Fish - Profile Management",
		main_tabs = GUI_CreateTabs("Manage,Add,Edit",true),
	}
end

function ffxiv_task_fish:Draw()
	local tabindex, tabname = GUI_DrawTabs(self.GUI.main_tabs)
	if FFXIV_Common_BotRunning then 
		local currentMarker = ml_marker_mgr.currentMarker
		if (currentMarker ~= nil) then
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
		local profiletask = ffxiv_fish.currentTask
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
			local taskName = ffxiv_fish.currentTask.name or ffxiv_fish.currentTaskIndex
			GUI:InputText("##taskName",taskName,GUI.InputTextFlags_ReadOnly)
			GUI:PopItemWidth()
			GUI:Columns()
		end	
	GUI:Separator()
	end
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Fish Mode")
	GUI:SameLine()
	local MarkerOrProfileWidth = GUI:GetContentRegionAvail() 
	GUI:PushItemWidth(MarkerOrProfileWidth-8)
	local MarkerOrProfile = GUI_Combo("##FishMarkerOrProfile", "gFishMarkerOrProfileIndex", "gFishMarkerOrProfile", gFishMarkerOrProfileOptions)
	if (MarkerOrProfile) then
		-- Update tabs on change.
		-- Load correct tabs for current mode on inital run.
		if gFishMarkerOrProfileIndex == 1 then
			self.GUI.main_tabs = GUI_CreateTabs("Marker Lists,Settings,Collectable,Debug",true)
		elseif gFishMarkerOrProfileIndex == 2 then
			self.GUI.main_tabs = GUI_CreateTabs("Settings,Collectable,Debug",true)
		elseif gFishMarkerOrProfileIndex == 3 then
			self.GUI.main_tabs = GUI_CreateTabs("Quick Start,Settings,Collectable,Debug",true)
		end
	end
	GUI:PopItemWidth()
	-- Marker Options
	if gFishMarkerOrProfileIndex == 1 then
		if gFishProfileIndex ~= 1 or gFishProfile ~= GetString("None")then
			gFishProfileIndex = 1
			gFishProfile = GetString("None")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Marker Mode")
		GUI:SameLine()
		local MarkerModeWidth = GUI:GetContentRegionAvail() 
		GUI:PushItemWidth(MarkerModeWidth-8)
		local modeChanged = GUI_Combo("##Marker Mode", "gMarkerModeIndex", "gMarkerMode", ml_marker_mgr.modesDisplay)
		if (modeChanged) then
			local uuid = GetUUID()
			if ( string.valid(uuid) ) then
				if  ( Settings.minionlib.gMarkerModes == nil ) then Settings.minionlib.gMarkerModes = {} end
				Settings.minionlib.gMarkerModes[uuid] = ml_marker_mgr.modes[gMarkerModeIndex]
			end
		end
	-- Profile Options
	elseif gFishMarkerOrProfileIndex == 2 then
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Profile"))
		GUI:SameLine()
		local profileWidth = GUI:GetContentRegionAvail() 
		GUI:PushItemWidth(profileWidth-8)
		local profileChanged = GUI_Combo("##"..GetString("Profile"), "gFishProfileIndex", "gFishProfile", ffxiv_fish.profilesDisplay)
		if (profileChanged) then
			ffxiv_fish.profileData = ffxiv_fish.profiles[gFishProfile]
			local uuid = GetUUID()
			Settings.FFXIVMINION.gLastFishProfiles[uuid] = gFishProfile
		end
		GUI:PopItemWidth()
		if gGatherProfileIndex == 1 and (gFishProfileIndex == 1 or gFishProfile == GetString("None")) then
			GUI:TextColored(1,.1,.2,1,"No Profile Selected.")
			if (FFXIV_Common_BotRunning) then
				ml_global_information:ToggleRun()
				d("Please select/create a valid Profile.")
			end
		end
	end
	-- Settings
	if (tabname == GetString("Settings")) then
		
		GUI:Columns(2)
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use Exp Manuals"))
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Allow use of Experience boost manuals.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Use Cordials")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Allow use of Cordials for GP.")
		end
		GUI:NextColumn()
		GUI_Capture(GUI:Checkbox("##"..GetString("Use Exp Manuals"),gUseExpManuals),"gUseExpManuals")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Allow use of Experience boost manuals.")
		end
		GUI_Capture(GUI:Checkbox("##Use Cordials",gFishUseCordials),"gFishUseCordials");
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Allow use of Cordials for GP.")
		end
		GUI:Columns()
		--Stealth Settings
		GUI:Separator()
		GUI:Columns(2)
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Stealth - Detect Range")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Enemy range before applying Stealth.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Stealth - Remove Range")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Enemy range before removing Stealth.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Smart Stealth")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Smarter Stealth based on players direction and mob.")
		end
		GUI:NextColumn()
		local StealthWidth = GUI:GetContentRegionAvail()
		GUI:PushItemWidth(StealthWidth)
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
	end
	-- Collectables
	if (tabname == GetString("Collectable")) then
		local CollectableFullWidth = GUI:GetContentRegionAvail()-8
		if (GUI:Button("Use Known Defaults",CollectableFullWidth,20)) then
			GUI_Set("gFishCollectablePresets",{})
			for k,v in pairs(ffxiv_fish.collectibles) do
				local newCollectable = { name = v.name, value = v.minimum }
				table.insert(gFishCollectablePresets,newCollectable)
			end
			GUI_Set("gFishCollectablePresets",gFishCollectablePresets)
		end
		if (GUI:Button("Add Collectable",CollectableFullWidth,20)) then
			local newCollectable = { name = "", value = 0 }
			table.insert(gFishCollectablePresets,newCollectable)
			GUI_Set("gFishCollectablePresets",gFishCollectablePresets)
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
		if (table.valid(gFishCollectablePresets)) then
			GUI:Columns(2)
			for i,collectable in pairsByKeys(gFishCollectablePresets) do
				GUI:PushItemWidth(CollectableWidth1-8)
				local newName = GUI:InputText("##fish-collectablepair-name"..tostring(i),collectable.name)
				if (newName ~= collectable.name) then
					gFishCollectablePresets[i].name = newName
					GUI_Set("gFishCollectablePresets",gFishCollectablePresets)
				end
				if (GUI:IsItemHovered()) then
					GUI:SetTooltip("Case-sensitive item name for the item to become a collectable.")
				end
				GUI:PopItemWidth()
				GUI:NextColumn()
				GUI:PushItemWidth(CollectableWidth2-28)
				local newValue = GUI:InputInt("##fish-collectablepair-value"..tostring(i),collectable.value,0,0)
				if (newValue ~= collectable.value) then
					gFishCollectablePresets[i].value = newValue
					GUI_Set("gFishCollectablePresets",gFishCollectablePresets)
				end
				if (GUI:IsItemHovered()) then
					GUI:SetTooltip("Minimum collectable value at which the item will be accepted as a collectable.")
				end
				GUI:PopItemWidth()
				GUI:SameLine()
				GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
				--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
				GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
				if (GUI:ImageButton("##fish-collectablepair-delete"..tostring(i),ml_global_information.path.."\\GUI\\UI_Textures\\bt_alwaysfail_fail.png", 14, 14)) then
					gFishCollectablePresets[i] = nil
					GUI_Set("gFishCollectablePresets",gFishCollectablePresets)
				end
				GUI:PopStyleColor(2)
				GUI:NextColumn()
			end
		GUI:Columns()
		end
	end
	-- Fish Mode
	if (tabname == GetString("Marker Lists")) then
		local currentMode = ml_marker_mgr.modes[gMarkerModeIndex]
		local currentType = ml_marker_mgr.templateDisplayMap[gMarkerType]
		local currentMap = ml_marker_mgr.activeMap
		local currentList = ml_marker_mgr.GetList(currentMode,currentType,currentMap)
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Marker Type")
		GUI:SameLine()
		local MarkerTypeWidth = GUI:GetContentRegionAvail()
		GUI:PushItemWidth(MarkerTypeWidth-8)
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
			GUI:TextWrapped("No Markers exist for "..gMarkerType.." - "..gMarkerMode)
			GUI:TextWrapped("Set Markers and Marker Type Prior to enabling Bot")
			if (FFXIV_Common_BotRunning) then
				d("No Markers exist for "..gMarkerType.." - "..gMarkerMode)
				ml_global_information:ToggleRun()
			end
		end
		GUI:EndChild()
	end
	if (tabname == GetString("Quick Start")) then
		GUI:BeginChild("##header-QS",-8,GUI_GetFrameHeight(9),true)
		GUI:Columns(2)
		
	
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Bait Type")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Select the bait you would like to use.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Mooch")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Allow fish mooching.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Mooch II")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Allow fish mooching (Mooch 2).")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Patience")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Use Patience while fishing.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Patience II")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Use Patience 2 while fishing.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Snagging")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Apply the Snagging buff when fishing.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Fish Eyes")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Apply the Fish Eyes buff when fishing.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Chum")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Use Chum while fishing.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Double Hook")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Use Double Hook.")
		end
		
		GUI:NextColumn()
		
		local MarkerTypeWidth = GUI:GetContentRegionAvail()
		GUI:PushItemWidth(MarkerTypeWidth-8)
		local baitKey = { GetString("None"),GetString("Balloon Bug"),GetString("Bass Ball"),GetString("Bladed Steel Jig"),GetString("Bloodworm"),GetString("Blue Bobbit"),GetString("Bream Lure"),GetString("Brute Leech"),GetString("Butterworm"),GetString("Caddisfly Larva"),GetString("Chocobo Fly"),GetString("Crayfish Ball"),GetString("Crow Fly"),GetString("Fiend Worm"),GetString("Floating Minnow"),GetString("Giant Crane Fly"),GetString("Glowworm"),GetString("Goblin Jig"),GetString("Goby Ball"),GetString("Heavy Steel Jig"),GetString("Herring Ball"),GetString("Honey Worm"),GetString("Hoverworm"),GetString("Live Shrimp"),GetString("Lugworm"),GetString("Magma Worm"),GetString("Midge Basket"),GetString("Midge Larva"),GetString("Moth Pupa"),GetString("Nightcrawler"),GetString("Northern Krill"),GetString("Pill Bug"),GetString("Purse Web Spider"),GetString("Rainbow Spoon Lure"),GetString("Rat Tail"),GetString("Red Balloon"),GetString("Salmon Roe"),GetString("Sand Leech"),GetString("Sand Gecko"),GetString("Silkworm"),GetString("Silver Spoon Lure"),GetString("Sinking Minnow"),GetString("Spinner"),GetString("Spinnerbait"),GetString("Spoon Worm"),GetString("Snurble Fly"),GetString("Steel Jig"),GetString("Stem Borer"),GetString("Stonefly Larva"),GetString("Stonefly Nymph"),GetString("Streamer"),GetString("Suspending Minnow"),GetString("Syrphid Basket"),GetString("Topwater Frog"),GetString("Wildfowl Fly"),GetString("Yumizuno")}
		gFishBaitIndex = GetKeyByValue(gFishQuickBait,baitKey) or GetString("None")
		if (baitKey[gFishBaitIndex] ~= gFishQuickBait) then
			gFishQuickBait = baitKey[gFishBaitIndex]
		end
		GUI_Combo("##BaitLevels", "gFishBaitIndex", "gFishQuickBait", baitKey)
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Select the bait you would like to use.")
		end
		-- Quick Start Toggles.
		GUI_Capture(GUI:Checkbox("##Mooch",gQuickstartMooch),"gQuickstartMooch")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Allow fish mooching.")
		end
		GUI_Capture(GUI:Checkbox("##Mooch2",gQuickstartMooch2),"gQuickstartMooch2")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Allow fish mooching (Mooch 2).")
		end
		GUI_Capture(GUI:Checkbox("##Patience",gQuickstartPatience),"gQuickstartPatience")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Use Patience while fishing.")
		end
		GUI_Capture(GUI:Checkbox("##Patience2",gQuickstartPatience2),"gQuickstartPatience2")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Use Patience 2 while fishing.")
		end
		GUI_Capture(GUI:Checkbox("##Snagging",gQuickstartSnagging),"gQuickstartSnagging")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Apply the Snagging buff when fishing.")
		end
		GUI_Capture(GUI:Checkbox("##Fish Eyes",gQuickstartFishEyes),"gQuickstartFishEyes")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Apply the Fish Eyes buff when fishing.")
		end
		GUI_Capture(GUI:Checkbox("##Chum",gQuickstartChum),"gQuickstartChum")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Use Chum while fishing.")
		end
		GUI_Capture(GUI:Checkbox("##Double Hook",gQuickstartDH),"gQuickstartDH")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Use Double Hook.")
		end
		
		GUI:Columns()
		GUI:EndChild()
	end
		
	-- Debug Tab
	if (tabname == GetString("Debug")) then
		GUI:BeginChild("##header-debug",-8,GUI_GetFrameHeight(2),true)
		GUI:Columns(2)
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Fish Debug")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Enable Debug messages in console.")
		end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text("Debug Level")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Change the Debug message level. (The higher the number the more detailed the messages)")
		end
		GUI:NextColumn()
		
		
		GUI_Capture(GUI:Checkbox("##Fish Debug",gFishDebug),"gFishDebug")
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Enable Debug messages in console.")
		end
		local DebugWidth = GUI:GetContentRegionAvail()
		GUI:PushItemWidth(DebugWidth)
		
		local debugLevels = { 1, 2, 3}
		gFishDebugLevelIndex = GetKeyByValue(gFishDebugLevel,debugLevels) or 1
		if (debugLevels[gFishDebugLevelIndex] ~= gFishDebugLevel) then
			gFishDebugLevel = debugLevels[gFishDebugLevelIndex]
		end
		GUI_Combo("##Debug Level", "gFishDebugLevelIndex", "gFishDebugLevel", debugLevels)
		if (GUI:IsItemHovered()) then 
			GUI:SetTooltip("Change the Debug message level. (The higher the number the more detailed the messages)")
		end
		GUI:PopItemWidth()
		GUI:Columns()
		GUI:EndChild()
	end
end

function ffxiv_fish.GetLockout(profile,task)
	if (Settings.FFXIVMINION.gFishLockout ~= nil) then
		lockout = Settings.FFXIVMINION.gFishLockout
		if (table.valid(lockout[profile])) then
			return lockout[profile][task] or 0
		end
	end
	
	return 0
end
function ffxiv_fish.SetLockout(profile,task)
	local profile = IsNull(profile,"placeholder")
	if (Settings.FFXIVMINION.gFishLockout == nil or type(Settings.FFXIVMINION.gFishLockout) ~= "table") then
		Settings.FFXIVMINION.gFishLockout = {}
	end
	
	local lockout = Settings.FFXIVMINION.gFishLockout
	if (lockout[profile] == nil or type(lockout[profile]) ~= "table") then
		lockout[profile] = {}
	end
	
	lockout[profile][task] = GetCurrentTime()
	Settings.FFXIVMINION.gFishLockout = lockout
end
function ffxiv_fish.ResetLastGather()
	Settings.FFXIVMINION.gFishLockout = {}
end
ffxiv_fish = {}
ffxiv_fish.attemptedCasts = 0
ffxiv_fish.biteDetected = 0
ffxiv_fish.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\FishProfiles\]]
ffxiv_fish.profileData = {}
ffxiv_fish.currentTask = {}
ffxiv_fish.currentTaskIndex = 0
ffxiv_fish.collectibles = {
	{ name = AceLib.API.Items.GetNameByID(12713,47), id = "Icepick", minimum = 106 },
	{ name = AceLib.API.Items.GetNameByID(12724,47), id = "Glacier Core", minimum = 310 },
	{ name = AceLib.API.Items.GetNameByID(12721,47), id = "Whilom Catfish", minimum = 459 },
	{ name = AceLib.API.Items.GetNameByID(12726,47), id = "Sorcerer Fish", minimum = 646 },
	{ name = AceLib.API.Items.GetNameByID(12739,47), id = "Bubble Eye", minimum = 162 },
	{ name = AceLib.API.Items.GetNameByID(12742,47), id = "Dravanian Squeaker", minimum = 158 },
	{ name = AceLib.API.Items.GetNameByID(12767,47), id = "Warmwater Bichir", minimum = 683 },
	{ name = AceLib.API.Items.GetNameByID(12768,47), id = "Noontide Oscar", minimum = 258 },
	{ name = AceLib.API.Items.GetNameByID(12792,47), id = "Weston Bowfin", minimum = 376 },
	{ name = AceLib.API.Items.GetNameByID(12804,47), id = "Illuminati Perch", minimum = 826 },
	{ name = AceLib.API.Items.GetNameByID(12774,47), id = "Tiny Axolotl", minimum = 320 },
	{ name = AceLib.API.Items.GetNameByID(12828,47), id = "Thunderbolt Eel", minimum = 813 },
	{ name = AceLib.API.Items.GetNameByID(12837,47), id = "Capelin", minimum = 89 },
	{ name = AceLib.API.Items.GetNameByID(12830,47), id = "Loosetongue", minimum = 2441 },
	{ name = AceLib.API.Items.GetNameByID(12825,47), id = "Stupendemys", minimum = 1526 },
}

ffxiv_task_fish = inheritsFrom(ml_task)
function ffxiv_task_fish.Create()
    local newinst = inheritsFrom(ffxiv_task_fish)
    
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
    newinst.currentMarker = false
	ml_global_information.currentMarker = false
	
	newinst.filterLevel = true
	newinst.networkLatency = 0
	newinst.requiresAdjustment = false
	newinst.requiresRelocate = false
	
	newinst.snapshot = GetSnapshot()
	ffxiv_fish.currentTask = {}
	ffxiv_fish.currentTaskIndex = 0
	ffxiv_fish.attemptedCasts = 0
	ffxiv_fish.biteDetected = 0
    
    return newinst
end

function fd(var,level)
	local level = tonumber(level) or 3

	if ( gFishDebug == "1" ) then
		if ( level <= tonumber(gFishDebugLevel)) then
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

c_precastbuff = inheritsFrom( ml_cause )
e_precastbuff = inheritsFrom( ml_effect )
e_precastbuff.id = 0
function c_precastbuff:evaluate()
	c_precastbuff.activity = ""
		
	local fs = tonumber(Player:GetFishingState())
	if (fs == 0 or fs == 4) then

		if (ShouldEat()) then
			c_precastbuff.activity = "eat"
			return true
		end
		
		local needsStealth = false
		local task = ffxiv_fish.currentTask
		local marker = ml_global_information.currentMarker
		if (ValidTable(task)) then
			needsStealth = IsNull(task.usestealth,false)
		elseif (ValidTable(marker)) then
			needsStealth = (marker:GetFieldValue(GetUSString("useStealth")) == "1")
		end
		
		local hasStealth = HasBuff(Player.id,47)
		if (not hasStealth and needsStealth) then
			local stealth = ActionList:Get(298)
			if (stealth and stealth.isready and Player.action ~= 367) then
				c_precastbuff.activity = "stealth"
				return true
			end
		end
		
	end
	
	return false
end
function e_precastbuff:execute()
	ffxiv_fish.StopFishing()
	
	local activity = c_precastbuff.activity
	if (activity == "eat") then
		Eat()
		return
	end
	
	if (activity == "stealth") then
		local newTask = ffxiv_task_stealth.Create()
		newTask.addingStealth = true
		ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
		ml_task_hub:CurrentTask():SetDelay(2000)
		return
	end
end

c_mooch = inheritsFrom( ml_cause )
e_mooch = inheritsFrom( ml_effect )
function c_mooch:evaluate()
	if (Now() < ml_task_hub:CurrentTask().networkLatency) then
		return false
	end
	
	local useMooch = false
	local marker = ml_global_information.currentMarker
	local task = ffxiv_fish.currentTask
	if (ValidTable(task)) then
		useMooch = (task.usemooch == true) or false
	elseif (ValidTable(marker)) then
		useMooch = (marker:GetFieldValue(GetUSString("useMooch")) == "1")
	end
	
    local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
        local fs = tonumber(Player:GetFishingState())
        if (fs == 0 or fs == 4) then
			local mooch = ActionList:Get(297,1)
			if (useMooch and mooch and mooch.isready) then
				local moochables = ""
				if (ValidTable(task)) then
					if (task.moochables) then
						moochables = task.moochables
					end
				elseif (ValidTable(marker)) then
					moochables = marker:GetFieldValue(GetUSString("moochableFish")) or ""
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
    local mooch = ActionList:Get(297,1)
    if (mooch and mooch.isready) then
        if (mooch:Cast()) then
			ml_task_hub:CurrentTask().snapshot = GetSnapshot()
		end
		ml_task_hub:CurrentTask().castTimer = Now() + 1500
    end
end

c_release = inheritsFrom( ml_cause )
e_release = inheritsFrom( ml_effect )
function c_release:evaluate()
	if (Now() < ml_task_hub:CurrentTask().networkLatency) then
		return false
	end
	
    local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
        local fs = tonumber(Player:GetFishingState())
        if (fs == 0 or fs == 4) then
			local release = ActionList:Get(300,1)
			if (release and release.isready) then
				
				local whitelist = ""
				local whitelistHQ = ""
				local blacklist = ""
				local blacklistHQ = ""
				
				local task = ffxiv_fish.currentTask
				local marker = ml_global_information.currentMarker
				if (ValidTable(task)) then
					whitelist = IsNull(task.whitelist,"")
					whitelistHQ = IsNull(task.whitelisthq,"")
					blacklist = IsNull(task.blacklist,"")
					blacklistHQ = IsNull(task.blacklisthq,"")
				elseif (ValidTable(marker)) then
					whitelist = IsNull(marker:GetFieldValue(GetUSString("whitelistFish")),"")
					whitelistHQ = IsNull(marker:GetFieldValue(GetUSString("whitelistFishHQ")),"")
					blacklist = IsNull(marker:GetFieldValue(GetUSString("blacklistFish")),"")
					blacklistHQ = IsNull(marker:GetFieldValue(GetUSString("blacklistFishHQ")),"")
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
    end
    return false
end
function e_release:execute()
    local release = ActionList:Get(300,1)
    if (release and release.isready) then
        if (release:Cast()) then
			ml_task_hub:CurrentTask().snapshot = GetSnapshot()
		end
		ml_task_hub:CurrentTask().castTimer = Now() + 1500
    end
end

c_cast = inheritsFrom( ml_cause )
e_cast = inheritsFrom( ml_effect )
function c_cast:evaluate()
	if (Now() < ml_task_hub:CurrentTask().networkLatency) then
		return false
	end
	
	local currentBait = IsNull(Player:GetBait(),0)
	if (currentBait == 0) then
		return false
	end
	
    local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
        local fs = tonumber(Player:GetFishingState())
        if (fs == 0 or fs == 4) then
			local cast = ActionList:Get(289,1)
			if (cast and cast.isready) then
				return true
			end
        end
    end
    return false
end
function e_cast:execute()
	local cast = ActionList:Get(289,1)
	if (cast and cast.isready) then	
		if (cast:Cast()) then
			ml_task_hub:CurrentTask().snapshot = GetSnapshot()
		end
		if (ValidTable(ffxiv_fish.currentTask)) then
			if (ffxiv_fish.currentTask.taskStarted == 0) then
				ffxiv_fish.currentTask.taskStarted = Now()
			end
		end
		ffxiv_fish.attemptedCasts = ffxiv_fish.attemptedCasts + 1
		fd("[Cast]: Attempt #"..tostring(ffxiv_fish.attemptedCasts))
		ml_task_hub:CurrentTask().castTimer = Now() + 1500
	end
end

function GetSnapshot()
	local currentSnapshot = {}
	
	for x=0,3 do
		local inv = Inventory("type="..tostring(x))
		if (ValidTable(inv)) then
			for k,item in pairs(inv) do
				if currentSnapshot[item.id] == nil then
					-- New item
					currentSnapshot[item.id] = {}
					currentSnapshot[item.id].name = item.name
					currentSnapshot[item.id].HQcount = 0
					currentSnapshot[item.id].count = 0
				end
				-- Increment item counts
				if (toboolean(item.IsHQ)) then
					-- HQ
					currentSnapshot[item.id].HQcount = currentSnapshot[item.id].HQcount + item.count
				else
					-- NQ
					currentSnapshot[item.id].count = currentSnapshot[item.id].count + item.count
				end
			end
		end
	end
	
	return currentSnapshot
end

function GetNewInventory(snapshot)
	local currentInventory = GetSnapshot()
		
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
	
	local marker = ml_global_information.currentMarker
	local task = ffxiv_fish.currentTask
	if (not ValidTable(task) or not ValidTable(marker)) then
		needsStop = true
	end
	
    local castTimer = ml_task_hub:CurrentTask().castTimer
    if (ml_global_information.Now > castTimer) then
        local fs = tonumber(Player:GetFishingState())
        if (fs ~= 0 and c_returntomarker:evaluate()) then
            return true
        end
    end
    return false
end
function e_finishcast:execute()
    ffxiv_fish.StopFishing()
end

c_bite = inheritsFrom( ml_cause )
e_bite = inheritsFrom( ml_effect )
function c_bite:evaluate()
	local fs = tonumber(Player:GetFishingState())
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
		if (HasBuffs(Player,"764")) then
			local precisionHook = ActionList:Get(4179,1)
			local powerfulHook = ActionList:Get(4103,1)
			local status = Player.status
			
			if (status == 56 and precisionHook and precisionHook.isready) then
				precisionHook:Cast()
				return
			elseif (status == 57 and powerfulHook and powerfulHook.isready) then
				powerfulHook:Cast()
				return
			end
		end
			
		local bite = ActionList:Get(296,1)
		if (bite and bite.isready) then
			bite:Cast()
		end
	end
end

c_chum = inheritsFrom( ml_cause )
e_chum = inheritsFrom( ml_effect )
function c_chum:evaluate()
	local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
		
		local useBuff = false
		local task = ffxiv_fish.currentTask
		local marker = ml_global_information.currentMarker
		if (ValidTable(task)) then
			useBuff = IsNull(task.usechum,false)
		elseif (ValidTable(marker)) then
			useBuff = (marker:GetFieldValue(GetUSString("useChum")) == "1")
		end
		
		local requiresCast = false
		if (useBuff) then
			if (MissingBuffs(Player,"763")) then
				requiresCast = true
			end
		else
			if (HasBuffs(Player,"763")) then
				requiresCast = true
			end
		end
		
		if (requiresCast) then
			local chum = ActionList:Get(4104,1)
			if (chum and chum.isready) then	
				return true
			end
		end
	end
	
    return false
end
function e_chum:execute()
	local chum = ActionList:Get(4104,1)
	if (chum and chum.isready) then	
		chum:Cast()
		ml_task_hub:CurrentTask().castTimer = Now() + 1500
	end
end

c_fisheyes = inheritsFrom( ml_cause )
e_fisheyes = inheritsFrom( ml_effect )
function c_fisheyes:evaluate()
	local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
		
		local useBuff = false
		local task = ffxiv_fish.currentTask
		if (ValidTable(task)) then
			useBuff = IsNull(task.usefisheyes,false)
			
			local requiresCast = false
			if (useBuff) then
				if (MissingBuffs(Player,"762")) then
					requiresCast = true
				end
			else
				if (HasBuffs(Player,"762")) then
					requiresCast = true
				end
			end
			
			if (requiresCast) then
				local fisheyes = ActionList:Get(4105,1)
				if (fisheyes and fisheyes.isready) then	
					return true
				end
			end
		end
	end
	
    return false
end
function e_fisheyes:execute()
	local fisheyes = ActionList:Get(4105,1)
	if (fisheyes and fisheyes.isready) then	
		fisheyes:Cast()
		ml_task_hub:CurrentTask().castTimer = Now() + 1500
	end
end

c_snagging = inheritsFrom( ml_cause )
e_snagging = inheritsFrom( ml_effect )
function c_snagging:evaluate()
	local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
		
		local useBuff = false
		local task = ffxiv_fish.currentTask
		local marker = ml_global_information.currentMarker
		if (ValidTable(task)) then
			useBuff = IsNull(task.usesnagging,false)
		
			local requiresCast = false
			if (useBuff) then
				if (MissingBuffs(Player,"761")) then
					requiresCast = true
				end
			else
				if (HasBuffs(Player,"761")) then
					requiresCast = true
				end
			end
			
			if (requiresCast) then
				local snagging = ActionList:Get(4100,1)
				if (snagging and snagging.isready) then	
					return true
				end
			end
		end
	end
	
    return false
end
function e_snagging:execute()
	local snagging = ActionList:Get(4100,1)
	if (snagging and snagging.isready) then	
		snagging:Cast()
		ml_task_hub:CurrentTask().castTimer = Now() + 1500
	end
end

c_usecollect = inheritsFrom( ml_cause )
e_usecollect = inheritsFrom( ml_effect )
function c_usecollect:evaluate()
	local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
		
		local useBuff = false
		local task = ffxiv_fish.currentTask
		local marker = ml_global_information.currentMarker
		if (ValidTable(task)) then
			useBuff = IsNull(task.usecollect,false)
				
			local requiresCast = false
			if (useBuff) then
				if (MissingBuffs(Player,"805")) then
					requiresCast = true
				end
			else
				if (HasBuffs(Player,"805")) then
					requiresCast = true
				end
			end
			
			if (requiresCast) then
				local collect = ActionList:Get(4101,1)
				if (collect and collect.isready) then	
					return true
				end
			end
		end
	end
	
    return false
end
function e_usecollect:execute()
	local collect = ActionList:Get(4101,1)
	if (collect and collect.isready) then	
		collect:Cast()
		ml_task_hub:CurrentTask().castTimer = Now() + 1500
	end
end

c_patience = inheritsFrom( ml_cause )
e_patience = inheritsFrom( ml_effect )
c_patience.action = 0
function c_patience:evaluate()
	--Reset tempvar.
	c_patience.action = 0
	
	if (Player.gp.percent < 99) then
		return false
	end
	
	local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
		
		local usePatience = false
		local usePatience2 = false
		
		local task = ffxiv_fish.currentTask
		local marker = ml_global_information.currentMarker
		if (ValidTable(task)) then
			usePatience = IsNull(task.usepatience,false)
			usePatience2 = IsNull(task.usepatience2,false)
		elseif (ValidTable(marker)) then
			usePatience = (IsNull(marker:GetFieldValue(GetUSString("usePatience")),"0") == "1")
			usePatience2 = (IsNull(marker:GetFieldValue(GetUSString("usePatience2")),"0") == "1")
		end
		
		if (usePatience) then
			local patience = ActionList:Get(4102,1)
			if (patience and patience.isready) then	
				c_patience.action = 4102
				return true
			end
		elseif (usePatience2) then
			local patience2 = ActionList:Get(4106,1)
			if (patience2 and patience2.isready) then	
				c_patience.action = 4106
				return true
			end
		end
	end
	
    return false
end
function e_patience:execute()
    local patience = ActionList:Get(c_patience.action,1)
    if (patience and patience.isready) then
        patience:Cast()
		ml_task_hub:CurrentTask().castTimer = Now() + 1000
    end
end

c_collectibleaddonfish = inheritsFrom( ml_cause )
e_collectibleaddonfish = inheritsFrom( ml_effect )
function c_collectibleaddonfish:evaluate()
	if (ControlVisible("SelectYesNoItem")) then
		local info = Player:GetYesNoItemInfo()
		if (ValidTable(info)) then
			fd(info,2)			
			local validCollectible = false
			
			for i = 1,15 do
				local var = _G["gFishCollectibleName"..tostring(i)]
				local valuevar = _G["gFishCollectibleValue"..tostring(i)]
				
				if (var and var ~= "" and tonumber(valuevar) > 0) then
					local itemid = AceLib.API.Items.GetIDByName(var,47)
					if (itemid) then
						if (string.find(tostring(info.itemid),tostring(itemid))) then
							if (info.collectability >= tonumber(valuevar)) then
								validCollectible = true
							else
								fd("Collectibility was too low ["..tostring(info.collectability).."].",2)
							end
						else
							fd("Collectible was not the item we are looking for.",2)
							fd("Looking for ["..tostring(itemid).."], got ["..tostring(info.itemid).."]",2)
						end	
					else
						fd("Could not find an item ID for:" .. var,2)
					end
				end
			end
			
			local task = ffxiv_fish.currentTask
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
				fd("Cannot collect item, collectibility rating not approved.",2)
				PressYesNoItem(false) 
				return true
			else
				fd("Attempting to collect item, collectibility rating approved.",2)
				PressYesNoItem(true) 
				return true
			end
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
		local fs = tonumber(Player:GetFishingState())
		if ( fs == 9 ) then
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

c_setbait = inheritsFrom( ml_cause )
e_setbait = inheritsFrom( ml_effect )
e_setbait.baitid = 0
e_setbait.baitname = ""
function c_setbait:evaluate()
	local fs = tonumber(Player:GetFishingState())
    if (fs == 0 or fs == 4) then
		local baitChoice = ""
		
		local task = ffxiv_fish.currentTask
		local marker = ml_global_information.currentMarker
		if (ValidTable(task)) then
			baitChoice = IsNull(task.baitname,"")
		elseif (ValidTable(marker)) then
			baitChoice = marker:GetFieldValue(GetUSString("baitName")) or ""
		end
		
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
	end
        
    return false
end
function e_setbait:execute()
	local baitChoice = ""
	local rebuy = {}
	
	local task = ffxiv_fish.currentTask
	local marker = ml_global_information.currentMarker
	if (ValidTable(task)) then
		baitChoice = IsNull(task.baitname,"")
		rebuy = IsNull(task.rebuy,{})
	elseif (ValidTable(marker)) then
		baitChoice = marker:GetFieldValue(GetUSString("baitName")) or ""
	end

	local foundSuitable = false
	local baitIDs = {}
	if (baitChoice ~= "") then
		for bait in StringSplit(baitChoice,",") do
			if (tonumber(bait) ~= nil) then
				baitIDs[#baitIDs+1] = tonumber(bait)
				local item = Inventory:Get(tonumber(bait))
				if (item) then
					Player:SetBait(item.id)
					foundSuitable = true
					break
				end
			else
				local thisID = AceLib.API.Items.GetIDByName(bait)
				if (thisID) then
					baitIDs[#baitIDs+1] = thisID
					local item = Inventory:Get(thisID)
					if (item) then
						Player:SetBait(item.id)
						foundSuitable = true
						break
					end
				end
			end
		end
	end
	
	if (not foundSuitable) then
		fd("Could not find any suitable baits.",2)
		--fd("TODO: Add the shit to buy more bait here...",2)
		
		if (ffxiv_fish.IsFishing()) then
			ffxiv_fish.StopFishing()
			return
		end
		
		if (ValidTable(rebuy)) then
			local rebuyids = {}
			for k,v in pairs(rebuy) do
				if (type(k) == "string") then
					local thisID = AceLib.API.Items.GetIDByName(k)
					if (thisID) then
						rebuyids[thisID] = v
					end
				else
					rebuyids[k] = v
				end
			end
			
			if (ValidTable(rebuyids)) then
				for itemid,buyamount in pairsByKeys(rebuyids) do
					local nearestPurchase = AceLib.API.Items.FindNearestPurchaseLocation(itemid)
					if (nearestPurchase) then
						local newTask = ffxiv_misc_shopping.Create()
						
						newTask["itemid"] = itemid
						newTask["pos"] = nearestPurchase.pos
						newTask["mapid"] = nearestPurchase.mapid
						newTask["id"] = nearestPurchase.id
						newTask["conversationIndex"] = nearestPurchase.index
						newTask["buyamount"] = buyamount
						
						 ml_task_hub:CurrentTask():AddSubTask(newTask)
						--ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
						return
					end
				end
			end
		end

		ffxiv_fish.attemptedCasts = 3
	end
end

c_nextfishingmarker = inheritsFrom( ml_cause )
e_nextfishingmarker = inheritsFrom( ml_effect )
function c_nextfishingmarker:evaluate()
	if (gProfile ~= GetString("none")) then
		return false
	end
	
	if (gMarkerMgrMode == GetString("singleMarker")) then
		ml_task_hub:ThisTask().filterLevel = false
	else
		ml_task_hub:ThisTask().filterLevel = true
	end
	
    if ( ml_global_information.currentMarker ~= nil and ml_global_information.currentMarker ~= 0 ) then
        local marker = nil
        
        -- first check to see if we have no initiailized marker
        if (ml_global_information.currentMarker == false) then --default init value
            marker = ml_marker_mgr.GetNextMarker(GetString("fishingMarker"), ml_task_hub:ThisTask().filterLevel)
			
			if (marker == nil) then
				marker = ml_marker_mgr.GetNextMarker(GetString("fishingMarker"), false)
			end	
		end
		
		-- check if we've attempted a lot of casts with no bites
		if (marker == nil) then
            if (ffxiv_fish.attemptedCasts > 2) then
				marker = ml_marker_mgr.GetNextMarker(GetString("fishingMarker"), ml_task_hub:ThisTask().filterLevel)
				
				if (marker == nil) then
					marker = ml_marker_mgr.GetNextMarker(GetString("fishingMarker"), false)
				end
			end
        end
        
        -- next check to see if our level is out of range
        if (marker == nil) then
            if (ValidTable(ml_task_hub:ThisTask().currentMarker)) then
                if 	(ml_task_hub:ThisTask().filterLevel) and
					(Player.level < ml_global_information.currentMarker:GetMinLevel() or 
                    Player.level > ml_global_information.currentMarker:GetMaxLevel()) 
                then
                    marker = ml_marker_mgr.GetNextMarker(GetString("fishingMarker"), ml_task_hub:ThisTask().filterLevel)
                end
            end
        end
        
        -- last check if our time has run out
        if (marker == nil) then
			if (ValidTable(ml_global_information.currentMarker)) then
				local expireTime = ml_task_hub:ThisTask().markerTime
				if (Now() > expireTime) then
					ml_debug("Getting Next Marker, TIME IS UP!")
					marker = ml_marker_mgr.GetNextMarker(ml_global_information.currentMarker:GetType(), ml_task_hub:ThisTask().filterLevel)
				else
					return false
				end
			end
        end
        
        if (ValidTable(marker)) then
            e_nextfishingmarker.marker = marker
            return true
        end
    end
    
    return false
end
function e_nextfishingmarker:execute()
	ml_global_information.currentMarker = e_nextfishingmarker.marker
    ml_task_hub:ThisTask().currentMarker = e_nextfishingmarker.marker
    ml_task_hub:ThisTask().markerTime = Now() + (ml_task_hub:ThisTask().currentMarker:GetTime() * 1000)
	ml_global_information.MarkerTime = Now() + (ml_task_hub:ThisTask().currentMarker:GetTime() * 1000)
    ml_global_information.MarkerMinLevel = ml_task_hub:ThisTask().currentMarker:GetMinLevel()
    ml_global_information.MarkerMaxLevel = ml_task_hub:ThisTask().currentMarker:GetMaxLevel()
	gStatusMarkerName = ml_task_hub:ThisTask().currentMarker:GetName()
	ml_task_hub:CurrentTask().requiresAdjustment = true
	ffxiv_fish.attemptedCasts = 0
end

c_fishnexttask = inheritsFrom( ml_cause )
e_fishnexttask = inheritsFrom( ml_effect )
c_fishnexttask.blockOnly = false
c_fishnexttask.postpone = 0
function c_fishnexttask:evaluate()
	if (not Player.alive or MIsLoading() or MIsCasting() or not ValidTable(ffxiv_fish.profileData) or Now() < c_fishnexttask.postpone) then
		return false
	end
	
	c_fishnexttask.blockOnly = false
	
	local fs = tonumber(Player:GetFishingState())
	if (fs == 0 or fs == 4) then
	
		fd("Checking if task can be re-evaluated.")
		
		local evaluate = false
		local invalid = false
		local currentTask = ffxiv_fish.currentTask
		if (not ValidTable(currentTask)) then
			fd("No current task, set invalid flag.")
			invalid = true
		else
			if (IsNull(currentTask.interruptable,false) or IsNull(currentTask.lowpriority,false)) then
				fd("Task marked interruptable or low priority.")
				evaluate = true
			elseif not (currentTask.weatherlast or currentTask.weathernow or currentTask.weathernext or currentTask.highpriority or
					 currentTask.eorzeaminhour or currentTask.eorzeamaxhour or currentTask.normalpriority)
			then
				fd("Task has no high/normal priority markings, allow re-evaluation.")
				evaluate = true
			else
				fd("Task didn't fall into an always evaluate.")
			end
			
			if (ffxiv_fish.attemptedCasts > 2) then
				fd("Attempted casts reached 3, check for a new location.")
				ffxiv_fish.SetLockout(gProfile,ffxiv_fish.currentTaskIndex)
				invalid = true
			end
			
			if (not invalid) then
				if (currentTask.minlevel and Player.level < currentTask.minlevel) then
					invalid = true
				elseif (currentTask.maxlevel and Player.level > currentTask.maxlevel) then
					invalid = true
				end
			end
			
			if (not invalid) then
				local weather = AceLib.API.Weather.Get(currentTask.mapid)
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
						invalid = true
					else
						fd("Max time allowed ["..tostring(currentTask.maxtime).."], time passed ["..tostring(TimeSince(currentTask.taskStarted)).."].")
					end
				end
				if (IsNull(currentTask.eorzeaminhour,-1) ~= -1 and IsNull(currentTask.eorzeamaxhour,-1) ~= -1) then
					local eTime = EorzeaTime()
					local eHour = eTime.hour
					
					--d("Need to figure out if we're between the valid hours.")
					--d("MinHour ["..tostring(currentTask.eorzeaminhour).."]")
					--d("MaxHour ["..tostring(currentTask.eorzeamaxhour).."]")
					
					local validHour = false
					local i = currentTask.eorzeaminhour
					while (i ~= currentTask.eorzeamaxhour) do
					
						--d("i = ["..tostring(i).."]")
						--d("ehour = ["..tostring(eHour).."]")
						
						if (i == eHour) then	
						
							--d("we found a match in our range, allow the task to continue.")
							
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
						break
					end
				end
			end
		end
		
		--[[
		if (invalid and ValidTable(ffxiv_fish.currentTask)) then	
			--d("Need to erase the current task, and stop.")
			
			local fs = tonumber(Player:GetFishingState())
			if (fs ~= 0) then
				local finishcast = ActionList:Get(299,1)
				if (finishcast and finishcast.isready) then
					finishcast:Cast()
				end
				
				c_fishnexttask.blockOnly = true
				return true
			end		
			
			ffxiv_fish.currentTask.taskStarted = 0
			ffxiv_fish.currentTask.taskFailed = 0
			ffxiv_fish.currentTask = {}
			ffxiv_fish.currentTaskIndex = 0
			
			local taskName = ffxiv_fish.currentTask.name or ffxiv_fish.currentTaskIndex
			gStatusTaskName = taskName
			
			if (gBotMode == GetString("questMode")) then
				gQuestStepType = "fish - [evaluating]"
			end
			
			ml_global_information.currentMarker = false
			gStatusMarkerName = ""
			
			ffxiv_fish.currentTask.taskStarted = 0
			ffxiv_fish.attemptedCasts = 0
			ml_task_hub:CurrentTask().requiresRelocate = true
			ml_global_information.lastInventorySnapshot = GetInventorySnapshot()
			
			c_fishnexttask.blockOnly = true
			return true
		end
		--]]
		
		if (evaluate or invalid) then
			local profileData = ffxiv_fish.profileData
			if (ValidTable(profileData.tasks)) then
				local highPriority = {}
				local validTasks = deepcopy(profileData.tasks,true)
				for i,data in pairs(validTasks) do
					local valid = true
					if (data.minlevel and Player.level < data.minlevel) then
						valid = false
					elseif (data.maxlevel and Player.level > data.maxlevel) then
						valid = false
					end
					
					if (valid) then
						local lockout = ffxiv_fish.GetLockout(gProfile,i)
						if (lockout ~= 0) then
							local lockoutTime = data.lockout or 300
							
							if (TimePassed(GetCurrentTime(), lockout) < lockoutTime) then
								valid = false
								fd("Task ["..tostring(i).."] not valid due to lockout.",3)
							end
						end
					end
					
					if (valid) then
						local weather = AceLib.API.Weather.Get(data.mapid)
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
					end
					
					if (valid) then
						if (IsNull(data.eorzeaminhour,-1) ~= -1 and IsNull(data.eorzeamaxhour,-1) ~= -1) then
							local eTime = EorzeaTime()
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
					end
					
					if (valid) then
						if (data.condition) then
							local conditions = shallowcopy(data.condition)
							for condition,value in pairs(conditions) do
								local f = assert(loadstring("return " .. condition))()
								if (f ~= nil) then
									if (f ~= value) then
										valid = false
									end
									conditions[condition] = nil
								end
								if (not valid) then
									break
								end
							end
						end
					end
					
					if (not valid) then
						validTasks[i] = nil
					end
				end
				
				if (ValidTable(validTasks)) then
					local highPriority = {}
					local normalPriority = {}
					local lowPriority = {}
					
					for i,data in pairsByKeys(validTasks) do
						-- Items with weather requirements go into high priority
						if (data.highpriority) then
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
					
					local currentTask = ffxiv_fish.currentTask
					local currentIndex = ffxiv_fish.currentTaskIndex
					
					local lowestIndex = 9999
					local best = nil
					for i,data in pairsByKeys(highPriority) do
						if (not best or (best and i < lowestIndex)) then
						
							fd("[High] Setting best task to ["..tostring(i).."]")
							
							best = data
							lowestIndex = i
						end
					end
					
					if (not best and not currentTask.highpriority) then
						lowestIndex = 9999
						best = nil
						for i,data in pairsByKeys(normalPriority) do
							if (not best or (best and i < lowestIndex)) then
							
								fd("[Normal] Setting best task to ["..tostring(i).."]")
								
								best = data
								lowestIndex = i
							end
						end
					end
					
					if (invalid and not best) then
						lowestIndex = 9999
						best = nil
						for i,data in pairsByKeys(lowPriority) do
							if (i > currentIndex) then
								if (not best or (best and i < lowestIndex)) then
									
									fd("[Low] Setting best task to ["..tostring(i).."]")
									
									best = data
									lowestIndex = i
								end
							end
						end
						
						if (not best) then
							for i,data in pairsByKeys(lowPriority) do
								if (not best or (best and i < lowestIndex)) then
									
									fd("[Low] Setting best task to ["..tostring(i).."]")
									
									best = data
									lowestIndex = i
								end
							end
						end
					end
					
					if (best) then
						if (ffxiv_fish.currentTaskIndex ~= lowestIndex) then
							fd("Chose task index ["..tostring(lowestIndex).."] as the next index.",2)
							
							local fs = tonumber(Player:GetFishingState())
							if (fs ~= 0) then
								local finishcast = ActionList:Get(299,1)
								if (finishcast and finishcast.isready) then
									finishcast:Cast()
								end
								return
							end
	
							
							ffxiv_fish.currentTaskIndex = lowestIndex
							ffxiv_fish.currentTask = best
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
	
	if (not ValidTable(ffxiv_fish.currentTask)) then
		c_fishnexttask.postpone = Now() + 15000
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
	
	ml_global_information.currentMarker = false
	gStatusMarkerName = ""
	
	ffxiv_fish.currentTask.taskStarted = 0
	ffxiv_fish.attemptedCasts = 0
	ml_task_hub:CurrentTask().requiresRelocate = true
	ml_global_information.lastInventorySnapshot = GetInventorySnapshot()
end

c_fishnextprofilemap = inheritsFrom( ml_cause )
e_fishnextprofilemap = inheritsFrom( ml_effect )
function c_fishnextprofilemap:evaluate()
    if (not ValidTable(ffxiv_fish.currentTask)) then
		return false
	end
    
	local task = ffxiv_fish.currentTask
	if (ValidTable(task)) then
		if (ml_global_information.Player_Map ~= task.mapid) then
			return true
		end
	end
    
    return false
end
function e_fishnextprofilemap:execute()
	local index = ffxiv_fish.currentTaskIndex
	local task = ffxiv_fish.currentTask
	
	local fs = tonumber(Player:GetFishingState())
	if (fs ~= 0) then
		local finishcast = ActionList:Get(299,1)
		if (finishcast and finishcast.isready) then
			finishcast:Cast()
		end
		return
	end

	local mapID = task.mapid
	local taskPos = task.pos
	local pos = ml_nav_manager.GetNextPathPos(ml_global_information.Player_Position,ml_global_information.Player_Map,mapID)
	if(ValidTable(pos)) then		
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
		
		--ffxiv_dialog_manager.IssueStopNotice("Fish_NextTask", "No path found from map "..tostring(ml_global_information.Player_Map).." to map "..tostring(mapID))
	end
end

c_fishnextprofilepos = inheritsFrom( ml_cause )
e_fishnextprofilepos = inheritsFrom( ml_effect )
function c_fishnextprofilepos:evaluate()
    if (not ValidTable(ffxiv_fish.currentTask)) then
		return false
	end
    
	local task = ffxiv_fish.currentTask
	if (task.mapid == ml_global_information.Player_Map) then
		local pos = task.pos
		local myPos = ml_global_information.Player_Position
		local dist = PDistance3D(myPos.x, myPos.y, myPos.z, pos.x, pos.y, pos.z)
		if (dist > 5 or ml_task_hub:CurrentTask().requiresRelocate) then
			return true
		end
	end
    
    return false
end
function e_fishnextprofilepos:execute()
	local fs = tonumber(Player:GetFishingState())
	if (fs ~= 0) then
		local finishcast = ActionList:Get(299,1)
		if (finishcast and finishcast.isready) then
			finishcast:Cast()
		end
		return
	end
	
    local newTask = ffxiv_task_movetopos.Create()
	local task = ffxiv_fish.currentTask
    newTask.pos = task.pos
	newTask.range = 1
	newTask.doFacing = true
	if (gTeleport == "1") then
		newTask.useTeleport = true
	end
	newTask.stealthFunction = ffxiv_fish.NeedsStealth
	
	ml_task_hub:CurrentTask().requiresRelocate = false
	ml_task_hub:CurrentTask().requiresAdjustment = true
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_fishnoactivity = inheritsFrom( ml_cause )
e_fishnoactivity = inheritsFrom( ml_effect )
function c_fishnoactivity:evaluate()
	local marker = ml_global_information.currentMarker
	local task = ffxiv_fish.currentTask
	if (not ValidTable(task) and not ValidTable(marker)) then
		ml_task_hub:CurrentTask():SetDelay(1000)
		return true
	end
	return false
end
function e_fishnoactivity:execute()
	-- Do nothing here, but there's no point in continuing to process and eat CPU.
end

function ffxiv_fish.NeedsStealth()
	if (MIsCasting() or MIsLoading() or IsFlying() or Player.incombat) then
		return false
	end

	local useStealth = false
	local task = ffxiv_fish.currentTask
	local marker = ml_global_information.currentMarker
	if (ValidTable(task)) then
		useStealth = IsNull(task.usestealth,false)
	elseif (ValidTable(marker)) then
		useStealth = (marker:GetFieldValue(GetUSString("useStealth")) == "1")
	end
	
	if (useStealth) then		
		local stealth = ActionList:Get(298)
		if (stealth) then
			local dangerousArea = false
			local myPos = ml_global_information.Player_Position
			local destPos = ml_task_hub:CurrentTask().pos
			local task = ffxiv_fish.currentTask
			local marker = ml_global_information.currentMarker
			if (ValidTable(task)) then
				dangerousArea = IsNull(task.dangerousarea,false)
				--destPos = task.pos
			elseif (ValidTable(marker)) then
				dangerousArea = marker:GetFieldValue(GetUSString("dangerousArea")) == "1"
				--destPos = marker:GetPosition()
			end
		
			if (not dangerousArea and ml_task_hub:CurrentTask().name == "MOVETOPOS") then
				local dest = ml_task_hub:CurrentTask().pos
				if (Distance3D(myPos.x,myPos.y,myPos.z,dest.x,dest.y,dest.z) > 75) then
					return false
				end
			end
			
			local distance = PDistance3D(myPos.x, myPos.y, myPos.z, destPos.x, destPos.y, destPos.z)
			if (distance <= 6) then
				local potentialAdds = EntityList("alive,attackable,aggressive,maxdistance=50,minlevel="..tostring(Player.level - 10))
				if (ValidTable(potentialAdds)) then
					return true
				end
			end
			
			local addMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(gAdvStealthDetect))
			if (ValidTable(addMobList)) then
				return true
			end
			
			local hasStealth = HasBuff(Player.id,47)
			if (hasStealth) then
				local removeMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(gAdvStealthRemove))
				if (ValidTable(removeMobList)) then
					--d("Still detecting enemies, need to keep stealth.")
					return true
				end
			end
		end
	end
	
	return false
end

function ffxiv_fish.IsFishing()
	local fs = tonumber(Player:GetFishingState())
	if (fs ~= 0) then
		return true
	end
	return false
end

function ffxiv_fish.StopFishing()
	local fs = tonumber(Player:GetFishingState())
	if (fs ~= 0) then
		local finishcast = ActionList:Get(299,1)
		if (finishcast and finishcast.isready) then
			if (finishcast:Cast()) then
				if (ml_task_hub:CurrentTask()) then
					ml_task_hub:CurrentTask():SetDelay(1500)
				end
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
	local marker = ml_global_information.currentMarker
	if (ValidTable(task)) then
		useStealth = IsNull(task.usestealth,false)
	elseif (ValidTable(marker)) then
		useStealth = (marker:GetFieldValue(GetUSString("useStealth")) == "1")
	end
	
	if (useStealth) then
		if (ml_global_information.Player_InCombat) then
			return false
		end
		
		local fs = tonumber(Player:GetFishingState())
		if (fs ~= 0) then
			return false
		end
		
		local stealth = ActionList:Get(298)
		if (stealth) then
			local dangerousArea = false
			local destPos = {}
			local myPos = ml_global_information.Player_Position
			local task = ffxiv_fish.currentTask
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
			
			local addMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(gAdvStealthDetect))
			local removeMobList = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance="..tostring(gAdvStealthRemove))
			
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
	local fs = tonumber(Player:GetFishingState())
	if( fs == 0 and ml_task_hub:CurrentTask().requiresAdjustment ) then -- FISHSTATE_BITE
		return true
	end
    return false
end
function e_syncadjust:execute()
	local heading;
	local marker = ml_global_information.currentMarker
	local task = ffxiv_fish.currentTask
	if (ValidTable(task)) then
		heading = task.pos.h
	elseif (ValidTable(marker)) then
		local pos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
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

function ffxiv_task_fish:Init()
    --init ProcessOverwatch() cnes
	local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 150 )
    self:add( ke_dead, self.overwatch_elements)
	
	local ke_collectible = ml_element:create( "Collectible", c_collectibleaddonfish, e_collectibleaddonfish, 140 )
    self:add( ke_collectible, self.overwatch_elements)
	
	local ke_flee = ml_element:create( "Flee", c_gatherflee, e_gatherflee, 130 )
    self:add( ke_flee, self.overwatch_elements)
	
	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 100 )
    self:add( ke_inventoryFull, self.overwatch_elements)
  
    --init Process() cnes
	local ke_autoEquip = ml_element:create( "AutoEquip", c_autoequip, e_autoequip, 250 )
    self:add( ke_autoEquip, self.process_elements)
	
    local ke_resetIdle = ml_element:create( "ResetIdle", c_resetidle, e_resetidle, 200 )
    self:add(ke_resetIdle, self.process_elements)
	
	local ke_nextTask = ml_element:create( "NextTask", c_fishnexttask, e_fishnexttask, 180 )
    self:add( ke_nextTask, self.process_elements)
	
	local ke_nextMarker = ml_element:create( "NextMarker", c_nextfishingmarker, e_nextfishingmarker, 175 )
    self:add( ke_nextMarker, self.process_elements)
	
	local ke_noActivity = ml_element:create( "NoActivity", c_fishnoactivity, e_fishnoactivity, 150 )
    self:add( ke_noActivity, self.process_elements)
	
	local ke_nextProfileMap = ml_element:create( "NextProfileMap", c_fishnextprofilemap, e_fishnextprofilemap, 110 )
    self:add( ke_nextProfileMap, self.process_elements)
	
	local ke_nextProfilePos = ml_element:create( "NextProfilePos", c_fishnextprofilepos, e_fishnextprofilepos, 100 )
    self:add( ke_nextProfilePos, self.process_elements)
    
    local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 100 )
    self:add( ke_returnToMarker, self.process_elements)
    
    local ke_setbait = ml_element:create( "SetBait", c_setbait, e_setbait, 90 )
    self:add(ke_setbait, self.process_elements)
	
	local ke_syncadjust = ml_element:create( "SyncAdjust", c_syncadjust, e_syncadjust, 80)
	self:add(ke_syncadjust, self.process_elements)
	
	local ke_precast = ml_element:create( "PreCast", c_precastbuff, e_precastbuff, 70 )
    self:add(ke_precast, self.process_elements)
	
	local ke_collect = ml_element:create( "Collect", c_usecollect, e_usecollect, 68 )
    self:add(ke_collect, self.process_elements)
	
	local ke_snagging = ml_element:create( "Snagging", c_snagging, e_snagging, 67 )
    self:add(ke_snagging, self.process_elements)
	
	local ke_fisheyes = ml_element:create( "FishEyes", c_fisheyes, e_fisheyes, 65 )
    self:add(ke_fisheyes, self.process_elements)
	
	local ke_chum = ml_element:create( "Chum", c_chum, e_chum, 60 )
    self:add(ke_chum, self.process_elements)
	
	local ke_patience = ml_element:create( "Patience", c_patience, e_patience, 50 )
    self:add(ke_patience, self.process_elements)
	
	local ke_mooch = ml_element:create( "Mooch", c_mooch, e_mooch, 40 )
    self:add(ke_mooch, self.process_elements)
	
	local ke_release = ml_element:create( "Release", c_release, e_release, 30 )
    self:add(ke_release, self.process_elements)	
    
    local ke_cast = ml_element:create( "Cast", c_cast, e_cast, 20 )
    self:add(ke_cast, self.process_elements)
    
    local ke_bite = ml_element:create( "Bite", c_bite, e_bite, 10 )
    self:add(ke_bite, self.process_elements)
   
    self:AddTaskCheckCEs()
end
function ffxiv_task_fish.UIInit()
	ffxivminion.Windows.Fish = { id = strings["us"].fishMode, Name = GetString("fishMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Fish)
	
	if (Settings.FFXIVMINION.gFishVersion == nil) then
		Settings.FFXIVMINION.gFishVersion = 1.0
		Settings.FFXIVMINION.gFishCollectibleName1 = nil
		Settings.FFXIVMINION.gFishCollectibleName2 = nil
		Settings.FFXIVMINION.gFishCollectibleValue1 = nil
		Settings.FFXIVMINION.gFishCollectibleValue2 = nil
	end
	
	if (Settings.FFXIVMINION.gLastFishProfile == nil) then
        Settings.FFXIVMINION.gLastFishProfile = GetString("none")
    end
	
	for i = 1,15 do
		Settings.FFXIVMINION["gFishCollectibleName"..tostring(i)] = IsNull(Settings.FFXIVMINION["gFishCollectibleName"..tostring(i)],ffxiv_fish.collectibles[i].name)
		Settings.FFXIVMINION["gFishCollectibleValue"..tostring(i)] = IsNull(Settings.FFXIVMINION["gFishCollectibleValue"..tostring(i)],ffxiv_fish.collectibles[i].minimum)
	end
	
	if (Settings.FFXIVMINION.gFishDebug == nil) then
		Settings.FFXIVMINION.gFishDebug = "0"
	end
	if (Settings.FFXIVMINION.gFishDebugLevel == nil) then
		Settings.FFXIVMINION.gFishDebugLevel = "1"
	end	
	
	local winName = GetString("fishMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	GUI_NewButton(winName, GetString("markerManager"), "ToggleMarkerMgr")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("profile"),"gProfile",group,"None")
	GUI_NewComboBox(winName,GetString("navmesh") ,"gmeshname",group,ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
	GUI_NewField(winName,GetString("markerName"),"gStatusMarkerName",group )
	GUI_NewField(winName,GetString("markerTime"),"gStatusMarkerTime",group )
	GUI_NewField(winName,"Current Task","gStatusTaskName",group )
	GUI_NewCheckbox(winName,"Fish Debug","gFishDebug",group)
	GUI_NewComboBox(winName,"Debug Level","gFishDebugLevel",group,"1,2,3")
	
	local group = "Collectible"
	local uistring = IsNull(AceLib.API.Items.BuildUIString(47,120),"")
	for i = 1,15 do
		GUI_NewComboBox(winName,"Collectible","gFishCollectibleName"..tostring(i),group,uistring)
		GUI_NewField(winName,"Min Value","gFishCollectibleValue"..tostring(i),group)
	end
	
	GUI_UnFoldGroup(winName,GetString("status"))
	GUI_UnFoldGroup(winName,"Collectible")
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	for i = 1,15 do
		_G["gFishCollectibleName"..tostring(i)] = Settings.FFXIVMINION["gFishCollectibleName"..tostring(i)]
		_G["gFishCollectibleValue"..tostring(i)] = Settings.FFXIVMINION["gFishCollectibleValue"..tostring(i)]
	end
	
	gFishDebug = Settings.FFXIVMINION.gFishDebug
	gFishDebugLevel = Settings.FFXIVMINION.gFishDebugLevel
end

function ffxiv_fish.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
		if (	k == "gProfile" and gBotMode == GetString("fishMode")) then
			ffxiv_fish.LoadProfile(v)
			Settings.FFXIVMINION["gLastFishProfile"] = v
        elseif (string.find(k,"gFishCollectibleValue") or
				string.find(k,"gFishCollectibleName") or
				k == "gFishDebug" or
				k == "gFishDebugLevel")		
		then
			Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(GetString("fishMode"))
end
function ffxiv_fish.UpdateProfiles()
    local profiles = GetString("none")
    local found = GetString("none")	
    local profilelist = dirlist(ffxiv_fish.profilePath,".*lua")
    if ( TableSize(profilelist) > 0) then
		for i,profile in pairs(profilelist) do			
            profile = string.gsub(profile, ".lua", "")
            profiles = profiles..","..profile
            if ( Settings.FFXIVMINION.gLastFishProfile ~= nil and Settings.FFXIVMINION.gLastFishProfile == profile ) then
                found = profile
            end
        end		
    end
	
    gProfile_listitems = profiles
    gProfile = found
	ffxiv_fish.LoadProfile(gProfile)
end
function ffxiv_fish.LoadProfile(strName)
	if (strName ~= GetString("none")) then
		if (FileExists(ffxiv_fish.profilePath..strName..".lua")) then
			ffxiv_fish.profileData,e = persistence.load(ffxiv_fish.profilePath..strName..".lua")
			if (ValidTable(ffxiv_fish.profileData)) then
				fd("Fishing profile ["..strName.."] loaded successfully.")
			else
				if (e) then
					fd("Encountered error loading fishing profile ["..e.."].")
				end
			end
		end
	else
		ffxiv_fish.profileData = {}
	end
end
function ffxiv_fish.GetLockout(profile,task)
	if (Settings.FFXIVMINION.gFishLockout ~= nil) then
		lockout = Settings.FFXIVMINION.gFishLockout
		if (ValidTable(lockout[profile])) then
			return lockout[profile][task] or 0
		end
	end
	
	return 0
end
function ffxiv_fish.SetLockout(profile,task)
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
function ffxiv_fish.SetupMarkers()
    -- add marker templates for fishing
    local fishingMarker = ml_marker:Create("fishingTemplate")
	fishingMarker:SetType(GetString("fishingMarker"))
	fishingMarker:AddField("string", GetUSString("baitName"), GetString("baitName"), "")	
	fishingMarker:AddField("checkbox", GetUSString("useMooch"), GetString("useMooch"), "1")
	fishingMarker:AddField("checkbox", GetUSString("usePatience"), GetString("usePatience"), "0")
	fishingMarker:AddField("checkbox", GetUSString("usePatience2"), GetString("usePatience2"), "0")
	fishingMarker:AddField("checkbox", GetUSString("useChum"), GetString("useChum"), "0")
	fishingMarker:AddField("string", GetUSString("moochableFish"), GetString("moochableFish"), "")
	fishingMarker:AddField("string", GetUSString("whitelistFish"), GetString("whitelistFish"), "")
	fishingMarker:AddField("string", GetUSString("whitelistFishHQ"), GetString("whitelistFishHQ"), "")
	fishingMarker:AddField("string", GetUSString("blacklistFish"), GetString("blacklistFish"), "")
	fishingMarker:AddField("string", GetUSString("blacklistFishHQ"), GetString("blacklistFishHQ"), "")
	fishingMarker:AddField("checkbox", GetUSString("useStealth"), GetString("useStealth"), "1")
	fishingMarker:AddField("checkbox", GetUSString("dangerousArea"), GetString("dangerousArea"), "0")
	
    fishingMarker:SetTime(300)
    fishingMarker:SetMinLevel(1)
    fishingMarker:SetMaxLevel(60)
    ml_marker_mgr.AddMarkerTemplate(fishingMarker)
	
    -- refresh the manager with the new templates
    ml_marker_mgr.RefreshMarkerTypes()
	ml_marker_mgr.RefreshMarkerNames()
end

ffxiv_fish.SetupMarkers()
RegisterEventHandler("GUI.Update",ffxiv_fish.GUIVarUpdate)
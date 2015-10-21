ffxiv_task_fish = inheritsFrom(ml_task)
ffxiv_task_fish.attemptedCasts = 0
ffxiv_task_fish.biteDetected = 0
ffxiv_task_fish.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\FishProfiles\]]
ffxiv_task_fish.profileData = {}
ffxiv_task_fish.currentTask = {}
ffxiv_task_fish.currentTaskIndex = 0

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
	
    newinst.castFailTimer = 0
	newinst.filterLevel = true
    newinst.missingBait = false
	newinst.networkLatency = 0
	newinst.requiresAdjustment = false
	
	newinst.snapshot = GetSnapshot()
	ffxiv_task_fish.currentTask = {}
	ffxiv_task_fish.currentTaskIndex = 0
    
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
	local fs = tonumber(Player:GetFishingState())
	
	if (fs == 0 or fs == 4) then	
		local foodID = 0
		if (gFoodHQ ~= "None") then
			foodID = ffxivminion.foodsHQ[gFoodHQ]
		elseif (gFood ~= "None") then
			foodID = ffxivminion.foods[gFood]
		end

		if foodID ~= 0 then
			local food = Inventory:Get(foodID)
			if (ValidTable(food) and MissingBuffs(Player,"48")) then
				e_precastbuff.id = foodID
				return true
			end
		end
	end
	
	return false
end
function e_precastbuff:execute()
	local finishcast = ActionList:Get(299,1)
    if (finishcast and finishcast.isready) then
        finishcast:Cast()
		ml_task_hub:CurrentTask().networkLatency = Now() + 1000
    end
	if (Now() > ml_task_hub:CurrentTask().networkLatency) then
		local food = Inventory:Get(e_precastbuff.id)
		if (food) then
			food:Use()
			ml_task_hub:CurrentTask().networkLatency = Now() + 1000
		end
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
	local task = ffxiv_task_fish.currentTask
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
						if (moochable == lastCatch) then
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
				
				local task = ffxiv_task_fish.currentTask
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
					if (hq) then
						if (whitelistHQ and whitelistHQ ~= "") then
							local release = true
							for mustkeep in StringSplit(whitelistHQ,",") do
								local mustkeepid = 0
								if (tonumber(mustkeep) ~= nil) then
									mustkeepid = tonumber(mustkeep)
								else
									mustkeepid = AceLib.API.Items.GetIDByName(mustkeep,47)
								end
								
								if (mustkeepid == lastCatch) then
									release = false
								end
							end
							if (release) then
								return true
							end
						elseif (blacklistHQ and blacklistHQ ~= "") then
							for throwaway in StringSplit(blacklistHQ,",") do
								local throwawayid = 0
								if (tonumber(throwaway) ~= nil) then
									throwawayid = tonumber(throwaway)
								else
									throwawayid = AceLib.API.Items.GetIDByName(throwaway,47)
								end
								
								if (throwawayid == lastCatch) then
									return true
								end
							end
						end
					else
						if (whitelist and whitelist ~= "") then
							local release = true
							for mustkeep in StringSplit(whitelist,",") do
								local mustkeepid = 0
								if (tonumber(mustkeep) ~= nil) then
									mustkeepid = tonumber(mustkeep)
								else
									mustkeepid = AceLib.API.Items.GetIDByName(mustkeep,47)
								end
								
								if (mustkeepid == lastCatch) then
									release = false
								end
							end
						elseif (blacklist and blacklist ~= "") then
							for throwaway in StringSplit(blacklist,",") do
								local throwawayid = 0
								if (tonumber(throwaway) ~= nil) then
									throwawayid = tonumber(throwaway)
								else
									throwawayid = AceLib.API.Items.GetIDByName(throwaway,47)
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
		if (ValidTable(ffxiv_task_fish.currentTask)) then
			if (ffxiv_task_fish.currentTask.taskStarted == 0) then
				ffxiv_task_fish.currentTask.taskStarted = Now()
			end
		end
		ffxiv_task_fish.attemptedCasts = ffxiv_task_fish.attemptedCasts + 1
		fd("[Cast]: Attempt #"..tostring(ffxiv_task_fish.attemptedCasts))
		ml_task_hub:CurrentTask().castTimer = Now() + 1500
	end
end

function GetSnapshot()
	local currentSnapshot = {}
	
	local inv = Inventory("") -- no filter includes bags and equipped only, not key items, crystals, currency, etc...
    if (ValidTable(inv)) then
        for k,item in pairs(inv) do
			local itemid = item.id
			if (itemid > 1000000) then itemid = itemid - 1000000 end
            if currentSnapshot[itemid] == nil then
                -- New item
                currentSnapshot[itemid] = {}
                currentSnapshot[itemid].HQcount = 0
                currentSnapshot[itemid].count = 0
            end
            -- Increment item counts
            if (item.IsHQ == 1) then
                -- HQ
                currentSnapshot[itemid].HQcount = currentSnapshot[itemid].HQcount + item.count
            else
                -- NQ
                currentSnapshot[itemid].count = currentSnapshot[itemid].count + item.count
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
				--d(name.." (HQ) is NEW")
				return itemid, true
			else
				--d(name.." is NEW")
				return itemid, false
			end
		else
			-- Item already existed in inventory
			if item.HQcount > snapshot[itemid].HQcount then
				--d(name.." (HQ) has INCREMENTED")
				return itemid, true
			elseif item.count > snapshot[itemid].count then
				--d(name.." has INCREMENTED")
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
    local castTimer = ml_task_hub:CurrentTask().castTimer
    if (ml_global_information.Now > castTimer) then
        local fs = tonumber(Player:GetFishingState())
        if (fs ~= 4 and c_returntomarker:evaluate()) then
            return true
        end
    end
    return false
end
function e_finishcast:execute()
    local finishcast = ActionList:Get(299,1)
    if (finishcast and finishcast.isready) then
        finishcast:Cast()
    end
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
	if (ffxiv_task_fish.biteDetected == 0) then
		ffxiv_task_fish.biteDetected = Now() + math.random(250,1000)
		return
	elseif (Now() > ffxiv_task_fish.biteDetected) then
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
		local task = ffxiv_task_fish.currentTask
		if (ValidTable(task)) then
			useBuff = IsNull(task.usechum,false)
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
		local task = ffxiv_task_fish.currentTask
		if (ValidTable(task)) then
			useBuff = IsNull(task.usefisheyes,false)
		end
		
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
		local task = ffxiv_task_fish.currentTask
		if (ValidTable(task)) then
			useBuff = IsNull(task.usesnagging,false)
		end
		
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
	
    return false
end
function e_snagging:execute()
	local snagging = ActionList:Get(4100,1)
	if (snagging and snagging.isready) then	
		snagging:Cast()
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
		
		local task = ffxiv_task_fish.currentTask
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
			local validCollectible = false
			
			if (gFishCollectibleName1 and gFishCollectibleName1 ~= "" and tonumber(gFishCollectibleValue1) > 0) then
				local itemid = AceLib.API.Items.GetIDByName(gFishCollectibleName1,47)
				if (itemid) then
					if (info.itemid == itemid) then
						if (info.collectability >= tonumber(gFishCollectibleValue1)) then
							validCollectible = true
						else
							fd("Collectibility was too low ["..tostring(info.collectability).."].")
						end
					else
						fd("Collectible was not the item we are looking for.")
						fd("Looking for ["..tostring(itemid).."], got ["..tostring(info.itemid).."]")
					end	
				else
					fd("Could not find an item ID for:" .. gFishCollectibleName1)
				end
			end
			
			if (gFishCollectibleName2 and gFishCollectibleName2 ~= "" and tonumber(gFishCollectibleValue2) > 0) then
				local itemid = AceLib.API.Items.GetIDByName(gFishCollectibleName2,47)
				if (itemid) then
					if (info.itemid == itemid) then
						if (info.collectability >= tonumber(gFishCollectibleValue2)) then
							validCollectible = true
						else
							fd("Collectibility was too low ["..tostring(info.collectability).."].")
						end
					else
						fd("Collectible was not the item we are looking for.")
						fd("Looking for ["..tostring(itemid).."], got ["..tostring(info.itemid).."]")
					end	
				else
					fd("Could not find an item ID for:" .. gFishCollectibleName2)
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
function e_collectibleaddonfish:execute()
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_resetidle = inheritsFrom( ml_cause )
e_resetidle = inheritsFrom( ml_effect )
function c_resetidle:evaluate()
	if (ffxiv_task_fish.attemptedCasts > 0 or ffxiv_task_fish.biteDetected > 0) then
		local fs = tonumber(Player:GetFishingState())
		if ( fs == 9 ) then
			return true
		end
	end
    return false
end
function e_resetidle:execute()
	ml_debug("Resetting idle status, waiting detected.")
	ffxiv_task_fish.attemptedCasts = 0
	ffxiv_task_fish.biteDetected = 0
end

c_setbait = inheritsFrom( ml_cause )
e_setbait = inheritsFrom( ml_effect )
e_setbait.baitid = 0
e_setbait.baitname = ""
function c_setbait:evaluate()
	local fs = tonumber(Player:GetFishingState())
    if (fs == 0 or fs == 4) then
		local baitChoice = ""
		
		local task = ffxiv_task_fish.currentTask
		local marker = ml_global_information.currentMarker
		if (ValidTable(task)) then
			baitChoice = IsNull(task.baitname,"")
		elseif (ValidTable(marker)) then
			baitChoice = marker:GetFieldValue(GetUSString("baitName")) or ""
		end
		
		fd("baitChoice ["..tostring(baitChoice).."].",3)
		local currentbait = Player:GetBait()
		if (not currentbait or currentbait == 0) then
			fd("No bait is equipped, need to try to find something.",2)
			return true
		else
			fd("Current bait equipped is ["..tostring(currentbait).."].",3)
			local baitFound = false
			if (baitChoice ~= "") then
				for bait in StringSplit(baitChoice,",") do
					if (tonumber(bait) ~= nil) then
						if (currentbait == tonumber(bait)) then
							baitFound = true
						end
					else
						fd("Searching for bait ID for ["..IsNull(bait,"").."].",3)
						local thisID = AceLib.API.Items.GetIDByName(bait)
						if (thisID) then
							if (currentbait == thisID) then
								fd("Found bait and it is the one we want, processing will cease.",3)
								baitFound = true
							end
						end
					end
				end
			else
				fd("No bait choices selected, processing will cease.",3)
				return false
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
	
	local task = ffxiv_task_fish.currentTask
	local marker = ml_global_information.currentMarker
	if (ValidTable(task)) then
		baitChoice = IsNull(task.baitname,"")
	elseif (ValidTable(marker)) then
		baitChoice = marker:GetFieldValue(GetUSString("baitName")) or ""
	end

	if (baitChoice ~= "") then
		for bait in StringSplit(baitChoice,",") do
			if (tonumber(bait) ~= nil) then
				local item = Inventory:Get(tonumber(bait))
				if (item) then
					Player:SetBait(item.id)
					return
				end
			else
				local thisID = AceLib.API.Items.GetIDByName(bait)
				if (thisID) then
					local item = Inventory:Get(thisID)
					if (item) then
						Player:SetBait(item.id)
						return
					end
				end
			end
		end
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
            if (ffxiv_task_fish.attemptedCasts > 2) then
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
            ml_task_hub:CurrentTask().missingBait = false
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
	ffxiv_task_fish.attemptedCasts = 0
end

c_fishnexttask = inheritsFrom( ml_cause )
e_fishnexttask = inheritsFrom( ml_effect )
function c_fishnexttask:evaluate()
	if (not Player.alive or ml_global_information.Player_IsLoading or ml_global_information.Player_IsCasting or not ValidTable(ffxiv_task_fish.profileData)) then
		d("Cannot evaluate profile.")
		return false
	end
	
	local fs = tonumber(Player:GetFishingState())
	if (fs == 0 or fs == 4) then
	
		fd("Checking if task can be re-evaluated.")
		
		local evaluate = false
		local invalid = false
		local currentTask = ffxiv_task_fish.currentTask
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
			
			if (ffxiv_task_fish.attemptedCasts > 2) then
				fd("Attempted casts reached 3, check for a new location.")
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
		
		if (evaluate or invalid) then
			local profileData = ffxiv_task_fish.profileData
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
						if (data.weatherlast or data.weathernow or data.weathernext or data.highpriority) then
							highPriority[i] = data
						elseif (data.eorzeaminhour or data.eorzeamaxhour or data.normalpriority) then
							normalPriority[i] = data
						else
							fd("Added task at ["..tostring(i).."] to the low priority queue.")
							lowPriority[i] = data
						end
					end
					
					local currentTask = ffxiv_task_fish.currentTask
					local currentIndex = ffxiv_task_fish.currentTaskIndex
					
					local lowestIndex = 9999
					local best = nil
					for i,data in pairsByKeys(highPriority) do
						if (not best or (best and i < lowestIndex)) then
							best = data
							lowestIndex = i
						end
					end
					
					if (not best) then
						lowestIndex = 9999
						best = nil
						for i,data in pairsByKeys(normalPriority) do
							if (not best or (best and i < lowestIndex)) then
								best = data
								lowestIndex = i
							end
						end
					end
					
					if (invalid and not best) then
						fd("Re-evaluate the low priority queue, current task is invalid. Current index")
						lowestIndex = 9999
						best = nil
						for i,data in pairsByKeys(lowPriority) do
							if (i > currentIndex) then
								if (not best or (best and i < lowestIndex)) then
									best = data
									lowestIndex = i
								end
							end
						end
						
						if (not best) then
							for i,data in pairsByKeys(lowPriority) do
								if (not best or (best and i < lowestIndex)) then
									best = data
									lowestIndex = i
								end
							end
						end
					end
					
					if (best) then
						if (ffxiv_task_fish.currentTaskIndex ~= lowestIndex) then
							ffxiv_task_fish.currentTaskIndex = lowestIndex
							ffxiv_task_fish.currentTask = best
							return true
						end
					end
				end
			end
		end
	end
					
	return false
end
function e_fishnexttask:execute()
	ffxiv_task_fish.currentTask.taskStarted = 0
	ffxiv_task_fish.attemptedCasts = 0
end

c_fishnextprofilemap = inheritsFrom( ml_cause )
e_fishnextprofilemap = inheritsFrom( ml_effect )
function c_fishnextprofilemap:evaluate()
    if (not ValidTable(ffxiv_task_fish.currentTask)) then
		return false
	end
    
	local task = ffxiv_task_fish.currentTask
	if (ValidTable(task)) then
		if (ml_global_information.Player_Map ~= task.mapid) then
			return true
		end
	end
    
    return false
end
function e_fishnextprofilemap:execute()
	local index = ffxiv_task_fish.currentTaskIndex
	local task = ffxiv_task_fish.currentTask
	
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
			local map,aeth = GetAetheryteByMapID(mapID, taskPos)
			if (aeth) then
				local aetheryte = GetAetheryteByID(aeth)
				if (aetheryte) then
					if (GilCount() >= aetheryte.price and aetheryte.isattuned) then
						if (ml_global_information.Player_IsMoving) then
							Player:Stop()
							return
						end
						
						local noTeleportMaps = { [177] = true, [178] = true, [179] = true }
						if (noTeleportMaps[ml_global_information.Player_Map]) then
							return
						end
						
						if (ActionIsReady(7,5)) then
							if (Player:Teleport(aeth)) then	
								local newTask = ffxiv_task_teleport.Create()
								newTask.setHomepoint = false
								newTask.aetheryte = aeth
								newTask.mapID = map
								ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
							end
						end
						return
					end
				end
			end
		end
		
		ffxiv_dialog_manager.IssueStopNotice("Fish_NextTask", "No path found from map "..tostring(ml_global_information.Player_Map).." to map "..tostring(mapID))
	end
end

c_fishnextprofilepos = inheritsFrom( ml_cause )
e_fishnextprofilepos = inheritsFrom( ml_effect )
function c_fishnextprofilepos:evaluate()
    if (not ValidTable(ffxiv_task_fish.currentTask)) then
		return false
	end
    
	local task = ffxiv_task_fish.currentTask
	if (task.mapid == ml_global_information.Player_Map) then
		local pos = task.pos
		local myPos = ml_global_information.Player_Position
		local dist = Distance3D(myPos.x, myPos.y, myPos.z, pos.x, pos.y, pos.z)
		if (dist > 5) then
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
	local task = ffxiv_task_fish.currentTask
    newTask.pos = task.pos
	newTask.range = 0.5
	newTask.doFacing = true
	if (gTeleport == "1") then
		newTask.useTeleport = true
	end
	ml_task_hub:CurrentTask().requiresAdjustment = true
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_fishstealth = inheritsFrom( ml_cause )
e_fishstealth = inheritsFrom( ml_effect )
e_fishstealth.timer = 0
function c_fishstealth:evaluate()
	local useStealth = false
	local task = ffxiv_task_fish.currentTask
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
			local task = ffxiv_task_fish.currentTask
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
			
			local distance = Distance3D(myPos.x, myPos.y, myPos.z, destPos.x, destPos.y, destPos.z)
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
    local newTask = ffxiv_task_syncadjust.Create()
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
    
    return newinst
end
function ffxiv_task_syncadjust:Init()   
	Player:Move(FFXIV.MOVEMENT.FORWARD)
	self.timer = Now() + 200
	
    self:AddTaskCheckCEs()
end
function ffxiv_task_syncadjust:task_complete_eval()		
	if ( Now() > self.timer) then
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
	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 40 )
    self:add( ke_inventoryFull, self.overwatch_elements)
	
	local ke_collectible = ml_element:create( "Collectible", c_collectibleaddonfish, e_collectibleaddonfish, 30 )
    self:add( ke_collectible, self.overwatch_elements)
	
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 20 )
    self:add( ke_dead, self.overwatch_elements)
    
    local ke_stealth = ml_element:create( "Stealth", c_fishstealth, e_fishstealth, 15 )
    self:add( ke_stealth, self.overwatch_elements)
  
    --init Process() cnes
	local ke_autoEquip = ml_element:create( "AutoEquip", c_autoequip, e_autoequip, 250 )
    self:add( ke_autoEquip, self.process_elements)
	
    local ke_resetIdle = ml_element:create( "ResetIdle", c_resetidle, e_resetidle, 200 )
    self:add(ke_resetIdle, self.process_elements)
	
	local ke_nextTask = ml_element:create( "NextTask", c_fishnexttask, e_fishnexttask, 180 )
    self:add( ke_nextTask, self.process_elements)
	
	local ke_nextProfileMap = ml_element:create( "NextProfileMap", c_fishnextprofilemap, e_fishnextprofilemap, 160 )
    self:add( ke_nextProfileMap, self.process_elements)
	
	local ke_nextMarker = ml_element:create( "NextMarker", c_nextfishingmarker, e_nextfishingmarker, 150 )
    self:add( ke_nextMarker, self.process_elements)
	
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
	
	local ke_snagging = ml_element:create( "Snagging", c_snagging, e_snagging, 68 )
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
	
	if (Settings.FFXIVMINION.gLastFishProfile == nil) then
        Settings.FFXIVMINION.gLastFishProfile = GetString("none")
    end
	if (Settings.FFXIVMINION.gFishCollectibleName1 == nil) then
		Settings.FFXIVMINION.gFishCollectibleName1 = ""
	end
	if (Settings.FFXIVMINION.gFishCollectibleName2 == nil) then
		Settings.FFXIVMINION.gFishCollectibleName2 = ""
	end
	if (Settings.FFXIVMINION.gFishCollectibleValue1 == nil) then
		Settings.FFXIVMINION.gFishCollectibleValue1 = 0
	end
	if (Settings.FFXIVMINION.gFishCollectibleValue2 == nil) then
		Settings.FFXIVMINION.gFishCollectibleValue2 = 0
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
	GUI_NewCheckbox(winName,"Fish Debug","gFishDebug",group)
	GUI_NewComboBox(winName,"Debug Level","gFishDebugLevel",group,"1,2,3")
	
	local group = "Collectible"
	GUI_NewComboBox(winName,"Collectible","gFishCollectibleName1",group,AceLib.API.Items.BuildUIString(47,120))
	GUI_NewField(winName,"Min Value","gFishCollectibleValue1",group)
	GUI_NewComboBox(winName,"Collectible","gFishCollectibleName2",group,AceLib.API.Items.BuildUIString(47,120))
	GUI_NewField(winName,"Min Value","gFishCollectibleValue2",group)
	
	GUI_UnFoldGroup(winName,GetString("status"))
	GUI_UnFoldGroup(winName,"Collectible")
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gFishCollectibleName1 = Settings.FFXIVMINION.gFishCollectibleName1
    gFishCollectibleValue1 = Settings.FFXIVMINION.gFishCollectibleValue1
	gFishCollectibleName2 = Settings.FFXIVMINION.gFishCollectibleName2
    gFishCollectibleValue2 = Settings.FFXIVMINION.gFishCollectibleValue2
	gFishDebug = Settings.FFXIVMINION.gFishDebug
	gFishDebugLevel = Settings.FFXIVMINION.gFishDebugLevel
	
    RegisterEventHandler("GUI.Update",ffxiv_task_fish.GUIVarUpdate)
	
	ffxiv_task_fish.SetupMarkers()
end
function ffxiv_task_fish.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
		if (	k == "gProfile" and gBotMode == GetString("fishMode")) then
			ffxiv_task_fish.LoadProfile(v)
			Settings.FFXIVMINION["gLastFishProfile"] = v
        elseif (k == "gFishCollectibleValue1" or
				k == "gFishCollectibleValue2" or
				k == "gFishCollectibleName1" or
				k == "gFishCollectibleName2" or
				k == "gFishDebug" or
				k == "gFishDebugLevel")		
		then
			Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(GetString("fishMode"))
end
function ffxiv_task_fish.UpdateProfiles()
    local profiles = GetString("none")
    local found = GetString("none")	
    local profilelist = dirlist(ffxiv_task_fish.profilePath,".*lua")
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
	ffxiv_task_fish.LoadProfile(gProfile)
end
function ffxiv_task_fish.LoadProfile(strName)
	if (strName ~= GetString("none")) then
		if (FileExists(ffxiv_task_fish.profilePath..strName..".lua")) then
			ffxiv_task_fish.profileData,e = persistence.load(ffxiv_task_fish.profilePath..strName..".lua")
			if (ValidTable(ffxiv_task_fish.profileData)) then
				fd("Fishing profile ["..strName.."] loaded successfully.")
			else
				if (e) then
					fd("Encountered error loading fishing profile ["..e.."].")
				end
			end
		end
	else
		ffxiv_task_fish.profileData = {}
	end
end
function ffxiv_task_fish.SetupMarkers()
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
ffxiv_fish = {}
ffxiv_fish.attemptedCasts = 0
ffxiv_fish.biteDetected = 0
ffxiv_fish.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\FishProfiles\]]
ffxiv_fish.profiles = {}
ffxiv_fish.profilesDisplay = {}

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

ffxiv_fish.GUI = {
	x = 0,
	y = 0, 
	height = 0,
	width = 0,
}

ffxiv_task_fish = inheritsFrom(ml_task)
function ffxiv_task_fish.Create()
    --local newinst = inheritsFrom(ffxiv_task_fish)
    
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
    newinst.currentMarker = false
	ml_global_information.currentMarker = false
	
	newinst.filterLevel = true
	newinst.networkLatency = 0
	newinst.requiresAdjustment = false
	newinst.requiresRelocate = false
	
	newinst.snapshot = GetInventorySnapshot({0,1,2,3})
	ffxiv_fish.currentTask = {}
	ffxiv_fish.currentTaskIndex = 0
	ffxiv_fish.attemptedCasts = 0
	ffxiv_fish.biteDetected = 0
	
	setmetatable(newinst, { __index = ffxiv_task_fish })
    return newinst
end

function fd(var,level)
	local level = tonumber(level) or 3

	if ( gFishDebug  ) then
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
c_precastbuff.activity = ""
c_precastbuff.item = nil
c_precastbuff.itemid = 0
c_precastbuff.requirestop = false
c_precastbuff.requiredismount = false
function c_precastbuff:evaluate()
	
	if (MIsLoading() or MIsCasting() or IsFlying()) then
		return false
	end
	
	c_precastbuff.activity = ""
	c_precastbuff.itemid = 0
	c_precastbuff.requirestop = false
	c_precastbuff.requiredismount = false
		
	local fs = tonumber(Player:GetFishingState())
	if (fs == 0 or fs == 4) then

		if (ShouldEat()) then
			c_precastbuff.activity = "eat"
			c_precastbuff.requirestop = true
			c_precastbuff.requiredismount = true
			return true
		end
		
		local useCordials = (gGatherUseCordials)
		local useFood = 0
		local needsStealth = false
		
		local task = ffxiv_fish.currentTask
		local marker = ml_global_information.currentMarker
		if (table.valid(task)) then
			needsStealth = IsNull(task.usestealth,false)
			minimumGP = IsNull(task.mingp,0)
			useCordials = IsNull(task.usecordials,useCordials)
			useFood = IsNull(task.food,0)
		elseif (table.valid(marker)) then
			needsStealth = (marker:GetFieldValue(GetUSString("useStealth")) )
		else
			return false
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
		
		if (useCordials) then
			local canUse,cordialItem = CanUseCordial()
			if (canUse and table.valid(cordialItem)) then
				if (not ffxiv_fish.NeedsPatienceCheck() or HasBuffs(Player,"764")) then
					d("[NodePreBuff]: Need to use a cordial.")
					c_precastbuff.activity = "usecordial"
					c_precastbuff.itemid = cordialItem.hqid
					c_precastbuff.requirestop = true
					c_precastbuff.requiredismount = true
					return true
				end
			end					
		end
	end
	
	return false
end
function e_precastbuff:execute()
	ffxiv_fish.StopFishing()
	
	local activityitemid = c_precastbuff.itemid
	local requirestop = c_precastbuff.requirestop
	local requiredismount = c_precastbuff.requiredismount
	local activity = c_precastbuff.activity
	
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
		return
	end
	
	if (activity == "stealth") then
		local newTask = ffxiv_task_stealth.Create()
		newTask.addingStealth = true
		ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
		ml_global_information.Await(2000)
		return
	end
	
	if (activity == "usecordial") then
		local cordial, action = GetItem(activityitemid)
		if (cordial and cordial:IsReady(Player.id)) then
			cordial:Cast(Player.id)
			local castid = action.id
			ml_global_information.Await(5000, function () return Player.castinginfo.lastcastid == castid end)
			return
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
	local task = ffxiv_fish.currentTask
	if (table.valid(task)) then
		useMooch = (task.usemooch == true) or false
	elseif (table.valid(marker)) then
		useMooch = (marker:GetFieldValue(GetUSString("useMooch")) )
	else
		return false
	end
	
    local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
        local fs = tonumber(Player:GetFishingState())
        if (fs == 0 or fs == 4) then
			local mooch = SkillMgr.GetAction(297,1)
			if (useMooch and mooch and mooch:IsReady(Player.id)) then
				local moochables = ""
				if (table.valid(task)) then
					if (task.moochables) then
						moochables = task.moochables
					end
				elseif (table.valid(marker)) then
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
    local mooch = SkillMgr.GetAction(297,1)
    if (mooch and mooch:IsReady(Player.id)) then
        if (mooch:Cast()) then
			ml_task_hub:CurrentTask().snapshot = GetInventorySnapshot({0,1,2,3})
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
			local release = SkillMgr.GetAction(300,1)
			if (release and release:IsReady(Player.id)) then
				
				local whitelist = ""
				local whitelistHQ = ""
				local blacklist = ""
				local blacklistHQ = ""
				
				local task = ffxiv_fish.currentTask
				local marker = ml_global_information.currentMarker
				if (table.valid(task)) then
					whitelist = IsNull(task.whitelist,"")
					whitelistHQ = IsNull(task.whitelisthq,"")
					blacklist = IsNull(task.blacklist,"")
					blacklistHQ = IsNull(task.blacklisthq,"")
				elseif (table.valid(marker)) then
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
    local release = SkillMgr.GetAction(300,1)
    if (release and release:IsReady(Player.id)) then
        if (release:Cast()) then
			ml_task_hub:CurrentTask().snapshot = GetInventorySnapshot({0,1,2,3})
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
			local cast = SkillMgr.GetAction(289,1)
			if (cast and cast:IsReady(Player.id)) then
				return true
			end
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
		ml_task_hub:CurrentTask().castTimer = Now() + 1500
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
	
	local marker = ml_global_information.currentMarker
	local task = ffxiv_fish.currentTask
	if (not table.valid(task) or not table.valid(marker)) then
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
			local precisionHook = SkillMgr.GetAction(4179,1)
			local powerfulHook = SkillMgr.GetAction(4103,1)
			local status = Player.status
			
			if (status == 56 and precisionHook and precisionHook:IsReady(Player.id)) then
				precisionHook:Cast()
				return
			elseif (status == 57 and powerfulHook and powerfulHook:IsReady(Player.id)) then
				powerfulHook:Cast()
				return
			end
		end
			
		local bite = SkillMgr.GetAction(296,1)
		if (bite and bite:IsReady(Player.id)) then
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
		if (table.valid(task)) then
			useBuff = IsNull(task.usechum,false)
		elseif (table.valid(marker)) then
			useBuff = (marker:GetFieldValue(GetUSString("useChum")) )
		end
		
		local chum = SkillMgr.GetAction(4104,1)
		if (chum and chum:IsReady(Player.id)) then	
			if (useBuff) then
				if (MissingBuffs(Player,"763")) then
					if (chum:Cast()) then
						ml_global_information.Await(3000, function () return (HasBuffs(Player,"763")) end)
					end
				end
			else
				if (HasBuffs(Player,"763")) then
					if (chum:Cast()) then
						ml_global_information.Await(3000, function () return (MissingBuffs(Player,"763")) end)
					end
				end
			end
		end
	end
	
    return false
end
function e_chum:execute()
end

c_fisheyes = inheritsFrom( ml_cause )
e_fisheyes = inheritsFrom( ml_effect )
function c_fisheyes:evaluate()
	local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
		
		local useBuff = false
		local task = ffxiv_fish.currentTask
		if (table.valid(task)) then
			local fisheyes = SkillMgr.GetAction(4105,1)
			if (fisheyes and fisheyes:IsReady(Player.id)) then
				useBuff = IsNull(task.usefisheyes,false)
				if (useBuff) then
					if (MissingBuffs(Player,"762")) then
						if (fisheyes:Cast()) then
							ml_global_information.Await(3000, function () return (HasBuffs(Player,"762")) end)
						end
						return true
					end
				else
					if (HasBuffs(Player,"762")) then
						if (fisheyes:Cast()) then
							ml_global_information.Await(3000, function () return (MissingBuffs(Player,"762")) end)
						end
						return true
					end
				end
			end
		end
	end
	
    return false
end
function e_fisheyes:execute()
end

c_snagging = inheritsFrom( ml_cause )
e_snagging = inheritsFrom( ml_effect )
function c_snagging:evaluate()
	local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
		
		local useBuff = false
		local task = ffxiv_fish.currentTask
		local marker = ml_global_information.currentMarker
		if (table.valid(task)) then
			local snagging = SkillMgr.GetAction(4100,1)
			if (snagging and snagging:IsReady(Player.id)) then
				useBuff = IsNull(task.usesnagging,false)
			
				local requiresCast = false
				if (useBuff) then
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
		end
	end
	
    return false
end
function e_snagging:execute()
end

c_usecollect = inheritsFrom( ml_cause )
e_usecollect = inheritsFrom( ml_effect )
function c_usecollect:evaluate()
	local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
		
		local useBuff = false
		local task = ffxiv_fish.currentTask
		local marker = ml_global_information.currentMarker
		if (table.valid(task)) then
			
			local collect = SkillMgr.GetAction(4101,1)
			if (collect and collect:IsReady(Player.id)) then
				useBuff = IsNull(task.usecollect,false)
				
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
	
	if (Player.gp.percent < 99) then
		return false
	end
	
	local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
		
		local usePatience = false
		local usePatience2 = false
		
		local task = ffxiv_fish.currentTask
		local marker = ml_global_information.currentMarker
		if (table.valid(task)) then
			usePatience = IsNull(task.usepatience,false)
			usePatience2 = IsNull(task.usepatience2,false)
		elseif (table.valid(marker)) then
			usePatience = (IsNull(marker:GetFieldValue(GetUSString("usePatience")),"0") )
			usePatience2 = (IsNull(marker:GetFieldValue(GetUSString("usePatience2")),"0") )
		end
		
		if (usePatience2) then
			local patience2 = SkillMgr.GetAction(4106,1)
			if (patience2 and patience2:IsReady(Player.id)) then	
				if (ffxiv_fish.NeedsCordialCheck()) then
					if (Player:GetFishingState() ~= 0) then
						local finishcast = SkillMgr.GetAction(299,1)
						if (finishcast and finishcast.isready) then
							finishcast:Cast()
						end
						qd("[QuestFishComplete]: Quitting out of fishing state.",2)
						ml_global_information.Await(2500, function () return Player:GetFishingState() == 0 end)
						return false
					end
				end
				if (patience2:Cast()) then
					ml_global_information.Await(3000, function () return (SkillMgr.GetAction(4106,1).isoncd) end)
				end
				return true
			end
		elseif (usePatience) then
			local patience = SkillMgr.GetAction(4102,1)
			if (patience and patience:IsReady(Player.id)) then	
				if (ffxiv_fish.NeedsCordialCheck()) then
					if (Player:GetFishingState() ~= 0) then
						local finishcast = SkillMgr.GetAction(299,1)
						if (finishcast and finishcast.isready) then
							finishcast:Cast()
						end
						qd("[QuestFishComplete]: Quitting out of fishing state.",2)
						ml_global_information.Await(2500, function () return Player:GetFishingState() == 0 end)
						return false
					end
				end
				if (patience:Cast()) then
					ml_global_information.Await(3000, function () return (SkillMgr.GetAction(4102,1).isoncd) end)
				end
				return true
			end
		end
	end
	
    return false
end
function e_patience:execute() end

c_collectibleaddonfish = inheritsFrom( ml_cause )
e_collectibleaddonfish = inheritsFrom( ml_effect )
function c_collectibleaddonfish:evaluate()
	if (IsControlOpen("SelectYesNoCountItem")) then
		local info = GetControlData("SelectYesNoCountItem")
		if (table.valid(info)) then
			
			-- remove later
			table.print(info)
			
			local validCollectible = false
			
			for i = 1,15 do
				local var = _G["gFishCollectibleName"..tostring(i)]
				local valuevar = _G["gFishCollectibleValue"..tostring(i)]
				
				if (var and var ~= "" and tonumber(valuevar) > 0) then
					local itemid = AceLib.API.Items.GetIDByName(var,47)
					if (itemid) then
						if (string.contains(tostring(info.itemid),tostring(itemid))) then
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
									gd("Collectibility was too low ["..tostring(info.collectability).."].",3)
								end
							end	
						end
					end
				end
			end
			
			-- needs to be removed
			--ml_global_information:ToggleRun()
			if (not validCollectible) then
				d("Cannot collect item ["..info.name.."], collectibility rating not approved.",2)
				UseControlAction("SelectYesNoCountItem","No")
			else
				d("Attempting to collect item ["..info.name.."], collectibility rating approved.",2)
				UseControlAction("SelectYesNoCountItem","Yes")
			end
			ml_global_information.Await(3000, function () return not IsControlOpen("SelectYesNoCountItem") end)				
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
		local fs = tonumber(Player:GetFishingState())
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

c_setbait = inheritsFrom( ml_cause )
e_setbait = inheritsFrom( ml_effect )
e_setbait.baitid = 0
e_setbait.baitname = ""
function c_setbait:evaluate()
	if (Player.ismounted) then
		return false
	end
	
	local fs = tonumber(Player:GetFishingState())
    if (fs == 0 or fs == 4) then
		local baitChoice = ""
		
		local task = ffxiv_fish.currentTask
		local marker = ml_global_information.currentMarker
		if (table.valid(task)) then
			baitChoice = IsNull(task.baitname,"")
		elseif (table.valid(marker)) then
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
	if (table.valid(task)) then
		baitChoice = IsNull(task.baitname,"")
		rebuy = IsNull(task.rebuy,{})
	elseif (table.valid(marker)) then
		baitChoice = marker:GetFieldValue(GetUSString("baitName")) or ""
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
	
	if (not foundSuitable) then
		fd("Could not find any suitable baits.",2)
		--fd("TODO: Add the shit to buy more bait here...",2)
		
		if (ffxiv_fish.IsFishing()) then
			ffxiv_fish.StopFishing()
			return
		end
		
		if (table.valid(rebuy)) then
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
	if (gFishProfile ~= GetString("none")) then
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
            if (table.valid(ml_task_hub:ThisTask().currentMarker)) then
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
			if (table.valid(ml_global_information.currentMarker)) then
				local expireTime = ml_task_hub:ThisTask().markerTime
				if (Now() > expireTime) then
					ml_debug("Getting Next Marker, TIME IS UP!")
					marker = ml_marker_mgr.GetNextMarker(ml_global_information.currentMarker:GetType(), ml_task_hub:ThisTask().filterLevel)
				else
					return false
				end
			end
        end
        
        if (table.valid(marker)) then
            e_nextfishingmarker.marker = marker
            return true
        end
    end
    
    return false
end
function e_nextfishingmarker:execute()
	local fs = tonumber(Player:GetFishingState())
	if (fs ~= 0) then
		local finishcast = SkillMgr.GetAction(299,1)
		if (finishcast and finishcast:IsReady(Player.id)) then
			finishcast:Cast()
		end
		return
	end
							
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
c_fishnexttask.subset = {}
c_fishnexttask.subsetExpiration = 0
function c_fishnexttask:evaluate()
	if (not Player.alive or MIsLoading() or MIsCasting() or not table.valid(ffxiv_fish.profileData)) then
		return false
	end
	
	c_fishnexttask.blockOnly = false
	
	local fs = tonumber(Player:GetFishingState())
	if (fs == 0 or fs == 4) then
	
		fd("Checking if task can be re-evaluated.")
		
		local evaluate = false
		local invalid = false
		local tempinvalid = false
		local currentTask = ffxiv_fish.currentTask
		local currentTaskIndex = ffxiv_fish.currentTaskIndex
		
		if (not table.valid(currentTask)) then
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
				
				local profileName = (gBotMode == GetString("questMode") and gQuestProfile) or gFishProfile
				ffxiv_fish.SetLockout(profileName,ffxiv_fish.currentTaskIndex)
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
					local eTime = AceLib.API.Weather.GetDateTime() 
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
		
		if (invalid and not tempinvalid) then
			c_fishnexttask.subset[currentTaskIndex] = nil
		end
		
		if (evaluate or invalid) then
			local profileData = ffxiv_fish.profileData
			if (table.valid(profileData.tasks)) then
				
				local validTasks = {}
				if (Now() < c_fishnexttask.subsetExpiration) then
					validTasks = c_fishnexttask.subset
				else
					validTasks = deepcopy(profileData.tasks,true)
				
					for i,data in pairs(validTasks) do
						local valid = true
						if (data.minlevel and Player.level < data.minlevel) then
							valid = false
						elseif (data.maxlevel and Player.level > data.maxlevel) then
							valid = false
						end
						
						if (valid) then
							local profileName = (gBotMode == GetString("questMode") and gQuestProfile) or gFishProfile
							local lockout = ffxiv_fish.GetLockout(profileName,i)
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
						end
						
						if (valid) then
							if (data.condition) then
								local conditions = deepcopy(data.condition,true)
								valid = TestConditions(conditions)
							end
						end
						
						if (not valid) then
							validTasks[i] = nil
						end
					end
				
					c_fishnexttask.subset = validTasks
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
					c_fishnexttask.subsetExpiration = Now() + expirationDelay
				end
					
				if (table.valid(validTasks)) then
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
							if (i > currentTaskIndex) then
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
								local finishcast = SkillMgr.GetAction(299,1)
								if (finishcast and finishcast:IsReady(Player.id)) then
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
    if (not table.valid(ffxiv_fish.currentTask)) then
		return false
	end
    
	local task = ffxiv_fish.currentTask
	if (table.valid(task)) then
		if (Player.localmapid ~= task.mapid) then
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
		local finishcast = SkillMgr.GetAction(299,1)
		if (finishcast and finishcast:IsReady(Player.id)) then
			finishcast:Cast()
		end
		return
	end

	local mapID = task.mapid
	local taskPos = task.pos
	local pos = ml_nav_manager.GetNextPathPos(Player.pos,Player.localmapid,mapID)
	if(table.valid(pos)) then		
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
function c_fishnextprofilepos:evaluate()
    if (not table.valid(ffxiv_fish.currentTask)) then
		return false
	end
    
	local task = ffxiv_fish.currentTask
	if (task.mapid == Player.localmapid) then
		local pos = task.pos
		local myPos = Player.pos
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
    newTask.pos = task.pos
	newTask.range = 1
	newTask.doFacing = true
	if (gTeleportHack) then
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
	if (not table.valid(task) and not table.valid(marker)) then
		ml_global_information.Await(1000)
		return true
	end
	return false
end
function e_fishnoactivity:execute()
	-- Do nothing here, but there's no point in continuing to process and eat CPU.
end

function ffxiv_fish.NeedsCordialCheck()
	local useCordials = (gGatherUseCordials)
	local task = ffxiv_fish.currentTask
	if (table.valid(task)) then
		useCordials = IsNull(task.usecordials,useCordials)
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
	
	local task = ffxiv_fish.currentTask
	local marker = ml_global_information.currentMarker
	if (table.valid(task)) then
		usePatience = IsNull(task.usepatience,false)
		usePatience2 = IsNull(task.usepatience2,false)
	elseif (table.valid(marker)) then
		usePatience = (IsNull(marker:GetFieldValue(GetUSString("usePatience")),"0") )
		usePatience2 = (IsNull(marker:GetFieldValue(GetUSString("usePatience2")),"0") )
	end
	
	return (usePatience or usePatience2)
end

function ffxiv_fish.NeedsStealth()
	if (MIsCasting() or MIsLoading() or IsFlying() or Player.incombat) then
		return false
	end

	local useStealth = false
	local task = ffxiv_fish.currentTask
	local marker = ml_global_information.currentMarker
	if (table.valid(task)) then
		useStealth = IsNull(task.usestealth,false)
	elseif (table.valid(marker)) then
		useStealth = (marker:GetFieldValue(GetUSString("useStealth")) )
	end
	
	if (useStealth) then		
		local stealth = SkillMgr.GetAction(298,1)
		if (stealth) then
			local dangerousArea = false
			local myPos = Player.pos
			local destPos = ml_task_hub:CurrentTask().pos
			local task = ffxiv_fish.currentTask
			local marker = ml_global_information.currentMarker
			if (table.valid(task)) then
				dangerousArea = IsNull(task.dangerousarea,false)
				--destPos = task.pos
			elseif (table.valid(marker)) then
				dangerousArea = marker:GetFieldValue(GetUSString("dangerousArea")) 
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
	local fs = tonumber(Player:GetFishingState())
	if (fs ~= 0) then
		return true
	end
	return false
end

function ffxiv_fish.StopFishing()
	local fs = tonumber(Player:GetFishingState())
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
	local marker = ml_global_information.currentMarker
	if (table.valid(task)) then
		useStealth = IsNull(task.usestealth,false)
	elseif (table.valid(marker)) then
		useStealth = (marker:GetFieldValue(GetUSString("useStealth")) )
	end
	
	if (useStealth) then
		if (Player.incombat) then
			return false
		end
		
		local fs = tonumber(Player:GetFishingState())
		if (fs ~= 0) then
			return false
		end
		
		local stealth = SkillMgr.GetAction(298,1)
		if (stealth) then
			local dangerousArea = false
			local destPos = {}
			local myPos = Player.pos
			local task = ffxiv_fish.currentTask
			local marker = ml_global_information.currentMarker
			if (table.valid(task)) then
				dangerousArea = IsNull(task.dangerousarea,false)
				destPos = task.pos
			elseif (table.valid(marker)) then
				dangerousArea = marker:GetFieldValue(GetUSString("dangerousArea")) 
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
	if (table.valid(task)) then
		heading = task.pos.h
	elseif (table.valid(marker)) then
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

function ffxiv_task_syncadjust:task_fail_eval()
	if (not Player.alive) then
		return true
	end
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
	--local ke_autoEquip = ml_element:create( "AutoEquip", c_autoequip, e_autoequip, 250 )
    --self:add( ke_autoEquip, self.process_elements)
	
	local ke_recommendEquip = ml_element:create( "RecommendEquip", c_recommendequip, e_recommendequip, 250 )
    self:add( ke_recommendEquip, self.process_elements)
	
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
	
	local ke_precast = ml_element:create( "PreCast", c_precastbuff, e_precastbuff, 45 )
    self:add(ke_precast, self.process_elements)
	
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

function ffxiv_task_fish.SetModeOptions()
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
	
	local uistring = IsNull(AceLib.API.Items.BuildUIString(47,120),"")
	gFishCollectablesList = { GetString("none") }
	if (ValidString(uistring)) then
		for collectable in StringSplit(uistring,",") do
			table.insert(gFishCollectablesList,collectable)
		end
	end
	
	gFishCollect = ffxivminion.GetSetting("gFishCollect",{})
	self.GUI = {}
	self.GUI.main_tabs = GUI_CreateTabs("status,settings",true)
end

function ffxiv_task_fish:Draw()
	
	local profileChanged = GUI_Combo(GetString("profile"), "gFishProfileIndex", "gFishProfile", ffxiv_fish.profilesDisplay)
	if (profileChanged) then
		ffxiv_fish.profileData = ffxiv_fish.profiles[gFishProfile]
		local uuid = GetUUID()
		Settings.FFXIVMINION.gLastFishProfiles[uuid] = gFishProfile
	end
	
	GUI_DrawTabs(self.GUI.main_tabs)
	local tabs = self.GUI.main_tabs
	
	if (tabs.tabs[1].isselected) then
		GUI:BeginChild("##header-status",0,GUI_GetFrameHeight(3),true)
		GUI:PushItemWidth(120)					
		
		GUI:Checkbox(GetString("botEnabled"),FFXIV_Common_BotRunning)
		GUI_Capture(GUI:Checkbox("Fish Debug",gFishDebug),"gFishDebug");
		local debugLevels = { 1, 2, 3}
		GUI_Combo("Debug Level", "gFishDebugLevelIndex", "gFishDebugLevel", debugLevels)
		
		GUI:PopItemWidth()
		GUI:EndChild()
	end
	
	if (tabs.tabs[2].isselected) then
		GUI:BeginChild("##header-settings",0,60,true)
		GUI:PushItemWidth(120)				
		
		--[[
		if (GUI:Button("Add Collectable",20,100)) then
			local newCollectable = GetString("none")
			table.insert(gFishCollect,newCollectable)
		end
		
		if (table.valid(gFishCollect)) then
			for i,collectable in pairsByKeys(gFishCollect) do
				local doSave = false
				local currentIndex = GetKeyByValue(collectable,gFishCollectablesList)
				local selectedIndex = GUI:Combo("Collectable##"..tostring(i), currentIndex, gFishCollectablesList )
				if (selectedIndex ~= currentIndex) then
					gFishCollect[i] = gFishCollectablesList[selectedIndex]
					doSave  
				end
				GUI:SameLine()
				if (GUI:SmallButton(" - ##"..tostring(i))) then
					gFishCollect[i] = nil
					Settings.FFXIVMINION.gFishCollect = gFishCollect
				end
				if (doSave) then
					Settings.FFXIVMINION.gFishCollect = gFishCollect
				end
			end
		end
		--]]
		
		GUI:PopItemWidth()
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
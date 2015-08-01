ffxiv_task_fish = inheritsFrom(ml_task)
ffxiv_task_fish.attemptedCasts = 0
ffxiv_task_fish.biteDetected = 0

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
	
    newinst.baitName = ""
    newinst.castFailTimer = 0
	newinst.filterLevel = true
    newinst.missingBait = false
	newinst.networkLatency = 0
	newinst.requiresAdjustment = false
	
	newinst.snapshot = GetSnapshot()
    
    return newinst
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
	local marker = ml_task_hub:CurrentTask().currentMarker
	if (ValidTable(marker)) then
		useMooch = (marker:GetFieldValue(GetString("useMooch")) == "1")
	end
	
    local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
        local fs = tonumber(Player:GetFishingState())
        if (fs == 0 or fs == 4) then
			local mooch = ActionList:Get(297,1)
			if (useMooch and mooch and mooch.isready) then
				local moochables = marker:GetFieldValue(GetString("Moochable Fish")) or ""
				
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
				local marker = ml_global_information.currentMarker
				if (ValidTable(marker)) then
					local whitelist = marker:GetFieldValue(GetString("whitelistFish"))
					local whitelistHQ = marker:GetFieldValue(GetString("whitelistFishHQ"))
					local blacklist = marker:GetFieldValue(GetString("blacklistFish"))
					local blacklistHQ = marker:GetFieldValue(GetString("blacklistFishHQ"))
					
					local lastCatch,hq = GetNewInventory(ml_task_hub:CurrentTask().snapshot)
					if (lastCatch) then
						if (hq) then
							if (whitelistHQ and whitelistHQ ~= "") then
								for mustkeep in StringSplit(whitelistHQ,",") do
									if (mustkeep == lastCatch) then
										return false
									else
										return true
									end
								end
							elseif (blacklistHQ and blacklistHQ ~= "") then
								for throwaway in StringSplit(blacklistHQ,",") do
									if (throwaway == lastCatch) then
										return true
									end
								end
							end
						else
							if (whitelist and whitelist ~= "") then
								for mustkeep in StringSplit(whitelist,",") do
									if (mustkeep == lastCatch) then
										return false
									else
										return true
									end
								end
							elseif (blacklist and blacklist ~= "") then
								for throwaway in StringSplit(blacklist,",") do
									if (throwaway == lastCatch) then
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
			ffxiv_task_fish.attemptedCasts = ffxiv_task_fish.attemptedCasts + 1
			ml_task_hub:CurrentTask().snapshot = GetSnapshot()
		end
		ml_task_hub:CurrentTask().castTimer = Now() + 1500
	end
end

function GetSnapshot()
	local currentSnapshot = {}
	
	local inv = Inventory("") -- no filter includes bags and equipped only, not key items, crystals, currency, etc...
    if (ValidTable(inv)) then
        for k,item in pairs(inv) do
            if currentSnapshot[item.name] == nil then
                -- New item
                currentSnapshot[item.name] = {}
                currentSnapshot[item.name].HQcount = 0
                currentSnapshot[item.name].count = 0
            end
            -- Increment item counts
            if (item.IsHQ == 1) then
                -- HQ
                currentSnapshot[item.name].HQcount = currentSnapshot[item.name].HQcount + item.count
            else
                -- NQ
                currentSnapshot[item.name].count = currentSnapshot[item.name].count + item.count
            end
        end
	end
	
	return currentSnapshot
end

function GetNewInventory(snapshot)
	local currentInventory = GetSnapshot()
		
	for name,item in pairs(currentInventory) do
		if (snapshot[name] == nil) then
			-- Item is new in inventory
			if item.HQcount > 0 then
				--d(name.." (HQ) is NEW")
				return name, true
			else
				--d(name.." is NEW")
				return name, false
			end
		else
			-- Item already existed in inventory
			if item.HQcount > snapshot[name].HQcount then
				--d(name.." (HQ) has INCREMENTED")
				return name, true
			elseif item.count > snapshot[name].count then
				--d(name.." has INCREMENTED")
				return name, false
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

c_patience = inheritsFrom( ml_cause )
e_patience = inheritsFrom( ml_effect )
c_patience.action = 0
function c_patience:evaluate()
	--Reset tempvar.
	c_patience.action = 0
	
	local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
		local marker = ml_global_information.currentMarker
		if (ValidTable(marker)) then
			local usePatience = (marker:GetFieldValue(GetString("usePatience")) == "1")
			local usePatience2 = (marker:GetFieldValue(GetString("usePatience2")) == "1")
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
	d("Resetting idle status, waiting detected.")
	ffxiv_task_fish.attemptedCasts = 0
	ffxiv_task_fish.biteDetected = 0
end

c_setbait = inheritsFrom( ml_cause )
e_setbait = inheritsFrom( ml_effect )
e_setbait.baitid = 0
e_setbait.baitname = ""
function c_setbait:evaluate()
    if (ml_task_hub:CurrentTask().missingBait or gFishNoMarker == "1") then
        return false
    end
    
    local fs = tonumber(Player:GetFishingState())
    if (fs == 0 or fs == 4) then
        local marker = ml_task_hub:CurrentTask().currentMarker
        if (marker ~= nil and marker ~= false) then
            local baitName = marker:GetFieldValue(GetString("baitName"))
            if (baitName ~= "None" and baitName ~= ml_task_hub:CurrentTask().baitName) then
                --check to see if we have the bait in inventory
                ml_debug("Looking for bait named "..baitName)
                for i = 0,3 do
                    local inventory = Inventory("type="..tostring(i))
                    if (inventory ~= nil and inventory ~= 0) then
                        for _,item in pairs(inventory) do
                            if item.name == baitName then
                                e_setbait.baitid = item.id
								e_setbait.baitname = item.name
								return true
                            end
                        end
                    end
                end
                ml_debug("Could not find bait! Attempting to use current bait")
            end
        end
    end
        
    return false
end
function e_setbait:execute()
    Player:SetBait(e_setbait.baitid)
    ml_task_hub:CurrentTask().baitName = e_setbait.baitname
end

c_nextfishingmarker = inheritsFrom( ml_cause )
e_nextfishingmarker = inheritsFrom( ml_effect )
function c_nextfishingmarker:evaluate()
	if (gFishNoMarker == "1") then	
		return false
	end
	
	if (gMarkerMgrMode == GetString("singleMarker")) then
		ml_task_hub:ThisTask().filterLevel = false
	else
		ml_task_hub:ThisTask().filterLevel = true
	end
	
    if ( ml_task_hub:ThisTask().currentMarker ~= nil and ml_task_hub:ThisTask().currentMarker ~= 0 ) then
        local marker = nil
        
        -- first check to see if we have no initiailized marker
        if (ml_task_hub:ThisTask().currentMarker == false) then --default init value
            marker = ml_marker_mgr.GetNextMarker(GetString("fishingMarker"), ml_task_hub:ThisTask().filterLevel)
        
			if (marker == nil) then
				ml_task_hub:ThisTask().filterLevel = false
				marker = ml_marker_mgr.GetNextMarker(GetString("fishingMarker"), ml_task_hub:ThisTask().filterLevel)
			end	
		end
		
		-- check if we've attempted a lot of casts with no bites
		if (marker == nil) then
            if (ffxiv_task_fish.attemptedCasts > 3) then
				marker = ml_marker_mgr.GetNextMarker(GetString("fishingMarker"), ml_task_hub:ThisTask().filterLevel)
			end
        end
        
        -- next check to see if our level is out of range
        if (marker == nil) then
            if (ValidTable(ml_task_hub:ThisTask().currentMarker)) then
                if 	(ml_task_hub:ThisTask().filterLevel) and
					(Player.level < ml_task_hub:ThisTask().currentMarker:GetMinLevel() or 
                    Player.level > ml_task_hub:ThisTask().currentMarker:GetMaxLevel()) 
                then
                    marker = ml_marker_mgr.GetNextMarker(GetString("fishingMarker"), ml_task_hub:ThisTask().filterLevel)
                end
            end
        end
        
        -- last check if our time has run out
        if (marker == nil) then
			if (ValidTable(ml_task_hub:ThisTask().currentMarker)) then
				local expireTime = ml_task_hub:ThisTask().markerTime
				if (Now() > expireTime) then
					ml_debug("Getting Next Marker, TIME IS UP!")
					marker = ml_marker_mgr.GetNextMarker(ml_task_hub:ThisTask().currentMarker:GetType(), ml_task_hub:ThisTask().filterLevel)
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
	self.timer = Now() + 500
	
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
	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 30 )
    self:add( ke_inventoryFull, self.overwatch_elements)
	
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 20 )
    self:add( ke_dead, self.overwatch_elements)
    
    local ke_stealth = ml_element:create( "Stealth", c_stealth, e_stealth, 15 )
    self:add( ke_stealth, self.overwatch_elements)
  
    --init Process() cnes
    local ke_resetIdle = ml_element:create( "ResetIdle", c_resetidle, e_resetidle, 110 )
    self:add(ke_resetIdle, self.process_elements)
	
	local ke_nextMarker = ml_element:create( "NextMarker", c_nextfishingmarker, e_nextfishingmarker, 100 )
    self:add( ke_nextMarker, self.process_elements)
    
    local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 90 )
    self:add( ke_returnToMarker, self.process_elements)
    
    local ke_setbait = ml_element:create( "SetBait", c_setbait, e_setbait, 80 )
    self:add(ke_setbait, self.process_elements)
	
	local ke_syncadjust = ml_element:create( "SyncAdjust", c_syncadjust, e_syncadjust, 70)
	self:add(ke_syncadjust, self.process_elements)
	
	local ke_precast = ml_element:create( "PreCast", c_precastbuff, e_precastbuff, 60 )
    self:add(ke_precast, self.process_elements)
	
	local ke_patience = ml_element:create( "Patience", c_patience, e_patience, 55 )
    self:add(ke_patience, self.process_elements)
	
	local ke_mooch = ml_element:create( "Mooch", c_mooch, e_mooch, 50 )
    self:add(ke_mooch, self.process_elements)
	
	local ke_release = ml_element:create( "Release", c_release, e_release, 40 )
    self:add(ke_release, self.process_elements)	
    
    local ke_cast = ml_element:create( "Cast", c_cast, e_cast, 30 )
    self:add(ke_cast, self.process_elements)
    
    local ke_bite = ml_element:create( "Bite", c_bite, e_bite, 20 )
    self:add(ke_bite, self.process_elements)
   
    
    self:AddTaskCheckCEs()
end

-- UI settings etc
function ffxiv_task_fish.UIInit()
	ffxivminion.Windows.Fish = { id = strings["us"].fishMode, Name = GetString("fishMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Fish)
	
	local winName = GetString("fishMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	GUI_NewButton(winName, GetString("markerManager"), "ToggleMarkerMgr")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("navmesh") ,"gmeshname",group,ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
	GUI_NewField(winName,GetString("markerName"),"gStatusMarkerName",group )
	GUI_NewField(winName,GetString("markerTime"),"gStatusMarkerTime",group )
	
	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
    
    RegisterEventHandler("GUI.Update",ffxiv_task_fish.GUIVarUpdate)
	
	ffxiv_task_fish.SetupMarkers()
end

function ffxiv_task_fish.SetupMarkers()
    -- add marker templates for fishing
    local fishingMarker = ml_marker:Create("fishingTemplate")
	fishingMarker:SetType(GetString("fishingMarker"))
	fishingMarker:AddField("string", GetString("baitName"), "")
	fishingMarker:AddField("checkbox", GetString("useMooch"), "1")
	fishingMarker:AddField("checkbox", GetString("usePatience"), "0")
	fishingMarker:AddField("checkbox", GetString("usePatience2"), "0")
	fishingMarker:AddField("string", GetString("moochableFish"), "")
	fishingMarker:AddField("string", GetString("whitelistFish"), "")
	fishingMarker:AddField("string", GetString("whitelistFishHQ"), "")
	fishingMarker:AddField("string", GetString("blacklistFish"), "")
	fishingMarker:AddField("string", GetString("blacklistFishHQ"), "")
	fishingMarker:AddField("checkbox", GetString("useStealth"), "1")
	fishingMarker:AddField("checkbox", GetString("dangerousArea"), "0")
	
    fishingMarker:SetTime(300)
    fishingMarker:SetMinLevel(1)
    fishingMarker:SetMaxLevel(60)
    ml_marker_mgr.AddMarkerTemplate(fishingMarker)
	
    -- refresh the manager with the new templates
    ml_marker_mgr.RefreshMarkerTypes()
	ml_marker_mgr.RefreshMarkerNames()
end
ffxiv_task_fish = inheritsFrom(ml_task)
ffxiv_task_fish.name = "LT_FISH"

function ffxiv_task_fish.Create()
    local newinst = inheritsFrom(ffxiv_task_fish)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_fish members
    newinst.castTimer = 0
    newinst.markerTime = 0
    newinst.currentMarker = false
    newinst.baitName = ""
    newinst.castFailTimer = 0
	newinst.filterLevel = true
    newinst.missingBait = false
	newinst.networkLatency = 0
	newinst.requiresAdjustment = false
    
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
            return true
        end
    end
    return false
end
function e_cast:execute()
	local marker = ml_task_hub:CurrentTask().currentMarker
	local useMooch = false
	if (ValidTable(marker)) then
		useMooch = marker:GetFieldValue(strings[gCurrentLanguage].useMooch) == "1" and true or false
	elseif (gFishNoMarker == "1") then
		useMooch = gUseMooch == "1" and true or false
	end
	
    local mooch = ActionList:Get(297,1)
    if (mooch) and Player.level > 24 and (mooch.isready) and useMooch then
        mooch:Cast()
		ml_task_hub:CurrentTask().castTimer = Now() + 1500
    else
        local cast = ActionList:Get(289,1)
        if (cast and cast.isready) then	
            cast:Cast()
			ml_task_hub:CurrentTask().castTimer = Now() + 1500
        end
    end
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
    local bite = ActionList:Get(296,1)
    if (bite and bite.isready) then
        bite:Cast()
    end
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
            local baitName = marker:GetFieldValue(strings[gCurrentLanguage].baitName)
            if (baitName ~= "None" and baitName ~= ml_task_hub:CurrentTask().baitName) then
                --check to see if we have the bait in inventory
                ml_debug("Looking for bait named "..baitName)
                for i = 0,3 do
                    local inventory = Inventory("type="..tostring(i))
                    if (inventory ~= nil and inventory ~= 0) then
                        for _,item in ipairs(inventory) do
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
	
    if ( ml_task_hub:CurrentTask().currentMarker ~= nil and ml_task_hub:CurrentTask().currentMarker ~= 0 ) then
        local marker = nil
        
        -- first check to see if we have no initiailized marker
        if (ml_task_hub:CurrentTask().currentMarker == false) then --default init value
            marker = ml_marker_mgr.GetNextMarker(strings[gCurrentLanguage].fishingMarker, ml_task_hub:CurrentTask().filterLevel)
        
			if (marker == nil) then
				ml_task_hub:CurrentTask().filterLevel = false
				marker = ml_marker_mgr.GetNextMarker(strings[gCurrentLanguage].fishingMarker, ml_task_hub:CurrentTask().filterLevel)
			end	
		end
        
        -- next check to see if our level is out of range
        if (marker == nil) then
            if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then
                if 	(ml_task_hub:CurrentTask().filterLevel) and
					(Player.level < ml_task_hub:CurrentTask().currentMarker:GetMinLevel() or 
                    Player.level > ml_task_hub:CurrentTask().currentMarker:GetMaxLevel()) 
                then
                    marker = ml_marker_mgr.GetNextMarker(strings[gCurrentLanguage].fishingMarker, ml_task_hub:CurrentTask().filterLevel)
                end
            end
        end
        
        -- last check if our time has run out
        if (marker == nil) then
            local time = ml_task_hub:CurrentTask().currentMarker:GetTime()
			if (time and time ~= 0 and TimeSince(ml_task_hub:CurrentTask().markerTime) > time * 1000) then
				--ml_debug("Marker timer: "..tostring(TimeSince(ml_task_hub:CurrentTask().markerTime)) .."seconds of " ..tostring(time)*1000)
                ml_debug("Getting Next Marker, TIME IS UP!")
                marker = ml_marker_mgr.GetNextMarker(strings[gCurrentLanguage].fishingMarker, ml_task_hub:CurrentTask().filterLevel)
            else
                return false
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
    ml_task_hub:CurrentTask().currentMarker = e_nextfishingmarker.marker
    ml_task_hub:CurrentTask().markerTime = ml_global_information.Now
	ml_global_information.MarkerTime = ml_global_information.Now
    ml_global_information.MarkerMinLevel = ml_task_hub:CurrentTask().currentMarker:GetMinLevel()
    ml_global_information.MarkerMaxLevel = ml_task_hub:CurrentTask().currentMarker:GetMaxLevel()
	gStatusMarkerName = ml_task_hub:CurrentTask().currentMarker:GetName()
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
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 20 )
    self:add( ke_dead, self.overwatch_elements)
    
    local ke_stealth = ml_element:create( "Stealth", c_stealth, e_stealth, 15 )
    self:add( ke_stealth, self.overwatch_elements)
  
    --init Process() cnes
    --local ke_finishcast = ml_element:create( "FinishingCast", c_finishcast, e_finishcast, 30 )
    --self:add(ke_finishcast, self.process_elements)
    
    local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 25 )
    self:add( ke_returnToMarker, self.process_elements)
    
    --nextmarker defined in ffxiv_task_gather.lua
    local ke_nextMarker = ml_element:create( "NextMarker", c_nextfishingmarker, e_nextfishingmarker, 20 )
    self:add( ke_nextMarker, self.process_elements)
    
    local ke_setbait = ml_element:create( "SetBait", c_setbait, e_setbait, 10 )
    self:add(ke_setbait, self.process_elements)
	
	local ke_syncadjust = ml_element:create( "SyncAdjust", c_syncadjust, e_syncadjust, 8)
	self:add(ke_syncadjust, self.process_elements)
	
	local ke_precast = ml_element:create( "PreCast", c_precastbuff, e_precastbuff, 7 )
    self:add(ke_precast, self.process_elements)
    
    local ke_cast = ml_element:create( "Cast", c_cast, e_cast, 5 )
    self:add(ke_cast, self.process_elements)
    
    local ke_bite = ml_element:create( "Bite", c_bite, e_bite, 5 )
    self:add(ke_bite, self.process_elements)
   
    
    self:AddTaskCheckCEs()
end

-- UI settings etc
function ffxiv_task_fish.UIInit()
	ffxivminion.Windows.Fish = { id = strings["us"].fishMode, Name = GetString("fishMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Fish)

	if ( Settings.FFXIVMINION.gFishNoMarker == nil ) then
        Settings.FFXIVMINION.gFishNoMarker = "0"
	end
	if ( Settings.FFXIVMINION.gUseMooch == nil ) then
		Settings.FFXIVMINION.gUseMooch = "1"
	end
	
	local winName = GetString("fishMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].botMode,"gBotMode",group,"None")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].navmesh ,"gmeshname",group,ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,strings[gCurrentLanguage].botEnabled,"gBotRunning",group)
	GUI_NewField(winName,strings[gCurrentLanguage].markerName,"gStatusMarkerName",group )
	GUI_NewField(winName,strings[gCurrentLanguage].markerTime,"gStatusMarkerTime",group )
	local group = GetString("settings")
    GUI_NewCheckbox(winName,strings[gCurrentLanguage].noMarker,"gFishNoMarker",group)
	GUI_NewCheckbox(winName,strings[gCurrentLanguage].useMooch,"gUseMooch",group)
	
	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gUseMooch = Settings.FFXIVMINION.gUseMooch
	gFishNoMarker = Settings.FFXIVMINION.gFishNoMarker
    
    RegisterEventHandler("GUI.Update",ffxiv_task_fish.GUIVarUpdate)
	
	ffxiv_task_fish.SetupMarkers()
end

function ffxiv_task_fish.SetupMarkers()
    -- add marker templates for fishing
    local fishingMarker = ml_marker:Create("fishingTemplate")
	fishingMarker:SetType(strings[gCurrentLanguage].fishingMarker)
	fishingMarker:AddField("string", strings[gCurrentLanguage].baitName, "")
	fishingMarker:AddField("checkbox", strings[gCurrentLanguage].useMooch, "1")
	fishingMarker:AddField("checkbox", strings[gCurrentLanguage].useStealth, "0")
    fishingMarker:SetTime(300)
    fishingMarker:SetMinLevel(1)
    fishingMarker:SetMaxLevel(50)
    ml_marker_mgr.AddMarkerTemplate(fishingMarker)
	
    -- refresh the manager with the new templates
    ml_marker_mgr.RefreshMarkerTypes()
	ml_marker_mgr.RefreshMarkerNames()
end

function ffxiv_task_fish.GUIVarUpdate(Event, NewVals, OldVals)
	 for k,v in pairs(NewVals) do
		if ( 	k == "gUseMooch" or
				k == "gFishNoMarker" ) then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(GetString("fishMode"))
end
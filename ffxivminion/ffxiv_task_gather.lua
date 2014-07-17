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
    newinst.gatherTimer = 0
	newinst.gatherDistance = 1.5
	newinst.maxGatherDistance = 100 -- for setting the range when the character is beeing considered "too far away from the gathermarker" where it would make him run back to the marker
	newinst.gatheredMap = false
	newinst.gatheredGardening = false
    newinst.idleTimer = 0
	newinst.filterLevel = true
    
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
	local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
        return false
    end

    if ( ml_task_hub:CurrentTask().gatherid == nil or ml_task_hub:CurrentTask().gatherid == 0 ) then
        return true
    end
    
    local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
    if (gatherable ~= nil) then
        if (not gatherable.cangather) then
            return true 
        end
    elseif (gatherable == nil) then
        return true
    end
    
    return false
end
function e_findgatherable:execute()
    ml_debug( "Getting new gatherable target" )
    local minlevel = 1
    local maxlevel = 50
    if (ValidTable(ml_task_hub:CurrentTask().currentMarker) and
		gMarkerMgrMode ~= strings[gCurrentLanguage].singleMarker) 
	then
		minlevel = ml_task_hub:CurrentTask().currentMarker:GetMinLevel()
		maxlevel = ml_task_hub:CurrentTask().currentMarker:GetMaxLevel()
    end
    
    local gatherable = GetNearestGatherable(minlevel,maxlevel)
    if (gatherable ~= nil) then
		-- reset blacklist vars for a new node
		ml_task_hub:CurrentTask().failedTimer = 0		
		ml_task_hub:CurrentTask().gatheredMap = false
        ml_task_hub:CurrentTask().gatherid = gatherable.id		
				
		-- setting the maxrange for the "return to marker" check, so we dont have a pingpong navigation between going to node and going back to marker		
		if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then
			local nodePos = gatherable.pos
			local markerPos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
            
			--just for testing
			local distance2d = Distance2D(nodePos.x, nodePos.z, markerPos.x, markerPos.z)
			ml_debug("Distance2D Node <-> current Marker: "..tostring(distance2d))		
			local pathdist = NavigationManager:GetPath(nodePos.x,nodePos.y,nodePos.z,markerPos.x, markerPos.y,markerPos.z)
			if ( pathdist ) then
				local pdist = PathDistance(pathdist)
				ml_debug("Path distance Node <-> current Marker : "..tostring(pdist))
				if ( pdist > 50 ) then
					ml_task_hub:CurrentTask().maxGatherDistance = pdist + 25
					return
				end
			end			
		end
		--default 
		ml_task_hub:CurrentTask().maxGatherDistance = 250
		
    else
		-- no gatherables nearby, try to walk to next gather marker by setting the current marker's timer to "exceeded"
        if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then            
			if ( TimeSince(ml_task_hub:CurrentTask().gatherTimer) > 1500 ) then
                local markerPos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
				local pPos = Player.pos
				-- we are nearby our marker and no nodes are nearby anymore, grab the next one
				if (Distance2D(pPos.x, pPos.z, markerPos.x, markerPos.z) < 15) then
					local t = ml_task_hub:CurrentTask().currentMarker:GetTime()
					ml_task_hub:CurrentTask().markerTime = ml_task_hub:CurrentTask().markerTime - t
				else
					-- walk to the center of our marker first
					if (markerPos ~= nil and markerPos ~= 0) then
						Player:MoveTo(markerPos.x, markerPos.y, markerPos.z, 10, false, gRandomPaths=="1")
                        ml_task_hub:CurrentTask().idleTimer = ml_global_information.Now
					end
				end
            end
        end
    end
	
	--idiotcheck for no usable markers found on this mesh
	if (ml_task_hub:CurrentTask().currentMarker ~= nil and ml_task_hub:CurrentTask().currentMarker ~= 0 and ml_task_hub:CurrentTask().currentMarker == false) then
        ml_error("THE LOADED NAVMESH HAS NO MINING/BOTANY MARKERS IN THE LEVELRANGE OF YOUR PLAYER")	
	end
	return false
end

c_movetogatherable = inheritsFrom( ml_cause )
e_movetogatherable = inheritsFrom( ml_effect )
function c_movetogatherable:evaluate()
    if ( TimeSince(ml_task_hub:CurrentTask().gatherTimer) < 1500 ) then
        return false
    end
    
    if ( ml_task_hub:CurrentTask().gatherid ~= nil and ml_task_hub:CurrentTask().gatherid ~= 0 ) then
        local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
        if (Player:GetGatherableSlotList() == nil and gatherable ~= nil and gatherable.distance2d > (ml_task_hub:CurrentTask().gatherDistance + 0.5)) then
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
        if (gTeleport == "1") then
            GameHacks:TeleportToXYZ(pos.x,pos.y,pos.z)
        else
            local newTask = ffxiv_task_movetopos.Create()
            newTask.pos = pos
            newTask.range = ml_task_hub:CurrentTask().gatherDistance
            newTask.gatherRange = 0.0
            ml_task_hub:CurrentTask():AddSubTask(newTask)
        end
    end
end

c_nextgathermarker = inheritsFrom( ml_cause )
e_nextgathermarker = inheritsFrom( ml_effect )
function c_nextgathermarker:evaluate()
    local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
        return false
    end
	
	if (gMarkerMgrMode == strings[gCurrentLanguage].singleMarker) then
		ml_task_hub:CurrentTask().filterLevel = false
	end
    
    if ( ml_task_hub:CurrentTask().currentMarker ~= nil and ml_task_hub:CurrentTask().currentMarker ~= 0 ) then
        local marker = nil
        
        -- first check to see if we have no initialized marker
        if (ml_task_hub:CurrentTask().currentMarker == false) then --default init value
            local markerType = ""
            if (Player.job == FFXIV.JOBS.BOTANIST) then
                markerType = strings[gCurrentLanguage].botanyMarker
            else
                markerType = strings[gCurrentLanguage].miningMarker
            end
            marker = ml_marker_mgr.GetNextMarker(markerType, ml_task_hub:CurrentTask().filterLevel)
			
			if (marker == nil) then
				ml_task_hub:CurrentTask().filterLevel = false
				marker = ml_marker_mgr.GetNextMarker(markerType, ml_task_hub:CurrentTask().filterLevel)
			end
        end
        
        -- next check to see if our level is out of range
        if (marker == nil) then
            if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then
                if 	(ml_task_hub:CurrentTask().filterLevel) and
					(Player.level < ml_task_hub:CurrentTask().currentMarker:GetMinLevel() or 
                    Player.level > ml_task_hub:CurrentTask().currentMarker:GetMaxLevel()) 
                then
                    marker = ml_marker_mgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker:GetType(), ml_task_hub:CurrentTask().filterLevel)
                end
            end
        end
        
        -- next check to see if we can't find any gatherables at our current marker
        if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then            
			if ( ml_task_hub:CurrentTask().idleTimer ~= 0 and TimeSince(ml_task_hub:CurrentTask().idleTimer) > 30 * 1000 ) then
                ml_task_hub:CurrentTask().idleTimer = 0
                local markerPos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
				local pPos = Player.pos
				-- we are nearby our marker and no nodes are nearby anymore, grab the next one
				if (Distance2D(pPos.x, pPos.z, markerPos.x, markerPos.z) < 15) then
                    marker = ml_marker_mgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker:GetType(), ml_task_hub:CurrentTask().filterLevel)
				end
            end
        end
        
        -- last check if our time has run out
        if (marker == nil) then
            local time = ml_task_hub:CurrentTask().currentMarker:GetTime()
			if (time and time ~= 0 and TimeSince(ml_task_hub:CurrentTask().markerTime) > time * 1000) then
				--ml_debug("Marker timer: "..tostring(TimeSince(ml_task_hub:CurrentTask().markerTime)) .."seconds of " ..tostring(time)*1000)
                ml_debug("Getting Next Marker, TIME IS UP!")
                marker = ml_marker_mgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker:GetType(), ml_task_hub:CurrentTask().filterLevel)
            else
                return false
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
    ml_task_hub:CurrentTask().currentMarker = e_nextgathermarker.marker
    ml_task_hub:CurrentTask().markerTime = ml_global_information.Now
	ml_global_information.MarkerTime = ml_global_information.Now
    ml_global_information.MarkerMinLevel = ml_task_hub:CurrentTask().currentMarker:GetMinLevel()
    ml_global_information.MarkerMaxLevel = ml_task_hub:CurrentTask().currentMarker:GetMaxLevel()
	ml_global_information.BlacklistContentID = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].NOTcontentIDEquals)
    ml_global_information.WhitelistContentID = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].contentIDEquals)
	gStatusMarkerName = ml_task_hub:CurrentTask().currentMarker:GetName()
end

c_gather = inheritsFrom( ml_cause )
e_gather = inheritsFrom( ml_effect )
function c_gather:evaluate()
    local list = Player:GetGatherableSlotList()
    local node = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
    if (list or (node ~= nil and node.distance2d < ml_task_hub:CurrentTask().gatherDistance + 0.5)) then
        return true
    end
    
	ml_global_information.IsWaiting = false
    return false
end
function e_gather:execute()
	Dismount()
	
    local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
		ml_global_information.IsWaiting = true
        
		-- reset fail timer
        if (ml_task_hub:CurrentTask().failedTimer ~= 0) then
            ml_task_hub:CurrentTask().failedTimer = 0
        end
    
        if ( gSMactive == "1") then
			if (ActionList:IsCasting()) then return end
            if (SkillMgr.Gather() ) then
				ml_task_hub:CurrentTask().failedTimer = ml_global_information.Now -- just to make sure it doesnt cast skills and somehow while moving away from the node blacklits it..dont know if that is needed
                return
            end
        end

		if (TimeSince(ml_task_hub:CurrentTask().interactTimer) > 1000) then
			-- first try to get treasure maps
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
					if (IsMap(item.id)) then
						Player:Gather(item.index)
						ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
						return
					end
				end
			end
			
			-- second try to get gardening supplies
			if (not ml_task_hub:CurrentTask().gatheredGardening) then
				for i, item in pairs(list) do
					if 	(IsGardening(item.id))
					then
						Player:Gather(item.index)
						ml_task_hub:CurrentTask().gatheredGardening = true
						ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
						return
					end
				end
			end
			
			if (ValidTable(ml_task_hub:CurrentTask().currentMarker)) then
				-- do 2 loops to allow prioritization of first item
				local item1 = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].selectItem1)
				local item2 = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].selectItem2)
				
				if (item1 ~= "") then
					for i, item in pairs(list) do
						local n = tonumber(item1)
						if (n ~= nil) then
							if (item.index == (n-1) and item.id ~= nil) then
								Player:Gather(n-1)
								ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
								return
							end
						else						
							if (item.name == item1) then
								Player:Gather(item.index)
								ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
								return
							end
						end
					end
				end
				
				if (item2 ~= "") then
					for i, item in pairs(list) do
						local n = tonumber(item2)
						if (n ~= nil) then
							if (item.index == (n-1) and item.id ~= nil) then
								Player:Gather(n-1)
								ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
								return
							end
						else						
							if (item.name == item2) then
								Player:Gather(item.index)
								ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
								return
							end
						end
					end
				end
			end
			
			-- just grab a random item otherwise
			for i, item in pairs(list) do
				if item.chance > 50 and not IsGardening(item.id) and not IsMap(item.id) then
					Player:Gather(item.index)
					ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
					return
				end
			end
		end
    else
		ml_global_information.IsWaiting = false
        local node = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
        if ( node ) then
            local target = Player:GetTarget()
            if ( (target ~=nil and target.id ~= node.id) or target == nil or target == {} ) then
                Player:SetTarget(node.id)
            else
				--Eat()
                Player:Interact(node.id)
				ml_task_hub:CurrentTask().interactTimer = ml_global_information.Now
                -- start fail timer
                if (ml_task_hub:CurrentTask().failedTimer == 0) then
                    ml_task_hub:CurrentTask().failedTimer = ml_global_information.Now
                elseif (TimeSince(ml_task_hub:CurrentTask().failedTimer) > 12000) then
					ml_blacklist.AddBlacklistEntry(strings[gCurrentLanguage].gatherMode, node.id, node.name, ml_global_information.Now + 1800*1000)
					ml_task_hub:CurrentTask().gatherid = 0
					ml_task_hub:CurrentTask().failedTimer = 0
				end
            end

            if (gTeleport == "1") then
                Player:MoveToStraight(Player.pos.x+2, Player.pos.y, Player.pos.z+2)
            end
        else
            --ml_debug(" EntityList:Get(ml_task_hub:CurrentTask().gatherid) returned no node!")
        end
    end
end

c_gatherwindow = inheritsFrom( ml_cause )
e_gatherwindow = inheritsFrom( ml_effect )
function c_gatherwindow:evaluate()
	local list = Player:GetGatherableSlotList()
    if (list ~= nil and ml_task_hub:CurrentTask().name == "MOVETOPOS") then
		return true
	end
end
function e_gatherwindow:execute()
	ml_debug("Bad! We fell into the gathering/moveto timing bug...terminating MoveTo task")
	-- Complete the moveto task so that we can go back to gathering window
	ml_task_hub:CurrentTask():task_complete_execute()
end

function ffxiv_task_gather:Init()
    --init ProcessOverWatch cnes
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 25 )
    self:add( ke_dead, self.overwatch_elements)
    
    local ke_stealth = ml_element:create( "Stealth", c_stealth, e_stealth, 15 )
    self:add( ke_stealth, self.overwatch_elements)
	
	local ke_gatherWindow = ml_element:create( "GatherWindow", c_gatherwindow, e_gatherwindow, 20)
	self:add( ke_gatherWindow, self.overwatch_elements)
    
    --init Process cnes
    --in descending priority order just for you stefan
    local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 25 )
    self:add( ke_returnToMarker, self.process_elements)
    
    local ke_nextMarker = ml_element:create( "NextMarker", c_nextgathermarker, e_nextgathermarker, 20 )
    self:add( ke_nextMarker, self.process_elements)
    
    local ke_findGatherable = ml_element:create( "FindGatherable", c_findgatherable, e_findgatherable, 15 )
    self:add(ke_findGatherable, self.process_elements)
    
    local ke_moveToGatherable = ml_element:create( "MoveToGatherable", c_movetogatherable, e_movetogatherable, 10 )
    self:add( ke_moveToGatherable, self.process_elements)
    
    local ke_gather = ml_element:create( "Gather", c_gather, e_gather, 5 )
    self:add(ke_gather, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_gather:OnSleep()

end

function ffxiv_task_gather:OnTerminate()

end

function ffxiv_task_gather:IsGoodToAbort()

end

function ffxiv_task_gather.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if (	k == "gGatherPS"	) then
            if (v == "1") then
                GameHacks:SetPermaSprint(true)
            else
                GameHacks:SetPermaSprint(false)
            end
        end
        if ( 	k == "gDoStealth" or
                k == "gGatherPS" ) then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(ffxivminion.Windows.Main.Name)
end

-- UI settings etc
function ffxiv_task_gather.UIInit()
    GUI_NewCheckbox(GetString("advancedSettings"), strings[gCurrentLanguage].useStealth, "gDoStealth",strings[gCurrentLanguage].gatherMode)
    GUI_NewCheckbox(ffxivminion.Windows.Main.Name, strings[gCurrentLanguage].permaSprint, "gGatherPS",GetString("hacks"))
    
    ffxivminion.ResizeWindow()
    
    if (Settings.FFXIVMINION.gDoStealth == nil) then
        Settings.FFXIVMINION.gDoStealth = "0"
    end
    
    
    if (Settings.FFXIVMINION.gGatherPS == nil) then
        Settings.FFXIVMINION.gGatherPS = "0"
    end
    
    gDoStealth = Settings.FFXIVMINION.gDoStealth
    gGatherPS = Settings.FFXIVMINION.gGatherPS
    if(gGatherPS == "1") then
        GameHacks:SetPermaSprint(true)
    end
    
    ffxiv_task_gather.SetupMarkers()
    
    RegisterEventHandler("GUI.Update",ffxiv_task_gather.GUIVarUpdate)
end

function ffxiv_task_gather.SetupMarkers()
    -- add marker templates for gathering
    local botanyMarker = ml_marker:Create("botanyTemplate")
	botanyMarker:SetType(strings[gCurrentLanguage].botanyMarker)
	botanyMarker:AddField("string", strings[gCurrentLanguage].selectItem1, "")
	botanyMarker:AddField("string", strings[gCurrentLanguage].selectItem2, "")
	botanyMarker:AddField("string", strings[gCurrentLanguage].contentIDEquals, "")
	botanyMarker:AddField("string", strings[gCurrentLanguage].NOTcontentIDEquals, "")
    botanyMarker:SetTime(300)
    botanyMarker:SetMinLevel(1)
    botanyMarker:SetMaxLevel(50)
    ml_marker_mgr.AddMarkerTemplate(botanyMarker)
	
	local miningMarker = botanyMarker:Copy()
	miningMarker:SetName("miningTemplate")
	miningMarker:SetType(strings[gCurrentLanguage].miningMarker)
    ml_marker_mgr.AddMarkerTemplate(miningMarker)
    
    -- refresh the manager with the new templates
    ml_marker_mgr.RefreshMarkerTypes()
	ml_marker_mgr.RefreshMarkerNames()
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
}        
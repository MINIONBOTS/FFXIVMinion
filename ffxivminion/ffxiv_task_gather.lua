ffxiv_task_gather = inheritsFrom(ml_task)
ffxiv_task_gather.name = "LT_GATHER"

function ffxiv_task_gather:Create()
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
    newinst.previousMarker = false
    newinst.gatherTimer = 0
	newinst.gatherDistance = 1.5
	newinst.maxGatherDistance = 100 -- for setting the range when the character is beeing considered "too far away from the gathermarker" where it would make him run back to the marker
    
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
    if ( ml_task_hub.CurrentTask().gatherid == nil or ml_task_hub.CurrentTask().gatherid == 0 ) then
        return true
    end
    
    local gatherable = EntityList:Get(ml_task_hub.CurrentTask().gatherid)
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
    if (ml_task_hub:CurrentTask().currentMarker ~= nil and ml_task_hub:CurrentTask().currentMarker ~= false) then
        local markerInfo = mm.GetMarkerInfo(ml_task_hub:CurrentTask().currentMarker)
        if ValidTable(markerInfo) then
            minlevel = markerInfo.minlevel
            maxlevel = markerInfo.maxlevel
        end
    end
    
    local gatherable = GetNearestGatherable(minlevel,maxlevel)
    if (gatherable ~= nil) then
		-- reset blacklist vars for a new node
		ml_task_hub:CurrentTask().failedTimer = 0		
        ml_task_hub.CurrentTask().gatherid = gatherable.id		
				
		-- setting the maxrange for the "return to marker" check, so we dont have a pingpong navigation between going to node and going back to marker		
		if (ml_task_hub:CurrentTask().currentMarker ~= nil and ml_task_hub:CurrentTask().currentMarker ~= 0) then
			local markerInfo = mm.GetMarkerInfo(ml_task_hub:CurrentTask().currentMarker)
			local nodePos = gatherable.pos
			
			--just for testing
			local distance2d = Distance2D(nodePos.x, nodePos.z, markerInfo.x, markerInfo.z)
			ml_debug("Distance2D Node <-> current Marker: "..tostring(distance2d))		
			local pathdist = NavigationManager:GetPath(nodePos.x,nodePos.y,nodePos.z,markerInfo.x, markerInfo.y,markerInfo.z)
			if ( pathdist ) then
				local pdist = PathDistance(pathdist)
				ml_debug("Path distance Node <-> current Marker : "..tostring(pdist))
				if ( pdist > 50 ) then
					ml_task_hub.CurrentTask().maxGatherDistance = pdist + 25
					return
				end
			end			
		end
		--default 
		ml_task_hub.CurrentTask().maxGatherDistance = 250
		
    else
		-- no gatherables nearby, try to walk to next gather marker by setting the current marker's timer to "exceeded"
        if (ml_task_hub:CurrentTask().currentMarker ~= nil and ml_task_hub:CurrentTask().currentMarker ~= 0) then
            if ( os.difftime(os.time(), ml_task_hub:CurrentTask().gatherTimer) > 1 ) then
                local markerInfo = mm.GetMarkerInfo(ml_task_hub:CurrentTask().currentMarker)
				local pPos = Player.pos
				-- we are nearby our marker and no nodes are nearby anymore, grab the next one
				if (Distance2D(pPos.x, pPos.z, markerInfo.x, markerInfo.z) < 15) then
					local t = GatherMgr.GetMarkerTime(ml_task_hub:CurrentTask().currentMarker)
					ml_task_hub:CurrentTask().markerTime = ml_task_hub:CurrentTask().markerTime - t
				else
					-- walk to the center of our marker first
					if (markerInfo ~= nil and markerInfo ~= 0) then
						Player:MoveTo(markerInfo.x, markerInfo.y, markerInfo.z, 10, false, gRandomPaths=="1")
					end
				end
            end
        end
    end
end

c_movetogatherable = inheritsFrom( ml_cause )
e_movetogatherable = inheritsFrom( ml_effect )
function c_movetogatherable:evaluate()
    if ( os.difftime(os.time(), ml_task_hub:CurrentTask().gatherTimer) < 1 ) then
        return false
    end
    
    if ( ml_task_hub:CurrentTask().gatherid ~= nil and ml_task_hub:CurrentTask().gatherid ~= 0 ) then
        local gatherable = EntityList:Get(ml_task_hub.CurrentTask().gatherid)
        if (Player:GetGatherableSlotList() == nil and gatherable ~= nil and gatherable.distance2d > (ml_task_hub.CurrentTask().gatherDistance + 0.5)) then
            return true
        end
    end
    
    return false
end
function e_movetogatherable:execute()
    local pos = EntityList:Get(ml_task_hub.CurrentTask().gatherid).pos
    if (pos ~= nil and pos ~= 0) then
        if (gGatherTP == "1") then
            GameHacks:TeleportToXYZ(pos.x,pos.y,pos.z)
        else
            local newTask = ffxiv_task_movetopos:Create()
            newTask.pos = pos
            newTask.range = ml_task_hub.CurrentTask().gatherDistance
            newTask.gatherRange = 0.0
            ml_task_hub:CurrentTask():AddSubTask(newTask)
        end
    end
end

c_nextmarker = inheritsFrom( ml_cause )
e_nextmarker = inheritsFrom( ml_effect )
function c_nextmarker:evaluate()
    -- this function (along with the marker manager stuff in general) needs a major refactor
    -- for the purposes of beta I'm just doing all the marker checking shit for all modes here
    if (gBotMode == strings[gCurrentLanguage].partyMode and not IsLeader() ) then
        return false
    end
    
    if ((gBotMode == strings[gCurrentLanguage].gatherMode or gBotMode == strings[gCurrentLanguage].fishMode) and gGMactive == "0") or
       (gBotMode == strings[gCurrentLanguage].grindMode and gDoFates == "1" and gFatesOnly == "1")
    then
        return false
    end
    
    if gBotMode == strings[gCurrentLanguage].gatherMode then
        local list = Player:GetGatherableSlotList()
        if (list ~= nil) then
            return false
        end
    end
    
    if ( ml_task_hub:CurrentTask().currentMarker ~= nil and ml_task_hub:CurrentTask().currentMarker ~= 0) then
        local marker = nil
        
        -- first check to see if we have no initiailized marker
        if (ml_task_hub:CurrentTask().currentMarker == false) then --default init value
            marker = GatherMgr.GetNextMarker(nil, nil)
        end
        
        -- next check to see if our level is out of range
        if (marker == nil) then
            local markerInfo = mm.GetMarkerInfo(ml_task_hub:CurrentTask().currentMarker)
            if (ValidTable(markerInfo)) then
                local markerType = mm.GetMarkerType(ml_task_hub:CurrentTask().currentMarker)
                if 	(markerType == "grindSpot" and gIgnoreGrindLvl == "0") or
                    ((markerType == "botanySpot" or markerType == "miningSpot") and gIgnoreGatherLvl == "0") or
                    (markerType == "fishingSpot" and gIgnoreFishLvl == "0") 
                then
                    if (Player.level < markerInfo.minlevel or Player.level > markerInfo.maxlevel) then
                        marker = GatherMgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker, ml_task_hub:CurrentTask().previousMarker)
                    end
                end
            end
        end
        
        -- last check if our time has run out
        if (marker == nil) then
            local time = GatherMgr.GetMarkerTime(ml_task_hub:CurrentTask().currentMarker)
            if gBotMode == strings[gCurrentLanguage].grindMode or gBotMode == strings[gCurrentLanguage].partyMode then
                time = math.random(600,1200)
            end
            ml_debug("Marker timer: "..tostring(os.difftime(os.time(),ml_task_hub:CurrentTask().markerTime) .."seconds of " ..tostring(time)))
			if (time and time ~= 0 and os.difftime(os.time(),ml_task_hub:CurrentTask().markerTime) > time) then
                ml_debug("Getting Next Marker, TIME IS UP!")
                marker = GatherMgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker, ml_task_hub:CurrentTask().previousMarker)
            else
                return false
            end
        end
        
        if marker ~= nil then
            if marker ~= ml_task_hub:CurrentTask().currentMarker then
                e_nextmarker.marker = marker
                return true
            end
        elseif (gBotMode == strings[gCurrentLanguage].grindMode or gBotMode == strings[gCurrentLanguage].partyMode) then
            --ignore it so people don't whine about debug spam
            --ml_debug("No grind markers detected. Defaulting to local grinding at current position")
        else
            ml_error("The gather manager is enabled but no markers have been detected on mesh. Defaulting to random behavior and disabling gather manager")
            gGMactive = "0"
        end
    end
    
    return false
end
function e_nextmarker:execute()
    ml_task_hub:CurrentTask().previousMarker = ml_task_hub:CurrentTask().currentMarker
    ml_task_hub:CurrentTask().currentMarker = e_nextmarker.marker
    ml_task_hub:CurrentTask().markerTime = os.time()
    
    local markerInfo = mm.GetMarkerInfo(ml_task_hub:CurrentTask().currentMarker)
    local markerType = mm.GetMarkerType(ml_task_hub:CurrentTask().currentMarker)
    
    if (TableSize(markerInfo) > 0) then
        ml_global_information.MarkerMinLevel = markerInfo.minlevel
        ml_global_information.MarkerMaxLevel = markerInfo.maxlevel
    else
        ml_global_information.MarkerMinLevel = 1
        ml_global_information.MarkerMaxLevel = 50
    end
end

c_gather = inheritsFrom( ml_cause )
e_gather = inheritsFrom( ml_effect )
function c_gather:evaluate()
    local list = Player:GetGatherableSlotList()
    local node = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
    if (list or (node ~= nil and node.distance2d < ml_task_hub:CurrentTask().gatherDistance + 0.5)) then
        return true
    end
    
    return false
end
function e_gather:execute()    
    local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
        -- reset fail timer
        if (ml_task_hub:CurrentTask().failedTimer ~= 0) then
            ml_task_hub:CurrentTask().failedTimer = 0
        end
    
        if ( gSMactive == "1") then
            if (SkillMgr.Gather() ) then
				ml_task_hub:CurrentTask().failedTimer = os.time() -- just to make sure it doesnt cast skills and somehow while moving away from the node blacklits it..dont know if that is needed
                return
            end
        end
        -- first check to see if we have a gathermanager marker
        if (gGMactive == "1") then
            if (ml_task_hub:CurrentTask().currentMarker ~= nil) then
                local markerData = GatherMgr.GetMarkerData(ml_task_hub:CurrentTask().currentMarker)
                if (markerData ~= nil and markerData ~= 0) then
                    -- do 2 loops to allow prioritization of first item
                    for i, item in pairs(list) do
                        if item.name == markerData[1] then
                            Player:Gather(item.index)
                            ml_task_hub:CurrentTask().gatherTimer = os.time()
                            return
                        end
                    end
                    
                    for i, item in pairs(list) do
                        if item.name == markerData[2] then
                            Player:Gather(item.index)
                            ml_task_hub:CurrentTask().gatherTimer = os.time()
                            return
                        end
                    end
                end
            end
        end
        
        -- otherwise just grab a random item 
        for i, item in pairs(list) do
            if item.chance > 50 then
                Player:Gather(item.index)
                ml_task_hub:CurrentTask().gatherTimer = os.time()
                return
            end
        end
    else
        local node = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
        if ( node ) then
            local target = Player:GetTarget()
            if ( (target ~=nil and target.id ~= node.id) or target == nil or target == {} ) then
                Player:SetTarget(node.id)
            else
                Player:Interact(node.id)
                -- start fail timer
                if (ml_task_hub:CurrentTask().failedTimer == 0) then
                    ml_task_hub:CurrentTask().failedTimer = os.time()
                elseif (os.difftime(os.time(), ml_task_hub:CurrentTask().failedTimer) > 12) then
					ml_blacklist.AddBlacklistEntry(ffxiv_task_gather.name, node.id, os.time() + 1800)
					ml_task_hub:CurrentTask().gatherid = 0
					ml_task_hub:CurrentTask().failedTimer = 0
				end
            end

            if (gGatherTP == "1") then
                Player:MoveToStraight(Player.pos.x+2, Player.pos.y, Player.pos.z+2)
            end
        else
            wt_error(" EntityList:Get(ml_task_hub:CurrentTask().gatherid) returned no node!")
        end
    end
end

c_atnode = inheritsFrom( ml_cause )
e_atnode = inheritsFrom( ml_effect )
function c_atnode:evaluate()
    if (ml_task_hub:CurrentTask().name == "MOVETOPOS" and ml_task_hub:ThisTask().subtask == ml_task_hub:CurrentTask() and Player.ismounted) then
        if ( ml_task_hub:ThisTask().gatherid ~= nil and ml_task_hub:ThisTask().gatherid ~= 0 ) then
            local gatherable = EntityList:Get(ml_task_hub:ThisTask().gatherid)
            if (ValidTable(gatherable)) then
                return gatherable.distance2d < 4
            end
        end
    end
    return false
end
function e_atnode:execute()
    -- call the complete logic so that bot will dismount
    ml_task_hub:CurrentTask():task_complete_execute()
    ml_task_hub:CurrentTask():Terminate()
end

c_gatherwindow = inheritsFrom( ml_cause )
e_gatherwindow = inheritsFrom( ml_effect )
function c_gatherwindow:evaluate()
	local list = Player:GetGatherableSlotList()
    if (list ~= nil and ml_task_hub.CurrentTask().name == "MOVETOPOS") then
		return true
	end
end
function e_gatherwindow:execute()
	ml_debug("Bad! We fell into the gathering/moveto timing bug...terminating MoveTo task")
	-- Complete the moveto task so that we can go back to gathering window
	ml_task_hub.CurrentTask():task_complete_execute()
end

function ffxiv_task_gather:Init()
    --init ProcessOverWatch cnes
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 20 )
    self:add( ke_dead, self.overwatch_elements)
    
    local ke_stealth = ml_element:create( "Stealth", c_stealth, e_stealth, 15 )
    self:add( ke_stealth, self.overwatch_elements)
	
	local ke_gatherWindow = ml_element:create( "GatherWindow", c_gatherwindow, e_gatherwindow, 20)
	self:add( ke_gatherWindow, self.overwatch_elements)
    
    --local ke_atNode = ml_element:create( "AtNode", c_atnode, e_atnode, 10 )
    --self:add( ke_atNode, self.overwatch_elements)
    
    --init Process cnes
    --in descending priority order just for you stefan
    local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 25 )
    self:add( ke_returnToMarker, self.process_elements)
    
    local ke_nextMarker = ml_element:create( "NextMarker", c_nextmarker, e_nextmarker, 20 )
    self:add( ke_nextMarker, self.process_elements)
    
    local ke_findGatherable = ml_element:create( "FindGatherable", c_findgatherable, e_findgatherable, 15 )
    self:add(ke_findGatherable, self.process_elements)
    
    local ke_moveToGatherable = ml_element:create( "MoveToGatherable", c_movetogatherable, e_movetogatherable, 10 )
    self:add( ke_moveToGatherable, self.process_elements)
    
    local ke_gather = ml_element:create( "Gather", c_gather, e_gather, 5 )
    self:add(ke_gather, self.process_elements)
    
    self:AddTaskCheckCEs()
    
    -- create node blacklist
    ml_blacklist.CreateBlacklist(self.name)
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
                k == "gChangeJobs" or
                k == "gGatherPS" or
                k == "gGatherTP" or
                k == "gIgnoreGatherLvl" ) then
            Settings.FFXIVMINION[tostring(k)] = v
        end
		if ( k == "gRandomMarker" ) then
			-- always enable ignorelevel with randomMarkers to prevent fuckups
			if ( v == "1") then
				gIgnoreGrindLvl = "1"
			end
			Settings.FFXIVMINION[tostring(k)] = v
		end
    end
    GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

-- UI settings etc
function ffxiv_task_gather.UIInit()
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].useStealth, "gDoStealth",strings[gCurrentLanguage].gatherMode)
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].randomizeMarkers, "gRandomMarker",strings[gCurrentLanguage].gatherMode)
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].ignoreMarkerLevels, "gIgnoreGatherLvl",strings[gCurrentLanguage].gatherMode)
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].teleport, "gGatherTP",strings[gCurrentLanguage].gatherMode)
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].permaSprint, "gGatherPS",strings[gCurrentLanguage].gatherMode)
    
    GUI_SizeWindow(ml_global_information.MainWindow.Name,250,400)
    
    if (Settings.FFXIVMINION.gDoStealth == nil) then
        Settings.FFXIVMINION.gDoStealth = "0"
    end
    
    if (Settings.FFXIVMINION.gRandomMarker == nil) then
        Settings.FFXIVMINION.gRandomMarker = "0"
    end
    
    if (Settings.FFXIVMINION.gChangeJobs == nil) then
        Settings.FFXIVMINION.gChangeJobs = "0"
    end
    
    if (Settings.FFXIVMINION.gGatherTP == nil) then
        Settings.FFXIVMINION.gGatherTP = "0"
    end
    
    if (Settings.FFXIVMINION.gGatherPS == nil) then
        Settings.FFXIVMINION.gGatherPS = "0"
    end
    
    if (Settings.FFXIVMINION.gIgnoreGatherLvl == nil) then
        Settings.FFXIVMINION.gIgnoreGatherLvl = "1"
    end
    
    gDoStealth = Settings.FFXIVMINION.gDoStealth
    gRandomMarker = Settings.FFXIVMINION.gRandomMarker
    gChangeJobs = Settings.FFXIVMINION.gChangeJobs
    gGatherTP = Settings.FFXIVMINION.gGatherTP
    gGatherPS = Settings.FFXIVMINION.gGatherPS
    gIgnoreGatherLvl = Settings.FFXIVMINION.gIgnoreGatherLvl
    if(gGatherPS == "1") then
        GameHacks:SetPermaSprint(true)
    end
    
    RegisterEventHandler("GUI.Update",ffxiv_task_gather.GUIVarUpdate)
end
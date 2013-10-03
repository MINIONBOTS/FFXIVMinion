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
	newinst.markerTimer = false
	newinst.currentMarker = 0
	newinst.prevMarker = 0
	newinst.isGathering = false
	
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
	ml_task_hub:CurrentTask().isGathering = false
	local gatherable = GetNearestGatherable()
	if (gatherable ~= nil) then
		Player:SetTarget(gatherable.id)
		ml_task_hub.CurrentTask().gatherid = gatherable.id
	else
		if (ml_task_hub:CurrentTask().currentMarker ~= nil and ml_task_hub:CurrentTask().currentMarker ~= 0) then
			local markerInfo = mm.GetMarkerInfo(ml_task_hub:CurrentTask().currentMarker)
			if (markerInfo ~= nil and markerInfo ~= {}) then
				Player:MoveTo(markerInfo.x, markerInfo.y, markerInfo.z, 10)
			end
		end
	end
end

c_movetogatherable = inheritsFrom( ml_cause )
e_movetogatherable = inheritsFrom( ml_effect )
function c_movetogatherable:evaluate()
	if ( ml_task_hub:CurrentTask().gatherid ~= nil and ml_task_hub:CurrentTask().gatherid ~= 0 ) then
		local gatherable = EntityList:Get(ml_task_hub.CurrentTask().gatherid)
		if (gatherable ~= nil and gatherable.distance > 3) then
			return true
		end
	end
	
	return false
end
function e_movetogatherable:execute()
	local pos = EntityList:Get(ml_task_hub.CurrentTask().gatherid).pos
	if (pos ~= nil and pos ~= {}) then
		if (gGatherTP == "1") then
			GameHacks:TeleportToXYZ(pos.x,pos.y,pos.z)
		else
			local newTask = ffxiv_task_movetopos:Create()
			newTask.pos = pos
			newTask.range = 1.5
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	end
end

c_nextmarker = inheritsFrom( ml_cause )
e_nextmarker = inheritsFrom( ml_effect )
function c_nextmarker:evaluate()
	if ( gGMactive == "1" and ml_task_hub:CurrentTask().markerTimer ~= 0 and not ml_task_hub:CurrentTask().isGathering) then
		if ( ml_task_hub:CurrentTask().markerTimer == false or os.time() > ml_task_hub:CurrentTask().markerTimer) then
			-- get the next marker
			local marker = GatherMgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker, ml_task_hub:CurrentTask().prevMarker)
			if marker ~= nil then
				if marker ~= currentMarker then
                    e_nextmarker.marker = marker
					return true
				end
			end
		end
	end
	
	return false
end
function e_nextmarker:execute()
    ml_task_hub:CurrentTask().prevMarker = ml_task_hub:CurrentTask().currentMarker
    ml_task_hub:CurrentTask().currentMarker = e_nextmarker.marker
    local timer = GatherMgr.GetMarkerTime(e_nextmarker.marker)
    if (timer ~= 0) then
        timer = timer + os.time()
    end
    ml_task_hub:CurrentTask().markerTimer = timer

	local markerInfo = mm.GetMarkerInfo(ml_task_hub:CurrentTask().currentMarker)
	
	if (gChangeJobs) then
		local markerType = mm.GetMarkerType(marker)
		if (markerType == "miningSpot" and Player.job == FFXIV.JOBS.BOTANIST) then
			--change job
		elseif (markerType == "botanySpot" and Player.job == FFXIV.JOBS.MINER) then
			--change job
		end
	end
	
	local newTask = ffxiv_task_movetopos:Create()
	newTask.pos = {x = markerInfo.x, y = markerInfo.y, z = markerInfo.z}
	newTask.range = 3
	ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_ASAP)
end

c_gather = inheritsFrom( ml_cause )
e_gather = inheritsFrom( ml_effect )
function c_gather:evaluate()
	local node = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
	if (node ~= nil and node.distance < 3) then
        return true
    end
	
	return false
end
function e_gather:execute()
    local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
        ml_task_hub:CurrentTask().isGathering = true
		-- first check to see if we have a gathermanager marker
		if (gGMactive == "1") then
			if (ml_task_hub:CurrentTask().currentMarker ~= nil) then
				local markerData = GatherMgr.GetMarkerData(ml_task_hub:CurrentTask().currentMarker)
				for i, item in pairs(list) do
					if item.name == markerData[1] or item.name == markerData[2] then
						Player:Gather(item.index)
						return
					end
				end
			end
		end
		
		-- otherwise just grab a random item 
		for i, item in pairs(list) do
			if item.chance > 50 then
				Player:Gather(item.index)
                return
			end
		end
    else
        local node = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
        Player:Interact(node.id)
        
        -- little hack here to resync if we teleported...hopefully remove it later
        --if (gGatherTP == "1") then
		--	local Skill = 
        --   ActionList:Cast(JUMP)
        --end
    end
end

---------------------------------------------------------------------------------------------
--STEALTH: If (distance to aggro < 18) Then (cast stealth)
--Uses stealth when gathering to avoid aggro
---------------------------------------------------------------------------------------------
c_stealth = inheritsFrom( ml_cause )
e_stealth = inheritsFrom( ml_effect )
function c_stealth:evaluate()
	if (gDoStealth == "0") then
		return false
	end

	if (ActionList:CanCast(212,0)) then
		local mobList = EntityList("attackable,onmesh,maxdistance=17")
		if(TableSize(mobList) > 0 and not HasBuff(Player.id, 47)) or
          (TableSize(mobList) == 0 and HasBuff(Player.id, 47)) 
        then
            return true
        end
	end
	
	return false
end
function e_stealth:execute()
	ActionList:Cast(212,0)
end

function ffxiv_task_gather:Init()
	--init ProcessOverWatch cnes
	local ke_stealth = ml_element:create( "Stealth", c_stealth, e_stealth, 15 )
	self:add( ke_stealth, self.overwatch_elements)
	
	local ke_nextMarker = ml_element:create( "NextMarker", c_nextmarker, e_nextmarker, 10 )
	self:add( ke_nextMarker, self.overwatch_elements)
	
	--init Process cnes
	
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
			d("test")
			if (v == "1") then
				GameHacks:SetPermaSprint(true)
			else
				GameHacks:SetPermaSprint(false)
			end
		end
		if ( 	k == "gDoStealth" or
				k == "gRandomMarker" or
				k == "gChangeJobs" or
				k == "gGatherPS" or
				k == "gGatherTP" ) then
				d("test2")
			Settings.FFXIVMINION[tostring(k)] = v
		end
	end
	GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

-- UI settings etc
function ffxiv_task_gather.UIInit()
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Use Stealth", "gDoStealth","Gather")
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Randomize Markers", "gRandomMarker","Gather")
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Change Jobs (Not Working)", "gChangeJobs","Gather")
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Teleport (HACK!)", "gGatherTP","Gather")
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, "PermaSprint (HACK!)", "gGatherPS","Gather")
	
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
	
	gDoStealth = Settings.FFXIVMINION.gDoFates
	gRandomMarker = Settings.FFXIVMINION.gFatesOnly
	gChangeJobs = Settings.FFXIVMINION.gChangeJobs
	gGatherTP = Settings.FFXIVMINION.gGatherTP
	gGatherPS = Settings.FFXIVMINION.gGatherPS
    if(gGatherPS == "1") then
        GameHacks:SetPermaSprint(true)
    end
	
	RegisterEventHandler("GUI.Update",ffxiv_task_gather.GUIVarUpdate)
end
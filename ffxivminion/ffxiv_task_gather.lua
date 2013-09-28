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
	local gatherable = GetNearestGatherable()
	if (gatherable ~= nil) then
		Player:SetTarget(gatherable.id)
		ml_task_hub.CurrentTask().gatherid = gatherable.id
	else
		local markerInfo = mm.GetMarkerInfo(ml_task_hub:CurrentTask().currentMarker)
		if (markerInfo ~= nil and markerInfo ~= {}) then
			Player:MoveTo(markerInfo.x, markerInfo.y, markerInfo.z, 10)
		end
	end
end

c_movetogatherable = inheritsFrom( ml_cause )
e_movetogatherable = inheritsFrom( ml_effect )
function c_movetogatherable:evaluate()
	if ( ml_task_hub:CurrentTask().gatherid ~= nil and ml_task_hub:CurrentTask().gatherid ~= 0 ) then
		local gatherable = EntityList:Get(ml_task_hub.CurrentTask().gatherid)
		if (gatherable ~= nil and gatherable.distance > 2.5) then
			return true
		end
	end
	
	return false
end
function e_movetogatherable:execute()
	local pos = EntityList:Get(ml_task_hub.CurrentTask().gatherid).pos
	if (pos ~= nil and pos ~= {}) then
		local newTask = ffxiv_task_movetopos:Create()
		newTask.pos = pos
		newTask.range = 2.5
		ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_ASAP)
	end
end

c_nextmarker = inheritsFrom( ml_cause )
e_nextmarker = inheritsFrom( ml_effect )
function c_nextmarker:evaluate()
	if ( gGMactive == "1" and ml_task_hub:CurrentTask().markerTimer ~= 0) then
		if ( ml_task_hub:CurrentTask().markerTimer == false or os.time() > ml_task_hub:CurrentTask().markerTimer) then
			-- get the next marker
			local marker = GatherMgr.GetNextMarker(ml_task_hub:CurrentTask().currentMarker, ml_task_hub:CurrentTask().prevMarker)
			if marker ~= nil then
				if marker ~= currentMarker then
					ml_task_hub:CurrentTask().prevMarker = ml_task_hub:CurrentTask().currentMarker
					ml_task_hub:CurrentTask().currentMarker = marker
					local timer = GatherMgr.GetMarkerTime(marker)
					if (timer ~= 0) then
						timer = timer + os.time()
					end
					ml_task_hub:CurrentTask().markerTimer = timer
					
					return true
				end
			end
		end
	end
	
	return false
end
function e_nextmarker:execute()
	local marker = ml_task_hub:CurrentTask().currentMarker
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
	Player:SetTarget(ml_task_hub:CurrentTask().gatherid)
	local node = Player:GetTarget()
	if (node ~= nil and node.distance < 2.5) then
		local list = Player:GetGatherableSlotList()
		if (list ~= nil) then
			e_gather.list = list
			return true
		else
			Player:Interact(node.id)
		end
	else
		Player:SetTarget(ml_task_hub.CurrentTask().targetid)
	end
	
	return false
end
function e_gather:execute()
	if (e_gather.list ~= nil and TableSize(e_gather.list) > 0) then
		-- first check to see if we have a gathermanager marker
		if (gGMactive == "1") then
			if (ml_task_hub:CurrentTask().currentMarker ~= nil) then
				local markerData = GatherMgr.GetMarkerData(ml_task_hub:CurrentTask().currentMarker)
				for i, item in pairs(e_gather.list) do
					if item.name == markerData then
						Player:Gather(item.index)
						return
					end
				end
			end
		end
		
		-- otherwise just grab a random item 
		for i, item in pairs(e_gather.list) do
			if item.chance > 50 then
				Player:Gather(item.index)
			end
		end
	end
end

---------------------------------------------------------------------------------------------
--STEALTH: If (distance to aggro < 18) Then (cast stealth)
--Uses stealth when gathering to avoid aggro
---------------------------------------------------------------------------------------------
c_stealth = inheritsFrom( ml_cause )
e_stealth = inheritsFrom( ml_effect )
function c_stealth:evaluate()
	if (not gDoStealth) then
		return false
	end
	
	local stealth = Skillbar:Get(229)
	if (stealth ~= nil) then
		local mobList = EntityList("attackable,onmesh,maxdistance=17")
		if(TableSize(mobList) > 0) then
			if (HasBuff(Player, 47)) then
				return false
			else
				return true
			end
		else
			if (HasBuff(Player, 47)) then
				stealth:Cast()
			end
		end
	end
	
	return false
end
function e_stealth:execute()
	Skillbar:Get(229):Cast()
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
		if ( 	k == "gDoStealth" or
				k == "gRandomMarker" or
				k == "gChangeJobs" ) then
			Settings.FFXIVMINION[tostring(k)] = v
		end
	end
	GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

-- UI settings etc
function ffxiv_task_gather.UIInit()
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Use Stealth", "gDoStealth","Gather")
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Randomize Markers", "gRandomMarker","Gather")
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Change Jobs", "gChangeJobs","Gather")
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
	
	gDoStealth = Settings.FFXIVMINION.gDoFates
	gRandomMarker = Settings.FFXIVMINION.gFatesOnly
	gChangeJobs = Settings.FFXIVMINION.evacPoint
	
	RegisterEventHandler("GUI.Update",ffxiv_task_grind.GUIVarUpdate)
end
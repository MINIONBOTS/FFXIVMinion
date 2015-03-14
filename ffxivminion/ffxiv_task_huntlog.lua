ffxiv_task_huntlog = inheritsFrom(ml_task)
--Translate jobs down to their class equivalent.
ffxiv_task_huntlog.jobTranslate = {
	[19] = 1,
	[20] = 2,
	[21] = 3,
	[22] = 4,
	[23] = 5,
	[24] = 6,
	[25] = 7,
	[27] = 26,
	[28] = 26,
	[30] = 29,
}

function ffxiv_task_huntlog.Create()
    local newinst = inheritsFrom(ffxiv_task_huntlog)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_huntlog members
    newinst.name = "LT_HUNTLOG"
	
	newinst.huntParams = {}
	newinst.validIndexes = {}
	newinst.possibleTargets = {}
	
	--Huntlog handles being called as a subtask via the adHoc property, which removes the task after a successful kill.
	newinst.adHoc = false
	
    return newinst
end

c_huntlogkillaggrotarget = inheritsFrom( ml_cause )
e_huntlogkillaggrotarget = inheritsFrom( ml_effect )
e_huntlogkillaggrotarget.targetid = 0
function c_huntlogkillaggrotarget:evaluate()
	if (ActionList:IsCasting()) then
		return false
	end
	
	local el = nil
	--Try onmesh first.
	el = EntityList("alive,onmesh,attackable,targetingme,maxdistance=25")
	if (ValidTable(el)) then
		local id, target = next(el)
		if (ValidTable(target)) then
			if(target.hp.current > 0 and (target.level <= (Player.level + 3)) and (target.level >= (Player.level - 10)) and
				(target.fateid == 0 or (target.fateid ~= 0 and target.level >= (Player.level - 5)))) 
			then
				e_huntlogkillaggrotarget.targetid = target.id
				return true
			end
		end
	end
			
	--For summoners/pet users
	local petid = nil
	if (Player.pet) then 
		petid = Player.pet.id 
	end
		
	if (petid) then
		el = EntityList("alive,attackable,onmesh,targeting="..tostring(petid)..",maxdistance=30")
		if (ValidTable(el)) then
			local id, target = next(el)
			if (ValidTable(target)) then
				if (target.hp.current > 0 and (target.level <= (Player.level + 3)) and (target.level >= (Player.level - 10)) and
					(target.fateid == 0 or (target.fateid ~= 0 and target.level >= (Player.level - 5)))) 
				then
					e_huntlogkillaggrotarget.targetid = target.id
					return true
				end
			end
		end
	end
    
    return false
end
function e_huntlogkillaggrotarget:execute()	
	if (Player:IsMoving()) then
		Player:Stop()
	end
	
	if (Player.ismounted) then
		Dismount()
		return
	end
	
	local newTask = ffxiv_task_grindCombat.Create()
    newTask.targetid = e_huntlogkillaggrotarget.targetid
	Player:SetTarget(e_huntlogkillaggrotarget.targetid)
	
	local c_killfail = inheritsFrom( ml_cause )
	local e_killfail = inheritsFrom( ml_effect )
	function c_killfail:evaluate()
		return Player.hp.percent < tonumber(gFleeHP) or Player.mp.percent < tonumber(gFleeMP)
	end
	function e_killfail:execute()
		ml_task_hub:CurrentTask():Terminate()
	end
    newTask:add( ml_element:create( "KillAggroFail", c_killfail, e_killfail, 100 ), newTask.overwatch_elements)
	ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
end

--This cne checks to see if a hunt log task should be created (subtask under Grind).
c_grind_addhuntlogtask = inheritsFrom( ml_cause )
e_grind_addhuntlogtask = inheritsFrom( ml_effect )
c_grind_addhuntlogtask.validIndexes = {}
c_grind_addhuntlogtask.possibleTargets = {}
function c_grind_addhuntlogtask:evaluate()
	--Reinitialize tempvars.
	c_grind_addhuntlogtask.validIndexes = {}
	c_grind_addhuntlogtask.possibleTargets = {}
	
	if (gGrindDoHuntLog == "0") then
		return false
	end

	--CNE will need to pass 2 main table checks to the task, we will only verify that there are possible indexes and targets.
	--First check that we have some valid indexes to complete.	
	c_grind_addhuntlogtask.validIndexes = ffxiv_task_huntlog.GetValidIndexes()
	if (not ValidTable(c_grind_addhuntlogtask.validIndexes)) then
		return false
	end
	
	--Second, check for targets, filtering to only this map (maybe expand into other maps later).
	c_grind_addhuntlogtask.possibleTargets = ffxiv_task_huntlog.GetTargetList(c_grind_addhuntlogtask.validIndexes)
	if (ValidTable(c_grind_addhuntlogtask.possibleTargets)) then
		return true
	end
	
	return false
end
function e_grind_addhuntlogtask:execute()
	local newTask = ffxiv_task_huntlog.Create()
	newTask.validIndexes = deepcopy(c_grind_addhuntlogtask.validIndexes,true)
	newTask.possibleTargets = deepcopy(c_grind_addhuntlogtask.possibleTargets,true)
	newTask.adHoc = true
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_selectvalidindexes = inheritsFrom( ml_cause )
e_selectvalidindexes = inheritsFrom( ml_effect )
c_selectvalidindexes.indexes = {}
function c_selectvalidindexes:evaluate()
	--Reinitialize tempvars.
	c_selectvalidindexes.indexes = {}
	
	c_selectvalidindexes.indexes = ffxiv_task_huntlog.GetValidIndexes()
	if (ValidTable(c_selectvalidindexes.indexes)) then
		if (not deepcompare(ml_task_hub:CurrentTask().validIndexes,c_selectvalidindexes.indexes,true)) then
			return true
		end
	end
	
	return false
end
function e_selectvalidindexes:execute()
	ml_task_hub:CurrentTask().validIndexes = shallowcopy(c_selectvalidindexes.indexes)
	ml_task_hub:CurrentTask().possibleTargets = {}
	ml_task_hub:CurrentTask().huntParams = {}
end

c_selectpossibletargets = inheritsFrom( ml_cause )
e_selectpossibletargets = inheritsFrom( ml_effect )
c_selectpossibletargets.targets = {}
function c_selectpossibletargets:evaluate()
	--Reinitialize tempvars.
	c_selectpossibletargets.targets = {}
	
	c_selectpossibletargets.targets = ffxiv_task_huntlog.GetTargetList(ml_task_hub:CurrentTask().validIndexes)
	if (ValidTable(c_selectpossibletargets.targets)) then
		if (not deepcompare(ml_task_hub:CurrentTask().possibleTargets,c_selectpossibletargets.targets,true)) then
			return true
		end
	end
	
	return false
end
function e_selectpossibletargets:execute()
	ml_task_hub:CurrentTask().possibleTargets = shallowcopy(c_selectpossibletargets.targets)
	ml_task_hub:CurrentTask().huntParams = {}
end

c_selectbesttarget = inheritsFrom( ml_cause )
e_selectbesttarget = inheritsFrom( ml_effect )
c_selectbesttarget.targetinfo = {}
function c_selectbesttarget:evaluate()
	--Reinitialize tempvars.
	c_selectbesttarget.targetinfo = {}
	
	local bestTarget = ffxiv_task_huntlog.GetBestTarget(ml_task_hub:CurrentTask().possibleTargets)
	if (bestTarget) then
		c_selectbesttarget.targetinfo = bestTarget
	end
	
	if (not deepcompare(ml_task_hub:CurrentTask().huntParams,c_selectbesttarget.targetinfo,true)) then
		return true
	end
	
	return false
end
function e_selectbesttarget:execute()
	ml_task_hub:CurrentTask().huntParams = shallowcopy(c_selectbesttarget.targetinfo)
end

c_huntlogmovetomap = inheritsFrom( ml_cause )
e_huntlogmovetomap = inheritsFrom( ml_effect )
e_huntlogmovetomap.mapID = 0
function c_huntlogmovetomap:evaluate()
	if (not ml_task_hub:CurrentTask().huntParams) then
		return false
	end
	
	if (not IsPositionLocked()) then
		local mapID = ml_task_hub:CurrentTask().huntParams["mapid"]
		if (mapID and mapID > 0) then
			if (Player.localmapid ~= mapID) then
				local pos = ml_nav_manager.GetNextPathPos(	Player.pos,
															Player.localmapid,
															mapID	)
				if (ValidTable(pos)) then
					e_huntlogmovetomap.mapID = mapID
					return true
				end
			end
		end
	end
	
	return false
end
function e_huntlogmovetomap:execute()
	local task = ffxiv_task_movetomap.Create()
	task.destMapID = e_huntlogmovetomap.mapID
	if (ValidTable(ml_task_hub:CurrentTask().huntParams["pos"])) then
		task.pos = ml_task_hub:CurrentTask().huntParams["pos"]
	end
	ml_task_hub:CurrentTask():AddSubTask(task)
end

c_huntlogkill = inheritsFrom( ml_cause )
e_huntlogkill = inheritsFrom( ml_effect )
e_huntlogkill.targetid = 0
function c_huntlogkill:evaluate()
	if (not ml_task_hub:CurrentTask().huntParams) then
		return false
	end
	
	local id = ml_task_hub:CurrentTask().huntParams["id"]
    if (id and id > 0) then
		local el = nil
		local pos = ml_task_hub:CurrentTask().huntParams["pos"]
		local maxlevel = ffxiv_task_huntlog.GetMaxMobLevel()
		
		el = EntityList("onmesh,alive,attackable,targetingme,contentid="..tostring(id))

		--otherwise check for mobs not incombat so we get credit for kill
		local petid = nil
		if (ValidTable(Player.pet)) then
			petid = Player.pet.id
		end
		
		if (not ValidTable(el) and petid ~= nil) then
			el = EntityList("onmesh,alive,attackable,fateid=0,contentid="..tostring(id)..",targeting="..tostring(petid))
		end
		
		if (not ValidTable(el)) then
			el = EntityList("onmesh,alive,attackable,fateid=0,contentid="..tostring(id)..",maxlevel="..tostring(maxlevel))
		end
		
		if(ValidTable(el)) then
			if (TableSize(el) == 1) then
				local id, entity = next(el)
				if(entity) then
					e_huntlogkill.targetid = id
					return true
				end
			else
				local lowestLevel = 51
				for id, entity in pairs(el) do
					if (entity.level < lowestLevel) then
						lowestLevel = entity.level
					end
				end
				
				local closestDistance = math.huge
				local closest = nil
				for id,entity in pairs(el) do
					if (entity.level <= (lowestLevel + 1)) then
						if (not closest or entity.pathdistance < closestDistance) then
							closest = entity
							closestDistance = entity.pathdistance
						end
					end
				end
				
				if (closest) then
					e_huntlogkill.targetid = closest.id
					return true
				end
			end
        end
    end
	
	return false
end
function e_huntlogkill:execute()
	local newTask = ffxiv_task_grindCombat.Create()
	newTask.targetid = e_huntlogkill.targetid
	--If this is an adhoc task, meaning, this task is not the root task, make sure to kill the task after the kill has been completed.
	if (ml_task_hub:CurrentTask().adHoc) then
		newTask.task_complete_execute = function ()
			Player:Stop()
			ml_task_hub:CurrentTask().completed = true
			ml_task_hub:CurrentTask():ParentTask().completed = true
			ml_task_hub:CurrentTask():ParentTask():SetDelay(3000)
		end
	else
		newTask.task_complete_execute = function ()
			Player:Stop()
			ml_task_hub:CurrentTask().completed = true
			ml_task_hub:CurrentTask():SetDelay(3000)
		end
	end
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_huntlogmovetopos = inheritsFrom( ml_cause )
e_huntlogmovetopos = inheritsFrom( ml_effect )
function c_huntlogmovetopos:evaluate()
	if (not IsPositionLocked()) then
		local mapID = ml_task_hub:CurrentTask().huntParams["mapid"]
		if (mapID and mapID > 0) then
			if(Player.localmapid == mapID) then
				local pos = ml_task_hub:ThisTask().huntParams["pos"]
				
				if (Distance3D(Player.pos.x, Player.pos.y, Player.pos.z, pos.x, pos.y, pos.z) > 15) then
					return true
				end
			end
		end
	end
	
	return false
end
function e_huntlogmovetopos:execute()
	local pos = ml_task_hub:CurrentTask().huntParams["pos"]
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = pos
	newTask.use3d = true
	newTask.range = 5
	if (gTeleport == "1") then
		newTask.useTeleport = true
	end
	ml_task_hub:ThisTask():AddSubTask(newTask)
end

function ffxiv_task_huntlog:Init()    
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 50 )
    self:add(ke_dead, self.overwatch_elements)
    
    local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 45 )
    self:add(ke_flee, self.overwatch_elements)
    
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 40 )
    self:add(ke_rest, self.overwatch_elements)
	
	local ke_selectValidIndexes = ml_element:create( "SelectValidIndexes", c_selectvalidindexes, e_selectvalidindexes, 45 )
    self:add(ke_selectValidIndexes, self.process_elements)
	
	local ke_selectPossibleTargets = ml_element:create( "SelectPossibleTargets", c_selectpossibletargets, e_selectpossibletargets, 40 )
    self:add(ke_selectPossibleTargets, self.process_elements)
	
	local ke_selectBestTarget = ml_element:create( "SelectBestTarget", c_selectbesttarget, e_selectbesttarget, 35 )
    self:add(ke_selectBestTarget, self.process_elements)
	
	local ke_moveToMap = ml_element:create( "MoveToMap", c_huntlogmovetomap, e_huntlogmovetomap, 30 )
    self:add(ke_moveToMap, self.process_elements)
	
	local ke_killAggro = ml_element:create( "KillAggro", c_huntlogkillaggrotarget, e_huntlogkillaggrotarget, 25 )
    self:add(ke_killAggro, self.process_elements)
	
	local ke_killEntry = ml_element:create( "KillEntry", c_huntlogkill, e_huntlogkill, 20 )
    self:add(ke_killEntry, self.process_elements)
	
	local ke_moveToPos = ml_element:create( "MoveToPos", c_huntlogmovetopos, e_huntlogmovetopos, 10 )
    self:add(ke_moveToPos, self.process_elements)
	
    self:AddTaskCheckCEs()
end

--[[
function ffxiv_task_huntlog.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gHuntMapID" )	then
            SafeSetVar(tostring(k),v)
        end
    end
    GUI_RefreshWindow(GetString("huntlogMode"))
end
--]]

function ffxiv_task_huntlog.UIInit()
	ffxivminion.Windows.HuntLog = { id = strings["us"].huntlogMode, Name = GetString("huntlogMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.HuntLog)
	
	local winName = GetString("huntlogMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	GUI_NewButton(winName, strings[gCurrentLanguage].markerManager, "ToggleMarkerMgr")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].botMode,"gBotMode",group,"None")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].skillProfile,"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,strings[gCurrentLanguage].navmesh ,"gmeshname",group,ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,strings[gCurrentLanguage].botEnabled,"gBotRunning",group)
	
	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
end

--[[
function ffxiv_task_huntlog.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" and string.find(Button,"ffxiv_hunt") ~= nil ) then
		if (Button == "ffxiv_huntAddLocation") then
			ffxiv_task_huntlog.AddHuntLocation()
		end
		if (Button == "ffxiv_huntRefreshMap") then
			ffxiv_task_huntlog.RefreshMap()
		end
		if (string.find(Button,"ffxiv_huntEditLocation") ~= nil) then
			local key = Button:gsub("ffxiv_huntEditLocation","")
			ffxiv_task_huntlog.EditHuntLocation(key)
		end
		if (Button == "ffxiv_huntSaveLocation") then
			ffxiv_task_huntlog.SaveGatherLocation()
		end
		if (Button == "ffxiv_huntRemoveLocation") then
			ffxiv_task_huntlog.RemoveGatherLocation()
		end
	end
end
--]]

function ffxiv_task_huntlog.GetTargetList(indexlist,filtermap)
	local filtermap = filtermap or false
	local list = indexlist
	if (not ValidTable(list)) then
		return nil
	end
	
	local targetList = {}
	for indexkey,indexdata in pairs(list) do
		for entrykey,entrydata in pairs(indexdata) do
			if (not ffxiv_task_huntlog.IsEntryComplete(indexkey,entrykey)) then
				if (not filtermap or (filtermap and entrydata.mapid == Player.localmapid)) then
					targetList[entrydata.id] = entrydata
				end
			end
		end
	end
	return targetList
end

function ffxiv_task_huntlog.GetValidIndexes()
	local safeIndexes = {}	
	local indexList = {}
	
	--First pass filters valid indexes by level.
	local rank = 0
	local info = ffxiv_task_huntlog.GetHuntLog()
	if (info) then
		for index,data in pairsByKeys(info) do
			if (rank == 0) then
				rank = data.currentrank
			end
			if (not data.iscompleted) then
				if (ffxiv_task_huntlog.IsIndexCompatible(data.currentrank,index)) then
					safeIndexes[index] = true
				end
			end
		end
	end
	
	if (rank == 0 or not ValidTable(safeIndexes)) then
		return nil
	end
	
	--Second pass filters indexes based on ffxiv_data_huntlog we have created.
	local class = ffxiv_task_huntlog.jobTranslate[Player.job] or Player.job
	for index,_ in pairs(safeIndexes) do
		local data = ffxiv_task_huntlog.GetIndexData(class,rank,index)
		if (data) then
			indexList[index] = data
		else
			d("Could not find valid data for class " .. class .. ", rank " .. rank .. ", index " .. index)
		end
	end
	
	return indexList
end

function ffxiv_task_huntlog.GetBestTarget(list)
	if (not ValidTable(list)) then
		return nil
	end
	
	local onMapTargets = {}
	local offMapTargets = {}
	local pmapid = Player.localmapid
	local ppos = shallowcopy(Player.pos)
	local maxlevel = ffxiv_task_huntlog.GetMaxMobLevel()
	
	for id, data in pairs(list) do
		if (data.mapid == pmapid) then
			onMapTargets[id] = data
		else
			offMapTargets[id] = data
		end
	end
	
	local targetTable = nil
	if (ValidTable(onMapTargets)) then
		targetTable = onMapTargets
		
		local entityString = ""
		for id, data in pairs(targetTable) do
			if (entityString == "") then
				entityString = tostring(id)
			else
				entityString = entityString..";"..tostring(id)
			end
		end
		
		local closestType = nil
		local nearscan = EntityList("nearest,alive,onmesh,attackable,contentid="..entityString..",maxlevel="..tostring(maxlevel))
		if (nearscan) then
			local id,target = next(nearscan)
			if (target) then
				closestType = target.uniqueid
			end
		end
		
		local closestData = targetTable[closestType]
		if (closestData) then
			d("Target ID "..tostring(closestData.id).." was found nearby, it is the best choice.")
			return closestData
		end		
	else
		targetTable = offMapTargets
	end
	
	local closest = nil
	local closestDistance = 999
	for id, data in pairs(targetTable) do
		local pos = data.pos
		local nodeDistance
		local dist = 0
		
		--d("Evaluating id:"..tostring(id))
		--d("Current map:"..tostring(Player.localmapid)..", destination map:"..tostring(data.task.params["mapid"]))
		
		if (pmapid ~= data.mapid) then
			local currNode = ml_nav_manager.GetNode(pmapid)	
			local destNode = ml_nav_manager.GetNode(data.mapid)				
			if(ValidTable(currNode) and ValidTable(destNode)) then
				local path = ml_nav_manager.GetPath(currNode, destNode)
				if (TableSize(path) >= 2) then
					local lastLeg = 0
					local firstLeg = 0
					local middleLeg = 0
					
					--First, get the last leg of the journey.
					local prevNode = path[TableSize(path) - 1]
					--d("Destination node "..tostring(destNode.id).." looking for previous node:"..tostring(prevNode.id))
					local prevNeighbor = destNode:GetNeighbor(prevNode.id)
					if (ValidTable(prevNeighbor)) then
						local closestGate = nil
						local closestDistance = 9999
						for id,data in pairs(prevNeighbor.gates) do
							local gateDist = Distance3D(pos.x,pos.y,pos.z,data.x,data.y,data.z)
							if (not closestGate or gateDist < closestDistance) then
								closestGate = data
								closestDistance = gateDist
							end
						end
						lastLeg = closestDistance
					else
						lastLeg = 3000
					end
					
					--Second, get the first leg of the journey.
					--The first leg is actually the currNode to the second node, since the first node in the path is actually the current node.
					local nextNode = path[2]
					local nextNeighbor = currNode:GetNeighbor(nextNode.id)
					local closestGate = nil
					local closestDistance = 9999
					for id,data in pairs(nextNeighbor.gates) do
						local pathdistUsed = false
						local pathdist = NavigationManager:GetPath(ppos.x,ppos.y,ppos.z,data.x,data.y,data.z)
						if ( pathdist ) then
							local pdist = PathDistance(pathdist)
							if ( pdist ~= nil ) then
								pathdistUsed = true
								if (not closestGate or pdist < closestDistance) then
									closestGate = data
									closestDistance = pdist
								end
							end
						end			
			
						if (not pathdistUsed) then
							local gateDist = Distance3D(ppos.x,ppos.y,ppos.z,data.x,data.y,data.z)
							if (not closestGate or gateDist < closestDistance) then
								closestGate = data
								closestDistance = gateDist
							end
						end
					end
					firstLeg = closestDistance
					
					--Third, get the middle leg.  For this, just guess 2000 per node, being lazy.
					local pathCount = TableSize(path)
					if (pathCount > 2) then
						middleLeg = (2000 * (pathCount - 2))
					end
					
					dist = dist + firstLeg + lastLeg + middleLeg
					if (onMap) then
						dist = dist + 1000
					end
				else
					--d("Path only contained 1 node. Current map:"..tostring(Player.localmapid)..", Destination map:"..tostring(data.mapid))
					dist = 3000
				end	
			end			
		end
		
		if (pmapid == data.mapid) then			
			local pathdist = NavigationManager:GetPath(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
			if ( pathdist ) then
				local pdist = PathDistance(pathdist)
				if ( pdist ~= nil ) then
					dist = pdist
				else
					dist = Distance3DT(pos,ppos)
				end
			else
				dist = Distance3DT(pos,ppos)
			end			
		end
		
		if (not closest or (dist < closestDistance and closest.id ~= data.id)) then
			closest = data
			closestDistance = dist
		end
	end
	
	if (ValidTable(closest)) then
		d("Target ID "..tostring(closest.id).." is the best choice.")
		return closest
	end
	
	return nil
end

function ffxiv_task_huntlog.IsIndexCompatible(rank,index)
	local rank = tonumber(rank) or 0
	local index = tonumber(index) or 0
	
	local indexLevel = ((rank - 1) * 10) + index

	if (Player.level >= 40) then
		return true
	elseif (Player.level >= 30) then
		if (indexLevel <= (Player.level + 5)) then
			return true
		end
	elseif (Player.level >= 10) then
		if (indexLevel <= (Player.level + 3)) then
			return true
		end
	else
		if (indexLevel <= (Player.level + 1)) then
			return true
		end
	end
	
	return false
end

function ffxiv_task_huntlog.GetMaxMobLevel()
	if (Player.level >= 40) then
		return 50
	elseif (Player.level >= 30) then
		return (Player.level + 5)
	elseif (Player.level >= 10) then
		return (Player.level + 3)
	else
		return (Player.level + 1)
	end
end

function ffxiv_task_huntlog.GetHuntLog()
	local class = ffxiv_task_huntlog.jobTranslate[Player.job] or Player.job
	if (class) then
		local logTable = Quest:GetHuntingLog(class)
		if (logTable) then
			return logTable
		end
	end
	return nil
end

function ffxiv_task_huntlog.IsEntryComplete(index,entry)
	local index = tonumber(index) or 0
	local entry = tonumber(entry) or 0
	
	local huntlog = ffxiv_task_huntlog.GetHuntLog()
	if (huntlog) then
		for i,data in pairsByKeys(huntlog) do
			if (i == index) then
				if (not data.iscompleted) then
					if (entry == 1) then
						if (data.entry1done) then
							return true
						else
							return false
						end
					elseif (entry == 2) then
						if (data.entry2done) then
							return true
						else
							return false
						end
					elseif (entry == 3) then
						if (data.entry3done) then
							return true
						else
							return false
						end
					elseif (entry == 4) then
						if (data.entry4done) then
							return true
						else
							return false
						end
					end
				else
					return true
				end
			end
		end
	end
	
	ml_error("IsEntryComplete resulted in 0, should never happen.")
	return 0
end

function ffxiv_task_huntlog.GetIndexData(class,rank,index)
	local class = tonumber(class) or 0
	local rank = tonumber(rank) or 0
	local index = tonumber(index) or 0

	if (class ~= 0 and rank ~= 0 and index ~= 0) then
		local data = ffxiv_data_huntlog
		if (data) then
			local classdata = data[class]
			if (classdata) then
				local rankdata = classdata[rank]
				if (rankdata) then
					local indexdata = rankdata[index]
					if (indexdata) then
						return indexdata
					end
				end
			end
		else
			d("HuntLog data is invalid.")
		end
	end
	
	return nil
end

function ffxiv_task_huntlog.GetEntryData(class,rank,index,entry)
	local class = tonumber(class) or 0
	local rank = tonumber(rank) or 0
	local index = tonumber(index) or 0
	local entry = tonumber(entry) or 0
	
	if (class ~= 0 and rank ~= 0 and index ~= 0 and entry ~= 0) then
		local data = ffxiv_data_huntlog
		if (data) then
			local classdata = data[class]
			if (classdata) then
				local rankdata = classdata[rank]
				if (rankdata) then
					local indexdata = rankdata[index]
					if (indexdata) then
						local entrydata = indexdata[entry]
						if (entrydata) then
							return entrydata
						end
					end
				end
			end
		end
	end
	
	return nil
end

function outputHuntingLog(job)
	d(Quest:GetHuntingLog(job))
end

--RegisterEventHandler("GUI.Item",ffxiv_task_huntlog.HandleButtons)
--RegisterEventHandler("GUI.Update",ffxiv_task_huntlog.GUIVarUpdate)
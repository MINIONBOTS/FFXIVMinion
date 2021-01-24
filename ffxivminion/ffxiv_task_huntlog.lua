ffxiv_task_huntlog = inheritsFrom(ml_task)
ffxiv_task_huntlog.addon_process_elements = {}
ffxiv_task_huntlog.addon_overwatch_elements = {}

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
	if (IsPlayerCasting()) then
		return false
	end
	
	local el = nil
	--Try onmesh first.
	el = EntityList("lowesthealth,alive,onmesh,attackable,aggro,maxdistance=25")
	if (table.valid(el)) then
		local id, target = next(el)
		if (table.valid(target)) then
			if((target.level <= (Player.level + 3)) and (target.level >= (Player.level - 10)) and
				(target.fateid == 0 or (target.fateid ~= 0 and target.level >= (Player.level - 5)))) 
			then
				e_huntlogkillaggrotarget.targetid = target.id
				return true
			else
				d("Max Level Check:"..tostring(target.level <= (Player.level + 3)))
				d("Min Level Check:"..tostring(target.level >= (Player.level - 10)))
				d("Fate Check:"..tostring(target.fateid == 0 or (target.fateid ~= 0 and target.level >= (Player.level - 5))))
			end
		end
	end
	
	el = EntityList("shortestpath,alive,onmesh,attackable,aggro,maxdistance=25")
	if (table.valid(el)) then
		local id, target = next(el)
		if (table.valid(target)) then
			if((target.level <= (Player.level + 3)) and (target.level >= (Player.level - 10)) and
				(target.fateid == 0 or (target.fateid ~= 0 and target.level >= (Player.level - 5)))) 
			then
				e_huntlogkillaggrotarget.targetid = target.id
				return true
			else
				d("Max Level Check:"..tostring(target.level <= (Player.level + 3)))
				d("Min Level Check:"..tostring(target.level >= (Player.level - 10)))
				d("Fate Check:"..tostring(target.fateid == 0 or (target.fateid ~= 0 and target.level >= (Player.level - 5))))
			end
		end
	end
	
	el = EntityList("nearest,alive,onmesh,attackable,aggro,maxdistance=25")
	if (table.valid(el)) then
		local id, target = next(el)
		if (table.valid(target)) then
			if((target.level <= (Player.level + 3)) and (target.level >= (Player.level - 10)) and
				(target.fateid == 0 or (target.fateid ~= 0 and target.level >= (Player.level - 5)))) 
			then
				e_huntlogkillaggrotarget.targetid = target.id
				return true
			else
				d("Max Level Check:"..tostring(target.level <= (Player.level + 3)))
				d("Min Level Check:"..tostring(target.level >= (Player.level - 10)))
				d("Fate Check:"..tostring(target.fateid == 0 or (target.fateid ~= 0 and target.level >= (Player.level - 5))))
			end
		end
	end
			
	--For summoners/pet users
	local petid = nil
	if (Player.pet) then 
		petid = Player.pet.id 
	end
		
	if (petid) then
		el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(petid)..",maxdistance=30")
		if (table.valid(el)) then
			local id, target = next(el)
			if (table.valid(target)) then
				if (target.hp.current > 0 and (target.level <= (Player.level + 3)) and (target.level >= (Player.level - 10)) and
					(target.fateid == 0 or (target.fateid ~= 0 and target.level >= (Player.level - 5)))) 
				then
					e_huntlogkillaggrotarget.targetid = target.id
					return true
				end
			end
		end
		
		el = EntityList("nearest,alive,attackable,onmesh,targeting="..tostring(petid)..",maxdistance=30")
		if (table.valid(el)) then
			local id, target = next(el)
			if (table.valid(target)) then
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
c_grind_addhuntlogtask.target = nil
function c_grind_addhuntlogtask:evaluate()
	if (not gGrindDoHuntlog) then
		return false
	end
	
	if (MIsLocked() or MIsLoading() or MIsCasting() or not HuntingLogsUnlocked()) then
		return false
	end
	
	--Reset tempvar.
	c_grind_addhuntlogtask.target = nil

	local bestTarget = AceLib.API.Huntlog.GetBestTarget()
	if (table.valid(bestTarget)) then
		local mapid = bestTarget.mapid
		if (CanAccessMap(mapid) or Player.localmapid == mapid) then
			d("Adding huntlog target: ID ["..tostring(bestTarget.id).."], @ MAPID ["..tostring(bestTarget.mapid).."].")
			c_grind_addhuntlogtask.target = bestTarget
			return true
		end
	end
	
	return false
end
function e_grind_addhuntlogtask:execute()
	ml_task_hub:CurrentTask().doingHuntlog = true

	local newTask = ffxiv_task_huntlog.Create()
	newTask.huntParams = c_grind_addhuntlogtask.target
	newTask.adHoc = true
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_quest_addhuntlogtask = inheritsFrom( ml_cause )
e_quest_addhuntlogtask = inheritsFrom( ml_effect )
c_quest_addhuntlogtask.target = nil
function c_quest_addhuntlogtask:evaluate()
	if (MIsLocked() or MIsLoading() or MIsCasting() or not HuntingLogsUnlocked() or not IsFighter(Player.job) or not gGrindDoHuntlog) then
		return false
	end
	
	--Reset tempvar.
	c_quest_addhuntlogtask.target = nil
	
	local bestTarget = AceLib.API.Huntlog.GetBestTarget()
	if (table.valid(bestTarget)) then
		local mapid = bestTarget.mapid
		if (CanAccessMap(mapid) or Player.localmapid == mapid) then
			d("Adding huntlog target: ID ["..tostring(bestTarget.id).."], @ MAPID ["..tostring(bestTarget.mapid).."].")
			c_quest_addhuntlogtask.target = bestTarget
			return true
		end
	end
	
	return false
end
function e_quest_addhuntlogtask:execute()
	local newTask = ffxiv_task_huntlog.Create()
	newTask.huntParams = c_quest_addhuntlogtask.target
	newTask.adHoc = true
	ml_task_hub:CurrentTask():AddSubTask(newTask)
	
	gCurrQuestID = ""
	gCurrQuestObjective = ""
	gCurrQuestStep = ""
	gQuestStepType = "huntlog"
	gQuestKillCount = ""
end

c_evaluatebesttarget = inheritsFrom( ml_cause )
e_evaluatebesttarget = inheritsFrom( ml_effect )
c_evaluatebesttarget.targetinfo = {}
function c_evaluatebesttarget:evaluate()
	--Reinitialize tempvars.
	c_evaluatebesttarget.targetinfo = {}
	
	local bestTarget = AceLib.API.Huntlog.GetBestTarget()
	if (table.valid(bestTarget)) then
		c_evaluatebesttarget.targetinfo = bestTarget
	end
	
	if (not deepcompare(ml_task_hub:CurrentTask().huntParams,c_evaluatebesttarget.targetinfo,true)) then
		d("[EvaluateBestTarget]: Updating target info.")
		return true
	end
	
	return false
end
function e_evaluatebesttarget:execute()
	ml_task_hub:CurrentTask().huntParams = deepcopy(c_evaluatebesttarget.targetinfo,true)
end

c_huntlogmovetomap = inheritsFrom( ml_cause )
e_huntlogmovetomap = inheritsFrom( ml_effect )
e_huntlogmovetomap.mapID = 0
function c_huntlogmovetomap:evaluate()
	if Player.incombat or (not ml_task_hub:CurrentTask().huntParams or MIsLocked() or MIsLoading()) then
		return false
	end
	
	e_huntlogmovetomap.mapID = 0
	
	local mapID = ml_task_hub:CurrentTask().huntParams["mapid"]
	if (mapID and mapID > 0) then
		if (Player.localmapid ~= mapID) then
			if (CanAccessMap(mapID)) then
				d("[HuntlogMoveToMap]: Need to move to map ID ["..tostring(mapID).."].")
				e_huntlogmovetomap.mapID = mapID
				return true
			end
		end
	end
	
	return false
end
function e_huntlogmovetomap:execute()
	local task = ffxiv_task_movetomap.Create()
	task.destMapID = e_huntlogmovetomap.mapID
	if (table.valid(ml_task_hub:CurrentTask().huntParams["pos"])) then
		task.pos = ml_task_hub:CurrentTask().huntParams["pos"]
	end
	ml_task_hub:CurrentTask():AddSubTask(task)
end

c_huntlogmovetopos = inheritsFrom( ml_cause )
e_huntlogmovetopos = inheritsFrom( ml_effect )
function c_huntlogmovetopos:evaluate()
	if (not ml_task_hub:CurrentTask().huntParams or MIsLocked() or MIsLoading()) then
		return false
	end
	
	local mapID = ml_task_hub:CurrentTask().huntParams["mapid"]
	if (mapID and mapID > 0) then
		if (Player.localmapid == mapID) then
			local ppos = Player.pos
			local pos = ml_task_hub:CurrentTask().huntParams["pos"]
			if (Distance3D(ppos.x, ppos.y, ppos.z, pos.x, pos.y, pos.z) > 15) then
				d("[HuntlogMoveToMap]: Need to move into position.")
				return true
			end
		end
	end
	
	return false
end
function e_huntlogmovetopos:execute()
	local pos = ml_task_hub:CurrentTask().huntParams["pos"]
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = pos
	newTask.range = 5
	if (gTeleportHack) then
		newTask.useTeleport = true
	end
	
	local id = ml_task_hub:CurrentTask().huntParams["id"]
	local maxlevel = AceLib.API.Huntlog.GetMaxMobLevel()
	local customSearch = "shortestpath,onmesh,alive,attackable,targeting=0,contentid="..tostring(id)..",maxlevel="..tostring(maxlevel)..",maxdistance=50"
	newTask.customSearch = customSearch
	newTask.customSearchCompletes = true
	
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_huntlogkill = inheritsFrom( ml_cause )
e_huntlogkill = inheritsFrom( ml_effect )
e_huntlogkill.targetid = 0
function c_huntlogkill:evaluate()
	if (not table.valid(ml_task_hub:CurrentTask().huntParams) or MIsLoading() or MIsCasting() or CannotMove()) then
		return false
	end
	
	local id = ml_task_hub:CurrentTask().huntParams["id"]
    if (id and id > 0) then
		local el = nil
		local pos = ml_task_hub:CurrentTask().huntParams["pos"]
		local maxlevel = AceLib.API.Huntlog.GetMaxMobLevel()
		
		el = EntityList("onmesh,alive,attackable,targetingme,contentid="..tostring(id))

		--otherwise check for mobs not incombat so we get credit for kill
		local petid = nil
		if (table.valid(Player.pet)) then
			petid = Player.pet.id
		end
		
		if (not table.valid(el) and petid ~= nil) then
			el = EntityList("onmesh,alive,attackable,fateid=0,contentid="..tostring(id)..",targeting="..tostring(petid))
		end
		
		if (not table.valid(el)) then
			el = EntityList("onmesh,alive,attackable,targeting=0,fateid=0,contentid="..tostring(id)..",maxlevel="..tostring(maxlevel))
		end
		
		if (not table.valid(el)) then
			el = EntityList("onmesh,alive,attackable,targeting=0,contentid="..tostring(id)..",maxlevel="..tostring(maxlevel))
		end
		
		if(table.valid(el)) then
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
	d("[HuntlogKill]:Creating kill task for :"..tostring(e_huntlogkill.targetid))
	newTask.attemptPull = true
	
	local ke_clearAggressives = ml_element:create( "ClearAggressiveTargets", c_questclearaggressive, e_questclearaggressive, 3 )
	newTask:add( ke_clearAggressives, newTask.process_elements)
		
	--If this is an adhoc task, meaning, this task is not the root task, make sure to kill the task after the kill has been completed.
	if (ml_task_hub:CurrentTask().adHoc) then
		newTask.task_complete_execute = function ()
			Player:Stop()
			ml_task_hub:CurrentTask().completed = true
			ml_task_hub:CurrentTask():ParentTask().completed = true
			ml_task_hub:CurrentTask():ParentTask():SetDelay(2000)
		end
	else
		newTask.task_complete_execute = function ()
			Player:Stop()
			ml_task_hub:CurrentTask().completed = true
			ml_global_information.Await(2000)
		end
	end
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

function ffxiv_task_huntlog:Init()
	local ke_isLoading = ml_element:create( "GrindIsLoading", c_grindisloading, e_grindisloading, 250 )
    self:add( ke_isLoading, self.overwatch_elements)
	
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 220 )
    self:add(ke_dead, self.overwatch_elements)
    
    local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 210 )
    self:add(ke_flee, self.overwatch_elements)
    
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 200 )
    self:add(ke_rest, self.overwatch_elements)
	
	local ke_isLocked = ml_element:create( "IsLocked", c_grindislocked, e_grindislocked, 180 )
    self:add( ke_isLocked, self.process_elements)

	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 150 )
    self:add( ke_inventoryFull, self.process_elements)
	
	local ke_recommendEquip = ml_element:create( "RecommendEquip", c_recommendequip, e_recommendequip, 130 )
    self:add( ke_recommendEquip, self.process_elements)
	
	local ke_repair = ml_element:create( "Repair", cf_needsrepair, ef_needsrepair, 125 )
    self:add( ke_repair, self.process_elements)
	
	local ke_eat = ml_element:create( "Eat", c_eat, e_eat, 120 )
    self:add( ke_eat, self.process_elements)
	
	local ke_evalBestTarget = ml_element:create( "EvalBestTarget", c_evaluatebesttarget, e_evaluatebesttarget, 35 )
    self:add(ke_evalBestTarget, self.process_elements)
	
	local ke_moveToMap = ml_element:create( "MoveToMap", c_huntlogmovetomap, e_huntlogmovetomap, 30 )
    self:add(ke_moveToMap, self.process_elements)
	
	local ke_killAggro = ml_element:create( "KillAggro", c_huntlogkillaggrotarget, e_huntlogkillaggrotarget, 25 )
    self:add(ke_killAggro, self.process_elements)
	
	local ke_killEntry = ml_element:create( "KillEntry", c_huntlogkill, e_huntlogkill, 20 )
    self:add(ke_killEntry, self.process_elements)
	
	local ke_moveToPos = ml_element:create( "MoveToPos", c_huntlogmovetopos, e_huntlogmovetopos, 10 )
    self:add(ke_moveToPos, self.process_elements)
	
	self:InitExtras()
    self:AddTaskCheckCEs()
end

function ffxiv_task_huntlog:InitExtras()
	local overwatch_elements = self.addon_overwatch_elements
	if (table.valid(overwatch_elements)) then
		for i,element in pairs(overwatch_elements) do
			self:add(element, self.overwatch_elements)
		end
	end
	
	local process_elements = self.addon_process_elements
	if (table.valid(process_elements)) then
		for i,element in pairs(process_elements) do
			self:add(element, self.process_elements)
		end
	end
end

function ffxiv_task_huntlog.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gDoGCHuntLog" )	then
            SafeSetVar(tostring(k),v)
        end
    end
    GUI_RefreshWindow(GetString("huntlogMode"))
end
function ffxiv_task_huntlog.UIInit()
	--[[
	ffxivminion.Windows.HuntLog = { id = strings["en"].huntlogMode, Name = GetString("huntlogMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.HuntLog)
	
	local winName = GetString("huntlogMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	GUI_NewButton(winName, GetString("markerManager"), "ToggleMarkerMgr")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSkillProfile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,GetString("navmesh") ,"FFXIV_Common_NavMesh",group,ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,GetString("botEnabled"),"FFXIV_Common_BotRunning",group)
	
	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	--]]
end
function ffxiv_task_huntlog:task_complete_eval()	
	if (self.adHoc) then
		local bestTarget = AceLib.API.Huntlog.GetBestTarget()
		if (not table.valid(bestTarget)) then
			d("no best target, task complete")
			return true
		else
			if (not deepcompare(bestTarget,self.huntParams,true)) then
				d("best target did not equal huntparams")
				d("-----------------------")
				table.print(bestTarget)
				d("-----------------------")
				table.print(self.huntParams)
				return true
			end
		end
    end
    
    return false
end
function ffxiv_task_huntlog:task_complete_execute()
    self.completed = true
	
	if (self.adHoc) then
		if (ml_task_hub:CurrentTask():ParentTask() and ml_task_hub:CurrentTask():ParentTask().name == "LT_GRIND") then
			ml_task_hub:CurrentTask():ParentTask().doingHuntlog = true
		end
	end
end

RegisterEventHandler("GUI.Update",ffxiv_task_huntlog.GUIVarUpdate,"ffxiv_task_huntlog.GUIVarUpdate")
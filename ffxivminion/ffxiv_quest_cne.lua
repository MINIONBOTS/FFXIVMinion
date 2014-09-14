--IMPORTANT
--see e_questinteract:execute for specifics of how to use the interact cne
--for new tasks. you must add an exclusion for any tasks with a higher priority
--"completion cne" that use the standard quest_step_eval:evaluate() function.
--otherwise the task will complete as soon as the interact completes without 
--waiting for the higher priority cne to run

c_questcanstart = inheritsFrom( ml_cause )
e_questcanstart = inheritsFrom( ml_effect )
function c_questcanstart:evaluate()
	if (TimeSince(ml_task_hub:CurrentTask().startTimer) > 1000) then
		return not ml_task_hub:CurrentTask().quest:isStarted()
	else
		return false
	end
end
function e_questcanstart:execute()
	local task = ml_task_hub:CurrentTask().quest:GetStartTask()
	if (ValidTable(task)) then
		ml_task_hub:CurrentTask():AddSubTask(task)
		ml_task_hub:CurrentTask().currentStepCompleted = false
		ml_task_hub:CurrentTask().currentStepIndex = 1
		gCurrQuestStep = tostring(ml_task_hub:CurrentTask().currentStepIndex)
		gQuestStepType = task.params["type"]
		Settings.FFXIVMINION.gCurrQuestStep = tonumber(gCurrQuestStep)
		ffxiv_task_quest.currentStepParams = task.params
		ffxiv_task_quest.lastStepStartTime = ml_global_information.Now
	end
end

--we want iscomplete to try to compensate for other quest bugs by firing when the client data
--shows that the quest is complete, but we don't want to break other non-quest steps that have
--been added after the final quest objective
c_questiscomplete = inheritsFrom( ml_cause )
e_questiscomplete = inheritsFrom( ml_effect )
function c_questiscomplete:evaluate()
	return 	ffxiv_task_quest.currentQuest:isComplete()
end
function e_questiscomplete:execute()
	local task = ffxiv_task_quest.currentQuest:GetCompleteTask()
	if (ValidTable(task)) then
		ml_task_hub:CurrentTask():AddSubTask(task)
		
		ffxiv_task_quest.currentStepParams = task.params
		gCurrQuestStep = tostring(ml_task_hub:ThisTask().currentStepIndex)
		gCurrQuestObjective = tostring(ffxiv_task_quest.currentQuest:currentObjectiveIndex())
		gQuestStepType = task.params["type"]
		Settings.FFXIVMINION.gCurrQuestStep = tonumber(gCurrQuestStep)
		ffxiv_task_quest.SetQuestFlags()
	end
end

--nextqueststep finds the appropriate step when a quest is restarted and iterates through the steps
--when the quest engine is running
c_nextqueststep = inheritsFrom( ml_cause )
e_nextqueststep = inheritsFrom( ml_effect )
function c_nextqueststep:evaluate()
	if (not ml_task_hub:CurrentTask().quest:isStarted())
	then
		return false
	end
	
	return ml_task_hub:CurrentTask().currentStepCompleted or (ffxiv_task_quest.restartStep and ffxiv_task_quest.restartStep ~= 0)
end
function e_nextqueststep:execute()
	local quest = ffxiv_task_quest.currentQuest
	--local objectiveStepIndex = quest:GetStepIndexForObjective(quest:currentObjectiveIndex())
	local currentStepIndex = tonumber(Settings.FFXIVMINION.gCurrQuestStep) or 1
	
	if ((ml_task_hub:CurrentTask().currentStepIndex == 1 and currentStepIndex > 1) or 
		ffxiv_task_quest.restartStep ~= 0) 
	then
		ml_task_hub:CurrentTask().currentStepIndex = currentStepIndex
		ffxiv_task_quest.restartStep = 0
		ffxiv_task_quest.lastStepStartTime = ml_global_information.Now
	else
		ml_task_hub:CurrentTask().currentStepIndex = ml_task_hub:CurrentTask().currentStepIndex + 1
	end
	
	local task = ml_task_hub:CurrentTask().quest:GetStepTask(ml_task_hub:CurrentTask().currentStepIndex)
	if (ValidTable(task)) then
		--update quest step state
		ml_task_hub:ThisTask().currentStepCompleted = false
		
		if(task.params["type"] == "complete") then
			--don't let nextqueststep queue a complete task, let the complete cne handle it
			return
		end
		-- initialize task vars for some step types here
		-- this could really be handled more elegantly than a giant ifelse but
		-- that will have to come later
		if(task.params["type"] == "kill") then
			if(Settings.FFXIVMINION.questKillCount ~= nil) then
				if(Settings.FFXIVMINION.questKillCount) then
					task.killCount = Settings.FFXIVMINION.questKillCount
				else
					task.killCount = 0
				end
				
				gQuestKillCount = tostring(task.killCount)
			end
		elseif(task.params["type"] == "vendor") then
			local itemtable = tonumber(task.params["itemid"])
			if(ValidTable(itemtable)) then
				local itemid = itemtable[Player.job] or itemtable[-1]
				if(itemid) then
					local item = Inventory:Get(itemid)
					if(ValidTable(item)) then
						task.startingCount = item.count
					end
				end
			end
		elseif(task.params["type"] == "useitem") then
			local itemid = tonumber(task.params["itemid"])
			if(itemid) then
				local item = Inventory:Get(itemid)
				if(ValidTable(item)) then
					task.startingCount = item.count
				end
			end
		end
		
		if(task.params["restartatstep"]) then
			ffxiv_task_quest.restartStep = task.params["restartatstep"]
		else
			ffxiv_task_quest.restartStep = 0
		end
		
		if(task.params["disableavoid"]) then
			gAvoidAOE = "0"
		end
			
		ml_task_hub:CurrentTask():AddSubTask(task)
		
		ffxiv_task_quest.currentStepParams = task.params
		gCurrQuestStep = tostring(ml_task_hub:ThisTask().currentStepIndex)
		gCurrQuestObjective = tostring(ffxiv_task_quest.currentQuest:currentObjectiveIndex())
		gQuestStepType = task.params["type"]
		Settings.FFXIVMINION.gCurrQuestStep = tonumber(gCurrQuestStep)
		ffxiv_task_quest.SetQuestFlags()	
		ffxiv_task_quest.lastStepStartTime = ml_global_information.Now
	end
end

c_questmovetomap = inheritsFrom( ml_cause )
e_questmovetomap = inheritsFrom( ml_effect )
function c_questmovetomap:evaluate()
	local mapID = ml_task_hub:CurrentTask().params["mapid"]
    if (mapID and mapID > 0) then
        if(Player.localmapid ~= mapID) then
			local pos = ml_nav_manager.GetNextPathPos(	Player.pos,
														Player.localmapid,
														mapID	)
			if(ValidTable(pos)) then
				e_questmovetomap.mapID = mapID
				return true
			else
				--ml_debug("No path found from map "..tostring(Player.localmapid).." to map "..tostring(mapID))
			end
        end
    end
	
	return false
end
function e_questmovetomap:execute()
	local task = ffxiv_task_movetomap.Create()
	task.destMapID = e_questmovetomap.mapID
	ml_task_hub:CurrentTask():AddSubTask(task)
end

c_questmovetopos = inheritsFrom( ml_cause )
e_questmovetopos = inheritsFrom( ml_effect )
function c_questmovetopos:evaluate()
	local mapID = ml_task_hub:CurrentTask().params["mapid"]
    if (mapID and mapID > 0) then
        if(Player.localmapid == mapID) then
			local pos = ml_task_hub:CurrentTask().params["pos"]
			local threshold = 2
			if(ml_task_hub:CurrentTask().params["type"] == "nav")then
				threshold = 0.5
			end
			--return Distance2D(Player.pos.x, Player.pos.z, pos.x, pos.z) > 2
			return Distance3D(Player.pos.x, Player.pos.y, Player.pos.z, pos.x, pos.y, pos.z) > threshold
        end
    end
	
	return false
end
function e_questmovetopos:execute()
	local pos = ml_task_hub:CurrentTask().params["pos"]
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = pos
	newTask.use3d = true
	newTask.postDelay = 1500
	if(ml_task_hub:CurrentTask().params["type"] == "nav")then
		newTask.range = 0.5
	end
	
	if (gTeleport == "1") then
		newTask.useTeleport = true
		--have to add a general delay before teleporting because it breaks lots of quest logic 
		--if the bot teleports before the server updates the client with updated quest data
		--have to do a distance check here that matches the same distance check in the teleport cne
		--because we don't want to do a delay unless the bot will teleport
		
		--local myPos = Player.pos
		--local gotoPos = newTask.pos
		--local distance = Distance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
        
        --if (distance > 20) then
        --    newTask:SetDelay(2000)
        --end
		
	end
	
	--add kill aggro target check
	local ke_killAggroTarget = ml_element:create( "KillAggroTarget", c_questkillaggrotarget, e_questkillaggrotarget, 20 )
	if(	ml_task_hub:CurrentTask().params["killaggro"] or 
		ml_task_hub:CurrentTask().params["type"] == "interact") 
	then
		newTask:add( ke_killAggroTarget, newTask.overwatch_elements)
	end
	
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_questaccept = inheritsFrom( ml_cause )
e_questaccept = inheritsFrom( ml_effect )
function c_questaccept:evaluate()	
	--local id = ffxiv_task_quest.currentQuest.id
	local id = ml_task_hub:CurrentTask().params["questid"] or ffxiv_task_quest.currentQuest.id
    if (id and id > 0) then
		return Quest:IsQuestAcceptDialogOpen(id)
    end
	
	return false
end
function e_questaccept:execute()
	Quest:AcceptQuest()
	--backup check here to clear Kill Count if its already set from previous bad run
	if(ml_task_hub:CurrentTask().params["type"] and ml_task_hub:CurrentTask().params["type"] == "kill")then
		ffxiv_task_quest.killCount = 0
		ffxiv_task_quest.backupKillCount = 0
		ffxiv_task_quest.killTaskCompleted = false
		
		Settings.FFXIVMINION.questKillCount = ffxiv_task_quest.killCount
		gQuestKillCount = ffxiv_task_quest.killCount
	end
	
	ml_task_hub:CurrentTask():ParentTask().startTimer = ml_global_information.Now
	ml_task_hub:CurrentTask().stepCompleted = true
end

c_questcomplete = inheritsFrom( ml_cause )
e_questcomplete = inheritsFrom( ml_effect )
function c_questcomplete:evaluate()
	return Quest:IsQuestRewardDialogOpen()
end
function e_questcomplete:execute()
	if(not ml_task_hub:CurrentTask().delayComplete) then
		ml_task_hub:CurrentTask():SetDelay(2000)
		ml_task_hub:CurrentTask().delayComplete = true
		return
	end
	
	if(ml_task_hub:CurrentTask().params["equip"]) then
		ffxiv_task_quest.lastArmoryIDs = GetArmoryIDsTable()
	end
	
	if(ml_task_hub:CurrentTask().params["itemreward"]) then
		local reward = ml_task_hub:CurrentTask().params["itemrewardslot"]
		local rewardslot
		if(type(reward) == "table") then
			rewardslot = reward[Player.job] or reward[-1]
		else
			rewardslot = tonumber(reward)
		end
		--d("Selecting reward from slot "..tostring(rewardslot))
		Quest:CompleteQuestReward(rewardslot)
	else
		Quest:CompleteQuestReward()
	end
	
	if(ml_task_hub:CurrentTask().params["equip"]) then
		--delay the task a bit so that the inventory will update
		ml_task_hub:CurrentTask():SetDelay(1500)
	end
	
	ml_task_hub:CurrentTask().stepCompleted = true
	ml_task_hub:CurrentTask():ParentTask().questCompleted = true
end

c_questinteract = inheritsFrom( ml_cause )
e_questinteract = inheritsFrom( ml_effect )
function c_questinteract:evaluate()
	local id = ml_task_hub:ThisTask().params["id"]
    if (id and id > 0) then
		local el = EntityList("shortestpath,contentid="..tostring(id))
		if(ValidTable(el)) then
			local id, entity = next(el)
			if(entity) then
				if 	(entity.type == 5 and entity.distance2d < 6) or
					(entity.distance < 4) 
				then
					--if channeltime is > 0 then we're already interacting with a quest object
					if(entity.type == 7) then
						ml_task_hub:ThisTask().isQuestObject = true
					end
					
					if(Player.castinginfo.channeltime > 0 or not entity.targetable) then
						return false
					else
						e_questinteract.entity = entity
						return true
					end
				end
			end
        end
    end
	
	return false
end
function e_questinteract:execute()
	local entity = e_questinteract.entity
	if (entity) then
		Player:Interact(entity.id)
		--vendor uses interact too but has a custom task_complete_eval() check
		--so we can ignore it
		if(	ml_task_hub:ThisTask().params["type"] == "interact"  and not
			ml_task_hub:ThisTask().params["itemturnin"] and not
			ml_task_hub:ThisTask().params["conversationindex"])
		then
			ml_task_hub:ThisTask().stepCompleted = true
		end
	end
end

c_questhandover = inheritsFrom( ml_cause )
e_questhandover = inheritsFrom( ml_effect )
function c_questhandover:evaluate()
	return Quest:IsRequestDialogOpen()
end
function e_questhandover:execute()
	ffxiv_task_quest.SetQuestFlags()
	if(ml_task_hub:CurrentTask().params["itemturnin"]) then
		if(ml_task_hub:CurrentTask().params["itemturninid"]) then
			if(not ml_task_hub:CurrentTask().idset) then
				ml_task_hub:CurrentTask().idset = {}
				for _, id in pairs(ml_task_hub:CurrentTask().params["itemturninid"]) do
					ml_task_hub:CurrentTask().idset[id] = false
				end
				ml_task_hub:CurrentTask().timer = ml_global_information.Now
			elseif(TimeSince(ml_task_hub:CurrentTask().timer) > 2000) then
				local handoverDone = true
				for id, handover in pairs(ml_task_hub:CurrentTask().idset) do
					if (not handover) then
						local item = Inventory:Get(id)
						if(ValidTable(item)) then
							item:HandOver()
							ml_task_hub:CurrentTask().idset[id] = true
							ml_task_hub:CurrentTask().timer = ml_global_information.Now
							handoverDone = false
							break
						end
					end
				end
				
				if(handoverDone) then
					Quest:RequestHandOver()
					--set a delay to allow the server to process the item handover
					ml_task_hub:CurrentTask():SetDelay(2000)
					if (ml_task_hub:CurrentTask().params["type"] == "interact") then
						ml_task_hub:CurrentTask().stepCompleted = true
					end
				end
			end
		else
			ml_error("Quest item handover required but no itemturninid set specified in profile")
		end
	else
		ml_error("Quest item handover required but itemturnin not specified in profile")
	end
end

c_questkill = inheritsFrom( ml_cause )
e_questkill = inheritsFrom( ml_effect )
function c_questkill:evaluate()
	local id = ml_task_hub:CurrentTask().params["id"]
    if (id and id > 0) then
		local el = nil
		local pos = ml_task_hub:CurrentTask().params["pos"]
		--if we're close to the kill position then check for any aggro mobs
		--if(Distance3D(Player.pos.x, Player.pos.y, Player.pos.z, pos.x, pos.y, pos.z) < 10) then
			el = EntityList("onmesh,alive,attackable,targetingme,contentid="..tostring(id))
		--end
	
		--otherwise check for mobs not incombat so we get credit for kill
		if(not ValidTable(el)) then
			el = EntityList("shortestpath,onmesh,alive,attackable,notincombat,contentid="..tostring(id))
		end
		
		if(ValidTable(el)) then
			local id, entity = next(el)
			if(entity) then
				e_questkill.id = id
				return true
			end
        end
    end
	
	return false
end
function e_questkill:execute()
	local newTask = ffxiv_task_killtarget.Create()
	newTask.targetid = e_questkill.id
	newTask.task_complete_execute = 
		function()
			ffxiv_task_quest.killTaskCompleted = true
			ml_task_hub:CurrentTask().completed = true
			--set a delay to give the inckillcount cne time to check quest flag update from server
			ml_task_hub:CurrentTask():SetDelay(3000)
		end
	newTask.task_fail_evaluate = 
		function()
			local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
			return not ValidTable(target) or (target.incombat and not target.targetid == Player.id)
		end
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_questprioritykill = inheritsFrom( ml_cause )
e_questprioritykill = inheritsFrom( ml_effect )
function c_questprioritykill:evaluate()
	local ids = ml_task_hub:ThisTask().params["ids"]
	
	local priority = 0
	for uniqueid in StringSplit(ids,";") do
		priority = priority + 1
		local currentPrio = ml_task_hub:ThisTask().currentPrio
		if ((currentPrio > 0 and priority < currentPrio) or currentPrio == 0) then
			local el = EntityList("shortestpath,onmesh,alive,attackable,contentid="..uniqueid)
			if (ValidTable(el)) then
				local id, target = next(el)
				if (target) then
					e_questprioritykill.id = target.id
					ml_task_hub:ThisTask().currentPrio = priority
					return true
				end
			end	
		end
	end
	
	return false
end
function e_questprioritykill:execute()
	local newTask = ffxiv_task_killtarget.Create()
	newTask.targetid = e_questprioritykill.id
	newTask.task_complete_execute = 
		function()
			ml_task_hub:CurrentTask():ParentTask().currentPrio = 0
			ml_task_hub:CurrentTask().completed = true
		end
	ml_task_hub:ThisTask():DeleteSubTasks()
	ml_task_hub:ThisTask():AddSubTask(newTask)
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_atinteract = inheritsFrom( ml_cause )
e_atinteract = inheritsFrom( ml_effect )
function c_atinteract:evaluate()
	-- if the current task is under delay then don't break it
	if (ml_task_hub:CurrentTask():IsDelayed()) then
		return false
	end

	if (ml_task_hub:CurrentTask().name == "MOVETOPOS" and not ml_task_hub:CurrentTask():ParentTask().name == "LT_KILLTARGET") then
		local id = ml_task_hub:ThisTask().params["id"]
		if (id and id > 0) then
			local el = EntityList("contentid="..tostring(id))
			if(ValidTable(el)) then
				local id, entity = next(el)
				if(entity) then
					if 	(entity.type == 5 and entity.distance2d < 6) or
						(entity.distance < 4) 
					then
						return true
					end
				end
			end
		end
	end
	
	return false
end
function e_atinteract:execute()
	ml_task_hub:CurrentTask():Terminate()
	ml_task_hub:CurrentTask():task_complete_execute()
end

c_indialog = inheritsFrom( ml_cause )
e_indialog = inheritsFrom( ml_effect )
function c_indialog:evaluate()
	return Quest:IsInDialog() and not ControlVisible("SelectIconString") and not ControlVisible("SelectString")
end
function e_indialog:execute()
	--do nothing, this is a blocking cne to avoid spamming
end

c_questyesno = inheritsFrom( ml_cause )
e_questyesno = inheritsFrom( ml_effect )
function c_questyesno:evaluate()
	if (gBotMode == GetString("assistMode") and gQuestHelpers == "0") then
		return false
	end
	return ControlVisible("SelectYesno")
end
function e_questyesno:execute()
	PressYesNo(true)
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_questisloading = inheritsFrom( ml_cause )
e_questisloading = inheritsFrom( ml_effect )
function c_questisloading:evaluate()
	return Quest:IsLoading()
end
function e_questisloading:execute()
	--do nothing, this is a blocking cne\
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_questgrind = inheritsFrom( ml_cause )
e_questgrind = inheritsFrom( ml_effect )
function c_questgrind:evaluate()
	return true
end
function e_questgrind:execute()
	--set fate variables properly
	if(Player.level < 5) then
		gDoFates = "0"
	else
		gDoFates = "1"
		gMinFateLevel = "5"
		gMaxFateLevel = "5"
	end
	
	local newTask = ffxiv_task_grind.Create()
	newTask.task_complete_eval = 
		function()
			return c_nextquest:evaluate()
		end
	--start grind task
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_changenavmesh = inheritsFrom( ml_cause )
e_changenavmesh = inheritsFrom( ml_effect )
function c_changenavmesh:evaluate()
	local step = ffxiv_task_quest.currentStepParams
	if(ValidTable(step)) then
		if(step["meshname"] ~= nil and ml_mesh_mgr.navmeshfilepath ~= nil) then
			local meshname = ml_mesh_mgr.navmeshfilepath..step["meshname"]
			if(	meshname ~= NavigationManager:GetNavMeshName() and
				Player.localmapid == step["mapid"]) 
			then
				e_changenavmesh.meshname = step["meshname"]
				return true
			end
		end
	end
end
function e_changenavmesh:execute()
	ml_mesh_mgr.LoadNavMesh( e_changenavmesh.meshname)
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_questtextcommand = inheritsFrom( ml_cause )
e_questtextcommand = inheritsFrom( ml_effect )
function c_questtextcommand:evaluate()
	local textstring = ml_task_hub:ThisTask().params["commandstring"]
	if(textstring == nil) then
		return false
	end

	local id = ml_task_hub:ThisTask().params["id"]
    if (id and id > 0) then
		local el = EntityList("contentid="..tostring(id))
		if(ValidTable(el)) then
			local id, entity = next(el)
			if(entity) then
				if (entity.distance < 6) 
				then
					e_questtextcommand.id = id
					return true
				else
					return false
				end
			end
        end
    end
	
	return true
end
function e_questtextcommand:execute()
	if(e_questtextcommand.id) then
		Player:SetTarget(e_questtextcommand.id)
	end
	
	SendTextCommand(ml_task_hub:ThisTask().params["commandstring"])
	ml_task_hub:ThisTask().stepCompleted = true
end

c_questuseitem = inheritsFrom( ml_cause )
e_questuseitem = inheritsFrom( ml_effect )
function c_questuseitem:evaluate()
	--if we already started using the item then there's gonna be a really annoying ~1000ms window
	--after the cast finishes when it will spam useitem again because the entity hasn't become not targetable yet
	--set a dynamic delay based on the cast time
	if (ml_task_hub:CurrentTask():IsDelayed() or
		ActionList:IsCasting()) 
	then
		return false
	end
	
	if(ml_task_hub:CurrentTask().params["itemid"]) then
		local id = ml_task_hub:CurrentTask().params["itemid"]
		local item = Inventory:Get(id)
		if(ValidTable(item)) then
			if(item.count < ml_task_hub:CurrentTask().startingCount) then
				return false
			end
			
			if(ml_task_hub:CurrentTask().params["id"]) then
				local list = EntityList("shortestpath,contentid="..tostring(ml_task_hub:CurrentTask().params["id"]))
				if(ValidTable(list)) then
					id, entity = next(list)
					if(id ~= nil and entity.targetable) then
						e_questuseitem.id = id
					end
				end
			end
			return true
		else
			d("No item with specified ID found in inventory")
			return false
		end
	else
		ml_error("No itemid found in profile")
		return false
	end
end
function e_questuseitem:execute()
	local item = Inventory:Get(ml_task_hub:CurrentTask().params["itemid"])
	if(e_questuseitem.id ~= nil) then
		Player:SetTarget(e_questuseitem.id)
		item:Use(e_questuseitem.id)
	else
		item:Use()
	end
		
	ml_task_hub:ThisTask().stepCompleted = true
end

c_questuseaction = inheritsFrom( ml_cause )
e_questuseaction = inheritsFrom( ml_effect )
function c_questuseaction:evaluate()
	if(ml_task_hub:CurrentTask().params["actionid"]) then
		local actionid = ml_task_hub:CurrentTask().params["actionid"]
		local actiontype = ml_task_hub:CurrentTask().params["actiontype"]

		local action = nil
		if(actiontype) then
			action = ActionList:Get(actionid,actiontype)
		else
			action = ActionList:Get(actionid)
		end
			
		if(ValidTable(action)) then
			e_questuseaction.action = action
			return true
		else
			ml_error("No action with specified id and type found")
			return false
		end
	else
		ml_error("No actionid found in profile")
		return false
	end
end
function e_questuseaction:execute()
	if(ml_task_hub:CurrentTask().params["id"]) then
		local list = EntityList("contentid="..tostring(ml_task_hub:ThisTask().params["id"]))
		if(ValidTable(list)) then
			local id, target = next(list)
			if(ValidTable(target)) then
				Player:SetTarget(target.id)
				e_questuseaction.action:Cast(target.id)
			end
		end
	else
		e_questuseaction.action:Cast()
	end
	
	ml_task_hub:ThisTask().stepCompleted = true
end

c_questmovetohealer = inheritsFrom( ml_cause )
e_questmovetohealer = inheritsFrom( ml_effect )
function c_questmovetohealer:evaluate()
	if(ml_task_hub:ThisTask().params["healderid"] and Player.hp.percent < 50) then
		local list = EntityList("contentid="..tostring(ml_task_hub:ThisTask().params["healderid"]))
		if(ValidTable(list)) then
			local id, healer = next(list)
			if(ValidTable(healer) and healer.distance > 5) then
				e_questmovetohealer.pos = healer.pos
				return true
			end
		end
	end
	
	return false
end
function e_questmovetohealer:execute()
	d("test move to healer")
	local pos = e_questmovetohealer.pos
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = pos
	newTask.use3d = true
	
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_questmovetoactionrange = inheritsFrom( ml_cause )
e_questmovetoactionrange = inheritsFrom( ml_effect )
function c_questmovetoactionrange:evaluate()
    if ( ml_task_hub:CurrentTask().params["id"] ) then
        local list = EntityList:Get("shortestpath,contentid="..ml_task_hub:CurrentTask().params["id"])
		if(ValidTable(list)) then
			local id, entity = next(list)
			if(ValidTable(entity)) then
				e_questmovetoactionrange.id = entity.id
				
				local actionid = ml_task_hub:CurrentTask().params["actionid"]
				local actiontype = ml_task_hub:CurrentTask().params["actiontype"]

				if(actiontype) then
					return not ActionList:CanCast(actionid,actiontype,entity.id)
				else
					return not ActionList:CanCast(actionid,entity.id)
				end
			end
        end
    end
    
    return false
end
function e_questmovetoactionrange:execute()
    ml_debug( "Moving within action range of target" )
    local target = EntityList:Get(e_questmovetoactionrange.id)
    if (target ~= nil and target.pos ~= nil) then
        local newTask = ffxiv_task_movetopos.Create()
        newTask.pos = target.pos
        newTask.useFollowMovement = false
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

c_questflee = inheritsFrom( ml_cause )
e_questflee = inheritsFrom( ml_effect )
e_questflee.fleeing = false
function c_questflee:evaluate()
	if (ml_global_information.disableFlee) then
		return false
	end
	
    if (Player.hasaggro and (Player.hp.percent < tonumber(gFleeHP) or Player.mp.percent < tonumber(gFleeMP))) then
		if(ValidTable(ml_marker_mgr.markerList["evacPoint"])) then
			return true
		else
			d("Need to flee but no evac position defined for current mesh - trying random position")
			local myPos = Player.pos
			local newPos = NavigationManager:GetRandomPointOnCircle(myPos.x,myPos.y,myPos.z,100,200)
			if(ValidTable(newPos)) then
				ml_marker_mgr.markerList["evacPoint"] = newPos
				return true
			end
        end
    end
    
    return false
end
function e_questflee:execute()
	ffxiv_task_quest.ResetStep()
	local fleePos = ml_marker_mgr.markerList["evacPoint"]
	if(ValidTable(fleePos)) then
		local newTask = ffxiv_task_movetopos.Create()
		newTask.pos = fleePos
		newTask.useTeleport = gTeleport == "1"
		newTask.task_complete_eval = 
			function ()
				return not Player.hasaggro
			end
		newTask.task_fail_eval = 
			function ()
				return not Player.alive or (not c_walktopos:evaluate() and Player.hasaggro)
			end
		--ml_task_hub:ThisTask().preserveSubtasks = true
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	else
		ml_error("Need to flee but no evac position defined for this mesh!!")
	end
end

c_questdead = inheritsFrom( ml_cause )
e_questdead = inheritsFrom( ml_effect )
function c_questdead:evaluate()
    if (Player.revivestate == 2 or Player.revivestate == 3) then --FFXIV.REVIVESTATE.DEAD & REVIVING
        return true
    end 
    return false
end
function e_questdead:execute()
	--if we have to restart at a previous interact step etc to spawn mobs to kill
	--then reset the step and all the kill state
	ffxiv_task_quest.ResetStep()

    ml_debug("Respawning...")
	-- try raise first
    if(PressYesNo(true)) then
		return
    end
	-- press ok
    if(PressOK()) then
		return
    end
end

--equip new items one per pulse
c_equipnewitems = inheritsFrom( ml_cause )
e_equipnewitems = inheritsFrom( ml_effect )
function c_equipnewitems:evaluate()
	return ffxiv_task_quest.armoryTable ~= nil
end
function e_equipnewitems:execute()
	local oldIDs = ffxiv_task_quest.armoryTable
	local currentIDs = GetArmoryIDsTable()
	local newIDs = {}
	for id, item in pairs(currentIDs) do
		if(oldIDs[id] == nil) then
			newIDs[id] = item
		end
	end
	
	if(TableSize(newIDs) > 0) then
		local id, item = next(newIDs)
		EquipItem(id)
		newIDs[id] = nil
	end
	
	if(TableSize(newIDs) == 0) then
		ffxiv_task_quest.armoryTable = nil
	else
		ffxiv_task_quest.armoryTable = GetArmoryIDsTable()
	end
end

--increment killcount
c_inckillcount = inheritsFrom( ml_cause )
e_inckillcount = inheritsFrom( ml_effect )
function c_inckillcount:evaluate()
	local disableFlagCheck = ml_task_hub:ThisTask().params["disableflagcheck"]
	if(ffxiv_task_quest.killTaskCompleted and (disableFlagCheck or ffxiv_task_quest.QuestFlagsChanged())) then
		return true
	elseif(ffxiv_task_quest.backupKillCount > 10) then
		--if the client gets ahead of the bot in killcount then the quest flags will never change once it reaches
		--the max kills for the objective. use a backup count and just count is as complete if its killed 5 with no flag change
		return true
	elseif(ffxiv_task_quest.killTaskCompleted) then
		ffxiv_task_quest.backupKillCount = ffxiv_task_quest.backupKillCount + 1
	end
	
	return false
end
function e_inckillcount:execute()
	ffxiv_task_quest.killCount = ffxiv_task_quest.killCount + 1
	ffxiv_task_quest.backupKillCount = 0
	ffxiv_task_quest.killTaskCompleted = false
	ffxiv_task_quest.SetQuestFlags()
	
	Settings.FFXIVMINION.questKillCount = ffxiv_task_quest.killCount
	gQuestKillCount = tostring(ffxiv_task_quest.killCount)
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_questkillaggrotarget = inheritsFrom( ml_cause )
e_questkillaggrotarget = inheritsFrom( ml_effect )
function c_questkillaggrotarget:evaluate()
	if(Player.castinginfo.channeltime > 0) then
		return false
	end
	
	--if we still have the quest object targeted then the mob may have spawned
	--don't start a kill aggro target task or we'll fuck up the next kill step
	local target = Player:GetTarget()
	if (ValidTable(target) and target.type == 7) then
		return false
	end

	if(ml_task_hub:ThisTask().name == "MOVETOPOS") then
		if(e_questflee.fleeing) then
			return false
		end
		
		local myPos = Player.pos
		local gotoPos = ml_task_hub:ThisTask().pos
		local distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
		if(distance > 50) then
			--d("KillAggroTarget False - distance to quest pos :"..tostring(distance))
			return false
		end
	end

	local el = EntityList("alive,attackable,onmesh,targetingme")
	if (ValidTable(el)) then
		local id, target = next(el)
		if (ValidTable(target)) then
			if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0 and (target.level <= (Player.level + 3))) then
				--d("KillAggroTarget True - targetingme")
				c_questkillaggrotarget.targetid = target.id
				return true
			end
		end
	end
	
	el = EntityList("shortestpath,alive,attackable,onmesh,aggressive,maxdistance=15")
	if (ValidTable(el)) then
		local id, target = next(el)
		if (ValidTable(target)) then
			if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0 and (target.level <= (Player.level + 3))) then
				--d("KillAggroTarget True - aggressive")
				c_questkillaggrotarget.targetid = target.id
				return true
			end
		end
	end
    
    return false
end
function e_questkillaggrotarget:execute()
	--just in case
	Player:Stop()
	Dismount()
	
	local newTask = ffxiv_task_killtarget.Create()
    newTask.targetid = c_questkillaggrotarget.targetid
	Player:SetTarget(c_questkillaggrotarget.targetid)
	
	--if our hp drops below flee rate then consider the task failed and gtfo
	local c_killfail = inheritsFrom( ml_cause )
	local e_killfail = inheritsFrom( ml_effect )
	function c_killfail:evaluate()
		return Player.hp.percent < tonumber(gFleeHP) or Player.mp.percent < tonumber(gFleeMP)
	end
	function e_killfail:execute()
		ml_task_hub:ThisTask():Terminate()
	end
    newTask:add( ml_element:create( "KillAggroFail", c_killfail, e_killfail, 100 ), newTask.overwatch_elements)
	ml_task_hub:ThisTask().preserveSubtasks = true
	ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
end

c_questbuy = inheritsFrom( ml_cause )
e_questbuy = inheritsFrom( ml_effect )

function c_questbuy:evaluate()	
	--check for vendor window open
	if (not ControlVisible("Shop")) then
		return false
	end
	
	local itemtable = ml_task_hub:CurrentTask().params["itemid"]
	if(ValidTable(itemtable))then
		local itemid = itemtable[Player.job] or itemtable[-1]
		if (itemid) then
			e_questbuy.itemid = tonumber(itemid)
			return true
		end
	end
	
	return false
	
end
function e_questbuy:execute()
	local buyamount = ml_task_hub:CurrentTask().params["buyamount"] or 1
	d("test")
	d(e_questbuy.itemid)
	if(Inventory:BuyShopItem(e_questbuy.itemid,buyamount)) then
		if(ml_task_hub:CurrentTask().params["equip"]) then
			ffxiv_task_quest.AddEquipItem(e_questbuy.itemid)
		end
	end
	
	--set a delay on the current task to give the server time to update the item count
	--so the task completion check will be valid
	ml_task_hub:CurrentTask():SetDelay(1000)
end

c_questselectconvindex = inheritsFrom( ml_cause )
e_questselectconvindex = inheritsFrom( ml_effect )
function c_questselectconvindex:evaluate()	
	--check for vendor window open
	local index = ml_task_hub:CurrentTask().params["conversationindex"]
	return index and (ControlVisible("SelectIconString") or ControlVisible("SelectString"))
end
function e_questselectconvindex:execute()
	SelectConversationIndex(tonumber(ml_task_hub:CurrentTask().params["conversationindex"]))
	if (ml_task_hub:CurrentTask().params["type"] == "interact") then
		ml_task_hub:CurrentTask().stepCompleted = true
	end
	--delay to allow conversation to update
	ml_task_hub:CurrentTask():SetDelay(1500)
end

--when we want to equip a new item from a reward we create a table of current ids before reward
--then this cne kicks in and sees that the table was set, checks a diff, and equips anything new
c_equipreward = inheritsFrom( ml_cause )
e_equipreward = inheritsFrom( ml_effect )
function c_equipreward:evaluate()	
	return ValidTable(ffxiv_task_quest.lastArmoryIDs)
end
function e_equipreward:execute()
	local newArmoryIDs = GetArmoryIDsTable()
	for id, _ in pairs(newArmoryIDs) do
		if(not ffxiv_task_quest.lastArmoryIDs[id]) then
			ffxiv_task_quest.AddEquipItem(id)
		end
	end
	ffxiv_task_quest.lastArmoryIDs = {}
end

c_questequip = inheritsFrom( ml_cause )
e_questequip = inheritsFrom( ml_effect )
function c_questequip:evaluate()
	local itemid = ml_task_hub:CurrentTask().params["itemid"]
	if(type(itemid) == "number") then
		local item = Inventory:Get(itemid)
		if(ValidTable(item)) then
			local currItem = GetItemInSlot(item.slot)
			return not currItem or (currItem.id ~= itemid)
		end
	elseif(type(itemid) == "table" and ValidTable(itemid)) then
		local equipped = true
		local itemtable = itemid[Player.job] or itemid[-1]
		if(ValidTable(itemtable)) then
			for _, id in pairs(itemtable) do
				local item = Inventory:Get(id)
				if(ValidTable(item)) then
					local currItem = GetItemInSlot(item.slot)
					if (not currItem or currItem.id ~= item.id) then
						equipped = false
					end
				end
			end
		end
		
		return not equipped
	end
	
	return false
end
function e_questequip:execute()
	local itemid = ml_task_hub:CurrentTask().params["itemid"]
	if(type(itemid) == "number") then
		ffxiv_task_quest.AddEquipItem(itemid)
	elseif(type(itemid) == "table" and ValidTable(itemid)) then
		local itemtable = itemid[Player.job] or itemid[-1]
		if(ValidTable(itemtable)) then
			for _, id in pairs(itemtable) do
				ffxiv_task_quest.AddEquipItem(id, true)
			end
		end
	end
end

c_questidle = inheritsFrom( ml_cause )
e_questidle = inheritsFrom( ml_effect )
function c_questidle:evaluate()
	return ml_global_information.idlePulseCount > 2000
end
function e_questidle:execute()
	--something break because we haven't executed a cne in a long time
	--try the next quest step
	ml_error("Stuck idle in task "..ml_task_hub:CurrentTask().name.." for quest "..gCurrQuestID.." on step "..gCurrQuestStep)
	if(gDevDebug == "1") then
		ml_task_hub.ToggleRun()
		return
	else
		ml_error("Attempting to fix by moving to next quest step")
		ml_task_hub:CurrentTask():task_complete_execute()
	end
end

c_questreset = inheritsFrom( ml_cause )
e_questreset = inheritsFrom( ml_effect )
function c_questreset:evaluate()
	return ml_global_information.idlePulseCount > 2000 
end
function e_questreset:execute()
	ml_error("Quest "..gCurrQuestID.." cannot be completed because all quest objectives have not been met...something screwed up!")
	if(gDevDebug == "1") then
		ml_task_hub.ToggleRun()
		return
	else
		ml_error("Attempting to restart quest objectives at step 2 of profile")
		ffxiv_task_quest.restartStep = 2
		ffxiv_task_quest.ResetStep()
	end
end

--sets a delay based on the cast time for item so that we don't spam 
c_questitemcastdelay = inheritsFrom( ml_cause )
e_questitemcastdelay = inheritsFrom( ml_effect )
function c_questitemcastdelay:evaluate()
	local target = Player:GetTarget()
	if(target and target.type == 7) then
		if(Player.castinginfo.casttime > 0 and not ml_task_hub:ThisTask().delaySet) then
			return true
		end
	end
end
function e_questitemcastdelay:execute()
	ml_task_hub:CurrentTask():SetDelay(tonumber(Player.castinginfo.casttime)*1000 + 2000)
	ml_task_hub:ThisTask().delaySet = true
end
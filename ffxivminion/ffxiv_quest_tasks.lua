--the main quest task (ffxiv_quest_task) will always have two separate indexes running simultaneously,
--currentStepIndex and currentObjectiveIndex, and these will never match since the start step is not considered
--an objective by the client.

--the tricky part to understand for quest step tasks is how they are completed. some tasks which we have
--good client data for have their own task_complete_eval() checks where they verify this data before
--completing. other tasks have to use an explicit "stepcompleted" flag check, which is set by the cne
--in the task that is the final cne for the step behavior. it should be obvious that this is not a very
--safe or clean way to verify that a quest objective has actually be completed - as we get more data in
--the quest objective flags we will try to get rid of this strategy. 

--default step complete eval/execute functions
--must be called from a quest step task where the parent task is a ffxiv_quest_task object
--these cnes will be used for all quest step tasks which do not overwrite the default eval or execute
--function with custom checks
function quest_step_complete_eval()
	--if we handed over an item then don't complete the step until the objective flags have changed
	--this is to avoid bugging the quest
	if(ml_task_hub:CurrentTask().params["itemturnin"]) then
		return ml_task_hub:CurrentTask().stepCompleted and ffxiv_task_quest.QuestFlagsChanged()
	end
	
	return ml_task_hub:CurrentTask().stepCompleted
end

function quest_step_complete_execute()
	if (ml_global_information.disableFlee) then
		ml_global_information.disableFlee = false
	end
	
	ffxiv_task_quest.restartStep = 0
	
	ml_task_hub:CurrentTask():ParentTask().currentStepCompleted = true
	ml_task_hub:CurrentTask().completed = true
	local delay = ml_task_hub:CurrentTask().params["delay"]
	if (delay == nil or delay == 0) then
		--minimum delay to allow quest objective flags to update
		delay = math.random(1500,2000)
	end
	ml_task_hub:CurrentTask():SetDelay(delay)
	
	--in case we turned off AOE for the quest step, set it back to original behavior
	gAvoidAOE = "1"
end

ffxiv_quest_task = inheritsFrom(ml_task)
ffxiv_quest_task.name = "LT_QUEST"

function ffxiv_quest_task.Create()
    local newinst = inheritsFrom(ffxiv_quest_task)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "LT_QUEST"
    
    newinst.currentStep = {}
	newinst.currentStepCompleted = true
    newinst.currentStepIndex = 1
	newinst.currentObjectiveIndex = 1
	newinst.profileData = {}
	newinst.quest = nil
	newinst.started = false
	newinst.startTimer = 0
	newinst.questCompleted = false
    
    return newinst
end

function ffxiv_quest_task:task_complete_eval()
	return self.quest:hasBeenCompleted()
end

function ffxiv_quest_task:task_complete_execute()
	self.completed = true
end

function ffxiv_quest_task:Init()
    --init ProcessOverWatch cnes
	local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 35 )
    self:add( ke_rest, self.process_elements)
	
	--its tempting to make autoequip an overwatch cne but there are too many states 
	--when the client does not allow gear changes
	local ke_equip = ml_element:create( "Equip", c_equip, e_equip, 25 )
    self:add( ke_equip, self.process_elements)
	
	--needs a timer to stop it from restarting due to latency for quest data change after accepting
	local ke_questCanStart = ml_element:create( "QuestCanStart", c_questcanstart, e_questcanstart, 20 )
    self:add( ke_questCanStart, self.process_elements)
	
    local ke_nextQuestStep = ml_element:create( "NextQuestStep", c_nextqueststep, e_nextqueststep, 15 )
    self:add( ke_nextQuestStep, self.process_elements)
	
	local ke_questIsComplete = ml_element:create( "QuestIsComplete", c_questiscomplete, e_questiscomplete, 14 )
    self:add( ke_questIsComplete, self.process_elements)
	
	local ke_questReset = ml_element:create( "QuestResetCheck", c_questreset, e_questreset, 10 )
    self:add( ke_questReset, self.process_elements)
	
	--overwatch
	local ke_questYesNo = ml_element:create( "QuestYesNo", c_questyesno, e_questyesno, 105 )
    self:add( ke_questYesNo, self.overwatch_elements)
	
	local ke_changeNavMesh = ml_element:create( "ChangeNavMesh", c_changenavmesh, e_changenavmesh, 100 )
    self:add( ke_changeNavMesh, self.overwatch_elements)
	
	self:AddTaskCheckCEs()
end

ffxiv_quest_start = inheritsFrom(ml_task)
ffxiv_quest_start.name = "QUEST_START"

function ffxiv_quest_start.Create()
    local newinst = inheritsFrom(ffxiv_quest_start)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "QUEST_START"
    
    newinst.params = {}
	newinst.stepCompleted = false
    
    return newinst
end

function ffxiv_quest_start:task_complete_eval()
	return ffxiv_task_quest.currentQuest:isStarted()
end

function ffxiv_quest_start:Init()
    --init ProcessOverWatch cnes
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 05 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	local ke_questInteract = ml_element:create( "QuestInteract", c_questinteract, e_questinteract, 10 )
    self:add( ke_questInteract, self.process_elements)
	
	local ke_questAtInteract = ml_element:create( "QuestAtInteract", c_atinteract, e_atinteract, 10 )
    self:add( ke_questAtInteract, self.overwatch_elements)
	
	local ke_questSelectConvIndex = ml_element:create( "QuestSelectConvIndex", c_questselectconvindex, e_questselectconvindex, 12 )
    self:add( ke_questSelectConvIndex, self.process_elements)
	
	local ke_questAccept = ml_element:create( "QuestAccept", c_questaccept, e_questaccept, 15 )
    self:add( ke_questAccept, self.process_elements)
	
	local ke_inDialog = ml_element:create( "QuestInDialog", c_indialog, e_indialog, 95 )
    self:add( ke_inDialog, self.process_elements)
	
	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

--quest_accept is the same as quest_start except it checks a passed in quest id 
--instead of the current quest id to verify completion
--we'll still inherit from ml_task in case we want to change stuff later
ffxiv_quest_accept = inheritsFrom(ml_task)
ffxiv_quest_accept.name = "QUEST_ACCEPT"

function ffxiv_quest_accept.Create()
	local newTask = ffxiv_quest_start.Create()
	newTask.name = "QUEST_ACCEPT"
	newTask.task_complete_eval = 
		function ()
			return Quest:HasQuest(ml_task_hub:CurrentTask().params["questid"])
		end
	return newTask
end

ffxiv_quest_complete = inheritsFrom(ml_task)
ffxiv_quest_complete.name = "QUEST_COMPLETE"

function ffxiv_quest_complete.Create()
    local newinst = inheritsFrom(ffxiv_quest_complete)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "QUEST_COMPLETE"
    
    newinst.params = {}
	newinst.stepCompleted = false
    
    return newinst
end

function ffxiv_quest_complete:task_complete_eval()
	return ffxiv_task_quest.currentQuest:hasBeenCompleted()
end

function ffxiv_quest_complete:task_fail_eval()
		--if the new task is a complete step and the quest isn't complete then we fucked up somewhere
		--try to restart at the second step of the quest and put up an error message
		return not ffxiv_task_quest.currentQuest:isComplete() and not ffxiv_task_quest.currentQuest:hasBeenCompleted()
end

function ffxiv_quest_complete:task_fail_execute()
	ml_error("Quest "..gCurrQuestID.." cannot be completed because all quest objectives have not been met...something screwed up!")
	ml_error("Attempting to restart quest objectives at step 2 of profile")
	ffxiv_task_quest.restartStep = 2
	ffxiv_task_quest.ResetStep()
	self:Terminate()
end

function ffxiv_quest_complete:Init()
	local ke_inDialog = ml_element:create( "QuestInDialog", c_indialog, e_indialog, 95 )
    self:add( ke_inDialog, self.process_elements)
	
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questHandover = ml_element:create( "QuestHandover", c_questhandover, e_questhandover, 15 )
    self:add( ke_questHandover, self.process_elements)

	local ke_questComplete = ml_element:create( "QuestComplete", c_questcomplete, e_questcomplete, 15 )
    self:add( ke_questComplete, self.process_elements)	
	
	local ke_questSelectConvIndex = ml_element:create( "QuestSelectConvIndex", c_questselectconvindex, e_questselectconvindex, 12 )
    self:add( ke_questSelectConvIndex, self.process_elements)
	
	local ke_questInteract = ml_element:create( "QuestInteract", c_questinteract, e_questinteract, 10 )
    self:add( ke_questInteract, self.process_elements)
	
	local ke_questAtInteract = ml_element:create( "QuestAtInteract", c_atinteract, e_atinteract, 10 )
    self:add( ke_questAtInteract, self.overwatch_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 05 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

ffxiv_quest_interact = inheritsFrom(ml_task)
ffxiv_quest_interact.name = "QUEST_INTERACT"

function ffxiv_quest_interact.Create()
    local newinst = inheritsFrom(ffxiv_quest_interact)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "QUEST_INTERACT"
    
    newinst.params = {}
	newinst.stepCompleted = false
    
    return newinst
end

function ffxiv_quest_interact:task_complete_eval()
	--self.isQuestObject should only be set after we interact with the object
	--so if its not targetable or its gone (for doors that make you leave/enter rooms)
	--then the task is complete
	local target = Player:GetTarget()
	if (target and (target.type == 7 or target.type == 5 or target.type == 3)) then
		if(ActionList:IsCasting()) then
			return false
		end
	end
	
	local id = ml_task_hub:ThisTask().params["id"]
    if (id and id > 0) then
		local el = EntityList("closest,maxdistance=10,contentid="..tostring(id))
		if(ValidTable(el)) then
			local id, entity = next(el)
			if(ValidTable(entity) and entity.type == 7) then
				return not entity.targetable
			end
		end
	end

	return ml_task_hub:CurrentTask().stepCompleted
end

--interact step will "complete" based on the following cne priority
--(1) QuestHandover
--(2) QuestSelectConvIndex
--(3) QuestInteract
--what this means is that if ["itemturnin"] exists in the param then the task will
--not set the "complete" flag for the step until this cne is executed. same
--idea for ["conversationindex"] but at a lower priority
function ffxiv_quest_interact:Init()
    --init ProcessOverWatch cnes
	local ke_inDialog = ml_element:create( "QuestInDialog", c_indialog, e_indialog, 95 )
    self:add( ke_inDialog, self.process_elements)
	
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)

	local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 22 )
    self:add( ke_rest, self.process_elements)
	
	local ke_questHandover = ml_element:create( "QuestHandover", c_questhandover, e_questhandover, 15 )
    self:add( ke_questHandover, self.process_elements)	
	
	local ke_questSelectConvIndex = ml_element:create( "QuestSelectConvIndex", c_questselectconvindex, e_questselectconvindex, 12 )
    self:add( ke_questSelectConvIndex, self.process_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 10 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	local ke_killAggroTarget = ml_element:create( "KillAggroTarget", c_questkillaggrotarget, e_questkillaggrotarget, 8 )
    self:add( ke_killAggroTarget, self.process_elements)
	
	local ke_questInteract = ml_element:create( "QuestInteract", c_questinteract, e_questinteract, 5 )
    self:add( ke_questInteract, self.process_elements)
	
	local ke_questIdle = ml_element:create( "QuestIdleCheck", c_questidle, e_questidle, 01 )
    self:add( ke_questIdle, self.process_elements)
	
	--overwatch
	local ke_flee = ml_element:create( "Flee", c_questflee, e_questflee, 15 )
    self:add( ke_flee, self.overwatch_elements)
	
	local ke_questAtInteract = ml_element:create( "QuestAtInteract", c_atinteract, e_atinteract, 10 )
    self:add( ke_questAtInteract, self.overwatch_elements)
	
	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

------------------------------------------------------
--kill quest
------------------------------------------------------

ffxiv_quest_kill = inheritsFrom(ml_task)
ffxiv_quest_kill.name = "QUEST_KILL"

function ffxiv_quest_kill.Create()
    local newinst = inheritsFrom(ffxiv_quest_kill)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "QUEST_KILL"
    
    newinst.params = {}
	newinst.stepCompleted = false
	newinst.killCount = 0
    
    return newinst
end

function ffxiv_quest_kill:Init()
    --init ProcessOverWatch cnes
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 30 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 25 )
    self:add( ke_rest, self.process_elements)
	
	local ke_incrementKillCount = ml_element:create( "IncrementKillCount", c_inckillcount, e_inckillcount, 22 )
    self:add( ke_incrementKillCount, self.process_elements)
	
	local ke_killAggroTarget = ml_element:create( "KillAggroTarget", c_questkillaggrotarget, e_questkillaggrotarget, 21 )
    self:add( ke_killAggroTarget, self.process_elements)
	
	local ke_questKill = ml_element:create( "QuestKill", c_questkill, e_questkill, 20 )
    self:add( ke_questKill, self.process_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 15 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	local ke_questIdle = ml_element:create( "QuestIdleCheck", c_questidle, e_questidle, 10 )
    self:add( ke_questIdle, self.process_elements)
	
	--overwatch
	local ke_flee = ml_element:create( "Flee", c_questflee, e_questflee, 15 )
    self:add( ke_flee, self.overwatch_elements)
	
	self:AddTaskCheckCEs()
end

function ffxiv_quest_kill:task_complete_eval()
	if((not self.params["killcount"] and ffxiv_task_quest.killCount == 1) or
		(self.params["killcount"] == ffxiv_task_quest.killCount))
	then
		return true
	end

	return false
end

function ffxiv_quest_kill:task_complete_execute()
	Settings.FFXIVMINION.questKillCount = nil
	gQuestKillCount = ""
	ffxiv_task_quest.killCount = 0
	
	quest_step_complete_execute()
end

--if we're stuck in a kill step because the count got screwed up and the quest objectives were completed already
--then the objectives flag will never change to increment the killcount again. we need to fail the task so that the
--complete cne can kick in
function ffxiv_quest_kill:task_fail_eval()
	local disableFlagCheck = self.params["disableflagcheck"]
	local isLastStep = tonumber(gCurrQuestStep) == (TableSize(ffxiv_task_quest.currentQuest.steps) - 1)

	return (not disableFlagCheck and ffxiv_task_quest.currentQuest:isComplete())
end

--using the same code as complete_execute() for now but created a separate callback in case we want to 
--customize the fail state later
function ffxiv_quest_kill:task_fail_execute()
	Settings.FFXIVMINION.questKillCount = nil
	gQuestKillCount = ""
	ffxiv_task_quest.killCount = 0
	
	quest_step_complete_execute()
end


------------------------------------------------------
--dutykill quest
--this is a general purpose quest task for fights
--where multiple mobs need to be prioritized 
------------------------------------------------------

ffxiv_quest_dutykill = inheritsFrom(ml_task)
ffxiv_quest_dutykill.name = "QUEST_DUTYKILL"

function ffxiv_quest_dutykill.Create()
    local newinst = inheritsFrom(ffxiv_quest_dutykill)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "QUEST_DUTYKILL"
	newinst.currentPrio = 999
    
    newinst.params = {}
	newinst.stepCompleted = false
    
    return newinst
end

function ffxiv_quest_dutykill:Init()
    --priority kill runs in overwatch so it can switch targets when necessary
	local ke_questMoveToHealer = ml_element:create( "QuestMoveToHealer", c_questmovetohealer, e_questmovetohealer, 25 )
    self:add( ke_questMoveToHealer, self.overwatch_elements)

    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questPriorityKill = ml_element:create( "QuestPriorityKill", c_questprioritykill, e_questprioritykill, 20 )
    self:add( ke_questPriorityKill, self.overwatch_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 15 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	local ke_questIdle = ml_element:create( "QuestIdleCheck", c_questidle, e_questidle, 01 )
    self:add( ke_questIdle, self.process_elements)
	
	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

function ffxiv_quest_dutykill:task_complete_eval()
	local mapid = self.params["mapid"]
	return Player.localmapid ~= mapid and ffxiv_task_quest.QuestObjectiveChanged()
end

function ffxiv_quest_dutykill:task_fail_eval()
	return Player.hp.percent < 10
end

function ffxiv_quest_dutykill:task_fail_execute()
	self:Invalidate()
	ffxiv_task_quest.ResetStep()
end

------------------------------------------------------
--nav helper
------------------------------------------------------

ffxiv_quest_nav = inheritsFrom(ml_task)
ffxiv_quest_nav.name = "QUEST_NAVIGATE"

function ffxiv_quest_nav.Create()
    local newinst = inheritsFrom(ffxiv_quest_nav)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "QUEST_NAVIGATE"
    
    newinst.params = {}
	newinst.stepCompleted = false
    
    return newinst
end

function ffxiv_quest_nav:task_complete_eval()
	local myPos = Player.pos
	local gotoPos = self.params["pos"]
	local distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
	
	if (distance <= 0.5) then
		return true
	end
end

function ffxiv_quest_nav:Init()
    --init ProcessOverWatch cnes
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 05 )
    self:add( ke_questMoveToPos, self.process_elements)

	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

------------------------------------------------------
--grind helper
------------------------------------------------------
ffxiv_quest_grind = inheritsFrom(ml_task)
ffxiv_quest_grind.name = "QUEST_GRIND"

function ffxiv_quest_grind.Create()
    local newinst = inheritsFrom(ffxiv_quest_grind)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "QUEST_GRIND"
    
    newinst.params = {}
	newinst.stepCompleted = false
    
    return newinst
end

function ffxiv_quest_grind:Init()
    --init ProcessOverWatch cnes
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questGrind = ml_element:create( "QuestGrind", c_questgrind, e_questgrind, 20 )
    self:add( ke_questGrind, self.process_elements)

	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

ffxiv_quest_textcommand = inheritsFrom(ml_task)
ffxiv_quest_textcommand.name = "QUEST_TEXTCOMMAND"

function ffxiv_quest_textcommand.Create()
    local newinst = inheritsFrom(ffxiv_quest_textcommand)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "QUEST_TEXTCOMMAND"
    
    newinst.params = {}
	newinst.stepCompleted = false
    
    return newinst
end

function ffxiv_quest_textcommand:Init()
    --init ProcessOverWatch cnes
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 20 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	local ke_questTextCommand = ml_element:create( "QuestTextCommand", c_questtextcommand, e_questtextcommand, 15 )
    self:add( ke_questTextCommand, self.process_elements)

	self.task_complete_eval = quest_step_complete_eval
	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

ffxiv_quest_useitem = inheritsFrom(ml_task)
ffxiv_quest_useitem.name = "QUEST_USEITEM"

function ffxiv_quest_useitem.Create()
    local newinst = inheritsFrom(ffxiv_quest_useitem)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "QUEST_USEITEM"
    
    newinst.params = {}
	newinst.stepCompleted = false
    
    return newinst
end

function ffxiv_quest_useitem:task_complete_eval()
	local target = Player:GetTarget()
	if(target and (target.type == 7 or target.type == 3)) then
		if(ActionList:IsCasting()) then
			return false
		end
	end
	
	local id = ml_task_hub:ThisTask().params["id"]
    if (id and id > 0) then
		local el = EntityList("closest,maxdistance=10,contentid="..tostring(id))
		if(ValidTable(el)) then
			local id, entity = next(el)
			if(ValidTable(entity)) then
				return not entity.targetable
			end
		end
	end
	
	if(ml_task_hub:CurrentTask().params["itemid"]) then
		local id = ml_task_hub:CurrentTask().params["itemid"]
		local item = Inventory:Get(id)
		if( not ValidTable(item)) then
			return true
		elseif(item.count < ml_task_hub:CurrentTask().startingCount and ml_task_hub:CurrentTask().stepCompleted) then
			return true
		end
	end
	
	return false
end

function ffxiv_quest_useitem:Init()
    --init ProcessOverWatch cnes
	local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 25 )
    self:add( ke_rest, self.process_elements)
	
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 20 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	local ke_killAggroTarget = ml_element:create( "KillAggroTarget", c_questkillaggrotarget, e_questkillaggrotarget, 15 )
    self:add( ke_killAggroTarget, self.process_elements)	
	
	local ke_questUseItem = ml_element:create( "QuestUseItem", c_questuseitem, e_questuseitem, 10 )
    self:add( ke_questUseItem, self.process_elements)
	
	local ke_questItemCastDelay = ml_element:create( "QuestItemCastDelay", c_questitemcastdelay, e_questitemcastdelay, 10 )
    self:add( ke_questItemCastDelay, self.process_elements)
	
	--overwatch
	local ke_flee = ml_element:create( "Flee", c_questflee, e_questflee, 15 )
    self:add( ke_flee, self.overwatch_elements)

	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

ffxiv_quest_useaction = inheritsFrom(ml_task)
ffxiv_quest_useaction.name = "QUEST_USEACTION"

function ffxiv_quest_useaction.Create()
    local newinst = inheritsFrom(ffxiv_quest_useaction)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "QUEST_USEACTION"
    
    newinst.params = {}
	newinst.stepCompleted = false
    
    return newinst
end

function ffxiv_quest_useaction:task_complete_eval()
	local target = Player:GetTarget()
	if(target and (target.type == 7 or target.type == 3)) then
		if(ActionList:IsCasting()) then
			return false
		end
	end
	
	local id = ml_task_hub:ThisTask().params["id"]
    if (id and id > 0) then
		local el = EntityList("closest,maxdistance=10,contentid="..tostring(id))
		if(ValidTable(el)) then
			local id, entity = next(el)
			if(ValidTable(entity)) then
				return not entity.targetable
			end
		end
	end
	
	return ml_task_hub:CurrentTask().stepCompleted
end

function ffxiv_quest_useaction:Init()
    --init ProcessOverWatch cnes
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 22 )
    self:add( ke_rest, self.process_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 20 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	local ke_killAggroTarget = ml_element:create( "KillAggroTarget", c_questkillaggrotarget, e_questkillaggrotarget, 16 )
    self:add( ke_killAggroTarget, self.process_elements)	
	
	local ke_moveToActionRange = ml_element:create( "QuestMoveToActionRange", c_questmovetoactionrange, e_questmovetoactionrange, 15 )
	self:add( ke_moveToActionRange, self.process_elements)
	
	local ke_questUseAction = ml_element:create( "QuestUseAction", c_questuseaction, e_questuseaction, 10 )
    self:add( ke_questUseAction, self.process_elements)
	
	
	--overwatch
	local ke_flee = ml_element:create( "Flee", c_questflee, e_questflee, 15 )
    self:add( ke_flee, self.overwatch_elements)

	self.task_complete_eval = quest_step_complete_eval
	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

ffxiv_quest_vendor = inheritsFrom(ml_task)
ffxiv_quest_vendor.name = "QUEST_VENDOR"

function ffxiv_quest_vendor.Create()
    local newinst = inheritsFrom(ffxiv_quest_vendor)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "QUEST_VENDOR"
    
    newinst.params = {}
	newinst.stepCompleted = false
	newinst.startingCount = 0
    
    return newinst
end

function ffxiv_quest_vendor:task_complete_eval()
	local itemtable = self.params["itemid"]
	if(ValidTable(itemtable)) then
		local itemid = itemtable[Player.job] or itemtable[-1]
		local amount = tonumber(self.params["buyamount"])
		local item = Inventory:Get(itemid)
		if(ValidTable(item)) then
			local buycomplete = false
			if(amount) then
				buycomplete = item.count == self.startingCount + amount
			else
				buycomplete = item.count > self.startingCount
			end
			
			if(buycomplete) then
				Inventory:CloseShopWindow()
				return true
			end
		end
	end
	
	return false
end

function ffxiv_quest_vendor:Init()
	local ke_inDialog = ml_element:create( "QuestInDialog", c_indialog, e_indialog, 95 )
    self:add( ke_inDialog, self.process_elements)
	
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questBuy = ml_element:create( "QuestBuy", c_questbuy, e_questbuy, 15 )
    self:add( ke_questBuy, self.process_elements)
	
	local ke_questSelectConvIndex = ml_element:create( "QuestSelectConvIndex", c_questselectconvindex, e_questselectconvindex, 12 )
    self:add( ke_questSelectConvIndex, self.process_elements)
	
	local ke_questInteract = ml_element:create( "QuestInteract", c_questinteract, e_questinteract, 10 )
    self:add( ke_questInteract, self.process_elements)
	
	local ke_questAtInteract = ml_element:create( "QuestAtInteract", c_atinteract, e_atinteract, 10 )
    self:add( ke_questAtInteract, self.overwatch_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 05 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

ffxiv_quest_equip = inheritsFrom(ml_task)
ffxiv_quest_equip.name = "QUEST_EQUIP"

function ffxiv_quest_equip.Create()
    local newinst = inheritsFrom(ffxiv_quest_equip)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "QUEST_EQUIP"
    
    newinst.params = {}
	newinst.stepCompleted = false
    
    return newinst
end

function ffxiv_quest_equip:Init()
	local ke_inDialog = ml_element:create( "QuestInDialog", c_indialog, e_indialog, 95 )
    self:add( ke_inDialog, self.process_elements)

    --equip is the cne that actually equips items in the equip queue (ml_global_information.itemIDsToEquip)
	local ke_equip = ml_element:create( "Equip", c_equip, e_equip, 25 )
    self:add( ke_equip, self.process_elements)
	
	--questEquip checks the step params and adds any non-equipped itemids to the queue
    local ke_questEquip = ml_element:create( "QuestEquip", c_questequip, e_questequip, 20 )
    self:add( ke_questEquip, self.process_elements)
	
	
	--the questequip cne checks to see if we have equipped all requested items so its also a valid completion eval
	self.task_complete_eval = function() return not c_questequip:evaluate() end
	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end
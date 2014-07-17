--the most complex part of the questing engine to understand is that it is using two different types of task/step
--verification. if a quest step represents an objective from the quest client data then the engine will attempt
--to use client data for safer verification that the quest steps are being completed properly. otherwise if the
--["nonquestobjective"] param is true for the step then the quest engine will use a backup explicit step increment
--where the completion variable is simply set to true by the step task without verifying that the quest objective
--index has changed in the client. this is the only way to allow non quest objective steps to be included in the
--profiles while still making the best attempt to verify that quests are being completed properly. 
--the main quest task (ffxiv_quest_task) will always have two separate indexes running simultaneously,
--currentStepIndex and currentObjectiveIndex, and these will never match since the start step is not considered
--an objective by the client.


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
    local ke_nextQuestStep = ml_element:create( "NextQuestStep", c_nextqueststep, e_nextqueststep, 15 )
    self:add( ke_nextQuestStep, self.process_elements)
	
	--needs a timer to stop it from restarting due to latency for quest data change after accepting
	local ke_questCanStart = ml_element:create( "QuestCanStart", c_questcanstart, e_questcanstart, 20 )
    self:add( ke_questCanStart, self.process_elements)
	
	local ke_questIsComplete = ml_element:create( "QuestIsComplete", c_questiscomplete, e_questiscomplete, 20 )
    self:add( ke_questIsComplete, self.process_elements)
	
	local ke_changeNavMesh = ml_element:create( "ChangeNavMesh", c_changenavmesh, e_changenavmesh, 100 )
    self:add( ke_changeNavMesh, self.overwatch_elements)
	
	local ke_questYesNo = ml_element:create( "QuestYesNo", c_questyesno, e_questyesno, 105 )
    self:add( ke_questYesNo, self.overwatch_elements)
	
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

function ffxiv_quest_complete:Init()
    --init ProcessOverWatch cnes
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 05 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	local ke_questInteract = ml_element:create( "QuestInteract", c_questinteract, e_questinteract, 10 )
    self:add( ke_questInteract, self.process_elements)
	
	local ke_questAtInteract = ml_element:create( "QuestAtInteract", c_atinteract, e_atinteract, 10 )
    self:add( ke_questAtInteract, self.overwatch_elements)
	
	local ke_questComplete = ml_element:create( "QuestComplete", c_questcomplete, e_questcomplete, 15 )
    self:add( ke_questComplete, self.process_elements)
	
	local ke_questHandover = ml_element:create( "QuestHandover", c_questhandover, e_questhandover, 15 )
    self:add( ke_questHandover, self.process_elements)
	
	local ke_inDialog = ml_element:create( "QuestInDialog", c_indialog, e_indialog, 95 )
    self:add( ke_inDialog, self.process_elements)
	
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


function ffxiv_quest_interact:Init()
    --init ProcessOverWatch cnes
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 05 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	local ke_questInteract = ml_element:create( "QuestInteract", c_questinteract, e_questinteract, 10 )
    self:add( ke_questInteract, self.process_elements)
	
	local ke_questAtInteract = ml_element:create( "QuestAtInteract", c_atinteract, e_atinteract, 10 )
    self:add( ke_questAtInteract, self.overwatch_elements)
	
	local ke_questHandover = ml_element:create( "QuestHandover", c_questhandover, e_questhandover, 15 )
    self:add( ke_questHandover, self.process_elements)
	
	local ke_inDialog = ml_element:create( "QuestInDialog", c_indialog, e_indialog, 95 )
    self:add( ke_inDialog, self.process_elements)
	
	--local ke_questYesNo = ml_element:create( "QuestYesNo", c_questyesno, e_questyesno, 100 )
    --self:add( ke_questYesNo, self.overwatch_elements)
	
	--local ke_questIsLoading = ml_element:create( "QuestIsLoading", c_questisloading, e_questisloading, 105 )
    --self:add( ke_questIsLoading, self.process_elements)

	self.task_complete_eval = quest_step_complete_eval
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
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 15 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	local ke_questKill = ml_element:create( "QuestKill", c_questkill, e_questkill, 20 )
    self:add( ke_questKill, self.process_elements)
	
	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

function ffxiv_quest_kill:task_complete_eval()
	--if(self.params["nonquestobjective"]) then
		if((not self.params["killcount"] and self.killCount == 1) or
			(self.params["killcount"] == self.killCount))
		then
			Settings.FFXIVMINION.questKillCount = nil
			return true
		end
	--else
		--d("test1")
		--d(ml_task_hub:ThisTask().currentObjectiveIndex)
		--d("test2")
		--d(ffxiv_task_quest.currentQuest:currentObjectiveIndex())
		--d(ml_task_hub:ThisTask().currentObjectiveIndex ~= ffxiv_task_quest.currentQuest:currentObjectiveIndex())
	--	return 	ffxiv_task_quest.currentQuest:isComplete() or 
	--			ml_task_hub:ThisTask():ParentTask().currentObjectiveIndex ~= ffxiv_task_quest.currentQuest:currentObjectiveIndex()
	--end
	
	return false
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
	
	local ke_questPriorityKill = ml_element:create( "QuestPriorityKill", c_questprioritykill, e_questprioritykill, 20 )
    self:add( ke_questPriorityKill, self.overwatch_elements)
	
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 15 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

function ffxiv_quest_dutykill:task_complete_eval()
	local mapid = self.params["mapid"]
	return Player.localmapid ~= mapid
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
	
	if (distance <= 1.0) then
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

function ffxiv_quest_useitem:Init()
    --init ProcessOverWatch cnes
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 15 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	local ke_questUseItem = ml_element:create( "QuestUseItem", c_questuseitem, e_questuseitem, 10 )
    self:add( ke_questUseItem, self.process_elements)

	self.task_complete_eval = quest_step_complete_eval
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

function ffxiv_quest_useaction:Init()
    --init ProcessOverWatch cnes
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 20 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	local ke_moveToActionRange = ml_element:create( "QuestMoveToActionRange", c_questmovetoactionrange, e_questmovetoactionrange, 15 )
	self:add( ke_moveToActionRange, self.process_elements)
	
	local ke_questUseAction = ml_element:create( "QuestUseAction", c_questuseaction, e_questuseaction, 10 )
    self:add( ke_questUseAction, self.process_elements)

	self.task_complete_eval = quest_step_complete_eval
	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

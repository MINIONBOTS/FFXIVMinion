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
	newinst.profileData = {}
	newinst.quest = nil
	newinst.started = false
	newinst.startTimer = 0
	newinst.questCompleted = false
    
    return newinst
end

function ffxiv_quest_task:task_complete_eval()
	return self.questCompleted
end

function ffxiv_quest_task:task_complete_execute()
	ffxiv_task_quest.completedQuestIDs[self.quest.id] = true
	self.completed = true
end

function ffxiv_quest_task:Init()
    --init ProcessOverWatch cnes
    local ke_nextQuestStep = ml_element:create( "NextQuestStep", c_nextqueststep, e_nextqueststep, 15 )
    self:add( ke_nextQuestStep, self.process_elements)
	
    --local ke_useAetheryte = ml_element:create( "UseAetheryte", c_useaetheryte, e_useaetheryte, 25 )
    --self:add( ke_useAetheryte, self.process_elements)
	
	--needs a timer to stop it from restarting due to latency for quest data change after accepting
	local ke_questCanStart = ml_element:create( "QuestCanStart", c_questcanstart, e_questcanstart, 20 )
    self:add( ke_questCanStart, self.process_elements)
	
	local ke_questIsComplete = ml_element:create( "QuestIsComplete", c_questiscomplete, e_questiscomplete, 20 )
    self:add( ke_questIsComplete, self.process_elements)
	
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
	
	self.task_complete_eval = quest_step_complete_eval
	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
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
	
	self.task_complete_eval = quest_step_complete_eval
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

	self.task_complete_eval = quest_step_complete_eval
	self.task_complete_execute = quest_step_complete_execute
	self:AddTaskCheckCEs()
end

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
	return 	(not self.params["killcount"] and self.killCount == 1) or
			(self.params["killcount"] == self.killCount)
end
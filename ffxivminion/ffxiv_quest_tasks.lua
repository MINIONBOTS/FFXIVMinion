ffxiv_quest_task = inheritsFrom(ml_profile_task)
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
    newinst.currentStepIndex = 0
	newinst.profileData = {}
	newinst.quest = nil
	newinst.started = false
    
    return newinst
end

c_nextqueststep = inheritsFrom( ml_cause )
e_nextqueststep = inheritsFrom( ml_effect )
function c_nextqueststep:evaluate()
	local self = ml_task_hub:CurrentTask()
	
	if (not ml_task_hub:CurrentTask().quest:isStarted() or
		ml_task_hub:CurrentTask().quest:isCompleted())
	then
		return false
	end
	
	local stepindex = Quest:GetQuestCurrentStep(ml_task_hub:CurrentTask().quest.id)
    if (stepindex ~= ml_task_hub:CurrentTask().currentStepIndex) then
		e_nextqueststep.stepindex = stepindex
		return true
	end
	
	return false
end
function e_nextqueststep:execute()
	ml_task_hub:CurrentTask().currentStepIndex = e_nextqueststep.stepindex
	local task = ml_task_hub:CurrentTask().quest:GetStepTask(ml_task_hub:CurrentTask().currentStepIndex)
	if (ValidTable(task)) then
		ml_task_hub:CurrentTask():AddSubTask(task)
	end
end


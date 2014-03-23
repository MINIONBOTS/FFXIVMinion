ml_profile_task = inheritsFrom(ml_task)
ml_profile_task.name = "LT_PROFILE"

function ml_profile_task.Create()
    local newinst = inheritsFrom(ml_profile_task)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "LT_PROFILE"
    
    newinst.currentStep = {}
	newinst.currentStepCompleted = true
    newinst.currentStepIndex = 0
	newinst.profileData = {}
    
    return newinst
end

function ml_profile_task:Process()
    --check process cnes first
    if (TableSize(self.process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(self.process_elements)
		if (self:superClass() and TableSize(self:superClass().process_elements) > 0) then
			ml_cne_hub.eval_elements(self:superClass().process_elements)
		end
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
	end
    
    --then load the next step task and pass it control
	if (not self:hasCompleted()) then
        self:NextStep()
        self:CreateStepTask()
	end
    
    return false
end

function ml_profile_task:NextStep()
    if (ValidTable(self.profileData) and not self:hasCompleted()) then
        local stepData = self.profileData[self.currentStepIndex + 1]
        if (ValidTable(stepData)) then
            self.currentStepIndex = self.currentStepIndex + 1
            self.currentStepData = stepData
        else
            self.completed = true
        end
    end
end

function ml_profile_task:CreateStepTask()
    if (ValidTable(self.currentStepData) and not self:hasCompleted()) then
        local stepTask = findfunction(self.currentStepData.taskFunction)()
        if (ValidTable(stepTask)) then
            table_merge(self.currentStepData, stepTask.params)
            self:AddSubTask(stepTask)
        end
    end
end
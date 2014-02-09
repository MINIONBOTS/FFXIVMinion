-- ml_profile_task.lua contains functionality for iterating through a formatted profile
-- in the following series of steps:
-- 1: Get next step table
-- 2: Create new task using task string from profile
-- 3: Set the appropriate parameter data on the new task
-- 4: Add the new task and pass control to it
-- 5: Wait for the new task to be complete

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
    
    --step data
    newinst.currentStep = {}
	newinst.currentStepCompleted = true
    newinst.currentStepIndex = 0
    
    --profile data
    newinst.profileData = {}
    newinst.profilePath = ""
    newinst.profileCompleted = false
    
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
    if (not self.profileCompleted) then
        self:NextStep()
        self:CreateStepTask()
    else
        d("Profile Completed - Stopping task execution")
        ml_task_hub.ToggleRun()
    end
    
    return false
end

function ml_profile_task:LoadProfile(profilePath)
    if (profilePath ~= "" and file_exists(profilePath)) then
        self.profileData = persistence.load(profilePath)
        local luaPath = profilePath:sub(1,profilePath:find(".info")).."lua"
        if (file_exists(luaPath)) then
            dofile(luaPath)
        end
    end
end

function ml_profile_task:NextStep()
    if (ValidTable(self.profileData) and not self.profileCompleted) then
        local stepData = self.profileData[self.currentStepIndex + 1]
        if (ValidTable(stepData)) then
            self.currentStepIndex = self.currentStepIndex + 1
            self.currentStepData = stepData
        else
            self.profileCompleted = true
        end
    end
end

function ml_profile_task:CreateStepTask()
    if (ValidTable(self.currentStepData) and not self.profileCompleted) then
        local stepTask = findfunction(self.currentStepData.taskFunction)()
        if (ValidTable(stepTask)) then
            table_merge(self.currentStepData, stepTask.params)
            self:AddSubTask(stepTask)
        end
    end
end
-- A task should be created for any modularly separable behavior (ie: MoveToPosition)
-- It should not be created simply for calculating data (ie: GetTarget)
-- For a regularly repeated calculation create a global function in ffxiv_helpers.lua

ml_task = inheritsFrom(nil)

ml_task.name = "task_base"
ml_task.valid = true
ml_task.completed = false
ml_task.subtask = nil
ml_task.auxiliary = false
ml_task.process_elements = {}
ml_task.overwatch_elements = {}
ml_task.breakUpdate = false
ml_task.delayTime = 0
ml_task.delayTimer = 0

-- These functions are NOT overwritten in derived tasks

function ml_task:Terminate()
	ml_debug(self.name.."->Terminate()")
    self:DeleteSubTasks()
    self:OnTerminate()
	self.completed = true
end

function ml_task:isValid()
	return self.valid
end

function ml_task:hasCompleted()
	return self.completed
end

function ml_task:AddSubTask(task)
    ml_debug(self.name.."->AddSubTask("..task.name..")")
    self.subtask = task
	self.subtask:Init()
end

function ml_task:DeleteSubTasks()
	ml_debug(self.name.."->DeleteSubTasks")
    if (self.subtask ~= nil) then
        self.subtask = nil
    end
end

function ml_task:ParentTask()
    if (ml_task_hub.prevQueueId ~= nil) then
		local task = ml_task_hub.queues[ml_task_hub.prevQueueId].rootTask
		local currTask = nil
		while(task ~= nil) do
			currTask = task
			task = task.subtask
            if task == self then
                return currTask
            end
		end
		
		return nil
	end
end

function ml_task:Update()
	ml_debug(self.name.."->Update()")
    ml_task_hub.thisTask = self
    local continueUpdate = true
    while (continueUpdate) do
        if (not self:isValid()) then
			ml_debug(self.name.." has failed")
            self:DeleteSubTasks()
            return TS_FAILED
        end
        if ( self:hasCompleted() ) then
			if(TimeSince(self.delayTime) > self.delayTimer) then
				ml_debug(self.name.." has succeeded")
				self:DeleteSubTasks()
				return TS_SUCCEEDED
			end
        end
        local taskRet = nil
		
		local currentSubtaskName = nil
		if (self.subtask ~= nil) then
			currentSubtaskName = self.subtask.name
		end
		
		if(self:ProcessOverWatch()) then
			ml_debug(self.name.."->ProcessOverWatch executed an effect, breaking loop")
			--process overwatch element requested to break update loop
			--only delete subtask if we didn't just add it via our overwatch cne
			if (self.subtask ~= nil and (currentSubtaskName ~= nil or self.subtask.name == currentSubtaskName)) then
				self:DeleteSubTasks()
			end
			break
		end
		
        if ( self.subtask ~= nil ) then
			ml_debug(self.name.." sending update to subtask "..self.subtask.name)
            taskRet = self.subtask:Update()
			--d("taskRet "..tostring(taskRet))
            if ( taskRet ~= TS_PROGRESSING ) then
                continueUpdate = self:OnSubTaskReturn(ret)
                self:DeleteSubTasks()
            else
                continueUpdate = false
            end
        else
			ml_debug(self.name.."->Process()")
			gFFXIVMinionTask = self.name
			if(TimeSince(self.delayTime) > self.delayTimer) then
				continueUpdate = self:Process()
			else
				ml_debug("Delaying Process for "..tostring(self.delayTimer - (ml_global_information.Now - self.delayTime)).."ms")
				continueUpdate = false
			end
        end
    end
	ml_debug(self.name.."->Update() returning")
    return TS_PROGRESSING
end

function ml_task:IsAuxiliary()
    return self.auxiliary
end

function ml_task:Process()
    if (TableSize(self.process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(self.process_elements)

		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end

--ProcessOverWatch checks the game state for any unanticipated changes and queues
--appropriate subtasks if it detects the need for immediate behavior changes
function ml_task:ProcessOverWatch()
    if (TableSize(self.overwatch_elements) > 0) then
		ml_debug(self.name.."->ProcessOverWatch()")
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(self.overwatch_elements)

		ml_cne_hub.queue_to_execute()
		return ml_cne_hub.execute()
	end
end

function ml_task:SetDelay(delayTimer)
	if(	type(delayTimer) == "number" and
		delayTimer > 0)
	then
		self.delayTime = ml_global_information.Now
		self.delayTimer = delayTimer
	else
		ml_error("Invalid delaytimer input")
	end
end

--These functions ARE overwritten in derived tasks

-- Place all element init for the element lists here, it will be called when the task is added
function ml_task:Init()

end

-- Each task calculates its own priority by checking the game state
-- This will allow for dynamic priorities
function ml_task:GetPriority()
	
end

-- Called when a task is suppressed
function ml_task:OnSleep()

end

-- Called when task is terminated before completion
function ml_task:OnTerminate()

end

-- Called to check if a task can be terminated early
function ml_task:IsGoodToAbort()

end

function ml_task:add( element, elementList )
	ml_debug ( "adding element " .. tostring( element.name ) )
	if ( element ~= nil and element.isa ~= nil and element:isa( ml_element ) ) then
		table.insert( elementList, element )
	else
		ml_error( "invalid element, not added" )
	end
end

function ml_task:OnSubTaskReturn()

end

--These functions are used by the cne system to determine when a task should be considered
--completed or failed...the completion check MUST be filled out for every task

function ml_task:task_complete_eval()
    return false
end

function ml_task:task_complete_execute()
    self.completed = true
end

function ml_task:task_fail_eval()
    return false
end

function ml_task:task_fail_execute()
    self.completed = true
end

function ml_task:AddTaskCheckCEs()
    --Add complete check
    local c_complete = inheritsFrom(ml_cause)
    function c_complete:evaluate() return ml_task_hub:CurrentTask():task_complete_eval() end
    
    local e_complete = inheritsFrom(ml_effect)
    function e_complete:execute() ml_task_hub:CurrentTask():task_complete_execute() end

    local ke_complete = ml_element:create( "TaskComplete", c_complete, e_complete, ml_effect.priorities.interrupt )
	self:add( ke_complete, self.process_elements)
    
    --Add fail check
    local c_fail = inheritsFrom(ml_cause)
    function c_fail:evaluate() return ml_task_hub:CurrentTask():task_fail_eval() end
    
    local e_fail = inheritsFrom(ml_effect)
    function e_fail:execute() ml_task_hub:CurrentTask():task_fail_execute() end

    local ke_fail = ml_element:create( "TaskFail", c_fail, e_fail, ml_effect.priorities.interrupt )
	self:add( ke_fail, self.process_elements)
end

function ml_task.Create()
	local newinst = inheritsFrom( ml_task )
    newinst.name = ""
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    return newinst
end

function ml_task:UIInit()
	return true
end

function ml_task:RegisterDebug()
    
end

function ml_task:ShowDebugWindow()
    if ( self.DebugWindowCreated == nil ) then
        ml_debug( "Opening Queue Debug Window" )
        GUI_NewWindow( self.name, 140, 10, 100, 50 + (TableSize(self.process_elements) + TableSize(self.overwatch_elements)) * 18 )
        
        if (TableSize(self.overwatch_elements) > 0) then
            for _, elem in pairs(self.overwatch_elements) do
                GUI_NewButton( self.name, elem.name , self.name .."::" .. elem.name )
            end
        end

        if (TableSize(self.process_elements) > 0) then
            for _, elem in pairs(self.process_elements) do
                GUI_NewButton( self.name, elem.name , self.name .."::" .. elem.name )
            end
        end
        
        GUI_SizeWindow( self.name, 100, 50 + (TableSize(self.process_elements) + TableSize(self.overwatch_elements)) * 18 )
        
        self.DebugWindowCreated  = true
    end
end
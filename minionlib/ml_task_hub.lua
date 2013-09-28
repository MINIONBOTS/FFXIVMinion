ml_task_hub = {}

QUEUE_LONG_TERM = ml_task_queue:create("LONGTERM")
QUEUE_REACTIVE = ml_task_queue:create("REACTIVE")
QUEUE_IMMEDIATE = ml_task_queue:create("IMMEDIATE")

ml_task_hub.queues = {
	QUEUE_IMMEDIATE,
	QUEUE_REACTIVE,
	QUEUE_LONG_TERM
}
ml_task_hub.prevQueueId = nil
ml_task_hub.shouldRun = false
ml_task_hub.currentTask = nil

function ml_task_hub:Add(task, queueIndex, priority)
	if( task ~= nil and queueIndex < 4 and priority < 2) then
		ml_debug("Add: "..task.name.." to queue "..tostring(queueIndex).." with priority "..tostring(priority))
		ml_task_hub.queues[queueIndex]:Add(task, priority)
	else
		ml_debug("Problem with task/queueIndex/priority")
	end
end

function ml_task_hub:IsValid()
    return ml_task_hub.prevQueueId ~= TableSize(ml_task_hub.queues)
end

function ml_task_hub:Update()
	if(ml_task_hub.shouldRun) then
		local prevQueue = nil
		if(ml_task_hub:IsValid()) then
			prevQueue = ml_task_hub.queues[prevQueueId]
		end
		local currQueueId = 0
		local didUpate = false
		for index, queue in pairs(ml_task_hub.queues)  do
			ml_task_hub:HandlePending( queue, prevQueue )
			if ( queue:HasOrders() ) then
				ml_task_hub.prevQueueId = index
				queue:Update()
				didUpdate = true
				break
			end
		end
		
		return didUpdate
	end
end

function ml_task_hub:CurrentQueue()
    return ml_task_hub.queues[ml_task_hub.prevQueueId]
end

function ml_task_hub:CurrentTask()
	if (ml_task_hub.prevQueueId ~= nil) then
		local task = ml_task_hub.queues[ml_task_hub.prevQueueId].rootTask
		local currTask = nil
		while(task ~= nil) do
			currTask = task
			task = task.subtask
		end
		
		return currTask
	end
end

function ml_task_hub:CheckForTask(task)
	if (task ~= nil) then
		for i, queue in pairs (ml_task_hub.queues) do
			if (queue.rootTask ~= nil and queue.rootTask.name == task.name or
				queue.pendingTask ~= nil and queue.pendingTask.name == task.name) then
				return true
			end
		end
	end
	
	return false
end

function ml_task_hub:PromotePending()

end

function ml_task_hub:HandlePending(currQueue, prevQueue)
	if ( currQueue:HasPending() ) then
		local promote = false
		if ( currQueue:PendingPriority() == TP_IMMEDIATE or prevQueue == nil ) then
			promote = true;
		else
			promote = prevQueue:IsGoodToAbort();
		end
		if ( promote ) then
			if ( prevQueue ~= nil ) then
				if ( currQueue == prevQueue ) then
					prevQueue:Terminate()
				--else
					--Not going to sleep the previous queue for now as I see no benefit
					--prevQueue:Sleep()
				end
			end
			currQueue:PromotePending()
		end
	end
end

function ml_task_hub:ClearQueues()
	ml_debug("Clearing all queues")
	for i = 1,3 do
		ml_task_hub.queues[i]:Delete()
		ml_task_hub.queues[i]:DeletePending()
	end
end

-- on/off switch
function ml_task_hub.ToggleRun()	
	ml_task_hub.shouldRun = not ml_task_hub.shouldRun
	-- don't reset information when we stop or else we lose debugging info
	if (shouldRun) then
		ml_global_information.Reset()
	else
		ml_global_information.Stop()
	end
	--ml_debug("Task Hub Update: "..tostring(ml_task_hub.shouldRun))	
end

function ml_task_hub:ShowDebugWindow()
	if ( self.DebugWindowCreated == nil ) then
		wt_debug( "Opening Hub Debug Window" )
		GUI_NewWindow( "ML_TASK_QUEUES", 10, 10, 100, 50 + TableSize( 3 ) * 14)

		for k, queue in pairs( ml_task_hub.queues ) do
			GUI_NewButton( "ML_TASK_QUEUES", queue.name, "ML_TASK_QUEUE" .."::" .. queue.name )
		end
		self.DebugWindowCreated  = true
	end
end

function ml_task_hub.HandleStateDebugButtons( Event, Button )
	if ( Event == "GUI.Item" ) then
		for k, v in string.gmatch( Button, "(.-)::(.+)") do
			ml_debug( "A:" .. k .. " B:" .. v )
			if ( k == "ML_TASK_QUEUES" ) then
				for queueName, queue in pairs( ml_task_hub.queues ) do
					if ( queue.name == v ) then
						queue:ShowDebugWindow()
					end
				end
			else
				for statekey, state in pairs( wt_core_controller.state_list ) do
					if ( state.name == k ) then
						for ek, elmt in pairs( state.kelement_list ) do
							if ( elmt.name == v ) then
								wt_debug( "Executing elmt:evaluate() = " .. tostring( elmt:evaluate() ) )
								wt_debug( "Executing effect" )
								elmt.effect:execute()
							end
						end
					end
				end
			end
		end
	end
end

RegisterEventHandler( "GUI_REQUEST_RUN_TOGGLE", ml_task_hub.ToggleRun )
RegisterEventHandler( "FFXIVMINION.toggle", ml_task_hub.ToggleRun )
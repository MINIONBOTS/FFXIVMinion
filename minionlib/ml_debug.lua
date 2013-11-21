ml_debug_window = {}
ml_debug_window.tickcount = 0
ml_debug_window.trueEvals = {}
ml_debug_window.lastExec = nil

function ml_debug_window.HandleInit()
	GUI_NewWindow("Debug",450,60,350,350)
    GUI_NewCheckbox("Debug", "EnableDebug", "gEnableDebug")
end

function ml_debug_window.OnUpdate( event, tickcount )
    if (tickcount - ml_debug_window.tickcount > 150) then
        ml_debug_window.tickcount = tickcount
        if (gEnableDebug == "1") then
            local prevQueueId = 3
            if (ml_task_hub.prevQueueId ~= nil) then
                prevQueueId = ml_task_hub.prevQueueId
            end
            
            local queue = ml_task_hub.queues[prevQueueId]
            if (queue.rootTask) then
                queue:ShowDebugWindow()
            elseif (queue.pendingTask) then
                queue:ShowDebugWindow()
            end
        end
    end
end

function ml_debug_window.HandleStateDebugButtons( Event, Button )
	if ( Event == "GUI.Item" ) then
		for k, v in string.gmatch( Button, "(.-)::(.+)") do
			if ( k == ml_task_hub:CurrentQueue().name) then
				for _, task in pairs( ml_task_hub:CurrentQueue():TaskList() ) do
					if (task.name == v ) then
						task:ShowDebugWindow()
					end
				end
			else
				for _, task in pairs( ml_task_hub:CurrentQueue():TaskList() ) do
					if ( k == task.name ) then
                        local list = {}
                        for i,j in pairs(task.overwatch_elements) do list[i] = j end
                        for i,j in pairs(task.process_elements) do list[i] = j end
                        
						for ek, elmt in pairs( list ) do
							if ( v == elmt.name ) then
								ml_debug( "Executing elmt:evaluate() = " .. tostring( elmt:evaluate() ) )
								ml_debug( "Executing effect" )
								elmt.effect:execute()
							end
						end
					end
				end
			end
		end
	end
end

--Not ready yet
--RegisterEventHandler( "GUI.Item", ml_debug_window.HandleStateDebugButtons )
--RegisterEventHandler("Module.Initalize",ml_debug_window.HandleInit)
--RegisterEventHandler("Gameloop.Update",ml_debug_window.OnUpdate)
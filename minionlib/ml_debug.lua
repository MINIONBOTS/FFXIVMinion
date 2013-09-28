ml_debug_window = {}

function ml_debug_window.HandleInit()	
	GUI_NewWindow("Debug",450,60,350,350)
    
    for _, queues in pairs(ml_task_hub.queues) do
        if (queue.rootTask ~= nil) then
            GUI_NewField("Debug","Root Task: ", "dRT_"..rootTask.name,queue.name );
            for memberName, memberValue in pairs(queue.rootTask) do
                if (memberName ~= "isa" and
                    memberName ~= "superClass" and
                    memberName ~= "class") 
                then
                    if (memberName == "process_elements" or memberName == "overwatch_elements") then
                        for name, element in pairs(memberValue) do
                            GUI_NewField("Debug","Eval "..name, memberValue.eval,queue.name );
                        end
                    end
                end
            end
        end
    end
end

function RecursiveTaskDisplay(task)
    
end

function ml_debug_window.OnUpdate( event, tickcount )
    GUI_Delete("Debug", "Junk")
    for _, queues in pairs(ml_task_hub.queues) do
        if (queue and queue.rootTask ~= nil) then
            GUI_NewField("Debug","Root Task: ", "dRT_"..rootTask.name,queue.name );
            for memberName, memberValue in pairs(queue.rootTask) do
                if (memberName ~= "isa" and
                    memberName ~= "superClass" and
                    memberName ~= "class") 
                then
                    if (memberName == "process_elements" or memberName == "overwatch_elements") then
                        for name, element in pairs(memberValue) do
                            GUI_NewField("Debug","Eval "..name, memberValue.eval,queue.name );
                        end
                    end
                end
            end
        end
    end
end

RegisterEventHandler("Module.Initalize",ml_debug_window.HandleInit)
RegisterEventHandler("Gameloop.Update",ml_debug_window.OnUpdate)
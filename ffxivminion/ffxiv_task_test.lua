ffxiv_task_test = inheritsFrom(ml_task)
function ffxiv_task_test.Create()
    local newinst = inheritsFrom(ffxiv_task_test)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetomap members
    newinst.name = "TEST"
   
    return newinst
end

function ffxiv_task_test:Init()
    -- The parent needs to take care of checking and updating the position of this task!!	
    --local ke_moveToGate = ml_element:create( "MoveToGate", c_movetogate, e_movetogate, 10 )
    --self:add( ke_moveToGate, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_fish.UIInit()
	GUI_NewField(ml_global_information.MainWindow.Name, "MapID:", "gTestMapID","NavTest")
	GUI_UnFoldGroup(ml_global_information.MainWindow.Name, "NavTest")
end

function ffxiv_task_test:Process()
	local mapID = tonumber(gTestMapID)
    if (mapID and mapID > 0) then
        if(Player.localMapID ~= mapID) then
            local task = ffxiv_task_movetomap.Create()
            task.destMapID = mapID
            ml_task_hub:CurrentTask():AddSubTask(task)
        end
    end
	
	if (TableSize(self.process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(self.process_elements)
		if (self:superClass() and TableSize(self:superClass().process_elements) > 0) then
			ml_cne_hub.eval_elements(self:superClass().process_elements)
		end
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end
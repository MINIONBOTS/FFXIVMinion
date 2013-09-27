ffxiv_task_grind = inheritsFrom(ml_task)
ffxiv_task_grind.name = "LT_GRIND"

function ffxiv_task_grind:Create()
    local newinst = inheritsFrom(ffxiv_task_grind)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_grind members
    newinst.name = "LT_GRIND"
    newinst.targetid = 0
    
    --this is the targeting function that will be used for the generic KillTarget task
    newinst.targetFunction = GetNearestAttackable
    
    return newinst
end

function ffxiv_task_grind:Init()
    --init ProcessOverWatch() elements
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 10 )
	self:add( ke_rest, self.overwatch_elements)
    
    local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 15 )
	self:add( ke_flee, self.overwatch_elements)

    --init Process() cnes
	local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_killtarget, e_add_killtarget, 10 )
	self:add(ke_addKillTarget, self.process_elements)
    
	local ke_addFate = ml_element:create( "AddFate", c_add_fate, e_add_fate, 15 )
	self:add(ke_addFate, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_grind:OnSleep()

end

function ffxiv_task_grind:OnTerminate()

end

function ffxiv_task_grind:IsGoodToAbort()

end

function ffxiv_task_grind.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		if ( 	k == "gDoFates" or
				k == "gFatesOnly" ) then
			Settings.FFXIVMINION[tostring(k)] = v
		end
	end
	GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

-- UI settings etc
function ffxiv_task_grind.UIInit()
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Do Fates", "gDoFates","Grind")
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Fates Only", "gFatesOnly","Grind")
	GUI_SizeWindow(ml_global_information.MainWindow.Name,250,400)
	
	if (Settings.FFXIVMINION.gDoFates == nil) then
		Settings.FFXIVMINION.gDoFates = "0"
	end
	
	if (Settings.FFXIVMINION.gFatesOnly == nil) then
		Settings.FFXIVMINION.gFatesOnly = "0"
	end
	
	gDoFates = Settings.FFXIVMINION.gDoFates
	gFatesOnly = Settings.FFXIVMINION.gFatesOnly
	
	RegisterEventHandler("GUI.Update",ffxiv_task_grind.GUIVarUpdate)
end
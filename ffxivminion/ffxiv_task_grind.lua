ffxiv_task_grind = inheritsFrom(ml_task)
ffxiv_task_grind.name = "LT_GRIND"
ffxiv_task_grind.evacPoint = {0, 0, 0}

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
    newinst.targetFunction = GetNearestGrindAttackable
    
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

function ffxiv_task_grind.SetEvacPoint()
	if (Player.onmesh) then
		ffxiv_task_grind.evacPoint = Player.pos
		Settings.FFXIVMINION.evacPoint = Player.pos
	end
end

-- UI settings etc
function ffxiv_task_grind.UIInit()
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Do Fates", "gDoFates","Grind")
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Fates Only", "gFatesOnly","Grind")
	GUI_NewNumeric(ml_global_information.MainWindow.Name, "MaxFateLvl: +", "gMaxFateLevel", "Grind")
	GUI_NewNumeric(ml_global_information.MainWindow.Name, "MinFateLvl: -", "gMinFateLevel", "Grind")
	GUI_NewButton(ml_global_information.MainWindow.Name, "SetEvacPoint", "setEvacPointEvent","Grind")
	GUI_SizeWindow(ml_global_information.MainWindow.Name,250,400)
	
	if (Settings.FFXIVMINION.gDoFates == nil) then
		Settings.FFXIVMINION.gDoFates = "0"
	end
	
	if (Settings.FFXIVMINION.gFatesOnly == nil) then
		Settings.FFXIVMINION.gFatesOnly = "0"
	end
	
	if (Settings.FFXIVMINION.gMaxFateLevel == nil) then
		Settings.FFXIVMINION.gMaxFateLevel = "5"
	end
	
	if (Settings.FFXIVMINION.gMinFateLevel == nil) then
		Settings.FFXIVMINION.gMinFateLevel = "5"
	end
	
	if (Settings.FFXIVMINION.evacPoint == nil) then
		Settings.FFXIVMINION.evacPoint = {x = 0, y = 0, z = 0}
	end
	
	gDoFates = Settings.FFXIVMINION.gDoFates
	gFatesOnly = Settings.FFXIVMINION.gFatesOnly
	gMaxFateLevel = Settings.FFXIVMINION.gMaxFateLevel
	gMinFateLevel = Settings.FFXIVMINION.gMinFateLevel
	ffxiv_task_grind.evacPoint = Settings.FFXIVMINION.evacPoint
	
	RegisterEventHandler("GUI.Update",ffxiv_task_grind.GUIVarUpdate)
	RegisterEventHandler("setEvacPointEvent",ffxiv_task_grind.SetEvacPoint)
end
ffxiv_crafting_goldsmith = inheritsFrom(ml_task)

function ffxiv_crafting_goldsmith.Create()
    local newinst = inheritsFrom(ffxiv_crafting_goldsmith)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_crafting_goldsmith members
    newinst.name = "GOLDSMITH"
    newinst.targetid = 0
    newinst.range = 3
	
    return newinst
end

function ffxiv_crafting_goldsmith:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_crafting_goldsmith:OnSleep()

end

function ffxiv_crafting_goldsmith:OnTerminate()

end

function ffxiv_crafting_goldsmith:IsGoodToAbort()

end

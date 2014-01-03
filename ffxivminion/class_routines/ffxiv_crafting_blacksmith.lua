ffxiv_crafting_blacksmith = inheritsFrom(ml_task)

function ffxiv_crafting_blacksmith.Create()
    local newinst = inheritsFrom(ffxiv_crafting_blacksmith)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_crafting_blacksmith members
    newinst.name = "BLACKSMITH"
    newinst.targetid = 0
    newinst.range = 3
	
    return newinst
end

function ffxiv_crafting_blacksmith:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_crafting_blacksmith:OnSleep()

end

function ffxiv_crafting_blacksmith:OnTerminate()

end

function ffxiv_crafting_blacksmith:IsGoodToAbort()

end

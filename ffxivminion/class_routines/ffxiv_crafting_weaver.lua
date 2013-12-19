ffxiv_crafting_weaver = inheritsFrom(ml_task)

function ffxiv_crafting_weaver:Create()
    local newinst = inheritsFrom(ffxiv_crafting_weaver)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_crafting_weaver members
    newinst.name = "WEAVER"
    newinst.targetid = 0
    newinst.range = 3
	
    return newinst
end

function ffxiv_crafting_weaver:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_crafting_weaver:OnSleep()

end

function ffxiv_crafting_weaver:OnTerminate()

end

function ffxiv_crafting_weaver:IsGoodToAbort()

end

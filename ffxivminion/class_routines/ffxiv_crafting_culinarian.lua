ffxiv_crafting_culinarian = inheritsFrom(ml_task)

function ffxiv_crafting_culinarian:Create()
    local newinst = inheritsFrom(ffxiv_crafting_culinarian)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_crafting_culinarian members
    newinst.name = "CULINARIAN"
    newinst.targetid = 0
    newinst.range = 3
	
    return newinst
end

function ffxiv_crafting_culinarian:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_crafting_culinarian:OnSleep()

end

function ffxiv_crafting_culinarian:OnTerminate()

end

function ffxiv_crafting_culinarian:IsGoodToAbort()

end

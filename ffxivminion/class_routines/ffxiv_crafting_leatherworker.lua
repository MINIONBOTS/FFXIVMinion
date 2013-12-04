ffxiv_crafting_leatherworker = inheritsFrom(ml_task)

function ffxiv_crafting_leatherworker:Create()
    local newinst = inheritsFrom(ffxiv_crafting_leatherworker)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_crafting_leatherworker members
    newinst.name = "LEATHERWORKER"
    newinst.targetid = 0
    newinst.range = 3
	
    return newinst
end

function ffxiv_crafting_leatherworker:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_crafting_leatherworker:OnSleep()

end

function ffxiv_crafting_leatherworker:OnTerminate()

end

function ffxiv_crafting_leatherworker:IsGoodToAbort()

end

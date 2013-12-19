ffxiv_crafting_carpenter = inheritsFrom(ml_task)

function ffxiv_crafting_carpenter:Create()
    local newinst = inheritsFrom(ffxiv_crafting_carpenter)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_crafting_carpenter members
    newinst.name = "CARPENTER"
    newinst.targetid = 0
    newinst.range = 3
	
    return newinst
end

function ffxiv_crafting_carpenter:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_crafting_carpenter:OnSleep()

end

function ffxiv_crafting_carpenter:OnTerminate()

end

function ffxiv_crafting_carpenter:IsGoodToAbort()

end

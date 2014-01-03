ffxiv_crafting_armorer = inheritsFrom(ml_task)

function ffxiv_crafting_armorer.Create()
    local newinst = inheritsFrom(ffxiv_crafting_armorer)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_crafting_armorer members
    newinst.name = "ARMORER"
    newinst.targetid = 0
    newinst.range = 3
	
    return newinst
end

function ffxiv_crafting_armorer:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_crafting_armorer:OnSleep()

end

function ffxiv_crafting_armorer:OnTerminate()

end

function ffxiv_crafting_armorer:IsGoodToAbort()

end

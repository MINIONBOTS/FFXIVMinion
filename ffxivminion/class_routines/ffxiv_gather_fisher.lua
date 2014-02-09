ffxiv_gather_fisher = inheritsFrom(ml_task)

function ffxiv_gather_fisher.Create()
    local newinst = inheritsFrom(ffxiv_gather_fisher)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_gather_fisher members
    newinst.name = "ARCANIST"
    newinst.range = 3
	newinst.targetid = 0
    
    return newinst
end

function ffxiv_gather_fisher:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_gather_fisher:OnSleep()

end

function ffxiv_gather_fisher:OnTerminate()

end

function ffxiv_gather_fisher:IsGoodToAbort()

end

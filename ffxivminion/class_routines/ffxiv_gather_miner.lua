ffxiv_gather_miner = inheritsFrom(ml_task)

function ffxiv_gather_miner.Create()
    local newinst = inheritsFrom(ffxiv_gather_miner)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_gather_miner members
    newinst.name = "MINER"
    newinst.targetid = 0
    newinst.range = 3
	
    return newinst
end

function ffxiv_gather_miner:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_gather_miner:OnSleep()

end

function ffxiv_gather_miner:OnTerminate()

end

function ffxiv_gather_miner:IsGoodToAbort()

end

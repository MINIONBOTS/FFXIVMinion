ffxiv_gather_botanist = inheritsFrom(ml_task)

function ffxiv_gather_botanist:Create()
    local newinst = inheritsFrom(ffxiv_gather_botanist)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_gather_botanist members
    newinst.name = "BOTANIST"
    newinst.range = 3
	newinst.targetid = 0
	
    return newinst
end

function ffxiv_gather_botanist:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_gather_botanist:OnSleep()

end

function ffxiv_gather_botanist:OnTerminate()

end

function ffxiv_gather_botanist:IsGoodToAbort()

end

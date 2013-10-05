ffxiv_combat_bard = inheritsFrom(ml_task)
ffxiv_combat_bard.range = 3

function ffxiv_combat_bard:Create()
    local newinst = inheritsFrom(ffxiv_combat_bard)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_bard members
    newinst.name = "BARD"
    newinst.targetid = 0
	newinst.range = 3
    
    return newinst
end

function ffxiv_combat_bard:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_bard:OnSleep()

end

function ffxiv_combat_bard:OnTerminate()

end

function ffxiv_combat_bard:IsGoodToAbort()

end

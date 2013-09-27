ffxiv_combat_arcanist = inheritsFrom(ml_task)
ffxiv_combat_arcanist.range = 25

function ffxiv_combat_arcanist:Create()
    local newinst = inheritsFrom(ffxiv_combat_arcanist)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_arcanist members
    newinst.name = "ARCANIST"
    newinst.targetid = 0
    
    return newinst
end

function ffxiv_combat_arcanist:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_arcanist:OnSleep()

end

function ffxiv_combat_arcanist:OnTerminate()

end

function ffxiv_combat_arcanist:IsGoodToAbort()

end

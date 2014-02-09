ffxiv_combat_monk = inheritsFrom(ml_task)
ffxiv_combat_monk.range = 2

function ffxiv_combat_monk.Create()
    local newinst = inheritsFrom(ffxiv_combat_monk)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_monk members
    newinst.name = "MONK"
    newinst.targetid = 0
	newinst.range = 2
    
    return newinst
end

function ffxiv_combat_monk:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_monk:OnSleep()

end

function ffxiv_combat_monk:OnTerminate()

end

function ffxiv_combat_monk:IsGoodToAbort()

end

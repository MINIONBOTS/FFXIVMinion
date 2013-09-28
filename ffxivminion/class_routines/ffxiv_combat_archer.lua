ffxiv_combat_archer = inheritsFrom(ml_task)
ffxiv_combat_archer.range = 25

function ffxiv_combat_archer:Create()
    local newinst = inheritsFrom(ffxiv_combat_archer)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_archer members
    newinst.name = "ARCHER"
    newinst.targetid = 0
	newinst.range = 25
    
    return newinst
end

function ffxiv_combat_archer:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_archer:OnSleep()

end

function ffxiv_combat_archer:OnTerminate()

end

function ffxiv_combat_archer:IsGoodToAbort()

end

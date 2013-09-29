ffxiv_combat_gladiator = inheritsFrom(ml_task)
ffxiv_combat_gladiator.range = 3

function ffxiv_combat_gladiator:Create()
    local newinst = inheritsFrom(ffxiv_combat_gladiator)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_gladiator members
    newinst.name = "GLADIATOR"
    newinst.targetid = 0
	newinst.range = 3
    
    return newinst
end

function ffxiv_combat_gladiator:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_gladiator:OnSleep()

end

function ffxiv_combat_gladiator:OnTerminate()

end

function ffxiv_combat_gladiator:IsGoodToAbort()

end

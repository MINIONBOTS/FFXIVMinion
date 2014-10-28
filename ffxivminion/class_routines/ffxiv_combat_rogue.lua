ffxiv_combat_rogue = inheritsFrom(ml_task)
ffxiv_combat_rogue.range = 2

function ffxiv_combat_rogue.Create()
    local newinst = inheritsFrom(ffxiv_combat_rogue)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_rogue members
    newinst.name = "ROGUE"
    newinst.targetid = 0
	newinst.range = 2
    
    return newinst
end

function ffxiv_combat_rogue:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_rogue:OnSleep()

end

function ffxiv_combat_rogue:OnTerminate()

end

function ffxiv_combat_rogue:IsGoodToAbort()

end

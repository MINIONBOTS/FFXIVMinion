ffxiv_combat_warrior = inheritsFrom(ml_task)
ffxiv_combat_warrior.range = 2

function ffxiv_combat_warrior:Create()
    local newinst = inheritsFrom(ffxiv_combat_warrior)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_warrior members
    newinst.name = "WARRIOR"
    newinst.targetid = 0
	newinst.range = 2
    
    return newinst
end

function ffxiv_combat_warrior:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_warrior:OnSleep()

end

function ffxiv_combat_warrior:OnTerminate()

end

function ffxiv_combat_warrior:IsGoodToAbort()

end

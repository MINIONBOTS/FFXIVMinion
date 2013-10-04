ffxiv_combat_dragoon = inheritsFrom(ml_task)
ffxiv_combat_dragoon.range = 3

function ffxiv_combat_dragoon:Create()
    local newinst = inheritsFrom(ffxiv_combat_dragoon)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_dragoon members
    newinst.name = "DRAGOON"
    newinst.targetid = 0
	newinst.range = 3
    
    return newinst
end

function ffxiv_combat_dragoon:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_dragoon:OnSleep()

end

function ffxiv_combat_dragoon:OnTerminate()

end

function ffxiv_combat_dragoon:IsGoodToAbort()

end

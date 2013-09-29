ffxiv_combat_thaumaturge = inheritsFrom(ml_task)
ffxiv_combat_thaumaturge.range = 24

function ffxiv_combat_thaumaturge:Create()
    local newinst = inheritsFrom(ffxiv_combat_thaumaturge)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_thaumaturge members
    newinst.name = "THAUMATURGE"
    newinst.targetid = 0
	newinst.range = 24
    
    return newinst
end

function ffxiv_combat_thaumaturge:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_thaumaturge:OnSleep()

end

function ffxiv_combat_thaumaturge:OnTerminate()

end

function ffxiv_combat_thaumaturge:IsGoodToAbort()

end

ffxiv_combat_scholer = inheritsFrom(ml_task)
ffxiv_combat_scholer.range = 24

function ffxiv_combat_scholer:Create()
    local newinst = inheritsFrom(ffxiv_combat_scholer)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_scholer members
    newinst.name = "SCHOLER"
    newinst.targetid = 0
	newinst.range = 24
    
    return newinst
end

function ffxiv_combat_scholer:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_scholer:OnSleep()

end

function ffxiv_combat_scholer:OnTerminate()

end

function ffxiv_combat_scholer:IsGoodToAbort()

end

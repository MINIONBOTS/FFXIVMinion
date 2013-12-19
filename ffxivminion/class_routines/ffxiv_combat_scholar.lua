ffxiv_combat_scholar = inheritsFrom(ml_task)
ffxiv_combat_scholar.range = 24

function ffxiv_combat_scholar:Create()
    local newinst = inheritsFrom(ffxiv_combat_scholar)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_scholar members
    newinst.name = "SCHOLER"
    newinst.targetid = 0
	newinst.range = 24
    
    return newinst
end

function ffxiv_combat_scholar:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_scholar:OnSleep()

end

function ffxiv_combat_scholar:OnTerminate()

end

function ffxiv_combat_scholar:IsGoodToAbort()

end

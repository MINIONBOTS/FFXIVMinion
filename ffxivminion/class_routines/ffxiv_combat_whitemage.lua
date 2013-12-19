ffxiv_combat_whitemage = inheritsFrom(ml_task)
ffxiv_combat_whitemage.range = 24

function ffxiv_combat_whitemage:Create()
    local newinst = inheritsFrom(ffxiv_combat_whitemage)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_whitemage members
    newinst.name = "WHITEMAGE"
    newinst.targetid = 0
	newinst.range = 24
    
    return newinst
end

function ffxiv_combat_whitemage:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_whitemage:OnSleep()

end

function ffxiv_combat_whitemage:OnTerminate()

end

function ffxiv_combat_whitemage:IsGoodToAbort()

end

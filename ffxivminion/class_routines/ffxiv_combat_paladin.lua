ffxiv_combat_paladin = inheritsFrom(ml_task)
ffxiv_combat_paladin.range = 2

function ffxiv_combat_paladin.Create()
    local newinst = inheritsFrom(ffxiv_combat_paladin)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_paladin members
    newinst.name = "PALADIN"
    newinst.targetid = 0
	newinst.range = 2
    
    return newinst
end

function ffxiv_combat_paladin:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_paladin:OnSleep()

end

function ffxiv_combat_paladin:OnTerminate()

end

function ffxiv_combat_paladin:IsGoodToAbort()

end

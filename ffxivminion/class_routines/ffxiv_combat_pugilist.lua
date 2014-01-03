ffxiv_combat_pugilist = inheritsFrom(ml_task)
ffxiv_combat_pugilist.range = 2

function ffxiv_combat_pugilist.Create()
    local newinst = inheritsFrom(ffxiv_combat_pugilist)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_pugilist members
    newinst.name = "PUGILIST"
    newinst.targetid = 0
	newinst.range = 2
    
    return newinst
end

function ffxiv_combat_pugilist:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_pugilist:OnSleep()

end

function ffxiv_combat_pugilist:OnTerminate()

end

function ffxiv_combat_pugilist:IsGoodToAbort()

end

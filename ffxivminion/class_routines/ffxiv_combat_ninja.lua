ffxiv_combat_ninja = inheritsFrom(ml_task)
ffxiv_combat_ninja.range = 2

function ffxiv_combat_ninja.Create()
    local newinst = inheritsFrom(ffxiv_combat_ninja)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_ninja members
    newinst.name = "NINJA"
    newinst.targetid = 0
	newinst.range = 2
    
    return newinst
end

function ffxiv_combat_ninja:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_ninja:OnSleep()

end

function ffxiv_combat_ninja:OnTerminate()

end

function ffxiv_combat_ninja:IsGoodToAbort()

end

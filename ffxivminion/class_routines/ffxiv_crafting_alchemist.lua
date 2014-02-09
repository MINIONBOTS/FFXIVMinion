ffxiv_crafting_alchemist = inheritsFrom(ml_task)

function ffxiv_crafting_alchemist.Create()
    local newinst = inheritsFrom(ffxiv_crafting_alchemist)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_crafting_alchemist members
    newinst.name = "ALCHEMIST"
    newinst.targetid = 0
    newinst.range = 3
	
    return newinst
end

function ffxiv_crafting_alchemist:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_crafting_alchemist:OnSleep()

end

function ffxiv_crafting_alchemist:OnTerminate()

end

function ffxiv_crafting_alchemist:IsGoodToAbort()

end

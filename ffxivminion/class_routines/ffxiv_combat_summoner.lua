ffxiv_combat_summoner = inheritsFrom(ml_task)
ffxiv_combat_summoner.range = 24

function ffxiv_combat_summoner.Create()
    local newinst = inheritsFrom(ffxiv_combat_summoner)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_summoner members
    newinst.name = "SUMMONER"
    newinst.targetid = 0
	newinst.range = 24
    
    return newinst
end

function ffxiv_combat_summoner:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_summoner:OnSleep()

end

function ffxiv_combat_summoner:OnTerminate()

end

function ffxiv_combat_summoner:IsGoodToAbort()

end

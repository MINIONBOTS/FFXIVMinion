ffxiv_combat_gladiator = inheritsFrom(ml_task)
ffxiv_combat_gladiator.range = 2

function ffxiv_combat_gladiator:Create()
    local newinst = inheritsFrom(ffxiv_combat_gladiator)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_gladiator members
    newinst.name = "GLADIATOR"
    newinst.targetid = 0
	newinst.range = 2
    
    return newinst
end

c_fastblade = inheritsFrom( ml_cause )
e_fastblade = inheritsFrom( ml_effect )
function c_fastblade:evaluate()
    --this is the beginning of a combo so only use it if we are starting a new rotation
    if(ml_task_hub:CurrentTask().newRotation) then
        if(ActionList:CanCast(FFXIVMINION.SKILLS.TRUETHRUST,ml_task_hub:CurrentTask().targetid)) then
            return true
        end
    end
    
    return false
end
function e_fastblade:execute()
	local skill = ActionList:Get(FFXIVMINION.SKILLS.TRUETHRUST, 1)
	if (skill ~= nil) then
		if ( skill.cd == 0) then
			skill:Cast(ml_task_hub:CurrentTask().targetid)
			ml_task_hub:CurrentTask().prevSkillID = FFXIVMINION.SKILLS.TRUETHRUST
			ml_task_hub:CurrentTask().newRotation = false
		end
	end
end

function ffxiv_combat_gladiator:Init()
    --init cnes
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_gladiator:OnSleep()

end

function ffxiv_combat_gladiator:OnTerminate()

end

function ffxiv_combat_gladiator:IsGoodToAbort()

end

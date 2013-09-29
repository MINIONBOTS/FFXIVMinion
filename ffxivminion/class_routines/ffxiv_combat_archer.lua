ffxiv_combat_archer = inheritsFrom(ml_task)
ffxiv_combat_archer.range = 24

function ffxiv_combat_archer:Create()
    local newinst = inheritsFrom(ffxiv_combat_archer)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_archer members
    newinst.name = "ARCHER"
    newinst.targetid = 0
	newinst.range = 24
	newinst.newRotation = true
    
    return newinst
end

--process_elements cne list for each skill to determine the optimal choice
c_heavyshot = inheritsFrom( ml_cause )
e_heavyshot = inheritsFrom( ml_effect )
function c_heavyshot:evaluate()
    --this is the beginning of a combo so only use it if we are starting a new rotation
    if(ml_task_hub:CurrentTask().newRotation) then
        if(Skillbar:CanCast(97)) then
            return true
        end
    end
    
    return false
end
function e_heavyshot:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub:CurrentTask().targetid then
			local skill = Skillbar:Get(97)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast()
                    ml_task_hub:CurrentTask().prevSkillID = 97
                end
            end
		end
	end
end

--process_elements cne list for each skill to determine the optimal choice
c_straightshot = inheritsFrom( ml_cause )
e_straightshot = inheritsFrom( ml_effect )
function c_straightshot:evaluate()
	if (not HasBuff(Player, 130)) then
		return true
	end
	
	return false
end

function e_straightshot:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub:CurrentTask().targetid then
			local skill = Skillbar:Get(98)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast()
                    ml_task_hub:CurrentTask().prevSkillID = 98
                end
            end
		end
	end
end

function ffxiv_combat_archer:Init()
    --init cnes
	local ke_heavyshot = ml_element:create( "HeavyShot", c_heavyshot, e_heavyshot, 5 )
	self:add( ke_heavyshot, self.process_elements)
	
	local ke_straightshot = ml_element:create( "StraightShot", c_straightshot, e_straightshot, 10 )
	self:add( ke_straightshot, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_combat_archer:OnSleep()

end

function ffxiv_combat_archer:OnTerminate()

end

function ffxiv_combat_archer:IsGoodToAbort()

end

function ffxiv_combat_archer:task_complete_eval()
    local target = Player:GetTarget()
    if (target == nil or not target.alive) then
        return true
    end
    
    return false
end

function ffxiv_combat_archer:task_complete_execute()
    self.targetid = 0
    self.completed = true
end

ffxiv_combat_conjurer = inheritsFrom(ml_task)
ffxiv_combat_conjurer.name = "CONJURER"
ffxiv_combat_conjurer.range = 25

function ffxiv_combat_conjurer:Create()
    local newinst = inheritsFrom(ffxiv_combat_conjurer)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_conjurer members
    newinst.name = "CONJURER"
    newinst.targetid = 0
    newinst.range = 25
    newinst.prevSkillID = 0
    newinst.newRotation = true
    
    return newinst
end

--process_elements cne list for each skill to determine the optimal choice
c_cure = inheritsFrom( ml_cause )
e_cure = inheritsFrom( ml_effect )
function c_cure:evaluate()
    if(Player.hp.percent < 50 and Skillbar:CanCast(FFXIVMINION.SKILLS.CURE,Player.id)) then
		return true
    end
    return false
end
function e_cure:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub:CurrentTask().targetid then
			local skill = Skillbar:Get(FFXIVMINION.SKILLS.CURE)
            if (skill ~= nil) then
                if (skill.cd == 0) then
                    skill:Cast()
                end
            end
		end
	end
end

c_buffs = inheritsFrom( ml_cause )
e_buffs = inheritsFrom( ml_effect )
function c_buffs:evaluate()
    --don't use buffs etc during the middle of a combo
    if( not HasBuff(Player,FFXIVMINION.BUFFS.PROTECT)) then 
        return true
    end
    
    return false
end

function e_buffs:execute()
	local skill = Skillbar:Get(FFXIVMINION.SKILLS.PROTECT)
	if (skill ~= nil) then
		if ( skill.cd == 0) then
			skill:Cast()
		end
	end
end

c_stone = inheritsFrom( ml_cause )
e_stone = inheritsFrom( ml_effect )
function c_stone:evaluate()
	if(Skillbar:CanCast(FFXIVMINION.SKILLS.STONE,ml_task_hub:CurrentTask().targetid)) then
		return true
	end
    return false
end
function e_stone:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub.CurrentTask().targetid then
			local skill = Skillbar:Get(FFXIVMINION.SKILLS.STONE)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast()
                end
            end
		end
	end
end

c_aero = inheritsFrom( ml_cause )
e_aero = inheritsFrom( ml_effect )
function c_aero:evaluate()
	local t = ml_task_hub:CurrentTask().targetid
	if(Skillbar:CanCast(FFXIVMINION.SKILLS.AERO,t) and not HasBuffFrom(t,FFXIVMINION.BUFFS.AERO,Player.id)) then
		return true
	end
    return false
end

function e_aero:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub.CurrentTask().targetid then
			local skill = Skillbar:Get(FFXIVMINION.SKILLS.AERO)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast()
                end
            end
		end
	end
end

--add skill cnes
function ffxiv_combat_conjurer:Init()
    --init cnes
    local ke_cure = ml_element:create( "Cure", c_cure, e_cure , 50 )
	self:add( ke_cure, self.process_elements)
	
    local ke_buff = ml_element:create( "Buffs", c_buffs, e_buffs, 40 )
	self:add( ke_buff, self.process_elements)
    
    local ke_aero = ml_element:create( "Aero", c_aero, e_aero, 30 )
	self:add( ke_aero, self.process_elements)
	
	local ke_stone = ml_element:create( "Stone", c_stone, e_stone, 20)
	self:add( ke_stone, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_conjurer:task_complete_eval()
    local target = Player:GetTarget()
    if (target == nil or not target.alive) then
        return true
    end
    
    return false
end

function ffxiv_combat_conjurer:task_complete_execute()
    self.targetid = 0
    self.completed = true
end

function ffxiv_combat_conjurer:OnSleep()

end

function ffxiv_combat_conjurer:OnTerminate()

end

function ffxiv_combat_conjurer:IsGoodToAbort()

end




--temp enum vals that will be replaced by lua enums in dll
FFXIVMINION.SKILLS.STONE       		= 119
FFXIVMINION.SKILLS.CURE	            = 120
FFXIVMINION.SKILLS.AERO			    = 121
FFXIVMINION.SKILLS.CLERICSTANCE     = 122
FFXIVMINION.SKILLS.PROTECT		    = 123
FFXIVMINION.SKILLS.MEDICA	        = 124
FFXIVMINION.SKILLS.RAISE	        = 125
FFXIVMINION.SKILLS.FLUIDAURA	    = 134

FFXIVMINION.BUFFS = {}
FFXIVMINION.BUFFS.PROTECT			= 146
FFXIVMINION.BUFFS.AERO				= 143


ffxiv_combat_conjurer.skills = {
    [FFXIVMINION.SKILLS.STONE]       = {name = "Stone",    level = 1,  combo = nil},
    [FFXIVMINION.SKILLS.CURE]            = {name = "Cure",          level = 2,  combo = nil},          
    [FFXIVMINION.SKILLS.AERO]     = {name = "Aero",  level = 4,  combo = nil},
    [FFXIVMINION.SKILLS.CLERICSTANCE]       = {name = "Cleric Stance",    level = 6,  combo = nil},
    [FFXIVMINION.SKILLS.PROTECT]     = {name = "Protect",  level = 8,  combo = nil},
}
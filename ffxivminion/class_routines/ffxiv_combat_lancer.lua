ffxiv_combat_lancer = inheritsFrom(ml_task)
ffxiv_combat_lancer.name = "LANCER"
ffxiv_combat_lancer.range = 2

function ffxiv_combat_lancer:Create()
    local newinst = inheritsFrom(ffxiv_combat_lancer)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_lancer members
    newinst.name = "LANCER"
    newinst.targetid = 0
    newinst.range = 2
    newinst.prevSkillID = 0
    newinst.newRotation = true
    
    return newinst
end

--process_elements cne list for each skill to determine the optimal choice
c_truethrust = inheritsFrom( ml_cause )
e_truethrust = inheritsFrom( ml_effect )
function c_truethrust:evaluate()
    --this is the beginning of a combo so only use it if we are starting a new rotation
    if(ml_task_hub:CurrentTask().newRotation) then
        if(Skillbar:CanCast(FFXIVMINION.SKILLS.TRUETHRUST)) then
            return true
        end
    end
    
    return false
end
function e_truethrust:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub:CurrentTask().targetid then
			local skill = Skillbar:Get(FFXIVMINION.SKILLS.TRUETHRUST)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast()
                    ml_task_hub:CurrentTask().prevSkillID = FFXIVMINION.SKILLS.TRUETHRUST
                    ml_task_hub:CurrentTask().newRotation = false
                end
            end
		end
	end
end

c_feint = inheritsFrom( ml_cause )
e_feint = inheritsFrom( ml_effect )
function c_feint:evaluate()
    --don't use buffs etc during the middle of a combo
    if(ml_task_hub:CurrentTask().newRotation and ml_task_hub:CurrentTask().prevSkillID ~= FFXIVMINION.SKILLS.FEINT) then
        return true
    end
    
    return false
end
function e_feint:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub:CurrentTask().targetid then
			local skill = Skillbar:Get(FFXIVMINION.SKILLS.FEINT)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast()
                    ml_task_hub:CurrentTask().prevSkillID = FFXIVMINION.SKILLS.FEINT
                end
            end
		end
	end
end

c_vorpalthrust = inheritsFrom( ml_cause )
e_vorpalthrust = inheritsFrom( ml_effect )
function c_vorpalthrust:evaluate()
    if(not ml_task_hub:CurrentTask().newRotation and Player.level >= ffxiv_combat_lancer.skills[FFXIVMINION.SKILLS.VORPALTHRUST].level) then
        if(ml_task_hub:CurrentTask().prevSkillID == ffxiv_combat_lancer.skills[FFXIVMINION.SKILLS.VORPALTHRUST].combo) then
            if(Skillbar:CanCast(FFXIVMINION.SKILLS.VORPALTHRUST)) then
                return true
            end
        end
    end
    
    return false
end
function e_vorpalthrust:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub.CurrentTask().targetid then
			local skill = Skillbar:Get(FFXIVMINION.SKILLS.VORPALTHRUST)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast()
                    ml_task_hub.CurrentTask().prevSkillID = FFXIVMINION.SKILLS.VORPALTHRUST
                    if(Player.level < 26) then
                        ml_task_hub:CurrentTask().newRotation = true
                    end
                end
            end
		end
	end
end

c_heavythrust = inheritsFrom( ml_cause )
e_heavythrust = inheritsFrom( ml_effect )
function c_heavythrust:evaluate()
	if(IsBehind(EntityList:Get(ml_task_hub:CurrentTask().targetid)) and ml_task_hub:CurrentTask().prevSkillID ~= FFXIVMINION.SKILLS.HEAVYTHRUST) then
		if(ml_task_hub:CurrentTask().newRotation and Player.level >= ffxiv_combat_lancer.skills[FFXIVMINION.SKILLS.HEAVYTHRUST].level) then
			if(Skillbar:CanCast(FFXIVMINION.SKILLS.HEAVYTHRUST)) then
				return true
			end
		end
	end
    
    return false
end
function e_heavythrust:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub.CurrentTask().targetid then
			local skill = Skillbar:Get(FFXIVMINION.SKILLS.HEAVYTHRUST)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast()
                    ml_task_hub.CurrentTask().prevSkillID = FFXIVMINION.SKILLS.HEAVYTHRUST
                end
            end
		end
	end
end

--add skill cnes
function ffxiv_combat_lancer:Init()
    --init cnes
    local ke_truethrust = ml_element:create( "TrueThrust", c_truethrust, e_truethrust, 5 )
	self:add( ke_truethrust, self.process_elements)
	
    local ke_feint = ml_element:create( "Feint", c_feint, e_feint, 10 )
	self:add( ke_feint, self.process_elements)
    
    local ke_vorpalthrust = ml_element:create( "VorpalThrust", c_vorpalthrust, e_vorpalthrust, 5 )
	self:add( ke_vorpalthrust, self.process_elements)
	
	--local ke_heavythrust = ml_element:create( "HeavyThrust", c_heavythrust, e_heavythrust, 15)
	--self:add( ke_heavythrust, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_lancer:task_complete_eval()
    local target = Player:GetTarget()
    if (target == nil or not target.alive) then
        return true
    end
    
    return false
end

function ffxiv_combat_lancer:task_complete_execute()
    self.targetid = 0
    self.completed = true
end

function ffxiv_combat_lancer:OnSleep()

end

function ffxiv_combat_lancer:OnTerminate()

end

function ffxiv_combat_lancer:IsGoodToAbort()

end

--temp enum vals that will be replaced by lua enums in dll
FFXIVMINION.SKILLS.TRUETHRUST       = 75
FFXIVMINION.SKILLS.FEINT            = 76 
FFXIVMINION.SKILLS.VORPALTHRUST     = 78
FFXIVMINION.SKILLS.KEENFLURRY       = 77
FFXIVMINION.SKILLS.IMPULSEDRIVE     = 81
FFXIVMINION.SKILLS.LEGSWEEP         = 80
FFXIVMINION.SKILLS.HEAVYTHRUST      = 79
FFXIVMINION.SKILLS.PIERCINGTALON    = 82
FFXIVMINION.SKILLS.LIFESURGE        = 83
FFXIVMINION.SKILLS.INVIGORATE       = 84
FFXIVMINION.SKILLS.FULLTHRUST       = 85
FFXIVMINION.SKILLS.PHLEBOTOMIZE     = 86
FFXIVMINION.SKILLS.BLOODFORBLOOD    = 87
FFXIVMINION.SKILLS.DISEMBOWEL       = 88
FFXIVMINION.SKILLS.DOOMSPIKE        = 89
FFXIVMINION.SKILLS.RINGOFTHORNS     = 90
FFXIVMINION.SKILLS.CHAOSTHRUST      = 91

ffxiv_combat_lancer.skills = {
    [FFXIVMINION.SKILLS.TRUETHRUST]       = {name = "True Thrust",    level = 1,  combo = nil},
    [FFXIVMINION.SKILLS.FEINT]            = {name = "Feint",          level = 2,  combo = nil},          
    [FFXIVMINION.SKILLS.VORPALTHRUST]     = {name = "Vorpal Thrust",  level = 4,  combo = FFXIVMINION.SKILLS.TRUETHRUST},
    [FFXIVMINION.SKILLS.KEENFLURRY]       = {name = "Keen Flurry",    level = 6,  combo = nil},
    [FFXIVMINION.SKILLS.IMPULSEDRIVE]     = {name = "Impulse Drive",  level = 8,  combo = nil},
    [FFXIVMINION.SKILLS.LEGSWEEP]         = {name = "Leg Sweep",      level = 10, combo = nil},
    [FFXIVMINION.SKILLS.HEAVYTHRUST]      = {name = "Heavy Thrust",   level = 12, combo = nil},          
    [FFXIVMINION.SKILLS.PIERCINGTALON]    = {name = "Piercing Talon", level = 15, combo = nil},
    [FFXIVMINION.SKILLS.LIFESURGE]        = {name = "Life Surge",     level = 18, combo = nil},
    [FFXIVMINION.SKILLS.INVIGORATE]       = {name = "Invigorate",     level = 22, combo = nil},
    [FFXIVMINION.SKILLS.FULLTHRUST]       = {name = "Full Thrust",    level = 26, combo = FFXIVMINION.SKILLS.VORPALTHRUST},
    [FFXIVMINION.SKILLS.PHLEBOTOMIZE]     = {name = "Phlebotomize",   level = 30, combo = nil},          
    [FFXIVMINION.SKILLS.BLOODFORBLOOD]    = {name = "Blood for Blood",level = 34, combo = FFXIVMINION.SKILLS.TRUETHRUST},
    [FFXIVMINION.SKILLS.DISEMBOWEL]       = {name = "Disembowel",     level = 38, combo = FFXIVMINION.SKILLS.IMPULSEDRIVE},
    [FFXIVMINION.SKILLS.DOOMSPIKE]        = {name = "Doom Spike",     level = 42, combo = nil},
    [FFXIVMINION.SKILLS.RINGOFTHORNS]     = {name = "Ring of Thorns", level = 46, combo = FFXIVMINION.SKILLS.HEAVYTHRUST},
    [FFXIVMINION.SKILLS.CHAOSTHRUST]      = {name = "Chaos Thrust",   level = 50, combo = FFXIVMINION.SKILLS.DISEMBOWEL}
}
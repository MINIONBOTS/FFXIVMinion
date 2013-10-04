ffxiv_combat_marauder = inheritsFrom(ml_task)
ffxiv_combat_marauder.name = "MARAUDER"
ffxiv_combat_marauder.range = 3

function ffxiv_combat_marauder:Create()
    local newinst = inheritsFrom(ffxiv_combat_marauder)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_combat_marauder members
    newinst.name = "MARAUDER"
    newinst.targetid = 0
    newinst.range = 2
    newinst.prevSkillID = 0
    newinst.newRotation = true
    
    return newinst
end

--process_elements cne list for each skill to determine the optimal choice
c_heavyswing = inheritsFrom( ml_cause )
e_heavyswing = inheritsFrom( ml_effect )
function c_heavyswing:evaluate()
    --this is the beginning of a combo so only use it if we are starting a new rotation
    if(ml_task_hub:CurrentTask().newRotation) then
        if(ActionList:CanCast(FFXIVMINION.SKILLS.HEAVYSWING)) then
            return true
        end
    end
    
    return false
end
function e_heavyswing:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub:CurrentTask().targetid then
			local skill = ActionList:Get(FFXIVMINION.SKILLS.HEAVYSWING)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast(t.id)
                    ml_task_hub:CurrentTask().prevSkillID = FFXIVMINION.SKILLS.HEAVYSWING
                    ml_task_hub:CurrentTask().newRotation = false
                end
            end
		end
	end
end


c_skullsunder = inheritsFrom( ml_cause )
e_skullsunder = inheritsFrom( ml_effect )
function c_skullsunder:evaluate()
	if(IsBehind(EntityList:Get(ml_task_hub:CurrentTask().targetid)) and ml_task_hub:CurrentTask().prevSkillID ~= FFXIVMINION.SKILLS.SKULLSUNDER) then
		if(ml_task_hub:CurrentTask().newRotation and Player.level >= ffxiv_combat_marauder.skills[FFXIVMINION.SKILLS.SKULLSUNDER].level) then
			if(ActionList:CanCast(FFXIVMINION.SKILLS.SKULLSUNDER)) then
				return true
			end
		end
	end
    
    return false
end
function e_skullsunder:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub.CurrentTask().targetid then
			local skill = ActionList:Get(FFXIVMINION.SKILLS.SKULLSUNDER)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast(t.id)
                    ml_task_hub.CurrentTask().prevSkillID = FFXIVMINION.SKILLS.SKULLSUNDER
                end
            end
		end
	end
end

c_fracture = inheritsFrom( ml_cause )
e_fracture = inheritsFrom( ml_effect )
function c_fracture:evaluate()
    if(not ml_task_hub:CurrentTask().newRotation and Player.level >= ffxiv_combat_marauder.skills[FFXIVMINION.SKILLS.FRACTURE].level) then
        if(ml_task_hub:CurrentTask().prevSkillID ~= ffxiv_combat_marauder.skills[FFXIVMINION.SKILLS.FRACTURE]) then
            if(ActionList:CanCast(FFXIVMINION.SKILLS.FRACTURE)) then
                return true
            end
        end
    end
    
    return false
end
function e_fracture:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub.CurrentTask().targetid then
			local skill = ActionList:Get(FFXIVMINION.SKILLS.FRACTURE)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast(t.id)
                    ml_task_hub.CurrentTask().prevSkillID = FFXIVMINION.SKILLS.FRACTURE
                end
            end
		end
	end
end

c_overpower = inheritsFrom( ml_cause )
e_overpower = inheritsFrom( ml_effect )
function c_overpower:evaluate()
	if(IsBehind(EntityList:Get(ml_task_hub:CurrentTask().targetid)) and ml_task_hub:CurrentTask().prevSkillID ~= FFXIVMINION.SKILLS.OVERPOWER) then
		if(ml_task_hub:CurrentTask().newRotation and Player.level >= ffxiv_combat_marauder.skills[FFXIVMINION.SKILLS.OVERPOWER].level) then
			if(ActionList:CanCast(FFXIVMINION.SKILLS.OVERPOWER)) then
				return true
			end
		end
	end
    
    return false
end
function e_overpower:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub.CurrentTask().targetid then
			local skill = ActionList:Get(FFXIVMINION.SKILLS.OVERPOWER)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast(t.id)
                    ml_task_hub.CurrentTask().prevSkillID = FFXIVMINION.SKILLS.OVERPOWER
                end
            end
		end
	end
end


c_maim = inheritsFrom( ml_cause )
e_maim = inheritsFrom( ml_effect )
function c_maim:evaluate()
    if(not ml_task_hub:CurrentTask().newRotation and Player.level >= ffxiv_combat_marauder.skills[FFXIVMINION.SKILLS.MAIM].level) then
        if(ml_task_hub:CurrentTask().prevSkillID ~= ffxiv_combat_marauder.skills[FFXIVMINION.SKILLS.MAIM]) then
            if(ActionList:CanCast(FFXIVMINION.SKILLS.MAIM)) then
                return true
            end
        end
    end
    
    return false
end
function e_maim:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub.CurrentTask().targetid then
			local skill = ActionList:Get(FFXIVMINION.SKILLS.MAIM)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast(t.id)
                    ml_task_hub.CurrentTask().prevSkillID = FFXIVMINION.SKILLS.MAIM
                end
            end
		end
	end
end

c_brutalswing = inheritsFrom( ml_cause )
e_brutalswing = inheritsFrom( ml_effect )
function c_brutalswing:evaluate()
    if(not ml_task_hub:CurrentTask().newRotation and Player.level >= ffxiv_combat_marauder.skills[FFXIVMINION.SKILLS.BRUTALSWING].level) then
        if(ml_task_hub:CurrentTask().prevSkillID == ffxiv_combat_marauder.skills[FFXIVMINION.SKILLS.BRUTALSWING]) then
            if(ActionList:CanCast(FFXIVMINION.SKILLS.BRUTALSWING)) then
                return true
            end
        end
    end
    
    return false
end
function e_brutalswing:execute()
	local t = Player:GetTarget()
	if ( t ) then 
		if t.id == ml_task_hub.CurrentTask().targetid then
			local skill = ActionList:Get(FFXIVMINION.SKILLS.BRUTALSWING)
            if (skill ~= nil) then
                if ( skill.cd == 0) then
                    skill:Cast(t.id)
                    ml_task_hub.CurrentTask().prevSkillID = FFXIVMINION.SKILLS.BRUTALSWING
					if(Player.level < 35) then
                        ml_task_hub:CurrentTask().newRotation = true
                    end
					
                end
            end
		end
	end
end




--add skill cnes
function ffxiv_combat_marauder:Init()
    --init cnes
	local ke_heavyswing = ml_element:create( "HeavySwing", c_heavyswing, e_heavyswing, 5)
	self:add( ke_heavyswing, self.process_elements)
	
	local ke_skullsunder = ml_element:create( "SkullSunder", c_skullsunder, e_skullsunder, 10)
	self:add( ke_skullsunder, self.process_elements)
    
    local ke_fracture = ml_element:create( "Fracture", c_fracture, e_fracture, 15 )
	self:add( ke_fracture, self.process_elements)
	
	local ke_overpower = ml_element:create( "Overpower", c_overpower, e_overpower, 20 )
	self:add( ke_overpower, self.process_elements)
	
	local ke_maim = ml_element:create( "Maim", c_maim, e_maim, 25 )
	self:add( ke_maim, self.process_elements)
	
	local ke_brutalswing = ml_element:create( "BrutalSwing", c_brutalswing, e_brutalswing, 30 )
	self:add( ke_brutalswing, self.process_elements)
	
    
    self:AddTaskCheckCEs()
end

function ffxiv_combat_marauder:task_complete_eval()
    local target = Player:GetTarget()
    if (target == nil or not target.alive) then
        return true
    end
    
    return false
end

function ffxiv_combat_marauder:task_complete_execute()
    self.targetid = 0
    self.completed = true
end

function ffxiv_combat_marauder:OnSleep()

end

function ffxiv_combat_marauder:OnTerminate()

end

function ffxiv_combat_marauder:IsGoodToAbort()

end

--temp enum vals that will be replaced by lua enums in dll
FFXIVMINION.SKILLS.HEAVYSWING 		= 31
FFXIVMINION.SKILLS.FORESIGHT		= 32
FFXIVMINION.SKILLS.FRACTURE 		= 33
FFXIVMINION.SKILLS.BLOODBATH 		= 34
FFXIVMINION.SKILLS.SKULLSUNDER		= 35
FFXIVMINION.SKILLS.MERCYSTROKE 		= 36
FFXIVMINION.SKILLS.MAIM				= 37
FFXIVMINION.SKILLS.BERSERK 			= 38
FFXIVMINION.SKILLS.BRUTALSWING 		= 39
FFXIVMINION.SKILLS.OVERPOWER 		= 41
FFXIVMINION.SKILLS.TOMAHAWK 		= 46

ffxiv_combat_marauder.skills = {

	[FFXIVMINION.SKILLS.HEAVYSWING]       = {name = "Heavy Swing",    level = 1,  combo = nil},
	[FFXIVMINION.SKILLS.FORESIGHT]        = {name = "Foresight",      level = 2,  combo = nil},
	[FFXIVMINION.SKILLS.SKULLSUNDER]      = {name = "Skull Sunder",   level = 4,  combo = nil},
	[FFXIVMINION.SKILLS.FRACTURE]         = {name = "Fracture",       level = 6,  combo = nil},
	[FFXIVMINION.SKILLS.BLOODBATH]        = {name = "Bloodbath",      level = 8,  combo = nil},
	[FFXIVMINION.SKILLS.BRUTALSWING]      = {name = "Brutal Swing",   level = 10, combo = nil},
	[FFXIVMINION.SKILLS.OVERPOWER]        = {name = "Overpower",      level = 12, combo = nil},   
    [FFXIVMINION.SKILLS.TOMAHAWK]         = {name = "Tomahawk",    	  level = 15, combo = nil},    
	[FFXIVMINION.SKILLS.MAIM]       	  = {name = "Maim",    		  level = 18, combo = nil},
	[FFXIVMINION.SKILLS.BERSERK]       	  = {name = "Berserk",    	  level = 22, combo = nil},	
    [FFXIVMINION.SKILLS.MERCYSTROKE]      = {name = "Mercy Stroke",   level = 26, combo = nil}        

}
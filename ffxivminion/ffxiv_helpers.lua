-- This file holds global helper functions

function GetNearestGrindAttackable()
	local level = Player.level
	local el = EntityList("nearest,alive,attackable,onmesh,minLevel="..tostring(level-1)..",maxlevel="..tostring(level+1))
	if ( el ) then
		local i,e = next(el)
		if (i~=nil and e~=nil) then
			return e
		end
	end
	ml_debug("GetNearestAttackable() failed with no entity found matching params")
	return nil
end

function GetNearestFateAttackable()
    local myPos = Player.pos
    local fateID = GetClosestFateID(myPos, true, true)
    if (fateID ~= nil and fateID ~= 0) then
        local el = EntityList("nearest,alive,attackable,onmesh,fateid="..tostring(fateID))
		if ( el ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                return e
            end
        end
    end
    
	ml_debug("GetNearestFateAttackable() failed with no entity found matching params")
	return nil
end

function GetNearestAggro()
    local el = EntityList("nearest,alive,attackable,onmesh,aggro")
    if ( el ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
    
	ml_debug("GetNearestAggro() failed with no entity found matching params")
	return nil
end

function GetNearestGatherable()
	local el = EntityList("nearest,onmesh,gatherable")
	if ( el ) then
		local i,e = next(el)
		if (i~=nil and e~=nil) then
			return e
		end
	end
	ml_debug("GetNearestGatherable() failed with no entity found matching params")
	return nil
end

function HasBuff(targetid, buffID)
	local entity = EntityList:Get(targetid)
	local buffs = entity.buffs
	if (buffs ~= nil and TableSize(buffs) > 0) then
		for i, buff in pairs(buffs) do
			if (buff.id == buffID) then
				return true
			end
		end
	end
	
	return false
end

function HasBuffFrom(targetID, buffID, ownerID)
	local target = EntityList:Get(targetID)
	if (target ~= nil and target ~= {}) then
		local buffs = target.buffs
		if (buffs ~= nil and TableSize(buffs) > 0) then
			for i, buff in pairs(buffs) do
				if (buff.id == buffID and buff.ownerid == ownerID) then
					return true
				end
			end
		end
	end
end

function IsBehind(entity)
	if(entity.distance < ml_global_information.AttackRange) then
		local entityHeading = nil
		
		if (entity.pos.h < 0) then
			entityHeading = entity.pos.h + 2 * math.pi
		else
			entityHeading = entity.pos.h
		end

		--d("Entity Heading: "..tostring(entityHeading))
		
		local entityAngle = math.atan2(Player.pos.x - entity.pos.x, Player.pos.z - entity.pos.z)
		
		--d("Entity Angle: "..tostring(entityAngle))
		
		local deviation = entityAngle - entityHeading
		local absDeviation = math.abs(deviation)
		
		--d("Deviation: "..tostring(deviation))
		--d("absDeviation: "..tostring(absDeviation))
		
		local leftover = absDeviation - math.pi
		--d("Leftover: "..tostring(leftover))
		if (leftover > -(math.pi/4) and leftover < (math.pi/4))then
			return true
		end
	end
	return false
end

function GetFateByID(fateID)
	local fate = nil
	local fateList = MapObject:GetFateList()
	if (fateList ~= nil and fateList ~= {}) then
		local _, fate = next(fateList)
		while (_ ~= nil and fate ~= nil) do
			if (fate.id == fateID) then
				return fate
			end
			_, fate = next(fateList, _)
		end
	end
	
	return fate
end

function GetClosestFateID(pos, levelCheck, meshCheck)
	local fateList = MapObject:GetFateList()
	if (fateList ~= nil and fateList ~= {}) then
		local nearestFate = nil
		local nearestDistance = 99999999
		local _, fate = next(fateList)
		local level = Player.level
		while (_ ~= nil and fate ~= nil) do
			if (mm.FateBlacklist[fate.id] == nil) then
				if (not levelCheck or (levelCheck and (fate.level >= level - tonumber(gMinFateLevel) and fate.level <= level + tonumber(gMaxFateLevel)))) then
					--d("DIST TO FATE :".."ID"..tostring(fate.id).." "..tostring(NavigationManager:GetPointToMeshDistance({x=fate.x, y=fate.y, z=fate.z})) .. " ONMESH: "..tostring(NavigationManager:IsOnMesh(fate.x, fate.y, fate.z)))
					if (not meshCheck or (meshCheck and NavigationManager:GetPointToMeshDistance({x=fate.x, y=fate.y, z=fate.z})<=3)) then
						local distance = Distance3D(pos.x, pos.y, pos.z, fate.x, fate.y, fate.z)
						if (nearestFate == nil or distance < nearestDistance) then
							nearestFate = fate
							nearestDistance = distance
						end
					end
				end
			end
			_, fate = next(fateList, _)
		end
	
		if (nearestFate ~= nil) then
			return nearestFate.id
		end
	end
	
	return 0
end

function InCombatRange(targetid)
    local target = EntityList:Get(targetid)
    if (target == nil or target == {}) then
        d("InCombatRange NO TARGET")
		return false
    end
    
	local testSkills =
	{
		[FFXIV.JOBS.ARCANIST] 		= 163,
		[FFXIV.JOBS.ARCHER]			= 97,
		[FFXIV.JOBS.BARD]			= 97,
		[FFXIV.JOBS.BLACKMAGE]		= 142,
		[FFXIV.JOBS.CONJURER]		= 119,
		[FFXIV.JOBS.DRAGOON]		= 75,
		[FFXIV.JOBS.GLADIATOR] 		= 9,
		[FFXIV.JOBS.LANCER]			= 75,
		[FFXIV.JOBS.MARAUDER] 		= 31,
		[FFXIV.JOBS.MONK] 			= 53,
		[FFXIV.JOBS.PALADIN] 		= 9,
		[FFXIV.JOBS.PUGILIST] 		= 53,
		[FFXIV.JOBS.SCHOLAR] 		= 163,
		[FFXIV.JOBS.SUMMONER] 		= 163,
		[FFXIV.JOBS.THAUMATURGE] 	= 142,
		[FFXIV.JOBS.WARRIOR] 	 	= 31,
		[FFXIV.JOBS.WHITEMAGE] 	 	= 119,
	}
	
	-- CanCast returns true 90% of the cases for me when beeing 1-2 units too far away to cast
	local skill = ActionList:Get(testSkills[Player.job])
	if ( skill )then
		-- You can't check for skill.range > target.distance...this will make melee characters look really stupid
		-- because they run right up underneath larger monsters. You have to account for hitradius which can be 
		-- very large for big mobs.
		
		-- fix for melee chars hopping behind an enemy that runs away?
		if ( ActionList:CanCast(testSkills[Player.job],target.id) ) then
			if ( ml_global_information.AttackRange < 5) then  -- 255 is -1 , melee weapons need a fix I guess, they show -1
				return (target.distance - target.hitradius) < 3
			else
				return true
			end
		end				
	end
	
	return false
end
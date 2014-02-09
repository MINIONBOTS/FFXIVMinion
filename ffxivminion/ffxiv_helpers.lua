-- This file holds global helper functions

-- I needed to add the lowesthealth check in the bettertargetsearch, this would have collided with this one when terminating the current killtask to swtich to a better target. 
-- Using the lowest health in combatrange should do the job, if it cant find anything, then it grabs the nearest enemy and moves towards it
function GetNearestGrindAttackable()
    local excludeString = ml_blacklist.GetExcludeString(strings[gCurrentLanguage].monsters)
    local el = nil
    
    local minLevel = ml_global_information.MarkerMinLevel 
    local maxLevel = ml_global_information.MarkerMaxLevel
   -- d(tostring(minLevel).. " "..tostring(maxLevel))
    if (ValidTable(ml_task_hub:CurrentTask())) then
		if ((ml_task_hub:CurrentTask().name == "LT_GRIND" or ml_task_hub:CurrentTask().name == "LT_PARTY" ) and ml_task_hub:CurrentTask().currentMarker ~= false) then
            local markerInfo = mm.GetMarkerInfo(ml_task_hub:CurrentTask().currentMarker)
            if (ValidTable(markerInfo)) then
                minLevel = markerInfo.minlevel
                maxLevel = markerInfo.maxlevel
            end
        end
    end
    
    if (excludeString) then
        el = EntityList("lowesthealth,alive,attackable,onmesh,targetingme,fateid=0,exclude_contentid="..excludeString)
    else
        el = EntityList("lowesthealth,alive,attackable,onmesh,targetingme,fateid=0")
    end
    
    if ( el ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end	
    
    if (excludeString) then
        el = EntityList("shortestpath,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0,exclude_contentid="..excludeString)
    else
        el = EntityList("shortestpath,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0")
    end
    
    if ( el ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
    
    if (excludeString) then
        el = EntityList("shortestpath,alive,attackable,onmesh,minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0,exclude_contentid="..excludeString)
    else
        el = EntityList("shortestpath,alive,attackable,onmesh,minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0")
    end
    
    if ( el ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
    ml_debug("GetNearestGrindAttackable() failed with no entity found matching params")
    return nil
end

function GetNearestFateAttackable()
    local excludeString = ml_blacklist.GetExcludeString(strings[gCurrentLanguage].monsters)
    local el = nil

    local myPos = Player.pos
    local fateID = GetClosestFateID(myPos, true, true)
    if (fateID ~= nil and fateID ~= 0) then
        
        if (excludeString) then
            el = EntityList("shortestpath,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",fateid="..tostring(fateID)..",exclude_contentid="..excludeString)
        else
            el = EntityList("shortestpath,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",fateid="..tostring(fateID))
        end
        
        if ( el ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                return e
            end
        end	
    
        if (excludeString) then
            el = EntityList("shortestpath,alive,attackable,onmesh,fateid="..tostring(fateID)..",exclude_contentid="..excludeString)
        else    
            el = EntityList("shortestpath,alive,attackable,onmesh,fateid="..tostring(fateID))            
        end    
            
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

function GetNearestFateAttackableID(fateID)
    if (fateID ~= nil and fateID ~= 0) then
        local excludeString = ml_blacklist.GetExcludeString(strings[gCurrentLanguage].monsters)
        local el = nil
        if (excludeString) then
            el = EntityList("shortestpath,alive,attackable,onmesh,fateid="..tostring(fateID)..",exclude_contentid="..excludeString)
        else
            el = EntityList("shortestpath,alive,attackable,onmesh,fateid="..tostring(fateID))
        end
         
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

function GetBestHealTarget()
    local pID = Player.id
    local el = EntityList("lowesthealth,friendly,chartype=4,myparty,targetable,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
    if ( el ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
    
    local el = EntityList("lowesthealth,friendly,chartype=4,targetable,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
    if ( el ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
    --ml_debug("GetBestHealTarget() failed with no entity found matching params")
    return nil
end

function GetClosestHealTarget()
    local pID = Player.id
    local el = EntityList("nearest,friendly,chartype=4,myparty,targetable,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
    if ( el ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
    
    local el = EntityList("nearest,friendly,chartype=4,targetable,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
    if ( el ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
    --ml_debug("GetBestHealTarget() failed with no entity found matching params")
    return nil
end

function GetPVPTarget()
    local targets = {}
    local bestTarget = nil
    local nearest = nil
	local lowestHealth = nil
    
	local enemyParty = EntityList("onmesh,attackable,alive,chartype=4")
    if (ValidTable(enemyParty)) then
        local id, entity = next(enemyParty)
        while (id ~= nil and entity ~= nil) do
            if not HasBuff(entity.id, 3) and entity.chartype ~= 2 then -- get sleep buff id
				local role = GetRoleString(entity.job)
                if role == "Healer" then
                    targets["Healer"] = entity
                elseif role == "DPS" then
                    if (targets["DPS"] ~= nil) then
						-- keep blackmage as highest prioritized ranged target
						if (gPrioritizeRanged == "1" and IsRangedDPS(entity.job)) then
							if (targets["DPS"].job ~= FFXIV.JOBS.BLACKMAGE) then
								targets["DPS"] = entity
							end
                        end
					else
						targets["DPS"] = entity
                    end
                else
                    targets["Tank"] = entity
                end 
				
				if targets["Nearest"] == nil or targets["Nearest"].distance > entity.distance then
					targets["Nearest"] = entity
				end
				
				if targets["Lowest Health"] == nil or targets["Lowest Health"].hp.percent > entity.hp.percent then
					targets["Lowest Health"] = entity
				end
            end
            id, entity = next(enemyParty, id)
        end
    end
	
	for ttype, target in pairs(targets) do
		if (target and target.alive) then
			ml_debug(ttype..": "..target.name)
		end
	end
    
	if gPVPTargetOne == strings[gCurrentLanguage].healer and targets["Healer"] and targets["Healer"].alive then
		return targets["Healer"]
	elseif gPVPTargetOne == strings[gCurrentLanguage].dps and targets["DPS"] and targets["DPS"].alive then
		return targets["DPS"]
	elseif gPVPTargetOne == strings[gCurrentLanguage].tank and targets["Tank"] and targets["Tank"].alive then
		return targets["Tank"]
	elseif gPVPTargetOne == strings[gCurrentLanguage].lowestHealth and targets["Lowest Health"] and targets["Lowest Health"].alive then
		return targets["Lowest Health"]
	elseif gPVPTargetOne == strings[gCurrentLanguage].nearest and targets["Nearest"] and targets["Nearest"].alive then
		return targets["Nearest"]
	elseif gPVPTargetTwo == strings[gCurrentLanguage].healer and targets["Healer"] and targets["Healer"].alive then
		return targets["Healer"]
	elseif gPVPTargetTwo == strings[gCurrentLanguage].dps and targets["DPS"] and targets["DPS"].alive then
		return targets["DPS"]
	elseif gPVPTargetTwo == strings[gCurrentLanguage].tank and targets["Tank"] and targets["Tank"].alive then
		return targets["Tank"]
	elseif gPVPTargetTwo == strings[gCurrentLanguage].lowestHealth and targets["Lowest Health"] and targets["Lowest Health"].alive then
		return targets["Lowest Health"]
	elseif gPVPTargetTwo == strings[gCurrentLanguage].nearest and targets["Nearest"] and targets["Nearest"].alive then
		return targets["Nearest"]
	else 
		return targets["Lowest Health"]
	end
	
	ml_error("Bad, we shouldn't have gotten to this point!")
end

function GetNearestAggro()
    local el = EntityList("nearest,alive,attackable,onmesh,targetingme")
    if ( el ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
    
    ml_debug("GetNearestAggro() failed with no entity found matching params")
    return nil
end

function GetNearestGatherable(minlevel,maxlevel)
    local excludeString = ml_blacklist.GetExcludeString(strings[gCurrentLanguage].gatherMode)
    local el = nil
    if (excludeString) then
        el = EntityList("shortestpath,onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel)..",exclude="..excludeString)
    else
        el = EntityList("shortestpath,onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel))
    end
    
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
    if (ValidTable(entity)) then
        local buffs = entity.buffs
        if (buffs ~= nil and TableSize(buffs) > 0) then
            for i, buff in pairs(buffs) do
                if (buff.id == buffID) then
                    return true
                end
            end
        end
    else
        return nil
    end
    
    return false
end

function HasBuffFrom(targetID, buffID, ownerID)
    local target = EntityList:Get(targetID)
    if (target ~= nil and target ~= 0) then
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
function HasBuffsFromOwner(entity, buffIDs, ownerid)
    local buffs = entity.buffs
    if (buffs == nil or TableSize(buffs) == 0) then return false end
    for _orids in StringSplit(buffIDs,",") do
      local found = false
      for _andid in StringSplit(_orids,"+") do
          found = false
          for i, buff in pairs(buffs) do
            if (buff.id == tonumber(_andid)and buff.ownerid == ownerid) then 
              found = true 
            end
          end
          if (not found) then 
            break
          end
      end
      if (found) then 
        return true 
      end
    end
    return false
end
function HasBuffs(entity, buffIDs)
    local buffs = entity.buffs
    if (buffs == nil or TableSize(buffs) == 0) then return false end
    for _orids in StringSplit(buffIDs,",") do
      local found = false
      for _andid in StringSplit(_orids,"+") do
          found = false
          for i, buff in pairs(buffs) do
            if (buff.id == tonumber(_andid)) then 
              found = true 
            end
          end
          if (not found) then 
            break
          end
      end
      if (found) then 
        return true 
      end
    end
    return false
end

function IsBehind(entity)
    if(entity.distance2d < ml_global_information.AttackRange) then
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

function ConvertHeading(heading)
	if (heading < 0) then
		return heading + 2 * math.pi
	else
		return heading
	end
end

function GetPosFromDistanceHeading(startPos, distance, heading)
	local head = ConvertHeading(heading)
	d(head)
	local newX = distance * math.sin(head) + startPos.x
	local newZ = distance * math.cos(head) + startPos.z
	return {x = newX, y = startPos.y, z = newZ}
end

function GetFateByID(fateID)
    local fate = nil
    local fateList = MapObject:GetFateList()
    if (fateList ~= nil and fateList ~= 0) then
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

function GetClosestFateID(pos, levelcheck, meshCheck)
    local fateList = MapObject:GetFateList()
    if (fateList ~= nil and fateList ~= 0) then
        local nearestFate = nil
        local nearestDistance = 99999999
        local _, fate = next(fateList)
        local level = Player.level
		local myPos = Player.pos
        while (_ ~= nil and fate ~= nil) do
			if (not ml_blacklist.CheckBlacklistEntry("Fates", fate.id) and (fate.status == 2 or (fate.status == 7 and Distance2D(myPos.x, myPos.z, fate.x, fate.z) < 20))) then
                if ( (tonumber(gMinFateLevel) == 0 and fate.level <= level + tonumber(gMaxFateLevel) ) or (fate.level >= level - tonumber(gMinFateLevel) and fate.level <= level + tonumber(gMaxFateLevel))) then
                    --d("DIST TO FATE :".."ID"..tostring(fate.id).." "..tostring(NavigationManager:GetPointToMeshDistance({x=fate.x, y=fate.y, z=fate.z})) .. " ONMESH: "..tostring(NavigationManager:IsOnMesh(fate.x, fate.y, fate.z)))
                    if (not meshCheck or (meshCheck and NavigationManager:GetPointToMeshDistance({x=fate.x, y=fate.y, z=fate.z})<=5)) then
                    --	d(" NavigationManager:GetPointToMeshDistance: "..tostring( NavigationManager:GetPointToMeshDistance({x=fate.x, y=fate.y, z=fate.z}) ).." fate: "..tostring( fate.name))
                        local distance = PathDistance(NavigationManager:GetPath(myPos.x,myPos.y,myPos.z,fate.x,fate.y,fate.z))
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

function IsLeader()
	local leader = GetPartyLeader()
	if ( leader ) then
		if ( leader.id == Player.id ) then
			return true
		end
	end	
		
    return false
end

function GetPartyLeader()
    local Plist = EntityList.myparty
    if (TableSize(Plist) > 0 ) then
        local i,member = next (Plist)
        while (i~=nil and member~=nil ) do
            if ( member.isleader ) then
                return member
            end
            i,member = next (Plist,i)
        end
    end
    return nil	
end

function InCombatRange(targetid)
    local target = EntityList:Get(targetid)
    if (target == nil or target == {}) then
        ml_debug("InCombatRange NO TARGET")
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
        -- You can't check for skill.range > target.distance2d...this will make melee characters look really stupid
        -- because they run right up underneath larger monsters. You have to account for hitradius which can be 
        -- very large for big mobs.
        
        -- fix for melee chars hopping behind an enemy that runs away?
        if ( ActionList:CanCast(testSkills[Player.job],target.id) ) then
            if ( ml_global_information.AttackRange < 5) then  -- 255 is -1 , melee weapons need a fix I guess, they show -1
                return (target.distance2d - target.hitradius) < 3
            else
                return true
            end
        end				
    end
    
    return false
end

function Mount()
    if not(Player.ismounted) then
        local mounts = ActionList("type=13")
		local mount = mounts[1]
		if ( mount ) then
			local acMount = ActionList:Get(mount.id,13)
			if (acMount.isready) then
				acMount:Cast()
			end
		end
    end
end

function Dismount()
    if (Player.ismounted) then
        local mounts = ActionList("type=13")
        local mount = mounts[1]
        local acMount = ActionList:Get(mount.id,13)
        if (acMount.isready) then
            acMount:Cast()
        end
    end
end

function NodeHasItem(itemName)
    local list = Player:GetGatherableSlotList()
    if (ValidTable(list)) then
        for i,item in pairs(list) do
            if (item.name == itemName) then
                return true
            end
        end
    end
    
    return false
end

function TimeSince(previousTime)
    return ml_global_information.Now - previousTime
end

function GetRoleString(jobID)
    if 
        jobID == FFXIV.JOBS.ARCANIST or
        jobID == FFXIV.JOBS.ARCHER or
        jobID == FFXIV.JOBS.BARD or
        jobID == FFXIV.JOBS.BLACKMAGE or
        jobID == FFXIV.JOBS.DRAGOON or
        jobID == FFXIV.JOBS.LANCER or
        jobID == FFXIV.JOBS.MONK or
        jobID == FFXIV.JOBS.PUGILIST or
        jobID == FFXIV.JOBS.SUMMONER or
        jobID == FFXIV.JOBS.THAUMATURGE
    then
        return "DPS"
    elseif
        jobID == FFXIV.JOBS.CONJURER or
        jobID == FFXIV.JOBS.SCHOLAR or
        jobID == FFXIV.JOBS.WHITEMAGE
    then
        return "Healer"
    elseif 
        jobID == FFXIV.JOBS.GLADIATOR or
        jobID == FFXIV.JOBS.MARAUDER or
        jobID == FFXIV.JOBS.PALADIN or
        jobID == FFXIV.JOBS.WARRIOR
    then
        return "Tank"
    end
end

function IsRangedDPS(jobID)
	return 	jobID == FFXIV.JOBS.ARCANIST or
			jobID == FFXIV.JOBS.ARCHER or
			jobID == FFXIV.JOBS.BARD or
			jobID == FFXIV.JOBS.BLACKMAGE or
			jobID == FFXIV.JOBS.SUMMONER or
			jobID == FFXIV.JOBS.THAUMATURGE
end

function IsRanged(jobID)
	return 	jobID == FFXIV.JOBS.ARCANIST or
			jobID == FFXIV.JOBS.ARCHER or
			jobID == FFXIV.JOBS.BARD or
			jobID == FFXIV.JOBS.BLACKMAGE or
			jobID == FFXIV.JOBS.SUMMONER or
			jobID == FFXIV.JOBS.THAUMATURGE or
			jobID == FFXIV.JOBS.CONJURER or
			jobID == FFXIV.JOBS.SCHOLAR or
			jobID == FFXIV.JOBS.WHITEMAGE
end

function PartyMemberWithBuff(hasbuffs, hasnot, maxdistance) 
  if (maxdistance==nil or maxdistance == "") then
    maxdistance = 30
  end
  local el = EntityList("myparty,chartype=4,maxdistance="..tostring(maxdistance)..",targetable,los")
  local i,e = next(el)
  while (i~=nil and e ~= nil) do
    if ( (hasbuffs=="" or HasBuffs(e,hasbuffs)) and (hasnot=="" or not HasBuffs(e,hasnot)) ) then
        d("picking " .. e.name )
        return e
    end
    i,e = next(el,i)
  end  
  return nil
end

function GetLocalAetheryte()
    local list = Player:GetAetheryteList()
    for index,aetheryte in ipairs(list) do
        if (aetheryte.islocalmap) then
            return aetheryte.id
        end
    end
    
    return nil
end
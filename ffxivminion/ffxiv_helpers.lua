-- This file holds global helper functions

-- I needed to add the lowesthealth check in the bettertargetsearch, this would have collided with this one when terminating the current killtask to swtich to a better target. 
-- Using the lowest health in combatrange should do the job, if it cant find anything, then it grabs the nearest enemy and moves towards it
function GetNearestGrindAttackable()
	local huntString = GetWhitelistIDString()
	local excludeString = GetBlacklistIDString()
	local block = 0
	local el = nil
	local nearestGrind = nil
	local nearestDistance = 9999
	local minLevel = ml_global_information.MarkerMinLevel 
	local maxLevel = ml_global_information.MarkerMaxLevel
	
	block = 1
	if (gClaimFirst	== "1") then		
		if (not IsNullString(huntString)) then
			local el = EntityList("shortestpath,contentid="..huntString..",notincombat,alive,attackable,onmesh")
			if ( el ) then
				local i,e = next(el)
				if (i~=nil and e~=nil and 
					(e.targetid == 0 or e.targetid == Player.id) and
					e.pathdistance <= tonumber(gClaimRange)) then
					--d("Grind returned, using block:"..tostring(block))
					return e
				end
			end
		end
	end	
    
	--Prioritize the lowest health with aggro on player, non-fate mobs.
	block = 2
	if (not IsNullString(excludeString)) then
		el = EntityList("shortestpath,alive,attackable,los,onmesh,targetingme,fateid=0,exclude_contentid="..excludeString..",maxdistance=30") 
	else
		el = EntityList("shortestpath,alive,attackable,los,onmesh,targetingme,fateid=0,maxdistance=30") 
	end
	
	if ( el ) then
		local i,e = next(el)
		if (i~=nil and e~=nil) then
			--d("Grind returned, using block:"..tostring(block))
			return e
		end
	end	

	--ml_debug("Grind failed check #1")

	--Lowest health with aggro on anybody in player's party, non-fate mobs.
	--Can't use aggrolist for party because chocobo doesn't get included, will eventually get railroaded.
	block = 3
	local party = EntityList.myparty
	if ( party ) then
		for i, member in pairs(party) do
			if (member.id and member.id ~= 0) then
				if (not IsNullString(excludeString)) then
					el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",fateid=0,exclude_contentid="..excludeString..",maxdistance=30")
				else
					el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",fateid=0,maxdistance=30")
				end
				
				if ( el ) then
					local i,e = next(el)
					if (i~=nil and e~=nil) then
						--d("Grind returned, using block:"..tostring(block))
						return e
					end
				end
			end
		end
	end
	
	block = 4
	if (ValidTable(Player.pet)) then
		if (not IsNullString(excludeString)) then
			el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(Player.pet.id)..",fateid=0,exclude_contentid="..excludeString..",maxdistance="..tostring(ml_global_information.AttackRange))
		else
			el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(Player.pet.id)..",fateid=0,maxdistance="..tostring(ml_global_information.AttackRange))
		end
		
		if ( el ) then
			local i,e = next(el)
			if (i~=nil and e~=nil) then
				--d("Grind returned, using block:"..tostring(block))
				return e
			end
		end
	end
	
	--Nearest specified hunt, ignore levels here, assume players know what they wanted to kill.
	block = 5
	if (not IsNullString(huntString)) then
		el = EntityList("contentid="..huntString..",shortestpath,alive,attackable,onmesh")
		
		if ( el ) then
			local i,e = next(el)
			if (i~=nil and e~=nil and (e.targetid == 0 or e.targetid == Player.id or gClaimed == "1")) then
				--d("Grind returned, using block:"..tostring(block))
				return e
			end
		end
	end
	
	--Nearest in our attack range, not targeting anything, non-fate, use PathDistance.
	if (IsNullString(huntString)) then
		if (not IsNullString(excludeString)) then
			el = EntityList("shortestpath,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0,exclude_contentid="..excludeString)
		else
			el = EntityList("shortestpath,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0")
		end
		
		block = 6
		if ( el ) then
			local i,e = next(el)
			if (i~=nil and e~=nil) then
				--d("Grind returned, using block:"..tostring(block))
				return e
			end
		end
	
		if (not IsNullString(excludeString)) then
			el = EntityList("shortestpath,alive,attackable,onmesh,minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0,exclude_contentid="..excludeString)
		else
			el = EntityList("shortestpath,alive,attackable,onmesh,minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0")
		end
		
		block = 7
		if ( el ) then
			local i,e = next(el)
			if (i~=nil and e~=nil) then
				--d("Grind returned, using block:"..tostring(block))
				return e
			end
		end
	end
	
    --d("GetNearestGrindAttackable() failed with no entity found matching params")
    return nil
end

function GetNearestGrindPriority()
	local huntString = GetWhitelistIDString
	local excludeString = GetBlacklistIDString
	local el = nil
	
	if (gClaimFirst	== "1") then
		if (not IsNullString(huntString)) then
			local el = EntityList("shortestpath,contentid="..tostring(huntString)..",targeting=0,notincombat,alive,attackable,onmesh")
			if ( el ) then
				local i,e = next(el)
				if ( i~= nil and e~= nil and 
					e.pathdistance <= tonumber(gClaimRange)) then
					return e
				end
			end
		end
	end	

	return nil
end

function GetNearestFateAttackable()
	local el = nil
    local myPos = Player.pos
    local fate = GetClosestFate(myPos)
	
    if (fate ~= nil) then
        el = EntityList("shortestpath,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",fateid="..tostring(fate.id))

        if ( el ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                return e
            end
        end	
    
        el = EntityList("shortestpath,alive,attackable,onmesh,fateid="..tostring(fate.id))            
            
        if ( el ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                return e
            end
        end
    end
    
    --ml_debug("GetNearestFateAttackable() failed with no entity found matching params")
    return nil
end

function GetHuntTarget()
	local nearest = nil
	local nearestDistance = 9999
	local excludeString = GetBlacklistIDString()
	local el = nil
	
	if (excludeString) then
		el = EntityList("contentid="..ffxiv_task_hunt.rankS..",alive,attackable,onmesh,exclude_contentid="..excludeString)
	else
		el = EntityList("contentid="..ffxiv_task_hunt.rankS..",alive,attackable,onmesh")
	end
	if (ValidTable(el)) then
		for i,e in pairs(el) do
			local myPos = Player.pos
			local tpos = e.pos
			local distance = Distance3D(myPos.x, myPos.y, myPos.z, tpos.x, tpos.y, tpos.z)
			if (distance < nearestDistance) then
				nearest = e
				nearestDistance = distance
			end
		end
		
		if (ValidTable(nearest)) then
			return "S", nearest
		end
	end
	
	if (excludeString) then
		el = EntityList("contentid="..ffxiv_task_hunt.rankA..",alive,attackable,onmesh,exclude_contentid="..excludeString)
	else
		el = EntityList("contentid="..ffxiv_task_hunt.rankA..",alive,attackable,onmesh")
	end
	if (ValidTable(el)) then
		for i,e in pairs(el) do
			local myPos = Player.pos
			local tpos = e.pos
			local distance = Distance3D(myPos.x, myPos.y, myPos.z, tpos.x, tpos.y, tpos.z)
			if (distance < nearestDistance) then
				nearest = e
				nearestDistance = distance
			end
		end
		
		if (ValidTable(nearest)) then
			return "A", nearest
		end
	end
	
	if (excludeString) then
		el = EntityList("contentid="..ffxiv_task_hunt.rankB..",alive,attackable,onmesh,exclude_contentid="..excludeString)
	else
		el = EntityList("contentid="..ffxiv_task_hunt.rankB..",alive,attackable,onmesh")
	end
	if (ValidTable(el)) then
		for i,e in pairs(el) do
			local myPos = Player.pos
			local tpos = e.pos
			local distance = Distance3D(myPos.x, myPos.y, myPos.z, tpos.x, tpos.y, tpos.z)
			if (distance < nearestDistance) then
				nearest = e
				nearestDistance = distance
			end
		end
		
		if (ValidTable(nearest)) then
			return "B", nearest
		end
	end
	
	return nil
end

function GetBestTankHealTarget( range )
	range = range or ml_global_information.AttackRange
    local pID = Player.id
	local lowest = nil
	local lowestHP = 101
	
    local el = EntityList("friendly,chartype=4,myparty,targetable,maxdistance="..tostring(range))
    if ( el ) then
		for i,e in pairs(el) do
			if (e.job == 1 or e.job == 19 or e.job == 3 or e.job == 21) then
				if (e.hp.percent < lowestHP ) then
					lowest = e
					lowestHP = e.hp.percent
				end
			end
        end
    end
	
	local ptrg = Player:GetTarget()
	if (ptrg ~= nil) then
		if (lowest == nil and Player.pet ~= nil and ptrg.targetid == Player.pet.id) then
			lowest = Player.pet
		end
	end
	
	if (lowest ~= nil and lowest.hp.percent ~= 0) then
		return lowest
	end
	
    return nil
end

function GetBestPartyHealTarget( npc, range )
	npc = npc or false
	range = range or ml_global_information.AttackRange
	
	local el = nil
	el = EntityList("lowesthealth,friendly,chartype=4,myparty,targetable,maxdistance="..tostring(range))
	
    if ( el ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            if (e.chartype == 4 or (e.chartype == 0 and (e.type == 2 or e.type == 3 or e.type == 5)) or (e.chartype == 3 and e.type == 2))  then
				return e
			end
        end
    end
	
	if (npc) then
		el = EntityList("lowesthealth,friendly,myparty,targetable,maxdistance="..tostring(range))
		if ( el ) then
			local i,e = next(el)
			if (i~=nil and e~=nil) then
				if (e.chartype == 4 or (e.chartype == 0 and (e.type == 2 or e.type == 3 or e.type == 5)) or (e.chartype == 3 and e.type == 2))  then
					return e
				end
			end
		end
	end
	
	if (gBotMode == GetString("partyMode") and not IsLeader()) then
		local leader = GetPartyLeader()
		if (leader and leader.id ~= 0) then
			local leaderentity = EntityList:Get(leader.id)
			if (leaderentity and leaderentity.distance <= range) then
				return leaderentity
			end
		end
	end
	
    return nil
end

function GetLowestMPParty()
    local pID = Player.id
	local lowest = nil
	local lowestMP = 101
    local el = EntityList("myparty,type=1,targetable,maxdistance=35")
    if ( el ) then
        local i,e = next(el)
        while (i~=nil and e~=nil) do
            if (e.mp.percent ~= nil and e.hp.percent > 0 and e.mp.percent < lowestMP) then
				if (e.job == 28 or e.job == 27 or e.job == 26 or e.job == 24 or e.job == 19 or e.job == 6 or e.job == 1 ) then
					lowest = e
					lowestMP = e.mp.percent
				end
			end
			i,e  = next(el,i) 
        end
    end
	
	if (Player.hp.percent > 0 and Player.mp.percent < lowestMP) then
		if (Player.job == 28 or Player.job == 27 or Player.job == 26 or Player.job == 24 or Player.job == 19 or Player.job == 6 or Player.job == 1 ) then
			lowest = Player
			lowestMP = Player.mp.percent
		end
	end
	
	if (lowest ~= nil and lowest.hp.percent ~= 0) then
		return lowest
	end
	
    --ml_debug("GetLowestMPTarget() failed with no entity found matching params")
    return nil
end

function GetLowestHPParty( skill )
    npc = skill.npc == "1" and true or false
	range = skill.range or ml_global_information.AttackRange
	count = skill.ptcount or 0
	minHP = skill.pthpb or 0
	
	local lowest = nil
	local lowestHP = 101
	local el = nil
	local memCount = 0
	
	if (count ~= 0 and minHP > 0) then
		local party = EntityList.myparty
		for i, member in pairs(party) do
			if (((not npc and member.type == 1) or npc) and	member.id ~= 0 and member.targetable and member.distance <= range and member.hp.percent <= minHP) then
				memCount = memCount + 1
			end
			if (memCount >= skill.ptcount) then
				return true
			end
		end
	else
		if (not npc) then
			el = EntityList("myparty,type=1,targetable,maxdistance="..tostring(range))
		else
			el = EntityList("myparty,targetable,maxdistance="..tostring(range))
		end
		
		if ( el ) then
			local i,e = next(el)
			while (i~=nil and e~=nil) do
				if (e.hp.percent ~= nil and e.hp.percent > 0 and e.hp.percent < lowestHP) then
					lowest = e
					lowestHP = e.hp.percent
				end
				i,e  = next(el,i) 
			end
		end
		
		if (Player.hp.percent > 0 and Player.hp.percent < lowestHP) then
			lowest = Player
			lowestHP = Player.hp.percent
		end
		
		if (lowest ~= nil and lowest.hp.percent ~= 0) then
			if (lowest.chartype == 4 or (lowest.chartype == 0 and (lowest.type == 2 or lowest.type == 3 or lowest.type == 5)) or (lowest.chartype == 3 and lowest.type == 2))  then
				return lowest
			end
		end
	end
	
    --ml_debug("GetLowestHPTarget() failed with no entity found matching params")
    return nil
end

function GetLowestTPParty()
	local lowest = nil
	local lowestTP = 1001
    local el = EntityList("myparty,type=1,targetable,maxdistance=35")
    if ( el ) then
        local i,e = next(el)
        while (i~=nil and e~=nil) do
            if (e.tp ~= nil and e.hp.percent > 0 and e.tp < lowestTP) then
				if (e.job == 1 or e.job == 2 or e.job == 3 or e.job == 4 or e.job == 5 or e.job == 19 or e.job == 20 or
					e.job == 21 or e.job == 22 or e.job == 23 ) then
					lowest = e
					lowestTP = e.tp
				end
			end
			i,e  = next(el,i) 
        end
    end
	
	if (Player.hp.percent > 0 and Player.tp < lowestTP) then
		local e = Player
		if (e.job == 1 or e.job == 2 or e.job == 3 or e.job == 4 or e.job == 5 or e.job == 19 or e.job == 20 or	e.job == 21 or e.job == 22 or e.job == 23 ) then
			lowest = Player
			lowestTP = Player.tp
		end
	end
	
	if (lowest ~= nil and lowest.hp.percent ~= 0) then
		return lowest
	end
	
	--ml_debug("lowest tp failed with no matches.")
    return nil
end

function GetBestHealTarget( npc, range )
	npc = npc or false
	range = range or ml_global_information.AttackRange
	
	local el = nil
	el = EntityList("lowesthealth,alive,friendly,chartype=4,targetable,maxdistance="..tostring(range))
	if ( el ) then
		local i,e = next(el)
		if (i~=nil and e~=nil) then
			return e
		end
	end
	
	if (npc) then
		el = EntityList("lowesthealth,alive,friendly,targetable,maxdistance="..tostring(range))
		if ( el ) then
			local i,e = next(el)
			if (i~=nil and e~=nil) then
				if ((e.chartype == 0 and (e.type == 2 or e.type == 3 or e.type == 5)) or (e.chartype == 3 and e.type == 2))  then
					return e
				end
			end
		end
	end
   
    ml_debug("GetBestHealTarget() failed with no entity found matching params")
    return nil
end

function GetBestBaneTarget()
	local bestTarget = nil
	local party = EntityList.myparty
	local el = nil
	
	--Check the original diseased target, make sure it has all the required buffs, and that they're all 3 or more, blow it up, reset the best dot target.
	if (SkillMgr.bestAOE ~= 0) then
		local e = EntityList:Get(SkillMgr.bestAOE)
		if (ValidTable(e) and e.alive and e.attackable and e.los and e.distance <= 25 and HasBuffs(e, "179+180+189", 3, Player)) then
			SkillMgr.bestAOE = 0
			return e
		end
	end
	
	--If the original target is not found, check the best target with clustered, blow it up, reset the best dot target.
	for i,member in pairs(party) do
		if (member.id ~= 0) then
			local el = EntityList("alive,attackable,los,clustered=8,targeting="..tostring(member.id)..",maxdistance=25")
			if ( el ) then
				for k,e in pairs(el) do
					if HasBuffs(e, "179+180+189", 3, Player) then
						SkillMgr.bestAOE = 0
						return e
					end
				end
			end
		end
	end
	
    return nil
end

function GetBestDoTTarget()
	local bestTarget = nil
	local party = EntityList.myparty
	local el = nil
	
	--Check for the original DoT target, if it exists, and is still missing debuffs, keep using it.
	if (SkillMgr.bestAOE ~= 0) then
		local e = EntityList:Get(SkillMgr.bestAOE)
		if (ValidTable(e) and e.alive and e.attackable and e.los and e.distance <= 25 and MissingBuffs(e, "179,180,189", 3, Player)) then
			return e
		end
	end
	
	--Check for a new target that is clustered and missing all 3 buffs
	for i,member in pairs(party) do
		if (member.id ~= 0) then
			local el = EntityList("alive,attackable,los,clustered=8,targeting="..tostring(member.id)..",maxdistance=25")
			if ( el ) then
				for k,e in pairs(el) do
					if MissingBuffs(e, "179+180+189", 3, Player) then
						SkillMgr.bestAOE = e.id
						return e
					end
				end
			end
		end
	end
	
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

function GetBestRevive( party, role)
	party = party or false
	role = role or "Any"
	range = ml_global_information.AttackRange
	
	local el = nil
	if (party) then
		el = EntityList("myparty,dead,maxdistance="..tostring(range))
	else
		el = EntityList("dead,maxdistance="..tostring(range))
	end 
								
	if ( el ) then
		if (role ~= "Any") then
			local i,e = next(el)
			while (i~=nil and e~=nil) do
				if (e.job ~= nil and GetRoleString(e.job) == role and not HasBuffs(e, "148")) then
					return e
				end
				i,e = next(el,i)  
			end  
		else
			local i,e = next(el)
			if (i~=nil and e~=nil) then
				if (not HasBuffs(e, "148")) then
					return e
				end
			end  
		end
	end
	
	if (gBotMode == GetString("partyMode") and not IsLeader()) then
		local leader = GetPartyLeader()
		if (leader and leader.id ~= 0) then
			local leaderentity = EntityList:Get(leader.id)
			if (leaderentity and leaderentity.distance <= range and not leader.alive and not HasBuffs(leaderentity, "148")) then
				return leaderentity
			end
		end
	end
	
	
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
			local beingSlept = false
			for i,teammate in pairs(EntityList.myparty) do
				if (TableSize(teammate.castinginfo) > 0) then
					if (teammate.castinginfo.channeltargetid == entity.id and 
						(teammate.castinginfo.channelingid == 128 or
						teammate.castinginfo.channelingid == 145) and
						teammate.id ~= Player.id) then
						beingSlept = true
					end
				end
				if beingSlept then
					break
				end
			end
			
            if (not HasBuff(entity.id, 3) and not HasBuff(entity.id, 397) and entity.chartype ~= 2 and not beingSlept) then -- get sleep buff id
				local role = GetRoleString(entity.job)
                if role == strings[gCurrentLanguage].healer then
                    targets[strings[gCurrentLanguage].healer] = entity
                elseif role == strings[gCurrentLanguage].dps then
                    if (targets[strings[gCurrentLanguage].dps] ~= nil) then
						-- keep blackmage as highest prioritized ranged target
						if (gPrioritizeRanged == "1" and IsRangedDPS(entity.job)) then
							if (targets[strings[gCurrentLanguage].dps].job ~= FFXIV.JOBS.BLACKMAGE) then
								targets[strings[gCurrentLanguage].dps] = entity
							end
                        end
					else
						targets[strings[gCurrentLanguage].dps] = entity
                    end
                else
                    targets[strings[gCurrentLanguage].tank] = entity
                end 
				
				if role == strings[gCurrentLanguage].healer then
					local eid = entity.id
					local untargeted = true
                    for i,teammate in pairs(EntityList.myparty) do
						if (teammate.targetid == eid and teammate.id ~= Player.id and entity.hp.percent > 40) then
							untargeted = false
						end
						if not untargeted then
							break
						end
					end
					if untargeted then
						targets[strings[gCurrentLanguage].unattendedHealer] = entity
					else
						targets[strings[gCurrentLanguage].unattendedHealer] = nil
					end
				end
				
				if IsMeleeDPS(entity.job) then
					targets[strings[gCurrentLanguage].meleeDPS] = entity				
				end
				
				if IsCasterDPS(entity.job) then
					if (targets[strings[gCurrentLanguage].caster] ~= nil) then
						if (targets[strings[gCurrentLanguage].caster].job ~= FFXIV.JOBS.BLACKMAGE) then
							targets[strings[gCurrentLanguage].caster] = entity
						end
					else
						targets[strings[gCurrentLanguage].caster] = entity
					end
				end
				
				if IsRangedDPS(entity.job) then
					if (targets[strings[gCurrentLanguage].ranged] ~= nil) then
						if (targets[strings[gCurrentLanguage].ranged].job ~= FFXIV.JOBS.BLACKMAGE) then
							targets[strings[gCurrentLanguage].ranged] = entity
						end
					else
						targets[strings[gCurrentLanguage].ranged] = entity
					end
				end
				
				if (entity.job == FFXIV.JOBS.BLACKMAGE or entity.job == FFXIV.JOBS.WHITEMAGE) then
					if (targets[strings[gCurrentLanguage].sleeper] ~= nil) then
						if (targets[strings[gCurrentLanguage].sleeper].job ~= FFXIV.JOBS.BLACKMAGE) then
							targets[strings[gCurrentLanguage].sleeper] = entity
						end
					else
						targets[strings[gCurrentLanguage].sleeper] = entity
					end
				end
				
				if targets[strings[gCurrentLanguage].nearDead] == entity and (entity.hp.percent > 30 or not entity.alive or entity.distance > 25) then
					targets[strings[gCurrentLanguage].nearDead] = nil
				end
				
				if entity.hp.percent < 30 and entity.pathdistance < 15 then
					targets[strings[gCurrentLanguage].nearDead] = entity
				end
					
				
				if targets[strings[gCurrentLanguage].nearest] == nil or targets[strings[gCurrentLanguage].nearest].distance > entity.distance then
					targets[strings[gCurrentLanguage].nearest] = entity
				end
				
				if targets[strings[gCurrentLanguage].lowestHealth] == nil or targets[strings[gCurrentLanguage].lowestHealth].hp.percent > entity.hp.percent then
					targets[strings[gCurrentLanguage].lowestHealth] = entity
				end
            end
            id, entity = next(enemyParty, id)
        end
    end
	
	for k,v in pairs(targets) do
		if not v.alive then
			targets[k] = nil
		end
	end
	
	if targets[gPVPTargetOne] ~= nil and targets[gPVPTargetOne].alive then
		return targets[gPVPTargetOne]
	elseif targets[gPVPTargetTwo] ~= nil and targets[gPVPTargetTwo].alive then
		return targets[gPVPTargetTwo]
	elseif targets[gPVPTargetThree] ~= nil and targets[gPVPTargetThree].alive then
		return targets[gPVPTargetThree]
	elseif targets[gPVPTargetFour] ~= nil and targets[gPVPTargetFour].alive then
		return targets[gPVPTargetFour]
	elseif targets[gPVPTargetFive] ~= nil and targets[gPVPTargetFive].alive then
		return targets[gPVPTargetFive]
	else
		return targets[strings[gCurrentLanguage].lowestHealth]
	end
	
	ml_error("Bad, we shouldn't have gotten to this point!")
end

function GetDutyTarget( maxHP )
	maxHP = maxHP or nil
	
	if (gBotMode ~= strings[gCurrentLanguage].dutyMode or not IsDutyLeader() or ml_task_hub:CurrentTask().encounterData.bossIDs == nil) then
        return nil
    end
	
	if (ml_task_hub:CurrentTask().encounterData.prioritize ~= nil) then
		if (ml_task_hub:CurrentTask().encounterData.prioritize) then
			for uniqueid in StringSplit(ml_task_hub:CurrentTask().encounterData.bossIDs,";") do
				local el = nil
				if Player.incombat then
					el = EntityList("lowesthealth,alive,contentid="..uniqueid..",maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
				else
					el = EntityList("nearest,alive,contentid="..uniqueid..",maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
				end
				if (ValidTable(el)) then
					local id, target = next(el)
					if (target.targetable) then
						if (not maxHP or target.hp.percent > maxHP) then
							return target
						end
					end
				end		
			end
		end
	end
	
	local el = nil
	local highestHP = 1
	local bestAOE = nil
	--First, try to get the best AOE target if we are killing the mobs.
	if (Player.incombat and ml_task_hub:CurrentTask().encounterData["doKill"] == true) then
		el = EntityList("alive,los,clustered=5,contentid="..ml_task_hub:CurrentTask().encounterData.bossIDs..",maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))	
		if (ValidTable(el)) then
			
			for id, target in pairs(el) do
				if (target.hp.current > highestHP and target.attackable) then
					if (not maxHP or target.hp.percent > maxHP) then
						bestAOE = target
					end
				end			
			end
			
			if (ValidTable(bestAOE)) then
				return bestAOE
			end
		end	
	end
	
	--Second, try to get the lowesthealth, if we are killing the mobs.
	if (Player.incombat and ml_task_hub:CurrentTask().encounterData["doKill"] == true) then
		el = EntityList("lowesthealth,alive,los,contentid="..ml_task_hub:CurrentTask().encounterData.bossIDs..",maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))	
		if (ValidTable(el)) then
			local id, target = next(el)
			if (target.attackable) then
				if (not maxHP or target.hp.percent > maxHP) then
					return target
				end
			end
		end	
	end
	
	highestHP = 1
	bestAOE = nil
	--Third, try to get the best AOE target if we are killing the mobs, los ignored.
	if (Player.incombat and ml_task_hub:CurrentTask().encounterData["doKill"] == true) then
		el = EntityList("alive,clustered=5,contentid="..ml_task_hub:CurrentTask().encounterData.bossIDs..",maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))	
		if (ValidTable(el)) then
			for id, target in pairs(el) do
				if (target.hp.current > highestHP and target.attackable) then
					if (not maxHP or target.hp.percent > maxHP) then
						bestAOE = target
					end
				end			
			end
			
			if (ValidTable(bestAOE)) then
				return bestAOE
			end
		end	
	end
	
	--Fourth, try to get the lowesthealth, if we are killing the mobs, los ignored.
	if (Player.incombat and ml_task_hub:CurrentTask().encounterData["doKill"] == true) then
		el = EntityList("lowesthealth,alive,contentid="..ml_task_hub:CurrentTask().encounterData.bossIDs..",maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))	
		if (ValidTable(el)) then
			local id, target = next(el)
			if (target.attackable) then
				if (not maxHP or target.hp.percent > maxHP) then
					return target
				end
			end
		end	
	end
	
	--Fifth, if we are only pulling, get one with no target.
	if (ml_task_hub:CurrentTask().encounterData["doKill"] == false) then
		el = EntityList("nearest,alive,targeting=0,contentid="..ml_task_hub:CurrentTask().encounterData.bossIDs..",maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))		
		if (ValidTable(el)) then
			for id, target in pairs(el) do
				if (target.attackable and target.targetid == 0) then
					if (not maxHP or target.hp.percent > maxHP) then
						return target
					end
				end
			end
		end	
	end
	
	--Lastly, fall back and just get what we can.
	el = EntityList("alive,contentid="..ml_task_hub:CurrentTask().encounterData.bossIDs..",maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))	
	if (ValidTable(el)) then
		for id, target in pairs(el) do
			if (target.attackable) then
				if (not maxHP or target.hp.percent > maxHP) then
					return target
				end
			end
		end
	end	
	
    return nil
end

function GetNearestAggro()
	if (not IsNullString(excludeString)) then
		el = EntityList("shortestpath,alive,attackable,los,onmesh,targetingme,exclude_contentid="..excludeString..",maxdistance=30") 
	else
		el = EntityList("shortestpath,alive,attackable,los,onmesh,targetingme,maxdistance=30") 
	end
	
	if ( el ) then
		local i,e = next(el)
		if (i~=nil and e~=nil) then
			--d("Grind returned, using block:"..tostring(block))
			return e
		end
	end
	
	local party = EntityList.myparty
	if ( party ) then
		for i, member in pairs(party) do
			if (member.id and member.id ~= 0) then
				if (not IsNullString(excludeString)) then
					el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",exclude_contentid="..excludeString..",maxdistance=30")
				else
					el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",maxdistance=30")
				end
				
				if ( el ) then
					local i,e = next(el)
					if (i~=nil and e~=nil) then
						--d("Grind returned, using block:"..tostring(block))
						return e
					end
				end
			end
		end
	end
    
    return nil
end

function GetNearestGatherable(minlevel,maxlevel)
    local el = nil
    local whitelist = GetWhitelistIDString()
    local blacklist = GetBlacklistIDString()
    
    if (whitelist and whitelist ~= "") then
        el = EntityList("shortestpath,onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel)..",contentid="..whitelist)
    elseif (blacklist and blacklist ~= "") then
        el = EntityList("shortestpath,onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel)..",exclude_contentid="..blacklist)
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

function GetMaxAttackRange()
	local target = Player:GetTarget()
	
	if (target and target.id ~= nil) then
		local highestRange = 1
		
		if ( TableSize(SkillMgr.SkillProfile) > 0 ) then
			for prio,skill in pairs(SkillMgr.SkillProfile) do
				if ( skill.maxRange > 0 and skill.used == "1" and skill.maxRange > highestRange ) then
					local s = ActionList:Get(skill.id)
					if (s) then
						if (ActionList:CanCast(skill.id,target.id) and 
							((ml_global_information.AttackRange < 5 and s.isready) or
							ml_global_information.AttackRange >= 5)) then
							highestRange = tonumber(skill.maxRange) * (tonumber(gCombatRangePercent) / 100)
						end
					end
				end
			end
		end
		return highestRange
	end
	
	return 1
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

function HasSkill( skillids )
	local skills = SkillMgr.SkillProfile
	--for prio,skill in spairs(SkillMgr.SkillProfile)
	
	if (not ValidTable(skills)) then return false end
	
	for _orids in StringSplit(skillids,",") do
		local found = false
		for _andid in StringSplit(_orids,"+") do
			found = false
			for i, skill in pairs(skills) do
				if (tonumber(skill.id) == tonumber(_andid) and (skill.used == "1")) then 
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

function HasBuffs(entity, buffIDs, dura, ownerid)
	local duration = dura or 0
	local owner = ownerid or 0
	
    local buffs = entity.buffs
	if (buffs == nil or TableSize(buffs) == 0) then return false end
	for _orids in StringSplit(buffIDs,",") do
		local found = false
		for _andid in StringSplit(_orids,"+") do
			found = false
			for i, buff in pairs(buffs) do
				if (buff.id == tonumber(_andid) and (duration == 0 or buff.duration > duration) 
					and (owner == 0 or buff.ownerid == owner)) then 
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

function MissingBuffs(entity, buffIDs, dura, ownerid)
	local duration = dura or 0
	local owner = ownerid or 0
	
	--If we have no buffs, we are missing everything.
    local buffs = entity.buffs
    if (buffs == nil or TableSize(buffs) == 0) then 
    	return true
    end
    
    --Start by assuming we have no buffs, so they are missing.
    local missing = true
    for _orids in StringSplit(buffIDs,",") do
    	missing = true
		for _andid in StringSplit(_orids,"+") do
			for i, buff in pairs(buffs) do
				if (buff.id == tonumber(_andid) and (duration == 0 or buff.duration > duration)
					and (owner == 0 or buff.ownerid == owner)) then 
					missing = false 
				end
			end
			if (not missing) then 
				break
			end
		end
		if (missing) then 
			return true
		end
    end
    
    return false
end


function ActionList:IsCasting()
	return (Player.castinginfo.channelingid ~= 0 or Player.castinginfo.castingid ~= 0)
end

function SetFacing( posX, posY, posZ)
	posX = tonumber(posX) or 0
	posY = tonumber(posY) or 0
	posZ = tonumber(posZ) or 0
	
	if (posX == 0 and posY == 0 and posZ == 0) then
		posY = .5
	end
	
	Player:SetFacing(posX, posY, posZ)
end

function isCasting(entity, actionIDs , minCasttime , targetid) 
	local ci = entity.castinginfo 
	minCasttime = minCasttime or 0
	
	if ( ci == nil or ci.channelingid == 0 ) then return false end
	
	if ( minCasttime > 0 ) then
		if (ci.channeltime < minCasttime ) then 
			return false 
		elseif (ci.channeltime >= minCasttime and actionIDs == "") then
			return true
		end
	end
	if ( targetid ~= nil and ci.channeltargetid ~= targetid ) then return false end
	
	if (actionIDs ~= "") then
		for _orids in StringSplit(actionIDs,",") do
			if (tonumber(_orids) == ci.channelingid) then
				return true
			end
		end
	end

	return false
end

function HasContentID(entity, contentIDs) 	
	local cID = entity.contentid
	
	for _orids in StringSplit(contentIDs,",") do
		if (tonumber(_orids) == cID) then
			return true
		end
	end
	return false
end

function IsCasterDPS(jobID)
	return 	jobID == FFXIV.JOBS.ARCANIST or
			jobID == FFXIV.JOBS.BLACKMAGE or
			jobID == FFXIV.JOBS.SUMMONER or
			jobID == FFXIV.JOBS.THAUMATURGE
end

function IsCaster(jobID)
	return 	jobID == FFXIV.JOBS.ARCANIST or
			jobID == FFXIV.JOBS.BLACKMAGE or
			jobID == FFXIV.JOBS.SUMMONER or
			jobID == FFXIV.JOBS.THAUMATURGE or
			jobID == FFXIV.JOBS.WHITEMAGE or
			jobID == FFXIV.JOBS.CONJURER or
			jobID == FFXIV.JOBS.SCHOLAR
end

function IsReviveSkill(skillID)
    if (skillID == 173 or skillID == 125) then
        return true
    end
    return false
end
 
 function IsFlanking(entity)
	if not entity or entity.id == Player.id then return false end
	
    if ((entity.distance2d - (entity.hitradius + 1)) <= ml_global_information.AttackRange) then
        local entityHeading = nil
        
        if (entity.pos.h < 0) then
            entityHeading = entity.pos.h + 2 * math.pi
        else
            entityHeading = entity.pos.h
        end

        local entityAngle = math.atan2(Player.pos.x - entity.pos.x, Player.pos.z - entity.pos.z)        
        local deviation = entityAngle - entityHeading
        local absDeviation = math.abs(deviation)
        
        local leftover = absDeviation - math.pi
		leftover = math.abs(leftover)
		
        if (leftover > (math.pi/4) and leftover < (math.pi*.75)) then
            return true
        end
    end
	
    return false
end

function IsBehind(entity)
	if not entity or entity.id == Player.id then return false end
	
    if ((entity.distance2d - (entity.hitradius + 1)) <= ml_global_information.AttackRange) then
        local entityHeading = nil
        
        if (entity.pos.h < 0) then
            entityHeading = entity.pos.h + 2 * math.pi
        else
            entityHeading = entity.pos.h
        end
        
        local entityAngle = math.atan2(Player.pos.x - entity.pos.x, Player.pos.z - entity.pos.z)        
        local deviation = entityAngle - entityHeading
        local absDeviation = math.abs(deviation)
        
        local leftover = absDeviation - math.pi

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

function HeadingToRadians(heading)
	return heading + math.pi
end

function RadiansToHeading(radians)
	return radians - math.pi
end

function DegreesToHeading(degrees)
	return RadiansToHeading(math.rad(degrees))
end

function HeadingToDegrees(heading)
	return math.deg(HeadingToRadians(heading))
end

function TurnAround(sync)	
	local sync = sync or false
	local newHeading = HeadingToDegrees(Player.pos.h)
	newHeading = newHeading + 180
	if (newHeading > 360) then
		newHeading = newHeading - 360
	end
	newHeading = DegreesToHeading(newHeading)	
	if (sync) then
		Player:SetFacingSync(newHeading)
	else
		Player:SetFacing(newHeading)
	end
end

 function AngleFromPos(pos1, pos2)
	if ( TableSize(pos1) < 3 or TableSize(pos2) < 3 ) then
		return nil
	else		
		local angle = math.deg(math.atan2((pos1.x-pos2.x),(pos1.z-pos2.z)))
		if angle < 0 then
		  angle = 360+angle
		end

		return angle
	end
end

function FindPointOnCircle(pos, angle, radius)
	local angleMin = angle - 20
	local angleMax = angle + 20
	local anew

	if angleMin < 0 then
		angleMin = 360 + angleMin
	elseif angleMax > 360 then
		angleMax = angleMax - 360
	end

	if angleMin > angleMax then
		angleMin = math.random(angleMin, 360)
		angleMax = math.random(0, angleMax)
		anew = (math.random(0,1) == 0 and angleMin or angleMax)
	else
		anew = math.random(angleMin, angleMax)
	end

	local ReturnAngle = {}
	ReturnAngle.x = math.sin(math.rad(anew))*radius + pos.x
	ReturnAngle.y = pos.y
	ReturnAngle.z = math.cos(math.rad(anew))*radius + pos.z
	return ReturnAngle
end 

function FindPointLeftRight(pos, angle, radius, relative)
	
	relative = relative or true
	local angleMin
	local angleMax
	
	--if relative then
		angleMin = angle-math.random(90,100)
		angleMax = angle+math.random(90,100)
	--else
		--angleMin = angle-math.random(90,)
		--angleMax = angle+math.random(45,60)
	--end
	

	if angleMin < 0 then
		angleMin = 360 + angleMin
	elseif angleMax > 360 then
		angleMax = angleMax - 360
	end

	local ReturnAngle1 = {}
	ReturnAngle1.x = math.sin(math.rad(angleMin))*radius + pos.x
	ReturnAngle1.y = pos.y
	ReturnAngle1.z = math.cos(math.rad(angleMin))*radius + pos.z

	local ReturnAngle2 = {}
	ReturnAngle2.x = math.sin(math.rad(angleMax))*radius + pos.x
	ReturnAngle2.y = pos.y
	ReturnAngle2.z = math.cos(math.rad(angleMax))*radius + pos.z

	local ReturnAngle = math.random(0,1) == 0 and ReturnAngle1 or ReturnAngle2
	return ReturnAngle
end

function GetPosFromDistanceHeading(startPos, distance, heading)
	local head = ConvertHeading(heading)
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

function GetClosestFate(pos)
    local fateList = MapObject:GetFateList()
    if (TableSize(fateList) > 0) then
        local nearestFate = nil
        local nearestDistance = 99999999
        local level = Player.level
		local myPos = Player.pos
		
		for k, fate in pairs(fateList) do
			if (not ml_blacklist.CheckBlacklistEntry("Fates", fate.id) and 
				(fate.status == 2 or (fate.status == 7 and Distance2D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z) < 50))
				and fate.completion >= tonumber(gFateWaitPercent)) then	
				
					if ( (tonumber(gMinFateLevel) == 0 or (fate.level >= level - tonumber(gMinFateLevel))) and 
						 (tonumber(gMaxFateLevel) == 0 or (fate.level <= level + tonumber(gMaxFateLevel))) ) then
						--d("DIST TO FATE :".."ID"..tostring(fate.id).." "..tostring(NavigationManager:GetPointToMeshDistance({x=fate.x, y=fate.y, z=fate.z})) .. " ONMESH: "..tostring(NavigationManager:IsOnMesh(fate.x, fate.y, fate.z)))
						local p,dist = NavigationManager:GetClosestPointOnMesh({x=fate.x, y=fate.y, z=fate.z},false)
						if (dist <= 5) then
							local distance = PathDistance(NavigationManager:GetPath(myPos.x,myPos.y,myPos.z,fate.x,fate.y,fate.z))
							if (nearestFate == nil or distance < nearestDistance) then
								nearestFate = fate
								nearestDistance = distance
							end
						end
						
					end
            end
        end
    
        if (nearestFate ~= nil) then
			--local fate = nearestFate
			--d("Fate details: Name="..fate.name..",id="..tostring(fate.id)..",completion="..tostring(fate.completion)..",pos="..tostring(fate.x)..","..tostring(fate.y)..","..tostring(fate.z))
            return nearestFate
        end
    end
    
    return nil
end

function IsLeader()
	local leader = nil
	for i,m in pairs(EntityList.myparty) do
		if m.isleader then
			--d("Name:"..tostring(m.name)..", ID:"..tostring(m.id))
			leader = m
		end
	end
	
	if ( leader ) then
		if ( leader.id == Player.id ) then
			return true
		end
	end	
		
    return false
end

function GetPartyLeader()
	if (gBotMode == strings[gCurrentLanguage].partyMode and gPartyGrindUsePartyLeader == "0") then
	
		if (gPartyLeaderName ~= "") then
		local party = EntityList("type=1,name="..gPartyLeaderName)
			if (ValidTable(party)) then
				local i,member = next (party)
				if (i and member) then
					return member
				end
			end
		end
	else
		local party = EntityList.myparty
		if (ValidTable(party)) then
			for i,m in pairs(party) do
				if m.isleader then
					return m
				end
			end
		end
	end 
    
    return nil	    
end

function InCombatRange(targetid)
	local target = {}
	
	--Quick change here to allow passing of a target or just the ID.
	if (type(targetid) == "table") then
		local id = targetid.id
		target = EntityList:Get(id)
		if (TableSize(target) == 0) then
			return false
		end
	else
		target = EntityList:Get(targetid)
		if (TableSize(target) == 0) then
			return false
		end
	end
	
	--If we're in duty, consider the player always in-range, should be handled by the profile.
	--d(ml_task_queue.rootTask)
	if (gBotMode == strings[gCurrentLanguage].dutyMode) then
		return true
	end
	
	if (gBotMode == strings[gCurrentLanguage].gatherMode) then
		local node = EntityList:Get(targetid)
		if (node and node.distance2d < 4) then
			return true
		end
		return false
	end
	
	--If we're casting on the target, consider the player in-range, so that it doesn't attempt to move and interrupt the cast.
	if ( Player.castinginfo.channelingid ~= nil and Player.castinginfo.channeltargetid == targetid) then
		return true
	end
	
	--If the target is los, consider the player not in-range.
	if (not target.los) then
		return false
	end
	
	local highestRange = 0
	local charge = false
	local skillID = nil
	
	if ( TableSize(SkillMgr.SkillProfile) > 0 ) then
		for prio,skill in spairs(SkillMgr.SkillProfile) do
			if ( skill.maxRange > 0 and skill.used == "1" and skill.maxRange > highestRange ) then
				local s = ActionList:Get(skill.id)
				if (s) then
					if (ActionList:CanCast(skill.id,target.id) and 
						((ml_global_information.AttackRange < 5 and s.isready) or
						ml_global_information.AttackRange >= 5)) then
						skillID = skill.id
						highestRange = tonumber(skill.maxRange)
						charge = skill.charge == "1" and true or false
					end
				end
			end
		end
	end
	
	--Throw in some sanity checks.
	if (highestRange > 30) then
		highestRange = 30
	elseif (highestRange < 3) then
		highestRange = 3
	end
	--d("Last skill picked:"..skill.name..", range:"..tostring(skill.maxRange)..", charge:"..tostring(skill.charge))
	
	--d(tostring(ml_global_information.AttackRange)..","..tostring(highestRange)..","..tostring(skillID))
	if ( ml_global_information.AttackRange < 5 ) then
		if (skillID ~= nil) then
			if (highestRange > 5) then
				if ((target.targetid == 0 or target.targetid == nil) and ml_task_hub:RootTask().name ~= "LT_PVP") then
					--d(tostring(skillID).."skill not charge type, but used anyway")
					if ((target.distance - target.hitradius) <= (highestRange * (tonumber(gCombatRangePercent) / 100))) then
						if SkillMgr.Cast( target ) then
							local pos = target.pos
							SetFacing(pos.x,pos.y,pos.z)
							return true
						end
					end
				elseif (charge) then
					--d(tostring(skillID).."skill was charge type")
					if ((target.distance - target.hitradius) <= (highestRange * (tonumber(gCombatRangePercent) / 100))) then
						if SkillMgr.Cast( target ) then
							local pos = target.pos
							SetFacing(pos.x,pos.y,pos.z)
							return true
						end
					end
				end
			end
		end
	else
		return ((target.distance - target.hitradius) <= (highestRange * (tonumber(gCombatRangePercent) / 100)))
	end
	
	--d("InCombatRange based on range:"..tostring((target.distance2d - target.hitradius) <= (3 * (tonumber(gCombatRangePercent) / 100) )))
	return ((target.distance - target.hitradius) <= (3 * (tonumber(gCombatRangePercent) / 100) ))
end

function GetMounts()
	local MountsList = "None"
	local eq = ActionList("type=13")
	for k,v in pairs(eq) do
		MountsList = MountsList..","..v.name
	end
	
	return MountsList
end

function Mount()
	local mountID
	local mountIndex
	
	if not(Player.ismounted) then
	    local mountlist = ActionList("type=13")
		for k,mount in pairs(mountlist) do
			if (gMount == mount.name) then
				mountID = mount.id
				mountIndex = tonumber(k)
			end
		end
		
		if (mountIndex ~= 1) then
			local al = ActionList("type=6")
			local dismiss = al[2]
			local acDismiss = ActionList:Get(dismiss.id,6)
			if (acDismiss.isready) then
				acDismiss:Cast()
			end
		end
	
		local acMount = ActionList:Get(mountID,13)
		if (acMount.isready) then
			acMount:Cast()
		end
	end
end

function Dismount()
	if (Player.ismounted) then
		local mountlist = ActionList("type=13")
		for k,mount in pairs(mountlist) do
			if (gMount == mount.name) then
				mountID = mount.id
			end
		end
		
		local acMount = ActionList:Get(mountID,13)
		if (acMount.isready) then
			acMount:Cast()
		end
	end
end

function Repair()
	if (gRepair == "1") then
		local eq = Inventory("type=1000")
		for i,e in pairs(eq) do
			if (e.condition <= 10) then
				e:Repair()
			end
		end
	end
end

function Eat()
	local foodID
	
	if (gFoodHQ ~= "None") then
		foodID = ffxivminion.foodsHQ[gFoodHQ]
	elseif (gFood ~= "None") then
		foodID = ffxivminion.foods[gFood]
	end
			
	local food = Inventory:Get(foodID)
	if (TableSize(food) > 0 and not HasBuffs(Player,"48")) then
		food:Use()
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

function WhitelistTarget()
	local target = Player:GetTarget()
	if (target) then
		local whitelistGlobal = tostring(_G["Field_"..strings[gCurrentLanguage].contentIDEquals])
		if (whitelistGlobal ~= "") then
			whitelistGlobal = whitelistGlobal..";"..tostring(target.contentid)
		else
			whitelistGlobal = tostring(target.contentid)
		end
		_G["Field_"..strings[gCurrentLanguage].contentIDEquals] = whitelistGlobal
		GUI_RefreshWindow(ml_marker_mgr.editwindow.name)
		
		local name = strings[gCurrentLanguage].contentIDEquals
		if (ValidTable(ml_marker_mgr.currentEditMarker)) then
			ml_marker_mgr.currentEditMarker:SetFieldValue(name, _G["Field_"..strings[gCurrentLanguage].contentIDEquals])
			ml_marker_mgr.WriteMarkerFile(ml_marker_mgr.markerPath)
		end
	end
end

function BlacklistTarget()
	local target = Player:GetTarget()
	if (target) then
		local blacklistGlobal = tostring(_G["Field_"..strings[gCurrentLanguage].NOTcontentIDEquals])
		if (blacklistGlobal ~= "") then
			blacklistGlobal = blacklistGlobal..";"..tostring(target.contentid)
		else
			blacklistGlobal = tostring(target.contentid)
		end
		_G["Field_"..strings[gCurrentLanguage].NOTcontentIDEquals] = blacklistGlobal
		GUI_RefreshWindow(ml_marker_mgr.editwindow.name)
		
		local name = strings[gCurrentLanguage].NOTcontentIDEquals
		if (ValidTable(ml_marker_mgr.currentEditMarker)) then
			ml_marker_mgr.currentEditMarker:SetFieldValue(name, _G["Field_"..strings[gCurrentLanguage].NOTcontentIDEquals])
			ml_marker_mgr.WriteMarkerFile(ml_marker_mgr.markerPath)
		end
	end
end

function IsMap(itemid)
	return (tonumber(itemid) ~= nil and
		tonumber(itemid) >= 6687 and
		tonumber(itemid) <= 6692)
end

function IsGardening(itemid)
	return (tonumber(itemid) ~= nil and
		tonumber(itemid) >= 7715 and
		tonumber(itemid) <= 7767)
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
        return strings[gCurrentLanguage].dps
    elseif
        jobID == FFXIV.JOBS.CONJURER or
        jobID == FFXIV.JOBS.SCHOLAR or
        jobID == FFXIV.JOBS.WHITEMAGE
    then
        return strings[gCurrentLanguage].healer
    elseif 
        jobID == FFXIV.JOBS.GLADIATOR or
        jobID == FFXIV.JOBS.MARAUDER or
        jobID == FFXIV.JOBS.PALADIN or
        jobID == FFXIV.JOBS.WARRIOR
    then
        return strings[gCurrentLanguage].tank
    end
end

function IsMeleeDPS(jobID)
	return 	jobID == FFXIV.JOBS.MONK or
			jobID == FFXIV.JOBS.PUGILIST or
			jobID == FFXIV.JOBS.DRAGOON or
			jobID == FFXIV.JOBS.LANCER
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
	for i,e in pairs(el) do	
		if ( (hasbuffs=="" or HasBuffs(e,hasbuffs)) and (hasnot=="" or not MissingBuffs(e,hasnot)) ) then
			return e
		end						
	end
	
	return nil
end

function PartySMemberWithBuff(hasbuffs, hasnot, maxdistance) 
	maxdistance = maxdistance or 30
 
	local el = EntityList("myparty,chartype=4,maxdistance="..tostring(maxdistance)..",targetable,los")
	for i,e in pairs(el) do	
		if ( (hasbuffs=="" or HasBuffs(e,hasbuffs)) and (hasnot=="" or not MissingBuffs(e,hasnot)) ) then
			return e
		end						
	end

	if ( (hasbuffs=="" or HasBuffs(Player,hasbuffs)) and (hasnot=="" or not MissingBuffs(Player,hasnot)) ) then
        return Player
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

function GetAetheryteByMapID(id)
    local list = Player:GetAetheryteList()
    for index,aetheryte in ipairs(list) do
        if (aetheryte.territory == id) then
            return aetheryte.id
        end
    end
    
    return nil
end

function GetBlacklistIDString()
    -- otherwise first grab the global blacklist exclude string
    local excludeString = ml_blacklist.GetExcludeString(strings[gCurrentLanguage].monsters)
    
    -- then add on any local contentIDs to exclude
    if (ml_global_information.BlacklistContentID and ml_global_information.BlacklistContentID ~= "") then
        excludeString = excludeString..";"..ml_global_information.BlacklistContentID
    end
    
    return excludeString
end

function GetWhitelistIDString()	
    return ml_global_information.WhitelistContentID
end

function GetPartySize()
	local count = 0
	local party = EntityList.myparty
	for _, entry in pairs(party) do
		if (entry) then
			local entity = EntityList:Get(entry.id)
			if (entity.chartype == 4) then
				count = count + 1
			end
		end
	end
	
	return count
end

function GetDutyFromID(dutyID)
	local dutyList = Duty:GetDutyList()
	for _, duty in pairs(dutyList) do
		if (duty.id == dutyID) then
			return duty
		end
	end
	
	return ""
end

function GetBestGrindMap()
	local mapid = Player.localmapid
	local level = Player.level
	
	local inthanalan = 	mapid == 140 or
						mapid == 141 or
						mapid == 145 or
						mapid == 146 or
						mapid == 147 or
						mapid == 140 or
						mapid == 141 or
						mapid == 130 or
						mapid == 131
						
	local inshroud =	mapid == 148 or
						mapid == 152 or
						mapid == 153 or
						mapid == 154 or
						mapid == 132 or --new gridania
						mapid == 133 --old gridania
						
	local inlanoscea = 	mapid == 129 or --upper limsa
						mapid == 128 or --lower limsa
						mapid == 134 or
						mapid == 135 or
						mapid == 137 or
						mapid == 138 or
						mapid == 139 or
						mapid == 180
						
	if (level < 15) then
		if (inthanalan) then
			return 140 --western than
		elseif (inshroud) then
			return 148 --central shroud
		elseif (inlanoscea) then
			return 134 --middle la noscea
		end
	elseif (level >= 15 and level < 20) then
		return 152 --east shroud
	elseif (level >= 20 and level < 25) then
		return 152 --east shroud
	elseif (level >= 20 and level < 30) then
		return 146 --southern than
	elseif (level >= 30 and level < 35) then
		return 146 --southern than
	elseif (level >= 35 and level < 40) then
		return 139 --upper la noscea
	else
		return 180 --outer la noscea
	end
end

function EquipItem(itemID)
	local item = Inventory:Get(itemID)
	if(ValidTable(item)) then
		local equipSlot = 
		{
			[FFXIV.INVENTORYTYPE.INV_ARMORY_OFFHAND] = 1,
			[FFXIV.INVENTORYTYPE.INV_ARMORY_HEAD] = 2,
			[FFXIV.INVENTORYTYPE.INV_ARMORY_BODY] = 3,
			[FFXIV.INVENTORYTYPE.INV_ARMORY_HANDS] = 4,
			[FFXIV.INVENTORYTYPE.INV_ARMORY_WAIST] = 5,
			[FFXIV.INVENTORYTYPE.INV_ARMORY_LEGS] = 6,
			[FFXIV.INVENTORYTYPE.INV_ARMORY_FEET] = 7,
			[FFXIV.INVENTORYTYPE.INV_ARMORY_NECK] = 8,
			[FFXIV.INVENTORYTYPE.INV_ARMORY_EARS] = 9,
			[FFXIV.INVENTORYTYPE.INV_ARMORY_WRIST] = 10,
			[FFXIV.INVENTORYTYPE.INV_ARMORY_RINGS] = 11,
			[FFXIV.INVENTORYTYPE.INV_ARMORY_SOULCRYSTAL] = 12,
			[FFXIV.INVENTORYTYPE.INV_ARMORY_MAINHAND] = 0
		}
		item:Move(1000,equipSlot[item.type])
	end
end

function EquipBestItem(slot)
	
end

function GetArmoryIDsTable()
	local equipSlot = 
	{
		[FFXIV.INVENTORYTYPE.INV_ARMORY_OFFHAND] = 1,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_HEAD] = 2,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_BODY] = 3,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_HANDS] = 4,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_WAIST] = 5,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_LEGS] = 6,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_FEET] = 7,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_NECK] = 8,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_EARS] = 9,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_WRIST] = 10,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_RINGS] = 11,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_SOULCRYSTAL] = 12,
		[FFXIV.INVENTORYTYPE.INV_ARMORY_MAINHAND] = 0
	}
	
	local ids = {}
	for key,_ in pairs(equipSlot) do
		local itemlist = Inventory("type="..tostring(key))
		if(ValidTable(itemlist)) then
			for id, item in pairs(itemlist) do
				ids[item.id] = item
			end
		end
	end
	
	return ids
end

function EorzeaTime()
    
	local et = {}
    local ratioRealToGame = (1440 / 70)	
	
	local jpTime = {}
	jpTime.year = os.date("!%Y")
	jpTime.month = os.date("!%m")
	jpTime.day = os.date("!%d")
	local hour = tonumber(os.date("!%H")) + (os.date("*t").isdst == true and 1 or 0) + 9
	if (hour >= 24) then
		jpTime.day = utc.date + 1
		hour = hour - 24
	end
	jpTime.hour = hour
	jpTime.min = os.date("!%M")
	jpTime.sec = os.date("!%S")
	local jpSecs = os.time(jpTime)
	
	local epoch = { year = 2010, month = 6, day = 12, hour = 0, min = 0, sec = 0 }
	local epochSecs = os.time(epoch)
	
	local diffTime = (jpSecs - epochSecs) - 90000 
	
	local delta = (diffTime * ratioRealToGame)
	
	local gameSecond = (delta % 60) or 0
	delta = delta - gameSecond
	delta = delta / 60
	et.second = gameSecond

	local gameMinute = (delta % 60) or 0
	delta = delta - gameMinute
	delta = delta / 60
	et.minute = gameMinute

	local gameHour = (delta % 24) or 0
	delta = delta - gameHour
	delta = delta / 24
	et.hour = gameHour
	
	local gameDay = (delta % 32) or 0
	delta = delta - gameDay
	delta = delta / 32
	et.day = gameDay
	
	local gameMonth = (delta % 12) or 0
	delta = delta - gameMonth
	delta = delta / 12
	et.month = gameMonth
	
	local gameYear = delta or 0
	et.year = gameYear
	
	return et
end

function GetQuestByID(questID)
	local list = Quest:GetQuestList()
	if(ValidTable(list)) then
		for id, quest in pairs(list) do
			if(id == questID) then
				return quest
			end
		end
	end
end
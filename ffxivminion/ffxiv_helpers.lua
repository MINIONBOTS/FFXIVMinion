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
				if (ValidTable(e) and e.uniqueid ~= 541) then
					if ((e.targetid == 0 or e.targetid == Player.id) and
						e.pathdistance <= tonumber(gClaimRange)) then
						--d("Grind returned, using block:"..tostring(block))
						return e
					end
				end
			end
		end
	end	
    
	--Prioritize the lowest health with aggro on player, non-fate mobs.
	block = 2
	if (not IsNullString(excludeString)) then
		el = EntityList("shortestpath,alive,attackable,onmesh,targetingme,fateid=0,exclude_contentid="..excludeString..",maxpathdistance=30") 
	else
		el = EntityList("shortestpath,alive,attackable,onmesh,targetingme,fateid=0,maxpathdistance=30") 
	end
	
	if ( el ) then
		local i,e = next(el)
		if (ValidTable(e) and e.uniqueid ~= 541) then
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
					if (ValidTable(e) and e.uniqueid ~= 541) then
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
			if (ValidTable(e) and e.uniqueid ~= 541) then
				--d("Grind returned, using block:"..tostring(block))
				return e
			end
		end
	end
	
	--Nearest specified hunt, ignore levels here, assume players know what they wanted to kill.
	block = 5
	if (not IsNullString(huntString)) then
		el = EntityList("contentid="..huntString..",shortestpath,fateid=0,alive,attackable,onmesh")
		
		if ( el ) then
			local i,e = next(el)
			if (ValidTable(e) and e.uniqueid ~= 541) then
				if (e.targetid == 0 or e.targetid == Player.id or gClaimed == "1") then
					--d("Grind returned, using block:"..tostring(block))
					return e
				end
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
			if (ValidTable(e) and e.uniqueid ~= 541) then
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
			if (ValidTable(e) and e.uniqueid ~= 541) then
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
		el = EntityList("shortestpath,alive,attackable,targetingme,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",fateid="..tostring(fate.id))

        if ( el ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
				epos = shallowcopy(e.pos)
				local dist = Distance2D(epos.x,epos.z,fate.x,fate.z)
				if (dist <= fate.radius) then
					return e
				end
            end
        end	
    
        el = EntityList("shortestpath,alive,attackable,targetingme,onmesh,fateid="..tostring(fate.id))            
            
        if ( el ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                epos = shallowcopy(e.pos)
				local dist = Distance2D(epos.x,epos.z,fate.x,fate.z)
				if (dist <= fate.radius) then
					return e
				end
            end
        end
		
        el = EntityList("shortestpath,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",fateid="..tostring(fate.id))

        if ( el ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
				epos = shallowcopy(e.pos)
				local dist = Distance2D(epos.x,epos.z,fate.x,fate.z)
				if (dist <= fate.radius) then
					return e
				end
            end
        end	
    
        el = EntityList("shortestpath,alive,attackable,onmesh,fateid="..tostring(fate.id))            
            
        if ( el ) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                epos = shallowcopy(e.pos)
				local dist = Distance2D(epos.x,epos.z,fate.x,fate.z)
				if (dist <= fate.radius) then
					return e
				end
            end
        end
    end
    
    return nil
end

function GetHuntTarget()
	local nearest = nil
	local nearestDistance = 9999
	local excludeString = GetBlacklistIDString()
	local el = nil
	
	if (gHuntSRankHunt == "1") then
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
	end
	
	if (gHuntARankHunt == "1") then
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
	end
	
	if (gHuntBRankHunt == "1") then
		if (gHuntBRankHuntID ~= "") then
			if (excludeString) then
				el = EntityList("contentid="..tostring(gHuntBRankHuntID)..",alive,attackable,onmesh,exclude_contentid="..excludeString)
			else
				el = EntityList("contentid="..tostring(gHuntBRankHuntID)..",alive,attackable,onmesh")
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
		end
		
		if (gHuntBRankHuntAny == "1") then
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
		end
	end
	
	return nil
end

function IsValidHealTarget(e)
	if (ValidTable(e) and e.alive) then
		return (e.chartype == 4) or
			(e.chartype == 0 and (e.type == 2 or e.type == 3 or e.type == 5)) or
			(e.chartype == 3 and e.type == 2)
	end
	
	return false
end

function GetBestTankHealTarget( range )
	range = range or ml_global_information.AttackRange
	local lowest = nil
	local lowestHP = 101

    local el = EntityList("friendly,alive,chartype=4,myparty,targetable,maxdistance="..tostring(range))
    if ( el ) then
		for i,e in pairs(el) do
			if (IsTank(e.job) and e.hp.percent < lowestHP ) then
				lowest = e
				lowestHP = e.hp.percent
			end
        end
    end
	
	local ptrg = Player:GetTarget()
	if (ptrg and Player.pet) then
		if (lowest == nil and ptrg.targetid == Player.pet.id) then
			lowest = Player.pet
		end
	end
	
	return lowest
end

function GetBestPartyHealTarget( npc, range )
	npc = npc or false
	range = range or ml_global_information.AttackRange
	
	local el = EntityList("lowesthealth,alive,friendly,chartype=4,myparty,targetable,maxdistance="..tostring(range))
    if ( el ) then
        local i,e = next(el)
        if (i and e and IsValidHealTarget(e)) then
			return e
        end
    end
	
	if (npc) then
		el = EntityList("lowesthealth,alive,friendly,myparty,targetable,maxdistance="..tostring(range))
		if ( el ) then
			local i,e = next(el)
			if (i and e and IsValidHealTarget(e)) then
				return e
			end
		end
	end
	
	if (gBotMode == GetString("partyMode") and not IsLeader()) then
		local leader, isEntity = GetPartyLeader()
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
	
	local mpUsers = {
		[1] = true,
		[6] = true,
		[19] = true,
		[24] = true,
		[26] = true,
		[27] = true,
		[28] = true,
	}
	
    local el = EntityList("myparty,alive,type=1,targetable,maxdistance=35")
    if ( el ) then
		for i,e in pairs(el) do
			if (mpUsers[e.job] and e.mp.percent < lowestMP) then
				lowest = e
				lowestMP = e.mp.percent
			end
        end
    end
	
	if (Player.alive and mpUsers[Player.job] and Player.mp.percent < lowestMP) then
		lowest = Player
		lowestMP = Player.mp.percent
	end
	
	return lowest
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
		return false
	else
		if (not npc) then
			el = EntityList("myparty,alive,type=1,targetable,maxdistance="..tostring(range))
		else
			el = EntityList("myparty,alive,targetable,maxdistance="..tostring(range))
		end
		
		if ( el ) then
			for i,e in pairs(el) do
				if (IsValidHealTarget(e)) then
					if (not lowest or e.hp.percent < lowestHP) then
						lowest = e
						lowestHP = e.hp.percent
					end
				end
			end
		end
		
		if (Player.alive and Player.hp.percent < lowestHP) then
			lowest = Player
			lowestHP = Player.hp.percent
		end
		
		return lowest
	end
end

function GetLowestTPParty()
	local lowest = nil
	local lowestTP = 1001
	
	local tpUsers = {
		[1] = true,
		[2] = true,
		[3] = true,
		[4] = true,
		[5] = true,
		[19] = true,
		[20] = true,
		[21] = true,
		[22] = true,
		[23] = true,
	}
	
    local el = EntityList("myparty,alive,type=1,targetable,maxdistance=35")
    if ( el ) then
        for i,e in pairs(el) do
			if (e.job and tpUsers[e.job]) then
				if (e.tp < lowestTP) then
					lowest = e
					lowestTP = e.tp
				end
			end
        end
    end
	
	if (Player.alive and tpUsers[Player.job] and Player.tp < lowestTP) then
		lowest = Player
		lowestTP = Player.tp
	end
	
    return lowest
end

function GetBestHealTarget( npc, range )
	npc = npc or false
	range = range or ml_global_information.AttackRange
	
	local el = nil
	el = EntityList("lowesthealth,alive,friendly,chartype=4,targetable,maxdistance="..tostring(range))
	if ( el ) then
		local i,e = next(el)
		if (i~=nil and e~=nil) then
			if (IsValidHealTarget(e)) then
				return e
			end
		end
	end
	
	if (npc) then
		el = EntityList("lowesthealth,alive,friendly,targetable,maxdistance="..tostring(range))
		if ( el ) then
			local i,e = next(el)
			if (i~=nil and e~=nil) then
				if (IsValidHealTarget(e)) then
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
	range = 30
	
	local el = nil
	if (party) then
		el = EntityList("myparty,dead,maxdistance="..tostring(range))
	else
		el = EntityList("dead,maxdistance="..tostring(range))
	end 
								
	if ( el ) then
		if (role ~= "Any") then
			for i,e in pairs(el) do
				if (e.job ~= nil and GetRoleString(e.job) == role and MissingBuffs(e, "148")) then
					return e
				end 
			end  
		else
			for i,e in pairs(el) do
				if (MissingBuffs(e, "148")) then
					return e
				end
			end  
		end
	end
	
	if (gBotMode == GetString("partyMode") and not IsLeader()) then
		local leader, isEntity = GetPartyLeader()
		if (leader and leader.id ~= 0) then
			local leaderentity = EntityList:Get(leader.id)
			if (leaderentity and leaderentity.distance <= range and not leader.alive and MissingBuffs(leaderentity, "148")) then
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
    
	local enemyParty = nil
	if (Player.localmapid == 376 or Player.localmapid == 422) then
		enemyParty = EntityList("lowesthealth,onmesh,attackable,targetingme,alive,chartype=4,maxdistance=15")
		if(not ValidTable(enemyParty)) then
			enemyParty = EntityList("lowesthealth,onmesh,attackable,targetingme,alive,chartype=4,maxdistance=25")
		end
		if(not ValidTable(enemyParty)) then
			enemyParty = EntityList("lowesthealth,onmesh,attackable,alive,chartype=4,maxdistance=15")
		end
		if(not ValidTable(enemyParty)) then
			enemyParty = EntityList("lowesthealth,onmesh,attackable,alive,chartype=4,maxdistance=25")
		end
		if(not ValidTable(enemyParty)) then
			enemyParty = EntityList("lowesthealth,onmesh,attackable,alive,maxdistance=15")
		end
		if(not ValidTable(enemyParty)) then
			enemyParty = EntityList("lowesthealth,onmesh,attackable,alive,maxdistance=25")
		end
		if(not ValidTable(enemyParty)) then
			enemyParty = EntityList("shortestpath,onmesh,attackable,alive,chartype=4,maxdistance=45")
		end
		if(not ValidTable(enemyParty)) then
			enemyParty = EntityList("shortestpath,onmesh,attackable,alive,maxdistance=45")
		end
	else
		enemyParty = EntityList("onmesh,attackable,alive,chartype=4")
	end
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

function GetPrioritizedTarget( targetlist )
	--targetlist should be a semi-colon ";" separated string list
end

function GetDutyTarget( maxHP )
	maxHP = maxHP or nil
	local el = nil
	
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

function GetNearestGrindAggro()
	taskName = ml_task_hub:ThisTask().name
	
	if (not IsNullString(excludeString)) then
		if (taskName == "LT_GRIND") then
			el = EntityList("lowesthealth,alive,attackable,onmesh,targetingme,fateid=0,exclude_contentid="..excludeString..",maxdistance=30") 
		else
			el = EntityList("lowesthealth,alive,attackable,onmesh,targetingme,exclude_contentid="..excludeString..",maxdistance=30") 
		end
	else
		if (taskName == "LT_GRIND") then
			el = EntityList("lowesthealth,alive,attackable,onmesh,targetingme,fateid=0,maxdistance=30") 
		else
			el = EntityList("lowesthealth,alive,attackable,onmesh,targetingme,maxdistance=30") 
		end
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
					if (taskName == "LT_GRIND") then
						el = EntityList("lowesthealth,alive,attackable,onmesh,fateid=0,targeting="..tostring(member.id)..",exclude_contentid="..excludeString..",maxdistance=30")
					else
						el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",exclude_contentid="..excludeString..",maxdistance=30")
					end
				else
					if (taskName == "LT_GRIND") then
						el = EntityList("lowesthealth,alive,attackable,onmesh,fateid=0,targeting="..tostring(member.id)..",maxdistance=30")
					else
						el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",maxdistance=30")
					end
				end
				
				if ( el ) then
					local i,e = next(el)
					if (i~=nil and e~=nil) then
						return e
					end
				end
			end
		end
	end
    
    return nil
end

function GetNearestAggro()
	taskName = ml_task_hub:ThisTask().name
	
	if (not IsNullString(excludeString)) then
		if (taskName == "LT_GRIND") then
			el = EntityList("lowesthealth,alive,attackable,onmesh,targetingme,fateid=0,exclude_contentid="..excludeString..",maxdistance=30") 
		else
			el = EntityList("lowesthealth,alive,attackable,onmesh,targetingme,exclude_contentid="..excludeString..",maxdistance=30") 
		end
	else
		if (taskName == "LT_GRIND") then
			el = EntityList("lowesthealth,alive,attackable,onmesh,targetingme,fateid=0,maxdistance=30") 
		else
			el = EntityList("lowesthealth,alive,attackable,onmesh,targetingme,maxdistance=30") 
		end
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
					if (taskName == "LT_GRIND") then
						el = EntityList("lowesthealth,alive,attackable,onmesh,fateid=0,targeting="..tostring(member.id)..",exclude_contentid="..excludeString..",maxdistance=30")
					else
						el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",exclude_contentid="..excludeString..",maxdistance=30")
					end
				else
					if (taskName == "LT_GRIND") then
						el = EntityList("lowesthealth,alive,attackable,onmesh,fateid=0,targeting="..tostring(member.id)..",maxdistance=30")
					else
						el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",maxdistance=30")
					end
				end
				
				if ( el ) then
					local i,e = next(el)
					if (i~=nil and e~=nil) then
						return e
					end
				end
			end
		end
	end
    
    return nil
end

function RoundUp(number, multiple)
	local number = tonumber(number)
	local multiple = tonumber(multiple)
	
	return (math.floor(((number + (multiple - 1)) / multiple)) * multiple)
end

function GetNearestGatherable(minlevel,maxlevel)
    local el = nil
    local whitelist = nil
    local blacklist = nil
	
	if (ValidTable(ml_task_hub:ThisTask().currentMarker)) then
		whitelist = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(GetString("contentIDEquals"))
		blacklist = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(GetString("NOTcontentIDEquals"))
	end
    
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

function GetNearestUnspoiled(class)
	--Rocky Outcrop = 6
	--Mining Node = 5
	--Mature Tree = 7
	--Vegetation = 8
	local contentID = (class == FFXIV.JOBS.MINER) and "5;6" or "7;8"
    local el = EntityList("shortestpath,onmesh,gatherable,contentid="..tostring(contentID))
    
    if ( el ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
	
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
				if (buff.id == tonumber(_andid) 
					and (duration == 0 or buff.duration > duration or HasInfiniteDuration(buff.id)) 
					and (owner == 0 or buff.ownerid == owner)) 
				then 
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
				if (buff.id == tonumber(_andid) 
					and (duration == 0 or buff.duration > duration or HasInfiniteDuration(buff.id))
					and (owner == 0 or buff.ownerid == owner)) 
				then
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

function HasInfiniteDuration(id)
	infiniteDurationAbilities = {
		[614] = true,
	}
	
	return infiniteDurationAbilities[id] or false
end

function ActionList:IsCasting()
	return (Player.castinginfo.channelingid ~= 0 or Player.castinginfo.castid == 4)
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

function IsReviveSkill(skillID)
    if (skillID == 173 or skillID == 125) then
        return true
    end
    return false
end

function IsHealingSkill(skillID)
	local id = tonumber(skillID)
	
	local cures = {
		[120] = true,
		[135] = true,
		[131] = true,
		[190] = true,
		[185] = true,
		[186] = true,
		[189] = true,
	}
    if (cures[id]) then
        return true
    end
    return false
end

function IsMudraSkill(skillID)
	local id = tonumber(skillID)
	
	local mudras = {
		[2261] = true,
		[2259] = true,
		[2263] = true,
	}
    if (mudras[id]) then
        return true
    end
    return false
end

function IsNinjutsuSkill(skillID)
	local id = tonumber(skillID)
	
	local ninjutsus = {
		[2260] = true,
		[2265] = true,
		[2266] = true,
		[2267] = true,
		[2268] = true,
		[2269] = true,
		[2270] = true,
		[2271] = true,
		[2272] = true,
	}
    if (ninjutsus[id]) then
        return true
    end
    return false
end

function IsUncoverSkill(skillID)
	return (skillID == 214 or skillID == 231)
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
        local leftover = math.abs(absDeviation - math.pi)
		
        if ((leftover < (math.pi * 1.75) and leftover > (math.pi * 1.25)) or
			(leftover < (math.pi * .75) and leftover > (math.pi * .25))) 
		then
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
        local leftover = math.abs(absDeviation - math.pi)
		
        if (leftover > (math.pi * 1.75) or leftover < (math.pi * .25))then
            return true
        end
    end
    return false
end

function IsFront(entity)
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
        local leftover = math.abs(absDeviation - math.pi)
		
        if (leftover > (math.pi * .75) and leftover < (math.pi * 1.25)) then
            return true
        end
    end
    return false
end

function EntityIsFront(entity)
	if not entity or entity.id == Player.id then return false end
	
	local playerHeading = nil
	if (Player.pos.h < 0) then
		playerHeading = Player.pos.h + 2 * math.pi
	else
		playerHeading = Player.pos.h
	end
	
	local playerAngle = math.atan2(entity.pos.x - Player.pos.x, entity.pos.z - Player.pos.z)  	
	local deviation = playerAngle - playerHeading
	local absDeviation = math.abs(deviation)
	
	local leftover = math.abs(absDeviation - math.pi)
	
	if (leftover > (math.pi * .75)) then
		return true
	end
		
    return false
end

function Distance3DT(pos1,pos2)
	assert(type(pos1) == "table","Distance3DT - expected type table for first argument")
	assert(type(pos2) == "table","Distance3DT - expected type table for second argument")
	
	local distance = Distance3D(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z)
	return distance
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

function PosIsEqual(pos1, pos2)
	if (type(pos1) == "table" and type(pos2) == "table") then
		if (pos1.x and pos1.y and pos1.z and pos2.x and pos2.y and pos2.z) then
			if (tonumber(pos1.x) == tonumber(pos2.x) and tonumber(pos1.y) == tonumber(pos2.y) and tonumber(pos1.z) == tonumber(pos2.z)) then
				return true
			end
		end
	end
	return false
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
		local myPos = shallowcopy(Player.pos)
		local whitelistString = ml_blacklist.GetExcludeString("FATE Whitelist")
		local whitelistTable = {}
		
		if (not IsNullString(whitelistString)) then
			for entry in StringSplit(whitelistString,";") do
				local delimiter = entry:find('-')
				if (delimiter ~= nil and delimiter ~= 0) then
					local mapid = entry:sub(0,delimiter-1)
					local fateid = entry:sub(delimiter+1)
					if (tonumber(mapid) == Player.localmapid) then
						whitelistTable[fateid] = true
					end
				end
			end
		end
		
		if (ValidTable(whitelistTable)) then
			for k, fate in pairs(fateList) do
				if (whitelistTable[fate.id] and	fate.status == 2 and fate.completion >= tonumber(gFateWaitPercent)) then	
					local p,dist = NavigationManager:GetClosestPointOnMesh({x=fate.x, y=fate.y, z=fate.z},false)
					if (dist <= 5) then
						--local distance = PathDistance(NavigationManager:GetPath(myPos.x,myPos.y,myPos.z,p.x,p.y,p.z))
						local distance = Distance3D(myPos.x,myPos.y,myPos.z,p.x,p.y,p.z)
						if (distance) then
							if (not nearestFate or (nearestFate and (distance < nearestDistance))) then
								nearestFate = shallowcopy(fate)
								nearestDistance = distance
							end
						end
					end
				end
			end
		else
			for k, fate in pairs(fateList) do
				if (not ml_blacklist.CheckBlacklistEntry("Fates", fate.id) and 
					(fate.status == 2 or (fate.status == 7 and Distance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z) < 50))
					and fate.completion >= tonumber(gFateWaitPercent)) 
				then	
					if ( (tonumber(gMinFateLevel) == 0 or (fate.level >= level - tonumber(gMinFateLevel))) and 
						 (tonumber(gMaxFateLevel) == 0 or (fate.level <= level + tonumber(gMaxFateLevel))) ) then
						--d("DIST TO FATE :".."ID"..tostring(fate.id).." "..tostring(NavigationManager:GetPointToMeshDistance({x=fate.x, y=fate.y, z=fate.z})) .. " ONMESH: "..tostring(NavigationManager:IsOnMesh(fate.x, fate.y, fate.z)))
						local p,dist = NavigationManager:GetClosestPointOnMesh({x=fate.x, y=fate.y, z=fate.z},false)
						if (dist <= 5) then
							--local distance = PathDistance(NavigationManager:GetPath(myPos.x,myPos.y,myPos.z,p.x,p.y,p.z))
							local distance = Distance3D(myPos.x,myPos.y,myPos.z,p.x,p.y,p.z) or 0
							if (distance ~= 0) then
								if (not nearestFate or (nearestFate and (distance < nearestDistance))) then
									nearestFate = shallowcopy(fate)
									nearestDistance = distance
								end
							end
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

function IsOnMap(mapid)
	local mapid = tonumber(mapid)
	if (Player.localmapid == mapid) then
		return true
	end
	
	return false
end

function ScanForMobs(ids,distance)
	local ids = (type(ids) == "string" and ids) or tostring(ids)
	local maxdistance = tonumber(distance) or 30
	local el = EntityList("nearest,targetable,alive,contentid="..ids..",maxdistance="..tostring(maxdistance))
	if (ValidTable(el)) then
		for i,e in pairs(el) do
			if (ValidTable(e)) then
				return true
			end
		end
	end
	
	return false
end

function ScanForObjects(ids,distance)
	local ids = (type(ids) == "string" and ids) or tostring(ids)
	local maxdistance = tonumber(distance) or 30
	local el = EntityList("nearest,targetable,contentid="..ids..",maxdistance="..tostring(maxdistance))
	if (ValidTable(el)) then
		for i,e in pairs(el) do
			if (ValidTable(e)) then
				return true
			end
		end
	end
	
	return false
end

function PathDistanceTest()
	PathDistanceTable({x=3.399,y=39.517,z=7.191})
end

function PathDistanceTable(gotoPos)
	if (ValidTable(gotoPos)) then
		local ppos = Player.pos
		local path = NavigationManager:GetPath(ppos.x,ppos.y,ppos.z,gotoPos.x,gotoPos.y,gotoPos.z)
		
		local prevPos = nil
		for k,v in pairsByKeys(path) do
			if (prevPos == nil) then
				d("Distance:"..tostring(Distance3D(ppos.x,ppos.y,ppos.z,v.x,v.y,v.z)))
			else
				d("Distance:"..tostring(Distance3D(prevPos.x,prevPos.y,prevPos.z,v.x,v.y,v.z)))
			end
			prevPos = {x=v.x,y=v.y,z=v.z}
		end
		
		--[[
		local dist
		if ( pathdist ) then
			local pdist = PathDistance(pathdist)
			if ( pdist ~= nil ) then
				dist = pdist
			else
				dist = Distance3DT(gotoPos,ppos)
			end
		else
			dist = Distance3DT(gotoPos,ppos)
		end	
		--]]
	end
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
		local el = EntityList("type=1,name="..gPartyLeaderName)
			if (ValidTable(el)) then
				local i,leaderentity = next (el)
				if (i and leaderentity) then
					return leaderentity, true
				end
			end
		end
	else
		local leader = nil
		local isEntity = false
		local party = EntityList.myparty
		if (ValidTable(party)) then
			for i,member in pairs(party) do
				if member.isleader then
					leader = member
					isEntity = false
				end
			end
		end
		
		if (leader) then
			local el = EntityList("type=1,name="..leader.name)
			if (ValidTable(el)) then
				local i,leaderentity = next (el)
				if (i and leaderentity) then
					leader = leaderentity
					isEntity = true
				end
			end
		end
		
		if (leader) then
			return leader, isEntity
		end
	end 
    
    return nil	    
end

function GetPartyLeaderPos()
	local pos = nil
	
	local leader, isEntity = GetPartyLeader()
    if (leader) then
		if (leader.pos.x ~= -1000) then
			pos = shallowcopy(leader.pos)
		end
	end
	
	return pos
end

function IsInParty(id)
	local found = false
	local party = EntityList.myparty
	if (ValidTable(party)) then
		for i, member in pairs(party) do
			if member.id == id then
				return true
			end
		end
	end
	return false
end

function InCombatRange(targetid)
	if (gBotRunning == "0") then
		return false
	end
	
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
	
	local highestRange = 0
	local charge = false
	local skillID = nil
	
	if ( TableSize(SkillMgr.SkillProfile) > 0 ) then
		for prio,skill in spairs(SkillMgr.SkillProfile) do
			local skilldata = ActionList:Get(tonumber(skill.id))
			if (skilldata) then
				if ( skilldata.range > 0 and skill.used == "1" and skilldata.range > highestRange and ActionList:CanCast(tonumber(skill.id),target.id)) then
					if ((ml_global_information.AttackRange < 5 and skilldata.isready) or ml_global_information.AttackRange >= 5) then
						skillID = tonumber(skill.id)
						highestRange = tonumber(skilldata.range)
						charge = (skill.charge == "1" and true) or false
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

	--d("attackRange:"..tostring(ml_global_information.AttackRange))
	if ( ml_global_information.AttackRange < 5 ) then
		if (skillID ~= nil) then
			if (highestRange > 5) then
				if ((target.targetid == 0 or target.targetid == nil) and ml_task_hub:RootTask().name ~= "LT_PVP") then
					if ((target.distance - target.hitradius) <= (highestRange * (tonumber(gCombatRangePercent) / 100))) then
						if SkillMgr.Cast( target ) then
							local pos = target.pos
							SetFacing(pos.x,pos.y,pos.z)
							return true
						end
					end
				elseif (charge) then
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

function IsMounting()
	return (Player.action == 83 or Player.action == 84 or Player.action == 165)
end

function IsMounted()
	return (Player.ismounted or Player.action == 166)
end

function IsDismounting()
	return (Player.action == 32)
end

function IsPositionLocked()
	return not ActionIsReady(2,5)
end

function IsLoading()
	return (Quest:IsLoading() or Player.localmapid == 0)
end

function HasAction(id, category)
	id = tonumber(id) or 0
	category = category or 1
	
	if (id ~= 0) then
		local actions = ActionList("type="..tostring(category))
		if (ValidTable(actions)) then
			for k,v in pairsByKeys(actions) do
				if (v.id == id) then
					return true
				end
			end
		end
	end
	return false			
end

function ActionIsReady(id, category)
	id = tonumber(id) or 0
	category = category or 1
	
	if (HasAction(id, category)) then
		local action = ActionList:Get(id,category)
		if (action and action.isready) then
			return true
		end
	end
	return false
end

function Mount(id)
	local mountID = id or 0
	local actions = nil
	
	if (IsMounted() or IsMounting()) then
		ml_debug("Cannot mount while mounted or mounting.")
		return
	end
	
	--If we weren't passed an id (party-grind), look it up.
	if (mountID == 0) then
		actions = ActionList("type=13")
		for k,v in pairsByKeys(actions) do
			if (v.name == gMount) then
				mountID = v.id
			end
		end
	end
		
	--Check to see if the mountID is not 1, in which case the chocobo companion needs to be dismissed first.
	if (mountID ~= 1) then
		actions = ActionList("type=6")
		if (ValidTable(actions)) then
			for k,v in pairsByKeys(actions) do
				if (v.id == 2) then
					local acDismiss = ActionList:Get(2,6)
					if (acDismiss and acDismiss.isready) then
						acDismiss:Cast()
						return 
					end
				end
			end
		end
	end
	
	if (mountID ~= 0) then
		actions = ActionList("type=13")
		for k,v in pairsByKeys(actions) do
			if (v.id == mountID) then
				local acMount = ActionList:Get(mountID,13)
				if (acMount and acMount.isready) then
					acMount:Cast()
					ml_task_hub:CurrentTask():SetDelay(1000)
				end
			end
		end
	end			
end

function Dismount()
	if (Player.ismounted) then
		local mountlist = ActionList("type=13")
		
		if ( TableSize( mountlist) > 0 ) then
			for k,mount in pairs(mountlist) do
				if (gMount == mount.name) then
					mountID = mount.id
				end
			end
		end
		
		local acMount = ActionList:Get(mountID,13)
		if ( acMount ) then
			if (acMount.isready) then
				acMount:Cast()
			end
		else
			ml_error("You need to select a Mount in the Minion Settings!")
		end
	end
end

function Repair()
	if (gRepair == "1") then
		local eq = Inventory("type=1000")
		for i,e in pairs(eq) do
			if (e.condition <= 30) then
				e:Repair()
			end
		end
	end
end

function ShouldEat()
	local foodID = nil
	if (gFoodHQ ~= "None") then
		foodID = ffxivminion.foodsHQ[gFoodHQ]
	elseif (gFood ~= "None") then
		foodID = ffxivminion.foods[gFood]
	end
			
	if (foodID) then
		local food = Inventory:Get(foodID)
		if (TableSize(food) > 0 and not HasBuffs(Player,"48")) then
			return true
		end
	end
	return false
end
	
function Eat()
	local foodID = nil
	if (gFoodHQ ~= "None") then
		foodID = ffxivminion.foodsHQ[gFoodHQ]
	elseif (gFood ~= "None") then
		foodID = ffxivminion.foods[gFood]
	end
			
	if (foodID) then
	local food = Inventory:Get(foodID)
	if (TableSize(food) > 0 and not HasBuffs(Player,"48")) then
		food:Use()
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
	local itemid = tonumber(itemid) or 0
	return (itemid >= 6687 and itemid <= 6692)
end

function IsGardening(itemid)
	local itemid = tonumber(itemid) or 0
	return ((itemid >= 7715 and itemid <= 7767) 
			or itemid == 8024
			or itemid == 5365)
end

function IsChocoboFood(itemid)
	local itemid = tonumber(itemid) or 0
	return (itemid >= 10094 and itemid <= 10098)
end

function IsChocoboFoodSpecial(itemid)
	local itemid = tonumber(itemid) or 0
	
	local special = {
		[10098] = true,
		[10095] = true,
	}
	return special[itemid]
end

function IsUnspoiled(contentid)
	return contentid == 5 or contentid == 6 or 
			contentid == 7 or contentid == 8
end

--===========================
--Class/Role Helpers
--===========================

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
        jobID == FFXIV.JOBS.THAUMATURGE or
		jobID == FFXIV.JOBS.ROGUE or
		jobID == FFXIV.JOBS.NINJA
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
	local jobID = tonumber(jobID)
	return 	jobID == FFXIV.JOBS.MONK or
			jobID == FFXIV.JOBS.PUGILIST or
			jobID == FFXIV.JOBS.DRAGOON or
			jobID == FFXIV.JOBS.LANCER or
			jobID == FFXIV.JOBS.ROGUE or
			jobID == FFXIV.JOBS.NINJA
end

function IsRangedDPS(jobID)
	local jobID = tonumber(jobID)
	return 	jobID == FFXIV.JOBS.ARCANIST or
			jobID == FFXIV.JOBS.ARCHER or
			jobID == FFXIV.JOBS.BARD or
			jobID == FFXIV.JOBS.BLACKMAGE or
			jobID == FFXIV.JOBS.SUMMONER or
			jobID == FFXIV.JOBS.THAUMATURGE
end

function IsRanged(jobID)
	local jobID = tonumber(jobID)
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

function IsPhysicalDPS(jobID)
	local jobID = tonumber(jobID)
	return 	jobID == FFXIV.JOBS.MONK or
			jobID == FFXIV.JOBS.PUGILIST or
			jobID == FFXIV.JOBS.DRAGOON or
			jobID == FFXIV.JOBS.LANCER or
			jobID == FFXIV.JOBS.ROGUE or
			jobID == FFXIV.JOBS.NINJA or 
			jobID == FFXIV.JOBS.ARCHER or
			jobID == FFXIV.JOBS.BARD
end

function IsCasterDPS(jobID)
	local jobID = tonumber(jobID)
	return 	jobID == FFXIV.JOBS.ARCANIST or
			jobID == FFXIV.JOBS.BLACKMAGE or
			jobID == FFXIV.JOBS.SUMMONER or
			jobID == FFXIV.JOBS.THAUMATURGE
end

function IsCaster(jobID)
	local jobID = tonumber(jobID)
	return 	jobID == FFXIV.JOBS.ARCANIST or
			jobID == FFXIV.JOBS.BLACKMAGE or
			jobID == FFXIV.JOBS.SUMMONER or
			jobID == FFXIV.JOBS.THAUMATURGE or
			jobID == FFXIV.JOBS.WHITEMAGE or
			jobID == FFXIV.JOBS.CONJURER or
			jobID == FFXIV.JOBS.SCHOLAR
end

function IsTank(jobID)
	local jobID = tonumber(jobID)
	local tanks = {
		[FFXIV.JOBS.GLADIATOR] = true,
		[FFXIV.JOBS.MARAUDER] = true,
		[FFXIV.JOBS.PALADIN] = true,
		[FFXIV.JOBS.WARRIOR] = true,
	}
	
	return tanks[jobID]
end

function IsGatherer(jobID)
	local jobID = tonumber(jobID)
	if (jobID >= 16 and jobID <= 17) then
		return true
	end
	
	return false
end

function IsFighter(jobID)
	local jobID = tonumber(jobID)
	if ((jobID >= 0 and jobID <= 8) or
		(jobID >= 19))
	then
		return true
	end
	
	return false
end

function IsCrafter(jobID)
	local jobID = tonumber(jobID)
	if (jobID >= 8 and jobID <= 15) then
		return true
	end
	
	return false
end

function IsFisher(jobID)
	local jobID = tonumber(jobID)
	return jobID == 18
end

function PartyMemberWithBuff(hasbuffs, hasnot, maxdistance) 
	if (maxdistance==nil or maxdistance == "") then
		maxdistance = 30
	end
	
	local el = EntityList("myparty,alive,chartype=4,maxdistance="..tostring(maxdistance)..",targetable")
	for i,e in pairs(el) do	
		if ( (hasbuffs=="" or HasBuffs(e,hasbuffs)) and (hasnot=="" or not MissingBuffs(e,hasnot)) ) then
			return e
		end						
	end
	
	return nil
end

function PartySMemberWithBuff(hasbuffs, hasnot, maxdistance) 
	maxdistance = maxdistance or 30
 
	local el = EntityList("myparty,alive,chartype=4,maxdistance="..tostring(maxdistance)..",targetable")
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

function GetAttunedAetheryteList()
	local attuned = {}
	local list = Player:GetAetheryteList()
	for id,aetheryte in pairsByKeys(list) do
		if (aetheryte.isattuned) then
			table.insert(attuned, aetheryte)
		end
	end
	
	return attuned
end

function GetAetheryteByID(id)
	local aethid = tonumber(id) or 0
	local list = Player:GetAetheryteList()
    for index,aetheryte in pairsByKeys(list) do
        if (aetheryte.id == aethid) then
            return aetheryte
        end
    end
    
    return nil
end

function GetAetheryteByMapID(id, p)
	local pos = p
	
	local mapid = Player.localmapid
	if (id == 133 and mapid ~= 132) then
		id = 132
	elseif (id == 128 and mapid ~= 129) then
		id = 129
	elseif (id == 131 and mapid ~= 130) then
		id = 130
	end
	
	if 	(mapid == 131 and id == 130) or
		(mapid == 128 and id == 129) or
		(mapid == 133 and id == 133)
	then
		return nil
	end
	
	sharedMaps = {
		[153] = { name = "South Shroud",
			[1] = { name = "Quarrymill", id = 5, x = 177, z = -65},
			[2] = { name = "Camp Tranquil", id = 6, x = -229, z = 352},
		},
		[137] = {name = "Eastern La Noscea",
			[1] = { name = "Costa Del Sol", id = 11, x = 0, z = 0},
			[2] = { name = "Wineport", id = 12, x = 0, z = 0},
		},
		[138] = {name = "Western La Noscea",
			[1] = { name = "Swiftperch", id = 13, x = 652, z = -507},
			[2] = { name = "Aleport", id = 14, x = 261, z = 223},
		},
		[146] = {name = "Southern Thanalan",
			[1] = { name = "Little Ala Mhigo", id = 19, x = -152, z = -419},
			[2] = { name = "Forgotten Springs", id = 20, x = 330, z = 405},
		},
		[147] = {name = "Northern Thanalan",
			[1] = { name = "Bluefog", id = 21, x = 24, z = 452},
			[2] = { name = "Ceruleum", id = 22, x = -33, z = -32},
		},
	}
	
	local list = GetAttunedAetheryteList()
	if (not pos or not sharedMaps[id]) then
		for index,aetheryte in ipairs(list) do
			if (aetheryte.territory == id) then
				return id, aetheryte.id
			end
		end
	else
		local map = sharedMaps[id]
		if (id == 153 or id == 138 or id == 146 or id == 147) then
			local distance1 = Distance2D(pos.x, pos.z, map[1].x, map[1].z)
			local distance2 = Distance2D(pos.x, pos.z, map[2].x, map[2].z)
			return id, ((distance1 < distance2) and map[1].id) or map[2].id
		elseif (id == 137) then
			return id, ((pos.x > 218 and pos.z > 51) and map[1].id) or map[2].id
		end
	end
	
	return nil
end

function GetAetheryteLocation(id)
	local aethid = tonumber(id) or 0
	aetherytes = 
	{
		[8] = {
			mapid = 129, x = -85.681526184082, y = 18.800333023071, z = -6.4848699569702
		},
		[52] = {
			mapid = 134, x = 224.27067565918, y = 113.09999084473, z = -261.05822753906
		},
		[10] = {
			mapid = 135, x = 156.93988037109, y = 14.09584903717, z = 668.01940917969
		},
		[11] = {
			mapid = 137, x = 490.56713867188, y = 17.416807174683, z = 474.01110839844
		},
		[12] = {
			mapid = 137, x = -20.159227371216, y = 70.599250793457, z = 7.4133810997009
		},
		[14] = {
			mapid = 138, x = 259.89932250977, y = -22.75, z = 223.38513183594
		},
		[13] = {
			mapid = 138, x = 652.9736328125, y = 9.2408666610718, z = 509.41586303711
		},
		[15] = {
			mapid = 139, x = 433.61944580078, y = 3.6090106964111, z = 92.736114501953
		},
		[16] = {
			mapid = 180, x = -122.27465820313, y = 64.79615020752, z = -211.87341308594
		},
		[2] = {
			mapid = 132, x = 30.390216827393, y = 1.8258748054504, z = 26.265508651733
		},
		[3] = {
			mapid = 148, x = 13.585005760193, y = -1.1827243566513, z = 41.725193023682
		},
		[4] = {
			mapid = 152, x = -189.0665435791, y = 4.4424576759338, z = 293.23275756836
		},
		[5] = {
			mapid = 153, x = 181.93789672852, y = 8.6657190322876, z = -66.213958740234
		},
		[6] = {
			mapid = 153, x = -226.1929473877, y = 21.010675430298, z = 355.90420532227
		},
		[7] = {
			mapid = 154, x = -45.544578552246, y = -39.256271362305, z = 230.90368652344
		},
		[9] = {
			mapid = 130, x = -143.30297851563, y = -3.1548881530762, z = -165.79141235352
		},
		[17] = {
			mapid = 140, x = 71.629104614258, y = 45.432174682617, z = -230.00273132324
		},
		[53] = {
			mapid = 141, x = -15.56315612793, y = -1.8785282373428, z = -169.75825500488
		},
		[18] = {
			mapid = 145, x = -379.7414855957, y = -59, z = 142.57489013672
		},
		[19] = {
			mapid = 146, x = -165.46360778809, y = 26.138355255127, z = -414.46130371094
		},
		[20] = {
			mapid = 146, x = -321.84567260742, y = 8.2604389190674, z = 406.19985961914
		},
		[21] = {
			mapid = 147, x = 21.909135818481, y = 6.9785833358765, z = 458.83193969727
		},
		[22] = {
			mapid = 147, x = -24.236480712891, y = 48.309478759766, z = -27.79927444458
		},
		[23] = {
			mapid = 155, x = 227.28480529785, y = 312, z = -229.6822052002
		},
		[24] = {
			mapid = 156, x = 48.166370391846, y = 20.295000076294, z = -667.26159667969
		},
		[55] = {
			mapid = 250, x = 41.127487182617, y = 5.5999984741211, z = -8.2964677810669
		},
	}
	
	local aetheryte = aetherytes[aethid]
	if (aetheryte) then
		return {x = aetheryte.x, y = aetheryte.y, z = aetheryte.z}
	end
	
	return nil
end

function GetClosestAetheryteToMapIDPos(id, p)
	local pos = p
	
	local mapid = Player.localmapid
	if (id == 133 and mapid ~= 132) then
		id = 132
	elseif (id == 128 and mapid ~= 129) then
		id = 129
	elseif (id == 131 and mapid ~= 130) then
		id = 130
	end
	
	if 	(mapid == 131 and id == 130) or
		(mapid == 128 and id == 129) or
		(mapid == 133 and id == 133)
	then
		return nil
	end
	
	sharedMaps = {
		[153] = { name = "South Shroud",
			[1] = { name = "Quarrymill", id = 5, x = 177, z = -65},
			[2] = { name = "Camp Tranquil", id = 6, x = -229, z = 352},
		},
		[137] = {name = "Eastern La Noscea",
			[1] = { name = "Costa Del Sol", id = 11, x = 0, z = 0},
			[2] = { name = "Wineport", id = 12, x = 0, z = 0},
		},
		[138] = {name = "Western La Noscea",
			[1] = { name = "Swiftperch", id = 13, x = 652, z = -507},
			[2] = { name = "Aleport", id = 14, x = 261, z = 223},
		},
		[146] = {name = "Southern Thanalan",
			[1] = { name = "Little Ala Mhigo", id = 19, x = -152, z = -419},
			[2] = { name = "Forgotten Springs", id = 20, x = 330, z = 405},
		},
		[147] = {name = "Northern Thanalan",
			[1] = { name = "Bluefog", id = 21, x = 24, z = 452},
			[2] = { name = "Ceruleum", id = 22, x = -33, z = -32},
		},
	}
	
	local list = GetAttunedAetheryteList()
	if (sharedMaps[id] == nil) then
		for index,aetheryte in ipairs(list) do
			if (aetheryte.territory == id) then
				return aetheryte.id
			end
		end
	else
		local map = sharedMaps[id]
		if (id == 153 or id == 138 or id == 146 or id == 147) then
			local distance1 = Distance2D(pos.x, pos.z, map[1].x, map[1].z)
			local distance2 = Distance2D(pos.x, pos.z, map[2].x, map[2].z)
			return ((distance1 < distance2) and map[1].id) or map[2].id
		elseif (id == 137) then
			return ((pos.x > 218 and pos.z > 51) and map[1].id) or map[2].id
		end
	end
	
	return nil
end

function GetOffMapMarkerPos(strMeshName, strMarkerName)
	local newMarkerPos = nil
	
	local markerPath = ml_mesh_mgr.navmeshfilepath..strMeshName..".info"
	if (FileExists(markerPath)) then
		local markerList = persistence.load(markerPath)
		local markerName = strMarkerName
		
		local searchMarker = nil
		for _, list in pairs(markerList) do
			for name, marker in pairs(list) do
				if (name == markerName) then
					searchMarker = marker
				end
				if (searchMarker) then
					break
				end
			end
			if (searchMarker) then
				break
			end
		end
		if (searchMarker) then
			local markerFields = searchMarker.fields
			if (markerFields["x"] and markerFields["y"] and markerFields["z"]) then
				newMarkerPos = { x = markerFields["x"].value, y = markerFields["y"].value, z = markerFields["z"].value }
			end
		end
	end
	
	return newMarkerPos
end

function ShouldTeleport()
	if (IsPositionLocked() or IsLoading() or ControlVisible("SelectString") or ControlVisible("SelectIconString") or IsShopWindowOpen()) then
		return true
	end
	
	if (gTeleport == "0") then
		return false
	elseif (ml_task_hub:CurrentTask().noTeleport) then
		return false
	else
		if (gParanoid == "0") then
			return true
		else
			local scanDistance = 50
			if (gBotMode == GetString("gatherMode")) then
				scanDistance = 100
			end
			local players = EntityList("type=1,maxdistance=".. scanDistance)
			local nearbyPlayers = TableSize(players)
			if nearbyPlayers > 0 then
				return false
			end
			return true
		end
	end
end

function GetBlacklistIDString()
    -- otherwise first grab the global blacklist exclude string
    local excludeString = ml_blacklist.GetExcludeString(strings[gCurrentLanguage].monsters)
    
    -- then add on any local contentIDs to exclude
    if (ml_global_information.BlacklistContentID and ml_global_information.BlacklistContentID ~= "") then
		if (excludeString) then
			excludeString = excludeString..";"..ml_global_information.BlacklistContentID
		else
			d("BlacklistIDString:"..tostring(ml_global_information.BlacklistContentID))
			excludeString = ml_global_information.BlacklistContentID
		end
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
						
	if (level < 12) then
		if (inthanalan) then
			return 140 --western than
		elseif (inshroud) then
			return 148 --central shroud
		elseif (inlanoscea) then
			return 134 --middle la noscea
		end
	elseif ( level >= 12 and level < 20) then
		if (inthanalan) then
			return 140 --western than
		elseif (inshroud) then
			return 152 --east shroud
		elseif (inlanoscea) then
			return 138 --middle la noscea
		end
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

function CheckSlotLevels(slotids,level)
	--[[
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
	--]]
	
	local slotids = tostring(slotids)
	local level = tonumber(level)
	for slot in StringSplit(slotids,",") do
		local equipped = Inventory("type=1000")
		local itemFound = false
		for i,item in pairs(equipped) do
			if (item.slot == tonumber(slot)) then
				itemFound = true
				if (item.level < level) then
					return false
				end
			end
		end
		if (itemFound) then
			break
		end
		if (not itemFound) then
			return false
		end
	end
	
	return true
end

function FindItemsBySlot(slot,ui)
	local slot = tonumber(slot)
	local ui = tonumber(ui)
	local items = {}
	
	--Look through regular bags first.
	for x=0,3 do
		local inv = Inventory("type="..tostring(x))
		for i, item in pairs(inv) do
			if (ValidTable(item) and item.requiredlevel > 0) then
				if (item.requiredlevel <= Player.level) then
					local isHQ = item.IsHQ == 1
					local itemid = (isHQ and (item.id - 1000000)) or item.id
					local itemDetails = ffxiv_item_data[itemid]
					if (itemDetails and itemDetails.slot == slot and itemDetails.ui == ui) then
						itemDetails.hq = isHQ
						items[item.id] = itemDetails
					end
				end
			end
		end
	end
	
	--Look through armory bags for off-hand through wrists
	for x=3200,3209 do
		local inv = Inventory("type="..tostring(x))
		for i, item in pairs(inv) do
			if (ValidTable(item) and item.requiredlevel > 0) then
				if (item.requiredlevel <= Player.level) then
					local isHQ = item.IsHQ == 1
					local itemid = (isHQ and (item.id - 1000000)) or item.id
					local itemDetails = ffxiv_item_data[itemid]
					if (itemDetails and itemDetails.slot == slot and itemDetails.ui == ui) then
						itemDetails.hq = isHQ
						items[item.id] = itemDetails
					end
				end
			end
		end
	end
	
	--Look through rings armory bag.
	local inv = Inventory("type=3300")
	for i, item in pairs(inv) do
		if (ValidTable(item) and item.requiredlevel > 0) then
			if (item.requiredlevel <= Player.level) then
				local isHQ = item.IsHQ == 1
				local itemid = (isHQ and (item.id - 1000000)) or item.id
				local itemDetails = ffxiv_item_data[itemid]
				if (itemDetails and itemDetails.slot == slot and itemDetails.ui == ui) then
					itemDetails.hq = isHQ
					items[item.id] = itemDetails
				end
			end
		end
	end
	
	--Look through soulstone armory bag.
	local inv = Inventory("type=3400")
	for i, item in pairs(inv) do
		if (ValidTable(item) and item.requiredlevel > 0) then
			if (item.requiredlevel <= Player.level) then
				local itemid = item.id
				local itemDetails = ffxiv_item_data[itemid]
				if (itemDetails and itemDetails.slot == slot and itemDetails.ui == ui) then
					itemDetails.hq = false
					items[item.id] = itemDetails
				end
			end
		end
	end
	
	--Look through weapons armory bag.
	local inv = Inventory("type=3500")
	for i, item in pairs(inv) do
		if (ValidTable(item) and item.requiredlevel > 0) then
			if (item.requiredlevel <= Player.level) then
				local isHQ = item.IsHQ == 1
				local itemid = (isHQ and (item.id - 1000000)) or item.id
				local itemDetails = ffxiv_item_data[itemid]
				if (itemDetails and itemDetails.slot == slot and itemDetails.ui == ui) then
					itemDetails.hq = isHQ
					items[item.id] = itemDetails
				end
			end
		end
	end
	
	for id,item in pairs(items) do
		if (not item.classes[Player.job]) then
			items[id] = nil
		end
	end
	
	return items
end

function EquipItem(itemID, itemtype)
	local itemtype = itemtype or 0
	local item = Inventory:Get(itemID)
	if(ValidTable(item) and item.type ~= FFXIV.INVENTORYTYPE.INV_EQUIPPED) then
		if (itemtype ~= 0) then
			item:Move(1000,itemtype)
		else
			item:Move(1000,GetEquipSlotForItem(item))
		end
	end
end

function IsEquipped(itemid)
	local itemid = tonumber(itemid)
	local currEquippedItems = Inventory("type=1000")
	for id,item in pairs(currEquippedItems) do
		if(item.id == itemid) then
			return true
		end
	end
	return false
end

function GetItemInSlot(equipSlot)
	local currEquippedItems = Inventory("type=1000")
	for id,item in pairs(currEquippedItems) do
		if(item.slot == equipSlot) then
			return item
		end
	end
	return nil
end

function ItemIsReady(itemid)
	itemid = tonumber(itemid)
	
	local hasItem = false
	for x=0,3 do
		local inv = Inventory("type="..tostring(x))
		for i, item in pairs(inv) do
			if (itemid == item.id) then
				hasItem = true
			end
			if (hasItem) then
				break
			end
		end
	end

	if (hasItem) then					
		local item = Inventory:Get(itemid)
		if (item and item.isready) then
			return true
		end
	end
	
	return false
end

function IsInventoryFull()
	local itemcount = 0
	
	--Look through regular bags first.
	for x=0,3 do
		local inv = Inventory("type="..tostring(x))
		for i, item in pairs(inv) do
			itemcount = itemcount + 1
		end
	end
	
	if (itemcount == 100) then
		return true
	end
	
	return false
end

function ItemCount(itemid)
	local itemcount = 0
	
	--Look through regular bags first.
	for x=0,3 do
		local inv = Inventory("type="..tostring(x))
		for i, item in pairs(inv) do
			if (item.id == itemid) then
				itemcount = itemcount + item.count
			end
		end
	end
	
	--Look through equipped items bag.
	local inv = Inventory("type=1000")
	for i, item in pairs(inv) do
		if (item.id == itemid) then
			itemcount = itemcount + 1
		end
	end
	
	--Look through armory bags for off-hand through wrists
	for x=3200,3209 do
		local inv = Inventory("type="..tostring(x))
		for i, item in pairs(inv) do
			if (item.id == itemid) then
				itemcount = itemcount + 1
			end
		end
	end
	
	--Look through rings armory bag.
	local inv = Inventory("type=3300")
	for i, item in pairs(inv) do
		if (item.id == itemid) then
			itemcount = itemcount + 1
		end
	end
	
	--Look through soulstones armory bag.
	local inv = Inventory("type=3400")
	for i, item in pairs(inv) do
		if (item.id == itemid) then
			itemcount = itemcount + 1
		end
	end
	
	--Look through weapons armory bag.
	local inv = Inventory("type=3500")
	for i, item in pairs(inv) do
		if (item.id == itemid) then
			itemcount = itemcount + 1
		end
	end
	
	--Look through quest/key items bag.
	local inv = Inventory("type=2004")
	for i, item in pairs(inv) do
		if (item.id == itemid) then
			itemcount = itemcount + item.count
		end
	end
	
	return itemcount
end

function GilCount()
	local gil = 0
	local inv = Inventory("type=2000")
	for i,item in pairs(inv) do
		if (item.slot == 0) then
			gil = item.count
		end
	end
	return gil
end

function PoeticCount()
	local poetic = 0
	local inv = Inventory("type=2000")
	for i,item in pairs(inv) do
		if (item.slot == 6) then
			poetic = item.count
		end
	end
	return poetic
end

function SoldieryCount()
	local soldiery = 0
	local inv = Inventory("type=2000")
	for i,item in pairs(inv) do
		if (item.slot == 7) then
			soldiery = item.count
		end
	end
	return soldiery
end

function IsShopWindowOpen()
	return (ControlVisible("Shop") or ControlVisible("ShopExchangeItem") or ControlVisible("ShopExchangeCurrency")
		or ControlVisible("ShopCard") or ControlVisible("ShopExchangeCoin"))
end

function IsArmoryFull(slot)
	local slot = tonumber(slot)
	local xref = {
		[0] = 3500,
		[1] = 3200,
		[2] = 3201,
		[3] = 3202,
		[4] = 3203,
		[5] = 3204,
		[6] = 3205,
		[7] = 3206,
		[8] = 3207,
		[9] = 3208,
		[10] = 3209,
		[11] = 3300,
		[12] = 3300,		
	}
	if (slot ~= 13) then
		local inv = Inventory("type="..tostring(xref[slot]))
		if (inv) then
			local occupiedSlots = 0
			for i, item in pairs(inv) do
				if (item.id and item.id ~= 0) then
					occupiedSlots = occupiedSlots + 1
				end
			end
			if (occupiedslots == 25) then
				return true
			end
		end
	end
	return false
end

function GetUnequippedItem(itemid)
	local itemid = tonumber(itemid)
	
	--Look through regular bags first.
	for x=0,3 do
		local inv = Inventory("type="..tostring(x))
		for i, item in pairs(inv) do
			if (item.id == itemid) then
				return item
			end
		end
	end
	
	--Look through armory bags for off-hand through wrists
	for x=3200,3209 do
		local inv = Inventory("type="..tostring(x))
		for i, item in pairs(inv) do
			if (item.id == itemid) then
				return item
			end
		end
	end
	
	--Look through rings armory bag.
	local inv = Inventory("type=3300")
	for i, item in pairs(inv) do
		if (item.id == itemid) then
			return item
		end
	end
	
	--Look through soulstones armory bag.
	local inv = Inventory("type=3400")
	for i, item in pairs(inv) do
		if (item.id == itemid) then
			return item
		end
	end
	
	--Look through weapons armory bag.
	local inv = Inventory("type=3500")
	for i, item in pairs(inv) do
		if (item.id == itemid) then
			return item
		end
	end
	
	return nil
end

function GetEquipSlotForItem(item)
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
	
	return equipSlot[item.type]
end

function CountItemsByID(id, includeHQ)
	includeHQ = includeHQ or false
	
	local count = 0
	for x=0,3 do
		local inv = Inventory("type="..tostring(x))
		for i, item in pairs(inv) do
			if (item.id == id) then
				count = count + item.count
			end
			--TODO: FIX INCLUDEHQ
			--if (includeHQ) then
				--if (item.id
			--end
		end
	end
	return count
end

function GetArmoryIDsTable()
	local invTypes = 
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
	for key,_ in pairs(invTypes) do
		local itemlist = Inventory("type="..tostring(key))
		if(ValidTable(itemlist)) then
			for id, item in pairs(itemlist) do
				ids[item.id] = true
			end
		end
	end
	
	return ids
end

function SubtractHours(start, value)
	start = tonumber(start) or 0
	local newHour = start - value
	if newHour < 0 then
		newHour = newHour + 24
	end
	return newHour	
end

function SubtractHours12(start, value)
	start = tonumber(start) or 1
	local newHour = start - value
	if newHour < 1 then
		newHour = newHour + 12
	end
	return newHour
end

function AddHours(start, value)
	start = tonumber(start) or 0
	local newHour = start + value
	if newHour > 23 then
		newHour = newHour - 24
	end
	return newHour	
end

function AddHours12(start, value)
	start = tonumber(start) or 1
	local newHour = start + value
	if newHour > 12 then
		newHour = newHour - 12
	end
	return newHour	
end

function GetJPTime()
	local jpTime = {}
	jpTime.year = tonumber(os.date("!%Y"))
	jpTime.month = tonumber(os.date("!%m"))
	jpTime.day = tonumber(os.date("!%d"))
	
	local utcHour = tonumber(os.date("!%H"))
	local jphour = AddHours(utcHour,9)
	if ( utcHour >= 15 ) then
		jpTime.day = jpTime.day + 1
	end
	
	jpTime.hour = jphour
	jpTime.minute = tonumber(os.date("!%M"))
	jpTime.sec = tonumber(os.date("!%S"))
	
	return jpTime
end

function EorzeaTime()
	local et = {}
    local ratioRealToGame = (1440 / 70)

	local jpTime = {}
	jpTime.year = os.date("!%Y")
	jpTime.month = os.date("!%m")
	jpTime.day = os.date("!%d")

	local utcHour = tonumber(os.date("!%H"))
	local offset = 9
	local jphour = AddHours(utcHour,offset)
	if ( utcHour >= 15 ) then
		jpTime.day = jpTime.day + 1
	end
	jpTime.hour = jphour
	jpTime.min = os.date("!%M")
	jpTime.sec = os.date("!%S")
	jpTime.isdst = false
	
	local jpSecs = os.time(jpTime)
	local epoch = { year = 2010, month = 6, day = 11, hour = 16, min = 0, sec = 0, isdst = false }
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

function IsLimsa(mapid)
	local mapid = tonumber(mapid)
	return (mapid == 128 or mapid == 129)
end

function IsUldah(mapid)
	local mapid = tonumber(mapid)
	return (mapid == 132 or mapid == 133)
end

function IsGridania(mapid)
	local mapid = tonumber(mapid)
	return (mapid == 130 or mapid == 131)
end

function NewCheckbox(strWinName,strText,strVarName,varDefaultValue,strGroup)
	assert(strWinName and type(strWinName) == "string", "Window name of type string expected. Received "..tostring(strWinName).." of type "..tostring(type(strWinName)))
	assert(strText and type(strText) == "string", "Description of type string expected. Received "..tostring(strText).." of type "..tostring(type(strText)))
	assert(strVarName and type(strVarName) == "string", "Variable name of type string expected. Received "..tostring(strVarName).." of type "..tostring(type(strVarName)))
	assert(strGroup and type(strGroup) == "string", "Group name of type string expected. Received "..tostring(strGroup).." of type "..tostring(type(strGroup)))
	assert(varDefaultValue ~= nil, "Default value for checkbox required.")
	
	if (Settings.FFXIVMINION[strVarName] == nil) then
		Settings.FFXIVMINION[strVarName] = varDefaultValue
	end
	
	GUI_NewCheckbox(strWinName,strText,strVarName,strGroup)
	
	_G[strVarName] = Settings.FFXIVMINION[strVarName]
end

function NewComboBox(strWinName,strText,strVarName,varDefaultValue,strGroup,strOptions)
	assert(strWinName and type(strWinName) == "string", "Window name of type string expected. Received "..tostring(strWinName).." of type "..tostring(type(strWinName)))
	assert(strText and type(strText) == "string", "Description of type string expected. Received "..tostring(strText).." of type "..tostring(type(strText)))
	assert(strVarName and type(strVarName) == "string", "Variable name of type string expected. Received "..tostring(strVarName).." of type "..tostring(type(strVarName)))
	assert(strGroup and type(strGroup) == "string", "Group name of type string expected. Received "..tostring(strGroup).." of type "..tostring(type(strGroup)))
	assert(varDefaultValue ~= nil, "Default value for checkbox required.")
	
	if (Settings.FFXIVMINION[strVarName] == nil) then
		Settings.FFXIVMINION[strVarName] = varDefaultValue
	end
	
	GUI_NewCheckbox(strWinName,strText,strVarName,strGroup,strOptions)
	
	_G[strVarName] = Settings.FFXIVMINION[strVarName]
end

function NewField(strWinName,strText,strVarName,varDefaultValue,strGroup)
	assert(strWinName and type(strWinName) == "string", "Window name of type string expected. Received "..tostring(strWinName).." of type "..tostring(type(strWinName)))
	assert(strText and type(strText) == "string", "Description of type string expected. Received "..tostring(strText).." of type "..tostring(type(strText)))
	assert(strVarName and type(strVarName) == "string", "Variable name of type string expected. Received "..tostring(strVarName).." of type "..tostring(type(strVarName)))
	assert(strGroup and type(strGroup) == "string", "Group name of type string expected. Received "..tostring(strGroup).." of type "..tostring(type(strGroup)))
	assert(varDefaultValue ~= nil, "Default value for field required.")
	
	if (Settings.FFXIVMINION[strVarName] == nil) then
		Settings.FFXIVMINION[strVarName] = varDefaultValue
	end
	
	GUI_NewCheckbox(strWinName,strText,strVarName,strGroup)
	
	_G[strVarName] = Settings.FFXIVMINION[strVarName]
end

function NewNumeric(strWinName,strText,strVarName,varDefaultValue,strGroup,lngMin,lngMax)
	assert(strWinName and type(strWinName) == "string", "Window name of type string expected. Received "..tostring(strWinName).." of type "..tostring(type(strWinName)))
	assert(strText and type(strText) == "string", "Description of type string expected. Received "..tostring(strText).." of type "..tostring(type(strText)))
	assert(strVarName and type(strVarName) == "string", "Variable name of type string expected. Received "..tostring(strVarName).." of type "..tostring(type(strVarName)))
	assert(varDefaultValue ~= nil, "Default value for checkbox required.")
	
	if (Settings.FFXIVMINION[strVarName] == nil) then
		Settings.FFXIVMINION[strVarName] = varDefaultValue
	end
	
	GUI_NewCheckbox(strWinName,strText,strVarName,strGroup)
	
	_G[strVarName] = Settings.FFXIVMINION[strVarName]
end

function NewButton(strWinName,strText,strVarName,varDefaultValue,strGroup)
	assert(strWinName and type(strWinName) == "string", "Window name of type string expected. Received "..tostring(strWinName).." of type "..tostring(type(strWinName)))
	assert(strText and type(strText) == "string", "Description of type string expected. Received "..tostring(strText).." of type "..tostring(type(strText)))
	assert(strVarName and type(strVarName) == "string", "Variable name of type string expected. Received "..tostring(strVarName).." of type "..tostring(type(strVarName)))
	assert(strGroup and type(strGroup) == "string", "Group name of type string expected. Received "..tostring(strGroup).." of type "..tostring(type(strGroup)))
	assert(varDefaultValue ~= nil, "Default value for checkbox required.")
	
	if (Settings.FFXIVMINION[strVarName] == nil) then
		Settings.FFXIVMINION[strVarName] = varDefaultValue
	end
	
	GUI_NewCheckbox(strWinName,strText,strVarName,strGroup)
	
	_G[strVarName] = Settings.FFXIVMINION[strVarName]
end
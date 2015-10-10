-- This file holds global helper functions
ff = {}
function FilterByProximity(entities,center,radius,sortfield)
	if (ValidTable(entities) and ValidTable(center) and tonumber(radius) > 0) then
		local validEntities = {}
		for i,e in pairs(entities) do
			local epos = e.pos
			local dist = Distance3D(center.x,center.y,center.z,epos.x,epos.y,epos.z)
	
			if (dist <= radius) then
				table.insert(validEntities,e)
			end
		end
		
		if (ValidTable(validEntities)) then
			if (sortfield and type(sortfield) == "string" and sortfield ~= "") then
				table.sort(validEntities,function(a,b) return a[sortfield] < b[sortfield] end)
				return validEntities
			else
				return validEntities
			end
		else
			return nil
		end
	else
		d("[FilterByProximity]: Entities list, center point, or radius was invalid.")
	end
end
ff["FilterByProximity"] = FilterByProximity
function GetNearestGrindAttackable()
	local huntString = GetWhitelistIDString()
	local excludeString = GetBlacklistIDString()
	local block = 0
	local el = nil
	local nearestGrind = nil
	local nearestDistance = 9999
	local marker = ml_global_information.currentMarker
	local minLevel = ml_global_information.MarkerMinLevel 
	local maxLevel = ml_global_information.MarkerMaxLevel
	
	if (ml_task_hub:CurrentTask().safeLevel) then
		maxLevel = Player.level + 2
	end
	
	local radius = 0
	local markerPos;
	if (ValidTable(marker)) then
		local maxradius = marker:GetFieldValue(GetUSString("maxRadius"))
		if (tonumber(maxradius) and tonumber(maxradius) > 0) then
			radius = tonumber(maxradius)
		end
		markerPos = marker:GetPosition()
	end
	
	if (radius > 0 and ValidTable(markerPos)) then
		d("Checking marker with radius section.")
		if (gClaimFirst	== "1") then		
			if (not IsNullString(huntString)) then
				el = EntityList("contentid="..huntString..",notincombat,alive,attackable,onmesh")
				
				if (ValidTable(el)) then
					local filtered = FilterByProximity(el,markerPos,radius,"pathdistance")
					if (ValidTable(filtered)) then
						for i,e in pairs(filtered) do
							if (ValidTable(e) and e.uniqueid ~= 541) then
								if ((e.targetid == 0 or e.targetid == Player.id) and
									e.pathdistance <= tonumber(gClaimRange)) then
									return e
								end
							end
						end
					end
				end
			end
		end	
		
		--Prioritize the lowest health with aggro on player, non-fate mobs.
		if (not IsNullString(excludeString)) then
			el = EntityList("shortestpath,alive,attackable,onmesh,targetingme,fateid=0,exclude_contentid="..excludeString..",maxpathdistance=30") 
		else
			el = EntityList("shortestpath,alive,attackable,onmesh,targetingme,fateid=0,maxpathdistance=30") 
		end
		
		local party = EntityList.myparty
		if ( party ) then
			for i, member in pairs(party) do
				if (member.id and member.id ~= 0 and member.mapid == Player.mapid) then
					if (not IsNullString(excludeString)) then
						el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",fateid=0,exclude_contentid="..excludeString..",maxdistance=30")
					else
						el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",fateid=0,maxdistance=30")
					end
					
					if (ValidTable(el)) then
						local filtered = FilterByProximity(el,markerPos,radius)
						if (ValidTable(filtered)) then
							for i,e in pairs(filtered) do
								if (ValidTable(e) and e.uniqueid ~= 541) then
									return e
								end
							end
						end
					end
				end
			end
		end
		
		
		
		if (ValidTable(Player.pet)) then
			if (not IsNullString(excludeString)) then
				el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(Player.pet.id)..",fateid=0,exclude_contentid="..excludeString..",maxdistance="..tostring(ml_global_information.AttackRange))
			else
				el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(Player.pet.id)..",fateid=0,maxdistance="..tostring(ml_global_information.AttackRange))
			end
			
			if (ValidTable(el)) then
				local filtered = FilterByProximity(el,markerPos,radius)
				if (ValidTable(filtered)) then
					for i,e in pairs(filtered) do
						if (ValidTable(e) and e.uniqueid ~= 541) then
							return e
						end
					end
				end
			end
		end
		
		--Nearest specified hunt, ignore levels here, assume players know what they wanted to kill.
		if (not IsNullString(huntString)) then
			el = EntityList("contentid="..huntString..",fateid=0,alive,attackable,onmesh")
			
			if (ValidTable(el)) then
				local filtered = FilterByProximity(el,markerPos,radius,"pathdistance")
				if (ValidTable(filtered)) then
					for i,e in pairs(filtered) do
						if (ValidTable(e) and e.uniqueid ~= 541) then
							if (e.targetid == 0 or e.targetid == Player.id or gClaimed == "1") then
								return e
							end
						end
					end
				end
			end
		end
		
		--Nearest in our attack range, not targeting anything, non-fate, use PathDistance.
		if (IsNullString(huntString)) then
			if (not IsNullString(excludeString)) then
				el = EntityList("alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0,exclude_contentid="..excludeString)
			else
				el = EntityList("alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0")
			end
			
			if (ValidTable(el)) then
				local filtered = FilterByProximity(el,markerPos,radius,"pathdistance")
				if (ValidTable(filtered)) then
					for i,e in pairs(filtered) do
						if (ValidTable(e) and e.uniqueid ~= 541) then
							return e
						end
					end
				end
			end
		
			if (not IsNullString(excludeString)) then
				el = EntityList("shortestpath,alive,attackable,onmesh,minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0,exclude_contentid="..excludeString)
			else
				el = EntityList("shortestpath,alive,attackable,onmesh,minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0")
			end
			
			if (ValidTable(el)) then
				local filtered = FilterByProximity(el,markerPos,radius,"pathdistance")
				if (ValidTable(filtered)) then
					for i,e in pairs(filtered) do
						if (ValidTable(e) and e.uniqueid ~= 541) then
							return e
						end
					end
				end
			end
		end
	else
		d("Checking marker without radius section.")
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
			d("Checking whitelist section.")
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
			d("Checking non-whitelist section.")
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
	end
	
    --d("GetNearestGrindAttackable() failed with no entity found matching params")
    return nil
end
ff["GetNearestGrindAttackable"] = GetNearestGrindAttackable
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
ff["GetNearestGrindPriority"] = GetNearestGrindPriority
function GetNearestFateAttackable()
	local el = nil
    local myPos = ml_global_information.Player_Position
    local fate = GetClosestFate(myPos)
	
    if (fate ~= nil) then
		if (fate.type == 1) then
			el = EntityList("alive,attackable,onmesh,fateid="..tostring(fate.id))
			if (ValidTable(el)) then
				local bestTarget = nil
				local highestHP = 0
				
				for i,e in pairs(el) do
					if (not bestTarget or (bestTarget and e.hp.max > highestHP)) then
						bestTarget = e
						highestHP = e.hp.max
					end
				end
				
				if (bestTarget) then
					return bestTarget
				end
			end
		end
		
		
		el = EntityList("shortestpath,alive,attackable,targetingme,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",fateid="..tostring(fate.id))
        if (ValidTable(el)) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
				local epos = e.pos
				local dist = Distance2D(epos.x,epos.z,fate.x,fate.z)
				if (dist <= fate.radius) then
					return e
				end
            end
        end	
    
        el = EntityList("shortestpath,alive,attackable,targetingme,onmesh,fateid="..tostring(fate.id))            
        if (ValidTable(el)) then
            local i,e = next(el)
            if (i~=nil and e~=nil) then
                epos = shallowcopy(e.pos)
				local dist = Distance2D(epos.x,epos.z,fate.x,fate.z)
				if (dist <= fate.radius) then
					return e
				end
            end
        end
		
		if (gFateKillAggro == "1") then
			el = EntityList("shortestpath,alive,attackable,aggro,onmesh")
			if (ValidTable(el)) then
				local i,e = next(el)
				if (i~=nil and e~=nil) then
					return e
				end
			end	
		end
		
        el = EntityList("shortestpath,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",fateid="..tostring(fate.id))
        if (ValidTable(el)) then
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
            
        if (ValidTable(el)) then
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
ff["GetNearestFateAttackable"] = GetNearestFateAttackable
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
				local myPos = ml_global_information.Player_Position
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
				local myPos = ml_global_information.Player_Position
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
					local myPos = ml_global_information.Player_Position
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
					local myPos = ml_global_information.Player_Position
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
ff["GetHuntTarget"] = GetHuntTarget
function IsValidHealTarget(e)
	if (ValidTable(e) and e.alive and e.targetable and not e.aggro) then
		return (e.chartype == 4) or
			(e.chartype == 0 and (e.type == 2 or e.type == 3 or e.type == 5)) or
			(e.chartype == 3 and e.type == 2) or
			(e.chartype == 5 and e.type == 2)
	end
	
	return false
end
ff["IsValidHealTarget"] = IsValidHealTarget
function GetBestTankHealTarget( range )
	range = range or ml_global_information.AttackRange
	local lowest = nil
	local lowestHP = 101

    local el = EntityList("friendly,alive,chartype=4,myparty,targetable,maxdistance="..tostring(range))
	--local el = EntityList("friendly,alive,chartype=4,myparty,maxdistance="..tostring(range))
    if ( ValidTable(el) ) then
		for i,e in pairs(el) do
			if (IsTank(e.job) and e.hp.percent < lowestHP ) then
				lowest = e
				lowestHP = e.hp.percent
			end
        end
    end
	
	local ptrg = ml_global_information.Player_Target
	if (ptrg and Player.pet) then
		if (lowest == nil and ptrg.targetid == Player.pet.id) then
			lowest = Player.pet
		end
	end
	
	return lowest
end
ff["GetBestTankHealTarget"] = GetBestTankHealTarget
function GetBestPartyHealTarget( npc, range, hp )	
	local npc = npc
	if (npc == nil) then npc = false end
	local range = range or ml_global_information.AttackRange
	local hp = hp or 95
	
	local healables = {}
	
	local el = EntityList("alive,friendly,chartype=4,myparty,targetable,maxdistance="..tostring(range))
	if ( ValidTable(el) ) then
		for i,e in pairs(el) do
			if (IsValidHealTarget(e) and e.hp.percent <= hp) then
				healables[i] = e
			end
		end
	end
	
	if (npc) then
		el = EntityList("alive,friendly,myparty,targetable,maxdistance="..tostring(range))
		if ( ValidTable(el) ) then
			for i,e in pairs(el) do
				if (IsValidHealTarget(e) and e.hp.percent <= hp) then
					healables[i] = e
				end
			end
		end
	end
	
	if (ValidTable(healables)) then
		local lowest = nil
		local lowesthp = 100
		
		for i,e in pairs(healables) do
			if (not lowest or (lowest and e.hp.percent < lowesthp)) then
				lowest = e
				lowesthp = e.hp.percent
			end
		end
		
		if (lowest) then
			return lowest
		end
	end
	
	if (gBotMode == GetString("partyMode") and not IsLeader()) then
		local leader, isEntity = GetPartyLeader()
		if (leader and leader.id ~= 0) then
			local leaderentity = EntityList:Get(leader.id)
			if (leaderentity and leaderentity.distance <= range and leaderentity.hp.percent <= hp) then
				return leaderentity
			end
		end
	end
	
    return nil
end
ff["GetBestPartyHealTarget"] = GetBestPartyHealTarget
function GetPetSkillRangeRadius(id)
	local id = tonumber(id) or 0
	
	local petRangeRadius = {
		--Carbuncle 1
		[9] = { range = 25, radius = 0},
		[10] = { range = 5, radius = 0},
		[11] = { range = 25, radius = 5},
		[12] = { range = 25, radius = 15},
		
		--Carbuncle 2
		[13] = { range = 25, radius = 0},
		[14] = { range = 5, radius = 0},
		[15] = { range = 25, radius = 5},
		[16] = { range = 25, radius = 15},
		
		--Garuda
		[17] = { range = 25, radius = 0},
		[18] = { range = 5, radius = 0},
		[19] = { range = 25, radius = 5},
		[20] = { range = 25, radius = 15},
		
		--Titan
		[22] = { range = 3, radius = 0},
		[23] = { range = 0, radius = 4},
		[24] = { range = 0, radius = 0},
		[25] = { range = 3, radius = 0},
		
		--Ifrit
		[27] = { range = 3, radius = 0},
		[28] = { range = 3, radius = 0},
		[29] = { range = 0, radius = 0},
		[30] = { range = 0, radius = 3},
		
		--Eos
		[32] = { range = 30, radius = 0},
		[33] = { range = 0, radius = 15},
		[34] = { range = 0, radius = 15},
		[35] = { range = 0, radius = 15},
		
		--Selene
		[36] = { range = 30, radius = 0},
		[37] = { range = 25, radius = 0},
		[38] = { range = 0, radius = 20},
		[39] = { range = 0, radius = 20},		
	}
	
	if (petRangeRadius[id]) then
		return petRangeRadius[id]
	end
	
	return nil
end
ff["GetPetSkillRangeRadius"] = GetPetSkillRangeRadius
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
			--el = EntityList("myparty,alive,type=1,maxdistance="..tostring(range))
		else
			el = EntityList("myparty,alive,targetable,maxdistance="..tostring(range))
			--el = EntityList("myparty,alive,maxdistance="..tostring(range))
		end
		
		if ( ValidTable(el) ) then
			for i,e in pairs(el) do
				if (IsValidHealTarget(e)) then
					if (not lowest or e.hp.percent < lowestHP) then
						lowest = e
						lowestHP = e.hp.percent
					end
				end
			end
		end
		
		if (Player.alive and ml_global_information.Player_HP.percent < lowestHP) then
			lowest = Player
			lowestHP = ml_global_information.Player_HP.percent
		end
		
		return lowest
	end
end
ff["GetLowestHPParty"] = GetLowestHPParty
function GetLowestMPParty( range, role )
    local pID = Player.id
	local lowest = nil
	local lowestMP = 101
	local range = tonumber(range) or 35 
	local role = tostring(role) or ""
	
	local mpUsers = {
		[1] = true,
		[6] = true,
		[19] = true,
		[24] = true,
		[26] = true,
		[27] = true,
		[28] = true,
	}
	
	-- If the role is to be filtered, remove the non-applicable jobs here.
	local roleTable = GetRoleTable(role)
	if (roleTable) then
		for jobid,_ in pairs(mpUsers) do
			if (not roleTable[jobid]) then
				mpUsers[jobid] = nil
			end
		end
	end
	
    local el = EntityList("myparty,alive,type=1,targetable,maxdistance="..tostring(range))
	--local el = EntityList("myparty,alive,type=1,maxdistance="..tostring(range))
    if ( ValidTable(el) ) then
		for i,e in pairs(el) do
			if (mpUsers[e.job] and e.mp.percent < lowestMP) then
				lowest = e
				lowestMP = e.mp.percent
			end
        end
    end
	
	if (Player.alive and mpUsers[Player.job] and ml_global_information.Player_MP.percent < lowestMP) then
		lowest = Player
		lowestMP = ml_global_information.Player_MP.percent
	end
	
	return lowest
end
ff["GetLowestMPParty"] = GetLowestMPParty
function GetLowestTPParty( range, role )
	local lowest = nil
	local lowestTP = 1001
	local range = tonumber(range) or 35
	local role = tostring(role) or ""
	
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
		[29] = true,
		[30] = true,
	}
	
	-- If the role is to be filtered, remove the non-applicable jobs here.
	local roleTable = GetRoleTable(role)
	if (roleTable) then
		for jobid,_ in pairs(tpUsers) do
			if (not roleTable[jobid]) then
				tpUsers[jobid] = nil
			end
		end
	end
	
    local el = EntityList("myparty,alive,type=1,targetable,maxdistance="..tostring(range))
	--local el = EntityList("myparty,alive,type=1,targetable,maxdistance="..tostring(range))
    if ( ValidTable(el) ) then
        for i,e in pairs(el) do
			if (e.job and tpUsers[e.job]) then
				if (e.tp < lowestTP) then
					lowest = e
					lowestTP = e.tp
				end
			end
        end
    end
	
	if (Player.alive and tpUsers[Player.job] and ml_global_information.Player_TP < lowestTP) then
		lowest = Player
		lowestTP = ml_global_information.Player_TP
	end
	
    return lowest
end
ff["GetLowestTPParty"] = GetLowestTPParty
function GetBestHealTarget( npc, range, reqhp )
	local npc = npc
	if (npc == nil) then npc = false end
	local range = range or ml_global_information.AttackRange
	local reqhp = tonumber(reqhp) or 95
	
	--d("[GetBestHealTarget]: Params:"..tostring(npc)..","..tostring(range)..","..tostring(reqhp))
	
	local healables = {}
	
	local el = EntityList("alive,friendly,chartype=4,targetable,maxdistance="..tostring(range))
	if ( ValidTable(el) ) then
		for i,e in pairs(el) do
			if (IsValidHealTarget(e) and e.hp.percent <= reqhp) then
				--d("[GetBestHealTarget]: "..tostring(e.name).." is a valid target with ["..tostring(e.hp.percent).."] HP %.")
				healables[i] = e
			end
		end
	end
	
	if (npc) then
		--d("[GetBestHealTarget]: Checking non-players section.")
		local el = EntityList("alive,targetable,maxdistance="..tostring(range))
		if ( ValidTable(el) ) then
			for i,e in pairs(el) do
				if (IsValidHealTarget(e) and e.hp.percent <= reqhp) then
					--d("[GetBestHealTarget]: "..tostring(e.name).." is a valid target with ["..tostring(e.hp.percent).."] HP %.")
					healables[i] = e
				end
			end
		end
	end
	
	if (ValidTable(healables)) then
		local lowest = nil
		local lowesthp = 100
		
		for i,e in pairs(healables) do
			if (not lowest or (lowest and e.hp.percent < lowesthp)) then
				lowest = e
				lowesthp = e.hp.percent
				--d("[GetBestHealTarget]: "..tostring(e.name).." is the lowest target with ["..tostring(e.hp.percent).."] HP %.")
			end
		end
		
		if (lowest) then
			return lowest
		end
	end
   
    ml_debug("GetBestHealTarget() failed with no entity found matching params")
    return nil
end
ff["GetBestHealTarget"] = GetBestHealTarget
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
ff["GetBestBaneTarget"] = GetBestBaneTarget
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
ff["GetBestDoTTarget"] = GetBestDoTTarget
function GetClosestHealTarget()
    local pID = Player.id
    local el = EntityList("nearest,friendly,chartype=4,myparty,targetable,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
	--local el = EntityList("nearest,friendly,chartype=4,myparty,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
    if ( ValidTable(el) ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
    
    local el = EntityList("nearest,friendly,chartype=4,targetable,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
	--local el = EntityList("nearest,friendly,chartype=4,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
    if ( ValidTable(el) ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
    --ml_debug("GetBestHealTarget() failed with no entity found matching params")
    return nil
end
ff["GetClosestHealTarget"] = GetClosestHealTarget
function GetBestRevive( party, role)
	party = party or false
	role = role or ""
	range = 30
	
	local el = nil
	if (party) then
		el = EntityList("myparty,targtable,dead,maxdistance="..tostring(range))
	else
		el = EntityList("dead,targetable,maxdistance="..tostring(range))
	end 
	
	-- Filter out the inappropriate roles.
	local targets = {}
	if (el) then
		local roleTable = GetRoleTable(role)
		if (roleTable) then
			for id,entity in pairs(el) do
				if (entity.job and roleTable[entity.job]) then
					targets[id] = entity
				end
			end
		else
			for id,entity in pairs(el) do
				targets[id] = entity
			end
		end
	end
	
	-- Filter out targets with the res buff.
	if (targets) then
		for id,entity in pairs(targets) do
			if (HasBuffs(entity,"148")) then
				targets[id] = nil
			end
		end
	end
	
	if (targets) then
		for id,entity in pairs(targets) do
			if (entity) then
				return entity
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
ff["GetBestRevive"] = GetBestRevive
function GetPVPTarget()
    local targets = {}
    local bestTarget = nil
    local nearest = nil
	local lowestHealth = nil
    
	local enemyParty = nil
	if (ml_global_information.Player_Map == 376 or ml_global_information.Player_Map == 422) then
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
                if role == GetString("healer") then
                    targets[GetString("healer")] = entity
                elseif role == GetString("dps") then
                    if (targets[GetString("dps")] ~= nil) then
						-- keep blackmage as highest prioritized ranged target
						if (gPrioritizeRanged == "1" and IsRangedDPS(entity.job)) then
							if (targets[GetString("dps")].job ~= FFXIV.JOBS.BLACKMAGE) then
								targets[GetString("dps")] = entity
							end
                        end
					else
						targets[GetString("dps")] = entity
                    end
                else
                    targets[GetString("tank")] = entity
                end 
				
				if role == GetString("healer") then
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
						targets[GetString("unattendedHealer")] = entity
					else
						targets[GetString("unattendedHealer")] = nil
					end
				end
				
				if IsMeleeDPS(entity.job) then
					targets[GetString("meleeDPS")] = entity				
				end
				
				if IsCasterDPS(entity.job) then
					if (targets[GetString("caster")] ~= nil) then
						if (targets[GetString("caster")].job ~= FFXIV.JOBS.BLACKMAGE) then
							targets[GetString("caster")] = entity
						end
					else
						targets[GetString("caster")] = entity
					end
				end
				
				if IsRangedDPS(entity.job) then
					if (targets[GetString("ranged")] ~= nil) then
						if (targets[GetString("ranged")].job ~= FFXIV.JOBS.BLACKMAGE) then
							targets[GetString("ranged")] = entity
						end
					else
						targets[GetString("ranged")] = entity
					end
				end
				
				if (entity.job == FFXIV.JOBS.BLACKMAGE or entity.job == FFXIV.JOBS.WHITEMAGE) then
					if (targets[GetString("sleeper")] ~= nil) then
						if (targets[GetString("sleeper")].job ~= FFXIV.JOBS.BLACKMAGE) then
							targets[GetString("sleeper")] = entity
						end
					else
						targets[GetString("sleeper")] = entity
					end
				end
				
				if targets[GetString("nearDead")] == entity and (entity.hp.percent > 30 or not entity.alive or entity.distance > 25) then
					targets[GetString("nearDead")] = nil
				end
				
				if entity.hp.percent < 30 and entity.pathdistance < 15 then
					targets[GetString("nearDead")] = entity
				end
					
				
				if targets[GetString("nearest")] == nil or targets[GetString("nearest")].distance > entity.distance then
					targets[GetString("nearest")] = entity
				end
				
				if targets[GetString("lowestHealth")] == nil or targets[GetString("lowestHealth")].hp.percent > entity.hp.percent then
					targets[GetString("lowestHealth")] = entity
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
		return targets[GetString("lowestHealth")]
	end
	
	ml_error("Bad, we shouldn't have gotten to this point!")
end
ff["GetPVPTarget"] = GetPVPTarget
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
ff["GetNearestGrindAggro"] = GetNearestGrindAggro
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
ff["GetNearestAggro"] = GetNearestAggro
function RoundUp(number, multiple)
	local number = tonumber(number)
	local multiple = tonumber(multiple)
	
	return (math.floor(((number + (multiple - 1)) / multiple)) * multiple)
end
ff["RoundUp"] = RoundUp
function GetNearestFromList(strList,pos,radius)
	local el = EntityList(strList)
	if (ValidTable(el)) then
		local filteredList = {}
		for i,e in pairs(el) do
			if (not radius or (radius > 200)) then
				table.insert(filteredList,e)
			else
				local epos = e.pos
				local dist = Distance3D(pos.x,pos.y,pos.z,epos.x,epos.y,epos.z)
				
				if (dist <= radius) then
					table.insert(filteredList,e)
				end
			end
		end
		
		if (ValidTable(filteredList)) then
			table.sort(filteredList,function(a,b) return a.pathdistance < b.pathdistance end)
			
			local i,e = next(filteredList)
			if (i and e) then
				return e
			end
		end
	end
	
	return nil
end
function GetNearestGatherable(marker)
    local el = nil
    local whitelist = ""
    local blacklist = ""
	local minlevel = 1
	local maxlevel = 60
	local radius = 0
	local markerPos = nil
	
	if (ValidTable(marker)) then
		if (gMarkerMgrMode ~= GetString("singleMarker")) then	
			local mincontentlevel = marker:GetFieldValue(GetUSString("minContentLevel"))
			if (tonumber(mincontentlevel) and tonumber(mincontentlevel) > 0) then
				minlevel = tonumber(mincontentlevel)
			end
			
			local maxcontentlevel = marker:GetFieldValue(GetUSString("maxContentLevel"))
			if (tonumber(maxcontentlevel) and tonumber(maxcontentlevel) > 0) then
				maxlevel = tonumber(maxcontentlevel)
			end
		end
		
		local maxradius = marker:GetFieldValue(GetUSString("maxRadius"))
		if (tonumber(maxradius) and tonumber(maxradius) > 0) then
			radius = tonumber(maxradius)
		end
		
		markerPos = marker:GetPosition()
		whitelist = tostring(marker:GetFieldValue(GetUSString("contentIDEquals")))
		blacklist = tostring(marker:GetFieldValue(GetUSString("NOTcontentIDEquals")))
	end
    
	if (radius == 0 or radius > 200 or not ValidTable(markerPos)) then
		if (whitelist and whitelist ~= "") then
			el = EntityList("shortestpath,onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel)..",contentid="..whitelist)
		elseif (blacklist and blacklist ~= "") then
			el = EntityList("shortestpath,onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel)..",exclude_contentid="..blacklist)
		else
			el = EntityList("shortestpath,onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel))
		end
		
		if ( ValidTable(el) ) then
			local i,e = next(el)
			if (i~=nil and e~=nil) then
				return e
			end
		end
	elseif (ValidTable(markerPos)) then
		if (whitelist and whitelist ~= "") then
			el = EntityList("onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel)..",contentid="..whitelist)
		elseif (blacklist and blacklist ~= "") then
			el = EntityList("onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel)..",exclude_contentid="..blacklist)
		else
			el = EntityList("onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel))
		end
		
		local gatherables = {}
		if (ValidTable(el)) then
			for i,g in pairs(el) do
				local gpos = g.pos
				local dist = Distance3D(markerPos.x,markerPos.y,markerPos.z,gpos.x,gpos.y,gpos.z)
				
				if (dist <= radius) then
					table.insert(gatherables,g)
				end
			end
		end
		
		if (ValidTable(gatherables)) then
			table.sort(gatherables,	function(a,b) return a.pathdistance < b.pathdistance end)
			
			local i,g = next(gatherables)
			if (i and g) then
				return g
			end
		end
	end
    
    ml_debug("GetNearestGatherable() failed with no entity found matching params")
    return nil
end
ff["GetNearestGatherable"] = GetNearestGatherable
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
ff["GetNearestUnspoiled"] = GetNearestUnspoiled
function GetMaxAttackRange()
	local target = ml_global_information.Player_Target
	
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
ff["GetMaxAttackRange"] = GetMaxAttackRange
function HasBuff(targetid, buffID)
	local buffID = tonumber(buffID) or 0
	
	if (targetid == Player.id) then
		local buffs = ml_global_information.Player_Buffs
		if (ValidTable(buffs)) then
			for i, buff in pairs(buffs) do
				if (buff.id == buffID) then
					return true
				end
			end
		end
	else
		local entity = EntityList:Get(targetid)
		if (ValidTable(entity)) then
			local buffs = entity.buffs
			if (ValidTable(buffs)) then
				for i, buff in pairs(buffs) do
					if (buff.id == buffID) then
						return true
					end
				end
			end
		end
	end
    
    return false
end
ff["HasBuff"] = HasBuff
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
ff["HasSkill"] = HasSkill
function HasBuffs(entity, buffIDs, dura, ownerid)
	local duration = dura or 0
	local owner = ownerid or 0
	
	if (ValidTable(entity)) then
		local buffs;
		if (entity.id == Player.id) then
			buffs = ml_global_information.Player_Buffs
		else
			buffs = entity.buffs
		end
		if (ValidTable(buffs)) then
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
		end
	end
	return false
end
ff["HasBuffs"] = HasBuffs
function MissingBuffs(entity, buffIDs, dura, ownerid)
	local duration = dura or 0
	local owner = ownerid or 0
	
	if (ValidTable(entity)) then
		--If we have no buffs, we are missing everything.
		local buffs;
		if (entity.id == Player.id) then
			buffs = ml_global_information.Player_Buffs
		else
			buffs = entity.buffs
		end
		
		if (ValidTable(buffs)) then
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
	end
    
    return true
end
ff["MissingBuffs"] = MissingBuffs
function GetFleeHP()
	local attackingMobs = TableSize(EntityList("onmesh,alive,attackable,targetingme,maxdistance=15"))
	local fleeHP = tonumber(gFleeHP) + (3 * attackingMobs)
	return fleeHP
end
ff["GetFleeHP"] = GetFleeHP
function HasInfiniteDuration(id)
	infiniteDurationAbilities = {
		[614] = true,
	}
	
	return infiniteDurationAbilities[id] or false
end
ff["HasInfiniteDuration"] = HasInfiniteDuration
function ActionList:IsCasting()
	return (ml_global_information.Player_Casting.channelingid ~= 0)
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
ff["SetFacing"] = SetFacing
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
ff["isCasting"] = isCasting
function HasContentID(entity, contentIDs) 	
	local cID = entity.contentid
	
	for _orids in StringSplit(contentIDs,",") do
		if (tonumber(_orids) == cID) then
			return true
		end
	end
	return false
end
ff["HasContentID"] = HasContentID
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
ff["IsHealingSkill"] = IsHealingSkill
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
ff["IsMudraSkill"] = IsMudraSkill
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
ff["IsNinjutsuSkill"] = IsNinjutsuSkill
function IsUncoverSkill(skillID)
	return (skillID == 214 or skillID == 231)
end
ff["IsUncoverSkill"] = IsUncoverSkill
function GetSkillByID(skillid,skilltype)
	local skillid = tonumber(skillid)
	
	local skilltypes = {
		[1] = true,
		[11] = true,
		[8] = true,
	}
	
	if (skilltype) then
		local al = ActionList("type="..tostring(skilltype))
		if (al) then
			for id,skill in pairs(al) do
				if (id == skillid) then
					return skill
				end
			end
		end
	else
		for id,_ in pairs(skilltypes) do
			local al = ActionList("type="..tostring(id))
			if (al) then
				for id,skill in pairs(al) do
					if (id == skillid) then
						return skill
					end
				end
			end
		end
	end
	
	return nil
end
ff["GetSkillByID"] = GetSkillByID
 function IsFlanking(entity)
	if not entity or entity.id == Player.id then return false end
	
    if ((entity.distance2d - (entity.hitradius + 1)) <= ml_global_information.AttackRange) then
        local entityHeading = nil
        
        if (entity.pos.h < 0) then
            entityHeading = entity.pos.h + 2 * math.pi
        else
            entityHeading = entity.pos.h
        end
		
		local myPos = ml_global_information.Player_Position
        local entityAngle = math.atan2(myPos.x - entity.pos.x, myPos.z - entity.pos.z)        
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
ff["IsFlanking"] = IsFlanking
function IsBehind(entity)
	if not entity or entity.id == Player.id then return false end
	
    if ((entity.distance2d - (entity.hitradius + 1)) <= ml_global_information.AttackRange) then
        local entityHeading = nil
        
        if (entity.pos.h < 0) then
            entityHeading = entity.pos.h + 2 * math.pi
        else
            entityHeading = entity.pos.h
        end
        
		local myPos = ml_global_information.Player_Position
        local entityAngle = math.atan2(myPos.x - entity.pos.x, myPos.z - entity.pos.z)        
        local deviation = entityAngle - entityHeading
        local absDeviation = math.abs(deviation)
        local leftover = math.abs(absDeviation - math.pi)
		
        if (leftover > (math.pi * 1.75) or leftover < (math.pi * .25)) then
            return true
        end
    end
    return false
end
ff["IsBehind"] = IsBehind
function IsBehindSafe(entity)
	if not entity or entity.id == Player.id then return false end
	local entityHeading = nil
	
	if (entity.pos.h < 0) then
		entityHeading = entity.pos.h + 2 * math.pi
	else
		entityHeading = entity.pos.h
	end
	
	local myPos = ml_global_information.Player_Position
	local entityAngle = math.atan2(myPos.x - entity.pos.x, myPos.z - entity.pos.z)        
	local deviation = entityAngle - entityHeading
	local absDeviation = math.abs(deviation)
	local leftover = math.abs(absDeviation - math.pi)
	
	if (leftover > (math.pi * 1.70) or leftover < (math.pi * .30)) then
		return true
	end
    return false
end
ff["IsBehindSafe"] = IsBehindSafe
function IsFront(entity)
	if not entity or entity.id == Player.id then return false end
	local entityHeading = nil
	
	if (entity.pos.h < 0) then
		entityHeading = entity.pos.h + 2 * math.pi
	else
		entityHeading = entity.pos.h
	end
	
	local myPos = ml_global_information.Player_Position
	local entityAngle = math.atan2(myPos.x - entity.pos.x, myPos.z - entity.pos.z) 
	local deviation = entityAngle - entityHeading
	local absDeviation = math.abs(deviation)
	local leftover = math.abs(absDeviation - math.pi)
	
	if (leftover > (math.pi * .75) and leftover < (math.pi * 1.25)) then
		return true
	end
    return false
end
ff["IsFront"] = IsFront
function IsFrontSafe(entity)
	if not entity or entity.id == Player.id then return false end
	local entityHeading = nil
	
	if (entity.pos.h < 0) then
		entityHeading = entity.pos.h + 2 * math.pi
	else
		entityHeading = entity.pos.h
	end
	
	local myPos = ml_global_information.Player_Position
	local entityAngle = math.atan2(myPos.x - entity.pos.x, myPos.z - entity.pos.z) 
	local deviation = entityAngle - entityHeading
	local absDeviation = math.abs(deviation)
	local leftover = math.abs(absDeviation - math.pi)
	
	if (leftover > (math.pi * .70) and leftover < (math.pi * 1.30)) then
		return true
	end
    return false
end
ff["IsFrontSafe"] = IsFrontSafe
function EntityIsFrontWide(entity)
	if not entity or entity.id == Player.id then return false end
	
	local ppos = ml_global_information.Player_Position
	local epos = entity.pos
	local playerHeading = ConvertHeading(ppos.h)
	
	local playerAngle = math.atan2(epos.x - ppos.x, epos.z - ppos.z) 
	local deviation = playerAngle - playerHeading
	local absDeviation = math.abs(deviation)
	local leftover = math.abs(absDeviation - math.pi)
	
	if (leftover > (math.pi * .70) and leftover < (math.pi * 1.30)) then
		return true
	end
    return false
end
ff["EntityIsFrontWide"] = EntityIsFrontWide
function EntityIsFront(entity)
	if not entity or entity.id == Player.id then return false end
	
	local ppos = ml_global_information.Player_Position
	local epos = entity.pos
	local playerHeading = ConvertHeading(ppos.h)
	
	local playerAngle = math.atan2(epos.x - ppos.x, epos.z - ppos.z) 
	local deviation = playerAngle - playerHeading
	local absDeviation = math.abs(deviation)
	local leftover = math.abs(absDeviation - math.pi)
	
	if (leftover > (math.pi * .85) and leftover < (math.pi * 1.15)) then
		return true
	end
    return false
end
ff["EntityIsFront"] = EntityIsFront
function EntityIsFrontTight(entity)
	if not entity or entity.id == Player.id then return false end
	
	local ppos = ml_global_information.Player_Position
	local epos = entity.pos
	local playerHeading = ConvertHeading(ppos.h)
	
	local playerAngle = math.atan2(epos.x - ppos.x, epos.z - ppos.z) 
	local deviation = playerAngle - playerHeading
	local absDeviation = math.abs(deviation)
	local leftover = math.abs(absDeviation - math.pi)
	
	if (leftover > (math.pi * .95) and leftover < (math.pi * 1.05)) then
		return true
	end
    return false
end
ff["EntityIsFrontTight"] = EntityIsFrontTight
function Distance3DT(pos1,pos2)
	assert(type(pos1) == "table","Distance3DT - expected type table for first argument")
	assert(type(pos2) == "table","Distance3DT - expected type table for second argument")
	
	local distance = Distance3D(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z)
	return distance
end
ff["Distance3DT"] = Distance3DT
function ConvertHeading(heading)
	if (heading < 0) then
		return heading + 2 * math.pi
	else
		return heading
	end
end
ff["ConvertHeading"] = ConvertHeading
function HeadingToRadians(heading)
	return heading + math.pi
end
ff["HeadingToRadians"] = HeadingToRadians
function RadiansToHeading(radians)
	return radians - math.pi
end
ff["RadiansToHeading"] = RadiansToHeading
function DegreesToHeading(degrees)
	return RadiansToHeading(math.rad(degrees))
end
ff["DegreesToHeading"] = DegreesToHeading
function HeadingToDegrees(heading)
	return math.deg(HeadingToRadians(heading))
end
ff["HeadingToDegrees"] = HeadingToDegrees
function TurnAround(sync)	
	local sync = sync or false
	local newHeading = HeadingToDegrees(ml_global_information.Player_Position.h)
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
ff["TurnAround"] = TurnAround
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
ff["PosIsEqual"] = PosIsEqual
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
ff["AngleFromPos"] = AngleFromPos
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
ff["FindPointOnCircle"] = FindPointOnCircle
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
ff["FindPointLeftRight"] = FindPointLeftRight
function GetPosFromDistanceHeading(startPos, distance, heading)
	local head = ConvertHeading(heading)
	local newX = distance * math.sin(head) + startPos.x
	local newZ = distance * math.cos(head) + startPos.z
	return {x = newX, y = startPos.y, z = newZ}
end
ff["GetPosFromDistanceHeading"] = GetPosFromDistanceHeading
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
ff["GetFateByID"] = GetFateByID
function GetApprovedFates()
	local approvedFates = {}
	
	local level = Player.level
	local fatelist = MapObject:GetFateList()
	if (ValidTable(fatelist)) then
		for _,fate in pairs(fatelist) do
			local minFateLevel = tonumber(gMinFateLevel) or 0
			local maxFateLevel = tonumber(gMaxFateLevel) or 0
			
			local isChain,firstChain = ffxiv_task_fate.IsChain(ml_global_information.Player_Map, fate.id)
			local isPrio = ffxiv_task_fate.IsHighPriority(ml_global_information.Player_Map, fate.id)
			
			if ((minFateLevel == 0 or (fate.level >= (level - minFateLevel))) and 
				(maxFateLevel == 0 or (fate.level <= (level + maxFateLevel)))) 
			then
				if (not (isChain or isPrio) and (fate.type == 0 and gDoBattleFates == "1" and fate.completion >= tonumber(gFateBattleWaitPercent))) then
					table.insert(approvedFates,fate)
				elseif (not (isChain or isPrio) and (fate.type == 1 and gDoBossFates == "1" and fate.completion >= tonumber(gFateBossWaitPercent))) then
					table.insert(approvedFates,fate)
				elseif (not (isChain or isPrio) and (fate.type == 2 and gDoGatherFates == "1" and fate.completion >= tonumber(gFateGatherWaitPercent))) then
					table.insert(approvedFates,fate)
				elseif (not (isChain or isPrio) and (fate.type == 3 and gDoDefenseFates == "1" and fate.completion >= tonumber(gFateDefenseWaitPercent))) then
					table.insert(approvedFates,fate)
				elseif (not (isChain or isPrio) and (fate.type == 4 and gDoEscortFates == "1" and fate.completion >= tonumber(gFateEscortWaitPercent))) then
					table.insert(approvedFates,fate)
				elseif ((isChain or isPrio) and gDoChainFates == "1") then
					if (fate.completion >= tonumber(gFateChainWaitPercent) or not firstChain) then
						table.insert(approvedFates,fate)
					end
				end
			end
		end
	end
	
	return approvedFates
end
ff["GetApprovedFates"] = GetApprovedFates
function IsFateApproved(fateid)
	local fateid = tonumber(fateid) or 0
	if (fateid == 0) then
		return false
	end
	
	local fateList = GetApprovedFates()
	if (fateList) then
		for k,fate in pairs(fateList) do
			if (fate.id == fateid) then
				return true
			end
		end
	end
	
	if (ffxiv_task_fate.IsHighPriority(ml_global_information.Player_Map, fateid) or ffxiv_task_fate.IsChain(ml_global_information.Player_Map, fateid)) then
		return true
	end
	
	return false
end
ff["IsFateApproved"] = IsFateApproved
function IsInsideFate()
	local closestFate = GetClosestFate()
	if (ValidTable(closestFate)) then
		local fatePos = {x = closestFate.x, y = closestFate.y, z = closestFate.z}
		local myPos = ml_global_information.Player_Position
		local dist = Distance2D(myPos.x,myPos.z,fatePos.x,fatePos.z)
		if (dist < closestFate.radius) then
			return true
		end
	end
	
	return false
end
ff["IsInsideFate"] = IsInsideFate
function GetClosestFate(pos)
	local fateList = GetApprovedFates()
	if (ValidTable(fateList)) then
		--d("Found some approved fates.")
        local nearestFate = nil
        local nearestDistance = 9999
        local level = Player.level
		local myPos = ml_global_information.Player_Position
		local whitelistString = ml_blacklist.GetExcludeString("FATE Whitelist")
		local whitelistTable = {}
		
		if (not IsNullString(whitelistString)) then
			for entry in StringSplit(whitelistString,";") do
				local delimiter = entry:find('-')
				if (delimiter ~= nil and delimiter ~= 0) then
					local mapid = entry:sub(0,delimiter-1)
					local fateid = entry:sub(delimiter+1)
					if (tonumber(mapid) == ml_global_information.Player_Map) then
						whitelistTable[fateid] = true
					end
				end
			end
		end
		
		if (ValidTable(whitelistTable)) then
			for k, fate in pairs(fateList) do
				if (whitelistTable[fate.id] and	fate.status == 2) then	
					local p,dist = NavigationManager:GetClosestPointOnMesh({x=fate.x, y=fate.y, z=fate.z},false)
					if (p and dist <= 5) then
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
			local validFates = {}
			--Add fates that are high priority or chains first.
			for k, fate in pairs(fateList) do
				if (not ml_blacklist.CheckBlacklistEntry("Fates", fate.id)) then
					if (fate.status == 2) then	
						if (ffxiv_task_fate.IsHighPriority(ml_global_information.Player_Map, fate.id) or ffxiv_task_fate.IsChain(ml_global_information.Player_Map, fate.id)) then
							local p,dist = NavigationManager:GetClosestPointOnMesh({x=fate.x, y=fate.y, z=fate.z},false)
							if (p and dist <= 20) then
								table.insert(validFates,fate)
								--d("Added 1 high priority fate.")
							end
						end
					end
				end
			end
			
			if (not ValidTable(validFates)) then
				for k, fate in pairs(fateList) do
					if (not ml_blacklist.CheckBlacklistEntry("Fates", fate.id)) then
						if (fate.status == 2) then	
							local p,dist = NavigationManager:GetClosestPointOnMesh({x=fate.x, y=fate.y, z=fate.z},false)
							if (p and dist <= 20) then
								table.insert(validFates,fate)
								--d("Added 1 normal fate.")
							end
						end
					end
				end
			end
			
			if (ValidTable(validFates)) then
				--d("Found some valid fates, figuring out which one is closest.")
				for k, fate in pairs(validFates) do
					local distance = Distance3D(myPos.x,myPos.y,myPos.z,fate.x,fate.y,fate.z) or 0
					if (distance ~= 0) then
						if (not nearestFate or (nearestFate and (distance < nearestDistance))) then
							nearestFate = shallowcopy(fate)
							nearestDistance = distance
						end
					end
				end
			end
		end
    
        if (nearestFate ~= nil) then
			local fate = nearestFate
			--d("Fate details: Name="..fate.name..",id="..tostring(fate.id)..",completion="..tostring(fate.completion)..",pos="..tostring(fate.x)..","..tostring(fate.y)..","..tostring(fate.z))
            return nearestFate
        end
    end
    
    return nil
end
ff["GetClosestFate"] = GetClosestFate
function IsOnMap(mapid)
	local mapid = tonumber(mapid)
	if (ml_global_information.Player_Map == mapid) then
		return true
	end
	
	return false
end
ff["IsOnMap"] = IsOnMap
function ScanForMobs(ids,distance)
	local ids = (type(ids) == "string" and ids) or tostring(ids)
	local maxdistance = tonumber(distance) or 30
	local el = EntityList("nearest,targetable,alive,contentid="..ids..",maxdistance="..tostring(maxdistance))
	if (ValidTable(el)) then
		local i,e = next(el)
		if (i and e) then
			return true
		end
	end
	
	local el = EntityList("nearest,aggro,alive,contentid="..ids..",maxdistance="..tostring(maxdistance))
	if (ValidTable(el)) then
		local i,e = next(el)
		if (i and e) then
			return true
		end
	end

	return false
end
ff["ScanForMobs"] = ScanForMobs
function ScanForCaster(ids,distance,spells)
	local ids = (type(ids) == "string" and ids) or tostring(ids)
	local spells = (type(spells) == "string" and spells) or tostring(spells)
	
	local maxdistance = tonumber(distance) or 30
	local el = EntityList("nearest,targetable,alive,contentid="..ids..",maxdistance="..tostring(maxdistance))
	if (ValidTable(el)) then
		for i,e in pairs(el) do
			if (i and e and e.castinginfo) then
				if (MultiComp(e.castinginfo.channelingid,spells) or MultiComp(e.castinginfo.castingid,spells)) then
					return true
				end
			end
		end
	end
	
	return false
end
ff["ScanForCaster"] = ScanForCaster
function ScanForObjects(ids,distance)
	local ids = (type(ids) == "string" and ids) or tostring(ids)
	local maxdistance = tonumber(distance) or 30
	local el = EntityList("nearest,targetable,contentid="..ids..",maxdistance="..tostring(maxdistance))
	if (ValidTable(el)) then
		local i,e = next(el)
		if (i and e) then
			return true
		end
	end
	
	return false
end
ff["ScanForObjects"] = ScanForObjects
function CanUseCannon()
	if (ml_global_information.Player_IsLocked) then
		local misc = ActionList("type=1,level=0")
		if (ValidTable(misc)) then
			for i,skill in pairsByKeys(misc) do
				if (skill.id == 1134 or skill.id == 1437 or skill.id == 2630 or skill.id == 1128 or skill.id == 2434) then
					if (skill.isready) then
						return true
					end
				end
			end
		end
	end
	return false
end
ff["CanUseCannon"] = CanUseCannon
function GetPathDistance(pos1,pos2)
	assert(pos1 and pos1.x and pos1.y and pos1.z,"First argument to GetPathDistance is invalid.")
	assert(pos2 and pos2.x and pos2.y and pos2.z,"Second argument to GetPathDistance is invalid.")
	
	local dist = nil
	
	local p1,dist1 = NavigationManager:GetClosestPointOnMesh(pos1) or pos1
	local p2,dist2 = NavigationManager:GetClosestPointOnMesh(pos2) or pos2
	
	local path = NavigationManager:GetPath(p1.x,p1.y,p1.z,p2.x,p2.y,p2.z)
	if (ValidTable(path)) then
		local pathdist = PathDistance(path)
		if (ValidTable(pathdist)) then
			dist = pathdist
		end
	end	
	
	if (dist == nil) then
		dist = Distance3DT(pos1,pos2)
	end
	
	return dist
end
ff["GetPathDistance"] = GetPathDistance
--d(tostring(HasNavPath({x = 74.20,y = 53.83,z = 146.82},{x = -261.51,y = 149.58,z = 20.098554611206})))
--d(NavigationManager:GetPointToMeshDistance(Player.pos,true))
function HasNavPath(pos1,pos2)
	assert(pos1 and pos1.x and pos1.y and pos1.z,"First argument to GetPathDistance is invalid.")
	assert(pos2 and pos2.x and pos2.y and pos2.z,"Second argument to GetPathDistance is invalid.")
	
	local p1 = NavigationManager:GetClosestPointOnMesh(pos1)
	local p2 = NavigationManager:GetClosestPointOnMesh(pos2)
	
	local dist1 = NavigationManager:GetPointToMeshDistance(pos1,false)
	local dist2 = NavigationManager:GetPointToMeshDistance(pos2,false)
	
	if (dist1 > 15) then
		d("Position 1 is a distance of :"..tostring(dist1).." from nearest mesh point.")
	end
	if (dist2 > 15) then
		d("Position 2 is a distance of :"..tostring(dist2).." from nearest mesh point.")
	end
	
	if (p1 and p2) then
		--[[
		local omcs = {}
		local omcfile = ml_marker_mgr.markerPath..ml_mesh_mgr.GetFileName(gmeshname)..".nxi"
		local inFile,err = io.open(omcfile, "r")
		if (not err) then
			for line in inFile:lines() do
				local omc = StringToTable(line, '%s')
				if (omc) then
					local startingPoint = {x = omc[2], y = omc[3], z - omc[4]}
					local endingPoint = {x = omc[5], y = omc[6], z - omc[7]}
					if (ValidTable(startingPoint) and ValidTable(endingPoint)) then
						table.insert(omcs,omc)
					end
				end
			end

			inFile:close()
		end
		
		--]]
		local path = NavigationManager:GetPath(p1.x,p1.y,p1.z,p2.x,p2.y,p2.z)
		if (ValidTable(path)) then
		
			local lastPos = path[TableSize(path)]
			if (ValidTable(lastPos)) then
				local finaldist = Distance3D(prevPos.x,prevPos.y,prevPos.z,p2.x,p2.y,p2.z)
				if (finaldist > 5) then
					local minipoints = GetLinePoints(prevPos,p2,5)
					if (ValidTable(minipoints)) then
						local validCounter = 0
						local invalidCounter = 0
						
						for i,pos in pairsByKeys(minipoints) do
							local meshdist = NavigationManager:GetPointToMeshDistance(pos,false)
							if (meshdist > 4) then
								invalidCounter = invalidCounter + 1
							else
								validCounter = validCounter + 1
							end
						end						
					end
				else
					return true
				end
			end
			
			--[[
			local points = {}
			
			local x = 1
			local prevPos = pos1
			
			for i,pos in pairsByKeys(path) do
				--Add the previous points list.
				points[x] = prevPos
				x = x + 1
				
				local dist = Distance3D(prevPos.x,prevPos.y,prevPos.z,pos.x,pos.y,pos.z)
				if (dist > 5) then
					local minipoints = GetLinePoints(prevPos,pos,5)
					if (ValidTable(minipoints)) then
						for i,pos in pairsByKeys(minipoints) do
							points[x] = pos
							x = x + 1
						end
					end
				end
				prevPos = {x = pos.x, y = pos.y, z = pos.z}
			end
			
			local finaldist = Distance3D(prevPos.x,prevPos.y,prevPos.z,p2.x,p2.y,p2.z)
			if (finaldist > 5) then
				local minipoints = GetLinePoints(prevPos,p2,5)
				if (ValidTable(minipoints)) then
					for i,pos in pairsByKeys(minipoints) do
						points[x] = pos
						x = x + 1
					end
				end
			end
			
			if (ValidTable(points)) then
				ffxiv_task_test.RenderPoints(points)	
				local validPath = true
				for i,point in pairsByKeys(points) do
					local meshdist = NavigationManager:GetPointToMeshDistance(point,false)
					if (meshdist > 10) then
						d("Point x="..tostring(point.x)..",y="..tostring(point.y)..",z="..tostring(point.z).." has no nearby mesh.")
						validPath = false
					else
						d("Point x="..tostring(point.x)..",y="..tostring(point.y)..",z="..tostring(point.z).." has nearby mesh at a distance of ["..tostring(meshdist).."].")
					end
				end
				
				if (validPath) then
					return true
				end
			end
			--]]
		end
	end
	
	return false
end
ff["HasNavPath"] = HasNavPath
function GetLinePoints(pos1,pos2,length)
	local distance = Distance3D(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z)
	local segments = math.floor(distance / length)
	
	local points = {}
	for x=1,segments do
		local thisDist = Distance3D(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z)
		local ratio = length / thisDist
		
		local newX = pos1.x + (ratio * (pos2.x - pos1.x))
		local newY = pos1.y + (ratio * (pos2.y - pos1.y))
		local newZ = pos1.z + (ratio * (pos2.z - pos1.z))
		
		local newPos = {x = newX, y = newY, z = newZ}
		points[x] = newPos
		pos1 = newPos
	end
	
	return points
end
ff["GetLinePoints"] = GetLinePoints
function GetAggroDetectionPoints(pos1,pos2)
	assert(ValidTable(pos1),"First argument is not a valid position.")
	assert(ValidTable(pos2),"Second argument is not a valid position.")
	
	local points = {}
	local path = NavigationManager:GetPath(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z)
	if (path) then
		local x = 1
		local prevPos = pos1
		
		for i,pos in pairsByKeys(path) do
			--Add the previous points list.
			points[x] = prevPos
			x = x + 1
			
			local dist = Distance3D(prevPos.x,prevPos.y,prevPos.z,pos.x,pos.y,pos.z)
			if (dist > 5) then
				local minipoints = GetLinePoints(prevPos,pos,5)
				if (ValidTable(minipoints)) then
					for i,pos in pairsByKeys(minipoints) do
						points[x] = pos
						x = x + 1
					end
				end
			end
			prevPos = {x = pos.x, y = pos.y, z = pos.z}
		end
	end
	return points
end
ff["GetAggroDetectionPoints"] = GetAggroDetectionPoints
function PathDistanceTable(gotoPos)
	if (ValidTable(gotoPos)) then
		local ppos = ml_global_information.Player_Position
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
ff["PathDistanceTable"] = PathDistanceTable
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
ff["IsLeader"] = IsLeader
function GetPartyLeader()
	if (gBotMode == GetString("partyMode") and gPartyGrindUsePartyLeader == "0") then
		if (gPartyLeaderName ~= "") then
			local el = EntityList("type=1,name="..gPartyLeaderName)
			if (ValidTable(el)) then
				local i,leaderentity = next (el)
				if (i and leaderentity) then
					return leaderentity, true
				end
			end
			
			local party = EntityList.myparty
			if (ValidTable(party)) then
				for i,member in pairs(party) do
					if (member.name == gPartyLeaderName) then
						leader = member
						return leader, false
					end
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
ff["GetPartyLeader"] = GetPartyLeader
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
ff["GetPartyLeaderPos"] = GetPartyLeaderPos
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
ff["IsInParty"] = IsInParty
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
	if (gBotMode == GetString("dutyMode")) then
		return true
	end
	
	if (gBotMode == GetString("gatherMode")) then
		local node = EntityList:Get(targetid)
		if (node and node.distance2d < 4) then
			return true
		end
		return false
	end
	
	--If we're casting on the target, consider the player in-range, so that it doesn't attempt to move and interrupt the cast.
	if ( ml_global_information.Player_Casting.channelingid ~= nil and ml_global_information.Player_Casting.channeltargetid == targetid) then
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
		return (target.distance - target.hitradius) <= (highestRange * (tonumber(gCombatRangePercent) / 100))
	end
	
	--d("InCombatRange based on range:"..tostring((target.distance2d - target.hitradius) <= (3 * (tonumber(gCombatRangePercent) / 100) )))
	return ((target.distance - target.hitradius) <= (3 * (tonumber(gCombatRangePercent) / 100) ))
end
ff["InCombatRange"] = InCombatRange
function CanAttack(targetid)
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
	
	local canCast = false
	local testSkill = SkillMgr.GCDSkills[Player.job]
	canCast = ActionList:CanCast(testSkill,target.id)
	return canCast
end
ff["CanAttack"] = CanAttack
function GetMounts()
	local MountsList = "None"
	local eq = ActionList("type=13")
	for k,v in pairs(eq) do
		MountsList = MountsList..","..v.name
	end
	
	return MountsList
end
ff["GetMounts"] = GetMounts
function GetMountID()
	local mountID
	local mountIndex
	local mountlist = ActionList("type=13")
	
	if (ValidTable(mountlist)) then
		--First pass, look for our named mount.
		for k,v in pairsByKeys(mountlist) do
			if (v.name == gMount) then
				local acMount = ActionList:Get(v.id,13)
				if (acMount and acMount.isready) then
					return v.id
				end
			end
		end
		
		--Second pass, look for any mount as backup.
		if (gMount == GetString("none")) then
			for k,v in pairsByKeys(mountlist) do
				local acMount = ActionList:Get(v.id,13)
				if (acMount and acMount.isready) then
					return v.id
				end
			end		
		end
	end
	
	return nil
end
ff["GetMountID"] = GetMountID
function IsMounting()
	return (not Player.ismounted and (Player.action == 83 or Player.action == 84 or Player.action == 165))
end
ff["IsMounting"] = IsMounting
function IsMounted()
	return (Player.ismounted or Player.action == 166)
end
ff["IsMounted"] = IsMounted
function IsDismounting()
	return (Player.ismounted and (Player.action == 32))
end
ff["IsDismounting"] = IsDismounting
function IsPositionLocked()
	return not ActionIsReady(2,5)
	--return (not ActionIsReady(2) and not Player.ismounted)
end
ff["IsPositionLocked"] = IsPositionLocked
function IsLoading()
	return (Quest:IsLoading() or ml_global_information.Player_Map == 0 or ml_mesh_mgr.meshLoading)
end
ff["IsLoading"] = IsLoading
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
ff["HasAction"] = HasAction
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
ff["ActionIsReady"] = ActionIsReady
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
					ml_task_hub:CurrentTask():SetDelay(1200)
				end
			end
		end
	end			
end
ff["Mount"] = Mount
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
			SendTextCommand("/mount")
			--ml_error("You need to select a Mount in the Minion Settings!")
		end
	end
end
ff["Dismount"] = Dismount
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
ff["Repair"] = Repair
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
ff["ShouldEat"] = ShouldEat
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
ff["Eat"] = Eat
function NodeHasItem(searchItem)
	if (searchItem and type(searchItem) == "string" and searchItem ~= "") then
		for itemName in StringSplit(searchItem,",") do
			local list = Player:GetGatherableSlotList()
			if (ValidTable(list)) then
				for i,item in pairs(list) do
					if (item.name == itemName) then
						return true
					end
				end
			end
		end
	end
    
    return false
end
ff["NodeHasItem"] = NodeHasItem
function WhitelistTarget()
	local target = ml_global_information.Player_Target
	if (target) then
		local key = GetUSString("contentIDEquals")
		
		local whitelistGlobal = tostring(_G["Field_"..key])
		if (whitelistGlobal ~= "") then
			whitelistGlobal = whitelistGlobal..";"..tostring(target.contentid)
		else
			whitelistGlobal = tostring(target.contentid)
		end
		_G["Field_"..key] = whitelistGlobal
		GUI_RefreshWindow(ml_marker_mgr.editwindow.name)
		
		if (ValidTable(ml_marker_mgr.currentEditMarker)) then
			ml_marker_mgr.currentEditMarker:SetFieldValue(key, _G["Field_"..key])
			ml_marker_mgr.WriteMarkerFile()
		end
	end
end
ff["WhitelistTarget"] = WhitelistTarget
function BlacklistTarget()
	local target = ml_global_information.Player_Target
	if (target) then
		local key = GetUSString("NOTcontentIDEquals")
		
		local blacklistGlobal = tostring(_G["Field_"..key])
		if (blacklistGlobal ~= "") then
			blacklistGlobal = blacklistGlobal..";"..tostring(target.contentid)
		else
			blacklistGlobal = tostring(target.contentid)
		end
		_G["Field_"..key] = blacklistGlobal
		GUI_RefreshWindow(ml_marker_mgr.editwindow.name)
		
		if (ValidTable(ml_marker_mgr.currentEditMarker)) then
			ml_marker_mgr.currentEditMarker:SetFieldValue(key, _G["Field_"..key])
			ml_marker_mgr.WriteMarkerFile()
		end
	end
end
ff["BlacklistTarget"] = BlacklistTarget
function IsMap(itemid)
	local itemid = tonumber(itemid) or 0
	return ((itemid >= 6687 and itemid <= 6692) or
		(itemid == 7884 or itemid == 8156 or itemid == 9900) or
		(itemid >= 12241 and itemid <= 12243))
end
ff["IsMap"] = IsMap
function IsGardening(itemid)
	local itemid = tonumber(itemid) or 0
	return ((itemid >= 7715 and itemid <= 7767) 
			or itemid == 8024
			or itemid == 5365)
end
ff["IsGardening"] = IsGardening
-- Ixali hidden items have a max item count of 5.
function IsIxaliRare(itemid)
	local itemid = tonumber(itemid) or 0
	local rares = {
		[2001392] = true,
		[2001389] = true,
		[2001427] = true,
		[2001416] = true,
		[2001413] = true,
		[2001425] = true,
	}
	return rares[itemid]
end
ff["IsIxaliRare"] = IsIxaliRare
-- Ixali "regular" items have a max item count of 15.
function IsIxaliSemiRare(itemid)
	local itemid = tonumber(itemid) or 0
	local rares = {
		[2001391] = true,
		[2001388] = true,
		[2001426] = true,
		[2001415] = true,
		[2001412] = true,
		[2001424] = true,
	}
	return rares[itemid]
end
ff["IsIxaliSemiRare"] = IsIxaliSemiRare
function IsChocoboFood(itemid)
	local itemid = tonumber(itemid) or 0
	return ((itemid >= 10094 and itemid <= 10095) or
			(itemid >= 10097 and itemid <= 10098))
end
ff["IsChocoboFood"] = IsChocoboFood
function IsChocoboFoodSpecial(itemid)
	local itemid = tonumber(itemid) or 0
	
	local special = {
		[10098] = true,
		[10095] = true,
	}
	return special[itemid]
end
ff["IsChocoboFoodSpecial"] = IsChocoboFoodSpecial
function IsRareItem(itemid)
	local itemid = tonumber(itemid) or 0
	local rareItem = {
		[8024] = true,
		[5365] = true,
		[10099] = true,
		[10335] = true,
		
		[12946] = true,
		[12947] = true,
		[12948] = true,
		[12949] = true,
		[12950] = true,
		
		
		[12956] = true,
		[12957] = true,
		[12958] = true,
		[12959] = true,
		[12960] = true,
	}
	
	return rareItem[itemid]
end
ff["IsRareItem"] = IsRareItem
function IsRareItemSpecial(itemid)
	local itemid = tonumber(itemid) or 0
	local superRare = {
		[12951] = true,
		[12952] = true,
		[12953] = true,
		[12954] = true,
		[12955] = true,
		[12961] = true,
		[12962] = true,
		[12963] = true,
		[12964] = true,
		[12965] = true,
		[12966] = true,
	}
	
	return superRare[itemid]
end
ff["IsRareItemSpecial"] = IsRareItemSpecial
function IsUnspoiled(contentid)
	return (contentid >= 5 and contentid <= 8)
end
ff["IsUnspoiled"] = IsUnspoiled
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
		jobID == FFXIV.JOBS.NINJA or
		jobID == FFXIV.JOBS.MACHINIST
    then
        return GetString("dps")
    elseif
        jobID == FFXIV.JOBS.CONJURER or
        jobID == FFXIV.JOBS.SCHOLAR or
        jobID == FFXIV.JOBS.WHITEMAGE or
		jobID == FFXIV.JOBS.ASTROLOGIAN
    then
        return GetString("healer")
    elseif 
        jobID == FFXIV.JOBS.GLADIATOR or
        jobID == FFXIV.JOBS.MARAUDER or
        jobID == FFXIV.JOBS.PALADIN or
        jobID == FFXIV.JOBS.WARRIOR or 
		jobID == FFXIV.JOBS.DARKKNIGHT
    then
        return GetString("tank")
    end
end
ff["GetRoleString"] = GetRoleString
function GetRoleTable(rolestring)
	if (rolestring == "DPS") then
		return {
			[FFXIV.JOBS.ARCHER] = true,
			[FFXIV.JOBS.BARD] = true,
			[FFXIV.JOBS.BLACKMAGE] = true,
			[FFXIV.JOBS.DRAGOON] = true,
			[FFXIV.JOBS.LANCER] = true,
			[FFXIV.JOBS.MONK] = true,
			[FFXIV.JOBS.PUGILIST] = true,
			[FFXIV.JOBS.ROGUE] = true,
			[FFXIV.JOBS.NINJA] = true,
			[FFXIV.JOBS.MACHINIST] = true,
		}
	elseif (rolestring == "Healer") then
		return {
			[FFXIV.JOBS.CONJURER] = true,
			[FFXIV.JOBS.SCHOLAR] = true,
			[FFXIV.JOBS.WHITEMAGE] = true,
			[FFXIV.JOBS.ASTROLOGIAN] = true,
		}
	elseif (rolestring == "Tank") then
		return {
			[FFXIV.JOBS.GLADIATOR] = true,
			[FFXIV.JOBS.MARAUDER] = true,
			[FFXIV.JOBS.PALADIN] = true,
			[FFXIV.JOBS.WARRIOR] = true,
			[FFXIV.JOBS.DARKKNIGHT] = true,
		}
	elseif (rolestring == "Caster") then
		return {
			[FFXIV.JOBS.ARCANIST] = true,
			[FFXIV.JOBS.BLACKMAGE] = true,
			[FFXIV.JOBS.SUMMONER] = true,
			[FFXIV.JOBS.THAUMATURGE] = true,
			[FFXIV.JOBS.WHITEMAGE] = true,
			[FFXIV.JOBS.CONJURER] = true,
			[FFXIV.JOBS.SCHOLAR] = true,
			[FFXIV.JOBS.ASTROLOGIAN] = true,
		}
	end
	return nil
end
ff["GetRoleTable"] = GetRoleTable
function IsMeleeDPS(jobID)
	local jobID = tonumber(jobID)
	return 	jobID == FFXIV.JOBS.MONK or
			jobID == FFXIV.JOBS.PUGILIST or
			jobID == FFXIV.JOBS.DRAGOON or
			jobID == FFXIV.JOBS.LANCER or
			jobID == FFXIV.JOBS.ROGUE or
			jobID == FFXIV.JOBS.NINJA
end
ff["IsMeleeDPS"] = IsMeleeDPS
function IsRangedDPS(jobID)
	local jobID = tonumber(jobID)
	return 	jobID == FFXIV.JOBS.ARCANIST or
			jobID == FFXIV.JOBS.ARCHER or
			jobID == FFXIV.JOBS.BARD or
			jobID == FFXIV.JOBS.BLACKMAGE or
			jobID == FFXIV.JOBS.SUMMONER or
			jobID == FFXIV.JOBS.THAUMATURGE or
			jobID == FFXIV.JOBS.MACHINIST
end
ff["IsRangedDPS"] = IsRangedDPS
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
			jobID == FFXIV.JOBS.WHITEMAGE or
			jobID == FFXIV.JOBS.ASTROLOGIAN or
			jobID == FFXIV.JOBS.MACHINIST
end
ff["IsRanged"] = IsRanged
function IsPhysicalDPS(jobID)
	local jobID = tonumber(jobID)
	return 	jobID == FFXIV.JOBS.MONK or
			jobID == FFXIV.JOBS.PUGILIST or
			jobID == FFXIV.JOBS.DRAGOON or
			jobID == FFXIV.JOBS.LANCER or
			jobID == FFXIV.JOBS.ROGUE or
			jobID == FFXIV.JOBS.NINJA or 
			jobID == FFXIV.JOBS.ARCHER or
			jobID == FFXIV.JOBS.BARD or
			jobID == FFXIV.JOBS.MACHINIST
end
ff["IsPhysicalDPS"] = IsPhysicalDPS
function IsCasterDPS(jobID)
	local jobID = tonumber(jobID)
	return 	jobID == FFXIV.JOBS.ARCANIST or
			jobID == FFXIV.JOBS.BLACKMAGE or
			jobID == FFXIV.JOBS.SUMMONER or
			jobID == FFXIV.JOBS.THAUMATURGE
end
ff["IsCasterDPS"] = IsCasterDPS
function IsCaster(jobID)
	local jobID = tonumber(jobID)
	return 	jobID == FFXIV.JOBS.ARCANIST or
			jobID == FFXIV.JOBS.BLACKMAGE or
			jobID == FFXIV.JOBS.SUMMONER or
			jobID == FFXIV.JOBS.THAUMATURGE or
			jobID == FFXIV.JOBS.WHITEMAGE or
			jobID == FFXIV.JOBS.CONJURER or
			jobID == FFXIV.JOBS.SCHOLAR or 
			jobID == FFXIV.JOBS.ASTROLOGIAN
end
ff["IsCaster"] = IsCaster
function IsHealer(jobID)
	local jobID = tonumber(jobID)
	return 	jobID == FFXIV.JOBS.WHITEMAGE or
			jobID == FFXIV.JOBS.CONJURER or
			jobID == FFXIV.JOBS.SCHOLAR or 
			jobID == FFXIV.JOBS.ASTROLOGIAN
end
ff["IsHealer"] = IsHealer
function IsTank(jobID)
	local jobID = tonumber(jobID)
	local tanks = {
		[FFXIV.JOBS.GLADIATOR] = true,
		[FFXIV.JOBS.MARAUDER] = true,
		[FFXIV.JOBS.PALADIN] = true,
		[FFXIV.JOBS.WARRIOR] = true,
		[FFXIV.JOBS.DARKKNIGHT] = true,
	}
	
	return tanks[jobID]
end
ff["IsTank"] = IsTank
function IsGatherer(jobID)
	local jobID = tonumber(jobID)
	if (jobID >= 16 and jobID <= 17) then
		return true
	end
	
	return false
end
ff["IsGatherer"] = IsGatherer
function IsFighter(jobID)
	local jobID = tonumber(jobID)
	if ((jobID >= 0 and jobID <= 8) or
		(jobID >= 19))
	then
		return true
	end
	
	return false
end
ff["IsFighter"] = IsFighter
function IsCrafter(jobID)
	local jobID = tonumber(jobID)
	if (jobID >= 8 and jobID <= 15) then
		return true
	end
	
	return false
end
ff["IsCrafter"] = IsCrafter
function IsFisher(jobID)
	local jobID = tonumber(jobID)
	return jobID == 18
end
ff["IsFisher"] = IsFisher
function PartyMemberWithBuff(hasbuffs, hasnot, maxdistance) 
	if (maxdistance==nil or maxdistance == "") then
		maxdistance = 30
	end
	
	local el = EntityList("myparty,alive,targetable,chartype=4,maxdistance="..tostring(maxdistance))
	--local el = EntityList("myparty,alive,chartype=4,maxdistance="..tostring(maxdistance))
	if (ValidTable(el)) then
		for i,e in pairs(el) do	
			if ((hasbuffs=="" or HasBuffs(e,hasbuffs)) and (hasnot=="" or MissingBuffs(e,hasnot))) then
				return e
			end						
		end
	end
	
	return nil
end
ff["PartyMemberWithBuff"] = PartyMemberWithBuff
function PartySMemberWithBuff(hasbuffs, hasnot, maxdistance) 
	maxdistance = maxdistance or 30
 
	local el = EntityList("myparty,alive,targetable,chartype=4,maxdistance="..tostring(maxdistance))
	--local el = EntityList("myparty,alive,chartype=4,maxdistance="..tostring(maxdistance))
	if (ValidTable(el)) then
		for i,e in pairs(el) do	
			if ((hasbuffs=="" or HasBuffs(e,hasbuffs)) and (hasnot=="" or MissingBuffs(e,hasnot))) then
				return e
			end						
		end
	end

	if ((hasbuffs=="" or HasBuffs(Player,hasbuffs)) and (hasnot=="" or MissingBuffs(Player,hasnot))) then
        return Player
    end
	
	return nil
end
ff["PartySMemberWithBuff"] = PartySMemberWithBuff
function GetLocalAetheryte()
    local list = Player:GetAetheryteList()
    for index,aetheryte in ipairs(list) do
        if (aetheryte.islocalmap) then
            return aetheryte.id
        end
    end
    
    return nil
end
ff["GetLocalAetheryte"] = GetLocalAetheryte
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
ff["GetAttunedAetheryteList"] = GetAttunedAetheryteList
function GetHomepoint()
	local homepoint = 0
	
	local attuned = GetAttunedAetheryteList()
	if (ValidTable(attuned)) then
		for id,aetheryte in pairsByKeys(attuned) do
			if (aetheryte.ishomepoint) then
				homepoint = aetheryte.territory
			end
		end
	end
	return homepoint
end
ff["GetHomepoint"] = GetHomepoint
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
ff["GetAetheryteByID"] = GetAetheryteByID
function IsAetheryteUnattuned(id)
	local aethid = tonumber(id) or 0
	local aetheryte = GetAetheryteByID(aethid)
	if (aetheryte) then
		return not aetheryte.isattuned
	end
	return false
end
ff["IsAetheryteUnattuned"] = IsAetheryteUnattuned
function GetAetheryteByMapID(id, p)
	local pos = p
	
	local mapid = ml_global_information.Player_Map
	if (id == 133 and mapid ~= 132) then
		id = 132
	elseif (id == 128 and mapid ~= 129) then
		id = 129
	elseif (id == 131 and mapid ~= 130) then
		id = 130
	elseif (id == 419 and mapid ~= 418) then
		id = 418
	elseif (id == 399 and mapid ~= 478) then
		id = 478
	end
	
	if 	(mapid == 131 and id == 130) or
		(mapid == 128 and id == 129) or
		(mapid == 133 and id == 133) or
		(mapid == 418 and (id == 419 or id == 439 or id == 427 or id == 456 or id == 433)) or
		(mapid == 399 and id == 478)
	then
		return nil
	end
	
	sharedMaps = {
		[153] = { name = "South Shroud",
			[1] = { name = "Quarrymill", id = 5, x = 181, z = -66},
			[2] = { name = "Camp Tranquil", id = 6, x = -226, z = 355},
		},
		[137] = {name = "Eastern La Noscea",
			[1] = { name = "Costa Del Sol", id = 11, x = 0, z = 0},
			[2] = { name = "Wineport", id = 12, x = 0, z = 0},
		},
		[138] = {name = "Western La Noscea",
			[1] = { name = "Swiftperch", id = 13, x = 652, z = 509 },
			[2] = { name = "Aleport", id = 14, x = 261, z = 223 },		
		},
		[146] = {name = "Southern Thanalan",
			[1] = { name = "Little Ala Mhigo", id = 19, x = -165, z = -414 },
			[2] = { name = "Forgotten Springs", id = 20, x = -320, z = 406 },
		},
		[147] = {name = "Northern Thanalan",
			[1] = { name = "Bluefog", id = 21, x = 24, z = 458 },
			[2] = { name = "Ceruleum", id = 22, x = -24, z = -27 },
		},
		[401] = {name = "Sea of Clouds",
			[1] = { name = "Cloudtop", id = 72, x = -611, z = 545 },
			[2] = { name = "OkZundu", id = 73, x = -606, z = -419 },
		},
		[398] = {name = "Dravanian Forelands",
			[1] = { name = "Tailfeather", id = 76, x = 533, z = 35 },
			[2] = { name = "Anyx", id = 77, x = -300, z = 30 },
		},
		[400] = {name = "Churning Mists",
			[1] = { name = "Moghome", id = 78, x = 256, z = 599 },
			[2] = { name = "Zenith", id = 79, x = -583, z = 316 },
		},		
	}
	
	local list = GetAttunedAetheryteList()
	if (not pos or not sharedMaps[id]) then
		for index,aetheryte in pairsByKeys(list) do
			if (aetheryte.territory == id) then
				return id, aetheryte.id
			end
		end
	else
		local map = sharedMaps[id]
		if (id == 137) then
			return id, ((pos.x > 218 and pos.z > 51) and map[1].id) or map[2].id
		else 
			local distance1 = Distance2D(pos.x, pos.z, map[1].x, map[1].z)
			local distance2 = Distance2D(pos.x, pos.z, map[2].x, map[2].z)
			return id, ((distance1 < distance2) and map[1].id) or map[2].id
		end
	end
	
	return nil
end
ff["GetAetheryteByMapID"] = GetAetheryteByMapID
function GetAetheryteLocation(id)
	local aethid = tonumber(id) or 0
	aetherytes = 
	{
		[2] = {
			mapid = 132, x = 30.390216827393, y = 1.8258748054504, z = 26.265508651733
		},
		[3] = {
			mapid = 148, x = 13.585005760193, y = -1.1827243566513, z = 41.725193023682
		},
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
			mapid = 130, x = -141.2413, y = -3.154881, z = -166.22462
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
		[70] = {
			mapid = 418, x = -68.819107055664, y = 8.1133041381836, z = 46.482696533203
		},
		[71] = {
			mapid = 397, x = 477.33963012695, y = 213.68281555176, z = 712.01037597656
		},
		[72] = {
			mapid = 401, x = -611.17010498047, y = -122.47959899902, z = 545.20111083984
		},
		[73] = {
			mapid = 401, x = -606.52301025391, y = -51.05184173584, z = -419.39642333984
		},
		[74] = {
			mapid = 402, x = -719.61926269531, y = -186.96055603027, z = -591.29595947266
		},
		[75] = {
			mapid = 478, x = 70.658157348633, y = 209.25, z = -15.381930351257
		},
		[76] = {
			mapid = 398, x = 533.27545166016, y = -50.119258880615, z = 35.244457244873
		},
		[77] = {
			mapid = 398, x = -300.9377746582, y = -21.131076812744, z = 30.079961776733
		},
		[78] = {
			mapid = 400, x = 256.49853515625, y = -41.158931732178, z = 599.15924072266
		},
		[79] = {
			mapid = 400, x = -583.82263183594, y = 49.774040222168, z = 316.41677856445
		},
	}
	
	local aetheryte = aetherytes[aethid]
	if (aetheryte) then
		return {x = aetheryte.x, y = aetheryte.y, z = aetheryte.z}
	end
	
	return nil
end
ff["GetAetheryteLocation"] = GetAetheryteLocation
function CanUseAetheryte(aethid)
	local aethid = tonumber(aethid) or 0
	if (aethid ~= 0) then
		local aetheryte = GetAetheryteByID(aethid)
		if (aetheryte) then
			if (GilCount() >= aetheryte.price and aetheryte.isattuned) then
				return true
			end
		end
	end
	
	return false
end
ff["CanUseAetheryte"] = CanUseAetheryte
function GetOffMapMarkerList(strMeshName, strMarkerType)
	local markerPath = ml_mesh_mgr.navmeshfilepath..strMeshName..".info"
	if (FileExists(markerPath)) then
		local markerList, e = persistence.load(markerPath)
		if (markerList) then
			local templateKey = ml_marker_mgr.GetTemplateKey(strMarkerType)
			if (templateKey) then
				local sublist = markerList[templateKey]
				if (sublist) then
					local namestring = ""
					for k,marker in pairs(sublist) do
						setmetatable(marker, {__index = ml_marker})
						
						local markerName = marker:GetName()
						if (namestring == "") then
							namestring = markerName
						else
							namestring = namestring..","..markerName
						end
					end
					return namestring
				else	
					ml_debug("No markers found on map for type ["..strMarkerType.."].")
				end
			end
		else
			d("Marker file could not be loaded successfully for destination mesh ["..tostring(strMeshName).."].")
			d("Error ["..e.."]")
		end
	else
		d("No marker file found for destination mesh ["..tostring(strMeshName).."].")
	end
	
	return nil
end
ff["GetOffMapMarkerList"] = GetOffMapMarkerList
function IsCityMap(mapid)
	local mapid = tonumber(mapid)
	local cityMaps = {
		[133] = true,
		[132] = true,
		[128] = true,
		[129] = true,
		[131] = true,
		[130] = true,
		[418] = true,
		[419] = true,
	}
	return cityMaps[mapid]
end
ff["IsCityMap"] = IsCityMap
function GetOffMapMarkerPos(strMeshName, strMarkerName)
	local newMarkerPos = nil
	
	local markerPath = ml_mesh_mgr.navmeshfilepath..strMeshName..".info"
	if (FileExists(markerPath)) then
		local markerList, e = persistence.load(markerPath)
		local markerName = strMarkerName
		
		local searchMarker = nil
		if (markerList) then
			for template, list in pairs(markerList) do
				if (template ~= "evacPoint") then
					for index, marker in pairs(list) do
						setmetatable(marker, {__index = ml_marker})
						
						if (marker:GetName() == markerName) then
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
			end
			if (searchMarker) then
				local markerFields = searchMarker.fields
				if (markerFields["x"] and markerFields["y"] and markerFields["z"]) then
					newMarkerPos = { x = markerFields["x"].value, y = markerFields["y"].value, z = markerFields["z"].value }
				end
			end
		else
			d("No markers found for destination mesh ["..tostring(strMeshName).."].")
		end
	end
	
	return newMarkerPos
end
ff["GetOffMapMarkerPos"] = GetOffMapMarkerPos
function ShouldTeleport(pos)
	if (ml_global_information.Player_IsLocked or ml_global_information.Player_IsLoading or ControlVisible("SelectString") or ControlVisible("SelectIconString") or IsShopWindowOpen()) then
		return false
	end
	
	if (ml_task_hub:CurrentTask().noTeleport) then
		return false
	end
	
	if (gTeleport == "0") then
		return false
	else
		if (gParanoid == "0") then
			return true
		else
			local scanDistance = 50
			local players = EntityList("type=1,maxdistance=".. scanDistance)
			local nearbyPlayers = TableSize(players)
			if nearbyPlayers > 0 then
				return false
			end
			
			if (pos or ml_task_hub:CurrentTask().pos) then
				local gotoPos = nil
				if (pos) then
					gotoPos = pos
				else
					gotoPos = ml_task_hub:CurrentTask().pos
				end
				
				local players = EntityList("type=1")
				if (players) then
					for i,entity in pairs(players) do
						local epos = entity.pos
						if (Distance3D(epos.x,epos.y,epos.z,gotoPos.x,gotoPos.y,gotoPos.z) <= 50) then
							return false
						end
					end
				end
			end
			
			return true
		end
	end
end
ff["ShouldTeleport"] = ShouldTeleport
function GetBlacklistIDString()
    -- otherwise first grab the global blacklist exclude string
    local excludeString = ml_blacklist.GetExcludeString(GetString("monsters"))
    
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
ff["GetBlacklistIDString"] = GetBlacklistIDString
function GetWhitelistIDString()	
    return ml_global_information.WhitelistContentID
end
ff["GetWhitelistIDString"] = GetWhitelistIDString
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
ff["GetPartySize"] = GetPartySize
function HasDutyUnlocked(dutyID)
	local dutyID = tonumber(dutyID)
	local dutyList = Duty:GetDutyList()
	if (not dutyList) then
		SendTextCommand("/dutyfinder")
	end
	
	if (dutyList) then
		for _, duty in pairs(dutyList) do
			if (duty.id == dutyID) then
				return true
			end
		end
	end
	
	return false
end
ff["HasDutyUnlocked"] = HasDutyUnlocked
function HuntingLogsUnlocked()	
	local requiredQuests = {
		[1] = 253,
		[2] = 533,
		[3] = 311,
		[4] = 23,
		[5] = 21,
		[6] = 22,
		[7] = 345,
		[8] = 453,
		[9] = 104,
	}
	
	for i,quest in pairs(requiredQuests) do
		if (Quest:IsQuestCompleted(quest)) then
			return true
		end
	end
	
	return false
end
ff["HuntingLogsUnlocked"] = HuntingLogsUnlocked
function GetBestGrindMap()
	local mapid = ml_global_information.Player_Map
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
		else
			return 148
		end
	elseif ( level >= 12 and level < 20) then
		if (inthanalan) then
			return 140 --western than
		elseif (inshroud) then
			return 152 --east shroud
		elseif (inlanoscea) then
			return 138 --middle la noscea
		else
			return 152
		end
	elseif (level >= 20 and level < 22) then
		return 152 --east shroud
	elseif (level >= 22 and level < 30) then
		return 153 --south shroud
	elseif (level >= 30 and level < 35) then
		return 137 --eastern la noscea
	elseif (level >= 35 and level < 45) then
		return 155 --coerthas
	elseif (level >= 45) then
		return 156 --mor dhona
	end
end
ff["GetBestGrindMap"] = GetBestGrindMap
function EquipItem(itemid, itemslot)
	local itemtype = tonumber(itemslot)
	local itemid = tonumber(itemid)
	
	local item = Inventory:Get(itemid)
	if (item and item.canequip) then
		item:Move(1000,itemslot)
	end
end
ff["EquipItem"] = EquipItem
function UnequipItem(itemid)
	local itemid = tonumber(itemid)
	
	local item = GetEquippedItem(itemid)
	if (item) then
		local itemData = GetItemData(item.id)
		if (itemData) then
			local armorySlot = GetArmorySlotForItem(itemData.slot)
			if (armorySlot) then
				local freeSlot = GetFirstFreeArmorySlot(armorySlot)
				if (freeSlot) then
					item:Move(armorySlot,freeSlot)
				end
			end
		end
	end
end
ff["UnequipItem"] = UnequipItem
function IsEquipped(itemid)
	local itemid = tonumber(itemid)
	local currEquippedItems = Inventory("type=1000")
	for id,item in pairs(currEquippedItems) do
		if (item.id == itemid) then
			return true
		end
	end
	return false
end
ff["IsEquipped"] = IsEquipped
function EquippedItemLevel(slot)
	local slot = tonumber(slot)
	local currEquippedItems = Inventory("type=1000")
	if (currEquippedItems) then
		for id,item in pairs(currEquippedItems) do
			if (item.slot == slot) then
				return item.level
			end
		end
	end
	
	--d("Could not find an equipped item in slot ["..tostring(slot).."], returning 0.")
	return 0
end
ff["EquippedItemLevel"] = EquippedItemLevel
function GetItemInSlot(equipSlot)
	local currEquippedItems = Inventory("type=1000")
	for id,item in pairs(currEquippedItems) do
		if(item.slot == equipSlot) then
			return item
		end
	end
	return nil
end
ff["GetItemInSlot"] = GetItemInSlot
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
ff["ItemIsReady"] = ItemIsReady
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
ff["IsInventoryFull"] = IsInventoryFull
function GetInventorySnapshot()
	local currentSnapshot = {}
	
	--Look through regular bags first.
	for x=0,3 do
		local inv = Inventory("type="..tostring(x))
		if (ValidTable(inv)) then
			for k,item in pairs(inv) do
				if currentSnapshot[item.id] == nil then
					-- New item
					currentSnapshot[item.id] = {}
					currentSnapshot[item.id].HQcount = 0
					currentSnapshot[item.id].count = 0
				end
				-- Increment item counts
				if (item.IsHQ == 1) then
					-- HQ
					currentSnapshot[item.id].HQcount = currentSnapshot[item.id].HQcount + item.count
				else
					-- NQ
					currentSnapshot[item.id].count = currentSnapshot[item.id].count + item.count
				end
			end
		end
	end
	
	--Look through equipped items bag.
	local inv = Inventory("type=1000")
	if (ValidTable(inv)) then
		for k,item in pairs(inv) do
			if currentSnapshot[item.id] == nil then
				-- New item
				currentSnapshot[item.id] = {}
				currentSnapshot[item.id].HQcount = 0
				currentSnapshot[item.id].count = 0
			end
			-- Increment item counts
			if (item.IsHQ == 1) then
				-- HQ
				currentSnapshot[item.id].HQcount = currentSnapshot[item.id].HQcount + item.count
			else
				-- NQ
				currentSnapshot[item.id].count = currentSnapshot[item.id].count + item.count
			end
		end
	end
	
	--Look through currency bag.
	local inv = Inventory("type=2000")
	if (ValidTable(inv)) then
		for k,item in pairs(inv) do
			if currentSnapshot[item.id] == nil then
				-- New item
				currentSnapshot[item.id] = {}
				currentSnapshot[item.id].HQcount = 0
				currentSnapshot[item.id].count = 0
			end
			-- Increment item counts
			if (item.IsHQ == 1) then
				-- HQ
				currentSnapshot[item.id].HQcount = currentSnapshot[item.id].HQcount + item.count
			else
				-- NQ
				currentSnapshot[item.id].count = currentSnapshot[item.id].count + item.count
			end
		end
	end
	
	--Look through crystals bag.
	local inv = Inventory("type=2001")
	if (ValidTable(inv)) then
		for k,item in pairs(inv) do
			if currentSnapshot[item.id] == nil then
				-- New item
				currentSnapshot[item.id] = {}
				currentSnapshot[item.id].HQcount = 0
				currentSnapshot[item.id].count = 0
			end
			-- Increment item counts
			if (item.IsHQ == 1) then
				-- HQ
				currentSnapshot[item.id].HQcount = currentSnapshot[item.id].HQcount + item.count
			else
				-- NQ
				currentSnapshot[item.id].count = currentSnapshot[item.id].count + item.count
			end
		end
	end
	
	--Look through key items bag.
	local inv = Inventory("type=2004")
	if (ValidTable(inv)) then
		for k,item in pairs(inv) do
			if currentSnapshot[item.id] == nil then
				-- New item
				currentSnapshot[item.id] = {}
				currentSnapshot[item.id].HQcount = 0
				currentSnapshot[item.id].count = 0
			end
			-- Increment item counts
			if (item.IsHQ == 1) then
				-- HQ
				currentSnapshot[item.id].HQcount = currentSnapshot[item.id].HQcount + item.count
			else
				-- NQ
				currentSnapshot[item.id].count = currentSnapshot[item.id].count + item.count
			end
		end
	end
	
	return currentSnapshot
end
ff["GetInventorySnapshot"] = GetInventorySnapshot
function GetInventoryItemGains(itemid,hqonly)
	local itemid = tonumber(itemid) or 0
	if (hqonly == nil) then hqonly = false end
	local originalCount = 0
	local newCount = 0
	
	local original = ml_global_information.lastInventorySnapshot
	
	if (ValidTable(original)) then
		for id,item in pairs(original) do
			if (id == itemid) then
				if (hqonly) then
					originalCount = item.HQcount
				else
					originalCount = item.count + item.HQcount
				end
			end
		end
	end
	
	local new = GetInventorySnapshot()
	
	if (ValidTable(new)) then
		for id,item in pairs(new) do
			if (id == itemid) then
				if (hqonly) then
					newCount = item.HQcount
				else
					newCount = item.count + item.HQcount
				end
			end
		end
	end
	
	local gained = newCount - originalCount
		
	return gained
end
ff["GetInventoryItemGains"] = GetInventoryItemGains
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
	
	--Look through currency bag.
	local inv = Inventory("type=2000")
	for i, item in pairs(inv) do
		if (item.id == itemid) then
			itemcount = item.count
		end
	end
	
	--Look through crystals bag.
	local inv = Inventory("type=2001")
	for i, item in pairs(inv) do
		if (item.id == itemid) then
			itemcount = item.count
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
ff["ItemCount"] = ItemCount
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
ff["GilCount"] = GilCount
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
ff["PoeticCount"] = PoeticCount
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
ff["SoldieryCount"] = SoldieryCount
function IsCompanionSummoned()
	local el = EntityList("type=2,chartype=3,ownerid="..tostring(Player.id))
	if (ValidTable(el)) then
		return true
	end
	
	local dismiss = ActionList:Get(2,6)
	if (dismiss and dismiss.isready) then
		return true
	end
	
	return false
end
ff["IsCompanionSummoned"] = IsCompanionSummoned
function GetCompanionEntity()
	local el = EntityList("type=2,chartype=3,ownerid="..tostring(Player.id))
	if (ValidTable(el)) then
		local i,entity = next(el)
		if (i and entity) then
			return entity
		end
	end
	
	return nil
end
ff["GetCompanionEntity"] = GetCompanionEntity
function IsShopWindowOpen()
	return (ControlVisible("Shop") or ControlVisible("ShopExchangeItem") or ControlVisible("ShopExchangeCurrency")
		or ControlVisible("ShopCard") or ControlVisible("ShopExchangeCoin"))
end
ff["IsShopWindowOpen"] = IsShopWindowOpen
function IsArmoryFull(slot)
	local slot = tonumber(slot)
	local xref = {
		[0] = 3500, -- Weapon
		[1] = 3200, -- OffHand
		[2] = 3201, -- Head
		[3] = 3202, -- Chest
		[4] = 3203, -- Gloves
		[5] = 3204, -- Belt
		[6] = 3205, -- Pants
		[7] = 3206, -- Feet
		[8] = 3207, -- Earring
		[9] = 3208, -- Necklace
		[10] = 3209, -- Wrist
		[11] = 3300, -- Rings
		[12] = 3300, -- Rings		
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
ff["IsArmoryFull"] = IsArmoryFull
function ArmoryItemCount(slot)
	local slot = tonumber(slot)
	local xref = {
		[0] = 3500, -- Weapon
		[1] = 3200, -- OffHand
		[2] = 3201, -- Head
		[3] = 3202, -- Chest
		[4] = 3203, -- Gloves
		[5] = 3204, -- Belt
		[6] = 3205, -- Pants
		[7] = 3206, -- Feet
		[8] = 3207, -- Earring
		[9] = 3208, -- Necklace
		[10] = 3209, -- Wrist
		[11] = 3300, -- Rings
		[12] = 3300, -- Rings		
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
			return occupiedSlots
		end
	end
	return 0
end
ff["ArmoryItemCount"] = ArmoryItemCount
function GetFirstFreeArmorySlot(armoryType)
	local armoryType = tonumber(armoryType)
	local inv = Inventory("type="..tostring(armoryType))
	if (inv) then
		local maxslots = (armoryType == 3400 and 10) or 25
		for i=0,maxslots do
			local found = false
			for id,item in pairs(inv) do
				if (item.slot == i) then
					if (item and item.id ~= 0) then
						local found = true
					end
				end
			end
			if (not found) then
				return i
			end
		end
	end
	return nil
end
ff["GetFirstFreeArmorySlot"] = GetFirstFreeArmorySlot
function GetEquippedItem(itemid)
	local itemid = tonumber(itemid)
	
	local inv = Inventory("type=1000")
	for i, item in pairs(inv) do
		if (item.id == itemid) then
			return item
		end
	end
	
	return nil
end
ff["GetEquippedItem"] = GetEquippedItem
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
ff["GetUnequippedItem"] = GetUnequippedItem
function GetEquipSlotForItem(slot)
	local slot = tonumber(slot)
	local equipSlot = {
		[1] = 0,
		[2] = 1,
		[3] = 2,
		[4] = 3,
		[5] = 4,
		[6] = 5,
		[7] = 6,
		[8] = 7,
		[9] = 8,
		[10] = 9,
		[11] = 10,
		[12] = 11,
		[13] = 0,
		[17] = 13,
	}
	
	return equipSlot[slot]
end
ff["GetEquipSlotForItem"] = GetEquipSlotForItem
function GetArmorySlotForItem(slot)
	local slot = tonumber(slot)
	local armorySlot = {
		[1] = FFXIV.INVENTORYTYPE.INV_ARMORY_MAINHAND,
		[13] = FFXIV.INVENTORYTYPE.INV_ARMORY_MAINHAND,
		[2] = FFXIV.INVENTORYTYPE.INV_ARMORY_OFFHAND,
		[3] = FFXIV.INVENTORYTYPE.INV_ARMORY_HEAD,
		[4] = FFXIV.INVENTORYTYPE.INV_ARMORY_BODY,
		[5] = FFXIV.INVENTORYTYPE.INV_ARMORY_HANDS,
		[6] = FFXIV.INVENTORYTYPE.INV_ARMORY_WAIST,
		[7] = FFXIV.INVENTORYTYPE.INV_ARMORY_LEGS,
		[8] = FFXIV.INVENTORYTYPE.INV_ARMORY_FEET,
		[9] = FFXIV.INVENTORYTYPE.INV_ARMORY_NECK,
		[10] = FFXIV.INVENTORYTYPE.INV_ARMORY_EARS,
		[11] = FFXIV.INVENTORYTYPE.INV_ARMORY_WRIST,
		[12] = FFXIV.INVENTORYTYPE.INV_ARMORY_RINGS,
		[17] = FFXIV.INVENTORYTYPE.INV_ARMORY_SOULCRYSTAL,
	}
	
	return armorySlot[slot]
end
ff["GetArmorySlotForItem"] = GetArmorySlotForItem
function SubtractHours(start, value)
	start = tonumber(start) or 0
	local newHour = start - value
	if newHour < 0 then
		newHour = newHour + 24
	end
	return newHour	
end
ff["SubtractHours"] = SubtractHours
function SubtractHours12(start, value)
	start = tonumber(start) or 1
	local newHour = start - value
	if newHour < 1 then
		newHour = newHour + 12
	end
	return newHour
end
ff["SubtractHours12"] = SubtractHours12
function AddHours(start, value)
	start = tonumber(start) or 0
	local newHour = start + value
	if newHour > 23 then
		newHour = newHour - 24
	end
	return newHour	
end
ff["AddHours"] = AddHours
function AddHours12(start, value)
	start = tonumber(start) or 1
	local newHour = start + value
	if newHour > 12 then
		newHour = newHour - 12
	end
	return newHour	
end
ff["AddHours12"] = AddHours12
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
	jpTime.min = tonumber(os.date("!%M"))
	jpTime.sec = tonumber(os.date("!%S"))
	jpTime.isdst = false
	
	return jpTime
end
ff["GetJPTime"] = GetJPTime
function GetUTCTime()
	local utcTime = {}
	utcTime.year = tonumber(os.date("!%Y"))
	utcTime.month = tonumber(os.date("!%m"))
	utcTime.day = tonumber(os.date("!%d"))
	utcTime.hour = tonumber(os.date("!%H"))
	utcTime.min = tonumber(os.date("!%M"))
	utcTime.sec = tonumber(os.date("!%S")) 
	utcTime.isdst = false
	
	return utcTime
end
ff["GetUTCTime"] = GetUTCTime
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
ff["EorzeaTime"] = EorzeaTime
function GetCurrentTime()
	local t = os.date('!*t')
	local thisTime = os.time(t)
	return thisTime
end
ff["GetCurrentTime"] = GetCurrentTime
function TimePassed(t1, t2)
	local diff = os.difftime(t1, t2)
	return diff
end
ff["TimePassed"] = TimePassed
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
ff["GetQuestByID"] = GetQuestByID
function IsLimsa(mapid)
	local mapid = tonumber(mapid)
	return (mapid == 128 or mapid == 129)
end
ff["IsLimsa"] = IsLimsa
function IsUldah(mapid)
	local mapid = tonumber(mapid)
	return (mapid == 132 or mapid == 133)
end
ff["IsUldah"] = IsUldah
function IsGridania(mapid)
	local mapid = tonumber(mapid)
	return (mapid == 130 or mapid == 131)
end
ff["IsGridania"] = IsGridania
function GameRegion()
	if (GetGameRegion and GetGameRegion()) then
		return GetGameRegion()
	end
	return 1
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

function IsNull(variant,default)
	if (variant == nil) then
		if (default == nil) then
			return true
		else
			return default
		end
	else
		return variant
	end
end

function CanUseAirship()
	if (GilCount() < 100) then
		return false
	else
		return ((Quest:HasQuest(674) and Quest:GetQuestCurrentStep(674) == 255) or Quest:IsQuestCompleted(674))
	end
	return false
end

function CanAccessMap(mapid)
	local mapid = tonumber(mapid) or 0
	
	if (mapid ~= 0) then
		if (ml_global_information.Player_Map ~= mapid) then
			local pos = ml_nav_manager.GetNextPathPos(	ml_global_information.Player_Position,
														ml_global_information.Player_Map,
														mapid	)
			if (ValidTable(pos)) then
				return true
			end
			
			
			local aethData = ffxiv_aetheryte_data[mapid]
			if (ValidTable(aethData)) then
				for k,aeth in pairs(aethData) do
					if (ValidTable(aeth)) then

						local valid = true
						if (aeth.requires) then
							d("Checking aetheryte requirement data.")
							local requirements = shallowcopy(aeth.requires)
							for requirement,value in pairs(requirements) do
								local f = assert(loadstring("return " .. requirement))()
								if (f ~= nil) then
									if (f ~= value) then
										d("Aetheryte failed requirement ["..tostring(requirement).."].")
										valid = false
									end
								end
								if (not valid) then
									break
								end
							end
						end
						
						if (valid) then
							local aetheryte = GetAetheryteByID(aeth.aethid)
							if (aetheryte) then
								if (GilCount() >= aetheryte.price and aetheryte.isattuned) then
									return true
								end
							end
						end
					end
				end
			end
			
			-- Fall back check to see if we can get to Foundation, and from there to the destination.
			local aetheryte = GetAetheryteByID(70)
			if (aetheryte) then
				if (GilCount() >= aetheryte.price and aetheryte.isattuned) then
					local aethPos = {x = -68.819107055664, y = 8.1133041381836, z = 46.482696533203}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,418,mapid)
					if (ValidTable(backupPos)) then
						return true
					end
				end
			end
		end
	end
	
	return false
end

function GetHinterlandsSection(pos)
	local sections = {
		[1] = {
			a = {x = -953, z = -334},
			b = {x = -302, z = -330},
			c = {x = -239, z = -133},
			d = {x = -953, z = -125},
			x = {x = -532, z = -188},
		},
		[2] = {
			a = {x = -953, z = -125},
			b = {x = -196, z = -199},
			c = {x = -130, z = 551},
			d = {x = -953, z = 551},
			x = {x = -548, z = 201},
		},
		[3] = {
			a = {x = -953, z = 551},
			b = {x = 458, z = 551},
			c = {x = 517, z = 960},
			d = {x = -953, z = 878},
			x = {x = -265, z = 704},
		},
	}
	
	local sec = 2
	if (ValidTable(pos)) then
		local ent1Dist = Distance3D(pos.x,pos.y,pos.z,-542.46624755859,155.99462890625,-518.10394287109)
		if (ent1Dist <= 200) then
			sec = 1
		else
			for i,section in pairs(sections) do
				local isInsideRect = AceLib.API.Math.IsInsideRectangle(pos,section)
				if (isInsideRect) then
					sec = 1
					break
				end
			end
		end
	end
	
	return sec
end
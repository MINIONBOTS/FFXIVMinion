-- This file holds global helper functions
ff = {}
ff.lastPos = {}
ff.lastPath = 0
ff.lastFail = 0

function FilterByProximity(entities,center,radius,sortfield)
	if (ValidTable(entities) and ValidTable(center) and tonumber(radius) > 0) then
		local validEntities = {}
		for i,e in pairs(entities) do
			local epos = e.pos
			local dist = PDistance3D(center.x,center.y,center.z,epos.x,epos.y,epos.z)
	
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

function GetNearestGrindAttackable()
	local huntString = GetWhitelistIDString()
	local excludeString = IsNull(GetBlacklistIDString(),"")
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
	
	if (excludeString == "") then
		excludeString = "541"
	else
		excludeString = excludeString..";541"
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
		--d("Checking marker with radius section.")
		if (gClaimFirst	== "1") then		
			if (not IsNullString(huntString)) then
				el = MEntityList("nearest,contentid="..huntString..",notincombat,targeting=0,alive,attackable,onmesh,exclude_contentid="..excludeString)
				
				if (ValidTable(el)) then
					local i,e = next(el)
					if (i and e and e.distance <= tonumber(gClaimRange)) then
						return e
					end
				end
				
				el = MEntityList("nearest,contentid="..huntString..",notincombat,targeting="..tostring(Player.id)..",alive,attackable,onmesh,exclude_contentid="..excludeString)
				if (ValidTable(el)) then
					local i,e = next(el)
					if (i and e and e.distance <= tonumber(gClaimRange)) then
						return e
					end
				end
			end
		end	
		
		--Prioritize the lowest health with aggro on player, non-fate mobs.
		el = MEntityList("nearest,alive,attackable,onmesh,targetingme,fateid=0,exclude_contentid="..excludeString..",maxdistance=40")
		if (ValidTable(el)) then
			local i,e = next(el)
			if (ValidTable(e)) then
				return e
			end
		end
		
		--Prioritize the lowest health with aggro on player, non-fate mobs.
		el = MEntityList("nearest,alive,attackable,onmesh,claimedbyid="..tostring(Player.id)..",fateid=0,exclude_contentid="..excludeString..",maxdistance=40") 
		if (ValidTable(el)) then
			local i,e = next(el)
			if (ValidTable(e)) then
				return e
			end
		end
				
		local party = EntityList.myparty
		if ( party ) then
			for i, member in pairs(party) do
				if (member.id and member.id ~= 0 and member.mapid == Player.mapid) then
					el = MEntityList("alive,attackable,onmesh,targeting="..tostring(member.id)..",fateid=0,exclude_contentid="..excludeString..",maxdistance=30")
					
					if (ValidTable(el)) then
						local filtered = FilterByProximity(el,markerPos,radius,"distance")
						if (ValidTable(filtered)) then
							for i,e in pairs(filtered) do
								if (ValidTable(e)) then
									return e
								end
							end
						end
					end
				end
			end
		end	
		
		if (ValidTable(Player.pet)) then
			el = MEntityList("alive,attackable,onmesh,targeting="..tostring(Player.pet.id)..",fateid=0,exclude_contentid="..excludeString..",maxdistance="..tostring(ml_global_information.AttackRange))
			
			if (ValidTable(el)) then
				local filtered = FilterByProximity(el,markerPos,radius,"distance")
				if (ValidTable(filtered)) then
					for i,e in pairs(filtered) do
						if (ValidTable(e)) then
							return e
						end
					end
				end
			end
		end
		
		local companion = GetCompanionEntity()
		if (companion) then
			el = MEntityList("nearest,alive,attackable,onmesh,targeting="..tostring(companion.id)..",maxdistance=30,exclude_contentid="..excludeString)
			if (ValidTable(el)) then
				local i,e = next(el)
				if (i and e) then
					return target
				end
			end
		end
		
		--Nearest specified hunt, ignore levels here, assume players know what they wanted to kill.
		if (not IsNullString(huntString)) then
			el = MEntityList("contentid="..huntString..",fateid=0,alive,attackable,onmesh,exclude_contentid="..excludeString)
			
			if (ValidTable(el)) then
				local filtered = FilterByProximity(el,markerPos,radius,"distance")
				if (ValidTable(filtered)) then
					for i,e in pairs(filtered) do
						if (ValidTable(e)) then
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
			el = MEntityList("alive,attackable,onmesh,minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0,exclude_contentid="..excludeString..",maxdistance="..tostring(ml_global_information.AttackRange))
			
			if (ValidTable(el)) then
				local filtered = FilterByProximity(el,markerPos,radius,"distance")
				if (ValidTable(filtered)) then
					for i,e in pairs(filtered) do
						if (ValidTable(e)) then
							return e
						end
					end
				end
			end
		
			el = MEntityList("alive,attackable,onmesh,minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0,exclude_contentid="..excludeString)
			if (ValidTable(el)) then
				local filtered = FilterByProximity(el,markerPos,radius,"distance")
				if (ValidTable(filtered)) then
					for i,e in pairs(filtered) do
						if (ValidTable(e)) then
							return e
						end
					end
				end
			end
		end
	else
		--d("Checking marker without radius section.")
		block = 1
		if (gClaimFirst	== "1") then		
			if (not IsNullString(huntString)) then
				local el = MEntityList("nearest,contentid="..huntString..",notincombat,alive,attackable,onmesh,exclude_contentid="..excludeString)
				if ( el ) then
					local i,e = next(el)
					if (ValidTable(e)) then
						if ((e.targetid == 0 or e.targetid == Player.id) and
							e.distance <= tonumber(gClaimRange)) then
							--d("Grind returned, using block:"..tostring(block))
							return e
						end
					end
				end
			end
		end	
		
		--Prioritize the lowest health with aggro on player, non-fate mobs.
		block = 2		
		el = MEntityList("nearest,alive,attackable,onmesh,targetingme,fateid=0,exclude_contentid="..excludeString..",maxdistance=40")
		if (ValidTable(el)) then
			local i,e = next(el)
			if (ValidTable(e)) then
				return e
			end
		end
		
		--Prioritize the lowest health with aggro on player, non-fate mobs.
		el = MEntityList("nearest,alive,attackable,onmesh,claimedbyid="..tostring(Player.id)..",fateid=0,exclude_contentid="..excludeString..",maxdistance=40") 
		if (ValidTable(el)) then
			local i,e = next(el)
			if (ValidTable(e)) then
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
					el = MEntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",fateid=0,exclude_contentid="..excludeString..",maxdistance=30")
					
					if ( el ) then
						local i,e = next(el)
						if (ValidTable(e)) then
							--d("Grind returned, using block:"..tostring(block))
							return e
						end
					end
				end
			end
		end
		
		block = 4
		if (ValidTable(Player.pet)) then
			el = MEntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(Player.pet.id)..",fateid=0,exclude_contentid="..excludeString..",maxdistance="..tostring(ml_global_information.AttackRange))
			
			if ( el ) then
				local i,e = next(el)
				if (ValidTable(e)) then
					--d("Grind returned, using block:"..tostring(block))
					return e
				end
			end
		end
		
		--Nearest specified hunt, ignore levels here, assume players know what they wanted to kill.
		block = 5
		if (not IsNullString(huntString)) then
			--d("Checking whitelist section.")
			el = MEntityList("nearest,contentid="..huntString..",fateid=0,alive,attackable,onmesh,exclude_contentid="..excludeString)
			
			if ( el ) then
				local i,e = next(el)
				if (ValidTable(e)) then
					if (e.targetid == 0 or e.targetid == Player.id or gClaimed == "1") then
						--d("Grind returned, using block:"..tostring(block))
						return e
					end
				end
			end
		end
		
		--Nearest in our attack range, not targeting anything, non-fate, use PathDistance.
		if (IsNullString(huntString)) then
			--d("Checking non-whitelist section.")
			el = MEntityList("nearest,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0,exclude_contentid="..excludeString)
			
			block = 6
			if ( el ) then
				local i,e = next(el)
				if (ValidTable(e)) then
					--d("Grind returned, using block:"..tostring(block))
					return e
				end
			end
		
			el = MEntityList("nearest,alive,attackable,onmesh,minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0,exclude_contentid="..excludeString)
			
			block = 7
			if ( el ) then
				local i,e = next(el)
				if (ValidTable(e)) then
					--d("Grind returned, using block:"..tostring(block))
					return e
				end
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
			local el = MEntityList("shortestpath,contentid="..tostring(huntString)..",targeting=0,notincombat,alive,attackable,onmesh")
			if ( el ) then
				local i,e = next(el)
				if ( i~= nil and e~= nil and 
					e.distance <= tonumber(gClaimRange)) then
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
    local fate = MGetFateByID(ml_task_hub:CurrentTask().fateid)
	
    if (fate and fate.status == 2 and fate.completion < 100) then
		if (fate.type == 1) then
			d("fate type is 1")
			
			el = MEntityList("alive,attackable,onmesh,fateid="..tostring(fate.id))
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
					if (bestTarget.targetid ~= Player.id and bestTarget.aggropercentage ~= 100) then
						-- See if we have something attacking us that can be killed quickly, if we are not currently the target.
						el = MEntityList("nearest,alive,attackable,targetingme,onmesh,maxdistance=25")
						if (ValidTable(el)) then
							d("searching targets that are targeting me")
							local nearestQuick = nil
							local nearestQuickDistance = 500
							
							for i,e in pairs(el) do
								local epos = e.pos
								local ehp = e.hp
								local mhp = Player.hp
								local dist = Distance2D(epos.x,epos.z,fate.x,fate.z)
								if (dist <= fate.radius and 
									(ehp.max <= (mhp.max * 2) or (ehp.current < (mhp.max * 2)))) 
								then
									if (not nearestQuick or (nearestQuick and dist < nearestQuickDistance)) then
										nearestQuick,nearestQuickDistance = e,dist
									end
								end
							end
							
							if (nearestQuick) then
								return nearestQuick
							end						
						end	
					end
					
				
					return bestTarget
				end
			end
		end
		
		el = MEntityList("nearest,alive,attackable,targetingme,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",fateid="..tostring(fate.id))
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
    
        el = MEntityList("nearest,alive,attackable,targetingme,onmesh,fateid="..tostring(fate.id))            
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
		
		local companion = GetCompanionEntity()
		if (companion) then
			el = MEntityList("nearest,alive,attackable,onmesh,fateid="..tostring(fate.id)..",targeting="..tostring(companion.id)..",maxlevel="..tostring(Player.level+3)..",maxdistance=30")
			if (ValidTable(el)) then
				local id, target = next(el)
				if (ValidTable(target) and myTarget == 0) then
					return target
				end
			end
			
			el = MEntityList("nearest,alive,attackable,onmesh,fateid=0,targeting="..tostring(companion.id)..",maxlevel="..tostring(Player.level+3)..",maxdistance=30")
			if (ValidTable(el)) then
				local id, target = next(el)
				if (ValidTable(target) and myTarget == 0) then
					return target
				end
			end
		end
		
		if (gFateKillAggro == "1") then
			el = MEntityList("nearest,alive,attackable,aggro,fateid=0,onmesh")
			if (ValidTable(el)) then
				local i,e = next(el)
				if (i~=nil and e~=nil) then
					return e
				end
			end	
		end
		
        el = MEntityList("nearest,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",fateid="..tostring(fate.id))
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
    
        el = MEntityList("nearest,alive,attackable,onmesh,fateid="..tostring(fate.id))            
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
			el = MEntityList("contentid="..ffxiv_task_hunt.rankS..",alive,attackable,onmesh,exclude_contentid="..excludeString)
		else
			el = MEntityList("contentid="..ffxiv_task_hunt.rankS..",alive,attackable,onmesh")
		end
		if (ValidTable(el)) then
			for i,e in pairs(el) do
				local myPos = Player.pos
				local tpos = e.pos
				local distance = PDistance3D(myPos.x, myPos.y, myPos.z, tpos.x, tpos.y, tpos.z)
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
			el = MEntityList("contentid="..ffxiv_task_hunt.rankA..",alive,attackable,onmesh,exclude_contentid="..excludeString)
		else
			el = MEntityList("contentid="..ffxiv_task_hunt.rankA..",alive,attackable,onmesh")
		end
		if (ValidTable(el)) then
			for i,e in pairs(el) do
				local myPos = Player.pos
				local tpos = e.pos
				local distance = PDistance3D(myPos.x, myPos.y, myPos.z, tpos.x, tpos.y, tpos.z)
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
				el = MEntityList("contentid="..tostring(gHuntBRankHuntID)..",alive,attackable,onmesh,exclude_contentid="..excludeString)
			else
				el = MEntityList("contentid="..tostring(gHuntBRankHuntID)..",alive,attackable,onmesh")
			end
			if (ValidTable(el)) then
				for i,e in pairs(el) do
					local myPos = Player.pos
					local tpos = e.pos
					local distance = PDistance3D(myPos.x, myPos.y, myPos.z, tpos.x, tpos.y, tpos.z)
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
				el = MEntityList("contentid="..ffxiv_task_hunt.rankB..",alive,attackable,onmesh,exclude_contentid="..excludeString)
			else
				el = MEntityList("contentid="..ffxiv_task_hunt.rankB..",alive,attackable,onmesh")
			end
			if (ValidTable(el)) then
				for i,e in pairs(el) do
					local myPos = Player.pos
					local tpos = e.pos
					local distance = PDistance3D(myPos.x, myPos.y, myPos.z, tpos.x, tpos.y, tpos.z)
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
	if (ValidTable(e) and e.alive and e.targetable and not e.aggro) then
		return (e.chartype == 4) or (e.id == Player.id) or
			(e.chartype == 0 and (e.type == 2 or e.type == 3 or e.type == 5)) or
			(e.chartype == 3 and e.type == 2) or
			((e.chartype == 5 and e.type == 2) and (e.friendly or not e.attackable))
	end
	
	return false
end
function GetBestTankHealTarget( range )
	range = range or ml_global_information.AttackRange
	local lowest = nil
	local lowestHP = 101

    local el = MEntityList("friendly,alive,chartype=4,myparty,targetable,maxdistance="..tostring(range))
	--local el = MEntityList("friendly,alive,chartype=4,myparty,maxdistance="..tostring(range))
    if ( ValidTable(el) ) then
		for i,e in pairs(el) do
			if (IsTank(e.job) and e.hp.percent < lowestHP ) then
				lowest = e
				lowestHP = e.hp.percent
			end
        end
    end
	
	local ptrg = MGetTarget()
	if (ptrg and Player.pet) then
		if (lowest == nil and ptrg.targetid == Player.pet.id) then
			lowest = Player.pet
		end
	end
	
	return lowest
end
function GetBestPartyHealTarget( npc, range, hp )	
	local npc = npc
	if (npc == nil) then npc = false end
	local range = range or ml_global_information.AttackRange
	local hp = hp or 95
	
	local healables = {}
	
	local el = MEntityList("alive,friendly,chartype=4,myparty,targetable,maxdistance="..tostring(range))
	if ( ValidTable(el) ) then
		for i,e in pairs(el) do
			if (IsValidHealTarget(e) and e.hp.percent <= hp) then
				healables[i] = e
			end
		end
	end
	
	if (npc) then
		el = MEntityList("alive,friendly,myparty,targetable,maxdistance="..tostring(range))
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
	
	if (gBotMode == GetString("partyMode") and not IsPartyLeader()) then
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
function GetLowestHPParty( skill )
    npc = (skill.npc == "1")
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
			el = MEntityList("myparty,alive,type=1,targetable,maxdistance="..tostring(range))
			--el = MEntityList("myparty,alive,type=1,maxdistance="..tostring(range))
		else
			el = MEntityList("myparty,alive,targetable,maxdistance="..tostring(range))
			--el = MEntityList("myparty,alive,maxdistance="..tostring(range))
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

function GetLowestMPParty( range, role, includeself )
    local pID = Player.id
	local lowest = nil
	local lowestMP = 101
	local includeself = IsNull(includeself,"0") == "1"
	local range = tonumber(range) or 35 
	local role = tostring(role) or ""
	
	local mpUsers = {
		[FFXIV.JOBS.GLADIATOR] = true,
		[FFXIV.JOBS.CONJURER] = true,
		[FFXIV.JOBS.PALADIN] = true,
		[FFXIV.JOBS.WHITEMAGE] = true,
		[FFXIV.JOBS.ARCANIST] = true,
		[FFXIV.JOBS.SUMMONER] = true,
		[FFXIV.JOBS.SCHOLAR] = true,
		[FFXIV.JOBS.DARKKNIGHT] = true,
		[FFXIV.JOBS.ASTROLOGIAN] = true,
	}
	
	-- DPS, Healer, Tank, Caster

	-- If the role is to be filtered, remove the non-applicable jobs here.
	local roleTable = GetRoleTable(role)
	if (roleTable) then
		for jobid,_ in pairs(mpUsers) do
			if (not roleTable[jobid]) then
				mpUsers[jobid] = nil
			end
		end
	end
	
    local el = MEntityList("myparty,alive,type=1,targetable,maxdistance="..tostring(range))
    if ( ValidTable(el) ) then
		for i,e in pairs(el) do
			if (mpUsers[e.job] and e.mp.percent < lowestMP) then
				lowest = e
				lowestMP = e.mp.percent
			end
        end
    end
	
	if (includeself) then
		if (Player.alive and mpUsers[Player.job] and Player.mp.percent < lowestMP) then
			lowest = Player
			lowestMP = Player.mp.percent
		end
	end
	
	return lowest
end

function GetLowestTPParty( range, role, includeself )
	local lowest = nil
	local lowestTP = 1001
	local includeself = IsNull(includeself,"0") == "1"
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
	
    local el = MEntityList("myparty,alive,type=1,targetable,maxdistance="..tostring(range))
	--local el = MEntityList("myparty,alive,type=1,targetable,maxdistance="..tostring(range))
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
	
	if (includeself) then
		if (Player.alive and tpUsers[Player.job] and ml_global_information.Player_TP < lowestTP) then
			lowest = Player
			lowestTP = ml_global_information.Player_TP
		end
	end
	
    return lowest
end
function GetBestHealTarget( npc, range, reqhp )
	local npc = npc
	if (npc == nil) then npc = false end
	local range = range or ml_global_information.AttackRange
	local reqhp = tonumber(reqhp) or 95
	
	--d("[GetBestHealTarget]: Params:"..tostring(npc)..","..tostring(range)..","..tostring(reqhp))
	
	local healables = {}
	
	local el = MEntityList("alive,friendly,chartype=4,targetable,maxdistance="..tostring(range))
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
		local el = MEntityList("alive,targetable,maxdistance="..tostring(range))
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
function GetBestBaneTarget()
	local bestTarget = nil
	local party = EntityList.myparty
	local el = nil
	
	--Check the original diseased target, make sure it has all the required buffs, and that they're all 3 or more, blow it up, reset the best dot target.
	if (SkillMgr.bestAOE ~= 0) then
		local e = EntityList:Get(SkillMgr.bestAOE)
		if (ValidTable(e) and e.alive and e.attackable and e.los and e.distance <= 25 and HasBuffs(e, "179+180+189", 3, Player.id)) then
			SkillMgr.bestAOE = 0
			return e
		end
	end
	
	--If the original target is not found, check the best target with clustered, blow it up, reset the best dot target.
	for i,member in pairs(party) do
		if (member.id ~= 0) then
			local el = MEntityList("alive,attackable,los,clustered=8,targeting="..tostring(member.id)..",maxdistance=25")
			if ( el ) then
				for k,e in pairs(el) do
					if HasBuffs(e, "179+180+189", 3, Player.id) then
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
		if (ValidTable(e) and e.alive and e.attackable and e.los and e.distance <= 25 and MissingBuffs(e, "179,180,189", 3, Player.id)) then
			return e
		end
	end
	
	--Check for a new target that is clustered and missing all 3 buffs
	for i,member in pairs(party) do
		if (member.id ~= 0) then
			local el = MEntityList("alive,attackable,los,clustered=8,targeting="..tostring(member.id)..",maxdistance=25")
			if ( el ) then
				for k,e in pairs(el) do
					if MissingBuffs(e, "179+180+189", 3, Player.id) then
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
    local el = MEntityList("nearest,friendly,chartype=4,myparty,targetable,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
	--local el = MEntityList("nearest,friendly,chartype=4,myparty,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
    if ( ValidTable(el) ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
    
    local el = MEntityList("nearest,friendly,chartype=4,targetable,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
	--local el = MEntityList("nearest,friendly,chartype=4,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
    if ( ValidTable(el) ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
    --ml_debug("GetBestHealTarget() failed with no entity found matching params")
    return nil
end
function GetBestRevive( party, role)
	party = IsNull(party,false)
	role = role or ""
	range = 30
	
	local el = nil
	if (party) then
		el = MEntityList("myparty,friendly,chartype=4,targtable,dead,maxdistance="..tostring(range))
	else
		el = MEntityList("friendly,dead,chartype=4,targetable,maxdistance="..tostring(range))
	end 
	
	-- Filter out the inappropriate roles.
	local targets = {}
	if (ValidTable(el)) then
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
	
	if (gBotMode == GetString("partyMode") and not IsPartyLeader()) then
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
		enemyParty = MEntityList("lowesthealth,onmesh,attackable,targetingme,alive,chartype=4,maxdistance=15")
		if(not ValidTable(enemyParty)) then
			enemyParty = MEntityList("lowesthealth,onmesh,attackable,targetingme,alive,chartype=4,maxdistance=25")
		end
		if(not ValidTable(enemyParty)) then
			enemyParty = MEntityList("lowesthealth,onmesh,attackable,alive,chartype=4,maxdistance=15")
		end
		if(not ValidTable(enemyParty)) then
			enemyParty = MEntityList("lowesthealth,onmesh,attackable,alive,chartype=4,maxdistance=25")
		end
		if(not ValidTable(enemyParty)) then
			enemyParty = MEntityList("lowesthealth,onmesh,attackable,alive,maxdistance=15")
		end
		if(not ValidTable(enemyParty)) then
			enemyParty = MEntityList("lowesthealth,onmesh,attackable,alive,maxdistance=25")
		end
		if(not ValidTable(enemyParty)) then
			enemyParty = MEntityList("shortestpath,onmesh,attackable,alive,chartype=4,maxdistance=45")
		end
		if(not ValidTable(enemyParty)) then
			enemyParty = MEntityList("shortestpath,onmesh,attackable,alive,maxdistance=45")
		end
	else
		enemyParty = MEntityList("onmesh,attackable,alive,chartype=4")
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
function GetNearestGrindAggro()
	taskName = ml_task_hub:ThisTask().name
	
	if (not IsNullString(excludeString)) then
		if (taskName == "LT_GRIND") then
			el = MEntityList("lowesthealth,alive,attackable,onmesh,targetingme,fateid=0,exclude_contentid="..excludeString..",maxdistance=30") 
		else
			el = MEntityList("lowesthealth,alive,attackable,onmesh,targetingme,exclude_contentid="..excludeString..",maxdistance=30") 
		end
	else
		if (taskName == "LT_GRIND") then
			el = MEntityList("lowesthealth,alive,attackable,onmesh,targetingme,fateid=0,maxdistance=30") 
		else
			el = MEntityList("lowesthealth,alive,attackable,onmesh,targetingme,maxdistance=30") 
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
						el = MEntityList("lowesthealth,alive,attackable,onmesh,fateid=0,targeting="..tostring(member.id)..",exclude_contentid="..excludeString..",maxdistance=30")
					else
						el = MEntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",exclude_contentid="..excludeString..",maxdistance=30")
					end
				else
					if (taskName == "LT_GRIND") then
						el = MEntityList("lowesthealth,alive,attackable,onmesh,fateid=0,targeting="..tostring(member.id)..",maxdistance=30")
					else
						el = MEntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",maxdistance=30")
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
			el = MEntityList("lowesthealth,alive,attackable,onmesh,targetingme,fateid=0,exclude_contentid="..excludeString..",maxdistance=30") 
		else
			el = MEntityList("lowesthealth,alive,attackable,onmesh,targetingme,exclude_contentid="..excludeString..",maxdistance=30") 
		end
	else
		if (taskName == "LT_GRIND") then
			el = MEntityList("lowesthealth,alive,attackable,onmesh,targetingme,fateid=0,maxdistance=30") 
		else
			el = MEntityList("lowesthealth,alive,attackable,onmesh,targetingme,maxdistance=30") 
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
						el = MEntityList("lowesthealth,alive,attackable,onmesh,fateid=0,targeting="..tostring(member.id)..",exclude_contentid="..excludeString..",maxdistance=30")
					else
						el = MEntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",exclude_contentid="..excludeString..",maxdistance=30")
					end
				else
					if (taskName == "LT_GRIND") then
						el = MEntityList("lowesthealth,alive,attackable,onmesh,fateid=0,targeting="..tostring(member.id)..",maxdistance=30")
					else
						el = MEntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",maxdistance=30")
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
function GetNearestFromList(strList,pos,radius)
	local el = MEntityList(strList)
	if (ValidTable(el)) then
		local filteredList = {}
		for i,e in pairs(el) do
			if (not radius or (radius >= 100)) then
				table.insert(filteredList,e)
			else
				local epos = e.pos
				local dist = PDistance3D(pos.x,pos.y,pos.z,epos.x,epos.y,epos.z)
				
				if (dist <= radius) then
					table.insert(filteredList,e)
				end
			end
		end
		
		if (ValidTable(filteredList)) then
			table.sort(filteredList,function(a,b) return a.distance < b.distance end)
			
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
			el = MEntityList("shortestpath,onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel)..",contentid="..whitelist)
		elseif (blacklist and blacklist ~= "") then
			el = MEntityList("shortestpath,onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel)..",exclude_contentid="..blacklist)
		else
			el = MEntityList("shortestpath,onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel))
		end
		
		if ( ValidTable(el) ) then
			local i,e = next(el)
			if (i~=nil and e~=nil) then
				return e
			end
		end
	elseif (ValidTable(markerPos)) then
		if (whitelist and whitelist ~= "") then
			el = MEntityList("onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel)..",contentid="..whitelist)
		elseif (blacklist and blacklist ~= "") then
			el = MEntityList("onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel)..",exclude_contentid="..blacklist)
		else
			el = MEntityList("onmesh,gatherable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxlevel))
		end
		
		local gatherables = {}
		if (ValidTable(el)) then
			for i,g in pairs(el) do
				local gpos = g.pos
				local dist = PDistance3D(markerPos.x,markerPos.y,markerPos.z,gpos.x,gpos.y,gpos.z)
				
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
function GetNearestUnspoiled(class)
	--Rocky Outcrop = 6
	--Mining Node = 5
	--Mature Tree = 7
	--Vegetation = 8
	local contentID = (class == FFXIV.JOBS.MINER) and "5;6" or "7;8"
    local el = MEntityList("shortestpath,onmesh,gatherable,contentid="..tostring(contentID))
    
    if ( el ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
	
    return nil
end
function HasBuff(targetid, buffID, stacks, duration, ownerid)
	local targetid = tonumber(targetid) or 0
	local buffID = tonumber(buffID) or 0
	local stacks = tonumber(stacks) or 0
	local duration = tonumber(duration) or 0
	local ownerid = tonumber(ownerid) or 0
	
	local entity = MGetEntity(targetid)
	if (ValidTable(entity)) then
		local buffs = entity.buffs
		if (ValidTable(buffs)) then
			for i, buff in pairs(buffs) do
				if (buff.id == buffID) then
					if ((stacks == 0 or stacks >= buff.stacks) and
						(duration == 0 or buff.duration >= duration or HasInfiniteDuration(buff.id)) and 
						(ownerid == 0 or buff.ownerid == ownerid)) 
					then
						return true
					end
				end
			end
		end
	end
    
    return false
end
function MissingBuff(targetid, buffID, stacks, duration, ownerid)
	local targetid = tonumber(targetid) or 0
	local buffID = tonumber(buffID) or 0
	local stacks = tonumber(stacks) or 0
	local duration = tonumber(duration) or 0
	local ownerid = tonumber(ownerid) or 0
	
	local entity = MGetEntity(targetid)
	if (ValidTable(entity)) then
		local buffs = entity.buffs
		if (ValidTable(buffs)) then
			local missing = true
			for i, buff in pairs(buffs) do
				if (buff.id == buffID) then
					if ((stacks == 0 or stacks >= buff.stacks) and
						(duration == 0 or buff.duration >= duration or HasInfiniteDuration(buff.id)) and 
						(ownerid == 0 or buff.ownerid == ownerid)) 
					then
						missing = false
					end
				end
				if (not missing) then
					return false
				end
			end
		end
		
		return true
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
	local buffIDs = IsNull(tostring(buffIDs),"")
	
	if (ValidTable(entity) and buffIDs ~= "") then
		local buffs = entity.buffs

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
function MissingBuffs(entity, buffIDs, dura, ownerid)
	local duration = dura or 0
	local owner = ownerid or 0
	local buffIDs = IsNull(tostring(buffIDs),"")
	
	if (ValidTable(entity) and buffIDs ~= "") then
		--If we have no buffs, we are missing everything.
		local buffs = entity.buffs
		
		if (ValidTable(buffs)) then
			--Start by assuming we have no buffs, so they are missing.
			for _orids in StringSplit(buffIDs,",") do
				local missing = true
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
		
		return true
	end
    
    return false
end
function GetFleeHP()
	local attackingMobs = TableSize(MEntityList("onmesh,alive,attackable,targetingme,maxdistance=15"))
	local fleeHP = tonumber(gFleeHP) + (3 * attackingMobs)
	return fleeHP
end
function HasInfiniteDuration(id)
	infiniteDurationAbilities = {
		[614] = true,
	}
	
	return infiniteDurationAbilities[id] or false
end
function IsPlayerCasting(fullcheck)
	fullcheck = IsNull(fullcheck,false)
	return (Player.castinginfo.channelingid ~= 0 or (fullcheck and Player.castinginfo.castingid ~= 0))
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
function IsHealingSkill(skillID)
	local id = tonumber(skillID)
	
	local cures = {
		[120] = true,
		[124] = true,
		[126] = true,
		[131] = true,
		[133] = true,
		[135] = true,
		[140] = true,
		[185] = true,
		[186] = true,
		[187] = true,
		[189] = true,
		[190] = true,
		[3541] = true,
		[3570] = true,
		[3583] = true,
		[3594] = true,
		[3595] = true,
		[3600] = true,
		[3601] = true,
		[3602] = true,
		[3610] = true,
		[3614] = true,
	}
    if (cures[id]) then
        return true
    end
    return false
end
function IsFriendlyBuff(skillID)
	local id = tonumber(skillID)
	
	local buffs = {
		[27] = true,
		[123] = true,
		[129] = true,
		[137] = true,
		[2249] = true,
		[3564] = true,
		[3565] = true,
		[3612] = true,
	}
    if (buffs[id]) then
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
function IsOmni(entity)
	if not entity or entity.id == Player.id then return false end
	local omnis = {
		[4954] = true,
		[4776] = true,
	}
	return omnis[entity.contentid]
end
function IsFlanking(entity,dorangecheck)
	if not entity or entity.id == Player.id then return false end
	local dorangecheck = IsNull(dorangecheck,true)
	
	if (entity.pos.h > math.pi or entity.pos.h < (-1 * math.pi)) then
		return true
	end
	
    if ((entity.distance2d - (entity.hitradius + 1)) <= ml_global_information.AttackRange or not dorangecheck) then
        local entityHeading = nil
        
        if (entity.pos.h < 0) then
            entityHeading = entity.pos.h + 2 * math.pi
        else
            entityHeading = entity.pos.h
        end
		
		local myPos = Player.pos
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
function IsBehind(entity,dorangecheck)
	if not entity or entity.id == Player.id then return false end
	local dorangecheck = IsNull(dorangecheck,true)
	
	if (entity.pos.h > math.pi or entity.pos.h < (-1 * math.pi)) then
		return true
	end
	
    if ((entity.distance2d - (entity.hitradius + 1)) <= ml_global_information.AttackRange or not dorangecheck) then
        local entityHeading = nil
        
        if (entity.pos.h < 0) then
            entityHeading = entity.pos.h + 2 * math.pi
        else
            entityHeading = entity.pos.h
        end
        
		local myPos = Player.pos
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
function IsBehindSafe(entity)
	if not entity or entity.id == Player.id then return false end
	if (entity.pos.h > math.pi or entity.pos.h < (-1 * math.pi)) then
		return true
	end
	
	local entityHeading = nil
	
	if (entity.pos.h < 0) then
		entityHeading = entity.pos.h + 2 * math.pi
	else
		entityHeading = entity.pos.h
	end
	
	local myPos = Player.pos
	local entityAngle = math.atan2(myPos.x - entity.pos.x, myPos.z - entity.pos.z)        
	local deviation = entityAngle - entityHeading
	local absDeviation = math.abs(deviation)
	local leftover = math.abs(absDeviation - math.pi)
	
	if (leftover > (math.pi * 1.70) or leftover < (math.pi * .30)) then
		return true
	end
    return false
end
function IsFront(entity,dorangecheck)
	if not entity or entity.id == Player.id then return false end
	local dorangecheck = IsNull(dorangecheck,true)
	
	if (entity.pos.h > math.pi or entity.pos.h < (-1 * math.pi)) then
		return true
	end
	
	if ((entity.distance2d - (entity.hitradius + 1)) <= ml_global_information.AttackRange or not dorangecheck) then
		local entityHeading = nil
		
		if (entity.pos.h < 0) then
			entityHeading = entity.pos.h + 2 * math.pi
		else
			entityHeading = entity.pos.h
		end
		
		local myPos = Player.pos
		local entityAngle = math.atan2(myPos.x - entity.pos.x, myPos.z - entity.pos.z) 
		local deviation = entityAngle - entityHeading
		local absDeviation = math.abs(deviation)
		local leftover = math.abs(absDeviation - math.pi)
		
		if (leftover > (math.pi * .75) and leftover < (math.pi * 1.25)) then
			return true
		end
	end
    return false
end
function IsFrontSafe(entity)
	if not entity or entity.id == Player.id then return false end
	if (entity.pos.h > math.pi or entity.pos.h < (-1 * math.pi)) then
		return true
	end
	
	local entityHeading = nil
	
	if (entity.pos.h < 0) then
		entityHeading = entity.pos.h + 2 * math.pi
	else
		entityHeading = entity.pos.h
	end
	
	local myPos = Player.pos
	local entityAngle = math.atan2(myPos.x - entity.pos.x, myPos.z - entity.pos.z) 
	local deviation = entityAngle - entityHeading
	local absDeviation = math.abs(deviation)
	local leftover = math.abs(absDeviation - math.pi)
	
	if (leftover > (math.pi * .70) and leftover < (math.pi * 1.30)) then
		return true
	end
    return false
end
function IsFrontSafer(entity,pos)
	pos = pos or Player.pos
	if not entity or entity.id == Player.id then return false end
	if (entity.pos.h > math.pi or entity.pos.h < (-1 * math.pi)) then
		return true
	end
	
	local entityHeading = nil
	
	if (entity.pos.h < 0) then
		entityHeading = entity.pos.h + 2 * math.pi
	else
		entityHeading = entity.pos.h
	end
	
	local entityAngle = math.atan2(pos.x - entity.pos.x, pos.z - entity.pos.z) 
	local deviation = entityAngle - entityHeading
	local absDeviation = math.abs(deviation)
	local leftover = math.abs(absDeviation - math.pi)
	
	if (leftover > (math.pi * .60) and leftover < (math.pi * 1.40)) then
		return true
	end
    return false
end
function EntityIsFrontWide(entity)
	if not entity or entity.id == Player.id then return false end
	
	local ppos = Player.pos
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
function EntityIsFront(entity)
	if not entity or entity.id == Player.id then return false end
	
	local ppos = Player.pos
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
function EntityIsFrontTight(entity)
	if not entity or entity.id == Player.id then return false end
	
	local ppos = Player.pos
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
function Distance3DT(pos1,pos2)
	assert(type(pos1) == "table","Distance3DT - expected type table for first argument")
	assert(type(pos2) == "table","Distance3DT - expected type table for second argument")
	
	local distance = Distance3D(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z)
	return round(distance,2)
end
function Distance2DT(pos1,pos2)
	assert(type(pos1) == "table","Distance3DT - expected type table for first argument")
	assert(type(pos2) == "table","Distance3DT - expected type table for second argument")

	local distance = Distance2D(pos1.x,pos1.z,pos2.x,pos2.z)
	return round(distance,2)
end
function ConvertHeading(heading)
	if (heading < 0) then
		return heading + 2 * math.pi
	else
		return heading
	end
end
function RevertHeading(heading)
	if (heading > math.pi) then
		return heading - (2 * math.pi)
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
    local fateList = MFateList()
	if (ValidTable(fateList)) then
		for _,fate in pairs(fateList) do
			 if (fate.id == fateID) then
                return fate
            end
		end	
	end
	
	return nil
end
function GetApprovedFates()
	local approvedFates = {}
	
	local level = Player.level
	local fatelist = MFateList()
	if (ValidTable(fatelist)) then
		for _,fate in pairs(fatelist) do
			local minFateLevel = tonumber(gMinFateLevel) or 0
			local maxFateLevel = tonumber(gMaxFateLevel) or 0
			local fatePos = {x = fate.x, y = fate.y, z = fate.z}
			
			local isChain,firstChain = ffxiv_task_fate.IsChain(Player.localmapid, fate.id)
			local isPrio = ffxiv_task_fate.IsHighPriority(Player.localmapid, fate.id)
			
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

	return false
end
function IsInsideFate()
	local closestFate = GetClosestFate()
	if (ValidTable(closestFate)) then
		local fatePos = {x = closestFate.x, y = closestFate.y, z = closestFate.z}
		local myPos = Player.pos
		local dist = Distance2D(myPos.x,myPos.z,fatePos.x,fatePos.z)
		if (dist < closestFate.radius) then
			return true
		end
	end
	
	return false
end
function GetClosestFate(pos,pathcheck)
	if (pathcheck == nil) then pathcheck = false end
	
	local fateList = GetApprovedFates()
	if (ValidTable(fateList)) then		
		if (pathcheck and gTeleport == "0") then
			for i=TableSize(fateList),1,-1 do
				local fate = fateList[i]
				local fatePos = {x = fate.x, y = fate.y, z = fate.z}
				if (not HasNavPath(pos,fatePos)) then
					d("Removing fate ["..tostring(fate.id).."] from list, no path.")
					table.remove(fateList, i)
				end
			end
		end
		
		--d("Found some approved fates.")
        local nearestFate = nil
        local nearestDistance = 9999
        local level = Player.level
		local myPos = Player.pos
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
				if (whitelistTable[fate.id] and	fate.status == 2) then	
					local p,dist = NavigationManager:GetClosestPointOnMesh({x=fate.x, y=fate.y, z=fate.z},false)
					if (p and dist <= 5) then
						--local distance = PathDistance(NavigationManager:GetPath(myPos.x,myPos.y,myPos.z,p.x,p.y,p.z))
						local distance = PDistance3D(myPos.x,myPos.y,myPos.z,p.x,p.y,p.z)
						if (distance) then
							if (not nearestFate or (nearestFate and (distance < nearestDistance))) then
								nearestFate = fate
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
						if (ffxiv_task_fate.IsHighPriority(Player.localmapid, fate.id) or ffxiv_task_fate.IsChain(Player.localmapid, fate.id)) then
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
					local distance = PDistance3D(myPos.x,myPos.y,myPos.z,fate.x,fate.y,fate.z) or 0
					if (distance ~= 0) then
						if (not nearestFate or (nearestFate and (distance < nearestDistance))) then
							nearestFate = fate
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
	local el = MEntityList("nearest,targetable,alive,contentid="..ids..",maxdistance="..tostring(maxdistance))
	if (ValidTable(el)) then
		local i,e = next(el)
		if (i and e) then
			return true
		end
	end
	
	local el = MEntityList("nearest,aggro,alive,contentid="..ids..",maxdistance="..tostring(maxdistance))
	if (ValidTable(el)) then
		local i,e = next(el)
		if (i and e) then
			return true
		end
	end

	return false
end
function ScanForCaster(ids,distance,spells)
	local ids = (type(ids) == "string" and ids) or tostring(ids)
	local spells = (type(spells) == "string" and spells) or tostring(spells)
	
	local maxdistance = tonumber(distance) or 30
	local el = MEntityList("alive,contentid="..ids..",maxdistance="..tostring(maxdistance))
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
function ScanForObjects(ids,distance)
	local ids = (type(ids) == "string" and ids) or tostring(ids)
	local maxdistance = tonumber(distance) or 30
	local el = MEntityList("nearest,targetable,contentid="..ids..",maxdistance="..tostring(maxdistance))
	if (ValidTable(el)) then
		local i,e = next(el)
		if (i and e) then
			return true
		end
	end
	
	return false
end
function ScanForEntity(ids,distance)
	local ids = (type(ids) == "string" and ids) or tostring(ids)
	local maxdistance = tonumber(distance) or 30
	local el = MEntityList("nearest,contentid="..ids..",maxdistance="..tostring(maxdistance))
	if (ValidTable(el)) then
		local i,e = next(el)
		if (i and e) then
			return true
		end
	end
	
	return false
end
function CanUseCannon()
	if (MIsLocked()) then
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
ml_global_information.lastPathGet = 0
function HasNavPath(pos1,pos2,previousDistance)
	if (true) then
		return true
	end
	
	local previousDistance = IsNull(previousDistance,0)
	
	if (pos1 and pos2) then
		if (CanFlyInZone() and ValidTable(ffxiv_task_test.flightMesh)) then
			if (ffxiv_task_test.GetPath(pos1,pos2)) then
				return true
			end
		end
		
		-- See if there is a transport function required to reach this area first.
		--[[
		local transportFunction = _G["Transport"..tostring(Player.localmapid)]
		if (transportFunction ~= nil and type(transportFunction) == "function") then
			local retval = transportFunction(pos1,pos2)
			if (retval == true) then
				return true
			end
		end--]]
		
		local p1 = NavigationManager:GetClosestPointOnMesh(pos1)
		local p2 = NavigationManager:GetClosestPointOnMesh(pos2)
		
		if (p1 and p2) then
			if (TimeSince(ml_global_information.lastPathGet) > 2000 or ml_global_information.lastPathGet == Now()) then
				ml_global_information.lastPathGet = Now()
				local path = NavigationManager:GetPath(p1.x,p1.y,p1.z,p2.x,p2.y,p2.z)
				if (ValidTable(path)) then
					local lastPos = path[TableSize(path)-1]
					local finalDist = PDistance3D(lastPos.x,lastPos.y,lastPos.z,p2.x,p2.y,p2.z)
					if (finalDist <= 2) then	
						--d("Distance from last to end is small, we have a valid path.")
						return true
					else
						local startDist = PDistance3D(lastPos.x,lastPos.y,lastPos.z,p1.x,p1.y,p1.z)
						if (startDist <= 2) then
							--d("We jumped a very small distance or none at all in this iteration, no path.")
							return false
						else
							--d("Assume path is long and we have further iterations to check.")
							return HasNavPath(lastPos,p2)
						end
					end
				end
			end
		end
	end
	
	return false
end
function GetNavPath(pos1,pos2)
	local p1 = NavigationManager:GetClosestPointOnMesh(pos1)
	local p2 = NavigationManager:GetClosestPointOnMesh(pos2)
	
	if (p1 and p2) then		
		local path = NavigationManager:GetPath(p1.x,p1.y,p1.z,p2.x,p2.y,p2.z)
		if (ValidTable(path)) then
			local lastPos = path[TableSize(path)-1]
			
			local finalDist = PDistance3D(lastPos.x,lastPos.y,lastPos.z,p2.x,p2.y,p2.z)
			if (finalDist < 2) then
				--d("Distance from last to end is small, we have a valid path.")
				return true
			else
				local startDist = PDistance3D(lastPos.x,lastPos.y,lastPos.z,p1.x,p1.y,p1.z)
				if (startDist < 2) then
					return false
				else
					return GetNavPath(lastPos,p2)
				end
			end
		end
	end
end
function GetLinePoints(pos1,pos2,length)
	local distance = PDistance3D(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z)
	local segments = math.floor(distance / length)
	
	local points = {}
	for x=1,segments do
		local thisDist = PDistance3D(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z)
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
			
			local dist = PDistance3D(prevPos.x,prevPos.y,prevPos.z,pos.x,pos.y,pos.z)
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
	if (gBotMode == GetString("partyMode") and gPartyGrindUsePartyLeader == "0") then
		if (gPartyLeaderName ~= "") then
			local el = MEntityList("type=1,name="..gPartyLeaderName)
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
			local el = MEntityList("type=1,name="..leader.name)
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
	if (gBotRunning == "0" or IsFlying()) then
		return false
	end
	
	local target;
	--Quick change here to allow passing of a target or just the ID.
	if (type(targetid) == "table") then
		local id = targetid.id
		target = MGetEntity(id)
		if (not target or not ValidTable(target)) then
			return false
		end
	else
		target = MGetEntity(targetid)
		if (not target or not ValidTable(target)) then
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
	if ( Player.castinginfo.channelingid ~= 0 and Player.castinginfo.channeltargetid == targetid) then
		return true
	end
	
	local rootTaskName = ""
	local rootTask = ml_task_hub:RootTask()
	if (rootTask) then
		rootTaskName = rootTask.name
	end
	
	local attackRange = ml_global_information.AttackRange
	if (attackRange < 5 and ((target.distance - target.hitradius) <= (3 * (tonumber(gCombatRangePercent) / 100)))) then
		return true
	elseif (attackRange > 5 and ((target.distance - target.hitradius) <= (24 * (tonumber(gCombatRangePercent) / 100)))) then
		return true
	end
	
	local highestRange = 0
	local charge = false
	local skillID = nil
	
	--and ActionList:CanCast(tonumber(skill.id),target.id)

	if ( TableSize(SkillMgr.SkillProfile) > 0 ) then
		for prio,skill in spairs(SkillMgr.SkillProfile) do
			local skilldata = MGetAction(tonumber(skill.id))
			if (skilldata) then
				if ( skilldata.range > 0 and skill.used == "1" and skilldata.range > highestRange) then
					if ((attackRange < 5 and skilldata.isready) or attackRange >= 5) then
						skillID = tonumber(skill.id)
						highestRange = tonumber(skilldata.range)
						charge = (skill.charge == "1" and true) or false
					end
				end
			end
		end
	end
	
	if ( attackRange < 5 ) then			
		if (skillID ~= nil) then
			if (highestRange > 5) then
				if ((target.targetid == 0 or target.targetid == nil) and rootTaskName ~= "LT_PVP") then
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

	return false
end
function CanAttack(targetid,skillid,skilltype)
	local target = {}
	--Quick change here to allow passing of a target or just the ID.
	if (type(targetid) == "table") then
		local id = targetid.id
		target = MGetEntity(id)
		if (TableSize(target) == 0) then
			return false
		end
	else
		target = MGetEntity(targetid)
		if (TableSize(target) == 0) then
			return false
		end
	end
	
	if (target.los) then
		local canCast = false
		local action;
		if (skillid ~= nil and tonumber(skillid) ~= nil) then
			local stype = 1
			if (skilltype ~= nil and tonumber(skilltype) ~= nil) then
				stype = skilltype
			end
			action = ActionList:Get(skillid,stype,target.id)
		else
			testSkill = SkillMgr.GCDSkills[Player.job]
			action = ActionList:Get(testSkill,1,target.id)
		end
		
		if (action) then
			if (action.range >= ((target.distance - target.hitradius) * .98)) then
				return true
			end
		end
	end
		
	return false
end
function GetMounts()
	local mounts = "None"
	local eq = ActionList("type=13")
	for k,v in pairsByKeys(eq) do
		mounts = mounts..","..v.name
	end
	
	return mounts
end
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
function IsMounting()
	return (not Player.ismounted and (Player.action == 83 or Player.action == 84 or Player.action == 165))
end
function IsMounted()
	return (Player.ismounted)
end
function IsDismounting()
	return (Player.action == 31 or Player.action == 32 or Player.action == 33)
end
function IsPositionLocked()
	local jump = ActionList:Get(2,5)
	return (jump and not jump.isready)
end
function IsLoading()
	if (Quest:IsLoading()) then
		--d("IsLoading [1]")
		return true
	elseif (Player.localmapid == 0) then
		--d("IsLoading [2]")
		return true
	elseif (ml_mesh_mgr.loadingMesh) then
		--d("IsLoading [3]")
		return true
	end
	
	return false
	--return (Quest:IsLoading() or Player.localmapid == 0 or ml_mesh_mgr.loadingMesh)
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
	if (MIsLoading()) then
		return false
	end

	id = tonumber(id) or 0
	category = category or 1
	
	local action = ActionList:Get(id,category)
	if (IsNull(action,0) ~= 0) then
		if (action.isready) then
			return true
		end
	end
	return false
end
function Mount(id)
	local mountID = id or 0
	
	if (IsMounted() or IsMounting()) then
		ml_debug("Cannot mount while mounted or mounting.")
		return
	end
	
	local mounts = ActionList("type=13")
	if (ValidTable(mounts)) then
		--If we weren't passed an id (party-grind), look it up.
		if (mountID == 0) then
			for k,v in pairsByKeys(mounts) do
				if (v.name == gMount) then
					mountID = v.id
				end
			end
		end
			
		if (mountID ~= 0) then
			for k,acmount in pairsByKeys(mounts) do
				if (acmount.id == mountID and acmount.isready) then
					--d("Casted the mount.")
					if (acmount:Cast()) then
						return true
					end
				end
			end
		end	
	end
	
	return false
end
function Dismount()
	local isflying = IsFlying()
	
	if (Player.ismounted and (not isflying or (isflying and not Player:IsMoving()))) then
		SendTextCommand("/mount")
	end
end

function Repair()
	if (gRepair == "1") then
		local blacklist = ml_global_information.repairBlacklist
		local eq = MInventory("type=1000")
		for i,e in pairs(eq) do
			if (e.condition <= 30) then
				if (blacklist[e.id] == nil) then
					blacklist[e.id] = 0
				end
				if (blacklist[e.id] < 3) then
					e:Repair()
					blacklist[e.id] = blacklist[e.id] + 1
				end
			else
				if (blacklist[e.id]) then
					blacklist[e.id] = nil
				end
			end
		end
	end
end
function NeedsRepair()
	if (gRepair == "1") then
		local blacklist = ml_global_information.repairBlacklist
		local eq = MInventory("type=1000")
		for i,e in pairs(eq) do
			if (e.condition <= 30) then
				if (blacklist[e.id] == nil) then
					blacklist[e.id] = 0
				end
				if (blacklist[e.id] < 3) then
					return true
				end
			else
				if (blacklist[e.id]) then
					blacklist[e.id] = nil
				end
			end
		end
	end
	return false
end
function ShouldEat()
	local foodID = nil
	if (gFoodHQ ~= "None") then
		foodID = ffxivminion.foodsHQ[gFoodHQ]
		--d("[ShouldEat]: Looking for foodID ["..tostring(foodID).."].")
		local food = MGetItem(foodID)
		if (food and food.isready and not HasBuffs(Player,"48")) then
			return true
		end
	elseif (gFood ~= "None") then
		foodID = ffxivminion.foods[gFood]
		--d("[ShouldEat]: Looking for foodID ["..tostring(foodID).."].")
		local food = MGetItem(foodID)
		if (food and food.isready and not HasBuffs(Player,"48")) then
			return true
		end
	end
	return false
end
function Eat()
	local foodID = nil
	if (gFoodHQ ~= "None") then
		foodID = ffxivminion.foodsHQ[gFoodHQ]
		--d("[Eat]: Looking for foodID ["..tostring(foodID).."].")
		local food = MGetItem(foodID)
		if (food and food.isready and not HasBuffs(Player,"48")) then
			food:Use()
		end
	elseif (gFood ~= "None") then
		foodID = ffxivminion.foods[gFood]
		--d("[Eat]: Looking for foodID ["..tostring(foodID).."].")
		local food = MGetItem(foodID)
		if (food and food.isready and not HasBuffs(Player,"48")) then
			food:Use()
		end
	end
end
function NodeHasItem(searchItem)
	if (searchItem and type(searchItem) == "string" and searchItem ~= "") then
		for itemName in StringSplit(searchItem,",") do
			local list = MGatherableSlotList()
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
function WhitelistTarget()
	local target = MGetTarget()
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
function BlacklistTarget()
	local target = MGetTarget()
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
function IsMap(itemid)
	local itemid = tonumber(itemid) or 0
	return ((itemid >= 6687 and itemid <= 6692) or
		(itemid == 7884 or itemid == 8156 or itemid == 9900) or
		(itemid >= 12241 and itemid <= 12243))
end
function IsGardening(itemid)
	local itemid = tonumber(itemid) or 0
	return ((itemid >= 7715 and itemid <= 7767) 
			or itemid == 8024
			or itemid == 5365)
end
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
function IsChocoboFood(itemid)
	local itemid = tonumber(itemid) or 0
	return ((itemid >= 10094 and itemid <= 10095) or
			(itemid >= 10097 and itemid <= 10098))
end
function IsChocoboFoodSpecial(itemid)
	local itemid = tonumber(itemid) or 0
	
	local special = {
		[10098] = true,
		[10095] = true,
	}
	return special[itemid]
end
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
function IsUnspoiled(contentid)
	contentid = IsNull(contentid,0)
	return (contentid >= 5 and contentid <= 8)
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
			jobID == FFXIV.JOBS.THAUMATURGE or
			jobID == FFXIV.JOBS.MACHINIST
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
			jobID == FFXIV.JOBS.WHITEMAGE or
			jobID == FFXIV.JOBS.ASTROLOGIAN or
			jobID == FFXIV.JOBS.MACHINIST
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
			jobID == FFXIV.JOBS.BARD or
			jobID == FFXIV.JOBS.MACHINIST
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
			jobID == FFXIV.JOBS.SCHOLAR or 
			jobID == FFXIV.JOBS.ASTROLOGIAN
end
function IsHealer(jobID)
	local jobID = tonumber(jobID)
	return 	jobID == FFXIV.JOBS.WHITEMAGE or
			jobID == FFXIV.JOBS.CONJURER or
			jobID == FFXIV.JOBS.SCHOLAR or 
			jobID == FFXIV.JOBS.ASTROLOGIAN
end
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
	
	local el = MEntityList("myparty,alive,targetable,chartype=4,maxdistance="..tostring(maxdistance))
	--local el = MEntityList("myparty,alive,chartype=4,maxdistance="..tostring(maxdistance))
	if (ValidTable(el)) then
		for i,e in pairs(el) do	
			if ((hasbuffs=="" or HasBuffs(e,hasbuffs)) and (hasnot=="" or MissingBuffs(e,hasnot))) then
				return e
			end						
		end
	end
	
	return nil
end
function PartySMemberWithBuff(hasbuffs, hasnot, maxdistance) 
	maxdistance = maxdistance or 30
 
	local el = MEntityList("myparty,alive,targetable,chartype=4,maxdistance="..tostring(maxdistance))
	--local el = MEntityList("myparty,alive,chartype=4,maxdistance="..tostring(maxdistance))
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
ml_global_information.lastAetheryteCache = 0
function GetAetheryteList(force)
	local force = IsNull(force,false)
	
	if (force == true or ml_global_information.Player_Aetherytes == nil) then
		local newData = CopyAetheryteData()
		if (newData) then
			ml_global_information.Player_Aetherytes = newData
			ml_global_information.lastAetheryteCache = Now()
		end
	else
		if not (MIsLoading()) then
			if (TimeSince(ml_global_information.lastAetheryteCache) > 30000) then
				local newData = CopyAetheryteData()
				if (newData) then
					ml_global_information.Player_Aetherytes = newData
					ml_global_information.lastAetheryteCache = Now()
				end
			end
		end
	end
	
	return ml_global_information.Player_Aetherytes
end
function CopyAetheryteData()
	local apiList = Player:GetAetheryteList()
	if (ValidTable(apiList)) then
		local aethData = {}
		for i,aetheryte in pairsByKeys(apiList) do
			aethData[i] = {
				ptr = aetheryte.ptr,
				id = aetheryte.id,
				name = aetheryte.name,
				ishomepoint = aetheryte.ishomepoint,
				isfavpoint = aetheryte.isfavpoint,
				territory = aetheryte.territory,
				region = aetheryte.region,
				islocalmap = aetheryte.islocalmap,
				price = aetheryte.price,
				isattuned = aetheryte.isattuned,
			}
		end
		return aethData
	end
	return nil
end
function GetLocalAetheryte()
    local list = ml_global_information.Player_Aetherytes
	if (ValidTable(list)) then
		for index,aetheryte in pairsByKeys(list) do
			if (aetheryte.islocalmap) then
				return aetheryte.id
			end
		end
	end
    
    return nil
end
function GetAttunedAetheryteList(force)
	local force = IsNull(force,false)
	
	local attuned = {}
	
	local list = GetAetheryteList(force)
	if (ValidTable(list)) then
		for id,aetheryte in pairsByKeys(list) do
			if (aetheryte.isattuned) then
				table.insert(attuned, aetheryte)
			end
		end
	end
	
	return attuned
end
function GetUnattunedAetheryteList()
	local aethList = {}
	for map,aethdata in pairs(ffxiv_aetheryte_data) do
		for k,aeth in pairs(aethdata) do
			local valid = true
			local requirement = aeth.requires
			if (requirement ~= nil and type(requirement) == "function") then
				valid = IsNull(requirement(),false)
			end
			
			if (valid) then
				aethList[aeth.aethid] = aeth
			end
		end
	end
	
	if (ValidTable(aethList)) then
		local list = ml_global_information.Player_Aetherytes
		if (ValidTable(list)) then
			for id,aetheryte in pairsByKeys(list) do
				if (aetheryte.isattuned and aethList[aetheryte.id]) then
					aethList[aetheryte.id] = nil
				end
			end
		end
	end
	
	return aethList
end
function GetHomepoint()
	local homepoint = 0
	
	local attuned = GetAttunedAetheryteList(true)
	if (ValidTable(attuned)) then
		for id,aetheryte in pairsByKeys(attuned) do
			if (aetheryte.ishomepoint) then
				homepoint = aetheryte.territory
			end
		end
	end
	return homepoint
end
function GetAetheryteByID(id,force)
	local aethid = tonumber(id) or 0
	local force = IsNull(force,false)
	
	local list = GetAetheryteList(force)
	if (ValidTable(list)) then
		for index,aetheryte in pairsByKeys(list) do
			if (aetheryte.id == aethid) then
				return aetheryte
			end
		end
	end
    
    return nil
end
function IsAetheryteUnattuned(id)
	local aethid = tonumber(id) or 0
	local aetheryte = GetAetheryteByID(aethid,true)
	if (aetheryte) then
		return not aetheryte.isattuned
	end
	return false
end
function IsAetheryte(id)
	local aethData = ffxiv_aetheryte_data
	if (table.valid(aetherytes)) then
		for mapid,aetherytes in pairs(aethData) do
			for aetheryte,aethdata in pairs(aetherytes) do
				if (aethdata.aethid == id) then
					return true
				end
			end
		end
	end
	
	return false
end
function GetAetheryteByMapID(mapid, p)
	local pos = p
	
	local myMap = Player.localmapid
	if (mapid == 133 and myMap ~= 132) then
		mapid = 132
	elseif (mapid == 128 and myMap ~= 129) then
		mapid = 129
	elseif (mapid == 131 and myMap ~= 130) then
		mapid = 130
	elseif (mapid == 419 and myMap ~= 418) then
		mapid = 418
	elseif (mapid == 399 and myMap ~= 478) then
		mapid = 478
	end
	
	if 	(myMap == 131 and mapid == 130) or
		(myMap == 128 and mapid == 129) or
		(myMap == 133 and mapid == 133) or
		(myMap == 418 and (mapid == 419 or mapid == 439 or mapid == 427 or mapid == 456 or mapid == 433)) or
		(myMap == 399 and mapid == 478)
	then
		return nil
	end
	
	local ppos = Player.pos
	
	sharedMaps = {
		[153] = { name = "South Shroud",
			[1] = { name = "Quarrymill", aethid = 5, x = 181, z = -66},
			[2] = { name = "Camp Tranquil", aethid = 6, x = -226, z = 355},
		},
		[137] = {name = "Eastern La Noscea",
			[1] = { name = "Costa Del Sol", aethid = 11, x = 0, z = 0,
				best = function ()  
					if (not (ppos.x > 218 and ppos.z > 51) and (pos.x > 218 and pos.z > 51)) then
						return true
					end
					return false
				end	
			},
			[2] = { name = "Wineport", aethid = 12, x = 0, z = 0, 
				best = function ()  
					if ((ppos.x > 218 and ppos.z > 51) and not (pos.x > 218 and pos.z > 51)) then
						return true
					end
					return false
				end	
			},
		},
		[138] = {name = "Western La Noscea",
			[1] = { name = "Swiftperch", aethid = 13, x = 652, z = 509 },
			[2] = { name = "Aleport", aethid = 14, x = 261, z = 223 },		
		},
		[146] = {name = "Southern Thanalan",
			[1] = { name = "Little Ala Mhigo", aethid = 19, x = -165, z = -414 },
			[2] = { name = "Forgotten Springs", aethid = 20, x = -320, z = 406 },
		},
		[147] = {name = "Northern Thanalan",
			[1] = { name = "Bluefog", aethid = 21, x = 24, z = 458 },
			[2] = { name = "Ceruleum", aethid = 22, x = -24, z = -27 },
		},
		[401] = {name = "Sea of Clouds",
			[1] = { name = "Cloudtop", aethid = 72, x = -611, z = 545, 
				best = function ()  
					if (GetSeaOfCloudsSection(Player.pos) == 1 and GetSeaOfCloudsSection(pos) == 2) then
						return true
					end
					return false
				end				
			},
			[2] = { name = "OkZundu", aethid = 73, x = -606, z = -419,
				best = function ()  
					if (GetSeaOfCloudsSection(Player.pos) == 2 and GetSeaOfCloudsSection(pos) == 1) then
						return true
					end
					return false
				end				
			},
		},
		[398] = {name = "Dravanian Forelands",
			[1] = { name = "Tailfeather", aethid = 76, x = 533, z = 35 },
			[2] = { name = "Anyx", aethid = 77, x = -300, z = 30 },
		},
		[400] = {name = "Churning Mists",
			[1] = { name = "Moghome", aethid = 78, x = 256, z = 599 },
			[2] = { name = "Zenith", aethid = 79, x = -583, z = 316 },
		},		
	}
	
	local list = GetAttunedAetheryteList()
	if (ValidTable(list)) then
		if (not pos or not sharedMaps[mapid]) then
			--d("This is not a shared map or we were not given a position.")
			for index,aetheryte in pairsByKeys(list) do
				if (aetheryte.territory == mapid) then
					if (GilCount() >= aetheryte.price and aetheryte.price > 0 and aetheryte.isattuned) then
						return aetheryte
					end
				end
			end
		else
			--d("This is a shared map and we were given a position.")
			local bestID = nil
			
			local sharedMap = sharedMaps[mapid]
			local choices = {}
			for _,sharedData in pairs(sharedMap) do
				for index,aetheryte in pairsByKeys(list) do
					if (aetheryte.id == sharedData.aethid) then
						if (GilCount() >= aetheryte.price and aetheryte.isattuned) then
							choices[#choices+1] = sharedData
						end
					end
				end
			end
			
			local size = TableSize(choices)
			if (size > 1) then
			
				if (choices[1].best and type(choices[1].best) == "function") then
					if (choices[1].best() == true) then
						bestID = choices[1].aethid
					end
				end
				
				if (bestID == nil) then
					if (choices[2].best and type(choices[2].best) == "function") then
						if (choices[2].best() == true) then
							bestID = choices[2].aethid
						end
					end
				end
				
				if (bestID == nil) then
					local distance1 = Distance2D(pos.x, pos.z, choices[1].x, choices[1].z)
					local distance2 = Distance2D(pos.x, pos.z, choices[2].x, choices[2].z)
					bestID = ((distance1 < distance2) and choices[1].aethid) or choices[2].aethid
				end
				
				if (bestID ~= nil) then
					for index,aetheryte in pairsByKeys(list) do
						if (aetheryte.id == bestID) then
							return aetheryte
						end
					end
				end
			elseif (size == 1) then
				for index,aetheryte in pairsByKeys(list) do
					if (aetheryte.id == choices[1].aethid) then
						return aetheryte
					end
				end
			end
		end
	else
		--d("No attuned aetherytes found.")
	end
	
	return nil
end
function GetAetheryteLocation(id)
	local aethid = tonumber(id) or 0
	
	local aetheryteData = ffxiv_aetheryte_data
	for mapid,mapdata in pairs(aetheryteData) do
		for k,aethdata in pairs(mapdata) do
			if (aethdata.aethid == aethid) then
				return {x = aethdata.x, y = aethdata.y, z = aethdata.z}
			end
		end
	end
	
	return nil
end
function CanUseAetheryte(aethid)
	local aethid = tonumber(aethid) or 0
	if (aethid ~= 0) then
		local list = GetAttunedAetheryteList()
		if (ValidTable(list)) then
			for k,aetheryte in pairs(list) do
				if (aetheryte.id == aethid) then
					if (GilCount() >= aetheryte.price and aetheryte.price > 0) then
						return true
					end
				end
			end
		end
	end
	
	return false
end
function GetOffMapMarkerList(strMeshName, strMarkerType)
	local markerPath = ml_mesh_mgr.defaultpath.."\\"..strMeshName..".info"
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
		[478] = true,
	}
	return cityMaps[mapid]
end
function GetOffMapMarkerPos(strMeshName, strMarkerName)
	local newMarkerPos = nil
	
	local markerPath = ml_mesh_mgr.defaultpath.."\\"..strMeshName..".info"
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
function ShouldTeleport(pos)
	if (MIsLocked() or MIsLoading() or ControlVisible("SelectString") or ControlVisible("SelectIconString") or IsShopWindowOpen()) then
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
			local players = MEntityList("type=1,maxdistance=".. scanDistance)
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
				
				local players = MEntityList("type=1")
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
	elseif (level < 49) then
		return 156
	elseif (level <= 49 or (level > 49 and not QuestCompleted(1583))) then
		return 147 --north than
	elseif (level <= 53 and QuestCompleted(1583) and CanAccessMap(397)) then
		return 397
	elseif (level <= 60 and (not QuestCompleted(1609) or not CanAccessMap(398))) then
		return 397
	elseif (level <= 60 and (QuestCompleted(1609) and CanAccessMap(398))) then
		return 398
	end
end
function EquipItem(itemid, itemslot)
	local itemid = tonumber(itemid)
	
	local item = MGetItem(itemid)
	if (item and item.canequip) then
		item:Move(1000,itemslot)
	end
end
function IsEquipped(itemid)
	local itemid = tonumber(itemid)
	local currEquippedItems = MInventory("type=1000")
	for id,item in pairs(currEquippedItems) do
		if (item.hqid == itemid) then
			return true
		end
	end
	return false
end
function EquippedItemLevel(slot)
	local slot = tonumber(slot)
	local currEquippedItems = MInventory("type=1000")
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
function GetItemInSlot(equipSlot)
	local currEquippedItems = MInventory("type=1000")
	for id,item in pairs(currEquippedItems) do
		if(item.slot == equipSlot) then
			return item
		end
	end
	return nil
end
function ItemReady(hqid)
	local itemid = tonumber(hqid)
	local hqid = tonumber(hqid)
	
	if (itemid > 1000000) then
		itemid = itemid - 1000000
	end
	
	local items = Inventory("itemid="..tostring(itemid))
	if (ValidTable(items)) then
		for _,item in pairs(items) do
			if (item.hqid == hqid) then
				return item.isready
			end
		end
	end
	
	return false
end	
function IsInventoryFull()
	local itemcount = 0
	
	--Look through regular bags first.
	for x=0,3 do
		local inv = MInventory("type="..tostring(x))
		for i, item in pairs(inv) do
			itemcount = itemcount + 1
		end
	end
	
	if (itemcount == 100) then
		return true
	end
	
	return false
end
function GetInventorySnapshot()
	local currentSnapshot = {}
	
	--Look through regular bags first.
	for x=0,3 do
		local inv = MInventory("type="..tostring(x))
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
	local inv = MInventory("type=1000")
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
	local inv = MInventory("type=2000")
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
	local inv = MInventory("type=2001")
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
	local inv = MInventory("type=2004")
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

function GetInventoryItemGains(itemid,hqonly)
	hqonly = IsNull(hqonly,false)
	itemid = tonumber(itemid) or 0
	
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

function GetItem(hqid)
	local itemid = tonumber(hqid) or 0
	local hqid = tonumber(hqid) or 0
	
	if (itemid >= 1000000 and itemid < 2000000) then
		itemid = itemid - 1000000
	elseif (itemid >= 500000 and itemid < 600000) then
		itemid = itemid - 500000
	end
	
	local items = Inventory("itemid="..tostring(itemid))
	if (ValidTable(items)) then
		for _,item in pairs(items) do
			if (item.hqid == hqid) then
				return item
			end
		end
	end
	
	local inv = Inventory("type=2004,itemid="..tostring(itemid))
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through equipped items bag.
	local inv = MInventory("type=1000,itemid="..tostring(itemid))
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through currency bag.
	local inv = MInventory("type=2000,itemid="..tostring(itemid))
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through crystals bag.
	local inv = MInventory("type=2001,itemid="..tostring(itemid))
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through armory bags for off-hand through wrists
	for x=3200,3209 do
		local inv = MInventory("type="..tostring(x)..",itemid="..tostring(itemid))
		if (ValidTable(inv)) then
			for i,item in pairs(inv) do
				if (item.hqid == itemid) then
					return item
				end
			end
		end
	end
	
	--Look through rings armory bag.
	local inv = MInventory("type=3300,itemid="..tostring(itemid))
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through soulstones armory bag.
	local inv = MInventory("type=3400,itemid="..tostring(itemid))
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through weapons armory bag.
	local inv = MInventory("type=3500,itemid="..tostring(itemid))
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	return nil
end	

--[[
function GetItem(itemid)
	itemid = tonumber(itemid) or 0
	--includehq = IsNull(includehq,true)
	--requirehq = IsNull(requirehq,false)
	
	--Look through regular bags first.
	for x=0,3 do
		local inv = MInventory("type="..tostring(x))
		if (ValidTable(inv)) then
			for i, item in pairs(inv) do				
				if (item.hqid == itemid) then
					return item
				end
			end
		end
	end

	--Look through equipped items bag.
	local inv = MInventory("type=1000")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through currency bag.
	local inv = MInventory("type=2000")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through crystals bag.
	local inv = MInventory("type=2001")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through armory bags for off-hand through wrists
	for x=3200,3209 do
		local inv = MInventory("type="..tostring(x))
		if (ValidTable(inv)) then
			for i,item in pairs(inv) do
				if (item.hqid == itemid) then
					return item
				end
			end
		end
	end
	
	--Look through rings armory bag.
	local inv = MInventory("type=3300")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through soulstones armory bag.
	local inv = MInventory("type=3400")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through weapons armory bag.
	local inv = MInventory("type=3500")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through quest/key items bag.
	local inv = MInventory("type=2004")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	return nil
end
--]]

function ItemCount(itemid,includehq,requirehq)
	itemid = tonumber(itemid) or 0
	includehq = IsNull(includehq,false)
	requirehq = IsNull(requirehq,false)
	local itemcount = 0
	
	--Look through regular bags first.
	for x=0,3 do
		local inv = MInventory("type="..tostring(x))
		if (ValidTable(inv)) then
			for i, item in pairs(inv) do	
				if (not includehq and not requirehq) then
					if (item.hqid == itemid) then
						itemcount = itemcount + item.count
					end
				else
					if (item.id == itemid) then
						if (requirehq) then
							if (toboolean(item.IsHQ)) then
								itemcount = itemcount + item.count
							end
						else	
							if (includehq or (not includehq and not toboolean(item.IsHQ))) then
								itemcount = itemcount + item.count
							end
						end
					end
				end
			end
		end
	end

	--Look through equipped items bag.
	local inv = MInventory("type=1000")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (not includehq and not requirehq) then
				if (item.hqid == itemid) then
					itemcount = itemcount + item.count
				end
			else
				if (item.id == itemid) then
					if (requirehq) then
						if (toboolean(item.IsHQ)) then
							itemcount = itemcount + item.count
						end
					else	
						if (includehq or (not includehq and not toboolean(item.IsHQ))) then
							itemcount = itemcount + item.count
						end
					end
				end
			end
		end
	end
	
	--Look through currency bag.
	local inv = MInventory("type=2000")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				itemcount = itemcount + item.count
			end
		end
	end
	
	--Look through crystals bag.
	local inv = MInventory("type=2001")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				itemcount = itemcount + item.count
			end
		end
	end
	
	--Look through armory bags for off-hand through wrists
	for x=3200,3209 do
		local inv = MInventory("type="..tostring(x))
		if (ValidTable(inv)) then
			for i,item in pairs(inv) do
				if (not includehq and not requirehq) then
					if (item.hqid == itemid) then
						itemcount = itemcount + item.count
					end
				else
					if (item.id == itemid) then
						if (requirehq) then
							if (toboolean(item.IsHQ)) then
								itemcount = itemcount + item.count
							end
						else	
							if (includehq or (not includehq and not toboolean(item.IsHQ))) then
								itemcount = itemcount + item.count
							end
						end
					end
				end
			end
		end
	end
	
	--Look through rings armory bag.
	local inv = MInventory("type=3300")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (not includehq and not requirehq) then
				if (item.hqid == itemid) then
					itemcount = itemcount + item.count
				end
			else
				if (item.id == itemid) then
					if (requirehq) then
						if (toboolean(item.IsHQ)) then
							itemcount = itemcount + item.count
						end
					else	
						if (includehq or (not includehq and not toboolean(item.IsHQ))) then
							itemcount = itemcount + item.count
						end
					end
				end
			end
		end
	end
	
	--Look through soulstones armory bag.
	local inv = MInventory("type=3400")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (not includehq and not requirehq) then
				if (item.hqid == itemid) then
					itemcount = itemcount + item.count
				end
			else
				if (item.id == itemid) then
					if (requirehq) then
						if (toboolean(item.IsHQ)) then
							itemcount = itemcount + item.count
						end
					else	
						if (includehq or (not includehq and not toboolean(item.IsHQ))) then
							itemcount = itemcount + item.count
						end
					end
				end
			end
		end
	end
	
	--Look through weapons armory bag.
	local inv = MInventory("type=3500")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (not includehq and not requirehq) then
				if (item.hqid == itemid) then
					itemcount = itemcount + item.count
				end
			else
				if (item.id == itemid) then
					if (requirehq) then
						if (toboolean(item.IsHQ)) then
							itemcount = itemcount + item.count
						end
					else	
						if (includehq or (not includehq and not toboolean(item.IsHQ))) then
							itemcount = itemcount + item.count
						end
					end
				end
			end
		end
	end
	
	--Look through quest/key items bag.
	local inv = MInventory("type=2004")
	if (ValidTable(inv)) then
		for i, item in pairs(inv) do
			if (not includehq and not requirehq) then
				if (item.hqid == itemid) then
					itemcount = itemcount + item.count
				end
			else
				if (item.id == itemid) then
					if (requirehq) then
						if (toboolean(item.IsHQ)) then
							itemcount = itemcount + item.count
						end
					else	
						if (includehq or (not includehq and not toboolean(item.IsHQ))) then
							itemcount = itemcount + item.count
						end
					end
				end
			end
		end
	end
	
	return itemcount
end
function GilCount()
	local gil = 0
	local inv = MInventory("type=2000")
	for i,item in pairs(inv) do
		if (item.slot == 0) then
			gil = item.count
		end
	end
	return gil
end
function PoeticCount()
	local poetic = 0
	local inv = MInventory("type=2000")
	for i,item in pairs(inv) do
		if (item.slot == 6) then
			poetic = item.count
		end
	end
	return poetic
end
function SoldieryCount()
	local soldiery = 0
	local inv = MInventory("type=2000")
	for i,item in pairs(inv) do
		if (item.slot == 7) then
			soldiery = item.count
		end
	end
	return soldiery
end
function IsCompanionSummoned()
	local el = MEntityList("type=2,chartype=3,ownerid="..tostring(Player.id))
	if (ValidTable(el)) then
		return true
	end
	
	local dismiss = ActionList:Get(2,6)
	if (dismiss and dismiss.isready) then
		return true
	end
	
	return false
end
function GetCompanionEntity()
	local el = MEntityList("type=2,chartype=3,ownerid="..tostring(Player.id))
	if (ValidTable(el)) then
		local i,entity = next(el)
		if (i and entity) then
			return entity
		end
	end
	
	return nil
end
function IsShopWindowOpen()
	return (ControlVisible("Shop") or ControlVisible("ShopExchangeItem") or ControlVisible("ShopExchangeCurrency")
		or ControlVisible("ShopCard") or ControlVisible("ShopExchangeCoin"))
end
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
		local inv = MInventory("type="..tostring(xref[slot]))
		if (inv) then
			local occupiedSlots = 0
			for i, item in pairs(inv) do
				if (item.id ~= 0) then
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
		local inv = MInventory("type="..tostring(xref[slot]))
		if (inv) then
			local occupiedSlots = 0
			for i, item in pairs(inv) do
				if (item and item.id ~= 0) then
					occupiedSlots = occupiedSlots + 1
				end
			end
			return occupiedSlots
		end
	end
	return 0
end
function LowestArmoryItem(slot)
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
	
	local lowest = nil
	local lowesti = 999
	
	if (slot ~= 13) then
		local inv = MInventory("type="..tostring(xref[slot]))
		if (inv) then
			for i, item in pairs(inv) do
				if (not lowest or (lowest and item.level < lowesti)) then
					lowest,lowesti = item, item.level
					lowest.bag = xref[slot]
				end
			end
		end
	end
	return lowest
end
function GetFirstFreeArmorySlot(armoryType)
	local armoryType = tonumber(armoryType)
	local inv = MInventory("type="..tostring(armoryType))
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
function GetFirstFreeInventorySlot()
	for x = 0,3 do
		local inv = MInventory("type="..tostring(x))
		if (inv) then
			for i=0,24 do
				local found = false
				for id,item in pairs(inv) do
					if (item.slot == i) then
						if (item and item.id ~= 0) then
							found = true
						end
					end
				end
				if (not found) then
					return x,i
				end
			end
		end
	end
	return nil,nil
end
function GetEquippedItem(itemid)
	local itemid = tonumber(itemid)
	
	local inv = MInventory("type=1000")
	for i, item in pairs(inv) do
		if (item.hqid == itemid) then
			return item
		end
	end
	
	return nil
end
function GetUnequippedItem(itemid)
	local itemid = tonumber(itemid)
	
	--Look through regular bags first.
	for x=0,3 do
		local inv = MInventory("type="..tostring(x))
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through armory bags for off-hand through wrists
	for x=3200,3209 do
		local inv = MInventory("type="..tostring(x))
		for i, item in pairs(inv) do
			if (item.hqid == itemid) then
				return item
			end
		end
	end
	
	--Look through rings armory bag.
	local inv = MInventory("type=3300")
	for i, item in pairs(inv) do
		if (item.hqid == itemid) then
			return item
		end
	end
	
	--Look through soulstones armory bag.
	local inv = MInventory("type=3400")
	for i, item in pairs(inv) do
		if (item.hqid == itemid) then
			return item
		end
	end
	
	--Look through weapons armory bag.
	local inv = MInventory("type=3500")
	for i, item in pairs(inv) do
		if (item.hqid == itemid) then
			return item
		end
	end
	
	return nil
end
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
	jpTime.min = tonumber(os.date("!%M"))
	jpTime.sec = tonumber(os.date("!%S"))
	jpTime.isdst = false
	
	return jpTime
end
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
function GetCurrentTime()
	local t = os.date('!*t')
	local thisTime = os.time(t)
	return thisTime
end
function TimePassed(t1, t2)
	local diff = os.difftime(t1, t2)
	return diff
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

function IIF(test,truepart,falsepart)
	if (ValidString(test)) then
		local f = assert(loadstring("return (" .. test .. ")"))()
		if (f ~= nil) then
			if (f == true) then
				return truepart
			end
		end
	elseif (test == true) then
		return truepart
	end
	return falsepart
end

function ClearTable(t)
	if (t ~= nil and type(t) == "table") then
		for k,v in pairs(t) do
			t[k] = nil
		end
	end
end

function IsTable(t)
	if (t ~= nil and type(t) == "table") then
		return true
	end
	return false
end

function IsPVPMap(mapid)
	local mapid = tonumber(mapid) or 0
	local pvpMaps = {
		[149] = true,
		[175] = true,
		[184] = true,
		[186] = true,
		[250] = true,
		[336] = true,
		[337] = true,
		[352] = true,
		[376] = true,
		[422] = true,
		[431] = true,
		[502] = true,
		[506] = true,
		[518] = true,
		[525] = true,
		[526] = true,
		[527] = true,
		[528] = true,
		[537] = true,
		[538] = true,
		[539] = true,
		[540] = true,
		[541] = true,
		[542] = true,
		[543] = true,
		[544] = true,
		[545] = true,
		[546] = true,
		[547] = true,
		[548] = true,
		[549] = true,
		[550] = true,
		[551] = true,
		[552] = true,
		[554] = true,
	}
	return (pvpMaps[mapid] ~= nil)
end

function CanUseAirship()
	if (GilCount() < 120) then
		return false
	else
		if ((Quest:IsQuestCompleted(107) and Quest:IsQuestCompleted(546)) or -- Limsa Starter
			(Quest:IsQuestCompleted(594) and Quest:IsQuestCompleted(528)) or -- Uldah Starter
			(Quest:IsQuestCompleted(39) and Quest:IsQuestCompleted(507))) -- Gridania Starter
		then
			return true
		end
	end
	return false
end

function CanAccessMap(mapid)
	local mapid = tonumber(mapid) or 0
	
	if (mapid ~= 0) then
		if (Player.localmapid ~= mapid) then
			local pos = ml_nav_manager.GetNextPathPos(	Player.pos,
														Player.localmapid,
														mapid	)
			if (ValidTable(pos)) then
				--d("Found a nav path for mapid ["..tostring(mapid).."].")
				return true
			end
			
			local attunedAetherytes = GetAttunedAetheryteList()
			for k,aetheryte in pairs(attunedAetherytes) do
				--d("Checking attuned aetheryte for territory ["..tostring(aetheryte.territory).."] and cost ["..tostring(aetheryte.price).."].")
				if (aetheryte.territory == mapid and GilCount() >= aetheryte.price) then
					--d("Found an attuned aetheryte for mapid ["..tostring(mapid).."].")
					return true
				end
			end
			
			local nearestAetheryte = GetAetheryteByMapID(mapid)
			if (nearestAetheryte) then
				if (GilCount() >= nearestAetheryte.price) then
					--d("Found an attuned aetheryte for mapid ["..tostring(mapid).."].")
					return true
				end
			end
			
			-- Fall back check to see if we can get to Foundation, and from there to the destination.
			for k,aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.id == 70 and GilCount() >= aetheryte.price) then
					local aethPos = {x = -68.819107055664, y = 8.1133041381836, z = 46.482696533203}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,418,mapid)
					if (ValidTable(backupPos)) then
						--d("Found an attuned backup position aetheryte for mapid ["..tostring(mapid).."].")
						return true
					end
				end
			end
		else
			return true
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
		local ent1Dist = PDistance3D(pos.x,pos.y,pos.z,-542.46624755859,155.99462890625,-518.10394287109)
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

function GetSeaOfCloudsSection(pos)
    local sections = {
        [1] = {
            a = {x = -935, z = -935},
            b = {x = -935, z = 117},
            c = {x = 505, z = 117},
            d = {x = 505, z = -935},
            x = {x = -215, z = -409},
        },
        [2] = {
            a = {x = 505, z = -935},
            b = {x = 505, z = -280},
            c = {x = 911, z = -280},
            d = {x = 911, z = -935},
            x = {x = 708, z = -607.5},
        },
        [3] = {
            a = {x = -935, z = 117},
            b = {x = -935, z = 219},
            c = {x = -517, z = 219},
            d = {x = -517, z = 117},
            x = {x = -726, z = 168},
        },
        [4] = {
            a = {x = -280, z = 117},
            b = {x = -280, z = 230},
            c = {x = 426, z = 230},
            d = {x = 426, z = 117},
            x = {x = 73, z = 173.5},
        },
        [5] = {
            a = {x = 300, z = 230},
            b = {x = 300, z = 300},
            c = {x = 430, z = 300},
            d = {x = 430, z = 230},
            x = {x = 365, z = 265},
        },
    }

    local sec = 2
    if (ValidTable(pos)) then
        for i,section in pairs(sections) do
            local isInsideRect = AceLib.API.Math.IsInsideRectangle(pos,section)
            if (isInsideRect) then
                sec = 1
                break
            end
        end
    end

    return sec
end

function Transport139(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	local gilCount = GilCount()
	if (pos1.x < 0 and pos2.x > 0) then
		if (gilCount > 100) then
			return true, function ()
				local newTask = ffxiv_nav_interact.Create()
				newTask.pos = {x = -341.24, y = -1, z = 112.098}
				newTask.uniqueid = 1003586
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		else
			d("[Transport139]: Need need to cross the water, but we lack the gil, might cause a stuck.")
		end
	elseif (pos1.x > 0 and pos2.x < 0) then
		if (gilCount > 100) then
			return true, function ()
				local newTask = ffxiv_nav_interact.Create()
				newTask.pos = {x = 222.812, y = -.959197, z = 258.17599}
				newTask.uniqueid = 1003587
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		else
			d("[Transport139]: Need need to cross the water, but we lack the gil, might cause a stuck.")
		end
	end
	
	return false			
end

function Transport156(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if ((pos1.y < -150 and pos1.x < 12 and pos1.x > -10 and pos1.z < 16.5 and pos1.z > -14.1) and 
		not (pos2.y < -150 and pos2.x < 12 and pos2.x > -10 and pos2.z < 16.5 and pos2.z > -14.1)) then
		--d("Need  to move from west to east.")
		return true, function ()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = .70, y = -157, z = 16.2}
			newTask.uniqueid = 2002502
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	elseif (not (pos1.y < -150 and pos1.x < 12 and pos1.x > -10 and pos1.z < 16.5 and pos1.z > -14.1) and 
			(pos2.y < -150 and pos2.x < 12 and pos2.x > -10 and pos2.z < 16.5 and pos2.z > -14.1)) then
		--d("Need  to move from west to east.")
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = 21.9, y = 20.7, z = -682}
			newTask.uniqueid = 1006530
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	end
	
	return false			
end

function Transport137(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (Distance3DT(pos2,{x = 877, y = 20, z = 145}) < 100 and Distance3DT(pos1,{x = 877, y = 20, z = 145}) > 100) then
		-- Need to go from Costa to the boat, talk to the Ferry Skipper.
		return true, function ()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = 607.8, y = 11.6, z = 391.8}
			newTask.uniqueid = 1003585
			newTask.conversationstrings = {
				["us"] = "Board the Rhotano privateer",
				de = "Zum Großen Schoner",
				fr = "Aller à bord du navire au large",
				jp = "「洋上の大型船」へ行く",
				cn = "前往海上的大型船",
				kr = "'대형 원양어선'으로 이동",
			}
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	elseif (Distance3DT(pos1,{x = 877, y = 20, z = 145}) < 100  and Distance3DT(pos2,{x = 877, y = 20, z = 145}) > 100) then
		-- Need to leave the boat, talk to the captain.
		return true, function ()
			-- Need to leave the boat, talk to the captain.
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = 886.9, y = 21.4, z = 134.2}
			newTask.uniqueid = 1005414
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	end
	
	
	if (GilCount() > 100) then
		if ((pos1.x > 218 and pos1.z > 51) and not (pos2.x > 218 and pos2.z > 51)) then
			--d("Need to move from Costa area to Wineport.")
			return true, function()
				if (CanUseAetheryte(12) and not Player.incombat) then
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (Player.ismounted) then
						Dismount()
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not MIsLocked()) then
						if (Player:Teleport(12)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 12
							newTask.mapID = 137
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				else
					d("Aetheryte 12 check?:"..tostring(CanUseAetheryte(12)))
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 344.447, y = 32.770, z = 91.694}
					newTask.uniqueid = 1003588
					newTask.abort = function () return (CanUseAetheryte(12) and not Player.incombat) end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		elseif (not (pos1.x > 218 and pos1.z > 51) and (pos2.x > 218 and pos2.z > 51)) then
			--d("Need to move from Wineport to Costa area.")
			return true, function()
				if (CanUseAetheryte(11) and not Player.incombat) then
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (Player.ismounted) then
						Dismount()
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not MIsLocked()) then
						if (Player:Teleport(11)) then
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 11
							newTask.mapID = 137
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				else
					d("Aetheryte 11 check?:"..tostring(CanUseAetheryte(11)))
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 21.919, y = 34.0788, z = 223.187}
					newTask.uniqueid = 1003589
					newTask.abort = function () return (CanUseAetheryte(11) and not Player.incombat) end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end
	end
	
	return false			
end

function Transport138(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (GilCount() > 100) then
		if (not (pos1.x < -170 and pos1.z > 390) and (pos2.x <-170 and pos2.z > 390)) then
			return true, function()
				local newTask = ffxiv_nav_interact.Create()
				newTask.pos = {x = 318.314, y = -36, z = 351.376}
				newTask.uniqueid = 1003584
				newTask.conversationIndex = 3
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		elseif ((pos1.x < -170 and pos1.z > 390) and not (pos2.x <-170 and pos2.z > 390)) then
			return true, function()
				local newTask = ffxiv_nav_interact.Create()
				newTask.pos = {x = -290, y = -41.263, z = 407.726}
				newTask.uniqueid = 1005239
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		end
	end
	
	return false			
end

function Transport130(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (pos1.y < 40 and pos2.y > 50) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = -20.760, y = 10, z = -45.3617}
			newTask.uniqueid = 1001834
			newTask.conversationIndex = 1
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	elseif (pos1.y > 50 and pos2.y < 40) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = -25.125, y = 81.799, z = -30.658}
			newTask.uniqueid = 1004339
			newTask.conversationIndex = 2
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	end

	return false			
end

function Transport128(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (pos1.y < 60 and pos2.y > 70) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = 7.802, y = 40, z = 16.158}
			newTask.uniqueid = 1003597
			newTask.conversationIndex = 1
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	elseif (pos1.y > 70 and pos2.y < 60) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = -8.922, y = 91.5, z = -15.193}
			newTask.uniqueid = 1003583
			newTask.conversationIndex = 1
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	end

	return false			
end

function Transport212(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if ((pos1.x < 23.85 and pos1.x > -15.46) and not (pos2.x < 23.85 and pos2.x > -15.46)) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = 22.386226654053, y = 0.99999862909317, z = -0.097462706267834}
			newTask.uniqueid = 2001715
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	elseif (not (pos1.x < 23.85 and pos1.x > -15.46) and (pos2.x < 23.85 and pos2.x > -15.46 )) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = 26.495914459229, y = 1.0000013113022, z = -0.018158292397857}
			newTask.uniqueid = 2001717
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	end

	return false			
end

function Transport351(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if ((pos1.z < 27.394 and pos1.z > -27.20) and not (pos2.z < 27.39 and pos2.z > -27.20)) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = 0.060269583016634, y = -1.9736720323563, z = -26.994096755981}
			newTask.uniqueid = 2002878
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	elseif (not (pos1.z < 27.394 and pos1.z > -27.20) and (pos2.z < 27.39 and pos2.z > -27.20)) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = 0.010291699320078, y = -2, z = -29.227424621582}
			newTask.uniqueid = 2002880
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	end

	return false			
end

function Transport146(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	local distance = PDistance3D(pos1.x,pos1.y,pos1.z,-60.55,-25.107,-556.96)
	if (pos1.y < -15 and distance < 40) then
		if (Quest:IsQuestCompleted(343) or (Quest:HasQuest(343) and Quest:GetQuestCurrentStep(343) > 3)) then
			return true, function()
				local myPos = Player.pos
				local newTask = ffxiv_nav_interact.Create()
				newTask.pos = {x = -69.099, y = -25.899, z = -574.400}
				newTask.uniqueid = 1004609
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		end
	end

	return false			
end

function Transport399(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (not CanFlyInZone()) then
		if (GetHinterlandsSection(pos1) ~= GetHinterlandsSection(pos2)) then
			return true, function()
				local newTask = ffxiv_task_movetomap.Create()
				newTask.destMapID = 478
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		end
	end

	return false			
end

function Transport401(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (not CanFlyInZone()) then
		if (GetSeaOfCloudsSection(pos1) ~= GetSeaOfCloudsSection(pos2)) then
			if (GilCount() > 100) then
				if (GetSeaOfCloudsSection(Player.pos) == 1) then
					if (CanUseAetheryte(72) and not Player.incombat) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (Player.ismounted and GetGameRegion() ~= 1) then
								Dismount()
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not MIsLocked()) then
								if (Player:Teleport(72)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 72
									newTask.mapID = 401
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					end
				else
					if (CanUseAetheryte(73) and not Player.incombat) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (Player.ismounted and GetGameRegion() ~= 1) then
								Dismount()
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not MIsLocked()) then
								if (Player:Teleport(73)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 73
									newTask.mapID = 401
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					end
				end
			end
			
			--[[
			return true, function()
				local newTask = ffxiv_task_movetomap.Create()
				newTask.destMapID = 478
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
			--]]
		end
	end

	return false			
end

function CanFlyInZone()
	if (Player.flying) then
		if (Player.flying.canflyinzone) then
			return true
		end
	end
	return false
end

function IsFlying()
	if (Player.flying) then
		if (Player.flying.isflying) then
			return true
		end
	end
	return false
end

function GetPitch()
	if (Player.flying) then
		return Player.flying.pitch
	end
	return false
end

function ValidTable(t)
	if ( t ~= nil and type(t) == "table" ) then
		for k,v in pairs(t) do
			if (k ~= nil and v ~= nil) then
				return true
			end
		end
	end
	
    return false
end

function TableSize(t)
	if ( t == nil or type(t) ~= "table" ) then
		return 0
	end
	
	local count = 0
	for k,v in pairs(t) do
		count = count + 1
	end

	return count
end

function DoWait(ms)
	ms = tonumber(ms) or 150
	local instructions = {
		{"Wait", { ms }},
	}
	ml_mesh_mgr.ParseInstructions(instructions)
end

function Stop()
	local instructions = {
		{"Stop", {}},
	}
	ml_mesh_mgr.ParseInstructions(instructions)
end

function MoveTo(x,y,z,range,useFollowMovement,useRandomPath,useSmoothTurns)
	local gotoPos = {x = x, y = y, z = z}
	local myPos = Player.pos
		
	if (ValidTable(ff.lastPos)) then
		local lastPos = ff.lastPos
		local dist = PDistance3D(lastPos.x, lastPos.y, lastPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
		if (dist < 1) then
			if ((TimeSince(ff.lastPath) < 20000 and Player:IsMoving()) or
				(TimeSince(ff.lastPath) < 1000) or
				(TimeSince(ff.lastFail) < 10000)) 
			then
				return
			end
		end
	end
		
	local path = Player:MoveTo(tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z),range,useFollowMovement,useRandomPath,useSmoothTurns)
	ff.lastPos = gotoPos
	
	if (not tonumber(path)) then
		ml_debug("[MoveTo]: An error occurred in creating the path.", "gLogCNE", 2)
		if (path ~= nil) then
			ml_debug(path)
		end
		Stop()
		ff.lastFail = Now()
	elseif (path >= 0) then
		ml_debug("[MoveTo]: A path with ["..tostring(path).."] points was created.", "gLogCNE", 2)
		ff.lastPos = gotoPos
		ff.lastPath = Now()
	elseif (path <= -1) then
		ml_debug("[MoveTo]: A path could not be created towards the goal, error code ["..tostring(path).."].", "gLogCNE", 2)
		Stop()
		ff.lastFail = Now()
	end
end

function UsingBattleItem()
	local currentAction = Player.action
	return (currentAction == 83 or currentAction == 84 or currentAction == 85 or currentAction == 89 or currentAction == 90 or currentAction == 91)
end

function IsTransporting()
	return HasBuff(Player.id,404)
end

function toboolean(input)
	if (input ~= nil) then
		if (type(input) == "string") then
			if (input == "1" or input == "true") then
				return true
			else
				return false
			end
		elseif (type(input) == "number") then
			return input == 1
		end
	end
	return false
end

function TestConditions(conditions)			
	local testKey,testVal = next(conditions)
	if (tonumber(testKey) ~= nil) then
		for i,conditionset in pairsByKeys(conditions) do
			for condition,value in pairs(conditionset) do
				local f = assert(loadstring("return " .. condition))()
				if (f ~= nil) then
					if (f ~= value) then
						return false
					end
					conditions[i][condition] = nil
				end
			end
			conditions[i] = nil
		end
	else
		for condition,value in pairs(conditions) do
			local f = assert(loadstring("return " .. condition))()
			if (f ~= nil) then
				if (f ~= value) then
					return false
				end
				conditions[condition] = nil
			end
		end
	end
	
	return true, conditions
end

function string.pad(str, padding, padchar)
    if padchar == nil then padchar = ' ' end
    return str .. string.rep(padchar, padding - string.len(str))
end

function IsPOTD(mapid)
	local potd = {
		[561] = true,
		[562] = true,
		[563] = true,
		[564] = true,
		[565] = true,
	}
	
	return potd[mapid]
end

function IsHW(mapid)
	local hw = {
		[397] = true,
		[398] = true,
		[399] = true,
		[400] = true,
		[401] = true,
		[402] = true,
	}
	
	return hw[mapid]
end
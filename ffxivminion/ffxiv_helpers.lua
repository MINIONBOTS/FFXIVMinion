-- This file holds global helper functions
ff = {}
ff.lastPos = {}
ff.lastPath = 0
ff.lastFail = 0
ff.lastaetherCurrent = {}
ff.aetherCurrent = {}
ff.mapsections = {
	[399] = 0,
}

function GetPatchLevel()
	local gr = ffxivminion.gameRegion
	if (IsNull(gr,0) == 0) then
		gr = GetGameRegion()
		ffxivminion.gameRegion = gr
	end
	return ffxivminion.patchLevel[gr]
end

function FilterByProximity(entities,center,radius,sortfield)
	if (table.valid(entities) and table.valid(center) and tonumber(radius) > 0) then
		local validEntities = {}
		for i,e in pairs(entities) do
			local epos = e.pos
			local dist = PDistance3D(center.x,center.y,center.z,epos.x,epos.y,epos.z)
	
			if (dist <= radius) then
				table.insert(validEntities,e)
			end
		end
		
		if (table.valid(validEntities)) then
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

function FindRadarMarker(id,flag,both,reqdist,distancepos)
	local id = tonumber(id) or 0
	local flag = tonumber(flag) or 0
	local both = IsNull(both,false)
	local reqdist = IsNull(reqdist,0)
	local distancepos = IsNull(distancepos,Player.pos)

	local viable = {}
	local info = GetControlData("_NaviMap")
	if (table.valid(info)) then
		if (table.valid(info.markers)) then
			for k,marker in pairs(info.markers) do
				local dist2d = 0
				if (reqdist ~= 0) then
					dist2d = math.distance2d(marker.x,marker.y,distancepos.x,distancepos.z)
				end
				if (reqdist == 0 or dist2d <= reqdist) then
					if (both and id ~= 0 and flag ~= 0) then
						if (id ~= 0 and marker.id == id and (bit.band(marker.flags,flag) ~= 0 or marker.flags == flag)) then
							d("[FindRadarMarker] Found a marker with id ["..tostring(id).."] and flag ["..tostring(flag).."].")
							viable = {id = marker.id, flags = marker.flags, x = marker.x, z = marker.y}
							return viable
						end
					else
						if (id ~= 0 and marker.id == id and flag ~= 0 and (bit.band(marker.flags,flag) ~= 0 or marker.flags == flag)) then
							d("[FindRadarMarker] Found a marker with id ["..tostring(id).."].")
							viable = {id = marker.id, flags = marker.flags, x = marker.x, z = marker.y}
							return viable
						elseif (flag ~= 0 and bit.band(marker.flags,flag) ~= 0) then
							d("[FindRadarMarker] Found a marker with flag ["..tostring(flag).."].")
							viable = {id = marker.id, flags = marker.flags, x = marker.x, z = marker.y}
							return viable
						elseif (id ~= 0 and marker.id == id) then
							d("[FindRadarMarker] Found a marker with id ["..tostring(id).."].")
							viable = {id = marker.id, flags = marker.flags, x = marker.x, z = marker.y}
							return viable
						end
					end
				end
			end
		end
	end
	
	return nil
end

function GetNearestGrindAttackable()
	local excludeString = ""
	local huntString = ""
	
	local monsterBlacklist = ml_list_mgr.GetList("Mob Blacklist")
	local monsterHuntlist = ml_list_mgr.GetList("Mob Whitelist")
	
	if (monsterBlacklist) then
		excludeString = monsterBlacklist:GetList("string","id",";")
	end
	if (monsterHuntlist) then
		huntString = monsterHuntlist:GetList("string","id",";")
	end
	
	local block = 0
	local el = nil
	local nearestGrind = nil
	local nearestDistance = 9999
	
	if (excludeString == "") then
		excludeString = "541"
	else
		excludeString = excludeString..";541"
	end
	
	local minLevel, maxLevel, basePos, radius, blacklist, whitelist = 1, 70, Player.pos, 150, "", ""
	
	local task = ffxiv_grind.currentTask
	local marker = ml_marker_mgr.currentMarker
	
	if (table.valid(task)) then
		minLevel = IsNull(task.mincontentlevel,1)
		maxLevel = IsNull(task.maxcontentlevel,70)
		radius = IsNull(task.maxradius,150)
		basePos = task.pos
		blacklist = IsNull(task.blacklist,"")
		whitelist = IsNull(task.whitelist,"")
	elseif (table.valid(marker)) then
		minLevel = IsNull(marker.mincontentlevel,1)
		maxLevel = IsNull(marker.maxcontentlevel,70)
		radius = IsNull(marker.maxradius,150)
		basePos = marker.pos
		blacklist = IsNull(marker.blacklist,"")
		whitelist = IsNull(marker.whitelist,"")
	end
	
	if (whitelist ~= "") then
		if (huntString ~= "") then
			huntString = huntString..";"..whitelist
		else
			huntString = whitelist
		end
	end
	if (blacklist ~= "") then
		if (excludeString ~= "") then
			excludeString = excludeString..";"..blacklist
		else
			excludeString = blacklist
		end
	end
	
	local huntTable = {}
	local excludeTable = {}
	if (huntString ~= "") then
		for contentid in StringSplit(huntString,";") do
			huntTable[tonumber(contentid)] = true
		end
	end
	if (excludeString ~= "") then
		for contentid in StringSplit(excludeString,";") do
			excludeTable[tonumber(contentid)] = true
		end
	end
	
	local selfaggro = {}
	local immediateaggro = {}
	local partyaggro = {}
	local notincombat = {}
	local lowhp = {}
	local claimrange = {}
	local memberids = {}
	local filtered = {}
	local unclaimed = {}

	local attackables = MEntityList("alive,attackable,fateid=0")
	if (table.valid(attackables)) then
	
		local pid = Player.id
		local party = EntityList.myparty
		if (party) then
			for i,e in pairs(party) do
				memberids[e.id] = true
			end
		end
		memberids[pid] = true
		local pet = Player.pet
		local companion = GetCompanionEntity()
		
		for i,entity in pairs(attackables) do
			if (entity) then
				local eid, hpp, epos, distance2d, contentid, aggro, claimedbyid, targetid, incombat = entity.id, entity.hp.percent, entity.pos, entity.distance2d, entity.contentid, entity.aggro, entity.targetid, entity.targetid, entity.incombat
				local cached = { id = eid, hpp = hpp, pos = epos, distance2d = distance2d, contentid = contentid, aggro = aggro, claimedbyid = claimedbyid, targetid = targetid, incombat = incombat }
				
				-- Filter out entities by distance
				if (table.valid(basePos) and radius > 0) then
					local dist2d = math.distance2d(entity.pos,basePos)
					if (dist2d > radius) then
						attackables[i] = nil
					end
				end
				
				-- Filter out white/blacklists
				if (table.valid(huntTable)) then
					if (not huntTable[contentid]) then
						attackables[i] = nil
					end
				elseif (table.valid(excludeTable)) then
					if (excludeTable[contentid]) then
						attackables[i] = nil
					end
				end
				
				if (attackables[i]) then
					filtered[eid] = cached
				
					if (gClaimed or not incombat) then
						notincombat[eid] = cached
						if (gClaimFirst) then
							if (distance2d <= gClaimRange) then
								claimrange[eid] = cached
							end
						end
					end
					if (hpp < 50) then
						lowhp[eid] = cached
					end
					
					if (aggro or claimedbyid == pid or targetid == Player.id) then
						selfaggro[eid] = cached
					elseif ((pet and (claimedbyid == pet.id or targetid == pet.id)) or (companion and (claimedbyid == companion.id or targetid == companion.id))) then
						immediateaggro[eid] = cached
					elseif (memberids[claimedbyid] or memberids[targetid]) then
						partyaggro[eid] = cached	
					elseif (not gClaimed and claimedbyid ~= 0) then
						attackables[i] = nil
						filtered[eid] = nil
					end
				end
			end
		end
	end
	
	if (table.valid(filtered)) then
	
		-- Check if we have something we can claim (for hunting near us)
		if (table.valid(claimrange)) then
			local nearest, nearestDistance = nil, 1000
			for i,e in pairs(filtered) do
				if (claimrange[i]) then
					if (not nearest or (nearest and e.distance2d < nearestDistance)) then
						nearest, nearestDistance = e, e.distance2d
					end
				end
			end
			
			if (nearest) then
				local actual = EntityList:Get(nearest.id)
				if (actual) then
					--d("[GetNearestGrindAttackable]: Returning nearest hunt mob that we can claim quickly.")
					return actual
				end
			end
		end
		
		-- Check for aggro
		if (table.valid(selfaggro) or table.valid(immediateaggro) or table.valid(partyaggro)) then
			local lowest, lowestHP = nil, 100
			local nearest, nearestDistance = nil, 1000
			
			if (table.valid(lowhp)) then
				for i,e in pairs(lowhp) do
					if (selfaggro[i] or immediateaggro[i] or partyaggro[i]) then
						if (not lowest or (lowest and e.hpp < lowestHP)) then
							lowest, lowestHP = e, e.hpp
						end
					end
				end
			end
			
			if (lowest) then
				local actual = EntityList:Get(lowest.id)
				if (actual) then
					--d("[GetNearestGrindAttackable]: Returning lowest low-HP aggro mob.")
					return actual
				end
			end
			
			for i,e in pairs(filtered) do
				if (selfaggro[i] or immediateaggro[i] or partyaggro[i]) then
					if (not nearest or (nearest and e.distance2d < nearestDistance)) then
						nearest, nearestDistance = e, e.distance2d
					end
				end
			end
			
			if (nearest) then
				local actual = EntityList:Get(nearest.id)
				if (actual) then
					--d("[GetNearestGrindAttackable]: Returning nearest aggro mob.")
					return actual
				end
			end
		end
	end
	
	-- Last check, nearest non-filtered mob.
	if (table.valid(attackables)) then
		local nearest, nearestDistance = nil, 1000
		for i,e in pairs(attackables) do
			if (not nearest or (nearest and e.distance2d < nearestDistance)) then
				if (e.level <= (Player.level + 2)) then
					if (e.level >= (Player.level - 4)) then
						nearest, nearestDistance = e, e.distance2d
					else
						nearest, nearestDistance = e, e.distance2d
					end
				end
			end
		end
			
		if (nearest) then
			local actual = EntityList:Get(nearest.id)
			if (actual) then
				--d("[GetNearestGrindAttackable]: Returning nearest grindable mob. ["..tostring(actual.name).."], @ ["..tostring(actual.pos.x)..","..tostring(actual.pos.y)..","..tostring(actual.pos.z).."]")
				return actual
			else
				d("[GetNearestGrindAttackable]: No Mobs Attackable below level "..tostring(Player.level + 2).." within Grind range of "..tostring(radius))
			end
		end
	end
    return nil
end

function GetNearestFateAttackable2()

	local fate = MGetFateByID(ml_task_hub:CurrentTask().fateid)
	if (fate) then
		local maxLevel = fate.maxlevel
		local overMaxLevel = (Player.level > maxLevel)
		local basePos = { x = fate.x, y = fate.y, z = fate.z }
		local radius = fate.radius
		
		local excludeString = ""
		local monsterBlacklist = ml_list_mgr.GetList("Mob Blacklist")
		local monsterHuntlist = ml_list_mgr.GetList("Mob Whitelist")
		if (monsterBlacklist) then
			excludeString = monsterBlacklist:GetList("string","id",";")
		end
		
		local el = nil
		local nearestGrind = nil
		local nearestDistance = 9999
		
		if (excludeString == "") then
			excludeString = "541"
		else
			excludeString = excludeString..";541"
		end
		local blacklist = ""
		if (blacklist ~= "") then
			if (excludeString ~= "") then
				excludeString = excludeString..";"..blacklist
			else
				excludeString = blacklist
			end
		end
		
		local excludeTable = {}
		if (excludeString ~= "") then
			for contentid in StringSplit(excludeString,";") do
				excludeTable[tonumber(contentid)] = true
			end
		end
		
		local selfaggro = {}
		local immediateaggro = {}
		local partyaggro = {}
		local notincombat = {}
		local lowhp = {}
		local claimrange = {}
		local memberids = {}
		local filtered = {}
		local unclaimed = {}
		
		local attackables = MEntityList("alive,attackable")
		if (table.valid(attackables)) then
			local pid = Player.id
			local party = EntityList.myparty
			if (party) then
				for i,e in pairs(party) do
					memberids[e.id] = true
				end
			end
			memberids[pid] = true
			local pet = Player.pet
			local companion = GetCompanionEntity()
			
			for i,e in pairs(attackables) do
				local entity = EntityList:Get(e.id)
				if (entity) then
					local eid, hpp, epos, distance2d, contentid, aggro, claimedbyid, targetid, incombat, fateid = entity.id, entity.hp.percent, entity.pos, entity.distance2d, entity.contentid, entity.aggro, entity.targetid, entity.targetid, entity.incombat, entity.fateid
					local cached = { id = eid, hpp = hpp, pos = epos, distance2d = distance2d, contentid = contentid, aggro = aggro, claimedbyid = claimedbyid, targetid = targetid, incombat = incombat, fateid = fateid }
					
					-- Filter out entities by distance
					if (table.valid(basePos) and radius > 0) then
						local dist2d = math.distance2d(entity.pos,basePos)
						if (dist2d > radius) then
							attackables[i] = nil
						end
					end
					
					-- Filter out white/blacklists
					if (table.valid(huntTable)) then
						if (not huntTable[contentid]) then
							attackables[i] = nil
						end
					elseif (table.valid(excludeTable)) then
						if (excludeTable[contentid]) then
							attackables[i] = nil
						end
					end
					
					if (attackables[i]) then
						filtered[eid] = cached
					
						if (gClaimed or not incombat) then
							notincombat[eid] = cached
							if (gClaimFirst) then
								if (distance2d <= gClaimRange) then
									claimrange[eid] = cached
								end
							end
						end
						if (hpp < 50) then
							lowhp[eid] = cached
						end
						
						if (aggro or claimedbyid == pid or targetid == Player.id) then
							selfaggro[eid] = cached
						elseif ((pet and (claimedbyid == pet.id or targetid == pet.id)) or (companion and (claimedbyid == companion.id or targetid == companion.id))) then
							immediateaggro[eid] = cached
						elseif (memberids[claimedbyid] or memberids[targetid]) then
							partyaggro[eid] = cached					
						end
					end
				end
			end
			
		end
	
		
		if (fate.status == 2 and fate.completion < 100) then
			
		end
	end


	
	if (table.valid(filtered)) then
	
		-- Check if we have something we can claim (for hunting near us)
		if (table.valid(claimrange)) then
			local nearest, nearestDistance = nil, 1000
			for i,e in pairs(filtered) do
				if (claimrange[i]) then
					if (not nearest or (nearest and e.distance2d < nearestDistance)) then
						nearest, nearestDistance = e, e.distance2d
					end
				end
			end
			
			if (nearest) then
				--d("[GetNearestGrindAttackable]: Returning nearest hunt mob that we can claim quickly.")
				return attackables[nearest.id]
			end
		end
		
		-- Check for aggro
		if (table.valid(selfaggro) or table.valid(immediateaggro) or table.valid(partyaggro)) then
			local lowest, lowestHP = nil, 100
			local nearest, nearestDistance = nil, 1000
			
			if (table.valid(lowhp)) then
				for i,e in pairs(lowhp) do
					if (selfaggro[i] or immediateaggro[i] or partyaggro[i]) then
						if (not lowest or (lowest and e.hpp < lowestHP)) then
							lowest, lowestHP = e, e.hpp
						end
					end
				end
			end
			
			if (lowest) then
				--d("[GetNearestGrindAttackable]: Returning lowest low-HP aggro mob.")
				return attackables[lowest.id]
			end
			
			for i,e in pairs(filtered) do
				if (selfaggro[i] or immediateaggro[i] or partyaggro[i]) then
					if (not nearest or (nearest and e.distance2d < nearestDistance)) then
						nearest, nearestDistance = e, e.distance2d
					end
				end
			end
			
			if (nearest) then
				--d("[GetNearestGrindAttackable]: Returning nearest aggro mob.")
				return attackables[nearest.id]
			end
		end
		
		-- Last check, nearest non-filtered mob.
		if (table.valid(notincombat)) then
			local nearest, nearestDistance = nil, 1000
			for i,e in pairs(notincombat) do
				if (not nearest or (nearest and e.distance2d < nearestDistance)) then
					nearest, nearestDistance = e, e.distance2d
				end
			end
				
			if (nearest) then
				--d("[GetNearestGrindAttackable]: Returning nearest grindable mob. ["..tostring(actual.name).."], @ ["..tostring(actual.pos.x)..","..tostring(actual.pos.y)..","..tostring(actual.pos.z).."]")
				return nearest
			end
		end
	end
	
    return nil
end

function GetNearestGrindPriority()
	local huntString = GetWhitelistIDString
	local excludeString = GetBlacklistIDString
	local el = nil
	
	if (gClaimFirst	) then
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
	
	if (fate) then
		local maxLevel = fate.maxlevel
		local overMaxLevel = (Player.level > maxLevel)
		
		if (fate.status == 2 and fate.completion < 100) then
		
			local nearest,nearestDistance = nil,0
			el = MEntityList("alive,attackable,onmesh,maxdistance2d=100,contentid=6737;6738")
			if (table.valid(el)) then
				for i,entity in pairs(el) do
					if (entity.fateid == fate.id) then
						local epos = entity.pos
						local fatedist = Distance2D(epos.x,epos.z,fate.x,fate.z)
						if (fatedist <= fate.radius or (not overMaxLevel and fatedist <= (fate.radius * 1.10))) then
							local dist = entity.distance2d
							if (not nearest or dist < nearestDistance) then
								nearest, nearestDistance = entity, dist
							end
						end
					end
				end
				if (nearest) then
					return nearest
				end
			end	
			
			if (fate.type == 1) then
				el = MEntityList("alive,attackable,onmesh")
				if (table.valid(el)) then
					local bestTarget = nil
					local highestHP = 0
					
					for i,entity in pairs(el) do
						if (entity.fateid == fate.id or entity.fateid > 10000) then
							if (not bestTarget or (bestTarget and entity.hp.max > highestHP)) then
								bestTarget = entity
								highestHP = entity.hp.max
							end
						end
					end
					
					if (bestTarget) then
						if (bestTarget.targetid ~= Player.id and bestTarget.aggropercentage ~= 100) then
							-- See if we have something attacking us that can be killed quickly, if we are not currently the target.
							el = MEntityList("los,nearest,alive,attackable,targetingme,onmesh,maxdistance2d=25")
							if (table.valid(el)) then
								local nearestQuick = nil
								local nearestQuickDistance = 500
								
								for i,e in pairs(el) do
									local entity = EntityList:Get(e.id)
									if (entity) then
										local epos = entity.pos
										local ehp = entity.hp
										local mhp = Player.hp
										local dist = Distance2D(epos.x,epos.z,fate.x,fate.z)
										if (dist <= fate.radius and 
											(ehp.max <= (mhp.max * 2) or (ehp.current < (mhp.max * 2)))) 
										then
											if (not nearestQuick or (nearestQuick and dist < nearestQuickDistance)) then
												nearestQuick,nearestQuickDistance = entity,dist
											end
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
			
			local nearest,nearestDistance = nil,0
			el = MEntityList("alive,attackable,targetingme,onmesh,maxdistance2d=10")
			if (table.valid(el)) then
				for i,entity in pairs(el) do
					if (entity.fateid == fate.id or entity.fateid > 10000 or gFateKillAggro) then
						local epos = entity.pos
						local fatedist = Distance2D(epos.x,epos.z,fate.x,fate.z)
						if (fatedist <= fate.radius or (not overMaxLevel and fatedist <= (fate.radius * 1.10)) or entity.fateid == 0) then
							local dist = entity.distance2d
							if (not nearest or dist < nearestDistance) then
								nearest, nearestDistance = entity, dist
							end
						end
					end
				end
				if (nearest) then
					return nearest
				end
			end	

			nearest,nearestDistance = nil,0
			local companion = GetCompanionEntity()
			if (companion) then
				el = MEntityList("alive,attackable,onmesh,targeting="..tostring(companion.id)..",maxlevel="..tostring(Player.level+3)..",maxdistance=30")
				if (table.valid(el)) then
					for i,e in pairs(el) do
						if (e.fateid == fate.id or e.fateid > 10000 or gFateKillAggro) then
							local epos = e.pos
							local fatedist = Distance2D(epos.x,epos.z,fate.x,fate.z)
							if (fatedist <= fate.radius or (not overMaxLevel and fatedist <= (fate.radius * 1.10)) or e.fateid == 0) then
								local dist3d = Distance3D(epos.x,epos.y,epos.z,myPos.x,myPos.y,myPos.z)
								if (not nearest or dist3d < nearestDistance) then
									nearest, nearestDistance = e, dist3d
								end
							end
						end
					end
					if (nearest) then
						return nearest
					end
				end	
			end
			
			local nearest,nearestDistance = nil,0
			el = MEntityList("los,alive,attackable,aggro,onmesh,maxdistance=10")
			if (table.valid(el)) then
				for i,entity in pairs(el) do
					if (entity.fateid == fate.id or entity.fateid > 10000 or gFateKillAggro) then
						local epos = entity.pos
						local fatedist = Distance2D(epos.x,epos.z,fate.x,fate.z)
						if (fatedist <= fate.radius or (not overMaxLevel and fatedist <= (fate.radius * 1.10)) or entity.fateid == 0) then
							local dist3d = Distance3D(epos.x,epos.y,epos.z,myPos.x,myPos.y,myPos.z)
							if (not nearest or dist3d < nearestDistance) then
								nearest, nearestDistance = entity, dist3d
							end
						end
					end
				end
				if (nearest) then
					return nearest
				end
			end	
			
			nearest,nearestDistance = nil,0
			el = MEntityList("alive,attackable,onmesh")
			if (table.valid(el)) then
				for i,entity in pairs(el) do
					if (entity.fateid == fate.id or entity.fateid > 10000) then
						local epos = entity.pos
						local fatedist = Distance2D(epos.x,epos.z,fate.x,fate.z)
						if (fatedist <= fate.radius) then
							local dist3d = Distance3D(epos.x,epos.y,epos.z,myPos.x,myPos.y,myPos.z)
							if (not nearest or dist3d < nearestDistance) then
								nearest, nearestDistance = entity, dist3d
							end
						end
					end
				end
				if (nearest) then
					return nearest
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
	
	if (gHuntSRankHunt ) then
		if (excludeString) then
			el = MEntityList("contentid="..ffxiv_task_hunt.rankS..",alive,attackable,onmesh,exclude_contentid="..excludeString)
		else
			el = MEntityList("contentid="..ffxiv_task_hunt.rankS..",alive,attackable,onmesh")
		end
		if (table.valid(el)) then
			for i,e in pairs(el) do
				local myPos = Player.pos
				local tpos = e.pos
				local distance = PDistance3D(myPos.x, myPos.y, myPos.z, tpos.x, tpos.y, tpos.z)
				if (distance < nearestDistance) then
					nearest = e
					nearestDistance = distance
				end
			end
			
			if (table.valid(nearest)) then
				return "S", nearest
			end
		end
	end
	
	if (gHuntARankHunt ) then
		if (excludeString) then
			el = MEntityList("contentid="..ffxiv_task_hunt.rankA..",alive,attackable,onmesh,exclude_contentid="..excludeString)
		else
			el = MEntityList("contentid="..ffxiv_task_hunt.rankA..",alive,attackable,onmesh")
		end
		if (table.valid(el)) then
			for i,e in pairs(el) do
				local myPos = Player.pos
				local tpos = e.pos
				local distance = PDistance3D(myPos.x, myPos.y, myPos.z, tpos.x, tpos.y, tpos.z)
				if (distance < nearestDistance) then
					nearest = e
					nearestDistance = distance
				end
			end
			
			if (table.valid(nearest)) then
				return "A", nearest
			end
		end
	end
	
	if (gHuntBRankHunt ) then
		if (gHuntBRankHuntID ~= "") then
			if (excludeString) then
				el = MEntityList("contentid="..tostring(gHuntBRankHuntID)..",alive,attackable,onmesh,exclude_contentid="..excludeString)
			else
				el = MEntityList("contentid="..tostring(gHuntBRankHuntID)..",alive,attackable,onmesh")
			end
			if (table.valid(el)) then
				for i,e in pairs(el) do
					local myPos = Player.pos
					local tpos = e.pos
					local distance = PDistance3D(myPos.x, myPos.y, myPos.z, tpos.x, tpos.y, tpos.z)
					if (distance < nearestDistance) then
						nearest = e
						nearestDistance = distance
					end
				end
				
				if (table.valid(nearest)) then
					return "B", nearest
				end
			end
		end
		
		if (gHuntBRankHuntAny ) then
			if (excludeString) then
				el = MEntityList("contentid="..ffxiv_task_hunt.rankB..",alive,attackable,onmesh,exclude_contentid="..excludeString)
			else
				el = MEntityList("contentid="..ffxiv_task_hunt.rankB..",alive,attackable,onmesh")
			end
			if (table.valid(el)) then
				for i,e in pairs(el) do
					local myPos = Player.pos
					local tpos = e.pos
					local distance = PDistance3D(myPos.x, myPos.y, myPos.z, tpos.x, tpos.y, tpos.z)
					if (distance < nearestDistance) then
						nearest = e
						nearestDistance = distance
					end
				end
				
				if (table.valid(nearest)) then
					return "B", nearest
				end
			end
		end
	end
	
	return nil
end
function IsValidHealTarget(e)
	if (table.valid(e) and e.alive and e.targetable and not e.aggro) then
		return (e.chartype == 4) or (e.id == Player.id) or
			(e.chartype == 0 and (e.type == 2 or e.type == 3 or e.type == 5)) or
			(e.chartype == 3 and e.type == 2) or
			(((e.chartype == 5 or e.chartype == 9) and e.type == 2) and (e.friendly or not e.attackable))
	end
	
	return false
end
function GetBestTankHealTarget( range )
	range = range or ml_global_information.AttackRange
	local lowest = nil
	local lowestHP = 101

    local el = MEntityList("friendly,alive,chartype=4,myparty,targetable,maxdistance="..tostring(range))
	--local el = MEntityList("friendly,alive,chartype=4,myparty,maxdistance="..tostring(range))
    if ( table.valid(el) ) then
		for i,entity in pairs(el) do
			if (IsTank(entity.job) and entity.hp.percent < lowestHP ) then
				lowest = entity
				lowestHP = entity.hp.percent
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
function GetBestPartyHealTarget( npc, range, hp, whitelist )	
	local npc = npc
	if (npc == nil) then npc = false end
	local range = range or ml_global_information.AttackRange
	local hp = hp or 95
	local whitelist = IsNull(whitelist,"")
	
	local search = ""
	local healables = {}
	
	search = "alive,friendly,chartype=4,myparty,targetable,maxdistance="..tostring(range)
	if (whitelist ~= "") then search = search .. ",contentid=" .. tostring(whitelist) end
	
	local el = MEntityList(search)	
	if ( table.valid(el) ) then
		for i,entity in pairs(el) do
			if (IsValidHealTarget(entity) and entity.hp.percent <= hp) then
				healables[i] = entity
			end
		end
	end
	
	if (npc) then
		search = "alive,targetable,maxdistance="..tostring(range)
		if (whitelist ~= "") then search = search .. ",contentid=" .. tostring(whitelist)  end
	
		el = MEntityList(search)
		if ( table.valid(el) ) then
			for i,entity in pairs(el) do
				if (IsValidHealTarget(entity) and entity.hp.percent <= hp) then
					healables[i] = entity
				end
			end
		end
	end
	
	if (table.valid(healables)) then
		local lowest = nil
		local lowesthp = 100
		
		for i,entity in pairs(healables) do
			if (not lowest or (lowest and entity.hp.percent < lowesthp)) then
				lowest = entity
				lowesthp = entity.hp.percent
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
    npc = (skill.npc )
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
		
		if ( table.valid(el) ) then
			for i,entity in pairs(el) do
				if (IsValidHealTarget(entity)) then
					if (not lowest or entity.hp.percent < lowestHP) then
						lowest = entity
						lowestHP = entity.hp.percent
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

function GetLowestMPParty( range, role, includeself )
    local pID = Player.id
	local lowest = nil
	local lowestMP = 101
	local includeself = IsNull(includeself,"0") 
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
		--[FFXIV.JOBS.GUNBREAKER] = true, not sure yet
		--[FFXIV.JOBS.DANCER] = true, not sure yet
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
    if ( table.valid(el) ) then
		for i,entity in pairs(el) do
			if (mpUsers[entity.job] and entity.mp.percent < lowestMP) then
				lowest = entity
				lowestMP = entity.mp.percent
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
	local includeself = IsNull(includeself,"0") 
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
		--[FFXIV.JOBS.GUNBREAKER] = true, not sure yet
		--[FFXIV.JOBS.DANCER] = true, not sure yet
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
    if ( table.valid(el) ) then
        for i,entity in pairs(el) do
			if (entity.job and tpUsers[entity.job]) then
				if (entity.tp < lowestTP) then
					lowest = entity
					lowestTP = entity.tp
				end
			end
        end
    end
	
	if (includeself) then
		if (Player.alive and tpUsers[Player.job] and Player.tp < lowestTP) then
			lowest = Player
			lowestTP = Player.tp
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
	if ( table.valid(el) ) then
		for i,entity in pairs(el) do
			if (IsValidHealTarget(entity) and entity.hp.percent <= reqhp) then
				--d("[GetBestHealTarget]: "..tostring(entity.name).." is a valid target with ["..tostring(entity.hp.percent).."] HP %.")
				healables[i] = entity
			end
		end
	end
	
	if (npc) then
		--d("[GetBestHealTarget]: Checking non-players section.")
		local el = MEntityList("alive,targetable,maxdistance="..tostring(range))
		if ( table.valid(el) ) then
			for i,entity in pairs(el) do
				if (IsValidHealTarget(entity) and entity.hp.percent <= reqhp) then
					--d("[GetBestHealTarget]: "..tostring(entity.name).." is a valid target with ["..tostring(entity.hp.percent).."] HP %.")
					healables[i] = entity
				end
			end
		end
	end
	
	if (table.valid(healables)) then
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
		if (table.valid(e) and e.alive and e.attackable and e.los and e.distance <= 25 and HasBuffs(e, "179+180+189", 3, Player.id)) then
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
		if (table.valid(e) and e.alive and e.attackable and e.los and e.distance <= 25 and MissingBuffs(e, "179,180,189", 3, Player.id)) then
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
    if ( table.valid(el) ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
    
    local el = MEntityList("nearest,friendly,chartype=4,targetable,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
	--local el = MEntityList("nearest,friendly,chartype=4,exclude="..tostring(pID)..",maxdistance="..tostring(ml_global_information.AttackRange))
    if ( table.valid(el) ) then
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
	if (table.valid(el)) then
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
		if(not table.valid(enemyParty)) then
			enemyParty = MEntityList("lowesthealth,onmesh,attackable,targetingme,alive,chartype=4,maxdistance=25")
		end
		if(not table.valid(enemyParty)) then
			enemyParty = MEntityList("lowesthealth,onmesh,attackable,alive,chartype=4,maxdistance=15")
		end
		if(not table.valid(enemyParty)) then
			enemyParty = MEntityList("lowesthealth,onmesh,attackable,alive,chartype=4,maxdistance=25")
		end
		if(not table.valid(enemyParty)) then
			enemyParty = MEntityList("lowesthealth,onmesh,attackable,alive,maxdistance=15")
		end
		if(not table.valid(enemyParty)) then
			enemyParty = MEntityList("lowesthealth,onmesh,attackable,alive,maxdistance=25")
		end
		if(not table.valid(enemyParty)) then
			enemyParty = MEntityList("shortestpath,onmesh,attackable,alive,chartype=4,maxdistance=45")
		end
		if(not table.valid(enemyParty)) then
			enemyParty = MEntityList("shortestpath,onmesh,attackable,alive,maxdistance=45")
		end
	else
		enemyParty = MEntityList("onmesh,attackable,alive,chartype=4")
	end
    if (table.valid(enemyParty)) then
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
						if (gPrioritizeRanged  and IsRangedDPS(entity.job)) then
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
				
				if targets[GetString("nearDead")] == entity and (entity.hp.percent > 30 or not entity.alive or entity.distance2d > 25) then
					targets[GetString("nearDead")] = nil
				end
				
				if entity.hp.percent < 30 and entity.pathdistance < 15 then
					targets[GetString("nearDead")] = entity
				end
					
				
				if targets[GetString("nearest")] == nil or targets[GetString("nearest")].distance2d > entity.distance2d then
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
	if (table.valid(el)) then
		
		local filteredList = {}
		for i,entity in pairs(el) do
			local epos = entity.pos
			if (NavigationManager:IsReachable(epos)) then
				if (not radius or (radius >= 150)) then
					table.insert(filteredList,entity)
				else
					local dist = Distance2D(pos.x,pos.z,epos.x,epos.z)
					if (dist <= radius) then
						table.insert(filteredList,entity)
					end
				end
			else
				local ppos = Player.pos
				d("[GetNearestFromList]- Entity at ["..tostring(math.round(epos.x,0))..","..tostring(math.round(epos.y,0))..","..tostring(math.round(epos.z,0)).."] not reachable from ["..tostring(math.round(ppos.x,0))..","..tostring(math.round(ppos.y,0))..","..tostring(math.round(ppos.z,0)).."] in Map "..tostring(Player.localmapid))
			end
		end
		
		if (table.valid(filteredList)) then
			table.sort(filteredList,function(a,b) return a.distance2d < b.distance2d end)
			for i,e in ipairs(filteredList) do
				if (i and e) then
					return e
				end
			end
		end
	end
	
	return nil
end
function GetNearestGatherable(marker)
    local el = nil
    local whitelist = ""
    local blacklist = ""
	local mincontentlevel = 1
	local maxcontentlevel = 70
	local radius = 0
	local markerPos = nil
	
	if (table.valid(marker)) then
		if (gMarkerMgrMode ~= GetString("singleMarker")) then	
			mincontentlevel = IsNull(marker.mincontentlevel,0)
			maxcontentlevel = IsNull(marker.maxcontentlevel,0)
		end
		
		local maxradius = marker.maxradius
		if (tonumber(maxradius) and tonumber(maxradius) > 0) then
			radius = tonumber(maxradius)
		end
		
		markerPos = marker:GetPosition()
		whitelist = tostring(marker.whitelist)
		blacklist = tostring(marker.blacklist)
	end
    
	if (radius == 0 or radius > 200 or not table.valid(markerPos)) then
		if (whitelist and whitelist ~= "") then
			el = MEntityList("shortestpath,onmesh,gatherable,targetable,minlevel="..tostring(mincontentlevel)..",maxlevel="..tostring(maxcontentlevel)..",contentid="..whitelist)
		elseif (blacklist and blacklist ~= "") then
			el = MEntityList("shortestpath,onmesh,gatherable,targetable,minlevel="..tostring(mincontentlevel)..",maxlevel="..tostring(maxcontentlevel)..",exclude_contentid="..blacklist)
		else
			el = MEntityList("shortestpath,onmesh,gatherable,targetable,minlevel="..tostring(mincontentlevel)..",maxlevel="..tostring(maxcontentlevel))
		end
		
		if ( table.valid(el) ) then
			local i,e = next(el)
			if (i~=nil and e~=nil) then
				return e
			end
		end
	elseif (table.valid(markerPos)) then
		if (whitelist and whitelist ~= "") then
			el = MEntityList("onmesh,gatherable,targetable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxcontentlevel)..",contentid="..whitelist)
		elseif (blacklist and blacklist ~= "") then
			el = MEntityList("onmesh,gatherable,targetable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxcontentlevel)..",exclude_contentid="..blacklist)
		else
			el = MEntityList("onmesh,gatherable,targetable,minlevel="..tostring(minlevel)..",maxlevel="..tostring(maxcontentlevel))
		end
		
		local gatherables = {}
		if (table.valid(el)) then
			for i,gatherable in pairs(el) do
				local gpos = gatherable.pos
				local dist = PDistance3D(markerPos.x,markerPos.y,markerPos.z,gpos.x,gpos.y,gpos.z)
				
				if (dist <= radius) then
					table.insert(gatherables,gatherable)
				end
			end
		end
		
		if (table.valid(gatherables)) then
			table.sort(gatherables,	function(a,b) return a.pathdistance < b.pathdistance end)
			for i,g in ipairs(gatherables) do
				if (i and g) then
					return g
				end
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
    local el = MEntityList("nearest,onmesh,gatherable,targetable,contentid="..tostring(contentID))
    
    if ( el ) then
        local i,e = next(el)
        if (i~=nil and e~=nil) then
            return e
        end
    end
	
    return nil
end
function GetNearestEvacPoint()
	local nearest, nearestDistance = nil, math.huge
	local evacPoints = ml_marker_mgr.GetMarkers("type=Evac,mapid="..tostring(Player.localmapid))
	if (table.valid(evacPoints)) then
		for id, evac in pairs(evacPoints) do
			local dist = math.distance3d(Player.pos,evac.pos)
			if (not nearest or (dist < nearestDistance)) then
				nearest, nearestDistance = evac, dist
			end
		end
	end
	return nearest
end
function AddEvacPoint(manual)
	local manual = IsNull(manual,false)
	
	local checkDistance = 30	
	if (manual) then
		checkDistance = 10
	end
	
	local canAdd = (manual or gGrindEvacAuto)
	local evacPoint = GetNearestEvacPoint()
	if (evacPoint) then
		local fpos = evacPoint.pos
		local ppos = Player.pos
		if (Distance3D(ppos.x, ppos.y, ppos.z, fpos.x, fpos.y, fpos.z) < checkDistance) then
			d("[AddEvacPoint]: Evac point was not added, there is already one very close.")
			canAdd = false
		end
	end
	
	if (not manual) then
		local el = EntityList("alive,attackable,aggressive,exclude_contentid=541,maxdistance=40")
		if (table.valid(el)) then
			d("[AddEvacPoint]: Evac point was not added, it does not appear to be a safe area.")
			canAdd = false
		end
	end
	
	if (canAdd) then
		ml_marker_mgr.AddEvacPoint()
	end
end
function HasBuff(targetid, buffID, stacks, duration, ownerid)
	local buffID = tonumber(buffID) or 0
	local stacks = tonumber(stacks) or 0
	local duration = tonumber(duration) or 0
	local ownerid = tonumber(ownerid) or 0
	
	local entity;
	if (type(targetid) == "number") then
		entity = MGetEntity(targetid)
	elseif (type(targetid) == "table") then
		entity = targetid
	end
	
	if (table.valid(entity)) then
		local buffs = entity.buffs
		if (table.valid(buffs)) then
			for i, buff in pairs(buffs) do
				if (buff.id == buffID) then
					if ((stacks == 0 or buff.stacks >= stacks) and
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
function HasBuffX(targetid, buffID, stacks, duration, ownerid)
	local buffID = tonumber(buffID) or 0
	local stacks = tonumber(stacks) or 0
	local duration = tonumber(duration) or 0
	local ownerid = tonumber(ownerid) or 0
	
	local entity;
	if (type(targetid) == "number") then
		entity = MGetEntity(targetid)
	elseif (type(targetid) == "table") then
		entity = targetid
	end
	
	if (table.valid(entity)) then
		local buffs = entity.buffs
		if (table.valid(buffs)) then
			for i, buff in pairs(buffs) do
				if (buff.id == buffID) then
					if ((stacks == 0 or stacks == buff.stacks) and
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
	local buffID = tonumber(buffID) or 0
	local stacks = tonumber(stacks) or 0
	local duration = tonumber(duration) or 0
	local ownerid = tonumber(ownerid) or 0
	
	local entity;
	if (type(targetid) == "number") then
		entity = MGetEntity(targetid)
	elseif (type(targetid) == "table") then
		entity = targetid
	end
	
	if (table.valid(entity)) then
		local buffs = entity.buffs
		if (table.valid(buffs)) then
			local missing = true
			for i, buff in pairs(buffs) do
				if (buff.id == buffID) then
					if ((stacks == 0 or buff.stacks >= stacks) and
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
function MissingBuffX(targetid, buffID, stacks, duration, ownerid)
	local buffID = tonumber(buffID) or 0
	local stacks = tonumber(stacks) or 0
	local duration = tonumber(duration) or 0
	local ownerid = tonumber(ownerid) or 0
	
	local entity;
	if (type(targetid) == "number") then
		entity = MGetEntity(targetid)
	elseif (type(targetid) == "table") then
		entity = targetid
	end
	
	if (table.valid(entity)) then
		local buffs = entity.buffs
		if (table.valid(buffs)) then
			local missing = true
			for i, buff in pairs(buffs) do
				if (buff.id == buffID) then
					if ((stacks == 0 or stacks == buff.stacks) and
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
	
	if (not table.valid(skills)) then return false end
	
	for _orids in StringSplit(skillids,",") do
		local found = false
		for _andid in StringSplit(_orids,"+") do
			found = false
			for i, skill in pairs(skills) do
				if (tonumber(skill.id) == tonumber(_andid) and (skill.used )) then 
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
function HasBuffs(entity, buffs, duration, ownerid, stacks)
	local duration = duration or 0
	local owner = ownerid or 0
	local stacks = stacks or 0
	local buffs = IsNull(tostring(buffs),"")
	
	if (table.valid(entity) and buffs ~= "") then
		local ebuffs = entity.buffs

		if (table.valid(ebuffs)) then
			for _orids in StringSplit(buffs,",") do
				local found = false
				for _andid in StringSplit(_orids,"+") do
					found = false
					for i, buff in pairs(ebuffs) do
						if (buff.id == tonumber(_andid) 
							and (stacks == 0 or stacks == buff.stacks)
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
function MissingBuffs(entity, buffs, duration, ownerid, stacks)
	local duration = duration or 0
	local owner = ownerid or 0
	local stacks = stacks or 0
	local buffs = IsNull(tostring(buffs),"")
	
	if (table.valid(entity) and buffs ~= "") then
		local ebuffs = entity.buffs
		
		if (table.valid(ebuffs)) then
			for _orids in StringSplit(buffs,",") do
				local missing = true
				for _andid in StringSplit(_orids,"+") do
					for i, buff in pairs(ebuffs) do
						if (buff.id == tonumber(_andid) 
							and (stacks == 0 or stacks == buff.stacks)
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
	if IsEurekaMap(Player.localmapid) then
		fleeHP = tonumber(gEurekaFleeHP) + (3 * attackingMobs)
	end
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
function HasContentID(entity, contentIDs) 	
	local cID = entity.contentid
	
	for _orids in StringSplit(contentIDs,",") do
		if (tonumber(_orids) == cID) then
			return true
		end
	end
	return false
end
function IsPetSummonSkill(skillID)
    if (skillID == 165 or
		skillID == 150 or
        skillID == 170 or
        skillID == 180 or
		skillID == 2864 or
		skillID == 2865) 
	then
        return true
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
		[7434] = true,
		[7445] = true,
		[8895] = true,
		[8896] = true,
		[8898] = true,
		[8902] = true,
		[8904] = true,
		[8905] = true,
		[8909] = true,
		[8913] = true,
		[8914] = true,
		[8916] = true,
		[10029] = true,
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
		[3611] = true,
		[3612] = true,
		[7432] = true,
		[8921] = true,
		[8922] = true,
		[8923] = true,
		[8924] = true,
		[9621] = true,
		[9651] = true,
	}
	
    if (buffs[id]) then
        return true
    end
	
	if (id >= 4401 and id <= 4424) then
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
	if (HasBuff(Player,1250)) then return true end
	local omnis = {
		[4954] = true,
		[4776] = true,
	}
	return omnis[entity.contentid]
end
function IsFlanking(entity,dorangecheck)
	if not entity or entity.id == Player.id then return false end
	local dorangecheck = IsNull(dorangecheck,true)
	
	if (HasBuff(Player,1250)) then return true end
	if (round(entity.pos.h,4) > round(math.pi,4) or round(entity.pos.h,4) < (-1 * round(math.pi,4))) then
		return true
	end
	
    if (entity.distance2d <= ml_global_information.AttackRange or not dorangecheck) then
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
	
	if (HasBuff(Player,1250)) then return true end
	if (round(entity.pos.h,4) > round(math.pi,4) or round(entity.pos.h,4) < (-1 * round(math.pi,4))) then
		return true
	end
	
    if (entity.distance2d <= ml_global_information.AttackRange or not dorangecheck) then
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
	if (round(entity.pos.h,4) > round(math.pi,4) or round(entity.pos.h,4) < (-1 * round(math.pi,4))) then
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
	
	if (HasBuff(Player,1250)) then return true end
	if (round(entity.pos.h,4) > round(math.pi,4) or round(entity.pos.h,4) < (-1 * round(math.pi,4))) then
		return true
	end
	
	if (entity.distance2d <= ml_global_information.AttackRange or not dorangecheck) then
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
	if (table.valid(fateList)) then
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
	if (table.valid(fatelist)) then
		for _,fate in pairs(fatelist) do
			local minFateLevel = 70
			local maxFateLevel = 2
			
			if gEnableAdvancedGrindSettings then
				minFateLevel = IsNull(tonumber(gGrindFatesMinLevel),0)
				maxFateLevel = IsNull(tonumber(gGrindFatesMaxLevel),0)
			end
			
			--local fatePos = {x = fate.x, y = fate.y, z = fate.z}
			
			local isChain,firstChain = ffxiv_task_fate.IsChain(Player.localmapid, fate.id)
			local isPrio = ffxiv_task_fate.IsHighPriority(Player.localmapid, fate.id)
			
			if ((gGrindFatesNoMinLevel or (fate.level >= (level - minFateLevel))) and 
				(gGrindFatesNoMaxLevel or (fate.level <= (level + maxFateLevel)))) 
			then
				if (not (isChain or isPrio) and (fate.type == 0 and gGrindDoBattleFates  and fate.completion >= tonumber(gFateBattleWaitPercent))) then
					table.insert(approvedFates,fate)
				elseif (not (isChain or isPrio) and (fate.type == 1 and gGrindDoBossFates  and fate.completion >= tonumber(gFateBossWaitPercent))) then
					table.insert(approvedFates,fate)
				elseif (not (isChain or isPrio) and (fate.type == 2 and gGrindDoGatherFates  and fate.completion >= tonumber(gFateGatherWaitPercent))) then
					table.insert(approvedFates,fate)
				elseif (not (isChain or isPrio) and (fate.type == 3 and gGrindDoDefenseFates  and fate.completion >= tonumber(gFateDefenseWaitPercent))) then
					table.insert(approvedFates,fate)
				elseif (not (isChain or isPrio) and (fate.type == 4 and gGrindDoEscortFates  and fate.completion >= tonumber(gFateEscortWaitPercent))) then
					table.insert(approvedFates,fate)
				elseif (not (isChain or isPrio) and (fate.type == -1 and fate.completion >= tonumber(gFateEscortWaitPercent))) then
					table.insert(approvedFates,fate)
				elseif ((isChain or isPrio) and gDoChainFates ) then
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
	if (table.valid(closestFate)) then
		local fatePos = {x = closestFate.x, y = closestFate.y, z = closestFate.z}
		local myPos = Player.pos
		local dist = Distance2D(myPos.x,myPos.z,fatePos.x,fatePos.z)
		if (dist < closestFate.radius) then
			return true
		end
	end
	
	return false
end
function GetClosestFate(pos)
	local fateList = GetApprovedFates()
	if (table.valid(fateList)) then	

		if (not gTeleportHack) then
			local ppos = Player.pos
			for i=TableSize(fateList),1,-1 do
				local fate = fateList[i]
				local fatePos = {x = fate.x, y = fate.y, z = fate.z}	

				if (not ml_navigation:CheckPath(fatePos)) then
					--d("[GetClosestFate] - Cannot find path to fate ["..tostring(fate.name).."] - From ["..tostring(math.round(ppos.x,0))..","..tostring(math.round(ppos.y,0))..","..tostring(math.round(ppos.z,0)).."] - To ["..tostring(math.round(fatePos.x,0))..","..tostring(math.round(fatePos.y,0))..","..tostring(math.round(fatePos.z,0)).."] - MapID ["..tostring(Player.localmapid) .."]")
					table.remove(fateList, i)
				end
			end
		end
		
		--d("Found some approved fates.")
        local nearestFate = nil
        local nearestDistance = 99999
        local level = Player.level
		local myPos = Player.pos
		
		local hasWhitelist = false
		local fateBlacklist = ml_list_mgr.GetList("FATE Blacklist")
		local fateWhitelist = ml_list_mgr.GetList("FATE Whitelist")
		if (table.valid(fateWhitelist)) then
			local entries = fateWhitelist.entries
			for i, entry in pairs(entries) do
				if (entry.mapid == Player.localmapid) then
					hasWhitelist = true
					break
				end
			end
		end
		
		local recheck = true
		local noPaths = {}
		
		while (recheck) do
			recheck = false
			if (hasWhitelist) then
				d("[GetClosestFate]: Player has a whitelist setup, need to follow it.")
				for k, fate in pairs(fateList) do
					local id,name,status,x,y,z = fate.id, fate.name, fate.status, fate.x, fate.y, fate.z
					if (fateWhitelist:Find(id,"id") ~= nil and status == 2 and not noPaths[fate.id]) then
						d("[GetClosestFate]: Fate ["..tostring(fate.name).."] is whitelisted and active.")
						local distance = PDistance3D(myPos.x,myPos.y,myPos.z,x,y,z)
						if (distance) then
							if (not nearestFate or (nearestFate and (distance < nearestDistance))) then
								nearestFate = fate
								nearestDistance = distance
							end
						end
					end
				end
			else
				local validFates = {}
				--Add fates that are high priority or chains first.
				for k, fate in pairs(fateList) do
					local id,name,status,x,y,z = fate.id, fate.name, fate.status, fate.x, fate.y, fate.z
					if (fateBlacklist:Find(id,"id") == nil and not noPaths[fate.id]) then
						local activatable = (table.valid(ffxiv_task_fate.Activateable(Player.localmapid, fate.id)))
						if (fate.status == 2) or ((fate.status == 7) and activatable) then	
							if (ffxiv_task_fate.IsHighPriority(Player.localmapid, fate.id) or ffxiv_task_fate.IsChain(Player.localmapid, fate.id)) then
								table.insert(validFates,fate)
							end
						end
					else
						--d("[GetClosestFate]: Fate ["..tostring(fate.name).."] is blacklisted, ignore it.")
					end
				end
				
				if (not table.valid(validFates)) then
					for k, fate in pairs(fateList) do
						local id,name,status,x,y,z = fate.id, fate.name, fate.status, fate.x, fate.y, fate.z
						if (fateBlacklist:Find(id,"id") == nil and not noPaths[fate.id]) then
							local activatable = (table.valid(ffxiv_task_fate.Activateable(Player.localmapid, fate.id)))
							if (fate.status == 2) or ((fate.status == 7) and activatable) then	
								table.insert(validFates,fate)
							end
						else
							--d("[GetClosestFate]: Fate ["..tostring(fate.name).."] is blacklisted, ignore it.")
						end
					end
				end
				
				if (table.valid(validFates)) then
					--d("Found some valid fates, figuring out which one is closest.")
					for k, fate in pairs(validFates) do
						local id,name,status,x,y,z = fate.id, fate.name, fate.status, fate.x, fate.y, fate.z
						local distance = PDistance3D(myPos.x,myPos.y,myPos.z,x,y,z) or -1
						--d("distance for ["..tostring(fate.name).."] is ["..tostring(distance).."]")
						if (distance ~= -1) then
							if (not nearestFate or (nearestFate and (distance < nearestDistance))) then
								nearestFate = fate
								nearestDistance = distance
							end
						end
					end
				end
			end
			
			if (nearestFate) then
				--d("we have a nearest fate")
				if (not ml_navigation:CheckPath(nearestFate)) then
					if (table.size(validFates) > 1) then
						recheck = true
						noPaths[nearestFate.id] = true
					end
					nearestFate = nil
					nearestDistance = 99999
				end
			end
		end
    
        if (nearestFate) then
			--d("[GetClosestFate] - Nearest Fate details: Name="..nearestFate.name..",id="..tostring(nearestFate.id)..",completion="..tostring(nearestFate.completion)..",pos="..tostring(nearestFate.x)..","..tostring(nearestFate.y)..","..tostring(nearestFate.z))
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
	local maxdistance = tonumber(distance) or 150
	local el = MEntityList("nearest,targetable,alive,contentid="..ids..",maxdistance2d="..tostring(maxdistance))
	if (table.valid(el)) then
		local i,e = next(el)
		if (i and e) then
			return true
		end
	end

	return false
end
function ScanForLocation(ids,distance,spells)
	local ids = (type(ids) == "string" and ids) or tostring(ids)
	local maxdistance = tonumber(distance) or 150
	local caster = false
	local closest = nil
	local closestdist = 99999999
	local el = MEntityList("contentid="..ids..",maxdistance2d="..tostring(maxdistance))
	if (table.valid(el)) then
		for i,e in pairs(el) do
			if (e and e.castinginfo) then
				if (not spells or (spells and (MultiComp(e.castinginfo.channelingid,spells)))) then
					if (e.distance < closestdist) then
						closestdist = e.distance
						caster = true
						closest = e
					end
				end
			end
		end
	end
	return caster, closest
end
function ScanForCaster(ids,distance,spells,includeself)
	local includeself = IsNull(includeself,false)
	local ids = (type(ids) == "string" and ids) or tostring(ids) or ""
	local spells = (type(spells) == "string" and spells) or tostring(spells)
	
	local maxdistance = tonumber(distance) or 150
	local el;
	if (string.valid(ids)) then
		el = MEntityList("contentid="..ids..",maxdistance2d="..tostring(maxdistance))
	else
		el = MEntityList("maxdistance2d="..tostring(maxdistance))
	end
	if (table.valid(el)) then
		for i,e in pairs(el) do
			if (e and e.castinginfo) then
				if (MultiComp(e.castinginfo.channelingid,spells)) then
					local hits = {}
					local hit = EntityList:Get(e.castinginfo.channeltargetid)
					if (table.valid(hit)) then
						hits[hit.id] = hit
					end
					return true, e, hits
				elseif (MultiComp(e.castinginfo.castingid,spells)) then
					local hits = {}
					local targets = e.castinginfo.castingtargets
					if (table.valid(targets)) then
						for i,target in pairs(targets) do
							local entity = EntityList:Get(target)
							if (table.valid(entity)) then
								hits[entity.id] = entity
							end							
						end
					else
						local hit = EntityList:Get(e.castinginfo.channeltargetid)
						if (table.valid(hit)) then
							hits[hit.id] = hit
						end
					end
					return true, e, hits
				end
			end
		end
	end
	
	if (MultiComp(Player.castinginfo.channelingid,spells)) then
		local hits = {}
		local hit = EntityList:Get(Player.castinginfo.channeltargetid)
		if (table.valid(hit)) then
			hits[hit.id] = hit
		end
		return true, Player, hits
	elseif (MultiComp(Player.castinginfo.castingid,spells)) then
		local hits = {}
		local targets = Player.castinginfo.castingtargets
		if (table.valid(targets)) then
			for i,target in pairs(targets) do
				local entity = EntityList:Get(target)
				if (table.valid(entity)) then
					hits[entity.id] = entity
				end							
			end
		else
			local hit = EntityList:Get(Player.castinginfo.channeltargetid)
			if (table.valid(hit)) then
				hits[hit.id] = hit
			end
		end
		return true, Player, hits
	end
	
	return false, nil, nil
end
function ScanForObjects(ids,distance)
	local ids = (type(ids) == "string" and ids) or tostring(ids)
	local maxdistance = tonumber(distance) or 150
	local el = MEntityList("nearest,targetable,contentid="..ids..",maxdistance2d="..tostring(maxdistance))
	if (table.valid(el)) then
		local i,e = next(el)
		if (i and e) then
			return true
		end
	end
	
	return false
end
function ScanForEntity(ids,distance,buffids)
	local ids = (type(ids) == "string" and ids) or tostring(ids)
	local maxdistance = tonumber(distance) or 150
	local buffids = (type(buffids) == "string" and buffids) or tostring(buffids)
	
	local el = MEntityList("contentid="..ids..",maxdistance2d="..tostring(maxdistance))
	if (table.valid(el)) then
		local i,entity = next(el)
		if (i and entity) then
			if (buffids == "" or HasBuffs(entity,buffids)) then
				return true
			end
		end
	end
	
	return false
end
function CanUseCannon()
	if (MIsLocked()) then
		local misc = ActionList(1)
		if (table.valid(misc)) then
			local cannons = { 1134, 1437, 2630, 1128, 2434 }
			for _,cannonid in pairs(cannons) do
				if (misc[cannonid] ~= nil and misc[cannonid]:IsReady(Player.id)) then
					return true
				end
			end
		end
	end
	return false
end
function GetPathDistance(pos1,pos2,threshold)
	assert(pos1 and pos1.x and pos1.y and pos1.z,"First argument to GetPathDistance is invalid.")
	assert(pos2 and pos2.x and pos2.y and pos2.z,"Second argument to GetPathDistance is invalid.")
	local threshold = IsNull(threshold,100)
	
	local dist = math.distance3d(pos1,pos2)
	if (dist < threshold) then
		--local path = NavigationManager:MoveTo(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z) -- this does something else in addition to path
		local path = NavigationManager:GetPath(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z)
		if (table.valid(path)) then
			local pathdist = PathDistance(path)
			if (table.valid(pathdist)) then
				dist = pathdist
			end
		end
	end
	
	return dist
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
	assert(table.valid(pos1),"First argument is not a valid position.")
	assert(table.valid(pos2),"Second argument is not a valid position.")
	
	local points = {}
	local path = ffnav.currentPath
	if (table.valid(path)) then
		local x = 1
		local prevPos = pos1
		
		for i,pos in pairsByKeys(path) do
			--Add the previous points list.
			points[x] = prevPos
			x = x + 1
			
			local dist = PDistance3D(prevPos.x,prevPos.y,prevPos.z,pos.x,pos.y,pos.z)
			if (dist > 5) then
				local minipoints = GetLinePoints(prevPos,pos,5)
				if (table.valid(minipoints)) then
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
	if (gBotMode == GetString("partyMode") and not gPartyGrindUsePartyLeader) then
		if (gPartyLeaderName ~= "") then
			local el = MEntityList("type=1,name="..gPartyLeaderName)
			if (table.valid(el)) then
				local i,leaderentity = next (el)
				if (i and leaderentity) then
					return leaderentity, true
				end
			end
			
			local party = EntityList.myparty
			if (table.valid(party)) then
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
		if (table.valid(party)) then
			for i,member in pairs(party) do
				if member.isleader then
					leader = member
					isEntity = false
				end
			end
		end
		
		if (leader) then
			local el = MEntityList("type=1,name="..leader.name)
			if (table.valid(el)) then
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
function IsPartyLeader()
	local partyLeader = GetPartyLeader()
	if (partyLeader) then
		return partyLeader.name == Player.name
	end
	
	return false
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
	if (table.valid(party)) then
		for i, member in pairs(party) do
			if member.id == id then
				return true
			end
		end
	end
	return false
end
function InCombatRange(targetid)
	if (not FFXIV_Common_BotRunning or IsFlying()) then
		return false
	end
	
	local target;
	if (type(targetid) == "table") then
		local id = targetid.id
		target = MGetEntity(id)
		if (not target or not table.valid(target)) then
			return false
		end
	else
		target = MGetEntity(targetid)
		if (not target or not table.valid(target)) then
			return false
		end
	end
	local targetid = target.id
	
	--If we're in duty, consider the player always in-range, should be handled by the profile.
	--d(ml_task_queue.rootTask)
	if (gBotMode == GetString("dutyMode")) then
		return true
	elseif (gBotMode == GetString("gatherMode")) then
		local node = EntityList:Get(targetid)
		if (node and node.distance2d ~= 0 and node.distance2d < 4) then
			return true
		end
		return false
	end
	
	--If we're casting on the target, consider the player in-range, so that it doesn't attempt to move and interrupt the cast.
	if (Player.castinginfo.channelingid ~= 0 and Player.castinginfo.channeltargetid == targetid) then
		return true
	end
	
	local attackRange = ml_global_information.AttackRange	
	if (target.distance2d ~= 0 and target.distance2d <= (attackRange * .97)) then
		local check = SkillMgr.CheckTestSkill(Player.job, target)
		if (check ~= nil) then
			return check
		end
		
		return target.los
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
			action = ActionList:Get(stype,skillid)
		else
			testSkill = SkillMgr.GCDSkills[Player.job]
			action = ActionList:Get(1,testSkill)
		end
		
		if (action) then
			if (action:IsReady(target.id) or (action.range >= target.distance2d)) then
				return true
			end
		end
	end
		
	return false
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
	if GetUIPermission(98) == 0 then
		return true
	end
	return false
end
function IsLoading()
	if (IsControlOpen("FadeMiddle") or IsControlOpen("NowLoading")) then
		--d("IsLoading [1] - Loading screen open.")
		return true
	elseif (Player.localmapid == 0) then
		--d("IsLoading [2] - In a transitional map state (mapid 0).")
		return true
	elseif (HasBuff(Player.id,1937)) then
		--d("IsLoading [3] - In event.")
		return true
	else
		local meshState = NavigationManager:GetNavMeshState()
		if (In(meshState,GLOBAL.MESHSTATE.MESHLOADING,GLOBAL.MESHSTATE.MESHSAVING,GLOBAL.MESHSTATE.MESHBUILDING)) then
			--d("IsLoading [4]: MESHSTATE ["..tostring(meshState).."]")
			return true
		end
	end
	
	return false
end
function HasAction(id, category)
	local id = tonumber(id) or 0
	local category = category or 1
	
	if (id ~= 0) then
		local action = ActionList:Get(category,id)
		if (table.valid(action)) then
			return true
		end
		return false
	end
	return false			
end
function ActionIsReady(id, category)
	if (MIsLoading() or not ActionList:IsReady()) then
		return false
	end

	local id = tonumber(id) or 0
	local category = category or 1
	
	local action = ActionList:Get(category,id)
	if (table.valid(action)) then
		if (action:IsReady(Player.id)) then
			return true
		end
	end
	return false
end
function Mount(id)
	local mountID = id or 0
	local patchLevel = GetPatchLevel()
	
	if (IsMounted() or IsMounting()) then
		ml_debug("Cannot mount while mounted or mounting.")
		return
	end
	
	local mounts = ActionList:Get(13)
	if (table.valid(mounts)) then
		if (mountID == 0) then
			if (table.valid(mounts)) then
				--First pass, look for our named mount.
				for mountid,mountaction in pairsByKeys(mounts) do
					if (mountaction.name == gMountName and ((mountaction.canfly and (mountid > 1 or QuestCompleted(2117))) or (patchLevel >= 5.3 and QuestCompleted(524)) or not CanFlyInZone())) then
						if (mountaction:IsReady(Player.id)) then
							mountaction:Cast()
							return true
						end
					end
				end	
			end
		else
			for mountid,mountaction in pairsByKeys(mounts) do
				if (mountid == mountID and ((mountaction.canfly and (mountid > 1 or QuestCompleted(2117))) or (patchLevel >= 5.3 and QuestCompleted(524)) or not CanFlyInZone())) then
					if (mountaction:IsReady()) then
						mountaction:Cast()
						return true
					end
				end
			end
		end
		
		--Second pass, look for any mount as backup.
		for mountid,mountaction in pairsByKeys(mounts) do
			if (mountaction:IsReady(Player.id) and ((mountaction.canfly and (mountid > 1 or QuestCompleted(2117))) or (patchLevel >= 5.3 and QuestCompleted(524)) or not CanFlyInZone())) then
				mountaction:Cast()
				return true
			end
		end	
	end
	
	return false
end
function Dismount()
	if (Player.ismounted) then
		local dismount = ActionList:Get(13,Player.mountid)
		local dismountMain = ActionList:Get(5,23)
		if (dismount and dismount:IsReady(Player.id)) then
			d("[Dismount]: Used primary method.")
			dismount:Cast(Player.id)
			if (IsFlying()) then
				Descend()
			end
		elseif (dismountMain and dismountMain:IsReady(Player.id)) then
			d("[Dismount]: Used secondary method.")
			dismountMain:Cast(Player.id)
			if (IsFlying()) then
				Descend()
			end
		else
			d("[Dismount]: Used backup method.")
			SendTextCommand("/mount")
			if (IsFlying()) then
				Descend()
			end
		end
	end
	
	--[[
	if (Player.ismounted and (not isflying or (isflying and not Player:IsMoving()))) then
		local dismount = ActionList:Get(5,23)
		if (dismount and dismount:IsReady(Player.id)) then
			dismount:Cast(Player.id)
		else
			SendTextCommand("/mount")
		end
	end
	--]]
end
function Repair()
	if (gRepair) then
		local bag = Inventory:Get(1000)
		if (table.valid(bag)) then
			local ilist = bag:GetList()
			if (table.valid(ilist)) then
				for slot,item in pairs(ilist) do
					item:Repair()
				end
			end
		end
	end
end
function NeedsRepair()
	if (gRepair and GetPatchLevel() < 5.4) then
		local bag = Inventory:Get(1000)
		if (table.valid(bag)) then
			local ilist = bag:GetList()
			if (table.valid(ilist)) then
				for slot,item in pairs(ilist) do
					if (item.condition <= 50) then
						return true
					end
				end
			end
		end
	end
	return false
end
function ShouldEat()
	if (gFood ~= GetString("none")) then
		local foodEntry = ml_global_information.foods[gFood]
		if (foodEntry) then
			local foodID = foodEntry.id
			local foodStack = foodEntry.buffstackid
			--d("[ShouldEat]: Looking for foodID ["..tostring(foodID).."].")
			local food, action = GetItem(foodID)
			if (food and action and not action.isoncd and (MissingBuff(Player,48,0,60) or (gFoodSpecific and MissingBuffX(Player,48,foodStack,60)))) then
				return true
			end
		end
	end
	return false
end
function Eat()
	if (gFood ~= GetString("none")) then
		local foodEntry = ml_global_information.foods[gFood]
		if (foodEntry) then
			local foodID = foodEntry.id
			local foodStack = foodEntry.buffstackid
			--d("[Eat]: Looking for foodID ["..tostring(foodID).."].")
			local food, action = GetItem(foodID)
			if (food and action and food:IsReady(Player.id) and (MissingBuff(Player,48,0,60) or (gFoodSpecific and MissingBuffX(Player,48,foodStack,60)))) then
				food:Cast(Player.id)
				local castid = action.id
				ml_global_information.Await(5000, function () return Player.castinginfo.lastcastid == castid end)
			end
		end
	end
end
function NodeHasItem(searchItem)
	if (searchItem and type(searchItem) == "string" and searchItem ~= "") then
		for itemName in StringSplit(searchItem,",") do
			local list = MGatherableSlotList()
			if (table.valid(list)) then
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
		
		if (table.valid(ml_marker_mgr.currentEditMarker)) then
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
		
		if (table.valid(ml_marker_mgr.currentEditMarker)) then
			ml_marker_mgr.currentEditMarker:SetFieldValue(key, _G["Field_"..key])
			ml_marker_mgr.WriteMarkerFile()
		end
	end
end
function IsMap(itemid)
	local itemid = tonumber(itemid) or 0
	return ((itemid >= 6687 and itemid <= 6692) or
		(itemid == 7884 or itemid == 8156 or itemid == 9900) or
		(itemid >= 12241 and itemid <= 12243) or
		(itemid >= 17835 and itemid <= 17836) or 
		In(itemid,19770,24794,26744,26745))
end
function IsGardening(itemid)
	local itemid = tonumber(itemid) or 0
	return ((itemid >= 7715 and itemid <= 7767) 
			or (itemid >= 7029 and itemid <= 7031)
			or itemid == 8024
			or itemid == 5365
			or itemid == 7034
			or itemid == 12650
			or itemid == 12656
			or itemid == 12887
			or (itemid >= 15865 and itemid <= 15870)
			)
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
	local contid = IsNull(contentid,0)
	if (type(contentid) == "table") then
		contid = contentid.contentid
	end
	return (contid >= 5 and contid <= 8)
end
function IsEphemeral(contentid)
	local contid = IsNull(contentid,0)
	if (type(contentid) == "table") then
		contid = contentid.contentid
	end
	return (contid >= 9 and contid <= 12)
end
function IsLegendary(contentid)
	local contid = IsNull(contentid,0)
	if (type(contentid) == "table") then
		contid = contentid.contentid
	end
	return (contid >= 13 and contid <= 16)
end
function IsConcealed(contentid)
	local contid = IsNull(contentid,0)
	if (type(contentid) == "table") then
		contid = contentid.contentid
	end
	return (contid >= 17 and contid <= 20)
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
		jobID == FFXIV.JOBS.DANCER or
        jobID == FFXIV.JOBS.DRAGOON or
        jobID == FFXIV.JOBS.LANCER or
        jobID == FFXIV.JOBS.MONK or
        jobID == FFXIV.JOBS.PUGILIST or
        jobID == FFXIV.JOBS.SUMMONER or
        jobID == FFXIV.JOBS.THAUMATURGE or
		jobID == FFXIV.JOBS.ROGUE or
		jobID == FFXIV.JOBS.NINJA or
		jobID == FFXIV.JOBS.MACHINIST or
		jobID == FFXIV.JOBS.SAMURAI or
		jobID == FFXIV.JOBS.REDMAGE or
		jobID == FFXIV.JOBS.BLUEMAGE
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
		jobID == FFXIV.JOBS.DARKKNIGHT or 
		jobID == FFXIV.JOBS.GUNBREAKER
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
			[FFXIV.JOBS.DANCER] = true,
			[FFXIV.JOBS.DRAGOON] = true,
			[FFXIV.JOBS.LANCER] = true,
			[FFXIV.JOBS.MONK] = true,
			[FFXIV.JOBS.PUGILIST] = true,
			[FFXIV.JOBS.ROGUE] = true,
			[FFXIV.JOBS.NINJA] = true,
			[FFXIV.JOBS.MACHINIST] = true,
			[FFXIV.JOBS.SAMURAI] = true,
			[FFXIV.JOBS.REDMAGE] = true,
			[FFXIV.JOBS.BLUEMAGE] = true,
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
			[FFXIV.JOBS.GUNBREAKER] = true,
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
			[FFXIV.JOBS.REDMAGE] = true,
			[FFXIV.JOBS.BLUEMAGE] = true,
		}
	elseif (rolestring == "MeleeDPS") then
      		return {
  			[FFXIV.JOBS.DRAGOON] = true,
			[FFXIV.JOBS.LANCER] = true,
			[FFXIV.JOBS.MONK] = true,
			[FFXIV.JOBS.PUGILIST] = true,
  			[FFXIV.JOBS.ROGUE] = true,
			[FFXIV.JOBS.NINJA] = true,
         		[FFXIV.JOBS.SAMURAI] = true,
		}
	elseif (rolestring == "RangeDPS") then
		return {
			[FFXIV.JOBS.ARCHER] = true,
			[FFXIV.JOBS.BARD] = true,
			[FFXIV.JOBS.BLACKMAGE] = true,
			[FFXIV.JOBS.DANCER] = true,
			[FFXIV.JOBS.MACHINIST] = true,
			[FFXIV.JOBS.ARCANIST] = true,
			[FFXIV.JOBS.BLACKMAGE] = true,
			[FFXIV.JOBS.SUMMONER] = true,
			[FFXIV.JOBS.THAUMATURGE] = true,
			[FFXIV.JOBS.REDMAGE] = true,
		}
	end
	return nil
end
function IsMeleeDPS(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
	elseif (type(var) == "number") then
		jobid = var
	end
	
	return 	(jobid == FFXIV.JOBS.MONK or
			jobid == FFXIV.JOBS.PUGILIST or
			jobid == FFXIV.JOBS.DRAGOON or
			jobid == FFXIV.JOBS.LANCER or
			jobid == FFXIV.JOBS.ROGUE or
			jobid == FFXIV.JOBS.NINJA or 
			jobid == FFXIV.JOBS.SAMURAI)
end
function IsRangedDPS(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
	elseif (type(var) == "number") then
		jobid = var
	end
	
	return 	(jobid == FFXIV.JOBS.ARCANIST or
			jobid == FFXIV.JOBS.ARCHER or
			jobid == FFXIV.JOBS.BARD or
			jobid == FFXIV.JOBS.BLACKMAGE or
			jobid == FFXIV.JOBS.DANCER or
			jobid == FFXIV.JOBS.SUMMONER or
			jobid == FFXIV.JOBS.THAUMATURGE or
			jobid == FFXIV.JOBS.MACHINIST or 
			jobid == FFXIV.JOBS.REDMAGE or
			jobid == FFXIV.JOBS.BLUEMAGE)
end
function IsRanged(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
	elseif (type(var) == "number") then
		jobid = var
	end
	
	return 	(jobid == FFXIV.JOBS.ARCANIST or
			jobid == FFXIV.JOBS.ARCHER or
			jobid == FFXIV.JOBS.BARD or
			jobid == FFXIV.JOBS.DANCER or
			jobid == FFXIV.JOBS.BLACKMAGE or
			jobid == FFXIV.JOBS.SUMMONER or
			jobid == FFXIV.JOBS.THAUMATURGE or
			jobid == FFXIV.JOBS.CONJURER or
			jobid == FFXIV.JOBS.SCHOLAR or
			jobid == FFXIV.JOBS.WHITEMAGE or
			jobid == FFXIV.JOBS.ASTROLOGIAN or
			jobid == FFXIV.JOBS.MACHINIST or
			jobid == FFXIV.JOBS.REDMAGE or
			jobid == FFXIV.JOBS.BLUEMAGE)
end
function IsPhysicalDPS(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
	elseif (type(var) == "number") then
		jobid = var
	end

	return 	(jobid == FFXIV.JOBS.MONK or
			jobid == FFXIV.JOBS.PUGILIST or
			jobid == FFXIV.JOBS.DRAGOON or
			jobid == FFXIV.JOBS.LANCER or
			jobid == FFXIV.JOBS.ROGUE or
			jobid == FFXIV.JOBS.NINJA or 
			jobid == FFXIV.JOBS.ARCHER or
			jobid == FFXIV.JOBS.SAMURAI or
			jobid == FFXIV.JOBS.BARD or
			jobid == FFXIV.JOBS.DANCER or
			jobid == FFXIV.JOBS.MACHINIST)
end
function IsCasterDPS(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
	elseif (type(var) == "number") then
		jobid = var
	end

	return 	(jobid == FFXIV.JOBS.ARCANIST or
			jobid == FFXIV.JOBS.BLACKMAGE or
			jobid == FFXIV.JOBS.SUMMONER or
			jobid == FFXIV.JOBS.THAUMATURGE or
			jobid == FFXIV.JOBS.REDMAGE or 
			jobid == FFXIV.JOBS.BLUEMAGE)
end
function IsCaster(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
	elseif (type(var) == "number") then
		jobid = var
	end

	return 	(jobid == FFXIV.JOBS.ARCANIST or
			jobid == FFXIV.JOBS.BLACKMAGE or
			jobid == FFXIV.JOBS.SUMMONER or
			jobid == FFXIV.JOBS.THAUMATURGE or
			jobid == FFXIV.JOBS.WHITEMAGE or
			jobid == FFXIV.JOBS.CONJURER or
			jobid == FFXIV.JOBS.SCHOLAR or 
			jobid == FFXIV.JOBS.ASTROLOGIAN or
			jobid == FFXIV.JOBS.REDMAGE or
			jobid == FFXIV.JOBS.BLUEMAGE)
end
function IsHealer(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
	elseif (type(var) == "number") then
		jobid = var
	end

	return 	(jobid == FFXIV.JOBS.WHITEMAGE or
			jobid == FFXIV.JOBS.CONJURER or
			jobid == FFXIV.JOBS.SCHOLAR or 
			jobid == FFXIV.JOBS.ASTROLOGIAN)
end
function IsTank(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
	elseif (type(var) == "number") then
		jobid = var
	end
	
	return (jobid == FFXIV.JOBS.GLADIATOR or
		jobid == FFXIV.JOBS.MARAUDER or
		jobid == FFXIV.JOBS.PALADIN or
		jobid == FFXIV.JOBS.WARRIOR or
		jobid == FFXIV.JOBS.GUNBREAKER or
		jobid == FFXIV.JOBS.DARKKNIGHT)
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
	if ((jobID >= 0 and jobID <= 7) or
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
	
	local el = MEntityList("myparty,alive,targetable,chartype=4,maxdistance2d="..tostring(maxdistance))
	--local el = MEntityList("myparty,alive,chartype=4,maxdistance="..tostring(maxdistance))
	if (table.valid(el)) then
		for i,entity in pairs(el) do	
			if ((hasbuffs=="" or HasBuffs(entity,hasbuffs)) and (hasnot=="" or MissingBuffs(entity,hasnot))) then
				return entity
			end
		end
	end
	
	return nil
end
function PartySMemberWithBuff(hasbuffs, hasnot, maxdistance) 
	maxdistance = maxdistance or 30
 
	local el = MEntityList("myparty,alive,targetable,chartype=4,maxdistance="..tostring(maxdistance))
	--local el = MEntityList("myparty,alive,chartype=4,maxdistance="..tostring(maxdistance))
	if (table.valid(el)) then
		for i,entity in pairs(el) do	
			if ((hasbuffs=="" or HasBuffs(entity,hasbuffs)) and (hasnot=="" or MissingBuffs(entity,hasnot))) then
				return entity
			end
		end
	end

	if ((hasbuffs=="" or HasBuffs(Player,hasbuffs)) and (hasnot=="" or MissingBuffs(Player,hasnot))) then
        return Player
    end
	
	return nil
end

function MembersWithBuffs(hasbuffs, hasnot, maxdistance, includeself) 
	local hasbuffs = IsNull(hasbuffs,"")
	local hasnot = IsNull(hasnot,"")
	local maxdistance = IsNull(maxdistance,30)
	local includeself = IsNull(includeself,true)
	local returnables = {}
	
	if (hasbuffs ~= "" or hasnot ~= "") then
		local el = MEntityList("myparty,alive,targetable,chartype=4,maxdistance2d="..tostring(maxdistance))
		if (ValidTable(el)) then
			for i,e in pairs(el) do	
				if ((hasbuffs=="" or ((table.isa(hasbuffs) and HasBuffs{ entity = e, buffs = hasbuffs.buffs, duration = hasbuffs.duration, ownerid = hasbuffs.ownerid, stacks = hasbuffs.stacks}) or (type(hasbuffs) == "string" and HasBuffs(e,hasbuffs)))) and 
					(hasnot=="" or ((table.isa(hasnot) and MissingBuffs{ entity = e, buffs = hasnot.buffs, duration = hasnot.duration, ownerid = hasnot.ownerid, stacks = hasnot.stacks}) or (type(hasnot) == "string" and MissingBuffs(e,hasnot)))))
				then
					table.insert(returnables,e)
				end						
			end
		end

		if (includeself) then
			if ((hasbuffs=="" or ((table.isa(hasbuffs) and HasBuffs{ entity = Player, buffs = hasbuffs.buffs, duration = hasbuffs.duration, ownerid = hasbuffs.ownerid, stacks = hasbuffs.stacks}) or (type(hasbuffs) == "string" and HasBuffs(Player,hasbuffs)))) and 
				(hasnot=="" or ((table.isa(hasnot) and MissingBuffs{ entity = Player, buffs = hasnot.buffs, duration = hasnot.duration, ownerid = hasnot.ownerid, stacks = hasnot.stacks}) or (type(hasnot) == "string" and MissingBuffs(Player,hasnot)))))
			then
				table.insert(returnables,Player)
			end
		end
	end
	
	return returnables
end

ml_global_information.lastAetheryteCache = 0
function GetAetheryteList(force)
	
	--return Player:GetAetheryteList()
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
	if (table.valid(apiList)) then
		local aethData = {}
		for i,aetheryte in pairs(apiList) do
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
	if (table.valid(list)) then
		for index,aetheryte in pairs(list) do
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
	if (table.valid(list)) then
		for id,aetheryte in pairs(list) do
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
	
	if (table.valid(aethList)) then
		local list = ml_global_information.Player_Aetherytes
		if (table.valid(list)) then
			for id,aetheryte in pairs(list) do
				if (aetheryte.isattuned and aethList[aetheryte.id]) then
					aethList[aetheryte.id] = nil
				end
			end
		end
	end
	
	return aethList
end

function GetUnattunedCurrents()
	local currentList = {}
	if not QuestCompleted(1597) then
		return nil
	end
	for map,currentdata in pairs(ffxiv_aethercurrent_data) do
		for j,current in pairs(currentdata) do
			local valid = true
			local validmap = true
			local attuned = false
			local requirement = current.requires
			
			if map ~= Player.localmapid then
				validmap = false 
			end
			
			if (requirement ~= nil and type(requirement) == "function") then
				valid = IsNull(requirement(),false)
			end
			
			if GetAetherCurrentData(Player.localmapid)[current.id] == true then
				attuned = true
			end
			
			if (valid) and (validmap) and (not attuned) then
				currentList[current.aethid] = current
			end
		end
	end
	
	return currentList
end

function GetHomepoint()
	local homepoint = 0
	
	local attuned = GetAttunedAetheryteList(true)
	if (table.valid(attuned)) then
		for id,aetheryte in pairs(attuned) do
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
	if (table.valid(list)) then
		for index,aetheryte in pairs(list) do
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
	if (table.valid(aethData)) then
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
	elseif (In(mapid,177) and not In(myMap,177,128,129)) then
		mapid = 129
	elseif (In(mapid,178) and not In(myMap,178,130,131)) then
		mapid = 130
	elseif (In(mapid,179) and not In(myMap,179,132,133)) then
		mapid = 132
	elseif (In(mapid,629,628) and not In(myMap,629,628)) then
		mapid = 628
	elseif (In(mapid,843,819) and not In(myMap,843,819)) then
		mapid = 819
	end
	
	if 	(myMap == 131 and mapid == 130) or
		(myMap == 128 and mapid == 129) or
		(myMap == 133 and mapid == 133) or
		(myMap == 418 and (mapid == 419 or mapid == 439 or mapid == 427 or mapid == 456 or mapid == 433)) or
		(myMap == 399 and mapid == 478)
	then
		return nil
	end
	if (mapid == 639 and myMap ~= 628) then
		mapid = 628
	end
	if myMap == 813 and (HasQuest(3609) or (QuestCompleted(3609) and not CanUseAetheryte(141))) then
		return nil
	end
	if (mapid == 815 and GetAhmAraengSection(pos) == 1) and (HasQuest(3609) or (QuestCompleted(3609) and not CanUseAetheryte(141))) then
		mapid = 813
	end
	if ((myMap == 614 and GetYanxiaSection(Player.pos) == 2) or (myMap == 622)) and HasQuest(2518) then
		return nil
	end
	if (((mapid == 614 and GetYanxiaSection(pos) == 2) or (myMap == 614 and GetYanxiaSection(Player.pos) == 1)) and HasQuest(2518)) then
		mapid = 622
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
					if In(GetELNSection(pos),1,3) then
						return true
					end
					return false
				end	
			},
			[2] = { name = "Wineport", aethid = 12, x = 0, z = 0, 
				best = function ()  
					if In(GetELNSection(pos),2) then
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
					if In(GetSeaOfCloudsSection(pos),2) then
						return true
					end
					return false
				end				
			},
			[2] = { name = "OkZundu", aethid = 73, x = -606, z = -419,
				best = function ()  
					if In(GetSeaOfCloudsSection(pos),1) then
						return true
					end
					return false
				end				
			},
		},
		[398] = {name = "The Dravanian Forelands",
            [1] = { name = "Tailfeather", aethid = 76, x = 531.49, z = 20.57, 
                best = function ()  
					if In(GetForelandsSection(pos),1) then
                        return true
                    end
                    return false
                end                
            },
            [2] = { name = "Anyx Trine", aethid = 77, x = -301.09, z = 38.07,
                best = function ()  
					if In(GetForelandsSection(pos),2) then
                        return true
                    end
                    return false
                end                
            },
        },
		[400] = {name = "Churning Mists",
			[1] = { name = "Moghome", aethid = 78, x = 256, z = 599 },
			[2] = { name = "Zenith", aethid = 79, x = -583, z = 316 },
		},		
		[612] = {name = "The Fringe",
			[1] = { name = "Castrum Oriens", aethid = 98, x = -629, z = -509 },
			[2] = { name = "The Peering Stones", aethid = 99, x = 417, z = 240 },
		},	
		[613] = {name = "The Ruby Sea",
			[1] = { name = "Onokoro", aethid = 106, x = 90, z = -587 },
			[2] = { name = "Tamamizu", aethid = 105, x = 365, z = -263 },
		},	
		[614] = {name = "Yanxia",
			[1] = { name = "Namai", aethid = 107, x = 432, z = -85,
				best = function ()  
					if In(GetYanxiaSection(pos),1) then
						return true
					end
					return false
				end				
			},
			[2] = { name = "The House of the Fierce", aethid = 108, x = 241, z = -402,
				best = function ()  
					if In(GetYanxiaSection(pos),2) then
						return true
					end
					return false
				end				
			},
		},
		[620] = {name = "The Peaks",
			[1] = { name = "Ala Gannha", aethid = 100, x = 114, z = -747 },
			[2] = { name = "Ala Ghiri", aethid = 101, x = -272, z = 746 },
		},
		[621] = {name = "The Lochs",
			[1] = { name = "Porta Praetoria", aethid = 102, x = -653.27, y = 50.50, z = -12.33 },
			[2] = { name = "The Ala Mhigan Quarter", aethid = 103, x = 616.35, y = 81.39, z = 657.47 },
		},
		[622] = {name = "The Azim Steppe",
			[1] = { name = "Reunion", aethid = 109, x = 555, z = 346 },
			[2] = { name = "The Dawn Throne", aethid = 110, x = 71, z = 36 },
		},		
		[813] = {name = "Lakeland",
			[1] = { name = "Fort Jobb", aethid = 132, x = 753, z = -28.8},
			[2] = { name = "Osttall", aethid = 136, x = -735, z = -230},
		},		
		[814] = {name = "Kholusia",
			[1] = { name = "Stilltide", aethid = 137, x = 668, z = 289},
			[2] = { name = "Wright", aethid = 138, x = -244, z = 385},
			[3] = { name = "Tomra", aethid = 139, x = -431, z = -618,
				best = function ()  
					if In(GetKholusiaSection(pos),2) then
						return true
					end
					return false
				end				
			},
		},		
		[815] = {name = "Amh Araeng",
			[1] = { name = "Mord", aethid = 140, x = 246, z = -200 },
			[2] = { name = "Inn", aethid = 161, x = 399, z = 307 },
			[3] = { name = "Twine", aethid = 141, x = -499, z = -210},
		},		
		[816] = {name = "Il Mheg",
			[1] = { name = "Lydha Lran", aethid = 144, x = -344, z = 512},
			[2] = { name = "Pla Enni", aethid = 145, x = -72, z = -857},
			[3] = { name = "Wolekdorf", aethid = 146, x = 380, z = -687},
		},	
		[817] = {name = "Greatwood",
			[1] = { name = "Slitherbough", aethid = 142, x = -103, z = 297},
			[2] = { name = "Fanow", aethid = 143, x = 382, z = -194},
		},
		[818] = {name = "The Tempest",
			[1] = { name = "The Ondo Cups", aethid = 147, x = 561, z = -199},
			[2] = { name = "Macarenses", aethid = 148, x = -141, z = 218},
		},		
	}
	
	local list = GetAttunedAetheryteList()
	if (table.valid(list)) then
		if (not pos or not sharedMaps[mapid]) then
			--d("This is not a shared map or we were not given a position.")
			for index,aetheryte in pairs(list) do
				if (aetheryte.territory == mapid) then
					if (GilCount() >= aetheryte.price and ffxiv_map_nav.IsAetheryte(aetheryte.id) and aetheryte.isattuned) then
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
				for index,aetheryte in pairs(list) do
					if (aetheryte.id == sharedData.aethid) then
						if (GilCount() >= aetheryte.price and aetheryte.isattuned) then
							choices[#choices+1] = sharedData
						end
					end
				end
			end
			
			local size = TableSize(choices)
			if (size > 1) then
			
				local closest,closestDistance = nil,5000
				for i,choice in pairsByKeys(choices) do
					if (choice.aethid) then
						if (choice.best and type(choice.best) == "function") then
							if (choice.best() == true) then
								closest = choice.aethid
								break
							end
						end
					
						local dist = Distance2D(pos.x, pos.z, choice.x, choice.z)
						if not closest or (dist < closestDistance) then
							closest = choice.aethid
							closestDistance = dist
						end
					end
				end
				
				if (closest) then
					bestID = closest
				end
					
				if (bestID ~= nil) then
					for index,aetheryte in pairs(list) do
						if (aetheryte.id == bestID) then
							return aetheryte
						end
					end
				end
			elseif (size == 1) then
				for index,aetheryte in pairs(list) do
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
		if (table.valid(list)) then
			for k,aetheryte in pairs(list) do
				if (aetheryte.id == aethid) then
					if (GilCount() >= aetheryte.price and ffxiv_map_nav.IsAetheryte(aethid)) then
						return true
					end
				end
			end
		end
	end
	
	return false
end
function GetOffMapMarkerList(strMeshName, strMarkerType)
	--[[
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
	--]]
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
		[628] = true,
		[635] = true,			
		[819] = true,			
		[820] = true,		
		[886] = true,
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
	if (MIsLocked() or MIsLoading() or IsControlOpen("SelectString") or IsControlOpen("SelectIconString") or IsShopWindowOpen()) then
		return false
	end
	
	if (ml_task_hub:CurrentTask().noTeleport) then
		return false
	end
	
	if (not gTeleportHack) then
		return false
	else
		if (not gTeleportHackParanoid) then
			return true
		else
			local scanDistance = gTeleportHackParanoidDistance
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
						if (Distance3D(epos.x,epos.y,epos.z,gotoPos.x,gotoPos.y,gotoPos.z) <= scanDistance) then
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
	-- Minion questids are (datamined_questid-65536), so 253 is http://garlandtools.org/db/#quest/65789
	-- Grand Company unlock quests are included here to allow boosted chars without a class hunt log
	-- to do GC hunt logs (e.g.: jobs released after ARR: AST, RDM, GNB, etc.)
	local requiredQuests = {
		[1] = 253,  -- Way of the Gladiator
		[2] = 286,  -- My First Gladius
		[3] = 311,  -- Way of the Marauder
		[4] = 312,  -- My First Axe
		[5] = 345,  -- Way of the Thaumaturge
		[6] = 346,  -- My First Scepter
		[7] = 23,   -- Way of the Lancer
		[8] = 218,  -- My First Spear
		[9] = 533,  -- Way of the Pugilist
		[10] = 553, -- My First Hora
		[11] = 21,  -- Way of the Archer
		[12] = 219, -- My First Bow
		[13] = 453, -- Way of the Arcanist
		[14] = 454, -- My First Grimoire
		[15] = 22,  -- Way of the Conjurer
		[16] = 211, -- My First Cane
		[17] = 680, -- The Company You Keep (Twin Adder)
		[18] = 681, -- The Company You Keep (Maelstrom)
		[19] = 682, -- The Company You Keep (Immortal Flames)
	}
	
	for i,quest in pairs(requiredQuests) do
		if (Quest:IsQuestCompleted(quest)) then
			--d("Quest :"..tostring(quest).." is completed.")
			return true
		else
			--d("Quest :"..tostring(quest).." is NOT completed.")
		end
	end
	
	return false
end
function GetBestGrindMapDefault()
	local mapid = Player.localmapid
	local level = Player.level
	if ( mapid and level ) then
		local inthanalan = 	In(mapid,140,141,145,146,147,140,141,130,131)
		local inshroud = 	In(mapid,148,152,153,154,132,133)
		local inlanoscea = 	In(mapid,129,128,134,135,137,138,139,180)
		
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
		elseif (level >= 30 and level < 40) then
			return 137 --eastern la noscea
		elseif (level >= 40 and level < 45) then
			return 155 --coerthas
		elseif ((level >= 45 and level < 50) or (level >= 50 and (not QuestCompleted(1583) or not CanAccessMap(397)))) then
			return 147 -- northern thanalan
		elseif (level >= 60 and CanAccessMap(612)) then
			return 612 --The Fringes
		elseif (level >= 58 and level < 60 and CanAccessMap(478) and CanAccessMap(399)) then
			return 399 --The Dravanian Hinterlands
		elseif (level >= 55 and level < 60 and CanAccessMap(398)) then
			return 398	--The Dravanian Forelands
		elseif (level >= 50 and level < 60 and CanAccessMap(397)) then
			return 397 --Coerthas Western Highlands		
		else
			return 138
		end	
	end
end
function EquipItem(itemid, itemslot)
	local itemid = tonumber(itemid)
	local item = GetItem(itemid)
	if (item and item.canequip) then
		item:Move(1000,itemslot)
	end
end
function IsEquipped(itemid)
	local itemid = tonumber(itemid)
	
	local bag = Inventory:Get(1000)
	if (table.valid(bag)) then
		local item = bag:Get(itemid)
		if (item) then
			return true
		end
	end
	
	return false
end
function EquippedItemLevel(slot)
	local slot = tonumber(slot)
	
	local bag = Inventory:Get(1000)
	if (table.valid(bag)) then
		local item = bag:GetItem(slot)
		if (item) then
			return item.level
		end
	end
	
	return 0
end
function ItemReady(hqid,targetid)
	local targetid = targetid or 0
	
	local item,itemaction = GetItem(hqid)
	if (item and itemaction) then
		if (targetid ~= 0) then
			return itemaction:IsReady(targetid)
		else
			return itemaction:IsReady()
		end		
	end
	
	return false
end	
function IsInventoryFull(maxitems)
	local maxitems = maxitems or 137
	
	local itemcount = 0
	local inventories = {0,1,2,3}
	for _,invid in pairs(inventories) do
		local bag = Inventory:Get(invid)
		if (table.valid(bag)) then
			itemcount = itemcount + bag.used
		end
	end
	
	return itemcount >= maxitems
end
function GetInventorySnapshot(inventories)
	local currentSnapshot = {}
	
	local inventories = inventories or {0,1,2,3,1000,2004,2000}
	for _,invid in pairs(inventories) do
		local bag = Inventory:Get(invid)
		if (table.valid(bag)) then
			local ilist = bag:GetList()
			if (table.valid(ilist)) then
				for slot,item in pairs(ilist) do
					if currentSnapshot[item.id] == nil then
						-- New item
						currentSnapshot[item.id] = {}
						currentSnapshot[item.id].HQcount = 0
						currentSnapshot[item.id].count = 0
						currentSnapshot[item.id].name = item.name
					end
					-- Increment item counts
					if (item.ishq == 1) then
						-- HQ
						currentSnapshot[item.id].HQcount = currentSnapshot[item.id].HQcount + item.count
					else
						-- NQ
						currentSnapshot[item.id].count = currentSnapshot[item.id].count + item.count
					end
				end
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
	
	if (table.valid(original)) then
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
	
	if (table.valid(new)) then
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

function GetItem(hqid,inventories)
	local hqid = tonumber(hqid) or 0
	local inventories = inventories or {0,1,2,3,1000,2004,2000,2001,3200,3201,3202,3203,3204,3205,3206,3207,3208,3209,3300,3400,3500}
	
	if (hqid ~= 0) then
		if (table.isa(inventories)) then
			for _,invid in pairs(inventories) do
				local bag = Inventory:Get(invid)
				if (table.isa(bag)) then
					local bagSize = bag.size
					for i = 0,bagSize-1 do
						local item = bag:GetItem(i)
						if (item and item.hqid == hqid) then
							return item,item:GetAction()
						end
					end
				end
			end
		end
	end
	
	return nil,nil
end	

function GetItems(hqids,inventories)
	
	local hqids = IsNull(hqids,{})
	local inventories = inventories or {0,1,2,3,1000,2004,2000,2001,3200,3201,3202,3203,3204,3205,3206,3207,3208,3209,3300,3400,3500}
	
	local returnables = {}
	if (table.isa(hqids)) then
		local searchables = {}
		for i = 1,#hqids do 
			searchables[hqids[i]] = true 
		end
	
		if (table.isa(inventories)) then
			for _,invid in pairs(inventories) do
				local bag = Inventory:Get(invid)
				if (table.isa(bag)) then
					local bagSize = bag.size
					for i = 0,bagSize-1 do
						local item = bag:GetItem(i)
						if (item) then
							local hqid = item.hqid
							if (searchables[hqid]) then
								table.insert(returnables,{ item = item, action = item:GetAction() })
							end
						end
					end
				end
			end
		end
	end
	
	return returnables
end	

function GetItemTest(hqid, method, iterations)
	local method = IsNull(method,1)
	local iterations = IsNull(iterations,1)
	
	local results = 0
	
	local testFunc;
	if (method == 1) then
		testFunc = ItemCount
	else
		testFunc = ItemCount2
	end
	for i = 1,iterations do
		local startTime = os.clock()
		local item = testFunc(hqid)
		local finishTime = os.clock()
		local elapsed = (finishTime - startTime)
		results = results + elapsed
	end
	
	local average = results/iterations
	
	d("ItemCount took an average of ["..tostring(average).."] seconds to complete.")
end

function GetItemBySlot(slotid,inventoryid)
	local slotid = tonumber(slotid) or 1
	local inventoryid = inventoryid or 2000
	
	local bag = Inventory:Get(inventoryid)
	if (table.isa(bag)) then
		local item = bag:GetItem(slotid-1)
		if (item) then
			return item
		end
	end
	
	return nil
end	

function GetFirstFreeSlot(hqid,inventories)
	local hqid = tonumber(hqid) or 0
	local inventories = inventories or {0,1,2,3,3200,3201,3202,3203,3204,3205,3206,3207,3208,3209,3300,3400,3500}
	
	if (hqid ~= 0) then
		if (table.isa(inventories)) then
			for _,invid in ipairs(inventories) do
				local bag = Inventory:Get(invid)
				if (table.isa(bag)) then
					if (bag.free > 0) then
						if (bag.free == bag.size) then
							return invid,1
						else
							local ilist = bag:GetList()
							if (table.isa(ilist)) then
								for i = 1, bag.size do
									if (not ilist[i]) then
										return invid,i
									end
								end
							end
						end
					end
				end
			end
		end
	end
	
	return nil,nil
end	

function ItemCount(hqid,inventoriesArg,includehqArg)
	local hqid = tonumber(hqid) or 0
	local inventories = {0,1,2,3,1000,2004,2000,2001,3200,3201,3202,3203,3204,3205,3206,3207,3208,3209,3300,3400,3500}
	local includehq = false
	
	if (type(inventoriesArg) == "table") then
		inventories = inventoriesArg
	elseif (type(inventoriesArg) == "boolean") then
		includehq = inventoriesArg
	end
	if (type(includehqArg) == "table") then
		inventories = includehqArg
	elseif (type(includehqArg) == "boolean") then
		includehq = includehqArg
	end
	
	if (memoize.itemcount == nil) then
		memoize.itemcount = {}
	end
	
	if (memoize.itemcount[hqid]) then
		if (includehq and memoize.itemcount[hqid + 1000000]) then
			--d("returning HQ memoized count for ["..tostring(hqid).."], ["..tostring((memoize.itemcount[hqid].count + memoize.itemcount[hqid].counthq)).."]")
			return (memoize.itemcount[hqid].count + memoize.itemcount[hqid + 1000000].count)
		else
			--d("returning memoized count for ["..tostring(hqid).."], ["..tostring((memoize.itemcount[hqid].count + memoize.itemcount[hqid].counthq)).."]")
			return (memoize.itemcount[hqid].count)
		end
	end

	local itemcount = 0
	
	if (hqid ~= 0) then
		if (table.valid(inventories)) then
			for invid = 1,#inventories do
				local bag = Inventory:Get(inventories[invid])
				if (table.isa(bag)) then
					local bagSize = bag.size
					for i = 0,bagSize-1 do
						local item = bag:GetItem(i)
						if (item) then
							local ihqid = item.hqid -- maybe a bit overkill, but it does take away 1 call at least
							if (ihqid == hqid) then
								itemcount = itemcount + item.count
								if (memoize.itemcount[hqid] == nil) then
									memoize.itemcount[hqid] = { count = 0 }
								end
								memoize.itemcount[hqid].count = itemcount
							elseif (includehq and (ihqid == hqid + 1000000)) then
								itemcount = itemcount + item.count
								if (memoize.itemcount[ihqid] == nil) then
									memoize.itemcount[ihqid] = { count = 0 }
								end
								memoize.itemcount[ihqid].count = itemcount
							end
						end
					end
				end
			end
		end
	end
	
	return itemcount
end

function ItemCounts(hqids,inventoriesArg,includehqArg)
	local hqids = IsNull(hqids,{})
	local inventories = inventories or {0,1,2,3,1000,2004,2000,2001,3200,3201,3202,3203,3204,3205,3206,3207,3208,3209,3300,3400,3500}
	local includehq = false
	
	if (type(inventoriesArg) == "table") then
		inventories = inventoriesArg
	elseif (type(inventoriesArg) == "boolean") then
		includehq = inventoriesArg
	end
	if (type(includehqArg) == "table") then
		inventories = includehqArg
	elseif (type(includehqArg) == "boolean") then
		includehq = includehqArg
	end
	
	if (memoize.itemcount == nil) then
		memoize.itemcount = {}
	end
	
	local returnables = {}
	
	if (table.isa(hqids)) then
		local allhqids = {}
		for i = 1,#hqids do 
			local hqid = hqids[i]
			
			allhqids[hqid] = { count = 0 }
			local hqcounterpart = 0
			if (includehq and hqid < 500000) then
				hqcounterpart = hqid + 1000000
				allhqids[hqcounterpart] = { count = 0 }
			end
		end
		
		for hqid,_ in pairs(allhqids) do
			if (memoize.itemcount[hqid]) then
				--d("removing entry for ["..tostring(hqid).."]")
				returnables[hqid] = { id = hqid, count = IsNull(memoize.itemcount[hqid].count,0) }
				if (includehq) then
					if (memoize.itemcount[hqid + 1000000]) then
						returnables[hqid].count = returnables[hqid].count + memoize.itemcount[hqid + 1000000].count
					end
				end
				allhqids[hqid] = nil
			else
				--d("creating entry for ["..tostring(hqid).."]")
				memoize.itemcount[hqid] = { count = 0 }
				returnables[hqid] = { id = hqid, count = 0 }
			end
		end
		
		if (table.isa(inventories)) then
			for _,invid in pairs(inventories) do
				local bag = Inventory:Get(invid)
				if (table.isa(bag)) then
					local bagSize = bag.size
					for i = 0,bagSize-1 do
						local item = bag:GetItem(i)
						if (item) then
							local itemid = item.hqid
							if (allhqids[itemid]) then
								allhqids[itemid].count = allhqids[itemid].count + item.count
								memoize.itemcount[itemid].count = allhqids[itemid].count
								returnables[itemid] = { id = itemid, count = IsNull(memoize.itemcount[itemid].count,0) }
							end
						end
					end
				end
			end
		end
		
		if (table.valid(allhqids)) then
			for hqid,info in pairs(allhqids) do
				if (includehq and hqid >= 1000000) then
					local nqid = (hqid - 1000000)
					if (returnables[nqid]) then
						returnables[nqid].count = (returnables[nqid].count + info.count)
					else
						returnables[nqid] = { id = nqid, count = info.count }
					end
				end
			end
		end
	end
	
	return returnables
end	

function GilCount()
	local gil = 0
	local gilItem = GetItemBySlot(1,2000)
	if (gilItem) then
		gil = gilItem.count
	end
	return gil
end
function IsCompanionSummoned()
	local companion = GetCompanionEntity()
	if (companion) then
		return true
	end
	
	local dismiss = ActionList:Get(6,2)
	if (dismiss and dismiss:IsReady()) then
		return true
	end
	
	return false
end
function GetCompanionEntity()
	local el = MEntityList("type=2,chartype=3,ownerid="..tostring(Player.id))
	if (table.valid(el)) then
		local i,entity = next(el)
		if (i and entity) then
			return entity
		end
	end
	
	return nil
end
function IsShopWindowOpen()
	return (IsControlOpen("Shop") or IsControlOpen("ShopExchangeItem") or IsControlOpen("ShopExchangeCurrency")
		or IsControlOpen("ShopCard") or IsControlOpen("ShopExchangeCoin"))
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
		local bag = Inventory:Get(xref[slot])
		if (table.valid(bag)) then
			return bag.free <= 0
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
		local bag = Inventory:Get(xref[slot])
		if (table.valid(bag)) then
			return bag.used > 0
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
		local bag = Inventory:Get(xref[slot])
		if (table.valid(bag)) then
			local ilist = bag:GetList()
			if (table.valid(ilist)) then
				for slot, item in pairs(inv) do
					if (not lowest or (lowest and item.level < lowesti)) then
						lowest,lowesti = item, item.level
					end
				end
			end
		end
	end
	return lowest
end
function GetFirstFreeArmorySlot(armoryType)
	return GetFirstFreeSlot({armoryType})
end
function GetFirstFreeInventorySlot()
	return GetFirstFreeSlot({0,1,2,3})
end
function GetEquippedItem(itemid)
	local itemid = tonumber(itemid)
	local inventories = inventories or {1000}
	return GetItem(hqid,inventories)
end
function GetUnequippedItem(itemid)
	local itemid = tonumber(itemid)
	local inventories = inventories or {0,1,2,3,3200,3201,3202,3203,3204,3205,3206,3207,3208,3209,3300,3400,3500}
	return GetItem(hqid,inventories)
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
	if(table.valid(list)) then
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
function IsFoundation(mapid)
	local mapid = tonumber(mapid)
	return (mapid == 418 or mapid == 419)
end
function GameRegion()
	if (GetGameRegion and GetGameRegion()) then
		return GetGameRegion()
	end
	return 1
end
function IsNull(variant,default,typecheck)
	if (variant == nil) then
		if (default == nil) then
			return true
		else
			return default
		end
	else
		if (default ~= nil and typecheck == true and type(variant) ~= type(default)) then
			return default
		else
			return variant
		end
	end
end
function IIF(test,truepart,falsepart)
	if (ValidString(test)) then
		local ok,ret = LoadString("return (" .. test .. ")")
		if (ok and ret == true) then
			return truepart
		end
	elseif (test == true) then
		return truepart
	end
	return falsepart
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
		
		[250] = true, -- Wolves Den
		[336] = true, -- Wolves Den
		[337] = true, -- Wolves Den
		[175] = true, -- Wolves Den
		[352] = true, -- Wolves Den
		[186] = true, -- Wolves Den
		
		[422] = true, -- Frontlines - Slaughter
		
		[149] = true, --   The Feasting Grounds
		[376] = true, --   the Borderland Ruins (Secure)
		[431] = true, --   Seal Rock (Seize)
		[525] = true, --   the Feast (4 on 4 - Training)
		[527] = true, --   the Feast (4 on 4 - Ranked)
		[554] = true, --   the Fields of Glory (Shatter)
		[619] = true, --   the Feast (Custom Match - Feasting Grounds)
		[632] = true, --   the Feast (4 on 4 - Training)
		[644] = true, --   the Feast (4 on 4 - Ranked)
		[646] = true, --   the Feast (Custom Match - Lichenweed)
		[729] = true, --   Astragalos
		[745] = true, --   the Feast (Team Ranked)
		[765] = true, --   the Feast (Ranked)
		[766] = true, --   the Feast (Training)
		[767] = true, --   the Feast (Custom Match - Crystal Tower)
		[767] = true, --   the Feast (Team Custom Match - Crystal Tower)
		[791] = true, --   Hidden Gorge
		[888] = true, --   Onsal Hakair (Danshig Naadam)
		
		[537] = true, -- The Fold ??
		[538] = true, -- The Fold ??
		[539] = true, -- The Fold ??
		[540] = true, -- The Fold ??
		[541] = true, -- The Fold ??
		[542] = true, -- The Fold ??
		[543] = true, -- The Fold ??
		[544] = true, -- The Fold ??
		[545] = true, -- The Fold ??
		[546] = true, -- The Fold ??
		[547] = true, -- The Fold ??
		[548] = true, -- The Fold ??
		[549] = true, -- The Fold ??
		[550] = true, -- The Fold ??
		[551] = true, -- The Fold ??
		
		
	}
	return (pvpMaps[mapid] ~= nil)
end

function IsEurekaMap(mapid)
	local mapid = tonumber(mapid) or 0
	local eMaps = {
		[732] = true,
		[763] = true,
		[795] = true,
		[827] = true,
		[920] = true, --Bozjan Southern Front
		[975] = true, --Zadnor
	}
	return (eMaps[mapid] ~= nil)
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
			if (table.valid(pos)) then
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
			
			-- Fall back check to see if we can get to EL, and from there to the destination.
			for k,aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.id == 134 and GilCount() >= aetheryte.price) then
					local aethPos = {x = 0, y = 82, z = 0}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,820,destMapID)
					if (table.valid(backupPos)) then
						d("Found an attuned backup position aetheryte for mapid ["..tostring(mapid).."].")
						e_teleporttomap.aeth = aetheryte
						return true
					end
				end
			end
			
			if (mapid == 820 and not CanUseAetheryte(134)) then
			-- Fall back alternate check to see if we can get to EL, and from there to the destination.
				for k,aetheryte in pairs(attunedAetherytes) do
					if (aetheryte.id == 138 and GilCount() >= aetheryte.price) then
						local aethPos = {x = -244, y = 20, z = 385}
						local backupPos = ml_nav_manager.GetNextPathPos({x = -244, y = 20, z = 385},814,820)
						if (table.valid(backupPos)) then
							--d("Found an attuned backup position aetheryte for 820 in Kholusia.")
							e_teleporttomap.aeth = aetheryte
							return true
						end
					end
				end
			end
			
			-- Fall back check to see if we can get to Crystal, and from there to the destination.
			for k,aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.id == 133 and GilCount() >= aetheryte.price) then
					local aethPos = {x = -65, y = 4, z = 0}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,819,destMapID)
					if (table.valid(backupPos)) then
						--d("Found an attuned backup position aetheryte for mapid ["..tostring(mapid).."].")
						e_teleporttomap.aeth = aetheryte
						return true
					end
				end
			end
			
			-- Fall back check to see if we can get to Foundation, and from there to the destination.
			for k,aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.id == 70 and GilCount() >= aetheryte.price) then
					local aethPos = {x = -68.819107055664, y = 8.1133041381836, z = 46.482696533203}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,418,mapid)
					if (table.valid(backupPos)) then
						--d("Found an attuned backup position aetheryte for mapid ["..tostring(mapid).."].")
						return true
					end
				end
			end
			
			-- Fall back check to see if we can get to Idyllshire, and from there to the destination.
			for k,aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.id == 75 and GilCount() >= aetheryte.price) then
					local aethPos = {x = 66.53, y = 207.82, z = -26.03}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,478,mapid)
					if (table.valid(backupPos)) then
						--d("Found an attuned backup position aetheryte for mapid ["..tostring(mapid).."].")
						return true
					end
				end
			end
			
			-- Fall back check to see if we can get to Kugane, and from there to the destination.
			for k,aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.id == 111 and GilCount() >= aetheryte.price) then
					local aethPos = {x = 45.89, y = 4.2, z = -40.59}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,628,mapid)
					if (table.valid(backupPos)) then
						d("Found an attuned backup position aetheryte for mapid ["..tostring(mapid).."].")
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

function GetELNSection(pos)
    local section3 = {
        [1] = {
            a = {x = 950, z = 100},
            b = {x = 850, z = 100},
            c = {x = 850, z = 170},
            d = {x = 950, z = 170},
            x = {x = 875, z = 150},
        },
       
        
    }
	local section1 = {
        
		[1] = {
            a = {x = 1000, z = 40},
            b = {x = 275, z = 40},
            c = {x = 275, z = 1000},
            d = {x = 1000, z = 1000},
            x = {x = 600, z = 500},
        },
		
		[2] = {
            a = {x = 1000, z = 270},
            b = {x = 175, z = 270},
            c = {x = 175, z = 1000},
            d = {x = 1000, z = 1000},
            x = {x = 600, z = 600},
        },
    }
	local sec = 2
	if (table.valid(pos)) then
        for i,section in pairs(section1) do
            local isInsideRect = AceLib.API.Math.IsInsideRectangle(pos,section)
            if (isInsideRect) then
                sec = 1
                break
            end
        end
    end
	 if (table.valid(pos)) then
        for i,section in pairs(section3) do
            local isInsideRect = AceLib.API.Math.IsInsideRectangle(pos,section)
            if (isInsideRect) then
                sec = 3
                break
            end
        end
    end
	
	return sec
end

function GetForelandsSection(pos)
    local sections = {
         [1] = {
            a = {x = 640, z = -874},
            b = {x = 640, z = -555},
            c = {x = 910, z = -555},
            d = {x = 910, z = -874},
            x = {x = 757, z = -714.5},
        },
        [2] = {
            a = {x = 640, z = -647},
			b = {x = 640, z = -555},
			c = {x = 160, z = -555},
            d = {x = 160, z = -647},
            x = {x = 400, ymax = 10, z = -601},
        },
        [3] = {
            a = {x = 98, z = -555},
            b = {x = 98, z = 500},
            c = {x = 910, z = 500},
            d = {x = 910, z = -555},
            x = {x = 481.5, z = -27.5},
        },
        [4] = {
            a = {x = 33, z = -208},
			b = {x = 33, z = -109},
			c = {x = 98, z = -109},
            d = {x = 98, z = -208},
            x = {x = 65.5, z = -158.5},
        },
        [5] = {
            a = {x =  98, z = -246},
			b = {x =  98, z = -490},
			c = {x = -29, z = -490},
            d = {x = -29, z = -246},
            x = {x = 34.5, z = -368},
        },
        [6] = {
            a = {x = 98, z = -490},
			b = {x = 98, z = -520},
			c = {x = 80, z = -520},
            d = {x = 80, z = -490},
            x = {x = 89, z = -505},
        },
    }
	
	local sec = 2
    if (table.valid(pos)) then
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
		[4] = {
			a = {x = 140, z = 430},
			b = {x = 220, z = 430},
			c = {x = 222, z = 567},
			d = {x = 136, z = 598},
			x = {x = 160, z = 490},
		},
	}
	
	local sec = 2
	if (table.valid(pos)) then
		local ent1Dist = PDistance3D(pos.x,pos.y,pos.z,-542.46624755859,155.99462890625,-518.10394287109)
		if (ent1Dist <= 250) then
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
    if (table.valid(pos)) then
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

function GetFringeSection(pos)
    local sections = {
		-- gate tunnel
        [1] = {
            a = {x = -86, z = 229}, -- gate right
            b = {x = -67, z = 193}, -- gate left
            c = {x = -159, z = 144}, -- left side ent 
            d = {x = -179, z = 181},-- right side ent
            x = {x = -124, z = 188},
        },
		 -- left bottom side
        [2] = {
            a = {x = -86, z = 229}, -- gate right
            b = {x = -1000, z = 181}, --right side ent
            c = {x = -1000, z = 1000}, -- left bdy
            d = {x = -86, z = 1000}, -- gate waaaaaay south
            x = {x = -450, z = 600},
        },
		-- top left side
        [3] = {
            a = {x = -1000, z = -1000}, -- top left corner map
            b = {x = -1000, z = 144}, --left side ent
            c = {x = 106, z = 144}, -- gate right
            d = {x = 106, z = -1000}, -- top of zone
            x = {x = -450, z = -400},
        },
		-- top of map 
         [4] = {
            a = {x = 600, z = -370}, -- top of section 2
            b = {x = 600, z = -1000}, -- top right corner zone
            c = {x = -1000, z = -1000}, -- top left cnr map
            d = {x = -1000, z = -370}, -- right side to top of section 2
            x = {x = -200, z = -600},
        },
        -- top right mid 1
        [5] = {
            a = {x = 383, z = -350}, -- 1
            b = {x = 262, z = -150}, -- 2
            c = {x = 55, z = -333}, -- 3
            d = {x = 177, z = -465}, -- 4
            x = {x = 227, z = -371},
        },
		[6] = {
            a = {x = 383, z = -376}, -- 1
            b = {x = 348, z = -300}, -- 
            c = {x = 55, z = -333}, -- 
            d = {x = 177, z = -465}, --
            x = {x = 227, z = -371},
        },
		[7] = {
            a = {x = -39, z = 140}, -- 1
            b = {x = -1000, z = 140}, -- 
            c = {x = -1000, z = 347}, -- 
            d = {x = -151, z = 347}, --
            x = {x = -230, z = 180},
        },
		[8] = {
            a = {x = 106, z = -74}, 
            b = {x = 238, z = -172}, 
            c = {x = 210, z = -199}, 
            d = {x = 25, z = -156}, 
            x = {x = 144.75, z = -150.25},
        },
    }
	
	local sec = 2
    if (table.valid(pos)) then
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
function GetYanxiaSection(pos)
	local sections = {
        [1] = {
            a = {x = -650, z = 90},
            b = {x = 990, z = 90},
            c = {x = 990, z = 900},
            d = {x = -650, z = 900},
            x = {x = 170, z = 495},
        },
        [2] = {
            a = {x = 333, z = -350},
            b = {x = 1000, z = -350},
            c = {x = 1000, z = 1000},
            d = {x = 333, z = 1000},
            x = {x = 700, z = 400},
        },
        [3] = {
            a = {x = 465, z = -497},
            b = {x = 1000, z = -497},
            c = {x = 1000, z = 1000},
            d = {x = 465, z = 1000},
            x = {x = 700, z = 750},
        },
        [4] = {
            a = {x = -1000, z = -17},
            b = {x = 1000, z = -17},
            c = {x = 1000, z = 1000},
            d = {x = -1000, z = 1000},
            x = {x = 0, z = 500},
        },
        [5] = {
            a = {x = -71, z = -172},
            b = {x = 1000, z = -172},
            c = {x = 1000, z = 1000},
            d = {x = -71, z = 1000},
            x = {x = 500, z = 400},
        },
		[6] = {
            a = {x = 273, z = -375},
            b = {x = 1000, z = -375},
            c = {x = 1000, z = 1000},
            d = {x = 273, z = 1000},
            x = {x = 600, z = 300},
        },
		[7] = {
            a = {x = 273, z = -375},
            b = {x = 277, z = -380},
            c = {x = 286, z = -376},
            d = {x = 281, z = -369},
            x = {x = 279, z = -375},
        },
    }
	
	local sec = 2
    if (table.valid(pos)) then
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

function GetPeaksSection(pos)
    local section3 = {
        [1] = {
            a = {x = -81, z = 225},
            b = {x = 700, z = 225},
            c = {x = 700, z = 500},
            d = {x = -81, z = 500},
            x = {x = 350, z = 375},
        },
        [2] = {
            a = {x = -38, z = 500},
            b = {x = 700, z = 500},
            c = {x = 700, z = 900},
            d = {x = -38, z = 900},
            x = {x = 350, z = 700},
        },
        [3] = {
            a = {x = -100, z = 700},
            b = {x = -38, z = 700},
            c = {x = -38, z = 900},
            d = {x = -100, z = 900},
            x = {x = -70, z = 800},
        },
        [4] = {
            a = {x = -81, z = 225},
            b = {x = 700, z = 225},
            c = {x = 700, z = 26},
            d = {x = -81, z = 26},
            x = {x = 350, z = 100},
        },
        [5] = {
            a = {x = -81, z = 225},
            b = {x = -180, z = 130},
            c = {x = -110, z = 70},
            d = {x = -32, z = 164},
            x = {x = -90, z = 150},
        },
        [6] = {
            a = {x = -180, z = 130},
            b = {x = -180, z = 0},
            c = {x = 50, z = 0},
            d = {x = 50, z = 130},
            x = {x = -50, z = 70},
        },
		[7] = {
            a = {x = -100, z = 75},
            b = {x = -100, z = -55},
            c = {x = 65, z = -55},
            d = {x = 65, z = 75},
            x = {x = -15, z = 38},
        },
        [8] = {
            a = {x = -136, z = 178},
            b = {x = -115, z = 199},
            c = {x = -104, z = 190},
            d = {x = -124, z = 163},
            x = {x = -122, z = 179},
        },
		[9] = {
            a = {x = -105, z = 740},
            b = {x = -105, z = 769},
            c = {x = -50, z = 769},
            d = {x = -50, z = 740},
            x = {x = -86, z = 753},
        },
    }
	local section1 = {
        [1] = {
            a = {x = -1000, z = 26},
            b = {x = 1000, z = 26},
            c = {x = 1000, z = -1000},
            d = {x = -1000, z = -1000},
            x = {x = 0, z = -500},
        },
    }
	local sec = 2
	if (table.valid(pos)) then
        for i,section in pairs(section1) do
            local isInsideRect = AceLib.API.Math.IsInsideRectangle(pos,section)
            if (isInsideRect) then
                sec = 1
                break
            end
        end
    end
	 if (table.valid(pos)) then
        for i,section in pairs(section3) do
            local isInsideRect = AceLib.API.Math.IsInsideRectangle(pos,section)
            if (isInsideRect) then
                sec = 3
                break
            end
        end
    end
	
	return sec
end

function GetLochsSection(pos)
	local sections = {
        [1] = {
            a = {x = 490, z = 664},
            b = {x = 490, z = 552},
            c = {x = 850, z = 552},
            d = {x = 850, z = 664},
            x = {x = 650, z = 600},
        },
		[2] = {
            a = {x = 664, z = 464},
            b = {x = 664, z = 750},
            c = {x = 850, z = 750},
            d = {x = 850, z = 464},
            x = {x = 750, z = 600},
        },
		[3] = {
            a = {x = 610, z = 732},
            b = {x = 490, z = 664},
            c = {x = 665, z = 464},
            d = {x = 770, z = 561},
            x = {x = 652, z = 599},
        },
		[4] = {
            a = {x = 770, z = 400},
            b = {x = 557, z = 400},
            c = {x = 535, z = 642},
            d = {x = 808, z = 656},
            x = {x = 678, z = 553},
        },
		[5] = {
            a = {x = 560, z = 400},
            b = {x = 489, z = 521},
            c = {x = 569, z = 139},
            d = {x = 644, z = 499},
            x = {x = 583, z = 500},
        },
		[6] = {
            a = {x = 751, z = 732},
            b = {x = 611, z = 732},
            c = {x = 611, z = 623},
            d = {x = 751, z = 623},
            x = {x = 700, z = 680},
        },
		
	   
	   
    }
	
	local sec = 1
    if (table.valid(pos)) then
        for i,section in pairs(sections) do
            local isInsideRect = AceLib.API.Math.IsInsideRectangle(pos,section)
            if (isInsideRect) then
                sec = 2
                break
            end
        end
    end
	
	return sec
end
function GetKholusiaSection(pos)
    local sections = {
        [1] = {
            a = {x = -900, z = -850},
            b = {x = -900, z = 265},
            c = {x = 900, z = 265},
            d = {x = 900, z = -850},
            x = {x = 0, ymin = 135, z = -292.5},
        },
    }

    local sec = 1
    if (table.valid(pos)) then
        for i,section in pairs(sections) do
            local isInsideRect = AceLib.API.Math.IsInsideRectangle(pos,section)
            if (isInsideRect) then
                sec = 2
                break
            end
        end
    end

    return sec
end

function GetAhmAraengSection(pos)
    local section2 = {
        [1] = {
            a = {x = -700, z = -800},
            b = {x = -700, z = 213},
            c = {x = 125, z = 213},
            d = {x = 125, z = -800},
            x = {x = -287.5, z = -293.5},
        },
        [2] = {
            a = {x = -143, z = 213},
            b = {x = -143, z = 283},
            c = {x = 125, z = 283},
            d = {x = 125, z = 213},
            x = {x = -9, z = 248},
        },
    }
	local section3 = {
        [1] = {
            a = {x = -700, z = 213},
            b = {x = -700, z = 551},
            c = {x = -143, z = 551},
            d = {x = -143, z = 213},
            x = {x = -421.5, z = 382},
        },
        [2] = {
            a = {x = -143, z = 334},
            b = {x = -143, z = 551},
            c = {x = 117, z = 551},
            d = {x = 117, z = 334},
            x = {x = -13, z = 442.5},
        },
		[3] = {
            a = {x = 117, z = 389},
            b = {x = 117, z = 551},
            c = {x = 164, z = 551},
            d = {x = 164, z = 389},
            x = {x = 140.5, z = 470},
        },
		[4] = {
            a = {x = 164, z = 441},
            b = {x = 164, z = 551},
            c = {x = 212, z = 551},
            d = {x = 212, z = 441},
            x = {x = 188, z = 496},
        },
		[5] = {
            a = {x = 212, z = 512},
            b = {x = 212, z = 551},
            c = {x = 299, z = 551},
            d = {x = 299, z = 512},
            x = {x = 255.5, z = 531.5},
        },
		[6] = {
            a = {x = -700, z = 551},
            b = {x = -700, z = 1000},
            c = {x = 800, z = 1000},
            d = {x = 800, z = 551},
            x = {x = 50, z = 775.5},
        },
    }

    local sec = 1
	if (table.valid(pos)) then
        for i,section in pairs(section2) do
            local isInsideRect = AceLib.API.Math.IsInsideRectangle(pos,section)
            if (isInsideRect) then
                sec = 2
                break
            end
        end
    end
	if (table.valid(pos)) then
        for i,section in pairs(section3) do
            local isInsideRect = AceLib.API.Math.IsInsideRectangle(pos,section)
            if (isInsideRect) then
                sec = 3
                break
            end
        end
    end
	
	return sec
end

function GetTempestSection(pos)
    local sections = {
        [1] = {
            a = {x = -1000, z = -500},
            b = {x = -1000, z = 1000},
            c = {x = -530, z = 1000},
            d = {x = -530, z = -500},
            x = {x = -765, z = 250},
        },
        [2] = {
            a = {x = -530, z = 130},
            b = {x = -530, z = 1000},
            c = {x = -70, z = 1000},
            d = {x = -70, z = 130},
            x = {x = -300, z = 565},
        },
        [3] = {
            a = {x = -70, z = 198},
            b = {x = -70, z = 1000},
            c = {x = 97, z = 1000},
            d = {x = 97, z = 198},
            x = {x = 13.5, z = 599},
        },
        [4] = {
            a = {x = 97, z = 333},
            b = {x = 97, z = 1000},
            c = {x = 213, z = 1000},
            d = {x = 213, z = 333},
            x = {x = 155, z = 666.5},
        },
        [5] = {
            a = {x = 213, z = 530},
            b = {x = 213, z = 1000},
            c = {x = 415, z = 1000},
            d = {x = 415, z = 530},
            x = {x = 314, z = 765},
        },
    }

    local sec = 1
    if (table.valid(pos)) then
        for i,section in pairs(sections) do
            local isInsideRect = AceLib.API.Math.IsInsideRectangle(pos,section)
            if (isInsideRect) then
                sec = 2
                break
            end
        end
    end

    return sec
end

function Transport139(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (CanFlyInZone()) then
		return false
	end
	
	local gilCount = GilCount()
	if (pos1.x < 0 and pos2.x > 0) then
		if (gilCount >= 40) then
			return true, function ()
				local newTask = ffxiv_nav_interact.Create()
				newTask.pos = {x = -341.24, y = -1, z = 112.098}
				newTask.contentid = 1003586
				newTask.abort = function ()
					return Player.pos.x > 0
				end
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		else
			d("[Transport139]: Need need to cross the water, but we lack the gil, might cause a stuck.")
		end
	elseif (pos1.x > 0 and pos2.x < 0) then
		if (gilCount >= 40) then
			return true, function ()
				local newTask = ffxiv_nav_interact.Create()
				newTask.pos = {x = 222.812, y = -.959197, z = 258.17599}
				newTask.contentid = 1003587
				newTask.abort = function ()
					return Player.pos.x < 0
				end
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
			newTask.contentid = 2002502
			newTask.abort = function ()
				return not (Player.pos.y < -150 and Player.pos.x < 12 and Player.pos.x > -10 and Player.pos.z < 16.5 and Player.pos.z > -14.1)
			end
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	elseif (not (pos1.y < -150 and pos1.x < 12 and pos1.x > -10 and pos1.z < 16.5 and pos1.z > -14.1) and 
			(pos2.y < -150 and pos2.x < 12 and pos2.x > -10 and pos2.z < 16.5 and pos2.z > -14.1)) then
		--d("Need  to move from west to east.")
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = 21.9, y = 20.7, z = -682}
			newTask.contentid = 1006530
			newTask.abort = function ()
				return (Player.pos.y < -150 and Player.pos.x < 12 and Player.pos.x > -10 and Player.pos.z < 16.5 and Player.pos.z > -14.1)
			end
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	end
	
	return false			
end

function Transport137(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	if (GetELNSection(pos1) ~= GetELNSection(pos2)) then
		if (GetELNSection(Player.pos) ~= 3) and (GetELNSection(pos2) == 3) then
			if (GilCount() > 0) then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 607.8, y = 11.6, z = 391.8}
					--newTask.contentid = 1003585
					newTask.contentid = "1003585;1005420"
					newTask.conversationstrings = {
						["en"] = "Board the Rhotano Privateer",
						de = "Zum Großen Schoner",
						fr = "Aller à bord du navire au large",
						jp = "「洋上の大型船」へ行く",
						cn = "前往海上的大型船",
						kr = "'대형 원양어선'으로 이동",
					}
					newTask.abort = function ()
						return (GetELNSection(Player.pos) == 3)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		elseif (GetELNSection(Player.pos) == 3) and (GetELNSection(pos2) == 1) then
			if (GilCount() > 0) then
				return true, function ()
					-- Need to leave the boat, talk to the captain.
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 886.9, y = 21.4, z = 134.2}
					newTask.contentid = 1005414
					newTask.abort = function ()
						return (GetELNSection(Player.pos) == 1)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end
		if (GetELNSection(Player.pos) ~= 2) and (GetELNSection(pos2) == 2) then
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
							if (ActionIsReady(7,5) and not MIsCasting(true) and not MIsLocked()) then
								if (Player:Teleport(12)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 12
									newTask.mapID = 137
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						else
							local newTask = ffxiv_nav_interact.Create()
							newTask.pos = {x = 344.447, y = 32.770, z = 91.694}
							newTask.contentid = 1003588
							newTask.abort = function () 
								return (GetELNSection(Player.pos) == 2) or (CanUseAetheryte(12) and not Player.incombat) 
							end
							ml_task_hub:CurrentTask():AddSubTask(newTask)
						end
					end
				end
			end
		elseif (GetELNSection(Player.pos) == 2) and (GetELNSection(pos2) ~= 2) then
			--d("Need to move from Wineport to Costa area.")
			return true, function()
				if (CanUseAetheryte(11) and not Player.incombat) then
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
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
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 21.919, y = 34.0788, z = 223.187}
					newTask.contentid = 1003589
					newTask.abort = function () 
						return (GetELNSection(Player.pos) ~= 2) or (CanUseAetheryte(11) and not Player.incombat) 
					end
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
	
	if (CanFlyInZone()) then
		return false
	end
	
	if (GilCount() > 100) then
		if (not (pos1.x < -170 and pos1.z > 390) and (pos2.x <-170 and pos2.z > 390)) then
			return true, function()
				local newTask = ffxiv_nav_interact.Create()
				newTask.pos = {x = 318.314, y = -36, z = 351.376}
				newTask.contentid = 1003584
				newTask.conversationIndex = 3
				newTask.abort = function () 
					return (Player.pos.x < -170 and Player.pos.z > 390)
				end
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		elseif ((pos1.x < -170 and pos1.z > 390) and not (pos2.x <-170 and pos2.z > 390)) then
			return true, function()
				local newTask = ffxiv_nav_interact.Create()
				newTask.pos = {x = -290, y = -41.263, z = 407.726}
				newTask.contentid = 1005239
				newTask.abort = function () 
					return not (Player.pos.x < -170 and Player.pos.z > 390)
				end
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
			newTask.contentid = 1001834
			newTask.conversationIndex = 1
			newTask.abort = function () 
				return not (Player.pos.y < 40)
			end
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	elseif (pos1.y > 50 and pos2.y < 40) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = -25.125, y = 81.799, z = -30.658}
			newTask.contentid = 1004339
			newTask.conversationIndex = 2
			newTask.abort = function () 
				return not (Player.pos.y > 50)
			end
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
			newTask.contentid = 1003597
			newTask.conversationIndex = 1
			newTask.abort = function () 
				return not (Player.pos.y < 60)
			end
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	elseif (pos1.y > 70 and pos2.y < 60) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = -8.922, y = 91.5, z = -15.193}
			newTask.contentid = 1003583
			newTask.conversationIndex = 1
			newTask.abort = function () 
				return not (Player.pos.y > 70)
			end
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
			newTask.contentid = 2001715
			newTask.abort = function () 
				return not (Player.pos.x < 23.85 and Player.pos.x > -15.46)
			end
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	elseif (not (pos1.x < 23.85 and pos1.x > -15.46) and (pos2.x < 23.85 and pos2.x > -15.46 )) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = 26.495914459229, y = 1.0000013113022, z = -0.018158292397857}
			newTask.contentid = 2001717
			newTask.abort = function () 
				return (Player.pos.x < 23.85 and Player.pos.x > -15.46)
			end
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
			newTask.contentid = 2002878
			newTask.abort = function () 
				return not (Player.pos.z < 27.394 and Player.pos.z > -27.20)
			end
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	elseif (not (pos1.z < 27.394 and pos1.z > -27.20) and (pos2.z < 27.39 and pos2.z > -27.20)) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = 0.010291699320078, y = -2, z = -29.227424621582}
			newTask.contentid = 2002880
			newTask.abort = function () 
				return (Player.pos.z < 27.394 and Player.pos.z > -27.20)
			end
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
				newTask.contentid = 1004609
				newTask.abort = function ()
					local distance = PDistance3D(Player.pos.x,Player.pos.y,Player.pos.z,-60.55,-25.107,-556.96)
					return not (Player.pos.y < -15 and distance < 40) 
				end
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		end
	end

	return false			
end

function Transport398(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (false) then -- need to re-evaluate the sections before enabling this
	--if (not CanFlyInZone()) then
		if (GetForelandsSection(pos1) ~= GetForelandsSection(pos2)) then
			if (GilCount() > 1000) then
				if (GetForelandsSection(Player.pos) == 2) then
					if (CanUseAetheryte(76) and not Player.incombat) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(76)) then
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 76
									newTask.mapID = 398
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					end
				else
					if (CanUseAetheryte(77) and not Player.incombat) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(77)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 77
									newTask.mapID = 398
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					end
				end
			end
		end
	end

	return false			
end

function Transport399(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (not CanFlyInZone()) then
		local libraryDist = math.distance3d(Player.pos,{x = 295, y = 232, z = 768 })
		if (GetHinterlandsSection(pos1) ~= GetHinterlandsSection(pos2) and libraryDist > 300) then
			return true, function()
				local newTask = ffxiv_task_movetomap.Create()
				newTask.destMapID = 478
				ff.mapsections[399] = GetHinterlandsSection(pos2)
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
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
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
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
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
		end
	end

	return false			
end

function Transport612(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (not CanFlyInZone()) then
		if QuestCompleted(2530) then 
			local gilCount = GilCount()
	--d("Player Fringe sec = ["..tostring(GetFringeSection(Player.pos))"]")
	--d("Endpoint Fringe sec = ["..tostring(GetFringeSection(pos2))"]")
			if (GetFringeSection(pos1) ~= GetFringeSection(pos2)) then
				if (GetFringeSection(Player.pos) == 2) then
					if (CanUseAetheryte(98) and not Player.incombat) and (gilCount > 100) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(98)) then	
								--d("teleport 98")
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 98
									newTask.mapID = 612
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					else
						if (gilCount > 0) then
							return true, function ()
								local newTask = ffxiv_nav_interact.Create()
								newTask.pos = {x = -68, y = 56, z = 211}
								newTask.contentid = 1019531
								newTask.abort = function ()
									return (GetFringeSection(Player.pos) ~= 2)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
							end
						end
					end
				else
					if (CanUseAetheryte(99) and not Player.incombat) and (gilCount > 100) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(99)) then	
								--d("teleport 99")
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 99
									newTask.mapID = 612
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					else
						if (gilCount > 0) then
							return true, function ()
								local newTask = ffxiv_nav_interact.Create()
								newTask.pos = {x = -91, y = 50, z = 210}
								newTask.contentid = 1019530
								newTask.abort = function ()
									return (GetFringeSection(Player.pos) == 2)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
							end
						end
					end
				end
			end
		end
	end
		
	return false			
end

function Transport614(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if HasQuest(2518) or QuestCompleted(2518) then
		if (GetYanxiaSection(pos1) ~= GetYanxiaSection(pos2)) then
			if (GilCount() > 200) then
				if (GetYanxiaSection(Player.pos) == 1) then
					if (CanUseAetheryte(108) and not Player.incombat) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(108)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 108
									newTask.mapID = 614
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					end
				else
					if (CanUseAetheryte(107) and not Player.incombat) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(107)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 107
									newTask.mapID = 614
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					end
				end
			end
		end
		if (GetYanxiaSection(Player.pos) ~= 2) and (GetYanxiaSection(pos2) == 2) then
			if not (CanUseAetheryte(108)) then
				return true, function()
					local newTask = ffxiv_task_movetomap.Create()
					newTask.destMapID = 622
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end
	end
	return false			
end

function Transport620(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (not CanFlyInZone()) then
		if (GetPeaksSection(pos1) ~= GetPeaksSection(pos2)) then
			if (GilCount() > 200) then
				if (GetPeaksSection(Player.pos) ~= 1) then
					if (GetPeaksSection(pos2) == 1) then
						if (CanUseAetheryte(100) and not Player.incombat) then
							return true, function () 
								if (Player:IsMoving()) then
									Player:Stop()
									ml_global_information.Await(1500, function () return not Player:IsMoving() end)
									return
								end
								if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
									if (Player:Teleport(100)) then	
										local newTask = ffxiv_task_teleport.Create()
										newTask.aetheryte = 100
										newTask.mapID = 620
										ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
									end
								end
							end
						end
					end
				end
				
				if (GetPeaksSection(Player.pos) == 1) then
					if (GetPeaksSection(pos2) ~= 1) then
						if (CanUseAetheryte(101) and not Player.incombat) then
							return true, function () 
								if (Player:IsMoving()) then
									Player:Stop()
									ml_global_information.Await(1500, function () return not Player:IsMoving() end)
									return
								end
								if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
									if (Player:Teleport(101)) then	
										local newTask = ffxiv_task_teleport.Create()
										newTask.aetheryte = 101
										newTask.mapID = 620
										ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
									end
								end
							end
						end
					end
				end
			end
		end
		
		if (HasQuest(2537) and GetQuestInfo(2537,'step') >= 2) or (QuestCompleted(2537) and not QuestCompleted(2541)) then
			if (GetPeaksSection(Player.pos) ~= 3) and (GetPeaksSection(pos2) == 3) then
				if (GilCount() > 0) then
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = -129, y = 305, z = 189}
						newTask.contentid = 2008944
						newTask.abort = function ()
							return (GetPeaksSection(Player.pos) == 3)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				end
			end
		end
		if QuestCompleted(2541) then
			if (GetPeaksSection(Player.pos) ~= 3) and (GetPeaksSection(pos2) == 3) then
				if (GilCount() > 0) then
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = -132, y = 305, z = 191}
						newTask.contentid = 1021557
						newTask.abort = function ()
							return (GetPeaksSection(Player.pos) == 3)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				end
			end
			
		end
	end
	
	return false			
end

function Transport621(pos1,pos2)
    local pos1 = pos1 or Player.pos
    local pos2 = pos2
    
	if (not CanFlyInZone()) then
		if QuestCompleted(2550) then
			if (GetLochsSection(Player.pos)~= 1)  and (GetLochsSection(pos2) == 1) then
				if (GilCount() > 0) then
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = 500, y = 69, z = 583}
						newTask.contentid = 1023048
						newTask.abort = function ()
							return (GetLochsSection(Player.pos) == 1)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				end
			end
			if (GetLochsSection(Player.pos)~= 2)  and (GetLochsSection(pos2) == 2) then
				if (GilCount() > 0) then
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = 466, y = 61, z = 583}
						newTask.contentid = 1023047
						newTask.abort = function ()
							return (GetLochsSection(Player.pos) == 2)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				end
			end
		end
	end

    return false            
end

function Transport622(pos1,pos2)
    local pos1 = pos1 or Player.pos
    local pos2 = pos2
    
    if (IsDiving()  and (pos2.x < 140 and pos2.x > -130 and pos2.z < 178 and pos2.z > -78 and pos2.y > 50)) then
		return true, function()
			local newTask = ffxiv_task_movetopos.Create()
			newTask.pos = {x = 61.60, y = 8.80, z = 41.12}
			newTask.contentid = 1019423
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	end
	if ((pos1.x < 140 and pos1.x > -130 and pos1.z < 178 and pos1.z > -78 and pos1.y > 50) and not (pos2.x < 140 and pos2.x > -130 and pos2.z < 178 and pos2.z > -78 and pos2.y > 50) and CanFlyInZone() == false) then
		if (GetQuestInfo(2509,'step') == 3) then
			return true, function()
				local newTask = ffxiv_nav_interact.Create()
				newTask.pos = {x = 66.06, y = 114.90, z = -8.38}
				newTask.contentid = 1023089
				newTask.abort = function ()
					return not (Player.pos.x < 140 and Player.pos.x > -130 and Player.pos.z < 178 and Player.pos.z > -78 and Player.pos.y > 50)
				end
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		else
			return true, function()
				local newTask = ffxiv_nav_interact.Create()
				newTask.pos = {x = 66.06, y = 114.90, z = -8.38}
				newTask.contentid = 1019424
				newTask.abort = function ()
					return not (Player.pos.x < 140 and Player.pos.x > -130 and Player.pos.z < 178 and Player.pos.z > -78 and Player.pos.y > 50)
				end
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		end
    elseif (not (pos1.x < 140 and pos1.x > -130 and pos1.z < 178 and pos1.z > -78 and pos1.y > 50) and (pos2.x < 140 and pos2.x > -130 and pos2.z < 178 and pos2.z > -78 and pos2.y > 50) and CanFlyInZone() == false) then
        return true, function()
            local newTask = ffxiv_nav_interact.Create()
            newTask.pos = {x = 61.60, y = 8.80, z = 41.12}
            newTask.contentid = 1019423
			newTask.abort = function ()
				return (Player.pos.x < 140 and Player.pos.x > -130 and Player.pos.z < 178 and Player.pos.z > -78 and Player.pos.y > 50)
			end
            ml_task_hub:CurrentTask():AddSubTask(newTask)
        end
    end
	
    return false            
end
function Transport814(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (not CanFlyInZone()) then
		if (HasQuest(3634) and GetQuestInfo(3634,'step') >= 2) or QuestCompleted(3634) then 
			local gilCount = GilCount()
			if (GetKholusiaSection(pos1) ~= GetKholusiaSection(pos2)) then
				if (GetKholusiaSection(Player.pos) == 1) then
					if (CanUseAetheryte(139) and not Player.incombat) and (gilCount > 100) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(139)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 139
									newTask.mapID = 814
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					else
						if (gilCount > 0) then
							return true, function ()
								local newTask = ffxiv_nav_interact.Create()
								newTask.pos = {x = -454.70, y = 65.78, z = 58.27}
								newTask.contentid = 1028319
								newTask.abort = function ()
									return (GetKholusiaSection(Player.pos) ~= 1)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
							end
						end
					end
				end
				if (GetKholusiaSection(Player.pos) == 2) then
					if (CanUseAetheryte(138) and not Player.incombat) and (gilCount > 100) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(138)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 138
									newTask.mapID = 814
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					else
						if (gilCount > 0) then
							return true, function ()
								local newTask = ffxiv_nav_interact.Create()
								newTask.pos = {x = -454.64, y = 334.05, z = -16.98}
								newTask.contentid = 1028320
								newTask.abort = function ()
									return (GetKholusiaSection(Player.pos) ~= 2)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
							end
						end
					end
				end
			end
		end
	end
		
	return false			
end
function Transport815(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (not CanFlyInZone()) then
		if QuestCompleted(3609) then 
			local gilCount = GilCount()
			if (GetAhmAraengSection(pos1) ~= GetAhmAraengSection(pos2)) then
				if (GetAhmAraengSection(Player.pos) == 1 and GetAhmAraengSection(pos2) == 2) then
					if (CanUseAetheryte(141) and not Player.incombat) and (gilCount > 100) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(141)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 141
									newTask.mapID = 815
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					end
				end
				if (GetAhmAraengSection(Player.pos) == 2 and GetAhmAraengSection(pos2) == 1) then
					if (CanUseAetheryte(140) and not Player.incombat) and (gilCount > 100) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(140)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 140
									newTask.mapID = 815
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					end
				end
			end
		end	
		if (QuestCompleted(3619) or (HasQuest(3619) and GetQuestInfo(3619,'step') >= 255)) then 
			local gilCount = GilCount()
			if (GetAhmAraengSection(pos1) ~= GetAhmAraengSection(pos2)) then
				if (GetAhmAraengSection(Player.pos) == 2 and GetAhmAraengSection(pos2) == 3) then
					if (gilCount > 0) then
							return true, function ()
								local newTask = ffxiv_nav_interact.Create()
								newTask.pos = {x = -474.59, y = 45.55, z = -237.59}
								newTask.contentid = 1031660
								newTask.abort = function ()
									return (GetAhmAraengSection(Player.pos) ~= 2)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
						end
					end
				end
				if (GetAhmAraengSection(Player.pos) == 3 and GetAhmAraengSection(pos2) == 2) then
					if (CanUseAetheryte(141) and not Player.incombat) and (gilCount > 100) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(141)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 141
									newTask.mapID = 815
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					else
						if (gilCount > 0) then
							return true, function ()
								local newTask = ffxiv_nav_interact.Create()
								newTask.pos = {x = -176.01, y = -3.42, z = 215.46}
								newTask.contentid = 2010763
								newTask.abort = function ()
									return (GetAhmAraengSection(Player.pos) ~= 3)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
							end
						end
					end
				end
				if (GetAhmAraengSection(Player.pos) == 1 and GetAhmAraengSection(pos2) == 3) then
					if (CanUseAetheryte(141) and not Player.incombat) and (gilCount > 100) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(141)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 141
									newTask.mapID = 815
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					end
				end
				if (GetAhmAraengSection(Player.pos) == 3 and GetAhmAraengSection(pos2) == 1) then
					if (CanUseAetheryte(140) and not Player.incombat) and (gilCount > 100) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(140)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 140
									newTask.mapID = 815
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					end
				end
			end
		end
	end
		
	return false			
end
function Transport818(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (not CanFlyInZone()) then
		if QuestCompleted(3652) then 
			local gilCount = GilCount()
			if (GetTempestSection(pos1) ~= GetTempestSection(pos2)) then
				if (GetTempestSection(Player.pos) == 1) then
					if (CanUseAetheryte(148) and not Player.incombat) and (gilCount > 100) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(148)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 148
									newTask.mapID = 818
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					else
						if (gilCount > 0) then
							return true, function ()
								local newTask = ffxiv_nav_interact.Create()
								newTask.pos = {x = -610.40, y = 45.48, z = 94.93}
								newTask.contentid = 2010145
								newTask.abort = function ()
									return (GetTempestSection(Player.pos) ~= 1)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
							end
						end
					end
				end
				if (GetTempestSection(Player.pos) == 2) then
					if (CanUseAetheryte(147) and not Player.incombat) and (gilCount > 100) then
						return true, function () 
							if (Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1500, function () return not Player:IsMoving() end)
								return
							end
							if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
								if (Player:Teleport(147)) then	
									local newTask = ffxiv_task_teleport.Create()
									newTask.aetheryte = 147
									newTask.mapID = 818
									ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
								end
							end
						end
					else
						if (gilCount > 0) then
							return true, function ()
								local newTask = ffxiv_nav_interact.Create()
								newTask.pos = {x = -602.82, y = -282.73, z = 113.49}
								newTask.contentid = 2010146
								newTask.abort = function ()
									return (GetTempestSection(Player.pos) ~= 2)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
							end
						end
					end
				end
			end
		end
	end
		
	return false			
end

function CanFlyInZone()
	if (GetPatchLevel() >= 5.35) then
	--if (QuestCompleted(524)) then
		--return true
	--end 
	end
	
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

function CanDiveInZone()
	if (Player.diving) then
		if (Player.diving.candiveinzone) then
			return true
		end
	end
	return false
end

function IsSwimming()
	if (Player.diving) then
		if (Player.diving.isswimming) then
			return true
		end
	end
	return false
end

function IsDiving()
	if (Player.diving) then
		if (Player.diving.isdiving) then
			return true
		end
	end
	return false
end

function GetDiveHeight()
	if (Player.diving) then
		return Player.diving.heightlevel
	end
	return false
end

function CannotMove()
	return (IsControlOpen("FadeMiddle") or (MIsLocked() and not IsFlying() and not IsDiving() and not IsSwimming()))
end

function DoWait(ms)
	ms = tonumber(ms) or 150
	local instructions = {
		{"Wait", { ms }},
	}
	ml_navigation.ParseInstructions(instructions)
end

function Stop()
	local instructions = {
		{"Stop", {}},
	}
	ml_navigation.ParseInstructions(instructions)
end
function Descend(incnode)
	if (IsFlying()) then
		local incnode = IsNull(incnode,false)
		
		local _trackDown, _dismount
		_trackDown = function ()
			--d("[Descend]: Start tracking.")
			local startHeight = Player.pos.y
			
			ffnav.AwaitSuccessFail(100, 250, 
				function () return Player.pos.y < startHeight end, nil, 
				_trackDown, 
				function () 
					d("[Descend]: End descent process.")
					if (incnode) then
						ml_navigation.pathindex = ml_navigation.pathindex + 1
						NavigationManager.NavPathNode = ml_navigation.pathindex
					end
				end
			)
			ml_global_information.Await(10000, function () return not ffnav.IsYielding() end)
		end
		
		_dismount = function ()
			local dismount = ActionList:Get(13,Player.mountid)
			local dismountMain = ActionList:Get(5,23)
			if (dismount and dismount:IsReady(Player.id)) then
				local startHeight = Player.pos.y
				
				d("[Descend]: Start descend.")
				dismount:Cast(Player.id)
				ffnav.AwaitSuccess(100, 250, 
					function () return Player.pos.y < startHeight end, 
					_trackDown
				)
				ml_global_information.Await(10000, function () return not ffnav.IsYielding() end)
				
			elseif (dismountMain and dismountMain:IsReady(Player.id)) then
				local startHeight = Player.pos.y
				
				d("[Descend]: Start descend, used secondary cast.")
				dismountMain:Cast(Player.id)
				ffnav.AwaitSuccess(100, 250, 
					function () return Player.pos.y < startHeight end, 
					_trackDown
				)
				ml_global_information.Await(10000, function () return not ffnav.IsYielding() end)
				
			end
		end
		
		_dismount()
	end
end

function Dive()
	local _waitDown, _dive
	_waitDown = function ()
		local startHeight = Player.pos.y
		
		ffnav.AwaitSuccessFail(100, 250, 
			function ()	return Player.pos.y < startHeight or MIsLoading() end, nil, 
			_waitDown, 
			function () 
				d("[Dive]: End dive process.")
				if (ffnav.isdescending) then
					ffnav.isdescending = false
					ml_navigation.pathindex = ml_navigation.pathindex + 1
					NavigationManager.NavPathNode = ml_navigation.pathindex
				end
			end
		)
		ml_global_information.Await(10000, function () return not ffnav.IsYielding() end)
	end
	
	_dive = function ()
		local startHeight = Player.pos.y
		
		d("[Dive]: Start dive.")
		Player:Dive()
		ffnav.AwaitSuccessFail(250, 1000, 
			function () return (Player.pos.y < startHeight or MIsLoading() or IsDiving()) end, nil,
			_waitDown, 
			function () 
				if (not IsFlying() and not IsDiving()) then
					_dive()
				else
					d("[Dive]: Stop attempting to dive, flying or already diving.")
				end
			end
		)
		ml_global_information.Await(10000, function () return not ffnav.IsYielding() end)
	end
	
	_dive()
end

function UsingBattleItem()
	local currentAction = Player.action
	return (currentAction == 83 or currentAction == 84 or currentAction == 85 or currentAction == 89 or currentAction == 90 or currentAction == 91)
end

function IsTransporting()
	return HasBuff(Player.id,404)
end

function TestConditions(conditions)
	if (not memoize.conditions) then
		memoize.conditions = {}
	end
	
	if (not table.valid(conditions)) then
		return true
	end
	
	tested = {}
	local testKey,testVal = next(conditions)
	if (tonumber(testKey) ~= nil) then
		for i,conditionset in pairsByKeys(conditions) do
			tested[i] = {}
			if (ValidTable(conditionset)) then
				for condition,value in pairs(conditionset) do
					
					if (memoize.conditions[condition] ~= nil) then
						if (memoize.conditions[condition] ~= value) then
							return false
						end
					else
						local startTime = os.clock()
						local ok,ret;
						if (type(condition) == "function") then
							ok, ret = pcall(condition)
						elseif (type(condition) == "string") then
							ok, ret = LoadString("return " .. condition)
						end
						local finishTime = os.clock()
						local elapsed = (finishTime - startTime)
						if (elapsed > 0.1) then
							d("condition:"..tostring(condition).." took ["..tostring(elapsedTime).."] to evaluate")
						end
						if (ok and ret ~= nil) then
							memoize.conditions[condition] = ret
							if (ret ~= value) then
								return false
							end
						end
					end
					tested[i][condition] = true
				end
			end
			
			if (ValidTable(conditionset)) then
				for condition,value in pairs(conditionset) do
					if (not tested[i][condition]) then
						if (_G[condition] and (type(_G[condition]) == "string" or type(_G[condition]) == "number")) then
							if (_G[condition] ~= value) then
								return false
							end
							tested[i][condition] = true
						end
					end
				end
			end
		end
	else
		if (ValidTable(conditions)) then
			for condition,value in pairs(conditions) do
				if (memoize.conditions[condition] ~= nil) then
					if (memoize.conditions[condition] ~= value) then
						return false
					end
				else
					local startTime = os.clock()
					local ok,ret;
					if (type(condition) == "function") then
						ok, ret = pcall(condition)
					elseif (type(condition) == "string") then
						ok, ret = LoadString("return " .. condition)
					end
					local finishTime = os.clock()
					local elapsed = (finishTime - startTime)
					if (elapsed > 0.1) then
						d("condition:"..tostring(condition).." took ["..tostring(elapsedTime).."] to evaluate")
					end
					if (ok and ret ~= nil) then
						memoize.conditions[condition] = ret
						if (ret ~= value) then
							return false
						end
					end
				end
				tested[condition] = true
			end
		end
		
		if (ValidTable(conditions)) then
			for condition,value in pairs(conditions) do
				if (not tested[condition]) then
					if (_G[condition] and (type(_G[condition]) == "string" or type(_G[condition]) == "number")) then
						if (_G[condition] ~= value) then
							return false
						end
						tested[condition] = true
					end
				end
			end
		end
	end
	
	return true, conditions
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

function QueueAction( actionid, targetid, actiontype )
	local actionid = actionid or 0
	local actiontype = actiontype or 1
	local tid = targetid or Player.id
	
	local target = MGetEntity(tid)
	if (table.valid(target)) then
		local action = ActionList:Get(actiontype,actionid)
		if (action and action:IsReady(tid)) then
			local tpos = target.pos
			if (tid ~= Player.id) then
				Player:SetFacing(tpos.x,tpos.y,tpos.z)
			end
				
			if (action:Cast(tid)) then
				local castid = action.id
				ml_global_information.AwaitDo(100, 1000, 
					function ()
						return (Player.castinginfo.lastcastid == castid)
					end,
					function ()
						Player:SetFacing(tpos.x,tpos.y,tpos.z)
						local action = ActionList:Get(actiontype,actionid)
						if (action and action:IsReady(tid)) then
							action:Cast(tid)
						end
					end
				)
				return true
			end
		end
	end
end

function QueueActionXYZ( actionid, targetid, actiontype )
	local actionid = actionid or 0
	local actiontype = actiontype or 1
	local tid = targetid or Player.id
	
	local target = MGetEntity(tid)
	if (table.valid(target)) then
		local action = ActionList:Get(actiontype,actionid)
		if (action and action:IsReady(tid)) then
			local tpos = target.pos
			if (tid ~= Player.id) then
				Player:SetFacing(tpos.x,tpos.y,tpos.z)
			end
				
			if (action:Cast(tpos.x,tpos.y,tpos.z)) then
				local castid = action.id
				ml_global_information.AwaitDo(100, 1000, 
					function ()
						return (Player.castinginfo.lastcastid == castid)
					end,
					function ()
						Player:SetFacing(tpos.x,tpos.y,tpos.z)
						local action = ActionList:Get(actiontype,actionid)
						if (action and action:IsReady(tid)) then
							action:Cast(tpos.x,tpos.y,tpos.z)
						end
					end
				)
				return true
			end
		end
	end
end

function NotQueued()
	return Duty:GetQueueStatus() == 0
end
function InQueue()
	return Duty:GetQueueStatus() == 1
end
function IsConfirming()
	return Duty:GetQueueStatus() == 2
end
function IsReadying()
	return Duty:GetQueueStatus() == 3
end
function InInstance()
	return (Duty:GetQueueStatus() == 4 and Duty:GetDutyTimeRemaining() > 0)
end
function GetVersion()
	if (GUI_NewWindow) then
		return 32
	else
		return 64
	end
end
function GetConversationList()
	local controlName;
	if (IsControlOpen("SelectIconString")) then
		controlName = "SelectIconString"
	elseif (IsControlOpen("SelectString")) then
		controlName = "SelectString"
	elseif (IsControlOpen("CutSceneSelectString")) then
		controlName = "CutSceneSelectString"
	end
	
	if (controlName) then
		local control = GetControl(controlName)
		if (control) then
			return control:GetData()
		end
	end
	
	-- This change breaks the questing profiles that rely on it.
	--[[
	if (IsControlOpen("CutSceneSelectString")) then
		local control = GetControl("CutSceneSelectString")
		if (control) then
			local rawtable = control:GetRawData()
			local stringtable = {}
			local indexcount = 0
			for index, data in pairsByKeys(rawtable) do
				if (data.type == "string") then
					stringtable[indexcount] = data.value
					indexcount = indexcount + 1
				end
			end
			return stringtable
		end
	end
	--]]
	
	return nil
end
function SelectConversationLine(line)
	local line = IsNull(line,0)
	local controlName;
	if (IsControlOpen("SelectIconString")) then
		controlName = "SelectIconString"
	elseif (IsControlOpen("SelectString")) then
		controlName = "SelectString"
	elseif (IsControlOpen("CutSceneSelectString")) then
		controlName = "CutSceneSelectString"
	end
	
	if (controlName) then
		return UseControlAction(controlName,"SelectIndex",line)
	end
	return false
end
function SelectConversationIndex(index)
	local index = IsNull(index,0)
	local controlName;
	if (IsControlOpen("SelectIconString")) then
		controlName = "SelectIconString"
	elseif (IsControlOpen("SelectString")) then
		controlName = "SelectString"
	elseif (IsControlOpen("CutSceneSelectString")) then
		controlName = "CutSceneSelectString"
	end
	
	if (controlName) then
		return UseControlAction(controlName,"SelectIndex",index-1)
	end
	return false
end
function deepcompare(t1,t2,ignore_mt)
	local function _deepcompare(t1, t2, ignore_mt)
		local ty1 = type(t1)
		local ty2 = type(t2)
		if ty1 ~= ty2 then return false end
		-- non-table types can be directly compared
		if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
		-- as well as tables which have the metamethod __eq
		local mt = getmetatable(t1)
		if not ignore_mt and mt and mt.__eq then return t1 == t2 end
		for k1,v1 in pairs(t1) do
			local v2 = t2[k1]
			if v2 == nil or not _deepcompare(v1,v2) then return false end
		end
		for k2,v2 in pairs(t2) do
			local v1 = t1[k2]
			if v1 == nil or not _deepcompare(v1,v2) then return false end
		end
		return true
	end
	return _deepcompare(t1, t2, ignore_mt)
end
function SetCurrentTaskProperty(strProperty, value)
	local currentTask = ml_task_hub:CurrentTask()
	if (table.valid(currentTask)) then
		currentTask[strProperty] = value
	end
end
function SetThisTaskProperty(strProperty, value)
	local thisTask = ml_task_hub:ThisTask()
	if (table.valid(thisTask)) then
		thisTask[strProperty] = value
	end
end
function SetNamedTaskProperty(strTask, strProperty, value)
	local task = _G[strTask]
	if (task) then
		task[strProperty] = value
	end
end
function GetCurrentTaskProperty(strProperty)
	local currentTask = ml_task_hub:CurrentTask()
	if (table.valid(currentTask)) then
		return currentTask[strProperty]
	end
end
function GetThisTaskProperty(strProperty)
	local thisTask = ml_task_hub:ThisTask()
	if (table.valid(thisTask)) then
		return thisTask[strProperty]
	end
end
function GetNamedTaskProperty(strTask, strProperty)
	local task = _G[strTask]
	if (task) then
		return task[strProperty]
	end
end
function In(var,...)
	local var = var
	
	local args = {...}
	for i=1, #args do
		if (args[i] == var or (tonumber(var) ~= nil and tonumber(args[i]) == tonumber(var))) then
			return true
		end
	end
	
	return false
end
function Between(var,low,high,inclusive)
	local inclusive = IsNull(inclusive,true)
	if (var and type(var) == "number" and low and type(low) == "number" and high and type(high) == "number") then
		if (low < high) then
			if (inclusive) then
				return (low <= var and high >= var)
			else
				return (low < var and high > var)
			end
		elseif (low > high) then
			if (inclusive) then
				return (high <= var and low >= var)
			else
				return (high < var and low > var)
			end
		end
	end
	return false
end
function FindClosestMesh(pos,distance,checkcubes,cubesonly)
	local checkcubes = IsNull(checkcubes,true)
	local cubesonly = IsNull(cubesonly,false)
	local minDist = IsNull(distance,10)
	
	local closest,closestDistance = nil, 100
	if (checkcubes) then
		local p = NavigationManager:GetClosestPointInCubes(pos)
		if (table.valid(p)) then
			if (p.distance <= minDist) then
				closest = p
				closestDistance = p.distance
			end
		end
	end
	
	if (not cubesonly) then
		local p = NavigationManager:GetClosestPointOnMesh(pos)
		if (table.valid(p)) then
			if (p.distance <= minDist) then
				if (p.distance < closestDistance) then
					closest = p
				end
			end
		end
	end
	
	if (closest) then
		return closest
	end
	
	local y1 = pos.y
	local y2 = pos.y
				
	for i = y2, y2+10, 0.5 do
		local trypos = {x = pos.x, y = i, z = pos.z}
		local p = NavigationManager:GetClosestPointOnMesh(trypos)
		if (table.valid(p)) then
			if (p.distance <= minDist) then	
				return p
			end
		end
	end
	
	for i = y1, y1-10, -0.5 do
		local trypos = {x = pos.x, y = i, z = pos.z}
		local p = NavigationManager:GetClosestPointOnMesh(trypos)
		if (table.valid(p) and p.distance <= minDist) then	
			if (p.distance <= minDist) then	
				return p
			end
		end
	end
	return nil
end
function IsEntityReachable(entityid,range)
	local entityid = IsNull(entityid,0)
	local range = IsNull(range,2)
	local entity;
	if (type(entityid) == "number" and entityid ~= 0) then
		entity = EntityList:Get(entityid)
	elseif (type(entityid) == "table") then
		entity = entityid
	end
	
	if (table.valid(entity)) then
		if (entity and (IsDiving() or (not entity.meshpos or (entity.meshpos and entity.meshpos.distance <= range)))) then
			return true
		end
	end
	return false
end
function GetInteractableEntity(contentids,types)
	local contentids = IsNull(tostring(contentids),"")
	local types = IsNull(types,{0,2,3,5,6,7})
	
	local interacts;
	if (string.valid(contentids)) then
		interacts = MEntityList("targetable,contentid="..contentids..",maxdistance2d=30")
	else
		interacts = MEntityList("targetable,maxdistance2d=15")
	end
	
	if (table.valid(interacts)) then
		local validInteracts = {}
		for i,entity in pairs(interacts) do
			for _,typeid in pairs(types) do
				if (typeid == entity.type) then
					validInteracts[i] = entity
				end
			end
		end
		
		if (table.valid(validInteracts)) then
			local ppos = Player.pos
			local nearest, nearestDistance = nil, math.huge
			for i,interact in pairs(validInteracts) do
				local dist = interact.distance2d
				if (not nearest or (nearest and dist < nearestDistance)) then
					nearest, nearestDistance = interact, dist
				end
			end
			
			return nearest
		end
	end
	return nil
end

-- Very general check for things that would prevent moving around
function Busy()
	local currentTask = ml_task_hub:CurrentTask()
	return MIsLocked() or (MIsCasting() and (currentTask == nil or IsNull(currentTask.interruptCasting,false) == false)) or MIsLoading() or IsControlOpen("SelectString") or IsControlOpen("SelectIconString") or IsShopWindowOpen() 
		or IsControlOpen("Gathering") or IsControlOpen("GatheringMasterpiece") or Player:GetFishingState() ~= 0 or not Player.alive or IsControlOpen("Synthesis") or IsControlOpen("SynthesisSimple") 
		or IsControlOpen("Talk") or IsControlOpen("Snipe") or IsControlOpen("Request") or IsControlOpen("JournalResult") or IsControlOpen("JournalAccept")
end

-- Various windows that we should not move around in while open.
function HasInteractWindows()
	return IsControlOpen("SelectString") or IsControlOpen("SelectIconString") or IsShopWindowOpen() 
		or IsControlOpen("Gathering") or IsControlOpen("GatheringMasterpiece") or IsControlOpen("Synthesis") or IsControlOpen("SynthesisSimple") 
		or IsControlOpen("Talk") or IsControlOpen("Snipe") or IsControlOpen("Request") or IsControlOpen("JournalResult") or IsControlOpen("JournalAccept")
		or IsControlOpen("HWDSupply") or IsControlOpen("HWDGathereInspect") or IsControlOpen("ContentsFinderConfirm")
end

function GetDutyCompleted(mapid)
	local currentData = ffxivminion.DutyCurrentData[mapid]
	if (currentData ~= nil) then
		return currentData
	end
	return false
end

function HasAllCurrents(mapid)
	local currentData = ffxivminion.AetherCurrentData[mapid]
	if (table.valid(currentData)) then
	local tsize = table.size(currentData)
		for i = 1, tsize do
			if (currentData[i] == false) then
				return false
			end
		end
		return true
	end
	return false
end

function GetAetherCurrentData(mapid)
	
	local status = {}
	if (table.valid(ffxivminion.AetherCurrentData)) then
		if ffxivminion.AetherCurrentData[mapid] ~= nil then
			status = ffxivminion.AetherCurrentData[mapid]
		end
	end

	return status
end

function FindNearestCollectableAppraiser()
	local idyllshire = { id = 1012300, aethid = 75, mapid = 478, pos = {x = -18.3, y = 206.5, z = 45.1} }
	local morDhona = { id = 1013396, aethid = 24, mapid = 156, pos = {x = 50.28, y = 31.09, z = -735.2} }
	local rhalgr = { id = 1019457, aethid = 104, mapid = 635, pos = {x = -66.80, y = 0.01, z = 63.40} }
	local gridania = { id = 1003076, aethid = 2, mapid = 133, pos = {x = 143, y = 13, z = -103} }
	local limsa = { id = 1003632, aethid = 8, mapid = 129, pos = {x = -257, y = 16, z = 40} }
	local uldah = { id = 1001616, aethid = 9, mapid = 131, pos = {x =149, y = 4, z = -17} }
	local eulmore = { id = 1027542, aethid = 134, mapid = 820, pos = {x =17, y = 82, z = -19} }
	
	if (Player.localmapid == morDhona.mapid) then
		return morDhona
	elseif (Player.localmapid == idyllshire.mapid) then
		return idyllshire
	elseif (Player.localmapid == rhalgr.mapid) then
		return rhalgr
	elseif (Player.localmapid == gridania.mapid) then
		return gridania
	elseif (Player.localmapid == limsa.mapid) then
		return limsa
	elseif (Player.localmapid == uldah.mapid) then
		return uldah
	elseif (Player.localmapid == eulmore.mapid) and QuestCompleted(3603) then
		return eulmore
	else
		local hasIdyllshire, hasRhalgr, hasMorDhona, hasEulmore = false, false, false, false
		local idyllshireCost, rhalgrCost, morDhonaCost, eulmoreCost = 0, 0, 0, 0
		local gil = GilCount()
		local attuned = GetAttunedAetheryteList(true)
		if (table.valid(attuned)) then
			for id,aetheryte in pairs(attuned) do
				if (aetheryte.id == morDhona.aethid and gil >= aetheryte.price) then
					hasMorDhona = true
					morDhonaCost = aetheryte.price
				elseif (aetheryte.id == idyllshire.aethid and gil >= aetheryte.price) then
					hasIdyllshire = true
					idyllshireCost = aetheryte.price
				elseif (aetheryte.id == rhalgr.aethid and gil >= aetheryte.price) then
					hasRhalgr = true
					rhalgrCost = aetheryte.price
				elseif QuestCompleted(3603) and (aetheryte.id == eulmore.aethid and gil >= aetheryte.price) then
					hasEulmore = true
					eulmoreCost = aetheryte.price
				end
				if (hasIdyllshire and hasMorDhona and hasRhalgr) or (hasEulmore) then
					break
				end
			end
		end
		if hasEulmore then
			return eulmore
		end
		if (hasIdyllshire and hasMorDhona and hasRhalgr) then
			if (morDhonaCost < rhalgrCost and morDhonaCost < idyllshireCost) then
				return morDhona
			elseif (idyllshireCost < morDhonaCost and idyllshireCost < rhalgrCost) then
				return idyllshire
			elseif (rhalgrCost < morDhonaCost and rhalgrCost < idyllshireCost) then
				return rhalgr
			end
		elseif (hasMorDhona) then
			return morDhona
		end
	end
	
	return nil
end
function GetLowestValue(...)
	local lowestValue = math.huge
	
	local vals = {...}
	if (table.valid(vals)) then
		for k,value in pairs(vals) do
			if (value < lowestValue) then
				lowestValue = value
			end
		end
	end
	
	return lowestValue
end
function FindClosestCity()
	local idyllshire = { aethid = 75, mapid = 478 }
	local rhalgr = { aethid = 104, mapid = 635 }
	local gridania = { aethid = 2, mapid = 132 }
	local limsa = { aethid = 8, mapid = 129 }
	local uldah = { aethid = 9, mapid = 131 }
	local eulmore = { aethid = 134, mapid = 820 }
	
	local inns = {
		[177] = "Mizzenmast Inn",
		[178] = "The Hourglass",
		[179] = "The Roost",
		[429] = "Cloud Nine",
		[629] = "Bokairo Inn",
		[843] = "The Pendants Personal Suite"
	}
	if inns[Player.localmapid] then
		return Player.localmapid
	end
	
	if (Player.localmapid == idyllshire.mapid) then
		return idyllshire
	elseif (Player.localmapid == rhalgr.mapid) then
		return rhalgr
	elseif (Player.localmapid == gridania.mapid) then
		return gridania
	elseif (Player.localmapid == limsa.mapid) then
		return limsa
	elseif (Player.localmapid == uldah.mapid) then
		return uldah
	elseif (Player.localmapid == eulmore.mapid) then
		return eulmore
	else
		local hasIdyllshire, hasRhalgr, hasEulmore, hasGridania, hasLimsa, hasUldah = false, false, false, false, false, false, false
		local idyllshireCost, rhalgrCost, eulmoreCost, gridaniaCost, limsaCost, uldahCost = 1000, 1000, 1000, 1000, 1000, 1000, 1000
		local gil = GilCount()
		local attuned = GetAttunedAetheryteList()
		if (table.valid(attuned)) then
			for id,aetheryte in pairs(attuned) do
				if (aetheryte.id == idyllshire.aethid and gil >= aetheryte.price) then
					hasIdyllshire = true
					idyllshireCost = aetheryte.price
				elseif (aetheryte.id == rhalgr.aethid and gil >= aetheryte.price) then
					hasRhalgr = true
					rhalgrCost = aetheryte.price
				elseif QuestCompleted(3603) and (aetheryte.id == eulmore.aethid and gil >= aetheryte.price) then
					hasEulmore = true
					eulmoreCost = aetheryte.price
				elseif (aetheryte.id == gridania.aethid and gil >= aetheryte.price) then
					hasGridania = true
					gridaniaCost = aetheryte.price
				elseif (aetheryte.id == limsa.aethid and gil >= aetheryte.price) then
					hasLimsa = true
					limsaCost = aetheryte.price
				elseif (aetheryte.id == uldah.aethid and gil >= aetheryte.price) then
					hasUldah = true
					uldahCost = aetheryte.price
				end
			end
		end
		
		local cheapest = GetLowestValue(idyllshireCost, rhalgrCost, morDhonaCost, eulmoreCost, gridaniaCost, limsaCost, uldahCost)
		if hasIdyllshire and (cheapest == idyllshireCost) then
			return idyllshire.mapid
		elseif hasRhalgr and (cheapest == rhalgrCost) then
			return rhalgr.mapid
		elseif hasEulmore and (cheapest == eulmoreCost) then
			return eulmore.mapid
		elseif hasGridania and (cheapest == gridaniaCost) then
			return gridania.mapid
		elseif hasLimsa and (cheapest == limsaCost) then
			return limsa.mapid
		elseif hasUldah and (cheapest == uldahCost) then
			return uldah.mapid
		end
	end
	
	return 0
end
function MoveDirectly3D(pos)
	local ppos = Player.pos
	if (pos ~= nil) then
		local dist3D = math.distance3d(pos,ppos)
		local anglediff = math.angle({x = math.sin(ppos.h), y = 0, z =math.cos(ppos.h)}, {x = pos.x-ppos.x, y = 0, z = pos.z-ppos.z})
		if ( anglediff < 35 and dist3D > (5*ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()])) then
			Player:SetFacing(pos.x,pos.y,pos.z, true) -- smooth facing
		else
			Player:SetFacing(pos.x,pos.y,pos.z)
		end
		
		-- Set Pitch							
		local currentPitch = math.round(Player.flying.pitch,3)
		local minVector = math.normalize(math.vectorize(ppos,pos))
		local pitch = math.asin(-1 * minVector.y)
		Player:SetPitch(pitch)
		
		-- Move
		if (not Player:IsMoving()) then
			Player:Move(FFXIV.MOVEMENT.FORWARD)	
			ml_global_information.Await(2000, function () return Player:IsMoving() end)
		end
		ml_navigation.path = {}
	end
end
function GetHoverHeight()
	local ppos = Player.pos
	local hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y+2,ppos.z,ppos.x,ppos.y-10,ppos.z) 
	if (hit) then
		local height = (ppos.y - hity)
		if (height >= 0) then
			return height
		end
	end
	return 10
end

ffxivminion.lastPitchCalc = 0
ffxivminion.lastVector = {}
function GetRequiredPitch(pos,noadjustment)
	local noadjustment = IsNull(noadjustment,false)
	if (table.valid(pos)) then
		local ppos = Player.pos
		
		--[[
		-- The path is conputed at the feet, so it is possible to get stuck on objects at the head level.
		-- This code attempts to angle the player down a bit if such an object is found.
		local hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y+4,ppos.z,pos.x,pos.y+4,pos.z) 
		if (hit) then
			for i = 3, 15, 3 do
				d("Obstacle detected, adjust pitch down by [" .. i .. "]..")
				hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y+4,ppos.z,pos.x,pos.y-i,pos.z)
				if (not hit) then
					d("New trajectory appears safe, use it.")
					pos = { x = pos.x, y = pos.y - i, z = pos.z }
					break
				end
			end
		end
		
		local nextNode = ml_navigation.path[ml_global_information.pathindex]
		if (table.isa(nextNode) and nextNode.is_cube) then
			-- Auto-adjust for feet-level impacts.
			if (not hit) then
				hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y-0.25,ppos.z,pos.x,pos.y,pos.z) 
				if (hit) then
					for i = 3, 15, 3 do
						d("Obstacle detected, adjust pitch up by [" .. i .. "]..")
						hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y-0.25,ppos.z,pos.x,pos.y+i,pos.z)
						if (not hit) then
							d("New trajectory appears safe, use it.")
							pos = { x = pos.x, y = pos.y + i, z = pos.z }
							break
						end
					end
				end
			end
		end
		--]]
		
		local currentPitch = math.round(Player.flying.pitch,3)
		local vector = math.normalize(math.vectorize(ppos,pos))
		
		ffxivminion.lastVector = vector
		
		local pitch = math.asin(-1 * vector.y)
		if (pitch > 1.4835) then
			--d("Required pitch was too high (downward) ["..tostring(pitch).."], shifted down to max.")
			ffxivminion.lastPitchCalc = 1.4835
			return 1.4835
		elseif (pitch < -0.7599) then
			--d("Required pitch was too low (upward) ["..tostring(pitch).."], shifted up to max.")
			ffxivminion.lastPitchCalc = -0.7599
			return pitch -0.7599
		else
			ffxivminion.lastPitchCalc = pitch
			return pitch
		end
	end		
	return 0
end
function IsNormalMap(mapid)
	local maps = {
		[130] = true,
		[134] = true,
		[135] = true,
		[137] = true,
		[138] = true,
		[139] = true,
		[140] = true,
		[141] = true,
		[145] = true,
		[146] = true,
		[147] = true,
		[148] = true,
		[152] = true,
		[153] = true,
		[154] = true,
		[155] = true,
		[156] = true,
		[180] = true,
		[130] = true,
		[182] = true,
		[131] = true,
		[128] = true,
		[181] = true,
		[129] = true,
		[132] = true,
		[183] = true,
		[133] = true,
		[179] = true,
		[178] = true,
		[177] = true,
		[144] = true,
		[351] = true,
		[388] = true,
		[395] = true,
		[397] = true,
		[398] = true,
		[399] = true,
		[400] = true,
		[401] = true,
		[402] = true,
		[418] = true,
		[419] = true,
		[463] = true, 
		[478] = true, 
		[612] = true,
		[613] = true,
		[614] = true,
		[620] = true,
		[621] = true,
		[622] = true,
		[628] = true,		
		[635] = true,	
		[759] = true,	
		[813] = true,	
		[814] = true,	
		[815] = true,	
		[816] = true,		
		[817] = true,	
		[818] = true,			
		[819] = true,			
		[820] = true,	
		[844] = true,	
	}
	return maps[mapid] ~= nil
end
function IsHousingMap(mapid)
	local maps = {
		[339] = true,
		[340] = true,
		[341] = true,
		[641] = true,
	}
	return maps[mapid] ~= nil
end
function ValidPosition(pos)
	if (table.valid(pos)) then
		return (pos.x ~= nil and pos.y ~= nil and pos.z ~= nil and type(pos.x) == "number" and type(pos.y) == "number" and type(pos.z) == "number")
	end
	return false
end
function GetUIValue()
	local totalUI = 0
	for i=0,165 do
		if (GetUIPermission(i) == 1) then
			totalUI = totalUI + i
		end
	end
	return totalUI
end
function PlayerDriving()
	if ((GUI:IsMouseDown(0) and GUI:IsMouseDown(1)) or GUI:IsMouseDragging(1)) then
		return true
	end
	return false
end
function UsingAutoFace()
	return Player.settings.autoface
end
function HQToID(id)
	if (id >= 500000 and id < 600000) then
		return (id - 500000)
	elseif (id >= 1000000) then
		return (id - 1000000)
	else
		return id
	end
end
function Time()
	return IsNull(GetEorzeaTime().servertime,0)
end
function CleanConvoLine(line)
	local clean = string.gsub(line,"[()-/\x02\x16\x01\x03]","")
	return clean
end
function IsDutyCompleted(ctype,id)
	local dutyList = Duty:GetCompleteDutyList()
	if (table.valid(dutyList)) then
		for i,duty in pairs(dutyList) do
			if (duty.type == ctype and duty.id == id) then
				return duty.completed
			end
		end
	end
	return false
end
function IsInCombat(includepet,includecompanion)
	local includepet = IsNull(includepet,true)
	local includecompanion = IsNull(includecompanion,true)
	
	if (Player.incombat) then
		return true
	elseif (includepet or includecompanion) then
		--local el = MEntityList("alive,attackable,incombat")  leaving this out for now, may be necessary, but hopefully not
		if (includepet) then
			if (Player.pet) then
				if (Player.pet.incombat) then
					return true
				end
				--[[
				if (table.valid(el)) then
					for i,entity in pairs(el) do
						if (In(Player.pet.id,entity.targetid,entity.claimedbyid)) then
							return true
						end
					end
				end
				--]]
			end
		elseif (includecompanion) then
			local companion = GetCompanionEntity()
			if (companion) then
				if (companion.alive and companion.incombat) then
					return true
				end
				--[[
				if (table.valid(el)) then
					for i,entity in pairs(el) do
						if (In(companion.id,entity.targetid,entity.claimedbyid)) then
							return true
						end
					end
				end
				--]]
			end
		end
	end
	return false
end
function GetParty()
	local party = IsNull(MEntityList("myparty,alive,maxdistance2d=100"),{})
	party[Player.id] = Player
	
	local npcTeam = MEntityList("alive,chartype=9,targetable,maxdistance2d=100")
	if (npcTeam) then
		for i,entity in pairs(npcTeam) do
			local econt = entity.contentid
			if (entity.ownerid == Player.id or In(econt,10066,10067,10068,10069,10070,10071,10072,10073)) then
				party[i] = entity
			end
		end
	end
	return party
end
function CheckDirectorTextIndex(...)
	local index = MGetDirectorIndex()
	if (index == 0) then
		return false
	else
		local args = {...}
		for i=1, #args do
			if (args[i] == index) then
				return true
			end
		end
	end
	
	return false
end

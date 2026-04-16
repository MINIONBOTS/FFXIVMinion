-- This file holds global helper functions
ff = {}
ff.lastPos = {}
ff.lastPath = 0
ff.lastFail = 0
ff.lastaetherCurrent = {}
ff.aetherCurrent = {}

-- Nav debug logger (no-op by default, set navd = d to enable debug output)
function navd() end

-- QuestCompleted fallback: C++ registers this global, but if missing provide a Lua shim
if (not QuestCompleted) then
	function QuestCompleted(id)
		return Quest:IsQuestCompleted(id)
	end
end

ff.mapsections = {
	[399] = 0,
}

-- Trust member role tables (by contentid)
-- Derived from AST card targeting: Bole/Ewer = tanks, Balance/Spear = DPS, remainder = healers
ff.trust_tanks = {
	[713]=true, [1455]=true, [5964]=true, [8650]=true, [9348]=true, [9363]=true,
	[11262]=true, [11266]=true, [11271]=true, [11313]=true, [11326]=true, [11330]=true, [11334]=true,
	[11416]=true, [11431]=true, [12236]=true, [12312]=true, [12463]=true, [12464]=true, [12487]=true, [12488]=true,
}
ff.trust_healers = {
	[1492]=true, [4130]=true,
	[8650]=true, [9346]=true, [9349]=true, [9363]=true, [10586]=true,
	[11264]=true, [11267]=true, [11271]=true, [11329]=true, [11333]=true, [11337]=true,
	[12239]=true, [12465]=true, [12468]=true, [12469]=true,
	[12487]=true, [12488]=true,
}
ff.trust_melee_dps = {
	[4133]=true, -- Raubahn (Gladiator)
	[5970]=true, -- Lyse (Monk)
	[6148]=true, -- Hien (Samurai)
	[8650]=true, -- Crystal Exarch (all-rounder)
	[8889]=true, -- Ryne (Rogue)
	[8917]=true, -- Minfilia (Rogue)
	[9363]=true, -- G'raha Tia (all-rounder)
	[10013]=true, -- Estinien (Dragoon)
	[11269]=true, -- Ryne's avatar (Rogue)
	[11270]=true, -- Estinien's avatar
	[11271]=true, -- G'raha Tia's avatar (all-rounder)
	[11331]=true, -- Scion Lancer
	[11335]=true, -- Serpent Lancer
	[11433]=true, -- Temple Banneret (Lancer)
	[12237]=true, -- House Fortemps Banneret (Lancer)
	[12466]=true, -- Yugiri (Ninja)
	[12470]=true, -- Resistance Pikedance (Lancer)
	[12487]=true, -- Wuk Lamat (all-rounder)
	[12488]=true, -- G'raha Tia (all-rounder)
	[12635]=true, -- J'moldva (Lancer)
}
ff.trust_phys_ranged_dps = {
	[8919]=true, -- Lyna (Dancer)
	[10899]=true, -- Hythlodaeus (Bard)
	[11418]=true, -- Zero (Bard)
	[12053]=true, -- Zero's avatar (Bard)
	[12740]=true, -- Koana (Phys Ranged)
}
ff.trust_caster_dps = {
	[4846]=true, -- Krile (Pictomancer)
	[5239]=true, -- Alisaie (Red Mage)
	[8378]=true, -- Y'shtola (caster DPS)
	[10898]=true, -- Emet-Selch (caster DPS)
	[11265]=true, -- Alisaie's avatar (Red Mage)
	[11268]=true, -- Y'shtola's avatar (caster DPS)
	[11328]=true, [11332]=true, [11336]=true, -- Thaumaturges
	[12739]=true, -- Zoraal Ja (Magic DPS)
	[13522]=true, -- Krile's avatar (Pictomancer)
}
ff.trust_dps = {
	[4133]=true, [4846]=true, [5239]=true, [5970]=true, [6148]=true,
	[8378]=true, [8650]=true, [8889]=true, [8917]=true, [8919]=true, [9347]=true, [9363]=true,
	[10013]=true, [10898]=true, [10899]=true, [11265]=true, [11268]=true,
	[11269]=true, [11270]=true, [11271]=true, [11282]=true, [11328]=true, [11331]=true, [11332]=true, [11335]=true, [11336]=true, [11418]=true, [11433]=true,
	[12053]=true, [12237]=true, [12466]=true, [12467]=true, [12470]=true, [12487]=true, [12488]=true, [12489]=true, [12635]=true, [12739]=true, [12740]=true, [13522]=true,
}

function ff.debugLog(var, level, debugFlag, debugLevel, questAware)
	local level = tonumber(level) or 3
	local requiredLevel = debugLevel
	if (questAware and gBotMode == "questMode" and gQuestDebug) then
		requiredLevel = gQuestDebugLevel
	end
	if (debugFlag or (questAware and gQuestDebug and gBotMode == "questMode")) then
		if (level <= tonumber(requiredLevel)) then
			if (type(var) == "string") then
				d("[L"..tostring(level).."]["..tostring(Now()).."]: "..var)
			elseif (type(var) == "number" or type(var) == "boolean") then
				d("[L"..tostring(level).."]["..tostring(Now()).."]: "..tostring(var))
			elseif (type(var) == "table") then
				outputTable(var)
			end
		end
	end
end


function GetPatchLevel()
	local gr = ffxivminion.gameRegion
	if (IsNull(gr,0) == 0) then
		gr = GetGameRegion()
		ffxivminion.gameRegion = gr
	end
	return ffxivminion.patchLevel[gr]
end
function GetBestMesh(baseName, version, suffix)
	if not tonumber(version) then
		return baseName
	end
	suffix = suffix or "_V"
	
	local bestMesh = ""
	local pathName = GetStartupPath()..[[\Navigation\]]
	for i = 1, 20, 1 do
		if i <= tonumber(version) then
			local candidate = baseName..suffix..tostring(i)
			if FolderExists(pathName..candidate) then
				bestMesh = candidate
			end
		end
	end 
	
	if bestMesh ~= "" then
		return bestMesh
	else
		return baseName
	end
end
function GetBestMoonMesh(version)
	return GetBestMesh("Sinus Ardorum", version, "_V")
end
function GetBestPhaennaMesh(version)
	return GetBestMesh("Phaenna", version, "_v")
end
function GetBestOizysMesh(version)
	return GetBestMesh("Oizys", version, "_v")
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

	local fate = FFXIVLib.API.Fate.GetActiveFateById(ml_task_hub:CurrentTask().fateid)
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
			
			for i,entity in pairs(attackables) do
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
					
					-- Filter out blacklists
					if (table.valid(excludeTable)) then
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

function GetNearestFateAttackable()
	local el = nil
    local myPos = Player.pos
    local fate = FFXIVLib.API.Fate.GetActiveFateById(ml_task_hub:CurrentTask().fateid)
	
	if (fate) then
		local maxLevel = fate.maxlevel
		local overMaxLevel = (Player.level > maxLevel)
		
		if (fate.status == 2 and fate.completion < 100) then
		
			local nearest,nearestDistance = nil,0
			local nearestNoLos,nearestNoLosDist = nil,0
			el = MEntityList("alive,attackable,onmesh,maxdistance2d=100,contentid=6737;6738")
			if (table.valid(el)) then
				for i,entity in pairs(el) do
					if (entity.fateid == fate.id) then
						local epos = entity.pos
						local fatedist = Distance2D(epos.x,epos.z,fate.x,fate.z)
						if (fatedist <= fate.radius or (not overMaxLevel and fatedist <= (fate.radius * 1.10))) then
							local dist = entity.distance2d
							if (entity.los) then
								if (not nearest or dist < nearestDistance) then
									nearest, nearestDistance = entity, dist
								end
							else
								if (not nearestNoLos or dist < nearestNoLosDist) then
									nearestNoLos, nearestNoLosDist = entity, dist
								end
							end
						end
					end
				end
				if (nearest) then
					return nearest
				end
				if (nearestNoLos) then
					return nearestNoLos
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
			local nearestNoLos,nearestNoLosDist = nil,0
			el = MEntityList("alive,attackable,targetingme,onmesh,maxdistance2d=10")
			if (table.valid(el)) then
				for i,entity in pairs(el) do
					if (entity.fateid == fate.id or entity.fateid > 10000 or gFateKillAggro) then
						local epos = entity.pos
						local fatedist = Distance2D(epos.x,epos.z,fate.x,fate.z)
						if (fatedist <= fate.radius or (not overMaxLevel and fatedist <= (fate.radius * 1.10)) or entity.fateid == 0) then
							local dist = entity.distance2d
							if (entity.los) then
								if (not nearest or dist < nearestDistance) then
									nearest, nearestDistance = entity, dist
								end
							else
								if (not nearestNoLos or dist < nearestNoLosDist) then
									nearestNoLos, nearestNoLosDist = entity, dist
								end
							end
						end
					end
				end
				if (nearest) then
					return nearest
				end
				if (nearestNoLos) then
					return nearestNoLos
				end
			end	

			nearest,nearestDistance = nil,0
			nearestNoLos,nearestNoLosDist = nil,0
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
								if (e.los) then
									if (not nearest or dist3d < nearestDistance) then
										nearest, nearestDistance = e, dist3d
									end
								else
									if (not nearestNoLos or dist3d < nearestNoLosDist) then
										nearestNoLos, nearestNoLosDist = e, dist3d
									end
								end
							end
						end
					end
					if (nearest) then
						return nearest
					end
					if (nearestNoLos) then
						return nearestNoLos
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
			nearestNoLos,nearestNoLosDist = nil,0
			el = MEntityList("alive,attackable,onmesh")
			if (table.valid(el)) then
				for i,entity in pairs(el) do
					if (entity.fateid == fate.id or entity.fateid > 10000) then
						local epos = entity.pos
						local fatedist = Distance2D(epos.x,epos.z,fate.x,fate.z)
						if (fatedist <= fate.radius) then
							local dist3d = Distance3D(epos.x,epos.y,epos.z,myPos.x,myPos.y,myPos.z)
							if (entity.los) then
								if (not nearest or dist3d < nearestDistance) then
									nearest, nearestDistance = entity, dist3d
								end
							else
								if (not nearestNoLos or dist3d < nearestNoLosDist) then
									nearestNoLos, nearestNoLosDist = entity, dist3d
								end
							end
						end
					end
				end
				if (nearest) then
					return nearest
				end
				if (nearestNoLos) then
					return nearestNoLos
				end
			end	
		end
	end
    
    return nil
end
function GetHuntTarget()
	local excludeString = GetBlacklistIDString()
	local myPos = Player.pos
	
	local function findNearest(contentids, rank)
		local el
		if (excludeString) then
			el = MEntityList("contentid="..contentids..",alive,attackable,onmesh,exclude_contentid="..excludeString)
		else
			el = MEntityList("contentid="..contentids..",alive,attackable,onmesh")
		end
		if (table.valid(el)) then
			local nearest = nil
			local nearestDistance = 9999
			for i,e in pairs(el) do
				local tpos = e.pos
				local distance = PDistance3D(myPos.x, myPos.y, myPos.z, tpos.x, tpos.y, tpos.z)
				if (distance < nearestDistance) then
					nearest = e
					nearestDistance = distance
				end
			end
			if (table.valid(nearest)) then
				return rank, nearest
			end
		end
		return nil
	end
	
	if (gHuntSRankHunt ) then
		local rank, target = findNearest(ffxiv_task_hunt.rankS, "S")
		if (rank) then return rank, target end
	end
	
	if (gHuntARankHunt ) then
		local rank, target = findNearest(ffxiv_task_hunt.rankA, "A")
		if (rank) then return rank, target end
	end
	
	if (gHuntBRankHunt ) then
		if (gHuntBRankHuntID ~= "") then
			local rank, target = findNearest(tostring(gHuntBRankHuntID), "B")
			if (rank) then return rank, target end
		end
		
		if (gHuntBRankHuntAny ) then
			local rank, target = findNearest(ffxiv_task_hunt.rankB, "B")
			if (rank) then return rank, target end
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
			if (IsTank(entity) and entity.hp.percent < lowestHP ) then
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
	
	if (gBotMode == "partyMode" and not IsPartyLeader()) then
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
	if id == 0 then return nil end

	return FFXIVLib.API.Action.GetPetActionById(id)
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
		[FFXIV.JOBS.REDMAGE] = true,
		[FFXIV.JOBS.BLUEMAGE] = true,
		[FFXIV.JOBS.PICTOMANCER] = true
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
		el = MEntityList("myparty,friendly,chartype=4,targetable,dead,maxdistance="..tostring(range))
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
	
	if (gBotMode == "partyMode" and not IsPartyLeader()) then
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
				local role = GetRoleString(entity)
                if role == GetString("healer") then
                    targets[GetString("healer")] = entity
                elseif role == GetString("dps") then
                    if (targets[GetString("dps")] ~= nil) then
						-- keep blackmage as highest prioritized ranged target
						if (gPrioritizeRanged  and IsRangedDPS(entity)) then
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
				
				if IsMeleeDPS(entity) then
					targets[GetString("meleeDPS")] = entity				
				end
				
				if IsCasterDPS(entity) then
					if (targets[GetString("caster")] ~= nil) then
						if (targets[GetString("caster")].job ~= FFXIV.JOBS.BLACKMAGE) then
							targets[GetString("caster")] = entity
						end
					else
						targets[GetString("caster")] = entity
					end
				end
				
				if IsRangedDPS(entity) then
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
	local taskName = ml_task_hub:ThisTask().name
	local excludeString = GetBlacklistIDString()
	local el = nil
	
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
function IsDebuffable(targetid)
	
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
				if (buff.dispellable and buff.isdebuff) then
					return true
				end
			end
		end
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
function TryFaceHeading(targetHeading, epsilon)
	if (ml_navigation and ml_navigation.TryFaceHeading) then
		return ml_navigation:TryFaceHeading(targetHeading, epsilon)
	end
	Player:SetFacing(targetHeading)
	return true
end
function TryFaceTarget(targetX, targetY, targetZ, angleEpsilon)
	if (ml_navigation and ml_navigation.TryFaceTarget) then
		return ml_navigation:TryFaceTarget(targetX, targetY, targetZ, angleEpsilon)
	end
	Player:SetFacing(targetX, targetY, targetZ)
	return true
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
function IsFriendlyBuff(skillID)
	local id = tonumber(skillID)
	
    if (buffs[id]) then
        return true
    end
	
	if (id >= 4401 and id <= 4424) then
		return true
	end
	
    return false
end
local mudras = {
	[2261] = true,
	[2259] = true,
	[2263] = true,
	[18805] = true,
	[18806] = true,
	[18807] = true,
}
function IsMudraSkill(skillID)
	local id = tonumber(skillID)
	
    if (mudras[id]) then
        return true
    end
    return false
end
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
function IsNinjutsuSkill(skillID)
	local id = tonumber(skillID)
	

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
	local head = IsNull(ConvertHeading(heading),0)
	local newX = distance * math.sin(head) + startPos.x
	local newZ = distance * math.cos(head) + startPos.z
	return {x = newX, y = startPos.y, z = newZ}
end

-- Delegated to FFXIVLib.API.Fate.GetActiveFateById via lib_fate.lua
-- GetFateByID is now a global alias set in lib_fate.lua
-- Delegated to FFXIVLib.API.Fate.GetApprovedFates via lib_fate.lua
-- GetApprovedFates is now a global alias set in lib_fate.lua
-- Delegated to FFXIVLib.API.Fate.IsFateApproved via lib_fate.lua
-- IsFateApproved is now a global alias set in lib_fate.lua
-- Delegated to FFXIVLib.API.Fate.IsInsideFate via lib_fate.lua
-- IsInsideFate is now a global alias set in lib_fate.lua
-- Delegated to FFXIVLib.API.Fate.GetClosestFate via lib_fate.lua
-- GetClosestFate is now a global alias set in lib_fate.lua

function IsOnMap(mapid)
	local mapid = tonumber(mapid)
	if (Player.localmapid == mapid) then
		return true
	end
	
	return false
end
function FilterEntityListByIcon(elist,whitelist,blacklist)
	local returnables = {}
	if (not table.valid(elist)) then
		return returnables
	end
	if (whitelist and IsNull(whitelist,"") ~= "") then
		for iconid in StringSplit(whitelist,",") do
			for i,e in pairs(elist) do
				if (tostring(e.iconid) == tostring(iconid)) then
					returnables[i] = e
				end
			end
		end
	elseif (blacklist and IsNull(blacklist,"") ~= "") then
		returnables = elist
		for iconid in StringSplit(blacklist,",") do
			for i,e in pairs(returnables) do
				if (tostring(e.iconid) == tostring(iconid)) then
					returnables[i] = nil
				end
			end
		end
	else
		return elist
	end
	
	return returnables
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
	if not (pos1 and pos1.x and pos1.y and pos1.z) then return nil end
	if not (pos2 and pos2.x and pos2.y and pos2.z) then return nil end
	local threshold = IsNull(threshold,100)

	local dist = math.distance3d(pos1,pos2)
	if (dist < threshold) then
		--local path = NavigationManager:MoveTo(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z) -- this does something else in addition to path
		local _t0 = os.clock() * 1000
		local path = NavigationManager:GetPath(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z)
		local _dt = os.clock() * 1000 - _t0
		if (_dt > 1) then
			d("[QPerf] GetPathDistance->GetPath: " .. string.format("%.2f", _dt) .. "ms eucl=" .. string.format("%.1f", dist))
		end
		if (table.valid(path)) then
			local pathdist = PathDistance(path)
			if (table.valid(pathdist)) then
				dist = pathdist
			end
		end
	end

	return dist
end
-- Non-blocking variant. Returns (distance, resolved).
-- resolved=true means navmesh distance (or beyond threshold). resolved=false means Euclidean estimate, async pending.
function GetPathDistanceAsync(pos1,pos2,threshold)
	assert(pos1 and pos1.x and pos1.y and pos1.z,"First argument to GetPathDistanceAsync is invalid.")
	assert(pos2 and pos2.x and pos2.y and pos2.z,"Second argument to GetPathDistanceAsync is invalid.")
	local threshold = IsNull(threshold,100)
	
	local dist = math.distance3d(pos1,pos2)
	if (dist < threshold) then
		local result = NavigationManager:GetPathAsync(pos1.x,pos1.y,pos1.z,pos2.x,pos2.y,pos2.z)
		if (type(result) == "table" and table.valid(result)) then
			-- Path table returned from cache — extract distance from first node
			if (result[1] and result[1].pathdistance) then
				return result[1].pathdistance, true
			end
			local pathdist = PathDistance(result)
			if (table.valid(pathdist)) then
				return pathdist, true
			end
		elseif (type(result) == "number" and result <= 0) then
			-- Cached path failure (unreachable): resolved but no valid path
			return nil, true
		end
		-- result is positive integer (cacheID, request enqueued) or nil — return Euclidean estimate
		return dist, false
	end
	
	return dist, true
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
	for i,m in pairs(EntityList.myparty) do
		if m.isleader then
			return m.id == Player.id
		end
	end
		
    return false
end
function GetPartyLeader()
	if (gBotMode == "partyMode" and not gPartyGrindUsePartyLeader) then
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
						return member, false
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
					break
				end
			end
		end
		
		if (leader) then
			local entity = EntityList:Get(leader.id)
			if (entity and entity.id ~= 0) then
				return entity, true
			end
			return leader, false
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
-- for quests that force the user into a specific action set
function IsImpersonating() 
	return HasBuffs(Player,"1534,2760")
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
	if (gBotMode == "dutyMode") then
		return true
	elseif (gBotMode == "gatherMode") then
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
	
	local impersonating = IsImpersonating() 
	local attackRange = ml_global_information.AttackRange
	if (impersonating) then
		attackRange = 3
	end	
	if (target.distance2d ~= 0 and target.distance2d <= (attackRange * .97)) then
		if (not impersonating) then
			local check = SkillMgr.CheckTestSkill(Player.job, target)
			if (check ~= nil) then
				return check
			end
		end
		
		return (target.los or target.los2)
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
		In(itemid,19770,24794,26744,26745,33611,36612,39591) or
		In(itemid,43556,43557,46185))
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
	-- Support entity tables (trust NPCs have no valid jobID)
	if (type(jobID) == "table") then
		local cid = jobID.contentid
		if (cid) then
			if (ff.trust_tanks[cid]) then return GetString("tank") end
			if (ff.trust_healers[cid]) then return GetString("healer") end
			if (ff.trust_dps[cid]) then return GetString("dps") end
		end
		jobID = jobID.job or 0
	end
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
		jobID == FFXIV.JOBS.BLUEMAGE or
		jobID == FFXIV.JOBS.REAPER or
		jobID == FFXIV.JOBS.VIPER or
		jobID == FFXIV.JOBS.PICTOMANCER
    then
        return GetString("dps")
    elseif
        jobID == FFXIV.JOBS.CONJURER or
        jobID == FFXIV.JOBS.SCHOLAR or
        jobID == FFXIV.JOBS.WHITEMAGE or
		jobID == FFXIV.JOBS.ASTROLOGIAN or
		jobID == FFXIV.JOBS.SAGE
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
			[FFXIV.JOBS.REAPER] = true,
			[FFXIV.JOBS.VIPER] = true,
			[FFXIV.JOBS.PICTOMANCER] = true,
		}
	elseif (rolestring == "Healer") then
		return {
			[FFXIV.JOBS.CONJURER] = true,
			[FFXIV.JOBS.SCHOLAR] = true,
			[FFXIV.JOBS.WHITEMAGE] = true,
			[FFXIV.JOBS.ASTROLOGIAN] = true,
			[FFXIV.JOBS.SAGE] = true,
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
			[FFXIV.JOBS.SAGE] = true,
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
			[FFXIV.JOBS.REAPER] = true,
			[FFXIV.JOBS.VIPER] = true,
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
			[FFXIV.JOBS.PICTOMANCER] = true,
		}
	end
	return nil
end
function IsMeleeDPS(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
		if (ff.trust_melee_dps[var.contentid]) then return true end
	elseif (type(var) == "number") then
		jobid = var
	end
	
	return 	(jobid == FFXIV.JOBS.MONK or
			jobid == FFXIV.JOBS.PUGILIST or
			jobid == FFXIV.JOBS.DRAGOON or
			jobid == FFXIV.JOBS.LANCER or
			jobid == FFXIV.JOBS.ROGUE or
			jobid == FFXIV.JOBS.NINJA or 
			jobid == FFXIV.JOBS.SAMURAI or
			jobid == FFXIV.JOBS.REAPER or
			jobid == FFXIV.JOBS.VIPER)
end
function IsRangedDPS(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
		local cid = var.contentid
		if (ff.trust_phys_ranged_dps[cid] or ff.trust_caster_dps[cid]) then return true end
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
			jobid == FFXIV.JOBS.BLUEMAGE or
			jobid == FFXIV.JOBS.PICTOMANCER)
end
function IsRanged(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
		local cid = var.contentid
		if (ff.trust_phys_ranged_dps[cid] or ff.trust_caster_dps[cid] or ff.trust_healers[cid]) then return true end
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
			jobid == FFXIV.JOBS.SAGE or
			jobid == FFXIV.JOBS.MACHINIST or
			jobid == FFXIV.JOBS.REDMAGE or
			jobid == FFXIV.JOBS.BLUEMAGE or
			jobid == FFXIV.JOBS.PICTOMANCER)
end
function IsPhysicalDPS(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
		local cid = var.contentid
		if (ff.trust_melee_dps[cid] or ff.trust_phys_ranged_dps[cid]) then return true end
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
			jobid == FFXIV.JOBS.MACHINIST or
			jobid == FFXIV.JOBS.REAPER or
			jobid == FFXIV.JOBS.VIPER)
end
function IsCasterDPS(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
		if (ff.trust_caster_dps[var.contentid]) then return true end
	elseif (type(var) == "number") then
		jobid = var
	end

	return 	(jobid == FFXIV.JOBS.ARCANIST or
			jobid == FFXIV.JOBS.BLACKMAGE or
			jobid == FFXIV.JOBS.SUMMONER or
			jobid == FFXIV.JOBS.THAUMATURGE or
			jobid == FFXIV.JOBS.REDMAGE or 
			jobid == FFXIV.JOBS.BLUEMAGE or
			jobid == FFXIV.JOBS.PICTOMANCER)
end
function IsCaster(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
		local cid = var.contentid
		if (ff.trust_caster_dps[cid] or ff.trust_healers[cid]) then return true end
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
			jobid == FFXIV.JOBS.BLUEMAGE or
			jobid == FFXIV.JOBS.SAGE or
			jobid == FFXIV.JOBS.PICTOMANCER)
end
function IsHealer(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
		if (ff.trust_healers[var.contentid]) then return true end
	elseif (type(var) == "number") then
		jobid = var
	end

	return 	(jobid == FFXIV.JOBS.WHITEMAGE or
			jobid == FFXIV.JOBS.CONJURER or
			jobid == FFXIV.JOBS.SCHOLAR or 
			jobid == FFXIV.JOBS.ASTROLOGIAN or
			jobid == FFXIV.JOBS.SAGE)
end
function IsTank(var)
	local var = IsNull(var,Player)
	local jobid;
	if (type(var) == "table") then
		jobid = var.job or 0
		if (ff.trust_tanks[var.contentid]) then return true end
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
	if jobID ~= nil and (jobID >= 16 and jobID <= 17) then
		return true
	end
	
	return false
end
function IsFighter(jobID)
	local jobID = tonumber(jobID)
	if jobID ~= nil and ((jobID >= 0 and jobID <= 7) or (jobID >= 19)) then
		return true
	end
	
	return false
end
function IsCrafter(jobID)
	local jobID = tonumber(jobID)
	if jobID ~= nil and (jobID >= 8 and jobID <= 15) then
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
-- Returns the game's aetheryte list, optionally filtered by attunement.
-- force: boolean - force refresh the cache
-- attunementFlag: 0 or nil = all, 1 = unlocked only, 2 = locked only
-- Returns: { [index] = aetheryte, ... }
function GetAetheryteList(force, attunementFlag)
	
	--return Player:GetAetheryteList()
	local force = IsNull(force,false)
	attunementFlag = IsNull(attunementFlag, 0)
	if attunementFlag == true then attunementFlag = 1
	elseif attunementFlag == false then attunementFlag = 2 end
	
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
	
	if attunementFlag == 0 then
		return ml_global_information.Player_Aetherytes
	end
	
	local result = {}
	local list = ml_global_information.Player_Aetherytes
	if (table.valid(list)) then
		for _, aetheryte in pairs(list) do
			if (attunementFlag == 1 and aetheryte.isattuned)
				or (attunementFlag == 2 and not aetheryte.isattuned) then
				table.insert(result, aetheryte)
			end
		end
	end
	return result
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
	if force then GetAetheryteList(true) end
	return FFXIVLib.API.Map.GetAetherytes(1)
end
function GetUnattunedAetheryteList()
	local aethList = {}
	local dict = FFXIVLib.API.Map.GetAethernetDictionary()
	if not dict then return aethList end

	for aethId, row in pairs(dict) do
		if row.IsAetheryte == true and FFXIVLib.API.Map.CanAttuneAetheryte(row) then
			-- Remap new field names to old-compatible shape
			aethList[aethId] = {
				aethid = aethId,
				id = row.TerritoryId or row.territory,
				x = row.WorldX,
				y = row.WorldY,
				z = row.WorldZ,
				IsAetheryte = true,
			}
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

-- Quest unlock overrides for aether currents gated behind content
-- that the data tables don't reflect. Key = EObjId, Value = QuestId.
local AetherCurrentQuestOverrides = {
	-- Coerthas Western Highlands (401)
	[2006228] = 1643,
	[2006229] = 1643,
	[2006231] = 1643,
	[2006234] = 1643,
	-- The Fringes (612)
	[2007967] = 2530,
	[2007971] = 2530,
	[2007972] = 2530,
	-- The Ruby Sea (613)
	[2008004] = 2484,
	-- The Peaks (620)
	[2007981] = 2534,
	[2007984] = 2537,
	-- The Lochs (621)
	[2007994] = 2550,
	-- Yanxia (622)
	[2008019] = 2507,
	-- Il Mheg (814)
	[2010041] = 3634,
	[2010042] = 3634,
	-- Ahm Araeng (815)
	[2010050] = 3609,
	[2010052] = 3619,
	-- The Rak'tika Greatwood (816)
	[2010059] = 3313,
	[2010062] = 3313,
	[2010063] = 3313,
	-- Amh Araeng (817)
	[2010069] = 3334,
	[2010073] = 3334,
	-- The Tempest (818)
	[2010083] = 3651,
	-- Thavnair (956)
	[2011985] = 4441,
	[2011986] = 4441,
	-- Garlemald (957)
	[2011995] = 4412,
	[2011996] = 4412,
	-- Mare Lamentorum (959)
	[2012010] = 4400,
	[2012011] = 4400,
	[2012012] = 4400,
	[2012013] = 4400,
	-- Elpis (961)
	[2012020] = 4421,
	[2012021] = 4421,
	[2012025] = 4433,
	[2012026] = 4429,
	-- Ultima Thule (960)
	[2012030] = 4455,
	[2012031] = 4455,
	[2012032] = 4459,
	[2012033] = 4459,
	-- Urqopacha (1187)
	[2013929] = 4889,
	[2013930] = 4889,
	[2013931] = 4889,
	[2013932] = 4889,
	[2013933] = 4889,
	-- Kozama'uka (1188)
	[2013940] = 4879,
	[2013941] = 4879,
	[2013942] = 4879,
	[2013943] = 4879,
	-- Yak T'el (1189)
	[2013949] = 4903,
	[2013950] = 4903,
	[2013951] = 4903,
	[2013952] = 4903,
	[2013953] = 4903,
	-- Living Memory (1192)
	[2013974] = 4949,
	[2013975] = 4951,
	[2013976] = 4949,
	[2013977] = 4951,
	[2013978] = 4951,
	[2013979] = 4953,
	[2013980] = 4956,
	[2013981] = 4953,
	[2013982] = 4953,
	[2013983] = 4956,
}

function GetUnattunedCurrents()
	if not QuestCompleted(1597) then
		return nil
	end

	local currents = FFXIVLib.API.AetherCurrent.GetAetherCurrentsByTerritoryId(Player.localmapid)
	if not currents then return nil end

	local attunedStatus = GetAetherCurrentData(Player.localmapid)
	local currentList = {}

	for i = 1, #currents do
		local row = currents[i]

		-- Skip if already attuned (SlotIndex matches the old "id" field)
		if attunedStatus[row.SlotIndex] == true then
			-- already attuned, skip
		-- Skip if no world position (quest-only currents without a field object)
		elseif not row.EObjId or not row.WorldX then
			-- no field object, skip
		-- Check quest gate
		elseif row.QuestId and row.QuestId > 0 and not QuestCompleted(row.QuestId) then
			-- quest not completed, skip
		-- Check quest override gate
		elseif AetherCurrentQuestOverrides[row.EObjId] and not QuestCompleted(AetherCurrentQuestOverrides[row.EObjId]) then
			-- quest override not completed, skip
		else
			-- Return in old-compatible shape: keyed by EObjId (old "aethid")
			currentList[row.EObjId] = {
				id = row.SlotIndex,
				aethid = row.EObjId,
				x = row.WorldX,
				y = row.WorldY,
				z = row.WorldZ,
			}
		end
	end

	return currentList
end

function GetHomepoint()
	local homepoint = 0
	
	local list = FFXIVLib.API.Map.GetAetherytes(1)
	if (table.valid(list)) then
		for _, aetheryte in pairs(list) do
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
	if not id then return false end
	local row = FFXIVLib.API.Map.GetAetheryteById(id)
	if not row then return false end
	return row.IsAetheryte == true
end

------------------------------------------------------------
-- Section-aware aetheryte selection overrides
--
-- Maps territory IDs to rules that override distance-based
-- aetheryte selection when the destination is in a specific
-- map section (terrain obstacles make closer aetheryte impractical).
--
-- Each rule: { sections = {sectionIds}, aethid = preferredId }
-- Or: { fn = function(section, pos) -> aethid|nil } for complex cases
------------------------------------------------------------
AETHERYTE_SECTION_OVERRIDES = {
	-- Eastern La Noscea: sections 1,3 -> Costa Del Sol (11); section 2 -> Wineport (12)
	[137] = {
		{ sections = {1, 3}, aethid = 11 },
		{ sections = {2},    aethid = 12 },
	},
	-- Sea of Clouds: section 2 -> Cloudtop (72); section 1 -> Ok'Zundu (73)
	[401] = {
		{ sections = {2}, aethid = 72 },
		{ sections = {1}, aethid = 73 },
	},
	-- Dravanian Forelands: section 1 -> Tailfeather (76); section 2 -> Anyx Trine (77)
	[398] = {
		{ sections = {1}, aethid = 76 },
		{ sections = {2}, aethid = 77 },
	},
	-- Yanxia: section 1 -> Namai (107); section 2 -> House of the Fierce (108)
	[614] = {
		{ sections = {1}, aethid = 107 },
		{ sections = {2}, aethid = 108 },
	},
	-- Kholusia: section 2 -> Tomra (139)
	[814] = {
		{ sections = {2}, aethid = 139 },
	},
	-- Labyrinthos: section 2 -> Hamlet (167); section 3 -> Aporia (168)
	[956] = {
		{ sections = {2}, aethid = 167 },
		{ sections = {3}, aethid = 168 },
	},
	-- Thavnair: section 2 -> Palaka's Stand (171)
	[957] = {
		{ sections = {2}, aethid = 171 },
	},
	-- Ultima Thule: section 2 -> Abode of the Ea (180); sections 3,4,5 -> Base Omicron (181)
	[960] = {
		{ sections = {2},       aethid = 180 },
		{ sections = {3, 4, 5}, aethid = 181 },
	},
	-- Urqopacha: section 2 -> Wolar's Echo (201)
	[1187] = {
		{ sections = {2}, aethid = 201 },
	},
	-- Kozama'uka: section 1 -> Ok'hanu (202);
	-- section 2 + pos.x > 0 -> Many Fires (203); section 2 (else) -> Earthenshire (204)
	[1188] = {
		{ sections = {1}, aethid = 202 },
		{ fn = function(section, pos)
			if section == 2 then
				if pos.x > 0 then return 203 end
				return 204
			end
		end },
	},
	-- Yak T'el: sections 2,3 -> Mamook (206); section 1 + pos.x > 0 + pos.z > 300 -> Mamook (206)
	[1189] = {
		{ fn = function(section, pos)
			if In(section, 2, 3) then return 206 end
			if section == 1 and pos.x > 0 and pos.z > 300 then return 206 end
		end },
	},
}

-- Aetherytes to always prefer regardless of distance (workarounds)
AETHERYTE_ALWAYS_PREFER = {
	[958] = 172, -- Garlemald: always Camp Broken Glass (pathing issue exiting Tertium)
}

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
	-- DT path blocking
	if myMap == 1185 and (HasQuest(4879) or (QuestCompleted(4879) and not CanUseAetheryte(203))) then
		d("special path needed for Kozamauka Section 2")
		return nil
	end
	if myMap == 1188 and (HasQuest(4889) or (QuestCompleted(4889) and not CanUseAetheryte(201))) then
		d("special path needed for Uyuypoga Section 2")
		return nil
	end
	
	-- assign map for special paths
	if (mapid == 815 and GetMapSection(815, pos) == 1) and (HasQuest(3609) or (QuestCompleted(3609) and not CanUseAetheryte(141))) then
		mapid = 813
	end
	if ((myMap == 614 and GetMapSection(614, Player.pos) == 2) or (myMap == 622)) and HasQuest(2518) then
		return nil
	end
	if (((mapid == 614 and GetMapSection(614, pos) == 2) or (myMap == 614 and GetMapSection(614, Player.pos) == 1)) and HasQuest(2518)) then
		mapid = 622
	end
	-- DT Teleports
	-- Kozamauka Section 2
	if (mapid == 1188 and GetMapSection(1188, pos) == 2) and (HasQuest(4879) or (QuestCompleted(4879) and not CanUseAetheryte(203))) then
		mapid = 1185
	end
	
	-- Uyuypoga Section 2
	if (mapid == 1187 and GetMapSection(1187, pos) == 2) and (HasQuest(4889) or (QuestCompleted(4889) and not CanUseAetheryte(201))) then
		mapid = 1188
	end
	-- Main hall
	if (mapid == 987 and myMap ~= 962) then
		mapid = 962
	end


	-- Section-aware aetheryte overrides: (mapId → section → preferred aethid)
	-- For zones where terrain makes straight-line distance misleading.
	local sectionOverride = AETHERYTE_SECTION_OVERRIDES[mapid]

	local list = FFXIVLib.API.Map.GetAetherytes(1)
	if (table.valid(list)) then
		-- Build list of affordable, unlocked aetherytes on this map
		local candidates = {}
		for _, aetheryte in pairs(list) do
			if aetheryte.territory == mapid and GilCount() >= aetheryte.price and IsAetheryte(aetheryte.id) then
				candidates[#candidates+1] = aetheryte
			end
		end

		if #candidates == 0 then
			return nil
		end

		-- No destination position: return first available
		if not pos then
			return candidates[1]
		end

		-- Single candidate: return it
		if #candidates == 1 then
			return candidates[1]
		end

		-- Check section-aware override first
		if sectionOverride then
			local section = GetMapSection(mapid, pos)
			if section and section > 0 then
				-- Check override functions (Kozama'uka, Yak T'el special cases)
				for _, rule in ipairs(sectionOverride) do
					if rule.fn then
						local overrideId = rule.fn(section, pos)
						if overrideId then
							for _, c in ipairs(candidates) do
								if c.id == overrideId then return c end
							end
						end
					elseif rule.sections and rule.aethid then
						if In(section, unpack(rule.sections)) then
							for _, c in ipairs(candidates) do
								if c.id == rule.aethid then return c end
							end
						end
					end
				end
			end
		end

		-- Always-prefer override (Garlemald pathing workaround)
		local alwaysPrefer = AETHERYTE_ALWAYS_PREFER[mapid]
		if alwaysPrefer then
			for _, c in ipairs(candidates) do
				if c.id == alwaysPrefer then return c end
			end
		end

		-- Distance-based fallback: pick closest aetheryte to destination
		local best = nil
		local bestDist = math.huge
		local aethData = FFXIVLib.API.Map.GetAetherytesByMapId(mapid)
		for _, c in ipairs(candidates) do
			local row = aethData and aethData[c.id]
			local dist
			if row and row.WorldX and row.WorldZ then
				dist = Distance2D(pos.x, pos.z, row.WorldX, row.WorldZ)
			else
				-- Fallback to game aetheryte pos
				dist = Distance2D(pos.x, pos.z, c.pos and c.pos.x or 0, c.pos and c.pos.z or 0)
			end
			if dist < bestDist then
				best = c
				bestDist = dist
			end
		end

		return best
	else
		--d("No attuned aetherytes found.")
	end
	
	return nil
end
function GetAetheryteLocation(id)
	local aethid = tonumber(id) or 0
	if aethid == 0 then return nil end
	local row = FFXIVLib.API.Map.GetAetheryteById(aethid)
	if not row then return nil end
	return {x = row.WorldX, y = row.WorldY, z = row.WorldZ}
end
function CanUseAetheryte(aethid)
	local aethid = tonumber(aethid) or 0
	if (aethid ~= 0) then
		local list = FFXIVLib.API.Map.GetAetherytes(1)
		if (table.valid(list)) then
			for _, aetheryte in pairs(list) do
				if (aetheryte.id == aethid) then
					if (GilCount() >= aetheryte.price and IsAetheryte(aethid)) then
						return true
					end
				end
			end
		end
	end
	
	return false
end
function GetOffMapMarkerList(strMeshName, strMarkerType)
	return nil
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
    local excludeString = ml_blacklist and ml_blacklist.GetExcludeString(GetString("monsters")) or nil
    
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
	if (hqid == 0) then return 0 end

	local includehq = false
	if (type(inventoriesArg) == "boolean") then
		includehq = inventoriesArg
	end
	if (type(includehqArg) == "boolean") then
		includehq = includehqArg
	end

	-- includehq=true: NQ+HQ combined (C++ GetItemCount matches by base ID, returns NQ+HQ)
	if (includehq) then
		d("ItemCount debug: counting NQ+HQ for base ID "..tostring(hqid))
		return Inventory:GetItemCount(hqid)
	end

	-- HQ-offset ID (1000000 <= hqid < 1500000): count only HQ items for that base ID
	if (hqid >= 1000000 and hqid < 1500000) then
		d("ItemCount debug: counting HQ for base ID "..tostring(hqid - 1000000))
		return Inventory:GetItemCountHQ(hqid - 1000000)
	end

	-- Collectable-offset ID (500000 <= hqid < 1000000): count collectable items via C++
	if (hqid >= 500000 and hqid < 1000000) then
		d("ItemCount debug: counting collectables for base ID "..tostring(hqid - 500000))
		return Inventory:GetItemCountCollectable(hqid - 500000)
	end

	-- Default: NQ-only count by base ID via C++ (subtract HQ to match original hqid-based semantics)
	local total = Inventory:GetItemCount(hqid)
	local hqCount = Inventory:GetItemCountHQ(hqid)
	d("ItemCount debug: total="..tostring(total)..", hqCount="..tostring(hqCount))

	return total - hqCount
end

function ItemCounts(hqids,inventoriesArg,includehqArg)
	local hqids = IsNull(hqids,{})

	local includehq = false
	if (type(inventoriesArg) == "boolean") then
		includehq = inventoriesArg
	end
	if (type(includehqArg) == "boolean") then
		includehq = includehqArg
	end

	local returnables = {}

	if (not table.isa(hqids)) then
		return returnables
	end

	-- Separate IDs by type for appropriate C++ dispatch
	local baseIds = {}
	local hqIds = {}
	local collectableIds = {}

	for i = 1,#hqids do
		local hqid = hqids[i]
		if (hqid >= 1000000 and hqid < 1500000) then
			hqIds[#hqIds + 1] = hqid
		elseif (hqid >= 500000 and hqid < 1000000) then
			collectableIds[#collectableIds + 1] = hqid
		else
			baseIds[#baseIds + 1] = hqid
		end
	end

	-- Batch count base IDs via C++ (single pass through all bags)
	if (#baseIds > 0) then
		local idTable = {}
		for i = 1,#baseIds do
			idTable[baseIds[i]] = true
		end
		local counts = Inventory:GetItemCounts(idTable)
		if (counts) then
			for i = 1,#baseIds do
				local id = baseIds[i]
				local count = counts[id] or 0
				if (includehq) then
					-- GetItemCounts returns NQ+HQ combined (by base ID), which is what includehq wants
					returnables[id] = { id = id, count = count }
				else
					-- NQ only: subtract HQ count
					local hqCount = Inventory:GetItemCountHQ(id)
					returnables[id] = { id = id, count = count - hqCount }
				end
			end
		end
	end

	-- HQ offset IDs: use C++ GetItemCountHQ
	for i = 1,#hqIds do
		local hqid = hqIds[i]
		local baseId = hqid - 1000000
		local count = Inventory:GetItemCountHQ(baseId)
		returnables[hqid] = { id = hqid, count = count }
	end

	-- Collectable offset IDs: use C++ GetItemCountCollectable
	for i = 1,#collectableIds do
		local hqid = collectableIds[i]
		local baseId = hqid - 500000
		local count = Inventory:GetItemCountCollectable(baseId)
		returnables[hqid] = { id = hqid, count = count }
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
		or IsControlOpen("ShopCard") or IsControlOpen("ShopExchangeCoin") or IsControlOpen("InclusionShop"))
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
	if not memoize.questList then
		local list = Quest:GetQuestList()
		memoize.questList = list or false
	end
	local list = memoize.questList
	if list and table.valid(list) then
		return list[questID]
	end
end
function IsLimsa(mapid)
	local mapid = tonumber(mapid)
	return (mapid == 128 or mapid == 129)
end
function IsUldah(mapid)
	local mapid = tonumber(mapid)
	return (mapid == 130 or mapid == 131)
end
function IsGridania(mapid)
	local mapid = tonumber(mapid)
	return (mapid == 132 or mapid == 133)
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

    [1032] = true, -- ???, The Palaistra
    [1033] = true, -- ???, The Volcanic Heart
    [1034] = true, -- ???, Cloud Nine
    
    [1058] = true, -- ???, The Palaistra
    [1059] = true, -- ???, The Volcanic Heart
    [1060] = true, -- ???, Cloud Nine
	
    [1116] = true, -- ???, Clockwork Castletown
    [1117] = true, -- ???, Clockwork Castletown

    [1138] = true, -- The Red Sands
    [1139] = true, -- The Red Sands
    
    [1273] = true, -- secure frontline

	[1293] = true, -- ???, ウルヴズジェイル, The Bayside Battleground
    [1294] = true, -- ???, ウルヴズジェイル, The Bayside Battleground

	[1313] = true, -- worqor chirteh (triumph)
}
function IsPVPMap(mapid)
    local mapid = tonumber(mapid) or Player.localmapid
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

local _canAccessMapCache = {}
local _canAccessMapCacheTime = 0

-- BFS that walks the nav graph (Lua side) and only follows edges
-- where at least one entry satisfies its requirements.
local function _canTraverseNavPath(fromMap, toMap)
	if fromMap == toMap then return true end
	local navData = ffxiv_map_nav and ffxiv_map_nav.data
	if not navData then navd("[BFS] no navData"); return false end
	if not navData[fromMap] then
		navd("[BFS] missing source node: " .. tostring(fromMap))
		return false
	end

	navd("[BFS] start " .. fromMap .. " -> " .. toMap)
	local visited = { [fromMap] = true }
	local parent = {}
	local queue = { fromMap }
	local head = 1
	while head <= #queue do
		local current = queue[head]
		head = head + 1
		if current == toMap then
			-- reconstruct path for debug
			local path = { toMap }
			local node = toMap
			while parent[node] do
				node = parent[node]
				path[#path + 1] = node
			end
			-- reverse
			local pathStr = ""
			for i = #path, 1, -1 do
				pathStr = pathStr .. tostring(path[i])
				if i > 1 then pathStr = pathStr .. " -> " end
			end
			navd("[BFS] FOUND path: " .. pathStr)
			return true
		end
		local neighbors = navData[current]
		if neighbors then
			for nid, entries in pairs(neighbors) do
				if not visited[nid] and type(entries) == "table" and #entries > 0 then
					local anyValid = false
					local blockReason = nil
					for ei, entry in ipairs(entries) do
						if not entry.requires then
							anyValid = true
							navd("[BFS]   " .. current .. " -> " .. nid .. " entry#" .. ei .. " NO requires (pass)")
							break
						end
						local allPass = true
						local failedReq = nil
						for req, val in pairs(entry.requires) do
							local ok, ret = LoadString("return " .. req)
							if ok and ret ~= nil and ret ~= val then
								allPass = false
								failedReq = req .. "=" .. tostring(ret) .. " want=" .. tostring(val)
								break
							end
						end
						if allPass then
							anyValid = true
							navd("[BFS]   " .. current .. " -> " .. nid .. " entry#" .. ei .. " requires MET")
							break
						else
							blockReason = failedReq
						end
					end
					if anyValid then
						visited[nid] = true
						parent[nid] = current
						queue[#queue + 1] = nid
					else
						navd("[BFS]   " .. current .. " -> " .. nid .. " BLOCKED (" .. tostring(blockReason) .. ")")
					end
				end
			end
		end
	end
	navd("[BFS] NO path " .. fromMap .. " -> " .. toMap .. " visited " .. TableSize(visited) .. " nodes")
	return false
end

local function _CanAccessMapImpl(mapid)
	if (mapid ~= 0) then
		if (Player.localmapid ~= mapid) then
			local ppos = Player.pos
			local srcMap = Player.localmapid

			local pos = ml_nav_manager.GetNextPathPos(	ppos,
														srcMap,
														mapid	)
			if (table.valid(pos)) then
				if _canTraverseNavPath(srcMap, mapid) then
					return true
				end
			else
				-- GetNextPathPos failed but BFS may still find a traversable path
				if _canTraverseNavPath(srcMap, mapid) then
					return true
				end
			end
			
			local attunedAetherytes = FFXIVLib.API.Map.GetAetherytes(1)
			for _, aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.territory == mapid and GilCount() >= aetheryte.price) then
					return true
				end
			end
			
			local nearestAetheryte = GetAetheryteByMapID(mapid)
			if (nearestAetheryte) then
				if (GilCount() >= nearestAetheryte.price) then
					return true
				end
			end
			
			-- Fall back check to see if we can get to EL, and from there to the destination.
			for k,aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.id == 134 and GilCount() >= aetheryte.price) then
					local aethPos = {x = 0, y = 82, z = 0}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,820,mapid)
					if (table.valid(backupPos)) and _canTraverseNavPath(820, mapid) then
						d("Found an attuned backup position aetheryte for mapid 1["..tostring(mapid).."].")
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
						if (table.valid(backupPos)) and _canTraverseNavPath(814, 820) then
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
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,819,mapid)
					if (table.valid(backupPos)) and _canTraverseNavPath(819, mapid) then
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
					if (table.valid(backupPos)) and _canTraverseNavPath(418, mapid) then
						return true
					end
				end
			end
			
			-- Fall back check to see if we can get to Idyllshire, and from there to the destination.
			for k,aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.id == 75 and GilCount() >= aetheryte.price) then
					local aethPos = {x = 66.53, y = 207.82, z = -26.03}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,478,mapid)
					if (table.valid(backupPos)) and _canTraverseNavPath(478, mapid) then
						return true
					end
				end
			end
			
			-- Fall back check to see if we can get to Kugane, and from there to the destination.
			for k,aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.id == 111 and GilCount() >= aetheryte.price) then
					local aethPos = {x = 45.89, y = 4.2, z = -40.59}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,628,mapid)
					if (table.valid(backupPos)) and _canTraverseNavPath(628, mapid) then
						d("Found an attuned backup position aetheryte for mapid 2["..tostring(mapid).."].")
						return true
					end
				end
			end
			-- Fall back check to see if we can get to Tuliyollal, and from there to the destination.
			for k,aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.id == 216 and GilCount() >= aetheryte.price) then
					local aethPos = {x = -24, y = 0, z = 7.5}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,1185,mapid)
					if (table.valid(backupPos)) and _canTraverseNavPath(1185, mapid) then
						d("Found an attuned backup position aetheryte for mapid 3["..tostring(mapid).."].")
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

function CanAccessMap(mapid)
	local mapid = tonumber(mapid) or 0
	
	local now = Now()
	if (now - _canAccessMapCacheTime) > 30000 then
		_canAccessMapCache = {}
		_canAccessMapCacheTime = now
	end
	local cached = _canAccessMapCache[mapid]
	if (cached ~= nil) then
		return cached
	end
	
	local ok, result = xpcall(function() return _CanAccessMapImpl(mapid) end, function(err)
		d("[Nav] _CanAccessMapImpl ERROR mapid=" .. tostring(mapid) .. ": " .. tostring(err))
		local tb = debug and debug.traceback and debug.traceback("", 2) or "no traceback"
		d("[Nav] traceback: " .. tostring(tb))
	end)
	if not ok then result = false end
	navd("[Nav] CanAccessMap(" .. tostring(mapid) .. ") = " .. tostring(result) .. " ok=" .. tostring(ok))
	_canAccessMapCache[mapid] = result
	return result
end

-- Legacy wrappers: delegate to data_map_sections via GetMapSection.
-- Kept for string-based condition references in data_nav / aethernet_dictionary.
function GetELNSection(pos) return GetMapSection(961, pos) end

function GetForelandsSection(pos) return GetMapSection(398, pos) end

function GetHinterlandsSection(pos) return GetMapSection(399, pos) end

function GetSeaOfCloudsSection(pos) return GetMapSection(401, pos) end

function GetFringeSection(pos) return GetMapSection(612, pos) end
function GetYanxiaSection(pos) return GetMapSection(614, pos) end

function GetPeaksSection(pos) return GetMapSection(620, pos) end

function GetLochsSection(pos) return GetMapSection(621, pos) end
function GetKholusiaSection(pos) return GetMapSection(814, pos) end

function GetAhmAraengSection(pos) return GetMapSection(815, pos) end

function GetTempestSection(pos) return GetMapSection(957, pos) end

function GetThavnairSection(pos) return GetMapSection(963, pos) end
function GetLabyrithosSection(pos) return GetMapSection(956, pos) end
function GetMareLamentorumSection(pos) return GetMapSection(959, pos) end
function GetUltimaThuleSection(pos) return GetMapSection(960, pos) end
function GetUyuypogaSection(pos) return GetMapSection(1187, pos) end

function GetKozamaukaSection(pos) return GetMapSection(1188, pos) end
function GetYakTelSection(pos) return GetMapSection(1189, pos) end

function GetLivingMemorySection(pos) return GetMapSection(1192, pos) end
-- Cosmic data now lives in FFXIVLib.API.CosmicExploration (data_cosmic.lua).
-- Local aliases kept so Transport1237/1291/1310 references still resolve.
local centerPoints = FFXIVLib.API.CosmicExploration.GetCenterPoints(1237)
local portalPositions = FFXIVLib.API.CosmicExploration.GetPortalPositions(1237)

local phaennaCenterPoints = FFXIVLib.API.CosmicExploration.GetCenterPoints(1291)
local phaennaPortalPositions = FFXIVLib.API.CosmicExploration.GetPortalPositions(1291)

local oizysCenterPoints = FFXIVLib.API.CosmicExploration.GetCenterPoints(1310)
local oizysPortalPositions = FFXIVLib.API.CosmicExploration.GetPortalPositions(1310)

function GetCosmicMoon(pos, closest)
	return FFXIVLib.API.CosmicExploration.GetSection(1237, pos, closest)
end

function CalcMoonTransport(pos1, pos2, pos1Section, pos2Section)
	return FFXIVLib.API.CosmicExploration.ShouldTransport(1237, pos1, pos2, pos1Section, pos2Section)
end

function CalcPhaennaTransport(pos1, pos2, pos1Section, pos2Section)
	return FFXIVLib.API.CosmicExploration.ShouldTransport(1291, pos1, pos2, pos1Section, pos2Section)
end
function GetPhaenna(pos, closest)
	return FFXIVLib.API.CosmicExploration.GetSection(1291, pos, closest)
end

function GetOizys(pos, closest)
	return FFXIVLib.API.CosmicExploration.GetSection(1310, pos, closest)
end

local _sectionFunctions = {
	[1237] = function(pos) return GetCosmicMoon(pos, true) end,
	[1291] = function(pos) return GetPhaenna(pos, true) end,
	[1310] = function(pos) return GetOizys(pos, true) end,
}

function GetMapSection(mapId, pos)
	local fn = _sectionFunctions[mapId]
	if fn then return fn(pos) end
	return FFXIVLib.API.Map.GetMapSection(mapId, pos)
end

function CalcOizysTransport(pos1, pos2, pos1Section, pos2Section)
	return FFXIVLib.API.CosmicExploration.ShouldTransport(1310, pos1, pos2, pos1Section, pos2Section)
end
function Transport1237(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	local pos1Section = GetCosmicMoon(pos1)
	local pos2Section = GetCosmicMoon(pos2,true)
	
	-- cosmoliner introduced map 3
	if ffxivminion.MoonMapVersion < 3 then
		return false
	end
	
	if In(pos1Section,1) then
		-- north
		if In(pos2Section,2,3,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 4.5, y = 3, z = -61}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(3.13)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- east
		if In(pos2Section,4,10) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 59, y = 3, z = 4.5}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(1.57)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- south
		if In(pos2Section,5,6,7,11,12,15,16,17) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -4.5, y = 3.025, z = 60}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(0.04)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- west
		if In(pos2Section,8,9,13,14) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -61, y = 3.3, z = -4.5}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-1.63)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,2) then
		-- south
		if In(pos2Section,1,6,12,15,16,17) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -19.2, y = 40, z = -404}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-1.6)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- east
		if In(pos2Section,3,4,5,10,11,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 18.3, y = 39.8, z = -395}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(1.55)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- west
		if In(pos2Section,7,8,9,13,14) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -19.2, y = 40, z = -404}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-1.6)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,3) then
		-- north
		if In(pos2Section,1,2,8,9,13,14) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 278, y = 42, z = -318}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-2.51)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- south
		if In(pos2Section,4,5,6,7,10,11,12,15,16,17) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 304, y = 42, z = -273}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(0.7)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- enter
		if In(pos2Section,23,24,25,26,27,28,29) and ffxivminion.MoonMapVersion >= 13 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 320, y = 42, z = -305}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(2.23)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,4) then
		-- west
		if In(pos2Section,1,8,9,13,14) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 379, y = 42, z = -4.5}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-1.55)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end
			end
		end
		-- north
		if In(pos2Section,2,3,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 404, y = 42, z = -19}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(3.13)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- east
		if In(pos2Section,10) and ffxivminion.MoonMapVersion >= 7 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 419, y = 42, z = 4.5}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(1.55)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- south
		if In(pos2Section,5,6,7,11,12,15,16,17) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 395, y = 42, z = 19}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-0.01)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,5) then
		-- north
		if In(pos2Section,1,2,3,4,10,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 297, y = 27, z = 268}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(2.31)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- south
		if In(pos2Section,11) and ffxivminion.MoonMapVersion >= 7 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 290, y = 27, z = 296}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(0.77)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- west
		if In(pos2Section,6,7,8,9,12,13,14,15,16,17) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 263, y = 27, z = 290}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-0.81)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,6) then
		-- north
		if In(pos2Section,1,2) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 4.4, y = 37, z = 379}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(3.1)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- east
		if In(pos2Section,3,4,5,10,11,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 21, y = 37, z = 404.5}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(1.54)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- south
		if In(pos2Section,12,15,16,17) and ffxivminion.MoonMapVersion >= 7 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -4, y = 37, z = 418}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-0.01)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- west
		if In(pos2Section,7,8,9,13,14) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -19, y = 37, z = 395}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-1.61)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,7) then
		-- north
		if In(pos2Section,1,2,3,8,9,13,14,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -290, y = 31, z = 263}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-2.35)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- south
		if In(pos2Section,4,5,6,10,11,12,15,16,17) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -269, y = 31, z = 296}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(0.79)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,8) then
		-- west
		if In(pos2Section,14) and ffxivminion.MoonMapVersion >= 6 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -291, y = 36, z = -297}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-2.36)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- north
		if In(pos2Section,1,2,3,4,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -263, y = 36, z = -290}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(2.33)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- south
		if In(pos2Section,5,6,7,9,10,11,12,13,15,16,17) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -297, y = 36, z = -269}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-0.8)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,9) then
		-- north
		if In(pos2Section,2,3,8,14,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -395, y = 38, z = -19}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(3.14)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- east
		if In(pos2Section,1,4,10) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -380, y = 38, z = 4.5}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(1.55)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- south
		if In(pos2Section,5,6,7,11,12,15,16,17) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -404, y = 38, z = 19}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-0.01)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- west
		if In(pos2Section,13) and ffxivminion.MoonMapVersion >= 6 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -419, y = 38, z = -4.5}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-1.59)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,10) and ffxivminion.MoonMapVersion >= 7 then
		-- west
		if In(pos2Section,1,2,3,4,5,6,7,8,9,10,13,14,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 724, y = 61, z = -8.5}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-1.57)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- south
		if In(pos2Section,11,12,15,16,17) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 739, y = 61, z = 15.5}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-0.04)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,11) and ffxivminion.MoonMapVersion >= 7 then
		-- east
		if In(pos2Section,10) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 443, y = 46, z = 500}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(2.34)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- north
		if In(pos2Section,1,2,3,4,5,6,7,8,9,13,14,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 416, y = 47, z = 493}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-2.36)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- south
		if In(pos2Section,12,15,16,17) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 410, y = 47, z = 521}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-0.79)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,12) and ffxivminion.MoonMapVersion >= 7 then
		-- north
		if In(pos2Section,1,2,3,6,7,8,9,13,14,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -95, y = 52, z = 730}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(3.12)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- east
		if In(pos2Section,4,5,10,11) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -80, y = 53, z = 754}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(1.55)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- into Tunnel
		if In(pos2Section,15,16,17) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -121, y = 54, z = 739}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-1.56)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,13) and ffxivminion.MoonMapVersion >= 6 then
		-- east
		if In(pos2Section,1,2,3,4,5,6,7,8,9,10,11,12,15,16,17,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -679, y = 62, z = 14.5}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(1.5)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- north
		if In(pos2Section,14) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -694, y = 62, z = -9.8}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(3.13)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,14) and ffxivminion.MoonMapVersion >= 6 then
		-- south
		if In(pos2Section,13) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -557, y = 61, z = -529}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-0.82)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- east
		if In(pos2Section,1,2,3,4,5,6,7,8,9,10,11,12,15,16,17,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -529, y = 61, z = -523}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(0.77)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- redundant check but here just as a note
	elseif In(pos1Section,15) and ffxivminion.MoonMapVersion >= 8 then
		-- out of tunnel
		if In(pos2Section,1,2,3,4,5,6,7,8,9,10,11,12,13,14,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -319, y = 54, z = 759}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(1.57)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- north
		if In(pos2Section,16) and ffxivminion.MoonMapVersion >= 9 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -335, y = 53, z = 730}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(3.12)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- west
		if In(pos2Section,17) and ffxivminion.MoonMapVersion >= 9 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -360, y = 53, z = 745}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-1.59)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,16) and ffxivminion.MoonMapVersion >= 9 then
		-- to tunnel exit
		if In(pos2Section,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -599, y = 53, z = 394}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(1.57)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- south
		if In(pos2Section,17) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -639, y = 53, z = 385}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-1.57)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,17) and ffxivminion.MoonMapVersion >= 9 then
		-- to tunnel exit
		if In(pos2Section,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,23,24,25,26,27,28,29) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -713, y = 93, z = 768}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(1.59)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- north
		if In(pos2Section,16) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = -729, y = 93, z = 743}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-3.13)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,23,24) then
		-- exit tunnel
		if In(pos2Section,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22) then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 391, y = -57, z = -395}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-0.89)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- further into nadir
		if In(pos2Section,25,26,27,28,29) and ffxivminion.MoonMapVersion >= 14 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 434, y = -57, z = -409}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(2.25)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,25) then
		-- to exit tunnel
		if In(pos2Section,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,24) and ffxivminion.MoonMapVersion >= 14 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 624, y = -72, z = -562}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-0.91)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- west
		if In(pos2Section,26) and ffxivminion.MoonMapVersion >= 14 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 625, y = -72, z = -582}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-2.48)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
		-- east
		if In(pos2Section,28) and ffxivminion.MoonMapVersion >= 14 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 651, y = -72, z = -552}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(0.64)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,26) then
		-- to exit tunnel
		if not In(pos2Section,26) and ffxivminion.MoonMapVersion >= 14 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 387, y = -117, z = -848}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(1.91)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,27) then
		-- to exit tunnel
		if not In(pos2Section,27) and ffxivminion.MoonMapVersion >= 14 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 645, y = -108, z = -925}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(0.87)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	elseif In(pos1Section,28) then
		-- to exit tunnel
		if not In(pos2Section,28) and ffxivminion.MoonMapVersion >= 14 then
			if CalcMoonTransport(pos1, pos2, pos1Section, pos2Section) then
				local portalPos = {x = 874, y = -55, z = -374}
				local distance = math.distance2d(pos1, portalPos)
				if distance > 2 then
					return true, function()
						local newTask = ffxiv_task_movetopos.Create()
						newTask.pos = portalPos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				else
					return true, function()
						Player:SetFacing(-2.3)
						Player:Move(FFXIV.MOVEMENT.FORWARD)
					end
				end 
			end
		end
	end 
	return false
end
function Transport1291(pos1, pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	local pos1Section = GetPhaenna(pos1)
	local pos2Section = GetPhaenna(pos2, true)
	
	-- Check if we're on the Phaenna map
	if Player.localmapid ~= 1291 then
		return false
	end
	
	-- cosmoliner introduced map 3
	if ffxivminion.PhaennaMapVersion < 3 then
		return false
	end
	
	-- Need valid sections
	if not pos1Section or pos1Section == 0 or not pos2Section or pos2Section == 0 then
		return false
	end
	
	-- Check map version requirements for specific sectors
	-- Sectors 19, 20, 21, 22 require version >= 9
	if In(pos1Section, 19, 20, 21, 22) or In(pos2Section, 19, 20, 21, 22) then
		if ffxivminion.PhaennaMapVersion < 9 then
			return false
		end
	end
	
	-- Sectors 23, 24 require version >= 15
	if In(pos1Section, 23, 24) or In(pos2Section, 23, 24) then
		if ffxivminion.PhaennaMapVersion < 15 then
			return false
		end
	end
	
	-- Same section, no transport needed
	if pos1Section == pos2Section then
		return false
	end
	
	-- Check if transport is beneficial
	if not CalcPhaennaTransport(pos1, pos2, pos1Section, pos2Section) then
		return false
	end
	
	-- Static format portal selection based on sections
	local portalData = nil
	
	if In(pos1Section, 1) then
		if In(pos2Section, 2) then
			portalData = phaennaPortalPositions[1] and phaennaPortalPositions[1]["1 North"]
		elseif In(pos2Section, 3,4,5) then
			portalData = phaennaPortalPositions[1] and phaennaPortalPositions[1]["1 East"]
		elseif In(pos2Section, 6,7,15,16,17,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[1] and phaennaPortalPositions[1]["1 South"]
		elseif In(pos2Section, 8,9,10,11,12,13,14) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[1] and phaennaPortalPositions[1]["1 West"]
		end
	elseif In(pos1Section, 2) then
		if In(pos2Section, 1,6,18,17,16) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[2] and phaennaPortalPositions[2]["2 South"]
		elseif In(pos2Section, 3, 4, 5) then
			portalData = phaennaPortalPositions[2] and phaennaPortalPositions[2]["2 East"]
		elseif In(pos2Section, 8,9,10,11,12,13,14,15) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[2] and phaennaPortalPositions[2]["2 West"]
		end
	elseif In(pos1Section, 3) then
		if In(pos2Section, 1,2,8,9,10,11,12) then
			portalData = phaennaPortalPositions[3] and phaennaPortalPositions[3]["3 North"]
		elseif In(pos2Section, 4,5,6,7,13,14,15,16,17,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15  then
			portalData = phaennaPortalPositions[3] and phaennaPortalPositions[3]["3 South"]
		end
	elseif In(pos1Section, 4) then
		-- add 4 west
		if In(pos2Section, 3,2,9) then
			portalData = phaennaPortalPositions[4] and phaennaPortalPositions[4]["4 North"]
		elseif In(pos2Section, 1,8,10,11,12,13,14) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15  then
			portalData = phaennaPortalPositions[4] and phaennaPortalPositions[4]["4 West"]
		elseif In(pos2Section, 5,6,7,15,16,17,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[4] and phaennaPortalPositions[4]["4 South"]
		end
	elseif In(pos1Section, 5) then
		if In(pos2Section, 1,2,3,4,8,9,10,11,12) then
			portalData = phaennaPortalPositions[5] and phaennaPortalPositions[5]["5 North"]
		elseif In(pos2Section, 6,7,13,14,15,16,17,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[5] and phaennaPortalPositions[5]["5 West"]
		end
	elseif In(pos1Section, 6) then
		if In(pos2Section, 1,2,3) then
			portalData = phaennaPortalPositions[6] and phaennaPortalPositions[6]["6 North"]
		elseif In(pos2Section, 4,5) then
			portalData = phaennaPortalPositions[6] and phaennaPortalPositions[6]["6 East"]
		elseif In(pos2Section, 7,8,9,10,11,12,13,14) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[6] and phaennaPortalPositions[6]["6 West"]
		elseif In(pos2Section, 15,16,17,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[6] and phaennaPortalPositions[6]["6 South"]
		end
	elseif In(pos1Section, 7) then
		if In(pos2Section, 1,2,3,4,5,6) then
			portalData = phaennaPortalPositions[7] and phaennaPortalPositions[7]["7 East"]
		elseif In(pos2Section, 8,9,10,11,12) then
			portalData = phaennaPortalPositions[7] and phaennaPortalPositions[7]["7 North"]
		elseif In(pos2Section, 14,13) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15  then
			portalData = phaennaPortalPositions[7] and phaennaPortalPositions[7]["7 West"]
		elseif In(pos2Section, 15,16,17,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[7] and phaennaPortalPositions[7]["7 South"]
		end
	elseif In(pos1Section, 8) then
		if In(pos2Section, 1,4,3,5) then
			portalData = phaennaPortalPositions[8] and phaennaPortalPositions[8]["8 East"]
		elseif In(pos2Section, 9,2) then
			portalData = phaennaPortalPositions[8] and phaennaPortalPositions[8]["8 North"]
		elseif In(pos2Section, 7,6,5,18,17,16,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[8] and phaennaPortalPositions[8]["8 South"]
		elseif In(pos2Section, 10,11,12,13,14,15) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[8] and phaennaPortalPositions[8]["8 West"]
		end
	elseif In(pos1Section, 9) then
		if In(pos2Section, 1,2,3,4,5,6,7) then
			portalData = phaennaPortalPositions[9] and phaennaPortalPositions[9]["9 East"]
		elseif In(pos2Section, 8,7,6,18,16,17,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[9] and phaennaPortalPositions[9]["9 South"]
		elseif In(pos2Section, 10,11,12,13,14,15) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[9] and phaennaPortalPositions[9]["9 West"]
		end
	elseif In(pos1Section, 10) then
		if In(pos2Section, 9,2,3) then
			portalData = phaennaPortalPositions[10] and phaennaPortalPositions[10]["10 North"]
		elseif In(pos2Section, 11,8,14,7,6,5,1,4,15,16,17,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[10] and phaennaPortalPositions[10]["10 South East"]
		elseif In(pos2Section, 12,13) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15  then
			portalData = phaennaPortalPositions[10] and phaennaPortalPositions[10]["10 South"]
		end
	elseif In(pos1Section, 11) then
		if In(pos2Section, 10) then
			portalData = phaennaPortalPositions[11] and phaennaPortalPositions[11]["11 North"]
		elseif In(pos2Section, 14,15,16,17,7,18,13) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[11] and phaennaPortalPositions[11]["11 South"]
		elseif In(pos2Section, 8,1,4,3,5,6,7) then
			portalData = phaennaPortalPositions[11] and phaennaPortalPositions[11]["11 East"]
		elseif In(pos2Section, 12) then
			portalData = phaennaPortalPositions[11] and phaennaPortalPositions[11]["11 West"]
		end
	elseif In(pos1Section, 12) then
		if In(pos2Section, 10,9,2) then
			portalData = phaennaPortalPositions[12] and phaennaPortalPositions[12]["12 North"]
		elseif In(pos2Section, 13) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[12] and phaennaPortalPositions[12]["12 South"]
		elseif In(pos2Section, 1,3,4,5,6,7,8,11,14,15,16,17,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[12] and phaennaPortalPositions[12]["12 East"]
		end
	elseif In(pos1Section, 13) then
		if In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[13] and phaennaPortalPositions[13]["13 South"]
		elseif In(pos2Section, 1,2,3,4,5,6,7,8,9,10,11,12) then
			portalData = phaennaPortalPositions[13] and phaennaPortalPositions[13]["13 West"]
		elseif In(pos2Section, 14,15,16,17,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[13] and phaennaPortalPositions[13]["13 East"]
		end
	elseif In(pos1Section, 14) then
		if In(pos2Section, 13) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[14] and phaennaPortalPositions[14]["14 West"]
		elseif In(pos2Section, 1,2,3,4,5,6) then
			portalData = phaennaPortalPositions[14] and phaennaPortalPositions[14]["14 North"]
		elseif In(pos2Section, 15,16,17,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[14] and phaennaPortalPositions[14]["14 South"]
		elseif In(pos2Section, 7,8,9,10,11,12) then
			portalData = phaennaPortalPositions[14] and phaennaPortalPositions[14]["14 East"]
		end
	elseif In(pos1Section, 15) then
		if In(pos2Section, 1,2,3,4,5,6,7,8,9,10,11,12,13,14) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[15] and phaennaPortalPositions[15]["15 North"]
		elseif In(pos2Section, 16) then
			portalData = phaennaPortalPositions[15] and phaennaPortalPositions[15]["15 South"]
		elseif In(pos2Section, 17,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[15] and phaennaPortalPositions[15]["15 East"]
		end
	elseif In(pos1Section, 16) then
		if In(pos2Section, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[16] and phaennaPortalPositions[16]["16 North"]
		elseif In(pos2Section, 17,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[16] and phaennaPortalPositions[16]["16 East"]
		end
	elseif In(pos1Section, 17) then
		if In(pos2Section, 1,2,3,4,5,6,7,8,9,10,11,18) or In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[17] and phaennaPortalPositions[17]["17 North"]
		elseif In(pos2Section, 16) then
			portalData = phaennaPortalPositions[17] and phaennaPortalPositions[17]["17 South"]
		elseif In(pos2Section, 12,13,14,15) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[17] and phaennaPortalPositions[17]["17 West"]
		end
	elseif In(pos1Section, 18) then
		if In(pos2Section, 1,2,3,4,5,6,8,9,10,11,12) then
			portalData = phaennaPortalPositions[18] and phaennaPortalPositions[18]["18 North"]
		elseif In(pos2Section, 15,17,16) then
			portalData = phaennaPortalPositions[18] and phaennaPortalPositions[18]["18 South"]
		elseif In(pos2Section, 7,14,13) or In(pos2Section, 23,24) and ffxivminion.PhaennaMapVersion >= 15 then
			portalData = phaennaPortalPositions[18] and phaennaPortalPositions[18]["18 West"]
		elseif In(pos2Section, 19,20,21,22) and ffxivminion.PhaennaMapVersion >= 9 then
			portalData = phaennaPortalPositions[18] and phaennaPortalPositions[18]["18 East"]
		end
	elseif In(pos1Section, 19) and ffxivminion.PhaennaMapVersion >= 9 then
		-- Section 19 portals (requires version >= 9)
		if In(pos2Section, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,23,24) then
			portalData = phaennaPortalPositions[19] and phaennaPortalPositions[19]["19 North"]
		elseif In(pos2Section, 20,21,22) then
			portalData = phaennaPortalPositions[19] and phaennaPortalPositions[19]["19 South"]
		end
	elseif In(pos1Section, 20) and ffxivminion.PhaennaMapVersion >= 9 then
		if In(pos2Section, 21,22) then
			portalData = phaennaPortalPositions[20] and phaennaPortalPositions[20]["20 West"]
		elseif In(pos2Section, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,23,24) then
			portalData = phaennaPortalPositions[20] and phaennaPortalPositions[20]["20 East"]
		end
	elseif In(pos1Section, 21) and ffxivminion.PhaennaMapVersion >= 9 then
		if In(pos2Section, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,23,24) then
			portalData = phaennaPortalPositions[21] and phaennaPortalPositions[21]["21 South"]
		elseif In(pos2Section, 22) then
			portalData = phaennaPortalPositions[21] and phaennaPortalPositions[21]["21 East"]
		end
	elseif In(pos1Section, 22) and ffxivminion.PhaennaMapVersion >= 9 then
		if In(pos2Section, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,23,24) then
			portalData = phaennaPortalPositions[22] and phaennaPortalPositions[22]["22 West"]
		end
	elseif In(pos1Section, 23) and ffxivminion.PhaennaMapVersion >= 15 then
		if In(pos2Section, 24) then
			portalData = phaennaPortalPositions[23] and phaennaPortalPositions[23]["23 South"]
		elseif In(pos2Section, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22) then
			portalData = phaennaPortalPositions[23] and phaennaPortalPositions[23]["23 North"]
		end
	elseif In(pos1Section, 24) and ffxivminion.PhaennaMapVersion >= 15 then
		if In(pos2Section, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23) then
			portalData = phaennaPortalPositions[24] and phaennaPortalPositions[24]["24 North"]
		end
	end
	
	-- Check version requirements for portal
	if portalData and portalData.requires then
		if ffxivminion.PhaennaMapVersion < portalData.requires then
			portalData = nil
		end
	end
	
	if not portalData then
		return false
	end
	
	local portalPos = portalData.pos
	local distance = math.distance2d(pos1, portalPos)
	
	if distance > 2 then
		return true, function()
			local newTask = ffxiv_task_movetopos.Create()
			newTask.pos = portalPos
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	else
		return true, function()
			Player:SetFacing(portalData.facing)
			Player:Move(FFXIV.MOVEMENT.FORWARD)
		end
	end
end

function Transport1310(pos1, pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	local pos1Section = GetOizys(pos1)
	local pos2Section = GetOizys(pos2, true)
	
	-- Check if we're on the Oizys map
	if Player.localmapid ~= 1310 then
		return false
	end
	
	-- Need valid sections
	if not pos1Section or pos1Section == 0 or not pos2Section or pos2Section == 0 then
		return false
	end
	
	-- Check map version requirements for specific sectors
	-- Sectors 6, 7 require version >= 3
	if In(pos1Section, 6, 7) or In(pos2Section, 6, 7) then
		if not ffxivminion.OizysMapVersion or ffxivminion.OizysMapVersion < 3 then
			return false
		end
	end
	-- Sectors 17, 18 require version >= 6
	if In(pos1Section, 17, 18) or In(pos2Section, 17, 18) then
		if not ffxivminion.OizysMapVersion or ffxivminion.OizysMapVersion < 6 then
			return false
		end
	end
	
	-- Same section, no transport needed
	if pos1Section == pos2Section then
		return false
	end
	
	-- Check if transport is beneficial
	if not CalcOizysTransport(pos1, pos2, pos1Section, pos2Section) then
		return false
	end
	
	-- Portal selection based on sections
	-- Portal naming: "X-Y" means portal in section X going to section Y
	local portalData = nil
	
	if In(pos1Section, 1) then
		if In(pos2Section, 17) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[1] and oizysPortalPositions[1]["1-8"]
		elseif In(pos2Section, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[1] and oizysPortalPositions[1]["1-8"]
		elseif In(pos2Section, 2, 3, 4, 5, 13, 14, 15) then
			portalData = oizysPortalPositions[1] and oizysPortalPositions[1]["1-2"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[1] and oizysPortalPositions[1]["1-8"]
		elseif In(pos2Section, 8, 9, 10, 11) then
			portalData = oizysPortalPositions[1] and oizysPortalPositions[1]["1-8"]
		elseif In(pos2Section, 12, 16) then
			portalData = oizysPortalPositions[1] and oizysPortalPositions[1]["1-12"]
		end
	elseif In(pos1Section, 2) then
		if In(pos2Section, 17, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[2] and oizysPortalPositions[2]["2-1"]
		elseif In(pos2Section, 1, 8, 12, 16) then
			portalData = oizysPortalPositions[2] and oizysPortalPositions[2]["2-1"]
		elseif In(pos2Section, 3, 5) then
			portalData = oizysPortalPositions[2] and oizysPortalPositions[2]["2-3"]
		elseif In(pos2Section, 4) then
			portalData = oizysPortalPositions[2] and oizysPortalPositions[2]["2-4"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[2] and oizysPortalPositions[2]["2-4"]
		elseif In(pos2Section, 13, 14, 15) then
			portalData = oizysPortalPositions[2] and oizysPortalPositions[2]["2-13"]
		end
	elseif In(pos1Section, 3) then
		if In(pos2Section, 17, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[3] and oizysPortalPositions[3]["3-2"]
		elseif In(pos2Section, 1, 2, 8, 12, 13, 16) then
			portalData = oizysPortalPositions[3] and oizysPortalPositions[3]["3-2"]
		elseif In(pos2Section, 4) then
			portalData = oizysPortalPositions[3] and oizysPortalPositions[3]["3-4"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[3] and oizysPortalPositions[3]["3-4"]
		elseif In(pos2Section, 5, 14, 15) then
			portalData = oizysPortalPositions[3] and oizysPortalPositions[3]["3-5"]
		end
	elseif In(pos1Section, 4) then
		if In(pos2Section, 17, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[4] and oizysPortalPositions[4]["4-6"]
		elseif In(pos2Section, 1, 2, 13) then
			portalData = oizysPortalPositions[4] and oizysPortalPositions[4]["4-2"]
		elseif In(pos2Section, 3, 5, 14, 15) then
			portalData = oizysPortalPositions[4] and oizysPortalPositions[4]["4-3"]
		elseif In(pos2Section, 8, 9, 10, 11, 12, 16) then
			portalData = oizysPortalPositions[4] and oizysPortalPositions[4]["4-6"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[4] and oizysPortalPositions[4]["4-6"]
		end
	elseif In(pos1Section, 5) then
		if In(pos2Section, 17, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[5] and oizysPortalPositions[5]["5-4"]
		elseif In(pos2Section, 1, 2, 3, 8, 12, 13) then
			portalData = oizysPortalPositions[5] and oizysPortalPositions[5]["5-3"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[5] and oizysPortalPositions[5]["5-3"]
		elseif In(pos2Section, 4, 9, 10, 11, 14, 15, 16) then
			portalData = oizysPortalPositions[5] and oizysPortalPositions[5]["5-4"]
		end
	elseif In(pos1Section, 6) and ffxivminion.OizysMapVersion >= 3 then
		if In(pos2Section, 17) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[6] and oizysPortalPositions[6]["6-7"]
		elseif In(pos2Section, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[6] and oizysPortalPositions[6]["6-8"]
		elseif In(pos2Section, 2, 3, 4, 5, 13, 14, 15) then
			portalData = oizysPortalPositions[6] and oizysPortalPositions[6]["6-4"]
		elseif In(pos2Section, 7) then
			portalData = oizysPortalPositions[6] and oizysPortalPositions[6]["6-7"]
		elseif In(pos2Section, 1, 8, 9, 10, 11, 12, 16) then
			portalData = oizysPortalPositions[6] and oizysPortalPositions[6]["6-8"]
		end
	elseif In(pos1Section, 7) and ffxivminion.OizysMapVersion >= 3 then
		if In(pos2Section, 17, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[7] and oizysPortalPositions[7]["7-17"]
		elseif In(pos2Section, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 16) then
			portalData = oizysPortalPositions[7] and oizysPortalPositions[7]["7-6"]
		end
	elseif In(pos1Section, 8) then
		if In(pos2Section, 17) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[8] and oizysPortalPositions[8]["8-6"]
		elseif In(pos2Section, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[8] and oizysPortalPositions[8]["8-9"]
		elseif In(pos2Section, 1, 2, 3, 4, 5, 12, 13, 14, 15, 16) then
			portalData = oizysPortalPositions[8] and oizysPortalPositions[8]["8-1"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[8] and oizysPortalPositions[8]["8-6"]
		elseif In(pos2Section, 9, 10, 11) then
			portalData = oizysPortalPositions[8] and oizysPortalPositions[8]["8-9"]
		end
	elseif In(pos1Section, 9) then
		if In(pos2Section, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[9] and oizysPortalPositions[9]["9-18"]
		elseif In(pos2Section, 17) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[9] and oizysPortalPositions[9]["9-18"]
		elseif In(pos2Section, 1, 2, 3, 4, 5, 8, 12, 13, 14, 15, 16) then
			portalData = oizysPortalPositions[9] and oizysPortalPositions[9]["9-8"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[9] and oizysPortalPositions[9]["9-8"]
		elseif In(pos2Section, 10) then
			portalData = oizysPortalPositions[9] and oizysPortalPositions[9]["9-10"]
		elseif In(pos2Section, 11) then
			portalData = oizysPortalPositions[9] and oizysPortalPositions[9]["9-11"]
		end
	elseif In(pos1Section, 10) then
		if In(pos2Section, 17) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[10] and oizysPortalPositions[10]["10-8"]
		elseif In(pos2Section, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[10] and oizysPortalPositions[10]["10-9"]
		elseif In(pos2Section, 1, 8) then
			portalData = oizysPortalPositions[10] and oizysPortalPositions[10]["10-8"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[10] and oizysPortalPositions[10]["10-8"]
		elseif In(pos2Section, 9, 11) then
			portalData = oizysPortalPositions[10] and oizysPortalPositions[10]["10-9"]
		elseif In(pos2Section, 2, 3, 4, 5, 13, 14, 15) then
			portalData = oizysPortalPositions[10] and oizysPortalPositions[10]["10-11"]
		elseif In(pos2Section, 12, 16) then
			portalData = oizysPortalPositions[10] and oizysPortalPositions[10]["10-12"]
		end
	elseif In(pos1Section, 11) then
		if In(pos2Section, 17) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[11] and oizysPortalPositions[11]["11-9"]
		elseif In(pos2Section, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[11] and oizysPortalPositions[11]["11-9"]
		elseif In(pos2Section, 1, 8, 9, 12, 16) then
			portalData = oizysPortalPositions[11] and oizysPortalPositions[11]["11-9"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[11] and oizysPortalPositions[11]["11-9"]
		elseif In(pos2Section, 2, 3, 4, 5, 10, 13, 14, 15) then
			portalData = oizysPortalPositions[11] and oizysPortalPositions[11]["11-10"]
		end
	elseif In(pos1Section, 12) then
		if In(pos2Section, 17, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[12] and oizysPortalPositions[12]["12-1"]
		elseif In(pos2Section, 1, 2, 3, 4, 5, 8, 9) then
			portalData = oizysPortalPositions[12] and oizysPortalPositions[12]["12-1"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[12] and oizysPortalPositions[12]["12-1"]
		elseif In(pos2Section, 10, 11) then
			portalData = oizysPortalPositions[12] and oizysPortalPositions[12]["12-10"]
		elseif In(pos2Section, 13, 14, 15) then
			portalData = oizysPortalPositions[12] and oizysPortalPositions[12]["12-13"]
		elseif In(pos2Section, 16) then
			portalData = oizysPortalPositions[12] and oizysPortalPositions[12]["12-16"]
		end
	elseif In(pos1Section, 13) then
		if In(pos2Section, 17, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[13] and oizysPortalPositions[13]["13-2"]
		elseif In(pos2Section, 1, 2, 3, 4, 5, 8, 9, 10, 11) then
			portalData = oizysPortalPositions[13] and oizysPortalPositions[13]["13-2"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[13] and oizysPortalPositions[13]["13-2"]
		elseif In(pos2Section, 12, 16) then
			portalData = oizysPortalPositions[13] and oizysPortalPositions[13]["13-12"]
		elseif In(pos2Section, 14, 15) then
			portalData = oizysPortalPositions[13] and oizysPortalPositions[13]["13-14"]
		end
	elseif In(pos1Section, 14) then
		if In(pos2Section, 17, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[14] and oizysPortalPositions[14]["14-13"]
		elseif In(pos2Section, 1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13) then
			portalData = oizysPortalPositions[14] and oizysPortalPositions[14]["14-13"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[14] and oizysPortalPositions[14]["14-13"]
		elseif In(pos2Section, 15) then
			portalData = oizysPortalPositions[14] and oizysPortalPositions[14]["14-15"]
		elseif In(pos2Section, 16) then
			portalData = oizysPortalPositions[14] and oizysPortalPositions[14]["14-16"]
		end
	elseif In(pos1Section, 15) then
		if In(pos2Section, 17, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[15] and oizysPortalPositions[15]["15-14"]
		elseif In(pos2Section, 1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 14) then
			portalData = oizysPortalPositions[15] and oizysPortalPositions[15]["15-14"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[15] and oizysPortalPositions[15]["15-14"]
		elseif In(pos2Section, 16) then
			portalData = oizysPortalPositions[15] and oizysPortalPositions[15]["15-16"]
		end
	elseif In(pos1Section, 16) then
		if In(pos2Section, 17, 18) and ffxivminion.OizysMapVersion >= 6 then
			portalData = oizysPortalPositions[16] and oizysPortalPositions[16]["16-12"]
		elseif In(pos2Section, 1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13) then
			portalData = oizysPortalPositions[16] and oizysPortalPositions[16]["16-12"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[16] and oizysPortalPositions[16]["16-12"]
		elseif In(pos2Section, 14, 15) then
			portalData = oizysPortalPositions[16] and oizysPortalPositions[16]["16-14"]
		end
	elseif In(pos1Section, 17) and ffxivminion.OizysMapVersion >= 6 then
		if In(pos2Section, 18) then
			portalData = oizysPortalPositions[17] and oizysPortalPositions[17]["17-18"]
		elseif In(pos2Section, 6, 7) and ffxivminion.OizysMapVersion >= 3 then
			portalData = oizysPortalPositions[17] and oizysPortalPositions[17]["17-7"]
		elseif In(pos2Section, 1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 14, 15, 16) then
			portalData = oizysPortalPositions[17] and oizysPortalPositions[17]["17-7"]
		end
	elseif In(pos1Section, 18) and ffxivminion.OizysMapVersion >= 6 then
		if In(pos2Section, 17) then
			portalData = oizysPortalPositions[18] and oizysPortalPositions[18]["18-17"]
		elseif In(pos2Section, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16) then
			portalData = oizysPortalPositions[18] and oizysPortalPositions[18]["18-9"]
		elseif In(pos2Section, 9) then
			portalData = oizysPortalPositions[18] and oizysPortalPositions[18]["18-9"]
		end
	end
	
	-- No valid portal found
	if not portalData then
		return false
	end
	
	-- Move to portal or enter it
	local portalPos = portalData.pos
	local distance = math.distance2d(pos1, portalPos)
	
	if distance > 2 then
		return true, function()
			local newTask = ffxiv_task_movetopos.Create()
			newTask.pos = portalPos
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	else
		return true, function()
			Player:SetFacing(portalData.facing)
			Player:Move(FFXIV.MOVEMENT.FORWARD)
		end
	end
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

-- Helper function to check if portal meets version requirements
local function PortalMeetsVersion(portalData)
	if not portalData then
		return false
	end
	local requiredVersion = portalData.requires or 3
	return ffxivminion.PhaennaMapVersion >= requiredVersion
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
	if (GetMapSection(961, pos1) ~= GetMapSection(961, pos2)) then
		if (GetMapSection(961, Player.pos) ~= 3) and (GetMapSection(961, pos2) == 3) then
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
						return (GetMapSection(961, Player.pos) == 3)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		elseif (GetMapSection(961, Player.pos) == 3) and (GetMapSection(961, pos2) == 1) then
			if (GilCount() > 0) then
				return true, function ()
					-- Need to leave the boat, talk to the captain.
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 886.9, y = 21.4, z = 134.2}
					newTask.contentid = 1005414
					newTask.abort = function ()
						return (GetMapSection(961, Player.pos) == 1)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end
		if (GetMapSection(961, Player.pos) ~= 2) and (GetMapSection(961, pos2) == 2) then
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
								return (GetMapSection(961, Player.pos) == 2) or (CanUseAetheryte(12) and not Player.incombat) 
							end
							ml_task_hub:CurrentTask():AddSubTask(newTask)
						end
					end
				end
			end
		elseif (GetMapSection(961, Player.pos) == 2) and (GetMapSection(961, pos2) ~= 2) then
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
						return (GetMapSection(961, Player.pos) ~= 2) or (CanUseAetheryte(11) and not Player.incombat) 
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
	
	if ((pos1.x < 23.85 and pos1.x > -16.5) and not (pos2.x < 23.85 and pos2.x > -16.5)) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = 22.386226654053, y = 0.99999862909317, z = -0.097462706267834}
			newTask.contentid = 2001715
			newTask.abort = function () 
				return not (Player.pos.x < 23.85 and Player.pos.x > -16.5)
			end
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	elseif (not (pos1.x < 23.85 and pos1.x > -16.5) and (pos2.x < 23.85 and pos2.x > -16.5 )) then
		return true, function()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = 26.495914459229, y = 1.0000013113022, z = -0.018158292397857}
			newTask.contentid = 2001717
			newTask.abort = function () 
				return (Player.pos.x < 23.85 and Player.pos.x > -16.5)
			end
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	end

	return false			
end

function Transport351(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	local enterSolar = true

	
		local task = ml_task_hub and ml_task_hub.CurrentTask and ml_task_hub:CurrentTask()
		if task and task.destMapID and task.destMapID ~= 351 then
			enterSolar = false
		end

	if ((pos1.z < 27.394 and pos1.z > -27.20) and not (pos2.z < 27.39 and pos2.z > -27.20)) and enterSolar then
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

function Transport398(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (false) then -- need to re-evaluate the sections before enabling this
	--if (not CanFlyInZone()) then
		if (GetMapSection(398, pos1) ~= GetMapSection(398, pos2)) then
			if (GilCount() > 1000) then
				if (GetMapSection(398, Player.pos) == 2) then
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
		if (GetMapSection(399, pos1) ~= GetMapSection(399, pos2) and libraryDist > 300) then
			return true, function()
				local newTask = ffxiv_task_movetomap.Create()
				newTask.destMapID = 478
				ff.mapsections[399] = GetMapSection(399, pos2)
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
		if (GetMapSection(401, pos1) ~= GetMapSection(401, pos2)) then
			if (GilCount() > 100) then
				if (GetMapSection(401, Player.pos) == 1) then
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
		if HasQuest(2530) or QuestCompleted(2530) then 
			local gilCount = GilCount()
			--d("Player Fringe sec = ["..tostring(GetMapSection(612, Player.pos)).."]")
			--d("Endpoint Fringe sec = ["..tostring(GetMapSection(612, pos2)).."]")
			if (GetMapSection(612, pos1) ~= GetMapSection(612, pos2)) then
				if (GetMapSection(612, Player.pos) == 2) then
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
									return (GetMapSection(612, Player.pos) ~= 2)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
							end
						end
					end
				else
					if HasQuest(2530) or QuestCompleted(2530) then
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
						elseif HasQuest(2530) then
							return true, function ()
								local newTask = ffxiv_nav_interact.Create()
								newTask.pos = {x = -91, y = 50, z = 210}
								newTask.contentid = 1020573
								newTask.abort = function ()
									return (GetMapSection(612, Player.pos) == 2)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
							end
						else
							return true, function ()
								local newTask = ffxiv_nav_interact.Create()
								newTask.pos = {x = -91, y = 50, z = 210}
								newTask.contentid = 1019530
								newTask.abort = function ()
									return (GetMapSection(612, Player.pos) == 2)
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
		if (GetMapSection(614, pos1) ~= GetMapSection(614, pos2)) then
			if (GilCount() > 200) then
				if (GetMapSection(614, Player.pos) == 1) then
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
		if (GetMapSection(614, Player.pos) ~= 2) and (GetMapSection(614, pos2) == 2) then
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
		if (GetMapSection(620, pos1) ~= GetMapSection(620, pos2)) then
			if (GilCount() > 200) then
				if (GetMapSection(620, Player.pos) ~= 1) then
					if (GetMapSection(620, pos2) == 1) then
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
				
				if (GetMapSection(620, Player.pos) == 1) then
					if (GetMapSection(620, pos2) ~= 1) then
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
		
		if (HasQuest(2537) and GetQuestInfo(2537,'step') >= 2) then
			if (GetMapSection(620, Player.pos) ~= 3) and (GetMapSection(620, pos2) == 3) then
				if (GilCount() > 0) then
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = -129, y = 305, z = 189}
						newTask.contentid = 2008944
						newTask.abort = function ()
							return (GetMapSection(620, Player.pos) == 3)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				end
			end
		end
		if (QuestCompleted(2537) and not QuestCompleted(2541)) then
			if (GetMapSection(620, Player.pos) ~= 3) and (GetMapSection(620, pos2) == 3) then
				if (GilCount() > 0) then
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = -129, y = 305, z = 189}
						newTask.contentid = 2008449
						newTask.abort = function ()
							return (GetMapSection(620, Player.pos) == 3)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				end
			end
		end
		if QuestCompleted(2541) then
			if (GetMapSection(620, Player.pos) ~= 3) and (GetMapSection(620, pos2) == 3) then
				if (GilCount() > 0) then
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = -132, y = 305, z = 191}
						newTask.contentid = 1021557
						newTask.abort = function ()
							return (GetMapSection(620, Player.pos) == 3)
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
			if (GetMapSection(621, Player.pos)~= 1)  and (GetMapSection(621, pos2) == 1) then
				if (GilCount() > 0) then
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = 500, y = 69, z = 583}
						newTask.contentid = 1023048
						newTask.abort = function ()
							return (GetMapSection(621, Player.pos) == 1)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				end
			end
			if (GetMapSection(621, Player.pos)~= 2)  and (GetMapSection(621, pos2) == 2) then
				if (GilCount() > 0) then
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = 466, y = 61, z = 583}
						newTask.contentid = 1023047
						newTask.abort = function ()
							return (GetMapSection(621, Player.pos) == 2)
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
			if (GetMapSection(814, pos1) ~= GetMapSection(814, pos2)) then
				if (GetMapSection(814, Player.pos) == 1) then
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
									return (GetMapSection(814, Player.pos) ~= 1)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
							end
						end
					end
				end
				if (GetMapSection(814, Player.pos) == 2) then
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
									return (GetMapSection(814, Player.pos) ~= 2)
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
			if (GetMapSection(815, pos1) ~= GetMapSection(815, pos2)) then
				if (GetMapSection(815, Player.pos) == 1 and GetMapSection(815, pos2) == 2) then
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
				if (GetMapSection(815, Player.pos) == 2 and GetMapSection(815, pos2) == 1) then
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
			if (GetMapSection(815, pos1) ~= GetMapSection(815, pos2)) then
				if (GetMapSection(815, Player.pos) == 2 and GetMapSection(815, pos2) == 3) then
					if (gilCount > 0) then
							return true, function ()
								local newTask = ffxiv_nav_interact.Create()
								newTask.pos = {x = -474.59, y = 45.55, z = -237.59}
								newTask.contentid = 1031660
								newTask.abort = function ()
									return (GetMapSection(815, Player.pos) ~= 2)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
						end
					end
				end
				if (GetMapSection(815, Player.pos) == 3 and GetMapSection(815, pos2) == 2) then
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
									return (GetMapSection(815, Player.pos) ~= 3)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
							end
						end
					end
				end
				if (GetMapSection(815, Player.pos) == 1 and GetMapSection(815, pos2) == 3) then
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
				if (GetMapSection(815, Player.pos) == 3 and GetMapSection(815, pos2) == 1) then
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
			if (GetMapSection(957, pos1) ~= GetMapSection(957, pos2)) then
				if (GetMapSection(957, Player.pos) == 1) then
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
									return (GetMapSection(957, Player.pos) ~= 1)
								end
								ml_task_hub:CurrentTask():AddSubTask(newTask)
							end
						end
					end
				end
				if (GetMapSection(957, Player.pos) == 2) then
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
									return (GetMapSection(957, Player.pos) ~= 2)
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
function Transport956(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (not CanFlyInZone()) then
		if (GetQuestInfo(4441,'step') >= 5) or QuestCompleted(4441) then 
			local gilCount = GilCount()
			-- lift south
			if GetMapSection(956, pos1) == 1 and GetMapSection(956, pos2) ~= 1 then
				if (CanUseAetheryte(167) and not Player.incombat) and (gilCount > 100) then
					return true, function () 
						if (Player:IsMoving()) then
							Player:Stop()
							ml_global_information.Await(1500, function () return not Player:IsMoving() end)
							return
						end
						if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
							if (Player:Teleport(167)) then	
								local newTask = ffxiv_task_teleport.Create()
								newTask.aetheryte = 167
								newTask.mapID = 956
								ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
							end
						end
					end
				else
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = 362.26, y = 79.69, z = 302.08}
						newTask.contentid = 1039548
						newTask.abort = function ()
							return GetMapSection(956, Player.pos) == 2
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				end
			elseif GetMapSection(956, pos1) ~= 1 and GetMapSection(956, pos2) == 1 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 229.88, y = -18.74, z = 298.73}
					newTask.contentid = 1039549
					newTask.abort = function ()
						return GetMapSection(956, Player.pos) == 1
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end	
		-- inner lift
		if (GetQuestInfo(4448,'step') >= 5) or QuestCompleted(4448) then 
			if GetMapSection(956, pos1) ~= 3 and GetMapSection(956, pos2) == 3 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -620.72, y = -27.67, z = 302.17}
					newTask.contentid = 1039550
					newTask.abort = function ()
						return GetMapSection(956, Player.pos) == 3
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			elseif GetMapSection(956, pos1) == 3 and GetMapSection(956, pos2) ~= 3 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -614.86, y = -191.12, z = 305.74}
					newTask.contentid = 1039551
					newTask.abort = function ()
						return GetMapSection(956, Player.pos) == 2
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end
	end
		
	return false			
end
function Transport957(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (not CanFlyInZone()) then
		local gilCount = GilCount()
		if GetMapSection(963, pos1) == 1 and GetMapSection(963, pos2) == 2 then
			if (CanUseAetheryte(171) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(171)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 171
							newTask.mapID = 957
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			else
				-- saved for forced pathing if needed.
				-- removed bridge connection to avoid attemptijng to path over bridge for fates etc.
			end
		end
	end
		
	return false			
end
function Transport959(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	if (not CanFlyInZone()) then
		if QuestCompleted(4403) and GetMapSection(959, Player.pos) == 2 then 
			if  (pos1.y < -60 and (pos2.y >= -60)) then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -26, y = -130, z = -580}
					newTask.contentid = 2012664
					newTask.abort = function ()
						return (Player.pos.y >= -60)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end	
		if QuestCompleted(4400) then
			if GetMapSection(959, pos1) == 1 and GetMapSection(959, pos2) == 2  then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 203, y = 59, z = 407}
					newTask.contentid = 1038869
					newTask.abort = function ()
						return GetMapSection(959, Player.pos) == 2
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
			if GetMapSection(959, pos1) == 1 and GetMapSection(959, pos2) == 3  then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 203, y = 59, z = 407}
					newTask.contentid = 1038869
					newTask.abort = function ()
						return GetMapSection(959, Player.pos) == 2
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
			if GetMapSection(959, pos1) == 2 and GetMapSection(959, pos2) == 1 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -4, y = -26, z = -213}
					newTask.contentid = 1038870
					newTask.abort = function ()
						return GetMapSection(959, Player.pos) == 1
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
			if GetMapSection(959, pos1) == 3 and GetMapSection(959, pos2) == 1 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -4, y = -26, z = -213}
					newTask.contentid = 1038870
					newTask.abort = function ()
						return GetMapSection(959, Player.pos) == 1
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end	
	end
		
	return false			
end
function Transport960(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	if (not CanFlyInZone()) then
		-- island 1
		if GetQuestInfo(4455,'step') == 255 or QuestCompleted(4455) then 
			-- move to 2
			if GetMapSection(960, pos1) == 1 and GetMapSection(960, pos2) ~= 1 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -608, y = 92, z = -208}
					newTask.contentid = 2012544
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 2
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			-- move from 2
			elseif GetMapSection(960, pos1) ~= 1 and GetMapSection(960, pos2) == 1 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -471, y = 232, z = -260}
					newTask.contentid = 2012545
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 1
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end	
		-- island 2
		if GetQuestInfo(4459,'step') >= 2 and not QuestCompleted(4459) then
			-- move to 3
			if In(GetMapSection(960, pos1),1,2) and GetMapSection(960, pos2) == 3 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 440, y = 285, z = -319}
					newTask.contentid = 2012794
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 3
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			-- move from 3 to 2
			elseif GetMapSection(960, pos1) == 3 and In(GetMapSection(960, pos2),1,2) then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 514, y = 440, z = 140}
					newTask.contentid = 2012481
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 2
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end	
		if QuestCompleted(4459) then
			-- move to 3
			if In(GetMapSection(960, pos1),1,2) and GetMapSection(960, pos2) == 3 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 440, y = 285, z = -319}
					newTask.contentid = 2012480
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 3
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			-- move from 3 to 2
			elseif GetMapSection(960, pos1) == 3 and In(GetMapSection(960, pos2),1,2) then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 514, y = 440, z = 140}
					newTask.contentid = 2012481
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 2
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end	
		-- island 3
		if GetQuestInfo(4460,'step') == 255 and not QuestCompleted(4460)then
			-- move to island 4
			if GetMapSection(960, pos1) ~= 4 and GetMapSection(960, pos2) == 4 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 639, y = 439, z = 241}
					newTask.contentid = 2012796
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 4
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
				-- move from island 4
			elseif GetMapSection(960, pos1) == 4 and GetMapSection(960, pos2) ~= 4 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 694, y = 479, z = 226}
					newTask.contentid = 2012483
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 3
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end	
		if QuestCompleted(4460) then
			-- move to island 4
			if GetMapSection(960, pos1) ~= 4 and GetMapSection(960, pos2) == 4 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 639, y = 439, z = 241}
					newTask.contentid = 2012482
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 4
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
				-- move from island 4
			elseif GetMapSection(960, pos1) == 4 and GetMapSection(960, pos2) ~= 4 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 694, y = 479, z = 226}
					newTask.contentid = 2012483
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 3
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end	
		if GetQuestInfo(4462,'step') >= 2 and not QuestCompleted(4462) then
			if GetMapSection(960, pos1) ~= 5 and GetMapSection(960, pos2) == 5 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 492, y = 438, z = 365}
					newTask.contentid = 2012795
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 5
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			elseif GetMapSection(960, pos1) == 5 and GetMapSection(960, pos2) ~= 5 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 469, y = 418, z = 403}
					newTask.contentid = 2012485
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 3
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end	
		if QuestCompleted(4462) then
			if GetMapSection(960, pos1) ~= 5 and GetMapSection(960, pos2) == 5 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 492, y = 438, z = 365}
					newTask.contentid = 2012484
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 5
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			elseif GetMapSection(960, pos1) == 5 and GetMapSection(960, pos2) ~= 5 then
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 469, y = 418, z = 403}
					newTask.contentid = 2012485
					newTask.abort = function ()
						return GetMapSection(960, Player.pos) == 3
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end	
	end
		
	return false			
end

function Transport1187(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (not CanFlyInZone()) then
		local gilCount = GilCount()
		if In(GetMapSection(1187, pos1),1) and In(GetMapSection(1187, pos2),2) then
			if (CanUseAetheryte(201) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(201)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 201
							newTask.mapID = 1187
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		elseif In(GetMapSection(1187, pos1),2) and In(GetMapSection(1187, pos2),1) then
			if (CanUseAetheryte(200) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(200)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 200
							newTask.mapID = 1187
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		end
	end
	
	return false	
end
function Transport1188(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	
	if (not CanFlyInZone()) then
		local gilCount = GilCount()
		if In(GetMapSection(1188, pos1),1) and In(GetMapSection(1188, pos2),2) then
			if (CanUseAetheryte(204) and not Player.incombat) and (gilCount > 100) and pos2.x < 200 then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(204)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 204
							newTask.mapID = 1188
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
			if (CanUseAetheryte(203) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(203)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 203
							newTask.mapID = 1188
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		elseif In(GetMapSection(1188, pos1),2) and In(GetMapSection(1188, pos2),1) then
			if (CanUseAetheryte(202) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(202)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 202
							newTask.mapID = 1188
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		end
	end
	
	if (GetMapSection(1188, Player.pos) ~= 2) and (GetMapSection(1188, pos2) == 2) then
		if not (CanUseAetheryte(203)) then
			return true, function()
				local newTask = ffxiv_task_movetomap.Create()
				newTask.destMapID = 1185
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		end
	end
	
	return false			
end
function Transport1189(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	local gilCount = GilCount()
	
	-- leave section 3
	if In(GetMapSection(1189, pos1),3) and In(GetMapSection(1189, pos2),2) then
		return true, function ()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = -782, y = -297, z = 772}
			newTask.contentid = 1048030
			newTask.abort = function ()
				return In(GetMapSection(1189, Player.pos),2)
			end
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	end
	
	if In(GetMapSection(1189, pos1),3) and In(GetMapSection(1189, pos2),1) then
		if (CanUseAetheryte(205) and not Player.incombat) and (gilCount > 100) then
			return true, function () 
				if (Player:IsMoving()) then
					Player:Stop()
					ml_global_information.Await(1500, function () return not Player:IsMoving() end)
					return
				end
				if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
					if (Player:Teleport(205)) then	
						local newTask = ffxiv_task_teleport.Create()
						newTask.aetheryte = 205
						newTask.mapID = 1189
						ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
					end
				end
			end
		end
	end
	
	-- get to section 3
	if In(GetMapSection(1189, pos1),1) and In(GetMapSection(1189, pos2),3) then
		if (CanUseAetheryte(206) and not Player.incombat) and (gilCount > 100) then
			return true, function () 
				if (Player:IsMoving()) then
					Player:Stop()
					ml_global_information.Await(1500, function () return not Player:IsMoving() end)
					return
				end
				if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
					if (Player:Teleport(206)) then	
						local newTask = ffxiv_task_teleport.Create()
						newTask.aetheryte = 206
						newTask.mapID = 1189
						ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
					end
				end
			end
		end
	end
	
	if In(GetMapSection(1189, pos1),2) and In(GetMapSection(1189, pos2),3) then
		return true, function ()
			local newTask = ffxiv_nav_interact.Create()
			newTask.pos = {x = -711, y = -199, z = 624}
			newTask.contentid = 1047707
			newTask.abort = function ()
				return In(GetMapSection(1189, Player.pos),3)
			end
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	end
	
	-- teleport prior to flight
	if (not CanFlyInZone()) then
		if In(GetMapSection(1189, pos1),2) and In(GetMapSection(1189, pos2),1) then
			if (CanUseAetheryte(205) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(205)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 205
							newTask.mapID = 1189
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		end
		if In(GetMapSection(1189, pos1),1) and In(GetMapSection(1189, pos2),2) then
			if (CanUseAetheryte(206) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(206)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 206
							newTask.mapID = 1189
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		end
	end
	
	return false			
end
function Transport1192(pos1,pos2)
	local pos1 = pos1 or Player.pos
	local pos2 = pos2
	local gilCount = GilCount()
	
	if (not CanFlyInZone()) then
		-- Gate Keeper: 1 -> 2
		if In(GetMapSection(1192, pos1),1) and In(GetMapSection(1192, pos2),2) then
			if (HasQuest(4949) and GetQuestInfo(4949,'step') > 2) or QuestCompleted(4949) then
				d("Moving from section 1 to section 2")
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -36.30, y = 53.20, z = 753.60}
					newTask.contentid = 1048242
					newTask.abort = function ()
						return In(GetMapSection(1192, Player.pos),2)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end
		-- Gate Keeper: 1 -> 3
		if In(GetMapSection(1192, pos1),1) and In(GetMapSection(1192, pos2),3) then
			if (HasQuest(4951) and GetQuestInfo(4951,'step') > 1) or QuestCompleted(4951) then
				d("Moving from section 1 to section 3")
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 57.88, y = 53.20, z = 772.03}
					newTask.contentid = 1048243
					newTask.abort = function ()
						return In(GetMapSection(1192, Player.pos),3)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			end
		end
		-- Gate Keeper: 1 -> 4
		if In(GetMapSection(1192, pos1),1) and In(GetMapSection(1192, pos2),4) then
			if not CanUseAetheryte(214) then
				if (HasQuest(4953) and GetQuestInfo(4953,'step') >= 2) or QuestCompleted(4953) then
					d("Moving from section 1 to section 4")
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = 35.72, y = 53.20, z = 753.17}
						newTask.contentid = 1048244
						newTask.abort = function ()
							return In(GetMapSection(1192, Player.pos),4)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				end
			elseif (CanUseAetheryte(214) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(214)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 214
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		end
		-- Gate Keeper: 1 -> 5
		if In(GetMapSection(1192, pos1),1) and In(GetMapSection(1192, pos2),5) then
			if not CanUseAetheryte(215) then
				if (HasQuest(4956) and GetQuestInfo(4956,'step') >= 3) or QuestCompleted(4956) then
					d("Moving from section 1 to section 5")
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = -56.99, y = 53.20, z = 768.40}
						newTask.contentid = 1048245
						newTask.abort = function ()
							return In(GetMapSection(1192, Player.pos),5)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				end
			elseif (CanUseAetheryte(215) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(215)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 215
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		end
		-- Gate Keeper: 2 -> 1
		if In(GetMapSection(1192, pos1),2) and In(GetMapSection(1192, pos2),1) then
			if not CanUseAetheryte(213) then
				d("Moving from section 2 to section 1")
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -125.11, y = 6.38, z = 562.62}
					newTask.contentid = 1048247
					newTask.abort = function ()
						return In(GetMapSection(1192, Player.pos),1)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(213)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 213
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		elseif In(GetMapSection(1192, pos1),2) and In(GetMapSection(1192, pos2),3) then
			if not CanUseAetheryte(213) then
				d("Moving from section 2 to section 3")
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -125.11, y = 6.38, z = 562.62}
					newTask.contentid = 1048247
					newTask.abort = function ()
						return In(GetMapSection(1192, Player.pos),1)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(213)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 213
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		elseif In(GetMapSection(1192, pos1),2) and In(GetMapSection(1192, pos2),4) then
			if not CanUseAetheryte(214) then
				if not CanUseAetheryte(213) then
					d("Moving from section 2 to section 4")
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = -125.11, y = 6.38, z = 562.62}
						newTask.contentid = 1048247
						newTask.abort = function ()
							return In(GetMapSection(1192, Player.pos),1)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
					return true, function () 
						if (Player:IsMoving()) then
							Player:Stop()
							ml_global_information.Await(1500, function () return not Player:IsMoving() end)
							return
						end
						if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
							if (Player:Teleport(213)) then	
								local newTask = ffxiv_task_teleport.Create()
								newTask.aetheryte = 213
								newTask.mapID = 1192
								ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
							end
						end
					end
				end
			elseif (CanUseAetheryte(214) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(214)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 214
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		elseif In(GetMapSection(1192, pos1),2) and In(GetMapSection(1192, pos2),5) then
			if not CanUseAetheryte(215) then
				if not CanUseAetheryte(213) then
					d("Moving from section 2 to section 5")
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = -125.11, y = 6.38, z = 562.62}
						newTask.contentid = 1048247
						newTask.abort = function ()
							return In(GetMapSection(1192, Player.pos),1)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
					return true, function () 
						if (Player:IsMoving()) then
							Player:Stop()
							ml_global_information.Await(1500, function () return not Player:IsMoving() end)
							return
						end
						if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
							if (Player:Teleport(213)) then	
								local newTask = ffxiv_task_teleport.Create()
								newTask.aetheryte = 213
								newTask.mapID = 1192
								ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
							end
						end
					end
				end
			elseif (CanUseAetheryte(215) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(215)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 215
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		end
		
		-- Gate Keeper: 3 -> 1
		if In(GetMapSection(1192, pos1),3) and In(GetMapSection(1192, pos2),1) then
			if not CanUseAetheryte(213) then
				d("Moving from section 3 to section 1")
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 206.26, y = 0.20, z = 661.89}
					newTask.contentid = 1048248
					newTask.abort = function ()
						return In(GetMapSection(1192, Player.pos),1)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(213)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 213
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		elseif In(GetMapSection(1192, pos1),3) and In(GetMapSection(1192, pos2),2) then
			if not CanUseAetheryte(213) then
				d("Moving from section 3 to section 2")
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 206.26, y = 0.20, z = 661.89}
					newTask.contentid = 1048248
					newTask.abort = function ()
						return In(GetMapSection(1192, Player.pos),1)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(213)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 213
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		elseif In(GetMapSection(1192, pos1),3) and In(GetMapSection(1192, pos2),4) then
			if not CanUseAetheryte(214) then
				if not CanUseAetheryte(213) then
					d("Moving from section 3 to section 4")
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = 206.26, y = 0.20, z = 661.89}
						newTask.contentid = 1048248
						newTask.abort = function ()
							return In(GetMapSection(1192, Player.pos),1)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
					return true, function () 
						if (Player:IsMoving()) then
							Player:Stop()
							ml_global_information.Await(1500, function () return not Player:IsMoving() end)
							return
						end
						if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
							if (Player:Teleport(213)) then	
								local newTask = ffxiv_task_teleport.Create()
								newTask.aetheryte = 213
								newTask.mapID = 1192
								ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
							end
						end
					end
				end
			elseif (CanUseAetheryte(214) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(214)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 214
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		elseif In(GetMapSection(1192, pos1),3) and In(GetMapSection(1192, pos2),5) then
			if not CanUseAetheryte(215) then
				if not CanUseAetheryte(213) then
					d("Moving from section 3 to section 5")
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = 206.26, y = 0.20, z = 661.89}
						newTask.contentid = 1048248
						newTask.abort = function ()
							return In(GetMapSection(1192, Player.pos),1)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
					return true, function () 
						if (Player:IsMoving()) then
							Player:Stop()
							ml_global_information.Await(1500, function () return not Player:IsMoving() end)
							return
						end
						if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
							if (Player:Teleport(213)) then	
								local newTask = ffxiv_task_teleport.Create()
								newTask.aetheryte = 213
								newTask.mapID = 1192
								ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
							end
						end
					end
				end
			elseif (CanUseAetheryte(215) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(215)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 215
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		end
		-- Gate Keeper: 4 -> 1
		if In(GetMapSection(1192, pos1),4) and In(GetMapSection(1192, pos2),1) then
			if not CanUseAetheryte(213) then
				d("Moving from section 4 to section 1")
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 256.12, y = -13.06, z = 29.10}
					newTask.contentid = 1048249
					newTask.abort = function ()
						return In(GetMapSection(1192, Player.pos),1)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(213)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 213
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		elseif In(GetMapSection(1192, pos1),4) and In(GetMapSection(1192, pos2),2) then
			if not CanUseAetheryte(213) then
				d("Moving from section 4 to section 2")
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 256.12, y = -13.06, z = 29.10}
					newTask.contentid = 1048249
					newTask.abort = function ()
						return In(GetMapSection(1192, Player.pos),1)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(213)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 213
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		elseif In(GetMapSection(1192, pos1),4) and In(GetMapSection(1192, pos2),3) then
			if not CanUseAetheryte(213) then
				d("Moving from section 4 to section 3")
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = 256.12, y = -13.06, z = 29.10}
					newTask.contentid = 1048249
					newTask.abort = function ()
						return In(GetMapSection(1192, Player.pos),1)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(213)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 213
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		elseif In(GetMapSection(1192, pos1),4) and In(GetMapSection(1192, pos2),5) then
			if not CanUseAetheryte(215) then
				if not CanUseAetheryte(213) then
					d("Moving from section 4 to section 5")
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = 256.12, y = -13.06, z = 29.10}
						newTask.contentid = 1048249
						newTask.abort = function ()
							return In(GetMapSection(1192, Player.pos),1)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
					return true, function () 
						if (Player:IsMoving()) then
							Player:Stop()
							ml_global_information.Await(1500, function () return not Player:IsMoving() end)
							return
						end
						if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
							if (Player:Teleport(213)) then	
								local newTask = ffxiv_task_teleport.Create()
								newTask.aetheryte = 213
								newTask.mapID = 1192
								ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
							end
						end
					end
				end
			elseif (CanUseAetheryte(215) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(215)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 215
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		end
		-- Gate Keeper: 5 -> 1
		if In(GetMapSection(1192, pos1),5) and In(GetMapSection(1192, pos2),1) then
			if not CanUseAetheryte(213) then
				d("Moving from section 5 to section 1")
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -178.06, y = 37.39, z = 66.91}
					newTask.contentid = 1048250
					newTask.abort = function ()
						return In(GetMapSection(1192, Player.pos),1)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(213)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 213
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		elseif In(GetMapSection(1192, pos1),5) and In(GetMapSection(1192, pos2),2) then
			if not CanUseAetheryte(213) then
				d("Moving from section 5 to section 2")
				return true, function ()
					local newTask = ffxiv_nav_interact.Create()
					newTask.pos = {x = -178.06, y = 37.39, z = 66.91}
					newTask.contentid = 1048250
					newTask.abort = function ()
						return In(GetMapSection(1192, Player.pos),1)
					end
					ml_task_hub:CurrentTask():AddSubTask(newTask)
				end
			elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(213)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 213
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
						end
					end
				end
			end
		elseif In(GetMapSection(1192, pos1),5) and In(GetMapSection(1192, pos2),3) then
			if not CanUseAetheryte(214) then
				if not CanUseAetheryte(213) then
					d("Moving from section 5 to section 3")
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = -178.06, y = 37.39, z = 66.91}
						newTask.contentid = 1048250
						newTask.abort = function ()
							return In(GetMapSection(1192, Player.pos),1)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
					return true, function () 
						if (Player:IsMoving()) then
							Player:Stop()
							ml_global_information.Await(1500, function () return not Player:IsMoving() end)
							return
						end
						if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
							if (Player:Teleport(213)) then	
								local newTask = ffxiv_task_teleport.Create()
								newTask.aetheryte = 213
								newTask.mapID = 1192
								ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
							end
						end
					end
				end
			end
		elseif In(GetMapSection(1192, pos1),5) and In(GetMapSection(1192, pos2),4) then
			if not CanUseAetheryte(214) then
				if not CanUseAetheryte(213) then
					d("Moving from section 5 to section 4")
					return true, function ()
						local newTask = ffxiv_nav_interact.Create()
						newTask.pos = {x = -178.06, y = 37.39, z = 66.91}
						newTask.contentid = 1048250
						newTask.abort = function ()
							return In(GetMapSection(1192, Player.pos),1)
						end
						ml_task_hub:CurrentTask():AddSubTask(newTask)
					end
				elseif (CanUseAetheryte(213) and not Player.incombat) and (gilCount > 100) then
					return true, function () 
						if (Player:IsMoving()) then
							Player:Stop()
							ml_global_information.Await(1500, function () return not Player:IsMoving() end)
							return
						end
						if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
							if (Player:Teleport(213)) then	
								local newTask = ffxiv_task_teleport.Create()
								newTask.aetheryte = 213
								newTask.mapID = 1192
								ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
							end
						end
					end
				end
			elseif (CanUseAetheryte(214) and not Player.incombat) and (gilCount > 100) then
				return true, function () 
					if (Player:IsMoving()) then
						Player:Stop()
						ml_global_information.Await(1500, function () return not Player:IsMoving() end)
						return
					end
					if (ActionIsReady(7,5) and not MIsCasting(true) and not CannotMove()) then
						if (Player:Teleport(214)) then	
							local newTask = ffxiv_task_teleport.Create()
							newTask.aetheryte = 214
							newTask.mapID = 1192
							ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
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
		ml_navigation:CancelFlightFollowCam()
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
	return FFXIVLib.API.Map.IsDeepDungeon(mapid) or false
end

function IsHW(mapid)
	return FFXIVLib.API.Map.GetExpansion(mapid) == 1
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
	--elseif (IsControlOpen("CutSceneSelectString")) then
	--	controlName = "CutSceneSelectString"
	end
	
	if (controlName) then
		local control = GetControl(controlName)
		if (control) then
			return control:GetData()
		end
	end
	
	-- This change breaks the questing profiles that rely on it.
	
	if (IsControlOpen("CutSceneSelectString")) then
		local control = GetControl("CutSceneSelectString")
		if (control) then
			local rawtable = control:GetRawData()
			local stringtable = {}
			local indexcount = 0
			if table.valid(rawtable) then
				for index, data in pairsByKeys(rawtable) do
					if (data.type == "string") then
						stringtable[indexcount] = data.value
						indexcount = indexcount + 1
					end
				end
			end
			return stringtable
		end
	end
	
	
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
	
	local y1 = pos.y or 0
	local y2 = pos.y or 0
				
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
				local failedInteracts = ml_global_information and ml_global_information.failedInteracts
				local failTime = (failedInteracts and failedInteracts[interact.id]) or 0
				if (failTime == 0 or TimeSince(failTime) > 30000) then
					local dist = interact.distance2d
					if (not nearest or (nearest and dist < nearestDistance)) then
						nearest, nearestDistance = interact, dist
					end
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
		or IsControlOpen("Talk") or IsControlOpen("Snipe") or IsControlOpen("Request") or IsControlOpen("JournalResult") or IsControlOpen("JournalAccept") or HasBuffs(Player,"1963,1268")
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
	-- Collectable Appraiser ENpc IDs and their access requirements
	local appraisers = {
		{ id = 1049084, aethid = 217, mapid = 1186, quest = 5008 }, -- Solution Nine
		{ id = 1037306, aethid = 183, mapid = 963,  quest = 4175 }, -- Radz-at-Han
		{ id = 1027542, aethid = 134, mapid = 820,  quest = 3603 }, -- Eulmore
		{ id = 1019457, aethid = 104, mapid = 635 },                -- Rhalgr's Reach
		{ id = 1012300, aethid = 75,  mapid = 478 },                -- Idyllshire
		{ id = 1013396, aethid = 24,  mapid = 156 },                -- Mor Dhona
		{ id = 1003076, aethid = 2,   mapid = 133 },                -- Old Gridania
		{ id = 1003632, aethid = 8,   mapid = 129 },                -- Limsa Lominsa
		{ id = 1001616, aethid = 9,   mapid = 131 },                -- Ul'dah
	}

	-- Resolve NPC positions from game data
	local function resolveAppraiser(entry)
		local spawns = FFXIVLib.API.NPC.GetENpcSpawns(entry.id)
		if spawns and #spawns > 0 then
			-- Find the spawn on the expected map
			for _, spawn in ipairs(spawns) do
				if spawn.mapid == entry.mapid then
					return { id = entry.id, aethid = entry.aethid, mapid = entry.mapid,
						pos = { x = spawn.x, y = spawn.y, z = spawn.z } }
				end
			end
			-- Fallback to first spawn
			local s = spawns[1]
			return { id = entry.id, aethid = entry.aethid, mapid = entry.mapid,
				pos = { x = s.x, y = s.y, z = s.z } }
		end
		return nil
	end

	-- Check if player is already on an appraiser's map
	for _, entry in ipairs(appraisers) do
		if Player.localmapid == entry.mapid then
			if not entry.quest or QuestCompleted(entry.quest) then
				return resolveAppraiser(entry)
			end
		end
	end

	-- Find cheapest reachable appraiser via aetheryte cost
	local gil = GilCount()
	local attuned = FFXIVLib.API.Map.GetAetherytes(1)
	if not table.valid(attuned) then return nil end

	local best = nil
	local bestCost = math.huge
	for _, entry in ipairs(appraisers) do
		if not entry.quest or QuestCompleted(entry.quest) then
			local aetheryte = attuned[entry.aethid]
			if aetheryte and gil >= aetheryte.price then
				if aetheryte.price < bestCost then
					bestCost = aetheryte.price
					best = entry
				end
			end
		end
	end

	if best then
		return resolveAppraiser(best)
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
	
	if FFXIVLib.API.Map.IsInn(Player.localmapid) then
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
		local attuned = FFXIVLib.API.Map.GetAetherytes(1)
		if (table.valid(attuned)) then
			for _, aetheryte in pairs(attuned) do
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
	return FFXIVLib.API.Map.IsFieldZone(mapid) or IsHousingMap(mapid) or IsInn(mapid) or IsCityMap(mapid)
end
function IsHousingMap(mapid)
	return FFXIVLib.API.Map.IsHousingZone(mapid)
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
		[1185] = true,	
		[1186] = true,
	}
	return cityMaps[mapid]
end
function IsInn(mapid)
	return FFXIVLib.API.Map.IsInn(mapid)
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
		if (includepet) then
			if (Player.pet) then
				if (Player.pet.incombat) then
					return true
				end
			end
		elseif (includecompanion) then
			local companion = GetCompanionEntity()
			if (companion) then
				if (companion.alive and companion.incombat) then
					return true
				end
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

-- Returns center points and portal positions for the given map
-- mapid: 1237 = Moon, 1291 = Phaenna, 1310 = Oizys
function GetCosmicCenterPoints(mapid)
	return FFXIVLib.API.CosmicExploration.GetCenterPoints(mapid or 1237)
end

function GetCosmicPortalPositions(mapid)
	return FFXIVLib.API.CosmicExploration.GetPortalPositions(mapid or 1237)
end

---------------------------------------------------------------------------------------------
--ADD_TASK CNEs
--These are cnes which are used to check the current game state and add a new task/subtask
--based on the needs of the parent task they are assigned to. They differ from the task
--completion CNEs since they don't perform any action other than to queue a new task. 
--Every task must have a CNE like this to queue it when appropriate. They can be placed
--in either the process elements or the overwatch elements for a task based on the priority
--of the task they queue. MOVETOTARGET, for instance, should be placed in the overwatch
--list since it needs to be checked continually for moving targets; COMBAT can be placed
--into the process list since there is no need to queue another combat task until the
--previous combat task is completed and control returns to the parent task.
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--ADD_KILLTARGET: If (current target hp > 0) Then (add longterm killtarget task)
--Adds a killtarget task if target hp > 0
---------------------------------------------------------------------------------------------
c_add_killtarget = inheritsFrom( ml_cause )
e_add_killtarget = inheritsFrom( ml_effect )
c_add_killtarget.oocCastTimer = 0
function c_add_killtarget:evaluate()
	-- block killtarget for grinding when user has specified "Fates Only"
	if ((ml_task_hub:CurrentTask().name == "LT_GRIND" or ml_task_hub:CurrentTask().name == "LT_PARTY" ) and gFatesOnly == "1") then
		if (ml_task_hub:CurrentTask().name == "LT_GRIND") then
			local aggro = GetNearestAggro()
			if ValidTable(aggro) then
				if (aggro.hp.current > 0 and aggro.id and aggro.id ~= 0 and aggro.distance <= 30) then
					c_add_killtarget.targetid = aggro.id
					d("Adding an aggro target in first block.")
					return true
				end
			end
		end
        return false
    end
	
	if (gBotMode == GetString("partyMode") and not IsPartyLeader()) then
        return false
    end
	
	if not (ml_task_hub:ThisTask().name == "LT_FATE" and ml_task_hub:CurrentTask().name == "MOVETOPOS") then
		local aggro = GetNearestAggro()
		if ValidTable(aggro) then
			if (aggro.hp.current > 0 and aggro.id and aggro.id ~= 0 and aggro.distance <= 30) then
				d("Adding an aggro target.")
				c_add_killtarget.targetid = aggro.id
				return true
			end
		end 
	end
    
	if (SkillMgr.Cast( Player, true)) then
		c_add_killtarget.oocCastTimer = Now() + 1500
		return false
	end
	
	if (MIsCasting() or Now() < c_add_killtarget.oocCastTimer) then
		return false
	end
	
	local target = ml_task_hub:CurrentTask().targetFunction()
    if (ValidTable(target)) then
        if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0) then
			d("Picked target in normal block.")
            c_add_killtarget.targetid = target.id
            return true
        end
    end
    
    return false
end
function e_add_killtarget:execute()
	local newTask = ffxiv_task_grindCombat.Create()
	newTask.betterTargetFunction = ml_task_hub:CurrentTask().targetFunction
	newTask.targetid = c_add_killtarget.targetid
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_killaggrotarget = inheritsFrom( ml_cause )
e_killaggrotarget = inheritsFrom( ml_effect )
c_killaggrotarget.targetid = 0
function c_killaggrotarget:evaluate()
	if (gBotMode == GetString("partyMode") and IsPartyLeader() ) then
        return false
    end
	
	if (gBotMode == GetString("partyMode")) then
		local leader, isEntity = GetPartyLeader()	
		if (leader and leader.id ~= 0) then
			local entity = EntityList:Get(leader.id)
			if ( entity  and entity.id ~= 0) then
				if ((entity.incombat and entity.distance > 7) or (not entity.incombat and entity.distance > 10) or (entity.ismounted) or Player.ismounted) then
					return false
				end
			end
		end
	end
	
    local target = GetNearestAggro()
	if (ValidTable(target)) then
		if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0) then
			c_killaggrotarget.targetid = target.id
			return true
		end
	end
    
    return false
end
function e_killaggrotarget:execute()
	local newTask = ffxiv_task_grindCombat.Create()
	Player:SetTarget(c_killaggrotarget.targetid)
    newTask.targetid = c_killaggrotarget.targetid
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end
---------------------------------------------------------------------------------------------
---- minion attacks the target the leader has
--Adds a task to use a combat routine to attack/kill target 
---------------------------------------------------------------------------------------------
c_assistleader = inheritsFrom( ml_cause )
e_assistleader = inheritsFrom( ml_effect )
c_assistleader.targetid = nil
c_assistleader.movementDelay = 0
function c_assistleader:evaluate()
    if (gBotMode == GetString("partyMode") and IsPartyLeader()) then
        return false
    end
	
    local leader, isEntity = GetPartyLeader()	
    if (ValidTable(leader) and isEntity) then
		local leadtarget = leader.targetid
		if (leader.ismounted or not leader.incombat or not leadtarget or leadtarget == 0) then
			return false			
		end
		
		if (ml_task_hub:ThisTask().subtask) then
			local task = ml_task_hub:ThisTask().subtask
			if (task.name == "GRIND_COMBAT" and task.targetid == leadtarget) then
				return false
			end
		end
		
		if (NotQueued()) then
			--d("executing not queued version>")
			local target = EntityList:Get(leadtarget)				
			if ( ValidTable(target) and target.alive and (target.onmesh or InCombatRange(target.id))) then
				c_assistleader.targetid = target.id
				return true
			end
		else	
			--d("executing queued version>")
			local target = EntityList:Get(leadtarget)				
			if ( ValidTable(target) and target.alive and target.targetid == leader.id and (target.onmesh or InCombatRange(target.id))) then
				c_assistleader.targetid = target.id
				return true
			end
		end
    end
    
    return false
end
function e_assistleader:execute()
	local id = c_assistleader.targetid
	if ( Player.ismounted ) then
		Dismount()
		return
	end
	
	if (NotQueued()) then
		--d("executing nonqueued")
		if (ml_task_hub:CurrentTask().name == "GRIND_COMBAT") then
			--d("setting new id to "..tostring(id))
			ml_task_hub:CurrentTask().targetid = id
		else
			--d("starting new grind combat for id "..tostring(id))
			local newTask = ffxiv_task_grindCombat.Create()
			newTask.targetid = id 
			newTask.noFateSync = true
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	else
		if (c_avoid:evaluate()) then
			e_avoid:execute()
			return
		end
		
		if (c_autopotion:evaluate()) then
			e_autopotion:execute()
			return
		end

		--d("executing queued")
		local target = MGetEntity(c_assistleader.targetid)
		local pos = target.pos
		local ppos = Player.pos
		local dist = PDistance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
		
		if (ml_global_information.AttackRange > 5) then
			--d("executing caster version")
			if ((not InCombatRange(target.id) or not target.los) and not MIsCasting()) then
				if (Now() > c_assistleader.movementDelay) then
					if (target.distance <= (target.hitradius + 1)) then
						Player:MoveTo(pos.x,pos.y,pos.z, 1.5, false, false, false)
					else
						Player:MoveTo(pos.x,pos.y,pos.z, (target.hitradius + 1), false, false, false)
					end
					c_assistleader.movementDelay = Now() + 1000
				end
			end
			if (InCombatRange(target.id)) then
				Player:SetTarget(target.id)
				if (Player.ismounted) then
					Dismount()
				end
				if (Player:IsMoving() and target.los) then
					Player:Stop()
					if (IsCaster(Player.job)) then
						return
					end
				end
				if (not EntityIsFrontTight(target)) then
					Player:SetFacing(pos.x,pos.y,pos.z) 
				end
			end
			if (InCombatRange(target.id) and target.attackable and target.alive) then
				SkillMgr.Cast( target )
			end
		else
			--d("Melee class, check if we're in combat range and such..")
			Player:SetTarget(target.id)
			if (not InCombatRange(target.id) or not target.los) then
				Player:MoveTo(pos.x,pos.y,pos.z, 1.5, false, false, false)
			end
			if (InCombatRange(target.id)) then
				Player:SetTarget(target.id)
				Player:SetFacing(pos.x,pos.y,pos.z) 
				if (target.los) then
					Player:Stop()
				end
			end
				
			SkillMgr.Cast( target )
		end
	end
end

---------------------------------------------------------------------------------------------
--ADD_COMBAT: If (target hp > 0) Then (add combat task)
--Adds a task to use a combat routine to attack/kill target 
---------------------------------------------------------------------------------------------
c_add_combat = inheritsFrom( ml_cause )
e_add_combat = inheritsFrom( ml_effect )
function c_add_combat:evaluate()
	
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
	
	--Do some special checking here for hunts.
	if (target) then
		if (ml_task_hub:RootTask().name == "LT_HUNT") then
			if (ml_task_hub:CurrentTask().rank == "S") then
				local allies = EntityList("alive,friendly,chartype=4,targetable,maxdistance=50")
				if ((target.hp.percent > tonumber(gHuntSRankHP)) and (not allies or TableSize(allies) < tonumber(gHuntSRankAllies))) then
					return false
				end
			elseif (ml_task_hub:CurrentTask().rank == "A") then
				local allies = EntityList("alive,friendly,chartype=4,targetable,maxdistance=50")
				if ((target.hp.percent > tonumber(gHuntARankHP)) and (not allies or TableSize(allies) < tonumber(gHuntARankAllies))) then
					return false
				end
			elseif (ml_task_hub:CurrentTask().rank == "B") then
				if (Now() < ml_task_hub:CurrentTask().waitTimer and target.targetid == 0) then
					return false
				end
			end
		end
	end
	
	--If we made it this far without stopping, assume the target can be safely engaged.
	if (not ml_task_hub:CurrentTask().canEngage) then
		ml_task_hub:CurrentTask().canEngage = true
	end
	
	if (target and target.id ~= 0) then
		return InCombatRange(target.id) and target.alive and not IsMounting()
	end
        
    return false
end
function e_add_combat:execute()
	Dismount()
	
	if (IsMounting() or Player.ismounted) then	
		return
	end
	
    if ( gSMactive == "1" ) then
        local newTask = ffxiv_task_skillmgrAttack.Create()
        newTask.targetid = ml_task_hub:CurrentTask().targetid
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    else
		ml_debug("Skill manager is not active, defaulting to class routine.")
        local newTask = ml_global_information.CurrentClass.Create()
        newTask.targetid = ml_task_hub:CurrentTask().targetid
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

---------------------------------------------------------------------------------------------
--ADD_FATE: If (fate of proper level is on mesh) Then (add longterm fate task)
--Adds a fate task if there is a fate on the mesh
---------------------------------------------------------------------------------------------
c_add_fate = inheritsFrom( ml_cause )
e_add_fate = inheritsFrom( ml_effect )
c_add_fate.fate = {}
function c_add_fate:evaluate()
    if (gBotMode == GetString("partyMode") and not IsPartyLeader()) then
		return false
    end
	
	c_add_fate.fate = {}
    
    if (gDoFates == "1") then
		local fate = GetClosestFate(ml_global_information.Player_Position,true)
		if (fate and fate.completion < 100) then
			c_add_fate.fate = fate
			return true
		end
    end
    
    return false
end
function e_add_fate:execute()
    local newTask = ffxiv_task_fate.Create()
    newTask.fateid = c_add_fate.fate.id
	newTask.fatePos = {x = c_add_fate.fate.x, y = c_add_fate.fate.y, z = c_add_fate.fate.z}
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_nextatma = inheritsFrom( ml_cause )
e_nextatma = inheritsFrom( ml_effect )
e_nextatma.atma = nil
function c_nextatma:evaluate()	
	if (gAtma == "0" or ml_global_information.Player_InCombat or ffxiv_task_grind.inFate or MIsLoading()) then
		return false
	end
	
	local map = Player.localmapid
	local mapFound = false
	local mapItem = nil
	local itemFound = false
	local getNext = false
	local jpTime = GetJPTime()
	
	--First loop, check for best atma based on JP time theory.
	for a, atma in pairs(ffxiv_task_grind.atmas) do
		if ((tonumber(atma.hour) == jpTime.hour and jpTime.min <= 55) or
			(tonumber(atma.hour) == AddHours12(jpTime.hour,1) and jpTime.min > 55)) then
			local haveBest = false
			--local bestAtma = a
			for x=0,3 do
				local inv = Inventory("type="..tostring(x))
				for i, item in pairs(inv) do
					if (item.id == atma.item) then
						haveBest = true
					end
					if (haveBest) then	
						break
					end
				end
				if (haveBest) then
					break
				end
			end
		
			if (not haveBest) then
				if (atma.map ~= map) then
					e_nextatma.atma = atma
					return true
				end
			end
		end
	end
	
	--Second loop, check to see if we have this map's atma, and return false if we still don't have it yet.
	for a, atma in pairs(ffxiv_task_grind.atmas) do
		if (atma.map == map) then
			local haveClosest = false
			
			for x=0,3 do
				local inv = Inventory("type="..tostring(x))
				for i, item in pairs(inv) do
					if (item.id == atma.item) then
						haveClosest = true
					end
					if (haveClosest) then	
						break
					end
				end
				if (haveClosest) then
					break
				end
			end
			
			if (not haveClosest) then
				--We're already on the map with the most appropriate atma and we don't have it
				return false
			end
		end
	end
	
	--Third loop, figure out which ones we do have, then go anywhere else.
	for a, atma in pairs(ffxiv_task_grind.atmas) do
		local found = false
		for x=0,3 do
			local inv = Inventory("type="..tostring(x))
			for i, item in pairs(inv) do
				if (item.id == atma.item) then
					found = true
				end
				if (found) then	
					break
				end
			end
			if (found) then
				break
			end
		end
		
		if (not found) then
			e_nextatma.atma = atma
			return true
		end
	end
	
	return false
end
function e_nextatma:execute()
	local atma = e_nextatma.atma
	Player:Stop()
	Dismount()
	
	if (Player.ismounted) then
		return
	end
	
	if (ActionIsReady(7,5)) then
		Player:Teleport(atma.tele)
		ml_task_hub:ThisTask().correctMap = atma.map
		
		local newTask = ffxiv_task_teleport.Create()
		--d("Changing to new location for "..tostring(atma.name).." atma.")
		newTask.aetheryte = atma.tele
		newTask.mapID = atma.map
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	end
end

c_nextluminous = inheritsFrom( ml_cause )
e_nextluminous = inheritsFrom( ml_effect )
e_nextluminous.luminous = nil
function c_nextluminous:evaluate()	
	if (gAtma == "0" or ml_global_information.Player_InCombat or ffxiv_task_grind.inFate or MIsLoading()) then
		return false
	end
	
	e_nextluminous.luminous = nil
	
	local map = Player.localmapid
	local crystals = ffxiv_task_grind.luminous
	
	local mapFound = false
	local mapItem = nil
	local itemFound = false
	local getNext = false
	local jpTime = GetJPTime()
	
	--First loop, check if we can do the one on our current map.
	for i, crystal in pairsByKeys(crystals) do
		--["Ice"] = 		{ name = "Ice", 		map = 397, item = 13569 },
		if (crystal.map == map and ItemCount(crystal.item) < 3) then
			itemFound = true
			
		end
			
		if ((tonumber(atma.hour) == jpTime.hour and jpTime.min <= 55) or
			(tonumber(atma.hour) == AddHours12(jpTime.hour,1) and jpTime.min > 55)) then
			local haveBest = false
			--local bestAtma = a
			for x=0,3 do
				local inv = Inventory("type="..tostring(x))
				for i, item in pairs(inv) do
					if (item.id == atma.item) then
						haveBest = true
					end
					if (haveBest) then	
						break
					end
				end
				if (haveBest) then
					break
				end
			end
		
			if (not haveBest) then
				if (atma.map ~= map) then
					e_nextatma.atma = atma
					return true
				end
			end
		end
	end
	
	--Second loop, check to see if we have this map's atma, and return false if we still don't have it yet.
	for a, atma in pairs(ffxiv_task_grind.atmas) do
		if (atma.map == map) then
			local haveClosest = false
			
			for x=0,3 do
				local inv = Inventory("type="..tostring(x))
				for i, item in pairs(inv) do
					if (item.id == atma.item) then
						haveClosest = true
					end
					if (haveClosest) then	
						break
					end
				end
				if (haveClosest) then
					break
				end
			end
			
			if (not haveClosest) then
				--We're already on the map with the most appropriate atma and we don't have it
				return false
			end
		end
	end
	
	--Third loop, figure out which ones we do have, then go anywhere else.
	for a, atma in pairs(ffxiv_task_grind.atmas) do
		local found = false
		for x=0,3 do
			local inv = Inventory("type="..tostring(x))
			for i, item in pairs(inv) do
				if (item.id == atma.item) then
					found = true
				end
				if (found) then	
					break
				end
			end
			if (found) then
				break
			end
		end
		
		if (not found) then
			e_nextluminous.atma = atma
			return true
		end
	end
	
	return false
end
function e_nextluminous:execute()
	local luminous = e_nextluminous.luminous
	Player:Stop()
	Dismount()
	
	if (Player.ismounted) then
		return
	end
	
	if (ActionIsReady(7,5)) then
		Player:Teleport(atma.tele)
		ml_task_hub:ThisTask().correctMap = atma.map
		
		local newTask = ffxiv_task_teleport.Create()
		--d("Changing to new location for "..tostring(atma.name).." atma.")
		newTask.aetheryte = atma.tele
		newTask.mapID = atma.map
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	end
	
	ml_task_hub:ThisTask().correctMap = atma.map
end

--=======Avoidance============

c_avoid = inheritsFrom( ml_cause )
e_avoid = inheritsFrom( ml_effect )
e_avoid.lastAvoid = {}
c_avoid.newAvoid = {}
function c_avoid:evaluate()	
	if (gAvoidAOE == "0" or tonumber(gAvoidHP) == 0 or tonumber(gAvoidHP) < ml_global_information.Player_HP.percent) then
		return false
	end
	
	if (ml_task_hub:CurrentTask().name == "MOVETOPOS" or 
		ml_task_hub:CurrentTask().name == "MOVETOMAP" or
		ml_task_hub:CurrentTask().name == "MOVETOINTERACT") 
	then
		return false
	end
	
	--Reset tempvar.
	c_avoid.newAvoid = {}
	
	-- Check for nearby enemies casting things on us.
	local el = EntityList("aggro,incombat,onmesh,maxdistance=40")
	if (ValidTable(el)) then
		for i,e in pairs(el) do
			local shouldAvoid, spellData = AceLib.API.Avoidance.GetAvoidanceInfo(e)
			if (shouldAvoid and spellData) then
				local lastAvoid = c_avoid.lastAvoid
				if (lastAvoid) then
					if (spellData.id == lastAvoid.data.id and e.id == lastAvoid.attacker.id and Now() < lastAvoid.timer) then
						--d("Don't dodge, we already dodged this recently.")
						return false							
					end
				end
				
				--c_avoid.newAvoid = { timer = Now() + (castTime * 1000), spell = avoidableSpell, attacker = e, persistent = isPersistent }
				c_avoid.newAvoid = { timer = Now() + (spellData.castTime * 1000), data = spellData, attacker = e }
				return true
			end
		end
	end
	
	local el = EntityList("alive,incombat,attackable,onmesh,maxdistance=25")
	if (ValidTable(el)) then
		for i,e in pairs(el) do
			local shouldAvoid, spellData = AceLib.API.Avoidance.GetAvoidanceInfo(e)
			if (shouldAvoid and spellData) then
				local lastAvoid = c_avoid.lastAvoid
				if (lastAvoid) then
					if (spellData.id == lastAvoid.data.id and e.id == lastAvoid.attacker.id and Now() < lastAvoid.timer) then
						--d("Don't dodge, we already dodged this recently.")
						return false							
					end
				end
				
				--c_avoid.newAvoid = { timer = Now() + (castTime * 1000), spell = avoidableSpell, attacker = e, persistent = isPersistent }
				c_avoid.newAvoid = { timer = Now() + (spellData.castTime * 1000), data = spellData, attacker = e }
				return true
			end
		end
	end
	
	return false
end
function e_avoid:execute() 			
	local newPos,seconds,obstacle = AceLib.API.Avoidance.GetAvoidancePos(c_avoid.newAvoid)
	
	if (ValidTable(newPos)) then
		local ppos = ml_global_information.Player_Position
		local moveDist = PDistance3D(ppos.x,ppos.y,ppos.z,newPos.x,newPos.y,newPos.z)
		if (moveDist > 1.5) then
			if (ValidTable(obstacle)) then
				--table.insert(ml_global_information.navObstacles,obstacle)
				d("Adding nav obstacle.")
			end
			c_avoid.lastAvoid = c_avoid.newAvoid
			local newTask = ffxiv_task_avoid.Create()
			newTask.pos = newPos
			newTask.targetid = c_avoid.newAvoid.attacker.id
			newTask.attackTarget = IsNull(ml_task_hub:ThisTask().targetid,0)
			newTask.interruptCasting = true
			newTask.maxTime = seconds
			ml_task_hub:ThisTask().preserveSubtasks = true
			ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
			d("Adding avoidance task.")
			
			c_bettertargetsearch.postpone = Now() + 5000
		end
	else
		d("Can't dodge, didn't find a valid position.")
	end
end

c_autopotion = inheritsFrom( ml_cause )
e_autopotion = inheritsFrom( ml_effect )
c_autopotion.potions = {
	{ minlevel = 50, item = 13637 },
	{ minlevel = 40, item = 4554 },
	{ minlevel = 30, item = 4553 },
	{ minlevel = 10, item = 4552 },
	{ minlevel = 1, item = 4551 },
}
c_autopotion.ethers = {
	{ minlevel = 50, item = 13638 },
	{ minlevel = 40, item = 4558 },
	{ minlevel = 30, item = 4557 },
	{ minlevel = 10, item = 4556 },
	{ minlevel = 1, item = 4555 },
}
c_autopotion.item = nil
function c_autopotion:evaluate()
	if (MIsLocked() or MIsLoading() or ControlVisible("SelectString") or ControlVisible("SelectIconString") 
		or IsShopWindowOpen() or Player.ismounted or IsFlying() or IsTransporting() or not Player.incombat) 
	then
		return false
	end
	
	-- Reset tempvar.
	c_autopotion.item = nil
	
	if (Player.alive) then
		local potions = c_autopotion.potions
		if (tonumber(gPotionHP) > 0 and ml_global_information.Player_HP.percent < tonumber(gPotionHP)) then
			for k,itempair in pairsByKeys(potions) do
				if (Player.level >= itempair.minlevel) then
					local item = Inventory:Get(tonumber(itempair.item))
					if (item and item.isready) then
						c_autopotion.item = item
						return true
					end
					
					local hqitem = Inventory:Get(tonumber(itempair.item) + 1000000)
					if (hqitem and hqitem.isready) then
						c_autopotion.item = hqitem
						return true
					end
				end
			end
		end
		
		local ethers = c_autopotion.ethers
		if (tonumber(gPotionMP) > 0 and ml_global_information.Player_MP.percent < tonumber(gPotionMP)) then
			for k,itempair in pairsByKeys(ethers) do
				if (Player.level >= itempair.minlevel) then
					local item = Inventory:Get(tonumber(itempair.item))
					if (item and item.isready) then
						c_autopotion.item = item
						return true
					end
					
					local hqitem = Inventory:Get(tonumber(itempair.item) + 1000000)
					if (hqitem and hqitem.isready) then
						c_autopotion.item = hqitem
						return true
					end
				end
			end
		end
	end
	
	return false
end
function e_autopotion:execute()
	local item = c_autopotion.item
	if (item and item.isready) then
		item:Use()
	end
	--local newTask = ffxiv_task_useitem.Create()
	--newTask.itemid = c_autopotion.itemid
	--ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
end

---------------------------------------------------------------------------------------------
--ADD_MOVETOTARGET: If (current target distance > combat range) Then (add movetotarget task)
--Adds a MoveToTarget task 
---------------------------------------------------------------------------------------------
c_movetotarget = inheritsFrom( ml_cause )
e_movetotarget = inheritsFrom( ml_effect )
function c_movetotarget:evaluate()
	if ( not ml_task_hub:CurrentTask().canEngage ) then
		return false
	end
	
    if ( ml_task_hub:CurrentTask().targetid ~= nil and ml_task_hub:CurrentTask().targetid ~= 0 ) then
        local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
        if (target and target.id ~= 0 and target.alive) then
            return not InCombatRange(target.id)
        end
    end
    
    return false
end
function e_movetotarget:execute()
    ml_debug( "Moving within combat range of target" )
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = target.pos
	newTask.targetid = target.id
	newTask.useFollowMovement = false
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_movecloser = inheritsFrom( ml_cause )
e_movecloser = inheritsFrom( ml_effect )
function c_movecloser:evaluate()
	if ( ml_task_hub:CurrentTask().targetid ~= nil and ml_task_hub:CurrentTask().targetid ~= 0 ) then
		local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
		if (target and target.id ~= 0 and target.alive) then
			return (target.distance > 40)
		end
	end
	
	return false
end
function e_movecloser:execute()
	local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = target.pos
	newTask.targetid = target.id
	newTask.useFollowMovement = false
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_movetotargetsafe = inheritsFrom( ml_cause )
e_movetotargetsafe = inheritsFrom( ml_effect )
function c_movetotargetsafe:evaluate()
	if ( ml_task_hub:CurrentTask().canEngage ) then
		return false
	end
	
    if ( ml_task_hub:CurrentTask().targetid and ml_task_hub:CurrentTask().targetid ~= 0 ) then
        local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
        if (target and target.id ~= 0 and target.alive) then
			local tpos = target.pos
			local pos = ml_global_information.Player_Position
			if (Distance3D(tpos.x,tpos.y,tpos.z,pos.x,pos.y,pos.z) > (ml_task_hub:CurrentTask().safeDistance + 2)) then
				return true
			end
        end
    end
    
    return false
end
function e_movetotargetsafe:execute()
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
	local newTask = ffxiv_task_movetopos.Create()
	newTask.range = ml_task_hub:CurrentTask().safeDistance
	newTask.pos = target.pos
	newTask.targetid = target.id
	newTask.useFollowMovement = false
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

---------------------------------------------------------------------------------------------
--ADD_MOVETOMAP
--Adds a MoveToGate task 
---------------------------------------------------------------------------------------------
c_interactgate = inheritsFrom( ml_cause )
e_interactgate = inheritsFrom( ml_effect )
e_interactgate.timer = 0
e_interactgate.id = 0
e_interactgate.selector = 0
function c_interactgate:evaluate()
	if (MIsLoading() or MIsLocked() or MIsCasting(true)) then
		return false
	end
	
	e_interactgate.id = 0
	e_interactgate.selector = 0
	
    if (ml_task_hub:CurrentTask().destMapID) then
		if (Player.localmapid ~= ml_task_hub:CurrentTask().destMapID) then
			local pos = ml_nav_manager.GetNextPathPos(	ml_global_information.Player_Position, 
														Player.localmapid,	
														ml_task_hub:CurrentTask().destMapID	)

			if (ValidTable(pos) and pos.g) then				
				local interacts = EntityList("targetable,maxdistance=4,contentid="..tostring(pos.g))
				if (ValidTable(interacts)) then
					local i,interactable = next(interacts)
					if (i and interactable) then
						e_interactgate.id = interactable.id
						if (pos.i) then
							e_interactgate.selector = pos.i
						end
						return true
					end
				end
			end
		end
	end
	
	return false
end
function e_interactgate:execute()
	if (Now() < e_interactgate.timer) then
		return false
	end
	
	if (Player:IsMoving()) then
		Player:Stop()
	end
	
	if (ControlVisible("SelectString") or ControlVisible("SelectIconString")) then
		local selector = e_interactgate.selector
		SelectConversationIndex(selector)
		e_interactgate.timer = Now() + 1500
		return
	end
	
	local gate = EntityList:Get(e_interactgate.id)
	local pos = gate.pos
	SetFacing(pos.x,pos.y,pos.z)
	Player:Interact(gate.id)
	e_interactgate.timer = Now() + 1500
end

c_transportgate = inheritsFrom( ml_cause )
e_transportgate = inheritsFrom( ml_effect )
e_transportgate.details = nil
function c_transportgate:evaluate()
	if (MIsLoading() or MIsLocked() or MIsCasting(true)) then
		return false
	end
	
	if (ml_task_hub:ThisTask().destMapID) then
		if (Player.localmapid ~= ml_task_hub:CurrentTask().destMapID) then
			local pos = ml_nav_manager.GetNextPathPos( 	ml_global_information.Player_Position,	
														Player.localmapid,	
														ml_task_hub:CurrentTask().destMapID	)
			
			if (ValidTable(pos)) then
				if (not c_usenavinteraction:evaluate(pos)) then
					if (ValidTable(pos) and pos.b) then
						local details = {}
						details.uniqueid = pos.b
						details.pos = { x = pos.x, y = pos.y, z = pos.z }
						details.conversationIndex = pos.i or 0
						e_transportgate.details = details
						return true
					elseif (ValidTable(pos) and pos.a) then
						local details = {}
						details.uniqueid = pos.a
						details.pos = { x = pos.x, y = pos.y, z = pos.z }
						details.conversationIndex = pos.i or 0
						e_transportgate.details = details
						return true
					end
				end
			end
		end
	end
	
	return false
end
function e_transportgate:execute()
	local gateDetails = e_transportgate.details
	local newTask = ffxiv_nav_interact.Create()
	if (gTeleport == "1") then
		newTask.useTeleport = true
	end
	newTask.destMapID = ml_task_hub:CurrentTask().destMapID
	newTask.pos = gateDetails.pos
	newTask.uniqueid = gateDetails.uniqueid
	newTask.conversationIndex = gateDetails.conversationIndex
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_movetogate = inheritsFrom( ml_cause )
e_movetogate = inheritsFrom( ml_effect )
e_movetogate.pos = {}
function c_movetogate:evaluate()
	if (MIsLoading() or 
		(MIsLocked() and not IsFlying()) or 
		MIsCasting() or
		Player.localmapid == 0) 
	then
		return false
	end
	
	e_movetogate.pos = {}
	
    if (ml_task_hub:CurrentTask().destMapID and (Player.localmapid ~= ml_task_hub:CurrentTask().destMapID)) then
        local pos = ml_nav_manager.GetNextPathPos(	ml_global_information.Player_Position,
													Player.localmapid,
													ml_task_hub:CurrentTask().destMapID	)
		if (ValidTable(pos)) then
			e_movetogate.pos = pos
			return true
		else
			local backupPos = ml_nav_manager.GetNextPathPos(	ml_global_information.Player_Position,
																Player.localmapid,
																155	)
			if (ValidTable(backupPos)) then
				ml_task_hub:CurrentTask().destMapID = 155
				e_movetogate.pos = backupPos
				return true
			end
		end
	end
	
	return false
end
function e_movetogate:execute()
	local pos = e_movetogate.pos
	
	local mapid = ml_task_hub:CurrentTask().destMapID
	if (mapid == 399 and Player.localmapid == 478) then
		local destPos = ml_task_hub:CurrentTask().pos
		if (ValidTable(destPos)) then
			if (GetHinterlandsSection(destPos) == 1) then
				d("Destination is hinterlands section 1.")
				pos = {x = 73.259323120117, y = 205, z = 143.04707336426, h = -0.52216768264771}
			else
				d("Destination is hinterlands section 2.")
				pos = {x = 147.0463, y = 207, z = 115.8594, h = 0.9793}
			end
		end
	end
	
	local newTask = ffxiv_task_movetopos.Create()
	newTask.use3d = false
	newTask.pos = pos
	local newPos = { x = pos.x, y = pos.y, z = pos.z }
	local newPos = GetPosFromDistanceHeading(newPos, 5, pos.h)
	
	if (not e_movetogate.pos.g and not e_movetogate.pos.b and not e_movetogate.pos.a) then
		newTask.gatePos = newPos
	end
	
	newTask.range = 0.5
	newTask.remainMounted = true
	newTask.ignoreAggro = true
	newTask.destMapID = ml_task_hub:CurrentTask().destMapID
	if (gTeleport == "1") then
		newTask.useTeleport = true
	end
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_leavelockedarea = inheritsFrom( ml_cause )
e_leavelockedarea = inheritsFrom( ml_effect )
e_leavelockedarea.map = 0
function c_leavelockedarea:evaluate()
	if (MIsLoading() or MIsLocked() or MIsCasting(true)) then
		return false
	end
	
	e_leavelockedarea.map = 0
	
    if (ml_task_hub:CurrentTask().destMapID and (Player.localmapid ~= ml_task_hub:CurrentTask().destMapID)) then
        local pos = ml_nav_manager.GetNextPathPos(	ml_global_information.Player_Position,
													Player.localmapid,
													ml_task_hub:CurrentTask().destMapID	)
		if (not ValidTable(pos)) then
			-- No valid path forward, set a new destination for the nearest map.
			local currNode = ml_nav_manager.GetNode(Player.localmapid)
			if (ValidTable(currNode)) then
				local neighbors = currNode:ValidNeighbors()
				if (ValidTable(neighbors)) then
					local nearest = nil
					local nearestDistance = math.huge
					local ppos = ml_global_information.Player_Position
					
					for id,entries in pairs(neighbors) do
						for _,gate in pairs(entries) do
							local dist = PDistance3D(ppos.x,ppos.y,ppos.z,gate.x,gate.y,gate.z)
							if (not nearest or (nearest and dist < nearestDistance)) then
								nearest = id
								nearestDistance = dist
							end
						end
					end
					
					if (nearest) then
						e_leavelockedarea.map = nearest
					end
				end
			end
		end
	end
end
function e_leavelockedarea:execute()
	ml_task_hub:CurrentTask().destMapID = e_leavelockedarea.map
end

c_teleporttomap = inheritsFrom( ml_cause )
e_teleporttomap = inheritsFrom( ml_effect )
e_teleporttomap.aeth = nil
function c_teleporttomap:evaluate()
	if (MIsLoading() or 
		(MIsLocked() and not IsFlying()) or 
		MIsCasting() or GilCount() < 1500 or
		IsNull(ml_task_hub:ThisTask().destMapID,0) == 0 or
		IsNull(ml_task_hub:ThisTask().destMapID,0) == Player.localmapid) 
	then
		ml_debug("Cannot use teleport, position is locked, or we are casting, or our gil count is less than 1500.")
		return false
	end
	
	e_teleporttomap.aeth = nil
	
	local el = EntityList("alive,attackable,onmesh,aggro")
	if (ValidTable(el)) then
		ml_debug("Cannot use teleport, we have aggro currently.")
		return false
	end
	
	--Only perform this check when dismounted.
	local teleport = ActionList:Get(7,5)
	if (not teleport or not teleport.isready or Player.castinginfo.channelingid == 5) then
		ml_debug("Cannot use teleport, the spell is not ready or we are already casting it.")
		return false
	end
	
	local noTeleportMaps = { [177] = true, [178] = true, [179] = true }
	if (noTeleportMaps[Player.localmapid]) then
		d("Cannot teleport to that map.")
		return false
	end
	
	local destMapID = ml_task_hub:ThisTask().destMapID
    if (destMapID) then
        local pos = ml_nav_manager.GetNextPathPos(	ml_global_information.Player_Position,
                                                    Player.localmapid,
                                                    destMapID	)
		if (ValidTable(pos)) then
			local ppos = ml_global_information.Player_Position
			local dist = PDistance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
			
			if (ValidTable(ml_nav_manager.currPath) and (TableSize(ml_nav_manager.currPath) > 2 or (TableSize(ml_nav_manager.currPath) <= 2 and dist > 120))) then
				
				local aeth = GetAetheryteByMapID(destMapID, ml_task_hub:ThisTask().pos)
				if (aeth) then
					e_teleporttomap.aeth = aeth
					return true
				end
				
				local lastAeth = nil
				for _, node in pairsByKeys(ml_nav_manager.currPath) do
					if (node.id ~= Player.localmapid) then
						local aeth = GetAetheryteByMapID(node.id)
						if (aeth) then
							lastAeth = aeth
						end
					end
				end
				
				if (lastAeth ~= nil) then
					e_teleporttomap.aeth = lastAeth
					return true
				end
			end
		else
			--d("Attempting to find aetheryte for mapid ["..tostring(destMapID).."].")
			local aeth = GetAetheryteByMapID(destMapID, ml_task_hub:ThisTask().pos)
			if (aeth) then
				e_teleporttomap.aeth = aeth
				return true
			end
			
			local attunedAetherytes = GetAttunedAetheryteList()
			-- Fall back check to see if we can get to Foundation, and from there to the destination.
			for k,aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.id == 70 and GilCount() >= aetheryte.price) then
					local aethPos = {x = -68.819107055664, y = 8.1133041381836, z = 46.482696533203}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,418,destMapID)
					if (ValidTable(backupPos)) then
						e_teleporttomap.aeth = aetheryte
						return true
					end
				end
			end
		end
	else
		ml_debug("Cannot use teleport, no destination map ID was provided.")
    end
    
    return false
end
function e_teleporttomap:execute()
	if (Player:IsMoving()) then
		Player:Stop()
		return
	end
	
	if (ActionIsReady(7,5)) then
		if (Player:Teleport(e_teleporttomap.aeth.id)) then	
		
			ml_global_information.Await(10000, function () return Quest:IsLoading() end)
			
			if (ml_task_hub:CurrentTask().name ~= "MOVETOMAP") then
				ml_task_hub:CurrentTask().completed = true
			end
		
			local newTask = ffxiv_task_teleport.Create()
			newTask.setHomepoint = ml_task_hub:ThisTask().setHomepoint
			newTask.aetheryte = e_teleporttomap.aeth.id
			newTask.mapID = e_teleporttomap.aeth.territory
			ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
			ml_task_hub:CurrentTask():SetDelay(1500)
		end
	end
end

c_followleader = inheritsFrom( ml_cause )
e_followleader = inheritsFrom( ml_effect )
c_followleader.range = math.random(3,8)
c_followleader.leaderpos = nil
c_followleader.leader = nil
c_followleader.distance = nil
c_followleader.hasEntity = false
e_followleader.isFollowing = false
e_followleader.stopFollow = false
function c_followleader:evaluate()
	if ((gBotMode == GetString("partyMode") and IsPartyLeader()) or MIsCasting(true)) then
        return false
    end
	
	local leader, isEntity = GetPartyLeader()
	local leaderPos = GetPartyLeaderPos()
	if (ValidTable(leaderPos) and ValidTable(leader)) then
		local myPos = ml_global_information.Player_Position	
		local distance = PDistance3D(myPos.x, myPos.y, myPos.z, leaderPos.x, leaderPos.y, leaderPos.z)
		
		local isHealer = GetRoleString(Player.job) == "healer"
		local isDPS = GetRoleString(Player.job) == "dps"
		local isTank = GetRoleString(Player.job) == "tank"
		
		local rangeClose,rangeFar = 8,12
		if (InInstance() or leader.incombat) then
			rangeClose,rangeFar = 5,8
		end
		
		local passages = EntityList("contentid=2007188")
		if (table.valid(passages)) then
			local i, passage = next(passages)
			if (passage) then
				local passagePos = passage.pos
				if (Distance3DT(passagePos,leaderPos) < 5) then
					rangeClose,rangeFar = 3,3
				end
			end
		end
		
		if ((isHealer and distance > rangeFar) or (isDPS and distance > rangeClose) or (distance > rangeFar)) or (isEntity and (leader.ismounted and not Player.ismounted)) then	
			c_followleader.leaderpos = leaderPos
			c_followleader.leader = leader
			c_followleader.distance = distance
			c_followleader.hasEntity = isEntity
			return true
		end
	end
	
	if (e_followleader.isFollowing) then
		e_followleader.stopFollow = true
		return true
	end
	
    return false
end

function e_followleader:execute()
	local leader = c_followleader.leader
	local leaderPos = c_followleader.leaderpos
	local distance = c_followleader.distance
	
	if (Player.onmesh and e_followleader.isFollowing and e_followleader.stopFollow) then
		Player:Stop()
		e_followleader.isFollowing = false
		e_followleader.stopFollow = false
		return
	end
	
	if (Player.onmesh and not IsPOTD(Player.localmapid)) then	
		-- mount
		
		if (gUseMount == "1" and gMount ~= "None" and c_followleader.hasEntity) then
			if (((leader.castinginfo.channelingid == 4 or leader.ismounted) or distance >= tonumber(gMountDist)) and not Player.ismounted) then
				if (not MIsCasting()) then
					Player:Stop()
					Mount()
				end
				return
			end
		end
		
		--sprint
		if (gUseSprint == "1" and distance >= tonumber(gSprintDist)) then
			if ( not HasBuff(Player.id, 50) and not Player.ismounted) then
				local sprint = ActionList:Get(3)
				if (sprint.isready) then	
					sprint:Cast()
				end
			end
		end
		
		if (gTeleport == "1") then
			if (distance > 100) then
				GameHacks:TeleportToXYZ(leaderPos.x,leaderPos.y,leaderPos.z)
				Player:SetFacingSynced(leaderPos.x,leaderPos.y,leaderPos.z)
			end
		end
		
		if (c_followleader.hasEntity and leader.los) then
			ml_debug( "Moving to Leader: "..tostring(Player:MoveTo(leaderPos.x, leaderPos.y, leaderPos.z, tonumber(c_followleader.range),true,false)))	
		else
			ml_debug( "Moving to Leader: "..tostring(Player:MoveTo(leaderPos.x, leaderPos.y, leaderPos.z, tonumber(c_followleader.range),false,false)))	
		end
		if ( not Player:IsMoving()) then
			if ( ml_global_information.AttackRange < 5 ) then
				c_followleader.range = math.random(4,6)
			else
				c_followleader.range = math.random(10,12)
			end
		end
		e_followleader.isFollowing = true
	else
		if (not Player:IsMoving()) then
			local myPos = Player.pos
			local leaderid = leader.id
			Player:SetFacing(leaderPos.x,leaderPos.y,leaderPos.z)
			Player:Move(FFXIV.MOVEMENT.FORWARD)
			ml_global_information.AwaitDo(1500, 30000, 
				function ()
					if (not Player:IsMoving()) then
						return true
					end
					local leader = EntityList:Get(leaderid)
					if (not leader) then
						return true
					else
						local leaderPos = leader.pos
						local myPos = Player.pos
						return (Distance3DT(leaderPos,myPos) < 4)
					end
					return false
				end,
				function ()
					local leader = EntityList:Get(leaderid)
					if (leader) then
						local leaderPos = leader.pos
						Player:SetFacing(leaderPos.x,leaderPos.y,leaderPos.z)
					end
				end,
				function ()
					if (Player:IsMoving()) then
						Player:Stop()
					end
				end
			)
			--d("Trying to follow target, off mesh.")
			--Player:FollowTarget(leader.id)
			--ml_global_information.Await(1000, function () Player:IsMoving() end)
		end
	end
end

---------------------------------------------------------------------------------------------
--Task Completion CNEs
--These are cnes which are added to the process element list for a task and exist only to
--complete the specified task. They should be specific to the task which contains them...
--their only purpose should be to check the current game state and adjust the behavior of 
--the task in order to ensure its completion. 
---------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
--WALKTOPOS: If (distance to target > task.range) Then (move to pos)
---------------------------------------------------------------------------------------------
c_walktopos = inheritsFrom( ml_cause )
e_walktopos = inheritsFrom( ml_effect )
c_walktopos.pos = 0
e_walktopos.lastRun = 0
e_walktopos.lastPath = 0
e_walktopos.lastFail = 0
e_walktopos.lastStealth = 0
c_walktopos.lastPos = {}
e_walktopos.movedNotMoving = 0
c_walktopos.throttle = 500
function c_walktopos:evaluate()
	if ((MIsLocked() and not IsFlying()) or
		MIsLoading() or
		Player:IsJumping() or 
		IsMounting() or
		ControlVisible("SelectString") or ControlVisible("SelectIconString") or 
		IsShopWindowOpen() or
		(Now() < IsNull(ml_task_hub:CurrentTask().moveWait,0)) or 
		(MIsCasting() and not IsNull(ml_task_hub:CurrentTask().interruptCasting,false))) 
	then
		return false
	end
	
    if (ValidTable(ml_task_hub:CurrentTask().pos) or ValidTable(ml_task_hub:CurrentTask().gatePos)) then		
		local myPos = ml_global_information.Player_Position
		local gotoPos = nil
		if (ml_task_hub:CurrentTask().gatePos) then
			gotoPos = ml_task_hub:CurrentTask().gatePos
			--ml_debug("[c_walktopos]: Position adjusted to gate position.", "gLogCNE", 2)
		else
			gotoPos = ml_task_hub:CurrentTask().pos
			local p,dist = NavigationManager:GetClosestPointOnMesh(gotoPos)
			if (p and dist ~= 0 and dist < 6) then
				--ml_debug("[c_walktopos]: Position adjusted to closest mesh point.", "gLogCNE", 2)
				gotoPos = p
			end
			--ml_debug("[c_walktopos]: Position left as original position.", "gLogCNE", 2)
		end
		
		if (ValidTable(gotoPos)) then
			
			-- If we're very close to an interactable
			local target = MGetTarget()
			if (target) then
				local tpos = target.pos
				local distFromGoal = PDistance3D(tpos.x,tpos.y,tpos.z,gotoPos.x,gotoPos.y,gotoPos.z)
				if (distFromGoal <= 5) then
					if (target.distance < 2.5 and target.los) then
						if (Player:IsMoving()) then
							--d("Stopped because we are very close to the target.")
							Player:Stop()
						end
						return false
					end
				end
			end
			
			local range = ml_task_hub:CurrentTask().range or 0
			if (range > 0) then
				local distance = 0.0
				if (ml_task_hub:CurrentTask().use3d) then
					distance = PDistance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
				else
					distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
				end
			
				if (distance > ml_task_hub:CurrentTask().range) then
					c_walktopos.pos = gotoPos
					return true
				end
			else
				c_walktopos.pos = gotoPos
				return true
			end
		end
    end
	
    return false
end
function e_walktopos:execute()

	if (IsGatherer(Player.job) or IsFisher(Player.job)) then
		local needsStealth = ml_global_information.needsStealth and not ml_task_hub:CurrentTask().alwaysMount
		local hasStealth = HasBuff(Player.id,47)
		if (not hasStealth and needsStealth) then
			if (Player.action ~= 367 and TimeSince(e_walktopos.lastStealth) > 1200) then
				local newTask = ffxiv_task_stealth.Create()
				newTask.addingStealth = true
				ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
				e_walktopos.lastStealth = Now()
				c_walktopos.lastPos = nil
				--d("adding stealth.")
				return
			end
		elseif (hasStealth and not needsStealth) then
			if (Player.action ~= 367 and TimeSince(e_walktopos.lastStealth) > 1200) then
				local newTask = ffxiv_task_stealth.Create()
				newTask.droppingStealth = true
				ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
				e_walktopos.lastStealth = Now()
				--d("dropping stealth.")
				c_walktopos.lastPos = nil
				return
			end
		end
	end

	if (ValidTable(c_walktopos.pos)) then
		local gotoPos = c_walktopos.pos
		local myPos = ml_global_information.Player_Position
		
		if (ValidTable(c_walktopos.lastPos)) then
			local lastPos = c_walktopos.lastPos
			--d("Checking if last wanted position was the same position.")
			local dist = PDistance3D(lastPos.x, lastPos.y, lastPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
			if (dist < 1 and Player.GetNavStatus ~= nil and Player:GetNavStatus() == 1) then
				return
			end
		end
		
		ml_debug("[e_walktopos]: Position = { x = "..tostring(gotoPos.x)..", y = "..tostring(gotoPos.y)..", z = "..tostring(gotoPos.z).."}", "gLogCNE", 2)
		
		local dist = PDistance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
		if (dist > 2) then
			
			ml_debug("[e_walktopos]: Hit MoveTo..", "gLogCNE", 2)
			local path = Player:MoveTo(tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z),1,ml_task_hub:CurrentTask().useFollowMovement or false,gRandomPaths=="1",ml_task_hub:CurrentTask().useSmoothTurns or false)
			
			c_walktopos.lastPos = gotoPos
			if (not tonumber(path)) then
				d("[e_walktopos]: Error occurred in MoveTo, no value was returned generating a path from ["..tostring(round(myPos.x,1))..","..tostring(round(myPos.y,1))..","..tostring(round(myPos.z,1)).."] to ["..tostring(round(gotoPos.x,1))..","..tostring(round(gotoPos.y,1))..","..tostring(round(gotoPos.z,1)).."]")
				
				if (path ~= nil) then
					ml_debug(path)
				end
				Player:Stop()
				e_walktopos.lastFail = Now()
			elseif (path >= 0) then
				d("[e_walktopos]: Path generated by MoveTo with ["..tostring(path).."] points. ["..tostring(round(myPos.x,1))..","..tostring(round(myPos.y,1))..","..tostring(round(myPos.z,1)).."] to ["..tostring(round(gotoPos.x,1))..","..tostring(round(gotoPos.y,1))..","..tostring(round(gotoPos.z,1)).."]")
				
				e_walktopos.lastPath = Now()
				
				if (not Player:IsMoving()) then
					if (e_walktopos.movedNotMoving > 2) then
						Player:Stop()
						e_walktopos.movedNotMoving = 0
					else
						e_walktopos.movedNotMoving = e_walktopos.movedNotMoving + 1
					end						
				end
				
				return
			elseif (path <= -1) then
				d("[e_walktopos]: Error code ["..tostring(path).."] was generated by MoveTo, while creating a path from ["..tostring(round(myPos.x,1))..","..tostring(round(myPos.y,1))..","..tostring(round(myPos.z,1)).."] to ["..tostring(round(gotoPos.x,1))..","..tostring(round(gotoPos.y,1))..","..tostring(round(gotoPos.z,1)).."]")
				
				Player:Stop()
				e_walktopos.lastFail = Now()
			end
		else
			--d("We are very close, make sure we aren't flying.")
			if (not IsFlying()) then
				Player:SetFacing(gotoPos.x,gotoPos.y,gotoPos.z)
				if (not Player:IsMoving()) then
					Player:Move(FFXIV.MOVEMENT.FORWARD)
					e_walktopos.lastRun = Now()
				end
			end
		end
	end
	c_walktopos.pos = 0
end

c_avoidaggressives = inheritsFrom( ml_cause )
e_avoidaggressives = inheritsFrom( ml_effect )
c_avoidaggressives.lastSet = {}
function c_avoidaggressives:evaluate()
	if (IsFlying() or MIsLocked()) then
		return false
	end
	
	local lastSet = c_avoidaggressives.lastSet
	local ppos = Player.pos
	if (ValidTable(lastSet)) then
		if (Player.localmapid == lastSet.mapid) then
			local dist = PDistance3D(lastSet.x,lastSet.y,lastSet.z,ppos.x,ppos.y,ppos.z)
			if (dist <= 80 or Player:IsMoving()) then
				return false
			end
		end
	end
	
	local needsUpdate = false
	
	local aggressives = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance=50")
	if (ValidTable(aggressives)) then
		local avoidanceAreas = ml_global_information.avoidanceAreas
		for i,entity in pairs(aggressives) do
		
			local hasEntry = false
			for i,area in pairs(avoidanceAreas) do
				if (area.id == entity.id) then
					local movedDist = PDistance3D(entity.pos.x,entity.pos.y,entity.pos.z,area.x,area.y,area.z)
					if (area.expiration < Now()) then
						d("Removed avoidance area for ["..tostring(entity.name).."] because it has expired.")
						avoidanceAreas[i] = nil
					elseif (movedDist > 4) then
						d("Removed avoidance area for ["..tostring(entity.name).."] because it is no longer valid.")
						avoidanceAreas[i] = nil
					else
						hasEntry = true
					end
				end
			end
			
			if (not hasEntry) then
				d("Setting avoidance area for ["..tostring(entity.name).."].")
				local newArea = { id = entity.id, x = round(entity.pos.x,1), y = round(entity.pos.y,1), z = round(entity.pos.z,1), level = entity.level, r = 10, expiration = Now() + 15000, source = "c_avoidaggressives" }
				table.insert(avoidanceAreas,newArea)
				needsUpdate = true
			end
		end		
	else
		local avoidanceAreas = ml_global_information.avoidanceAreas
		if (ValidTable(avoidanceAreas)) then
			for i,area in pairs(avoidanceAreas) do
				if (area.source == "c_avoidaggressives") then
					if (TableSize(avoidanceAreas) > 1) then
						avoidanceAreas[i] = nil
						needsUpdate = true
					else
						ml_global_information.avoidanceAreas = {}
						needsUpdate = true
						break
					end
				end
			end
		end
	end
	
	if (needsUpdate) then
		local avoidanceAreas = ml_global_information.avoidanceAreas
		if (ValidTable(avoidanceAreas)) then
			--d("Setting avoidance areas.")
			--NavigationManager:SetAvoidanceAreas(avoidanceAreas)
		else
			--NavigationManager:ClearAvoidanceAreas()
		end
		c_avoidaggressives.lastSet = { mapid = Player.localmapid, x = ppos.x, y = ppos.y, z = ppos.z }
	end
	
	return false
end
function e_avoidaggressives:execute()
	--Do nothing, abusing the cne system a bit here.
end

c_useaethernet = inheritsFrom( ml_cause )
e_useaethernet = inheritsFrom( ml_effect )
e_useaethernet.nearest = nil
e_useaethernet.destination = nil
function c_useaethernet:evaluate(mapid, pos)
	if (true) then
		return false
	end
	
	local gotoPos = pos or ml_task_hub:CurrentTask().pos
	local destMapID = IsNull(ml_task_hub:CurrentTask().destMapID,0)
	if (destMapID == 0) then
		destMapID = Player.localmapid
	end

	e_useaethernet.nearest = nil
	e_useaethernet.destination = nil
	
	if (not table.valid(gotoPos)) then
		return false
	elseif (table.valid(gotoPos) and Distance3DT(gotoPos,Player.pos) < 30 and destMapID == Player.localmapid) then
		return false
	end	
	
	local gotoDist = Distance3DT(gotoPos,Player.pos)
	
	local nearestAethernet,nearestDistance = AceLib.API.Map.GetNearestAethernet(Player.localmapid,Player.pos,1)	
	local bestAethernet,bestDistance = AceLib.API.Map.GetBestAethernet(destMapID,gotoPos)
	if (nearestAethernet and bestAethernet and (nearestAethernet.id ~= bestAethernet.id) and (bestDistance < gotoDist or destMapID ~= Player.localmapid)) then
		if (IsNull(ml_task_hub:CurrentTask().uniqueid,0) ~= nearestAethernet.id) then 
			--d("current id:"..tostring(ml_task_hub:CurrentTask().uniqueid)..", new id:"..tostring(nearestAethernet.id))
			e_useaethernet.nearest = nearestAethernet
			e_useaethernet.destination = bestAethernet
			return true
		end
	end
	
	return false
end
function e_useaethernet:execute()
	if (table.valid(e_useaethernet.nearest)) then
		if (table.valid(e_useaethernet.destination)) then
			--d("Use aethernet task to go from ["..tostring(e_useaethernet.nearest.id).."] to ["..tostring(e_useaethernet.destination.id).."]")
			local newTask = ffxiv_task_moveaethernet.Create()
			newTask.uniqueid = e_useaethernet.nearest.id
			newTask.pos = e_useaethernet.nearest.pos
			newTask.conversationstrings = e_useaethernet.destination.conversationstrings
			newTask.useAethernet = true
			
			ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
		end
	end
end

c_unlockaethernet = inheritsFrom( ml_cause )
e_unlockaethernet = inheritsFrom( ml_effect )
e_unlockaethernet.nearest = nil
e_unlockaethernet.destination = nil
function c_unlockaethernet:evaluate(mapid, pos)
	local gotoPos = pos or ml_task_hub:CurrentTask().pos
	local destMapID = IsNull(ml_task_hub:CurrentTask().destMapID,0)
	if (destMapID == 0) then
		destMapID = Player.localmapid
	end
	
	e_unlockaethernet.nearest = nil
	
	if (not table.valid(gotoPos)) then
		return false
	end	
	
	local gotoDist = Distance3DT(gotoPos,Player.pos)
	
	local nearestAethernet,nearestDistance = AceLib.API.Map.GetNearestAethernet(Player.localmapid,Player.pos,2)	
	if (nearestAethernet) then
		if (IsNull(ml_task_hub:CurrentTask().uniqueid,0) ~= nearestAethernet.id) then 
			--d("current id:"..tostring(ml_task_hub:CurrentTask().uniqueid)..", new id:"..tostring(nearestAethernet.id))
			if (nearestDistance < 15 or nearestDistance < Distance3DT(Player.pos,gotoPos)) then
				e_unlockaethernet.nearest = nearestAethernet
				return true
			end
		end
	end
	
	return false
end
function e_unlockaethernet:execute()
	if (table.valid(e_unlockaethernet.nearest)) then
		--d("Use interact task to unlock ["..tostring(e_unlockaethernet.nearest.id).."]")
		local newTask = ffxiv_task_moveaethernet.Create()
		newTask.uniqueid = e_unlockaethernet.nearest.id
		newTask.pos = e_unlockaethernet.nearest.pos
		newTask.unlockAethernet = true
		
		ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
	end
end

c_usenavinteraction = inheritsFrom( ml_cause )
e_usenavinteraction = inheritsFrom( ml_effect )
c_usenavinteraction.blockOnly = false
e_usenavinteraction.task = nil
e_usenavinteraction.timer = 0
function c_usenavinteraction:evaluate(pos)
	local gotoPos = pos or ml_task_hub:ThisTask().pos
	
	e_usenavinteraction.task = nil
	c_usenavinteraction.blockOnly = false
	
	if (not ValidTable(gotoPos)) then
		return false
	end
	
	local transportFunction = _G["Transport"..tostring(Player.localmapid)]
	if (transportFunction ~= nil and type(transportFunction) == "function") then
		local retval,task = transportFunction(ml_global_information.Player_Position,gotoPos)
		if (retval == true) then
			e_usenavinteraction.task = task
			return true
		end
	end
	
	--[[local requiresTransport = ml_global_information.requiresTransport
	if (requiresTransport[Player.localmapid]) then
		e_usenavinteraction.task = requiresTransport[Player.localmapid].reaction
		return requiresTransport[Player.localmapid].test()
	end--]]
	
	return false
end
function e_usenavinteraction:execute()
	if (MIsCasting() or Now() < e_usenavinteraction.timer or c_usenavinteraction.blockOnly) then
		return false
	end
	
	e_usenavinteraction.task()
	e_usenavinteraction.timer = Now() + 2000
end

-- Checks for a better target while we are engaged in fighting an enemy and switches to it
c_bettertargetsearch = inheritsFrom( ml_cause )
e_bettertargetsearch = inheritsFrom( ml_effect )
c_bettertargetsearch.targetid = 0
c_bettertargetsearch.throttle = 1000
c_bettertargetsearch.postpone = 0
function c_bettertargetsearch:evaluate()        
    if (MIsLoading() or MIsLocked() or MIsCasting() or 
		(gBotMode == GetString("partyMode") and not IsPartyLeader()) or
		Now() < c_bettertargetsearch.postpone) 
	then
        return false
    end
	
	if (ml_task_hub:CurrentTask().betterTargetFunction and type(ml_task_hub:CurrentTask().betterTargetFunction)) then
		local newTarget = ml_task_hub:CurrentTask().betterTargetFunction()
		if (newTarget and newTarget.id ~= ml_task_hub:CurrentTask().targetid) then
			c_bettertargetsearch.targetid = newTarget.id
			return true
		end
	end
     
    return false
end
function e_bettertargetsearch:execute()
    ml_task_hub:CurrentTask().targetid = c_bettertargetsearch.targetid
	Player:SetTarget(c_bettertargetsearch.targetid)        
end

-----------------------------------------------------------------------------------------------
--MOUNT: If (distance to pos > ? or < ?) Then (mount or unmount)
---------------------------------------------------------------------------------------------
c_mount = inheritsFrom( ml_cause )
e_mount = inheritsFrom( ml_effect )
e_mount.id = 0
e_mount.lastPathCheck = 0
e_mount.lastPathPos = {}
c_mount.reattempt = 0
c_mount.attemptPos = nil
function c_mount:evaluate()
	if (MIsLocked() or MIsLoading() or ControlVisible("SelectString") or ControlVisible("SelectIconString") 
		or IsShopWindowOpen() or Player.ismounted or ml_global_information.Player_InCombat or IsFlying() or IsTransporting()) 
	then
		return false
	end
	
	if (IsMounting()) then
		return true
	end
	
	noMountMaps = {
		[130] = true,[131] = true,[132] = true,[133] = true,[128] = true,[129] = true,[144] = true,
		[337] = true,[336] = true,[175] = true,[352] = true,[418] = true,[419] = true,
	}
	
    if (noMountMaps[Player.localmapid]) then
		return false
	end
	
	if (HasBuffs(Player,"47") and ml_global_information.needsStealth and not ml_task_hub:CurrentTask().alwaysMount) then
		return false
	end
	
	e_mount.id = 0
	
    if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0) then
		local myPos = ml_global_information.Player_Position
		local gotoPos = ml_task_hub:CurrentTask().pos
		local lastPos = e_mount.lastPathPos
		
		--if (ValidTable(c_mount.attemptPos)) then
			--local lastDist = Distance3D(myPos.x, myPos.y, myPos.z, c_mount.attemptPos.x, c_mount.attemptPos.y, c_mount.attemptPos.z)
			--if (Now() < c_mount.reattempt and lastDist < 15) then
				--return false
			--end
		--end

		-- If we change our gotoPos or have never measured it, reset the watch.
		if (ValidTable(lastPos)) then
			if (PDistance3D(lastPos.x, lastPos.y, lastPos.z, gotoPos.x, gotoPos.y, gotoPos.z) > 1) then
				e_mount.lastPathPos = gotoPos
				e_mount.lastPathCheck = 0
			end
		end
		
		local distance = PDistance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
		
		local forcemount = false
		if (CanFlyInZone()) then
			
			if (ml_task_hub:CurrentTask().alwaysMount) then
				forcemount = true
			else
				if (not Player:IsMoving() or TimeSince(e_mount.lastPathCheck) > 5000) then
					local path = NavigationManager:GetPath(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
					local pathsize = TableSize(path)
					if (pathsize > 0) then
						if (ValidTable(path)) then
							local lasthop = path[pathsize-1]
							if (lasthop) then
								local goaltohop = PDistance3D(lasthop.x, lasthop.y, lasthop.z, gotoPos.x, gotoPos.y, gotoPos.z)
								if (goaltohop > 5) then
									forcemount = true
								end
							end
						end
					end
					
					e_mount.lastPathCheck = Now()
				end
			end
		end

		if ((distance > tonumber(gMountDist)) or forcemount) then
			--Added mount verifications here.
			--Realistically, the GUIVarUpdates should handle this, but just in case, we backup check it here.
			local mountID
			local mountIndex
			local mountlist = ActionList("type=13")
			
			if (ValidTable(mountlist)) then
				--First pass, look for our named mount.
				for k,v in pairsByKeys(mountlist) do
					if (v.name == gMount) then
						local acMount = ActionList:Get(v.id,13)
						if (acMount and acMount.isready) then
							e_mount.id = v.id
							return true
						end
					end
				end
				
				--Second pass, look for any mount as backup.
				if (gMount == GetString("none")) then
					for k,v in pairsByKeys(mountlist) do
						local acMount = ActionList:Get(v.id,13)
						if (acMount and acMount.isready) then
							SetGUIVar("gMount", v.name)
							e_mount.id = v.id
							return true
						end
					end		
				end
			end
		end
    end
    
    return false
end
function e_mount:execute()
	if (Player:IsMoving()) then
		Player:Stop()
		ml_global_information.Await(1500, function () return not Player:IsMoving() end)
		return
	end
	
	if (IsMounting() or UsingBattleItem()) then
		--d("Adding a wait.")
		if (CanFlyInZone()) then
			ml_task_hub:CurrentTask():SetDelay(2000)
		end
		return
	end
	
    if (Mount(e_mount.id)) then
		ml_global_information.Await(5000, function () return Player.ismounted end)
	end
	
	--ml_task_hub:CurrentTask():SetDelay(500)
	--c_mount.reattempt = Now() + 10000
	--local ppos = Player.pos
	--c_mount.attemptPos = { x = round(ppos.x,1), y = round(ppos.y,1), z = round(ppos.z,1) }
end

c_battlemount = inheritsFrom( ml_cause )
e_battlemount = inheritsFrom( ml_effect )
e_battlemount.id = 0
function c_battlemount:evaluate()
	if (MIsLocked() or MIsLoading() or ControlVisible("SelectString") or ControlVisible("SelectIconString") 
		or IsShopWindowOpen() or Player.ismounted or ml_global_information.Player_InCombat or IsFlying() or IsTransporting()) 
	then
		return false
	end
	
	if (IsMounting()) then
		return true
	end
	
	noMountMaps = {
		[130] = true,[131] = true,[132] = true,[133] = true,[128] = true,[129] = true,[144] = true,
		[337] = true,[336] = true,[175] = true,[352] = true,[418] = true,[419] = true,
	}
	
    if (noMountMaps[Player.localmapid]) then
		return false
	end
	
	if (HasBuffs(Player,"47") and ml_global_information.needsStealth) then
		return false
	end
	
	e_battlemount.id = 0
	
    if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0 and gUseMount == "1") then
		local myPos = ml_global_information.Player_Position
		local gotoPos = ml_task_hub:CurrentTask().pos
		local distance = PDistance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
	
		if (distance > tonumber(gMountDist)) then
			--Added mount verifications here.
			--Realistically, the GUIVarUpdates should handle this, but just in case, we backup check it here.
			local mountID
			local mountIndex
			local mountlist = ActionList("type=13")
			
			if (ValidTable(mountlist)) then
				--First pass, look for our named mount.
				for k,v in pairsByKeys(mountlist) do
					if (v.name == gMount) then
						local acMount = ActionList:Get(v.id,13)
						if (acMount and acMount.isready) then
							e_battlemount.id = v.id
							return true
						end
					end
				end
				
				--Second pass, look for any mount as backup.
				if (gMount == GetString("none")) then
					for k,v in pairsByKeys(mountlist) do
						local acMount = ActionList:Get(v.id,13)
						if (acMount and acMount.isready) then
							SetGUIVar("gMount", v.name)
							e_battlemount.id = v.id
							return true
						end
					end		
				end
			end
		end
    end
    
    return false
end
function e_battlemount:execute()
	if (Player:IsMoving()) then
		Player:Stop()
		--d("Stopped.")
		return
	end
	
	if (IsMounting() or UsingBattleItem()) then
		--d("Adding a wait.")
		ml_task_hub:CurrentTask():SetDelay(2000)
		return
	end
	
    Mount(e_battlemount.id)
	--d("Set a delay for 500")
	ml_task_hub:CurrentTask():SetDelay(500)
end

c_battleitem = inheritsFrom( ml_cause )
e_battleitem = inheritsFrom( ml_effect )
function c_battleitem:evaluate()
	return UsingBattleItem()
end
function e_battleitem:execute()
	--Do nothing, just block execution of other stuff.
end

c_companion = inheritsFrom( ml_cause )
e_companion = inheritsFrom( ml_effect )
function c_companion:evaluate()
	if (ffxiv_task_quest.noCompanion == true) then
		return false
	end
	
    if (gBotMode == GetString("pvpMode") or 
		Player.ismounted or IsMounting() or IsDismounting() or
		IsCompanionSummoned() or InInstance()) 
	then
        return false
    end

    if ((gChocoGrind == "1" and (gBotMode == GetString("grindMode") or gBotMode == GetString("partyMode"))) or
		(gChocoAssist == "1" and gBotMode == GetString("assistMode")) or
		(gChocoQuest == "1" and gBotMode == GetString("questMode"))) 
	then	
		local green = MGetItem(4868)
		if (green and green.isready) then
			return true
		end
    end
	
    return false
end
function e_companion:execute()
	if (Player:IsMoving()) then
		Player:Stop()
		ml_global_information.Await(2000, function () return not Player:IsMoving() end)
		return
	end
	
	local green = MGetItem(4868)
	if (green and green.isready) then
		green:Use()
		ml_global_information.AwaitDo(250, 5000, 
			function () 
				return (IsCompanionSummoned() or Player.castinginfo.castingid == 851) 
			end,
			function () 
				--local bestPotion = Inventory:Get(itemID)
				local green = MGetItem(4868)
				if (green and green.isready) then
					green:Use()
				end
			end
		)
	end
end

c_stance = inheritsFrom( ml_cause )
e_stance = inheritsFrom( ml_effect )
function c_stance:evaluate()
	if (IsCompanionSummoned() and ValidString(gChocoStance)) then
		
		if (TimeSince(ml_global_information.stanceTimer) >= 30000) then
			local stanceAction = ml_global_information.chocoStance[gChocoStance]
			if (stanceAction) then
				local acStance = ActionList:Get(stanceAction,6)		
				if (acStance and acStance.isready) then
					acStance:Cast(Player.id)
					return true
				end
			end
		end
	end
    
    return false
end

function e_stance:execute()
	ml_global_information.stanceTimer = Now()
	ml_task_hub:ThisTask().preserveSubtasks = true
end

-----------------------------------------------------------------------------------------------
--SPRINT: If (distance to pos > ? or < ?) Then (mount or unmount)
---------------------------------------------------------------------------------------------
c_sprint = inheritsFrom( ml_cause )
e_sprint = inheritsFrom( ml_effect )
function c_sprint:evaluate()
    if (gBotMode == "PVP") then
        return false
    end
	
	if (MIsLocked() or MIsLoading() or IsMounting() or ControlVisible("SelectString") or ControlVisible("SelectIconString") or IsShopWindowOpen() or Player.ismounted or IsTransporting()) then
		return false
	end

    if (not HasBuff(Player.id, 50) and Player:IsMoving()) then
		if (IsCityMap(Player.localmapid) or gUseSprint == "1") then
			if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0) then
				local myPos = ml_global_information.Player_Position
				local gotoPos = ml_task_hub:CurrentTask().pos
				local distance = PDistance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
				
				if (distance > tonumber(gSprintDist)) then	
					local sprint = ActionList:Get(3)
					if (sprint and sprint.isready) then
						return true
					end
				end
			end
		end
    end
    
    return false
end
function e_sprint:execute()
    local sprint = ActionList:Get(3)
	if (sprint and sprint.isready) then
		sprint:Cast()
	end
end

--minor abuse of the cne system here to update target pos
c_updatetarget = inheritsFrom( ml_cause )
e_updatetarget = inheritsFrom( ml_effect )
function c_updatetarget:evaluate()	
    if (ml_task_hub:ThisTask().targetid~=nil and ml_task_hub:ThisTask().targetid~=0)then
        local target = EntityList:Get(ml_task_hub.ThisTask().targetid)
        if (target ~= nil) then
            if (target.alive and target.attackable) then
                if (ml_task_hub:CurrentTask().name == "MOVETOPOS" ) then
					e_updatetarget.pos = target.pos				
                end
				return false
            end
        end
    end	
end
function e_updatetarget:execute()
end

c_attarget = inheritsFrom( ml_cause )
e_attarget = inheritsFrom( ml_effect )
function c_attarget:evaluate()
    if (ml_task_hub:CurrentTask().name == "MOVETOPOS") then
        if ml_global_information.AttackRange > 20 then
            local target = EntityList:Get(ml_task_hub:ThisTask().targetid)
            if ValidTable(target) then
                local rangePercent = tonumber(gCombatRangePercent) * 0.01
                return InCombatRange(ml_task_hub:ThisTask().targetid) and target.distance2d < (ml_global_information.AttackRange * rangePercent)
            end
        else
            return InCombatRange(ml_task_hub:ThisTask().targetid)
        end
    end
    return false
end
function e_attarget:execute()
    Player:Stop()
    ml_task_hub:CurrentTask():task_complete_execute()
    ml_task_hub:CurrentTask():Terminate()
end

---------------------------------------------------------------------------------------------
--REACTIVE/IMMEDIATE Game State CNEs
--These are cnes which are used to check the current game state and perform some kind of
--emergency action. They should generally be placed in the overwatch element list at an
--appropriate level in the subtask tree so that they can monitor all subtasks below them
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--REST: If (not player.hasAggro and player.hp.percent < 50) Then (do nothing)
--Blocks all subtask execution until player hp has increased
---------------------------------------------------------------------------------------------
c_rest = inheritsFrom( ml_cause )
e_rest = inheritsFrom( ml_effect )
function c_rest:evaluate()
	if (Now() < ml_global_information.suppressRestTimer and ml_global_information.Player_HP.percent > 20) then
		return false
	end
	
	if (InInstance()) then
		return false
	end
	
	if (ml_task_hub:ThisTask().name == "LT_GRIND") then
		if (gDoFates == "1" and gFatesOnly == "1") then
			return false
		end
	elseif (ml_task_hub:ThisTask().name == "LT_FATE") then
		local fate = MGetFateByID(ml_task_hub:ThisTask().fateid)
		if (ValidTable(fate)) then
			local fatePos = {x = fate.x,y = fate.y,z = fate.z}
			local myPos = Player.pos
			local dist2d = Distance2D(myPos.x,myPos.z,fatePos.x,fatePos.z)
			if (dist2d > fate.radius) then
				return false
			end
		end
	end
	
	local isDOL = (Player.job >= 16 and Player.job <= 18)
	local isDOH = (Player.job >= 8 and Player.job <= 15)
	
	if (( tonumber(gRestHP) > 0 and ml_global_information.Player_HP.percent < tonumber(gRestHP)) or
		(( tonumber(gRestMP) > 0 and ml_global_information.Player_MP.percent < tonumber(gRestMP)) and not isDOL and not isDOH))
	then
		if (ml_global_information.Player_InCombat or not Player.alive) then
			--d("Cannot rest, still in combat or not alive.")
			return false
		end
		
		local aggrolist = EntityList("alive,aggro")
		if (ValidTable(aggrolist)) then
			return false
		end
		
		-- don't rest if we have rest in fates disabled and we're in a fate or FatesOnly is enabled
		if (gRestInFates == "0") then
			if (gBotMode == GetString("grindMode")) then
				return not IsInsideFate()
			end
		end
	
		return true
	end
    
    return false
end
function e_rest:execute()
	Player:Stop()
	local newTask = ffxiv_task_rest.Create()
	ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	d("Entering a resting state due to low hp/mp.")
end

---------------------------------------------------------------------------------------------
--FLEE: If (aggolist.size > 0 and health.percent < 50) Then (run to a random point)
--Attempts to shake aggro by running away and resting
---------------------------------------------------------------------------------------------
c_flee = inheritsFrom( ml_cause )
e_flee = inheritsFrom( ml_effect )
e_flee.fleePos = {}
function c_flee:evaluate()
	local params = ml_task_hub:ThisTask().params
	if (params and params.noflee and params.noflee == true) then
		return false
	end
	
	if (InInstance()) then
		return false
	end
	
	e_flee.fleePos = {}
	
	if ((ml_global_information.Player_InCombat) and (ml_global_information.Player_HP.percent < GetFleeHP() or ml_global_information.Player_MP.percent < tonumber(gFleeMP))) then
		local ppos = ml_global_information.Player_Position
		
		if (ValidTable(ml_marker_mgr.markerList["evacPoint"])) then
			local fpos = ml_marker_mgr.markerList["evacPoint"]
			if (Distance3D(ppos.x, ppos.y, ppos.z, fpos.x, fpos.y, fpos.z) > 50) then
				e_flee.fleePos = fpos
				return true
			end
		end
		
		for i = 1,10 do
			local newPos = NavigationManager:GetRandomPointOnCircle(ppos.x,ppos.y,ppos.z,100,200)
			if (ValidTable(newPos)) then
				local p,dist = NavigationManager:GetClosestPointOnMesh(newPos)
				if (p) then
					e_flee.fleePos = p
					return true
				end
			end
		end
	end
    
    return false
end
function e_flee:execute()
	local fleePos = e_flee.fleePos
	if (ValidTable(fleePos)) then
		local newTask = ffxiv_task_flee.Create()
		newTask.pos = fleePos
		newTask.useTeleport = (gTeleport == "1")
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	end
end

---------------------------------------------------------------------------------------------
--DEAD: Checks Revivestate of player and revives at nearest aetheryte, homepoint, favpoint or we shall see 
--Blocks all subtask execution until player is alive 
---------------------------------------------------------------------------------------------
c_dead = inheritsFrom( ml_cause )
e_dead = inheritsFrom( ml_effect )
c_dead.timer = 0
e_dead.blockOnly = false
function c_dead:evaluate()	
    if (not Player.alive) then
		if (gBotMode == GetString("grindMode") or gBotMode == GetString("partyMode")) then
			if (c_dead.timer == 0) then
				c_dead.timer = Now() + 30000
				return false
			end
			if (Now() > c_dead.timer or HasBuffs(Player, "148")) then
				ffxiv_task_grind.inFate = false
				return true
			end
		else
			return true
		end
		
		e_dead.blockOnly = true
		return true
    end 
    return false
end
function e_dead:execute()
	if (ml_task_hub:ThisTask().name == "LT_GRIND") then
		ml_task_hub:ThisTask().targetid = 0
		ml_task_hub:ThisTask().markerTime = 0
		ml_task_hub:ThisTask().currentMarker = false
		ml_global_information.currentMarker = false
		ffxiv_task_grind.inFate = false
	elseif (ml_task_hub:ThisTask().name == "LT_GATHER") then
		ml_task_hub:ThisTask().gatherid = 0
		ml_task_hub:ThisTask().markerTime = 0
		ml_task_hub:ThisTask().currentMarker = false
		ml_global_information.currentMarker = false
		ml_task_hub:ThisTask().failedSearches = 0 
	elseif (ml_task_hub:ThisTask().name == "LT_FISH") then
		ml_task_hub:ThisTask().castTimer = 0
		ml_task_hub:ThisTask().markerTime = 0
		ml_task_hub:ThisTask().currentMarker = false
		ml_global_information.currentMarker = false
		ml_task_hub:ThisTask().networkLatency = 0
		ml_task_hub:ThisTask().requiresAdjustment = false
		ml_task_hub:ThisTask().snapshot = GetSnapshot()
	end
	
	if (e_dead.blockOnly) then
		e_dead.blockOnly = false
		return
	end
		
	if (ControlVisible("_NotificationParty")) then
		return
	end

	if (Player.revivestate == 2) then
		-- try raise first
		if (PressYesNo(true)) then
			c_dead.timer = 0
			ml_global_information.Await(20000, function () return Player.alive end)
			return
		end
		-- press ok
		if (PressOK()) then
			c_dead.timer = 0
			ml_global_information.Await(20000, function () return Player.alive end)
			return
		end
	end
end

c_pressconfirm = inheritsFrom( ml_cause )
e_pressconfirm = inheritsFrom( ml_effect )
function c_pressconfirm:evaluate()
	if (gBotMode == GetString("assistMode")) then
		return (gConfirmDuty == "1" and ControlVisible("ContentsFinderConfirm") and not MIsLoading())
	end
	
    return (ControlVisible("ContentsFinderConfirm") and not MIsLoading() and Player.revivestate ~= 2 and Player.revivestate ~= 3)
end
function e_pressconfirm:execute()
	PressDutyConfirm(true)
	if (gBotMode == GetString("pvpMode")) then
		ml_task_hub:ThisTask().state = "DUTY_STARTED"
	elseif (gBotMode == GetString("dutyMode") and IsDutyLeader()) then
		ffxiv_task_duty.state = "DUTY_ENTER"
	end
	ml_global_information.Await(5000, function () return not ControlVisible("ContentsFinderConfirm")  end)
end

-- more to refactor here later most likely
c_returntomarker = inheritsFrom( ml_cause )
e_returntomarker = inheritsFrom( ml_effect )
function c_returntomarker:evaluate()
	if (Player.incombat or MIsCasting() or MIsLoading() or (MIsLocked() and not IsFlying()) or ControlVisible("Gathering")) then
		return false
	end
	
    if (gBotMode == GetString("partyMode") and not IsPartyLeader()) then
        return false
    end
	
	if (ValidTable(ffxiv_fish.currentTask)) then
		return false
	end
    
	-- right now when randomize markers is active, it first walks to the marker and then checks for levelrange, this should probably get changed, but 
	-- making this will most likely break the behavior on some badly made meshes 
    if (ml_task_hub:CurrentTask().currentMarker ~= false and ml_task_hub:CurrentTask().currentMarker ~= nil) then
	
		local markerType = ml_task_hub:ThisTask().currentMarker:GetType()
		if (markerType == GetString("unspoiledMarker") and not ffxiv_task_gather.IsIdleLocation()) then
			return false
		end
	
        local myPos = ml_global_information.Player_Position
        local pos = ml_task_hub:CurrentTask().currentMarker:GetPosition()
        local distance = Distance2D(myPos.x, myPos.z, pos.x, pos.z)
		
		if (ml_task_hub:CurrentTask().name == "LT_GRIND" or ml_task_hub:CurrentTask().name == "LT_PARTY") then
			local target = ml_task_hub:CurrentTask().targetFunction()
			if (distance > 200 or (target == nil and distance > 10)) then
				return true
			end
		end
		
		if (gBotMode == GetString("pvpMode")) then
			if (ml_task_hub:CurrentTask().state ~= "COMBAT_STARTED" or (Player.localmapid ~= 376 and Player.localmapid ~= 422)) then
				if (distance > 25) then
					return true
				end
			else
				return false
			end
		end	
		
		if (gBotMode == GetString("huntMode")) then
			if (distance > 15) then
				return true
			end
		end		
		
		if (gBotMode == GetString("gatherMode")) then
			local gatherid = ml_task_hub:CurrentTask().gatherid or 0
			if (gatherid == 0 and distance > 25) then
				d("No gatherable currently, return to the marker.")
				return true
			end
			if (gMarkerMgrMode ~= GetString("markerTeam")) then
				local radius = 150
				local maxradius = ml_global_information.currentMarker:GetFieldValue(GetUSString("maxRadius"))
				if (tonumber(maxradius) and tonumber(maxradius) > 0) then
					radius = tonumber(maxradius)
				end
				if (distance > radius) then
					return true
				end
			end
		end
		
        if (gBotMode == GetString("fishMode") and distance > 3) then
            return true
        end
    end
    
    return false
end
function e_returntomarker:execute()
	if (gBotMode == GetString("fishMode")) then
		local fs = tonumber(Player:GetFishingState())
		if (fs ~= 0) then
			local finishcast = ActionList:Get(299,1)
			if (finishcast and finishcast.isready) then
				finishcast:Cast()
			end
			return
		end
	end
	
    local newTask = ffxiv_task_movetopos.Create()
    local markerPos = ml_global_information.currentMarker:GetPosition()
    local markerType = ml_global_information.currentMarker:GetType()
    newTask.pos = markerPos
    newTask.range = math.random(3,5)
	if (markerType == GetString("huntMarker") or
		markerType == GetString("miningMarker") or
		markerType == GetString("botanyMarker") or
		markerType == GetString("grindMarker")) 
	then
		newTask.remainMounted = true
	end
    if (markerType == GetString("fishingMarker")) then
        newTask.pos.h = markerPos.h
        newTask.range = 0.5
        newTask.doFacing = true
    end
	if (gTeleport == "1") then
		newTask.useTeleport = true
	end
	
	if (markerType == GetString("miningMarker") or
		markerType == GetString("botanyMarker"))
	then
		newTask.stealthFunction = ffxiv_gather.NeedsStealth
	elseif (markerType == GetString("fishingMarker")) then
		newTask.stealthFunction = ffxiv_fish.NeedsStealth
	end
	
	--[[
	newTask.abortFunction = function()
		if (gBotMode == GetString("grindMode")) then
			local newTarget = GetNearestGrind()
			if (ValidTable(newTarget)) then
				return true
			end
			
			if (gGather == "1") then
				local node = eso_gather_manager.ClosestNode(true)
				if (ValidTable(node)) then
					return true
				end
			end
		end
		if (gBotMode == GetString("gatherMode")) then
			local node = eso_gather_manager.ClosestNode(true)
			if (ValidTable(node)) then
				return true
			end
		end
		return false
	end
	--]]
	
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

--------------------------------------------------------------------------------------------
--  Keep track of whether we need stealth or not so other cne's know if they can break it.
--------------------------------------------------------------------------------------------
c_stealthupdate = inheritsFrom( ml_cause )
e_stealthupdate = inheritsFrom( ml_effect )
c_stealthupdate.timer = 0
function c_stealthupdate:evaluate()	
	local stealthFunction = ml_task_hub:CurrentTask().stealthFunction
	if (stealthFunction ~= nil and type(stealthFunction) == "function") then
		
		local fs = tonumber(Player:GetFishingState())
		if (ControlVisible("Gathering") or fs ~= 0) then
			return false
		end
		
		local needsStealth = stealthFunction()
		if (ml_global_information.needsStealth ~= needsStealth) then
			ml_global_information.needsStealth = needsStealth
		end
	else
		if (ml_global_information.needsStealth ~= false) then
			ml_global_information.needsStealth = false
		end	
	end
	
	return false
end
function e_stealthupdate:execute()
	--Nothing here, just update the variable.
end

c_acceptquest = inheritsFrom( ml_cause )
e_acceptquest = inheritsFrom( ml_effect )
function c_acceptquest:evaluate()
	if (gBotMode == GetString("assistMode") and gQuestHelpers == "0") then
		return false
	end
	return Quest:IsQuestAcceptDialogOpen()
end
function e_acceptquest:execute()
	Quest:AcceptQuest()
	ml_global_information.Await(3000, function () return not Quest:IsQuestAcceptDialogOpen() end)
end

c_handoverquest = inheritsFrom( ml_cause )
e_handoverquest = inheritsFrom( ml_effect )
function c_handoverquest:evaluate()
	if (gBotMode == GetString("assistMode") and gQuestHelpers == "0") then
		return false
	end
	return Quest:IsRequestDialogOpen()
end
function e_handoverquest:execute()
	local inv = Inventory("type=2004")

	for id, item in pairs(inv) do 
		if (item:HandOver()) then
			d("Handed over item ID:"..tostring(item.id))
			ml_task_hub:CurrentTask():SetDelay(1000)
			return
		end
	end			
	Quest:RequestHandOver()
end

c_completequest = inheritsFrom( ml_cause )
e_completequest = inheritsFrom( ml_effect )
function c_completequest:evaluate()
	if (gBotMode == GetString("assistMode") and gQuestHelpers == "0") then
		return false
	end
	return Quest:IsQuestRewardDialogOpen()
end
function e_completequest:execute()
	Quest:CompleteQuestReward(0)
end

c_teleporttopos = inheritsFrom( ml_cause )
e_teleporttopos = inheritsFrom( ml_effect )
c_teleporttopos.pos = 0
e_teleporttopos.teleCooldown = 0
function c_teleporttopos:evaluate()
	if (Now() < e_teleporttopos.teleCooldown or gTeleport == "0" or IsFlying()) then
		return false
	end
	
	local useTeleport = ml_task_hub:CurrentTask().useTeleport
	if (MIsCasting() or MIsLocked() or MIsLoading() or IsMounting() or 
		ControlVisible("SelectString") or ControlVisible("SelectIconString") or IsShopWindowOpen() or
		not ValidTable(ml_task_hub:CurrentTask().pos) or not useTeleport) 
	then
		return false
	end
	
	local myPos = ml_global_information.Player_Position
	local gotoPos = ml_task_hub:CurrentTask().pos
	
	if (not ValidTable(gotoPos) or c_rest:evaluate() or not ShouldTeleport(gotoPos)) then
		return false
	end
	 
	local distance = PDistance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
	if (distance > 10) then
		local properPos = nil
		if (ml_task_hub:CurrentTask().gatePos) then
			properPos = ml_task_hub:CurrentTask().pos
		else
			properPos = ml_task_hub:CurrentTask().pos
			local p,dist = NavigationManager:GetClosestPointOnMesh(properPos)
			if (p and dist ~= 0) then
				properPos = p
			end
		end
		
		c_teleporttopos.pos = properPos
		return true
	end
    return false
end
function e_teleporttopos:execute()
    if ( c_teleporttopos.pos ~= 0) then
        local gotoPos = c_teleporttopos.pos
		Player:Stop()
		
        GameHacks:TeleportToXYZ(tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z))
		ml_global_information.queueSync = {timer = Now() + 150, pos = gotoPos}
		e_teleporttopos.teleCooldown = Now() + 1000
    else
        ml_error(" Critical error in e_walktopos, c_walktopos.pos == 0!!")
    end
    c_teleporttopos.pos = 0
end

c_autoequip = inheritsFrom( ml_cause )
e_autoequip = inheritsFrom( ml_effect )
c_autoequip.postpone = 0
e_autoequip.item = nil
e_autoequip.bag = nil
e_autoequip.slot = nil
function c_autoequip:evaluate()	
	if (((gQuestAutoEquip == "0" or Now() < c_autoequip.postpone) and gForceAutoEquip == false) or 
		IsShopWindowOpen() or (MIsLocked() and not IsFlying()) or MIsLoading() or 
		not Player.alive or Player.incombat or
		ControlVisible("Gathering") or Player:GetFishingState() ~= 0) 
	then
		return false
	end
	
	e_autoequip.item = nil
	e_autoequip.bag = nil
	e_autoequip.slot = nil
	
	local doPostpone = true
	
	if (ValidTable(ffxiv_task_quest.lockedSlots)) then
		for slot,questid in pairs(ffxiv_task_quest.lockedSlots) do
			if (Quest:IsQuestCompleted(questid)) then
				ffxiv_task_quest.lockedSlots[slot] = nil
			end
		end
	end
	
	local applicableSlots = {
		[0] = true,
		[1] = true,
		[2] = true,
		[3] = true,
		[4] = true,
		[5] = true,
		[6] = true,
		[7] = true,
		[8] = true,
		[9] = true,
		[10] = true,
		[11] = true,
		[12] = true,
	}
	
	for slot,data in pairs(applicableSlots) do
		if (ffxiv_task_quest.lockedSlots[slot] or IsArmoryFull(slot)) then
			applicableSlots[slot] = nil
		else
			applicableSlots[slot] = {}
			applicableSlots[slot].equippedItem = 0
			applicableSlots[slot].equippedValue = 0
			applicableSlots[slot].unequippedItem = 0
			applicableSlots[slot].unequippedValue = 0
		end
	end
	
	-- Fill with comparison data.
	for slot,data in pairsByKeys(applicableSlots) do
		local equipped = Inventory("type=1000")
		if (ValidTable(equipped)) then
			for _,item in pairs(equipped) do
				local found = false
				if (item.slot == slot and item.id ~= 0) then
					found = true
					data.equippedValue = AceLib.API.Items.GetItemStatWeight(item,slot)
					data.equippedItem = item
					
					if (ValidTable(item)) then
						ml_debug("Slot ["..tostring(slot).."] Equipped item ["..tostring(item.name).." ]["..tostring(item.hqid).."] has a value of :"..tostring(data.equippedValue))
					end
				end
				if (found) then
					break
				end
			end
		end
		
		if (slot == 0) then
			data.unequippedItem,data.unequippedValue = AceLib.API.Items.FindWeaponUpgrade()
			if (IsNull(data.unequippedItem,0) ~= 0) then
				ml_debug("Slot ["..tostring(slot).."] Best upgrade item ["..tostring(data.unequippedItem.name).."] has a value of :"..tostring(data.unequippedValue))
			end
		elseif (slot == 1) then
			if (AceLib.API.Items.IsShieldEligible()) then
				data.unequippedItem,data.unequippedValue = AceLib.API.Items.FindShieldUpgrade()
				if (IsNull(data.unequippedItem,0) ~= 0) then
					ml_debug("Slot ["..tostring(slot).."] Best upgrade item ["..tostring(data.unequippedItem.name).."] has a value of :"..tostring(data.unequippedValue))
				end
			end
		else
			data.unequippedItem,data.unequippedValue = AceLib.API.Items.FindArmorUpgrade(slot)
			if (IsNull(data.unequippedItem,0) ~= 0) then
				ml_debug("Slot ["..tostring(slot).."] Best upgrade item ["..tostring(data.unequippedItem.name).."] has a value of :"..tostring(data.unequippedValue))
			end
		end
	end
	
	for slot,data in pairsByKeys(applicableSlots) do		
		if (IsNull(data.unequippedItem,0) ~= 0 and ((data.unequippedValue > data.equippedValue) or (data.equippedItem == 0))) then
			if (ArmoryItemCount(slot) == 25 and (data.unequippedItem.bag >= 0 and data.unequippedItem.bag <= 3)) then
				ml_debug("Armoury slots for ["..tostring(slot).."] are full, attempting to rearrange inventory.")
				
				local firstBag,firstSlot = GetFirstFreeInventorySlot()
				if (firstBag ~= nil) then
					if (slot == 0) then
						local downgrades = AceLib.API.Items.FindWeaponDowngrades()
						if (ValidTable(downgrades)) then
							for i,item in pairs(downgrades) do
								if (item.bag > 3) then
									ml_debug("Will attempt to place item ["..tostring(item.id).."] into bag ["..tostring(firstBag).."], slot ["..tostring(firstSlot).."].")
									
									e_autoequip.item = item
									e_autoequip.bag = firstBag
									e_autoequip.slot = firstSlot
									return true
								end
							end
						else
							lowestItem = LowestArmoryItem(slot)
							if (lowestItem) then
								ml_debug("Will attempt to place item ["..tostring(lowestItem.id).."] into bag ["..tostring(firstBag).."], slot ["..tostring(firstSlot).."].")
								
								e_autoequip.item = lowestItem
								e_autoequip.bag = firstBag
								e_autoequip.slot = firstSlot
								return true
							end
						end
					elseif (slot == 1) then
						local downgrades = AceLib.API.Items.FindShieldDowngrades()
						if (ValidTable(downgrades)) then
							for i,item in pairs(downgrades) do
								if (item.bag > 3) then
									e_autoequip.item = item
									e_autoequip.bag = firstBag
									e_autoequip.slot = firstSlot
									return true
								end
							end
						else
							lowestItem = LowestArmoryItem(slot)
							if (lowestItem) then
								ml_debug("Will attempt to place item ["..tostring(lowestItem.id).."] into bag ["..tostring(firstBag).."], slot ["..tostring(firstSlot).."].")
								
								e_autoequip.item = lowestItem
								e_autoequip.bag = firstBag
								e_autoequip.slot = firstSlot
								return true
							end
						end
					else
						local downgrades = AceLib.API.Items.FindArmorDowngrades(slot)
						if (ValidTable(downgrades)) then
							for i,item in pairs(downgrades) do
								if (item.bag > 3) then
									e_autoequip.item = item
									e_autoequip.bag = firstBag
									e_autoequip.slot = firstSlot
									return true
								end
							end
						else
							lowestItem = LowestArmoryItem(slot)
							if (lowestItem) then
								ml_debug("Will attempt to place item ["..tostring(lowestItem.id).."] into bag ["..tostring(firstBag).."], slot ["..tostring(firstSlot).."].")
								
								e_autoequip.item = lowestItem
								e_autoequip.bag = firstBag
								e_autoequip.slot = firstSlot
								return true
							end
						end
					end
				end
				
				ml_debug("Autoequip cannot be used for slot ["..tostring(slot).."], all armoury slots are full.")
				return false
			end
			
			e_autoequip.item = data.unequippedItem
			e_autoequip.bag = 1000
			e_autoequip.slot = slot
			return true
		else
			--d("Prevented equipping item into slot ["..tostring(slot).."].")
		end
	end
	
	if (doPostpone) then
		c_autoequip.postpone = Now() + 5000
	end
	
	return false
end
function e_autoequip:execute()
	local item = e_autoequip.item
	if (ValidTable(item)) then
		local itemid = item.hqid
		ml_debug("Moving item ["..tostring(itemid).."] to bag "..tostring(e_autoequip.bag)..", slot "..tostring(e_autoequip.slot))
		item:Move(e_autoequip.bag,e_autoequip.slot)
		ml_global_information.Await(1500, function () return (IsEquipped(itemid)) end)
	end
	--if (ml_task_hub:CurrentTask()) then
		--ml_task_hub:CurrentTask():SetDelay(200)
	--end
end

c_selectconvindex = inheritsFrom( ml_cause )
e_selectconvindex = inheritsFrom( ml_effect )
c_selectconvindex.unexpected = 0
function c_selectconvindex:evaluate()	
	if (c_selectconvindex.unexpected > 5) then
		c_selectconvindex.unexpected = 0
	end
	return (ControlVisible("SelectIconString") or ControlVisible("SelectString"))
end
function e_selectconvindex:execute()	
	local index = ml_task_hub:CurrentTask().conversationIndex
	if (not index) then
		c_selectconvindex.unexpected = c_selectconvindex.unexpected + 1
		index = c_selectconvindex.unexpected
	end
	SelectConversationIndex(tonumber(index))
	ml_task_hub:ThisTask():SetDelay(1000)
end

c_returntomap = inheritsFrom( ml_cause )
e_returntomap = inheritsFrom( ml_effect )
e_returntomap.mapID = 0
function c_returntomap:evaluate()
	if ((MIsLocked() and not IsFlying()) or MIsLoading() or not Player.alive) then
		return false
	end
	
	if (ml_task_hub:ThisTask().correctMap and (ml_task_hub:ThisTask().correctMap ~= Player.localmapid)) then
		local mapID = ml_task_hub:ThisTask().correctMap
		if (CanAccessMap(mapID)) then
			e_returntomap.mapID = mapID
			return true
		end
	end
	
	return false
end
function e_returntomap:execute()
	local task = ffxiv_task_movetomap.Create()
	task.setHomepoint = true
	task.destMapID = e_returntomap.mapID
	ml_task_hub:Add(task, IMMEDIATE_GOAL, TP_IMMEDIATE)
end

c_inventoryfull = inheritsFrom( ml_cause )
e_inventoryfull = inheritsFrom( ml_effect )
function c_inventoryfull:evaluate()
	if (IsInventoryFull()) then
		if (not IsFighter(Player.job)) then
			return true
		end
	end
	
    return false
end
function e_inventoryfull:execute()
	if (gBotRunning == "1") then
		GUI_ToggleConsole(true)
		d("Inventory is full, bot will stop.")
		ml_task_hub:ToggleRun()
	end
end

c_unpackdata = inheritsFrom( ml_cause )
e_unpackdata = inheritsFrom( ml_effect )
function c_unpackdata:evaluate()
	--if (not ml_task_hub:CurrentTask().dataUnpacked and (ml_task_hub:CurrentTask().encounterData or ml_task_hub:CurrentTask().params)) then
		--return true
	--end
	
    return false
end
function e_unpackdata:execute()
	if (ml_task_hub:CurrentTask().encounterData) then
		
	end
	ml_task_hub:CurrentTask().dataUnpacked = true
end

c_falling = inheritsFrom( ml_cause )
e_falling = inheritsFrom( ml_effect )
c_falling.jumpKillTimer = 0
c_falling.lastMeasure = 0
function c_falling:evaluate()
	local myPos = ml_global_information.Player_Position
	if (Player:IsJumping()) then
		if (c_falling.jumpKillTimer == 0) then
			c_falling.jumpKillTimer = Now() + 1000
			c_falling.lastY = myPos.y
		elseif (Now() > c_falling.jumpKillTimer) then
			if (myPos.y < (c_falling.lastY - 3)) then
				return true
			end
		end
	else
		if (c_falling.jumpKillTimer ~= 0) then
			c_falling.jumpKillTimer = 0
			c_falling.lastY = 0
		end
	end
	
    return false
end
function e_falling:execute()
	Player:Stop()
	c_falling.jumpKillTimer = 0
end

c_clearaggressive = inheritsFrom( ml_cause )
e_clearaggressive = inheritsFrom( ml_effect )
c_clearaggressive.targetid = 0
c_clearaggressive.timer = 0
function c_clearaggressive:evaluate()
	if (MIsCasting() or MIsLocked() or MIsLoading() or ControlVisible("SelectYesno") or ControlVisible("SelectString") or ControlVisible("SelectIconString")) then
		return false
	end
	
	if (Now() < c_clearaggressive.timer) then
		return false
	end
	
	--Reset the tempvar.
	c_clearaggressive.targetid = 0
	
	local clearAggressive = ml_task_hub:CurrentTask().clearAggressive or false
	if (clearAggressive) then
		local ppos = ml_global_information.Player_Position
		local id = ml_task_hub:CurrentTask().targetid or 0
		if (id > 0) then
			local el = EntityList("shortestpath,targetable,contentid="..tostring(id))
			if (el) then
				local i,entity = next(el)
				if (i and entity) then
					local epos = entity.pos
					c_clearaggressive.timer = Now() + 5000
					local aggroChecks = GetAggroDetectionPoints(ppos,epos)
					if (ValidTable(aggroChecks)) then
						for k,navPos in pairsByKeys(aggroChecks) do
							local aggressives = EntityList("aggressive,alive,attackable,targeting=0,minlevel="..tostring(Player.level - 10)..",exclude_contentid="..tostring(id))
							if (ValidTable(aggressives)) then
								for _,aggressive in pairs(aggressives) do
									local agpos = aggressive.pos
									local dist = PDistance3D(navPos.x,navPos.y,navPos.z,agpos.x,agpos.y,agpos.z)
									local tdist = PDistance3D(navPos.x,navPos.y,navPos.z,epos.x,epos.y,epos.z)
									if (dist <= 12 and dist < tdist) then
										c_questclearaggressive.targetid = aggressive.id
										return true
									end
								end
							end
						end
					end
				end
			end
		elseif (ml_task_hub:CurrentTask().pos) then
			local dest = ml_task_hub:CurrentTask().pos
			c_clearaggressive.timer = Now() + 5000
			local aggroChecks = GetAggroDetectionPoints(ppos,dest)
			if (ValidTable(aggroChecks)) then
				for k,navPos in pairsByKeys(aggroChecks) do
					local aggressives = nil
					if (gBotMode == "NavTest") then
						local aggressives = EntityList("aggressive,alive,attackable,targeting=0")
					else
						local aggressives = EntityList("aggressive,alive,attackable,targeting=0,minlevel="..tostring(Player.level - 10))
					end
					if (ValidTable(aggressives)) then
						for _,aggressive in pairs(aggressives) do
							local agpos = aggressive.pos
							local dist = PDistance3D(navPos.x,navPos.y,navPos.z,agpos.x,agpos.y,agpos.z)
							if (dist <= 15) then
								c_questclearaggressive.targetid = aggressive.id
								return true
							end
						end
					end
				end
			end
		end
	end
    
    return false
end
function e_clearaggressive:execute()	
	Player:Stop()
	
	local newTask = ffxiv_task_grindCombat.Create()
    newTask.targetid = c_questclearaggressive.targetid
	Player:SetTarget(c_questclearaggressive.targetid)
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_isloading = inheritsFrom( ml_cause )
e_isloading = inheritsFrom( ml_effect )
function c_isloading:evaluate()
	return MIsLoading()
end
function e_isloading:execute()
	d("Character is loading, prevent other actions and idle.")
end

c_mapyesno = inheritsFrom( ml_cause )
e_mapyesno = inheritsFrom( ml_effect )
function c_mapyesno:evaluate()
	return ControlVisible("SelectYesno")
end
function e_mapyesno:execute()
	if (ControlVisible("_NotificationParty")) then
		PressYesNo(false)
	else
		PressYesNo(true)
	end
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_reachedmap = inheritsFrom( ml_cause )
e_reachedmap = inheritsFrom( ml_effect )
function c_reachedmap:evaluate()
	return (Player.localmapid == ml_task_hub:ThisTask().destMapID)
end
function e_reachedmap:execute()
	ml_task_hub:ThisTask().completed = true
end

c_movetomap = inheritsFrom( ml_cause )
e_movetomap = inheritsFrom( ml_effect )
function c_movetomap:evaluate()
	if (MIsCasting() or (MIsLocked() and not IsFlying()) or MIsLoading()) then
		return false
	end
	
	local mapID = ml_task_hub:CurrentTask().mapid
	if (mapID and mapID > 0) then
		if (Player.localmapid ~= mapID) then
			if (CanAccessMap(mapID)) then
				e_movetomap.mapID = mapID
				return true
			end
		end
	end
	
	return false
end
function e_movetomap:execute()
	local task = ffxiv_task_movetomap.Create()
	task.destMapID = e_movetomap.mapID
	if (ValidTable(ml_task_hub:CurrentTask().pos)) then
		task.pos = ml_task_hub:CurrentTask().pos
	end
	ml_task_hub:CurrentTask():AddSubTask(task)
end

c_buy = inheritsFrom( ml_cause )
e_buy = inheritsFrom( ml_effect )
function c_buy:evaluate()	
	if (not IsShopWindowOpen()) then
		return false
	end
	
	local itemid;
	local itemtable = ml_task_hub:CurrentTask().itemid
	if (ValidTable(itemtable)) then
		itemid = itemtable[Player.job] or itemtable[-1]
	elseif (tonumber(itemtable)) then
		itemid = tonumber(itemtable)
	end
	
	if (itemid) then
		e_buy.itemid = tonumber(itemid)
		return true
	end
	
	return false
end
function e_buy:execute()
	local buyamount = ml_task_hub:CurrentTask().buyamount or 1
	if (buyamount > 99) then
		buyamount = 99
		ml_task_hub:CurrentTask().buyamount = ml_task_hub:CurrentTask().buyamount - 99
	end
	
	Inventory:BuyShopItem(e_buy.itemid,buyamount)
	ml_task_hub:CurrentTask():SetDelay(1000)
end

c_moveandinteract = inheritsFrom( ml_cause )
e_moveandinteract = inheritsFrom( ml_effect )
c_moveandinteract.entityid = 0
function c_moveandinteract:evaluate()
	if (MIsCasting() or (MIsLocked() and not IsFlying()) or MIsLoading() or 
		ControlVisible("SelectString") or ControlVisible("SelectIconString")) 
	then
		return false
	end
	
	local id = ml_task_hub:CurrentTask().id
    if (id and id > 0) then
		return true
    end
	
	return false
end
function e_moveandinteract:execute()
	local newTask = ffxiv_task_movetointeract.Create()
	newTask.uniqueid = ml_task_hub:CurrentTask().id
	newTask.pos = ml_task_hub:CurrentTask().pos
	newTask.use3d = true
	
	if (gTeleport == "1") then
		newTask.useTeleport = true
	end
	
	ml_task_hub:ThisTask():AddSubTask(newTask)
end

c_switchclass = inheritsFrom( ml_cause )
e_switchclass = inheritsFrom( ml_effect )
e_switchclass.weapon = nil
function c_switchclass:evaluate()	
	e_switchclass.weapon = nil
	
	local class = ml_task_hub:CurrentTask().class
	if (Player.job ~= class) then
		if (IsShopWindowOpen() or (MIsLocked() and not IsFlying()) or MIsLoading() or 
			not Player.alive or ml_global_information.Player_InCombat or
			ControlVisible("Gathering") or Player:GetFishingState() ~= 0) 
		then
			return false
		end
			
		local canSwitch,bestWeapon = CanSwitchToClass(class)
		if (canSwitch) then
			if (bestWeapon) then
				e_switchclass.weapon = bestWeapon
				return true
			end
		end	
	end
	return false
end
function e_switchclass:execute()	
	local weapon = e_switchclass.weapon
	if (weapon) then
		weapon:Move(1000,0)
		ml_task_hub:CurrentTask():SetDelay(2500)
	end
end

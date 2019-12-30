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

	if not Player.onmesh then
		d("Blocked due to off mesh")
		return false
	end
	-- block killtarget for grinding when user has specified "Fates Only"
	
	if ((ml_task_hub:CurrentTask().name == "LT_GRIND" or ml_task_hub:CurrentTask().name == "LT_PARTY" ) and gGrindDoFates and (gGrindFatesOnly and Player.level > 10)) then
		if (ml_task_hub:CurrentTask().name == "LT_GRIND") then
			local aggro = GetNearestAggro()
			if table.valid(aggro) then
				if (aggro.hp.current > 0 and aggro.id and aggro.id ~= 0 and aggro.distance2d <= 30) then
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
		if table.valid(aggro) then
			if (aggro.hp.current > 0 and aggro.id and aggro.id ~= 0 and aggro.distance2d <= 30) then
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
    if (table.valid(target)) then
        if(target.hp and target.hp.current > 0 and target.id ~= nil and target.id ~= 0) then
			--d("Picked target in normal block.")
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
	if ((gBotMode == GetString("partyMode") and IsPartyLeader()) or IsPOTD(Player.localmapid) or not IsFighter(Player.job)) then
        return false
    end
	
	if (gBotMode == GetString("partyMode")) then
		local leader, isEntity = GetPartyLeader()	
		if (leader and leader.id ~= 0) then
			local entity = EntityList:Get(leader.id)
			if ( entity  and entity.id ~= 0) then
				if ((entity.incombat and entity.distance2d > 7) or (not entity.incombat and entity.distance2d > 10) or (entity.ismounted) or Player.ismounted) then
					return false
				end
			end
		end
	end
	
    local target = GetNearestAggro()
	if (table.valid(target)) then
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
    if (table.valid(leader) and isEntity) then
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
			if (table.valid(target) and target.alive) then
				c_assistleader.targetid = target.id
				return true
			end
		else	
			--d("executing queued version>")
			local target = EntityList:Get(leadtarget)				
			if (table.valid(target) and target.alive) then
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
	
	if (NotQueued() and not IsPOTD(Player.localmapid)) then
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

		local target = MGetEntity(c_assistleader.targetid)
		local targetid = target.id
		local pos = target.pos
		local ppos = Player.pos
		local dist = Distance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
		
		if (ml_global_information.AttackRange > 5) then
			--d("executing caster version")
			if ((not InCombatRange(target.id) or not target.los) and not MIsCasting()) then
				if (Now() > c_assistleader.movementDelay) then
					if (target.distance2d <= ml_global_information.AttackRange) then
						Player:MoveTo(pos.x,pos.y,pos.z,1.5, 0, 0, target.id)
					else
						Player:MoveTo(pos.x,pos.y,pos.z, (target.hitradius + 1), 0, 0, target.id)
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
			Player:SetTarget(targetid)
			if ((not InCombatRange(targetid) or not target.los) and dist > 3) then
				--Player:MoveTo(pos.x,pos.y,pos.z, 1.5, false, false, false)
				
				Player:Move(FFXIV.MOVEMENT.FORWARD)
				ml_global_information.AwaitDo(250, 30000, 
					function ()
						if (not Player:IsMoving()) then
							return true
						end
						local target = EntityList:Get(targetid)
						if (not target) then
							return true
						else
							local targetPos = target.pos
							local myPos = Player.pos
							local dist3d = Distance3DT(targetPos,myPos)
							return ((InCombatRange(target.id) and target.los) or dist3d < target.hitradius or dist3d < 3)
						end
						return false
					end,
					function ()
						local target = EntityList:Get(targetid)
						if (target) then
							local targetPos = target.pos
							Player:SetFacing(targetPos.x,targetPos.y,targetPos.z)
						end
					end,
					function ()
						if (Player:IsMoving()) then
							Player:Stop()
						end
					end
				)
			end
			if (InCombatRange(target.id) or dist <= 5) then
				Player:SetTarget(target.id)
				Player:SetFacing(pos.x,pos.y,pos.z) 
				if (Player:IsMoving()) then
					Player:Stop()
				end
			end
				
			SkillMgr.Cast( target )
		end
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
    
    if (gGrindDoFates) then
		local fate = GetClosestFate(Player.pos,true)
		if (fate and fate.completion < 100) then
			c_add_fate.fate = fate
			return true
		end
    end
    
    return false
end
function e_add_fate:execute()
	local fate = c_add_fate.fate
	local ppos = Player.pos
	local fatePos = {x = c_add_fate.fate.x, y = c_add_fate.fate.y, z = c_add_fate.fate.z}
	
	local newTask = ffxiv_task_fate.Create()
    newTask.fateid = c_add_fate.fate.id
	newTask.fatePos = fatePos
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_nextatma = inheritsFrom( ml_cause )
e_nextatma = inheritsFrom( ml_effect )
e_nextatma.atma = nil
function c_nextatma:evaluate()	
	if (not gGrindAtmaMode or Player.incombat or ffxiv_task_grind.inFate or MIsLoading()) then
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
			
			local item = GetItem(atma.item)
			if (item) then
				haveBest = true
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
			
			local item = GetItem(atma.item)
			if (item) then
				haveClosest = true
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
		
		local item = GetItem(atma.item)
		if (item) then
			found = true
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
		ml_task_hub:ThisTask().correctMapFunction = nil
		
		local newTask = ffxiv_task_teleport.Create()
		--d("Changing to new location for "..tostring(atma.name).." atma.")
		newTask.aetheryte = atma.tele
		newTask.mapID = atma.map
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	end
end

c_nextluminous = inheritsFrom( ml_cause )
e_nextluminous = inheritsFrom( ml_effect )
e_nextluminous.crystal = nil
function c_nextluminous:evaluate()	
	if (not gGrindLuminousMode or Player.incombat or ffxiv_task_grind.inFate or MIsLoading()) then
		return false
	end
	
	e_nextluminous.crystal = nil
	
	local crystals = ffxiv_task_grind.luminous
	
	--Second loop, check to see if we have this map's atma, and return false if we still don't have it yet.
	for i, crystal in pairs(crystals) do
		if (crystal.map == Player.localmapid) then
			local count = ItemCount(crystal.item)
			if (count < 1) then
				return false
			end
		end
	end
	
	for i, crystal in pairs(crystals) do
		local count = ItemCount(crystal.item)
		if (count < 1) then
			e_nextluminous.crystal = crystal
			return true
		end
	end
	
	return false
end
function e_nextluminous:execute()
	local crystal = e_nextluminous.crystal
	ml_task_hub:ThisTask().correctMap = crystal.map
	ml_task_hub:ThisTask().correctMapFunction = nil
	
	if (Player:IsMoving()) then
		Player:Stop()
		ml_global_information.Await(1500, function () return not Player:IsMoving() end)
	end
	
	local task = ffxiv_task_movetomap.Create()
	task.destMapID = crystal.map
	ml_task_hub:Add(task, REACTIVE_GOAL, TP_IMMEDIATE)
end

--=======Avoidance============

c_avoid = inheritsFrom( ml_cause )
e_avoid = inheritsFrom( ml_effect )
e_avoid.lastAvoid = {}
c_avoid.newAvoid = {}
c_avoid.avoidDetails = {}
function c_avoid:evaluate()	
	if gBotMode == GetString("assistMode") then
		return false
	end
	if (IsFlying() or not gAvoidAOE or tonumber(gAvoidHP) == 0 or tonumber(gAvoidHP) < Player.hp.percent or not Player.onmesh) then
		return false
	end
	if IsEurekaMap(Player.localmapid) and (tonumber(gEurekaAvoidHP) == 0 or tonumber(gEurekaAvoidHP) < Player.hp.percent) then
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
	c_avoid.avoidDetails = {}
	
	-- Check for nearby enemies casting things on us.
	local el = EntityList("aggro,incombat,onmesh,maxdistance=40")
	if (table.valid(el)) then
		for i,entity in pairs(el) do
			local e = EntityList:Get(entity.id)
			if (e) then
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
				end
			end
		end
	end
	
	local el = EntityList("alive,incombat,attackable,onmesh,maxdistance=25")
	if (table.valid(el)) then
		for i,entity in pairs(el) do
			local e = EntityList:Get(entity.id)
			if (e) then
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
				end
			end
		end
	end
	if not IsNormalMap(Player.localmapid) then
		local el = EntityList("onmesh,maxdistance=40")
		if (table.valid(el)) then
			for i,entity in pairs(el) do
				local e = EntityList:Get(entity.id)
				if (e) then
					local shouldAvoid, spellData = AceLib.API.Avoidance.GetAvoidanceInfo(e)
					d(spellData)
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
					end
				end
			end
		end
	end
	if (table.valid(c_avoid.newAvoid)) then
		local newPos,seconds,obstacle = AceLib.API.Avoidance.GetAvoidancePos(c_avoid.newAvoid)
		if (table.valid(newPos)) then
			local ppos = Player.pos
			local moveDist = PDistance3D(ppos.x,ppos.y,ppos.z,newPos.x,newPos.y,newPos.z)
			if (moveDist > 1) then
				c_avoid.avoidDetails = { pos = newPos, seconds = seconds}
				return true
			else
				d("Dodge distance is very close.")
			end
		else
			d("Can't dodge, didn't find a valid position.")
		end
	end
	
	return false
end
function e_avoid:execute() 	
	local details = c_avoid.avoidDetails
	local tid = 0
	local currentTarget = Player:GetTarget()
	if (currentTarget) then
		tid = currentTarget.id
	elseif (ml_task_hub:ThisTask().targetid ~= 0) then
		tid = ml_task_hub:ThisTask().targetid
	end
	
	c_avoid.lastAvoid = c_avoid.newAvoid
	local newTask = ffxiv_task_avoid.Create()
	newTask.pos = details.pos
	newTask.targetid = c_avoid.newAvoid.attacker.id
	newTask.attackTarget = tid
	newTask.interruptCasting = true
	newTask.maxTime = details.seconds
	SetThisTaskProperty("preserveSubtasks",true)
	ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	d("Adding avoidance task.")
	
	c_bettertargetsearch.postpone = Now() + 5000
	if ((newTask.maxTime * 1000) > 5000) then
		c_bettertargetsearch.postpone = Now() + ((maxTime + 1) * 1000)
	end
end

c_autopotion = inheritsFrom( ml_cause )
e_autopotion = inheritsFrom( ml_effect )
c_autopotion.potions = {
	{ minlevel = 60, item = 23167 },
	{ minlevel = 50, item = 13637 },
	{ minlevel = 40, item = 4554 },
	{ minlevel = 30, item = 4553 },
	{ minlevel = 10, item = 4552 },
	{ minlevel = 1, item = 4551 },
}
c_autopotion.ethers = {
	{ minlevel = 60, item = 23168 },
	{ minlevel = 50, item = 13638 },
	{ minlevel = 40, item = 4558 },
	{ minlevel = 30, item = 4557 },
	{ minlevel = 10, item = 4556 },
	{ minlevel = 1, item = 4555 },
}
c_autopotion.item = nil
c_autopotion.lastPass = 0
function c_autopotion:evaluate()
	if (MIsLocked() or MIsLoading() or IsControlOpen("SelectString") or IsControlOpen("SelectIconString") or IsControlOpen("CutSceneSelectString")
		or IsShopWindowOpen() or Player.ismounted or IsFlying() or IsTransporting() or not Player.incombat or TimeSince(c_autopotion.lastPass) < 1000) 
	then
		return false
	end
	
	local findPotions = {}
	local plvl = Player.level
	
	-- Reset tempvar.
	c_autopotion.item = nil
	if (Player.alive) then
		if IsEurekaMap(Player.localmapid) then
			if (tonumber(gEurekaPotionHP) > 0 and Player.hp.percent < tonumber(gEurekaPotionHP)) then
				table.insert(findPotions,22306)
			end
			if gEurekaAntidote and (HasBuff(Player.id,18)) then
				table.insert(findPotions,4564)
			end
		else 
			local potions = c_autopotion.potions
			if (tonumber(gPotionHP) > 0 and Player.hp.percent < tonumber(gPotionHP)) then
				for k,itempair in ipairs(potions) do
					if (plvl >= itempair.minlevel) then
						table.insert(findPotions,itempair.item + 1000000)
						table.insert(findPotions,itempair.item)
					end
				end
			end
			
			local ethers = c_autopotion.ethers
			if (tonumber(gPotionMP) > 0 and Player.mp.percent < tonumber(gPotionMP)) then
				for k,itempair in ipairs(ethers) do
					if (plvl >= itempair.minlevel) then
						table.insert(findPotions,itempair.item + 1000000)
						table.insert(findPotions,itempair.item)
					end
				end
			end
		end
	end
	
	if (not table.valid(findPotions)) then
		c_autopotion.lastPass = Now()
		return false
	end
	
	local potionItems = GetItems(findPotions,{0,1,2,3})
	if (table.valid(potionItems)) then
		for prio,itemdata in ipairs(potionItems) do
			local potion,potionAction = itemdata.item, itemdata.action
			if (potion and potionAction and not potionAction.isoncd) then
				c_autopotion.item = potion
				return true
			end
		end
	else
		-- Didn't find the items, not likely to acquire them and need them in the next 10 seconds.
		-- This time could be much longer if not for the fact that the inventory API often fails to properly see all details.
		c_autopotion.lastPass = Now() + 10000
	end
	
	return false
end
function e_autopotion:execute()
	local item = c_autopotion.item
	if (item) then
		item:Cast(Player.id)
	end
	c_autopotion.lastPass = (Now() - 500)
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
			local pos = Player.pos
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
e_interactgate.conversationstrings = ""
function c_interactgate:evaluate()
	if (MIsLoading() or MIsLocked() or MIsCasting(true)) then
		return false
	end
	
	e_interactgate.id = 0
	e_interactgate.selector = 0
	e_interactgate.conversationstrings = ""
	
    if (ml_task_hub:CurrentTask().destMapID) then
		if (Player.localmapid ~= ml_task_hub:CurrentTask().destMapID) then
			local pos = ml_nav_manager.GetNextPathPos(	Player.pos, 
														Player.localmapid,	
														ml_task_hub:CurrentTask().destMapID	)

			if (table.valid(pos) and pos.g) then				
				local interacts = EntityList("targetable,maxdistance=4,contentid="..tostring(pos.g))
				if (table.valid(interacts)) then
					local i,interactable = next(interacts)
					if (i and interactable and interactable.interactable) then
						e_interactgate.id = interactable.id
						if (pos.i) then
							e_interactgate.selector = pos.i
						end
						if (pos.conversationstrings) then
							e_interactgate.conversationstrings = pos.conversationstrings
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
		ml_global_information.Await(100,2000, function () return not Player:IsMoving() end)
	end
	
	if (IsControlOpen("SelectString") or IsControlOpen("SelectIconString")) then
		if (e_interactgate.conversationstrings ~= "") then
			local conversationstrings = e_interactgate.conversationstrings
			local convoList = GetConversationList()
			if (table.valid(convoList)) then
				if (table.valid(conversationstrings)) then
					for selectindex,convo in pairs(convoList) do
						local cleanedline = CleanConvoLine(convo)
						for k,v in pairs(conversationstrings) do
							local cleanedv = CleanConvoLine(v)
							if (string.contains(cleanedline,cleanedv)) then
								d("Use conversation line ["..tostring(convo).."]")
								SelectConversationLine(selectindex)
								ml_global_information.Await(500,2000, function () return not (IsControlOpen("SelectString") and IsControlOpen("SelectIconString")) end)
								return false
							end
						end
					end
				end
			end
		else
			local selector = e_interactgate.selector
			SelectConversationIndex(selector)
			e_interactgate.timer = Now() + 1500
			return
		end
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
			local pos = ml_nav_manager.GetNextPathPos( 	Player.pos,	
														Player.localmapid,	
														ml_task_hub:CurrentTask().destMapID	)
			
			if (table.valid(pos)) then
				if (not c_usenavinteraction:evaluate(pos)) then
					if (table.valid(pos) and pos.b) then
						local details = {}
						details.contentid = pos.b
						details.pos = { x = pos.x, y = pos.y, z = pos.z }
						details.conversationIndex = pos.i or 0
						details.conversationstrings = pos.conversationstrings or ""
						e_transportgate.details = details
						return true
					elseif (table.valid(pos) and pos.a) then
						local details = {}
						details.contentid = pos.a
						details.pos = { x = pos.x, y = pos.y, z = pos.z }
						details.conversationIndex = pos.i or 0
						details.conversationstrings = pos.conversationstrings or ""
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
	if (gTeleportHack) then
		newTask.useTeleport = true
	end
	newTask.destMapID = ml_task_hub:CurrentTask().destMapID
	newTask.pos = gateDetails.pos
	newTask.contentid = gateDetails.contentid
	newTask.conversationIndex = gateDetails.conversationIndex
	newTask.conversationstrings = gateDetails.conversationstrings
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_movetogate = inheritsFrom( ml_cause )
e_movetogate = inheritsFrom( ml_effect )
e_movetogate.pos = {}
function c_movetogate:evaluate()
	if (Busy()) then
		return false
	end
	
	e_movetogate.pos = {}
	
    if (ml_task_hub:CurrentTask().destMapID and (Player.localmapid ~= ml_task_hub:CurrentTask().destMapID)) then
        local pos = ml_nav_manager.GetNextPathPos(	Player.pos,
													Player.localmapid,
													ml_task_hub:CurrentTask().destMapID	)
		if (table.valid(pos)) then
			e_movetogate.pos = pos
			return true
		end
	end
	
	return false
end
function e_movetogate:execute()
	local pos = e_movetogate.pos

	local mapid = ml_task_hub:CurrentTask().destMapID
	if (mapid == 399 and Player.localmapid == 478) then
		local destPos = ml_task_hub:CurrentTask().pos
		if (table.valid(destPos)) then
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
	if (gTeleportHack) then
		newTask.useTeleport = true
	end
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_teleporttomap = inheritsFrom( ml_cause )
e_teleporttomap = inheritsFrom( ml_effect )
e_teleporttomap.aeth = nil
function c_teleporttomap:evaluate()
	if (Busy() or GilCount() < 1500 or IsNull(ml_task_hub:ThisTask().destMapID,Player.localmapid) == Player.localmapid) then
		ml_debug("Cannot use teleport, position is locked, or we are casting.")
		return false
	end
	if (GilCount() < 1500) then
		ml_global_information.ShowInformation(GetString("Cannot use teleport, gil count is less than 1500."))
		return false
	end
	
	e_teleporttomap.aeth = nil
	
	--local el = EntityList("alive,attackable,onmesh,aggro")
	--if (table.valid(el)) then
		--ml_debug("Cannot use teleport, we have aggro currently.")
		--return false
	--end
	
	--Only perform this check when dismounted.
	local teleport = ActionList:Get(5,7)
	if (not teleport or not teleport:IsReady(Player.id) or Player.castinginfo.channelingid == 5) then
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
		local ppos = Player.pos
        local pos = ml_nav_manager.GetNextPathPos(	ppos,
                                                    Player.localmapid,
                                                    destMapID	)
		if (table.valid(pos)) then
			local dist = PDistance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
			
			if (table.valid(ml_nav_manager.currPath) and (TableSize(ml_nav_manager.currPath) > 2 or (TableSize(ml_nav_manager.currPath) <= 2 and dist > 120))) then
				
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
				d("using block 1")
				e_teleporttomap.aeth = aeth
				return true
			end
		
			local attunedAetherytes = GetAttunedAetheryteList()
			
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
			
			if (destMapID == 820 and not CanUseAetheryte(134)) then
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
						d("using block 2")
						e_teleporttomap.aeth = aetheryte
						return true
					end
				end
			end
			
			-- Fall back check to see if we can get to Foundation, and from there to the destination.
			for k,aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.id == 70 and GilCount() >= aetheryte.price) then
					local aethPos = {x = -68.819107055664, y = 8.1133041381836, z = 46.482696533203}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,418,destMapID)
					if (table.valid(backupPos)) then
						d("using block 2")
						e_teleporttomap.aeth = aetheryte
						return true
					end
				end
			end
			
			-- Fall back check to see if we can get to Idyllshire, and from there to the destination.
			for k,aetheryte in pairs(attunedAetherytes) do
				if (aetheryte.id == 75 and GilCount() >= aetheryte.price) then
					local aethPos = {x = 66.53, y = 207.82, z = -26.03}
					local backupPos = ml_nav_manager.GetNextPathPos(aethPos,478,destMapID)
					--table.print(ml_nav_manager.GetNextPathPos({x = 66.53, y = 207.82, z = -26.03},478,399))
					if (table.valid(backupPos)) then
						d("using block 3")
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
	
	if (c_killaggrotarget:evaluate()) then
		e_killaggrotarget:execute()
		return
	end
	
	if (ActionIsReady(7,5)) then
		if (Player:Teleport(e_teleporttomap.aeth.id)) then	
		
			ml_global_information.Await(10000, function () return IsControlOpen("NowLoading") end)
			
			if (ml_task_hub:CurrentTask().name ~= "MOVETOMAP") then
				ml_task_hub:CurrentTask().completed = true
			end
		
			local newTask = ffxiv_task_teleport.Create()
			newTask.setHomepoint = ml_task_hub:ThisTask().setHomepoint
			newTask.aetheryte = e_teleporttomap.aeth.id
			newTask.mapID = e_teleporttomap.aeth.territory
			ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
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
	if (table.valid(leaderPos) and table.valid(leader)) then
		local myPos = Player.pos	
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
		
		if (gUseMount and gMountName ~= GetString("none") and c_followleader.hasEntity) then
			if (((leader.castinginfo.channelingid == 4 or leader.ismounted) or distance >= tonumber(gMountDist)) and not Player.ismounted) then
				if (not MIsCasting()) then
					Player:Stop()
					Mount()
				end
				return
			end
		end
		
		--sprint
		if (gUseSprint and distance >= tonumber(gSprintDist)) then
			if ( not HasBuff(Player.id, 50) and not Player.ismounted) then
				local sprint = ActionList:Get(1,3)
				if (sprint:IsReady(Player.id)) then	
					sprint:Cast()
				end
			end
		end
		
		if (gTeleportHack) then
			if (distance > 100) then
				Hacks:TeleportToXYZ(leaderPos.x,leaderPos.y,leaderPos.z,true)
			end
		end
		
		if (c_followleader.hasEntity and leader.los) then
			ml_debug( "Moving to Leader: "..tostring(Player:MoveTo(leaderPos.x, leaderPos.y, leaderPos.z, tonumber(c_followleader.range), 0, 0, leader.id)))	
		else
			ml_debug( "Moving to Leader: "..tostring(Player:MoveTo(leaderPos.x, leaderPos.y, leaderPos.z, tonumber(c_followleader.range), 0, 0, leader.id)))	
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
			ml_global_information.AwaitDo(500, 30000, 
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
						return (Distance3DT(leaderPos,myPos) < 5)
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

c_updatewalkpos = inheritsFrom( ml_cause )
e_updatewalkpos = inheritsFrom( ml_effect )
e_updatewalkpos.pos = nil
function c_updatewalkpos:evaluate()
	e_updatewalkpos.pos = nil
	
	local customSearch = ml_task_hub:CurrentTask().customSearch
	if (string.valid(customSearch)) then
		local el = EntityList(customSearch)
		if (table.valid(el)) then
			local i,entity = next(el)
			if (i and entity) then
				if ( entity.distance < 50 ) then
					Player:SetTarget(entity.id)
				end
				local newPos = entity.pos
				if (not PosIsEqual(entity.pos,ml_task_hub:CurrentTask().pos)) then
					e_updatewalkpos.pos = entity.pos
					ml_task_hub:CurrentTask().pos = e_updatewalkpos.pos
				end
			end
		end
	end
	return false
end
function e_updatewalkpos:execute()
	-- don't really need this, waste of time
end

-- Part 1 of the split-logic nav.
-- This part will build the path, and walktopos will only need to check if one exists and enable pathing.
c_getmovementpath = inheritsFrom( ml_cause )
e_getmovementpath = inheritsFrom( ml_effect )
c_getmovementpath.lastFallback = 0
c_getmovementpath.lastGoal = {}
function c_getmovementpath:evaluate()
	if not Player.onmesh then
		return false
	end
	if (MIsLoading() or MIsLocked() or ffnav.IsProcessing()) then
		return false
	end
	
	if (table.valid(ml_task_hub:CurrentTask().pos) or table.valid(ml_task_hub:CurrentTask().gatePos)) then		
		local gotoPos = nil
		if (ml_task_hub:CurrentTask().gatePos) then
			gotoPos = ml_task_hub:CurrentTask().gatePos
			ml_debug("[c_getmovementpath]: Position adjusted to gate position.", "gLogCNE", 3)
		else
			gotoPos = ml_task_hub:CurrentTask().pos
			ml_debug("[c_getmovementpath]: Position left as original position.", "gLogCNE", 3)
		end
		
		if (table.valid(gotoPos)) then
			if (table.valid(ml_task_hub:CurrentTask().gatePos)) then
				local meshpos = FindClosestMesh(gotoPos,6,true)
				if (meshpos and meshpos.distance ~= 0 and meshpos.distance < 6) then
					ml_task_hub:CurrentTask().gatePos = meshpos
				end
			end
			
			local pathLength = 0
			
			local navid = IsNull(ml_task_hub:CurrentTask().navid,0)
			
			local dist = math.distance2d(gotoPos,Player.pos)
			-- Attempt to get a path that doesn't require cubes for stealth pathing.
			if (gBotMode == GetString("NavTest") and gTestNoFly) or (ml_global_information.needsStealth and not IsFlying() and not IsDiving() and not Player.incombat and not ml_task_hub:CurrentTask().alwaysMount) or (dist < tonumber(gMountDist) and (tonumber(gotoPos.y) >= Player.pos.y - 8 and tonumber(gotoPos.y) <= Player.pos.y + 8)) then
				ml_debug("[GetMovementPath]: rebuilding non-flying path..")
				pathLength = Player:BuildPath(tonumber(gotoPos.x), tonumber(gotoPos.y), tonumber(gotoPos.z),0,(GLOBAL.CUBE.AIR + GLOBAL.CUBE.AVOID),navid)
				ml_debug("[GetMovementPath]: no fly pathLength found, lenght: = "..tostring(pathLength))
			end
			
			if (gBotMode ~= GetString("NavTest") or (gBotMode == GetString("NavTest") and not gTestNoFly)) and (pathLength <= 0) then
				-- attempt to get a path with no avoidance first
				if (TimeSince(c_getmovementpath.lastFallback) > 10000 or not table.valid(c_getmovementpath.lastGoal) or math.distance3d(c_getmovementpath.lastGoal,gotoPos) > 1) then
					if (NavigationManager.ShowCells == nil ) then
					-- old nav version:
						pathLength = Player:BuildPath(tonumber(gotoPos.x), tonumber(gotoPos.y), tonumber(gotoPos.z),bit.bor((GLOBAL.FLOOR.BORDER + GLOBAL.FLOOR.AVOID),IsNull(ml_task_hub:CurrentTask().floorfilters,0)),bit.bor(GLOBAL.CUBE.AVOID,IsNull(ml_task_hub:CurrentTask().cubefilters,0)),navid)
					else
					-- new nav version:
						pathLength = Player:BuildPath(tonumber(gotoPos.x), tonumber(gotoPos.y), tonumber(gotoPos.z),bit.bor(GLOBAL.FLOOR.AVOID,IsNull(ml_task_hub:CurrentTask().floorfilters,0)),bit.bor(GLOBAL.CUBE.AVOID,IsNull(ml_task_hub:CurrentTask().cubefilters,0)),navid)
					end
					--d("Pulled a path with no avoids: Last Fallback ["..tostring(TimeSince(c_getmovementpath.lastFallback)).."], goal dist ["..tostring(math.distance3d(c_getmovementpath.lastGoal,gotoPos)).."]")
					ml_debug("[GetMovementPath]: pathLength with no avoids = "..tostring(pathLength))
				end
				
				if (pathLength <= 0) then
					ml_debug("[GetMovementPath]: rebuild cube path..")
					pathLength = Player:BuildPath(tonumber(gotoPos.x), tonumber(gotoPos.y), tonumber(gotoPos.z),IsNull(ml_task_hub:CurrentTask().floorfilters,0),IsNull(ml_task_hub:CurrentTask().cubefilters,0),navid)
					c_getmovementpath.lastFallback = Now()
					c_getmovementpath.lastGoal = gotoPos
					ml_debug("[GetMovementPath]: pathLength cube path = "..tostring(pathLength))
				end
			end
			
			if (pathLength > 0 or ml_navigation:HasPath()) then
				ml_debug("[GetMovementPath]: Path length returned ["..tostring(pathLength).."]")
				return false
			end
		else
			d("[GetMovementPath]: Invalid gotopos in current Task")
		end
	else
		d("[GetMovementPath]: Current Task does not have a valid position !")
	end
	
	d("[GetMovementPath]: We could not get a path to our destination.")
    return true
end
function e_getmovementpath:execute()
	-- Logic is reversed here, if we successfully updated the path, there's no reason to do anything.
	-- If no path was pulled, we should Stop() the character, because there's no reason to try mount/stealth/walk without any path.
	if (Player:IsMoving()) then
		Player:Stop()
	end
end

---------------------------------------------------------------------------------------------
--Task Completion CNEs
--These are cnes which are added to the process element list for a task and exist only to
--complete the specified task. They should be specific to the task which contains them...
--their only purpose should be to check the current game state and adjust the behavior of 
--the task in order to ensure its completion. 
---------------------------------------------------------------------------------------------
c_walktopos = inheritsFrom( ml_cause )
e_walktopos = inheritsFrom( ml_effect )
function c_walktopos:evaluate()
	if (Busy() or Player:IsJumping() or IsMounting()) then
		return false
	end
	
	if (ml_navigation:HasPath()) then
		if (ml_navigation:EnablePathing()) then
			ml_debug("[WalkToPos]: Pathing was started.")
		end
		return true
	else
		if (ml_navigation:DisablePathing()) then
			ml_debug("[WalkToPos]: Pathing was stopped.")
			return true
		end
	end
	
    return false
end
function e_walktopos:execute()
	-- Nothing to really do here, just updating the pathing var, which should allow navigation to begin running.
end

-- Slight difference here in that we cannot simply stop near an entity if we are flying.
-- Player must be forced to the ground in order to be able to dismount if at all possible.
-- Sometimes due to the way the pathing works, it will put us hovering right at an object, and this is not acceptable.
c_walktoentity = inheritsFrom( ml_cause )
e_walktoentity = inheritsFrom( ml_effect )
function c_walktoentity:evaluate()
	if (Busy() or Player:IsJumping() or IsMounting()) then
		return false
	end
	
	if (ml_navigation:HasPath()) then
		if (ml_navigation:EnablePathing()) then
			ml_debug("[WalkToEntity]: Pathing was started.",3)
		end
		return true
	else
		if (ml_navigation:DisablePathing()) then
			ml_debug("[WalkToEntity]: Pathing was stopped.",3)
		end
	end
	
    return false
end
function e_walktoentity:execute()
	-- Nothing to really do here, just updating the pathing var, which should allow navigation to begin running.
end

c_avoidaggressives = inheritsFrom( ml_cause )
e_avoidaggressives = inheritsFrom( ml_effect )
c_avoidaggressives.lastSet = {}
function c_avoidaggressives:evaluate()
	-- Disabled this for now, the size is too unpredictable.
	if (IsFlying() or MIsLocked() or true) then
		return false
	end
	
	local lastSet = c_avoidaggressives.lastSet
	local ppos = Player.pos
	if (table.valid(lastSet)) then
		if (Player.localmapid == lastSet.mapid) then
			local dist = PDistance3D(lastSet.x,lastSet.y,lastSet.z,ppos.x,ppos.y,ppos.z)
			if (dist <= 80 or Player:IsMoving()) then
				return false
			end
		end
	end
	
	local needsUpdate = false
	
	local interactable
	if (ml_task_hub:CurrentTask().interact ~= 0) then
		interactable = EntityList:Get(ml_task_hub:CurrentTask().interact)
	end
	
	local cpos = ml_task_hub:CurrentTask().pos
	
	local aggressives = EntityList("alive,attackable,aggressive,minlevel="..tostring(Player.level - 10)..",maxdistance=50")
	if (table.valid(aggressives)) then
		local avoidanceAreas = ml_global_information.avoidanceAreas
		for i,entity in pairs(aggressives) do
			if (entity.distance2d < 15 or entity.los) then
					
				local hasEntry = false
				for k,area in pairs(avoidanceAreas) do
					if (area.source == "c_avoidaggressives") then
						if (area.id == entity.id) then
							local movedDist = PDistance3D(entity.pos.x,entity.pos.y,entity.pos.z,area.x,area.y,area.z)
							if (area.expiration < Now()) then
								d("Removed avoidance area for ["..tostring(entity.name).."] because it has expired.")
								avoidanceAreas[k] = nil
							elseif (movedDist > 4) then
								d("Removed avoidance area for ["..tostring(entity.name).."] because it is no longer valid.")
								avoidanceAreas[k] = nil
							else
								if (interactable) then
									local intDist = math.distance2d(interactable.pos,entity.pos)
									if (intDist < 15) then
										avoidanceAreas[k] = nil
									end
								end
								
								hasEntry = true
							end
						end
					end
				end
				
				if (not hasEntry) then
					local newArea = { id = entity.id, x = round(entity.pos.x,1), y = round(entity.pos.y,1), z = round(entity.pos.z,1), level = entity.level, r = 0, expiration = Now() + 15000, source = "c_avoidaggressives" }
					
					local canAdd = true
					if (interactable) then
						local intDist = math.distance2d(interactable.pos,newArea)
						if (intDist < 15) then
							d("Could not add avoidance area, too close to interactable.")
							canAdd = false
						end
					end
					
					--[[
					if (table.valid(cpos)) then
						local intDist = math.distance2d(cpos,newArea)
						if (intDist <= newArea.r) then
							d("Could not add avoidance area, too close to destination.")
							canAdd = false
						end
					end
					--]]
					
					if (canAdd) then
						d("Setting avoidance area for ["..tostring(entity.name).."]. Total Avoidance areas: "..tostring(table.size(avoidanceAreas)))
						table.insert(avoidanceAreas,newArea)
						needsUpdate = true
					end
				end
			end
		end		
	else
		local avoidanceAreas = ml_global_information.avoidanceAreas
		if (table.valid(avoidanceAreas)) then
			for i,area in pairs(avoidanceAreas) do
				if (area.source == "c_avoidaggressives") then
					avoidanceAreas[i] = nil
					needsUpdate = true
				end
			end
		end
	end
	
	if (needsUpdate) then
		local avoidanceAreas = ml_global_information.avoidanceAreas
		if (table.valid(avoidanceAreas)) then
			--d("Setting avoidance areas.")
			NavigationManager:SetAvoidanceAreas(avoidanceAreas)
		else
			NavigationManager:ClearAvoidanceAreas()
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
e_useaethernet.isresidential = nil
c_useaethernet.used = false
function c_useaethernet:evaluate(mapid, pos)
	if (IsTransporting()) then
		return false
	end
	
	local gotoPos = pos or ml_task_hub:CurrentTask().pos
	local destMapID = IsNull(ml_task_hub:CurrentTask().destMapID,0)
	if (destMapID == 0) then
		destMapID = Player.localmapid
	end

	e_useaethernet.nearest = nil
	e_useaethernet.destination = nil
	e_useaethernet.isresidential = nil
	
	if (c_useaethernet.used) then
		return false
	elseif (not table.valid(gotoPos)) then
		return false
	elseif (table.valid(gotoPos) and Distance3DT(gotoPos,Player.pos) < 30 and destMapID == Player.localmapid) then
		return false
	end	
	
	local gotoDist = Distance3DT(gotoPos,Player.pos)
	
	if (Player.localmapid == 129 and destMapID == 339 and QuestCompleted(1214)) then
		e_useaethernet.nearest = {
			["id"] = 8, ["mapid"] = 129, ["pos"] = { ["x"] = -81.74, ["y"] = 18.9, ["z"] = 3.56 }
		}
		e_useaethernet.isresidential = true
		return true
	elseif (Player.localmapid == 132 and destMapID == 340 and QuestCompleted(1212)) then
		e_useaethernet.nearest = {
			["id"] = 2, ["mapid"] = 132, ["pos"] = { ["x"] = 34, ["y"] = 2.2, ["z"] = 32.62	}
		}
		e_useaethernet.isresidential = true
		return true
	elseif (Player.localmapid == 130 and destMapID == 341 and QuestCompleted(1213)) then
		e_useaethernet.nearest = {
			["id"] = 9, ["mapid"] = 130, ["pos"] = { ["x"] = -142.28, ["y"] = -3.15, ["z"] = -166 }
		}
		e_useaethernet.isresidential = true
		return true
	else
		local nearestAethernet,nearestDistance = AceLib.API.Map.GetNearestAethernet(Player.localmapid,Player.pos,1)	
		local bestAethernet,bestDistance = AceLib.API.Map.GetBestAethernet(destMapID,gotoPos)
		if (nearestAethernet and bestAethernet and (nearestAethernet.id ~= bestAethernet.id) and (bestDistance < gotoDist or destMapID ~= Player.localmapid)) then
			if (IsNull(ml_task_hub:CurrentTask().contentid,0) ~= nearestAethernet.id) then 
				d("best athernet for ["..tostring(destMapID).."] - ["..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z).."] is ["..tostring(bestAethernet.id))
				--d("current id:"..tostring(ml_task_hub:CurrentTask().contentid)..", new id:"..tostring(nearestAethernet.id))
				e_useaethernet.nearest = nearestAethernet
				e_useaethernet.destination = bestAethernet
				return true
			end
		end
	end
	
	return false
end
function e_useaethernet:execute()
	if (table.valid(e_useaethernet.nearest)) then
		if (e_useaethernet.isresidential) then
			local newTask = ffxiv_task_moveaethernet.Create()
			newTask.contentid = e_useaethernet.nearest.id
			newTask.pos = e_useaethernet.nearest.pos
			--newTask.conversationstrings = e_useaethernet.destination.conversationstrings
			newTask.useAethernet = true
			newTask.isResidential = true
			c_useaethernet.used = true
			
			ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
		elseif (table.valid(e_useaethernet.destination)) then
			d("Use aethernet task to go from ["..tostring(e_useaethernet.nearest.id).."] to ["..tostring(e_useaethernet.destination.id).."]")
			local newTask = ffxiv_task_moveaethernet.Create()
			newTask.contentid = e_useaethernet.nearest.id
			newTask.pos = e_useaethernet.nearest.pos
			newTask.conversationstrings = e_useaethernet.destination.conversationstrings
			newTask.useAethernet = true
			c_useaethernet.used = true
			
			ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
		end
	end
end

c_unlockaethernet = inheritsFrom( ml_cause )
e_unlockaethernet = inheritsFrom( ml_effect )
e_unlockaethernet.nearest = nil
e_unlockaethernet.destination = nil
function c_unlockaethernet:evaluate(mapid, pos)
	if (IsTransporting()) then
		return false
	end
	
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
	
	local nearestAethernetUnlocked,nearestDistanceUnlocked = AceLib.API.Map.GetNearestAethernet(Player.localmapid,Player.pos,1)		
	local nearestAethernetLocked,nearestDistanceLocked = AceLib.API.Map.GetNearestAethernet(Player.localmapid,Player.pos,2)	
	if (nearestAethernetLocked and (not nearestAethernetUnlocked or nearestDistanceLocked <= nearestDistanceUnlocked)) then
		if (IsNull(ml_task_hub:CurrentTask().contentid,0) ~= nearestAethernetLocked.id) then 
			--d("current id:"..tostring(ml_task_hub:CurrentTask().contentid)..", new id:"..tostring(nearestAethernetLocked.id))
			if (nearestDistanceLocked < 15 or nearestDistanceLocked < Distance3DT(Player.pos,gotoPos)) then
				e_unlockaethernet.nearest = nearestAethernetLocked
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
		newTask.contentid = e_unlockaethernet.nearest.id
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
	if (IsTransporting()) then
		return false
	end
	
	local gotoPos = pos or ml_task_hub:ThisTask().pos
	
	e_usenavinteraction.task = nil
	c_usenavinteraction.blockOnly = false
	
	if (not table.valid(gotoPos)) then
		return false
	end
	
	local transportFunction = _G["Transport"..tostring(Player.localmapid)]
	if (transportFunction ~= nil and type(transportFunction) == "function") then
		local retval,task = transportFunction(Player.pos,gotoPos)
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
--c_bettertargetsearch.throttle = 1000
c_bettertargetsearch.postpone = 0
function c_bettertargetsearch:evaluate()        
    if (MIsLoading() or MIsLocked() or
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
	c_bettertargetsearch.postpone = Now() + 5000
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
c_mount.blockOnly = true
function c_mount:evaluate()
	if (MIsLocked() or MIsLoading() or IsControlOpen("SelectString") or IsControlOpen("SelectIconString") 
		or IsShopWindowOpen() or IsFlying() or IsTransporting() or IsSwimming())
	then
		return false
	end
	
	c_mount.blockOnly = false
	
	local myPos = Player.pos
	local gotoPos = ml_task_hub:CurrentTask().pos
	if (table.valid(gotoPos)) then
		local dist2d = math.distance2d(myPos, gotoPos)
		local dist3d = math.distance3d(myPos, gotoPos)
		local dismountDistance = IsNull(ml_task_hub:CurrentTask().dismountDistance,5)
		
		local needsMount = false
		if (table.valid(ml_navigation.path)) then
			for i, node in pairs(ml_navigation.path) do
				if (i >= ml_navigation.pathindex) then
					ml_navigation.TagNode(node)
					if (node.air or node.air_avoid) then
						needsMount = true
					end
				end
			end		
		end
		
		if (not needsMount) then
			if (dismountDistance > 0 and dist2d <= dismountDistance and 
				(dist3d <= (dismountDistance + 3) or (IsFlying() and dist3d <= (dismountDistance + 10)))) 
			then
				local doDismount = false
				if (Player.ismounted and not ml_task_hub:CurrentTask().remainMounted) then
					doDismount = true
				end
				if (doDismount and not IsDismounting()) then
					Dismount()
					c_mount.blockOnly = true
					return true
				end
				return false
			else
				--d("remain mounted ["..tostring(ml_task_hub:CurrentTask().remainMounted).."], not within dismount distance ["..tostring(dismountDistance).."], dist2d ["..tostring(dist2d).."], dist3d ["..tostring(dist3d).."]")
			end
		else
			--d("[Mount]: Cannot dismount, needs to fly still.")
		end
	end
	
	if (Player.ismounted or Player.incombat or ml_task_hub:CurrentTask().nomount) then
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
	
    if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0 and gUseMount) then
		local lastPos = e_mount.lastPathPos

		-- If we change our gotoPos or have never measured it, reset the watch.
		if (table.valid(lastPos)) then
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
			end
		end
		
		if ((distance > tonumber(gMountDist)) or forcemount) then
			--Added mount verifications here.
			--Realistically, the GUIVarUpdates should handle this, but just in case, we backup check it here.
			local mountID
			local mountIndex
			local mountlist = ActionList:Get(13)
			
			if (table.valid(mountlist)) then
				--First pass, look for our named mount.
				for id,acMount in pairsByKeys(mountlist) do
					if (acMount.name == gMountName and ((acMount.canfly and (id > 1 or QuestCompleted(2117))) or not CanFlyInZone())) then
						if (acMount:IsReady(Player.id)) then
							e_mount.id = acMount.id
							return true
						end
					end
				end
				
				--Second pass, look for any mount as backup.
				for id,acMount in pairsByKeys(mountlist) do
					if (acMount:IsReady(Player.id) and ((acMount.canfly and (id > 1 or QuestCompleted(2117))) or not CanFlyInZone())) then
						e_mount.id = acMount.id
						return true
					end
				end		
			end
		end
    end
    
    return false
end
function e_mount:execute()
	if (c_mount.blockOnly) or not Player.onmesh then
		return false
	end
	
	if (Player:IsMoving()) then
		Player:PauseMovement()
		ml_global_information.AwaitDo(1000, function () return not Player:IsMoving() end, function () Player:PauseMovement() end)
		return
	end
	
	if (IsMounting() or UsingBattleItem()) then
		return
	end
	
	if (Mount(e_mount.id)) then
		ml_global_information.AwaitSuccess(500, 
			function () 
				return (IsMounting() or UsingBattleItem())
			end,
			function ()
				ml_global_information.Await(3000, function () return Player.ismounted end)
			end
		)
	end
end

c_battlemount = inheritsFrom( ml_cause )
e_battlemount = inheritsFrom( ml_effect )
e_battlemount.id = 0
function c_battlemount:evaluate()
	if (MIsLocked() or MIsLoading() or IsControlOpen("SelectString") or IsControlOpen("SelectIconString") 
		or IsShopWindowOpen() or Player.ismounted or Player.incombat or IsFlying() or IsTransporting()) 
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
	
    if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0 and gUseMount) then
		local myPos = Player.pos
		local gotoPos = ml_task_hub:CurrentTask().pos
		local distance = PDistance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
	
		if (distance > tonumber(gMountDist)) then
			--Added mount verifications here.
			--Realistically, the GUIVarUpdates should handle this, but just in case, we backup check it here.
			local mountID
			local mountIndex
			local mountlist = ActionList:Get(13)
			
			if (table.valid(mountlist)) then
				--First pass, look for our named mount.
				for id,acMount in pairsByKeys(mountlist) do
					if (acMount.name == gMountName) then
						if (acMount:IsReady(Player.id)) then
							e_mount.id = acMount.id
							return true
						end
					end
				end
				
				--Second pass, look for any mount as backup.
				if (gMountName == GetString("none")) then
					for id,acMount in pairsByKeys(mountlist) do
						if (acMount:IsReady(Player.id)) then
							e_mount.id = acMount.id
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
		Player:PauseMovement()
		ml_global_information.Await(1500, function () return not Player:IsMoving() end)
		return
	end
	
	if (IsMounting() or UsingBattleItem()) then
		--d("Adding a wait.")
		ml_global_information.Await(2000)
		return
	end
	
    Mount(e_battlemount.id)
	--d("Set a delay for 500")
	ml_global_information.Await(500)
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
    if (ffxiv_task_quest.noCompanion == true or gBotMode == GetString("pvpMode") or InInstance() or Player.ismounted or IsMounting() or IsDismounting() or
		IsCompanionSummoned() or (Player.castinginfo.lastcastid == 851 and Player.castinginfo.timesincecast < 10000)) 
	then
		--[[
		d("1:"..tostring(ffxiv_task_quest.noCompanion))
		d("2:"..tostring(gBotMode == GetString("pvpMode")))
		d("3:"..tostring(Player.ismounted))
		d("4:"..tostring(IsMounting()))
		d("5:"..tostring(IsDismounting()))
		d("6:"..tostring(IsCompanionSummoned()))
		d("7:"..tostring(InInstance()))
		d("8:"..tostring((Player.castinginfo.lastcastid == 851 and Player.castinginfo.timesincecast < 10000)))
		--]]
        return false
    end

    if ((gChocoGrind and (gBotMode == GetString("grindMode") or gBotMode == GetString("partyMode") or ml_task_hub:CurrentTask().name == "GRIND_COMBAT")) or
		(gChocoAssist and gBotMode == GetString("assistMode")) or
		(gChocoQuest and gBotMode == GetString("questMode"))) 
	then	
		local green = GetItem(4868)
		if (green and green:IsReady()) then
			return true
		end
    end
	
    return false
end
function e_companion:execute()
	if (Player:IsMoving()) then
		Player:PauseMovement()
		ml_global_information.Await(1500, function () return not Player:IsMoving() end)
	end
	
	local green = GetItem(4868)
	if (green and green:IsReady()) then
		green:Cast()
		ml_global_information.AwaitSuccess(1000,2500, function () return Player.castinginfo.castingid == 851 end)
	end
end

c_stance = inheritsFrom( ml_cause )
e_stance = inheritsFrom( ml_effect )
function c_stance:evaluate()
	if (gChocoStanceString ~= GetString("None")) then -- Index 6 is "none"
		local companion = GetCompanionEntity()
		if (companion and ValidString(gChocoStanceString)) then
			if (TimeSince(ml_global_information.stanceTimer) >= 30000) then
				local stanceAction = ml_global_information.chocoStance[gChocoStanceString]
				if (stanceAction) then
					local acStance = ActionList:Get(6,stanceAction)		
					if (acStance and not acStance.isoncd and acStance.usable) then
						acStance:Cast(Player.id)
						return true
					end
				end
			end
		end
	end
    
    return false
end
function e_stance:execute()
	ml_global_information.stanceTimer = Now()
	SetThisTaskProperty("preserveSubtasks",true)
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
	
	if (MIsLocked() or MIsLoading() or IsMounting() or IsControlOpen("SelectString") or IsControlOpen("SelectIconString") or IsShopWindowOpen() or Player.ismounted or IsTransporting()) then
		return false
	end

    if (not HasBuff(Player.id, 50) and Player:IsMoving()) then
		if (IsCityMap(Player.localmapid) or gUseSprint) then
			if ( ml_task_hub:CurrentTask().pos ~= nil and ml_task_hub:CurrentTask().pos ~= 0) then
				local myPos = Player.pos
				local gotoPos = ml_task_hub:CurrentTask().pos
				local distance = PDistance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
				
				if (distance > tonumber(gSprintDist)) then	
					local sprint = ActionList:Get(1,3)
					if (sprint and sprint:IsReady(Player.id)) then
						return true
					end
				end
			end
		end
    end
    
    return false
end
function e_sprint:execute()
    local sprint = ActionList:Get(1,3)
	if (sprint and sprint:IsReady(Player.id)) then
		sprint:Cast()
	end
end

---------------------------------------------------------------------------------------------
--REST: If (not player.hasAggro and player.hp.percent < 50) Then (do nothing)
--Blocks all subtask execution until player hp has increased
---------------------------------------------------------------------------------------------
c_rest = inheritsFrom( ml_cause )
e_rest = inheritsFrom( ml_effect )
function c_rest:evaluate()
	if (Now() < ml_global_information.suppressRestTimer and Player.hp.percent > 20) then
		return false
	end
	
	if (InInstance() and not IsEurekaMap(Player.localmapid)) then
		return false
	end
	
	if (ml_task_hub:ThisTask().name == "LT_GRIND") then
		if (gGrindDoFates and gGrindFatesOnly ) then
			return false
		end
	elseif (ml_task_hub:ThisTask().name == "LT_FATE") then
		local fate = MGetFateByID(ml_task_hub:ThisTask().fateid)
		if (table.valid(fate)) then
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
	
	local dorest = false
	if IsEurekaMap(Player.localmapid) then
		if (( tonumber(gEurekaRestHP) > 0 and Player.hp.percent < tonumber(gEurekaRestHP)) or
		(( tonumber(gEurekaRestMP) > 0 and Player.mp.percent < tonumber(gEurekaRestMP)) and not isDOL and not isDOH)) then
			dorest = true
		end
	else	
		if (( tonumber(gRestHP) > 0 and Player.hp.percent < tonumber(gRestHP)) or
		(( tonumber(gRestMP) > 0 and Player.mp.percent < tonumber(gRestMP)) and not isDOL and not isDOH)) then
			dorest = true
		end
	end
		
		
	if dorest then
		if (Player.incombat or not Player.alive) then
			--d("Cannot rest, still in combat or not alive.")
			return false
		end
		
		local aggrolist = EntityList("alive,aggro")
		if (table.valid(aggrolist)) then
			--d("Cannot rest, has aggro.")
			return false
		end
		
		-- don't rest if we have rest in fates disabled and we're in a fate or FatesOnly is enabled
		if (not gRestInFates) then
			if (gBotMode == GetString("grindMode")) then
			--d("Cannot rest, not Rest In Fates.")
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
	if (params and params.noflee and params.noflee == true or InInstance()) then
		return false
	end
	
	if (InInstance()) then
		return false
	end
	
	e_flee.fleePos = {}
	
	if ((Player.incombat) and (Player.hp.percent < GetFleeHP() or Player.mp.percent < tonumber(gFleeMP))) then
		local ppos = Player.pos
		
		local evacPoint = GetNearestEvacPoint()
		if (evacPoint) then
			local fpos = evacPoint.pos
			if (Distance3D(ppos.x, ppos.y, ppos.z, fpos.x, fpos.y, fpos.z) > 50) then
				if (ml_navigation:CheckPath(fpos,true)) then
					e_flee.fleePos = fpos
					return true
				end
			end
		end
		
		for i = 1,10 do
			local newPos = NavigationManager:GetRandomPointOnCircle(ppos.x,ppos.y,ppos.z,100,200)
			if (table.valid(newPos)) then
				local p = FindClosestMesh(newPos,20,false)
				if (p and ml_navigation:CheckPath(p,true)) then
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
	if (table.valid(fleePos)) then
		local newTask = ffxiv_task_flee.Create()
		newTask.pos = fleePos
		newTask.useTeleport = (gTeleportHack)
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	end
end

c_eat = inheritsFrom( ml_cause )
e_eat = inheritsFrom( ml_effect )
function c_eat:evaluate()
	if (Player.incombat or Busy()) then
		return false
	end
	
	if ( gFood ~= GetString("none")) then
		if ( TimeSince(ml_global_information.foodCheckTimer) > 10000) then
			if (ShouldEat()) then
				return true
			end
		end
	end
    return false
end
function e_eat:execute()
	if (Player:IsMoving()) then
		Player:PauseMovement()
		ml_global_information.Await(1500, function () return not Player:IsMoving() end)
		return false
	end
	
	Eat()
	ml_global_information.foodCheckTimer = Now()
	ml_global_information.Await(2000)
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
		ml_marker_mgr.currentMarker = nil
		ffxiv_task_grind.inFate = false
	elseif (ml_task_hub:ThisTask().name == "LT_GATHER") then
		ml_task_hub:ThisTask().gatherid = 0
		ml_task_hub:ThisTask().markerTime = 0
		ml_marker_mgr.currentMarker = nil
		ml_task_hub:ThisTask().failedSearches = 0 
	elseif (ml_task_hub:ThisTask().name == "LT_FISH") then
		ml_task_hub:ThisTask().castTimer = 0
		ml_task_hub:ThisTask().markerTime = 0
		ml_marker_mgr.currentMarker = nil
		ml_task_hub:ThisTask().networkLatency = 0
		ml_task_hub:ThisTask().requiresAdjustment = false
		ml_task_hub:ThisTask().snapshot = GetInventorySnapshot({0,1,2,3})
	end
	
	if (e_dead.blockOnly) then
		e_dead.blockOnly = false
		return
	end
		
	if (IsControlOpen("_NotificationParty")) then
		return
	end

	if (Player.revivestate == 2) then
		-- try raise first
		if (IsEurekaMap(Player.localmapid)) then
			if (HasBuffs(Player,"148,1140")) then
				if (UseControlAction("SelectYesno","Yes")) then
					c_dead.timer = 0
					ml_global_information.Await(20000, function () return Player.alive end)
					return
				end
			end
		else
			if (UseControlAction("SelectYesno","Yes")) then
				c_dead.timer = 0
				ml_global_information.Await(20000, function () return Player.alive end)
				return
			end
		end
	end
end

c_pressconfirm = inheritsFrom( ml_cause )
e_pressconfirm = inheritsFrom( ml_effect )
function c_pressconfirm:evaluate()
	if (gBotMode == GetString("assistMode")) then
		return (gAssistConfirmDuty and IsControlOpen("ContentsFinderConfirm") and not MIsLoading())
	end
	
    return (IsControlOpen("ContentsFinderConfirm") and not MIsLoading() and Player.revivestate ~= 2 and Player.revivestate ~= 3)
end
function e_pressconfirm:execute()
	if (UseControlAction("ContentsFinderConfirm","Confirm")) then
		if (gBotMode == GetString("pvpMode")) then
			ml_task_hub:ThisTask().state = "DUTY_STARTED"
		elseif (gBotMode == GetString("dutyMode") and IsDutyLeader()) then
			ffxiv_task_duty.state = "DUTY_ENTER"
		end
		ml_global_information.Await(5000, function () return not IsControlOpen("ContentsFinderConfirm")  end)
	end
end

-- more to refactor here later most likely
c_returntomarker = inheritsFrom( ml_cause )
e_returntomarker = inheritsFrom( ml_effect )
function c_returntomarker:evaluate()
	if (Busy() or Player.incombat) then
		return false
	end
	
    if (gBotMode == GetString("partyMode") and not IsPartyLeader()) then
        return false
    end
	
	if (table.valid(ffxiv_fish.currentTask) or not ml_marker_mgr.currentMarker) then
		return false
	end
    
	-- right now when randomize markers is active, it first walks to the marker and then checks for levelrange, this should probably get changed, but 
	-- making this will most likely break the behavior on some badly made meshes 
	local currentMarker = ml_marker_mgr.currentMarker
	local markerType = currentMarker.type
	if (markerType == GetString("unspoiledMarker") and not ffxiv_task_gather.IsIdleLocation()) then
		return false
	end

	local myPos = Player.pos
	local pos = currentMarker.pos
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
			local maxradius = currentMarker.maxradius
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
    
    return false
end
function e_returntomarker:execute()
	if (gBotMode == GetString("fishMode")) then
		local fs = tonumber(Player:GetFishingState())
		if (fs ~= 0) then
			local finishcast = ActionList:Get(1,299)
			if (finishcast and finishcast:IsReady(Player.id)) then
				finishcast:Cast()
			end
			return
		end
	end
	
    local newTask = ffxiv_task_movetopos.Create()
    local markerPos = ml_marker_mgr.currentMarker.pos
    local markerType = ml_marker_mgr.currentMarker.type
    newTask.pos = markerPos
    newTask.range = math.random(3,5)
	
	if (markerType == GetString("huntMarker") or
		markerType == "Mining" or
		markerType == "Botany" or
		markerType == GetString("grindMarker")) 
	then
		newTask.remainMounted = true
	end
	
    if (markerType == "Fishing") then
        newTask.pos.h = markerPos.h
        newTask.range = 0.5
        newTask.doFacing = true
    end
	if (gTeleportHack) then
		newTask.useTeleport = true
	end
	
	if (markerType == "Mining" or markerType == "Botany") then
		newTask.stealthFunction = ffxiv_gather.NeedsStealth
	elseif (markerType == "Fishing") then
		newTask.stealthFunction = ffxiv_fish.NeedsStealth
	end
	
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
		if (IsControlOpen("Gathering") or fs ~= 0) then
			return false
		end
		
		local needsStealth = (stealthFunction() and not ml_task_hub:CurrentTask().alwaysMount and not IsFlying())
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

c_dostealth = inheritsFrom( ml_cause )
e_dostealth = inheritsFrom( ml_effect )
c_dostealth.lastStealth = 0
c_dostealth.addStealth = false
c_dostealth.dropStealth = false
function c_dostealth:evaluate()	
	c_dostealth.addStealth = false
	c_dostealth.dropStealth = false

	if GameRegion() == 1 then
		return false
	end
	local needsStealth = ml_global_information.needsStealth
	ml_global_information.canStealth = ml_global_information.needsStealth
	local hasStealth = HasBuff(Player.id,47)
	local nextnode = ml_navigation.path[ ml_navigation.pathindex ]
	ml_navigation.TagNode(nextnode)
	if (needsStealth and nextnode and nextnode.is_cube) then
		-- If we have stealth, we could actually walk up to a cube node to some degree sometimes, but this may not be needed, so keeping it simple for now.
		-- Not going to remove stealth in this cne because mounting should take care of it for us and be safer.
		d("[DoStealth]: Next node type is a cube, we won't be able to stealth to it.")
		ml_global_information.canStealth = false
		return false
	end
	
	if (not IsGatherer(Player.job) and not IsFisher(Player.job)) then
		ml_global_information.canStealth = false
		return false
	end
	
	-- 367 is the player animation for stealth and 1200 is just a little more than the time it usually takes to add it.
	if (Player.action ~= 367 and TimeSince(c_dostealth.lastStealth) > 1200) then
		if (needsStealth and not hasStealth) then
			c_dostealth.addStealth = true
			return true
		elseif (not needsStealth and hasStealth) then
			
			-- Check if stealth will be broken by mount, if it will, don't manually remove it.
			local myPos = Player.pos
			local gotoPos = ml_task_hub:CurrentTask().pos
			if (table.valid(gotoPos)) then
				local dist2d = math.distance2d(myPos, gotoPos)
				local dist3d = math.distance3d(myPos, gotoPos)
				
				local needsMount = false
				if (table.valid(ml_navigation.path)) then
					for i, node in pairs(ml_navigation.path) do
						if (i >= ml_navigation.pathindex) then
							ml_navigation.TagNode(node)
							if (node.air or node.air_avoid) then
								needsMount = truec_autopotion
							end
						end
					end		
				end
				
				local noMountMaps = {
					[130] = true,[131] = true,[132] = true,[133] = true,[128] = true,[129] = true,[144] = true,
					[337] = true,[336] = true,[175] = true,[352] = true,[418] = true,[419] = true,
				}
				
				if (not noMountMaps[Player.localmapid]) then
					local forcemount = false
					if (CanFlyInZone()) then
						if (ml_task_hub:CurrentTask().alwaysMount) then
							forcemount = true
						end
					end
				
					if ((dist3d > tonumber(gMountDist)) or forcemount or needsMount) then
						return false
					end
				end
			
			end
			
			c_dostealth.dropStealth = true
			return true
		end
	end
	
	return false
end
function e_dostealth:execute()
	local newTask = ffxiv_task_stealth.Create()
	newTask.addingStealth = c_dostealth.addStealth
	newTask.droppingStealth = c_dostealth.dropStealth
	ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_IMMEDIATE)
	c_dostealth.lastStealth = Now()
end

c_acceptquest = inheritsFrom( ml_cause )
e_acceptquest = inheritsFrom( ml_effect )
function c_acceptquest:evaluate()
	if (gBotMode == GetString("assistMode") and not gQuestHelpers) then
		return false
	end
	return IsControlOpen("JournalAccept")
end
function e_acceptquest:execute()
	UseControlAction("JournalAccept","Accept",0)
	ml_global_information.Await(2000, function () return not IsControlOpen("JournalAccept") end)
end

c_handoverquest = inheritsFrom( ml_cause )
e_handoverquest = inheritsFrom( ml_effect )
function c_handoverquest:evaluate()
	if (gBotMode == GetString("assistMode") and not gQuestHelpers) then
		return false
	end
	return IsControlOpen("Request")
end
function e_handoverquest:execute()
	local inventories = {0,1,2,3,2004}
	for _,invid in pairs(inventories) do
		local bag = Inventory:Get(invid)
		if (table.valid(bag)) then
			local ilist = bag:GetList()
			if (table.valid(ilist)) then
				for slot, item in pairs(ilist) do 
					local result = item:HandOver()
					if (result and (result == 1 or result == true or result == 65536)) then
						ml_global_information.Await(math.random(800,1200))
						return
					end
				end	
			end
		end
	end
	
	if (UseControlAction("Request","HandOver",1)) then
		ml_global_information.Await(math.random(1200,2000))
	end
end

c_completequest = inheritsFrom( ml_cause )
e_completequest = inheritsFrom( ml_effect )
function c_completequest:evaluate()
	if (gBotMode == GetString("assistMode") and not gQuestHelpers) then
		return false
	end
	if (IsControlOpen("JournalResult")) then
		return true
	end	
	return false
end
function e_completequest:execute()
	local questid = IsNull(GetControlData("JournalResult","questid"),0)
	if (questid ~= 0) then
		local hasReward = AceLib.API.Quest.HasReward(questid)
		if (not hasReward) then
			d("Quest has no reward indicated, use basic accept.",1)
			ml_global_information.Await(math.random(1500,2500),
				function () UseControlAction("JournalResult","Complete") end,
				ml_global_information.Await(1000, 10000, function () return not HasQuest(questid) end)
			)
		end
	else
		d("Invalid quest id was passed.",1)
	end
end

c_teleporttopos = inheritsFrom( ml_cause )
e_teleporttopos = inheritsFrom( ml_effect )
c_teleporttopos.pos = 0
e_teleporttopos.teleCooldown = 0
function c_teleporttopos:evaluate()
	if (Now() < e_teleporttopos.teleCooldown or not gTeleportHack or IsFlying()) then
		return false
	end
	
	local useTeleport = ml_task_hub:CurrentTask().useTeleport
	if (MIsCasting() or MIsLocked() or MIsLoading() or IsMounting() or 
		IsControlOpen("SelectString") or IsControlOpen("SelectIconString") or IsShopWindowOpen() or
		not table.valid(ml_task_hub:CurrentTask().pos) or not useTeleport) 
	then
		return false
	end
	
	local myPos = Player.pos
	local gotoPos = ml_task_hub:CurrentTask().pos
	
	if (not table.valid(gotoPos) or c_rest:evaluate() or not ShouldTeleport(gotoPos)) then
		return false
	end
	 
	local distance = PDistance3D(myPos.x, myPos.y, myPos.z, gotoPos.x, gotoPos.y, gotoPos.z)
	if (distance > 10) then
		local properPos = nil
		if (ml_task_hub:CurrentTask().gatePos) then
			properPos = ml_task_hub:CurrentTask().pos
		else
			properPos = ml_task_hub:CurrentTask().pos
			local p = FindClosestMesh(properPos,10,false)
			if (p) then
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
		
        Hacks:TeleportToXYZ(tonumber(gotoPos.x),tonumber(gotoPos.y),tonumber(gotoPos.z),true)
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
	if (Busy() or ((not gAutoEquip or Now() < c_autoequip.postpone) and gForceAutoEquip == false) or Player.incombat or Now() < (ml_global_information.lastEquip + (1000 * 60 * 5))) then
		return false
	end
	
	-- Check to see if we can get valid data from the game, if not, skip it.
	local weapon = GetItemBySlot(1,1000)
	if (not weapon and IsNull(weapon.name,"") == "") then
		if (gBotMode ~= GetString("assistMode")) then
			ml_global_information.Await(1000, function () return GetItemBySlot(1,1000) ~= nil end)
			return true
		else
			return false
		end		
	end
	
	e_autoequip.item = nil
	e_autoequip.bag = nil
	e_autoequip.slot = nil
	
	local doPostpone = true
	
	if (table.valid(ffxiv_task_quest.lockedSlots)) then
		for slot,questid in pairs(ffxiv_task_quest.lockedSlots) do
			if (Quest:IsQuestCompleted(questid)) then
				ffxiv_task_quest.lockedSlots[slot] = nil
			end
		end
	end
	
	local applicableSlots = {
		[0] = true,
		--[1] = true,
		--[2] = true,
		--[3] = true,
		--[4] = true,
		--[5] = true,
		--[6] = true,
		--[7] = true,
		--[8] = true,
		--[9] = true,
		--[10] = true,
		--[11] = true,
		[12] = true,
	}
	
	for slot,data in pairs(applicableSlots) do
		if (ffxiv_task_quest.lockedSlots[slot]) then
			--d("isarmoryfull:"..tostring(IsArmoryFull(slot)).." for slot ["..tostring(slot).."] is true")
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
		local equipped = Inventory:Get(1000)
		if (table.valid(equipped)) then
			local ilist = equipped:GetList()
			if (table.valid(ilist)) then
				for _,item in pairs(ilist) do
					local found = false
					if (item.slot == slot and item.id ~= 0) then
						found = true
						data.equippedValue = AceLib.API.Items.GetItemStatWeight(item,slot)
						data.equippedItem = item
						
						if (table.valid(item)) then
							ml_debug("Slot ["..tostring(slot).."] Equipped item ["..tostring(item.name).." ]["..tostring(item.hqid).."] has a value of :"..tostring(data.equippedValue))
						end
					end
					if (found) then
						break
					end
				end
			end
		end
		
		if (slot == 0) then
			data.unequippedItem,data.unequippedValue = AceLib.API.Items.FindWeaponUpgrade()
			if (IsNull(data.unequippedItem,0) ~= 0) then
				ml_debug("Slot ["..tostring(slot).."] Best upgrade item ["..tostring(data.unequippedItem.name).."] has a value of :"..tostring(data.unequippedValue))
			end
		--elseif (slot == 1) then
			--if (AceLib.API.Items.IsShieldEligible()) then
				--data.unequippedItem,data.unequippedValue = AceLib.API.Items.FindShieldUpgrade()
				--if (IsNull(data.unequippedItem,0) ~= 0) then
					--ml_debug("Slot ["..tostring(slot).."] Best upgrade item ["..tostring(data.unequippedItem.name).."] has a value of :"..tostring(data.unequippedValue))
				--end
			--end
		else
			data.unequippedItem,data.unequippedValue = AceLib.API.Items.FindArmorUpgrade(slot)
			if (IsNull(data.unequippedItem,0) ~= 0) then
				ml_debug("Slot ["..tostring(slot).."] Best upgrade item ["..tostring(data.unequippedItem.name).."] has a value of :"..tostring(data.unequippedValue))
			end
		end
	end
	
	for slot,data in pairsByKeys(applicableSlots) do		
		if (IsNull(data.unequippedItem,0) ~= 0 and ((data.unequippedValue > data.equippedValue) or (data.equippedItem == 0))) then
			--[[
			if (ArmoryItemCount(slot) == 25 and (data.unequippedItem.bag >= 0 and data.unequippedItem.bag <= 3)) then
				ml_debug("Armoury slots for ["..tostring(slot).."] are full, attempting to rearrange inventory.")
				
				local firstBag,firstSlot = GetFirstFreeInventorySlot()
				if (firstBag ~= nil) then
					if (slot == 0) then
						local downgrades = AceLib.API.Items.FindWeaponDowngrades()
						if (table.valid(downgrades)) then
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
						if (table.valid(downgrades)) then
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
						if (table.valid(downgrades)) then
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
			--]]
			
			d("Try to equip item ["..tostring(data.unequippedItem.hqid).."]")
			
			e_autoequip.item = data.unequippedItem
			e_autoequip.bag = 1000
			e_autoequip.slot = slot
			return true
		else
			--d("Prevented equipping item into slot ["..tostring(slot).."].")
		end
	end
	
	if (doPostpone) then
		c_autoequip.postpone = Now() + 30000
	end
	
	return false
end
function e_autoequip:execute()
	local item = e_autoequip.item
	if (table.valid(item)) then
		local itemid = item.hqid
		d("Moving item ["..tostring(itemid).."] to bag "..tostring(e_autoequip.bag)..", slot "..tostring(e_autoequip.slot))
		item:Move(e_autoequip.bag,e_autoequip.slot)
		ml_global_information.Await(500, 2000, function () return IsEquipped(itemid) end)
	else
		ml_global_information.Await(1000)
	end
end

c_recommendequip = inheritsFrom( ml_cause )
e_recommendequip = inheritsFrom( ml_effect )
e_recommendequip.lastEquip = {}
function c_recommendequip:evaluate()
	if (not gAutoEquip or Busy() or Player.incombat or not IsNormalMap(Player.localmapid)) then
		return false
	end	
	
	if (Now() < (ml_global_information.lastEquip + (1000 * 60 * 5))) then
		ml_debug("[RecommendEquip]: Last equip was too soon ["..tostring(TimeSince(ml_global_information.lastEquip)).."]")
		return false
	end
	
	-- Don't equip if we've already done it for this level.
	-- Questing will automatically reset this as necessary if we receive gear.
	if (table.valid(e_recommendequip.lastEquip)) then
		if (e_recommendequip.lastEquip[Player.job] and e_recommendequip.lastEquip[Player.job] >= Player.level) then
			return false
		end	
	end
	
	if (gBotMode == GetString("questMode")) then
		ml_debug("[RecommendEquip]: Checking quest version ["..tostring(gQuestAutoEquip).."] or ["..tostring(gForceAutoEquip).."]")
		return (gQuestAutoEquip or gForceAutoEquip)
	else
		ml_debug("[RecommendEquip]: Checking non-quest version ["..tostring(gAutoEquip).."] or ["..tostring(gForceAutoEquip).."]")
		return (gAutoEquip or gForceAutoEquip)
	end
	
	return false
end
function e_recommendequip:execute()
	if (not IsControlOpen("Character")) then
		ActionList:Get(10,2):Cast()
		ml_global_information.Await(1000, 2000, function () return IsControlOpen("Character") end)
		ml_debug("[RecommendEquip]: Opened character panel.")
	else
		if (not IsControlOpen("RecommendEquip")) then
			UseControlAction("Character","OpenRecommendEquip")
			ml_global_information.Await(1500, 3000, function () return IsControlOpen("RecommendEquip") end)
			ml_debug("[RecommendEquip]: Open Recommended Equipment panel.")
		else
			if (UseControlAction("RecommendEquip","Equip")) then
				ml_global_information.yield = { 
					mintimer = 0,
					maxtimer = Now() + 1000,
					followall = function () 
						ActionList:Get(10,2):Cast()
						ml_global_information.lastEquip = Now()
						e_recommendequip.lastEquip = { [Player.job] = Player.level }
					end
				}
				ml_debug("[RecommendEquip]: Equipping recommended gear, setting last use timer.")
			end
		end
	end

	SetThisTaskProperty("preserveSubtasks",true)
end

c_selectconvindex = inheritsFrom( ml_cause )
e_selectconvindex = inheritsFrom( ml_effect )
c_selectconvindex.unexpected = 0
c_selectconvindex.reset = 0
c_selectconvindex.lastmenu = ""
c_selectconvindex.selected = 0
function c_selectconvindex:evaluate()	
	if (c_selectconvindex.unexpected > 5) then
		c_selectconvindex.unexpected = 0
	end
	if (TimeSince(c_selectconvindex.reset) > 10000) then
		c_selectconvindex.reset = 0
		c_selectconvindex.lastmenu = ""
		ml_task_hub:CurrentTask().checked = {}
	end
	return (IsControlOpen("SelectIconString") or IsControlOpen("SelectString"))
end
function e_selectconvindex:execute()	
	local conversationstrings = IsNull(ml_task_hub:CurrentTask().conversationstrings,{})
	local checkedIndexes = IsNull(ml_task_hub:CurrentTask().checked,{})
	
	if (table.valid(conversationstrings)) then
		local convoList = GetConversationList()
		if (table.valid(convoList)) then
			if c_selectconvindex.lastmenu ~= "" then
				if convoList[1] ~= c_selectconvindex.lastmenu then
					checkedIndexes[c_selectconvindex.selected] = true
				end
			end
			c_selectconvindex.lastmenu = convoList[1]
			for k,v in pairs(conversationstrings) do
				for selectindex,convo in pairs(convoList) do
					if not (checkedIndexes[k]) then
						local cleanedv = CleanConvoLine(v)
						local cleanedline = CleanConvoLine(convo)						
						if (string.contains(cleanedline,cleanedv)) then
							d("Use conversation line ["..tostring(convo).."]")
							SelectConversationLine(selectindex)
							ml_global_information.Await(2000, function () return not (table.valid(GetConversationList())) end)
							c_selectconvindex.selected = k
							return false
						end
					end
				end
			end
		end
	else
		local index = ml_task_hub:CurrentTask().conversationIndex
		if (not index) then
			c_selectconvindex.unexpected = c_selectconvindex.unexpected + 1
			index = c_selectconvindex.unexpected
		end
		SelectConversationIndex(tonumber(index))
		ml_global_information.Await(2000, function () return not (table.valid(GetConversationList())) end)
	end	
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
	
	if (FFXIV_Common_BotRunning) then
		ffxiv_dialog_manager.IssueStopNotice("Inventory","Inventory is full, bot will stop.")
	end
end

c_falling = inheritsFrom( ml_cause )
e_falling = inheritsFrom( ml_effect )
c_falling.jumpKillTimer = 0
c_falling.lastMeasure = 0
function c_falling:evaluate()
	local myPos = Player.pos
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
	ml_global_information.Await(10000, function () return (not Player:IsJumping() or not Player.alive) end)
	c_falling.jumpKillTimer = 0
end

c_clearaggressive = inheritsFrom( ml_cause )
e_clearaggressive = inheritsFrom( ml_effect )
c_clearaggressive.targetid = 0
c_clearaggressive.timer = 0
function c_clearaggressive:evaluate()
	if (MIsCasting() or MIsLocked() or MIsLoading() or IsControlOpen("SelectYesno") or IsControlOpen("SelectString") or IsControlOpen("SelectIconString")) then
		return false
	end
	
	if (Now() < c_clearaggressive.timer) then
		return false
	end
	
	--Reset the tempvar.
	c_clearaggressive.targetid = 0
	
	local clearAggressive = ml_task_hub:CurrentTask().clearAggressive or false
	if (clearAggressive) then
		local ppos = Player.pos
		local id = ml_task_hub:CurrentTask().targetid or 0
		if (id > 0) then
			local el = EntityList("shortestpath,targetable,contentid="..tostring(id))
			if (el) then
				local i,entity = next(el)
				if (i and entity) then
					local epos = entity.pos
					c_clearaggressive.timer = Now() + 5000
					local aggroChecks = GetAggroDetectionPoints(ppos,epos)
					if (table.valid(aggroChecks)) then
						for k,navPos in pairsByKeys(aggroChecks) do
							local aggressives = EntityList("aggressive,alive,attackable,targeting=0,minlevel="..tostring(Player.level - 10)..",exclude_contentid="..tostring(id))
							if (table.valid(aggressives)) then
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
			if (table.valid(aggroChecks)) then
				for k,navPos in pairsByKeys(aggroChecks) do
					local aggressives = nil
					if (gBotMode == "NavTest") then
						local aggressives = EntityList("aggressive,alive,attackable,targeting=0")
					else
						local aggressives = EntityList("aggressive,alive,attackable,targeting=0,minlevel="..tostring(Player.level - 10))
					end
					if (table.valid(aggressives)) then
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
	return IsControlOpen("SelectYesno")
end
function e_mapyesno:execute()
	PressYesNo(true)
	SetThisTaskProperty("preserveSubtasks",true)
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
	if (Busy()) then
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
	if (ml_task_hub:CurrentTask().aethid) then
		task.aethid = ml_task_hub:CurrentTask().aethid
	end
	if (table.valid(ml_task_hub:CurrentTask().pos)) then
		task.pos = ml_task_hub:CurrentTask().pos
	end
	ml_task_hub:CurrentTask():AddSubTask(task)
end

c_buy = inheritsFrom( ml_cause )
e_buy = inheritsFrom( ml_effect )
c_buy.failedAttempts = 0
function c_buy:evaluate()
	if (IsControlOpen("SelectYesno")) then
		UseControlAction("SelectYesno","CheckAccept")
		UseControlAction("SelectYesno","Yes")
		ml_global_information.Await(1500, function () return not IsControlOpen("SelectYesno") end)
		return true
	end
	
	if (IsControlOpen("SelectYesnoCount")) then
		UseControlAction("SelectYesnoCount","CheckAccept")
		UseControlAction("SelectYesnoCount","Yes")
		ml_global_information.Await(1000, function () return not IsControlOpen("SelectYesnoCount") end)
		return true
	end
	
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
		local buyamount = ml_task_hub:CurrentTask().buyamount or 1
		if (buyamount > 99) then
			buyamount = 99
		end
		
		d("Buying item ID ["..tostring(itemid).."].")
		local itemCount = ItemCount(itemid)
		Inventory:BuyShopItem(itemid,buyamount)
		ml_global_information.AwaitSuccess(2000, 
			function () 
				if (IsControlOpen("SelectYesno")) then
					PressYesNo(true)
					return true		
				end
			end
		)
	end
	
	return false
end
function e_buy:execute()
	--don't really need this
end

c_moveandinteract = inheritsFrom( ml_cause )
e_moveandinteract = inheritsFrom( ml_effect )
c_moveandinteract.entityid = 0
function c_moveandinteract:evaluate()
	if (Busy())	then
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
	newTask.contentid = ml_task_hub:CurrentTask().id
	newTask.pos = ml_task_hub:CurrentTask().pos
	
	if (gTeleportHack) then
		newTask.useTeleport = true
	end
	
	ml_task_hub:ThisTask():AddSubTask(newTask)
end

c_switchclass = inheritsFrom( ml_cause )
e_switchclass = inheritsFrom( ml_effect )
e_switchclass.weapon = nil
e_switchclass.blockOnly = false
function c_switchclass:evaluate()	
	e_switchclass.weapon = nil
	e_switchclass.blockOnly = false
	
	local class = ml_task_hub:CurrentTask().class
	if (Player.job ~= class) then
		if (Busy() or Player.incombat) then
			return false
		end
		
		local override = ml_task_hub:CurrentTask().override
		local gsvar = "gGearset"..tostring(class)
		local searchList = Player:GetGearSetList()
		local newSet = _G[gsvar]
		
		if table.valid(searchList) then
			if (In(tonumber(newSet),0) or (tonumber(newSet) ~= 0 and (not string.contains(searchList[tonumber(newSet)].name,ffxivminion.classes[class])))) then
				if ffxivminion.classes[class] then
					for i,e in spairs(searchList) do
						if (string.contains(e.name,ffxivminion.classes[class])) then
							newSet = i
						end
					end
				end
			end
		end
		
		if (override ~= 0) then
			local commandString = "/gs change "..tostring(override)
			SendTextCommand(commandString)
			ml_global_information.Await(3000, function () return (Player.job == class) end)
			e_switchclass.blockOnly = true
			return true
		elseif (tonumber(newSet) ~= 0) then
			local commandString = "/gs change "..tostring(newSet)
			SendTextCommand(commandString)
			ml_global_information.Await(3000, function () return (Player.job == class) end)
			e_switchclass.blockOnly = true
			return true
		else
			local canSwitch,bestWeapon = CanSwitchToClass(class)
			if (canSwitch) then
				if (bestWeapon) then
					e_switchclass.weapon = bestWeapon
					return true
				end
			end	
		end
	end
	return false
end
function e_switchclass:execute()
	if (e_switchclass.blockOnly) then
		return false
	end
	
	local job = Player.job
	local weapon = e_switchclass.weapon
	if (weapon) then
		local weaponid = weapon.hqid
		weapon:Move(1000,0)
		ml_global_information.Await(1000, 3000, function () return Player.job ~= job end)
		ml_global_information.lastEquip = 0
	end
end

c_skiptalk = inheritsFrom( ml_cause )
e_skiptalk = inheritsFrom( ml_effect )
function c_skiptalk:evaluate()
	if (gSkipTalk and (FFXIV_Common_BotRunning or not gSkipTalkRunningOnly)) then
		if IsControlOpen("Talk") then
			UseControlAction("Talk","Click")
			if (not IsControlOpen("SelectIconString") and not IsControlOpen("SelectString") and not IsControlOpen("Request")) then
				ml_global_information.Await(250)
			end
			return true
		end
	end

	return false
end
function e_skiptalk:execute()
	SetThisTaskProperty("preserveSubtasks",true)
end

c_skipcutscene = inheritsFrom( ml_cause )
e_skipcutscene = inheritsFrom( ml_effect )
c_skipcutscene.lastSkip = 0
function c_skipcutscene:evaluate()
	if (gSkipCutscene and FFXIV_Common_BotRunning and not IsControlOpen("Snipe") and not IsControlOpen("JournalResult") and TimeSince(c_skipcutscene.lastSkip) > 3000) then
		local totalUI = 0
		for i=0,165 do
			if (GetUIPermission(i) == 1) then
				totalUI = totalUI + i
			end
		end
		
		if (In(totalUI,4647,4115,4515,4725,5701,3451,2628,2626,2893,3506,3909,4526,4809,4677) and not IsControlOpen("NowLoading")) then
			if (IsControlOpen("SelectString") or IsControlOpen("SelectIconString") or IsControlOpen("CutSceneSelectString")) then
				local convoList = GetConversationList()
				if (table.valid(convoList)) then
					SelectConversationIndex(1)
				end
			else
				PressKey(27)
				--KeyDown(27)
				--ml_global_information.Await(250,function () KeyUp(27) end)
			end
			return true
		end
	end

	return false
end
function e_skipcutscene:execute()
	c_skipcutscene.lastSkip = Now()
	SetThisTaskProperty("preserveSubtasks",true)
end

c_dointeract = inheritsFrom( ml_cause )
e_dointeract = inheritsFrom( ml_effect )
c_dointeract.blockExecution = false
c_dointeract.lastInteract = 0
function c_dointeract:evaluate()
	local myTarget = MGetTarget()
	local ppos = Player.pos
	
	if (IsControlOpen("HousingSelectBlock")) then
		UseControlAction("HousingSelectBlock","Travel",math.random(1,10))
		ml_task_hub:CurrentTask().initiatedPos = Player.pos
		ml_global_information.Await(1000, 3000, 
			function () 
				return IsControlOpen("SelectYesno") 
			end, 
			function () 
				ml_global_information.AwaitDo(1000, 3000, 
					function () return MIsLoading() end, 
					function () UseControlAction("SelectYesno","Yes") end)
			end)
		return true
	end
	
	-- Scan for our wanted contentid to get as much data as we can, for better decisions.
	local interactable = nil
	if (ml_task_hub:CurrentTask().lastInteractableSearch == nil) then
		ml_task_hub:CurrentTask().lastInteractableSearch = 0
	end
	if (ml_task_hub:CurrentTask().interact == 0 and TimeSince(ml_task_hub:CurrentTask().lastInteractableSearch) > 500) then
		if (IsNull(ml_task_hub:CurrentTask().contentid,0) ~= 0) then
			ml_debug("[DoInteract]: Looking for contentid ["..tostring(ml_task_hub:CurrentTask().contentid).."]",3)
			local nearestInteract = GetInteractableEntity(ml_task_hub:CurrentTask().contentid)
			if (nearestInteract) then
				ml_task_hub:CurrentTask().interact = nearestInteract.id
			else
				ml_debug("[DoInteract]: Didn't find any matching entities.",3)
			end
			ml_task_hub:CurrentTask().lastInteractableSearch = Now()
		end
		
		if (math.distance2d(Player.pos,ml_task_hub:CurrentTask().pos) < 3 and math.distance3d(Player.pos,ml_task_hub:CurrentTask().pos) < 4) then
			local nearestInteract = GetInteractableEntity()
			if (nearestInteract) then
				ml_task_hub:CurrentTask().interact = nearestInteract.id
			end
			ml_task_hub:CurrentTask().lastInteractableSearch = Now()
		end
	end
	
	-- Get the actual entity, to work with.
	if (ml_task_hub:CurrentTask().interact ~= 0) then
		interactable = EntityList:Get(ml_task_hub:CurrentTask().interact)
	end
	
	-- Set our target, if we are within a reasonable range.
	
	if (interactable) then
		if (ml_task_hub:CurrentTask().useTargetPos) then
			ml_task_hub:CurrentTask().pos = interactable.pos
		elseif (not ml_task_hub:CurrentTask().useProfilePos) then
			if (interactable.meshpos and not IsFlying() and not IsDiving()) then
				if (not ml_task_hub:CurrentTask().pathChecked) then
					local meshpos = interactable.meshpos
					if (NavigationManager:IsReachable(meshpos)) then
						ml_task_hub:CurrentTask().pos = interactable.meshpos
					end
					ml_task_hub:CurrentTask().pathChecked = true
				end
			end
		end
	end
	
	if (interactable and interactable.targetable and interactable.distance2d < 30) then
		if (not myTarget or (myTarget and myTarget.id ~= interactable.id)) then
			Player:SetTarget(interactable.id)
		end
	end
	
	if (interactable) then
		local ipos = interactable.pos
		local ydiff = (ipos.y - ppos.y)
		local radius = (interactable.hitradius >= 2 and interactable.hitradius) or 2
		local defaults = {
			[0] = 2.5,
			[3] = 5.5,
			[7] = 2.1,
		}
		
		-- general rules so far:
		-- aetherytes (radius 2): distance2d of slightly less than 8
		-- npcs (radius 0.5) (type3): distance2d of 6
		-- gatherables (radius 0.5) (all so far) distance2d of 2.5
		-- npcs (radius 2) (type 7): distance2d of 2.1
		-- npcs (radius 0.5) (type 7): distance2d of 3.5

		--if (myTarget and myTarget.id == interactable.id and myTarget.interactable) then
		if (myTarget and myTarget.id == interactable.id) then
			
			if (table.valid(interactable) and ((not ml_task_hub:CurrentTask().interactRange3d) or (ml_task_hub:CurrentTask().interactRange3d and interactable.distance < ml_task_hub:CurrentTask().interactRange3d))) then		
				if (interactable.type == 5) then
					if ((ffxiv_map_nav.IsAetheryte(interactable.contentid) and interactable.distance2d <= 6 and ydiff <= 4.7 and ydiff >= -1.3) or  
						(not ffxiv_map_nav.IsAetheryte(interactable.contentid) and interactable.distance2d <= 4 and ydiff <= 3 and ydiff >= -1.2))
					then
						if (not IsFlying()) then
							if (not ml_task_hub:CurrentTask().ignoreAggro and c_killaggrotarget:evaluate()) then
								e_killaggrotarget:execute()
								return false
							end
				
							Player:SetFacing(interactable.pos.x,interactable.pos.y,interactable.pos.z)

							if (TimeSince(c_dointeract.lastInteract) > 2000 and Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1000, function () return not Player:IsMoving() end)
								return true
							end
							
							local convoList = GetConversationList()
							if (not table.valid(convoList) and not MIsLocked()) then
								d("["..ml_task_hub:CurrentTask().name.."]: Interacting with aetheryte target.")
								Player:Interact(interactable.id)
							end
							
							if (TimeSince(c_dointeract.lastInteract) > 2000) then
								ml_global_information.Await(1000)
								return true
							end
							
							if (ml_task_hub:CurrentTask().interactAttempts == nil) then
								ml_task_hub:CurrentTask().interactAttempts = 1
							else
								ml_task_hub:CurrentTask().interactAttempts = ml_task_hub:CurrentTask().interactAttempts + 1
							end
							c_dointeract.lastInteract = Now()
							return false
						else
							--Dismount()
							Descend()
							--ml_global_information.Queue(1000,Dismount)
							return true
						end
					end
				else
					local range = ((ml_task_hub:CurrentTask().interactRange and ml_task_hub:CurrentTask().interactRange >= 3) and ml_task_hub:CurrentTask().interactRange) or defaults[interactable.type] or radius
					if (not ml_task_hub:CurrentTask().interactRange and ml_task_hub:CurrentTask().interactRange3d and range > ml_task_hub:CurrentTask().interactRange3d) then
						range = ml_task_hub:CurrentTask().interactRange3d
					end
					if (interactable.cangather) then
						range = 2.5
					end
					
					--d("[DoInteract]: Required range :"..tostring(range)..", Actual range:"..tostring(interactable.distance2d)..", IsEntityReachable:"..tostring(IsEntityReachable(interactable,range + 2)))
					
					if (interactable and IsEntityReachable(interactable,range + 2) and interactable.distance2d < range) then
						if (not IsFlying()) then
							if (not ml_task_hub:CurrentTask().ignoreAggro and c_killaggrotarget:evaluate()) then
								e_killaggrotarget:execute()
								return false
							end
				
							
							Player:SetFacing(interactable.pos.x,interactable.pos.y,interactable.pos.z)
							
							-- Special handler for gathering.  Need to wait on GP before interacting sometimes.
							if not ml_task_hub:CurrentTask().touchOnly and (IsNull(ml_task_hub:CurrentTask().minGP,0) > Player.gp.current and Player.gp.current < Player.gp.max) then
								d("["..ml_task_hub:CurrentTask().name.."]: Waiting on GP before attempting node.")
								Player:Stop()
								return true
							end
							
							if (IsGatherer(Player.job) and interactable.contentid > 4 and table.size(EntityList.aggro) > 0) then
								d("["..ml_task_hub:CurrentTask().name.."]: Don't attempt a special node if we gained aggro.")
								return false
							end
							
							--d("["..ml_task_hub:CurrentTask().name.."]: Interacting with target type ["..tostring(interactable.type).."].")
							Player:Interact(interactable.id)
							if (ml_task_hub:CurrentTask().interactAttempts == nil) then
								ml_task_hub:CurrentTask().interactAttempts = 1
							else
								ml_task_hub:CurrentTask().interactAttempts = ml_task_hub:CurrentTask().interactAttempts + 1
							end
							return false
						else
							--Dismount()
							Descend()
							--ml_global_information.Queue(1000,Dismount)
							return true
						end
					end
				end
			end
		end
	end
	
	if (interactable and interactable.los and interactable.distance2d < 15 and IsDiving()) then
		local tpos = interactable.pos
		local gotoPos = ml_task_hub:CurrentTask().pos
		if (table.valid(tpos) and table.valid(gotoPos)) then
			local dist3d = math.distance3d(gotoPos,tpos)
			if (dist3d < 3) then
				MoveDirectly3D(tpos)
				return true
			end
		end
	end				
	
	return false
end
function e_dointeract:execute()
end

c_classexchange = inheritsFrom( ml_cause )
e_classexchange = inheritsFrom( ml_effect )
c_classexchange.Item = 0
c_classexchange.count = 0
c_classexchange.set = false
c_classexchange.time = 0
c_classexchange.npcids = {
	[8] = 1028326,
	[9] = 1027233,
	[10] = 1027233,
	[11] = 1027233,
	[12] = 1028326,
	[13] = 1028326,
	[14] = 1027235,
	[15] = 1027235,
	[16] = 1027236,
	[17] = 1027236,
	[18] = 1027237,
}
function c_classexchange:evaluate()

	if (IsControlOpen("HelpWindow")) then
		UseControlAction("HelpWindow","Close")
		return
	end
	if TimeSince(c_classexchange.time) < 1000 then
		return 
	end
	local uuid = GetUUID()
	local npcid = c_classexchange.npcids[Player.job]	
	
	if (IsControlOpen("HugeCraftworksSupply")) then
	local doTurnin = true
		local data = GetControlData("HugeCraftworksSupply")
		
		local turninCount = data.neededamount 
		local itemID = data.itemid
		local esteemLevel = data.esteemlevel
		local currentEsteem = data.esteem
		local deliverReady = data.slotsfilled > 0
		
		if Settings.FFXIVMINION.classturnins == nil then 
			Settings.FFXIVMINION.classturnins = {} 
		end
		if Settings.FFXIVMINION.classturnins[uuid] == nil then 
			Settings.FFXIVMINION.classturnins[uuid] = {} 
		end
		if Settings.FFXIVMINION.classturnins[uuid][npcid] == nil then 
			Settings.FFXIVMINION.classturnins[uuid][npcid] = {} 
		end
		if Settings.FFXIVMINION.classturnins[uuid][npcid][esteemLevel] == nil then 
			Settings.FFXIVMINION.classturnins[uuid][npcid][esteemLevel] = {} 
			doTurnin = false
		end
		
		Settings.FFXIVMINION.classturnins[uuid][npcid][esteemLevel] = {yeild = data.neededamount, esteem = currentEsteem}
		Settings.FFXIVMINION.classturnins = Settings.FFXIVMINION.classturnins
			
			
		local currentCount = (ItemCount(itemID + 1000000))
		local item, itemAction = GetItem(itemID + 1000000)
		if (not item or (currentCount < turninCount)) then
			item, itemAction = GetItem(itemID)
			currentCount = ItemCount(itemID,false)
		end			
		if not c_classexchange.set then
			if (IsControlOpen("InputNumeric")) then
				UseControlAction("InputNumeric","EnterAmount",currentCount)
				c_classexchange.set = true
				c_classexchange.time = Now()
				ml_global_information.Await(1000)
				return
			end
			if item and (currentCount >= turninCount) then
				c_classexchange.count = currentCount
				item:HandOver()
				c_classexchange.time = Now()
				ml_global_information.Await(1000)
				return
			end
		end
		if (deliverReady or c_classexchange.set) and doTurnin then
			UseControlAction("HugeCraftworksSupply","Deliver")
			c_classexchange.set = false
			c_classexchange.time = Now()
			if Settings.FFXIVMINION.classturnins[uuid][npcid][esteemLevel] then
				Settings.FFXIVMINION.classturnins[uuid][npcid][esteemLevel].esteem = nil
				Settings.FFXIVMINION.classturnins[uuid][npcid][esteemLevel].complete = true
				Settings.FFXIVMINION.classturnins = Settings.FFXIVMINION.classturnins
			end
			ml_task_hub:CurrentTask().completed = true
			ml_global_information.Await(1000)
			return
		end
		
		UseControlAction("HugeCraftworksSupply","Close")
		c_classexchange.time = Now()
		ml_task_hub:CurrentTask().completed = true
	end	
	
	if (IsControlOpen("HugeCraftworksSupplyResult")) then
		d("Closing Result Window")
		UseControlAction("HugeCraftworksSupplyResult","Close")
	end
	
	if (IsControlOpen("JournalAccept")) then
		d("Accepting Quest")
		UseControlAction("JournalAccept","Accept")
		if Settings.FFXIVMINION.classturnins[uuid][npcid].esteemlevel then
			Settings.FFXIVMINION.classturnins[uuid][npcid].esteem = nil
			Settings.FFXIVMINION.classturnins[uuid][npcid].esteemlevel = nil
			Settings.FFXIVMINION.classturnins = Settings.FFXIVMINION.classturnins
		end
		ml_task_hub:CurrentTask().completed = true
	end
	return false
end
function e_classexchange:execute()
	if (IsControlOpen("HugeCraftworksSupply")) then
		d("delivering Window")
		UseControlAction("HugeCraftworksSupply","Deliver")
		ml_task_hub:CurrentTask().completed = true
	end
end

c_scripexchange = inheritsFrom( ml_cause )
e_scripexchange = inheritsFrom( ml_effect )
c_scripexchange.lastItem = 0
c_scripexchange.lastComplete = 0
c_scripexchange.lastSwitch = 0
c_scripexchange.lastOpen = 0
c_scripexchange.handoverComplete = false
function c_scripexchange:evaluate()
	if (IsControlOpen("SelectYesno") and Player.alive and TimeSince(c_scripexchange.lastComplete) < 5000) then
		if (not IsControlOpen("_NotificationParty")) then
			UseControlAction("SelectYesno","Yes")
			ml_global_information.Await(2000, function () return not IsControlOpen("SelectYesno") end)
			return
		end
	end	
	
	if (IsControlOpen("Request")) then
		if (c_scripexchange.handoverComplete) then
			d("[ScripExchange]: Completing handover process.")
			UseControlAction("Request","HandOver")
			c_scripexchange.handoverComplete = false
			c_scripexchange.lastComplete = Now()
			return true
		else
			local items = {}
			if gSOEFilterArmory then 
				items = GetItems({c_scripexchange.lastItem},{0,1,2,3,3200,3201,3202,3203,3204,3205,3206,3207,3208,3209,3300,3500})
			else
				items = GetItems({c_scripexchange.lastItem},{0,1,2,3})
			end
			
			if (table.valid(items)) then
				d("[ScripExchange]: Found ["..tostring(table.size(items)).."] possible items.")
				for i, itemdata in pairs(items) do
					if (itemdata) then
						local item = itemdata.item
						if (item) then
							local result = item:HandOver()
							d("[ScripExchange]: Handing over item ["..tostring(item.name).."], collectability ["..tostring(item.collectability).."], result ["..tostring(result).."].")
							if (result ~= nil and (result == 1 or result == true or result == 65536 or result == 10)) then
								c_scripexchange.handoverComplete = true
								return true
							end
						end
					end
				end
			else
				d("[ScripExchange]: Couldn't find item ["..tostring(c_scripexchange.lastItem).."]")
			end
		end
		return false
	end
	
	c_scripexchange.lastItem = 0
	c_scripexchange.handoverComplete = false
	local addonName = "MasterPieceSupply"
	local addonCatagory = "SelectCategory"
	local addonComplete = "CompleteDelivery"
	if (not IsControlOpen(addonName)) then
		return false
	else
		if (not ml_task_hub:CurrentTask().loaded) then
			ml_global_information.Await(1000)
			UseControlAction(addonName,addonCatagory,0)
			c_scripexchange.lastSwitch = Now() + 1000
			ml_task_hub:CurrentTask().loaded = true
		end
	end
	
	local currentCategory = GetControlData(addonName,"category")
	local currentItems = GetControlData(addonName,"items")
	local checkedCategories = IsNull(ml_task_hub:CurrentTask().categories,{0,1,2,3,4,5,6,7,8,9,10})
	local currentCheck = 0
	for i = 0,10 do
		if (checkedCategories[i] ~= true) then
			currentCheck = i
			break
		end
	end
	
	if (currentCategory ~= currentCheck) then
		d("[ScripExchange]: Switch to category ["..tostring(currentCheck).."]")
		UseControlAction(addonName,addonCatagory,currentCheck)
		c_scripexchange.lastSwitch = Now()
		return true
	else
		if (table.isa(currentItems)) then
			d("[ScripExchange]: Found items list for category ["..tostring(currentCategory).."].")
			for index,itemdata in pairs(currentItems) do
				--d("[ScripExchange]: Checking data for ["..tostring(itemdata.itemid).."].")
				
				local rewardcurrency, currentamount = AceLib.API.Items.GetExchangeRewardCurrency(itemdata.itemid, currentCategory)
				--[[
					expreward = 111750, isdeliverable = false, itemid = 520087, name = "Velodyna Grass Carp", ownedquantity = 0, requiredquantity = 1, scripreward = 18
				--]]
				if ((currentamount + itemdata.scripreward) <= 2000) then
					if (itemdata.ownedquantity >= itemdata.requiredquantity) then
						local originalQuantity = itemdata.ownedquantity
						c_scripexchange.lastItem = itemdata.itemid
						c_scripexchange.handoverComplete = false
						
						local completeret = UseControlAction(addonName,addonComplete,index-1)
						--d("[ScripExchange]: Attempting to turn in item at index ["..tostring(index).."].")
						return true
					else
						--d("[ScripExchange]: Owned quantity ["..tostring(itemdata.ownedquantity).."] < Required Quantity ["..tostring(itemdata.requiredquantity).."].")
					end
				else
					--d("[ScripExchange]: Max scrip count for this item is reached, do not turn in.")
				end
			end
			
			if (TimeSince(c_scripexchange.lastSwitch) > 500) then
				ml_task_hub:CurrentTask().categories[currentCheck] = true
			end
			return true
		end
	end
	
	return false
end
function e_scripexchange:execute()
	--don't really need this
end

c_exchange = inheritsFrom( ml_cause )
e_exchange = inheritsFrom( ml_effect )
c_exchange.lastItem = 0
c_exchange.lastComplete = 0
c_exchange.lastSwitch = 0
c_exchange.lastOpen = 0
c_exchange.attempts = 0
c_exchange.handoverComplete = false
function c_exchange:evaluate()
	if (IsControlOpen("SelectYesno") and Player.alive and TimeSince(c_exchange.lastComplete) < 5000) then
		if (not IsControlOpen("_NotificationParty")) then
			UseControlAction("SelectYesno","Yes")
			ml_global_information.Await(2000, function () return not IsControlOpen("SelectYesno") end)
			return
		end
	end	
	
	if (IsControlOpen("Request")) then
		if (c_exchange.handoverComplete) then
			d("[ScripExchange]: Completing handover process.")
			UseControlAction("Request","HandOver")
			c_exchange.handoverComplete = false
			c_exchange.lastComplete = Now()
			return true
		else
			local items = GetItems({c_exchange.lastItem},{0,1,2,3})
			
			if (table.valid(items)) then
				d("[ScripExchange]: Found ["..tostring(table.size(items)).."] possible items.")
				for i, itemdata in pairs(items) do
					if (itemdata) then
						local item = itemdata.item
						if (item) then
							local result = item:HandOver()
							d("[ScripExchange]: Handing over item ["..tostring(item.name).."], collectability ["..tostring(item.collectability).."], result ["..tostring(result).."].")
							if (result ~= nil and (result == 1 or result == true or result == 65536 or result == 10)) then
								c_exchange.handoverComplete = true
								c_exchange.attempts = 0
								return true
							end
						end
					end
				end
			else
				d("[ScripExchange]: Couldn't find item ["..tostring(c_exchange.lastItem).."]")
			end
		end
		return false
	end
	
	c_exchange.lastItem = 0
	c_exchange.handoverComplete = false
	local addonName = "HWDSupply"
	local addonCatagory = "SetTabIndex"
	local addonComplete = "SetIndex"
		
	if (not IsControlOpen(addonName)) then
		return false
	else
		if (not ml_task_hub:CurrentTask().loaded) then
			ml_global_information.Await(1000)
			UseControlAction(addonName,addonCatagory,0)
			c_exchange.lastSwitch = Now() + 1000
			ml_task_hub:CurrentTask().loaded = true
		end
	end
	local catagoryData = GetControlRawData("HWDSupply",30)
	local currentCategory = nil
	if catagoryData then
		currentCategory = catagoryData.value
	end
	local currentItems = AceLib.API.Items.BuildFirmamentExchangeList()
	local checkedCategories = IsNull(ml_task_hub:CurrentTask().categories,{0,1,2,3,4,5,6,7})
	local currentCheck = 0
	for i = 0,7 do
		if (checkedCategories[i] ~= true) then
			currentCheck = i
			break
		end
	end
	
	if (currentCategory ~= currentCheck) then
		d("[ScripExchange]: Switch to category ["..tostring(currentCheck).."]")
		UseControlAction(addonName,addonCatagory,currentCheck)
		c_exchange.lastSwitch = Now()
		return true
	else
		if (table.isa(currentItems)) then
			d("[ScripExchange]: Found items list for category ["..tostring(currentCategory).."].")
			for index,itemdata in pairs(currentItems[currentCategory + 8]) do
				
				local rewardcurrency, currentamount = AceLib.API.Items.GetExchangeRewardCurrency(itemdata.itemid, currentCategory)
				if ((currentamount + itemdata.reward) <= 10000) then
					
					local itemNumbers = GetControlRawData("HWDSupply",35 + (index * 14)).value
					if itemNumbers > 0 then
						--local originalQuantity = itemdata.ownedquantity
						c_exchange.lastItem = itemdata.itemid + 500000
						c_exchange.handoverComplete = false
						c_exchange.attempts = c_exchange.attempts + 1
						local completeret = UseControlAction(addonName,addonComplete,index-1)
						--d("[ScripExchange]: Attempting to turn in item at index ["..tostring(index).."].")
						return true
					else
						d("[ScripExchange]: Owned 0.")
					end
				else
					--d("[ScripExchange]: Max scrip count for this item is reached, do not turn in.")
				end
			end
			
			if (TimeSince(c_exchange.lastSwitch) > 500) then
				ml_task_hub:CurrentTask().categories[currentCheck] = true
			end
			return true
		end
	end
	
	return false
end
function e_exchange:execute()
end

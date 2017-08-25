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
	if ((ml_task_hub:CurrentTask().name == "LT_GRIND" or ml_task_hub:CurrentTask().name == "LT_PARTY" ) and gGrindDoFates and gGrindFatesOnly ) then
		if (ml_task_hub:CurrentTask().name == "LT_GRIND") then
			local aggro = GetNearestAggro()
			if table.valid(aggro) then
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
		if table.valid(aggro) then
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
    if (table.valid(target)) then
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
	if ((gBotMode == GetString("partyMode") and IsPartyLeader()) or IsPOTD(Player.localmapid)) then
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
    
    if (gGrindDoFates ) then
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
function c_avoid:evaluate()	
	if (not gAvoidAOE or tonumber(gAvoidHP) == 0 or tonumber(gAvoidHP) < Player.hp.percent or not Player.onmesh) then
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
	if (table.valid(el)) then
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
	if (table.valid(el)) then
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
	
	if (table.valid(newPos)) then
		local ppos = Player.pos
		local moveDist = PDistance3D(ppos.x,ppos.y,ppos.z,newPos.x,newPos.y,newPos.z)
		if (moveDist > 1.5) then
			if (table.valid(obstacle)) then
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
			SetThisTaskProperty("preserveSubtasks",true)
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
	if (MIsLocked() or MIsLoading() or IsControlOpen("SelectString") or IsControlOpen("SelectIconString") 
		or IsShopWindowOpen() or Player.ismounted or IsFlying() or IsTransporting() or not Player.incombat) 
	then
		return false
	end
	
	-- Reset tempvar.
	c_autopotion.item = nil
	
	if (Player.alive) then
		local potions = c_autopotion.potions
		if (tonumber(gPotionHP) > 0 and Player.hp.percent < tonumber(gPotionHP)) then
			for k,itempair in pairsByKeys(potions) do
				if (Player.level >= itempair.minlevel) then
					local item = GetItem(tonumber(itempair.item))
					if (item and item:IsReady(Player.id)) then
						c_autopotion.item = item
						return true
					end
					
					local hqitem = GetItem(tonumber(itempair.item) + 1000000)
					if (hqitem and hqitem:IsReady(Player.id)) then
						c_autopotion.item = hqitem
						return true
					end
				end
			end
		end
		
		local ethers = c_autopotion.ethers
		if (tonumber(gPotionMP) > 0 and Player.mp.percent < tonumber(gPotionMP)) then
			for k,itempair in pairsByKeys(ethers) do
				if (Player.level >= itempair.minlevel) then
					local item = GetItem(tonumber(itempair.item))
					if (item and item:IsReady(Player.id)) then
						c_autopotion.item = item
						return true
					end
					
					local hqitem = GetItem(tonumber(itempair.item) + 1000000)
					if (hqitem and hqitem:IsReady(Player.id)) then
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
	if (item) then
		item:Cast(Player.id)
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
						local cleanedline = string.gsub(convo,"[()-/]","")
						for k,v in pairs(conversationstrings) do
							local cleanedv = string.gsub(v,"[()-/]","")
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
	if (MIsLoading() or 
		CannotMove() or 
		MIsCasting() or
		Player.localmapid == 0) 
	then
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
	if (MIsLoading() or 
		CannotMove() or 
		MIsCasting() or GilCount() < 1500 or
		IsNull(ml_task_hub:ThisTask().destMapID,0) == 0 or
		IsNull(ml_task_hub:ThisTask().destMapID,0) == Player.localmapid) 
	then
		ml_debug("Cannot use teleport, position is locked, or we are casting, or our gil count is less than 1500.")
		return false
	end
	
	e_teleporttomap.aeth = nil
	
	local el = EntityList("alive,attackable,onmesh,aggro")
	if (table.valid(el)) then
		ml_debug("Cannot use teleport, we have aggro currently.")
		return false
	end
	
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
			d("Attempting to find aetheryte for mapid ["..tostring(destMapID).."].")
			local aeth = GetAetheryteByMapID(destMapID, ml_task_hub:ThisTask().pos)
			if (aeth) then
				d("using block 1")
				e_teleporttomap.aeth = aeth
				return true
			end
			
			local attunedAetherytes = GetAttunedAetheryteList()
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
function c_getmovementpath:evaluate()
	if (MIsLoading() and not ffnav.IsProcessing() and not ffnav.isascending) then
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
				local meshpos = FindClosestMesh(gotoPos)
				if (meshpos and meshpos.distance ~= 0 and meshpos.distance < 6) then
					ml_task_hub:CurrentTask().gatePos = meshpos
				end
			end
			
			local pathLength = 0
		
			-- Attempt to get a path that doesn't require cubes for stealth pathing.
			if (ml_global_information.needsStealth and not IsFlying() and not Player.incombat and not ml_task_hub:CurrentTask().alwaysMount) then
				--d("rebuild non-cube path")
				pathLength = Player:BuildPath(tonumber(gotoPos.x), tonumber(gotoPos.y), tonumber(gotoPos.z), nil, nil, nil, 1, true)
			end
			
			if (pathLength <= 0) then
				--d("rebuild cube path")
				pathLength = Player:BuildPath(tonumber(gotoPos.x), tonumber(gotoPos.y), tonumber(gotoPos.z), nil, true, nil, 1, false)
			end
			
			if (pathLength > 0 or ml_navigation:HasPath()) then
				ml_debug("[GetMovementPath]: Path length returned ["..tostring(pathLength).."]")
				return false
			end
		else
			d("no valid gotopos")
		end
	else
		d("didn't have a valid position")
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
	if (CannotMove() or
		MIsLoading() or
		Player:IsJumping() or 
		IsMounting() or
		IsControlOpen("SelectString") or IsControlOpen("SelectIconString") or 
		IsShopWindowOpen() or
		(MIsCasting() and not IsNull(ml_task_hub:CurrentTask().interruptCasting,false))) 
	then
		return false
	end
	
	if (ml_navigation:HasPath()) then
		if (ml_navigation:EnablePathing()) then
			d("[WalkToPos]: Pathing was started.")
		end
		return true
	else
		if (ml_navigation:DisablePathing()) then
			d("[WalkToPos]: Pathing was stopped.")
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
	if (CannotMove() or
		MIsLoading() or
		Player:IsJumping() or 
		IsMounting() or
		IsControlOpen("SelectString") or IsControlOpen("SelectIconString") or 
		IsShopWindowOpen() or
		(MIsCasting() and not IsNull(ml_task_hub:CurrentTask().interruptCasting,false))) 
	then
		return false
	end
	
	if (ml_navigation:HasPath()) then
		if (ml_navigation:EnablePathing()) then
			d("[WalkToEntity]: Pathing was started.")
		end
		return true
	else
		if (IsFlying()) then
			-- First make sure there is somewhere to land so we don't fly into deep space.
			local ppos = Player.pos
			local hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y,ppos.z,ppos.x,ppos.y-15,ppos.z)
			if (hit) then
			
				-- Basically just aim down and try to land.
				-- If this doesn't work we are probably SOL anyway.
				Player:SetPitch(1.377) 
				if (not Player:IsMoving()) then
					Player:Move(FFXIV.MOVEMENT.FORWARD)
					ffnav.Await(3000, function () return Player:IsMoving() end)
					return true
				end
				ffnav.Await(5000, function () return not IsFlying() end)
				return true
			else
				if (ml_navigation:DisablePathing()) then
					d("[WalkToEntity]: Pathing was stopped, while in flight, because no landing area was detected.")
				end
			end
		else
			if (ml_navigation:DisablePathing()) then
				d("[WalkToEntity]: Pathing was stopped.")
			end
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
function c_useaethernet:evaluate(mapid, pos)
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
		if (IsNull(ml_task_hub:CurrentTask().contentid,0) ~= nearestAethernet.id) then 
			d("best athernet for ["..tostring(destMapID).."] - ["..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z).."] is ["..tostring(bestAethernet.id))
			--d("current id:"..tostring(ml_task_hub:CurrentTask().contentid)..", new id:"..tostring(nearestAethernet.id))
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
			d("Use aethernet task to go from ["..tostring(e_useaethernet.nearest.id).."] to ["..tostring(e_useaethernet.destination.id).."]")
			local newTask = ffxiv_task_moveaethernet.Create()
			newTask.contentid = e_useaethernet.nearest.id
			newTask.pos = e_useaethernet.nearest.pos
			newTask.conversationstrings = e_useaethernet.destination.conversationstrings
			newTask.useAethernet = true
			
			ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
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
		if (IsNull(ml_task_hub:CurrentTask().contentid,0) ~= nearestAethernet.id) then 
			--d("current id:"..tostring(ml_task_hub:CurrentTask().contentid)..", new id:"..tostring(nearestAethernet.id))
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
	if (MIsLocked() or MIsLoading() or IsControlOpen("SelectString") or IsControlOpen("SelectIconString") 
		or IsShopWindowOpen() or IsFlying() or IsTransporting() or ml_global_information.canStealth or IsSwimming() or IsDiving()) 
	then
		return false
	end
	
	local myPos = Player.pos
	local gotoPos = ml_task_hub:CurrentTask().pos
	if (table.valid(gotoPos)) then
		local dist3d = math.distance3d(myPos, gotoPos)
		local dismountDistance = IsNull(ml_task_hub:CurrentTask().dismountDistance,5)
		if (not ml_task_hub:CurrentTask().remainMounted and dismountDistance > 0 and dist3d <= dismountDistance) then
			if (ml_task_hub:CurrentTask().dismountTimer == nil) then
				ml_task_hub:CurrentTask().dismountTimer = 0
			end
			if (not IsFlying() and Player.ismounted and not IsDismounting() and Now() > ml_task_hub:CurrentTask().dismountTimer) then
				Dismount()
				ml_task_hub:CurrentTask().dismountTimer = Now() + 500
				return true
			end
			return false
		end
	end
	
	if (Player.ismounted or Player.incombat) then
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
function e_mount:execute()
	if (Player:IsMoving()) then
		Player:PauseMovement()
		ml_global_information.Await(1500, function () return not Player:IsMoving() end)
		return
	end
	
	if (IsMounting() or UsingBattleItem()) then
		--d("Adding a wait.")
		if (CanFlyInZone()) then
			ml_global_information.Await(2000)
		end
		return
	end
	
    if (Mount(e_mount.id)) then
		ml_global_information.Await(5000, function () return Player.ismounted end)
	end
	
	--ml_global_information.Await(500)
	--c_mount.reattempt = Now() + 10000
	--local ppos = Player.pos
	--c_mount.attemptPos = { x = round(ppos.x,1), y = round(ppos.y,1), z = round(ppos.z,1) }
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
    if (ffxiv_task_quest.noCompanion == true or gBotMode == GetString("pvpMode") or 
		Player.ismounted or IsMounting() or IsDismounting() or
		IsCompanionSummoned() or InInstance() or Player.castinginfo.lastcastid == 851) 
	then
        return false
    end

    if ((gChocoGrind and (gBotMode == GetString("grindMode") or gBotMode == GetString("partyMode"))) or
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
		ml_global_information.Await(5000, function () return Player.castinginfo.castingid == 851 end)
	end
end

c_stance = inheritsFrom( ml_cause )
e_stance = inheritsFrom( ml_effect )
function c_stance:evaluate()
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
	
	if (InInstance()) then
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
	
	if (( tonumber(gRestHP) > 0 and Player.hp.percent < tonumber(gRestHP)) or
		(( tonumber(gRestMP) > 0 and Player.mp.percent < tonumber(gRestMP)) and not isDOL and not isDOH))
	then
		if (Player.incombat or not Player.alive) then
			--d("Cannot rest, still in combat or not alive.")
			return false
		end
		
		local aggrolist = EntityList("alive,aggro")
		if (table.valid(aggrolist)) then
			return false
		end
		
		-- don't rest if we have rest in fates disabled and we're in a fate or FatesOnly is enabled
		if (not gRestInFates) then
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
				local p = FindClosestMesh(newPos)
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
	if (MIsLoading() or MIsLocked() or MIsCasting() or IsFlying() or Player.incombat) then
		return false
	end
	
	if ( gFood ~= "None") then
		if ( TimeSince(ml_global_information.foodCheckTimer) > 10000) then
			if (not IsControlOpen("Gathering") and not IsControlOpen("Synthesis") and not IsControlOpen("SynthesisSimple")) then
				if (ShouldEat()) then
					return true
				end
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
		if (UseControlAction("SelectYesno","Yes")) then
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
	if (Player.incombat or MIsCasting() or MIsLoading() or CannotMove() or IsControlOpen("Gathering")) then
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
	if (gTeleportHack) then
		newTask.useTeleport = true
	end
	
	if (markerType == GetString("miningMarker") or
		markerType == GetString("botanyMarker"))
	then
		newTask.stealthFunction = ffxiv_gather.NeedsStealth
	elseif (markerType == GetString("fishingMarker")) then
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

	local needsStealth = ml_global_information.needsStealth
	local hasStealth = HasBuff(Player.id,47)
	local nextnode = ml_navigation.path[ ml_navigation.pathindex ]
	if (needsStealth and nextnode and string.contains(nextnode.type,"CUBE")) then
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
			c_dostealth.dropStealth = true
			return true
		end
	end
	
	return false
end
function e_dostealth:execute()
	ml_global_information.canStealth = ml_global_information.needsStealth
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
		if (hasReward) then
			local reward = AceLib.API.Quest.ChooseBestReward(questid)
			if (reward) then
				d("Quest reward index ["..tostring(reward).."] was chosen.",1)
				ml_global_information.Await(math.random(1500,2500),
					function () UseControlAction("JournalResult","Complete",reward) end,
					ml_global_information.Await(1000, 10000, function () return not HasQuest(questid) end)
				)
			else
				d("No best reward was returned, something went wrong.",1)
			end
		else
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
			local p = FindClosestMesh(properPos)
			if (p and p.distance ~= 0) then
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
	if (((not gAutoEquip or Now() < c_autoequip.postpone) and gForceAutoEquip == false) or 
		IsShopWindowOpen() or CannotMove() or MIsLoading() or 
		not Player.alive or Player.incombat or
		IsControlOpen("Gathering") or Player:GetFishingState() ~= 0 or Now() < (ml_global_information.lastEquip + (1000 * 60 * 5))) 
	then
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
function c_recommendequip:evaluate()
	if (IsShopWindowOpen() or CannotMove() or MIsLoading() or IsControlOpen("Talk") or
		not Player.alive or Player.incombat or IsControlOpen("Synthesis") or IsControlOpen("SynthesisSimple") or IsControlOpen("Gathering") or Player:GetFishingState() ~= 0)
	then
		return false
	end	
	
	if (Now() < (ml_global_information.lastEquip + (1000 * 60 * 5))) then
		ml_debug("[RecommendEquip]: Last equip was too soon ["..tostring(TimeSince(ml_global_information.lastEquip)).."]")
		return false
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
function c_selectconvindex:evaluate()	
	if (c_selectconvindex.unexpected > 5) then
		c_selectconvindex.unexpected = 0
	end
	return (IsControlOpen("SelectIconString") or IsControlOpen("SelectString"))
end
function e_selectconvindex:execute()	
	local conversationstrings = IsNull(ml_task_hub:CurrentTask().conversationstrings,{})
	if (table.valid(conversationstrings)) then
		local convoList = GetConversationList()
		if (table.valid(convoList)) then
			for selectindex,convo in pairs(convoList) do
				local cleanedline = string.gsub(convo,"[()-/]","")
				for k,v in pairs(conversationstrings) do
					local cleanedv = string.gsub(v,"[()-/]","")
					if (string.contains(cleanedline,cleanedv)) then
						d("Use conversation line ["..tostring(convo).."]")
						SelectConversationLine(selectindex)
						ml_global_information.Await(2000, function () return not (table.valid(GetConversationList())) end)
						return false
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
	if (MIsCasting() or CannotMove() or MIsLoading()) then
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
		PressYesNo(true)
		ml_global_information.Await(1500, function () return not IsControlOpen("SelectYesno") end)
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
	if (MIsCasting() or CannotMove() or MIsLoading() or 
		IsControlOpen("SelectString") or IsControlOpen("SelectIconString") or IsShopWindowOpen()) 
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
function c_switchclass:evaluate()	
	e_switchclass.weapon = nil
	
	local class = ml_task_hub:CurrentTask().class
	if (Player.job ~= class) then
		if (IsShopWindowOpen() or CannotMove() or MIsLoading() or 
			not Player.alive or Player.incombat or
			IsControlOpen("Gathering") or Player:GetFishingState() ~= 0) 
		then
			return false
		end
			
		local canSwitch,bestWeapon = CanSwitchToClass(class)
		if (canSwitch and bestWeapon) then
			e_switchclass.weapon = bestWeapon
			return true
		end	
	end
	return false
end
function e_switchclass:execute()	
	local job = Player.job
	local weapon = e_switchclass.weapon
	if (weapon) then
		local weaponid = weapon.hqid
		d("attempting to move weapon ["..tostring(weaponid).."] into equipment")
		weapon:Move(1000,0)
		ml_global_information.Await(1000, 3000, function() return Player.job ~= job end)
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
	if (gSkipCutscene and FFXIV_Common_BotRunning and not IsControlOpen("JournalResult") and TimeSince(c_skipcutscene.lastSkip) > 3000) then
		local totalUI = 0
		for i=0,165 do
			if (GetUIPermission(i) == 1) then
				totalUI = totalUI + i
			end
		end
		
		if (totalUI == 5701 and not IsControlOpen("NowLoading")) then
			if (IsControlOpen("SelectString") or IsControlOpen("SelectIconString")) then
				local convoList = GetConversationList()
				if (table.valid(convoList)) then
					SelectConversationIndex(1)
				end
			else
				KeyDown(27)
				ml_global_information.Await(250,function () KeyUp(27) end)
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
	
	-- Scan for our wanted contentid to get as much data as we can, for better decisions.
	local interactable = nil
	if (ml_task_hub:CurrentTask().lastInteractableSearch == nil) then
		ml_task_hub:CurrentTask().lastInteractableSearch = 0
	end
	if (ml_task_hub:CurrentTask().interact == 0 and TimeSince(ml_task_hub:CurrentTask().lastInteractableSearch) > 500) then
		if (ml_task_hub:CurrentTask().contentid ~= 0) then
			local nearestInteract = GetInteractableEntity(ml_task_hub:CurrentTask().contentid)
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
			if ( interactable.meshpos and not IsFlying()) then
				if (not ml_task_hub:CurrentTask().pathChecked) then
					local meshpos = interactable.meshpos
					local x,y,z = meshpos.x,meshpos.y,meshpos.z
					if (NavigationManager:IsReachable(meshpos)) then
						ml_task_hub:CurrentTask().pos = interactable.meshpos
					end
					ml_task_hub:CurrentTask().pathChecked = true
				end
			end
		end
	end
	
	if (interactable and interactable.targetable) then
		if (not myTarget or (myTarget and myTarget.id ~= interactable.id)) then
			Player:SetTarget(interactable.id)
		end
	end
	
	if (interactable and not IsFlying()) then
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

		if (not IsFlying()) then
			--if (myTarget and myTarget.id == interactable.id and myTarget.interactable) then
			if (myTarget and myTarget.id == interactable.id) then
				
				--[[
				-- Special handler for gathering.  Need to wait on GP before interacting sometimes.
				if (IsNull(ml_task_hub:CurrentTask().minGP,0) > Player.gp.current) then
					d("["..ml_task_hub:CurrentTask().name.."]: Waiting on GP before attempting node.")
					Player:Stop()
					return true
				end
				
				if (IsGatherer(Player.job) and interactable.contentid > 4 and table.size(EntityList.aggro) > 0) then
					d("["..ml_task_hub:CurrentTask().name.."]: Don't attempt a special node if we gained aggro.")
					return false
				end
				
				d("["..ml_task_hub:CurrentTask().name.."]: Interacting with target type ["..tostring(interactable.type).."].")
				Player:Interact(interactable.id)
				ml_task_hub:CurrentTask().interactAttempts = ml_task_hub:CurrentTask().interactAttempts + 1
				
				-- this return might need to be false, if the .interactable is not perfect
				return true
				--]]
				
				if (table.valid(interactable) and ((not ml_task_hub:CurrentTask().interactRange3d and ydiff <= 4.95 and ydiff >= -1.3) or (ml_task_hub:CurrentTask().interactRange3d and interactable.distance < ml_task_hub:CurrentTask().interactRange3d))) then			
					if (interactable.type == 5) then
						if (interactable.distance2d <= 7) then
							Player:SetFacing(interactable.pos.x,interactable.pos.y,interactable.pos.z)

							if (TimeSince(c_dointeract.lastInteract) > 2000 and Player:IsMoving()) then
								Player:Stop()
								ml_global_information.Await(1000, function () return not Player:IsMoving() end)
								return true
							end
							
							d("["..ml_task_hub:CurrentTask().name.."]: Interacting with aetheryte target.")
							Player:Interact(interactable.id)
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
						end
					else
						local range = ((ml_task_hub:CurrentTask().interactRange and ml_task_hub:CurrentTask().interactRange >= 3) and ml_task_hub:CurrentTask().interactRange) or defaults[interactable.type] or radius
						if (not ml_task_hub:CurrentTask().interactRange and ml_task_hub:CurrentTask().interactRange3d and range > ml_task_hub:CurrentTask().interactRange3d) then
							range = ml_task_hub:CurrentTask().interactRange3d
						end
						if (interactable.cangather) then
							range = 2.5
						end
						
						if (interactable and IsEntityReachable(interactable,range + 2) and interactable.distance2d < range) then
							Player:SetFacing(interactable.pos.x,interactable.pos.y,interactable.pos.z)
							
							-- Special handler for gathering.  Need to wait on GP before interacting sometimes.
							if (IsNull(ml_task_hub:CurrentTask().minGP,0) > Player.gp.current) then
								d("["..ml_task_hub:CurrentTask().name.."]: Waiting on GP before attempting node.")
								Player:Stop()
								return true
							end
							
							if (IsGatherer(Player.job) and interactable.contentid > 4 and table.size(EntityList.aggro) > 0) then
								d("["..ml_task_hub:CurrentTask().name.."]: Don't attempt a special node if we gained aggro.")
								return false
							end
							
							d("["..ml_task_hub:CurrentTask().name.."]: Interacting with target type ["..tostring(interactable.type).."].")
							Player:Interact(interactable.id)
							if (ml_task_hub:CurrentTask().interactAttempts == nil) then
								ml_task_hub:CurrentTask().interactAttempts = 1
							else
								ml_task_hub:CurrentTask().interactAttempts = ml_task_hub:CurrentTask().interactAttempts + 1
							end
							return false
						end
					end
				end
			end
		end
	end
	return false
end
function e_dointeract:execute()
end
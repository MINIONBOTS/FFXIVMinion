ffxiv_task_pvp = inheritsFrom(ml_task)
ffxiv_task_pvp.name = "LT_PVP"
ffxiv_task_pvp.lastTick = 0
ffxiv_task_pvp.multibotJoin = false
ffxiv_task_pvp.wonLastMatch = false

function ffxiv_task_pvp.Create()
    local newinst = inheritsFrom(ffxiv_task_pvp)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_pvp members
    newinst.name = "LT_PVP"
    newinst.targetid = 0
    newinst.queueTimer = 0
    newinst.windowTimer = 0
	newinst.afkTimer = 0
	newinst.lastPos = {}
	newinst.fleeing = false
	newinst.targetPrio = ""
    newinst.leaveTimer = 0
	
	-- set the correct starting state in case we're already in a pvp map and reload lua
	if MultiComp(Player.localmapid, "337,175,336,186,376,422") then
		newinst.state = "WAITING_FOR_COMBAT"
	else
		newinst.state = ""
	end
	newinst.targetTimer = 0
	newinst.startTimer = 0
	newinst.enterTimer = 0
	newinst.markerTime = 0
	newinst.multibotBroadcastTimer = 0
	newinst.multibotWithdrawTimer = 0
	
    newinst.currentMarker = false
	newinst.filterLevel = false
    newinst.atMarker = false
	newinst.deadTimes = 0
	newinst.movementDelay = 0
	newinst.currentLeader = ""
    
    newinst.targetFunction = GetPVPTarget
    
    return newinst
end

c_joinqueuepvp = inheritsFrom( ml_cause )
e_joinqueuepvp = inheritsFrom( ml_effect )
function c_joinqueuepvp:evaluate() 
    return ((   not MultiComp(Player.localmapid, "337,175,336,186,376,422")) and 
				(IsLeader() or TableSize(EntityList.myparty) == 0) and
				not IsLoading() and Player.alive and
                (ml_task_hub:ThisTask().state == "COMBAT_ENDED" or
				ml_task_hub:ThisTask().state == ""))
end
function e_joinqueuepvp:execute()
    if not ControlVisible("ContentsFinder") then
		SendTextCommand("/dutyfinder")
        ml_task_hub:ThisTask().windowTimer = Now() + 1500
    elseif ( ControlVisible("ContentsFinder") and (Now() > ml_task_hub:ThisTask().windowTimer)) then
        PressDutyJoin()
        ml_task_hub:ThisTask().state = "WAITING_FOR_DUTY"
		ffxiv_task_pvp.multibotJoin = false
    end
end

c_detectenter = inheritsFrom( ml_cause )
e_detectenter = inheritsFrom( ml_effect )
function c_detectenter:evaluate() 
    return (   MultiComp(Player.localmapid,"337,175,336,186,376,422") and 
			MultiComp(ml_task_hub:ThisTask().state,"WAITING_FOR_DUTY,DUTY_STARTED") and
			not IsLoading())
end
function e_detectenter:execute()
    ml_task_hub:ThisTask().state = "WAITING_FOR_COMBAT"
	ml_task_hub:ThisTask().enterTimer = Now()
	ml_task_hub:ThisTask().deadTimes = 0
end

c_pressleave = inheritsFrom( ml_cause )
e_pressleave = inheritsFrom( ml_effect )
function c_pressleave:evaluate()
    return (MultiComp(Player.localmapid, "337,175,336,186,376,422") and ControlVisible("ColosseumRecord"))
end
function e_pressleave:execute()
	-- reset pvp task state since it doesn't get terminated/reinstantiated
	ml_task_hub:ThisTask().state = "COMBAT_ENDED"
	ml_task_hub:ThisTask().targetid = 0
	ml_task_hub:ThisTask().startTimer = 0
	ml_task_hub:ThisTask().leaveTimer = 0
	ml_task_hub:ThisTask().enterTimer = 0
	ml_task_hub:ThisTask().afkTimer = 0
	Player:Stop()
	ffxiv_task_pvp.wonLastMatch = Player.alive
		
    if (gPVPDelayLeave == "1" and ml_task_hub:ThisTask().leaveTimer == 0) then
        ml_task_hub:ThisTask().leaveTimer = Now() + math.random(12000,18000)
    elseif (gPVPDelayLeave == "0" or Now() > ml_task_hub:ThisTask().leaveTimer) then
        PressLeaveColosseum()
    end
end

c_startcombat = inheritsFrom( ml_cause )
e_startcombat = inheritsFrom( ml_effect )
function c_startcombat:evaluate()	
	-- make sure we don't go back into combat state after the leave button is pressed
	if ml_task_hub:ThisTask().state == "COMBAT_ENDED" or ml_task_hub:ThisTask().state == "COMBAT_STARTED" then return false end
	
	if (Player.localmapid == 186 and ml_task_hub:ThisTask().state == "WAITING_FOR_COMBAT") then
		if (gPVPSpeedMatchPartner and gPVPSpeedMatchPartner ~= "") then
			local enemyParty = EntityList("onmesh,attackable,alive,chartype=4")
			if (enemyParty) then
				for i,enemy in pairs(enemyParty) do
					if (enemy.name == gPVPSpeedMatchPartner) then
						local p,dist = NavigationManager:GetClosestPointOnMesh({0,.1349,0},false)
						GameHacks:TeleportToXYZ(p.x,p.y,p.z)
						Player:Jump()
						return true
					end
				end
			else
				--d("No valid enemy team found.")
			end
		end
	else
		--d("MapID or state is not valid for speed matching.")
		--d("MapID:"..tostring(Player.localmapid))
		--d("State:"..tostring(ml_task_hub:ThisTask().state))
	end
	
    -- just in case we restart lua while in pvp combat
    if ((MultiComp(Player.localmapid,"337,175,336,186,376,422")) and (Player.incombat or InCombatRange(ml_task_hub:ThisTask().targetid))) then
		return true
    end
	
	if (ml_task_hub:ThisTask().state == "WAITING_FOR_COMBAT" and 
		((MultiComp(Player.localmapid,"337,175,336,186") and TimeSince(ml_task_hub:ThisTask().enterTimer) > 62000) or
		((Player.localmapid == 376 or Player.localmapid == 422) and TimeSince(ml_task_hub:ThisTask().enterTimer) > 116000))) then
		return true
	end

    if ((MultiComp(Player.localmapid, "337,175,336,186,376,422")) and ml_task_hub:ThisTask().state == "WAITING_FOR_COMBAT") then
        local party = EntityList("myparty")
        local maxdistance = 0
        if (ValidTable(party)) then
			local myPos = Player.pos
			for i,e in pairs(party) do
				-- if any party members are in combat then start combat
                if e.incombat then return true end
				
				if (MultiComp(Player.localmapid,"337,175,336,186")) then
					-- otherwise check to see if any party members have crossed the gate and set a random timer
					if 	(myPos.x > 33.3 and e.pos.x < 33.3) or
						(myPos.x < -33.3 and e.pos.x > -33.3)
					then
						if (ml_task_hub:ThisTask().startTimer == 0) then
							ml_task_hub:ThisTask().startTimer = Now() + math.random(0,500)
						elseif (Now() > ml_task_hub:ThisTask().startTimer) then
							return true
						end
					end
				end
            end
        end
            
        return false
    end
    
    return false
end
function e_startcombat:execute()
    ml_task_hub:ThisTask().state = "COMBAT_STARTED"
end

c_pvpflee = inheritsFrom( ml_cause )
e_pvpflee = inheritsFrom( ml_effect )
e_pvpflee.fleePos = {}
function c_pvpflee:evaluate()
	if (Player.localmapid ~= 376 and Player.localmapid ~= 422) then
		return false
	end
	
	if ((Player.incombat) and (Player.hp.percent < tonumber(gFleeHP) or Player.mp.percent < tonumber(gFleeMP))) then
		if (ValidTable(ml_marker_mgr.markerList["evacPoint"])) then
			local fpos = ml_marker_mgr.markerList["evacPoint"]
			local ppos = Player.pos
			if (Distance3D(ppos.x, ppos.y, ppos.z, fpos.x, fpos.y, fpos.z) > 50) then
				e_pvpflee.fleePos = fpos
				return true
			end
		end
		
		local ppos = Player.pos
		local newPos = NavigationManager:GetRandomPointOnCircle(ppos.x,ppos.y,ppos.z,100,200)
		if (ValidTable(newPos)) then
			e_pvpflee.fleePos = newPos
			return true
		end
	end
    
    return false
end
function e_pvpflee:execute()
	local fleePos = e_pvpflee.fleePos
	if (ValidTable(fleePos)) then
		local newTask = ffxiv_task_flee.Create()
		newTask.pos = fleePos
		newTask.useTeleport = false
		newTask.task_complete_eval = 
			function ()
				return not Player.incombat or (Player.hp.percent > tonumber(gFleeHP) and Player.mp.percent > tonumber(gFleeMP))
			end
		newTask.task_fail_eval = 
			function ()
				return not Player.alive or ((not c_walktopos:evaluate() or Player:IsMoving()) and Player.incombat)
			end
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	else
		ml_error("Need to flee but no evac position defined for this mesh!!")
	end
end

c_afkmove = inheritsFrom( ml_cause )
e_afkmove = inheritsFrom( ml_effect )
function c_afkmove:evaluate()
	return 	(gAFKMove == "1" and 
			Now() > ml_task_hub:ThisTask().afkTimer and
			( MultiComp(Player.localmapid, "337,175,336,186,376,422")) and
			TimeSince(ml_task_hub:ThisTask().enterTimer) > 5000)
end
function e_afkmove:execute()
	if (ml_task_hub:ThisTask().afkTimer == 0) then
		ml_task_hub:ThisTask().afkTimer = ml_global_information.Now + math.random(25000,30000)
		return
	elseif (ml_global_information.Now > ml_task_hub:ThisTask().afkTimer) then
		if (MultiComp(Player.localmapid, "337,175,336,186")) then
			local myPos = Player.pos
			local newPos = NavigationManager:GetRandomPointOnCircle(myPos.x, myPos.y, myPos.z,2,1)
			local betterPos,dist = NavigationManager:GetClosestPointOnMesh(newPos)
			
			if (ValidTable(betterPos) and dist <= 5) and 
				((Player.pos.x < -33.3 and betterPos.x < -33.3) or (Player.pos.x > 33.3 and betterPos.x > 33.3)) then
				Player:MoveTo(betterPos.x, betterPos.y, betterPos.z, 0.5)
				ml_task_hub:ThisTask().lastPos = betterPos
				ml_task_hub:ThisTask().afkTimer = Now() + 30000
			end
		else
			local myPos = Player.pos
			local newPos = NavigationManager:GetRandomPointOnCircle(myPos.x, myPos.y, myPos.z,10,5)
			local betterPos,dist = NavigationManager:GetClosestPointOnMesh(newPos)
			
			Player:MoveTo(betterPos.x, betterPos.y, betterPos.z, 0.5)
			ml_task_hub:ThisTask().afkTimer = 0
		end
	end
end

c_pvpdetectenemy = inheritsFrom( ml_cause )
e_pvpdetectenemy = inheritsFrom( ml_effect )
c_pvpdetectenemy.targetid = nil
function c_pvpdetectenemy:evaluate()
	if (ml_task_hub:ThisTask().state ~= "COMBAT_STARTED" or (Player.localmapid ~= 376 and Player.localmapid ~= 422) or IsLoading() or ControlVisible("ColosseumRecord")) then
		return false
	end
	
	if (ml_task_hub:ThisTask().name ~= "MOVETOPOS") then
		return false
	end
    
	local newTarget = EntityList("shortestpath,onmesh,attackable,alive,chartype=4,targetingme,maxdistance=30")
	if (ValidTable(newTarget)) then
		c_pvpdetectenemy.targetid = newTarget.id
		return true
	end
    
    return false
end
function e_pvpdetectenemy:execute()
	ml_task_hub:ThisTask().targetid = c_pvpdetectenemy.targetid
	ml_task_hub:ThisTask().targetTimer = Now()
	Dismount()
	Player:Stop()
end

c_pvpavoid = inheritsFrom( ml_cause )
e_pvpavoid = inheritsFrom( ml_effect )
c_pvpavoid.target = nil
c_pvpavoid.lastavoid = 0
function c_pvpavoid:evaluate()	
	if (gPVPAvoid == "0" or TimeSince(c_pvpavoid.lastavoid) > 10000) then
		return false
	end
	
	local enemyParty = EntityList("onmesh,attackable,alive,chartype=4")
	if (enemyParty) then
		for i,e in pairs(enemyParty) do
			if (TableSize(e.castinginfo) > 0 and e.castinginfo.channelingid ~= 0) then
				local distance = (e.distance + e.hitradius)
				local spell = e.castinginfo.channelingid
				local spelltarget = e.castinginfo.channeltargetid
				
				if (MultiComp(spell, "145,128,146") and spelltarget == Player.id) then
					--d("Detected enemy spell ["..tostring(spell).."] @"..tostring(spelltarget).." at distance "..tostring(distance))
				end
				
				if (MultiComp(spell, "145,128,146")) then
					if (((spell == 145 or spell == 128) and spelltarget == Player.id and distance < 25) or
						((spell == 146) and distance < 10 )) then
						c_pvpavoid.target = e
						c_pvpavoid.lastavoid = ml_global_information.Now
						return true
					end
				end
			end
		end
	end
	
	return false
end
function e_pvpavoid:execute() 
	local target = c_pvpavoid.target
	local pos = Player.pos
	local epos = target.pos
	local angle = AngleFromPos(pos, epos)
	local angle2 = AngleFromPos(epos, pos)
	local onMesh = false
	local attempt = 0
	local escapePoint
	
	if (target.castinginfo.channeltargetid == target.id) then
		escapePoint = (math.random(0,1) == 0 and FindPointOnCircle(epos, angle, (target.hitradius + 10)) or FindPointLeftRight(epos, angle2, (target.hitradius + 13), false))
	else
		escapePoint = FindPointOnCircle(epos, angle, (target.hitradius + 25))
	end
	
	local p,dist = NavigationManager:GetClosestPointOnMesh(escapePoint)
	if (p ~= nil and dist <= 25) then
		local newTask = ffxiv_task_pvpavoid.Create()
		newTask.pos = p
		newTask.maxTime = tonumber(target.castinginfo.casttime - target.castinginfo.channeltime)
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_ASAP)
	end
end

c_confirmEnterPVP = inheritsFrom( ml_cause )
e_confirmEnterPVP = inheritsFrom( ml_effect )
e_confirmEnterPVP.confirm = false
function c_confirmEnterPVP:evaluate()	
	if (ControlVisible("ContentsFinderConfirm") and not IsLoading() and Player.alive) then
		return true
	end
end
function e_confirmEnterPVP:execute()
	PressDutyConfirm(true)
	ml_task_hub:ThisTask().state = "DUTY_STARTED"
end

c_pvpdead = inheritsFrom( ml_cause )
e_pvpdead = inheritsFrom( ml_effect )
c_pvpdead.timer = 0
c_pvpdead.throttle = 1000
function c_pvpdead:evaluate()
	if (Player.alive or ControlVisible("ColosseumRecord")) then	
		return false
	end
	
	if (not Player.alive and HasBuffs(Player,"148")) then
		return true
	end
	
	if (Player.localmapid == 376 or Player.localmapid == 422) then
		if (not Player.alive and c_pvpdead.timer == 0) then
			c_pvpdead.timer = Now() + 7000 + (ml_task_hub:ThisTask().deadTimes * 5000)
		end 
		
		if (not Player.alive and Now() > c_pvpdead.timer) then
			return true
		end
	end
	
    return false
end
function e_pvpdead:execute()
	if (HasBuffs(Player,"148")) then
		PressYesNo(true)
		c_pvpdead.timer = 0
	else
		PressYesNoCounter(true)
		c_pvpdead.timer = 0
		ml_task_hub:ThisTask():ResetMarkerStatus()
	end
end

c_pvpfollowleader = inheritsFrom( ml_cause )
e_pvpfollowleader = inheritsFrom( ml_effect )
c_pvpfollowleader.range = math.random(3,8)
c_pvpfollowleader.leaderpos = nil
c_pvpfollowleader.leader = nil
c_pvpfollowleader.distance = nil
c_pvpfollowleader.hasEntity = false
e_pvpfollowleader.isFollowing = false
e_pvpfollowleader.stopFollow = false
function c_pvpfollowleader:evaluate()
	if (gBotMode == GetString("partyMode") and IsLeader() or IsPlayerCasting()) then
        return false
    end
	
	local leader, isEntity = GetPartyLeader()
	local leaderPos = GetPartyLeaderPos()
	if (ValidTable(leaderPos) and ValidTable(leader)) then
		local myPos = shallowcopy(Player.pos)	
		local distance = PDistance3D(myPos.x, myPos.y, myPos.z, leaderPos.x, leaderPos.y, leaderPos.z)
		
		if (((leader.incombat and distance > 5) or (distance > 10)) or (isEntity and (leader.ismounted and not Player.ismounted))) then				
			c_pvpfollowleader.leaderpos = leaderPos
			c_pvpfollowleader.leader = leader
			c_pvpfollowleader.distance = distance
			c_pvpfollowleader.hasEntity = isEntity
			return true
		end
	end
	
	if (e_pvpfollowleader.isFollowing) then
		e_pvpfollowleader.stopFollow = true
		return true
	end
	
    return false
end
function e_pvpfollowleader:execute()
	local leader = c_pvpfollowleader.leader
	local leaderPos = c_pvpfollowleader.leaderpos
	local distance = c_pvpfollowleader.distance
	
	if (e_pvpfollowleader.isFollowing and e_pvpfollowleader.stopFollow) then
		Player:Stop()
		e_pvpfollowleader.isFollowing = false
		e_pvpfollowleader.stopFollow = false
		return
	end
	
	if (Player.onmesh) then		
		-- mount
		
		if (gUseMount == "1" and gMount ~= "None" and c_pvpfollowleader.hasEntity) then
			if (((leader.castinginfo.channelingid == 4 or leader.ismounted) or distance >= tonumber(gMountDist)) and not Player.ismounted) then
				if (not IsPlayerCasting()) then
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
		
		if (c_pvpfollowleader.hasEntity and leader.los) then
			ml_debug( "Moving to Leader: "..tostring(Player:MoveTo(leaderPos.x, leaderPos.y, leaderPos.z, tonumber(c_pvpfollowleader.range),true,false)))	
		else
			ml_debug( "Moving to Leader: "..tostring(Player:MoveTo(leaderPos.x, leaderPos.y, leaderPos.z, tonumber(c_pvpfollowleader.range),false,false)))	
		end
		if ( not Player:IsMoving()) then
			if ( ml_global_information.AttackRange < 5 ) then
				c_pvpfollowleader.range = math.random(4,6)
			else
				c_pvpfollowleader.range = math.random(6,10)
			end
		end
		e_pvpfollowleader.isFollowing = true
	else
		if ( not Player:IsMoving() ) then
			local FollowResult = Player:FollowTarget(leader.id)
			ml_debug( "Following Leader: "..tostring(FollowResult))
		end
	end
end

function ffxiv_task_pvp:Init()
    --init Process() cnes		
	local ke_pressLeave = ml_element:create( "LeaveColosseum", c_pressleave, e_pressleave, 50 )
    self:add(ke_pressLeave, self.overwatch_elements)
	
	local ke_pvpDead = ml_element:create( "Dead", c_pvpdead, e_pvpdead, 35 )
    self:add( ke_pvpDead, self.overwatch_elements)
	
	local ke_pvpFlee = ml_element:create( "Flee", c_pvpflee, e_pvpflee, 30 )
    self:add( ke_pvpFlee, self.overwatch_elements)
	
	local ke_pvpDetectEnemy = ml_element:create( "DetectEnemy", c_pvpdetectenemy, e_pvpdetectenemy, 25 )
    self:add(ke_pvpDetectEnemy, self.overwatch_elements)
	
	local ke_pressConfirm = ml_element:create( "ConfirmDuty", c_confirmEnterPVP, e_confirmEnterPVP, 10 )
    self:add(ke_pressConfirm, self.process_elements)
	
	local ke_startCombat = ml_element:create( "StartCombat", c_startcombat, e_startcombat, 15 )
    self:add(ke_startCombat, self.process_elements)
	
	local ke_detectEnter = ml_element:create( "DetectEnter", c_detectenter, e_detectenter, 10 )
    self:add(ke_detectEnter, self.process_elements)
    
    local ke_pressJoin = ml_element:create( "JoinDutyFinder", c_joinqueuepvp, e_joinqueuepvp, 10 )
    self:add(ke_pressJoin, self.process_elements)
    
    local ke_startCombat = ml_element:create( "StartCombat", c_startcombat, e_startcombat, 5 )
    self:add(ke_startCombat, self.process_elements)
	
	local ke_afkMove = ml_element:create( "AFKMove", c_afkmove, e_afkmove, 5 )
    self:add( ke_afkMove, self.process_elements)
  
    self:AddTaskCheckCEs()
end

-- custom process function for optimal performance
function ffxiv_task_pvp:Process()
	if (IsLoading() or ml_mesh_mgr.loadingMesh) then
		return false
	end
	
    -- only perform combat logic when we are in the wolves den
    if (MultiComp(Player.localmapid, "337,175,336,186,376,422") and Player.alive) then
        if (ml_task_hub:ThisTask().state == "COMBAT_STARTED") then
			if (HasBuffs(Player,"2,3,13,149,280,397")) then
				Player:Stop()
			else
				local markerPos = nil
				if (ValidTable(ml_task_hub:ThisTask().currentMarker)) then
					markerPos = ml_task_hub:ThisTask().currentMarker:GetPosition()
				end
				
				local target = EntityList:Get(ml_task_hub:ThisTask().targetid)
				local tpos = nil
				if (ValidTable(target)) then
					tpos = shallowcopy(target.pos)
				end
				
				if (	TimeSince(ml_task_hub:ThisTask().targetTimer) > 1000 or
						ml_task_hub:ThisTask().targetid == 0 or
						not target or
						(target and target.targetid ~= Player.id and tpos and markerPos and (Player.localmapid == 376 or Player.localmapid == 422) and (Distance3D(markerPos.x,markerPos.y,markerPos.z,tpos.x,tpos.y,tpos.z) > 20)) or
						(target and tpos and markerPos and (Player.localmapid == 376 or Player.localmapid == 422) and (Distance3D(markerPos.x,markerPos.y,markerPos.z,tpos.x,tpos.y,tpos.z) > 30)) or
						(target and (not target.alive or HasBuff(target.id,3) or HasBuff(target.id,397)))) 
				then
					if (c_returntomarker:evaluate()) then
						if (not ml_task_hub:CurrentTask().name == "MOVETOPOS" and ml_task_hub:CurrentTask().destination == "PVPMARKER") then
							c_returntomarker:execute()
						end
					else
						local newTarget = GetPVPTarget()
						if ValidTable(newTarget) and newTarget.id ~= ml_task_hub:ThisTask().targetid then
							if ((Player.localmapid == 376 or Player.localmapid == 422) and markerPos) then
								local ntpos = shallowcopy(newTarget.pos)
								if ( newTarget.targetid == Player.id or PDistance3D(markerPos.x,markerPos.y,markerPos.z,ntpos.x,ntpos.y,ntpos.z) < 50 ) then
									ml_task_hub:ThisTask().targetid = newTarget.id
									target = EntityList:Get(ml_task_hub:ThisTask().targetid)
								end
							else
								ml_task_hub:ThisTask().targetid = newTarget.id
								target = EntityList:Get(ml_task_hub:ThisTask().targetid)
							end
						end
						ml_task_hub:ThisTask().targetTimer = Now()		
						
						if ValidTable(target) then
							local pos = target.pos
							if (gPVPWinTrade == "1" and ffxiv_task_pvp.wonLastMatch) then
								Player:SetTarget(target.id)
								Player:SetFacing(pos.x,pos.y,pos.z)
							else
								if (Player.ismounted) then
									Dismount()
									return
								end
								
								Player:SetTarget(target.id)
								local dist = PDistance3D(Player.pos.x,Player.pos.y,Player.pos.z,pos.x,pos.y,pos.z)
								
								if (ml_global_information.AttackRange > 5) then
									if ((not InCombatRange(target.id) or not target.los) and not IsPlayerCasting()) then
										if (Now() > self.movementDelay) then
											local path = Player:MoveTo(pos.x,pos.y,pos.z, 15, false, false)
											self.movementDelay = Now() + 1000
										end
									end
									if (InCombatRange(target.id)) then
										if (Player.ismounted) then
											Dismount()
										end
										if ((IsCaster(Player.job) and Player:IsMoving()) or target.los) then
											Player:Stop()
										end
									end
									
									if (InCombatRange(target.id) and target.attackable and target.alive) then
										Player:SetFacing(pos.x,pos.y,pos.z) 
										SkillMgr.Cast( target )
									end
								else
									if (not InCombatRange(target.id) or not target.los) then
										if (target.los and dist <= 6) then
											Player:MoveTo(pos.x,pos.y,pos.z, 0.5, true, false)
										else
											Player:MoveTo(pos.x,pos.y,pos.z, 0.5, true, false)
										end
									end
									if (InCombatRange(target.id)) then
										if (Player.ismounted) then
											Dismount()
										end
										if (Player:IsMoving()) then
											Player:Stop()
										end
									end
									
									if (InCombatRange(target.id) and target.attackable and target.alive) then
										Player:SetFacing(pos.x,pos.y,pos.z)
										SkillMgr.Cast( target )
									end
								end
							end
						else
							ml_task_hub:ThisTask().targetid = 0
							if Player.role == 4 then
								SkillMgr.Cast( Player, true )
							end
						end
					end
				end
			end
        else
           SkillMgr.Cast( Player , true )
        end
    end
      
    --Process regular elements.
    if (TableSize(self.process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(self.process_elements)
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end

function GetPVPTargetTypes()
	local targetTypeList = GetStringList("healer,dps,tank,sleeper,caster,ranged,meleeDPS,nearDead,nearest,lowestHealth,unattendedHealer",",")
	return targetTypeList
end

-- UI settings etc
function ffxiv_task_pvp.UIInit()
	--Add it to the main tracking table, so that we can save positions for it.
	if ( not ffxivminion.Windows) then
		ffxivminion.Windows = {}
	end

	ffxivminion.Windows.PVP = { id = strings["us"].pvpMode, Name = GetString("pvpMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.PVP)
	
	if (Settings.FFXIVMINION.gPVPTargetOne == nil) then
        Settings.FFXIVMINION.gPVPTargetOne = GetString("healer")
    end
    if (Settings.FFXIVMINION.gPVPTargetTwo == nil) then
        Settings.FFXIVMINION.gPVPTargetTwo = GetString("lowestHealth")
    end
	if (Settings.FFXIVMINION.gPVPTargetThree == nil) then
        Settings.FFXIVMINION.gPVPTargetThree = GetString("lowestHealth")
    end
	if (Settings.FFXIVMINION.gPVPTargetFour == nil) then
        Settings.FFXIVMINION.gPVPTargetFour = GetString("lowestHealth")
    end
	if (Settings.FFXIVMINION.gPVPTargetFive == nil) then
        Settings.FFXIVMINION.gPVPTargetFive = GetString("lowestHealth")
    end
    if (Settings.FFXIVMINION.gPrioritizeRanged == nil) then
        Settings.FFXIVMINION.gPrioritizeRanged = "0"
    end
	if (Settings.FFXIVMINION.gAFKMove == nil) then
        Settings.FFXIVMINION.gAFKMove = "1"
    end
    if (Settings.FFXIVMINION.gPVPDelayLeave == nil) then
        Settings.FFXIVMINION.gPVPDelayLeave = "0"
    end
	if (Settings.FFXIVMINION.gPVPAvoid == nil) then
        Settings.FFXIVMINION.gPVPAvoid = "0"
    end
	if (Settings.FFXIVMINION.gPVPSpeedMatchPartner == nil) then
        Settings.FFXIVMINION.gPVPSpeedMatchPartner = ""
    end
	if (Settings.FFXIVMINION.gStatusPVPLeader == nil) then
        Settings.FFXIVMINION.gStatusPVPLeader = ""
    end
	if (Settings.FFXIVMINION.gPVPWinTrade == nil) then
        Settings.FFXIVMINION.gPVPWinTrade = "0"
    end
	
	local winName = GetString("pvpMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	GUI_NewButton(winName, GetString("markerManager"), "ToggleMarkerMgr")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,GetString("navmesh") ,"gmeshname",group,ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
	GUI_NewField(winName,GetString("PartyLeader"),"gStatusPVPLeader",group)
	GUI_NewField(winName,GetString("markerName"),"gStatusMarkerName",group)
	GUI_NewField(winName,GetString("markerTime"),"gStatusMarkerTime",group)
	
	local group = GetString("settings")
	local targetTypeList = GetPVPTargetTypes()
    GUI_NewComboBox(winName,GetString("pvpTargetOne"),"gPVPTargetOne",group,targetTypeList)
    GUI_NewComboBox(winName,GetString("pvpTargetTwo"),"gPVPTargetTwo",group,targetTypeList)
	GUI_NewComboBox(winName,GetString("pvpTargetThree"),"gPVPTargetThree",group,targetTypeList)
	GUI_NewComboBox(winName,GetString("pvpTargetFour"),"gPVPTargetFour",group,targetTypeList)
	GUI_NewComboBox(winName,GetString("pvpTargetFive"),"gPVPTargetFive",group,targetTypeList)
    GUI_NewCheckbox(winName,GetString("prioritizeRanged"), "gPrioritizeRanged",group)
	GUI_NewCheckbox(winName,GetString("antiAFKMove"), "gAFKMove",group)
    GUI_NewCheckbox(winName,GetString("delayLeave"), "gPVPDelayLeave",group)
	GUI_NewCheckbox(winName,GetString("pvpAvoid"), "gPVPAvoid",group)
	GUI_NewField(winName,GetString("pvpSpeedMatchPartner"), "gPVPSpeedMatchPartner",group)
	GUI_NewCheckbox(winName,"Win Trade", "gPVPWinTrade",group)
	
	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
    gPVPTargetOne = ffxivminion.SafeComboBox(Settings.FFXIVMINION.gPVPTargetOne,gPVPTargetOne_listitems,GetString("lowestHealth"))
	gPVPTargetTwo = ffxivminion.SafeComboBox(Settings.FFXIVMINION.gPVPTargetTwo,gPVPTargetTwo_listitems,GetString("lowestHealth"))
	gPVPTargetThree = ffxivminion.SafeComboBox(Settings.FFXIVMINION.gPVPTargetThree,gPVPTargetThree_listitems,GetString("lowestHealth"))
	gPVPTargetFour = ffxivminion.SafeComboBox(Settings.FFXIVMINION.gPVPTargetFour,gPVPTargetFour_listitems,GetString("lowestHealth"))
	gPVPTargetFive = ffxivminion.SafeComboBox(Settings.FFXIVMINION.gPVPTargetFive,gPVPTargetFive_listitems,GetString("lowestHealth"))

    gPrioritizeRanged = Settings.FFXIVMINION.gPrioritizeRanged
    gAFKMove = Settings.FFXIVMINION.gAFKMove
    gPVPDelayLeave = Settings.FFXIVMINION.gPVPDelayLeave
	gPVPAvoid = Settings.FFXIVMINION.gPVPAvoid
	gPVPSpeedMatchPartner = Settings.FFXIVMINION.gPVPSpeedMatchPartner
	gPVPWinTrade = Settings.FFXIVMINION.gPVPWinTrade
	
	RegisterEventHandler("GUI.Update",ffxiv_task_pvp.GUIVarUpdate)
end

function ffxiv_task_pvp.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gPVPTargetOne" or
                k == "gPVPTargetTwo" or
				k == "gPVPTargetThree" or
				k == "gPVPTargetFour" or
				k == "gPVPTargetFive" or
                k == "gPrioritizeRanged" or
                k == "gAFKMove" or
                k == "gPVPAvoid" or
                k == "gPVPDelayLeave" or 
				k == "gPVPSpeedMatchPartner" or
				k == "gPVPWinTrade" )
        then
            SafeSetVar(tostring(k),v)
        end
    end
    GUI_RefreshWindow(GetString("pvpMode"))
end

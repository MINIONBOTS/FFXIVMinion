ffxiv_task_pvp = inheritsFrom(ml_task)
ffxiv_task_pvp.name = "LT_PVP"
ffxiv_task_pvp.lastTick = 0

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
	newinst.multibotJoin = false
	newinst.multibotWithdraw = false
	
	-- set the correct starting state in case we're already in a pvp map and reload lua
	if MultiComp(Player.localmapid, "337,175,336,352,376") then
		newinst.state = "WAITING_FOR_COMBAT"
	else
		newinst.state = ""
	end
	newinst.targetTimer = 0
	newinst.startTimer = 0
	newinst.enterTimer = 0
	
	newinst.markerTime = 0
    newinst.currentMarker = false
	newinst.filterLevel = false
    newinst.atMarker = false
	newinst.deadTimes = 0
    
    newinst.targetFunction = GetPVPTarget
    
    return newinst
end

c_joinqueuepvp = inheritsFrom( ml_cause )
e_joinqueuepvp = inheritsFrom( ml_effect )
function c_joinqueuepvp:evaluate() 
    return ((   not MultiComp(Player.localmapid, "337,175,336,352,376")) and 
				(IsLeader() or TableSize(EntityList.myparty) == 0) and
				not IsLoading() and Player.alive and
                (ml_task_hub:ThisTask().state == "COMBAT_ENDED" or
				ml_task_hub:ThisTask().state == ""))
end
function e_joinqueuepvp:execute()
    if not ControlVisible("ContentsFinder") then
        ActionList:Cast(33,0,10)
        ml_task_hub:ThisTask().windowTimer = Now() + 1500
    elseif ( ControlVisible("ContentsFinder") and (Now() > ml_task_hub:ThisTask().windowTimer)) then
        PressDutyJoin()
        ml_task_hub:ThisTask().state = "WAITING_FOR_DUTY"
    end
end

c_detectenter = inheritsFrom( ml_cause )
e_detectenter = inheritsFrom( ml_effect )
function c_detectenter:evaluate() 
    return (   MultiComp(Player.localmapid,"337,175,336,352,376") and 
			MultiComp(ml_task_hub:ThisTask().state,"WAITING_FOR_DUTY,DUTY_STARTED") and
			not IsLoading())
end
function e_detectenter:execute()
    ml_task_hub:ThisTask().state = "WAITING_FOR_COMBAT"
	ml_task_hub:ThisTask().enterTimer = Now()
	ml_task_hub:ThisTask().deadTimes = 0
end

c_pressleave = inheritsFrom( ml_cause )
c_pressleave.throttle = 1000
e_pressleave = inheritsFrom( ml_effect )
function c_pressleave:evaluate() 
    return (MultiComp(Player.localmapid, "337,175,336,352,376") and ControlVisible("ColosseumRecord"))
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
	ml_task_hub:ThisTask():ResetMarkerStatus()
		
    if (gPVPDelayLeave == "1" and ml_task_hub:ThisTask().leaveTimer == 0) then
        ml_task_hub:ThisTask().leaveTimer = Now() + math.random(12000,18000)
    elseif (gPVPDelayLeave == "0" or Now() > ml_task_hub:ThisTask().leaveTimer) then
        PressLeaveColosseum()
    end
end

--d(ml_task_hub:CurrentTask().state)

c_startcombat = inheritsFrom( ml_cause )
e_startcombat = inheritsFrom( ml_effect )
function c_startcombat:evaluate()	
	-- make sure we don't go back into combat state after the leave button is pressed
	if ml_task_hub:ThisTask().state == "COMBAT_ENDED" or ml_task_hub:ThisTask().state == "COMBAT_STARTED" then return false end
	
	if (Player.localmapid == 352 and ml_task_hub:ThisTask().state == "WAITING_FOR_COMBAT") then
		if (gPVPSpeedMatchPartner and gPVPSpeedMatchPartner ~= "") then
			local enemyParty = EntityList("onmesh,attackable,alive,chartype=4")
			for i,enemy in pairs(enemyParty) do
				if (enemy.name == gPVPSpeedMatchPartner) then
					local p,dist = NavigationManager:GetClosestPointOnMesh({0,.1349,0},false)
					GameHacks:TeleportToXYZ(p.x,p.y,p.z)
					return true
				end
			end
		end
	end
	
    -- just in case we restart lua while in pvp combat
    if ((MultiComp(Player.localmapid,"337,175,336,352,376")) and (Player.incombat or InCombatRange(ml_task_hub:ThisTask().targetid))) then
        return true
    end
	
	if (ml_task_hub:ThisTask().state == "WAITING_FOR_COMBAT" and 
		((MultiComp(Player.localmapid,"337,175,336,352") and TimeSince(ml_task_hub:ThisTask().enterTimer) > 62000) or
		(Player.localmapid == 376 and TimeSince(ml_task_hub:ThisTask().enterTimer) > 116000))) then
		return true
	end

    if ((MultiComp(Player.localmapid, "337,175,336,352,376")) and ml_task_hub:ThisTask().state == "WAITING_FOR_COMBAT") then
        local party = EntityList.myparty
        local maxdistance = 0
        if (ValidTable(party)) then
			local myPos = Player.pos
            local i,e = next(party)
            while i ~= nil and e ~= nil do
				-- if any party members are in combat then start combat
                if e.incombat then return true end
				
				if (MultiComp(Player.localmapid,"337,175,336,352")) then
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
            i, e = next(party, i)
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
	if (Player.localmapid ~= 376) then
		return false
	end
	
	if ((Player.incombat or Player.hasaggro) and (Player.hp.percent < tonumber(gFleeHP) or Player.mp.percent < tonumber(gFleeMP))) then
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
			( MultiComp(Player.localmapid, "337,175,336,352,376")) and
			TimeSince(ml_task_hub:ThisTask().enterTimer) > 5000)
end
function e_afkmove:execute()
	if (ml_task_hub:ThisTask().afkTimer == 0) then
		ml_task_hub:ThisTask().afkTimer = ml_global_information.Now + math.random(25000,30000)
		return
	elseif (ml_global_information.Now > ml_task_hub:ThisTask().afkTimer) then
		if (MultiComp(Player.localmapid, "337,175,336,352")) then
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
function c_pvpdetectenemy:evaluate()
	if (ml_task_hub:ThisTask().state ~= "COMBAT_STARTED" or Player.localmapid ~= 376) then
		return false
	end
	
	if (ml_task_hub:ThisTask().name == "LT_PVP") then
		return false
	end
    
	local newTarget = GetPVPTarget()
	if (ValidTable(newTarget)) then
		ml_task_hub:ThisTask().targetid = newTarget.id
		ml_task_hub:ThisTask().targetTimer = Now()
		return true
	end
    
    return false
end
function e_pvpdetectenemy:execute()
	Player:Stop()
end

c_atpvpmarker = inheritsFrom( ml_cause )
e_atpvpmarker = inheritsFrom( ml_effect )
function c_atpvpmarker:evaluate()
	if (ml_task_hub:RootTask().state ~= "COMBAT_STARTED" or Player.localmapid ~= 376) then
		return false
	end

    if (ml_task_hub:ThisTask().atMarker) then
        return false
    end
    
    if (ml_task_hub:ThisTask().currentMarker ~= false and ml_task_hub:ThisTask().currentMarker ~= nil) then
        local myPos = Player.pos
        local pos = ml_task_hub:ThisTask().currentMarker:GetPosition()
        local distance = Distance3D(myPos.x, myPos.y, myPos.z, pos.x, pos.y, pos.z)
		
		if (distance <= 6) then
			return true
		end
    end
    
    return false
end
function e_atpvpmarker:execute()
	ml_global_information.MarkerTime = Now() + (ml_task_hub:ThisTask().currentMarker:GetTime() * 1000)
	ml_task_hub:ThisTask().markerTime = Now() + (ml_task_hub:ThisTask().currentMarker:GetTime() * 1000)
	ml_task_hub:ThisTask().atMarker = true
end

c_nextpvpmarker = inheritsFrom( ml_cause )
e_nextpvpmarker = inheritsFrom( ml_effect )
e_nextpvpmarker.marker = false
function c_nextpvpmarker:evaluate()
	if (ml_task_hub:ThisTask().state ~= "COMBAT_STARTED" or Player.localmapid ~= 376) then
		return false
	end

    if (not ml_marker_mgr.markersLoaded) then
        return false
    end
	
	local nearestTarget = GetPVPTarget()
	if (nearestTarget) then
		return false
	end
	
    if ( ml_task_hub:ThisTask().currentMarker ~= nil and ml_task_hub:ThisTask().currentMarker ~= 0 ) then
        local marker = nil
        
        -- first check to see if we have no initiailized marker
        if (ml_task_hub:ThisTask().currentMarker == false) then --default init value
            marker = ml_marker_mgr.GetNextMarker(strings[gCurrentLanguage].pvpMarker, ml_task_hub:ThisTask().filterLevel)
        
			if (marker == nil) then
				ml_task_hub:ThisTask().filterLevel = false
				marker = ml_marker_mgr.GetNextMarker(strings[gCurrentLanguage].pvpMarker, ml_task_hub:ThisTask().filterLevel)
			end	
		end
        
        -- last check if our time has run out
        if (marker == nil and ml_task_hub:ThisTask().atMarker) then
			if (ValidTable(ml_task_hub:ThisTask().currentMarker)) then
				local expireTime = ml_task_hub:ThisTask().markerTime
				if (Now() > expireTime) then
					ml_debug("Getting Next Marker, TIME IS UP!")
					marker = ml_marker_mgr.GetNextMarker(ml_task_hub:ThisTask().currentMarker:GetType(), ml_task_hub:ThisTask().filterLevel)
				else
					return false
				end
			end
        end
        
        if (ValidTable(marker)) then
            e_nextpvpmarker.marker = marker
            return true
        end
    end
    
    return false
end
function e_nextpvpmarker:execute()	
	ml_task_hub:ThisTask().atMarker = false
	ml_global_information.currentMarker = e_nextpvpmarker.marker
    ml_task_hub:ThisTask().currentMarker = e_nextpvpmarker.marker
    ml_task_hub:ThisTask().markerTime = Now() + (ml_task_hub:ThisTask().currentMarker:GetTime() * 1000)
	ml_global_information.MarkerTime = Now() + (ml_task_hub:ThisTask().currentMarker:GetTime() * 1000)
    ml_global_information.MarkerMinLevel = ml_task_hub:ThisTask().currentMarker:GetMinLevel()
    ml_global_information.MarkerMaxLevel = ml_task_hub:ThisTask().currentMarker:GetMaxLevel()
    ml_global_information.BlacklistContentID = ml_task_hub:ThisTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].NOTcontentIDEquals)
    ml_global_information.WhitelistContentID = ml_task_hub:ThisTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].contentIDEquals)
	gStatusMarkerName = ml_task_hub:ThisTask().currentMarker:GetName()
	
	local newTask = ffxiv_task_movetopos.Create()
    local markerPos = ml_task_hub:ThisTask().currentMarker:GetPosition()
    local markerType = ml_task_hub:ThisTask().currentMarker:GetType()
    newTask.pos = markerPos
    newTask.range = math.random(0,5)
	newTask.use3d = true
	newTask.remainMounted = true
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_pvpavoid = inheritsFrom( ml_cause )
e_pvpavoid = inheritsFrom( ml_effect )
c_pvpavoid.target = nil
c_pvpavoid.lastavoid = 0
function c_pvpavoid:evaluate()	
	if (gPVPAvoid == "0" and TimeSince(c_pvpavoid.lastavoid) > 10000) then
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
e_confirmEnterPVP.confirm = true
function c_confirmEnterPVP:evaluate()
	if (ControlVisible("ContentsFinderConfirm")) then
		if (gMultiBotEnabled == "1") then
			if ( not ml_task_hub:ThisTask().multibotWithdraw and not ml_task_hub:ThisTask().multibotJoin) then
				mb.BroadcastQueueStatus( true )
				return false
			elseif ( ml_task_hub:ThisTask().multibotWithdraw ) then
				e_confirmEnterPVP.confirm = false
				return true
			elseif ( ml_task_hub:ThisTask().multibotJoin ) then
				e_confirmEnterPVP.confirm = true
				return true
			end
		else
			return (Player.localmapid ~= 337 and Player.localmapid ~= 175 and Player.localmapid ~= 336 and Player.localmapid ~= 352)
		end
	end
end
function e_confirmEnterPVP:execute()
	if (gMultiBotEnabled == "1") then
		local confirm = e_confirmEnterPVP.confirm
		PressDutyConfirm(confirm)
		mb.BroadcastQueueStatus( false )
		if (not confirm ) then
			ml_task_hub:ThisTask().state = ""
		end
	else
		PressDutyConfirm(true)
		ml_task_hub:ThisTask().state = "DUTY_STARTED"
	end
end

c_pvpdead = inheritsFrom( ml_cause )
e_pvpdead = inheritsFrom( ml_effect )
c_pvpdead.timer = 0
c_pvpdead.throttle = 1000
function c_pvpdead:evaluate()
	if (Player.alive) then	
		return false
	end
	
	if (not Player.alive and HasBuffs(Player,"148")) then
		return true
	end
	
	if (Player.localmapid == 376) then
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

function ffxiv_task_pvp:Init()
    --init Process() cnes	
	
	--local ke_pvpAvoid = ml_element:create( "PVPAvoid", c_pvpavoid, e_pvpavoid, 10 )
    --self:add(ke_pvpAvoid, self.overwatch_elements)
	
	local ke_pvpDead = ml_element:create( "Dead", c_pvpdead, e_pvpdead, 35 )
    self:add( ke_pvpDead, self.overwatch_elements)
	
	local ke_pvpFlee = ml_element:create( "Flee", c_pvpflee, e_pvpflee, 30 )
    self:add( ke_pvpFlee, self.overwatch_elements)
	
	local ke_pvpDetectEnemy = ml_element:create( "DetectEnemy", c_pvpdetectenemy, e_pvpdetectenemy, 25 )
    self:add(ke_pvpDetectEnemy, self.overwatch_elements)
	
	local ke_atMarker = ml_element:create( "AtMarker", c_atpvpmarker, e_atpvpmarker, 20 )
    self:add(ke_atMarker, self.overwatch_elements)
	
	local ke_pressLeave = ml_element:create( "LeaveColosseum", c_pressleave, e_pressleave, 10 )
    self:add(ke_pressLeave, self.overwatch_elements)
	
	local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 19 )
    self:add(ke_returnToMarker, self.process_elements)
	
    local ke_nextMarker = ml_element:create( "NextMarker", c_nextpvpmarker, e_nextpvpmarker, 18 )
    self:add(ke_nextMarker, self.process_elements)
	
	local ke_pressConfirm = ml_element:create( "ConfirmDuty", c_pressconfirm, e_pressconfirm, 10 )
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
	if (IsLoading() or ml_mesh_mgr.meshLoading) then
		return false
	end
	
    -- only perform combat logic when we are in the wolves den
    if (MultiComp(Player.localmapid, "337,175,336,352,376") and Player.alive) then
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
						(target and tpos and markerPos and Player.localmapid == 376 and (Distance3D(markerPos.x,markerPos.y,markerPos.z,tpos.x,tpos.y,tpos.z) > 50)) or
						(target and (not target.alive or HasBuff(target.id,3) or HasBuff(target.id,397)))) 
				then
					local newTarget = GetPVPTarget()
					if ValidTable(newTarget) and newTarget.id ~= ml_task_hub:ThisTask().targetid then
						if (Player.localmapid == 376 and markerPos) then
							local ntpos = shallowcopy(newTarget.pos)
							if ( Distance3D(markerPos.x,markerPos.y,markerPos.z,ntpos.x,ntpos.y,ntpos.z) < 50) then
								ml_task_hub:ThisTask().targetid = newTarget.id
								target = EntityList:Get(ml_task_hub:ThisTask().targetid)
							end
						else
							ml_task_hub:ThisTask().targetid = newTarget.id
							target = EntityList:Get(ml_task_hub:ThisTask().targetid)
						end
					end
					ml_task_hub:ThisTask().targetTimer = Now()
				end
				
				if ValidTable(target) then
					if (Player.ismounted) then
						Dismount()
						return
					end
					
					local pos = target.pos
					Player:SetTarget(target.id)
					Player:SetFacing(pos.x,pos.y,pos.z)
					SkillMgr.Cast( target )
					
					local dist = Distance2D(Player.pos.x,Player.pos.z,pos.x,pos.z)
					if (ml_global_information.AttackRange > 5) then
						if InCombatRange(target.id) then
							Player:SetFacing(pos.x,pos.y,pos.z)
							SkillMgr.Cast( target )
						else
							if (dist > 25 and not ActionList:IsCasting()) then
								local PathSize = Player:MoveTo(pos.x,pos.y,pos.z, 20, false, false)
							end
							Player:SetFacing(pos.x,pos.y,pos.z)
							SkillMgr.Cast( target )
						end
					else
						if (dist > 6 or not target.los) then
							local path = Player:MoveTo(pos.x,pos.y,pos.z, 1, false, false)
						elseif (dist > 1) then
							local PathSize = Player:MoveTo(pos.x,pos.y,pos.z, 1, true, false)
						end
						Player:SetFacing(pos.x,pos.y,pos.z)
						SkillMgr.Cast( target )
					end
				else
					ml_task_hub:ThisTask().targetid = 0
					if Player.role == 4 then
						SkillMgr.Cast( Player, true )
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

function GetPVPArenas()
	local arenaList = ""
	local order = function( t,a,b ) return (t[a].DutyListIndex < t[b].DutyListIndex) end
	for i, arena in spairs(Duty:GetDutyList(),order) do
		if (MultiComp(arena.id, "337,175,336,352,376")) then
			if arenaList == "" then
				arenaList = arena.name
			else
				arenaList = arenaList..","..arena.name
			end
		end
	end

	return arenaList
end

function GetPVPTargetTypes()
	local targetTypeList = strings[gCurrentLanguage].healer..","..strings[gCurrentLanguage].dps..","..strings[gCurrentLanguage].tank
	targetTypeList = targetTypeList..","..strings[gCurrentLanguage].sleeper..","..strings[gCurrentLanguage].caster..","..strings[gCurrentLanguage].ranged..","..strings[gCurrentLanguage].meleeDPS
	targetTypeList = targetTypeList..","..strings[gCurrentLanguage].nearDead..","..strings[gCurrentLanguage].nearest..","..strings[gCurrentLanguage].lowestHealth..","..strings[gCurrentLanguage].unattendedHealer

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
        Settings.FFXIVMINION.gPVPTargetOne = "Healer"
    end
    if (Settings.FFXIVMINION.gPVPTargetTwo == nil) then
        Settings.FFXIVMINION.gPVPTargetTwo = "Lowest Health"
    end
	if (Settings.FFXIVMINION.gPVPTargetThree == nil) then
        Settings.FFXIVMINION.gPVPTargetThree = "Lowest Health"
    end
	if (Settings.FFXIVMINION.gPVPTargetFour == nil) then
        Settings.FFXIVMINION.gPVPTargetFour = "Lowest Health"
    end
	if (Settings.FFXIVMINION.gPVPTargetFive == nil) then
        Settings.FFXIVMINION.gPVPTargetFive = "Lowest Health"
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
	
	local winName = GetString("pvpMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	GUI_NewButton(winName, strings[gCurrentLanguage].markerManager, "ToggleMarkerMgr")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].botMode,"gBotMode",group,"None")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].skillProfile,"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,strings[gCurrentLanguage].navmesh ,"gmeshname",group,ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,strings[gCurrentLanguage].botEnabled,"gBotRunning",group)
	GUI_NewField(winName,strings[gCurrentLanguage].markerName,"gStatusMarkerName",group )
	GUI_NewField(winName,strings[gCurrentLanguage].markerTime,"gStatusMarkerTime",group )
	
	local group = GetString("settings")
	--GUI_NewComboBox(winName,strings[gCurrentLanguage].pvpArena,"gPVPArena",group,GetPVPArenas())
    GUI_NewComboBox(winName,strings[gCurrentLanguage].pvpTargetOne,"gPVPTargetOne",group,"")
    GUI_NewComboBox(winName,strings[gCurrentLanguage].pvpTargetTwo,"gPVPTargetTwo",group,"")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].pvpTargetThree,"gPVPTargetThree",group,"")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].pvpTargetFour,"gPVPTargetFour",group,"")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].pvpTargetFive,"gPVPTargetFive",group,"")
    GUI_NewCheckbox(winName,strings[gCurrentLanguage].prioritizeRanged, "gPrioritizeRanged",group)
	GUI_NewCheckbox(winName,strings[gCurrentLanguage].antiAFKMove, "gAFKMove",group)
    GUI_NewCheckbox(winName,strings[gCurrentLanguage].delayLeave, "gPVPDelayLeave",group)
	GUI_NewCheckbox(winName,strings[gCurrentLanguage].pvpAvoid, "gPVPAvoid",group)
	GUI_NewField(winName,strings[gCurrentLanguage].pvpSpeedMatchPartner, "gPVPSpeedMatchPartner",group)
	
	local targetTypeList = GetPVPTargetTypes()
	gPVPTargetOne_listitems = targetTypeList
    gPVPTargetTwo_listitems = targetTypeList
	gPVPTargetThree_listitems = targetTypeList
	gPVPTargetFour_listitems = targetTypeList
	gPVPTargetFive_listitems = targetTypeList
	
	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
    gPVPTargetOne = Settings.FFXIVMINION.gPVPTargetOne
    gPVPTargetTwo = Settings.FFXIVMINION.gPVPTargetTwo
	gPVPTargetThree = Settings.FFXIVMINION.gPVPTargetThree
	gPVPTargetFour = Settings.FFXIVMINION.gPVPTargetFour
	gPVPTargetFive = Settings.FFXIVMINION.gPVPTargetFive
    gPrioritizeRanged = Settings.FFXIVMINION.gPrioritizeRanged
    gAFKMove = Settings.FFXIVMINION.gAFKMove
    gPVPDelayLeave = Settings.FFXIVMINION.gPVPDelayLeave
	gPVPAvoid = Settings.FFXIVMINION.gPVPAvoid
	gPVPSpeedMatchPartner = Settings.FFXIVMINION.gPVPSpeedMatchPartner
	
	ffxiv_task_pvp.SetupMarkers()
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
				k == "gPVPSpeedMatchPartner")
        then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(GetString("pvpMode"))
end

function ffxiv_task_pvp.SetupMarkers()
    local pvpMarker = ml_marker:Create("pvpTemplate")
	pvpMarker:SetType(strings[gCurrentLanguage].pvpMarker)
    pvpMarker:SetTime(0)
    pvpMarker:SetMinLevel(50)
    pvpMarker:SetMaxLevel(50)
    ml_marker_mgr.AddMarkerTemplate(pvpMarker)
    ml_marker_mgr.RefreshMarkerTypes()
	ml_marker_mgr.RefreshMarkerNames()
end

function ffxiv_task_pvp:ResetMarkerStatus()
	ml_global_information.currentMarker = false
	self.currentMarker = false
	ml_global_information.MarkerTime = 0
	self.markerTime = 0
	gStatusMarkerName = ""
    self.atMarker = false
end

ffxiv_task_pvpavoid = inheritsFrom(ml_task)
function ffxiv_task_pvpavoid.Create()
    local newinst = inheritsFrom(ffxiv_task_pvpavoid)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetopos members
    newinst.name = "PVP_AVOID"
    newinst.pos = 0
    newinst.range = 1
	newinst.maxTime = 0
    newinst.started = ml_global_information.Now
    
    return newinst
end

function ffxiv_task_pvpavoid:Init()

	local pos = ml_task_hub:ThisTask().pos 
    local PathSize = Player:MoveTo(pos.x,pos.y,pos.z, 1, false, false)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_pvpavoid:task_complete_eval()
	if TimeSince(ml_task_hub:ThisTask().started) > (ml_task_hub:ThisTask().maxTime * 1000) then
		return true
	end
	
	if TimeSince(ml_task_hub:ThisTask().started) > 5000 then
		return true
	end
	
	local myPos = Player.pos
	local gotoPos = ml_task_hub:ThisTask().pos  
	local distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
	
	if (distance <= self.range) then
		return true
	end

    return false
end

function ffxiv_task_pvpavoid:task_complete_execute()
	self.completed = true
    
	local target = Player:GetTarget()
	if (target ~= nil) then
		local pos = target.pos
		Player:SetFacing(pos.x,pos.y,pos.z)
	end
end

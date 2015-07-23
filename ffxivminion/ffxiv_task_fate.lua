---------------------------------------------------------------------------------------------
--TASK_FATE: Longterm Goal - Complete a fate event successfully
---------------------------------------------------------------------------------------------
ffxiv_task_fate = inheritsFrom(ml_task)
function ffxiv_task_fate.Create()
    local newinst = inheritsFrom(ffxiv_task_fate)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_fate members
    newinst.name = "LT_FATE"
    newinst.fateid = 0
	newinst.fatePos = {}
	newinst.targetid = 0
    newinst.targetFunction = GetNearestFateAttackable
	newinst.killFunction = ffxiv_task_grindCombat
	newinst.waitingForChain = false
	newinst.nextFate = {}
	newinst.randomDelayCompleted = false
	
    --newinst.fateTimer = 0
    newinst.fateCompletion = 0
    newinst.started = false
    newinst.moving = false
    newinst.fatePos = {}
	ffxiv_task_grind.inFate = false
    
    return newinst
end

---------------------------------------------------------------------------------------------
--FATEWAIT: If (detect new aggro) Then (kill mob)
---------------------------------------------------------------------------------------------

c_fatewait = inheritsFrom( ml_cause )
e_fatewait = inheritsFrom( ml_effect )
function c_fatewait:evaluate()
	if (IsLoading() or ml_mesh_mgr.meshLoading or ActionList:IsCasting()) then
		return false
	end
	
    local myPos = Player.pos
    local gotoPos = ml_marker_mgr.markerList["evacPoint"]
    return  (gFateWaitNearEvac == "1" and gFatesOnly == "1" and gDoFates == "1" and TableSize(gotoPos) > 0 and 
            NavigationManager:IsOnMesh(gotoPos.x, gotoPos.y, gotoPos.z) and
            Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z) > 15)
end
function e_fatewait:execute()
    local newTask = ffxiv_task_movetopos.Create()
	newTask.destination = "FATE_WAIT"
    local evacPoint = ml_marker_mgr.markerList["evacPoint"]
    local newPos = NavigationManager:GetRandomPointOnCircle(evacPoint.x,evacPoint.y,evacPoint.z,1,5)
    if (ValidTable(newPos)) then
        newTask.pos = {x = newPos.x, y = newPos.y, z = newPos.z}
    else
        newTask.pos = {x = evacPoint.x, y = evacPoint.y, z = evacPoint.z}
    end
    
    newTask.remainMounted = true
	newTask.task_fail_eval = function ()
		return c_add_fate:evaluate()
	end
	newTask.task_fail_execute = function ()
		Player:Stop()
		newTask.valid = false
	end

    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

---------------------------------------------------------------------------------------------
--FATEQUIT: If (completion % has not changed over timer) Then (temporarily blacklist)
---------------------------------------------------------------------------------------------
--[[
c_fatequit = inheritsFrom( ml_cause )
e_fatequit = inheritsFrom( ml_effect )
function c_fatequit:evaluate()
    if ( ml_task_hub:CurrentTask().fateid ~= nil and ml_task_hub:CurrentTask().fateid ~= 0 ) then
        local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
        if (fate ~= nil and TableSize(fate) > 0) then
            if (ml_task_hub:CurrentTask().fateCompletion ~= nil and ml_task_hub:CurrentTask().fateCompletion == fate.completion) then
                if (ml_task_hub:CurrentTask().fateTimer ~= nil and ml_task_hub:CurrentTask().fateTimer ~= 0) then
                    if (TimeSince(ml_task_hub:CurrentTask().fateTimer) > (tonumber(gFateBLTimer)*1000)) then
                        return true
                    end
                end
            elseif (ml_task_hub:CurrentTask().fateCompletion ~= nil and ml_task_hub:CurrentTask().fateTimer ~= nil) then
                ml_task_hub:CurrentTask().fateCompletion = fate.completion
                ml_task_hub:CurrentTask().fateTimer = ml_global_information.Now
            end
        end
    end
    
    return false
end
function e_fatequit:execute()
    if ( ml_task_hub:CurrentTask().fateid ~= nil and ml_task_hub:CurrentTask().fateid ~= 0 ) then
        -- blacklist fate for 5 minutes and terminate task
        local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
        ml_blacklist.AddBlacklistEntry("Fates", fate.id, fate.name, ml_global_information.Now + 1800*1000)
        ml_task_hub:CurrentTask():Terminate()
    end
end
--]]

---------------------------------------------------------------------------------------------
--BETTERFATESEARCH: If (fate with < distance than current target exists) Then (select new fate)
--Clears the current fate and adds a new one if it finds a better match along the route
---------------------------------------------------------------------------------------------
c_betterfatesearch = inheritsFrom( ml_cause )
e_betterfatesearch = inheritsFrom( ml_effect )
c_betterfatesearch.timer = 0
e_betterfatesearch.fateid = 0
function c_betterfatesearch:evaluate()
    if (TimeSince(c_betterfatesearch.timer) < 10000) then
        return false
    end
	
	local thisFate = GetFateByID(ml_task_hub:ThisTask().fateid)
	if (ValidTable(thisFate)) then
		local fatePos = {x = thisFate.x,y = thisFate.y,z = thisFate.z}
		local myPos = Player.pos
		local dist2d = Distance2D(myPos.x,myPos.z,fatePos.x,fatePos.z)
		
		if (ffxiv_task_fate.IsChain(Player.localmapid,thisFate.id) or ffxiv_task_fate.IsHighPriority(Player.localmapid,thisFate.id)) then
			return false
		end
		
		local closestFate = GetClosestFate(myPos)
		if (ValidTable(closestFate) and thisFate.id ~= closestFate.id) then
			if (closestFate.status == 2) then
				if (ffxiv_task_fate.IsChain(Player.localmapid,closestFate.id) or ffxiv_task_fate.IsHighPriority(Player.localmapid,closestFate.id)) then
					c_betterfatesearch.timer = Now()
					e_betterfatesearch.fateid = closestFate.id
					return true	
				elseif (dist2d > thisFate.radius + 20) then
					c_betterfatesearch.timer = Now()
					e_betterfatesearch.fateid = closestFate.id
					return true	
				end
			end
		end
	end
   
    return false
end
function e_betterfatesearch:execute()
	Player:Stop()
    ml_task_hub:ThisTask().fateid = e_betterfatesearch.fateid
end

c_teletofate = inheritsFrom( ml_cause )
e_teletofate = inheritsFrom( ml_effect )
c_teletofate.radius = nil
c_teletofate.pos = nil
c_teletofate.lastTele = 0
function c_teletofate:evaluate()
	if (gTeleport == "0" or 
		Now() < c_teletofate.lastTele or 
		ml_task_hub:ThisTask().name ~= "LT_FATE" or 
		not ml_task_hub:ThisTask().randomDelayCompleted) 
	then
		return false
	end	
	
    if ( ml_task_hub:ThisTask().fateid ~= nil and ml_task_hub:ThisTask().fateid ~= 0 ) then
        local fate = GetFateByID(ml_task_hub:ThisTask().fateid)
        if (fate ~= nil and TableSize(fate) > 0) then
		
			local percent = tonumber(gFateTeleportPercent)
			if (gTeleport == "1" and percent == 0) then
				--use a default completion percentage to enable fate teleport to match checkbox
				percent = 5
			end
			
			if fate.completion > percent then
				local myPos = Player.pos
				local fatePos = {x = fate.x, y = fate.y, z = fate.z}
				
				if (gParanoid == "1") then
					local scanDistance = 50
					local players = EntityList("type=1,maxdistance=".. scanDistance)
					local nearbyPlayers = TableSize(players)
					if nearbyPlayers > 0 then
						return false
					end
					
					local players = EntityList("type=1")
					if (players) then
						for i,entity in pairs(players) do
							local epos = entity.pos
							if (Distance3D(epos.x,epos.y,epos.z,fatePos.x,fatePos.y,fatePos.z) <= 50) then
								return false
							end
						end
					end
				end
	
				local dest,dist = NavigationManager:GetClosestPointOnMesh(fatePos,false)
				if (dest and dist < 10) then
					if Distance2D(myPos.x,myPos.z,dest.x,dest.z) > (fate.radius * 2) then
						c_teletofate.radius = fate.radius
						c_teletofate.pos = dest
						return true
					end
				end
			end
        end
    end
    
    return false
end
function e_teletofate:execute()
	local dest = c_teletofate.pos
	local newPos = NavigationManager:GetRandomPointOnCircle(dest.x,dest.y,dest.z,c_teletofate.radius,(c_teletofate.radius + 15))
	local newdest,dist = NavigationManager:GetClosestPointOnMesh(newPos,false)
	
	Player:Stop()
	if (newdest) then
		GameHacks:TeleportToXYZ(newdest.x,newdest.y,newdest.z)
	end
	Player:SetFacingSynced(Player.pos.h)
	c_teletofate.lastTele = Now() + 10000
	ffxiv_task_grind.inFate = true
end

c_movetochainlocation = inheritsFrom( ml_cause )
e_movetochainlocation = inheritsFrom( ml_effect )
function c_movetochainlocation:evaluate()
	if ( ml_task_hub:CurrentTask().fateid ~= nil and 
		ml_task_hub:CurrentTask().fateid ~= 0 and 
		ml_task_hub:CurrentTask().waitingForChain and 
		ValidTable(ml_task_hub:CurrentTask().nextFate)) 
	then
        local fate = ml_task_hub:CurrentTask().nextFate
		local myPos = Player.pos
		local distance = Distance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z)
		if (distance > 5) then				
			return true
		else
			d("Distance is "..tostring(distance).." from next chain location.")
		end
	end
    
    return false
end
function e_movetochainlocation:execute()
    local fate = ml_task_hub:CurrentTask().nextFate
    if (ValidTable(fate)) then
        local newTask = ffxiv_task_movetopos.Create()
		local fatePos = {x = fate.x, y = fate.y, z = fate.z}
        newTask.pos = fatePos
		newTask.remainMounted = true
		
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

c_movewithfate = inheritsFrom( ml_cause )
e_movewithfate = inheritsFrom( ml_effect )
function c_movewithfate:evaluate()
	if ( ml_task_hub:CurrentTask().fateid ~= nil and ml_task_hub:CurrentTask().fateid ~= 0 ) then
	
		local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
		local currentFatePos = ml_task_hub:CurrentTask().fatePos
		local newFatePos = {x = fate.x, y = fate.y, z = fate.z}
	
		local tablesEqual = true
		if (ValidTable(fate)) then
			if (not ValidTable(currentFatePos)) then
				currentFatePos = shallowcopy(newFatePos)
				return false
			elseif (ValidTable(currentFatePos) and not Player.incombat) then
				if (not deepcompare(currentFatePos,newFatePos,true)) then
					currentFatePos = shallowcopy(newFatePos)
					return true
				end
			end
		end
	end
    
    return false
end
function e_movewithfate:execute()
    local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
    if (ValidTable(fate)) then
        local newTask = ffxiv_task_movetofate.Create()
		local fatePos = ml_task_hub:CurrentTask().fatePos
		newTask.fateid = ml_task_hub:CurrentTask().fateid
        newTask.pos = fatePos
		newTask.actualPos = fatePos
		
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

-----------------------------------------------------------------------------------------------
--MOVETOFATE: If (current fate distance > fate.radius) Then (add movetofate task)
--Moves within range of fate specified by ml_task_hub:CurrentTask().fateid
---------------------------------------------------------------------------------------------
c_movetofate = inheritsFrom( ml_cause )
e_movetofate = inheritsFrom( ml_effect )
function c_movetofate:evaluate()
    if ( ml_task_hub:CurrentTask().fateid ~= nil and ml_task_hub:CurrentTask().fateid ~= 0 ) then
        local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
		
        if (ValidTable(fate)) then
            local myPos = Player.pos
            local distance = Distance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z)
			if (distance > fate.radius) then				
				return true
			end
        end
    end
    
    return false
end
function e_movetofate:execute()
    local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
    if (ValidTable(fate)) then
        local newTask = ffxiv_task_movetofate.Create()
		local fatePos = {x = fate.x, y = fate.y, z = fate.z}
		newTask.fateid = ml_task_hub:CurrentTask().fateid
		newTask.allowRandomization = false
        newTask.pos = fatePos
		newTask.actualPos = fatePos
		
        ml_task_hub:CurrentTask():AddSubTask(newTask)
    end
end

---------------------------------------------------------------------------------------------
--SyncFateLevel
---------------------------------------------------------------------------------------------
c_syncfatelevel = inheritsFrom( ml_cause )
e_syncfatelevel = inheritsFrom( ml_effect )
function c_syncfatelevel:evaluate()
    if (Player:GetSyncLevel() ~= 0 or Now() < ml_global_information.syncTimer) then
        return false
    end
	
    local myPos = Player.pos
	local fateID = ml_task_hub:ThisTask().fateid
	local fate = GetFateByID(fateID)
	if ( ValidTable(fate)) then
		if (ffxiv_task_fate.RequiresSync(fate.level)) then
			local distance = Distance2D(myPos.x, myPos.z, fate.x, fate.z)
			if (distance <= fate.radius) then				
				return true
			end
		end
	end
    return false
end
function e_syncfatelevel:execute()
    ml_debug( "Current Sync Fate level: "..tostring(Player:GetSyncLevel() ))
    ml_debug( "Syncing Fate level Result: "..tostring(Player:SyncLevel()))
	ml_task_hub:ThisTask().preserveSubtasks = true
	ml_global_information.syncTimer = Now() + 1000
end

c_updatefate = inheritsFrom( ml_cause )
e_updatefate = inheritsFrom( ml_effect )
function c_updatefate:evaluate()
	local fate = GetFateByID(ml_task_hub:ThisTask().fateid)
	local fatePos = ml_task_hub:ThisTask().fatePos
	
	local tablesEqual = true
	if (ValidTable(fate)) then
		if (not fatePos) then
			fatePos = {x = fate.x, y = fate.y, z = fate.z}
		elseif (ValidTable(fatePos) and not Player.incombat) then
			if not deepcompare(fate,fateDetails,true) then
				fateDetails = shallowcopy(fate)
			end
		end
		
		if (ml_task_hub:ThisTask().waitingForChain) then ml_task_hub:ThisTask().waitingForChain = false end
		if (ValidTable(ml_task_hub:ThisTask().nextFate)) then ml_task_hub:ThisTask().nextFate = {} end
	end
	
	return false
end
function e_updatefate:execute()
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_resettarget = inheritsFrom( ml_cause )
e_resettarget = inheritsFrom( ml_effect )
function c_resettarget:evaluate()
	local subtask = ml_task_hub:ThisTask().subtask
	local fate = GetFateByID(ml_task_hub:ThisTask().fateid)
	
	if (ValidTable(fate)) then
		if (subtask and subtask.name == "GRIND_COMBAT" and subtask.targetid and subtask.targetid > 0) then
			if (Player:GetSyncLevel() ~= 0) then
				local target = EntityList:Get(subtask.targetid)
				if (ValidTable(target)) then
					if (target.fateid == fate.id) then
						local epos = shallowcopy(target.pos)
						local dist = Distance2D(epos.x,epos.z,fate.x,fate.z)
						if (dist > fate.radius) then
							return true
						end
					end
				end
			end
		end
	end
    
    return false
end
function e_resettarget:execute()
	d("Dropping target outside FATE radius.")
end

c_faterandomdelay = inheritsFrom( ml_cause )
e_faterandomdelay = inheritsFrom( ml_effect )
function c_faterandomdelay:evaluate()
	local fate = GetFateByID(ml_task_hub:ThisTask().fateid)
	
	if (ValidTable(fate) and not ml_task_hub:ThisTask().randomDelayCompleted) then
		local dist = Distance2D(Player.pos.x,Player.pos.z,fate.x,fate.z)
		
		if (fate.completion == 0 and dist > (fate.radius + 20)) then
			return true
		else
			ml_task_hub:ThisTask().randomDelayCompleted = true
		end
	end
    
    return false
end
function e_faterandomdelay:execute()
	local minWait = tonumber(gFateRandomDelayMin) * 1000
	local maxWait = tonumber(gFateRandomDelayMax) * 1000
	
	ml_task_hub:CurrentTask():SetDelay(math.random(minWait,maxWait))
	ml_task_hub:ThisTask().randomDelayCompleted = true
	d("Random delay commenced.")
end

c_add_fatetarget = inheritsFrom( ml_cause )
e_add_fatetarget = inheritsFrom( ml_effect )
c_add_fatetarget.oocCastTimer = 0
function c_add_fatetarget:evaluate()
	if (not Player.incombat) then
		if (SkillMgr.Cast( Player, true)) then
			c_add_fatetarget.oocCastTimer = Now() + 1500
			return false
		end
		
		if (ActionList:IsCasting() or Now() < c_add_fatetarget.oocCastTimer) then
			return false
		end
	end
	
	local fate = GetFateByID(ml_task_hub:CurrentTask().fateid)
	if (ValidTable(fate)) then
		local myPos = Player.pos
		local fatePos = {x = fate.x, y = fate.y, z = fate.z}
		
		local dist = Distance3D(myPos.x,myPos.y,myPos.z,fatePos.x,fatePos.y,fatePos.z)
		if (not ffxiv_task_fate.RequiresSync(fate.level) or dist < fate.radius) then
			local target = GetNearestFateAttackable()
			if (ValidTable(target)) then
				if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0) then
					c_add_fatetarget.targetid = target.id
					return true
				end
			end
		end
	end
	
	if (gFateKillAggro == "1") then
		local aggro = GetNearestAggro()
		if ValidTable(aggro) then
			if (aggro.hp.current > 0 and aggro.id and aggro.id ~= 0 and aggro.distance <= 30) then
				c_add_fatetarget.targetid = aggro.id
				return true
			end
		end 
	end
    
    return false
end
function e_add_fatetarget:execute()
	local newTask = ffxiv_task_grindCombat.Create()
	newTask.targetid = c_add_fatetarget.targetid
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

function ffxiv_task_fate:Init()
    --init processoverwatch 
	local ke_fateEnd = ml_element:create( "FateEnd", c_endfate, e_endfate, 100)
    self:add( ke_fateEnd, self.overwatch_elements)
	
	local ke_updateFate = ml_element:create( "UpdateFateDetails", c_updatefate, e_updatefate, 90 )
    self:add( ke_updateFate, self.overwatch_elements)
	
	local ke_teleToFate = ml_element:create( "TeleportToFate", c_teletofate, e_teletofate, 70 )
    self:add( ke_teleToFate, self.overwatch_elements)
	
    local ke_betterFate = ml_element:create( "BetterFateSearch", c_betterfatesearch, e_betterfatesearch, 60 )
    self:add( ke_betterFate, self.overwatch_elements)
            
    local ke_syncFate = ml_element:create( "SyncFateLevel", c_syncfatelevel, e_syncfatelevel, 50 )
    self:add( ke_syncFate, self.overwatch_elements)
	
	--local ke_resetTarget = ml_element:create( "ResetTarget", c_resettarget, e_resettarget, 3 )
	--self:add( ke_resetTarget, self.overwatch_elements)
    
    --init process    	
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 90 )
    self:add( ke_rest, self.process_elements)
	
	local ke_fateRandomDelay = ml_element:create( "RandomFateDelay", c_faterandomdelay, e_faterandomdelay, 80 )
    self:add( ke_fateRandomDelay, self.process_elements)
        
    local ke_addKillTarget = ml_element:create( "AddFateTarget", c_add_fatetarget, e_add_fatetarget, 60 )
    self:add(ke_addKillTarget, self.process_elements)
    
	local ke_moveToFate = ml_element:create( "MoveToFate", c_movetofate, e_movetofate, 50 )
    self:add( ke_moveToFate, self.process_elements)
	
    local ke_moveWithFate = ml_element:create( "MoveWithFate", c_movewithfate, e_movewithfate, 45 )
    self:add( ke_moveWithFate, self.process_elements)
	
	local ke_moveChainFate = ml_element:create( "MoveChainFate", c_movetochainlocation, e_movetochainlocation, 40 )
    self:add( ke_moveChainFate, self.process_elements)
end

c_endfate = inheritsFrom( ml_cause )
e_endfate = inheritsFrom( ml_effect )
function c_endfate:evaluate()
	if (ml_task_hub:ThisTask().waitingForChain) then
		return false
	end
	
    local fate = GetFateByID(ml_task_hub:ThisTask().fateid)
    if (not fate or fate.completion > 99) then
        return true
    end
	
	if (not IsFateApproved(fate.id)) then
		d("FATE "..tostring(fate.id).." no longer meets its approval requirements, task ending.")
		return true
	end
    
    return false
end
function e_endfate:execute()
	local isChain, isFirst, isLast, nextFate = ffxiv_task_fate.IsChain(Player.localmapid,ml_task_hub:ThisTask().fateid)
	if (isChain and not isLast and ValidTable(nextFate)) then
		Player:Stop()
		ml_task_hub:ThisTask().fateid = nextFate.id
		ml_task_hub:ThisTask().waitingForChain = true
		ml_task_hub:ThisTask().nextFate = nextFate
	else
		ffxiv_task_grind.inFate = false
		Player:Stop()
		ml_task_hub:ThisTask().completed = true
		ml_task_hub:ThisTask():DeleteSubTasks()
		ml_task_hub:ThisTask():ParentTask():SetDelay(1000)
		ml_global_information.suppressRestTimer = Now() + 10000
	end
end

function ffxiv_task_fate.RequiresSync(fateLevel)
	local fateLevel = tonumber(fateLevel) or 0
	local playerLevel = Player.level
	
	local requiresSync = false
	if (fateLevel > 0) then
		if (fateLevel < 50) then
			if ((fateLevel < (playerLevel - 5)) or Player.level > 50) then
				requiresSync = true
			end
		else
			if (fateLevel < (playerLevel - 4)) then
				requiresSync = true
			end
		end
	end
		
	return requiresSync
end

function ffxiv_task_fate.IsHighPriority(mapid, fateid)
	local mapid = tonumber(mapid) or 0
	local fateid = tonumber(fateid) or 0
	
	local highPriority = {
		[147] = "643,644,645,646",
		[155] = "501,502,503,504",
	}
	
	local mapPriority = highPriority[mapid]
	if (mapPriority) then
		return MultiComp(fateid,mapPriority)
	end
	
	return false
end

function ffxiv_task_fate.IsChain(mapid, fateid)
	local mapid = tonumber(mapid) or 0
	local fateid = tonumber(fateid) or 0
	
	local chains = {
		[155] = {
			[1] = {
				{ id = 501, x = 278.2, y = 338.7, z = -505.9 },
				{ id = 502, x = 261.5, y = 359.2, z = -662.6 },
				{ id = 503, x = 263.0, y = 359.2, z = -663.6 },
				{ id = 504, x = 263.0, y = 359.2, z = -663.6 },
			},
		},
		[147] = {
			[1] = {
				{ id = 643, x = 255.6, y = 25, z = 45.5 },
				{ id = 644, x = 255.6, y = 25, z = 10 },
				{ id = 645, x = 255.6, y = 25, z = 10 },
				{ id = 646, x = 255.6, y = 25, z = 10 },
			},
		},
	}
	
	local mapChains = chains[mapid]
	if (mapChains) then
		for chainid,chaindata in pairs(mapChains) do
			for order,fatedata in pairs(chaindata) do
				if (fatedata.id == fateid) then
					local firstChain = (order == 1)
					local lastChain = (order == TableSize(chaindata))
					local nextFate = nil
					
					if (not lastChain) then
						if (chaindata[order+1]) then
							nextFate = chaindata[order+1]
						end
					end
					
					--d("Is this the last chain member? "..tostring(lastChain))
					return true, firstChain, lastChain, nextFate
				end
			end
		end
	end
	
	return false, nil, nil
end

function ffxiv_task_fate.BlacklistInitUI()
    GUI_NewNumeric(ml_blacklist_mgr.mainwindow.name,GetString("fateIndex"),"gFateIndex",GetString("addEntry"),"1","5")
    GUI_NewField(ml_blacklist_mgr.mainwindow.name,GetString("fateName"),"gFateName",GetString("addEntry"))
    GUI_NewButton(ml_blacklist_mgr.mainwindow.name, GetString("blacklistFate"), "gBlacklistFateAddEvent", GetString("addEntry"))
    RegisterEventHandler("gBlacklistFateAddEvent", ffxiv_task_grind.BlacklistFate)
end

function ffxiv_task_fate.WhitelistInitUI()
    GUI_NewField(ml_blacklist_mgr.mainwindow.name,GetString("fateName"),"gWhitelistFateName",GetString("addEntry"))
	GUI_NewField(ml_blacklist_mgr.mainwindow.name,"Map ID","gFateMapID",GetString("addEntry"))
    GUI_NewButton(ml_blacklist_mgr.mainwindow.name, GetString("blacklistFate"), "gWhitelistFateAddEvent", GetString("addEntry"))
    RegisterEventHandler("gWhitelistFateAddEvent", ffxiv_task_grind.WhitelistFate)
end

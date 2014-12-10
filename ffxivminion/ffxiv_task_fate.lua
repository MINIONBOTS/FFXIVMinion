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
	newinst.targetid = 0
    newinst.targetFunction = GetNearestFateAttackable
	newinst.killFunction = ffxiv_task_grindCombat
	
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
    local myPos = Player.pos
    local gotoPos = ml_marker_mgr.markerList["evacPoint"]
    return  gFatesOnly == "1" and gDoFates == "1" and TableSize(gotoPos) > 0 and 
            NavigationManager:IsOnMesh(gotoPos.x, gotoPos.y, gotoPos.z) and
            Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z) > 15 and
			ml_task_hub:CurrentTask().name == "LT_GRIND"
end
function e_fatewait:execute()
    local newTask = ffxiv_task_movetopos.Create()
    local evacPoint = ml_marker_mgr.markerList["evacPoint"]
    local newPos = NavigationManager:GetRandomPointOnCircle(evacPoint.x,evacPoint.y,evacPoint.z,1,5)
    if (ValidTable(newPos)) then
        newTask.pos = {x = newPos.x, y = newPos.y, z = newPos.z}
    else
        newTask.pos = {x = evacPoint.x, y = evacPoint.y, z = evacPoint.z}
    end
    
    newTask.remainMounted = true
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
    if (ffxiv_task_grind.inFate or TimeSince(c_betterfatesearch.timer) < 10000) then
        return false
    end
    
    local myPos = Player.pos
    local fate = GetClosestFate(myPos)
	if (ValidTable(fate)) then
		if (fate.id ~= ml_task_hub:ThisTask().fateid) then
			c_betterfatesearch.timer = Now()
			e_betterfatesearch.fateid = fate.id
			return true	
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
	if (gTeleport == "0") then
		return false
	end

	local players = EntityList("type=1,maxdistance=30")
	local nearbyPlayers = TableSize(players)
	if nearbyPlayers > 0 then
		ml_debug("Can't teleport, nearby players = "..tostring(nearbyPlayers))
		return false
	end
	
	if (tonumber(gFateTeleportPercent) == 0 and gTeleport == "0") then
		ml_debug("Can't teleport, it's turned off.")
		return false
	end
	
	if Now() < c_teletofate.lastTele then
		ml_debug("Can't teleport, not enough time has passed.")
		return false
	end
	
    if ( ml_task_hub:ThisTask().fateid ~= nil and ml_task_hub:ThisTask().fateid ~= 0 ) then
        local fate = GetFateByID(ml_task_hub:ThisTask().fateid)
        if (fate ~= nil and TableSize(fate) > 0) then
			local percent = tonumber(gFateTeleportPercent)
			if (gTeleport == "1" and percent == 0) then
				--use a default completion percentage to enable fate teleport to match checkbox
				percent = 10
			end
			
			if fate.completion > percent then
				local myPos = Player.pos
				local fatePos = {x = fate.x, y = fate.y, z = fate.z}
				local dest,dist = NavigationManager:GetClosestPointOnMesh(fatePos,false)
				
				if (dist < 3) then
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
	local newPos = NavigationManager:GetRandomPointOnCircle(dest.x,dest.y,dest.z,5,c_teletofate.radius)
	
	if (newPos) then
		GameHacks:TeleportToXYZ(newPos.x,newPos.y,newPos.z)
	else
		GameHacks:TeleportToXYZ(dest.x,dest.y,dest.z)
	end
	Player:SetFacingSynced(Player.pos.h)
	c_teletofate.lastTele = Now() + 10000
	ffxiv_task_grind.inFate = true
end

-----------------------------------------------------------------------------------------------
--MOVETOFATE: If (current fate distance > fate.radius) Then (add movetofate task)
--Moves within range of fate specified by ml_task_hub:CurrentTask().fateid
---------------------------------------------------------------------------------------------
c_movetofate = inheritsFrom( ml_cause )
e_movetofate = inheritsFrom( ml_effect )
function c_movetofate:evaluate()
    if ( ml_task_hub:ThisTask().fateid ~= nil and ml_task_hub:ThisTask().fateid ~= 0 ) then
        local fate = GetFateByID(ml_task_hub:ThisTask().fateid)
		
        if (ValidTable(fate)) then
            local myPos = Player.pos
            local distance = Distance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z)
            if ( ml_task_hub:ThisTask().moving) then
                if (distance > fate.radius/4) then				
                    return true
                end
            else
                if (distance > fate.radius) then				
                    return true
                end
            end
        end
		
    end
    
    return false
end
function e_movetofate:execute()
    local fate = GetFateByID(ml_task_hub:ThisTask().fateid)
    if (ValidTable(fate)) then
        local newTask = ffxiv_task_movetopos.Create()
		newTask.remainMounted = true
        newTask.pos = {x = fate.x, y = fate.y, z = fate.z}
		
        if ( ml_task_hub:ThisTask().moving) then
            newTask.range = math.random(3, fate.radius * .25)
        else
            newTask.range = 4
        end
        ml_task_hub:ThisTask():AddSubTask(newTask)
    end
end

c_atfate = inheritsFrom( ml_cause )
e_atfate = inheritsFrom( ml_effect )
function c_atfate:evaluate()
    if (ml_task_hub:CurrentTask().name == "MOVETOPOS" and ml_task_hub:ThisTask().subtask == ml_task_hub:CurrentTask()) then
        if ( ml_task_hub:ThisTask().fateid ~= nil and ml_task_hub:ThisTask().fateid ~= 0 ) then
            local fate = GetFateByID(ml_task_hub:ThisTask().fateid)
            if (ValidTable(fate)) then
                -- check to see if we have to sync for this fate...if we do, then we can't stop outside the radius for a target
                local plevel = Player.level
                if (fate.level < plevel - 5) then
                    return false
                end
                
                -- check for fate targets within combat range and stop if we find one instead of running into fate
                local el = EntityList("shortestpath,alive,attackable,onmesh,maxpathdistance="..tostring(ml_global_information.AttackRange)..",fateid="..tostring(fate.id))
                if ( el ) then
                    local i,e = next(el)
                    if (i~=nil and e~=nil) then
                        return ValidTable(e)
                    end
                end	
            end
        end
    end
    return false
end
function e_atfate:execute()
    --Player:Stop()
    -- call the complete logic so that bot will dismount
    -- stay mounted since we have a target and we want to continue running to it
    ml_task_hub:CurrentTask().remainMounted = true
    ml_task_hub:CurrentTask():task_complete_execute()
    ml_task_hub:CurrentTask():Terminate()
	ffxiv_task_grind.inFate = true
end

---------------------------------------------------------------------------------------------
--SyncFateLevel
---------------------------------------------------------------------------------------------
c_syncfatelevel = inheritsFrom( ml_cause )
e_syncfatelevel = inheritsFrom( ml_effect )
c_syncfatelevel.throttle = 1000
function c_syncfatelevel:evaluate()
    if (Player:GetSyncLevel() ~= 0) then
        return false
    end
	
    local myPos = Player.pos
	local fateID = ml_task_hub:ThisTask().fateid
	local fate = GetFateByID(fateID)
	if ( fate and TableSize(fate)) then
		local plevel = Player.level
		if (fate.level < (plevel - 5))then
			local myPos = Player.pos
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
end

c_movingfate = inheritsFrom( ml_cause )
e_movingfate = inheritsFrom( ml_effect )
function c_movingfate:evaluate()
    if ( ml_task_hub:ThisTask().moving) then
        return false
    end
    
    if ( ml_task_hub:ThisTask().fateid ~= nil and ml_task_hub:ThisTask().fateid ~= 0 ) then
        local fate = GetFateByID(ml_task_hub:ThisTask().fateid)
        if (ValidTable(fate)) then
            local fatePos = {x = fate.x, y = fate.y, z = fate.z}
            if ( TableSize(ml_task_hub:ThisTask().fatePos) == 0 ) then
                ml_task_hub:ThisTask().fatePos = fatePos
                return false
            else
                local oldFatePos = ml_task_hub:ThisTask().fatePos
                local distance = Distance2D(oldFatePos.x, oldFatePos.z, fatePos.x, fatePos.z)
                if (distance > 0) then
                    return true
                end
            end
        end
    end
    
    return false
end
function e_movingfate:execute()
    ml_task_hub:ThisTask().moving = true
end

c_resettarget = inheritsFrom( ml_cause )
e_resettarget = inheritsFrom( ml_effect )
function c_resettarget:evaluate()
	local subtask = ml_task_hub:ThisTask().subtask
	local fate = GetFateByID(ml_task_hub:ThisTask().fateid)
	
	if (ValidTable(fate)) then
		if (subtask and subtask.name == "GRIND_COMBAT" and subtask.targetid and subtask.targetid > 0) then
			if (Player:GetSyncLevel() ~= 0 or (Player:GetSyncLevel() == 0 and (fate.level < (Player.level - 5)))) then
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

function ffxiv_task_fate:Init()
    --init processoverwatch 
	local ke_teleToFate = ml_element:create( "TeleportToFate", c_teletofate, e_teletofate, 16 )
    self:add( ke_teleToFate, self.overwatch_elements)
	
    local ke_betterFate = ml_element:create( "BetterFateSearch", c_betterfatesearch, e_betterfatesearch, 15 )
    self:add( ke_betterFate, self.overwatch_elements)
            
    local ke_syncFate = ml_element:create( "SyncFateLevel", c_syncfatelevel, e_syncfatelevel, 10 )
    self:add( ke_syncFate, self.overwatch_elements)
    
    local ke_atFate = ml_element:create( "AtFate", c_atfate, e_atfate, 5 )
    self:add( ke_atFate, self.overwatch_elements)
	
	local ke_resetTarget = ml_element:create( "ResetTarget", c_resettarget, e_resettarget, 3 )
	self:add( ke_resetTarget, self.overwatch_elements)
    
    --init process
    local ke_movingFate = ml_element:create( "SetFateMovingFlag", c_movingfate, e_movingfate, 30 )
    self:add( ke_movingFate, self.process_elements)
    
    --local ke_quitFate = ml_element:create( "QuitFate", c_fatequit, e_fatequit, 25 )
    --self:add( ke_quitFate, self.process_elements)
    
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 20 )
    self:add( ke_rest, self.process_elements)
        
    local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_killtarget, e_add_killtarget, 15 )
    self:add(ke_addKillTarget, self.process_elements)
    
    local ke_moveToFate = ml_element:create( "MoveToFate", c_movetofate, e_movetofate, 5 )
    self:add( ke_moveToFate, self.process_elements)
	
	--local ke_KillAggroTarget = ml_element:create( "KillAggroTarget", c_killaggrotarget, e_killaggrotarget, 2 )
	--self:add(ke_KillAggroTarget, self.process_elements)
    
    self:AddOverwatchTaskCheckCEs()
end

function ffxiv_task_fate:task_complete_eval()
    local fate = GetFateByID(self.fateid)
    if (fate == nil) then
        return true
    end
    
    return false
end

function ffxiv_task_fate:task_complete_execute()
	Player:Stop()
	ffxiv_task_grind.inFate = false
	self:Terminate()
	self:ParentTask():SetDelay(6000)
end


function ffxiv_task_fate.BlacklistInitUI()
    GUI_NewNumeric(ml_blacklist_mgr.mainwindow.name,strings[gCurrentLanguage].fateIndex,"gFateIndex",strings[gCurrentLanguage].addEntry,"1","5")
    GUI_NewField(ml_blacklist_mgr.mainwindow.name,strings[gCurrentLanguage].fateName,"gFateName",strings[gCurrentLanguage].addEntry)
    GUI_NewButton(ml_blacklist_mgr.mainwindow.name, strings[gCurrentLanguage].blacklistFate, "gBlacklistFateAddEvent", strings[gCurrentLanguage].addEntry)
    RegisterEventHandler("gBlacklistFateAddEvent", ffxiv_task_grind.BlacklistFate)
end

function ffxiv_task_fate.WhitelistInitUI()
    GUI_NewNumeric(ml_blacklist_mgr.mainwindow.name,strings[gCurrentLanguage].fateIndex,"gFateIndex",strings[gCurrentLanguage].addEntry,"1","5")
    GUI_NewField(ml_blacklist_mgr.mainwindow.name,strings[gCurrentLanguage].fateName,"gFateName",strings[gCurrentLanguage].addEntry)
	GUI_NewField(ml_blacklist_mgr.mainwindow.name,"Map ID","gFateMapID",strings[gCurrentLanguage].addEntry)
    GUI_NewButton(ml_blacklist_mgr.mainwindow.name, strings[gCurrentLanguage].blacklistFate, "gWhitelistFateAddEvent", strings[gCurrentLanguage].addEntry)
    RegisterEventHandler("gWhitelistFateAddEvent", ffxiv_task_grind.WhitelistFate)
end

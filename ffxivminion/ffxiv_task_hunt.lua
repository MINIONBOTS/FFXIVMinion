ffxiv_task_hunt = inheritsFrom(ml_task)
ffxiv_task_hunt.rankS = "2953;2954;2955;2956;2957;2958;2959;2960;2961;2962;2963;2964;2965;2966;2967;2968;2969"
ffxiv_task_hunt.rankA = "2936;2937;2938;2939;2940;2941;2942;2943;2944;2945;2946;2947;2948;2949;2950;2951;2952"
ffxiv_task_hunt.rankB = "2919;2920;2921;2922;2923;2924;2925;2926;2927;2928;2929;2930;2931;2932;2933;2934;2935"

ffxiv_task_hunt.multiTargetID = 0
ffxiv_task_hunt.multiTargetMapID = 0
ffxiv_task_hunt.multiHasTarget = false
ffxiv_task_hunt.multiTargetLocation = {}
ffxiv_task_hunt.multiReturnMap = 0
ffxiv_task_hunt.hasTarget = false
ffxiv_task_hunt.location = 0
ffxiv_task_hunt.locationIndex = 0
ffxiv_task_hunt.locationTimer = 0

ffxiv_task_hunt.editwindow = {name = GetString("huntLocationEditor"), x = 0, y = 0, width = 250, height = 230}

function ffxiv_task_hunt.Create()
    local newinst = inheritsFrom(ffxiv_task_hunt)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_hunt members
    newinst.name = "LT_HUNT"
    newinst.lastTarget = 0
    newinst.markerTime = 0
    newinst.currentMarker = false
	newinst.filterLevel = false
	newinst.startMap = Player.localmapid
    newinst.atMarker = false
	
	ffxiv_task_hunt.multiHasTarget = false
	ffxiv_task_hunt.multiTrackingTarget = false
	ffxiv_task_hunt.multiTargetLocation = {}
	ffxiv_task_hunt.hasTarget = false
	ffxiv_task_hunt.locationTimer = 0
	ffxiv_task_hunt.location = 0
	ffxiv_task_hunt.locationIndex = 0

    return newinst
end

c_add_hunttarget = inheritsFrom( ml_cause )
e_add_hunttarget = inheritsFrom( ml_effect )
c_add_hunttarget.targetid = 0
c_add_hunttarget.rank = ""
c_add_hunttarget.name = ""
c_add_hunttarget.pos = {}
c_add_hunttarget.oocCastTimer = 0
function c_add_hunttarget:evaluate()
	if (ffxiv_task_hunt.multiTrackingTarget or ffxiv_task_hunt.multiHasTarget) then
		return false
	end
	
	if (ffxiv_task_hunt.hasTarget or ml_task_hub:CurrentTask().name == "LT_KILLTARGET") then
		return false
	end
	
	local parentTask = ""
	if (ml_task_hub:CurrentTask():ParentTask()) then
		parentTask = ml_task_hub:CurrentTask():ParentTask().name
	end
	
	--Only deal with aggro if we are not moving to a marker.
	if (ml_task_hub:CurrentTask().name ~= "MOVETOPOS" and ml_task_hub:CurrentTask().atMarker ) then
		local aggro = GetNearestAggro()
		if ValidTable(aggro) then
			if (aggro.hp.current > 0 and aggro.id and aggro.id ~= 0 and aggro.distance <= 30) then
				c_add_hunttarget.targetid = aggro.id
				return true
			end
		end 
	end
    
	if (ml_global_information.IsWaiting) then 
		return false 
	end
	
	if (SkillMgr.Cast( Player, true)) then
		c_add_hunttarget.oocCastTimer = Now() + 1500
		return false
	end
	
	if (IsPlayerCasting() or Now() < c_add_hunttarget.oocCastTimer) then
		return false
	end
	
    local rank, target = GetHuntTarget()
    if (ValidTable(target)) then
		c_add_hunttarget.name = target.name
		c_add_hunttarget.pos = target.pos
		c_add_hunttarget.rank = rank
		c_add_hunttarget.targetid = target.id
		return true
    end
    
    return false
end
function e_add_hunttarget:execute()	
	ml_task_hub:RootTask().atMarker = false
	
	if (c_add_hunttarget.rank ~= "" and c_add_hunttarget.name ~= "") then
		if (c_add_hunttarget.rank == "S" and gHuntSRankSound == "1") then
			GameHacks:PlaySound(37)
			GameHacks:PlaySound(37)
			GameHacks:PlaySound(37)
		elseif (c_add_hunttarget.rank == "A" and gHuntARankSound == "1") then
			GameHacks:PlaySound(36)
			GameHacks:PlaySound(36)
			GameHacks:PlaySound(36)
		elseif (c_add_hunttarget.rank == "B" and gHuntBRankSound == "1") then
			GameHacks:PlaySound(38)
			GameHacks:PlaySound(38)
			GameHacks:PlaySound(38)
		end
		
		--Using /tell to self for now, for testing.
		if (c_add_hunttarget.rank == "S" and gHuntSRankDoCommand == "1") then
			SendTextCommand(gHuntSRankCommandString)
		elseif (c_add_hunttarget.rank == "A" and gHuntARankDoCommand == "1") then
			SendTextCommand(gHuntARankCommandString)
		end
	end
	
    local newTask = ffxiv_task_killtarget.Create()
	Player:SetTarget(c_add_hunttarget.targetid)
    newTask.targetid = c_add_hunttarget.targetid
	newTask.rank = c_add_hunttarget.rank
	newTask.canEngage = false
	
	if (c_add_hunttarget.rank == "S") then
		newTask.failTimer = (tonumber(gHuntSRankMaxWait) * 1000)
		newTask.waitTimer = Now()
		newTask.safeDistance = 40
	elseif (c_add_hunttarget.rank == "A") then
		newTask.failTimer = (tonumber(gHuntARankMaxWait) * 1000)
		newTask.waitTimer = Now()
		newTask.safeDistance = 30
	else
		newTask.failTimer = nil
		newTask.waitTimer = Now()
		newTask.safeDistance = 2
		newTask.canEngage = true
	end
	
	--Communicate using the multibot server engine, if in use.
	if (gMultiBotEnabled == "1") then
		mb.BroadcastHuntStatus( Player.localmapid, c_add_hunttarget.pos )
	end
	
	--Reset the variables, just in case.
	c_add_hunttarget.targetid = 0
	c_add_hunttarget.rank = ""
	c_add_hunttarget.name = ""
	c_add_hunttarget.pos = ""
	
	Player:Stop()
	ffxiv_task_hunt.hasTarget = true
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_nexthuntmarker = inheritsFrom( ml_cause )
e_nexthuntmarker = inheritsFrom( ml_effect )
function c_nexthuntmarker:evaluate()

	if (ffxiv_task_hunt.multiTrackingTarget or ffxiv_task_hunt.multiHasTarget or ffxiv_task_hunt.hasTarget) then
		--d("Exiting hunt marker in condition 1.")
		return false
	end

    if (not ml_marker_mgr.markersLoaded) then
		--d("Exiting hunt marker in condition 1.")
        return false
    end
	
    if ( ml_task_hub:RootTask().currentMarker ~= nil and ml_task_hub:RootTask().currentMarker ~= 0 ) then
        local marker = nil
        
        -- first check to see if we have no initiailized marker
        if (ml_task_hub:RootTask().currentMarker == false) then --default init value
            marker = ml_marker_mgr.GetNextMarker(GetString("huntMarker"), ml_task_hub:RootTask().filterLevel)
        
			if (marker == nil) then
				ml_task_hub:RootTask().filterLevel = false
				marker = ml_marker_mgr.GetNextMarker(GetString("huntMarker"), ml_task_hub:RootTask().filterLevel)
			end	
		end
        
        -- next check to see if our level is out of range
        if (marker == nil) then
            if (ValidTable(ml_task_hub:RootTask().currentMarker)) then
                if 	(ml_task_hub:RootTask().filterLevel) and
					(Player.level < ml_task_hub:RootTask().currentMarker:GetMinLevel() or 
                    Player.level > ml_task_hub:RootTask().currentMarker:GetMaxLevel()) 
                then
                    marker = ml_marker_mgr.GetNextMarker(GetString("huntMarker"), ml_task_hub:RootTask().filterLevel)
                end
            end
        end
        
        -- last check if our time has run out
        if (marker == nil) then
			if (ValidTable(ml_task_hub:RootTask().currentMarker)) then
				local time = ml_task_hub:RootTask().currentMarker:GetTime() or 0
				if (time == 0 or (TimeSince(ml_task_hub:RootTask().markerTime) > time * 1000 and ml_task_hub:RootTask().atMarker)) then
					local myPos = Player.pos
					local pos = ml_task_hub:RootTask().currentMarker:GetPosition()
					local distance = PDistance3D(myPos.x, myPos.y, myPos.z, pos.x, pos.y, pos.z)
					
					if (distance <= 30) then
						marker = ml_marker_mgr.GetNextMarker(GetString("huntMarker"), ml_task_hub:CurrentTask().filterLevel)
					end
				else
					--d("Exiting hunt marker in condition 3.")
					return false
				end
			end
        end
		
        if (ValidTable(marker)) then
            e_nexthuntmarker.marker = marker
            return true
        end
    end
    
	--d("Exiting hunt marker in condition 4.")
    return false
end
function e_nexthuntmarker:execute()
	--If we find a new marker, set it as current marker, and immediately move to it.
	--Set atMarker to false until we get there so that the timer does not count down until we arrive at the marker.
	ml_task_hub:RootTask().atMarker = false
    ml_task_hub:RootTask().currentMarker = e_nexthuntmarker.marker
    ml_task_hub:RootTask().markerTime = Now()
	ml_global_information.MarkerTime = Now()
    ml_global_information.MarkerMinLevel = ml_task_hub:RootTask().currentMarker:GetMinLevel()
    ml_global_information.MarkerMaxLevel = ml_task_hub:RootTask().currentMarker:GetMaxLevel()
    ml_global_information.BlacklistContentID = ml_task_hub:RootTask().currentMarker:GetFieldValue(GetUSString("NOTcontentIDEquals"))
    ml_global_information.WhitelistContentID = ml_task_hub:RootTask().currentMarker:GetFieldValue(GetUSString("contentIDEquals"))
	gStatusMarkerName = ml_task_hub:RootTask().currentMarker:GetName()
	
	local markerPos = ml_task_hub:RootTask().currentMarker:GetPosition()
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = markerPos
	newTask.range = math.random(10,15)
	newTask.reason = "MOVE_HUNT_MARKER"
	newTask.use3d = true
	newTask.remainMounted = true
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_athuntmarker = inheritsFrom( ml_cause )
e_athuntmarker = inheritsFrom( ml_effect )
function c_athuntmarker:evaluate()
	if (ffxiv_task_hunt.multiTrackingTarget or ffxiv_task_hunt.multiHasTarget or ffxiv_task_hunt.hasTarget) then
		return false
	end
	
    if (ml_task_hub:RootTask().atMarker) then
        return false
    end
    
    if (ml_task_hub:RootTask().currentMarker ~= false and ml_task_hub:RootTask().currentMarker ~= nil) then
		if (ValidTable(ml_task_hub:RootTask().currentMarker)) then
			local time = ml_task_hub:RootTask().currentMarker:GetTime() or 0
			if (time == 0) then
				return false
			end
			
			local myPos = Player.pos
			local pos = ml_task_hub:RootTask().currentMarker:GetPosition()
			local distance = PDistance3D(myPos.x, myPos.y, myPos.z, pos.x, pos.y, pos.z)
			
			if (distance <= 15) then
				return true
			end
		end
    end
    
    return false
end
function e_athuntmarker:execute()
	ml_task_hub:RootTask().markerTime = Now()
	ml_global_information.MarkerTime = Now()
	ml_task_hub:RootTask().atMarker = true
end

c_huntquit = inheritsFrom( ml_cause )
e_huntquit = inheritsFrom( ml_effect )
function c_huntquit:evaluate()
    if ( ml_task_hub:RootTask().name == "LT_HUNT" and ml_task_hub:RootTask().subtask and ml_task_hub:RootTask().subtask.name == "LT_KILLTARGET" ) then		
		local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
		if (ml_task_hub:CurrentTask().failTimer and ml_task_hub:CurrentTask().failTimer ~= 0 and Now() > ml_task_hub:CurrentTask().failTimer) then
			if 	(not target or not target.attackable or 
				(target and not target.alive) or 
				(target and not target.onmesh and not target.los)) then
				return true
			elseif (ml_task_hub:CurrentTask().rank == "S") then
				local allies = EntityList("alive,friendly,chartype=4,targetable,maxdistance=50")
				if ((target.hp.percent >= tonumber(gHuntSRankHP)) and (not allies or TableSize(allies) < tonumber(gHuntSRankAllies))) then
					return true
				end
			elseif (ml_task_hub:CurrentTask().rank == "A") then
				local allies = EntityList("alive,friendly,chartype=4,targetable,maxdistance=50")
				if ((target.hp.percent >= tonumber(gHuntARankHP)) and (not allies or TableSize(allies) < tonumber(gHuntARankAllies))) then
					return true
				end
			end
		end
    end
    
    return false
end
function e_huntquit:execute()
    if ( ml_task_hub:CurrentTask().targetid and ml_task_hub:CurrentTask().targetid ~= 0 ) then
        -- blacklist hunt target for 5 minutes and terminate task
        local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
		ml_blacklist.AddBlacklistEntry(GetString("monsters"), target.contentid, target.name, Now() + 300*1000)
        d("Temporarily blacklisted:"..target.name)
        ml_task_hub:CurrentTask():Terminate()
		ffxiv_task_hunt.hasTarget = false
    end
end

c_nexthuntlocation = inheritsFrom( ml_cause )
e_nexthuntlocation = inheritsFrom( ml_effect )
c_nexthuntlocation.location = {}
c_nexthuntlocation.locationIndex = 0
function c_nexthuntlocation:evaluate()		
	--If we are tracking a multibot target, don't run this.
	if (ffxiv_task_hunt.multiTrackingTarget or ffxiv_task_hunt.multiHasTarget) then
		return false
	end
	
	local locations = gHuntLocations
	--First check to see if we are on a valid starting map, and if we are, start here.
	if (ffxiv_task_hunt.locationIndex == 0 and ffxiv_task_hunt.location == 0) then
		local startHere = false
		for i, location in spairs(locations) do
			if (location.mapid == Player.localmapid) then
				startHere = true
			end
			if (startHere) then
				ffxiv_task_hunt.location = location.mapid
				ffxiv_task_hunt.locationIndex = tonumber(i)
				ffxiv_task_hunt.locationTimer = Now() + (tonumber(location.timer) * 60 * 1000)
				return false
			end
		end
	end
	
	local maxLocation = TableSize(locations)
	if (Now() > ffxiv_task_hunt.locationTimer and not ffxiv_task_hunt.hasTarget and maxLocation > 1) then
		
		local newLocation = {}
		
		if (ffxiv_task_hunt.locationIndex == maxLocation and maxLocation > 1) then
			--We're at the last location, so use the first.
			newLocation = locations["1"]
			--Verify that there is infact an aetheryte that we can teleport to here.
			local aetherytes = Player:GetAetheryteList()
			for i, aetheryte in pairs(aetherytes) do
				if tonumber(aetheryte.territory) == newLocation.mapid then
					newLocation.teleport = aetheryte.id
					c_nexthuntlocation.location = newLocation
					c_nexthuntlocation.locationIndex = 1
					return true
				end
			end			
		else
			newLocation = locations[tostring(ffxiv_task_hunt.locationIndex + 1)]
			local aetherytes = Player:GetAetheryteList()
			for i, aetheryte in pairs(aetherytes) do
				if tonumber(aetheryte.territory) == newLocation.mapid then
					newLocation.teleport = aetheryte.id
					c_nexthuntlocation.location = newLocation
					c_nexthuntlocation.locationIndex = (ffxiv_task_hunt.locationIndex + 1)
					return true
				end
			end	
		end
	end
	
	return false
end
function e_nexthuntlocation:execute()
	--ml_task_hub:Add(task.Create(), LONG_TERM_GOAL, TP_ASAP) REACTIVE_GOAL or IMMEDIATE_GOAL
	local location = c_nexthuntlocation.location
	Player:Stop()
	Dismount()
	
	if (Player.ismounted) then
		return
	end
	
	if (ml_task_hub:CurrentTask().name ~= "LT_TELEPORT" and ActionIsReady(5)) then
		Player:Teleport(location.teleport)
	
		ffxiv_task_hunt.location = location.mapid
		ffxiv_task_hunt.locationIndex = c_nexthuntlocation.locationIndex
		ffxiv_task_hunt.locationTimer = Now() + (tonumber(location.timer) * 60 * 1000) + 15000 -- Add on 15 seconds for teleport time.
				
		local newTask = ffxiv_task_teleport.Create()
		newTask.aetheryte = location.teleport
		newTask.mapID = location.mapid
		ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_ASAP)
	end
end

c_multibotdetect = inheritsFrom( ml_cause )
e_multibotdetect = inheritsFrom( ml_effect )
function c_multibotdetect:evaluate()	
	if (gMultiBotEnabled == "0") then
		return false
	end
	
	--Don't run this if we're currently already tracking a target.
	if ( ml_task_hub:RootTask().name == "LT_HUNT" and ml_task_hub:RootTask().subtask and ml_task_hub:RootTask().subtask.name == "LT_KILLTARGET" ) then
		return false
	end
	
	--At this point, we should be free to kill a new target.
	--Last check is to make sure we can teleport to the given location.
	if (ffxiv_task_hunt.multiHasTarget) then
		if (Player.localmapid ~= ffxiv_task_hunt.multiTargetMapID) then
			local newLocation = {}
			local aetherytes = Player:GetAetheryteList()
			for i, aetheryte in pairs(aetherytes) do
				if tonumber(aetheryte.territory) == ffxiv_task_hunt.multiTargetMapID then
					newLocation.mapid = ffxiv_task_hunt.multiTargetMapID
					newLocation.teleport = aetheryte.id
					newLocation.x = ffxiv_task_hunt.multiTargetLocation[3]
					newLocation.y = ffxiv_task_hunt.multiTargetLocation[4]
					newLocation.z = ffxiv_task_hunt.multiTargetLocation[5]
					newLocation.h = ffxiv_task_hunt.multiTargetLocation[6]
					newLocation.targetid = ffxiv_task_hunt.multiTargetID
					
					c_nexthuntlocation.location = newLocation
					return true
				end
			end		
		end
	end
	
	return false
end
function e_multibotdetect:execute()
	--ml_task_hub:Add(task.Create(), LONG_TERM_GOAL, TP_ASAP) REACTIVE_GOAL or IMMEDIATE_GOAL
	local location = c_nexthuntlocation.location
	
	if (Player.localmapid ~= ffxiv_task_hunt.multiTargetMapID) then
		Player:Stop()
		Dismount()
		ffxiv_task_hunt.multiReturnMap = Player.localmapid
		
		if (Player.ismounted) then
			return
		end
		
		if (Player.castinginfo.channelingid ~= 5) then
			Player:Teleport(location.teleport)
		elseif (Player.castinginfo.channelingid == 5) then
			ffxiv_task_hunt.location = location.mapid
					
			local newTask = ffxiv_task_teleport.Create()
			newTask.aetheryte = location.teleport
			newTask.mapID = location.mapid
			ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_ASAP)
		end
	else
		
		ffxiv_task_hunt.multiTrackingTarget = true
		ffxiv_task_hunt.multiHasTarget = false
	end
end

function ffxiv_task_hunt:Init()    
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 25 )
    self:add(ke_dead, self.overwatch_elements)
    
    local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 15 )
    self:add(ke_flee, self.overwatch_elements)
    
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 14 )
    self:add(ke_rest, self.overwatch_elements)
	
	local ke_nextLocation = ml_element:create( "NextLocation", c_nexthuntlocation, e_nexthuntlocation, 13 )
    self:add(ke_nextLocation, self.overwatch_elements)
	
	local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_hunttarget, e_add_hunttarget, 12 )
    self:add(ke_addKillTarget, self.overwatch_elements)

	local ke_atMarker = ml_element:create( "AtMarker", c_athuntmarker, e_athuntmarker, 10 )
    self:add(ke_atMarker, self.overwatch_elements)
	
    local ke_nextMarker = ml_element:create( "NextMarker", c_nexthuntmarker, e_nexthuntmarker, 9 )
    self:add(ke_nextMarker, self.overwatch_elements)
	
	local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 25 )
    self:add(ke_returnToMarker, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_hunt.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gHuntMapID" or
				k == "gHuntMapTimer" or
				k == "gHuntMarkerStyle" or
				k == "gHuntSRankHP" or
				k == "gHuntSRankAllies" or
				k == "gHuntSRankMaxWait" or
				k == "gHuntSRankDoCommand" or
				k == "gHuntSRankSound" or
				k == "gHuntARankHP" or
				k == "gHuntARankAllies" or
				k == "gHuntARankMaxWait" or
				k == "gHuntARankDoCommand" or
				k == "gHuntARankSound" or
				k == "gHuntBRankHuntID" or
				k == "gHuntBRankHuntAny" or
				k == "gHuntBRankSound" or
				k == "gHuntSRankHunt" or
				k == "gHuntARankHunt" or 
				k == "gHuntBRankHunt" or
				k == "gHuntSRankHunt"
				)
		then
            SafeSetVar(tostring(k),v)
        end
    end
    GUI_RefreshWindow(GetString("huntMode"))
end

function ffxiv_task_hunt.UIInit()
	ffxivminion.Windows.Hunt = { id = strings["us"].huntMode, Name = GetString("huntMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Hunt)

	if (Settings.FFXIVMINION.gHuntLocations == nil) then
		Settings.FFXIVMINION.gHuntLocations = {}
	end
	if ( Settings.FFXIVMINION.gHuntMapID == nil ) then
		Settings.FFXIVMINION.gHuntMapID = ""
	end
	if ( Settings.FFXIVMINION.gHuntMapTimer == nil ) then
		Settings.FFXIVMINION.gHuntMapTimer = ""
	end
	if ( Settings.FFXIVMINION.gHuntMarkerStyle == nil ) then
		Settings.FFXIVMINION.gHuntMarkerStyle = "Marker List"
	end
	if ( Settings.FFXIVMINION.gHuntSRankHP == nil ) then
		Settings.FFXIVMINION.gHuntSRankHP = 1
	end
	if ( Settings.FFXIVMINION.gHuntSRankAllies == nil ) then
		Settings.FFXIVMINION.gHuntSRankAllies = 12
	end
	if ( Settings.FFXIVMINION.gHuntSRankMaxWait == nil ) then
		Settings.FFXIVMINION.gHuntSRankMaxWait = 120
	end
	if ( Settings.FFXIVMINION.gHuntSRankDoCommand == nil ) then
		Settings.FFXIVMINION.gHuntSRankDoCommand = "0"
	end
	if ( Settings.FFXIVMINION.gHuntSRankCommandString == nil ) then
		Settings.FFXIVMINION.gHuntSRankCommandString = ""
	end
	if ( Settings.FFXIVMINION.gHuntSRankSound == nil ) then
		Settings.FFXIVMINION.gHuntSRankSound = "0"
	end
	if ( Settings.FFXIVMINION.gHuntARankHP == nil ) then
		Settings.FFXIVMINION.gHuntARankHP = 1
	end
	if ( Settings.FFXIVMINION.gHuntARankAllies == nil ) then
		Settings.FFXIVMINION.gHuntARankAllies = 2
	end
	if ( Settings.FFXIVMINION.gHuntARankMaxWait == nil ) then
		Settings.FFXIVMINION.gHuntARankMaxWait = 120
	end
	if ( Settings.FFXIVMINION.gHuntARankDoCommand == nil ) then
		Settings.FFXIVMINION.gHuntARankDoCommand = "0"
	end
	if ( Settings.FFXIVMINION.gHuntARankCommandString == nil ) then
		Settings.FFXIVMINION.gHuntARankCommandString = ""
	end
	if ( Settings.FFXIVMINION.gHuntARankSound == nil ) then
		Settings.FFXIVMINION.gHuntARankSound = "0"
	end
	if ( Settings.FFXIVMINION.gHuntBRankHuntAny == nil ) then
		Settings.FFXIVMINION.gHuntBRankHuntAny = ""
	end
	if ( Settings.FFXIVMINION.gHuntBRankHuntID == nil ) then
		Settings.FFXIVMINION.gHuntBRankHuntID = ""
	end
	if ( Settings.FFXIVMINION.gHuntBRankSound == nil ) then
		Settings.FFXIVMINION.gHuntBRankSound = ""
	end
	if ( Settings.FFXIVMINION.gHuntBRankHunt == nil ) then
		Settings.FFXIVMINION.gHuntBRankHunt = "1"
	end
	if ( Settings.FFXIVMINION.gHuntARankHunt == nil ) then
		Settings.FFXIVMINION.gHuntARankHunt = "1"
	end
	if ( Settings.FFXIVMINION.gHuntSRankHunt == nil ) then
		Settings.FFXIVMINION.gHuntSRankHunt = "1"
	end
	
	if ( Settings.FFXIVMINION.gHuntLocation == nil ) then
		Settings.FFXIVMINION.gHuntLocation = ""
	end
	if ( Settings.FFXIVMINION.gHuntMonsterS == nil ) then
		Settings.FFXIVMINION.gHuntMonsterS = ""
	end
	if ( Settings.FFXIVMINION.gHuntMonsterA == nil ) then
		Settings.FFXIVMINION.gHuntMonsterA = ""
	end
	if ( Settings.FFXIVMINION.gHuntMonsterB == nil ) then
		Settings.FFXIVMINION.gHuntMonsterB = ""
	end
	
	local winName = GetString("huntMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	GUI_NewButton(winName, GetString("markerManager"), "ToggleMarkerMgr")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,GetString("navmesh") ,"gmeshname",group,ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
	GUI_NewField(winName,GetString("markerName"),"gStatusMarkerName",group )
	GUI_NewField(winName,GetString("markerTime"),"gStatusMarkerTime",group )

	GUI_NewCheckbox(winName,"Do S Rank",		"gHuntSRankHunt",	"S-Rank Hunt")
    GUI_NewNumeric(winName,"HP % <=",			"gHuntSRankHP",		"S-Rank Hunt")
	GUI_NewNumeric(winName,"Nearby Allies >",	"gHuntSRankAllies", "S-Rank Hunt")
	GUI_NewNumeric(winName,"Max Wait (s)",		"gHuntSRankMaxWait", "S-Rank Hunt")
	GUI_NewCheckbox(winName,"Play Sound",		"gHuntSRankSound", "S-Rank Hunt")
	GUI_NewCheckbox(winName,"Perform Command",	"gHuntSRankDoCommand", "S-Rank Hunt")
	GUI_NewField(winName,"Text Command",		"gHuntSRankCommandString", "S-Rank Hunt")
	
	GUI_NewCheckbox(winName,"Do A Rank",		"gHuntARankHunt",	"A-Rank Hunt")
	GUI_NewNumeric(winName,"HP % <=",			"gHuntARankHP",		"A-Rank Hunt")
	GUI_NewNumeric(winName,"Nearby Allies >",	"gHuntARankAllies", "A-Rank Hunt")
	GUI_NewNumeric(winName,"Max Wait (s)",		"gHuntARankMaxWait", "A-Rank Hunt")
	GUI_NewCheckbox(winName,"Play Sound",		"gHuntARankSound", "A-Rank Hunt")
	GUI_NewCheckbox(winName,"Perform Command",	"gHuntARankDoCommand", "A-Rank Hunt")
	GUI_NewField(winName,"Text Command",		"gHuntARankCommandString", "A-Rank Hunt")
	
	GUI_NewCheckbox(winName,"Do B Rank",		"gHuntBRankHunt","B-Rank Hunt")
	GUI_NewField(winName,"Hunt ID",				"gHuntBRankHuntID","B-Rank Hunt")
	GUI_NewCheckbox(winName,"Hunt Any",			"gHuntBRankHuntAny", "B-Rank Hunt")
	GUI_NewCheckbox(winName,"Play Sound",		"gHuntBRankSound", "B-Rank Hunt")
	
	
	local firstLocation, locationList = ffxiv_task_hunt.GetLocationsList()
	GUI_NewComboBox(winName,GetString("locationName"),		"gHuntLocation",	"New Location", locationList)
	gHuntLocation = firstLocation
	GUI_NewButton(winName,"Add Location", "ffxiv_huntAddLocation", "New Location")
	
	local firstMonster, monsterList = ffxiv_task_hunt.GetMonsterList("S")
	GUI_NewComboBox(winName,"S-Rank",		"gHuntMonsterS",		"New Monster", monsterList)
	gHuntMonsterS = firstMonster
	GUI_NewButton(winName,"Add Monster", "ffxiv_huntAddMonsterS", "New Monster")
	
	firstMonster, monsterList = ffxiv_task_hunt.GetMonsterList("A")
	GUI_NewComboBox(winName,"A-Rank",		"gHuntMonsterA",		"New Monster", monsterList)
	gHuntMonsterA = firstMonster
	GUI_NewButton(winName,"Add Monster", "ffxiv_huntAddMonsterA", "New Monster")
	
	firstMonster, monsterList = ffxiv_task_hunt.GetMonsterList("B")
	GUI_NewComboBox(winName,"B-Rank",		"gHuntMonsterB",		"New Monster", monsterList)
	gHuntMonsterB = firstMonster
	GUI_NewButton(winName,"Add Monster", "ffxiv_huntAddMonsterB", "New Monster")
	
	GUI_UnFoldGroup(winName,GetString("status"))
	GUI_UnFoldGroup(winName,"New Location" )
	GUI_UnFoldGroup(winName,"New Monster" )
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	
	local editWindow = ffxiv_task_hunt.editwindow
	GUI_NewWindow(editWindow.name,editWindow.x,editWindow.y,editWindow.width,editWindow.height,"",true)
	winName = editWindow.name
	group = GetString("settings")
	GUI_NewField(winName,GetString("locationName"),		"eHuntMapName",group)
	GUI_NewCheckbox(winName,GetString("enabled"), 			"eHuntMapEnabled",group)
	GUI_NewNumeric(winName,"Map Time (minutes)",						"eHuntMapTimer",group)
	GUI_NewButton(winName,GetString("saveLocation"),		"ffxiv_huntSaveLocation")
	GUI_NewButton(winName,GetString("removeLocation"),		"ffxiv_huntRemoveLocation")
	GUI_UnFoldGroup(winName,GetString("settings"))
	GUI_SizeWindow(winName, editWindow.width, editWindow.height)
	GUI_WindowVisible(winName, false)
	
	
	gHuntLocations = Settings.FFXIVMINION.gHuntLocations
	gHuntMapID = Player.localmapid
	gHuntMapTimer = Settings.FFXIVMINION.gHuntMapTimer
	--gHuntMarkerStyle = Settings.FFXIVMINION.gHuntMarkerStyle
	gHuntSRankHP = Settings.FFXIVMINION.gHuntSRankHP
	gHuntSRankAllies = Settings.FFXIVMINION.gHuntSRankAllies
	gHuntSRankMaxWait = Settings.FFXIVMINION.gHuntSRankMaxWait
	gHuntSRankDoCommand = Settings.FFXIVMINION.gHuntSRankDoCommand
	gHuntSRankCommandString = Settings.FFXIVMINION.gHuntSRankCommandString
	gHuntSRankSound = Settings.FFXIVMINION.gHuntSRankSound
	gHuntARankHP = Settings.FFXIVMINION.gHuntARankHP
	gHuntARankAllies = Settings.FFXIVMINION.gHuntARankAllies
	gHuntARankMaxWait = Settings.FFXIVMINION.gHuntARankMaxWait
	gHuntARankDoCommand = Settings.FFXIVMINION.gHuntARankDoCommand
	gHuntARankCommandString = Settings.FFXIVMINION.gHuntARankCommandString
	gHuntARankSound = Settings.FFXIVMINION.gHuntARankSound
	gHuntBRankHuntID = Settings.FFXIVMINION.gHuntBRankHuntID
	gHuntBRankHuntAny = Settings.FFXIVMINION.gHuntBRankHuntAny
	gHuntBRankSound = Settings.FFXIVMINION.gHuntBRankSound
	gHuntBRankHunt = Settings.FFXIVMINION.gHuntBRankHunt
	gHuntARankHunt = Settings.FFXIVMINION.gHuntARankHunt
	gHuntSRankHunt = Settings.FFXIVMINION.gHuntSRankHunt
	
	ffxiv_task_hunt.RefreshHuntLocations()
	ffxiv_task_hunt.SetupMarkers()
end

function ffxiv_task_hunt.SetupMarkers()
    local huntMarker = ml_marker:Create("huntTemplate")
	huntMarker:SetType(GetString("huntMarker"))
    huntMarker:SetTime(0)
    huntMarker:SetMinLevel(1)
    huntMarker:SetMaxLevel(50)
    ml_marker_mgr.AddMarkerTemplate(huntMarker)
    ml_marker_mgr.RefreshMarkerTypes()
	ml_marker_mgr.RefreshMarkerNames()
end

function ffxiv_task_hunt.AddHuntLocation()
	local list = Settings.FFXIVMINION.gHuntLocations
	local locations = ffxiv_task_hunt.locations
	local key = gHuntLocation
	
	local firstBracket = string.find(key,"[", nil, true)
	key = tonumber(key:sub(1,firstBracket - 1))
	
	if (not key or not locations[key]) then
		ml_error("An error occurred trying to get the location.")
	end
	
	if (list[key]) then
		ml_error("This location already exists, edit the existing one instead.")
	end
		
	local location = locations[key]
	local order = TableSize(list) + 1
	
	if ( TableSize(list) > 0 ) then
		local reorder = 1
		for k,v in pairsByKeys(list) do
			v.order = reorder
			reorder = reorder + 1
		end
	end
	
	local newlocation = {
		name = location.name,
		enabled = true,
		order = order,
		timer = location.timer,
	}
	
	list[key] = newlocation
	gHuntLocations = list
	Settings.FFXIVMINION.gHuntLocations = gHuntLocations
	ffxiv_task_hunt.RefreshHuntLocations()
end

function ffxiv_task_hunt.EditHuntLocation(key)
	local key = tonumber(key)
	local list = Settings.FFXIVMINION.gHuntLocations
	
	--Check to make sure that something hasn't gone wrong with the index and reindex the table if necessary.
	if (not list[key]) then
		d("This location doesn't exist.")
		return
	end
	
	local location = list[key]
	if (ValidTable(location)) then
		eGatherMapName = location.name
		eGatherMapEnabled = (location.enabled == true) and "1" or "0"
		eGatherMapIdle = (location.isIdle == true) and "1" or "0"
		eGatherMapHour = location.hour
		eGatherMapClass = (location.class == FFXIV.JOBS.MINER) and "MINER" or "BOTANIST"
		eGatherMapMarker = location.marker
	else
		d("Location is corrupted, please remove it and start over.")
		return
	end
	
	local window = ffxiv_task_gather.editwindow
	local base = ffxivminion.GetWindowSize(GetString("gatherMode"))
	GUI_MoveWindow(window.name,base.x + base.width,base.y)
	GUI_WindowVisible(window.name, true)
	GUI_RefreshWindow(window.name)
end

function ffxiv_task_hunt.SaveHuntLocation()
	local list = Settings.FFXIVMINION.gHuntLocations
	local locations = ffxiv_task_hunt.locations
	local key = gHuntLocation
	
	local firstBracket = string.find(key,"[", nil, true)
	key = tonumber(key:sub(1,firstBracket - 1))
	
	if (not key or not locations[key]) then
		ml_error("An error occurred trying to get the location.")
	end
	
	if (list[key]) then
		ml_error("This location already exists, edit the existing one instead.")
	end
		
	local location = locations[key]
	local order = TableSize(list) + 1
	
	if ( TableSize(list) > 0 ) then
		local reorder = 1
		for k,v in pairsByKeys(list) do
			v.order = reorder
			reorder = reorder + 1
		end
	end
	
	local location = {
		name = eGatherMapName,
		enabled = (eGatherMapEnabled == "1"),
		order = tonumber(eGatherMapHour),
		timer = location.timer,
	}
	
	list[key] = newlocation
	gHuntLocations = list
	Settings.FFXIVMINION.gHuntLocations = gHuntLocations
	ffxiv_task_hunt.RefreshHuntLocations()
end

function ffxiv_task_hunt.RemoveHuntLocation()
	local list = Settings.FFXIVMINION.gHuntLocations
	local newList = {}
	local newKey = 1
	
	--Rebuild the list without the unwanted key, rather than actually remove it, to retain the integer index.
	list[key] = nil
	for k,v in spairs(list) do
		newList[tostring(newKey)] = v
		newKey = newKey + 1
	end
	
	gHuntLocations = newList
	Settings.FFXIVMINION.gHuntLocations = gHuntLocations
	ffxiv_task_hunt.RefreshHuntLocations()
end

function ffxiv_task_hunt.RefreshHuntLocations()
	local winName = ffxivminion.Windows.Hunt.Name
	local tabName = "Locations"
	local list = Settings.FFXIVMINION.gHuntLocations
	
	--Remove old entries from beta hunt.
	for k,v in pairs(list) do
		if (v.name == nil or v.order == nil) then
			list[k] = nil
		end
	end

	Settings.FFXIVMINION.gHuntLocations = list
	
	GUI_DeleteGroup(winName,tabName)
	if (TableSize(list) > 0) then
		for k,v in pairsByKeys(list) do
			GUI_NewButton(winName, tostring(k).."["..v.name.."]",	"ffxiv_huntEditLocation"..tostring(k), tabName)
		end
		GUI_UnFoldGroup(winName,tabName)
	end
	
	ffxivminion.SizeWindow(winName)
	GUI_RefreshWindow(winName)
end

function ffxiv_task_hunt.RefreshMap()
	local winName = ffxivminion.Windows.Hunt.Name
	gHuntMapID = Player.localmapid
	GUI_RefreshWindow(winName)
end

function ffxiv_task_hunt.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" and string.find(Button,"ffxiv_hunt") ~= nil ) then
		if (Button == "ffxiv_huntAddLocation") then
			ffxiv_task_hunt.AddHuntLocation()
		end
		if (Button == "ffxiv_huntRefreshMap") then
			ffxiv_task_hunt.RefreshMap()
		end
		if (string.find(Button,"ffxiv_huntEditLocation") ~= nil) then
			local key = Button:gsub("ffxiv_huntEditLocation","")
			ffxiv_task_hunt.EditHuntLocation(key)
		end
		if (Button == "ffxiv_huntSaveLocation") then
			ffxiv_task_hunt.SaveGatherLocation()
		end
		if (Button == "ffxiv_huntRemoveLocation") then
			ffxiv_task_hunt.RemoveGatherLocation()
		end
	end
end

function ffxiv_task_hunt.GetLocationsList()
	local list = ""
	local firstEntry = ""
	local locations = ffxiv_task_hunt.locations
	for id,location in pairsByKeys(locations) do
		if (list == "") then
			list = tostring(id).."["..location.name.."]"
			firstEntry = tostring(id).."["..location.name.."]"
		else
			list = list..","..tostring(id).."["..location.name.."]"
		end
	end
	
	return firstEntry, list
end

function ffxiv_task_hunt.GetMonsterList(rank)
	local sortedlist = ""
	
	local list = {}
	local locations = ffxiv_task_hunt.locations
	for id,location in pairsByKeys(locations) do
		local hunts = location.hunts
		for cid,info in pairs(hunts) do
			if (info.rank == rank) then
				list[cid] = info.name
			elseif (info.rank == rank) then
				list[cid] = info.name
			elseif (info.rank == rank) then
				list[cid] = info.name
			end	
		end
	end
	
	local firstEntry = ""
	local order = function( t,a,b ) return (t[a] < t[b]) end	
	for k,v in spairs(list, order) do
		if (sortedlist == "") then
			sortedlist = tostring(k).."["..v.."]"
			firstEntry = tostring(k).."["..v.."]"
		else
			sortedlist = sortedlist..","..tostring(k).."["..v.."]"
		end
	end
	
	return firstEntry, sortedlist
end

ffxiv_task_hunt.locations = {
	[134] = { name = "Middle La Noscea", enabled = true, timer = 900,
		hunts = {
			[2962] = { name = "Croque-Mitaine", rank = "S" },
			[2945] = { name = "Vogaal Ja", rank = "A" },
			[2928] = { name = "Skogs Fru", rank = "B" },
		}
	},
	[135] = { name = "Lower La Noscea", enabled = true, timer = 900,
		hunts = {
			[2963] = { name = "Croakadile", rank = "S" },
			[2946] = { name = "Unktehi", rank = "A" },
			[2929] = { name = "Barbastelle", rank = "B" },
		}
	},
	[137] = { name = "Eastern La Noscea", enabled = true, timer = 900,
		hunts = {
			[2964] = { name = "Garlok", rank = "S" },
			[2947] = { name = "Hellsclaw", rank = "A" },
			[2930] = { name = "Bloody Mary", rank = "B" },
		}
	},
	[138] = { name = "Western La Noscea", enabled = true, timer = 900,
		hunts = {
			[2965] = { name = "Bonnacon", rank = "S" },
			[2948] = { name = "Nahn", rank = "A" },
			[2931] = { name = "Dark Helmet", rank = "B" },
		}
	},
	[139] = { name = "Upper La Noscea", enabled = true, timer = 900,
		hunts = {
			[2966] = { name = "Nandi", rank = "S" },
			[2949] = { name = "Marberry", rank = "A" },
			[2932] = { name = "Myradrosh", rank = "B" },
		}
	},
	[180] = { name = "Outer La Noscea", enabled = true, timer = 900,
		hunts = {
			[2967] = { name = "Mahisha", rank = "S" },
			[2950] = { name = "Cornu", rank = "A" },
			[2933] = { name = "Vuokho", rank = "B" },
		}
	},
	[148] = { name = "Central Shroud", enabled = true, timer = 900,
		hunts = {
			[2953] = { name = "Laideronnette", rank = "S" },
			[2936] = { name = "Forneus", rank = "A" },
			[2919] = { name = "White Joker", rank = "B" },
		}
	},
	[152] = { name = "East Shroud", enabled = true, timer = 900,
		hunts = {
			[2954] = { name = "Wulgaru", rank = "S" },
			[2936] = { name = "Melt", rank = "A" },
			[2919] = { name = "Stinging Sophie", rank = "B" },
		}
	},
	[153] = { name = "South Shroud", enabled = true, timer = 900,
		hunts = {
			[2955] = { name = "Mindflayer", rank = "S" },
			[2938] = { name = "Ghede Ti Malice", rank = "A" },
			[2921] = { name = "Monarch Ogrefly", rank = "B" },
		}
	},
	[154] = { name = "North Shroud", enabled = true, timer = 900,
		hunts = {
			[2956] = { name = "Thousand-cast Theda", rank = "S" },
			[2939] = { name = "Girtab", rank = "A" },
			[2922] = { name = "Phecda", rank = "B" },
		}
	},
	[140] = { name = "Western Thanalan", enabled = true, timer = 900,
		hunts = {
			[2957] = { name = "Zona Seeker", rank = "S" },
			[2940] = { name = "Alectyron", rank = "A" },
			[2923] = { name = "Sewer Syrup", rank = "B" },
		}
	},
	[141] = { name = "Central Thanalan", enabled = true, timer = 900,
		hunts = {
			[2958] = { name = "Brontes", rank = "S" },
			[2941] = { name = "Sabotender Bailarina", rank = "A" },
			[2924] = { name = "Ovjang", rank = "B" },
		}
	},
	[145] = { name = "Eastern Thanalan", enabled = true, timer = 900,
		hunts = {
			[2959] = { name = "Lampalagua", rank = "S" },
			[2942] = { name = "Maahes", rank = "A" },
			[2925] = { name = "Gatling", rank = "B" },
		}
	},
	[146] = { name = "Southern Thanalan", enabled = true, timer = 900,
		hunts = {
			[2960] = { name = "Nunyunuwi", rank = "S" },
			[2943] = { name = "Zanig'oh", rank = "A" },
			[2926] = { name = "Albin the Ashen", rank = "B" },
		}
	},
	[147] = { name = "Northern Thanalan", enabled = true, timer = 900,
		hunts = {
			[2961] = { name = "Minhocao", rank = "S" },
			[2944] = { name = "Dalvag's Final Flame", rank = "A" },
			[2927] = { name = "Flame Sergeant Dalvag", rank = "B" },
		}
	},
	[155] = { name = "Coerthas", enabled = true, timer = 900,
		hunts = {
			[2968] = { name = "Safat", rank = "S" },
			[2951] = { name = "Marraco", rank = "A" },
			[2934] = { name = "Naul", rank = "B" },
		}
	},
	[156] = { name = "Mor Dhona", enabled = true, timer = 900,
		hunts = {
			[2969] = { name = "Agrippa The Mighty", rank = "S" },
			[2952] = { name = "Kurrea", rank = "A" },
			[2935] = { name = "Leech King", rank = "B" },
		}
	},
}

RegisterEventHandler("GUI.Item",ffxiv_task_hunt.HandleButtons)
RegisterEventHandler("GUI.Update",ffxiv_task_hunt.GUIVarUpdate)
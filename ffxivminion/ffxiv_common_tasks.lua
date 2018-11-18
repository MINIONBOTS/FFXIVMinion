---------------------------------------------------------------------------------------------
--REACTIVE GOALS--
--These are tasks which may be called in reaction to changes in the game state, such as
--mob movement/aggro. They should be placed in the REACTIVE queue and continue to pulse 
--there until they are completed and control returns to the LONGTERM queue rootTask. 
--They are generally placed in the ProcessOverWatch element list of a strategy level
--task since they need to monitor game state changes continually.
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
--TASK_MOVETOPOS: Reactive Goal - Move to the specified position
--This task moves the player to a specified position, the partent of this task needs to make sure
--that this movetopos task has up2date positions and is still valid.
---------------------------------------------------------------------------------------------

ffxiv_task_movetopos = inheritsFrom(ml_task)
function ffxiv_task_movetopos.Create()
    local newinst = inheritsFrom(ffxiv_task_movetopos)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetopos members
    newinst.name = "MOVETOPOS"
    newinst.pos = 0
    newinst.range = 1.5
    newinst.doFacing = false
    newinst.pauseTimer = 0
    newinst.gatherRange = 0.0
    newinst.remainMounted = false
    newinst.useFollowMovement = false
	newinst.obstacleTimer = 0
	newinst.customSearch = ""
	newinst.customSearchCompletes = false
	newinst.useTeleport = false	-- this is for hack teleport, not in-game teleport spell
	newinst.dismountDistance = 10
	newinst.failTimer = 0
	
	newinst.startMap = Player.localmapid
	
	newinst.distanceCheckTimer = 0
	newinst.lastPosition = nil
	
	newinst.flightPath = nil
	newinst.noFlight = false
	newinst.stealthFunction = nil
	
	newinst.abortFunction = nil
	ml_global_information.monitorStuck = true
	ml_global_information.needsStealth = false
	ml_global_information.canStealth = false
	
	newinst.destMapID = 0
	newinst.alwaysMount = false
	newinst.noFly = false
	
	NavigationManager:ResetPath()
	--NavigationManager.NavPathNode = 0
	
	ffxiv_unstuck.Reset()
    
    return newinst
end

function ffxiv_task_movetopos:Init()
	local ke_stuck = ml_element:create( "Stuck", c_stuck, e_stuck, 160 )
    self:add( ke_stuck, self.overwatch_elements)
	
	local ke_unlockAethernet = ml_element:create( "UnlockAethernet", c_unlockaethernet, e_unlockaethernet, 150 )
    self:add( ke_unlockAethernet, self.process_elements)
	
	local ke_useAethernet = ml_element:create( "UseAethernet", c_useaethernet, e_useaethernet, 145 )
    self:add( ke_useAethernet, self.process_elements)
	c_useaethernet.used = false

	local ke_teleportToMap = ml_element:create( "TeleportToMap", c_teleporttomap, e_teleporttomap, 140 )
    self:add( ke_teleportToMap, self.process_elements)
			
	local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 130 )
    self:add( ke_teleportToPos, self.process_elements)
	
	local ke_stealth = ml_element:create( "CheckStealth", c_stealthupdate, e_stealthupdate, 100 )
    self:add( ke_stealth, self.process_elements)
	
	local ke_useNavInteraction = ml_element:create( "UseNavInteraction", c_usenavinteraction, e_usenavinteraction, 90 )
    self:add( ke_useNavInteraction, self.process_elements)
	
	local ke_getMovementPath = ml_element:create( "GetMovementPath", c_getmovementpath, e_getmovementpath, 85 )
    self:add( ke_getMovementPath, self.process_elements)

	local ke_useStealth = ml_element:create( "Stealth", c_dostealth, e_dostealth, 80 )
    self:add( ke_useStealth, self.process_elements)
	
	local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 75 )
    self:add( ke_mount, self.process_elements)
	
    local ke_sprint = ml_element:create( "Sprint", c_sprint, e_sprint, 70 )
    self:add( ke_sprint, self.process_elements)
	
	local ke_falling = ml_element:create( "Falling", c_falling, e_falling, 60 )
    self:add( ke_falling, self.process_elements)
    	
    local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 40 )
    self:add( ke_walkToPos, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetopos:task_complete_eval()
	if ((MIsLoading() or (MIsLocked() and not HasInteractWindows())) and ml_navigation:IsUsingConnection()) then
		return false
	end
	
	if (Busy() or self.startMap ~= Player.localmapid) then
		ml_debug("[MOVETOPOS]: Completing due to locked, loading, mesh loading.")
		return true
	end
	
	if (self.destMapID and Player.localmapid == self.destMapID) then
		return true
	end

    if (table.valid(self.pos)) then
        local myPos = Player.pos
		local gotoPos = self.gatePos or self.pos
		
		local range2d, range3d = ml_navigation.GetMovementThresholds()
		local dist2d, dist3d = math.distance2d(myPos,gotoPos), math.distance3d(myPos,gotoPos)
		
		if (dist3d < 40 and self.customSearch ~= "") then
			local el = EntityList(self.customSearch)
			if (ValidTable(el)) then
				local id,entity = next(el)
				if (ValidTable(entity)) then
					if (entity.alive) then
						if (self.customSearchCompletes) then
							if (InCombatRange(entity.id)) then
								ml_debug("[MOVETOPOS]: Ending movetopos, found the target.")
								return true
							end
						end
						
						local epos = entity.pos						
						if (not deepcompare(self.pos,epos,true)) then
							self.pos = { x = epos.x, y = epos.y, z = epos.z }
							gotoPos = self.pos
							
							ml_debug("[MOVETOPOS]: Using target's exact coordinate : [x:"..tostring(self.pos.x)..",y:"..tostring(self.pos.y)..",z:"..tostring(self.pos.z).."]")
							dist2d, dist3d = math.distance2d(myPos,gotoPos), math.distance3d(myPos,gotoPos)
						end
					end
				end
			end
		end
		
        ml_debug("Bot Position: ("..tostring(myPos.x)..","..tostring(myPos.y)..","..tostring(myPos.z)..")")
        ml_debug("MoveTo Position: ("..tostring(gotoPos.x)..","..tostring(gotoPos.y)..","..tostring(gotoPos.z)..")")
        ml_debug("Task Range: "..tostring(self.range))
        ml_debug("Current Distance: "..tostring(dist3d))
		--ml_debug("Path Distance: "..tostring(pathdistance))
        ml_debug("Completion Distance: "..tostring(self.range + self.gatherRange))
		
		local requiredRange = (self.range + self.gatherRange)
		local requiredRange3d = (IsNull(self.range3d,self.range + 2))
		
		--d("[MOVETOPOS]: Checking range ["..tostring(dist2d).."], ["..tostring(dist3d).."]")
		--d("[MOVETOPOS]: Checking requirement ["..tostring(range2d).."], ["..tostring(range3d).."]")
		--d("[MOVETOPOS]: Checking manual requirement ["..tostring(requiredRange).."]")
		
		if (Player.onmesh or IsFlying()) then
			if ((dist2d <= requiredRange or dist2d <= range2d) and (dist3d <= requiredRange3d or dist3d <= range3d)) then
				Player:Stop()
				if (not self.remainMounted and Player.ismounted) then
					Dismount()
					return false
				else
					return true
				end
			end
		end
    end    
    return false
end

function ffxiv_task_movetopos:task_complete_execute()
	Player:Stop()
	if (self.doFacing) then
		Player:SetFacing(ml_task_hub:CurrentTask().pos.h)
    end
    self.completed = true
	ml_debug("[MOVETOPOS]: Task completing.")
end

function ffxiv_task_movetopos:task_fail_eval()
	if (not Player.alive) then
		return true
	end
	
	return false
end

function ffxiv_task_movetopos:task_fail_execute()
	Player:Stop()
    self.valid = false
	ml_debug("[MOVETOPOS]: Failing.")
end

ffxiv_task_movetofate = inheritsFrom(ml_task)
function ffxiv_task_movetofate.Create()
    local newinst = inheritsFrom(ffxiv_task_movetofate)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetopos members
    newinst.name = "MOVETOFATE"
	newinst.requiresPosRandomize = false
	newinst.actualPos = 0
    newinst.pos = 0
    newinst.range = 2
    newinst.fateid = 0
    newinst.lastMove = 0
	newinst.lastRandomize = 0
    newinst.useFollowMovement = false
	newinst.obstacleTimer = 0
	newinst.dismountTimer = 0
	newinst.dismountDistance = 15
	newinst.failTimer = 0
	newinst.useSmoothTurns = true
	
	newinst.distanceCheckTimer = 0
	newinst.lastPosition = nil
	
	ml_global_information.monitorStuck = true
	newinst.alwaysMount = false
	ffxiv_unstuck.Reset()
    
    return newinst
end

function ffxiv_task_movetofate:Init()
	local ke_stuck = ml_element:create( "Stuck", c_stuck, e_stuck, 150 )
    self:add( ke_stuck, self.overwatch_elements)
	
	local ke_useNavInteraction = ml_element:create( "UseNavInteraction", c_usenavinteraction, e_usenavinteraction, 100 )
    self:add( ke_useNavInteraction, self.process_elements)
	
	local ke_getMovementPath = ml_element:create( "GetMovementPath", c_getmovementpath, e_getmovementpath, 90 )
    self:add( ke_getMovementPath, self.process_elements)
	
	local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 80 )
    self:add( ke_mount, self.process_elements)
	
	--local ke_flyToPos = ml_element:create( "FlyToPos", c_flytopos, e_flytopos, 80 )
    --self:add( ke_flyToPos, self.process_elements)
    
    local ke_sprint = ml_element:create( "Sprint", c_sprint, e_sprint, 70 )
    self:add( ke_sprint, self.process_elements)
	
	local ke_falling = ml_element:create( "Falling", c_falling, e_falling, 60 )
    self:add( ke_falling, self.process_elements)
    
    -- The parent needs to take care of checking and updating the position of this task!!	
    local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 5 )
    self:add( ke_walkToPos, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetofate:task_complete_eval()	
	local fate = MGetFateByID(self.fateid)
	if (table.valid(fate)) then
		local myPos = Player.pos
		local fatedist = PDistance3D(myPos.x,myPos.y,myPos.z,fate.x,fate.y,fate.z)
		
		if (Player.level <= fate.maxlevel or fatedist < fate.radius) then
			local maxdistance = (ml_global_information.AttackRange > 5 and ml_global_information.AttackRange) or 10
			local el = EntityList("nearest,alive,attackable,onmesh,maxdistance="..tostring(maxdistance)..",fateid="..tostring(fate.id))
			if ( table.valid(el) ) then
				local i,e = next(el)
				if (i~=nil and e~=nil) then
					return true
				end
			end	
		end 
	
		local fatePos = {x = fate.x, y = fate.y, z = fate.z}
		if (not deepcompare(self.actualPos,fatePos,true)) then
			--self.pos = fatePos
			self.actualPos = fatePos
			self.requiresPosRandomize = true
			self.lastMove = Now()
		end
		
		local myPos = Player.pos
		local dist = PDistance3D(myPos.x,myPos.y,myPos.z,self.actualPos.x,self.actualPos.y,self.actualPos.z)
		if (self.requiresPosRandomize and 
			(TimeSince(self.lastRandomize) > math.random(2000,3000) or (dist > (fate.radius * .95)))) 
		then
			local newPos = nil
			local skipRandomization = false
			
			if (dist < (fate.radius * .95)) then
				local npcs = EntityList("type=2,chartype=5,alive,onmesh,fateid="..tostring(self.fateid))
				if (table.valid(npcs)) then
					local heading = nil
					for i,npc in pairs(npcs) do
						local npos = npc.pos
						local dist = Distance2D(self.actualPos.x,self.actualPos.z,npos.x,npos.z)
						
						if (dist < 10) then
							if (IsFrontSafe(npc) and (npc.distance2d < fate.radius * .90)) then
								self.pos = myPos
								self.requiresPosRandomize = false
								self.lastRandomize = Now()	
							end
							heading = npos.h
						end
						if (heading) then
							break
						end
					end
					
					if (heading) then
						local mobRight = ConvertHeading((heading - (math.pi * (math.random(11,20)/100))))%(2*math.pi)
						local mobLeft = ConvertHeading((heading + (math.pi * (math.random(11,20)/100))))%(2*math.pi)
						local mobFrontLeft = ConvertHeading((heading + (math.pi * (math.random(1,10)/100))))%(2*math.pi)
						local mobFrontRight = ConvertHeading((heading - (math.pi * (math.random(1,10)/100))))%(2*math.pi)
						
						local options = {
							GetPosFromDistanceHeading(self.actualPos, math.random(10,20), mobFrontLeft),
							GetPosFromDistanceHeading(self.actualPos, math.random(10,20), mobFrontRight),
						}
						
						local selection = options[math.random(1,TableSize(options))]
						if (table.valid(selection)) then
							local p = FindClosestMesh(selection,15,false)
							if (table.valid(p)) then
								newPos = p
							end
						end
					end
				end
			else
				newPos = self.actualPos
			end
			
			if (not table.valid(newPos)) then
				local randomPoint = NavigationManager:GetRandomPointOnCircle(self.pos.x,self.pos.y,self.pos.z,math.random(1,3),math.random(8,12))
				if (table.valid(randomPoint)) then
					local p = FindClosestMesh(randomPoint,10,false)
					if (table.valid(p)) then
						newPos = p
					end
				end
			end
			
			if (not table.valid(newPos)) then
				local p = FindClosestMesh(self.pos,10,false)
				if (table.valid(p)) then
					newPos = p
				end
			end
			
			if (self.requiresPosRandomize) then
				if (table.valid(newPos)) then
					self.pos = newPos
				end
				self.requiresPosRandomize = false
				self.lastRandomize = Now()
			end
		else
			--d("Not randomizing position.")
			--d("Requires Randomize:"..tostring(self.requiresPosRandomize))
			--d("TimeSince Randomize:"..tostring(TimeSince(self.lastRandomize) > 1000))
		end
		
		--While the FATE is moving, follow it closely.
		if (TimeSince(self.lastMove) > 3000) then
			if (table.valid(self.pos)) then
				local myPos = Player.pos
				local gotoPos = self.pos
				
				local distance = Distance2D(myPos.x, myPos.z, gotoPos.x, gotoPos.z)
				
				if (distance <= (self.range)) then
					return true
				end
			end 
		end 
	end
    return false
end

function ffxiv_task_movetofate:task_complete_execute()
	Player:Stop()
	self.completed = true
	ml_global_information.monitorStuck = false
end

function ffxiv_task_movetofate:task_fail_eval()
	local fate = MGetFateByID(self.fateid)
	if (not table.valid(fate)) then
		return true
	end
	
	return false
end
function ffxiv_task_movetofate:task_fail_execute()
	Player:Stop()
    self.valid = false
	ml_global_information.monitorStuck = false
end

--++MOVE_TO_INTERACT
ffxiv_task_movetointeract = inheritsFrom(ml_task)
function ffxiv_task_movetointeract.Create()
    local newinst = inheritsFrom(ffxiv_task_movetointeract)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "MOVETOINTERACT"
	
	newinst.started = Now()
	newinst.contentid = 0
	newinst.interact = 0
	newinst.navid = 0
	
	newinst.pos = false
	newinst.range = nil
	newinst.areaChanged = false
	newinst.useTeleport = true
	newinst.failTimer = 0
	newinst.interactRange = nil
	newinst.dismountDistance = 5
	newinst.killParent = false
	newinst.startMap = Player.localmapid
	newinst.conversationstring = ""
	newinst.conversationstrings = ""
	newinst.conversationindex = -1
	newinst.blockExecution = false
	newinst.detectedMovement = false
	newinst.stealthFunction = nil
	
	newinst.interactAttempts = 0
	newinst.maxAttempts = 0
	
	newinst.skipTalkVal = gSkipTalk
	gSkipTalk = false
	
	ml_global_information.monitorStuck = true
	ml_global_information.needsStealth = false
	ml_global_information.canStealth = false
	newinst.alwaysMount = false
	
	ffxiv_unstuck.Reset()
	
    return newinst
end

function ffxiv_task_movetointeract:Init()
	local ke_stuck = ml_element:create( "Stuck", c_stuck, e_stuck, 150 )
    self:add( ke_stuck, self.overwatch_elements)
	
	local ke_unlockAethernet = ml_element:create( "UnlockAethernet", c_unlockaethernet, e_unlockaethernet, 140 )
    self:add( ke_unlockAethernet, self.process_elements)
	
	local ke_useAethernet = ml_element:create( "UseAethernet", c_useaethernet, e_useaethernet, 135 )
    self:add( ke_useAethernet, self.process_elements)
	c_useaethernet.used = false
	
	local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 130 )
    self:add( ke_teleportToPos, self.process_elements)
	
	local ke_useNavInteraction = ml_element:create( "UseNavInteraction", c_usenavinteraction, e_usenavinteraction, 125 )
    self:add( ke_useNavInteraction, self.process_elements)
	
	local ke_stealth = ml_element:create( "Stealth", c_stealthupdate, e_stealthupdate, 110 )
    self:add( ke_stealth, self.process_elements)
	
	local ke_interact = ml_element:create( "Interact", c_dointeract, e_dointeract, 100 )
    self:add( ke_interact, self.process_elements)
	
	local ke_getMovementPath = ml_element:create( "GetMovementPath", c_getmovementpath, e_getmovementpath, 90 )
    self:add( ke_getMovementPath, self.process_elements)
	
	local ke_useStealth = ml_element:create( "Stealth", c_dostealth, e_dostealth, 85 )
    self:add( ke_useStealth, self.process_elements)
	
	local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 80 )
    self:add( ke_mount, self.process_elements)
    
    local ke_sprint = ml_element:create( "Sprint", c_sprint, e_sprint, 70 )
    self:add( ke_sprint, self.process_elements)
	
	local ke_falling = ml_element:create( "Falling", c_falling, e_falling, 60 )
    self:add( ke_falling, self.process_elements)
	
	local ke_walkToEntity = ml_element:create( "WalkToEntity", c_walktoentity, e_walktoentity, 10 )
    self:add( ke_walkToEntity, self.process_elements)
	
	self:AddTaskCheckCEs()
end

function ffxiv_task_movetointeract:task_complete_eval()
	if (IsControlOpen("SelectString") or IsControlOpen("SelectIconString")) then
		local convoList = GetConversationList()
		if (table.valid(convoList)) then
			if (string.valid(self.conversationstring)) then
				for selectindex,convo in pairs(convoList) do
					local cleanedline = CleanConvoLine(convo)
					local cleanedv = CleanConvoLine(self.conversationstring)
					if (string.contains(IsNull(cleanedline,""),IsNull(cleanedv,""))) then
						d("Use conversation line ["..tostring(convo).."]")
						SelectConversationLine(selectindex)
						ml_global_information.Await(500,2000, function () return not (IsControlOpen("SelectString") and IsControlOpen("SelectIconString")) end)
						return false
					end
				end
			elseif (table.valid(self.conversationstrings)) then
				for selectindex,convo in pairs(convoList) do
					local cleanedline = CleanConvoLine(convo)
					for k,v in pairs(self.conversationstrings) do
						local cleanedv = CleanConvoLine(v)
						if (string.contains(IsNull(cleanedline,""),IsNull(cleanedv,""))) then
							d("Use conversation line ["..tostring(convo).."]")
							SelectConversationLine(selectindex)
							ml_global_information.Await(500,2000, function () return not (IsControlOpen("SelectString") and IsControlOpen("SelectIconString")) end)
							return false
						end
					end
				end
			elseif (self.conversationindex > 0) then
				SelectConversationIndex(self.conversationindex)
				ml_global_information.Await(500,2000, function () return not (IsControlOpen("SelectString") and IsControlOpen("SelectIconString")) end)
				return false
			end
		end
	end
	
	-- Dumbed this down to one helper, lots of conditions already, and I fear more to come, diving doesn't follow the usual rules.
	if ((MIsLoading() or (MIsLocked() and not HasInteractWindows())) and ml_navigation:IsUsingConnection()) then
		return false
	end
	
	if (Busy() or self.startMap ~= Player.localmapid) then
		return true
	end
	
	local myTarget = MGetTarget()
	local ppos = Player.pos
	
	local interactable = nil
	if (self.interact ~= 0) then
		interactable = EntityList:Get(self.interact)
	end
	
	--if (interactable and interactable.meshpos) then
		--d("[NAVIGATION]: Task Pos ["..tostring(ml_task_hub:CurrentTask().pos.x)..","..tostring(ml_task_hub:CurrentTask().pos.y)..","..tostring(ml_task_hub:CurrentTask().pos.z).."]")
		--d("[NAVIGATION]: Interactable Pos ["..tostring(interactable.pos.x)..","..tostring(interactable.pos.y)..","..tostring(interactable.pos.z).."]")
	--end
	
	--if (not IsFlying()) then
		local dist2d,dist3d = math.distance2d(ppos,self.pos),math.distance3d(ppos,self.pos)
		if (self.interact ~= 0 and dist2d < 50 and dist3d < 50) then
			if (not interactable or not interactable.targetable) then
				return true
			end
		else
			if (dist2d <= 5 and dist3d <= 10) then
				local interacts = EntityList("targetable,contentid="..tostring(self.contentid)..",maxdistance=10")
				if (not table.valid(interacts)) then
					return true
				end
			end			
		end
	--end
	
	return false
end

function ffxiv_task_movetointeract:task_complete_execute()
    Player:Stop()
	
	if (self.killParent) then
		ml_task_hub:ThisTask():ParentTask().stepCompleted = true
		ml_task_hub:ThisTask():ParentTask().stepCompletedTimer = Now() + 1000
	end
	gSkipTalk = self.skipTalkVal
	self.completed = false
end

function ffxiv_task_movetointeract:task_fail_eval()
	if (not Player.alive) then
		return true
	end
	
	if (IsNull(self.maxAttempts,0) > 0 and IsNull(self.interactAttempts,0) >= IsNull(self.maxAttempts,0)) then
		if (not ml_global_information.failedInteracts) then
			ml_global_information.failedInteracts = {}
		end
		if (self.interact) then
			d("adding ["..tostring(self.interact).."] to failed interacts")
			ml_global_information.failedInteracts[self.interact] = Now()
		end
		return true
	end
	
	return false
end

function ffxiv_task_movetointeract:task_fail_execute()
	gSkipTalk = self.skipTalkVal
    self.valid = false
end

----------------------------------------------------------------------------------------------------------
ffxiv_task_movetomap = inheritsFrom(ml_task)
function ffxiv_task_movetomap.Create()
    local newinst = inheritsFrom(ffxiv_task_movetomap)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetomap members
    newinst.name = "MOVETOMAP"
    newinst.destMapID = 0
    newinst.tryTP = true
	newinst.setHomepoint = false
	newinst.pos = nil
   
    return newinst
end

function ffxiv_task_movetomap:Init()
	local ke_yesnoQuest = ml_element:create( "QuestYesNo", c_mapyesno, e_mapyesno, 150 )
    self:add(ke_yesnoQuest, self.overwatch_elements)
	
	local ke_reachedMap = ml_element:create( "ReachedMap", c_reachedmap, e_reachedmap, 100)
    self:add( ke_reachedMap, self.overwatch_elements)
	
	local ke_unlockAethernet = ml_element:create( "UnlockAethernet", c_unlockaethernet, e_unlockaethernet, 70 )
    self:add( ke_unlockAethernet, self.process_elements)
	
	local ke_useAethernet = ml_element:create( "UseAethernet", c_useaethernet, e_useaethernet, 65 )
    self:add( ke_useAethernet, self.process_elements)
	c_useaethernet.used = false
	
    local ke_teleportToMap = ml_element:create( "TeleportToMap", c_teleporttomap, e_teleporttomap, 60 )
    self:add( ke_teleportToMap, self.process_elements)
	
	local ke_transportGate = ml_element:create( "TransportGate", c_transportgate, e_transportgate, 50 )
    self:add( ke_transportGate, self.process_elements)
	
	local ke_interactGate = ml_element:create( "InteractGate", c_interactgate, e_interactgate, 40 )
    self:add( ke_interactGate, self.process_elements)

    local ke_moveToGate = ml_element:create( "MoveToGate", c_movetogate, e_movetogate, 30 )
    self:add( ke_moveToGate, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_movetomap:task_complete_eval()
	if (MIsLoading() or Player.localmapid == ml_task_hub:ThisTask().destMapID) then
		return true
	end
	
	return false
end

function ffxiv_task_movetomap:task_fail_eval()
	return (not Player.alive or Player.incombat)
end

--=======================SUMMON CHOCO TASK=========================-

ffxiv_task_summonchoco = inheritsFrom(ml_task)
function ffxiv_task_summonchoco.Create()
    local newinst = inheritsFrom(ffxiv_task_summonchoco)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_killtarget members
    newinst.name = "LT_SUMMON_CHOCOBO"
    
    return newinst
end

function ffxiv_task_summonchoco:Init()    
    self:AddTaskCheckCEs()
end

function ffxiv_task_summonchoco:task_complete_eval()	
	local al = ActionList("type=6")
	local dismiss = al[2]
	local acDismiss = SkillMgr.GetAction(dismiss.id,6)
	local item = GetItem(4868,{0,1,2,3})	
	
	if ( acDismiss.isready or item.isready) then
		return true
	end
	
	return false
end

function ffxiv_task_summonchoco:task_complete_execute()
    self.completed = true
	ml_global_information.summonTimer = ml_global_information.Now
end

function ffxiv_task_summonchoco:task_fail_eval()
	return (not Player.alive)
end

--=======================TELEPORT TASK=========================-

ffxiv_task_teleport = inheritsFrom(ml_task)
function ffxiv_task_teleport.Create()
    local newinst = inheritsFrom(ffxiv_task_teleport)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    newinst.name = "LT_TELEPORT"
	newinst.aetheryte = 0
    newinst.mapID = 0
	newinst.mesh = nil
    newinst.started = Now()
	newinst.lastActivity = Now()
	newinst.setEvac = true
	newinst.setHomepoint = false
	newinst.conversationIndex = 0
    
    return newinst
end

function ffxiv_task_teleport:Init() 
	local ke_setHomepoint = ml_element:create( "SetHomepoint", c_sethomepoint, e_sethomepoint, 50 )
	self:add( ke_setHomepoint, self.process_elements)
	
    self:AddTaskCheckCEs()
end

c_sethomepoint = inheritsFrom( ml_cause )
e_sethomepoint = inheritsFrom( ml_effect )
e_sethomepoint.aethid = 0
e_sethomepoint.aethpos = {}
function c_sethomepoint:evaluate()    
	if (MIsLoading() or MIsCasting(true) or MIsLocked() or 
		IsControlOpen("SelectString") or IsControlOpen("SelectIconString") or IsCityMap(Player.localmapid))
	then
		return false
	end
	
	e_sethomepoint.aethid = 0
	e_sethomepoint.aethpos = {}
	
	if (not ml_task_hub:CurrentTask().setHomepoint or Player.localmapid ~= ml_task_hub:CurrentTask().mapID) then
		return false
	end
	
	local homepoint = GetHomepoint()
	if (homepoint ~= 0) then
		d("homepoint is ["..tostring(homepoint).."] and current mapid is ["..tostring(ml_task_hub:CurrentTask().mapID).."]")
		if (homepoint ~= ml_task_hub:CurrentTask().mapID) then
			local location = GetAetheryteLocation(ml_task_hub:CurrentTask().aetheryte)
			if (table.valid(location)) then
				d("need to set homepoint")
				e_sethomepoint.aethid = ml_task_hub:CurrentTask().aetheryte
				e_sethomepoint.aethpos = {x = location.x, y = location.y, z = location.z}
				return true
			end
		end
	end
    
    return false
end
function e_sethomepoint:execute()
    local newTask = ffxiv_task_movetointeract.Create()
	newTask.contentid = e_sethomepoint.aethid
	newTask.pos = e_sethomepoint.aethpos
	
	if (gTeleportHack) then
		newTask.useTeleport = true
	end
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

function ffxiv_task_teleport:task_complete_eval()
	if (MIsLoading() or MIsCasting(true)) then
		--d("isloading or iscasting")
		return false
	end
	
	if (IsControlOpen("SelectIconString") or IsControlOpen("SelectString")) then
		local convoList = GetConversationList()
		if (table.valid(convoList)) then
			local conversationstrings = {
				["E"] = "Set Home Point";
				["J"] = "ホームポイント登録";
				["G"] = "Als Heimatpunkt registrieren";
				["F"] = "Enregistrer comme point de retour";
				["CN"] = "设置返回点";
				["KR"] = "귀환 지점 설정";
			}

			for selectindex,convo in pairs(convoList) do
				local cleanedline = CleanConvoLine(convo)
				for k,v in pairs(conversationstrings) do
					local cleanedv = CleanConvoLine(v)
					if (string.contains(IsNull(cleanedline,""),IsNull(cleanedv,""))) then
						d("Use conversation line ["..tostring(convo).."]")
						SelectConversationLine(selectindex)
						ml_global_information.Await(2000, function () return IsControlOpen("SelectYesno") end)
						return false
					end
				end
			end
		else
			return false
		end
	end
	
	if (IsControlOpen("SelectYesno")) then
		PressYesNo(true)
		ml_global_information.Await(1500, function () return GetHomepoint() == Player.localmapid end)
		return
	end
	
	if (Player.localmapid ~= self.mapID) then
		--d("map doesn't match needed map, can't complete")
		return false
	end
	
	if (self.setHomepoint and not IsCityMap(Player.localmapid)) then
		local homepoint = GetHomepoint()
		if (homepoint ~= self.mapID) then
			--d("homepoint doesn't match the mapid")
			return false
		end
	end
	
	if (self.setEvac) then
		AddEvacPoint()
	end
	
	--d("complete teleport")
	return true
end
function ffxiv_task_teleport:task_complete_execute()  
	self.completed = true
end

function ffxiv_task_teleport:task_fail_eval()
	if (Player.incombat or not Player.alive) then
		return true
	end
	
	if (Busy()) then
		self.lastActivity = Now()
		return false
	end
	
	if (TimeSince(self.started) > 25000) then
		return true
	elseif (TimeSince(self.lastActivity) > 5000) then
		return true
	end
end
function ffxiv_task_teleport:task_fail_execute()  
	self.valid = false
end

--=======================STEALTH TASK=========================-
--This is a blocking task to prevent anything else from happening
--while stealth is being added or removed.

ffxiv_task_stealth = inheritsFrom(ml_task)
function ffxiv_task_stealth.Create()
    local newinst = inheritsFrom(ffxiv_task_stealth)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_killtarget members
    newinst.name = "LT_STEALTH"
	newinst.droppingStealth = false
	newinst.addingStealth = false
	newinst.timer = 0
	newinst.failTimer = Now() + 6000

    return newinst
end

function ffxiv_task_stealth:Init()    
    self:AddTaskCheckCEs()    
end

function ffxiv_task_stealth:task_complete_eval()
	if (self.addingStealth) then
		if (Player.ismounted) then
			Dismount()
			return false
		end
	end
	
	local action = nil
    if (Player.job == FFXIV.JOBS.BOTANIST) then
        action = SkillMgr.GetAction(212)
    elseif (Player.job == FFXIV.JOBS.MINER) then
        action = SkillMgr.GetAction(229)
    elseif (Player.job == FFXIV.JOBS.FISHER) then
        action = SkillMgr.GetAction(298)
    end

	if (self.droppingStealth) then
		if (MissingBuffs(Player,"47")) then
			return true
		end
	end
	
	if (self.addingStealth) then
		if (HasBuffs(Player,"47")) then
			return true
		end
		if (action and action.isoncd and Player:IsMoving()) then
			Player:PauseMovement()
		end
	end
	
	if (action and not action.isoncd) then
		if (action:Cast(Player.id)) then
			ml_global_information.Await(1000, function () return HasBuff(Player,47) end)
			return true
		end
    end
	
	return false
end
function ffxiv_task_stealth:task_complete_execute()
	-- Need this or the Player will continue moving at slow speeds.
	if (self.droppingStealth and Player:IsMoving()) then
		Player:PauseMovement()
		Player:Move(FFXIV.MOVEMENT.FORWARD)
	end
    self.completed = true
end

function ffxiv_task_stealth:task_fail_eval()
	if (not Player.alive or Player.incombat or MIsLocked() or IsControlOpen("GatheringMasterpiece")) then
		return true
	end
	
	local fs = tonumber(Player:GetFishingState())
	if (IsControlOpen("Gathering") or fs ~= 0) then
		return true
	end
	
	if (Now() > self.failTimer) then
		return true
	end
	
	return false
end

--=======================USEITEM TASK=========================-

ffxiv_task_useitem = inheritsFrom(ml_task)
function ffxiv_task_useitem.Create()
    local newinst = inheritsFrom(ffxiv_task_useitem)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_killtarget members
    newinst.name = "LT_USEITEM"
	newinst.itemid = 0
	newinst.targetid = 0
	newinst.pos = {}
	newinst.timer = 0
	newinst.useTime = 0
	newinst.startingCount = 0
	newinst.dismountDelay = 0
	newinst.maxTime = Now() + 12000
	newinst.useAttempts = 0
	
	newinst.setup = false
    
    return newinst
end

function ffxiv_task_useitem:Init()    
    self:AddTaskCheckCEs()
end

function ffxiv_task_useitem:task_complete_eval()	
	local itemcount = ItemCount(self.itemid) or 0
	if (not self.setup) then
		self.startingCount = itemcount
		self.setup = true
	end
	
	if (itemcount < self.startingCount or itemcount == 0 or self.useAttempts > 3) then
		return true
	end
	
	if (Now() > self.maxTime) then
		return true
	end
	
	if (IsFlying()) then
		return false
	end
	
	if (Player.ismounted) then
		Dismount()
		return false
	end
	
	if (Player:IsMoving()) then
		Player:Stop()
		ml_global_information.Await(1000, function () return (not Player:IsMoving()) end)
		return false
	end
	
	if (MIsCasting()) then
		ml_global_information.Await(10000, function () return Player.castinginfo.castingid == 0 end)
		return false 
	end
	
	local item, action = GetItem(self.itemid)
	if (item and action and not action.isoncd) then
		if (item:IsReady(Player.id) and self.targetid == 0) then
			item:Cast()
			self.useAttempts = self.useAttempts + 1
			local castid = action.id
			ml_global_information.Await(5000, function () return Player.castinginfo.lastcastid == castid end)
			return false
		elseif (item:IsReady(targetid) and self.targetid ~= 0) then
			item:Cast(self.targetid)
			self.useAttempts = self.useAttempts + 1
			local castid = action.id
			ml_global_information.Await(5000, function () return Player.castinginfo.lastcastid == castid end)
			return false
		elseif (item:IsReady() and table.valid(self.pos)) then
			item:Cast(self.pos.x, self.pos.y, self.pos.z)
			self.useAttempts = self.useAttempts + 1
			local castid = action.id
			ml_global_information.Await(5000, function () return Player.castinginfo.lastcastid == castid end)
			return false
		end
	end
	
	return false
end

function ffxiv_task_useitem:task_complete_execute()
    self.completed = true
end

function ffxiv_task_useitem:task_fail_eval()
	local fs = Player:GetFishingState()
	if ((fs ~= 0 and fs ~= 4) or IsControlOpen("Gathering")) then	
		return true
	end
	
    return (not Player.alive or MIsLoading())
end
function ffxiv_task_useitem:task_fail_execute()
    self.valid = false
end

--=======================AVOID TASK=========================-

ffxiv_task_avoid = inheritsFrom(ml_task)
function ffxiv_task_avoid.Create()
    local newinst = inheritsFrom(ffxiv_task_avoid)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetopos members
    newinst.name = "AVOID"
	newinst.targetid = 0
    newinst.pos = 0
	newinst.maxTime = 0
    newinst.started = Now()
	newinst.attackTarget = 0
    
    return newinst
end

function ffxiv_task_avoid:Init()
    Player:MoveTo(self.pos.x,self.pos.y,self.pos.z)
    self:AddTaskCheckCEs()
end

function ffxiv_task_avoid:task_complete_eval()
	local ppos = Player.pos
	local topos = self.pos
	local dist = PDistance3D(ppos.x,ppos.y,ppos.z,topos.x,topos.y,topos.z)
	
	if (self.maxTime > 0) then
		if TimeSince(self.started) > (self.maxTime * 1000) then
			return true
		end
	else
		if (dist < 0.5 or (dist < 2 and not Player:IsMoving())) then
			return true
		end
	end
	
	local target = MGetEntity(self.targetid)
	if (not target or not target.alive or target.castinginfo.channelingid == 0) then
		return true
	end
	
	if TimeSince(ml_task_hub:ThisTask().started) > 5000 then
		return true
	end
	
	if (dist > 1) then
		Player:MoveTo(self.pos.x,self.pos.y,self.pos.z,0.5,0,1)
	end
	
	if (dist < 1.5 and not Player:IsMoving()) then
		local target;
		if (self.attackTarget ~= 0) then
			target = MGetEntity(self.attackTarget)
		else 
			target = MGetTarget()
		end
		if (target ~= nil) then
			local pos = target.pos
			Player:SetFacing(pos.x,pos.y,pos.z)
			if (InCombatRange(target.id) and target.attackable and target.alive) then
				SkillMgr.Cast( target )
			end
		end
	end
    return false
end

function ffxiv_task_avoid:task_complete_execute()
    Player:Stop()
    
	local target = MGetTarget()
	if (target ~= nil) then
		local pos = target.pos
		Player:SetFacing(pos.x,pos.y,pos.z)
	end
	self.completed = true
end

function ffxiv_task_avoid:task_fail_eval()
    return (not Player.alive)
end
function ffxiv_task_avoid:task_fail_execute()
    self.valid = false
end

--=======================REST TASK=========================-
--This is a blocking task to prevent anything else from happening
--while stealth is being added or removed.

ffxiv_task_rest = inheritsFrom(ml_task)
function ffxiv_task_rest.Create()
    local newinst = inheritsFrom(ffxiv_task_rest)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "LT_REST"
	newinst.timer = Now()
	newinst.failTimer = 0
    
    return newinst
end

function ffxiv_task_rest:Init()
    self:AddTaskCheckCEs()
end

function ffxiv_task_rest:task_complete_eval()
	--Try to cast self-heals if we have them.
	SkillMgr.Cast( Player, true )
	
	if (gTeleportHack and TimeSince(self.timer) < 5000) then
		return false
	end
	
	local restHP, restMP = gRestHP, gRestMP
	if (IsEurekaMap(Player.localmapid)) then
		restHP, restMP = gEurekaRestHP, gEurekaRestMP
	end
	
    if ((Player.hp.percent > math.random(90,95) or tonumber(restHP) == 0) and (Player.mp.percent > math.random(90,95) or tonumber(restMP) == 0)) then
		return true
	end
	
	if (Player.hp.percent > math.random(90,95) and TimeSince(self.timer) > 120000) then
		return true
	end
	
	return false
end
function ffxiv_task_rest:task_complete_execute()
	d("Completed resting, resuming normal task actions.")
    self.completed = true
end

function ffxiv_task_rest:task_fail_eval()
    if (not Player.alive) then
		return true
	end
	
	if (Player.incombat) then
		local el = EntityList("alive,attackable,targetingme,maxdistance=25")
		if(table.valid(el)) then
			return true
		end
	end
	
	return false
end

---------------------------------------------------------------------------------------------
--TASK_MOVETOPOS: Reactive Goal - Move to the specified position
--This task moves the player to a specified position, the partent of this task needs to make sure
--that this movetopos task has up2date positions and is still valid.
---------------------------------------------------------------------------------------------
ffxiv_task_flee = inheritsFrom(ml_task)
function ffxiv_task_flee.Create()
    local newinst = inheritsFrom(ffxiv_task_flee)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetopos members
    newinst.name = "LT_FLEE"
    newinst.pos = 0
    newinst.range = 1.5
	newinst.useTeleport = false	-- this is for hack teleport, not in-game teleport spell
	newinst.failTimer = 0
	
	newinst.alwaysMount = false

    return newinst
end

function ffxiv_task_flee:Init()	
	local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 20 )
    self:add( ke_teleportToPos, self.process_elements)
	
	local ke_getMovementPath = ml_element:create( "GetMovementPath", c_getmovementpath, e_getmovementpath, 15 )
    self:add( ke_getMovementPath, self.process_elements)
	
	local ke_falling = ml_element:create( "Falling", c_falling, e_falling, 10 )
    self:add( ke_falling, self.process_elements)
	
    local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 5 )
    self:add( ke_walkToPos, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_flee:task_complete_eval()
	if (MIsLoading()) then
		return true
	end
	
	if (Player:IsMoving()) then
		local sprint = SkillMgr.GetAction(3)
		if (sprint and sprint.isready) then
			sprint:Cast()
		end
    end
	
	local fleeHP, fleeMP, restHP, restMP, potionHP = gFleeHP, gFleeMP, gRestHP, gRestMP, gPotionHP
	if (IsEurekaMap(Player.localmapid)) then
		fleeHP, fleeMP, restHP, restMP, potionHP = gEurekaFleeHP, gEurekaFleeMP, gEurekaRestHP, gEurekaRestMP, gEurekaPotionHP
	end
	
	return (not Player.incombat or 
		((tonumber(restHP) > tonumber(fleeHP) and Player.hp.percent > tonumber(restHP) and tonumber(restMP) > tonumber(fleeMP) and Player.mp.percent > tonumber(restMP)) or
		(tonumber(fleeHP) > 0 and Player.hp.percent > tonumber(potionHP)) or
		(tonumber(fleeHP) > 0 and Player.hp.percent > 75)))
end

function ffxiv_task_flee:task_complete_execute()
    Player:Stop()
	NavigationManager:ClearAvoidanceAreas()
    self.completed = true
	ml_global_information.Await(2000)
end

function ffxiv_task_flee:task_fail_eval()
	return (not Player.alive) or (Player.incombat and math.distance3d(Player.pos,self.pos) < 2)
end

--=======================GRIND COMBAT TASK=========================-

ffxiv_task_grindCombat = inheritsFrom(ml_task)
function ffxiv_task_grindCombat.Create()
    local newinst = inheritsFrom(ffxiv_task_grindCombat)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetopos members
    newinst.name = "GRIND_COMBAT"
	newinst.targetid = 0
    newinst.noTeleport = false
	newinst.noFateSync = false
	newinst.teleportThrottle = 0
	newinst.targetPos = nil
	newinst.movementDelay = 0
	newinst.lastMovement = 0
	newinst.attackThrottle = false
	newinst.attackThrottleTimer = 0
	newinst.noFlee = false
	newinst.fleeHandled = false
	
	newinst.attemptPull = false
	newinst.pullTimer = 0
	newinst.pullPos1 = Player.pos
	newinst.pullPos2 = Player.pos
	newinst.betterTargetFunction = nil
	ffxiv_unstuck.Reset()
	
	--d("[GrindCombat]: Beginning new task.")
	
    return newinst
end

function ffxiv_task_grindCombat:Init()
    local ke_avoidance = ml_element:create( "Avoidance", c_avoid, e_avoid, 50 )
	self:add( ke_avoidance, self.overwatch_elements)
	
	local ke_autoPotion = ml_element:create( "AutoPotion", c_autopotion, e_autopotion, 45)
	self:add(ke_autoPotion, self.overwatch_elements)
	
	local ke_battleItem = ml_element:create( "BattleItem", c_battleitem, e_battleitem, 40 )
    self:add( ke_battleItem, self.overwatch_elements)
		
	local ke_stuck = ml_element:create( "BattleStuck", c_stuck, e_stuck, 150 )
    self:add( ke_stuck, self.process_elements)
	
	local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 40 )
	self:add( ke_rest, self.process_elements)
	
	local ke_companion = ml_element:create( "Companion", c_companion, e_companion, 35 )
	self:add( ke_companion, self.process_elements)
	
	local ke_stance = ml_element:create( "Stance", c_stance, e_stance, 30 )
	self:add( ke_stance, self.process_elements)
	
	local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 20 )
    self:add( ke_mount, self.process_elements)
	
    local ke_sprint = ml_element:create( "Sprint", c_sprint, e_sprint, 15 )
    self:add( ke_sprint, self.process_elements)
	
    local ke_roleset = ml_element:create( "RoleSet", c_roleautoset, e_roleautoset, 200 )
    self:add( ke_roleset, self.process_elements)
	
	local ke_bettertargetsearch = ml_element:create("SearchBetterTarget", c_bettertargetsearch, e_bettertargetsearch, 10)
	self:add( ke_bettertargetsearch, self.process_elements)
	
	self:AddTaskCheckCEs()
end

function ffxiv_task_grindCombat:Process()	
	ml_cne_hub.clear_queue()
	ml_cne_hub.eval_elements(self.process_elements)
	ml_cne_hub.queue_to_execute()
	local executed = ml_cne_hub.execute()
	if (executed) then
		--d("Executed a CNE.")
		return false
	end
		
	local target = EntityList:Get(self.targetid)
	if (table.valid(target)) then
	
		if (target.targetable) then
			local currentTarget = MGetTarget()
			if (not currentTarget or (currentTarget and currentTarget.id ~= target.id)) then
				--d("Set the target.")
				Player:SetTarget(target.id)
			end
		end
		
		self.pos = target.pos
		
		if (target.fateid ~= 0) then
			--d("Check fate details.")
			local fateID = target.fateid
			local fate = MGetFateByID(fateID)
			if ( fate and fate.completion < 100 and fate.status == 2) then
				if (Player.level > fate.maxlevel) then
					local myPos = Player.pos
					local distance = Distance2D(myPos.x, myPos.z, fate.x, fate.z)
					if (distance > (fate.radius * .98)) then
						local newTask = ffxiv_task_movetofate.Create()
						local fatePos = {x = fate.x, y = fate.y, z = fate.z}
						newTask.fateid = fateID
						newTask.allowRandomization = false
						newTask.pos = fatePos
						newTask.actualPos = fatePos
						ml_task_hub:CurrentTask():AddSubTask(newTask)
						return
					elseif (distance <= (fate.radius*.98)) then --else stuckoutside the fate,never syncing	
						if (Player:GetSyncLevel() == 0) then
							if (Now() > ml_global_information.syncTimer) then
								Player:SyncLevel()
								ml_global_information.syncTimer = Now() + 2000
							end
						end
					end
				end
			end
		end
		
		local teleport = ShouldTeleport(target.pos)
		local pos = target.pos
		local ppos = Player.pos
		local pullpos1 = self.pullPos1
		local pullpos2 = self.pullPos2
		local range = ml_global_information.AttackRange
		local eh = ConvertHeading(pos.h)
		local mobRear = ConvertHeading((eh - (math.pi)))%(2*math.pi)
		local nearbyMobCount = 0
		local nearbyMobs = EntityList("alive,aggressive,attackable,distanceto="..tostring(target.id)..",maxdistance=8")
		
		if (table.valid(nearbyMobs)) then
			nearbyMobCount = TableSize(nearbyMobs)
			for i,mob in pairs(nearbyMobs) do
				if (mob.id == target.id or mob.id == Player.id or mob.targetid == Player.id) then
					nearbyMobCount = nearbyMobCount - 1
				end
			end
		end
		
		local dist = PDistance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
		if (ml_global_information.AttackRange > 5) then			
			if (IsFlying() or (not InCombatRange(target.id) and not MIsCasting())) then
				if (teleport and dist > 60 and Now() > self.teleportThrottle) then
					local telePos = GetPosFromDistanceHeading(pos, 20, mobRear)
					local p = FindClosestMesh(telePos,10,false)
					if (table.valid(p)) then
						Hacks:TeleportToXYZ(tonumber(p.x),tonumber(p.y),tonumber(p.z),true)
						self.teleportThrottle = Now() + 1500
					end
				else
					if (IsFlying() or target.distance2d <= (target.hitradius + 1)) then
						Player:MoveTo(pos.x,pos.y,pos.z, 1.5, 0, 0, target.id)
					else
						if (math.distance3d(ppos,pos) < 60 and not IsFlying()) then
							local pathLength = Player:MoveTo(pos.x,pos.y,pos.z, (target.hitradius + 1), 0, 1, target.id)
							if (pathLength <= 0) then
								Player:MoveTo(pos.x,pos.y,pos.z, (target.hitradius + 1), 0, 0, target.id)
							end
						else
							Player:MoveTo(pos.x,pos.y,pos.z, (target.hitradius + 1), 0, 0, target.id)
						end
					end
				end
			end
			
			if (InCombatRange(target.id)) then
				if (Player.ismounted) then
					if (IsFlying()) then
						Descend()
					else
						Dismount()
					end
				end				
				if (Player:IsMoving() and not IsFlying()) then
					Player:Stop()
					--d("Need to stop so we can cast.")
					if (IsCaster(Player.job)) then
						return
					end
				end
				--if (not EntityIsFrontTight(target)) then
					--d("Need to face the enemy so we can cast.")
					Player:SetFacing(pos.x,pos.y,pos.z) 
				--end
			end
			
			--d("Checking if we are in combat range and the target was attackable.")
			if (not IsFlying()) then
				if (InCombatRange(target.id) and target.attackable and target.alive) then
					if (not self.attackThrottle or Now() > self.attackThrottleTimer) then
						--d("FIRE AWAY")
						SkillMgr.Cast( target )
						if (self.attackThrottle) then
							if (Player.level > target.level) then
								self.attackThrottleTimer = Now() + 2900
							end
						end
					end
				end
			end
		else
			--d("Melee class, check if we're in combat range and such..")
			if (IsFlying() or not InCombatRange(target.id)) then
				if (not self.attemptPull or nearbyMobCount == 0 or (self.attemptPull and (self.pullTimer == 0 or Now() > self.pullTimer))) then
					if (teleport and not self.attemptPull and dist > 60 and Now() > self.teleportThrottle) then
						local telePos = GetPosFromDistanceHeading(pos, 2, mobRear)
						local p = FindClosestMesh(telePos,10,false)
						if (table.valid(p)) then
							Hacks:TeleportToXYZ(tonumber(p.x),tonumber(p.y),tonumber(p.z),true)
							self.teleportThrottle = Now() + 1500
						end
					else
						if (math.distance3d(ppos,pos) < 60 and not IsFlying()) then
							local pathLength = Player:MoveTo(pos.x,pos.y,pos.z, (target.hitradius + 1), 0, 1, target.id)
							if (pathLength <= 0) then
								Player:MoveTo(pos.x,pos.y,pos.z, (target.hitradius + 1), 0, 0, target.id)
							end
						else
							Player:MoveTo(pos.x,pos.y,pos.z, (target.hitradius + 1), 0, 0, target.id)
						end
					end
					local dist1 = PDistance3D(ppos.x,ppos.y,ppos.z,pullpos1.x,pullpos1.y,pullpos1.z)
					local dist2 = PDistance3D(ppos.x,ppos.y,ppos.z,pullpos2.x,pullpos2.y,pullpos2.z)
					if (dist1 > 10) then
						self.pullPos2 = self.pullPos1
						self.pullPos1 = {x = ppos.x, y = ppos.y, z = ppos.z}
					end
					ml_task_hub:CurrentTask().lastMovement = Now()
				end
			end
			if (InCombatRange(target.id) or (target.distance2d <= 15 and not ml_navigation:IsUsingConnection())) then
				if (Player.ismounted) then
					if (IsFlying()) then
						Descend()
					else
						Dismount()
					end
				end
			end
			if (InCombatRange(target.id) and not IsFlying()) then
				Player:SetFacing(pos.x,pos.y,pos.z) 
				if (Player:IsMoving()) then
					Player:Stop()
				end
				-- Check for combat range before executing.
				if (not self.attackThrottle or Now() > self.attackThrottleTimer) then
					if (SkillMgr.Cast( target ) and self.attemptPull and self.pullTimer == 0 and nearbyMobCount > 0) then
						--Player:Stop()
						local pullPos = nil
						local dist1 = PDistance3D(ppos.x,ppos.y,ppos.z,self.pullPos1.x,self.pullPos1.y,self.pullPos1.z)
						if (dist1 > 6) then
							--d("using pullpos 1")
							pullPos = self.pullPos1
						else
							--d("using pullpos 2")
							pullPos = self.pullPos2
						end
						--Player:MoveTo(pullPos.x,pullPos.y,pullPos.z, 1, false, false, false)
						Player:MoveTo(pullPos.x,pullPos.y,pullPos.z, 1)
						self.pullTimer = Now() + 5000
					end
					if (self.attackThrottle) then
						if (Player.level > target.level) then
							self.attackThrottleTimer = Now() + 2900
						end
					end
				end
			end
		end
	else
		if (not ml_task_hub:CurrentTask():ParentTask() or ml_task_hub:CurrentTask():ParentTask().name ~= "LT_FATE" and Now() > ml_global_information.syncTimer) then
			if (ml_task_hub:CurrentTask():ParentTask()) then
				ml_debug("ParentTask:["..ml_task_hub:CurrentTask():ParentTask().name.."] is not valid for sync, Player will be unsynced.")
			end
			if (Player:GetSyncLevel() ~= 0) then
				Player:SyncLevel()
				ml_global_information.syncTimer = Now() + 1000
			end
		end
	end
end

function ffxiv_task_grindCombat:task_complete_eval()
	local target = EntityList:Get(self.targetid)
    if (not target or not target.alive or not target.attackable) then
		--d("[GrindCombat]: Task complete due to no target, target not alive, or target not attackable.")
        return true
    end
   
	return false
end
function ffxiv_task_grindCombat:task_complete_execute()
	ml_debug("[GrindCombat]: Task completing.")
	if (not ml_task_hub:CurrentTask():ParentTask() or ml_task_hub:CurrentTask():ParentTask().name ~= "LT_FATE" and Now() > ml_global_information.syncTimer) then
		if (Player:GetSyncLevel() ~= 0) then
			if (ml_task_hub:CurrentTask():ParentTask()) then
				ml_debug("ParentTask:["..ml_task_hub:CurrentTask():ParentTask().name.."] is not valid for sync, Player will be unsynced.")
			end
			--Player:SyncLevel()
			--ml_global_information.syncTimer = Now() + 1000
		end
	end
    Player:Stop()
	ActionList:StopCasting()
	self.completed = true
end

function ffxiv_task_grindCombat:task_fail_eval()
	local target = EntityList:Get(self.targetid)
	if (target) then
		if (target.fateid > 0 and target.fateid < 1500) then
			--d("checking if task should fail due to fate.")
			local fateID = target.fateid
			local fate = MGetFateByID(fateID)
			if (not fate) then
				--d("[GrindCombat]: Task complete due to fate target and fate not found.")
				return true
			elseif (fate and fate.completion > 99) then
				--d("[GrindCombat]: Task complete due to fate target and fate completion > 99 ["..tostring(fate.completion).."].")
				return true
			end
		end
	end
	
	if (not Player.alive) then
		--d("[GrindCombat]: Task failure due to death.")
		return true
	end
	
	if (not self.noFlee and not self.fleeHandled and c_flee:evaluate()) then
		d("[GrindCombat]: Task failure due to flee.")
		return true
	end
	
	return false
end
function ffxiv_task_grindCombat:task_fail_execute()
	ActionList:StopCasting()
	Player:Stop()
	self.valid = false
end

ffxiv_mesh_interact = inheritsFrom(ml_task)
function ffxiv_mesh_interact.Create()
    local newinst = inheritsFrom(ffxiv_mesh_interact)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "MESH_INTERACT"
	
	newinst.interact = 0
    newinst.interactLatency = 0
	
	newinst.skipTalkVal = gSkipTalk
	gSkipTalk = false
    return newinst
end

function ffxiv_mesh_interact:Init()
	local ke_detectYesNo = ml_element:create( "DetectYesNo", c_detectyesno, e_detectyesno, 150 )
    self:add( ke_detectYesNo, self.overwatch_elements)

	self:AddTaskCheckCEs()
end

function ffxiv_mesh_interact:task_complete_eval()	
	if (self.interact == 0) then
		local interacts = EntityList("nearest,targetable,type=7,chartype=0,maxdistance2d=6")
		if (table.valid(interacts)) then
			local i, interact = next(interacts)
			if (interact and interact.id and interact.id ~= 0) then
				self.interact = interact.id
			end
		end
		
		local interacts = EntityList("nearest,targetable,type=3,chartype=0,maxdistance2d=6")
		if (table.valid(interacts)) then
			local i, interact = next(interacts)
			if (interact and interact.id and interact.id ~= 0) then
				self.interact = interact.id
			end
		end
	end
	
	if (self.interact ~= 0) then
		local target = MGetTarget()
		if (not target or (target and target.id ~= self.interact)) then
			local interact = EntityList:Get(tonumber(self.interact))
			if (interact and interact.targetable) then
				Player:SetTarget(self.interact)
				d("Setting target for interact.")
			end		
		end
		
		if (target and target.id == self.interact and Now() > self.interactLatency) then
			if (not MIsLoading() and not MIsLocked()) then
				local interact = EntityList:Get(tonumber(self.interact))
				local radius = (interact.hitradius >= 1 and interact.hitradius) or 1
				if (interact and interact.interactable) then
				--if (interact and interact.distance < (radius * 4)) then
					Player:SetFacing(interact.pos.x,interact.pos.y,interact.pos.z)
					Player:Interact(interact.id)
					self.interactLatency = Now() + 1000
				end
			end
		end
	end
	
	local interact = EntityList:Get(tonumber(self.interact))
	if (not interact or not interact.targetable or MIsLoading() or interact.distance2d > 6) then
		return true
	end
end

function ffxiv_mesh_interact:task_complete_execute()
	d("Mesh interact task completed normally.")
	ml_mesh_mgr.ResetOMC()
	gSkipTalk = self.skipTalkVal
	self.completed = true
end

function ffxiv_mesh_interact:task_fail_eval()
    if (Player.incombat or not Player.alive) then
		return true
	end
	
	return false
end

function ffxiv_mesh_interact:task_fail_execute()
	d("Mesh interact task failed.")
	ml_mesh_mgr.ResetOMC()
	gSkipTalk = self.skipTalkVal
    self.valid = false
end

--=====USE BOAT====

c_detectyesno = inheritsFrom( ml_cause )
e_detectyesno = inheritsFrom( ml_effect )
function c_detectyesno:evaluate()
	return IsControlOpen("SelectYesno")
end
function e_detectyesno:execute()
	PressYesNo(true)
	ml_task_hub:ThisTask().preserveSubtasks = true
end

ffxiv_nav_interact = inheritsFrom(ml_task)
function ffxiv_nav_interact.Create()
    local newinst = inheritsFrom(ffxiv_nav_interact)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "NAV_INTERACT"
	
	newinst.contentid = 0
	newinst.interact = 0
	newinst.delayTimer = 0
	newinst.conversationIndex = 0
	newinst.conversationstrings = ""
	newinst.pos = false
	newinst.range = 1.5
	newinst.areaChanged = false
	newinst.removedMoveElement = false
	newinst.useTeleport = true
	newinst.failTimer = 0
	newinst.interactRange = nil
	newinst.dismountDistance = 15
	newinst.killParent = false
	newinst.abort = nil
	newinst.alwaysMount = false
	
	newinst.skipTalkVal = gSkipTalk
	gSkipTalk = false
	
    return newinst
end

function ffxiv_nav_interact:Init()
	local ke_skipTalk = ml_element:create( "SkipTalk", c_skiptalk, e_skiptalk, 200 )
    self:add(ke_skipTalk, self.overwatch_elements)
	
	local ke_detectYesNo = ml_element:create( "DetectYesNo", c_detectyesno, e_detectyesno, 150 )
    self:add( ke_detectYesNo, self.overwatch_elements)
	
	local ke_convIndex = ml_element:create( "ConversationIndex", c_selectconvindex, e_selectconvindex, 19 )
    self:add( ke_convIndex, self.overwatch_elements)
	
	local ke_isLoading = ml_element:create( "IsLoading", c_gatherisloading, e_gatherisloading, 250 )
    self:add( ke_isLoading, self.process_elements)
	
	local ke_teleportToMap = ml_element:create( "TeleportToMap", c_teleporttomap, e_teleporttomap, 140 )
    self:add( ke_teleportToMap, self.process_elements)
	
	local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 130 )
	self:add( ke_teleportToPos, self.process_elements)
	
	local ke_useNavInteraction = ml_element:create( "UseNavInteraction", c_usenavinteraction, e_usenavinteraction, 90 )
    self:add( ke_useNavInteraction, self.process_elements )
	
	local ke_getMovementPath = ml_element:create( "GetMovementPath", c_getmovementpath, e_getmovementpath, 85 )
    self:add( ke_getMovementPath, self.process_elements)
			
	local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 60 )
	self:add( ke_mount, self.process_elements)
			
	local ke_falling = ml_element:create( "Falling", c_falling, e_falling, 50 )
    self:add( ke_falling, self.process_elements)
	
	local ke_interact = ml_element:create( "Interact", c_dointeract, e_dointeract, 20 )
    self:add( ke_interact, self.process_elements)	
	
	local ke_walkToEntity = ml_element:create( "WalkToEntity", c_walktoentity, e_walktoentity, 10 )
    self:add( ke_walkToEntity, self.process_elements)

	self:AddTaskCheckCEs()
end

function ffxiv_nav_interact:task_complete_eval()
	local myTarget = MGetTarget()
	local ppos = Player.pos
	
	if (self.abort and type(self.abort) == "function") then
		if (self.abort() == true) then
			return true
		end
	end
	
	if (MIsLoading() and not self.areaChanged) then
		self.areaChanged = true
		return false
	end
	
	if (not MIsLoading() and self.areaChanged) then
		return true
	end
	
	if (MIsLocked() or IsControlOpen("SelectYesno")) then
		if (Player:IsMoving()) then
			Player:Stop()
		end
		return false
	end	
	
	return false
end

ffxiv_nav_interact.task_complete_execute = ffxiv_task_movetointeract.task_complete_execute
ffxiv_nav_interact.task_fail_execute = ffxiv_task_movetointeract.task_fail_execute
function ffxiv_nav_interact:task_fail_eval()
    if (Player.incombat or not Player.alive) then
		return true
	end
	
	return false
end


ffxiv_misc_shopping = inheritsFrom(ml_task)
function ffxiv_misc_shopping.Create()
    local newinst = inheritsFrom(ffxiv_misc_shopping)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "MISC_SHOPPING"
	
	newinst.setup = false
	newinst.startingCount = 0
	newinst.itemid = 0
	newinst.buyamount = 0
	newinst.id = 0
	newinst.mapid = 0
	newinst.pos = {}
	
    return newinst
end

function ffxiv_misc_shopping:task_complete_eval()
	local itemid;
	local itemtable = self.itemid
	if (table.valid(itemtable)) then
		itemid = itemtable[Player.job] or itemtable[-1]
	elseif (tonumber(itemtable)) then
		itemid = tonumber(itemtable)
	end
	
	if (not self.setup) then
		self.startingCount = ItemCount(itemid)
		self.setup = true
	end
	
	if (itemid) then
		local amount = tonumber(self.buyamount) or 0

		local itemcount = ItemCount(itemid)
		if (itemcount > 0) then			
			local buycomplete = false
			if (amount > 0) then
				if (itemcount >= (self.startingCount + amount)) then
					ml_debug("[Shopping_TaskComplete]: We only needed "..tostring(self.startingCount + amount)..", so we can complete this.", 3)
					buycomplete = true
				end
			else
				if (itemcount > 0) then
					ml_debug("[Shopping_TaskComplete]: We only need 1, so we can complete this.", 3)
					buycomplete = true
				end
			end
			
			if (buycomplete) then
				return true
			end
		end
	end
	
	return false
end

function ffxiv_misc_shopping:task_complete_execute()
	local shop = GetControl("Shop")
	if (shop and shop:IsOpen()) then
		shop:Close()	
		ml_global_information.Await(1500, function () return not IsControlOpen("Shop") end) 
		return false
	end
	
	local shopSelect = GetControl("SelectString")
	if (shopSelect and shopSelect:IsOpen()) then
		shopSelect:Close()	
		ml_global_information.Await(1500, function () return not IsControlOpen("SelectString") end) 
		return false
	end
	
	local shopSelectIcon = GetControl("SelectIconString")
	if (shopSelectIcon and shopSelectIcon:IsOpen()) then
		shopSelectIcon:Close()	
		ml_global_information.Await(1500, function () return not IsControlOpen("SelectIconString") end) 
		return false
	end
	
	self.completed = true
end

function ffxiv_misc_shopping:Init()
	local ke_moveToMap = ml_element:create( "MoveToMap", c_movetomap, e_movetomap, 150 )
    self:add( ke_moveToMap, self.process_elements)
	
	local ke_buy = ml_element:create( "Buy", c_buy, e_buy, 100 )
	self:add( ke_buy, self.process_elements)
	
	local ke_selectConvIndex = ml_element:create( "SelectConvIndex", c_selectconvindex, e_selectconvindex, 90 )
    self:add( ke_selectConvIndex, self.process_elements)
	
	local ke_positionLocked = ml_element:create( "PositionLocked", c_positionlocked, e_positionlocked, 80 )
    self:add( ke_positionLocked, self.process_elements)
	
	local ke_interact = ml_element:create( "Interact", c_moveandinteract, e_moveandinteract, 10 )
    self:add( ke_interact, self.process_elements)
	
	--Overwatch
	--local ke_flee = ml_element:create( "Flee", c_questflee, e_questflee, 25 )
    --self:add( ke_flee, self.overwatch_elements)

	self:AddTaskCheckCEs()
end

ffxiv_misc_switchclass = inheritsFrom(ml_task)
function ffxiv_misc_switchclass.Create()
    local newinst = inheritsFrom(ffxiv_misc_switchclass)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "MISC_SWITCHCLASS"
    
    newinst.params = {}
	newinst.stepCompleted = false	
	newinst.class = 0
	newinst.override = 0
	newinst.autoequipCheck = 0
    
    return newinst
end
function ffxiv_misc_switchclass:Init()	
	local ke_switchClass = ml_element:create( "SwitchClass", c_switchclass, e_switchclass, 100 )
    self:add( ke_switchClass, self.process_elements)
	
	local c_complete = inheritsFrom(ml_cause)
    function c_complete:evaluate() return ml_task_hub:CurrentTask():task_complete_eval() end
    
    local e_complete = inheritsFrom(ml_effect)
    function e_complete:execute() ml_task_hub:CurrentTask():task_complete_execute() end

    local ke_complete = ml_element:create( "TaskComplete", c_complete, e_complete, 1 )
	self:add( ke_complete, self.process_elements)
	
	gForceAutoEquip = true
	c_autoequip.postpone = 0
end
function ffxiv_misc_switchclass:task_complete_eval()
	local class = self.class
	
	if (Player.job ~= class) then
		d("[SwitchClass]: Need to change class to ["..tostring(class).."]")
		if (Busy() or Player.incombat) then
			d("[SwitchClass]: Cannot swap right now, invalid state.")
			return false
		end
		
		local override = self.override
		local gsvar = "gGearset"..tostring(Player.job)
		if (override ~= 0) then
			local commandString = "/gs change "..tostring(override)
			SendTextCommand(commandString)
			ml_global_information.Await(3000, function () return (Player.job == class) end)
			return true
		elseif (_G[gsvar] ~= 0) then
			local commandString = "/gs change "..tostring(_G[gsvar])
			SendTextCommand(commandString)
			ml_global_information.Await(3000, function () return (Player.job == class) end)
			return true
		else
			local canSwitch,bestWeapon = CanSwitchToClass(class)
			if (canSwitch) then
				return false
			else
				d("Not allowed to switch, no proper weapon found.")
			end	
			
			d("[SwitchClass]: Checking autoequip.")
			if (c_recommendequip:evaluate()) then
				e_recommendequip:execute()
				d("[SwitchClass]: Autoequip had work to do, so don't complete yet.")
				return false
			end
		end
	end
	
	d("[SwitchClass]: Completing task.")
	return true
end
function ffxiv_misc_switchclass:task_complete_execute()
	gForceAutoEquip = false
	self.completed = true
end
function ffxiv_misc_switchclass:task_fail_eval()
	if (Player.incombat or not Player.alive) then
		return true
	end
	
	return false
end
function ffxiv_misc_switchclass:task_fail_execute()
	self.valid = true
end

-- Use Aethernet
ffxiv_task_moveaethernet = inheritsFrom(ml_task)
function ffxiv_task_moveaethernet.Create()
    local newinst = inheritsFrom(ffxiv_task_moveaethernet)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "MOVEAETHERNET"
	
	newinst.started = Now()
	newinst.contentid = 0
	newinst.interact = 0
	newinst.pos = false
	newinst.areaChanged = false
	newinst.useTeleport = true
	newinst.failTimer = 0
	newinst.interactRange = 4
	newinst.killParent = false
	newinst.startMap = Player.localmapid
	newinst.conversationstring = ""
	newinst.conversationstrings = ""
	newinst.conversationindex = -1
	newinst.useAethernet = false
	newinst.unlockAethernet = false
	newinst.blockExecution = false
	newinst.detectedMovement = false
	newinst.stealthFunction = nil
	
	newinst.skipTalkVal = gSkipTalk
	gSkipTalk = false
	
	ml_global_information.monitorStuck = true
	newinst.alwaysMount = false
	newinst.initiatedPos = {}
	
	ffxiv_unstuck.Reset()
	
    return newinst
end

function ffxiv_task_moveaethernet:Init()
	local ke_stuck = ml_element:create( "Stuck", c_stuck, e_stuck, 150 )
    self:add( ke_stuck, self.overwatch_elements)

	local ke_teleportToPos = ml_element:create( "TeleportToPos", c_teleporttopos, e_teleporttopos, 130 )
    self:add( ke_teleportToPos, self.process_elements)
	
	local ke_useNavInteraction = ml_element:create( "UseNavInteraction", c_usenavinteraction, e_usenavinteraction, 100 )
    self:add( ke_useNavInteraction, self.process_elements)
	
	local ke_getMovementPath = ml_element:create( "GetMovementPath", c_getmovementpath, e_getmovementpath, 95 )
    self:add( ke_getMovementPath, self.process_elements)
	
	local ke_mount = ml_element:create( "Mount", c_mount, e_mount, 90 )
    self:add( ke_mount, self.process_elements)
    
    local ke_sprint = ml_element:create( "Sprint", c_sprint, e_sprint, 70 )
    self:add( ke_sprint, self.process_elements)
	
	local ke_falling = ml_element:create( "Falling", c_falling, e_falling, 60 )
    self:add( ke_falling, self.process_elements)
	
	local ke_interact = ml_element:create( "Interact", c_dointeract, e_dointeract, 20 )
    self:add( ke_interact, self.process_elements)
	
	local ke_walkToPos = ml_element:create( "WalkToPos", c_walktopos, e_walktopos, 5 )
    self:add( ke_walkToPos, self.process_elements)
	
	self:AddTaskCheckCEs()
end

function ffxiv_task_moveaethernet:task_complete_eval()
	if (IsControlOpen("SelectString") or IsControlOpen("SelectIconString")) then
		local convoList = GetConversationList()
		if (table.valid(convoList)) then
			if (self.useAethernet) then
				local aethernet = {
					us = "Aethernet",
					de = "Ätherytennetz",
					fr = "Réseau de transport urbain éthéré",
					jp = "都市転送網",
					cn = "都市传送网",
					kr = "도시 내 이동",
				}
				
				local residential = {
					us = "Residential District Aethernet",
					de = "Wohnviertel",
					fr = "Quartier résidentiel",
					jp = "冒険者居住区転送",
					cn = "冒险者住宅区传送",
					kr = "모험가 거주구로 이동",
				}
				
				for selectindex,convo in pairs(convoList) do
					local cleanedline = CleanConvoLine(convo)
					for language,astring in pairs(aethernet) do
						local cleanedastring = CleanConvoLine(astring)
						if (string.contains(cleanedline,cleanedastring) and not string.contains(cleanedline,residential[language])) then
							d("Use conversation line ["..tostring(convo).."] to open Aethernet menu.")
							SelectConversationLine(selectindex)
							ml_global_information.Await(500,2000, function () return not (IsControlOpen("SelectString") and IsControlOpen("SelectIconString")) end)
						end
					end
				end
				d("Checked if we need to open aetheryte menu.")
			end
			
			if (string.valid(self.conversationstring)) then
				d("Checking task conversation string.")
				for selectindex,convo in pairs(convoList) do
					local cleanedline = CleanConvoLine(convo)
					local cleanedv = CleanConvoLine(self.conversationstring)
					d("Looking for aethernet - ["..tostring(cleanedv).."], found ["..tostring(cleanedline).."].")
					if (string.contains(IsNull(cleanedline,""),IsNull(cleanedv,""))) then
						d("Use conversation line ["..tostring(selectindex).."] to select ["..tostring(convo).." for ["..tostring(self.conversationstring).."].")
						SelectConversationLine(selectindex)
						self.initiatedPos = Player.pos
						ml_global_information.Await(500,2000, function () return not (IsControlOpen("SelectString") and IsControlOpen("SelectIconString")) end)
						return false
					end
				end
			elseif (table.valid(self.conversationstrings)) then
				d("Checking task conversation strings.")
				for selectindex,convo in pairs(convoList) do
					local cleanedline = CleanConvoLine(convo)
					for k,v in pairs(self.conversationstrings) do
						local cleanedv = CleanConvoLine(v)
						d("Looking for aethernet - ["..tostring(cleanedv).."], found ["..tostring(cleanedline).."].")
						if (string.contains(IsNull(cleanedline,""),IsNull(cleanedv,""))) then
							d("Use conversation line ["..tostring(selectindex).."] to select ["..tostring(convo).." for ["..tostring(cleanedv).."].")
							SelectConversationLine(selectindex)
							self.initiatedPos = Player.pos
							ml_global_information.Await(500,2000, function () return not (IsControlOpen("SelectString") and IsControlOpen("SelectIconString")) end)
							return false
						end
					end
				end
			elseif (self.conversationindex > 0) then
				d("Checking task conversation index.")
				SelectConversationIndex(self.conversationindex)
				self.initiatedPos = Player.pos
				ml_global_information.Await(500,2000, function () return not (IsControlOpen("SelectString") and IsControlOpen("SelectIconString")) end)
				return false
			end
		end
	end
	
	local myTarget = MGetTarget()
	local ppos = Player.pos
	
	if (self.useAethernet and (MIsLoading() or self.startMap ~= Player.localmapid)) then
		if (MIsLoading()) then
			local initiatedPos = IsNull(self.initiatedPos,Player.pos)
			d("Triggering wait for full load-in.")
			ml_global_information.Await(10000, function () return (Player and not Busy() and math.distance3d(initiatedPos,Player.pos) > 10) end)
		end
		return true
	elseif (self.unlockAethernet and AceLib.API.Map.HasAttunements(self.contentid)) then
		return true
	end
	
	local interactable = nil
	if (self.interact ~= 0) then
		interactable = EntityList:Get(self.interact)
	end
	
	local dist2d,dist3d = math.distance2d(ppos,self.pos),math.distance3d(ppos,self.pos)
	if (self.interact ~= 0 and dist2d < 50 and dist3d < 50) then
		if (not interactable or not interactable.targetable) then
			return true
		end
	else
		if (dist2d <= 5 and dist3d <= 10) then
			local interacts = EntityList("targetable,contentid="..tostring(self.contentid)..",maxdistance=10")
			if (not table.valid(interacts)) then
				return true
			end
		end			
	end
	
	return false
end

ffxiv_task_moveaethernet.task_complete_execute = ffxiv_task_movetointeract.task_complete_execute
ffxiv_task_moveaethernet.task_fail_eval = ffxiv_task_movetointeract.task_fail_eval
ffxiv_task_moveaethernet.task_fail_execute = ffxiv_task_movetointeract.task_fail_execute

ffxiv_misc_scripexchange = inheritsFrom(ml_task)
function ffxiv_misc_scripexchange.Create()
    local newinst = inheritsFrom(ffxiv_misc_scripexchange)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "MISC_SCRIPEXCHANGE"
	
	newinst.categories = {}
	newinst.loaded = false
	
	local appraiser = FindNearestCollectableAppraiser()
	if (table.valid(appraiser)) then
		newinst.id = appraiser.id
		newinst.mapid = appraiser.mapid
		newinst.pos = appraiser.pos
		newinst.aethid = appraiser.aethid
	else
		newinst.id = 1013396
		newinst.mapid = 156
		newinst.pos = {
			x = 50.28, y = 31.09, z = -735.2
		}
	end
	
    return newinst
end

function ffxiv_misc_scripexchange:task_complete_eval()
	local checkedAll = true
	for i = 0,10 do
		if (self.categories[i] ~= true) then
			checkedAll = false
		end
	end
	return checkedAll
end

function ffxiv_misc_scripexchange:task_complete_execute()
	local supply = GetControl("MasterPieceSupply")
	if (supply and supply:IsOpen()) then
		supply:Close()	
		ml_global_information.Await(1500, function () return not IsControlOpen("MasterPieceSupply") end) 
		return
	end
	self.completed = true
end

function ffxiv_misc_scripexchange:Init()
	local ke_moveToMap = ml_element:create( "MoveToMap", c_movetomap, e_movetomap, 150 )
    self:add( ke_moveToMap, self.process_elements)
	
	local ke_scripExchange = ml_element:create( "ScripExchange", c_scripexchange, e_scripexchange, 100 )
	self:add( ke_scripExchange, self.process_elements)
	
	local ke_selectConvIndex = ml_element:create( "SelectConvIndex", c_selectconvindex, e_selectconvindex, 90 )
    self:add( ke_selectConvIndex, self.process_elements)
	
	local ke_positionLocked = ml_element:create( "PositionLocked", c_positionlocked, e_positionlocked, 80 )
    self:add( ke_positionLocked, self.process_elements)
	
	local ke_interact = ml_element:create( "Interact", c_moveandinteract, e_moveandinteract, 10 )
    self:add( ke_interact, self.process_elements)

	self:AddTaskCheckCEs()
end

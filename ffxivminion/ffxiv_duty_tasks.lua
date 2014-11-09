c_dutyavoid = inheritsFrom( ml_cause )
e_dutyavoid = inheritsFrom( ml_effect )
c_dutyavoid.avoidTime = nil
c_dutyavoid.facing = 0
function c_dutyavoid:evaluate()
	if (ml_task_hub:ThisTask().name ~= "DUTY_KILL") then
		return false
	end
	
	if (not ml_task_hub:ThisTask().encounterData["avoid"] or 
		not ml_task_hub:ThisTask().encounterData["avoidpos"]) 
	then
		return false
	end
	
	for uniqueid in StringSplit(ml_task_hub:CurrentTask().encounterData.bossIDs,";") do
		local el = EntityList("nearest,alive,contentid="..uniqueid..",maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
		if (ValidTable(el)) then
			for id, target in pairs(el) do
				for spell in StringSplit(ml_task_hub:ThisTask().encounterData["avoid"],";") do
					if (tonumber(spell) == target.castinginfo.channelingid) then
						c_dutyavoid.avoidTime = target.castinginfo.casttime + 1000
						c_dutyavoid.facing = target.pos.h
						return true
					end
				end
			end
		end		
	end
	
    return false
end
function e_dutyavoid:execute() 
	local avoidpos = ml_task_hub:ThisTask().encounterData["avoidpos"]
	local avoidtime = ml_task_hub:ThisTask().encounterData["avoidTime"] or c_dutyavoid.avoidTime
	
	GameHacks:TeleportToXYZ(avoidpos.x, avoidpos.y, avoidpos.z)
	Player:SetFacing(c_dutyavoid.facing)
	ml_task_hub:ThisTask().immunePulses = 0
	ml_task_hub:ThisTask().failTimer = 0
	ml_task_hub:CurrentTask():SetDelay(avoidtime)
	--[[
	local newTask = ffxiv_task_duty_avoid.Create()
	newTask.pos = ml_task_hub:ThisTask().encounterData["avoidpos"]
	newTask.targetid = target.id
	newTask.interruptCasting = true
	newTask.maxTime = tonumber(target.castinginfo.casttime) + 500
	ml_task_hub:ThisTask().preserveSubtasks = true
	ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	--]]
end

ffxiv_duty_kill_task = inheritsFrom(ml_task)
function ffxiv_duty_kill_task.Create()
    local newinst = inheritsFrom(ffxiv_duty_kill_task)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
	newinst.name = "DUTY_KILL"
	newinst.timer = 0
	newinst.failed = false
	newinst.failTimer = 0
	newinst.encounterData = {}
	newinst.suppressFollow = false
	newinst.suppressFollowTimer = 0
	newinst.suppressAssist = false
	newinst.pullHandled = false
	newinst.hasSynced = false
	
	newinst.immunePulses = 0
	newinst.lastEntity = nil
	newinst.lastHPPercent = 100
	newinst.immuneMax = 80
	
    return newinst
end

function ffxiv_duty_kill_task:Process()	
	
	if (not self.hasSynced) then
		Player:SetFacingSynced(Player.pos.h)
		self.hasSynced = true
	end
	
	local killPercent = nil
	if ( self.encounterData["killto%"]) then
		killPercent = tonumber(self.encounterData["killto%"])
	end

	local entity = GetDutyTarget(killPercent)
	
	local myPos = shallowcopy(Player.pos)
	local fightPos = nil
	if (self.encounterData.fightPos) then
		fightPos = self.encounterData.fightPos["General"]
	end
	
	local startPos = nil
	if (self.encounterData.startPos) then
		startPos = self.encounterData.startPos["General"]
	end
	
	if (ValidTable(entity)) then
		if (self.lastEntity == nil or self.lastEntity ~= entity.id) then
			self.lastEntity = entity.id
			self.lastHPPercent = entity.hp.percent
			self.immunePulses = 0
		elseif (self.lastEntity == entity.id) then
			if (self.lastHPPercent == entity.hp.percent) then
				self.immunePulses = self.immunePulses + 1
			elseif (self.lastHPPercent > entity.hp.percent) then
				self.lastHPPercent = entity.hp.percent
				self.immunePulses = 0
			end
		end
		
		if (fightPos and not self.pullHandled) then
			--fightPos is for handling pull situations
			if (entity.targetid == 0) then
				Player:SetTarget(entity.id)
				SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
				SkillMgr.Cast( entity )
				self.hasFailed = false
			else
				GameHacks:TeleportToXYZ(fightPos.x, fightPos.y, fightPos.z)
				SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
				self.pullHandled = true
			end
		elseif (fightPos and self.pullHandled and Distance3D(myPos.x,myPos.y,myPos.z,fightPos.x,fightPos.y,fightPos.z) > 1) then
			GameHacks:TeleportToXYZ(fightPos.x, fightPos.y, fightPos.z)
			SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
		elseif (startPos and fightPos == nil and Distance3D(myPos.x,myPos.y,myPos.z,startPos.x,startPos.y,startPos.z) > 1 and TableSize(SkillMgr.teleBack) == 0) then
			GameHacks:TeleportToXYZ(startPos.x, startPos.y, startPos.z)
			SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
		elseif (ml_task_hub:CurrentTask().encounterData.doKill ~= nil and 
				ml_task_hub:CurrentTask().encounterData.doKill == false ) then
					if (entity.targetid == 0) then
						Player:SetTarget(entity.id)
						SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
						SkillMgr.Cast( entity )
						self.hasFailed = false
					else
						self.hasFailed = true
					end
		elseif (ml_task_hub:CurrentTask().encounterData.doKill == nil or 
				ml_task_hub:CurrentTask().encounterData.doKill == true) then
					self.hasFailed = false
					
					local pos = entity.pos
					Player:SetTarget(entity.id)
					
					--Telecasting, teleport to mob portion.
					if (ml_global_information.AttackRange < 5 and gUseTelecast == "1" and entity.castinginfo.channelingid == 0 and
						gTeleport == "1" and SkillMgr.teleCastTimer == 0 and SkillMgr.IsGCDReady()
						and entity.targetid ~= Player.id) then
						
						self.suppressFollow = true
						self.suppressFollowTimer = Now() + 2500
						
						SkillMgr.teleBack = startPos
						GameHacks:TeleportToXYZ(pos.x + 1,pos.y, pos.z)
						TurnAround()
						--Player:SetFacing(pos.h)
						SkillMgr.teleCastTimer = Now() + 1600
					end
					
					SetFacing(pos.x, pos.y, pos.z)
					SkillMgr.Cast( entity )
					
					--Telecasting, teleport back to spot portion.
					if (TableSize(SkillMgr.teleBack) > 0 and 
						(Now() > SkillMgr.teleCastTimer or entity.castinginfo.channelingid ~= 0 or entity.targetid == Player.id)) then
						local back = SkillMgr.teleBack
						--Player:Stop()
						GameHacks:TeleportToXYZ(back.x, back.y, back.z)
						Player:SetFacingSynced(back.h)
						--Player:SetFacing(back.h)
						SkillMgr.teleBack = {}
						SkillMgr.teleCastTimer = 0
					end
					
		end
	else
		self.hasFailed = true
	end
	
	if (TableSize(ml_task_hub:CurrentTask().process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(ml_task_hub:CurrentTask().process_elements)
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end

function ffxiv_duty_kill_task:task_complete_eval()
	-- If the task has failed and we haven't yet started the countdown, start it.
	if (not self.encounterData.noImmune) then
		if (self.immunePulses > self.immuneMax) then
			d("Immune pulses reached "..tostring(self.immunePulses).." which exceeds the max of "..tostring(self.immuneMax)) 
			return true
		end
	end
	
	if (self.hasFailed and self.failTimer == 0) then
		if (self.encounterData.failTime and self.encounterData.failTime > 0) then
			self.failTimer = Now() + self.encounterData.failTime
		else
			return true
		end
	end
	
	-- If the task had started counting down, but is no longer failing, reset the state.
	if (not self.hasFailed and self.failTimer ~= 0) then
		self.failTimer = 0
	end
	
	-- If the failTimer is not 0 (starting value) and we've exceeded the time, end the task.
	if (self.failTimer > 0 and Now() > self.failTimer) then
		return true
	end
	
    return false
end
function ffxiv_duty_kill_task:task_complete_execute()
    ml_task_hub:CurrentTask().completed = true
	ml_task_hub:CurrentTask():ParentTask().encounterCompleted = true
end

function ffxiv_duty_kill_task:Init()	
	local ke_dutyAvoid = ml_element:create( "DutyAvoid", c_dutyavoid, e_dutyavoid, 35 )
    self:add( ke_dutyAvoid, self.overwatch_elements)
	
    self:AddTaskCheckCEs()
end

--=================================================================
--Interact Task - Can be used for doors, keys, other interactables. 
-- Leader Only
--=================================================================

c_dutyAtInteract = inheritsFrom( ml_cause )
e_dutyAtInteract = inheritsFrom( ml_effect )
function c_dutyAtInteract:evaluate()
	if (ml_task_hub:ThisTask().name ~= "LT_LOOT" and ml_task_hub:ThisTask().name ~= "LT_INTERACT") then
		return false
	end
	
	if (not ml_task_hub:CurrentTask().encounterData["lootid"] and 
		not ml_task_hub:CurrentTask().encounterData["interactid"]) 
	then
		return false
	end
	
	if (not ml_task_hub:CurrentTask().attarget) then
		local tpos = {}
		local ppos = {}
		
		local searchid = 0
		local lootid = tonumber(ml_task_hub:CurrentTask().encounterData.lootid) or 0
		local interactid = tonumber(ml_task_hub:CurrentTask().encounterData.interactid) or 0
		if (lootid ~= 0) then
			searchid = lootid
		elseif (interactid ~= 0) then
			searchid = interactid
		end
		
		if (searchid == 0) then
			return false
		end
		
		local interacts = EntityList("type=7,chartype=0")
		for i, interactable in pairs(interacts) do
			if interactable.uniqueid == searchid then
				tpos = interactable.pos
				ppos = Player.pos
				local dist = Distance3D(ppos.x,ppos.y,ppos.z,tpos.x,tpos.y,tpos.z)
				if (dist <= 5) then
					return true
				end
			end
		end
		
		local chests = EntityList("type=4,chartype=0")
		for i, interactable in pairs(chests) do
			if interactable.uniqueid == searchid then
				tpos = interactable.pos
				ppos = Player.pos
				local dist = Distance3D(ppos.x,ppos.y,ppos.z,tpos.x,tpos.y,tpos.z)
				if (dist <= 5) then
					return true
				end
			end
		end
		
		local npcs = EntityList("type=3,chartype=0")
		for i, interactable in pairs(npcs) do
			if interactable.uniqueid == searchid then
				tpos = interactable.pos
				ppos = Player.pos
				local dist = Distance3D(ppos.x,ppos.y,ppos.z,tpos.x,tpos.y,tpos.z)
				if (dist <= 5) then
					return true
				end
			end
		end
		
		if (not ml_task_hub:CurrentTask().repositioned) then
			GameHacks:TeleportToXYZ(tpos.x,tpos.y,tpos.z)
			Player:SetFacingSynced(tpos.x,tpos.y,tpos.z)
			ml_task_hub:CurrentTask().repositioned = true
			--[[ Need a mesh to make this work.
			local ppos = Player.pos
			if (not NavigationManager:IsOnMesh(ppos.x,ppos.y,ppos.z)) then
				local p,dist = NavigationManager:GetClosestPointOnMesh(tpos)
				GameHacks:TeleportToXYZ(p.x,p.y,p.z)
				ml_task_hub:CurrentTask().repositioned = true
			end	
			--]]
		end
		
		--[[
		if (TimeSince(ml_task_hub:CurrentTask().throttle) > 1500) then
			local PathSize = Player:MoveTo(tpos.x,tpos.y,tpos.z,2,false,false)
			ml_task_hub:CurrentTask().throttle = Now()
		end
		--]]
	end
	
	return false
end
function e_dutyAtInteract:execute()
	ml_task_hub:CurrentTask().attarget = true
end

c_interact = inheritsFrom( ml_cause )
e_interact = inheritsFrom( ml_effect )
c_interact.id = 0
function c_interact:evaluate()
	if (ml_task_hub:ThisTask().name ~= "LT_LOOT" and ml_task_hub:ThisTask().name ~= "LT_INTERACT") then
		return false
	end
	
	if (not ml_task_hub:CurrentTask().encounterData["lootid"] and 
		not ml_task_hub:CurrentTask().encounterData["interactid"]) 
	then
		return false
	end
	
	if (not ml_task_hub:CurrentTask().attarget) then
		return false
	end
	
	if (Now() < ml_task_hub:CurrentTask().latencyTimer) then
		return false
	end
	ml_task_hub:CurrentTask().latencyTimer = Now() + 1500
	
	local searchid = 0
	local lootid = tonumber(ml_task_hub:CurrentTask().encounterData.lootid) or 0
	local interactid = tonumber(ml_task_hub:CurrentTask().encounterData.interactid) or 0
	if (lootid ~= 0) then
		searchid = lootid
	elseif (interactid ~= 0) then
		searchid = interactid
	end
	
	if (searchid == 0) then
		return false
	end
	
	local interacts = EntityList("type=7,chartype=0,maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
	for i, interactable in pairs(interacts) do
		if interactable.uniqueid == searchid then
			if (interactable.targetable) then
				c_interact.id = interactable.id
				return true
			end
		end
	end
	
	local chests = EntityList("type=4,chartype=0,maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
	for i, interactable in pairs(chests) do
		if interactable.uniqueid == searchid then
			if (interactable.targetable) then
				c_interact.id = interactable.id
				return true
			end
		end
	end
	
	local npcs = EntityList("type=3,chartype=0,maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
	for i, interactable in pairs(npcs) do
		if interactable.uniqueid == searchid then
			if (interactable.targetable) then
				c_interact.id = interactable.id
				return true
			end
		end
	end
	
	ml_task_hub:CurrentTask().hasInteract = false
    return false
end
----------------------------------------------------------------------------------------------------------------------------------------
function e_interact:execute()
	local interact = EntityList:Get(c_interact.id)
	Player:SetTarget(interact.id)
	local pos = interact.pos
	SetFacing(pos.x,pos.y,pos.z)
	Player:Interact(interact.id)
	ml_task_hub:CurrentTask().latencyTimer = Now() + 500
end
----------------------------------------------------------------------------------------------------------------------------------------
ffxiv_task_interact = inheritsFrom(ml_task)
function ffxiv_task_interact.Create()
    local newinst = inheritsFrom(ffxiv_task_interact)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
   
	newinst.name = "LT_INTERACT"
	newinst.encounterData = {}
	newinst.failTimer = 0
	
	newinst.repositioned = false
	newinst.attarget = false
	newinst.latencyTimer = 0
	newinst.hasInteract = true
	newinst.isComplete = false
	newinst.maxTime = 0
	
    return newinst
end
----------------------------------------------------------------------------------------------------------------------------------------
function ffxiv_task_interact:Init()
	local ke_atInteract = ml_element:create( "AtInteract", c_dutyAtInteract, e_dutyAtInteract, 10 )
    self:add( ke_atInteract, self.process_elements)
	
	local ke_yesnoQuest = ml_element:create( "QuestYesNo", c_questyesno, e_questyesno, 6 )
    self:add(ke_yesnoQuest, self.process_elements)
	
    local ke_interact = ml_element:create( "Interact", c_interact, e_interact, 5 )
    self:add(ke_interact, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_interact:task_complete_eval()
	if (self.maxTime == 0) then
		if (self.encounterData.maxTime and self.encounterData.maxTime > 0) then
			self.maxTime = Now() + self.encounterData.maxTime
		else
			self.maxTime = Now() + 10000
		end
	end
	
	if (Player.castinginfo.channelingid == 24) then
		return false
	end
	
	if (Now() > self.maxTime) then
		return true
	end
	
	if (not ml_task_hub:CurrentTask().hasInteract and not self.isComplete) then
		self.isComplete = true
		if (self.encounterData.failTime and self.encounterData.failTime > 0) then
			self.failTimer = Now() + self.encounterData.failTime
		else
			self.failTimer = Now() + 1000
		end
		return false
	end
	
	-- If the task had started counting down, but is no longer failing, reset the state.
	if (not self.isComplete and self.failTimer ~= 0) then
		self.failTimer = 0
		return false
	end
	
	-- If the failTimer is not 0 (starting value) and we've exceeded the time, end the task.
	if (self.failTimer > 0 and Now() > self.failTimer) then
		return true
	end
	
	return false
end

function ffxiv_task_interact:task_complete_execute()
	self.completed = true
	self:ParentTask().encounterCompleted = true
end

--===================================================
--Loot Task
--===================================================
ffxiv_task_loot = inheritsFrom(ml_task)
function ffxiv_task_loot.Create()
    local newinst = inheritsFrom(ffxiv_task_loot)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
   
	newinst.name = "LT_LOOT"
	newinst.encounterData = {}
	newinst.failTimer = 0
	
	newinst.repositioned = false
	newinst.attarget = false
	newinst.latencyTimer = 0
	newinst.isComplete = false
	newinst.maxTime = 0
	
    return newinst
end
----------------------------------------------------------------------------------------------------------------------------------------
function ffxiv_task_loot:Init()
	local ke_atInteract = ml_element:create( "AtInteract", c_dutyAtInteract, e_dutyAtInteract, 10 )
    self:add( ke_atInteract, self.process_elements)
	
	local ke_yesnoQuest = ml_element:create( "QuestYesNo", c_questyesno, e_questyesno, 6 )
    self:add(ke_yesnoQuest, self.process_elements)
	
    local ke_interact = ml_element:create( "Interact", c_interact, e_interact, 5 )
    self:add(ke_interact, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_loot:task_complete_eval()
	if (self.maxTime == 0) then
		if (self.encounterData.maxTime and self.encounterData.maxTime > 0) then
			self.maxTime = Now() + self.encounterData.maxTime
		else
			self.maxTime = Now() + 10000
		end
	end
	
	if (Player.castinginfo.channelingid == 24) then
		return false
	end
	
	if (Now() > self.maxTime) then
		return true
	end
	
	if (Inventory:HasLoot()) then
		return true
	end
	
	return false
end

function ffxiv_task_loot:task_complete_execute()
	self.completed = true
	self:ParentTask().encounterCompleted = true
end


--Loot Roll task
c_roll = inheritsFrom( ml_cause )
e_roll = inheritsFrom( ml_effect )
function c_roll:evaluate()
	if (not Inventory:HasLoot()) then
		return false	
	end
	
	if (Now() < ml_task_hub:CurrentTask().latencyTimer) then
		return false
	end
	ml_task_hub:CurrentTask().latencyTimer = Now() + 1000
	
	local loot = Inventory:GetLootList()
	if (loot and ml_task_hub:CurrentTask().rollstate ~= "Complete") then
		return true
	end
    
    return false
end
function e_roll:execute()
	ml_task_hub:CurrentTask().isComplete = false
	local loot = Inventory:GetLootList()
	if (loot) then
		local i,e = next(loot)
		while (i~=nil and e~=nil) do    
			if (ml_task_hub:CurrentTask().rollstate == "Need") then
				if (gLootOption == "Need" or gLootOption == "Any") then 
					d("Attempting to need on loot, result was:"..tostring(e:Need()))
					ml_task_hub:CurrentTask().rollstate = "Greed"
					ml_task_hub:CurrentTask().latencyTimer = Now() + 1000
					return
				end
				ml_task_hub:CurrentTask().rollstate = "Greed"
			end
			if (ml_task_hub:CurrentTask().rollstate == "Greed") then
				if (gLootOption == "Need" or gLootOption == "Greed" or gLootOption == "Any") then 
					d("Attempting to greed on loot, result was:"..tostring(e:Greed()))
					ml_task_hub:CurrentTask().rollstate = "Pass"					
					ml_task_hub:CurrentTask().latencyTimer = Now() + 1000
					return
				end
				ml_task_hub:CurrentTask().rollstate = "Pass"
			end
			if (ml_task_hub:CurrentTask().rollstate == "Pass") then
				d("Attempting to pass on loot, result was:"..tostring(e:Pass()))
				ml_task_hub:CurrentTask().latencyTimer = Now() + 1000
				ml_task_hub:CurrentTask().rollstate = "Complete"
			end
			i,e = next (loot,i)
		end  
	end
end


ffxiv_task_lootroll = inheritsFrom(ml_task)
function ffxiv_task_lootroll.Create()
    local newinst = inheritsFrom(ffxiv_task_lootroll)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
	newinst.encounterData = {}
   
    newinst.name = "LT_LOOTROLL"
	newinst.rollstate = "Need"
	newinst.failTimer = 0
	newinst.isComplete = false
	newinst.latencyTimer = 0
	newinst.maxTime = 0
    
    return newinst
end

function ffxiv_task_lootroll:Init() 	
	local ke_lootroll = ml_element:create( "Roll", c_roll, e_roll, 10 )
    self:add(ke_lootroll, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_lootroll:task_complete_eval()
	if (self.maxTime == 0) then
		self.maxTime = Now() + 10000
	end
	
	if (Now() > self.maxTime) then
		return true
	end
	
	if (not Inventory:HasLoot()) then
		return true
	end
	
	return false
end

function ffxiv_task_lootroll:task_complete_execute()
    self.completed = true
end

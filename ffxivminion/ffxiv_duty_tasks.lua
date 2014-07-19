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
	
    return newinst
end

function ffxiv_duty_kill_task:Process()	
	
	local killPercent = nil
	if ( self.encounterData["killto%"]) then
		killPercent = tonumber(self.encounterData["killto%"])
	end

	local entity = GetDutyTarget(killPercent)
	
	local myPos = Player.pos
	local fightPos = nil
	if (self.encounterData.fightPos) then
		fightPos = self.encounterData.fightPos["General"]
	end
	
	local startPos = nil
	if (self.encounterData.startPos) then
		startPos = self.encounterData.startPos["General"]
	end
	
	if (ValidTable(entity)) then
		if (fightPos and not self.pullHandled) then
			--fightPos is for handling pull situations
			if (self.timer == 0) then
				--if we haven't pulled yet, attack the proper entity and tack on a few seconds of wait time
				Player:SetFacingSynced(entity.pos.h)
				Player:SetTarget(entity.id)
				SetFacing(entity.pos.x,entity,pos.y,entity.pos.z)
				SkillMgr.Cast( entity )
				self.timer = Now() + math.random(3000,4000)
				self.hasFailed = false
			elseif (Now() <= self.timer) then
				SetFacing(entity.pos.x,entity,pos.y,entity.pos.z)
				SkillMgr.Cast( entity )
				self.hasFailed = false
			elseif (Now() > self.timer and Player.incombat) then
				--after we wait enough time, move to the proper fightPos
				GameHacks:TeleportToXYZ(fightPos.x, fightPos.y, fightPos.z)
				Player:SetFacingSynced(fightPos.h)
				self.pullHandled = true
			end
		elseif (ml_task_hub:CurrentTask().encounterData.doKill ~= nil and 
				ml_task_hub:CurrentTask().encounterData.doKill == false ) then
					if (entity.targetid == 0) then
						--Player:SetFacingSynced(entity.pos.h)
						Player:SetTarget(entity.id)
						SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
						SkillMgr.Cast( entity )
						self.hasFailed = false
					else
						self.hasFailed = true
					end
			--return false
		elseif (ml_task_hub:CurrentTask().encounterData.doKill == nil or 
				ml_task_hub:CurrentTask().encounterData.doKill == true) then
					self.hasFailed = false
					
					local pos = entity.pos
					
					SetFacing(pos.x, pos.y, pos.z)
					Player:SetTarget(entity.id)
					
					--Telecasting, teleport to mob portion.
					if (ml_global_information.AttackRange < 5 and entity.castinginfo.channelingid == 0 and
						gTeleport == "1" and SkillMgr.teleCastTimer == 0 and SkillMgr.IsGCDReady()
						and entity.targetid ~= Player.id) then
						
						self.suppressFollow = true
						self.suppressFollowTimer = Now() + 2500
						
						SkillMgr.teleBack = startPos
						GameHacks:TeleportToXYZ(pos.x + 1,pos.y, pos.z)
						Player:SetFacingSynced(pos.h)
						SkillMgr.teleCastTimer = Now() + 1600
					end
					
					SkillMgr.Cast( entity )
					
					--Telecasting, teleport back to spot portion.
					if (TableSize(SkillMgr.teleBack) > 0 and 
						(Now() > SkillMgr.teleCastTimer or entity.castinginfo.channelingid ~= 0 or entity.targetid == Player.id)) then
						local back = SkillMgr.teleBack
						--Player:Stop()
						GameHacks:TeleportToXYZ(back.x, back.y, back.z)
						Player:SetFacingSynced(back.h)
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
    self:AddTaskCheckCEs()
end

--=================================================================
--Interact Task - Can be used for doors, keys, other interactables. 
-- Leader Only
--=================================================================

c_dutyAtInteract = inheritsFrom( ml_cause )
e_dutyAtInteract = inheritsFrom( ml_effect )
function c_dutyAtInteract:evaluate()
	if (not ml_task_hub:CurrentTask().attarget) then
		local tpos = {}
		local ppos = {}
		
		local interacts = EntityList("type=7,chartype=0")
		for i, interactable in pairs(interacts) do
			if interactable.uniqueid == tonumber(ml_task_hub:CurrentTask().encounterData.interactid) then
				tpos = interactable.pos
				ppos = Player.pos
				local dist = Distance3D(ppos.x,ppos.y,ppos.z,tpos.x,tpos.y,tpos.z)
				--d("Distance to target = "..tostring(dist))
				if (dist <= 5) then
					return true
				end
			end
		end
		
		if (not ml_task_hub:CurrentTask().repositioned) then
			GameHacks:TeleportToXYZ(tpos.x,tpos.y,tpos.z)
			Player:SetFacingSynced(tpos.h)
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
c_interact.object = {}
c_interact.lastInteract = 0
function c_interact:evaluate()
	if (not ml_task_hub:CurrentTask().attarget) then
		return false
	end
	
	local interacts = EntityList("type=7,chartype=0,maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
	for i, interactable in pairs(interacts) do
		if interactable.uniqueid == tonumber(ml_task_hub:CurrentTask().encounterData.interactid) then
			if (interactable.targetable) then
				if (c_interact.lastInteract == 0 or Now() > c_interact.lastInteract) then
					Player:SetTarget(interactable.id)
					c_interact.object = interactable
					c_interact.lastInteract = Now() + 1000
					return true
				else
					return false
				end
			end
		end
	end
	
	--Couldn't find the interactable, terminate the task.
	if (ml_task_hub:CurrentTask().throttle == 0) then
		ml_task_hub:CurrentTask().throttle = Now() + 1500
	end
	
	if (Now() > ml_task_hub:CurrentTask().throttle) then
		ml_task_hub:CurrentTask():Terminate()
	end
	
    return false
end
----------------------------------------------------------------------------------------------------------------------------------------
function e_interact:execute()
	local pos = c_interact.object.pos
	SetFacing(pos.x,pos.y,pos.z)
	Player:Interact(c_interact.object.id)
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
   
	newinst.encounterData = {}
	newinst.failTimer = 0
    newinst.name = "LT_INTERACT"
	newinst.repositioned = false
	newinst.attarget = false
	newinst.throttle = 0
	
	if (newinst.encounterData.maxTime and newinst.encounterData.maxTime > 0) then
		newinst.maxTime = Now() + newinst.encounterData.maxTime
	else
		newinst.maxTime = Now() + 5000
	end
	
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
	if (Player.castinginfo.channelingid == 24) then
		return false
	end
	
	if (Now() > self.maxTime) then
		return true
	end
end

function ffxiv_task_interact:task_complete_execute()
	self.completed = true
	self:ParentTask().encounterCompleted = true
end

function ffxiv_task_interact:OnTerminate()
	self:ParentTask().encounterCompleted = true
end

--===================================================
--Loot Task
--===================================================

c_roll = inheritsFrom( ml_cause )
e_roll = inheritsFrom( ml_effect )
function c_roll:evaluate()
	if (not Inventory:HasLoot()) then
		return false	
	end
	
	local loot = Inventory:GetLootList()
	if (loot and ml_task_hub:CurrentTask().rollstate ~= "Complete" and Now() > ml_task_hub:CurrentTask().rollTimer) then
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
					e:Need() 
					ml_task_hub:CurrentTask().rollTimer = Now() + 1500
				end
				ml_task_hub:CurrentTask().rollstate = "Greed"
			end
			if (ml_task_hub:CurrentTask().rollstate == "Greed") then
				if (gLootOption == "Greed" or gLootOption == "Any") then 
					e:Greed() 
					ml_task_hub:CurrentTask().rollTimer = Now() + 1500
				end
				ml_task_hub:CurrentTask().rollstate = "Pass"
			end
			if (ml_task_hub:CurrentTask().rollstate == "Pass") then
				if (gLootOption == "Pass" or gLootOption == "Any") then 
					e:Pass() 
				end
				ml_task_hub:CurrentTask().rollstate = "Complete"
			end
			i,e = next (loot,i)
		end  
	end
end

c_loot = inheritsFrom( ml_cause )
e_loot = inheritsFrom( ml_effect )
c_loot.chest = {}
c_loot.lastCheck = 0
function c_loot:evaluate()
	if (Now() < c_loot.lastCheck) then
		return false
	end
	c_loot.lastCheck = Now() + 500

	if (IsDutyLeader() and ml_task_hub:CurrentTask().hasChest) then
		if (Inventory:HasLoot() == false) then
			local chests = nil
			if (not ml_task_hub:CurrentTask().encounterData.lootid) then
				chests = EntityList("nearest,type=4,chartype=0,maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
			else
				chests = EntityList("type=4,chartype=0,maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
			end
			
			if ( ValidTable(chests) ) then
				for i, chest in pairs(chests) do
					if (not ml_task_hub:CurrentTask().encounterData.lootid) then
						if (chest.targetable) then
							Player:SetTarget(chest.id)
							c_loot.chest = chest
							return true
						end
					else 
						if (chest.uniqueid == tonumber(ml_task_hub:CurrentTask().encounterData.lootid)) then
							if (chest.targetable) then
								Player:SetTarget(chest.id)
								c_loot.chest = chest
								return true
							end
						end
					end
				end
			end
		end
	end
	
	ml_task_hub:CurrentTask().hasChest = false
    return false
end
function e_loot:execute()
	ml_task_hub:CurrentTask().isComplete = false
	local pos = c_loot.chest.pos
	SetFacing(pos.x,pos.y,pos.z)
	Player:Interact(c_loot.chest.id)
end

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
	newinst.encounterData = {}
   
    newinst.name = "LT_LOOT"
	newinst.rollTimer = 0
	newinst.rollstate = "Need"
	newinst.hasChest = true
	newinst.failTimer = 0
	newinst.maxTime = Now() + 10000
	newinst.isComplete = false
	
	if (newinst.encounterData.maxTime and newinst.encounterData.maxTime > 0) then
		newinst.maxTime = Now() + newinst.encounterData.maxTime
	end
    
    return newinst
end

function ffxiv_task_loot:Init() 	
	local ke_lootroll = ml_element:create( "Roll", c_roll, e_roll, 10 )
    self:add(ke_lootroll, self.process_elements)
	
    local ke_loot = ml_element:create( "Loot", c_loot, e_loot, 5 )
    self:add(ke_loot, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_loot:task_complete_eval()
	if (not IsDutyLeader() and not Inventory:HasLoot()) then
		return true
	end
	
	if (not ml_task_hub:CurrentTask().hasChest and not Inventory:HasLoot()) then
		self.isComplete = true
		if (self.encounterData.failTime and self.encounterData.failTime > 0) then
			self.failTimer = Now() + self.encounterData.failTime
		else
			self.failTimer = Now() + 500
		end
	end
	
	-- If the task had started counting down, but is no longer failing, reset the state.
	if (not self.isComplete and self.failTimer ~= 0) then
		self.failTimer = 0
	end
	
	-- If the failTimer is not 0 (starting value) and we've exceeded the time, end the task.
	if (self.failTimer > 0 and Now() > self.failTimer) then
		return true
	end
	
	if (Now() > ml_task_hub:CurrentTask().maxTime) then
		return true
	end

	return false
end

function ffxiv_task_loot:task_complete_execute()
    self.completed = true
	self:ParentTask().encounterCompleted = true
end
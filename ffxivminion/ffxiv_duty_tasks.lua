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
	newinst.syncTimer = 0
	newinst.encounterData = {}
	newinst.suppressFollow = false
	newinst.suppressFollowTimer = 0
	newinst.suppressAssist = false
	newinst.sceneTimer = 0
	newinst.hasScene = false
	newinst.syncRequired = true
    newinst.syncTimer = Now() + 1000
	
    return newinst
end

function ffxiv_duty_kill_task:Process()
	if ( not IsDutyLeader() ) then
		return
	end
	
	if (ml_task_hub:ThisTask().syncRequired and Now() > ml_task_hub:ThisTask().syncTimer) then
		Player:SetFacingSynced(Player.pos.x, Player.pos.y, Player.pos.z)
		Player:SetFacingSynced(Player.pos.x, Player.pos.y, Player.pos.z)
		ml_task_hub:ThisTask().syncRequired = false
	end
	
	if (ml_task_hub:CurrentTask().sceneTimer == 0 and ml_task_hub:CurrentTask().encounterData.doWait) then
		ml_task_hub:CurrentTask().sceneTimer = ml_global_information.Now + tonumber(ml_task_hub:CurrentTask().encounterData.waitTime)
		return
	elseif (ml_global_information.Now < ml_task_hub:CurrentTask().sceneTimer and not Player.incombat) then
		return
	end
	
	local killPercent = nil
	if ( ml_task_hub:CurrentTask().encounterData["killto%"]) then
		killPercent = tonumber(ml_task_hub:CurrentTask().encounterData["killto%"])
	end
	local entity = GetDutyTarget(killPercent)
	
	local myPos = Player.pos
	local fightPos = nil
	if (ml_task_hub:CurrentTask().encounterData.fightPos) then
		fightPos = ml_task_hub:CurrentTask().encounterData.fightPos["General"]
	end
	local startPos = nil
	if (ml_task_hub:CurrentTask().encounterData.startPos) then
		startPos = ml_task_hub:CurrentTask().encounterData.startPos["General"]
	end
	
	if (ValidTable(entity)) then		
		if (fightPos) then
			if (ml_task_hub:CurrentTask().timer == 0) then
				Player:SetTarget(entity.id)
				Player:SetFacingSynced(entity.pos.x, entity.pos.y, entity.pos.z)
				SkillMgr.Cast( entity )
				ml_task_hub:CurrentTask().timer = ml_global_information.Now + math.random(2000,3000)
			elseif (ml_global_information.Now > ml_task_hub:CurrentTask().timer or Player.incombat) then
				GameHacks:TeleportToXYZ(fightPos.x, fightPos.y, fightPos.z)
				Player:SetTarget(entity.id)
				Player:SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
				local newTask = ffxiv_task_skillmgrAttack.Create()
				newTask.targetid = entity.id
				ml_task_hub:CurrentTask():AddSubTask(newTask)
			end
		elseif (ml_task_hub:CurrentTask().encounterData.doKill ~= nil and 
				ml_task_hub:CurrentTask().encounterData.doKill == false ) then
					Player:SetTarget(entity.id)
					Player:SetFacingSynced(entity.pos.x, entity.pos.y, entity.pos.z)
					SkillMgr.Cast( entity )
			--return false
		elseif (ml_task_hub:CurrentTask().encounterData.doKill == nil or 
				ml_task_hub:CurrentTask().encounterData.doKill == true) then
					if (entity ~= nil and entity.alive and InCombatRange(entity.id)) then
						Player:SetTarget(entity.id)
						local pos = entity.pos
						
						if (ml_global_information.AttackRange < 5 and
							gBotMode == strings[gCurrentLanguage].dutyMode and entity.castinginfo.channelingid == 0 and
							gTeleport == "1" and (not IsDutyLeader() or ffxiv_task_duty.independentMode) and SkillMgr.teleCastTimer == 0 and SkillMgr.IsGCDReady()
							and entity.targetid ~= Player.id) then
							
							ml_task_hub:CurrentTask().suppressFollow = true
							ml_task_hub:CurrentTask().suppressFollowTimer = Now() + 2500
							
							SkillMgr.teleBack = startPos
							GameHacks:TeleportToXYZ(pos.x + 1,pos.y, pos.z)
							Player:SetFacingSynced(pos.x,pos.y,pos.z)
							Player:SetTarget(entity.id)
							SkillMgr.teleCastTimer = Now() + 1600
						end
						
						Player:SetFacingSynced(entity.pos.x, entity.pos.y, entity.pos.z)
						SkillMgr.Cast( entity )
						
						if (TableSize(SkillMgr.teleBack) > 0 and 
							gBotMode == strings[gCurrentLanguage].dutyMode and 
							(Now() > SkillMgr.teleCastTimer or entity.castinginfo.channelingid ~= 0)) then
							local back = SkillMgr.teleBack
							--Player:Stop()
							GameHacks:TeleportToXYZ(back.x, back.y, back.z)
							Player:SetFacingSynced(back.x, back.y, back.z)
							SkillMgr.teleBack = {}
							SkillMgr.teleCastTimer = 0
						end
					end
		end
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
	if (ml_global_information.Now < ml_task_hub:CurrentTask().timer) then
		return false
	end
	
	if (ml_task_hub:CurrentTask().encounterData.doKill ~= nil and ml_task_hub:CurrentTask().encounterData.doKill == false) then
		if (Player.incombat) then
			return true
		end
	end
	
	local killPercent = nil
	if ( ml_task_hub:CurrentTask().encounterData["killto%"]) then
		killPercent = tonumber(ml_task_hub:CurrentTask().encounterData["killto%"])
	end
	local entity = GetDutyTarget(killPercent)
	if (not entity) then
		return true
	end
	
    return false
end
function ffxiv_duty_kill_task:task_complete_execute()
    ml_task_hub:CurrentTask().completed = true
	ml_task_hub:CurrentTask():ParentTask().encounterCompleted = true
end

function ffxiv_duty_kill_task:Init()
    --init Process() cnes	
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
			if interactable.uniqueid == ml_task_hub:CurrentTask().encounterData.interactid then
				tpos = interactable.pos
				ppos = Player.pos
				local dist = Distance3D(ppos.x,ppos.y,ppos.z,tpos.x,tpos.y,tpos.z)
				d("Distance to target = "..tostring(dist))
				if (dist <= 3) then
					return true
				end
			end
		end
		
		if (not ml_task_hub:CurrentTask().repositioned) then
			GameHacks:TeleportToXYZ(tpos.x,tpos.y,tpos.z)
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
function c_interact:evaluate()
	if (not ml_task_hub:CurrentTask().attarget) then
		return false
	end
	
	local interacts = EntityList("type=7,chartype=0,maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
	for i, interactable in pairs(interacts) do
		if interactable.uniqueid == ml_task_hub:CurrentTask().encounterData.interactid then
			if (interactable.targetable) then
				Player:SetTarget(interactable.id)
				c_interact.object = interactable
				return true
			end
		end
	end
	
	--for k,v in pairs(EntityList("type=4,chartype=0,maxdistance=5")) do d(v.targetable) end
    return false
end
----------------------------------------------------------------------------------------------------------------------------------------
function e_interact:execute()
	local pos = c_interact.object.pos
	Player:SetFacingSynced(pos.x,pos.y,pos.z)
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
    newinst.name = "LT_INTERACT"
	newinst.repositioned = false
	newinst.attarget = false
	newinst.targetid = 0
	newinst.throttle = 0
	newinst.startTimer = Now()
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
	if TimeSince(ml_task_hub:CurrentTask().startTimer) > (ml_task_hub:CurrentTask().encounterData.maxWait * 1000) then
		return true
	end
	
	local interacts = EntityList("type=7,chartype=0,maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
	local completed = true
	for i, interactable in pairs(interacts) do
		if interactable.uniqueid == ml_task_hub:CurrentTask().encounterData.interactid then
			if (interactable.targetable) then
				completed = false
			end
		end
		if (not completed) then
			break
		end
	end
	
	return completed
end

function ffxiv_task_interact:task_complete_execute()
	self.completed = true
	ml_task_hub:CurrentTask():ParentTask().encounterCompleted = true
end

--===================================================
--Loot Task
--===================================================

c_roll = inheritsFrom( ml_cause )
e_roll = inheritsFrom( ml_effect )
function c_roll:evaluate()
	if (Inventory:HasLoot() == false) then
		if (ml_task_hub:CurrentTask().rollstate ~= "Need" and ml_task_hub:CurrentTask().rollstate ~= "Complete") then
			ml_task_hub:CurrentTask().rollstate = "Complete"
		end
		return false	
	end
	
	local loot = Inventory:GetLootList()
	if (loot and ml_task_hub:CurrentTask().rollstate ~= "Complete" and Now() > ml_task_hub:CurrentTask().rollTimer) then
		return true
	end
    
    return false
end
function e_roll:execute()
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
function c_loot:evaluate()
	if (IsDutyLeader()) then
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
						if (chest.uniqueid == ml_task_hub:CurrentTask().encounterData.lootid) then
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
    return false
end
function e_loot:execute()
	local pos = c_loot.chest.pos
	Player:SetFacingSynced(pos.x,pos.y,pos.z)
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
	newinst.failTimer = Now() + 15000
    
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
	if (ml_task_hub:CurrentTask().rollstate == "Complete" and
		Inventory:HasLoot() == false) then
		return true
	end
	
	if (not IsDutyLeader() and not Inventory:HasLoot()) then
		return true
	end
	
	if (Now() > ml_task_hub:CurrentTask().failTimer) then
		return true
	end

	return false
end

function ffxiv_task_loot:task_complete_execute()
    self.completed = true
	ml_task_hub:CurrentTask():ParentTask().encounterCompleted = true
end
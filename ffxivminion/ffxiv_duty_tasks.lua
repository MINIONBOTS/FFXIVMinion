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
	newinst.suppressAssist = false
	newinst.sceneTimer = 0
	newinst.hasScene = false
    
    return newinst
end

function ffxiv_duty_kill_task:Process()
	if( not IsDutyLeader() ) then
		return
	end
	
	if (ml_task_hub:CurrentTask().sceneTimer == 0 and ml_task_hub:CurrentTask().encounterData.doWait) then
		ml_task_hub:CurrentTask().sceneTimer = ml_global_information.Now + tonumber(ml_task_hub:CurrentTask().encounterData.waitTime)
		return
	elseif (ml_global_information.Now < ml_task_hub:CurrentTask().sceneTimer and not Player.incombat) then
		return
	end

	local target = EntityList("nearest,alive,contentid="..ml_task_hub:CurrentTask().encounterData.bossIDs..",maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
	local id, entity = nil
	if (ValidTable(target)) then
		id, entity = next(target)
	end
	
	local oldTarget = EntityList("nearest,alive,contentid="..ml_task_hub:CurrentTask().encounterData.bossIDs..",targetingme")
	local oldEntity = nil
	if (ValidTable(oldTarget)) then
		id, oldEntity = next(oldTarget)
	end
	
	local myPos = Player.pos
	local fightPos = nil
	if (ml_task_hub:CurrentTask().encounterData.fightPos) then
		fightPos = ml_task_hub:CurrentTask().encounterData.fightPos["General"]
	end
	
	if (ValidTable(entity)) then
		if (fightPos) then
			if (ml_task_hub:CurrentTask().timer == 0) then
				Player:SetFacingSynced(entity.pos.x, entity.pos.y, entity.pos.z)
				Player:SetTarget(entity.id)
				SkillMgr.Cast( entity )
				ml_task_hub:CurrentTask().timer = ml_global_information.Now + math.random(2000,3000)
			elseif (ml_global_information.Now > ml_task_hub:CurrentTask().timer or Player.incombat) then
				GameHacks:TeleportToXYZ(fightPos.x, fightPos.y, fightPos.z)
				Player:SetFacingSynced(entity.pos.x, entity.pos.y, entity.pos.z)
				Player:SetTarget(entity.id)
				local newTask = ffxiv_task_skillmgrAttack.Create()
				newTask.targetid = entity.id
				ml_task_hub:CurrentTask():AddSubTask(newTask)
				return false
			end
		elseif (
			ml_task_hub:CurrentTask().encounterData.doKill ~= nil and 
			ml_task_hub:CurrentTask().encounterData.doKill == false) 
		then
			Player:SetFacingSynced(entity.pos.x, entity.pos.y, entity.pos.z)
			Player:SetTarget(entity.id)
			SkillMgr.Cast( entity )
			--return false
		elseif (
			ml_task_hub:CurrentTask().encounterData.doKill == nil or
			ml_task_hub:CurrentTask().encounterData.doKill == true)
		then
			Player:SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
			Player:SetTarget(entity.id)
			local newTask = ffxiv_task_skillmgrAttack.Create()
			newTask.targetid = entity.id
			ml_task_hub:CurrentTask():AddSubTask(newTask)
			return false
		end
	end
	
	if (TableSize(ml_task_hub:CurrentTask().process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(ml_task_hub:CurrentTask().process_elements)
		if (ml_task_hub:CurrentTask():superClass() and TableSize(ml_task_hub:CurrentTask():superClass().process_elements) > 0) then
			ml_cne_hub.eval_elements(ml_task_hub:CurrentTask():superClass().process_elements)
		end
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

	local target = EntityList("nearest,alive,contentid="..ml_task_hub:CurrentTask().encounterData.bossIDs..",maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
	if (ml_task_hub:CurrentTask().encounterData.doKill ~= nil and ml_task_hub:CurrentTask().encounterData.doKill == false) then
		if (Player.incombat) then
			return true
		end
	end
	
	if (ValidTable(target)) then
		local id, entity = next(target)
		if (ValidTable(entity)) then
			return not entity.attackable
		end
	end
    
    return true
end

function ffxiv_duty_kill_task:task_complete_execute()
    ml_task_hub:CurrentTask().completed = true
	ml_task_hub:CurrentTask():ParentTask().encounterCompleted = true
end

function ffxiv_duty_kill_task:Init()
    --init Process() cnes
    self:AddTaskCheckCEs()
end
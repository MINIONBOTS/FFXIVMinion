ffxiv_quest_task = inheritsFrom(ml_task)
ffxiv_quest_task.name = "LT_QUEST"

function ffxiv_quest_task.Create()
    local newinst = inheritsFrom(ffxiv_quest_task)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "LT_QUEST"
    
    newinst.currentStep = {}
	newinst.currentStepCompleted = true
    newinst.currentStepIndex = 0
	newinst.profileData = {}
	newinst.quest = nil
	newinst.started = false
    
    return newinst
end

c_nextqueststep = inheritsFrom( ml_cause )
e_nextqueststep = inheritsFrom( ml_effect )
function c_nextqueststep:evaluate()
	local self = ml_task_hub:CurrentTask()
	
	if (not ml_task_hub:CurrentTask().quest:isStarted() or
		ml_task_hub:CurrentTask().quest:isComplete())
	then
		return false
	end
	
	local stepindex = Quest:GetQuestCurrentStep(ml_task_hub:CurrentTask().quest.id)
    if (stepindex ~= ml_task_hub:CurrentTask().currentStepIndex) then
		e_nextqueststep.stepindex = stepindex
		return true
	end
	
	return false
end
function e_nextqueststep:execute()
	ml_task_hub:CurrentTask().currentStepIndex = e_nextqueststep.stepindex
	local task = ml_task_hub:CurrentTask().quest:GetStepTask(ml_task_hub:CurrentTask().currentStepIndex)
	if (ValidTable(task)) then
		ml_task_hub:CurrentTask():AddSubTask(task)
	end
end

function ffxiv_quest_task:Init()
    --init ProcessOverWatch cnes
    local ke_nextQuestStep = ml_element:create( "NextQuestStep", c_nextqueststep, e_nextqueststep, 25 )
    self:add( ke_nextQuestStep, self.process_elements)
end

ffxiv_quest_interact = inheritsFrom(ml_task)
ffxiv_quest_interact.name = "LT_INTERACT"

function ffxiv_quest_interact.Create()
    local newinst = inheritsFrom(ffxiv_quest_interact)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "LT_INTERACT"
    
    newinst.params = {}
    
    return newinst
end

c_questmovetomap = inheritsFrom( ml_cause )
e_questmovetomap = inheritsFrom( ml_effect )
function c_questmovetomap:evaluate()
	local mapID = ml_task_hub:ThisTask().params["mapid"]
    if (mapID and mapID > 0) then
        if(Player.localmapid ~= mapID) then
			e_questmovetomap.mapid = mapID
			return true
        end
    end
	
	return false
end
function e_questmovetomap:execute()
	local task = ffxiv_task_movetomap.Create()
	task.destMapID = e_questmovetomap.mapID
	ml_task_hub:CurrentTask():AddSubTask(task)
end

c_questmovetopos = inheritsFrom( ml_cause )
e_questmovetopos = inheritsFrom( ml_effect )
function c_questmovetopos:evaluate()
	local mapID = ml_task_hub:ThisTask().params["mapid"]
    if (mapID and mapID > 0) then
        if(Player.localmapid == mapID) then
			local pos = ml_task_hub:ThisTask().params["pos"]
			return Distance2D(Player.pos.x, Player.pos.z, pos.x, pos.z) > 2
        end
    end
	
	return false
end
function e_questmovetopos:execute()
	local pos = ml_task_hub:ThisTask().params["pos"]
	local task = ffxiv_task_movetopos.Create()
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = pos
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_questinteract = inheritsFrom( ml_cause )
e_questinteract = inheritsFrom( ml_effect )
function c_questinteract:evaluate()
	local id = ml_task_hub:ThisTask().params["id"]
    if (id and id > 0) then
		local el = EntityList("contentid="..tostring(id))
		if(ValidTable(el)) then
			local id, entity = next(el)
			if(entity) then
				if 	(entity.type == 5 and entity.distance2d < 6) or
					(entity.distance < 3) 
				then
					e_questinteract.entity = entity
					return true
				end
			end
        end
    end
	
	return false
end
function e_questinteract:execute()
	local entity = e_questinteract.entity
	if (entity) then
		Player:Interact(entity.id)
	end
end

function ffxiv_quest_interact:Init()
    --init ProcessOverWatch cnes
    local ke_questMoveToMap = ml_element:create( "QuestMoveToMap", c_questmovetomap, e_questmovetomap, 25 )
    self:add( ke_questMoveToMap, self.process_elements)
	
	local ke_questMoveToPos = ml_element:create( "QuestMoveToPos", c_questmovetopos, e_questmovetopos, 20 )
    self:add( ke_questMoveToPos, self.process_elements)
	
	local ke_questInteract = ml_element:create( "QuestInteract", c_questinteract, e_questinteract, 15 )
    self:add( ke_questInteract, self.process_elements)
end

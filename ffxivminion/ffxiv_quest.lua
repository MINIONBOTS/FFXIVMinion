ffxiv_quest = inheritsFrom(nil)

function ffxiv_quest.Create()
	local quest = inheritsFrom(ffxiv_quest)
	
	quest.id = 0
	quest.level = 0
	quest.prereqs = {}
	quest.steps = {}
	
	return quest
end

function ffxiv_quest:CreateTask()
	local task = ffxiv_quest_task.Create()
	task.profileData = steps
	task.quest = self
	
	return task
end

function ffxiv_quest:canStart()
	for _, questid in pairs(prereqs) do
		if (not Quest:IsQuestCompleted(questid)) then
			return false
		end
	end
	
	return Player.level >= self.level
end

function ffxiv_quest:isStarted()
	return Quest:HasQuest(self.id)
end

function ffxiv_quest:isComplete()
	return Quest:IsQuestCompleted(self.id)
end

function ffxiv_quest:GetStartTask()
	local task = ffxiv_quest_start.Create()
	task.params = quest.steps[1]
	--task.quest = self
	
	return task
end

function ffxiv_quest:GetCompleteTask()
	local task = ffxiv_quest_complete.Create()
	task.params = quest.steps[TableSize(quest.steps)]
	--task.quest = self
	
	return task
end

function ffxiv_quest:GetStepTask(stepIndex)
	local params = quest.steps[stepIndex+1]
	local task = ffxiv_quest.tasks[params.type]
	task.params = params
	
	return task
end

function ffxiv_quest:GetNearestEntity()
	-- to be filled out later
	-- will be used to check if an objective entity for this quest is closer so we can switch to it
end

ffxiv_quest.tasks = 
{
	["start"] 		= ffxiv_quest_start,
	["complete"] 	= ffxiv_quest_complete,
	["interact"] 	= ffxiv_quest_interact,
	["killmobs"]	= ffxiv_quest_kill,
}
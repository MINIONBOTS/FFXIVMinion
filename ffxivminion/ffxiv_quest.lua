ffxiv_quest = inheritsFrom(nil)

function ffxiv_quest.Create()
	local quest = inheritsFrom(ffxiv_quest)
	
	quest.id = 0
	quest.level = 0
	quest.prereq = {}
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
	if (self:isComplete()) then
		return false
	end
	
	if(ValidTable(self.prereq)) then
		for jobid, questids in pairsByKeys(self.prereq) do
			if (jobid == Player.job or
				jobid == -1) 
			then
				for _, questid in pairs(questids) do
					if (not Settings.FFXIVMINION.completedQuestIDs[questid]) then
						return false
					end
				end
			end
		end
	end
	
	return Player.level >= self.level
end

function ffxiv_quest:isStarted()
	return Quest:HasQuest(self.id)
end

function ffxiv_quest:isComplete()
	return Settings.FFXIVMINION.completedQuestIDs[self.id] ~= nil
end

function ffxiv_quest:GetStartTask()
	local task = ffxiv_quest_start.Create()
	task.params = self.steps[1]
	
	return task
end

function ffxiv_quest:GetCompleteTask()
	local task = ffxiv_quest_complete.Create()
	task.params = self.steps[TableSize(self.steps)]
	
	return task
end

function ffxiv_quest:GetStepTask(stepIndex)
	local params = self.steps[stepIndex]
	local task = ffxiv_quest.tasks[params.type]()
	task.params = params
	
	return task
end

function ffxiv_quest:GetNearestEntity()
	-- to be filled out later
	-- will be used to check if an objective entity for this quest is closer so we can switch to it
end

ffxiv_quest.tasks = 
{
	["start"] 		= ffxiv_quest_start.Create,
	["complete"] 	= ffxiv_quest_complete.Create,
	["interact"] 	= ffxiv_quest_interact.Create,
	["kill"]		= ffxiv_quest_kill.Create,
	["nav"]			= ffxiv_quest_nav.Create,
	["grind"]		= ffxiv_quest_grind.Create,
	["accept"]		= ffxiv_quest_accept.Create,
}
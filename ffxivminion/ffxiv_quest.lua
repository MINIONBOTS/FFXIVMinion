ffxiv_quest = inheritsFrom(nil)

function ffxiv_quest.Create()
	local quest = inheritsFrom(ffxiv_quest)
	
	quest.id = 0
	quest.job = 0
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
	if (self:hasBeenCompleted()) then
		return false
	end
	
	if(self.job ~= -1 and Player.job ~= self.job) then
		return false
	end
	
	if(ValidTable(self.prereq)) then
		for jobid, questids in pairsByKeys(self.prereq) do
			if (jobid == Player.job or
				jobid == -1) 
			then
				for _, questid in pairs(questids) do
					if (not Quest:IsQuestCompleted(questid)) then
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

--checks to see if all quest objectives have been met
function ffxiv_quest:isComplete()
	--local currStep = tonumber(gCurrQuestStep) or 1
	
	--if (Quest:GetQuestCurrentStep(self.id) == 255 and
	--	TableSize(self.steps) <= currStep) then
	--	return true
	--else
	--	return false
	--end
	
	--Changed this to prevent it from skipping ahead to the complete task, leaving important objectives unfulfilled.
	--Leaving the original data here.
	return Quest:GetQuestCurrentStep(self.id) == 255
end

--checks to see if quest has been previously completed
function ffxiv_quest:hasBeenCompleted()
	return Quest:IsQuestCompleted(self.id)
end

function ffxiv_quest:currentObjectiveIndex()
	return Quest:GetQuestCurrentStep(self.id)
end

function ffxiv_quest:currentStepIndex()
	return GetStepIndexForObjective(self:currentObjectiveIndex())
end

function ffxiv_quest:GetStepIndexForObjective(objectiveIndex)
	if(objectiveIndex <= 0 or objectiveIndex >= TableSize(self.steps)) then
		ml_error("Quest:GetStepIndexForObjectove - Invalid objective index")
	end

	local stepIndex = 1
	for index,step in pairsByKeys(self.steps) do
		if(index ~= 1 and index ~= TableSize(self.steps) and not step["nonquestobjective"]) then
			if (stepIndex == objectiveIndex) then
				stepIndex = index
				break
			else
				stepIndex = stepIndex + 1
			end
		end
	end
	
	return stepIndex
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

--returns a task for the given step index
function ffxiv_quest:GetStepTask(stepIndex)
	local task = nil
	local params = self.steps[stepIndex]
	
	if (params) then
		task = ffxiv_quest.tasks[params.type]()
		task.params = params
	end
	
	return task
end

--finds the task for the step matching the objective index and returns it
function ffxiv_quest:GetObjectiveTask(objectiveIndex)
	return self:GetStepTask(self:GetStepIndexForObjective(objectiveIndex))
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
	["accept"]		= ffxiv_quest_accept.Create,
	["dutykill"]	= ffxiv_quest_dutykill.Create,
	["textcommand"] = ffxiv_quest_textcommand.Create,
	["useitem"] 	= ffxiv_quest_useitem.Create,
	["useaction"]	= ffxiv_quest_useaction.Create,
	["vendor"]		= ffxiv_quest_vendor.Create,
	["equip"]		= ffxiv_quest_equip.Create,
	["killaggro"]		= ffxiv_quest_killaggro.Create,
}
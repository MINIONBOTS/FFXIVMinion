ffxiv_task_quest = inheritsFrom(ml_task)
ffxiv_task_quest.name = "LT_QUEST_ENGINE"
ffxiv_task_quest.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\QuestProfiles\]]
ffxiv_task_quest.questList = {}
ffxiv_task_quest.currentQuest = {}
ffxiv_task_quest.currentStepParams = {}

function ffxiv_task_quest.Create()
    local newinst = inheritsFrom(ffxiv_task_quest)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "LT_QUEST_ENGINE"
    
	newinst.profileCompleted = false
    newinst.profilePath = ""
    
    return newinst
end

function ffxiv_task_quest.UIInit()
	GUI_NewButton(ffxivminion.Windows.Main.Name,"SetQuest","ffxiv_task_quest.SetQuest",strings[gCurrentLanguage].questMode)
	RegisterEventHandler("ffxiv_task_quest.SetQuest",ffxiv_task_quest.SetQuest)

	GUI_NewField(ffxivminion.Windows.Main.Name, "QuestID:", "gCurrQuestID",strings[gCurrentLanguage].botStatus)
	GUI_NewField(ffxivminion.Windows.Main.Name, "StepIndex:", "gCurrQuestStep",strings[gCurrentLanguage].botStatus)
	GUI_NewCheckbox(ffxivminion.Windows.Main.Name,"TestQuest","gTestQuest",strings[gCurrentLanguage].botStatus );
	--GUI_UnFoldGroup(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].questMode)
	
	if (Settings.FFXIVMINION.gLastQuestProfile == nil) then
        Settings.FFXIVMINION.gLastQuestProfile = ""
    end
	
	if (Settings.FFXIVMINION.gCurrQuestID == nil) then
        Settings.FFXIVMINION.gCurrQuestID = ""
    end
	
	if (Settings.FFXIVMINION.gCurrQuestStep == nil) then
        Settings.FFXIVMINION.gCurrQuestStep = ""
    end
	
	if (Settings.FFXIVMINION.completedQuestIDs == nil) then
		Settings.FFXIVMINION.completedQuestIDs = {}
	end
	
	if (Settings.FFXIVMINION.currentQuestStep == nil) then
		Settings.FFXIVMINION.currentQuestStep = 0
	end
	
	if (Settings.FFXIVMINION.gTestQuest == nil) then
        Settings.FFXIVMINION.gTestQuest = "0"
    end
	
	if(gBotMode == GetString("questMode")) then
		ffxiv_task_quest.UpdateProfiles()
	end
    
    GUI_SizeWindow(ffxivminion.Windows.Main.Name,178,357)
	
	gCurrQuestID = Settings.FFXIVMINION.gCurrQuestID
	gCurrQuestStep = Settings.FFXIVMINION.gCurrQuestStep
	gTestQuest = Settings.FFXIVMINION.gTestQuest
end

function ffxiv_task_quest.SetQuest()
	local questid = Quest:GetSelectedJournalQuest()
	if (questid and questid > 0) then
		gCurrQuestID = questid
	end
end

function ffxiv_task_quest.UpdateProfiles()
    local profiles = "None"
    local found = "None"	
    local profilelist = dirlist(ffxiv_task_quest.profilePath,".*info")
    if ( TableSize(profilelist) > 0) then			
        local i,profile = next ( profilelist)
        while i and profile do				
            profile = string.gsub(profile, ".info", "")
            profiles = profiles..","..profile
            if ( Settings.FFXIVMINION.gLastQuestProfile ~= nil and Settings.FFXIVMINION.gLastQuestProfile == profile ) then
                d("Last Profile found : "..profile)
                found = profile
            end
            i,profile = next ( profilelist,i)
        end		
    else
        d("No quest profiles found")
    end
    gProfile_listitems = profiles
    gProfile = found
	if (gProfile ~= "" and gProfile ~= "None") then
		ffxiv_task_quest.LoadProfile(ffxiv_task_quest.profilePath..gProfile..".info")
	end
end

function ffxiv_task_quest.LoadProfile(profilePath)
	d("Loading quest profile from "..profilePath)
	local profileData = {}
	local e = nil
    if (profilePath ~= "" and file_exists(profilePath)) then
        profileData, e = persistence.load(profilePath)
        local luaPath = profilePath:sub(1,profilePath:find(".info")).."lua"
        if (file_exists(luaPath)) then
            dofile(luaPath)
        end
    end
	
	if (ValidTable(profileData)) then
		--create quest objects for each quest in the profile
		local quests = profileData.quests
		if (ValidTable(quests)) then
			for id, questTable in pairs(quests) do
				local quest = ffxiv_quest.Create()
				quest.id = id
				quest.level = questTable.level
				quest.prereq = questTable.prereq
				quest.steps = questTable.steps
				
				if(questTable.job ~= nil) then
					quest.job = questTable.job
				else
					quest.job = -1
				end
				
				ffxiv_task_quest.questList[id] = quest
			end
		end
	else
		ml_error("Error reading quest profile")
		ml_error(e)
	end
end

c_testquest = inheritsFrom( ml_cause )
e_testquest = inheritsFrom( ml_effect )
function c_testquest:evaluate()
	if(gCurrQuestID ~= "" and tonumber(gCurrQuestID) > 0 and gTestQuest == "1") then
		return ValidTable(ffxiv_task_quest.questList[tonumber(gCurrQuestID)])
	end
end
function e_testquest:execute()
	local quest = ffxiv_task_quest.questList[tonumber(gCurrQuestID)]
	if (ValidTable(quest)) then
		local task = quest:CreateTask()
		if(gCurrQuestStep and gCurrQuestStep ~= "") then
			task.currentStepIndex = (tonumber(gCurrQuestStep)-1)
		else
			task.currentStepIndex = 1
		end
		
		ml_task_hub:CurrentTask():AddSubTask(task)
		
		ffxiv_task_quest.currentQuest = quest
	end
end

c_nextquest = inheritsFrom( ml_cause )
e_nextquest = inheritsFrom( ml_effect )
function c_nextquest:evaluate()
	if(	Settings.FFXIVMINION.currentQuestID ~= nil and 
		Quest:HasQuest(Settings.FFXIVMINION.currentQuestID) and
		ValidTable(ffxiv_task_quest.questList[Settings.FFXIVMINION.currentQuestID]))
	then
		e_nextquest.quest = ffxiv_task_quest.questList[Settings.FFXIVMINION.currentQuestID]
		return true
	end

	for id, quest in pairs(ffxiv_task_quest.questList) do
		if (quest:canStart()) then
			e_nextquest.quest = quest
			return true
		end
	end
	
	return false
end
function e_nextquest:execute()
	local quest = e_nextquest.quest
	if (ValidTable(quest)) then
		local task = quest:CreateTask()
		ml_task_hub:CurrentTask():AddSubTask(task)
		
		ffxiv_task_quest.currentQuest = quest
		gCurrQuestID = quest.id
		Settings.FFXIVMINION.currentQuestID = tonumber(gCurrQuestID)
	end
end

c_questaddgrind = inheritsFrom( ml_cause )
e_questaddgrind = inheritsFrom( ml_effect )
function c_questaddgrind:evaluate()
	-- we should always go grind if we can't find a quest to do
	-- might need to tweak this later?
	return true
end
function e_questaddgrind:execute()
	local grindmap = GetBestGrindMap()
	
	local newTask = ffxiv_quest_grind.Create()
	newTask.task_complete_eval = 
		function()
			return c_nextquest:evaluate()
		end
	newTask.params["mapid"] = grindmap
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

function ffxiv_task_quest:Init()
	--process elements
    local ke_nextQuest = ml_element:create( "NextQuest", c_nextquest, e_nextquest, 20 )
    self:add( ke_nextQuest, self.process_elements)
	
	local ke_questAddGrind = ml_element:create( "QuestAddGrind", c_questaddgrind, e_questaddgrind, 15 )
    self:add( ke_questAddGrind, self.process_elements)
	
	local ke_testQuest = ml_element:create( "TestQuest", c_testquest, e_testquest, 25 )
    self:add( ke_testQuest, self.process_elements)
	
	--overwatch elements
	local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 20 )
    self:add( ke_dead, self.overwatch_elements)
    
    local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 15 )
    self:add( ke_flee, self.overwatch_elements)
    
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 14 )
    self:add( ke_rest, self.overwatch_elements)
	
	local ke_questIsLoading = ml_element:create( "QuestIsLoading", c_questisloading, e_questisloading, 105 )
    self:add( ke_questIsLoading, self.overwatch_elements)
	
	local ke_questInDialog = ml_element:create( "QuestInDialog", c_questindialog, e_questindialog, 105 )
    self:add( ke_questInDialog, self.overwatch_elements)
	
	self:AddTaskCheckCEs()
end

function ffxiv_task_quest.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
		if (	k == "gProfile" and gBotMode == GetString("questMode")) then
			ffxiv_task_quest.LoadProfile(ffxiv_task_quest.profilePath..v..".info")
			Settings.FFXIVMINION["gLastQuestProfile"] = v
        elseif (k == "gCurrQuestID" or
				k == "gCurrQuestStep" or
				k == "gTestQuest" )
        then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(ffxivminion.Windows.Main.Name)
end

RegisterEventHandler("GUI.Update",ffxiv_task_quest.GUIVarUpdate)
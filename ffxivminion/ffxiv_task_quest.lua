ffxiv_task_quest = inheritsFrom(ml_task)
ffxiv_task_quest.name = "LT_QUEST_ENGINE"
ffxiv_task_quest.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\QuestProfiles\]]
ffxiv_task_quest.questList = {}
ffxiv_task_quest.currentQuest = {}
ffxiv_task_quest.currentStepParams = {}
ffxiv_task_quest.killCount = 0
ffxiv_task_quest.backupKillCount = 0
ffxiv_task_quest.questFlags = 0
ffxiv_task_quest.killTaskCompleted = false
ffxiv_task_quest.restartStep = 0

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
--Add it to the main tracking table, so that we can save positions for it.
	ffxivminion.Windows.Quest = { id = strings["us"].questMode, Name = GetString("questMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Quest)
	
	if (Settings.FFXIVMINION.gLastQuestProfile == nil) then
        Settings.FFXIVMINION.gLastQuestProfile = ""
    end
	if (Settings.FFXIVMINION.gCurrQuestID == nil) then
        Settings.FFXIVMINION.gCurrQuestID = ""
    end
	if (Settings.FFXIVMINION.completedQuestIDs == nil) then
		Settings.FFXIVMINION.completedQuestIDs = {}
	end
	if (Settings.FFXIVMINION.currentQuestObjective == nil) then
		Settings.FFXIVMINION.currentQuestObjective = 0
	end
	if (Settings.FFXIVMINION.gCurrQuestStep == nil) then
		Settings.FFXIVMINION.gCurrQuestStep = 0
	end
	if (Settings.FFXIVMINION.gTestQuest == nil) then
        Settings.FFXIVMINION.gTestQuest = "0"
    end
	if (Settings.FFXIVMINION.gQuestAutoEquip == nil) then
		Settings.FFXIVMINION.gQuestAutoEquip = "1"
	end
	if(gBotMode == GetString("questMode")) then
		ffxiv_task_quest.UpdateProfiles()
	end
	
	local winName = GetString("questMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].botMode,"gBotMode",group,"None")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].profile,"gProfile",group,"None")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].skillProfile,"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,strings[gCurrentLanguage].navmesh ,"gmeshname",group,ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,strings[gCurrentLanguage].botEnabled,"gBotRunning",group)
	GUI_NewField(winName, GetString("questID"), "gCurrQuestID",group)
	GUI_NewField(winName, GetString("objectiveIndex"), "gCurrQuestObjective",group)
	GUI_NewField(winName, GetString("stepIndex"), "gCurrQuestStep",group)
	GUI_NewField(winName, GetString("stepTask"), "gQuestStepType",group)
	GUI_NewField(winName, GetString("killCount"), "gQuestKillCount",group)
	local group = GetString("settings")
	GUI_NewCheckbox(winName,GetString("autoEquip"),"gQuestAutoEquip",group)
	
	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gCurrQuestID = Settings.FFXIVMINION.gCurrQuestID
	gCurrQuestStep = Settings.FFXIVMINION.gCurrQuestStep
	gTestQuest = Settings.FFXIVMINION.gTestQuest
	gQuestAutoEquip = Settings.FFXIVMINION.gQuestAutoEquip
end

function ffxiv_task_quest.SetQuestFlags()
	local questTable = GetQuestByID(ffxiv_task_quest.currentQuest.id)
	if(ValidTable(questTable)) then
		ffxiv_task_quest.questFlags = questTable.I16A + questTable.I16B + questTable.I16C
	end
end

function ffxiv_task_quest.QuestFlagsChanged()
	local questTable = GetQuestByID(ffxiv_task_quest.currentQuest.id)
	if(ValidTable(questTable)) then
		local questFlags = questTable.I16A + questTable.I16B + questTable.I16C
		return questFlags ~= ffxiv_task_quest.questFlags
	end
	
	return false
end

function ffxiv_task_quest.QuestObjectiveChanged()
	if(ValidTable(ffxiv_task_quest.currentQuest)) then
		return ffxiv_task_quest.currentQuest:currentObjectiveIndex() ~= tonumber(gCurrQuestObjective)
	end
end

function ffxiv_task_quest.AddEquipItem(itemid)
	local equipTable = ml_global_information.itemIDsToEquip[gProfile]
	if(not equipTable) then
		equipTable = {}
	end
	ml_global_information.itemIDsToEquip[gProfile] = equipTable
	
	local jobTable = equipTable[Player.job]
	if(not jobTable) then
		jobTable = {}
	end
	equipTable[Player.job] = jobTable
	
	jobTable[itemid] = true
	Settings.FFXIVMINION.itemIDsToEquip = ml_global_information.itemIDsToEquip
	Settings.FFXIVMINION.itemIDsToEquip = Settings.FFXIVMINION.itemIDsToEquip
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

function ffxiv_task_quest.ResetStep()
	if(ffxiv_task_quest.restartStep and ffxiv_task_quest.restartStep ~= 0) then
		gCurrQuestStep = tostring(ffxiv_task_quest.restartStep)
		Settings.FFXIVMINION.gCurrQuestStep = gCurrQuestStep
		Settings.FFXIVMINION.questKillCount = nil
		gQuestKillCount = ""
		ffxiv_task_quest.questFlags = 0
		ffxiv_task_quest.killCount = 0
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
		ffxiv_task_quest.questList = {}
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

c_nextquest = inheritsFrom( ml_cause )
e_nextquest = inheritsFrom( ml_effect )
function c_nextquest:evaluate()
	local currQuest = tonumber(Settings.FFXIVMINION.gCurrQuestID)

	if (currQuest ~= nil and 
		Quest:HasQuest(currQuest) and
		ValidTable(ffxiv_task_quest.questList[currQuest]))
	then
		e_nextquest.quest = ffxiv_task_quest.questList[currQuest]
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
		Settings.FFXIVMINION.gCurrQuestID = tonumber(gCurrQuestID)
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
	--its tempting to add equip cnes to overwatch but there are too many states 
	--when the client does not allow gear changes
	
	--equip reward checks if we just got an item we wanted to equip for the last quest reward
	--and queues it for equip if so
	local ke_equipReward = ml_element:create( "EquipReward", c_equipreward, e_equipreward, 30 )
    self:add( ke_equipReward, self.process_elements)
	
	local ke_equip = ml_element:create( "Equip", c_equip, e_equip, 25 )
    self:add( ke_equip, self.process_elements)
	
    local ke_nextQuest = ml_element:create( "NextQuest", c_nextquest, e_nextquest, 20 )
    self:add( ke_nextQuest, self.process_elements)
	
	local ke_questAddGrind = ml_element:create( "QuestAddGrind", c_questaddgrind, e_questaddgrind, 15 )
    self:add( ke_questAddGrind, self.process_elements)
	
	--overwatch elements
	local ke_dead = ml_element:create( "Dead", c_questdead, e_questdead, 20 )
    self:add( ke_dead, self.overwatch_elements)
    
    local ke_flee = ml_element:create( "Flee", c_questflee, e_questflee, 15 )
    self:add( ke_flee, self.overwatch_elements)
	
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
				k == "gQuestAutoEquip" )
        then
            Settings.FFXIVMINION[k] = v
        end
    end
    GUI_RefreshWindow(ffxivminion.Windows.Main.Name)
end

RegisterEventHandler("GUI.Update",ffxiv_task_quest.GUIVarUpdate)

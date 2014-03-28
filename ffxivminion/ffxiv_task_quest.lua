ffxiv_task_quest = inheritsFrom(ml_task)
ffxiv_task_quest.name = "LT_QUEST_ENGINE"
ffxiv_task_quest.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\QuestProfiles\]]
ffxiv_task_quest.questList = {}

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
	GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].profile,"gQuestProfile",strings[gCurrentLanguage].questMode,"")
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].teleport,"gQuestTeleport",strings[gCurrentLanguage].questMode)

    if (Settings.FFXIVMINION.gDutyTeleport == nil) then
        Settings.FFXIVMINION.gDutyTeleport = "0"
    end
	
	if (Settings.FFXIVMINION.gLastQuestProfile == nil) then
        Settings.FFXIVMINION.gLastQuestProfile = ""
    end
	
	ffxiv_task_quest.UpdateProfiles()
    
    GUI_SizeWindow(ml_global_information.MainWindow.Name,178,357)
	
	gQuestProfile = Settings.FFXIVMINION.gLastQuestProfile
    gQuestTeleport = Settings.FFXIVMINION.gQuestTeleport
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
    gQuestProfile_listitems = profiles
    gQuestProfile = found
	ffxiv_task_quest.LoadProfile(ffxiv_task_quest.profilePath..gQuestProfile..".info")
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
				quest.prereqs = questTable.prereqs
				quest.steps = questTable.steps
				
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
	for id, quest in pairs(ml_task_hub:CurrentTask().questList) do
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
	end
end

function ffxiv_task_quest:Init()
    --init ProcessOverWatch cnes
    local ke_nextQuest = ml_element:create( "NextQuest", c_nextquest, e_nextquest, 25 )
    self:add( ke_nextQuest, self.process_elements)
end

function ffxiv_task_quest.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
		if (	k == "gQuestProfile" ) then
			ffxiv_task_quest.LoadProfile(ffxiv_task_quest.profilePath..v..".info")
			Settings.FFXIVMINION["gLastQuestProfile"] = v
        elseif (k == "gQuestTeleport")
        then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

RegisterEventHandler("GUI.Update",ffxiv_task_quest.GUIVarUpdate)
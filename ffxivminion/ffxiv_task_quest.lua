ffxiv_task_quest = inheritsFrom(ml_profile_task)
ffxiv_task_quest.name = "LT_QUEST"
ffxiv_task_quest.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\QuestProfiles\]]

function ffxiv_task_quest.Create()
    local newinst = inheritsFrom(ffxiv_task_quest)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "LT_PROFILE"
    
    --ml_profile_task members
    newinst.currentStep = {}
	newinst.currentStepCompleted = true
    newinst.currentStepIndex = 0
    newinst.profileData = {}
    newinst.profilePath = ""
    newinst.profileCompleted = false
    
    
    
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
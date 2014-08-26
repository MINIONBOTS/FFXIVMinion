ml_quest_mgr = {}
ml_quest_mgr.ModuleName = "FFXIVMINION" -- gets reset on init
ml_quest_mgr.profilepath = GetStartupPath() -- gets reset on init
ml_quest_mgr.RegisteredButtonEventList = {} -- holds the already registered events of the questmanager

-- Main Window
ml_quest_mgr.mainwindow = { name = GetString("questManager"), x = 350, y = 50, w = 250, h = 350}
ml_quest_mgr.visible = false
ml_quest_mgr.QuestList = {}


-- Quest Editor Window
ml_quest_mgr.editwindow = { name = GetString("questEditor"), x = 350, y = 50, w = 250, h = 350}
ml_quest_mgr.editwindow.currentPrio = 0


-- Step Editor Window
ml_quest_mgr.stepwindow = { name = GetString("questStepEditor"), x = 350, y = 50, w = 250, h = 350}
ml_quest_mgr.stepwindow.currentPrio = 0

-- Script Window
ml_quest_mgr.currentscript = nil

function ml_quest_mgr.ModuleInit( name , path) 	
	
	if (not name or name == "") then return end
	
	ml_quest_mgr.ModuleName = name
	ml_quest_mgr.profilepath = path
	
	-- MAIN WINDOW
	if (Settings[ml_quest_mgr.ModuleName].gQMprofile == nil) then
		Settings[ml_quest_mgr.ModuleName].gQMprofile = "None"
	end
		
	GUI_NewWindow(ml_quest_mgr.mainwindow.name,ml_quest_mgr.mainwindow.x,ml_quest_mgr.mainwindow.y,ml_quest_mgr.mainwindow.w,ml_quest_mgr.mainwindow.h)
	GUI_NewComboBox(ml_quest_mgr.mainwindow.name,GetString("profile"),"gQMprofile",GetString("generalSettings"),"None")
	GUI_NewField(ml_quest_mgr.mainwindow.name,GetString("newProfileName"),"gQMnewname",GetString("generalSettings"))
	GUI_NewButton(ml_quest_mgr.mainwindow.name,GetString("newProfile"),"QMCreateNewProfile",GetString("generalSettings"))
	RegisterEventHandler("QMCreateNewProfile",ml_quest_mgr.CreateNewProfile)
	
	GUI_NewButton(ml_quest_mgr.mainwindow.name,GetString("saveProfile"),"QMSaveProfile")	
	RegisterEventHandler("QMSaveProfile",ml_quest_mgr.MainButtonHandler)	
	GUI_NewButton(ml_quest_mgr.mainwindow.name,GetString("questAddQuest"),"QMAddQuest")	
	RegisterEventHandler("QMAddQuest",ml_quest_mgr.MainButtonHandler)	


				
	gQMprofile = Settings[ml_quest_mgr.ModuleName].gQMprofile
	gQMnewname = ""
  		
	GUI_SizeWindow(ml_quest_mgr.mainwindow.name,ml_quest_mgr.mainwindow.w,ml_quest_mgr.mainwindow.h)
	GUI_UnFoldGroup(ml_quest_mgr.mainwindow.name,GetString("generalSettings"))
	GUI_WindowVisible(ml_quest_mgr.mainwindow.name,false)
	
	
	-- EDITOR WINDOW
	GUI_NewWindow(ml_quest_mgr.editwindow.name,ml_quest_mgr.mainwindow.x+ml_quest_mgr.mainwindow.w,ml_quest_mgr.mainwindow.y,ml_quest_mgr.editwindow.w,ml_quest_mgr.editwindow.h)		
	GUI_NewField(ml_quest_mgr.editwindow.name,GetString("questName"),"QME_Name",GetString("questInfo"))
	GUI_NewCheckbox(ml_quest_mgr.editwindow.name,GetString("questDone"),"QME_Done",GetString("questInfo"))	
	GUI_NewNumeric(ml_quest_mgr.editwindow.name,GetString("questMinLevel"),"QME_MinLevel",GetString("questInfo"),"0","80")
	GUI_NewNumeric(ml_quest_mgr.editwindow.name,GetString("questMaxLevel"),"QME_MaxLevel",GetString("questInfo"),"0","80")
	GUI_NewField(ml_quest_mgr.editwindow.name,GetString("questMap"),"QME_Map",GetString("questInfo"))
	--GUI_NewCheckbox(ml_quest_mgr.editwindow.name,GetString("questPreQuest"),"QME_PrevQuest",GetString("questInfo")) 
	GUI_NewCheckbox(ml_quest_mgr.editwindow.name,GetString("questRepeat"),"QME_Repeat",GetString("questInfo"))
	
	
	GUI_UnFoldGroup(ml_quest_mgr.editwindow.name,GetString("questInfo"))
	GUI_SizeWindow(ml_quest_mgr.editwindow.name,ml_quest_mgr.editwindow.w,ml_quest_mgr.editwindow.h)
	GUI_WindowVisible(ml_quest_mgr.editwindow.name,false)
	
	GUI_NewButton(ml_quest_mgr.editwindow.name,GetString("questDelete"),"QMDeleteQuest") 
	RegisterEventHandler("QMDeleteQuest",ml_quest_mgr.EditorButtonHandler)
	GUI_NewButton(ml_quest_mgr.editwindow.name,GetString("questReset"),"QMResetQuest") 
	RegisterEventHandler("QMResetQuest",ml_quest_mgr.EditorButtonHandler)
	GUI_NewButton(ml_quest_mgr.editwindow.name,GetString("questDown"),"QMLowerPrioQuest")
	RegisterEventHandler("QMLowerPrioQuest",ml_quest_mgr.EditorButtonHandler)
	GUI_NewButton(ml_quest_mgr.editwindow.name,GetString("questUp"),"QMHigherPrioQuest")	
	RegisterEventHandler("QMHigherPrioQuest",ml_quest_mgr.EditorButtonHandler)	
	GUI_NewButton(ml_quest_mgr.editwindow.name,GetString("questAddStep"),"QMAddStep")	
	RegisterEventHandler("QMAddStep",ml_quest_mgr.StepButtonHandler)
	
	
	-- STEP EDITOR WINDOW
	GUI_NewWindow(ml_quest_mgr.stepwindow.name,ml_quest_mgr.editwindow.x+ml_quest_mgr.editwindow.w,ml_quest_mgr.editwindow.y,ml_quest_mgr.stepwindow.w,ml_quest_mgr.stepwindow.h)		
	GUI_NewField(ml_quest_mgr.stepwindow.name,GetString("questName"),"QMS_Name",GetString("questStepInfo"))
	GUI_NewCheckbox(ml_quest_mgr.stepwindow.name,GetString("questStepDone"),"QMS_Done",GetString("questStepInfo"))	
	GUI_NewComboBox(ml_quest_mgr.stepwindow.name,GetString("questStepScript"),"gQMS_Script",GetString("questStepInfo"),"None")
	
	--Custom UI fields are in the task-scripts
	GUI_UnFoldGroup(ml_quest_mgr.stepwindow.name,GetString("questStepInfo"))
	GUI_SizeWindow(ml_quest_mgr.stepwindow.name,ml_quest_mgr.stepwindow.w,ml_quest_mgr.stepwindow.h)
	GUI_WindowVisible(ml_quest_mgr.stepwindow.name,false)
	
	GUI_NewButton(ml_quest_mgr.stepwindow.name,GetString("questStepDelete"),"QMDeleteStep") 
	RegisterEventHandler("QMDeleteStep",ml_quest_mgr.StepButtonHandler)	
	GUI_NewButton(ml_quest_mgr.stepwindow.name,GetString("questDown"),"QMLowerPrioStep")
	RegisterEventHandler("QMLowerPrioStep",ml_quest_mgr.StepButtonHandler)
	GUI_NewButton(ml_quest_mgr.stepwindow.name,GetString("questUp"),"QMHigherPrioStep")	
	RegisterEventHandler("QMHigherPrioStep",ml_quest_mgr.StepButtonHandler)
	
	
	-- QUEST PROGRESS TABLE (saving/loading character specific progress in quest profiles)		
	if (Settings[ml_quest_mgr.ModuleName].gQMprogress == nil) then
		Settings[ml_quest_mgr.ModuleName].gQMprogress = {}
	end


	ml_quest_mgr.UpdateProfiles() -- Update the profiles dropdownlist 
	ml_quest_mgr.UpdateCurrentProfileData()	
	
	--stubborn ffxivGUI
	GUI_SizeWindow(ml_quest_mgr.mainwindow.name,ml_quest_mgr.mainwindow.w,ml_quest_mgr.mainwindow.h)
	GUI_SizeWindow(ml_quest_mgr.editwindow.name,ml_quest_mgr.editwindow.w,ml_quest_mgr.editwindow.h)
	GUI_SizeWindow(ml_quest_mgr.stepwindow.name,ml_quest_mgr.stepwindow.w,ml_quest_mgr.stepwindow.h)
end

function ml_quest_mgr.UpdateCurrentProfileData()
    ml_quest_mgr.QuestList = {}
	if ( gQMprofile ~= nil and gQMprofile ~= "" and gQMprofile ~= "None" ) then        
		
		-- Check if we have a character specific progress file of that profile and load that first
		local pName = Player.name	
		pName = pName:gsub('%W','') -- only alphanumeric
		if ( pName ~= nil and pName ~= "" ) then        
			ml_quest_mgr.QuestList = persistence.load( ml_quest_mgr.profilepath..gQMprofile.."_"..pName..".qmpx")
		end
		
		if ( TableSize(ml_quest_mgr.QuestList) > 0) then
            d("Quest Profile & Progress for "..gQMprofile.."_"..pName.." loaded")				           
        else
			ml_quest_mgr.QuestList = persistence.load( ml_quest_mgr.profilepath..gQMprofile..".qmp")
			
			if ( TableSize(ml_quest_mgr.QuestList) > 0) then
				d("Quest Profile "..gQMprofile.." loaded")				           
			else
				ml_error("Quest Profile is empty or was not found..")			
			end
		end
    else
        d("No new Quest Profile selected!")
		gQMprofile = "None"
    end
	ml_quest_mgr.RefreshQuestList()
    GUI_UnFoldGroup(ml_quest_mgr.mainwindow.name,GetString("quests"))	
end

--**********************
-- MAIN WINDOW Functions
--**********************
function ml_quest_mgr.MainButtonHandler(event)
	if ( event == "QMSaveProfile") then
		ml_quest_mgr.SaveProfile()
		
	elseif ( event == "QMAddQuest") then
		ml_quest_mgr.AddNewQuest( nil )
		ml_quest_mgr.editwindow.currentPrio = table.maxn(ml_quest_mgr.QuestList)
		GUI_UnFoldGroup(ml_quest_mgr.mainwindow.name,GetString("quests"))
		ml_quest_mgr.EditQuest( nil )
	end
end

function ml_quest_mgr.UpdateProfiles()
	local profiles = "None"
	local found = "None"	
	local profilelist = dirlist(ml_quest_mgr.profilepath,".*qmp")
	if ( TableSize(profilelist) > 0) then			
		local i,profile = next ( profilelist)
		while i and profile do				
			profile = string.gsub(profile, ".qmp", "")
			
			profiles = profiles..","..profile
			if ( Settings[ml_quest_mgr.ModuleName].gQMprofile ~= nil and Settings[ml_quest_mgr.ModuleName].gQMprofile == profile ) then
				d("Last Profile found : "..profile)
				found = profile		
			end				
			i,profile = next ( profilelist,i)
		end		
	else
		ml_error("No Questmanager profiles found")		
	end
	gQMprofile_listitems = profiles
	
	--[[ try to load default profiles
	if ( found == "None" ) then
		local defaultprofile = ml_quest_mgr.DefaultProfiles[tonumber(Player.localmapid)]
		if ( defaultprofile ) then
			d("Loading default Profile for our Map")	
						
			GUI_WindowVisible(ml_quest_mgr.editwindow.name,false)
			GUI_DeleteGroup(ml_quest_mgr.mainwindow.name,GetString("quests"))
			ml_quest_mgr.QuestList = {}
			ml_quest_mgr.UpdateCurrentProfileData()
			Settings[ml_quest_mgr.ModuleName].gQMprofile = tostring(defaultprofile)
			gQMprofile = defaultprofile
			return
		end
	end]]	
	gQMprofile = found
	
	--Update Step-Script List
	local scripts = "None"
	local scriptlist = dirlist(ml_quest_mgr.profilepath,".*lua")
	if ( TableSize(scriptlist) > 0) then			
		local i,script = next ( scriptlist)
		while i and script do				
			script = string.gsub(script, ".lua", "")
			
			scripts = scripts..","..script						
			i,script = next ( scriptlist,i)
		end		
	else
		ml_error("No Questmanager scripts found")		
	end
	gQMS_Script_listitems = scripts
end

function ml_quest_mgr.SaveProfile()
	local filename = ""
    local isnew = false
    -- Save under new name if one was entered
    if ( gQMnewname ~= "" ) then
        filename = gQMnewname
        gQMnewname = ""
        isnew = true
    elseif (gQMprofile ~= nil and gQMprofile ~= "None" and gQMprofile ~= "") then
        filename = gQMprofile
        gQMnewname = ""		
    end
	
	 -- Save current Profiledata into the Profile-file 
    if ( filename ~= "" ) then
		d("Saving Profile Data into File: "..filename)
		
		-- Charspecific Profile with progress
		local pName = Player.name	
		pName = pName:gsub('%W','') -- only alphanumeric
		if ( pName ~= nil and pName ~= "" ) then        
			persistence.store( ml_quest_mgr.profilepath..gQMprofile.."_"..pName..".qmpx", ml_quest_mgr.QuestList)
		end
		
		-- Clean profile without progress for sharing		
		local cleanProfile = deepcopy( ml_quest_mgr.QuestList )
		cleanProfile = ml_quest_mgr.ResetProfile(cleanProfile)
		persistence.store( ml_quest_mgr.profilepath..filename..".qmp", cleanProfile)
		
		if ( isnew ) then
            gQMprofile_listitems = gQMprofile_listitems..","..filename
            gQMprofile = filename
            Settings[ml_quest_mgr.ModuleName].gQMprofile = filename
        end
	else
		ml_error("You need to enter a new Filename first!!")
	end
end

function ml_quest_mgr.CreateNewProfile()
	-- Delete existing Skills
    GUI_DeleteGroup(ml_quest_mgr.mainwindow.name,GetString("quests"))
	GUI_WindowVisible(ml_quest_mgr.editwindow.name,false)
	GUI_WindowVisible(ml_quest_mgr.stepwindow.name,false)
    gQMprofile = "None"
    Settings[ml_quest_mgr.ModuleName].gQMprofile = gQMprofile
    gQMnewname = ""	
	ml_quest_mgr.QuestList = {}
end

function ml_quest_mgr.AddNewQuest( quest )
	local newquestprio = table.maxn(ml_quest_mgr.QuestList)+1
	if ( quest and quest.prio ) then
		newquestprio = quest.prio
	end	
	local bevent = "Q"..tostring(newquestprio)
	
	local qname = "NewQuest"
	if ( quest and quest.name ~= "" ) then
		qname = quest.name
	end
	
	GUI_NewButton(ml_quest_mgr.mainwindow.name, tostring(newquestprio)..": "..qname, bevent,GetString("quests"))
	-- Check if a event with this name is already registered, this is needed since we cannot unregister events
	
	if ( ml_quest_mgr.RegisteredButtonEventList[bevent] == nil ) then
		RegisterEventHandler(bevent,ml_quest_mgr.EditQuest)
		ml_quest_mgr.RegisteredButtonEventList[bevent] = 1
	end
		
	if ( not quest ) then
		-- we are adding a new quest manually , not by loading a profile
		ml_quest_mgr.QuestList[newquestprio] = {		
			prio = newquestprio,
			name = "",
			done = "0",
			minlevel = 0,
			maxlevel = 80,		
			map = Player.localmapid, -- TODO: get currentmap name from the maps.data file here
			--prequest = "0",
			repeatable = "1",
			steps = {}
		}
		ml_quest_mgr.ToggleEditorMenu( 1 )
	else		
		ml_quest_mgr.QuestList[newquestprio] = {		
			prio = newquestprio,
			name = quest.name,
			done = quest.done,
			minlevel = quest.minlevel,
			maxlevel = quest.maxlevel,		
			map = quest.map,
			--prequest = quest.prequest,
			repeatable = quest.repeatable,
			steps = quest.steps
		}
	end
end

function ml_quest_mgr.RefreshQuestList()
	GUI_DeleteGroup(ml_quest_mgr.mainwindow.name,GetString("quests"))
	if ( TableSize( ml_quest_mgr.QuestList ) > 0 ) then
		local i,s = next ( ml_quest_mgr.QuestList )
		while i and s do
			ml_quest_mgr.AddNewQuest(s)
			i,s = next ( ml_quest_mgr.QuestList , i )
		end
	end
	GUI_UnFoldGroup(ml_quest_mgr.mainwindow.name,GetString("quests"))
	
	-- Update global variables from used scripts
	ml_quest_mgr.RefreshScriptData()
end


--**********************
-- EDITOR Functions
--**********************
function ml_quest_mgr.EditorButtonHandler(event)
	if ( event == "QMDeleteQuest") then				
		if ( TableSize(ml_quest_mgr.QuestList) > 0 ) then
			local i,s = next ( ml_quest_mgr.QuestList, ml_quest_mgr.editwindow.currentPrio)
			while i and s do
				s.prio = s.prio - 1
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio] = s
				ml_quest_mgr.editwindow.currentPrio = i
				i,s = next ( ml_quest_mgr.QuestList, i)
			end
			ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio] = nil
			ml_quest_mgr.RefreshQuestList()	
			GUI_WindowVisible(ml_quest_mgr.editwindow.name,false)
			GUI_WindowVisible(ml_quest_mgr.stepwindow.name,false)
		end
		
	elseif (event == "QMHigherPrioQuest") then		
		if ( TableSize(ml_quest_mgr.QuestList) > 0 ) then
			if ( ml_quest_mgr.editwindow.currentPrio > 1) then
				local tmp = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio-1]
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio-1] = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio]
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio-1].prio = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio-1].prio - 1
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio] = tmp
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].prio = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].prio + 1
				ml_quest_mgr.editwindow.currentPrio = ml_quest_mgr.editwindow.currentPrio-1
				GUI_WindowVisible(ml_quest_mgr.stepwindow.name,false)
				ml_quest_mgr.RefreshQuestList()				
			end
		end
		
	elseif ( event == "QMLowerPrioQuest") then			
		if ( TableSize(ml_quest_mgr.QuestList) > 0 ) then
			if ( ml_quest_mgr.editwindow.currentPrio < TableSize(ml_quest_mgr.QuestList)) then
				local tmp = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio+1]
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio+1] = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio]
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio+1].prio = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio+1].prio + 1
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio] = tmp
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].prio = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].prio - 1
				ml_quest_mgr.editwindow.currentPrio = ml_quest_mgr.editwindow.currentPrio+1
				GUI_WindowVisible(ml_quest_mgr.stepwindow.name,false)
				ml_quest_mgr.RefreshQuestList()				
			end
		end
	elseif ( event == "QMResetQuest") then
		if ( TableSize(ml_quest_mgr.QuestList) > 0 and TableSize(ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio]) > 0) then
			ml_quest_mgr.ResetQuest( ml_quest_mgr.editwindow.currentPrio )
			ml_quest_mgr.RefreshQuestList()
			GUI_WindowVisible(ml_quest_mgr.editwindow.name,false)
			GUI_WindowVisible(ml_quest_mgr.stepwindow.name,false)		
		end
	end	
end

function ml_quest_mgr.EditQuest( arg )	
	if ( arg ) then
		ml_quest_mgr.editwindow.currentPrio = tonumber(string.sub(arg, 2))
	end
	
	local wnd = GUI_GetWindowInfo(ml_quest_mgr.mainwindow.name)
	GUI_MoveWindow( ml_quest_mgr.editwindow.name, wnd.x+wnd.width,wnd.y) 
	GUI_WindowVisible(ml_quest_mgr.editwindow.name,true)
	GUI_SizeWindow(ml_quest_mgr.editwindow.name,ml_quest_mgr.editwindow.w,ml_quest_mgr.editwindow.h)
	
	local quest = ml_quest_mgr.QuestList[tonumber(ml_quest_mgr.editwindow.currentPrio)]	
	if ( quest ) then
		QME_Name = quest.name
		QME_Done = quest.done
		QME_MinLevel = tonumber(quest.minlevel)
		QME_MaxLevel = tonumber(quest.maxlevel)
		QME_Map = quest.map
		--QME_PrevQuest = quest.prequest
		QME_Repeat = quest.repeatable
	else
		ml_error("QuestList[prio] is nil!")		
	end
	
	--Updating StepWindow for this Quest
	GUI_WindowVisible(ml_quest_mgr.stepwindow.name,false)
	ml_quest_mgr.RefreshStepList()
		--stubborn ffxivGUI
	GUI_SizeWindow(ml_quest_mgr.mainwindow.name,ml_quest_mgr.mainwindow.w,ml_quest_mgr.mainwindow.h)
	GUI_SizeWindow(ml_quest_mgr.editwindow.name,ml_quest_mgr.editwindow.w,ml_quest_mgr.editwindow.h)
	GUI_SizeWindow(ml_quest_mgr.stepwindow.name,ml_quest_mgr.stepwindow.w,ml_quest_mgr.stepwindow.h)
end

function ml_quest_mgr.ToggleEditorMenu( arg )
	if (arg == 0) then
		GUI_WindowVisible(ml_quest_mgr.editwindow.name,false)
	else
		local wnd = GUI_GetWindowInfo(ml_quest_mgr.mainwindow.name)
		GUI_MoveWindow( ml_quest_mgr.editwindow.name, wnd.x+wnd.width,wnd.y)
		GUI_WindowVisible(ml_quest_mgr.editwindow.name,true)
		GUI_SizeWindow(ml_quest_mgr.editwindow.name,ml_quest_mgr.editwindow.w,ml_quest_mgr.editwindow.h)		
	end
end

function ml_quest_mgr.AddNewStep( step )

	local newquestprio = 1
	if ( TableSize(  ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps ) > 0 ) then
		newquestprio = table.maxn(ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps)+1
	end
	if ( step and step.prio ) then
		newquestprio = step.prio
	end	
	local bevent = "S"..tostring(newquestprio)
	
	local qname = "NewStep"
	if ( step and step.name ~= nil and step.name ~= "" ) then
		qname = step.name
	end
	
	GUI_NewButton(ml_quest_mgr.editwindow.name, tostring(newquestprio)..": "..qname, bevent,GetString("questSteps"))
	-- Check if a event with this name is already registered, this is needed since we cannot unregister events
	
	if ( ml_quest_mgr.RegisteredButtonEventList[bevent] == nil ) then
		RegisterEventHandler(bevent,ml_quest_mgr.EditStep)
		ml_quest_mgr.RegisteredButtonEventList[bevent] = 1
	end
		
	if ( not step ) then
		-- we are adding a new step manually , not by loading a profile
		ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[newquestprio] = {		
			prio = newquestprio,
			name = "",
			done = "0",
			script = { 
				name = "None",
				data = {},
			},			
		}
		ml_quest_mgr.ToggleStepEditorMenu( 1 )
	else		
		ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[newquestprio] = {		
			prio = newquestprio,
			name = step.name,
			done = step.done,			
			script = step.script			
		}
	end
end

function ml_quest_mgr.RefreshStepList()	
	GUI_DeleteGroup(ml_quest_mgr.editwindow.name,GetString("questSteps"))
	if ( TableSize( ml_quest_mgr.QuestList ) > 0 and TableSize( ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps ) > 0) then
			
		local i,s = next ( ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps )
		while i and s do
			ml_quest_mgr.AddNewStep(s)
			i,s = next ( ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps , i )
		end
	end
	GUI_UnFoldGroup(ml_quest_mgr.editwindow.name,GetString("questSteps"))
end


--**********************
-- STEP EDITOR Functions
--**********************
function ml_quest_mgr.StepButtonHandler(event)
	if ( event == "QMAddStep") then
		ml_quest_mgr.AddNewStep( nil )
		ml_quest_mgr.stepwindow.currentPrio = table.maxn(ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps)
		GUI_UnFoldGroup(ml_quest_mgr.editwindow.name,GetString("questSteps"))
		ml_quest_mgr.EditStep( nil )

	elseif ( event == "QMDeleteStep") then				
		if ( TableSize(ml_quest_mgr.QuestList) > 0 and TableSize( ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps ) > 0) then
			local i,s = next ( ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps, ml_quest_mgr.stepwindow.currentPrio)
			while i and s do
				s.prio = s.prio - 1
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio] = s
				ml_quest_mgr.stepwindow.currentPrio = i
				i,s = next ( ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps, i)
			end
			ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio] = nil
			ml_quest_mgr.RefreshStepList()	
			GUI_WindowVisible(ml_quest_mgr.stepwindow.name,false)
		end
		
	elseif (event == "QMHigherPrioStep") then		
		if ( TableSize(ml_quest_mgr.QuestList) > 0 and TableSize( ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps ) > 0) then
			if ( ml_quest_mgr.stepwindow.currentPrio > 1) then
				local tmp = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio-1]
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio-1] = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio]
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio-1].prio = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio-1].prio - 1
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio] = tmp
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio].prio = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio].prio + 1
				ml_quest_mgr.stepwindow.currentPrio = ml_quest_mgr.stepwindow.currentPrio-1
				ml_quest_mgr.RefreshStepList()				
			end
		end
		
	elseif ( event == "QMLowerPrioStep") then			
		if ( TableSize(ml_quest_mgr.QuestList) > 0 and TableSize( ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps ) > 0) then
			if ( ml_quest_mgr.stepwindow.currentPrio < TableSize(ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps)) then
				local tmp = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio+1]
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio+1] = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio]
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio+1].prio = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio+1].prio + 1
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio] = tmp
				ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio].prio = ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio].prio - 1
				ml_quest_mgr.stepwindow.currentPrio = ml_quest_mgr.stepwindow.currentPrio+1
				ml_quest_mgr.RefreshStepList()						
			end
		end
	end
end

function ml_quest_mgr.EditStep( arg )
	if ( arg ) then
		ml_quest_mgr.stepwindow.currentPrio = tonumber(string.sub(arg, 2))
	end
	
	local wnd = GUI_GetWindowInfo(ml_quest_mgr.editwindow.name)
	GUI_MoveWindow( ml_quest_mgr.stepwindow.name, wnd.x+wnd.width,wnd.y) 
	GUI_WindowVisible(ml_quest_mgr.stepwindow.name,true)
	GUI_SizeWindow(ml_quest_mgr.stepwindow.name,ml_quest_mgr.stepwindow.w,ml_quest_mgr.stepwindow.h)
	if ( TableSize(ml_quest_mgr.QuestList) > 0 and TableSize( ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps) > 0) then
		local step = ml_quest_mgr.QuestList[tonumber(ml_quest_mgr.editwindow.currentPrio)].steps[tonumber(ml_quest_mgr.stepwindow.currentPrio)]	
		if ( step ) then
			QMS_Name = step.name
			QMS_Done = step.done
			gQMS_Script = step.script.name
			-- Update Script UI
			ml_quest_mgr.RefreshScript()
		else
			ml_error("QuestList[prio][step] is nil!")		
		end	
	end
end

function ml_quest_mgr.ToggleStepEditorMenu( arg )
	if (arg == 0) then
		GUI_WindowVisible(ml_quest_mgr.stepwindow.name,false)
	else
		local wnd = GUI_GetWindowInfo(ml_quest_mgr.editwindow.name)
		GUI_MoveWindow( ml_quest_mgr.stepwindow.name, wnd.x+wnd.width,wnd.y)
		GUI_WindowVisible(ml_quest_mgr.stepwindow.name,true)
		GUI_SizeWindow(ml_quest_mgr.stepwindow.name,ml_quest_mgr.stepwindow.w,ml_quest_mgr.stepwindow.h)		
	end
end

--**********************
-- SCRIPT Functions
--**********************
-- Refreshes the currently shown ScriptUI and loads the corresponding scriptdata into the UI fields
function ml_quest_mgr.RefreshScript()
	-- Clear old scriptUI
	GUI_DeleteGroup(ml_quest_mgr.stepwindow.name,GetString("questStepDetails"))
	
	-- Load the UI elements of the selected script
	if ( gQMS_Script ~= nil and gQMS_Script ~= "" and gQMS_Script ~= "None" ) then
		-- Load Custom Step UI from script		
		local loadedFunction, cError = loadfile(ml_quest_mgr.profilepath..gQMS_Script..".lua")
		if ( loadedFunction == nil) then
			ml_error(" Couldnt load scriptfile")
		else			
			local script = loadedFunction()
			
			-- Assing it so we have access to this current script-instance later
			ml_quest_mgr.currentscript = script
			
			-- Load script UI elements
			local ident = "QPrio"..tostring(ml_quest_mgr.editwindow.currentPrio).."_QStep"..tostring(ml_quest_mgr.stepwindow.currentPrio).."_QName_"
			script:UIInit( ident )
			
			-- Fill the Script UI with its Data and define the global variables
			--d(ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio].script.data)
			script:SetData( ident, ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio].script.data )						
		end
	end	
	
	GUI_UnFoldGroup(ml_quest_mgr.stepwindow.name,GetString("questStepDetails"))
end

-- Saves the entered/changed data of the currently shown ScriptUI-Elements in the QuestList table
function ml_quest_mgr.ScriptUIEventHandler( event, eventTxt )
	--d("Scriptevent: "..event.. " eventTxt: "..eventTxt)
		
	if ( eventTxt ) then
		local ePos = string.find(eventTxt, "QPrio") 
		local sPos = string.find(eventTxt, "_QStep")
		local sEndPos = string.find(eventTxt, "_QName_")
						
		if ( ePos and sPos and sEndPos) then
			local ePrio = string.sub(eventTxt,ePos+5,sPos-1)
			local sPrio = string.sub(eventTxt,sPos+6,sEndPos-1)
			local evName = string.sub(eventTxt,sEndPos+7)
			--d ( tostring(ePrio).." "..tostring(sPrio).." "..tostring(evName))
			if ( tonumber(ePrio) and tonumber(sPrio) and evName and evName ~= "" ) then
				
				-- save script variable data in the QuestList[][].script.data[]
				if ( ml_quest_mgr.QuestList[tonumber(ePrio)]  and ml_quest_mgr.QuestList[tonumber(ePrio)].steps[tonumber(sPrio)]  and ml_quest_mgr.QuestList[tonumber(ePrio)].steps[tonumber(sPrio)].script.data ) then
					--d("Saving:")
					--d(eventTxt)
					ml_quest_mgr.QuestList[tonumber(ePrio)].steps[tonumber(sPrio)].script.data[tostring(evName)] = _G[eventTxt]
					
					-- Forward the Event to the currently shown script-eventhandler for extended handling
					if ( ml_quest_mgr.currentscript ) then
						local ident = "QPrio"..tostring(ePrio).."_QStep"..tostring(sPrio).."_QName_"
						ml_quest_mgr.currentscript:EventHandler( ident, evName )
					end
				else
					ml_error("Couldnt save script UI-variable into QuestList!")
				end
			end
		end
	end	
end

-- Updates the global variables defined by the loaded scripts 
function ml_quest_mgr.RefreshScriptData()
		
	if ( TableSize( ml_quest_mgr.QuestList ) > 0 ) then
	
		local qprio,quest = next ( ml_quest_mgr.QuestList )
		while qprio and quest do
			
			if ( TableSize( ml_quest_mgr.QuestList[qprio].steps ) > 0 ) then
				local sprio, step = next ( ml_quest_mgr.QuestList[qprio].steps )
				while sprio and step do
					
					if ( ml_quest_mgr.QuestList[qprio].steps[sprio].script.name and ml_quest_mgr.QuestList[qprio].steps[sprio].script.name ~= "" and ml_quest_mgr.QuestList[qprio].steps[sprio].script.name ~= "None") then
					
						local loadedFunction, cError = loadfile(ml_quest_mgr.profilepath..ml_quest_mgr.QuestList[qprio].steps[sprio].script.name..".lua")
						if ( loadedFunction == nil) then
							ml_error(" Couldnt load scriptfile: "..tostring(ml_quest_mgr.QuestList[qprio].steps[sprio].script.name))
						else			
							local script = loadedFunction()
							local ident = "QPrio"..tostring(qprio).."_QStep"..tostring(sprio).."_QName_"
							
							-- Fill the Script UI with its Data and define the global variables
							--d("RefreshScriptData "..ml_quest_mgr.QuestList[qprio].steps[sprio].script.name)
							script:SetData( ident, ml_quest_mgr.QuestList[qprio].steps[sprio].script.data )
						end
					end
				
					sprio,step = next ( ml_quest_mgr.QuestList[qprio].steps , sprio )
				end
			end
			
			qprio,quest = next ( ml_quest_mgr.QuestList , qprio )
		end		
	end
end



--**********************
-- GENERAL Functions
--**********************
function ml_quest_mgr.ToggleMenu()
	if (ml_quest_mgr.visible) then
		GUI_WindowVisible(ml_quest_mgr.mainwindow.name,false)
		GUI_WindowVisible(ml_quest_mgr.editwindow.name,false)
		GUI_WindowVisible(ml_quest_mgr.stepwindow.name,false)
		ml_quest_mgr.currentscript = nil
		ml_quest_mgr.visible = false
	else
		local wnd = GUI_GetWindowInfo("FFXIVMinion")	
		GUI_MoveWindow( ml_quest_mgr.mainwindow.name, wnd.x+wnd.width,wnd.y) 
		GUI_WindowVisible(ml_quest_mgr.mainwindow.name,true)	
		ml_quest_mgr.visible = true
	end
end

function ml_quest_mgr.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		if ( k == "gQMprofile" ) then
			GUI_WindowVisible(ml_quest_mgr.editwindow.name,false)
			GUI_WindowVisible(ml_quest_mgr.stepwindow.name,false)
			ml_quest_mgr.currentscript = nil
			ml_quest_mgr.UpdateCurrentProfileData()
			Settings[ml_quest_mgr.ModuleName].gQMprofile = v
		elseif ( k == "QME_Name" ) then ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].name = v
		elseif ( k == "QME_Done" ) then ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].done = v
		elseif ( k == "QME_MinLevel" ) then ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].minlevel = tonumber(v)
		elseif ( k == "QME_MaxLevel" ) then ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].maxlevel = tonumber(v)
		--elseif ( k == "QME_Map" ) then ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].map = v
		elseif ( k == "QME_PrevQuest" ) then ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].prequest = v
		elseif ( k == "QME_Repeat" ) then ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].repeatable = v
		
		elseif ( k == "QMS_Name" ) then ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio].name = v
		elseif ( k == "QMS_Done" ) then ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio].done = v
		elseif ( k == "gQMS_Script" ) then 
			ml_quest_mgr.QuestList[ml_quest_mgr.editwindow.currentPrio].steps[ml_quest_mgr.stepwindow.currentPrio].script.name = v		
			ml_quest_mgr.RefreshScript()
		end
	end
end



--**********************
-- API (lol) Functions
--**********************
-- Resets all "done" to 0 in the profile
function ml_quest_mgr.ResetProfile( questprofile )
	local profil
	if ( not questprofile ) then 
		profil = ml_quest_mgr.QuestList
	else
		profil = questprofile
	end

	if ( TableSize( profil ) > 0 ) then
	
		local qprio,quest = next ( profil )
		while qprio and quest do
			quest.done = "0"
			if ( TableSize( profil[qprio].steps ) > 0 ) then
				local sprio, step = next ( profil[qprio].steps )
				while sprio and step do
					step.done = "0"									
					sprio,step = next ( profil[qprio].steps , sprio )
				end
			end			
			qprio,quest = next ( profil , qprio )
		end		
	end
	return profil
end

-- Resets all "done" to 0 in the Quest
function ml_quest_mgr.ResetQuest( questprio )

	profil = ml_quest_mgr.QuestList

	if ( TableSize( profil ) > 0 ) then
	
		local qprio,quest = next ( profil )
		while qprio and quest do
			if ( qprio == questprio ) then
				quest.done = "0"
				if ( TableSize( profil[qprio].steps ) > 0 ) then
					local sprio, step = next ( profil[qprio].steps )
					while sprio and step do
						step.done = "0"									
						sprio,step = next ( profil[qprio].steps , sprio )
					end
				end
			end
			qprio,quest = next ( profil , qprio )
		end		
	end
	return profil
end

function ml_quest_mgr.GetNextIncompleteQuest()
	if ( TableSize( ml_quest_mgr.QuestList ) > 0 ) then
	
		local qprio,quest = next ( ml_quest_mgr.QuestList )
		while qprio and quest do
			
			if ( quest.done == "0" and TableSize( ml_quest_mgr.QuestList[qprio].steps ) > 0 ) then
				local sprio, step = next ( ml_quest_mgr.QuestList[qprio].steps )
				while sprio and step do
					
					if ( step.done == "0" and ml_quest_mgr.QuestList[qprio].steps[sprio].script.name and ml_quest_mgr.QuestList[qprio].steps[sprio].script.name ~= "" and ml_quest_mgr.QuestList[qprio].steps[sprio].script.name ~= "None") then
					
						local loadedFunction, cError = loadfile(ml_quest_mgr.profilepath..ml_quest_mgr.QuestList[qprio].steps[sprio].script.name..".lua")
						if ( loadedFunction == nil) then
							ml_error(" in loading scriptfile: "..tostring(ml_quest_mgr.QuestList[qprio].steps[sprio].script.name))
						else			
							local script = loadedFunction()
							local ident = "QPrio"..tostring(qprio).."_QStep"..tostring(sprio).."_QName_"
							
							-- Create an instance of the Script with its Data and define the global variables
							
							d("GetNextIncompleteQuest "..ml_quest_mgr.QuestList[qprio].steps[sprio].script.name)
							script:SetData( ident, ml_quest_mgr.QuestList[qprio].steps[sprio].script.data )
							
							return { qprio, sprio, script } -- returns prios too, so this script can be accessed from the "outside" later, for loading / saving stuff for ex
						end
					end
				
					sprio,step = next ( ml_quest_mgr.QuestList[qprio].steps , sprio )
				end
			end
			
			qprio,quest = next ( ml_quest_mgr.QuestList , qprio )
		end		
	end
	return nil
end

-- to update the quest/step/script data 
function ml_quest_mgr.SetQuestData( qprio, sprio, script, variablename, data )
	if ( TableSize( ml_quest_mgr.QuestList ) > 0 and variablename and data ) then
		if (qprio and TableSize( ml_quest_mgr.QuestList[qprio] ) > 0 ) then
			
			if ( sprio ) then 
				if ( TableSize( ml_quest_mgr.QuestList[qprio].steps[sprio] ) > 0 ) then
										
					if ( script ) then
						if ( ml_quest_mgr.QuestList[qprio].steps[sprio].script ) then
							-- data change should happen in script.data table
							ml_quest_mgr.QuestList[qprio].steps[sprio].script.data[variablename] = data
						else
							ml_error("ml_quest_mgr.SetQuestData: QuestList[qprio].steps[sprio].script nil")
						end
					
					else
						-- data change should happen in step table
						ml_quest_mgr.QuestList[qprio].steps[sprio][variablename] = data
					end				
				else
					ml_error("ml_quest_mgr.SetQuestData: QuestList[qprio].steps[sprio] nil")
				end
			else
				-- data change should happen in quest table
				ml_quest_mgr.QuestList[qprio][variablename] = data
				
			end
			
		else
			ml_error("ml_quest_mgr.SetQuestData: QuestPrio arg is nil or  ml_quest_mgr.QuestList[qprio] nil")
		end
	else
		ml_error("ml_quest_mgr.SetQuestData: QuestList nil or !variablename or !data")
	end
	return false
end





RegisterEventHandler("QuestManager.toggle", ml_quest_mgr.ToggleMenu)
RegisterEventHandler("GUI.Update",ml_quest_mgr.GUIVarUpdate)
RegisterEventHandler("GUI.Item",ml_quest_mgr.ScriptUIEventHandler)

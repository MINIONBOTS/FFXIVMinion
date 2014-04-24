QM = {}
--onOpen can be added if a certain function should run when the window is opened, otherwise it should be left as nil.
--baseY is used to tell the window to position itself below the specified window.
--baseX is used to tell the window to position itself right of the specified window.
QM.Windows = {
	Main = {visible = false, name = "Quest Manager", visibleDefault = false, onOpen = "QM.LoadProfile",
		x = 500, y = 40, width = 250, height = 520
	},
	QuestEditor = {visible = false, name = "Quest Editor", visibleDefault = false,
		base = "Main", width = 250, height = 250
	},
	StepManager = {visible = false, name = "Step Manager", visibleDefault = false, onOpen = "QM.LoadTaskFields",
		base = "QuestEditor", width = 250, height = 400
	},
	StepEditor = {visible = false, name = "Step Editor", visibleDefault = false,
		base = "StepManager", width = 250, height = 300
	},
	TurnInEditor = {visible = false, name = "Turn-In Editor", visibleDefault = false, onOpen = "QM.LoadItemSlot;QM.RefreshTurnovers",
		base = "StepManager", width = 250, height = 200
	},
	PreReqEditor = {visible = false, name = "Pre-Req Editor", visibleDefault = false, onOpen = "QM.RefreshPreReqs",
		base = "QuestEditor", width = 250, height = 200
	},
}
QM.Wrappers = {
	Quest = "quests",
	Duty = "Encounters",
}

QM.QuestPath = GetStartupPath()..[[\LuaMods\ffxivminion\QuestProfiles\]];
QM.DutyPath = GetStartupPath()..[[\LuaMods\ffxivminion\DutyProfiles\]];
QM.WindowTick = 0

--Initialize all tracking tables.
QM.Quests = {}
QM.Encounters = {}
QM.CurrentStep = 1
QM.LastQuest = nil

--All variables should be added here, along with their cast type, profile equivalent (if any), and an onChange event, if any functions should be called when the variable is updated.
QM.Variables = {
	qProfileType = 	{ default = "Duty", 	profile = "", 				cast = "string", onChange = "QM.LoadTypeOptions" },
	qProfileName = 	{ default = "None", 	profile = "" , 				cast = "string", onChange = "QM.LoadProfile"},
	qProfileNew = 	{ default = "", 		profile = "" , 				cast = "string"},
	qDutyTask = 	{ default = "Kill", 	profile = "" , 				cast = "string"},
	qDutyCustom = 	{ default = "", 		profile = "" , 				cast = "string"},
	qQuestID = 		{ default = "", 		profile = "" , 				cast = "number"},
	eQuestID = 		{ default = "", 		profile = "" , 				cast = "number"},
	qQuestJob = 	{ default = "None", 	profile = "job", 			cast = "number"},
	eQuestJob = 	{ default = "None", 	profile = "job", 			cast = "number"},
	qQuestLevel = 	{ default = 1,	 		profile = "level", 			cast = "number"},
	eQuestLevel = 	{ default = 1, 			profile = "level", 			cast = "number"},
	qPreReqJob = 	{ default = "All",  	profile = "" , 				cast = "number"},
	qPreReqID = 	{ default = 0,	 		profile = "" , 				cast = "number"},
	qStepNum = 		{ default = 1, 			profile = "" , 				cast = "number"},
	qStepTask = 	{ default = "start",	profile = "type", 			cast = "string", onChange = "QM.LoadTaskFields"},
	qTaskCustom = 	{ default = "", 		profile = "", 				cast = "string"},
	qTaskMesh = 	{ default = "", 		profile = "meshname", 		cast = "string"},
	qTaskMap = 		{ default = "", 		profile = "mapid", 			cast = "number"},
	qTaskNPC = 		{ default = "", 		profile = "id", 			cast = "number"},
	
	qTaskKillTarget = 	{ default = "", 	profile = "id", 			cast = "number"},
	qTaskKillCount = 	{ default = "", 	profile = "killcount", 		cast = "number"},
	qTaskDelay = 		{ default = "", 	profile = "delay", 			cast = "number"},
	qTaskRewardSlot = 	{ default = 0, 		profile = "itemrewardslot", cast = "number"},
	
	qTurnoverStep = 	{ default = 1, 		profile = "" , 				cast = "number"},
	qTurnoverID = 		{ default = "", 	profile = "itemturninid", 	cast = "number"},
	qTurnoverSlot = 	{default = 1, 		profile = "", 				cast = "number", onChange = "QM.LoadItemSlot"},
}

QM.Strings = {
	Meshes = 
		function()
			local meshlist = "none"
			local meshfilelist = dirlist(mm.navmeshfilepath,".*obj")
			if ( TableSize(meshfilelist) > 0) then
				local i,meshname = next ( meshfilelist)
				while i and meshname do
					meshname = string.gsub(meshname, ".obj", "")
					table.insert(mm.meshfiles, meshname)
					meshlist = meshlist..","..meshname
					i,meshname = next ( meshfilelist,i)
				end
			end
			return meshlist
		end,
	QuestIDs = 
		function()
			local questlist = ""
			local questnames = ""
			local ql = Quest:GetQuestList()
			local i,q = next(ql)
			while (i and q) do
				questlist = questlist..","..tostring(i)
				i,q = next(ql,i)
			end
			return questlist
		end,
	QuestTasks = "start,nav,interact,kill,complete,custom",
	QuestJobs = "None,ARCANIST,ARCHER,BARD,BLACKMAGE,CONJURER,DRAGOON,GLADIATOR,LANCER,MARAUDER,MONK,PALADIN,PUGILIST,SCHOLAR,SUMMONER,THAUMATURGE,WARRIOR,WHITEMAGE",
	PreReqJobs = "All,ARCANIST,ARCHER,BARD,BLACKMAGE,CONJURER,DRAGOON,GLADIATOR,LANCER,MARAUDER,MONK,PALADIN,PUGILIST,SCHOLAR,SUMMONER,THAUMATURGE,WARRIOR,WHITEMAGE",
}

QM.Builds = {
	Main = {
		[1] = {5, "GUI_NewComboBox",QM.Windows.Main.name,"Profile Type:",		"qProfileType",	"Details","Duty,Quest"},
		[2] = {5, "GUI_NewComboBox",QM.Windows.Main.name,"Existing Profile:",  	"qProfileName",	"Details", "None"},
		[3] = {4, "GUI_NewField", 	QM.Windows.Main.name,"New Profile",			"qProfileNew",	"Details"},
		[4] = {4, "GUI_NewButton", 	QM.Windows.Main.name,"Create Profile", 		"QM.CreateProfile", "Details"},
		[5] = {3, "GUI_NewButton", 	QM.Windows.Main.name,"Save Profile", 		"QM.SaveProfile"},
	},
	LoadTypeOptions = {
		[1] = {QM.Windows.Main.name, "New Encounter"},
		[2] = {QM.Windows.Main.name, "New Quest"},
		[3] = {QM.Windows.Main.name, "Encounters"},
		[4] = {QM.Windows.Main.name, "Quests"},
	},
	Duty = {
		[1] = {5, "GUI_NewComboBox",QM.Windows.Main.name,"Task:",			"qDutyTask",	"New Encounter",		"Kill,Loot,Custom"},
		[2] = {4, "GUI_NewField",	QM.Windows.Main.name,"Custom Task:",	"qDutyCustom",	"New Encounter"},
		[3] = {4, "GUI_NewButton", 	QM.Windows.Main.name,"Add Encounter", "QM.AddEncounter", "New Encounter"},
	},
	Quest = {
		[1] = {4, "GUI_NewField",	QM.Windows.Main.name,"Quest ID:",		"qQuestID",		"New Quest"},
		[2] = {4, "GUI_NewButton",	QM.Windows.Main.name,"Pull Quest ID", 	"QM.PullQuest",	"New Quest"},
		[3] = {5, "GUI_NewComboBox",QM.Windows.Main.name,"Quest Job:",		"qQuestJob",	"New Quest", QM.Strings.QuestJobs},
		[4] = {4, "GUI_NewField",	QM.Windows.Main.name,"Quest Level:",	"qQuestLevel",	"New Quest"},
		[5] = {4, "GUI_NewButton",	QM.Windows.Main.name,"Add Quest", 		"QM.AddQuest",  "New Quest"},
	},
	QuestEditor = {
		[1] = {4, "GUI_NewField",	QM.Windows.QuestEditor.name,"Quest ID:",		"eQuestID",		 "Details"},
		[2] = {4, "GUI_NewButton",	QM.Windows.QuestEditor.name,"Pull Quest ID", 	"QM.PullQuest",	 "Details"},
		[3] = {5, "GUI_NewComboBox",QM.Windows.QuestEditor.name,"Quest Job:",		"eQuestJob",	 "Details", QM.Strings.QuestJobs},
		[4] = {4, "GUI_NewField",	QM.Windows.QuestEditor.name,"Quest Level:",	    "eQuestLevel",	 "Details"},
		[5] = {3, "GUI_NewButton",	QM.Windows.QuestEditor.name,"Delete Quest",		"QM.DeleteQuest"},
		[6] = {3, "GUI_NewButton",	QM.Windows.QuestEditor.name,"Save Quest", 		"QM.ModifyQuest"},
		[7] = {3, "GUI_NewButton",	QM.Windows.QuestEditor.name,"Edit Steps", 		"QMToggleStepManager"},
		[8] = {3, "GUI_NewButton",	QM.Windows.QuestEditor.name,"Edit Pre-Reqs",	"QMTogglePreReqEditor"},
	},
	PreReqEditor = {
		[1] = {5, "GUI_NewComboBox",QM.Windows.PreReqEditor.name,"PreReq Job:",	"qPreReqJob",	 "New Pre-Req", QM.Strings.PreReqJobs},		
		[2] = {4, "GUI_NewField",	QM.Windows.PreReqEditor.name,"PreReq ID:",	"qPreReqID",  	"New Pre-Req"},
		[3] = {3, "GUI_NewButton", 	QM.Windows.PreReqEditor.name,"Clear All PreReqs",	"QM.ClearPreReqs"},
		[4] = {3, "GUI_NewButton",	QM.Windows.PreReqEditor.name,"Add Pre-Req",			"QM.AddPreReq"},
	},
	StepManager = {
		[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,"Current Step:",	"qStepNum",		"New Step"},
		[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,"Step Task:",		"qStepTask",	"New Step",	QM.Strings.QuestTasks},
		[3] = {3, "GUI_NewButton", 	QM.Windows.StepManager.name,"Clear All Steps", 	"QM.ClearSteps"},
		[4] = {3, "GUI_NewButton",	QM.Windows.StepManager.name,"Edit Turn-in(s)",	"QMToggleTurnInEditor"},
	},
	TurnInEditor = {
		[1] = {4, "GUI_NewField",	QM.Windows.TurnInEditor.name,"Step #:",		"qTurnoverStep","New Turnover"},
		[2] = {4, "GUI_NewField",	QM.Windows.TurnInEditor.name,"Turn-in ID:",	"qTurnoverID",	"New Turnover"},
		[3] = {4, "GUI_NewNumeric",	QM.Windows.TurnInEditor.name,"Item Slot:",	"qTurnoverSlot","New Turnover"},
		[4] = {3, "GUI_NewButton", 	QM.Windows.TurnInEditor.name,"Clear All Turnovers", "QM.ClearTurnovers"},
		[5] = {3, "GUI_NewButton",	QM.Windows.TurnInEditor.name,"Add Turnover", 		"QM.AddTurnover"},
	},
	QuestTasks = {
		["start"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,"Current Step:",	"qStepNum",	"New Step"},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,"Step Task:",	"qStepTask","New Step",	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Map ID:","qTaskMap",	"New Step"},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,"MeshName:","qTaskMesh","New Step", QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",QM.Windows.StepManager.name,"NPC ID:","qTaskNPC","New Step"},
			[6] = {4, "GUI_NewButton",QM.Windows.StepManager.name,"Add Step", "QM.AddStep","New Step"},
		},
		["nav"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,"Current Step:",	"qStepNum",	"New Step"},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,"Step Task:",	"qStepTask","New Step",	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Map ID:",	"qTaskMap",	"New Step"},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,"MeshName:","qTaskMesh","New Step", QM.Strings.Meshes },
			[5] = {4, "GUI_NewButton",QM.Windows.StepManager.name,"Add Step", "QM.AddStep","New Step"},
		},
		["kill"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,"Current Step:",	"qStepNum",	"New Step"},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,"Step Task:",	"qStepTask","New Step",	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Map ID:",		"qTaskMap","New Step"},
			[4] = {4, "GUI_NewField",QM.Windows.StepManager.name,"MeshName:",	"qTaskMesh","New Step", QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Target ID:",	"qTaskKillTarget","New Step"},
			[6] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Kill Count:",  "qTaskKillCount","New Step"},
			[7] = {4, "GUI_NewButton",QM.Windows.StepManager.name,"Add Step", "QM.AddStep","New Step"},
		},
		["interact"] = {
			[1] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Current Step:",	"qStepNum",	"New Step"},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,"Step Task:",	"qStepTask","New Step",	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Map ID:","qTaskMap","New Step"},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,"MeshName:","qTaskMesh","New Step", QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",QM.Windows.StepManager.name,"NPC ID:","qTaskNPC","New Step"},
			[6] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Delay:","qTaskDelay","New Step"},
			[7] = {4, "GUI_NewButton",QM.Windows.StepManager.name,"Add Step", "QM.AddStep","New Step"},
		},
		["complete"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,"Current Step:",	"qStepNum",	"New Step"},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,"Step Task:",	"qStepTask","New Step",	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Map ID:","qTaskMap","New Step"},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,"MeshName:","qTaskMesh","New Step", QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",QM.Windows.StepManager.name,"NPC ID:","qTaskNPC","New Step"},
			[6] = {4, "GUI_NewNumeric",QM.Windows.StepManager.name,"Reward Slot:","qTaskRewardSlot","New Step"},
			[7] = {4, "GUI_NewButton",QM.Windows.StepManager.name,"Add Step", "QM.AddStep","New Step"},
		},
		["custom"] = {
			[1] = {4, "GUI_NewField",	QM.Windows.StepManager.name,"Current Step:",	"qStepNum",	"New Step"},
			[2] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,"Step Task:",	"qStepTask","New Step",	QM.Strings.QuestTasks},
			[3] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Custom Task:","qTaskCustom","New Step"},
			[4] = {5, "GUI_NewComboBox",QM.Windows.StepManager.name,"MeshName:","qTaskMesh","New Step", QM.Strings.Meshes },
			[5] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Map ID:","qTaskMap","New Step"},
			[6] = {4, "GUI_NewField",QM.Windows.StepManager.name,"NPC ID:","qTaskNPC","New Step"},
			[5] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Target ID:","qTaskKillTarget","New Step"},
			[7] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Kill Count:","qTaskKillCount","New Step"},
			[8] = {4, "GUI_NewField",QM.Windows.StepManager.name,"Delay:","qTaskDelay","New Step"},
			[9] = {4, "GUI_NewNumeric",QM.Windows.StepManager.name,"Reward Slot:","qTaskRewardSlot","New Step"},
			[10] = {4, "GUI_NewButton",QM.Windows.StepManager.name,"Add Step", "QM.AddStep","New Step"},
		},		
	},
}

function QM.Init()

	if (Settings.FFXIVMINION.qmWindow == nil or Settings.FFXIVMINION.qmWindow == {}) then 
		local windowInfo = {} 
		windowInfo.width = 250
		windowInfo.height = 400
		windowInfo.x = 200
		windowInfo.y = 40
		
		Settings.FFXIVMINION.qmWindow = windowInfo
	end
	
	--Make sure all variables are initialized.
	for k,v in pairs(QM.Variables) do
		if Settings.FFXIVMINION[k] == nil then Settings.FFXIVMINION[k] = v.default end
	end
	
	--Create Windows
	QM.LoadWindows()
	--Pull starting values from settings file.
	QM.LoadVariables()
	
	--QM.LoadProfile()
	--Pull starting window fields for whichever type is selected.
	QM.LoadTypeOptions()
	
	--Add the Button to FFXIVMINION window
	GUI_NewButton("FFXIVMINION","Quest Manager","QMToggleMain")
end
--**************************************************************************************************************************************
function QM.GUIVarUpdate(Event, NewVals, OldVals)
	
	for k,v in pairs(NewVals) do
		if (Settings.FFXIVMINION[tostring(k)] == nil) then
			return
		end

		if (QM.Variables[tostring(k)].cast == "number") then
			if (v ~= nil) then
				Settings.FFXIVMINION[tostring(k)] = tonumber(v)
			else
				Settings.FFXIVMINION[tostring(k)] = 0
			end
		elseif (QM.Variables[tostring(k)].cast == "string") then
			Settings.FFXIVMINION[tostring(k)] = tostring(v)
		elseif (QM.Variables[tostring(k)].cast == "boolean") then
			local bool = tostring(v) == "true" and true or false
			Settings.FFXIVMINION[tostring(k)] = bool
		end  
		
		if (QM.Variables[tostring(k)].onChange ~= nil) then
			QM.ExecuteFunction(QM.Variables[tostring(k)].onChange)
		end
	end
	
	for k,v in pairs(QM.Windows) do
		GUI_RefreshWindow(v.name)
	end
end
--**************************************************************************************************************************************
function QM.LoadProfile()
	
	local info = {}

	if (qProfileType == "Duty") then
		info = persistence.load(QM.DutyPath..qProfileName..".info")
		if (TableSize(info) > 0) then
			QM.Encounters = info
		else
			QM.Encounters = {}
		end
	else
		info = persistence.load(QM.QuestPath..qProfileName..".info")
		if (TableSize(info) > 0) then
			QM.Quests = info.quests
		else
			QM.Quests = {}
		end
		QM.RefreshQuests()
	end
end
--**************************************************************************************************************************************
function QM.CreateProfile()
	local starter = {}
	starter[tostring(QM.Wrappers[qProfileType])] = {}
	
	if (qProfileType == "Duty") then
		persistence.store(QM.DutyPath..qProfileNew..".info",starter)
	else
		persistence.store(QM.QuestPath..qProfileNew..".info",starter)
	end
	
	QM.LoadTypeOptions()
	
	qProfileName = qProfileNew
	qProfileNew = ""
	
	QM.PushVariables()
end
--**************************************************************************************************************************************
function QM.SaveProfile()	
	if (qProfileType == "Duty") then
		local info = {}
		info.Encounters = QM.Encounters
		persistence.store(QM.DutyPath..qProfileName..".info",info)
	else
		local info = {}
		info.quests = QM.Quests
		persistence.store(QM.QuestPath..qProfileName..".info",info)
	end
end
--**************************************************************************************************************************************
function QM.AddQuest()
	local quest = {}
	local k = tonumber(qQuestID)
	quest.steps = {}
	if (qQuestJob ~= "None") then quest.job = tonumber(FFXIV.JOBS[qQuestJob]) end
	quest.level = tonumber(qQuestLevel)
	quest.prereq = false
	QM.Quests[k] = quest
	
	QM.RefreshQuests()
end
--**************************************************************************************************************************************
function QM.PullQuest()
	QM.LastQuest = tonumber(qQuestID)
	local quest = Quest:GetSelectedJournalQuest()
	qQuestID = tonumber(quest)
	Settings.FFXIVMINION.qQuestID = qQuestID
end
--**************************************************************************************************************************************
function QM.EditQuest(id)
	local id = tonumber(id)
    local wnd = GUI_GetWindowInfo(QM.Windows.Main.name)	
    
	GUI_MoveWindow( QM.Windows.QuestEditor.name, wnd.x+wnd.width,wnd.y)

    local quest = QM.Quests[id]
	eQuestID = id
	eQuestJob = (quest.job ~= nil and quest.job or QM.Variables.eQuestJob.default)
	eQuestLevel = quest.level
	
	Settings.FFXIVMINION.eQuestID = eQuestID
	Settings.FFXIVMINION.eQuestJob = eQuestJob
	Settings.FFXIVMINION.eQuestLevel = eQuestLevel
	
	GUI_WindowVisible(QM.Windows.QuestEditor.name,true)
end
--**************************************************************************************************************************************
function QM.ModifyQuest()
	local k = tonumber(eQuestID)
	local quest = QM.Quests[k]
	
	if (eQuestJob ~= "None") then quest.job = tonumber(FFXIV.JOBS[eQuestJob]) end
	quest.level = tonumber(eQuestLevel)
	
	QM.Quests[k] = quest
	QM.LastQuest = k

	QM.RefreshQuests()
end
--**************************************************************************************************************************************
function QM.DeleteQuest()
	local k = tonumber(eQuestID)
	QM.Quests[k] = nil
	
	QM.RefreshQuests()
end
--**************************************************************************************************************************************
function QM.RefreshQuests()
	GUI_DeleteGroup(QM.Windows.Main.name,"Quests")
	if (TableSize(QM.Quests) > 0) then
		for k,v in pairs(QM.Quests) do
			GUI_NewButton(QM.Windows.Main.name, tostring(k), "QMQuestEdit"..tostring(k), "Quests")
		end
		GUI_UnFoldGroup(QM.Windows.Main.name,"Quests")
	end
	
	GUI_SizeWindow(QM.Windows.Main.name,Settings.FFXIVMINION.qmWindow.width,Settings.FFXIVMINION.qmWindow.height)
	GUI_RefreshWindow(QM.Windows.Main.name)
end
--**************************************************************************************************************************************
function QM.AddEncounter()

end
--**************************************************************************************************************************************
function QM.AddPreReq()
	local id = tonumber(eQuestID)
	
	if (qPreReqJob ~= "None" and qPreReqID == nil) then 
		return 
	end
	
	if (qPreReqJob == "All") then
		if (type(QM.Quests[id].prereq) == "boolean") then QM.Quests[id].prereq = {} end
		QM.Quests[id].prereq[-1] = tonumber(qPreReqID)
	else
		if (type(QM.Quests[id].prereq) == "boolean") then QM.Quests[id].prereq = {} end
		QM.Quests[id].prereq[FFXIV.JOBS[qPreReqJob]] = tonumber(qPreReqID)
	end
	QM.RefreshPreReqs()
end
--**************************************************************************************************************************************
function QM.RemovePreReq(key)
	local id = tonumber(eQuestID)
	local key = tonumber(key)
	
	if (TableSize(QM.Quests[id].prereq) == 1) then
		QM.Quests[id].prereq = nil
		QM.Quests[id].prereq = false
	else
		QM.Quests[id].prereq[key] = nil
	end
	QM.RefreshPreReqs()
end
--**************************************************************************************************************************************
function QM.RefreshPreReqs()

	local id = tonumber(eQuestID)
	
	GUI_DeleteGroup(QM.Windows.PreReqEditor.name,"PreReqs")
	local unfold = false
	if (type(QM.Quests[id].prereq) ~= "boolean") then
		for k,v in pairs(QM.Quests[id].prereq) do
			GUI_NewButton(QM.Windows.PreReqEditor.name, tostring(v).."["..tostring(k).."]", "QMPreReqRemove"..tostring(k), "PreReqs")
			unfold = true
		end
	end
		
	if (unfold) then
		GUI_UnFoldGroup(QM.Windows.PreReqEditor.name,"PreReqs")
	end
	
	qPreReqID = tonumber(QM.LastQuest)
	Settings.FFXIVMINION.qPreReqID = qPreReqID
	
	local wnd = QM.Windows.PreReqEditor
	GUI_SizeWindow(wnd.name,wnd.width,wnd.height)
	GUI_RefreshWindow(wnd.name)
end
--**************************************************************************************************************************************
function QM.ClearPreReqs()
	local id = tonumber(eQuestID)
	QM.Quests[id].prereq = nil
	QM.Quests[id].prereq = false
	QM.RefreshPreReqs()
end
--**************************************************************************************************************************************
function QM.AddTurnover()
	local id = tonumber(eQuestID)
	local step = tonumber(qTurnoverStep)
	local key = 1
	
	--In case the step has not yet been created, add the turnin to the blank step.
	--When the step is added, have it detect this scenario.
	if (TableSize(QM.Quests[id].steps[step]) == 0) then
		QM.Quests[id].steps[step] = {}
	end
	
	if (TableSize(QM.Quests[id].steps[step].itemturninid) == 0) then 
		QM.Quests[id].steps[step].itemturninid = {} 
	end
	
	key = TableSize(QM.Quests[id].steps[step].itemturninid) + 1
	
	QM.Quests[id].steps[step].itemturninid[key] = tonumber(qTurnoverID)
	QM.RefreshTurnovers()
end
--**************************************************************************************************************************************
function QM.RefreshTurnovers()
	local id = tonumber(eQuestID)
	
	GUI_DeleteGroup(QM.Windows.TurnInEditor.name,"Turnovers")
	
	local unfold = false
	for k,v in ipairs(QM.Quests[id].steps) do
		if (TableSize(v.itemturninid) > 0) then
			QM.Quests[id].steps[k].itemturnin = true
			for i,item in pairs(v.itemturninid) do
				GUI_NewButton(QM.Windows.TurnInEditor.name, tostring(item).."["..tostring(k).."]["..tostring(i).."]", "QMTurnoverRemove"..tostring(item), "Turnovers")
				unfold = true
			end
		elseif (QM.Quests[id].steps[k].itemturninid == 0) then
			QM.Quests[id].steps[k].itemturnin = false
		end
	end
		
	if (unfold) then
		GUI_UnFoldGroup(QM.Windows.TurnInEditor.name,"Turnovers")
	end
	
	local wnd = QM.Windows.TurnInEditor
	GUI_SizeWindow(wnd.name,wnd.width,wnd.height)
	GUI_RefreshWindow(wnd.name)
end
--**************************************************************************************************************************************
function QM.RemoveTurnover(item)
	local id = tonumber(eQuestID)
	local step = nil
	local key = nil
	local item = tonumber(item)
	local tSize = 0
	
	for k,v in ipairs(QM.Quests[id].steps) do
		if (TableSize(v.itemturninid) > 0) then
			tSize = TableSize(v.itemturninid)
			for x,y in pairs(v.itemturninid) do
				if (tonumber(y) == item) then
					step = tonumber(k)
					key = tonumber(x)
					break
				end
			end
		end
	end
	
	if (tSize == 1) then
		QM.Quests[id].steps[step].itemturninid = nil
		QM.Quests[id].steps[step].itemturninid = 0
	else
		QM.Quests[id].steps[step].itemturninid[key] = nil
	end
	QM.RefreshTurnovers()
end
--**************************************************************************************************************************************
function QM.ClearTurnovers()
	local id = tonumber(eQuestID)
	local step = tonumber(qTurnoverStep)
	
	QM.Quests[id].steps[step].itemturninid = nil
	QM.Quests[id].steps[step].itemturninid = 0
end
--**************************************************************************************************************************************
function QM.AddStep()
	local task = {}
	
	for k,v in ipairs (QM.Builds.QuestTasks[qStepTask]) do
		local value = _G[v[5]]
		if (v[2] ~= "GUI_NewButton" and value ~= nil and value ~= "") then
			local var = QM.Variables[v[5]]
			if var.profile ~= "" then
				if var.cast == "number" then
					task[var.profile] = tonumber(value)
				elseif var.cast == "string" then
					task[var.profile] = tostring(value)
				end
			end
		end
	end
	
	if (task.itemrewardslot ~= 0 and task.itemrewardslot ~= nil) then 
		task.itemreward = true
	else 
		task.itemreward = false
	end
	
	
	
	local pos = Player.pos
	task.pos = {
		["x"] = pos.x;
		["y"] = pos.y;
		["z"] = pos.z;
	};
	
	local id = tonumber(eQuestID)
	local step = tonumber(qStepNum)

	if (QM.Quests[id].steps[step] == nil) then
		QM.Quests[id].steps[step] = {}
	end
	
	if (TableSize(QM.Quests[id].steps[step].itemturninid) > 0) then 
		task.itemturninid = {}
		task.itemturninid = QM.Quests[id].steps[step].itemturninid
		task.itemturnin = true
	end
	
	QM.Quests[id].steps[step] = task
	
	local orderedSteps = {}
	for k,v in pairsByKeys(QM.Quests[id].steps) do
		orderedSteps[k] = v
	end
	QM.Quests[id].steps = orderedSteps;
	
	QM.LoadTaskFields()
end
--**************************************************************************************************************************************
function QM.RemoveStep(id)
	local id = tonumber(id)
    QM.Quests[tonumber(eQuestID)].steps[id] = nil	
	QM.LoadTaskFields()
end
--**************************************************************************************************************************************
function QM.ClearSteps()
    QM.Quests[tonumber(eQuestID)].steps = {}
	QM.LoadTaskFields()
end
--**************************************************************************************************************************************
function QM.LoadTypeOptions()
	QM.CurrentStep = 1
	
	--Reload the profile list for the selected type.
	local profiles = "None"
	local profilelist = {}
	
	if (qProfileType == "Duty") then
		profilelist = dirlist(QM.DutyPath,".*info")
	else
		profilelist = dirlist(QM.QuestPath,".*info")
	end
	
	if ( TableSize(profilelist) > 0) then			
		local i,profile = next ( profilelist)
		while i and profile do				
			profile = string.gsub(profile, ".info", "")
			profiles = profiles..","..profile
			i,profile = next ( profilelist,i)
		end		
	end
	qProfileName_listitems = profiles

	
	for k,v in ipairs(QM.Builds.LoadTypeOptions) do
		GUI_DeleteGroup(v[1],v[2])
	end
	
	local unfoldGroups = {}
	local t = QM.Builds[qProfileType]
	for k,v in ipairs(t) do
		local args = v[1]
		if (args == 3) then
			_G[v[2]](v[3],v[4],v[5])
		elseif (args == 4) then
			_G[v[2]](v[3],v[4],v[5],v[6])
			unfoldGroups[v[6]] = true
		elseif (args == 5) then
			local list
			if (type(v[7]) == "string") then
				list = v[7]
			else
				list = v[7]()
			end
			_G[v[2]](v[3],v[4],v[5],v[6],list)
			unfoldGroups[v[6]] = true
		end
	end
	
	QM.LoadVariables()
	
	for k,v in pairs(unfoldGroups) do
		GUI_UnFoldGroup(QM.Windows.Main.name,tostring(k))
	end
	GUI_SizeWindow(QM.Windows.Main.name,Settings.FFXIVMINION.qmWindow.width,Settings.FFXIVMINION.qmWindow.height)
	GUI_RefreshWindow(QM.Windows.Main.name)
end
--**************************************************************************************************************************************
function QM.LoadTaskFields()	
	GUI_DeleteGroup(QM.Windows.StepManager.name,"New Step")
	
	local t = QM.Builds.QuestTasks[qStepTask]
	for k,v in ipairs(t) do
		local args = v[1]
		if (args == 3) then
			_G[v[2]](v[3],v[4],v[5])
		elseif (args == 4) then
			_G[v[2]](v[3],v[4],v[5],v[6])
		elseif (args == 5) then
			local list
			if (type(v[7]) == "string") then
				list = v[7]
			else
				list = v[7]()
			end
			_G[v[2]](v[3],v[4],v[5],v[6],list)
		end
	end
	
	QM.LoadVariables()
	QM.LoadCurrentValues()
	GUI_UnFoldGroup(QM.Windows.StepManager.name,"New Step")
	
	local id = tonumber(eQuestID)
	local maxStep = 0
	
	GUI_DeleteGroup(QM.Windows.StepManager.name,"Steps")
	if (TableSize(QM.Quests[id].steps) > 0) then
		for k,v in ipairs(QM.Quests[tonumber(eQuestID)].steps) do
			GUI_NewButton(QM.Windows.StepManager.name, tostring(v.type).."["..tostring(k).."]", "QMStepRemove"..tostring(k), "Steps")
			if k > maxStep then maxStep = tonumber(k) end
		end
		GUI_UnFoldGroup(QM.Windows.StepManager.name,"Steps")
	end
	
	maxStep = maxStep + 1
	qStepNum = maxStep
	Settings.FFXIVMINION.qStepNum = qStepNum
	qTurnoverStep = maxStep
	Settings.FFXIVMINION.qTurnoverStep = qTurnoverStep
	
	local wnd = QM.Windows.StepManager
	GUI_SizeWindow(wnd.name,wnd.width,wnd.height)
	GUI_RefreshWindow(wnd.name)
end
--**************************************************************************************************************************************
function QM.LoadVariables()
	for k,v in pairs(QM.Variables) do
		_G[k] = Settings.FFXIVMINION[k]
	end
end
--**************************************************************************************************************************************
function QM.PushVariables()
	for k,v in pairs(QM.Variables) do
		if Settings.FFXIVMINION[k] ~= _G[k] then
			Settings.FFXIVMINION[k] = _G[k]
		end
	end
end
--**************************************************************************************************************************************
function QM.LoadCurrentValues()
	local target = Player:GetTarget()
	if (target ~= nil) then
		qTaskKillTarget = target.contentid
		qTaskNPC = target.uniqueid
	end
	qTaskMesh = tostring(gmeshname)
	qTaskMap = Player.localmapid
	qStepNum = QM.CurrentStep
end
--**************************************************************************************************************************************
function QM.LoadItemSlot()
	slot = tonumber(qTurnoverSlot)
	
	local inv = Inventory("type=2004")
	if (inv) then
		local item = inv[slot]
		if (item) then
			qTurnoverID = tonumber(item.id)
		end
	end
end
--**************************************************************************************************************************************
function QM.LoadWindowFields(window)

	local unfoldGroups = {}
	local t = QM.Builds[window]
	
	--Cycle through the GUI elements for this window and load them, and unfold any necessary groups.
	for k,v in ipairs(t) do
		local args = v[1]
		if (args == 2) then
			_G[v[2]](v[3],v[4])
		elseif (args == 3) then
			_G[v[2]](v[3],v[4],v[5])
		elseif (args == 4) then
			_G[v[2]](v[3],v[4],v[5],v[6])
			unfoldGroups[v[6]] = true
		elseif (args == 5) then
			local list
			if (type(v[7]) == "string") then
				list = v[7]
			else
				list = v[7]()
			end
			_G[v[2]](v[3],v[4],v[5],v[6],list)
			unfoldGroups[v[6]] = true
		end
	end
	
	for k,v in pairs(unfoldGroups) do
		GUI_UnFoldGroup(QM.Windows[window].name,tostring(k))
	end
end
--**************************************************************************************************************************************
function QM.LoadWindows()	
	local windows = QM.Windows
	local WI = Settings.FFXIVMINION.qmWindow
	--The main window is used as the base x,y.
	--We use sizes and window offsets in the windows QM.Windows table to manage exact sizing/positions if necessary.
	
	for k,v in pairs(windows) do
		if (TableSize(QM.Builds[k]) > 0) then
			local wname = v.name
			GUI_NewWindow	(wname,WI.x,WI.y,v.width,v.height)
			QM.LoadWindowFields(k)
			GUI_SizeWindow	(wname,v.width,v.height)
			GUI_RefreshWindow(wname)
			GUI_WindowVisible(wname, v.visibleDefault)
		end
	end
end
--**************************************************************************************************************************************
function QM.WindowUpdate()	
	
	local WI = Settings.FFXIVMINION.qmWindow
	local W = GUI_GetWindowInfo(QM.Windows.Main.name)
	local WindowInfo = {}
	
	if (WI.width ~= W.width) then WindowInfo.width = W.width else WindowInfo.width = WI.width end
	if (WI.height ~= W.height) then WindowInfo.height = W.height else WindowInfo.height = WI.height	end
	if (WI.x ~= W.x) then WindowInfo.x = W.x else WindowInfo.x = WI.x end
	if (WI.y ~= W.y) then WindowInfo.y = W.y else WindowInfo.y = WI.y end

	if (WindowInfo ~= nil and WindowInfo ~= WI) then Settings.FFXIVMINION.qmWindow = WindowInfo end
end
--**************************************************************************************************************************************
function QM.WindowToggle(event)
	local window = string.gsub(event,"QMToggle","")
	
	if (QM.Windows[window].base ~= nil) then
		local wnd = GUI_GetWindowInfo(QM.Windows[QM.Windows[window].base].name)
		GUI_MoveWindow(QM.Windows[window].name, wnd.x+wnd.width, wnd.y)
	end
	
	GUI_WindowVisible(QM.Windows[window].name,not QM.Windows[window].visible)
	QM.Windows[window].visible = not QM.Windows[window].visible
	
	if (QM.Windows[window].onOpen ~= nil) then
		QM.ExecuteFunction(tostring(QM.Windows[window].onOpen))
	end
end
--**************************************************************************************************************************************
function QM.OnUpdateHandler( Event, ticks ) 		
	if (TimeSince(QM.WindowTick) > 10000) then
		QM.WindowTick = ticks
		QM.WindowUpdate()
	end
end
--**************************************************************************************************************************************
function QM.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" ) then
		if (string.sub(Button,1,11) == "QMQuestEdit") then
			QM.EditQuest(string.gsub(Button,"QMQuestEdit",""))
		elseif (string.sub(Button,1,12) == "QMStepRemove") then
			QM.RemoveStep(string.gsub(Button,"QMStepRemove",""))
		elseif (string.sub(Button,1,14) == "QMPreReqRemove") then
			QM.RemoveStep(string.gsub(Button,"QMPreReqRemove",""))
		elseif (string.sub(Button,1,16) == "QMTurnoverRemove") then
			QM.RemoveTurnover(string.gsub(Button,"QMTurnoverRemove",""))
		elseif (string.sub(Button,1,8) == "QMToggle") then
			QM.WindowToggle(Button)
		elseif (string.sub(Button,1,3) == "QM.") then
			QM.ExecuteFunction(Button)
		end
	end
end
--**************************************************************************************************************************************
function QM.ExecuteFunction(strFunction)
	if strFunction == nil then
		return
	end
	
	local t = QM.StringToTable(strFunction,";")
	local start = 1
	local finish = TableSize(t)
	
	for x = start,finish do
		local f = _G
		for v in t[x]:gmatch("[^%.]+") do
			f=f[v]
		end
		f()
	end
end
--**************************************************************************************************************************************
function QM.StringToTable(str, delimiter)
    local t = {}
    local search = "(.-)" .. delimiter
	local last_char = 1
	local i = 1
	str = string.gsub(str,"\r","")
	
	local index, char, data = str:find(search,1)
	while index do
		if data ~= "" then
			t[i] = data
		end
		last_char = char+1
		index, char, data = str:find(search, last_char)
		i = i + 1
	end
	
	if last_char <= #str then
		data = str:sub(last_char)
		t[i] = data
	end
	
	return t
end

RegisterEventHandler("GUI.Item", QM.HandleButtons )
RegisterEventHandler("Module.Initalize",QM.Init)
RegisterEventHandler("Gameloop.Update", QM.OnUpdateHandler)
RegisterEventHandler("GUI.Update",QM.GUIVarUpdate)

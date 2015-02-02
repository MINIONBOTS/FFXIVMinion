QM = {}
--onOpen can be added if a certain function should run when the window is opened, otherwise it should be left as nil.
--baseY is used to tell the window to position itself below the specified window.
--baseX is used to tell the window to position itself right of the specified window.
QM.Windows = {
	Main = {visible = false, name = strings[gCurrentLanguage].profileManager, visibleDefault = false, onOpen = "QM.LoadProfile",
		x = 500, y = 40, width = 250, height = 520
	},
	QuestEditor = {visible = false, name = strings[gCurrentLanguage].questEditor, visibleDefault = false,
		base = "Main", width = 250, height = 275
	},
	StepManager = {visible = false, name = strings[gCurrentLanguage].questSteps, visibleDefault = false, onOpen = "QM.LoadTaskFields",
		base = "QuestEditor", width = 250, height = 400
	},
	StepEditor = {visible = false, name = strings[gCurrentLanguage].questStepEditor, visibleDefault = false,
		base = "StepManager", width = 250, height = 400
	},
	ItemEditor = {visible = false, name = strings[gCurrentLanguage].questItemEditor, visibleDefault = false, onOpen = "QM.RefreshStepItems",
		base = "StepEditor", width = 250, height = 300
	},
	EncounterEditor = {visible = false, name = "Encounter Editor", visibleDefault = false,
		base = "Main", width = 250, height = 300
	},
	TurnInEditor = {visible = false, name = strings[gCurrentLanguage].questTurnoverEditor, visibleDefault = false, onOpen = "QM.PullTurnoverItem;QM.RefreshTurnovers",
		base = "StepManager", width = 250, height = 275
	},
	PreReqEditor = {visible = false, name = strings[gCurrentLanguage].questPreReqEditor, visibleDefault = false, onOpen = "QM.RefreshPreReqs",
		base = "QuestEditor", width = 250, height = 275
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
QM.DutyInfo = {}
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
	qQuestName = 	{ default = "", 		profile = "name" ,			cast = "string"},
	eQuestName = 	{ default = "", 		profile = "name" ,			cast = "string"},
	qQuestJob = 	{ default = "None", 	profile = "job", 			cast = "number"},
	eQuestJob = 	{ default = "None", 	profile = "job", 			cast = "number"},
	qQuestLevel = 	{ default = 1,	 		profile = "level", 			cast = "number"},
	eQuestLevel = 	{ default = 1, 			profile = "level", 			cast = "number"},
	qPreReqJob = 	{ default = "All",  	profile = "" , 				cast = "string"},
	qPreReqStep = 	{ default = 1, 			profile = "", 				cast = "number"},
	qPreReqID = 	{ default = "",	 		profile = "" , 				cast = "number"},
	qStepNum = 		{ default = "", 		profile = "" , 				cast = "number"},
	eStepNum = 		{ default = "", 		profile = "" , 				cast = "number"},
	qStepTask = 	{ default = "start",	profile = "type", 			cast = "string", onChange = "QM.LoadTaskFields"},
	eStepTask = 	{ default = "start",	profile = "type", 			cast = "string", onChange = "QM.LoadTaskFields"}, -- new
	qTaskCustom = 	{ default = "", 		profile = "", 				cast = "string"},
	qTaskCommandString = { default = "", 	profile = "commandstring", 	cast = "string"},
	eTaskCommandString = { default = "", 	profile = "commandstring", 	cast = "string"},
	qTaskItemSelector =  { default = 1, 	profile = "", 				cast = "number", onChange = "QM.PullTaskAddItem"},
	eTaskItemSelector =  { default = 1, 	profile = "", 				cast = "number", onChange = "QM.PullTaskEditItem"},
	qTaskItemID = 	{ default = 0, 			profile = "itemid", 		cast = "number"},
	eTaskItemID = 	{ default = 0, 			profile = "itemid", 		cast = "number"},
	qTaskMesh = 	{ default = "", 		profile = "meshname", 		cast = "string"},
	eTaskMesh = 	{ default = "", 		profile = "meshname", 		cast = "string"},
	qTaskMap = 		{ default = "", 		profile = "mapid", 			cast = "number"},
	eTaskMap = 		{ default = "", 		profile = "mapid", 			cast = "number"},
	qTaskNPC = 		{ default = "", 		profile = "id", 			cast = "number"},
	eTaskNPC = 		{ default = "", 		profile = "id", 			cast = "number"},
	qTaskAction = 	{ default = "",			profile = "actionid",		cast = "number"},
	eTaskAction = 	{ default = "",			profile = "actionid",		cast = "number"},
	qTaskQuestID = 	{ default = 0, 			profile = "questid", 		cast = "number"},
	eTaskQuestID = 	{ default = 0, 			profile = "questid", 		cast = "number"},
	qTaskKillTarget = 	{ default = "",		profile = "id", 			cast = "number"},
	eTaskKillTarget = 	{ default = "",		profile = "id", 			cast = "number"},
	qTaskKillPriorities = 	{ default = "",	profile = "ids", 			cast = "string"},
	eTaskKillPriorities = 	{ default = "",	profile = "ids", 			cast = "string"},
	qTaskKillCount = 	{ default = 0, 		profile = "killcount", 		cast = "number"},
	eTaskKillCount = 	{ default = 0, 		profile = "killcount", 		cast = "number"},
	qTaskDelay = 		{ default = 0, 		profile = "delay", 			cast = "number"},
	eTaskDelay = 		{ default = 0, 		profile = "delay", 			cast = "number"},
	qTaskRewardSlot = 	{ default = 0, 		profile = "itemrewardslot", cast = "number"},--new
	eTaskRewardSlot = 	{ default = 0, 		profile = "itemrewardslot", cast = "number"},--new
	
	qTaskUseRewardTable = { default = "0",	profile = "userewardtable", 	cast = "boolean"},--new
	eTaskUseRewardTable = { default = "0",	profile = "userewardtable", 	cast = "boolean"},--new
	
	qTaskConvoIndex = 	{ default = 0,		profile = "conversationindex", cast = "number"},
	eTaskConvoIndex = 	{ default = 0,		profile = "conversationindex", cast = "number"},
	qTaskItemJobReq = 	{ default = -1, 	profile = "", 				cast = "number"},
	qTaskItemAmount = 	{ default = 1, 		profile = "buyamount", 		cast = "number"},
	eTaskItemAmount = 	{ default = 1, 		profile = "buyamount", 		cast = "number"},	
	qTaskRestartStep = 	{ default = 0, 		profile = "restartatstep", 	cast = "number"}, --new
	eTaskRestartStep = 	{ default = 0, 		profile = "restartatstep", 	cast = "number"},	--new
	qTaskFailTime = 	{ default = 0, 		profile = "failtime", 		cast = "number"}, --new
	eTaskFailTime = 	{ default = 0, 		profile = "failtime", 		cast = "number"},	--new
	
	qTurnoverStep = 	{ default = 1, 		profile = "" , 				cast = "number"},
	qTurnoverID = 		{ default = "",		profile = "itemturninid", 	cast = "number"},
	qTurnoverSlot = 	{default = 1, 		profile = "", 				cast = "number", onChange = "QM.PullTurnoverItem"},
	
	qTaskUsePos = 	{ default = "0",		profile = "usepos", 		cast = "boolean"},--new
	qTaskUsePosX = 	{ default = 0, 			profile = "useposx", 		cast = "number"},--new
	qTaskUsePosY = 	{ default = 0, 			profile = "useposy", 		cast = "number"},--new
	qTaskUsePosZ = 	{ default = 0, 			profile = "useposz", 		cast = "number"},--new
	eTaskUsePos = 	{ default = "0",		profile = "usepos", 		cast = "boolean", subtable = true},--new
	eTaskUsePosX = 	{ default = 0, 			profile = "useposx", 		cast = "number", subtable = "usepos", subtableDef = "x"},--new
	eTaskUsePosY = 	{ default = 0, 			profile = "useposy", 		cast = "number", subtable = "usepos", subtableDef = "y"},--new
	eTaskUsePosZ = 	{ default = 0, 			profile = "useposz", 		cast = "number", subtable = "usepos", subtableDef = "z"},--new
	
	qTaskDisableFlagCheck = { default = "0",	profile = "disableflagcheck", 	cast = "boolean"},--new
	eTaskDisableFlagCheck = { default = "0",	profile = "disableflagcheck", 	cast = "boolean"},--new
	qTaskDisableAvoid = 	{ default = "0",	profile = "disableavoid", 	cast = "boolean"},--new
	eTaskDisableAvoid = 	{ default = "0",	profile = "disableavoid", 	cast = "boolean"},--new
	qTaskDisableCountCheck = { default = "0",	profile = "disablecountcheck", 	cast = "boolean"},--new
	eTaskDisableCountCheck = { default = "0",	profile = "disablecountcheck", 	cast = "boolean"},--new
	qTaskDisableTargetCheck = { default = "0",	profile = "disabletargetcheck", 	cast = "boolean"},--new
	eTaskDisableTargetCheck = { default = "0",	profile = "disabletargetcheck", 	cast = "boolean"},--new
	
	qTaskUseRewardTable = { default = "0",		profile = "userewardtable", 	cast = "boolean"},--new
	eTaskUseRewardTable = { default = "0",		profile = "userewardtable", 	cast = "boolean"},--new
	
	qTaskIndex = { default = 1,	profile = "index" , 	cast = "number"},--new
	eTaskIndex = { default = 1,	profile = "index" , 	cast = "number"},--new
	
	--new
	qTaskRewardSlotDefault = { default = "", 	profile = "rslotDEFAULT", 	cast = "number"},
	qTaskRewardSlotACN = { default = "", 	profile = "rslotARCANIST", 	cast = "number"},
	qTaskRewardSlotSMN = { default = "", 	profile = "rslotSUMMONER", 	cast = "number"},
	qTaskRewardSlotSCH = { default = "", 	profile = "rslotSCHOLAR", 	cast = "number"},
	qTaskRewardSlotTHM = { default = "", 	profile = "rslotTHAUMATURGE", 	cast = "number"},
	qTaskRewardSlotBLM = { default = "", 	profile = "rslotBLACKMAGE", 	cast = "number"},
	qTaskRewardSlotCNJ = { default = "", 	profile = "rslotCONJURER", 	cast = "number"},
	qTaskRewardSlotWHM = { default = "", 	profile = "rslotWHITEMAGE", 	cast = "number"},
	qTaskRewardSlotARC = { default = "", 	profile = "rslotARCHER", 	cast = "number"},
	qTaskRewardSlotBRD = { default = "", 	profile = "rslotBARD", 	cast = "number"},
	qTaskRewardSlotROG = { default = "", 	profile = "rslotROGUE", 	cast = "number"},
	qTaskRewardSlotNIN = { default = "", 	profile = "rslotNINJA", 	cast = "number"},
	qTaskRewardSlotGLD = { default = "", 	profile = "rslotGLADIATOR", 	cast = "number"},
	qTaskRewardSlotPLD = { default = "", 	profile = "rslotPALADIN", 	cast = "number"},
	qTaskRewardSlotMRD = { default = "", 	profile = "rslotMARAUDER", 	cast = "number"},
	qTaskRewardSlotWAR = { default = "", 	profile = "rslotWARRIOR", 	cast = "number"},
	qTaskRewardSlotLNC = { default = "", 	profile = "rslotLANCER", 	cast = "number"},
	qTaskRewardSlotDRG = { default = "", 	profile = "rslotDRAGOON", 	cast = "number"},
	qTaskRewardSlotPUG = { default = "", 	profile = "rslotPUGILIST", 	cast = "number"},
	qTaskRewardSlotMNK = { default = "", 	profile = "rslotMONK", 	cast = "number"},
	
	eTaskRewardSlotDefault = { default = "", 	profile = "slotEditDEFAULT", 	cast = "number"},
	eTaskRewardSlotACN = { default = "", 	profile = "slotEditARCANIST", 	cast = "number"},
	eTaskRewardSlotSMN = { default = "", 	profile = "slotEditSUMMONER", 	cast = "number"},
	eTaskRewardSlotSCH = { default = "", 	profile = "slotEditSCHOLAR", 	cast = "number"},
	eTaskRewardSlotTHM = { default = "", 	profile = "slotEditTHAUMATURGE", 	cast = "number"},
	eTaskRewardSlotBLM = { default = "", 	profile = "slotEditBLACKMAGE", 	cast = "number"},
	eTaskRewardSlotCNJ = { default = "", 	profile = "slotEditCONJURER", 	cast = "number"},
	eTaskRewardSlotWHM = { default = "", 	profile = "slotEditWHITEMAGE", 	cast = "number"},
	eTaskRewardSlotARC = { default = "", 	profile = "slotEditARCHER", 	cast = "number"},
	eTaskRewardSlotBRD = { default = "", 	profile = "slotEditBARD", 	cast = "number"},
	eTaskRewardSlotROG = { default = "", 	profile = "slotEditROGUE", 	cast = "number"},
	eTaskRewardSlotNIN = { default = "", 	profile = "slotEditNINJA", 	cast = "number"},
	eTaskRewardSlotGLD = { default = "", 	profile = "slotEditGLADIATOR", 	cast = "number"},
	eTaskRewardSlotPLD = { default = "", 	profile = "slotEditPALADIN", 	cast = "number"},
	eTaskRewardSlotMRD = { default = "", 	profile = "slotEditMARAUDER", 	cast = "number"},
	eTaskRewardSlotWAR = { default = "", 	profile = "slotEditWARRIOR", 	cast = "number"},
	eTaskRewardSlotLNC = { default = "", 	profile = "slotEditLANCER", 	cast = "number"},
	eTaskRewardSlotDRG = { default = "", 	profile = "slotEditDRAGOON", 	cast = "number"},
	eTaskRewardSlotPUG = { default = "", 	profile = "slotEditPUGILIST", 	cast = "number"},
	eTaskRewardSlotMNK = { default = "", 	profile = "slotEditMONK", 	cast = "number"},
	--new
	
	eEncounterNum = 	{ default = "", 		profile = "" , 				cast = "number"},
	eEncounterTask = 	{ default = "kill",		profile = "taskFunction", 	cast = "string", onChange = "QM.LoadEncounterFields"}, -- new
	eEncounterWaitTime =	{ default = "1000", profile = "waitTime",		cast = "number"},
	eEncounterFailTime =	{ default = "1000", profile = "failTime",		cast = "number"},
	eEncounterRadius = 	{ default = "30", 		profile = "radius", 		cast = "number"},
}

QM.Strings = {
	Meshes = 
		function()
			local meshlist = "none"
			local meshfilelist = dirlist(ml_mesh_mgr.navmeshfilepath,".*obj")
			if ( TableSize(meshfilelist) > 0) then
				local i,meshname = next ( meshfilelist)
				while i and meshname do
					meshname = string.gsub(meshname, ".obj", "")
					--table.insert(mm.meshfiles, meshname) not needed anymore with new ml_mesh_mgr.lua
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
	QuestTasks = "start,accept,nav,interact,kill,dutykill,textcommand,useitem,useaction,vendor,finish,complete",
	DutyTasks = "kill,loot,interact",
	QuestJobs = "None,ARCANIST,ARCHER,BARD,BLACKMAGE,BOTANIST,CONJURER,DRAGOON,FISHER,GLADIATOR,LANCER,MARAUDER,MINER,MONK,NINJA,PALADIN,PUGILIST,ROGUE,SCHOLAR,SUMMONER,THAUMATURGE,WARRIOR,WHITEMAGE",
	PreReqJobs = "All,ARCANIST,ARCHER,BARD,BLACKMAGE,BOTANIST,CONJURER,DRAGOON,FISHER,GLADIATOR,LANCER,MARAUDER,MINER,MONK,NINJA,PALADIN,PUGILIST,ROGUE,SCHOLAR,SUMMONER,THAUMATURGE,WARRIOR,WHITEMAGE",
}

QM.EncounterTasks = {
	["ffxiv_duty_kill_task.Create"] = "kill",
	["ffxiv_task_interact.Create"] = "interact",
	["ffxiv_task_loot.Create"] = "loot",
}

QM.Builds = {
	Main = {
		{5, "GUI_NewComboBox",QM.Windows.Main.name,strings[gCurrentLanguage].profileType,		"qProfileType",	strings[gCurrentLanguage].details, strings[gCurrentLanguage].dutyMode..","..strings[gCurrentLanguage].questMode},
		{5, "GUI_NewComboBox",QM.Windows.Main.name,strings[gCurrentLanguage].existingProfile, "qProfileName",	strings[gCurrentLanguage].details, "None"},
		{4, "GUI_NewField", 	QM.Windows.Main.name,strings[gCurrentLanguage].newProfileName,	"qProfileNew",	strings[gCurrentLanguage].details},
		{4, "GUI_NewButton", 	QM.Windows.Main.name,strings[gCurrentLanguage].createProfile, 	"QM.CreateProfile", strings[gCurrentLanguage].details},
		{3, "GUI_NewButton", 	QM.Windows.Main.name,strings[gCurrentLanguage].saveProfile, 	"QM.SaveProfile"},
	},
	LoadTypeOptions = {
		{QM.Windows.Main.name, strings[gCurrentLanguage].newEncounter},
		{QM.Windows.Main.name, strings[gCurrentLanguage].newQuest},
		{QM.Windows.Main.name, "Encounters"},
		{QM.Windows.Main.name, strings[gCurrentLanguage].quests},
	},
	Duty = {
		{4, "GUI_NewField",		QM.Windows.Main.name,"MapID",			"qEncounterSettingMapID",			"Profile Details"},
		{4, "GUI_NewCheckbox",	QM.Windows.Main.name,"Independent",		"qEncounterSettingIndependent",		"Profile Details"},
		{4, "GUI_NewNumeric",	QM.Windows.Main.name,"StartingIndex",	"qEncounterSettingEncounterIndex",	"Profile Details"},
		{5, "GUI_NewComboBox",	QM.Windows.Main.name,"Task",									"qEncounterTask",	strings[gCurrentLanguage].newEncounter, QM.Strings.DutyTasks},
		{4, "GUI_NewButton", 	QM.Windows.Main.name,strings[gCurrentLanguage].addEncounter, 	"QM.AddEncounter", 	strings[gCurrentLanguage].newEncounter},
	},
	Quest = {
		{4, "GUI_NewField",		QM.Windows.Main.name,strings[gCurrentLanguage].questID,			"qQuestID",		strings[gCurrentLanguage].newQuest},
		{4, "GUI_NewField",		QM.Windows.Main.name,"Quest Name",			"qQuestName",		strings[gCurrentLanguage].newQuest},
		{4, "GUI_NewButton",	QM.Windows.Main.name,strings[gCurrentLanguage].questPullID, 	"QM.PullQuest",	strings[gCurrentLanguage].newQuest},
		{5, "GUI_NewComboBox",	QM.Windows.Main.name,strings[gCurrentLanguage].questJob,		"qQuestJob",	strings[gCurrentLanguage].newQuest, QM.Strings.QuestJobs},
		{4, "GUI_NewField",		QM.Windows.Main.name,strings[gCurrentLanguage].questLevel,		"qQuestLevel",	strings[gCurrentLanguage].newQuest},
		{4, "GUI_NewButton",	QM.Windows.Main.name,strings[gCurrentLanguage].questAddQuest, 	"QM.AddQuest",  strings[gCurrentLanguage].newQuest},
	},
	QuestEditor = {
		{4, "GUI_NewField",		QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questID,		"eQuestID",		 strings[gCurrentLanguage].details},
		{4, "GUI_NewField",		QM.Windows.QuestEditor.name,"Quest Name",		"eQuestName",	 strings[gCurrentLanguage].details},
		{4, "GUI_NewButton",	QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questPullID, 	"QM.PullQuest",	 strings[gCurrentLanguage].details},
		{5, "GUI_NewComboBox",	QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questJob,		"eQuestJob",	 strings[gCurrentLanguage].details, QM.Strings.QuestJobs},
		{4, "GUI_NewField",		QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questLevel,	"eQuestLevel",	 strings[gCurrentLanguage].details},
		{3, "GUI_NewButton",	QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questDelete,	"QM.DeleteQuest"},
		{3, "GUI_NewButton",	QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questSave, 	"QM.ModifyQuest"},
		{3, "GUI_NewButton",	QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questEditSteps, 	"QMToggleStepManager"},
		{3, "GUI_NewButton",	QM.Windows.QuestEditor.name,strings[gCurrentLanguage].questEditPreReqs,	"QMTogglePreReqEditor"},
	},
	PreReqEditor = {
		{5, "GUI_NewComboBox",	QM.Windows.PreReqEditor.name,strings[gCurrentLanguage].prereqJob,	"qPreReqJob",	strings[gCurrentLanguage].newQuestPreReq, QM.Strings.PreReqJobs},		
		{4, "GUI_NewField",		QM.Windows.PreReqEditor.name,strings[gCurrentLanguage].prereqStep,"qPreReqStep", 	strings[gCurrentLanguage].newQuestPreReq},
		{4, "GUI_NewField",		QM.Windows.PreReqEditor.name,strings[gCurrentLanguage].prereqID,	"qPreReqID",  	strings[gCurrentLanguage].newQuestPreReq},
		{3, "GUI_NewButton", 	QM.Windows.PreReqEditor.name,strings[gCurrentLanguage].prereqClear,	"QM.ClearPreReqs"},
		{3, "GUI_NewButton",	QM.Windows.PreReqEditor.name,strings[gCurrentLanguage].questAddPreReq,			"QM.AddPreReq"},
	},
	StepManager = {
		{4, "GUI_NewField",		QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",		strings[gCurrentLanguage].newQuestStep},
		{5, "GUI_NewComboBox",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,		"qStepTask",	strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
		{3, "GUI_NewButton", 	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepClear, 	"QM.ClearSteps"},
		{3, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questEditTurnovers,	"QMToggleTurnInEditor"},
	},
	StepEditor = {
		{4, "GUI_NewField",		QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepCurrent,	"eStepNum",		strings[gCurrentLanguage].editQuestStep},
		{5, "GUI_NewComboBox",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,		"eStepTask",	strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
		{3, "GUI_NewButton", 	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questStepSave, 	"QM.SaveStep"},
		{3, "GUI_NewButton", 	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questStepDelete, 	"QM.RemoveStep"},
		{3, "GUI_NewButton", 	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questDown, 	"QM.StepPriorityDown"},
		{3, "GUI_NewButton", 	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questUp, 		"QM.StepPriorityUp"},
	},
	EncounterEditor = {
		{4, "GUI_NewField",		QM.Windows.EncounterEditor.name,strings[gCurrentLanguage].stepCurrent,		"eEncounterNum",	"Edit Encounter Step"},
		{5, "GUI_NewComboBox",	QM.Windows.EncounterEditor.name,strings[gCurrentLanguage].stepTask,		"eEncounterTask",		"Edit Encounter Step",	QM.Strings.DutyTasks},
		{3, "GUI_NewButton", 	QM.Windows.EncounterEditor.name,strings[gCurrentLanguage].questStepSave, 	"QM.SaveEncounter"},
		{3, "GUI_NewButton", 	QM.Windows.EncounterEditor.name,strings[gCurrentLanguage].questStepDelete, 	"QM.RemoveEncounter"},
		{3, "GUI_NewButton", 	QM.Windows.EncounterEditor.name,strings[gCurrentLanguage].questDown, 	"QM.EncounterPriorityDown"},
		{3, "GUI_NewButton", 	QM.Windows.EncounterEditor.name,strings[gCurrentLanguage].questUp, 		"QM.EncounterPriorityUp"},
	},
	ItemEditor = {
		{5, "GUI_NewComboBox",	QM.Windows.ItemEditor.name,strings[gCurrentLanguage].questJob,			"qTaskItemJobReq",	strings[gCurrentLanguage].newItem, QM.Strings.QuestJobs},
		{4, "GUI_NewField",		QM.Windows.ItemEditor.name,strings[gCurrentLanguage].stepItemID,		"qTaskItemID",		strings[gCurrentLanguage].newItem},
		{3, "GUI_NewButton", 	QM.Windows.ItemEditor.name,strings[gCurrentLanguage].questClearItems, 	"QM.ClearStepItems"},
		{3, "GUI_NewButton",	QM.Windows.ItemEditor.name,strings[gCurrentLanguage].questAddItem, 	"QM.AddStepItem"},
	},
	TurnInEditor = {
		{4, "GUI_NewField",	QM.Windows.TurnInEditor.name,strings[gCurrentLanguage].turnoverStep,"qTurnoverStep",strings[gCurrentLanguage].newQuestTurnover},
		{4, "GUI_NewField",	QM.Windows.TurnInEditor.name,strings[gCurrentLanguage].turnoverID,	"qTurnoverID",	strings[gCurrentLanguage].newQuestTurnover},
		{4, "GUI_NewNumeric",	QM.Windows.TurnInEditor.name,strings[gCurrentLanguage].turnoverSlot,"qTurnoverSlot",strings[gCurrentLanguage].newQuestTurnover},
		{3, "GUI_NewButton", 	QM.Windows.TurnInEditor.name,strings[gCurrentLanguage].turnoverClear, "QM.ClearTurnovers"},
		{3, "GUI_NewButton",	QM.Windows.TurnInEditor.name,strings[gCurrentLanguage].questAddTurnover, "QM.AddTurnover"},
	},
	QuestTasks = {
		["start"] = {
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Index","qTaskIndex",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["accept"] = {
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Index","qTaskIndex",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepQuestID,	"qTaskQuestID",	strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["nav"] = {
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Index","qTaskIndex",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,	"qTaskMap",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["kill"] = {
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Index","qTaskIndex",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,		"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,	"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,	"qTaskKillTarget",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepKillCount,  "qTaskKillCount",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["dutykill"] = {
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Index","qTaskIndex",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,		"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,	"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,	"qTaskKillPriorities",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["interact"] = {
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Index","qTaskIndex",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["textcommand"] = {
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Index","qTaskIndex",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCommandString,"qTaskCommandString",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["useitem"] = {
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Index","qTaskIndex",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewCheckbox",QM.Windows.StepManager.name,"AOE Item","qTaskUsePos",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"X","qTaskUsePosX",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Y","qTaskUsePosY",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Z","qTaskUsePosZ",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewNumeric",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepItemSelector,"qTaskItemSelector",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepItemID,"qTaskItemID", strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["useaction"] = {
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Index","qTaskIndex",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepAction,"qTaskAction", strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["vendor"] = {
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Index","qTaskIndex",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].convoIndex,"qTaskConvoIndex", strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepItemAmount,"qTaskItemAmount",	strings[gCurrentLanguage].newQuestStep},			
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["finish"] = {
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Index","qTaskIndex",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepQuestID,	"qTaskQuestID",	strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepReward,"qTaskRewardSlot",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
		},
		["complete"] = {
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepCurrent,	"qStepNum",	strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTask,	"qStepTask",strings[gCurrentLanguage].newQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,"Index","qTaskIndex",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMap,"qTaskMap",strings[gCurrentLanguage].newQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepManager.name,strings[gCurrentLanguage].stepMesh,"qTaskMesh",strings[gCurrentLanguage].newQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepTarget,"qTaskNPC",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepReward,"qTaskRewardSlot",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepManager.name,strings[gCurrentLanguage].stepDelay,"qTaskDelay",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questPullValues, "QM.LoadAddCurrentValues",strings[gCurrentLanguage].newQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepManager.name,strings[gCurrentLanguage].questAddStep, "QM.AddStep",strings[gCurrentLanguage].newQuestStep},
			
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"Default","qTaskRewardSlotDefault","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"ARCANIST","qTaskRewardSlotACN","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"SUMMONER","qTaskRewardSlotSMN","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"SCHOLAR","qTaskRewardSlotSCH","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"THAUMATURGE","qTaskRewardSlotTHM","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"BLACKMAGE","qTaskRewardSlotBLM","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"CONJURER","qTaskRewardSlotCNJ","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"WHITEMAGE","qTaskRewardSlotWHM","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"ARCHER","qTaskRewardSlotARC","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"BARD","qTaskRewardSlotBRD","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"ROGUE","qTaskRewardSlotROG","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"NINJA","qTaskRewardSlotNIN","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"GLADIATOR","qTaskRewardSlotGLD","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"PALADIN","qTaskRewardSlotPLD","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"MARAUDER","qTaskRewardSlotMRD","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"WARRIOR","qTaskRewardSlotWAR","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"LANCER","qTaskRewardSlotLNC","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"DRAGOON","qTaskRewardSlotDRG","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"PUGILIST","qTaskRewardSlotPUG","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepManager.name,"MONK","qTaskRewardSlotMNK","Reward Table"},
		},	
	},
	QuestTasksEdit = {
		["start"] = {
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",	strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["accept"] = {
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepQuestID,	"eTaskQuestID",	strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",	strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["nav"] = {
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,	"eTaskMap",	strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["kill"] = {
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,		"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,	"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,	"eTaskKillTarget",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepKillCount,  "eTaskKillCount",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["dutykill"] = {
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,		"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,	"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,	"eTaskKillPriorities",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["interact"] = {
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["textcommand"] = {
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepCommandString,"eTaskCommandString",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["useitem"] = {
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewCheckbox",QM.Windows.StepEditor.name,"AOE Item","eTaskUsePos",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,"X","eTaskUsePosX",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,"Y","eTaskUsePosY",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,"Z","eTaskUsePosZ",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepItemSelector,"eTaskItemSelector",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepItemID,"eTaskItemID", strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["useaction"] = {
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepAction,"eTaskAction", strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["vendor"] = {
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].convoIndex,"eTaskConvoIndex", strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepItemAmount,"eTaskItemAmount",	strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepDelay,"eTaskDelay",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questItemEditor, "QMToggleItemEditor",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},
		["finish"] = {
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepQuestID,	"eTaskQuestID",	strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepReward,"eTaskRewardSlot",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
		},	
		["complete"] = {
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTask,	"eStepTask",strings[gCurrentLanguage].editQuestStep,	QM.Strings.QuestTasks},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewCheckbox",QM.Windows.StepEditor.name,"Reward Table","eTaskUseRewardTable",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepReward,"eTaskRewardSlot",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
			
			--All,ARCANIST,ARCHER,BARD,BLACKMAGE,CONJURER,DRAGOON,GLADIATOR,LANCER,MARAUDER,MONK,PALADIN,PUGILIST,SCHOLAR,SUMMONER,THAUMATURGE,WARRIOR,WHITEMAGE
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"Default","eTaskRewardSlotDefault","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"ARCANIST","eTaskRewardSlotACN","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"SUMMONER","eTaskRewardSlotSMN","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"SCHOLAR","eTaskRewardSlotSCH","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"THAUMATURGE","eTaskRewardSlotTHM","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"BLACKMAGE","eTaskRewardSlotBLM","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"CONJURER","eTaskRewardSlotCNJ","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"WHITEMAGE","eTaskRewardSlotWHM","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"ARCHER","eTaskRewardSlotARC","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"BARD","eTaskRewardSlotBRD","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"ROGUE","eTaskRewardSlotROG","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"NINJA","eTaskRewardSlotNIN","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"GLADIATOR","eTaskRewardSlotGLD","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"PALADIN","eTaskRewardSlotPLD","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"MARAUDER","eTaskRewardSlotMRD","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"WARRIOR","eTaskRewardSlotWAR","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"LANCER","eTaskRewardSlotLNC","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"DRAGOON","eTaskRewardSlotDRG","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"PUGILIST","eTaskRewardSlotPUG","Reward Table"},
			{4, "GUI_NewNumeric",	QM.Windows.StepEditor.name,"MONK","eTaskRewardSlotMNK","Reward Table"},
		},	
	},
	DutyTasksEdit = {
		["kill"] = {
			{4, "GUI_NewField",		QM.Windows.EncounterEditor.name,strings[gCurrentLanguage].stepCurrent,		"eEncounterNum",	"Edit Encounter Step"},
			{5, "GUI_NewComboBox",	QM.Windows.EncounterEditor.name,"Task","eEncounterTask","Edit Encounter Step",	QM.Strings.DutyTasks},
			{4, "GUI_NewField",		QM.Windows.EncounterEditor.name,"Wait Time",	"eEncounterWaitTime",	"Edit Encounter Step"},
			{4, "GUI_NewField",		QM.Windows.EncounterEditor.name,"Fail Time",	"eEncounterFailTime",	"Edit Encounter Step"},
			{4, "GUI_NewNumeric",	QM.Windows.EncounterEditor.name,"Radius",		"eEncounterRadius",		"Edit Encounter Step"},
			--[[
			{4, "GUI_NewField",		QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",	strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",		QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
			--]]
		},
		["interact"] = {
			{4, "GUI_NewField",		QM.Windows.EncounterEditor.name,strings[gCurrentLanguage].stepCurrent,		"eEncounterNum",	"Edit Encounter Step"},
			{5, "GUI_NewComboBox",	QM.Windows.EncounterEditor.name,"Task","eEncounterTask","Edit Encounter Step",	QM.Strings.DutyTasks},
			{4, "GUI_NewField",		QM.Windows.EncounterEditor.name,"Wait Time",	"eEncounterWaitTime",	"Edit Encounter Step"},
			{4, "GUI_NewField",		QM.Windows.EncounterEditor.name,"Fail Time",	"eEncounterFailTime",	"Edit Encounter Step"},
			{4, "GUI_NewNumeric",	QM.Windows.EncounterEditor.name,"Radius",		"eEncounterRadius",		"Edit Encounter Step"},
			--[[
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepQuestID,	"eTaskQuestID",	strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,"eTaskMap",	strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepTarget,"eTaskNPC",strings[gCurrentLanguage].editQuestStep},
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
			--]]
		},
		["loot"] = {
			{4, "GUI_NewField",		QM.Windows.EncounterEditor.name,strings[gCurrentLanguage].stepCurrent,		"eEncounterNum",	"Edit Encounter Step"},
			{5, "GUI_NewComboBox",	QM.Windows.EncounterEditor.name,"Task","eEncounterTask","Edit Encounter Step",	QM.Strings.DutyTasks},
			{4, "GUI_NewField",		QM.Windows.EncounterEditor.name,"Wait Time",	"eEncounterWaitTime",	"Edit Encounter Step"},
			{4, "GUI_NewField",		QM.Windows.EncounterEditor.name,"Fail Time",	"eEncounterFailTime",	"Edit Encounter Step"},
			{4, "GUI_NewNumeric",	QM.Windows.EncounterEditor.name,"Radius",		"eEncounterRadius",		"Edit Encounter Step"},
			--[[
			{4, "GUI_NewField",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMap,	"eTaskMap",	strings[gCurrentLanguage].editQuestStep},
			{5, "GUI_NewComboBox",QM.Windows.StepEditor.name,strings[gCurrentLanguage].stepMesh,"eTaskMesh",strings[gCurrentLanguage].editQuestStep, QM.Strings.Meshes },
			{4, "GUI_NewButton",	QM.Windows.StepEditor.name,strings[gCurrentLanguage].questPullValues, "QM.LoadEditCurrentValues",strings[gCurrentLanguage].editQuestStep},
			--]]
		},
	},
}

function QM.Init()

	if (Settings.FFXIVMINION.qmWindow == nil or Settings.FFXIVMINION.qmWindow == {}) then 
		local windowInfo = {} 
		windowInfo.width = 250
		windowInfo.height = 300
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
	
	--Pull starting window fields for whichever type is selected.
	QM.LoadTypeOptions()
end
--**************************************************************************************************************************************
function QM.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		local var = QM.Variables[tostring(k)]
		if (var ~= nil) then
			SafeSetVar(tostring(k),v)
			if (var.onChange ~= nil) then
				QM.ExecuteFunction(var.onChange)
			end
		end
	end
	
	for k,v in pairs(QM.Windows) do
		GUI_RefreshWindow(v.name)
	end
end
--**************************************************************************************************************************************
function QM.LoadProfile()
	
	local info = {}
	
	if (qProfileName == "" or qProfileName == nil) then
		return
	end
	
	if (qProfileType == "Duty") then
		info = persistence.load(QM.DutyPath..qProfileName..".info")
		if (ValidTable(info) and ValidTable(info.Encounters)) then
			QM.DutyInfo = info
			QM.Encounters = info.Encounters
		else
			QM.DutyInfo = {}
			QM.Encounters = {}
		end
		
		QM.RefreshDutyInfo()
		QM.RefreshEncounters()
	else
		info = persistence.load(QM.QuestPath..qProfileName..".info")
		if (ValidTable(info) and ValidTable(info.quests)) then
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
	
	GUI_WindowVisible(QM.Windows.ItemEditor.name,false)
	GUI_WindowVisible(QM.Windows.StepEditor.name,false)
	GUI_WindowVisible(QM.Windows.StepManager.name,false)
	GUI_WindowVisible(QM.Windows.QuestEditor.name,false)
end
--**************************************************************************************************************************************
function QM.AddQuest()
	local quest = {}
	local k = tonumber(qQuestID)
	quest.steps = {}
	if (qQuestJob ~= "None") then quest.job = tonumber(FFXIV.JOBS[qQuestJob]) end
	
	if (qQuestName == "") then
		for id,data in pairs(Quest:GetQuestList()) do
			if (id == k) then
				quest.name = data.name
				found = true
			end
			if (found) then
				break
			end
		end
	else
		quest.name = qQuestName
	end
	
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
	
	local found = false
	for id,data in pairs(Quest:GetQuestList()) do
		if (id == qQuestID) then
			qQuestName = data.name
			found = true
		end
		if (found) then
			break
		end
	end
	
	Settings.FFXIVMINION.qQuestID = qQuestID
	Settings.FFXIVMINION.qQuestName = qQuestName
end
--**************************************************************************************************************************************
function QM.EditQuest(id)
	local id = tonumber(id)
    local wnd = GUI_GetWindowInfo(QM.Windows.Main.name)	
    
	GUI_MoveWindow( QM.Windows.QuestEditor.name, wnd.x+wnd.width,wnd.y)

    local quest = QM.Quests[id]
	eQuestID = id
	local jobNum = (quest.job ~= nil and quest.job) or 0
	if (jobNum == 0) then
		eQuestJob = QM.Variables.eQuestJob.default
	else
		local varName = nil
		for name,id in pairs(FFXIV.JOBS) do
			if (id == jobNum) then
				varName = name
			end
			if (varName ~= nil) then
				break
			end
		end
		eQuestJob = varName
	end
	eQuestLevel = quest.level
	
	if (not IsNullString(quest.name)) then
		eQuestName = quest.name
	else
		for id,data in pairs(Quest:GetQuestList()) do
			if (id == eQuestID) then
				eQuestName = data.name
				found = true
			end
			if (found) then
				break
			end
		end
	end
	
	Settings.FFXIVMINION.eQuestID = eQuestID
	Settings.FFXIVMINION.eQuestJob = eQuestJob
	Settings.FFXIVMINION.eQuestLevel = eQuestLevel
	Settings.FFXIVMINION.eQuestName = eQuestName
	
	GUI_WindowVisible(QM.Windows.QuestEditor.name,true)
end
--**************************************************************************************************************************************
function QM.ModifyQuest()
	local k = tonumber(eQuestID)
	local quest = QM.Quests[k]
	
	if (eQuestJob ~= "None") then quest.job = tonumber(FFXIV.JOBS[eQuestJob]) end
	quest.level = tonumber(eQuestLevel)
	quest.name = eQuestName
	
	QM.Quests[k] = quest
	QM.LastQuest = k

	QM.RefreshQuests()
	
	GUI_WindowVisible(QM.Windows.ItemEditor.name,false)
	GUI_WindowVisible(QM.Windows.StepEditor.name,false)
	GUI_WindowVisible(QM.Windows.StepManager.name,false)
end
--**************************************************************************************************************************************
function QM.DeleteQuest()
	local k = tonumber(eQuestID)
	QM.Quests[k] = nil
	
	QM.RefreshQuests()
end
--**************************************************************************************************************************************
function QM.RefreshQuests()
	GUI_DeleteGroup(QM.Windows.Main.name,strings[gCurrentLanguage].quests)
	if (TableSize(QM.Quests) > 0) then
		for k,v in spairs(QM.Quests) do
			--Check the quest list to see if we have it, tack on the quest name if we do.
			local questData = ffxiv_quest_data[k]
			if (questData) then
				local nameString = tostring(k).." ["..questData.name[gCurrentLanguage].."]" or questData.name.us
				GUI_NewButton(QM.Windows.Main.name, nameString, "QMQuestEdit"..tostring(k), strings[gCurrentLanguage].quests)
			else
				GUI_NewButton(QM.Windows.Main.name, tostring(k), "QMQuestEdit"..tostring(k), strings[gCurrentLanguage].quests)
			end
		end
		GUI_UnFoldGroup(QM.Windows.Main.name,strings[gCurrentLanguage].quests)
	end
	
	GUI_SizeWindow(QM.Windows.Main.name,Settings.FFXIVMINION.qmWindow.width,Settings.FFXIVMINION.qmWindow.height)
	GUI_RefreshWindow(QM.Windows.Main.name)
end
--**************************************************************************************************************************************
function QM.AddEncounter()
	local newEncounterIndex = TableSize(QM.Encounters) + 1
	QM.Encounters[newEncounterIndex] = { name = qEncounterName }
	QM.RefreshEncounters()
end
--**************************************************************************************************************************************
function QM.RefreshDutyInfo()
	local info = QM.DutyInfo
	
	qEncounterSettingMapID = info.MapID
	if (info.Independent) then
		qEncounterSettingIndependent = "1"
	else
		qEncounterSettingIndependent = "0"
	end
	qEncounterSettingEncounterIndex = info.EncounterIndex
end
--**************************************************************************************************************************************
function QM.RefreshEncounters()		
	GUI_DeleteGroup(QM.Windows.Main.name,strings[gCurrentLanguage].dutyEncounters)
	if (TableSize(QM.Encounters) > 0) then
		for k,v in spairs(QM.Encounters) do
			GUI_NewButton(QM.Windows.Main.name, tostring(k).."("..v.taskFunction..")", "QMEncounterEdit"..tostring(k), strings[gCurrentLanguage].dutyEncounters)
		end
		GUI_UnFoldGroup(QM.Windows.Main.name,strings[gCurrentLanguage].dutyEncounters)
	end
	
	GUI_SizeWindow(QM.Windows.Main.name,Settings.FFXIVMINION.qmWindow.width,Settings.FFXIVMINION.qmWindow.height)
	GUI_RefreshWindow(QM.Windows.Main.name)
end
--**************************************************************************************************************************************
function QM.EditEncounter(id)
	local encounterid = tonumber(id)
	local encounter = QM.Encounters[encounterid]
	local taskType = QM.EncounterTasks[encounter.taskFunction]
	
    local wnd = GUI_GetWindowInfo(QM.Windows.Main.name)

	QM.LoadEncounterEditFields(taskType)
	GUI_MoveWindow( QM.Windows.EncounterEditor.name, wnd.x+wnd.width,wnd.y)
	
	for task,fields in ipairs (QM.Builds.DutyTasksEdit[taskType]) do
		if (fields[2] ~= "GUI_NewButton") then
			local varName = fields[5]
			local varSetup = QM.Variables[varName]
			local profileString = varSetup.profile
			_G[varName] = encounter[profileString] or varSetup.default
			Settings.FFXIVMINION[varName] = _G[varName]
			SafeSetVar(varName,_G[varName])
		end
	end
	
	eEncounterNum = encounterid
	Settings.FFXIVMINION.eEncounterNum = eEncounterNum
	
	for task,shortName in pairs(QM.EncounterTasks) do
		if (encounter.taskFunction == task) then
			eEncounterTask = shortName
			Settings.FFXIVMINION.eEncounterTask = eEncounterTask
		end
	end

	GUI_WindowVisible(QM.Windows.EncounterEditor.name,true)
end
--**************************************************************************************************************************************
function QM.SaveEncounter()
	local encounterid = tonumber(eEncounterNum)
	local encounter = QM.Encounters[encounterid]
	
	for k,v in ipairs (QM.Builds.DutyTasksEdit[eEncounterTask]) do
		local value = _G[v[5]]
		if (v[2] ~= "GUI_NewButton" and value ~= nil and value ~= "") then
			local var = QM.Variables[v[5]]
			if var.profile ~= "" and value ~= "" then
				if var.cast == "number" then
					task[var.profile] = tonumber(value)
				elseif var.cast == "string" then
					task[var.profile] = tostring(value)
				elseif var.cast == "boolean" then
					if value == "0" then
						task[var.profile] = false
					else
						task[var.profile] = true
					end
				end
			end
		end
	end
	
	local pos = Player.pos
	task.pos = {
		["x"] = pos.x;
		["y"] = pos.y;
		["z"] = pos.z;
	};
	
	QM.Encounters[encounterid] = task
	
	GUI_WindowVisible( QM.Windows.EncounterEditor.name, false)
	QM.RefreshEncounters()
end
--**************************************************************************************************************************************
function QM.RemoveEncounter()
	local encounterid = tonumber(eEncounterNum)
	local encounter = QM.Encounters[encounterid]
	local tSize = TableSize(QM.Encounters)
	
	if (tSize == 1) then
		--Last entry, nix the table.
		QM.Encounters = nil
	elseif (tSize == encounterid) then
		--Highest entry, nix the entry.
		QM.Encounters[encounterid] = nil
	else
		--Table needs to be reordered
		QM.Encounters = QM.TableRemoveSort(QM.Encounters, encounterid)
	end
	GUI_WindowVisible( QM.Windows.EncounterEditor.name, false)
	QM.RefreshEncounters()
end
--**************************************************************************************************************************************
function QM.AddPreReq()
	local id = tonumber(eQuestID)
	
	if (qPreReqJob == "None" or qPreReqID == "") then 
		return 
	end
	
	local prID = tonumber(qPreReqID)
	local prJob = qPreReqJob == "All" and -1 or tonumber(FFXIV.JOBS[qPreReqJob])
	local prStep = tonumber(qPreReqStep)
	
	assert(type(prID) == "number", "PreReqID must be numeric.")
	if (type(QM.Quests[id].prereq) == "boolean") then
		if (prStep == 1) then
			QM.Quests[id].prereq = nil
			QM.Quests[id].prereq = {} 
		else
			d("Step is out of range.")
			return
		end
	end

	if (prStep > (TableSize(QM.Quests[id].prereq[prJob]) + 1)) then
		d("Step is out of range.")
		return
	end
	
	if (TableSize(QM.Quests[id].prereq[prJob]) == 0) then QM.Quests[id].prereq[prJob] = {} end
	
	if (QM.Quests[id].prereq[prJob][prStep] ~= nil) then
		QM.Quests[id].prereq[prJob] = QM.TableInsertSort(QM.Quests[id].prereq[prJob], prStep, prID)
	else
		QM.Quests[id].prereq[prJob][prStep] = prID
	end
	
	QM.RefreshPreReqs()
end
--**************************************************************************************************************************************
function QM.RemovePreReq(key)
	local id = tonumber(eQuestID)
	
	local t = QM.StringToTable(key,";")
	local prJob = tonumber(t[1])
	local prStep = tonumber(t[2])
	local tSize = TableSize(QM.Quests[id].prereq[prJob])
	
	if (tSize == 1) then
		--Last entry for the job, just nix the table.
		QM.Quests[id].prereq[prJob] = nil
		
		--If it was our only table, nix the prereqs completely.
		if (TableSize(QM.Quests[id].prereq) == 0) then
			QM.Quests[id].prereq = nil
			QM.Quests[id].prereq = false
		end
	elseif (tSize == prStep) then
		--Highest entry in the list, just nix the entry.
		QM.Quests[id].prereq[prJob][prStep] = nil
	else
		--Entry is somewhere in the middle, need to reorder it.
		QM.Quests[id].prereq[prJob] = QM.TableRemoveSort(QM.Quests[id].prereq[prJob], prStep)
	end
	QM.RefreshPreReqs()
end
--**************************************************************************************************************************************
function QM.RefreshPreReqs()
	local id = tonumber(eQuestID)
	
	GUI_DeleteGroup(QM.Windows.PreReqEditor.name,"PreReqs")
	local unfold = false
	if (type(QM.Quests[id].prereq) ~= "boolean") then
		for job,list in pairs(QM.Quests[id].prereq) do
			if TableSize(list) > 0 then
				for step, preReq in spairs(list) do
					GUI_NewButton(QM.Windows.PreReqEditor.name, tostring(job).."["..tostring(step).."] - "..tostring(preReq), "QMPreReqRemove"..tostring(job)..";"..tostring(step), "PreReqs")
					unfold = true
				end
			end 
		end
	end
		
	if (unfold) then
		GUI_UnFoldGroup(QM.Windows.PreReqEditor.name,"PreReqs")
	end
	
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
function QM.AddStepItem()
	local stepid = tonumber(eStepNum)
	local quest = tonumber(eQuestID)
	local step = QM.Quests[quest].steps[stepid]
	
	if (not ValidTable(step.itemid)) then
		step.itemid = {}
	end
	
	local job = qTaskItemJobReq == "None" and -1 or tonumber(FFXIV.JOBS[qTaskItemJobReq])
	local item = tonumber(qTaskItemID)
	
	step.itemid[job] = item
	
	QM.Quests[quest].steps[stepid] = step
	QM.RefreshStepItems()
end
--**************************************************************************************************************************************
function QM.RefreshStepItems()
	local stepid = tonumber(eStepNum)
	local quest = tonumber(eQuestID)
	local step = QM.Quests[quest].steps[stepid]
	
	GUI_DeleteGroup(QM.Windows.ItemEditor.name,GetString("items"))
	
	if (ValidTable(step.itemid)) then
		for job,item in pairs(step.itemid) do
			GUI_NewButton(QM.Windows.ItemEditor.name, tostring(item).."["..tostring(job).."]","QMItemRemove"..tostring(quest)..";"..tostring(stepid)..";"..tostring(job), GetString("items"))
		end
			
		GUI_UnFoldGroup(QM.Windows.ItemEditor.name,GetString("items"))
	end
	
	for k,v in pairs(QM.Quests[quest].steps[stepid]) do
		d("k="..tostring(k)..",v="..tostring(v))
	end
	
	local wnd = QM.Windows.ItemEditor
	GUI_SizeWindow(wnd.name,wnd.width,wnd.height)
	GUI_RefreshWindow(wnd.name)
end
--**************************************************************************************************************************************
function QM.ClearStepItems()
	local stepid = tonumber(eStepNum)
	local quest = tonumber(eQuestID)
	
	QM.Quests[quest].steps[stepid].itemid = nil
	QM.RefreshStepItems()
end
--**************************************************************************************************************************************
function QM.RemoveStepItem(itemstring)
	local i = 0
	local components = {}
	for _, component in StringSplit(itemstring,";") do
		components[i] = tonumber(component)
		i = i + 1
	end
	
	local quest = components[0]
	local stepid = components[1]
	local job = components[2]
	
	QM.Quests[quest].steps[stepid].itemid[job] = nil
	QM.RefreshStepItems()
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
		else
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
	
	for k,v in spairs(QM.Quests[id].steps) do
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
	QM.RefreshTurnovers()
end
--**************************************************************************************************************************************
function QM.AddStep()
	local task = {}
	
	for k,v in ipairs (QM.Builds.QuestTasks[qStepTask]) do
		local value = _G[v[5]]
		if (v[2] ~= "GUI_NewButton" and value ~= nil and value ~= "") then
			local var = QM.Variables[v[5]]
			if var.profile ~= "" and value ~= "" then
				if var.cast == "number" then
					task[var.profile] = tonumber(value)
				elseif var.cast == "string" then
					task[var.profile] = tostring(value)
				elseif var.cast == "boolean" then
					if value == "0" then
						task[var.profile] = false
					else
						task[var.profile] = true
					end
				end
			end
		end
	end
	
	if (task.usepos) then
		task.usepos = {}
		task.usepos.x = task.useposx
		task.usepos.y = task.useposy
		task.usepos.z = task.useposz
		
		task.useposx = nil
		task.useposy = nil
		task.useposz = nil
		task.id = nil
	else
		task.usepos = nil
		task.useposx = nil
		task.useposy = nil
		task.useposz = nil
	end
	
	if (not task.userewardtable and task.itemrewardslot ~= nil and task.itemrewardslot > 0) then
		task.itemrewardslot = task.itemrewardslot - 1
		task.itemreward = true
	elseif (task.userewardtable) then
		local rewardtable = {}
		for name,value in pairs(task) do
			if (string.find(name,"rslot") ~= nil) then
				if (value > 0) then
					local className = string.gsub(name,"rslot","")
					if (className ~= "DEFAULT") then
						local class = FFXIV.JOBS[className]
						rewardtable[class] = (tonumber(value) - 1)
					else
						rewardtable[-1] = (tonumber(value) - 1)
					end
				end
				task[name] = nil
			end
		end
		
		task.itemrewardslot = rewardtable
		task.itemreward = true
	else
		task.itemreward = false
	end
	
	for name, value in pairs(task) do
		if (string.find(name,"rslot") ~= nil) then
			task[name] = nil
		end
	end
	task.userewardtable = nil
	
	if (task.type == "complete" or task.type == "start") then
		if (task.index) then
			task.index = nil
		end
	end
	
	local pos = Player.pos
	task.pos = {
		["x"] = pos.x;
		["y"] = pos.y;
		["z"] = pos.z;
	};
	
	local id = tonumber(eQuestID)
	local step = tonumber(qStepNum)
	
	if (ValidTable(QM.Quests[id].steps[step])) then
		--If the task is nil and there's an itemturnin, add it in with the current task we are adding, and insert as-is.
		if (QM.Quests[id].steps[step].type == nil) then
			if (TableSize(QM.Quests[id].steps[step].itemturninid) > 0) then 
				task.itemturninid = {}
				task.itemturninid = QM.Quests[id].steps[step].itemturninid
				task.itemturnin = true
			end
			QM.Quests[id].steps[step] = task
		else
			QM.Quests[id].steps = QM.TableInsertSort(QM.Quests[id].steps, step, task)
		end
	else
		QM.Quests[id].steps[step] = {}
		QM.Quests[id].steps[step] = task
	end
	
	QM.LoadTaskFields()
end
--**************************************************************************************************************************************
function QM.SaveStep()
	local id = tonumber(eQuestID)
	local step = tonumber(eStepNum)
	local task = QM.Quests[id].steps[step]
	
	for k,v in ipairs (QM.Builds.QuestTasksEdit[eStepTask]) do
		local value = _G[v[5]]
		if (v[2] ~= "GUI_NewButton" and value ~= nil and value ~= "") then
			local var = QM.Variables[v[5]]
			if var.profile ~= "" and value ~= "" then
				if var.cast == "number" then
					task[var.profile] = tonumber(value)
				elseif var.cast == "string" then
					task[var.profile] = tostring(value)
				elseif var.cast == "boolean" then
					if value == "0" then
						task[var.profile] = false
					else
						task[var.profile] = true
					end
				end
			end
		end
	end
	
	if (task.usepos) then
		task.usepos = {}
		task.usepos.x = task.useposx
		task.usepos.y = task.useposy
		task.usepos.z = task.useposz
		
		task.useposx = nil
		task.useposy = nil
		task.useposz = nil
		task.id = nil
	else
		task.usepos = nil
		task.useposx = nil
		task.useposy = nil
		task.useposz = nil
	end
	
	if (not task.userewardtable and task.itemrewardslot ~= nil and task.itemrewardslot > 0) then
		task.itemrewardslot = task.itemrewardslot - 1
		task.itemreward = true
	elseif (task.userewardtable) then
		local rewardtable = {}
		for name,value in pairs(task) do
			if (string.find(name,"slotEdit") ~= nil) then
				if (value > 0) then
					local className = string.gsub(name,"slotEdit","")
					if (className ~= "DEFAULT") then
						local class = FFXIV.JOBS[className]
						rewardtable[class] = (tonumber(value) - 1)
					else
						rewardtable[-1] = (tonumber(value) - 1)
					end
				end
				task[name] = nil
			end
		end
		
		task.itemrewardslot = rewardtable
		task.itemreward = true
	else
		task.itemreward = false
	end
	
	for name, value in pairs(task) do
		if (string.find(name,"slotEdit") ~= nil) then
			task[name] = nil
		end
	end
	task.userewardtable = nil
	
	if (task.type == "complete" or task.type == "start") then
		if (task.index) then
			task.index = nil
		end
	end
	
	local pos = Player.pos
	task.pos = {
		["x"] = pos.x;
		["y"] = pos.y;
		["z"] = pos.z;
	};
	
	QM.Quests[id].steps[step] = task
	
	QM.LoadTaskFields()
	GUI_WindowVisible(QM.Windows.ItemEditor.name,false)
	GUI_WindowVisible(QM.Windows.StepEditor.name,false)
end
--**************************************************************************************************************************************
function QM.EditStep(id)
	local stepid = tonumber(id)
	local quest = tonumber(eQuestID)
    local wnd = GUI_GetWindowInfo(QM.Windows.StepManager.name)	
	local step = QM.Quests[quest].steps[stepid]
	
	QM.LoadTaskEditFields(step.type)
	GUI_MoveWindow( QM.Windows.StepEditor.name, wnd.x+wnd.width,wnd.y)
    
	eStepNum = stepid
	Settings.FFXIVMINION.eStepNum = eStepNum
	
	for task,fields in ipairs (QM.Builds.QuestTasksEdit[step.type]) do
		if (fields[2] ~= "GUI_NewButton") then
			local varName = fields[5]
			local varSetup = QM.Variables[varName]
			local profileString = varSetup.profile
			if (not varSetup.subtable) then
				if (varSetup.cast == "boolean") then
					_G[varName] = (step[profileString] and "1") or "0"
				else
					if (profileString == "itemrewardslot") then
						if (step["itemreward"]) then
							_G[varName] = step[profileString] + 1
						else
							_G[varName] = 0
						end
					else
						_G[varName] = step[profileString] or varSetup.default
					end
				end
				SafeSetVar(varName,_G[varName])
			else
				local subtableName = profileString
				for varName,varTable in pairs(QM.Variables) do
					if (varTable.subtable and varTable.subtable == subtableName) then
						if (step[subtableName] and step[subtableName][varTable.subtableDef]) then
							d("setting "..varName.." to "..tostring(step[subtableName][varTable.subtableDef]))
							_G[varName] = step[subtableName][varTable.subtableDef]
						else
							d("setting "..varName.." to "..tostring(varTable.default))
							_G[varName] = varTable.default
						end
						SafeSetVar(varName,_G[varName])
					end
				end
			end
		end
	end
	
	if (step.itemrewardslot and type(step.itemrewardslot) == "table") then
		eTaskUseRewardTable = "1"
		
		local jobNumReference = {}
		for name,value in pairs(FFXIV.JOBS) do
			jobNumReference[value] = name
		end
		jobNumReference[-1] = "DEFAULT"
		
		for jobNum,name in pairs(jobNumReference) do
			local profileString = "slotEdit"..name
			local vName = nil
			for varName,varTable in pairs(QM.Variables) do
				if (varTable.profile == profileString) then
					vName = varName
				end
			end
			
			if (vName) then
				if (step.itemrewardslot[jobNum]) then
					_G[vName] = (step.itemrewardslot[jobNum] + 1)
				else
					_G[vName] = 0
				end
				SafeSetVar(vName,_G[vName])
			end
		end	
	else
		eTaskUseReward = "0"
	end
	
	GUI_WindowVisible(QM.Windows.StepEditor.name,true)
end
--**************************************************************************************************************************************
function QM.RemoveStep()
	local quest = tonumber(eQuestID)
	local step = tonumber(eStepNum)
	local tSize = TableSize(QM.Quests[quest].steps)
	
	if (tSize == 1) then
		--Last entry, nix the table.
		QM.Quests[quest].steps = nil
	elseif (tSize == step) then
		--Highest entry, nix the entry.
		QM.Quests[quest].steps[step] = nil
	else
		--Table needs to be reordered
		QM.Quests[quest].steps = QM.TableRemoveSort(QM.Quests[quest].steps, step)
	end
	GUI_WindowVisible( QM.Windows.StepEditor.name, false)
	QM.LoadTaskFields()
end
--**************************************************************************************************************************************
function QM.StepPriorityUp()
	local quest = tonumber(eQuestID)
    local step = tonumber(eStepNum)
	
	if (step > 1) then
		QM.Quests[quest].steps = QM.TableShiftEntry(QM.Quests[quest].steps, step, "up")
		QM.LoadTaskFields()
		QM.EditStep(step-1)
	end
end
--**************************************************************************************************************************************
function QM.StepPriorityDown()
	local quest = tonumber(eQuestID)
    local step = tonumber(eStepNum)
	
	if (step < TableSize(QM.Quests[quest].steps)) then
		QM.Quests[quest].steps = QM.TableShiftEntry(QM.Quests[quest].steps, step, "down")
		QM.LoadTaskFields()
		QM.EditStep(step+1)
	end
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

	GUI_DeleteGroup(QM.Windows.StepManager.name,strings[gCurrentLanguage].newQuestStep)
	GUI_DeleteGroup(QM.Windows.StepManager.name,"Reward Table")
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
	
	GUI_UnFoldGroup(QM.Windows.StepManager.name,strings[gCurrentLanguage].newQuestStep)
	
	local id = tonumber(eQuestID)
	local maxStep = 0
	
	GUI_DeleteGroup(QM.Windows.StepManager.name,"Steps")
	if (TableSize(QM.Quests[id].steps) > 0) then
		for k,v in spairs(QM.Quests[tonumber(eQuestID)].steps) do
			GUI_NewButton(QM.Windows.StepManager.name, tostring(v.type).."["..tostring(k).."]", "QMStepEdit"..tostring(k), "Steps")
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
function QM.LoadTaskEditFields(steptype, preserve)
	preserve = preserve or false

	GUI_DeleteGroup(QM.Windows.StepEditor.name,strings[gCurrentLanguage].editQuestStep)
	GUI_DeleteGroup(QM.Windows.StepEditor.name,"Reward Table")
	
	local t = QM.Builds.QuestTasksEdit[steptype]
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
	
	GUI_UnFoldGroup(QM.Windows.StepEditor.name,strings[gCurrentLanguage].editQuestStep)
	QM.LoadVariables()
	
	local wnd = QM.Windows.StepEditor
	GUI_SizeWindow(wnd.name,wnd.width,wnd.height)
	GUI_RefreshWindow(wnd.name)
end
--**************************************************************************************************************************************
function QM.LoadEncounterEditFields(tasktype, preserve)
	preserve = preserve or false

	GUI_DeleteGroup(QM.Windows.EncounterEditor.name,"Edit Encounter Step" )
	
	local t = QM.Builds.DutyTasksEdit[tasktype]
	d("table size = "..tostring(TableSize(t)))
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
	
	GUI_UnFoldGroup(QM.Windows.EncounterEditor.name,"Edit Encounter Step")
	QM.LoadVariables()
	
	local wnd = QM.Windows.EncounterEditor
	d("name = "..tostring(wnd.name)..",width = "..tostring(wnd.width)..",height = "..tostring(wnd.height))
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
		if Settings.FFXIVMINION[tostring(k)] ~= _G[tostring(k)] then
			SafeSetVar(tostring(k),_G[tostring(k)])
		end
	end
end
--**************************************************************************************************************************************
function QM.LoadCurrentValues(strWindow)
	local questid = tonumber(eQuestID)
	--d("questid:"..tostring(questid))
	--d("meshmame:"..tostring(gmeshname))
	if (strWindow == "add") then
		local target = Player:GetTarget()
		if (target ~= nil) then
			qTaskKillTarget = target.uniqueid
			qTaskNPC = target.uniqueid
		end
		local pos = shallowcopy(Player.pos)
		qTaskIndex = Quest:GetQuestCurrentStep(questid)
		qTaskUsePosX = 	pos.x
		qTaskUsePosY = 	pos.y
		qTaskUsePosZ = 	pos.z
		qTaskMesh = tostring(gmeshname)
		qTaskMap = Player.localmapid
	elseif (strWindow == "edit") then
		local target = Player:GetTarget()
		if (target ~= nil) then
			eTaskKillTarget = target.uniqueid
			eTaskNPC = target.uniqueid
		end
		local pos = shallowcopy(Player.pos)
		eTaskIndex = Quest:GetQuestCurrentStep(questid)
		eTaskUsePosX = 	pos.x
		eTaskUsePosY = 	pos.y
		eTaskUsePosZ = 	pos.z
		eTaskMesh = tostring(gmeshname)
		eTaskMap = Player.localmapid
	end
		
	QM.PushVariables()
end
--**************************************************************************************************************************************
function QM.LoadAddCurrentValues()
	QM.LoadCurrentValues("add")
end
--**************************************************************************************************************************************
function QM.LoadEditCurrentValues()
	QM.LoadCurrentValues("edit")
end
--**************************************************************************************************************************************
function QM.PullTurnoverItem()
	local slot = tonumber(qTurnoverSlot)
	QM.LoadItemSlot(slot, "qTurnoverID")
end
function QM.PullTaskAddItem()
	local slot = tonumber(qTaskItemSelector)
	QM.LoadItemSlot(slot, "qTaskItemID")
end
function QM.PullTaskEditItem()
	local slot = tonumber(eTaskItemSelector)
	QM.LoadItemSlot(slot, "eTaskItemID")
end

function QM.LoadItemSlot( numSlot, strVar )
	local inv = Inventory("type=2004")
	if (inv) then
		local item = inv[numSlot]
		if (item) then
			_G[strVar] = tonumber(item.id)
		else
			_G[strVar] = 0
		end
	end
end
--**************************************************************************************************************************************
function QM.LoadWindowFields(window)

	local unfoldGroups = {}
	local t = QM.Builds[window]
	
	--Cycle through the GUI elements for this window and load them, and unfold any necessary groups.
	for k,v in spairs(t) do
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
	
	QM.LoadVariables()
	
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
			if (wname == strings[gCurrentLanguage].profileManager) then
				GUI_NewWindow	(wname,WI.x,WI.y,v.width,v.height)
			else
				GUI_NewWindow	(wname,WI.x,WI.y,v.width,v.height,"",true)
			end 
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

	local tablesEqual = true
	if (ValidTable(WindowInfo) and ValidTable(WI)) then
		tablesEqual = deepcompare(WindowInfo,WI,true)
	end
	if (not tablesEqual) then 
		SafeSetVar(tableName,WindowInfo)
	end
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
	if (TimeSince(QM.WindowTick) > 5000) then
		QM.WindowTick = ticks
		QM.WindowUpdate()
		
		local altered = false
		local quests = QM.Quests
		for id,quest in pairs(quests) do
			if (Quest:HasQuest(id)) then
				if (quest.name == nil or IsNullString(quest.name)) then
					for k,data in pairs(Quest:GetQuestList()) do
						if (k == id) then
							quest.name = data.name
							altered = true
						end
					end
				else
				end
			end
		end
		
		if (altered) then
			local info = {}
			info.quests = quests
			persistence.store(QM.QuestPath..qProfileName..".info",info)
		end
	end
end
--**************************************************************************************************************************************
function QM.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" ) then
		if (string.find(Button,"QMQuestEdit") ~= nil) then
			QM.EditQuest(string.gsub(Button,"QMQuestEdit",""))
		elseif (string.find(Button,"QMEncounterEdit") ~= nil) then
			QM.EditEncounter(string.gsub(Button,"QMEncounterEdit",""))
		elseif (string.sub(Button,1,10) == "QMStepEdit") then
			QM.EditStep(string.gsub(Button,"QMStepEdit",""))
		elseif (string.sub(Button,1,12) == "QMStepRemove") then
			QM.RemoveStep(string.gsub(Button,"QMStepRemove",""))
		elseif (string.sub(Button,1,12) == "QMItemRemove") then
			QM.RemoveStepItem(string.gsub(Button,"QMItemRemove",""))
		elseif (string.sub(Button,1,14) == "QMPreReqRemove") then
			QM.RemovePreReq(string.gsub(Button,"QMPreReqRemove",""))
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

function QM.TableShiftEntry(tblSort, iKey, strDirection)
	local temp = {}
	local t = tblSort
	local p = iKey
	local size = TableSize(t)
	
	if (strDirection == "up" and p > 1) then
		temp = t[p-1]
		t[p-1] = t[p]
		t[p] = temp
		
		return t
	elseif (strDirection == "down" and p < size) then
		temp = t[p+1]
		t[p+1] = t[p]
		t[p] = temp
		
		return t
	else
		return t
	end
end

function QM.TableInsertSort(tblSort, iInsertPoint, vInsertValue)
	assert(type(tblSort) == "table", "First parameter must be the table to sort.")
	assert(type(iInsertPoint) == "number", "Second parameter must be an integer insertion point.")
	assert(vInsertValue ~= nil, "Third parameter must be a non-null variant to be inserted.")
	
	local orderedTable = {}
	local tempTable = {}
	local t = tblSort
	local p = iInsertPoint
	local size = TableSize(t)
	
	if (size < p) then
		t[p] = vInsertValue
		orderedTable = t
	else
		for k,v in spairs(t) do
			if (tonumber(k) >= p) then
				tempTable[tonumber(k)+1] = v
			end
		end
			
		local x = (TableSize(t) + 1)
		for i=1,x do
			if i < p then
				orderedTable[i] = t[i]
			elseif i == p then
				orderedTable[i] = vInsertValue
			elseif i > p then
				orderedTable[i] = tempTable[i]
			end
		end
	end
	return orderedTable
end

function QM.TableRemoveSort(tblSort, iRemovePoint)
	assert(type(tblSort) == "table", "First parameter must be the table to sort.")
	assert(type(iRemovePoint) == "number", "Second parameter must be an integer insertion point.")
	
	local orderedTable = {}
	local tempTable = {}
	local t = tblSort
	local p = iRemovePoint
	local size = TableSize(t)
	
	assert(not(p > size or p < 1), "Removal point is out of range.")
	
	if (size == p) then
		t[p] = nil
		orderedTable = t
	else
		for k,v in spairs(t) do
			if tonumber(k) > p then
				tempTable[tonumber(k)-1] = v
			end
		end
		
		local x = (TableSize(t) - 1)
		
		for i=1,x do
			if i < p then
				orderedTable[i] = t[i]
			elseif i >= p then
				orderedTable[i] = tempTable[i]
			end
		end
	end
	return orderedTable
end

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

RegisterEventHandler("GUI.Item", QM.HandleButtons )
RegisterEventHandler("Module.Initalize",QM.Init)
RegisterEventHandler("Gameloop.Update", QM.OnUpdateHandler)
RegisterEventHandler("GUI.Update",QM.GUIVarUpdate)

ml_global_information = {}
--ml_global_information.path = GetStartupPath()
ml_global_information.Now = 0
ml_global_information.lastrun = 0
ml_global_information.MainWindow = { Name = "FFXIVMinion", x=50, y=50 , width=210, height=300 }
ml_global_information.BtnStart = { Name=strings[gCurrentLanguage].startStop,Event = "GUI_REQUEST_RUN_TOGGLE" }
ml_global_information.BtnPulse = { Name=strings[gCurrentLanguage].doPulse,Event = "Debug.Pulse" }
ml_global_information.CurrentClass = nil
ml_global_information.CurrentClassID = 0
ml_global_information.AttackRange = 2
ml_global_information.TaskUIInit = false
ml_global_information.MarkerMinLevel = 1
ml_global_information.MarkerMaxLevel = 50

FFXIVMINION = {}
FFXIVMINION.SKILLS = {}

function ml_global_information.OnUpdate( event, tickcount )
    ml_global_information.Now = tickcount
    
    -- Mesher.lua
    mm.OnUpdate( event, tickcount )
    
    -- skillmgr.lua
    SkillMgr.OnUpdate( event, tickcount )
    
    -- ffxiv_task_fate.lua
    ffxiv_task_fate.UpdateFateInfo(tickcount)
    
    -- ml_blacklist.lua
    ml_blacklist.ClearBlacklists()
    
    -- ml_blacklist_mgr.lua
    ml_blacklist_mgr.UpdateEntryTime()
    
    gFFXIVMiniondeltaT = tostring(tickcount - ml_global_information.lastrun)
    if (tickcount - ml_global_information.lastrun > tonumber(gFFXIVMINIONPulseTime)) then
        if (not ml_global_information.TaskUIInit) then
            -- load task UIs
            for i, task in pairs(ffxivminion.modes) do
                task.UIInit()
            end
            ml_global_information.TaskUIInit = true
        end
        ml_global_information.lastrun = tickcount
        if( ml_task_hub.CurrentTask() ~= nil) then
            gFFXIVMINIONTask = ml_task_hub:CurrentTask().name
        end
        if(ml_task_hub.shouldRun) then
            ffxivminion.CheckClass()
        end
        
        if (not ml_task_hub:Update() and ml_task_hub.shouldRun) then
            ml_error("No task queued, please select a valid bot mode in the Settings drop-down menu")
        end
    end
end

ffxivminion = {}

ffxivminion.modes = 
{
    [strings[gCurrentLanguage].grindMode] 	= ffxiv_task_grind, 
    [strings[gCurrentLanguage].fishMode] 	= ffxiv_task_fish,
    [strings[gCurrentLanguage].gatherMode] 	= ffxiv_task_gather,
	[strings[gCurrentLanguage].craftMode] 	= ffxiv_task_craft,
    [strings[gCurrentLanguage].assistMode]	= ffxiv_task_assist,
    [strings[gCurrentLanguage].partyMode]	= ffxiv_task_party
}

-- Module Event Handler
function ffxivminion.HandleInit()	
    GUI_SetStatusBar("Initalizing ffxiv Module...")
    
    if (Settings.FFXIVMINION.version == nil ) then
        Settings.FFXIVMINION.version = 1.0
        Settings.FFXIVMINION.gEnableLog = "0"
    end
    if ( Settings.FFXIVMINION.gFFXIVMINIONPulseTime == nil ) then
        Settings.FFXIVMINION.gFFXIVMINIONPulseTime = "150"
    end
    if ( Settings.FFXIVMINION.gEnableLog == nil ) then
        Settings.FFXIVMINION.gEnableLog = "0"
    end
    if ( Settings.FFXIVMINION.gLogCNE == nil ) then
        Settings.FFXIVMINION.gLogCNE = "0"
    end
    if ( Settings.FFXIVMINION.gBotMode == nil ) then
        Settings.FFXIVMINION.gBotMode = strings[gCurrentLanguage].grindMode
    end
    if ( Settings.FFXIVMINION.gUseMount == nil ) then
        Settings.FFXIVMINION.gUseMount = "0"
    end
    if ( Settings.FFXIVMINION.gUseSprint == nil ) then
        Settings.FFXIVMINION.gUseSprint = "0"
    end
    if ( Settings.FFXIVMINION.gMountDist == nil ) then
        Settings.FFXIVMINION.gMountDist = "200"
    end
    if ( Settings.FFXIVMINION.gSprintDist == nil ) then
        Settings.FFXIVMINION.gSprintDist = "50"
    end
    if ( Settings.FFXIVMINION.gAssistMode == nil ) then
        Settings.FFXIVMINION.gAssistMode = "None"
    end
    if ( Settings.FFXIVMINION.gAssistPriority == nil ) then
        Settings.FFXIVMINION.gAssistPriority = "Damage"
    end
    if ( Settings.FFXIVMINION.gRandomPaths == nil ) then
        Settings.FFXIVMINION.gRandomPaths = "0"
	end	
	if ( Settings.FFXIVMINION.gDisableDrawing == nil ) then
		Settings.FFXIVMINION.gDisableDrawing = "0"
	end
    
    GUI_NewWindow(ml_global_information.MainWindow.Name,ml_global_information.MainWindow.x,ml_global_information.MainWindow.y,ml_global_information.MainWindow.width,ml_global_information.MainWindow.height)
    GUI_NewButton(ml_global_information.MainWindow.Name, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
    GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].botMode,"gBotMode",strings[gCurrentLanguage].settings,"None")
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].botEnabled,"gBotRunning",strings[gCurrentLanguage].settings);
    GUI_NewField(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].pulseTime,"gFFXIVMINIONPulseTime",strings[gCurrentLanguage].botStatus );	
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].enableLog,"gEnableLog",strings[gCurrentLanguage].botStatus );
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].logCNE,"gLogCNE",strings[gCurrentLanguage].botStatus );
    GUI_NewField(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].task,"gFFXIVMINIONTask",strings[gCurrentLanguage].botStatus );
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].useMount,"gUseMount",strings[gCurrentLanguage].generalSettings );
    GUI_NewNumeric(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].mountDist,"gMountDist",strings[gCurrentLanguage].generalSettings );
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].useSprint,"gUseSprint",strings[gCurrentLanguage].generalSettings );
    GUI_NewNumeric(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].sprintDist,"gSprintDist",strings[gCurrentLanguage].generalSettings );
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].randomPaths,"gRandomPaths",strings[gCurrentLanguage].generalSettings );	
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].disabledrawing,"gDisableDrawing",strings[gCurrentLanguage].generalSettings );
    GUI_NewButton(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].skillManager, "SkillManager.toggle")
    GUI_NewButton(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].meshManager, "ToggleMeshmgr")
    GUI_NewButton(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].gatherManager, "ToggleGathermgr")
    GUI_NewButton(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].blacklistManager, "ToggleBlacklistMgr")
    GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].assistMode,"gAssistMode",strings[gCurrentLanguage].assist,"None,LowestHealth,Closest")
    GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].assistPriority,"gAssistPriority",strings[gCurrentLanguage].assist,"Damage,Healer")
    
    
    GUI_SizeWindow(ml_global_information.MainWindow.Name,210,300)
    
    gFFXIVMINIONTask = ""
    gBotRunning = "0"
    
    --GUI_FoldGroup(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].botStatus );
    GUI_UnFoldGroup(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].settings)
    
    gEnableLog = Settings.FFXIVMINION.gEnableLog
    gFFXIVMINIONPulseTime = Settings.FFXIVMINION.gFFXIVMINIONPulseTime
    gUseMount = Settings.FFXIVMINION.gUseMount
    gUseSprint = Settings.FFXIVMINION.gUseSprint
    gMountDist = Settings.FFXIVMINION.gMountDist
    gSprintDist = Settings.FFXIVMINION.gSprintDist
    gRandomPaths = Settings.FFXIVMINION.gRandomPaths
    gAssistMode = Settings.FFXIVMINION.gAssistMode
    gAssistPriority = Settings.FFXIVMINION.gAssistPriority
	gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
    
    -- setup bot mode
    local botModes = "None"
    if ( TableSize(ffxivminion.modes) > 0) then
        local i,entry = next ( ffxivminion.modes)
        while i and entry do
            botModes = botModes..","..i
            i,entry = next ( ffxivminion.modes,i)
        end
    end
    
    -- setup parent window for minionlib modules
    ml_marker_mgr.parentWindow = ml_global_information.MainWindow
    ml_blacklist_mgr.parentWindow = ml_global_information.MainWindow
    
    -- setup/load blacklist table
    ml_blacklist_mgr.path = GetStartupPath() .. [[\LuaMods\ffxivminion\blacklist.info]]
    ml_blacklist_mgr.ReadBlacklistFile(ml_blacklist_mgr.path)
    
    gBotMode_listitems = botModes
    
    gBotMode = Settings.FFXIVMINION.gBotMode
    ffxivminion.SetMode(gBotMode)
    
    ml_debug("GUI Setup done")
    GUI_SetStatusBar("Ready...")
end

function ffxivminion.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if( k == "gBotMode" ) then
            ffxivminion.CheckMode()
        end
        if (k == "gEnableLog") then
            if ( v == "1" ) then
                gFFXIVMINIONPulseTime = 1000
            else
                gFFXIVMINIONPulseTime = Settings.FFXIVMINION.gFFXIVMINIONPulseTime
            end
			Settings.FFXIVMINION[tostring(k)] = v
        elseif (
            k == "gLogCNE" or
            k == "gFFXIVMINIONPulseTime" or
            k == "gBotMode" or 
            k == "gUseMount" or
            k == "gUseSprint" or
            k == "gMountDist" or
            k == "gAssistMode" or
            k == "gAssistPriority" or
            k == "gSprintDist" or
            k == "gRandomPaths" )			
        then
            Settings.FFXIVMINION[tostring(k)] = v
        elseif ( k == "gBotRunning" ) then
            ml_task_hub.ToggleRun()
		elseif ( k == "gDisableDrawing" ) then
			if ( v == "1" ) then
				GameHacks:Disable3DRendering(true)
			else
				GameHacks:Disable3DRendering(false)
			end
        end
    end
    GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

function ffxivminion.SetMode(mode)
    local task = ffxivminion.modes[mode]
    if (task ~= nil) then
        ml_task_hub:Add(task:Create(), LONG_TERM_GOAL, TP_ASAP)
		gBotMode = mode
    end
end

function ffxivminion.CheckClass()
    local classes = 
    {
        [FFXIV.JOBS.ARCANIST] 		= ffxiv_combat_arcanist,
        [FFXIV.JOBS.ARCHER]			= ffxiv_combat_archer,
        [FFXIV.JOBS.BARD]			= ffxiv_combat_bard,
        [FFXIV.JOBS.BLACKMAGE]		= ffxiv_combat_blackmage,
        [FFXIV.JOBS.CONJURER]		= ffxiv_combat_conjurer,
        [FFXIV.JOBS.DRAGOON]		= ffxiv_combat_dragoon,
        [FFXIV.JOBS.GLADIATOR] 		= ffxiv_combat_gladiator,
        [FFXIV.JOBS.LANCER]			= ffxiv_combat_lancer,
        [FFXIV.JOBS.MARAUDER] 		= ffxiv_combat_marauder,
        [FFXIV.JOBS.MONK] 			= ffxiv_combat_monk,
        [FFXIV.JOBS.PALADIN] 		= ffxiv_combat_paladin,
        [FFXIV.JOBS.PUGILIST] 		= ffxiv_combat_pugilist,
        [FFXIV.JOBS.SCHOLAR] 		= ffxiv_combat_scholar,
        [FFXIV.JOBS.SUMMONER] 		= ffxiv_combat_summoner,
        [FFXIV.JOBS.THAUMATURGE] 	= ffxiv_combat_thaumaturge,
        [FFXIV.JOBS.WARRIOR] 	 	= ffxiv_combat_warrior,
        [FFXIV.JOBS.WHITEMAGE] 	 	= ffxiv_combat_whitemage,
        [FFXIV.JOBS.BOTANIST] 		= ffxiv_gather_botanist,
        [FFXIV.JOBS.FISHER] 		= ffxiv_gather_fisher,
        [FFXIV.JOBS.MINER] 			= ffxiv_gather_miner,
		
		[FFXIV.JOBS.CARPENTER] 		= ffxiv_crafting_carpenter,
        [FFXIV.JOBS.BLACKSMITH] 	= ffxiv_crafting_blacksmith,
		[FFXIV.JOBS.ARMORER] 		= ffxiv_crafting_armorer,
		[FFXIV.JOBS.GOLDSMITH] 		= ffxiv_crafting_goldsmith,
		[FFXIV.JOBS.LEATHERWORKER] 	= ffxiv_crafting_leatherworker,
		[FFXIV.JOBS.WEAVER] 		= ffxiv_crafting_weaver,
		[FFXIV.JOBS.ALCHEMIST] 		= ffxiv_crafting_alchemist,
		[FFXIV.JOBS.CULINARIAN] 	= ffxiv_crafting_culinarian,
    }
    
    --TODO check which class we are currently using and modify globals appropriately
    if (ml_global_information.CurrentClass == nil or ml_global_information.CurrentClassID ~= Player.job) then
        ml_global_information.CurrentClass = classes[Player.job]
        ml_global_information.CurrentClassID = Player.job
        if ml_global_information.CurrentClass ~= nil then
            ml_global_information.AttackRange = ml_global_information.CurrentClass.range
			
			-- autosetting the correct botmode
			if ( ml_global_information.CurrentClass == ffxiv_gather_botanist ) then
				ffxivminion.SetMode(strings[gCurrentLanguage].gatherMode)
			elseif ( ml_global_information.CurrentClass == ffxiv_gather_miner ) then
				ffxivminion.SetMode(strings[gCurrentLanguage].gatherMode)
			elseif ( ml_global_information.CurrentClass == ffxiv_gather_fisher ) then
				ffxivminion.SetMode(strings[gCurrentLanguage].fishMode)
			elseif ( ml_global_information.CurrentClass == ffxiv_crafting_carpenter or ml_global_information.CurrentClass == ffxiv_crafting_blacksmith 
					or ml_global_information.CurrentClass == ffxiv_crafting_armorer or ml_global_information.CurrentClass == ffxiv_crafting_goldsmith
					or ml_global_information.CurrentClass == ffxiv_crafting_leatherworker or ml_global_information.CurrentClass == ffxiv_crafting_weaver
					or ml_global_information.CurrentClass == ffxiv_crafting_alchemist or ml_global_information.CurrentClass == ffxiv_crafting_culinarian) then
				ffxivminion.SetMode(strings[gCurrentLanguage].craftMode)
			--default it to Grind if crafting/gathering/fishing mode was selected but we are not in that class
			elseif ( gBotMode == strings[gCurrentLanguage].gatherMode or gBotMode == strings[gCurrentLanguage].fishMode or gBotMode == strings[gCurrentLanguage].craftMode) then
				ffxivminion.SetMode(strings[gCurrentLanguage].grindMode)				
			end
			
        else
            ml_global_information.AttackRange = 3
        end
    end
end

function ffxivminion.CheckMode()
    local task = ffxivminion.modes[gBotMode]
    if (task ~= nil) then
        if (not ml_task_hub:CheckForTask(task)) then
            ffxivminion.SetMode(gBotMode)
        end
    elseif (gBotMode == "None") then
        ml_task_hub:ClearQueues()
    end
end

function ml_global_information.Reset()
    --TODO: Figure out what state needs to be reset and add calls here
    ml_task_hub:ClearQueues()
    ffxivminion.CheckMode()
end

function ml_global_information.Stop()
    --TODO: Do anything here for bot stopping
    
    if (Player:IsMoving()) then
        Player:Stop()
    end
end

-- Register Event Handlers
RegisterEventHandler("Module.Initalize",ffxivminion.HandleInit)
RegisterEventHandler("Gameloop.Update",ml_global_information.OnUpdate)
RegisterEventHandler("GUI.Update",ffxivminion.GUIVarUpdate)

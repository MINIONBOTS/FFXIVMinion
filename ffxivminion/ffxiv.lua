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
ml_global_information.BlacklistContentID = ""
ml_global_information.WhitelistContentID = ""
ml_global_information.MarkerTime = 0
ml_global_information.afkTimer = 0
ml_global_information.IsWaiting = false
ml_global_information.UnstuckTimer = 0

FFXIVMINION = {}
FFXIVMINION.SKILLS = {}

ffxivminion = {}
ffxivminion.modes = {}

function ml_global_information.OnUpdate( event, tickcount )
    ml_global_information.Now = tickcount
    
    if (ml_global_information.UnstuckTimer ~= 0 and TimeSince(ml_global_information.UnstuckTimer) > 15000) then
        ml_task_hub:ToggleRun()
        ml_global_information.UnstuckTimer = 0
    end
    
    -- Mesher.lua
    mm.OnUpdate( event, tickcount )
    
    -- skillmgr.lua
    SkillMgr.OnUpdate( event, tickcount )
    
    -- ffxiv_task_fate.lua
    ffxiv_task_grind.UpdateBlacklistUI(tickcount)
    
    -- ml_blacklist.lua
    ml_blacklist.ClearBlacklists()
    
    -- ml_blacklist_mgr.lua
    ml_blacklist_mgr.UpdateEntryTime()
    ml_blacklist_mgr.UpdateEntries(tickcount)
    
    --ffxiv_unstuck.lua
    ffxiv_unstuck.HandleUpdate(tickcount)
    
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
        if( ml_task_hub:CurrentTask() ~= nil) then
            gFFXIVMINIONTask = ml_task_hub:CurrentTask().name
        end
		--update marker status
		if (	gBotMode == strings[gCurrentLanguage].grindMode or
				gBotMode == strings[gCurrentLanguage].gatherMode or
				gBotMode == strings[gCurrentLanguage].fishMode) and (
				ValidTable(GetCurrentMarker())) and
				ml_task_hub.shouldRun
		then
			local timesince = TimeSince(ml_global_information.MarkerTime)
			local timeleft = ((GetCurrentMarker():GetTime() * 1000) - timesince) / 1000
			gStatusMarkerTime = tostring(round(timeleft, 1))
		else
			gStatusMarkerName = ""
			gStatusMarkerTime = ""
		end
		
		ffxivminion.CheckClass()
        
        if (not ml_task_hub:Update() and ml_task_hub.shouldRun) then
            ml_error("No task queued, please select a valid bot mode in the Settings drop-down menu")
        end
    end
end

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
        Settings.FFXIVMINION.gMountDist = "75"
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
	if ( Settings.FFXIVMINION.gAutoStart == nil ) then
		Settings.FFXIVMINION.gAutoStart = "0"
	end	
    if (Settings.FFXIVMINION.gStartCombat == nil) then
        Settings.FFXIVMINION.gStartCombat = "1"
    end
	
    if (Settings.FFXIVMINION.gConfirmDuty == nil) then
        Settings.FFXIVMINION.gConfirmDuty = "0"
    end
    
    if (Settings.FFXIVMINION.gSkipCutscene == nil) then
        Settings.FFXIVMINION.gSkipCutscene = "0"
    end
	
    if (Settings.FFXIVMINION.gSkipDialogue == nil) then
        Settings.FFXIVMINION.gSkipDialogue = "0"
    end
    
    if (Settings.FFXIVMINION.gDoUnstuck == nil) then
        Settings.FFXIVMINION.gDoUnstuck = "0"
    end
	
	if (Settings.FFXIVMINION.gUseHQMats == nil) then
		Settings.FFXIVMINION.gUseHQMats = "0"
	end
    
    if (Settings.FFXIVMINION.gClickToTeleport == nil) then
		Settings.FFXIVMINION.gClickToTeleport = "0"
	end
    
    if (Settings.FFXIVMINION.gClickToTravel == nil) then
		Settings.FFXIVMINION.gClickToTravel = "0"
	end
    
    GUI_NewWindow(ml_global_information.MainWindow.Name,ml_global_information.MainWindow.x,ml_global_information.MainWindow.y,ml_global_information.MainWindow.width,ml_global_information.MainWindow.height)
    GUI_NewButton(ml_global_information.MainWindow.Name, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
    GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].botMode,"gBotMode",strings[gCurrentLanguage].settings,"None")
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].botEnabled,"gBotRunning",strings[gCurrentLanguage].settings);
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].autoStartBot,"gAutoStart",strings[gCurrentLanguage].settings);	
    GUI_NewField(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].pulseTime,"gFFXIVMINIONPulseTime",strings[gCurrentLanguage].botStatus );	
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].enableLog,"gEnableLog",strings[gCurrentLanguage].botStatus );
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].logCNE,"gLogCNE",strings[gCurrentLanguage].botStatus );
    GUI_NewField(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].task,"gFFXIVMINIONTask",strings[gCurrentLanguage].botStatus );
	GUI_NewField(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].markerName,"gStatusMarkerName",strings[gCurrentLanguage].botStatus );
	GUI_NewField(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].markerTime,"gStatusMarkerTime",strings[gCurrentLanguage].botStatus );
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].useMount,"gUseMount",strings[gCurrentLanguage].generalSettings );
    GUI_NewNumeric(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].mountDist,"gMountDist",strings[gCurrentLanguage].generalSettings );
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].useSprint,"gUseSprint",strings[gCurrentLanguage].generalSettings );
    GUI_NewNumeric(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].sprintDist,"gSprintDist",strings[gCurrentLanguage].generalSettings );
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].randomPaths,"gRandomPaths",strings[gCurrentLanguage].generalSettings );	
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].disabledrawing,"gDisableDrawing",strings[gCurrentLanguage].generalSettings );
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].skipCutscene,"gSkipCutscene",strings[gCurrentLanguage].generalSettings );	
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].skipDialogue,"gSkipDialogue",strings[gCurrentLanguage].generalSettings );
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].doUnstuck,"gDoUnstuck",strings[gCurrentLanguage].generalSettings );
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].useHQMats,"gUseHQMats",strings[gCurrentLanguage].generalSettings );
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].clickToTeleport,"gClickToTeleport",strings[gCurrentLanguage].generalSettings );
	GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].clickToTravel,"gClickToTravel",strings[gCurrentLanguage].generalSettings );
    GUI_NewButton(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].skillManager, "SkillManager.toggle")
    GUI_NewButton(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].meshManager, "ToggleMeshmgr")
    GUI_NewButton(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].blacklistManager, "ToggleBlacklistMgr")
	GUI_NewButton(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].markerManager, "ToggleMarkerMgr")
	--GUI_NewButton(ml_global_information.MainWindow.Name, GetString("questManager"), "QuestManager.toggle")
    GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].assistMode,"gAssistMode",strings[gCurrentLanguage].assist,"None,LowestHealth,Closest")
    GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].assistPriority,"gAssistPriority",strings[gCurrentLanguage].assist,"Damage,Healer")
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].startCombat,"gStartCombat",strings[gCurrentLanguage].assist)
    GUI_NewCheckbox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].confirmDuty,"gConfirmDuty",strings[gCurrentLanguage].assist) 
    
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
    gAutoStart = Settings.FFXIVMINION.gAutoStart
    gStartCombat = Settings.FFXIVMINION.gStartCombat
    gConfirmDuty = Settings.FFXIVMINION.gConfirmDuty
    gSkipCutscene = Settings.FFXIVMINION.gSkipCutscene
    gSkipDialogue = Settings.FFXIVMINION.gSkipDialogue
    gDoUnstuck = Settings.FFXIVMINION.gDoUnstuck
    gUseHQMats = Settings.FFXIVMINION.gUseHQMats	
    gClickToTeleport = Settings.FFXIVMINION.gClickToTeleport
    gClickToTravel = Settings.FFXIVMINION.gClickToTravel
	
	ffxivminion.modes =
	{
		[strings[gCurrentLanguage].grindMode] 	= ffxiv_task_grind, 
		[strings[gCurrentLanguage].fishMode] 	= ffxiv_task_fish,
		[strings[gCurrentLanguage].gatherMode] 	= ffxiv_task_gather,
		[strings[gCurrentLanguage].craftMode] 	= ffxiv_task_craft,
		[strings[gCurrentLanguage].assistMode]	= ffxiv_task_assist,
		[strings[gCurrentLanguage].partyMode]	= ffxiv_task_party,
		[strings[gCurrentLanguage].pvpMode]	    = ffxiv_task_pvp,
		[strings[gCurrentLanguage].dutyMode] 	= ffxiv_task_duty,
		[strings[gCurrentLanguage].questMode]	= ffxiv_task_quest,
		["Test"]								= ffxiv_task_test,
	}
    
    -- setup parent window for minionlib modules
    ml_marker_mgr.parentWindow = ml_global_information.MainWindow
    ml_blacklist_mgr.parentWindow = ml_global_information.MainWindow
    
    -- setup/load blacklist tables
    ml_blacklist_mgr.path = GetStartupPath() .. [[\LuaMods\ffxivminion\blacklist.info]]
    ml_blacklist_mgr.ReadBlacklistFile(ml_blacklist_mgr.path)
    
    if not ml_blacklist.BlacklistExists("Fates") then
        ml_blacklist.CreateBlacklist("Fates")
    end
    
    if not ml_blacklist.BlacklistExists(strings[gCurrentLanguage].monsters) then
        ml_blacklist.CreateBlacklist(strings[gCurrentLanguage].monsters)
    end
    
    if not ml_blacklist.BlacklistExists(strings[gCurrentLanguage].gatherMode) then
        ml_blacklist.CreateBlacklist(strings[gCurrentLanguage].gatherMode)
    end
    
	-- setup marker manager callbacks and vars
	ml_marker_mgr.GetPosition = 	function () return Player.pos end
	ml_marker_mgr.GetLevel = 		function () return Player.level end
	ml_marker_mgr.DrawMarker =		mm.DrawMarker
	
	-- setup bot mode
    local botModes = "None"
    if ( TableSize(ffxivminion.modes) > 0) then
        local i,entry = next ( ffxivminion.modes)
        while i and entry do
            botModes = botModes..","..i
            i,entry = next ( ffxivminion.modes,i)
        end
    end
	
    gBotMode_listitems = botModes
    
    gBotMode = Settings.FFXIVMINION.gBotMode
    ffxivminion.SetMode(gBotMode)
    
	-- gAutoStart
	if ( gAutoStart == "1" ) then
		ml_task_hub.ToggleRun()		
	end
    
    if (gSkipCutscene == "1" ) then
        GameHacks:SkipCutscene(true)
    end
    
    if (gSkipDialogue == "1" ) then
        GameHacks:SkipDialogue(true)
    end
	
	if (gUseHQMats == "1") then
		Crafting:UseHQMats(true)
	end
    
	if (gClickToTeleport == "1") then
		GameHacks:SetClickToTeleport(true)
	end
    
	if (gClickToTravel == "1") then
		GameHacks:SetClickToTravel(true)
	end
    
	
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
			k == "gAutoStart" or
			k == "gStartCombat" or
			k == "gConfirmDuty" or
            k == "gDoUnstuck" or
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
		elseif ( k == "gSkipCutscene" ) then
			if ( v == "1" ) then
				GameHacks:SkipCutscene(true)
			else
				GameHacks:SkipCutscene(false)
			end
            Settings.FFXIVMINION[tostring(k)] = v
		elseif ( k == "gSkipDialogue" ) then
			if ( v == "1" ) then
				GameHacks:SkipDialogue(true)
			else
				GameHacks:SkipDialogue(false)
			end
            Settings.FFXIVMINION[tostring(k)] = v
        elseif ( k == "gClickToTeleport" ) then
			if ( v == "1" ) then
				GameHacks:SetClickToTeleport(true)
			else
				GameHacks:SetClickToTeleport(false)
			end
            Settings.FFXIVMINION[tostring(k)] = v
        elseif ( k == "gClickToTravel" ) then
			if ( v == "1" ) then
				GameHacks:SetClickToTravel(true)
			else
				GameHacks:SetClickToTravel(false)
			end
            Settings.FFXIVMINION[tostring(k)] = v
		elseif ( k == "gUseHQMats" ) then
			if ( v == "1" ) then
				Crafting:UseHQMats(true)
			else
				Crafting:UseHQMats(false)
			end
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

function ffxivminion.SetMode(mode)
    local task = ffxivminion.modes[mode]
    if (task ~= nil) then
        ml_task_hub:Add(task.Create(), LONG_TERM_GOAL, TP_ASAP)
		gBotMode = mode
        if (gBotMode == strings[gCurrentLanguage].pvpMode) then
            Player:EnableUnstuckJump(false)
        else
            Player:EnableUnstuckJump(true)
        end
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
            
            -- set default sm profile
            SkillMgr.SetDefaultProfile()
			
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

ml_global_information = {}
ml_global_information.path = GetStartupPath()
ml_global_information.Now = 0
ml_global_information.lastrun = 0
ml_global_information.CurrentClass = nil
ml_global_information.CurrentClassID = 0
ml_global_information.AttackRange = 2
ml_global_information.TaskUIInit = false
ml_global_information.MarkerMinLevel = 1
ml_global_information.MarkerMaxLevel = 50
ml_global_information.BlacklistContentID = ""
ml_global_information.WhitelistContentID = ""
ml_global_information.currentMarker = false
ml_global_information.MarkerTime = 0
ml_global_information.afkTimer = 0
ml_global_information.syncTimer = 0
ml_global_information.IsWaiting = false
ml_global_information.UnstuckTimer = 0
ml_global_information.stanceTimer = 0
ml_global_information.summonTimer = 0
ml_global_information.repairTimer = 0
ml_global_information.windowTimer = 0
ml_global_information.disableFlee = false
ml_global_information.updateFoodTimer = 0
ml_global_information.foodCheckTimer = 0
ml_global_information.rootCheckTimer = 0
ml_global_information.lastMode = ""
ml_global_information.itemIDsToEquip = {}
ml_global_information.idlePulseCount = 0
ml_global_information.autoStartQueued = false
ml_global_information.blacklistedAetherytes = {}
ml_global_information.navObstacles = {}
ml_global_information.navObstaclesTimer = 0
ml_global_information.suppressRestTimer = 0
ml_global_information.queueSync = nil

FFXIVMINION = {}
FFXIVMINION.SKILLS = {}

ffxivminion = {}
ffxivminion.foods = {}
ffxivminion.foodsHQ = {}
ffxivminion.modes = {}
ffxivminion.modesToLoad = {}

ffxivminion.Strings = {
	BotModes = 
		function ()
			local botModes = ""
			if ( TableSize(ffxivminion.modes) > 0) then
				for i, entry in pairs(ffxivminion.modes) do
					if (botModes == "") then
						botModes = i
					else
						botModes = botModes..","..i
					end
				end				
			end
			return botModes
		end,
	SKMProfiles = 
		function () return SkillMgr.UpdateProfiles() end,
	Mounts = 
		function ()
			local MountsList = "None"
			local eq = ActionList("type=13")
			for k,v in pairs(eq) do
				MountsList = MountsList..","..v.name
			end
			return MountsList
		end,
	Meshes = 
		function ()
			local count = 0
			local meshlist = "none"
			local meshfilelist = dirlist(ml_mesh_mgr.navmeshfilepath,".*obj")
			if ( ValidTable(meshfilelist)) then
				for i, meshname in pairs(meshfilelist) do
					meshname = string.gsub(meshname, ".obj", "")
					meshlist = meshlist..","..meshname
				end
			end
			
			return meshlist
		end,
}

ffxivminion.settingsVisible = false

function ml_global_information.OnUpdate( event, tickcount )

    ml_global_information.Now = tickcount
	
	if (ValidTable(ffxivminion.modesToLoad)) then
		ffxivminion.LoadModes()
		gBotRunning = "0"
	end
	
	if (ml_global_information.autoStartQueued) then
		if (Player) then
			ml_global_information.autoStartQueued = false
			ml_task_hub:ToggleRun()
		end
	end
	
	if (ml_global_information.queueSync) then
		local timer = ml_global_information.queueSync.timer
		local h = ml_global_information.queueSync.h or 1
		if (timer and Now() > timer) then
			Player:SetFacingSynced(h)
			ml_global_information.queueSync = nil
		end
	end
	
	if (ml_mesh_mgr and not IsLoading()) then
		ml_mesh_mgr.OMC_Handler_OnUpdate( tickcount )
	end
	
	if (ml_global_information.navObstacles and Now() > ml_global_information.navObstaclesTimer) then
		ml_global_information.navObstaclesTimer = Now() + 1000
		
		local needsClearing = false
		local hasNew = false
		--Check for expired obstacles and remove them from viability.
		local obstacles = ml_global_information.navObstacles
		for i,obstacle in pairs(obstacles) do
			if (Now() > obstacle.timer) then
				--d("Nav obstacle " .. i .. " was removed because its timer expired.")
				obstacles[i] = nil
				needsClearing = true
			else
				if (obstacle.isnew) then
					--d("Found a new obstacle.")
					hasNew = true
					obstacle.isnew = false
				end
			end
		end
		
		if (needsClearing) then
			--d("Clearing nav obstacles.")
			NavigationManager:ClearNavObstacles()
		end
		
		if (needsClearing or hasNew) then
			--d("Adding nav obstacles.")
			NavigationManager:AddNavObstacles(obstacles)
		end
	end 
	
	local pulseTime = tonumber(gFFXIVMINIONPulseTime) or 150
    if (TimeSince(ml_global_information.lastrun) > pulseTime) then
        ml_global_information.lastrun = tickcount
		
		-- close any social addons that might screw up behavior first
		if(	gBotRunning == "1" and 
			gBotMode ~= GetString("assistMode") and
			gBotMode ~= GetString("dutyMode")) 
		then
			ffxivminion.ClearAddons()
		end
		
        if( ml_task_hub:CurrentTask() ~= nil) then
            gFFXIVMINIONTask = ml_task_hub:CurrentTask().name
        end
		
		--update idle pulse count
		if (ml_global_information.idlePulseCount ~= 0) then
			gIdlePulseCount = tostring(ml_global_information.idlePulseCount)
		elseif(gIdlePulseCount ~= "") then
			gIdlePulseCount = ""
		end
		
		--update delay time
		if (ml_task_hub:CurrentTask() and ml_task_hub:CurrentTask():IsDelayed()) then
			gTaskDelay = tostring(ml_task_hub:CurrentTask():GetDelay())
		elseif(gTaskDelay ~= "") then
			gTaskDelay = ""
		end
		
		--update marker status
		if (	gBotMode == GetString("grindMode") or
				gBotMode == GetString("gatherMode") or
				gBotMode == GetString("fishMode") or
				gBotMode == GetString("questMode") or
				gBotMode == GetString("huntMode") or 
				gBotMode == GetString("pvpMode") ) and
				ml_task_hub.shouldRun and 
				ValidTable(ml_global_information.currentMarker)
		then
			local timeleft = (ml_global_information.MarkerTime - Now()) / 1000
			if (timeleft > 0) then
				gStatusMarkerTime = tostring(round(timeleft, 1))
			else
				gStatusMarkerTime = "0.0"
			end
		else
			gStatusMarkerName = ""
			gStatusMarkerTime = ""
		end
		
		local et = EorzeaTime() 
		gEorzeaTime = tostring(et.hour)..":"..(et.minute < 10 and "0" or "")..tostring(et.minute)
		
		-- Mesher.lua
		if (ml_mesh_mgr) then
			ml_mesh_mgr.OnUpdate( tickcount )
		end
		
		-- ffxiv_task_fate.lua
		ffxiv_task_grind.UpdateBlacklistUI(tickcount)
		
		-- ml_blacklist.lua
		ml_blacklist.ClearBlacklists()
		
		-- ml_blacklist_mgr.lua
		ml_blacklist_mgr.UpdateEntryTime()
		ml_blacklist_mgr.UpdateEntries(tickcount)
		
		if (SkillMgr) then
			ffxivminion.CheckClass()
		end		
		
		if (TimeSince(ml_global_information.windowTimer) > 10000) then
			ml_global_information.windowTimer = tickcount
			ffxivminion.SaveWindows()
		end
		
		if (TimeSince(ml_global_information.updateFoodTimer) > 15000) then
			ml_global_information.updateFoodTimer = tickcount
			ffxivminion.UpdateFoodOptions()
		end
		
		if (gBotRunning == "1") then
			
			if ( TimeSince(ml_global_information.repairTimer) > 30000 ) then
				ml_global_information.repairTimer = tickcount
				
				local list = Player:GetGatherableSlotList()
				local synth = Crafting:SynthInfo()	
		
				if (not ValidTable(list) and not ValidTable(synth) and not Player.incombat) then
					Repair()
				end
			end
	
			if ( gFood ~= "None" or gFoodHQ ~= "None" ) then
				if ( TimeSince(ml_global_information.foodCheckTimer) > 10000 and not Player.ismounted and not Player:IsMoving()) then
					ml_global_information.foodCheckTimer = tickcount
					
					local list = Player:GetGatherableSlotList()
					local synth = Crafting:SynthInfo()	
			
					if (not ValidTable(list) and not ValidTable(synth)) then
						Eat()
					end
				end
			end
			
			if (gUseCurielRoot == "1") then
				if ( TimeSince(ml_global_information.rootCheckTimer) > 30000 and not Player.ismounted) then
					ml_global_information.rootCheckTimer = tickcount
					
					if (not Player.ismounted and not IsMounting()) then
						local al = ActionList("type=6")
						local dismiss = al[2]
						local acDismiss = ActionList:Get(dismiss.id,6)
						local item = Inventory:Get(7894)

						if ( acDismiss.isready and item and item.isready) then
							local el = EntityList("nearest,myparty,type=2,chartype=3")
							if (ValidTable(el)) then
								local i, choco = next(el)
								if (i and choco) then
									if MissingBuffs(choco,"536") then
										Player:Stop()
										local newTask = ffxiv_task_useitem.Create()
										newTask.itemid = 7894
										newTask.useTime = 3000
										ml_task_hub:CurrentTask():AddSubTask(newTask)
									end
								end
							end
						end
					end
				end
			end
		end
        
        if (not ml_task_hub:Update() and ml_task_hub.shouldRun) then
            ml_error("No task queued, please select a valid bot mode in the Settings drop-down menu")
        end
    end
end

-- Module Event Handler
function ffxivminion.HandleInit()
		
	ml_global_information.MainWindow = { Name = GetString("settings"), x=50, y=50 , width=250, height=450 }
	ml_global_information.BtnStart = { Name=GetString("startStop"),Event = "GUI_REQUEST_RUN_TOGGLE" }
	ml_global_information.BtnPulse = { Name=GetString("doPulse"),Event = "Debug.Pulse" }
	
	ml_global_information.chocoStance = {
		[GetString("stFollow")] = 3,
		[GetString("stFree")] = 4,
		[GetString("stDefender")] = 5,
		[GetString("stAttacker")] = 6,
		[GetString("stHealer")] = 7,
	}
	
	ml_global_information.blacklistedAetherytes = {}
	
	ffxivminion.AddMode(GetString("grindMode"), ffxiv_task_grind) 
	ffxivminion.AddMode(GetString("fishMode"), ffxiv_task_fish)
	ffxivminion.AddMode(GetString("gatherMode"), ffxiv_task_gather)
	ffxivminion.AddMode(GetString("craftMode"), ffxiv_task_craft)
	ffxivminion.AddMode(GetString("assistMode"), ffxiv_task_assist)
	ffxivminion.AddMode(GetString("partyMode"), ffxiv_task_party)
	ffxivminion.AddMode(GetString("pvpMode"), ffxiv_task_pvp)
	ffxivminion.AddMode(GetString("frontlines"), ffxiv_task_frontlines)
	ffxivminion.AddMode(GetString("dutyMode"), ffxiv_task_duty)
	ffxivminion.AddMode(GetString("huntMode"), ffxiv_task_hunt)
	ffxivminion.AddMode(GetString("huntlogMode"), ffxiv_task_huntlog)
	ffxivminion.AddMode(GetString("quickStartMode"), ffxiv_task_qs_wrapper)
	ffxivminion.AddMode("NavTest", ffxiv_task_test)
	
	if ( not ffxivminion.Windows ) then
		ffxivminion.Windows = {}
	end
	
	ffxivminion.Windows.Main = { id = strings["us"].settings, Name = GetString("settings"), x=50, y=50, width=210, height=350 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Main)

	if ( Settings.FFXIVMINION.version == nil ) then
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
        Settings.FFXIVMINION.gBotMode = GetString("grindMode")
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
    if ( Settings.FFXIVMINION.gRandomPaths == nil ) then
        Settings.FFXIVMINION.gRandomPaths = "0"
	end	
	if ( Settings.FFXIVMINION.gDisableDrawing == nil ) then
		Settings.FFXIVMINION.gDisableDrawing = "0"
	end
	if ( Settings.FFXIVMINION.gAutoStart == nil ) then
		Settings.FFXIVMINION.gAutoStart = "0"
	end	
	if ( Settings.FFXIVMINION.gTeleport == nil) then
        Settings.FFXIVMINION.gTeleport = "0"
    end
	if ( Settings.FFXIVMINION.gParanoid == nil) then
        Settings.FFXIVMINION.gParanoid = "1"
    end
    if ( Settings.FFXIVMINION.gSkipCutscene == nil) then
        Settings.FFXIVMINION.gSkipCutscene = "0"
    end
    if ( Settings.FFXIVMINION.gSkipDialogue == nil) then
        Settings.FFXIVMINION.gSkipDialogue = "0"
    end
    if ( Settings.FFXIVMINION.gDoUnstuck == nil) then
        Settings.FFXIVMINION.gDoUnstuck = "0"
    end
	if ( Settings.FFXIVMINION.gUseHQMats == nil) then
		Settings.FFXIVMINION.gUseHQMats = "0"
	end
    if ( Settings.FFXIVMINION.gClickToTeleport == nil) then
		Settings.FFXIVMINION.gClickToTeleport = "0"
	end
    if ( Settings.FFXIVMINION.gClickToTravel == nil) then
		Settings.FFXIVMINION.gClickToTravel = "0"
	end
	if ( Settings.FFXIVMINION.gChoco == nil) then
		Settings.FFXIVMINION.gChoco = GetString("none")
	end
	if ( Settings.FFXIVMINION.gMount == nil) then
		Settings.FFXIVMINION.gMount = GetString("none")
	end
    if ( Settings.FFXIVMINION.gChocoStance == nil) then
		Settings.FFXIVMINION.gChocoStance = GetString("stFree")
	end
	if ( Settings.FFXIVMINION.gRepair == nil) then
		Settings.FFXIVMINION.gRepair = "1"
	end
	if ( Settings.FFXIVMINION.gGatherPS == nil) then
		Settings.FFXIVMINION.gGatherPS = "0" 
	end
	if ( Settings.FFXIVMINION.gPermaSwiftCast == nil) then
		Settings.FFXIVMINION.gPermaSwiftCast = "0" 
	end
	if ( Settings.FFXIVMINION.gFoodHQ == nil) then
		Settings.FFXIVMINION.gFoodHQ = "None" 
	end
	if ( Settings.FFXIVMINION.gFood == nil) then
		Settings.FFXIVMINION.gFood = "None" 
	end
	if ( Settings.FFXIVMINION.gAvoidAOE == nil) then
		Settings.FFXIVMINION.gAvoidAOE = "0" 
	end
	if (Settings.FFXIVMINION.gRestHP == nil) then
        Settings.FFXIVMINION.gRestHP = "70"
    end
    if (Settings.FFXIVMINION.gRestMP == nil) then
        Settings.FFXIVMINION.gRestMP = "0"
    end
    if (Settings.FFXIVMINION.gFleeHP == nil) then
        Settings.FFXIVMINION.gFleeHP = "20"
    end
    if (Settings.FFXIVMINION.gFleeMP == nil) then
        Settings.FFXIVMINION.gFleeMP = "0"
    end
	if (Settings.FFXIVMINION.gPotionHP == nil) then
        Settings.FFXIVMINION.gPotionHP = "50"
    end
	if (Settings.FFXIVMINION.gPotionMP == nil) then
        Settings.FFXIVMINION.gPotionMP = "0"
    end
	if (Settings.FFXIVMINION.gUseCurielRoot == nil) then
        Settings.FFXIVMINION.gUseCurielRoot = "0"
    end
	if (Settings.FFXIVMINION.gQuestAutoEquip == nil) then
		Settings.FFXIVMINION.gQuestAutoEquip = "1"
	end
	if (Settings.FFXIVMINION.gRandomMovement == nil) then
		Settings.FFXIVMINION.gRandomMovement = "0"
	end
	if (Settings.FFXIVMINION.gAvoidHP == nil) then
        Settings.FFXIVMINION.gAvoidHP = "100"
    end
	Settings.FFXIVMINION.gAdvStealthDetect = Settings.FFXIVMINION.gAdvStealthDetect or 25
	Settings.FFXIVMINION.gAdvStealthRemove = Settings.FFXIVMINION.gAdvStealthRemove or 30
	
	local winName = ffxivminion.Windows.Main.Name
	GUI_NewButton(winName, GetString("skillManager"), "SkillManager.toggle")
    GUI_NewButton(winName, GetString("meshManager"), "ToggleMeshManager")
    GUI_NewButton(winName, GetString("blacklistManager"), "ToggleBlacklistMgr")
	GUI_NewButton(winName, GetString("profileManager"),"QMToggleMain")
	GUI_NewButton(winName, GetString("importExport"), "ToggleImportMgr")
	GUI_NewButton(winName, GetString("multiManager"), "MultiBotManager.toggle")
	GUI_NewButton(winName, GetString("castPrevention"),"CastPrevention.toggle")
	GUI_NewButton(winName, GetString("shortcutManager"),"ShortcutManager.toggle")
	
	local group = GetString("botStatus")
	GUI_NewField(winName,GetString("pulseTime"),"gFFXIVMINIONPulseTime",group )
    GUI_NewCheckbox(winName,GetString("enableLog"),"gEnableLog",group )
    GUI_NewCheckbox(winName,GetString("logCNE"),"gLogCNE",group )
    GUI_NewField(winName,GetString("task"),"gFFXIVMINIONTask",group )
	GUI_NewField(winName,GetString("taskDelay"),"gTaskDelay",group )
	GUI_NewField(winName,GetString("idlePulseCount"),"gIdlePulseCount",group )
	GUI_NewField(winName,GetString("eorzeaTime"),"gEorzeaTime", group)
	
	local group = GetString("generalSettings")
    GUI_NewCheckbox(winName,GetString("autoStartBot"),"gAutoStart",group)
	GUI_NewCheckbox(winName,GetString("autoEquip"),"gQuestAutoEquip",group)
	GUI_NewCheckbox(winName,GetString("useMount"),"gUseMount",group )
	GUI_NewComboBox(winName,GetString("mount"), "gMount",group,GetMounts())
    GUI_NewNumeric(winName,GetString("mountDist"),"gMountDist",group )
    GUI_NewCheckbox(winName,GetString("useSprint"),"gUseSprint",group )
    GUI_NewNumeric(winName,GetString("sprintDist"),"gSprintDist",group )
	GUI_NewComboBox(winName,GetString("companion"), "gChoco",group,"")
	GUI_NewCheckbox(winName,GetString("curielRoot"),"gUseCurielRoot",group )
	gChoco_listitems = GetString("none")..","..GetString("grindMode")..","..GetString("assistMode")..","..GetString("questMode")..","..GetString("any")
	GUI_NewComboBox(winName,GetString("stance"),"gChocoStance",group,"")
	gChocoStance_listitems = GetString("stFree")..","..GetString("stDefender")..","..GetString("stAttacker")..","..GetString("stHealer")..","..GetString("stFollow")
	GUI_NewComboBox(winName,GetString("food"),"gFood", group, "None")
	GUI_NewComboBox(winName,GetString("foodHQ"),"gFoodHQ", group, "None")
	GUI_NewCheckbox(winName,GetString("avoidAOE"), "gAvoidAOE",group )
	GUI_NewCheckbox(winName,GetString("randomPaths"),"gRandomPaths",group )
	GUI_NewCheckbox(winName,GetString("randomMovement"),"gRandomMovement",group )
	GUI_NewCheckbox(winName,GetString("doUnstuck"),"gDoUnstuck",group )
	GUI_NewCheckbox(winName,GetString("useHQMats"),"gUseHQMats",group )
	
	local group = GetString("playerHPMPTP")
	GUI_NewNumeric(winName, GetString("avoidHP"), "gAvoidHP", group, "0", "100")
	GUI_NewNumeric(winName, GetString("restHP"), "gRestHP", group, "0", "100")
    GUI_NewNumeric(winName, GetString("restMP"), "gRestMP", group, "0", "100")
	GUI_NewNumeric(winName, GetString("potionHP"), "gPotionHP", group, "0", "100")
	GUI_NewNumeric(winName, GetString("potionMP"), "gPotionMP", group, "0", "100")
    GUI_NewNumeric(winName, GetString("fleeHP"), "gFleeHP", group, "0", "100")
    GUI_NewNumeric(winName, GetString("fleeMP"), "gFleeMP", group, "0", "100")
	
	local group = GetString("hacks")
	GUI_NewCheckbox(winName,GetString("repair"),"gRepair",group)
	GUI_NewCheckbox(winName,GetString("disabledrawing"),"gDisableDrawing",group)
	GUI_NewCheckbox(winName,GetString("teleport"),"gTeleport",group)
	GUI_NewCheckbox(winName,GetString("paranoid"),"gParanoid",group)
	GUI_NewCheckbox(winName,GetString("permaSprint"), "gGatherPS",group)
	GUI_NewCheckbox(winName,GetString("permaSwiftcast"),"gPermaSwiftCast",group)
    GUI_NewCheckbox(winName,GetString("skipCutscene"),"gSkipCutscene",group )
	GUI_NewCheckbox(winName,GetString("skipDialogue"),"gSkipDialogue",group )
	GUI_NewCheckbox(winName,GetString("clickToTeleport"),"gClickToTeleport",group)
	GUI_NewCheckbox(winName,GetString("clickToTravel"),"gClickToTravel",group)
	
	local group = GetString("advancedSettings")
	GUI_NewNumeric(winName, "Stealth Detect Range", "gAdvStealthDetect", group, "1", "100")
	GUI_NewNumeric(winName, "Stealth Remove Range", "gAdvStealthRemove", group, "1", "100")
	GUI_NewButton(winName, "Use Defaults", "ffxivminion.ResetAdvancedDefaults",group)
	
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gEnableLog = Settings.FFXIVMINION.gEnableLog
    gFFXIVMINIONPulseTime = Settings.FFXIVMINION.gFFXIVMINIONPulseTime
    gUseMount = Settings.FFXIVMINION.gUseMount
    gUseSprint = Settings.FFXIVMINION.gUseSprint
    gMountDist = Settings.FFXIVMINION.gMountDist
    gSprintDist = Settings.FFXIVMINION.gSprintDist
    gRandomPaths = Settings.FFXIVMINION.gRandomPaths
	gRandomMovement = Settings.FFXIVMINION.gRandomMovement
	gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
	gQuestAutoEquip = Settings.FFXIVMINION.gQuestAutoEquip
    gAutoStart = Settings.FFXIVMINION.gAutoStart
    gSkipCutscene = Settings.FFXIVMINION.gSkipCutscene
    gSkipDialogue = Settings.FFXIVMINION.gSkipDialogue
	gAvoidAOE = Settings.FFXIVMINION.gAvoidAOE
    gDoUnstuck = Settings.FFXIVMINION.gDoUnstuck
    gUseHQMats = Settings.FFXIVMINION.gUseHQMats	
    gClickToTeleport = Settings.FFXIVMINION.gClickToTeleport
    gClickToTravel = Settings.FFXIVMINION.gClickToTravel
	gChoco = Settings.FFXIVMINION.gChoco
	gChocoStance = Settings.FFXIVMINION.gChocoStance
	gMount = Settings.FFXIVMINION.gMount
	gRepair = Settings.FFXIVMINION.gRepair
	gTeleport = Settings.FFXIVMINION.gTeleport
	gParanoid = Settings.FFXIVMINION.gParanoid
	gGatherPS = Settings.FFXIVMINION.gGatherPS
	gPermaSwiftCast = Settings.FFXIVMINION.gPermaSwiftCast
	gFoodHQ = Settings.FFXIVMINION.gFoodHQ
	gFood = Settings.FFXIVMINION.gFood
	gAvoidHP = Settings.FFXIVMINION.gAvoidHP
	gRestHP = Settings.FFXIVMINION.gRestHP
    gRestMP = Settings.FFXIVMINION.gRestMP
    gFleeHP = Settings.FFXIVMINION.gFleeHP
    gFleeMP = Settings.FFXIVMINION.gFleeMP
	gPotionHP = Settings.FFXIVMINION.gPotionHP
	gPotionMP = Settings.FFXIVMINION.gPotionMP
	gUseCurielRoot = Settings.FFXIVMINION.gUseCurielRoot
	
	gAdvStealthDetect = Settings.FFXIVMINION.gAdvStealthDetect
	gAdvStealthRemove = Settings.FFXIVMINION.gAdvStealthRemove
	
	if (ValidTable(Settings.FFXIVMINION.itemIDsToEquip)) then
		ml_global_information.itemIDsToEquip = Settings.FFXIVMINION.itemIDsToEquip
	end
	
	if (ValidTable(ffxivminion.modesToLoad)) then
		ffxivminion.LoadModes()
	end
	
	gFFXIVMINIONTask = ""
    gBotRunning = "0"
	ml_global_information.lastMode = gBotMode
    
    -- setup parent window for minionlib modules
    ml_marker_mgr.parentWindow = ml_global_information.MainWindow
    ml_blacklist_mgr.parentWindow = ml_global_information.MainWindow
    
    -- setup/load blacklist tables
    ml_blacklist_mgr.path = GetStartupPath() .. [[\LuaMods\ffxivminion\blacklist.info]]
    ml_blacklist_mgr.ReadBlacklistFile(ml_blacklist_mgr.path)
    
    if not ml_blacklist.BlacklistExists(GetString("fates")) then
        ml_blacklist.CreateBlacklist(GetString("fates"))
    end
	
	if not ml_blacklist.BlacklistExists("FATE Whitelist") then
        ml_blacklist.CreateBlacklist("FATE Whitelist")
    end
    
    if not ml_blacklist.BlacklistExists(GetString("monsters")) then
        ml_blacklist.CreateBlacklist(GetString("monsters"))
    end
    
    if not ml_blacklist.BlacklistExists(GetString("gatherMode")) then
        ml_blacklist.CreateBlacklist(GetString("gatherMode"))
    end
	
	if not ml_blacklist.BlacklistExists(GetString("huntMonsters")) then
		ml_blacklist.CreateBlacklist(GetString("huntMonsters"))
	end
	
	if not ml_blacklist.BlacklistExists(GetString("aoe")) then
		ml_blacklist.CreateBlacklist(GetString("aoe"))
	end
	
	-- setup marker manager callbacks and vars
	ml_marker_mgr.GetPosition = 	function () return Player.pos end
	ml_marker_mgr.GetLevel = 		function () return Player.level end
	ml_marker_mgr.DrawMarker =		ffxivminion.DrawMarker
	ml_marker_mgr.markerPath = 		ml_global_information.path.. [[\Navigation\]]
	ml_node.DistanceTo	= 			ffxivminion.NodeDistance
	
-- setup meshmanager
	if ( ml_mesh_mgr ) then
		ml_mesh_mgr.parentWindow.Name = ml_global_information.MainWindow.Name
		ml_mesh_mgr.GetMapID = function () return Player.localmapid end
		ml_mesh_mgr.GetMapName = function () return "" end  -- didnt we have a mapname somewhere?
		ml_mesh_mgr.GetPlayerPos = function () return Player.pos end
		ml_mesh_mgr.SetEvacPoint = function ()
			if (gmeshname ~= "" and Player.onmesh) then
				ml_marker_mgr.markerList["evacPoint"] = shallowcopy(Player.pos)
				ml_marker_mgr.WriteMarkerFile(ml_marker_mgr.markerPath)
			end
		end
		ml_mesh_mgr.IsValidGameState = function ()
			return (not IsLoading())
		end
		ml_mesh_mgr.averagegameunitsize = 1
		ml_mesh_mgr.useQuaternion = false
		
	-- Set default meshes SetDefaultMesh(mapid, filename)
		ml_mesh_mgr.SetDefaultMesh(134, "Middle La Noscea")
		ml_mesh_mgr.SetDefaultMesh(135, "Lower La Noscea")
		ml_mesh_mgr.SetDefaultMesh(137, "Eastern La Noscea")
		ml_mesh_mgr.SetDefaultMesh(138, "Western La Noscea")
		ml_mesh_mgr.SetDefaultMesh(139, "Upper La Noscea")
		ml_mesh_mgr.SetDefaultMesh(140, "Western Thanalan")
		ml_mesh_mgr.SetDefaultMesh(141, "Central Thanalan")
		ml_mesh_mgr.SetDefaultMesh(145, "Eastern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(146, "Southern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(147, "Northern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(148, "Central Shroud")
		ml_mesh_mgr.SetDefaultMesh(152, "East Shroud")
		ml_mesh_mgr.SetDefaultMesh(153, "South Shroud")
		ml_mesh_mgr.SetDefaultMesh(154, "North Shroud")
		ml_mesh_mgr.SetDefaultMesh(155, "Coerthas")
		ml_mesh_mgr.SetDefaultMesh(156, "Mor Dhona")
		ml_mesh_mgr.SetDefaultMesh(180, "Outer La Noscea")
		ml_mesh_mgr.SetDefaultMesh(337, "Wolves Den")
		ml_mesh_mgr.SetDefaultMesh(336, "Wolves Den")
		ml_mesh_mgr.SetDefaultMesh(175, "Wolves Den")
		ml_mesh_mgr.SetDefaultMesh(352, "Wolves Den")
		ml_mesh_mgr.SetDefaultMesh(130, "Ul dah - Steps of Nald")
		ml_mesh_mgr.SetDefaultMesh(131, "Ul dah - Steps of Thal")
		ml_mesh_mgr.SetDefaultMesh(128, "Limsa (Upper)")
		ml_mesh_mgr.SetDefaultMesh(129, "Limsa (Lower)")
		ml_mesh_mgr.SetDefaultMesh(132, "New Gridania")
		ml_mesh_mgr.SetDefaultMesh(133, "Old Gridania")
		ml_mesh_mgr.SetDefaultMesh(376, "Frontlines")
		ml_mesh_mgr.SetDefaultMesh(422, "Frontlines - Slaughter")
		ml_mesh_mgr.SetDefaultMesh(212, "Waking Sands")
		ml_mesh_mgr.SetDefaultMesh(179, "Gridania - Inn")
		ml_mesh_mgr.SetDefaultMesh(178, "Ul dah - Inn")
		ml_mesh_mgr.SetDefaultMesh(177, "Limsa Lominsa - Inn")
		
		ml_mesh_mgr.SetDefaultMesh(181, "Limsa (Lower)")
		ml_mesh_mgr.SetDefaultMesh(182, "Ul dah - Steps of Nald")
		ml_mesh_mgr.SetDefaultMesh(183, "New Gridania")
		
		ml_mesh_mgr.SetDefaultMesh(203, "Ul dah - Heart of the Sworn")
		ml_mesh_mgr.SetDefaultMesh(205, "Lotus Stand")
		ml_mesh_mgr.SetDefaultMesh(204, "Limsa Lominsa - Command")
		
		ml_mesh_mgr.SetDefaultMesh(144, "Gold Saucer")
		-- Duties
		--ml_mesh_mgr.SetDefaultMesh(397, "Coerthas Western Highlands")
		--ml_mesh_mgr.SetDefaultMesh(339, "Mist")
		--ml_mesh_mgr.SetDefaultMesh(340, "Lavender Beds")
		--ml_mesh_mgr.SetDefaultMesh(341, "The Goblet")
				
		ml_mesh_mgr.InitMarkers() -- Update the Markers-group in the mesher UI
	end
	
	-- gAutoStart
	if ( gAutoStart == "1" ) then
		ml_global_information.autoStartQueued = true		
	end
	if (gDisableDrawing == "1" ) then
		GameHacks:Disable3DRendering(true)
	end
    if (gSkipCutscene == "1" ) then
        --GameHacks:SkipCutscene(true)
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
	if (gGatherPS == "1") then
        GameHacks:SetPermaSprint(true)
    end
	if (gPermaSwiftCast == "1") then
        GameHacks:SetPermaSwiftCast(true)
    end
	
	NavigationManager:SetAreaCost(3,5)
	
	ffxivminion.UpdateFoodOptions()
end

function ffxivminion.GUIVarUpdate(Event, NewVals, OldVals)
	local backupVals = {}
	for k,v in pairs(OldVals) do
		if ( k == "gMount") then
			backupVals.gMount = v
		end
	end
	
    for k,v in pairs(NewVals) do
        if ( k == "gBotMode" ) then
            ffxivminion.SwitchMode(v)
			SafeSetVar(tostring(k),v)
        end
        if (k == "gEnableLog") then
            if ( v == "1" ) then
                gFFXIVMINIONPulseTime = 1000
            else
                gFFXIVMINIONPulseTime = Settings.FFXIVMINION.gFFXIVMINIONPulseTime
            end
			SafeSetVar(tostring(k),v)
		elseif (
			k == "gRestHP" or
            k == "gRestMP" or
            k == "gFleeHP" or
            k == "gFleeMP" or
			k == "gPotionHP" or
            k == "gPotionMP" or 
			k == "gUseSprint")
		then
			ffxivminion.SaveClassSettings(tostring(k),v)
			SafeSetVar(tostring(k),v)
        elseif (
            k == "gLogCNE" or
            k == "gFFXIVMINIONPulseTime" or
            k == "gBotMode" or 
            k == "gMountDist" or
            k == "gAssistMode" or
            k == "gAssistPriority" or
            k == "gSprintDist" or
			k == "gAutoStart" or
			k == "gStartCombat" or
			k == "gConfirmDuty" or
            k == "gDoUnstuck" or
            k == "gRandomPaths" or
			k == "gChoco" or
			k == "gChocoStance" or
			k == "gMount" or
			k == "gTeleport" or
			k == "gParanoid" or
			k == "gQuestHelpers" or
			k == "gRepair" or 
			k == "gUseAetherytes" or
			k == "gFood" or
			k == "gFoodHQ" or 
			k == "gAvoidAOE" or
			k == "gDevDebug" or
			k == "gUseCurielRoot" or
			k == "gAvoidHP" or
			k == "gAdvStealthDetect" or
			k == "gAdvStealthRemove"
			)				
        then
			SafeSetVar(tostring(k),v)
		elseif ( k == "gMount" ) then
			if ( v == GetString("none") and Player.ismounted and gBotRunning == "1" ) then
				ml_error("Cannot change mounts while mounted.")
				SetGUIVar("gMount",backupVals.gMount)
			else
				SafeSetVar(tostring(k),v)
			end
		elseif ( k == "gUseMount" )	then
			if ( v == "1") then
				local mountFound = false
				local mountlist = ActionList("type=13")
				if (ValidTable(mountlist)) then
					--Check to see that the mount we have selected is valid first.
					if (gMount ~= GetString("none")) then
						for k,v in pairsByKeys(mountlist) do
							if (v.name == gMount) then
								local acMount = ActionList:Get(v.id,13)
								if (acMount and acMount.isready) then
									mountFound = true
								end
							end
							if (mountFound) then
								break
							end
						end
					end
					
					--If it's not valid, pick the first available mount that we do have.
					if (not mountFound) then
						for k,v in pairsByKeys(mountlist) do
							local acMount = ActionList:Get(v.id,13)
							if (acMount and acMount.isready) then
								mountFound = true
								SetGUIVar("gMount", v.name)
							end
							if (mountFound) then
								break
							end
						end		
					end
				end
				--If we still haven't found a mount, disable mount usage so it doesn't cause nav issues.
				if (not mountFound) then
					ml_error("No usable mounts found, disabling mount for now.")
					SetGUIVar("gUseMount","0")
				else
					SafeSetVar(tostring(k),v)
				end
			else
				SafeSetVar(tostring(k),v)
			end
		end
		
        if ( k == "gBotRunning" ) then
            ml_task_hub.ToggleRun()
		end
		
		if ( k == "gDisableDrawing" ) then
			if ( v == "1" ) then
				GameHacks:Disable3DRendering(true)
			else
				GameHacks:Disable3DRendering(false)
			end
			SafeSetVar(tostring(k),v)
		end
		
		if ( k == "gSkipCutscene" ) then
			if ( v == "1" ) then
				GameHacks:SkipCutscene(true)
			else
				GameHacks:SkipCutscene(false)
			end
            SafeSetVar(tostring(k),v)
		end
		
		if ( k == "gSkipDialogue" ) then
			if ( v == "1" ) then
				GameHacks:SkipDialogue(true)
			else
				GameHacks:SkipDialogue(false)
			end
            SafeSetVar(tostring(k),v)
		end
		
        if ( k == "gClickToTeleport" ) then
			if ( v == "1" ) then
				GameHacks:SetClickToTeleport(true)
			else
				GameHacks:SetClickToTeleport(false)
			end
            SafeSetVar(tostring(k),v)
		end
		
        if ( k == "gClickToTravel" ) then
			if ( v == "1" ) then
				GameHacks:SetClickToTravel(true)
			else
				GameHacks:SetClickToTravel(false)
			end
            SafeSetVar(tostring(k),v)
		end
		
		if ( k == "gUseHQMats" ) then
			if ( v == "1" ) then
				Crafting:UseHQMats(true)
			else
				Crafting:UseHQMats(false)
			end
            SafeSetVar(tostring(k),v)
		end
		
		if ( k == "gGatherPS" ) then
            if ( v == "1") then
                GameHacks:SetPermaSprint(true)
            else
                GameHacks:SetPermaSprint(false)
            end
			SafeSetVar(tostring(k),v)
        end
		
		if ( k == "gPermaSwiftCast" ) then
            if ( v == "1") then
                GameHacks:SetPermaSwiftCast(true)
            else
                GameHacks:SetPermaSwiftCast(false)
            end
			SafeSetVar(tostring(k),v)
        end
    end
    GUI_RefreshWindow(ffxivminion.Windows.Main.Name)
end

function ffxivminion.SwitchMode(mode)	
	local task = ffxivminion.modes[mode]
    if (task ~= nil) then
		if (gBotMode ~= mode) then
			gBotMode = mode
			Settings.FFXIVMINION.gBotMode = gBotMode
		end
		
		if (gBotRunning == "1") then
			ml_task_hub.ToggleRun()
		end
	
		local wnd = nil
		if (ml_global_information.lastMode ~= mode and ml_global_information.lastMode ~= "") then
			wnd = GUI_GetWindowInfo(ml_global_information.lastMode)
			GUI_WindowVisible(ml_global_information.lastMode, false)
		end
		
		if (wnd) then
			GUI_MoveWindow(mode, wnd.x, wnd.y)
		end
		
		ffxivminion.SizeWindow(mode)
		GUI_WindowVisible(mode, true)
		ml_global_information.lastMode = mode
		
		if (gBotMode == GetString("pvpMode")) then
            Player:EnableUnstuckJump(false)
        else
            Player:EnableUnstuckJump(true)
        end
		
		--Set marker type to the appropriate type.
		if (gBotMode == GetString("gatherMode")) then
			if (gGatherUnspoiled == "1") then
				ml_marker_mgr.SetMarkerType(GetString("unspoiledMarker"))
			elseif (Player.job == FFXIV.JOBS.BOTANIST) then
				ml_marker_mgr.SetMarkerType(GetString("botanyMarker"))
			else
				ml_marker_mgr.SetMarkerType(GetString("miningMarker"))
			end
		elseif (gBotMode == GetString("huntMode")) then
			ml_marker_mgr.SetMarkerType(GetString("huntMarker"))
		elseif (gBotMode == GetString("fishMode")) then
			ml_marker_mgr.SetMarkerType(GetString("fishingMarker"))
		elseif (gBotMode == GetString("grindMode") or gBotMode == GetString("partyMode")) then
			ml_marker_mgr.SetMarkerType(GetString("grindMarker"))
		elseif (gBotMode == GetString("pvpMode")) then
			ml_marker_mgr.SetMarkerType(GetString("pvpMarker"))
		end
		
		--Setup default options.
		if (gBotMode == GetString("dutyMode")) then
			gTeleport = "1"
			gParanoid = "0"
			ffxiv_task_duty.UpdateProfiles()
			--gSkipCutscene = "1"
			gSkipDialogue = "1"
			gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
			GameHacks:SkipCutscene(gSkipCutscene == "1")
			GameHacks:SkipDialogue(gSkipDialogue == "1")
			GameHacks:Disable3DRendering(gDisableDrawing == "1")
			SendTextCommand("/busy off")
			gQuestAutoEquip = Settings.FFXIVMINION.gQuestAutoEquip
		elseif (gBotMode == GetString("questMode")) then
			if (Questing) then
				Questing.UpdateProfiles()
			end
			gTeleport = Settings.FFXIVMINION.gTeleport
			gParanoid = Settings.FFXIVMINION.gParanoid
			--gSkipCutscene = "1"
			gSkipDialogue = "1"
			gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
			GameHacks:SkipCutscene(gSkipCutscene == "1")
			GameHacks:SkipDialogue(gSkipDialogue == "1")
			GameHacks:Disable3DRendering(gDisableDrawing == "1")
			gAvoidAOE = "1"
			gQuestAutoEquip = "1"
		elseif (gBotMode == GetString("grindMode") or gBotMode == GetString("partyMode")) then
			gTeleport = Settings.FFXIVMINION.gTeleport
			gParanoid = Settings.FFXIVMINION.gParanoid
			gGrindDoHuntLog = Settings.FFXIVMINION.gGrindDoHuntLog
			gDoFates = Settings.FFXIVMINION.gDoFates
			gFatesOnly = Settings.FFXIVMINION.gFatesOnly
			gMinFateLevel = Settings.FFXIVMINION.gMinFateLevel
			gMaxFateLevel = Settings.FFXIVMINION.gMaxFateLevel
			gDoBattleFates = Settings.FFXIVMINION.gDoBattleFates
			gDoBossFates = Settings.FFXIVMINION.gDoBossFates
			gDoGatherFates = Settings.FFXIVMINION.gDoGatherFates
			gDoDefenseFates = Settings.FFXIVMINION.gDoDefenseFates
			gDoEscortFates = Settings.FFXIVMINION.gDoEscortFates
			gFateBattleWaitPercent = Settings.FFXIVMINION.gFateBattleWaitPercent
			gFateBossWaitPercent = Settings.FFXIVMINION.gFateBossWaitPercent
			gFateDefenseWaitPercent = Settings.FFXIVMINION.gFateDefenseWaitPercent
			gSkipCutscene = Settings.FFXIVMINION.gSkipCutscene
			gSkipDialogue = Settings.FFXIVMINION.gSkipDialogue
			gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
			GameHacks:SkipCutscene(gSkipCutscene == "1")
			GameHacks:SkipDialogue(gSkipDialogue == "1")
			GameHacks:Disable3DRendering(gDisableDrawing == "1")
			gAvoidAOE = "1"
			gProfile_listitems = "NA"
			gProfile = "NA"
			gQuestAutoEquip = Settings.FFXIVMINION.gQuestAutoEquip
		else
			gTeleport = Settings.FFXIVMINION.gTeleport
			gParanoid = Settings.FFXIVMINION.gParanoid
			gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
			gSkipCutscene = Settings.FFXIVMINION.gSkipCutscene
			gSkipDialogue = Settings.FFXIVMINION.gSkipDialogue
			GameHacks:SkipCutscene(gSkipCutscene == "1")
			GameHacks:SkipDialogue(gSkipDialogue == "1")
			GameHacks:Disable3DRendering(gDisableDrawing == "1")
			gAvoidAOE = Settings.FFXIVMINION.gAvoidAOE
			gProfile_listitems = "NA"
			gProfile = "NA"
			gQuestAutoEquip = Settings.FFXIVMINION.gQuestAutoEquip
		end
	end
end

function ffxivminion.SetMode(mode)
    local task = ffxivminion.modes[mode]
    if (task ~= nil) then
		GameHacks:SkipCutscene(gSkipCutscene == "1")
		GameHacks:SkipDialogue(gSkipDialogue == "1")
		ml_task_hub:Add(task.Create(), LONG_TERM_GOAL, TP_ASAP)
    end
end

function ffxivminion.VerifyClassSettings()
	--Perform initial load.
	ffxivminion.LoadClassSettings()
	
	local currentClass = ml_global_information.CurrentClass
	if (currentClass) then
		local classOptions = currentClass.options
		if (not classOptions) then
			d("[VerifyClassSettings]: Options does not exist, creating fresh table.")
			currentClass.options = {}
			classOptions = currentClass.options
		end
		
		local classSettings = classOptions.settings
		if (not classSettings) then
			d("[VerifyClassSettings]: Settings does not exist, creating fresh table.")
			classOptions.settings = {}
			classSettings = classOptions.settings
		end
		
		local settingsTemplate = {
			["gRestHP"] = true,
			["gRestMP"] = true,
			["gPotionHP"] = true,
			["gPotionMP"] = true,
			["gFleeHP"] = true,
			["gFleeMP"] = true,
			["gUseSprint"] = true,
		}
		
		local requiredUpdate = false
		for name,value in pairs(settingsTemplate) do
			if (not classSettings[name]) then
				d("[VerifyClassSettings]: Setting ["..name.."] does not exist, creating fresh instance from global variable.")
				classSettings[name] = _G[name]
				if (not requiredUpdate) then
					requiredUpdate = true
				end
			end
		end
		if (requiredUpdate) then
			d("VerifyClassSettings: Saving altered settings in : "..tostring(currentClass.optionsPath))
			persistence.store(currentClass.optionsPath,classOptions)
			
			--Reload settings if they were altered.
			ffxivminion.LoadClassSettings()
		end
	end
end

function ffxivminion.SaveClassSettings(strName, value)
	local currentClass = ml_global_information.CurrentClass
	if (currentClass) then
		local classOptions = currentClass.options
		if (classOptions) then
			local classSettings = classOptions.settings
			if (classSettings) then
				classSettings[strName] = value
				--d("SaveClassSettings: Saving settings in : "..tostring(currentClass.optionsPath))
				persistence.store(currentClass.optionsPath,classOptions)
			end
		end
	end
end

function ffxivminion.LoadClassSettings()
	local currentClass = ml_global_information.CurrentClass
	if (currentClass) then
		local optionsPath = currentClass.optionsPath
		local options,e = persistence.load(optionsPath)
		if (options) then
			currentClass.options = options
			d("[LoadClassSettings] : Loaded class options file.")
			if not (options.settings) then
				d("[LoadClassSettings] : Unable to find settings table in options file.")
			end
		else
			d("[LoadClassSettings] :"..e)
		end
	else
		d("[LoadClassSettings]: currentClass was invalid.")
	end
end

function ffxivminion.UseClassSettings()
	local currentClass = ml_global_information.CurrentClass
	if (currentClass) then
		local classOptions = currentClass.options
		if (classOptions) then
			local classSettings = classOptions.settings
			if (classSettings) then
				for name,value in pairs(classSettings) do
					_G[name] = value
					Settings.FFXIVMINION[name] = value
				end
			end
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
		[FFXIV.JOBS.NINJA] 			= ffxiv_combat_ninja,
		[FFXIV.JOBS.ROGUE]			= ffxiv_combat_rogue,
        [FFXIV.JOBS.PALADIN] 		= ffxiv_combat_paladin,
        [FFXIV.JOBS.PUGILIST] 		= ffxiv_combat_pugilist,
        [FFXIV.JOBS.SCHOLAR] 		= ffxiv_combat_scholar,
        [FFXIV.JOBS.SUMMONER] 		= ffxiv_combat_summoner,
        [FFXIV.JOBS.THAUMATURGE] 	= ffxiv_combat_thaumaturge,
        [FFXIV.JOBS.WARRIOR] 	 	= ffxiv_combat_warrior,
        [FFXIV.JOBS.WHITEMAGE] 	 	= ffxiv_combat_whitemage,
		[FFXIV.JOBS.ROGUE]			= ffxiv_combat_rogue,
		[FFXIV.JOBS.NINJA]			= ffxiv_combat_ninja,
		[FFXIV.JOBS.MACHINIST]		= ffxiv_combat_machinist,
		[FFXIV.JOBS.DARKKNIGHT]		= ffxiv_combat_darkknight,
		[FFXIV.JOBS.ASTROLOGIAN]	= ffxiv_combat_astrologian,		
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
	
	local playerClass = classes[Player.job]
	if (not playerClass) then
		ffxiv_dialog_manager.IssueStopNotice("FFXIV_CheckClass_InvalidClass", "Missing class routine file.")
		return
	end
	
	if (ml_global_information.CurrentClass == nil) then
		ml_global_information.CurrentClass = playerClass
		ml_global_information.CurrentClassID = Player.job
		ml_global_information.AttackRange = playerClass.range or 2
		SkillMgr.UseDefaultProfile()
		ffxivminion.VerifyClassSettings()
		ffxivminion.UseClassSettings()
		return
	end
    
    --TODO check which class we are currently using and modify globals appropriately
    if (ml_global_information.CurrentClassID ~= Player.job) then
        ml_global_information.CurrentClass = playerClass
        ml_global_information.CurrentClassID = Player.job
		ml_global_information.AttackRange = playerClass.range or 2
		SkillMgr.UseDefaultProfile()
		ffxivminion.VerifyClassSettings()
		ffxivminion.UseClassSettings()
		
		-- autosetting the correct botmode
		local newModeName = ""
		if ( ml_global_information.CurrentClass == ffxiv_gather_botanist or ml_global_information.CurrentClass == ffxiv_gather_miner) then
			newModeName = GetString("gatherMode")
		elseif ( ml_global_information.CurrentClass == ffxiv_gather_fisher ) then
			newModeName = GetString("fishMode")
		elseif ( ml_global_information.CurrentClass == ffxiv_crafting_carpenter or ml_global_information.CurrentClass == ffxiv_crafting_blacksmith 
				or ml_global_information.CurrentClass == ffxiv_crafting_armorer or ml_global_information.CurrentClass == ffxiv_crafting_goldsmith
				or ml_global_information.CurrentClass == ffxiv_crafting_leatherworker or ml_global_information.CurrentClass == ffxiv_crafting_weaver
				or ml_global_information.CurrentClass == ffxiv_crafting_alchemist or ml_global_information.CurrentClass == ffxiv_crafting_culinarian) then
			newModeName = GetString("craftMode")
		--default it to Grind if crafting/gathering/fishing mode was selected but we are not in that class
		elseif ( gBotMode == GetString("gatherMode") or gBotMode == GetString("fishMode") or gBotMode == GetString("craftMode")) then
			newModeName = GetString("grindMode")				
		end
					
		if (gBotMode ~= newModeName and newModeName ~= "") then
			ffxivminion.SwitchMode(newModeName)
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

function ffxivminion.CreateWindows()
	for i,window in pairs(ffxivminion.Windows) do
		local winTable = "AutoWindow"..window.id
		if (Settings.FFXIVMINION[winTable] == nil) then
			Settings.FFXIVMINION[winTable] = {}
		end
		
		settings = {}			
		settings.width = Settings.FFXIVMINION[winTable].width or window.width
		settings.height = Settings.FFXIVMINION[winTable].height or window.height
		settings.y = Settings.FFXIVMINION[winTable].y or window.y
		settings.x = Settings.FFXIVMINION[winTable].x or window.x		

		if (ValidTable(settings)) then Settings.FFXIVMINION[winTable] = settings end
		local wi = Settings.FFXIVMINION[winTable]		
		local wname = window.Name
		
		GUI_NewWindow	(wname,wi.x,wi.y,wi.width,wi.height) 
	end
end

function ffxivminion.CreateWindow(window)
	assert(type(window) == "table" and window.id and window.x and window.y and window.width and window.height and window.Name,"[CreateWindow]: Window is malformed or missing data.")
	
	local winTable = "AutoWindow"..window.id
	if (Settings.FFXIVMINION[winTable] == nil) then
		Settings.FFXIVMINION[winTable] = {}
	end

	settings = {}
	settings.width = Settings.FFXIVMINION[winTable].width or window.width
	settings.height = Settings.FFXIVMINION[winTable].height or window.height
	settings.y = Settings.FFXIVMINION[winTable].y or window.y
	settings.x = Settings.FFXIVMINION[winTable].x or window.x

	if (ValidTable(settings)) then
		SafeSetVar(winTable,settings)
	end
	
	local wi = Settings.FFXIVMINION[winTable]
	local wname = window.Name
	
	if (ValidTable(wi)) then
		if (window.hideModule) then
			GUI_NewWindow	(wname,wi.x,wi.y,wi.width,wi.height,"",true)
		else
			GUI_NewWindow	(wname,wi.x,wi.y,wi.width,wi.height)
		end
	end
end

function ffxivminion.SizeWindow(strName)
	local window = nil
	for i, wnd in pairs(ffxivminion.Windows) do
		if (wnd.Name == strName) then
			window = wnd
		end
	end
	
	if (window) then
		local winTableName = "AutoWindow"..window.id
		local winTable = Settings.FFXIVMINION[winTableName]
		GUI_SizeWindow(strName,winTable.width,winTable.height)
	end
end

function ffxivminion.GetWindowSize(strName)
	local window = nil
	for i, wnd in pairs(ffxivminion.Windows) do
		if (wnd.Name == strName) then
			window = wnd
		end
	end
	
	local winTableName = "AutoWindow"..window.id
	local winTable = Settings.FFXIVMINION[winTableName]
	return winTable
end

function ffxivminion.SaveWindows()
	for i,window in pairs(ffxivminion.Windows) do
		if (IsValidWindow(window)) then
			local winid = window.id or "unknown"
			local tableName = "AutoWindow".. winid
			local WI = Settings.FFXIVMINION[tableName]
			local W = GUI_GetWindowInfo(window.Name)
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
		else
			d(tostring(window.id or "unknown").." was invalid.")
		end
	end
end

function ffxivminion.OpenSettings()
	local wnd = GUI_GetWindowInfo(gBotMode)
	local winName = ffxivminion.Windows.Main.Name
	
	GUI_MoveWindow(winName,wnd.x+wnd.width,wnd.y)
	local winTable = ffxivminion.GetWindowSize(winName)
	GUI_SizeWindow(winName,wnd.width,winTable.height)
	GUI_WindowVisible(winName,true)
end

function ffxivminion.UpdateFood(var)
	if (var == "gFood") then
		gFoodHQ = "None"
		SafeSetVar("gFoodHQ",gFoodHQ)
	elseif (var == "gFoodHQ") then
		gFood = "None"
		SafeSetVar("gFood",gFood)
	end		
end

function ffxivminion.UpdateFoodOptions()
    
	local foodlistHQ = "None"
    local foodlist = "None"	
	for x = 0, 3 do
		local inv = Inventory("category=5,type="..tostring(x))
		if ( inv ) then
			for i, item in pairs(inv) do
				if (item.id > 10000) then
					if (ffxivminion.foodsHQ[item.name] ~= item.id) then
						ffxivminion.foodsHQ[item.name] = item.id 
					end
					foodlistHQ = foodlistHQ..","..item.name
				else
					if (ffxivminion.foods[item.name] ~= item.id) then
						ffxivminion.foods[item.name] = item.id
					end
					foodlist = foodlist..","..item.name
				end
			end
		end
	end
	
    gFood_listitems = foodlist
	gFoodHQ_listitems = foodlistHQ
	
	if (ffxivminion.foodsHQ[gFoodHQ] == nil) then
		gFoodHQ = "None"
		SafeSetVar("gFoodHQ",gFoodHQ)
	end
	if (ffxivminion.foods[gFood] == nil) then
		gFood = "None"
		SafeSetVar("gFood",gFood)
	end
	
	GUI_RefreshWindow(ffxivminion.Windows.Main.Name)
end

function ml_global_information.Reset()
    ml_task_hub:ClearQueues()
    ffxivminion.CheckMode()
end

function ml_global_information.Stop()
    if (Player:IsMoving()) then
        Player:Stop()
    end
	GameHacks:SkipCutscene(gSkipCutscene == "1")
	GameHacks:SkipDialogue(gSkipDialogue == "1")
end

function ffxivminion.ToggleAdvancedSettings()
    if (ffxivminion.settingsVisible) then
        GUI_WindowVisible(GetString("advancedSettings"),false)	
        ffxivminion.settingsVisible = false
    else
        local wnd = GUI_GetWindowInfo(ffxivminion.Windows.Main.Name)	
        GUI_MoveWindow( GetString("advancedSettings"), wnd.x+wnd.width,wnd.y) 
        GUI_WindowVisible(GetString("advancedSettings"),true)	
        ffxivminion.settingsVisible = true
    end
end

function ffxivminion.ResetAdvancedDefaults()
	Settings.FFXIVMINION.gAdvStealthDetect = 25
	gAdvStealthDetect = Settings.FFXIVMINION.gAdvStealthDetect
	
	Settings.FFXIVMINION.gAdvStealthRemove = 30
	gAdvStealthRemove = Settings.FFXIVMINION.gAdvStealthRemove
end

function ffxivminion.ResizeWindow()
	GUI_SizeWindow(ffxivminion.Windows.Main.Name,ml_global_information.MainWindow.width,ml_global_information.MainWindow.height)
end

function ffxivminion.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" and string.find(Button,"Field_") ~= nil ) then
		if (Button == "Field_Whitelist Target") then
			WhitelistTarget()
		elseif (Button == "Field_Blacklist Target") then
			BlacklistTarget()
		elseif (string.find(Button,"ffxivminion.")) then
			ExecuteFunction(Button)
		end
	end
end

-- Dont know where else to put this
function ffxivminion.DrawMarker(marker)

	local markertype = marker:GetType()
	local pos = marker:GetPosition()
	
    local color = 0
    local s = 1 -- size
    local h = 5 -- height
	
    if ( markertype == GetString("grindMarker") ) then
        color = 1 -- red
    elseif ( markertype == GetString("fishingMarker") ) then
        color = 4 --blue
    elseif ( markertype == GetString("miningMarker") ) then
        color = 7 -- yellow	
    elseif ( markertype == GetString("botanyMarker") ) then
        color = 8 -- orange
	elseif ( markertype == GetString("huntMarker") ) then
		color = 2
    end
    --Building the vertices for the object
    local t = { 
        [1] = { pos.x-s, pos.y+s+h, pos.z-s, color },
        [2] = { pos.x+s, pos.y+s+h, pos.z-s, color  },	
        [3] = { pos.x,   pos.y-s+h,   pos.z, color  },
        
        [4] = { pos.x+s, pos.y+s+h, pos.z-s, color },
        [5] = { pos.x+s, pos.y+s+h, pos.z+s, color  },	
        [6] = { pos.x,   pos.y-s+h,   pos.z, color  },
        
        [7] = { pos.x+s, pos.y+s+h, pos.z+s, color },
        [8] = { pos.x-s, pos.y+s+h, pos.z+s, color  },	
        [9] = { pos.x,   pos.y-s+h,   pos.z, color  },
        
        [10] = { pos.x-s, pos.y+s+h, pos.z+s, color },
        [11] = { pos.x-s, pos.y+s+h, pos.z-s, color  },	
        [12] = { pos.x,   pos.y-s+h,   pos.z, color  },
    }
    
    local id = RenderManager:AddObject(t)	
    return id
end

function ffxivminion.AddMode(name, task)
	ffxivminion.modesToLoad[name] = task
end

function ffxivminion.LoadModes()
	if (ValidTable(ffxivminion.modesToLoad)) then
		for modeName,task in pairs(ffxivminion.modesToLoad) do
			ffxivminion.modes[modeName] = task
			task:UIInit()
		end
		
		-- Empty out the table to prevent reloading.
		ffxivminion.modesToLoad = {}
	end
	
	local botModes = ffxivminion.Strings.BotModes()
	gBotMode_listitems = botModes
	gBotMode = Retranslate(Settings.FFXIVMINION.gBotMode)
	local modeFound = false
	for i, entry in pairs(ffxivminion.modes) do
		if (i == gBotMode) then
			modeFound = true
			break
		end
	end
	
	if (modeFound) then
		ffxivminion.SwitchMode(gBotMode)
	else
		gBotMode = GetString("grindMode")
		ffxivminion.SwitchMode(gBotMode)
	end
end

function ffxivminion.NodeDistance(self, id)
	
	local neighbor = self:GetNeighbor(id)
    if (neighbor) then
		local cost = neighbor.cost or 5
		local levelmin = neighbor.levelmin or 0
		if (levelmin > 0 and Player.level < levelmin and Player:GetSyncLevel() == 0) then
			cost = cost * 3
		end
		local requiredlevel = neighbor.requiredlevel or 0
		if (requiredlevel > 0 and Player.level < requiredlevel and Player:GetSyncLevel() == 0) then
			cost = 999
		end
		if (TableSize(neighbor.gates) == 1 and neighbor.gates[1].a ~= nil) then
			if ((not (Quest:HasQuest(674) and (Quest:GetQuestCurrentStep(674) == 255)) and not Quest:IsQuestCompleted(674)) or
				GilCount() < 100) 
			then
				cost = 999
			end
		end
		if (TableSize(neighbor.gates) == 1 and neighbor.gates[1].b ~= nil) then
			if (GilCount() < 120) then
				cost = 999
			end
		end
		
        return cost
    end
    
    return nil
end

-- clear any addons displayed by social actions like trade/party invites
function ffxivminion.ClearAddons()
	--trade window
	Player:CheckTradeWindow()
	
	--party invite
	if(ControlVisible("_NotificationParty") and ControlVisible("SelectYesno")) then
		if(not ffxivminion.declineTimer) then
			ffxivminion.declineTimer = Now() + math.random(3000,5000)
		elseif(Now() > ffxivminion.declineTimer) then
			if(not ffxivminion.inviteDeclined) then
				PressYesNo(false)
				ffxivminion.inviteDeclined = true
				ffxivminion.declineTimer = Now() + math.random(1000,3000)
			end
		end
	end
end

function ffxivminion.SafeComboBox(var,varlist,default)
	local outputVar = var
	local found = false
	for k in StringSplit(varlist,",") do
		if k == var then
			found = true
		end
		if (found) then
			break
		end
	end
	
	if (not found) then
		outputVar = default
	end
	
	return outputVar
end

function IsValidWindow(window)
	if (ValidTable(window)) then
		if (window.id and window.x and window.y and window.height and window.width and window.Name) then
			return true
		end
	end
	return false
end

function SetGUIVar(strName, value)
	strName = strName or ""
	if (strName ~= "" and _G[strName] ~= nil) then
		_G[strName] = value
		SafeSetVar(strName, value)
	end
end

function SafeSetVar(name, value)
	if (not name or not value or (name and not type(name) == "string")) then
		d("Prevented invalid name from being saved.")
		return false
	end

	local valName = name	
	local currentVal = Settings.FFXIVMINION[valName]
	if (type(value) == "table") then
		if not deepcompare(currentVal,value,true) then
			--d("writing table settings " .. valName)
			if (valName ~= nil and value ~= nil) then
				Settings.FFXIVMINION[valName] = value
			else
				d("Bad setting with name :"..tostring(valName).." was not written.")
			end
		end
	else
		if (currentVal ~= value and value ~= nil) then
			--d("writing " .. value .. " to " .. currentVal)
			if (valName ~= nil and value ~= nil) then
				Settings.FFXIVMINION[valName] = value
			else
				d("Bad setting with name :"..tostring(valName).." was not written.")
			end
		end
	end
end

-- Register Event Handlers
RegisterEventHandler("Module.Initalize",ffxivminion.HandleInit)
RegisterEventHandler("Gameloop.Update",ml_global_information.OnUpdate)
RegisterEventHandler("GUI.Update",ffxivminion.GUIVarUpdate)
RegisterEventHandler("ffxivminion.OpenSettings", ffxivminion.OpenSettings)
RegisterEventHandler("GUI.Item",		ffxivminion.HandleButtons)
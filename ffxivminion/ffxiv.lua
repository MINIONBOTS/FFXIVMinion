ffxivminion = {}
ffxivminion.foods = {}
ffxivminion.foodsHQ = {}
ffxivminion.modes = {}
ffxivminion.modesToLoad = {}

-- Create the main GUI container.
ffxivminion.GUI = {
	main = {
		name = "FFXIVMinion",
		open = true,
		visible = true,
		x = 0, y = 0, width = 0, height = 0,
	},
	main_task = {
		name = "FFXIVMINION_TASK_SECTION",
		open = true,
		visible = true,
		x = 0, y = 0, width = 0, height = 0,
	},
	main_bottom = {
		name = "FFXIVMINION_BOTTOM_BUTTONS",
		open = true,
		visible = true,
	},
	small = {
		name = "FFXIVMINION_MAIN_WINDOW_MINIMIZED",
		open = false,
		visible = true,
	},
	settings = {
		name = "Advanced Settings",
		open = false,
		visible = true,
	},
	current_tab = 1,
	draw_mode = 1,
}

FFXIVMINION = {}
FFXIVMINION.SKILLS = {}

memoize = {}
pmemoize = {}
tasktracking = {}
setmetatable(tasktracking, { __mode = 'v' })

ffxivminion.Strings = {
	BotModes = 
		function ()
			local botModes = ""
			if (ValidTable(ffxivminion.modes)) then
				local modes = ffxivminion.modes
				for i,entry in spairs(modes, function(modes,a,b) return a < b end) do
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
			local meshlist = GetString("none")
			local meshfilelist = {}
			local tmp = FolderList(ml_mesh_mgr.defaultpath)	
			for i,file in pairs (tmp) do
				if ( string.ends(file,".obj") ) then
					local filename = string.trim(file,4)
					table.insert(meshfilelist, ml_mesh_mgr.GetString(filename))
				end
			end			
			
			if ( ValidTable(meshfilelist)) then
				for i,meshname in pairsByKeys(meshfilelist) do
					meshlist = meshlist..","..meshname
				end
			end
			
			return meshlist
		end,
}

ffxivminion.settingsVisible = false

function ml_global_information.OnUpdate( event, tickcount )
    ml_global_information.Now = tickcount
	
	--local gamestate;
	--if (GetGameState and GetGameState()) then
		--gamestate = GetGameState()
	--else
		--gamestate = 1
	--end
	
	-- Switch according to the gamestate
	--if ( gamestate == 1 ) then
		ml_global_information.InGameOnUpdate( event, tickcount );
	--elseif (gamestate == 2 ) then
		--ml_global_information.InTitleScreenOnUpdate( event, tickcount )
	--elseif (gamestate == 3 ) then
		--ml_global_information.InCharacterSelectScreenOnUpdate( event, tickcount )
	--elseif (gamestate == 0 ) then
		--ml_global_information.InOpening( event, tickcount )
	--end
end

function ml_global_information.InOpening( event, tickcount )
	--d("In the game opening.")
end

function ml_global_information.InGameOnUpdate( event, tickcount )
	memoize = {}
	
	if (not Player) then
		return false
	end
	
	if (not ml_global_information.mainLoaded) then
		ffxivminion.CreateMainWindow()
		NavigationManager:SetAreaCost(3,5)
		ffxivminion.UpdateFoodOptions()
		ml_global_information.mainLoaded = true
	end
	
	if (ValidTable(ffxivminion.modesToLoad)) then
		ffxivminion.LoadModes()
		gBotRunning = "0"		
		FFXIV_Common_BotRunning = false
	end
	
	if (ml_global_information.autoStartQueued) then
		ml_global_information.autoStartQueued = false
		ml_task_hub:ToggleRun() -- convert
	end
	
	--collectgarbage()
	gStatusActiveTaskCount = TableSize(tasktracking)
	
	if (ml_global_information.IsYielding()) then
		--d("currently yielding, do not run")
		return false
	end
	
	if (ml_mesh_mgr) then
		if (not Quest:IsLoading()) then
			if (Player) then
				if (ml_global_information.queueLoader == true) then
					ml_global_information.Player_Aetherytes = GetAetheryteList(true)
					ml_global_information.queueLoader = false
				end
			end
			
			ml_mesh_mgr.OMC_Handler_OnUpdate( tickcount )
			
			local currentFile = NavigationManager.CurrentFile
			currentFile = ml_mesh_mgr.GetString(string.gsub(currentFile,ml_mesh_mgr.defaultpath.."\\", ""))
			if (currentFile ~= gmeshname) then
				gmeshname = currentFile
			end
		else
			if (ml_global_information.queueLoader == false) then
				ml_global_information.queueLoader = true
			end
		end
	end
	
	--[[
	if (ValidTable(ml_global_information.navObstacles) and Now() > ml_global_information.navObstaclesTimer) then
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
	--]]
	
	local pulseTime = tonumber(gFFXIVMINIONPulseTime) or 150
	local skillPulse = (pulseTime/2)
	
	if (TimeSince(ml_global_information.lastrun2) > skillPulse) then
		ml_global_information.lastrun2 = tickcount
		SkillMgr.OnUpdate()
	end
	
	--if (TimeSince(ml_global_information.lastrun) > pulseTime) then
	if (Now() >= ml_global_information.nextRun) then
		
		ml_global_information.nextRun = tickcount + pulseTime
		ml_global_information.lastPulseShortened = false
		
        --ml_global_information.lastrun = tickcount
		
		ffxivminion.UpdateGlobals()

		local thisMeasure = collectgarbage("count")/1024
		gMemoryUsage = tostring(thisMeasure)
		gMemoryGain = tostring(thisMeasure - ml_global_information.lastMeasure)
		ml_global_information.lastMeasure = thisMeasure
		
		-- close any social addons that might screw up behavior first
		if (gBotRunning == "1" and 
			gBotMode ~= GetString("assistMode") and
			gBotMode ~= GetString("dutyMode")) 
		then
			ffxivminion.ClearAddons()
		end
		
        if (ml_task_hub:CurrentTask() ~= nil) then
            gFFXIVMINIONTask = ml_task_hub:CurrentTask().name
        end
		
		--update idle pulse count
		if (ml_global_information.idlePulseCount ~= 0) then
			gIdlePulseCount = tostring(ml_global_information.idlePulseCount)
		elseif(gIdlePulseCount ~= "") then
			gIdlePulseCount = ""
		end
		
		gStatusStealth = tostring(ml_global_information.needsStealth)
		
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
		
		local et = AceLib.API.Weather.GetDateTime() 
		gEorzeaTime = tostring(et.hour)..":"..(et.minute < 10 and "0" or "")..tostring(et.minute)
		
		-- ffxiv_task_fate.lua
		ffxiv_task_grind.UpdateBlacklistUI(tickcount)
		
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
				if (not ControlVisible("Gathering") and not ControlVisible("Synthesis") and not ControlVisible("SynthesisSimple") and not Player.incombat) then
					if (NeedsRepair()) then
						Repair()
					end
					ml_global_information.repairTimer = tickcount
				end
			end
	
			if ( gFood ~= "None" or gFoodHQ ~= "None" ) then
				if ( TimeSince(ml_global_information.foodCheckTimer) > 10000 and not Player.ismounted and not Player:IsMoving()) then
					if (not ControlVisible("Gathering") and not ControlVisible("Synthesis") and not ControlVisible("SynthesisSimple")) then
						Eat()
						ml_global_information.foodCheckTimer = tickcount
					end
				end
			end
			
			--[[
			if (gUseCompanionItem ~= GetString("none")) then
				if ( TimeSince(ml_global_information.rootCheckTimer) > 30000 and not Player.ismounted) then
					ml_global_information.rootCheckTimer = tickcount
					
					if (not Player.ismounted and not IsMounting() and IsCompanionSummoned()) then
						
						local acDismiss = ActionList:Get(2,6)
						local item = Inventory:Get(7894)

						if ( acDismiss and acDismiss.isready and item and item.isready) then
							local el = EntityList("nearest,myparty,type=2,chartype=3")
							if (ValidTable(el)) then
								local i, choco = next(el)
								if (i and choco) then
									if MissingBuffs(choco,"536+537") then
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
			--]]
			
			if (gUseCurielRoot == "1") then
				if ( TimeSince(ml_global_information.rootCheckTimer) > 30000 and not Player.ismounted and not IsMounting()) then
					ml_global_information.rootCheckTimer = tickcount
					local acDismiss = ActionList:Get(2,6)
					local item = Inventory:Get(7894)

					if ( acDismiss and acDismiss.isready and item and item.isready) then
						local el = EntityList("nearest,myparty,type=2,chartype=3")
						if (ValidTable(el)) then
							local i, choco = next(el)
							if (i and choco) then
								if MissingBuffs(choco,"536+537") then
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
		
		if (ml_task_hub.shouldRun) then

			if (IsFighter(Player.job) and not ml_global_information.lastPulseShortened) then
				local actionID = SkillMgr.GCDSkills[Player.job]
				if (actionID) then
					local action = MGetAction(actionID)
					if (action) then
						if (action.isoncd) then
							local timediff = math.ceil((action.cd - action.cdmax) * 1000)
							if (timediff < pulseTime) then
								--d("shortening next pulse to occur in ["..tostring(timediff).."] ms")
								ml_global_information.nextRun = Now() + timediff
								ml_global_information.lastPulseShortened = true
							end
						end
					end
				end
			end
			
			if (not ml_task_hub:Update()) then
				ml_error("No task queued, please select a valid bot mode in the Settings drop-down menu")
			end
		end
    end
end

function ml_global_information.InCharacterSelectScreenOnUpdate( event, tickcount )
	--d("In the character select screen.")
end

function ml_global_information.InTitleScreenOnUpdate( event, tickcount )
	--d("In the title screen.")
end

function ml_global_information.BuildMenu()
	ml_global_information.menu = {}
	ml_global_information.menu.windows = {}
	ml_global_information.menu.vars = {}
	
	local width,height = GUI:GetScreenSize()
	if (Settings.FFXIVMINION.menuX == nil) then
		Settings.FFXIVMINION.menuX = (width/3)
	end
	ml_global_information.menu.vars.menuX = Settings.FFXIVMINION.menuX
	
	local flags = (GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoMove + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
	ml_global_information.menu.flags = flags
end

function ffxivminion.GUIVarCapture(newVal,varName,doSave)
	local doSave = IsNull(doSave,true)
	local needsSave = false
	
	local currentVal = _G[varName]
	if (currentVal ~= newVal or type(newVal) == "table") then
		_G[varName] = newVal
		needsSave = true
	end
		
	if (doSave and needsSave) then
		Settings.FFXIVMINION[varName] = newVal
	end

	return newVal
end

function ffxivminion.GetSetting(strSetting,default)
	if (Settings.FFXIVMINION[strSetting] == nil) then
		Settings.FFXIVMINION[strSetting] = default
	end
	return Settings.FFXIVMINION[strSetting]	
end

function ffxivminion.SetMainVars()
	FFXIV_Common_Profile = 1
	FFXIV_Common_ProfileList = {GetString("none")}
	FFXIV_Common_NavMesh = 1
	FFXIV_Common_MeshList = {GetString("none")}
	FFXIV_Common_BotMode = 1
	FFXIV_Common_ModeList = {GetString("none")}
	FFXIV_Common_SkillProfile = 1
	FFXIV_Common_SkillProfileList = {GetString("none")}
	FFXIV_Common_BotRunning = false
	
	--[[
	local uuid = GetUUID()
	if ( Settings.FFXIVMINION.gBotModes and string.valid(uuid) and Settings.FFXIVMINION.gBotModes[uuid] ) then
		gBotMode = Settings.FFXIVMINION.gBotModes[uuid]
		--FFXIV_Common_BotMode = GetKeyByValue(gBotMode,FFXIV_Common_ModeList)
	else
		gBotMode = ffxivminion.GetSetting("gBotMode",GetString("grindMode"))
		--FFXIV_Common_BotMode = GetKeyByValue(gBotMode,FFXIV_Common_ModeList)
	end
	--]]
	
	FFXIV_Core_Version = 2
	FFXIV_Core_PulseTime = ffxivminion.GetSetting("FFXIV_Core_PulseTime",150)
	FFXIV_Core_ActiveTaskCount = 0
	FFXIV_Core_ActiveTaskName = ""
	FFXIV_Core_ActiveTaskDelay = 0
	FFXIV_Core_IdlePulseCount = 0
	FFXIV_Core_MemoryUsage = 0
	
	FFXIV_Common_EorzeaTime = ""
	FFXIV_Common_EnableLog = ffxivminion.GetSetting("FFXIV_Common_EnableLog",false)
	FFXIV_Common_LogCNE = ffxivminion.GetSetting("FFXIV_Common_LogCNE",false)
	FFXIV_Common_LogLevel = ffxivminion.GetSetting("FFXIV_Common_LogLevel",1)
	FFXIV_Common_LogLevels = {"1", "2", "3"}
	FFXIV_Common_MountString = ""
	FFXIV_Common_Mount = ffxivminion.GetSetting("FFXIV_Common_Mount",1)
	FFXIV_Common_Mounts = {GetString("none")}
	ffxivminion.FillMountOptions()
	FFXIV_Common_UseMount = ffxivminion.GetSetting("FFXIV_Common_UseMount",true)
	FFXIV_Common_MountDist = ffxivminion.GetSetting("FFXIV_Common_MountDist",75)
	FFXIV_Common_UseSprint = ffxivminion.GetSetting("FFXIV_Common_UseSprint",false)
	FFXIV_Common_SprintDist = ffxivminion.GetSetting("FFXIV_Common_SprintDist",50)
	FFXIV_Common_RandomPaths = ffxivminion.GetSetting("FFXIV_Common_RandomPaths",false)
	FFXIV_Common_FoodString = ""
	FFXIV_Common_Food = ffxivminion.GetSetting("FFXIV_Common_Food",1)
	FFXIV_Common_Foods = {GetString("none")}
	ffxivminion.FillFoodOptions()
	FFXIV_Common_AutoStart = ffxivminion.GetSetting("FFXIV_Common_AutoStart",false)
	FFXIV_Common_Teleport = ffxivminion.GetSetting("FFXIV_Common_Teleport",false)
	FFXIV_Common_Paranoid = ffxivminion.GetSetting("FFXIV_Common_Paranoid",false)
	FFXIV_Common_SkipCutscene = ffxivminion.GetSetting("FFXIV_Common_SkipCutscene",false)
	FFXIV_Common_SkipDialogue = ffxivminion.GetSetting("FFXIV_Common_SkipDialogue",false)
	FFXIV_Common_ClickTeleport = ffxivminion.GetSetting("FFXIV_Common_ClickTeleport",false)
	FFXIV_Common_ClickTravel = ffxivminion.GetSetting("FFXIV_Common_ClickTravel",false)
	FFXIV_Common_DisableDrawing = ffxivminion.GetSetting("FFXIV_Common_DisableDrawing",false)
	FFXIV_Common_Repair = ffxivminion.GetSetting("FFXIV_Common_Repair",false)
	FFXIV_Common_PermaSprint = ffxivminion.GetSetting("FFXIV_Common_PermaSprint",false)
	FFXIV_Common_PermaSwift = ffxivminion.GetSetting("FFXIV_Common_PermaSwift",false)
	FFXIV_Common_ChocoAssist = ffxivminion.GetSetting("FFXIV_Common_ChocoAssist",false)
	FFXIV_Common_ChocoGrind = ffxivminion.GetSetting("FFXIV_Common_ChocoGrind",true)
	FFXIV_Common_ChocoQuest = ffxivminion.GetSetting("FFXIV_Common_ChocoQuest",true)
	FFXIV_Common_ChocoStanceString = ""
	FFXIV_Common_ChocoStance = ffxivminion.GetSetting("FFXIV_Common_ChocoStance",1)
	FFXIV_Common_ChocoStances = {GetString("stFree"), GetString("stDefender"), GetString("stAttacker"), GetString("stHealer"), GetString("stFollow")}
	
	FFXIV_Common_ChocoItemString = ""
	FFXIV_Common_ChocoItem = ffxivminion.GetSetting("FFXIV_Common_ChocoItem",1)
	FFXIV_Common_ChocoItems = {"Curiel Root (EXP)", "Sylkis Bud (ATK)", "Mimmet Gourd (Heal)", "Tantalplant (HP)", "Pahsana Fruit (ENM)"}
	
	FFXIV_Common_AvoidAOE = ffxivminion.GetSetting("FFXIV_Common_AvoidAOE",false)
	FFXIV_Common_AvoidHP = ffxivminion.GetSetting("FFXIV_Common_AvoidHP",100)
	FFXIV_Common_RestHP = ffxivminion.GetSetting("FFXIV_Common_RestHP",70)
	FFXIV_Common_RestMP = ffxivminion.GetSetting("FFXIV_Common_RestMP",0)
	FFXIV_Common_PotionHP = ffxivminion.GetSetting("FFXIV_Common_PotionHP",50)
	FFXIV_Common_PotionMP = ffxivminion.GetSetting("FFXIV_Common_PotionMP",0)
	FFXIV_Common_FleeHP = ffxivminion.GetSetting("FFXIV_Common_FleeHP",25)
	FFXIV_Common_FleeMP = ffxivminion.GetSetting("FFXIV_Common_FleeMP",0)
	FFXIV_Common_AutoEquip = ffxivminion.GetSetting("FFXIV_Common_AutoEquip",true)
	FFXIV_Common_StealthDetect = ffxivminion.GetSetting("FFXIV_Common_StealthDetect",25)
	FFXIV_Common_StealthRemove = ffxivminion.GetSetting("FFXIV_Common_StealthRemove",30)
	FFXIV_Common_StealthSmart = ffxivminion.GetSetting("FFXIV_Common_StealthSmart",true)
	
	ml_global_information.autoStartQueued = FFXIV_Common_AutoStart		
	GameHacks:Disable3DRendering(FFXIV_Common_DisableDrawing)
	GameHacks:SkipCutscene(FFXIV_Common_SkipCutscene)
	GameHacks:SkipDialogue(FFXIV_Common_SkipDialogue)
	GameHacks:SetClickToTeleport(FFXIV_Common_ClickTeleport)
	GameHacks:SetClickToTravel(FFXIV_Common_ClickTravel)
	GameHacks:SetPermaSprint(FFXIV_Common_PermaSprint)
	GameHacks:SetPermaSwiftCast(FFXIV_Common_PermaSwift)
end

function ffxivminion.CreateMainWindow()

	-- ALL THIS SHIT GOES AWAY, TO BE REMOVED.
	
	ffxivminion.Windows.Main = { id = strings["us"].settings, Name = GetString("settings"), x=50, y=50, width=210, height=350 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Main)
	
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
	GUI_NewField(winName,"# Active Tasks","gStatusActiveTaskCount",group )
    GUI_NewCheckbox(winName,GetString("enableLog"),"gEnableLog",group )
    GUI_NewCheckbox(winName,GetString("logCNE"),"gLogCNE",group )
	GUI_NewComboBox(winName,"Log Level","gLogLevel",group,"1,2,3")
	
    GUI_NewField(winName,GetString("task"),"gFFXIVMINIONTask",group )
	GUI_NewField(winName,GetString("taskDelay"),"gTaskDelay",group )
	GUI_NewField(winName,GetString("idlePulseCount"),"gIdlePulseCount",group )
	GUI_NewField(winName,GetString("eorzeaTime"),"gEorzeaTime", group)
	GUI_NewField(winName,"Memory Usage","gMemoryUsage", group)
	GUI_NewField(winName,"Memory Gain","gMemoryGain", group)
	GUI_NewField(winName,"Stealth","gStatusStealth", group)
	
	local group = GetString("generalSettings")
    GUI_NewCheckbox(winName,GetString("autoStartBot"),"gAutoStart",group)
	GUI_NewCheckbox(winName,GetString("autoEquip"),"gQuestAutoEquip",group)
	GUI_NewCheckbox(winName,GetString("useMount"),"gUseMount",group )
	GUI_NewComboBox(winName,GetString("mount"), "gMount",group,GetMounts())
    GUI_NewNumeric(winName,GetString("mountDist"),"gMountDist",group )
    GUI_NewCheckbox(winName,GetString("useSprint"),"gUseSprint",group )
    GUI_NewNumeric(winName,GetString("sprintDist"),"gSprintDist",group )
	GUI_NewComboBox(winName,GetString("food"),"gFood", group, "None")
	GUI_NewComboBox(winName,GetString("foodHQ"),"gFoodHQ", group, "None")
	GUI_NewCheckbox(winName,GetString("avoidAOE"), "gAvoidAOE",group )
	GUI_NewCheckbox(winName,GetString("randomPaths"),"gRandomPaths",group )
	GUI_NewCheckbox(winName,GetString("randomMovement"),"gRandomMovement",group )
	GUI_NewCheckbox(winName,GetString("useHQMats"),"gUseHQMats",group )
	GUI_NewCheckbox(winName,"Use EXP Manuals","gUseEXPManuals",group )
	
	local group = GetString("companion")
	GUI_NewCheckbox(winName,GetString("assistMode"),"gChocoAssist",group )
	GUI_NewCheckbox(winName,GetString("grindMode"),"gChocoGrind",group )
	GUI_NewCheckbox(winName,GetString("questMode"),"gChocoQuest",group )
	GUI_NewCheckbox(winName,GetString("curielRoot"),"gUseCurielRoot",group )
	GUI_NewComboBox(winName,GetString("stance"),"gChocoStance",group,"")
	gChocoStance_listitems = GetString("stFree")..","..GetString("stDefender")..","..GetString("stAttacker")..","..GetString("stHealer")..","..GetString("stFollow")
	
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
	GUI_NewNumeric(winName, "Stealth - Detect Range", "gAdvStealthDetect", group, "1", "100")
	GUI_NewNumeric(winName, "Stealth - Remove Range", "gAdvStealthRemove", group, "1", "100")
	GUI_NewCheckbox(winName, "Stealth - Risky Mode", "gAdvStealthRisky", group)
	GUI_NewButton(winName, "Use Defaults", "ffxivminion.ResetAdvancedDefaults",group)
	
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	Settings.FFXIVMINION.version = 1.0
	gFFXIVMINIONPulseTime = ffxivminion.GetSetting("gFFXIVMINIONPulseTime",150)
	
	--due to shared settings profile, we'll look for a character specific "last mode" first	
	if ( Settings.FFXIVMINION.gBotModes and string.valid(GetUUID()) and Settings.FFXIVMINION.gBotModes[GetUUID()] ) then
		gBotMode = Settings.FFXIVMINION.gBotModes[GetUUID()]
	else
		gBotMode = ffxivminion.GetSetting("gBotMode",GetString("grindMode"))
	end
	gEnableLog = ffxivminion.GetSetting("gEnableLog","0")
	gLogCNE = ffxivminion.GetSetting("gLogCNE","0")
	gLogLevel = ffxivminion.GetSetting("gLogLevel","1")
	gMount = ffxivminion.GetSetting("gMount",GetString("none"))
	gUseMount = ffxivminion.GetSetting("gUseMount","0")
	gMountDist = ffxivminion.GetSetting("gMountDist","75")
	gUseSprint = ffxivminion.GetSetting("gUseSprint","0")
	gSprintDist = ffxivminion.GetSetting("gSprintDist","50")
	gRandomPaths = ffxivminion.GetSetting("gRandomPaths","0")
	gAutoStart = ffxivminion.GetSetting("gAutoStart","0")
	gTeleport = ffxivminion.GetSetting("gTeleport","0")
	gParanoid = ffxivminion.GetSetting("gParanoid","1")
	gSkipCutscene = ffxivminion.GetSetting("gSkipCutscene","0")
	gSkipDialogue = ffxivminion.GetSetting("gSkipDialogue","0")
	gDisableDrawing = ffxivminion.GetSetting("gDisableDrawing","0")
	--gDoUnstuck = ffxivminion.GetSetting("gDoUnstuck","0")
	gUseHQMats = ffxivminion.GetSetting("gUseHQMats","0")
	gUseEXPManuals = ffxivminion.GetSetting("gUseEXPManuals","1")
	gClickToTeleport = ffxivminion.GetSetting("gClickToTeleport","0")
	gClickToTravel = ffxivminion.GetSetting("gClickToTravel","0")
	gChocoAssist = ffxivminion.GetSetting("gChocoAssist","0")
	gChocoGrind = ffxivminion.GetSetting("gChocoGrind","0")
	gChocoQuest = ffxivminion.GetSetting("gChocoQuest","0")
	gChocoStance = ffxivminion.GetSetting("gChocoStance",GetString("stFree"))
	gRepair = ffxivminion.GetSetting("gRepair","1")
	gGatherPS = ffxivminion.GetSetting("gGatherPS","0")
	gPermaSwiftCast = ffxivminion.GetSetting("gPermaSwiftCast","0")
	gFoodHQ = ffxivminion.GetSetting("gFoodHQ",GetString("none"))
	gFood = ffxivminion.GetSetting("gFood",GetString("none"))
	gAvoidAOE = ffxivminion.GetSetting("gAvoidAOE","0")
	gAvoidHP = ffxivminion.GetSetting("gAvoidHP","100")
	gRestHP = ffxivminion.GetSetting("gRestHP","70")
	gRestMP = ffxivminion.GetSetting("gRestMP","0")
	gFleeHP = ffxivminion.GetSetting("gFleeHP","20")
	gFleeMP = ffxivminion.GetSetting("gFleeMP","0")
	gPotionHP = ffxivminion.GetSetting("gPotionHP","50")
	gPotionMP = ffxivminion.GetSetting("gPotionMP","0")
	gUseCurielRoot = ffxivminion.GetSetting("gUseCurielRoot","0")
	gQuestAutoEquip = ffxivminion.GetSetting("gQuestAutoEquip","1")
	gAdvStealthDetect = ffxivminion.GetSetting("gAdvStealthDetect","25")
	gAdvStealthRemove = ffxivminion.GetSetting("gAdvStealthRemove","30")
	gAdvStealthRisky = ffxivminion.GetSetting("gAdvStealthRisky","0")
	
	-- gAutoStart
	if ( gAutoStart == "1" ) then
		ml_global_information.autoStartQueued = true		
	end
	if (gDisableDrawing == "1" ) then
		GameHacks:Disable3DRendering(true)
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
	if (gGatherPS == "1") then
        GameHacks:SetPermaSprint(true)
    end
	if (gPermaSwiftCast == "1") then
        GameHacks:SetPermaSwiftCast(true)
    end	
end

-- Module Event Handler
function ffxivminion.HandleInit()
	
	-- Build bottom menu for new GUI addons.
	ml_global_information.BuildMenu()
	ffxivminion.SetMainVars()
	--ffxivminion.SetupOverrides()
	
	gmeshname = GetString("none")
	
	-- Add "known" modes, safe.
	ffxivminion.AddMode(GetString("grindMode"), ffxiv_task_grind) 
	ffxivminion.AddMode(GetString("fishMode"), ffxiv_task_fish)
	ffxivminion.AddMode(GetString("gatherMode"), ffxiv_task_gather)
	ffxivminion.AddMode(GetString("craftMode"), ffxiv_task_craft)
	ffxivminion.AddMode(GetString("assistMode"), ffxiv_task_assist)
	ffxivminion.AddMode(GetString("partyMode"), ffxiv_task_party)
	ffxivminion.AddMode(GetString("pvpMode"), ffxiv_task_pvp)
	ffxivminion.AddMode(GetString("frontlines"), ffxiv_task_frontlines)
	ffxivminion.AddMode(GetString("huntMode"), ffxiv_task_hunt)
	ffxivminion.AddMode(GetString("huntlogMode"), ffxiv_task_huntlog)
	ffxivminion.AddMode(GetString("quickStartMode"), ffxiv_task_qs_wrapper)
	ffxivminion.AddMode("NavTest", ffxiv_task_test)
	
	-- To be removed.
	if ( not ffxivminion.Windows ) then
		ffxivminion.Windows = {GetString("none")}
	end
	
	-- New GUI code, need new strings and handlers for combo boxes.
	FFXIV_Common_MeshList = {}
	local meshfilelist = FolderList(ml_mesh_mgr.defaultpath)
	if (meshfilelist) then
		for i,file in spairs(meshfilelist, function( file,a,b ) return file[a] < file[b] end) do
			if ( string.ends(file,".obj") ) then
				local filename = string.trim(file,4)
				table.insert(FFXIV_Common_MeshList, ml_mesh_mgr.GetString(filename))
			end
		end		
	end
	
	FFXIV_Common_SkillProfileList = {GetString("none")}
    local profilelist = dirlist(SkillMgr.profilepath,".*lua")
    if (ValidTable(profilelist)) then
		for i,profile in pairs(profilelist) do		
            profile = string.gsub(profile, ".lua", "")
			table.insert(FFXIV_Common_SkillProfileList,profile)
        end		
    end

	gFFXIVMINIONTask = ""
    gBotRunning = "0" -- To be removed.
	FFXIV_Common_BotRunning = false
	
	-- Get last mode and set it to be used to start this session.
	local uuid = GetUUID()
	if ( string.valid(uuid) and Settings.FFXIVMINION.gBotModes and Settings.FFXIVMINION.gBotModes[uuid] ) then
		ml_global_information.lastMode = Settings.FFXIVMINION.gBotModes[uuid]
	else
		ml_global_information.lastMode = ffxivminion.GetSetting("gBotMode",GetString("grindMode"))
    end
	
    -- setup parent window for minionlib modules, so we know where to place them when opening.
	-- To be removed.
    ml_marker_mgr.parentWindow = ml_global_information.MainWindow
    ml_blacklist_mgr.parentWindow = ml_global_information.MainWindow
    
    -- setup/load blacklist tables
	-- Redo all this, blacklist shit sucks.
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
	
	gForceAutoEquip = false
	
	--local menuTab = { name = "Main", openWindow = function () ffxivminion.GUI.main.open = true end, isOpen = function() return ffxivminion.GUI.main.open end }	
	--table.insert(ml_global_information.menu.windows,menuTab)
	--local settingsTab = { name = "Settings", openWindow = function () ffxivminion.GUI.settings.open = true end, isOpen = function() return ffxivminion.GUI.settings.open end }	
	--table.insert(ml_global_information.menu.windows,settingsTab)
	ml_gui.ui_mgr:AddMember({ id = "FFXIVMINION##MENU_SETTINGS", name = "Settings", onClick = function() ffxivminion.GUI.settings.open = not ffxivminion.GUI.settings.open end, tooltip = "Open the FFXIVMinion settings."},"FFXIVMINION##MENU_HEADER")
end

-- To be removed, this is not necessary with the new GUI, and most of it will be invalid.
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
			-- save the last botMode in a new table, since the setting file can be used by multiple accounts now
			local uuid = GetUUID()
			if ( string.valid(uuid) ) then
				if  ( Settings.FFXIVMINION.gBotModes == nil ) then Settings.FFXIVMINION.gBotModes = {} end
				Settings.FFXIVMINION.gBotModes[uuid] = gBotMode
			end
        end
		if ( k == "gmeshname" and v ~= "") then
			if ( v ~= GetString("none")) then
				local filename = ml_mesh_mgr.GetFileName(v)
				d("Attempting to set new mesh ["..tostring(filename).."]")
				ml_mesh_mgr.SetDefaultMesh(Player.localmapid, filename)
				ml_mesh_mgr.LoadNavMesh( filename )
			else
				--ml_mesh_mgr.ClearNavMesh()
				NavigationManager:ClearNavMesh() 
			end
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
			k == "gLogLevel" or
            k == "gFFXIVMINIONPulseTime" or
            k == "gMountDist" or
            k == "gAssistMode" or
            k == "gAssistPriority" or
            k == "gSprintDist" or
			k == "gAutoStart" or
			k == "gStartCombat" or
			k == "gConfirmDuty" or
            k == "gRandomPaths" or
			k == "gChocoAssist" or
			k == "gChocoGrind" or
			k == "gChocoQuest" or
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
			k == "gAdvStealthRemove" or
			k == "gAdvStealthRisky" or
			k == "gQuestAutoEquip" or
			k == "gUseEXPManuals")				
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
		ml_global_information.mainTask = task
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
		
		--if (gBotMode == GetString("pvpMode")) then
            --Player:EnableUnstuckJump(false)
        --else
            --Player:EnableUnstuckJump(true)
        --end
		
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
			if (Duties) then
				Duties.UpdateProfiles()
			end
			gTeleport = "1"
			gParanoid = "0"
			gSkipCutscene = "1"
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
			gSkipCutscene = "1"
			gSkipDialogue = "1"
			gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
			GameHacks:SkipCutscene(gSkipCutscene == "1")
			GameHacks:SkipDialogue(gSkipDialogue == "1")
			GameHacks:Disable3DRendering(gDisableDrawing == "1")
			gAvoidAOE = "1"
			gQuestAutoEquip = "1"
		elseif (gBotMode == GetString("fishMode")) then
			gTeleport = Settings.FFXIVMINION.gTeleport
			gParanoid = Settings.FFXIVMINION.gParanoid
			gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
			gSkipCutscene = Settings.FFXIVMINION.gSkipCutscene
			gSkipDialogue = Settings.FFXIVMINION.gSkipDialogue
			GameHacks:SkipCutscene(gSkipCutscene == "1")
			GameHacks:SkipDialogue(gSkipDialogue == "1")
			GameHacks:Disable3DRendering(gDisableDrawing == "1")
			gAvoidAOE = Settings.FFXIVMINION.gAvoidAOE
			ffxiv_fish.UpdateProfiles()
			gQuestAutoEquip = Settings.FFXIVMINION.gQuestAutoEquip
		elseif (gBotMode == GetString("gatherMode")) then
			gTeleport = Settings.FFXIVMINION.gTeleport
			gParanoid = Settings.FFXIVMINION.gParanoid
			gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
			gSkipCutscene = Settings.FFXIVMINION.gSkipCutscene
			gSkipDialogue = Settings.FFXIVMINION.gSkipDialogue
			GameHacks:SkipCutscene(gSkipCutscene == "1")
			GameHacks:SkipDialogue(gSkipDialogue == "1")
			GameHacks:Disable3DRendering(gDisableDrawing == "1")
			gAvoidAOE = Settings.FFXIVMINION.gAvoidAOE
			ffxiv_gather.UpdateProfiles()
			gQuestAutoEquip = Settings.FFXIVMINION.gQuestAutoEquip
		elseif (gBotMode == GetString("craftMode")) then
			gTeleport = Settings.FFXIVMINION.gTeleport
			gParanoid = Settings.FFXIVMINION.gParanoid
			gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
			gSkipCutscene = Settings.FFXIVMINION.gSkipCutscene
			gSkipDialogue = Settings.FFXIVMINION.gSkipDialogue
			GameHacks:SkipCutscene(gSkipCutscene == "1")
			GameHacks:SkipDialogue(gSkipDialogue == "1")
			GameHacks:Disable3DRendering(gDisableDrawing == "1")
			gAvoidAOE = Settings.FFXIVMINION.gAvoidAOE
			ffxiv_craft.UpdateProfiles()
			gQuestAutoEquip = Settings.FFXIVMINION.gQuestAutoEquip
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
	if (not ValidTable(ml_global_information.classes)) then
		ml_global_information.classes = {
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
	end
	
	local classes = ml_global_information.classes
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
    
    if (ml_global_information.CurrentClassID ~= Player.job) then
        ml_global_information.CurrentClass = playerClass
        ml_global_information.CurrentClassID = Player.job
		ml_global_information.AttackRange = playerClass.range or 2
		SkillMgr.UseDefaultProfile()
		ffxivminion.VerifyClassSettings()
		ffxivminion.UseClassSettings()
		
		-- autosetting the correct botmode
		
		if (gBotMode ~= GetString("questMode")) then
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
				newModeName = GetString("assistMode")				
			end
					
			if (gBotMode ~= newModeName and newModeName ~= "") then
				ffxivminion.SwitchMode(newModeName)
			end
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
			WindowManager:NewWindow(wname,wi.x,wi.y,wi.width,wi.height,true)
			--GUI_NewWindow	(wname,wi.x,wi.y,wi.width,wi.height,"",true)
		else
			WindowManager:NewWindow(wname,wi.x,wi.y,wi.width,wi.height)
			--GUI_NewWindow	(wname,wi.x,wi.y,wi.width,wi.height)
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
			
			if (ValidTable(WI) and ValidTable(W)) then
				if (WI.width ~= W.width) then WindowInfo.width = W.width else WindowInfo.width = WI.width end
				if (WI.height ~= W.height) then WindowInfo.height = W.height else WindowInfo.height = WI.height	end
				if (WI.x ~= W.x) then WindowInfo.x = W.x else WindowInfo.x = WI.x end
				if (WI.y ~= W.y) then WindowInfo.y = W.y else WindowInfo.y = WI.y end
				
				local tablesEqual = deepcompare(WindowInfo,WI,true)
				if (not tablesEqual) then 
					SafeSetVar(tableName,WindowInfo)
				end
			end
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
	
	ffxivminion.GUI.settings.open = true
end

function ffxivminion.UpdateGlobals()
	if (Player) then
		ml_global_information.Player_Aetherytes = GetAetheryteList()
		ml_global_information.Player_Position = Player.pos
		ml_global_information.Player_Map = Player.localmapid
		ml_global_information.Player_HP = Player.hp
		ml_global_information.Player_MP = Player.mp
		ml_global_information.Player_TP = Player.tp
		ml_global_information.Player_InCombat = Player.incombat
	end
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

-- This section to be removed, old GUI method.
function ffxivminion.UpdateFoodOptions()
	
	local foodlistHQ = "None"
    local foodlist = "None"	
	for x = 0,3 do
		local inv = Inventory("category=5,type="..tostring(x))
		if ( inv ) then
			for i,item in pairs(inv) do
				if (toboolean(item.IsHQ)) then
					if (ffxivminion.foodsHQ[item.name] ~= item.hqid) then
						ffxivminion.foodsHQ[item.name] = item.hqid 
					end
					foodlistHQ = foodlistHQ..","..item.name
				else
					if (ffxivminion.foods[item.name] ~= item.hqid) then
						ffxivminion.foods[item.name] = item.hqid
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
	SkillMgr.receivedMacro = {}
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
		elseif (string.find(Button,"ffxivminion%.")) then
			ExecuteFunction(Button)
		end
	end
end

function ffxivminion.AddMode(name, task)
	ffxivminion.modesToLoad[name] = task
end

-- New GUI methods.
function ffxivminion.FillFoodOptions()
	ml_global_information.foods = {}
	
	local inv = Inventory("category=5")
	if ( inv ) then
		for i,item in pairs(inv) do
			if (item.class ~= 0) then
				local itemName = item.name
				if (toboolean(item.IsHQ)) then
					itemName = itemName.." (HQ)"
				end
				ml_global_information.foods[item.hqid] = {
					name = itemName,
					max = item.max,
					slot = item.slot,
					category = item.category,
				}
			end
		end
	end
	
	FFXIV_Common_Foods = {GetString("none")}
	local foods = ml_global_information.foods
	if (ValidTable(foods)) then
		for id,item in spairs(foods, function( item,a,b ) return item[a].name < item[b].name end) do
			table.insert(FFXIV_Common_Foods,item.name)
		end
	end
end

function ffxivminion.FillModeOptions()
	FFXIV_Common_ModeList = {}
	if (ValidTable(ffxivminion.modes)) then
		local modes = ffxivminion.modes
		for i,entry in spairs(modes, function(modes,a,b) return a < b end) do
			table.insert(FFXIV_Common_ModeList,i)
		end				
	end
end

function ffxivminion.FillMountOptions()
	FFXIV_Common_Mounts = { GetString("none") }
	local mounts = ActionList("type=13")
	if (mounts) then
		for k,v in pairs(mounts) do
			table.insert(FFXIV_Common_Mounts,v.name)
		end
	end
end

function ffxivminion.LoadModes()
	local _gmeshname = gmeshname
	if (ValidTable(ffxivminion.modesToLoad)) then
		for modeName,task in pairs(ffxivminion.modesToLoad) do
			--d("Loading mode ["..tostring(modeName).."].")
			ffxivminion.modes[modeName] = task
			task:UIInit() -- to be removed
			--task:NewInit() -- new method
			if (task.NewInit) then
				task.NewInit()
			end
		end
		
		-- Empty out the table to prevent reloading.
		ffxivminion.modesToLoad = {}
	end
	gmeshname = _gmeshname
	
	local botModes = ffxivminion.Strings.BotModes() -- to be removed
	gBotMode_listitems = botModes -- to be removed
	
	ffxivminion.FillModeOptions() -- new gui method
	
	local uuid = GetUUID()
	if ( string.valid(uuid) and Settings.FFXIVMINION.gBotModes and Settings.FFXIVMINION.gBotModes[uuid] ) then
		gBotMode = Settings.FFXIVMINION.gBotModes[uuid]
		FFXIV_Common_BotMode = GetKeyByValue(gBotMode,FFXIV_Common_ModeList)
	else
		gBotMode = Retranslate(Settings.FFXIVMINION.gBotMode)
		FFXIV_Common_BotMode = GetKeyByValue(gBotMode,FFXIV_Common_ModeList)
    end
	
	local modeFound = false
	for i, entry in pairs(ffxivminion.modes) do
		if (i == gBotMode) then
			modeFound = true
			break
		end
	end
	
	if (modeFound) then
		--d("Switching mode to ["..tostring(gBotMode).."].")
		ffxivminion.SwitchMode(gBotMode)
	else
		--d("Mode not found, switching mode to ["..tostring(gBotMode).."].")
		gBotMode = GetString("grindMode")
		ffxivminion.SwitchMode(gBotMode)
	end
end

-- clear any addons displayed by social actions like trade/party invites
function ffxivminion.ClearAddons()
	--trade window
	Player:CheckTradeWindow()
	
	--party invite
	if (ControlVisible("_NotificationParty") and ControlVisible("SelectYesno")) then
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

function ml_global_information.GetFrameHeight(rows)
	local fontSize = GUI:GetWindowFontSize()
	local windowPaddingY = ml_gui.style.current.windowpadding.y
	local framePaddingY = ml_gui.style.current.framepadding.y
	local itemSpacingY = ml_gui.style.current.itemspacing.y
	
	return ((fontSize * rows) + (itemSpacingY * (rows - 1)) + (framePaddingY * 2 * rows) + (windowPaddingY * 2))
end

function ml_global_information.DrawIntMinMax(label,varname,step,stepfast,minval,maxval)
	local var = _G[varname]
	local returned = ffxivminion.GUIVarCapture(GUI:InputInt(label,var,step,stepfast),varname)
	if (minval ~= nil and returned < minval) then ml_global_information.SetGUIVar(varname,minval) elseif (maxval ~= nil and returned > maxval) then ml_global_information.SetGUIVar(varname,minval) end
end

function ml_global_information.DrawFloatMinMax(label,varname,step,stepfast,precision,minval,maxval)
	local var = _G[varname]
	local precision = IsNull(precision,2)
	local returned = ffxivminion.GUIVarCapture(GUI:InputFloat(label,var,step,stepfast,precision),varname)
	if (minval ~= nil and returned < minval) then ml_global_information.SetGUIVar(varname,minval) elseif (maxval ~= nil and returned > maxval) then ml_global_information.SetGUIVar(varname,minval) end
end

function ml_global_information.SetGUIVar(varName,newVal)
	_G[varName] = newVal
	Settings.FFXIVMINION[varName] = newVal
end

function ml_global_information.DrawMainFull()
	if (ffxivminion.GUI.main.open) then
		if (ffxivminion.GUI.draw_mode == 1) then
			GUI:SetNextWindowSize(300,300,GUI.SetCond_Once) --set the next window size, only on first ever	
			GUI:SetNextWindowCollapsed(false,GUI.SetCond_Once)
			
			local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
			GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
			
			ffxivminion.GUI.main.visible, ffxivminion.GUI.main.open = GUI:Begin(ffxivminion.GUI.main.name, ffxivminion.GUI.main.open)
			if ( ffxivminion.GUI.main.visible ) then 
			
			--GUI:Begin("FFXIVMinion##Main_Window", true)
			
				local x, y = GUI:GetWindowPos()
				local width, height = GUI:GetWindowSize()
				
				ffxivminion.GUI.x = x; ffxivminion.GUI.y = y; ffxivminion.GUI.width = width; ffxivminion.GUI.height = height;
				
				GUI:Image(ml_global_information.GetMainIcon(),14,14)
				if (GUI:IsItemHoveredRect()) then
					if (GUI:IsMouseClicked(0)) then
						if (ffxivminion.GUI.draw_mode == 1) then
							ffxivminion.GUI.draw_mode = 0
						else
							ffxivminion.GUI.draw_mode = 1
						end
					end
				end
				GUI:SameLine(0,10)
				
				GUI:PushItemWidth(120)
				local newMode = GUI:Combo(GetString("botMode"), FFXIV_Common_BotMode, FFXIV_Common_ModeList )
				if (newMode ~= FFXIV_Common_BotMode) then
					FFXIV_Common_BotMode = newMode
					Settings.FFXIVMINION[FFXIV_Common_BotMode] = FFXIV_Common_BotMode
					gBotMode = FFXIV_Common_ModeList[FFXIV_Common_BotMode]
					Settings.FFXIVMINION[gBotMode] = gBotMode
					ffxivminion.SwitchMode(gBotMode)
				end
				GUI:PopItemWidth()

				GUI:BeginChild("##main-task-section",0,-50,false)
				local mainTask = ml_global_information.mainTask
				if (mainTask.Draw) then
					mainTask:Draw()
				end
				GUI:EndChild()
				
				local width = GUI:GetContentRegionAvailWidth()
				if (GUI:Button(GetString("advancedSettings"),width,20)) then
					ffxivminion.OpenSettings()
				end
				if (GUI:Button(ml_global_information.BtnStart.Name,width,20)) then
					ml_global_information.ToggleRun()	
				end
			else
				ml_global_information.DrawSmall()
			end
			GUI:End()
			GUI:PopStyleColor()
		end
	end
end

function ml_global_information.DrawSmall()
	if (ffxivminion.GUI.main.open) then		
		--if (ffxivminion.GUI.draw_mode ~= 1) then
			GUI:SetNextWindowSize(200,50,GUI.SetCond_Always) --set the next window size, only on first ever	
			local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
			GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .10)
			
			local flags = (GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
			GUI:Begin("FFXIVMINION_MAIN_WINDOW_MINIMIZED", true, flags)
				
			GUI:Image(ml_global_information.GetMainIcon(),14,14)
			if (GUI:IsItemHoveredRect()) then
				if (GUI:IsMouseClicked(0)) then
					if (ffxivminion.GUI.draw_mode == 1) then
						ffxivminion.GUI.draw_mode = 0
					else
						ffxivminion.GUI.draw_mode = 1
					end
				end
			end
			GUI:SameLine(0,10)
			
			local child_color = (FFXIV_Common_BotRunning == true and { r = 0, g = .10, b = 0, a = .75 }) or { r = .10, g = 0, b = 0, a = .75 }
			GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,10)
			GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)

			GUI:BeginChild("##label-"..gBotMode,120,35,true)
			GUI:AlignFirstTextHeightToWidgets()
			GUI:Text(gBotMode)
			GUI:EndChild()
			GUI:PopStyleColor()
			GUI:PopStyleVar()
			if (GUI:IsItemHovered()) then
				if (GUI:IsMouseClicked(0)) then
					ml_global_information.ToggleRun()
				end
			end
			
			GUI:End()
			GUI:PopStyleColor()
		--end
	end
end

function ml_global_information.DrawSettings()
	if (ffxivminion.GUI.settings.open) then
		GUI:SetNextWindowSize(300,300,GUI.SetCond_Once) --set the next window size, only on first ever	
		GUI:SetNextWindowCollapsed(false,GUI.SetCond_Once)
		
		local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
		GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
		
		ffxivminion.GUI.settings.visible, ffxivminion.GUI.settings.open = GUI:Begin(ffxivminion.GUI.settings.name, ffxivminion.GUI.settings.open)
		if ( ffxivminion.GUI.settings.visible ) then 
			
			if (GUI:CollapsingHeader(GetString("botStatus"),"main-header-botstatus",true,true)) then
				GUI:BeginChild("##main-header-botstatus",0,ml_global_information.GetFrameHeight(10),true)
				GUI:PushItemWidth(100)
				ml_global_information.DrawIntMinMax(GetString("pulseTime"),"FFXIV_Core_PulseTime",5,10,30,2000)
				GUI:PopItemWidth()
				GUI:PushItemWidth(60)
				GUI:LabelText("# Active Task Count",FFXIV_Core_ActiveTaskCount)
				GUI:LabelText("# Active Task Name",FFXIV_Core_ActiveTaskName)
				GUI:LabelText("# Active Task Delay",FFXIV_Core_ActiveTaskDelay)
				GUI:LabelText("Idle Pulse Count",FFXIV_Core_IdlePulseCount)
				GUI:PopItemWidth()
				GUI:PushItemWidth(100)
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("enableLog"),FFXIV_Common_EnableLog),"FFXIV_Common_EnableLog");
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("logCNE"),FFXIV_Common_LogCNE),"FFXIV_Common_LogCNE");
				ffxivminion.GUIVarCapture(GUI:Combo("Log Level", FFXIV_Common_LogLevel, FFXIV_Common_LogLevels ),"FFXIV_Common_LogLevel")
				GUI:LabelText("Eorzea Time",FFXIV_Common_EorzeaTime)
				GUI:LabelText("Memory Usage",FFXIV_Core_MemoryUsage)
				GUI:PopItemWidth()
				GUI:EndChild()
			end
			
			if (GUI:CollapsingHeader(GetString("generalSettings"),"main-header-generalsettings",true,true)) then
				GUI:BeginChild("##main-header-generalsettings",0,ml_global_information.GetFrameHeight(10),true)
				GUI:PushItemWidth(100)
				
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("autoStartBot"),FFXIV_Common_AutoStart),"FFXIV_Common_AutoStart");
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("autoEquip"),FFXIV_Common_AutoEquip),"FFXIV_Common_AutoEquip");
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("useMount"),FFXIV_Common_UseMount),"FFXIV_Common_UseMount");
				ml_global_information.DrawIntMinMax(GetString("mountDist"),"FFXIV_Common_MountDist",5,10,0,200)
				local newMode = GUI:Combo(GetString("mount"), FFXIV_Common_Mount, FFXIV_Common_Mounts)
				if (newMode ~= FFXIV_Common_Mount) then
					FFXIV_Common_Mount = newMode
					Settings.FFXIVMINION[FFXIV_Common_Mount] = FFXIV_Common_Mount
					FFXIV_Common_MountString = FFXIV_Common_Mounts[FFXIV_Common_Mount]
				end
				GUI:SameLine(0,5)
				if (GUI:ImageButton("##main-mounts-refresh",ml_global_information.path.."\\GUI\\UI_Textures\\change.png", 18, 18)) then
					ffxivminion.FillMountOptions()
				end
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("useSprint"),FFXIV_Common_UseSprint),"FFXIV_Common_UseSprint");
				ml_global_information.DrawIntMinMax(GetString("sprintDist"),"FFXIV_Common_SprintDist",5,10,0,200)
				local newMode = GUI:Combo(GetString("food"), FFXIV_Common_Food, FFXIV_Common_Foods)
				if (newMode ~= FFXIV_Common_Food) then
					FFXIV_Common_Food = newMode
					Settings.FFXIVMINION[FFXIV_Common_Food] = FFXIV_Common_Food
					FFXIV_Common_FoodString = FFXIV_Common_Foods[FFXIV_Common_Food]
				end
				GUI:SameLine(0,5)
				if (GUI:ImageButton("##main-food-refresh",ml_global_information.path.."\\GUI\\UI_Textures\\change.png", 18, 18)) then
					ffxivminion.FillFoodOptions()
				end
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("avoidAOE"),FFXIV_Common_AvoidAOE),"FFXIV_Common_AvoidAOE");
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("randomPaths"),FFXIV_Common_RandomPaths),"FFXIV_Common_RandomPaths");

				GUI:PopItemWidth()
				GUI:EndChild()
			end	
			
			if (GUI:CollapsingHeader(GetString("companion"),"main-header-companion",true,true)) then
				GUI:BeginChild("##main-header-companion",0,ml_global_information.GetFrameHeight(3),true)
				
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("assistMode"),FFXIV_Common_ChocoAssist),"FFXIV_Common_ChocoAssist"); GUI:SameLine()
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("grindMode"),FFXIV_Common_ChocoGrind),"FFXIV_Common_ChocoGrind"); GUI:SameLine()
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("questMode"),FFXIV_Common_ChocoQuest),"FFXIV_Common_ChocoQuest");
				
				GUI:PushItemWidth(160)
				local newMode = GUI:Combo(GetString("stance"), FFXIV_Common_ChocoStance, FFXIV_Common_ChocoStances)
				if (newMode ~= FFXIV_Common_ChocoStance) then
					FFXIV_Common_ChocoStance = newMode
					Settings.FFXIVMINION[FFXIV_Common_ChocoStance] = FFXIV_Common_ChocoStance
					FFXIV_Common_ChocoStanceString = FFXIV_Common_ChocoStances[FFXIV_Common_ChocoStance]
				end
				local newMode = GUI:Combo("Feed", FFXIV_Common_ChocoItem, FFXIV_Common_ChocoItems)
				if (newMode ~= FFXIV_Common_ChocoItem) then
					FFXIV_Common_ChocoItem = newMode
					Settings.FFXIVMINION[FFXIV_Common_ChocoItem] = FFXIV_Common_ChocoItem
					FFXIV_Common_ChocoItemString = FFXIV_Common_ChocoItems[FFXIV_Common_ChocoItem]
				end
				GUI:PopItemWidth()
				GUI:EndChild()
			end
			
			if (GUI:CollapsingHeader(GetString("playerHPMPTP"),"main-header-playerhpmptp",true,true)) then
				GUI:BeginChild("##main-header-playerhpmptp",0,ml_global_information.GetFrameHeight(7),true)
				GUI:PushItemWidth(120)
				ml_global_information.DrawIntMinMax(GetString("avoidHP"),"FFXIV_Common_AvoidHP",1,10,0,100)
				ml_global_information.DrawIntMinMax(GetString("restHP"),"FFXIV_Common_RestHP",1,10,0,100)
				ml_global_information.DrawIntMinMax(GetString("restMP"),"FFXIV_Common_RestMP",1,10,0,100)
				ml_global_information.DrawIntMinMax(GetString("potionHP"),"FFXIV_Common_PotionHP",1,10,0,100)
				ml_global_information.DrawIntMinMax(GetString("potionMP"),"FFXIV_Common_PotionMP",1,10,0,100)
				ml_global_information.DrawIntMinMax(GetString("fleeHP"),"FFXIV_Common_FleeHP",1,10,0,100)
				ml_global_information.DrawIntMinMax(GetString("fleeMP"),"FFXIV_Common_FleeMP",1,10,0,100)
				GUI:PopItemWidth()
				GUI:EndChild()
			end
			
			if (GUI:CollapsingHeader(GetString("hacks"),"main-header-hacks",true,true)) then
				GUI:BeginChild("##main-header-hacks",0,ml_global_information.GetFrameHeight(10),true)
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("repair"),FFXIV_Common_Repair),"FFXIV_Common_Repair")
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("disabledrawing"),FFXIV_Common_DisableDrawing),"FFXIV_Common_DisableDrawing")
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("teleport"),FFXIV_Common_Teleport),"FFXIV_Common_Teleport")
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("paranoid"),FFXIV_Common_Paranoid),"FFXIV_Common_Paranoid")
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("permaSprint"),FFXIV_Common_PermaSprint),"FFXIV_Common_PermaSprint")
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("permaSwiftcast"),FFXIV_Common_PermaSwift),"FFXIV_Common_PermaSwift")
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("skipCutscene"),FFXIV_Common_SkipCutscene),"FFXIV_Common_SkipCutscene")
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("skipDialogue"),FFXIV_Common_SkipDialogue),"FFXIV_Common_SkipDialogue")
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("clickToTeleport"),FFXIV_Common_ClickTeleport),"FFXIV_Common_ClickTeleport")
				ffxivminion.GUIVarCapture(GUI:Checkbox(GetString("clickToTravel"),FFXIV_Common_ClickTravel),"FFXIV_Common_ClickTravel")
				GUI:EndChild()
			end
			
			if (GUI:CollapsingHeader(GetString("advancedSettings"),"main-header-advancedsettings",true,true)) then
				GUI:BeginChild("##main-header-advancedsettings",0,ml_global_information.GetFrameHeight(3),true)
				ml_global_information.DrawIntMinMax("Stealth - Detect Range","FFXIV_Common_StealthDetect",1,10,0,100)
				ml_global_information.DrawIntMinMax("Stealth - Remove Range","FFXIV_Common_StealthRemove",1,10,0,100)
				ffxivminion.GUIVarCapture(GUI:Checkbox("Smart Stealth",FFXIV_Common_StealthSmart),"FFXIV_Common_StealthSmart")
				GUI:EndChild()
			end
			
		end

		GUI:End()
		GUI:PopStyleColor()
	end
end

function ml_global_information.Draw( event, ticks ) 
	
	-- Main "mode" window.
	-- DrawMode 1 is fully drawn, 2 is minimized, mode visible only.
	
	--ml_global_information.DrawMainFull()
	--ml_global_information.DrawSmall()
	--ml_global_information.DrawSettings()
	
	local menu = ml_global_information.menu
	local windows = menu.windows
	local vars = menu.vars
	local flags = menu.flags
	
	if (ValidTable(windows)) then
		
		local width,height = GUI:GetScreenSize()
		local currentX = vars.menuX
		local buttonsNeeded = {}
		for i,window in pairsByKeys(windows) do
			if (ValidTable(window)) then
				if (not window.isOpen()) then
					table.insert(buttonsNeeded,window)
				end
			end
		end
		
		if (ValidTable(buttonsNeeded)) then
			local fontSize = GUI:GetWindowFontSize()
			local windowPaddingY = ml_gui.style.current.windowpadding.y
			local framePaddingY = ml_gui.style.current.framepadding.y
			local itemSpacingY = ml_gui.style.current.itemspacing.y

			GUI:SetNextWindowPos(currentX,height - ((fontSize + (framePaddingY * 2) + (itemSpacingY) + (windowPaddingY * 2)) * 2) + windowPaddingY)
			local totalSize = 30
			for i,window in pairs(buttonsNeeded) do
				totalSize = totalSize + (string.len(window.name) * 7.15) + 5
			end
			GUI:SetNextWindowSize(totalSize,fontSize + (framePaddingY * 2) + (itemSpacingY) + (windowPaddingY * 2),GUI.SetCond_Always)
			
			local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
			local buttonBG = ml_gui.style.current.colors[GUI.Col_Button]
			GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], 0)
			GUI:Begin("#MenuBar",true,flags)
			GUI:BeginChild("##ButtonRegion")
			for i,window in pairsByKeys(buttonsNeeded) do
				GUI:PushStyleColor(GUI.Col_Button, buttonBG[1], buttonBG[2], buttonBG[3], 1)
				GUI:PushStyleVar(GUI.StyleVar_FrameRounding,4)
				if (GUI:Button(window.name,string.len(window.name) * 7.15,fontSize + (framePaddingY * 2) + (itemSpacingY))) then
					if (not GUI:IsMouseDown(0) and not menu.vars.dragging) then
						window.openWindow()
					end
				end
				if (i < TableSize(buttonsNeeded)) then
					GUI:SameLine(0,5);
				end
				GUI:PopStyleVar();
				GUI:PopStyleColor();
			end
			GUI:EndChild();
			if (GUI:IsItemHoveredRect(0)) then
				if (GUI:IsMouseDragging(0)) then
					menu.vars.dragging = true
				end
			end
			GUI:End()
			GUI:PopStyleColor();
		end	

		if (menu.vars.dragging) then
			if (GUI:IsMouseDown(0)) then
				menu.vars.dragging = true
			else
				menu.vars.dragging = false
			end
			
			local x,y = GUI:GetMousePos()
			vars.menuX = (x-20)
			Settings.FFXIVMINION.menuX = vars.menuX
		end		
	end
end

-- Register Event Handlers
RegisterEventHandler("Module.Initalize",ffxivminion.HandleInit)
RegisterEventHandler("Gameloop.Update",ml_global_information.OnUpdate)
RegisterEventHandler("GUI.Update",ffxivminion.GUIVarUpdate)
RegisterEventHandler("ffxivminion.OpenSettings", ffxivminion.OpenSettings)
RegisterEventHandler("GUI.Item",		ffxivminion.HandleButtons)
RegisterEventHandler("Gameloop.Draw", ml_global_information.Draw)
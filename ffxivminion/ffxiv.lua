ffxivminion = {}
ffxivminion.foods = {}
ffxivminion.foodsHQ = {}
ffxivminion.modes = {}
ffxivminion.modesToLoad = {}
ffxivminion.busyTimer = 0
ffxivminion.declineTimer = 0

ffxivminion.loginvars = {
	loginPaused = false,
	datacenterSelected = false,
	serverSelected = false,
	charSelected = false,
}

ffxivminion.logincenters = { "None","Elemental","Gaia","Mana","Aether","Primal","Chaos" }

ffxivminion.loginservers = {
	[1] = { "None" },
	[2] = {	"None","Atomos","Carbuncle","Garuda","Kujata","Omega","Ramuh","Tonberry","Typhon","Unicorn","Aegis","Gungnir" },
	[3] = { "None","Alexander","Bahamut","Fenrir","Ifrit","Tiamat","Ultima","Valefor","Yojimbo","Zeromus","Durandal","Ridill" },
	[4] = {	"None","Anima","Asura","Belias","Chocobo","Hades","Ixion","Mandragora","Pandaemonium","Shinryu","Titan","Masamune" },
	[5] = { "None","Adamantoise","Cactuar","Coeurl","Faerie","Gilgamesh","Goblin","Jenova","Mateus","Midgardsormr","Siren","Zalera","Balmung","Sargatanas" },
	[6] = {	"None","Behemoth","Brynhildr","Diabolos","Exodus","Famfrit","Lamia","Leviathan","Malboro","Twintania","Ultros","Excalibur","Hyperion" },
	[7] = {	"None","Cerberus","Lich","Moogle","Odin","Phoenix","Shiva","Zodiark","Ragnarok" },
}

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
	login = {
		name = "Login",
		open = false,
		visible = true,
	},
	current_tab = 1,
	draw_mode = 1,
}

FFXIVMINION = {}

memoize = {}
pmemoize = {}
tasktracking = {}
setmetatable(tasktracking, { __mode = 'v' })

function ml_global_information.OnUpdate( event, tickcount )
    ml_global_information.Now = tickcount
	
	local gamestate;
	if (GetGameState and GetGameState()) then
		gamestate = GetGameState()
	else
		gamestate = 1
	end
	
	if (ml_global_information.IsYielding()) then
		return false
	end
	
	-- Switch according to the gamestate
	if ( gamestate == FFXIV.GAMESTATE.INGAME ) then
		ml_global_information.InGameOnUpdate( event, tickcount );
	elseif (gamestate == FFXIV.GAMESTATE.MAINMENUSCREEN ) then
		ml_global_information.MainMenuScreenOnUpdate( event, tickcount )
	elseif (gamestate == FFXIV.GAMESTATE.CHARACTERSCREEN ) then
		ml_global_information.CharacterSelectScreenOnUpdate( event, tickcount )
	end
end

function ml_global_information.MainMenuScreenOnUpdate( event, tickcount )
	local login = ffxivminion.loginvars
	if (not login.loginPaused) then
		if (not IsControlOpen("TitleDataCenter")) then
			if (UseControlAction("_TitleMenu","OpenDataCenter",0)) then
				ml_global_information.Await(3000, function () return IsControlOpen("TitleDataCenter") end)
			end
		else
			if (not login.datacenterSelected) then
				if (FFXIV_Login_DataCenter and FFXIV_Login_DataCenter >= 2 and FFXIV_Login_DataCenter <= 7) then
					d("trying to login on datacenter:"..tostring(FFXIV_Login_DataCenter))
					if (UseControlAction("TitleDataCenter","SetDataCenter",(FFXIV_Login_DataCenter-2))) then
						login.datacenterSelected = true
						ml_global_information.Await(3000, function () return IsControlOpen("TitleDataCenter") end)
					end
				else
					d("login paused:Attempt to issue notice")
					login.loginPaused = true
					ffxiv_dialog_manager.IssueNotice("DataCenter Required", "You must select a DataCenter to continue the login process.")
				end
			else
				if (UseControlAction("TitleDataCenter","Proceed",0)) then
					ml_global_information.Await(10000, function () return GetGameState() ~= FFXIV.GAMESTATE.MAINMENUSCREEN end)
				end
			end
		end	
	end
end

function ml_global_information.CharacterSelectScreenOnUpdate( event, tickcount )
	local login = ffxivminion.loginvars
	if (not login.loginPaused) then
		if (not login.serverSelected) then
			if (FFXIV_Login_Server and FFXIV_Login_Server > 0) then
				local servers = GetServerList()
				if (table.valid(servers)) then
					for id, e in pairs(servers) do
						if (e.name == FFXIV_Login_ServerName) then
							d("selected server id:"..tostring(id))
							SelectServer(id)
							login.serverSelected = true
							ml_global_information.Await(1000)
						end
					end
				end	
			else
				login.loginPaused = true
				ffxiv_dialog_manager.IssueNotice("Server Required", "You must select a Server to continue the login process.")
			end
		else
			if (IsControlOpen("SelectYesno")) then
				if (UseControlAction("SelectYesno","Yes",0)) then
					ml_global_information.Await(5000, function () return not IsControlOpen("_CharaSelectListMenu") end)
				end
			else
				if (UseControlAction("_CharaSelectListMenu","SelectCharacter",FFXIV_Login_Character)) then
					ml_global_information.Await(5000, function () return IsControlOpen("SelectYesno") end)
				end
			end
		end
	end
end

function ml_global_information.InGameOnUpdate( event, tickcount )
	memoize = {}
	
	if (not Player) then
		return false
	end

	if (ValidTable(ffxivminion.modesToLoad)) then
		ffxivminion.LoadModes()
		FFXIV_Common_BotRunning = false
	end
	
	if (ml_global_information.autoStartQueued) then
		ml_global_information.autoStartQueued = false
		ml_task_hub:ToggleRun() -- convert
	end
	
	FFXIV_Core_ActiveTaskCount = TableSize(tasktracking)
	
	if (ml_mesh_mgr) then
		if (not IsControlOpen("NowLoading")) then
			if (Player) then
				if (ml_global_information.queueLoader == true) then
					ml_global_information.Player_Aetherytes = GetAetheryteList(true)
					ml_global_information.queueLoader = false
				end
			end
			
			ml_mesh_mgr.OMC_Handler_OnUpdate( tickcount )
			
			local currentFile = NavigationManager.CurrentFile
			currentFile = ml_mesh_mgr.GetString(string.gsub(currentFile,ml_mesh_mgr.defaultpath.."\\", ""))
			if (currentFile ~= FFXIV_Common_NavMesh) then
				FFXIV_Common_NavMesh = currentFile
			end
		else
			if (ml_global_information.queueLoader == false) then
				ml_global_information.queueLoader = true
			end
		end
	end

	local pulseTime = tonumber(FFXIV_Core_PulseTime) or 150
	local skillPulse = (pulseTime/2)
	
	--if (TimeSince(ml_global_information.lastrun2) > skillPulse) then
		--ml_global_information.lastrun2 = tickcount
		--SkillMgr.OnUpdate()
	--end
	
	--if (TimeSince(ml_global_information.lastrun) > pulseTime) then
	if (Now() >= ml_global_information.nextRun) then
		
		ml_global_information.nextRun = tickcount + pulseTime
		ml_global_information.lastPulseShortened = false
		
        --ml_global_information.lastrun = tickcount
		
		--ffxivminion.UpdateGlobals()
		
		--[[
		local thisMeasure = collectgarbage("count")/1024
		FFXIV_Core_MemoryUsage = tostring(thisMeasure)
		FFXIV_Core_MemoryGain = tostring(thisMeasure - ml_global_information.lastMeasure)
		ml_global_information.lastMeasure = thisMeasure
		--]]
		
		-- close any social addons that might screw up behavior first
		if (FFXIV_Common_BotRunning and 
			FFXIV_Common_BotMode ~= GetString("assistMode") and
			FFXIV_Common_BotMode ~= GetString("dutyMode")) 
		then
			ffxivminion.ClearAddons()
		end

        if (ml_task_hub:CurrentTask() ~= nil) then
            FFXIV_Core_ActiveTaskName = ml_task_hub:CurrentTask().name
        end
		
		--update idle pulse count
		if (ml_global_information.idlePulseCount ~= 0) then
			FFXIV_Core_IdlePulseCount = tostring(ml_global_information.idlePulseCount)
		elseif(FFXIV_Core_IdlePulseCount ~= "") then
			FFXIV_Core_IdlePulseCount = ""
		end
		
		--update marker status
		--[[
		if (	FFXIV_Common_BotMode == GetString("grindMode") or
				FFXIV_Common_BotMode == GetString("gatherMode") or
				FFXIV_Common_BotMode == GetString("fishMode") or
				FFXIV_Common_BotMode == GetString("questMode") or
				FFXIV_Common_BotMode == GetString("huntMode") or 
				FFXIV_Common_BotMode == GetString("pvpMode") ) and
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
		--]]
		
		--local et = AceLib.API.Weather.GetDateTime() 
		--FFXIV_Common_EorzeaTime = tostring(et.hour)..":"..(et.minute < 10 and "0" or "")..tostring(et.minute)
		
		--if (SkillMgr) then
			--ffxivminion.CheckClass()
		--end
		
		if (TimeSince(ml_global_information.updateFoodTimer) > 15000) then
			ml_global_information.updateFoodTimer = tickcount
			ffxivminion.FillFoodOptions()
		end
		
		if (FFXIV_Common_BotRunning) then
			if ( TimeSince(ml_global_information.repairTimer) > 30000 ) then
				if (not ControlVisible("Gathering") and not ControlVisible("Synthesis") and not ControlVisible("SynthesisSimple") and not Player.incombat) then
					if (NeedsRepair()) then
						Repair()
					end
					ml_global_information.repairTimer = tickcount
				end
			end
	
			if ( FFXIV_Common_Food ~= "None") then
				if ( TimeSince(ml_global_information.foodCheckTimer) > 10000 and not Player.ismounted and not Player:IsMoving()) then
					if (not ControlVisible("Gathering") and not ControlVisible("Synthesis") and not ControlVisible("SynthesisSimple")) then
						Eat()
						ml_global_information.foodCheckTimer = tickcount
					end
				end
			end
			
			if (FFXIV_Common_ChocoItemString ~= "None") then
				if ( TimeSince(ml_global_information.rootCheckTimer) > 10000 and not Player.ismounted and not IsMounting() and IsCompanionSummoned()) then
					ml_global_information.rootCheckTimer = tickcount
					
					local itemBuffs = ml_global_information.chocoItemBuffs
					if (table.valid(itemBuffs)) then
						for itemid,itemdetails in pairs(itemBuffs) do
							if (FFXIV_Common_ChocoItemString == itemdetails.name) then
								local item = nil
								for i = 0,3 do
									local bag = Inventory:Get(i)
									if (table.valid(bag)) then
										for bslot,bitem in pairs(bag) do
											if (item.id == itemid) then
												item = bitem
											end
										end
									end
								end
								
								local companion = GetCompanionEntity()
								if (item and item.isready and companion and companion.alive) then
									local buffString = tostring(itemdetails.buff1).."+"..tostring(itemdetails.buff2)
									if (MissingBuffs(companion, buffString)) then
										Player:Stop()
										local newTask = ffxiv_task_useitem.Create()
										newTask.itemid = itemid
										--newTask.targetid = companion.id
										ml_task_hub:CurrentTask():AddSubTask(newTask)
									end
								end
							end
						end
					end
				end
			end
		end
			
		if (ml_task_hub.shouldRun) then

			--[[
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
			--]]
			
			if (not ml_task_hub:Update()) then
				d("No task queued, please select a valid bot mode in the Settings drop-down menu")
			else
				--d("running cne")
			end
		end
    end
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

function ffxivminion.GetSetting(strSetting,default)
	if (Settings.FFXIVMINION[strSetting] == nil) then
		Settings.FFXIVMINION[strSetting] = default
	end
	return Settings.FFXIVMINION[strSetting]	
end

function ffxivminion.SetMainVars()
	-- Login
	local uuid = GetUUID()
	if ( Settings.FFXIVMINION.FFXIV_Login_DataCenters and string.valid(uuid) and Settings.FFXIVMINION.FFXIV_Login_DataCenters[uuid] ) then
		FFXIV_Login_DataCenterName = Settings.FFXIVMINION.FFXIV_Login_DataCenters[uuid]
	else
		FFXIV_Login_DataCenterName = ffxivminion.GetSetting("FFXIV_Login_DataCenterName",ffxivminion.logincenters[1])
	end
	FFXIV_Login_DataCenter = GetKeyByValue(FFXIV_Login_DataCenterName,ffxivminion.logincenters)
	
	d("datacentername:"..tostring(FFXIV_Login_DataCenterName))
	d("datacenter:"..tostring(FFXIV_Login_DataCenter))
	
	if ( Settings.FFXIVMINION.FFXIV_Login_Servers and string.valid(uuid) and Settings.FFXIVMINION.FFXIV_Login_Servers[uuid] ) then
		FFXIV_Login_ServerName = Settings.FFXIVMINION.FFXIV_Login_Servers[uuid]
	else
		FFXIV_Login_ServerName = ffxivminion.GetSetting("FFXIV_Login_ServerName",ffxivminion.loginservers[FFXIV_Login_DataCenter][1])
	end
	FFXIV_Login_Server = GetKeyByValue(FFXIV_Login_ServerName,ffxivminion.loginservers[FFXIV_Login_DataCenter])
	if (FFXIV_Login_Server == nil) then 
		FFXIV_Login_Server = 1
		FFXIV_Login_ServerName = ""
	end
	
	d("loginservername:"..tostring(FFXIV_Login_ServerName))
	d("loginserver:"..tostring(FFXIV_Login_Server))
	
	if ( Settings.FFXIVMINION.FFXIV_Login_Characters and string.valid(uuid) and Settings.FFXIVMINION.FFXIV_Login_Characters[uuid] ) then
		FFXIV_Login_Character = Settings.FFXIVMINION.FFXIV_Login_Characters[uuid]
	else
		FFXIV_Login_Character = ffxivminion.GetSetting("FFXIV_Login_Character",0)
	end
	
	-- In-Game
	FFXIV_Common_Profile = GetString("none")
	FFXIV_Common_ProfileIndex = 1
	FFXIV_Common_ProfileList = {GetString("none")}
	
	FFXIV_Common_NavMesh = GetString("none")
	FFXIV_Common_NavMeshIndex = 1
	FFXIV_Common_MeshList = {GetString("none")}
	
	FFXIV_Common_BotModeIndex = 1
	if ( Settings.FFXIVMINION.gBotModes and string.valid(uuid) and Settings.FFXIVMINION.gBotModes[uuid] ) then
		FFXIV_Common_BotMode = Settings.FFXIVMINION.gBotModes[uuid]
	else
		FFXIV_Common_BotMode = ffxivminion.GetSetting("FFXIV_Common_BotMode",GetString("assistMode"))
	end
	FFXIV_Common_ModeList = {GetString("none")}
	
	FFXIV_Common_SkillProfile = ffxivminion.GetSetting("FFXIV_Common_SkillProfile",GetString("assistMode"))
	FFXIV_Common_SkillProfileIndex = 1
	FFXIV_Common_SkillProfileList = {GetString("none")}
	
	FFXIV_Common_BotRunning = false
	FFXIV_Core_Version = 2
	FFXIV_Core_PulseTime = ffxivminion.GetSetting("FFXIV_Core_PulseTime",150)
	FFXIV_Core_ActiveTaskCount = 0
	FFXIV_Core_ActiveTaskName = ""
	FFXIV_Core_ActiveTaskDelay = 0
	FFXIV_Core_IdlePulseCount = 0
	FFXIV_Core_MemoryUsage = 0
	FFXIV_Core_MemoryGain = 0
	
	FFXIV_Common_EorzeaTime = ""
	FFXIV_Common_EnableLog = ffxivminion.GetSetting("FFXIV_Common_EnableLog",false)
	FFXIV_Common_LogCNE = ffxivminion.GetSetting("FFXIV_Common_LogCNE",false)
	
	FFXIV_Common_LogLevel = ffxivminion.GetSetting("FFXIV_Common_LogLevel",1)
	FFXIV_Common_LogLevels = {1,2,3}
	
	FFXIV_Common_MountIndex = 1
	FFXIV_Common_Mounts = {GetString("none")}
	FFXIV_Common_Mount = ffxivminion.GetSetting("FFXIV_Common_Mount",GetString("none"))
	ffxivminion.FillMountOptions()
	
	FFXIV_Common_UseMount = ffxivminion.GetSetting("FFXIV_Common_UseMount",true)
	FFXIV_Common_MountDist = ffxivminion.GetSetting("FFXIV_Common_MountDist",75)
	FFXIV_Common_UseSprint = ffxivminion.GetSetting("FFXIV_Common_UseSprint",false)
	FFXIV_Common_SprintDist = ffxivminion.GetSetting("FFXIV_Common_SprintDist",50)
	FFXIV_Common_RandomPaths = ffxivminion.GetSetting("FFXIV_Common_RandomPaths",false)
	
	FFXIV_Craft_UseHQMats = ffxivminion.GetSetting("FFXIV_Craft_UseHQMats",true)
	FFXIV_Common_UseEXPManuals = ffxivminion.GetSetting("FFXIV_Common_UseEXPManuals",true)
	FFXIV_Common_DeclineParties = ffxivminion.GetSetting("FFXIV_Common_DeclineParties",true)
	
	FFXIV_Common_Food = ffxivminion.GetSetting("FFXIV_Common_Food",GetString("none"))
	FFXIV_Common_FoodIndex = 1
	FFXIV_Common_Foods = {GetString("none")}
	ffxivminion.FillFoodOptions()
	
	FFXIV_Common_AutoStart = ffxivminion.GetSetting("FFXIV_Common_AutoStart",false)
	FFXIV_Common_Teleport = ffxivminion.GetSetting("FFXIV_Common_Teleport",false)
	FFXIV_Duty_Teleport = ffxivminion.GetSetting("FFXIV_Duty_Teleport",true)
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
	
	FFXIV_Common_ChocoStance = ffxivminion.GetSetting("FFXIV_Common_ChocoStance",1)
	FFXIV_Common_ChocoStances = {GetString("stFree"), GetString("stDefender"), GetString("stAttacker"), GetString("stHealer"), GetString("stFollow")}
	FFXIV_Common_ChocoStanceString = FFXIV_Common_ChocoStances[FFXIV_Common_ChocoStance]
	
	FFXIV_Common_ChocoItem = ffxivminion.GetSetting("FFXIV_Common_ChocoItem",1)
	FFXIV_Common_ChocoItems = {"Curiel Root (EXP)", "Sylkis Bud (ATK)", "Mimmet Gourd (Heal)", "Tantalplant (HP)", "Pahsana Fruit (ENM)"}
	FFXIV_Common_ChocoItemString = FFXIV_Common_ChocoItems[FFXIV_Common_ChocoItem]
	
	FFXIV_Common_AvoidAOE = ffxivminion.GetSetting("FFXIV_Common_AvoidAOE",false)
	FFXIV_Common_AvoidHP = ffxivminion.GetSetting("FFXIV_Common_AvoidHP",100)
	FFXIV_Common_RestHP = ffxivminion.GetSetting("FFXIV_Common_RestHP",70)
	FFXIV_Common_RestMP = ffxivminion.GetSetting("FFXIV_Common_RestMP",0)
	FFXIV_Common_PotionHP = ffxivminion.GetSetting("FFXIV_Common_PotionHP",50)
	FFXIV_Common_PotionMP = ffxivminion.GetSetting("FFXIV_Common_PotionMP",0)
	FFXIV_Common_FleeHP = ffxivminion.GetSetting("FFXIV_Common_FleeHP",25)
	FFXIV_Common_FleeMP = ffxivminion.GetSetting("FFXIV_Common_FleeMP",0)
	FFXIV_Common_AutoEquip = ffxivminion.GetSetting("FFXIV_Common_AutoEquip",true)
	FFXIV_Questing_AutoEquip = ffxivminion.GetSetting("FFXIV_Questing_AutoEquip",true)	
	FFXIV_Common_StealthDetect = ffxivminion.GetSetting("FFXIV_Common_StealthDetect",25)
	FFXIV_Common_StealthRemove = ffxivminion.GetSetting("FFXIV_Common_StealthRemove",30)
	FFXIV_Common_StealthSmart = ffxivminion.GetSetting("FFXIV_Common_StealthSmart",true)
	
	ml_global_information.autoStartQueued = FFXIV_Common_AutoStart		
	--GameHacks:Disable3DRendering(FFXIV_Common_DisableDrawing)
	--GameHacks:SkipCutscene(FFXIV_Common_SkipCutscene)
	--GameHacks:SkipDialogue(FFXIV_Common_SkipDialogue)
	--GameHacks:SetClickToTeleport(FFXIV_Common_ClickTeleport)
	--GameHacks:SetClickToTravel(FFXIV_Common_ClickTravel)
	--GameHacks:SetPermaSprint(FFXIV_Common_PermaSprint)
	--GameHacks:SetPermaSwiftCast(FFXIV_Common_PermaSwift)
	--Crafting:UseHQMats(FFXIV_Craft_UseHQMats)
end

-- Module Event Handler
function ffxivminion.HandleInit()

	-- Build bottom menu for new GUI addons.
	ffxivminion.GUI.settings.main_tabs = GUI_CreateTabs("botStatus,generalSettings,companion,playerHPMPTP,hacks,advancedSettings",true)
	ml_global_information.BuildMenu()
	ffxivminion.SetMainVars()
	
	FFXIV_Common_NavMesh = GetString("none")
	
	-- Add "known" modes, safe.
	--ffxivminion.AddMode(GetString("grindMode"), ffxiv_task_grind) 
	--ffxivminion.AddMode(GetString("fishMode"), ffxiv_task_fish)
	--ffxivminion.AddMode(GetString("gatherMode"), ffxiv_task_gather)
	--ffxivminion.AddMode(GetString("craftMode"), ffxiv_task_craft)
	ffxivminion.AddMode(GetString("assistMode"), ffxiv_task_assist)
	--ffxivminion.AddMode(GetString("partyMode"), ffxiv_task_party)
	--ffxivminion.AddMode(GetString("pvpMode"), ffxiv_task_pvp)
	--ffxivminion.AddMode(GetString("frontlines"), ffxiv_task_frontlines)
	--ffxivminion.AddMode(GetString("huntMode"), ffxiv_task_hunt)
	--ffxivminion.AddMode(GetString("huntlogMode"), ffxiv_task_huntlog)
	--ffxivminion.AddMode(GetString("quickStartMode"), ffxiv_task_qs_wrapper)
	--ffxivminion.AddMode("NavTest", ffxiv_task_test)
	
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
	
	--[[
	FFXIV_Common_SkillProfileList = {GetString("none")}
    local profilelist = dirlist(SkillMgr.profilepath,".*lua")
    if (ValidTable(profilelist)) then
		for i,profile in pairs(profilelist) do		
            profile = string.gsub(profile, ".lua", "")
			table.insert(FFXIV_Common_SkillProfileList,profile)
        end		
    end
	--]]

	FFXIV_Core_ActiveTaskName = ""
	FFXIV_Common_BotRunning = false
	
    local fateBlacklist = ml_list_mgr.AddList("FATE Blacklist")
	local fateWhitelist = ml_list_mgr.AddList("FATE Whitelist")
	local monsterBlacklist = ml_list_mgr.AddList(GetString("monsters"))
	
	--[[
	spotList.GUI.vars = { temptimer = 0, temptext = "", mapid = 0, name = "", pos = { x = 0, y = 0, z = 0} }
	spotList.draw = spotList.DefaultDraw2
	--]]
	
	gForceAutoEquip = false
	ml_gui.ui_mgr:AddMember({ id = "FFXIVMINION##MENU_SETTINGS", name = "Settings", onClick = function() ffxivminion.GUI.settings.open = not ffxivminion.GUI.settings.open end, tooltip = "Open the FFXIVMinion settings."},"FFXIVMINION##MENU_HEADER")
end

function ffxivminion.SwitchMode(mode)	
	local task = ffxivminion.modes[mode]
    if (task ~= nil) then
		ml_global_information.mainTask = task
		
		if (FFXIV_Common_BotRunning) then
			ml_task_hub.ToggleRun()
		end
		
		--[[
		--Setup default options.
		if (FFXIV_Common_BotMode == GetString("dutyMode")) then
			if (Duties) then
				Duties.UpdateProfiles()
			end
			FFXIV_Common_Teleport = FFXIV_Common_TeleportDefaultDuties
			FFXIV_Common_Paranoid = "0"
			FFXIV_Common_SkipCutscene = "1"
			FFXIV_Common_SkipDialogue = "1"
			FFXIV_Common_DisableDrawing = Settings.FFXIVMINION.FFXIV_Common_DisableDrawing
			GameHacks:SkipCutscene(FFXIV_Common_SkipCutscene)
			GameHacks:SkipDialogue(FFXIV_Common_SkipDialogue)
			GameHacks:Disable3DRendering(FFXIV_Common_DisableDrawing)
			SendTextCommand("/busy off")
			FFXIV_Common_AutoEquip = Settings.FFXIVMINION.FFXIV_Common_AutoEquip
		elseif (FFXIV_Common_BotMode == GetString("questMode")) then
			if (Questing) then
				Questing.UpdateProfiles()
			end
			FFXIV_Common_Teleport = Settings.FFXIVMINION.FFXIV_Common_Teleport
			FFXIV_Common_Paranoid = Settings.FFXIVMINION.FFXIV_Common_Paranoid
			FFXIV_Common_SkipCutscene = "1"
			FFXIV_Common_SkipDialogue = "1"
			FFXIV_Common_DisableDrawing = Settings.FFXIVMINION.FFXIV_Common_DisableDrawing
			GameHacks:SkipCutscene(FFXIV_Common_SkipCutscene)
			GameHacks:SkipDialogue(FFXIV_Common_SkipDialogue)
			GameHacks:Disable3DRendering(FFXIV_Common_DisableDrawing)
			FFXIV_Common_AvoidAOE = "1"
			FFXIV_Common_AutoEquip = gAutoEquipDefaultQuesting
		end
		--]]
	end
end

function ffxivminion.SetModeOptions(mode)
	local task = ffxivminion.modes[mode]
	if (task ~= nil) then
		if (task.SetModeOptions ~= nil) then
			task.SetModeOptions()
		else
			FFXIV_Common_Teleport = Settings.FFXIVMINION.FFXIV_Common_Teleport
			FFXIV_Common_Paranoid = Settings.FFXIVMINION.FFXIV_Common_Paranoid
			FFXIV_Common_DisableDrawing = Settings.FFXIVMINION.FFXIV_Common_DisableDrawing
			FFXIV_Common_SkipCutscene = Settings.FFXIVMINION.FFXIV_Common_SkipCutscene
			FFXIV_Common_SkipDialogue = Settings.FFXIVMINION.FFXIV_Common_SkipDialogue
			--GameHacks:SkipCutscene(FFXIV_Common_SkipCutscene)
			--GameHacks:SkipDialogue(FFXIV_Common_SkipDialogue)
			--GameHacks:Disable3DRendering(FFXIV_Common_DisableDrawing)
			FFXIV_Common_AvoidAOE = Settings.FFXIVMINION.FFXIV_Common_AvoidAOE
			FFXIV_Common_AutoEquip = Settings.FFXIVMINION.FFXIV_Common_AutoEquip			
			FFXIV_Common_Profile = "NA"
			FFXIV_Common_ProfileIndex = 1
			FFXIV_Common_ProfileList = { "NA" }
		end
	end
end

function ffxivminion.SetMode(mode)
    local task = ffxivminion.modes[mode]
    if (task ~= nil) then
		--GameHacks:SkipCutscene(FFXIV_Common_SkipCutscene)
		--GameHacks:SkipDialogue(FFXIV_Common_SkipDialogue)
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
			["FFXIV_Common_AvoidHP"] = true,
			["FFXIV_Common_RestHP"] = true,
			["FFXIV_Common_RestMP"] = true,
			["FFXIV_Common_PotionHP"] = true,
			["FFXIV_Common_PotionMP"] = true,
			["FFXIV_Common_FleeHP"] = true,
			["FFXIV_Common_FleeMP"] = true,
			["FFXIV_Common_UseSprint"] = true,
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
			[FF.JOBS.ARCANIST] 		= ffxiv_combat_arcanist,
			[FF.JOBS.ARCHER]		= ffxiv_combat_archer,
			[FF.JOBS.BARD]			= ffxiv_combat_bard,
			[FF.JOBS.BLACKMAGE]		= ffxiv_combat_blackmage,
			[FF.JOBS.CONJURER]		= ffxiv_combat_conjurer,
			[FF.JOBS.DRAGOON]		= ffxiv_combat_dragoon,
			[FF.JOBS.GLADIATOR] 	= ffxiv_combat_gladiator,
			[FF.JOBS.LANCER]		= ffxiv_combat_lancer,
			[FF.JOBS.MARAUDER] 		= ffxiv_combat_marauder,
			[FF.JOBS.MONK] 			= ffxiv_combat_monk,
			[FF.JOBS.NINJA] 		= ffxiv_combat_ninja,
			[FF.JOBS.ROGUE]			= ffxiv_combat_rogue,
			[FF.JOBS.PALADIN] 		= ffxiv_combat_paladin,
			[FF.JOBS.PUGILIST] 		= ffxiv_combat_pugilist,
			[FF.JOBS.SCHOLAR] 		= ffxiv_combat_scholar,
			[FF.JOBS.SUMMONER] 		= ffxiv_combat_summoner,
			[FF.JOBS.THAUMATURGE] 	= ffxiv_combat_thaumaturge,
			[FF.JOBS.WARRIOR] 	 	= ffxiv_combat_warrior,
			[FF.JOBS.WHITEMAGE] 	 = ffxiv_combat_whitemage,
			[FF.JOBS.ROGUE]			= ffxiv_combat_rogue,
			[FF.JOBS.NINJA]			= ffxiv_combat_ninja,
			[FF.JOBS.MACHINIST]		= ffxiv_combat_machinist,
			[FF.JOBS.DARKKNIGHT]	= ffxiv_combat_darkknight,
			[FF.JOBS.ASTROLOGIAN]	= ffxiv_combat_astrologian,		
			[FF.JOBS.BOTANIST] 		= ffxiv_gather_botanist,
			[FF.JOBS.FISHER] 		= ffxiv_gather_fisher,
			[FF.JOBS.MINER] 		= ffxiv_gather_miner,
			
			[FF.JOBS.CARPENTER] 	= ffxiv_crafting_carpenter,
			[FF.JOBS.BLACKSMITH] 	= ffxiv_crafting_blacksmith,
			[FF.JOBS.ARMORER] 		= ffxiv_crafting_armorer,
			[FF.JOBS.GOLDSMITH] 	= ffxiv_crafting_goldsmith,
			[FF.JOBS.LEATHERWORKER] = ffxiv_crafting_leatherworker,
			[FF.JOBS.WEAVER] 		= ffxiv_crafting_weaver,
			[FF.JOBS.ALCHEMIST] 	= ffxiv_crafting_alchemist,
			[FF.JOBS.CULINARIAN] 	= ffxiv_crafting_culinarian,
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
		--SkillMgr.UseDefaultProfile()
		ffxivminion.VerifyClassSettings()
		ffxivminion.UseClassSettings()
		return
	end
    
    if (ml_global_information.CurrentClassID ~= Player.job) then
        ml_global_information.CurrentClass = playerClass
        ml_global_information.CurrentClassID = Player.job
		ml_global_information.AttackRange = playerClass.range or 2
		--SkillMgr.UseDefaultProfile()
		ffxivminion.VerifyClassSettings()
		ffxivminion.UseClassSettings()
		
		-- autosetting the correct botmode
		
		if (FFXIV_Common_BotMode ~= GetString("questMode")) then
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
			elseif ( FFXIV_Common_BotMode == GetString("gatherMode") or FFXIV_Common_BotMode == GetString("fishMode") or FFXIV_Common_BotMode == GetString("craftMode")) then
				newModeName = GetString("assistMode")				
			end
					
			if (FFXIV_Common_BotMode ~= newModeName and newModeName ~= "") then
				ffxivminion.SwitchMode(newModeName)
			end
		end
    end
end

function ffxivminion.CheckMode()
    local task = ffxivminion.modes[FFXIV_Common_BotMode]
    if (task ~= nil) then
        if (not ml_task_hub:CheckForTask(task)) then
            ffxivminion.SetMode(FFXIV_Common_BotMode)
        end
    elseif (FFXIV_Common_BotMode == "None") then
        ml_task_hub:ClearQueues()
    end
end

function ffxivminion.UpdateGlobals()
	if (Player) then
		ml_global_information.Player_Aetherytes = GetAetheryteList()
		ml_global_information.Player_Map = Player.localmapid
		ml_global_information.Player_HP = Player.hp
		ml_global_information.Player_MP = Player.mp
		ml_global_information.Player_TP = Player.tp
	end
end

function ml_global_information.Reset()
    ml_task_hub:ClearQueues()
    ffxivminion.CheckMode()
end

function ml_global_information.Stop()
    if (Player:IsMoving()) then
        Player:Stop()
    end
	--SkillMgr.receivedMacro = {}
	--GameHacks:SkipCutscene(FFXIV_Common_SkipCutscene)
	--GameHacks:SkipDialogue(FFXIV_Common_SkipDialogue)
end

function ffxivminion.AddMode(name, task)
	d("added mode ["..name.."] with type ["..tostring(type(task)).."]")
	task.friendly = name
	ffxivminion.modesToLoad[name] = task
end

-- New GUI methods.
function ffxivminion.FillFoodOptions()
	ml_global_information.foods = {}
	
	for i = 0,3 do
		local bag = Inventory:Get(i)
		if (table.valid(bag)) then
			local ilist = bag:GetList()
			if (table.valid(ilist)) then
				for slot,item in pairs(ilist) do
					if (item.category == 5) then
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

function ffxivminion.FillMountOptions()
	FFXIV_Common_Mounts = { GetString("none") }
	local mounts = ActionList:Get(13)
	if (mounts) then
		for k,v in pairs(mounts) do
			table.insert(FFXIV_Common_Mounts,v.name)
			if (v.name == FFXIV_Common_Mount) then
				FFXIV_Common_MountIndex = table.size(FFXIV_Common_Mounts)
			end
		end
	end
end

function ffxivminion.LoadModes()
	
	if (ValidTable(ffxivminion.modesToLoad)) then
		for modeName,task in pairs(ffxivminion.modesToLoad) do
			d("Loading mode ["..tostring(modeName).."].")
			ffxivminion.modes[modeName] = task
			if (task.UIInit) then
				task:UIInit()
			end
		end
		
		-- Empty out the table to prevent reloading.
		ffxivminion.modesToLoad = {}
	end
	
	FFXIV_Common_ModeList = {}
	if (ValidTable(ffxivminion.modes)) then
		local modes = ffxivminion.modes
		for modeName,task in spairs(modes, function(modes,a,b) return a.friendly < b.friendly end) do
			table.insert(FFXIV_Common_ModeList,i)
			if (modeName == FFXIV_Common_BotMode) then
				FFXIV_Common_BotModeIndex = table.size(FFXIV_Common_ModeList)
			end
		end				
	end
	
	d("load modes: mode list has ["..tostring(table.size(FFXIV_Common_ModeList)).."]")
	
	local uuid = GetUUID()
	if ( Settings.FFXIVMINION.gBotModes and string.valid(uuid) and Settings.FFXIVMINION.gBotModes[uuid] ) then
		FFXIV_Common_BotMode = Settings.FFXIVMINION.gBotModes[uuid]
	else
		FFXIV_Common_BotMode = ffxivminion.GetSetting(FFXIV_Common_BotMode,GetString("grindMode"))
	end
	
	d("last bot mode setting:"..tostring(FFXIV_Common_BotMode))
	
	local modeIndex = GetKeyByValue(Retranslate(FFXIV_Common_BotMode),FFXIV_Common_ModeList)
	if (modeIndex) then
		FFXIV_Common_BotModeIndex = modeIndex
	else
		local backupIndex = GetKeyByValue(GetString("assistMode"),FFXIV_Common_ModeList)
		FFXIV_Common_BotModeIndex = backupIndex
		FFXIV_Common_BotMode = GetString("assistMode")
	end
	
	d("new bot mode setting:"..tostring(FFXIV_Common_BotMode))
	
	ffxivminion.SwitchMode(FFXIV_Common_BotMode)
end

-- clear any addons displayed by social actions like trade/party invites
function ffxivminion.ClearAddons()
	if (ffxivminion.busyTimer ~= 0 and Now() > ffxivminion.busyTimer) then
		SendTextCommand("/busy off")
		ffxivminion.busyTimer = 0
	end
	
	--trade window
	if (IsControlOpen("Trade")) then
		--local traders = EntityList("nearest,maxdistance=5,chartype=4")
		Player:Stop()
		ml_global_information.Await(2000, 
			function () 
				return not Player:IsMoving() 
			end,
			function ()
				SendTextCommand("/busy on")
				Player:CheckTradeWindow()
				ffxivminion.busyTimer = Now() + 60000
			end
		)
		return true
	end
	
	--party invite
	if (IsControlOpen("_NotificationParty") and toboolean(FFXIV_Common_DeclineParties)) then
		if (IsControlOpen("SelectYesno")) then
			if(ffxivminion.declineTimer == 0) then
				ffxivminion.declineTimer = Now() + math.random(3000,5000)
			elseif(Now() > ffxivminion.declineTimer) then
				if(not ffxivminion.inviteDeclined) then
					PressYesNo(false)
					ffxivminion.inviteDeclined = true
					ffxivminion.declineTimer = 0
				end
			end
		else
			SendTextCommand("/decline")
		end
	end
end

function ml_global_information.DrawMainFull()
	local gamestate = GetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		if (ffxivminion.GUI.main.open) then
			--if (ffxivminion.GUI.draw_mode == 1) then
				GUI:SetNextWindowSize(300,300,GUI.SetCond_Once) --set the next window size, only on first ever	
				GUI:SetNextWindowCollapsed(false,GUI.SetCond_Once)
				
				local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
				GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
				
				ffxivminion.GUI.main.visible, ffxivminion.GUI.main.open = GUI:Begin(ffxivminion.GUI.main.name, ffxivminion.GUI.main.open)
				if ( ffxivminion.GUI.main.visible ) then 
				
					local x, y = GUI:GetWindowPos()
					local width, height = GUI:GetWindowSize()
					
					ffxivminion.GUI.x = x; ffxivminion.GUI.y = y; ffxivminion.GUI.width = width; ffxivminion.GUI.height = height;
					
					--[[
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
					--]]
					
					GUI:PushItemWidth(120)
					local modeChanged = GUI_Combo(GetString("botMode"), "FFXIV_Common_BotModeIndex", "FFXIV_Common_BotMode", FFXIV_Common_ModeList)
					if (modeChanged) then
						ffxivminion.SwitchMode(FFXIV_Common_BotMode)
						local uuid = GetUUID()
						if ( string.valid(uuid) ) then
							if  ( Settings.FFXIVMINION.gBotModes == nil ) then Settings.FFXIVMINION.gBotModes = {} end
							Settings.FFXIVMINION.gBotModes[uuid] = FFXIV_Common_BotMode
						end
					end
					GUI:PopItemWidth()

					GUI:BeginChild("##main-task-section",0,-50,false)
					local mainTask = ml_global_information.mainTask
					if (mainTask) then
						if (mainTask.Draw) then
							mainTask:Draw()
						end
					end
					GUI:EndChild()
					
					local width = GUI:GetContentRegionAvailWidth()
					if (GUI:Button(GetString("advancedSettings"),width,20)) then
						ffxivminion.GUI.settings.open = not ffxivminion.GUI.settings.open
					end
					if (GUI:Button("Start / Stop",width,20)) then
						ml_global_information.ToggleRun()	
					end
				end
				GUI:End()
				GUI:PopStyleColor()
			--end
		end
	end
end

function ml_global_information.DrawSmall()
	local gamestate = GetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		if (ffxivminion.GUI.main.open) then		
			--if (ffxivminion.GUI.draw_mode ~= 1) then
				GUI:SetNextWindowSize(200,50,GUI.SetCond_Always) --set the next window size, only on first ever	
				local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
				GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .35)
				
				local flags = (GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
				GUI:Begin("FFXIVMINION_MAIN_WINDOW_MINIMIZED", true, flags)
				
				--[[			
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
				--]]
				
				local child_color = (FFXIV_Common_BotRunning == true and { r = 0, g = .10, b = 0, a = .75 }) or { r = .10, g = 0, b = 0, a = .75 }
				GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,10)
				GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)

				GUI:BeginChild("##label-"..FFXIV_Common_BotMode,120,35,true)
				GUI:AlignFirstTextHeightToWidgets()
				GUI:Text(FFXIV_Common_BotMode)
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
end

function ml_global_information.DrawSettings()
	local gamestate = GetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		if (ffxivminion.GUI.settings.open) then
			GUI:SetNextWindowSize(300,300,GUI.SetCond_Once) --set the next window size, only on first ever	
			GUI:SetNextWindowCollapsed(false,GUI.SetCond_Once)
			
			local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
			GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
			
			ffxivminion.GUI.settings.visible, ffxivminion.GUI.settings.open = GUI:Begin(ffxivminion.GUI.settings.name, ffxivminion.GUI.settings.open)
			if ( ffxivminion.GUI.settings.visible ) then 
				
				GUI_DrawTabs(ffxivminion.GUI.settings.main_tabs)
				local tabs = ffxivminion.GUI.settings.main_tabs
				
				if (tabs.tabs[1].isselected) then
					GUI:BeginChild("##main-header-botstatus",0,GUI_GetFrameHeight(10),true)
					GUI:PushItemWidth(100)
					GUI_DrawIntMinMax(GetString("pulseTime"),"FFXIV_Core_PulseTime",5,10,30,2000)
					GUI:PopItemWidth()
					GUI:PushItemWidth(60)
					GUI:LabelText("# Active Task Count",FFXIV_Core_ActiveTaskCount)
					GUI:LabelText("# Active Task Name",FFXIV_Core_ActiveTaskName)
					GUI:LabelText("# Active Task Delay",FFXIV_Core_ActiveTaskDelay)
					GUI:LabelText("Idle Pulse Count",FFXIV_Core_IdlePulseCount)
					GUI:PopItemWidth()
					GUI:PushItemWidth(100)
					GUI_Capture(GUI:Checkbox(GetString("enableLog"),FFXIV_Common_EnableLog),"FFXIV_Common_EnableLog");
					GUI_Capture(GUI:Checkbox(GetString("logCNE"),FFXIV_Common_LogCNE),"FFXIV_Common_LogCNE");
					GUI_Capture(GUI:Combo("Log Level", FFXIV_Common_LogLevel, FFXIV_Common_LogLevels ),"FFXIV_Common_LogLevel")
					
					GUI:LabelText("Eorzea Time",FFXIV_Common_EorzeaTime)
					GUI:LabelText("Memory Usage",FFXIV_Core_MemoryUsage)
					GUI:PopItemWidth()
					GUI:EndChild()
				end
				
				if (tabs.tabs[2].isselected) then
					GUI:BeginChild("##main-header-generalsettings",0,GUI_GetFrameHeight(10),true)
					GUI:PushItemWidth(100)
					
					GUI_Capture(GUI:Checkbox(GetString("autoStartBot"),FFXIV_Common_AutoStart),"FFXIV_Common_AutoStart");
					GUI_Capture(GUI:Checkbox(GetString("autoEquip"),FFXIV_Common_AutoEquip),"FFXIV_Common_AutoEquip",
						function ()
							if (FFXIV_Common_BotMode == GetString("questMode")) then
								 GUI_Set("FFXIV_Questing_AutoEquip",FFXIV_Common_AutoEquip)
							end
						end
					);
					GUI_Capture(GUI:Checkbox(GetString("useMount"),FFXIV_Common_UseMount),"FFXIV_Common_UseMount", 
						function ()
							if (FFXIV_Common_Mount == GetString("none")) then
								FFXIV_Common_MountIndex = 1
								 GUI_Set("FFXIV_Common_Mount",FFXIV_Common_Mounts[1])
							end
						end					
					)
					GUI_DrawIntMinMax(GetString("mountDist"),"FFXIV_Common_MountDist",5,10,0,200)
					GUI_Combo(GetString("mount"), "FFXIV_Common_MountIndex", "FFXIV_Common_Mount", FFXIV_Common_Mounts)
					GUI:SameLine(0,5)
					if (GUI:ImageButton("##main-mounts-refresh",ml_global_information.path.."\\GUI\\UI_Textures\\change.png", 18, 18)) then
						ffxivminion.FillMountOptions()
					end
					GUI_Capture(GUI:Checkbox(GetString("useSprint"),FFXIV_Common_UseSprint),"FFXIV_Common_UseSprint",function () ffxivminion.SaveClassSettings("FFXIV_Common_UseSprint",FFXIV_Common_UseSprint) end );
					GUI_DrawIntMinMax(GetString("sprintDist"),"FFXIV_Common_SprintDist",5,10,0,200)
					GUI_Combo(GetString("food"), "FFXIV_Common_FoodIndex", "FFXIV_Common_Food", FFXIV_Common_Foods)
					GUI:SameLine(0,5)
					if (GUI:ImageButton("##main-food-refresh",ml_global_information.path.."\\GUI\\UI_Textures\\change.png", 18, 18)) then
						ffxivminion.FillFoodOptions()
					end
					GUI_Capture(GUI:Checkbox(GetString("avoidAOE"),FFXIV_Common_AvoidAOE),"FFXIV_Common_AvoidAOE");
					GUI_Capture(GUI:Checkbox(GetString("randomPaths"),FFXIV_Common_RandomPaths),"FFXIV_Common_RandomPaths");

					GUI:PopItemWidth()
					GUI:EndChild()
				end	
				
				if (tabs.tabs[3].isselected) then
					GUI:BeginChild("##main-header-companion",0,GUI_GetFrameHeight(3),true)
					
					GUI_Capture(GUI:Checkbox(GetString("assistMode"),FFXIV_Common_ChocoAssist),"FFXIV_Common_ChocoAssist"); GUI:SameLine()
					GUI_Capture(GUI:Checkbox(GetString("grindMode"),FFXIV_Common_ChocoGrind),"FFXIV_Common_ChocoGrind"); GUI:SameLine()
					GUI_Capture(GUI:Checkbox(GetString("questMode"),FFXIV_Common_ChocoQuest),"FFXIV_Common_ChocoQuest");
					
					GUI:PushItemWidth(160)
					GUI_Combo(GetString("stance"), "FFXIV_Common_ChocoStance", "FFXIV_Common_ChocoStanceString", FFXIV_Common_ChocoStances)
					GUI_Combo("Feed", "FFXIV_Common_ChocoItem", "FFXIV_Common_ChocoItemString", FFXIV_Common_ChocoItems)
					GUI:PopItemWidth()
					GUI:EndChild()
				end
				
				if (tabs.tabs[4].isselected) then
					GUI:BeginChild("##main-header-playerhpmptp",0,GUI_GetFrameHeight(7),true)
					GUI:PushItemWidth(120)

					GUI_DrawIntMinMax(GetString("avoidHP"),"FFXIV_Common_AvoidHP",1,10,0,100,function () ffxivminion.SaveClassSettings("FFXIV_Common_AvoidHP",FFXIV_Common_AvoidHP) end )
					GUI_DrawIntMinMax(GetString("restHP"),"FFXIV_Common_RestHP",1,10,0,100,function () ffxivminion.SaveClassSettings("FFXIV_Common_RestHP",FFXIV_Common_RestHP) end)
					GUI_DrawIntMinMax(GetString("restMP"),"FFXIV_Common_RestMP",1,10,0,100,function () ffxivminion.SaveClassSettings("FFXIV_Common_RestMP",FFXIV_Common_RestMP) end)
					GUI_DrawIntMinMax(GetString("potionHP"),"FFXIV_Common_PotionHP",1,10,0,100,function () ffxivminion.SaveClassSettings("FFXIV_Common_PotionHP",FFXIV_Common_PotionHP) end)
					GUI_DrawIntMinMax(GetString("potionMP"),"FFXIV_Common_PotionMP",1,10,0,100,function () ffxivminion.SaveClassSettings("FFXIV_Common_PotionMP",FFXIV_Common_PotionMP) end)
					GUI_DrawIntMinMax(GetString("fleeHP"),"FFXIV_Common_FleeHP",1,10,0,100,function () ffxivminion.SaveClassSettings("FFXIV_Common_FleeHP",FFXIV_Common_FleeHP) end)
					GUI_DrawIntMinMax(GetString("fleeMP"),"FFXIV_Common_FleeMP",1,10,0,100,function () ffxivminion.SaveClassSettings("FFXIV_Common_FleeMP",FFXIV_Common_FleeMP) end)
					
					GUI:PopItemWidth()
					GUI:EndChild()
				end
				
				if (tabs.tabs[5].isselected) then
					GUI:BeginChild("##main-header-hacks",0,GUI_GetFrameHeight(10),true)
					GUI_Capture(GUI:Checkbox(GetString("repair"),FFXIV_Common_Repair),"FFXIV_Common_Repair")
					--GUI_Capture(GUI:Checkbox(GetString("disabledrawing"),FFXIV_Common_DisableDrawing),"FFXIV_Common_DisableDrawing", function () GameHacks:Disable3DRendering(FFXIV_Common_DisableDrawing) end)
					GUI_Capture(GUI:Checkbox(GetString("teleport"),FFXIV_Common_Teleport),"FFXIV_Common_Teleport", 
						function () 
							if (FFXIV_Common_BotMode == GetString("dutyMode")) then
								 GUI_Set("FFXIV_Duty_Teleport",FFXIV_Duty_Teleport)
							end
						end
					)
					--[[
					GUI_Capture(GUI:Checkbox(GetString("paranoid"),FFXIV_Common_Paranoid),"FFXIV_Common_Paranoid")
					GUI_Capture(GUI:Checkbox(GetString("permaSprint"),FFXIV_Common_PermaSprint),"FFXIV_Common_PermaSprint", function () GameHacks:SetPermaSprint(FFXIV_Common_PermaSprint) end)
					GUI_Capture(GUI:Checkbox(GetString("permaSwiftcast"),FFXIV_Common_PermaSwift),"FFXIV_Common_PermaSwift", function () GameHacks:SetPermaSwiftCast(FFXIV_Common_PermaSwift) end)
					GUI_Capture(GUI:Checkbox(GetString("skipCutscene"),FFXIV_Common_SkipCutscene),"FFXIV_Common_SkipCutscene", function () GameHacks:SkipCutscene(FFXIV_Common_SkipCutscene) end)
					GUI_Capture(GUI:Checkbox(GetString("skipDialogue"),FFXIV_Common_SkipDialogue),"FFXIV_Common_SkipDialogue", function () GameHacks:SkipDialogue(FFXIV_Common_SkipDialogue) end)
					GUI_Capture(GUI:Checkbox(GetString("clickToTeleport"),FFXIV_Common_ClickTeleport),"FFXIV_Common_ClickTeleport", function () GameHacks:SetClickToTeleport(FFXIV_Common_ClickTeleport) end)
					GUI_Capture(GUI:Checkbox(GetString("clickToTravel"),FFXIV_Common_ClickTravel),"FFXIV_Common_ClickTravel", function () GameHacks:SetClickToTravel(FFXIV_Common_ClickTravel) end)
					--]]				
					GUI:EndChild()
				end
				
				if (tabs.tabs[6].isselected) then
					GUI:BeginChild("##main-header-advancedsettings",0,GUI_GetFrameHeight(4),true)
					GUI:PushItemWidth(120)
					GUI_DrawIntMinMax("Stealth - Detect Range","FFXIV_Common_StealthDetect",1,10,0,100)
					GUI_DrawIntMinMax("Stealth - Remove Range","FFXIV_Common_StealthRemove",1,10,0,100)
					GUI:PopItemWidth()
					GUI_Capture(GUI:Checkbox("Smart Stealth",FFXIV_Common_StealthSmart),"FFXIV_Common_StealthSmart")
					if (GUI:Button("View Login Settings",200,20)) then
						ffxivminion.GUI.login.open = true
					end
					GUI:EndChild()
				end
			end

			GUI:End()
			GUI:PopStyleColor()
		end
	end
end

function ml_global_information.DrawMiniButtons()
	local gamestate = GetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
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
end

-- Login to the correct DataCenter.
function ml_global_information.DrawLoginHandler()
	local gamestate = GetGameState()
	if (gamestate ~= FFXIV.GAMESTATE.INGAME or ffxivminion.GUI.login.open) then
		
		GUI:SetNextWindowSize(300,135,GUI.SetCond_Always) --set the next window size, only on first ever	
		GUI:SetNextWindowCollapsed(false,GUI.SetCond_Always)
		
		local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
		GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
		
		ffxivminion.GUI.login.visible, ffxivminion.GUI.login.open = GUI:Begin(ffxivminion.GUI.login.name, ffxivminion.GUI.login.open)
		if ( ffxivminion.GUI.login.visible ) then 
			
			local width, height = GUI:GetWindowSize()
			
			GUI:PushItemWidth(120)
			local dcChanged = GUI_Combo("DataCenter", "FFXIV_Login_DataCenter", "FFXIV_Login_DataCenterName", ffxivminion.logincenters)
			if (dcChanged) then
				local uuid = GetUUID()
				if ( string.valid(uuid) ) then
					if  ( Settings.FFXIVMINION.FFXIV_Login_DataCenters == nil ) then 
						Settings.FFXIVMINION.FFXIV_Login_DataCenters = {} 
					end
					Settings.FFXIVMINION.FFXIV_Login_DataCenters[uuid] = FFXIV_Login_DataCenterName
				end
				GUI_Set("FFXIV_Login_Server",1)
				GUI_Set("FFXIV_Login_ServerName","")
				Settings.FFXIVMINION.FFXIV_Login_Servers[uuid] = FFXIV_Login_ServerName
			end
			
			if (table.valid(ffxivminion.loginservers[FFXIV_Login_DataCenter])) then
				--d("servers are valid for this datacenter")
				
				local serverChanged = GUI_Combo("Server", "FFXIV_Login_Server", "FFXIV_Login_ServerName", ffxivminion.loginservers[FFXIV_Login_DataCenter])
				if (serverChanged) then
					local uuid = GetUUID()
					if ( string.valid(uuid) ) then
						if  ( Settings.FFXIVMINION.FFXIV_Login_Servers == nil ) then 
							Settings.FFXIVMINION.FFXIV_Login_Servers = {} 
						end
						Settings.FFXIVMINION.FFXIV_Login_Servers[uuid] = FFXIV_Login_ServerName
					end
				end
			else
				d("no servers valid for this datacenter")
			end

			GUI_DrawIntMinMax("Character Index (0-n)","FFXIV_Login_Character",1,1,0,15,
				function () 
					local uuid = GetUUID()
					if ( string.valid(uuid) ) then
						if  ( Settings.FFXIVMINION.FFXIV_Login_Characters == nil ) then 
							Settings.FFXIVMINION.FFXIV_Login_Characters = {} 
						end
						Settings.FFXIVMINION.FFXIV_Login_Characters[uuid] = FFXIV_Login_Character
					end
				end 
			)
			GUI:PopItemWidth()
			
			if (GUI:Button(IIF(ffxivminion.loginvars.loginPaused,"Start","Pause"),width,20)) then
				ffxivminion.loginvars.loginPaused = not ffxivminion.loginvars.loginPaused
			end
		end
		
		GUI:End()
		GUI:PopStyleColor()
		
	end
end

function ml_global_information.Draw( event, ticks ) 
	-- Main "mode" window.
	-- DrawMode 1 is fully drawn, 2 is minimized, mode visible only.
	
	ml_global_information.DrawMainFull()
	ml_global_information.DrawSmall()
	ml_global_information.DrawSettings()
	ml_global_information.DrawMiniButtons()
	ml_global_information.DrawLoginHandler()
end

-- Register Event Handlers
RegisterEventHandler("Module.Initalize",ffxivminion.HandleInit)
RegisterEventHandler("Gameloop.Update",ml_global_information.OnUpdate)
RegisterEventHandler("Gameloop.Draw", ml_global_information.Draw)
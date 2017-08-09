ffxivminion = {}
ffxivminion.modes = {}
ffxivminion.modesToLoad = {}
ffxivminion.busyTimer = 0
ffxivminion.lastTradeDecline = 0
ffxivminion.lastTradeMessage = 0
ffxivminion.tradeDeclines = 0
ffxivminion.declineTimer = 0

ffxivminion.loginvars = {
	reset = true,
	loginPaused = false,
	datacenterSelected = false,
	serverSelected = false,
	charSelected = false,
}

ffxivminion.logincenters = { "None","Elemental","Gaia","Mana","Aether","Primal","Chaos" }

ffxivminion.loginservers = {
	[1] = { "None" },
	[2] = {	"None","Aegis","Atomos","Carbuncle","Garuda","Gungnir","Kujata","Ramuh","Tonberry","Typhon","Unicorn" },
	[3] = { "None","Alexander","Bahamut","Durandal","Fenrir","Ifrit","Ridill","Tiamat","Ultima","Valefor","Yojimbo","Zeromus" },
	[4] = {	"None","Anima","Asura","Belias","Chocobo","Hades","Ixion","Mandragora","Pandaemonium","Shinryu","Titan","Masamune" },
	[5] = { "None","Adamantoise","Balmung","Cactuar","Coeurl","Faerie","Gilgamesh","Goblin","Jenova","Mateus","Midgardsormr","Sargatanas","Siren","Zalera" },
	[6] = {	"None","Behemoth","Brynhildr","Diabolos","Excalibur","Exodus","Famfrit","Hyperion","Lamia","Leviathan","Malboro","Twintania","Ultros" },
	[7] = {	"None","Cerberus","Lich","Louisoix","Moogle","Odin","Omega","Phoenix","Ragnarok","Shiva","Zodiark" },
}

ffxivminion.AutoGrindDefault = [[
	local mapid = Player.localmapid
	local level = Player.level
	if ( mapid and level ) then
		local inthanalan = 	In(mapid,140,141,145,146,147,140,141,130,131)
		local inshroud = 	In(mapid,148,152,153,154,132,133)
		local inlanoscea = 	In(mapid,129,128,134,135,137,138,139,180)
		
		if (level < 12) then
			if (inthanalan) then
				return 140 --western than
			elseif (inshroud) then
				return 148 --central shroud
			elseif (inlanoscea) then
				return 134 --middle la noscea
			else
				return 148
			end
			
		elseif ( level >= 12 and level < 20) then
			if (inthanalan) then
				return 140 --western than
			elseif (inshroud) then
				return 152 --east shroud
			elseif (inlanoscea) then
				return 138 --middle la noscea
			else
				return 152
			end
			
		elseif (level >= 20 and level < 22) then
			return 152 --east shroud
		elseif (level >= 22 and level < 30) then
			return 153 --south shroud
		elseif (level >= 30 and level < 40) then
			return 137 --eastern la noscea
		elseif (level >= 40 and level < 45) then
			return 155 --coerthas
		elseif ((level >= 45 and level < 50) or (level >= 50 and (not QuestCompleted(1583) or not CanAccessMap(397)))) then
			return 147 -- northern thanalan
		elseif (level >= 60 and CanAccessMap(612)) then
			return 612 --The Fringes
		elseif (level >= 58 and level < 60 and CanAccessMap(478) and CanAccessMap(399)) then
			return 399 --The Dravanian Hinterlands
		elseif (level >= 55 and level < 60 and CanAccessMap(398)) then
			return 398	--The Dravanian Forelands
		elseif (level >= 50 and level < 60 and CanAccessMap(397)) then
			return 397 --Coerthas Western Highlands		
		else
			return 138
		end
	end
]]

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
	autogrind = {
		name = "Auto-Grind - Edit",
		open = false,
		visible = true,
		modified = false,
		error_text = "",
	},
	current_tab = 1,
	draw_mode = 1,
}

FFXIVMINION = {}

memoize = {}
pmemoize = {}
tasktracking = {}
setmetatable(tasktracking, { __mode = 'v' })

function ml_global_information.ResetLoginVars()
	if (not ffxivminion.loginvars.reset) then
		ffxivminion.loginvars = {
			reset = true,
			loginPaused = false,
			datacenterSelected = false,
			serverSelected = false,
			charSelected = false,
		}
	end
end

function ml_global_information.OnUpdate( event, tickcount )
    ml_global_information.Now = tickcount
	
	local gamestate;
	if (GetGameState and GetGameState()) then
		gamestate = GetGameState()
	else
		gamestate = 1
	end
	
	memoize = {}
	if (ml_global_information.IsYielding()) then
		--d("stuck in yield")
		return false
	end
	
	-- Switch according to the gamestate
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		ml_global_information.ResetLoginVars()
		ml_global_information.InGameOnUpdate( event, tickcount );
	elseif (gamestate == FFXIV.GAMESTATE.MAINMENUSCREEN) then
		ml_global_information.MainMenuScreenOnUpdate( event, tickcount )
	elseif (gamestate == FFXIV.GAMESTATE.CHARACTERSCREEN) then
		ml_global_information.CharacterSelectScreenOnUpdate( event, tickcount )
	elseif (gamestate == FFXIV.GAMESTATE.ERROR) then
		ml_global_information.ResetLoginVars()
		ml_global_information.ErrorScreenOnUpdate( event, tickcount )
	end
end

function ml_global_information.ErrorScreenOnUpdate( event, tickcount )
	local login = ffxivminion.loginvars
	if (not login.loginPaused) then
		--d("checking mainmenu")
		if (IsControlOpen("Dialogue")) then
			if (UseControlAction("Dialogue","PressOK",0)) then
				ml_global_information.Await(1000, 60000, function () return GetGameState() == FFXIV.GAMESTATE.MAINMENUSCREEN end)
			end
		end	
	end
end

function ml_global_information.MainMenuScreenOnUpdate( event, tickcount )
	local login = ffxivminion.loginvars
	if (not login.loginPaused) then
		--d("checking mainmenu")
		
		local serviceAccountList = GetConversationList()
		if (table.valid(serviceAccountList)) then
			if (SelectConversationLine(FFXIV_Login_ServiceAccount)) then
				ml_global_information.Await(500, 5000, function () return GetGameState() ~= FFXIV.GAMESTATE.MAINMENUSCREEN end)
			end
		else
			-- TitleDCWorldMap is used since 4.0 , before older versions use TitleDataCenter
			if (not IsControlOpen("TitleDataCenter") and not IsControlOpen("TitleDCWorldMap") ) then		
				if (UseControlAction("_TitleMenu","OpenDataCenter",0)) then
					ml_global_information.Await(100, 10000, function () return IsControlOpen("TitleDataCenter") or IsControlOpen("TitleDCWorldMap") end)
				end
			else
				if (not login.datacenterSelected) then
					if (FFXIV_Login_DataCenter and FFXIV_Login_DataCenter >= 2 and FFXIV_Login_DataCenter <= 7) then
						d("trying to login on datacenter:"..tostring(FFXIV_Login_DataCenter))
						if (UseControlAction("TitleDataCenter","SetDataCenter",(FFXIV_Login_DataCenter-2)) or UseControlAction("TitleDCWorldMap","SetDataCenter",(FFXIV_Login_DataCenter-2))) then
							login.datacenterSelected = true
							ml_global_information.Await(100, 10000, function () return IsControlOpen("TitleDataCenter") or IsControlOpen("TitleDCWorldMap") end)
						end
					else
						--d("login paused:Attempt to issue notice")
						ffxivminion.loginvars.loginPaused = true
						ffxiv_dialog_manager.IssueNotice("DataCenter Required", "You must select a DataCenter to continue the login process.")
					end
				else
					if (UseControlAction("TitleDataCenter","Proceed",0) or UseControlAction("TitleDCWorldMap","Proceed",0)) then
						ml_global_information.Await(1000, 60000, function () return (table.valid(GetConversationList()) or  GetGameState() ~= FFXIV.GAMESTATE.MAINMENUSCREEN) end)
						ffxivminion.loginvars.datacenterSelected = false
					end
				end
			end	
		end
	end
end

function ml_global_information.CharacterSelectScreenOnUpdate( event, tickcount )
	local login = ffxivminion.loginvars
	--if (not login.loginPaused and not IsControlOpen("SelectOk")) then
	if (not login.loginPaused and not IsControlOpen("SelectOk")) then
		--d("checking charselect")
		
		if (not login.serverSelected) then
			if (IsControlOpen("CharaSelect")) then
				if (not IsControlOpen("_CharaSelectWorldServer")) then
					local serverControl = GetControl("_CharaSelectWorldServer")
					if (serverControl) then
						serverControl:Open()
						ml_global_information.Await(1000, 10000, function () return IsControlOpen("_CharaSelectWorldServer") end)
					end
				else
					if (FFXIV_Login_Server and FFXIV_Login_Server > 0) then
						local servers = GetServerList()
						if (table.valid(servers)) then
							for id, e in pairs(servers) do
								if (e.name == FFXIV_Login_ServerName) then
									d("selected server id:"..tostring(id))
									SelectServer(id)
									ffxivminion.loginvars.serverSelected = true
									ml_global_information.Await(2000)
								end
							end
						end	
					else
						ffxivminion.loginvars.loginPaused = true
						ffxiv_dialog_manager.IssueNotice("Server Required", "You must select a Server to continue the login process.")
					end
				end
			end
		else
			if (IsControlOpen("SelectYesno")) then
				if (UseControlAction("SelectYesno","Yes",0)) then
					ml_global_information.Await(500, 5000, function () return (not IsControlOpen("_CharaSelectListMenu") or IsControlOpen("SelectOk")) end)
				end
			else
				if (UseControlAction("_CharaSelectListMenu","SelectCharacter",FFXIV_Login_Character)) then
					ml_global_information.Await(500, 5000, function () return IsControlOpen("SelectYesno") end)
				end
			end
		end
	end
end

function ml_global_information.InGameOnUpdate( event, tickcount )	
	if (not Player) then
		return false
	end

	if (table.valid(ffxivminion.modesToLoad)) then
		ffxivminion.LoadModes()
		FFXIV_Common_BotRunning = false
	end
	
	if (ml_global_information.autoStartQueued) then
		ml_global_information.autoStartQueued = false
		ml_global_information:ToggleRun() -- convert
	end
	
	FFXIV_Core_ActiveTaskCount = TableSize(tasktracking)
	
	if (ml_mesh_mgr) then
		if (not IsControlOpen("NowLoading")) then
			if (Player) then
				if (ml_global_information.queueLoader == true) then
					ml_global_information.Player_Aetherytes = GetAetheryteList(true)
					Hacks:Disable3DRendering(gDisableDrawing)
					ml_global_information.queueLoader = false
				end
			end
			
			--ml_mesh_mgr.OMC_Handler_OnUpdate( tickcount )
			
			local currentFile = NavigationManager.CurrentFile
			currentFile = ml_mesh_mgr.GetString(string.gsub(currentFile,ml_mesh_mgr.defaultpath.."\\", ""))
			if (currentFile ~= FFXIV_Common_NavMesh) then
				FFXIV_Common_NavMesh = currentFile
				FFXIV_Common_NavMeshIndex = GetKeyByValue(FFXIV_Common_NavMesh,FFXIV_Common_MeshList)
			end
		else
			if (ml_global_information.queueLoader == false) then
				Hacks:Disable3DRendering(false)
				ml_global_information.queueLoader = true
			end
		end
	end
	
	if (c_skiptalk:evaluate()) then
		e_skiptalk:execute()
		--return false
	end
	if (c_skipcutscene:evaluate()) then
		e_skipcutscene:execute()
		--return false
	end

	if (ml_navigation.IsHandlingInstructions(tickcount) or ml_navigation.IsHandlingOMC(tickcount)) then
		return false
	end
	
	local pulseTime = tonumber(gPulseTime) or 150
	local skillPulse = (pulseTime/2)
	
	if (TimeSince(ml_global_information.lastrun2) > skillPulse) then
		ml_global_information.lastrun2 = tickcount
		SkillMgr.OnUpdate()
	end
	
	if (Now() >= ml_global_information.nextRun) then
		
		ml_global_information.nextRun = tickcount + pulseTime
		ml_global_information.lastPulseShortened = false
		
        --ml_global_information.lastrun = tickcount
		
		ffxivminion.UpdateGlobals()
		NavigationManager:UseCubes(true) -- set this back to true every cycle, just in case. override when necessary.
		
		-- close any social addons that might screw up behavior first
		if (FFXIV_Common_BotRunning and 
			gBotMode ~= GetString("assistMode") and
			gBotMode ~= GetString("dutyMode")) 
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
		if (	gBotMode == GetString("grindMode") or
				gBotMode == GetString("gatherMode") or
				gBotMode == GetString("fishMode") or
				gBotMode == GetString("questMode") or
				gBotMode == GetString("huntMode") or 
				gBotMode == GetString("pvpMode") ) and
				ml_task_hub.shouldRun and 
				table.valid(ml_global_information.currentMarker)
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
		local et = GetEorzeaTime()
		FFXIV_Common_EorzeaTime = tostring(et.bell)..":"..(et.minute < 10 and "0" or "")..tostring(et.minute)
		
		if (SkillMgr) then
			ffxivminion.CheckClass()
		end
		
		if (TimeSince(ml_global_information.updateFoodTimer) > 15000) then
			ml_global_information.updateFoodTimer = tickcount
			ffxivminion.FillFoodOptions()
		end
		
		if ((FFXIV_Common_BotRunning or not gRepairRunningOnly) and gRepair) then
			if ( TimeSince(ml_global_information.repairTimer) > 30000 ) then
				if (not IsControlOpen("Gathering") and not IsControlOpen("Synthesis") and not Player.incombat) then
					if (NeedsRepair()) then
						Repair()
					end
					ml_global_information.repairTimer = tickcount
				end
			end
		end
		
		if (FFXIV_Common_BotRunning) then				
			if (gChocoItemString ~= "None") then
				if ( TimeSince(ml_global_information.rootCheckTimer) > 10000 and not Player.ismounted and not IsMounting() and IsCompanionSummoned()) then
					ml_global_information.rootCheckTimer = tickcount
					
					local itemBuffs = ml_global_information.chocoItemBuffs
					if (table.valid(itemBuffs)) then
						for itemid,itemdetails in pairs(itemBuffs) do
							if (gChocoItemString == itemdetails.name) then
								local item = nil
								for i = 0,3 do
									local bag = Inventory:Get(i)
									if (table.valid(bag)) then
										local ilist = bag:GetList()
										if (table.valid(ilist)) then
											for bslot,bitem in pairs(ilist) do
												if (bitem.id == itemid) then
													item = bitem
												end
											end
										end
									end
								end
								
								local companion = GetCompanionEntity()
								if (item and item:IsReady() and companion and companion.alive) then
									local buffString = tostring(itemdetails.buff1).."+"..tostring(itemdetails.buff2)
									if (MissingBuffs(companion, buffString)) then
										Player:PauseMovement()
										ml_global_information.Await(1500, function () return not Player:IsMoving() end)
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
			if (not ml_task_hub:Update()) then
				d("No task queued, please select a valid bot mode in the Settings drop-down menu")
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
	
	if ( Settings.FFXIVMINION.FFXIV_Login_Servers and string.valid(uuid) and Settings.FFXIVMINION.FFXIV_Login_Servers[uuid] ) then
		FFXIV_Login_ServerName = Settings.FFXIVMINION.FFXIV_Login_Servers[uuid]
		--d("pulling login server name for uuid ["..tostring(uuid).."], ["..tostring(FFXIV_Login_ServerName).."]")
	else
		FFXIV_Login_ServerName = ffxivminion.GetSetting("FFXIV_Login_ServerName",ffxivminion.loginservers[FFXIV_Login_DataCenter][1])
		--d("pulling first available login server name ["..tostring(FFXIV_Login_ServerName).."]")
	end
	FFXIV_Login_Server = GetKeyByValue(FFXIV_Login_ServerName,ffxivminion.loginservers[FFXIV_Login_DataCenter])
	if (FFXIV_Login_Server == nil) then 
		FFXIV_Login_Server = 1
		FFXIV_Login_ServerName = ""
		--d("reset server selection to first server.")
	end
	
	if ( Settings.FFXIVMINION.FFXIV_Login_ServiceAccounts and string.valid(uuid) and Settings.FFXIVMINION.FFXIV_Login_ServiceAccounts[uuid] ) then
		FFXIV_Login_ServiceAccount = Settings.FFXIVMINION.FFXIV_Login_ServiceAccounts[uuid]
	else
		FFXIV_Login_ServiceAccount = ffxivminion.GetSetting("FFXIV_Login_ServiceAccount",1)
	end
	
	if ( Settings.FFXIVMINION.FFXIV_Login_Characters and string.valid(uuid) and Settings.FFXIVMINION.FFXIV_Login_Characters[uuid] ) then
		FFXIV_Login_Character = Settings.FFXIVMINION.FFXIV_Login_Characters[uuid]
	else
		FFXIV_Login_Character = ffxivminion.GetSetting("FFXIV_Login_Character",0)
	end
	
	-- In-Game	
	FFXIV_Common_NavMesh = GetString("none")
	FFXIV_Common_NavMeshIndex = 1
	FFXIV_Common_MeshList = {GetString("none")}
	
	gBotModeIndex = 1
	if ( Settings.FFXIVMINION.gBotModes and string.valid(uuid) and Settings.FFXIVMINION.gBotModes[uuid] ) then
		gBotMode = Settings.FFXIVMINION.gBotModes[uuid]
	else
		gBotMode = ffxivminion.GetSetting("gBotMode",GetString("assistMode"))
	end
	gBotModeList = {GetString("none")}
	
	gSkillProfileIndex = 1
	gSkillProfile = GetString("none")
	
	FFXIV_Common_BotRunning = false
	FFXIV_Core_Version = 2
	gPulseTime = ffxivminion.GetSetting("gPulseTime",150)
	FFXIV_Core_ActiveTaskCount = 0
	FFXIV_Core_ActiveTaskName = ""
	FFXIV_Core_ActiveTaskDelay = 0
	FFXIV_Core_IdlePulseCount = 0
	FFXIV_Core_MemoryUsage = 0
	FFXIV_Core_MemoryGain = 0
	
	FFXIV_Common_EorzeaTime = ""
	gEnableLog = ffxivminion.GetSetting("gEnableLog",false)
	gLogCNE = ffxivminion.GetSetting("gLogCNE",false)
	
	gLogLevel = ffxivminion.GetSetting("gLogLevel",1)
	gLogLevels = {1,2,3}
	
	gMountNameIndex = 1
	gMountNames = {GetString("none")}
	gMountName = ffxivminion.GetSetting("gMountName",GetString("none"))
	gMountAvailableOnly = ffxivminion.GetSetting("gMountAvailableOnly",true)
	ffxivminion.FillMountOptions()
	
	gUseMount = ffxivminion.GetSetting("gUseMount",true)
	gMountDist = ffxivminion.GetSetting("gMountDist",75)
	gUseSprint = ffxivminion.GetSetting("gUseSprint",false)
	gSprintDist = ffxivminion.GetSetting("gSprintDist",50)
	FFXIV_Common_RandomPaths = ffxivminion.GetSetting("FFXIV_Common_RandomPaths",false)
	
	FFXIV_Craft_UseHQMats = ffxivminion.GetSetting("FFXIV_Craft_UseHQMats",true)
	gUseExpManuals = ffxivminion.GetSetting("gUseExpManuals",true)
	gDeclinePartyInvites = ffxivminion.GetSetting("gDeclinePartyInvites",true)
	gTradeInviteBusy = ffxivminion.GetSetting("gTradeInviteBusy",true)
	gTradeInviteMessage = ffxivminion.GetSetting("gTradeInviteMessage",false)
	gTradeInviteMessages = ffxivminion.GetSetting("gTradeInviteMessages","?;/shrug")
	
	gFood = ffxivminion.GetSetting("gFood",GetString("none"))
	gFoodIndex = 1
	gFoods = {GetString("none")}
	gFoodSpecific = ffxivminion.GetSetting("gFoodSpecific",true)
	gFoodAvailableOnly = ffxivminion.GetSetting("gFoodAvailableOnly",true)
	ffxivminion.FillFoodOptions()
	
	gAutoStart = ffxivminion.GetSetting("gAutoStart",false)
	gTeleportHack = ffxivminion.GetSetting("gTeleportHack",false)
	gDutyTeleportHack = ffxivminion.GetSetting("gDutyTeleportHack",true)
	gTeleportHackParanoid = ffxivminion.GetSetting("gTeleportHackParanoid",false)
	gSkipCutscene = ffxivminion.GetSetting("gSkipCutscene",false)
	gSkipTalk = ffxivminion.GetSetting("gSkipTalk",false)
	gSkipTalkRunningOnly = ffxivminion.GetSetting("gSkipTalkRunningOnly",false)
	gDisableDrawing = ffxivminion.GetSetting("gDisableDrawing",false)
	gRepair = ffxivminion.GetSetting("gRepair",true)
	gRepairRunningOnly = ffxivminion.GetSetting("gRepairRunningOnly",false)
	gPermaSprint = ffxivminion.GetSetting("gPermaSprint",false)
	FFXIV_Common_PermaSwift = ffxivminion.GetSetting("FFXIV_Common_PermaSwift",false)
	gChocoAssist = ffxivminion.GetSetting("gChocoAssist",false)
	gChocoGrind = ffxivminion.GetSetting("gChocoGrind",true)
	gChocoQuest = ffxivminion.GetSetting("gChocoQuest",true)
	
	gChocoStance = ffxivminion.GetSetting("gChocoStance",1)
	gChocoStances = {GetString("stFree"), GetString("stDefender"), GetString("stAttacker"), GetString("stHealer"), GetString("stFollow")}
	gChocoStanceString = gChocoStances[gChocoStance]
	
	gChocoItem = ffxivminion.GetSetting("gChocoItem",1)
	gChocoItems = {"Curiel Root (EXP)", "Sylkis Bud (ATK)", "Mimmet Gourd (Heal)", "Tantalplant (HP)", "Pahsana Fruit (ENM)"}
	gChocoItemString = gChocoItems[gChocoItem]
	
	gAvoidAOE = ffxivminion.GetSetting("gAvoidAOE",false)
	gAvoidHP = ffxivminion.GetSetting("gAvoidHP",100)
	gRestHP = ffxivminion.GetSetting("gRestHP",70)
	gRestMP = ffxivminion.GetSetting("gRestMP",0)
	gPotionHP = ffxivminion.GetSetting("gPotionHP",50)
	gPotionMP = ffxivminion.GetSetting("gPotionMP",0)
	gFleeHP = ffxivminion.GetSetting("gFleeHP",25)
	gFleeMP = ffxivminion.GetSetting("gFleeMP",0)
	gAutoEquip = ffxivminion.GetSetting("gAutoEquip",true)
	gQuestAutoEquip = ffxivminion.GetSetting("gQuestAutoEquip",true)	
	FFXIV_Common_StealthDetect = ffxivminion.GetSetting("FFXIV_Common_StealthDetect",25)
	FFXIV_Common_StealthRemove = ffxivminion.GetSetting("FFXIV_Common_StealthRemove",30)
	FFXIV_Common_StealthSmart = ffxivminion.GetSetting("FFXIV_Common_StealthSmart",true)
	
	gAutoGrindCode = ffxivminion.GetSetting("gAutoGrindCode",ffxivminion.AutoGrindDefault)
	GetBestGrindMap = GetBestGrindMapDefault
	local f = loadstring(gAutoGrindCode)
	if (f ~= nil) then
		GetBestGrindMap = f
	else
		ml_error("Compilation error in auto-grind code:")
		assert(loadstring(gAutoGrindCode))
	end
	
	ml_global_information.autoStartQueued = gAutoStart		
	Hacks:Disable3DRendering(gDisableDrawing)
	Hacks:SkipCutscene(gSkipCutscene)
	Hacks:SetPermaSprint(gPermaSprint)
end

-- Module Event Handler
function ffxivminion.HandleInit()

	-- Build bottom menu for new GUI addons.
	ffxivminion.GUI.settings.main_tabs = GUI_CreateTabs("botStatus,generalSettings,Behavioral,companion,playerHPMPTP,hacks,advancedSettings",true)
	ml_global_information.BuildMenu()
	ffxivminion.SetMainVars()
	
	FFXIV_Common_NavMesh = GetString("none")
	
	-- Add "known" modes, safe.
	ffxivminion.AddMode(GetString("grindMode"), ffxiv_task_grind) 
	ffxivminion.AddMode(GetString("fishMode"), ffxiv_task_fish)
	ffxivminion.AddMode(GetString("gatherMode"), ffxiv_task_gather)
	ffxivminion.AddMode(GetString("craftMode"), ffxiv_task_craft)
	ffxivminion.AddMode(GetString("assistMode"), ffxiv_task_assist)
	ffxivminion.AddMode(GetString("partyMode"), ffxiv_task_party)
	--ffxivminion.AddMode(GetString("pvpMode"), ffxiv_task_pvp)
	--ffxivminion.AddMode(GetString("frontlines"), ffxiv_task_frontlines)
	--ffxivminion.AddMode(GetString("huntMode"), ffxiv_task_hunt)
	--ffxivminion.AddMode(GetString("huntlogMode"), ffxiv_task_huntlog)
	--ffxivminion.AddMode(GetString("quickStartMode"), ffxiv_task_qs_wrapper)
	ffxivminion.AddMode("NavTest", ffxiv_task_test)
	
	-- New GUI code, need new strings and handlers for combo boxes.
	FFXIV_Common_MeshList = {""}
	local meshfilelist = FolderList(ml_mesh_mgr.defaultpath)
	if (meshfilelist) then
		for i,file in spairs(meshfilelist, function( file,a,b ) return file[a] < file[b] end) do
			if ( string.ends(file,".obj") ) then
				local filename = string.trim(file,4)
				table.insert(FFXIV_Common_MeshList, ml_mesh_mgr.GetString(filename))
			end
		end		
	end

	FFXIV_Core_ActiveTaskName = ""
	FFXIV_Common_BotRunning = false
	
    local fateBlacklist = ml_list_mgr.AddList("FATE Blacklist")
	fateBlacklist.DefaultDraw = DrawFateListUI
	local fateWhitelist = ml_list_mgr.AddList("FATE Whitelist")
	fateWhitelist.DefaultDraw = DrawFateListUI
	local monsterBlacklist = ml_list_mgr.AddList("Mob Blacklist")
	local monsterWhitelist = ml_list_mgr.AddList("Mob Whitelist")
	
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
		ffxivminion.SetModeOptions(mode)
		ml_global_information.mainTask = task
		
		if (FFXIV_Common_BotRunning) then
			ml_global_information:ToggleRun()
		end
		
		--[[
		--Setup default options.
		if (gBotMode == GetString("dutyMode")) then
			if (Duties) then
				Duties.UpdateProfiles()
			end
			gTeleportHack = gTeleportHackDefaultDuties
			gTeleportHackParanoid = "0"
			gSkipCutscene = "1"
			gSkipTalk = "1"
			gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
			Hacks:SkipCutscene(gSkipCutscene)
			Hacks:SkipDialogue(gSkipTalk)
			Hacks:Disable3DRendering(gDisableDrawing)
			SendTextCommand("/busy off")
			gAutoEquip = Settings.FFXIVMINION.gAutoEquip
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
			gTeleportHack = Settings.FFXIVMINION.gTeleportHack
			gTeleportHackParanoid = Settings.FFXIVMINION.gTeleportHackParanoid
			gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
			gSkipCutscene = Settings.FFXIVMINION.gSkipCutscene
			gSkipTalk = Settings.FFXIVMINION.gSkipTalk
			Hacks:SkipCutscene(gSkipCutscene)
			Hacks:Disable3DRendering(gDisableDrawing)
			gAvoidAOE = Settings.FFXIVMINION.gAvoidAOE
			gAutoEquip = Settings.FFXIVMINION.gAutoEquip			
		end
	end
end

function ffxivminion.SetMode(mode)
    local task = ffxivminion.modes[mode]
    if (task ~= nil) then
		Hacks:SkipCutscene(gSkipCutscene)
		ml_task_hub:Add(task.Create(), LONG_TERM_GOAL, TP_ASAP)
		ffxivminion.SetModeOptions(task)
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
			["gAvoidHP"] = true,
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
			if (classSettings[name] == nil) then
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
	if (not table.valid(ml_global_information.classes)) then
		ml_global_information.classes = {
			[FFXIV.JOBS.ARCANIST] 		= ffxiv_combat_arcanist,
			[FFXIV.JOBS.ARCHER]		= ffxiv_combat_archer,
			[FFXIV.JOBS.BARD]			= ffxiv_combat_bard,
			[FFXIV.JOBS.BLACKMAGE]		= ffxiv_combat_blackmage,
			[FFXIV.JOBS.CONJURER]		= ffxiv_combat_conjurer,
			[FFXIV.JOBS.DRAGOON]		= ffxiv_combat_dragoon,
			[FFXIV.JOBS.GLADIATOR] 	= ffxiv_combat_gladiator,
			[FFXIV.JOBS.LANCER]		= ffxiv_combat_lancer,
			[FFXIV.JOBS.MARAUDER] 		= ffxiv_combat_marauder,
			[FFXIV.JOBS.MONK] 			= ffxiv_combat_monk,
			[FFXIV.JOBS.NINJA] 		= ffxiv_combat_ninja,
			[FFXIV.JOBS.ROGUE]			= ffxiv_combat_rogue,
			[FFXIV.JOBS.PALADIN] 		= ffxiv_combat_paladin,
			[FFXIV.JOBS.PUGILIST] 		= ffxiv_combat_pugilist,
			[FFXIV.JOBS.SCHOLAR] 		= ffxiv_combat_scholar,
			[FFXIV.JOBS.SUMMONER] 		= ffxiv_combat_summoner,
			[FFXIV.JOBS.THAUMATURGE] 	= ffxiv_combat_thaumaturge,
			[FFXIV.JOBS.WARRIOR] 	 	= ffxiv_combat_warrior,
			[FFXIV.JOBS.WHITEMAGE] 	= ffxiv_combat_whitemage,
			[FFXIV.JOBS.ROGUE]			= ffxiv_combat_rogue,
			[FFXIV.JOBS.NINJA]			= ffxiv_combat_ninja,
			[FFXIV.JOBS.MACHINIST]		= ffxiv_combat_machinist,
			[FFXIV.JOBS.DARKKNIGHT]	= ffxiv_combat_darkknight,
			[FFXIV.JOBS.ASTROLOGIAN]	= ffxiv_combat_astrologian,	
			[FFXIV.JOBS.REDMAGE]	= ffxiv_combat_redmage,
			[FFXIV.JOBS.SAMURAI]	= ffxiv_combat_samurai,	
			
			[FFXIV.JOBS.BOTANIST] 		= ffxiv_gather_botanist,
			[FFXIV.JOBS.FISHER] 		= ffxiv_gather_fisher,
			[FFXIV.JOBS.MINER] 		= ffxiv_gather_miner,
			
			[FFXIV.JOBS.CARPENTER] 	= ffxiv_crafting_carpenter,
			[FFXIV.JOBS.BLACKSMITH] 	= ffxiv_crafting_blacksmith,
			[FFXIV.JOBS.ARMORER] 		= ffxiv_crafting_armorer,
			[FFXIV.JOBS.GOLDSMITH] 	= ffxiv_crafting_goldsmith,
			[FFXIV.JOBS.LEATHERWORKER] = ffxiv_crafting_leatherworker,
			[FFXIV.JOBS.WEAVER] 		= ffxiv_crafting_weaver,
			[FFXIV.JOBS.ALCHEMIST] 	= ffxiv_crafting_alchemist,
			[FFXIV.JOBS.CULINARIAN] 	= ffxiv_crafting_culinarian,
		}
	end
	
	local classes = ml_global_information.classes
	local playerClass = classes[Player.job]
	if (not playerClass) then
		ffxiv_dialog_manager.IssueNotice("FFXIV_CheckClass_InvalidClass", "Missing class routine file.")
		return
	end
	
	if (ml_global_information.CurrentClass == nil) then
		ml_global_information.CurrentClass = playerClass
		ml_global_information.CurrentClassID = Player.job
		local baseRange = 2
		if (type(playerClass.range) == "function") then
			baseRange = playerClass.range()
		elseif (type(playerClass.range) == "number") then
			baseRange = playerClass.range
		end
		ml_global_information.AttackRange = baseRange
		SkillMgr.UseDefaultProfile()
		ffxivminion.VerifyClassSettings()
		ffxivminion.UseClassSettings()
		return
	end
    
    if (ml_global_information.CurrentClassID ~= Player.job) then
        ml_global_information.CurrentClass = playerClass
        ml_global_information.CurrentClassID = Player.job
		local baseRange = 2
		if (type(playerClass.range) == "function") then
			baseRange = playerClass.range()
		elseif (type(playerClass.range) == "number") then
			baseRange = playerClass.range
		end
		ml_global_information.AttackRange = baseRange
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
				--ffxivminion.SwitchMode(newModeName)
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

function ffxivminion.UpdateGlobals()
	if (Player) then
		ml_global_information.Player_Aetherytes = GetAetheryteList()
		ml_global_information.Player_Map = Player.localmapid
	end
	
	local meshState = NavigationManager:GetNavMeshState()
	ml_global_information.MeshReady = (meshState == GLOBAL.MESHSTATE.MESHREADY or meshState == GLOBAL.MESHSTATE.MESHEMPTY)
end

function ml_global_information.Reset()
    ml_task_hub:ClearQueues()
    ffxivminion.CheckMode()
end

function ml_global_information.Stop()
	if (Player:IsMoving() or table.valid(ml_navigation.path)) then
		Player:Stop()
	end
	SkillMgr.receivedMacro = {}
	Hacks:SkipCutscene(gSkipCutscene)
end

function ffxivminion.AddMode(name, task)
	--d("added mode ["..name.."] with type ["..tostring(type(task)).."]")
	task.friendly = name
	ffxivminion.modesToLoad[name] = task
end

-- New GUI methods.
function ffxivminion.FillFoodOptions()
	local allFoods = AceLib.API.Items.GetAllFoods()

	ml_global_information.foods = {}
	if (table.valid(allFoods)) then
		for i,item in pairsByKeys(allFoods) do
			ml_global_information.foods[item.name] = {
				id = item.hqid,
				name = item.name,
				buffid = item.buffid,
				buffstackid = item.buffstackid,
			}
		end
	end
	
	gFoods = {GetString("none")}
	local foods = ml_global_information.foods
	if (table.valid(foods)) then
		for id,item in spairs(foods, function( item,a,b ) return item[a].name < item[b].name end) do
			table.insert(gFoods,item.name)
		end
	end
end

function ffxivminion.FillMountOptions()
	gMountNames = { GetString("none") }
	local mounts = ActionList:Get(13)
	if (mounts) then
		for k,v in pairs(mounts) do
			if (ValidString(v.name)) then
				if (not gMountAvailableOnly or v:IsReady()) then
					table.insert(gMountNames,v.name)
					if (v.name == gMountName) then
						gMountNameIndex = table.size(gMountNames)
					end
				end
			end
		end
	end
end

function ffxivminion.LoadModes()
	
	if (table.valid(ffxivminion.modesToLoad)) then
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
	
	gBotModeList = {}
	if (table.valid(ffxivminion.modes)) then
		local modes = ffxivminion.modes
		for modeName,task in spairs(modes, function(modes,a,b) return modes[a].friendly < modes[b].friendly end) do
			table.insert(gBotModeList,modeName)
			if (modeName == gBotMode) then
				gBotModeIndex = table.size(gBotModeList)
			end
		end				
	end
	
	local modeIndex = GetKeyByValue(Retranslate(gBotMode),gBotModeList)
	if (modeIndex) then
		gBotModeIndex = modeIndex
	else
		local backupIndex = GetKeyByValue(GetString("assistMode"),gBotModeList)
		gBotModeIndex = backupIndex
		gBotMode = GetString("assistMode")
	end
	
	ffxivminion.SwitchMode(gBotMode)
end

-- clear any addons displayed by social actions like trade/party invites
function ffxivminion.ClearAddons()
	if (ffxivminion.busyTimer ~= 0 and Now() > ffxivminion.busyTimer) then
		SendTextCommand("/busy off")
		ffxivminion.busyTimer = 0
	end
	
	if (ffxivminion.tradeDeclines > 0 and Now() > ffxivminion.lastTradeDecline + 30000) then
		if (not IsControlOpen("Trade")) then
			ffxivminion.tradeDeclines = 0
		end
	end
	
	--trade window
	if (IsControlOpen("Trade") and not Player:IsMoving()) then
		
		if (Now() < ffxivminion.lastTradeDecline + 15000 and ffxivminion.tradeDeclines > 0 and gTradeInviteBusy) then
			Player:CheckTradeWindow()
			ffxivminion.tradeDeclines = ffxivminion.tradeDeclines + 1
			ffxivminion.lastTradeDecline = Now()
			ml_global_information.Await(5000, 
				function () return IsControlOpen("Trade") end, 
				function () 
					SendTextCommand("/busy on")
					ffxivminion.busyTimer = Now() + 60000
				end
			)
		end
		
		if (Now() > ffxivminion.lastTradeMessage + 15000 and ffxivminion.tradeDeclines == 0) then
			if (ValidString(gTradeInviteMessages)) then
				local messageTable = {}
				for message in StringSplit(gTradeInviteMessages,";") do
					table.insert(messageTable,message)
				end
				local thisMessage = messageTable[math.random(1,table.size(messageTable))]
				if (ValidString(thisMessage)) then
					if (not string.starts(thisMessage,"/")) then
						thisMessage = "/say "..thisMessage
					end
					SendTextCommand(thisMessage)
					ffxivminion.lastTradeMessage = Now()
				end
			end
			ml_global_information.AwaitThen(math.random(2000,7000), 
				function ()
					Player:CheckTradeWindow()
					ffxivminion.tradeDeclines = ffxivminion.tradeDeclines + 1
					ffxivminion.lastTradeDecline = Now()
				end
			)
		end
		
		return true
	end
	
	--party invite
	if (IsControlOpen("_NotificationParty") and toboolean(gDeclinePartyInvites)) then
		if (IsControlOpen("SelectYesno")) then
			if(ffxivminion.declineTimer == 0) then
				ffxivminion.declineTimer = Now() + math.random(3000,5000)
			elseif(Now() > ffxivminion.declineTimer) then
				if (not ffxivminion.inviteDeclined) then
					UseControlAction("SelectYesno","No")
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
			if (ml_global_information.drawMode == 1) then
				GUI:SetNextWindowSize(350,300,GUI.SetCond_FirstUseEver) --set the next window size, only on first ever	
				GUI:SetNextWindowCollapsed(false,GUI.SetCond_Once)
				
				local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
				GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
				
				ffxivminion.GUI.main.visible, ffxivminion.GUI.main.open = GUI:Begin(ffxivminion.GUI.main.name, ffxivminion.GUI.main.open)
				if ( ffxivminion.GUI.main.visible ) then 
				
					local x, y = GUI:GetWindowPos()
					local width, height = GUI:GetWindowSize()
					local contentwidth = GUI:GetContentRegionAvailWidth()
					
					ffxivminion.GUI.x = x; ffxivminion.GUI.y = y; ffxivminion.GUI.width = width; ffxivminion.GUI.height = height;
					
					GUI:PushItemWidth(150)
					local modeChanged = GUI_Combo(GetString("botMode"), "gBotModeIndex", "gBotMode", gBotModeList)
					if (modeChanged) then
						ffxivminion.SwitchMode(gBotMode)
						local uuid = GetUUID()
						if ( string.valid(uuid) ) then
							if  ( Settings.FFXIVMINION.gBotModes == nil ) then Settings.FFXIVMINION.gBotModes = {} end
							Settings.FFXIVMINION.gBotModes[uuid] = gBotMode
						end
					end
					
					if (FFXIV_Common_BotRunning) then
						GUI:SameLine(0,25)
						GUI:TextColored(.1,1,.2,1,"*** RUNNING ***")
					end
					
					GUI:SameLine(contentwidth-20);
					GUI:Image(ml_global_information.GetMainIcon(),14,14)
					if (GUI:IsItemHovered()) then
						if (GUI:IsMouseClicked(0)) then
							if (ml_global_information.drawMode == 1) then
								ml_global_information.drawMode = 0
							else
								ml_global_information.drawMode = 1
							end
						end
					end
					GUI:PopItemWidth()
					
					GUI:PushItemWidth(200)
					local skillsChanged = GUI_Combo(GetString("skillProfile"), "gSkillProfileIndex", "gSkillProfile", SkillMgr.profiles)
					if (skillsChanged) then
						-- todo, fix this once ACR is updated again.
						--if (gACREnabled) then
							--gSkillProfileIndex = 1
						--else
							local uuid = GetUUID()
							Settings.FFXIVMINION.gSMDefaultProfiles[uuid][Player.job] = gSkillProfile
							SkillMgr.UseProfile(gSkillProfile)
						--end
					end
					GUI:PopItemWidth()
			
					GUI:SameLine(0,5)
					if (GUI:ImageButton("##main-skillmanager-edit",ml_global_information.path.."\\GUI\\UI_Textures\\w_eye.png", 16, 16)) then
						SkillMgr.GUI.manager.open = not SkillMgr.GUI.manager.open
					end
					if (GUI:Button(GetString("ACR Profile Options"),200,22)) then
						ACR.OpenProfileOptions()
					end
					
					--[[
					GUI:PushItemWidth(width-80)
					GUI_Combo(GetString("navmesh"), "FFXIV_Common_NavMeshIndex", "FFXIV_Common_NavMesh", FFXIV_Common_MeshList, 
						function ()
							if ( FFXIV_Common_NavMesh ~= GetString("none")) then
								local filename = ml_mesh_mgr.GetFileName(FFXIV_Common_NavMesh)
								d("Attempting to set new mesh ["..tostring(filename).."]")
								ml_mesh_mgr.SetDefaultMesh(Player.localmapid, filename)
								ml_mesh_mgr.LoadNavMesh( filename )
							else
								NavigationManager:ClearNavMesh() 
							end
						end
					)
					GUI:PopItemWidth()
					--]]
					
					local space = -50
					if (In(gBotMode,GetString("grindMode"),GetString("gatherMode"),GetString("fishMode"))) then
						space = -100
					end

					GUI:BeginChild("##main-task-section",0,space,false)
					local mainTask = ml_global_information.mainTask
					if (mainTask) then
						if (mainTask.Draw) then
							mainTask:Draw()
						end
					end
					GUI:EndChild()
					
					if (space == -100) then
						if (GUI:Button(GetString("Add Evac Point"),contentwidth,20)) then
							AddEvacPoint(true)
						end
						if (GUI:IsItemHovered()) then
							GUI:SetTooltip(GetString("Adds an evacuation destination for flee tasks."))
						end
					
						if (GUI:Button(GetString("Edit/View Markers"),(contentwidth/2)-4,20)) then
							ml_marker_mgr.GUI.main_window.open = true
							
							if (gBotMode == GetString("grindMode")) then
								gMarkerType = GetString("Grind")
							elseif (gBotMode == GetString("gatherMode")) then
								if (Player.job == 16) then
									gMarkerType = GetString("Mining")
								elseif (Player.job == 17) then
									gMarkerType = GetString("Botany")
								end
							elseif (gBotMode == GetString("fishMode")) then
								gMarkerType = GetString("Fishing")
							end
							
							gMarkerTypeIndex = GetKeyByValue(gMarkerType,ml_marker_mgr.templateDisplay)
							ml_marker_mgr.UpdateMarkerSelector()							
						end
						
						GUI:SameLine()
						
						if (GUI:Button(GetString("Create Marker"),(contentwidth/2)-4,20)) then
							ml_marker_mgr.GUI.main_window.open = true
							
							local markerAddType = ""
							if (gBotMode == GetString("grindMode")) then
								gMarkerType = GetString("Grind")
								markerAddType = "Grind"
							elseif (gBotMode == GetString("gatherMode")) then
								if (Player.job == 16) then
									gMarkerType = GetString("Mining")
									markerAddType = "Mining"
								elseif (Player.job == 17) then
									gMarkerType = GetString("Botany")
									markerAddType = "Botany"
								end
							elseif (gBotMode == GetString("fishMode")) then
								gMarkerType = GetString("Fishing")
								markerAddType = "Fishing"
							end
							
							gMarkerTypeIndex = GetKeyByValue(gMarkerType,ml_marker_mgr.templateDisplay)
							ml_marker_mgr.UpdateMarkerSelector()
							
							ml_marker_mgr.AddMarker(markerAddType)						
						end

					end
					if (GUI:Button(GetString("advancedSettings"),contentwidth,20)) then
						ffxivminion.GUI.settings.open = not ffxivminion.GUI.settings.open
					end
					if (GUI:Button("Start / Stop",contentwidth,20)) then
						ml_global_information.ToggleRun()	
					end
				end
				GUI:End()
				GUI:PopStyleColor()
			end
		end
	end
end

function ml_global_information.DrawSmall()
	local gamestate = GetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		if (ffxivminion.GUI.main.open) then		
			if (ml_global_information.drawMode ~= 1) then
				GUI:SetNextWindowSize(200,50,GUI.SetCond_Always) --set the next window size, only on first ever	
				local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
				GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .35)
				
				local flags = (GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
				GUI:Begin("FFXIVMINION_MAIN_WINDOW_MINIMIZED", true, flags)
				
				local x, y = GUI:GetWindowPos()
				local width, height = GUI:GetWindowSize()
				local contentwidth = GUI:GetContentRegionAvailWidth()
				
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
				
				GUI:SameLine(contentwidth-35);
				
				GUI:BeginChild("##style-switch",35,35,false)
				GUI:Text("");
				GUI:Image(ml_global_information.GetMainIcon(),14,14)
				if (GUI:IsItemHovered()) then
					if (GUI:IsMouseClicked(0)) then
						if (ml_global_information.drawMode == 1) then
							ml_global_information.drawMode = 0
						else
							ml_global_information.drawMode = 1
						end
					end
				end
				GUI:EndChild()
				
				GUI:End()
				GUI:PopStyleColor()
			end
		end
	end
end

function ml_global_information.DrawSettings()
	local gamestate = GetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		if (ffxivminion.GUI.settings.open) then
			GUI:SetNextWindowSize(600,500,GUI.SetCond_FirstUseEver) --set the next window size, only on first ever	
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
					GUI_DrawIntMinMax(GetString("pulseTime"),"gPulseTime",5,10,5,2000)
					GUI:PopItemWidth()
					GUI:PushItemWidth(60)
					GUI:Text("# Active Task Count"); GUI:SameLine(150); GUI:InputText("##active-task-count",FFXIV_Core_ActiveTaskCount,GUI.InputTextFlags_ReadOnly)
					GUI:PushItemWidth(200)
					GUI:Text("# Active Task Name"); GUI:SameLine(150); GUI:InputText("##active-task-name",FFXIV_Core_ActiveTaskName,GUI.InputTextFlags_ReadOnly)
					GUI:PopItemWidth()
					GUI:Text("# Active Task Delay"); GUI:SameLine(150); GUI:InputText("##active-task-delay",FFXIV_Core_ActiveTaskDelay,GUI.InputTextFlags_ReadOnly)
					GUI:Text("Idle Pulse Count"); GUI:SameLine(150); GUI:InputText("##idle-pulse-count",FFXIV_Core_IdlePulseCount,GUI.InputTextFlags_ReadOnly)
					GUI:PopItemWidth()
					GUI:PushItemWidth(100)
					GUI_Capture(GUI:Checkbox(GetString("enableLog"),gEnableLog),"gEnableLog");
					GUI_Capture(GUI:Checkbox(GetString("logCNE"),gLogCNE),"gLogCNE");
					GUI_Capture(GUI:Combo("Log Level", gLogLevel, gLogLevels ),"gLogLevel")
					
					GUI:LabelText("Eorzea Time",FFXIV_Common_EorzeaTime)
					GUI:LabelText("Memory Usage",FFXIV_Core_MemoryUsage)
					GUI:PopItemWidth()
					GUI:EndChild()
				end
				
				if (tabs.tabs[2].isselected) then
					GUI:BeginChild("##main-header-generalsettings",0,GUI_GetFrameHeight(10),true)
					GUI:PushItemWidth(200)
					
					GUI_Capture(GUI:Checkbox(GetString("autoStartBot"),gAutoStart),"gAutoStart");
					GUI_Capture(GUI:Checkbox(GetString("autoEquip"),gAutoEquip),"gAutoEquip",
						function ()
							if (gBotMode == GetString("questMode")) then
								 GUI_Set("gQuestAutoEquip",gAutoEquip)
							end
						end
					);
					GUI_Capture(GUI:Checkbox(GetString("useMount"),gUseMount),"gUseMount", 
						function ()
							if (gMountName == GetString("none")) then
								gMountNameIndex = 1
								 GUI_Set("gMountName",gMountNames[1])
							end
						end					
					)
					GUI_DrawIntMinMax(GetString("mountDist"),"gMountDist",5,10,0,200)
					GUI_Combo(GetString("mount"), "gMountNameIndex", "gMountName", gMountNames)
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("Pick only a mount that you can actually use.")
					end
					GUI:SameLine(0,5)
					if (GUI:ImageButton("##main-mounts-refresh",ml_global_information.path.."\\GUI\\UI_Textures\\change.png", 14, 14)) then
						ffxivminion.FillMountOptions()
					end
					GUI:SameLine(0,5)
					GUI_Capture(GUI:Checkbox("Show Available Mounts Only",gMountAvailableOnly),"gMountAvailableOnly", ffxivminion.FillMountOptions);
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("If this option is on, no mounts will be shown in an unmountable area.")
					end
					
					GUI_Capture(GUI:Checkbox(GetString("useSprint"),gUseSprint),"gUseSprint",function () ffxivminion.SaveClassSettings("gUseSprint",gUseSprint) end );
					GUI_DrawIntMinMax(GetString("sprintDist"),"gSprintDist",5,10,0,200)
					GUI_Combo(GetString("food"), "gFoodIndex", "gFood", gFoods)
					GUI:SameLine(0,5)
					if (GUI:ImageButton("##main-food-refresh",ml_global_information.path.."\\GUI\\UI_Textures\\change.png", 14, 14)) then
						ffxivminion.FillFoodOptions()
					end
					GUI:SameLine(0,5)
					GUI_Capture(GUI:Checkbox("Enforce Specifics",gFoodSpecific),"gFoodSpecific");
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("This option will force this specific food to be used, even if another one is currently in use.")
					end
					
					GUI_Capture(GUI:Checkbox(GetString("avoidAOE"),gAvoidAOE),"gAvoidAOE");
					GUI_Capture(GUI:Checkbox(GetString("randomPaths"),FFXIV_Common_RandomPaths),"FFXIV_Common_RandomPaths");

					GUI:PopItemWidth()
					GUI:EndChild()
				end	
				
				if (tabs.tabs[3].isselected) then
					GUI:BeginChild("##main-header-behavior",0,GUI_GetFrameHeight(5),true)
					
					GUI_Capture(GUI:Checkbox("Decline Party Invites",gDeclinePartyInvites),"gDeclinePartyInvites");
					GUI_Capture(GUI:Checkbox("/busy After Trade invite",gTradeInviteBusy),"gTradeInviteBusy");
					GUI_Capture(GUI:Checkbox("Send Message After Trade Invite.",gTradeInviteMessage),"gTradeInviteMessage");
					GUI_Capture(GUI:InputText("Message Options",gTradeInviteMessages),"gTradeInviteMessages");
					
					if (GUI:Button("Modify Auto-Grind")) then
						ffxivminion.GUI.autogrind.open = true
						ffxivminion.GUI.autogrind.error_text = ""
					end
					
					GUI:EndChild()
				end
				
				if (tabs.tabs[4].isselected) then
					GUI:BeginChild("##main-header-companion",0,GUI_GetFrameHeight(3),true)
					
					GUI_Capture(GUI:Checkbox(GetString("assistMode"),gChocoAssist),"gChocoAssist"); GUI:SameLine()
					GUI_Capture(GUI:Checkbox(GetString("grindMode"),gChocoGrind),"gChocoGrind"); GUI:SameLine()
					GUI_Capture(GUI:Checkbox(GetString("questMode"),gChocoQuest),"gChocoQuest");
					
					GUI:PushItemWidth(160)
					GUI_Combo(GetString("stance"), "gChocoStance", "gChocoStanceString", gChocoStances)
					GUI_Combo("Feed", "gChocoItem", "gChocoItemString", gChocoItems)
					GUI:PopItemWidth()
					GUI:EndChild()
				end
				
				if (tabs.tabs[5].isselected) then
					GUI:BeginChild("##main-header-playerhpmptp",0,GUI_GetFrameHeight(7),true)
					GUI:PushItemWidth(120)

					GUI_DrawIntMinMax(GetString("avoidHP"),"gAvoidHP",1,10,0,100,function () ffxivminion.SaveClassSettings("gAvoidHP",gAvoidHP) end )
					GUI_DrawIntMinMax(GetString("restHP"),"gRestHP",1,10,0,100,function () ffxivminion.SaveClassSettings("gRestHP",gRestHP) end)
					GUI_DrawIntMinMax(GetString("restMP"),"gRestMP",1,10,0,100,function () ffxivminion.SaveClassSettings("gRestMP",gRestMP) end)
					GUI_DrawIntMinMax(GetString("potionHP"),"gPotionHP",1,10,0,100,function () ffxivminion.SaveClassSettings("gPotionHP",gPotionHP) end)
					GUI_DrawIntMinMax(GetString("potionMP"),"gPotionMP",1,10,0,100,function () ffxivminion.SaveClassSettings("gPotionMP",gPotionMP) end)
					GUI_DrawIntMinMax(GetString("fleeHP"),"gFleeHP",1,10,0,100,function () ffxivminion.SaveClassSettings("gFleeHP",gFleeHP) end)
					GUI_DrawIntMinMax(GetString("fleeMP"),"gFleeMP",1,10,0,100,function () ffxivminion.SaveClassSettings("gFleeMP",gFleeMP) end)
					
					GUI:PopItemWidth()
					GUI:EndChild()
				end
				
				if (tabs.tabs[6].isselected) then
					GUI:BeginChild("##main-header-hacks",0,GUI_GetFrameHeight(10),true)
					GUI_Capture(GUI:Checkbox(GetString("repair"),gRepair),"gRepair"); GUI:SameLine(0,15)
					GUI_Capture(GUI:Checkbox(GetString("Require Bot Running").."##repair",gRepairRunningOnly),"gRepairRunningOnly")
					GUI_Capture(GUI:Checkbox(GetString("disabledrawing"),gDisableDrawing),"gDisableDrawing", function () Hacks:Disable3DRendering(gDisableDrawing) end)
					GUI_Capture(GUI:Checkbox(GetString("teleport"),gTeleportHack),"gTeleportHack", 
						function () 
							if (gBotMode == GetString("dutyMode")) then
								 GUI_Set("gDutyTeleportHack",gDutyTeleportHack)
							end
						end
					)

					GUI_Capture(GUI:Checkbox(GetString("paranoid"),gTeleportHackParanoid),"gTeleportHackParanoid")
					GUI_Capture(GUI:Checkbox(GetString("permaSprint"),gPermaSprint),"gPermaSprint", function () Hacks:SetPermaSprint(gPermaSprint) end)
					GUI_Capture(GUI:Checkbox(GetString("skipCutscene"),gSkipCutscene),"gSkipCutscene", function () Hacks:SkipCutscene(gSkipCutscene) end)
					GUI_Capture(GUI:Checkbox(GetString("skipDialogue"),gSkipTalk),"gSkipTalk"); GUI:SameLine(0,15)
					GUI_Capture(GUI:Checkbox(GetString("Require Bot Running").."##skiptalk",gSkipTalkRunningOnly),"gSkipTalkRunningOnly")
					GUI:EndChild()
				end
				
				if (tabs.tabs[7].isselected) then
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
		
		if (table.valid(windows)) then
			
			local width,height = GUI:GetScreenSize()
			local currentX = vars.menuX
			local buttonsNeeded = {}
			for i,window in pairsByKeys(windows) do
				if (table.valid(window)) then
					if (not window.isOpen()) then
						table.insert(buttonsNeeded,window)
					end
				end
			end
			
			if (table.valid(buttonsNeeded)) then
				local fontSize = GUI:GetWindowFontSize()
				local windowPaddingY = ml_gui.style.current.windowpadding.y
				local framePaddingY = ml_gui.style.current.framepadding.y
				local itemSpacingY = ml_gui.style.current.itemspacing.y

				GUI:SetNextWindowPos(currentX,height - ((fontSize + (framePaddingY * 2) + (itemSpacingY) + (windowPaddingY * 2)) * 2) + windowPaddingY)
				local totalSize = 30
				for i,window in pairs(buttonsNeeded) do
					totalSize = totalSize + (string.len(window.name) * 7.25) + 8
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
					if (GUI:Button(window.name,string.len(window.name) * 7.25 + 8,fontSize + (framePaddingY * 2) + (itemSpacingY))) then
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
		
		GUI:SetNextWindowSize(330,145,GUI.SetCond_Always) --set the next window size, only on first ever	
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
					--d("set login datacenter to ["..tostring(FFXIV_Login_DataCenterName).."] for UUID ["..tostring(uuid).."]")
					Settings.FFXIVMINION.FFXIV_Login_DataCenters[uuid] = FFXIV_Login_DataCenterName
				else
					--d("uuid not valid")
				end
				GUI_Set("FFXIV_Login_Server",1)
				GUI_Set("FFXIV_Login_ServerName","")
				if ( string.valid(uuid) ) then
					if  ( Settings.FFXIVMINION.FFXIV_Login_Servers == nil ) then 
						Settings.FFXIVMINION.FFXIV_Login_Servers = {} 
					end
					Settings.FFXIVMINION.FFXIV_Login_Servers[uuid] = FFXIV_Login_ServerName
				end
				
				ffxivminion.loginvars.datacenterSelected = false
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
						--d("set login server to ["..tostring(FFXIV_Login_ServerName).."] for UUID ["..tostring(uuid).."]")
						Settings.FFXIVMINION.FFXIV_Login_Servers[uuid] = FFXIV_Login_ServerName
					else	
						--d("uuid not valid")
					end
					
					ffxivminion.loginvars.serverSelected = false
				end
			end
			
			GUI_DrawIntMinMax("Service Account Index (0-n)","FFXIV_Login_ServiceAccount",1,1,0,15,
				function () 
					local uuid = GetUUID()
					if ( string.valid(uuid) ) then
						if  ( Settings.FFXIVMINION.FFXIV_Login_ServiceAccounts == nil ) then 
							Settings.FFXIVMINION.FFXIV_Login_ServiceAccounts = {} 
						end
						Settings.FFXIVMINION.FFXIV_Login_ServiceAccounts[uuid] = FFXIV_Login_ServiceAccount
					end
				end 
			)

			GUI_DrawIntMinMax("Character Index (0-n)","FFXIV_Login_Character",1,1,0,15,
				function () 
					local uuid = GetUUID()
					if ( string.valid(uuid) ) then
						if  ( Settings.FFXIVMINION.FFXIV_Login_Characters == nil ) then 
							Settings.FFXIVMINION.FFXIV_Login_Characters = {} 
						end
						Settings.FFXIVMINION.FFXIV_Login_Characters[uuid] = FFXIV_Login_Character
					end
						
					ffxivminion.loginvars.charSelected = false
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

function ml_global_information.DrawAutoGrindEditor()
	local gamestate = GetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		
		if (ffxivminion.GUI.autogrind.open) then
		
			GUI:SetNextWindowSize(700,500,GUI.SetCond_Always) --set the next window size, only on first ever	
			GUI:SetNextWindowCollapsed(false,GUI.SetCond_Always)
			
			local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
			GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
			
			ffxivminion.GUI.autogrind.visible, ffxivminion.GUI.autogrind.open = GUI:Begin(ffxivminion.GUI.autogrind.name, ffxivminion.GUI.autogrind.open)
			if ( ffxivminion.GUI.autogrind.visible ) then 
				
				local width, height = GUI:GetWindowSize()
				
				if (GUI:Button("Reset to Default")) then
					GUI_Set("gAutoGrindCode",ffxivminion.AutoGrindDefault)
					GetBestGrindMap = GetBestGrindMapDefault
				end
				
				local changed = false
				gAutoGrindCode,changed = GUI:InputTextEditor("##autogrind-editor", gAutoGrindCode, 680, 400, GUI.InputTextFlags_AllowTabInput)
				if (changed) then
					ffxivminion.GUI.autogrind.modified = true
				end
				
				if (ffxivminion.GUI.autogrind.modified) then
					if (GUI:Button("Apply",width,20)) then
						local f = loadstring(gAutoGrindCode)
						if (f ~= nil) then
							GetBestGrindMap = f
							ffxivminion.GUI.autogrind.modified = false
							ffxivminion.GUI.autogrind.error_text = ""
							Settings.FFXIVMINION.gAutoGrindCode = gAutoGrindCode
						else
							local errormsg = "Compilation error in auto-grind code:"
							local f,e = loadstring(gAutoGrindCode)
							errormsg = errormsg.."\n"..e
							
							ffxivminion.GUI.autogrind.error_text = errormsg
						end
					end
					
					if (ffxivminion.GUI.autogrind.error_text ~= "") then
						GUI:TextWrapped(ffxivminion.GUI.autogrind.error_text)
					end
				end
			end
			
			GUI:End()
			GUI:PopStyleColor()
		else
			if (ffxivminion.GUI.autogrind.modified) then
				ffxivminion.GUI.autogrind.modified = false
				ffxivminion.GUI.autogrind.error_text = ""
			end
		end
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
	ml_global_information.DrawAutoGrindEditor()
end

-- Register Event Handlers
RegisterEventHandler("Module.Initalize",ffxivminion.HandleInit)
RegisterEventHandler("Gameloop.Update",ml_global_information.OnUpdate)
RegisterEventHandler("Gameloop.Draw", ml_global_information.Draw)
ffxivminion = {}
ffxivminion.modes = {}
ffxivminion.modesToLoad = {}
ffxivminion.busyTimer = 0
ffxivminion.lastTradeDecline = 0
ffxivminion.lastTradeMessage = 0
ffxivminion.tradeDeclines = 0
ffxivminion.declineTimer = 0
ffxivminion.scripExchange = {}
ffxivminion.lastScripExchangeUpdate = {}
ffxivminion.AetherCurrentData = {}
ffxivminion.AetherCurrentCompleted = false
ffxivminion.DutyCurrentData = {}
ffxivminion.gameRegion = GetGameRegion()
ffxivminion.patchLevel = {
	[1] = 5.55,
	[2] = 5.45,
	[3] = 5.41
}

ffxivminion.loginvars = {
	reset = true,
	loginPaused = false,
	datacenterSelected = false,
	serverSelected = false,
	charSelected = false,
}

if (ffxivminion.gameRegion == 1) then
	ffxivminion.logincenters = { "-","Elemental","Gaia","Mana","Aether","Primal","Chaos","Light","Crystal" }
elseif (ffxivminion.gameRegion == 2) then
    ffxivminion.logincenters = { "-","陆行鸟","莫古力","猫小胖" }
else
	ffxivminion.logincenters = { "Main" }
end

if (ffxivminion.gameRegion == 1) then
	ffxivminion.loginservers = {
		[1] = { "-" },
		[2] = {	"-","Aegis","Atomos","Carbuncle","Garuda","Gungnir","Kujata","Ramuh","Tonberry","Typhon","Unicorn" },
		[3] = { "-","Alexander","Bahamut","Durandal","Fenrir","Ifrit","Ridill","Tiamat","Ultima","Valefor","Yojimbo","Zeromus" },
		[4] = {	"-","Anima","Asura","Belias","Chocobo","Hades","Ixion","Mandragora","Pandaemonium","Shinryu","Titan","Masamune" },
		[5] = { "-","Adamantoise","Cactuar","Faerie","Gilgamesh","Jenova","Midgardsormr","Sargatanas","Siren" },
		[6] = {	"-","Behemoth","Excalibur","Exodus","Famfrit","Hyperion","Lamia","Leviathan","Ultros" },
		[7] = {	"-","Spriggan","Cerberus","Louisoix","Moogle","Omega","Ragnarok" },
		[8] = {	"-","Twintania","Lich","Odin","Phoenix","Shiva","Zodiark" },
		[9] = {	"-","Balmung","Brynhildr","Coeurl","Diabolos","Goblin","Malboro","Mateus","Zalera" },
	}
elseif (ffxivminion.gameRegion == 2) then
    ffxivminion.loginservers = {
        [1] = { "-" },
        [2] = { "-","宇宙和音","幻影群岛","拉诺西亚","晨曦王座","沃仙曦染","神意之地","红玉海","萌芽池" },
        [3] = { "-","拂晓之间","旅人栈桥","梦羽宝境","潮风亭","白金幻象","白银乡","神拳痕","龙巢神殿" },
        [4] = { "-","延夏","摩杜纳","柔风海湾","琥珀原","紫水栈桥","静语庄园","海猫茶屋",}
    } 
elseif (ffxivminion.gameRegion == 3) then
	ffxivminion.loginservers = {
		[1] = { "-","톤베리","모그리","초코보","카벙클" },
	}
end

ffxivminion.classes = {
	[FFXIV.JOBS.ARCANIST] = "ACN",
	[FFXIV.JOBS.SCHOLAR] = "SCH",
	[FFXIV.JOBS.SUMMONER] = "SMN",
	[FFXIV.JOBS.THAUMATURGE] = "THM",
	[FFXIV.JOBS.BLACKMAGE] = "BLM",
	[FFXIV.JOBS.ARCHER]	= "ARC",
	[FFXIV.JOBS.BARD] = "BRD",
	[FFXIV.JOBS.CONJURER] = "CNJ",
	[FFXIV.JOBS.WHITEMAGE] = "WHM",
	[FFXIV.JOBS.LANCER] = "LNC",
	[FFXIV.JOBS.DRAGOON] = "DRG",
	[FFXIV.JOBS.GLADIATOR] = "GLD",
	[FFXIV.JOBS.PALADIN] = "PLD",
	[FFXIV.JOBS.MARAUDER] = "MRD",
	[FFXIV.JOBS.WARRIOR] = "WAR",
	[FFXIV.JOBS.PUGILIST] = "PUG",
	[FFXIV.JOBS.MONK] = "MNK",
	[FFXIV.JOBS.ROGUE] = "ROG",
	[FFXIV.JOBS.NINJA] = "NIN",
	[FFXIV.JOBS.MACHINIST] = "MCH",
	[FFXIV.JOBS.DARKKNIGHT]	= "DRK",
	[FFXIV.JOBS.ASTROLOGIAN] = "AST",	
	[FFXIV.JOBS.REDMAGE] = "RDM",
	[FFXIV.JOBS.SAMURAI] = "SAM",
	[FFXIV.JOBS.BOTANIST] = "BTN",
	[FFXIV.JOBS.FISHER] = "FSH",
	[FFXIV.JOBS.MINER] = "MIN",
	[FFXIV.JOBS.CARPENTER] = "CRP",
	[FFXIV.JOBS.BLACKSMITH] = "BSM",
	[FFXIV.JOBS.ARMORER] = "ARM",
	[FFXIV.JOBS.GOLDSMITH] = "GSM",
	[FFXIV.JOBS.LEATHERWORKER] = "LTW",
	[FFXIV.JOBS.WEAVER] = "WVR",
	[FFXIV.JOBS.ALCHEMIST] = "ALC",
	[FFXIV.JOBS.CULINARIAN] = "CUL",
	[FFXIV.JOBS.BLUEMAGE] = "BLU",
	[FFXIV.JOBS.DANCER] = "DNC",
	[FFXIV.JOBS.GUNBREAKER] = "GNB",
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
			
		elseif ( level >= 12 and level < 17) then
			if (inthanalan) then
				return 140 --western than
			elseif (inshroud) then
				return 152 --east shroud
			elseif (inlanoscea) then
				return 138 --western la noscea
			else
				return 152
			end
			
		elseif ((level >= 17 and level < 22) and CanAccessMap(152)) then
			return 152 --east shroud
		elseif ((level >= 22 and level < 30) and CanAccessMap(153)) then
			return 153 --south shroud
		elseif ((level >= 30 and level < 40) and CanAccessMap(137)) then
			return 137 --eastern la noscea
		elseif ((level >= 40 and level < 45) and CanAccessMap(155)) then
			return 155 --coerthas
		elseif ((level >= 45 and level < 48) and CanAccessMap(146)) then
			return 146 -- southern thanalan
		elseif ((level >= 48 and level < 50) or (level >= 50 and (not QuestCompleted(1583) or not CanAccessMap(397))) and CanAccessMap(147)) then
			return 147 -- northern thanalan
		elseif (level >= 74 and CanAccessMap(816)) then
			return 816 -- Il Mheg
		elseif (level >= 70 and CanAccessMap(813)) then
			return 813 -- Lakeland
		elseif (level >= 67 and CanAccessMap(622)) then
			return 622 -- The Azim Steppes
		elseif (level >= 60 and CanAccessMap(612)) then
			return 612 -- The Fringes
		elseif (level >= 58 and level < 60 and CanAccessMap(478) and CanAccessMap(399)) then
			return 399 --The Dravanian Hinterlands
		elseif (level >= 60 and CanAccessMap(478) and CanAccessMap(399) and not CanAccessMap(612)) then
			return 399 -- The Dravanian Hinterlands
		elseif (level >= 55 and level < 60 and CanAccessMap(398)) then
			return 398	-- The Dravanian Forelands
		elseif (level >= 50 and level < 60 and CanAccessMap(397)) then
			return 397 -- Coerthas Western Highlands		
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
	help = {
		name = "Help Window",
		open = false,
		visible = true,
	},
	informational = {
		name = "Information Window",
		open = false,
		visible = true,
		message = "",
		open_until = 0,
		colors = { r = 1, g = 1, b = 1, a = 1 },
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

ml_global_information.preparers = {}
function ml_global_information.PreUpdate( event, tickcount )
	memoize = {}
	
	-- if other addons/code need to prepare for update, it should be added to the preparers table as a function
	if (table.valid(ml_global_information.preparers)) then
		for _,prep in pairs(ml_global_information.preparers) do
			if (prep and type(prep) == "function") then
				prep()
			end
		end
	end
end

function ml_global_information.OnUpdate( event, tickcount )
    ml_global_information.Now = tickcount
	
	local gamestate = MGetGameState()
	
	ml_global_information.Queueables()
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
				ml_global_information.Await(1000, 10000, function () return MGetGameState() == FFXIV.GAMESTATE.MAINMENUSCREEN end)
			end
		end	
	end
end

function ml_global_information.MainMenuScreenOnUpdate( event, tickcount )
	local login = ffxivminion.loginvars
	if (not login.loginPaused) then
		--d("checking mainmenu")
		
		if (ffxivminion.gameRegion == 1) then
		
			local serviceAccountList = GetConversationList()
			if (table.valid(serviceAccountList)) then
				if (SelectConversationLine(FFXIV_Login_ServiceAccount)) then
					ml_global_information.Await(500, 5000, function () return MGetGameState() ~= FFXIV.GAMESTATE.MAINMENUSCREEN end)
				end
			else
				-- TitleDCWorldMap is used since 4.0 , before older versions use TitleDataCenter
				if (not IsControlOpen("TitleDataCenter") and not IsControlOpen("TitleDCWorldMap") ) then		
					if (UseControlAction("_TitleMenu","OpenDataCenter",0)) then
						ml_global_information.Await(100, 10000, function () return IsControlOpen("TitleDataCenter") or IsControlOpen("TitleDCWorldMap") end)
					end
				else
					if (not login.datacenterSelected) then
						if (FFXIV_Login_DataCenter and FFXIV_Login_DataCenter >= 2 and FFXIV_Login_DataCenter <= 9) then
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
							ml_global_information.Await(1000, 60000, function () return (table.valid(GetConversationList()) or  MGetGameState() ~= FFXIV.GAMESTATE.MAINMENUSCREEN) end)
							ffxivminion.loginvars.datacenterSelected = false
						end
					end
				end	
			end
		else
			if IsControlOpen("_TitleMenu") then		
				if (UseControlAction("_TitleMenu","Start")) then
					ml_global_information.Await(1000, 10000, function () return (table.valid(GetConversationList()) or MGetGameState() ~= FFXIV.GAMESTATE.MAINMENUSCREEN) end)
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
				local SelectYesnoMessage = GetControl("SelectYesno"):GetStrings()[2] or ""
				local QueueString = {
					[0] = "ログイン処理を中断してもよろしいですか？", -- JP
					[1] = "Are you certain you wish to leave the queue?", -- EN
					[2] = "Den Login-Prozess abbrechen?", -- DE
					[3] = "Voulez-vous quitter la queue?", -- FR
					[4] = "确定要取消登录吗？", -- CN
					[6] = "로그인 처리를 중단하시겠습니까?", -- KR
				}
				local ClientLanguage = GetGameLanguage() or 1
				local QueueMessage = QueueString[ClientLanguage]
				if SelectYesnoMessage ~= "" then
					if string.contains(SelectYesnoMessage,QueueMessage) == false then
						UseControlAction("SelectYesno","Yes",0)
					end
				end
			else
				if (UseControlAction("_CharaSelectListMenu","SelectCharacter",FFXIV_Login_Character)) then
					ml_global_information.Await(500, 5000, function () return IsControlOpen("SelectYesno") end)
				end
			end
		end
	elseif (IsControlOpen("SelectOk")) then
		local SelectOKMessage = GetControl("SelectOk"):GetStrings()[2] or ""
		local QueueString = {
			[1] = "This World is currently full.", -- EN
			[2] = "Auf dieser Welt herrscht momentan hoher Andrang", --DE
			[3] = "Ce Monde est plein.", -- FR
			[0] = "順次ログイン処理を行っていますのでしばらくお待ちください。", -- JP
			[4] = "当前服务器繁忙，需要排队进行登录，请耐心等待。", -- CN  
			[6] = "현재 서버가 혼잡합니다." -- KR
		}
		local ClientLanguage = GetGameLanguage() or 1
		local QueueMessage = QueueString[ClientLanguage]
		--d("SelectOKMessage: "..SelectOKMessage)
		--d("QueueMessage: "..QueueMessage)
		if SelectOKMessage ~= "" then
			-- detection for CN language not working, temporarily disable skip
			if ffxivminion.gameRegion == 2 or string.contains(SelectOKMessage,QueueMessage) == true then
				d("Waiting In Login Queue...")
				ml_global_information.Await(1000, 2000, function () return (IsControlOpen("SelectOk")) end)
			else
				--d("Not In Queue")
				if (UseControlAction("SelectOk","Yes",0)) then
					d("Skipping Select Window")
					ml_global_information.Await(500, 1000, function () return (IsControlOpen("SelectOk")) end)
				end
			end
		end
	end
end

ml_global_information.throttleTick = 0
function ml_global_information.InGameOnUpdate( event, tickcount )	
	if ((ml_global_information.throttleTick > 0 and (tickcount - ml_global_information.throttleTick) < 35) or not Player) then
		return false
	end
	ml_global_information.throttleTick = tickcount
	
	if (table.valid(ffxivminion.modesToLoad)) then
		ffxivminion.LoadModes()
		FFXIV_Common_BotRunning = false
	end
	
	if (ml_global_information.autoStartQueued) then
		ml_global_information.autoStartQueued = false
		ml_global_information:ToggleRun() -- convert
	end
		
		--FFXIV_Core_ActiveTaskCount = TableSize(tasktracking)
		
	if (ml_mesh_mgr) then
		if (Player) then
			if (ml_global_information.queueLoader == true) then
				if (not IsControlOpen("NowLoading")) then
					ml_global_information.Player_Aetherytes = GetAetheryteList(true)
					Hacks:Disable3DRendering(gDisableDrawing)
					ml_global_information.queueLoader = false
					
					local currentFile = NavigationManager.CurrentFile
					local path = ml_mesh_mgr.navigationpath or ml_mesh_mgr.defaultpath -- yes this can be nil ..had it , fx
					if(string.valid(path)) then
						currentFile = ml_mesh_mgr.GetString(string.gsub(currentFile, path.."\\", ""))
						if (currentFile ~= FFXIV_Common_NavMesh) then
							FFXIV_Common_NavMesh = currentFile
							FFXIV_Common_NavMeshIndex = GetKeyByValue(FFXIV_Common_NavMesh,FFXIV_Common_MeshList)
						end
					end					
					NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.CUBE, 0)
					NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.FLOOR, 0)
				end
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
	
	local pulseTime = gPulseTime or 150
	if (TimeSince(ml_global_information.lastrun2) >= pulseTime) then
		ml_global_information.lastrun2 = tickcount
		SkillMgr.OnUpdate()
	end
	
	if (Now() >= ml_global_information.nextRun) then
		
		ml_global_information.nextRun = tickcount + pulseTime
		ml_global_information.lastPulseShortened = false
		
		if (ml_mesh_mgr) then
			if (IsControlOpen("NowLoading")) then
				if (ml_global_information.queueLoader == false) then
					Hacks:Disable3DRendering(false)
					ml_global_information.queueLoader = true
				end
			end
		end
		
		if IsNormalMap(Player.localmapid) then
			if QuestCompleted(1597) and (c_getCurrentInfo:evaluate()) then
				e_getCurrentInfo:execute()
			elseif (IsControlOpen("AetherCurrent")) and ffxivminion.AetherCurrentCompleted then
				ActionList:Get(10,67):Cast()
				ffxivminion.AetherCurrentCompleted = false
			end
			if (c_getDutyComplete:evaluate()) then
				e_getDutyComplete:execute()
			end
		end
		if (IsControlOpen("MasterPieceSupply")) then
			local category = GetControlData("MasterPieceSupply","category")
			if (not ffxivminion.lastScripExchangeUpdate[category] or TimeSince(ffxivminion.lastScripExchangeUpdate[category]) > 600000) then
				local items = GetControlData("MasterPieceSupply","items")
				if (table.valid(items)) then
					ffxivminion.scripExchange[category] = {}
					for i,item in pairs(items) do
						ffxivminion.scripExchange[category][HQToID(item.itemid)] = true
					end
					ffxivminion.lastScripExchangeUpdate[category] = Now()
				end
			end
		end
		
		if (gBotMode ~= GetString("assistMode")) then ffxivminion.UpdateGlobals() end
		
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
		
		local et = MGetEorzeaTime()
		FFXIV_Common_EorzeaTime = tostring(et.bell)..":"..(et.minute < 10 and "0" or "")..tostring(et.minute)
		
		if (SkillMgr) then
			ffxivminion.CheckClass()
		end
		
		if (not Player.incombat) then
			if ((ffxivminion.GUI.settings.open and TimeSince(ml_global_information.updateFoodTimer) > 15000) or ml_global_information.updateFoodTimer == 0) then
				ml_global_information.updateFoodTimer = tickcount
				ffxivminion.FillFoodOptions(gFoodAvailableOnly)
			end
		
			if ((FFXIV_Common_BotRunning or not gRepairRunningOnly) and gRepair and GetPatchLevel() < 5.4) then
				if ( TimeSince(ml_global_information.repairTimer) > 30000 ) then
					if (not IsControlOpen("Gathering") and not IsControlOpen("Synthesis") and not Player.incombat) then
						if (NeedsRepair()) then
							Repair()
						end
						ml_global_information.repairTimer = tickcount
					end
				end
			end
			
			-- TODO: This section could potentially cause some FPS drops, need to rework a bit.
			if (FFXIV_Common_BotRunning and ml_task_hub:CurrentTask() ~= nil) then				
				if (gChocoItemString ~= GetString("none")) then
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
											ml_global_information.Await(1500, function () return not MIsMoving() end)
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
		end
			
		if (ml_task_hub.shouldRun) then
			if (not ml_task_hub:Update()) then
				d("No task queued, please select a valid bot mode in the Settings drop-down menu")
			end
		end
    end
end

function ml_global_information.GetMovementInfo(afk)
	local afk = IsNull(afk,false)
	
	local settings = Player.settings
	if (afk or (ml_navigation:HasPath() and ml_navigation.CanRun())) then
		Player:SetMoveMode(0)
		return Player.settings.autoface, 0
	else
		if (gAssistUseAutoFace and not settings.autoface) then
			Player:SetAutoFace(true)
		elseif (not gAssistUseAutoFace and settings.autoface) then
			Player:SetAutoFace(false)
		end
		if (gAssistUseLegacy and settings.movemode == 0) then
			Player:SetMoveMode(1)
		elseif (not gAssistUseLegacy and settings.movemode == 1) then
			Player:SetMoveMode(0)
		end
		return settings.autoface, settings.movemode
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

function SetGearsetInfo(disable)
	local disable = IsNull(disable,gAutoAssign)
	local searchList = Player:GetGearSetList()
	local newSets = {}
	if not disable then
		if table.valid(searchList) then
			for i = 1,38,1 do
				_G["gGearset"..tostring(i)] = 0
				Settings.FFXIVMINION["gGearset"..tostring(i)] = 0
				--d("clearing old gearsets")
			end
		
			for i,e in spairs(searchList) do
				local cleanedName = string.gsub(e.name,"[^0-9]","")
				if not newSets[e.job] then
					newSets[e.job] = tonumber(cleanedName)
					_G["gGearset"..tostring(e.job)] = i
					Settings.FFXIVMINION["gGearset"..tostring(e.job)] = i
					d("Setting gearset info for class ["..tostring(e.job).."] to ["..tostring(i).."]")
				else
					if IsNull(tonumber(cleanedName),0) > newSets[e.job] then
						newSets[e.job] = tonumber(cleanedName)
						_G["gGearset"..tostring(e.job)] = i
						Settings.FFXIVMINION["gGearset"..tostring(e.job)] = i
						d("Setting gearset info for class ["..tostring(e.job).."] to ["..tostring(i).."]")
					end
				end
			end
		else
			for i = 1,38,1 do
				_G["gGearset"..tostring(i)] = 0
				Settings.FFXIVMINION["gGearset"..tostring(i)] = 0
				--d("clearing old gearsets")
			end
		end
	end
end
function ffxivminion.SetMainVars()
	-- Login
	local uuid = GetUUID()
	if ( Settings.Global.FFXIV_Login_DataCenters and string.valid(uuid) and Settings.Global.FFXIV_Login_DataCenters[uuid] ) then
		FFXIV_Login_DataCenterName = Settings.Global.FFXIV_Login_DataCenters[uuid]
	else
		FFXIV_Login_DataCenterName = ffxivminion.GetSetting("FFXIV_Login_DataCenterName",ffxivminion.logincenters[1])
	end
	FFXIV_Login_DataCenter = IsNull(GetKeyByValue(FFXIV_Login_DataCenterName,ffxivminion.logincenters),1)
	
	if ( Settings.Global.FFXIV_Login_Servers and string.valid(uuid) and Settings.Global.FFXIV_Login_Servers[uuid] ) then
		FFXIV_Login_ServerName = Settings.Global.FFXIV_Login_Servers[uuid]
		--d("pulling login server name for uuid ["..tostring(uuid).."], ["..tostring(FFXIV_Login_ServerName).."]")
	else
		FFXIV_Login_ServerName = ffxivminion.GetSetting("FFXIV_Login_ServerName",ffxivminion.loginservers[FFXIV_Login_DataCenter][1])
		--d("pulling first available login server name ["..tostring(FFXIV_Login_ServerName).."]")
	end
	
	local serverIndex = GetKeyByValue(FFXIV_Login_ServerName,ffxivminion.loginservers[FFXIV_Login_DataCenter])
	if (serverIndex == nil) then
		FFXIV_Login_Server = 1
		FFXIV_Login_ServerName = ffxivminion.loginservers[FFXIV_Login_DataCenter]
	else
		FFXIV_Login_Server = serverIndex
	end
	
	if ( Settings.Global.FFXIV_Login_ServiceAccounts and string.valid(uuid) and Settings.Global.FFXIV_Login_ServiceAccounts[uuid] ) then
		FFXIV_Login_ServiceAccount = Settings.Global.FFXIV_Login_ServiceAccounts[uuid]
	else
		FFXIV_Login_ServiceAccount = ffxivminion.GetSetting("FFXIV_Login_ServiceAccount",1)
	end
	
	if ( Settings.Global.FFXIV_Login_Characters and string.valid(uuid) and Settings.Global.FFXIV_Login_Characters[uuid] ) then
		FFXIV_Login_Character = Settings.Global.FFXIV_Login_Characters[uuid]
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
	gBotMode = GetString(gBotMode)
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
	gUseSprint = ffxivminion.GetSetting("gUseSprint",true)
	gSprintDist = ffxivminion.GetSetting("gSprintDist",50)
	
	FFXIV_Craft_UseHQMats = ffxivminion.GetSetting("FFXIV_Craft_UseHQMats",true)
	gUseExpManuals = ffxivminion.GetSetting("gUseExpManuals",true)
	gDeclinePartyInvites = ffxivminion.GetSetting("gDeclinePartyInvites",true)
	gDeclinePartyTeleport = ffxivminion.GetSetting("gDeclinePartyTeleport",true)
	gTradeInviteBusy = ffxivminion.GetSetting("gTradeInviteBusy",true)
	gTradeInviteMessage = ffxivminion.GetSetting("gTradeInviteMessage",false)
	gTradeInviteMessages = ffxivminion.GetSetting("gTradeInviteMessages","?;/shrug")
	
	gFoodAvailableOnly = ffxivminion.GetSetting("gFoodAvailableOnly",true)
	ffxivminion.FillFoodOptions(gFoodAvailableOnly)
	gFood = ffxivminion.GetSetting("gFood",GetString("none"))
	gFoodIndex = IsNull(GetKeyByValue(gFood,gFoods),1)
	gFoods = {GetString("none")}
	gFoodSpecific = ffxivminion.GetSetting("gFoodSpecific",true)
	
	local currentFood = gFoods[gFoodIndex]
	if (gFood ~= currentfood) then
		if (table.valid(gFoods)) then
			for i,food in pairs(gFoods) do
				if (food == Mode) then
					gFoodIndex = i
					gFood =  gFoods[gFoodIndex]
				end
			end
		end
	end
	
	gAutoStart = ffxivminion.GetSetting("gAutoStart",false)
	gAutoAssign = ffxivminion.GetSetting("gAutoAssign",false)
	gTeleportHack = ffxivminion.GetSetting("gTeleportHack",false)
	gDutyTeleportHack = ffxivminion.GetSetting("gDutyTeleportHack",true)
	gTeleportHackParanoid = ffxivminion.GetSetting("gTeleportHackParanoid",false)
	gTeleportHackParanoidDistance = ffxivminion.GetSetting("gTeleportHackParanoidDistance",50)
	
	gSkipCutscene = ffxivminion.GetSetting("gSkipCutscene",false)
	gSkipTalk = ffxivminion.GetSetting("gSkipTalk",false)
	gSkipTalkRunningOnly = ffxivminion.GetSetting("gSkipTalkRunningOnly",false)
	gDisableDrawing = ffxivminion.GetSetting("gDisableDrawing",false)
	gRepair = ffxivminion.GetSetting("gRepair",true)
	gRepairRunningOnly = ffxivminion.GetSetting("gRepairRunningOnly",false)
	gChocoAssist = ffxivminion.GetSetting("gChocoAssist",false)
	gChocoGrind = ffxivminion.GetSetting("gChocoGrind",true)
	gChocoQuest = ffxivminion.GetSetting("gChocoQuest",true)
	
	gChocoStance = ffxivminion.GetSetting("gChocoStance",1)
	gChocoStances = {GetString("stFree"), GetString("stDefender"), GetString("stAttacker"), GetString("stHealer"), GetString("stFollow"), GetString("None")}
	gChocoStanceString = gChocoStances[gChocoStance]
	
	gChocoItem = ffxivminion.GetSetting("gChocoItem",1)
	gChocoItems = { "Curiel Root (EXP)", "Sylkis Bud (ATK)", "Mimmet Gourd (Heal)", "Tantalplant (HP)", "Pahsana Fruit (ENM)", GetString("none") }
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
	
	gEurekaAvoidHP = ffxivminion.GetSetting("gEurekaAvoidHP",100)
	gEurekaRestHP = ffxivminion.GetSetting("gEurekaRestHP",70)
	gEurekaRestMP = ffxivminion.GetSetting("gEurekaRestMP",0)
	gEurekaPotionHP = ffxivminion.GetSetting("gEurekaPotionHP",75)
	gEurekaPotionMP = ffxivminion.GetSetting("gEurekaPotionMP",0)
	gEurekaFleeHP = ffxivminion.GetSetting("gEurekaFleeHP",25)
	gEurekaFleeMP = ffxivminion.GetSetting("gEurekaFleeMP",0)
	gEurekaAntidote = ffxivminion.GetSetting("gEurekaAntidote",false)
	
	
	gStuckReturn = ffxivminion.GetSetting("gStuckReturn",true)
	gStuckTeleport = ffxivminion.GetSetting("gStuckTeleport",false)
	gStuckDisable = ffxivminion.GetSetting("gStuckDisable",true)
	gStuckRemesh = ffxivminion.GetSetting("gStuckRemesh",false)
	
	
	for jobid,abrev in pairs(ffxivminion.classes) do
		local str = "gGearset"..tostring(jobid)
		_G[str] = ffxivminion.GetSetting(str,0)
	end
	
	gQuestAutoEquip = ffxivminion.GetSetting("gQuestAutoEquip",true)	
	-- Auto Grind Stuff
	
	-- Version number used to Auto update vaules. YYYYMMDD
	ffxivminion.AutoGrindDefaultVersion = 20190704
	gAutoGrindVersion = ffxivminion.GetSetting("gAutoGrindVersion",0)
	local SettingsAutoGrindVersion = Settings.FFXIVMINION.gAutoGrindVersion
	if Settings.FFXIVMINION.gAutoGrindVersion < ffxivminion.AutoGrindDefaultVersion then
		Settings.FFXIVMINION.gAutoGrindVersion = ffxivminion.AutoGrindDefaultVersion
		Settings.FFXIVMINION.gAutoGrindCode = ffxivminion.AutoGrindDefault
		gAutoGrindVersion = ffxivminion.AutoGrindDefaultVersion
		d("Autogrind version outdated... Updating to version "..tostring(gAutoGrindVersion))
	end
	gAutoGrindCode = ffxivminion.GetSetting("gAutoGrindCode",ffxivminion.AutoGrindDefault)
	GetBestGrindMap = GetBestGrindMapDefault
	local f = loadstring(gAutoGrindCode)
	if (f ~= nil) then
		GetBestGrindMap = f
	else
		ml_error("Compilation error in auto-grind code:")
		assert(loadstring(gAutoGrindCode))
	end
	
	ffxivminion.AutoGearsetsVersion = 20200522
	gAutoGearsets = ffxivminion.GetSetting("gAutoGearsets",0)
	if gAutoGearsets < ffxivminion.AutoGearsetsVersion then
		gAutoGearsets = ffxivminion.AutoGearsetsVersion
		SetGearsetInfo()
		Settings.FFXIVMINION.gAutoGearsets = gAutoGearsets
	end
	ml_global_information.autoStartQueued = gAutoStart		
	Hacks:Disable3DRendering(gDisableDrawing)
	Hacks:SkipCutscene(gSkipCutscene)
end

-- Module Event Handler
function ffxivminion.HandleInit()
	-- Build bottom menu for new GUI addons.
	ffxivminion.GUI.settings.main_tabs = GUI_CreateTabs("Bot Status,General,Auto-Equip,Behavioral,companion,playerHPMPTP,hacks,advancedSettings,Stuck!",true)
	ffxivminion.GUI.help.main_tabs = GUI_CreateTabs("Report,Help,FAQ,Mesh Report",true)
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
	
	
	local uuid = GetUUID()
	if Settings.FFXIVMINION.classturnins == nil then 
		Settings.FFXIVMINION.classturnins = {}
		Settings.FFXIVMINION.classturnins = Settings.FFXIVMINION.classturnins
	end	
	if not Settings.FFXIVMINION.classturnins[uuid] then
		Settings.FFXIVMINION.classturnins[uuid] = {} 
		if table.valid(c_classexchange.npcids) then
			for i,e in pairs(c_classexchange.npcids) do
				Settings.FFXIVMINION.classturnins[uuid][e] = {}
			end
		end
		Settings.FFXIVMINION.classturnins = Settings.FFXIVMINION.classturnins
	end
	
	gForceAutoEquip = false
	ml_gui.ui_mgr:AddMember({ id = "FFXIVMINION##MENU_SETTINGS", name = "Settings", onClick = function() ffxivminion.GUI.settings.open = not ffxivminion.GUI.settings.open end, tooltip = "Open the FFXIVMinion settings."},"FFXIVMINION##MENU_HEADER")
end

function ffxivminion.SwitchMode(mode)	
	local task = ffxivminion.modes[mode]
    if (task ~= nil) then
		ffxivminion.SetModeOptions(mode)
		ml_global_information.mainTask = task
		
		if (FFXIV_Common_BotRunning) then
			ffxivminion.DutyCurrentData = {}
			ml_global_information:ToggleRun()
		end
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
			[FFXIV.JOBS.WHITEMAGE] 		= ffxiv_combat_whitemage,
			[FFXIV.JOBS.ROGUE]			= ffxiv_combat_rogue,
			[FFXIV.JOBS.NINJA]			= ffxiv_combat_ninja,
			[FFXIV.JOBS.MACHINIST]		= ffxiv_combat_machinist,
			[FFXIV.JOBS.DARKKNIGHT]		= ffxiv_combat_darkknight,
			[FFXIV.JOBS.ASTROLOGIAN]	= ffxiv_combat_astrologian,	
			[FFXIV.JOBS.REDMAGE]		= ffxiv_combat_redmage,
			[FFXIV.JOBS.SAMURAI]		= ffxiv_combat_samurai,
			[FFXIV.JOBS.BLUEMAGE]		= ffxiv_combat_bluemage,				
			[FFXIV.JOBS.GUNBREAKER]		= ffxiv_combat_gunbreaker,
			[FFXIV.JOBS.DANCER]			= ffxiv_combat_dancer,			
			
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
	
	local playerClass = ml_global_information.classes[Player.job]
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
		SkillMgr.UpdateBasicSkills()
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
		SkillMgr.UpdateBasicSkills()
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
    elseif (gBotMode == GetString("none")) then
        ml_task_hub:ClearQueues()
    end
end

function ffxivminion.UpdateGlobals()
	if (gBotMode ~= GetString("assistMode")) then
		if (Player) then
			ml_global_information.Player_Aetherytes = GetAetheryteList()
		end
		
		local meshState = NavigationManager:GetNavMeshState()
		ml_global_information.MeshReady = (meshState == GLOBAL.MESHSTATE.MESHREADY or meshState == GLOBAL.MESHSTATE.MESHEMPTY)
	end
end

function ml_global_information.Reset()
    ml_task_hub:ClearQueues()
    ffxivminion.CheckMode()
end

function ml_global_information.Stop()
	if (MIsMoving() or table.valid(ml_navigation.path)) and gBotMode ~= GetString("assistMode") then
		Player:Stop()
	end
	SkillMgr.receivedMacro = {}
	Hacks:SkipCutscene(gSkipCutscene)
end

function ffxivminion.AddMode(name, task)
	--d("added mode ["..name.."] with type ["..tostring(type(task)).."]")
	if task then
		task.friendly = name
		ffxivminion.modesToLoad[name] = task
	end
end

-- New GUI methods.
function ffxivminion.FillFoodOptions(availableonly)
	local availableonly = IsNull(availableonly,false)
	local allFoods
	if AceLib then
		allFoods = AceLib.API.Items.GetAllFoods(availableonly)
	else
		allFoods = {}
	end
	

	ml_global_information.foods = {}
	if (table.valid(allFoods)) then
		for i,item in pairs(allFoods) do
			ml_global_information.foods[item.name] = {
				id = item.hqid,
				name = item.name,
				buffid = item.buffid,
				buffstackid = item.buffstackid,
			}
		end
	end
	
	gFoods = { GetString("none") }
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
		
		if (Now() < ffxivminion.lastTradeDecline + 15000 and gTradeInviteBusy and (ffxivminion.tradeDeclines > 0 or not gTradeInviteMessage)) then
			d("Trade window active, attempting to close then will go into busy.")
			UseControlAction("Trade","Close")
			ffxivminion.tradeDeclines = ffxivminion.tradeDeclines + 1
			ffxivminion.lastTradeDecline = Now()
			ml_global_information.Await(5000, 
				function () return IsControlOpen("Trade") end, 
				function () 
					d("Trade window closed, doing into busy.")
					SendTextCommand("/busy on")
					ffxivminion.busyTimer = Now() + 60000
				end
			)
		end
		
		if (Now() > ffxivminion.lastTradeMessage + 15000 and ffxivminion.tradeDeclines == 0) then
			if (gTradeInviteMessage and ValidString(gTradeInviteMessages)) then
				d("Trade window active, attepting to send chat message.")
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
					d("Trade window active, now closing window.")
					UseControlAction("Trade","Close")
					ffxivminion.tradeDeclines = ffxivminion.tradeDeclines + 1
					ffxivminion.lastTradeDecline = Now()
				end
			)
		elseif (ffxivminion.tradeDeclines > 0 and gTradeInviteMessage and not gTradeInviteBusy) then
			ml_global_information.AwaitThen(math.random(2000,7000), 
				function ()
					d("Trade window recently closed, not sending chat message.")
					UseControlAction("Trade","Close")
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
	
	if (IsControlOpen("_NotificationTelepo") and toboolean(gDeclinePartyTeleport)) then
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
	local gamestate = MGetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		if (ffxivminion.GUI.main.open) then
			if (ml_global_information.drawMode == 1) then
				GUI:SetNextWindowSize(350,300,GUI.SetCond_FirstUseEver) --set the next window size, only on first ever	
				GUI:SetNextWindowCollapsed(false,GUI.SetCond_Once)
				
				local winBG = GUI:GetStyle().colors[GUI.Col_WindowBg]
				GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
				
				ffxivminion.GUI.main.visible, ffxivminion.GUI.main.open = GUI:Begin(ffxivminion.GUI.main.name, ffxivminion.GUI.main.open)
				if ( ffxivminion.GUI.main.visible ) then 
				
					local x, y = GUI:GetWindowPos()
					local width, height = GUI:GetWindowSize()
					local contentwidth = GUI:GetContentRegionAvailWidth()
					
					ffxivminion.GUI.x = x; ffxivminion.GUI.y = y; ffxivminion.GUI.width = width; ffxivminion.GUI.height = height;
					
					if (FFXIV_Common_BotRunning) then
						GUI:Text(GetString("Bot Status:")) GUI:SameLine()
						GUI:TextColored(.1,1,.2,1,GetString("RUNNING"))
					else
						GUI:Text(GetString("Bot Status:")) GUI:SameLine()
						GUI:TextColored(1,.1,.2,1,GetString("NOT RUNNING"))
					end
					GUI:SameLine((contentwidth - 20),5)
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
					
					GUI:AlignFirstTextHeightToWidgets()
					--GUI:BeginGroup()
					GUI:Text(GetString("botMode")) 
					GUI:SameLine(110)
					GUI:PushItemWidth(contentwidth - 165)
					local modeChanged = GUI_Combo("##"..GetString("botMode"), "gBotModeIndex", "gBotMode", gBotModeList)
					GUI:PopItemWidth()
					if (modeChanged) then
						ffxivminion.SwitchMode(gBotMode)
						local uuid = GetUUID()
						if ( string.valid(uuid) ) then
							if  ( Settings.FFXIVMINION.gBotModes == nil ) then Settings.FFXIVMINION.gBotModes = {} end
							Settings.FFXIVMINION.gBotModes[uuid] = gBotMode
							Settings.FFXIVMINION.gBotModes = Settings.FFXIVMINION.gBotModes
						end
					end
					--GUI:EndGroup()
					
					if (GUI:IsItemHovered()) then 
						GUI:SetTooltip("Assist: Handles combat with a selected skill profile while you do the moving.\
Crafting: Automates crafting of a single item or list using crafting orders.\
Fish: Automates fishing with a marker system, profile or quickstart.\
Gather: Automates gathering with a marker system, profile or quickstart.\
Grind: Various tasks like Fates, Mob farming, Relic (Atma/Luminous) and Hunting log.\
Minigames: Farms MGP via Cuff-a-Cur, Monster Toss and Tower Striker minigames.\
Party-Grind: Follows a party leader around assisting  them in combat.\
Quest: Completes quests based on a questing profile.\
") 
					end
					
					GUI:SameLine()
					if (GUI:Button(GetString("Help!"),55,20)) then
						ffxivminion.GUI.help.open = not ffxivminion.GUI.help.open
					end
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip(GetString("Help, Report and Faqs."))
					end
					local acrEnabled = false					
					if (IsGatherer(Player.job)) then
						if (gACREnabledGather) then
							acrEnabled = true
						end
					elseif (IsCrafter(Player.job)) then
						if (gACREnabledCraft) then
							acrEnabled = true
						end
					elseif (IsFighter(Player.job)) then
						if (IsPVPMap(Player.localmapid)) then
							if (gACREnabledPVP) then
								acrEnabled = true
							end
						else
							if (gACREnabled) then
								acrEnabled = true
							end
						end
					end
					local acrValid = (acrEnabled and table.valid(gACRSelectedProfiles) and gACRSelectedProfiles[Player.job])
					
					if (not acrValid) then
						GUI:AlignFirstTextHeightToWidgets()	
						GUI:Text(GetString("Skill Profile"))
						GUI:SameLine(110)
						
						GUI:PushItemWidth(contentwidth - 103)
						local skillsChanged = GUI_Combo("##"..GetString("Skill Profile"), "gSkillProfileIndex", "gSkillProfile", SkillMgr.profiles)
						GUI:PopItemWidth()
						if (skillsChanged) then
							if acrValid then
								gSkillProfileIndex = 1
							else
								local uuid = GetUUID()
								if ( string.valid(uuid) ) then
									gSMDefaultProfiles[Player.job] = gSkillProfile
									Settings.FFXIVMINION.gSMDefaultProfiles[uuid] = gSMDefaultProfiles
									Settings.FFXIVMINION.gSMDefaultProfiles = Settings.FFXIVMINION.gSMDefaultProfiles
								else
									d("UUID was invalid.")
								end
								
								SkillMgr.UseProfile(gSkillProfile)
							end
						end
							if (GUI:IsItemHovered()) then
								GUI:SetTooltip(GetString("Please ensure _SHB profiles are used for Shadowbringer expansion. \
(Not applicable for Monk or Ninja)"))
							end
						
						if (GUI:Button(GetString("Skill Filters"),(contentwidth / 2) - 4,20)) then
							if gSkillProfileIndex ~= 1 then
								SkillMgr.GUI.filters.open = not SkillMgr.GUI.filters.open
							else
								d("Invalid skill profile")
							end
						end
						if (GUI:IsItemHovered()) then
							GUI:SetTooltip(GetString("Skill Profile Filters."))
						end
						GUI:SameLine(0,8)
						if (GUI:Button(GetString("Skill Manager"),(contentwidth / 2) - 5,20)) then
							SkillMgr.GUI.manager.open = not SkillMgr.GUI.manager.open
						end
						if (GUI:IsItemHovered()) then
							GUI:SetTooltip(GetString("Skill Profile Editor."))
						end
					elseif (acrValid) then
					
						GUI:AlignFirstTextHeightToWidgets()	
						GUI:Text(GetString("ACR Active"))
						GUI:SameLine(110)
						if (GUI:Button(GetString("ACR Options"),150,20)) then
							ACR.OpenProfileOptions()
						end
					end
					
					GUI:Separator()
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
						local GatherClasses = Player.job == 16 or Player.job == 17 or Player.job == 18
						if (GatherClasses) then
							space = -75 
						elseif (not GatherClasses) then
							space = -100
						end
					end
					
					GUI:BeginChild("##main-task-section",0,space,false)
					local mainTask = ml_global_information.mainTask
					if (mainTask) then
						if (mainTask.Draw) then
							mainTask:Draw()
						end
					end
					GUI:EndChild()
					
					if (space == -100 or space == -75) then
						local GatherClasses = Player.job == 16 or Player.job == 17 or Player.job == 18
						if (not GatherClasses) then
							if (GUI:Button(GetString("Add Evac Point"),contentwidth,20)) then
								AddEvacPoint(true)
							end
							if (GUI:IsItemHovered()) then
								GUI:SetTooltip(GetString("Adds an evacuation destination for flee tasks."))
							end
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
					if (GUI:Button(GetString("Advanced Settings"),contentwidth,20)) then
						ffxivminion.GUI.settings.open = not ffxivminion.GUI.settings.open
					end
					if (GUI:Button(GetString("Start / Stop"),contentwidth,20)) then
						ffxivminion.DutyCurrentData = {}
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
	local gamestate = MGetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		if (ffxivminion.GUI.main.open) then		
			if (ml_global_information.drawMode ~= 1) then
				--if gBotMode == GetString("assistMode") or gBotMode == "NavTest" then -- People using this feature are basically hiding the UI.
				if gBotMode == "NavTest" then
					GUI:SetNextWindowSize(200,70,GUI.SetCond_Always) --set the next window size, only on first ever	
				else
					GUI:SetNextWindowSize(190,50,GUI.SetCond_Always) --set the next window size, only on first ever	
				end
				local winBG = GUI:GetStyle().colors[GUI.Col_WindowBg]
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
				if (GUI:IsItemHovered()) then
					if (GUI:IsMouseClicked(0)) then
						ffxivminion.DutyCurrentData = {}
						ml_global_information.ToggleRun()
					end
				end	
				GUI:SameLine(contentwidth-35);
				
				GUI:PopStyleColor()
				GUI:PopStyleVar()
				
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
				
				--[[
				if gBotMode == GetString("assistMode") then
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text(GetString("Target Mode").." = "..tostring(FFXIV_Assist_Modes[FFXIV_Assist_ModeIndex]))
				end
				--]]
				
				if gBotMode == "NavTest" then
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text(GetString("Distance 3d").." = "..tostring(Distance3D(Player.pos.x,Player.pos.y,Player.pos.z,gTestMapX,gTestMapY,gTestMapZ)))
				end
					
				GUI:End()
				GUI:PopStyleColor()
			end
		end
	end
end

function ml_global_information.DrawSettings()
	local gamestate = MGetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		if (ffxivminion.GUI.settings.open) then
			GUI:SetNextWindowSize(600,500,GUI.SetCond_FirstUseEver) --set the next window size, only on first ever	
			GUI:SetNextWindowCollapsed(false,GUI.SetCond_Once)
			
			local winBG = GUI:GetStyle().colors[GUI.Col_WindowBg]
			GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
			
			ffxivminion.GUI.settings.visible, ffxivminion.GUI.settings.open = GUI:Begin(ffxivminion.GUI.settings.name, ffxivminion.GUI.settings.open)
			if ( ffxivminion.GUI.settings.visible ) then 
				
				GUI:BeginChild("main-sidebar",150,0,true)
				local tabindex, tabname = GUI_DrawVerticalTabs(ffxivminion.GUI.settings.main_tabs)
				GUI:EndChild()
		
				GUI:SameLine(170)

				GUI:BeginChild("main-content",0,0,false)
				
				--local tabindex, tabname = GUI_DrawTabs(ffxivminion.GUI.settings.main_tabs)
				--local tabs = ffxivminion.GUI.settings.main_tabs
				
				
				if (tabindex == 9) then
					GUI:BeginChild("##main-header-unstuck",0,GUI_GetFrameHeight(10),true)
				
					GUI:Text(GetString("Options if stuck"));
					GUI_Capture(GUI:Checkbox(GetString("Attempt to remesh area"),gStuckRemesh),"gStuckRemesh");
					GUI_Capture(GUI:Checkbox(GetString("Return if available"),gStuckReturn),"gStuckReturn");
					GUI_Capture(GUI:Checkbox(GetString("Teleport to local Aetheryte"),gStuckTeleport),"gStuckTeleport");
					GUI_Capture(GUI:Checkbox(GetString("Disable Bot"),gStuckDisable),"gStuckDisable");
					
					GUI:EndChild()
				end
					
				if (tabindex == 1) then
					GUI:BeginChild("##main-header-botstatus",0,GUI_GetFrameHeight(10),true)
					GUI:PushItemWidth(100)
					GUI_DrawIntMinMax(GetString("Pulse Time"),"gPulseTime",5,10,5,2000)
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
					GUI_Capture(GUI:Checkbox(GetString("Enable Log"),gEnableLog),"gEnableLog");
					GUI_Capture(GUI:Checkbox(GetString("Log CNE"),gLogCNE),"gLogCNE");
					GUI_Capture(GUI:Combo("Log Level", gLogLevel, gLogLevels ),"gLogLevel")
					
					GUI:LabelText("Eorzea Time",FFXIV_Common_EorzeaTime)
					GUI:LabelText("Memory Usage",FFXIV_Core_MemoryUsage)
					GUI:PopItemWidth()
					GUI:EndChild()
				end
				
				if (tabindex == 2) then
					
					GUI_Capture(GUI:Checkbox(GetString("Auto Start Bot"),gAutoStart),"gAutoStart");
					GUI_Capture(GUI:Checkbox(GetString("Disable Auto Assign Gearsets"),gAutoAssign),"gAutoAssign");
					if gUseSprint == nil then
						gUseSprint = true
					end
					GUI_Capture(GUI:Checkbox(GetString("useSprint"),gUseSprint),"gUseSprint",function () ffxivminion.SaveClassSettings("gUseSprint",gUseSprint) end );
					GUI:SameLine(150)
					GUI:PushItemWidth(100); GUI_DrawIntMinMax(GetString("sprintDist"),"gSprintDist",5,10,0,200); GUI:PopItemWidth()
					
					GUI_Capture(GUI:Checkbox(GetString("useMount"),gUseMount),"gUseMount", 
						function ()
							if (gMountName == GetString("none")) then
								gMountNameIndex = 1
								 GUI_Set("gMountName",gMountNames[1])
							end
						end					
					)
					GUI:SameLine(150)
					GUI:PushItemWidth(100); GUI_DrawIntMinMax(GetString("Mount Distance"),"gMountDist",5,10,0,200); GUI:PopItemWidth()
					
					
					
					GUI:PushItemWidth(200); GUI_Combo(GetString("Mount"), "gMountNameIndex", "gMountName", gMountNames); GUI:PopItemWidth()
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("Pick only a mount that you can actually use.")
					end
					GUI:SameLine(275)
					if (GUI:ImageButton("##main-mounts-refresh",ml_global_information.path.."\\GUI\\UI_Textures\\change.png", 14, 14)) then
						ffxivminion.FillMountOptions()
					end
					GUI:SameLine(0,5)
					GUI_Capture(GUI:Checkbox(GetString("Show Available Mounts Only"),gMountAvailableOnly),"gMountAvailableOnly", ffxivminion.FillMountOptions);
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("If this option is on, no mounts will be shown in an unmountable area.")
					end	
					GUI:PushItemWidth(200); 
					GUI:InputText("##Current Active gFood",gFood,GUI.InputTextFlags_ReadOnly)
					GUI:SameLine()
					GUI:Text(GetString("Current Active Food"))
					GUI:PushItemWidth(200); 
					GUI_Combo(GetString("food"), "gFoodIndex", "gFood", gFoods); GUI:PopItemWidth()
					GUI:SameLine(275)
					if (GUI:ImageButton("##main-food-refresh",ml_global_information.path.."\\GUI\\UI_Textures\\change.png", 14, 14)) then
						ffxivminion.FillFoodOptions(gFoodAvailableOnly)
					end
					GUI:SameLine(0,5)
					GUI_Capture(GUI:Checkbox(GetString("Show Usable Only").."##food",gFoodAvailableOnly),"gFoodAvailableOnly");
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("If this option is on, only available items will be shown.")
					end
					GUI:SameLine(0,5)
					GUI_Capture(GUI:Checkbox(GetString("Enforce Specifics"),gFoodSpecific),"gFoodSpecific");
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("This option will force this specific food to be used, even if another one is currently in use.")
					end
					
					GUI_Capture(GUI:Checkbox(GetString("Avoid AOE"),gAvoidAOE),"gAvoidAOE");
					
					GUI:Separator();
				end	
				
				if (tabindex == 3) then
					GUI:BeginChild("##main-header-autoequip",0,GUI_GetFrameHeight(29.5),true)
					
					GUI_Capture(GUI:Checkbox(GetString("Auto Equip"),gAutoEquip),"gAutoEquip",
						function ()
							if (gBotMode == GetString("questMode")) then
								 GUI_Set("gQuestAutoEquip",gAutoEquip)
							end
						end
					);
					
					GUI:Spacing(); GUI:Spacing(); GUI:Spacing()
					GUI:Text(GetString("Gearsets"));
					
					GUI:BeginChild("##main-header-autoequip-gearsets",0,GUI_GetFrameHeight(26),true)
					local classlookup = {}
					for jobid,abrev in pairs(ffxivminion.classes) do
						classlookup[abrev] = jobid
					end
					
					local tanks = {"GLD","PLD","MRD","WAR","DRK","GNB"}
					local healers = {"CNJ","WHM","SCH","AST"}
					local melee = {"PUG","MNK","LNC","DRG","ROG","NIN","SAM"}
					local ranged = {"ARC","BRD","MCH","DNC"}
					local casters = {"THM","BLM","ACN","SMN","RDM","BLU"}
					local crafters = {"CRP","BSM","ARM","GSM","LTW","WVR","ALC","CUL"}
					local gatherers = {"MIN","BTN","FSH"}
					
					GUI:PushItemWidth(40)

					GUI:Image(ml_global_information.path.."\\GUI\\UI_Textures\\Role_Tank.png", 20, 20); GUI:SameLine(24, 24); GUI:Text("Tanks");
					GUI:Separator();
					
					local count = 1
					for i,abrev in pairsByKeys(tanks) do
						local jobid = classlookup[abrev]
						local str = "gGearset"..tostring(jobid)
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(abrev); GUI:SameLine(); 
						GUI_Capture(GUI:InputInt("##"..abrev,_G[str],0,0),str)
						GUI:SameLine(0,10)
						if (count % 6) == 0 and count ~= table.size(tanks) then GUI:NewLine() end
						count = count + 1
					end
					GUI:Spacing()
					GUI:Spacing()
					GUI:NewLine();
					
					GUI:PushItemWidth(40)
					GUI:Image(ml_global_information.path.."\\GUI\\UI_Textures\\Role_Healer.png", 20, 20) GUI:SameLine(24, 24); GUI:Text("Healers");
					GUI:Separator();
					
					local count = 1
					for i,abrev in pairsByKeys(healers) do
						local jobid = classlookup[abrev]
						local str = "gGearset"..tostring(jobid)
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(abrev); GUI:SameLine(); 
						GUI_Capture(GUI:InputInt("##"..abrev,_G[str],0,0),str)
						GUI:SameLine(0,10)
						if (count % 6) == 0 and count ~= table.size(healers) then GUI:NewLine() end
						count = count + 1
					end
					GUI:Spacing()
					GUI:Spacing()
					GUI:NewLine();
					
					GUI:PushItemWidth(40)
					GUI:Image(ml_global_information.path.."\\GUI\\UI_Textures\\Role_Melee.png", 20, 20) GUI:SameLine(24, 24); GUI:Text("Melee");
					GUI:Separator();
					
					local count = 1
					for i,abrev in pairsByKeys(melee) do
						local jobid = classlookup[abrev]
						local str = "gGearset"..tostring(jobid)
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(abrev); GUI:SameLine(); 
						GUI_Capture(GUI:InputInt("##"..abrev,_G[str],0,0),str)
						GUI:SameLine(0,10)
						if (count % 7) == 0 and count ~= table.size(melee) then GUI:NewLine() end
						count = count + 1
					end
					GUI:Spacing()
					GUI:Spacing()
					GUI:NewLine();

					GUI:PushItemWidth(40)
					GUI:Image(ml_global_information.path.."\\GUI\\UI_Textures\\Role_Ranged.png", 20, 20) GUI:SameLine(24, 24); GUI:Text("Ranged");
					GUI:Separator();
					
					local count = 1
					for i,abrev in pairsByKeys(ranged) do
						local jobid = classlookup[abrev]
						local str = "gGearset"..tostring(jobid)
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(abrev); GUI:SameLine(); 
						GUI_Capture(GUI:InputInt("##"..abrev,_G[str],0,0),str)
						GUI:SameLine(0,10)
						if (count % 6) == 0 and count ~= table.size(ranged) then GUI:NewLine() end
						count = count + 1
					end
					GUI:Spacing()
					GUI:Spacing()
					GUI:NewLine();

					GUI:PushItemWidth(40)
					GUI:Image(ml_global_information.path.."\\GUI\\UI_Textures\\Role_Casters.png", 20, 20) GUI:SameLine(24, 24); GUI:Text("Casters");
					GUI:Separator();
					
					local count = 1
					for i,abrev in pairsByKeys(casters) do
						local jobid = classlookup[abrev]
						local str = "gGearset"..tostring(jobid)
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(abrev); GUI:SameLine(); 
						GUI_Capture(GUI:InputInt("##"..abrev,_G[str],0,0),str)
						GUI:SameLine(0,10)
						if (count % 6) == 0 and count ~= table.size(casters) then GUI:NewLine() end
						count = count + 1
					end
					GUI:Spacing()
					GUI:Spacing()
					GUI:NewLine();

					GUI:PushItemWidth(40)
					GUI:Image(ml_global_information.path.."\\GUI\\UI_Textures\\Role_Crafters.png", 20, 20) GUI:SameLine(24, 24); GUI:Text("Crafters");
					GUI:Separator();
					
					local count = 1
					for i,abrev in pairsByKeys(crafters) do
						local jobid = classlookup[abrev]
						local str = "gGearset"..tostring(jobid)
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(abrev); GUI:SameLine(); 
						GUI_Capture(GUI:InputInt("##"..abrev,_G[str],0,0),str)
						GUI:SameLine(0,10)
						if (count % 8) == 0 and count ~= table.size(crafters) then GUI:NewLine() end
						count = count + 1
					end
					GUI:Spacing()
					GUI:Spacing()
					GUI:NewLine();
					
					GUI:PushItemWidth(40)
					GUI:Image(ml_global_information.path.."\\GUI\\UI_Textures\\Role_Gatherers.png", 20, 20) GUI:SameLine(24, 24); GUI:Text("Gatherers");
					GUI:Separator();
					
					local count = 1
					for i,abrev in pairsByKeys(gatherers) do
						local jobid = classlookup[abrev]
						local str = "gGearset"..tostring(jobid)
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(abrev); GUI:SameLine(); 
						GUI_Capture(GUI:InputInt("##"..abrev,_G[str],0,0),str)
						GUI:SameLine(0,10)
						if (count % 6) == 0 and count ~= table.size(gatherers) then GUI:NewLine() end
						count = count + 1
					end
					GUI:PopItemWidth()
					GUI:EndChild()
				end
			
				if (tabindex == 4) then
					GUI:BeginChild("##main-header-behavior",0,GUI_GetFrameHeight(6),true)
					
					GUI_Capture(GUI:Checkbox(GetString("Decline Party Invites"),gDeclinePartyInvites),"gDeclinePartyInvites");
					GUI_Capture(GUI:Checkbox(GetString("Decline Party Teleport"),gDeclinePartyTeleport),"gDeclinePartyTeleport");
					GUI_Capture(GUI:Checkbox(GetString("/busy After Trade invite"),gTradeInviteBusy),"gTradeInviteBusy");
					GUI_Capture(GUI:Checkbox(GetString("Send Message After Trade Invite."),gTradeInviteMessage),"gTradeInviteMessage");
					GUI_Capture(GUI:InputText(GetString("Message Options"),gTradeInviteMessages),"gTradeInviteMessages");
					
					if (GUI:Button(GetString("Modify Auto-Grind"))) then
						ffxivminion.GUI.autogrind.open = true
						ffxivminion.GUI.autogrind.error_text = ""
					end
					
					GUI:EndChild()
				end
				
				if (tabindex == 5) then
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
				
				if (tabindex == 6) then
					GUI:BeginChild("##main-header-playerhpmptp",0,GUI_GetFrameHeight(7),true)
					GUI:PushItemWidth(120)

					GUI_DrawIntMinMax(GetString("Avoid HP"),"gAvoidHP",1,10,0,100,function () ffxivminion.SaveClassSettings("gAvoidHP",gAvoidHP) end )
					GUI_DrawIntMinMax(GetString("Rest HP"),"gRestHP",1,10,0,100,function () ffxivminion.SaveClassSettings("gRestHP",gRestHP) end)
					GUI_DrawIntMinMax(GetString("Rest MP"),"gRestMP",1,10,0,100,function () ffxivminion.SaveClassSettings("gRestMP",gRestMP) end)
					GUI_DrawIntMinMax(GetString("Potion HP"),"gPotionHP",1,10,0,100,function () ffxivminion.SaveClassSettings("gPotionHP",gPotionHP) end)
					GUI_DrawIntMinMax(GetString("Potion MP"),"gPotionMP",1,10,0,100,function () ffxivminion.SaveClassSettings("gPotionMP",gPotionMP) end)
					GUI_DrawIntMinMax(GetString("Flee HP"),"gFleeHP",1,10,0,100,function () ffxivminion.SaveClassSettings("gFleeHP",gFleeHP) end)
					GUI_DrawIntMinMax(GetString("Flee MP"),"gFleeMP",1,10,0,100,function () ffxivminion.SaveClassSettings("gFleeMP",gFleeMP) end)
					
					GUI:PopItemWidth()
					GUI:EndChild()
					GUI:BeginChild("##Eureka-header-playerhpmptp",0,GUI_GetFrameHeight(8),true)
					GUI:PushItemWidth(120)

					GUI:Text(GetString("Eureka Only"));
					GUI_DrawIntMinMax(GetString("Avoid HP##Eureka"),"gEurekaAvoidHP",1,10,0,100,function () ffxivminion.SaveClassSettings("gEurekaAvoidHP",gEurekaAvoidHP) end )
					GUI_DrawIntMinMax(GetString("Rest HP##Eureka"),"gEurekaRestHP",1,10,0,100,function () ffxivminion.SaveClassSettings("gEurekaRestHP",gEurekaRestHP) end)
					GUI_DrawIntMinMax(GetString("Rest MP##Eureka"),"gEurekaRestMP",1,10,0,100,function () ffxivminion.SaveClassSettings("gEurekaRestMP",gEurekaRestMP) end)
					GUI_DrawIntMinMax(GetString("Potion HP##Eureka"),"gEurekaPotionHP",1,10,0,100,function () ffxivminion.SaveClassSettings("gEurekaPotionHP",gEurekaPotionHP) end)
					GUI_DrawIntMinMax(GetString("Flee HP##Eureka"),"gEurekaFleeHP",1,10,0,100,function () ffxivminion.SaveClassSettings("gEurekaFleeHP",gEurekaFleeHP) end)
					GUI_DrawIntMinMax(GetString("Flee MP##Eureka"),"gEurekaFleeMP",1,10,0,100,function () ffxivminion.SaveClassSettings("gEurekaFleeMP",gEurekaFleeMP) end)
					GUI_Capture(GUI:Checkbox(GetString("Antidote"),gEurekaAntidote),"gEurekaAntidote");
					
					GUI:PopItemWidth()
					GUI:EndChild()
					
				end
				
				if (tabindex == 7) then
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

					GUI_Capture(GUI:Checkbox(GetString("Paranoid"),gTeleportHackParanoid),"gTeleportHackParanoid")
					GUI:SameLine(0,10)
					GUI:PushItemWidth(100)
					GUI_DrawIntMinMax(GetString("D:(25 - 125)"),"gTeleportHackParanoidDistance",1,10,25,125)
					GUI:PopItemWidth()
					
					GUI_Capture(GUI:Checkbox(GetString("Skip Cutscene"),gSkipCutscene),"gSkipCutscene", function () Hacks:SkipCutscene(gSkipCutscene) end)
					GUI_Capture(GUI:Checkbox(GetString("Skip Dialogue"),gSkipTalk),"gSkipTalk"); GUI:SameLine(0,15)
					GUI_Capture(GUI:Checkbox(GetString("Require Bot Running").."##skiptalk",gSkipTalkRunningOnly),"gSkipTalkRunningOnly")
					GUI:EndChild()
				end
				
				if (tabindex == 8) then
					local width, height = GUI:GetWindowSize()
			
					GUI:PushItemWidth(120)
					local dcChanged = GUI_Combo("DataCenter", "FFXIV_Login_DataCenter", "FFXIV_Login_DataCenterName", ffxivminion.logincenters)
					if (dcChanged) then
						local uuid = GetUUID()
						if ( string.valid(uuid) ) then
							if  ( Settings.Global.FFXIV_Login_DataCenters == nil ) then 
								Settings.Global.FFXIV_Login_DataCenters = {} 
							end
							--d("set login datacenter to ["..tostring(FFXIV_Login_DataCenterName).."] for UUID ["..tostring(uuid).."]")
							Settings.Global.FFXIV_Login_DataCenters[uuid] = FFXIV_Login_DataCenterName
							Settings.Global.FFXIV_Login_DataCenters = Settings.Global.FFXIV_Login_DataCenters
						else
							--d("uuid not valid")
						end
						GUI_Set("FFXIV_Login_Server",1)
						GUI_Set("FFXIV_Login_ServerName","")
						if ( string.valid(uuid) ) then
							if  ( Settings.Global.FFXIV_Login_Servers == nil ) then 
								Settings.Global.FFXIV_Login_Servers = {} 
							end
							Settings.Global.FFXIV_Login_Servers[uuid] = FFXIV_Login_ServerName
							Settings.Global.FFXIV_Login_Servers = Settings.Global.FFXIV_Login_Servers
						end
						
						ffxivminion.loginvars.datacenterSelected = false
					end
					
					if (table.valid(ffxivminion.loginservers[FFXIV_Login_DataCenter])) then
						--d("servers are valid for this datacenter")
						
						local serverChanged = GUI_Combo("Server", "FFXIV_Login_Server", "FFXIV_Login_ServerName", ffxivminion.loginservers[FFXIV_Login_DataCenter])
						if (serverChanged) then
							local uuid = GetUUID()
							if ( string.valid(uuid) ) then
								if  ( Settings.Global.FFXIV_Login_Servers == nil ) then 
									Settings.Global.FFXIV_Login_Servers = {} 
								end
								--d("set login server to ["..tostring(FFXIV_Login_ServerName).."] for UUID ["..tostring(uuid).."]")
								Settings.Global.FFXIV_Login_Servers[uuid] = FFXIV_Login_ServerName
								Settings.Global.FFXIV_Login_Servers = Settings.Global.FFXIV_Login_Servers
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
								if  ( Settings.Global.FFXIV_Login_ServiceAccounts == nil ) then 
									Settings.Global.FFXIV_Login_ServiceAccounts = {} 
								end
								Settings.Global.FFXIV_Login_ServiceAccounts[uuid] = FFXIV_Login_ServiceAccount
								Settings.Global.FFXIV_Login_ServiceAccounts = Settings.Global.FFXIV_Login_ServiceAccounts
							end
						end 
					)

					GUI_DrawIntMinMax("Character Index (0-n)","FFXIV_Login_Character",1,1,0,15,
						function () 
							local uuid = GetUUID()
							if ( string.valid(uuid) ) then
								if  ( Settings.Global.FFXIV_Login_Characters == nil ) then 
									Settings.Global.FFXIV_Login_Characters = {} 
								end
								Settings.Global.FFXIV_Login_Characters[uuid] = FFXIV_Login_Character
								Settings.Global.FFXIV_Login_Characters = Settings.Global.FFXIV_Login_Characters
							end
								
							ffxivminion.loginvars.charSelected = false
						end 
					)
					GUI:PopItemWidth()
				end
			
				GUI:EndChild()
			end

			GUI:End()
			GUI:PopStyleColor()
		end
	end
end

function ml_global_information.DrawMiniButtons()
	local gamestate = MGetGameState()
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
				local windowPaddingY = GUI:GetStyle().windowpadding.y
				local framePaddingY = GUI:GetStyle().framepadding.y
				local itemSpacingY = GUI:GetStyle().itemspacing.y

				GUI:SetNextWindowPos(currentX,height - ((fontSize + (framePaddingY * 2) + (itemSpacingY) + (windowPaddingY * 2)) * 2) + windowPaddingY)
				local totalSize = 30
				for i,window in pairs(buttonsNeeded) do
					totalSize = totalSize + (string.len(window.name) * 7.25) + 8
				end
				GUI:SetNextWindowSize(totalSize,fontSize + (framePaddingY * 2) + (itemSpacingY) + (windowPaddingY * 2),GUI.SetCond_Always)
				
				local winBG = GUI:GetStyle().colors[GUI.Col_WindowBg]
				local buttonBG = GUI:GetStyle().colors[GUI.Col_Button]
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
	local gamestate = MGetGameState()
	if (gamestate ~= FFXIV.GAMESTATE.INGAME or ffxivminion.GUI.login.open) then
		
		GUI:SetNextWindowSize(330,145,GUI.SetCond_Always) --set the next window size, only on first ever	
		GUI:SetNextWindowCollapsed(false,GUI.SetCond_Always)
		
		local winBG = GUI:GetStyle().colors[GUI.Col_WindowBg]
		GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
		
		ffxivminion.GUI.login.visible, ffxivminion.GUI.login.open = GUI:Begin(ffxivminion.GUI.login.name, ffxivminion.GUI.login.open)
		if ( ffxivminion.GUI.login.visible ) then 
			
			local width, height = GUI:GetWindowSize()
			
			GUI:PushItemWidth(120)
			local dcChanged = GUI_Combo("DataCenter", "FFXIV_Login_DataCenter", "FFXIV_Login_DataCenterName", ffxivminion.logincenters)
			if (dcChanged) then
				local uuid = GetUUID()
				if ( string.valid(uuid) ) then
					if  ( Settings.Global.FFXIV_Login_DataCenters == nil ) then 
						Settings.Global.FFXIV_Login_DataCenters = {} 
					end
					--d("set login datacenter to ["..tostring(FFXIV_Login_DataCenterName).."] for UUID ["..tostring(uuid).."]")
					Settings.Global.FFXIV_Login_DataCenters[uuid] = FFXIV_Login_DataCenterName
					Settings.Global.FFXIV_Login_DataCenters = Settings.Global.FFXIV_Login_DataCenters
				else
					--d("uuid not valid")
				end
				GUI_Set("FFXIV_Login_Server",1)
				GUI_Set("FFXIV_Login_ServerName","")
				if ( string.valid(uuid) ) then
					if  ( Settings.Global.FFXIV_Login_Servers == nil ) then 
						Settings.Global.FFXIV_Login_Servers = {} 
					end
					Settings.Global.FFXIV_Login_Servers[uuid] = FFXIV_Login_ServerName
					Settings.Global.FFXIV_Login_Servers = Settings.Global.FFXIV_Login_Servers
				end
				
				ffxivminion.loginvars.datacenterSelected = false
			end
			
			if (table.valid(ffxivminion.loginservers[FFXIV_Login_DataCenter])) then
				--d("servers are valid for this datacenter")
				
				local serverChanged = GUI_Combo("Server", "FFXIV_Login_Server", "FFXIV_Login_ServerName", ffxivminion.loginservers[FFXIV_Login_DataCenter])
				if (serverChanged) then
					local uuid = GetUUID()
					if ( string.valid(uuid) ) then
						if  ( Settings.Global.FFXIV_Login_Servers == nil ) then 
							Settings.Global.FFXIV_Login_Servers = {} 
						end
						--d("set login server to ["..tostring(FFXIV_Login_ServerName).."] for UUID ["..tostring(uuid).."]")
						Settings.Global.FFXIV_Login_Servers[uuid] = FFXIV_Login_ServerName
						Settings.Global.FFXIV_Login_Servers = Settings.Global.FFXIV_Login_Servers
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
						if  ( Settings.Global.FFXIV_Login_ServiceAccounts == nil ) then 
							Settings.Global.FFXIV_Login_ServiceAccounts = {} 
						end
						Settings.Global.FFXIV_Login_ServiceAccounts[uuid] = FFXIV_Login_ServiceAccount
						Settings.Global.FFXIV_Login_ServiceAccounts = Settings.Global.FFXIV_Login_ServiceAccounts
					end
				end 
			)

			GUI_DrawIntMinMax("Character Index (0-n)","FFXIV_Login_Character",1,1,0,15,
				function () 
					local uuid = GetUUID()
					if ( string.valid(uuid) ) then
						if  ( Settings.Global.FFXIV_Login_Characters == nil ) then 
							Settings.Global.FFXIV_Login_Characters = {} 
						end
						Settings.Global.FFXIV_Login_Characters[uuid] = FFXIV_Login_Character
						Settings.Global.FFXIV_Login_Characters = Settings.Global.FFXIV_Login_Characters
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
	local gamestate = MGetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		
		if (ffxivminion.GUI.autogrind.open) then
		
			GUI:SetNextWindowSize(700,500,GUI.SetCond_Always) --set the next window size, only on first ever	
			GUI:SetNextWindowCollapsed(false,GUI.SetCond_Always)
			
			local winBG = GUI:GetStyle().colors[GUI.Col_WindowBg]
			GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
			
			ffxivminion.GUI.autogrind.visible, ffxivminion.GUI.autogrind.open = GUI:Begin(ffxivminion.GUI.autogrind.name, ffxivminion.GUI.autogrind.open)
			if ( ffxivminion.GUI.autogrind.visible ) then 
				
				local width, height = GUI:GetWindowSize()
				
				if (GUI:Button(GetString("Reset to Default"))) then
					GUI_Set("gAutoGrindCode",ffxivminion.AutoGrindDefault)
					GetBestGrindMap = GetBestGrindMapDefault
				end
				
				local changed = false
				gAutoGrindCode,changed = GUI:InputTextEditor("##autogrind-editor", gAutoGrindCode, 680, 400, GUI.InputTextFlags_AllowTabInput)
				if (changed) then
					ffxivminion.GUI.autogrind.modified = true
				end
				
				if (ffxivminion.GUI.autogrind.modified) then
					if (GUI:Button(GetString("Apply"),width,20)) then
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

function ml_global_information.DrawHelper() -- Helper Window
	local gamestate = MGetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		if (ffxivminion.GUI.help.open) then
			GUI:SetNextWindowSize(400,700,GUI.SetCond_Always) --set the next window size, only on first ever	
			GUI:SetNextWindowCollapsed(false,GUI.SetCond_Always)
			local winBG = GUI:GetStyle().colors[GUI.Col_WindowBg]
			GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
			ffxivminion.GUI.help.visible, ffxivminion.GUI.help.open = GUI:Begin(ffxivminion.GUI.help.name, ffxivminion.GUI.help.open)
			if ( ffxivminion.GUI.help.visible ) then
				--[[
					if (gBotMode == GetString("grindMode")) then
					elseif (gBotMode == GetString("gatherMode")) then
					elseif (gBotMode == GetString("fishMode")) then
					end
					
					assistMode                      = "Assist",
					grindMode                       = "Grind",
					gatherMode                      = "Gather",
					fishMode                        = "Fish",
					huntMode						= "Hunt",
					huntlogMode						= "Hunting Log",
					partyMode                       = "Party-Grind",
					craftMode                       = "Crafting",
				]]--
				
				GUI:Text(GetString("Current Bot Mode: ")..gBotMode)
				GUI:Separator()
				GUI_DrawTabs(ffxivminion.GUI.help.main_tabs)
				local tabs = ffxivminion.GUI.help.main_tabs
				if not (tabs.tabs[4].isselected) then
					NavigationManager.ShowFloorMesh = false 
					Settings.minionlib.ShowNavPath = false
				end
				if (tabs.tabs[4].isselected) then
					NavigationManager.ShowFloorMesh = true 
					NavigationManager.RenderDistance = 1
					NavigationManager.RenderAlpha = 115
					Settings.minionlib.ShowNavPath = true
					
					
					GUI:Text(GetString("Report issues in the Forum or Discord Channel."))
					GUI:Spacing();
					GUI:Spacing();
					GUI:Text(GetString("Please provide : "))
					GUI:Text(GetString("An image of your ENTIRE SCREEN with your report."))
					GUI:Text(GetString("This tab must be included in the image."))
					GUI:Text(GetString("Hide your Char name!!"))
					GUI:Spacing();
					GUI:Spacing();
					GUI:Separator()
					GUI:Text("MapID: "..tostring(Player.localmapid))
					GUI:Text("Navmesh: ".. tostring(ml_mesh_mgr.currentfilename))
					GUI:Separator()
					GUI:Text("Player position:")
					local PlayerPos = Player.pos
					GUI:Text("X: "..PlayerPos.x)
					GUI:Text("Y: "..PlayerPos.y)
					GUI:Text("Z: "..PlayerPos.z)
					GUI:Separator()
				end
				-- Help tab.
				if (tabs.tabs[2].isselected) then
					if (gBotMode == GetString("assistMode")) then
						GUI:Text(GetString("Assist Mode will... \
\
You Steer, we Shoot. \
\
Combat routines come from Skill Profile or ACR. \
Combat is only as good as the Profile used."))
					elseif (gBotMode == GetString("grindMode")) then
						GUI:Text(GetString("Grind Mode will... \
\
Do Fates, Huntlogs and Grind Mobs. \
\
Only for COMBAT Classes. \
\
While we endevour to Automate Settings, \
Settings can be changed if Advanced Settings is enabled. \
\
Combat routines come from Skill Profile or ACR. \
Combat is only as good as the Profile used."))
					elseif (gBotMode == GetString("gatherMode")) then
						GUI:Text(GetString("Gather Mode will... \
\
Use Markers, Profiles or Quickstart. \
Only for Miner or Botanist. \
\
Skills use are set by Skill Profile"))
					elseif (gBotMode == GetString("fishMode")) then
						GUI:Text(GetString("Fish Mode will... \
\
Use Markers, Profiles or Quickstart. \
\
Only for Fisher. \
\
Skills are NOT set via Skill Profile. \
Set Skills Via Marker or Profiles."))
					elseif (gBotMode == GetString("craftMode")) then
						GUI:Text(GetString("Craft Mode will... \
 \
Craft a list of items Set via Profile\
or \
Craft Single item type in Quickstart. \
\
Only for Craft Classes. \
\
Skills Profiles... \
\
Profile mode is set via the Craft Edit Tab, \
This allows Profiles to swap between crafts \
\
or \
\
Quickstart will use the Active Skill Profile Selection. \
\
Craft Mode is Only as Good as the Skill Profile!!"))
					else
						GUI:Text(GetString("Accepting help and Faq suggestions"))
					end
				end
				-- FAQ tab.
				if (tabs.tabs[3].isselected) then
					if (gBotMode == GetString("assistMode")) then
						GUI:Text(GetString("My Bot Wont attack? \
\
Check your skill profile is set to the right Class/Job. \
Is Start combat Checked?"))
					elseif (gBotMode == GetString("grindMode")) then
						GUI:Text(GetString("My Bot Doesnt move? \
\
Are any valid Fates Available? \
Are Max Fate settings to low? \
\
My Bot Wont attack? \
\
Check your skill profile is set to the right Class/Job."))
					elseif (gBotMode == GetString("gatherMode")) then
						GUI:Text(GetString("Bot Doesnt move? \
\
Profile has no valid tasks? \
Markers have radius to small? \
Heavensward or Stormblood may need Marker list."))
					elseif (gBotMode == GetString("fishMode")) then
						GUI:Text(GetString("Bot Doesnt Fish? \
\
Profile has no valid tasks? \
Current location has Lockout out due to fishing Limit?"))
					elseif (gBotMode == GetString("craftMode")) then
						GUI:Text(GetString("Bot Doesnt Craft? \
\
Profiles... \
Check UI alert and see if there is an alert. \
\
\
Quick start \
Have you set a Skill Profile? \
Do you have materials?"))
					elseif gBotMode == GetString("questMode") then
GUI:Text(GetString("I'm doing the 1-70 quests and above level 30,\
but I still don't have my Chocobo.  Why?"))

GUI:TextColored(1,.1,.2,1,GetString("Most likely it's still doing side quests and hasn't\
advanced the main quest line far enough to get your\
chocobo, that's totally normal.\
Also make sure you've configured the bot to select \
a grand company."))

GUI:Text(GetString("Why is it stuck at the quest asking for my \
chocobo name?"))

GUI:TextColored(1,.1,.2,1,GetString("You've either configured the bot to use an \
invalid name or haven't chosen one."))
					else
						GUI:Text(GetString("Accepting help and Faq suggestions"))
					end
				end
				-- Report tab.
				if (tabs.tabs[1].isselected) then
					GUI:Text("Report issues in the Forum or Discord Channel.")
					GUI:Spacing();
					GUI:TextWrapped("Provide enough information to reproduce the issue.")
					GUI:TextWrapped("If we cant reproduce it, we can't fix it.")
					GUI:Spacing();
					GUI:Spacing();
					GUI:Text("Please provide : ")
					GUI:Text("An image of your ENTIRE SCREEN with your report.")
					GUI:Text("This tab must be included in the image.")
					GUI:Text("Hide your Char name!!")
					GUI:Spacing();
					GUI:Spacing();
					GUI:Text("If the console has error messages")
					GUI:Text("include an image of the console.")
					GUI:Text("The image must show the FULL error.")
					GUI:Separator()
					GUI:Text("MapID: "..tostring(Player.localmapid))
					GUI:Text("Navmesh: ".. tostring(ml_mesh_mgr.currentfilename))
					GUI:Separator()
					GUI:Text("Patch Version:")
					GUI:Text(GetPatchLevel())
					GUI:Separator()
					GUI:Text("Player position:")
					local PlayerPos = Player.pos
					GUI:Text("X: "..PlayerPos.x)
					GUI:Text("Y: "..PlayerPos.y)
					GUI:Text("Z: "..PlayerPos.z)
					GUI:Separator()
					GUI:Text("Class: "); GUI:SameLine();	GUI:Text(tostring(Player.job))
					GUI:SameLine(200);
					GUI:Text("Level: "); GUI:SameLine();	GUI:Text(tostring(Player.level))
					local acrValid =  gACREnabled and (gACRSelectedProfiles[Player.job])
					if acrValid then
						GUI:Text("ACR Profile: "); GUI:SameLine();	GUI:Text((tostring(gACRSelectedProfiles[Player.job])))
					else
						GUI:Text("Skill Profile: "); GUI:SameLine();	GUI:Text(tostring(gSkillProfile))
					end
					GUI:Text("Current Task: "); GUI:SameLine();	GUI:Text(FFXIV_Core_ActiveTaskName)
					GUI:Text("Eorzea Time: "); GUI:SameLine();	GUI:Text(FFXIV_Common_EorzeaTime)
					GUI:Separator()
					local ppos = ml_mesh_mgr.GetPlayerPos()
					if NavigationManager:IsOnMesh(ppos) then
						GUI:Text(GetString("Is On Mesh: ")) GUI:SameLine() GUI:Text(tostring(NavigationManager:IsOnMesh(ppos)))
					else
						GUI:TextColored(1,.1,.2,1,GetString("Not On Mesh"))
					end
					
					if CanAccessMap(818) then
						GUI:Text("Can Access ALL maps");
					elseif CanAccessMap(817) then
						GUI:Text("Can Access The Rak'tika Greatwood");
					elseif CanAccessMap(816) then
						GUI:Text("Can Access Il Mheg");
					elseif CanAccessMap(815) then
						GUI:Text("Can Access Amh Araeng");
					elseif CanAccessMap(814) then
						GUI:Text("Can Access Lakeland");
					elseif CanAccessMap(819) then
						GUI:Text("Can Access The Crystarium");
					elseif CanAccessMap(621) then
						GUI:Text("Can Access The Lochs");
					elseif CanAccessMap(622) then
						GUI:Text("Can Access Azim Steppes");
					elseif CanAccessMap(614) then
						GUI:Text("Can Access Yanxia");
					elseif CanAccessMap(613) then
						GUI:Text("Can Access The Ruby Sea");
					elseif CanAccessMap(612) then
						GUI:Text("Can Access The Fringes");
					elseif CanAccessMap(402) then
						GUI:Text("Can Access Azys Lla");
					elseif CanAccessMap(399) then
						GUI:Text("Can Access Dravanian Hinterlands");
					elseif CanAccessMap(398) then
						GUI:Text("Can Access Dravanian Forelands");
					elseif CanAccessMap(397) then
						GUI:Text("Can Access CWH");
					elseif CanAccessMap(418) then
						GUI:Text("Can NOT Access CWH");
					elseif not CanAccessMap(418) then
						GUI:Text("Can NOT Access Heavensward maps");
					end
					
					GUI:Text("Can Fly on Map: "); GUI:SameLine(); GUI:Text(tostring(Player.flying.canflyinzone))
					GUI:Text("Mount Can Fly: "); GUI:SameLine(); GUI:Text(tostring(Player.mountcanfly))
					GUI:Text("Is Flying: "); GUI:SameLine(); GUI:Text(tostring(Player.flying.isflying))
					GUI:SameLine(200);
					GUI:Text("Is Diving: "); GUI:SameLine(); GUI:Text(tostring(Player.diving.isdiving))
					GUI:Text("Is Position Locked: "); GUI:SameLine(); GUI:Text(tostring(IsPositionLocked()))
					GUI:Separator()
					if gBotMode == GetString("questMode") then
						local questList = Quest:GetQuestList()
						if (TableSize(questList) > 0) then
							GUI:Text("Quest Journal size : "); GUI:SameLine(); GUI:Text(TableSize(questList))
						end
						
						GUI:Text("Profile : "); GUI:SameLine(); GUI:Text(gQuestProfile)
						if gCurrQuestID ~= "" then
							GUI:Text("Quest ID : "); GUI:SameLine(); GUI:Text(gCurrQuestID)
						end
						if gQuestStepType ~= "" then
							GUI:Text("Quest Task : "); GUI:SameLine(); GUI:Text(gQuestStepType)
						end
						if gCurrQuestStep ~= "" then
							GUI:Text("Quest Step Index : "); GUI:SameLine(); GUI:Text(gCurrQuestStep)
						end
						if gCurrQuestObjective ~= "" then
							GUI:Text("Quest Objective : "); GUI:SameLine(); GUI:Text(gCurrQuestObjective)
						end
						if gCurrQuestStep ~= "" then
							GUI:Text("Quest Step : "); GUI:SameLine(); GUI:Text(gCurrQuestStep)
						end
					end
					
					if (gBotMode == GetString("questMode") and _G["gQuestStepType"] == "grind") or gBotMode == GetString("grindMode") then
						if gEnableAdvancedGrindSettings then
							
							local minFateLevel = IsNull(tonumber(gGrindFatesMinLevel),0)
							local maxFateLevel = IsNull(tonumber(gGrindFatesMaxLevel),0)
							GUI:Text("Yes I was silly and altered deault fate settings!");
							if gGrindDoFates then
								GUI:Text(table.size(GetApprovedFates()).." Fates available in my area and for my lvl settings");
								if SetNoMinFateLevel then
									GUI:Text("No Min fate level");
								else
									GUI:Text("Min fate level is "..math.max((Player.level - minFateLevel),0));
								end
								if SetNoMaxFateLevel then
									GUI:Text("No Max fate level");
								else
									GUI:Text("Max fate level is "..(Player.level + gGrindFatesMaxLevel));
								end
							else
								GUI:Text("Do Fates is disabled");
							end
						else
							local minFateLevel = 70
							local maxFateLevel = 2
							GUI:Text("Using Default Grind settings");
							if gGrindDoFates then
								GUI:Text(table.size(GetApprovedFates()).." Fates available in my area and for my lvl settings");
								if SetNoMinFateLevel then
									GUI:Text("No Min fate level");
								else
									GUI:Text("Min fate level is "..math.max((Player.level - minFateLevel),0));
								end
								if SetNoMaxFateLevel then
									GUI:Text("No Max fate level");
								else
									GUI:Text("Max fate level is "..(Player.level + maxFateLevel));
								end
							else
								GUI:Text("Do Fates is disabled");
							end
						end
					end
				end
			end
			GUI:End()
			GUI:PopStyleColor()
		end
	end
end

function ml_global_information.ShowInformation(message, timer, r, g, b, a)
	ffxivminion.GUI.informational.open_until = Now() + IsNull(timer,5000)
	if (type(message) == "string") then
		ffxivminion.GUI.informational.message = message
		ffxivminion.GUI.informational.messagelines = {}
	elseif (type(message) == "table") then
		ffxivminion.GUI.informational.messagelines = message
		ffxivminion.GUI.informational.message = ""
	end
	ffxivminion.GUI.informational.colors = {
		r = IsNull(r,.5), g = IsNull(g,.1), b = IsNull(b,.1), a = IsNull(a,.75)
	}
	ffxivminion.GUI.informational.open = true
end

function ml_global_information.DrawInformationPopup() -- Helper Window
	local gamestate = MGetGameState()
	if (gamestate == FFXIV.GAMESTATE.INGAME) then
		local drawSegment = ffxivminion.GUI.informational
		if (drawSegment.open) then
			if (Now() > drawSegment.open_until) then
				drawSegment.open = false
			else
				local maxWidth, maxHeight = GUI:GetScreenSize()
				GUI:SetNextWindowPos((maxWidth/2 - 250),(maxHeight/2 + 200), GUI.SetCond_Always)
				if (table.valid(drawSegment.messagelines)) then
					GUI:SetNextWindowSize(500,GUI_GetFrameHeight(table.size(drawSegment.messagelines)),GUI.SetCond_Always)
				else
					GUI:SetNextWindowSize(500,GUI_GetFrameHeight(1),GUI.SetCond_Always)
				end
				
				local winBG = GUI:GetStyle().colors[GUI.Col_WindowBg]				
				GUI:PushStyleColor(GUI.Col_WindowBg, drawSegment.colors.r, drawSegment.colors.g, drawSegment.colors.b, drawSegment.colors.a)
				flags = (GUI.WindowFlags_NoInputs + GUI.WindowFlags_NoBringToFrontOnFocus + GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
				drawSegment.visible, drawSegment.open = GUI:Begin(drawSegment.name, drawSegment.open, flags)
				if ( drawSegment.visible ) then 
					if (table.valid(drawSegment.messagelines)) then
						for i,message in pairsByKeys(drawSegment.messagelines) do
							GUI:Text(message)	
						end
					else
						GUI:Text(drawSegment.message)	
					end
				end
				GUI:PopStyleColor()
				GUI:End()
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
	ml_global_information.DrawHelper()
	ml_global_information.DrawStuck()
	ml_global_information.DrawInformationPopup()
end

-- Register Event Handlers
RegisterEventHandler("Module.Initalize",ffxivminion.HandleInit,"ffxivminion.HandleInit")
RegisterEventHandler("Gameloop.Update",ml_global_information.OnUpdate,"ml_global_information.OnUpdate")
RegisterEventHandler("Gameloop.Draw", ml_global_information.Draw,"ml_global_information.Draw")

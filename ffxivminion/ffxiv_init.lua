-- Add things to ml_global_information, we no longer create it.	
--[[
FFXIV.JOBS = {
	ADVENTURER = 0,
	GLADIATOR = 1,
	PUGILIST = 2,
	MARAUDER = 3,
	LANCER = 4,
	ARCHER = 5,
	CONJURER = 6,
	THAUMAGURGE = 7,
	CARPENTER = 8,
	BLACKSMITH = 9,
	ARMORER = 10,
	GOLDSMITH = 11,
	LEATHERWORKER = 12,
	WEAVER = 13,
	ALCHEMIST = 14,
	CULINARIAN = 15,
	MINER = 16,
	BOTANIST = 17,
	FISHER = 18,
	PALADIN = 19,
	MONK = 20,
	WARRIOR = 21,
	DRAGOON = 22,
	BARD = 23,
	WHITEMAGE = 24,
	BLACKMAGE = 25,
	ARCANIST = 26,
	SUMMONER = 27,
	SCHOLER= 28,
	ROGUE = 29,
	NINJA = 30,
	MACHINIST = 31,
	DARKKNIGHT = 32,
	ASTROLOGIAN = 33,
}
--]]
if (FFXIV.JOBS.VIPER == nil) then
	FFXIV.JOBS.VIPER = 41
end
if (FFXIV.JOBS.PICTOMANCER == nil) then
	FFXIV.JOBS.PICTOMANCER = 42
end

ml_global_information.path = GetStartupPath()
ml_global_information.Now = 0
ml_global_information.yield = {}
ml_global_information.nextRun = 0
ml_global_information.lastPulseShortened = false
ml_global_information.lastrun2 = 0
ml_global_information.CurrentClass = nil
ml_global_information.CurrentClassID = 0
ml_global_information.AttackRange = 2
ml_global_information.MarkerMinLevel = 1
ml_global_information.MarkerMaxLevel = 50
ml_global_information.BlacklistContentID = ""
ml_global_information.WhitelistContentID = ""
ml_global_information.MarkerTime = 0
ml_global_information.afkTimer = 0
ml_global_information.syncTimer = 0
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
ml_global_information.loadCompleted = false
ml_global_information.blacklistedAetherytes = {}
ml_global_information.navObstacles = {}
--ml_global_information.navObstaclesTimer = 0
ml_global_information.suppressRestTimer = 0
ml_global_information.lastInventorySnapshot = {}
ml_global_information.repairBlacklist = {}
ml_global_information.avoidanceAreas = {}
ml_global_information.lastMeasure = 0
ml_global_information.requiresTransport = {}
ml_global_information.landing = nil
ml_global_information.queueLoader = false
-- Split this into 2 variables to deal with the logic timing.
-- [needsStealth] must be known in order to adjust the path request, and [canStealth] must come after to adjust actual activity performed.
ml_global_information.needsStealth = false
ml_global_information.canStealth = false
ml_global_information.gatherid = 0
ml_global_information.targetid = 0
ml_global_information.foods = {}
ml_global_information.mainTask = nil;
ml_global_information.drawMode = 1
ml_global_information.lastEquip = 0
ml_global_information.lastSkipTalk = 0
ml_global_information.buyBlacklist = {}

--Setup Globals
ml_global_information.lastUpdate = 0
ml_global_information.Player_Aetherytes = {}
ml_global_information.Player_Map = 0
ml_global_information.MeshReady = false

ml_global_information.chocoStance = {
	[GetString("stFollow")] = 3,
	[GetString("stFree")] = 4,
	[GetString("stDefender")] = 5,
	[GetString("stAttacker")] = 6,
	[GetString("stHealer")] = 7,
}

ml_global_information.classes = {}
ml_global_information.blacklistedAetherytes = {}

ml_global_information.chocoItemBuffs = {
	[7894] = { name = "Curiel Root (EXP)", item = 7894, buff1 = 536, buff2 = 537 },
	[7895] = { name = "Sylkis Bud (ATK)", item = 7895, buff1 = 538, buff2 = 539 },
	[7897] = { name = "Mimmet Gourd (Heal)", item = 7897, buff1 = 540, buff2 = 541 },
	[7898] = { name = "Tantalplant (HP)", item = 7898, buff1 = 542, buff2 = 543 },
	[7900] = { name = "Pahsana Fruit (ENM)", item = 7900, buff1 = 544, buff2 = 545 },
}

function ml_global_information.ToggleRun()	
	if ( ml_task_hub.shouldRun ) then
		ml_task_hub.shouldRun = false
		FFXIV_Common_BotRunning = false
	else
		ml_task_hub.shouldRun = true
		FFXIV_Common_BotRunning = true
	end	

	if (ml_task_hub.shouldRun) then
		ml_global_information.Reset()
	else
		ml_global_information.yield = {}
		ml_global_information.Stop()
	end
	
	-- Do some resets here.
	ml_marker_mgr.currentMarker = nil
end

function ml_global_information.GetMainIcon()
	local iconPath = ml_global_information.path.."\\GUI\\UI_Textures\\"
	if (ml_global_information.drawMode == 1) then
		return iconPath.."collapse.png"
	else
		return iconPath.."expand.png"
	end
end

function ml_global_information.NodeNeighbors(self)
	if (table.valid(self.neighbors)) then
		local validNeighbors = deepcopy(self.neighbors)
		
		for id,entries in pairs(validNeighbors) do
			for i,entrydata in pairs(entries) do
				if (entrydata.requires) then
					local add = true
					local requirements = shallowcopy(entrydata.requires)
					for requirement,value in pairs(requirements) do
						local ok, ret = LoadString("return " .. requirement)
						if (ok and ret ~= nil) then
							if (ret ~= value) then
								add = false
							end
						end
						if (not add) then
							break
						end
					end
					if (not add) then
						if (TableSize(validNeighbors[id]) > 1) then
							--d("Requirement not met, removing neighbor ["..tostring(id).."], entry # ["..tostring(i).."].")
							validNeighbors[id][i] = nil
						elseif (TableSize(validNeighbors[id]) == 1) then	
							--d("Requirement not met, removing neighbor ["..tostring(id).."] entirely.")
							validNeighbors[id] = nil
						end
					end
				end
			end			
		end
		
		return validNeighbors
	end
    return nil
end

function ml_global_information.NodeClosestNeighbor(self, origin, id)
	local neighbor = self:GetNeighbor(id)
	if (table.valid(neighbor)) then
		if (TableSize(neighbor) > 1) then
			local bestPos = nil
			local bestDist = math.huge
			for id, posTable in pairs(neighbor) do
				local valid = true
				if (posTable.requires) then
					local requirements = shallowcopy(posTable.requires)
					for requirement,value in pairs(requirements) do
						local ok, ret = LoadString("return " .. requirement)
						if (ok and ret ~= nil) then
							if (ret ~= value) then
								valid = false
							end
						end
						if (not valid) then
							break
						end
					end
				end
				
				if (valid) then
					local dist = PDistance3D(origin.x, origin.y, origin.z, posTable.x, posTable.y, posTable.z)
					if (dist < bestDist) then
						bestPos = posTable
						bestDist = dist
					end
				end
			end
			
			if (table.valid(bestPos)) then
				return bestPos
			end
		elseif (TableSize(neighbor == 1)) then
			local i,best = next(neighbor)
			if (i and best) then
				return best
			end
		end
    end
    
    return nil
end

function ml_global_information.AwaitDo(param1, param2, param3, param4, param5)
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
		ml_global_information.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			dowhile = param4,
			followall = param5,
		}
	else
		ml_global_information.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			dowhile = param3,
			followall = param4,
		}
	end
end

function ml_global_information.AwaitThen(param1, param2, param3, param4)
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
		if (param4 ~= nil and type(param4) == "function") then
			ml_global_information.yield = {
				mintimer = IIF(param1 ~= 0,Now() + param1,0),
				maxtimer = IIF(param2 ~= 0,Now() + param2,0),
				evaluator = param3,
				followall = param4,
			}
		else
			ml_global_information.yield = {
				mintimer = IIF(param1 ~= 0,Now() + param1,0),
				maxtimer = IIF(param2 ~= 0,Now() + param2,0),
				followall = param3,
			}
		end
	else
		if (param3 ~= nil and type(param3) == "function") then
			ml_global_information.yield = {
				mintimer = 0,
				maxtimer = Now() + param1,
				evaluator = param2,
				followall = param3,
			}
		else
			ml_global_information.yield = {
				mintimer = 0,
				maxtimer = Now() + param1,
				followall = param2,
			}
		end
	end
end

-- code for delayed queueables, use to execute miscellaneous delayed actions/lua
ml_global_information.queueables = {}

-- add a function to be executed after a time specified by delay "timer" in ms, or earlyout function "earlyout"
function ml_global_information.Queue(timer,func,earlyout)
	local queueable = { timer = Now() + timer, executor = func, earlyout = earlyout }
	table.insert(ml_global_information.queueables,queueable)
end

function ml_global_information.Queueables()
	if (table.valid(ml_global_information.queueables)) then
		for k,v in pairsByKeys(ml_global_information.queueables) do
			if (Now() >= v.timer or (v.earlyout and type(v.earlyout) == "function" and v.earlyout() == true)) then
				if (v.executor and type(v.executor) == "function") then
					v.executor()
					ml_global_information.queueables[k] = nil
				end
			end
		end
	end
end

function ml_global_information.TestQueue()
	SendTextCommand("/echo reset")
	ml_global_information.Queue(5000,
		function() 
			SendTextCommand("/echo first") 
			ml_global_information.Queue(1000,
				function() 
					SendTextCommand("/echo second") 
				end
			)
		end
	)
end

function ml_global_information.Init()
	-- Update default meshes.
	do
		BehaviorManager:ToggleMenu()
		ml_mesh_mgr.averagegameunitsize = 1
		ml_mesh_mgr.useQuaternion = false
		
		local enforce = nil
		if (not Settings.minionlib.newnavsystemlive_3) then
			-- We are running the new nav the first time or switched to it after using the old one last time, set the new default mesh names:
			enforce = true
			Settings.minionlib.newnavsystemlive_3 = true
		end
		
		-- Set default meshes SetDefaultMesh(mapid, filename)
		
		-- Cities ARR
		ml_mesh_mgr.SetDefaultMesh(130, "Ul'dah - Steps of Nald", enforce)
		ml_mesh_mgr.SetDefaultMesh(182, "Ul'dah - Steps of Nald", enforce)
		ml_mesh_mgr.SetDefaultMesh(131, "Ul'dah - Steps of Thal", enforce)
		ml_mesh_mgr.SetDefaultMesh(128, "Limsa Lominsa Upper Decks", enforce)
		ml_mesh_mgr.SetDefaultMesh(181, "Limsa Lominsa", enforce)
		ml_mesh_mgr.SetDefaultMesh(129, "Limsa Lominsa Lower Decks", enforce)
		ml_mesh_mgr.SetDefaultMesh(132, "New Gridania", enforce)
		ml_mesh_mgr.SetDefaultMesh(183, "New Gridania", enforce)
		ml_mesh_mgr.SetDefaultMesh(133, "Old Gridania", enforce)
		
		-- Barracks
		ml_mesh_mgr.SetDefaultMesh(534, "Twin Adder Barrack", enforce)
		ml_mesh_mgr.SetDefaultMesh(535, "Flame Barracks", enforce)
		ml_mesh_mgr.SetDefaultMesh(536, "Maelstrom Barracks", enforce)
		
		-- Cities HW
		ml_mesh_mgr.SetDefaultMesh(418, "Foundation", enforce)
		ml_mesh_mgr.SetDefaultMesh(419, "The Pillars", enforce)
		ml_mesh_mgr.SetDefaultMesh(428, "Seat of the Lord Commander", true)
		ml_mesh_mgr.SetDefaultMesh(427, "Saint Endalim's Scholasticate", true)
		ml_mesh_mgr.SetDefaultMesh(439, "The Lightfeather Proving Grounds", true)
		ml_mesh_mgr.SetDefaultMesh(433, "Fortemps Manor", true)
		ml_mesh_mgr.SetDefaultMesh(456, "Ruling Chamber", true)
		ml_mesh_mgr.SetDefaultMesh(886, "The Firmament", true)
		
		ml_mesh_mgr.SetDefaultMesh(478, "Idyllshire", enforce)
		
		-- Cities SB
		
		-- Cities SHB
		
		-- Main Areas ARR
		ml_mesh_mgr.SetDefaultMesh(134, "Middle La Noscea", enforce)
		ml_mesh_mgr.SetDefaultMesh(135, "Lower La Noscea", enforce)
		ml_mesh_mgr.SetDefaultMesh(137, "Eastern La Noscea", enforce)
		ml_mesh_mgr.SetDefaultMesh(138, "Western La Noscea", enforce)
		ml_mesh_mgr.SetDefaultMesh(139, "Upper La Noscea", enforce)
		ml_mesh_mgr.SetDefaultMesh(180, "Outer La Noscea", enforce)
		ml_mesh_mgr.SetDefaultMesh(177, "Mizzenmast Inn", true)
		ml_mesh_mgr.SetDefaultMesh(198, "Command Room", true)
		
		ml_mesh_mgr.SetDefaultMesh(140, "Western Thanalan", enforce)
		ml_mesh_mgr.SetDefaultMesh(141, "Central Thanalan", enforce)
		ml_mesh_mgr.SetDefaultMesh(145, "Eastern Thanalan", enforce)
		ml_mesh_mgr.SetDefaultMesh(146, "Southern Thanalan", enforce)
		ml_mesh_mgr.SetDefaultMesh(147, "Northern Thanalan", enforce)
		ml_mesh_mgr.SetDefaultMesh(178, "The Hourglass", true)
		ml_mesh_mgr.SetDefaultMesh(210, "Heart of the Sworn", true)
		
		ml_mesh_mgr.SetDefaultMesh(148, "Central Shroud", enforce)
		ml_mesh_mgr.SetDefaultMesh(152, "East Shroud", enforce)
		ml_mesh_mgr.SetDefaultMesh(153, "South Shroud", enforce)
		ml_mesh_mgr.SetDefaultMesh(154, "North Shroud", enforce)
		ml_mesh_mgr.SetDefaultMesh(179, "The Roost", true)
		ml_mesh_mgr.SetDefaultMesh(205, "Lotus Stand", true)
		ml_mesh_mgr.SetDefaultMesh(204, "Seat of the First Bow", true)

		ml_mesh_mgr.SetDefaultMesh(155, "Coerthas Central Highlands", enforce)
		ml_mesh_mgr.SetDefaultMesh(156, "Mor Dhona", enforce)
		
		ml_mesh_mgr.SetDefaultMesh(212, "The Waking Sands", true)
		ml_mesh_mgr.SetDefaultMesh(351, "The Rising Stones", true)
		ml_mesh_mgr.SetDefaultMesh(395, "Intercessory", true)
		
		-- Gold Saucer
		ml_mesh_mgr.SetDefaultMesh(144, "The Gold Saucer", true)
		ml_mesh_mgr.SetDefaultMesh(388, "Chocobo Square", true)
		
		-- Main Areas HW
		ml_mesh_mgr.SetDefaultMesh(397, "Coerthas Western Highlands", enforce)
		ml_mesh_mgr.SetDefaultMesh(398, "The Dravanian Forelands", enforce)
		ml_mesh_mgr.SetDefaultMesh(399, "The Dravanian Hinterlands", enforce)
		ml_mesh_mgr.SetDefaultMesh(400, "The Churning Mists", enforce)
		ml_mesh_mgr.SetDefaultMesh(401, "The Sea of Clouds", enforce)
		ml_mesh_mgr.SetDefaultMesh(402, "Azys Lla", enforce)
		
		ml_mesh_mgr.SetDefaultMesh(463, "Matoya's Cave", true)
		
		-- Main Areas SB
		ml_mesh_mgr.SetDefaultMesh(612, "The Fringes", enforce)
		ml_mesh_mgr.SetDefaultMesh(613, "The Ruby Sea", enforce)
		ml_mesh_mgr.SetDefaultMesh(614, "Yanxia", enforce)
		ml_mesh_mgr.SetDefaultMesh(620, "The Peaks", enforce)
		ml_mesh_mgr.SetDefaultMesh(621, "The Lochs", enforce)
		ml_mesh_mgr.SetDefaultMesh(622, "The Azim Steppe", enforce)
		
		ml_mesh_mgr.SetDefaultMesh(628, "Kugane", enforce)
		ml_mesh_mgr.SetDefaultMesh(735, "The Prima Vista Tiring Room", enforce)
		ml_mesh_mgr.SetDefaultMesh(736, "The Prima Vista Bridge", enforce)
		ml_mesh_mgr.SetDefaultMesh(635, "Rhalgr's Reach", enforce)
		ml_mesh_mgr.SetDefaultMesh(639, "Ruby Bazaar Offices", enforce)
		
		ml_mesh_mgr.SetDefaultMesh(680, "ImOnABoat", enforce)
		ml_mesh_mgr.SetDefaultMesh(681, "The House of the Fierce", enforce)
		ml_mesh_mgr.SetDefaultMesh(683, "First Alter of Djanan", enforce)
		ml_mesh_mgr.SetDefaultMesh(744, "Kienkan", enforce)
		ml_mesh_mgr.SetDefaultMesh(759, "Doman Enclave", enforce)
		ml_mesh_mgr.SetDefaultMesh(786, "Castrum Fluminis", enforce)
		
		-- Main Areas SHB
		
		 -- PVP
		ml_mesh_mgr.SetDefaultMesh(337, "Wolves' Den Pier", enforce)
		ml_mesh_mgr.SetDefaultMesh(336, "Wolves' Den Pier", enforce)
		ml_mesh_mgr.SetDefaultMesh(175, "Wolves' Den Pier", enforce)
		ml_mesh_mgr.SetDefaultMesh(352, "Wolves' Den Pier", enforce)
		ml_mesh_mgr.SetDefaultMesh(186, "Wolves' Den Pier", enforce)
		ml_mesh_mgr.SetDefaultMesh(250, "Wolves' Den Pier", enforce)		

		
		--ml_mesh_mgr.SetDefaultMesh(376, "Frontlines", enforce)
		--ml_mesh_mgr.SetDefaultMesh(422, "Frontlines - Slaughter", enforce)
		--ml_mesh_mgr.SetDefaultMesh(431, "Seal Rock", enforce)
		--ml_mesh_mgr.SetDefaultMesh(554, "[PVP] - Fields of Glory (Shatter)", enforce)
		--ml_mesh_mgr.SetDefaultMesh(729, "[PVP] - Astragalos (Rival Wings)", enforce)
		ml_mesh_mgr.SetDefaultMesh(888, "[PVP] Onsal Hakair", enforce)
		
		 -- Housing
		ml_mesh_mgr.SetDefaultMesh(339, "[Housing] Mist", nil)
		ml_mesh_mgr.SetDefaultMesh(340, "[Housing] Lavender Beds", nil)
		ml_mesh_mgr.SetDefaultMesh(341, "[Housing] The Goblet", nil)
		ml_mesh_mgr.SetDefaultMesh(641, "[Housing] Shirogane", nil)
		ml_mesh_mgr.SetDefaultMesh(979, "Empyreum", nil)
		
		-- Dungeons ARR
		ml_mesh_mgr.SetDefaultMesh(157, "[Dungeon] Sastasha", enforce)
		ml_mesh_mgr.SetDefaultMesh(1036, "[Dungeon] Sastasha", enforce)
		ml_mesh_mgr.SetDefaultMesh(164, "[Dungeon] Tamtara", enforce)
		ml_mesh_mgr.SetDefaultMesh(1037, "[Dungeon] Tamtara", enforce)
		ml_mesh_mgr.SetDefaultMesh(161, "[Dungeon] Copperbell Mines", enforce)
		ml_mesh_mgr.SetDefaultMesh(1038, "[Dungeon] Copperbell Mines v2", enforce)
		ml_mesh_mgr.SetDefaultMesh(162, "[Dungeon] Halatali", enforce)
		ml_mesh_mgr.SetDefaultMesh(169, "[Dungeon] Toto-Rak", enforce)
		ml_mesh_mgr.SetDefaultMesh(1039, "[Dungeon] The Thousand Maws of Toto-Rak v2", enforce)
		ml_mesh_mgr.SetDefaultMesh(166, "[Dungeon] Haukke Manor", enforce)
		ml_mesh_mgr.SetDefaultMesh(1040, "[Dungeon] Haukke Manor", enforce)
		ml_mesh_mgr.SetDefaultMesh(158, "[Dungeon] Brayflox", enforce)
		ml_mesh_mgr.SetDefaultMesh(1041, "[Dungeon] Brayflox's Longstop v2", enforce)
		ml_mesh_mgr.SetDefaultMesh(163, "[Dungeon] The Sunken Temple of Qarn", enforce)
		ml_mesh_mgr.SetDefaultMesh(170, "[Dungeon] Cutter's Cry", enforce)
		ml_mesh_mgr.SetDefaultMesh(168, "[Dungeon] Stone Vigil", enforce)
		ml_mesh_mgr.SetDefaultMesh(1042, "[Dungeon] Stone Vigil", enforce)
		ml_mesh_mgr.SetDefaultMesh(171, "[Dungeon] Dzemael Darkhold", enforce)
		ml_mesh_mgr.SetDefaultMesh(172, "[Dungeon] Aurum Vale", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Castrum Meridianum", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] The Praetorium", enforce)
		ml_mesh_mgr.SetDefaultMesh(159, "[Dungeon] Wanderers Palace", enforce)
		ml_mesh_mgr.SetDefaultMesh(167, "[Dungeon] Amdapor Keep", enforce)
		ml_mesh_mgr.SetDefaultMesh(160, "Pharos Sirius", enforce)
		ml_mesh_mgr.SetDefaultMesh(349, "[Dungeon] Copperbell (Hard)", enforce)
		ml_mesh_mgr.SetDefaultMesh(350, "[Dungeon] Haukke Manor (Hard)", enforce)
		--ml_mesh_mgr.SetDefaultMesh(363, "[Dungeon]LostCity", enforce)
		ml_mesh_mgr.SetDefaultMesh(360, "[Dungeon] Halatali (Hard)", enforce)
		ml_mesh_mgr.SetDefaultMesh(362, "[Dungeon] Brayflox (Hard)", enforce)
		--ml_mesh_mgr.SetDefaultMesh(361, "[Dungeon]HullbreakerIsle", enforce)
		--ml_mesh_mgr.SetDefaultMesh(373, "[Dungeon]TamTaraHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(365, "[Dungeon]StoneVigilHM", enforce)
		ml_mesh_mgr.SetDefaultMesh(371, "[Dungeon] Snowcloak", enforce)
		ml_mesh_mgr.SetDefaultMesh(387, "[Dungeon] Sastasha (Hard)", enforce)
		--ml_mesh_mgr.SetDefaultMesh(367, "[Dungeon]SunkenTempleHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(150, "[Dungeon]KeepersOfTheLake", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] The Wanderer's PalaceHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Amdapor KeepHM", enforce)
		ml_mesh_mgr.SetDefaultMesh(1043, "[Dungeon] Castrum Meridianum v2", enforce)
		ml_mesh_mgr.SetDefaultMesh(1044, "[Dungeon] The Praetorium v2", enforce)
		
		ml_mesh_mgr.SetDefaultMesh(1062, "[Dungeon] Snowcloak", enforce)
		ml_mesh_mgr.SetDefaultMesh(1063, "[Dungeon] The Keeper of the Lake", enforce)
		
		-- Dungeons HW
		ml_mesh_mgr.SetDefaultMesh(434, "[Dungeon] Dusk Vigil", enforce)
		ml_mesh_mgr.SetDefaultMesh(441, "[Dungeon] Sohm Al", enforce)
		ml_mesh_mgr.SetDefaultMesh(435, "[Dungeon] The Aery", enforce)
		ml_mesh_mgr.SetDefaultMesh(421, "[Dungeon] The Vault", enforce)
		ml_mesh_mgr.SetDefaultMesh(416, "[Dungeon] The Great Gubal Library", enforce)
		ml_mesh_mgr.SetDefaultMesh(1109, "[Dungeon] The Great Gubal Library v2", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] The Aetherochemical Research Facility", enforce)
		ml_mesh_mgr.SetDefaultMesh(1110, "[Dungeon] The Aetherochemical Research Facility v2", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Neverreap", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] The Fractal Continuum", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Saint Mocianne's Arboretum", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Pharos SiriusHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] The Antitower", enforce)
		ml_mesh_mgr.SetDefaultMesh(1111, "[Dungeon] The Antitower v2", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] The Lost City of AmdaporHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Sohr Khai", enforce)
		ml_mesh_mgr.SetDefaultMesh(1112, "[Dungeon] Sohr Khai v2", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Hullbreaker IsleHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Xelphatol", enforce)
		ml_mesh_mgr.SetDefaultMesh(1113, "[Dungeon] Xelphatol v2", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] The Great Gubal LibraryHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Baelsar's Wall", enforce)
		ml_mesh_mgr.SetDefaultMesh(1114, "[Dungeon] Baelsar's Wall v2", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Sohm AlHM", enforce)
		
		ml_mesh_mgr.SetDefaultMesh(1064, "[Dungeon] Sohm Al", enforce)
		ml_mesh_mgr.SetDefaultMesh(1065, "[Dungeon] The Aery", enforce)
		ml_mesh_mgr.SetDefaultMesh(1066, "[Dungeon] The Vault", enforce)
		
		
		
		-- Dungeons SB
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] The Sirensong Sea", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Shisui of the Violet Tides", enforce)
		ml_mesh_mgr.SetDefaultMesh(623, "[Dungeon] Bardam's Mettle", enforce)
		ml_mesh_mgr.SetDefaultMesh(660, "[Dungeon] Doma Castle", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Castrum Abania", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Ala Mhigo", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Kugane Castle", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] The Temple of the Fist", enforce)
		ml_mesh_mgr.SetDefaultMesh(1172, "[Dungeon] The Drowned City of Skalla v2", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Hells' Lid", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] The Fractal ContinuumHM", enforce)
		ml_mesh_mgr.SetDefaultMesh(768, "[Dungeon] The Swallow's Compass", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] The Burn", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] Saint Mocianne's ArboretumHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Dungeon] The Ghimlyt Dark", enforce)

		-- Dungeons SHB
		ml_mesh_mgr.SetDefaultMesh(837, "[Dungeon] Holminster", enforce)
		ml_mesh_mgr.SetDefaultMesh(821, "[Dungeon] Dohn Mheg", enforce)
		ml_mesh_mgr.SetDefaultMesh(823, "[Dungeon] The Qitana Ravel", enforce)
		ml_mesh_mgr.SetDefaultMesh(836, "[Dungeon] Malikah's Well", enforce)
		ml_mesh_mgr.SetDefaultMesh(822, "[Dungeon] Mt. Gulg", enforce)
		ml_mesh_mgr.SetDefaultMesh(838, "[Dungeon] Amaurot", enforce)
		ml_mesh_mgr.SetDefaultMesh(840, "[Dungeon] The Twinning", enforce)
		ml_mesh_mgr.SetDefaultMesh(841, "[Dungeon] Akadaemia Anyder", enforce)
		ml_mesh_mgr.SetDefaultMesh(884, "[Dungeon] The Grand Cosmos", enforce)
		ml_mesh_mgr.SetDefaultMesh(898, "[Dungeon] Anamnesis Anyder", enforce)
		ml_mesh_mgr.SetDefaultMesh(916, "[Dungeon] The Heroes' Gauntlet", enforce)
		ml_mesh_mgr.SetDefaultMesh(938, "[Dungeon] Paglth'an", enforce)
		
		-- Dungeons EW
		ml_mesh_mgr.SetDefaultMesh(952, "[Dungeon] The Tower of Zot", enforce)
		ml_mesh_mgr.SetDefaultMesh(969, "[Dungeon] The Tower of Babil", enforce)
		ml_mesh_mgr.SetDefaultMesh(970, "[Dungeon] Vanaspati", enforce)
		ml_mesh_mgr.SetDefaultMesh(974, "[Dungeon] Ktisis Hyperboreia", enforce)
		ml_mesh_mgr.SetDefaultMesh(978, "[Dungeon] The Aitiascope", enforce)
		ml_mesh_mgr.SetDefaultMesh(986, "[Dungeon] The Stigma Dreamscape", enforce)
		ml_mesh_mgr.SetDefaultMesh(976, "[Dungeon] Smileton", enforce)
		ml_mesh_mgr.SetDefaultMesh(1050, "[Dungeon] Alzadaal's Legacy", enforce)
		
		-- Trials ARR
		ml_mesh_mgr.SetDefaultMesh(202, "[Trial] The Bowl of Embers", enforce)
		ml_mesh_mgr.SetDefaultMesh(1045, "[Trial] The Bowl of Embers", enforce)
		ml_mesh_mgr.SetDefaultMesh(206, "[Trial] The Navel", enforce)
		ml_mesh_mgr.SetDefaultMesh(1046, "[Trial] The Navel", enforce)
		ml_mesh_mgr.SetDefaultMesh(295, "Bowl of Embers", enforce)
		ml_mesh_mgr.SetDefaultMesh(296, "The Navel - Full Platform", enforce)
		ml_mesh_mgr.SetDefaultMesh(297, "The Howling Eye", enforce)
		ml_mesh_mgr.SetDefaultMesh(1047, "The Howling Eye", enforce)
		ml_mesh_mgr.SetDefaultMesh(331, "The Howling Eye - Entrance", enforce)
		ml_mesh_mgr.SetDefaultMesh(359, "The Whorleater", enforce)
		ml_mesh_mgr.SetDefaultMesh(375, "The Striking Tree", enforce)
		ml_mesh_mgr.SetDefaultMesh(378, "Akh Afah Amphitheatre", enforce)
		--ml_mesh_mgr.SetDefaultMesh(208, "[Trial] Garuda", enforce)
		--ml_mesh_mgr.SetDefaultMesh(332, "[Trial] CapeWestwind", enforce)
		ml_mesh_mgr.SetDefaultMesh(426, "[Trial] Chrysalis", enforce)
		ml_mesh_mgr.SetDefaultMesh(1048, "[Trial] The Porta Decumana", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Steps of Faith", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] A Relic Reborn The Chimera", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] A Relic Reborn The Hydra", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] Battle on the Big Bridge", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Dragon's Neck", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] Battle in the Big Keep", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Bowl of EmbersHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Howling EyeHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The NavelHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(207, "[Trial] ThornmarchHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(281, "[Trial] The WhorleaterHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(374, "[Trial] The Striking TreeHM", enforce)
		ml_mesh_mgr.SetDefaultMesh(377, "Akh Afah Amphitheatre", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] Urth's Fount", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Minstrel's Ballad Ultima's Bane", enforce)
		
		-- Trials HW
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] Thok ast ThokHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Limitless BlueHM", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Singularity Reactor", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Final Steps of Faith", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] Containment Bay S1T7", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] Containment Bay P1T6", enforce)
		ml_mesh_mgr.SetDefaultMesh(637, "[Trial] Containment Bay Z1T9", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Limitless BlueEX", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] Thok ast ThokEX", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Minstrel's Ballad Thordan's Reign", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Minstrel's Ballad Nidhogg's Rage", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] Containment Bay S1T7EX", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] Containment Bay P1T6EX", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] Containment Bay Z1T9EX", enforce)
		
		-- Trials SB
		ml_mesh_mgr.SetDefaultMesh(674, "[Trial] The Pool of Tribute", enforce)
		ml_mesh_mgr.SetDefaultMesh(720, "[Trial] Emanation", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Royal Menagerie", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Jade Stoa", enforce)
		ml_mesh_mgr.SetDefaultMesh(779, "[Trial] Castrum Fluminis", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Great Hunt", enforce)
		ml_mesh_mgr.SetDefaultMesh(810, "[Trial] Hells' Kier", enforce)
		ml_mesh_mgr.SetDefaultMesh(811, "[Trial] Hells' Kier", enforce)
		ml_mesh_mgr.SetDefaultMesh(824, "[Trial] The Wreath of Snakes", enforce)
		ml_mesh_mgr.SetDefaultMesh(825, "[Trial] The Wreath of Snakes", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] Kugane Ohashi", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Pool of TributeEX", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Minstrel's Ballad Shinryu's Domain", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Jade StoaEX", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Minstrel's Ballad Tsukuyomi's Pain", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Great HuntEX", enforce)

		-- Trials SHB
		ml_mesh_mgr.SetDefaultMesh(845, "[Trial] The Dancing Plague", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Crown of the Immaculate", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Crown of the ImmaculateEX", enforce)
		ml_mesh_mgr.SetDefaultMesh(847, "[Trial] The Dying Gasp", enforce)
		ml_mesh_mgr.SetDefaultMesh(881, "[Trial] The Dying Gasp", enforce)
		ml_mesh_mgr.SetDefaultMesh(885, "[Trial] The Dying Gasp", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Trial] The Dancing PlagueEX", enforce)		
		ml_mesh_mgr.SetDefaultMesh(922, "[Trial] The Seat of Sacrifice", enforce)
		ml_mesh_mgr.SetDefaultMesh(950, "[Trial] G-Savior Deck", enforce)
		ml_mesh_mgr.SetDefaultMesh(951, "[Trial] G-Savior Deck", enforce)
		ml_mesh_mgr.SetDefaultMesh(991, "[Trial] G-Savior Deck", enforce)
		
		-- Trials EW
		ml_mesh_mgr.SetDefaultMesh(992, "[Trial] The Dark Inside", enforce)
		ml_mesh_mgr.SetDefaultMesh(997, "[Trial] The Final Day", enforce)
		ml_mesh_mgr.SetDefaultMesh(995, "[Trial] The Mothercrystal", enforce) --Hydaelyn
		ml_mesh_mgr.SetDefaultMesh(1095, "[Trial] Mount Ordeals", enforce) -- Rubicante Story
		ml_mesh_mgr.SetDefaultMesh(1096, "[Trial] Mount Ordeals", enforce) -- Rubicante EX
		ml_mesh_mgr.SetDefaultMesh(1140, "[Trial] The Voidcast Dais", enforce) -- Golbez Story
		ml_mesh_mgr.SetDefaultMesh(1141, "[Trial] The Voidcast Dais", enforce) -- Golbez EX
		ml_mesh_mgr.SetDefaultMesh(1168, "[Trial] The Abyssal Fracture", enforce) -- Zeromus Story
		ml_mesh_mgr.SetDefaultMesh(1169, "[Trial] The Abyssal Fracture", enforce) -- Zeromus EX		
		
		-- Raid Alliance ARR
		ml_mesh_mgr.SetDefaultMesh(174, "[Raid] Labyrinth of the Ancients", enforce)
		ml_mesh_mgr.SetDefaultMesh(372, "[Raid] Syrcus Tower", enforce)
		ml_mesh_mgr.SetDefaultMesh(151, "[Raid] The World of Darkness", enforce)
		
		-- Raid Alliance HW
		ml_mesh_mgr.SetDefaultMesh(508, "[Raid] The Void Ark", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] The Weeping City of Mhach", enforce)
		--ml_mesh_mgr.SetDefaultMesh(627, "[Raid] Dun Scaith", enforce)
		
		-- Raid Alliance SB
		ml_mesh_mgr.SetDefaultMesh(734, "[Raid] The Royal City of Rabanastre", enforce)
		ml_mesh_mgr.SetDefaultMesh(776, "[Raid] The Ridorana Lighthouse", enforce)
		ml_mesh_mgr.SetDefaultMesh(826, "[Raid] The Orbonne Monastery", enforce)
		
		-- Raid Alliance SHB
		ml_mesh_mgr.SetDefaultMesh(882, "[Raid] The Copied Factory", enforce)
		ml_mesh_mgr.SetDefaultMesh(896, "The Copied Factory2", true)
		ml_mesh_mgr.SetDefaultMesh(917, "[Raid] The Puppets' Bunker", enforce)
		ml_mesh_mgr.SetDefaultMesh(928, "The Puppets' Bunker2", true)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ???", enforce)
		
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] Castrum Lacus Litore", enforce)
		ml_mesh_mgr.SetDefaultMesh(936, "[Raid] Delubrum Reginae", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ???", enforce)
		
		-- Raids ARR
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] The Binding Coil of Bahamut", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] The Second Coil of Bahamut", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] The Second Coil of Bahamut Savage", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] The Final Coil of Bahamut", enforce)
		
		-- Raids HW
		ml_mesh_mgr.SetDefaultMesh(442, "[Raid] The Fist of the Father", enforce) -- a1
		ml_mesh_mgr.SetDefaultMesh(449, "[Raid] The Fist of the Father", enforce) -- a1s
		ml_mesh_mgr.SetDefaultMesh(443, "[Raid] The Cuff of the Father", enforce) -- a2
		ml_mesh_mgr.SetDefaultMesh(450, "[Raid] The Cuff of the Father", enforce) -- a2s
		ml_mesh_mgr.SetDefaultMesh(444, "[Raid] The Arm of the Father", enforce) -- a3
		ml_mesh_mgr.SetDefaultMesh(451, "[Raid] The Arm of the Father", enforce) -- a3s
		ml_mesh_mgr.SetDefaultMesh(445, "[Raid] The Burden of the Father", enforce) -- a4
		ml_mesh_mgr.SetDefaultMesh(452, "[Raid] The Burden of the Father", enforce) -- a4s
		ml_mesh_mgr.SetDefaultMesh(520, "[Raid] The Fist of the Son", enforce) -- a5
		ml_mesh_mgr.SetDefaultMesh(529, "[Raid] The Fist of the Son", enforce) -- a5s
		ml_mesh_mgr.SetDefaultMesh(521, "[Raid] The Cuff of the Son", enforce) -- a6
		ml_mesh_mgr.SetDefaultMesh(530, "[Raid] The Cuff of the Son", enforce) -- a6s
		ml_mesh_mgr.SetDefaultMesh(522, "[Raid] The Arm of the Son", enforce) -- a7
		ml_mesh_mgr.SetDefaultMesh(531, "[Raid] The Arm of the Son", enforce) -- a7s
		ml_mesh_mgr.SetDefaultMesh(523, "[Raid] The Burden of the Son", enforce) -- a8
		ml_mesh_mgr.SetDefaultMesh(532, "[Raid] The Burden of the Son", enforce) -- a8s
		ml_mesh_mgr.SetDefaultMesh(580, "[Raid] The Eyes of the Creator", enforce) -- a9
		ml_mesh_mgr.SetDefaultMesh(584, "[Raid] The Eyes of the Creator", enforce) -- a9s
		ml_mesh_mgr.SetDefaultMesh(581, "[Raid] The Breath of the Creator", enforce) -- a10
		ml_mesh_mgr.SetDefaultMesh(585, "[Raid] The Breath of the Creator", enforce) -- a10s
		ml_mesh_mgr.SetDefaultMesh(582, "[Raid] The Heart of the Creator", enforce) -- a11
		ml_mesh_mgr.SetDefaultMesh(586, "[Raid] The Heart of the Creator", enforce) -- a11s
		ml_mesh_mgr.SetDefaultMesh(583, "[Raid] The Soul of the Creator", enforce) -- a12
		ml_mesh_mgr.SetDefaultMesh(587, "[Raid] The Soul of the Creator", enforce) -- a12s

   		 -- Raids SB
		ml_mesh_mgr.SetDefaultMesh(690, "The Interdimensional Rift", enforce)
		ml_mesh_mgr.SetDefaultMesh(724, "The Interdimensional Rift", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] Omega Deltascape", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] Omega Deltascape Savag)", enforce)

		-- Raids SB Omega: released on July 4, 2017. Minimum item level of 295.
		ml_mesh_mgr.SetDefaultMesh(658, "The Interdimensional Rift2", enforce)
		ml_mesh_mgr.SetDefaultMesh(756, "The Interdimensional Rift2", enforce)
		ml_mesh_mgr.SetDefaultMesh(812, "The Interdimensional Rift2", enforce)
		ml_mesh_mgr.SetDefaultMesh(807, "The Interdimensional Rift2", enforce)
		ml_mesh_mgr.SetDefaultMesh(691, "[Raid] Deltascape V1.0", enforce) -- o1
		--ml_mesh_mgr.SetDefaultMesh(695, "[Raid] Deltascape V1.0", enforce) -- o1s
		ml_mesh_mgr.SetDefaultMesh(692, "[Raid] Deltascape V2.0", enforce) -- o2
		--ml_mesh_mgr.SetDefaultMesh(696, "[Raid] Deltascape V2.0", enforce) -- o2s
		ml_mesh_mgr.SetDefaultMesh(693, "[Raid] Deltascape V3.0", enforce) -- o3
		--ml_mesh_mgr.SetDefaultMesh(697, "[Raid] Deltascape V3.0", enforce) -- o3s
		--ml_mesh_mgr.SetDefaultMesh(694, "[Raid] Deltascape V4.0", enforce) -- o4
		--ml_mesh_mgr.SetDefaultMesh(698, "[Raid] Deltascape V4.0", enforce) -- o4s
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] The Unending Coil of Bahamut Ultimate", enforce)
		--ml_mesh_mgr.SetDefaultMesh(748, "[Raid] Sigmascape V1.0", enforce) -- o5
		--ml_mesh_mgr.SetDefaultMesh(752, "[Raid] Sigmascape V1.0", enforce) -- o5s
		--ml_mesh_mgr.SetDefaultMesh(749, "[Raid] Sigmascape V2.0", enforce) -- o6
		--ml_mesh_mgr.SetDefaultMesh(753, "[Raid] Sigmascape V2.0", enforce) -- o6s
		--ml_mesh_mgr.SetDefaultMesh(750, "[Raid] Sigmascape V3.0", enforce) -- o7
		--ml_mesh_mgr.SetDefaultMesh(754, "[Raid] Sigmascape V3.0", enforce) -- o7s
		--ml_mesh_mgr.SetDefaultMesh(751, "[Raid] Sigmascape V4.0", enforce) -- o8
		--ml_mesh_mgr.SetDefaultMesh(755, "[Raid] Sigmascape V4.0", enforce) -- o8s
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] The Minstrel's Ballad The Weapon's Refrain Ultimate", enforce)
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] Alphascape V1.0", enforce) -- o9
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] Alphascape V1.0", enforce) -- o9s
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] Alphascape V2.0", enforce) -- o10
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] Alphascape V2.0", enforce) -- o10s
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] Alphascape V3.0", enforce) -- o11
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] Alphascape V3.0", enforce) -- o11s
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] Alphascape V4.0", enforce) -- o12
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] Alphascape V4.0", enforce) -- o12s
		
		-- Raids SHB
		-- Eden's Gate
		ml_mesh_mgr.SetDefaultMesh(857, "The Core", enforce)
		ml_mesh_mgr.SetDefaultMesh(878, "The Empty", enforce)
		--ml_mesh_mgr.SetDefaultMesh(849, "[Raid] The Core", enforce)
		ml_mesh_mgr.SetDefaultMesh(850, "[Raid] The Halo_e2", enforce)
		ml_mesh_mgr.SetDefaultMesh(851, "[Raid] The Nereus Trench", enforce)
		--ml_mesh_mgr.SetDefaultMesh(852, "[Raid] Atlas Peak", enforce)
		--ml_mesh_mgr.SetDefaultMesh(853, "[Raid] The Core", enforce)
		--ml_mesh_mgr.SetDefaultMesh(854, "[Raid] The Halo_e2", enforce)
		--ml_mesh_mgr.SetDefaultMesh(855, "[Raid] The Nereus Trench", enforce)
		--ml_mesh_mgr.SetDefaultMesh(856, "[Raid] Atlas Peak", enforce)
		
		-- Eden's Verse
		ml_mesh_mgr.SetDefaultMesh(902, "[Raid] The Gandof Thunder Plains", enforce)
		ml_mesh_mgr.SetDefaultMesh(903, "[Raid] Ashfall", enforce)
		ml_mesh_mgr.SetDefaultMesh(904, "[Raid] The Halo_e7", enforce)
		ml_mesh_mgr.SetDefaultMesh(905, "[Raid] Great Glacier", enforce)
		ml_mesh_mgr.SetDefaultMesh(906, "[Raid] The Gandof Thunder Plains", enforce)		
		ml_mesh_mgr.SetDefaultMesh(907, "[Raid] Ashfall", enforce)		
		ml_mesh_mgr.SetDefaultMesh(908, "[Raid] The Halo_e7", enforce)		
		ml_mesh_mgr.SetDefaultMesh(909, "[Raid] Great Glacier", enforce)
		
		-- Eden's Promise
		ml_mesh_mgr.SetDefaultMesh(942, "[Raid] Sphere of Naught", enforce)
		ml_mesh_mgr.SetDefaultMesh(943, "[Raid] Laxan Loft", enforce)
		ml_mesh_mgr.SetDefaultMesh(944, "[Raid] Bygone Gaol", enforce)
		ml_mesh_mgr.SetDefaultMesh(945, "[Raid] The Garden of Nowhere", enforce)
		ml_mesh_mgr.SetDefaultMesh(946, "[Raid] Sphere of Naught", enforce)
		ml_mesh_mgr.SetDefaultMesh(947, "[Raid] Laxan Loft", enforce)
		ml_mesh_mgr.SetDefaultMesh(948, "[Raid] Bygone Gaol", enforce)
		ml_mesh_mgr.SetDefaultMesh(949, "[Raid] The Garden of Nowhere", enforce)
		
		-- Raids EW
		ml_mesh_mgr.SetDefaultMesh(1002, "[Raid] The Gates of Pandæmonium", enforce) -- p1
		ml_mesh_mgr.SetDefaultMesh(1003, "[Raid] The Gates of Pandæmonium", enforce) -- p1s
		ml_mesh_mgr.SetDefaultMesh(1004, "[Raid] The Stagnant Limbo", enforce) -- p2
		ml_mesh_mgr.SetDefaultMesh(1005, "[Raid] The Stagnant Limbo", enforce) -- p2s
		ml_mesh_mgr.SetDefaultMesh(1006, "[Raid] The Fervid Limbo", enforce) -- p3
		ml_mesh_mgr.SetDefaultMesh(1007, "[Raid] The Fervid Limbo", enforce) -- p3s
		ml_mesh_mgr.SetDefaultMesh(1008, "[Raid] The Sanguine Limbo", enforce) -- p4
		ml_mesh_mgr.SetDefaultMesh(1009, "[Raid] The Sanguine Limbo", enforce) -- p4s
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- Ultimate 1
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p5
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p5s
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p6
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p6s
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p7
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p7s
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p8
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p8s
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] , enforce) -- Ultimate 2
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p9
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p9s
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p10
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p10s
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p11
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p11s
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p12
		--ml_mesh_mgr.SetDefaultMesh(???, "[Raid] ", enforce) -- p12s
		
		-- Class Duties
		ml_mesh_mgr.SetDefaultMesh(228, "North Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(229, "South Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(230, "Central Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(231, "South Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(234, "East Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(235, "South Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(236, "South Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(237, "Duty_55", true)
		ml_mesh_mgr.SetDefaultMesh(238, "Old Gridania", true)
		ml_mesh_mgr.SetDefaultMesh(239, "Duty_439", true)
		ml_mesh_mgr.SetDefaultMesh(240, "North Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(251, "Ul'dah - Steps of Nald", true)
		ml_mesh_mgr.SetDefaultMesh(253, "Duty_288", true)
		ml_mesh_mgr.SetDefaultMesh(254, "Ul'dah - Steps of Nald", true)
		ml_mesh_mgr.SetDefaultMesh(255, "Western Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(256, "Eastern Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(257, "Eastern Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(258, "Duty_558", true)
		ml_mesh_mgr.SetDefaultMesh(259, "Duty_562", true)
		ml_mesh_mgr.SetDefaultMesh(260, "Duty_566", true)
		ml_mesh_mgr.SetDefaultMesh(261, "Southern Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(262, "Lower La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(263, "Western La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(264, "Lower La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(265, "Lower La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(266, "Eastern Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(267, "Western Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(268, "Eastern Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(269, "Western Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(270, "Duty_550", true)
		ml_mesh_mgr.SetDefaultMesh(285, "Middle La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(286, "ImOnABoat", true)
		ml_mesh_mgr.SetDefaultMesh(287, "Lower La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(288, "ImOnABoat", true)
		ml_mesh_mgr.SetDefaultMesh(289, "East Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(291, "South Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(310, "Eastern La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(311, "Eastern La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(312, "Southern Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(313, "Duty_1060", true)
		ml_mesh_mgr.SetDefaultMesh(314, "Central Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(315, "Mor Dhona", true)
		ml_mesh_mgr.SetDefaultMesh(316, "Coerthas Central Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(317, "South Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(318, "Southern Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(319, "Central Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(320, "Central Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(321, "North Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(322, "Coerthas Central Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(323, "Southern Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(324, "North Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(325, "Duty_1095", true)
		ml_mesh_mgr.SetDefaultMesh(326, "Duty_1096", true)
		ml_mesh_mgr.SetDefaultMesh(327, "Eastern La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(328, "Duty_1099", true)
		ml_mesh_mgr.SetDefaultMesh(329, "Duty_1102", true)
		ml_mesh_mgr.SetDefaultMesh(404, "Limsa Lominsa Lower Decks", true)
		ml_mesh_mgr.SetDefaultMesh(405, "Western La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(406, "Western La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(407, "ImOnABoat", true)
		ml_mesh_mgr.SetDefaultMesh(408, "Eastern La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(409, "Duty_155", true)
		ml_mesh_mgr.SetDefaultMesh(411, "Eastern La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(412, "Upper La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(413, "Duty_217", true)
		ml_mesh_mgr.SetDefaultMesh(414, "Duty_233", true)
		ml_mesh_mgr.SetDefaultMesh(415, "Lower La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(453, "Western La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(454, "Upper La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(464, "The Dravanian Forelands", true)
		ml_mesh_mgr.SetDefaultMesh(465, "Eastern Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(466, "Duty_1672", true)
		ml_mesh_mgr.SetDefaultMesh(467, "Coerthas Western Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(468, "Coerthas Central Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(469, "Coerthas Central Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(470, "Coerthas Western Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(471, "Eastern La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(472, "Coerthas Western Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(473, "South Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(474, "Duty_2016", true)
		ml_mesh_mgr.SetDefaultMesh(475, "Coerthas Central Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(476, "The Dravanian Hinterlands", true)
		ml_mesh_mgr.SetDefaultMesh(477, "Duty_1695", true)
		ml_mesh_mgr.SetDefaultMesh(480, "Mor Dhona", true)
		ml_mesh_mgr.SetDefaultMesh(481, "The Dravanian Forelands", true)
		ml_mesh_mgr.SetDefaultMesh(482, "The Dravanian Forelands", true)
		ml_mesh_mgr.SetDefaultMesh(483, "Northern Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(484, "Duty_1685", true)
		ml_mesh_mgr.SetDefaultMesh(486, "Outer La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(487, "Coerthas Central Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(488, "Coerthas Central Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(489, "Coerthas Western Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(490, "Duty_1688", true)
		ml_mesh_mgr.SetDefaultMesh(491, "Southern Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(492, "The Sea of Clouds", true)
		ml_mesh_mgr.SetDefaultMesh(493, "Duty_2037", true)
		ml_mesh_mgr.SetDefaultMesh(494, "Duty_2056", true)
		ml_mesh_mgr.SetDefaultMesh(495, "Lower La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(496, "Coerthas Central Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(497, "Coerthas Western Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(498, "Coerthas Western Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(499, "The Pillars", true)
		ml_mesh_mgr.SetDefaultMesh(500, "Duty_2058", true)
		ml_mesh_mgr.SetDefaultMesh(501, "Duty_2063", true)
		ml_mesh_mgr.SetDefaultMesh(502, "Duty_2104", true)
		ml_mesh_mgr.SetDefaultMesh(503, "Duty_2105", true)
		ml_mesh_mgr.SetDefaultMesh(640, "Duty_2416", true)
		ml_mesh_mgr.SetDefaultMesh(647, "Duty_2429", true)
		ml_mesh_mgr.SetDefaultMesh(648, "Duty_2430", true)
		ml_mesh_mgr.SetDefaultMesh(664, "Duty_2411", true)
		ml_mesh_mgr.SetDefaultMesh(666, "Ul'dah - Steps of Thal", true)
		ml_mesh_mgr.SetDefaultMesh(667, "Duty_2413", true) 
		ml_mesh_mgr.SetDefaultMesh(668, "Duty_2577", true )
		ml_mesh_mgr.SetDefaultMesh(669, "Duty_2588", true)
		ml_mesh_mgr.SetDefaultMesh(672, "Duty_2582", true)
		ml_mesh_mgr.SetDefaultMesh(673, "Duty_2592", true)
		ml_mesh_mgr.SetDefaultMesh(675, "Western La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(676, "Duty_2585", true)
		ml_mesh_mgr.SetDefaultMesh(678, "Duty_2418", true)
		ml_mesh_mgr.SetDefaultMesh(679, "The Royal Airship Landing", true)
		ml_mesh_mgr.SetDefaultMesh(699, "Duty_2907", true)
		ml_mesh_mgr.SetDefaultMesh(700, "Duty_2909", true)
		ml_mesh_mgr.SetDefaultMesh(701, "Duty_2627", true)
		ml_mesh_mgr.SetDefaultMesh(702, "Duty_2629", true)
		ml_mesh_mgr.SetDefaultMesh(703, "Duty_2892", true)
		ml_mesh_mgr.SetDefaultMesh(704, "Duty_2894", true)
		ml_mesh_mgr.SetDefaultMesh(705, "Ul'dah - Steps of Thal", true)
		ml_mesh_mgr.SetDefaultMesh(706, "Ul'dah - Steps of Thal", true)
		ml_mesh_mgr.SetDefaultMesh(707, "Duty_2587", true)
		ml_mesh_mgr.SetDefaultMesh(708, "Duty_2562", true)
		ml_mesh_mgr.SetDefaultMesh(709, "Duty_2565", true)
		ml_mesh_mgr.SetDefaultMesh(710, "Duty_2568", true)
		ml_mesh_mgr.SetDefaultMesh(711, "Duty_2570", true)
		ml_mesh_mgr.SetDefaultMesh(714, "Duty_2914", true)
		ml_mesh_mgr.SetDefaultMesh(715, "Duty_2917", true)
		ml_mesh_mgr.SetDefaultMesh(716, "Duty_2919", true) 
		ml_mesh_mgr.SetDefaultMesh(717, "Duty_2900", true)
		ml_mesh_mgr.SetDefaultMesh(718, "Duty_2904", true)
		ml_mesh_mgr.SetDefaultMesh(721, "Duty_2925", true)
		ml_mesh_mgr.SetDefaultMesh(722, "Duty_2927", true)
		ml_mesh_mgr.SetDefaultMesh(723, "Duty_2952", true)
		ml_mesh_mgr.SetDefaultMesh(726, "Duty_2950", true)
		ml_mesh_mgr.SetDefaultMesh(730, "Transparency", true)
		ml_mesh_mgr.SetDefaultMesh(746, "The Jade Stoa", true)
		ml_mesh_mgr.SetDefaultMesh(758, "The Jade Stoa", true)
		ml_mesh_mgr.SetDefaultMesh(810, "Hells' Kier", true)
		ml_mesh_mgr.SetDefaultMesh(811, "Hells' Kier", true)
		ml_mesh_mgr.SetDefaultMesh(865, "Duty_3262", true)
		ml_mesh_mgr.SetDefaultMesh(867, "Duty_3250", true)		
		ml_mesh_mgr.SetDefaultMesh(868, "Duty_3254", true)
		ml_mesh_mgr.SetDefaultMesh(869, "Duty_3248", true)
		ml_mesh_mgr.SetDefaultMesh(870, "Duty_3272", true)
		ml_mesh_mgr.SetDefaultMesh(871, "Duty_3278", true)
		ml_mesh_mgr.SetDefaultMesh(872, "Duty_3628", true)
		ml_mesh_mgr.SetDefaultMesh(873, "Duty_3247", true)
		ml_mesh_mgr.SetDefaultMesh(874, "Duty_3270", true)
		ml_mesh_mgr.SetDefaultMesh(875, "Duty_3276", true)
		ml_mesh_mgr.SetDefaultMesh(876, "Duty_3626", true)
		
		-- Latty SB
		ml_mesh_mgr.SetDefaultMesh(249, "Duty_414", true)
		ml_mesh_mgr.SetDefaultMesh(271, "Duty_551", true)
		ml_mesh_mgr.SetDefaultMesh(457, "Akh Afah Amphitheatre", true)
		ml_mesh_mgr.SetDefaultMesh(459, "Duty_1667", true)
		ml_mesh_mgr.SetDefaultMesh(460, "Duty_1601", true)
		ml_mesh_mgr.SetDefaultMesh(461, "The Sea of Clouds", true)
		ml_mesh_mgr.SetDefaultMesh(462, "Sacrificial Chamber", true)
		ml_mesh_mgr.SetDefaultMesh(513, "Duty_2163", true)
		ml_mesh_mgr.SetDefaultMesh(533, "Duty_2239", true)
		ml_mesh_mgr.SetDefaultMesh(592, "Bowl of Embers", true)
		ml_mesh_mgr.SetDefaultMesh(633, "Duty_2358", true)
		ml_mesh_mgr.SetDefaultMesh(634, "Duty_3027", true)
		ml_mesh_mgr.SetDefaultMesh(636, "Map636", true)
		ml_mesh_mgr.SetDefaultMesh(659, "Duty_2463", true)
		ml_mesh_mgr.SetDefaultMesh(665, "Duty_2474", true)
		ml_mesh_mgr.SetDefaultMesh(670, "Duty_2453", true)
		ml_mesh_mgr.SetDefaultMesh(671, "Duty_2528", true)
		ml_mesh_mgr.SetDefaultMesh(684, "Duty_2550", true)
		ml_mesh_mgr.SetDefaultMesh(685, "Duty_2498", true)
		ml_mesh_mgr.SetDefaultMesh(686, "Duty_2549", true)
		ml_mesh_mgr.SetDefaultMesh(688, "Duty_2515", true)
		ml_mesh_mgr.SetDefaultMesh(738, "Resonatorium", true)
		ml_mesh_mgr.SetDefaultMesh(757, "Duty_3024", true)
		ml_mesh_mgr.SetDefaultMesh(225, "Central Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(226, "Central Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(227, "Central Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(232, "South Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(233, "Central Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(248, "Central Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(252, "Middle La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(270, "Central Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(272, "Middle La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(273, "Western Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(274, "Ul'dah - Steps of Nald", true)
		ml_mesh_mgr.SetDefaultMesh(275, "Eastern Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(277, "East Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(278, "Western Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(279, "Lower La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(280, "Western La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(301, "Coerthas Central Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(302, "DutyKill-941", true)
		ml_mesh_mgr.SetDefaultMesh(303, "East Shroud", true)
		ml_mesh_mgr.SetDefaultMesh(304, "Coerthas Central Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(305, "Mor Dhona", true)
		ml_mesh_mgr.SetDefaultMesh(306, "Southern Thanalan", true)
		ml_mesh_mgr.SetDefaultMesh(307, "Lower La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(308, "Mor Dhona", true)
		ml_mesh_mgr.SetDefaultMesh(309, "Mor Dhona", true)
		ml_mesh_mgr.SetDefaultMesh(330, "Western La Noscea", true)
		ml_mesh_mgr.SetDefaultMesh(335, "Mor Dhona", true)
		ml_mesh_mgr.SetDefaultMesh(379, "Mor Dhona", true)
		ml_mesh_mgr.SetDefaultMesh(410, "Duty_88", true)
		ml_mesh_mgr.SetDefaultMesh(455, "The Sea of Clouds", true)
		ml_mesh_mgr.SetDefaultMesh(458, "Foundation", true)
		ml_mesh_mgr.SetDefaultMesh(479, "Coerthas Western Highlands", true)
		ml_mesh_mgr.SetDefaultMesh(485, "The Dravanian Hinterlands", true)
		ml_mesh_mgr.SetDefaultMesh(737, "Royal Palace", true)
		ml_mesh_mgr.SetDefaultMesh(769, "Duty_3076", true)
		
		-- Latty SHB
		ml_mesh_mgr.SetDefaultMesh(813, "Lakeland", enforce)
		ml_mesh_mgr.SetDefaultMesh(877, "Lakeland", true)
		ml_mesh_mgr.SetDefaultMesh(814, "Kholusia", enforce)
		ml_mesh_mgr.SetDefaultMesh(815, "Amh Araeng", enforce)
		ml_mesh_mgr.SetDefaultMesh(816, "Il Mheg", enforce)
		ml_mesh_mgr.SetDefaultMesh(817, "The Rak'tika Greatwood", enforce)
		ml_mesh_mgr.SetDefaultMesh(818, "The Tempest", enforce)
		
		ml_mesh_mgr.SetDefaultMesh(819, "The Crystarium", enforce)
		ml_mesh_mgr.SetDefaultMesh(820, "Eulmore", enforce)
		
		ml_mesh_mgr.SetDefaultMesh(842, "The Syrcus Trench", true)
		ml_mesh_mgr.SetDefaultMesh(844, "The Ocular", enforce)
		ml_mesh_mgr.SetDefaultMesh(880, "The Crown of the Immaculate", true)
		
		ml_mesh_mgr.SetDefaultMesh(861, "Duty_3305", true)
		ml_mesh_mgr.SetDefaultMesh(874, "Duty_3270", true)
		ml_mesh_mgr.SetDefaultMesh(859, "The Confessional of Toupasa the Elder", true)
		ml_mesh_mgr.SetDefaultMesh(862, "Duty_3606", true)
		ml_mesh_mgr.SetDefaultMesh(860, "Duty_3619", true)
		ml_mesh_mgr.SetDefaultMesh(863, "Duty_3631", true)
		ml_mesh_mgr.SetDefaultMesh(864, "Duty_3638", true)
		ml_mesh_mgr.SetDefaultMesh(890, "Lyhe Mheg", true) -- Lyhe Mheg (Pixies map)
		ml_mesh_mgr.SetDefaultMesh(891, "Lyhe Mheg (Rank Quest)", true) -- Lyhe Mheg (Pixies Rank Quest)
		ml_mesh_mgr.SetDefaultMesh(893, "Duty_3682", true) -- The Imperial Palace
		ml_mesh_mgr.SetDefaultMesh(918, "[Dungeon] Anamnesis Anyder", enforce)
		
		ml_mesh_mgr.SetDefaultMesh(900, "The Endeavor", true)
		ml_mesh_mgr.SetDefaultMesh(1163, "The Endeavor", true)
		ml_mesh_mgr.SetDefaultMesh(901, "The Diadem", true)
		ml_mesh_mgr.SetDefaultMesh(929, "The Diadem", true)
		ml_mesh_mgr.SetDefaultMesh(939, "The Diadem", true)
		
		-- Endwalker
		ml_mesh_mgr.SetDefaultMesh(956, "Labyrinthos", true)
		ml_mesh_mgr.SetDefaultMesh(957, "Thavnair", true)
		ml_mesh_mgr.SetDefaultMesh(958, "Garlemald", true)
		ml_mesh_mgr.SetDefaultMesh(959, "Mare Lamentorum", true)
		ml_mesh_mgr.SetDefaultMesh(960, "Ultima Thule", true)
		ml_mesh_mgr.SetDefaultMesh(961, "Elpis", true)
		ml_mesh_mgr.SetDefaultMesh(962, "Old Sharlayan", true)
		ml_mesh_mgr.SetDefaultMesh(963, "Radz-at-Han", true)
		ml_mesh_mgr.SetDefaultMesh(971, "Lemures Headquarters", true)
		ml_mesh_mgr.SetDefaultMesh(987, "Main Hall", true)
		ml_mesh_mgr.SetDefaultMesh(990, "Andron", true)
		ml_mesh_mgr.SetDefaultMesh(1001, "Strategy Room", true)
		ml_mesh_mgr.SetDefaultMesh(1015, "Duty_4107", true)
		ml_mesh_mgr.SetDefaultMesh(1016, "Duty_4119", true)
		ml_mesh_mgr.SetDefaultMesh(1017, "Duty_4125", true)
		ml_mesh_mgr.SetDefaultMesh(1018, "Duty_4131", true)
		ml_mesh_mgr.SetDefaultMesh(1019, "Duty_4113", true)
		ml_mesh_mgr.SetDefaultMesh(1020, "Duty_4074", true)
		ml_mesh_mgr.SetDefaultMesh(1021, "Duty_4078", true)
		ml_mesh_mgr.SetDefaultMesh(1022, "Duty_4068", true)
		ml_mesh_mgr.SetDefaultMesh(1023, "Duty_4072", true)
		ml_mesh_mgr.SetDefaultMesh(1028, "The Dark Inside", true)
		ml_mesh_mgr.SetDefaultMesh(1056, "Alzadaal's Legacy", true)
		ml_mesh_mgr.SetDefaultMesh(1057, "Restricted Archives", true)
		
		ml_mesh_mgr.SetDefaultMesh(1070, "[Dungeon] The Fell Court of Troia", true)
		ml_mesh_mgr.SetDefaultMesh(1073, "Elysion", true)
		ml_mesh_mgr.SetDefaultMesh(1091, "Duty_4594", true)
		ml_mesh_mgr.SetDefaultMesh(1077, "[Quest] Zero's Domain", true)
		ml_mesh_mgr.SetDefaultMesh(1089, "[Quest] The Fell Court of Troia", true)
		ml_mesh_mgr.SetDefaultMesh(1097, "[Dungeon] Lapis Manalis", true)
		ml_mesh_mgr.SetDefaultMesh(1115, "The Tower of Babil[Hildibrand]", true)
		ml_mesh_mgr.SetDefaultMesh(1126, "[Dungeon] The Aetherfont", true)
		ml_mesh_mgr.SetDefaultMesh(1164, "[Dungeon] The Lunar Subterrane", true)
		
		
		-- Latty EW
		ml_mesh_mgr.SetDefaultMesh(1014, "Duty_4432", true)
		ml_mesh_mgr.SetDefaultMesh(1013, "Duty_4464", true)
		ml_mesh_mgr.SetDefaultMesh(1011, "Duty_4394", true)
		ml_mesh_mgr.SetDefaultMesh(1052, "Duty_4522", true)
		ml_mesh_mgr.SetDefaultMesh(1053, "[Quest] The Porta Decumana", true)
		ml_mesh_mgr.SetDefaultMesh(1093, "[Quest] Stygian Insenescence Cells", true)
		ml_mesh_mgr.SetDefaultMesh(1120, "Duty_4673", true) -- Solo Duty 6.3
		ml_mesh_mgr.SetDefaultMesh(1119, "[Quest] Lapis Manalis", true) -- Story Area 6.3
		ml_mesh_mgr.SetDefaultMesh(1159, "The Voidcast Dais", true) -- Story Area 6.4
		ml_mesh_mgr.SetDefaultMesh(1160, "Senatus", true) -- Story Area 6.4
		ml_mesh_mgr.SetDefaultMesh(1161, "Estinien's Chambers", true) -- Story Area 6.4
		ml_mesh_mgr.SetDefaultMesh(1162, "The Red Moon", true) -- Story Area 6.4
		ml_mesh_mgr.SetDefaultMesh(1184, "[Dungeon] The Lunar Subterrane", true) -- CS area after dungeon
		
		-- Island Sanctuary
		ml_mesh_mgr.SetDefaultMesh(1055, "Unnamed Island", true)
		-- DT maps
		ml_mesh_mgr.SetDefaultMesh(1170, "Sunperch", true)
		ml_mesh_mgr.SetDefaultMesh(1171, "Earthen Sky Hideout", true)
		ml_mesh_mgr.SetDefaultMesh(1185, "Tuliyollal", true)
		ml_mesh_mgr.SetDefaultMesh(1186, "Solution Nine", true)
		ml_mesh_mgr.SetDefaultMesh(1187, "Urqopacha", true)
		ml_mesh_mgr.SetDefaultMesh(1188, "Kozama'uka", true)
		ml_mesh_mgr.SetDefaultMesh(1189, "Yak T'el", true)
		ml_mesh_mgr.SetDefaultMesh(1190, "Shaaloani", true)
		ml_mesh_mgr.SetDefaultMesh(1191, "Heritage Found", true)
		ml_mesh_mgr.SetDefaultMesh(1192, "Living Memory", true)
		ml_mesh_mgr.SetDefaultMesh(1205, "The For'ard Cabins", true)
		ml_mesh_mgr.SetDefaultMesh(1206, "Main Deck", true)
		ml_mesh_mgr.SetDefaultMesh(1207, "The Backroom", true)
		ml_mesh_mgr.SetDefaultMesh(1219, "Vanguard", true)
		ml_mesh_mgr.SetDefaultMesh(1220, "Summit of Everkeep", true)
		ml_mesh_mgr.SetDefaultMesh(1221, "Interphos", true)
		ml_mesh_mgr.SetDefaultMesh(1222, "Skydeep Cenote Inner Chamber", true)
		ml_mesh_mgr.SetDefaultMesh(1254, "[Quest] Yuweyawata", true)
		ml_mesh_mgr.SetDefaultMesh(1268, "Break Room", true)
		ml_mesh_mgr.SetDefaultMesh(1274, "[Quest] Throne Room", true)
		ml_mesh_mgr.SetDefaultMesh(1269, "Phantom Village", true) --	quest
		ml_mesh_mgr.SetDefaultMesh(1278, "Phantom Village", true)
		ml_mesh_mgr.SetDefaultMesh(1252, "South Horn",true)
				
	end
	
	-- General overrides.
	do
		-- setup marker manager callbacks and vars
		ml_marker_mgr.GetPosition = 	function () return Player.pos end
		ml_marker_mgr.GetLevel = 		function () return Player.level end
		ml_marker_mgr.DrawMarker =		ml_global_information.DrawMarker
		ml_node.ValidNeighbors = 		ml_global_information.NodeNeighbors
		ml_node.GetClosestNeighborPos = ml_global_information.NodeClosestNeighbor
		
		-- setup meshmanager
		if ( ml_mesh_mgr ) then
			--ml_mesh_mgr.parentWindow.Name = ml_global_information.MainWindow.Name
			ml_mesh_mgr.GetMapID = function () return Player.localmapid end
			ml_mesh_mgr.GetMapName = function (mapid)
				local mapid = IsNull(mapid,Player.localmapid)
				return GetMapName(mapid) 
			end
			ml_mesh_mgr.GetPlayerPos = function () return Player.pos end
			
			
			ml_global_information.meshTranslations = {}
			local defaultMaps = Settings.minionlib.DefaultMaps
			if (table.valid(defaultMaps)) then
				for mapid,meshname in pairs(defaultMaps) do
					ml_global_information.meshTranslations[meshname] = GetMapName(mapid)
				end
			end
			
			ml_mesh_mgr.GetString = function (meshname)
				local returnstring = meshname
				if (ml_global_information.meshTranslations[meshname]) then
					returnstring = returnstring.." - ["..ml_global_information.meshTranslations[meshname].."]"
				end
				return returnstring
			end
				
			ml_mesh_mgr.GetFileName = function (inputString) 
				if (ValidString(inputString)) then
					if (string.contains(inputString,'%s%-%s%[.+%]')) then
						inputString = string.gsub(inputString,'%s%-%s%[.+%]',"")
					end
				end
				return inputString 
			end
			
			ml_mesh_mgr.AllowedMapsLookup = function (mapid) 
				local placeid = AceLib.API.Map.GetPlaceID(mapid) or 0
				if (placeid ~= 0) then
					local allowedMaps = AceLib.API.Map.GetValidMaps(placeid)
					if (table.valid(allowedMaps)) then
						return allowedMaps
					end
				end
				return { [mapid] = mapid }
			end
			
			
			-- Say thank you to whoever did not put his mapid's into the setdefaultmesh stuff above..
			local IAmTooLazy = {
				[128] = "Limsa Lominsa Upper Decks",
				[129] = "Limsa Lominsa Lower Decks",
				[130] = "Ul'dah - Steps of Nald",
				[131] = "Ul'dah - Steps of Thal",
				[132] = "New Gridania",
				[133] = "Old Gridania",
				[134] = "Middle La Noscea",
				[135] = "Lower La Noscea",
				[136] = "Mist",
				[137] = "Eastern La Noscea",
				[138] = "Western La Noscea",
				[139] = "Upper La Noscea",
				[140] = "Western Thanalan",
				[141] = "Central Thanalan",
				[142] = "Halatali",
				[143] = "Steps of Faith",
				[144] = "The Gold Saucer",
				[145] = "Eastern Thanalan",
				[146] = "Southern Thanalan",
				[147] = "Northern Thanalan",
				[148] = "Central Shroud",
				[149] = "The Feasting Grounds",
				[150] = "The Keeper of the Lake",
				[151] = "The World of Darkness",
				[152] = "East Shroud",
				[153] = "South Shroud",
				[154] = "North Shroud",
				[155] = "Coerthas Central Highlands",
				[156] = "Mor Dhona",
				[157] = "Sastasha",
				[158] = "Brayflox's Longstop",
				[159] = "The Wanderer's Palace",
				[160] = "Pharos Sirius",
				[161] = "Copperbell Mines",
				[162] = "Halatali",
				[163] = "The Sunken Temple of Qarn",
				[164] = "The Tam-Tara Deepcroft",
				[166] = "Haukke Manor",
				[167] = "Amdapor Keep",
				[168] = "Stone Vigil",
				[169] = "The Thousand Maws of Toto-Rak",
				[170] = "Cutter's Cry",
				[171] = "Dzemael Darkhold",
				[172] = "Aurum Vale",
				[174] = "Labyrinth of the Ancients",
				[176] = "Mordion Gaol",
				[177] = "Mizzenmast Inn",
				[178] = "The Hourglass",
				[179] = "The Roost",
				[180] = "Outer La Noscea",
				[181] = "Limsa Lominsa",
				[182] = "Ul'dah - Steps of Nald",
				[183] = "New Gridania",
				[188] = "The Wanderer's Palace",
				[189] = "Amdapor Keep",
				[190] = "Central Shroud",
				[191] = "East Shroud",
				[192] = "South Shroud",
				[193] = "IC-06 Central Decks",
				[194] = "IC-06 Regeneration Grid",
				[195] = "IC-06 Main Bridge",
				[196] = "The Burning Heart",
				[198] = "Command Room",
				[202] = "Bowl of Embers",
				[204] = "Seat of the First Bow",
				[205] = "Lotus Stand",
				[206] = "The Navel",
				[207] = "Thornmarch",
				[208] = "The Howling Eye",
				[210] = "Heart of the Sworn",
				[212] = "The Waking Sands",
				[214] = "Middle La Noscea",
				[215] = "Western Thanalan",
				[216] = "Central Thanalan",
				[217] = "Castrum Meridianum",
				[219] = "Central Shroud",
				[220] = "South Shroud",
				[221] = "Upper La Noscea",
				[222] = "Lower La Noscea",
				[223] = "Coerthas Central Highlands",
				[224] = "The Praetorium",
				[225] = "Central Shroud",
				[226] = "Central Shroud",
				[227] = "Central Shroud",
				[228] = "North Shroud",
				[229] = "South Shroud",
				[230] = "Central Shroud",
				[231] = "South Shroud",
				[232] = "South Shroud",
				[233] = "Central Shroud",
				[234] = "East Shroud",
				[235] = "South Shroud",
				[236] = "South Shroud",
				[237] = "Central Shroud",
				[238] = "Old Gridania",
				[239] = "Central Shroud",
				[240] = "North Shroud",
				[241] = "Upper Aetheroacoustic Exploratory Site",
				[242] = "Lower Aetheroacoustic Exploratory Site",
				[243] = "The Ragnarok",
				[244] = "Ragnarok Drive Cylinder",
				[245] = "Ragnarok Central Core",
				[246] = "IC-04 Main Bridge",
				[247] = "Ragnarok Main Bridge",
				[248] = "Central Thanalan",
				[249] = "Lower La Noscea",
				[250] = "Wolves' Den Pier",
				[251] = "Ul'dah - Steps of Nald",
				[252] = "Middle La Noscea",
				[253] = "Central Thanalan",
				[254] = "Ul'dah - Steps of Nald",
				[255] = "Western Thanalan",
				[256] = "Eastern Thanalan",
				[257] = "Eastern Thanalan",
				[258] = "Central Thanalan",
				[259] = "Ul'dah - Steps of Nald",
				[260] = "Southern Thanalan",
				[261] = "Southern Thanalan",
				[262] = "Lower La Noscea",
				[263] = "Western La Noscea",
				[264] = "Lower La Noscea",
				[265] = "Lower La Noscea",
				[266] = "Eastern Thanalan",
				[267] = "Western Thanalan",
				[268] = "Eastern Thanalan",
				[269] = "Western Thanalan",
				[270] = "Central Thanalan",
				[271] = "Central Thanalan",
				[272] = "Middle La Noscea",
				[273] = "Western Thanalan",
				[274] = "Ul'dah - Steps of Nald",
				[275] = "Eastern Thanalan",
				[276] = "Hall of Summoning",
				[277] = "East Shroud",
				[278] = "Western Thanalan",
				[279] = "Lower La Noscea",
				[280] = "Western La Noscea",
				[281] = "The Whorleater",
				[282] = "Private Cottage - Mist",
				[283] = "Private House - Mist",
				[284] = "Private Mansion - Mist",
				[285] = "Middle La Noscea",
				[286] = "Rhotano Sea",
				[287] = "Lower La Noscea",
				[288] = "Rhotano Sea",
				[289] = "East Shroud",
				[290] = "East Shroud",
				[291] = "South Shroud",
				[292] = "Bowl of Embers",
				[293] = "The Navel",
				[294] = "The Howling Eye",
				[295] = "Bowl of Embers",
				[296] = "The Navel",
				[297] = "The Howling Eye",
				[298] = "Coerthas Central Highlands",
				[299] = "Mor Dhona",
				[300] = "Mor Dhona",
				[301] = "Coerthas Central Highlands",
				[302] = "Coerthas Central Highlands",
				[303] = "East Shroud",
				[304] = "Coerthas Central Highlands",
				[305] = "Mor Dhona",
				[306] = "Southern Thanalan",
				[307] = "Lower La Noscea",
				[308] = "Mor Dhona",
				[309] = "Mor Dhona",
				[310] = "Eastern La Noscea",
				[311] = "Eastern La Noscea",
				[312] = "Southern Thanalan",
				[313] = "Coerthas Central Highlands",
				[314] = "Central Thanalan",
				[315] = "Mor Dhona",
				[316] = "Coerthas Central Highlands",
				[317] = "South Shroud",
				[318] = "Southern Thanalan",
				[319] = "Central Shroud",
				[320] = "Central Shroud",
				[321] = "North Shroud",
				[322] = "Coerthas Central Highlands",
				[323] = "Southern Thanalan",
				[324] = "North Shroud",
				[325] = "Outer La Noscea",
				[326] = "Mor Dhona",
				[327] = "Eastern La Noscea",
				[328] = "Upper La Noscea",
				[329] = "The Wanderer's Palace",
				[330] = "Western La Noscea",
				[331] = "The Howling Eye",
				[332] = "Western Thanalan",
				[335] = "Mor Dhona",
				[338] = "Eorzean Subterrane",
				[339] = "Mist",
				[340] = "The Lavender Beds",
				[341] = "The Goblet",
				[342] = "Private Cottage - The Lavender Beds",
				[343] = "Private House - The Lavender Beds",
				[344] = "Private Mansion - The Lavender Beds",
				[345] = "Private Cottage - The Goblet",
				[346] = "Private House - The Goblet",
				[347] = "Private Mansion - The Goblet",
				[348] = "Porta Decumana",
				[349] = "Copperbell Mines",
				[350] = "Haukke Manor",
				[351] = "The Rising Stones",
				[353] = "Kugane Ohashi",
				[354] = "Containment Bay S1T7",
				[355] = "Dalamud's Shadow",
				[356] = "The Outer Coil",
				[357] = "Central Decks",
				[358] = "The Holocharts",
				[359] = "The Whorleater",
				[360] = "Halatali",
				[361] = "Hullbreaker Isle",
				[362] = "Brayflox's Longstop",
				[363] = "The Lost City of Amdapor",
				[364] = "Thornmarch",
				[365] = "Stone Vigil",
				[366] = "Griffin Crossing",
				[367] = "The Sunken Temple of Qarn",
				[368] = "The Weeping Saint",
				[369] = "Hall of the Bestiarii",
				[370] = "Main Bridge",
				[371] = "Snowcloak",
				[372] = "Syrcus Tower",
				[373] = "The Tam-Tara Deepcroft",
				[374] = "The Striking Tree",
				[375] = "The Striking Tree",
				[376] = "Carteneau Flats: Borderland Ruins",
				[377] = "Akh Afah Amphitheatre",
				[378] = "Akh Afah Amphitheatre",
				[379] = "Mor Dhona",
				[380] = "Dalamud's Shadow",
				[381] = "The Outer Coil",
				[382] = "Central Decks",
				[383] = "The Holocharts",
				[384] = "Private Chambers - Mist",
				[385] = "Private Chambers - The Lavender Beds",
				[386] = "Private Chambers - The Goblet",
				[387] = "Sastasha",
				[388] = "Chocobo Square",
				[389] = "Chocobo Square",
				[390] = "Chocobo Square",
				[391] = "Chocobo Square",
				[392] = "Sanctum of the Twelve",
				[393] = "Sanctum of the Twelve",
				[394] = "South Shroud",
				[395] = "Intercessory",
				[396] = "Amdapor Keep",
				[397] = "Coerthas Western Highlands",
				[398] = "The Dravanian Forelands",
				[399] = "The Dravanian Hinterlands",
				[400] = "The Churning Mists",
				[401] = "The Sea of Clouds",
				[402] = "Azys Lla",
				[403] = "Ala Mhigo",
				[404] = "Limsa Lominsa Lower Decks",
				[405] = "Western La Noscea",
				[406] = "Western La Noscea",
				[407] = "Rhotano Sea",
				[408] = "Eastern La Noscea",
				[409] = "Limsa Lominsa Upper Decks",
				[410] = "Northern Thanalan",
				[411] = "Eastern La Noscea",
				[412] = "Upper La Noscea",
				[413] = "Western La Noscea",
				[414] = "Eastern La Noscea",
				[415] = "Lower La Noscea",
				[416] = "The Great Gubal Library",
				[417] = "Chocobo Square",
				[418] = "Foundation",
				[419] = "The Pillars",
				[420] = "Neverreap",
				[421] = "The Vault",
				[423] = "Company Workshop - Mist",
				[424] = "Company Workshop - The Goblet",
				[425] = "Company Workshop - The Lavender Beds",
				[426] = "The Chrysalis",
				[427] = "Saint Endalim's Scholasticate",
				[428] = "Seat of the Lord Commander",
				[429] = "Cloud Nine",
				[430] = "The Fractal Continuum",
				[431] = "Seal Rock",
				[432] = "Thok ast Thok",
				[433] = "Fortemps Manor",
				[434] = "Dusk Vigil",
				[435] = "The Aery",
				[436] = "The Limitless Blue",
				[437] = "Singularity Reactor",
				[438] = "Aetherochemical Research Facility",
				[439] = "The Lightfeather Proving Grounds",
				[440] = "Ruling Chamber",
				[441] = "Sohm Al",
				[442] = "The Fist of the Father",
				[443] = "The Cuff of the Father",
				[444] = "The Arm of the Father",
				[445] = "The Burden of the Father",
				[446] = "Thok ast Thok",
				[447] = "The Limitless Blue",
				[448] = "Singularity Reactor",
				[449] = "The Fist of the Father",
				[450] = "The Cuff of the Father",
				[451] = "The Arm of the Father",
				[452] = "The Burden of the Father",
				[453] = "Western La Noscea",
				[454] = "Upper La Noscea",
				[455] = "The Sea of Clouds",
				[456] = "Ruling Chamber",
				[457] = "Akh Afah Amphitheatre",
				[458] = "Foundation",
				[459] = "Azys Lla",
				[460] = "Halatali",
				[461] = "The Sea of Clouds",
				[462] = "Sacrificial Chamber",
				[463] = "Matoya's Cave",
				[464] = "The Dravanian Forelands",
				[465] = "Eastern Thanalan",
				[466] = "Upper La Noscea",
				[467] = "Coerthas Western Highlands",
				[468] = "Coerthas Central Highlands",
				[469] = "Coerthas Central Highlands",
				[470] = "Coerthas Western Highlands",
				[471] = "Eastern La Noscea",
				[472] = "Coerthas Western Highlands",
				[473] = "South Shroud",
				[474] = "Limsa Lominsa Upper Decks",
				[475] = "Coerthas Central Highlands",
				[476] = "The Dravanian Hinterlands",
				[477] = "Coerthas Western Highlands",
				[478] = "Idyllshire",
				[479] = "Coerthas Western Highlands",
				[480] = "Mor Dhona",
				[481] = "The Dravanian Forelands",
				[482] = "The Dravanian Forelands",
				[483] = "Northern Thanalan",
				[484] = "Lower La Noscea",
				[485] = "The Dravanian Hinterlands",
				[486] = "Outer La Noscea",
				[487] = "Coerthas Central Highlands",
				[488] = "Coerthas Central Highlands",
				[489] = "Coerthas Western Highlands",
				[490] = "Hullbreaker Isle",
				[491] = "Southern Thanalan",
				[492] = "The Sea of Clouds",
				[493] = "Coerthas Western Highlands",
				[494] = "Eastern Thanalan",
				[495] = "Lower La Noscea",
				[496] = "Coerthas Central Highlands",
				[497] = "Coerthas Western Highlands",
				[498] = "Coerthas Western Highlands",
				[499] = "The Pillars",
				[500] = "Coerthas Central Highlands",
				[501] = "The Churning Mists",
				[502] = "Carteneau Flats: Borderland Ruins",
				[503] = "The Dravanian Hinterlands",
				[504] = "The Eighteenth Floor",
				[505] = "Alexander",
				[506] = "Chocobo Square",
				[507] = "Central Azys Lla",
				[508] = "Void Ark",
				[509] = "The Navel",
				[510] = "Pharos Sirius",
				[511] = "Saint Mocianne's Arboretum",
				[512] = "The Diadem",
				[513] = "The Vault",
				[514] = "The Diadem",
				[515] = "The Diadem",
				[516] = "The Antitower",
				[517] = "Containment Bay S1T7",
				[519] = "The Lost City of Amdapor",
				[520] = "The Fist of the Son",
				[521] = "The Cuff of the Son",
				[522] = "The Arm of the Son",
				[523] = "The Burden of the Son",
				[524] = "Containment Bay S1T7",
				[525] = "The Feasting Grounds",
				[527] = "The Feasting Grounds",
				[529] = "The Fist of the Son",
				[530] = "The Cuff of the Son",
				[531] = "The Arm of the Son",
				[532] = "The Burden of the Son",
				[533] = "Coerthas Central Highlands",
				[534] = "Twin Adder Barracks",
				[535] = "Flame Barracks",
				[536] = "Maelstrom Barracks",
				[537] = "The Fold",
				[538] = "The Fold",
				[539] = "The Fold",
				[540] = "The Fold",
				[541] = "The Fold",
				[542] = "The Fold",
				[543] = "The Fold",
				[544] = "The Fold",
				[545] = "The Fold",
				[546] = "The Fold",
				[547] = "The Fold",
				[548] = "The Fold",
				[549] = "The Fold",
				[550] = "The Fold",
				[551] = "The Fold",
				[552] = "Western La Noscea",
				[553] = "Alexander",
				[554] = "The Fields of Glory",
				[555] = "Sohr Khai",
				[556] = "The Weeping City of Mhach",
				[557] = "Hullbreaker Isle",
				[558] = "The Aquapolis",
				[559] = "Steps of Faith",
				[560] = "Aetherochemical Research Facility",
				[561] = "The Palace of the Dead",
				[562] = "The Palace of the Dead",
				[563] = "The Palace of the Dead",
				[564] = "The Palace of the Dead",
				[565] = "The Palace of the Dead",
				[566] = "Steps of Faith",
				[567] = "The Parrock",
				[568] = "Leofard's Chambers",
				[569] = "Steps of Faith",
				[570] = "The Palace of the Dead",
				[571] = "Haunted Manor",
				[572] = "Xelphatol",
				[573] = "Topmast Apartment Lobby",
				[574] = "Lily Hills Apartment Lobby",
				[575] = "Sultana's Breath Apartment Lobby",
				[576] = "Containment Bay P1T6",
				[577] = "Containment Bay P1T6",
				[578] = "The Great Gubal Library",
				[579] = "The Battlehall",
				[580] = "Eyes of the Creator",
				[581] = "Breath of the Creator",
				[582] = "Heart of the Creator",
				[583] = "Soul of the Creator",
				[584] = "Eyes of the Creator",
				[585] = "Breath of the Creator",
				[586] = "Heart of the Creator",
				[587] = "Soul of the Creator",
				[588] = "Heart of the Creator",
				[589] = "Chocobo Square",
				[590] = "Chocobo Square",
				[591] = "Chocobo Square",
				[592] = "Bowl of Embers",
				[593] = "The Palace of the Dead",
				[594] = "The Palace of the Dead",
				[595] = "The Palace of the Dead",
				[596] = "The Palace of the Dead",
				[597] = "The Palace of the Dead",
				[598] = "The Palace of the Dead",
				[599] = "The Palace of the Dead",
				[600] = "The Palace of the Dead",
				[601] = "The Palace of the Dead",
				[602] = "The Palace of the Dead",
				[603] = "The Palace of the Dead",
				[604] = "The Palace of the Dead",
				[605] = "The Palace of the Dead",
				[606] = "The Palace of the Dead",
				[607] = "The Palace of the Dead",
				[608] = "Topmast Apartment",
				[609] = "Lily Hills Apartment",
				[610] = "Sultana's Breath Apartment",
				[611] = "Frondale's Ward for Friendless Foundlings",
				[612] = "The Fringes",
				[613] = "The Ruby Sea",
				[614] = "Yanxia",
				[615] = "Baelsar's Wall",
				[616] = "Shisui of the Violet Tides",
				[617] = "Sohm Al",
				[619] = "The Feasting Grounds",
				[620] = "The Peaks",
				[621] = "The Lochs",
				[622] = "The Azim Steppe",
				[623] = "Bardam's Mettle",
				[624] = "The Diadem",
				[625] = "The Diadem",
				[626] = "The Sirensong Sea",
				[627] = "Dun Scaith",
				[628] = "Kugane",
				[629] = "Bokairo Inn",
				[630] = "The Diadem",
				[632] = "Lichenweed",
				[633] = "Carteneau Flats: Borderland Ruins",
				[634] = "Yanxia",
				[635] = "Rhalgr's Reach",
				[636] = "Omega Control",
				[637] = "Containment Bay Z1T9",
				[638] = "Containment Bay Z1T9",
				[639] = "Ruby Bazaar Offices",
				[640] = "The Fringes",
				[641] = "Shirogane",
				[644] = "Lichenweed",
				[646] = "Lichenweed",
				[647] = "The Fringes",
				[648] = "The Fringes",
				[649] = "Private Cottage - Shirogane",
				[650] = "Private House - Shirogane",
				[651] = "Private Mansion - Shirogane",
				[652] = "Private Chambers - Shirogane",
				[653] = "Company Workshop - Shirogane",
				[654] = "Kobai Goten Apartment Lobby",
				[655] = "Kobai Goten Apartment",
				[656] = "The Diadem",
				[657] = "The Ruby Sea",
				[658] = "The Interdimensional Rift",
				[659] = "Rhalgr's Reach",
				[660] = "Doma Castle",
				[661] = "Castrum Abania",
				[662] = "Kugane Castle",
				[663] = "The Temple of the Fist",
				[664] = "Kugane",
				[665] = "Kugane",
				[666] = "Ul'dah - Steps of Thal",
				[667] = "Kugane",
				[668] = "Eastern Thanalan",
				[669] = "Southern Thanalan",
				[670] = "The Fringes",
				[671] = "The Fringes",
				[672] = "Mor Dhona",
				[673] = "Sohm Al",
				[674] = "The Blessed Treasury",
				[675] = "Western La Noscea",
				[676] = "The Great Gubal Library",
				[677] = "The Blessed Treasury",
				[678] = "The Fringes",
				[679] = "The Royal Airship Landing",
				[680] = "The Misery",
				[681] = "The House of the Fierce",
				[682] = "The Doman Enclave",
				[683] = "The First Altar of Djanan Qhat",
				[684] = "The Lochs",
				[685] = "Yanxia",
				[686] = "The Lochs",
				[687] = "The Lochs",
				[688] = "The Azim Steppe",
				[689] = "Ala Mhigo",
				[690] = "The Interdimensional Rift",
				[691] = "Deltascape V1.0",
				[692] = "Deltascape V2.0",
				[693] = "Deltascape V3.0",
				[694] = "Deltascape V4.0",
				[695] = "Deltascape V1.0",
				[696] = "Deltascape V2.0",
				[697] = "Deltascape V3.0",
				[698] = "Deltascape V4.0",
				[699] = "Coerthas Central Highlands",
				[700] = "Foundation",
				[701] = "Seal Rock",
				[702] = "Aetherochemical Research Facility",
				[703] = "The Fringes",
				[704] = "Dalamud's Shadow",
				[705] = "Ul'dah - Steps of Thal",
				[706] = "Ul'dah - Steps of Thal",
				[707] = "The Weeping City of Mhach",
				[708] = "Rhotano Sea",
				[709] = "Coerthas Western Highlands",
				[710] = "Kugane",
				[711] = "The Ruby Sea",
				[712] = "The Lost Canals of Uznair",
				[713] = "The Azim Steppe",
				[714] = "Bardam's Mettle",
				[715] = "The Churning Mists",
				[716] = "The Peaks",
				[717] = "Wolves' Den Pier",
				[718] = "The Azim Steppe",
				[719] = "Emanation",
				[720] = "Emanation",
				[721] = "Amdapor Keep",
				[722] = "The Lost City of Amdapor",
				[723] = "The Azim Steppe",
				[724] = "The Interdimensional Rift",
				[725] = "The Lost Canals of Uznair",
				[726] = "The Ruby Sea",
				[727] = "The Royal Menagerie",
				[728] = "Mordion Gaol",
				[729] = "Astragalos",
				[730] = "Transparency",
				[731] = "The Drowned City of Skalla",
				[732] = "Eureka Anemos",
				[733] = "The Binding Coil of Bahamut",
				[734] = "The Royal City of Rabanastre",
				[735] = "The Prima Vista Tiring Room",
				[736] = "The Prima Vista Bridge",
				[737] = "Royal Palace",
				[738] = "The Resonatorium",
				[739] = "The Doman Enclave",
				[740] = "The Royal Menagerie",
				[741] = "Sanctum of the Twelve",
				[742] = "Hells' Lid",
				[743] = "The Fractal Continuum",
				[744] = "Kienkan",
				[745] = "Crystal Tower Training Grounds",
				[746] = "The Jade Stoa",
				[748] = "Sigmascape V1.0",
				[749] = "Sigmascape V2.0",
				[750] = "Sigmascape V3.0",
				[751] = "Sigmascape V4.0",
				[752] = "Sigmascape V1.0",
				[753] = "Sigmascape V2.0",
				[754] = "Sigmascape V3.0",
				[755] = "Sigmascape V4.0",
				[756] = "The Interdimensional Rift",
				[757] = "The Ruby Sea",
				[758] = "The Jade Stoa",
				[759] = "The Doman Enclave",
				[760] = "The Fringes",
				[761] = "The Great Hunt",
				[762] = "The Great Hunt",
				[763] = "Eureka Pagos",
				[764] = "Reisen Temple",
				[765] = "Crystal Tower Training Grounds",
				[766] = "Crystal Tower Training Grounds",
				[767] = "Crystal Tower Training Grounds",
				[768] = "The Swallow's Compass",
				[769] = "The Burn",
				[770] = "Heaven-on-High",
				[771] = "Heaven-on-High",
				[772] = "Heaven-on-High",
				[773] = "Heaven-on-High",
				[774] = "Heaven-on-High",
				[775] = "Heaven-on-High",
				[776] = "The Ridorana Lighthouse",
				[777] = "Ultimacy",
				[778] = "Castrum Fluminis",
				[779] = "Castrum Fluminis",
				[780] = "Heaven-on-High",
				[781] = "Reisen Temple Road",
				[782] = "Heaven-on-High",
				[783] = "Heaven-on-High",
				[784] = "Heaven-on-High",
				[785] = "Heaven-on-High",
				[786] = "Castrum Fluminis",
				[787] = "The Ridorana Cataract",
				[788] = "Saint Mocianne's Arboretum",
				[789] = "The Burn",
				[790] = "Ul'dah - Steps of Nald",
				[791] = "Hidden Gorge",
				[792] = "The Fall of Belah'dia",
				[793] = "[Dungeon] The Ghimlyt Dark",
				[794] = "The Shifting Altars of Uznair",
				[795] = "Eureka Pyros",
				[796] = "Blue Sky",
				[797] = "The Azim Steppe",
				[798] = "Psiscape V1.0",
				[799] = "Psiscape V2.0",
				[800] = "The Interdimensional Rift",
				[801] = "The Interdimensional Rift",
				[802] = "Psiscape V1.0",
				[803] = "Psiscape V2.0",
				[804] = "The Interdimensional Rift",
				[805] = "The Interdimensional Rift",
				[806] = "Kugane Ohashi",
				[807] = "The Interdimensional Rift",
				[808] = "The Interdimensional Rift",
				[809] = "Haunted Manor",
				[810] = "Hells' Kier",
				[811] = "Hells' Kier",
				[812] = "The Interdimensional Rift2",
				[824] = "The Wreath of Snakes",
				[825] = "The Wreath of Snakes",
				[826] = "The Orbonne Monastery",
				[827] = "Eureka Hydatos",
				[828] = "The Prima Vista Tiring Room",
				[829] = "Eorzean Alliance Headquarters",
				[830] = "The Ghimlyt Dark",
				[831] = "The Manderville Tables",
				[832] = "The Gold Saucer",
				[833] = "The Howling Eye",
				[834] = "The Howling Eye",
				[839] = "East Shroud",
				[843] = "The Pendants Personal Suite",
				[857] = "The Core",
				[878] = "The Empty",
				[890] = "Lyhe Mheg",
				[891] = "Lyhe Mheg (Rank Quest)",
				[896] = "The Copied Factory2",

				[895] = "Excavation Tunnels",
				[896] = "The Copied Factory2",
				[915] = "Gangos",
				[928] = "The Puppets' Bunker2",
				[979] = "Empyreum",
				[1073] = "Elysion"
			}
			ml_mesh_mgr.GetMapNameByMapID = function (mapid) 
				return IAmTooLazy[mapid]
			end
		end
	end
	
	-- Load class files here instead of the module.def
	local classFiles = FolderList(GetStartupPath().."\\LuaMods\\ffxivminion\\class_routines")
	if (classFiles) then
		for i,file in pairs(classFiles) do
			if ( string.ends(file,".lua") ) then
				--d("loading file ["..tostring(GetStartupPath().."\\LuaMods\\ffxivminion\\class_routines\\"..file).."]")
				local file, e = persistence.load(GetStartupPath().."\\LuaMods\\ffxivminion\\class_routines\\"..file)
				if (e) then
					d(e)
				end
			end
		end		
	end

	local ffxiv_mainmenu = {
		header = { id = "FFXIVMINION##MENU_HEADER", expanded = false, name = "FFXIVMinion", texture = GetStartupPath().."\\GUI\\UI_Textures\\ffxiv_shiny.png"},
		members = {	
			--{ id = "FFXIVMINION##MENU_MAINMENU", name = "Windows", sort = true },
			{ id = "FFXIVMINION##MENU_MAINMENU", name = "Main Task", onClick = function() ffxivminion.GUI.main.open = true ml_global_information.drawMode = 1 end, tooltip = "Open the Main Task window." },
			{ id = "FFXIVMINION##MENU_DEV", name = "Dev Tools", onClick = function() dev.GUI.open = not dev.GUI.open end, tooltip = "Open the Developer tools." },
		}
	}
	ml_gui.ui_mgr:AddComponent(ffxiv_mainmenu)
end

function IsControlOpen(strControl)
	local control = GetControlByName(strControl)
	  if (control) then
		if (control:IsOpen()) then
		  return true
		end
	  end
	return false
end

function GetControlData(strControl,strData)
	local control = GetControlByName(strControl)
	if (control) then
		local data = control:GetData()
		if (data) then
			if (strData == nil) then
				return data
			else
				if (table.valid(data)) then
					for dataid, dataval in pairs(data) do
						if (dataid == strData) then
							return dataval
						end
					end
				end
			end
		end
	end

	return nil
end

function GetControlStrings(strControl,numString)

	local control = GetControlByName(strControl)
	if (control) then
		local strings = control:GetStrings()
		if (table.valid(strings)) then
			if (numString == nil) then
				return strings
			else
				for stringid, stringval in pairs(strings) do
					if (stringid == numString) then
						return stringval
					end
				end
			end
		end
	end

	return nil
end

function GetControlRawData(strControl,index)

	local control = GetControlByName(strControl)
	if (control) then
		local datas = control:GetRawData()
		if (table.valid(datas)) then
			if (index == nil) then
				return datas
			else
				return datas[index]
			end
		end
	end

	return nil
end

function UseControlAction(strControl,strAction,actionArg,preDelay,postDelay)
	local preDelay = IsNull(preDelay,0)
	local postDelay = IsNull(postDelay,0)
	if (preDelay ~= 0) then
		ml_global_information.Queue(preDelay,function () UseControlAction(strControl,strAction,actionArg,0,postDelay) end)
	else
		local actionArg = IsNull(actionArg,0)
		local controls = MGetControls() -- testing?

		local control = GetControlByName(strControl)
		if (control and control:IsOpen()) then
			if (strAction == "Close") then
				control:Close()
			elseif (strAction == "Destroy") then
				control:Destroy()
			else
				local actions = control:GetActions()
				if (table.valid(actions)) then
					for aid, action in pairs(actions) do
						if (action == strAction) then
							if (postDelay ~= 0) then
								ml_global_information.Await(postDelay)
							end
							if (type(actionArg) == "table") then
								-- handle multiple args, min 2, max 3 args, using index 1-3
								if (table.size(actionArg) == 2) then
									control:Action(action,actionArg[1],actionArg[2])
								elseif (table.size(actionArg) == 3) then
									control:Action(action,actionArg[1],actionArg[2],actionArg[3])
								end
							else
								if (control:Action(action,actionArg)) then
									return true
								end
							end
							return false
						end
					end
				end
			end
		end

	end
	return false
end

function OpenControl(strControl)
	local control = GetControlByName(strControl)
	if (control and type(control) == "number") then
		CreateControl(control)
	elseif (control and type(control) == "table") then
		control:Open()
	end
end

function GetControl(strControl,allControls)
	local allControls = IsNull(allControls,false)
	
	local control = GetControlByName(strControl)
	if (control) then
		return control
	end
	
	if (allControls) then
		local controls = GetControlList()
		if (table.valid(controls)) then
			for id, e in pairs(controls) do
				if (e == strControl) then
					return id
				end
			end
		end
	end
	
	return nil
end

function GetPublicProfiles(path,ext)
	local profiles, profilesDisplay = { [GetString("none")] = {} }, { GetString("none") }
	
	local profileList = FolderList(path,ext)
	if (table.valid(profileList)) then
		for i,profile in pairs(profileList) do	
			local profileData, e = persistence.load(path..profile)
			if (table.valid(profileData)) then
				local profileName = string.gsub(profile,"%..+$","")
				if (IsNull(profileName,"") ~= "") then
					if (table.valid(profileData.names) and profileData.names[gCurrentLanguage]) then
						local translatedName = profileData.names[gCurrentLanguage]
						if (profiles[translatedName] == nil) then
							profiles[translatedName] = profileData
							table.insert(profilesDisplay,translatedName)
						end
					else
						if (profiles[profileName] == nil) then
							profiles[profileName] = profileData
							table.insert(profilesDisplay,profileName)
						end
					end
				end
			elseif (e) then
				d(e)
			end
		end		
	end
	
	return profiles,profilesDisplay
end

function ml_global_information.LoadBehaviorFiles()
	-- Load all our local "bot/addon" BTree files
	local path = GetStartupPath()  .. "\\LuaMods\\ffxivminion\\Behavior"
	if (not FolderExists(path)) then
		FolderCreate(path)
	end
	BehaviorManager:LoadBehaviorFromFolder(path)
 end
RegisterEventHandler("RefreshBehaviorFiles", ml_global_information.LoadBehaviorFiles,"ml_global_information.LoadBehaviorFiles")

function ml_global_information.CheckPartyInviteYesno(txt)
    if table.valid(txt) then
        for _, b in pairs(txt) do
            if string.find(b, "'s party?") then
                if string.find(b, "Join") then
                    return true
                end
            elseif string.find(b, "Rejoindre l'équipe de") then
                return true
            elseif string.find(b, "Der Gruppe von") then
                return true
            elseif string.find(b, "のパーティに参加します。よろしいですか？") then
                return true
            elseif string.find(b, "님의 파티에 참가하시겠습니까?") then
                return true
            elseif string.find(b, "确定要加入") and string.find(b, "的小队吗？") then
                return true
            end
        end
    end
end
function ml_global_information.CheckGroupTeleportYesno(txt)
    if table.valid(txt) then
        for _, b in pairs(txt) do
            if string.find(b, "Accept Teleport to ") then
                return true
            elseif string.find(b, "Voulez-vous vous téléporter vers la destination") then
                return true
            elseif string.find(b, "teleportieren lassen?") then
                return true
            elseif string.find(b, "へのテレポ勧誘を受けますか？") then
                return true
            elseif string.find(b, "이동하는 텔레포 초대를 수락하시겠습니까?") then
                return true
            elseif string.find(b, "的传送邀请吗？") then
                return true
            end
        end
    end
end
function PressYesNo(answer)
    local answer = IsNull(answer, true)
    if (answer == true) then
        answer = "Yes"
    elseif (answer == false) then
        answer = "No"
    end

    if (IsControlOpen("SelectYesno")) then
        if (IsControlOpen("_NotificationParty")) and gDeclinePartyInvites then
            return UseControlAction("SelectYesno", "No")
        else
            local txt = GetControlStrings("SelectYesno")
            if not table.valid(txt) and (gDeclinePartyInvites or gDeclinePartyTeleport) then
                d("text info invalid ? (SelectYesno), decline party invite " .. tostring(gDeclinePartyInvites) .. '  decline group teleport ' .. tostring(gDeclinePartyTeleport))
                return false
            end
            if ml_global_information.CheckPartyInviteYesno(txt) and gDeclinePartyInvites then
                d('decline party invite.')
                return UseControlAction("SelectYesno", "No")
            end
            if ml_global_information.CheckGroupTeleportYesno(txt) and gDeclinePartyTeleport then
                d('decline group teleport.')
                return UseControlAction("SelectYesno", "No")
            end
            return UseControlAction("SelectYesno", answer)
        end
    end
    return false
end

function DrawFateListUI(self)
	local vars = self.GUI.vars
	
	ml_gui.DrawTabs(self.GUI.main_tabs)
	
	-- dbk: Edit
	if (self.GUI.main_tabs.tabs[1].isselected) then
		GUI:Columns(4, "##listdetail-view", true)
		GUI:SetColumnOffset(1,60); GUI:SetColumnOffset(2,140); GUI:SetColumnOffset(3,210); GUI:SetColumnOffset(4,280); GUI:SetColumnOffset(5,350); GUI:SetColumnOffset(6,450);
		GUI:Text(GetString("Map")); GUI:NextColumn();
		GUI:Text(GetString("Name")); GUI:NextColumn();
		GUI:Text(GetString("ID")); GUI:NextColumn(); GUI:NextColumn();
		GUI:Separator();
		
		local entries = self.entries
		if (table.valid(entries)) then
			local myMap = Player.localmapid
			for i, entry in pairs(entries) do
				if (entry.mapid == myMap) then
					GUI:Text(entry.mapid); GUI:NextColumn();
					GUI:Text(entry.name); GUI:NextColumn();
					GUI:Text(entry.id); GUI:NextColumn();
					if (GUI:Button(GetString("Delete").."##"..tostring(i))) then
						self:DeleteEntry(i); 
					end
					GUI:NextColumn();
				end
			end
		end
		
		GUI:Columns(1)		
	end
			
	-- dbk: Add
	if (self.GUI.main_tabs.tabs[2].isselected) then
		
		local fateList = {}
		local fateDisplayList = {}
		
		local flist = MFateList()
		if (table.valid(flist)) then
			for id, e in pairs(flist) do
				if (self:Find(e.id,"id") == nil) then
					table.insert(fateDisplayList,e.name)
					table.insert(fateList,{ name = e.name, mapid = Player.localmapid, id = e.id })
				end
			end
		end			
		
		if (table.valid(fateList)) then
			if (FateListComboIndex == nil) then
				FateListComboIndex = 1
				FateListCombo = GetKeyByValue(FateListComboIndex,fateDisplayList)
			end
			
			GUI_Combo("Fates","FateListComboIndex","FateListCombo",fateDisplayList)
			
			GUI:Spacing(); GUI:Spacing();
			
			local fate = fateList[FateListComboIndex]
			GUI:Text("ID :"); GUI:SameLine(75); GUI:Text(fate.id)
			GUI:Text("Name :"); GUI:SameLine(75); GUI:Text(fate.name)
			GUI:Text("Map ID :"); GUI:SameLine(75); GUI:Text(fate.mapid)
			
			GUI:Spacing(); GUI:Spacing();

			if (GUI:Button(GetString("Add Entry"),200,24)) then
				local details = { name = fate.name, mapid = fate.mapid, id = fate.id }
				self:AddEntry(details)
				vars.temptext = "Added ["..tostring(fate.id).." : "..tostring(fate.name).."] to the list."
				vars.temptimer = Now() + 2000
			end

			if (vars.temptimer ~= 0) then
				if (Now() < vars.temptimer) then
					GUI:Text(vars.temptext)
				end
			end
		else
			GUI:Text("No active fates.")
		end
	end
end

function pd(strOut)
	if (strOut) then
		pcall(d,strOut)
	end
end

RegisterEventHandler("Module.Initalize",ml_global_information.Init, "ml_global_information.Init")

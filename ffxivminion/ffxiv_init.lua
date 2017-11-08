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

function ml_global_information.Init()
	-- Update default meshes.
	do
		BehaviorManager:ToggleMenu()
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
		ml_mesh_mgr.SetDefaultMesh(186, "Wolves Den")
		ml_mesh_mgr.SetDefaultMesh(250, "Wolves Den Pier")
		
		--ml_mesh_mgr.SetDefaultMesh(431, "Seal Rock")
		
		ml_mesh_mgr.SetDefaultMesh(130, "Ul dah - Steps of Nald")
		ml_mesh_mgr.SetDefaultMesh(182, "Ul dah - Steps of Nald")
		ml_mesh_mgr.SetDefaultMesh(131, "Ul dah - Steps of Thal")
		ml_mesh_mgr.SetDefaultMesh(128, "Limsa (Upper)")
		ml_mesh_mgr.SetDefaultMesh(181, "Limsa (Lower)")
		ml_mesh_mgr.SetDefaultMesh(129, "Limsa (Lower)")
		ml_mesh_mgr.SetDefaultMesh(132, "New Gridania")
		ml_mesh_mgr.SetDefaultMesh(183, "New Gridania")
		ml_mesh_mgr.SetDefaultMesh(133, "Old Gridania")
		ml_mesh_mgr.SetDefaultMesh(376, "Frontlines")
		ml_mesh_mgr.SetDefaultMesh(422, "Frontlines - Slaughter")
		ml_mesh_mgr.SetDefaultMesh(212, "Waking Sands")
		ml_mesh_mgr.SetDefaultMesh(179, "Gridania - Inn")
		ml_mesh_mgr.SetDefaultMesh(178, "Ul dah - Inn")
		ml_mesh_mgr.SetDefaultMesh(177, "Limsa Lominsa - Inn")
		
		ml_mesh_mgr.SetDefaultMesh(210, "Ul dah - Heart of the Sworn")
		ml_mesh_mgr.SetDefaultMesh(205, "Lotus Stand")
		ml_mesh_mgr.SetDefaultMesh(198, "Limsa Lominsa - Command")
		ml_mesh_mgr.SetDefaultMesh(204, "Gridania - First Bow")
		
		ml_mesh_mgr.SetDefaultMesh(144, "Gold Saucer")
		ml_mesh_mgr.SetDefaultMesh(388, "Gold Saucer - Chocobo Square")
		
		ml_mesh_mgr.SetDefaultMesh(331, "Garuda_Entrance")
		ml_mesh_mgr.SetDefaultMesh(351, "Rising Stones")
		ml_mesh_mgr.SetDefaultMesh(395, "Intercessory")
		ml_mesh_mgr.SetDefaultMesh(397, "Coerthas Western Highlands")
		ml_mesh_mgr.SetDefaultMesh(398, "The Dravanian Forelands")
		ml_mesh_mgr.SetDefaultMesh(399, "The Dravanian Hinterlands")
		ml_mesh_mgr.SetDefaultMesh(400, "The Churning Mists")
		ml_mesh_mgr.SetDefaultMesh(401, "Sea of Clouds")
		ml_mesh_mgr.SetDefaultMesh(402, "Azys Lla")
		ml_mesh_mgr.SetDefaultMesh(418, "Ishgard - Foundation")
		ml_mesh_mgr.SetDefaultMesh(419, "Ishgard - The Pillars")
		ml_mesh_mgr.SetDefaultMesh(427, "Ishgard - Scholasticate")
		ml_mesh_mgr.SetDefaultMesh(439, "Ishgard - Chocobo Proving Grounds")
		ml_mesh_mgr.SetDefaultMesh(433, "Ishgard - Fortempts Manor")
		ml_mesh_mgr.SetDefaultMesh(456, "Ishgard - Ruling Chamber")
		ml_mesh_mgr.SetDefaultMesh(463, "Matoyas Cave")
		ml_mesh_mgr.SetDefaultMesh(478, "Idyllshire") 
		
		ml_mesh_mgr.SetDefaultMesh(554, "[PVP] - Fields of Glory (Shatter)")
		
		ml_mesh_mgr.SetDefaultMesh(612, "The Fringes")
		ml_mesh_mgr.SetDefaultMesh(613, "The Ruby Sea")
		ml_mesh_mgr.SetDefaultMesh(614, "Yanxia")
		ml_mesh_mgr.SetDefaultMesh(620, "The Peaks")
		ml_mesh_mgr.SetDefaultMesh(621, "The Lochs")
		ml_mesh_mgr.SetDefaultMesh(622, "The Azim Steppe")
		ml_mesh_mgr.SetDefaultMesh(628, "Kugane")		
		ml_mesh_mgr.SetDefaultMesh(635, "Rhalgrs Reach")	
		ml_mesh_mgr.SetDefaultMesh(639, "Ruby Bazaar Offices")		
		ml_mesh_mgr.SetDefaultMesh(680, "ImOnABoatAgain")
		ml_mesh_mgr.SetDefaultMesh(681, "The House of the Fierce")
		ml_mesh_mgr.SetDefaultMesh(683, "First Alter of Djanan")
		
		
		-- Dungeons
		ml_mesh_mgr.SetDefaultMesh(435, "[Dungeon]Aery")
		ml_mesh_mgr.SetDefaultMesh(167, "[Dungeon]AmdaporKeep")
		ml_mesh_mgr.SetDefaultMesh(172, "[Dungeon]AurumVale")
		ml_mesh_mgr.SetDefaultMesh(158, "[Dungeon]Brayflox")
		ml_mesh_mgr.SetDefaultMesh(362, "[Dungeon]BrayfloxHM")
		ml_mesh_mgr.SetDefaultMesh(161, "[Dungeon]Copperbell")
		ml_mesh_mgr.SetDefaultMesh(349, "[Dungeon]CopperbellHM")
		ml_mesh_mgr.SetDefaultMesh(170, "[Dungeon]CuttersCry")
		ml_mesh_mgr.SetDefaultMesh(434, "[Dungeon]DuskVigil")
		ml_mesh_mgr.SetDefaultMesh(171, "[Dungeon]DzemaelDarkhold")
		ml_mesh_mgr.SetDefaultMesh(162, "[Dungeon]Halatali")
		ml_mesh_mgr.SetDefaultMesh(360, "[Dungeon]HalataliHM")
		ml_mesh_mgr.SetDefaultMesh(166, "[Dungeon]Haukke")
		ml_mesh_mgr.SetDefaultMesh(350, "[Dungeon]HaukkeHM")
		ml_mesh_mgr.SetDefaultMesh(361, "[Dungeon]HullbreakerIsle")
		ml_mesh_mgr.SetDefaultMesh(150, "[Dungeon]KeepersOfTheLake")
		ml_mesh_mgr.SetDefaultMesh(363, "[Dungeon]LostCity")
		ml_mesh_mgr.SetDefaultMesh(160, "[Dungeon]PharosSirius")
		ml_mesh_mgr.SetDefaultMesh(157, "[Dungeon]Sastasha")
		ml_mesh_mgr.SetDefaultMesh(387, "[Dungeon]SastashaHM")
		ml_mesh_mgr.SetDefaultMesh(371, "[Dungeon]Snowcloak")
		ml_mesh_mgr.SetDefaultMesh(441, "[Dungeon]SohmAl")
		ml_mesh_mgr.SetDefaultMesh(168, "[Dungeon]StoneVigil")
		ml_mesh_mgr.SetDefaultMesh(365, "[Dungeon]StoneVigilHM")
		ml_mesh_mgr.SetDefaultMesh(163, "[Dungeon]SunkenTemple")
		ml_mesh_mgr.SetDefaultMesh(367, "[Dungeon]SunkenTempleHM")
		ml_mesh_mgr.SetDefaultMesh(164, "[Dungeon]TamTara")
		ml_mesh_mgr.SetDefaultMesh(373, "[Dungeon]TamTaraHM")
		ml_mesh_mgr.SetDefaultMesh(169, "[Dungeon]TotoRak")
		ml_mesh_mgr.SetDefaultMesh(421, "[Dungeon]Vault")
		ml_mesh_mgr.SetDefaultMesh(159, "[Dungeon]WanderersPalace")
		ml_mesh_mgr.SetDefaultMesh(332, "[Trial]CapeWestwind")
		ml_mesh_mgr.SetDefaultMesh(426, "[Trial]Chrysalis")
		ml_mesh_mgr.SetDefaultMesh(208, "[Trial]Garuda")
		ml_mesh_mgr.SetDefaultMesh(202, "[Trial]Ifrit")
		ml_mesh_mgr.SetDefaultMesh(281, "[Trial]Leviathan")
		ml_mesh_mgr.SetDefaultMesh(207, "[Trial]MoogleMog")
		ml_mesh_mgr.SetDefaultMesh(374, "[Trial]Ramuh")
		ml_mesh_mgr.SetDefaultMesh(377, "[Trial]Shiva")
		ml_mesh_mgr.SetDefaultMesh(206, "[Trial]Titan")		
		
		-- Class Duties
		ml_mesh_mgr.SetDefaultMesh(228, "North Shroud")
		ml_mesh_mgr.SetDefaultMesh(229, "South Shroud")	
		ml_mesh_mgr.SetDefaultMesh(230, "Central Shroud")
		ml_mesh_mgr.SetDefaultMesh(231, "South Shroud")	
		ml_mesh_mgr.SetDefaultMesh(234, "East Shroud")
		ml_mesh_mgr.SetDefaultMesh(235, "South Shroud")	
		ml_mesh_mgr.SetDefaultMesh(236, "South Shroud")	
		ml_mesh_mgr.SetDefaultMesh(237, "Duty_55")
		ml_mesh_mgr.SetDefaultMesh(238, "Old Gridania")
		ml_mesh_mgr.SetDefaultMesh(239, "Duty_439")
		ml_mesh_mgr.SetDefaultMesh(240, "North Shroud")
		ml_mesh_mgr.SetDefaultMesh(251, "Ul dah - Steps of Nald")
		ml_mesh_mgr.SetDefaultMesh(253, "Duty_288")
		ml_mesh_mgr.SetDefaultMesh(254, "Ul dah - Steps of Nald")
		ml_mesh_mgr.SetDefaultMesh(255, "Western Thanalan")
		ml_mesh_mgr.SetDefaultMesh(256, "Eastern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(257, "Eastern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(258, "Central Thanalan")
		ml_mesh_mgr.SetDefaultMesh(259, "Ul dah - Steps of Nald")
		ml_mesh_mgr.SetDefaultMesh(260, "Southern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(261, "Southern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(262, "Lower La Noscea")
		ml_mesh_mgr.SetDefaultMesh(263, "Western La Noscea")
		ml_mesh_mgr.SetDefaultMesh(264, "Lower La Noscea")
		ml_mesh_mgr.SetDefaultMesh(265, "Lower La Noscea")
		ml_mesh_mgr.SetDefaultMesh(266, "Eastern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(267, "Western Thanalan")
		ml_mesh_mgr.SetDefaultMesh(268, "Eastern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(269, "Western Thanalan")
		ml_mesh_mgr.SetDefaultMesh(285, "Middle La Noscea")
		ml_mesh_mgr.SetDefaultMesh(286, "ImOnABoat")
		ml_mesh_mgr.SetDefaultMesh(287, "Lower La Noscea")
		ml_mesh_mgr.SetDefaultMesh(288, "ImOnABoat")
		ml_mesh_mgr.SetDefaultMesh(289, "East Shroud")
		ml_mesh_mgr.SetDefaultMesh(291, "South Shroud")	
		ml_mesh_mgr.SetDefaultMesh(310, "Eastern La Noscea")
		ml_mesh_mgr.SetDefaultMesh(311, "Eastern La Noscea")
		ml_mesh_mgr.SetDefaultMesh(312, "Southern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(313, "Coerthas")	
		ml_mesh_mgr.SetDefaultMesh(314, "Central Thanalan")
		ml_mesh_mgr.SetDefaultMesh(315, "Mor Dhona")	
		ml_mesh_mgr.SetDefaultMesh(316, "Coerthas")
		ml_mesh_mgr.SetDefaultMesh(317, "South Shroud")	
		ml_mesh_mgr.SetDefaultMesh(318, "Southern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(319, "Central Shroud")	
		ml_mesh_mgr.SetDefaultMesh(320, "Central Shroud")	
		ml_mesh_mgr.SetDefaultMesh(321, "North Shroud")	
		ml_mesh_mgr.SetDefaultMesh(322, "Coerthas")	
		ml_mesh_mgr.SetDefaultMesh(323, "Southern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(324, "North Shroud")	
		ml_mesh_mgr.SetDefaultMesh(325, "Outer La Noscea")
		ml_mesh_mgr.SetDefaultMesh(326, "Mor Dhona")		
		ml_mesh_mgr.SetDefaultMesh(327, "Eastern La Noscea")
		ml_mesh_mgr.SetDefaultMesh(328, "Duty_1099")
		ml_mesh_mgr.SetDefaultMesh(329, "Duty_1102")
		ml_mesh_mgr.SetDefaultMesh(404, "Limsa (Upper)")
		ml_mesh_mgr.SetDefaultMesh(405, "Western La Noscea")
		ml_mesh_mgr.SetDefaultMesh(406, "Western La Noscea")
		ml_mesh_mgr.SetDefaultMesh(407, "ImOnABoat")
		ml_mesh_mgr.SetDefaultMesh(408, "Eastern La Noscea")
		ml_mesh_mgr.SetDefaultMesh(409, "Duty_155")	
		ml_mesh_mgr.SetDefaultMesh(411, "Eastern La Noscea")
		ml_mesh_mgr.SetDefaultMesh(412, "Upper La Noscea")
		ml_mesh_mgr.SetDefaultMesh(413, "Duty_217")
		ml_mesh_mgr.SetDefaultMesh(414, "Eastern La Noscea")
		ml_mesh_mgr.SetDefaultMesh(415, "Lower La Noscea")
		ml_mesh_mgr.SetDefaultMesh(453, "Western La Noscea")
		ml_mesh_mgr.SetDefaultMesh(454, "Upper La Noscea")
		ml_mesh_mgr.SetDefaultMesh(464, "The Dravanian Forelands")
		ml_mesh_mgr.SetDefaultMesh(465, "Eastern Thanalan")	
		ml_mesh_mgr.SetDefaultMesh(466, "Duty_1672")
		ml_mesh_mgr.SetDefaultMesh(467, "Coerthas Western Highlands")
		ml_mesh_mgr.SetDefaultMesh(468, "Coerthas")	
		ml_mesh_mgr.SetDefaultMesh(469, "Coerthas")	
		ml_mesh_mgr.SetDefaultMesh(470, "Coerthas Western Highlands")
		ml_mesh_mgr.SetDefaultMesh(471, "Eastern La Noscea")
		ml_mesh_mgr.SetDefaultMesh(472, "Coerthas Western Highlands")
		ml_mesh_mgr.SetDefaultMesh(473, "South Shroud")	
		ml_mesh_mgr.SetDefaultMesh(474, "Limsa (Upper)")
		ml_mesh_mgr.SetDefaultMesh(475, "Coerthas")	
		ml_mesh_mgr.SetDefaultMesh(476, "The Dravanian Hinterlands")
		ml_mesh_mgr.SetDefaultMesh(477, "Duty_1695")
		ml_mesh_mgr.SetDefaultMesh(480, "Mor Dhona")	
		ml_mesh_mgr.SetDefaultMesh(481, "The Dravanian Forelands")
		ml_mesh_mgr.SetDefaultMesh(482, "The Dravanian Forelands")
		ml_mesh_mgr.SetDefaultMesh(483, "Northern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(484, "Duty_1685")
		ml_mesh_mgr.SetDefaultMesh(486, "Outer La Noscea")
		ml_mesh_mgr.SetDefaultMesh(487, "Coerthas")	
		ml_mesh_mgr.SetDefaultMesh(488, "Coerthas")	
		ml_mesh_mgr.SetDefaultMesh(489, "Coerthas Western Highlands")
		ml_mesh_mgr.SetDefaultMesh(490, "Lower La Noscea")
		ml_mesh_mgr.SetDefaultMesh(491, "Southern Thanalan")
		ml_mesh_mgr.SetDefaultMesh(492, "Sea of Clouds")
		ml_mesh_mgr.SetDefaultMesh(493, "Duty_2037")
		ml_mesh_mgr.SetDefaultMesh(494, "Duty_2056")	
		ml_mesh_mgr.SetDefaultMesh(495, "Lower La Noscea")
		ml_mesh_mgr.SetDefaultMesh(496, "Coerthas")	
		ml_mesh_mgr.SetDefaultMesh(497, "Coerthas Western Highlands")
		ml_mesh_mgr.SetDefaultMesh(498, "Coerthas Western Highlands")
		ml_mesh_mgr.SetDefaultMesh(499, "Ishgard - The Pillars")
		ml_mesh_mgr.SetDefaultMesh(500, "Coerthas")	
		ml_mesh_mgr.SetDefaultMesh(501, "The Churning Mists")
		ml_mesh_mgr.SetDefaultMesh(502, "Duty_2104")
		ml_mesh_mgr.SetDefaultMesh(503, "Duty_2105")
		ml_mesh_mgr.SetDefaultMesh(640, "Duty_2416")
		ml_mesh_mgr.SetDefaultMesh(647, "Duty_2429")
		ml_mesh_mgr.SetDefaultMesh(648, "Duty_2430")
		ml_mesh_mgr.SetDefaultMesh(664, "Duty_2411")
		ml_mesh_mgr.SetDefaultMesh(666, "Duty_2560")
		ml_mesh_mgr.SetDefaultMesh(667, "Duty_2413")
		--ml_mesh_mgr.SetDefaultMesh(668, "Duty_2577")
		ml_mesh_mgr.SetDefaultMesh(669, "Duty_2588")
		ml_mesh_mgr.SetDefaultMesh(672, "Duty_2582")
		ml_mesh_mgr.SetDefaultMesh(673, "Duty_2592")
		ml_mesh_mgr.SetDefaultMesh(675, "Western La Noscea")
		ml_mesh_mgr.SetDefaultMesh(676, "Duty_2585")
		ml_mesh_mgr.SetDefaultMesh(678, "Duty_2418")
		ml_mesh_mgr.SetDefaultMesh(699, "Duty_2907")
		ml_mesh_mgr.SetDefaultMesh(700, "Duty_2909")
		ml_mesh_mgr.SetDefaultMesh(702, "Duty_2629")
		ml_mesh_mgr.SetDefaultMesh(704, "Duty_2894")
		ml_mesh_mgr.SetDefaultMesh(705, "Duty_2572")
		ml_mesh_mgr.SetDefaultMesh(706, "Duty_2572")
		ml_mesh_mgr.SetDefaultMesh(707, "Duty_2587")
		ml_mesh_mgr.SetDefaultMesh(708, "Duty_2562")
		ml_mesh_mgr.SetDefaultMesh(709, "Duty_2565")
		ml_mesh_mgr.SetDefaultMesh(710, "Duty_2568")
		ml_mesh_mgr.SetDefaultMesh(711, "Duty_2570")
		ml_mesh_mgr.SetDefaultMesh(714, "Duty_2914")
		ml_mesh_mgr.SetDefaultMesh(715, "Duty_2917")
		ml_mesh_mgr.SetDefaultMesh(716, "Duty_2919")
		ml_mesh_mgr.SetDefaultMesh(717, "Duty_2900")
		ml_mesh_mgr.SetDefaultMesh(718, "Duty_2904")
		ml_mesh_mgr.SetDefaultMesh(721, "Duty_2925")
		ml_mesh_mgr.SetDefaultMesh(722, "Duty_2927")
		ml_mesh_mgr.SetDefaultMesh(723, "Duty_2952")
		ml_mesh_mgr.SetDefaultMesh(726, "Duty_2950")
		ml_mesh_mgr.SetDefaultMesh(503, "Duty_2105")
		ml_mesh_mgr.SetDefaultMesh(503, "Duty_2105")
		ml_mesh_mgr.SetDefaultMesh(503, "Duty_2105")
		ml_mesh_mgr.SetDefaultMesh(503, "Duty_2105")
		ml_mesh_mgr.SetDefaultMesh(704, "Duty_2894")
		ml_mesh_mgr.SetDefaultMesh(705, "Duty_2572")
		ml_mesh_mgr.SetDefaultMesh(706, "Duty_2572")
		ml_mesh_mgr.SetDefaultMesh(714, "Duty_2914")
		ml_mesh_mgr.SetDefaultMesh(503, "Duty_2105")
		
		-- Latty SB
		ml_mesh_mgr.SetDefaultMesh(670, "Duty_2453")
		ml_mesh_mgr.SetDefaultMesh(659, "Duty_2463")
		ml_mesh_mgr.SetDefaultMesh(665, "Duty_2474")
		ml_mesh_mgr.SetDefaultMesh(685, "Duty_2498")	
		ml_mesh_mgr.SetDefaultMesh(688, "Duty_2515")
		ml_mesh_mgr.SetDefaultMesh(671, "Duty_2528")
		ml_mesh_mgr.SetDefaultMesh(686, "Duty_2549")
		ml_mesh_mgr.SetDefaultMesh(684, "Duty_2550")
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
			{ id = "FFXIVMINION##MENU_MAINMENU", name = "Main Task", onClick = function() ffxivminion.GUI.main.open = true end, tooltip = "Open the Main Task window." },
			{ id = "FFXIVMINION##MENU_DEV", name = "Dev Tools", onClick = function() dev.GUI.open = not dev.GUI.open end, tooltip = "Open the Developer tools." },
		}
	}
	ml_gui.ui_mgr:AddComponent(ffxiv_mainmenu)
end

function IsControlOpen(strControl)
	if (memoize and memoize.opencontrols) then
		if (memoize.opencontrols[strControl]) then
			return (memoize.opencontrols[strControl] == true)
		end
	end

	if (memoize.opencontrols == nil) then
		memoize.opencontrols = {}
	end
	
	local controls = GetControls()
	if (table.valid(controls)) then
		for id,e in pairs(controls) do
			if (e.name == strControl) then
				local isopen = e:IsOpen()
				memoize.opencontrols[strControl] = isopen
				return isopen
			end				
		end
	end
		
	return false
end

function GetControlData(strControl,strData)
	local controls = GetControls()
	if (table.valid(controls)) then
		for id,control in pairs(controls) do
			if (control.name == strControl) then
				local data = control:GetData()
				if (table.valid(data)) then
					if (strData == nil) then
						return data
					else
						for dataid, dataval in pairs(data) do
							if (dataid == strData) then
								return dataval
							end
						end
					end
				end
			end
		end
	end
	return nil
end

function GetControlStrings(strControl,numString)
	local controls = GetControls()
	if (table.valid(controls)) then
		for id,control in pairs(controls) do
			if (control.name == strControl) then
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
		end
	end
	return nil
end

function UseControlAction(strControl,strAction,actionArg)
	local actionArg = IsNull(actionArg,0)
	local controls = GetControls()
	if (table.valid(controls)) then
		for id,control in pairs(controls) do
			if (control.name == strControl) then
				if (strAction == "Close") then
					control:Close()
				elseif (strAction == "Destroy") then
					control:Destroy()
				else
					local actions = control:GetActions()
					if (table.valid(actions)) then
						for aid, action in pairs(actions) do
							if (action == strAction) then
								if (control:Action(action,actionArg)) then
									return true
								end
							end
						end
					end
				end
			end
		end
	end
	return false
end

function OpenControl(strControl)
	local control = GetControl(strControl)
	if (control and type(control) == "number") then
		CreateControl(control)
	elseif (control and type(control) == "table") then
		control:Open()
	end
end

function GetControl(strControl,allControls)
	local allControls = IsNull(allControls,false)
	
	local controls = GetControls()
	if (table.valid(controls)) then
		for id,e in pairs(controls) do
			if (e.name == strControl) then
				return e
			end
		end
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
RegisterEventHandler("RefreshBehaviorFiles", ml_global_information.LoadBehaviorFiles)

function PressYesNo(answer)
	local answer = IsNull(answer,true)
	if (answer == true) then
		answer = "Yes"
	elseif (answer == false)then
		answer = "No"
	end
	
	if (IsControlOpen("SelectYesno")) then
		if (IsControlOpen("_NotificationParty")) then
			return UseControlAction("SelectYesno","No")
		else
			return UseControlAction("SelectYesno",answer)
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
				vars.temptext = "Added ["..tostring(fate.id).." : "..tostring(fate.name).."] to the blacklist."
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

RegisterEventHandler("Module.Initalize",ml_global_information.Init)
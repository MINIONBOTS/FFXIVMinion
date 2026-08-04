-- Public, user-curated territory-to-navmesh defaults.
--
-- Keep these as direct setter calls instead of a Lua table. The installer runs
-- once, allocates no 590-entry mapping table, and is then released by
-- ffxiv_init.lua so its function prototype can be garbage-collected.
--
-- Curated line format:
--   apply(TerritoryTypeRowId, "Navigation folder name", forceMode)
-- forceMode is migrationEnforce for a one-time upgrade replacement, true for an
-- unconditional replacement, or nil to preserve an existing user selection.
ffxiv_mesh_defaults = ffxiv_mesh_defaults or {}

function ffxiv_mesh_defaults.ApplyDefaultMappings(setter, migrationEnforce)
    if type(setter) ~= "function" then return 0 end
    local count = 0
    local function apply(mapId, meshName, force)
        count = count + 1
        setter(mapId, meshName, force)
    end
		apply(130, "Ul'dah - Steps of Nald", migrationEnforce)
		apply(182, "Ul'dah - Steps of Nald", migrationEnforce)
		apply(131, "Ul'dah - Steps of Thal", migrationEnforce)
		apply(128, "Limsa Lominsa Upper Decks", migrationEnforce)
		apply(181, "Limsa Lominsa", migrationEnforce)
		apply(129, "Limsa Lominsa Lower Decks", migrationEnforce)
		apply(132, "New Gridania", migrationEnforce)
		apply(183, "New Gridania", migrationEnforce)
		apply(133, "Old Gridania", migrationEnforce)
		
		-- Barracks
		apply(534, "Twin Adder Barrack", migrationEnforce)
		apply(535, "Flame Barracks", migrationEnforce)
		apply(536, "Maelstrom Barracks", migrationEnforce)
		
		-- Cities HW
		apply(418, "Foundation", migrationEnforce)
		apply(419, "The Pillars", migrationEnforce)
		apply(428, "Seat of the Lord Commander", true)
		apply(427, "Saint Endalim's Scholasticate", true)
		apply(439, "The Lightfeather Proving Grounds", true)
		apply(433, "Fortemps Manor", true)
		apply(456, "Ruling Chamber", true)
		apply(886, "The Firmament", true)
		
		apply(478, "Idyllshire", migrationEnforce)
		
		-- Cities SB
		
		-- Cities SHB
		
		-- Main Areas ARR
		apply(134, "Middle La Noscea", migrationEnforce)
		apply(135, "Lower La Noscea", migrationEnforce)
		apply(137, "Eastern La Noscea", migrationEnforce)
		apply(138, "Western La Noscea", migrationEnforce)
		apply(139, "Upper La Noscea", migrationEnforce)
		apply(180, "Outer La Noscea", migrationEnforce)
		apply(177, "Mizzenmast Inn", true)
		apply(198, "Command Room", true)
		
		apply(140, "Western Thanalan", migrationEnforce)
		apply(141, "Central Thanalan", migrationEnforce)
		apply(145, "Eastern Thanalan", migrationEnforce)
		apply(146, "Southern Thanalan", migrationEnforce)
		apply(147, "Northern Thanalan", migrationEnforce)
		apply(178, "The Hourglass", true)
		apply(210, "Heart of the Sworn", true)
		
		apply(148, "Central Shroud", migrationEnforce)
		apply(152, "East Shroud", migrationEnforce)
		apply(153, "South Shroud", migrationEnforce)
		apply(154, "North Shroud", migrationEnforce)
		apply(179, "The Roost", true)
		apply(205, "Lotus Stand", true)
		apply(204, "Seat of the First Bow", true)

		apply(155, "Coerthas Central Highlands", migrationEnforce)
		apply(156, "Mor Dhona", migrationEnforce)
		
		apply(212, "The Waking Sands", true)
		apply(351, "The Rising Stones", true)
		apply(395, "Intercessory", true)
		
		-- Gold Saucer
		apply(144, "The Gold Saucer", true)
		apply(388, "Chocobo Square", true)
		
		-- Main Areas HW
		apply(397, "Coerthas Western Highlands", migrationEnforce)
		apply(398, "The Dravanian Forelands", migrationEnforce)
		apply(399, "The Dravanian Hinterlands", migrationEnforce)
		apply(400, "The Churning Mists", migrationEnforce)
		apply(401, "The Sea of Clouds", migrationEnforce)
		apply(402, "Azys Lla", migrationEnforce)
		
		apply(463, "Matoya's Cave", true)
		
		-- Main Areas SB
		apply(612, "The Fringes", migrationEnforce)
		apply(613, "The Ruby Sea", migrationEnforce)
		apply(614, "Yanxia", migrationEnforce)
		apply(620, "The Peaks", migrationEnforce)
		apply(621, "The Lochs", migrationEnforce)
		apply(622, "The Azim Steppe", migrationEnforce)
		
		apply(628, "Kugane", migrationEnforce)
		apply(735, "The Prima Vista Tiring Room", migrationEnforce)
		apply(736, "The Prima Vista Bridge", migrationEnforce)
		apply(635, "Rhalgr's Reach", migrationEnforce)
		apply(639, "Ruby Bazaar Offices", migrationEnforce)
		
		apply(680, "ImOnABoat", migrationEnforce)
		apply(681, "The House of the Fierce", migrationEnforce)
		apply(683, "First Alter of Djanan", migrationEnforce)
		apply(744, "Kienkan", migrationEnforce)
		apply(759, "Doman Enclave", migrationEnforce)
		apply(786, "Castrum Fluminis", migrationEnforce)
		
		-- Main Areas SHB
		
		 -- PVP
		apply(337, "Wolves' Den Pier", migrationEnforce)
		apply(336, "Wolves' Den Pier", migrationEnforce)
		apply(175, "Wolves' Den Pier", migrationEnforce)
		apply(352, "Wolves' Den Pier", migrationEnforce)
		apply(186, "Wolves' Den Pier", migrationEnforce)
		apply(250, "Wolves' Den Pier", migrationEnforce)		

		
		--apply(376, "Frontlines", migrationEnforce)
		--apply(422, "Frontlines - Slaughter", migrationEnforce)
		--apply(431, "Seal Rock", migrationEnforce)
		--apply(554, "[PVP] - Fields of Glory (Shatter)", migrationEnforce)
		--apply(729, "[PVP] - Astragalos (Rival Wings)", migrationEnforce)
		apply(888, "[PVP] Onsal Hakair", migrationEnforce)
		
		 -- Housing
		apply(339, "[Housing] Mist", nil)
		apply(340, "[Housing] Lavender Beds", nil)
		apply(341, "[Housing] The Goblet", nil)
		apply(641, "[Housing] Shirogane", nil)
		apply(979, "Empyreum", nil)
		
		-- Dungeons ARR
		apply(157, "[Dungeon] Sastasha", migrationEnforce)
		apply(1036, "[Dungeon] Sastasha", migrationEnforce)
		apply(164, "[Dungeon] Tamtara", migrationEnforce)
		apply(1037, "[Dungeon] Tamtara", migrationEnforce)
		apply(161, "[Dungeon] Copperbell Mines", migrationEnforce)
		apply(1038, "[Dungeon] Copperbell Mines v2", migrationEnforce)
		apply(162, "[Dungeon] Halatali", migrationEnforce)
		apply(169, "[Dungeon] Toto-Rak", migrationEnforce)
		apply(1039, "[Dungeon] The Thousand Maws of Toto-Rak v2", migrationEnforce)
		apply(166, "[Dungeon] Haukke Manor", migrationEnforce)
		apply(1040, "[Dungeon] Haukke Manor", migrationEnforce)
		apply(158, "[Dungeon] Brayflox", migrationEnforce)
		apply(1041, "[Dungeon] Brayflox's Longstop v2", migrationEnforce)
		apply(163, "[Dungeon] The Sunken Temple of Qarn", migrationEnforce)
		apply(170, "[Dungeon] Cutter's Cry", migrationEnforce)
		apply(168, "[Dungeon] Stone Vigil", migrationEnforce)
		apply(1042, "[Dungeon] Stone Vigil", migrationEnforce)
		apply(171, "[Dungeon] Dzemael Darkhold", migrationEnforce)
		apply(172, "[Dungeon] Aurum Vale", migrationEnforce)
		--apply(???, "[Dungeon] Castrum Meridianum", migrationEnforce)
		--apply(???, "[Dungeon] The Praetorium", migrationEnforce)
		apply(159, "[Dungeon] Wanderers Palace", migrationEnforce)
		apply(167, "[Dungeon] Amdapor Keep", migrationEnforce)
		apply(160, "Pharos Sirius", migrationEnforce)
		apply(349, "[Dungeon] Copperbell (Hard)", migrationEnforce)
		apply(350, "[Dungeon] Haukke Manor (Hard)", migrationEnforce)
		--apply(363, "[Dungeon]LostCity", migrationEnforce)
		apply(360, "[Dungeon] Halatali (Hard)", migrationEnforce)
		apply(362, "[Dungeon] Brayflox (Hard)", migrationEnforce)
		--apply(361, "[Dungeon]HullbreakerIsle", migrationEnforce)
		--apply(373, "[Dungeon]TamTaraHM", migrationEnforce)
		--apply(365, "[Dungeon]StoneVigilHM", migrationEnforce)
		apply(371, "[Dungeon] Snowcloak", migrationEnforce)
		apply(387, "[Dungeon] Sastasha (Hard)", migrationEnforce)
		--apply(367, "[Dungeon]SunkenTempleHM", migrationEnforce)
		--apply(150, "[Dungeon]KeepersOfTheLake", migrationEnforce)
		--apply(???, "[Dungeon] The Wanderer's PalaceHM", migrationEnforce)
		--apply(???, "[Dungeon] Amdapor KeepHM", migrationEnforce)
		apply(1043, "[Dungeon] Castrum Meridianum v2", migrationEnforce)
		apply(1044, "[Dungeon] The Praetorium v2", migrationEnforce)
		
		apply(1062, "[Dungeon] Snowcloak", migrationEnforce)
		apply(1063, "[Dungeon] The Keeper of the Lake", migrationEnforce)
		
		-- Dungeons HW
		apply(434, "[Dungeon] Dusk Vigil", migrationEnforce)
		apply(441, "[Dungeon] Sohm Al", migrationEnforce)
		apply(435, "[Dungeon] The Aery", migrationEnforce)
		apply(421, "[Dungeon] The Vault", migrationEnforce)
		apply(416, "[Dungeon] The Great Gubal Library", migrationEnforce)
		apply(1109, "[Dungeon] The Great Gubal Library v2", migrationEnforce)
		--apply(???, "[Dungeon] The Aetherochemical Research Facility", migrationEnforce)
		apply(1110, "[Dungeon] The Aetherochemical Research Facility v2", migrationEnforce)
		--apply(???, "[Dungeon] Neverreap", migrationEnforce)
		--apply(???, "[Dungeon] The Fractal Continuum", migrationEnforce)
		--apply(???, "[Dungeon] Saint Mocianne's Arboretum", migrationEnforce)
		--apply(???, "[Dungeon] Pharos SiriusHM", migrationEnforce)
		--apply(???, "[Dungeon] The Antitower", migrationEnforce)
		apply(1111, "[Dungeon] The Antitower v2", migrationEnforce)
		--apply(???, "[Dungeon] The Lost City of AmdaporHM", migrationEnforce)
		--apply(???, "[Dungeon] Sohr Khai", migrationEnforce)
		apply(1112, "[Dungeon] Sohr Khai v2", migrationEnforce)
		--apply(???, "[Dungeon] Hullbreaker IsleHM", migrationEnforce)
		--apply(???, "[Dungeon] Xelphatol", migrationEnforce)
		apply(1113, "[Dungeon] Xelphatol v2", migrationEnforce)
		--apply(???, "[Dungeon] The Great Gubal LibraryHM", migrationEnforce)
		--apply(???, "[Dungeon] Baelsar's Wall", migrationEnforce)
		apply(1114, "[Dungeon] Baelsar's Wall v2", migrationEnforce)
		--apply(???, "[Dungeon] Sohm AlHM", migrationEnforce)
		
		apply(1064, "[Dungeon] Sohm Al", migrationEnforce)
		apply(1065, "[Dungeon] The Aery", migrationEnforce)
		apply(1066, "[Dungeon] The Vault", migrationEnforce)
		
		
		
		-- Dungeons SB
		--apply(???, "[Dungeon] The Sirensong Sea", migrationEnforce)
		--apply(???, "[Dungeon] Shisui of the Violet Tides", migrationEnforce)
		apply(623, "[Dungeon] Bardam's Mettle", migrationEnforce)
		apply(660, "[Dungeon] Doma Castle", migrationEnforce)
		--apply(???, "[Dungeon] Castrum Abania", migrationEnforce)
		--apply(???, "[Dungeon] Ala Mhigo", migrationEnforce)
		--apply(???, "[Dungeon] Kugane Castle", migrationEnforce)
		--apply(???, "[Dungeon] The Temple of the Fist", migrationEnforce)
		apply(1172, "[Dungeon] The Drowned City of Skalla v2", migrationEnforce)
		--apply(???, "[Dungeon] Hells' Lid", migrationEnforce)
		--apply(???, "[Dungeon] The Fractal ContinuumHM", migrationEnforce)
		apply(768, "[Dungeon] The Swallow's Compass", migrationEnforce)
		apply(1173, "[Dungeon] The Burn", migrationEnforce)
		--apply(???, "[Dungeon] Saint Mocianne's ArboretumHM", migrationEnforce)
		--apply(???, "[Dungeon] The Ghimlyt Dark", migrationEnforce)

		-- Dungeons SHB
		apply(837, "[Dungeon] Holminster", migrationEnforce)
		apply(821, "[Dungeon] Dohn Mheg", migrationEnforce)
		apply(823, "[Dungeon] The Qitana Ravel", migrationEnforce)
		apply(836, "[Dungeon] Malikah's Well", migrationEnforce)
		apply(822, "[Dungeon] Mt. Gulg", migrationEnforce)
		apply(838, "[Dungeon] Amaurot", migrationEnforce)
		apply(840, "[Dungeon] The Twinning", migrationEnforce)
		apply(841, "[Dungeon] Akadaemia Anyder", migrationEnforce)
		apply(884, "[Dungeon] The Grand Cosmos", migrationEnforce)
		apply(898, "[Dungeon] Anamnesis Anyder", migrationEnforce)
		apply(916, "[Dungeon] The Heroes' Gauntlet", migrationEnforce)
		apply(938, "[Dungeon] Paglth'an", migrationEnforce)
		
		-- Dungeons EW
		apply(952, "[Dungeon] The Tower of Zot", migrationEnforce)
		apply(969, "[Dungeon] The Tower of Babil", migrationEnforce)
		apply(970, "[Dungeon] Vanaspati", migrationEnforce)
		apply(974, "[Dungeon] Ktisis Hyperboreia", migrationEnforce)
		apply(978, "[Dungeon] The Aitiascope", migrationEnforce)
		apply(986, "[Dungeon] The Stigma Dreamscape", migrationEnforce)
		apply(976, "[Dungeon] Smileton", migrationEnforce)
		apply(1050, "[Dungeon] Alzadaal's Legacy", migrationEnforce)
		
		-- Trials ARR
		apply(202, "[Trial] The Bowl of Embers", migrationEnforce)
		apply(1045, "[Trial] The Bowl of Embers", migrationEnforce)
		apply(206, "[Trial] The Navel", migrationEnforce)
		apply(1046, "[Trial] The Navel", migrationEnforce)
		apply(295, "Bowl of Embers", migrationEnforce)
		apply(296, "The Navel - Full Platform", migrationEnforce)
		apply(297, "The Howling Eye", migrationEnforce)
		apply(1047, "The Howling Eye", migrationEnforce)
		apply(331, "The Howling Eye - Entrance", migrationEnforce)
		apply(359, "The Whorleater", migrationEnforce)
		apply(375, "The Striking Tree", migrationEnforce)
		apply(378, "Akh Afah Amphitheatre", migrationEnforce)
		--apply(208, "[Trial] Garuda", migrationEnforce)
		--apply(332, "[Trial] CapeWestwind", migrationEnforce)
		apply(426, "[Trial] Chrysalis", migrationEnforce)
		apply(1048, "[Trial] The Porta Decumana", migrationEnforce)
		--apply(???, "[Trial] The Steps of Faith", migrationEnforce)
		--apply(???, "[Trial] A Relic Reborn The Chimera", migrationEnforce)
		--apply(???, "[Trial] A Relic Reborn The Hydra", migrationEnforce)
		--apply(???, "[Trial] Battle on the Big Bridge", migrationEnforce)
		--apply(???, "[Trial] The Dragon's Neck", migrationEnforce)
		--apply(???, "[Trial] Battle in the Big Keep", migrationEnforce)
		--apply(???, "[Trial] The Bowl of EmbersHM", migrationEnforce)
		--apply(???, "[Trial] The Howling EyeHM", migrationEnforce)
		--apply(???, "[Trial] The NavelHM", migrationEnforce)
		--apply(207, "[Trial] ThornmarchHM", migrationEnforce)
		--apply(281, "[Trial] The WhorleaterHM", migrationEnforce)
		--apply(374, "[Trial] The Striking TreeHM", migrationEnforce)
		apply(377, "Akh Afah Amphitheatre", migrationEnforce)
		--apply(???, "[Trial] Urth's Fount", migrationEnforce)
		--apply(???, "[Trial] The Minstrel's Ballad Ultima's Bane", migrationEnforce)
		
		-- Trials HW
		--apply(???, "[Trial] Thok ast ThokHM", migrationEnforce)
		--apply(???, "[Trial] The Limitless BlueHM", migrationEnforce)
		--apply(???, "[Trial] The Singularity Reactor", migrationEnforce)
		--apply(???, "[Trial] The Final Steps of Faith", migrationEnforce)
		--apply(???, "[Trial] Containment Bay S1T7", migrationEnforce)
		--apply(???, "[Trial] Containment Bay P1T6", migrationEnforce)
		apply(637, "[Trial] Containment Bay Z1T9", migrationEnforce)
		--apply(???, "[Trial] The Limitless BlueEX", migrationEnforce)
		--apply(???, "[Trial] Thok ast ThokEX", migrationEnforce)
		--apply(???, "[Trial] The Minstrel's Ballad Thordan's Reign", migrationEnforce)
		--apply(???, "[Trial] The Minstrel's Ballad Nidhogg's Rage", migrationEnforce)
		--apply(???, "[Trial] Containment Bay S1T7EX", migrationEnforce)
		--apply(???, "[Trial] Containment Bay P1T6EX", migrationEnforce)
		--apply(???, "[Trial] Containment Bay Z1T9EX", migrationEnforce)
		
		-- Trials SB
		apply(674, "[Trial] The Pool of Tribute", migrationEnforce)
		apply(720, "[Trial] Emanation", migrationEnforce)
		--apply(???, "[Trial] The Royal Menagerie", migrationEnforce)
		--apply(???, "[Trial] The Jade Stoa", migrationEnforce)
		apply(779, "[Trial] Castrum Fluminis", migrationEnforce)
		--apply(???, "[Trial] The Great Hunt", migrationEnforce)
		apply(810, "[Trial] Hells' Kier", migrationEnforce)
		apply(811, "[Trial] Hells' Kier", migrationEnforce)
		apply(824, "[Trial] The Wreath of Snakes", migrationEnforce)
		apply(825, "[Trial] The Wreath of Snakes", migrationEnforce)
		--apply(???, "[Trial] Kugane Ohashi", migrationEnforce)
		--apply(???, "[Trial] The Pool of TributeEX", migrationEnforce)
		--apply(???, "[Trial] The Minstrel's Ballad Shinryu's Domain", migrationEnforce)
		--apply(???, "[Trial] The Jade StoaEX", migrationEnforce)
		--apply(???, "[Trial] The Minstrel's Ballad Tsukuyomi's Pain", migrationEnforce)
		--apply(???, "[Trial] The Great HuntEX", migrationEnforce)

		-- Trials SHB
		apply(845, "[Trial] The Dancing Plague", migrationEnforce)
		--apply(???, "[Trial] The Crown of the Immaculate", migrationEnforce)
		--apply(???, "[Trial] The Crown of the ImmaculateEX", migrationEnforce)
		apply(847, "[Trial] The Dying Gasp", migrationEnforce)
		apply(881, "[Trial] The Dying Gasp", migrationEnforce)
		apply(885, "[Trial] The Dying Gasp", migrationEnforce)
		--apply(???, "[Trial] The Dancing PlagueEX", migrationEnforce)		
		apply(922, "[Trial] The Seat of Sacrifice", migrationEnforce)
		apply(950, "[Trial] G-Savior Deck", migrationEnforce)
		apply(951, "[Trial] G-Savior Deck", migrationEnforce)
		apply(991, "[Trial] G-Savior Deck", migrationEnforce)
		
		-- Trials EW
		apply(992, "[Trial] The Dark Inside", migrationEnforce)
		apply(997, "[Trial] The Final Day", migrationEnforce)
		apply(995, "[Trial] The Mothercrystal", migrationEnforce) --Hydaelyn
		apply(1095, "[Trial] Mount Ordeals", migrationEnforce) -- Rubicante Story
		apply(1096, "[Trial] Mount Ordeals", migrationEnforce) -- Rubicante EX
		apply(1140, "[Trial] The Voidcast Dais", migrationEnforce) -- Golbez Story
		apply(1141, "[Trial] The Voidcast Dais", migrationEnforce) -- Golbez EX
		apply(1168, "[Trial] The Abyssal Fracture", migrationEnforce) -- Zeromus Story
		apply(1169, "[Trial] The Abyssal Fracture", migrationEnforce) -- Zeromus EX		
		
		-- Raid Alliance ARR
		apply(174, "[Raid] Labyrinth of the Ancients", migrationEnforce)
		apply(372, "[Raid] Syrcus Tower", migrationEnforce)
		apply(151, "[Raid] The World of Darkness", migrationEnforce)
		
		-- Raid Alliance HW
		apply(508, "[Raid] The Void Ark", migrationEnforce)
		--apply(???, "[Raid] The Weeping City of Mhach", migrationEnforce)
		--apply(627, "[Raid] Dun Scaith", migrationEnforce)
		
		-- Raid Alliance SB
		apply(734, "[Raid] The Royal City of Rabanastre", migrationEnforce)
		apply(776, "[Raid] The Ridorana Lighthouse", migrationEnforce)
		apply(826, "[Raid] The Orbonne Monastery", migrationEnforce)
		
		-- Raid Alliance SHB
		apply(882, "[Raid] The Copied Factory", migrationEnforce)
		apply(896, "The Copied Factory2", true)
		apply(917, "[Raid] The Puppets' Bunker", migrationEnforce)
		apply(928, "The Puppets' Bunker2", true)
		--apply(???, "[Raid] ???", migrationEnforce)
		
		--apply(???, "[Raid] Castrum Lacus Litore", migrationEnforce)
		apply(936, "[Raid] Delubrum Reginae", migrationEnforce)
		--apply(???, "[Raid] ???", migrationEnforce)
		
		-- Raids ARR
		--apply(???, "[Raid] The Binding Coil of Bahamut", migrationEnforce)
		--apply(???, "[Raid] The Second Coil of Bahamut", migrationEnforce)
		--apply(???, "[Raid] The Second Coil of Bahamut Savage", migrationEnforce)
		--apply(???, "[Raid] The Final Coil of Bahamut", migrationEnforce)
		
		-- Raids HW
		apply(442, "[Raid] The Fist of the Father", migrationEnforce) -- a1
		apply(449, "[Raid] The Fist of the Father", migrationEnforce) -- a1s
		apply(443, "[Raid] The Cuff of the Father", migrationEnforce) -- a2
		apply(450, "[Raid] The Cuff of the Father", migrationEnforce) -- a2s
		apply(444, "[Raid] The Arm of the Father", migrationEnforce) -- a3
		apply(451, "[Raid] The Arm of the Father", migrationEnforce) -- a3s
		apply(445, "[Raid] The Burden of the Father", migrationEnforce) -- a4
		apply(452, "[Raid] The Burden of the Father", migrationEnforce) -- a4s
		apply(520, "[Raid] The Fist of the Son", migrationEnforce) -- a5
		apply(529, "[Raid] The Fist of the Son", migrationEnforce) -- a5s
		apply(521, "[Raid] The Cuff of the Son", migrationEnforce) -- a6
		apply(530, "[Raid] The Cuff of the Son", migrationEnforce) -- a6s
		apply(522, "[Raid] The Arm of the Son", migrationEnforce) -- a7
		apply(531, "[Raid] The Arm of the Son", migrationEnforce) -- a7s
		apply(523, "[Raid] The Burden of the Son", migrationEnforce) -- a8
		apply(532, "[Raid] The Burden of the Son", migrationEnforce) -- a8s
		apply(580, "[Raid] The Eyes of the Creator", migrationEnforce) -- a9
		apply(584, "[Raid] The Eyes of the Creator", migrationEnforce) -- a9s
		apply(581, "[Raid] The Breath of the Creator", migrationEnforce) -- a10
		apply(585, "[Raid] The Breath of the Creator", migrationEnforce) -- a10s
		apply(582, "[Raid] The Heart of the Creator", migrationEnforce) -- a11
		apply(586, "[Raid] The Heart of the Creator", migrationEnforce) -- a11s
		apply(583, "[Raid] The Soul of the Creator", migrationEnforce) -- a12
		apply(587, "[Raid] The Soul of the Creator", migrationEnforce) -- a12s

   		 -- Raids SB
		apply(690, "The Interdimensional Rift", migrationEnforce)
		apply(724, "The Interdimensional Rift", migrationEnforce)
		--apply(???, "[Raid] Omega Deltascape", migrationEnforce)
		--apply(???, "[Raid] Omega Deltascape Savag)", migrationEnforce)

		-- Raids SB Omega: released on July 4, 2017. Minimum item level of 295.
		apply(658, "The Interdimensional Rift2", migrationEnforce)
		apply(756, "The Interdimensional Rift2", migrationEnforce)
		apply(812, "The Interdimensional Rift2", migrationEnforce)
		apply(807, "The Interdimensional Rift2", migrationEnforce)
		apply(691, "[Raid] Deltascape V1.0", migrationEnforce) -- o1
		--apply(695, "[Raid] Deltascape V1.0", migrationEnforce) -- o1s
		apply(692, "[Raid] Deltascape V2.0", migrationEnforce) -- o2
		--apply(696, "[Raid] Deltascape V2.0", migrationEnforce) -- o2s
		apply(693, "[Raid] Deltascape V3.0", migrationEnforce) -- o3
		--apply(697, "[Raid] Deltascape V3.0", migrationEnforce) -- o3s
		--apply(694, "[Raid] Deltascape V4.0", migrationEnforce) -- o4
		--apply(698, "[Raid] Deltascape V4.0", migrationEnforce) -- o4s
		--apply(???, "[Raid] The Unending Coil of Bahamut Ultimate", migrationEnforce)
		--apply(748, "[Raid] Sigmascape V1.0", migrationEnforce) -- o5
		--apply(752, "[Raid] Sigmascape V1.0", migrationEnforce) -- o5s
		--apply(749, "[Raid] Sigmascape V2.0", migrationEnforce) -- o6
		--apply(753, "[Raid] Sigmascape V2.0", migrationEnforce) -- o6s
		--apply(750, "[Raid] Sigmascape V3.0", migrationEnforce) -- o7
		--apply(754, "[Raid] Sigmascape V3.0", migrationEnforce) -- o7s
		--apply(751, "[Raid] Sigmascape V4.0", migrationEnforce) -- o8
		--apply(755, "[Raid] Sigmascape V4.0", migrationEnforce) -- o8s
		--apply(???, "[Raid] The Minstrel's Ballad The Weapon's Refrain Ultimate", migrationEnforce)
		--apply(???, "[Raid] Alphascape V1.0", migrationEnforce) -- o9
		--apply(???, "[Raid] Alphascape V1.0", migrationEnforce) -- o9s
		--apply(???, "[Raid] Alphascape V2.0", migrationEnforce) -- o10
		--apply(???, "[Raid] Alphascape V2.0", migrationEnforce) -- o10s
		--apply(???, "[Raid] Alphascape V3.0", migrationEnforce) -- o11
		--apply(???, "[Raid] Alphascape V3.0", migrationEnforce) -- o11s
		--apply(???, "[Raid] Alphascape V4.0", migrationEnforce) -- o12
		--apply(???, "[Raid] Alphascape V4.0", migrationEnforce) -- o12s
		
		-- Raids SHB
		-- Eden's Gate
		apply(857, "The Core", migrationEnforce)
		apply(878, "The Empty", migrationEnforce)
		--apply(849, "[Raid] The Core", migrationEnforce)
		apply(850, "[Raid] The Halo_e2", migrationEnforce)
		apply(851, "[Raid] The Nereus Trench", migrationEnforce)
		--apply(852, "[Raid] Atlas Peak", migrationEnforce)
		--apply(853, "[Raid] The Core", migrationEnforce)
		--apply(854, "[Raid] The Halo_e2", migrationEnforce)
		--apply(855, "[Raid] The Nereus Trench", migrationEnforce)
		--apply(856, "[Raid] Atlas Peak", migrationEnforce)
		
		-- Eden's Verse
		apply(902, "[Raid] The Gandof Thunder Plains", migrationEnforce)
		apply(903, "[Raid] Ashfall", migrationEnforce)
		apply(904, "[Raid] The Halo_e7", migrationEnforce)
		apply(905, "[Raid] Great Glacier", migrationEnforce)
		apply(906, "[Raid] The Gandof Thunder Plains", migrationEnforce)		
		apply(907, "[Raid] Ashfall", migrationEnforce)		
		apply(908, "[Raid] The Halo_e7", migrationEnforce)		
		apply(909, "[Raid] Great Glacier", migrationEnforce)
		
		-- Eden's Promise
		apply(942, "[Raid] Sphere of Naught", migrationEnforce)
		apply(943, "[Raid] Laxan Loft", migrationEnforce)
		apply(944, "[Raid] Bygone Gaol", migrationEnforce)
		apply(945, "[Raid] The Garden of Nowhere", migrationEnforce)
		apply(946, "[Raid] Sphere of Naught", migrationEnforce)
		apply(947, "[Raid] Laxan Loft", migrationEnforce)
		apply(948, "[Raid] Bygone Gaol", migrationEnforce)
		apply(949, "[Raid] The Garden of Nowhere", migrationEnforce)
		
		-- Raids EW
		apply(1002, "[Raid] The Gates of Pandæmonium", migrationEnforce) -- p1
		apply(1003, "[Raid] The Gates of Pandæmonium", migrationEnforce) -- p1s
		apply(1004, "[Raid] The Stagnant Limbo", migrationEnforce) -- p2
		apply(1005, "[Raid] The Stagnant Limbo", migrationEnforce) -- p2s
		apply(1006, "[Raid] The Fervid Limbo", migrationEnforce) -- p3
		apply(1007, "[Raid] The Fervid Limbo", migrationEnforce) -- p3s
		apply(1008, "[Raid] The Sanguine Limbo", migrationEnforce) -- p4
		apply(1009, "[Raid] The Sanguine Limbo", migrationEnforce) -- p4s
		--apply(???, "[Raid] ", migrationEnforce) -- Ultimate 1
		--apply(???, "[Raid] ", migrationEnforce) -- p5
		--apply(???, "[Raid] ", migrationEnforce) -- p5s
		--apply(???, "[Raid] ", migrationEnforce) -- p6
		--apply(???, "[Raid] ", migrationEnforce) -- p6s
		--apply(???, "[Raid] ", migrationEnforce) -- p7
		--apply(???, "[Raid] ", migrationEnforce) -- p7s
		--apply(???, "[Raid] ", migrationEnforce) -- p8
		--apply(???, "[Raid] ", migrationEnforce) -- p8s
		--apply(???, "[Raid] , migrationEnforce) -- Ultimate 2
		--apply(???, "[Raid] ", migrationEnforce) -- p9
		--apply(???, "[Raid] ", migrationEnforce) -- p9s
		--apply(???, "[Raid] ", migrationEnforce) -- p10
		--apply(???, "[Raid] ", migrationEnforce) -- p10s
		--apply(???, "[Raid] ", migrationEnforce) -- p11
		--apply(???, "[Raid] ", migrationEnforce) -- p11s
		--apply(???, "[Raid] ", migrationEnforce) -- p12
		--apply(???, "[Raid] ", migrationEnforce) -- p12s
		
		-- Class Duties
		apply(228, "North Shroud", true)
		apply(229, "South Shroud", true)
		apply(230, "Central Shroud", true)
		apply(231, "South Shroud", true)
		apply(234, "East Shroud", true)
		apply(235, "South Shroud", true)
		apply(236, "South Shroud", true)
		apply(237, "Duty_55", true)
		apply(238, "Old Gridania", true)
		apply(239, "Duty_439", true)
		apply(240, "North Shroud", true)
		apply(251, "Ul'dah - Steps of Nald", true)
		apply(253, "Duty_288", true)
		apply(254, "Ul'dah - Steps of Nald", true)
		apply(255, "Western Thanalan", true)
		apply(256, "Eastern Thanalan", true)
		apply(257, "Eastern Thanalan", true)
		apply(258, "Duty_558", true)
		apply(259, "Duty_562", true)
		apply(260, "Duty_566", true)
		apply(261, "Southern Thanalan", true)
		apply(262, "Lower La Noscea", true)
		apply(263, "Western La Noscea", true)
		apply(264, "Lower La Noscea", true)
		apply(265, "Lower La Noscea", true)
		apply(266, "Eastern Thanalan", true)
		apply(267, "Western Thanalan", true)
		apply(268, "Eastern Thanalan", true)
		apply(269, "Western Thanalan", true)
		apply(270, "Duty_550", true)
		apply(285, "Middle La Noscea", true)
		apply(286, "ImOnABoat", true)
		apply(287, "Lower La Noscea", true)
		apply(288, "ImOnABoat", true)
		apply(289, "East Shroud", true)
		apply(291, "South Shroud", true)
		apply(310, "Eastern La Noscea", true)
		apply(311, "Eastern La Noscea", true)
		apply(312, "Southern Thanalan", true)
		apply(313, "Duty_1060", true)
		apply(314, "Central Thanalan", true)
		apply(315, "Mor Dhona", true)
		apply(316, "Coerthas Central Highlands", true)
		apply(317, "South Shroud", true)
		apply(318, "Southern Thanalan", true)
		apply(319, "Central Shroud", true)
		apply(320, "Central Shroud", true)
		apply(321, "North Shroud", true)
		apply(322, "Coerthas Central Highlands", true)
		apply(323, "Southern Thanalan", true)
		apply(324, "North Shroud", true)
		apply(325, "Duty_1095", true)
		apply(326, "Duty_1096", true)
		apply(327, "Eastern La Noscea", true)
		apply(328, "Duty_1099", true)
		apply(329, "Duty_1102", true)
		apply(404, "Limsa Lominsa Lower Decks", true)
		apply(405, "Western La Noscea", true)
		apply(406, "Western La Noscea", true)
		apply(407, "ImOnABoat", true)
		apply(408, "Eastern La Noscea", true)
		apply(409, "Duty_155", true)
		apply(411, "Eastern La Noscea", true)
		apply(412, "Upper La Noscea", true)
		apply(413, "Duty_217", true)
		apply(414, "Duty_233", true)
		apply(415, "Lower La Noscea", true)
		apply(453, "Western La Noscea", true)
		apply(454, "Upper La Noscea", true)
		apply(464, "The Dravanian Forelands", true)
		apply(465, "Eastern Thanalan", true)
		apply(466, "Duty_1672", true)
		apply(467, "Coerthas Western Highlands", true)
		apply(468, "Coerthas Central Highlands", true)
		apply(469, "Coerthas Central Highlands", true)
		apply(470, "Coerthas Western Highlands", true)
		apply(471, "Eastern La Noscea", true)
		apply(472, "Coerthas Western Highlands", true)
		apply(473, "South Shroud", true)
		apply(474, "Duty_2016", true)
		apply(475, "Coerthas Central Highlands", true)
		apply(476, "The Dravanian Hinterlands", true)
		apply(477, "Duty_1695", true)
		apply(480, "Mor Dhona", true)
		apply(481, "The Dravanian Forelands", true)
		apply(482, "The Dravanian Forelands", true)
		apply(483, "Northern Thanalan", true)
		apply(484, "Duty_1685", true)
		apply(486, "Outer La Noscea", true)
		apply(487, "Coerthas Central Highlands", true)
		apply(488, "Coerthas Central Highlands", true)
		apply(489, "Coerthas Western Highlands", true)
		apply(490, "Duty_1688", true)
		apply(491, "Southern Thanalan", true)
		apply(492, "The Sea of Clouds", true)
		apply(493, "Duty_2037", true)
		apply(494, "Duty_2056", true)
		apply(495, "Lower La Noscea", true)
		apply(496, "Coerthas Central Highlands", true)
		apply(497, "Coerthas Western Highlands", true)
		apply(498, "Coerthas Western Highlands", true)
		apply(499, "The Pillars", true)
		apply(500, "Duty_2058", true)
		apply(501, "Duty_2063", true)
		apply(502, "Duty_2104", true)
		apply(503, "Duty_2105", true)
		apply(640, "Duty_2416", true)
		apply(647, "Duty_2429", true)
		apply(648, "Duty_2430", true)
		apply(664, "Duty_2411", true)
		apply(666, "Ul'dah - Steps of Thal", true)
		apply(667, "Duty_2413", true) 
		apply(668, "Duty_2577", true )
		apply(669, "Duty_2588", true)
		apply(672, "Duty_2582", true)
		apply(673, "Duty_2592", true)
		apply(675, "Western La Noscea", true)
		apply(676, "Duty_2585", true)
		apply(678, "Duty_2418", true)
		apply(679, "The Royal Airship Landing", true)
		apply(699, "Duty_2907", true)
		apply(700, "Duty_2909", true)
		apply(701, "Duty_2627", true)
		apply(702, "Duty_2629", true)
		apply(703, "Duty_2892", true)
		apply(704, "Duty_2894", true)
		apply(705, "Ul'dah - Steps of Thal", true)
		apply(706, "Ul'dah - Steps of Thal", true)
		apply(707, "Duty_2587", true)
		apply(708, "Duty_2562", true)
		apply(709, "Duty_2565", true)
		apply(710, "Duty_2568", true)
		apply(711, "Duty_2570", true)
		apply(714, "Duty_2914", true)
		apply(715, "Duty_2917", true)
		apply(716, "Duty_2919", true) 
		apply(717, "Duty_2900", true)
		apply(718, "Duty_2904", true)
		apply(721, "Duty_2925", true)
		apply(722, "Duty_2927", true)
		apply(723, "Duty_2952", true)
		apply(726, "Duty_2950", true)
		apply(730, "Transparency", true)
		apply(746, "The Jade Stoa", true)
		apply(758, "The Jade Stoa", true)
		apply(810, "Hells' Kier", true)
		apply(811, "Hells' Kier", true)
		apply(865, "Duty_3262", true)
		apply(867, "Duty_3250", true)		
		apply(868, "Duty_3254", true)
		apply(869, "Duty_3248", true)
		apply(870, "Duty_3272", true)
		apply(871, "Duty_3278", true)
		apply(872, "Duty_3628", true)
		apply(873, "Duty_3247", true)
		apply(874, "Duty_3270", true)
		apply(875, "Duty_3276", true)
		apply(876, "Duty_3626", true)
		
		-- Latty SB
		apply(249, "Duty_414", true)
		apply(271, "Duty_551", true)
		apply(457, "Akh Afah Amphitheatre", true)
		apply(459, "Duty_1667", true)
		apply(460, "Duty_1601", true)
		apply(461, "The Sea of Clouds", true)
		apply(462, "Sacrificial Chamber", true)
		apply(513, "Duty_2163", true)
		apply(533, "Duty_2239", true)
		apply(592, "Bowl of Embers", true)
		apply(633, "Duty_2358", true)
		apply(634, "Duty_3027", true)
		apply(636, "Map636", true)
		apply(659, "Duty_2463", true)
		apply(665, "Duty_2474", true)
		apply(670, "Duty_2453", true)
		apply(671, "Duty_2528", true)
		apply(684, "Duty_2550", true)
		apply(685, "Duty_2498", true)
		apply(686, "Duty_2549", true)
		apply(688, "Duty_2515", true)
		apply(738, "Resonatorium", true)
		apply(757, "Duty_3024", true)
		apply(225, "Central Shroud", true)
		apply(226, "Central Shroud", true)
		apply(227, "Central Shroud", true)
		apply(232, "South Shroud", true)
		apply(233, "Central Shroud", true)
		apply(248, "Central Thanalan", true)
		apply(252, "Middle La Noscea", true)
		apply(270, "Central Thanalan", true)
		apply(272, "Middle La Noscea", true)
		apply(273, "Western Thanalan", true)
		apply(274, "Ul'dah - Steps of Nald", true)
		apply(275, "Eastern Thanalan", true)
		apply(277, "East Shroud", true)
		apply(278, "Western Thanalan", true)
		apply(279, "Lower La Noscea", true)
		apply(280, "Western La Noscea", true)
		apply(301, "Coerthas Central Highlands", true)
		apply(302, "DutyKill-941", true)
		apply(303, "East Shroud", true)
		apply(304, "Coerthas Central Highlands", true)
		apply(305, "Mor Dhona", true)
		apply(306, "Southern Thanalan", true)
		apply(307, "Lower La Noscea", true)
		apply(308, "Mor Dhona", true)
		apply(309, "Mor Dhona", true)
		apply(330, "Western La Noscea", true)
		apply(335, "Mor Dhona", true)
		apply(379, "Mor Dhona", true)
		apply(410, "Duty_88", true)
		apply(455, "The Sea of Clouds", true)
		apply(458, "Foundation", true)
		apply(479, "Coerthas Western Highlands", true)
		apply(485, "The Dravanian Hinterlands", true)
		apply(737, "Royal Palace", true)
		apply(769, "Duty_3076", true)
		apply(954, "The Navel", true)
		
		-- Latty SHB
		apply(813, "Lakeland", migrationEnforce)
		apply(877, "Lakeland", true)
		apply(814, "Kholusia", migrationEnforce)
		apply(815, "Amh Araeng", migrationEnforce)
		apply(816, "Il Mheg", migrationEnforce)
		apply(817, "The Rak'tika Greatwood", migrationEnforce)
		apply(818, "The Tempest", migrationEnforce)
		
		apply(819, "The Crystarium", migrationEnforce)
		apply(820, "Eulmore", migrationEnforce)
		
		apply(842, "The Syrcus Trench", true)
		apply(844, "The Ocular", migrationEnforce)
		apply(880, "The Crown of the Immaculate", true)
		
		apply(861, "Duty_3305", true)
		apply(874, "Duty_3270", true)
		apply(859, "The Confessional of Toupasa the Elder", true)
		apply(862, "Duty_3606", true)
		apply(860, "Duty_3619", true)
		apply(863, "Duty_3631", true)
		apply(864, "Duty_3638", true)
		apply(890, "Lyhe Mheg", true) -- Lyhe Mheg (Pixies map)
		apply(891, "Lyhe Mheg (Rank Quest)", true) -- Lyhe Mheg (Pixies Rank Quest)
		apply(893, "Duty_3682", true) -- The Imperial Palace
		apply(918, "[Dungeon] Anamnesis Anyder", migrationEnforce)
		
		apply(900, "The Endeavor", true)
		apply(1163, "The Endeavor", true)
		apply(901, "The Diadem", true)
		apply(929, "The Diadem", true)
		apply(939, "The Diadem", true)
		
		-- Endwalker
		apply(956, "Labyrinthos", true)
		apply(957, "Thavnair", true)
		apply(958, "Garlemald", true)
		apply(959, "Mare Lamentorum", true)
		apply(960, "Ultima Thule", true)
		apply(961, "Elpis", true)
		apply(962, "Old Sharlayan", true)
		apply(963, "Radz-at-Han", true)
		apply(971, "Lemures Headquarters", true)
		apply(987, "Main Hall", true)
		apply(990, "Andron", true)
		apply(1001, "Strategy Room", true)
		apply(1015, "Duty_4107", true)
		apply(1016, "Duty_4119", true)
		apply(1017, "Duty_4125", true)
		apply(1018, "Duty_4131", true)
		apply(1019, "Duty_4113", true)
		apply(1020, "Duty_4074", true)
		apply(1021, "Duty_4078", true)
		apply(1022, "Duty_4068", true)
		apply(1023, "Duty_4072", true)
		apply(1028, "The Dark Inside", true)
		apply(1056, "Alzadaal's Legacy", true)
		apply(1057, "Restricted Archives", true)
		
		apply(1070, "[Dungeon] The Fell Court of Troia", true)
		apply(1073, "Elysion", true)
		apply(1091, "Duty_4594", true)
		apply(1077, "[Quest] Zero's Domain", true)
		apply(1089, "[Quest] The Fell Court of Troia", true)
		apply(1097, "[Dungeon] Lapis Manalis", true)
		apply(1115, "The Tower of Babil[Hildibrand]", true)
		apply(1126, "[Dungeon] The Aetherfont", true)
		apply(1164, "[Dungeon] The Lunar Subterrane", true)
		
		
		-- Latty EW
		apply(1014, "Duty_4432", true)
		apply(1013, "Duty_4464", true)
		apply(1011, "Duty_4394", true)
		apply(1052, "Duty_4522", true)
		apply(1053, "[Quest] The Porta Decumana", true)
		apply(1093, "[Quest] Stygian Insenescence Cells", true)
		apply(1120, "Duty_4673", true) -- Solo Duty 6.3
		apply(1119, "[Quest] Lapis Manalis", true) -- Story Area 6.3
		apply(1159, "The Voidcast Dais", true) -- Story Area 6.4
		apply(1160, "Senatus", true) -- Story Area 6.4
		apply(1161, "Estinien's Chambers", true) -- Story Area 6.4
		apply(1162, "The Red Moon", true) -- Story Area 6.4
		apply(1184, "[Dungeon] The Lunar Subterrane", true) -- CS area after dungeon
		
		-- Island Sanctuary
		apply(1055, "Unnamed Island", true)
		-- DT maps
		apply(1170, "Sunperch", true)
		apply(1171, "Earthen Sky Hideout", true)
		apply(1185, "Tuliyollal", true)
		apply(1186, "Solution Nine", true)
		apply(1187, "Urqopacha", true)
		apply(1188, "Kozama'uka", true)
		apply(1189, "Yak T'el", true)
		apply(1190, "Shaaloani", true)
		apply(1191, "Heritage Found", true)
		apply(1192, "Living Memory", true)
		apply(1205, "The For'ard Cabins", true)
		apply(1206, "Main Deck", true)
		apply(1207, "The Backroom", true)
		apply(1219, "Vanguard", true)
		apply(1220, "Summit of Everkeep", true)
		apply(1221, "Interphos", true)
		apply(1222, "Skydeep Cenote Inner Chamber", true)
		apply(1254, "[Quest] Yuweyawata", true)
		apply(1268, "Break Room", true)
		apply(1274, "[Quest] Throne Room", true)
		apply(1269, "Phantom Village", true) --	quest
		apply(1278, "Phantom Village", true)
		apply(1252, "South Horn",true)
		apply(1299, "[Quest] Containment Complex 10-29",true)
		apply(1312, "[Quest] The Ageless Necropolis",true)
		apply(1332, "Treno",true)
		apply(1334, "Alexandria Crater",true)
		apply(1338, "[Quest] Bentini Depot",true)
    return count
end


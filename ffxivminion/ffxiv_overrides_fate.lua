-- FATE NPCs and pickup objects are collected in game. The sheets do not
-- expose enough information to locate them reliably.

FFXIVMinionFate = FFXIVMinionFate or {}

-- A map block is built on first use and kept for the rest of the session.
FFXIVMinionFate.ActivationByMap = {}
FFXIVMinionFate.GatheringByMap = {}
FFXIVMinionFate.ActivationLoaders = {}
FFXIVMinionFate.GatheringLoaders = {}

FFXIVMinionFate.HighPriority = {
	[147] = { -- Northern Thanalan
		[643] = true, -- Dark Devices - The Plea
		[644] = true, -- Dark Devices - The Bait
		[645] = true, -- Dark Devices - The Switch
		[646] = true, -- Dark Devices - The End
	},
	[155] = { -- Coerthas Central Highlands
		[501] = true, -- Svara's Flight
		[502] = true, -- Svara's Fear
		[503] = true, -- Svara's Fall
		[504] = true, -- Svara's Fury
	},
	[1190] = { -- Shaaloani
		[1867] = true, -- The Serpentlord Stirs
		[1868] = true, -- The Serpentlord Speaks
		[1869] = true, -- The Serpentlord Sires
		[1870] = true, -- The Serpentlord Suffers
		[1862] = true, -- You Are What You Drink
	},
}

function FFXIVMinionFate.IsHighPriority(mapId, fateId)
	local mapData = FFXIVMinionFate.HighPriority[tonumber(mapId)]
	return mapData and mapData[tonumber(fateId)] or false
end

function FFXIVMinionFate._LoadActivationMap(mapId)
	local mapData = FFXIVMinionFate.ActivationByMap[mapId]
	if mapData then return mapData end
	local loader = FFXIVMinionFate.ActivationLoaders[mapId]
	if not loader then return nil end
	mapData = loader()
	FFXIVMinionFate.ActivationByMap[mapId] = mapData
	FFXIVMinionFate.ActivationLoaders[mapId] = nil
	return mapData
end

function FFXIVMinionFate._LoadGatheringMap(mapId)
	local mapData = FFXIVMinionFate.GatheringByMap[mapId]
	if mapData then return mapData end
	local loader = FFXIVMinionFate.GatheringLoaders[mapId]
	if not loader then return nil end
	mapData = loader()
	FFXIVMinionFate.GatheringByMap[mapId] = mapData
	FFXIVMinionFate.GatheringLoaders[mapId] = nil
	return mapData
end

-- NPCs used to start FATEs.
-- Middle La Noscea
FFXIVMinionFate.ActivationLoaders[134] = function()
	return {
		[225] = { id = 1355, pos = { x = 99, y = 64, z = -147 } }, -- Thwack-a-Mole
		[229] = { id = 1320, pos = { x = 12, y = 58, z = -303 } }, -- The Orange Boxes
	}
end

-- Eastern La Noscea
FFXIVMinionFate.ActivationLoaders[137] = function()
	return {
		[267] = { id = 1720, pos = { x = 28, y = 54, z = 105 } }, -- Finding Wine
		[271] = { id = 1867, pos = { x = -75, y = 44, z = 403 } }, -- Thrill of the Hunt
		[272] = { id = 1855, pos = { x = -49, y = 38, z = 476 } }, -- The Pelican Briefing
		[279] = { id = 1363, pos = { x = 519, y = 9, z = 152 } }, -- No Lip
		[334] = { id = 891, pos = { x = 437, y = 16, z = 389 } }, -- Consigned, Sealed, and Undelivered
		[562] = { id = 1659, pos = { x = -263, y = 46, z = 304 } }, -- Sweeter than Honey
	}
end

-- Western Thanalan
FFXIVMinionFate.ActivationLoaders[140] = function()
	return {
		[344] = { id = 1322, pos = { x = -88, y = 52, z = 268 } }, -- Deface the Facts
		[346] = { id = 1323, pos = { x = -204, y = 32, z = 370 } }, -- The Cores
	}
end

-- Central Thanalan
FFXIVMinionFate.ActivationLoaders[141] = function()
	return {
		[377] = { id = 1325, pos = { x = 363, y = -17, z = -71 } }, -- Orobon Part Two: The Spawning
	}
end

-- Eastern Thanalan
FFXIVMinionFate.ActivationLoaders[145] = function()
	return {
		[195] = { id = 1255, pos = { x = 118, y = -3, z = 50 } }, -- Attack on Highbridge: Denouement
	}
end

-- Southern Thanalan
FFXIVMinionFate.ActivationLoaders[146] = function()
	return {
		[434] = { id = 1343, pos = { x = -187, y = 3, z = -181 } }, -- Run Like a Flame
	}
end

-- Northern Thanalan
FFXIVMinionFate.ActivationLoaders[147] = function()
	return {
		[457] = { id = 1726, pos = { x = -95, y = 83, z = -268 } }, -- Reverse Engineering
		[556] = { id = 1726, pos = { x = 28, y = 35, z = 55 } }, -- Core Blimey
		[642] = { id = 1718, pos = { x = 17, y = 4, z = 397 } }, -- The Ceruleum Road
		[643] = { id = 1512, pos = { x = 214, y = 24, z = 90 } }, -- Dark Devices - The Plea
		[644] = { id = 1513, pos = { x = 252, y = 25, z = 2 } }, -- Dark Devices - The Bait
	}
end

-- Central Shroud
FFXIVMinionFate.ActivationLoaders[148] = function()
	return {
		[601] = { id = 526, pos = { x = -335, y = 62, z = -39 } }, -- What's Your Poison
		[603] = { id = 2175, pos = { x = -448, y = 63, z = -249 } }, -- If I Only Had a Soul
	}
end

-- East Shroud
FFXIVMinionFate.ActivationLoaders[152] = function()
	return {
		[143] = { id = 524, pos = { x = -485, y = 8, z = 158 } }, -- Now I See Bees I Won
		[217] = { id = 1330, pos = { x = -182, y = 0, z = 274 } }, -- What Have You Done for Mead Lately
		[607] = { id = 1728, pos = { x = 274, y = 0, z = 165 } }, -- Collecting Keepsakes
		[610] = { id = 1729, pos = { x = 338, y = -4, z = -58 } }, -- The Enemy of My Enemy
	}
end

-- South Shroud
FFXIVMinionFate.ActivationLoaders[153] = function()
	return {
		[158] = { id = 526, pos = { x = 232, y = 6, z = -5 } }, -- The Negotiators
		[166] = { id = 529, pos = { x = -200, y = 9, z = -47 } }, -- Another Round
		[168] = { id = 526, pos = { x = 371, y = 0, z = 21 } }, -- Hide and Seek
		[172] = { id = 520, pos = { x = 291, y = 6, z = -25 } }, -- Robbin' Goblins
	}
end

-- Coerthas Central Highlands
FFXIVMinionFate.ActivationLoaders[155] = function()
	return {
		[469] = { id = 1605, pos = { x = 323, y = 345, z = -520 } }, -- The Grey
		[482] = { id = 1582, pos = { x = -580.7, y = 225.21, z = -100.3 } }, -- Riddle Me This
		[486] = { id = 1603, pos = { x = -549, y = 237, z = 360 } }, -- Tower of Power
		[501] = { id = 1862, pos = { x = 245, y = 302, z = -281 } }, -- Svara's Flight
	}
end

-- Mor Dhona
FFXIVMinionFate.ActivationLoaders[156] = function()
	return {
		[512] = { id = 1584, pos = { x = -122, y = -2, z = -628 } }, -- Toll Collector
	}
end

-- Outer La Noscea
FFXIVMinionFate.ActivationLoaders[180] = function()
	return {
		[587] = { id = 1332, pos = { x = 117, y = 74, z = -249 } }, -- Schism
		[595] = { id = 1723, pos = { x = 28, y = 70, z = -205 } }, -- Overlooking the Obvious
	}
end

-- Coerthas Western Highlands
FFXIVMinionFate.ActivationLoaders[397] = function()
	return {
		[788] = { id = 3976, pos = { x = 451, y = 167, z = 408 } }, -- A Dung Deal
		[815] = { id = 4410, pos = { x = 426, y = 183, z = 508 } }, -- No Ifs, Ands, or Butts
		[817] = { id = 3967, pos = { x = -235, y = 121, z = -26 } }, -- Dishonored
	}
end

-- The Dravanian Forelands
FFXIVMinionFate.ActivationLoaders[398] = function()
	return {
		[821] = { id = 4254, pos = { x = 519, y = -44, z = -147 } }, -- Birds of a Feather
	}
end

-- The Churning Mists
FFXIVMinionFate.ActivationLoaders[400] = function()
	return {
		[728] = { id = 3959, pos = { x = 597, y = -9, z = -35 } }, -- Coin Toss
		[744] = { id = 3954, pos = { x = -422, y = 40, z = -20 } }, -- Waiting for Fjalar to Stall
		[752] = { id = 3952, pos = { x = -177, y = -22, z = 316 } }, -- It's the Moogle, Reinvented
		[872] = { id = 3948, pos = { x = -470, y = 40, z = 111 } }, -- End of the Rainbow
	}
end

-- The Sea of Clouds
FFXIVMinionFate.ActivationLoaders[401] = function()
	return {
		[852] = { id = 4004, pos = { x = -517, y = -57, z = -524 } }, -- Obey their Thirst
		[853] = { id = 4003, pos = { x = 300, y = 29, z = -602 } }, -- The Fugitive
	}
end

-- Azys Lla
FFXIVMinionFate.ActivationLoaders[402] = function()
	return {
		[880] = { id = 4025, pos = { x = -208, y = -162, z = -199 } }, -- A Bug's Death
	}
end

-- The Fringes
FFXIVMinionFate.ActivationLoaders[612] = function()
	return {
		[1112] = { id = 6396, pos = { x = -602, y = 115, z = -239 } }, -- Showing the Recruits What For
		[1120] = { id = 5660, pos = { x = 360, y = 62, z = -471 } }, -- Keeping the Peace
		[1122] = { id = 5660, pos = { x = 112, y = 52, z = -512 } }, -- Double Dhara
		[1127] = { id = 6409, pos = { x = -501, y = 53, z = 23 } }, -- The Mail Must Get Through
		[1131] = { id = 5791, pos = { x = 509, y = 52, z = 409 } }, -- The Antlion's Share
		[1133] = { id = 6417, pos = { x = 295, y = 43, z = 191 } }, -- Get Sharp
	}
end

-- The Ruby Sea
FFXIVMinionFate.ActivationLoaders[613] = function()
	return {
		[1149] = { id = 6476, pos = { x = 376, y = 0, z = -705 } }, -- The Coral High Ground
		[1152] = { id = 6479, pos = { x = -46, y = 0, z = 501 } }, -- Ray Band
		[1167] = { id = 6494, pos = { x = -337, y = 33, z = -819 } }, -- Another One Bites the Dust
	}
end

-- Yanxia
FFXIVMinionFate.ActivationLoaders[614] = function()
	return {
		[1110] = { id = 6292, pos = { x = -420, y = 32, z = 456 } }, -- Freedom Flies
		[1111] = { id = 6291, pos = { x = -76, y = 61, z = -700 } }, -- More to Offer
		[1118] = { id = 6406, pos = { x = -482, y = 82, z = -243 } }, -- Dizzy Miss Grizzly
		[1120] = { id = 5660, pos = { x = 360, y = 62, z = -471 } }, -- Keeping the Peace
		[1136] = { id = 6735, pos = { x = 647, y = 82, z = 230 } }, -- A Pain in the Neck
		[1208] = { id = 6499, pos = { x = -169, y = 14, z = 507 } }, -- A Tisket, a Tasket
		[1211] = { id = 6500, pos = { x = 270, y = 14, z = -635 } }, -- Scared Straightheart
		[1224] = { id = 6508, pos = { x = 230, y = 43, z = 52 } }, -- Rice and Shine
		[1225] = { id = 6510, pos = { x = 438, y = 86, z = 40 } }, -- In One Basket
	}
end

-- The Peaks
FFXIVMinionFate.ActivationLoaders[620] = function()
	return {
		[1176] = { id = 6431, pos = { x = -307, y = 60, z = -686 } }, -- And the Bandits Played On
		[1186] = { id = 6439, pos = { x = 211, y = 311, z = 371 } }, -- Fletching Returns
		[1195] = { id = 6444, pos = { x = 145, y = 303, z = 653 } }, -- Forget-me-not
	}
end

-- The Azim Steppe
FFXIVMinionFate.ActivationLoaders[622] = function()
	return {
		[1250] = { id = 6541, pos = { x = 460, y = 11, z = -83 } }, -- A Good Day to Die
		[1255] = { id = 6543, pos = { x = -210, y = 83, z = -532 } }, -- Rock for Food
		[1261] = { id = 6547, pos = { x = 460, y = -24, z = 586 } }, -- Killing Dzo
		[1269] = { id = 6554, pos = { x = 166, y = 34, z = -332 } }, -- They Shall Not Want
		[1308] = { id = 6559, pos = { x = 239, y = 11, z = -191 } }, -- The Dataqi Chronicles: Duty
	}
end

-- Il Mheg
FFXIVMinionFate.ActivationLoaders[816] = function()
	return {
		[1492] = { id = 8677, pos = { x = -686, y = 27, z = -96 } }, -- Twice Upon a Time
		[1495] = { id = 8677, pos = { x = -560, y = 33, z = 105 } }, -- Once Upon a Time
	}
end

-- Urqopacha
FFXIVMinionFate.ActivationLoaders[1187] = function()
	return {
		[1877] = { id = 12890, pos = { x = -149.81, y = -124.54, z = -671.16 } }, -- Pasture Expiration Date
		[1878] = { id = 12890, pos = { x = 200, y = -66.99, z = -182 } }, -- Fire Suppression
		[1879] = { id = 12896, pos = { x = -225.41, y = -80.87, z = -283.13 } }, -- Wolf Parade
		[1880] = { id = 12896, pos = { x = 524.99, y = -94.1, z = -17.94 } }, -- Panaq Attack
		[1885] = { id = 12906, pos = { x = -54.57, y = -141.03, z = -554.9 } }, -- Birds Up
		[1889] = { id = 12912, pos = { x = -278.03, y = 56.84, z = 50.46 } }, -- Gust Stop Already
		[1891] = { id = 12915, pos = { x = 74.79, y = 20.65, z = 302.16 } }, -- Salty Showdown
		[1894] = { id = 12920, pos = { x = 155.33, y = 23.31, z = 165.82 } }, -- Lay Off the Horns
	}
end

-- Kozama'uka
FFXIVMinionFate.ActivationLoaders[1188] = function()
	return {
		[1926] = { id = 13002, pos = { x = -142.35, y = 3.52, z = -157.71 } }, -- There's Always a Bigger Beast
		[1927] = { id = 13004, pos = { x = -12.88, y = 3.84, z = -264.84 } }, -- Reeds in Need
		[1931] = { id = 13009, pos = { x = 61.69, y = 7.85, z = -625.71 } }, -- Combing the Area
		[1934] = { id = 13015, pos = { x = 289.69, y = 115.56, z = 199.67 } }, -- Tax Dodging
		[1937] = { id = 13021, pos = { x = -640, y = 149.27, z = 16 } }, -- Borne on the Backs of Burrowers
		[1938] = { id = 13011, pos = { x = 535.86, y = 8.83, z = -515.41 } }, -- Sayona Your Prayers
		[1940] = { id = 13025, pos = { x = -762.4, y = 127.83, z = 588.78 } }, -- Putting the Fun in Fungicide
	}
end

-- Yak T'el
FFXIVMinionFate.ActivationLoaders[1189] = function()
	return {
		[1895] = { id = 13390, pos = { x = -357.07, y = 21.67, z = -277.82 } }, -- Could've Found Something Bigger
		[1896] = { id = 13390, pos = { x = -328, y = 25, z = -202 }, range = 3 }, -- La Selva se lo Llevó
		[1899] = { id = 13386, pos = { x = -38.42, y = 4.42, z = -350.64 } }, -- Stick it to the Mantis
		[1903] = { id = 13395, pos = { x = -302.85, y = -167.65, z = -441.3 } }, -- Stabbing Gutward
		[1905] = { id = 13394, pos = { x = 134.82, y = -162.8, z = 722.5 } }, -- Porting Is Such Sweet Sorrow
		[1906] = { id = 13434, pos = { x = 443.33, y = -150.44, z = 669.47 } }, -- Escape Shroom
	}
end

-- Shaaloani
FFXIVMinionFate.ActivationLoaders[1190] = function()
	return {
		[1863] = { id = 13527, pos = { x = 13.79, y = -4.79, z = 458.61 } }, -- That's Me and the Porter
		[1864] = { id = 13530, pos = { x = -487.75, y = 31.38, z = -258.64 } }, -- The Dead Never Die
		[1865] = { id = 13532, pos = { x = -94.93, y = 5.62, z = 164.45 } }, -- Gonna Have Me Some Fur
		[1869] = { id = 13534, pos = { x = -30.66, y = 27.12, z = -651.36 } }, -- The Serpentlord Sires
		[1874] = { id = 13544, pos = { x = 673.68, y = -14.58, z = -352.08 } }, -- A Raptor Runs Through It
		[1875] = { id = 13547, pos = { x = 289.27, y = -9.59, z = 42.73 } }, -- Ain't What I Herd
		[1876] = { id = 13550, pos = { x = 118.86, y = -4.6, z = -260.34 } }, -- Helms off to the Bull
	}
end

-- Heritage Found
FFXIVMinionFate.ActivationLoaders[1191] = function()
	return {
		[1942] = { id = 13409, pos = { x = 423.55, y = 79.53, z = -385.41 } }, -- It's Super Defective
		[1943] = { id = 13409, pos = { x = 520.18, y = 82.98, z = -199.35 } }, -- Running of the Katobleps
		[1945] = { id = 13439, pos = { x = 221.62, y = 97.77, z = 80.53 } }, -- Ware the Wolves
		[1949] = { id = 13418, pos = { x = 713.62, y = 149.31, z = 89.39 } }, -- License to Dill
		[1950] = { id = 13420, pos = { x = -408.67, y = 39.53, z = -303.46 } }, -- Domo Arigato
		[1952] = { id = 13424, pos = { x = -611.86, y = 31.81, z = -336.74 } }, -- Old Stampeding Grounds
		[1953] = { id = 13426, pos = { x = -171.81, y = 32.23, z = 338.84 } }, -- Pulling the Wool
		[1957] = { id = 13431, pos = { x = -589.4, y = -13.2, z = 680.99 } }, -- When It's So Salvage
	}
end

-- Living Memory
FFXIVMinionFate.ActivationLoaders[1192] = function()
	return {
		[1913] = { id = 13331, pos = { x = -712.25, y = -5.24, z = -321.54 } }, -- Seeds of Tomorrow
		[1916] = { id = 13336, pos = { x = -496.62, y = 0.2, z = 643.4 } }, -- Canal Carnage
		[1917] = { id = 13339, pos = { x = 291.9, y = 44.08, z = -638.15 } }, -- Scattered Memories
		[1920] = { id = 13347, pos = { x = 712.43, y = 7.8, z = 635.64 } }, -- Mascot March
	}
end

-- NPCs and world objects used by collection FATEs.

-- Eastern La Noscea
FFXIVMinionFate.GatheringLoaders[137] = function()
	return {
		[272] = { id = 1855, pos = { x = -49, y = 38, z = 476 }, itemid = 2001226 }, -- The Pelican Briefing
		[279] = { id = 1363, pos = { x = 519, y = 9, z = 152 }, itemid = 2001761 }, -- No Lip
		[562] = { id = 1659, pos = { x = -263, y = 46, z = 304 }, itemid = 2001207 }, -- Sweeter than Honey
	}
end

-- Western Thanalan
FFXIVMinionFate.GatheringLoaders[140] = function()
	return {
		[346] = { id = 1323, pos = { x = -204, y = 32, z = 370 }, itemid = 2001221 }, -- The Cores
	}
end

-- Northern Thanalan
FFXIVMinionFate.GatheringLoaders[147] = function()
	return {
		[457] = { id = 1726, pos = { x = -95, y = 83, z = -268 }, itemid = 2001209 }, -- Reverse Engineering
		[556] = { id = 1726, pos = { x = 28, y = 35, z = 55 }, itemid = 2001221 }, -- Core Blimey
	}
end

-- Central Shroud
FFXIVMinionFate.GatheringLoaders[148] = function()
	return {
		[603] = { id = 2175, pos = { x = -448, y = 63, z = -249 }, itemid = 2001228 }, -- If I Only Had a Soul
	}
end

-- South Shroud
FFXIVMinionFate.GatheringLoaders[153] = function()
	return {
		[168] = { id = 526, pos = { x = 371, y = 0, z = 21 }, itemid = 2001213 }, -- Hide and Seek
		[172] = { id = 520, pos = { x = 291, y = 6, z = -25 }, itemid = 2001211 }, -- Robbin' Goblins
	}
end

-- North Shroud
FFXIVMinionFate.GatheringLoaders[154] = function()
	return {
		[180] = { id = 533, pos = { x = -247, y = -31, z = 389 }, itemid = 2001212 }, -- That Which Binds Us
	}
end

-- Coerthas Central Highlands
FFXIVMinionFate.GatheringLoaders[155] = function()
	return {
		[472] = { id = 1715, pos = { x = 511, y = 348, z = -695 }, itemid = 2001208 }, -- Spring Forward, Fall Back
	}
end

-- The Dravanian Forelands
FFXIVMinionFate.GatheringLoaders[398] = function()
	return {
		[821] = { id = 4254, pos = { x = 519, y = -44, z = -147 }, itemid = 2006422 }, -- Birds of a Feather
	}
end

-- The Churning Mists
FFXIVMinionFate.GatheringLoaders[400] = function()
	return {
		[728] = { id = 3959, pos = { x = 597, y = -9, z = -35 }, itemid = 2006126 }, -- Coin Toss
	}
end

-- The Sea of Clouds
FFXIVMinionFate.GatheringLoaders[401] = function()
	return {
		[852] = { id = 4004, pos = { x = -517, y = -57, z = -524 }, itemid = 2006356 }, -- Obey their Thirst
	}
end

-- The Fringes
FFXIVMinionFate.GatheringLoaders[612] = function()
	return {
		[1133] = { id = 6417, pos = { x = 295, y = 43, z = 191 }, itemid = 2008390 }, -- Get Sharp
		[1136] = { id = 6735, pos = { x = 647, y = 82, z = 230 }, itemid = 2008959 }, -- A Pain in the Neck
	}
end

-- The Ruby Sea
FFXIVMinionFate.GatheringLoaders[613] = function()
	return {
		[1149] = { id = 6476, pos = { x = 376, y = 0, z = -705 }, itemid = 2008954 }, -- The Coral High Ground
	}
end

-- Yanxia
FFXIVMinionFate.GatheringLoaders[614] = function()
	return {
		[1111] = { id = 6291, pos = { x = -76, y = 61, z = -700 }, itemid = 2008613 }, -- More to Offer
		[1136] = { id = 6735, pos = { x = 647, y = 82, z = 230 }, itemid = 2008959 }, -- A Pain in the Neck
		[1224] = { id = 6508, pos = { x = 230, y = 43, z = 52 }, itemid = 2008751 }, -- Rice and Shine
		[1225] = { id = 6510, pos = { x = 438, y = 86, z = 40 }, itemid = 2008752 }, -- In One Basket
	}
end

-- The Peaks
FFXIVMinionFate.GatheringLoaders[620] = function()
	return {
		[1186] = { id = 6439, pos = { x = 211, y = 311, z = 371 }, itemid = 2008956 }, -- Fletching Returns
	}
end

-- The Azim Steppe
FFXIVMinionFate.GatheringLoaders[622] = function()
	return {
		[1308] = { id = 6559, pos = { x = 239, y = 11, z = -191 }, itemid = 2008947 }, -- The Dataqi Chronicles: Duty
	}
end

-- Il Mheg
FFXIVMinionFate.GatheringLoaders[816] = function()
	return {
		[1492] = { id = 8677, pos = { x = -686, y = 27, z = -9 }, itemid = 2002819 }, -- Twice Upon a Time
	}
end

-- Thavnair
FFXIVMinionFate.GatheringLoaders[957] = function()
	return {
		[1764] = { id = 10790, pos = { x = -31.58, y = 89, z = -538 }, itemid = 2003307 }, -- Full Petal Alchemist: Perilous Pickings
	}
end

-- Kozama'uka
FFXIVMinionFate.GatheringLoaders[1188] = function()
	return {
		[1931] = { id = 13009, pos = { x = 92.05, y = 6.88, z = -607.92 }, itemid = 2014204 }, -- Combing the Area
		[1937] = { id = 13021, pos = { x = -607.08, y = 144.17, z = 27.97 }, itemid = 2014205 }, -- Borne on the Backs of Burrowers
	}
end

-- Yak T'el
FFXIVMinionFate.GatheringLoaders[1189] = function()
	return {
		[1906] = { id = 13434, pos = { x = 444.33, y = -150.8, z = 702.67 }, itemid = 2014278 }, -- Escape Shroom
	}
end

-- Shaaloani
FFXIVMinionFate.GatheringLoaders[1190] = function()
	return {
		[1865] = { id = 13532, pos = { x = -119.74, y = 7.36, z = 190.58 }, itemid = 2014267 }, -- Gonna Have Me Some Fur
		[1869] = { id = 13534, pos = { x = 2.2, y = 20, z = -648.06 }, itemid = 2014268 }, -- The Serpentlord Sires
	}
end

-- Heritage Found
FFXIVMinionFate.GatheringLoaders[1191] = function()
	return {
		[1949] = { id = 13418, pos = { x = 694.76, y = 147.18, z = 64.36 }, itemid = 2014279 }, -- License to Dill
		[1957] = { id = 13431, pos = { x = -563.85, y = -14, z = 704.37 }, itemid = 2014280 }, -- When It's So Salvage
	}
end

-- Living Memory
FFXIVMinionFate.GatheringLoaders[1192] = function()
	return {
		[1913] = { id = 13331, pos = { x = -737.79, y = -5, z = -295.78 }, itemid = 2014099 }, -- Seeds of Tomorrow
		[1917] = { id = 13339, pos = { x = 301.35, y = 43.63, z = -671.32 }, itemid = 2014194 }, -- Scattered Memories
	}
end

function FFXIVMinionFate.GetActivateable(mapId, fateId)
	mapId = tonumber(mapId)
	fateId = tonumber(fateId)
	if not mapId or not fateId then return nil end
	local mapData = FFXIVMinionFate._LoadActivationMap(mapId)
	return mapData and mapData[fateId] or nil
end

function FFXIVMinionFate.GetGatherable(mapId, fateId)
	mapId = tonumber(mapId)
	fateId = tonumber(fateId)
	if not mapId or not fateId then return nil end
	local mapData = FFXIVMinionFate._LoadGatheringMap(mapId)
	local record = mapData and mapData[fateId] or nil
	if not record then return nil end

	if not record.turninid then
		local fate = FFXIVLib.API.Fate.GetFateById(fateId)
		if not fate then return nil end
		record.turninid = tonumber(fate.EventItem)
		if not record.turninid or record.turninid == 0 then return nil end
	end
	return record
end

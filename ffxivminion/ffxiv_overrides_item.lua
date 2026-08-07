FFXIVMinionItem = FFXIVMinionItem or {}

-- These are Minion inventory containers, not game sheet rows.
FFXIVMinionItem.SearchInventories = {
	0, 1, 2, 3, 1000, 2004, 2000, 2001,
	3200, 3201, 3202, 3203, 3204, 3205, 3206, 3207, 3208, 3209,
	3300, 3400, 3500,
}

function FFXIVMinionItem.GetArmoryBag(slot)
	slot = tonumber(slot)
	if slot == 0 then return 3500 end -- Main hand
	if slot and slot >= 1 and slot <= 10 then return 3199 + slot end
	if slot == 11 or slot == 12 then return 3300 end -- Rings share a bag
	return nil
end

function FFXIVMinionItem.GetEquipSlot(itemSlot)
	itemSlot = tonumber(itemSlot)
	if itemSlot and itemSlot >= 1 and itemSlot <= 12 then return itemSlot - 1 end
	if itemSlot == 13 then return 0 end -- Two-handed weapon
	if itemSlot == 17 then return 13 end -- Soul crystal
	return nil
end

function FFXIVMinionItem.GetArmoryType(itemSlot)
	itemSlot = tonumber(itemSlot)
	if itemSlot == 1 or itemSlot == 13 then return FFXIV.INVENTORYTYPE.INV_ARMORY_MAINHAND end
	if itemSlot == 2 then return FFXIV.INVENTORYTYPE.INV_ARMORY_OFFHAND end
	if itemSlot == 3 then return FFXIV.INVENTORYTYPE.INV_ARMORY_HEAD end
	if itemSlot == 4 then return FFXIV.INVENTORYTYPE.INV_ARMORY_BODY end
	if itemSlot == 5 then return FFXIV.INVENTORYTYPE.INV_ARMORY_HANDS end
	if itemSlot == 6 then return FFXIV.INVENTORYTYPE.INV_ARMORY_WAIST end
	if itemSlot == 7 then return FFXIV.INVENTORYTYPE.INV_ARMORY_LEGS end
	if itemSlot == 8 then return FFXIV.INVENTORYTYPE.INV_ARMORY_FEET end
	if itemSlot == 9 then return FFXIV.INVENTORYTYPE.INV_ARMORY_NECK end
	if itemSlot == 10 then return FFXIV.INVENTORYTYPE.INV_ARMORY_EARS end
	if itemSlot == 11 then return FFXIV.INVENTORYTYPE.INV_ARMORY_WRIST end
	if itemSlot == 12 then return FFXIV.INVENTORYTYPE.INV_ARMORY_RINGS end
	if itemSlot == 17 then return FFXIV.INVENTORYTYPE.INV_ARMORY_SOULCRYSTAL end
	return nil
end

-- A few gathering priorities are Minion behavior rather than sheet categories.
function FFXIVMinionItem.HasGatheringPriority(itemId, priority)
	local id = tonumber(itemId) or 0
	if priority == "gardening" then
		return id == 5365 -- Bamboo Stick
			or id == 7029 -- Island Seedling
			or id == 7030 -- Shroud Seedling
			or id == 7031 -- Desert Seedling
			or id == 8024 -- Waterfowl Feather
			or id == 12887 -- Sesame Seeds
	end
	if priority == "ixalirare" then
		return id == 2001389 -- Pristine Oak Log
			or id == 2001392 -- Large Granite Rock
			or id == 2001413 -- Tangle Mangrove Log
			or id == 2001416 -- Clear Water Cluster
			or id == 2001425 -- Ruby Spruce Log
			or id == 2001427 -- High-quality Furite
	end
	if priority == "ixalisemirare" then
		return id == 2001388 -- Pristine Oak Branch
			or id == 2001391 -- Small Granite Rock
			or id == 2001412 -- Tangle Mangrove Branch
			or id == 2001415 -- Clear Water Shard
			or id == 2001424 -- Ruby Spruce Branch
			or id == 2001426 -- Furite
	end
	if priority == "chocobofood" then
		return id == 10094 or id == 10095 or id == 10097 or id == 10098
	end
	if priority == "chocobofoodspecial" then
		return id == 10095 or id == 10098
	end
	if priority == "rare" then
		return id == 5365 -- Bamboo Stick
			or id == 8024 -- Waterfowl Feather
			or id == 10099 -- Unaspected Crystal
			or id == 10335 -- Dark Matter Cluster
			or (id >= 12946 and id <= 12950)
			or (id >= 12956 and id <= 12960)
	end
	if priority == "superrare" then
		return (id >= 12951 and id <= 12955)
			or (id >= 12961 and id <= 12966) -- Bright Fire Rock
	end
	return false
end

-- Built only when companion food is enabled.
function FFXIVMinionItem.GetChocoboItemBuffs()
	if not FFXIVMinionItem._chocoboItemBuffs then
		FFXIVMinionItem._chocoboItemBuffs = {
			[7894] = { name = "Curiel Root (EXP)", item = 7894, buff1 = 536, buff2 = 537 },
			[7895] = { name = "Sylkis Bud (ATK)", item = 7895, buff1 = 538, buff2 = 539 },
			[7897] = { name = "Mimett Gourd (Heal)", item = 7897, buff1 = 540, buff2 = 541 },
			[7898] = { name = "Tantalplant (HP)", item = 7898, buff1 = 542, buff2 = 543 },
			[7900] = { name = "Pahsana Fruit (ENM)", item = 7900, buff1 = 544, buff2 = 545 },
		}
	end
	return FFXIVMinionItem._chocoboItemBuffs
end

-- Relic drops are tied to regions by game behavior, not an item sheet column.
function FFXIVMinionItem.GetRelicGrindData(kind)
	if kind == "atma" then
		if not FFXIVMinionItem._atma then
			FFXIVMinionItem._atma = {
				Maiden = { item = 7851, map = 148, tele = 3 }, -- Central Shroud
				Scorpion = { item = 7852, map = 146, tele = 20 }, -- Southern Thanalan
				Waterbearer = { item = 7853, map = 139, tele = 15 }, -- Upper La Noscea
				Goat = { item = 7854, map = 152, tele = 4 }, -- East Shroud
				Bull = { item = 7855, map = 145, tele = 18 }, -- Eastern Thanalan
				Ram = { item = 7856, map = 134, tele = 52 }, -- Middle La Noscea
				Twins = { item = 7857, map = 140, tele = 17 }, -- Western Thanalan
				Lion = { item = 7858, map = 180, tele = 16 }, -- Outer La Noscea
				Fish = { item = 7859, map = 135, tele = 10 }, -- Lower La Noscea
				Archer = { item = 7860, map = 154, tele = 7 }, -- North Shroud
				Scales = { item = 7861, map = 141, tele = 53 }, -- Central Thanalan
				Crab = { item = 7862, map = 138, tele = 14 }, -- Western La Noscea
			}
		end
		return FFXIVMinionItem._atma
	end
	if kind == "luminous" then
		if not FFXIVMinionItem._luminous then
			FFXIVMinionItem._luminous = {
				Ice = { item = 13569, map = 397 }, -- Coerthas Western Highlands
				Earth = { item = 13572, map = 398 }, -- The Dravanian Forelands
				Water = { item = 13574, map = 399 }, -- The Dravanian Hinterlands
				Lightning = { item = 13573, map = 400 }, -- The Churning Mists
				Wind = { item = 13570, map = 401 }, -- The Sea of Clouds
				Fire = { item = 13571, map = 402 }, -- Azys Lla
			}
		end
		return FFXIVMinionItem._luminous
	end
	return nil
end

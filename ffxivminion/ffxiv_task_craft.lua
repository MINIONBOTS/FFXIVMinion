ffxiv_craft = {}

ffxiv_craft.tracking = {
	measurementDelay = 0,
	quickTimer = 0,
}
ffxiv_craft.crafts = {
	["CRP"] = 8,	["BSM"] = 9,	["ARM"] = 10,	["GSM"] = 11,
	["LTW"] = 12,	["WVR"] = 13,	["ALC"] = 14,	["CUL"] = 15,
}
ffxiv_craft.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\CraftProfiles\]]
ffxiv_craft.profiles = {}
ffxiv_craft.profilesDisplay = {}
ffxiv_craft.profileData = {}
ffxiv_craft.orders = {}
ffxiv_craft.ordersVisible = false
ffxiv_craft.orderSelectorVisible = false
ffxiv_craft.dictionaries = {}
ffxiv_craft.dictionariesDisplay = {}
ffxiv_craft.lastCraft = {}
ffxiv_craft.collectors = {
	[8] = 4560,
	[9] = 4561,
	[10] = 4562,
	[11] = 4563,
	[12] = 4564,
	[13] = 4565,
	[14] = 4566,
	[15] = 4567,
}
ffxiv_craft.collectibles = {

	-- Weekly
	{ name = AceLib.API.Items.GetNameByID(20776), minimum = 167 }, -- Far Eastern Antique
	{ name = AceLib.API.Items.GetNameByID(20775), minimum = 157 }, -- Gyr Abanian Souvenir
	{ name = AceLib.API.Items.GetNameByID(17550), minimum = 55 }, -- Coerthan Souvenir
	{ name = AceLib.API.Items.GetNameByID(17549), minimum = 55 }, -- Near Eastern Antique
	
	-- Carpenter
	{ alias = "Dragonscale Grinding Wheel", id = 11929, minimum = 350, name = AceLib.API.Items.GetNameByID(11929) },
	{ alias = "Persimmon Necklace", id = 19739, minimum = 610, name = AceLib.API.Items.GetNameByID(19739) },
	{ alias = "Holy Cedar Ring", id = 12020, minimum = 190, name = AceLib.API.Items.GetNameByID(12020) },
	{ alias = "Mythrite Pugil Stick", id = 10605, minimum = 160, name = AceLib.API.Items.GetNameByID(10605) },
	{ alias = "Hallowed Chestnut Mask of Healing", id = 10883, minimum = 270, name = AceLib.API.Items.GetNameByID(10883) },
	{ alias = "Pine Spinning Wheel", id = 19543, minimum = 510, name = AceLib.API.Items.GetNameByID(19543) },
	{ alias = "Holy Cedar Composite Bow", id = 10611, minimum = 160, name = AceLib.API.Items.GetNameByID(10611) },
	{ alias = "Muudhorn Fishing Rod", id = 19516, minimum = 320, name = AceLib.API.Items.GetNameByID(19516) },
	{ alias = "Beech Composite Bow", id = 18037, minimum = 320, name = AceLib.API.Items.GetNameByID(18037) },
	{ alias = "Birch Spinning Wheel", id = 11937, minimum = 350, name = AceLib.API.Items.GetNameByID(11937) },
	{ alias = "Birch Fishing Rod", id = 11914, minimum = 400, name = AceLib.API.Items.GetNameByID(11914) },
	{ alias = "Dark Chestnut Longbow", id = 10612, minimum = 220, name = AceLib.API.Items.GetNameByID(10612) },
	{ alias = "Holy Cedar Armillae", id = 12014, minimum = 190, name = AceLib.API.Items.GetNameByID(12014) },
	{ alias = "Hallowed Chestnut Necklace", id = 12012, minimum = 350, name = AceLib.API.Items.GetNameByID(12012) },
	{ alias = "Pine Cane", id = 18353, minimum = 470, name = AceLib.API.Items.GetNameByID(18353) },
	{ alias = "Zelkova Spinning Wheel", id = 19585, minimum = 660, name = AceLib.API.Items.GetNameByID(19585) },
	{ alias = "Hallowed Chestnut Fishing Rod", id = 11913, minimum = 290, name = AceLib.API.Items.GetNameByID(11913) },
	{ alias = "Persimmon Spinning Wheel", id = 19564, minimum = 610, name = AceLib.API.Items.GetNameByID(19564) },
	{ alias = "Holy Cedar Necklace", id = 12011, minimum = 220, name = AceLib.API.Items.GetNameByID(12011) },
	{ alias = "Zelkova Cane", id = 18665, minimum = 630, name = AceLib.API.Items.GetNameByID(18665) },
	{ alias = "Larch Wand", id = 18197, minimum = 370, name = AceLib.API.Items.GetNameByID(18197) },
	{ alias = "Polished Slate Grinding Wheel", id = 19562, minimum = 610, name = AceLib.API.Items.GetNameByID(19562) },
	{ alias = "Hallowed Chestnut Armillae", id = 12015, minimum = 320, name = AceLib.API.Items.GetNameByID(12015) },
	{ alias = "Birch Composite Bow", id = 10615, minimum = 400, name = AceLib.API.Items.GetNameByID(10615) },
	{ alias = "Dark Chestnut Lumber", id = 12581, minimum = 250, name = AceLib.API.Items.GetNameByID(12581) },
	{ alias = "Astral Grinding Wheel", id = 11927, minimum = 190, name = AceLib.API.Items.GetNameByID(11927) },
	{ alias = "Dark Chestnut Rod", id = 10636, minimum = 220, name = AceLib.API.Items.GetNameByID(10636) },
	{ alias = "Birch Rod", id = 10639, minimum = 400, name = AceLib.API.Items.GetNameByID(10639) },
	{ alias = "Zelkova Earrings", id = 19748, minimum = 650, name = AceLib.API.Items.GetNameByID(19748) },
	{ alias = "Persimmon Bracelets", id = 19740, minimum = 610, name = AceLib.API.Items.GetNameByID(19740) },
	{ alias = "Adamantite Trident", id = 10609, minimum = 400, name = AceLib.API.Items.GetNameByID(10609) },
	{ alias = "Molybdenum Trident", id = 18660, minimum = 630, name = AceLib.API.Items.GetNameByID(18660) },
	{ alias = "Hallowed Chestnut Ring", id = 12021, minimum = 290, name = AceLib.API.Items.GetNameByID(12021) },
	{ alias = "Adamantite Spear", id = 10608, minimum = 320, name = AceLib.API.Items.GetNameByID(10608) },
	{ alias = "Cloud Mica Grinding Wheel", id = 11928, minimum = 270, name = AceLib.API.Items.GetNameByID(11928) },
	{ alias = "Birch Signum", id = 10638, minimum = 320, name = AceLib.API.Items.GetNameByID(10638) },
	{ alias = "Hallowed Chestnut Composite Bow", id = 10613, minimum = 270, name = AceLib.API.Items.GetNameByID(10613) },
	{ alias = "Doman Steel Halberd", id = 18504, minimum = 560, name = AceLib.API.Items.GetNameByID(18504) },
	{ alias = "High Steel Trident", id = 18036, minimum = 320, name = AceLib.API.Items.GetNameByID(18036) },
	{ alias = "Cedar Longbow", id = 10610, minimum = 130, name = AceLib.API.Items.GetNameByID(10610) },
	{ alias = "Zelkova Necklace", id = 19749, minimum = 650, name = AceLib.API.Items.GetNameByID(19749) },
	{ alias = "Zelkova Longbow", id = 18661, minimum = 630, name = AceLib.API.Items.GetNameByID(18661) },
	{ alias = "Cedar Fishing Rod", id = 11911, minimum = 160, name = AceLib.API.Items.GetNameByID(11911) },
	{ alias = "Larch Bracelets", id = 19730, minimum = 420, name = AceLib.API.Items.GetNameByID(19730) },
	{ alias = "Zelkova Ring", id = 19751, minimum = 650, name = AceLib.API.Items.GetNameByID(19751) },
	{ alias = "Titanium Lance", id = 10606, minimum = 220, name = AceLib.API.Items.GetNameByID(10606) },
	{ alias = "Beech Rod", id = 18041, minimum = 300, name = AceLib.API.Items.GetNameByID(18041) },
	{ alias = "Titanium Fork", id = 10607, minimum = 270, name = AceLib.API.Items.GetNameByID(10607) },
	{ alias = "Stiperstone Grinding Wheel", id = 19520, minimum = 370, name = AceLib.API.Items.GetNameByID(19520) },
	{ alias = "Slate Grinding Wheel", id = 19541, minimum = 510, name = AceLib.API.Items.GetNameByID(19541) },
	{ alias = "Pine Fishing Rod", id = 19537, minimum = 510, name = AceLib.API.Items.GetNameByID(19537) },
	{ alias = "Birch Longbow", id = 10614, minimum = 320, name = AceLib.API.Items.GetNameByID(10614) },
	{ alias = "Pine Composite Bow", id = 18349, minimum = 470, name = AceLib.API.Items.GetNameByID(18349) },
	{ alias = "Persimmon Ring", id = 19741, minimum = 610, name = AceLib.API.Items.GetNameByID(19741) },
	{ alias = "Persimmon Cane", id = 18509, minimum = 560, name = AceLib.API.Items.GetNameByID(18509) },
	{ alias = "Larch Necklace", id = 19729, minimum = 420, name = AceLib.API.Items.GetNameByID(19729) },
	{ alias = "Persimmon Earrings", id = 19738, minimum = 610, name = AceLib.API.Items.GetNameByID(19738) },
	{ alias = "Cedar Crook", id = 10634, minimum = 130, name = AceLib.API.Items.GetNameByID(10634) },
	{ alias = "Dark Chestnut Spinning Wheel", id = 11936, minimum = 270, name = AceLib.API.Items.GetNameByID(11936) },
	{ alias = "Mythrite Trident", id = 10604, minimum = 130, name = AceLib.API.Items.GetNameByID(10604) },
	{ alias = "Larch Spinning Wheel", id = 19522, minimum = 370, name = AceLib.API.Items.GetNameByID(19522) },
	{ alias = "Holy Cedar Spinning Wheel", id = 11935, minimum = 190, name = AceLib.API.Items.GetNameByID(11935) },
	{ alias = "Almandine Grinding Wheel", id = 19583, minimum = 660, name = AceLib.API.Items.GetNameByID(19583) },
	{ alias = "Dark Chestnut Fishing Rod", id = 11912, minimum = 240, name = AceLib.API.Items.GetNameByID(11912) },
	{ alias = "Larch Ring", id = 19731, minimum = 420, name = AceLib.API.Items.GetNameByID(19731) },
	{ alias = "Doman Iron Lance", id = 18348, minimum = 470, name = AceLib.API.Items.GetNameByID(18348) },
	{ alias = "Larch Earrings", id = 19728, minimum = 420, name = AceLib.API.Items.GetNameByID(19728) },
	{ alias = "Larch Composite Bow", id = 18193, minimum = 370, name = AceLib.API.Items.GetNameByID(18193) },
	{ alias = "Zelkova Fishing Rod", id = 19579, minimum = 660, name = AceLib.API.Items.GetNameByID(19579) },
	{ alias = "Hallowed Chestnut Mask of Casting", id = 10925, minimum = 270, name = AceLib.API.Items.GetNameByID(10925) },
	{ alias = "Zelkova Bracelets", id = 19750, minimum = 650, name = AceLib.API.Items.GetNameByID(19750) },
	{ alias = "Birch Lumber", id = 12583, minimum = 360, name = AceLib.API.Items.GetNameByID(12583) },
	-- Blacksmith
	{ alias = "Titanium Creasing Knife", id = 11888, minimum = 240, name = AceLib.API.Items.GetNameByID(11888) },
	{ alias = "Titanium Ingot", id = 12525, minimum = 330, name = AceLib.API.Items.GetNameByID(12525) },
	{ alias = "Doman Steel Main Gauches", id = 18506, minimum = 610, name = AceLib.API.Items.GetNameByID(18506) },
	{ alias = "Doman Steel Culinary Knife", id = 19566, minimum = 610, name = AceLib.API.Items.GetNameByID(19566) },
	{ alias = "Doman Iron Greatsword", id = 18351, minimum = 510, name = AceLib.API.Items.GetNameByID(18351) },
	{ alias = "Adamantite Winglet", id = 10591, minimum = 400, name = AceLib.API.Items.GetNameByID(10591) },
	{ alias = "Mythrite Halfheart Saw", id = 11871, minimum = 160, name = AceLib.API.Items.GetNameByID(11871) },
	{ alias = "High Steel Claw Hammer", id = 19517, minimum = 370, name = AceLib.API.Items.GetNameByID(19517) },
	{ alias = "Hardsilver Hatchet", id = 11909, minimum = 290, name = AceLib.API.Items.GetNameByID(11909) },
	{ alias = "Adamantite Scythe", id = 11953, minimum = 350, name = AceLib.API.Items.GetNameByID(11953) },
	{ alias = "Adamantite Knives", id = 10620, minimum = 320, name = AceLib.API.Items.GetNameByID(10620) },
	{ alias = "Mythrite Flametongue", id = 10587, minimum = 190, name = AceLib.API.Items.GetNameByID(10587) },
	{ alias = "High Steel Longsword", id = 18189, minimum = 420, name = AceLib.API.Items.GetNameByID(18189) },
	{ alias = "Molybdenum File", id = 19581, minimum = 660, name = AceLib.API.Items.GetNameByID(19581) },
	{ alias = "Doman Iron Culverin", id = 18352, minimum = 510, name = AceLib.API.Items.GetNameByID(18352) },
	{ alias = "Molybdenum Pliers", id = 19582, minimum = 660, name = AceLib.API.Items.GetNameByID(19582) },
	{ alias = "Mythrite Katzbalger", id = 10586, minimum = 130, name = AceLib.API.Items.GetNameByID(10586) },
	{ alias = "Adamantite Awl", id = 11933, minimum = 350, name = AceLib.API.Items.GetNameByID(11933) },
	{ alias = "High Steel Scythe", id = 19526, minimum = 370, name = AceLib.API.Items.GetNameByID(19526) },
	{ alias = "Mythrite Pliers", id = 11923, minimum = 190, name = AceLib.API.Items.GetNameByID(11923) },
	{ alias = "Folded High Steel Knuckles", id = 18190, minimum = 420, name = AceLib.API.Items.GetNameByID(18190) },
	{ alias = "Titanium Greatsword", id = 10625, minimum = 290, name = AceLib.API.Items.GetNameByID(10625) },
	{ alias = "Doman Steel Pliers", id = 19561, minimum = 610, name = AceLib.API.Items.GetNameByID(19561) },
	{ alias = "Durium Texture Hammer", id = 19530, minimum = 470, name = AceLib.API.Items.GetNameByID(19530) },
	{ alias = "Adamantite Dolabra", id = 11906, minimum = 400, name = AceLib.API.Items.GetNameByID(11906) },
	{ alias = "Adamantite Culinary Knife", id = 11945, minimum = 350, name = AceLib.API.Items.GetNameByID(11945) },
	{ alias = "Titanium-barreled Snaphance", id = 10631, minimum = 290, name = AceLib.API.Items.GetNameByID(10631) },
	{ alias = "Molybdenum Halfheart Saw", id = 19569, minimum = 650, name = AceLib.API.Items.GetNameByID(19569) },
	{ alias = "Titanium Pugiones", id = 10618, minimum = 220, name = AceLib.API.Items.GetNameByID(10618) },
	{ alias = "Titanium Nugget", id = 12524, minimum = 250, name = AceLib.API.Items.GetNameByID(12524) },
	{ alias = "Adamantite File", id = 11921, minimum = 350, name = AceLib.API.Items.GetNameByID(11921) },
	{ alias = "Titanium Mortar", id = 11940, minimum = 270, name = AceLib.API.Items.GetNameByID(11940) },
	{ alias = "Titanium Axe", id = 10600, minimum = 220, name = AceLib.API.Items.GetNameByID(10600) },
	{ alias = "Titanium Knuckles", id = 10595, minimum = 290, name = AceLib.API.Items.GetNameByID(10595) },
	{ alias = "Titanium Cross-pein Hammer", id = 11876, minimum = 240, name = AceLib.API.Items.GetNameByID(11876) },
	{ alias = "Adamantite Bill", id = 10602, minimum = 320, name = AceLib.API.Items.GetNameByID(10602) },
	{ alias = "Mythrite Lapidary Hammer", id = 11883, minimum = 160, name = AceLib.API.Items.GetNameByID(11883) },
	{ alias = "Adamantite Sledgehammer", id = 11949, minimum = 350, name = AceLib.API.Items.GetNameByID(11949) },
	{ alias = "High Steel Doming Hammer", id = 19508, minimum = 320, name = AceLib.API.Items.GetNameByID(19508) },
	{ alias = "Doman Iron Uchigatana", id = 18358, minimum = 510, name = AceLib.API.Items.GetNameByID(18358) },
	{ alias = "Mythrite Zweihander", id = 10623, minimum = 190, name = AceLib.API.Items.GetNameByID(10623) },
	{ alias = "Titanium Longsword", id = 10589, minimum = 290, name = AceLib.API.Items.GetNameByID(10589) },
	{ alias = "Adamantite Jamadhars", id = 10596, minimum = 320, name = AceLib.API.Items.GetNameByID(10596) },
	{ alias = "Mythrite-barreled Musketoon", id = 10629, minimum = 190, name = AceLib.API.Items.GetNameByID(10629) },
	{ alias = "High Steel Dolabra", id = 19514, minimum = 320, name = AceLib.API.Items.GetNameByID(19514) },
	{ alias = "Molybdenum Longblade", id = 18663, minimum = 630, name = AceLib.API.Items.GetNameByID(18663) },
	{ alias = "Mythrite Patas", id = 10592, minimum = 130, name = AceLib.API.Items.GetNameByID(10592) },
	{ alias = "Mythrite-barreled Arquebus", id = 10628, minimum = 130, name = AceLib.API.Items.GetNameByID(10628) },
	{ alias = "High Steel Main Gauches", id = 18038, minimum = 300, name = AceLib.API.Items.GetNameByID(18038) },
	{ alias = "Mythrite War Axe", id = 10598, minimum = 130, name = AceLib.API.Items.GetNameByID(10598) },
	{ alias = "Doman Iron Hatchet", id = 19536, minimum = 470, name = AceLib.API.Items.GetNameByID(19536) },
	{ alias = "Adamantite Broadsword", id = 10590, minimum = 320, name = AceLib.API.Items.GetNameByID(10590) },
	{ alias = "High Steel Tachi", id = 18046, minimum = 300, name = AceLib.API.Items.GetNameByID(18046) },
	{ alias = "Molybdenum Lump Hammer", id = 19570, minimum = 650, name = AceLib.API.Items.GetNameByID(19570) },
	{ alias = "Hardsilver Saw", id = 11872, minimum = 240, name = AceLib.API.Items.GetNameByID(11872) },
	{ alias = "High Steel Guillotine", id = 18039, minimum = 300, name = AceLib.API.Items.GetNameByID(18039) },
	{ alias = "Doman Steel Claw Hammer", id = 19559, minimum = 610, name = AceLib.API.Items.GetNameByID(19559) },
	{ alias = "Hardsilver Dolabra", id = 11904, minimum = 240, name = AceLib.API.Items.GetNameByID(11904) },
	{ alias = "Adamantite Revolver", id = 10632, minimum = 320, name = AceLib.API.Items.GetNameByID(10632) },
	{ alias = "Mythrite Scythe", id = 11951, minimum = 190, name = AceLib.API.Items.GetNameByID(11951) },
	{ alias = "Mythrite Pugiones", id = 10616, minimum = 130, name = AceLib.API.Items.GetNameByID(10616) },
	{ alias = "Titanium Culinary Knife", id = 11944, minimum = 270, name = AceLib.API.Items.GetNameByID(11944) },
	{ alias = "High Steel Awl", id = 19521, minimum = 370, name = AceLib.API.Items.GetNameByID(19521) },
	{ alias = "High Steel Pliers", id = 19519, minimum = 370, name = AceLib.API.Items.GetNameByID(19519) },
	{ alias = "Mythrite Jamadhars", id = 10593, minimum = 190, name = AceLib.API.Items.GetNameByID(10593) },
	{ alias = "Molybdenum War Axe", id = 18659, minimum = 630, name = AceLib.API.Items.GetNameByID(18659) },
	{ alias = "Mythrite Claymore", id = 10622, minimum = 130, name = AceLib.API.Items.GetNameByID(10622) },
	{ alias = "Molybdenum Pickaxe", id = 19577, minimum = 650, name = AceLib.API.Items.GetNameByID(19577) },
	{ alias = "Doman Iron Awl", id = 19542, minimum = 510, name = AceLib.API.Items.GetNameByID(19542) },
	{ alias = "Molybdenum Scythe", id = 19589, minimum = 660, name = AceLib.API.Items.GetNameByID(19589) },
	{ alias = "Molybdenum Sledgehammer", id = 19588, minimum = 660, name = AceLib.API.Items.GetNameByID(19588) },
	{ alias = "Aurum Regis Creasing Knife", id = 11890, minimum = 400, name = AceLib.API.Items.GetNameByID(11890) },
	{ alias = "Adamantite Zweihander", id = 10626, minimum = 320, name = AceLib.API.Items.GetNameByID(10626) },
	{ alias = "Molybdenum Mortar", id = 19586, minimum = 660, name = AceLib.API.Items.GetNameByID(19586) },
	{ alias = "Molybdenum Knuckles", id = 18658, minimum = 630, name = AceLib.API.Items.GetNameByID(18658) },
	{ alias = "Titanium Sledgehammer", id = 11948, minimum = 270, name = AceLib.API.Items.GetNameByID(11948) },
	{ alias = "Molybdenum Culinary Knife", id = 19587, minimum = 660, name = AceLib.API.Items.GetNameByID(19587) },
	{ alias = "Adamantite Hatchet", id = 11910, minimum = 400, name = AceLib.API.Items.GetNameByID(11910) },
	{ alias = "Adamantite Claw Hammer", id = 11917, minimum = 350, name = AceLib.API.Items.GetNameByID(11917) },
	{ alias = "Adamantite Saw", id = 11874, minimum = 400, name = AceLib.API.Items.GetNameByID(11874) },
	{ alias = "Adamantite Mortar", id = 11941, minimum = 350, name = AceLib.API.Items.GetNameByID(11941) },
	{ alias = "Molybdenum Claw Hammer", id = 19580, minimum = 660, name = AceLib.API.Items.GetNameByID(19580) },
	{ alias = "Adamantite Headsman's Axe", id = 10603, minimum = 400, name = AceLib.API.Items.GetNameByID(10603) },
	{ alias = "High Steel Battleaxe", id = 18191, minimum = 420, name = AceLib.API.Items.GetNameByID(18191) },
	{ alias = "Doman Steel Longsword", id = 18501, minimum = 560, name = AceLib.API.Items.GetNameByID(18501) },
	{ alias = "Molybdenum Awl", id = 19584, minimum = 660, name = AceLib.API.Items.GetNameByID(19584) },
	{ alias = "Koppranickel Ornamental Hammer", id = 19509, minimum = 320, name = AceLib.API.Items.GetNameByID(19509) },
	{ alias = "High Steel Knuckles", id = 18034, minimum = 300, name = AceLib.API.Items.GetNameByID(18034) },
	{ alias = "Adamantite Pliers", id = 11925, minimum = 350, name = AceLib.API.Items.GetNameByID(11925) },
	{ alias = "Doman Steel Patas", id = 18502, minimum = 560, name = AceLib.API.Items.GetNameByID(18502) },
	{ alias = "High Steel Headsman's Axe", id = 18035, minimum = 300, name = AceLib.API.Items.GetNameByID(18035) },
	{ alias = "High Steel Culinary Knife", id = 19524, minimum = 370, name = AceLib.API.Items.GetNameByID(19524) },
	{ alias = "Titanium Ball-pein Hammer", id = 11880, minimum = 240, name = AceLib.API.Items.GetNameByID(11880) },
	{ alias = "Doman Steel Sledgehammer", id = 19567, minimum = 610, name = AceLib.API.Items.GetNameByID(19567) },
	{ alias = "Doman Steel Raising Hammer", id = 19550, minimum = 560, name = AceLib.API.Items.GetNameByID(19550) },
	{ alias = "Doman Iron Halfheart Saw", id = 19527, minimum = 470, name = AceLib.API.Items.GetNameByID(19527) },
	{ alias = "Molybdenum Creasing Knife", id = 19573, minimum = 650, name = AceLib.API.Items.GetNameByID(19573) },
	{ alias = "Adamantite-barreled Culverin", id = 10633, minimum = 400, name = AceLib.API.Items.GetNameByID(10633) },
	{ alias = "Hardsilver Texture Hammer", id = 11884, minimum = 240, name = AceLib.API.Items.GetNameByID(11884) },
	{ alias = "Adamantite Greatsword", id = 10627, minimum = 400, name = AceLib.API.Items.GetNameByID(10627) },
	{ alias = "Doman Iron File", id = 19539, minimum = 510, name = AceLib.API.Items.GetNameByID(19539) },
	-- Armorer
	{ alias = "Titanium Sollerets of Fending", id = 10707, minimum = 240, name = AceLib.API.Items.GetNameByID(10707) },
	{ alias = "Mythrite Alembic", id = 11895, minimum = 160, name = AceLib.API.Items.GetNameByID(11895) },
	{ alias = "Doman Iron Greaves of Fending", id = 18365, minimum = 470, name = AceLib.API.Items.GetNameByID(18365) },
	{ alias = "Mythrite Hauberk of Fending", id = 10677, minimum = 130, name = AceLib.API.Items.GetNameByID(10677) },
	{ alias = "Mythrite Hauberk of Maiming", id = 10719, minimum = 130, name = AceLib.API.Items.GetNameByID(10719) },
	{ alias = "High Steel Hoplon", id = 18048, minimum = 300, name = AceLib.API.Items.GetNameByID(18048) },
	{ alias = "Adamantite Tassets of Fending", id = 10695, minimum = 320, name = AceLib.API.Items.GetNameByID(10695) },
	{ alias = "Heavy Adamantite Gauntlets of Fending", id = 10689, minimum = 400, name = AceLib.API.Items.GetNameByID(10689) },
	{ alias = "Molybdenum Plate Belt of Fending", id = 18678, minimum = 630, name = AceLib.API.Items.GetNameByID(18678) },
	{ alias = "Adamantite Gauntlets of Fending", id = 10688, minimum = 320, name = AceLib.API.Items.GetNameByID(10688) },
	{ alias = "High Steel Scale Mail of Maiming", id = 18056, minimum = 320, name = AceLib.API.Items.GetNameByID(18056) },
	{ alias = "Adamantite Alembic", id = 11898, minimum = 400, name = AceLib.API.Items.GetNameByID(11898) },
	{ alias = "Adamantite Mail of Maiming", id = 10724, minimum = 400, name = AceLib.API.Items.GetNameByID(10724) },
	{ alias = "Mandragoras Frypan", id = 11901, minimum = 290, name = AceLib.API.Items.GetNameByID(11901) },
	{ alias = "Adamantite Circlet of Fending", id = 10675, minimum = 350, name = AceLib.API.Items.GetNameByID(10675) },
	{ alias = "Molybdenum Tassets of Maiming", id = 18918, minimum = 660, name = AceLib.API.Items.GetNameByID(18918) },
	{ alias = "Tigerskin Coat of Maiming", id = 18368, minimum = 510, name = AceLib.API.Items.GetNameByID(18368) },
	{ alias = "Doman Iron Frypan", id = 19534, minimum = 510, name = AceLib.API.Items.GetNameByID(19534) },
	{ alias = "Doman Steel Gauntlets of Fending", id = 18519, minimum = 560, name = AceLib.API.Items.GetNameByID(18519) },
	{ alias = "Adamantite Armor of Maiming", id = 10723, minimum = 350, name = AceLib.API.Items.GetNameByID(10723) },
	{ alias = "Molybdenum Plate Belt of Maiming", id = 18684, minimum = 630, name = AceLib.API.Items.GetNameByID(18684) },
	{ alias = "Frypan Caliente", id = 11899, minimum = 160, name = AceLib.API.Items.GetNameByID(11899) },
	{ alias = "Mythrite Sallet of Fending", id = 10670, minimum = 110, name = AceLib.API.Items.GetNameByID(10670) },
	{ alias = "High Steel Gauntlets of Maiming", id = 18213, minimum = 420, name = AceLib.API.Items.GetNameByID(18213) },
	{ alias = "Adamantite Frypan", id = 11902, minimum = 400, name = AceLib.API.Items.GetNameByID(11902) },
	{ alias = "Adamantite Leg Guards of Maiming", id = 10752, minimum = 400, name = AceLib.API.Items.GetNameByID(10752) },
	{ alias = "Molybdenum Alembic", id = 19575, minimum = 660, name = AceLib.API.Items.GetNameByID(19575) },
	{ alias = "Titanium Sallet of Maiming", id = 10714, minimum = 220, name = AceLib.API.Items.GetNameByID(10714) },
	{ alias = "Adamantite Plate Belt of Fending", id = 10696, minimum = 350, name = AceLib.API.Items.GetNameByID(10696) },
	{ alias = "Titanium Hoplon", id = 10667, minimum = 290, name = AceLib.API.Items.GetNameByID(10667) },
	{ alias = "Doman Iron Gauntlets of Fending", id = 18363, minimum = 470, name = AceLib.API.Items.GetNameByID(18363) },
	{ alias = "Doman Steel Shield", id = 18516, minimum = 610, name = AceLib.API.Items.GetNameByID(18516) },
	{ alias = "High Steel Mail of Maiming", id = 18212, minimum = 420, name = AceLib.API.Items.GetNameByID(18212) },
	{ alias = "Molybdenum Greaves of Fending", id = 18677, minimum = 650, name = AceLib.API.Items.GetNameByID(18677) },
	{ alias = "Adamantite Gauntlets of Maiming", id = 10730, minimum = 320, name = AceLib.API.Items.GetNameByID(10730) },
	{ alias = "Adamantite Helm of Maiming", id = 10716, minimum = 320, name = AceLib.API.Items.GetNameByID(10716) },
	{ alias = "Adamantite Sabatons of Maiming", id = 10751, minimum = 320, name = AceLib.API.Items.GetNameByID(10751) },
	{ alias = "Doman Steel Greaves of Scouting", id = 18545, minimum = 560, name = AceLib.API.Items.GetNameByID(18545) },
	{ alias = "Molybdenum Armguards of Striking", id = 18687, minimum = 650, name = AceLib.API.Items.GetNameByID(18687) },
	{ alias = "Mythrite Sabatons of Maiming", id = 10747, minimum = 130, name = AceLib.API.Items.GetNameByID(10747) },
	{ alias = "Mythrite Tassets of Maiming", id = 10733, minimum = 110, name = AceLib.API.Items.GetNameByID(10733) },
	{ alias = "Adamantite Hoplon", id = 10669, minimum = 400, name = AceLib.API.Items.GetNameByID(10669) },
	{ alias = "Mythrite Scutum", id = 10664, minimum = 130, name = AceLib.API.Items.GetNameByID(10664) },
	{ alias = "Adamantite Lorica of Fending", id = 10682, minimum = 400, name = AceLib.API.Items.GetNameByID(10682) },
	{ alias = "Adamantite Sabatons of Fending", id = 10709, minimum = 320, name = AceLib.API.Items.GetNameByID(10709) },
	{ alias = "Adamantite Tassets of Maiming", id = 10737, minimum = 320, name = AceLib.API.Items.GetNameByID(10737) },
	{ alias = "Adamantite Scutum", id = 10668, minimum = 350, name = AceLib.API.Items.GetNameByID(10668) },
	{ alias = "Molybdenum Headgear of Maiming", id = 18679, minimum = 630, name = AceLib.API.Items.GetNameByID(18679) },
	{ alias = "Molybdenum Armguards of Maiming", id = 18681, minimum = 650, name = AceLib.API.Items.GetNameByID(18681) },
	{ alias = "Adamantite Armor of Fending", id = 10681, minimum = 350, name = AceLib.API.Items.GetNameByID(10681) },
	{ alias = "Doman Steel Gauntlets of Striking", id = 18531, minimum = 560, name = AceLib.API.Items.GetNameByID(18531) },
	{ alias = "Titanium Vambraces of Scouting", id = 10855, minimum = 270, name = AceLib.API.Items.GetNameByID(10855) },
	{ alias = "Adamantite Chain Hose of Fending", id = 10702, minimum = 350, name = AceLib.API.Items.GetNameByID(10702) },
	{ alias = "Titanium Mask of Scouting", id = 10840, minimum = 220, name = AceLib.API.Items.GetNameByID(10840) },
	{ alias = "Titanium Tassets of Fending", id = 10694, minimum = 270, name = AceLib.API.Items.GetNameByID(10694) },
	{ alias = "Titanium Plate Belt of Fending", id = 10693, minimum = 190, name = AceLib.API.Items.GetNameByID(10693) },
	{ alias = "Titanium Vambraces of Maiming", id = 10729, minimum = 270, name = AceLib.API.Items.GetNameByID(10729) },
	{ alias = "Titanium Mail of Striking", id = 10764, minimum = 290, name = AceLib.API.Items.GetNameByID(10764) },
	{ alias = "Titanium Kite Shield", id = 10666, minimum = 240, name = AceLib.API.Items.GetNameByID(10666) },
	{ alias = "Titanium Headgear of Striking", id = 10757, minimum = 270, name = AceLib.API.Items.GetNameByID(10757) },
	{ alias = "Aurum Regis Sollerets of Healing", id = 10920, minimum = 400, name = AceLib.API.Items.GetNameByID(10920) },
	{ alias = "Titanium Cuirass of Maiming", id = 10721, minimum = 240, name = AceLib.API.Items.GetNameByID(10721) },
	{ alias = "Titanium Alembic", id = 11897, minimum = 290, name = AceLib.API.Items.GetNameByID(11897) },
	{ alias = "Mythrite Sabatons of Fending", id = 10705, minimum = 130, name = AceLib.API.Items.GetNameByID(10705) },
	{ alias = "Mythrite Gauntlets of Maiming", id = 10726, minimum = 130, name = AceLib.API.Items.GetNameByID(10726) },
	{ alias = "Mythrite Bladed Lantern Shield", id = 10665, minimum = 190, name = AceLib.API.Items.GetNameByID(10665) },
	{ alias = "Molybdenum Tassets of Fending", id = 18912, minimum = 660, name = AceLib.API.Items.GetNameByID(18912) },
	{ alias = "Molybdenum Headgear of Fending", id = 18673, minimum = 630, name = AceLib.API.Items.GetNameByID(18673) },
	{ alias = "Molybdenum Frypan", id = 19576, minimum = 660, name = AceLib.API.Items.GetNameByID(19576) },
	{ alias = "High Steel Bomb Frypan", id = 19513, minimum = 320, name = AceLib.API.Items.GetNameByID(19513) },
	{ alias = "Doman Steel Tabard of Maiming", id = 18524, minimum = 610, name = AceLib.API.Items.GetNameByID(18524) },
	{ alias = "High Steel Plate Belt of Maiming", id = 18216, minimum = 370, name = AceLib.API.Items.GetNameByID(18216) },
	{ alias = "Adamantite Helm of Fending", id = 10674, minimum = 320, name = AceLib.API.Items.GetNameByID(10674) },
	{ alias = "Doman Steel Frypan Caliente", id = 19555, minimum = 610, name = AceLib.API.Items.GetNameByID(19555) },
	{ alias = "High Steel Sollerets of Fending", id = 18209, minimum = 420, name = AceLib.API.Items.GetNameByID(18209) },
	{ alias = "High Steel Barbut of Fending", id = 18205, minimum = 370, name = AceLib.API.Items.GetNameByID(18205) },
	{ alias = "Doman Steel Armet of Fending", id = 18517, minimum = 610, name = AceLib.API.Items.GetNameByID(18517) },
	{ alias = "High Steel Armguards of Fending", id = 18051, minimum = 320, name = AceLib.API.Items.GetNameByID(18051) },
	{ alias = "Doman Iron Alembic", id = 19533, minimum = 510, name = AceLib.API.Items.GetNameByID(19533) },
	{ alias = "Hardsilver Alembic", id = 11896, minimum = 220, name = AceLib.API.Items.GetNameByID(11896) },
	{ alias = "Doman Iron Tassets of Maiming", id = 18372, minimum = 470, name = AceLib.API.Items.GetNameByID(18372) },
	{ alias = "Doman Steel Alembic", id = 19554, minimum = 610, name = AceLib.API.Items.GetNameByID(19554) },
	{ alias = "Adamantite Chain Hose of Maiming", id = 10744, minimum = 350, name = AceLib.API.Items.GetNameByID(10744) },
	{ alias = "Titanium Frypan", id = 11900, minimum = 220, name = AceLib.API.Items.GetNameByID(11900) },
	-- Goldsmith
	{ alias = "Aurum Regis Staff", id = 10645, minimum = 400, name = AceLib.API.Items.GetNameByID(10645) },
	{ alias = "Koppranickel Bracelet of Fending", id = 18257, minimum = 370, name = AceLib.API.Items.GetNameByID(18257) },
	{ alias = "Azurite Choker of Slaying", id = 18565, minimum = 610, name = AceLib.API.Items.GetNameByID(18565) },
	{ alias = "Aurum Regis Orrery", id = 10662, minimum = 350, name = AceLib.API.Items.GetNameByID(10662) },
	{ alias = "Mythrite Circlet of Striking", id = 10754, minimum = 130, name = AceLib.API.Items.GetNameByID(10754) },
	{ alias = "Mythrite Goggles of Gathering", id = 11983, minimum = 130, name = AceLib.API.Items.GetNameByID(11983) },
	{ alias = "Aurum Regis Bracelet of Slaying", id = 10998, minimum = 320, name = AceLib.API.Items.GetNameByID(10998) },
	{ alias = "Molybdenum Earring of Casting", id = 18719, minimum = 630, name = AceLib.API.Items.GetNameByID(18719) },
	{ alias = "Griffin Talon Needle", id = 11894, minimum = 400, name = AceLib.API.Items.GetNameByID(11894) },
	{ alias = "Bladed Steel Jig", id = 12707, minimum = 400, name = AceLib.API.Items.GetNameByID(12707) },
	{ alias = "Koppranickel Necklace of Casting", id = 18256, minimum = 420, name = AceLib.API.Items.GetNameByID(18256) },
	{ alias = "Azurite Earrings of Casting", id = 18563, minimum = 610, name = AceLib.API.Items.GetNameByID(18563) },
	{ alias = "Citrine Choker of Casting", id = 11065, minimum = 350, name = AceLib.API.Items.GetNameByID(11065) },
	{ alias = "Mythrite Needle", id = 11891, minimum = 160, name = AceLib.API.Items.GetNameByID(11891) },
	{ alias = "Muudhorn Ring of Slaying", id = 18263, minimum = 370, name = AceLib.API.Items.GetNameByID(18263) },
	{ alias = "Mormorion Ring of Slaying", id = 11008, minimum = 220, name = AceLib.API.Items.GetNameByID(11008) },
	{ alias = "Palladium Ring of Aiming", id = 18732, minimum = 630, name = AceLib.API.Items.GetNameByID(18732) },
	{ alias = "Mythrite Necklace of Aiming", id = 11013, minimum = 190, name = AceLib.API.Items.GetNameByID(11013) },
	{ alias = "Triphane Bracelet of Healing", id = 18104, minimum = 300, name = AceLib.API.Items.GetNameByID(18104) },
	{ alias = "Triphane Ring of Casting", id = 18110, minimum = 300, name = AceLib.API.Items.GetNameByID(18110) },
	{ alias = "Opal Earrings of Fending", id = 10979, minimum = 290, name = AceLib.API.Items.GetNameByID(10979) },
	{ alias = "Koppranickel Bracelet of Healing", id = 18260, minimum = 370, name = AceLib.API.Items.GetNameByID(18260) },
	{ alias = "Dragon Fang Needle", id = 11893, minimum = 270, name = AceLib.API.Items.GetNameByID(11893) },
	{ alias = "Citrine Choker of Aiming", id = 11017, minimum = 350, name = AceLib.API.Items.GetNameByID(11017) },
	{ alias = "Triphane Ring of Fending", id = 18106, minimum = 300, name = AceLib.API.Items.GetNameByID(18106) },
	{ alias = "Aurum Regis Planisphere", id = 10663, minimum = 400, name = AceLib.API.Items.GetNameByID(10663) },
	{ alias = "Chrysolite Earrings of Fending", id = 10981, minimum = 400, name = AceLib.API.Items.GetNameByID(10981) },
	{ alias = "Chrysolite Bracelet of Slaying", id = 10999, minimum = 400, name = AceLib.API.Items.GetNameByID(10999) },
	{ alias = "Yeti Staff", id = 10640, minimum = 130, name = AceLib.API.Items.GetNameByID(10640) },
	{ alias = "Aurum Regis Earrings of Casting", id = 11076, minimum = 320, name = AceLib.API.Items.GetNameByID(11076) },
	{ alias = "Azurite Bracelet of Aiming", id = 18571, minimum = 560, name = AceLib.API.Items.GetNameByID(18571) },
	{ alias = "Yeti Fang Ring of Slaying", id = 11007, minimum = 190, name = AceLib.API.Items.GetNameByID(11007) },
	{ alias = "Star Spinel Earrings of Casting", id = 18407, minimum = 510, name = AceLib.API.Items.GetNameByID(18407) },
	{ alias = "Imperial Jade Necklace of Aiming", id = 18956, minimum = 660, name = AceLib.API.Items.GetNameByID(18956) },
	{ alias = "Star Spinel Choker of Slaying", id = 18409, minimum = 510, name = AceLib.API.Items.GetNameByID(18409) },
	{ alias = "Triphane Ring of Aiming", id = 18108, minimum = 300, name = AceLib.API.Items.GetNameByID(18108) },
	{ alias = "Chrysolite Ring of Aiming", id = 11035, minimum = 400, name = AceLib.API.Items.GetNameByID(11035) },
	{ alias = "Citrine", id = 12547, minimum = 370, name = AceLib.API.Items.GetNameByID(12547) },
	{ alias = "Imperial Jade Necklace of Fending", id = 18954, minimum = 660, name = AceLib.API.Items.GetNameByID(18954) },
	{ alias = "Triphane Earrings of Fending", id = 18091, minimum = 320, name = AceLib.API.Items.GetNameByID(18091) },
	{ alias = "Azurite Ring of Healing", id = 18577, minimum = 560, name = AceLib.API.Items.GetNameByID(18577) },
	{ alias = "Koppranickel Necklace of Aiming", id = 18254, minimum = 420, name = AceLib.API.Items.GetNameByID(18254) },
	{ alias = "Hardsilver Needle", id = 11892, minimum = 220, name = AceLib.API.Items.GetNameByID(11892) },
	{ alias = "Aurum Regis Bracelet of Fending", id = 10974, minimum = 320, name = AceLib.API.Items.GetNameByID(10974) },
	{ alias = "Hardsilver Earrings of Healing", id = 11050, minimum = 240, name = AceLib.API.Items.GetNameByID(11050) },
	{ alias = "Koppranickel Earrings of Healing", id = 18250, minimum = 420, name = AceLib.API.Items.GetNameByID(18250) },
	{ alias = "Palladium Bracelet of Slaying", id = 18726, minimum = 630, name = AceLib.API.Items.GetNameByID(18726) },
	{ alias = "Triphane Earrings of Aiming", id = 18093, minimum = 320, name = AceLib.API.Items.GetNameByID(18093) },
	{ alias = "Griffin Talon Ring of Slaying", id = 11010, minimum = 350, name = AceLib.API.Items.GetNameByID(11010) },
	{ alias = "Koppranickel Earrings of Slaying", id = 18248, minimum = 420, name = AceLib.API.Items.GetNameByID(18248) },
	{ alias = "Triphane Choker of Healing", id = 18099, minimum = 320, name = AceLib.API.Items.GetNameByID(18099) },
	{ alias = "Star Spinel Ring of Fending", id = 18418, minimum = 470, name = AceLib.API.Items.GetNameByID(18418) },
	{ alias = "Star Spinel Ring of Aiming", id = 18420, minimum = 470, name = AceLib.API.Items.GetNameByID(18420) },
	{ alias = "Star Spinel Earrings of Healing", id = 18406, minimum = 510, name = AceLib.API.Items.GetNameByID(18406) },
	{ alias = "Yeti Fang Ring of Casting", id = 11079, minimum = 190, name = AceLib.API.Items.GetNameByID(11079) },
	{ alias = "Aurum Regis Bracelet of Casting", id = 11070, minimum = 320, name = AceLib.API.Items.GetNameByID(11070) },
	{ alias = "Dual-plated Koppranickel Planisphere", id = 18201, minimum = 420, name = AceLib.API.Items.GetNameByID(18201) },
	{ alias = "Agate Ring of Fending", id = 10982, minimum = 110, name = AceLib.API.Items.GetNameByID(10982) },
	{ alias = "Opal Earrings of Aiming", id = 11027, minimum = 290, name = AceLib.API.Items.GetNameByID(11027) },
	{ alias = "Yeti Fang Earrings", id = 12017, minimum = 160, name = AceLib.API.Items.GetNameByID(12017) },
	{ alias = "Star Spinel Bracelet of Healing", id = 18416, minimum = 470, name = AceLib.API.Items.GetNameByID(18416) },
	{ alias = "Agate Ring of Aiming", id = 11030, minimum = 110, name = AceLib.API.Items.GetNameByID(11030) },
	{ alias = "Palladium Planisphere", id = 18669, minimum = 650, name = AceLib.API.Items.GetNameByID(18669) },
	{ alias = "Hardsilver Monocle of Healing", id = 10882, minimum = 220, name = AceLib.API.Items.GetNameByID(10882) },
	{ alias = "Aurum Regis Longpole", id = 10644, minimum = 350, name = AceLib.API.Items.GetNameByID(10644) },
	{ alias = "Aurum Regis Earrings of Healing", id = 11052, minimum = 320, name = AceLib.API.Items.GetNameByID(11052) },
	{ alias = "Star Ruby", id = 12544, minimum = 260, name = AceLib.API.Items.GetNameByID(12544) },
	{ alias = "Palladium Ring of Fending", id = 18730, minimum = 630, name = AceLib.API.Items.GetNameByID(18730) },
	{ alias = "Opal Ring of Slaying", id = 11009, minimum = 270, name = AceLib.API.Items.GetNameByID(11009) },
	{ alias = "Palladium Needle", id = 19574, minimum = 650, name = AceLib.API.Items.GetNameByID(19574) },
	{ alias = "Hardsilver Earrings of Fending", id = 10978, minimum = 240, name = AceLib.API.Items.GetNameByID(10978) },
	{ alias = "Imperial Jade Earrings of Slaying", id = 18950, minimum = 660, name = AceLib.API.Items.GetNameByID(18950) },
	{ alias = "Palladium Choker of Healing", id = 18723, minimum = 630, name = AceLib.API.Items.GetNameByID(18723) },
	{ alias = "Opal Bracelet of Casting", id = 11069, minimum = 270, name = AceLib.API.Items.GetNameByID(11069) },
	{ alias = "Hardsilver Bangle of Aiming", id = 11020, minimum = 240, name = AceLib.API.Items.GetNameByID(11020) },
	{ alias = "Mythrite Planisphere", id = 10659, minimum = 190, name = AceLib.API.Items.GetNameByID(10659) },
	{ alias = "Aurum Regis Circlet of Healing", id = 10885, minimum = 400, name = AceLib.API.Items.GetNameByID(10885) },
	{ alias = "Durium Staff", id = 18354, minimum = 510, name = AceLib.API.Items.GetNameByID(18354) },
	{ alias = "Goblin Jig", id = 12706, minimum = 320, name = AceLib.API.Items.GetNameByID(12706) },
	{ alias = "Mythrite Earrings of Casting", id = 11072, minimum = 130, name = AceLib.API.Items.GetNameByID(11072) },
	{ alias = "Mythrite Earblades of Fending", id = 10977, minimum = 160, name = AceLib.API.Items.GetNameByID(10977) },
	{ alias = "Imperial Jade Earrings of Healing", id = 18952, minimum = 660, name = AceLib.API.Items.GetNameByID(18952) },
	{ alias = "Mythrite Bracelet of Healing", id = 11043, minimum = 160, name = AceLib.API.Items.GetNameByID(11043) },
	{ alias = "Mythrite Bangle of Slaying", id = 10994, minimum = 130, name = AceLib.API.Items.GetNameByID(10994) },
	{ alias = "Hardsilver Staff", id = 10642, minimum = 220, name = AceLib.API.Items.GetNameByID(10642) },
	{ alias = "Triphane Choker of Slaying", id = 18097, minimum = 320, name = AceLib.API.Items.GetNameByID(18097) },
	{ alias = "Imperial Jade Necklace of Slaying", id = 18955, minimum = 660, name = AceLib.API.Items.GetNameByID(18955) },
	{ alias = "Imperial Jade Necklace of Casting", id = 18958, minimum = 660, name = AceLib.API.Items.GetNameByID(18958) },
	{ alias = "Imperial Jade Earrings of Fending", id = 18949, minimum = 660, name = AceLib.API.Items.GetNameByID(18949) },
	{ alias = "Imperial Jade Earrings of Aiming", id = 18951, minimum = 660, name = AceLib.API.Items.GetNameByID(18951) },
	{ alias = "Hardsilver Star Globe", id = 10660, minimum = 240, name = AceLib.API.Items.GetNameByID(10660) },
	{ alias = "Azurite Earrings of Fending", id = 18559, minimum = 610, name = AceLib.API.Items.GetNameByID(18559) },
	{ alias = "Molybdenum Earring of Slaying", id = 18716, minimum = 630, name = AceLib.API.Items.GetNameByID(18716) },
	{ alias = "Hardsilver Pole", id = 10643, minimum = 290, name = AceLib.API.Items.GetNameByID(10643) },
	{ alias = "Hardsilver Earrings of Gathering", id = 12030, minimum = 290, name = AceLib.API.Items.GetNameByID(12030) },
	{ alias = "Agate Ring of Healing", id = 11054, minimum = 110, name = AceLib.API.Items.GetNameByID(11054) },
	{ alias = "Griffin Talon Ring of Healing", id = 11058, minimum = 350, name = AceLib.API.Items.GetNameByID(11058) },
	{ alias = "Griffin Talon Ring of Fending", id = 10986, minimum = 350, name = AceLib.API.Items.GetNameByID(10986) },
	{ alias = "Durium Chaplets", id = 19634, minimum = 510, name = AceLib.API.Items.GetNameByID(19634) },
	{ alias = "Dragon Fang Earrings", id = 12018, minimum = 270, name = AceLib.API.Items.GetNameByID(12018) },
	{ alias = "Aurum Regis Earrings of Slaying", id = 11004, minimum = 320, name = AceLib.API.Items.GetNameByID(11004) },
	{ alias = "Azurite Ring of Slaying", id = 18575, minimum = 560, name = AceLib.API.Items.GetNameByID(18575) },
	{ alias = "Aurum Regis Bracelet of Aiming", id = 11022, minimum = 320, name = AceLib.API.Items.GetNameByID(11022) },
	{ alias = "Citrine Choker of Fending", id = 10969, minimum = 350, name = AceLib.API.Items.GetNameByID(10969) },
	{ alias = "Azurite Choker of Healing", id = 18567, minimum = 610, name = AceLib.API.Items.GetNameByID(18567) },
	{ alias = "Azurite Ring of Casting", id = 18578, minimum = 560, name = AceLib.API.Items.GetNameByID(18578) },
	-- Leatherworker
	{ alias = "Gazelleskin Brais of Maiming", id = 18682, minimum = 650, name = AceLib.API.Items.GetNameByID(18682) },
	{ alias = "Dhalmelskin Jacket of Aiming", id = 10805, minimum = 240, name = AceLib.API.Items.GetNameByID(10805) },
	{ alias = "Dragonskin Belt of Maiming", id = 10736, minimum = 270, name = AceLib.API.Items.GetNameByID(10736) },
	{ alias = "Archaeoskin Gloves of Crafting", id = 11965, minimum = 130, name = AceLib.API.Items.GetNameByID(11965) },
	{ alias = "Dhalmelskin Belt of Casting", id = 10945, minimum = 220, name = AceLib.API.Items.GetNameByID(10945) },
	{ alias = "Dhalmelskin Crakows of Healing", id = 10917, minimum = 240, name = AceLib.API.Items.GetNameByID(10917) },
	{ alias = "Tigerskin Boots of Gathering", id = 19641, minimum = 510, name = AceLib.API.Items.GetNameByID(19641) },
	{ alias = "Archaeoskin Breeches of Maiming", id = 10740, minimum = 130, name = AceLib.API.Items.GetNameByID(10740) },
	{ alias = "Gaganaskin Bush Hat", id = 19617, minimum = 320, name = AceLib.API.Items.GetNameByID(19617) },
	{ alias = "Gazelleskin Choker", id = 19754, minimum = 660, name = AceLib.API.Items.GetNameByID(19754) },
	{ alias = "Gaganaskin Chaps of Aiming", id = 18070, minimum = 320, name = AceLib.API.Items.GetNameByID(18070) },
	{ alias = "Gaganaskin Shoes", id = 19616, minimum = 320, name = AceLib.API.Items.GetNameByID(19616) },
	{ alias = "Gazelleskin Wristband", id = 19755, minimum = 660, name = AceLib.API.Items.GetNameByID(19755) },
	{ alias = "Gyuki Leather Gloves of Crafting", id = 19624, minimum = 420, name = AceLib.API.Items.GetNameByID(19624) },
	{ alias = "Dragonskin Breeches of Fending", id = 10701, minimum = 290, name = AceLib.API.Items.GetNameByID(10701) },
	{ alias = "Dhalmel Leather", id = 12564, minimum = 250, name = AceLib.API.Items.GetNameByID(12564) },
	{ alias = "Serpentskin Thighboots of Healing", id = 10919, minimum = 350, name = AceLib.API.Items.GetNameByID(10919) },
	{ alias = "Marid Leather Breeches of Scouting", id = 18544, minimum = 610, name = AceLib.API.Items.GetNameByID(18544) },
	{ alias = "Tigerskin Tricorne of Striking", id = 18373, minimum = 510, name = AceLib.API.Items.GetNameByID(18373) },
	{ alias = "Gaganaskin Belt of Casting", id = 18090, minimum = 300, name = AceLib.API.Items.GetNameByID(18090) },
	{ alias = "Dragonskin Belt of Crafting", id = 11971, minimum = 320, name = AceLib.API.Items.GetNameByID(11971) },
	{ alias = "Archaeoskin Breeches of Fending", id = 10698, minimum = 130, name = AceLib.API.Items.GetNameByID(10698) },
	{ alias = "Gazelleskin Ringbelt of Aiming", id = 18930, minimum = 660, name = AceLib.API.Items.GetNameByID(18930) },
	{ alias = "Gazelleskin Brais of Scouting", id = 18700, minimum = 650, name = AceLib.API.Items.GetNameByID(18700) },
	{ alias = "Gazelleskin Twinbelt of Striking", id = 18690, minimum = 630, name = AceLib.API.Items.GetNameByID(18690) },
	{ alias = "Marid Leather Babouches of Gathering", id = 19651, minimum = 610, name = AceLib.API.Items.GetNameByID(19651) },
	{ alias = "Gazelleskin Coat of Healing", id = 18704, minimum = 650, name = AceLib.API.Items.GetNameByID(18704) },
	{ alias = "Serpentskin Thighboots of Striking", id = 10794, minimum = 400, name = AceLib.API.Items.GetNameByID(10794) },
	{ alias = "Serpentskin Brais of Scouting", id = 10871, minimum = 400, name = AceLib.API.Items.GetNameByID(10871) },
	{ alias = "Gazelleskin Ringbelt of Striking", id = 18924, minimum = 660, name = AceLib.API.Items.GetNameByID(18924) },
	{ alias = "Archaeoskin Jackboots of Crafting", id = 11978, minimum = 160, name = AceLib.API.Items.GetNameByID(11978) },
	{ alias = "Wyvernskin Jerkin", id = 11989, minimum = 220, name = AceLib.API.Items.GetNameByID(11989) },
	{ alias = "Dhalmelskin Armguards of Striking", id = 10770, minimum = 220, name = AceLib.API.Items.GetNameByID(10770) },
	{ alias = "Serpentskin Voyager's Belt of Maiming", id = 10738, minimum = 350, name = AceLib.API.Items.GetNameByID(10738) },
	{ alias = "Marid Leather Choker", id = 19744, minimum = 610, name = AceLib.API.Items.GetNameByID(19744) },
	{ alias = "Serpentskin Helm of Maiming", id = 10717, minimum = 400, name = AceLib.API.Items.GetNameByID(10717) },
	{ alias = "Fur-lined Gazelleskin Boots", id = 19661, minimum = 660, name = AceLib.API.Items.GetNameByID(19661) },
	{ alias = "Wyvernskin Wristbands", id = 12026, minimum = 190, name = AceLib.API.Items.GetNameByID(12026) },
	{ alias = "Wyvernskin Gloves of Fending", id = 10685, minimum = 160, name = AceLib.API.Items.GetNameByID(10685) },
	{ alias = "Dragonskin Choker", id = 12024, minimum = 320, name = AceLib.API.Items.GetNameByID(12024) },
	{ alias = "Dragonskin Wristbands", id = 12027, minimum = 320, name = AceLib.API.Items.GetNameByID(12027) },
	{ alias = "Wyvernskin Boots of Healing", id = 10916, minimum = 190, name = AceLib.API.Items.GetNameByID(10916) },
	{ alias = "Marid Leather Corset of Casting", id = 18558, minimum = 560, name = AceLib.API.Items.GetNameByID(18558) },
	{ alias = "Wyvernskin Belt of Scouting", id = 10860, minimum = 160, name = AceLib.API.Items.GetNameByID(10860) },
	{ alias = "Wyvernskin Mask of Casting", id = 10923, minimum = 190, name = AceLib.API.Items.GetNameByID(10923) },
	{ alias = "Archaeoskin Gloves of Healing", id = 10894, minimum = 110, name = AceLib.API.Items.GetNameByID(10894) },
	{ alias = "Gazelleskin Boots of Healing", id = 18707, minimum = 630, name = AceLib.API.Items.GetNameByID(18707) },
	{ alias = "Amphiptere Leather", id = 12566, minimum = 360, name = AceLib.API.Items.GetNameByID(12566) },
	{ alias = "Serpentskin Gloves", id = 11997, minimum = 350, name = AceLib.API.Items.GetNameByID(11997) },
	{ alias = "Serpentskin Thighboots of Aiming", id = 10836, minimum = 400, name = AceLib.API.Items.GetNameByID(10836) },
	{ alias = "Gazelleskin Earrings", id = 19753, minimum = 660, name = AceLib.API.Items.GetNameByID(19753) },
	{ alias = "Gyuki Leather Boots of Healing", id = 18239, minimum = 420, name = AceLib.API.Items.GetNameByID(18239) },
	{ alias = "Tigerskin Jackboots of Casting", id = 18401, minimum = 510, name = AceLib.API.Items.GetNameByID(18401) },
	{ alias = "Tigerskin Cap of Gathering", id = 19637, minimum = 510, name = AceLib.API.Items.GetNameByID(19637) },
	{ alias = "Serpentskin Boots of Striking", id = 10793, minimum = 350, name = AceLib.API.Items.GetNameByID(10793) },
	{ alias = "Dragonskin Gloves of Aiming", id = 10813, minimum = 270, name = AceLib.API.Items.GetNameByID(10813) },
	{ alias = "Tigerskin Armguards of Healing", id = 18393, minimum = 470, name = AceLib.API.Items.GetNameByID(18393) },
	{ alias = "Archaeoskin Belt of Striking", id = 10775, minimum = 110, name = AceLib.API.Items.GetNameByID(10775) },
	{ alias = "Wyvernskin Pot Helm of Maiming", id = 10713, minimum = 190, name = AceLib.API.Items.GetNameByID(10713) },
	{ alias = "Archaeoskin Gloves of Gathering", id = 11993, minimum = 130, name = AceLib.API.Items.GetNameByID(11993) },
	{ alias = "Dragonskin Ring", id = 12033, minimum = 290, name = AceLib.API.Items.GetNameByID(12033) },
	{ alias = "Gazelleskin Belt of Gathering", id = 19752, minimum = 660, name = AceLib.API.Items.GetNameByID(19752) },
	{ alias = "Serpentskin Bootlets of Casting", id = 10962, minimum = 400, name = AceLib.API.Items.GetNameByID(10962) },
	{ alias = "Tigerskin Ringbelt of Scouting", id = 18390, minimum = 470, name = AceLib.API.Items.GetNameByID(18390) },
	{ alias = "Archaeoskin Shoes of Aiming", id = 10831, minimum = 130, name = AceLib.API.Items.GetNameByID(10831) },
	{ alias = "Dragonskin Breeches of Scouting", id = 10869, minimum = 290, name = AceLib.API.Items.GetNameByID(10869) },
	{ alias = "Serpentskin Shoes", id = 11982, minimum = 400, name = AceLib.API.Items.GetNameByID(11982) },
	{ alias = "Gaganaskin Leg Guards of Fending", id = 18053, minimum = 320, name = AceLib.API.Items.GetNameByID(18053) },
	{ alias = "Serpentskin Hunting Belt of Scouting", id = 10864, minimum = 350, name = AceLib.API.Items.GetNameByID(10864) },
	{ alias = "Serpentskin Hose of Maiming", id = 10745, minimum = 400, name = AceLib.API.Items.GetNameByID(10745) },
	{ alias = "Serpentskin Armguards of Striking", id = 10772, minimum = 320, name = AceLib.API.Items.GetNameByID(10772) },
	{ alias = "Serpentskin Vest", id = 11992, minimum = 400, name = AceLib.API.Items.GetNameByID(11992) },
	{ alias = "Serpentskin Halfgloves of Crafting", id = 11969, minimum = 350, name = AceLib.API.Items.GetNameByID(11969) },
	{ alias = "Archaeoskin Shoes of Casting", id = 10957, minimum = 130, name = AceLib.API.Items.GetNameByID(10957) },
	{ alias = "Serpentskin Gloves of Casting", id = 10941, minimum = 350, name = AceLib.API.Items.GetNameByID(10941) },
	{ alias = "Serpentskin Dress Gloves of Casting", id = 10940, minimum = 320, name = AceLib.API.Items.GetNameByID(10940) },
	{ alias = "Serpentskin Armguards of Scouting", id = 10856, minimum = 320, name = AceLib.API.Items.GetNameByID(10856) },
	{ alias = "Gaganaskin Jacket of Aiming", id = 18068, minimum = 320, name = AceLib.API.Items.GetNameByID(18068) },
	{ alias = "Marid Leather Gloves of Crafting", id = 19644, minimum = 610, name = AceLib.API.Items.GetNameByID(19644) },
	{ alias = "Marid Leather Coat of Striking", id = 18530, minimum = 610, name = AceLib.API.Items.GetNameByID(18530) },
	{ alias = "Wyvernskin Choker", id = 12023, minimum = 220, name = AceLib.API.Items.GetNameByID(12023) },
	{ alias = "Marid Leather Belt of Fending", id = 18522, minimum = 560, name = AceLib.API.Items.GetNameByID(18522) },
	{ alias = "Gyuki Leather Twinbelt of Scouting", id = 18234, minimum = 370, name = AceLib.API.Items.GetNameByID(18234) },
	{ alias = "Serpentskin Bracers of Aiming", id = 10815, minimum = 350, name = AceLib.API.Items.GetNameByID(10815) },
	{ alias = "Gaganaskin Belt of Maiming", id = 18060, minimum = 300, name = AceLib.API.Items.GetNameByID(18060) },
	{ alias = "Serpentskin Hat of Casting", id = 10926, minimum = 320, name = AceLib.API.Items.GetNameByID(10926) },
	{ alias = "Dragonskin Boots of Healing", id = 10918, minimum = 290, name = AceLib.API.Items.GetNameByID(10918) },
	{ alias = "Gyuki Leather Ring", id = 19736, minimum = 420, name = AceLib.API.Items.GetNameByID(19736) },
	{ alias = "Gyuki Leather Halfgloves of Striking", id = 18219, minimum = 370, name = AceLib.API.Items.GetNameByID(18219) },
	{ alias = "Serpentskin Ringbelt of Aiming", id = 10821, minimum = 320, name = AceLib.API.Items.GetNameByID(10821) },
	{ alias = "Tigerskin Wristgloves of Striking", id = 18375, minimum = 470, name = AceLib.API.Items.GetNameByID(18375) },
	{ alias = "Gazelleskin Gloves of Crafting", id = 19654, minimum = 660, name = AceLib.API.Items.GetNameByID(19654) },
	{ alias = "Gazelleskin Open-toe Boots of Striking", id = 18689, minimum = 630, name = AceLib.API.Items.GetNameByID(18689) },
	{ alias = "Gyuki Leather Trousers of Maiming", id = 18214, minimum = 370, name = AceLib.API.Items.GetNameByID(18214) },
	{ alias = "Tigerskin Thighboots of Aiming", id = 18383, minimum = 510, name = AceLib.API.Items.GetNameByID(18383) },
	{ alias = "Gazelleskin Armguards of Aiming", id = 18693, minimum = 650, name = AceLib.API.Items.GetNameByID(18693) },
	{ alias = "Gyuki Leather Earrings", id = 19733, minimum = 420, name = AceLib.API.Items.GetNameByID(19733) },
	{ alias = "Gyuki Leather Twinbelt of Aiming", id = 18228, minimum = 370, name = AceLib.API.Items.GetNameByID(18228) },
	{ alias = "Gaganaskin Gloves", id = 19619, minimum = 320, name = AceLib.API.Items.GetNameByID(19619) },
	{ alias = "Gazelleskin Twinbelt of Scouting", id = 18702, minimum = 630, name = AceLib.API.Items.GetNameByID(18702) },
	{ alias = "Marid Leather Boots of Healing", id = 18551, minimum = 560, name = AceLib.API.Items.GetNameByID(18551) },
	{ alias = "Dragonskin Gloves of Healing", id = 10897, minimum = 270, name = AceLib.API.Items.GetNameByID(10897) },
	{ alias = "Dhalmelskin Shoes", id = 11980, minimum = 270, name = AceLib.API.Items.GetNameByID(11980) },
	{ alias = "Dhalmelskin Halfgloves of Crafting", id = 11967, minimum = 240, name = AceLib.API.Items.GetNameByID(11967) },
	{ alias = "Dhalmelskin Breeches of Fending", id = 10700, minimum = 240, name = AceLib.API.Items.GetNameByID(10700) },
	{ alias = "Archaeoskin Jackcoat of Gathering", id = 11988, minimum = 160, name = AceLib.API.Items.GetNameByID(11988) },
	-- Weaver
	{ alias = "Ruby Cotton Longkilt", id = 18244, minimum = 420, name = AceLib.API.Items.GetNameByID(18244) },
	{ alias = "Holy Rainbow Gloves", id = 11966, minimum = 190, name = AceLib.API.Items.GetNameByID(11966) },
	{ alias = "Chimerical Felt Corset of Casting", id = 10947, minimum = 320, name = AceLib.API.Items.GetNameByID(10947) },
	{ alias = "Chimerical Felt Alb of Healing", id = 10891, minimum = 350, name = AceLib.API.Items.GetNameByID(10891) },
	{ alias = "Chimerical Felt Hat of Casting", id = 10927, minimum = 400, name = AceLib.API.Items.GetNameByID(10927) },
	{ alias = "Rainbow Halfgloves of Scouting", id = 10852, minimum = 110, name = AceLib.API.Items.GetNameByID(10852) },
	{ alias = "Serge Poncho", id = 19658, minimum = 660, name = AceLib.API.Items.GetNameByID(19658) },
	{ alias = "Ramie Turban of Crafting", id = 11957, minimum = 240, name = AceLib.API.Items.GetNameByID(11957) },
	{ alias = "Chimerical Felt Cyclas of Scouting", id = 10849, minimum = 350, name = AceLib.API.Items.GetNameByID(10849) },
	{ alias = "Ramie Doublet of Crafting", id = 11962, minimum = 270, name = AceLib.API.Items.GetNameByID(11962) },
	{ alias = "Ramie Trousers of Gathering", id = 12003, minimum = 270, name = AceLib.API.Items.GetNameByID(12003) },
	{ alias = "Chimerical Felt Sash of Casting", id = 10948, minimum = 350, name = AceLib.API.Items.GetNameByID(10948) },
	{ alias = "Rainbow Bolero of Striking", id = 10761, minimum = 130, name = AceLib.API.Items.GetNameByID(10761) },
	{ alias = "Hallowed Ramie Doublet of Healing", id = 10890, minimum = 290, name = AceLib.API.Items.GetNameByID(10890) },
	{ alias = "Chimerical Felt Cap of Striking", id = 10758, minimum = 320, name = AceLib.API.Items.GetNameByID(10758) },
	{ alias = "Rainbow Ribbon of Aiming", id = 11012, minimum = 130, name = AceLib.API.Items.GetNameByID(11012) },
	{ alias = "Chimerical Felt Gloves of Healing", id = 10898, minimum = 320, name = AceLib.API.Items.GetNameByID(10898) },
	{ alias = "Bloodhempen Skirt", id = 19615, minimum = 320, name = AceLib.API.Items.GetNameByID(19615) },
	{ alias = "Chimerical Felt Klobuk of Healing", id = 10884, minimum = 320, name = AceLib.API.Items.GetNameByID(10884) },
	{ alias = "Rainbow Ribbon of Fending", id = 10964, minimum = 130, name = AceLib.API.Items.GetNameByID(10964) },
	{ alias = "Chimerical Felt Cap of Aiming", id = 10800, minimum = 320, name = AceLib.API.Items.GetNameByID(10800) },
	{ alias = "Holy Rainbow Sarouel of Fending", id = 10699, minimum = 160, name = AceLib.API.Items.GetNameByID(10699) },
	{ alias = "Chimerical Felt Corset of Healing", id = 10905, minimum = 320, name = AceLib.API.Items.GetNameByID(10905) },
	{ alias = "Ramie Tonban of Casting", id = 10952, minimum = 240, name = AceLib.API.Items.GetNameByID(10952) },
	{ alias = "Ruby Cotton Gilet of Scouting", id = 18230, minimum = 420, name = AceLib.API.Items.GetNameByID(18230) },
	{ alias = "Ruby Cotton Bottoms", id = 19625, minimum = 420, name = AceLib.API.Items.GetNameByID(19625) },
	{ alias = "Serge Hose of Aiming", id = 18538, minimum = 610, name = AceLib.API.Items.GetNameByID(18538) },
	{ alias = "Holy Rainbow Shoes", id = 11979, minimum = 220, name = AceLib.API.Items.GetNameByID(11979) },
	{ alias = "Chimerical Felt Robe of Casting", id = 10933, minimum = 350, name = AceLib.API.Items.GetNameByID(10933) },
	{ alias = "Holy Rainbow Sarouel of Casting", id = 10951, minimum = 160, name = AceLib.API.Items.GetNameByID(10951) },
	{ alias = "Rainbow Cap of Aiming", id = 10796, minimum = 110, name = AceLib.API.Items.GetNameByID(10796) },
	{ alias = "Chimerical Felt Trousers", id = 12005, minimum = 400, name = AceLib.API.Items.GetNameByID(12005) },
	{ alias = "Bloodhempen Chestwrap of Casting", id = 18086, minimum = 320, name = AceLib.API.Items.GetNameByID(18086) },
	{ alias = "Chimerical Felt Hose of Aiming", id = 10828, minimum = 350, name = AceLib.API.Items.GetNameByID(10828) },
	{ alias = "Chimerical Felt Coif of Aiming", id = 10801, minimum = 400, name = AceLib.API.Items.GetNameByID(10801) },
	{ alias = "Serge Hat of Casting", id = 18553, minimum = 560, name = AceLib.API.Items.GetNameByID(18553) },
	{ alias = "Ramie Halfgloves of Casting", id = 10938, minimum = 220, name = AceLib.API.Items.GetNameByID(10938) },
	{ alias = "Kudzu Longkilt of Casting", id = 18400, minimum = 470, name = AceLib.API.Items.GetNameByID(18400) },
	{ alias = "Kudzu Longkilt of Fending", id = 18364, minimum = 470, name = AceLib.API.Items.GetNameByID(18364) },
	{ alias = "Twinsilk Suspenders", id = 19653, minimum = 660, name = AceLib.API.Items.GetNameByID(19653) },
	{ alias = "Hallowed Ramie Doublet of Aiming", id = 10806, minimum = 290, name = AceLib.API.Items.GetNameByID(10806) },
	{ alias = "Chimerical Felt Tabard of Scouting", id = 10850, minimum = 400, name = AceLib.API.Items.GetNameByID(10850) },
	{ alias = "Serge Hose of Healing", id = 18550, minimum = 610, name = AceLib.API.Items.GetNameByID(18550) },
	{ alias = "Kudzu Corset of Casting", id = 18402, minimum = 470, name = AceLib.API.Items.GetNameByID(18402) },
	{ alias = "Twinsilk Slops of Healing", id = 18706, minimum = 650, name = AceLib.API.Items.GetNameByID(18706) },
	{ alias = "Twinsilk Slops of Gathering", id = 19660, minimum = 660, name = AceLib.API.Items.GetNameByID(19660) },
	{ alias = "Kudzu Tunic of Aiming", id = 18380, minimum = 510, name = AceLib.API.Items.GetNameByID(18380) },
	{ alias = "Cropped Twinsilk Slops", id = 19655, minimum = 660, name = AceLib.API.Items.GetNameByID(19655) },
	{ alias = "Chimerical Felt", id = 12592, minimum = 360, name = AceLib.API.Items.GetNameByID(12592) },
	{ alias = "Twinsilk Slops of Casting", id = 18712, minimum = 650, name = AceLib.API.Items.GetNameByID(18712) },
	{ alias = "Twinsilk Slops of Aiming", id = 18694, minimum = 650, name = AceLib.API.Items.GetNameByID(18694) },
	{ alias = "Twinsilk Sash of Casting", id = 18714, minimum = 630, name = AceLib.API.Items.GetNameByID(18714) },
	{ alias = "Serge Sarouel of Gathering", id = 19650, minimum = 610, name = AceLib.API.Items.GetNameByID(19650) },
	{ alias = "Bloodhempen Brais of Scouting", id = 18076, minimum = 300, name = AceLib.API.Items.GetNameByID(18076) },
	{ alias = "Serge Hood", id = 19657, minimum = 660, name = AceLib.API.Items.GetNameByID(19657) },
	{ alias = "Twinsilk Hood of Casting", id = 18709, minimum = 630, name = AceLib.API.Items.GetNameByID(18709) },
	{ alias = "Bloodhempen Brais of Striking", id = 18064, minimum = 300, name = AceLib.API.Items.GetNameByID(18064) },
	{ alias = "Twinsilk Corset of Healing", id = 18942, minimum = 650, name = AceLib.API.Items.GetNameByID(18942) },
	{ alias = "Serge Hat of Aiming", id = 18535, minimum = 560, name = AceLib.API.Items.GetNameByID(18535) },
	{ alias = "Kudzu Hat of Healing", id = 18391, minimum = 470, name = AceLib.API.Items.GetNameByID(18391) },
	{ alias = "Serge Sarouel of Crafting", id = 19645, minimum = 610, name = AceLib.API.Items.GetNameByID(19645) },
	{ alias = "Serge Knit Cap", id = 19652, minimum = 660, name = AceLib.API.Items.GetNameByID(19652) },
	{ alias = "Chimerical Felt Doublet of Crafting", id = 11964, minimum = 400, name = AceLib.API.Items.GetNameByID(11964) },
	{ alias = "Holy Rainbow Shirt of Scouting", id = 10846, minimum = 190, name = AceLib.API.Items.GetNameByID(10846) },
	{ alias = "Twinsilk Hood of Healing", id = 18703, minimum = 630, name = AceLib.API.Items.GetNameByID(18703) },
	{ alias = "Serge Work Gloves", id = 19659, minimum = 660, name = AceLib.API.Items.GetNameByID(19659) },
	{ alias = "Bloodhempen Culottes of Healing", id = 18082, minimum = 300, name = AceLib.API.Items.GetNameByID(18082) },
	{ alias = "Kudzu Trousers of Scouting", id = 18388, minimum = 470, name = AceLib.API.Items.GetNameByID(18388) },
	{ alias = "Chimerical Felt Chausses of Healing", id = 10912, minimum = 350, name = AceLib.API.Items.GetNameByID(10912) },
	{ alias = "Ruby Cotton Smalls", id = 18238, minimum = 420, name = AceLib.API.Items.GetNameByID(18238) },
	{ alias = "Holy Rainbow Hat", id = 11984, minimum = 190, name = AceLib.API.Items.GetNameByID(11984) },
	{ alias = "Ruby Cotton Sash of Casting", id = 18246, minimum = 370, name = AceLib.API.Items.GetNameByID(18246) },
	{ alias = "Holy Rainbow Coatee", id = 11961, minimum = 220, name = AceLib.API.Items.GetNameByID(11961) },
	{ alias = "Ruby Cotton Gambison", id = 18224, minimum = 420, name = AceLib.API.Items.GetNameByID(18224) },
	{ alias = "Rainbow Slops of Healing", id = 10908, minimum = 130, name = AceLib.API.Items.GetNameByID(10908) },
	{ alias = "Kudzu Cap of Crafting", id = 19632, minimum = 510, name = AceLib.API.Items.GetNameByID(19632) },
	{ alias = "Ramie Robe of Healing", id = 10889, minimum = 240, name = AceLib.API.Items.GetNameByID(10889) },
	{ alias = "Bloodhempen Vest of Scouting", id = 18074, minimum = 320, name = AceLib.API.Items.GetNameByID(18074) },
	{ alias = "Ramie Trousers of Aiming", id = 10826, minimum = 240, name = AceLib.API.Items.GetNameByID(10826) },
	{ alias = "Ramie Ribbon of Slaying", id = 10990, minimum = 220, name = AceLib.API.Items.GetNameByID(10990) },
	{ alias = "Ramie Cloth", id = 12590, minimum = 230, name = AceLib.API.Items.GetNameByID(12590) },
	{ alias = "Chimerical Felt Cap of Scouting", id = 10842, minimum = 320, name = AceLib.API.Items.GetNameByID(10842) },
	{ alias = "Hallowed Ramie Gaskins of Healing", id = 10911, minimum = 290, name = AceLib.API.Items.GetNameByID(10911) },
	{ alias = "Ruby Cotton Coatee", id = 19623, minimum = 420, name = AceLib.API.Items.GetNameByID(19623) },
	{ alias = "Rainbow Sash of Healing", id = 10901, minimum = 110, name = AceLib.API.Items.GetNameByID(10901) },
	{ alias = "Rainbow Cap of Casting", id = 10922, minimum = 110, name = AceLib.API.Items.GetNameByID(10922) },
	{ alias = "Serge Gambison of Casting", id = 18554, minimum = 610, name = AceLib.API.Items.GetNameByID(18554) },
	{ alias = "Hallowed Ramie Gaskins of Casting", id = 10953, minimum = 290, name = AceLib.API.Items.GetNameByID(10953) },
	{ alias = "Chimerical Felt Cyclas of Striking", id = 10765, minimum = 350, name = AceLib.API.Items.GetNameByID(10765) },
	{ alias = "Kudzu Robe of Healing", id = 18392, minimum = 510, name = AceLib.API.Items.GetNameByID(18392) },
	{ alias = "Hallowed Ramie Sash of Aiming", id = 10820, minimum = 270, name = AceLib.API.Items.GetNameByID(10820) },
	{ alias = "Ruby Cotton Bandana of Striking", id = 18217, minimum = 370, name = AceLib.API.Items.GetNameByID(18217) },
	{ alias = "Holy Rainbow Hat of Aiming", id = 10797, minimum = 160, name = AceLib.API.Items.GetNameByID(10797) },
	{ alias = "Chimerical Felt Breeches of Fending", id = 10703, minimum = 400, name = AceLib.API.Items.GetNameByID(10703) },
	{ alias = "Holy Rainbow Sarouel of Maiming", id = 10741, minimum = 160, name = AceLib.API.Items.GetNameByID(10741) },
	{ alias = "Holy Rainbow Shirt of Striking", id = 10762, minimum = 190, name = AceLib.API.Items.GetNameByID(10762) },
	{ alias = "Chimerical Felt Tabard of Striking", id = 10766, minimum = 400, name = AceLib.API.Items.GetNameByID(10766) },
	{ alias = "Chimerical Felt Breeches of Healing", id = 10913, minimum = 400, name = AceLib.API.Items.GetNameByID(10913) },
	{ alias = "Hallowed Ramie Sash of Casting", id = 10946, minimum = 270, name = AceLib.API.Items.GetNameByID(10946) },
	{ alias = "Chimerical Felt Sash of Aiming", id = 10822, minimum = 350, name = AceLib.API.Items.GetNameByID(10822) },
	-- Alchemist
	{ alias = "Gyuki Leather Grimoire", id = 18199, minimum = 370, name = AceLib.API.Items.GetNameByID(18199) },
	{ alias = "Commanding Craftsman's Tea", id = 19883, minimum = 510, name = AceLib.API.Items.GetNameByID(19883) },
	{ alias = "Koppranickel Codex", id = 18044, minimum = 320, name = AceLib.API.Items.GetNameByID(18044) },
	{ alias = "Noble's Picatrix", id = 10656, minimum = 320, name = AceLib.API.Items.GetNameByID(10656) },
	{ alias = "Dhalmelskin Grimoire", id = 10648, minimum = 240, name = AceLib.API.Items.GetNameByID(10648) },
	{ alias = "Hallowed Chestnut Wand", id = 10637, minimum = 270, name = AceLib.API.Items.GetNameByID(10637) },
	{ alias = "Wyvernskin Codex", id = 10653, minimum = 160, name = AceLib.API.Items.GetNameByID(10653) },
	{ alias = "Infusion of Strength", id = 19886, minimum = 660, name = AceLib.API.Items.GetNameByID(19886) },
	{ alias = "Infusion of Intelligence", id = 19889, minimum = 660, name = AceLib.API.Items.GetNameByID(19889) },
	{ alias = "Archaeoskin Codex", id = 10652, minimum = 110, name = AceLib.API.Items.GetNameByID(10652) },
	{ alias = "Draconian Potion of Intelligence", id = 12625, minimum = 350, name = AceLib.API.Items.GetNameByID(12625) },
	{ alias = "Wyvernskin Grimoire", id = 10647, minimum = 160, name = AceLib.API.Items.GetNameByID(10647) },
	{ alias = "Infusion of Dexterity", id = 19887, minimum = 660, name = AceLib.API.Items.GetNameByID(19887) },
	{ alias = "Draconian Potion of Strength", id = 12622, minimum = 320, name = AceLib.API.Items.GetNameByID(12622) },
	{ alias = "Competent Craftsman's Tea", id = 19882, minimum = 470, name = AceLib.API.Items.GetNameByID(19882) },
	{ alias = "Draconian Potion of Mind", id = 12626, minimum = 350, name = AceLib.API.Items.GetNameByID(12626) },
	{ alias = "Marid Leather Grimoire", id = 18511, minimum = 610, name = AceLib.API.Items.GetNameByID(18511) },
	{ alias = "Dragonskin Codex", id = 10655, minimum = 290, name = AceLib.API.Items.GetNameByID(10655) },
	{ alias = "Enchanted Aurum Regis Ink", id = 12603, minimum = 360, name = AceLib.API.Items.GetNameByID(12603) },
	{ alias = "Gyuki Leather Codex", id = 18200, minimum = 370, name = AceLib.API.Items.GetNameByID(18200) },
	{ alias = "Gazelleskin Codex", id = 18668, minimum = 630, name = AceLib.API.Items.GetNameByID(18668) },
	{ alias = "Tigerskin Grimoire", id = 18355, minimum = 510, name = AceLib.API.Items.GetNameByID(18355) },
	{ alias = "Infusion of Vitality", id = 19888, minimum = 650, name = AceLib.API.Items.GetNameByID(19888) },
	{ alias = "Potent Spiritbond Potion", id = 19885, minimum = 370, name = AceLib.API.Items.GetNameByID(19885) },
	{ alias = "Noble's Codex", id = 10657, minimum = 400, name = AceLib.API.Items.GetNameByID(10657) },
	{ alias = "Marid Leather Codex", id = 18512, minimum = 610, name = AceLib.API.Items.GetNameByID(18512) },
	{ alias = "Noble Gold", id = 10651, minimum = 400, name = AceLib.API.Items.GetNameByID(10651) },
	{ alias = "Koppranickel Index", id = 18043, minimum = 320, name = AceLib.API.Items.GetNameByID(18043) },
	{ alias = "Tigerskin Codex", id = 18356, minimum = 510, name = AceLib.API.Items.GetNameByID(18356) },
	{ alias = "Infusion of Mind", id = 19890, minimum = 650, name = AceLib.API.Items.GetNameByID(19890) },
	{ alias = "Holy Cedar Wand", id = 10635, minimum = 160, name = AceLib.API.Items.GetNameByID(10635) },
	{ alias = "Book of Aurum Regis", id = 10650, minimum = 320, name = AceLib.API.Items.GetNameByID(10650) },
	{ alias = "Dhalmelskin Codex", id = 10654, minimum = 240, name = AceLib.API.Items.GetNameByID(10654) },
	{ alias = "Gazelleskin Grimoire", id = 18667, minimum = 630, name = AceLib.API.Items.GetNameByID(18667) },
	{ alias = "Draconian Potion of Dexterity", id = 12623, minimum = 320, name = AceLib.API.Items.GetNameByID(12623) },
	{ alias = "Archaeoskin Grimoire", id = 10646, minimum = 110, name = AceLib.API.Items.GetNameByID(10646) },
	{ alias = "Draconian Potion of Vitality", id = 12624, minimum = 350, name = AceLib.API.Items.GetNameByID(12624) },
	{ alias = "Enchanted Hardsilver Ink", id = 12602, minimum = 250, name = AceLib.API.Items.GetNameByID(12602) },
	{ alias = "Dragonskin Grimoire", id = 10649, minimum = 290, name = AceLib.API.Items.GetNameByID(10649) },
	-- Culinarian
	{ alias = "Cockatrice Meatballs", id = 12858, minimum = 320, name = AceLib.API.Items.GetNameByID(12858) },
	{ alias = "Dhalmel Fricassee", id = 12869, minimum = 290, name = AceLib.API.Items.GetNameByID(12869) },
	{ alias = "Buckwheat Tea", id = 19809, minimum = 370, name = AceLib.API.Items.GetNameByID(19809) },
	{ alias = "Kaiser Roll", id = 12849, minimum = 240, name = AceLib.API.Items.GetNameByID(12849) },
	{ alias = "Baklava", id = 19811, minimum = 320, name = AceLib.API.Items.GetNameByID(19811) },
	{ alias = "Jerked Jhammel", id = 19819, minimum = 650, name = AceLib.API.Items.GetNameByID(19819) },
	{ alias = "Egg Foo Young", id = 19820, minimum = 610, name = AceLib.API.Items.GetNameByID(19820) },
	{ alias = "Charred Charr", id = 19828, minimum = 370, name = AceLib.API.Items.GetNameByID(19828) },
	{ alias = "Beet Soup", id = 12862, minimum = 220, name = AceLib.API.Items.GetNameByID(12862) },
	{ alias = "Stewed River Bream", id = 19827, minimum = 660, name = AceLib.API.Items.GetNameByID(19827) },
	{ alias = "Kasha", id = 19838, minimum = 370, name = AceLib.API.Items.GetNameByID(19838) },
	{ alias = "Chirashi-zushi", id = 19814, minimum = 650, name = AceLib.API.Items.GetNameByID(19814) },
	{ alias = "Doman Tea", id = 19807, minimum = 630, name = AceLib.API.Items.GetNameByID(19807) },
	{ alias = "Popoto Soba", id = 19816, minimum = 420, name = AceLib.API.Items.GetNameByID(19816) },
	{ alias = "Emerald Soup", id = 12863, minimum = 270, name = AceLib.API.Items.GetNameByID(12863) },
	{ alias = "Grilled Sweetfish", id = 12855, minimum = 220, name = AceLib.API.Items.GetNameByID(12855) },
	{ alias = "Loquat Juice", id = 19808, minimum = 320, name = AceLib.API.Items.GetNameByID(19808) },
	{ alias = "Gameni", id = 19831, minimum = 510, name = AceLib.API.Items.GetNameByID(19831) },
	{ alias = "Grilled Turban", id = 19822, minimum = 420, name = AceLib.API.Items.GetNameByID(19822) },
	{ alias = "Marron Glace", id = 12847, minimum = 350, name = AceLib.API.Items.GetNameByID(12847) },
	{ alias = "Warrior's Stew", id = 19837, minimum = 560, name = AceLib.API.Items.GetNameByID(19837) },
	{ alias = "Onigara-yaki", id = 19821, minimum = 630, name = AceLib.API.Items.GetNameByID(19821) },
	{ alias = "Morel Salad", id = 12854, minimum = 400, name = AceLib.API.Items.GetNameByID(12854) },
	{ alias = "Sesame Cookie", id = 13743, minimum = 270, name = AceLib.API.Items.GetNameByID(13743) },
	{ alias = "Tempura Platter", id = 19826, minimum = 560, name = AceLib.API.Items.GetNameByID(19826) },
	{ alias = "Stuffed Cabbage Rolls", id = 12866, minimum = 160, name = AceLib.API.Items.GetNameByID(12866) },
	{ alias = "Ishgardian Tea", id = 12842, minimum = 190, name = AceLib.API.Items.GetNameByID(12842) },
	{ alias = "Stuffed Chysahl", id = 12868, minimum = 400, name = AceLib.API.Items.GetNameByID(12868) },
	{ alias = "Sweet and Sour Frogs' Legs", id = 19825, minimum = 510, name = AceLib.API.Items.GetNameByID(19825) },
	{ alias = "Ishgardian Muffin", id = 12850, minimum = 190, name = AceLib.API.Items.GetNameByID(12850) },
	{ alias = "Steamed Grouper", id = 19824, minimum = 660, name = AceLib.API.Items.GetNameByID(19824) },
	{ alias = "Crab Croquette", id = 19833, minimum = 470, name = AceLib.API.Items.GetNameByID(19833) },
	{ alias = "Shorlog", id = 19817, minimum = 510, name = AceLib.API.Items.GetNameByID(19817) },
	{ alias = "Clam Chowder", id = 12864, minimum = 400, name = AceLib.API.Items.GetNameByID(12864) },
	{ alias = "Sohm Al Tart", id = 12846, minimum = 220, name = AceLib.API.Items.GetNameByID(12846) },
	{ alias = "Sauteed Porcini", id = 12853, minimum = 190, name = AceLib.API.Items.GetNameByID(12853) },
	{ alias = "Frozen Spirits", id = 12843, minimum = 320, name = AceLib.API.Items.GetNameByID(12843) },
	{ alias = "Royal Eggs", id = 12859, minimum = 290, name = AceLib.API.Items.GetNameByID(12859) },
	{ alias = "Birch Syrup", id = 12892, minimum = 370, name = AceLib.API.Items.GetNameByID(12892) },
	{ alias = "Liver-cheese Sandwich", id = 12851, minimum = 350, name = AceLib.API.Items.GetNameByID(12851) },
	{ alias = "Persimmon Pudding", id = 19813, minimum = 610, name = AceLib.API.Items.GetNameByID(19813) },
	{ alias = "Miso Soup with Tofu", id = 19834, minimum = 470, name = AceLib.API.Items.GetNameByID(19834) },
	{ alias = "Dhalmel Gratin", id = 12867, minimum = 220, name = AceLib.API.Items.GetNameByID(12867) },
	{ alias = "Miso Dengaku", id = 19829, minimum = 650, name = AceLib.API.Items.GetNameByID(19829) },
	{ alias = "Nomad Meat Pie", id = 19839, minimum = 560, name = AceLib.API.Items.GetNameByID(19839) },
	{ alias = "Jhammel Moussaka", id = 19830, minimum = 660, name = AceLib.API.Items.GetNameByID(19830) },
	{ alias = "Steppe Salad", id = 19832, minimum = 560, name = AceLib.API.Items.GetNameByID(19832) },
	{ alias = "Baked Pipira Pira", id = 12856, minimum = 320, name = AceLib.API.Items.GetNameByID(12856) },
	{ alias = "Deep-fried Okeanis", id = 12860, minimum = 400, name = AceLib.API.Items.GetNameByID(12860) },
	{ alias = "Fish Stew", id = 19835, minimum = 610, name = AceLib.API.Items.GetNameByID(19835) },
	{ alias = "Boiled Amberjack Head", id = 19823, minimum = 630, name = AceLib.API.Items.GetNameByID(19823) },
	{ alias = "Baked Onion Soup", id = 12861, minimum = 160, name = AceLib.API.Items.GetNameByID(12861) },
	{ alias = "Fig Bavarois", id = 12845, minimum = 130, name = AceLib.API.Items.GetNameByID(12845) },
}

ffxiv_task_craft = inheritsFrom(ml_task)
ffxiv_task_craft.name = "LT_CRAFT"
function ffxiv_task_craft.Create()
    local newinst = inheritsFrom(ffxiv_task_craft)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_craft members
	ffxiv_craft.ResetOrders()
    
    return newinst
end

function cd(var,level)
	local level = tonumber(level) or 3

	if ( gCraftDebug ) then
		if ( level <= tonumber(gCraftDebugLevel)) then
			if (type(var) == "string") then
				d("[L"..tostring(level).."]["..tostring(Now()).."]: "..var)
			elseif (type(var) == "number" or type(var) == "boolean") then
				d("[L"..tostring(level).."]["..tostring(Now()).."]: "..tostring(var))
			elseif (type(var) == "table") then
				outputTable(var)
			end
		end
	end
end
function ffxiv_craft.CanUseTea()
	if (IsCrafter(Player.job) and MissingBuff(Player.id,49,0,30)) then
		if gCraftTeaLevel == GetString("CP") or gCraftTeaLevel == GetString("Any") then
			local tea, action = GetItem(19884)
			if (tea and action and tea:IsReady(Player.id)) then
				return true, tea
			end
			local teahq, action = GetItem(1019884)
			if (teahq and action and teahq:IsReady(Player.id)) then
				return true, teahq
			end
		end
		if gCraftTeaLevel == GetString("Control") or gCraftTeaLevel == GetString("Any") then
			local tea, action = GetItem(19883)
			if (tea and action and tea:IsReady(Player.id)) then
				return true, tea
			end
			local teahq, action = GetItem(1019883)
			if (teahq and action and teahq:IsReady(Player.id)) then
				return true, teahq
			end
		end
		if gCraftTeaLevel == GetString("Craftmanship") or gCraftTeaLevel == GetString("Any") then
			local tea, action = GetItem(19882)
			if (tea and action and tea:IsReady(Player.id)) then
				return true, tea
			end
			local teahq, action = GetItem(1019882)
			if (teahq and action and teahq:IsReady(Player.id)) then
				return true, teahq
			end
		end
	end
	
	return false, nil
end
c_craftlimit = inheritsFrom( ml_cause )
e_craftlimit = inheritsFrom( ml_effect )
function c_craftlimit:evaluate()
	if (not ffxiv_craft.IsCrafting()) then
		if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
			local recipe = ml_task_hub:CurrentTask().recipe
			local itemid = ml_task_hub:CurrentTask().itemid
			local requireHQ = ml_task_hub:CurrentTask().requireHQ
			local requireCollect = ml_task_hub:CurrentTask().requireCollect
			local countHQ = ml_task_hub:CurrentTask().countHQ
			local requiredItems = ml_task_hub:CurrentTask().requiredItems
			local startingCount = ml_task_hub:CurrentTask().startingCount 
			
			local itemcount = 0
			if (requireCollect) then
				itemcount = itemcount + ItemCount(itemid + 500000)
			elseif (requireHQ) then
				itemcount = itemcount + ItemCount(itemid + 1000000)
			elseif (countHQ) then
				itemcount = itemcount + ItemCount(itemid,true)
			else
				itemcount = itemcount + ItemCount(itemid)
			end
			
			local canCraft = AceLib.API.Items.CanCraft(recipe.id)			
			if (not canCraft) then
				cd("[CraftLimit]: We can no longer craft this item, complete the order.",3)
				return true
			else
				if (requiredItems > 0 and itemcount >= (requiredItems + startingCount))	then
					cd("[CraftLimit]: Current item count ["..tostring(itemcount).."] is more than ["..tostring(requiredItems + startingCount).."], no need to start more.",3)
					return true
				end
			end
		elseif gCraftMarkerOrProfileIndex ~= 1 then
			if ((ml_task_hub:CurrentTask().maxItems > 0 and ml_task_hub:CurrentTask().itemsCrafted == ml_task_hub:CurrentTask().maxItems) or 
				ml_task_hub:CurrentTask().attemptedStarts > 2)
			then
				return true
			end
		end
	end
	
    return false
end
function e_craftlimit:execute()
	cd("[CraftLimit]: Profile has reached the preset requirements.",3)
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local recipeid = ml_task_hub:CurrentTask().recipe.id
		ffxiv_craft.orders[recipeid].completed = true
		ffxiv_craft.tracking.measurementDelay = Now()
		
		cd("[CraftLimit]: Setting order with recipe ID ["..tostring(recipeid).."] to complete.",3)
		ml_task_hub:CurrentTask().completed = true
	elseif gCraftMarkerOrProfileIndex ~= 1 then
		ml_global_information:ToggleRun()
	end
end

c_opencraftwnd = inheritsFrom( ml_cause )
e_opencraftwnd  = inheritsFrom( ml_effect )
function c_opencraftwnd:evaluate()
	if (MIsCasting() or not ml_task_hub:CurrentTask().allowWindowOpen ) then
		return false
	end
	
	if (not IsControlOpen("Synthesis") and not IsControlOpen("SynthesisSimple") and not IsControlOpen("RecipeNote")) then
		local logOpen = ActionList:Get(10,9)
		if (logOpen and logOpen.usable) then
			logOpen:Cast(Player.id)
			ml_global_information.Await(1000, 1500, function () return IsControlOpen("RecipeNote") end)
		end
		return true
	end
	
    return false
end

function e_opencraftwnd:execute()
end

c_startcraft = inheritsFrom( ml_cause )
e_startcraft = inheritsFrom( ml_effect )
function c_startcraft:evaluate()
	if (not ffxiv_craft.IsCrafting() and IsControlOpen("RecipeNote")) then
		
		if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
			local recipe = ml_task_hub:CurrentTask().recipe
			local jobRequired = recipe.class + 8
			
			if (Player.job == jobRequired) then
				local minCP = ml_task_hub:CurrentTask().requiredCP
				local itemid = ml_task_hub:CurrentTask().itemid
				local requireHQ = ml_task_hub:CurrentTask().requireHQ
				local requireCollect = ml_task_hub:CurrentTask().requireCollect
				local countHQ = ml_task_hub:CurrentTask().countHQ
				local canCraft,maxAmount = AceLib.API.Items.CanCraft(recipe.id)
				
				local itemcount = 0
				if (requireCollect) then
					itemcount = itemcount + ItemCount(itemid + 500000)
				elseif (requireHQ) then
					itemcount = itemcount + ItemCount(itemid + 1000000)
				elseif (countHQ) then
					itemcount = itemcount + ItemCount(itemid,true)
				else
					itemcount = itemcount + ItemCount(itemid)
				end
					
				local requiredItems = ml_task_hub:CurrentTask().requiredItems
				local startingCount = ml_task_hub:CurrentTask().startingCount 
				
				local quickCraft = ml_task_hub:CurrentTask().useQuick
				if (canCraft) then
					if (requiredItems == 0 or (requiredItems > 0 and itemcount < (requiredItems + startingCount))) then
						if (Player.cp.max >= minCP) or quickCraft then
							return true
						else 
							d("[StartCraft]: CP to Low for item ["..tostring(recipe.id).."].",2)
						end
					else
						cd("[StartCraft]: Current item count ["..tostring(itemcount).."] is more than ["..tostring(requiredItems + startingCount).."], no need to start more.",2)
						
					end
				else
					cd("[StartCraft]: We cannot craft anymore of item ["..tostring(recipe.id).."].",2)
				end
			end
		elseif gCraftMarkerOrProfileIndex ~= 1 then
			local minCP = tonumber(gCraftMinCP) or 0
			if (Player.cp.max < minCP) then
					d("[StartCraft]: Current CP < Minimum CP.")
					ml_global_information:ToggleRun()
				return false
			end
			
			local mats = Crafting:GetCraftingMats()
			if (table.valid(mats)) then
				for i = 1,6 do
					local ingredient = mats[i]
					if (ingredient) then
						if (gCraftUseHQ) then
							if (not gCraftUseHQBackup) then
								if (ingredient.needed <= ingredient.inventoryhq) then
									Crafting:SetCraftingMats(i-1,ingredient.needed)
								else
									Crafting:SetCraftingMats(i-1,ingredient.inventoryhq)
								end
							else
								if ((ingredient.inventorynq + ingredient.inventoryhq) >= ingredient.needed) then
									Crafting:SetCraftingMats(i-1,(ingredient.needed - ingredient.inventorynq))
								else
									ffxiv_dialog_manager.IssueStopNotice("Need More Items", "Cannot craft this item, not enough materials.", "okonly")
									return false
								end
							end
						else
							if (ingredient.needed > ingredient.inventorynq) then
								ffxiv_dialog_manager.IssueStopNotice("Need HQ", "Cannot craft this item without using HQ mats.", "okonly")
								return false
							end
						end
					end
				end
			end	
				
			if ( Crafting:CanCraftSelectedItem() ) then
				return true
			end
		end
	end	
	
    return false
end

function e_startcraft:execute()
	SkillMgr.prevSkillList = {}
	SkillMgr.tempPrevSkillList = {}
	
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local recipe = ml_task_hub:CurrentTask().recipe
		local itemid = ml_task_hub:CurrentTask().itemid
		if (not ml_task_hub:CurrentTask().recipeSelected) then
			cd("Recipe phase 1, set to: ["..tostring(recipe.class)..","..tostring(recipe.page)..","..tostring(recipe.id).."].",3)
			Crafting:SetRecipe(recipe.class,recipe.page,recipe.id)
			ml_task_hub:CurrentTask().recipeSelected = true
			
			local skillProfile = ml_task_hub:CurrentTask().skillProfile
			if (skillProfile ~= "" and gSkillProfile ~= skillProfile) then
				if (SkillMgr.HasProfile(skillProfile)) then
					SkillMgr.UseProfile(skillProfile)
				end
			end
			
			ml_global_information.Await(1000)
			return
		else
			if (not ml_task_hub:CurrentTask().matsSet) then
				local useHQ = ml_task_hub:CurrentTask().useHQ
				local mats = Crafting:GetCraftingMats()
				if (table.valid(mats)) then
					if (useHQ) then
						for i = 1,6 do
							local ingredient = mats[i]
							if (ingredient) then
								local hqAmount = ml_task_hub:CurrentTask()["hq"..tostring(i)]
								local hqAmountMin = ml_task_hub:CurrentTask()["hq"..tostring(i).."min"]
								if (hqAmount > 0) then
									if (ingredient.inventoryhq >= hqAmount) then
										Crafting:SetCraftingMats(i-1,hqAmount)
									elseif (hqAmountMin > 0 and ingredient.inventoryhq >= hqAmountMin and (hqAmountMin + ingredient.inventorynq) >= ingredient.needed) then
										Crafting:SetCraftingMats(i-1,hqAmountMin)
									elseif (hqAmountMin == 0 and (ingredient.inventoryhq + ingredient.inventorynq) >= ingredient.needed) then
										Crafting:SetCraftingMats(i-1,ingredient.inventoryhq)
									else
										d("Stop crafting item, not enough HQ.")
										e_craftlimit:execute()
										return false
									end
								end
							end
						end
					end
					ml_task_hub:CurrentTask().matsSet = true
				end				
			else
				if (Crafting:CanCraftSelectedItem()) then
				--if (true) then
					ml_task_hub:CurrentTask().failedAttempts = 0
					local usequick = ml_task_hub:CurrentTask().useQuick
					if (usequick) then
						local itemid = ml_task_hub:CurrentTask().itemid
						local canCraft,maxAmount = AceLib.API.Items.CanCraft(recipe.id)
						local wantedAmount = ml_task_hub:ThisTask().requiredItems
						if (wantedAmount > 0 and wantedAmount <= maxAmount and wantedAmount <= 99) then
							Crafting:CraftSelectedItem(wantedAmount)
						else
							if (maxAmount > 99) then
								Crafting:CraftSelectedItem(99)
							else
								Crafting:CraftSelectedItem(maxAmount)
							end
						end
						if (IsControlOpen("RecipeNote")) then
							ffxiv_craft.ToggleCraftingLog()
						end
						SkillMgr.newCraft = true
						ml_task_hub:CurrentTask().allowWindowOpen = false
					else
						Crafting:CraftSelectedItem()
						if (IsControlOpen("RecipeNote")) then
							ffxiv_craft.ToggleCraftingLog()
						end
						SkillMgr.newCraft = true
						ml_task_hub:CurrentTask().allowWindowOpen = false
					end
					ml_global_information.Await(2500)
					return
				else
					if (ml_task_hub:CurrentTask().failedAttempts < 20) then
						cd("[StartCraft]: We cannot craft anymore of item ["..tostring(recipe.id).."], but we will try a couple more times to be sure.",3)
						ml_task_hub:CurrentTask().failedAttempts = ml_task_hub:CurrentTask().failedAttempts + 1
						ml_global_information.Await(1000)
						return
					else
						cd("[StartCraft]: We cannot craft anymore of item ["..tostring(recipe.id).."].",3)
						ffxiv_craft.orders[recipe.id].completed = true
						ml_task_hub:CurrentTask().completed = true
					end
				end			
			end
		end
	elseif gCraftMarkerOrProfileIndex ~= 1 then				
		Crafting:CraftSelectedItem()
		if (IsControlOpen("RecipeNote")) then
			ffxiv_craft.ToggleCraftingLog()
		end
		ml_task_hub:ThisTask().attemptedStarts = ml_task_hub:ThisTask().attemptedStarts + 1
		SkillMgr.newCraft = true
		ml_global_information.Await(2500)
		ml_task_hub:CurrentTask().allowWindowOpen = false
	end
end

c_precraftbuff = inheritsFrom( ml_cause )
e_precraftbuff = inheritsFrom( ml_effect )
e_precraftbuff.id = 0
e_precraftbuff.activity = ""
e_precraftbuff.item = nil
e_precraftbuff.requiresLogClose = false
function c_precraftbuff:evaluate()

	e_precraftbuff.id = 0
	e_precraftbuff.item = nil
	e_precraftbuff.activity = ""
	e_precraftbuff.requiresLogClose = false
	
	if (not ffxiv_craft.IsCrafting()) then
		if (NeedsRepair()) then
			cd("[PreCraftBuff]: Need to repair.",3)
			e_precraftbuff.activity = "repair"
			e_precraftbuff.requiresLogClose = false
			return true
		end
		
		if (gCraftFood ~= GetString("none")) then
			local foodDetails = ml_global_information.foods[gCraftFood]
			if (foodDetails) then
				local foodID = foodDetails.id
				local foodStack = foodDetails.buffstackid
				
				local food, action = GetItem(foodID)
				if (food and action and not action.isoncd and MissingBuffX(Player,48,foodStack,180)) then
					cd("[PreCraftBuff]: Need to eat.",3)
					e_precraftbuff.activity = "eat"
					e_precraftbuff.id = foodID
					e_precraftbuff.requiresLogClose = true
					return true
				end
			end
		end
		
		local canUse,manualItem = CanUseExpManual()
		if (canUse and table.valid(manualItem)) then
			d("[NodePreBuff]: Need to use an exp manual.")
			e_precraftbuff.activity = "usemanual"
			e_precraftbuff.item = manualItem
			e_precraftbuff.requiresLogClose = true
			return true
		end
		
		local canUseTea,teaItem = ffxiv_craft.CanUseTea()
		if (canUseTea and table.valid(teaItem)) then
			d("[NodePreBuff]: Need to use a Tea.")
			e_precraftbuff.activity = "usetea"
			e_precraftbuff.item = teaItem
			e_precraftbuff.requiresLogClose = true
			return true
		end
		
		local hasCollect = HasBuffs(Player,"903")
		
		local isCollectable = gCraftCollectable
		if gCraftMarkerOrProfileIndex == 1 then
			isCollectable = ml_task_hub:CurrentTask().useCollect
		end
		if ((hasCollect and not isCollectable) or (not hasCollect and isCollectable)) then
			local collect = ActionList:Get(1,ffxiv_craft.collectors[Player.job])
			if (collect) then
				e_precraftbuff.activity = "usecollect"
				e_precraftbuff.requiresLogClose = true
				return true
			end
		end
		
		if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
			local recipe = ml_task_hub:CurrentTask().recipe
			local jobRequired = recipe.class + 8
			if (Player.job ~= jobRequired) then
				cd("[PreCraftBuff]: Need to switch class.",3)
				e_precraftbuff.activity = "switchclass"
				e_precraftbuff.requiresLogClose = true
				return true
			end
		end	
	end

	return false
end
function e_precraftbuff:execute()
	local activityItem = e_precraftbuff.item
	local activity = e_precraftbuff.activity
	
	if (e_precraftbuff.requiresLogClose) then
		if (IsControlOpen("RecipeNote")) then
			ffxiv_craft.ToggleCraftingLog()
			ml_task_hub:CurrentTask().allowWindowOpen = true
			ml_global_information.Await(5000, function () return (not IsControlOpen("RecipeNote") and not MIsLocked()) end)
			return
		end
	end
	
	if (activity == "repair") then
		cd("[PreCraftBuff]: Attempting repairs.",3)
		Repair()
		ml_global_information.Await(500)
	elseif (activity == "eat") then
		local food, action = GetItem(e_precraftbuff.id)
		if (food and action and food:IsReady(Player.id)) then
			cd("[PreCraftBuff]: Attempting to eat.",3)
			food:Cast(Player.id)
			local castid = action.id
			ml_global_information.Await(5000, function () return Player.castinginfo.lastcastid == castid end)
		end	
	elseif (activity == "switchclass") then
		local recipe = ml_task_hub:CurrentTask().recipe
		local jobRequired = recipe.class + 8
		local gearset = _G["gCraftGearset"..tostring(jobRequired)]
		cd("[PreCraftBuff]: Attempting to switch to gearset ["..tostring(gearset).."].",3)
		local commandString = "/gearset change "..tostring(gearset)
		SendTextCommand(commandString)
		ml_global_information.Await(3000)
	elseif (activity == "usemanual") then
		local manual = activityItem
		if (manual and manual:IsReady(Player.id)) then
			manual:Cast(Player.id)
			ml_global_information.Await(2000, 4000, function () return HasBuff(Player.id, 46) end)
			return
		end
	elseif (activity == "usetea") then
		local tea = activityItem
		if (tea and tea:IsReady(Player.id)) then
			tea:Cast(Player.id)
			ml_global_information.Await(2000, 4000, function () return HasBuff(Player.id, 46) end)
			return
		end
	elseif (activity == "usecollect") then
		local collect = ActionList:Get(1,ffxiv_craft.collectors[Player.job])
		local hasCollect = HasBuffs(Player,"903")
		if (collect and collect:IsReady(Player.id)) then
			if (collect:Cast()) then
				if (not hasCollect) then
					ml_global_information.Await(2500, function () return HasBuff(Player.id,903) end)
				else
					ml_global_information.Await(2500, function () return MissingBuff(Player.id,903) end)
				end
			end
		end
	end
end

c_craft = inheritsFrom( ml_cause )
e_craft = inheritsFrom( ml_effect )
function c_craft:evaluate()
	if ( ffxiv_craft.IsCrafting() or IsControlOpen("Synthesis")) then	
		if (IsControlOpen("Synthesis")) then
			local synthData = GetControlData("Synthesis")
			if (synthData) then
				ffxiv_craft.lastCraft = { id = synthData.itemid, name = synthData.name }
			end
		end	
		
		return true	
	end
    return false
end
function e_craft:execute()
	ml_task_hub:CurrentTask().recipeSelected = false
	ml_task_hub:CurrentTask().matsSet = false
	if (ml_task_hub:ThisTask().attemptedStarts > 0) then
		ml_task_hub:ThisTask().attemptedStarts = 0
		ml_task_hub:ThisTask().synthStarted = true
		ml_task_hub:ThisTask().itemsCrafted = ml_task_hub:ThisTask().itemsCrafted + 1
	end
    SkillMgr.Craft()
end

c_collectibleaddoncraft = inheritsFrom( ml_cause )
e_collectibleaddoncraft = inheritsFrom( ml_effect )
function c_collectibleaddoncraft:evaluate()
	if (IsControlOpen("SelectYesNoItem") or IsControlOpen("SelectYesNoCountItem")) then
		local info = GetControlData("SelectYesNoCountItem")
		if (table.valid(info)) then
			local validCollectible = false
			
			local job = Player.job
			local lastCraft = ffxiv_craft.lastCraft --= { id = synthData.itemid, name = synthData.name }
			
			if (table.valid(lastCraft) and table.valid(gCraftCollectablePresets)) then
				for i,collectable in pairsByKeys(gCraftCollectablePresets) do
					if (string.valid(collectable.name) and type(collectable.value) == "number") then
						local foundMatch = false
						if (lastCraft.name == collectable.name) then
							foundMatch = true
						else
							local itemid = AceLib.API.Items.GetIDByName(collectable.name)
							if (itemid and itemid == lastCraft.id ) then
								foundMatch = true
							end
						end
						
						if (foundMatch) then
							if (info.collectability >= tonumber(collectable.value)) then
								validCollectible = true
							else
								gd("Collectibility was too low ["..tostring(info.collectability).."].",1)
							end
						end
					end
					
					if (validCollectible) then
						break
					end
				end
			end	
			
			if (not validCollectible) then
				d("Cannot collect item ["..info.name.."], collectibility rating not approved.",1)
				UseControlAction("SelectYesNoCountItem","No")
			else
				d("Attempting to collect item ["..info.name.."], collectibility rating approved.",1)
				UseControlAction("SelectYesNoCountItem","Yes")
			end
			ml_global_information.Await(3000, function () return not IsControlOpen("SelectYesNoCountItem") end)				
			return true
		end
	end
	return false
end
function e_collectibleaddoncraft:execute()
	ml_task_hub:ThisTask().preserveSubtasks = true
end

c_quicksynth = inheritsFrom( ml_cause )
e_quicksynth = inheritsFrom( ml_effect )
function c_quicksynth:evaluate()
	return IsControlOpen("SynthesisSimple")
end
function e_quicksynth:execute()
	if (Player.action == 241) then
		ffxiv_craft.tracking.quickTimer = Now() + 7000
	end
	
	if (Now() >= ffxiv_craft.tracking.quickTimer) then
		if (UseControlAction("SynthesisSimple","Quit")) then
			ml_global_information.Await(6000)
			return true
		end
	end
	
	
	
	
end

c_selectcraft = inheritsFrom( ml_cause )
e_selectcraft = inheritsFrom( ml_effect )
function c_selectcraft:evaluate()
	
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local orders = ffxiv_craft.orders
		for id,order in pairs(orders) do
			if (order.completed == nil) then
				cd("[SelectCraft]: Initializing the completion status for id ["..tostring(id).."].",3)
				orders[id].completed = false
			end
			if (order.completed == false and order.skip ~= true) then
				local canCraft = AceLib.API.Items.CanCraft(id)
				if (canCraft) then
					cd("[SelectCraft]: Found an incomplete order ["..tostring(id).."], select a new craft.",3)
					return true
				end
			end
		end
		
		ffxiv_dialog_manager.IssueStopNotice("Nothing Craftable", "You cannot craft any of the items in the profile.", "okonly")
	else
		return true
	end
	return false
end
function e_selectcraft:execute()
	local newTask = ffxiv_task_craftitems.Create()
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local orders = ffxiv_craft.orders
		
		local sortfunc = function(orders,a,b) 
			return (orders[a].page < orders[b].page) or (orders[a].page == orders[b].page and orders[a].level < orders[b].level) 
		end
		
		local foundSelection = false
		for id,order in spairs(orders, sortfunc) do
			if (not order.completed and not order.skip) then
				local canCraft = AceLib.API.Items.CanCraft(id)
				if (canCraft) then
					
					local itemid = order.item
					local itemcount = 0
					if (order.collect) then
						itemcount = itemcount + ItemCount(itemid + 500000)
					elseif (order.requirehq) then
						itemcount = itemcount + ItemCount(itemid + 1000000)
					elseif (order.counthq) then
						itemcount = itemcount + ItemCount(itemid,true)
					else
						itemcount = itemcount + ItemCount(itemid)
					end
					
					newTask.startingCount = itemcount
					cd("[SelectCraft]: Starting Amount :"..tostring(itemcount)..".",3)
					newTask.requiredItems = order.amount
					cd("[SelectCraft]: Required Amount :"..tostring(order.amount)..".",3)
					newTask.requireHQ = order.requirehq
					newTask.requireCollect = order.collect
					newTask.requiredCP = order.requiredcp
					cd("[SelectCraft]: Required requiredcp :"..tostring(order.requiredcp)..".",2)
					newTask.countHQ = order.counthq
					newTask.itemid = order.item
					newTask.useQuick = order.usequick
					newTask.useCollect = order.collect
					newTask.useHQ = order.usehq
					cd("[SelectCraft]: Order HQ Status :"..tostring(order.usehq)..".",3)
					newTask.skillProfile = order.skillprofile
					
					for i = 1,6 do
						newTask["hq"..tostring(i)] = IsNull(order["hq"..tostring(i)],0)
						newTask["hq"..tostring(i).."min"] = IsNull(order["hq"..tostring(i).."min"],0)
					end
					
					newTask.recipe = { id = order.id, class = order.class, page = order.page }
					
					cd("[SelectCraft]: Can craft id ["..tostring(id).."], recipe details [ id = "..tostring(order.id).."].",2)
					cd("[SelectCraft]: RecipeDetails ["..tostring(order.class)..","..tostring(order.page).."].",2)
					
					foundSelection = true
				else
					cd("[SelectCraft]: Cannot undertake ["..tostring(id).."], not craftable.",3)
				end
			else
				cd("[SelectCraft]: Cannot undertake ["..tostring(id).."] as it has been completed.",3)
			end
			
			if (foundSelection) then
				break
			end
		end
		
		if (foundSelection) then
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	elseif  gCraftMarkerOrProfileIndex ~= 1 then
		newTask.maxItems = tonumber(gCraftMaxItems) or 0
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	end
end

ffxiv_task_craftitems = inheritsFrom(ml_task)
ffxiv_task_craftitems.name = "LT_CRAFTITEMS"
function ffxiv_task_craftitems.Create()
    local newinst = inheritsFrom(ffxiv_task_craftitems)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_craft members
	newinst.synthStarted = false
	newinst.attemptedStarts = 0
	newinst.itemsCrafted = 0
	newinst.allowWindowOpen = true
	newinst.maxItems = 0
	
	newinst.startingCount = 0
	newinst.requiredItems = 0
	newinst.requiredCP = 0
	newinst.requireHQ = false
	newinst.requireCollect = false
	newinst.countHQ = false
	newinst.itemid = 0
	newinst.useQuick = false
	newinst.useCollect = false
	newinst.useHQ = false
	newinst.recipe = {}
	newinst.recipeSelected = false
	newinst.matsSet = false
	newinst.skillProfile = ""
	newinst.quickTimer = 0
	
	newinst.failedAttempts = 0
    
    return newinst
end

function ffxiv_task_craftitems:Init()
	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 150 )
    self:add( ke_inventoryFull, self.process_elements)
	
	local ke_reachedCraftLimit = ml_element:create( "ReachedCraftLimit", c_craftlimit, e_craftlimit, 140 )
    self:add(ke_reachedCraftLimit, self.process_elements)
	
	local ke_precraftbuff = ml_element:create( "PreCraftBuff", c_precraftbuff, e_precraftbuff, 120 )
    self:add(ke_precraftbuff, self.process_elements)
	
	local ke_quickSynth = ml_element:create( "QuickSynth", c_quicksynth, e_quicksynth, 80 )
    self:add( ke_quickSynth, self.process_elements)

	local ke_startCraft = ml_element:create( "StartCraft", c_startcraft, e_startcraft, 70 )
    self:add(ke_startCraft, self.process_elements)
	
	local ke_craft = ml_element:create( "Crafting", c_craft, e_craft, 60 )
    self:add(ke_craft, self.process_elements)   
	
	local ke_opencraftlog = ml_element:create( "OpenCraftingLog", c_opencraftwnd, e_opencraftwnd, 50 )
    self:add(ke_opencraftlog, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_craftitems:task_complete_eval()
	return false
end

function ffxiv_task_craftitems:task_complete_execute()
	self.completed = true
end

function ffxiv_task_craftitems:task_fail_eval()
	return false
end

function ffxiv_task_craftitems:task_fail_execute()
    self.valid = false
end

function ffxiv_task_craft:Init()
    --init Process() cnes
	local ke_collectible = ml_element:create( "Collectible", c_collectibleaddoncraft, e_collectibleaddoncraft, 150 )
    self:add( ke_collectible, self.overwatch_elements)
	
	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 140 )
    self:add( ke_inventoryFull, self.process_elements)
	
	local ke_autoEquip = ml_element:create( "AutoEquip", c_autoequip, e_autoequip, 130 )
    self:add( ke_autoEquip, self.process_elements)
	
	local ke_selectCraft = ml_element:create( "SelectCraft", c_selectcraft, e_selectcraft, 100 )
    self:add(ke_selectCraft, self.process_elements)
end

function ffxiv_task_craft.SetModeOptions()
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

-- New GUI.
function ffxiv_task_craft:UIInit()
	gCrafts = {"CRP","BSM","ARM","GSM","LTW","WVR","ALC","CUL"}
	ffxiv_craft.profiles, ffxiv_craft.profilesDisplay = GetPublicProfiles(ffxiv_craft.profilePath,".*lua")
	
	local uuid = GetUUID()
	if (Settings.FFXIVMINION.gLastCraftProfiles == nil) then
		Settings.FFXIVMINION.gLastCraftProfiles = {}
	end
	if (Settings.FFXIVMINION.gLastCraftProfiles[uuid] == nil) then
		Settings.FFXIVMINION.gLastCraftProfiles[uuid] = {}
	end
	
	_G["gCraftProfile"] = Settings.FFXIVMINION.gLastCraftProfiles[uuid] or ffxiv_craft.profilesDisplay[1]
	_G["gCraftProfileIndex"] = GetKeyByValue(gCraftProfile,ffxiv_craft.profilesDisplay) or 1
	if (ffxiv_craft.profilesDisplay[gCraftProfileIndex] ~= gCraftProfile) then
		_G["gCraftProfile"] = ffxiv_craft.profilesDisplay[gCraftProfileIndex]
	end
	ffxiv_craft.profileData = ffxiv_craft.profiles[gCraftProfile] or {}
	if (table.valid(ffxiv_craft.profileData)) then
		ffxiv_craft.orders = ffxiv_craft.profileData.orders
		ffxiv_craft.ResetOrders()
	end
	
	gCraftDebug = ffxivminion.GetSetting("gCraftDebug",false)
	local debugLevels = { 1, 2, 3 }
	gCraftDebugLevel = ffxivminion.GetSetting("gCraftDebugLevel",1)
	gCraftDebugLevelIndex = GetKeyByValue(gCraftDebugLevel,debugLevels)
	
	gCraftMinCP = ffxivminion.GetSetting("gCraftMinCP",0)
	gCraftMaxItems = ffxivminion.GetSetting("gCraftMaxItems",0)
	gCraftUseHQ = ffxivminion.GetSetting("gCraftUseHQ",false)
	gCraftCollectable = ffxivminion.GetSetting("gCraftCollectable",false)
	gCraftUseHQBackup = ffxivminion.GetSetting("gCraftUseHQBackup",false)
	
	for i = 8,15 do
		_G["gCraftGearset"..tostring(i)] = ffxivminion.GetSetting("gCraftGearset"..tostring(i),0)
	end
	
	gCraftOrderSelectIndex = 1
	gCraftOrderSelect = "CRP"
	gCraftCollectablePresets = ffxivminion.GetSetting("gCraftCollectablePresets",{})	
		
	gTeaSelect = {GetString("none"),GetString("CP"),GetString("Control"),GetString("Craftmanship"),GetString("Any")}
	gCraftTeaLevel = ffxivminion.GetSetting("gCraftTeaLevel","none")
	gCraftTeaLevelIndex = GetKeyByValue(gCraftTeaLevel,gTeaSelect)
	
	gCraftFood = ffxivminion.GetSetting("gCraftFood",GetString("none"))
	gCraftFoodIndex = 1
	glastAlertUpdate = 0
	gUseCPTea = ffxivminion.GetSetting("gUseCPTea",false)
	-- Order Stuff
	
	--Add
	gCraftOrderAddID = 0
	gCraftOrderAddAmount = 1
	gCraftOrderAddRequireHQ = false
	gCraftOrderAddRequireCP = 0
	gCraftOrderAddCountHQ = false
	gCraftOrderAddQuick = false
	gCraftOrderAddCollect = false
	gCraftOrderAddHQ = false
	gCraftOrderAddSkillProfileIndex = 1
	gCraftOrderAddSkillProfile = GetString("none")
	
	--Edit
	gCraftOrderEditID = 0
	gCraftOrderEditAmount = 1
	gCraftOrderEditRequireHQ = false
	gCraftOrderEditRequiredCP = 0
	gCraftOrderEditCountHQ = false
	gCraftOrderEditQuick = false
	gCraftOrderEditCollect = false
	gCraftOrderEditHQ = false
	gCraftOrderEditSkillProfileIndex = 1
	gCraftOrderEditSkillProfile = GetString("none")
	
	gCraftNewProfileName = ""
	
	gCraftInspectProgress = ""
	gCraftInspectDurability = ""
	gCraftInspectCraftsmanship = ""
	gCraftInspectControl = ""
	gCraftInspectREquip = ""
	gCraftInspectCrystal1 = ""
	gCraftInspectCAmount1 = ""
	gCraftInspectCrystal2 = ""
	gCraftInspectCAmount2 = ""
	gCraftInspectIngredient1 = ""
	gCraftInspectIAmount1 = ""
	gCraftInspectIngredient2 = ""
	gCraftInspectIAmount2 = ""
	gCraftInspectIngredient3 = ""
	gCraftInspectIAmount3 = ""
	gCraftInspectIngredient4 = ""
	gCraftInspectIAmount4 = ""
	gCraftInspectIngredient5 = ""
	gCraftInspectIAmount5 = ""
	gCraftInspectIngredient6 = ""
	gCraftInspectIAmount6 = ""
	gCraftInspectCanCraft = ""
	gCraftInspectCraftable = ""
	--
	for i = 1,6 do
		_G["gCraftOrderAddHQIngredient"..tostring(i)] = 0
		_G["gCraftOrderAddHQIngredient"..tostring(i).."Min"] = 0
		_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"] = false
	end
	
	for i = 1,6 do
		_G["gCraftOrderEditHQIngredient"..tostring(i)] = 0
		_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"] = 0
		_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = false
	end
	
	for k = 10,70,10 do
		_G["gCraftDictionarySelectIndex"..tostring(k)] = 1
		_G["gCraftDictionarySelect"..tostring(k)] = GetString("none")				
	end
	
	
	
	-- New Marker/Profile Settings
	gCraftMarkerOrProfileOptions = { GetString("Profile"), GetString("Quick Start Mode") }
	gCraftMarkerOrProfile = ffxivminion.GetSetting("gCraftMarkerOrProfile",GetString("Markers"))
	gCraftMarkerOrProfileIndex = ffxivminion.GetSetting("gCraftMarkerOrProfileIndex",1)
	
	if gCraftMarkerOrProfileIndex == 1 then
			self.GUI.main_tabs = GUI_CreateTabs("Craft List,Settings,Collectable,Gearsets,Debug",true)
		elseif gCraftMarkerOrProfileIndex == 2 then
			self.GUI.main_tabs = GUI_CreateTabs("Settings,Collectable,Gearsets,Debug",true)
		end
	
end

ffxiv_task_craft.GUI = {
	x = 0,
	y = 0, 
	height = 0,
	width = 0,
	
	orders = {
		open = false,
		visible = true,
		name = "Craft - Order Management",
		main_tabs = GUI_CreateTabs("Manage,Add,Edit",true),
	},
}

function ffxiv_task_craft:Draw()
	local tabindex, tabname = GUI_DrawTabs(self.GUI.main_tabs)
	local tabs = self.GUI.main_tabs
	-- Craft Mode Selections.
	GUI:Separator()
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Craft Mode")
	GUI:SameLine()
	local MarkerOrProfileWidth = GUI:GetContentRegionAvail() 
	GUI:PushItemWidth(MarkerOrProfileWidth-8)
	local MarkerOrProfile = GUI_Combo("##MarkerOrProfile", "gCraftMarkerOrProfileIndex", "gCraftMarkerOrProfile", gCraftMarkerOrProfileOptions)
	if (MarkerOrProfile) then
		-- Update tabs on change.
		if gCraftMarkerOrProfileIndex == 1 then
			self.GUI.main_tabs = GUI_CreateTabs("Craft List,Settings,Collectable,Gearsets,Debug",true)
		elseif gCraftMarkerOrProfileIndex == 2 then
			self.GUI.main_tabs = GUI_CreateTabs("Settings,Collectable,Gearsets,Debug",true)
		end
	end
	GUI:PopItemWidth()
	
	if  (gCraftMarkerOrProfileIndex == 1) then
	
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Profile")) 
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Profile Tooltip")) end
		GUI:SameLine()
		
		local profileWidth = GUI:GetContentRegionAvail()
		GUI:PushItemWidth(profileWidth-68)
		local profileChanged = GUI_Combo("##"..GetString("Profile"), "gCraftProfileIndex", "gCraftProfile", ffxiv_craft.profilesDisplay)
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Profile Tooltip")) end
		GUI:PopItemWidth()
		if (profileChanged) then
			ffxiv_craft.profileData = ffxiv_craft.profiles[gCraftProfile]
			local uuid = GetUUID()
			Settings.FFXIVMINION.gLastCraftProfiles[uuid] = gCraftProfile
			ffxiv_craft.orders = ffxiv_craft.profileData.orders
			ffxiv_craft.ResetOrders()
		end
		GUI:PopItemWidth()
		GUI:SameLine()
		if (GUI:ImageButton("##main-order-edit",ml_global_information.path.."\\GUI\\UI_Textures\\w_eye.png", 14, 14)) then
			if (gCraftProfile ~= GetString("none")) then
				ffxiv_task_craft.GUI.orders.open = not ffxiv_task_craft.GUI.orders.open
			end
		end
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Opens the Crafting Order Editor.")) end
		GUI:SameLine(0,5)
		if (GUI:ImageButton("##main-order-add",ml_global_information.path.."\\GUI\\UI_Textures\\addon.png", 14, 14)) then
			local vars = {
				{
					["type"] = "string",
					["var"] = "gCraftNewProfileName",
					["display"] = "##new-profile",
					["width"] = 300,
				},
				{
					["type"] = "spacing",
					["amount"] = 3,
				},
				{
					["type"] = "button",
					["display"] = "OK",
					["isdefault"] = true,
					["sameline"] = true,
					["amount"] = 50,
					["width"] = 100,
					["onclick"] = function ()
						
						GUI:CloseCurrentPopup()
						ffxiv_craft.CreateNewProfile()
						gCraftProfile = gCraftNewProfileName
						gCraftProfileIndex = GetKeyByValue(gCraftProfile,ffxiv_craft.profilesDisplay)
						local uuid = GetUUID()
						Settings.FFXIVMINION.gLastCraftProfiles[uuid] = gCraftProfile
						
					end,
				},
				{
					["type"] = "button",
					["display"] = "Cancel",
					["width"] = 100,
					["onclick"] = function ()
						GUI:CloseCurrentPopup()
					end,
				},
			}
			ffxiv_dialog_manager.IssueNotice("New Profile", "Please pick a name for the new profile.", "none", vars)
		end
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Creates a New Crafting Order profile.")) end
	end
	
	-- Orders List
	if (tabname == GetString("Craft List")) then
		if FFXIV_Common_BotRunning and (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
			if (ml_task_hub:CurrentTask() and ml_task_hub:CurrentTask().itemid ~= nil) then
				local itemid = ml_task_hub:CurrentTask().itemid
				local requiredItems = ml_task_hub:CurrentTask().requiredItems
				local requireCollect = ml_task_hub:CurrentTask().requireCollect
				local startingCount = ml_task_hub:CurrentTask().startingCount 
				local requireHQ = ml_task_hub:CurrentTask().requireHQ
				local countHQ = ml_task_hub:CurrentTask().countHQ
				local itemcount = 0
				if (requireCollect) then
					itemcount = itemcount + ItemCount(itemid + 500000)
				elseif (requireHQ) then
					itemcount = itemcount + ItemCount(itemid + 1000000)
				elseif (countHQ) then
					itemcount = itemcount + ItemCount(itemid,true)
				else
					itemcount = itemcount + ItemCount(itemid)
				end
				local remainingCount = 0
				if (requiredItems > 0) then
					remainingCount = (requiredItems - (itemcount - startingCount))
					GUI:PushItemWidth(100)
					GUI:Text("Remaining Count of Current Item: "); GUI:SameLine(); GUI:InputText("##remainingCount",remainingCount,GUI.InputTextFlags_ReadOnly)
					GUI:PopItemWidth()
				else
					GUI:PushItemWidth(100)
					GUI:Text("Remaining Count of Current Item: "); GUI:SameLine(); GUI:InputText("##TimeLeft","Inf",GUI.InputTextFlags_ReadOnly) 
					GUI:PopItemWidth()
				end
			end
		end
	
		GUI:Separator();
		GUI:Columns(8, "#craft-manage-orders", true)
		GUI:SetColumnOffset(1, 160); GUI:SetColumnOffset(2, 225); GUI:SetColumnOffset(3, 275); GUI:SetColumnOffset(4, 325); GUI:SetColumnOffset(5, 370); GUI:SetColumnOffset(6, 415); GUI:SetColumnOffset(7, 475); GUI:SetColumnOffset(8, 535);
		
		
		GUI:Text("Item"); GUI:NextColumn();
		GUI:Text("Craft"); GUI:NextColumn();
		GUI:Text("Total"); GUI:NextColumn();
		GUI:Text("HQ"); GUI:NextColumn();
		GUI:Text("COL"); GUI:NextColumn();
		GUI:Text("Edit"); GUI:NextColumn();
		GUI:Text("Remove"); GUI:NextColumn();
		GUI:Text("Alert"); GUI:NextColumn();
		GUI:Separator();
		
		local orders = ffxiv_craft.orders
		if (table.valid(orders)) then
			local sortfunc = function(orders,a,b) 
				return (orders[a].page < orders[b].page) or (orders[a].page == orders[b].page and orders[a].level < orders[b].level) 
			end
			for id,order in spairs(orders, sortfunc) do
				GUI:AlignFirstTextHeightToWidgets(); GUI:Text(order.name);
				
				itemcount = order["itemcount"]
				itemcountHQ = order["itemcounthq"]
				itemcountCollectable = order["itemcountcollectable"]
				GUI:NextColumn()
				GUI:AlignFirstTextHeightToWidgets(); GUI:InputText("##amount",order.amount,GUI.InputTextFlags_ReadOnly) ; GUI:NextColumn()
				GUI:AlignFirstTextHeightToWidgets(); GUI:InputText("##itemcount",itemcount,GUI.InputTextFlags_ReadOnly) ; 
				GUI:NextColumn()
				GUI:AlignFirstTextHeightToWidgets(); GUI:InputText("##itemcountHQ",itemcountHQ,GUI.InputTextFlags_ReadOnly) ; 
				GUI:NextColumn()
				GUI:AlignFirstTextHeightToWidgets(); GUI:InputText("##itemcountCollectable",itemcountCollectable,GUI.InputTextFlags_ReadOnly) ; 
				GUI:NextColumn()
				
				GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
				--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
				GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
				
				if (GUI:ImageButton("##craft-manage-edit"..tostring(id),ml_global_information.path.."\\GUI\\UI_Textures\\w_edit.png", 16, 16)) then
					gCraftOrderEditID = id
						
					gCraftOrderEditAmount = IsNull(order["amount"],0)
					gCraftOrderEditRequiredCP = IsNull(order["requiredcp"],0)
					gCraftOrderEditRequireHQ = IsNull(order["requirehq"],false)
					gCraftOrderEditCountHQ = IsNull(order["counthq"],false)
					gCraftOrderEditQuick = IsNull(order["usequick"],false)
					gCraftOrderEditCollect = IsNull(order["collect"],false)
					gCraftOrderEditHQ = IsNull(order["usehq"],false)
					gCraftOrderEditSkillProfile = IsNull(order["skillprofile"],GetString("none"))
					gCraftOrderEditSkillProfileIndex = GetKeyByValue(gCraftOrderEditSkillProfile,SkillMgr.profiles)
					for i = 1,6 do
						if (not order["hq"..tostring(i)]) then
							_G["gCraftOrderEditHQIngredient"..tostring(i)] = 0
							_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"] = 0
							_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = false
							ffxiv_craft.UpdateOrderElement()
						else
							_G["gCraftOrderEditHQIngredient"..tostring(i)] = IsNull(order["hq"..tostring(i)],0)
							_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"] = IsNull(order["hq"..tostring(i).."min"],0)
							_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = IsNull(order["hq"..tostring(i).."max"],false)
						end
					end
							
					ffxiv_craft.UpdateOrderElement()		
					ffxiv_task_craft.GUI.orders.open = true
					GUI_SwitchTab(ffxiv_task_craft.GUI.orders.main_tabs,3)
				end
				
				GUI:PopStyleColor(2)
				GUI:NextColumn()
				if (GUI:ImageButton("##craft-manage-delete"..tostring(id),ml_global_information.path.."\\GUI\\UI_Textures\\bt_alwaysfail_fail.png", 16, 16)) then
					ffxiv_craft.DeleteOrder(id)
				end
				GUI:NextColumn()
				GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
				--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
				GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
				ffxiv_craft.UpdateAlertElement()
				
				local uiAlert = IsNull(order["uialert"],GetString("skillprofile"))
				
				if uiAlert == "skip" then
					local child_color = { r = 1, g = .90, b = .33, a = .0 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##skip-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text("Skip")
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Recipie Set to Skip.")) end
				elseif uiAlert == "skillprofile" then
					local child_color = { r = 1, g = .90, b = .33, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##skillprofile-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text("Skill")
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("No Skill Profile Set.")) end
				elseif uiAlert == "lowcp" then
					local child_color = { r = .95, g = .69, b = .2, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##lowcp-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text("CP")
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Not Craftable. CP Below Task Requirement.")) end
				elseif uiAlert == "cantCraft" then
					local child_color = { r = .50, g = 0.05, b = .2, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##cantCraft-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text("Alert")
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Not Craftable. May be missing materials or level to low.")) end
				elseif uiAlert == "canCraft" then
					local child_color = { r = .02, g = .79, b = .24, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##canCraft-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text("OK")
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Craftable.")) end
				end
						
				GUI:PopStyleColor(2)
				GUI:NextColumn()
			end
		end
		GUI:Columns(1)
	end
	
	
	-- Crafting Settings
	if (tabname == GetString("Settings")) then
		
		GUI:Columns(2)
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Food"))
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Show Usable Only"))
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use Exp Manuals"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow use of Experience boost manuals.")) end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use CP Tea"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow use of CP boost Tea.")) end
		GUI:NextColumn()
		local CraftStatusWidth = GUI:GetContentRegionAvail()
		GUI:PushItemWidth(CraftStatusWidth-8)
		GUI_Combo("##food", "gCraftFoodIndex", "gCraftFood", gFoods)
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("This option will override any Profile food choice.")
		end
		GUI_Capture(GUI:Checkbox("##Show Usable Onlyfood",gFoodAvailableOnly),"gFoodAvailableOnly");
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("If this option is on, only available items will be shown.")
		end
		GUI:SameLine(0,5)
		local buttonBG = ml_gui.style.current.colors[GUI.Col_Button]
		GUI:PushStyleColor(GUI.Col_Button, buttonBG[1], buttonBG[2], buttonBG[3], 1)
		GUI:PushStyleColor(GUI.Col_ButtonActive, buttonBG[1], buttonBG[2], buttonBG[3], 1)
		if (GUI:ImageButton("##craft-food-refresh",ml_global_information.path.."\\GUI\\UI_Textures\\change.png", 14, 14)) then
			ffxivminion.FillFoodOptions()
		end
		GUI:PopStyleColor(2)		
		
		GUI_Capture(GUI:Checkbox("##"..GetString("Use Exp Manuals"),gUseExpManuals),"gUseExpManuals")
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow use of Experience boost manuals.")) end
		
		if (gTeaSelect ~= gCraftTeaLevel) then
			gCraftTeaLevel = gTeaSelect
		end
		GUI_Combo("##tea", "gCraftTeaLevelIndex", "gCraftTeaLevel", gTeaSelect)
		
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow use of CP boost Tea.")) end
		GUI:Columns()
		GUI:Separator()
		if gCraftMarkerOrProfileIndex ~= 1 then
			GUI:Columns(2)
			GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Collectable"))
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Enable Collectable Synthesis")) end
			GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Craft Amount"))
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("How many crafts to complete before stopping.")) end
			GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Minimum CP"))
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("CP required before starting the craft. (Useful for CP food)")) end
			GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use HQ Mats"))
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow the use of HQ materials while crafting.")) end
			if gCraftUseHQ then
				GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Only If Necesssary"))
				if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Only use HQ materials if there are no NQ materials left.")) end
			end
			GUI:NextColumn()
			local CraftStatusWidth2 = GUI:GetContentRegionAvail()
			GUI:PushItemWidth(CraftStatusWidth2-8)
			GUI_Capture(GUI:Checkbox("##Collectable",gCraftCollectable),"gCraftCollectable")
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Enable Collectable Synthesis")) end
			GUI_Capture(GUI:InputInt("##"..GetString("Craft Amount"),gCraftMaxItems,0,0),"gCraftMaxItems")
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("How many crafts to complete before stopping.")) end
			GUI_Capture(GUI:InputInt("##"..GetString("Minimum CP"),gCraftMinCP,0,0),"gCraftMinCP")
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("CP required before starting the craft. (Useful for CP food)")) end
			GUI_Capture(GUI:Checkbox("##"..GetString("Use HQ Mats"),gCraftUseHQ),"gCraftUseHQ")
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow the use of HQ materials while crafting.")) end
			if gCraftUseHQ then
				GUI_Capture(GUI:Checkbox("##"..GetString("Only If Necesssary"),gCraftUseHQBackup),"gCraftUseHQBackup")
				if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Only use HQ materials if there are no NQ materials left.")) end
			end	
			GUI:PopItemWidth()
			GUI:Columns()
		end
		GUI:Separator()
	end
	-- Collectable Table
	if (tabname == GetString("Collectable")) then
		local CollectableFullWidth = GUI:GetContentRegionAvail()-8
		if (GUI:Button("Use Known Defaults",CollectableFullWidth,20)) then
			GUI_Set("gCraftCollectablePresets",{})
			for k,v in pairs(ffxiv_craft.collectibles) do
				local newCollectable = { name = v.name, value = v.minimum }
				table.insert(gCraftCollectablePresets,newCollectable)
			end
			GUI_Set("gCraftCollectablePresets",gCraftCollectablePresets)
		end
		if (GUI:Button("Add Collectable",CollectableFullWidth,20)) then
			local newCollectable = { name = "", value = 0 }
			table.insert(gCraftCollectablePresets,newCollectable)
			GUI_Set("gCraftCollectablePresets",gCraftCollectablePresets)
		end
		
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Add a new Collectable to the list below.")) end
		GUI:Columns(2)
		local CollectableWidth1 = GUI:GetContentRegionAvail()
		GUI:Text(GetString("Item Name"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Case-sensitive item name for the item to become a collectable.")) end
		GUI:NextColumn()
		local CollectableWidth2 = GUI:GetContentRegionAvail()
		GUI:Text(GetString("Minimum Value"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Minimum Value for Item")) end
		GUI:Columns()
		GUI:Separator()
		if (table.valid(gCraftCollectablePresets)) then
		GUI:Columns(2)
			for i,collectable in pairsByKeys(gCraftCollectablePresets) do
				GUI:PushItemWidth(CollectableWidth1-8)
				local newName = GUI:InputText("##craft-collectablepair-name"..tostring(i),collectable.name)
				if (newName ~= collectable.name) then
					gCraftCollectablePresets[i].name = newName
					GUI_Set("gCraftCollectablePresets",gCraftCollectablePresets)
				end
				if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Case-sensitive item name for the item to become a collectable.")) end
				GUI:PopItemWidth()
				GUI:NextColumn()
				GUI:PushItemWidth(CollectableWidth2-28)
				local newValue = GUI:InputInt("##craft-collectablepair-value"..tostring(i),collectable.value,0,0)
				if (newValue ~= collectable.value) then
					gCraftCollectablePresets[i].value = newValue
					GUI_Set("gCraftCollectablePresets",gCraftCollectablePresets)
				end
				if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Minimum Value for Item")) end
				GUI:PopItemWidth()
				GUI:SameLine()
				GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
				--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
				GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
				if (GUI:ImageButton("##craft-collectablepair-delete"..tostring(i),ml_global_information.path.."\\GUI\\UI_Textures\\bt_alwaysfail_fail.png", 14, 14)) then
					gCraftCollectablePresets[i] = nil
					GUI_Set("gCraftCollectablePresets",gCraftCollectablePresets)
				end
				GUI:PopStyleColor(2)
				GUI:NextColumn()
			end
		GUI:Columns()
		end
	end
	-- Class Gear Sets
	if (tabname == GetString("Gearsets")) then
		GUI:PushItemWidth(40)
		local GearSetsColumnWidth = (GUI:GetContentRegionAvail()/2)-50
		for i = 8,15 do
			GUI:AlignFirstTextHeightToWidgets()
			GUI:Text(gCrafts[i-7])
			GUI:SameLine()
			GUI:PushItemWidth(GearSetsColumnWidth)
			GUI_Capture(GUI:InputInt("##craft-gearset"..tostring(i),_G["gCraftGearset"..tostring(i)],0,0),"gCraftGearset"..tostring(i))
			GUI:PopItemWidth()
			if (i ~= 9 and i ~= 11 and i ~= 13 and i ~= 15) then
				GUI:SameLine()
			end
		end
		GUI:PopItemWidth()
	end
	if (tabname == GetString("Debug")) then
		GUI:Columns(2)
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Craft Debug"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Enable Debug messages in console.")) end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Debug Level"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Change the Debug message level. (The higher the number the more detailed the messages)")) end
		GUI:NextColumn()
		local CraftStatusWidth = GUI:GetContentRegionAvail()
		GUI:PushItemWidth(CraftStatusWidth-8)
		GUI_Capture(GUI:Checkbox("##"..GetString("Craft Debug"),gCraftDebug),"gCraftDebug")
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Enable Debug messages in console.")) end
		
		local debugLevels = { 1, 2, 3}
		gCraftDebugLevelIndex = GetKeyByValue(gCraftDebugLevel,debugLevels) or 1
		if (debugLevels[gCraftDebugLevelIndex] ~= gCraftDebugLevel) then
			gCraftDebugLevel = debugLevels[gCraftDebugLevelIndex]
		end
		GUI_Combo("##Debug Level", "gCraftDebugLevelIndex", "gCraftDebugLevel", debugLevels)
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Change the Debug message level. (The higher the number the more detailed the messages)")) end
		
		GUI:PopItemWidth()
		GUI:Columns()
	end
end

function ffxiv_craft.IsCrafting()
	return (IsControlOpen("Synthesis") or IsControlOpen("SynthesisSimple"))
end

function ffxiv_craft.ToggleCraftingLog()
	if (IsControlOpen("RecipeNote")) then
		if (UseControlAction("RecipeNote","Close")) then
			return true
		end
	else
		local logOpen = ActionList:Get(10,9)
		if (logOpen and logOpen.usable) then
			if (logOpen:Cast(Player.id)) then
				ml_global_information.Await(1000, 1500, function () return IsControlOpen("RecipeNote") end)
			end
		end
	end
end

function ffxiv_craft.ResetOrders()
	local orders = ffxiv_craft.orders
	if (table.valid(orders)) then
		for id,order in pairs(orders) do
			orders[id].completed = false
		end
	end
end

function ffxiv_craft.SaveProfile(strName)
	strName = IsNull(strName,"")
	
	local info = {}
	if (table.valid(ffxiv_craft.orders)) then
		info.orders = ffxiv_craft.orders
	else
		info.orders = {}
	end
	
	if (strName ~= "") then
		persistence.store(ffxiv_craft.profilePath..strName..".lua",info)
	else
		persistence.store(ffxiv_craft.profilePath..gCraftProfile..".lua",info)
	end
	
	ffxiv_craft.profiles, ffxiv_craft.profilesDisplay = GetPublicProfiles(ffxiv_craft.profilePath,".*lua")
end

function ffxiv_craft.CreateNewProfile()
	if (ValidString(gCraftNewProfileName)) then
		d("Creating new profile ["..tostring(gCraftNewProfileName).."].")
		ffxiv_craft.SaveProfile(gCraftNewProfileName)
		ffxiv_craft.profiles, ffxiv_craft.profilesDisplay = GetPublicProfiles(ffxiv_craft.profilePath,".*lua")
	end
end

function ffxiv_craft.AddToProfile()
	local recipeid = tonumber(gCraftOrderAddID) or 0
	
	if (recipeid ~= 0) then
		local orders = ffxiv_craft.orders
		if (orders[recipeid] == nil) then
			local recipeDetails = AceLib.API.Items.GetRecipeDetails(recipeid)
			local thisOrder = { 	
				id = recipeid, 
				item = recipeDetails.id, 
				name = recipeDetails.name, 
				level = recipeDetails.attemptlevel,
				class = recipeDetails.class, 
				page = recipeDetails.page,
				amount = gCraftOrderAddAmount, 
				usequick = gCraftOrderAddQuick, 
				collect = gCraftOrderAddCollect, 
				usehq = gCraftOrderAddHQ, 
				skillprofile = gCraftOrderAddSkillProfile,
				requirehq = gCraftOrderAddRequireHQ, 
				requiredcp = gCraftOrderAddRequireCP, 
				counthq = gCraftOrderAddCountHQ,
				skip = false,
				completed = false,
			}
			
			for i = 1,6 do
				thisOrder["hq"..tostring(i).."max"] = IsNull(_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"],false)
				thisOrder["hq"..tostring(i).."min"] = IsNull(_G["gCraftOrderAddHQIngredient"..tostring(i).."Min"],0)
				thisOrder["hq"..tostring(i)] = IsNull(_G["gCraftOrderAddHQIngredient"..tostring(i)],0)
			end
			
			orders[recipeid] = thisOrder
			ffxiv_craft.SaveProfile()
		end
	end
end

function ffxiv_craft.UsingProfile()
	return table.valid(ffxiv_craft.orders)
end

function ffxiv_craft.DeleteOrder(key)
	local key = (tonumber(key) or tonumber(gCraftOrderEditID) or 0)
	
	local orders = ffxiv_craft.orders
	if (orders and orders[key]) then
		if (TableSize(orders) > 1) then
			ffxiv_craft.orders[key] = nil
		else
			ffxiv_craft.orders = {}
		end
		ffxiv_craft.SaveProfile()
	end
end
	
function ffxiv_craft.UpdateAlertElement()
	
	if (gBotMode == GetString("craftMode") and gCraftMarkerOrProfileIndex ~= 1) or gBotMode ~= GetString("craftMode") or (Now() < ffxiv_craft.tracking.measurementDelay) then
		return false
	end
	
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local playercp = Player.cp.max
		local orders = ffxiv_craft.orders
		local foundSelection = false
		if (table.valid(orders)) then
		
			
			for id,order in pairs(orders) do
				
				if order["uialert"] == nil then
					order["uialert"] = "None"
				end
				if order["itemcount"] == nil then
					order["itemcount"] = 0
				end
				if order["itemcounthq"] == nil then
					order["itemcounthq"] = 0
				end
				if order["itemcountcollectable"] == nil then
					order["itemcountcollectable"] = 0
				end
				if order["skillprofile"] == nil then
					order["skillprofile"] = GetString("none")
				end
				if order["requiredcp"] == nil then
					order["requiredcp"] = 0
				end
				if order["collect"] == nil then
					order["collect"] = false
				end
					
				local canCraft = AceLib.API.Items.CanCraft(id)
				local okCP = (order["requiredcp"] ~= nil and (playercp >= order["requiredcp"])) or (order["usequick"] == true)
				if order["skip"] == true then
					order["uialert"] = "skip"
				elseif (order["skillprofile"] == "None") and (order["usequick"] == false) then
					order["uialert"] = "skillprofile"
				elseif not okCP then
					order["uialert"] = "lowcp"
				elseif not canCraft then
					order["uialert"] = "cantCraft"
				elseif canCraft then
					order["uialert"] = "canCraft"
				end
				
				local itemid = order.item
				local itemcount = 0
				local itemcountHQ = 0
				local itemcountCollectable = 0
				itemcount = itemcount + ItemCount(itemid,true)
				itemcountHQ = itemcountHQ + ItemCount(itemid + 1000000)
				itemcountCollectable = itemcountCollectable + ItemCount(itemid + 500000)
				if order["itemcount"] ~= itemcount then
					order["itemcount"]= itemcount
				end
				if order["itemcounthq"] ~= itemcountHQ then
					order["itemcounthq"]= itemcountHQ
				end
				if order["itemcountcollectable"] ~= itemcountCollectable then
					order["itemcountcollectable"]= itemcountCollectable
				end
			end
		end
		ffxiv_craft.SaveProfile()
		ffxiv_craft.tracking.measurementDelay = Now() + 10000
	end
end	

function ffxiv_craft.UpdateOrderElement()
	local key = tonumber(gCraftOrderEditID) or 0
	local orders = ffxiv_craft.orders
	if (table.valid(orders)) then
		local thisOrder = orders[key]
		if (thisOrder) then
			thisOrder["amount"] = gCraftOrderEditAmount
			thisOrder["requiredcp"] = gCraftOrderEditRequiredCP
			thisOrder["requirehq"] = gCraftOrderEditRequireHQ
			thisOrder["counthq"] = gCraftOrderEditCountHQ
			thisOrder["usequick"] = gCraftOrderEditQuick
			thisOrder["collect"] = gCraftOrderEditCollect
			thisOrder["usehq"] = gCraftOrderEditHQ
			thisOrder["skillprofile"] = IsNull(gCraftOrderEditSkillProfile,GetString("none"))
			
			for i = 1,6 do
				thisOrder["hq"..tostring(i).."max"] = IsNull(_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"],false)
				thisOrder["hq"..tostring(i).."min"] = IsNull(_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"],0)
				thisOrder["hq"..tostring(i)] = IsNull(_G["gCraftOrderEditHQIngredient"..tostring(i)],0)
			end
			
			ffxiv_craft.SaveProfile()
			ffxiv_craft.tracking.measurementDelay = Now()
		end
	end
end

function ffxiv_craft.InspectRecipe(key)
	local key = tonumber(key) or 0
	local recipeDetails = AceLib.API.Items.GetRecipeDetails(key)
	gCraftInspectProgress = recipeDetails.progress or ""
	gCraftInspectDurability = recipeDetails.durability or ""
	gCraftInspectCraftsmanship = recipeDetails.craftsmanship or ""
	gCraftInspectControl = recipeDetails.control or ""
	gCraftInspectREquip = IIF(recipeDetails.requiredequip ~= 0,IsNull(recipeDetails.requipname,"").."["..IsNull(recipeDetails.requiredequip,"").."]","")
	gCraftInspectCrystal1 = IIF(recipeDetails.crystal1 ~= 0,IsNull(recipeDetails.c1name,"").."["..IsNull(recipeDetails.crystal1,"").."]","")
	gCraftInspectCAmount1 = IIF(recipeDetails.crystal1 ~= 0,tostring(IsNull(recipeDetails.camount1,0)).."("..IsNull(ItemCount(recipeDetails.crystal1,{2001 },true),0)..")","")
	gCraftInspectCrystal2 = IIF(recipeDetails.crystal2 ~= 0,IsNull(recipeDetails.c2name,"").."["..IsNull(recipeDetails.crystal2,"").."]","")
	gCraftInspectCAmount2 = IIF(recipeDetails.crystal2 ~= 0,tostring(IsNull(recipeDetails.camount2,0)).."("..IsNull(ItemCount(recipeDetails.crystal2,{2001 },true),0)..")","")
	gCraftInspectIngredient1 = IIF(recipeDetails.ingredient1 ~= 0,IsNull(recipeDetails.ing1name,"").."["..IsNull(recipeDetails.ingredient1,"").."]","")
	gCraftInspectIAmount1 = IIF(recipeDetails.iamount1 > 0,tostring(IsNull(recipeDetails.iamount1,0)).."("..IsNull(ItemCount(recipeDetails.ingredient1,{0,1,2,3},true),0)..")","")
	gCraftInspectIngredient2 = IIF(recipeDetails.ingredient2 ~= 0,IsNull(recipeDetails.ing2name,"").."["..IsNull(recipeDetails.ingredient2,"").."]","")
	gCraftInspectIAmount2 = IIF(recipeDetails.iamount2 > 0,tostring(IsNull(recipeDetails.iamount2,0)).."("..IsNull(ItemCount(recipeDetails.ingredient2,{0,1,2,3},true),0)..")","")
	gCraftInspectIngredient3 = IIF(recipeDetails.ingredient3 ~= 0,IsNull(recipeDetails.ing3name,"").."["..IsNull(recipeDetails.ingredient3,"").."]","")
	gCraftInspectIAmount3 = IIF(recipeDetails.iamount3 > 0,tostring(IsNull(recipeDetails.iamount3,0)).."("..IsNull(ItemCount(recipeDetails.ingredient3,{0,1,2,3},true),0)..")","")
	gCraftInspectIngredient4 = IIF(recipeDetails.ingredient4 ~= 0,IsNull(recipeDetails.ing4name,"").."["..IsNull(recipeDetails.ingredient4,"").."]","")
	gCraftInspectIAmount4 = IIF(recipeDetails.iamount4 > 0,tostring(IsNull(recipeDetails.iamount4,0)).."("..IsNull(ItemCount(recipeDetails.ingredient4,{0,1,2,3},true),0)..")","")
	gCraftInspectIngredient5 = IIF(recipeDetails.ingredient5 ~= 0,IsNull(recipeDetails.ing5name,"").."["..IsNull(recipeDetails.ingredient5,"").."]","")
	gCraftInspectIAmount5 = IIF(recipeDetails.iamount5 > 0,tostring(IsNull(recipeDetails.iamount5,0)).."("..IsNull(ItemCount(recipeDetails.ingredient5,{0,1,2,3},true),0)..")","")
	gCraftInspectIngredient6 = IIF(recipeDetails.ingredient6 ~= 0,IsNull(recipeDetails.ing6name,"").."["..IsNull(recipeDetails.ingredient6,"").."]","")
	gCraftInspectIAmount6 = IIF(recipeDetails.iamount6 > 0,tostring(IsNull(recipeDetails.iamount6,0)).."("..IsNull(ItemCount(recipeDetails.ingredient6,{0,1,2,3},true),0)..")","")

	local canCraft,maxAmount = AceLib.API.Items.CanCraft(key)
	gCraftInspectCanCraft = tostring(canCraft)
	gCraftInspectCraftable = maxAmount
	
	GUI:Columns(2, "##craft-recipe-inspection", true)
	GUI:SetColumnOffset(1, 200); GUI:SetColumnOffset(2, 400)
	GUI:Text("Can Craft"); GUI:NextColumn(); GUI:Text(gCraftInspectCanCraft); GUI:NextColumn();
	GUI:Text("Amount Craftable"); GUI:NextColumn(); GUI:Text(gCraftInspectCraftable); GUI:NextColumn();
	
	GUI:Text("Progress"); GUI:NextColumn(); GUI:Text(gCraftInspectProgress); GUI:NextColumn();
	GUI:Text("Durability"); GUI:NextColumn(); GUI:Text(gCraftInspectDurability); GUI:NextColumn();
	GUI:Text("Craftsmanship"); GUI:NextColumn(); GUI:Text(gCraftInspectCraftsmanship); GUI:NextColumn();
	GUI:Text("Control"); GUI:NextColumn(); GUI:Text(gCraftInspectControl); GUI:NextColumn();
	GUI:Text("Equipment"); GUI:NextColumn(); GUI:Text(gCraftInspectREquip); GUI:NextColumn();
	if (gCraftInspectCrystal1 ~= "") then
		GUI:Text(gCraftInspectCrystal1); GUI:NextColumn(); GUI:Text(gCraftInspectCAmount1); GUI:NextColumn();
	end
	if (gCraftInspectCrystal2 ~= "") then
		GUI:Text(gCraftInspectCrystal2); GUI:NextColumn(); GUI:Text(gCraftInspectCAmount2); GUI:NextColumn();
	end
	if (gCraftInspectIngredient1 ~= "") then
		GUI:Text(gCraftInspectIngredient1); GUI:NextColumn(); GUI:Text(gCraftInspectIAmount1); GUI:NextColumn();
	end
	if (gCraftInspectIngredient2 ~= "") then
		GUI:Text(gCraftInspectIngredient2); GUI:NextColumn(); GUI:Text(gCraftInspectIAmount2); GUI:NextColumn();
	end
	if (gCraftInspectIngredient3 ~= "") then
		GUI:Text(gCraftInspectIngredient3); GUI:NextColumn(); GUI:Text(gCraftInspectIAmount3); GUI:NextColumn();
	end
	if (gCraftInspectIngredient4 ~= "") then
		GUI:Text(gCraftInspectIngredient4); GUI:NextColumn(); GUI:Text(gCraftInspectIAmount4); GUI:NextColumn();
	end
	if (gCraftInspectIngredient5 ~= "") then
		GUI:Text(gCraftInspectIngredient5); GUI:NextColumn(); GUI:Text(gCraftInspectIAmount5); GUI:NextColumn();
	end
	if (gCraftInspectIngredient6 ~= "") then
		GUI:Text(gCraftInspectIngredient6); GUI:NextColumn(); GUI:Text(gCraftInspectIAmount6); GUI:NextColumn();
	end	
	GUI:Columns(1)
end

function ffxiv_craft.GetDictionary(maxattemptlevel, craftid)
	local craftid = IsNull(craftid,0)
	local maxattemptlevel = IsNull(maxattemptlevel,10)
	if (craftid == 0) then
		local crafts = ffxiv_craft.crafts
		craftid = crafts[gCraftOrderSelect]
	end
	
	if (craftid) then
		if (ffxiv_craft.dictionaries[craftid] and ffxiv_craft.dictionariesDisplay[craftid]) then
			if (ffxiv_craft.dictionaries[craftid][maxattemptlevel] and ffxiv_craft.dictionariesDisplay[craftid][maxattemptlevel]) then
				return ffxiv_craft.dictionaries[craftid][maxattemptlevel], ffxiv_craft.dictionariesDisplay[craftid][maxattemptlevel]
			end
		end
			
		local recipes,dictionary = AceLib.API.Items.BuildRecipeString(craftid,0,(maxattemptlevel-9),maxattemptlevel)
		if (dictionary) then
			if (not ffxiv_craft.dictionaries[craftid] or not not ffxiv_craft.dictionariesDisplay[craftid]) then
				ffxiv_craft.dictionaries[craftid] = {}
				ffxiv_craft.dictionariesDisplay[craftid] = {}
			end
			ffxiv_craft.dictionaries[craftid][maxattemptlevel] = {}
			ffxiv_craft.dictionariesDisplay[craftid][maxattemptlevel]  = {}
			
			local newDictionary = { [1] = {recipeid = 0, itemid = 0, name = GetString("none")} }
			local newDisplayDictionary = { [1] = GetString("none") }
			
			local sortfunc = function(dictionary,a,b) 
				return (dictionary[a].name < dictionary[b].name)
			end
			for _,data in spairs(dictionary, sortfunc) do
				table.insert(newDictionary, {recipeid = data.recipeid, itemid = data.itemid, name = data.name})
				table.insert(newDisplayDictionary, data.name.." ["..tostring(data.recipeid).."]")
			end
			
			ffxiv_craft.dictionaries[craftid][maxattemptlevel] = newDictionary
			ffxiv_craft.dictionariesDisplay[craftid][maxattemptlevel] = newDisplayDictionary
		
			return ffxiv_craft.dictionaries[craftid][maxattemptlevel], ffxiv_craft.dictionariesDisplay[craftid][maxattemptlevel]
		end
	end
	
	return nil, nil
end

--[[
function ffxiv_craft.GUIVarUpdate(Event, NewVals, OldVals)
	local backupVals = {}
	for k,v in pairs(OldVals) do
		backupVals[k] = v
	end
    for k,v in pairs(NewVals) do
        if 	( 	k == "gCraftMinCP" or 
				k == "gCraftMaxItems" or
				k == "gCraftDebug" or
				k == "gCraftDebugLevel" or
				string.contains(tostring(k),"gCraftCollectible") or
				string.contains(tostring(k),"gCraftGearset"))				
		then
            SafeSetVar(tostring(k),v)
		elseif (k == "gCraftOrderSelect") then
			SafeSetVar(tostring(k),v)
			ffxiv_craft.SwitchCraftWindow()
		elseif (string.contains(tostring(k),"gCraftOrderEdit")) then
			ffxiv_craft.EditOrderElement(k,v)
		elseif ( k == "gProfile" and gBotMode == GetString("craftMode")) then
			ffxiv_craft.LoadProfile(v)
			Settings.FFXIVMINION["gLastCraftProfile"] = v
        end
    end
    GUI_RefreshWindow(GetString("craftMode"))
end
--]]

function ffxiv_craft.Draw( event, ticks ) 
	ffxiv_craft.UpdateAlertElement()
	if (ffxiv_task_craft.GUI.orders.open) then
		GUI:SetNextWindowSize(500,200,GUI.SetCond_FirstUseEver) --set the next window size, only on first ever	
		GUI:SetNextWindowCollapsed(false,GUI.SetCond_Always)
		
		local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
		GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
		
		ffxiv_task_craft.GUI.orders.visible, ffxiv_task_craft.GUI.orders.open = GUI:Begin(ffxiv_task_craft.GUI.orders.name, ffxiv_task_craft.GUI.orders.open)
		if ( ffxiv_task_craft.GUI.orders.visible ) then 
		
			GUI_DrawTabs(ffxiv_task_craft.GUI.orders.main_tabs)
			local tabs = ffxiv_task_craft.GUI.orders.main_tabs
			
			if (tabs.tabs[1].isselected) then
				local width, height = GUI:GetWindowSize()		
				local cwidth, cheight = GUI:GetContentRegionAvail()
				
				
				local orders = ffxiv_craft.orders
				if (table.valid(orders)) then
					
					GUI:Separator();
					GUI:Columns(7, "#craft-manage-orders", true)
					GUI:SetColumnOffset(1, 125); GUI:SetColumnOffset(2, 225); GUI:SetColumnOffset(3, 300); GUI:SetColumnOffset(4, 340); GUI:SetColumnOffset(5, 380); GUI:SetColumnOffset(6, 440);  GUI:SetColumnOffset(7, 650);	 			
					GUI:Text("Item"); GUI:NextColumn();
					GUI:Text("Recipe"); GUI:NextColumn();
					GUI:Text("Amount"); GUI:NextColumn();
					GUI:Text("Skip"); GUI:NextColumn();
					GUI:Text("Edit"); GUI:NextColumn();
					GUI:Text("Remove"); GUI:NextColumn();
					GUI:Text("Alert"); GUI:NextColumn();
					GUI:Separator();
				
					local sortfunc = function(orders,a,b) 
						return (orders[a].page < orders[b].page) or (orders[a].page == orders[b].page and orders[a].level < orders[b].level) 
					end
					for id,order in spairs(orders, sortfunc) do
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(order.name); 
						if (GUI:IsItemHovered()) then
							GUI:BeginTooltip()
							ffxiv_craft.InspectRecipe(id)
							GUI:EndTooltip()
						end						
						GUI:NextColumn()
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(id); GUI:NextColumn()
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(order.amount); GUI:NextColumn()
						
						if (order.skip == nil) then
							orders[id].skip = false
							ffxiv_craft.SaveProfile()
						end
						
						local newVal, changed = GUI:Checkbox("##skip-"..tostring(id),order.skip)
						if (changed) then
							orders[id].skip = newVal
							if orders[id].skip == true then
								orders[id].uialert = skip
							end
							ffxiv_craft.tracking.measurementDelay = Now()
						end
						GUI:NextColumn()
						
						GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
						--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
						GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
						
						if (GUI:ImageButton("##craft-manage-edit"..tostring(id),ml_global_information.path.."\\GUI\\UI_Textures\\w_edit.png", 16, 16)) then
							gCraftOrderEditID = id
							
							gCraftOrderEditAmount = IsNull(order["amount"],0)
							gCraftOrderEditCollect = IsNull(order["collect"],false)
							gCraftOrderEditRequiredCP = IsNull(order["requiredcp"],0)
							gCraftOrderEditRequireHQ = IsNull(order["requirehq"],false)
							gCraftOrderEditCountHQ = IsNull(order["counthq"],false)
							gCraftOrderEditQuick = IsNull(order["usequick"],false)
							gCraftOrderEditHQ = IsNull(order["usehq"],false)
							gCraftOrderEditSkillProfile = IsNull(order["skillprofile"],GetString("none"))
							gCraftOrderEditSkillProfileIndex = GetKeyByValue(gCraftOrderEditSkillProfile,SkillMgr.profiles)
														
							for i = 1,6 do
								if (not order["hq"..tostring(i)]) then
									_G["gCraftOrderEditHQIngredient"..tostring(i)] = 0
									_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"] = 0
									_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = false
									ffxiv_craft.UpdateOrderElement()
								else
									_G["gCraftOrderEditHQIngredient"..tostring(i)] = IsNull(order["hq"..tostring(i)],0)
									_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"] = IsNull(order["hq"..tostring(i).."min"],0)
									_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = IsNull(order["hq"..tostring(i).."max"],false)
								end
							end
							
							GUI_SwitchTab(ffxiv_task_craft.GUI.orders.main_tabs,3)
						end
						GUI:NextColumn()
						if (GUI:ImageButton("##craft-manage-delete"..tostring(id),ml_global_information.path.."\\GUI\\UI_Textures\\bt_alwaysfail_fail.png", 16, 16)) then
							ffxiv_craft.DeleteOrder(id)
						end
						GUI:NextColumn()
				GUI:PopStyleColor(2)
				GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
				--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
				GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
				ffxiv_craft.UpdateAlertElement()
				
				local uiAlert = IsNull(order["uialert"],GetString("skillprofile"))
				
				if uiAlert == "skip" then
					local child_color = { r = 1, g = .90, b = .33, a = .0 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##skip-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text("Skip")
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Recipie Set to Skip.")) end
				elseif uiAlert == "skillprofile" then
					local child_color = { r = 1, g = .90, b = .33, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##skillprofile-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text("Skill")
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("No Skill Profile Set.")) end
				elseif uiAlert == "lowcp" then
					local child_color = { r = .95, g = .69, b = .2, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##lowcp-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text("CP")
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Not Craftable. CP Below Task Requirement.")) end
				elseif uiAlert == "cantCraft" then
					local child_color = { r = .50, g = 0.05, b = .2, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##cantCraft-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text("Alert")
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Not Craftable. May be missing materials or level to low.")) end
				elseif uiAlert == "canCraft" then
					local child_color = { r = .02, g = .79, b = .24, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##canCraft-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text("OK")
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Craftable.")) end
				end
						
				GUI:PopStyleColor(2)
						GUI:NextColumn()
					end
					
					GUI:Columns(1)
				end
			end
			
			if (tabs.tabs[2].isselected) then	
				GUI:PushItemWidth(60)
				GUI_Combo("Class", "gCraftOrderSelectIndex", "gCraftOrderSelect", gCrafts)
				GUI:PopItemWidth()
				
				for k = 10,70,10 do
					local dictionary, dictionaryDisplay = ffxiv_craft.GetDictionary(k)
					if (dictionary and dictionaryDisplay) then
						--d("found dictionary for k = "..tostring(k))
						GUI:PushItemWidth(300)
						local selectionChanged = GUI_Combo(tostring(k-9).."-"..tostring(k), "gCraftDictionarySelectIndex"..tostring(k), "gCraftDictionarySelect"..tostring(k), dictionaryDisplay)
						if (selectionChanged) then
							local thisRecipe = dictionary[_G["gCraftDictionarySelectIndex"..tostring(k)]]
							if (thisRecipe) then
								gCraftOrderAddID = thisRecipe.recipeid
								gCraftOrderAddAmount = 1
								gCraftOrderAddCollect = false
								gCraftOrderAddRequireHQ = false
								gCraftOrderAddRequireCP = 0
								gCraftOrderAddCountHQ = false
								gCraftOrderAddQuick = false
								gCraftOrderAddHQ = false
								gCraftOrderAddSkillProfileIndex = 1
								gCraftOrderAddSkillProfile = GetString("none")
							end
							for j = 10,70,10 do
								if (j ~= k) then
									_G["gCraftDictionarySelectIndex"..tostring(j)] = 1
									_G["gCraftDictionarySelect"..tostring(j)] = GetString("none")		
								end
							end
						end
						GUI:PopItemWidth()
					else
						GUI:Text("Could not find display dictionary for ["..gCraftOrderSelect.."] with attempt level ["..tostring(k).."]")
					end					
				end
				
				if (gCraftOrderAddID ~= 0) then
					
					GUI:Separator()
				
					GUI:Columns(2)
					
					GUI:AlignFirstTextHeightToWidgets() GUI:Text("Amount to Craft"); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text("Use Collect"); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text("skillProfile"); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text("Required CP"); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text("Require HQ"); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text("Count HQ"); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text("Use QuickSynth"); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text("Use HQ Items"); 
					GUI:NextColumn()
					
					GUI:PushItemWidth(200)
					GUI_Capture(GUI:InputInt("##Amount to Craft",gCraftOrderAddAmount,0,0),"gCraftOrderAddAmount")
					GUI:PopItemWidth()
					GUI_Capture(GUI:Checkbox("##Use Collect",gCraftOrderAddCollect),"gCraftOrderAddCollect")
					if (not gCraftOrderAddQuick) then
						GUI:PushItemWidth(200)
						GUI_Combo(GetString("##skillProfile1"), "gCraftOrderAddSkillProfileIndex", "gCraftOrderAddSkillProfile", SkillMgr.profiles)
						GUI:PopItemWidth()
					end
					
					GUI:PushItemWidth(200)
					GUI_Capture(GUI:InputInt("##RequiredCP",gCraftOrderAddRequireCP,0,0),"gCraftOrderAddRequireCP")
					GUI_Capture(GUI:Checkbox("##Require HQ",gCraftOrderAddRequireHQ),"gCraftOrderAddRequireHQ")
					GUI_Capture(GUI:Checkbox("##Count HQ",gCraftOrderAddCountHQ),"gCraftOrderAddCountHQ")
					GUI_Capture(GUI:Checkbox("##Use QuickSynth",gCraftOrderAddQuick),"gCraftOrderAddQuick")
					GUI_Capture(GUI:Checkbox("##Use HQ Items",gCraftOrderAddHQ),"gCraftOrderAddHQ")
					GUI:PopItemWidth()
					GUI:Columns()
					if (gCraftOrderAddHQ) then						
						local recipeDetails = AceLib.API.Items.GetRecipeDetails(gCraftOrderAddID)
						if (recipeDetails) then
							
							GUI:Columns(5, "#craft-add-hq", true)
							GUI:SetColumnOffset(1, 250); GUI:SetColumnOffset(2, 325); GUI:SetColumnOffset(3, 425); GUI:SetColumnOffset(4, 525);
							GUI:AlignFirstTextHeightToWidgets()
							
							GUI:Text("Ingredient"); GUI:NextColumn();
							GUI:Text("Required"); GUI:NextColumn();
							GUI:Text("Max HQ Amount"); GUI:NextColumn();
							GUI:Text("Min HQ Amount"); GUI:NextColumn();
							GUI:Text("Use All HQ"); GUI:NextColumn();
							
							GUI:Separator();
							
							for i = 1,6 do
								local ing = recipeDetails["ingredient"..tostring(i)]
								if (ing and ing ~= 0) then
									GUI:AlignFirstTextHeightToWidgets()
									GUI:Text(recipeDetails["ing"..tostring(i).."name"]); GUI:Dummy(); GUI:NextColumn();
									GUI:AlignFirstTextHeightToWidgets()
									GUI:Text(tostring(recipeDetails["iamount"..tostring(i)])); GUI:Dummy(); GUI:NextColumn();
									
									
									GUI:PushItemWidth(50)
									local newVal, changed = GUI:InputInt("##HQ Amount"..tostring(i),_G["gCraftOrderAddHQIngredient"..tostring(i)],0,0)
									if (changed) then
										if (not GUI:IsItemActive()) then
											if (newVal > recipeDetails["iamount"..tostring(i)]) then
												newVal = recipeDetails["iamount"..tostring(i)]
											elseif (newVal < 0) then
												newVal = 0
											end
											if (newVal == recipeDetails["iamount"..tostring(i)]) then
												_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"] = true
											else
												_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"] = false
											end
										end
										_G["gCraftOrderAddHQIngredient"..tostring(i)] = newVal
										if (not GUI:IsItemActive()) then
											ffxiv_craft.UpdateOrderElement()
										end							
									end
									if (GUI:IsItemHovered()) then
										GUI:SetTooltip("Max amount of HQ items to use for this item in the craft.")
									end
									GUI:PopItemWidth()
									GUI:NextColumn();
									
									GUI:PushItemWidth(50)
									local newVal, changed = GUI:InputInt("##HQ MinAmount"..tostring(i),_G["gCraftOrderAddHQIngredient"..tostring(i).."Min"],0,0)
									if (changed) then
										if (not GUI:IsItemActive()) then
											if (newVal > recipeDetails["iamount"..tostring(i)]) then
												newVal = recipeDetails["iamount"..tostring(i)]
											elseif (newVal < 0) then
												newVal = 0
											end
										end
										_G["gCraftOrderAddHQIngredient"..tostring(i).."Min"] = newVal
										if (not GUI:IsItemActive()) then
											ffxiv_craft.UpdateOrderElement()
										end
									end
									if (GUI:IsItemHovered()) then
										GUI:SetTooltip("Minimum amount of HQ items to use for this item in the craft.")
									end
									GUI:PopItemWidth()
									GUI:NextColumn();
									
									local newVal, changed = GUI:Checkbox("##Max-"..tostring(i),_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"])
									if (changed) then
										if (newVal == false) then
											if (_G["gCraftOrderAddHQIngredient"..tostring(i)] == recipeDetails["iamount"..tostring(i)]) then
												_G["gCraftOrderAddHQIngredient"..tostring(i)] = 0
											end
										elseif (newVal == true) then
											_G["gCraftOrderAddHQIngredient"..tostring(i)] = recipeDetails["iamount"..tostring(i)]
										end
										_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"] = newVal
										ffxiv_craft.UpdateOrderElement()
									end
									GUI:NextColumn();
								end
							end
							
							GUI:Columns(1)
						else
							GUI:Text("Could not find recipe details.")
						end					
					end
					
					GUI:Spacing()
					GUI:Separator()
					GUI:Spacing()
					
					if (GUI:Button("Add to Profile",200,20)) then
						ffxiv_craft.AddToProfile()
					end
				end
			end
			
			if (tabs.tabs[3].isselected) then
				if (ffxiv_craft.orders[gCraftOrderEditID] ~= nil) then
					local orders = ffxiv_craft.orders[gCraftOrderEditID]
					
					GUI:Columns(2)
					
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Amount to Craft")); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use Collect"));   
					if (not gCraftOrderEditQuick) then
						GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Skill Profile")); 
					end  
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Required CP"));   
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Require HQ"));  
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Count HQ"));  
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use QuickSynth")); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use HQ Items"));  
					GUI:NextColumn()
					
					GUI:PushItemWidth(200)
					
							
					
					GUI_Capture(GUI:InputInt("##Amount to Craft",gCraftOrderEditAmount,0,0),"gCraftOrderEditAmount")
					GUI:PopItemWidth()
					if (orders.amount ~= gCraftOrderEditAmount) then
						orders.amount = gCraftOrderEditAmount
						ffxiv_craft.UpdateOrderElement()
					end
					GUI_Capture(GUI:Checkbox("##Use Collect",gCraftOrderEditCollect),"gCraftOrderEditCollect")
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("Use Collect Synth Buff.")
					end
					if (orders.collect ~= gCraftOrderEditCollect) then
						orders.collect = gCraftOrderEditCollect
						ffxiv_craft.UpdateOrderElement()
					end
					
					if (not gCraftOrderEditQuick) then
						GUI:PushItemWidth(200)
						GUI_Combo(GetString("##skillProfile"), "gCraftOrderEditSkillProfileIndex", "gCraftOrderEditSkillProfile", SkillMgr.profiles)
						
						GUI:PopItemWidth()
					end
					if (orders.skillprofile ~= gCraftOrderEditSkillProfile) then
						orders.skillprofile = gCraftOrderEditSkillProfile
						ffxiv_craft.UpdateOrderElement()
					end
					
					GUI_Capture(GUI:InputInt("##RequiredCP1",gCraftOrderEditRequiredCP,0,0),"gCraftOrderEditRequiredCP")
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("Min Cp to craft Item.")
					end
					if (orders.requiredcp ~= gCraftOrderEditRequiredCP) then
						orders.requiredcp = gCraftOrderEditRequiredCP
						ffxiv_craft.UpdateOrderElement()
					end
					
					GUI_Capture(GUI:Checkbox("##RequireHQ2",gCraftOrderEditRequireHQ),"gCraftOrderEditRequireHQ")
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("Only count if item Was HQ.")
					end
					if (orders.requirehq ~= gCraftOrderEditRequireHQ) then
						orders.requirehq = gCraftOrderEditRequireHQ
						ffxiv_craft.UpdateOrderElement()
					end
					
					
					GUI_Capture(GUI:Checkbox("##Count HQ",gCraftOrderEditCountHQ),"gCraftOrderEditCountHQ")
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("Count if HQ and Normal items.")
					end
					if (orders.counthq ~= gCraftOrderEditCountHQ) then
						orders.counthq = gCraftOrderEditCountHQ
						ffxiv_craft.UpdateOrderElement()
					end
					GUI_Capture(GUI:Checkbox("##Use QuickSynth",gCraftOrderEditQuick),"gCraftOrderEditQuick")
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("Quicksynth Items.")
					end
					if (orders.usequick ~= gCraftOrderEditQuick) then
						orders.usequick = gCraftOrderEditQuick
						ffxiv_craft.UpdateOrderElement()
					end
					GUI_Capture(GUI:Checkbox("##Use HQ Items",gCraftOrderEditHQ),"gCraftOrderEditHQ")
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("Use Hq materials. (Advanced)")
					end
					if (orders.usehq ~= gCraftOrderEditHQ) then
						orders.usehq = gCraftOrderEditHQ
						ffxiv_craft.UpdateOrderElement()
					end
					GUI:Columns()
					
					if (gCraftOrderEditHQ) then
						GUI:Separator()
						local recipeDetails = AceLib.API.Items.GetRecipeDetails(gCraftOrderEditID)
						if (recipeDetails) then
							
							GUI:Columns(5, "#craft-edit-hq", true)
							GUI:SetColumnOffset(1, 250); GUI:SetColumnOffset(2, 325); GUI:SetColumnOffset(3, 425); GUI:SetColumnOffset(4, 525);
							GUI:AlignFirstTextHeightToWidgets()
							
							GUI:Text("Ingredient"); GUI:NextColumn();
							GUI:Text("Required"); GUI:NextColumn();
							GUI:Text("Max HQ Amount"); GUI:NextColumn();
							GUI:Text("Min HQ Amount"); GUI:NextColumn();
							GUI:Text("Use All HQ"); GUI:NextColumn();
							GUI:Separator();
							
							for i = 1,6 do
								local ing = recipeDetails["ingredient"..tostring(i)]
								if (ing and ing ~= 0) then
									GUI:AlignFirstTextHeightToWidgets()
									GUI:Text(recipeDetails["ing"..tostring(i).."name"]); GUI:Dummy();GUI:NextColumn();
									GUI:AlignFirstTextHeightToWidgets()
									GUI:Text(recipeDetails["iamount"..tostring(i)]); GUI:Dummy();GUI:NextColumn();
									
									GUI:PushItemWidth(50)
									GUI:AlignFirstTextHeightToWidgets()
									local newVal, changed = GUI:InputInt("##HQ Amount-"..tostring(i),_G["gCraftOrderEditHQIngredient"..tostring(i)],0,0)
									if (changed) then
										if (not GUI:IsItemActive()) then
											if (newVal > recipeDetails["iamount"..tostring(i)]) then
												newVal = recipeDetails["iamount"..tostring(i)]
											elseif (newVal < 0) then
												newVal = 0
											end
											if (newVal == recipeDetails["iamount"..tostring(i)]) then
												_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = true
											else
												_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = false
											end
										end
										_G["gCraftOrderEditHQIngredient"..tostring(i)] = newVal
										if (not GUI:IsItemActive()) then
											ffxiv_craft.UpdateOrderElement()
										end
									end
									if (GUI:IsItemHovered()) then
										GUI:SetTooltip("Max amount of HQ items to use for this item in the craft.")
									end
									GUI:PopItemWidth()
									GUI:NextColumn();
									
									GUI:PushItemWidth(50)
									GUI:AlignFirstTextHeightToWidgets()
									local newVal, changed = GUI:InputInt("##HQ MinAmount-"..tostring(i),_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"],0,0)
									if (changed) then
										if (not GUI:IsItemActive()) then
											if (newVal > recipeDetails["iamount"..tostring(i)]) then
												newVal = recipeDetails["iamount"..tostring(i)]
											elseif (newVal < 0) then
												newVal = 0
											end
										end
										_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"] = newVal
										if (not GUI:IsItemActive()) then
											ffxiv_craft.UpdateOrderElement()
										end
									end
									if (GUI:IsItemHovered()) then
										GUI:SetTooltip("Minimum amount of HQ items to use for this item in the craft.")
									end
									GUI:PopItemWidth()
									GUI:NextColumn();
									
									GUI:AlignFirstTextHeightToWidgets()
									local newVal, changed = GUI:Checkbox("##Max-"..tostring(i),_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"])
									if (changed) then
										if (newVal == false) then
											if (_G["gCraftOrderEditHQIngredient"..tostring(i)] == recipeDetails["iamount"..tostring(i)]) then
												_G["gCraftOrderEditHQIngredient"..tostring(i)] = 0
											end
										elseif (newVal == true) then
											_G["gCraftOrderEditHQIngredient"..tostring(i)] = recipeDetails["iamount"..tostring(i)]
										end
										_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = newVal
										ffxiv_craft.UpdateOrderElement()
									end
									GUI:NextColumn();
								end
							end
							
							GUI:Columns(1)
						else
							GUI:Text("Could not find recipe details.")
						end					
					end
				end
			end
		end
		GUI:End()
	end
end

RegisterEventHandler("Gameloop.Draw", ffxiv_craft.Draw)
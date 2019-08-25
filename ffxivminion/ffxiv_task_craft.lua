ffxiv_craft = {}

ffxiv_craft.tracking = {
	measurementDelay = 0,
	quickTimer = 0,
	lastSetRecipe = 0,
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
	[12] = 4565,
	[13] = 4564,
	[14] = 4566,
	[15] = 4567,
}
ffxiv_craft.collectibles = {

	-- Weekly (Custom Delivery)
	-- Zhloe Alipoh
	{ name = AceLib.API.Items.GetNameByID(17549), minimum = 55 },	--	Near Eastern Antique
	{ name = AceLib.API.Items.GetNameByID(17550), minimum = 57 },	--	Coerthan Souvenir	
	{ name = AceLib.API.Items.GetNameByID(17551), minimum = 59 },	--	Maelstrom Materiel	
	{ name = AceLib.API.Items.GetNameByID(17552), minimum = 63 },	--	Heartfelt Gift	
	{ name = AceLib.API.Items.GetNameByID(17553), minimum = 68 },	--	Orphanage Donation	
	-- M 'naago
	{ name = AceLib.API.Items.GetNameByID(20775), minimum = 157 },	--	Gyr Abanian Souvenir
	{ name = AceLib.API.Items.GetNameByID(20776), minimum = 167 },	--	Far Eastern Antique	
	{ name = AceLib.API.Items.GetNameByID(20777), minimum = 130 },	--	Gold Saucer Consolation Prize	
	{ name = AceLib.API.Items.GetNameByID(20778), minimum = 130 },	--	M Tribe Sundries	
	{ name = AceLib.API.Items.GetNameByID(20779), minimum = 104 },	--	Resistance Materiel
	-- Kurenai
	{ name = AceLib.API.Items.GetNameByID(23143), minimum = 195 },	--	Gyr Abanian Remedies	
	{ name = AceLib.API.Items.GetNameByID(23144), minimum = 195 },	--	Anti-shark Harpoon
	{ name = AceLib.API.Items.GetNameByID(23145), minimum = 130 },	--	Coerthan Cold-weather Gear
	{ name = AceLib.API.Items.GetNameByID(23146), minimum = 130 },	--	Sui-no-Sato Special
	{ name = AceLib.API.Items.GetNameByID(23147), minimum = 110 },	--	Cloud Pearl
	-- Adkiragh
	{ name = AceLib.API.Items.GetNameByID(24562), minimum = 233 },	--	Ishgardian Culinary Essentials
	{ name = AceLib.API.Items.GetNameByID(24563), minimum = 233 },	--	Fermented Juice
	{ name = AceLib.API.Items.GetNameByID(24564), minimum = 161 },	--	Signature Buuz Cookware
	{ name = AceLib.API.Items.GetNameByID(24565), minimum = 161 },	--	Hard Place Decorative Furnishings 
	{ name = AceLib.API.Items.GetNameByID(24566), minimum = 125 },	--	Arkhi Brewing Set
	
	-- Carpenter
	{ name = AceLib.API.Items.GetNameByID(10608), minimum = 320 },	--	Adamantite Spear
	{ name = AceLib.API.Items.GetNameByID(10609), minimum = 400 },	--	Adamantite Trident
	{ name = AceLib.API.Items.GetNameByID(19583), minimum = 660 },	--	Almandine Grinding Wheel
	{ name = AceLib.API.Items.GetNameByID(25797), minimum = 640 },	--	Applewood Staff
	{ name = AceLib.API.Items.GetNameByID(11927), minimum = 190 },	--	Astral Grinding Wheel
	{ name = AceLib.API.Items.GetNameByID(18037), minimum = 320 },	--	Beech Composite Bow
	{ name = AceLib.API.Items.GetNameByID(18041), minimum = 300 },	--	Beech Rod
	{ name = AceLib.API.Items.GetNameByID(10615), minimum = 400 },	--	Birch Composite Bow
	{ name = AceLib.API.Items.GetNameByID(11914), minimum = 400 },	--	Birch Fishing Rod
	{ name = AceLib.API.Items.GetNameByID(10614), minimum = 320 },	--	Birch Longbow
	{ name = AceLib.API.Items.GetNameByID(12583), minimum = 360 },	--	Birch Lumber
	{ name = AceLib.API.Items.GetNameByID(10639), minimum = 400 },	--	Birch Rod
	{ name = AceLib.API.Items.GetNameByID(10638), minimum = 320 },	--	Birch Signum
	{ name = AceLib.API.Items.GetNameByID(11937), minimum = 350 },	--	Birch Spinning Wheel
	{ name = AceLib.API.Items.GetNameByID(25956), minimum = 700 },	--	Bluespirit Cane
	{ name = AceLib.API.Items.GetNameByID(25951), minimum = 700 },	--	Bluespirit Spear
	{ name = AceLib.API.Items.GetNameByID(10634), minimum = 130 },	--	Cedar Crook
	{ name = AceLib.API.Items.GetNameByID(11911), minimum = 160 },	--	Cedar Fishing Rod
	{ name = AceLib.API.Items.GetNameByID(10610), minimum = 130 },	--	Cedar Longbow
	{ name = AceLib.API.Items.GetNameByID(11928), minimum = 270 },	--	Cloud Mica Grinding Wheel
	{ name = AceLib.API.Items.GetNameByID(11912), minimum = 240 },	--	Dark Chestnut Fishing Rod
	{ name = AceLib.API.Items.GetNameByID(10612), minimum = 220 },	--	Dark Chestnut Longbow
	{ name = AceLib.API.Items.GetNameByID(12581), minimum = 250 },	--	Dark Chestnut Lumber
	{ name = AceLib.API.Items.GetNameByID(10636), minimum = 220 },	--	Dark Chestnut Rod
	{ name = AceLib.API.Items.GetNameByID(11936), minimum = 270 },	--	Dark Chestnut Spinning Wheel
	{ name = AceLib.API.Items.GetNameByID(18348), minimum = 470 },	--	Doman Iron Lance
	{ name = AceLib.API.Items.GetNameByID(18504), minimum = 560 },	--	Doman Steel Halberd
	{ name = AceLib.API.Items.GetNameByID(11929), minimum = 350 },	--	Dragonscale Grinding Wheel
	{ name = AceLib.API.Items.GetNameByID(26272), minimum = 930 },	--	Dwarven Lignum Bow
	{ name = AceLib.API.Items.GetNameByID(26271), minimum = 930 },	--	Dwarven Lignum Lance
	{ name = AceLib.API.Items.GetNameByID(26277), minimum = 930 },	--	Dwarven Lignum Pole
	{ name = AceLib.API.Items.GetNameByID(12015), minimum = 320 },	--	Hallowed Chestnut Armillae
	{ name = AceLib.API.Items.GetNameByID(10613), minimum = 270 },	--	Hallowed Chestnut Composite Bow
	{ name = AceLib.API.Items.GetNameByID(11913), minimum = 290 },	--	Hallowed Chestnut Fishing Rod
	{ name = AceLib.API.Items.GetNameByID(10925), minimum = 270 },	--	Hallowed Chestnut Mask of Casting
	{ name = AceLib.API.Items.GetNameByID(10883), minimum = 270 },	--	Hallowed Chestnut Mask of Healing
	{ name = AceLib.API.Items.GetNameByID(12012), minimum = 350 },	--	Hallowed Chestnut Necklace
	{ name = AceLib.API.Items.GetNameByID(12021), minimum = 290 },	--	Hallowed Chestnut Ring
	{ name = AceLib.API.Items.GetNameByID(18036), minimum = 320 },	--	High Steel Trident
	{ name = AceLib.API.Items.GetNameByID(12014), minimum = 190 },	--	Holy Cedar Armillae
	{ name = AceLib.API.Items.GetNameByID(10611), minimum = 160 },	--	Holy Cedar Composite Bow
	{ name = AceLib.API.Items.GetNameByID(12011), minimum = 220 },	--	Holy Cedar Necklace
	{ name = AceLib.API.Items.GetNameByID(12020), minimum = 190 },	--	Holy Cedar Ring
	{ name = AceLib.API.Items.GetNameByID(11935), minimum = 190 },	--	Holy Cedar Spinning Wheel
	{ name = AceLib.API.Items.GetNameByID(19730), minimum = 420 },	--	Larch Bracelets
	{ name = AceLib.API.Items.GetNameByID(18193), minimum = 370 },	--	Larch Composite Bow
	{ name = AceLib.API.Items.GetNameByID(19728), minimum = 420 },	--	Larch Earrings
	{ name = AceLib.API.Items.GetNameByID(19729), minimum = 420 },	--	Larch Necklace
	{ name = AceLib.API.Items.GetNameByID(19731), minimum = 420 },	--	Larch Ring
	{ name = AceLib.API.Items.GetNameByID(19522), minimum = 370 },	--	Larch Spinning Wheel
	{ name = AceLib.API.Items.GetNameByID(18197), minimum = 370 },	--	Larch Wand
	{ name = AceLib.API.Items.GetNameByID(27229), minimum = 960 },	--	Lignum Vitae Bracelet
	{ name = AceLib.API.Items.GetNameByID(27150), minimum = 1060 },	--	Lignum Vitae Fishing Rod
	{ name = AceLib.API.Items.GetNameByID(27154), minimum = 1060 },	--	Lignum Vitae Grinding Wheel
	{ name = AceLib.API.Items.GetNameByID(27693), minimum = 930 },	--	Lignum Vitae Lumber
	{ name = AceLib.API.Items.GetNameByID(27228), minimum = 960 },	--	Lignum Vitae Necklace
	{ name = AceLib.API.Items.GetNameByID(27156), minimum = 1060 },	--	Lignum Vitae Spinning Wheel
	{ name = AceLib.API.Items.GetNameByID(27690), minimum = 570 },	--	Miracle Apple Lumber
	{ name = AceLib.API.Items.GetNameByID(18660), minimum = 630 },	--	Molybdenum Trident
	{ name = AceLib.API.Items.GetNameByID(19516), minimum = 320 },	--	Muudhorn Fishing Rod
	{ name = AceLib.API.Items.GetNameByID(10605), minimum = 160 },	--	Mythrite Pugil Stick
	{ name = AceLib.API.Items.GetNameByID(10604), minimum = 130 },	--	Mythrite Trident
	{ name = AceLib.API.Items.GetNameByID(19740), minimum = 610 },	--	Persimmon Bracelets
	{ name = AceLib.API.Items.GetNameByID(18509), minimum = 560 },	--	Persimmon Cane
	{ name = AceLib.API.Items.GetNameByID(19738), minimum = 610 },	--	Persimmon Earrings
	{ name = AceLib.API.Items.GetNameByID(19739), minimum = 610 },	--	Persimmon Necklace
	{ name = AceLib.API.Items.GetNameByID(19741), minimum = 610 },	--	Persimmon Ring
	{ name = AceLib.API.Items.GetNameByID(19564), minimum = 610 },	--	Persimmon Spinning Wheel
	{ name = AceLib.API.Items.GetNameByID(18353), minimum = 470 },	--	Pine Cane
	{ name = AceLib.API.Items.GetNameByID(18349), minimum = 470 },	--	Pine Composite Bow
	{ name = AceLib.API.Items.GetNameByID(19537), minimum = 510 },	--	Pine Fishing Rod
	{ name = AceLib.API.Items.GetNameByID(19543), minimum = 510 },	--	Pine Spinning Wheel
	{ name = AceLib.API.Items.GetNameByID(19562), minimum = 610 },	--	Polished Slate Grinding Wheel\
	{ name = AceLib.API.Items.GetNameByID(26116), minimum = 830 },	--	Sandteak Cane
	{ name = AceLib.API.Items.GetNameByID(26111), minimum = 830 },	--	Sandteak Fauchard
	{ name = AceLib.API.Items.GetNameByID(27129), minimum = 900 },	--	Sandteak Fishing Rod
	{ name = AceLib.API.Items.GetNameByID(27133), minimum = 900 },	--	Sandteak Grinding Wheel
	{ name = AceLib.API.Items.GetNameByID(27692), minimum = 830 },	--	Sandteak Lumber
	{ name = AceLib.API.Items.GetNameByID(19541), minimum = 510 },	--	Slate Grinding Wheel
	{ name = AceLib.API.Items.GetNameByID(19520), minimum = 370 },	--	Stiperstone Grinding Wheel
	{ name = AceLib.API.Items.GetNameByID(10607), minimum = 270 },	--	Titanium Fork
	{ name = AceLib.API.Items.GetNameByID(10606), minimum = 220 },	--	Titanium Lance
	{ name = AceLib.API.Items.GetNameByID(26008), minimum = 770 },	--	White Ash Earring of Fending
	{ name = AceLib.API.Items.GetNameByID(26011), minimum = 770 },	--	White Ash Earring of Healing
	{ name = AceLib.API.Items.GetNameByID(27108), minimum = 700 },	--	White Ash Fishing Rod
	{ name = AceLib.API.Items.GetNameByID(27218), minimum = 770 },	--	White Ash Necklace
	{ name = AceLib.API.Items.GetNameByID(27220), minimum = 770 },	--	White Ash Ring
	{ name = AceLib.API.Items.GetNameByID(27114), minimum = 700 },	--	White Ash Spinning Wheel
	{ name = AceLib.API.Items.GetNameByID(27204), minimum = 500 },	--	White Oak Bracelets
	{ name = AceLib.API.Items.GetNameByID(25636), minimum = 500 },	--	White Oak Cane
	{ name = AceLib.API.Items.GetNameByID(25632), minimum = 500 },	--	White Oak Composite Bow
	{ name = AceLib.API.Items.GetNameByID(27091), minimum = 500 },	--	White Oak Grinding Wheel
	{ name = AceLib.API.Items.GetNameByID(25631), minimum = 500 },	--	White Oak Partisan
	{ name = AceLib.API.Items.GetNameByID(27205), minimum = 500 },	--	White Oak Ring
	{ name = AceLib.API.Items.GetNameByID(25637), minimum = 500 },	--	White Oak Rod
	{ name = AceLib.API.Items.GetNameByID(27093), minimum = 500 },	--	White Oak Spinning Wheel
	{ name = AceLib.API.Items.GetNameByID(19750), minimum = 650 },	--	Zelkova Bracelets
	{ name = AceLib.API.Items.GetNameByID(18665), minimum = 630 },	--	Zelkova Cane
	{ name = AceLib.API.Items.GetNameByID(19748), minimum = 650 },	--	Zelkova Earrings
	{ name = AceLib.API.Items.GetNameByID(19579), minimum = 660 },	--	Zelkova Fishing Rod
	{ name = AceLib.API.Items.GetNameByID(18661), minimum = 630 },	--	Zelkova Longbow
	{ name = AceLib.API.Items.GetNameByID(19928), minimum = 625 },	--	Zelkova Lumber
	{ name = AceLib.API.Items.GetNameByID(19749), minimum = 650 },	--	Zelkova Necklace
	{ name = AceLib.API.Items.GetNameByID(19751), minimum = 650 },	--	Zelkova Ring
	{ name = AceLib.API.Items.GetNameByID(19585), minimum = 660 },	--	Zelkova Spinning Wheel

	-- Blacksmith
	{ name = AceLib.API.Items.GetNameByID(11933), minimum = 350 },	--	Adamantite Awl
	{ name = AceLib.API.Items.GetNameByID(10602), minimum = 320 },	--	Adamantite Bill
	{ name = AceLib.API.Items.GetNameByID(10590), minimum = 320 },	--	Adamantite Broadsword
	{ name = AceLib.API.Items.GetNameByID(11917), minimum = 350 },	--	Adamantite Claw Hammer
	{ name = AceLib.API.Items.GetNameByID(11945), minimum = 350 },	--	Adamantite Culinary Knife
	{ name = AceLib.API.Items.GetNameByID(11906), minimum = 400 },	--	Adamantite Dolabra
	{ name = AceLib.API.Items.GetNameByID(11921), minimum = 350 },	--	Adamantite File
	{ name = AceLib.API.Items.GetNameByID(10627), minimum = 400 },	--	Adamantite Greatsword
	{ name = AceLib.API.Items.GetNameByID(11910), minimum = 400 },	--	Adamantite Hatchet
	{ name = AceLib.API.Items.GetNameByID(10603), minimum = 400 },	--	Adamantite Headsman's Axe
	{ name = AceLib.API.Items.GetNameByID(10596), minimum = 320 },	--	Adamantite Jamadhars
	{ name = AceLib.API.Items.GetNameByID(10620), minimum = 320 },	--	Adamantite Knives
	{ name = AceLib.API.Items.GetNameByID(11941), minimum = 350 },	--	Adamantite Mortar
	{ name = AceLib.API.Items.GetNameByID(11925), minimum = 350 },	--	Adamantite Pliers
	{ name = AceLib.API.Items.GetNameByID(10632), minimum = 320 },	--	Adamantite Revolver
	{ name = AceLib.API.Items.GetNameByID(11874), minimum = 400 },	--	Adamantite Saw
	{ name = AceLib.API.Items.GetNameByID(11953), minimum = 350 },	--	Adamantite Scythe
	{ name = AceLib.API.Items.GetNameByID(11949), minimum = 350 },	--	Adamantite Sledgehammer
	{ name = AceLib.API.Items.GetNameByID(10591), minimum = 400 },	--	Adamantite Winglet
	{ name = AceLib.API.Items.GetNameByID(10626), minimum = 320 },	--	Adamantite Zweihander
	{ name = AceLib.API.Items.GetNameByID(10633), minimum = 400 },	--	Adamantite-barreled Culverin
	{ name = AceLib.API.Items.GetNameByID(11890), minimum = 400 },	--	Aurum Regis Creasing Knife
	{ name = AceLib.API.Items.GetNameByID(25950), minimum = 700 },	--	Bluespirit Axe
	{ name = AceLib.API.Items.GetNameByID(27116), minimum = 700 },	--	Bluespirit Culinary Knife
	{ name = AceLib.API.Items.GetNameByID(25954), minimum = 700 },	--	Bluespirit Guillotine
	{ name = AceLib.API.Items.GetNameByID(25963), minimum = 700 },	--	Bluespirit Gunblade
	{ name = AceLib.API.Items.GetNameByID(25955), minimum = 700 },	--	Bluespirit Handgonne
	{ name = AceLib.API.Items.GetNameByID(27107), minimum = 770 },	--	Bluespirit Hatchet
	{ name = AceLib.API.Items.GetNameByID(27106), minimum = 770 },	--	Bluespirit Pickaxe
	{ name = AceLib.API.Items.GetNameByID(25948), minimum = 700 },	--	Bluespirit Sword
	{ name = AceLib.API.Items.GetNameByID(25628), minimum = 500 },	--	Deepgold Anelace
	{ name = AceLib.API.Items.GetNameByID(25795), minimum = 640 },	--	Deepgold Arquebus
	{ name = AceLib.API.Items.GetNameByID(27092), minimum = 500 },	--	Deepgold Awl
	{ name = AceLib.API.Items.GetNameByID(25630), minimum = 500 },	--	Deepgold Battleaxe
	{ name = AceLib.API.Items.GetNameByID(25803), minimum = 640 },	--	Deepgold Bayonet
	{ name = AceLib.API.Items.GetNameByID(25804), minimum = 640 },	--	Deepgold Chakrams
	{ name = AceLib.API.Items.GetNameByID(27078), minimum = 500 },	--	Deepgold Cross-pein Hammer
	{ name = AceLib.API.Items.GetNameByID(25793), minimum = 570 },	--	Deepgold Daggers
	{ name = AceLib.API.Items.GetNameByID(25794), minimum = 570 },	--	Deepgold Greatsword
	{ name = AceLib.API.Items.GetNameByID(27708), minimum = 570 },	--	Deepgold Ingot
	{ name = AceLib.API.Items.GetNameByID(25629), minimum = 500 },	--	Deepgold Katars
	{ name = AceLib.API.Items.GetNameByID(27094), minimum = 500 },	--	Deepgold Mortar
	{ name = AceLib.API.Items.GetNameByID(27079), minimum = 500 },	--	Deepgold Raising Hammer
	{ name = AceLib.API.Items.GetNameByID(27077), minimum = 500 },	--	Deepgold Saw
	{ name = AceLib.API.Items.GetNameByID(19542), minimum = 510 },	--	Doman Iron Awl
	{ name = AceLib.API.Items.GetNameByID(18352), minimum = 510 },	--	Doman Iron Culverin
	{ name = AceLib.API.Items.GetNameByID(19539), minimum = 510 },	--	Doman Iron File
	{ name = AceLib.API.Items.GetNameByID(18351), minimum = 510 },	--	Doman Iron Greatsword
	{ name = AceLib.API.Items.GetNameByID(19527), minimum = 470 },	--	Doman Iron Halfheart Saw
	{ name = AceLib.API.Items.GetNameByID(19536), minimum = 470 },	--	Doman Iron Hatchet
	{ name = AceLib.API.Items.GetNameByID(18358), minimum = 510 },	--	Doman Iron Uchigatana
	{ name = AceLib.API.Items.GetNameByID(19559), minimum = 610 },	--	Doman Steel Claw Hammer
	{ name = AceLib.API.Items.GetNameByID(19566), minimum = 610 },	--	Doman Steel Culinary Knife
	{ name = AceLib.API.Items.GetNameByID(18501), minimum = 560 },	--	Doman Steel Longsword
	{ name = AceLib.API.Items.GetNameByID(18506), minimum = 610 },	--	Doman Steel Main Gauches
	{ name = AceLib.API.Items.GetNameByID(18502), minimum = 560 },	--	Doman Steel Patas
	{ name = AceLib.API.Items.GetNameByID(19561), minimum = 610 },	--	Doman Steel Pliers
	{ name = AceLib.API.Items.GetNameByID(19550), minimum = 560 },	--	Doman Steel Raising Hammer
	{ name = AceLib.API.Items.GetNameByID(19567), minimum = 610 },	--	Doman Steel Sledgehammer
	{ name = AceLib.API.Items.GetNameByID(19530), minimum = 470 },	--	Durium Texture Hammer
	{ name = AceLib.API.Items.GetNameByID(27155), minimum = 960 },	--	Dwarven Mythril Awl
	{ name = AceLib.API.Items.GetNameByID(27141), minimum = 1060 },	--	Dwarven Mythril Cross-pein Hammer
	{ name = AceLib.API.Items.GetNameByID(26284), minimum = 930 },	--	Dwarven Mythril Glaives
	{ name = AceLib.API.Items.GetNameByID(27149), minimum = 1060 },	--	Dwarven Mythril Hatchet
	{ name = AceLib.API.Items.GetNameByID(27143), minimum = 1060 },	--	Dwarven Mythril Lapidary Hammer
	{ name = AceLib.API.Items.GetNameByID(26283), minimum = 930 },	--	Dwarven Mythril Manatrigger
	{ name = AceLib.API.Items.GetNameByID(27148), minimum = 1060 },	--	Dwarven Mythril Pickaxe
	{ name = AceLib.API.Items.GetNameByID(26280), minimum = 930 },	--	Dwarven Mythril Planisphere
	{ name = AceLib.API.Items.GetNameByID(27153), minimum = 960 },	--	Dwarven Mythril Pliers
	{ name = AceLib.API.Items.GetNameByID(27142), minimum = 1060 },	--	Dwarven Mythril Raising Hammer
	{ name = AceLib.API.Items.GetNameByID(26273), minimum = 930 },	--	Dwarven Mythril Rotaries
	{ name = AceLib.API.Items.GetNameByID(27144), minimum = 1060 },	--	Dwarven Mythril Round Knife
	{ name = AceLib.API.Items.GetNameByID(27140), minimum = 1060 },	--	Dwarven Mythril Saw
	{ name = AceLib.API.Items.GetNameByID(27160), minimum = 960 },	--	Dwarven Mythril Scythe
	{ name = AceLib.API.Items.GetNameByID(27159), minimum = 960 },	--	Dwarven Mythril Sledgehammer
	{ name = AceLib.API.Items.GetNameByID(18190), minimum = 420 },	--	Folded High Steel Knuckles
	{ name = AceLib.API.Items.GetNameByID(11904), minimum = 240 },	--	Hardsilver Dolabra
	{ name = AceLib.API.Items.GetNameByID(11909), minimum = 290 },	--	Hardsilver Hatchet
	{ name = AceLib.API.Items.GetNameByID(11872), minimum = 240 },	--	Hardsilver Saw
	{ name = AceLib.API.Items.GetNameByID(11884), minimum = 240 },	--	Hardsilver Texture Hammer
	{ name = AceLib.API.Items.GetNameByID(19521), minimum = 370 },	--	High Steel Awl
	{ name = AceLib.API.Items.GetNameByID(18191), minimum = 420 },	--	High Steel Battleaxe
	{ name = AceLib.API.Items.GetNameByID(19517), minimum = 370 },	--	High Steel Claw Hammer
	{ name = AceLib.API.Items.GetNameByID(19524), minimum = 370 },	--	High Steel Culinary Knife
	{ name = AceLib.API.Items.GetNameByID(19514), minimum = 320 },	--	High Steel Dolabra
	{ name = AceLib.API.Items.GetNameByID(19508), minimum = 320 },	--	High Steel Doming Hammer
	{ name = AceLib.API.Items.GetNameByID(18039), minimum = 300 },	--	High Steel Guillotine
	{ name = AceLib.API.Items.GetNameByID(18035), minimum = 300 },	--	High Steel Headsman's Axe
	{ name = AceLib.API.Items.GetNameByID(18034), minimum = 300 },	--	High Steel Knuckles
	{ name = AceLib.API.Items.GetNameByID(18189), minimum = 420 },	--	High Steel Longsword
	{ name = AceLib.API.Items.GetNameByID(18038), minimum = 300 },	--	High Steel Main Gauches
	{ name = AceLib.API.Items.GetNameByID(19519), minimum = 370 },	--	High Steel Pliers
	{ name = AceLib.API.Items.GetNameByID(19526), minimum = 370 },	--	High Steel Scythe
	{ name = AceLib.API.Items.GetNameByID(18046), minimum = 300 },	--	High Steel Tachi
	{ name = AceLib.API.Items.GetNameByID(19509), minimum = 320 },	--	Koppranickel Ornamental Hammer
	{ name = AceLib.API.Items.GetNameByID(19584), minimum = 660 },	--	Molybdenum Awl
	{ name = AceLib.API.Items.GetNameByID(19580), minimum = 660 },	--	Molybdenum Claw Hammer
	{ name = AceLib.API.Items.GetNameByID(19573), minimum = 650 },	--	Molybdenum Creasing Knife
	{ name = AceLib.API.Items.GetNameByID(19587), minimum = 660 },	--	Molybdenum Culinary Knife
	{ name = AceLib.API.Items.GetNameByID(19581), minimum = 660 },	--	Molybdenum File
	{ name = AceLib.API.Items.GetNameByID(19569), minimum = 650 },	--	Molybdenum Halfheart Saw
	{ name = AceLib.API.Items.GetNameByID(19947), minimum = 625 },	--	Molybdenum Ingot
	{ name = AceLib.API.Items.GetNameByID(18658), minimum = 630 },	--	Molybdenum Knuckles
	{ name = AceLib.API.Items.GetNameByID(18663), minimum = 630 },	--	Molybdenum Longblade
	{ name = AceLib.API.Items.GetNameByID(19570), minimum = 650 },	--	Molybdenum Lump Hammer
	{ name = AceLib.API.Items.GetNameByID(19586), minimum = 660 },	--	Molybdenum Mortar
	{ name = AceLib.API.Items.GetNameByID(19577), minimum = 650 },	--	Molybdenum Pickaxe
	{ name = AceLib.API.Items.GetNameByID(19582), minimum = 660 },	--	Molybdenum Pliers
	{ name = AceLib.API.Items.GetNameByID(19589), minimum = 660 },	--	Molybdenum Scythe
	{ name = AceLib.API.Items.GetNameByID(19588), minimum = 660 },	--	Molybdenum Sledgehammer
	{ name = AceLib.API.Items.GetNameByID(18659), minimum = 630 },	--	Molybdenum War Axe
	{ name = AceLib.API.Items.GetNameByID(10622), minimum = 130 },	--	Mythrite Claymore
	{ name = AceLib.API.Items.GetNameByID(10587), minimum = 190 },	--	Mythrite Flametongue
	{ name = AceLib.API.Items.GetNameByID(11871), minimum = 160 },	--	Mythrite Halfheart Saw
	{ name = AceLib.API.Items.GetNameByID(10593), minimum = 190 },	--	Mythrite Jamadhars
	{ name = AceLib.API.Items.GetNameByID(10586), minimum = 130 },	--	Mythrite Katzbalger
	{ name = AceLib.API.Items.GetNameByID(11883), minimum = 160 },	--	Mythrite Lapidary Hammer
	{ name = AceLib.API.Items.GetNameByID(10592), minimum = 130 },	--	Mythrite Patas
	{ name = AceLib.API.Items.GetNameByID(11923), minimum = 190 },	--	Mythrite Pliers
	{ name = AceLib.API.Items.GetNameByID(10616), minimum = 130 },	--	Mythrite Pugiones
	{ name = AceLib.API.Items.GetNameByID(11951), minimum = 190 },	--	Mythrite Scythe
	{ name = AceLib.API.Items.GetNameByID(10598), minimum = 130 },	--	Mythrite War Axe
	{ name = AceLib.API.Items.GetNameByID(10623), minimum = 190 },	--	Mythrite Zweihander
	{ name = AceLib.API.Items.GetNameByID(10628), minimum = 130 },	--	Mythrite-barreled Arquebus
	{ name = AceLib.API.Items.GetNameByID(10629), minimum = 190 },	--	Mythrite-barreled Musketoon
	{ name = AceLib.API.Items.GetNameByID(25801), minimum = 570 },	--	Stonegold Uchigatana
	{ name = AceLib.API.Items.GetNameByID(26110), minimum = 830 },	--	Titanbronze Battleaxe
	{ name = AceLib.API.Items.GetNameByID(27123), minimum = 900 },	--	Titanbronze Creasing Knife
	{ name = AceLib.API.Items.GetNameByID(26109), minimum = 830 },	--	Titanbronze Fists
	{ name = AceLib.API.Items.GetNameByID(26108), minimum = 830 },	--	Titanbronze Kilij
	{ name = AceLib.API.Items.GetNameByID(27136), minimum = 900 },	--	Titanbronze Mortar
	{ name = AceLib.API.Items.GetNameByID(27127), minimum = 900 },	--	Titanbronze Pickaxe
	{ name = AceLib.API.Items.GetNameByID(27132), minimum = 900 },	--	Titanbronze Pliers
	{ name = AceLib.API.Items.GetNameByID(27122), minimum = 900 },	--	Titanbronze Texture Hammer
	{ name = AceLib.API.Items.GetNameByID(10600), minimum = 220 },	--	Titanium Axe
	{ name = AceLib.API.Items.GetNameByID(11880), minimum = 240 },	--	Titanium Ball-pein Hammer
	{ name = AceLib.API.Items.GetNameByID(11888), minimum = 240 },	--	Titanium Creasing Knife
	{ name = AceLib.API.Items.GetNameByID(11876), minimum = 240 },	--	Titanium Cross-pein Hammer
	{ name = AceLib.API.Items.GetNameByID(11944), minimum = 270 },	--	Titanium Culinary Knife
	{ name = AceLib.API.Items.GetNameByID(10625), minimum = 290 },	--	Titanium Greatsword
	{ name = AceLib.API.Items.GetNameByID(12525), minimum = 330 },	--	Titanium Ingot
	{ name = AceLib.API.Items.GetNameByID(10595), minimum = 290 },	--	Titanium Knuckles
	{ name = AceLib.API.Items.GetNameByID(10589), minimum = 290 },	--	Titanium Longsword
	{ name = AceLib.API.Items.GetNameByID(11940), minimum = 270 },	--	Titanium Mortar
	{ name = AceLib.API.Items.GetNameByID(12524), minimum = 250 },	--	Titanium Nugget
	{ name = AceLib.API.Items.GetNameByID(10618), minimum = 220 },	--	Titanium Pugiones
	{ name = AceLib.API.Items.GetNameByID(11948), minimum = 270 },	--	Titanium Sledgehammer
	{ name = AceLib.API.Items.GetNameByID(10631), minimum = 290 },	--	Titanium-barreled Snaphance

	-- Armorer
	{ name = AceLib.API.Items.GetNameByID(11898), minimum = 400 },	--	Adamantite Alembic
	{ name = AceLib.API.Items.GetNameByID(10681), minimum = 350 },	--	Adamantite Armor of Fending
	{ name = AceLib.API.Items.GetNameByID(10723), minimum = 350 },	--	Adamantite Armor of Maiming
	{ name = AceLib.API.Items.GetNameByID(10702), minimum = 350 },	--	Adamantite Chain Hose of Fending
	{ name = AceLib.API.Items.GetNameByID(10744), minimum = 350 },	--	Adamantite Chain Hose of Maiming
	{ name = AceLib.API.Items.GetNameByID(10675), minimum = 350 },	--	Adamantite Circlet of Fending
	{ name = AceLib.API.Items.GetNameByID(11902), minimum = 400 },	--	Adamantite Frypan
	{ name = AceLib.API.Items.GetNameByID(10688), minimum = 320 },	--	Adamantite Gauntlets of Fending
	{ name = AceLib.API.Items.GetNameByID(10730), minimum = 320 },	--	Adamantite Gauntlets of Maiming
	{ name = AceLib.API.Items.GetNameByID(10674), minimum = 320 },	--	Adamantite Helm of Fending
	{ name = AceLib.API.Items.GetNameByID(10716), minimum = 320 },	--	Adamantite Helm of Maiming
	{ name = AceLib.API.Items.GetNameByID(10669), minimum = 400 },	--	Adamantite Hoplon
	{ name = AceLib.API.Items.GetNameByID(10752), minimum = 400 },	--	Adamantite Leg Guards of Maiming
	{ name = AceLib.API.Items.GetNameByID(10682), minimum = 400 },	--	Adamantite Lorica of Fending
	{ name = AceLib.API.Items.GetNameByID(10724), minimum = 400 },	--	Adamantite Mail of Maiming
	{ name = AceLib.API.Items.GetNameByID(10696), minimum = 350 },	--	Adamantite Plate Belt of Fending
	{ name = AceLib.API.Items.GetNameByID(10709), minimum = 320 },	--	Adamantite Sabatons of Fending
	{ name = AceLib.API.Items.GetNameByID(10751), minimum = 320 },	--	Adamantite Sabatons of Maiming
	{ name = AceLib.API.Items.GetNameByID(10668), minimum = 350 },	--	Adamantite Scutum
	{ name = AceLib.API.Items.GetNameByID(10695), minimum = 320 },	--	Adamantite Tassets of Fending
	{ name = AceLib.API.Items.GetNameByID(10737), minimum = 320 },	--	Adamantite Tassets of Maiming
	{ name = AceLib.API.Items.GetNameByID(10920), minimum = 400 },	--	Aurum Regis Sollerets of Healing
	{ name = AceLib.API.Items.GetNameByID(25973), minimum = 770 },	--	Bluespirit Cuirass of Maiming
	{ name = AceLib.API.Items.GetNameByID(25974), minimum = 700 },	--	Bluespirit Gauntlets of Maiming
	{ name = AceLib.API.Items.GetNameByID(26006), minimum = 700 },	--	Bluespirit Greaves of Casting
	{ name = AceLib.API.Items.GetNameByID(25972), minimum = 700 },	--	Bluespirit Helm of Maiming
	{ name = AceLib.API.Items.GetNameByID(25971), minimum = 700 },	--	Bluespirit Plate Belt of Fending
	{ name = AceLib.API.Items.GetNameByID(27105), minimum = 770 },	--	Bluespirit Porxie Frypan
	{ name = AceLib.API.Items.GetNameByID(25970), minimum = 700 },	--	Bluespirit Sabatons of Fending
	{ name = AceLib.API.Items.GetNameByID(25976), minimum = 700 },	--	Bluespirit Sabatons of Maiming
	{ name = AceLib.API.Items.GetNameByID(27083), minimum = 500 },	--	Deepgold Alembic
	{ name = AceLib.API.Items.GetNameByID(25647), minimum = 500 },	--	Deepgold Cuirass of Fending
	{ name = AceLib.API.Items.GetNameByID(25648), minimum = 500 },	--	Deepgold Gauntlets of Fending
	{ name = AceLib.API.Items.GetNameByID(27708), minimum = 570 },	--	Deepgold Ingot
	{ name = AceLib.API.Items.GetNameByID(25807), minimum = 640 },	--	Deepgold Mail of Fending
	{ name = AceLib.API.Items.GetNameByID(25670), minimum = 500 },	--	Deepgold Mask of Scouting
	{ name = AceLib.API.Items.GetNameByID(25681), minimum = 500 },	--	Deepgold Plate Belt of Healing
	{ name = AceLib.API.Items.GetNameByID(25657), minimum = 500 },	--	Deepgold Plate Belt of Maiming
	{ name = AceLib.API.Items.GetNameByID(25663), minimum = 500 },	--	Deepgold Plate Belt of Striking
	{ name = AceLib.API.Items.GetNameByID(25805), minimum = 640 },	--	Deepgold Shield
	{ name = AceLib.API.Items.GetNameByID(25650), minimum = 500 },	--	Deepgold Sollerets of Fending
	{ name = AceLib.API.Items.GetNameByID(25816), minimum = 570 },	--	Deepgold Sollerets of Maiming
	{ name = AceLib.API.Items.GetNameByID(25829), minimum = 570 },	--	Deepgold Tassets of Aiming
	{ name = AceLib.API.Items.GetNameByID(25847), minimum = 570 },	--	Deepgold Tassets of Casting
	{ name = AceLib.API.Items.GetNameByID(25811), minimum = 570 },	--	Deepgold Tassets of Fending
	{ name = AceLib.API.Items.GetNameByID(25835), minimum = 570 },	--	Deepgold Tassets of Scouting
	{ name = AceLib.API.Items.GetNameByID(25806), minimum = 570 },	--	Deepgold Wings of Fending
	{ name = AceLib.API.Items.GetNameByID(19533), minimum = 510 },	--	Doman Iron Alembic
	{ name = AceLib.API.Items.GetNameByID(19534), minimum = 510 },	--	Doman Iron Frypan
	{ name = AceLib.API.Items.GetNameByID(18363), minimum = 470 },	--	Doman Iron Gauntlets of Fending
	{ name = AceLib.API.Items.GetNameByID(18365), minimum = 470 },	--	Doman Iron Greaves of Fending
	{ name = AceLib.API.Items.GetNameByID(18372), minimum = 470 },	--	Doman Iron Tassets of Maiming
	{ name = AceLib.API.Items.GetNameByID(19554), minimum = 610 },	--	Doman Steel Alembic
	{ name = AceLib.API.Items.GetNameByID(18517), minimum = 610 },	--	Doman Steel Armet of Fending
	{ name = AceLib.API.Items.GetNameByID(19555), minimum = 610 },	--	Doman Steel Frypan Caliente
	{ name = AceLib.API.Items.GetNameByID(18519), minimum = 560 },	--	Doman Steel Gauntlets of Fending
	{ name = AceLib.API.Items.GetNameByID(18531), minimum = 560 },	--	Doman Steel Gauntlets of Striking
	{ name = AceLib.API.Items.GetNameByID(18545), minimum = 560 },	--	Doman Steel Greaves of Scouting
	{ name = AceLib.API.Items.GetNameByID(18516), minimum = 610 },	--	Doman Steel Shield
	{ name = AceLib.API.Items.GetNameByID(18524), minimum = 610 },	--	Doman Steel Tabard of Maiming
	{ name = AceLib.API.Items.GetNameByID(27146), minimum = 1060 },	--	Dwarven Mythril Alembic
	{ name = AceLib.API.Items.GetNameByID(26293), minimum = 930 },	--	Dwarven Mythril Chainmail of Maiming
	{ name = AceLib.API.Items.GetNameByID(27147), minimum = 1060 },	--	Dwarven Mythril Frypan
	{ name = AceLib.API.Items.GetNameByID(26286), minimum = 930 },	--	Dwarven Mythril Helm of Fending
	{ name = AceLib.API.Items.GetNameByID(26292), minimum = 930 },	--	Dwarven Mythril Helm of Maiming
	{ name = AceLib.API.Items.GetNameByID(26309), minimum = 960 },	--	Dwarven Mythril Plate Belt of Aiming
	{ name = AceLib.API.Items.GetNameByID(26321), minimum = 960 },	--	Dwarven Mythril Plate Belt of Healing
	{ name = AceLib.API.Items.GetNameByID(26297), minimum = 930 },	--	Dwarven Mythril Plate Belt of Maiming
	{ name = AceLib.API.Items.GetNameByID(26315), minimum = 960 },	--	Dwarven Mythril Plate Belt of Scouting
	{ name = AceLib.API.Items.GetNameByID(26285), minimum = 960 },	--	Dwarven Mythril Shield
	{ name = AceLib.API.Items.GetNameByID(11899), minimum = 160 },	--	Frypan Caliente
	{ name = AceLib.API.Items.GetNameByID(11896), minimum = 220 },	--	Hardsilver Alembic
	{ name = AceLib.API.Items.GetNameByID(10689), minimum = 400 },	--	Heavy Adamantite Gauntlets of Fending
	{ name = AceLib.API.Items.GetNameByID(18051), minimum = 320 },	--	High Steel Armguards of Fending
	{ name = AceLib.API.Items.GetNameByID(18205), minimum = 370 },	--	High Steel Barbut of Fending
	{ name = AceLib.API.Items.GetNameByID(19513), minimum = 320 },	--	High Steel Bomb Frypan
	{ name = AceLib.API.Items.GetNameByID(18213), minimum = 420 },	--	High Steel Gauntlets of Maiming
	{ name = AceLib.API.Items.GetNameByID(18048), minimum = 300 },	--	High Steel Hoplon
	{ name = AceLib.API.Items.GetNameByID(18212), minimum = 420 },	--	High Steel Mail of Maiming
	{ name = AceLib.API.Items.GetNameByID(18216), minimum = 370 },	--	High Steel Plate Belt of Maiming
	{ name = AceLib.API.Items.GetNameByID(18056), minimum = 320 },	--	High Steel Scale Mail of Maiming
	{ name = AceLib.API.Items.GetNameByID(18209), minimum = 420 },	--	High Steel Sollerets of Fending
	{ name = AceLib.API.Items.GetNameByID(11901), minimum = 290 },	--	Mandragoras Frypan
	{ name = AceLib.API.Items.GetNameByID(19575), minimum = 660 },	--	Molybdenum Alembic
	{ name = AceLib.API.Items.GetNameByID(18681), minimum = 650 },	--	Molybdenum Armguards of Maiming
	{ name = AceLib.API.Items.GetNameByID(18687), minimum = 650 },	--	Molybdenum Armguards of Striking
	{ name = AceLib.API.Items.GetNameByID(19576), minimum = 660 },	--	Molybdenum Frypan
	{ name = AceLib.API.Items.GetNameByID(18677), minimum = 650 },	--	Molybdenum Greaves of Fending
	{ name = AceLib.API.Items.GetNameByID(18673), minimum = 630 },	--	Molybdenum Headgear of Fending
	{ name = AceLib.API.Items.GetNameByID(18679), minimum = 630 },	--	Molybdenum Headgear of Maiming
	{ name = AceLib.API.Items.GetNameByID(19947), minimum = 625 },	--	Molybdenum Ingot
	{ name = AceLib.API.Items.GetNameByID(18678), minimum = 630 },	--	Molybdenum Plate Belt of Fending
	{ name = AceLib.API.Items.GetNameByID(18684), minimum = 630 },	--	Molybdenum Plate Belt of Maiming
	{ name = AceLib.API.Items.GetNameByID(18912), minimum = 660 },	--	Molybdenum Tassets of Fending
	{ name = AceLib.API.Items.GetNameByID(18918), minimum = 660 },	--	Molybdenum Tassets of Maiming
	{ name = AceLib.API.Items.GetNameByID(11895), minimum = 160 },	--	Mythrite Alembic
	{ name = AceLib.API.Items.GetNameByID(10665), minimum = 190 },	--	Mythrite Bladed Lantern Shield
	{ name = AceLib.API.Items.GetNameByID(10726), minimum = 130 },	--	Mythrite Gauntlets of Maiming
	{ name = AceLib.API.Items.GetNameByID(10677), minimum = 130 },	--	Mythrite Hauberk of Fending
	{ name = AceLib.API.Items.GetNameByID(10719), minimum = 130 },	--	Mythrite Hauberk of Maiming
	{ name = AceLib.API.Items.GetNameByID(10705), minimum = 130 },	--	Mythrite Sabatons of Fending
	{ name = AceLib.API.Items.GetNameByID(10747), minimum = 130 },	--	Mythrite Sabatons of Maiming
	{ name = AceLib.API.Items.GetNameByID(10670), minimum = 110 },	--	Mythrite Sallet of Fending
	{ name = AceLib.API.Items.GetNameByID(10664), minimum = 130 },	--	Mythrite Scutum
	{ name = AceLib.API.Items.GetNameByID(10733), minimum = 110 },	--	Mythrite Tassets of Maiming
	{ name = AceLib.API.Items.GetNameByID(18368), minimum = 510 },	--	Tigerskin Coat of Maiming
	{ name = AceLib.API.Items.GetNameByID(27125), minimum = 900 },	--	Titanbronze Alembic
	{ name = AceLib.API.Items.GetNameByID(26150), minimum = 830 },	--	Titanbronze Headband of Scouting
	{ name = AceLib.API.Items.GetNameByID(27126), minimum = 900 },	--	Titanbronze Moogle Frypan
	{ name = AceLib.API.Items.GetNameByID(26149), minimum = 830 },	--	Titanbronze Tassets of Aiming
	{ name = AceLib.API.Items.GetNameByID(26167), minimum = 830 },	--	Titanbronze Tassets of Casting
	{ name = AceLib.API.Items.GetNameByID(26161), minimum = 830 },	--	Titanbronze Tassets of Healing
	{ name = AceLib.API.Items.GetNameByID(26137), minimum = 830 },	--	Titanbronze Tassets of Maiming
	{ name = AceLib.API.Items.GetNameByID(26155), minimum = 830 },	--	Titanbronze Tassets of Scouting
	{ name = AceLib.API.Items.GetNameByID(11897), minimum = 290 },	--	Titanium Alembic
	{ name = AceLib.API.Items.GetNameByID(10721), minimum = 240 },	--	Titanium Cuirass of Maiming
	{ name = AceLib.API.Items.GetNameByID(11900), minimum = 220 },	--	Titanium Frypan
	{ name = AceLib.API.Items.GetNameByID(10757), minimum = 270 },	--	Titanium Headgear of Striking
	{ name = AceLib.API.Items.GetNameByID(10667), minimum = 290 },	--	Titanium Hoplon
	{ name = AceLib.API.Items.GetNameByID(10666), minimum = 240 },	--	Titanium Kite Shield
	{ name = AceLib.API.Items.GetNameByID(10764), minimum = 290 },	--	Titanium Mail of Striking
	{ name = AceLib.API.Items.GetNameByID(10840), minimum = 220 },	--	Titanium Mask of Scouting
	{ name = AceLib.API.Items.GetNameByID(10693), minimum = 190 },	--	Titanium Plate Belt of Fending
	{ name = AceLib.API.Items.GetNameByID(10714), minimum = 220 },	--	Titanium Sallet of Maiming
	{ name = AceLib.API.Items.GetNameByID(10707), minimum = 240 },	--	Titanium Sollerets of Fending
	{ name = AceLib.API.Items.GetNameByID(10694), minimum = 270 },	--	Titanium Tassets of Fending
	{ name = AceLib.API.Items.GetNameByID(10729), minimum = 270 },	--	Titanium Vambraces of Maiming
	{ name = AceLib.API.Items.GetNameByID(10855), minimum = 270 },	--	Titanium Vambraces of Scouting

	-- Goldsmith
	{ name = AceLib.API.Items.GetNameByID(11030), minimum = 110 },	--	Agate Ring of Aiming
	{ name = AceLib.API.Items.GetNameByID(10982), minimum = 110 },	--	Agate Ring of Fending
	{ name = AceLib.API.Items.GetNameByID(11054), minimum = 110 },	--	Agate Ring of Healing
	{ name = AceLib.API.Items.GetNameByID(11022), minimum = 320 },	--	Aurum Regis Bracelet of Aiming
	{ name = AceLib.API.Items.GetNameByID(11070), minimum = 320 },	--	Aurum Regis Bracelet of Casting
	{ name = AceLib.API.Items.GetNameByID(10974), minimum = 320 },	--	Aurum Regis Bracelet of Fending
	{ name = AceLib.API.Items.GetNameByID(10998), minimum = 320 },	--	Aurum Regis Bracelet of Slaying
	{ name = AceLib.API.Items.GetNameByID(10885), minimum = 400 },	--	Aurum Regis Circlet of Healing
	{ name = AceLib.API.Items.GetNameByID(11076), minimum = 320 },	--	Aurum Regis Earrings of Casting
	{ name = AceLib.API.Items.GetNameByID(11052), minimum = 320 },	--	Aurum Regis Earrings of Healing
	{ name = AceLib.API.Items.GetNameByID(11004), minimum = 320 },	--	Aurum Regis Earrings of Slaying
	{ name = AceLib.API.Items.GetNameByID(10644), minimum = 350 },	--	Aurum Regis Longpole
	{ name = AceLib.API.Items.GetNameByID(10662), minimum = 350 },	--	Aurum Regis Orrery
	{ name = AceLib.API.Items.GetNameByID(10663), minimum = 400 },	--	Aurum Regis Planisphere
	{ name = AceLib.API.Items.GetNameByID(10645), minimum = 400 },	--	Aurum Regis Staff
	{ name = AceLib.API.Items.GetNameByID(18571), minimum = 560 },	--	Azurite Bracelet of Aiming
	{ name = AceLib.API.Items.GetNameByID(18567), minimum = 610 },	--	Azurite Choker of Healing
	{ name = AceLib.API.Items.GetNameByID(18565), minimum = 610 },	--	Azurite Choker of Slaying
	{ name = AceLib.API.Items.GetNameByID(18563), minimum = 610 },	--	Azurite Earrings of Casting
	{ name = AceLib.API.Items.GetNameByID(18559), minimum = 610 },	--	Azurite Earrings of Fending
	{ name = AceLib.API.Items.GetNameByID(18578), minimum = 560 },	--	Azurite Ring of Casting
	{ name = AceLib.API.Items.GetNameByID(18577), minimum = 560 },	--	Azurite Ring of Healing
	{ name = AceLib.API.Items.GetNameByID(18575), minimum = 560 },	--	Azurite Ring of Slaying
	{ name = AceLib.API.Items.GetNameByID(12707), minimum = 400 },	--	Bladed Steel Jig
	{ name = AceLib.API.Items.GetNameByID(25949), minimum = 700 },	--	Bluespirit Baghnakhs
	{ name = AceLib.API.Items.GetNameByID(25953), minimum = 700 },	--	Bluespirit Daggers
	{ name = AceLib.API.Items.GetNameByID(25964), minimum = 700 },	--	Bluespirit Glaives
	{ name = AceLib.API.Items.GetNameByID(25952), minimum = 700 },	--	Bluespirit Longbow
	{ name = AceLib.API.Items.GetNameByID(25960), minimum = 700 },	--	Bluespirit Star Globe
	{ name = AceLib.API.Items.GetNameByID(25961), minimum = 700 },	--	Bluespirit Uchigatana
	{ name = AceLib.API.Items.GetNameByID(10999), minimum = 400 },	--	Chrysolite Bracelet of Slaying
	{ name = AceLib.API.Items.GetNameByID(10981), minimum = 400 },	--	Chrysolite Earrings of Fending
	{ name = AceLib.API.Items.GetNameByID(11035), minimum = 400 },	--	Chrysolite Ring of Aiming
	{ name = AceLib.API.Items.GetNameByID(12547), minimum = 370 },	--	Citrine
	{ name = AceLib.API.Items.GetNameByID(11017), minimum = 350 },	--	Citrine Choker of Aiming
	{ name = AceLib.API.Items.GetNameByID(11065), minimum = 350 },	--	Citrine Choker of Casting
	{ name = AceLib.API.Items.GetNameByID(10969), minimum = 350 },	--	Citrine Choker of Fending
	{ name = AceLib.API.Items.GetNameByID(25862), minimum = 640 },	--	Diaspore Bracelet of Casting
	{ name = AceLib.API.Items.GetNameByID(25856), minimum = 640 },	--	Diaspore Choker of Healing
	{ name = AceLib.API.Items.GetNameByID(25854), minimum = 640 },	--	Diaspore Choker of Slaying
	{ name = AceLib.API.Items.GetNameByID(25850), minimum = 570 },	--	Diaspore Earrings of Aiming
	{ name = AceLib.API.Items.GetNameByID(25848), minimum = 570 },	--	Diaspore Earrings of Fending
	{ name = AceLib.API.Items.GetNameByID(25865), minimum = 570 },	--	Diaspore Ring of Aiming
	{ name = AceLib.API.Items.GetNameByID(25864), minimum = 570 },	--	Diaspore Ring of Slaying
	{ name = AceLib.API.Items.GetNameByID(12018), minimum = 270 },	--	Dragon Fang Earrings
	{ name = AceLib.API.Items.GetNameByID(11893), minimum = 270 },	--	Dragon Fang Needle
	{ name = AceLib.API.Items.GetNameByID(18201), minimum = 420 },	--	Dual-plated Koppranickel Planisphere
	{ name = AceLib.API.Items.GetNameByID(19634), minimum = 510 },	--	Durium Chaplets
	{ name = AceLib.API.Items.GetNameByID(18354), minimum = 510 },	--	Durium Staff
	{ name = AceLib.API.Items.GetNameByID(27224), minimum = 1060 },	--	Dwarven Mythril Bracelets
	{ name = AceLib.API.Items.GetNameByID(27223), minimum = 1060 },	--	Dwarven Mythril Choker
	{ name = AceLib.API.Items.GetNameByID(27222), minimum = 1060 },	--	Dwarven Mythril Ear Cuffs
	{ name = AceLib.API.Items.GetNameByID(27145), minimum = 1060 },	--	Dwarven Mythril Needle
	{ name = AceLib.API.Items.GetNameByID(27225), minimum = 1060 },	--	Dwarven Mythril Ring
	{ name = AceLib.API.Items.GetNameByID(12706), minimum = 320 },	--	Goblin Jig
	{ name = AceLib.API.Items.GetNameByID(11894), minimum = 400 },	--	Griffin Talon Needle
	{ name = AceLib.API.Items.GetNameByID(10986), minimum = 350 },	--	Griffin Talon Ring of Fending
	{ name = AceLib.API.Items.GetNameByID(11058), minimum = 350 },	--	Griffin Talon Ring of Healing
	{ name = AceLib.API.Items.GetNameByID(11010), minimum = 350 },	--	Griffin Talon Ring of Slaying
	{ name = AceLib.API.Items.GetNameByID(11020), minimum = 240 },	--	Hardsilver Bangle of Aiming
	{ name = AceLib.API.Items.GetNameByID(10978), minimum = 240 },	--	Hardsilver Earrings of Fending
	{ name = AceLib.API.Items.GetNameByID(12030), minimum = 290 },	--	Hardsilver Earrings of Gathering
	{ name = AceLib.API.Items.GetNameByID(11050), minimum = 240 },	--	Hardsilver Earrings of Healing
	{ name = AceLib.API.Items.GetNameByID(10882), minimum = 220 },	--	Hardsilver Monocle of Healing
	{ name = AceLib.API.Items.GetNameByID(11892), minimum = 220 },	--	Hardsilver Needle
	{ name = AceLib.API.Items.GetNameByID(10643), minimum = 290 },	--	Hardsilver Pole
	{ name = AceLib.API.Items.GetNameByID(10642), minimum = 220 },	--	Hardsilver Staff
	{ name = AceLib.API.Items.GetNameByID(10660), minimum = 240 },	--	Hardsilver Star Globe
	{ name = AceLib.API.Items.GetNameByID(25694), minimum = 500 },	--	Hematite Choker of Slaying
	{ name = AceLib.API.Items.GetNameByID(25688), minimum = 500 },	--	Hematite Earrings of Fending
	{ name = AceLib.API.Items.GetNameByID(19966), minimum = 625 },	--	Imperial Jade
	{ name = AceLib.API.Items.GetNameByID(18951), minimum = 660 },	--	Imperial Jade Earrings of Aiming
	{ name = AceLib.API.Items.GetNameByID(18949), minimum = 660 },	--	Imperial Jade Earrings of Fending
	{ name = AceLib.API.Items.GetNameByID(18952), minimum = 660 },	--	Imperial Jade Earrings of Healing
	{ name = AceLib.API.Items.GetNameByID(18950), minimum = 660 },	--	Imperial Jade Earrings of Slaying
	{ name = AceLib.API.Items.GetNameByID(18956), minimum = 660 },	--	Imperial Jade Necklace of Aiming
	{ name = AceLib.API.Items.GetNameByID(18958), minimum = 660 },	--	Imperial Jade Necklace of Casting
	{ name = AceLib.API.Items.GetNameByID(18954), minimum = 660 },	--	Imperial Jade Necklace of Fending
	{ name = AceLib.API.Items.GetNameByID(18955), minimum = 660 },	--	Imperial Jade Necklace of Slaying
	{ name = AceLib.API.Items.GetNameByID(25700), minimum = 500 },	--	Islewolf Bracelet of Aiming
	{ name = AceLib.API.Items.GetNameByID(25707), minimum = 500 },	--	Islewolf Ring of Casting
	{ name = AceLib.API.Items.GetNameByID(25706), minimum = 500 },	--	Islewolf Ring of Healing
	{ name = AceLib.API.Items.GetNameByID(18257), minimum = 370 },	--	Koppranickel Bracelet of Fending
	{ name = AceLib.API.Items.GetNameByID(18260), minimum = 370 },	--	Koppranickel Bracelet of Healing
	{ name = AceLib.API.Items.GetNameByID(18250), minimum = 420 },	--	Koppranickel Earrings of Healing
	{ name = AceLib.API.Items.GetNameByID(18248), minimum = 420 },	--	Koppranickel Earrings of Slaying
	{ name = AceLib.API.Items.GetNameByID(18254), minimum = 420 },	--	Koppranickel Necklace of Aiming
	{ name = AceLib.API.Items.GetNameByID(18256), minimum = 420 },	--	Koppranickel Necklace of Casting
	{ name = AceLib.API.Items.GetNameByID(27212), minimum = 770 },	--	Manasilver Ear Cuffs
	{ name = AceLib.API.Items.GetNameByID(27103), minimum = 770 },	--	Manasilver Needle
	{ name = AceLib.API.Items.GetNameByID(18719), minimum = 630 },	--	Molybdenum Earring of Casting
	{ name = AceLib.API.Items.GetNameByID(18716), minimum = 630 },	--	Molybdenum Earring of Slaying
	{ name = AceLib.API.Items.GetNameByID(11008), minimum = 220 },	--	Mormorion Ring of Slaying
	{ name = AceLib.API.Items.GetNameByID(18263), minimum = 370 },	--	Muudhorn Ring of Slaying
	{ name = AceLib.API.Items.GetNameByID(10994), minimum = 130 },	--	Mythrite Bangle of Slaying
	{ name = AceLib.API.Items.GetNameByID(11043), minimum = 160 },	--	Mythrite Bracelet of Healing
	{ name = AceLib.API.Items.GetNameByID(10754), minimum = 130 },	--	Mythrite Circlet of Striking
	{ name = AceLib.API.Items.GetNameByID(10977), minimum = 160 },	--	Mythrite Earblades of Fending
	{ name = AceLib.API.Items.GetNameByID(11072), minimum = 130 },	--	Mythrite Earrings of Casting
	{ name = AceLib.API.Items.GetNameByID(11983), minimum = 130 },	--	Mythrite Goggles of Gathering
	{ name = AceLib.API.Items.GetNameByID(11013), minimum = 190 },	--	Mythrite Necklace of Aiming
	{ name = AceLib.API.Items.GetNameByID(11891), minimum = 160 },	--	Mythrite Needle
	{ name = AceLib.API.Items.GetNameByID(10659), minimum = 190 },	--	Mythrite Planisphere
	{ name = AceLib.API.Items.GetNameByID(11069), minimum = 270 },	--	Opal Bracelet of Casting
	{ name = AceLib.API.Items.GetNameByID(11027), minimum = 290 },	--	Opal Earrings of Aiming
	{ name = AceLib.API.Items.GetNameByID(10979), minimum = 290 },	--	Opal Earrings of Fending
	{ name = AceLib.API.Items.GetNameByID(11009), minimum = 270 },	--	Opal Ring of Slaying
	{ name = AceLib.API.Items.GetNameByID(18726), minimum = 630 },	--	Palladium Bracelet of Slaying
	{ name = AceLib.API.Items.GetNameByID(18723), minimum = 630 },	--	Palladium Choker of Healing
	{ name = AceLib.API.Items.GetNameByID(19574), minimum = 650 },	--	Palladium Needle
	{ name = AceLib.API.Items.GetNameByID(18669), minimum = 650 },	--	Palladium Planisphere
	{ name = AceLib.API.Items.GetNameByID(18732), minimum = 630 },	--	Palladium Ring of Aiming
	{ name = AceLib.API.Items.GetNameByID(18730), minimum = 630 },	--	Palladium Ring of Fending
	{ name = AceLib.API.Items.GetNameByID(26340), minimum = 960 },	--	Petalite Bracelet of Aiming
	{ name = AceLib.API.Items.GetNameByID(26339), minimum = 960 },	--	Petalite Bracelet of Slaying
	{ name = AceLib.API.Items.GetNameByID(26333), minimum = 960 },	--	Petalite Choker of Fending
	{ name = AceLib.API.Items.GetNameByID(26334), minimum = 960 },	--	Petalite Choker of Slaying
	{ name = AceLib.API.Items.GetNameByID(26332), minimum = 930 },	--	Petalite Earrings of Casting
	{ name = AceLib.API.Items.GetNameByID(26331), minimum = 930 },	--	Petalite Earrings of Healing
	{ name = AceLib.API.Items.GetNameByID(26345), minimum = 930 },	--	Petalite Ring of Aiming
	{ name = AceLib.API.Items.GetNameByID(26343), minimum = 930 },	--	Petalite Ring of Fending
	{ name = AceLib.API.Items.GetNameByID(12544), minimum = 260 },	--	Star Ruby
	{ name = AceLib.API.Items.GetNameByID(18416), minimum = 470 },	--	Star Spinel Bracelet of Healing
	{ name = AceLib.API.Items.GetNameByID(18409), minimum = 510 },	--	Star Spinel Choker of Slaying
	{ name = AceLib.API.Items.GetNameByID(18407), minimum = 510 },	--	Star Spinel Earrings of Casting
	{ name = AceLib.API.Items.GetNameByID(18406), minimum = 510 },	--	Star Spinel Earrings of Healing
	{ name = AceLib.API.Items.GetNameByID(18420), minimum = 470 },	--	Star Spinel Ring of Aiming
	{ name = AceLib.API.Items.GetNameByID(18418), minimum = 470 },	--	Star Spinel Ring of Fending
	{ name = AceLib.API.Items.GetNameByID(25640), minimum = 500 },	--	Stonegold Astrometer
	{ name = AceLib.API.Items.GetNameByID(25652), minimum = 500 },	--	Stonegold Circlet of Maiming
	{ name = AceLib.API.Items.GetNameByID(25642), minimum = 500 },	--	Stonegold Degen
	{ name = AceLib.API.Items.GetNameByID(25800), minimum = 640 },	--	Stonegold Orrery
	{ name = AceLib.API.Items.GetNameByID(26126), minimum = 900 },	--	Titanbronze Headgear of Fending
	{ name = AceLib.API.Items.GetNameByID(26132), minimum = 900 },	--	Titanbronze Headgear of Maiming
	{ name = AceLib.API.Items.GetNameByID(26122), minimum = 830 },	--	Titanbronze Rapier
	{ name = AceLib.API.Items.GetNameByID(18104), minimum = 300 },	--	Triphane Bracelet of Healing
	{ name = AceLib.API.Items.GetNameByID(18099), minimum = 320 },	--	Triphane Choker of Healing
	{ name = AceLib.API.Items.GetNameByID(18097), minimum = 320 },	--	Triphane Choker of Slaying
	{ name = AceLib.API.Items.GetNameByID(18093), minimum = 320 },	--	Triphane Earrings of Aiming
	{ name = AceLib.API.Items.GetNameByID(18091), minimum = 320 },	--	Triphane Earrings of Fending
	{ name = AceLib.API.Items.GetNameByID(18108), minimum = 300 },	--	Triphane Ring of Aiming
	{ name = AceLib.API.Items.GetNameByID(18110), minimum = 300 },	--	Triphane Ring of Casting
	{ name = AceLib.API.Items.GetNameByID(18106), minimum = 300 },	--	Triphane Ring of Fending
	{ name = AceLib.API.Items.GetNameByID(26180), minimum = 900 },	--	Triplite Bracelet of Aiming
	{ name = AceLib.API.Items.GetNameByID(26182), minimum = 900 },	--	Triplite Bracelet of Casting
	{ name = AceLib.API.Items.GetNameByID(26173), minimum = 900 },	--	Triplite Choker of Fending
	{ name = AceLib.API.Items.GetNameByID(26171), minimum = 830 },	--	Triplite Earrings of Healing
	{ name = AceLib.API.Items.GetNameByID(26183), minimum = 830 },	--	Triplite Ring of Fending
	{ name = AceLib.API.Items.GetNameByID(12017), minimum = 160 },	--	Yeti Fang Earrings
	{ name = AceLib.API.Items.GetNameByID(11079), minimum = 190 },	--	Yeti Fang Ring of Casting
	{ name = AceLib.API.Items.GetNameByID(11007), minimum = 190 },	--	Yeti Fang Ring of Slaying
	{ name = AceLib.API.Items.GetNameByID(10640), minimum = 130 },	--	Yeti Staff

	-- Leatherworker
	{ name = AceLib.API.Items.GetNameByID(12566), minimum = 360 },	--	Amphiptere Leather
	{ name = AceLib.API.Items.GetNameByID(10775), minimum = 110 },	--	Archaeoskin Belt of Striking
	{ name = AceLib.API.Items.GetNameByID(10698), minimum = 130 },	--	Archaeoskin Breeches of Fending
	{ name = AceLib.API.Items.GetNameByID(10740), minimum = 130 },	--	Archaeoskin Breeches of Maiming
	{ name = AceLib.API.Items.GetNameByID(11965), minimum = 130 },	--	Archaeoskin Gloves of Crafting
	{ name = AceLib.API.Items.GetNameByID(11993), minimum = 130 },	--	Archaeoskin Gloves of Gathering
	{ name = AceLib.API.Items.GetNameByID(10894), minimum = 110 },	--	Archaeoskin Gloves of Healing
	{ name = AceLib.API.Items.GetNameByID(11978), minimum = 160 },	--	Archaeoskin Jackboots of Crafting
	{ name = AceLib.API.Items.GetNameByID(11988), minimum = 160 },	--	Archaeoskin Jackcoat of Gathering
	{ name = AceLib.API.Items.GetNameByID(10831), minimum = 130 },	--	Archaeoskin Shoes of Aiming
	{ name = AceLib.API.Items.GetNameByID(10957), minimum = 130 },	--	Archaeoskin Shoes of Casting
	{ name = AceLib.API.Items.GetNameByID(26019), minimum = 700 },	--	Atrociraptorskin Amulet of Slaying
	{ name = AceLib.API.Items.GetNameByID(25969), minimum = 770 },	--	Atrociraptorskin Breeches of Fending
	{ name = AceLib.API.Items.GetNameByID(27176), minimum = 700 },	--	Atrociraptorskin Cap of Gathering
	{ name = AceLib.API.Items.GetNameByID(26003), minimum = 770 },	--	Atrociraptorskin Coat of Casting
	{ name = AceLib.API.Items.GetNameByID(25985), minimum = 770 },	--	Atrociraptorskin Corselet of Aiming
	{ name = AceLib.API.Items.GetNameByID(25991), minimum = 770 },	--	Atrociraptorskin Corselet of Scouting
	{ name = AceLib.API.Items.GetNameByID(25984), minimum = 700 },	--	Atrociraptorskin Headgear of Aiming
	{ name = AceLib.API.Items.GetNameByID(26013), minimum = 770 },	--	Atrociraptorskin Necklace of Fending
	{ name = AceLib.API.Items.GetNameByID(12564), minimum = 250 },	--	Dhalmel Leather
	{ name = AceLib.API.Items.GetNameByID(10770), minimum = 220 },	--	Dhalmelskin Armguards of Striking
	{ name = AceLib.API.Items.GetNameByID(10945), minimum = 220 },	--	Dhalmelskin Belt of Casting
	{ name = AceLib.API.Items.GetNameByID(10700), minimum = 240 },	--	Dhalmelskin Breeches of Fending
	{ name = AceLib.API.Items.GetNameByID(10917), minimum = 240 },	--	Dhalmelskin Crakows of Healing
	{ name = AceLib.API.Items.GetNameByID(11967), minimum = 240 },	--	Dhalmelskin Halfgloves of Crafting
	{ name = AceLib.API.Items.GetNameByID(10805), minimum = 240 },	--	Dhalmelskin Jacket of Aiming
	{ name = AceLib.API.Items.GetNameByID(11980), minimum = 270 },	--	Dhalmelskin Shoes
	{ name = AceLib.API.Items.GetNameByID(11971), minimum = 320 },	--	Dragonskin Belt of Crafting
	{ name = AceLib.API.Items.GetNameByID(10736), minimum = 270 },	--	Dragonskin Belt of Maiming
	{ name = AceLib.API.Items.GetNameByID(10918), minimum = 290 },	--	Dragonskin Boots of Healing
	{ name = AceLib.API.Items.GetNameByID(10701), minimum = 290 },	--	Dragonskin Breeches of Fending
	{ name = AceLib.API.Items.GetNameByID(10869), minimum = 290 },	--	Dragonskin Breeches of Scouting
	{ name = AceLib.API.Items.GetNameByID(12024), minimum = 320 },	--	Dragonskin Choker
	{ name = AceLib.API.Items.GetNameByID(10813), minimum = 270 },	--	Dragonskin Gloves of Aiming
	{ name = AceLib.API.Items.GetNameByID(10897), minimum = 270 },	--	Dragonskin Gloves of Healing
	{ name = AceLib.API.Items.GetNameByID(12033), minimum = 290 },	--	Dragonskin Ring
	{ name = AceLib.API.Items.GetNameByID(12027), minimum = 320 },	--	Dragonskin Wristbands
	{ name = AceLib.API.Items.GetNameByID(19661), minimum = 660 },	--	Fur-lined Gazelleskin Boots
	{ name = AceLib.API.Items.GetNameByID(18090), minimum = 300 },	--	Gaganaskin Belt of Casting
	{ name = AceLib.API.Items.GetNameByID(18060), minimum = 300 },	--	Gaganaskin Belt of Maiming
	{ name = AceLib.API.Items.GetNameByID(19617), minimum = 320 },	--	Gaganaskin Bush Hat
	{ name = AceLib.API.Items.GetNameByID(18070), minimum = 320 },	--	Gaganaskin Chaps of Aiming
	{ name = AceLib.API.Items.GetNameByID(19619), minimum = 320 },	--	Gaganaskin Gloves
	{ name = AceLib.API.Items.GetNameByID(18068), minimum = 320 },	--	Gaganaskin Jacket of Aiming
	{ name = AceLib.API.Items.GetNameByID(18053), minimum = 320 },	--	Gaganaskin Leg Guards of Fending
	{ name = AceLib.API.Items.GetNameByID(19616), minimum = 320 },	--	Gaganaskin Shoes
	{ name = AceLib.API.Items.GetNameByID(19997), minimum = 625 },	--	Gazelle Leather
	{ name = AceLib.API.Items.GetNameByID(18693), minimum = 650 },	--	Gazelleskin Armguards of Aiming
	{ name = AceLib.API.Items.GetNameByID(19752), minimum = 660 },	--	Gazelleskin Belt of Gathering
	{ name = AceLib.API.Items.GetNameByID(18707), minimum = 630 },	--	Gazelleskin Boots of Healing
	{ name = AceLib.API.Items.GetNameByID(18682), minimum = 650 },	--	Gazelleskin Brais of Maiming
	{ name = AceLib.API.Items.GetNameByID(18700), minimum = 650 },	--	Gazelleskin Brais of Scouting
	{ name = AceLib.API.Items.GetNameByID(19754), minimum = 660 },	--	Gazelleskin Choker
	{ name = AceLib.API.Items.GetNameByID(18704), minimum = 650 },	--	Gazelleskin Coat of Healing
	{ name = AceLib.API.Items.GetNameByID(19753), minimum = 660 },	--	Gazelleskin Earrings
	{ name = AceLib.API.Items.GetNameByID(19654), minimum = 660 },	--	Gazelleskin Gloves of Crafting
	{ name = AceLib.API.Items.GetNameByID(18689), minimum = 630 },	--	Gazelleskin Open-toe Boots of Striking
	{ name = AceLib.API.Items.GetNameByID(18930), minimum = 660 },	--	Gazelleskin Ringbelt of Aiming
	{ name = AceLib.API.Items.GetNameByID(18924), minimum = 660 },	--	Gazelleskin Ringbelt of Striking
	{ name = AceLib.API.Items.GetNameByID(18702), minimum = 630 },	--	Gazelleskin Twinbelt of Scouting
	{ name = AceLib.API.Items.GetNameByID(18690), minimum = 630 },	--	Gazelleskin Twinbelt of Striking
	{ name = AceLib.API.Items.GetNameByID(19755), minimum = 660 },	--	Gazelleskin Wristband
	{ name = AceLib.API.Items.GetNameByID(25828), minimum = 570 },	--	Gliderskin Boots of Aiming
	{ name = AceLib.API.Items.GetNameByID(25840), minimum = 640 },	--	Gliderskin Boots of Healing
	{ name = AceLib.API.Items.GetNameByID(25815), minimum = 640 },	--	Gliderskin Breeches of Maiming
	{ name = AceLib.API.Items.GetNameByID(25826), minimum = 570 },	--	Gliderskin Gloves of Aiming
	{ name = AceLib.API.Items.GetNameByID(25832), minimum = 570 },	--	Gliderskin Gloves of Scouting
	{ name = AceLib.API.Items.GetNameByID(25810), minimum = 640 },	--	Gliderskin Thighboots of Fending
	{ name = AceLib.API.Items.GetNameByID(25834), minimum = 570 },	--	Gliderskin Thighboots of Scouting
	{ name = AceLib.API.Items.GetNameByID(25822), minimum = 570 },	--	Gliderskin Thighboots of Striking
	{ name = AceLib.API.Items.GetNameByID(18239), minimum = 420 },	--	Gyuki Leather Boots of Healing
	{ name = AceLib.API.Items.GetNameByID(19733), minimum = 420 },	--	Gyuki Leather Earrings
	{ name = AceLib.API.Items.GetNameByID(19624), minimum = 420 },	--	Gyuki Leather Gloves of Crafting
	{ name = AceLib.API.Items.GetNameByID(18219), minimum = 370 },	--	Gyuki Leather Halfgloves of Striking
	{ name = AceLib.API.Items.GetNameByID(19736), minimum = 420 },	--	Gyuki Leather Ring
	{ name = AceLib.API.Items.GetNameByID(18214), minimum = 370 },	--	Gyuki Leather Trousers of Maiming
	{ name = AceLib.API.Items.GetNameByID(18228), minimum = 370 },	--	Gyuki Leather Twinbelt of Aiming
	{ name = AceLib.API.Items.GetNameByID(18234), minimum = 370 },	--	Gyuki Leather Twinbelt of Scouting
	{ name = AceLib.API.Items.GetNameByID(19651), minimum = 610 },	--	Marid Leather Babouches of Gathering
	{ name = AceLib.API.Items.GetNameByID(18522), minimum = 560 },	--	Marid Leather Belt of Fending
	{ name = AceLib.API.Items.GetNameByID(18551), minimum = 560 },	--	Marid Leather Boots of Healing
	{ name = AceLib.API.Items.GetNameByID(18544), minimum = 610 },	--	Marid Leather Breeches of Scouting
	{ name = AceLib.API.Items.GetNameByID(19744), minimum = 610 },	--	Marid Leather Choker
	{ name = AceLib.API.Items.GetNameByID(18530), minimum = 610 },	--	Marid Leather Coat of Striking
	{ name = AceLib.API.Items.GetNameByID(18558), minimum = 560 },	--	Marid Leather Corset of Casting
	{ name = AceLib.API.Items.GetNameByID(19644), minimum = 610 },	--	Marid Leather Gloves of Crafting
	{ name = AceLib.API.Items.GetNameByID(10856), minimum = 320 },	--	Serpentskin Armguards of Scouting
	{ name = AceLib.API.Items.GetNameByID(10772), minimum = 320 },	--	Serpentskin Armguards of Striking
	{ name = AceLib.API.Items.GetNameByID(10962), minimum = 400 },	--	Serpentskin Bootlets of Casting
	{ name = AceLib.API.Items.GetNameByID(10793), minimum = 350 },	--	Serpentskin Boots of Striking
	{ name = AceLib.API.Items.GetNameByID(10815), minimum = 350 },	--	Serpentskin Bracers of Aiming
	{ name = AceLib.API.Items.GetNameByID(10871), minimum = 400 },	--	Serpentskin Brais of Scouting
	{ name = AceLib.API.Items.GetNameByID(10940), minimum = 320 },	--	Serpentskin Dress Gloves of Casting
	{ name = AceLib.API.Items.GetNameByID(11997), minimum = 350 },	--	Serpentskin Gloves
	{ name = AceLib.API.Items.GetNameByID(10941), minimum = 350 },	--	Serpentskin Gloves of Casting
	{ name = AceLib.API.Items.GetNameByID(11969), minimum = 350 },	--	Serpentskin Halfgloves of Crafting
	{ name = AceLib.API.Items.GetNameByID(10926), minimum = 320 },	--	Serpentskin Hat of Casting
	{ name = AceLib.API.Items.GetNameByID(10717), minimum = 400 },	--	Serpentskin Helm of Maiming
	{ name = AceLib.API.Items.GetNameByID(10745), minimum = 400 },	--	Serpentskin Hose of Maiming
	{ name = AceLib.API.Items.GetNameByID(10864), minimum = 350 },	--	Serpentskin Hunting Belt of Scouting
	{ name = AceLib.API.Items.GetNameByID(10821), minimum = 320 },	--	Serpentskin Ringbelt of Aiming
	{ name = AceLib.API.Items.GetNameByID(11982), minimum = 400 },	--	Serpentskin Shoes
	{ name = AceLib.API.Items.GetNameByID(10836), minimum = 400 },	--	Serpentskin Thighboots of Aiming
	{ name = AceLib.API.Items.GetNameByID(10919), minimum = 350 },	--	Serpentskin Thighboots of Healing
	{ name = AceLib.API.Items.GetNameByID(10794), minimum = 400 },	--	Serpentskin Thighboots of Striking
	{ name = AceLib.API.Items.GetNameByID(11992), minimum = 400 },	--	Serpentskin Vest
	{ name = AceLib.API.Items.GetNameByID(10738), minimum = 350 },	--	Serpentskin Voyager's Belt of Maiming
	{ name = AceLib.API.Items.GetNameByID(25678), minimum = 500 },	--	Smilodonskin Armguards of Healing
	{ name = AceLib.API.Items.GetNameByID(25686), minimum = 500 },	--	Smilodonskin Boots of Casting
	{ name = AceLib.API.Items.GetNameByID(27163), minimum = 500 },	--	Smilodonskin Gloves of Crafting
	{ name = AceLib.API.Items.GetNameByID(27168), minimum = 500 },	--	Smilodonskin Gloves of Gathering
	{ name = AceLib.API.Items.GetNameByID(25672), minimum = 500 },	--	Smilodonskin Gloves of Scouting
	{ name = AceLib.API.Items.GetNameByID(25656), minimum = 500 },	--	Smilodonskin Leggings of Maiming
	{ name = AceLib.API.Items.GetNameByID(27201), minimum = 500 },	--	Smilodonskin Tool Belt
	{ name = AceLib.API.Items.GetNameByID(25649), minimum = 500 },	--	Smilodonskin Trousers of Fending
	{ name = AceLib.API.Items.GetNameByID(27200), minimum = 1060 },	--	Swallowskin Boots
	{ name = AceLib.API.Items.GetNameByID(27197), minimum = 1060 },	--	Swallowskin Coat
	{ name = AceLib.API.Items.GetNameByID(27193), minimum = 1060 },	--	Swallowskin Fingerless Gloves
	{ name = AceLib.API.Items.GetNameByID(27198), minimum = 1060 },	--	Swallowskin Gloves
	{ name = AceLib.API.Items.GetNameByID(26306), minimum = 930 },	--	Swallowskin Gloves of Aiming
	{ name = AceLib.API.Items.GetNameByID(26294), minimum = 930 },	--	Swallowskin Gloves of Maiming
	{ name = AceLib.API.Items.GetNameByID(26300), minimum = 930 },	--	Swallowskin Gloves of Striking
	{ name = AceLib.API.Items.GetNameByID(26305), minimum = 930 },	--	Swallowskin Robe of Aiming
	{ name = AceLib.API.Items.GetNameByID(26317), minimum = 960 },	--	Swallowskin Robe of Healing
	{ name = AceLib.API.Items.GetNameByID(27195), minimum = 1060 },	--	Swallowskin Shoes
	{ name = AceLib.API.Items.GetNameByID(26302), minimum = 930 },	--	Swallowskin Shoes of Striking
	{ name = AceLib.API.Items.GetNameByID(27226), minimum = 960 },	--	Swallowskin Survival Belt
	{ name = AceLib.API.Items.GetNameByID(27221), minimum = 960 },	--	Swallowskin Tool Belt
	{ name = AceLib.API.Items.GetNameByID(18393), minimum = 470 },	--	Tigerskin Armguards of Healing
	{ name = AceLib.API.Items.GetNameByID(19641), minimum = 510 },	--	Tigerskin Boots of Gathering
	{ name = AceLib.API.Items.GetNameByID(19637), minimum = 510 },	--	Tigerskin Cap of Gathering
	{ name = AceLib.API.Items.GetNameByID(18401), minimum = 510 },	--	Tigerskin Jackboots of Casting
	{ name = AceLib.API.Items.GetNameByID(18390), minimum = 470 },	--	Tigerskin Ringbelt of Scouting
	{ name = AceLib.API.Items.GetNameByID(18383), minimum = 510 },	--	Tigerskin Thighboots of Aiming
	{ name = AceLib.API.Items.GetNameByID(18373), minimum = 510 },	--	Tigerskin Tricorne of Striking
	{ name = AceLib.API.Items.GetNameByID(18375), minimum = 470 },	--	Tigerskin Wristgloves of Striking
	{ name = AceLib.API.Items.GetNameByID(10860), minimum = 160 },	--	Wyvernskin Belt of Scouting
	{ name = AceLib.API.Items.GetNameByID(10916), minimum = 190 },	--	Wyvernskin Boots of Healing
	{ name = AceLib.API.Items.GetNameByID(12023), minimum = 220 },	--	Wyvernskin Choker
	{ name = AceLib.API.Items.GetNameByID(10685), minimum = 160 },	--	Wyvernskin Gloves of Fending
	{ name = AceLib.API.Items.GetNameByID(11989), minimum = 220 },	--	Wyvernskin Jerkin
	{ name = AceLib.API.Items.GetNameByID(10923), minimum = 190 },	--	Wyvernskin Mask of Casting
	{ name = AceLib.API.Items.GetNameByID(10713), minimum = 190 },	--	Wyvernskin Pot Helm of Maiming
	{ name = AceLib.API.Items.GetNameByID(12026), minimum = 190 },	--	Wyvernskin Wristbands
	{ name = AceLib.API.Items.GetNameByID(26130), minimum = 900 },	--	Zonureskin Caligae of Fending
	{ name = AceLib.API.Items.GetNameByID(26136), minimum = 900 },	--	Zonureskin Caligae of Maiming
	{ name = AceLib.API.Items.GetNameByID(26127), minimum = 900 },	--	Zonureskin Coat of Fending
	{ name = AceLib.API.Items.GetNameByID(26164), minimum = 830 },	--	Zonureskin Fingerless Gloves of Casting
	{ name = AceLib.API.Items.GetNameByID(26158), minimum = 830 },	--	Zonureskin Fingerless Gloves of Healing
	{ name = AceLib.API.Items.GetNameByID(26140), minimum = 830 },	--	Zonureskin Fingerless Gloves of Striking
	{ name = AceLib.API.Items.GetNameByID(27182), minimum = 900 },	--	Zonureskin Jacket of Crafting
	{ name = AceLib.API.Items.GetNameByID(27187), minimum = 900 },	--	Zonureskin Robe of Gathering

	-- Weaver
	{ name = AceLib.API.Items.GetNameByID(18076), minimum = 300 },	--	Bloodhempen Brais of Scouting
	{ name = AceLib.API.Items.GetNameByID(18064), minimum = 300 },	--	Bloodhempen Brais of Striking
	{ name = AceLib.API.Items.GetNameByID(18086), minimum = 320 },	--	Bloodhempen Chestwrap of Casting
	{ name = AceLib.API.Items.GetNameByID(18082), minimum = 300 },	--	Bloodhempen Culottes of Healing
	{ name = AceLib.API.Items.GetNameByID(19615), minimum = 320 },	--	Bloodhempen Skirt
	{ name = AceLib.API.Items.GetNameByID(18074), minimum = 320 },	--	Bloodhempen Vest of Scouting
	{ name = AceLib.API.Items.GetNameByID(25682), minimum = 500 },	--	Brightlinen Cap of Casting
	{ name = AceLib.API.Items.GetNameByID(27167), minimum = 500 },	--	Brightlinen Coat of Gathering
	{ name = AceLib.API.Items.GetNameByID(25677), minimum = 500 },	--	Brightlinen Cyclas of Healing
	{ name = AceLib.API.Items.GetNameByID(27162), minimum = 500 },	--	Brightlinen Doublet Vest of Crafting
	{ name = AceLib.API.Items.GetNameByID(25664), minimum = 500 },	--	Brightlinen Hood of Aiming
	{ name = AceLib.API.Items.GetNameByID(25658), minimum = 500 },	--	Brightlinen Hood of Striking
	{ name = AceLib.API.Items.GetNameByID(25673), minimum = 500 },	--	Brightlinen Hose of Scouting
	{ name = AceLib.API.Items.GetNameByID(25653), minimum = 500 },	--	Brightlinen Tabard of Maiming
	{ name = AceLib.API.Items.GetNameByID(12592), minimum = 360 },	--	Chimerical Felt
	{ name = AceLib.API.Items.GetNameByID(10891), minimum = 350 },	--	Chimerical Felt Alb of Healing
	{ name = AceLib.API.Items.GetNameByID(10703), minimum = 400 },	--	Chimerical Felt Breeches of Fending
	{ name = AceLib.API.Items.GetNameByID(10913), minimum = 400 },	--	Chimerical Felt Breeches of Healing
	{ name = AceLib.API.Items.GetNameByID(10800), minimum = 320 },	--	Chimerical Felt Cap of Aiming
	{ name = AceLib.API.Items.GetNameByID(10842), minimum = 320 },	--	Chimerical Felt Cap of Scouting
	{ name = AceLib.API.Items.GetNameByID(10758), minimum = 320 },	--	Chimerical Felt Cap of Striking
	{ name = AceLib.API.Items.GetNameByID(10912), minimum = 350 },	--	Chimerical Felt Chausses of Healing
	{ name = AceLib.API.Items.GetNameByID(10801), minimum = 400 },	--	Chimerical Felt Coif of Aiming
	{ name = AceLib.API.Items.GetNameByID(10947), minimum = 320 },	--	Chimerical Felt Corset of Casting
	{ name = AceLib.API.Items.GetNameByID(10905), minimum = 320 },	--	Chimerical Felt Corset of Healing
	{ name = AceLib.API.Items.GetNameByID(10849), minimum = 350 },	--	Chimerical Felt Cyclas of Scouting
	{ name = AceLib.API.Items.GetNameByID(10765), minimum = 350 },	--	Chimerical Felt Cyclas of Striking
	{ name = AceLib.API.Items.GetNameByID(11964), minimum = 400 },	--	Chimerical Felt Doublet of Crafting
	{ name = AceLib.API.Items.GetNameByID(10898), minimum = 320 },	--	Chimerical Felt Gloves of Healing
	{ name = AceLib.API.Items.GetNameByID(10927), minimum = 400 },	--	Chimerical Felt Hat of Casting
	{ name = AceLib.API.Items.GetNameByID(10828), minimum = 350 },	--	Chimerical Felt Hose of Aiming
	{ name = AceLib.API.Items.GetNameByID(10884), minimum = 320 },	--	Chimerical Felt Klobuk of Healing
	{ name = AceLib.API.Items.GetNameByID(10933), minimum = 350 },	--	Chimerical Felt Robe of Casting
	{ name = AceLib.API.Items.GetNameByID(10822), minimum = 350 },	--	Chimerical Felt Sash of Aiming
	{ name = AceLib.API.Items.GetNameByID(10948), minimum = 350 },	--	Chimerical Felt Sash of Casting
	{ name = AceLib.API.Items.GetNameByID(10850), minimum = 400 },	--	Chimerical Felt Tabard of Scouting
	{ name = AceLib.API.Items.GetNameByID(10766), minimum = 400 },	--	Chimerical Felt Tabard of Striking
	{ name = AceLib.API.Items.GetNameByID(12005), minimum = 400 },	--	Chimerical Felt Trousers
	{ name = AceLib.API.Items.GetNameByID(19655), minimum = 660 },	--	Cropped Twinsilk Slops
	{ name = AceLib.API.Items.GetNameByID(27196), minimum = 1060 },	--	Dwarven Cotton Bandana
	{ name = AceLib.API.Items.GetNameByID(27191), minimum = 1060 },	--	Dwarven Cotton Beret
	{ name = AceLib.API.Items.GetNameByID(27199), minimum = 1060 },	--	Dwarven Cotton Breeches
	{ name = AceLib.API.Items.GetNameByID(26307), minimum = 960 },	--	Dwarven Cotton Gaskins of Aiming
	{ name = AceLib.API.Items.GetNameByID(26325), minimum = 930 },	--	Dwarven Cotton Gaskins of Casting
	{ name = AceLib.API.Items.GetNameByID(26319), minimum = 930 },	--	Dwarven Cotton Gaskins of Healing
	{ name = AceLib.API.Items.GetNameByID(26295), minimum = 930 },	--	Dwarven Cotton Gaskins of Maiming
	{ name = AceLib.API.Items.GetNameByID(26313), minimum = 960 },	--	Dwarven Cotton Gaskins of Scouting
	{ name = AceLib.API.Items.GetNameByID(26301), minimum = 930 },	--	Dwarven Cotton Gaskins of Striking
	{ name = AceLib.API.Items.GetNameByID(27192), minimum = 1060 },	--	Dwarven Cotton Jacket
	{ name = AceLib.API.Items.GetNameByID(26322), minimum = 930 },	--	Dwarven Cotton Petasos of Casting
	{ name = AceLib.API.Items.GetNameByID(27194), minimum = 1060 },	--	Dwarven Cotton Trousers
	{ name = AceLib.API.Items.GetNameByID(26304), minimum = 960 },	--	Dwarven Cotton Turban of Aiming
	{ name = AceLib.API.Items.GetNameByID(10806), minimum = 290 },	--	Hallowed Ramie Doublet of Aiming
	{ name = AceLib.API.Items.GetNameByID(10890), minimum = 290 },	--	Hallowed Ramie Doublet of Healing
	{ name = AceLib.API.Items.GetNameByID(10953), minimum = 290 },	--	Hallowed Ramie Gaskins of Casting
	{ name = AceLib.API.Items.GetNameByID(10911), minimum = 290 },	--	Hallowed Ramie Gaskins of Healing
	{ name = AceLib.API.Items.GetNameByID(10820), minimum = 270 },	--	Hallowed Ramie Sash of Aiming
	{ name = AceLib.API.Items.GetNameByID(10946), minimum = 270 },	--	Hallowed Ramie Sash of Casting
	{ name = AceLib.API.Items.GetNameByID(11961), minimum = 220 },	--	Holy Rainbow Coatee
	{ name = AceLib.API.Items.GetNameByID(11966), minimum = 190 },	--	Holy Rainbow Gloves
	{ name = AceLib.API.Items.GetNameByID(11984), minimum = 190 },	--	Holy Rainbow Hat
	{ name = AceLib.API.Items.GetNameByID(10797), minimum = 160 },	--	Holy Rainbow Hat of Aiming
	{ name = AceLib.API.Items.GetNameByID(10951), minimum = 160 },	--	Holy Rainbow Sarouel of Casting
	{ name = AceLib.API.Items.GetNameByID(10699), minimum = 160 },	--	Holy Rainbow Sarouel of Fending
	{ name = AceLib.API.Items.GetNameByID(10741), minimum = 160 },	--	Holy Rainbow Sarouel of Maiming
	{ name = AceLib.API.Items.GetNameByID(10846), minimum = 190 },	--	Holy Rainbow Shirt of Scouting
	{ name = AceLib.API.Items.GetNameByID(10762), minimum = 190 },	--	Holy Rainbow Shirt of Striking
	{ name = AceLib.API.Items.GetNameByID(11979), minimum = 220 },	--	Holy Rainbow Shoes
	{ name = AceLib.API.Items.GetNameByID(25827), minimum = 640 },	--	Iridescent Bottoms of Aiming
	{ name = AceLib.API.Items.GetNameByID(25845), minimum = 640 },	--	Iridescent Bottoms of Casting
	{ name = AceLib.API.Items.GetNameByID(25839), minimum = 640 },	--	Iridescent Bottoms of Healing
	{ name = AceLib.API.Items.GetNameByID(25821), minimum = 640 },	--	Iridescent Bottoms of Striking
	{ name = AceLib.API.Items.GetNameByID(25830), minimum = 570 },	--	Iridescent Hat of Scouting
	{ name = AceLib.API.Items.GetNameByID(25812), minimum = 570 },	--	Iridescent Hood of Maiming
	{ name = AceLib.API.Items.GetNameByID(25843), minimum = 640 },	--	Iridescent Top of Casting
	{ name = AceLib.API.Items.GetNameByID(25837), minimum = 640 },	--	Iridescent Top of Healing
	{ name = AceLib.API.Items.GetNameByID(19632), minimum = 510 },	--	Kudzu Cap of Crafting
	{ name = AceLib.API.Items.GetNameByID(18402), minimum = 470 },	--	Kudzu Corset of Casting
	{ name = AceLib.API.Items.GetNameByID(18391), minimum = 470 },	--	Kudzu Hat of Healing
	{ name = AceLib.API.Items.GetNameByID(18400), minimum = 470 },	--	Kudzu Longkilt of Casting
	{ name = AceLib.API.Items.GetNameByID(18364), minimum = 470 },	--	Kudzu Longkilt of Fending
	{ name = AceLib.API.Items.GetNameByID(18392), minimum = 510 },	--	Kudzu Robe of Healing
	{ name = AceLib.API.Items.GetNameByID(18388), minimum = 470 },	--	Kudzu Trousers of Scouting
	{ name = AceLib.API.Items.GetNameByID(18380), minimum = 510 },	--	Kudzu Tunic of Aiming
	{ name = AceLib.API.Items.GetNameByID(26129), minimum = 900 },	--	Ovim Wool Bottoms of Fending
	{ name = AceLib.API.Items.GetNameByID(26139), minimum = 900 },	--	Ovim Wool Coat of Striking
	{ name = AceLib.API.Items.GetNameByID(27184), minimum = 900 },	--	Ovim Wool Gaskins of Crafting
	{ name = AceLib.API.Items.GetNameByID(27189), minimum = 900 },	--	Ovim Wool Gaskins of Gathering
	{ name = AceLib.API.Items.GetNameByID(26151), minimum = 830 },	--	Ovim Wool Jacket of Scouting
	{ name = AceLib.API.Items.GetNameByID(26159), minimum = 830 },	--	Ovim Wool Skirt of Healing
	{ name = AceLib.API.Items.GetNameByID(26163), minimum = 830 },	--	Ovim Wool Tunic of Casting
	{ name = AceLib.API.Items.GetNameByID(26144), minimum = 830 },	--	Ovim Wool Ushanka of Aiming
	{ name = AceLib.API.Items.GetNameByID(25979), minimum = 770 },	--	Pixie Cotton Acton of Striking
	{ name = AceLib.API.Items.GetNameByID(25987), minimum = 770 },	--	Pixie Cotton Brais of Aiming
	{ name = AceLib.API.Items.GetNameByID(25993), minimum = 770 },	--	Pixie Cotton Brais of Scouting
	{ name = AceLib.API.Items.GetNameByID(27174), minimum = 700 },	--	Pixie Cotton Breeches of Crafting
	{ name = AceLib.API.Items.GetNameByID(25981), minimum = 770 },	--	Pixie Cotton Culottes of Striking
	{ name = AceLib.API.Items.GetNameByID(27171), minimum = 700 },	--	Pixie Cotton Hat of Crafting
	{ name = AceLib.API.Items.GetNameByID(25996), minimum = 700 },	--	Pixie Cotton Hood of Healing
	{ name = AceLib.API.Items.GetNameByID(27211), minimum = 770 },	--	Pixie Cotton Sash
	{ name = AceLib.API.Items.GetNameByID(10761), minimum = 130 },	--	Rainbow Bolero of Striking
	{ name = AceLib.API.Items.GetNameByID(10796), minimum = 110 },	--	Rainbow Cap of Aiming
	{ name = AceLib.API.Items.GetNameByID(10922), minimum = 110 },	--	Rainbow Cap of Casting
	{ name = AceLib.API.Items.GetNameByID(10852), minimum = 110 },	--	Rainbow Halfgloves of Scouting
	{ name = AceLib.API.Items.GetNameByID(11012), minimum = 130 },	--	Rainbow Ribbon of Aiming
	{ name = AceLib.API.Items.GetNameByID(10964), minimum = 130 },	--	Rainbow Ribbon of Fending
	{ name = AceLib.API.Items.GetNameByID(10901), minimum = 110 },	--	Rainbow Sash of Healing
	{ name = AceLib.API.Items.GetNameByID(10908), minimum = 130 },	--	Rainbow Slops of Healing
	{ name = AceLib.API.Items.GetNameByID(12590), minimum = 230 },	--	Ramie Cloth
	{ name = AceLib.API.Items.GetNameByID(11962), minimum = 270 },	--	Ramie Doublet of Crafting
	{ name = AceLib.API.Items.GetNameByID(10938), minimum = 220 },	--	Ramie Halfgloves of Casting
	{ name = AceLib.API.Items.GetNameByID(10990), minimum = 220 },	--	Ramie Ribbon of Slaying
	{ name = AceLib.API.Items.GetNameByID(10889), minimum = 240 },	--	Ramie Robe of Healing
	{ name = AceLib.API.Items.GetNameByID(10952), minimum = 240 },	--	Ramie Tonban of Casting
	{ name = AceLib.API.Items.GetNameByID(10826), minimum = 240 },	--	Ramie Trousers of Aiming
	{ name = AceLib.API.Items.GetNameByID(12003), minimum = 270 },	--	Ramie Trousers of Gathering
	{ name = AceLib.API.Items.GetNameByID(11957), minimum = 240 },	--	Ramie Turban of Crafting
	{ name = AceLib.API.Items.GetNameByID(18217), minimum = 370 },	--	Ruby Cotton Bandana of Striking
	{ name = AceLib.API.Items.GetNameByID(19625), minimum = 420 },	--	Ruby Cotton Bottoms
	{ name = AceLib.API.Items.GetNameByID(19623), minimum = 420 },	--	Ruby Cotton Coatee
	{ name = AceLib.API.Items.GetNameByID(18224), minimum = 420 },	--	Ruby Cotton Gambison
	{ name = AceLib.API.Items.GetNameByID(18230), minimum = 420 },	--	Ruby Cotton Gilet of Scouting
	{ name = AceLib.API.Items.GetNameByID(18244), minimum = 420 },	--	Ruby Cotton Longkilt
	{ name = AceLib.API.Items.GetNameByID(18246), minimum = 370 },	--	Ruby Cotton Sash of Casting
	{ name = AceLib.API.Items.GetNameByID(18238), minimum = 420 },	--	Ruby Cotton Smalls
	{ name = AceLib.API.Items.GetNameByID(18554), minimum = 610 },	--	Serge Gambison of Casting
	{ name = AceLib.API.Items.GetNameByID(18535), minimum = 560 },	--	Serge Hat of Aiming
	{ name = AceLib.API.Items.GetNameByID(18553), minimum = 560 },	--	Serge Hat of Casting
	{ name = AceLib.API.Items.GetNameByID(19657), minimum = 660 },	--	Serge Hood
	{ name = AceLib.API.Items.GetNameByID(18538), minimum = 610 },	--	Serge Hose of Aiming
	{ name = AceLib.API.Items.GetNameByID(18550), minimum = 610 },	--	Serge Hose of Healing
	{ name = AceLib.API.Items.GetNameByID(19652), minimum = 660 },	--	Serge Knit Cap
	{ name = AceLib.API.Items.GetNameByID(19658), minimum = 660 },	--	Serge Poncho
	{ name = AceLib.API.Items.GetNameByID(19645), minimum = 610 },	--	Serge Sarouel of Crafting
	{ name = AceLib.API.Items.GetNameByID(19650), minimum = 610 },	--	Serge Sarouel of Gathering
	{ name = AceLib.API.Items.GetNameByID(19659), minimum = 660 },	--	Serge Work Gloves
	{ name = AceLib.API.Items.GetNameByID(19987), minimum = 625 },	--	Twinsilk
	{ name = AceLib.API.Items.GetNameByID(18942), minimum = 650 },	--	Twinsilk Corset of Healing
	{ name = AceLib.API.Items.GetNameByID(18709), minimum = 630 },	--	Twinsilk Hood of Casting
	{ name = AceLib.API.Items.GetNameByID(18703), minimum = 630 },	--	Twinsilk Hood of Healing
	{ name = AceLib.API.Items.GetNameByID(18714), minimum = 630 },	--	Twinsilk Sash of Casting
	{ name = AceLib.API.Items.GetNameByID(18694), minimum = 650 },	--	Twinsilk Slops of Aiming
	{ name = AceLib.API.Items.GetNameByID(18712), minimum = 650 },	--	Twinsilk Slops of Casting
	{ name = AceLib.API.Items.GetNameByID(19660), minimum = 660 },	--	Twinsilk Slops of Gathering
	{ name = AceLib.API.Items.GetNameByID(18706), minimum = 650 },	--	Twinsilk Slops of Healing
	{ name = AceLib.API.Items.GetNameByID(19653), minimum = 660 },	--	Twinsilk Suspenders

	-- Alchemist
	{ name = AceLib.API.Items.GetNameByID(10652), minimum = 110 },	--	Archaeoskin Codex
	{ name = AceLib.API.Items.GetNameByID(10646), minimum = 110 },	--	Archaeoskin Grimoire
	{ name = AceLib.API.Items.GetNameByID(25958), minimum = 700 },	--	Bluespirit Grimoire
	{ name = AceLib.API.Items.GetNameByID(10650), minimum = 320 },	--	Book of Aurum Regis
	{ name = AceLib.API.Items.GetNameByID(19883), minimum = 510 },	--	Commanding Craftsman's Tea
	{ name = AceLib.API.Items.GetNameByID(19882), minimum = 470 },	--	Competent Craftsman's Tea
	{ name = AceLib.API.Items.GetNameByID(27955), minimum = 500 },	--	Crimson Firesand
	{ name = AceLib.API.Items.GetNameByID(27959), minimum = 900 },	--	Cunning Craftsman's Syrup
	{ name = AceLib.API.Items.GetNameByID(10654), minimum = 240 },	--	Dhalmelskin Codex
	{ name = AceLib.API.Items.GetNameByID(10648), minimum = 240 },	--	Dhalmelskin Grimoire
	{ name = AceLib.API.Items.GetNameByID(12623), minimum = 320 },	--	Draconian Potion of Dexterity
	{ name = AceLib.API.Items.GetNameByID(12625), minimum = 350 },	--	Draconian Potion of Intelligence
	{ name = AceLib.API.Items.GetNameByID(12626), minimum = 350 },	--	Draconian Potion of Mind
	{ name = AceLib.API.Items.GetNameByID(12622), minimum = 320 },	--	Draconian Potion of Strength
	{ name = AceLib.API.Items.GetNameByID(12624), minimum = 350 },	--	Draconian Potion of Vitality
	{ name = AceLib.API.Items.GetNameByID(10655), minimum = 290 },	--	Dragonskin Codex
	{ name = AceLib.API.Items.GetNameByID(10649), minimum = 290 },	--	Dragonskin Grimoire
	{ name = AceLib.API.Items.GetNameByID(26278), minimum = 930 },	--	Dwarven Mythril Grimoire
	{ name = AceLib.API.Items.GetNameByID(12603), minimum = 360 },	--	Enchanted Aurum Regis Ink
	{ name = AceLib.API.Items.GetNameByID(27781), minimum = 930 },	--	Enchanted Dimythrite Ink
	{ name = AceLib.API.Items.GetNameByID(12602), minimum = 250 },	--	Enchanted Hardsilver Ink
	{ name = AceLib.API.Items.GetNameByID(27772), minimum = 700 },	--	Enchanted Manasilver Ink
	{ name = AceLib.API.Items.GetNameByID(19903), minimum = 625 },	--	Enchanted Palladium Ink
	{ name = AceLib.API.Items.GetNameByID(18668), minimum = 630 },	--	Gazelleskin Codex
	{ name = AceLib.API.Items.GetNameByID(18667), minimum = 630 },	--	Gazelleskin Grimoire
	{ name = AceLib.API.Items.GetNameByID(25799), minimum = 570 },	--	Gliderskin Codex
	{ name = AceLib.API.Items.GetNameByID(27770), minimum = 640 },	--	Grade 1 Intelligence Alkahest
	{ name = AceLib.API.Items.GetNameByID(27771), minimum = 640 },	--	Grade 1 Mind Alkahest
	{ name = AceLib.API.Items.GetNameByID(27767), minimum = 640 },	--	Grade 1 Strength Alkahest
	{ name = AceLib.API.Items.GetNameByID(27769), minimum = 640 },	--	Grade 1 Vitality Alkahest
	{ name = AceLib.API.Items.GetNameByID(27765), minimum = 500 },	--	Growth Formula Iota
	{ name = AceLib.API.Items.GetNameByID(18200), minimum = 370 },	--	Gyuki Leather Codex
	{ name = AceLib.API.Items.GetNameByID(18199), minimum = 370 },	--	Gyuki Leather Grimoire
	{ name = AceLib.API.Items.GetNameByID(10637), minimum = 270 },	--	Hallowed Chestnut Wand
	{ name = AceLib.API.Items.GetNameByID(10635), minimum = 160 },	--	Holy Cedar Wand
	{ name = AceLib.API.Items.GetNameByID(19887), minimum = 660 },	--	Infusion of Dexterity
	{ name = AceLib.API.Items.GetNameByID(19889), minimum = 660 },	--	Infusion of Intelligence
	{ name = AceLib.API.Items.GetNameByID(19890), minimum = 650 },	--	Infusion of Mind
	{ name = AceLib.API.Items.GetNameByID(19886), minimum = 660 },	--	Infusion of Strength
	{ name = AceLib.API.Items.GetNameByID(19888), minimum = 650 },	--	Infusion of Vitality
	{ name = AceLib.API.Items.GetNameByID(18044), minimum = 320 },	--	Koppranickel Codex
	{ name = AceLib.API.Items.GetNameByID(18043), minimum = 320 },	--	Koppranickel Index
	{ name = AceLib.API.Items.GetNameByID(18512), minimum = 610 },	--	Marid Leather Codex
	{ name = AceLib.API.Items.GetNameByID(18511), minimum = 610 },	--	Marid Leather Grimoire
	{ name = AceLib.API.Items.GetNameByID(10651), minimum = 400 },	--	Noble Gold
	{ name = AceLib.API.Items.GetNameByID(10657), minimum = 400 },	--	Noble's Codex
	{ name = AceLib.API.Items.GetNameByID(10656), minimum = 320 },	--	Noble's Picatrix
	{ name = AceLib.API.Items.GetNameByID(19885), minimum = 370 },	--	Potent Spiritbond Potion
	{ name = AceLib.API.Items.GetNameByID(27777), minimum = 830 },	--	Refined Natron
	{ name = AceLib.API.Items.GetNameByID(18356), minimum = 510 },	--	Tigerskin Codex
	{ name = AceLib.API.Items.GetNameByID(18355), minimum = 510 },	--	Tigerskin Grimoire
	{ name = AceLib.API.Items.GetNameByID(27787), minimum = 1060 },	--	Tincture of Dexterity
	{ name = AceLib.API.Items.GetNameByID(27789), minimum = 1060 },	--	Tincture of Intelligence
	{ name = AceLib.API.Items.GetNameByID(27786), minimum = 1060 },	--	Tincture of Strength
	{ name = AceLib.API.Items.GetNameByID(10653), minimum = 160 },	--	Wyvernskin Codex
	{ name = AceLib.API.Items.GetNameByID(10647), minimum = 160 },	--	Wyvernskin Grimoire
	{ name = AceLib.API.Items.GetNameByID(26119), minimum = 900 },	--	Zonureskin Codex

	-- Culinarian
	{ name = AceLib.API.Items.GetNameByID(27860), minimum = 700 },	--	Baguette
	{ name = AceLib.API.Items.GetNameByID(27869), minimum = 830 },	--	Baked Megapiranha
	{ name = AceLib.API.Items.GetNameByID(12861), minimum = 160 },	--	Baked Onion Soup
	{ name = AceLib.API.Items.GetNameByID(12856), minimum = 320 },	--	Baked Pipira Pira
	{ name = AceLib.API.Items.GetNameByID(19811), minimum = 320 },	--	Baklava
	{ name = AceLib.API.Items.GetNameByID(12862), minimum = 220 },	--	Beet Soup
	{ name = AceLib.API.Items.GetNameByID(27876), minimum = 960 },	--	Blood Bouillabaisse
	{ name = AceLib.API.Items.GetNameByID(27864), minimum = 770 },	--	Blood Tomato Salad
	{ name = AceLib.API.Items.GetNameByID(12892), minimum = 370 },	--	Birch Syrup
	{ name = AceLib.API.Items.GetNameByID(19823), minimum = 630 },	--	Boiled Amberjack Head
	{ name = AceLib.API.Items.GetNameByID(27858), minimum = 640 },	--	Broad Bean Salad
	{ name = AceLib.API.Items.GetNameByID(19809), minimum = 370 },	--	Buckwheat Tea
	{ name = AceLib.API.Items.GetNameByID(19828), minimum = 370 },	--	Charred Charr
	{ name = AceLib.API.Items.GetNameByID(19814), minimum = 650 },	--	Chirashi-zushi
	{ name = AceLib.API.Items.GetNameByID(12864), minimum = 400 },	--	Clam Chowder
	{ name = AceLib.API.Items.GetNameByID(12858), minimum = 320 },	--	Cockatrice Meatballs
	{ name = AceLib.API.Items.GetNameByID(19833), minimum = 470 },	--	Crab Croquette
	{ name = AceLib.API.Items.GetNameByID(12860), minimum = 400 },	--	Deep-fried Okeanis
	{ name = AceLib.API.Items.GetNameByID(12869), minimum = 290 },	--	Dhalmel Fricassee
	{ name = AceLib.API.Items.GetNameByID(12867), minimum = 220 },	--	Dhalmel Gratin
	{ name = AceLib.API.Items.GetNameByID(19807), minimum = 630 },	--	Doman Tea
	{ name = AceLib.API.Items.GetNameByID(19820), minimum = 610 },	--	Egg Foo Young
	{ name = AceLib.API.Items.GetNameByID(12863), minimum = 270 },	--	Emerald Soup
	{ name = AceLib.API.Items.GetNameByID(27874), minimum = 930 },	--	Espresso con Panna
	{ name = AceLib.API.Items.GetNameByID(12845), minimum = 130 },	--	Fig Bavarois
	{ name = AceLib.API.Items.GetNameByID(19835), minimum = 610 },	--	Fish Stew
	{ name = AceLib.API.Items.GetNameByID(12843), minimum = 320 },	--	Frozen Spirits
	{ name = AceLib.API.Items.GetNameByID(19831), minimum = 510 },	--	Gameni
	{ name = AceLib.API.Items.GetNameByID(27839), minimum = 570 },	--	Garden Beet Sugar
	{ name = AceLib.API.Items.GetNameByID(27842), minimum = 700 },	--	Golden Honey
	{ name = AceLib.API.Items.GetNameByID(27859), minimum = 640 },	--	Grilled Platinum Bream
	{ name = AceLib.API.Items.GetNameByID(27853), minimum = 500 },	--	Grilled Rail
	{ name = AceLib.API.Items.GetNameByID(12855), minimum = 220 },	--	Grilled Sweetfish
	{ name = AceLib.API.Items.GetNameByID(19822), minimum = 420 },	--	Grilled Turban
	{ name = AceLib.API.Items.GetNameByID(12850), minimum = 190 },	--	Ishgardian Muffin
	{ name = AceLib.API.Items.GetNameByID(12842), minimum = 190 },	--	Ishgardian Tea
	{ name = AceLib.API.Items.GetNameByID(27881), minimum = 1060 },	--	Jellie Harcot
	{ name = AceLib.API.Items.GetNameByID(19819), minimum = 650 },	--	Jerked Jhammel
	{ name = AceLib.API.Items.GetNameByID(19830), minimum = 660 },	--	Jhammel Moussaka
	{ name = AceLib.API.Items.GetNameByID(12849), minimum = 240 },	--	Kaiser Roll
	{ name = AceLib.API.Items.GetNameByID(19838), minimum = 370 },	--	Kasha
	{ name = AceLib.API.Items.GetNameByID(27880), minimum = 1060 },	--	Lemonade
	{ name = AceLib.API.Items.GetNameByID(12851), minimum = 350 },	--	Liver-cheese Sandwich
	{ name = AceLib.API.Items.GetNameByID(19808), minimum = 320 },	--	Loquat Juice
	{ name = AceLib.API.Items.GetNameByID(12847), minimum = 350 },	--	Marron Glace
	{ name = AceLib.API.Items.GetNameByID(19829), minimum = 650 },	--	Miso Dengaku
	{ name = AceLib.API.Items.GetNameByID(19834), minimum = 470 },	--	Miso Soup with Tofu
	{ name = AceLib.API.Items.GetNameByID(27875), minimum = 930 },	--	Mist Spinach Saute
	{ name = AceLib.API.Items.GetNameByID(12854), minimum = 400 },	--	Morel Salad
	{ name = AceLib.API.Items.GetNameByID(27868), minimum = 830 },	--	Mushroom Skewer
	{ name = AceLib.API.Items.GetNameByID(19839), minimum = 560 },	--	Nomad Meat Pie
	{ name = AceLib.API.Items.GetNameByID(27863), minimum = 770 },	--	Nut Bake
	{ name = AceLib.API.Items.GetNameByID(19821), minimum = 625 },	--	Onigara-yaki
	{ name = AceLib.API.Items.GetNameByID(27879), minimum = 1060 },	--	Ovim Cordon Bleu
	{ name = AceLib.API.Items.GetNameByID(27882), minimum = 1060 },	--	Oysters on the Half Shell
	{ name = AceLib.API.Items.GetNameByID(19813), minimum = 610 },	--	Persimmon Pudding
	{ name = AceLib.API.Items.GetNameByID(27862), minimum = 700 },	--	Pixie Apple Pie
	{ name = AceLib.API.Items.GetNameByID(27871), minimum = 900 },	--	Popoto au Gratin
	{ name = AceLib.API.Items.GetNameByID(19816), minimum = 420 },	--	Popoto Soba
	{ name = AceLib.API.Items.GetNameByID(27854), minimum = 500 },	--	Purple Carrot Juice
	{ name = AceLib.API.Items.GetNameByID(27867), minimum = 830 },	--	Roast Ovim
	{ name = AceLib.API.Items.GetNameByID(12859), minimum = 290 },	--	Royal Eggs
	{ name = AceLib.API.Items.GetNameByID(12853), minimum = 190 },	--	Sauteed Porcini
	{ name = AceLib.API.Items.GetNameByID(13743), minimum = 270 },	--	Sesame Cookie
	{ name = AceLib.API.Items.GetNameByID(19817), minimum = 510 },	--	Shorlog
	{ name = AceLib.API.Items.GetNameByID(12846), minimum = 220 },	--	Sohm Al Tart
	{ name = AceLib.API.Items.GetNameByID(27840), minimum = 640 },	--	Squid Ink
	{ name = AceLib.API.Items.GetNameByID(19824), minimum = 660 },	--	Steamed Grouper
	{ name = AceLib.API.Items.GetNameByID(19832), minimum = 560 },	--	Steppe Salad
	{ name = AceLib.API.Items.GetNameByID(19827), minimum = 660 },	--	Stewed River Bream
	{ name = AceLib.API.Items.GetNameByID(12866), minimum = 160 },	--	Stuffed Cabbage Rolls
	{ name = AceLib.API.Items.GetNameByID(12868), minimum = 400 },	--	Stuffed Chysahl
	{ name = AceLib.API.Items.GetNameByID(19825), minimum = 510 },	--	Sweet and Sour Frogs' Legs
	{ name = AceLib.API.Items.GetNameByID(19826), minimum = 560 },	--	Tempura Platter
	{ name = AceLib.API.Items.GetNameByID(27841), minimum = 700 },	--	Upland Wheat Flour
	{ name = AceLib.API.Items.GetNameByID(19837), minimum = 560 },	--	Warrior's Stew
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
		if gCraftTeaTypeIndex == 2 or gCraftTeaTypeIndex == 5 then
			-- "Cunning Craftsman's Syrup",
			local teahq, action = GetItem(1027959)
			if (teahq and action and not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(27959)
			if (tea and action and not action.isoncd) then
				return true, tea
			end		
			-- "Cunning Craftsman's Tea",
			local teahq, action = GetItem(1019884)
			if (teahq and action and not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(19884)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
		end
		if gCraftTeaTypeIndex == 3 or gCraftTeaTypeIndex == 5 then
			-- "Commanding Craftsman's Syrup",
			local teahq, action = GetItem(1027958)
			if (teahq and action and not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(27958)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
			-- "Commanding Craftsman's Tea",
			local teahq, action = GetItem(1019883)
			if (teahq and action and not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(19883)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
		end
		if gCraftTeaTypeIndex == 4 or gCraftTeaTypeIndex == 5 then
			-- "Competent Craftsman's Syrup",
			local teahq, action = GetItem(1027957)
			if (teahq and action and  not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(27957)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
			-- "Competent Craftsman's Tea",
			local teahq, action = GetItem(1019882)
			if (teahq and action and  not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(19882)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
		end
	end
	
	return false, nil
end

c_waitlog = inheritsFrom( ml_cause )
e_waitlog = inheritsFrom( ml_effect )
function c_waitlog:evaluate()
	if (IsControlOpen("RecipeNote")) then
		local logData = GetControlData("RecipeNote")
		if (logData and IsNull(logData.class,-1) < 0) then
			ml_global_information.Await(1000)
			return true
		end
	end
		
	return false
end

function e_waitlog:execute()
end

c_closelog = inheritsFrom( ml_cause )
e_closelog = inheritsFrom( ml_effect )
function c_closelog:evaluate()
	if (ml_task_hub:CurrentTask().allowWindowOpen ) then
		return false
	end
	if (IsControlOpen("Synthesis") or IsControlOpen("SynthesisSimple") or IsControlOpen("SynthesisSimpleDialog") or IsControlOpen("SelectYesno") or IsControlOpen("SelectYesNoCountItem") or MIsLoading() or IsControlOpen("Talk") or IsControlOpen("Request")) then	
		--d("Cannot clear inventory, basic reasons.")
		return false
	end
	if (IsControlOpen("RecipeNote")) then
		if (IsInventoryFull()) then
			return true
		end
	end
		
	return false
end

function e_closelog:execute()
	if (IsControlOpen("RecipeNote")) then
		ffxiv_craft.ToggleCraftingLog()
		ml_task_hub:CurrentTask().allowWindowOpen = true
	end
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
			
			local getcounts = {}
			getcounts[itemid] = true
			getcounts[itemid + 1000000] = true
			getcounts[itemid + 500000] = true
			
			local getcountsorted = {}
			for itemid,_ in pairs(getcounts) do
				table.insert(getcountsorted,itemid)
			end
			
			local itemcounts = ItemCounts(getcountsorted)
			
			local itemcountnorm = IsNull(itemcounts[itemid].count,0)
			local itemcountHQ = IsNull(itemcounts[itemid + 1000000].count,0)
			local itemcountCollectable = IsNull(itemcounts[itemid + 500000].count,0)
			local itemcount = itemcountnorm + itemcountHQ + itemcountCollectable
			
			if (requireCollect) then
				itemcount = itemcountCollectable
			elseif (requireHQ) then
				itemcount = itemcountHQ
			elseif (countHQ) then
				itemcount = itemcountnorm + itemcountHQ
			end
			
			local taskDetails = ml_task_hub:CurrentTask()
			local canCraft,maxAmount = AceLib.API.Items.CanCraft(recipe.id,taskDetails.useHQ,taskDetails)
			if (not canCraft) then
				cd("[CraftLimit]: We can no longer craft this item, complete the order.",3)
				return true
			else
				if (requiredItems > 0 and itemcount >= (requiredItems + startingCount))	then
					cd("[CraftLimit]: Current item count ["..tostring(itemcount).."] is more than ["..tostring(requiredItems + startingCount).."], no need to start more.",3)
					return true
				end
			end
			
			
		elseif gCraftMarkerOrProfileIndex == 2 then
			cd("Max Items = "..tostring(ml_task_hub:CurrentTask().maxItems))
			cd("Craft Attempts = "..tostring(ml_task_hub:CurrentTask().itemsCrafted))
			if ((ml_task_hub:CurrentTask().maxItems > 0 and ml_task_hub:CurrentTask().itemsCrafted == ml_task_hub:CurrentTask().maxItems) or 
				ml_task_hub:CurrentTask().attemptedStarts > 5) then
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
		local key = ml_task_hub:CurrentTask().key
		ffxiv_craft.orders[key].completed = true
		ffxiv_craft.tracking.measurementDelay = Now()
		
		cd("[CraftLimit]: Setting order with recipe ID ["..tostring(recipeid).."] to complete.",3)
		ml_task_hub:CurrentTask().completed = true
	end
	if gCraftMarkerOrProfileIndex == 2 then
		if (IsControlOpen("RecipeNote")) then
			ffxiv_craft.ToggleCraftingLog()
			ml_task_hub:CurrentTask().allowWindowOpen = true
		end
		ml_global_information:ToggleRun()
	end
end

c_opencraftwnd = inheritsFrom( ml_cause )
e_opencraftwnd  = inheritsFrom( ml_effect )
function c_opencraftwnd:evaluate()
	if (MIsCasting() or not ml_task_hub:CurrentTask().allowWindowOpen or MIsLocked()) then
		return false
	end
	
	if (not IsControlOpen("Synthesis") and not IsControlOpen("SynthesisSimple") and not IsControlOpen("SynthesisSimpleDialog") and not IsControlOpen("RecipeNote")) then
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
e_startcraft.blocktime = 0
function c_startcraft:evaluate()
	e_startcraft.blocktime = 0
	if (not ffxiv_craft.IsCrafting() and (IsControlOpen("RecipeNote") or IsControlOpen("SynthesisSimpleDialog"))) then
		
		if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
			local recipe = ml_task_hub:CurrentTask().recipe
			local jobRequired = recipe.class + 8
			
			if (Player.job == jobRequired) then
				local minCP = ml_task_hub:CurrentTask().requiredCP
				local itemid = ml_task_hub:CurrentTask().itemid
				local requireHQ = ml_task_hub:CurrentTask().requireHQ
				local requireCollect = ml_task_hub:CurrentTask().requireCollect
				local countHQ = ml_task_hub:CurrentTask().countHQ
				local canCraft,maxAmount = AceLib.API.Items.CanCraft(recipe.id,ml_task_hub:CurrentTask().useHQ)
				
				local getcounts = {}
				getcounts[itemid] = true
				getcounts[itemid + 1000000] = true
				getcounts[itemid + 500000] = true
				
				local getcountsorted = {}
				for itemid,_ in pairs(getcounts) do
					table.insert(getcountsorted,itemid)
				end
				
				local itemcounts = ItemCounts(getcountsorted)
				
				local itemcountnorm = IsNull(itemcounts[itemid].count,0)
				local itemcountHQ = IsNull(itemcounts[itemid + 1000000].count,0)
				local itemcountCollectable = IsNull(itemcounts[itemid + 500000].count,0)
				local itemcount = itemcountnorm + itemcountHQ + itemcountCollectable
				
				
				if (requireCollect) then
					itemcount = itemcountCollectable
				elseif (requireHQ) then
					itemcount = itemcountHQ
				elseif (countHQ) then
					itemcount = itemcountnorm + itemcountHQ
				end
					
				local requiredItems = ml_task_hub:CurrentTask().requiredItems
				local startingCount = ml_task_hub:CurrentTask().startingCount 
				
				local quickCraft = ml_task_hub:CurrentTask().useQuick
				if (canCraft or ml_task_hub:CurrentTask().ifNecessary) then
					if (requiredItems == 0 or (requiredItems > 0 and itemcount < (requiredItems + startingCount))) then
						if (Player.cp.max >= minCP) or (quickCraft and not requireCollect) then
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
							if (gCraftUseHQBackup) then
								if ((ingredient.selectedhq + ingredient.selectednq) < ingredient.needed) then
									if ((ingredient.inventorynq + ingredient.inventoryhq) >= ingredient.needed) then
										d("[Craft]: This craft requires use of ["..tostring((ingredient.needed - ingredient.inventorynq)).."] HQ of ["..ingredient.name.."] to have enough materials.")
										Crafting:SetCraftingMats(i-1,(ingredient.needed - ingredient.inventorynq))
										e_startcraft.blocktime = math.random(150,300)
										return true
									else
										ffxiv_dialog_manager.IssueStopNotice("Need More Items", "Cannot craft this item, not enough materials.", "okonly")
										return false
									end
								end
							else
								if (ingredient.needed <= ingredient.inventoryhq and (ingredient.selectedhq < ingredient.needed)) then
									d("[Craft]: This craft prefers the use of ["..tostring(ingredient.needed).."] HQ of ["..ingredient.name.."], per options.")
									Crafting:SetCraftingMats(i-1,ingredient.needed)
									e_startcraft.blocktime = math.random(150,300)
									return true
								elseif (ingredient.needed > ingredient.inventoryhq) then
									if (ingredient.selectedhq < ingredient.inventoryhq) then
										d("[Craft]: This craft will use ["..tostring(ingredient.needed).."] HQ of ["..ingredient.name.."], since we can't use 100% HQ.")
										Crafting:SetCraftingMats(i-1,ingredient.inventoryhq)
										e_startcraft.blocktime = math.random(150,300)
										return true
									elseif (ingredient.needed > (ingredient.selectednq + ingredient.selectedhq) and ingredient.needed <= (ingredient.inventoryhq + ingredient.inventorynq)) then -- ghetto fix, can't manually update nq mats atm
										--ml_global_information:ToggleRun()
										ffxiv_craft:ToggleCraftingLog()
										ml_task_hub:CurrentTask().allowWindowOpen = true
										return false
									end
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
			else
				d("[Craft]: Need to wait for materials control feedback.")
				return false
			end	
				
			if ( Crafting:CanCraftSelectedItem(ml_task_hub:CurrentTask().useQuick) ) then
				return true
			else 
				ml_task_hub:ThisTask().attemptedStarts = ml_task_hub:ThisTask().attemptedStarts + 1
			end
		end
	end	
	
    return false
end

function e_startcraft:execute()
	if (e_startcraft.blocktime > 0) then
		ml_global_information.Await(e_startcraft.blocktime)
		return
	end

	SkillMgr.prevSkillList = {}
	SkillMgr.tempPrevSkillList = {}
	
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local recipe = ml_task_hub:CurrentTask().recipe
		local itemid = ml_task_hub:CurrentTask().itemid
		local indexInfo = Crafting:GetSelectedCraftInfo(recipe.id)
		local skillProfile = ml_task_hub:CurrentTask().skillProfile
		local key = ml_task_hub:CurrentTask().key
		
		if (table.valid(indexInfo)) then
			if indexInfo.iscorrectindex ~= true then 
				d("Recipe phase 1, set to: ["..tostring(recipe.class)..","..tostring(recipe.page)..","..tostring(recipe.id).."].",3)
				Crafting:SetRecipe(recipe.class,recipe.page,recipe.id)
				ml_task_hub:CurrentTask().recipeSelected = true
				ffxiv_craft.tracking.lastSetRecipe = Now()
				ml_task_hub:CurrentTask().matsSet = false
				
				ml_global_information.Await(1000)
				return
			elseif (skillProfile ~= "" and gSkillProfile ~= skillProfile and skillProfile ~= GetString("none")) then
				if (SkillMgr.HasProfile(skillProfile)) then
					SkillMgr.UseProfile(skillProfile)
				end
				
				ml_global_information.Await(1000)
				return
			else
				if (not ml_task_hub:CurrentTask().matsSet) then
					local useHQ = ml_task_hub:CurrentTask().useHQ
					local ifNecessary = ml_task_hub:CurrentTask().ifNecessary
					local mats = Crafting:GetCraftingMats()
					if (table.valid(mats)) then
						if (useHQ) then
							for i = 1,6 do
								local ingredient = mats[i]
								if (ingredient) then
								
									local hqAmountMax = ml_task_hub:CurrentTask()["hq"..tostring(i)]
									if hqAmountMax > ingredient.needed then
										hqAmountMax = ingredient.needed
									end
									local hqAmountMin = ml_task_hub:CurrentTask()["hq"..tostring(i).."min"]
									if not ifNecessary then
										if ((ingredient.inventoryhq >= hqAmountMax) and (hqAmountMax >= hqAmountMin) and (ingredient.selectedhq < hqAmountMax)) then -- set max hq material
											d("[Craft]: Order is set to use Maximum ["..tostring(hqAmountMax).."] HQ of ["..ingredient.name.."].")
											Crafting:SetCraftingMats(i-1,hqAmountMax) -- set max
											ml_global_information.Await(math.random(150,300))
											return
										elseif ((ingredient.inventoryhq >= hqAmountMin) and (ingredient.inventoryhq < hqAmountMax) and (ingredient.selectedhq < ingredient.inventoryhq)) then -- set as much as currently possible
											d("[Craft]: Order is set use as much HQ as I Currently have of ["..tostring(ingredient.inventoryhq).."] HQ of ["..ingredient.name.."].")
											Crafting:SetCraftingMats(i-1,ingredient.inventoryhq) -- set what i have
											ml_global_information.Await(math.random(150,300))
											return
										elseif (ingredient.inventoryhq < hqAmountMin) then
											d("[Craft]: Stop crafting item, not enough HQ Items of ["..ingredient.name.."].")
											e_craftlimit:execute()
											return false
										elseif ((ingredient.selectedhq + ingredient.inventorynq) < ingredient.needed) then
											d("[Craft]: Stop crafting item, not enough ingrediends of ["..ingredient.name.."].")
											e_craftlimit:execute()
											return false
										end
									else
										if ((ingredient.selectedhq + ingredient.selectednq) < ingredient.needed) then
											if ((ingredient.inventorynq + ingredient.inventoryhq) >= ingredient.needed and ingredient.selectedhq < (ingredient.needed - ingredient.selectednq)) then
												d("[Craft]: Order is set to use HQ mats if necessary, need ["..tostring((ingredient.needed - ingredient.inventorynq)).."] of ["..ingredient.name.."].")
												Crafting:SetCraftingMats(i-1,(ingredient.needed - ingredient.inventorynq))
												ml_global_information.Await(math.random(150,300))
												return
											else
												d("[Craft]: Not enough materials including HQ.")
												e_craftlimit:execute()
												return false
											end
										end
									end
								end
							end
						end
						ml_task_hub:CurrentTask().matsSet = true
					else
						d("[Craft]: Need to wait for materials control feedback.")
						return false
					end				
				else
					if (Crafting:CanCraftSelectedItem(ml_task_hub:CurrentTask().useQuick)) then
						ml_task_hub:CurrentTask().failedAttempts = 0
						local usequick = ml_task_hub:CurrentTask().useQuick
						local requireCollect = ml_task_hub:CurrentTask().requireCollect
						if (usequick and not requireCollect) then
							local itemid = ml_task_hub:CurrentTask().itemid
							local canCraft,maxAmount = AceLib.API.Items.CanCraft(recipe.id,ml_task_hub:CurrentTask().useHQ)
							local wantedAmount = ml_task_hub:ThisTask().requiredItems
							local yield = AceLib.API.Items.GetRecipeDetails(recipe.id).yield
							local craftAmount = math.ceil(wantedAmount / yield)
							if (craftAmount > 0 and craftAmount <= (maxAmount / yield) and craftAmount <= 99) then
								if (IsControlOpen("SynthesisSimpleDialog")) then
									d("using control with craftamount :"..tostring(craftAmount))
									UseControlAction("SynthesisSimpleDialog","Synthesize",{craftAmount, ml_task_hub:CurrentTask().useHQ})
								else
									d("using quick synth again")
									UseControlAction("RecipeNote","QuickSynthesis",{craftAmount, ml_task_hub:CurrentTask().useHQ})
									ml_global_information.Await(1000, 5000, function () return (IsControlOpen("SynthesisSimpleDialog") and not IsControlOpen("RecipeNote")) end)
									return
								end
							else
								if ((maxAmount / yield) > 99) then
									if (IsControlOpen("SynthesisSimpleDialog")) then
										d("using control with 99 :"..tostring(craftAmount))
										UseControlAction("SynthesisSimpleDialog","Synthesize",{99, ml_task_hub:CurrentTask().useHQ})
									else
										UseControlAction("RecipeNote","QuickSynthesis",{craftAmount, ml_task_hub:CurrentTask().useHQ})
										ml_global_information.Await(1000, 5000, function () return (IsControlOpen("SynthesisSimpleDialog") and not IsControlOpen("RecipeNote")) end)
										return
									end
								else
									if (IsControlOpen("SynthesisSimpleDialog")) then
										d("using control with max yield :"..tostring(craftAmount))
										UseControlAction("SynthesisSimpleDialog","Synthesize",{(maxAmount / yield), ml_task_hub:CurrentTask().useHQ})
									else
										UseControlAction("RecipeNote","QuickSynthesis",{craftAmount, ml_task_hub:CurrentTask().useHQ})
										ml_global_information.Await(1000, 5000, function () return (IsControlOpen("SynthesisSimpleDialog") and not IsControlOpen("RecipeNote")) end)
										return
									end
								end
							end
							SkillMgr.newCraft = true
							ml_task_hub:CurrentTask().allowWindowOpen = false
							ml_global_information.Await(5000, function () return (IsControlOpen("SynthesisSimple") and not IsControlOpen("RecipeNote")) end)
							return true
						else
							UseControlAction("RecipeNote","Synthesize")	
							SkillMgr.newCraft = true
							ml_task_hub:CurrentTask().matsSet = false
							ml_task_hub:CurrentTask().allowWindowOpen = false
							ml_global_information.Await(5000, function () return (IsControlOpen("Synthesis") and not IsControlOpen("RecipeNote")) end)
							return true
						end
						return
					else
						if (ml_task_hub:CurrentTask().failedAttempts < 10) then
							d("[StartCraft]: We cannot craft anymore of item ["..tostring(recipe.id).."], but we will try a couple more times to be sure.",3)
							ml_task_hub:CurrentTask().failedAttempts = ml_task_hub:CurrentTask().failedAttempts + 1
							ml_task_hub:CurrentTask().matsSet = false
							ml_task_hub:CurrentTask().recipeSelected = false
							ml_global_information.Await(2500)
							return
						else
							cd("[StartCraft]: We cannot craft anymore of item ["..tostring(recipe.id).."].",3)
							ffxiv_craft.orders[key].completed = true
							ml_task_hub:CurrentTask().completed = true
						end
					end			
				end
			end
		end
	elseif gCraftMarkerOrProfileIndex ~= 1 then				
		UseControlAction("RecipeNote","Synthesize")	
		ml_task_hub:ThisTask().attemptedStarts = ml_task_hub:ThisTask().attemptedStarts + 1
		SkillMgr.newCraft = true
		ml_global_information.Await(5000, function () return (IsControlOpen("Synthesis") and not IsControlOpen("RecipeNote")) end)
		--ml_task_hub:CurrentTask().allowWindowOpen = false
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
		
		if Player.ismounted and not IsFlying() then
			cd("[PreCraftBuff]: Need to Dismount.",3)
			e_precraftbuff.activity = "dismount"
			e_precraftbuff.requiresLogClose = false
			return true
		end
		
		if (NeedsRepair()) then
			cd("[PreCraftBuff]: Need to repair.",3)
			e_precraftbuff.activity = "repair"
			e_precraftbuff.requiresLogClose = false
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
			ml_global_information.AwaitSuccess(5000, function () return Player.castinginfo.lastcastid == castid end)
		end	
	elseif (activity == "switchclass") then
		local recipe = ml_task_hub:CurrentTask().recipe
		local jobRequired = recipe.class + 8
		local gearset = _G["gGearset"..tostring(jobRequired)]
		d("[PreCraftBuff]: Attempting to switch to gearset ["..tostring(gearset).."].",3)
		local commandString = "/gearset change "..tostring(gearset)
		SendTextCommand(commandString)
		ml_global_information.Await(3000)
	elseif (activity == "usemanual") then
		local manual = activityItem
		if (manual and manual:IsReady(Player.id)) then
			manual:Cast(Player.id)
			ml_global_information.AwaitSuccess(2000, 4000, function () return HasBuff(Player.id, 46) end)
			return
		end
	elseif (activity == "usetea") then
		local tea = activityItem
		if (tea and tea:IsReady(Player.id)) then
			tea:Cast(Player.id)
			ml_global_information.AwaitSuccess(2000, 4000, function () return HasBuff(Player.id, 49) end)
			return
		end
	elseif (activity == "usecollect") then
		local collect = ActionList:Get(1,ffxiv_craft.collectors[Player.job])
		local hasCollect = HasBuffs(Player,"903")
		if (collect and collect:IsReady(Player.id)) then
			if (collect:Cast()) then
				if (not hasCollect) then
					ml_global_information.AwaitSuccess(2500, function () return HasBuff(Player.id,903) end)
				else
					ml_global_information.AwaitSuccess(2500, function () return MissingBuff(Player.id,903) end)
				end
			end
		end
	elseif (activity == "dismount") then
		Dismount()
		ml_global_information.AwaitSuccess(2000, 4000, function () return not Player.ismounted end)
	end
end

c_craftend = inheritsFrom( ml_cause )
e_craftend = inheritsFrom( ml_effect )
function c_craftend:evaluate()
	if (IsControlOpen("Synthesis")) then
		local synthData = GetControlData("Synthesis")
		if (synthData and synthData.progress == synthData.progressmax) then
			ml_global_information.AwaitSuccess(1000, 3000, function () return IsControlOpen("RecipeNote") end)
			return true
		end
	end
    return false
end
function e_craftend:execute()
end

c_craft = inheritsFrom( ml_cause )
e_craft = inheritsFrom( ml_effect )
function c_craft:evaluate()
	if ( ffxiv_craft.IsCrafting() ) then	
		if (IsControlOpen("Synthesis")) then
			local synthData = GetControlData("Synthesis")
			if (synthData and IsNull(synthData.itemid,0) ~= 0 and IsNull(synthData.name,"") ~= "") then
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
	local addonName = "SelectYesno"
	--if (ffxivminion.gameRegion == 3) then
		--addonName = "SelectYesNoCountItem"
	--end
	if (IsControlOpen("SelectYesNoItem") or IsControlOpen(addonName)) then
		local info = GetControlData(addonName)
		if (info and IsNull(info.collectability,-1) >= 0) then
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
				d("Cannot collect item ["..info.name.."], collectibility rating not approved.",2)
				UseControlAction(addonName,"No")
			else
				d("Attempting to collect item ["..info.name.."], collectibility rating approved.",2)
				UseControlAction(addonName,"Yes")
			end
			ml_global_information.Await(2000, 3000, function () return not IsControlOpen("Synthesis") end)						
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
	if (ml_task_hub:CurrentTask().quickTimer > 0 and TimeSince(ml_task_hub:CurrentTask().quickTimer) > 7000) then
		if (UseControlAction("SynthesisSimple","Quit")) then
			ml_task_hub:CurrentTask().quickTimer = 0
			ml_global_information.Await(6000)
			return true
		end
	end
	
	if (Player.action == 241 or Player.action == 248) then
		ml_task_hub:CurrentTask().quickTimer = Now()
	end
end

c_selectcraft = inheritsFrom( ml_cause )
e_selectcraft = inheritsFrom( ml_effect )
function c_selectcraft:evaluate()
	if ( ffxiv_craft.IsCrafting() ) then	
		return false
	end
	
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local orders = ffxiv_craft.orders
		for id,order in pairs(orders) do
			if (order.completed == nil) then
				cd("[SelectCraft]: Initializing the completion status for id ["..tostring(id).."].",3)
				orders[id].completed = false
			end
			if (order.completed == false and order.skip ~= true) then
				local canCraft,maxAmount = AceLib.API.Items.CanCraft(order.id,order.usehq)
				if (canCraft) or (order.ifnecessary) then
					cd("[SelectCraft]: Found an incomplete order ["..tostring(id).."], select a new craft.",3)
					return true
				else
					d("Can't Craft:"..tostring(order.name))
				end
			end
		end
		ffxiv_craft.ToggleCraftingLog()
		ffxiv_dialog_manager.IssueStopNotice("Nothing Craftable", "You cannot craft any of the items in the profile.", "okonly")
	elseif  gCraftMarkerOrProfileIndex ~= 1 then
		return true
	end
	return false
end
function e_selectcraft:execute()

	local newTask = ffxiv_task_craftitems.Create()
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local orders = ffxiv_craft.orders
		
		local foundSelection = false
		for id,order in spairs(orders) do
		
			if (not order.completed and not order.skip) then
				local canCraft,maxAmount = AceLib.API.Items.CanCraft(order.id,order.usehq)

				if (canCraft) or (order.ifnecessary) then
					d("new task = "..tostring(id))
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
					newTask.ifNecessary = order.ifnecessary
					cd("[SelectCraft]: Order HQ Status :"..tostring(order.usehq)..".",3)
					newTask.skillProfile = order.skillprofile
					newTask.key = id
					
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
	newinst.countHQ = true
	newinst.itemid = 0
	newinst.useQuick = false
	newinst.useCollect = false
	newinst.useHQ = false
	newinst.ifNecessary = false
	newinst.recipe = {}
	newinst.recipeSelected = false
	newinst.matsSet = false
	newinst.skillProfile = ""
	newinst.key = 0
	newinst.quickTimer = 0
	
	newinst.failedAttempts = 0
    
    return newinst
end

function ffxiv_task_craftitems:Init()
	local ke_badLog = ml_element:create( "BadLogState", c_waitlog, e_waitlog, 170 )
    self:add( ke_badLog, self.process_elements)

	local ke_closeLog = ml_element:create( "CloseLog", c_closelog, e_closelog, 160 )
    self:add( ke_closeLog, self.process_elements)
	
	local ke_craftend = ml_element:create( "CraftComplete", c_craftend, e_craftend, 61 )
    self:add(ke_craftend, self.process_elements)  
	
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
	if (IsControlOpen("RecipeNote")) then
		ffxiv_craft.ToggleCraftingLog()
		ml_task_hub:CurrentTask().allowWindowOpen = true
	end
	
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
		Settings.FFXIVMINION.gLastCraftProfiles = Settings.FFXIVMINION.gLastCraftProfiles
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
	
	--for i = 8,15 do
	--	_G["gGearset"..tostring(i)] = ffxivminion.GetSetting("gGearset"..tostring(i),0)
	--end
	
	gCraftOrderSelectIndex = 1
	gCraftOrderSelect = "CRP"
	gCraftCollectablePresets = ffxivminion.GetSetting("gCraftCollectablePresets",{})	
		
	gTeaSelection = {GetString("none"),GetString("CP"),GetString("Control"),GetString("Craftmanship"),GetString("Any")}
	gCraftTeaList = ffxivminion.GetSetting("gCraftTeaList",GetString("none"))
	gCraftTeaTypeIndex = IsNull(GetKeyByValue(gCraftTeaList,gTeaSelection),1)
	
	gCraftFood = ffxivminion.GetSetting("gCraftFood",GetString("none"))
	gCraftFoodIndex = IsNull(GetKeyByValue(gCraftFood,gFoods),1)
	glastAlertUpdate = 0
	gUseCPTea = ffxivminion.GetSetting("gUseCPTea",false)
	-- Order Stuff
	
	--Add
	gCraftOrderAddID = 0
	gCraftOrderAddRecipeID = 0
	gCraftOrderAddAmount = 1
	gCraftOrderAddRequireHQ = false
	gCraftOrderAddRequireCP = 0
	gCraftOrderAddCountHQ = true
	gCraftOrderAddQuick = false
	gCraftOrderAddCollect = false
	gCraftOrderAddHQ = false
	gCraftOrderAddIfNecessary = false
	gCraftOrderAddSkillProfileIndex = 1
	gCraftOrderAddSkillProfile = GetString("none")
	
	--Edit
	gCraftOrderEditID = 0
	gCraftOrderEditRecipeID = 0
	gCraftOrderEditAmount = 1
	gCraftOrderEditRequireHQ = false
	gCraftOrderEditRequiredCP = 0
	gCraftOrderEditCountHQ = true
	gCraftOrderEditQuick = false
	gCraftOrderEditCollect = false
	gCraftOrderEditHQ = false
	gCraftOrderEditIfNecessary = false
	gCraftOrderEditSkillProfileIndex = 1
	gCraftOrderEditSkillProfile = GetString("none")
	gCraftOrderEditSkip = false
	
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
	
	for k = 5,80,5 do
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
			Settings.FFXIVMINION.gLastCraftProfiles = Settings.FFXIVMINION.gLastCraftProfiles
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
						Settings.FFXIVMINION.gLastCraftProfiles = Settings.FFXIVMINION.gLastCraftProfiles
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
		ffxiv_craft.UpdateAlertElement()
		
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
					GUI:PushItemWidth(50)
					GUI:Text("Remaining Count of Current Item: "); GUI:SameLine(); GUI:InputText("##remainingCount",remainingCount,GUI.InputTextFlags_ReadOnly)
					GUI:PopItemWidth()
				else
					local orders = ffxiv_craft.orders
					if (table.valid(orders)) then
						local maxCount = IsNull(orders[ml_task_hub:CurrentTask().key].maxcount,"Inf")
						GUI:PushItemWidth(50)
						GUI:Text("Remaining Count of Current Item: "); GUI:SameLine(); GUI:InputText("##CountRemaining",maxCount,GUI.InputTextFlags_ReadOnly) 
						if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Based from total item count only.")) end
				
						GUI:PopItemWidth()
					end
				end
			end
		end
	
		GUI:Separator();
		GUI:Columns(10, "#craft-manage-orders", true)
		GUI:SetColumnOffset(1, 160);
		GUI:SetColumnOffset(2, 210);
		GUI:SetColumnOffset(3, 260);
		GUI:SetColumnOffset(4, 310);
		GUI:SetColumnOffset(5, 360);
		GUI:SetColumnOffset(6, 400);
		GUI:SetColumnOffset(7, 430); -- up icon
		GUI:SetColumnOffset(8, 460); -- down icon
		GUI:SetColumnOffset(9, 505);
		GUI:SetColumnOffset(10, 580);
		
		GUI:Text("Item"); GUI:NextColumn();
		GUI:Text("Total"); GUI:NextColumn();
		GUI:Text("Norm"); GUI:NextColumn();
		GUI:Text("HQ"); GUI:NextColumn();
		GUI:Text("COL"); GUI:NextColumn();
		GUI:Text("Edit"); GUI:NextColumn();
		GUI:NextColumn(); -- up icon
		GUI:NextColumn(); -- down icon
		GUI:Text("Skip"); GUI:NextColumn();
		GUI:Text("Alert"); GUI:NextColumn();
		GUI:Separator();
		
		local orders = ffxiv_craft.orders
		if (table.valid(orders)) then
			for id,order in spairs(orders) do
			GUI:AlignFirstTextHeightToWidgets(); 
			if order.collect then
				GUI:Text("(C) " .. tostring(order.name));
			else
				GUI:AlignFirstTextHeightToWidgets(); GUI:Text(order.name);
			end	
				itemcount = order["itemcount"]
				itemcountNorm = order["itemcountnorm"]
				itemcountHQ = order["itemcounthq"]
				itemcountCollectable = order["itemcountcollectable"]
				GUI:NextColumn()
				GUI:AlignFirstTextHeightToWidgets(); GUI:InputText("##itemcount",itemcount,GUI.InputTextFlags_ReadOnly) ; 
				GUI:NextColumn()
				GUI:AlignFirstTextHeightToWidgets(); GUI:InputText("##itemcountNorm",itemcountNorm,GUI.InputTextFlags_ReadOnly) ; 
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
					gCraftOrderEditRecipeID = order.id
						
					gCraftOrderEditAmount = IsNull(order["amount"],0)
					gCraftOrderEditRequiredCP = IsNull(order["requiredcp"],0)
					gCraftOrderEditRequireHQ = IsNull(order["requirehq"],false)
					gCraftOrderEditCountHQ = IsNull(order["counthq"],true)
					gCraftOrderEditCollect = IsNull(order["collect"],false)
					if gCraftOrderEditCollect == true then
						gCraftOrderEditQuick = false
					else
						gCraftOrderEditQuick = IsNull(order["usequick"],false)
					end
					gCraftOrderEditHQ = IsNull(order["usehq"],false)
					gCraftOrderEditIfNecessary = IsNull(order["ifnecessary"],false)

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
				
				local doPriorityUp = 0
				local doPriorityDown = 0
				local doPriorityTop = 0
					
				GUI:Image(ml_global_information.path.."\\GUI\\UI_Textures\\w_up.png",16,16); GUI:SameLine(0,15);
				if (GUI:IsItemHovered()) then
					if (GUI:IsMouseClicked(0)) then
						doPriorityUp = id
					elseif (GUI:IsMouseClicked(1)) then
						doPriorityTop = id
					end
					GUI:SetTooltip("Right click will update old profile task numbering on move.")
				end
				if (doPriorityUp ~= 0 and doPriorityUp ~= 1) then
					
					local currentPos = doPriorityUp
					local newPos = doPriorityUp - 1
					
					local temp = orders[newPos]
					orders[newPos] = orders[currentPos]
					orders[currentPos] = temp	
										
					ffxiv_craft.SaveProfile()
				end
				if (doPriorityTop ~= 0 and doPriorityTop ~= 1) then
					
					local currentPos = doPriorityTop
					local newPos = doPriorityTop
					
					while currentPos > 1 do
						local temp = orders[newPos]
						orders[newPos] = orders[currentPos]
						orders[currentPos] = temp	
						currentPos = newPos
						newPos = newPos - 1
					end
										
					ffxiv_craft.SaveProfile()
				end
					
				GUI:NextColumn()
				
				GUI:Image(ml_global_information.path.."\\GUI\\UI_Textures\\w_down.png",16,16); GUI:SameLine(0,15);
				if (GUI:IsItemHovered()) then
					if (GUI:IsMouseClicked(0)) then
						doPriorityDown = id
					end
				end
				if (doPriorityDown ~= 0 and doPriorityDown < TableSize(orders)) then
					
					local currentPos = doPriorityDown
					local newPos = doPriorityDown + 1
					
					local temp = orders[newPos]
					orders[newPos] = orders[currentPos]
					orders[currentPos] = temp	
										
					ffxiv_craft.SaveProfile()
				end
				
				GUI:NextColumn()
				
				gCraftOrderEditSkip = IsNull(order.skip,false)
				local newVal, changed = GUI:Checkbox("##skip-"..tostring(id),gCraftOrderEditSkip)
				if (changed) then
					orders[id].skip = newVal
					if orders[id].skip == true then
						orders[id].uialert = "skip"
					end
				end
				
				GUI:NextColumn()
				GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
				--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
				GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
				
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
				elseif uiAlert == "lowmats" then
					local child_color = { r = .95, g = .69, b = .2, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##lowmats-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text("Mats")
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Full Order not craftable. Will craft partial order.")) end
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
		
		-- Label Column
		GUI:Columns(2)
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Current Active Food"))
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Food"))
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Show Usable Only"))
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use Exp Manuals"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow use of Experience boost manuals.")) end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use Tea Type"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow use of Tea Boosts.")) end
		GUI:NextColumn()
		
		-- Data column
		local CraftStatusWidth = GUI:GetContentRegionAvail()
		GUI:PushItemWidth(CraftStatusWidth-8)
		
		GUI:InputText("##Current Active Food",gCraftFood,GUI.InputTextFlags_ReadOnly)
		GUI_Combo("##food", "gCraftFoodIndex", "gCraftFood", gFoods)
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("This option will override any Profile food choice.")
		end
		GUI_Capture(GUI:Checkbox("##Show Usable Onlyfood",gFoodAvailableOnly),"gFoodAvailableOnly");
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("If this option is on, only available items will be shown.")
		end
		GUI:SameLine(0,5)
		
		
		local buttonBG = GUI:GetStyle().colors[GUI.Col_Button]
		GUI:PushStyleColor(GUI.Col_Button, buttonBG[1], buttonBG[2], buttonBG[3], 1)
		GUI:PushStyleColor(GUI.Col_ButtonActive, buttonBG[1], buttonBG[2], buttonBG[3], 1)
		if (GUI:ImageButton("##craft-food-refresh",ml_global_information.path.."\\GUI\\UI_Textures\\change.png", 14, 14)) then
			ffxivminion.FillFoodOptions(gFoodAvailableOnly)
		end
		GUI:PopStyleColor(2)		
		
		GUI_Capture(GUI:Checkbox("##"..GetString("Use Exp Manuals"),gUseExpManuals),"gUseExpManuals")
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow use of Experience boost manuals.")) end
		
		if (gTeaSelection ~= gCraftTeaList) then
			gCraftTeaList = gTeaSelection
		end
		GUI_Combo("##tea", "gCraftTeaTypeIndex", "gCraftTeaList", gTeaSelection)
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow use of CP boost Tea.")) end
		
		GUI:Columns()
		
		GUI:Separator()
		if gCraftMarkerOrProfileIndex ~= 1 then
			GUI:Columns(2)
			GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Collectable"))
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Enable Collectable Synthesis")) end
			GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Craft Attempts"))
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("How many crafts to complete, (or fail) before stopping.")) end
			GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Minimum CP"))
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("CP required before starting the craft. (Useful for CP food)")) end
			GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use HQ Mats"))
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow the use of HQ materials while crafting.")) end
			if gCraftUseHQ then
				GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Only If Necessary"))
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
				GUI_Capture(GUI:Checkbox("##"..GetString("Only If Necessary"),gCraftUseHQBackup),"gCraftUseHQBackup")
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
		GUI:Separator();
		GUI:Text("Please set Gearsets in Advanced Settings Auto-Equip Tab");
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
			ml_global_information.Await(1000, 3000, function () return (not IsControlOpen("RecipeNote") and not MIsLocked()) end)
			return true
		end
	else
		local logOpen = ActionList:Get(10,9)
		if (logOpen and logOpen.usable) then
			logOpen:Cast(Player.id)
			ml_global_information.Await(1000, 3000, function () return IsControlOpen("RecipeNote") end)
			return true
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
	
	if (table.valid(info)) then
		if (strName ~= "") then
			persistence.store(ffxiv_craft.profilePath..strName..".lua",info)
		else
			persistence.store(ffxiv_craft.profilePath..gCraftProfile..".lua",info)
		end
	else
		d("[Craft]: Orders table was invalid.")
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
	local recipeid = tonumber(gCraftOrderAddRecipeID) or 0
	if (recipeid ~= 0) then
		local orders = ffxiv_craft.orders
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
			ifnecessary = gCraftOrderAddIfNecessary,
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
		
		table.insert(ffxiv_craft.orders,thisOrder)
		ffxiv_craft.SaveProfile()
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
	if (ffxiv_craft.IsCrafting() or (gBotMode == GetString("craftMode") and gCraftMarkerOrProfileIndex ~= 1) or 
		gBotMode ~= GetString("craftMode") or 
		(Now() < ffxiv_craft.tracking.measurementDelay))
	then
		return false
	end
	
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local playercp = Player.cp.max
		local orders = ffxiv_craft.orders
		local foundSelection = false
		if (table.valid(orders)) then
		
			local getcounts = {}
			for id,order in pairs(orders) do
				local itemid = order.item
				getcounts[itemid] = true
				getcounts[itemid + 1000000] = true
				getcounts[itemid + 500000] = true
			end
			
			local getcountsorted = {}
			for itemid,_ in pairs(getcounts) do
				table.insert(getcountsorted,itemid)
			end
			
			local itemcounts = ItemCounts(getcountsorted)
			for id,order in pairs(orders) do
			
				if order["uialert"] == nil then
					order["uialert"] = "None"
				end
				if order["itemcount"] == nil then
					order["itemcount"] = 0
				end
				if order["itemcountnorm"] == nil then
					order["itemcountnorm"] = 0
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
				if order["maxcount"] == nil then
					order["maxcount"] = 0
				end
				if order["ifnecessary"] == nil then
					order["ifnecessary"] = false
				end
					
				local canCraft,maxAmount,yield = AceLib.API.Items.CanCraft(order.id,order["usehq"])

				if order["maxcount"] ~= maxAmount then
					order["maxcount"]= maxAmount
				end
				local lowMats = false
				if order.amount ~= 0 then
					if maxAmount > 0 then
						if (maxAmount * yield) < order.amount then
							lowMats = true
						end
					end
				end
					
				local okCP = (order["requiredcp"] ~= nil and (playercp >= order["requiredcp"])) or (order["usequick"] == true)
				if order["skip"] == true then
					order["uialert"] = "skip"
				elseif (order["skillprofile"] == "None") and (order["usequick"] == false) then
					order["uialert"] = "skillprofile"
				elseif not okCP then
					order["uialert"] = "lowcp"
				elseif lowMats then
					order["uialert"] = "lowmats"
				elseif maxAmount == 0 then
					order["uialert"] = "cantCraft"
				elseif maxAmount > 0 then
					order["uialert"] = "canCraft"
				end
				
				local itemid = order.item
				
				local itemcountnorm = IsNull(itemcounts[itemid].count,0)
				local itemcountHQ = IsNull(itemcounts[itemid + 1000000].count,0)
				local itemcountCollectable = IsNull(itemcounts[itemid + 500000].count,0)
				local itemcount = itemcountnorm + itemcountHQ + itemcountCollectable
				
				--cd("itemid = "..tostring(itemid))
				--cd("itemcountnorm = "..tostring(itemcountnorm))
				--cd("itemcountHQ = "..tostring(itemcountHQ))
				--cd("itemcountCollectable = "..tostring(itemcountCollectable))
				--cd("itemcount = "..tostring(itemcount))
				
				if order["itemcount"] ~= itemcount then
					order["itemcount"]= itemcount
				end
				if order["itemcountnorm"] ~= itemcountnorm then
					order["itemcountnorm"]= itemcountnorm
				end
				if order["itemcounthq"] ~= itemcountHQ then
					order["itemcounthq"]= itemcountHQ
				end
				if order["itemcountcollectable"] ~= itemcountCollectable then
					order["itemcountcollectable"]= itemcountCollectable
				end
			end
		end
		--ffxiv_craft.SaveProfile()
		ffxiv_craft.tracking.measurementDelay = Now() + 1000
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
			thisOrder["ifnecessary"] = gCraftOrderEditIfNecessary
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
	local maxattemptlevel = IsNull(maxattemptlevel,5)
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
			
		local recipes,dictionary = AceLib.API.Items.BuildRecipeString(craftid,0,(maxattemptlevel-4),maxattemptlevel)
		if (dictionary) then
			if (not ffxiv_craft.dictionaries[craftid] or not ffxiv_craft.dictionariesDisplay[craftid]) then
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
				string.contains(tostring(k),"gGearset"))				
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
	if (ffxiv_task_craft.GUI.orders.open) then
		GUI:SetNextWindowSize(500,200,GUI.SetCond_FirstUseEver) --set the next window size, only on first ever	
		GUI:SetNextWindowCollapsed(false,GUI.SetCond_Always)
		
		local winBG = GUI:GetStyle().colors[GUI.Col_WindowBg]
		GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
		
		ffxiv_task_craft.GUI.orders.visible, ffxiv_task_craft.GUI.orders.open = GUI:Begin(ffxiv_task_craft.GUI.orders.name, ffxiv_task_craft.GUI.orders.open)
		if ( ffxiv_task_craft.GUI.orders.visible ) then 
		
			GUI_DrawTabs(ffxiv_task_craft.GUI.orders.main_tabs)
			local tabs = ffxiv_task_craft.GUI.orders.main_tabs
			
			if (tabs.tabs[1].isselected) then
				ffxiv_craft.UpdateAlertElement()
				
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
										
					for id,order in spairs(orders) do
						if order.collect then
							GUI:Text("(C) " .. tostring(order.name));
						else
							GUI:AlignFirstTextHeightToWidgets(); GUI:Text(order.name);
						end				
						GUI:NextColumn()
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(order.id); GUI:NextColumn()
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(order.amount); GUI:NextColumn()
						
						if (order.skip == nil) then
							orders[id].skip = false
							ffxiv_craft.SaveProfile()
						end						
						
						gCraftOrderEditSkip = IsNull(order.skip,false)
						local newVal, changed = GUI:Checkbox("##skip-"..tostring(id),gCraftOrderEditSkip)
						if (changed) then
							orders[id].skip = newVal
							if orders[id].skip == true then
								orders[id].uialert = "skip"
							end
						end
						
						GUI:NextColumn()
						
						GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
						--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
						GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
						
						if (GUI:ImageButton("##craft-manage-edit"..tostring(id),ml_global_information.path.."\\GUI\\UI_Textures\\w_edit.png", 16, 16)) then
							gCraftOrderEditID = id
							gCraftOrderEditRecipeID = order.id
							
							gCraftOrderEditAmount = IsNull(order["amount"],0)
							gCraftOrderEditCollect = IsNull(order["collect"],false)
							gCraftOrderEditRequiredCP = IsNull(order["requiredcp"],0)
							gCraftOrderEditRequireHQ = IsNull(order["requirehq"],false)
							gCraftOrderEditCountHQ = IsNull(order["counthq"],true)
							if gCraftOrderEditCollect == true then
								gCraftOrderEditQuick = false
							else
								gCraftOrderEditQuick = IsNull(order["usequick"],false)
							end
							gCraftOrderEditHQ = IsNull(order["usehq"],false)
							gCraftOrderEditIfNecessary = IsNull(order["ifnecessary"],false)
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
						elseif uiAlert == "lowmats" then
							local child_color = { r = .95, g = .69, b = .2, a = .75 }
							GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
							GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
							GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
							GUI:BeginChild("##lowmats-"..tostring(id),50,20,true)
							GUI:AlignFirstTextHeightToWidgets()
							GUI:Text("Mats")
							GUI:EndChild()
							GUI:PopStyleColor()
							GUI:PopStyleVar()
							GUI:PopStyleVar()
							if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Full Order not craftable. Will craft partial order.")) end
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
				
				for k = 5,80,5 do
					local dictionary, dictionaryDisplay = ffxiv_craft.GetDictionary(k)
					if (dictionary and dictionaryDisplay) then
						--d("found dictionary for k = "..tostring(k))
						GUI:PushItemWidth(300)
						local selectionChanged = GUI_Combo(tostring(k-4).."-"..tostring(k), "gCraftDictionarySelectIndex"..tostring(k), "gCraftDictionarySelect"..tostring(k), dictionaryDisplay)
						if (selectionChanged) then
							local thisRecipe = dictionary[_G["gCraftDictionarySelectIndex"..tostring(k)]]
							if (thisRecipe) then
								gCraftOrderAddID = thisRecipe.recipeid
								gCraftOrderAddRecipeID = thisRecipe.recipeid
								gCraftOrderAddAmount = 1
								gCraftOrderAddCollect = false
								gCraftOrderAddRequireHQ = false
								gCraftOrderAddRequireCP = 0
								gCraftOrderAddCountHQ = true
								gCraftOrderAddQuick = false
								gCraftOrderAddHQ = false
								gCraftOrderAddIfNecessary = false
								gCraftOrderAddSkillProfileIndex = 1
								gCraftOrderAddSkillProfile = GetString("none")
							end
							for j = 5,80,5 do
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
				if (gCraftOrderAddRecipeID ~= 0) then
					
					GUI:Separator()
				
					GUI:Columns(2)
					
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Amount to Craft")); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use Collect")); 
					if (not gCraftOrderAddQuick) then
						GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Skill Profile")); 
					end
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Required CP")); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Require HQ")); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Count HQ")); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use QuickSynth")); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use HQ Items")); 
					if gCraftOrderAddHQ then
						GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Only If Necessary")); 
					end
					GUI:NextColumn()
					
					GUI:PushItemWidth(250)
					GUI_Capture(GUI:InputInt("##Amount to Craft",gCraftOrderAddAmount,0,0),"gCraftOrderAddAmount")
					GUI:PopItemWidth()
					GUI_Capture(GUI:Checkbox("##Use Collect",gCraftOrderAddCollect),"gCraftOrderAddCollect")
					if (not gCraftOrderAddQuick) then
						GUI:PushItemWidth(250)
						GUI_Combo(GetString("##skillProfile1"), "gCraftOrderAddSkillProfileIndex", "gCraftOrderAddSkillProfile", SkillMgr.profiles)
						GUI:PopItemWidth()
					end
					
					GUI:PushItemWidth(250)
					GUI_Capture(GUI:InputInt("##RequiredCP",gCraftOrderAddRequireCP,0,0),"gCraftOrderAddRequireCP")
					GUI_Capture(GUI:Checkbox("##Require HQ",gCraftOrderAddRequireHQ),"gCraftOrderAddRequireHQ")
					GUI_Capture(GUI:Checkbox("##Count HQ",gCraftOrderAddCountHQ),"gCraftOrderAddCountHQ")
					if gCraftOrderAddCollect then 
						gCraftOrderAddQuick = false
					end
					GUI_Capture(GUI:Checkbox("##Use QuickSynth",gCraftOrderAddQuick),"gCraftOrderAddQuick")
					GUI_Capture(GUI:Checkbox("##Use HQ Items",gCraftOrderAddHQ),"gCraftOrderAddHQ")
					GUI:PopItemWidth()
					if (gCraftOrderAddHQ) then						
						
						GUI_Capture(GUI:Checkbox("##AddIfNecessary",gCraftOrderAddIfNecessary),"gCraftOrderAddIfNecessary")
						if (GUI:IsItemHovered()) then
							GUI:SetTooltip(GetString("Only use HQ materials if there are no NQ materials left."))
						end
					end	
					
					GUI:Columns()
					if (gCraftOrderAddHQ) and not gCraftOrderAddIfNecessary then	
						local recipeDetails = AceLib.API.Items.GetRecipeDetails(gCraftOrderAddRecipeID)
						if (recipeDetails) then
							
							GUI:Columns(5, "#craft-add-hq", true)
							GUI:SetColumnOffset(1, 250); GUI:SetColumnOffset(2, 325); GUI:SetColumnOffset(3, 425); GUI:SetColumnOffset(4, 525);
							GUI:AlignFirstTextHeightToWidgets()
							
							GUI:Text("Ingredient"); GUI:NextColumn();
							GUI:Text("Required"); GUI:NextColumn();
							GUI:Text("Min HQ Amount"); GUI:NextColumn();
							GUI:Text("Max HQ Amount"); GUI:NextColumn();
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
									local newVal, changed = GUI:InputInt("##HQ MinAmount"..tostring(i),_G["gCraftOrderAddHQIngredient"..tostring(i).."Min"],0,0)
									if (changed) then
									
										if (newVal > recipeDetails["iamount"..tostring(i)]) then
											newVal = recipeDetails["iamount"..tostring(i)]
										ffxiv_craft.UpdateOrderElement()
										elseif (newVal < 0) then
											newVal = 0
										ffxiv_craft.UpdateOrderElement()
										end
											
										_G["gCraftOrderAddHQIngredient"..tostring(i).."Min"] = newVal
										ffxiv_craft.UpdateOrderElement()
									end
									if (GUI:IsItemHovered()) then
										GUI:SetTooltip("Minimum amount of HQ items to use for this item in the craft.")
									end
									GUI:PopItemWidth()
									GUI:NextColumn();
									
									GUI:PushItemWidth(50)
									local newVal, changed = GUI:InputInt("##HQ Amount"..tostring(i),_G["gCraftOrderAddHQIngredient"..tostring(i)],0,0)
									if (changed) then
									
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
											
										_G["gCraftOrderAddHQIngredient"..tostring(i)] = newVal
										ffxiv_craft.UpdateOrderElement()
									end
									if (GUI:IsItemHovered()) then
										GUI:SetTooltip("Max amount of HQ items to use for this item in the craft.")
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
					
					if (GUI:Button("Add to Profile",250,20)) then
					
						d("Adding Recipe id ["..gCraftOrderAddRecipeID.."]")
						ffxiv_craft.AddToProfile()
						ffxiv_craft.tracking.measurementDelay = Now()
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
					if (gCraftOrderEditHQ) then
						GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Only If Necessary")); 
					end
					GUI:NextColumn()
					
					GUI:PushItemWidth(250)
					
							
					
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
					if gCraftOrderEditCollect == true then
						gCraftOrderEditQuick = false
					end
					
					if (not gCraftOrderEditQuick) then
						GUI:PushItemWidth(250)
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
					
					if (gCraftOrderEditHQ) then
					
						GUI_Capture(GUI:Checkbox("##EditIfNecessary",gCraftOrderEditIfNecessary),"gCraftOrderEditIfNecessary")
						if 	(GUI:IsItemHovered()) then
							GUI:SetTooltip(GetString("Only use HQ materials if there are no NQ materials left."))
						end
						if (orders.ifnecessary ~= gCraftOrderEditIfNecessary) then
							orders.ifnecessary = gCraftOrderEditIfNecessary
							ffxiv_craft.UpdateOrderElement()
						end
					end
					
					GUI:Columns()
					if (gCraftOrderEditHQ) and not gCraftOrderEditIfNecessary then
						GUI:Separator()
						local recipeDetails = AceLib.API.Items.GetRecipeDetails(gCraftOrderEditRecipeID)
						if (recipeDetails) then
							
							GUI:Columns(5, "#craft-edit-hq", true)
							GUI:SetColumnOffset(1, 250); GUI:SetColumnOffset(2, 325); GUI:SetColumnOffset(3, 425); GUI:SetColumnOffset(4, 525);
							GUI:AlignFirstTextHeightToWidgets()
							
							GUI:Text("Ingredient"); GUI:NextColumn();
							GUI:Text("Required"); GUI:NextColumn();
							GUI:Text("Min HQ Amount"); GUI:NextColumn();
							GUI:Text("Max HQ Amount"); GUI:NextColumn();
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
									local newVal, changed = GUI:InputInt("##HQ MinAmount-"..tostring(i),_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"],0,0)
									if (changed) then
									
										if (newVal > recipeDetails["iamount"..tostring(i)]) then
											newVal = recipeDetails["iamount"..tostring(i)]
										elseif (newVal < 0) then
											newVal = 0
										end
										
										_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"] = newVal
										ffxiv_craft.UpdateOrderElement()
									end
									if (GUI:IsItemHovered()) then
										GUI:SetTooltip("Minimum amount of HQ items to use for this item in the craft.")
									end
									GUI:PopItemWidth()
									GUI:NextColumn();
									
									GUI:PushItemWidth(50)
									GUI:AlignFirstTextHeightToWidgets()
									local newVal, changed = GUI:InputInt("##HQ Amount-"..tostring(i),_G["gCraftOrderEditHQIngredient"..tostring(i)],0,0)
									if (changed) then
									
										if (newVal ~= recipeDetails["iamount"..tostring(i)]) then
											recipeDetails["iamount"..tostring(i)] = newVal
										elseif (newVal < 0) then
											newVal = 0
										end
										if (newVal == recipeDetails["iamount"..tostring(i)]) then
											_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = true
										else
											_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = false
										end
										
										_G["gCraftOrderEditHQIngredient"..tostring(i)] = newVal
										ffxiv_craft.UpdateOrderElement()
									end
									if (GUI:IsItemHovered()) then
										GUI:SetTooltip("Max amount of HQ items to use for this item in the craft.")
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

RegisterEventHandler("Gameloop.Draw", ffxiv_craft.Draw, "ffxiv_craft.Draw")

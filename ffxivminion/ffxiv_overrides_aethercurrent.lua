-- Curated access requirements for field aether currents.
--
-- AetherCurrent.Quest covers currents awarded by quests; it does not describe
-- the story progression needed to physically reach every field current. Keep
-- those behavioral gates public and editable here.
--
-- This is executable branching rather than an EObjId lookup table, so loading
-- the module does not leave a persistent 60+ entry data table for Lua's GC.
function FFXIVAetherCurrentRequirementsMet(eObjId)
	local id = tonumber(eObjId)
	if not id then return true end

	-- The Dravanian Hinterlands - Leaving Idyllshire
	if id == 2006210 or id == 2006214 then
		return QuestCompleted(1658) and GetHinterlandsSection(Player.pos) == 1
	end

	-- The Sea of Clouds - Into the Blue
	if id == 2006228 or id == 2006229 or id == 2006231 or id == 2006234 then
		return QuestCompleted(1643)
	end

	-- The Fringes - Rising Fortunes, Rising Spirits
	if id == 2007971 or id == 2007972 then
		return QuestCompleted(2530)
	end

	-- The Ruby Sea - In Soroban We Trust
	if id == 2008004 then return QuestCompleted(2484) end

	-- The Peaks - The First of Many
	if id == 2007981 then return HasQuest(2534) or QuestCompleted(2534) end
	-- The Peaks - Heavens Weep
	if id == 2007984 then return QuestCompleted(2537) end

	-- The Lochs - The Resonant
	if id == 2007994 then return QuestCompleted(2550) end
	-- The Azim Steppe - In the Footsteps of Bardam the Brave
	if id == 2008019 then return QuestCompleted(2507) end

	-- Kholusia - The View from Above
	if id == 2010041 or id == 2010042 then return QuestCompleted(3634) end

	-- Amh Araeng - The Best Way Out
	if id == 2010050 then
		return QuestCompleted(3609) and GetAhmAraengSection(Player.pos) == 2
	end
	-- Amh Araeng - Full Steam Ahead
	if id == 2010052 then return QuestCompleted(3619) end

	-- Il Mheg - A Visit to the Nu Mou
	if id == 2010059 or id == 2010062 or id == 2010063 then
		return QuestCompleted(3313)
	end

	-- The Rak'tika Greatwood - Top of the Tree
	if id == 2010069 or id == 2010073 then return QuestCompleted(3334) end
	-- The Tempest - The Illuminated Land
	if id == 2010083 then return QuestCompleted(3651) end

	-- Labyrinthos - Going Underground
	if id == 2011985 or id == 2011986 then return QuestCompleted(4441) end
	-- Thavnair - Beyond the Depths of Despair
	if id == 2011995 or id == 2011996 then return QuestCompleted(4412) end

	-- Mare Lamentorum - Helping Hands
	if id == 2012010 or id == 2012011 or id == 2012012 or id == 2012013 then
		return QuestCompleted(4400)
	end

	-- Elpis - Petalouda Hunt
	if id == 2012020 or id == 2012021 then return QuestCompleted(4421) end
	-- Elpis - A Flower upon Your Return
	if id == 2012025 then return QuestCompleted(4433) end
	-- Elpis - Travelers at the Crossroads
	if id == 2012026 then return QuestCompleted(4429) end

	-- Ultima Thule - A Test of Will
	if id == 2012030 or id == 2012031 then return QuestCompleted(4455) end
	-- Ultima Thule - Victory... Lost
	if id == 2012032 or id == 2012033 then return QuestCompleted(4459) end

	-- Urqopacha - History's Keepers
	if id == 2013929 or id == 2013930 or id == 2013931
		or id == 2013932 or id == 2013933
	then
		return QuestCompleted(4889)
	end

	-- Kozama'uka - For All Turali
	if id == 2013940 or id == 2013941 or id == 2013942 or id == 2013943 then
		return QuestCompleted(4879)
	end

	-- Yak T'el - Into the Traverse
	if id == 2013949 or id == 2013950 or id == 2013951
		or id == 2013952 or id == 2013953
	then
		return QuestCompleted(4903)
	end

	-- Living Memory - Those Who Live Forever
	if id == 2013974 or id == 2013976 then
		return (HasQuest(4949) and GetQuestInfo(4949, "step") > 2)
			or QuestCompleted(4949)
	end
	-- Living Memory - The Land of Dreams
	if id == 2013975 or id == 2013977 or id == 2013978 then
		return (HasQuest(4951) and GetQuestInfo(4951, "step") > 1)
			or QuestCompleted(4951)
	end
	-- Living Memory - The Sanctuary of the Strong
	if id == 2013979 or id == 2013981 or id == 2013982 then
		return (HasQuest(4953) and GetQuestInfo(4953, "step") >= 2)
			or QuestCompleted(4953)
	end
	-- Living Memory - An Explorer's Delight
	if id == 2013980 or id == 2013983 then
		return (HasQuest(4956) and GetQuestInfo(4956, "step") >= 3)
			or QuestCompleted(4956)
	end

	return true
end

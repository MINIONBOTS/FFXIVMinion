FFXIVMinionHuntlog = FFXIVMinionHuntlog or {}

-- Starting characters do not always report the "Way of" quest as complete,
-- so keep both level 1 quests for each original combat class.
function FFXIVMinionHuntlog.IsUnlocked()
	return Quest:IsQuestCompleted(253) -- Way of the Gladiator
		or Quest:IsQuestCompleted(286) -- My First Gladius
		or Quest:IsQuestCompleted(533) -- Way of the Pugilist
		or Quest:IsQuestCompleted(553) -- My First Hora
		or Quest:IsQuestCompleted(311) -- Way of the Marauder
		or Quest:IsQuestCompleted(312) -- My First Axe
		or Quest:IsQuestCompleted(23) -- Way of the Lancer
		or Quest:IsQuestCompleted(218) -- My First Spear
		or Quest:IsQuestCompleted(21) -- Way of the Archer
		or Quest:IsQuestCompleted(219) -- My First Bow
		or Quest:IsQuestCompleted(22) -- Way of the Conjurer
		or Quest:IsQuestCompleted(211) -- My First Cane
		or Quest:IsQuestCompleted(345) -- Way of the Thaumaturge
		or Quest:IsQuestCompleted(346) -- My First Scepter
		or Quest:IsQuestCompleted(453) -- Way of the Arcanist
		or Quest:IsQuestCompleted(454) -- My First Grimoire
		-- Boosted jobs can have a GC log without an ARR class log.
		or Quest:IsQuestCompleted(681) -- The Company You Keep (Maelstrom)
		or Quest:IsQuestCompleted(680) -- The Company You Keep (Twin Adder)
		or Quest:IsQuestCompleted(682) -- The Company You Keep (Immortal Flames)
end

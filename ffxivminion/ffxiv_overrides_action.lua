-- Action IDs used by SkillManager that cannot be read cleanly from Action.
-- Keep these public; profile and addon authors may need to update them.

FFXIVMinionAction = FFXIVMinionAction or {}

-- These groups are SkillManager behavior, not Action sheet categories.
function FFXIVMinionAction.HasClassification(actionId, classification)
	local id = tonumber(actionId)
	if not id then return false end
	local name = classification
	if name ~= "healing" and name ~= "friendlybuff" and name ~= "petsummon"
		and name ~= "mudra" and name ~= "ninjutsu"
	then
		name = type(name) == "string" and string.lower(name) or ""
	end

	if name == "healing" then
		if id == 120 then return true end -- Cure
		if id == 124 then return true end -- Medica
		if id == 126 then return true end -- Esuna
		if id == 131 then return true end -- Cure III
		if id == 133 then return true end -- Medica II
		if id == 135 then return true end -- Cure II
		if id == 140 then return true end -- Benediction
		if id == 185 then return true end -- Adloquium
		if id == 186 then return true end -- Succor
		if id == 187 then return true end -- Leeches
		if id == 189 then return true end -- Lustrate
		if id == 190 then return true end -- Physick
		if id == 3541 then return true end -- Clemency
		if id == 3570 then return true end -- Tetragrammaton
		if id == 3583 then return true end -- Indomitability
		if id == 3594 then return true end -- Benefic
		if id == 3595 then return true end -- Aspected Benefic
		if id == 3600 then return true end -- Helios
		if id == 3601 then return true end -- Aspected Helios
		if id == 3602 then return true end -- Exalted Detriment
		if id == 3610 then return true end -- Benefic II
		if id == 3614 then return true end -- Essential Dignity
		if id == 7434 then return true end -- Excogitation
		if id == 7445 then return true end -- Lady of Crowns
		if id == 8895 then return true end -- Cure
		if id == 8896 then return true end -- Cure II
		if id == 8898 then return true end -- Regen
		if id == 8902 then return true end -- Benediction
		if id == 8904 then return true end -- Physick
		if id == 8905 then return true end -- Adloquium
		if id == 8909 then return true end -- Lustrate
		if id == 8913 then return true end -- Benefic
		if id == 8914 then return true end -- Benefic II
		if id == 8916 then return true end -- Essential Dignity
		if id == 10029 then return true end -- Lady of Crowns
	elseif name == "friendlybuff" then
		if id >= 4401 and id <= 4424 then return true end -- the Balance through the Spire
		if id == 27 then return true end -- Cover
		if id == 123 then return true end -- Protect
		if id == 129 then return true end -- Stoneskin
		if id == 137 then return true end -- Regen
		if id == 2249 then return true end -- Goad
		if id == 3564 then return true end -- Shadewalker
		if id == 3565 then return true end -- Smoke Screen
		if id == 3611 then return true end -- Time Dilation
		if id == 3612 then return true end -- Synastry
		if id == 7432 then return true end -- Divine Benison
		if id == 8921 then return true end -- the Balance
		if id == 8922 then return true end -- the Bole
		if id == 8923 then return true end -- the Ewer
		if id == 8924 then return true end -- the Spire
		if id == 9621 then return true end -- Divine Benison
		if id == 9651 then return true end -- Protect
	elseif name == "petsummon" then
		if id == 150 then return true end -- Swiftcast
		if id == 165 then return true end -- Summon
		if id == 170 then return true end -- Summon II
		if id == 180 then return true end -- Summon III
		if id == 2864 then return true end -- Rook Autoturret
		if id == 2865 then return true end -- Bishop Autoturret
	elseif name == "mudra" then
		if id == 2259 then return true end -- Ten
		if id == 2261 then return true end -- Chi
		if id == 2263 then return true end -- Jin
		if id == 18805 then return true end -- Ten
		if id == 18806 then return true end -- Chi
		if id == 18807 then return true end -- Jin
	elseif name == "ninjutsu" then
		if id == 2260 then return true end -- Ninjutsu
		if id == 2265 then return true end -- Fuma Shuriken
		if id == 2266 then return true end -- Katon
		if id == 2267 then return true end -- Raiton
		if id == 2268 then return true end -- Hyoton
		if id == 2269 then return true end -- Huton
		if id == 2270 then return true end -- Doton
		if id == 2271 then return true end -- Suiton
		if id == 2272 then return true end -- Rabbit Medium
	end

	return false
end

-- Summon action -> spawned BNpcBase content IDs. Action has no FK for this.
function FFXIVMinionAction.GetPetContentIds(actionId)
	local id = tonumber(actionId)
	if id == 2864 then return "3666" end -- Rook Autoturret -> rook autoturret
	if id == 2865 then return "3667" end -- Bishop Autoturret -> bishop autoturret
	if id == 165 then return "1404;1398;1401" end -- Summon -> Garuda-Egi, Eos, Emerald Carbuncle
	if id == 170 then return "1403;1399;1400" end -- Summon II -> Titan-Egi, Selene, Topaz Carbuncle
	if id == 180 then return "1402" end -- Summon III -> Ifrit-Egi
	return nil
end

-- Known GCD action used to read the job's current recast time.
function FFXIVMinionAction.GetRepresentativeGCD(jobId, pvp, level)
	local id = tonumber(jobId)
	if not id then return nil end

	if pvp then
		if id == 1 or id == 19 then return 8718 end -- GLA/PLD: Fast Blade
		if id == 3 or id == 21 then return 8758 end -- MRD/WAR: Heavy Swing
		if id == 2 or id == 20 then return 8780 end -- PGL/MNK: Bootshine
		if id == 4 or id == 22 then return 8791 end -- LNC/DRG: True Thrust
		if id == 5 or id == 23 then return 8834 end -- ARC/BRD: Heavy Shot
		if id == 6 or id == 24 then return 8895 end -- CNJ/WHM: Cure
		if id == 7 or id == 25 then return 8858 end -- THM/BLM: Fire
		if id == 26 or id == 28 then return 8904 end -- ACN/SCH: Physick
		if id == 27 then return 8872 end -- SMN: Ruin III
		if id == 29 or id == 30 then return 8807 end -- ROG/NIN: Spinning Edge
		if id == 31 then return 8845 end -- MCH: Split Shot
		if id == 33 then return 8912 end -- AST: Malefic III
		if id == 32 then return 8769 end -- DRK: Hard Slash
		if id == 34 then return 8821 end -- SAM: Hakaze
		if id == 35 then return 8882 end -- RDM: Veraero
		if id == 38 then return 17756 end -- DNC: Cascade
		if id == 37 then return 17703 end -- GNB: Keen Edge
		return nil
	end

	if id == 1 or id == 19 then return 9 end -- GLA/PLD: Fast Blade
	if id == 3 or id == 21 then return 31 end -- MRD/WAR: Heavy Swing
	if id == 2 or id == 20 then return 53 end -- PGL/MNK: Bootshine
	if id == 4 or id == 22 then return 75 end -- LNC/DRG: True Thrust
	if id == 5 or id == 23 then return 97 end -- ARC/BRD: Heavy Shot
	if id == 6 or id == 24 then return 119 end -- CNJ/WHM: Stone
	if id == 7 or id == 25 then return 142 end -- THM/BLM: Blizzard
	if id == 26 or id == 27 or id == 28 then return 163 end -- ACN/SMN/SCH: Ruin
	if id == 17 then return 218 end -- BTN: Field Mastery
	if id == 16 then return 235 end -- MIN: Sharp Vision
	if id == 29 or id == 30 then return 2240 end -- ROG/NIN: Spinning Edge
	if id == 31 then return 2866 end -- MCH: Split Shot
	if id == 33 then return 3596 end -- AST: Malefic
	if id == 32 then return 3617 end -- DRK: Hard Slash
	if id == 34 then return 7477 end -- SAM: Hakaze
	if id == 35 then return tonumber(level) == 1 and 7504 or 7503 end -- RDM: Riposte/Jolt
	if id == 36 then return 11385 end -- BLU: Water Cannon
	if id == 38 then return 15989 end -- DNC: Cascade
	if id == 37 then return 16137 end -- GNB: Keen Edge
	if id == 39 then return 24373 end -- RPR: Slice
	if id == 40 then return 24283 end -- SGE: Dosis
	if id == 41 then return 34606 end -- VPR: Steel Fangs
	if id == 42 then return 34650 end -- PCT: Fire in Red
	return nil
end

-- Some jobs need a few fallbacks because actions are replaced as they level.
FFXIVMinionAction.TestSkillArcher = { 98, 97 } -- Straight Shot, Heavy Shot
FFXIVMinionAction.TestSkillConjurer = { 132, 127, 121, 119 } -- Aero II, Stone II, Aero, Stone
FFXIVMinionAction.TestSkillWhiteMage = { 7431, 3568, 132, 127, 121, 119 } -- Stone IV, Stone III, Aero II, Stone II, Aero, Stone
FFXIVMinionAction.TestSkillThaumaturge = { 156, 142 } -- Scathe, Blizzard
FFXIVMinionAction.TestSkillArcanist = { 178, 164, 163 } -- Bio II, Bio, Ruin
FFXIVMinionAction.TestSkillSummoner = { 7424, 3579, 178, 164, 163 } -- Bio III, Ruin III, Bio II, Bio, Ruin
FFXIVMinionAction.TestSkillScholar = { 7435, 3584, 178, 164, 163 } -- Broil II, Broil, Bio II, Bio, Ruin
FFXIVMinionAction.TestSkillMachinist = { 7411, 2866 } -- Heated Split Shot, Split Shot
FFXIVMinionAction.TestSkillAstrologian = { 7442, 3598, 3596 } -- Malefic III, Malefic II, Malefic
FFXIVMinionAction.TestSkillRedMage = { 7503, 7504 } -- Jolt, Riposte

-- Known attack used by the navigation reachability check.
function FFXIVMinionAction.GetTestSkill(jobId, pvp)
	local id = tonumber(jobId)
	if not id then return nil end

	if pvp then
		if id == 1 or id == 19 then return 8718 end -- GLA/PLD: Fast Blade
		if id == 3 or id == 21 then return 8758 end -- MRD/WAR: Heavy Swing
		if id == 2 or id == 20 then return 8780 end -- PGL/MNK: Bootshine
		if id == 4 or id == 22 then return 8791 end -- LNC/DRG: True Thrust
		if id == 5 or id == 23 then return 8834 end -- ARC/BRD: Heavy Shot
		if id == 6 or id == 24 then return 8895 end -- CNJ/WHM: Cure
		if id == 7 or id == 25 then return 8858 end -- THM/BLM: Fire
		if id == 26 or id == 28 then return 8904 end -- ACN/SCH: Physick
		if id == 27 then return 8872 end -- SMN: Ruin III
		if id == 29 or id == 30 then return 8807 end -- ROG/NIN: Spinning Edge
		if id == 31 then return 8845 end -- MCH: Split Shot
		if id == 33 then return 8912 end -- AST: Malefic III
		if id == 32 then return 8769 end -- DRK: Hard Slash
		if id == 34 then return 8821 end -- SAM: Hakaze
		if id == 35 then return 8882 end -- RDM: Veraero
		if id == 38 then return 17756 end -- DNC: Cascade
		if id == 37 then return 17703 end -- GNB: Keen Edge
		if id == 39 then return 24373 end -- RPR: Slice
		if id == 40 then return 24283 end -- SGE: Dosis
		if id == 41 then return 34606 end -- VPR: Steel Fangs
		if id == 42 then return 34650 end -- PCT: Fire in Red
		return nil
	end

	if id == 1 or id == 19 then return 9 end -- GLA/PLD: Fast Blade
	if id == 3 or id == 21 then return 31 end -- MRD/WAR: Heavy Swing
	if id == 2 or id == 20 then return 53 end -- PGL/MNK: Bootshine
	if id == 4 or id == 22 then return 75 end -- LNC/DRG: True Thrust
	if id == 5 or id == 23 then return FFXIVMinionAction.TestSkillArcher end -- ARC/BRD
	if id == 6 then return FFXIVMinionAction.TestSkillConjurer end -- CNJ
	if id == 24 then return FFXIVMinionAction.TestSkillWhiteMage end -- WHM
	if id == 7 or id == 25 then return FFXIVMinionAction.TestSkillThaumaturge end -- THM/BLM
	if id == 26 then return FFXIVMinionAction.TestSkillArcanist end -- ACN
	if id == 27 then return FFXIVMinionAction.TestSkillSummoner end -- SMN
	if id == 28 then return FFXIVMinionAction.TestSkillScholar end -- SCH
	if id == 17 then return 218 end -- BTN: Field Mastery
	if id == 16 then return 235 end -- MIN: Sharp Vision
	if id == 29 or id == 30 then return 2240 end -- ROG/NIN: Spinning Edge
	if id == 31 then return FFXIVMinionAction.TestSkillMachinist end -- MCH
	if id == 33 then return FFXIVMinionAction.TestSkillAstrologian end -- AST
	if id == 32 then return 3617 end -- DRK: Hard Slash
	if id == 34 then return 7477 end -- SAM: Hakaze
	if id == 35 then return FFXIVMinionAction.TestSkillRedMage end -- RDM
	if id == 36 then return 11385 end -- BLU: Water Cannon
	if id == 38 then return 15989 end -- DNC: Cascade
	if id == 37 then return 16137 end -- GNB: Keen Edge
	return nil

end

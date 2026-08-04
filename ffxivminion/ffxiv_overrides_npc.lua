FFXIVMinionNPC = FFXIVMinionNPC or {}

-- Trust and allied battle actors do not expose a usable ClassJob ID.
-- These roles describe how Minion should treat the live BNpc variants.
function FFXIVMinionNPC.HasTrustRole(contentId, role)
	local id = tonumber(contentId)
	if not id then return false end
	if role ~= "tank" and role ~= "healer" and role ~= "dps"
		and role ~= "melee" and role ~= "physicalranged" and role ~= "caster"
	then
		role = string.lower(tostring(role or ""))
	end

	if role == "tank" then
		return id == 713 -- Thancred
			or id == 1455 -- Haurchefant
			or id == 5964 -- Arenvald
			or id == 8650 -- Crystal Exarch
			or id == 9348 -- Thancred
			or id == 9363 -- G'raha Tia
			or id == 11262 -- Aymeric
			or id == 11266 -- Thancred's avatar
			or id == 11271 -- G'raha Tia's avatar
			or id == 11313 -- Ysayle
			or id == 11326 -- Eager marauder
			or id == 11330 -- Scion marauder
			or id == 11334 -- Storm marauder
			or id == 11416 -- Varshahn
			or id == 11431 -- Temple Knight
			or id == 12236 -- House Fortemps knight
			or id == 12312 -- Pero Roggo
			or id == 12463 -- Carvallain
			or id == 12464 -- Gosetsu
			or id == 12487 -- Wuk Lamat
			or id == 12488 -- G'raha Tia
	end

	if role == "healer" then
		return id == 1492 -- Urianger
			or id == 4130 -- Alphinaud
			or id == 8650 -- Crystal Exarch
			or id == 9346 -- Alphinaud
			or id == 9349 -- Urianger
			or id == 9363 -- G'raha Tia
			or id == 10586 -- Venat
			or id == 11264 -- Alphinaud's avatar
			or id == 11267 -- Urianger's avatar
			or id == 11271 -- G'raha Tia's avatar
			or id == 11329 -- Eager conjurer
			or id == 11333 -- Scion conjurer
			or id == 11337 -- Serpent conjurer
			or id == 12239 -- Temple chirurgeon
			or id == 12465 -- Mol youth
			or id == 12468 -- Doman shaman
			or id == 12469 -- Resistance fighter
			or id == 12487 -- Wuk Lamat
			or id == 12488 -- G'raha Tia
	end

	if role == "melee" then
		return id == 4133 -- Raubahn
			or id == 5970 -- Lyse
			or id == 6148 -- Hien
			or id == 8650 -- Crystal Exarch
			or id == 8889 -- Ryne
			or id == 8917 -- Minfilia
			or id == 9363 -- G'raha Tia
			or id == 10013 -- Estinien
			or id == 11269 -- Ryne's avatar
			or id == 11270 -- Estinien's avatar
			or id == 11271 -- G'raha Tia's avatar
			or id == 11331 -- Scion lancer
			or id == 11335 -- Serpent lancer
			or id == 11433 -- Temple banneret
			or id == 12237 -- House Fortemps banneret
			or id == 12466 -- Yugiri
			or id == 12470 -- Resistance pikedancer
			or id == 12487 -- Wuk Lamat
			or id == 12488 -- G'raha Tia
			or id == 12635 -- J'moldva
	end

	if role == "physicalranged" then
		return id == 8919 -- Lyna
			or id == 10899 -- Hythlodaeus
			or id == 11418 -- Zero
			or id == 12053 -- Zero's avatar
			or id == 12740 -- Koana
	end

	if role == "caster" then
		return id == 4846 -- Krile
			or id == 5239 -- Alisaie
			or id == 8378 -- Y'shtola
			or id == 10898 -- Emet-Selch
			or id == 11265 -- Alisaie's avatar
			or id == 11268 -- Y'shtola's avatar
			or id == 11328 -- Eager thaumaturge
			or id == 11332 -- Scion thaumaturge
			or id == 11336 -- Flame thaumaturge
			or id == 12739 -- Zoraal Ja
			or id == 13522 -- Krile's avatar
	end

	if role == "dps" then
		return FFXIVMinionNPC.HasTrustRole(id, "melee")
			or FFXIVMinionNPC.HasTrustRole(id, "physicalranged")
			or FFXIVMinionNPC.HasTrustRole(id, "caster")
			or id == 9347 -- Ryne
			or id == 11282 -- Byregot's avatar
			or id == 12467 -- Doman liberator
			or id == 12489 -- Erenville
	end

	return false
end

-- These bosses behave as omnidirectional even though BNpcBase says otherwise.
function FFXIVMinionNPC.HasOmnidirectionalOverride(contentId)
	local id = tonumber(contentId)
	return id == 4776 -- Sephirot
		or id == 4954 -- Hraesvelgr
end

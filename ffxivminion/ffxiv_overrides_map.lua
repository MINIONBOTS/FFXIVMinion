FFXIVMinionMap = FFXIVMinionMap or {}

-- The Firmament behaves like a city for sprint, aethernet, and homepoint logic.
-- TerritoryType keeps it in the restoration-content category instead of town.
FFXIVLib.API.Map.SetCityMapOverride(886, true) -- The Firmament

-- The sheets only have 2D map-marker positions for these airship landings.
FFXIVLib.API.Map.SetLocationOnlyNavigationOverride(93, 128, -18.23, 92, -8.60) -- Limsa Lominsa Upper Decks
FFXIVLib.API.Map.SetLocationOnlyNavigationOverride(94, 132, 25.13, -19, 97.43) -- New Gridania
FFXIVLib.API.Map.SetLocationOnlyNavigationOverride(95, 130, -16.95, 83, -9.42) -- Ul'dah - Steps of Nald

-- This is just the most useful progression marker for the help window.
function FFXIVMinionMap.GetAccessText()
	-- Dawntrail
	if CanAccessMap(1192) then return "Can Access Living Memory" end
	if CanAccessMap(1191) then return "Can Access Heritage Found" end
	if CanAccessMap(1186) then return "Can Access Solution Nine" end
	if CanAccessMap(1190) then return "Can Access Shaaloani" end
	if CanAccessMap(1189) then return "Can Access Yak T'el" end
	if CanAccessMap(1188) then return "Can Access Kozama'uka" end
	if CanAccessMap(1187) then return "Can Access Urqopacha" end
	if CanAccessMap(1185) then return "Can Access Tuliyollal" end

	-- Endwalker
	if CanAccessMap(960) then return "Can Access Ultima Thule" end
	if CanAccessMap(961) then return "Can Access Elpis" end
	if CanAccessMap(959) then return "Can Access Mare Lamentorum" end
	if CanAccessMap(958) then return "Can Access Garlemald" end
	if CanAccessMap(963) then return "Can Access Radz-at-Han" end
	if CanAccessMap(957) then return "Can Access Thavnair" end
	if CanAccessMap(956) then return "Can Access Labyrinthos" end
	if CanAccessMap(962) then return "Can Access Old Sharlayan" end

	-- Shadowbringers
	if CanAccessMap(818) then return "Can Access The Tempest" end
	if CanAccessMap(817) then return "Can Access The Rak'tika Greatwood" end
	if CanAccessMap(816) then return "Can Access Il Mheg" end
	if CanAccessMap(815) then return "Can Access Amh Araeng" end
	if CanAccessMap(814) then return "Can Access Lakeland" end
	if CanAccessMap(819) then return "Can Access The Crystarium" end

	-- Stormblood
	if CanAccessMap(621) then return "Can Access The Lochs" end
	if CanAccessMap(622) then return "Can Access The Azim Steppe" end
	if CanAccessMap(614) then return "Can Access Yanxia" end
	if CanAccessMap(613) then return "Can Access The Ruby Sea" end
	if CanAccessMap(612) then return "Can Access The Fringes" end

	-- Heavensward
	if CanAccessMap(402) then return "Can Access Azys Lla" end
	if CanAccessMap(399) then return "Can Access The Dravanian Hinterlands" end
	if CanAccessMap(398) then return "Can Access The Dravanian Forelands" end
	if CanAccessMap(397) then return "Can Access Coerthas Western Highlands" end
	if CanAccessMap(418) then return "Can NOT Access Coerthas Western Highlands" end
	return "Can NOT Access Heavensward maps"
end

function FFXIVMinionMap._FindAttunedAetheryte(aetherytes, aetheryteId)
	if not table.valid(aetherytes) then return nil end
	for _, aetheryte in pairs(aetherytes) do
		if aetheryte.id == aetheryteId then return aetheryte end
	end
	return nil
end

function FFXIVMinionMap._TryFallbackTravel(aetherytes, aetheryteId, destinationMapId)
	local aetheryte = FFXIVMinionMap._FindAttunedAetheryte(aetherytes, aetheryteId)
	if not aetheryte or GilCount() < aetheryte.price then return nil end

	local row = FFXIVLib.API.Map.GetAetheryteById(aetheryteId)
	local pos = FFXIVLib.API.Map.GetAetheryteLocation(aetheryteId)
	local mapId = row and row.TerritoryId or tonumber(aetheryte.territory)
	if not mapId or not table.valid(pos) then return nil end

	local nextPos = ml_nav_manager.GetNextPathPos(pos, mapId, destinationMapId)
	if table.valid(nextPos) then return aetheryte end
	return nil
end

-- Last-resort hubs used when the normal aetheryte route lookup has no answer.
function FFXIVMinionMap.GetFallbackTravelAetheryte(destinationMapId, aetherytes)
	if destinationMapId == 820 then
		-- Eulmore Aetheryte Plaza -> Eulmore
		local aetheryte = FFXIVMinionMap._TryFallbackTravel(aetherytes, 134, destinationMapId)
		if aetheryte then return aetheryte end

		-- Wright -> Eulmore, before the Eulmore crystal is unlocked
		if not FFXIVLib.API.Map.CanUseAetheryte(134) then
			aetheryte = FFXIVMinionMap._TryFallbackTravel(aetherytes, 138, destinationMapId)
			if aetheryte then return aetheryte end
		end
	end

	-- The Crystarium Aetheryte Plaza
	local aetheryte = FFXIVMinionMap._TryFallbackTravel(aetherytes, 133, destinationMapId)
	if aetheryte then return aetheryte end
	-- Ishgard Aetheryte Plaza
	aetheryte = FFXIVMinionMap._TryFallbackTravel(aetherytes, 70, destinationMapId)
	if aetheryte then return aetheryte end
	-- Yedlihmad, for walking into Radz-at-Han before its crystal is unlocked
	aetheryte = FFXIVMinionMap._TryFallbackTravel(aetherytes, 169, destinationMapId)
	if aetheryte then return aetheryte end
	-- Idyllshire Aetheryte Plaza
	aetheryte = FFXIVMinionMap._TryFallbackTravel(aetherytes, 75, destinationMapId)
	if aetheryte then return aetheryte end
	-- Tuliyollal Aetheryte Plaza
	return FFXIVMinionMap._TryFallbackTravel(aetherytes, 216, destinationMapId)
end

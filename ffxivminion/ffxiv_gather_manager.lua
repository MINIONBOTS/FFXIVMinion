-- Gathermanager for adv. gathering customization
GatherMgr = { }
GatherMgr.version = "v0.1";
GatherMgr.infopath = GetStartupPath() .. [[\Navigation\]];
GatherMgr.mainwindow = { name = strings[gCurrentLanguage].gatherManager, x = 450, y = 50, w = 250, h = 350}
GatherMgr.visible = false

function GatherMgr.ModuleInit() 	
        
    GUI_NewWindow(GatherMgr.mainwindow.name,GatherMgr.mainwindow.x,GatherMgr.mainwindow.y,GatherMgr.mainwindow.w,GatherMgr.mainwindow.h)
    GUI_NewCheckbox(GatherMgr.mainwindow.name,strings[gCurrentLanguage].activated,"gGMactive",strings[gCurrentLanguage].generalSettings)
    
    --mining menu
    GUI_NewComboBox(GatherMgr.mainwindow.name,strings[gCurrentLanguage].selectMarker,"gMiningSpot",strings[gCurrentLanguage].mining,"None")
    GUI_NewField(GatherMgr.mainwindow.name,strings[gCurrentLanguage].selectItem1,"gMiningItem1",strings[gCurrentLanguage].mining)
    GUI_NewField(GatherMgr.mainwindow.name,strings[gCurrentLanguage].selectItem2,"gMiningItem2",strings[gCurrentLanguage].mining)
    GUI_NewNumeric(GatherMgr.mainwindow.name,strings[gCurrentLanguage].gatherTime,"gMiningTime",strings[gCurrentLanguage].mining,"0","7200")
    
    GUI_NewComboBox(GatherMgr.mainwindow.name,strings[gCurrentLanguage].selectMarker,"gBotanySpot",strings[gCurrentLanguage].botany,"None")
    GUI_NewField(GatherMgr.mainwindow.name,strings[gCurrentLanguage].selectItem1,"gBotanyItem1",strings[gCurrentLanguage].botany)
    GUI_NewField(GatherMgr.mainwindow.name,strings[gCurrentLanguage].selectItem2,"gBotanyItem2",strings[gCurrentLanguage].botany)
    GUI_NewNumeric(GatherMgr.mainwindow.name,strings[gCurrentLanguage].gatherTime,"gBotanyTime",strings[gCurrentLanguage].botany,"0","7200")
    
    GUI_NewComboBox(GatherMgr.mainwindow.name,strings[gCurrentLanguage].selectMarker,"gFishingSpot",strings[gCurrentLanguage].fishing,"None")
    GUI_NewField(GatherMgr.mainwindow.name,strings[gCurrentLanguage].baitName,"gBaitName",strings[gCurrentLanguage].fishing)
    GUI_NewNumeric(GatherMgr.mainwindow.name,strings[gCurrentLanguage].gatherTime,"gFishingTime",strings[gCurrentLanguage].fishing,"0","7200")

    if (gBaitName == nil) then
        gBaitName = ""
    end
    
    gMiningTime = "900"
    gBotanyTime = "900"
    
    if (Settings.FFXIVMINION.gGMactive == nil) then
        Settings.FFXIVMINION.gGMactive = "1"
    end
    gGMactive = Settings.FFXIVMINION.gGMactive
    
    GUI_UnFoldGroup(GatherMgr.mainwindow.name, strings[gCurrentLanguage].generalSettings)
    GUI_WindowVisible(GatherMgr.mainwindow.name,false)
end

function GatherMgr.UpdateMarkerLists()
    -- setup markers
    local miningMarkers = "None"
    local gatherList = mm.MarkerList["miningSpot"]
    for key, pos in pairs(gatherList) do
        miningMarkers = miningMarkers..","..key
    end
    
    local botanyMarkers = "None"
    gatherList = mm.MarkerList["botanySpot"]
    for key, pos in pairs(gatherList) do
        botanyMarkers = botanyMarkers..","..key 
    end
    
    local fishingMarkers = "None"
    local gatherList = mm.MarkerList["fishingSpot"]
    for key, pos in pairs(gatherList) do
        fishingMarkers = fishingMarkers..","..key 
    end

    gMiningSpot_listitems = miningMarkers
    gBotanySpot_listitems = botanyMarkers
    gFishingSpot_listitems = fishingMarkers
    
    gMiningSpot = "None"
    gMiningItem1 = "None"
    gMiningItem2 = "None"
    gBotanySpot = "None"
    gBotanyItem1 = "None"
    gBotanyItem2 = "None"
    gFishingSpot = "None"
    gFishingBait = "None"
end

function GatherMgr.UpdateMarkerInfo(markerType, markerName)
    local markerInfo = mm.GetMarkerInfo(markerName)
    if (markerInfo ~= nil and markerInfo ~= 0) then
        local data = GatherMgr.GetMarkerData(markerName)
        local time = GatherMgr.GetMarkerTime(markerName)
        
        if(markerType == "miningSpot") then
            if(data ~= nil and data ~= 0) then
                gMiningItem1 = data[1]
                gMiningItem2 = data[2]
            else
                gMiningItem1 = "None"
                gMiningItem2 = "None"
            end
            
            if(time ~= nil and time ~= "") then
                gMiningTime = time
            else
                gMiningTime = "300"
            end
        elseif(markerType == "botanySpot") then
            if(data ~= nil and data ~= 0) then
                gBotanyItem1 = data[1]
                gBotanyItem2 = data[2]
            else
                gBotanyItem1 = "None"
                gBotanyItem2 = "None"
            end
            
            if(time ~= nil and time ~= "") then
                gBotanyTime = time
            else
                gBotanyTime = "300"
            end
        elseif(markerType == "fishingSpot") then
            if(data ~= nil and data ~= 0) then
                gBaitName = data[1]
            else
                gBaitName = "None"
            end
            
            if(time ~= nil and time ~= "") then
                gFishingTime = time
            else
                gFishingTime = "300"
            end
        end
    end
end

function GatherMgr.WriteMarkerInfo(markerType, markerName)
    if (markerName ~= "" and markerName ~= "nil") then
        local data = {}
        local time = nil
        if(markerType == "miningSpot") then
            data[1] = gMiningItem1
            data[2] = gMiningItem2
            time = tonumber(gMiningTime)
        elseif (markerType == "botanySpot") then
            data[1] = gBotanyItem1
            data[2] = gBotanyItem2
            time = tonumber(gBotanyTime)
        elseif (markerType == "fishingSpot") then
            data = {gBaitName}
            time = tonumber(gFishingTime)
        end
        
        if (data ~= nil and data ~= 0) then
            mm.SetMarkerData(markerName,data)
            mm.SetMarkerTime(markerName,time)
            return true
        end
    end
    
    return false
end

function GatherMgr.GetNextMarker(currentMarker, previousMarker)
    local markerType
    if (currentMarker ~= nil) then
        for tag, posList in pairs(mm.MarkerList) do
            if posList[currentMarker] ~= nil then
                markerType = tag
            end
        end
    else
        if (Player.job == FFXIV.JOBS.BOTANIST) then
            markerType = "botanySpot"
        elseif (Player.job == FFXIV.JOBS.MINER) then
            markerType = "miningSpot"
        elseif (Player.job == FFXIV.JOBS.FISHER) then
            markerType = "fishingSpot"
        else
            markerType = "grindSpot"
        end
    end
    
    local list = {}
    
    if (markerType == "miningSpot" and gChangeJobs) then
		for k,v in pairs(mm.MarkerList["miningSpot"]) do list[k] = v end
    elseif ( markerType == "botanySpot" and gChangeJobs ) then
		for k,v in pairs(mm.MarkerList["botanySpot"]) do list[k] = v end
    else
        list = mm.MarkerList[markerType]
    end
    
    if (TableSize(list) == 0) then
        return nil
    end
    
    -- if we only have one marker then we just return it
    if (TableSize(list) == 1) then
        local name, marker = next(list)
		if ((Player.level >= marker.minlevel and Player.level <= marker.maxlevel) or gIgnoreGrindLvl == "1") then
			return name
		else
			return nil
		end
    end
    
    -- if we only have two markers we choose the other one
	-- Changed this to take into account level ranges, otherwise you end up running into problems if you only have 2 markers in a given area like 20 and 50.
    if (TableSize(list) == 2) then
        for name, marker in pairs(list) do
            if (name ~= currentMarker and ((Player.level >= marker.minlevel and Player.level <= marker.maxlevel) or gIgnoreGrindLvl == "1")) then
                return name
			else
				return currentMarker
            end
        end
    end
    
    local currMarker = currentMarker or ""
    local prevMarker = previousMarker or ""
    
    -- otherwise grab the next marker based on randomization or closest distance
    local closestMarker = nil
    local closestDistance = 99999999
    if gRandomMarker == "0" then
        for name, marker in pairs(list) do
            local myPos = Player.pos
            local distance = Distance2D(myPos.x, myPos.z, marker.x, marker.z)
            if (closestMarker == nil or distance < closestDistance and name ~= currMarker and name ~= prevMarker) then
                if  (markerType == "grindSpot" and ((Player.level >= marker.minlevel and Player.level <= marker.maxlevel) or gIgnoreGrindLvl == "1")) or
                    (markerType == "fishingSpot" and ((Player.level >= marker.minlevel and Player.level <= marker.maxlevel) or gIgnoreFishLvl == "1")) or
                    ((markerType == "botanySpot" or markerType == "miningSpot") and ((Player.level >= marker.minlevel and Player.level <= marker.maxlevel) or gIgnoreGatherLvl == "1"))
                then
                    closestMarker = name
                    closestDistance = distance
                end
            end
        end
    else		
        local rnd = math.random(1,TableSize(list))
        local index = 1
        for name,info in pairs(list) do
            if rnd == index then				
                closestMarker = name
            end
            index = index + 1
        end
    end
    
    return closestMarker
end

function GatherMgr.GetMarkerData(markerName)
    local markerInfo = mm.GetMarkerInfo(markerName)
    if (markerInfo ~= nil and markerInfo ~= 0) then
        return markerInfo.data
    end
    
    return nil
end

function GatherMgr.GetMarkerTime(markerName)
    local markerInfo = mm.GetMarkerInfo(markerName)
    if (markerInfo ~= nil and markerInfo ~= 0) then
        return markerInfo.time
    end
    
    return nil
end


function GatherMgr.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        --d(tostring(k).." = "..tostring(v))
        if ( k == "gGMactive") then			
            Settings.FFXIVMINION[tostring(k)] = v
        elseif (k == "gMiningSpot") then
            GatherMgr.UpdateMarkerInfo("miningSpot",v)
        elseif (k == "gBotanySpot") then
            GatherMgr.UpdateMarkerInfo("botanySpot",v)
        elseif (k == "gFishingSpot") then
            GatherMgr.UpdateMarkerInfo("fishingSpot",v)
        elseif (k == "gMiningItem1" or k == "gMiningItem2" or k == "gMiningTime") then
            GatherMgr.WriteMarkerInfo("miningSpot",gMiningSpot)
        elseif (k == "gBotanyItem1" or k == "gBotanyItem2" or k == "gBotanyTime") then
            GatherMgr.WriteMarkerInfo("botanySpot",gBotanySpot)
        elseif (k == "gBaitName" or k == "gFishingTime") then
            GatherMgr.WriteMarkerInfo("fishingSpot",gFishingSpot)
        end
    end
end

function GatherMgr.ToggleMenu()
    if (GatherMgr.visible) then
        GUI_WindowVisible(GatherMgr.mainwindow.name,false)	
        GatherMgr.visible = false
    else
        local wnd = GUI_GetWindowInfo("FFXIVMinion")
        GUI_MoveWindow( GatherMgr.mainwindow.name, wnd.x+wnd.width,wnd.y) 
        GUI_WindowVisible(GatherMgr.mainwindow.name,true)	
        GatherMgr.visible = true
    end
end


GatherMgr.MiningItems =
{
    "Alumina Salts",				-- = "id",
    "Aqueous Whetstone",			-- = "id",
    "Alumen",                       -- = "id",
    "Animal Glue",					-- = "id",
    "Amber",						-- = "id",
    "Amethyst",						-- = "id",
    "Aquamarine",					-- = "id",
    "Astral Moraine",				-- = "id",
    "Astral Rock",					-- = "id",
    "Black Pearl",					-- = "id",
    "Blue Pigment",                 -- = "id",
    "Brimstone",                    -- = "id",
    "Bomb Ash",                     -- = "id",
    "Bone Chip",                    -- = "id",
    "Brown Pigment",                -- = "id",
    "Black Quartz",					-- = "id",
    "Blue Quartz",					-- = "id",
    "Black Mor Dhona Slag",			-- = "id",
    "Black O'Ghomoro Slag",			-- = "id",
    "Black Sagolii Slag",			-- = "id",
    "Black Tinolqa Slag",			-- = "id",
    "Blue Abalathia Slag",			-- = "id",
    "Brown Abalathia Slag",			-- = "id",
    "Brown O'Ghomoro Slag",			-- = "id",
    "Brown Sagolii Slag",			-- = "id",
    "Brown Tinolqa Slag",			-- = "id",
    "Cinnabar",                     -- = "id",
    "Cobalt Ore",					-- = "id",
    "Copper Ore",                   -- = "id",
    "Copper Sand",                  -- = "id",
    "Copper Dust",					-- = "id",
    "Danburite",					-- = "id",
    "Darksteel Ore",				-- = "id",
    "Diamond",						-- = "id",
    "Dragon Obsidian",				-- = "id",
    "Earth Moraine",				-- = "id",
    "Earth Crystal",              	-- = "id",
    "Earth Rock",                   -- = "id",
    "Earth Shard",                  -- = "id",
    "Effervescent Water",           -- = "id",
    "Electrum Ore",					-- = "id",
    "Emerald",						-- = "id",
    "Fire Moraine",					-- = "id",
    "Fire Crystal",                 -- = "id",
    "Fire Rock",                    -- = "id",
    "Fire Shard",                   -- = "id",
    "Fine Sand",					-- = "id",
    "Fluorite",						-- = "id",
    "Flint Stone",					-- = "id",
    "Grade 1 Carbonized Matter",    -- = "id",
    "Grade 2 Carbonized Matter",    -- = "id",
    "Green Pigment",                -- = "id",
    "Green Quartz",					-- = "id",
    "Grenade Ash",					-- = "id",
    "Grey Pigment",                 -- = "id",
    "Garnet",						-- = "id",
    "Goshenite",					-- = "id",
    "Gold Dust",					-- = "id",
    "Gold Ore",						-- = "id",
    "Gold Sand",					-- = "id",
    "Heliodor",						-- = "id",
    "Ice Moraine",					-- = "id",
    "Iolite",						-- = "id",
    "Ice Crystal",                  -- = "id",
    "Ice Rock",                     -- = "id",
    "Ice Shard",                    -- = "id",
    "Iron Ore",                     -- = "id",
    "Iron Sand",                    -- = "id",
    "Indigo Quartz",				-- = "id",
    "Jade",							-- = "id",
    "Jadeite",						-- = "id",			
    "Lapis Lazuli",					-- = "id",
    "Lightning Moraine",			-- = "id",
    "Lightning Crystal",            -- = "id",
    "Lightning Rock",               -- = "id",
    "Lightning Shard",              -- = "id",
    "Light Kidney Ore",				-- = "id",
    "Limonite",						-- = "id",
    "Limestone",					-- = "id",
    "Muddy Water",                  -- = "id",
    "Mudstone",                     -- = "id",
    "Mudstone Whetstone",			 -- = "id",
    "Miser's Mythril",				-- = "id",
    "Mythril Ore",					-- = "id",
    "Malachite",					-- = "id",
    "Nephrite",						-- = "id",
    "Obsidian",                     -- = "id",
    "Purple Pigment",               -- = "id",
    "Pearl",						-- = "id",	
    "Peridot",						-- = "id",
    "Peacock Ore",					-- = "id",
    "Platinum Ore",					-- = "id",
    "Pyrite",						-- = "id",
    "Ragstone",                     -- = "id",
    "Ragstone Whetstone",			-- = "id",
    "Raw Danburite",                -- = "id",
    "Raw Fluorite",                 -- = "id",
    "Raw Malachite",                -- = "id",
    "Raw Sphene",                   -- = "id",
    "Raw Sunstone",                 -- = "id",
    "Red Pigment",                  -- = "id",
    "Rock Salt",                    -- = "id",
    "Raw Amber",					-- = "id",
    "Raw Amethyst",					-- = "id",
    "Raw Aquamarine",				-- = "id",
    "Raw Diamond",					-- = "id",
    "Raw Emerald",					-- = "id",
    "Raw Garnet",					-- = "id",
    "Raw Goshenite",				-- = "id",
    "Raw Heliodor",					-- = "id",
    "Raw Iolite",					-- = "id",
    "Raw Lapis Lazuli",				-- = "id",	
    "Raw Peridot",					-- = "id",
    "Raw Rubellite",				-- = "id",
    "Raw Ruby",						-- = "id",
    "Raw Sapphire",					-- = "id",
    "Raw Spinel",					-- = "id",
    "Raw Topaz",					-- = "id",
    "Raw Tourmaline",				-- = "id",
    "Raw Turquoise",				-- = "id",
    "Raw Zircon",					-- = "id",
    "Radiant Earth Moraine",		-- = "id",
    "Radiant Fire Moraine",			-- = "id",
    "Radiant Ice Moraine",			-- = "id",
    "Radiant Lightning Moraine",	-- = "id",
    "Radiant Water Moraine",		-- = "id",
    "Radiant Wind Moraine",			-- = "id",
    "Rubellite",					-- = "id"
    "Red Quartz",					-- = "id"
    "River Sand",					-- = "id"
    "Ruby",							-- = "id"
    "Sea Sand",						-- = "id"
    "Silex",                        -- = "id",
    "Siltstone",                    -- = "id",
    "Siltstone Whetstone",			-- = "id",
    "Silver Dust",					-- = "id",
    "Silver Leaf",					-- = "id",
    "Silver Ore",                   -- = "id",
    "Silver Sand",                  -- = "id",
    "Soiled Femur",                 -- = "id",
    "Sunrise Tellin",               -- = "id",
    "Sapphire",						-- = "id"
    "Sphene",						-- = "id"
    "Spinel",						-- = "id"
    "Sunstone",						-- = "id"
    "Stiperstone",					-- = "id"
    "Tin Ore",                      -- = "id",
    "Topaz",						-- = "id"
    "Tourmaline",					-- = "id"
    "Turquoise",					-- = "id"
    "Umbral Moraine",				-- = "id"
    "Uncultured Pearl",				-- = "id"
    "Violet Quartz",				-- = "id"
    "Water Crystal",                -- = "id",
    "Water Rock",                   -- = "id",
    "Water Shard",                  -- = "id",
    "White Quartz",					-- = "id",
    "Wind Crystal",                 -- = "id",
    "Water Moraine",				-- = "id"
    "Water Rock",					-- = "id"
    "Wind Moraine",					-- = "id"
    "Wind Rock",					-- = "id"	
    "Wind Shard",                   -- = "id",
    "Wyvern Obsidian",              -- = "id",
    "Wyrm Obsidian",				-- = "id",
    "Yellow Pigment",               -- = "id",
    "Yellow Quartz",				-- = "id",
    "Zinc Ore",                     -- = "id"
    "Zircon"						-- = "id"
}                                     
                                     
GatherMgr.BotanyItems =              
{                                    
    "Allagan Snail",                -- = "id",
    "Alpine Parsnip",               -- = "id",
    "Ash Branch",                   -- = "id",
    "Ash Log",                      -- = "id",
    "Beehive Chip",                 -- = "id",
    "Belladonna",                   -- = "id",
    "Black Pepper",                 -- = "id",
    "Buffalo Beans",                -- = "id",
    "Carnation",                    -- = "id",
    "Chanterelle",                  -- = "id",
    "Cieldalaes Spinach",           -- = "id",
    "Cinderfoot Olive",             -- = "id",
    "Cinnamon",                     -- = "id",
    "Cloves",                       -- = "id",
    "Cock Feather",                 -- = "id",
    "Cotton Boll",                  -- = "id",
    "Crow Feather",                 -- = "id",
    "Earth Shard",                  -- = "id",
    "Elm Log",                      -- = "id",
    "Faerie Apple",                 -- = "id",
    "Fire Shard",                   -- = "id",
    "Galago Mint",                  -- = "id",
    "Garlean Garlic",               -- = "id",
    "Gil Bun",                      -- = "id",
    "Grade 1 Carbonized Matter",    -- = "id",
    "Grade 1 Dark Matter",          -- = "id",
    "Grade 2 Dark Matter",          -- = "id",
    "Grade 3 Dark Matter",          -- = "id",
    "Gridanian Chestnut",           -- = "id",
    "Gridanian Walnut",             -- = "id",
    "Highland Parsley",             -- = "id",
    "Ice Crystal",                  --  = "id",
    "Ice Shard",                    -- = "id",
    "Kukuru Bean",                  -- = "id",
    "La Noscean Lettuce",           -- = "id",
    "La Noscean Orange",            -- = "id",
    "Lalafellin Lentil",            -- = "id",
    "Latex",                        -- = "id",
    "Lavender",                     -- = "id",
    "Lightning Shard",              -- = "id",
    "Lowland Grapes",               -- = "id",
    "Maple Branch",                 -- = "id",
    "Maple Log",                    -- = "id",
    "Maple Sap",                    -- = "id",
    "Marjoram",                     -- = "id",
    "Matron's Mistletoe",           -- = "id",
    "Millioncorn",                  -- = "id",
    "Ogre Pumpkin",                 -- = "id",
    "Paprika",                      -- = "id",
    "Popoto",                       --  = "id",
    "Ruby Tomato",                  -- = "id",
    "Straw",                        -- = "id",
    "Sunset Wheat",                 -- = "id",
    "Tinolqa Mistletoe",            -- = "id",
    "Tree Toad",                    -- = "id",
    "Vanilla Beans",                -- = "id",
    "Walnut Log",                   -- = "id",
    "Water Shard",                  -- = "id",
    "White Scorpion",               -- = "id",
    "Wild Onion",                   -- = "id",
    "Wind Shard",                   -- = "id",
    "Yellow Ginseng",               -- = "id",
    "Yew Branch",                   -- = "id",
    "Yew Log"                       -- = "id"
}                         
          
RegisterEventHandler("ToggleGathermgr", GatherMgr.ToggleMenu)
RegisterEventHandler("GUI.Update",GatherMgr.GUIVarUpdate)
RegisterEventHandler("Module.Initalize",GatherMgr.ModuleInit)

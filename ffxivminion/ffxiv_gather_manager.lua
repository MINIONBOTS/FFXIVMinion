-- Gathermanager for adv. gathering customization
GatherMgr = { }
GatherMgr.version = "v0.1";
GatherMgr.infopath = GetStartupPath() .. [[\Navigation\]];
GatherMgr.mainwindow = { name = strings[gCurrentLanguage].gatherManager, x = 450, y = 50, w = 350, h = 350}

function GatherMgr.ModuleInit() 	
		
	GUI_NewWindow(GatherMgr.mainwindow.name,GatherMgr.mainwindow.x,GatherMgr.mainwindow.y,GatherMgr.mainwindow.w,GatherMgr.mainwindow.h)
	GUI_NewCheckbox(GatherMgr.mainwindow.name,strings[gCurrentLanguage].activated,"gGMactive",strings[gCurrentLanguage].generalSettings)
    
    --mining menu
	GUI_NewComboBox(GatherMgr.mainwindow.name,strings[gCurrentLanguage].selectMarker,"gMiningSpot",strings[gCurrentLanguage].mining,"None")
	GUI_NewComboBox(GatherMgr.mainwindow.name,strings[gCurrentLanguage].selectItem,"gMiningItem",strings[gCurrentLanguage].mining,"None")
    GUI_NewNumeric(GatherMgr.mainwindow.name,strings[gCurrentLanguage].gatherTime,"gMiningTime",strings[gCurrentLanguage].mining,"0","7200")
    
    GUI_NewComboBox(GatherMgr.mainwindow.name,strings[gCurrentLanguage].selectMarker,"gBotanySpot",strings[gCurrentLanguage].botany,"None")
	GUI_NewComboBox(GatherMgr.mainwindow.name,strings[gCurrentLanguage].selectItem,"gBotanyItem",strings[gCurrentLanguage].botany,"None")
    GUI_NewNumeric(GatherMgr.mainwindow.name,strings[gCurrentLanguage].gatherTime,"gBotanyTime",strings[gCurrentLanguage].botany,"0","7200")
    
    GUI_NewComboBox(GatherMgr.mainwindow.name,strings[gCurrentLanguage].selectMarker,"gFishingSpot",strings[gCurrentLanguage].fishing,"None")
	--GUI_NewComboBox(GatherMgr.mainWindow.name,strings[gCurrentLanguage].selectBait,"gFishingBait",strings[gCurrentLanguage].fishing,"None")
    GUI_NewField(GatherMgr.mainwindow.name,strings[gCurrentLanguage].baitName,"gBaitName",strings[gCurrentLanguage].fishing)
    GUI_NewNumeric(GatherMgr.mainwindow.name,strings[gCurrentLanguage].gatherTime,"gFishingTime",strings[gCurrentLanguage].fishing,"0","7200")
    --local fishingBait = "None"
    --for name,id in pairs(GatherMgr.BotanyItems) do
    --  botanyItems = botanyItems..","..name
    --end
    --gBotanyItem_listitems = botanyItems
    if (gBaitName == nil) then
        gBaitName = ""
    end
    
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
	gMiningItem = "None"
	gBotanySpot = "None"
	gBotanyItem = "None"
	gFishingSpot = "None"
	gFishingBait = "None"
	
	if (miningMarkers ~= "None") then
		local miningItems = "None"
		for name,id in pairs(GatherMgr.MiningItems) do
			miningItems = miningItems..","..name
		end
		gMiningItem_listitems = miningItems
	else
		gMiningItem_listitems = "None"
	end
	
	if (botanyMarkers ~= "None") then
		local botanyItems = "None"
		for name,id in pairs(GatherMgr.BotanyItems) do
			botanyItems = botanyItems..","..name
		end
		gBotanyItem_listitems = botanyItems
	else
		gBotanyItem_listitems = "None"
	end
end

function GatherMgr.UpdateMarkerInfo(markerType, markerName)
    local markerInfo = mm.GetMarkerInfo(markerName)
    if (markerInfo ~= nil and markerInfo ~= {}) then
        local data = GatherMgr.GetMarkerData(markerName)
        local time = GatherMgr.GetMarkerTime(markerName)
		
		if(markerType == "miningSpot") then
			if(data ~= nil and data ~= "") then
				gMiningItem = data
			else
				gMiningItem = "None"
			end
			
			if(time ~= nil and time ~= "") then
				gMiningTime = time
			else
				gMiningTime = 0
			end
		elseif(markerType == "botanySpot") then
			if(data ~= nil and data ~= "") then
				gBotanyItem = data
			else
				gBotanyItem = "None"
			end
			
			if(time ~= nil and time ~= "") then
				gBotanyTime = time
			else
				gBotanyTime = 0
			end
		elseif(markerType == "fishingSpot") then
			if(data ~= nil and data ~= "") then
				gFishingItem = data
			else
				gFishingItem = "None"
			end
			
			if(time ~= nil and time ~= "") then
				gFishingTime = time
			else
				gFishingTime = 0
			end
		end
    end
end

function GatherMgr.WriteMarkerInfo(markerType, markerName)
    if (markerName ~= "" and markerName ~= "nil") then
        local data = nil
		local time = nil
        if(markerType == "miningSpot") then
            data = gMiningItem
			time = tonumber(gMiningTime)
        elseif (markerType == "botanySpot") then
            data = gBotanyItem
			time = tonumber(gBotanyTime)
        elseif (markerType == "fishingSpot") then
            data = gFishingBait
			time = tonumber(gFishingTime)
        end
        
        if (data ~= nil and data ~= "") then
            mm.SetMarkerData(markerName,data)
			mm.SetMarkerTime(markerName,time)
            return true
        end
    end
    
    return false
end

function GatherMgr.GetMarkerData(markerName)
    local markerInfo = mm.GetMarkerInfo(markerName)
    if (markerInfo ~= nil and markerInfo ~= {}) then
        return markerInfo.data
    end
    
    return nil
end

function GatherMgr.GetMarkerTime(markerName)
    local markerInfo = mm.GetMarkerInfo(markerName)
    if (markerInfo ~= nil and markerInfo ~= {}) then
        return markerInfo.time
    end
    
    return nil
end

function GatherMgr.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		--d(tostring(k).." = "..tostring(v))
		if ( k == "gGMactive") then			
			Settings.GW2MINION[tostring(k)] = v
        elseif (k == "gMiningSpot") then
            GatherMgr.UpdateMarkerInfo("miningSpot",v)
        elseif (k == "gBotanySpot") then
            GatherMgr.UpdateMarkerInfo("botanySpot",v)
        elseif (k == "gFishingSpot") then
            GatherMgr.UpdateMarkerInfo("fishingSpot",v)
        elseif (k == "gMiningItem" or k == "gMiningTime") then
            GatherMgr.WriteMarkerInfo("miningSpot",gMiningSpot)
        elseif (k == "gBotanySpot" or k == "gBotanyTime") then
            GatherMgr.WriteMarkerInfo("botanySpot",gBotanySpot)
        elseif (k == "gFishingSpot" or k == "gFishingTime") then
            GatherMgr.WriteMarkerInfo("fishingSpot",gFishingSpot)
		end
	end
end

function GatherMgr.ToggleMenu()
	if (GatherMgr.visible) then
		GUI_WindowVisible(GatherMgr.mainwindow.name,false)	
		GatherMgr.visible = false
	else
		--local wnd = GUI_GetWindowInfo("GW2Minion")	 
		GUI_WindowVisible(GatherMgr.mainwindow.name,true)	
		GatherMgr.visible = true
	end
end

GatherMgr.MiningItems =
{
    ["Alumen"]                        = "id",
    ["Blue Pigment"]                  = "id",
    ["Brimstone"]                     = "id",
    ["Bomb Ash"]                      = "id",
    ["Bone Chip"]                     = "id",
    ["Brown Pigment"]                 = "id",
    ["Cinnabar"]                      = "id",
    ["Copper Ore"]                    = "id",
    ["Copper Sand"]                   = "id",
    ["Earth Crystal"]                 = "id",
    ["Earth Rock"]                    = "id",
    ["Earth Shard"]                   = "id",
    ["Effervescent Water"]            = "id",
    ["Fire Crystal"]                  = "id",
    ["Fire Rock"]                     = "id",
    ["Fire Shard"]                    = "id",
    ["Grade 1 Carbonized Matter"]     = "id",
    ["Grade 2 Carbonized Matter"]     = "id",
    ["Green Pigment"]                 = "id",
    ["Grey Pigment"]                  = "id",
    ["Ice Crystal"]                   = "id",
    ["Ice Rock"]                      = "id",
    ["Ice Shard"]                     = "id",
    ["Iron Ore"]                      = "id",
    ["Iron Sand"]                     = "id",
    ["Lightning Crystal"]             = "id",
    ["Lightning Rock"]                = "id",
    ["Lightning Shard"]               = "id",
    ["Muddy Water"]                   = "id",
    ["Mudstone"]                      = "id",
    ["Obsidian"]                      = "id",
    ["Purple Pigment"]                = "id",
    ["Ragstone"]                      = "id",
    ["Raw Danburite"]                 = "id",
    ["Raw Fourite"]                   = "id",
    ["Raw Malachite"]                 = "id",
    ["Raw Sphere"]                    = "id",
    ["Raw Sunstone"]                  = "id",
    ["Red Pigment"]                   = "id",
    ["Rock Salt"]                     = "id",
    ["Silex"]                         = "id",
    ["Siltstone"]                     = "id",
    ["Silver Ore"]                    = "id",
    ["Silver Sand"]                   = "id",
    ["Soiled Femur"]                  = "id",
    ["Sunrise Tellin"]                = "id",
    ["Tin Ore"]                       = "id",
    ["Water Crystal"]                 = "id",
    ["Water Rock"]                    = "id",
    ["Water Shard"]                   = "id",
    ["Wind Crystal"]                  = "id",
    ["Wind Shard"]                    = "id",
    ["Wyvern Obsidian"]               = "id",
    ["Yellow Pigment"]                = "id",
    ["Zinc Ore"]                      = "id"
}

GatherMgr.BotanyItems = 
{
	["Allagan Snail"]                = "id",
	["Alpine Parsnip"]               = "id",
	["Ash Branch"]                   = "id",
	["Ash Log"]                      = "id",
	["Beehive Chip"]                 = "id",
	["Belladonna"]                   = "id",
	["Black Pepper"]                 = "id",
	["Buffalo Beans"]                = "id",
	["Carnation"]                    = "id",
	["Chanterelle"]                  = "id",
	["Cieldalaes Spinach"]           = "id",
	["Cinderfoot Olive"]             = "id",
	["Cinnamon"]                     = "id",
	["Cloves"]                        = "id",
	["Cock Feather"]                 = "id",
	["Cotton Boll"]                  = "id",
	["Crow Feather"]                 = "id",
	["Earth Shard"]                  = "id",
	["Elm Log"]                      = "id",
	["Faerie Apple"]                 = "id",
	["Fire Shard"]                   = "id",
	["Galago Mint"]                  = "id",
	["Garlean Garlic"]               = "id",
	["Gil Bun"]                      = "id",
	["Grade 1 Carbonized Matter"]    = "id",
	["Grade 1 Dark Matter"]          = "id",
	["Grade 2 Dark Matter"]          = "id",
	["Grade 3 Dark Matter"]          = "id",
	["Gridanian Chestnut"]           = "id",
	["Gridanian Walnut"]             = "id",
	["Highland Parsley"]             = "id",
	["Ice Crystal"]                   = "id",
	["Ice Shard"]                    = "id",
	["Kukuru Bean"]                  = "id",
	["La Noscean Lettuce"]           = "id",
	["La Noscean Orange"]            = "id",
	["Lalafellin Lentil"]            = "id",
	["Latex"]                        = "id",
	["Lavender"]                     = "id",
	["Lightning Shard"]              = "id",
	["Lowland Grapes"]               = "id",
	["Maple Branch"]                 = "id",
	["Maple Log"]                    = "id",
	["Maple Sap"]                    = "id",
	["Marjoram"]                     = "id",
	["Matron's Mistletoe"]           = "id",
	["Millioncorn"]                  = "id",
	["Ogre Pumpkin"]                 = "id",
	["Paprika"]                      = "id",
	["Popoto"]                        = "id",
	["Ruby Tomato"]                  = "id",
	["Straw"]                        = "id",
	["Sunset Wheat"]                 = "id",
	["Tinolqa Mistletoe"]            = "id",
	["Tree Toad"]                    = "id",
	["Vanilla Beans"]                = "id",
	["Walnut Log"]                   = "id",
	["Water Shard"]                  = "id",
	["White Scorpion"]               = "id",
	["Wild Onion"]                   = "id",
	["Wind Shard"]                   = "id",
	["Yellow Ginseng"]               = "id",
	["Yew Branch"]                   = "id",
	["Yew Log"]                      = "id"
}                                   

RegisterEventHandler("ToggleGathermgr", GatherMgr.ToggleMenu)
RegisterEventHandler("GUI.Update",GatherMgr.GUIVarUpdate)
RegisterEventHandler("Module.Initalize",GatherMgr.ModuleInit)

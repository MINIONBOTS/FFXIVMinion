-- Main config file of GW2Minion

wt_radar = {}
wt_radar.MainWindow = { Name = "Radar", x=250, y=200 , width=200, height=200 }
wt_radar.visible = false

function wt_radar.OnUpdate( event, tickcount )
    
end

-- Module Event Handler
function wt_radar.HandleInit()	
    GUI_SetStatusBar("Initalizing FFXIV Radar...")
        
    if ( Settings.FFXIVMINION.gRadar == nil ) then
        Settings.FFXIVMINION.gRadar = "0"
    end		
    if ( Settings.FFXIVMINION.g2dRadar == nil ) then
        Settings.FFXIVMINION.g2dRadar = "0"
    end	
    if ( Settings.FFXIVMINION.g3dRadar == nil ) then
        Settings.FFXIVMINION.g3dRadar = "0"
    end	
    if ( Settings.FFXIVMINION.g2dRadarFullScreen == nil ) then
        Settings.FFXIVMINION.g2dRadarFullScreen = "0"
    end	
    if ( Settings.FFXIVMINION.gRadarShowNode == nil ) then
        Settings.FFXIVMINION.gRadarShowNode = "0"
    end		
    if ( Settings.FFXIVMINION.gRadarShowPlayers == nil ) then
        Settings.FFXIVMINION.gRadarShowPlayers = "0"
    end	
    if ( Settings.FFXIVMINION.gRadarShowBattleNPCs == nil ) then
        Settings.FFXIVMINION.gRadarShowBattleNPCs = "0"
    end	
    if ( Settings.FFXIVMINION.gRadarShowEventNPCs == nil ) then
        Settings.FFXIVMINION.gRadarShowEventNPCs = "0"
    end	
    if ( Settings.FFXIVMINION.gRadarShowEventObjs == nil ) then
        Settings.FFXIVMINION.gRadarShowEventObjs = "0"
    end	
    if ( Settings.FFXIVMINION.gRadarShowAetherytes == nil ) then
        Settings.FFXIVMINION.gRadarShowAetherytes = "0"
    end	
    if ( Settings.FFXIVMINION.gRadarX == nil ) then
        Settings.FFXIVMINION.gRadarX = -1.0
    end		
    if ( Settings.FFXIVMINION.gRadarY == nil ) then
        Settings.FFXIVMINION.gRadarY = -1.0
    end	
    if ( Settings.FFXIVMINION.gRadarSpecialTargets == nil ) then
        Settings.FFXIVMINION.gRadarSpecialTargets = "2919,2920,2921,2922,2923,2924,2925,2926,2927,2928,2929,2930,2931,2932,2933,2934,2935,2936,2937,2938,2939,2940,2941,2942,2943,2944,2945,2946,2947,2948,2949,2950,2951,2952,2953,2954,2955,2956,2957,2958,2959,2960,2961,2962,2963,2964,2965,2966,2967,2968,2969"
    end	
	
	

    GUI_NewWindow(wt_radar.MainWindow.Name,wt_radar.MainWindow.x,wt_radar.MainWindow.y,wt_radar.MainWindow.width,wt_radar.MainWindow.height)	
    GUI_NewCheckbox(wt_radar.MainWindow.Name,strings[gCurrentLanguage].enableRadar,"gRadar","Radar" );
    GUI_NewCheckbox(wt_radar.MainWindow.Name,strings[gCurrentLanguage].enable2DRadar,"g2dRadar","Radar" );
    GUI_NewCheckbox(wt_radar.MainWindow.Name,strings[gCurrentLanguage].enable3DRadar,"g3dRadar","Radar" );
    GUI_NewCheckbox(wt_radar.MainWindow.Name,strings[gCurrentLanguage].fullscreenRadar,"g2dRadarFullScreen","Radar" );
    
    GUI_NewCheckbox(wt_radar.MainWindow.Name,strings[gCurrentLanguage].showNodes,"gRadarShowNode","RadarSettings" );
    GUI_NewCheckbox(wt_radar.MainWindow.Name,strings[gCurrentLanguage].showPlayers,"gRadarShowPlayers","RadarSettings" );
    GUI_NewCheckbox(wt_radar.MainWindow.Name,strings[gCurrentLanguage].showBattleNPCs,"gRadarShowBattleNPCs","RadarSettings" );
    GUI_NewCheckbox(wt_radar.MainWindow.Name,strings[gCurrentLanguage].showEventNPCs,"gRadarShowEventNPCs","RadarSettings" );
    GUI_NewCheckbox(wt_radar.MainWindow.Name,strings[gCurrentLanguage].showEventObjects,"gRadarShowEventObjs","RadarSettings" );
    GUI_NewCheckbox(wt_radar.MainWindow.Name,strings[gCurrentLanguage].showAetherytes,"gRadarShowAetherytes","RadarSettings" )
	
	GUI_NewField(wt_radar.MainWindow.Name,"SpecialTargetContentIDs","gRadarSpecialTargets","RadarSettings" )
	

    GUI_NewNumeric(wt_radar.MainWindow.Name,strings[gCurrentLanguage].xPos,"gRadarX","RadarSettings" )
    GUI_NewNumeric(wt_radar.MainWindow.Name,strings[gCurrentLanguage].yPos,"gRadarY","RadarSettings" )
    
    gRadar = Settings.FFXIVMINION.gRadar
    g2dRadar = Settings.FFXIVMINION.g2dRadar
    g3dRadar = Settings.FFXIVMINION.g3dRadar
    g2dRadarFullScreen = Settings.FFXIVMINION.g2dRadarFullScreen
    gRadarShowNode = Settings.FFXIVMINION.gRadarShowNode
    gRadarShowPlayers = Settings.FFXIVMINION.gRadarShowPlayers
    gRadarShowBattleNPCs = Settings.FFXIVMINION.gRadarShowBattleNPCs
    gRadarShowEventNPCs = Settings.FFXIVMINION.gRadarShowEventNPCs
    gRadarShowEventObjs = Settings.FFXIVMINION.gRadarShowEventObjs
    gRadarShowAetherytes = Settings.FFXIVMINION.gRadarShowAetherytes
    gRadarX = Settings.FFXIVMINION.gRadarX
    gRadarY = Settings.FFXIVMINION.gRadarY
    gRadarSpecialTargets = Settings.FFXIVMINION.gRadarSpecialTargets
	

    if ( gRadar == "0") then GameHacks:SetRadarSettings("gRadar",false) else GameHacks:SetRadarSettings("gRadar",true) end
    if ( g2dRadar == "0") then GameHacks:SetRadarSettings("g2dRadar",false) else GameHacks:SetRadarSettings("g2dRadar",true) end
    if ( g3dRadar == "0") then GameHacks:SetRadarSettings("g3dRadar",false) else GameHacks:SetRadarSettings("g3dRadar",true) end
    if ( g2dRadarFullScreen == "0") then GameHacks:SetRadarSettings("g2dRadarFullScreen",false) else GameHacks:SetRadarSettings("g2dRadarFullScreen",true) end
    if ( gRadarShowNode == "0") then GameHacks:SetRadarSettings("gRadarShowNode",false) else GameHacks:SetRadarSettings("gRadarShowNode",true) end
    if ( gRadarShowPlayers == "0") then GameHacks:SetRadarSettings("gRadarShowPlayers",false) else GameHacks:SetRadarSettings("gRadarShowPlayers",true) end
    if ( gRadarShowBattleNPCs == "0") then GameHacks:SetRadarSettings("gRadarShowBattleNPCs",false) else GameHacks:SetRadarSettings("gRadarShowBattleNPCs",true) end
    if ( gRadarShowEventNPCs == "0") then GameHacks:SetRadarSettings("gRadarShowEventNPCs",false) else GameHacks:SetRadarSettings("gRadarShowEventNPCs",true) end
    if ( gRadarShowEventObjs == "0") then GameHacks:SetRadarSettings("gRadarShowEventObjs",false) else GameHacks:SetRadarSettings("gRadarShowEventObjs",true) end
    if ( gRadarShowAetherytes == "0") then GameHacks:SetRadarSettings("gRadarShowAetherytes",false) else GameHacks:SetRadarSettings("gRadarShowAetherytes",true) end
    if ( gRadarSpecialTargets ~= nil and gRadarSpecialTargets ~= "" ) then GameHacks:SetRadarSettings("gRadarSpecialTargetList", tostring(gRadarSpecialTargets)) end
	if ( tonumber(gRadarX) ~= nil) then GameHacks:SetRadarSettings("gRadarX",tonumber(gRadarX)) end
    if ( tonumber(gRadarY) ~= nil) then GameHacks:SetRadarSettings("gRadarY",tonumber(gRadarY)) end
    
	
    GUI_WindowVisible(wt_radar.MainWindow.Name,false)
end

function wt_radar.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if (k == "gRadar" or
            k == "g2dRadar" or 			
            k == "g3dRadar" or
            k == "g2dRadarFullScreen" or
            k == "gRadarShowNode" or
            k == "gRadarShowPlayers" or
            k == "gRadarShowBattleNPCs" or			
            k == "gRadarShowEventNPCs" or
            k == "gRadarShowEventObjs" or
            k == "gRadarShowAetherytes")
        then
            Settings.FFXIVMINION[tostring(k)] = v
            if ( v == "0") then
                GameHacks:SetRadarSettings(k,false)
            else
                GameHacks:SetRadarSettings(k,true)
            end
        end
		if ( k == "gRadarSpecialTargets" and gRadarSpecialTargets ~= nil ) then
			Settings.FFXIVMINION[tostring(k)] = v
			GameHacks:SetRadarSettings("gRadarSpecialTargetList", tostring(gRadarSpecialTargets))
		end
        if ( k == "gRadarX" and tonumber(v) ~= nil) then
            Settings.FFXIVMINION[tostring(k)] = v
            GameHacks:SetRadarSettings(k,tonumber(v))
        end
        if ( k == "gRadarY" and tonumber(v) ~= nil) then
            Settings.FFXIVMINION[tostring(k)] = v
            GameHacks:SetRadarSettings(k,tonumber(v))
        end
    end
    GUI_RefreshWindow(wt_radar.MainWindow.Name)
end

function wt_radar.ToggleMenu()
    if (wt_radar.visible) then
        GUI_WindowVisible(wt_radar.MainWindow.Name,false)	
        wt_radar.visible = false
    else		 
        GUI_WindowVisible(wt_radar.MainWindow.Name,true)	
        wt_radar.visible = true
    end
end

-- Register Event Handlers
RegisterEventHandler("Module.Initalize",wt_radar.HandleInit)
RegisterEventHandler("Radar.toggle", wt_radar.ToggleMenu)
RegisterEventHandler("GUI.Update",wt_radar.GUIVarUpdate)
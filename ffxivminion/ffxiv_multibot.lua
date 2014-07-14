mb = { }
mb.mainwindow = { name = "MultiBot Manager", x = 350, y = 100, w = 250, h = 300}
mb.visible = false
mb.lasttick = 0
mb.queueStatus = false
mb.queueWithdraw = false
mb.withdrawTimer = 0

function mb.ModuleInit() 	

	if (Settings.FFXIVMINION.gMultiBotEnabled == nil) then
		Settings.FFXIVMINION.gMultiBotEnabled = "0"
	end
	if ( Settings.FFXIVMINION.gMultiChannel == nil ) then
		Settings.FFXIVMINION.gMultiChannel = "Group1"
	end
	if ( Settings.FFXIVMINION.gMultiServer == nil ) then
		Settings.FFXIVMINION.gMultiServer = "127.0.0.1"
	end
	if ( Settings.FFXIVMINION.gMultiPort == nil ) then
		Settings.FFXIVMINION.gMultiPort = "7777"
	end
	if ( Settings.FFXIVMINION.gMultiPass == nil ) then
		Settings.FFXIVMINION.gMultiPass = "minionpw"
	end

    GUI_NewWindow(mb.mainwindow.name,mb.mainwindow.x,mb.mainwindow.y,mb.mainwindow.w,mb.mainwindow.name.h)
	GUI_NewCheckbox(mb.mainwindow.name,GetString("activated"),"gMultiBotEnabled",GetString("generalSettings"))	
	GUI_NewField(mb.mainwindow.name,GetString("multiChannel"),"gMultiChannel",GetString("serverInfo"))
	GUI_NewField(mb.mainwindow.name,GetString("multiServer"),"gMultiServer",GetString("serverInfo"))
	GUI_NewField(mb.mainwindow.name,GetString("multiPort"),"gMultiPort",GetString("serverInfo"))
	GUI_NewField(mb.mainwindow.name,GetString("multiPass"),"gMultiPass",GetString("serverInfo"))
	GUI_NewButton(mb.mainwindow.name,GetString("toggleOnOff"), "MultiBotManager.activate")
	
	gMultiBotEnabled = Settings.FFXIVMINION.gMultiBotEnabled
	gMultiChannel = Settings.FFXIVMINION.gMultiChannel
	gMultiServer = Settings.FFXIVMINION.gMultiServer
	gMultiPort = Settings.FFXIVMINION.gMultiPort
	gMultiPass = Settings.FFXIVMINION.gMultiPass
	
    GUI_UnFoldGroup(mb.mainwindow.name,GetString("generalSettings"))
	GUI_UnFoldGroup(mb.mainwindow.name,GetString("serverInfo"))	
	GUI_SizeWindow(mb.mainwindow.name,mb.mainwindow.w,mb.mainwindow.h)	
    GUI_WindowVisible(mb.mainwindow.name,false)

	if (gMultiBotEnabled == "1" and MultiBotIsConnected() ) then
		MultiBotJoinChannel(gMultiChannel)
	end
end

function mb.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if (
            k == "gMultiBotEnabled" or
            k == "gMultiChannel" or
            k == "gMultiServer" or 
            k == "gMultiPort" or
            k == "gMultiPass")			
        then
            Settings.FFXIVMINION[tostring(k)] = v
		end
	end
    GUI_RefreshWindow(ffxivminion.Windows.Main.Name)
end

function mb.ToggleOnOff()
	if gMultiBotEnabled == "1" then
		gMultiBotEnabled = "0"
	else
		gMultiBotEnabled = "1"
	end
end

function mb.ToggleMenu()
    if (mb.visible) then
        GUI_WindowVisible(mb.mainwindow.name,false)	
        mb.visible = false
    else
        local wnd = GUI_GetWindowInfo(ffxivminion.Windows.Main.Name)	
        GUI_MoveWindow( mb.mainwindow.name, wnd.x+wnd.width,wnd.y) 
        GUI_WindowVisible(mb.mainwindow.name,true)	
        mb.visible = true
    end
end

function mb.OnUpdate( event, tickcount )
    if ( tickcount - mb.lasttick > 500 ) then
        mb.lasttick = tickcount
        
        if (gMultiBotEnabled == "1") then
			if ( not MultiBotIsConnected() )then
				if ( not MultiBotConnect( gMultiServer , tonumber(gMultiPort) , gMultiPass) ) then
					gMultiBotEnabled = "0"
					d("Could not connect to the server with the specified IP:Port and password.")
				else
					if (MultiBotJoinChannel(gMultiChannel)) then
						d("Channel join succeeeded for channel ["..gMultiChannel.."]")
					else
						d("Channel join failed for channel ["..gMultiChannel.."]")
					end						
				end	
			end
		else
			if ( MultiBotIsConnected() ) then
				d("MultiBot disconnected.")
				MultiBotDisconnect()
			end
		end			
    end
end

function mb.BroadcastQueueStatus( ready )
	-- State 1: Leader of one team communicates that he is ready with msgID = 1.
	-- State 2: Leader has received acknowledgement that the other team is ready, pass it along to the minions with msgID = 2.
	-- State 3: Leader has no received acknowledgement that the other team is ready, probably randoms, pass along a message to withdraw with msgID = 3.
	-- State 4: Reset the queue status whenever we join the instance or as necessary under other conditions.
	if ( IsLeader() ) then
		if ( ready and not mb.QueueReady() and (Now() < mb.withdrawTimer or mb.withdrawTimer == 0)) then
			MultiBotSend( "1;"..Player.name, gMultiChannel )
			mb.withdrawTimer = Now() + 15000
		elseif ( ready and mb.QueueReady()) then
			MultiBotSend( "2;"..Player.name, gMultiChannel )
			mb.withdrawTimer = 0
		elseif ( ready and not mb.QueueReady() and Now() > mb.withdrawTimer and mb.withdrawTimer ~= 0)  then
			MultiBotSend( "3;"..Player.name, gMultiChannel )
			mb.queueWithdraw = true
		elseif ( not ready ) then
			MultiBotSend( "4;Reset", gMultiChannel )
			mb.queueStatus = false
			mb.queueWithdraw = false
		end
	end
end

function mb.QueueReady()
	return mb.queueStatus
end
--**********************************************************
-- HandleMultiBotMessages
--**********************************************************
function HandleMultiBotMessages( event, message, channel )	
	if ( gMultiBotEnabled == "1" ) then
		--d("Message:"..tostring(message)..", Channel:"..tostring(channel))
		if ( channel == gMultiChannel ) then
			--d("Detected messages in the proper channel.")
			local delimiter = message:find(';')
			if (delimiter ~= nil and delimiter ~= 0) then

				local msgID = message:sub(0,delimiter-1)
				local msg = message:sub(delimiter+1)
				if (tonumber(msgID) ~= nil and msg ~= nil ) then
				
					--d("msgID:" .. msgID)
					--d("msg:" .. msg)

					if ( tonumber(msgID) == 1 and msg ~= "" and msg ~= Player.name and IsLeader()) then
                        mb.queueStatus = true
					elseif ( tonumber(msgID) == 2 and msg ~= "" and msg == GetPartyLeader().name) then
                        ml_task_hub:CurrentTask().multibotJoin = true
					elseif ( tonumber(msgID) == 3 and msg ~= "" and msg == GetPartyLeader().name) then
						ml_task_hub:CurrentTask().multibotWithdraw = true
					elseif ( tonumber(msgID) == 4 and msg ~= "" ) then
						ml_task_hub:CurrentTask().multibotWithdraw = false
						ml_task_hub:CurrentTask().multibotJoin = false
					end
					
				end
			end
		end
	end
end

RegisterEventHandler("MultiBotManager.activate", mb.ToggleOnOff)
RegisterEventHandler("MultiBotManager.toggle", mb.ToggleMenu)
RegisterEventHandler("Module.Initalize",mb.ModuleInit)
RegisterEventHandler("GUI.Update",mb.GUIVarUpdate)
RegisterEventHandler("Gameloop.Update",mb.OnUpdate)
RegisterEventHandler("MULTIBOT.Message",HandleMultiBotMessages)
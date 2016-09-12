dev = {}
dev.open = true
dev.unfolded = true


function dev.Init()
	-- Register Button	
	ml_gui.ui_mgr:AddSubMember({ id = "FFXIVMINION##DEV_1", name = "Dev-Monitor", onClick = function() dev.open = not dev.open end, tooltip = "Open the Dev monitor."},"FFXIVMINION##MENU_HEADER","FFXIVMINION##MENU_ADDONS")	
end
RegisterEventHandler("Module.Initalize",dev.Init)


function dev.DrawCall(event, ticks )
	
	if ( dev.open  ) then 
		GUI:SetNextWindowPosCenter(GUI.SetCond_Appearing)
		GUI:SetNextWindowSize(500,400,GUI.SetCond_FirstUseEver) --set the next window size, only on first ever
		dev.unfolded, dev.open = GUI:Begin("Dev-Monitor", dev.open)
		if ( dev.unfolded ) then 
			local gamestate = GetGameState()
									
			GUI:PushStyleVar(GUI.StyleVar_FramePadding, 4, 0)
			GUI:PushStyleVar(GUI.StyleVar_ItemSpacing, 8, 2)
			
			if ( GUI:TreeNode("AddonControls")) then
				if ( GUI:TreeNode("Active Controls")) then
					local controls = GetControls()
					if (table.valid(controls)) then
						for id, e in pairs(controls) do
							GUI:PushItemWidth(150)
							if ( GUI:TreeNode(tostring(id).." - "..e.name.." "..tostring(table.size(e:GetActions())).."") ) then
								GUI:BulletText("Ptr") GUI:SameLine(200) GUI:InputText("##devc0"..tostring(id),tostring(string.format( "%X",e.ptr)))
								local isopen = e:IsOpen()
								GUI:BulletText("IsOpen") GUI:SameLine(200) GUI:InputText("##devc1"..tostring(id),tostring(isopen))
								if (isopen == false) then
									if (GUI:Button("Open",100,15) ) then d("Opening Control Result: "..tostring(e:Open())) end
									GUI:SameLine()
									if (GUI:Button("Destroy",100,15) ) then d("Destroy Control Result: "..tostring(e:Destroy())) end
								else
									if (GUI:Button("Close",100,15) ) then d("Closing Control Result: "..tostring(e:Close())) end
									GUI:SameLine()
									if (GUI:Button("Destroy",100,15) ) then d("Destroy Control Result: "..tostring(e:Destroy())) end
									
									local ac = e:GetActions()
									if (table.valid(ac)) then
										GUI:SetNextTreeNodeOpened(true,GUI.SetCond_Always)
										if ( GUI:TreeNode("Control Actions##"..tostring(id)) ) then
											for aid, action in pairs(ac) do
												if (GUI:Button(action,150,15) ) then d("Action Result :" ..tostring(e:Action(action))) end
											end
											GUI:TreePop()
										end
									end
									
									if ( GUI:TreeNode("Dev##"..tostring(id)) ) then										
										if (GUI:Button("PushButton",100,15) ) then d("Push Button Result: "..tostring(e:PushButton(dev.pushbuttonA, dev.pushbuttonB))) end
										GUI:SameLine()										
										if ( not dev.pushbuttonA or dev.pushbuttonA < 0) then dev.pushbuttonA = 0 end
										dev.pushbuttonA = GUI:InputInt("##devc2"..tostring(id),dev.pushbuttonA ,1,1) 
										GUI:SameLine()
										if ( not dev.pushbuttonB or dev.pushbuttonB < 0) then dev.pushbuttonB = 0 end
										dev.pushbuttonB = GUI:InputInt("##devc3"..tostring(id),dev.pushbuttonB ,1,1)																					
										GUI:TreePop()
									end
								end
								
								
								
								
								
								GUI:TreePop()
							end					
							GUI:PopItemWidth()
						end
					end
					GUI:TreePop()
				end	
				if ( GUI:TreeNode("All Controls")) then	
					local controls = GetControlList()
					GUI:PushItemWidth(200)
					if (table.valid(controls)) then
						for id, e in pairs(controls) do
							GUI:BulletText("ID: "..tostring(id)) GUI:SameLine(150) GUI:InputText("##devac0"..tostring(id), e) 
							GUI:SameLine() 
							if (GUI:Button("Create##"..tostring(id),50,15) ) then d("Creating Control Result: "..tostring(CreateControl(id))) end
						end
					end
					GUI:PopItemWidth()
					GUI:TreePop()
				end				
				GUI:TreePop()
			end
			
			
			if ( GUI:TreeNode("ServerList")) then
				GUI:PushItemWidth(200)
				local servers = GetServerList()
				if (table.valid(servers)) then
					for id, e in pairs(servers) do
						GUI:Text(tostring(id).." - "..e.name) GUI:SameLine()
						if (GUI:Button("Select##"..tostring(id),50,15) ) then SelectServer(id) end
					end
				end				
				GUI:PopItemWidth()
				GUI:TreePop()
			end
			

			if ( GUI:TreeNode("Utility Functions & Info")) then
				GUI:PushItemWidth(300)
				if (dev.sendcmd == nil ) then dev.sendcmd = "" end
				dev.sendcmd = GUI:InputText("##devuf1", dev.sendcmd) GUI:SameLine()	if (GUI:Button("SendCommand",100,15) ) then SendTextCommand(dev.sendcmd) end

				
				GUI:PopItemWidth()
				GUI:TreePop()
			end
			
			if ( gamestate == FFXIV.GAMESTATE.MAINMENUSCREEN ) then 
			
			
			elseif( gamestate == FFXIV.GAMESTATE.CHARACTERSCREEN ) then 
			
			
			elseif( gamestate == FFXIV.GAMESTATE.INGAME ) then 
			
			end
			
			
			GUI:PopStyleVar(2)
		end
		GUI:End()
	end
end
RegisterEventHandler("Gameloop.Draw", dev.DrawCall)

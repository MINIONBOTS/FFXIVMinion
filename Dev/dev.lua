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
			
			if ( GUI:TreeNode("Player") ) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					local c = Player
					if ( c ) then dev.DrawGameObjectDetails(c) else	GUI:Text("No Player Found") end
				else
					GUI:Text("Not Ingame...")
				end
				GUI:TreePop()
			end
			
			if ( GUI:TreeNode("Target") ) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					local c = Player:GetTarget()
					if ( c ) then dev.DrawGameObjectDetails(c) else	GUI:Text("No Target Found") end
				else
					GUI:Text("Not Ingame...")
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
				
				local p = Player
				if ( p ) then 
					GUI:BulletText("Map ID") GUI:SameLine(200) GUI:InputText("##devuf2",tostring(c.mapid))
				end
				
				GUI:PopItemWidth()
				GUI:TreePop()
			end
			
			GUI:PopStyleVar(2)
		end
		GUI:End()
	end
end
RegisterEventHandler("Gameloop.Draw", dev.DrawCall)


function dev.DrawGameObjectDetails(c) 
	GUI:PushItemWidth(200)
	if ( GUI:TreeNode("Core Data") ) then
		GUI:BulletText("Ptr") GUI:SameLine(200) GUI:InputText("##dev0",tostring(string.format( "%X",c.ptr)))
		GUI:BulletText("ID") GUI:SameLine(200) GUI:InputText("##dev1",tostring(c.id))
		GUI:BulletText("Name") GUI:SameLine(200) GUI:InputText("##dev2",c.name)	
		GUI:BulletText("ContentID") GUI:SameLine(200) GUI:InputText("##dev4",tostring(c.contentid))
		GUI:BulletText("Type") GUI:SameLine(200) GUI:InputText("##dev5",tostring(c.type))
		GUI:BulletText("CharType") GUI:SameLine(200) GUI:InputText("##dev6",tostring(c.chartype))
		GUI:BulletText("TargetID") GUI:SameLine(200) GUI:InputText("##dev7",tostring(c.targetid))
		GUI:BulletText("OwnerID") GUI:SameLine(200) GUI:InputText("##dev8",tostring(c.ownerid))
		GUI:BulletText("Claimed By ID") GUI:SameLine(200) GUI:InputText("##dev43",tostring(c.claimedbyid))
		GUI:BulletText("Fate ID") GUI:SameLine(200) GUI:InputText("##dev35", tostring(c.fateid))
		GUI:TreePop()
	end
	if ( GUI:TreeNode("Bars Data") ) then
		local h = c.hp
		GUI:BulletText("Health") GUI:SameLine(200)  GUI:InputFloat3( "##dev9", h.current, h.max, h.percent, 2, GUI.InputTextFlags_ReadOnly)
		h = c.mp
		GUI:BulletText("MP") GUI:SameLine(200)  GUI:InputFloat3( "##dev10", h.current, h.max, h.percent, 2, GUI.InputTextFlags_ReadOnly)
		h = c.cp
		GUI:BulletText("CP") GUI:SameLine(200)  GUI:InputFloat3( "##dev11", h.current, h.max, h.percent, 2, GUI.InputTextFlags_ReadOnly)
		h = c.gp
		GUI:BulletText("GP") GUI:SameLine(200)  GUI:InputFloat3( "##dev12", h.current, h.max, h.percent, 2, GUI.InputTextFlags_ReadOnly)
		GUI:BulletText("TP") GUI:SameLine(200) GUI:InputText("##dev13",tostring(c.tp))	
		GUI:TreePop()
	end
	local p = c.pos
	if ( GUI:TreeNode("Position Data") ) then
		GUI:BulletText("Position") GUI:SameLine(200)  GUI:InputFloat4( "##dev14", p.x, p.y, p.z, p.h, 2, GUI.InputTextFlags_ReadOnly)
		GUI:BulletText("Radius") GUI:SameLine(200) GUI:InputText("##dev15",tostring(c.hitradius))	
		GUI:BulletText("Distance") GUI:SameLine(200) GUI:InputFloat("##dev16", c.distance,0,0,2)
		GUI:BulletText("Distance2D") GUI:SameLine(200) GUI:InputFloat("##dev17", c.distance2d,0,0,2)
		GUI:BulletText("PathDistance") GUI:SameLine(200) GUI:InputFloat("##dev18", c.pathdistance,0,0,2)	
		GUI:BulletText("LoS") GUI:SameLine(200) GUI:InputText("##dev19", tostring(c.los))
		GUI:BulletText("LoS2") GUI:SameLine(200) GUI:InputText("##dev20", tostring(c.los2))
		GUI:BulletText("OnMesh") GUI:SameLine(200) GUI:InputText("##dev20", tostring(c.onmesh))	
		GUI:TreePop()
	end	
	if ( GUI:TreeNode("Misc Data") ) then
		GUI:BulletText("IsMounted") GUI:SameLine(200) GUI:InputText("##dev38", tostring(c.ismounted))
		GUI:BulletText("Job") GUI:SameLine(200) GUI:InputText("##dev21",tostring(c.job))
		GUI:BulletText("Level") GUI:SameLine(200) GUI:InputText("##dev22",tostring(c.level))
		GUI:BulletText("GrandCompany") GUI:SameLine(200) GUI:InputText("##dev41",tostring(c.grandcompany))
		GUI:BulletText("GrandCompanyRank") GUI:SameLine(200) GUI:InputText("##dev42",tostring(c.grandcompanyrank))
		GUI:BulletText("Aggro") GUI:SameLine(200) GUI:InputText("##dev24",tostring(c.aggro))
		GUI:BulletText("AggroPercentage") GUI:SameLine(200) GUI:InputText("##dev25",tostring(c.aggropercentage))	
		GUI:BulletText("Attackable") GUI:SameLine(200) GUI:InputText("##dev26", tostring(c.attackable))
		GUI:BulletText("Aggressive") GUI:SameLine(200) GUI:InputText("##dev27", tostring(c.aggressive))
		GUI:BulletText("Friendly") GUI:SameLine(200) GUI:InputText("##dev28", tostring(c.friendly))
		GUI:BulletText("InCombat") GUI:SameLine(200) GUI:InputText("##dev29", tostring(c.incombat))
		GUI:BulletText("Targetable") GUI:SameLine(200) GUI:InputText("##dev30", tostring(c.targetable))
		GUI:BulletText("Alive") GUI:SameLine(200) GUI:InputText("##dev31", tostring(c.alive))
		GUI:BulletText("Gatherable") GUI:SameLine(200) GUI:InputText("##dev32", tostring(c.cangather))
		if ( c.cangather ) then
			GUI:BulletText("GatherAttempts") GUI:SameLine(200) GUI:InputText("##dev33", tostring(c.gatherattempts))
			GUI:BulletText("GatherAttemptsMax") GUI:SameLine(200) GUI:InputText("##dev34", tostring(c.gatherattemptsmax))
		end
		GUI:TreePop()
	end
	
	if ( GUI:TreeNode("Cast & Spell Data") ) then
		GUI:BulletText("Current Action") GUI:SameLine(200) GUI:InputText("##dev36", tostring(c.action))
		GUI:BulletText("Last Action") GUI:SameLine(200) GUI:InputText("##dev37", tostring(c.lastaction))
		GUI:TreePop()
	end
	
	if ( GUI:TreeNode("Buffs") ) then
		local buffs = c.buffs
		if ( table.size(buffs) > 0) then
			for id, b in pairs(buffs) do
				if ( GUI:TreeNode(tostring(b.slot).." - "..b.name) ) then
					GUI:BulletText("Ptr") GUI:SameLine(200) GUI:InputText("##devb0",tostring(string.format( "%X",b.ptr)))
					GUI:BulletText("Ptr2") GUI:SameLine(200) GUI:InputText("##devb1",tostring(string.format( "%X",b.ptr2)))
					GUI:BulletText("ID") GUI:SameLine(200) GUI:InputText("##devb8", tostring(b.id))
					GUI:BulletText("Duration") GUI:SameLine(200) GUI:InputText("##devb9", tostring(b.duration))				
					GUI:BulletText("Name") GUI:SameLine(200) GUI:InputText("##devb3", tostring(b.name))
					GUI:BulletText("OwnerID") GUI:SameLine(200) GUI:InputText("##devb4", tostring(b.ownerid))
					GUI:BulletText("IsBuff") GUI:SameLine(200) GUI:InputText("##devb5", tostring(b.isbuff))
					GUI:BulletText("IsDebuff") GUI:SameLine(200) GUI:InputText("##devb6", tostring(b.isdebuff))
					GUI:BulletText("Stacks") GUI:SameLine(200) GUI:InputText("##devb7", tostring(b.stacks))
					GUI:BulletText("Slot") GUI:SameLine(200) GUI:InputText("##devb2", tostring(b.slot))
					GUI:TreePop()
				end
			end
		else
			GUI:Text("No Buffs Available...")
		end
		GUI:TreePop()
	end
	
	GUI:PopItemWidth()	
end










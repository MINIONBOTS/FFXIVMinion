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
												if (GUI:Button(action,150,15) ) then d("Action Result with arg "..tostring(dev.addoncontrolarg).." :" ..tostring(e:Action(action,dev.addoncontrolarg))) end
												GUI:SameLine()
												if (not dev.addoncontrolarg) then dev.addoncontrolarg = 0 end
												dev.addoncontrolarg = GUI:InputInt("Arg 1##"..tostring(aid)..tostring(id), dev.addoncontrolarg)
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
--End Active Controls

			
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
			
if ( GUI:TreeNode("ActionList")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					GUI:PushItemWidth(100)	
					GUI:BulletText("IsCasting") GUI:SameLine(200) GUI:InputText("##devac22",tostring(ActionList:IsCasting())) GUI:SameLine()
					if (GUI:Button("StopCasting",100,15) ) then d("StopCasting Result: "..tostring(ActionList:StopCasting())) end
					GUI:BulletText("Is Hotbar Ready") GUI:SameLine(200) GUI:InputText("##devac23",tostring(ActionList:IsReady())) 
					GUI:PopItemWidth()
					GUI:PushItemWidth(200)
					local actiontypes = ActionList:GetTypes()
					if (table.valid(actiontypes)) then
						for actiontype, e in pairs(actiontypes) do
							if ( GUI:TreeNode(tostring(actiontype).." - "..e)) then
								local actionlist = ActionList:Get(actiontype) 	-- ALTERNATIVE:  ActionList:Get(actiontype, skillID) , to get the single action back
								if (table.valid(actionlist)) then
									for actionid, action in pairs(actionlist) do
										if ( GUI:TreeNode(tostring(actionid).." - "..action.name)) then --rather slow making 6000+ names :D
										--if ( GUI:TreeNode(tostring(actionid).." - ")) then
											GUI:BulletText("Ptr") GUI:SameLine(200) GUI:InputText("##devac1"..tostring(actionid),tostring(string.format( "%X",action.ptr)))
											GUI:BulletText("ID") GUI:SameLine(200) GUI:InputText("##devac2"..tostring(actionid),tostring(action.id))
											GUI:BulletText("Type") GUI:SameLine(200) GUI:InputText("##devac3"..tostring(actionid),tostring(action.type))
											GUI:BulletText("SkillType") GUI:SameLine(200) GUI:InputText("##devac4"..tostring(actionid),tostring(action.skilltype))
											GUI:BulletText("Cost") GUI:SameLine(200) GUI:InputText("##devac5"..tostring(actionid),tostring(action.cost))
											GUI:BulletText("CastTime") GUI:SameLine(200) GUI:InputText("##devac6"..tostring(actionid),tostring(action.casttime))
											GUI:BulletText("RecastTime") GUI:SameLine(200) GUI:InputText("##devac7"..tostring(actionid),tostring(action.recasttime))
											GUI:BulletText("IsOnCooldown") GUI:SameLine(200) GUI:InputText("##devac8"..tostring(actionid),tostring(action.isoncd))
											GUI:BulletText("Cooldown") GUI:SameLine(200) GUI:InputText("##devac9"..tostring(actionid),tostring(action.cd))
											GUI:BulletText("CooldownMax") GUI:SameLine(200) GUI:InputText("##devac10"..tostring(actionid),tostring(action.cdmax))
											GUI:BulletText("Range") GUI:SameLine(200) GUI:InputText("##devac11"..tostring(actionid),tostring(action.range))
											GUI:BulletText("Radius") GUI:SameLine(200) GUI:InputText("##devac12"..tostring(actionid),tostring(action.radius))
											GUI:BulletText("Level") GUI:SameLine(200) GUI:InputText("##devac13"..tostring(actionid),tostring(action.level))
											GUI:BulletText("Job") GUI:SameLine(200) GUI:InputText("##devac14"..tostring(actionid),tostring(action.job))
											GUI:BulletText("IsCasting") GUI:SameLine(200) GUI:InputText("##devac15"..tostring(actionid),tostring(action.iscasting))
											GUI:BulletText("ComboSpellID") GUI:SameLine(200) GUI:InputText("##devac16"..tostring(actionid),tostring(action.combospellid))
											GUI:BulletText("IsGroundTargeted") GUI:SameLine(200) GUI:InputText("##devac17"..tostring(actionid),tostring(action.isgroundtargeted))
											
											GUI:BulletText("IsReady(Player)") GUI:SameLine(200) GUI:InputText("##devac20"..tostring(actionid),tostring(action:IsReady()))
											GUI:BulletText("IsFacing(Player)") GUI:SameLine(200) GUI:InputText("##devac21"..tostring(actionid),tostring(action:IsFacing()))
											local tar = Player:GetTarget()
											if ( tar ) then
												GUI:BulletText("IsReady(Target)") GUI:SameLine(200) GUI:InputText("##devac18"..tostring(actionid),tostring(action:IsReady(tar.id)))
												GUI:BulletText("IsFacing(Target)") GUI:SameLine(200) GUI:InputText("##devac19"..tostring(actionid),tostring(action:IsFacing(tar.id)))
											end
											if (GUI:Button("Cast(Player)##"..tostring(actionid),100,15) ) then d("Cast Result: "..tostring(action:Cast())) end 
											if ( tar ) then
												GUI:SameLine(200)
												if (GUI:Button("Cast(Target)##"..tostring(actionid),100,15) ) then d("Cast Result: "..tostring(action:Cast(tar.id))) end
											end
											GUI:TreePop()
										end									
									end
								end
								GUI:TreePop()
							end
						end
					end
					GUI:PopItemWidth()
				else
					GUI:Text("Not Ingame...")
				end
				GUI:TreePop()
			end
-- END ACTIONLIST

			
			if ( GUI:TreeNode("Duty List")) then
				GUI:PushItemWidth(200)
				local dList = Duty:GetDutyList()
				if (table.valid(dList)) then
					for id, e in pairs(dList) do
						if ( GUI:TreeNode(e.name) ) then
							GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devDL1"..tostring(id),tostring(e.id))
							GUI:BulletText(".mapid") GUI:SameLine(200) GUI:InputText("##devDL2"..tostring(id),tostring(e.mapid))
							GUI:BulletText(".selectindex") GUI:SameLine(200) GUI:InputText("##devDL3"..tostring(id),tostring(e.selectindex))
							GUI:BulletText(".requiredlevel") GUI:SameLine(200) GUI:InputText("##devDL4"..tostring(id),tostring(e.requiredlevel))
							GUI:BulletText(".synchlevel") GUI:SameLine(200) GUI:InputText("##devDL5"..tostring(id),tostring(e.synclevel))
							GUI:BulletText(".partysize") GUI:SameLine(200) GUI:InputText("##devDL6"..tostring(id),tostring(e.partysize))
							GUI:TreePop()
						end
					end
				else
					GUI:Text("Duty Finder Not Open...")
				end				
				GUI:PopItemWidth()
				GUI:TreePop()
			end
-- END DUTY LIST

			if ( GUI:TreeNode("Fates")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					GUI:PushItemWidth(200)
					local flist = GetFateList()
					if (table.valid(flist)) then
						for id, e in pairs(flist) do
							if ( GUI:TreeNode(tostring(e.id).." - "..e.name)) then
								GUI:BulletText("Ptr") GUI:SameLine(200) GUI:InputText("##devufa1",tostring(string.format( "%X",e.ptr)))
								GUI:BulletText("ID") GUI:SameLine(200) GUI:InputText("##devufa2",tostring(e.id))
								GUI:BulletText("Type") GUI:SameLine(200) GUI:InputText("##devufa3",tostring(e.type))
								GUI:BulletText("Status") GUI:SameLine(200) GUI:InputText("##devufa4",tostring(e.status))
								GUI:BulletText("Duration") GUI:SameLine(200) GUI:InputText("##devufa7",tostring(e.duration))
								GUI:BulletText("Completion") GUI:SameLine(200) GUI:InputText("##devufa8",tostring(e.completion))
								GUI:BulletText("Level") GUI:SameLine(200) GUI:InputText("##devufa5",tostring(e.level))
								GUI:BulletText("MaxLevel") GUI:SameLine(200) GUI:InputText("##devufa6",tostring(e.maxlevel))	
								GUI:BulletText("Radius") GUI:SameLine(200) GUI:InputText("##devufa9",tostring(e.radius))							
								GUI:BulletText("Position") GUI:SameLine(200)  GUI:InputFloat3( "##devufa10", e.x, e.y, e.z, 2, GUI.InputTextFlags_ReadOnly)							
								GUI:TreePop()
							end
						end
					end				
					GUI:PopItemWidth()
				else
					GUI:Text("Not Ingame...")
				end
				GUI:TreePop()
			end
--End Fates


			if ( GUI:TreeNode("Inventory")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					GUI:PushItemWidth(200)			
					local inv = Inventory:GetTypes()
					if (table.valid(inv)) then
						for id, e in pairs(inv) do
							if ( GUI:TreeNode(tostring(e))) then
									local bag = Inventory:Get(e) 	-- ALTERNATIVE:  Inventory:Get() , to get the full list
									if (table.valid(bag)) then
										GUI:BulletText("Ptr") GUI:SameLine(200) GUI:InputText("##devbag1"..tostring(id),tostring(string.format( "%X",bag.ptr)))
										GUI:BulletText("Slots/Free/Used") GUI:SameLine(200) GUI:InputInt3("##devbag2"..tostring(id),tostring(bag.size),tostring(bag.free),tostring(bag.used))
										
										local ilist = bag:GetList()
										if (table.valid(ilist)) then
											for slot, item in pairs(ilist) do
												if ( GUI:TreeNode(tostring(slot).." - "..item.name)) then
													GUI:BulletText("Ptr") GUI:SameLine(200) GUI:InputText("##devbag3"..tostring(slot),tostring(string.format( "%X",item.ptr)))
													GUI:BulletText("Ptr2") GUI:SameLine(200) GUI:InputText("##devbag4"..tostring(slot),tostring(string.format( "%X",item.ptr2)))
													GUI:BulletText("ID") GUI:SameLine(200) GUI:InputText("##devbag5"..tostring(slot),tostring(item.id))
													GUI:BulletText("Is HQ") GUI:SameLine(200) GUI:InputText("##devbag19"..tostring(slot),tostring(item.ishq))
													GUI:BulletText("HQID") GUI:SameLine(200) GUI:InputText("##devbag6"..tostring(slot),tostring(item.hqid))
													GUI:BulletText("Slot") GUI:SameLine(200) GUI:InputText("##devbag7"..tostring(slot),tostring(item.slot))
													GUI:BulletText("Parent BagID") GUI:SameLine(200) GUI:InputText("##devbag8"..tostring(slot),tostring(item.type))
													GUI:BulletText("Stack Size") GUI:SameLine(200) GUI:InputText("##devbag9"..tostring(slot),tostring(item.count))
													GUI:BulletText("Max Stack") GUI:SameLine(200) GUI:InputText("##devbag10"..tostring(slot),tostring(item.max))
													GUI:BulletText("Condition") GUI:SameLine(200) GUI:InputText("##devbag11"..tostring(slot),tostring(item.condition))
													GUI:BulletText("Spiritbond") GUI:SameLine(200) GUI:InputText("##devbag18"..tostring(slot),tostring(item.spiritbond))	
													GUI:BulletText("Level") GUI:SameLine(200) GUI:InputText("##devbag13"..tostring(slot),tostring(item.level))
													GUI:BulletText("Required Level") GUI:SameLine(200) GUI:InputText("##devbag14"..tostring(slot),tostring(item.level))
													GUI:BulletText("Can Equip") GUI:SameLine(200) GUI:InputText("##devbag15"..tostring(slot),tostring(item.requiredlevel))												
													GUI:BulletText("class") GUI:SameLine(200) GUI:InputText("##devbag17"..tostring(slot),tostring(item.class))																							
													GUI:BulletText("Category") GUI:SameLine(200) GUI:InputText("##devbag20"..tostring(slot),tostring(item.category))
													GUI:BulletText("UICategory") GUI:SameLine(200) GUI:InputText("##devbag21"..tostring(slot),tostring(item.uicategory))
													GUI:BulletText("SearchCategory") GUI:SameLine(200) GUI:InputText("##devbag22"..tostring(slot),tostring(item.searchcategory))
													GUI:BulletText("CanEquip") GUI:SameLine(200) GUI:InputText("##devbag16"..tostring(slot),tostring(item.canequip))
																										
													local action = item:GetAction()
													if (table.valid(action)) then
														if ( GUI:TreeNode("Action: "..tostring(action.id).." - "..action.name)) then --rather slow making 6000+ names :D
														--if ( GUI:TreeNode(tostring(actionid).." - ")) then
															GUI:BulletText("Ptr") GUI:SameLine(200) GUI:InputText("##devac1"..tostring(actionid),tostring(string.format( "%X",action.ptr)))
															GUI:BulletText("ID") GUI:SameLine(200) GUI:InputText("##devac2"..tostring(actionid),tostring(action.id))
															GUI:BulletText("Type") GUI:SameLine(200) GUI:InputText("##devac3"..tostring(actionid),tostring(action.type))
															GUI:BulletText("SkillType") GUI:SameLine(200) GUI:InputText("##devac4"..tostring(actionid),tostring(action.skilltype))
															GUI:BulletText("Cost") GUI:SameLine(200) GUI:InputText("##devac5"..tostring(actionid),tostring(action.cost))
															GUI:BulletText("CastTime") GUI:SameLine(200) GUI:InputText("##devac6"..tostring(actionid),tostring(action.casttime))
															GUI:BulletText("RecastTime") GUI:SameLine(200) GUI:InputText("##devac7"..tostring(actionid),tostring(action.recasttime))
															GUI:BulletText("IsOnCooldown") GUI:SameLine(200) GUI:InputText("##devac8"..tostring(actionid),tostring(action.isoncd))
															GUI:BulletText("Cooldown") GUI:SameLine(200) GUI:InputText("##devac9"..tostring(actionid),tostring(action.cd))
															GUI:BulletText("CooldownMax") GUI:SameLine(200) GUI:InputText("##devac10"..tostring(actionid),tostring(action.cdmax))

															GUI:BulletText("IsReady(Player)") GUI:SameLine(200) GUI:InputText("##devac20"..tostring(actionid),tostring(action:IsReady()))
															GUI:BulletText("IsFacing(Player)") GUI:SameLine(200) GUI:InputText("##devac21"..tostring(actionid),tostring(action:IsFacing()))
															local tar = Player:GetTarget()
															if ( tar ) then
																GUI:BulletText("IsReady(Target)") GUI:SameLine(200) GUI:InputText("##devac18"..tostring(actionid),tostring(action:IsReady(tar.id)))
																GUI:BulletText("IsFacing(Target)") GUI:SameLine(200) GUI:InputText("##devac19"..tostring(actionid),tostring(action:IsFacing(tar.id)))
															end
															if (GUI:Button("Cast(Player)##"..tostring(actionid),100,15) ) then d("Cast Result: "..tostring(action:Cast())) end 
															if ( tar ) then
																GUI:SameLine(200)
																if (GUI:Button("Cast(Target)##"..tostring(actionid),100,15) ) then d("Cast Result: "..tostring(action:Cast(tar.id))) end
															end
															GUI:TreePop()
														end
													else
														GUI:BulletText("No Action Available")
													end
																										
													if (GUI:Button("Purify()##"..tostring(slot),100,15) ) then d("Purify Result: "..tostring(item:Purify())) end
													GUI:SameLine(200)
													if (GUI:Button("Repair()##"..tostring(slot),100,15) ) then d("Repair Result: "..tostring(item:Repair())) end
													
													if (GUI:Button("HandOver()##"..tostring(slot),100,15) ) then d("HandOver Result: "..tostring(item:HandOver())) end
													GUI:SameLine(200)
													if (GUI:Button("Sell()##"..tostring(slot),100,15) ) then d("Sell Result: "..tostring(item:Sell())) end
													
													if (GUI:Button("Convert()##"..tostring(slot),100,15) ) then d("Convert Result: "..tostring(item:Convert())) end
													GUI:SameLine(200)
													if (GUI:Button("Salvage()##"..tostring(slot),100,15) ) then d("Salvage Result: "..tostring(item:Salvage())) end
												
													GUI:Separator()
													GUI:TreePop()
												end
											end
										end
									end
								GUI:TreePop()
							end
						end
					end				
					GUI:PopItemWidth()
				else
					GUI:Text("Not Ingame...")
				end					
				GUI:TreePop()
			end
-- END INVENTORY
			

			if ( GUI:TreeNode("Loot List")) then
				GUI:PushItemWidth(200)
				local list = Inventory:GetLootList()
				if (table.valid(list)) then
					for id, e in pairs(list) do
						if ( GUI:TreeNode(tostring(id)) ) then
							GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##devLoot1"..tostring(id),tostring(string.format( "%X",e.ptr)))
							GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devLoot2"..tostring(id),tostring(e.id))
							GUI:BulletText(".StateA") GUI:SameLine(200) GUI:InputText("##devLoot3"..tostring(id),tostring(e.StateA))
							GUI:BulletText(".StateB") GUI:SameLine(200) GUI:InputText("##devLoot4"..tostring(id),tostring(e.StateB))
							GUI:BulletText(".StateC") GUI:SameLine(200) GUI:InputText("##devLoot5"..tostring(id),tostring(e.StateC))
							GUI:BulletText(".StateD") GUI:SameLine(200) GUI:InputText("##devLoot6"..tostring(id),tostring(e.StateD))
							GUI:TreePop()
						end
					end
					-- FOR TESTING , THERE IS A TOGGLE BOOL AND IDK WHAT IT IS YET:
					GUI:Separator()
					list = Inventory:GetLootList(1)
					if (table.valid(list)) then
						for id, e in pairs(list) do
							if ( GUI:TreeNode(tostring(id)) ) then
								GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##devLoot1"..tostring(id),tostring(string.format( "%X",e.ptr)))
								GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devLoot2"..tostring(id),tostring(e.id))
								GUI:BulletText(".StateA") GUI:SameLine(200) GUI:InputText("##devLoot3"..tostring(id),tostring(e.StateA))
								GUI:BulletText(".StateB") GUI:SameLine(200) GUI:InputText("##devLoot4"..tostring(id),tostring(e.StateB))
								GUI:BulletText(".StateC") GUI:SameLine(200) GUI:InputText("##devLoot5"..tostring(id),tostring(e.StateC))
								GUI:BulletText(".StateD") GUI:SameLine(200) GUI:InputText("##devLoot6"..tostring(id),tostring(e.StateD))
								GUI:TreePop()
							end
						end
					end
				else
					GUI:Text("No Loot Available...")
				end				
				GUI:PopItemWidth()
				GUI:TreePop()
			end
--  END LOOTLIST
			
			
			if ( GUI:TreeNode("Shop List")) then
				GUI:PushItemWidth(200)
				local slist = Inventory:GetShopList()
				if (table.valid(slist)) then
					for id, e in pairs(slist) do
						if ( GUI:TreeNode(tostring(id).." - "..e.name) ) then
							GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##devSEhop1"..tostring(id),tostring(string.format( "%X",e.ptr)))
							GUI:BulletText(".slot") GUI:SameLine(200) GUI:InputText("##devSEhop2"..tostring(id),tostring(e.slot))
							GUI:BulletText(".shopid") GUI:SameLine(200) GUI:InputText("##devSEhop3"..tostring(id),tostring(e.shopid))
							GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devSEhop3"..tostring(id),tostring(e.id))							
							GUI:BulletText(".price") GUI:SameLine(200) GUI:InputText("##devSEhop4"..tostring(id),tostring(e.price))
							GUI:BulletText(".count") GUI:SameLine(200) GUI:InputText("##devSEhop5"..tostring(id),tostring(e.count))
							GUI:TreePop()
						end
					end					
				else
					GUI:Text("No NPC Shop List Available...")
				end				
				GUI:PopItemWidth()
				GUI:TreePop()
			end
--  END SHOPLIST



			if ( GUI:TreeNode("ServerList")) then
				GUI:PushItemWidth(200)
				local servers = GetServerList()
				if (table.valid(servers)) then
					for id, e in pairs(servers) do
						GUI:Text(tostring(id).." - "..e.name) GUI:SameLine()
						if (GUI:Button("Select##"..tostring(id),50,15) ) then SelectServer(id) end
					end
				else
					GUI:Text("Not in Character Select screen...")
				end				
				GUI:PopItemWidth()
				GUI:TreePop()
			end
-- END SERVERLIST 


			if ( GUI:TreeNode("UI Permissions")) then
				for i=0,165 do
					GUI:Text("UI Element "..i.." = "..tostring(GetUIPermission(i)))
				end
			end
-- END UI PERMISSIONS


			if ( GUI:TreeNode("Utility Functions & Info")) then
				GUI:PushItemWidth(200)
				if (dev.sendcmd == nil ) then dev.sendcmd = "" end
				dev.sendcmd = GUI:InputText("##devuf1", dev.sendcmd) GUI:SameLine()	if (GUI:Button("SendCommand",100,15) ) then SendTextCommand(dev.sendcmd) end
				
				local p = Player
				if ( p ) then 
					GUI:BulletText("Map ID") GUI:SameLine(200) GUI:InputText("##devuf2",tostring(p.localmapid))
					GUI:BulletText("Map Name") GUI:SameLine(200) GUI:InputText("##devuf3",GetMapName(p.localmapid))
					
				end
				
				GUI:PopItemWidth()
				GUI:TreePop()
			end
-- END UTILITY FUNCTIONS & INFO		

			
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
		local cinfo = c.castinginfo
		if ( table.size(cinfo) > 0) then
			GUI:BulletText("Casting ID") GUI:SameLine(200) GUI:InputText("##dev38", tostring(cinfo.castingid))
			GUI:BulletText("Casting Time") GUI:SameLine(200) GUI:InputText("##dev39", tostring(cinfo.casttime))
			GUI:BulletText("Casting TargetCount") GUI:SameLine(200) GUI:InputText("##dev40", tostring(cinfo.castingtargetcount))
			if ( GUI:TreeNode("Casting Targets") ) then
				local ct = cinfo.castingtargets			
				if ( table.size(ct) > 0) then
					for tid, target in pairs(ct) do
						GUI:BulletText("Target "..tostring(tid)) GUI:SameLine(200) GUI:InputText("##dev45"..tostring(tid), tostring(target))
					end
				end
				GUI:TreePop()
			end	
			GUI:BulletText("Last Cast ID") GUI:SameLine(200) GUI:InputText("##dev41", tostring(cinfo.lastcastid))
			GUI:BulletText("Channeling ID") GUI:SameLine(200) GUI:InputText("##dev42", tostring(cinfo.channelingid))
			GUI:BulletText("Channeling Target ID") GUI:SameLine(200) GUI:InputText("##dev43", tostring(cinfo.channeltargetid))
			GUI:BulletText("Channeling Time") GUI:SameLine(200) GUI:InputText("##dev44", tostring(cinfo.channeltime))
			
		end
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










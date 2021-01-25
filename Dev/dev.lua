dev = {}
dev.GUI = {
	open = false,
	visible = true,
}
dev.job_class = {
	[19] = 1,
	[20] = 2,
	[21] = 3,
	[22] = 4,
	[23] = 5,
	[24] = 6,
	[25] = 7,
	[27] = 26,
	[28] = 26,
	[30] = 29,
}

dev.renderobjdrawmode = { [0] = "POINTS", [1] = "LINES", [2] = "TRIANGLES", }

function dev.Init()
	gDevFilterActions = true	
	gDevAddonTextFilter = ""
	gDevAddonOpenFilter = false
	gDevAddonClosedFilter = false
	gDevHackMaxZoom = 20.0
	gDevHackMinZoom = 1.5
	gDevHackDisableCutscene = false
	gDevHackDisableRendering = false
	gDevHackFlySpeed = 20.0
	gDevHackWalkSpeed = 6.0
	gDevHackWalkSpeedBwd = 2.4000000953674
	gDevHackMountSpeed = 9.0
	gDevHackMountSpeedBwd = 3.2000000476837
	gDevScannerString = "alive,aggressive"
	gDevRecordNPCs = false
	gDevRecordedNPCs = {}
	gDevX = 0
	gDevY = 0
end


RegisterEventHandler("Module.Initalize",dev.Init,"dev.Init")

dev.logUiEvent = false

RegisterEventHandler("Game.UIEvent", function(eventName, eventJson) 
	if dev.logUiEvent then
		d(eventJson)
	end
end, "Game.UIEvent")

function dev.ChatTest()
	SendTextCommand("/say "..tostring(os.time(os.date('*t'))))
end

function dev.DrawCall(event, ticks )
	
	if ( dev.GUI.open  ) then 
		GUI:SetNextWindowPosCenter(GUI.SetCond_Appearing)
		GUI:SetNextWindowSize(500,400,GUI.SetCond_FirstUseEver) --set the next window size, only on first ever
		dev.GUI.visible, dev.GUI.open = GUI:Begin("Dev-Monitor", dev.GUI.open)
		if ( dev.GUI.visible ) then 
			local gamestate = GetGameState()
									
			GUI:PushStyleVar(GUI.StyleVar_FramePadding, 4, 0)
			GUI:PushStyleVar(GUI.StyleVar_ItemSpacing, 8, 2)

			if ( GUI:TreeNode("UI Events")) then
				dev.logUiEvent = GUI:Checkbox("Logs UI events", dev.logUiEvent)
				GUI:TreePop()
			end
			-- cbk: Addon Controls
			
			if ( GUI:TreeNode("AddonControls")) then
				GUI:PushItemWidth(200); gDevAddonTextFilter = GUI:InputText("Filter by Name",gDevAddonTextFilter); GUI:PopItemWidth();
				gDevAddonOpenFilter = GUI:Checkbox("Show Open Only",gDevAddonOpenFilter)
				gDevAddonClosedFilter = GUI:Checkbox("Show Closed Only",gDevAddonClosedFilter)
				
				if ( GUI:TreeNode("Active Controls")) then
					local controls = GetControls()
					if (table.valid(controls)) then
						for id, e in pairs(controls) do
							if (gDevAddonTextFilter == "" or string.contains(e.name,gDevAddonTextFilter)) then
								
								local isopen = e:IsOpen()
								if ((gDevAddonOpenFilter and isopen) or (gDevAddonClosedFilter and not isopen) or (not gDevAddonOpenFilter and not gDevAddonClosedFilter)) then
									GUI:PushItemWidth(150)
									if ( GUI:TreeNode(tostring(id).." - "..e.name.." ("..tostring(table.size(e:GetActions())).." / "..tostring(table.size(e:GetData()))..")") ) then
										GUI:BulletText("Ptr") GUI:SameLine(200) GUI:InputText("##devc0"..tostring(id),tostring(string.format( "%X",e.ptr)))
										
										GUI:BulletText("IsOpen") GUI:SameLine(200) GUI:InputText("##devc1"..tostring(id),tostring(isopen))
										local x,y = e:GetXY()
										GUI:BulletText("Position") GUI:SameLine(200) GUI:InputText("##devc1pos"..tostring(id),tostring(x).. ", "..tostring(y)) 
										GUI:PushItemWidth(50)
										gDevX = GUI:InputText("##devc1pos2"..tostring(id),tostring(gDevX)) 
										GUI:SameLine(140) 
										GUI:PushItemWidth(50)
										gDevY = GUI:InputText("##devc1pos3"..tostring(id),tostring(gDevY))
									
										GUI:SameLine(200)
									
									if (GUI:Button("Set Pos",75,15) ) then e:SetXY(tonumber(gDevX),tonumber(gDevY)) end
										
										
										GUI:PushItemWidth(150)
										
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

											local ad = e:GetData()
											if (table.valid(ad)) then
												for key, value in pairs(ad) do	
													if (type(value) == "table") then
														GUI:BulletText(key)
														for vk,vv in pairs(value) do
															if (type(vv) == "table") then
																GUI:Text("") GUI:SameLine(0,30) GUI:Text("["..tostring(vk).."] -") GUI:SameLine(0,10)
																for vvk,vvv in pairs(vv) do
																	GUI:Text("["..tostring(vvk).."]:") GUI:SameLine(0,5) GUI:Text(vvv) GUI:SameLine(0,5)
																end
															else
																GUI:BulletText(vk) GUI:SameLine(200) GUI:InputText("##devcvdata"..tostring(vk),tostring(vv))
															end
															GUI:NewLine()
														end
													else
														GUI:BulletText(key) GUI:SameLine(200) GUI:InputText("##devcdata"..tostring(key),tostring(value))
													end
												end										
											end
                                        											
											if ( GUI:TreeNode("Strings##"..tostring(id)) ) then
												local str = e:GetStrings()
												if (table.valid(str)) then
													for key, value in pairs(str) do												
														GUI:BulletText(tostring(key)) GUI:SameLine(200) GUI:InputText("##devcdatastr"..tostring(key),value)													
													end										
												end
												GUI:TreePop()
											end	

											if (GUI:TreeNode("RawData##"..tostring(id)) ) then
												local datas = e:GetRawData()
												if (table.valid(datas)) then	
													GUI:Separator()                                            
													GUI:Columns(3, "##RawDataDetails",true)
													GUI:Text("Index"); GUI:NextColumn()
													GUI:Text("Type"); GUI:NextColumn()
													GUI:Text("Value"); GUI:NextColumn()
													GUI:Separator()             
													for index, data in pairs(datas) do			
														if (data.type ~= "0") then
															GUI:Text(tostring(index)) GUI:NextColumn()
															GUI:Text(tostring(data.type)) GUI:NextColumn()
															GUI:PushItemWidth(500)
															if (data.type == "int32") then
																GUI:Text(tostring(data.value))
															elseif (data.type == "uint32") then
																GUI:Text(tostring(data.value))
															elseif (data.type == "bool") then
																GUI:Text(tostring(data.value))
															elseif (data.type == "string") then
																GUI:Text(data.value)
															elseif (data.type == "float") then
																GUI:Text(tostring(data.value))
															elseif (data.type == "4bytes") then
																GUI:Text("A: "..tostring(data.value.A).." B: "..tostring(data.value.B).." C: "..tostring(data.value.C).." D: "..tostring(data.value.D))
															else
																GUI:Text("")  
															end        
															GUI:NextColumn()  
															GUI:PopItemWidth()                                           
														end
													end	
													GUI:Separator()
													GUI:Columns(1)		
												end
												GUI:TreePop()
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
						end
					end
					GUI:TreePop()
				end	
				if ( GUI:TreeNode("All Controls")) then	
					local controls = GetControlList()
					GUI:PushItemWidth(200)
					if (table.valid(controls)) then
						for id, e in pairs(controls) do
							if (gDevAddonTextFilter == "" or string.contains(e,gDevAddonTextFilter)) then
								GUI:BulletText("ID: "..tostring(id)) GUI:SameLine(150) GUI:InputText("##devac0"..tostring(id), e) 
								GUI:SameLine() 
								if (GUI:Button("Create##"..tostring(id),50,15) ) then d("Creating Control Result: "..tostring(CreateControl(id))) end
							end
						end
					end
					GUI:PopItemWidth()
					GUI:TreePop()
				end				
				GUI:TreePop()
			end
			--End Active Controls
			
			-- cbk: Player
			if ( GUI:TreeNode("Player") ) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					local c = Player
					if ( c ) then dev.DrawGameObjectDetails(c,true) else	GUI:Text("No Player found.") end
                    local mapX, mapY, mapZ = WorldToMapCoords(c.localmapid, c.pos.x, c.pos.y, c.pos.z)
					
					GUI:BulletText("Map ID") GUI:SameLine(200) GUI:InputText("##devuf2",tostring(c.localmapid))
					GUI:BulletText("Map Name") GUI:SameLine(200) GUI:InputText("##devuf3",GetMapName(c.localmapid))
					GUI:BulletText("Map X") GUI:SameLine(200) GUI:InputText("##devuf4",tostring(mapX))
					GUI:BulletText("Map Y") GUI:SameLine(200) GUI:InputText("##devuf5",tostring(mapY))
					GUI:BulletText("Map Z") GUI:SameLine(200) GUI:InputText("##devuf6",tostring(mapZ))
					GUI:BulletText("Pulse Duration") GUI:SameLine(200) GUI:InputText("##devuf7",tostring(GetBotPerformance()))
					
					if ( GUI:TreeNode("Gauge Data") ) then
						local g = Player.gauge
						if ( table.valid(g)) then
							for i,k in pairs (g) do
								GUI:BulletText(tostring(i)..": ") GUI:SameLine(200) GUI:InputText("##devegg"..tostring(i),tostring(k))	
							end							
						end
						GUI:TreePop()
					end
					
					if ( GUI:TreeNode("Job Levels")) then
						local lev = Player.levels
						if (table.valid(lev)) then
							for key, value in pairs(lev) do
								GUI:BulletText("Job: "..tostring(key).." - Level: "..tostring(value))							
							end
						end
						GUI:TreePop()
					end
					
					if ( GUI:TreeNode("Stats & Char Attributes")) then
						local stat = Player.stats
						if (table.valid(stat)) then
							for key, value in pairs(stat) do
								GUI:BulletText(tostring(key).." - Value: "..tostring(value))							
							end
						end
						
						for i = 0, 100 do
							local s = Player:GetStats(i)
							if(s)then
								GUI:BulletText("Index: "..tostring(i).." - Value: "..tostring(s))
							end
						end
						GUI:TreePop()
					end
					
					if ( GUI:TreeNode("Game Settings")) then
                        local settings = Player.settings
						GUI:BulletText("AutoFace: "..tostring(settings.autoface))
                        GUI:SameLine()
                        if GUI:Button("Enable##enable_autoface") then Player:SetAutoFace(true) end
                        GUI:SameLine()
                        if GUI:Button("Disable##disable_autoface") then Player:SetAutoFace(false) end
						GUI:BulletText("MoveMode: "..tostring(settings.movemode))
                        GUI:SameLine()
                        if GUI:Button("Set Standard") then Player:SetMoveMode(0) end
                        GUI:SameLine()
                        if GUI:Button("Set Legacy") then Player:SetMoveMode(1) end
						GUI:TreePop()
					end

					if (GUI:TreeNode("Gearsets")) then
						for i, gs in ipairs(Player:GetGearSetList()) do
							if (GUI:TreeNode(tostring(i) .. " - " .. gs.name)) then
								GUI:BulletText("Name") GUI:SameLine(200) GUI:InputText("##devgearsetname" .. tostring(i), gs.name)
								GUI:BulletText("Job") GUI:SameLine(200) GUI:InputText("##devgearsetjob" .. tostring(i), gs.job)
								if (GUI:Button("Equip##" .. "devgs" .. tostring(i), 100, 15)) then
									SendTextCommand("/gs equip " .. tostring(i)) -- the command is "/gs equip 1" where 1 is the index of the gear set, GetGearSetList() returns them in order
								end
								GUI:TreePop()
							end
						end
						GUI:TreePop()
					end
				else
					GUI:Text("Not Ingame...")
				end
				GUI:TreePop()
			end
-- END PLAYER INFO		
			
			-- cbk: Player Pet
			if (Player.pet) then
				if ( GUI:TreeNode("Pet") ) then
					if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
						local c = Player.pet
						if ( c ) then dev.DrawGameObjectDetails(c,false,true) else	GUI:Text("No pet found.") end
					else
						GUI:Text("Not Ingame...")
					end
					GUI:TreePop()
				end
			end
			
			-- cbk: Target
			if ( GUI:TreeNode("Target") ) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					local c = Player:GetTarget()
					if ( c ) then dev.DrawGameObjectDetails(c) else	GUI:Text("No target found.") end
				else
					GUI:Text("Not Ingame...")
				end
				GUI:TreePop()
			end
						
			-- cbk: Scanner
			if ( GUI:TreeNode("Scanner") ) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					GUI:Separator()
					GUI:Text("EntityList")
					GUI:PushItemWidth(500)
					gDevScannerString = GUI:InputText("##scanner-string",gDevScannerString);
					GUI:PopItemWidth()
					GUI:Separator()
					local el = EntityList(gDevScannerString)
					if (table.valid(el)) then
						GUI:Columns(9, "##dev-scanner-details",true)
						
						GUI:Text("Identity"); GUI:NextColumn()
						GUI:Text("Current Target"); GUI:NextColumn()
						GUI:Text("Casting"); GUI:NextColumn()
						GUI:Text("Casttime"); GUI:NextColumn()
						GUI:Text("Channeling"); GUI:NextColumn()
						GUI:Text("Channeltime"); GUI:NextColumn()
						GUI:Text("Channel Target"); GUI:NextColumn()
						GUI:Text("Animation"); GUI:NextColumn()
						GUI:Text("Last Anim"); GUI:NextColumn()
						
						for i, entity in pairs(el) do
							GUI:Text(entity.name.." ["..tostring(entity.contentid).."]"); GUI:NextColumn();
							
							local targetname = ""
							if (entity.targetid ~= 0) then
								local target = EntityList:Get(entity.targetid)
								if (target and target.name ~= nil) then
									targetname = target.name
								end
							end
							GUI:Text(targetname); GUI:NextColumn();
							local castname, channelname = "", ""
							local castlookup, channellookup
							local ci = entity.castinginfo
							if (ci) then
								castlookup = SearchAction(ci.castingid,1)
								channellookup = SearchAction(ci.channelingid,1)
							end
							if (castlookup and castlookup[1]) then 
								castname = IsNull(castlookup[1].name,"") 
							end
							if (channellookup and channellookup[1]) then 
								channelname = IsNull(channellookup[1].name,"") 
							end
							
							GUI:Text(castname.."["..tostring(ci.castingid).."]"); GUI:NextColumn();
							GUI:Text(ci.casttime); GUI:NextColumn();
							GUI:Text(channelname.."["..tostring(ci.channelingid).."]"); GUI:NextColumn();
							GUI:Text(ci.channeltime); GUI:NextColumn();
							
							targetname = ""
							if (ci.channeltargetid ~= 0) then
								local target = EntityList:Get(ci.channeltargetid)
								if (target and target.name ~= nil) then
									targetname = target.name
								end
							end
							GUI:Text(targetname); GUI:NextColumn();
							
							GUI:Text(entity.action); GUI:NextColumn();
							GUI:Text(entity.lastaction); GUI:NextColumn();
						end
						
						GUI:Columns(1)
					end
				else
					GUI:Text("Not Ingame...")
				end
				GUI:TreePop()
			end
						
			-- cbk: ActionList
			if ( GUI:TreeNode("ActionList")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					GUI:PushItemWidth(100)	
					GUI:BulletText("IsCasting") GUI:SameLine(200) GUI:InputText("##devac22",tostring(ActionList:IsCasting())) GUI:SameLine()
					if (GUI:Button("StopCasting",100,15) ) then d("StopCasting Result: "..tostring(ActionList:StopCasting())) end
					GUI:BulletText("Is Hotbar Ready") GUI:SameLine(200) GUI:InputText("##devac23",tostring(ActionList:IsReady())) 
					gDevFilterActions = GUI:Checkbox("Filter Actions",gDevFilterActions)
					GUI:PopItemWidth()
					GUI:PushItemWidth(200)
					local actiontypes = ActionList:GetTypes()
					if (table.valid(actiontypes)) then
						for actiontype, e in pairs(actiontypes) do
							if ( GUI:TreeNode(tostring(actiontype).." - "..e)) then
								local actionlist = ActionList:Get(actiontype) 	-- ALTERNATIVE:  ActionList:Get(actiontype, skillID) , to get the single action back
								if (table.valid(actionlist)) then
									for actionid, action in pairs(actionlist) do
										if (not gDevFilterActions or (action.usable)) then
											--local action = ActionList:Get(actiontype,actionid)
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
												GUI:BulletText("IsGroundTargeted") GUI:SameLine(250) GUI:InputText("##devac17"..tostring(actionid),tostring(action.isgroundtargeted))
												GUI:BulletText("IsReady(Player)") GUI:SameLine(250) GUI:InputText("##devac20"..tostring(actionid),tostring(action:IsReady()))
												GUI:BulletText("IsFacing(Player)") GUI:SameLine(250) GUI:InputText("##devac21"..tostring(actionid),tostring(action:IsFacing()))
												GUI:BulletText("CanCastResult(Player)") GUI:SameLine(250) GUI:InputText("##devac24"..tostring(actionid),tostring(action:CanCastResult()))
												GUI:BulletText(".usable") GUI:SameLine(200) GUI:InputText("##devac22"..tostring(actionid),tostring(action.usable))
												
												if (action.type == 1) then
													GUI:BulletText(".attacktype") GUI:SameLine(200) GUI:InputText("##devac26"..tostring(actionid),tostring(action.attacktype))
													GUI:BulletText(".cooldowngroup") GUI:SameLine(200) GUI:InputText("##devac27"..tostring(actionid),tostring(action.cooldowngroup))
													GUI:BulletText(".statusgainedid") GUI:SameLine(200) GUI:InputText("##devac28"..tostring(actionid),tostring(action.statusgainedid))
													GUI:BulletText(".secondarycostid") GUI:SameLine(200) GUI:InputText("##devac29"..tostring(actionid),tostring(action.secondarycostid))
													GUI:BulletText(".aspect") GUI:SameLine(200) GUI:InputText("##devac30"..tostring(actionid),tostring(action.aspect))
													GUI:BulletText(".category") GUI:SameLine(200) GUI:InputText("##devac31"..tostring(actionid),tostring(action.category))
													GUI:BulletText(".primarycosttype") GUI:SameLine(200) GUI:InputText("##devac32"..tostring(actionid),tostring(action.primarycosttype))
												end

												if (action.type == 13) then
													GUI:BulletText(".canfly") GUI:SameLine(200) GUI:InputText("##devac23"..tostring(actionid),tostring(action.canfly))
												end												
												local tar = Player:GetTarget()
												if ( tar ) then
													GUI:BulletText("IsReady(Target)") GUI:SameLine(250) GUI:InputText("##devac18"..tostring(actionid),tostring(action:IsReady(tar.id)))
													GUI:BulletText("IsFacing(Target)") GUI:SameLine(250) GUI:InputText("##devac19"..tostring(actionid),tostring(action:IsFacing(tar.id)))
													GUI:BulletText("CanCastResult(Target)") GUI:SameLine(250) GUI:InputText("##devac25"..tostring(actionid),tostring(action:CanCastResult(tar.id)))
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

			-- cbk: Aether Currents
			if ( GUI:TreeNode("Aether Currents List")) then					
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(200)
					local aeclist = Player:GetAetherCurrentsList()
					if (table.valid(aeclist)) then
						for id, e in pairs(aeclist) do
							if ( GUI:TreeNode(tostring(id).." - "..GetMapName(e.mapid))) then
								GUI:BulletText(".isattuned") GUI:SameLine(200) GUI:InputText("##devaec0"..tostring(id),tostring(e.isattuned))	
								GUI:BulletText(".mapid") GUI:SameLine(200) GUI:InputText("##devaec1"..tostring(id),tostring(e.mapid))	
								for statidx, statvalue in pairs(e.status) do
									GUI:BulletText(".status["..tostring(statidx).."]") GUI:SameLine(200) GUI:InputText("##devaec2"..tostring(id)..tostring(statidx),tostring(statvalue))	
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
-- END Aether Currents LIST

			-- cbk: Aetheryte List
			if ( GUI:TreeNode("Aetheryte List")) then				
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(200)
					local aelist = Player:GetAetheryteList()
					if (table.valid(aelist)) then
						for id, e in pairs(aelist) do
							if ( GUI:TreeNode(tostring(e.id).." - "..e.name)) then
								GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##devae0"..tostring(id),tostring(string.format( "%X",e.ptr)))
								GUI:BulletText(".ptr2") GUI:SameLine(200) GUI:InputText("##devae1"..tostring(id),tostring(string.format( "%X",e.ptr2)))
								GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devae2"..tostring(id),tostring(e.id))
								GUI:BulletText(".internalid") GUI:SameLine(200) GUI:InputText("##devae10"..tostring(id),tostring(e.internalid))								
								GUI:BulletText(".ishomepoint") GUI:SameLine(200) GUI:InputText("##devae3"..tostring(id),tostring(e.ishomepoint))
								GUI:BulletText(".region") GUI:SameLine(200) GUI:InputText("##devae4"..tostring(id),tostring(e.region))
								GUI:BulletText(".islocalmap") GUI:SameLine(200) GUI:InputText("##devae5"..tostring(id),tostring(e.islocalmap))
								GUI:BulletText(".isattuned") GUI:SameLine(200) GUI:InputText("##devae6"..tostring(id),tostring(e.isattuned))
								GUI:BulletText(".isfavpoint") GUI:SameLine(200) GUI:InputText("##devae7"..tostring(id),tostring(e.isfavpoint))
								GUI:BulletText(".price") GUI:SameLine(200) GUI:InputText("##devae8"..tostring(id),tostring(e.price))
								GUI:BulletText(".mapid") GUI:SameLine(200) GUI:InputText("##devae9"..tostring(id),tostring(e.territory))
                                for k,levelId in pairs(e.levels) do
                                    GUI:BulletText(".levels["..tostring(k).."]") GUI:SameLine(200) GUI:InputText("##devae10level"..tostring(id)..tostring(k),tostring(levelId))
                                    GUI:SameLine() 
                                    if (GUI:Button("Teleport##"..tostring(id)..tostring(k),70) ) then 
                                        d("Teleport Result: "..tostring(Player:Teleport(e.id, levelId))) 
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
-- END Aetheryte LIST

			if ( GUI:TreeNode("Chat Log")) then
				local clog = GetChatLines()
				if ( table.valid(clog)) then
					GUI:PushItemWidth(200)
					for i,k in pairs(clog) do
						if ( GUI:TreeNode("Line -"..tostring(i))) then
							GUI:BulletText(".line") GUI:SameLine(200) GUI:InputText("##CH1"..tostring(i),k.line)
							GUI:BulletText(".timestamp") GUI:SameLine(200) GUI:InputText("##CH2"..tostring(i),tostring(k.timestamp))
							GUI:BulletText(".code") GUI:SameLine(200) GUI:InputText("##CH3"..tostring(i),tostring(k.code))
							GUI:BulletText(".subcode") GUI:SameLine(200) GUI:InputText("##CH4"..tostring(i),tostring(k.subcode))
							GUI:TreePop()
						end
					end
					GUI:PopItemWidth()
				end
				GUI:TreePop()
			end				
---  END CHAT	


			-- cbk: Crafting
			if ( GUI:TreeNode("Crafting")) then
				GUI:PushItemWidth(200)
				if ( GUI:TreeNode("Desynth Skill Level")) then
					local lev = Player.desynthskill
					if (table.valid(lev)) then
						for key, value in pairs(lev) do
							GUI:BulletText("Job: "..tostring(key).." - Level: "..tostring(value))							
						end
					end
					GUI:TreePop()
				end	
				if ( GUI:TreeNode("Craft Mats List")) then
					local cmList = Crafting:GetCraftingMats()
					if (table.valid(cmList)) then
						for id, e in pairs(cmList) do
							if ( GUI:TreeNode(tostring(e.index).." - "..e.name)) then
								GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##deCML0"..tostring(id),tostring(string.format( "%X",e.ptr)))
								GUI:BulletText(".itemid") GUI:SameLine(200) GUI:InputText("##deCML1"..tostring(id),tostring(e.itemid))
								GUI:BulletText(".inventoryhq") GUI:SameLine(200) GUI:InputText("##deCML2"..tostring(id),tostring(e.inventoryhq))
								GUI:BulletText(".inventorynq") GUI:SameLine(200) GUI:InputText("##deCML3"..tostring(id),tostring(e.inventorynq))
								GUI:BulletText(".needed") GUI:SameLine(200) GUI:InputText("##deCML4"..tostring(id),tostring(e.needed))
								GUI:BulletText(".selectedhq") GUI:SameLine(200) GUI:InputText("##deCML5"..tostring(id),tostring(e.selectedhq))
								GUI:BulletText(".selectednq") GUI:SameLine(200) GUI:InputText("##deCML6"..tostring(id),tostring(e.selectednq))
								GUI:TreePop()
							end
						end
					end
					GUI:TreePop()
				end	
				if ( GUI:TreeNode("Selected Craft Info")) then
					if (not dev.craftrecipe) then dev.craftrecipe = 0 end
					GUI:BulletText("Craft Recipe Id") GUI:SameLine(200) dev.craftrecipe = GUI:InputInt("##devci2",dev.craftrecipe) 
					
					--GUI:SameLine()
					-- Takes in no args for just the list, or a recipe id to compare if its the correct index
					local ciList = Crafting:GetSelectedCraftInfo(dev.craftrecipe)
					if(ciList ~= nil) then 
						GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##deCIL001"..tostring(id),tostring(string.format( "%X",ciList.ptr)))
						GUI:BulletText(".class") GUI:SameLine(200) GUI:InputText("##deCIL0"..tostring(id),tostring(ciList.class))
						GUI:BulletText(".page") GUI:SameLine(200) GUI:InputText("##deCIL1"..tostring(id),tostring(ciList.page))
						GUI:BulletText(".selectedindex") GUI:SameLine(200) GUI:InputText("##deCIL2"..tostring(id),tostring(ciList.selectedindex))
						GUI:BulletText(".iscorrectindex") GUI:SameLine(200) GUI:InputText("##deCIL3"..tostring(id),tostring(ciList.iscorrectindex))
						GUI:BulletText(".recipeid") GUI:SameLine(200) GUI:InputText("##deCIL4"..tostring(id),tostring(ciList.recipeid))
						
						GUI:BulletText(".itemid") GUI:SameLine(200) GUI:InputText("##deCIL5"..tostring(id),tostring(ciList.itemid))
						GUI:BulletText(".difficulty") GUI:SameLine(200) GUI:InputText("##deCIL6"..tostring(id),tostring(ciList.difficulty))
						GUI:BulletText(".durability") GUI:SameLine(200) GUI:InputText("##deCIL7"..tostring(id),tostring(ciList.durability))
						GUI:BulletText(".qualitymax") GUI:SameLine(200) GUI:InputText("##deCIL8"..tostring(id),tostring(ciList.qualitymax))
						GUI:BulletText(".recommendedcraftsmanship") GUI:SameLine(200) GUI:InputText("##deCIL9"..tostring(id),tostring(ciList.recommendedcraftsmanship))					
						GUI:BulletText(".canquicksynth") GUI:SameLine(200) GUI:InputText("##deCIL10"..tostring(id),tostring(ciList.canquicksynth))	
						
						
						
						GUI:TreePop()
					end


					GUI:TreePop()
				end	
				GUI:PopItemWidth()
				GUI:TreePop()
			end
--  END CRAFTING	


			if ( GUI:TreeNode("Duty Info")) then
			
			
				GUI:BulletText("IsQueued") GUI:SameLine(200) GUI:InputText("##devDLx1",tostring(Duty:IsQueued()))
				GUI:BulletText("GetQueueStatus") GUI:SameLine(200) GUI:InputText("##devDLx2",tostring(Duty:GetQueueStatus()))
				
				if GUI:TreeNode("GetActiveDutyInfo") then
					local info = Duty:GetActiveDutyInfo()
					if (table.valid(info)) then
						GUI:PushItemWidth(200)
						GUI:BulletText(".name") GUI:SameLine(200) GUI:InputText("##dutyinfo_name",tostring(info.name))
						GUI:BulletText(".timer") GUI:SameLine(200) GUI:InputText("##dutyinfo_timer",tostring(info.timer))
						GUI:BulletText(".dutytype") GUI:SameLine(200) GUI:InputText("##dutyinfo_type",tostring(info.dutytype))
						GUI:BulletText(".dutystep") GUI:SameLine(200) GUI:InputText("##dutyinfo_step",tostring(info.dutystep))
						GUI:PopItemWidth()	
					else
						GUI:Text("Not in duty ...")
					end	
					GUI:TreePop()
				end
				
				if GUI:TreeNode("GetActiveDutyObjectives") then
					local objectives = Duty:GetActiveDutyObjectives()
					if (table.valid(objectives)) then
						GUI:PushItemWidth(200)
						GUI:Separator()                                            
						GUI:Columns(4, "##devdutyobjectives",true)
						GUI:Text("Name"); GUI:NextColumn()
						GUI:Text("Type"); GUI:NextColumn()
						GUI:Text("Values"); GUI:NextColumn()
						GUI:Text("Completed"); GUI:NextColumn()
						GUI:Separator()             
						for idx, data in ipairs(objectives) do		
							GUI:Text(tostring(data.name)) GUI:NextColumn()
							GUI:Text(tostring(data.type)) GUI:NextColumn()
							GUI:Text(tostring(data.values[1]).." / "..tostring(data.values[2])) GUI:NextColumn()
							GUI:Text(tostring(data.completed)) GUI:NextColumn()
						end
						GUI:Separator()
						GUI:Columns(1)	
						GUI:PopItemWidth()	
					else
						GUI:Text("Not in duty ...")
					end	
					GUI:TreePop()
				end

				-- cbk: Duty List v2
				if ( GUI:TreeNode("Duty List (v2)")) then
					if( gamestate == FFXIV.GAMESTATE.INGAME ) then
						if dev.dl_hide_unjoinable == nil then dev.dl_hide_unjoinable = true end
						dev.dl_hide_unjoinable = GUI:Checkbox("Hide unjoinable duty",dev.dl_hide_unjoinable)
						
						GUI:PushItemWidth(200)
						local dList = Duty:GetCompleteDutyList()
						if (table.valid(dList)) then
							for id, e in pairs(dList) do
								if e.canjoin or not dev.dl_hide_unjoinable then
									if ( GUI:TreeNode(string.format("[%d.%d] - %s", e.type, e.id, e.name)) ) then
										local uniqName = tostring(e.type).."_"..tostring(e.id)
										GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devDLv21"..uniqName,tostring(e.id))
										GUI:BulletText(".type") GUI:SameLine(200) GUI:InputText("##devDLv27"..uniqName,tostring(e.type))
										GUI:BulletText(".mapid") GUI:SameLine(200) GUI:InputText("##devDLv22"..uniqName,tostring(e.mapid))
										GUI:BulletText(".requiredlevel") GUI:SameLine(200) GUI:InputText("##devDLv24"..uniqName,tostring(e.requiredlevel))
										GUI:BulletText(".synchlevel") GUI:SameLine(200) GUI:InputText("##devDLv25"..uniqName,tostring(e.synclevel))
										GUI:BulletText(".partysize") GUI:SameLine(200) GUI:InputText("##devDLv26"..uniqName,tostring(e.partysize))
										GUI:BulletText(".canjoin") GUI:SameLine(200) GUI:InputText("##devDLv27"..uniqName,tostring(e.canjoin))
										GUI:BulletText(".completed") GUI:SameLine(200) GUI:InputText("##devDLv28"..uniqName,tostring(e.completed))
										if GUI:Button("Join duty##"..uniqName) then
											-- Can take multiple parameters to queue multiple duty (only for duty type 2)
											-- ex: JoinDuty(type, id1, id2, ...)
											Duty:JoinDuty(e.type, e.id) 
										end
										GUI:TreePop()
									end
								end
							end
						else
							GUI:Text("No duties found...")
						end	
						GUI:PopItemWidth()
					else
						GUI:Text("Not Ingame...")
					end				
					GUI:TreePop()
				end	
				
				
				-- cbk: Duty List
				if ( GUI:TreeNode("Duty List")) then
					if( gamestate == FFXIV.GAMESTATE.INGAME ) then
						GUI:PushItemWidth(200)
						local dList = Duty:GetDutyList()
						if (table.valid(dList)) then
							for id, e in pairs(dList) do
								if ( GUI:TreeNode(e.name) ) then
									GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##devDL0"..tostring(id),tostring(string.format( "%X",e.ptr)))
									GUI:BulletText(".ptr2") GUI:SameLine(200) GUI:InputText("##devDL7"..tostring(id),tostring(string.format( "%X",e.ptr2)))
									GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devDL1"..tostring(id),tostring(e.id))
									GUI:BulletText(".type") GUI:SameLine(200) GUI:InputText("##devDL7"..tostring(id),tostring(e.type))
									GUI:BulletText(".internalid") GUI:SameLine(200) GUI:InputText("##devDL8"..tostring(id),tostring(e.internalid))
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
					else
						GUI:Text("Not Ingame...")
					end				
					GUI:TreePop()
				end
					
				GUI:TreePop()
			end
			
			-- cbk: EnmityList
			if ( GUI:TreeNode("EnmityList")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					GUI:PushItemWidth(200)
					local enist = Player:GetEnmityList()
					if (table.valid(enist)) then
						for id, e in pairs(enist) do
							GUI:BulletText("TargetID: "..tostring(e.targetid).." Enmity: "..tostring(e.enmity))
						end
					else
						GUI:Text("No Enmity Available...")
					end				
					GUI:PopItemWidth()
				else
					GUI:Text("Not Ingame...")
				end
				GUI:TreePop()
			end
--End ENMITYLIST

			-- cbk: Fates
			if ( GUI:TreeNode("Fates")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					GUI:PushItemWidth(200)
					local flist = GetFateList()
					if (table.valid(flist)) then
						for id, e in pairs(flist) do
							if ( GUI:TreeNode(tostring(e.id).." - "..e.name)) then
								GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##devufa1",tostring(string.format( "%X",e.ptr)))
								GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devufa2",tostring(e.id))
								GUI:BulletText(".type") GUI:SameLine(200) GUI:InputText("##devufa3",tostring(e.type))
								GUI:BulletText(".status") GUI:SameLine(200) GUI:InputText("##devufa4",tostring(e.status))
								GUI:BulletText(".duration") GUI:SameLine(200) GUI:InputText("##devufa7",tostring(e.duration))
								GUI:BulletText(".completion") GUI:SameLine(200) GUI:InputText("##devufa8",tostring(e.completion))
								GUI:BulletText(".level") GUI:SameLine(200) GUI:InputText("##devufa5",tostring(e.level))
								GUI:BulletText(".maxlevel") GUI:SameLine(200) GUI:InputText("##devufa6",tostring(e.maxlevel))									
								GUI:BulletText(".radius") GUI:SameLine(200) GUI:InputText("##devufa9",tostring(e.radius))
								GUI:BulletText("Position") GUI:SameLine(200)  GUI:InputFloat3( "##devufa10", e.x, e.y, e.z, 2, GUI.InputTextFlags_ReadOnly)
								GUI:BulletText(".postype") GUI:SameLine(200) GUI:InputText("##devufa12",tostring(e.postype))
								
								GUI:PushItemWidth(150)
								GUI:BulletText("SyncLevel") GUI:SameLine(200) GUI:InputText("##devufa11",tostring(Player:GetSyncLevel()))
								GUI:SameLine()
								if (GUI:Button("Sync##"..tostring(id),100,15) ) then Player:SyncLevel() end
								GUI:PopItemWidth()
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

			-- cbk: Fishing
			if ( GUI:TreeNode("Fishing")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(150)
					GUI:BulletText("FishingState") GUI:SameLine(200) GUI:InputText("##devfi0",tostring(Player:GetFishingState()))
					GUI:BulletText("GetGigHead") GUI:SameLine(200) GUI:InputText("##devfi5",tostring(Player:GetGigHead()))
					local lastCatchID = Player:GetLastCatchId()
					if (dev.lastCatchID == nil) then
						dev.lastCatchID = 0
						dev.lastCatchReset = true
						dev.lastCatchName = ""
					end
					if (tonumber(lastCatchID) ~= nil) then
						if (lastCatchID == 0) then
							dev.lastCatchReset = true
						elseif (lastCatchID ~= 0 and dev.lastCatchReset) then
							dev.lastCatchID = lastCatchID
							if (lastCatchID > 1000000) then
								dev.lastCatchName =  AceLib.API.Items.GetNameByID(lastCatchID - 1000000).." (HQ)"
							elseif (lastCatchID > 500000 and lastCatchID < 600000) then
								dev.lastCatchName =  AceLib.API.Items.GetNameByID(lastCatchID - 500000).." (C)"
							else
								dev.lastCatchName =  AceLib.API.Items.GetNameByID(lastCatchID)
							end
						end
					end
					
					GUI:BulletText("LastCatchId") GUI:SameLine(200) GUI:InputText("##devfi6",tostring(lastCatchID))
					GUI:BulletText("LastCatch (ID)") GUI:SameLine(200) GUI:InputText("##devfi6",tostring(dev.lastCatchID))
					GUI:BulletText("LastCatch (Name)") GUI:SameLine(200) GUI:InputText("##devfi6.1",tostring(dev.lastCatchName ))
					
					GUI:BulletText("GetBait") GUI:SameLine(200) GUI:InputText("##devfi1",tostring(Player:GetBait()))					
					if (not dev.fishbait) then dev.fishbait = 0 end
					GUI:BulletText("Bait itemID") GUI:SameLine(200) dev.fishbait = GUI:InputText("##devfi2",dev.fishbait) 
					GUI:SameLine()
					if (GUI:Button("Set Bait##"..tostring(id),50,15) ) then Player:SetBait(dev.fishbait) end
					GUI:PopItemWidth()
				else
					GUI:Text("Not Ingame...")
				end
				GUI:TreePop()
			end
-- End Fishing 

			-- cbk: Fish Guide
			if ( GUI:TreeNode("Fish Guide")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					local data = GetControlData("FishGuide")
					if (table.valid(data)) then
						GUI:PushItemWidth(150)
						GUI:BulletText("Mode") GUI:SameLine(200) GUI:InputText("##devfigu0", data.mode)			
						if (GUI:Button("Set Fishing Mode")) then GetControl("FishGuide"):Action("SetFishingMode") end
						GUI:SameLine()
						if (GUI:Button("Set Spear Fishing Mode")) then GetControl("FishGuide"):Action("SetSpearFishingMode") end
						local caughtList = { }
						local uncaughtList = { }
						for _,entry in pairs(data.entries) do
							if entry.caught then
								table.insert(caughtList, entry)
							else
								table.insert(uncaughtList, entry)
							end
						end
						if (GUI:TreeNode("Caught fish ids - "..tostring(#caughtList))) then
							for _,entry in pairs(caughtList) do
								GUI:Text(tostring(entry.id))
							end
							GUI:TreePop();
						end
						if (GUI:TreeNode("Uncaught fish ids - "..tostring(#uncaughtList))) then
							for _,entry in pairs(uncaughtList) do
								GUI:Text(tostring(entry.id))
							end
							GUI:TreePop();
						end
						GUI:PopItemWidth()
					else
						GUI:Text("Fish Guide not open...")
					end
				else
					GUI:Text("Not Ingame...")
				end
				GUI:TreePop()
			end
-- End Fish Guide

			-- cbk: Gathering
			if ( GUI:TreeNode("Gathering")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					GUI:PushItemWidth(200)
					local glist = Player:GetGatherableSlotList()
					if (table.valid(glist)) then
						for id, e in pairs(glist) do
							if ( GUI:TreeNode(tostring(e.index).." - "..e.name)) then
								GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##devga0",tostring(string.format( "%X",e.ptr)))
								GUI:BulletText(".index") GUI:SameLine(200) GUI:InputText("##devga1",tostring(e.index))
								GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devga2",tostring(e.id))
								GUI:BulletText(".chance") GUI:SameLine(200) GUI:InputText("##devga3",tostring(e.chance))
								GUI:BulletText(".hqchance") GUI:SameLine(200) GUI:InputText("##devga4",tostring(e.hqchance))
								GUI:BulletText(".level") GUI:SameLine(200) GUI:InputText("##devga5",tostring(e.level))
								GUI:BulletText(".requiredlevel") GUI:SameLine(200) GUI:InputText("##devga6",tostring(e.requiredlevel))
								GUI:BulletText(".minperception") GUI:SameLine(200) GUI:InputText("##devga7",tostring(e.minperception))
								GUI:BulletText(".quantity") GUI:SameLine(200) GUI:InputText("##devga14",tostring(e.quantity))
								GUI:BulletText(".isunknown") GUI:SameLine(200) GUI:InputText("##devga8",tostring(e.isunknown))
								GUI:BulletText(".iscollectable") GUI:SameLine(200) GUI:InputText("##devga8",tostring(e.iscollectable))
								GUI:BulletText(".UNKNOWN") GUI:SameLine(200) GUI:InputText("##devga9",tostring(e.UNKNOWN))
								GUI:BulletText(".UNKNOWN2") GUI:SameLine(200) GUI:InputText("##devga10",tostring(e.UNKNOWN2))
								GUI:BulletText(".UNKNOWN3") GUI:SameLine(200) GUI:InputText("##devga11",tostring(e.UNKNOWN3))
								GUI:BulletText(".UNKNOWN4") GUI:SameLine(200) GUI:InputText("##devga12",tostring(e.UNKNOWN4))
								GUI:BulletText(".UNKNOWN5") GUI:SameLine(200) GUI:InputText("##devga13",tostring(e.UNKNOWN5))
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
--End GATHERING

			-- cbk: Gathering - Collectable
			if ( GUI:TreeNode("Gathering - Collectable")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					if ( IsControlOpen("GatheringMasterpiece") ) then
						GUI:PushItemWidth(200)
						local e = GetControlData("GatheringMasterpiece")
						if (table.valid(e)) then
							GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##devgac0",tostring(string.format( "%X",e.ptr)))
							GUI:BulletText(".rarity") GUI:SameLine(200) GUI:InputText("##devga1",tostring(e.rarity))
							GUI:BulletText(".raritymax") GUI:SameLine(200) GUI:InputText("##devga2",tostring(e.raritymax))
							GUI:BulletText(".wear") GUI:SameLine(200) GUI:InputText("##devga3",tostring(e.wear))
							GUI:BulletText(".wearmax") GUI:SameLine(200) GUI:InputText("##devga4",tostring(e.wearmax))
							GUI:BulletText(".chance") GUI:SameLine(200) GUI:InputText("##devga5",tostring(e.chance))
							GUI:BulletText(".chancehq") GUI:SameLine(200) GUI:InputText("##devga6",tostring(e.chancehq))
						end				
						GUI:PopItemWidth()
					else
						GUI:Text("GatheringMasterpiece not open..")
					end
				else
					GUI:Text("Not Ingame...")
				end
				GUI:TreePop()
			end
--End GATHERING COLLECTABLE

			-- cbk: Gold Saucer
			if ( GUI:TreeNode("Gold Saucer")) then
                GUI:PushItemWidth(200)
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
                    if ( GUI:TreeNode("Triple Triad")) then
                        local ttinfo = Player:GetTripleTriadInfo()
                        GUI:BulletText("Time Remaining") GUI:SameLine(200) GUI:InputText("##devgstt0", tostring(ttinfo.timeremaining))
                        GUI:BulletText("Match Rule 1") GUI:SameLine(200) GUI:InputText("##devgstt1", tostring(ttinfo.matchrule1))
                        GUI:BulletText("Match Rule 2") GUI:SameLine(200) GUI:InputText("##devgstt2", tostring(ttinfo.matchrule2))
                        if (GUI:TreeNode("Card List")) then
                            local cards = Player:GetGSCardList()
                            GUI:Separator()                                            
                            GUI:Columns(4, "##devgsttcardlist",true)
                            GUI:Text("Id"); GUI:NextColumn()
                            GUI:Text("Type"); GUI:NextColumn()
                            GUI:Text("Rarity"); GUI:NextColumn()
                            GUI:Text("Stats (T-B-L-R)"); GUI:NextColumn()
                            GUI:Separator()             
                            for id, data in pairs(cards) do		
                                GUI:Text(tostring(id)) GUI:NextColumn()
                                GUI:Text(tostring(data.type)) GUI:NextColumn()
                                GUI:Text(tostring(data.rarity)) GUI:NextColumn()
                                GUI:Text(tostring(data.top).." "..tostring(data.bottom).." "..tostring(data.left).." "..tostring(data.right)) GUI:NextColumn()
                            end
                            GUI:Separator()
                            GUI:Columns(1)	
                            GUI:TreePop()
                        end
                        if (GUI:TreeNode("Deck List")) then
                            local decks = Player:GetGSDeckList()
                            for deckidx, cards in pairs(decks) do
                                if ( GUI:TreeNode("Deck #"..tostring(deckidx))) then
                                    GUI:Separator()                                            
                                    GUI:Columns(2, "##devgsttdeck"..tostring(deckidx),true)
                                    GUI:Text("Slot"); GUI:NextColumn()
                                    GUI:Text("CardId"); GUI:NextColumn()
                                    GUI:Separator()             
                                    for slot, cardid in pairs(cards) do		
                                        GUI:Text(tostring(slot)) GUI:NextColumn()
                                        GUI:Text(tostring(cardid)) GUI:NextColumn()
                                    end
                                    GUI:Separator()
                                    GUI:Columns(1)	
                                    GUI:TreePop()
                                end
                            end
                            GUI:TreePop()
                        end
                        local ttcontrol = GetControl("TripleTriad")
                        if ( ttcontrol ~= nil ) then
                            GUI:BulletText("Team Turn") GUI:SameLine(200) GUI:InputText("##devgstt1", tostring(ttinfo.teamturn))	
                            if (GUI:TreeNode("Blue Deck") and table.valid(ttinfo.decks[0])) then
                                GUI:Separator()                                            
                                GUI:Columns(6, "##devgsttdeckblue"..tostring(deckidx),true)
                                GUI:Text("Slot"); GUI:NextColumn()
                                GUI:Text("CardId"); GUI:NextColumn()
                                GUI:Text("Team"); GUI:NextColumn()
                                GUI:Text("Rarity"); GUI:NextColumn()
                                GUI:Text("Type"); GUI:NextColumn()
                                GUI:Text("Stats (T-B-L-R)"); GUI:NextColumn()
                                for slot,data in pairs(ttinfo.decks[0]) do
                                    GUI:Text(tostring(slot)) GUI:NextColumn()
                                    GUI:Text(tostring(data.id)) GUI:NextColumn()
                                    GUI:Text(tostring(data.team)) GUI:NextColumn()
                                    GUI:Text(tostring(data.rarity)) GUI:NextColumn()
                                    GUI:Text(tostring(data.type)) GUI:NextColumn()
                                    GUI:Text(tostring(data.top).." "..tostring(data.bottom).." "..tostring(data.left).." "..tostring(data.right)) GUI:NextColumn()
                                end
                                GUI:Separator()
                                GUI:Columns(1)	
                                GUI:TreePop()
                            end
                            if (GUI:TreeNode("Red Deck") and table.valid(ttinfo.decks[1])) then
                                GUI:Separator()                                            
                                GUI:Columns(6, "##devgsttdeckred"..tostring(deckidx),true)
                                GUI:Text("Slot"); GUI:NextColumn()
                                GUI:Text("CardId"); GUI:NextColumn()
                                GUI:Text("Team"); GUI:NextColumn()
                                GUI:Text("Rarity"); GUI:NextColumn()
                                GUI:Text("Type"); GUI:NextColumn()
                                GUI:Text("Stats (T-B-L-R)"); GUI:NextColumn()
                                for slot,data in pairs(ttinfo.decks[1]) do
                                    GUI:Text(tostring(slot)) GUI:NextColumn()
                                    GUI:Text(tostring(data.id)) GUI:NextColumn()
                                    GUI:Text(tostring(data.team)) GUI:NextColumn()
                                    GUI:Text(tostring(data.rarity)) GUI:NextColumn()
                                    GUI:Text(tostring(data.type)) GUI:NextColumn()
                                    GUI:Text(tostring(data.top).." "..tostring(data.bottom).." "..tostring(data.left).." "..tostring(data.right)) GUI:NextColumn()
                                end
                                GUI:Separator()
                                GUI:Columns(1)	
                                GUI:TreePop()
                            end
                            if (GUI:TreeNode("Board Cards") and table.valid(ttinfo.boardcards)) then
                                GUI:Separator()                                            
                                GUI:Columns(6, "##devgsttboardcards"..tostring(deckidx),true)
                                GUI:Text("Slot"); GUI:NextColumn()
                                GUI:Text("CardId"); GUI:NextColumn()
                                GUI:Text("Team"); GUI:NextColumn()
                                GUI:Text("Rarity"); GUI:NextColumn()
                                GUI:Text("Type"); GUI:NextColumn()
                                GUI:Text("Stats (T-B-L-R)"); GUI:NextColumn()
                                for slot,data in pairs(ttinfo.boardcards) do
                                    GUI:Text(tostring(slot)) GUI:NextColumn()
                                    GUI:Text(tostring(data.id)) GUI:NextColumn()
                                    GUI:Text(tostring(data.team)) GUI:NextColumn()
                                    GUI:Text(tostring(data.rarity)) GUI:NextColumn()
                                    GUI:Text(tostring(data.type)) GUI:NextColumn()
                                    GUI:Text(tostring(data.top).." "..tostring(data.bottom).." "..tostring(data.left).." "..tostring(data.right)) GUI:NextColumn()
                                end
                                GUI:Separator()
                                GUI:Columns(1)	
                                GUI:TreePop()
                            end
                            GUI:Separator()
                            if (not dev.playcard_src) then dev.playcard_src = 1 end
                            if (not dev.playcard_dst) then dev.playcard_dst = 1 end
                            if (GUI:Button("Play Card")) then
                                ttcontrol:Action("PlayCard", dev.playcard_src, dev.playcard_dst)
                            end
                            dev.playcard_src = GUI:InputInt("Deck slot##devgsttplaycardsrc", dev.playcard_src)
                            dev.playcard_dst = GUI:InputInt("Board slot##devgsttplaycarddst", dev.playcard_dst)
                        else
                            GUI:Text("Start a game to see more data ...")
                        end
                        GUI:TreePop()
                    end

                    if ( GUI:TreeNode("Chocobo Racing")) then
                        local crinfo = Player:GetChocoboRacingInfo()
                        if crinfo then
                            GUI:BulletText("State") GUI:SameLine(200) GUI:InputText("##devgscr0", tostring(crinfo.state))
                            GUI:BulletText("Completion %") GUI:SameLine(200) GUI:InputText("##devgscr1", tostring(crinfo.completion))
                            GUI:BulletText("Time Elapsed") GUI:SameLine(200) GUI:InputText("##devgscr2", tostring(crinfo.elapsed))
                            GUI:BulletText("Is Lathered") GUI:SameLine(200) GUI:InputText("##devgscr3", tostring(crinfo.lathered))
                            
                            GUI:Separator()
                            if (not dev.chocobo_move_event) then dev.chocobo_move_event = 16 end -- Jump
                            if (GUI:Button("Send Move Event")) then
                                Player:SendChocoboRacingMoveEvent(dev.chocobo_move_event)
                            end
                            GUI:SameLine()
                            dev.chocobo_move_event = GUI:InputInt("Move Type##devgscrmoveinput", dev.chocobo_move_event)
                            
                            if (GUI:TreeNode("Chocobos") and table.valid(crinfo.chocobos)) then
                                GUI:Separator()                                            
                                GUI:Columns(4, "##devgscrchocobos",true)
                                GUI:Text("Slot"); GUI:NextColumn()
                                GUI:Text("Object Id"); GUI:NextColumn()
                                GUI:Text("Name"); GUI:NextColumn()
                                GUI:Text("Stamina"); GUI:NextColumn()
                                for slot,data in pairs(crinfo.chocobos) do
                                    GUI:Text(tostring(slot)) GUI:NextColumn()
                                    GUI:Text(tostring(data.id)) GUI:NextColumn()
                                    GUI:Text(tostring(data.name)) GUI:NextColumn()
                                    GUI:Text(tostring(data.stamina)) GUI:NextColumn()
                                end
                                GUI:Separator()
                                GUI:Columns(1)	
                                GUI:TreePop()
                            end
                        else
                            GUI:Text("Not in a race ...")
                        end
                        GUI:TreePop()
                    end

					if ( GUI:TreeNode("Air Force One")) then
						local shooting_targets = Duty:RideShooting_GetTargets()
						if (GUI:TreeNode("Targets##shooting_targets")) then
							if table.valid(shooting_targets) then
								GUI:Separator()                                            
								GUI:Columns(3, "##devgshootingtargets",true)
								GUI:Text("ID"); GUI:NextColumn()
								GUI:Text("Pos"); GUI:NextColumn()
								GUI:Text("Action"); GUI:NextColumn()
								for _,data in ipairs(shooting_targets) do
									GUI:Text(tostring(data.id)) GUI:NextColumn()
									GUI:Text(string.format("%.0f, %.0f, %.0f", data.x, data.y, data.z)) GUI:NextColumn()
									if GUI:Button("Shoot##shoot_"..tostring(data.id)) then
										d("Shoot", data.id)
										Duty:RideShooting_ShootTarget(data.id)
									end
									GUI:NextColumn()
								end
								GUI:Separator()
								GUI:Columns(1)
							end	
							GUI:TreePop()
						end
                        GUI:TreePop()
                    end
                else
					GUI:Text("Not Ingame...")
				end
                GUI:PopItemWidth()
				GUI:TreePop()
			end
            --End Gold Saucer
			
			-- cbk: Hacks
			if ( GUI:TreeNode("Hacks")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					GUI:PushItemWidth(200)
						if (GUI:Button("ResetCam##",100,15) ) then
							Hacks:ResetCamMaxZoom() 
							gDevHackMaxZoom = 20.0
							gDevHackMinZoom = 1.5
						end
						
						local zoommax, changedmaxzoom = GUI:SliderFloat("CamZoomMax", gDevHackMaxZoom, 1.5, 240)
						if (changedmaxzoom) then
							gDevHackMaxZoom = zoommax
							if (gDevHackMaxZoom < gDevHackMinZoom) then
								gDevHackMinZoom = gDevHackMaxZoom - 1.0
							end
						end
						
						local zoommin, changedminzoom = GUI:SliderFloat("CamZoomMin", gDevHackMinZoom, 1.5, 240)
						if (changedminzoom) then
							gDevHackMinZoom = zoommin
						end
						
						if (changedminzoom or changedmaxzoom) then
							Hacks:SetCamMaxZoom(gDevHackMinZoom,gDevHackMaxZoom)
						end
						
						local disabled, changedcutscene = GUI:Checkbox("Disable Cutscene", gDevHackDisableCutscene)
						if (changedcutscene) then
							gDevHackDisableCutscene = disabled
							Hacks:SkipCutscene(gDevHackDisableCutscene)
						end
						
						local disabled, changedrendering = GUI:Checkbox("Disable Rendering", gDevHackDisableRendering)
						if (changedrendering) then
							gDevHackDisableRendering = disabled
							Hacks:Disable3DRendering(gDevHackDisableRendering)
						end
						
						local hackFlySpeed, changedflyspeed = GUI:SliderFloat("Fly Speed", gDevHackFlySpeed, 10, 100)
						if (changedflyspeed) then
							gDevHackFlySpeed = hackFlySpeed
							Player:SetSpeed(0,gDevHackFlySpeed,gDevHackFlySpeed,gDevHackFlySpeed)	
						end

						local hackWalkSpeed, changedwalkspeed = GUI:SliderFloat("Walk Speed", gDevHackWalkSpeed, 6, 50)
						if (changedwalkspeed) then
							gDevHackWalkSpeed = hackWalkSpeed
							Player:SetSpeed(1,gDevHackWalkSpeed,gDevHackWalkSpeed,gDevHackWalkSpeed)	-- arg 1 = 0 flying 1 walking 2 mounted
						end
						
						local hackMountSpeed, changedmountspeed = GUI:SliderFloat("Mount Speed", gDevHackMountSpeed, 6, 50)
						if (changedmountspeed) then
							gDevHackMountSpeed = hackMountSpeed
							Player:SetSpeed(2,gDevHackMountSpeed,gDevHackMountSpeed,gDevHackMountSpeed)	-- arg 1 = 0 flying 1 walking 2 mounted
						end
						
						if (GUI:Button("ResetSpeed##",100,15) ) then
							Player:ResetSpeed(0) -- flying
							Player:ResetSpeed(1) -- walking
							Player:ResetSpeed(2) -- mounted
							gDevHackFlySpeed = 20.0
							gDevHackWalkSpeed = 6.0
							gDevHackWalkSpeedBwd = 2.4000000953674
							gDevHackMountSpeed = 9.0
							gDevHackMountSpeedBwd = 3.2000000476837	
						end
						

						
					GUI:PopItemWidth()

				else
					GUI:Text("Not Ingame...")
				end
				GUI:TreePop()
			end
--End HACKS

			-- cbk: Inventory
			if ( GUI:TreeNode("Inventory")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then 
					GUI:PushItemWidth(200)		
					if (GUI:TreeNode("Special Currencies")) then
					local cur = Inventory:GetSpecialCurrencies()
						if(table.valid(cur)) then
							for id, currency in pairs(cur) do
								GUI:BulletText(tostring(currency.itemid))
								GUI:SameLine()
								GUI:Text(currency.name)
								GUI:SameLine(360)
								GUI:Text("Count: "..tostring(currency.count))
							end
						end
						GUI:TreePop()
					end
					local inv = Inventory:GetTypes()
					if (table.valid(inv)) then
						for id, e in pairs(inv) do
							if ( GUI:TreeNode(tostring(e))) then
									local bag = Inventory:Get(e) 	-- ALTERNATIVE:  Inventory:Get() , to get the full list
									if (table.valid(bag)) then
										GUI:BulletText("Ptr") GUI:SameLine(200) GUI:InputText("##devbag1"..tostring(id),tostring(string.format( "%X",bag.ptr)))
										GUI:BulletText("Slots/Free/Used") GUI:SameLine(200) GUI:InputInt3("##devbag2"..tostring(id),tostring(bag.size),tostring(bag.free),tostring(bag.used))
										if (GUI:Button("Sort()##",100,15) ) then d(Inventory:SortInventory()) end
										if (GUI:Button("RepairAll()##",100,15) ) then d(bag:RepairAll()) end -- with RepairAll(true) uses darkmater otherwise use gil
										local ilist = bag:GetList() -- can also use bag:GetSortedItemList()
										if (table.valid(ilist)) then
											for slot, item in pairs(ilist) do
												if ( GUI:TreeNode(tostring(slot).." - "..item.name)) then
													GUI:BulletText("Ptr") GUI:SameLine(225) GUI:InputText("##devbag3"..tostring(slot),tostring(string.format( "%X",item.ptr)))
													GUI:BulletText("Ptr2") GUI:SameLine(225) GUI:InputText("##devbag4"..tostring(slot),tostring(string.format( "%X",item.ptr2)))
													GUI:BulletText("ID") GUI:SameLine(225) GUI:InputText("##devbag5"..tostring(slot),tostring(item.id))
													GUI:BulletText("Is HQ") GUI:SameLine(225) GUI:InputText("##devbag19"..tostring(slot),tostring(item.ishq))
													GUI:BulletText("HQID") GUI:SameLine(225) GUI:InputText("##devbag6"..tostring(slot),tostring(item.hqid))
													GUI:BulletText("Slot") GUI:SameLine(225) GUI:InputText("##devbag7"..tostring(slot),tostring(item.slot))
													GUI:BulletText("Parent BagID") GUI:SameLine(225) GUI:InputText("##devbag8"..tostring(slot),tostring(item.type))
													GUI:BulletText("Stack Size") GUI:SameLine(225) GUI:InputText("##devbag9"..tostring(slot),tostring(item.count))
													GUI:BulletText("Max Stack") GUI:SameLine(225) GUI:InputText("##devbag10"..tostring(slot),tostring(item.max))
													GUI:BulletText("Condition") GUI:SameLine(225) GUI:InputText("##devbag11"..tostring(slot),tostring(item.condition))
													GUI:BulletText("Collectability") GUI:SameLine(225) GUI:InputText("##devbag27"..tostring(slot),tostring(item.collectability))
													GUI:BulletText("Spiritbond") GUI:SameLine(225) GUI:InputText("##devbag18"..tostring(slot),tostring(item.spiritbond))
													GUI:BulletText("Level") GUI:SameLine(225) GUI:InputText("##devbag13"..tostring(slot),tostring(item.level))
													GUI:BulletText("Required Level") GUI:SameLine(225) GUI:InputText("##devbag14"..tostring(slot),tostring(item.requiredlevel))
													GUI:BulletText("class") GUI:SameLine(225) GUI:InputText("##devbag17"..tostring(slot),tostring(item.class))
													GUI:BulletText("Category") GUI:SameLine(225) GUI:InputText("##devbag20"..tostring(slot),tostring(item.category))
													GUI:BulletText("UICategory") GUI:SameLine(225) GUI:InputText("##devbag21"..tostring(slot),tostring(item.uicategory))
													GUI:BulletText("SearchCategory") GUI:SameLine(225) GUI:InputText("##devbag22"..tostring(slot),tostring(item.searchcategory))
													GUI:BulletText("CanEquip") GUI:SameLine(225) GUI:InputText("##devbag16"..tostring(slot),tostring(item.canequip))
													GUI:BulletText("EquipSlot") GUI:SameLine(225) GUI:InputText("##devbag15"..tostring(slot),tostring(item.equipslot))
													GUI:BulletText("Price") GUI:SameLine(225) GUI:InputText("##devbag26"..tostring(slot),tostring(item.price))
													GUI:BulletText("MateriaSlotCount") GUI:SameLine(225) GUI:InputText("##devbag28"..tostring(slot),tostring(item.materiaslotcount))
													GUI:BulletText("Materia Free Slots") GUI:SameLine(225) GUI:InputText("##devbag29"..tostring(slot),tostring(item.materiaslotcount - table.size(item.materias)))
													if table.valid(item.materias) then
														for x, y in pairs(item.materias) do
															GUI:BulletText(tostring(x))
															GUI:SameLine(225)
															GUI:InputText("##devbag29"..tostring(y.name),tostring(y.name))
														end
													end
													GUI:BulletText("IsReady") GUI:SameLine(225) GUI:InputText("##devbag25"..tostring(slot),tostring(item:IsReady()))


													GUI:BulletText("Rarity") GUI:SameLine(225) GUI:InputText("##devbag30"..tostring(slot),tostring(item.rarity))
													GUI:BulletText("IsUnique") GUI:SameLine(225) GUI:InputText("##devbag31"..tostring(slot),tostring(item.isunique))
													GUI:BulletText("IsUntradeable") GUI:SameLine(225) GUI:InputText("##devbag32"..tostring(slot),tostring(item.isuntradeable))
													GUI:BulletText("IsCollectable") GUI:SameLine(225) GUI:InputText("##devbag33",tostring(item.iscollectable))
													-- if desynthvalue > 0 then IsDesynthable = true
													GUI:BulletText("DesynthValue") GUI:SameLine(225) GUI:InputText("##devbag34",tostring(item.desynthvalue))
													dev.isDesynthable = ""
													if item.desynthvalue > 0 then
														dev.isDesynthable = "true"
													else
														dev.isDesynthable = "false"
													end
													GUI:BulletText("IsDesynthable") GUI:SameLine(225) GUI:InputText("##devbag35",tostring(dev.isDesynthable))
													GUI:BulletText("RepairClassJob") GUI:SameLine(225) GUI:InputText("##devbag36",tostring(item.repairclassjob))
													GUI:BulletText("RepairItem") GUI:SameLine(225) GUI:InputText("##devbag37",tostring(item.repairitem))
													if item.repairitem > 0 then
														dev.repairItemName = AceLib.API.Items.GetNameByID(item.repairitem) or ""
														GUI:BulletText("RepairItem (Name)") GUI:SameLine(225) GUI:InputText("##devbag38",tostring(dev.repairItemName))
													end
													GUI:BulletText("IsBinding") GUI:SameLine(225) GUI:InputText("##devbag39"..tostring(slot),tostring(item.isbinding))

													local tar = Player:GetTarget()
													if ( tar ) then
														GUI:BulletText("IsReady(Target)") GUI:SameLine(225) GUI:InputText("##devbag24"..tostring(slot),tostring(item:IsReady(tar.id)))
													end

													local materias = item.materias
													if table.valid(materias) and GUI:TreeNode("Materias##devbag_mats"..tostring(slot)) then
														for i,v in ipairs(materias) do
															GUI:Text("Materia #"..tostring(i))
															GUI:BulletText(" ItemId") GUI:SameLine(225) GUI:InputText("##devbag_mat_itemid"..tostring(slot)..tostring(i),tostring(v.itemid))
															GUI:BulletText(" Name") GUI:SameLine(225) GUI:InputText("##devbag_mat_name"..tostring(slot)..tostring(i),tostring(v.name))
															GUI:BulletText(" Attribute") GUI:SameLine(225) GUI:InputText("##devbag_mat_attr"..tostring(slot)..tostring(i),tostring(v.attribute))
															GUI:BulletText(" Value") GUI:SameLine(225) GUI:InputText("##devbag_mat_value"..tostring(slot)..tostring(i),tostring(v.value))
														end
														GUI:TreePop()
													end

													local nqstats = {} -- [type] = stat
													local hqstats = {} -- [type] = hqStat

													for i = 0, 255 do
														if (item:GetStat(i, false) ~= 0) then
															nqstats[i] = item:GetStat(i, false)
														end
														if (item:GetStat(i, true) ~= 0) then
															hqstats[i] = item:GetStat(i, true)
														end
													end

													if table.valid(nqstats) then
														if GUI:TreeNode("NQ Stats##devbags_nqstats_" .. tostring(slot)) then
															for k, v in pairs(nqstats) do
																GUI:BulletText("Type " .. k) GUI:SameLine(225) GUI:InputText("##devbag_nqstat_" .. tostring(slot), tostring(v))
															end
															GUI:TreePop()
														end
													end

													if table.valid(hqstats) then
														if GUI:TreeNode("HQ Stats##devbags_nqstats_" .. tostring(slot)) then
															for k, v in pairs(hqstats) do
																GUI:BulletText("Type " .. k) GUI:SameLine(225) GUI:InputText("##devbag_hqstat_" .. tostring(slot), tostring(v))
															end
															GUI:TreePop()
														end
													end

													local action = item:GetAction()
													if (table.valid(action)) then
														if ( GUI:TreeNode("Action: "..tostring(action.id).." - "..action.name)) then --rather slow making 6000+ names :D
															--if ( GUI:TreeNode(tostring(actionid).." - ")) then
															GUI:BulletText("Ptr") GUI:SameLine(225) GUI:InputText("##devac1"..tostring(action.id),tostring(string.format( "%X",action.ptr)))
															GUI:BulletText("ID") GUI:SameLine(225) GUI:InputText("##devac2"..tostring(action.id),tostring(action.id))
															GUI:BulletText("Type") GUI:SameLine(225) GUI:InputText("##devac3"..tostring(action.id),tostring(action.type))
															GUI:BulletText("SkillType") GUI:SameLine(225) GUI:InputText("##devac4"..tostring(action.id),tostring(action.skilltype))
															GUI:BulletText("Cost") GUI:SameLine(225) GUI:InputText("##devac5"..tostring(action.id),tostring(action.cost))
															GUI:BulletText("CastTime") GUI:SameLine(225) GUI:InputText("##devac6"..tostring(action.id),tostring(action.casttime))
															GUI:BulletText("RecastTime") GUI:SameLine(225) GUI:InputText("##devac7"..tostring(action.id),tostring(action.recasttime))
															GUI:BulletText("IsOnCooldown") GUI:SameLine(225) GUI:InputText("##devac8"..tostring(action.id),tostring(action.isoncd))
															GUI:BulletText("Cooldown") GUI:SameLine(225) GUI:InputText("##devac9"..tostring(action.id),tostring(action.cd))
															GUI:BulletText("CooldownMax") GUI:SameLine(225) GUI:InputText("##devac10"..tostring(action.id),tostring(action.cdmax))

															GUI:BulletText("IsReady(Player)") GUI:SameLine(225) GUI:InputText("##devac20"..tostring(action.id),tostring(action:IsReady()))
															GUI:BulletText("IsFacing(Player)") GUI:SameLine(225) GUI:InputText("##devac21"..tostring(action.id),tostring(action:IsFacing()))
															local tar = Player:GetTarget()
															if ( tar ) then
																GUI:BulletText("IsReady(Target)") GUI:SameLine(225) GUI:InputText("##devac18"..tostring(action.id),tostring(action:IsReady(tar.id)))
																GUI:BulletText("IsFacing(Target)") GUI:SameLine(225) GUI:InputText("##devac19"..tostring(action.id),tostring(action:IsFacing(tar.id)))
															end
															GUI:TreePop()
														end
													else
														GUI:BulletText("No Action Available")
													end

													if (GUI:Button("Cast()##"..tostring(slot),100,15) ) then d("Cast Result: "..tostring(item:Cast())) end
													GUI:SameLine(0,20)
													if (GUI:Button("Cast(Player)##"..tostring(slot),100,15) ) then d("Cast Result: "..tostring(item:Cast(Player.id))) end
													GUI:SameLine(0,20)
													local tar = Player:GetTarget() or Player
													if (GUI:Button("Cast(Target)##"..tostring(item.id),100,15) ) then d("Cast Result: "..tostring(item:Cast(tar.id))) end

													if (GUI:Button("Sell()##"..tostring(slot),100,15) ) then d("Sell Result: "..tostring(item:Sell())) end
													GUI:SameLine(0,20)
													if (GUI:Button("Discard()##"..tostring(slot),100,15) ) then d("Discard Result: "..tostring(item:Discard())) end
													GUI:SameLine(0,20)
													if (GUI:Button("RetrieveMateria()##"..tostring(slot),100,15) ) then d("RetrieveMateria Result: "..tostring(item:RetrieveMateria())) end

													if (GUI:Button("HandOver()##"..tostring(slot),100,15) ) then d("HandOver Result: "..tostring(item:HandOver())) end
													GUI:SameLine(0,20)
													if (GUI:Button("Gardening()##"..tostring(slot),100,15) ) then d("Gardening Result: "..tostring(item:Gardening())) end
													GUI:SameLine(0,20)
													if (GUI:Button("Repair()##"..tostring(slot),100,15) ) then d("Repair Result: "..tostring(item:Repair())) end


													if (GUI:Button("Salvage()##"..tostring(slot),100,15) ) then
														if ( item:CanCast(5, 5) ) then -- Can Cast check of Actiontype "General" , Action "desynthesis" on the item
															d("Salvage Result: "..tostring(item:Salvage()))
														end
													end
													GUI:SameLine(0,20)
													if (GUI:Button("Purify()##"..tostring(slot),100,15) ) then
														if ( item:CanCast(5, 21) ) then -- Can Cast check of Actiontype "General" , Action "purify" on the item
															d("Purify Result: "..tostring(item:Purify()))
														end
													end
													GUI:SameLine(0,20)
													if (GUI:Button("Convert()##"..tostring(slot),100,15) ) then
														if ( item:CanCast(5, 14) ) then -- Can Cast check of Actiontype "General" , Action "materialize" on the item
															d("Convert Result: "..tostring(item:Convert()))
														end
													end
													
													if (GUI:Button("Meld()##"..tostring(slot),100,15) ) then
														if ( item:CanCast(5, 12) or item:CanCast(5, 13)) then -- Can Cast check of Actiontype "General" , Action "meld" on the item, 12 is basic meld, 13 is advanced
															d("Meld Result: "..tostring(item:Meld()))
														end
													end

													if (GUI:Button("Transmute()##"..tostring(slot),100,15) ) then d("Transmute Result: "..tostring(item:Transmute())) end
													GUI:SameLine(0,20)
													if (GUI:Button("SelectFeed()##"..tostring(slot),100,15) ) then d("SelectFeed Result: "..tostring(item:SelectFeed())) end
													GUI:SameLine(0,20)
													if (GUI:Button("Reward()##"..tostring(slot),100,15) ) then d("Reward Result: "..tostring(item:Reward())) end

													-- This Gardening() handles fertilizing and also handing over of items (seeds n stuff)

													local nextAvailableBag = -1
													local nextAvailableSlot = -1

													-- the goal of this loop is to show the difference between Move(qty) and Split(). Split() will call the in game function and requires
													-- no further calculations, Move(qty) is more flexible but requires more work
													-- in this case, Move() and Move(qty) will intentionally ignore all previous bags, and only consider the current and remaining bags

													for b = item.type, 3 do -- item.type is Parent BagID for some reason
														local invList = Inventory:Get(b):GetList()
														local found = false
														for s = 1, 35 do
															if (invList[s] == nil) then
																nextAvailableBag = b
																nextAvailableSlot = s-1
																found = true
																break
															end
														end
														if (found) then break end
													end

													if (GUI:Button("Split()##" .. tostring(slot), 100, 15)) then d("Split Result: " .. tostring(item:Split(1))) end
													GUI:SameLine(0, 20)
													if (GUI:Button("Move()##" .. tostring(slot), 100, 15) and nextAvailableBag ~= -1 and nextAvailableSlot ~= -1) then d("Move Result: " .. tostring(item:Move(nextAvailableBag, nextAvailableSlot))) end
													GUI:SameLine(0, 20)
													if (GUI:Button("Move(qty)##" .. tostring(slot), 100, 15) and nextAvailableBag ~= -1 and nextAvailableSlot ~= -1) then d("Move(qty) Result: " .. tostring(item:Move(nextAvailableBag, nextAvailableSlot, 1))) end

													if (GUI:Button("LowerQuality()##" .. tostring(slot), 100, 15)) then d("LowerItemQuality Result: " .. tostring(item:LowerQuality())) end


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
			
			-- cbk: Loot
			if ( GUI:TreeNode("Loot List")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(200)				
					local list = Inventory:GetLootList()
					if (table.valid(list)) then
						for id, e in pairs(list) do
							if ( GUI:TreeNode(tostring(id)) ) then
								GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##devLoot1"..tostring(id),tostring(string.format( "%X",e.ptr)))
								GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devLoot2"..tostring(id),tostring(e.id))
								GUI:BulletText(".timeleft") GUI:SameLine(200) GUI:InputText("##devLoot3"..tostring(id),tostring(e.timeleft))
								GUI:BulletText(".rollvalue") GUI:SameLine(200) GUI:InputText("##devLoot4"..tostring(id),tostring(e.rollvalue))--	// the "number 0-99 rolled"
								GUI:BulletText(".rollstate") GUI:SameLine(200) GUI:InputText("##devLoot5"..tostring(id),tostring(e.rollstate))--	// 0=No Roll, 1=Need, 2=Greed, 3=Pass  , after rolling that is
								GUI:BulletText(".info") GUI:SameLine(200) GUI:InputText("##devLoot6"..tostring(id),tostring(e.info)) --// 0 = Needable items if loot exists, 1=only greed items available, 17 = already rolled
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
				end
				GUI:TreePop()
			end
--  END LOOTLIST
			
			-- cbk: MapObjects
			if ( GUI:TreeNode("MapObjects")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then					
					dev.mapobjectlisttype = GUI:InputInt("MapList##", dev.mapobjectlisttype or 1)
					if(dev.mapobjectlisttype > 3) then dev.mapobjectlisttype = 3 end
					local list = GetMapObjects(dev.mapobjectlisttype)
					if(table.valid(list))then
						for id, e in pairs(list) do
							if ( GUI:TreeNode(tostring(id).." - "..tostring(e.name))) then
								GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##mapobj1"..tostring(id),tostring(string.format( "%X",e.ptr)))
								GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##mapobj2"..tostring(id),tostring(e.id))								
								GUI:BulletText(".type") GUI:SameLine(200) GUI:InputText("##mapobj3"..tostring(id),tostring(e.type))
								GUI:BulletText(".pos") GUI:SameLine(200) GUI:InputFloat3( "##mapobj4", e.pos.x, e.pos.y, e.pos.z, 2, GUI.InputTextFlags_ReadOnly)
								if(e.entity)then
									local player = e.entity
									GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##devpa0"..tostring(id),tostring(string.format( "%X",player.ptr)))
									GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devpa1"..tostring(id),tostring(player.id))
									GUI:BulletText(".guid") GUI:SameLine(200) GUI:InputText("##devpa9"..tostring(id),tostring(player.guid))								
									GUI:BulletText(".mapid") GUI:SameLine(200) GUI:InputText("##devpa2"..tostring(id),tostring(player.mapid))
									GUI:BulletText(".isleader") GUI:SameLine(200) GUI:InputText("##devpa3"..tostring(id),tostring(player.isleader))								
									GUI:BulletText(".region") GUI:SameLine(200) GUI:InputText("##devpa4"..tostring(id),tostring(player.region))
									GUI:BulletText(".onmesh") GUI:SameLine(200) GUI:InputText("##devpa5"..tostring(id),tostring(player.onmesh))
									local p = player.pos
									GUI:BulletText(".pos") GUI:SameLine(200)  GUI:InputFloat3( "##devpa6", p.x, p.y, p.z, 2, GUI.InputTextFlags_ReadOnly)
									local h = player.hp
									GUI:BulletText(".hp") GUI:SameLine(200)  GUI:InputFloat3( "##devpa7", h.current, h.max, h.percent, 2, GUI.InputTextFlags_ReadOnly)
									h = player.mp
									GUI:BulletText(".mp") GUI:SameLine(200)  GUI:InputFloat3( "##devpa8", h.current, h.max, h.percent, 2, GUI.InputTextFlags_ReadOnly)
									GUI:BulletText(".shield") GUI:SameLine(200)  GUI:InputText("##devpa9"..tostring(id),tostring(player.shield))
									GUI:BulletText(".job") GUI:SameLine(200)  GUI:InputText("##devpa10"..tostring(id),tostring(player.job))
									GUI:BulletText(".state") GUI:SameLine(200)  GUI:InputText("##devpa11"..tostring(id),tostring(player.state))
									GUI:BulletText(".level") GUI:SameLine(200)  GUI:InputText("##devpa12"..tostring(id),tostring(player.level))
								end
								GUI:TreePop()
							end
						end
					end
				else
					GUI:Text("Not Ingame...")
				end
				GUI:TreePop()
			end
			-- END MapObjects

			-- cbk: Movement
			if ( GUI:TreeNode("Movement")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(150)					
					GUI:BulletText("IsMoving") GUI:SameLine(200) GUI:InputText("##devmov1",tostring(Player:IsMoving()))					
					GUI:SameLine()
					if (GUI:Button("Stop##"..tostring(id),50,15) ) then Player:Stop() end 					
					GUI:BulletText("IsMoving Forward") GUI:SameLine(200) GUI:InputText("##devmov2",tostring(Player:IsMoving(FFXIV.MOVEMENT.FORWARD)))
					GUI:BulletText("IsMoving Back") GUI:SameLine(200) GUI:InputText("##devmov3",tostring(Player:IsMoving(FFXIV.MOVEMENT.BACKWARD)))
					GUI:BulletText("IsMoving Left") GUI:SameLine(200) GUI:InputText("##devmov4",tostring(Player:IsMoving(FFXIV.MOVEMENT.LEFT)))
					GUI:BulletText("IsMoving Right") GUI:SameLine(200) GUI:InputText("##devmov5",tostring(Player:IsMoving(FFXIV.MOVEMENT.RIGHT)))
					GUI:BulletText("IsMoving Up") GUI:SameLine(200) GUI:InputText("##devmov6",tostring(Player:IsMoving(FFXIV.MOVEMENT.UP)))
					GUI:BulletText("IsMoving Down") GUI:SameLine(200) GUI:InputText("##devmov7",tostring(Player:IsMoving(FFXIV.MOVEMENT.DOWN)))
					GUI:BulletText("IsJumping") GUI:SameLine(200) GUI:InputText("##devmov8",tostring(Player:IsJumping()))
					GUI:SameLine()
					if (GUI:Button("Jump##"..tostring(id),50,15) ) then Player:Jump() end				
					GUI:BulletText("GetSpeed-Forward") GUI:SameLine(200) GUI:InputText("##devmov9",tostring(Player:GetSpeed()["Forward"]))
					GUI:BulletText("GetSpeed-Backward") GUI:SameLine(200) GUI:InputText("##devmov9a",tostring(Player:GetSpeed()["Backward"]))
					GUI:BulletText("GetSpeed-Strafe") GUI:SameLine(200) GUI:InputText("##devmov9b",tostring(Player:GetSpeed()["Strafe"]))
					
					-- THere is also a Player:SetSpeed(type, forwardspeed, backwardspeeed, strafespeed) 
					-- Where type is 0 for flying, 1 for walking and 2 for mounted speed which you can set seperately
					
					GUI:BulletText("IsFlying") GUI:SameLine(200) GUI:InputText("##devmov11",tostring(Player.flying.isflying))
					GUI:BulletText("CanFlyInZone") GUI:SameLine(200) GUI:InputText("##devmov12",tostring(Player.flying.canflyinzone))
					GUI:BulletText("Pitch") GUI:SameLine(200) GUI:InputText("##devmov13",tostring(Player.flying.pitch))
					if (not dev.pitch) then dev.pitch = 0 end
					GUI:BulletText("SetPitch") GUI:SameLine(200) dev.pitch = GUI:InputFloat("##devmov10",dev.pitch,0,0,2)
					GUI:SameLine()					
					if (GUI:Button("SetPitch##"..tostring(id),50,15) ) then Player:SetPitch(dev.pitch) end
									
					GUI:BulletText("IsSwimming") GUI:SameLine(200) GUI:InputText("##devmov14",tostring(Player.diving.isswimming))
					GUI:BulletText("CanDiveInZone") GUI:SameLine(200) GUI:InputText("##devmov15",tostring(Player.diving.candiveinzone))
					GUI:BulletText("IsDiving") GUI:SameLine(200) GUI:InputText("##devmov16",tostring(Player.diving.isdiving))
					GUI:BulletText("HeightLevel") GUI:SameLine(200) GUI:InputText("##devmov17",tostring(Player.diving.heightlevel))
					GUI:BulletText("GetHoverHeight") GUI:SameLine(200) GUI:InputText("##devmov18",tostring(GetHoverHeight()))		
					
					if (GUI:Button("Dive##"..tostring(id),50,15) ) then Player:Dive() end
					if (GUI:Button("TakeOff##"..tostring(id),50,15) ) then Player:TakeOff() end
					
					GUI:PopItemWidth()
				else
					GUI:Text("Not Ingame...")
				end
				GUI:TreePop()
			end
-- END MOVEMENT

			-- cbk: Party
			if ( GUI:TreeNode("PartyMembers")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(200)
					local plist = EntityList.myparty
					if (table.valid(plist)) then
						for id, e in pairs(plist) do
							if ( GUI:TreeNode(tostring(id).." - "..e.name) ) then
								GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##devpa0"..tostring(id),tostring(string.format( "%X",e.ptr)))
								GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devpa1"..tostring(id),tostring(e.id))
								GUI:BulletText(".guid") GUI:SameLine(200) GUI:InputText("##devpa9"..tostring(id),tostring(e.guid))								
								GUI:BulletText(".mapid") GUI:SameLine(200) GUI:InputText("##devpa2"..tostring(id),tostring(e.mapid))
								GUI:BulletText(".isleader") GUI:SameLine(200) GUI:InputText("##devpa3"..tostring(id),tostring(e.isleader))								
								GUI:BulletText(".region") GUI:SameLine(200) GUI:InputText("##devpa4"..tostring(id),tostring(e.region))
								GUI:BulletText(".onmesh") GUI:SameLine(200) GUI:InputText("##devpa5"..tostring(id),tostring(e.onmesh))
								local p = e.pos
								GUI:BulletText(".pos") GUI:SameLine(200)  GUI:InputFloat3( "##devpa6", p.x, p.y, p.z, 2, GUI.InputTextFlags_ReadOnly)
                                local h = e.hp
                                GUI:BulletText(".hp") GUI:SameLine(200)  GUI:InputFloat3( "##devpa7", h.current, h.max, h.percent, 2, GUI.InputTextFlags_ReadOnly)
                                h = e.mp
								GUI:BulletText(".mp") GUI:SameLine(200)  GUI:InputFloat3( "##devpa8", h.current, h.max, h.percent, 2, GUI.InputTextFlags_ReadOnly)
								GUI:BulletText(".shield") GUI:SameLine(200)  GUI:InputText("##devpa9"..tostring(id),tostring(e.shield))
								GUI:BulletText(".job") GUI:SameLine(200)  GUI:InputText("##devpa10"..tostring(id),tostring(e.job))
								GUI:BulletText(".state") GUI:SameLine(200)  GUI:InputText("##devpa11"..tostring(id),tostring(e.state))
								GUI:BulletText(".level") GUI:SameLine(200)  GUI:InputText("##devpa12"..tostring(id),tostring(e.level))
								if (GUI:Button("Kick##"..tostring(id),50,15) ) then Player:KickPartyMember(e.guid) end
								GUI:TreePop()
							end
						end
					else
						GUI:Text("No PartyMembers Available...")
					end	
			-- crossworld party
			if ( GUI:TreeNode("CrossWorldParty")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(200)
					local plist = EntityList.crossworldparty
					if (table.valid(plist)) then
						for id, e in pairs(plist) do
							if ( GUI:TreeNode(tostring(id).." - "..e.name) ) then
								GUI:BulletText(".partyindex") GUI:SameLine(200) GUI:InputText("##devcpa1"..tostring(id),tostring(e.partyindex))
								GUI:BulletText(".isonline") GUI:SameLine(200) GUI:InputText("##devcpa1"..tostring(id),tostring(e.isonline))
								GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devcpa1"..tostring(id),tostring(e.id))
								GUI:BulletText(".guid") GUI:SameLine(200) GUI:InputText("##devcpa9"..tostring(id),tostring(e.guid))	
								GUI:BulletText(".level") GUI:SameLine(200)  GUI:InputText("##devcpa12"..tostring(id),tostring(e.level))								
								GUI:BulletText(".job") GUI:SameLine(200)  GUI:InputText("##devcpa10"..tostring(id),tostring(e.job))
								GUI:BulletText(".iscrossworld") GUI:SameLine(200)  GUI:InputText("##devcpa12"..tostring(id),tostring(e.iscrossworld))
								GUI:BulletText(".isleader") GUI:SameLine(200) GUI:InputText("##devcpa3"..tostring(id),tostring(e.isleader))	
								if (GUI:Button("Kick##"..tostring(id),50,15) ) then Player:KickPartyMember(e.guid) end
								GUI:TreePop()
							end
						end
					else
						GUI:Text("No CrossWorldParty Available...")
					end				
					GUI:PopItemWidth()
				end
				GUI:TreePop()
			end					
					GUI:PopItemWidth()
				end
				GUI:TreePop()
			end
--  END PARTY			
			
			-- cbk: Quest
			if ( GUI:TreeNode("Quest List")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(200)
					local qList = Quest:GetQuestList()
					if (table.valid(qList)) then
						for id, e in pairsByKeys(qList) do
							if ( GUI:TreeNode(tostring(id).." - "..e.name) ) then							
								GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devql0"..tostring(id),tostring(e.id))
								GUI:BulletText(".step") GUI:SameLine(200) GUI:InputText("##devql1"..tostring(id),tostring(e.step))
								GUI:BulletText(".completed") GUI:SameLine(200) GUI:InputText("##devql2"..tostring(id),tostring(e.completed))
								GUI:BulletText(".I8A") GUI:SameLine(200) GUI:InputText("##devql3"..tostring(id),tostring(e.I8A))
								GUI:BulletText(".I8B") GUI:SameLine(200) GUI:InputText("##devql4"..tostring(id),tostring(e.I8B))
								GUI:BulletText(".I8C") GUI:SameLine(200) GUI:InputText("##devql5"..tostring(id),tostring(e.I8C))
								GUI:BulletText(".I8D") GUI:SameLine(200) GUI:InputText("##devql6"..tostring(id),tostring(e.I8D))
								GUI:BulletText(".I8E") GUI:SameLine(200) GUI:InputText("##devql7"..tostring(id),tostring(e.I8E))
								GUI:BulletText(".I8F") GUI:SameLine(200) GUI:InputText("##devql8"..tostring(id),tostring(e.I8F))
								GUI:BulletText(".I8AH") GUI:SameLine(200) GUI:InputText("##devql9"..tostring(id),tostring(e.I8AH))
								GUI:BulletText(".I8BH") GUI:SameLine(200) GUI:InputText("##flag8"..tostring(id),tostring(e.I8BH))
                                GUI:BulletText(".I8CH") GUI:SameLine(200) GUI:InputText("##flag9"..tostring(id),tostring(e.I8CH))
                                GUI:BulletText(".I8DH") GUI:SameLine(200) GUI:InputText("##flag10"..tostring(id),tostring(e.I8DH))
                                GUI:BulletText(".I8EH") GUI:SameLine(200) GUI:InputText("##flag11"..tostring(id),tostring(e.I8EH))
                                GUI:BulletText(".I8FH") GUI:SameLine(200) GUI:InputText("##flag12"..tostring(id),tostring(e.I8FH))
                                GUI:BulletText(".I8AL") GUI:SameLine(200) GUI:InputText("##flag13"..tostring(id),tostring(e.I8AL))
                                GUI:BulletText(".I8BL") GUI:SameLine(200) GUI:InputText("##flag14"..tostring(id),tostring(e.I8BL))
                                GUI:BulletText(".I8CL") GUI:SameLine(200) GUI:InputText("##flag15"..tostring(id),tostring(e.I8CL))
                                GUI:BulletText(".I8DL") GUI:SameLine(200) GUI:InputText("##flag16"..tostring(id),tostring(e.I8DL))
                                GUI:BulletText(".I8EL") GUI:SameLine(200) GUI:InputText("##flag17"..tostring(id),tostring(e.I8EL))
                                GUI:BulletText(".I8FL") GUI:SameLine(200) GUI:InputText("##flag18"..tostring(id),tostring(e.I8FL))
                                GUI:TreePop()
							end
						end
						GUI:Separator()
						if (dev.questid == nil) then dev.questid = 122 end
						GUI:BulletText("Enter Quest ID") GUI:SameLine(200) dev.questid = GUI:InputText("##devq20",dev.questid)
						GUI:BulletText("HasQuest") GUI:SameLine(200) GUI:InputText("##devq20"..tostring(id),tostring(Quest:HasQuest(tonumber(dev.questid),false)),GUI.InputTextFlags_CharsDecimal)
						GUI:BulletText("GetQuestCurrentStep") GUI:SameLine(200) GUI:InputText("##devq20"..tostring(id),tostring(Quest:GetQuestCurrentStep(tonumber(dev.questid),false)),GUI.InputTextFlags_CharsDecimal)
						GUI:BulletText("IsQuestCompleted") GUI:SameLine(200) GUI:InputText("##devq20"..tostring(id),tostring(Quest:IsQuestCompleted(tonumber(dev.questid),false)),GUI.InputTextFlags_CharsDecimal)
						GUI:BulletText("Allowance") GUI:SameLine(200) GUI:InputText("##devq20"..tostring(id),tostring(Quest:GetQuestAllowance()),GUI.InputTextFlags_ReadOnly)
						
					else
						GUI:Text("Duty Finder Not Open...")
					end	
					GUI:PopItemWidth()
				else
					GUI:Text("Not Ingame...")
				end				
				GUI:TreePop()
			end
-- END QUEST LIST
			if ( GUI:TreeNode("Leve List")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(200)
					local qList = Quest:GetLeveList()
					if (table.valid(qList)) then
						for id, e in pairsByKeys(qList) do
							if ( GUI:TreeNode(tostring(id).." - "..e.name) ) then							
								GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devql0"..tostring(id),tostring(e.id))
								GUI:BulletText(".step") GUI:SameLine(200) GUI:InputText("##devql1"..tostring(id),tostring(e.step))
								GUI:BulletText(".completed") GUI:SameLine(200) GUI:InputText("##devll2"..tostring(id),tostring(e.completed))
								GUI:BulletText(".I8A") GUI:SameLine(200) GUI:InputText("##devll3"..tostring(id),tostring(e.I8A))
								GUI:BulletText(".I8B") GUI:SameLine(200) GUI:InputText("##devll4"..tostring(id),tostring(e.I8B))
								GUI:BulletText(".I8C") GUI:SameLine(200) GUI:InputText("##devll5"..tostring(id),tostring(e.I8C))
								GUI:BulletText(".I8D") GUI:SameLine(200) GUI:InputText("##devll6"..tostring(id),tostring(e.I8D))
								GUI:BulletText(".I8E") GUI:SameLine(200) GUI:InputText("##devll7"..tostring(id),tostring(e.I8E))
								GUI:BulletText(".I8F") GUI:SameLine(200) GUI:InputText("##devll8"..tostring(id),tostring(e.I8F))
								GUI:BulletText(".I8AH") GUI:SameLine(200) GUI:InputText("##devll9"..tostring(id),tostring(e.I8AH))
								GUI:BulletText(".I8BH") GUI:SameLine(200) GUI:InputText("##flagl8"..tostring(id),tostring(e.I8BH))
                                GUI:BulletText(".I8CH") GUI:SameLine(200) GUI:InputText("##flagl9"..tostring(id),tostring(e.I8CH))
                                GUI:BulletText(".I8DH") GUI:SameLine(200) GUI:InputText("##flagl10"..tostring(id),tostring(e.I8DH))
                                GUI:BulletText(".I8EH") GUI:SameLine(200) GUI:InputText("##flagl11"..tostring(id),tostring(e.I8EH))
                                GUI:BulletText(".I8FH") GUI:SameLine(200) GUI:InputText("##flagl12"..tostring(id),tostring(e.I8FH))
                                GUI:BulletText(".I8AL") GUI:SameLine(200) GUI:InputText("##flagl13"..tostring(id),tostring(e.I8AL))
                                GUI:BulletText(".I8BL") GUI:SameLine(200) GUI:InputText("##flagl14"..tostring(id),tostring(e.I8BL))
                                GUI:BulletText(".I8CL") GUI:SameLine(200) GUI:InputText("##flagl15"..tostring(id),tostring(e.I8CL))
                                GUI:BulletText(".I8DL") GUI:SameLine(200) GUI:InputText("##flagl16"..tostring(id),tostring(e.I8DL))
                                GUI:BulletText(".I8EL") GUI:SameLine(200) GUI:InputText("##flagl17"..tostring(id),tostring(e.I8EL))
                                GUI:BulletText(".I8FL") GUI:SameLine(200) GUI:InputText("##flagl18"..tostring(id),tostring(e.I8FL))
                                GUI:TreePop()
							end
						end
						GUI:Separator()
						if (dev.questid == nil) then dev.questid = 123 end
						GUI:BulletText("Enter Quest ID") GUI:SameLine(200) dev.questid = GUI:InputText("##devl20",dev.questid)
						GUI:BulletText("HasQuest") GUI:SameLine(200) GUI:InputText("##devl20"..tostring(id),tostring(Quest:HasQuest(tonumber(dev.questid),true)),GUI.InputTextFlags_CharsDecimal)
						GUI:BulletText("GetQuestCurrentStep") GUI:SameLine(200) GUI:InputText("##devl20"..tostring(id),tostring(Quest:GetQuestCurrentStep(tonumber(dev.questid),true)),GUI.InputTextFlags_CharsDecimal)
						GUI:BulletText("IsQuestCompleted") GUI:SameLine(200) GUI:InputText("##devl20"..tostring(id),tostring(Quest:IsQuestCompleted(tonumber(dev.questid),true)),GUI.InputTextFlags_CharsDecimal)
						GUI:BulletText("Allowance") GUI:SameLine(200) GUI:InputText("##devl20"..tostring(id),tostring(Quest:GetQuestAllowance()),GUI.InputTextFlags_ReadOnly)
						
					else
						GUI:Text("Duty Finder Not Open...")
					end	
					GUI:PopItemWidth()
				else
					GUI:Text("Not Ingame...")
				end				
				GUI:TreePop()
			end
-- END QUEST LIST			
			-- cbk: Render Manager
			if ( GUI:TreeNode("Renderobject List")) then
			
				-- RenderManager:AddObject( tablewith vertices here ) , returns the renderobject which is a lua metatable. it has an .id which should be used everytime afterwards if the object is being accessed:
				-- RenderManager:GetObject(id)  - use this always before you actually access a renderobject of yours, because the object could have been deleted at any time in c++ due to other code erasing it
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(100)
					if ( not dev.renderobjname ) then dev.renderobjname = "Test" end
					
					if (GUI:Button("Add New Object##newobject"..tostring(id),150,15) ) then
						local ppos = Player.pos
						RenderManager:AddObject(dev.renderobjname, { [1] = { x=ppos.x, y=ppos.y, z=ppos.z, r =0.5,g =0.5,b =0.5,a =0.8, }} )--creating a new object with just 1 vertex, lazy utilizing that one table we already have
					end
					 GUI:SameLine()
					dev.renderobjname = GUI:InputText("Object Name##robja1",dev.renderobjname)	
					
					if (GUI:Button("Delete All Objects##robject"..tostring(id),150,15) ) then RenderManager:RemoveAllObjects() end
					
					
					local rlist = RenderManager:GetObjectList()
					if (table.valid(rlist)) then
						for id, e in pairs(rlist) do
							local changed = false
							local needupdate = false
							if ( GUI:TreeNode("ID: "..tostring(e.id).." - "..e.name) ) then
								e.enabled, changed = GUI:Checkbox("Enabled##robj2"..tostring(id),e.enabled)
								if ( changed ) then if(e.enabled) then e:Enable() else e:Disable() end end
								GUI:SameLine()
								e.drawmode, changed = GUI:Combo("DrawMode", e.drawmode, dev.renderobjdrawmode)								
								if ( changed ) then e:SetDrawMode(e.drawmode) end
								GUI:SameLine()
								if (GUI:Button("Delete Object##object"..tostring(id),150,15) ) then RenderManager:RemoveObject(e.id) end
								
								local vertices = e:GetVertices()								
								local removeid
								if ( GUI:TreeNode("Vertices".."##vtxlist") ) then
									if (table.valid(vertices)) then
										GUI:PushItemWidth(200)
										for vi, vertex in pairs(vertices) do
											if ( GUI:TreeNode(tostring(vi).."##vtx") ) then
												GUI:BulletText("Position") GUI:SameLine(200)  vertex.x, vertex.y, vertex.z, changed = GUI:InputFloat3( "##robj4"..tostring(vi), vertex.x, vertex.y, vertex.z, 2, GUI.InputTextFlags_CharsDecimal)
												if ( changed ) then needupdate = true end
												GUI:BulletText("Color (RGBA)") GUI:SameLine(200)  vertex.r, vertex.g, vertex.b, vertex.a, changed = GUI:InputFloat4( "##robj5"..tostring(vi), vertex.r, vertex.g, vertex.b, vertex.a, 2, GUI.InputTextFlags_CharsDecimal)											
												if ( changed ) then needupdate = true end
												if (GUI:Button("Delete Vertex##object"..tostring(id),150,15) ) then removeid = vi end
												GUI:TreePop()
											end
										end										
										GUI:PopItemWidth()
																												
									else
										GUI:Text("This Object has no Vertices.")										
									end
									-- Add a new vertext to our current object
									if (GUI:Button("Add New Vertex##vertex"..tostring(id),150,15) ) then
										local ppos = Player.pos
										table.insert(vertices,{ x=ppos.x, y=ppos.y, z=ppos.z, r =0.5,g =0.5,b =0.5,a =0.8, })
										needupdate = true
									end		
									GUI:TreePop()
								end
								-- Remove vertex
								if (removeid ~= nil ) then table.remove(vertices,removeid) needupdate = true end
								if (needupdate) then
									e:SetVertices(vertices)
								end								
								
								GUI:Separator()
								GUI:TreePop()
							end
						end					
					else
						GUI:Text("No RenderObjects Available...")
					end				
					GUI:PopItemWidth()
				end
				GUI:TreePop()
			end
-- END RENDEROBJECTS			
			
			-- cbk: Shop List
			if ( GUI:TreeNode("Shop List")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
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
								if (GUI:Button("BuyShopItem##"..tostring(id),150,15) ) then Inventory:BuyShopItem(e.id) end
								
								GUI:TreePop()
							end
						end					
					else
						GUI:Text("No NPC Shop List Available...")
					end				
					GUI:PopItemWidth()
				end
				GUI:TreePop()
			end
--  END SHOPLIST

			-- cbk: itemexchange List
			if ( GUI:TreeNode("Item Exchange List")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(200)
					local slist = Inventory:GetItemExchangeList()
					if (table.valid(slist)) then
						for id, e in pairs(slist) do
							if ( GUI:TreeNode(tostring(id).." - "..e.name) ) then
								GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##devIElist"..tostring(id),tostring(string.format( "%X",e.ptr)))
								GUI:BulletText(".slot") GUI:SameLine(200) GUI:InputText("##devIElist2"..tostring(id),tostring(e.slot))
								GUI:BulletText(".id") GUI:SameLine(200) GUI:InputText("##devIElist3"..tostring(id),tostring(e.id))
								GUI:BulletText(".id2") GUI:SameLine(200) GUI:InputText("##devIElist4"..tostring(id),tostring(e.id2))							
								GUI:BulletText(".price1") GUI:SameLine(200) GUI:InputText("##devIElist5"..tostring(id),tostring(e.price1))
								GUI:BulletText(".price2") GUI:SameLine(200) GUI:InputText("##devIElist6"..tostring(id),tostring(e.price2))
								GUI:BulletText(".price3") GUI:SameLine(200) GUI:InputText("##devIElist7"..tostring(id),tostring(e.price3))
								
								GUI:BulletText(".type1") GUI:SameLine(200) GUI:InputText("##devIElist5"..tostring(id),tostring(e.type1))
								GUI:BulletText(".type2") GUI:SameLine(200) GUI:InputText("##devIElist6"..tostring(id),tostring(e.type2))
								GUI:BulletText(".type3") GUI:SameLine(200) GUI:InputText("##devIElist7"..tostring(id),tostring(e.type3))
								
								if (GUI:Button("BuyShopItem2##"..tostring(id),150,15) ) then Inventory:BuyShopItem(e.id) end
								
								GUI:TreePop()
							end
						end					
					else
						GUI:Text("No NPC Shop List Available...")
					end				
					GUI:PopItemWidth()
				end
				GUI:TreePop()
			end
--  END SHOPLIST

			if ( GUI:TreeNode("Game Settings")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(200)
					local slist = GetGameSettings()
					if (table.valid(slist)) then
						for id, e in pairs(slist) do
							if ( GUI:TreeNode(tostring(id).." - "..e.name) ) then
								GUI:BulletText(".ptr") GUI:SameLine(200) GUI:InputText("##devGSlist"..tostring(id),tostring(string.format( "%X",e.ptr)))
								GUI:BulletText(".name") GUI:SameLine(200) GUI:InputText("##devGSlist2"..tostring(id),tostring(e.name))
								GUI:BulletText(".type") GUI:SameLine(200) GUI:InputText("##devGSlist3"..tostring(id),tostring(e.type))
								GUI:BulletText(".value") GUI:SameLine(200) GUI:InputText("##devGSlist4"..tostring(id),tostring(e.value))
								if (value == nil ) then value = tostring(0) end
								if (GUI:Button("SetValue##"..tostring(id),80,15) ) then e:SetValue(tonumber(value)) end GUI:SameLine(200) value = GUI:InputText("##devGSlist5"..tostring(id),tostring(value)) 
								GUI:TreePop()
							end
						end					
					else
						GUI:Text("No Settings List")
					end				
					GUI:PopItemWidth()
				end
				GUI:TreePop()
			end

			-- cbk: ServerList
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

			-- cbk: UI Permissions
			if ( GUI:TreeNode("UI Permissions")) then
				local totalUI = 0
				for i=0,165 do
					if (GetUIPermission(i) == 1) then
						totalUI = totalUI + i
					end
				end
				GUI:Text("UI Elements ["..tostring(totalUI).."]")
				for i=0,165 do
					GUI:Text("UI Element "..i.." = "..tostring(GetUIPermission(i)))
				end
			end
-- END UI PERMISSIONS

			-- cbk: Weather
			if ( GUI:TreeNode("Player specific Data")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(200)					
					if ( GUI:TreeNode("Eorzea Time")) then
						local ezt = GetEorzeaTime()
						GUI:BulletText(".bell") GUI:SameLine(200) GUI:InputText("##devezt",tostring(ezt.bell))
						GUI:BulletText(".minute") GUI:SameLine(200) GUI:InputText("##devezt2",tostring(ezt.minute))
						GUI:BulletText(".moon") GUI:SameLine(200) GUI:InputText("##devezt3",tostring(ezt.moon))		
						GUI:BulletText(".sun") GUI:SameLine(200) GUI:InputText("##devezt4",tostring(ezt.sun))	
						GUI:BulletText(".year") GUI:SameLine(200) GUI:InputText("##devezt5",tostring(ezt.year))	
						GUI:BulletText(".servertime") GUI:SameLine(200) GUI:InputText("##devezt6",tostring(ezt.servertime))	
						GUI:TreePop()
					end
				if ( GUI:TreeNode("Snipe Cam")) then
						local snp = Player:GetSnipeCam()
						GUI:BulletText("x, y, zoom") GUI:SameLine(200)  GUI:InputFloat3( "##dev9", snp.x, snp.y, snp.zoom , 2, GUI.InputTextFlags_ReadOnly) 
						
						-- Player:SetSnipeCam(x,y,zoom)
						-- Player:SetSnipeCam(x,y)
						-- Player:SetSnipeCam(zoom)
						GUI:SameLine()	if (GUI:Button("SnipeShoot##",100,15) ) then Player:SnipeShoot() end
						GUI:BulletText("Targets Remaining") GUI:SameLine(200) GUI:InputText("##devess",tostring(Player:GetSnipeTargetsRemain()))
						GUI:BulletText("HasTarget") GUI:SameLine(200) GUI:InputText("##devess1",tostring(Player:SnipeHasTarget()))							
						GUI:TreePop()
					end
					GUI:PopItemWidth()
				end
				GUI:TreePop()
			end

			-- cbk: Utility
			if ( GUI:TreeNode("Utility Functions")) then
				if( gamestate == FFXIV.GAMESTATE.INGAME ) then
					GUI:PushItemWidth(200)
					GUI:BulletText("GetGameState") GUI:SameLine(200) GUI:InputText("##devUT0",tostring(GetGameState()))
					GUI:BulletText("GameVersion") GUI:SameLine(200) GUI:InputText("##devUT1",tostring(GetGameVersion()))
					GUI:BulletText("GameLanguage") GUI:SameLine(200) GUI:InputText("##devUT2",tostring(GetGameLanguage()))
					GUI:BulletText("GetGameRegion") GUI:SameLine(200) GUI:InputText("##devUT3",tostring(GetGameRegion()))
					GUI:BulletText("GetCurrentWeather") GUI:SameLine(200) GUI:InputText("##devUT4",tostring(GetCurrentWeather()))

					if (dev.sendcmd == nil ) then dev.sendcmd = "" end
					dev.sendcmd = GUI:InputText("##devuf1", dev.sendcmd) GUI:SameLine()	if (GUI:Button("SendCommand",100,15) ) then SendTextCommand(dev.sendcmd) end
										
					if (GUI:Button("Respawn##"..tostring(id),100,15) ) then d("Respawn Result : "..tostring(Player:Respawn())) end					
						
					local t = Player:GetTarget()
					if ( t ) then
						if (GUI:Button("Face Target##"..tostring(id),100,15) ) then d("Result : "..tostring(Player:SetFacing(t.pos.x,t.pos.y,t.pos.z,true))) end	-- without the "true" argument, the facing is 100% instant, else it is smooth
						GUI:SameLine()
						if (GUI:Button("Clear Target##"..tostring(id),100,15) ) then d("Result : "..tostring(Player:ClearTarget())) end
						if (GUI:Button("Follow Target##"..tostring(id),100,15) ) then d("Result : "..tostring(Player:FollowTarget(t.id))) end
						if (GUI:Button("Raycast##"..tostring(id),100,15) ) then d("Result : "..tostring(RayCast(Player.pos.x,Player.pos.y,Player.pos.z,t.pos.x,t.pos.y,t.pos.z))) end
					else
						GUI:Text("Select a Target...")
					end
				
					gDevRecordNPCs = GUI:Checkbox("Record NPCs",gDevRecordNPCs)
					if (gDevRecordNPCs) then
						local mapid = Player.localmapid
						if (mapid ~= 0) then
							local el = EntityList("")
							if (table.valid(el)) then
								for i,e in pairs(el) do
									local entity = EntityList:Get(e.id)
									if (entity) then
										local contentid = entity.contentid
										if (contentid >= 1000000 and contentid <= 1024000 and gDevRecordedNPCs[contentid] == nil) then
											local pos = entity.pos
											gDevRecordedNPCs[contentid] = { contentid = contentid, mapid = mapid, x = pos.x, y = pos.y, z = pos.z }
										end
									end
								end
							end
						end
					end		

					if (GUI:Button("Output Entries")) then
						local filePath = GetStartupPath() .. [[\LuaMods\Dev\npcrecordings.csv]]
						for contentid,entry in pairsByKeys(gDevRecordedNPCs) do
							local towrite = entry.contentid .. "," .. entry.mapid .. "," .. entry.x .. "," .. entry.y .. "," .. entry.z .. "\n"
							FileWrite(filePath,towrite,true)
						end
					end
					GUI:PopItemWidth()
				end
				GUI:TreePop()
			end
-- 	END UTILITY FUNCTIONS

			if ( GUI:TreeNode("Installed Addons") ) then
				dev.showInitAddons = GUI:Checkbox("Include Initialize Events", dev.showInitAddons or false)
				if(not dev.lastaddontick or ticks - dev.lastaddontick > 200) then
					dev.lastaddontick = ticks
					dev.addonlist = GetAddonList()
					table.sort(dev.addonlist, function(a,b) return a.average > b.average end)					
				end
				GUI:PushItemWidth(250)
				GUI:Columns( 6, "#beer", true )
				GUI:SetColumnWidth(0, 250)
				GUI:SetColumnWidth(1, 125)
				GUI:SetColumnWidth(2, 100)
				GUI:SetColumnWidth(3, 100)
				GUI:SetColumnWidth(4, 100)
				GUI:SetColumnWidth(5, 100)
				GUI:Text("Addon")
				GUI:NextColumn()
				GUI:Text("Event")
				GUI:NextColumn()
				GUI:Text("lasttick")						
				GUI:NextColumn()						
				GUI:Text("highest (ms)")
				GUI:NextColumn()
				GUI:Text("lowest (ms)")
				GUI:NextColumn()
				GUI:Text("average (ms)")
				GUI:NextColumn()
				GUI:Separator()					
				for i, e in pairs(dev.addonlist) do
					if(e.highest ~= 0) then
						if(dev.showInitAddons or ( e.lasttick < 10000 and e.event ~= "Module.Initialize"))then
							GUI:Text(e.name)
							GUI:NextColumn()
							GUI:Text(e.event)
							GUI:NextColumn()
							GUI:Text(e.lasttick)
							GUI:NextColumn()
							GUI:Text(e.highest)
							GUI:NextColumn()
							GUI:Text(e.slowest)
							GUI:NextColumn()
							GUI:Text(e.average)
							GUI:NextColumn()
						end
					end
				end
				GUI:Columns(1)
				GUI:PopItemWidth()
				GUI:TreePop()
			end
-- 	END INSTALLED ADDONS


			GUI:PopStyleVar(2)
		end
		GUI:End()
	end
end
RegisterEventHandler("Gameloop.Draw", dev.DrawCall, "dev.DrawCall")

function dev.DrawGameObjectDetails(c,isplayer,ispet) 
	GUI:PushItemWidth(200)
	if ( GUI:TreeNode("Core Data") ) then
		GUI:BulletText("Ptr") GUI:SameLine(200) GUI:InputText("##dev0",tostring(string.format( "%X",c.ptr)))
		GUI:BulletText("ID") GUI:SameLine(200) GUI:InputText("##dev1",tostring(c.id))
		GUI:BulletText("Name") GUI:SameLine(200) GUI:InputText("##dev2",c.name)	
		GUI:BulletText("ContentID") GUI:SameLine(200) GUI:InputText("##dev4",tostring(c.contentid))
		GUI:BulletText("Type") GUI:SameLine(200) GUI:InputText("##dev5",tostring(c.type))
		GUI:BulletText("Status") GUI:SameLine(200) GUI:InputText("##dev5a",tostring(c.status))
		if (ispet) then
			GUI:BulletText("PetType") GUI:SameLine(200) GUI:InputText("##objpettype",tostring(c.pettype))
			GUI:BulletText("PetState") GUI:SameLine(200) GUI:InputInt2( "##objpetstate", c.petstate[1], c.petstate[2], GUI.InputTextFlags_ReadOnly)
		end
		GUI:BulletText("ChocoboState") GUI:SameLine(200) GUI:InputText("##objchocobostate",tostring(c.chocobostate))
		GUI:BulletText("CharType") GUI:SameLine(200) GUI:InputText("##dev6",tostring(c.chartype))
		GUI:BulletText("TargetID") GUI:SameLine(200) GUI:InputText("##dev7",tostring(c.targetid))
		GUI:BulletText("OwnerID") GUI:SameLine(200) GUI:InputText("##dev8",tostring(c.ownerid))
		GUI:BulletText("Claimed By ID") GUI:SameLine(200) GUI:InputText("##dev43",tostring(c.claimedbyid))
		GUI:BulletText("Fate ID") GUI:SameLine(200) GUI:InputText("##dev35", tostring(c.fateid))
		GUI:BulletText("Icon ID") GUI:SameLine(200) GUI:InputText("##dev354", tostring(c.iconid))
		GUI:TreePop()
	end
	if ( GUI:TreeNode("Bars Data") ) then
		GUI:PushItemWidth(250)
		local h = c.hp
		GUI:BulletText("Health") GUI:SameLine(200)  GUI:InputFloat3( "##dev9", h.current, h.max, h.percent, 2, GUI.InputTextFlags_ReadOnly)
		GUI:PushItemWidth(100)
			GUI:SameLine() GUI:InputFloat("##dev9.1", h.extra, 2, GUI.InputTextFlags_ReadOnly)
		GUI:PopItemWidth()
		h = c.mp
		GUI:BulletText("MP") GUI:SameLine(200)  GUI:InputFloat3( "##dev10", h.current, h.max, h.percent, 2, GUI.InputTextFlags_ReadOnly)
		h = c.cp
		GUI:BulletText("CP") GUI:SameLine(200)  GUI:InputFloat3( "##dev11", h.current, h.max, h.percent, 2, GUI.InputTextFlags_ReadOnly)
		h = c.gp
		GUI:BulletText("GP") GUI:SameLine(200)  GUI:InputFloat3( "##dev12", h.current, h.max, h.percent, 2, GUI.InputTextFlags_ReadOnly)
		GUI:BulletText("TP") GUI:SameLine(200) GUI:InputText("##dev13",tostring(c.tp))
		GUI:PopItemWidth()		
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
		GUI:BulletText("IsReachable") GUI:SameLine(200) GUI:InputText("##dev48", tostring(c.isreachable))
		local meshpos = c.meshpos
		if ( meshpos ) then 
			GUI:BulletText("MeshPosition") GUI:SameLine(200)  GUI:InputFloat3( "##dev9m", meshpos.x, meshpos.y, meshpos.z, 2, GUI.InputTextFlags_ReadOnly)
			GUI:BulletText("Dist MeshPos-Player") GUI:SameLine(200)  GUI:InputFloat("##dev12m", meshpos.distance,0,0,2)
			GUI:BulletText("Dist to MeshPos") GUI:SameLine(200)  GUI:InputFloat("##dev13m", meshpos.meshdistance,0,0,2)	
		else
			GUI:BulletText("MeshPosition") GUI:SameLine(200)  GUI:InputFloat3( "##dev9m", 0, 0, m0, 2, GUI.InputTextFlags_ReadOnly)
			GUI:BulletText("Dist MeshPos-Player") GUI:SameLine(200)  GUI:InputFloat("##dev12m", 0,0,0,2)
			GUI:BulletText("Dist to MeshPos") GUI:SameLine(200)  GUI:InputFloat("##dev13m", 0,0,0,2)			
		end
		local cubepos = c.cubepos
		if( table.valid(cubepos)) then
			GUI:BulletText("CubePosition") GUI:SameLine(200)  GUI:InputFloat3( "##deva14m", cubepos.x, cubepos.y, cubepos.z, 2, GUI.InputTextFlags_ReadOnly)
			GUI:BulletText("Dist CubePos-Player") GUI:SameLine(200)  GUI:InputFloat("##deva15m", cubepos.distance,0,0,2)
			GUI:BulletText("Dist to CubePos") GUI:SameLine(200)  GUI:InputFloat("##deva16m", cubepos.meshdistance,0,0,2)
		end		
		GUI:TreePop()
	end	
	if ( GUI:TreeNode("Misc Data") ) then
		GUI:BulletText("IsMounted") GUI:SameLine(200) GUI:InputText("##dev38", tostring(c.ismounted))
		GUI:BulletText("Job") GUI:SameLine(200) GUI:InputText("##dev21",tostring(c.job))
		GUI:BulletText("Level") GUI:SameLine(200) GUI:InputText("##dev22",tostring(c.level))
		GUI:BulletText("PvPTeam") GUI:SameLine(200) GUI:InputText("##dev672",tostring(c.pvpteam))
		GUI:BulletText("GrandCompany") GUI:SameLine(200) GUI:InputText("##dev41",tostring(c.grandcompany))
		GUI:BulletText("GrandCompanyRank") GUI:SameLine(200) GUI:InputText("##dev42",tostring(c.grandcompanyrank))
		GUI:BulletText("Aggro") GUI:SameLine(200) GUI:InputText("##dev24",tostring(c.aggro))
		GUI:BulletText("AggroPercentage") GUI:SameLine(200) GUI:InputText("##dev25",tostring(c.aggropercentage))	
		if(isplayer)then
			GUI:BulletText("Has Aggro") GUI:SameLine(200) GUI:InputText("##devp45", tostring(c.hasaggro))
			GUI:BulletText("ReviveState") GUI:SameLine(200) GUI:InputText("##devp46", tostring(c.revivestate))
			GUI:BulletText("Party Role") GUI:SameLine(200) GUI:InputText("##devp46", tostring(c.role))
		end
		GUI:BulletText("Attackable") GUI:SameLine(200) GUI:InputText("##dev26", tostring(c.attackable))
		GUI:BulletText("Aggressive") GUI:SameLine(200) GUI:InputText("##dev27", tostring(c.aggressive))
		GUI:BulletText("Friendly") GUI:SameLine(200) GUI:InputText("##dev28", tostring(c.friendly))
		GUI:BulletText("InCombat") GUI:SameLine(200) GUI:InputText("##dev29", tostring(c.incombat))
		GUI:BulletText("Interactable") GUI:SameLine(200) GUI:InputText("##dev291", tostring(c.interactable))
		GUI:BulletText("Targetable") GUI:SameLine(200) GUI:InputText("##dev30", tostring(c.targetable))
		GUI:BulletText("Alive") GUI:SameLine(200) GUI:InputText("##dev31", tostring(c.alive))
		GUI:BulletText("Gatherable") GUI:SameLine(200) GUI:InputText("##dev32", tostring(c.cangather))
		GUI:BulletText("Spear Fish State") GUI:SameLine(200) GUI:InputText("##dev33", tostring(c.spearfishstate))
		GUI:BulletText("Marker") GUI:SameLine(200) GUI:InputText("##dev36", tostring(c.marker))
		GUI:BulletText("Online Status") GUI:SameLine(200) GUI:InputText("##dev37", tostring(c.onlinestatus))
		GUI:BulletText("Current World") GUI:SameLine(200) GUI:InputText("##dev38", tostring(c.currentworld))
		GUI:BulletText("Home World") GUI:SameLine(200) GUI:InputText("##dev39", tostring(c.homeworld))
			-- SpearFishing
			--SPEARFISHSTATE_NOTFISHNODE = -1,
			--SPEARFISHSTATE_NONE = 0,
			--SPEARFISHSTATE_BEGIN = 1,
			--SPEARFISHSTATE_BUBBLES = 2, 
			--SPEARFISHSTATE_SUCCESS = 4,
			--SPEARFISHSTATE_MISSED = 5,
			--SPEARFISHSTATE_UNKN = 6,
			--SPEARFISHSTATE_GOTAWAY = 7,
			--SPEARFISHSTATE_NOTAVAIL = 9,
		if ( c.cangather ) then
			GUI:BulletText("GatherAttempts") GUI:SameLine(200) GUI:InputText("##dev34", tostring(c.gatherattempts))
			GUI:BulletText("GatherAttemptsMax") GUI:SameLine(200) GUI:InputText("##dev35", tostring(c.gatherattemptsmax))
		end
		GUI:TreePop()
	end
	
	if ( GUI:TreeNode("Cast & Spell Data") ) then
		GUI:BulletText("Current Action") GUI:SameLine(200) GUI:InputText("##dev36", tostring(c.action))
		GUI:BulletText("Last Action") GUI:SameLine(200) GUI:InputText("##dev37", tostring(c.lastaction))
		local cinfo = c.castinginfo
		if ( table.size(cinfo) > 0) then
			GUI:BulletText("(.castinginfo)")
			GUI:BulletText("ptr") GUI:SameLine(250) GUI:InputText("##dev38323", string.format( "%X",cinfo.ptr))
			GUI:BulletText("Casting ID") GUI:SameLine(250) GUI:InputText("##dev38", tostring(cinfo.castingid))
			GUI:BulletText("Casting Time") GUI:SameLine(250) GUI:InputText("##dev39", tostring(cinfo.casttime))
			GUI:BulletText("Casting TargetCount") GUI:SameLine(250) GUI:InputText("##dev40", tostring(cinfo.castingtargetcount))
			GUI:BulletText("Casting Interruptible") GUI:SameLine(250) GUI:InputText("##dev42130", tostring(cinfo.castinginterruptible))
			if ( GUI:TreeNode("Casting Targets") ) then
				local ct = cinfo.castingtargets			
				if ( table.size(ct) > 0) then
					for tid, target in pairs(ct) do
						GUI:BulletText("Target "..tostring(tid)) GUI:SameLine(200) GUI:InputText("##dev45"..tostring(tid), tostring(target))
					end
				end
				GUI:TreePop()
			end	
			GUI:BulletText("Last Cast ID") GUI:SameLine(250) GUI:InputText("##dev41", tostring(cinfo.lastcastid))
			GUI:BulletText("Time Since Last Cast") GUI:SameLine(250) GUI:InputText("##dev47", tostring(cinfo.timesincecast))
			GUI:BulletText("Channeling ID") GUI:SameLine(250) GUI:InputText("##dev42", tostring(cinfo.channelingid))
			GUI:BulletText("Channeling Target ID") GUI:SameLine(250) GUI:InputText("##dev43", tostring(cinfo.channeltargetid))
			GUI:BulletText("Channeling Time") GUI:SameLine(250) GUI:InputText("##dev44", tostring(cinfo.channeltime))
			if(isplayer)then
				GUI:BulletText("ComboTime Remain") GUI:SameLine(250) GUI:InputText("##devp45", tostring(c.combotimeremain))
				GUI:BulletText("Last Combo ID") GUI:SameLine(250) GUI:InputText("##devp46", tostring(c.lastcomboid))
			
			end
		end
		GUI:TreePop()
	end
	
	local ekinfo = c.eurekainfo
	if ( table.size(ekinfo) > 0) then
		if ( GUI:TreeNode(".eurekainfo") ) then
			GUI:BulletText(".level") GUI:SameLine(200) GUI:InputText("##eurekainfo.level", tostring(ekinfo.level))
			local aff = { [0] = "self", [1] = "fire", [2] = "ice", [3] = "wind", [4] = "earth", [5] = "lightning", [6] = "water"}
			GUI:BulletText(".element") GUI:SameLine(200) GUI:InputText("##eurekainfo.element", tostring(ekinfo.element).."("..IsNull(aff[ekinfo.element],"none")..")")
			GUI:TreePop()
		end
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
					GUI:BulletText("Dispellable") GUI:SameLine(200) GUI:InputText("##devb10", tostring(b.dispellable))
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

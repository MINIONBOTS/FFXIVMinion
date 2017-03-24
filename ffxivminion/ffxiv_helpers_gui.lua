ffxiv_dialog_manager = {}
ffxiv_dialog_manager.popup = {}
ffxiv_dialog_manager.controls = {
	["okonly"] = { "OK" },
	["yesno"] = { "Yes", "No" },
	["okcancel"] = { "OK", "Cancel" },
	["none"] = {},
}
ffxiv_dialog_manager.popupresult = 0

function ffxiv_dialog_manager.IssueNotice(title, message, buttonset, guivars)
	local buttonset = IsNull(buttonset,"okonly")
	ffxiv_dialog_manager.popup = { ["type"] = buttonset, lines = message, title = title, gui = guivars, popped = false }
end

function ffxiv_dialog_manager.IssueStopNotice(title, message, buttonset, guivars)
	local buttonset = IsNull(buttonset,"okonly")
	ffxiv_dialog_manager.popup = { ["type"] = buttonset, lines = message, title = title, gui = guivars, popped = false }
	
	if (FFXIV_Common_BotRunning) then
		ml_global_information.ToggleRun()
	end
end

function ffxiv_dialog_manager.TableToGUI(vars)
	
	local popup = ffxiv_dialog_manager.popup
	if (table.valid(popup)) then
		if (table.valid(vars)) then
			
			local selectedIndex, selectedName = 0,""
			if (table.valid(popup.tab_control)) then
				if (TableSize(popup.tab_control.tabs) > 0) then
					selectedIndex,selectedName = ml_gui.DrawTabs(popup.tab_control)
				end
			end
			
			for k,vartable in pairsByKeys(vars) do
				local controltype = vartable.type
				local controldisplay = vartable.display
				local controlvar = vartable.var
				local controlisdefault = vartable.isdefault
				local controldefault = vartable.default
				local controlclick = vartable.onclick
				local controlstep = IsNull(vartable.step,1)
				local controlmin = vartable.minvalue
				local controlmax = vartable.maxvalue
				local controltab = vartable.tab
				local onchange = vartable.onchange
				local tooltip = vartable.tooltip
				local sameline = vartable.sameline
				local controlamount = vartable.amount
				local width = vartable.width
				
				if (not controltab or (controltab and (selectedName == controltab))) then
					local changedVal = false
					
					if (width and type(width) == "number") then
						GUI:PushItemWidth(width)
					end
					
					if (controltype == "combobox") then
						local controllist = vartable.list or ""
						local combotable = string.totable(controllist,",")
						local currentval = _G[controlvar]
						local currentindex = GetKeyByValue(currentval,combotable)
						
						local newindex = GUI:Combo(controldisplay, _G[controlvar.."_index"], combotable)
						if (newindex ~= _G[controlvar.."_index"]) then
							changedVal = true
							_G[controlvar.."_index"] = newindex
							_G[controlvar] = combotable[newindex]
							Settings.FFXIVMINION[controlvar.."_index"] = _G[controlvar.."_index"]
							Settings.FFXIVMINION[controlvar] = _G[controlvar]
						end
					elseif (controltype == "checkbox" or controltype == "boolean") then
						local newval = GUI:Checkbox(controldisplay,_G[controlvar])
						if (newval ~= _G[controlvar]) then
							changedVal = true
							_G[controlvar] = newval
							Settings.FFXIVMINION[controlvar] = _G[controlvar]
						end
					elseif (controltype == "numeric" or controltype == "number") then
						local newval = GUI:InputInt(controldisplay,_G[controlvar],controlstep,(controlstep * 2))
						if (newval ~= _G[controlvar]) then
							local allowSave = true
							if (controlmin and newval < controlmin) then
								allowSave = false
							elseif (controlmax and newval > controlmax) then
								allowSave = false
							end
							if (allowSave) then
								changedVal = true
								_G[controlvar] = newval
								Settings.FFXIVMINION[controlvar] = _G[controlvar]
							end	
						end
					elseif (controltype == "field" or controltype == "string") then
						local newval = GUI:InputText(controldisplay,_G[controlvar])
						if (newval ~= _G[controlvar]) then
							changedVal = true
							_G[controlvar] = newval
							Settings.FFXIVMINION[controlvar] = _G[controlvar]
						end
					elseif (controltype == "button") then
						local doExecute = false
						if (controlisdefault and GUI:IsKeyPressed(13)) then
							doExecute = true
						end
						if (width and type(width) == "number") then
							if (GUI:Button(controldisplay,width,20)) then
								doExecute = true
							end
						else
							if (GUI:Button(controldisplay)) then
								doExecute = true
							end
						end
						if (doExecute) then
							if (controlclick and type(controlclick) == "function") then
								controlclick()
							elseif (controlclick and type(controlclick) == "string") then
								local f = assert(loadstring(controlclick))()
							end
						end
					end	

					if (changedVal and onchange and type(onchange) == "string") then
						local f = assert(loadstring(onchange))()
					end
					
					if (width and type(width) == "number") then
						GUI:PopItemWidth()
					end

					if (string.valid(tooltip)) then
						if (GUI:IsItemHovered()) then
							GUI:SetTooltip(tooltip)
						end
					end
					
					if (sameline and sameline == true) then
						if (controlamount and type(controlamount) == "number") then
							GUI:SameLine(0,controlamount)
						else
							GUI:SameLine(0,10)
						end
					end
					
					if (controltype == "spacing") then
						if (controlamount and type(controlamount) == "number") then
							for i = 1,controlamount do
								GUI:Spacing()
							end
						else
							GUI:Spacing()
						end
					end
					
					if (controltype == "separator") then
						GUI:Separator()
					end					
				end
			end
		end
	end
end

function ffxiv_dialog_manager.Draw( event, ticks ) 
	local popup = ffxiv_dialog_manager.popup
	if (table.valid(popup)) then
		if (not popup.popped) then
			popup.popped = true
			GUI:OpenPopup(popup.title)
		end
		
		local width, height = 500, 100
		if (popup.gui) then
			if (popup.gui.height) then
				height = popup.gui.height
			end
			if (popup.gui.width) then
				width = popup.gui.width
			end
		end
		
		GUI:SetNextWindowSize(width,height,GUI.SetCond_Once)
		
		if (GUI:BeginPopupModal(popup.title, true)) then
			GUI:Spacing(); GUI:Spacing(); 
			
			local lines = popup.lines
			if (type(lines) == "table") then
				for i,line in pairsByKeys(lines) do
					GUI:Text(line)
				end
			elseif (type(lines) == "string") then
				GUI:Text(lines)
			end
			
			GUI:Spacing(); GUI:Spacing(); 
			
			ffxiv_dialog_manager.TableToGUI(popup.gui)
			
			local controls = ffxiv_dialog_manager.controls
			if (table.valid(controls[popup.type])) then
				local controlset = controls[popup.type]
				if (controlset[1] ~= nil) then
					if (GUI:IsKeyPressed(13) or GUI:Button(controlset[1],100,20)) then
						GUI:CloseCurrentPopup()
						ffxiv_dialog_manager.popupresult = 1
						ffxiv_dialog_manager.popup = {}
					end
				end
				
				if (controlset[2] ~= nil) then
					GUI:SameLine(0,20)
					if (GUI:Button(controlset[2],100,20)) then
						GUI:CloseCurrentPopup()
						ffxiv_dialog_manager.popupresult = 0
						ffxiv_dialog_manager.popup = {}
					end
				end
			end
			
			GUI:EndPopup()
		end
	end
end

function GUI_Get(varName)
	return _G[varName]
end

function GUI_Set(varName,newVal)
	_G[varName] = newVal
	Settings.FFXIVMINION[varName] = newVal
end
SetGUIVar = GUI_Set -- For backwards compatibility

function GUI_Detect(newVal,varName,onChange)
	local currentVal = _G[varName]
	if (currentVal ~= newVal or (type(newVal) == "table" and not deepcompare(currentVal,newVal))) then
		_G[varName] = newVal
	end
		
	return newVal
end

function GUI_Capture(newVal,varName,onChange,forceSave)
	local forceSave = IsNull(forceSave,false)
	local needsSave = false
	
	local currentVal = _G[varName]
	if (forceSave or currentVal ~= newVal or (type(newVal) == "table" and not deepcompare(currentVal,newVal))) then
		_G[varName] = newVal
		needsSave = true
		if (onChange and type(onChange) == "function") then
			onChange()
		end
	end
		
	if (needsSave) then
		Settings.FFXIVMINION[varName] = newVal
	end

	return newVal
end

function GUI_Combo(label, varindex, varval, itemlist, height)
	local changed = false
	
	local newIndex = GUI:Combo(label, _G[varindex], itemlist, height)
	if (newIndex ~= _G[varindex]) then
		changed = true
		_G[varindex] = newIndex
		Settings.FFXIVMINION[varindex] = _G[varindex]
		_G[varval] = itemlist[_G[varindex]]
		Settings.FFXIVMINION[varval] = _G[varval]
	end
	
	return changed, _G[varindex], _G[varval]
end

function GUI_GetFrameHeight(rows)
	local fontSize = GUI:GetWindowFontSize()
	local windowPaddingY = ml_gui.style.current.windowpadding.y
	local framePaddingY = ml_gui.style.current.framepadding.y
	local itemSpacingY = ml_gui.style.current.itemspacing.y
	
	return ((fontSize * rows) + (itemSpacingY * (rows - 1)) + (framePaddingY * 2 * rows) + (windowPaddingY * 2))
end

function GUI_DrawIntMinMax(label,varname,step,stepfast,minval,maxval,onchange)
	local var = _G[varname]
	local returned = GUI_Capture(GUI:InputInt(label,var,step,stepfast),varname, onchange)
	if (minval ~= nil and returned < minval) then GUI_Set(varname,minval) elseif (maxval ~= nil and returned > maxval) then GUI_Set(varname,minval) end
end

function GUI_DrawFloatMinMax(label,varname,step,stepfast,precision,minval,maxval,onchange)
	local var = _G[varname]
	local precision = IsNull(precision,2)
	local returned = GUI_Capture(GUI:InputFloat(label,var,step,stepfast,precision),varname,onchange)
	if (minval ~= nil and returned < minval) then GUI_Set(varname,minval) elseif (maxval ~= nil and returned > maxval) then GUI_Set(varname,minval) end
end

function GUI_CreateTabs(strTabs,doTranslate)
	local doTranslate = IsNull(doTranslate,false)
	
	local tab_control = {
		options = {
		
		},
		events = {
			onChange = function() end,
			onClick = function() end,
		},
		tabs = {
		
		},
	}
					
	if (string.valid(strTabs)) then

		for tab in StringSplit(strTabs,",") do
			local tabname = tab
			if (doTranslate) then
				tabname = GetString(tabname)
				if (not string.valid(tabname)) then
					tabname = tab
				end
			end
			
			if (string.valid(tabname)) then
				local newTab = {
					onClick = function() end,
					isselected = false,
					ishovered = false,
					selected = { name = tabname, r = .96, g = .15, b = .20, a = 1 },
					hovered = { name = tabname, r = .89, g = .70, b = .70, a = 1 },
					normal = { name = tabname, r = 1, g = 1, b = 1, a = 1 },
				}
				if (TableSize(tab_control.tabs) == 0) then
					newTab.isselected = true
				end
				table.insert(tab_control.tabs,newTab)
			end
		end
	end
	return tab_control
end

function GUI_SwitchTab(tTabs,iTab)
	local tabs = tTabs.tabs
	tabs[iTab].isselected = true
	for k,tab2 in pairs(tabs) do
		if (iTab ~= k and tab2.isselected) then
			tabs[k].isselected = false
		end
	end
end

function GUI_DrawTabs(tTabs)

	local returnIndex,returnName;
	local fontSize = GUI:GetWindowFontSize()
	local windowPaddingY = ml_gui.style.current.windowpadding.y
	local framePaddingY = ml_gui.style.current.framepadding.y

	GUI:BeginChild("##main-tabs",0,fontSize+(framePaddingY * 2),false)
	
	local counter = 1;
	
	local events = tTabs.events
	local tabs = tTabs.tabs
	
	for i,tab in pairsByKeys(tabs) do
		if (table.valid(tab)) then
			if (counter == 1) then
				GUI:AlignFirstTextHeightToWidgets()
			end
			
			hovered = tab.hovered
			selected = tab.selected
			normal = tab.normal
			
			if (tab.isselected) then
				if (selected.r > 1 or selected.g > 1 or selected.b > 1) then
					GUI:TextColored(GUI:ColorConvertRGBtoHSV(selected.r,selected.g,selected.b),selected.a,selected.name)
				else
					GUI:TextColored(selected.r,selected.g,selected.b,selected.a,selected.name)
				end
				returnIndex, returnName = i, selected.name
			elseif (tab.ishovered) then
				if (hovered.r > 1 or hovered.g > 1 or hovered.b > 1) then
					GUI:TextColored(GUI:ColorConvertRGBtoHSV(hovered.r,hovered.g,hovered.b),hovered.a,hovered.name)
				else
					GUI:TextColored(hovered.r,hovered.g,hovered.b,hovered.a,hovered.name)
				end
			else
				if (normal.r > 1 or normal.g > 1 or normal.b > 1) then
					GUI:TextColored(GUI:ColorConvertRGBtoHSV(normal.r,normal.g,normal.b),normal.a,normal.name)
				else
					GUI:TextColored(normal.r,normal.g,normal.b,normal.a,normal.name)
				end
			end
			
			tabs[i].ishovered = GUI:IsItemHovered()
			if (tab.ishovered) then
				if (events.onHover and type(events.onHover) == "function") then
					events.onHover()
				end	
				if (tab.onHover and type(tab.onHover) == "function") then
					tab.onHover()
				end					
				if (GUI:IsMouseClicked(0,false)) then
					if (not tabs[i].isselected) then
						if (events.onChange and type(events.onChange) == "function") then
							events.onChange()
						end
					end
					if (events.onClick and type(events.onClick) == "function") then
						events.onClick()
					end
					if (tab.onClick and type(tab.onClick) == "function") then
						tab.onClick()
					end
					tabs[i].isselected = true
					
					for k,tab2 in pairs(tabs) do
						if (i ~= k and tab2.isselected) then
							tabs[k].isselected = false
						end
					end
				end
			end
			
			counter = counter + 1
			local itemsPerLine = IsNull(tTabs.itemsPerLine,(TableSize(tabs) + 1))
			if (counter <= itemsPerLine and i < TableSize(tabs)) then
				GUI:SameLine(0,8); GUI:Text("|"); GUI:SameLine(0,8) 
			else
				counter = 1;
			end
		end
	end
	
	GUI:EndChild()
	GUI:Separator();
	GUI:Spacing()
	
	return returnIndex,returnName
end

RegisterEventHandler("Gameloop.Draw", ffxiv_dialog_manager.Draw)
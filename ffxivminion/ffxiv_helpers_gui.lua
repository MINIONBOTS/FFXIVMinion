ffxiv_dialog_manager = {}
ffxiv_dialog_manager.popup = {}
ffxiv_dialog_manager.controls = {
	["okonly"] = { "OK" },
	["yesno"] = { "Yes", "No" },
	["okcancel"] = { "OK", "Cancel" },
}
ffxiv_dialog_manager.popupresult = 0

function ffxiv_dialog_manager.IssueNotice(title, message, controlset)
	local controlset = IsNull(controlset,1)
	ffxiv_dialog_manager.popup = { ["type"] = "okonly", lines = message, title = title, popped = false }
end

function ffxiv_dialog_manager.IssueStopNotice(title, message, controlset)
	local controlset = IsNull(controlset,1)
	ffxiv_dialog_manager.popup = { ["type"] = "okonly", lines = message, title = title, popped = false }
	
	if (FFXIV_Common_BotRunning) then
		ml_task_hub.ToggleRun()
	end
end

function ffxiv_dialog_manager.Draw( event, ticks ) 
	local popup = ffxiv_dialog_manager.popup
	if (table.valid(popup)) then
		if (not popup.popped) then
			popup.popped = true
			GUI:OpenPopup(popup.title)
		end
		
		if (GUI:BeginPopupModal(popup.title)) then
			local lines = popup.lines
			if (type(lines) == "table") then
				for i,line in pairsByKeys(lines) do
					GUI:Text(line)
				end
			elseif (type(lines) == "string") then
				GUI:Text(lines)
			end
			
			local controls = ffxiv_dialog_manager.controls
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
			
			GUI:EndPopup()
		end
	end
end

function GUI_Set(varName,newVal)
	_G[varName] = newVal
	Settings.FFXIVMINION[varName] = newVal
end

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
	local returned = GUI_Capture(GUI:InputInt(label,var,step,stepfast),varname)
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
				returnIndex, returnName = i, hovered.name
			else
				if (normal.r > 1 or normal.g > 1 or normal.b > 1) then
					GUI:TextColored(GUI:ColorConvertRGBtoHSV(normal.r,normal.g,normal.b),normal.a,normal.name)
				else
					GUI:TextColored(normal.r,normal.g,normal.b,normal.a,normal.name)
				end
				returnIndex, returnName = i, normal.name
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
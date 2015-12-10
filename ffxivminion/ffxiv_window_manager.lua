ffxiv_window_manager = {}
ffxiv_window_manager.windows = {}
ffxiv_window_manager.events = {}
ffxiv_window = inheritsFrom(nil)

function ffxiv_window.Create(strName,iWidth,iHeight,hideFromBar)
	if (not ffxiv_window_manager.windows[strName]) then
		local newWindow = inheritsFrom(ffxiv_window)
		newWindow.name = strName
		newWindow.visible = false
		newWindow.longestLabel = 15
		newWindow.longestField = 30
		newWindow.elements = {}
		newWindow.groups = {}
		newWindow.resetWidth = iWidth or 200
		newWindow.resetHeight = Height or 50
		newWindow.width = newWindow.resetWidth
		newWindow.height = newWindow.resetHeight

		local hideFromBar = hideFromBar or false
		
		local window = WindowManager:NewWindow(strName, 500, 350, newWindow.width, newWindow.height, hideFromBar)
		window:Hide()
		newWindow.window = window
		
		ffxiv_window_manager.windows[strName] = newWindow
		return newWindow
	else
		return ffxiv_window_manager.windows[strName]
	end
end

function ffxiv_window:AddCheckbox(display,editvar,group,default,settingsModule)
	local display = display or ""
	if (type(display) == "string" and display ~= "") then
		local editvar = editvar or "cvar_"..display
		local group = group or "Options"
		local default = default or "0"
		
		local window = self.window
		if (window) then
			local control = window:NewCheckBox(display,editvar,group)
			self.elements[display] = control
			
			if (settingsModule and type(settingsModule) == "string") then
				local settingsVar = Settings[settingsModule][editvar]
				if (settingsVar) then
					_G[editvar] = settingsVar
				else
					if (default ~= nil) then
						if (_G[editvar]) then
							_G[editvar] = default
							Settings[settingsModule][editvar] = default
						end
					end
				end
			else
				if (default ~= nil) then
					if (_G[editvar]) then
						_G[editvar] = default
					end
				end
			end
			
			
			local groups = self.groups
			if (groups[group] == nil) then
				groups[group] = 1
				self.height = self.height + 25
			else
				groups[group] = groups[group] + 1
			end
			
			self:UpdateWidth("checkbox",string.len(display))
			self.height = self.height + 20
			window:SetSize(self.width,self.height)
			return control
		end
	end
end

function ffxiv_window:AddComboBox(display,editvar,group,itemlist,default,settingsModule)
	local display = display or ""
	if (type(display) == "string" and display ~= "") then
		local editvar = editvar or "cvar_"..display
		local group = group or "Options"
		local itemlist = itemlist or ""
		
		local window = self.window
		if (window) then
			local control = window:NewComboBox(display,editvar,group,itemlist)
			self.elements[display] = control
			
			if (settingsModule and type(settingsModule) == "string") then
				local settingsVar = Settings[settingsModule][editvar]
				if (settingsVar) then
					_G[editvar] = settingsVar
				else
					if (default ~= nil) then
						if (_G[editvar]) then
							_G[editvar] = default
							Settings[settingsModule][editvar] = default
						end
					end
				end
			else
				if (default ~= nil) then
					if (_G[editvar]) then
						_G[editvar] = default
					end
				end
			end
			
			local groups = self.groups
			if (groups[group] == nil) then
				groups[group] = 1
				self.height = self.height + 25
			else
				groups[group] = groups[group] + 1
			end
			
			self:UpdateWidth("combobox",string.len(display))
			self.height = self.height + 20
			window:SetSize(self.width,self.height)
			return control
		end
	end
end

function ffxiv_window:AddNumeric(display,editvar,group,minval,maxval,default,settingsModule)
	local display = display or ""
	if (type(display) == "string" and display ~= "") then
		local editvar = editvar or "cvar_"..display
		local group = group or "Options"
		local minval = tonumber(minval) or 0
		local maxval = tonumber(maxval) or 0
		
		local window = self.window
		if (window) then
			local control;
			if (minval ~= 0 or maxval ~= 0) then
				control = window:NewNumeric(display,editvar,group,minval,maxval)
			else
				control = window:NewNumeric(display,editvar,group)
			end
			self.elements[display] = control
			
			if (settingsModule and type(settingsModule) == "string") then
				local settingsVar = Settings[settingsModule][editvar]
				if (settingsVar) then
					_G[editvar] = settingsVar
				else
					if (default ~= nil) then
						if (_G[editvar]) then
							_G[editvar] = default
							Settings[settingsModule][editvar] = default
						end
					end
				end
			else
				if (default ~= nil) then
					if (_G[editvar]) then
						_G[editvar] = default
					end
				end
			end
			
			local groups = self.groups
			if (groups[group] == nil) then
				groups[group] = 1
				self.height = self.height + 25
			else
				groups[group] = groups[group] + 1
			end
			
			self:UpdateWidth("numeric",string.len(display))
			self.height = self.height + 20
			window:SetSize(self.width,self.height)
			return control
		end
	end
end

function ffxiv_window:AddField(display,editvar,group,default,settingsModule)
	local display = display or ""
	if (type(display) == "string" and display ~= "") then
		local editvar = editvar or "cvar_"..display
		local group = group or "Options"
		
		local window = self.window
		if (window) then
			local control = window:NewField(display,editvar,group)
			self.elements[display] = control
			
			if (settingsModule and type(settingsModule) == "string") then
				local settingsVar = Settings[settingsModule][editvar]
				if (settingsVar) then
					_G[editvar] = settingsVar
				else
					if (default ~= nil) then
						if (_G[editvar]) then
							_G[editvar] = default
							Settings[settingsModule][editvar] = default
						end
					end
				end
			else
				if (default ~= nil) then
					if (_G[editvar]) then
						_G[editvar] = default
					end
				end
			end
			
			local groups = self.groups
			if (groups[group] == nil) then
				groups[group] = 1
				self.height = self.height + 25
			else
				groups[group] = groups[group] + 1
			end
			
			self:UpdateWidth("field",string.len(display))
			self.height = self.height + 20
			window:SetSize(self.width,self.height)
			return control
		end
	end
end

function ffxiv_window:AddEvent(strEvent, fnEvent)
	ffxiv_window_manager.events[strEvent] = fnEvent
end

function ffxiv_window:AddButton(display, strEvent, fnEvent, group)
	local window = self.window
	if (window) then
		local control;
		if (group ~= nil) then
			control = window:NewButton(display, strEvent, group)
			
			local groups = self.groups
			if (groups[group] == nil) then
				groups[group] = 1
				self.height = self.height + 25
			else
				groups[group] = groups[group] + 1
			end
		else
			control = window:NewButton(display, strEvent)
		end
		self.elements[display] = true
		
		if (fnEvent and type(fnEvent) == "function") then
			self:AddEvent(strEvent, fnEvent)
		end
		
		self:UpdateWidth("button",string.len(display))
		self.height = self.height + 25
		if (self.visible) then
			window:Hide()
			window:SetSize(self.width,self.height)
			window:Show()
		else
			window:SetSize(self.width,self.height)
		end
	end
end

function ffxiv_window:Hide()
	local window = self.window
	if (window) then
		window:Hide()
		self.visible = false
	end
end

function ffxiv_window:Show(baseWindow,dockPosition)
	--baseWindow is a string with the name
	--dockPosition accepts left/right/below/above
	
	local window = self.window
	if (window) then
		window:SetSize(self.width,self.height)
		if (baseWindow and type(baseWindow) == "string") then
			local wnd = WindowManager:GetWindow(baseWindow)
			if (wnd) then
				if (dockPosition == "right") then
					window:SetPos(wnd.x+wnd.width,wnd.y) 
				elseif (dockPosition == "left") then
					window:SetPos(wnd.x-self.width,wnd.y) 
				elseif (dockPosition == "above") then
					window:SetPos(wnd.x,wnd.y-self.height) 
				elseif (dockPosition == "below") then
					window:SetPos(wnd.x,wnd.y+wnd.height) 
				end
			end
		end
		window:Show()
		self.visible = true
	end
end

function ffxiv_window:FoldGroup(strGroup)
	local window = self.window
	if (window) then
		window:Fold(strGroup)
	end
end

function ffxiv_window:UnFoldGroup(strGroup)
	local window = self.window
	if (window) then
		window:UnFold(strGroup)
	end
end

function ffxiv_window:DeleteGroup(strGroup)
	local window = self.window
	if (window) then
		window:DeleteGroup(strGroup)
		local thisGroup = self.groups[strGroup]
		if (thisGroup ~= nil) then
			local newHeight = self.height - (thisGroup * 20) + 25
			self.height = newHeight
		end
	end
end

function ffxiv_window:ResetSize()
	self.longestLabel = 15
	self.longestField = 30
	self.width = self.resetWidth
	self.height = self.resetHeight
	
	local window = self.window
	if (window) then
		window:SetSize(self.width,self.height)
	end
end

function ffxiv_window:HideGroup(strGroup)
	local window = self.window
	if (window) then
		window:HideGroup(strGroup)
	end
end

function ffxiv_window:ShowGroup(strGroup)
	local window = self.window
	if (window) then
		window:ShowGroup(strGroup)
	end
end

function ffxiv_window:GetControl(strName)
	local window = self.window
	if (window) then
		local control = window:GetControl(strName)
		if (control) then
			return control
		else
			d("Could not find control with the name ["..strName.."].")
			return nil
		end
	end
end

function ffxiv_window:UpdateWidth(controlType,width)
	local longestLabel = self.longestLabel 
	local longestField = self.longestField
	
	local requiresUpdate = false
	if (controlType == "button") then
		if (width > longestField) then
			self.longestField = width
			requiresUpdate = true
		end
	else
		if (width > longestLabel) then
			self.longestLabel = width
			requiresUpdate = true
		end
	end
	
	if (requiresUpdate) then
		local total = 50 + (((self.longestField + self.longestLabel) - 10) * 6)
		self.width = total
	end
end

function ffxiv_window_manager:Show(strName)
	local windows = self.windows
	if (windows) then
		for name,managedwindow in pairs(windows) do
			if (name == strName) then
				local window = managedwindow.window
				if (window) then
					window:SetSize(self.width,self.height)
					window:Show()
				end
			end
		end
	end
end

function ffxiv_window_manager:Hide(strName)
	local windows = self.windows
	if (windows) then
		for name,window in pairs(windows) do
			if (name == strName) then
				window:Hide()
			end
		end
	end
end

function ffxiv_window_manager.ButtonHandler(event, Button)
	if (event == "GUI.Item") then
		local events = ffxiv_window_manager.events
		if (events) then
			for name,action in pairs(events) do
				if (name == Button) then
					action()
				end
			end
		end
	end
end

RegisterEventHandler("GUI.Item",ffxiv_window_manager.ButtonHandler)
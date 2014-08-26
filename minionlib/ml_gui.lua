GUI_Window = {}
setmetatable(GUI_Window, {
	__call = 	function (cls, ...)
					return cls.New(...)
				end,
	__index = 	GUI_Window,
	positions = {top = true, bottom = true, left = true, right = true, none = true}
})

function GUI_Window.New( strName, iX, iY, iH, iW, bVisibleDefault, bAutoSave )
	local self = setmetatable({}, GUI_Window)
		--Non-Optional parameters
		self.name = strName
		self.x = iX
		self.y = iY
		self.height = iH
		self.width = iW
		--Optional parameters
		self.visible = bVisibleDefault or false
		self.autoSave = bAutoSave or false
		self.position = "none"
		self.positionBase = ""
		
		local saveTable = "AutoWindow_"..self.name
		if (self.autoSave) then
			--Create the AutoSave tables if it does not exist.
			if (Settings.FFXIVMINION[saveTable] == nil) then
				Settings.FFXIVMINION[saveTable] = {}
			end
			
			settings = {}			
			settings.width = Settings.FFXIVMINION[saveTable].width or self.width
			settings.height = Settings.FFXIVMINION[saveTable].height or self.height
			settings.y = Settings.FFXIVMINION[saveTable].y or self.y
			settings.x = Settings.FFXIVMINION[saveTable].x or self.x		

			if (ValidTable(settings)) then Settings.FFXIVMINION[saveTable] = settings end
			
			self.x = settings.x
			self.y = settings.y
			self.height = settings.height
			self.width = settings.width
		else
			--AutoSave table exists, but window does not use it, so erase the table.
			if (ValidTable(Settings.FFXIVMINION[saveTable])) then
				Settings.FFXIVMINION[saveTable] = nil
			end
		end
		
		--Placeholders for elements.
		--Windows can truly only hold buttons, element groups.
		self.buttons = {}
		self.groups = {}
		--Triggers are variables that cause a window refresh.
		self.triggers = {}
		
		GUI_Manager.Add(self)
	return self
end

function GUI_Window:OnOpen()
	--[[
	Override this method on an individual basis 
	if something should occur when the window is opened.
	--]]
end

function GUI_Window:OnLoad()
	--[[
	Override this method on an individual basis 
	if something should occur when the window is first loaded/created.
	--]]
end


function GUI_Window:Create(bRefreshOnly)
	local refreshOnly = bRefreshOnly or false
	local wPos = self:GetLocation()
	
	if (not refreshOnly) then
		GUI_NewWindow	(self.name, wPos.x, wPos.y, wPos.width, wPos.height)
		
		--Create buttons first.
		for i, button in spairs(self.buttons) do
			GUI_NewButton(self.name, button.name, button.method)
		end
	end
	
	--Erase all groups first, just to be sure.
	for i, group in pairs(self.groups) do
		GUI_DeleteGroup(self.name, group.name)
	end
	
	--Create all groups and switchers, and unfold them if necessary.
	for i, group in spairs(self.groups) do
		if (group.switcher) then
			local name = _G[group.switcher]
			local switches = groups.group
			switches[var]:Create(self.name)
		else
			group:Create(self.name)
		end
		GUI_UnFoldGroup(self.name,group.name)
	end
	
	GUI_SizeWindow	(self.name, wPos.width, wPos.height)
	GUI_RefreshWindow(self.name)
	GUI_WindowVisible(self.name, self.visible)
end

--Just use it as a helper, so we don't have to duplicate code.
function GUI_Window:Refresh()
	self:Create(true)
end

function GUI_Window:SetLocation( strPosition, oWindow )
	if (self.positions[strPosition] and ValidTable(oWindow)) then
		self.position = strPosition
		self.positionBase = oWindow.name
	end
end

function GUI_Window:UpdateLocation()
	if (self.autoSave) then
		local saveTable = "AutoWindow_"..self.name
		local WI = Settings.FFXIVMINION[saveTable]
		local W = GUI_GetWindowInfo(self.name)
		local settings = {}
			
		settings.width = (WI.width ~= W.width) and W.width or WI.width
		settings.height = (WI.height ~= W.height) and W.height or WI.height
		settings.x = (WI.x ~= W.x) and W.x or WI.x
		settings.y = (WI.y ~= W.y) and W.y or WI.y
			
		if (ValidTable(settings) and settings ~= WI) then 
			Settings.FFXIVMINION[saveTable] = settings
		end
	end
end

function GUI_Window:GetLocation()
	if (self.position ~= "") then
		local pos = self.position
		local window = ml_ui:GetWindow(self.positionBase)
		if (ValidTable(window)) then
			if (self.position == "right") then
				return {x = (window.x + window.width), y = window.y, height = self.height, width = self.width}
			elseif (self.position == "left") then
				return {x = (window.x - self.width), y = window.y, height = self.height, width = self.width}
			elseif (self.position == "bottom") then
				return {x = window.x, y = (window.y + window.height), height = self.height, width = self.width}
			elseif (self.position == "top") then
				return {x = window.x, y = (window.y - self.height), height = self.height, width = self.width} 
			end
		end
	else
		return {x = self.x, y = self.y, height = self.height, width = self.width}
	end
end

--This function is for top-level buttons that do not reside in a group.
--Only buttons can be added this way because other elements cause visual issues when not in a group.
--Buttons on GUI appear in order of first added on bottom, last added on top.
function GUI_Window:AddButton( strName, strFunction )
	if not IsNullString(strName) and not IsNullString(strFunction) then
		local found = false
		for i, button in pairs(self.buttons) do
			if ( button.name == strName ) then
				found = true
			end
			if (found) then
				d("Button was not added because a button with this name already exists.")
				return false
			end
		end
		
		local insertPos = TableSize(self.buttons) + 1
		self.buttons[insertPos] = { name = strName, method = strFunction }
		GUI_Manager.Update(self)
	end
end

function GUI_Window:AddGroup( oGroup )
	if ValidTable(oGroup) then
		local insertPos = TableSize(self.groups) + 1
		self.groups[insertPos] = oGroup
	end
	GUI_Manager.Update(self)
end

function GUI_Window:AddSwitcher( oSwitcher )
	self:AddGroup( oSwitcher )
	self:AddTrigger(oSwitcher.switch)
	GUI_Manager.Update(self)
end

function GUI_Window:AddTrigger( strTrigger )
	if (strTrigger and strTrigger ~= "") then
		self.triggers[strTrigger] = true
	end
end


GUI_Group = {}
setmetatable(GUI_Group, {
	__call = 	function (cls, ...)
					return cls.New(...)
				end,
	__index = GUI_Group
})

function GUI_Group.New( strGroup, bAutoExpand )
	local self = setmetatable({}, GUI_Group)
		--Non-Optional parameters
		self.name = strGroup
		--Optional parameters
		self.autoExpand = bAutoExpand or false
		--Element placeholders
		self.elements = {}
	return self
end

function GUI_Group:Create( strWindow )
	if (ValidTable(self.elements) and strWindow and strWindow ~= "") then
		for i, element in spairs(self.elements) do
			if (element.type == "button") then
				GUI_NewButton(strWindow, element.name, element.method, self.name)
			elseif (element.type == "field") then
				GUI_NewField(strWindow, element.name, element.variable, self.name)
			elseif (element.type == "checkbox") then
				GUI_NewCheckbox(strWindow, element.name, element.variable, self.name)
			elseif (element.type == "numeric") then
				if (element.min == 0 and element.max == 9999) then
					GUI_NewNumeric(strWindow, element.name, element.variable, self.name)
				else
					GUI_NewNumeric(strWindow, element.name, element.variable, self.name, element.min, element.max)
				end
			elseif (element.type == "combobox") then
				local list
				if (type(element.list) == "string") then
					list = element.list
				else
					list = element.list()
				end
				
				GUI_NewComboBox(strWindow, element.name, element.variable, self.name, list)
			end
		end
	end
end

function GUI_Group:AddButton( strName, strFunction )
	if not IsNullString(strName) and not IsNullString(strFunction) then
		local found = false
		for i, element in pairs(self.elements) do
			if ( element.name == strName and element.type == "button" ) then
				found = true
			end
			if (found) then
				d("Button was not added because a button with this name already exists.")
				return false
			end
		end
		
		local insertPos = TableSize(self.elements) + 1
		self.elements[insertPos] = { type = "button", name = strName, method = strFunction }
	end
end

function GUI_Group:AddField( strName, strVariable, varDefault )
	if not IsNullString(strName) and not IsNullString(strVariable) then
		local found = false
		for i, element in pairs(self.elements) do
			if ( element.variable == strVariable ) then
				found = true
			end
			if (found) then
				d("Field was not added because this variable is already being used.")
				return false
			end
		end
		
		local insertPos = TableSize(self.elements) + 1
		self.elements[insertPos] = { type = "field", name = strName, variable = strVariable }
		
		local defaultValue = tonumber(varDefault) or varDefault
		if (not defaultValue) then defaultValue = "" end
		
		--Use a global reference for creating the variable object, for easy access.
		local oName = "GUI_"..strVariable
		_G[oName] = GUI_Variable(strVariable, defaultValue)
	end
end

function GUI_Group:AddCheckBox( strName, strVariable, varDefault )
	if not IsNullString(strName) and not IsNullString(strVariable) then
		local found = false
		for i, element in pairs(self.elements) do
			if ( element.variable == strVariable ) then
				found = true
			end
			if (found) then
				d("CheckBox was not added because this variable is already being used.")
				return false
			end
		end
		
		local insertPos = TableSize(self.elements) + 1
		self.elements[insertPos] = { type = "checkbox", name = strName, variable = strVariable }
		
		local defaultValue = (varDefault == true or varDefault == "1") and "1" or "0"
		--Use a global reference for creating the variable object, for easy access.
		local oName = "GUI_"..strVariable
		_G[oName] = GUI_Variable(strVariable, defaultValue)
	end
end

function GUI_Group:AddNumeric( strName, strVariable, varDefault, iMin, iMax )
	if not IsNullString(strName) and not IsNullString(strVariable) then
		local found = false
		for i, element in pairs(self.elements) do
			if ( element.variable == strVariable ) then
				found = true
			end
			if (found) then
				d("Numeric was not added because this variable is already being used.")
				return false
			end
		end
		
		iMin = iMin or 0
		iMax = iMax or 9999
		local insertPos = TableSize(self.elements) + 1
		self.elements[insertPos] = { type = "numeric", name = strName, variable = strVariable, min = iMin, max = iMax }
	
		local defaultValue = tonumber(varDefault) or varDefault		
		--Use a global reference for creating the variable object, for easy access.
		local oName = "GUI_"..strVariable
		_G[oName] = GUI_Variable(strVariable, defaultValue)
	end
end

--varList can be a string of comma-separated text, or a function that returns such a string
function GUI_Group:AddComboBox( strName, strVariable, varDefault, varList )
	if not IsNullString(strName) and not IsNullString(strVariable) and varList then
		local found = false
		for i, element in pairs(self.elements) do
			if ( element.variable == strVariable ) then
				found = true
			end
			if (found) then
				d("ComboBox was not added because this variable is already being used.")
				return false
			end
		end
		
		local insertPos = TableSize(self.elements) + 1
		self.elements[insertPos] = { type = "combobox", name = strName, variable = strVariable, list = varList }
	
		local defaultValue = tonumber(varDefault) or varDefault
		if (not defaultValue) then defaultValue = "" end
		
		--Use a global reference for creating the variable object, for easy access.
		local oName = "GUI_"..strVariable
		_G[oName] = GUI_Variable(strVariable, defaultValue)
	end
end

--Switchers contain other groups, and change the group based on certain variable.
GUI_Switcher = {}
setmetatable(GUI_Switcher, {
	__call = 	function (cls, ...)
					return cls.New(...)
				end,
	__index = GUI_Switcher
})

function GUI_Switcher.New( strName, varSwitch, bAutoExpand)
	local self = setmetatable({}, GUI_Switcher)
		--Non-Optional parameters
		self.name = strName
		self.switch = varSwitch
		--Optional parameters
		self.autoExpand = bAutoExpand or false
		--Element placeholders
		self.groups = {}
	return self
end

function GUI_Switcher:AddGroup( varGroup )
	if ValidTable(varGroup) then
		self.groups[varGroup.name] = varGroup
	end
end

--Variables, given their own object to provide access to custom event methods.
GUI_Variable = {}
setmetatable(GUI_Variable, {
	__call = 	function (cls, ...)
					return cls.New(...)
				end,
	__index = GUI_Variable
})

--At the minimum, variables need a name and a default value.
function GUI_Variable.New( strName, varDefault )
	local self = setmetatable({}, GUI_Variable)
	--Non-Optional parameters
	self.name = strName
	self.default = varDefault
	
	if (Settings.FFXIVMINION[self.name] == nil) then
		Settings.FFXIVMINION[self.name] = self.default
	end
	
	 _G[self.name] = Settings.FFXIVMINION[self.name]
	
	GUI_Manager.AddVariable(self)
	return self
end

function GUI_Variable:OnChange()
	--[[
	Override this method on an individual basis 
	if something should occur when the variable is changed.
	
	
	Ex:
	function GUI_gSomeVar:OnChange()
		RefreshAllWindows()
		d("Put some stuff in console")
	end
	--]]
end
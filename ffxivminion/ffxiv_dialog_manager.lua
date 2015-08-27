--[[
	local message = ml_task_hub:ThisTask().params["notes"] or "Profile has completed successfully."
	local winName = "EndProfile_"..tostring(ml_task_hub:CurrentTask():ParentTask().quest.id)
	local hide = function () ffxiv_dialog_manager:Hide(winName) end
	local newDialog = ffxiv_dialog.Create(winName)
	if (newDialog) then
		if (newDialog.elements == 0) then
			newDialog:AddButton("OK",winName.."_OKFunction")
			newDialog:AddEvent(winName.."_OKFunction",hide)
			newDialog:AddLabel(message)
		end
		newDialog:Show()
	end
--]]

ffxiv_dialog_manager = {}
ffxiv_dialog_manager.dialogs = {}
ffxiv_dialog_manager.events = {}
ffxiv_dialog = inheritsFrom(nil)

function ffxiv_dialog.Create(strName)
	assert(strName and type(strName) == "string" and strName ~= "", "First argument for ffxiv_dialog:Create expects type [string] of length 1 or more.")
	if (not ffxiv_dialog_manager.dialogs[strName]) then
		local newDialog = inheritsFrom(ffxiv_dialog)
		newDialog.name = strName
		newDialog.visible = false
		newDialog.elements = 0
		newDialog.height = 50
		newDialog.longestLine = 0
		newDialog.width = 50
		
		local window = WindowManager:NewWindow(strName, 500, 350, newDialog.width, newDialog.height, true)
		window:Hide()
		newDialog.window = window
		
		ffxiv_dialog_manager.dialogs[strName] = newDialog
		return newDialog
	else
		return ffxiv_dialog_manager.dialogs[strName]
	end
end

function ffxiv_dialog:AddEvent(strName, fnEvent)
	assert(strName and type(strName) == "string" and strName ~= "", "First argument for ffxiv_dialog:AddEvent expects type [string] of length 1 or more.")
	assert(fnEvent and type(fnEvent) == "function", "Second argument for ffxiv_dialog:AddEvent expects type [function], received ["..tostring(type(fnEvent)).."]")
	
	ffxiv_dialog_manager.events[strName] = fnEvent
end

function ffxiv_dialog:AddLabel(varLine)
	assert(varLine and (type(varLine) == "string" or type(varLine) == "table"), "First argument for ffxiv_dialog:AddLabel expects type [string] of length 1 or more.")
	
	local window = self.window
	if (window) then
		if (type(varLine) == "table") then
			for i,name in pairsByKeys(varLine) do
				window:NewLabel(name)
				self.elements = self.elements + 1
				self.height = self.height + 23.5
				if (string.len(name) > self.longestLine) then
					self.longestLine = string.len(name)
					self.width = 50 + ((string.len(name) - 10) * 6)
				end
			end
		elseif (type(varLine) == "string") then
			window:NewLabel(varLine)
			self.elements = self.elements + 1
			self.height = self.height + 23.5
			if (string.len(varLine) > self.longestLine) then
				self.longestLine = string.len(varLine)
				self.width = 50 + ((string.len(varLine) - 10) * 6)
			end
		end
	end
end

function ffxiv_dialog:AddButton(strName, strEvent)         
	assert(strName and type(strName) == "string" and strName ~= "", "First argument for ffxiv_dialog:AddButton expects type [string] of length 1 or more.")
	assert(strEvent and type(strEvent) == "string" and strEvent ~= "", "Second argument for ffxiv_dialog:AddButton expects type [string] of length 1 or more.")
	
	local window = self.window
	if (window) then
		window:NewButton(strName, strEvent)
		self.elements = self.elements + 1
		self.height = self.height + 25
	end
end

function ffxiv_dialog:Hide()
	local window = self.window
	if (window) then
		window:Hide()
	end
end

function ffxiv_dialog:Show()
	local window = self.window
	if (window) then
		window:SetSize(self.width,self.height)
		window:Show()
	end
end

function ffxiv_dialog_manager:Hide(strName)
	local dialogs = self.dialogs
	if (dialogs) then
		for name,dialog in pairs(dialogs) do
			if (name == strName) then
				dialog:Hide()
			end
		end
	end
end

function ffxiv_dialog_manager.ButtonHandler(event, Button)
	if (event == "GUI.Item") then
		local events = ffxiv_dialog_manager.events
		if (events) then
			for name,action in pairs(events) do
				if (name == Button) then
					action()
				end
			end
		end
	end
end

function ffxiv_dialog_manager.IssueStopNotice(winTitle, message)
	local message = message or ""
	local winName = winTitle or "Stop Notice"
	local hide = function () ffxiv_dialog_manager:Hide(winName) end
	local newDialog = ffxiv_dialog.Create(winName)
	if (newDialog) then
		if (newDialog.elements == 0) then
			newDialog:AddButton("OK",winName.."_OKFunction")
			newDialog:AddEvent(winName.."_OKFunction",hide)
			newDialog:AddLabel(message)
		end
		newDialog:Show()
	end
	
	if (gBotRunning == "1") then
		ml_task_hub.ToggleRun()
	end
end

function ffxiv_dialog_manager.IssueNotice(winTitle, message)
	local message = message or ""
	local winName = winTitle or "Notice"
	local hide = function () ffxiv_dialog_manager:Hide(winName) end
	local newDialog = ffxiv_dialog.Create(winName)
	if (newDialog) then
		if (newDialog.elements == 0) then
			newDialog:AddButton("OK",winName.."_OKFunction")
			newDialog:AddEvent(winName.."_OKFunction",hide)
			newDialog:AddLabel(message)
		end
		newDialog:Show()
	end
end

RegisterEventHandler("GUI.Item",ffxiv_dialog_manager.ButtonHandler)
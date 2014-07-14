--GUI_Manager stores and controls windows.
--Most functions could be accessed directly on the element objects
--, but it looks cleaner passed through a central hub like this.

GUI_Manager = {}
GUI_Manager.windows = {}
GUI_Manager.variables = {}
GUI_Manager.events = {}

--Add a window to the manager.
function GUI_Manager.AddWindow(oWindow)
	if (ValidTable(oWindow)) then
		local key = oWindow.name
		
		if (key) then
			GUI_Manager.windows[key] = oWindow
		end
	end
end

function GUI_Manager.AddVariable(oVariable)
	if (ValidTable(oVariable)) then
		local vName = oVariable.name
		if (not GUI_Manager.variables[vName]) then
			GUI_Manager.variables[vName] = {}
		end
		GUI_Manager.variables[vName] = oVariable
		GUI_Manager.InitializeVariable(strVariable)
	end
end

function GUI_Manager.Update(oWindow)
	if (ValidTable(GUI_Manager.windows[oWindow.name])) then
		GUI_Manager.windows[oWindow.name] = oWindow
	end
end

function GUI_Manager.CreateAllWindows()
	local windows = GUI_Manager.windows
	for i, window in pairs(windows) do
		window:Create()
	end
end

function GUI_Manager.UpdateWindows()
	local windows = GUI_Manager.windows
	for i, window in pairs(windows) do
		window:UpdateLocation()
	end
end

function GUI_Manager.CatchTriggers( strVariable )
	local windows = GUI_Manager.windows
	for _, window in pairs(windows) do
		if (window.triggers[strVariable]) then
			window:Refresh()
		end
	end
end

function GUI_Manager.LoadVariables()
	local variables = GUI_Manager.variables
	
	for k,v in pairs(variables) do
		_G[v.name] = Settings.FFXIVMINION[v.name]
	end
end

function GUI_Manager.CatchEvents( strVariable )
	for i, variable in pairs(GUI_Manager.variables) do
		if (variable.name == strVariable) then
			variable:OnChange()
		end
	end
end

function GUI_Manager.GetWindow( varGet )
	if (varGet) then
		if type(varGet) == "table" then
			if (ValidTable(GUI_Manager.windows[varGet.name])) then
				return GUI_Manager.windows[varGet.name]
			end
		elseif type(varGet) == "string" then
			if (not IsNullString(varGet)) then
				if (ValidTable(GUI_Manager.windows[varGet])) then
					return GUI_Manager.windows[varGet]
				end
			end
		end
	end
	
	return nil
end

function GUI_Manager.OpenWindow( strCommand )
		local window = string.gsub(event,"QMToggle","")
		
		if (QM.Windows[window].base ~= nil) then
			local wnd = GUI_GetWindowInfo(QM.Windows[QM.Windows[window].base].name)
			GUI_MoveWindow(QM.Windows[window].name, wnd.x+wnd.width, wnd.y)
		end
		
		GUI_WindowVisible(QM.Windows[window].name,not QM.Windows[window].visible)
		QM.Windows[window].visible = not QM.Windows[window].visible
		
		if (QM.Windows[window].onOpen ~= nil) then
			QM.ExecuteFunction(tostring(QM.Windows[window].onOpen))
		end
end



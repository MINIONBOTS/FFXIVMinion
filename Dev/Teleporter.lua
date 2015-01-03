TP = { }
TP.coordspath = GetStartupPath()..[[\LuaMods\Dev\Waypoint\]];
TP.WinNames = {
	Main = "Teleporter",
	Save = "New Waypoint",
	Edit = "Edit Waypoint",
}
TP.WinName = TP.WinNames.Main

TP.WindowTick = 0
TP.ClickTPTick = 0
TP.UpdateWaypointTick = 0
TP.MapID = 0
TP.availableCoords = {}

TP.Visible = {
	Main = false,
	Save = false,
	Edit = false,
}

TP.ModifierKeys = {
	["None"] = 0,
	["Left SHIFT"] = 160,
	["Right SHIFT"] = 161,
	["Left CONTROL"] = 162,
	["Right CONTROL"] = 163,
	["Left ALT"] = 164,
	["Right ALT"] = 165,
}

TP.ShortcutKeys = {
["None"]=	0,
["Left Mouse"]=	1,
["Right Mouse"]=	2,
["Middle Mouse"]=	4,
["BACKSPACE"]=	8,
["TAB"]=	9,
["ENTER"]=	13,
["PAUSE"]=	19,
["ESC"]=	27,
["SPACEBAR"]=	32,
["PAGE UP"]=	33,
["PAGE DOWN"]=	34,
["END"]=	35,
["HOME"]=	36,
["LEFT ARROW"]=	37,
["UP ARROW"]=	38,
["RIGHT ARROW"]=	39,
["DOWN ARROW"]=	40,
["PRINT"]=	42,
["INS"]=	45,
["DEL"]=	46,
["0"]=	48,
["1"]=	49,
["2"]=	50,
["3"]=	51,
["4"]=	52,
["5"]=	53,
["6"]=	54,
["7"]=	55,
["8"]=	56,
["9"]=	57,
["A"]=	65,
["B"]=	66,
["C"]=	67,
["D"]=	68,
["E"]=	69,
["F"]=	70,
["G"]=	71,
["H"]=	72,
["I"]=	73,
["J"]=	74,
["K"]=	75,
["L"]=	76,
["M"]=	77,
["N"]=	78,
["O"]=	79,
["P"]=	80,
["Q"]=	81,
["R"]=	82,
["S"]=	83,
["T"]=	84,
["U"]=	85,
["V"]=	86,
["W"]=	87,
["X"]=	88,
["Y"]=	89,
["Z"]=	90,
["NUM 0"]=	96,
["NUM 1"]=	97,
["NUM 2"]=	98,
["NUM 3"]=	99,
["NUM 4"]=	100,
["NUM 5"]=	101,
["NUM 6"]=	102,
["NUM 7"]=	103,
["NUM 8"]=	104,
["NUM 9"]=	105,
["Separator"]=	108,
["Subtract"]=	109,
["Decimal"]=	110,
["Divide"]=	111,
["F1"]=	112,
["F2"]=	113,
["F3"]=	114,
["F4"]=	115,
["F5"]=	116,
["F6"]=	117,
["F7"]=	118,
["F8"]=	119,
["F9"]=	120,
["F10"]=	121,
["F11"]=	122,
["F12"]=	123,
["SCROLL LOCK"]=	145,
}

TP.AutoList = {}
TP.AutoListMapId = 0
TP.AutoGroups={[5]="Aetheryte",[7]="Object",[3]="NPC",[2]="Beast",[100]="FATE"}

function TP.ModuleInit()

	if (Settings.Dev.TeleportWindow == nil or Settings.Dev.TeleportWindow == {}) then 
		local windowInfo = {} 
		windowInfo.width = 380
		windowInfo.height = 520
		windowInfo.x = 500
		windowInfo.y = 40
		
		Settings.Dev.TeleportWindow = windowInfo
	end
	
	local WI = Settings.Dev.TeleportWindow

	if (Settings.Dev.gClickTeleport == nil) then
		Settings.Dev.gClickTeleport = "Cursor"
	end
	if (Settings.Dev.gClickName1 == nil) then
		Settings.Dev.gClickName1 = "None"
	end
	if (Settings.Dev.gClickName2 == nil) then
		Settings.Dev.gClickName2 = "None"
	end
	if (Settings.Dev.gAutoRecord == nil) then
		Settings.Dev.gAutoRecord = "0"
	end
	if (Settings.Dev.gAutoRecordMobs == nil) then
		Settings.Dev.gAutoRecordMobs = "0"
	end
	if (Settings.Dev.gMoveDist == nil) then
		Settings.Dev.gMoveDist = "10"
	end
	
	--Let's create all our windows at once, instead of all throughout the code.
	local WinName = nil
	
	--Waypoint Edit Window
	WinName = TP.WinNames.Edit
	GUI_NewWindow	(WinName,WI.x,WI.y,WI.width,WI.height,"",true)
	
	GUI_NewComboBox (WinName,"Waypoint:","gRepPoint","Waypoint","")
	GUI_NewField	(WinName,"New Name:","gRepName","Waypoint")
	GUI_NewButton	(WinName,"Get Target Name","TP.GetTargetName","Waypoint")
	
	GUI_NewButton	(WinName,"Delete Waypoint","TPChangeWaypointDelete")
	GUI_NewButton	(WinName,"Rename Waypoint","TPChangeWaypointRename")
	GUI_NewButton	(WinName,"Replace to Target POS","TPChangeWaypointReplaceTPos")
	GUI_NewButton	(WinName,"Replace to Player POS","TPChangeWaypointReplacePPos")
	
	GUI_UnFoldGroup	(WinName,"Waypoint")
	GUI_SizeWindow	(WinName,WI.width,200)
	GUI_WindowVisible(WinName,TP.Visible.Edit)	
	
	--Teleporter Save Window
	WinName = TP.WinNames.Save
	GUI_NewWindow	(WinName,WI.x,WI.y,WI.width,100,"",true)
	GUI_NewField	(WinName,"Name:","gSaveName","Save")
	GUI_NewButton	(WinName,"Get Target Name","TP.GetTargetName","Save")
	GUI_NewButton	(WinName,"Save Player POS","TPSavePlayer")
	GUI_NewButton	(WinName,"Save Target POS","TPSaveTarget")
	
	GUI_UnFoldGroup	(WinName,"Save")
	GUI_SizeWindow	(WinName,WI.width,130)
	GUI_WindowVisible(WinName,TP.Visible.Save)			
	
	--Teleporter Main Window
	WinName = TP.WinName
	GUI_NewWindow	(WinName,WI.x,WI.y,WI.width,WI.height)
    GUI_NewField	(WinName,"Map ID","gMapName","Info")
    GUI_NewField	(WinName," X | Y | Z | H","gPlayerPOS","Info")
    GUI_UnFoldGroup	(WinName,"Info")
	
	local teleKey1 = ""
	local teleKey2 = ""
	
	local sort_func = function( t,a,b ) return t[a] < t[b] end
	for k,v in spairs(TP.ModifierKeys,sort_func) do
		teleKey1 = teleKey1..","..k
	end
	
	for k,v in spairs(TP.ShortcutKeys,sort_func) do
		teleKey2 = teleKey2..","..k
	end
	
	GUI_NewCheckbox	(WinName,"Auto-Record","gAutoRecord","Setting")
	GUI_NewCheckbox	(WinName,"Include Mobs","gAutoRecordMobs","Setting")
	GUI_NewComboBox	(WinName,"Port To:","gClickTeleport","Setting","None,Cursor,Target")
	GUI_NewComboBox	(WinName,"Port Buttons","gClickName1","Setting",teleKey1)
	GUI_NewComboBox	(WinName,"+","gClickName2","Setting",teleKey2)
	
	GUI_NewButton(WinName,"QS 1","TPQuickSave1","Quick Save/Load")
	GUI_NewButton(WinName,"QL 1","TPQuickLoad1","Quick Save/Load")
	GUI_NewButton(WinName,"QS 2","TPQuickSave2","Quick Save/Load")
	GUI_NewButton(WinName,"QL 2","TPQuickLoad2","Quick Save/Load")

	GUI_NewField	(WinName,"Distance","gMoveDist","Move")
	GUI_NewButton	(WinName,"Forward",	"TPMoveF","Move")
	GUI_NewButton	(WinName,"Back",	"TPMoveB","Move")
	GUI_NewButton	(WinName,"Right",	"TPMoveR","Move")
	GUI_NewButton	(WinName,"Left",	"TPMoveL","Move")
	GUI_NewButton	(WinName,"Down",	"TPMoveD","Move")
	GUI_NewButton	(WinName,"Up",		"TPMoveU","Move")

	GUI_NewButton(TP.WinName,"Refresh","TP.Refresh")
	GUI_NewButton(TP.WinName,"Edit Waypoint", "TPToggleEdit")
	GUI_NewButton(TP.WinName,"New Waypoint","TPToggleSave")
	
	GUI_SizeWindow(TP.WinName,WI.width,WI.height)
	GUI_WindowVisible(TP.WinName, TP.Visible.Main)
	
	gAutoRecord = Settings.Dev.gAutoRecord	
	gAutoRecordMobs = Settings.Dev.gAutoRecordMobs
	gClickTeleport = Settings.Dev.gClickTeleport
	gClickName1 = Settings.Dev.gClickName1
    gClickName2 = Settings.Dev.gClickName2
	gMoveDist = Settings.Dev.gMoveDist
end

function TP.GUIVarUpdate(Event, NewVals, OldVals)
	
	for k,v in pairs(NewVals) do		
		if (
			k == "gAutoRecord" or
			k == "gAutoRecordMobs" or
			k == "gClickTeleport" or
			k == "gClickName1" or
			k == "gClickName2" or
			k == "gMoveDist") then
			Settings.Dev[tostring(k)] = v
		end  
	end

	GUI_RefreshWindow(TP.WinName)
end

function TP.OnUpdate( Event, ticks ) 	
	if (TimeSince(TP.ClickTPTick) > 50 ) then
		TP.ClickTPTick = ticks
		TP.TargetPort()
	end
	
	if (TimeSince(TP.WindowTick) > 1000) then
		TP.WindowTick = ticks
		TP.WindowUpdate()
	end
	
	if (TimeSince(TP.UpdateWaypointTick) > 1000) then
		TP.UpdateWaypointTick = ticks
		if (not IsLoading()) then
			local p = shallowcopy(Player.pos)
			gPlayerPOS = string.format("%.2f",p.x).." | "..string.format("%.2f",p.y).." | "..string.format("%.2f",p.z).." | "..string.format("%.2f",p.h)
			if (TP.MapID ~= Player.localmapid) then
				TP.Refresh()
			end
		end
		TP.DoAutoAdd()
	end
end

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function CalculateTargetPosition( dest )
	local p,dist = NavigationManager:GetClosestPointOnMesh(dest)

	if (tpPrefMeshPos == "0" or dist > 40) then
		dist = tonumber(tpDistance)
		if (dist == nil ) then dist = 0.0 end
		local dirV = { x=math.sin(dest.h)*dist,z = math.cos(dest.h)*dist }
		local pos = deepcopy(dest)
		pos.x = dest.x + dirV.x
		pos.z = dest.z + dirV.z
		return pos
	else
		return p
	end
    
end

function TP.UpdateAutoAddGUI()
	for i, group in pairs(TP.AutoGroups) do
		GUI_DeleteGroup(TP.WinName,group)
	end

	local sort_func = function( t,a,b ) return t[a].NAME < t[b].NAME end
	for oid,obj in spairs(TP.AutoList,sort_func) do 
		GUI_NewButton(TP.WinName,	obj.NAME.." / "..tostring(obj.ID),	"AutoListTP_"..tostring(obj.ID),	TP.AutoGroups[obj.TYPE])
	end
	
	GUI_SizeWindow(TP.WinName,Settings.Dev.TeleportWindow.width,Settings.Dev.TeleportWindow.height)
	GUI_RefreshWindow(TP.WinName)
end

function TP.DoAutoAdd()    
	if (not IsLoading()) then
		if (gAutoRecord == "1") then
			local el = EntityList("")
			local i,e = next(el)
			local dirty = false
			while (i~=nil and e ~= nil) do
				if (e.targetable and (e.type == 3 or e.type==5 or e.type==7 or (gAutoRecordMobs == "1" and e.type == 2)) and e.uniqueid ~= 0) then
					obj = { }
					obj.ID = e.uniqueid
					obj.CONTENTID = e.contentid
					obj.TYPE = e.type
					obj.POS = e.pos
					obj.NAME = e.name

					if (TP.AutoList[obj.ID] == nil) then
						TP.AutoList[obj.ID] = obj
						dirty = true
					end
				end
				i,e = next(el,i)  
			end
			
			local fatelist = MapObject:GetFateList()
			if (ValidTable(fatelist)) then
				for i, fate in pairs(fatelist) do
					obj = {}
					obj.ID = fate.id
					obj.NAME = fate.name
					obj.TYPE = 100
					obj.POS = {
						x = fate.x,
						y = fate.y,
						z = fate.z,
					}
					if (TP.AutoList[obj.ID] == nil) then
						TP.AutoList[obj.ID] = obj
						dirty = true
					end
				end
			end
			
			if (dirty) then
				persistence.store(TP.coordspath..TP.AutoListMapId.."_auto"..".lua",TP.AutoList)
				TP.UpdateAutoAddGUI()
			end
		end
	end
end

--**************************************************************************************************************************************
function TP.ChangeWaypoint(event)
	local ppos = shallowcopy(Player.pos)
	local target = Player:GetTarget()
	local tpos = nil
	if (ValidTable(target)) then
		tpos = shallowcopy(target.pos)
	end
	local WinName = TP.WinNames.Edit
	
	local oldCoordKey = 0
	local oldCoord = {}
	for i, coord in pairs(TP.availableCoords) do
		if (coord.name == gRepPoint) then
			oldCoordKey = i
			oldCoord = coord
		end
	end
	
	if (oldCoord and oldCoordKey ~= 0) then
		if (event == "ReplacePPos") then
			TP.availableCoords[oldCoordKey] = {
				name = (gRepName ~= "" and gRepName) or oldCoord.name,
				x = ppos.x,
				y = ppos.y,
				z = ppos.z,
				h = ppos.h,
			}
		elseif (event == "ReplaceTPos" and tpos ~= nil) then
			TP.availableCoords[oldCoordKey] = {
				name = (gRepName ~= "" and gRepName) or oldCoord.name,
				x = tpos.x,
				y = tpos.y,
				z = tpos.z,
				h = ppos.h,
			}
		elseif (event == "Rename" and gRepName ~= "") then
			TP.availableCoords[oldCoordKey] = {
				name = gRepName,
				x = oldCoord.x,
				y = oldCoord.y,
				z = oldCoord.z,
				h = oldCoord.h,
			}
		elseif (event == "Delete") then
			table.remove(TP.availableCoords,oldCoordKey)
		end
	
		persistence.store(TP.coordspath..tostring(Player.localmapid)..".lua",TP.availableCoords)
		GUI_WindowVisible(WinName,false)
		TP.RefreshWaypoints()
	end
end
--**************************************************************************************************************************************
function TP.SaveWaypoint(event)
	if (event == "Player") then
		if (gSaveName ~= "") then
			local ppos = shallowcopy(Player.pos)
			local WinName = TP.WinNames.Save
			local savePos = {}
			
			savePos.name = gSaveName
			savePos.x = ppos.x
			savePos.y = ppos.y
			savePos.z = ppos.z
			savePos.h = ppos.h
			
			table.insert(TP.availableCoords, savePos)
			persistence.store(TP.coordspath..tostring(Player.localmapid)..".lua",TP.availableCoords)
			GUI_WindowVisible(WinName,false)
			TP.RefreshWaypoints()
		end
	elseif (event == "Target") then
		local target = Player:GetTarget()
		if (ValidTable(target) and gSaveName ~= "") then
			local tpos = shallowcopy(target.pos)
			local ppos = shallowcopy(Player.pos)
			local WinName = "Teleporter Save"
			local savePos = {}
			
			savePos.name = gSaveName
			savePos.x = tpos.x
			savePos.y = tpos.y
			savePos.z = tpos.z
			savePos.h = ppos.h
			
			table.insert(TP.availableCoords, savePos)
			persistence.store(TP.coordspath..tostring(Player.localmapid)..".lua",TP.availableCoords)
			GUI_WindowVisible(WinName,false)
			TP.RefreshWaypoints()
		end
	end
end
--**************************************************************************************************************************************
function TP.GetTargetName()
	local target = Player:GetTarget()
	if (target and target.name) then
		gSaveName = target.name
		gRepName = target.name
	end
end
--**************************************************************************************************************************************
function TP.Port(key)
	local key = tonumber(key)
	local coord = TP.availableCoords[key]
	
	if (ValidTable(coord)) then
		GameHacks:TeleportToXYZ(coord.x,coord.y,coord.z)
		Player:SetFacingSynced(coord.h)
	end
end
--**************************************************************************************************************************************
function TP.LoadWaypoints()
	local mapID = Player.localmapid
	TP.MapID = mapID
	gMapName = mapID
	
	--Load waypoints from _auto files.
	if (TP.AutoListMapId == 0 or TP.AutoListMapId ~= Player.localmapid) then
		TP.AutoListMapId = Player.localmapid
		TP.AutoList = persistence.load(TP.coordspath..TP.AutoListMapId.."_auto"..".lua")
		
		if (TP.AutoList == nil) then
			TP.AutoList = {}  
		else 
			TP.UpdateAutoAddGUI()
		end
    end
		
	TP.availableCoords = {}
	local lines = fileread(TP.coordspath..tostring(mapID)..".lua")
	if (lines) then
		for i,line in pairs(lines) do
			if (line ~= "") then
				if (string.find(line,":") ~= nil) then
					local newCoord = {}
					local i = 1
					for part in StringSplit(line,":") do
						part = string.gsub(part,"\r","")
						if i == 1 then
							newCoord.name = part
						elseif i == 2 then
							newCoord.x = tonumber(part)
						elseif i == 3 then
							newCoord.z = tonumber(part)
						elseif i == 4 then
							newCoord.y = tonumber(part)
						elseif i == 5 then
							newCoord.h = tonumber(part)
						end
						i = i + 1
					end
					if (ValidTable(newCoord) and i >= 4) then
						table.insert(TP.availableCoords, newCoord)
					end
				end
			end
		end
		if (TableSize(TP.availableCoords) > 0) then
			persistence.store(TP.coordspath..tostring(mapID)..".lua",TP.availableCoords)
		end
	end
	
	if (TableSize(TP.availableCoords) == 0) then
		local profile = persistence.load(TP.coordspath..tostring(mapID)..".lua")
		if (ValidTable(profile)) then
			TP.availableCoords = profile
		end
	end
	
	TP.RefreshWaypoints()
end
--**************************************************************************************************************************************
function TP.RefreshWaypoints()
	local unfoldList = {}
	for i,group in pairs(TP.GRPName) do
		GUI_DeleteGroup(TP.WinName,group[1])
	end
	
	if (ValidTable(TP.availableCoords)) then
		for i,coord in spairs(TP.availableCoords,function( coord,a,b ) return coord[a].name < coord[b].name end) do
			local matched = false
			local matchGroup = ""
			for _, group in pairs(TP.GRPName) do
				if (string.find(coord.name,group[1]) ~= nil) then
					if (group[4] == 1) then	
						unfoldList[group[1]] = true 
					end
					matched = true
					matchGroup = group[1]
				end
				if (matched) then
					break
				end
			end
			if (matched) then
				GUI_NewButton(TP.WinName,coord.name,"TPPort"..i,matchGroup)
			else
				unfoldList[TP.StdWPName] = true
				GUI_NewButton(TP.WinName,coord.name,"TPPort"..i,TP.StdWPName)
			end
		end
				
		for k,v in pairs(unfoldList) do
			if (v) then 
				GUI_UnFoldGroup	(TP.WinName,k) 
			end
		end		
	end
	
	GUI_SizeWindow(TP.WinName,Settings.Dev.TeleportWindow.width,Settings.Dev.TeleportWindow.height)
	GUI_RefreshWindow(TP.WinName)
end
--**************************************************************************************************************************************
function TP.Refresh()
	TP.LoadWaypoints()
end
--**************************************************************************************************************************************
function TP.WindowUpdate()	
	local WI = shallowcopy(Settings.Dev.TeleportWindow)
	local W = shallowcopy(GUI_GetWindowInfo(TP.WinName))
	
	local tablesEqual = deepcompare(WI,W,true)
	if (not tablesEqual) then
		Settings.Dev.TeleportWindow = W
	end
end
--**************************************************************************************************************************************
function TP.TargetPort()
	local target = Player:GetTarget()
	local value1, value2 = 0
	for k,v in pairs(TP.ModifierKeys) do
		if k == gClickName1 then 
			value1 = v 
		end
	end
	for k,v in pairs(TP.ShortcutKeys) do
		if k == gClickName2 then 
			value2 = v 
		end
	end
	
	if (gClickTeleport == "Target" and target ~= nil) then
		local tpos = target.pos
		if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
			(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
			(not (value1 == 0 and value2 == 0))) then
			GameHacks:TeleportToXYZ(tpos.x,tpos.y,tpos.z)
			Player:SetFacingSynced(Player.pos.h)
		end
	elseif (gClickTeleport == "Cursor") then
		if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
			(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
			(not (value1 == 0 and value2 == 0))) then
			GameHacks:TeleportToCursorPosition()
			Player:SetFacingSynced(Player.pos.h)
		end
	end
end
--**************************************************************************************************************************************
function TP.Move(event)
	local p = shallowcopy(Player.pos)

	local h = ConvertHeading(p.h)
	local dist = tonumber(gMoveDist)
	local theta_right = ConvertHeading((h - (math.pi/2)))%(2*math.pi)
	local theta_left = ConvertHeading((h + (math.pi/2)))%(2*math.pi)
	local theta_back = ConvertHeading((h - (math.pi)))%(2*math.pi)
	local newPos = {}
	
	if (event == "F") then newPos = GetPosFromDistanceHeading(p, dist, p.h)
	elseif (event == "B") then newPos = GetPosFromDistanceHeading(p, dist, theta_back)
	elseif (event == "R") then newPos = GetPosFromDistanceHeading(p, dist, theta_right)
	elseif (event == "L") then newPos = GetPosFromDistanceHeading(p, dist, theta_left)
	elseif (event == "U") then newPos = {x = p.x, y = p.y + dist, z = p.z}
	elseif (event == "D") then newPos = {x = p.x, y = p.y - dist, z = p.z}
	end
	
	GameHacks:TeleportToXYZ(newPos.x,newPos.y,newPos.z)
	Player:SetFacingSynced(p.h)
end
--**************************************************************************************************************************************
function TP.Quick(event)
	local p = shallowcopy(Player.pos)
	
	if (event == "Save1") then
		Settings.Dev.QuickSave1 = {x = p.x, y = p.y, z = p.z, h = p.h}
	elseif (event == "Save2") then 
		Settings.Dev.QuickSave2 = {x = p.x, y = p.y, z = p.z, h = p.h}
	elseif (event == "Load1") then
		local ql = Settings.Dev.QuickSave1
		GameHacks:TeleportToXYZ(tonumber(ql.x),tonumber(ql.y),tonumber(ql.z))
		Player:SetFacingSynced(ql.h)
	elseif (event == "Load2") then 
		local ql = Settings.Dev.QuickSave2
		GameHacks:TeleportToXYZ(tonumber(ql.x),tonumber(ql.y),tonumber(ql.z))
		Player:SetFacingSynced(ql.h)
	end
end
--**************************************************************************************************************************************
function TP.UpdateWaypointList()
	local mapID = Player.localmapid
	local profile = persistence.load(TP.coordspath..tostring(mapID)..".lua")
	local list = ""
	local firstEntry = ""
	if (ValidTable(profile)) then
		for i, coord in pairs(profile) do
			if list == "" then
				list = string.gsub(coord.name,",","")
				firstEntry = list
			else
				list = list..","..string.gsub(coord.name,",","")
			end
		end
		TP.availableCoords = profile
	end
	
	gRepPoint_listitems = list
	gRepPoint = firstEntry
end

function TP.WindowToggle(event)
	local window = string.gsub(event,"TPToggle","")
	
	if window == "Edit" then TP.UpdateWaypointList() end
	GUI_WindowVisible(TP.WinNames[window],not TP.Visible[window])
	TP.Visible[window] = not TP.Visible[window]
end

function TP.HandleButtons( Event, Button )
  
  if ( Event == "GUI.Item" ) then
		if (string.find(Button,"AutoListTP_") ~= nil) then
			local id = string.gsub(Button,"AutoListTP_","")
			local obj = TP.AutoList[tonumber(id)]
			outputTable(obj)
			if (obj and obj.POS) then
				Player:Stop()
				GameHacks:TeleportToXYZ(obj.POS.x,obj.POS.y,obj.POS.z)
				Player:SetFacingSynced(obj.POS.x,obj.POS.y,obj.POS.z)
			end
		elseif (string.sub(Button,1,8) == "TPToggle") then
			TP.WindowToggle(Button)
		elseif (string.find(Button,"TPMove") ~= nil) then
			TP.Move(string.gsub(Button,"TPMove",""))
		elseif (string.find(Button,"TPQuick") ~= nil) then
			TP.Quick(string.gsub(Button,"TPQuick",""))
		elseif (string.find(Button,"TPChangeWaypoint") ~= nil) then
			TP.ChangeWaypoint(string.gsub(Button,"TPChangeWaypoint",""))
		elseif (string.find(Button,"TPSave") ~= nil) then
			TP.SaveWaypoint(string.gsub(Button,"TPSave",""))
		elseif (string.find(Button,"TPPort") ~= nil) then
			TP.Port(string.gsub(Button,"TPPort",""))
		elseif (string.sub(Button,1,3) == "TP.") then
			ExecuteFunction(Button)
		end
	end
end

RegisterEventHandler("Module.Initalize",TP.ModuleInit)
RegisterEventHandler("Gameloop.Update", TP.OnUpdate)
RegisterEventHandler("GUI.Update",TP.GUIVarUpdate)
RegisterEventHandler("GUI.Item",TP.HandleButtons)

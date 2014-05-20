TP = { }
TP.coordspath = GetStartupPath()..[[\LuaMods\dev\Waypoint\]];
TP.WinNames = {
	Main = "Dev - TP",
	Save = "Teleporter Save",
	Replace = "Teleporter Replace/Rename/Delete",
	Info = "Info",
}
TP.WinName = TP.WinNames.Main

TP.WindowTick = 0
TP.ClickTPTick = 0
TP.UpdateWaypointTick = 0
TP.MapID = 0

TP.Visible = {
	Main = false,
	Save = false,
	Replace = false,
	Info = false,
}

--cPort is the actual coord list format
TP.cPort = {}
--cPortS is the names
TP.cPortS = {} 

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
TP.AutoGroups={[5]="Aetheryte",[7]="Object",[3]="NPC" }

function TP.Build()

	if (Settings.Teleporter.TeleportWindow == nil or Settings.Teleporter.TeleportWindow == {}) then 
		local windowInfo = {} 
		windowInfo.width = 380
		windowInfo.height = 520
		windowInfo.x = 500
		windowInfo.y = 40
		
		Settings.Teleporter.TeleportWindow = windowInfo
	end
	
	local WI = Settings.Teleporter.TeleportWindow

	if (Settings.Teleporter.gClickTeleport == nil) then
		Settings.Teleporter.gClickTeleport = "None"
	end
	if (Settings.Teleporter.gClickName1 == nil) then
		Settings.Teleporter.gClickName1 = "None"
	end
	if (Settings.Teleporter.gClickName2 == nil) then
		Settings.Teleporter.gClickName2 = "None"
	end
	if (Settings.Teleporter.gAutoSync == nil) then
		Settings.Teleporter.gAutoSync = "1"
	end
	if (Settings.Teleporter.gAutoRecord == nil) then
		Settings.Teleporter.gAutoRecord = "0"
	end
	if (Settings.Teleporter.gMoveDist == nil) then
		Settings.Teleporter.gMoveDist = "10"
	end
	
	--Let's create all our windows at once, instead of all throughout the code.
	local WinName = nil
	
	--Teleporter Replace/Rename/Delete Window
	WinName = TP.WinNames.Replace
	GUI_NewWindow	(WinName,WI.x,WI.y,WI.width,WI.height)
	
	GUI_NewComboBox (WinName,"Waypoint:","gRepPoint","Waypoint","")
	GUI_NewField	(WinName,"New Name:","gRepName","Waypoint")
	--GetTargetName
	GUI_NewButton	(WinName,"Get Target Name","TP.GetTargetName","Waypoint")
	RegisterEventHandler("TP.GetTargetName", TP.GetTargetName)
	
	GUI_NewButton	(WinName,"Delete Waypoint","TP.ChangeDelete")
	RegisterEventHandler("TP.ChangeDelete", TP.Change)
	GUI_NewButton	(WinName,"Rename Waypoint","TP.ChangeRename")
	RegisterEventHandler("TP.ChangeRename", TP.Change)
	GUI_NewButton	(WinName,"Replace to Target POS","TP.ChangeReplaceTPos")
	RegisterEventHandler("TP.ChangeReplaceTPos", TP.Change)
	GUI_NewButton	(WinName,"Replace to Player POS","TP.ChangeReplacePPos")
	RegisterEventHandler("TP.ChangeReplacePPos", TP.Change)
	
	GUI_UnFoldGroup	(WinName,"Waypoint")
	GUI_SizeWindow	(WinName,WI.width,200)
	GUI_WindowVisible(WinName,TP.Visible.Replace)	
	
	--Teleporter Save Window
	WinName = TP.WinNames.Save
	GUI_NewWindow	(WinName,WI.x,WI.y,WI.width,100)
	GUI_NewField	(WinName,"Name:","gSaveName","Save")
	GUI_NewButton	(WinName,"Get Target Name","TP.GetTargetName","Save")
	RegisterEventHandler("TP.GetTargetName", TP.GetTargetName)
	
	GUI_NewButton	(WinName,"Save Player POS","TP.save")
	RegisterEventHandler("TP.save", TP.Save)
	GUI_NewButton	(WinName,"Save Target POS","TP.saveTarget")
	RegisterEventHandler("TP.saveTarget", TP.Save)
	
	GUI_UnFoldGroup	(WinName,"Save")
	GUI_SizeWindow	(WinName,WI.width,130)
	GUI_WindowVisible(WinName,TP.Visible.Save)			
	
	--Teleporter Main Window
	WinName = TP.WinName
	GUI_NewWindow	(WinName,WI.x,WI.y,WI.width,WI.height)
    	GUI_NewField	(WinName,"Map - (id)","gMapName","Info")
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
	
	GUI_NewCheckbox	(WinName,"Auto-Sync","gAutoSync","Setting")
	GUI_NewCheckbox	(WinName,"Auto-Record","gAutoRecord","Setting")
	--GUI_NewCheckbox	(TP.WinName,"Use Mesh Positions","tpPrefMeshPos","Setting")
	GUI_NewComboBox	(WinName,"Port To:","gClickTeleport","Setting","None,Cursor,Target")
	GUI_NewComboBox	(WinName,"Port Buttons","gClickName1","Setting",teleKey1)
	GUI_NewComboBox	(WinName,"+","gClickName2","Setting",teleKey2)
	
	GUI_NewButton(WinName,"QS 1","TP.QuickSave1","Quick Save/Load")
	RegisterEventHandler("TP.QuickSave1", TP.CorMove)
	GUI_NewButton(WinName,"QL 1","TP.QuickLoad1","Quick Save/Load")
	RegisterEventHandler("TP.QuickLoad1", TP.CorMove)
	GUI_NewButton(WinName,"QS 2","TP.QuickSave2","Quick Save/Load")
	RegisterEventHandler("TP.QuickSave2", TP.CorMove)
	GUI_NewButton(WinName,"QL 2","TP.QuickLoad2","Quick Save/Load")
	RegisterEventHandler("TP.QuickLoad2", TP.CorMove)

	GUI_NewField	(WinName,"Distance","gMoveDist","Move")
	GUI_NewButton	(WinName,"Forward",	"TP.MoveF","Move")
	RegisterEventHandler("TP.MoveF", TP.CorMove)
	GUI_NewButton	(WinName,"Back",	"TP.MoveB","Move")
	RegisterEventHandler("TP.MoveB", TP.CorMove)
	GUI_NewButton	(WinName,"Right",	"TP.MoveR","Move")
	RegisterEventHandler("TP.MoveR", TP.CorMove)
	GUI_NewButton	(WinName,"Left",	"TP.MoveL","Move")
	RegisterEventHandler("TP.MoveL", TP.CorMove)
	GUI_NewButton	(WinName,"Down",	"TP.MoveD","Move")
	RegisterEventHandler("TP.MoveD", TP.CorMove)
	GUI_NewButton	(WinName,"Up",		"TP.MoveU","Move")
	RegisterEventHandler("TP.MoveU", TP.CorMove)
	
	GUI_NewButton(ml_global_information.MainWindow.Name,"Teleport","ToggleMain")
	RegisterEventHandler("ToggleMain", TP.WindowToggle)	
	
	GUI_NewButton(TP.WinName,"Refresh","TP.Refresh")
	RegisterEventHandler("TP.Refresh", TP.Refresh)
	
	GUI_NewButton(TP.WinName,"Replace / Rename / Delete", "ToggleReplace")
	RegisterEventHandler("ToggleReplace", TP.WindowToggle)
	
	GUI_NewButton(TP.WinName,"Save","ToggleSave")
	RegisterEventHandler("ToggleSave", TP.WindowToggle)
	
	GUI_SizeWindow(TP.WinName,WI.width,WI.height)
	GUI_WindowVisible(TP.WinName, TP.Visible.Main)
	
	gAutoSync = Settings.Teleporter.gAutoSync
	gAutoRecord = Settings.Teleporter.gAutoRecord	
	gClickTeleport = Settings.Teleporter.gClickTeleport
	gClickName1 = Settings.Teleporter.gClickName1
    	gClickName2 = Settings.Teleporter.gClickName2
	gMoveDist = Settings.Teleporter.gMoveDist
end

function TP.GUIVarUpdate(Event, NewVals, OldVals)
	
	for k,v in pairs(NewVals) do		
		if (
			k == "gAutoSync" or
			k == "gAutoRecord" or
			k == "gClickTeleport" or
			k == "gClickName1" or
			k == "gClickName2" or
			k == "gMoveDist") then
			Settings.Teleporter[tostring(k)] = v
		end  
	end

	GUI_RefreshWindow(ml_global_information.MainWindow.Name)
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

--[[
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
--]]

function TP.UpdateAutoAddGUI()
	GUI_DeleteGroup(TP.WinName,"Aetheryte")
	GUI_DeleteGroup(TP.WinName,"NPC")
	GUI_DeleteGroup(TP.WinName,"Object")

	local sort_func = function( t,a,b ) return t[a].NAME < t[b].NAME end

	for oid,obj in spairs(TP.AutoList,sort_func) do 
		GUI_NewButton(TP.WinName,	obj.NAME.." / "..tostring(obj.ID),	"AutoListTP_"..tostring(obj.ID),	TP.AutoGroups[obj.TYPE])
	end
end

function TP.DoAutoAdd()
    
    if (TP.AutoListMapId == 0 or TP.AutoListMapId ~= Player.localmapid) then
		TP.AutoListMapId = Player.localmapid
		TP.AutoList = persistence.load(TP.coordspath..TP.AutoListMapId.."_auto"..".lua")
		
		if (TP.AutoList == nil) then
			TP.AutoList = { }  
		else 
			TP.UpdateAutoAddGUI()
		end
    end
    
    if (tpAuto_Record == "1") then
		local el = EntityList("")
		local i,e = next(el)
		local dirty = false
		while (i~=nil and e ~= nil) do
			if (e.targetable and (e.type == 3 or e.type==5 or e.type==7) and e.uniqueid ~= 0 ) then
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
		if (dirty) then
			persistence.store(TP.coordspath..TP.AutoListMapId.."_auto"..".lua",TP.AutoList)
			TP.UpdateAutoAddGUI()
		end
    end
end


--**************************************************************************************************************************************
function TP.Change(dir)
	local ppos = Player.pos
	local target = Player:GetTarget()
	local WinName = "Teleporter Replace/Rename/Delete"
	local oldPoint = gRepPoint
	local newPoint = gRepName
	local saveString = ""
	
	if (dir == "TP.ChangeReplacePPos") then
		if (oldPoint == nil or oldPoint == "") then
			ml_error("No valid waypoint selected.")
			return
		end
		for _,v in pairs(TP.cPort) do
			if (v[1] == oldPoint) then
				v[2] = ppos.x
				v[3] = ppos.z
				v[4] = ppos.y
				v[5] = ppos.h
				break
			end
		end
	elseif (dir == "TP.ChangeReplaceTPos") then
		if (target ~= nil) then
			if (oldPoint == nil or oldPoint == "") then
				ml_error("No valid waypoint selected.")
				return
			end
			for _,v in pairs(TP.cPort) do
				if (v[1] == oldPoint) then
					v[2] = tpos.x
					v[3] = tpos.z
					v[4] = tpos.y
					v[5] = ppos.h
					break
				end
			end
		else
			ml_error("No valid target.")
			return
		end
	elseif (dir == "TP.ChangeRename") then
		if (newPoint == nil or newPoint == "") then
			ml_error("No valid save name entered.")
			return
		end
		for _,v in pairs(TP.cPort) do
			if (v[1] == oldPoint) then
				v[1] = newPoint
				break
			end
		end
	elseif (dir == "TP.ChangeDelete") then
		for _,v in pairs(TP.cPort) do
			if (v[1] == oldPoint) then
				v = nil
				break
			end
		end
	end
	
	for k,v in pairs(TP.cPort) do
		if (v[5] == nil) then v[5] = "0.01" end
		saveString = saveString..v[1]..":"..string.format("%f",v[2])..":"..string.format("%f",v[3])..":"..string.format("%f",v[4])..":"..string.format("%f",v[5]).."\n"
	end
	filewrite(TP.coordspath..TP.MapID..".lua",saveString)
	GUI_WindowVisible(WinName,false)
	TP.Refresh()
end
--**************************************************************************************************************************************
function TP.Save(dir)
	local ppos = Player.pos
	local target = Player:GetTarget()
	local saveString = ""
	local WinName = "Teleporter Save"
	local savePos = {}
	
	if (string.sub(dir,1,13) == "TP.save") then
	
		if (dir == "TP.saveTarget") then
			if (target ~= nil) then
				local tpos = target.pos
				savePos.x = tpos.x
				savePos.y = tpos.y
				savePos.z = tpos.z
			end
		else
			savePos.x = ppos.x
			savePos.y = ppos.y
			savePos.z = ppos.z
		end
		
		if (gSaveName ~= "") then
			for k,v in pairs(TP.cPort) do
				if (v[5] == nil) then v[5] = "0.01" end
				saveString = saveString..v[1]..":"..v[2]..":"..v[3]..":"..v[4]..":"..v[5].."\n"
			end
			
			saveString = saveString..gSaveName..":"..string.format("%.3f",savePos.x)..":"..string.format("%.3f",savePos.z)..":"..string.format("%.3f",savePos.y)..":"..string.format("%.2f",ppos.h).."\n"	
			filewrite(TP.coordspath..TP.MapID..".lua",saveString)
			GUI_WindowVisible(WinName,false)
			TP.Refresh()
		end
	end
end
--**************************************************************************************************************************************
function TP.GetTargetName()
	local target = Player:GetTarget()
	if (target ~= nil) then
		gSaveName = target.name
		ggRepName = target.name
	end
end
--**************************************************************************************************************************************
function TP.ReadMAP(cMID)
	local aelist = Player:GetAetheryteList()
	local b = " "
	if (aelist) then 
		for k,v in pairs(aelist) do				
			if(v.territory == tonumber(cMID)) then
				b = v.name
			end
		end		
	end
	return b
end
--**************************************************************************************************************************************
function TP.PortTO(event)
	local str = string.gsub(event,"PT_","")
	local SavedX,SavedY,SavedZ,SavedL 
	for k,v in pairs(TP.cPort) do
		if (v[1] == str) then
			SavedX = v[2]
			SavedY = v[3]
			SavedZ = v[4]
			SavedL = v[5]
		end
	end
	TP.gSaveName = str
	GameHacks:TeleportToXYZ(tonumber(SavedX),tonumber(SavedZ),tonumber(SavedY))
	Player:SetFacingSynced(tonumber(SavedL))
end
--**************************************************************************************************************************************
function TP.UpdateWaypoints()
	local mapID = Player.localmapid
	local cName = TP.ReadMAP(mapID)
	local unfoldList = {}
	TP.MapID = mapID
	gMapName = cName.." - ("..tostring(mapID)..")"
		
	for _,e in pairs(TP.GRPName) do
		GUI_DeleteGroup(TP.WinName,e[1])
	end
		
	TP.cPort = {}
	TP.cPortS = {}
		
	local profile = fileread(TP.coordspath..tostring(mapID)..".lua")
	if (profile) then
		for i,e in pairs(profile) do
			if (e ~= "") then
				table.insert (TP.cPort,i,TP.split(e,":"))
				table.insert (TP.cPortS,i,TP.cPort[i][1])
			end
		end
			
		table.sort(TP.cPortS)
		for i,e in pairs(TP.cPortS) do
			local matched = false
			-- k[1] is the name, v is the index
			for v,k in pairs(TP.GRPName) do
				matchLen = string.len(k[2])
				if (matchLen == 0) then matchLen = 3 end
				if (string.upper(string.sub(e,1,matchLen)) == k[2]) then
					GUI_NewButton(TP.WinName,k[3]..string.sub(e,matchLen+1),"PT_"..e,k[1])
					if (k[4] == 1) then	unfoldList[k[1]] = true end
					matched = true
				end
			end
			if (not matched) then 
				GUI_NewButton(TP.WinName,e,"PT_"..e,TP.StdWPName)
			end
			RegisterEventHandler("PT_"..e, TP.PortTO)	
		end
	end
	
	for k,v in pairs(unfoldList) do
		if (v) then 
			GUI_UnFoldGroup	(TP.WinName,k) 
		end
	end
	
	local p = Player.pos
	gPlayerPOS = string.format("%.2f",p.x).." | "..string.format("%.2f",p.z).." | "..string.format("%.2f",p.y).." | "..string.format("%.2f",p.h)
end
--**************************************************************************************************************************************
function TP.split(str, pat)
	local t = {}
	local fpat = "(.-)" .. pat
	local last_end = 1
	str = string.gsub(str,"\r","")
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(t,cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end
	return t
end
--**************************************************************************************************************************************
function TP.Refresh()  
	TP.DoAutoAdd()
	TP.UpdateWaypoints()
	GUI_SizeWindow(TP.WinName,Settings.Teleporter.TeleportWindow.width,Settings.Teleporter.TeleportWindow.height)
	GUI_RefreshWindow(TP.WinName)
end
--**************************************************************************************************************************************
function TP.WindowUpdate()	
	
	local WI = Settings.Teleporter.TeleportWindow
	local W = GUI_GetWindowInfo(TP.WinName)
	local WindowInfo = {}
	
	if (WI.width ~= W.width) then WindowInfo.width = W.width else WindowInfo.width = WI.width end
	if (WI.height ~= W.height) then WindowInfo.height = W.height else WindowInfo.height = WI.height	end
	if (WI.x ~= W.x) then WindowInfo.x = W.x else WindowInfo.x = WI.x end
	if (WI.y ~= W.y) then WindowInfo.y = W.y else WindowInfo.y = WI.y end

	if (WindowInfo ~= nil and WindowInfo ~= WI) then Settings.Teleporter.TeleportWindow = WindowInfo end
end
--**************************************************************************************************************************************
function TP.OnUpdateHandler( Event, ticks ) 	
	if (TimeSince(TP.ClickTPTick) > 50 ) then
		TP.ClickTPTick = ticks
		if ( gClickTeleport ~= "None") then
			TP.TargetPort()
		end
	end
	
	if (TimeSince(TP.WindowTick) > 10000) then
		TP.WindowTick = ticks
		TP.WindowUpdate()
	end
	
	if (TimeSince(TP.UpdateWaypointTick) > 5000) then
		TP.UpdateWaypointTick = ticks
		if (TP.MapID == 0 or TP.MapID ~= Player.localmapid) then
			TP.Refresh()
		end
	end
end
--**************************************************************************************************************************************
function TP.TargetPort()
	local target = Player:GetTarget()
	if (gClickTeleport ~= "None") then
	
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
				Player:SetFacingSynced(tpos.h)
			end
		else
			if ((value1 == 0 or MeshManager:IsKeyPressed(value1)) and 
				(value2 == 0 or MeshManager:IsKeyPressed(value2)) and
				(not (value1 == 0 and value2 == 0))) then
				GameHacks:TeleportToCursorPosition()
			end
		end
	end
end
--**************************************************************************************************************************************
function TP.CorMove(dir)
	local p = Player.pos
	local SavedX,SavedY,SavedZ,SavedH
	SavedX = p.x
	SavedY = p.y
	SavedZ = p.z
	SavedH = p.h
	local h = ConvertHeading(p.h)
	local dist = tonumber(gMoveDist)
	local theta_right = ConvertHeading((h - (math.pi/2)))%(2*math.pi)
	local theta_left = ConvertHeading((h + (math.pi/2)))%(2*math.pi)
	local theta_back = ConvertHeading((h - (math.pi)))%(2*math.pi)
	local newPos = {}
	
	if (string.sub(dir,1,7) == "TP.Move") then
		if (dir == "TP.MoveF") then newPos = GetPosFromDistanceHeading(p, dist, p.h)
		elseif (dir == "TP.MoveB") then newPos = GetPosFromDistanceHeading(p, dist, theta_back)
		elseif (dir == "TP.MoveR") then newPos = GetPosFromDistanceHeading(p, dist, theta_right)
		elseif (dir == "TP.MoveL") then newPos = GetPosFromDistanceHeading(p, dist, theta_left)
		elseif (dir == "TP.MoveU") then newPos = {x = SavedX, y = p.y + dist, z = SavedZ}
		elseif (dir == "TP.MoveD") then newPos = {x = SavedX, y = p.y - dist, z = SavedZ}
		end
        GameHacks:TeleportToXYZ(newPos.x,newPos.y,newPos.z)
        if (gAutoSync == "1") then
            Player:SetFacingSynced(p.h)
        else
            Player:SetFacing(p.h)
        end
	else
		if (dir == "TP.QuickSave1") then
			Settings.Teleporter.QuickSave1 = {p.x,p.z,p.y,p.h}
		elseif (dir == "TP.QuickSave2") then 
			Settings.Teleporter.QuickSave2 = {p.x,p.z,p.y,p.h}
		elseif (dir == "TP.QuickLoad1") then
			GameHacks:TeleportToXYZ(tonumber(Settings.Teleporter.QuickSave1[1]),tonumber(Settings.Teleporter.QuickSave1[3]),tonumber(Settings.Teleporter.QuickSave1[2]))
            if (gAutoSync == "1") then
                Player:SetFacingSynced(Settings.Teleporter.QuickSave1[4])
            else
                Player:SetFacing(Settings.Teleporter.QuickSave1[4])
            end
		elseif (dir == "TP.QuickLoad2") then 
			GameHacks:TeleportToXYZ(tonumber(Settings.Teleporter.QuickSave2[1]),tonumber(Settings.Teleporter.QuickSave2[3]),tonumber(Settings.Teleporter.QuickSave2[2]))
            if (gAutoSync == "1") then
                Player:SetFacingSynced(Settings.Teleporter.QuickSave2[4])
            else
                Player:SetFacing(Settings.Teleporter.QuickSave2[4])
            end
		end
	end
end
--**************************************************************************************************************************************
function TP.UpdateWaypointList()
	local list = ""
	if (TableSize(TP.cPortS) == 0) then
		local profile = fileread(TP.coordspath..mapID..".lua")
		if (profile) then
			for i,e in pairs(profile) do
				if (e ~= "") then
					table.insert (TP.cPort,i,TP.split(e,":"))
					table.insert (TP.cPortS,i,TP.cPort[i][1])
				end
			end	
			table.sort(TP.cPortS)
		end
	end
	
	if (TableSize(TP.cPortS) > 0) then
		for _,v in pairs(TP.cPortS) do
			list = list..","..tostring(v)
		end
	end
	gRepPoint_listitems = list
end
--**************************************************************************************************************************************
function TP.WindowToggle(event)
	local window = string.gsub(event,"Toggle","")
	
	if window == "Replace" then TP.UpdateWaypointList() end
	GUI_WindowVisible(TP.WinNames[window],not TP.Visible[window])
	TP.Visible[window] = not TP.Visible[window]
end

RegisterEventHandler("Module.Initalize",TP.Build)
RegisterEventHandler("Gameloop.Update", TP.OnUpdateHandler)
RegisterEventHandler("GUI.Update",TP.GUIVarUpdate)

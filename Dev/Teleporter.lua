TP = { }
TP.coordspath = GetStartupPath() .. [[\LuaMods\dev\Waypoint\]];
TP.WinName = "Dev - TP"
TP.lastticks = 0
TP.MapID = 0
TP.LoadID = 0
TP.visicheck = 1
TP.visicheckM = 0
TP.TGName = ""
TP.cPort = {}
TP.cPortS = {} 
TP.cSaveinf = 0
TP.cDeleteinf = 0
TP.cReplaceinf = 0
TP.cInfocheck = 0
TP.cRepID = 0
TP.cDelID = 0
TP.DelGRP = {}
TP.halfticks = 0
TP.isTraveling = false
TP.TravelingStopingDistance = 10.0
TP.key1 = {"NONE","Left Mouse","Right Mouse","Middle Mouse","BACKSPACE","TAB","ENTER","PAUSE","ESC","SPACEBAR","PAGE UP","PAGE DOWN","END","HOME","LEFT ARROW","UP ARROW","RIGHT ARROW","DOWN ARROW","PRINT","INS","DEL","0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","NUM 0","NUM 1","NUM 2","NUM 3","NUM 4","NUM 5","NUM 6","NUM 7","NUM 8","NUM 9","Separator","Subtract","Decimal","Divide","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","SCROLL LOCK","Left SHIFT","Right SHIFT","Left CONTROL","Right CONTROL","Left ALT","Right ALT"}
TP.key2 = {0,1,2,4,8,9,13,19,27,32,33,34,35,36,37,38,39,40,42,45,46,48,49,50,51,52,53,54,55,56,57,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,96,97,98,99,100,101,102,103,104,105,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,145,160,161,162,163,164,165}

TP.AutoList = { }
TP.LastAutoList = 0
TP.AutoListMapId = 0
TP.AutoGroups={[5]="Aetheryte",[7]="Object",[3]="NPC" }


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
  d(dest)
   
  local p,dist = NavigationManager:GetClosestPointOnMesh(dest)
  d("mesh distance" .. dist)
  if (tpPrefMeshPos == "0" or dist > 40) then
    dist = tonumber(tpDistance)
    if (dist == nil ) then dist = 0.0 end
    local dirV = { x=math.sin(dest.h)*dist,z = math.cos(dest.h)*dist }
    local pos = deepcopy(dest)
    pos.x = dest.x + dirV.x
    pos.z = dest.z + dirV.z
    d("calculated pos " .. tostring(pos))
    return pos
  else
    d("mesh pos " .. tostring(p))
    return p
  end
    
end

function TP.GUIItem( evnttype , event )
  
  local tokenlen = string.len("AutoListTP_")
  
  if (string.sub(event,1,tokenlen) == "AutoListTP_") then
    d("handling teleport event " ..event)
    local id = string.sub(event,tokenlen+1)
    d("extracted id " .. id)
    local obj = TP.AutoList[tonumber(id)]
    if (obj ~= nil) then
      
      if (TP.isTraveling) then 
        Player:Stop()
        TP.isTraveling = false
        return
      end
      
      d("found obj " .. obj.NAME .. ", telporting ....")
      if (tpMoveToMode == "1") then
        ml_debug( "Moving to ("..tostring(obj.POS.x)..","..tostring(obj.POS.y)..","..tostring(obj.POS.z)..")")	
        local PathSize = Player:MoveTo(tonumber(obj.POS.x),tonumber(obj.POS.y),tonumber(obj.POS.z),TP.TravelingStopingDistance, false,false)  
        if (PathSize == 0) then
          mt_error("ERROR: No route to target")
          Player:Stop()
          TP.isTraveling=false
        else
          TP.isTraveling=true
          ml_debug( "traveling to destination")	
        end
      else
        local dest = CalculateTargetPosition(obj.POS)
        GameHacks:TeleportToXYZ(dest.x,dest.y,dest.z)
        Player:SetFacingSynced(obj.POS.x,obj.POS.y,obj.POS.z)
      end
    end
  end
end

function TP.UpdateAutoAddGUI()
  GUI_DeleteGroup(TP.WinName,"Aetheryte")
  GUI_DeleteGroup(TP.WinName,"NPC")
  GUI_DeleteGroup(TP.WinName,"Object")
  d("Setting up new groups")
  
  local sort_func = function( t,a,b ) return t[a].NAME < t[b].NAME end
  
  for oid,obj in spairs(TP.AutoList,sort_func) do 
       --d("adding " .. obj.NAME)
       GUI_NewButton(TP.WinName,obj.NAME .. " / " .. tostring(obj.ID),"AutoListTP_" .. tostring(obj.ID),TP.AutoGroups[obj.TYPE])
  end
  
end

function TP.DoAutoAdd()
    
    if (TP.AutoListMapId == 0 or TP.AutoListMapId ~= Player.localmapid) then
      TP.AutoListMapId = Player.localmapid
      d("loading autolist from " ..TP.coordspath..TP.AutoListMapId.."_auto"..".lua")
      TP.AutoList = persistence.load(TP.coordspath..TP.AutoListMapId.."_auto"..".lua")
      d("Autolist loaded " .. tostring(TP.AutoList ~= nil))
      if (TP.AutoList == nil) then
        TP.AutoList = { }  
      else 
        TP.UpdateAutoAddGUI()
      end
      d("Autolist size " .. TableSize(TP.AutoList))
      
    end
    
    if (tpAuto_Record == "1") then
      local el = EntityList("")
      local i,e = next(el)
      local dirty = false
      while (i~=nil and e ~= nil) do
        if (e.targetable and (e.type == 3 or e.type==5 or e.type==7) and e.uniqueid ~= 0 ) then
          --d(e.id .. ":" .. e.name .. " at " .. e.pos.x .. ",".. e.pos.y .. "," ..e.pos.z .. " type=".. e.type )
          obj = { }
          obj.ID = e.uniqueid
          obj.CONTENTID = e.contentid
          obj.TYPE = e.type
          obj.POS = e.pos
          obj.NAME = e.name
          
          if (TP.AutoList[obj.ID] == nil) then
            d("adding " .. obj.NAME)
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


function TP.Build()

	if (Settings.Dev.check == nil) then
		Settings.Dev.WinInfX = 790
		Settings.Dev.WinInfY = 40
		Settings.Dev.WinInfW = 380
		Settings.Dev.WinInfH = 520
		Settings.Dev.check = true
	end
	GUI_NewWindow(TP.WinName,Settings.Dev.WinInfX,Settings.Dev.WinInfY,Settings.Dev.WinInfW,Settings.Dev.WinInfH)
    GUI_NewField(TP.WinName,"Map - (id)","mapNAME","Info")
    GUI_NewField(TP.WinName," X | Y | Z | H","tb_aPos","Info")
    GUI_UnFoldGroup(TP.WinName,"Info")
	
	local B1 = "NONE,"
	local B2 = ""
	for k,v in pairs(TP.key1) do
		if k > 84 then B1 = B1..v.."," end
		if k > 1 and k < 85 then B2 = B2..v.."," end
	end
	if (Settings.Dev.checkM == nil) then
		Settings.Dev.WinInfMX = 304
		Settings.Dev.WinInfMY = 50
		Settings.Dev.WinInfMW = 225
		Settings.Dev.WinInfMH = 265
		Settings.Dev.Click_ButtonNUM1 = 0
		Settings.Dev.Click_ButtonNUM2 = 4
		Settings.Dev.Distance = "10"
		Settings.Dev.Click_Teleport = "0"
		Settings.Dev.Click_Button1 = "Left CONTROL"
		Settings.Dev.Click_Button2 = "Middle Mouse"
		Settings.Dev.checkM = true
        Settings.Dev.Auto_Sync = "1"
	end
    
    if (Settings.Dev.Auto_Sync == nil) then
        Settings.Dev.Auto_Sync = "1"
    end
	
	if (Settings.Dev.Distance == nil) then
		Settings.Dev.Distance = "10"
	end
  
  if (Settings.Dev.Auto_Record == nil) then
    Settings.Dev.Auto_Record = "0"
  end
  
  if (Settings.Dev.tpDistance == nil) then
    Settings.Dev.tpDistance = "0.0"
  end
  
  if (Settings.Dev.tpMoveToMode == nil) then
    Settings.Dev.tpMoveToMode = "0"
  end
  
  if (Settings.Dev.tpPrefMeshPos == nil) then
    Settings.Dev.tpPrefMeshPos = "1"
  end
    
  
	--
  GUI_NewCheckbox(TP.WinName,"Auto-Sync","tpAuto_Sync","Setting")
	tpAuto_Sync = Settings.Dev.Auto_Sync
  GUI_NewCheckbox(TP.WinName,"Auto-Record","tpAuto_Record","Setting")
	tpAuto_Record = Settings.Dev.Auto_Record
  GUI_NewField(TP.WinName,"Distance","tpDistance","Setting")
	tpDistance = Settings.Dev.tpDistance
  GUI_NewCheckbox(TP.WinName,"Move To Mode","tpMoveToMode","Setting")
	tpMoveToMode = Settings.Dev.tpMoveToMode
  GUI_NewCheckbox(TP.WinName,"Use Mesh Positions","tpPrefMeshPos","Setting")
	tpPrefMeshPos = Settings.Dev.tpPrefMeshPos
	GUI_NewCheckbox(TP.WinName,"Port 2 Cursor","tpClick_Tele","Setting")
	tpClick_Tele = Settings.Dev.Click_Teleport
	GUI_NewComboBox(TP.WinName,"Port Buttons","tpClick_Button1","Setting",B1)
	tpClick_Button1 = Settings.Dev.Click_Button1
	GUI_NewComboBox(TP.WinName,"+","tpClick_Button2","Setting",B2)
    tpClick_Button2 = Settings.Dev.Click_Button2
	--
	GUI_NewButton(TP.WinName,"QS 1","TP.QuickSave1","Quick Save/Load")
	RegisterEventHandler("TP.QuickSave1", TP.CorMove)
	GUI_NewButton(TP.WinName,"QL 1","TP.QuickLoad1","Quick Save/Load")
	RegisterEventHandler("TP.QuickLoad1", TP.CorMove)
	GUI_NewButton(TP.WinName,"QS 2","TP.QuickSave2","Quick Save/Load")
	RegisterEventHandler("TP.QuickSave2", TP.CorMove)
	GUI_NewButton(TP.WinName,"QL 2","TP.QuickLoad2","Quick Save/Load")
	RegisterEventHandler("TP.QuickLoad2", TP.CorMove)
	--
	GUI_NewField(TP.WinName,"Distance","tpMove_Dist","Move")
	tpMove_Dist = Settings.Dev.Distance
	GUI_NewButton(TP.WinName,"Forward","TP.MoveF","Move")
	RegisterEventHandler("TP.MoveF", TP.CorMove)
	GUI_NewButton(TP.WinName,"Back","TP.MoveB","Move")
	RegisterEventHandler("TP.MoveB", TP.CorMove)
	GUI_NewButton(TP.WinName,"Right","TP.MoveR","Move")
	RegisterEventHandler("TP.MoveR", TP.CorMove)
	GUI_NewButton(TP.WinName,"Left","TP.MoveL","Move")
	RegisterEventHandler("TP.MoveL", TP.CorMove)
	GUI_NewButton(TP.WinName,"Down","TP.MoveD","Move")
	RegisterEventHandler("TP.MoveD", TP.CorMove)
	GUI_NewButton(TP.WinName,"Up","TP.MoveU","Move")
	RegisterEventHandler("TP.MoveU", TP.CorMove)
	
	GUI_NewButton(ml_global_information.MainWindow.Name,"Teleport","TP.StartTP")
	RegisterEventHandler("TP.StartTP", TP.StartTPs)	
	GUI_NewButton(TP.WinName,"Refresh","TP.Refresh")
	RegisterEventHandler("TP.Refresh", TP.Refreshing)
	GUI_NewButton(TP.WinName,"Replace / Rename / Delete","TP.Change_Open")
	RegisterEventHandler("TP.Change_Open", TP.Change)
	GUI_NewButton(TP.WinName,"Save","TP.saveOpen")
	RegisterEventHandler("TP.saveOpen", TP.Save)
	GUI_SizeWindow(TP.WinName,Settings.Dev.WinInfW,Settings.Dev.WinInfH)
	GUI_WindowVisible(TP.WinName, false)
end
--**************************************************************************************************************************************
function TP.StartTPs(dir)
	if (dir == "TP.StartTP") then
		if (TP.visicheck == 1) then
			GUI_WindowVisible(TP.WinName,false)
			TP.visicheck = 0
		else
			GUI_WindowVisible(TP.WinName,true)
			TP.visicheck = 1
		end	
		

	elseif (dir == "TP.StartTPM") then
		if (TP.visicheckM == 1) then
			GUI_WindowVisible(TP.Move_Winname,false)
			TP.visicheckM = 0
		else
			GUI_WindowVisible(TP.Move_Winname,true)
			TP.visicheckM = 1
		end
		
	end
	
	
	GUI_SizeWindow(TP.WinName,Settings.Dev.WinInfW,Settings.Dev.WinInfH)
end
--**************************************************************************************************************************************
function TP.Change(dir)
	local p = Player.pos
	local PG = Player:GetTarget()
	local Tcheck = 0
	local WinName = "Teleporter Replace/Rename/Delete"
	if (dir == "TP.Change_Open") then
		if (TP.cReplaceinf == 0) then
			TP.cReplaceinf = 1
			GUI_NewWindow(WinName,Settings.Dev.WinInfX,Settings.Dev.WinInfY,Settings.Dev.WinInfW,Settings.Dev.WinInfH)
			GUI_NewButton(WinName,"Delete Waypoint","TP.WPOiNTdelete")
			RegisterEventHandler("TP.WPOiNTdelete", TP.Change)
			GUI_NewButton(WinName,"Rename Waypoint","TP.WPOiNTrename")
			RegisterEventHandler("TP.WPOiNTrename", TP.Change)
			GUI_NewButton(WinName,"Replace to Target POS","TP.WPOiNTreplaceT")
			RegisterEventHandler("TP.WPOiNTreplaceT", TP.Change)
			GUI_NewButton(WinName,"Replace to Player POS","TP.WPOiNTreplaceP")
			RegisterEventHandler("TP.WPOiNTreplaceP", TP.Change)
			GUI_NewField(WinName,"Name:","repNAME","Waypoint Name")
			GUI_NewButton(WinName,"Get Target Name","TP.WTargetName","Waypoint Name")
			RegisterEventHandler("TP.WTargetName", TP.Change)
		end
			GUI_MoveWindow(WinName,Settings.Dev.WinInfX,Settings.Dev.WinInfY)
			GUI_WindowVisible("Save",false)	
			GUI_UnFoldGroup(WinName,"Waypoint Name")
			
			for i,e in pairs(TP.GRPName) do
				GUI_DeleteGroup(WinName,e[1])
				GUI_UnFoldGroup(WinName,e[1])
			end
			for i,e in pairs(TP.cPort) do
				bb = 0
				for v,k in pairs(TP.GRPName) do
					if (k[1] == TP.StdWPName) then cc = v end
					ll = string.len(k[2])
					if (ll == 0) then ll = 3 end
					if (string.upper(string.sub(e[1],1,ll)) == k[2]) then
						GUI_NewButton(WinName,e[1],"PTR_"..i,k[1])
						TP.DelGRP[v] = 1
						bb = 1
					end
				end
				if (bb == 0) then 
					GUI_NewButton(WinName,e[1],"PTR_"..i,TP.GRPName[cc][1])
					TP.DelGRP[cc] = 1
				end
				RegisterEventHandler("PTR_"..i, TP.Change)
			end
			TP.DelGroups(WinName)
			GUI_SizeWindow(WinName,Settings.Dev.WinInfW,Settings.Dev.WinInfH)
			GUI_WindowVisible(WinName,true)
			--------------------------------------------------------------------------------------------	
	elseif (string.sub(dir,1,15) == "TP.WPOiNT") then
		if (repNAME ~= nil or repNAME ~= "") then
			local saveK = ""
			local Tcheck = 0
			if (dir == "TP.WPOiNTreplaceP") then
				TP.cPort[tonumber(TP.cRepID)][2] = p.x
				TP.cPort[tonumber(TP.cRepID)][3] = p.z
				TP.cPort[tonumber(TP.cRepID)][4] = p.y
				TP.cPort[tonumber(TP.cRepID)][5] = p.h
			elseif (dir == "TP.WPOiNTreplaceT") then
			if (PG ~= nil) then
				TP.cPort[tonumber(TP.cRepID)][2] = PG.pos.x 
				TP.cPort[tonumber(TP.cRepID)][3] = PG.pos.z
				TP.cPort[tonumber(TP.cRepID)][4] = PG.pos.y
				TP.cPort[tonumber(TP.cRepID)][5] = p.h
			else
				Tcheck = 1
			end
			elseif (dir == "TP.WPOiNTrename") then
				TP.cPort[tonumber(TP.cRepID)][1] = tostring(repNAME)
			elseif (dir == "TP.WPOiNTdelete") then	
				table.remove(TP.cPort, tonumber(TP.cRepID))
			end
			if (Tcheck == 0) then
			for k,v in pairs(TP.cPort) do
				if (v[5] == nil) then v[5] = "0.01" end
				saveK = saveK..v[1]..":"..string.format("%f",v[2])..":"..string.format("%f",v[3])..":"..string.format("%f",v[4])..":"..string.format("%f",v[5]).."\n"
			end
				filewrite(TP.coordspath..TP.MapID..".lua",saveK)
				d("Teleport::Save Waypoint to -> "..TP.MapID..".lua")
				repNAME = ""	
				TP.MapID = 0
				GUI_WindowVisible(WinName,false)
			else
				if (TP.cInfocheck == 0) then 
					TP.cInfocheck = 1
					GUI_NewWindow("Info",Settings.Dev.WinInfX,Settings.Dev.WinInfY,Settings.Dev.WinInfW,55)
					GUI_NewButton("Info","NO TARGET SET!"," ")
					GUI_SizeWindow("Info",Settings.Dev.WinInfW,55)
				else
					GUI_WindowVisible("Info",true)
				end
				Tcheck = 0
			end
		end
	elseif (dir == "TP.WTargetName") then
		if (PG ~= nil) then
			repNAME = PG.name
		end
	else
		TP.cRepID = string.gsub(dir,"PTR_","")
		for i,e in pairs(TP.cPort) do
			if (i == tonumber(TP.cRepID)) then repNAME = e[1] end	
		end
		GUI_RefreshWindow(WinName)
		--TP.Change("TP.Change_Open")
	end	
    
    GUI_SizeWindow(TP.WinName,Settings.Dev.WinInfW,Settings.Dev.WinInfH)
end
--**************************************************************************************************************************************
function TP.Save(dir)
	local Pp = Player.pos
	local PG = Player:GetTarget()
	local saveK = ""
	local Tcheck = 0
	local WinName = "Teleporter Save"
	if (dir == "TP.saveOpen") then
		local WinY = Settings.Dev.WinInfY
		--GUI_MoveWindow(TP.WinName,Settings.Dev.WinInfX,Settings.Dev.WinInfY+130)
		--GUI_MoveWindow(WinName,Settings.Dev.WinInfX,WinY)
		if (TP.cSaveinf == 0) then
			TP.cSaveinf = 1
			GUI_NewWindow(WinName,Settings.Dev.WinInfX,WinY,0,0)
			GUI_NewField(WinName,"Waypoint Name:","cSaveName"," ")
			GUI_NewButton(WinName,"Get Target Name","TP.GetTargetName"," ")
			RegisterEventHandler("TP.GetTargetName", TP.Save)
			GUI_NewButton(WinName,"Save Player POS","TP.save")
			RegisterEventHandler("TP.save", TP.Save)
			GUI_NewButton(WinName,"Save Target POS","TP.saveTarget")
			RegisterEventHandler("TP.saveTarget", TP.Save)
		end
		GUI_UnFoldGroup(WinName," ")
		GUI_SizeWindow(WinName,Settings.Dev.WinInfW,130)
		GUI_WindowVisible(WinName,true)	
	elseif (string.sub(dir,1,13) == "TP.save") then
		if (dir == "TP.saveTarget") then
			if (PG  ~= nil) then	
				PsX = PG.pos.x
				PsY = PG.pos.y
				PsZ = PG.pos.z
			else
				Tcheck = 1
			end
		else
			PsX = Pp.x
			PsY = Pp.y
			PsZ = Pp.z
		end
		if (cSaveName ~= "") then
			if (Tcheck == 0) then
			for k,v in pairs(TP.cPort) do
				if (v[5] == nil) then v[5] = "0.01" end
				saveK = saveK..v[1]..":"..v[2]..":"..v[3]..":"..v[4]..":"..v[5].."\n"
			end
			saveK = saveK..cSaveName..":"..string.format("%f",PsX)..":"..string.format("%f",PsZ)..":"..string.format("%f",PsY)..":"..string.format("%f",Pp.h).."\n"	
				filewrite(TP.coordspath..TP.MapID..".lua",saveK)
				d("Teleport::Save Waypoint to -> "..TP.MapID..".lua")
				TP.MapID = 0
				GUI_WindowVisible(WinName,false)
			else
				if (TP.cInfocheck == 0) then 
					TP.cInfocheck = 1
					GUI_NewWindow("Info",Settings.Dev.WinInfX,Settings.Dev.WinInfY,Settings.Dev.WinInfW,55)
					GUI_NewButton("Info","NO TARGET SET!"," ")
					GUI_SizeWindow("Info",Settings.Dev.WinInfW,55)
				else
					GUI_WindowVisible("Info",true)
				end
				Tcheck = 0
			end	
		end
	elseif (dir == "TP.GetTargetName") then
		if (PG  ~= nil) then
			cSaveName = PG.name	
		end
	end
end
--**************************************************************************************************************************************
function TP.ReadMAP(cMID)
	local aelist = Player:GetAetheryteList()
	local b = " "
	--local saveK = ""
	if (aelist) then 
		for k,v in pairs(aelist) do
		--saveK=saveK..v.territory.."-"..v.name.."\n"				
			if(v.territory == tonumber(cMID)) then
				b = v.name
			end
		end	
		--d(filewrite(TP.coordspath.."MapID.inf",saveK))		
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
	TP.cSaveName = str
  if (TP.isTraveling) then 
    Player:Stop()
    TP.isTraveling = false
    return
  end
      
  if (tpMoveToMode == "1") then
    ml_debug( "Moving to ("..tostring(obj.POS.x)..","..tostring(obj.POS.y)..","..tostring(obj.POS.z)..")")	
    local PathSize = Player:MoveTo(tonumber(SavedX),tonumber(SavedZ),tonumber(SavedY),TP.TravelingStopingDistance, false,false)  
    if (PathSize == 0) then
      mt_error("ERROR: No route to target")
      Player:Stop()
      TP.isTraveling=false
    else
      TP.isTraveling=true
      ml_debug( "traveling to destination")	
    end
  else
    GameHacks:TeleportToXYZ(tonumber(SavedX),tonumber(SavedZ),tonumber(SavedY))
    Player:SetFacingSynced(tonumber(SavedL))
  end	
end
--**************************************************************************************************************************************
function TP.UpdateWaypoints()
  mapID = tostring(Player.localmapid)
  if (TP.MapID ~= mapID) then
		local cName = TP.ReadMAP(mapID)
		TP.MapID = mapID
		mapNAME = cName.." - ("..mapID..")"
		for i,e in pairs(TP.GRPName) do
			GUI_DeleteGroup(TP.WinName,e[1])
			if (e[4] == 1) then GUI_UnFoldGroup(TP.WinName,e[1]) else GUI_FoldGroup(TP.WinName,e[1]) end
		end
		TP.cPort = {}
		TP.cPortS = {}
		local profile = fileread(TP.coordspath..mapID..".lua")
		d("Teleport::Load Waypoint from -> "..TP.MapID..".lua")
		if (profile) then
			for i,e in pairs(profile) do
				if (e ~= "") then
					table.insert (TP.cPort,i,TP.split(e,":"))
					table.insert (TP.cPortS,i,TP.cPort[i][1])
				end
			end
			table.sort(TP.cPortS)
			for i,e in pairs(TP.cPortS) do
				bb = 0
				for v,k in pairs(TP.GRPName) do
					if (k[1] == TP.StdWPName) then cc = v end
					ll = string.len(k[2])
					if (ll == 0) then ll=3 end
					if (string.upper(string.sub(e,1,ll)) == k[2]) then
						GUI_NewButton(TP.WinName,k[3]..string.sub(e,ll+1),"PT_"..e,k[1])
						TP.DelGRP[v] = 1
						bb = 1
					end
				end
				if (bb == 0) then 
					GUI_NewButton(TP.WinName,e,"PT_"..e,TP.GRPName[cc][1])
					TP.DelGRP[cc] = 1
				end
				RegisterEventHandler("PT_"..e, TP.PortTO)	
			end
		end
		TP.DelGroups(TP.WinName)
	end
	local p = Player.pos
	tb_aPos = string.format("%f",p.x).." | "..string.format("%f",p.z).." | "..string.format("%f",p.y).." | "..string.format("%f",p.h)
end
--**************************************************************************************************************************************
function TP.DelGroups(WNAME)
	for i,e in pairs(TP.GRPName) do
		if (TP.DelGRP[i] == nil) then GUI_DeleteGroup(WNAME,e[1]) end
	end
	TP.DelGRP = {}
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
function TP.Refreshing()  
	TP.MapID = 0
end
--**************************************************************************************************************************************
function TP.WindowsHandler()
local W = GUI_GetWindowInfo(TP.WinName)
	if (Settings.Dev.WinInfY ~= W.y) then Settings.Dev.WinInfY = W.y end
	if (Settings.Dev.WinInfX ~= W.x) then Settings.Dev.WinInfX = W.x end
	if (Settings.Dev.WinInfW ~= W.width) then Settings.Dev.WinInfW = W.width end
	if (Settings.Dev.WinInfH ~= W.height) then Settings.Dev.WinInfH = W.height end
local WM = GUI_GetWindowInfo(TP.WinName)
	if (Settings.Dev.WinInfMY ~= WM.y) then Settings.Dev.WinInfMY = WM.y end
	if (Settings.Dev.WinInfMX ~= WM.x) then Settings.Dev.WinInfMX = WM.x end
	if (Settings.Dev.WinInfMW ~= WM.width) then Settings.Dev.WinInfMW = WM.width end
	if (Settings.Dev.WinInfMH ~= WM.height) then Settings.Dev.WinInfMH = WM.height end
	if (Settings.Dev.Distance ~= tpMove_Dist) then Settings.Dev.Distance = tpMove_Dist end
	if (Settings.Dev.Click_Teleport ~= tpClick_Tele) then Settings.Dev.Click_Teleport = tpClick_Tele end
	if (Settings.Dev.Click_Button1 ~= tpClick_Button1) then 
		Settings.Dev.Click_Button1 = tpClick_Button1 
		Settings.Dev.Click_ButtonNUM1 = TP.KeySelect(tpClick_Button1)
	end
	if (Settings.Dev.Click_Button2 ~= tpClick_Button2) then 
		Settings.Dev.Click_Button2 = tpClick_Button2 
		Settings.Dev.Click_ButtonNUM2 = TP.KeySelect(tpClick_Button2)
	end
    if (Settings.Dev.Auto_Sync ~= tpAuto_Sync) then
        Settings.Dev.Auto_Sync = tpAuto_Sync
    end
	 if (Settings.Dev.Auto_Record ~= tpAuto_Record ) then
        Settings.Dev.Auto_Record  = tpAuto_Record 
   end
	 if (Settings.Dev.tpDistance ~= tpDistance ) then
        Settings.Dev.tpDistance  = tpDistance 
   end
	 if ( Settings.Dev.tpMoveToMode ~= tpMoveToMode ) then
        Settings.Dev.tpMoveToMode  = tpMoveToMode 
   end
  
  
  
end

--**************************************************************************************************************************************
function TP.OnUpdateHandler( Event, ticks ) 	
	if ( ticks - TP.lastticks > 500 ) then
		TP.lastticks = ticks
		if ( tpClick_Tele == "1") then
			TP.TargetPort()
		end
		TP.halfticks = TP.halfticks + 0.5
		if (TP.halfticks == 1) then
			TP.WindowsHandler()
			TP.halfticks = 0
		end
		if (TP.LoadID == 2) then
			TP.UpdateWaypoints()
		else
			if (TP.LoadID <= 2) then
				TP.LoadID = TP.LoadID + 1
			end
		end	
	end
  if (TP.LastAutoList == 0) then
    TP.LastAutoList = ticks
  elseif (ticks - TP.LastAutoList > 2000) then
    TP.LastAutoList = ticks
    TP.DoAutoAdd()
  end
end

function TP.TargetPort()
	if (Settings.Dev.Click_ButtonNUM1 == 0) then
		if (MeshManager:IsKeyPressed(Settings.Dev.Click_ButtonNUM2)) then
			GameHacks:TeleportToCursorPosition()
		end
	elseif (Settings.Dev.Click_ButtonNUM2 == 0) then
		if (MeshManager:IsKeyPressed(Settings.Dev.Click_ButtonNUM1)) then
			GameHacks:TeleportToCursorPosition()
		end
	else
		if (MeshManager:IsKeyPressed(Settings.Dev.Click_ButtonNUM1) and MeshManager:IsKeyPressed(Settings.Dev.Click_ButtonNUM2)) then
			GameHacks:TeleportToCursorPosition()
		end
	end
end
--**************************************************************************************************************************************
function TP.CorMove(dir)
	d("test")
	local p = Player.pos
	local SavedX,SavedY,SavedZ,SavedH
	SavedX = p.x
	SavedY = p.y
	SavedZ = p.z
	SavedH = p.h
	local h = ConvertHeading(p.h)
	local dist = tonumber(tpMove_Dist)
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
        if (tpAuto_Sync == "1") then
            Player:SetFacingSynced(p.h)
        else
            Player:SetFacing(p.h)
        end
    
	else
		if (dir == "TP.QuickSave1") then
			Settings.Dev.QuickSave1 = {p.x,p.z,p.y,p.h}
		elseif (dir == "TP.QuickSave2") then 
			Settings.Dev.QuickSave2 = {p.x,p.z,p.y,p.h}
		elseif (dir == "TP.QuickLoad1") then
			GameHacks:TeleportToXYZ(tonumber(Settings.Dev.QuickSave1[1]),tonumber(Settings.Dev.QuickSave1[3]),tonumber(Settings.Dev.QuickSave1[2]))
            if (tpAuto_Sync == "1") then
                Player:SetFacingSynced(Settings.Dev.QuickSave1[4])
            else
                Player:SetFacing(Settings.Dev.QuickSave1[4])
            end
		elseif (dir == "TP.QuickLoad2") then 
			GameHacks:TeleportToXYZ(tonumber(Settings.Dev.QuickSave2[1]),tonumber(Settings.Dev.QuickSave2[3]),tonumber(Settings.Dev.QuickSave2[2]))
            if (tpAuto_Sync == "1") then
                Player:SetFacingSynced(Settings.Dev.QuickSave2[4])
            else
                Player:SetFacing(Settings.Dev.QuickSave2[4])
            end
		end
	end
end
--**************************************************************************************************************************************
function TP.KeySelect(sKEY)
	for k,v in pairs(TP.key1) do
		if (v == sKEY) then
			return TP.key2[k]
		end
	end
end	



RegisterEventHandler("Module.Initalize",TP.Build)
RegisterEventHandler("Gameloop.Update", TP.OnUpdateHandler)
RegisterEventHandler("GUI.Item",TP.GUIItem)


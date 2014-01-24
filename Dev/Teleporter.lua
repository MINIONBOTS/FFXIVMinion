Teleport = { }
Teleport.coordspath = GetStartupPath() .. [[\LuaMods\dev\Waypoint\]];
Teleport.WinName = "Dev - TP"
Teleport.lastticks = 0
Teleport.MapID = 0
Teleport.LoadID = 0
Teleport.visicheck = 1
Teleport.visicheckM = 0
Teleport.TGName = ""
Teleport.cPort = {}
Teleport.cPortS = {} 
Teleport.cSaveinf = 0
Teleport.cDeleteinf = 0
Teleport.cReplaceinf = 0
Teleport.cInfocheck = 0
Teleport.cRepID = 0
Teleport.cDelID = 0
Teleport.DelGRP = {}
Teleport.halfticks = 0
Teleport.key1 = {"NONE","Left Mouse","Right Mouse","Middle Mouse","BACKSPACE","TAB","ENTER","PAUSE","ESC","SPACEBAR","PAGE UP","PAGE DOWN","END","HOME","LEFT ARROW","UP ARROW","RIGHT ARROW","DOWN ARROW","PRINT","INS","DEL","0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","NUM 0","NUM 1","NUM 2","NUM 3","NUM 4","NUM 5","NUM 6","NUM 7","NUM 8","NUM 9","Separator","Subtract","Decimal","Divide","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","SCROLL LOCK","Left SHIFT","Right SHIFT","Left CONTROL","Right CONTROL","Left ALT","Right ALT"}
Teleport.key2 = {0,1,2,4,8,9,13,19,27,32,33,34,35,36,37,38,39,40,42,45,46,48,49,50,51,52,53,54,55,56,57,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,96,97,98,99,100,101,102,103,104,105,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,145,160,161,162,163,164,165}

Teleport.AutoList = { }
Teleport.LastAutoList = 0
Teleport.AutoListMapId = 0
Teleport.AutoGroups={[5]="Aetheryte",[7]="Object",[3]="NPC" }


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
  
  local pos = deepcopy(dest)
  d(dest)
  local dist = tonumber(tpDistance)
  if (dist == nil ) then dist = 0.0 end
  
  local dirV = { x=math.sin(dest.h)*dist,z = math.cos(dest.h)*dist }
  pos.x = dest.x + dirV.x
  pos.z = dest.z + dirV.z
  d(pos)
  return pos
end

function Teleport.GUIItem( evnttype , event )
  
  local tokenlen = string.len("AutoListTP_")
  
  if (string.sub(event,1,tokenlen) == "AutoListTP_") then
    d("handling teleport event " ..event)
    local id = string.sub(event,tokenlen+1)
    d("extracted id " .. id)
    local obj = Teleport.AutoList[tonumber(id)]
    if (obj ~= nil) then
      d("found obj " .. obj.NAME .. ", telporting ....")
      local dest = CalculateTargetPosition(obj.POS)
      GameHacks:TeleportToXYZ(dest.x,dest.y,dest.z)
      Player:SetFacingSynced(obj.POS.x,obj.POS.y,obj.POS.z)
    end
  end
end

function Teleport.UpdateAutoAddGUI()
  GUI_DeleteGroup(Teleport.WinName,"Aetheryte")
  GUI_DeleteGroup(Teleport.WinName,"NPC")
  GUI_DeleteGroup(Teleport.WinName,"Object")
  d("Setting up new groups")
  
  local sort_func = function( t,a,b ) return t[a].NAME < t[b].NAME end
  
  for oid,obj in spairs(Teleport.AutoList,sort_func) do 
       --d("adding " .. obj.NAME)
       GUI_NewButton(Teleport.WinName,obj.NAME .. " / " .. tostring(obj.ID),"AutoListTP_" .. tostring(obj.ID),Teleport.AutoGroups[obj.TYPE])
  end
end

function Teleport.DoAutoAdd()
    
    if (Teleport.AutoListMapId == 0 or Teleport.AutoListMapId ~= Player.localmapid) then
      Teleport.AutoListMapId = Player.localmapid
      d("loading autolist from " ..Teleport.coordspath..Teleport.AutoListMapId.."_auto"..".lua")
      Teleport.AutoList = persistence.load(Teleport.coordspath..Teleport.AutoListMapId.."_auto"..".lua")
      d("Autolist loaded " .. tostring(Teleport.AutoList ~= nil))
      if (Teleport.AutoList == nil) then
        Teleport.AutoList = { }  
      else 
        Teleport.UpdateAutoAddGUI()
      end
      d("Autolist size " .. TableSize(Teleport.AutoList))
      
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
          
          if (Teleport.AutoList[obj.ID] == nil) then
            d("adding " .. obj.NAME)
            Teleport.AutoList[obj.ID] = obj
            dirty = true
          end
        end
        i,e = next(el,i)  
      end
      if (dirty) then
        persistence.store(Teleport.coordspath..Teleport.AutoListMapId.."_auto"..".lua",Teleport.AutoList)
        Teleport.UpdateAutoAddGUI()
      end
    end
end


function Teleport.Build()

	if (Settings.Dev.check == nil) then
		Settings.Dev.WinInfX = 790
		Settings.Dev.WinInfY = 40
		Settings.Dev.WinInfW = 380
		Settings.Dev.WinInfH = 520
		Settings.Dev.check = true
	end
	GUI_NewWindow(Teleport.WinName,Settings.Dev.WinInfX,Settings.Dev.WinInfY,Settings.Dev.WinInfW,Settings.Dev.WinInfH)
    GUI_NewField(Teleport.WinName,"Map - (id)","mapNAME","Info")
    GUI_NewField(Teleport.WinName," X | Y | Z | H","tb_aPos","Info")
    GUI_UnFoldGroup(Teleport.WinName,"Info")
	
	local B1 = "NONE,"
	local B2 = ""
	for k,v in pairs(Teleport.key1) do
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
  
	--
  GUI_NewCheckbox(Teleport.WinName,"Auto-Sync","tpAuto_Sync","Setting")
	tpAuto_Sync = Settings.Dev.Auto_Sync
  GUI_NewCheckbox(Teleport.WinName,"Auto-Record","tpAuto_Record","Setting")
	tpAuto_Record = Settings.Dev.Auto_Record
  GUI_NewField(Teleport.WinName,"Distance","tpDistance","Setting")
	tpDistance = Settings.Dev.tpDistance
	GUI_NewCheckbox(Teleport.WinName,"Port 2 Cursor","tpClick_Tele","Setting")
	tpClick_Tele = Settings.Dev.Click_Teleport
	GUI_NewComboBox(Teleport.WinName,"Port Buttons","tpClick_Button1","Setting",B1)
	tpClick_Button1 = Settings.Dev.Click_Button1
	GUI_NewComboBox(Teleport.WinName,"+","tpClick_Button2","Setting",B2)
    tpClick_Button2 = Settings.Dev.Click_Button2
	--
	GUI_NewButton(Teleport.WinName,"QS 1","Teleport.QuickSave1","Quick Save/Load")
	RegisterEventHandler("Teleport.QuickSave1", Teleport.CorMove)
	GUI_NewButton(Teleport.WinName,"QL 1","Teleport.QuickLoad1","Quick Save/Load")
	RegisterEventHandler("Teleport.QuickLoad1", Teleport.CorMove)
	GUI_NewButton(Teleport.WinName,"QS 2","Teleport.QuickSave2","Quick Save/Load")
	RegisterEventHandler("Teleport.QuickSave2", Teleport.CorMove)
	GUI_NewButton(Teleport.WinName,"QL 2","Teleport.QuickLoad2","Quick Save/Load")
	RegisterEventHandler("Teleport.QuickLoad2", Teleport.CorMove)
	--
	GUI_NewField(Teleport.WinName,"Distance","tpMove_Dist","Move")
	tpMove_Dist = Settings.Dev.Distance
	GUI_NewButton(Teleport.WinName,"Forward","Teleport.MoveF","Move")
	RegisterEventHandler("Teleport.MoveF", Teleport.CorMove)
	GUI_NewButton(Teleport.WinName,"Back","Teleport.MoveB","Move")
	RegisterEventHandler("Teleport.MoveB", Teleport.CorMove)
	GUI_NewButton(Teleport.WinName,"Right","Teleport.MoveR","Move")
	RegisterEventHandler("Teleport.MoveR", Teleport.CorMove)
	GUI_NewButton(Teleport.WinName,"Left","Teleport.MoveL","Move")
	RegisterEventHandler("Teleport.MoveL", Teleport.CorMove)
	GUI_NewButton(Teleport.WinName,"Down","Teleport.MoveD","Move")
	RegisterEventHandler("Teleport.MoveD", Teleport.CorMove)
	GUI_NewButton(Teleport.WinName,"Up","Teleport.MoveU","Move")
	RegisterEventHandler("Teleport.MoveU", Teleport.CorMove)
	
	GUI_NewButton(ml_global_information.MainWindow.Name,"Teleport","Teleport.StartTP")
	RegisterEventHandler("Teleport.StartTP", Teleport.StartTPs)	
	GUI_NewButton(Teleport.WinName,"Refresh","Teleport.Refresh")
	RegisterEventHandler("Teleport.Refresh", Teleport.Refreshing)
	GUI_NewButton(Teleport.WinName,"Replace / Rename / Delete","Teleport.Change_Open")
	RegisterEventHandler("Teleport.Change_Open", Teleport.Change)
	GUI_NewButton(Teleport.WinName,"Save","Teleport.saveOpen")
	RegisterEventHandler("Teleport.saveOpen", Teleport.Save)
	GUI_SizeWindow(Teleport.WinName,Settings.Dev.WinInfW,Settings.Dev.WinInfH)
end
--**************************************************************************************************************************************
function Teleport.StartTPs(dir)
	if (dir == "Teleport.StartTP") then
		if (Teleport.visicheck == 1) then
			GUI_WindowVisible(Teleport.WinName,false)
			Teleport.visicheck = 0
		else
			GUI_WindowVisible(Teleport.WinName,true)
			Teleport.visicheck = 1
		end	
		

	elseif (dir == "Teleport.StartTPM") then
		if (Teleport.visicheckM == 1) then
			GUI_WindowVisible(Teleport.Move_Winname,false)
			Teleport.visicheckM = 0
		else
			GUI_WindowVisible(Teleport.Move_Winname,true)
			Teleport.visicheckM = 1
		end
		
	end
	
	
	GUI_SizeWindow(Teleport.WinName,Settings.Dev.WinInfW,Settings.Dev.WinInfH)
end
--**************************************************************************************************************************************
function Teleport.Change(dir)
	local p = Player.pos
	local PG = Player:GetTarget()
	local Tcheck = 0
	local WinName = "Teleporter Replace/Rename/Delete"
	if (dir == "Teleport.Change_Open") then
		if (Teleport.cReplaceinf == 0) then
			Teleport.cReplaceinf = 1
			GUI_NewWindow(WinName,Settings.Dev.WinInfX,Settings.Dev.WinInfY,Settings.Dev.WinInfW,Settings.Dev.WinInfH)
			GUI_NewButton(WinName,"Delete Waypoint","Teleport.WPOiNTdelete")
			RegisterEventHandler("Teleport.WPOiNTdelete", Teleport.Change)
			GUI_NewButton(WinName,"Rename Waypoint","Teleport.WPOiNTrename")
			RegisterEventHandler("Teleport.WPOiNTrename", Teleport.Change)
			GUI_NewButton(WinName,"Replace to Target POS","Teleport.WPOiNTreplaceT")
			RegisterEventHandler("Teleport.WPOiNTreplaceT", Teleport.Change)
			GUI_NewButton(WinName,"Replace to Player POS","Teleport.WPOiNTreplaceP")
			RegisterEventHandler("Teleport.WPOiNTreplaceP", Teleport.Change)
			GUI_NewField(WinName,"Name:","repNAME","Waypoint Name")
			GUI_NewButton(WinName,"Get Target Name","Teleport.WTargetName","Waypoint Name")
			RegisterEventHandler("Teleport.WTargetName", Teleport.Change)
		end
			GUI_MoveWindow(WinName,Settings.Dev.WinInfX,Settings.Dev.WinInfY)
			GUI_WindowVisible("Save",false)	
			GUI_UnFoldGroup(WinName,"Waypoint Name")
			
			for i,e in pairs(Teleport.GRPName) do
				GUI_DeleteGroup(WinName,e[1])
				GUI_UnFoldGroup(WinName,e[1])
			end
			for i,e in pairs(Teleport.cPort) do
				bb = 0
				for v,k in pairs(Teleport.GRPName) do
					if (k[1] == Teleport.StdWPName) then cc = v end
					ll = string.len(k[2])
					if (ll == 0) then ll = 3 end
					if (string.upper(string.sub(e[1],1,ll)) == k[2]) then
						GUI_NewButton(WinName,e[1],"PTR_"..i,k[1])
						Teleport.DelGRP[v] = 1
						bb = 1
					end
				end
				if (bb == 0) then 
					GUI_NewButton(WinName,e[1],"PTR_"..i,Teleport.GRPName[cc][1])
					Teleport.DelGRP[cc] = 1
				end
				RegisterEventHandler("PTR_"..i, Teleport.Change)
			end
			Teleport.DelGroups(WinName)
			GUI_SizeWindow(WinName,Settings.Dev.WinInfW,Settings.Dev.WinInfH)
			GUI_WindowVisible(WinName,true)
			--------------------------------------------------------------------------------------------	
	elseif (string.sub(dir,1,15) == "Teleport.WPOiNT") then
		if (repNAME ~= nil or repNAME ~= "") then
			local saveK = ""
			local Tcheck = 0
			if (dir == "Teleport.WPOiNTreplaceP") then
				Teleport.cPort[tonumber(Teleport.cRepID)][2] = p.x
				Teleport.cPort[tonumber(Teleport.cRepID)][3] = p.z
				Teleport.cPort[tonumber(Teleport.cRepID)][4] = p.y
				Teleport.cPort[tonumber(Teleport.cRepID)][5] = p.h
			elseif (dir == "Teleport.WPOiNTreplaceT") then
			if (PG ~= nil) then
				Teleport.cPort[tonumber(Teleport.cRepID)][2] = PG.pos.x 
				Teleport.cPort[tonumber(Teleport.cRepID)][3] = PG.pos.z
				Teleport.cPort[tonumber(Teleport.cRepID)][4] = PG.pos.y
				Teleport.cPort[tonumber(Teleport.cRepID)][5] = p.h
			else
				Tcheck = 1
			end
			elseif (dir == "Teleport.WPOiNTrename") then
				Teleport.cPort[tonumber(Teleport.cRepID)][1] = tostring(repNAME)
			elseif (dir == "Teleport.WPOiNTdelete") then	
				table.remove(Teleport.cPort, tonumber(Teleport.cRepID))
			end
			if (Tcheck == 0) then
			for k,v in pairs(Teleport.cPort) do
				if (v[5] == nil) then v[5] = "0.01" end
				saveK = saveK..v[1]..":"..string.format("%f",v[2])..":"..string.format("%f",v[3])..":"..string.format("%f",v[4])..":"..string.format("%f",v[5]).."\n"
			end
				filewrite(Teleport.coordspath..Teleport.MapID..".lua",saveK)
				d("Teleport::Save Waypoint to -> "..Teleport.MapID..".lua")
				repNAME = ""	
				Teleport.MapID = 0
				GUI_WindowVisible(WinName,false)
			else
				if (Teleport.cInfocheck == 0) then 
					Teleport.cInfocheck = 1
					GUI_NewWindow("Info",Settings.Dev.WinInfX,Settings.Dev.WinInfY,Settings.Dev.WinInfW,55)
					GUI_NewButton("Info","NO TARGET SET!"," ")
					GUI_SizeWindow("Info",Settings.Dev.WinInfW,55)
				else
					GUI_WindowVisible("Info",true)
				end
				Tcheck = 0
			end
		end
	elseif (dir == "Teleport.WTargetName") then
		if (PG ~= nil) then
			repNAME = PG.name
		end
	else
		Teleport.cRepID = string.gsub(dir,"PTR_","")
		for i,e in pairs(Teleport.cPort) do
			if (i == tonumber(Teleport.cRepID)) then repNAME = e[1] end	
		end
		GUI_RefreshWindow(WinName)
		--Teleport.Change("Teleport.Change_Open")
	end	
end
--**************************************************************************************************************************************
function Teleport.Save(dir)
	local Pp = Player.pos
	local PG = Player:GetTarget()
	local saveK = ""
	local Tcheck = 0
	local WinName = "Teleporter Save"
	if (dir == "Teleport.saveOpen") then
		local WinY = Settings.Dev.WinInfY
		--GUI_MoveWindow(Teleport.WinName,Settings.Dev.WinInfX,Settings.Dev.WinInfY+130)
		--GUI_MoveWindow(WinName,Settings.Dev.WinInfX,WinY)
		if (Teleport.cSaveinf == 0) then
			Teleport.cSaveinf = 1
			GUI_NewWindow(WinName,Settings.Dev.WinInfX,WinY,0,0)
			GUI_NewField(WinName,"Waypoint Name:","cSaveName"," ")
			GUI_NewButton(WinName,"Get Target Name","Teleport.GetTargetName"," ")
			RegisterEventHandler("Teleport.GetTargetName", Teleport.Save)
			GUI_NewButton(WinName,"Save Player POS","Teleport.save")
			RegisterEventHandler("Teleport.save", Teleport.Save)
			GUI_NewButton(WinName,"Save Target POS","Teleport.saveTarget")
			RegisterEventHandler("Teleport.saveTarget", Teleport.Save)
		end
		GUI_UnFoldGroup(WinName," ")
		GUI_SizeWindow(WinName,Settings.Dev.WinInfW,130)
		GUI_WindowVisible(WinName,true)	
	elseif (string.sub(dir,1,13) == "Teleport.save") then
		if (dir == "Teleport.saveTarget") then
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
			for k,v in pairs(Teleport.cPort) do
				if (v[5] == nil) then v[5] = "0.01" end
				saveK = saveK..v[1]..":"..v[2]..":"..v[3]..":"..v[4]..":"..v[5].."\n"
			end
			saveK = saveK..cSaveName..":"..string.format("%f",PsX)..":"..string.format("%f",PsZ)..":"..string.format("%f",PsY)..":"..string.format("%f",Pp.h).."\n"	
				filewrite(Teleport.coordspath..Teleport.MapID..".lua",saveK)
				d("Teleport::Save Waypoint to -> "..Teleport.MapID..".lua")
				Teleport.MapID = 0
				GUI_WindowVisible(WinName,false)
			else
				if (Teleport.cInfocheck == 0) then 
					Teleport.cInfocheck = 1
					GUI_NewWindow("Info",Settings.Dev.WinInfX,Settings.Dev.WinInfY,Settings.Dev.WinInfW,55)
					GUI_NewButton("Info","NO TARGET SET!"," ")
					GUI_SizeWindow("Info",Settings.Dev.WinInfW,55)
				else
					GUI_WindowVisible("Info",true)
				end
				Tcheck = 0
			end	
		end
	elseif (dir == "Teleport.GetTargetName") then
		if (PG  ~= nil) then
			cSaveName = PG.name	
		end
	end
end
--**************************************************************************************************************************************
function Teleport.ReadMAP(cMID)
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
		--d(filewrite(Teleport.coordspath.."MapID.inf",saveK))		
	end
	return b
end
--**************************************************************************************************************************************
function Teleport.PortTO(event)
	local str = string.gsub(event,"PT_","")
	local SavedX,SavedY,SavedZ,SavedL 
	for k,v in pairs(Teleport.cPort) do
		if (v[1] == str) then
			SavedX = v[2]
			SavedY = v[3]
			SavedZ = v[4]
			SavedL = v[5]
		end
	end
	Teleport.cSaveName = str
	GameHacks:TeleportToXYZ(tonumber(SavedX),tonumber(SavedZ),tonumber(SavedY))
	Player:SetFacingSynced(tonumber(SavedL))
end
--**************************************************************************************************************************************
function Teleport.UpdateWaypoints()
  mapID = tostring(Player.localmapid)
  if (Teleport.MapID ~= mapID) then
		local cName = Teleport.ReadMAP(mapID)
		Teleport.MapID = mapID
		mapNAME = cName.." - ("..mapID..")"
		for i,e in pairs(Teleport.GRPName) do
			GUI_DeleteGroup(Teleport.WinName,e[1])
			if (e[4] == 1) then GUI_UnFoldGroup(Teleport.WinName,e[1]) else GUI_FoldGroup(Teleport.WinName,e[1]) end
		end
		Teleport.cPort = {}
		Teleport.cPortS = {}
		local profile = fileread(Teleport.coordspath..mapID..".lua")
		d("Teleport::Load Waypoint from -> "..Teleport.MapID..".lua")
		if (profile) then
			for i,e in pairs(profile) do
				if (e ~= "") then
					table.insert (Teleport.cPort,i,Teleport.split(e,":"))
					table.insert (Teleport.cPortS,i,Teleport.cPort[i][1])
				end
			end
			table.sort(Teleport.cPortS)
			for i,e in pairs(Teleport.cPortS) do
				bb = 0
				for v,k in pairs(Teleport.GRPName) do
					if (k[1] == Teleport.StdWPName) then cc = v end
					ll = string.len(k[2])
					if (ll == 0) then ll=3 end
					if (string.upper(string.sub(e,1,ll)) == k[2]) then
						GUI_NewButton(Teleport.WinName,k[3]..string.sub(e,ll+1),"PT_"..e,k[1])
						Teleport.DelGRP[v] = 1
						bb = 1
					end
				end
				if (bb == 0) then 
					GUI_NewButton(Teleport.WinName,e,"PT_"..e,Teleport.GRPName[cc][1])
					Teleport.DelGRP[cc] = 1
				end
				RegisterEventHandler("PT_"..e, Teleport.PortTO)	
			end
		end
		Teleport.DelGroups(Teleport.WinName)
	end
	local p = Player.pos
	tb_aPos = string.format("%f",p.x).." | "..string.format("%f",p.z).." | "..string.format("%f",p.y).." | "..string.format("%f",p.h)
end
--**************************************************************************************************************************************
function Teleport.DelGroups(WNAME)
	for i,e in pairs(Teleport.GRPName) do
		if (Teleport.DelGRP[i] == nil) then GUI_DeleteGroup(WNAME,e[1]) end
	end
	Teleport.DelGRP = {}
end
--**************************************************************************************************************************************
function Teleport.split(str, pat)
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
function Teleport.Refreshing()  
	Teleport.MapID = 0
end
--**************************************************************************************************************************************
function Teleport.WindowsHandler()
local W = GUI_GetWindowInfo(Teleport.WinName)
	if (Settings.Dev.WinInfY ~= W.y) then Settings.Dev.WinInfY = W.y end
	if (Settings.Dev.WinInfX ~= W.x) then Settings.Dev.WinInfX = W.x end
	if (Settings.Dev.WinInfW ~= W.width) then Settings.Dev.WinInfW = W.width end
	if (Settings.Dev.WinInfH ~= W.height) then Settings.Dev.WinInfH = W.height end
local WM = GUI_GetWindowInfo(Teleport.WinName)
	if (Settings.Dev.WinInfMY ~= WM.y) then Settings.Dev.WinInfMY = WM.y end
	if (Settings.Dev.WinInfMX ~= WM.x) then Settings.Dev.WinInfMX = WM.x end
	if (Settings.Dev.WinInfMW ~= WM.width) then Settings.Dev.WinInfMW = WM.width end
	if (Settings.Dev.WinInfMH ~= WM.height) then Settings.Dev.WinInfMH = WM.height end
	if (Settings.Dev.Distance ~= tpMove_Dist) then Settings.Dev.Distance = tpMove_Dist end
	if (Settings.Dev.Click_Teleport ~= tpClick_Tele) then Settings.Dev.Click_Teleport = tpClick_Tele end
	if (Settings.Dev.Click_Button1 ~= tpClick_Button1) then 
		Settings.Dev.Click_Button1 = tpClick_Button1 
		Settings.Dev.Click_ButtonNUM1 = Teleport.KeySelect(tpClick_Button1)
	end
	if (Settings.Dev.Click_Button2 ~= tpClick_Button2) then 
		Settings.Dev.Click_Button2 = tpClick_Button2 
		Settings.Dev.Click_ButtonNUM2 = Teleport.KeySelect(tpClick_Button2)
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
  
  
end

--**************************************************************************************************************************************
function Teleport.OnUpdateHandler( Event, ticks ) 	
	if ( ticks - Teleport.lastticks > 500 ) then
		Teleport.lastticks = ticks
		if ( tpClick_Tele == "1") then
			Teleport.TargetPort()
		end
		Teleport.halfticks = Teleport.halfticks + 0.5
		if (Teleport.halfticks == 1) then
			Teleport.WindowsHandler()
			Teleport.halfticks = 0
		end
		if (Teleport.LoadID == 2) then
			Teleport.UpdateWaypoints()
		else
			if (Teleport.LoadID <= 2) then
				Teleport.LoadID = Teleport.LoadID + 1
			end
		end	
	end
  if (Teleport.LastAutoList == 0) then
    Teleport.LastAutoList = ticks
  elseif (ticks - Teleport.LastAutoList > 2000) then
    Teleport.LastAutoList = ticks
    Teleport.DoAutoAdd()
  end
end

function Teleport.TargetPort()
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
function Teleport.CorMove(dir)
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
	
	if (string.sub(dir,1,13) == "Teleport.Move") then
		if (dir == "Teleport.MoveF") then newPos = GetPosFromDistanceHeading(p, dist, p.h)
		elseif (dir == "Teleport.MoveB") then newPos = GetPosFromDistanceHeading(p, dist, theta_back)
		elseif (dir == "Teleport.MoveR") then newPos = GetPosFromDistanceHeading(p, dist, theta_right)
		elseif (dir == "Teleport.MoveL") then newPos = GetPosFromDistanceHeading(p, dist, theta_left)
		elseif (dir == "Teleport.MoveU") then newPos = {x = SavedX, y = p.y + dist, z = SavedZ}
		elseif (dir == "Teleport.MoveD") then newPos = {x = SavedX, y = p.y - dist, z = SavedZ}
		end
        GameHacks:TeleportToXYZ(newPos.x,newPos.y,newPos.z)
        if (tpAuto_Sync == "1") then
            Player:SetFacingSynced(p.h)
        else
            Player:SetFacing(p.h)
        end
    
	else
		if (dir == "Teleport.QuickSave1") then
			Settings.Dev.QuickSave1 = {p.x,p.z,p.y,p.h}
		elseif (dir == "Teleport.QuickSave2") then 
			Settings.Dev.QuickSave2 = {p.x,p.z,p.y,p.h}
		elseif (dir == "Teleport.QuickLoad1") then
			GameHacks:TeleportToXYZ(tonumber(Settings.Dev.QuickSave1[1]),tonumber(Settings.Dev.QuickSave1[3]),tonumber(Settings.Dev.QuickSave1[2]))
            if (tpAuto_Sync == "1") then
                Player:SetFacingSynced(Settings.Dev.QuickSave1[4])
            else
                Player:SetFacing(Settings.Dev.QuickSave1[4])
            end
		elseif (dir == "Teleport.QuickLoad2") then 
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
function Teleport.KeySelect(sKEY)
	for k,v in pairs(Teleport.key1) do
		if (v == sKEY) then
			return Teleport.key2[k]
		end
	end
end	



RegisterEventHandler("Module.Initalize",Teleport.Build)
RegisterEventHandler("Gameloop.Update", Teleport.OnUpdateHandler)
RegisterEventHandler("GUI.Update",Teleport.GUIVarUpdate)
RegisterEventHandler("GUI.Item",Teleport.GUIItem)


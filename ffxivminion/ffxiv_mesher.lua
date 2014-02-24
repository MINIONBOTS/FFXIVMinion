-- Map & Meshmanager
mm = { }
mm.navmeshfilepath = GetStartupPath() .. [[\Navigation\]];
mm.mainwindow = { name = strings[gCurrentLanguage].meshManager, x = 350, y = 100, w = 250, h = 400}
mm.meshfiles = {}
mm.currentmapdata = {} 
mm.visible = false
mm.lasttick = 0
mm.mapID = 0
mm.evacPoint = {}
mm.version = 1.0
mm.MarkerList = 
{
    ["grindSpot"] = {},
    ["fishingSpot"] = {},
    ["miningSpot"] = {},
    ["botanySpot"] = {},
    ["navSpot"] = {}
}
mm.MarkerRenderList = {}
mm.reloadMeshPending = false
mm.reloadMeshTmr = 0
mm.reloadMeshName = ""
mm.FateBlacklist = {}
mm.OMC = 0

function mm.ModuleInit() 	
        
    if (Settings.FFXIVMINION.gMeshMGR == nil) then
        Settings.FFXIVMINION.gMeshMGR = "1"
    end
	-- make sure to do set the default meshes even when Settings.FFXIVMINION.Maps ~= nil
    if (Settings.FFXIVMINION.Maps == nil) then
        Settings.FFXIVMINION.Maps = {
			[134] = "Middle La Noscea",
			[135] = "Lower La Noscea",
			[137] = "Eastern La Noscea - Costa Del Sol",
			[138] = "Western La Noscea",
			[139] = "Upper La Noscea - Left",
			[140] = "Western Thanalan",
			[141] = "Central Thanalan",
			[145] = "Eastern Thanalan",
			[146] = "Southern Thanalan",
			[147] = "Northern Thanalan",
			[148] = "Central Shroud",
			[152] = "East Shroud",
			[153] = "South Shroud",
			[154] = "North Shroud",
			[155] = "Coerthas",
			[156] = "Mor Dhona",
			[180] = "Outer La Noscea",
			[337] = "Wolves Den",
			[336] = "Wolves Den",
			[175] = "Wolves Den",
		}
    end
    
    -- for wolves den
    if Settings.FFXIVMINION.Maps[336] == nil then
        Settings.FFXIVMINION.Maps[336] = "Wolves Den"
    end
	
    if Settings.FFXIVMINION.Maps[337] == nil then
        Settings.FFXIVMINION.Maps[337] = "Wolves Den"
    end
    
    if Settings.FFXIVMINION.Maps[175] == nil then
        Settings.FFXIVMINION.Maps[175] = "Wolves Den"
    end

    local wnd = GUI_GetWindowInfo("FFXIVMinion")
    GUI_NewWindow(mm.mainwindow.name,wnd.x+wnd.width,wnd.y,mm.mainwindow.w,mm.mainwindow.h)
    GUI_NewCheckbox(mm.mainwindow.name,strings[gCurrentLanguage].activated,"gMeshMGR",strings[gCurrentLanguage].generalSettings)
    GUI_NewComboBox(mm.mainwindow.name,strings[gCurrentLanguage].navmesh ,"gmeshname",strings[gCurrentLanguage].generalSettings,"")
    GUI_NewCheckbox(mm.mainwindow.name,strings[gCurrentLanguage].showrealMesh,"gShowRealMesh",strings[gCurrentLanguage].generalSettings)
    GUI_NewCheckbox(mm.mainwindow.name,strings[gCurrentLanguage].showPath,"gShowPath",strings[gCurrentLanguage].generalSettings)
    --Grab all meshfiles in our Navigation directory
    local count = 0
    local meshlist = "none"
    local meshfilelist = dirlist(mm.navmeshfilepath,".*obj")
    if ( TableSize(meshfilelist) > 0) then
        local i,meshname = next ( meshfilelist)
        while i and meshname do
            meshname = string.gsub(meshname, ".obj", "")
            table.insert(mm.meshfiles, meshname)
            meshlist = meshlist..","..meshname
            i,meshname = next ( meshfilelist,i)
        end
    end
        
    if (Settings.FFXIVMINION.gnewmeshname == nil) then
        Settings.FFXIVMINION.gnewmeshname = ""
    end
    GUI_NewCheckbox(mm.mainwindow.name,strings[gCurrentLanguage].showMesh,"gShowMesh",strings[gCurrentLanguage].editor)	
    GUI_NewField(mm.mainwindow.name,strings[gCurrentLanguage].newMeshName,"gnewmeshname",strings[gCurrentLanguage].editor)
    GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].newMesh,"newMeshEvent",strings[gCurrentLanguage].editor)
    GUI_NewCheckbox(mm.mainwindow.name,strings[gCurrentLanguage].recmesh,"gMeshrec",strings[gCurrentLanguage].editor)
    GUI_NewComboBox(mm.mainwindow.name,strings[gCurrentLanguage].recAreaType ,"gRecAreaType",strings[gCurrentLanguage].editor,"Road,Lowdanger,Highdanger")-- enum 1,2,3
    GUI_NewNumeric(mm.mainwindow.name,strings[gCurrentLanguage].recAreaSize,"gRecAreaSize",strings[gCurrentLanguage].editor,"1","500")
    GUI_NewCheckbox(mm.mainwindow.name,strings[gCurrentLanguage].changeMesh,"gMeshChange",strings[gCurrentLanguage].editor)
    GUI_NewComboBox(mm.mainwindow.name,strings[gCurrentLanguage].changeAreaType ,"gChangeAreaType",strings[gCurrentLanguage].editor,"Delete,Road,Lowdanger,Highdanger")
    GUI_NewNumeric(mm.mainwindow.name,strings[gCurrentLanguage].changeAreaSize,"gChangeAreaSize",strings[gCurrentLanguage].editor,"1","10")	
    GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].addOffMeshSpot,"offMeshSpotEvent",strings[gCurrentLanguage].editor)
    RegisterEventHandler("offMeshSpotEvent", mm.AddOMC)
    GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].delOffMeshSpot,"deleteoffMeshEvent",strings[gCurrentLanguage].editor)
    RegisterEventHandler("deleteoffMeshEvent", mm.DeleteOMC)
    GUI_NewCheckbox(mm.mainwindow.name,strings[gCurrentLanguage].biDirOffMesh,"gBiDirOffMesh",strings[gCurrentLanguage].editor)
    
    
    gShowMesh = "0"
    gShowRealMesh = "0"
    gShowPath = "0"
    gMeshrec = "0"
    gRecAreaType = "Lowdanger"
    gRecAreaSize = "20"
    gMeshChange = "0"
    gChangeAreaType = "Road"
    gChangeAreaSize = "5"
    gBiDirOffMesh = "0"
        
    MeshManager:SetRecordingArea(2)
    MeshManager:RecSize(gRecAreaSize)
    MeshManager:SetChangeToArea(1)
    MeshManager:SetChangeToRadius(gChangeAreaSize)
    MeshManager:SetChangeAreaMode(false)
    MeshManager:Record(false)
    
    GUI_NewButton(mm.mainwindow.name,strings[gCurrentLanguage].saveMesh,"saveMeshEvent",strings[gCurrentLanguage].editor)
    
    
    RegisterEventHandler("newMeshEvent",mm.ClearNavMesh)	
    RegisterEventHandler("saveMeshEvent",mm.SaveMesh)


    gmeshname_listitems = meshlist
    gnewmeshname = ""
    gMeshMGR = Settings.FFXIVMINION.gMeshMGR 
    
    GUI_SizeWindow(mm.mainwindow.name,mm.mainwindow.w,mm.mainwindow.h)
    GUI_WindowVisible(mm.mainwindow.name,false)
end

function mm.ReadMarkerList(meshname)
	local infopath = mm.navmeshfilepath..meshname..".info"
	
	if (FileExists(infopath)) then
		local lines = LinesFrom(infopath)
		
		--check for old marker file
		if (lines[1] == "version=1") then
			mm.OldReadMarkerList(meshname)
			mm.ConvertMarkerList(infopath)
		else
			ml_marker_mgr.ReadMarkerFile(infopath)
		end
		
		ml_marker_mgr.RefreshMarkerNames()
	end
end

function mm.OldReadMarkerList(meshname)
    -- clear old lists for previous mesh
    for tag, list in pairs(mm.MarkerList) do
        mm.MarkerList[tag] = {}
    end
    
    -- helper functions located in ml_utility.lua
    local lines = LinesFrom(mm.navmeshfilepath..meshname..".info")
    local version = 0
    if ( TableSize(lines) > 0) then
        for i, line in pairs(lines) do
            local sections = {}
            for section in StringSplit(line,":") do
                table.insert(sections, section)
            end
            local tag = nil
            local key = nil
            local mark = string.find(sections[1], "=")
            if (mark ~= nil) then
                tag = sections[1]:sub(0,mark-1)
                key = sections[1]:sub(mark+1)
            end
            if ( tag == "MapID" ) then
                mm.mapID = tonumber(key)
            elseif (tag == "evacPoint") then
                local posTable = {}
                for coord in StringSplit(key,",") do
                    table.insert(posTable, tonumber(coord))
                end
                if (TableSize(posTable) == 3) then
                    mm.evacPoint = { x = tonumber(posTable[1]), y = tonumber(posTable[2]), z = tonumber(posTable[3]) }
                end	
            elseif (tag == "version") then
                version = tonumber(key)
            else
                local posTable = {}
                for coord in StringSplit(sections[2],",") do
                    table.insert(posTable, tonumber(coord))
                end
                local i = 4
                local markerMinLevel = 1
                local markerMaxLevel = 50
                if (version == 1) then
                    markerMinLevel = tonumber(sections[3])
                    markerMaxLevel = tonumber(sections[4])
                    i = 5
                else
                    markerMinLevel = tonumber(sections[3])
                    markerMaxLevel = tonumber(sections[3])
                end
                
                local markerTime = tonumber(sections[i])
                local dataTable = {}
                for data in StringSplit(sections[i+1],",") do
                    table.insert(dataTable, data)
                end
                
                -- add the marker to the list
                local list = mm.MarkerList[tag]
                -- Remove old Marker
                if (mm.MarkerRenderList[key]) then
                    RenderManager:RemoveObject(mm.MarkerRenderList[key])
                end
                -- Draw this Marker
                list[key] = {x=posTable[1],y=posTable[2],z=posTable[3],h=posTable[4],minlevel=markerMinLevel,maxlevel=markerMaxLevel,time=markerTime,data=dataTable}
                                
            end
        end
    else
        ml_debug("NO INFO FILE FOR THAT MESH EXISTS")
    end
end

---------
--Mesh
---------

function mm.ClearNavMesh()
    -- Unload old Mesh
    if (NavigationManager:GetNavMeshName() ~= "") then
        d("Unloading ".. NavigationManager:GetNavMeshName() .." NavMesh.")
        d("Result: "..tostring(NavigationManager:UnloadNavMesh()))	
    end
	
    -- Delete Markers
    ml_marker_mgr.ClearMarkerList()
end

function mm.SaveMesh()
    d("Saving NavMesh...")
    --[[gShowRealMesh = "0"
    NavigationManager:ShowNavMesh(false)
    gShowPath = "0"
    NavigationManager:ShowNavPath(false)
    gShowMesh = "0"
    MeshManager:ShowTriMesh(false)
    gMeshrec = "0"
    MeshManager:Record(false)]]
            
    local filename = ""
    -- If a new Meshname is given, create a new file and save it in there
    if ( gnewmeshname ~= nil and gnewmeshname ~= "" ) then
        -- Make sure file doesnt exist
        local found = false		
        local meshfilelist = dirlist(mm.navmeshfilepath,".*obj")
        if ( TableSize(meshfilelist) > 0) then
            local i,meshname = next ( meshfilelist)
            while i and meshname do
                meshname = string.gsub(meshname, ".obj", "")
                if (meshname == gnewmeshname) then
                    d("Mesh with that Name exists already...")
                    found = true
                    break
                end
                i,meshname = next ( meshfilelist,i)
            end
        end
        if ( not found) then
            -- add new file to list
            gmeshname_listitems = gmeshname_listitems..","..gnewmeshname			
        end
        filename = gnewmeshname		
        
    -- Else we save it under the selected name
    elseif (gmeshname ~= nil and gmeshname ~= "" and gmeshname ~= "none") then
        filename = gmeshname		
    end	
    if ( filename ~= "" and filename ~= "none" ) then
        d("SAVING UNDER: "..tostring(filename))
        d("Result: "..tostring(NavigationManager:SaveNavMesh(filename)))
        mm.reloadMeshPending = true
        mm.reloadMeshTmr = mm.lasttick
        mm.reloadMeshName = filename	
        gnewmeshname = ""
        gmeshname = filename
    else
        ml_error("Enter a proper Navmesh name!")
    end
end

function mm.ChangeNavMesh(newmesh)			
    -- Set the new mesh for the local map	
    if ( NavigationManager:GetNavMeshName() ~= newmesh and NavigationManager:GetNavMeshName() ~= "") then
        d("Unloading current Navmesh: "..tostring(NavigationManager:UnloadNavMesh()))		

		ml_marker_mgr.ClearMarkerList()
        mm.reloadMeshPending = true
        mm.reloadMeshTmr = mm.lasttick
        mm.reloadMeshName = newmesh
        return
    else
        -- Load the mesh for our Map
        if (newmesh ~= nil and newmesh ~= "" and newmesh ~= "none") then				
            d("Loading Navmesh " ..newmesh)
            if (not NavigationManager:LoadNavMesh(mm.navmeshfilepath..newmesh)) then
                d("Error loading Navmesh: "..path)
            else
                mm.reloadMeshPending = false
                mm.ReadMarkerList(newmesh)				
                local mapid = Player.localmapid
                if ( mapid ~= nil and mapid~=0 ) then
                    d("Setting default Mesh for this Zone..(ID :"..tostring(mapid).." Meshname: "..newmesh)
                    Settings.FFXIVMINION.Maps[mapid] = newmesh
                    mm.mapID = mapid
                end				
            end
        end
    end
    gmeshname = newmesh
    Settings.FFXIVMINION.gmeshname = newmesh
    gMeshMGR = "1"
end

function mm.ToggleMenu()
    if (mm.visible) then
        GUI_WindowVisible(mm.mainwindow.name,false)	
        mm.visible = false
    else
        local wnd = GUI_GetWindowInfo("FFXIVMinion")	
        GUI_MoveWindow( mm.mainwindow.name, wnd.x+wnd.width,wnd.y) 
        GUI_WindowVisible(mm.mainwindow.name,true)	
        mm.visible = true
    end
end

function mm.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do		
        if ( k == "gmeshname") then
            mm.ChangeNavMesh(v)
        elseif( k == "gShowRealMesh") then
            if (v == "1") then
                NavigationManager:ShowNavMesh(true)
            else
                NavigationManager:ShowNavMesh(false)
            end
        elseif( k == "gShowPath") then
            if (v == "1") then
                NavigationManager:ShowNavPath(true)
            else
                NavigationManager:ShowNavPath(false)
            end			
        elseif( k == "gShowMesh") then
            if (v == "1") then
                MeshManager:ShowTriMesh(true)
            else
                MeshManager:ShowTriMesh(false)
            end				
        elseif( k == "gMeshrec") then
            if (v == "1") then
                MeshManager:Record(true)
            else
                MeshManager:Record(false)
            end
        elseif( k == "gRecAreaType") then
            if (v == "Road") then
                MeshManager:SetRecordingArea(1)
            elseif (v == "Lowdanger") then
                MeshManager:SetRecordingArea(2)
            elseif (v == "Highdanger") then
                MeshManager:SetRecordingArea(3)
            end
        elseif( k == "gRecAreaSize") then
            MeshManager:RecSize(tonumber(gRecAreaSize))
        elseif( k == "gMeshChange") then
            if (v == "1") then
                MeshManager:SetChangeAreaMode(true)
            else
                MeshManager:SetChangeAreaMode(false)
            end
        elseif( k == "gChangeAreaType") then
            if (v == "Road") then
                MeshManager:SetChangeToArea(1)
            elseif (v == "Lowdanger") then
                MeshManager:SetChangeToArea(2)
            elseif (v == "Highdanger") then
                MeshManager:SetChangeToArea(3)
            elseif (v == "Delete") then	
                MeshManager:SetChangeToArea(255)
            end
        elseif( k == "gChangeAreaSize") then
            MeshManager:SetChangeToRadius(tonumber(gChangeAreaSize))
        elseif( k == "gMeshMGR" or k == "gnewmeshname" ) then
            Settings.FFXIVMINION[tostring(k)] = v    
        end
    end
    GUI_RefreshWindow(mm.mainwindow.name)
end

function mm.OnUpdate( event, tickcount )
    if ( tickcount - mm.lasttick > 500 ) then
        mm.lasttick = tickcount
        
        if ( gMeshrec == "1") then
            -- 162 = Left CTRL
            if ( MeshManager:IsKeyPressed(162) ) then --162 is the integervalue of the virtualkeycode (hex)
                MeshManager:RecForce(true)
            else
                MeshManager:RecForce(false)
            end
            -- 160 = Left Shift
            if ( MeshManager:IsKeyPressed(160) ) then
                MeshManager:RecSize(2*gRecAreaSize)
            else
                MeshManager:RecSize(gRecAreaSize)
            end
            
                        
        end
        
        
        -- 18 + 2 = ALT + VK_RBUTTON Delete Triangles under mouse
            if ( MeshManager:IsKeyPressed(18) and MeshManager:IsKeyPressed(2)) then
                local mousepos = MeshManager:GetMousePos()
                d("Deleting cell "..tostring(mousepos.x).." "..tostring(mousepos.z).. " "..tostring(mousepos.y))
                if ( TableSize(mousepos) > 0 ) then					
                    d("Deleting cell result: "..tostring(MeshManager:DeleteRasterTriangle(mousepos)))
                end
            end	
            
        -- (re-)Loading Navmesh
        if (mm.reloadMeshPending and mm.lasttick - mm.reloadMeshTmr > 2000 and mm.reloadMeshName ~= "") then
            mm.reloadMeshTmr = mm.lasttick
            mm.ChangeNavMesh(mm.reloadMeshName)
        end
        
        -- Check if we switched maps
        local mapid = Player.localmapid
        if ( not mm.reloadMeshPending and mapid ~= nil and mm.mapID ~= mapid ) then			
            if (Settings.FFXIVMINION.Maps[mapid] ~= nil) then
                d("Autoloading Navmesh for this Zone: "..Settings.FFXIVMINION.Maps[mapid])
                mm.reloadMeshPending = true
                mm.reloadMeshTmr = mm.lasttick
                mm.reloadMeshName = Settings.FFXIVMINION.Maps[mapid]				
            end
        end
    end
end

function mm.DrawMarker(marker)
	local markertype = marker:GetType()
	local pos = marker:GetPosition()

    local color = 0
    local s = 1 -- size
    local h = 5 -- height
	
    if ( markertype == "Grind Marker" ) then
        color = 1 -- red
    elseif ( markertype == "Fishing Marker" ) then
        color = 4 --blue
    elseif ( markertype == "Mining Marker" ) then
        color = 7 -- yellow	
    elseif ( markertype == "Botany marker" ) then
        color = 8 -- orange
    end
    --Building the vertices for the object
    local t = { 
        [1] = { pos.x-s, pos.y+s+h, pos.z-s, color },
        [2] = { pos.x+s, pos.y+s+h, pos.z-s, color  },	
        [3] = { pos.x,   pos.y-s+h,   pos.z, color  },
        
        [4] = { pos.x+s, pos.y+s+h, pos.z-s, color },
        [5] = { pos.x+s, pos.y+s+h, pos.z+s, color  },	
        [6] = { pos.x,   pos.y-s+h,   pos.z, color  },
        
        [7] = { pos.x+s, pos.y+s+h, pos.z+s, color },
        [8] = { pos.x-s, pos.y+s+h, pos.z+s, color  },	
        [9] = { pos.x,   pos.y-s+h,   pos.z, color  },
        
        [10] = { pos.x-s, pos.y+s+h, pos.z+s, color },
        [11] = { pos.x-s, pos.y+s+h, pos.z-s, color  },	
        [12] = { pos.x,   pos.y-s+h,   pos.z, color  },
    }
    
    local id = RenderManager:AddObject(t)	
    return id
end

-- add offmesh connection
function mm.AddOMC()
    local pos = Player.pos
    
    mm.OMC = mm.OMC+1
    if (mm.OMC == 1 ) then
        mm.OMCP1 = pos
        mm.OMCP1.y = mm.OMCP1.y +0.15
    elseif (mm.OMC == 2 ) then
        mm.OMCP2 = pos
        mm.OMCP2.y = mm.OMCP2.y + 0.15
        if ( gBiDirOffMesh == "0" ) then
            MeshManager:AddOffMeshConnection(mm.OMCP1,mm.OMCP2,false)
        else
            MeshManager:AddOffMeshConnection(mm.OMCP1,mm.OMCP2,true)
        end
        mm.OMC = 0
    end	
end
-- delete offmesh connection
function mm.DeleteOMC()
    local pos = Player.pos
    MeshManager:DeleteOffMeshConnection(pos)
    mm.OMC = 0
end

function mm.ConvertMarkerList(path)
	if (TableSize(mm.MarkerList) > 0) then
		for type, list in pairs(mm.MarkerList) do
			for name, marker in pairs(list) do
				local newMarker = nil
				if (type == "grindSpot") then 
					newMarker = ml_marker_mgr.templateList[strings[gCurrentLanguage].grindMarker]:Copy()
				elseif (type == "botanySpot") then
					newMarker = ml_marker_mgr.templateList[strings[gCurrentLanguage].botanyMarker]:Copy()
					newMarker:SetFieldValue(strings[gCurrentLanguage].selectItem1, marker.data[1])
					newMarker:SetFieldValue(strings[gCurrentLanguage].selectItem2, marker.data[2])
				elseif (type == "miningSpot") then
					newMarker = ml_marker_mgr.templateList[strings[gCurrentLanguage].miningMarker]:Copy()
					newMarker:SetFieldValue(strings[gCurrentLanguage].selectItem1, marker.data[1])
					newMarker:SetFieldValue(strings[gCurrentLanguage].selectItem2, marker.data[2])
				elseif (type == "fishingSpot") then
					newMarker = ml_marker_mgr.templateList[strings[gCurrentLanguage].fishingMarker]:Copy()
					newMarker:SetFieldValue(strings[gCurrentLanguage].baitName, marker.data[1])
				else
					return
				end
				
				if (ValidTable(newMarker)) then
					newMarker:SetName(name)
					newMarker:SetTime(marker.time)
					local pos = {x = marker.x, y = marker.y, z = marker.z, h = marker.h}
					newMarker:SetPosition(pos)
					newMarker:SetMinLevel(marker.minlevel)
					newMarker:SetMaxLevel(marker.maxlevel)
					ml_marker_mgr.AddMarker(newMarker)
				end
			end
		end
		
		--save backup of original info file
		os.rename(path, path..".old")
		ml_marker_mgr.markerPath = path
	end
end

RegisterEventHandler("ToggleMeshmgr", mm.ToggleMenu)
RegisterEventHandler("GUI.Update",mm.GUIVarUpdate)
RegisterEventHandler("Module.Initalize",mm.ModuleInit)
--RegisterEventHandler("Gameloop.Update",mm.OnUpdate)


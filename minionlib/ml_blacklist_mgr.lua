ml_blacklist_mgr = {}
ml_blacklist_mgr.mainwindow = { name = strings[gCurrentLanguage].blacklistManager, x = 350, y = 100, w = 250, h = 400}
ml_blacklist_mgr.parentWindow = nil
ml_blacklist_mgr.path = ""

function ml_blacklist_mgr.HandleInit()
    GUI_NewWindow(ml_blacklist_mgr.mainwindow.name,ml_blacklist_mgr.mainwindow.x,ml_blacklist_mgr.mainwindow.y,ml_blacklist_mgr.mainwindow.w,ml_blacklist_mgr.mainwindow.h)
    GUI_NewComboBox(ml_blacklist_mgr.mainwindow.name,strings[gCurrentLanguage].blacklistName,"gBlacklistName",strings[gCurrentLanguage].generalSettings,"")
    GUI_NewComboBox(ml_blacklist_mgr.mainwindow.name,strings[gCurrentLanguage].blacklistEntry,"gBlacklistEntry",strings[gCurrentLanguage].generalSettings,"")
    GUI_NewField(ml_blacklist_mgr.mainwindow.name,strings[gCurrentLanguage].entryTime,"gBlacklistEntryTime",strings[gCurrentLanguage].generalSettings)
    GUI_NewButton(ml_blacklist_mgr.mainwindow.name,strings[gCurrentLanguage].deleteEntry,"ml_blacklist_mgr.DeleteEntry",strings[gCurrentLanguage].generalSettings)
    RegisterEventHandler("ml_blacklist_mgr.DeleteEntry",ml_blacklist_mgr.DeleteEntry)
    
    GUI_SizeWindow(ml_blacklist_mgr.mainwindow.name, ml_blacklist_mgr.mainwindow.w, ml_blacklist_mgr.mainwindow.h)
    GUI_UnFoldGroup(ml_blacklist_mgr.mainwindow.name, strings[gCurrentLanguage].generalSettings)
    GUI_WindowVisible(ml_blacklist_mgr.mainwindow.name,false)
end

function ml_blacklist_mgr.RefreshNames()
    local nameList = GetComboBoxList(ml_blacklist.blacklist)
    gBlacklistName_listitems = nameList["keyList"]
    gBlacklistName = nameList["firstKey"]
    
    ml_blacklist_mgr.RefreshEntries()
end

function ml_blacklist_mgr.RefreshEntries()
    local entryList = GetComboBoxList(ml_blacklist.blacklist[gBlacklistName])
    gBlacklistEntry_listitems = entryList["keyList"]
    gBlacklistEntry = entryList["firstKey"]
end

function ml_blacklist_mgr.DeleteEntry()
    ml_blacklist.DeleteEntry(gBlacklistName, gBlacklistEntry)
    ml_blacklist_mgr.RefreshEntries()
end

function ml_blacklist_mgr.ReadBlacklistFile(path)
    if path and path ~= "" then
        ml_blacklist.blacklist = persistence.load(path) or {}
        ml_blacklist_mgr.RefreshNames()
    end
end

function ml_blacklist_mgr.WriteBlacklistFile(path)
    if path and path ~= "" then
        persistence.store(path, ml_blacklist.blacklist)
    end
end

function ml_blacklist_mgr.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if (k == "gBlacklistName") then
            ml_blacklist_mgr.RefreshEntries()
        elseif (k == "gBlacklistEntry") then
            ml_blacklist_mgr.UpdateEntryTime()
        end
    end
end

function ml_blacklist_mgr.UpdateEntryTime()
    local entryTime = ml_blacklist.GetEntryTime(gBlacklistName, gBlacklistEntry)
    if (entryTime == true) then
        gBlacklistEntryTime = "Infinite"
    elseif (entryTime) then
        gBlacklistEntryTime = tostring(round(entryTime/1000,0))
    else
        gBlacklistEntryTime = ""
    end
end

function ml_blacklist_mgr.ToggleMenu()
    if (ml_blacklist_mgr.visible) then
        GUI_WindowVisible(ml_blacklist_mgr.mainwindow.name,false)	
        ml_blacklist_mgr.visible = false
    else
        local wnd = GUI_GetWindowInfo(ml_blacklist_mgr.parentWindow.Name)
        if (wnd) then
            GUI_MoveWindow( ml_blacklist_mgr.mainwindow.name, wnd.x+wnd.width,wnd.y) 
            GUI_WindowVisible(ml_blacklist_mgr.mainwindow.name,true)
        end
        
        ml_blacklist_mgr.visible = true
    end
end

RegisterEventHandler("ToggleBlacklistMgr", ml_blacklist_mgr.ToggleMenu)
RegisterEventHandler("GUI.Update",ml_blacklist_mgr.GUIVarUpdate)
RegisterEventHandler("Module.Initalize",ml_blacklist_mgr.HandleInit)

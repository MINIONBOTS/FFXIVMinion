ffxiv_marker_mgr = {}
ffxiv_marker_mgr.templates = {}

function ffxiv_marker_mgr.ToggleWindow()
	ml_marker_mgr.GUI.main_window.open = not ml_marker_mgr.GUI.main_window.open
end

function ffxiv_marker_mgr.HandleInit()	
	ffxiv_marker_mgr.BuildGrind()
	ffxiv_marker_mgr.BuildGather()
	ffxiv_marker_mgr.BuildFishing()
	ml_gui.ui_mgr:AddMember({ id = "FFXIVMINION##MENU_MARKERS", name = GetString("Markers"), onClick = ffxiv_marker_mgr.ToggleWindow, tooltip = "Open the Marker Manager."},"FFXIVMINION##MENU_HEADER")
end

function ffxiv_marker_mgr.BasicDraw(marker)
	local fields = marker.fields
	local changed, dowrite = false, false

	GUI:PushItemWidth(200)
	GUI:Text(GetString("Name"));
	fields.name, changed = GUI:InputText("##name", fields.name); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(75)
	GUI:Text(GetString("Player Level"));
	fields.minlevel, changed = GUI:InputInt("##minlevel",fields.minlevel,0,0); GUI:SameLine(0,10); if (changed) then dowrite = true end
	GUI:Text(GetString(" - ")); GUI:SameLine(0,10)
	fields.maxlevel, changed = GUI:InputInt("##maxlevel",fields.maxlevel,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(75)
	GUI:Text(GetString("Radius"));
	GUI:SameLine(0,10);
	fields.maxradius, changed = GUI:InputInt("##maxradius",fields.maxradius,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(150)
	GUI:Text(GetString("Position"));
	GUI:Text(GetString(" X ")); GUI:SameLine(0,10)
	fields.pos.x, changed = GUI:InputFloat("##posx",fields.pos.x,0,0,3); if (changed) then dowrite = true end
	GUI:Text(GetString(" Y ")); GUI:SameLine(0,10)
	fields.pos.y, changed = GUI:InputFloat("##posy",fields.pos.y,0,0,3); if (changed) then dowrite = true end
	GUI:Text(GetString(" Z ")); GUI:SameLine(0,10)
	fields.pos.z, changed = GUI:InputFloat("##posz",fields.pos.z,0,0,3); if (changed) then dowrite = true end
	GUI:Text(GetString(" H ")); GUI:SameLine(0,10)
	fields.pos.h, changed = GUI:InputFloat("##posh",fields.pos.h,0,0,3); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	if (GUI:Button(GetString("Set New Position"),180,20)) then
		local myPos = Player.pos
		fields.pos.x, fields.pos.y, fields.pos.z, fields.pos.h = myPos.x, myPos.y, myPos.z, myPos.h
		dowrite = true
	end
	GUI:Separator();
	GUI:Spacing()
	GUI:Spacing()
	
	if (dowrite) then
		ml_marker_mgr.WriteMarkerFile()
	end
end

function ffxiv_marker_mgr.AppendContentID(list, contentid)
	list = IsNull(list, "")
	local value = tostring(contentid)
	if (list == "") then
		return value
	elseif (not string.contains(list,value)) then
		return list..";"..value
	end
	return list
end

function ffxiv_marker_mgr.GetGatherField(marker, fieldName, legacyFieldName, defaultValue)
	local value = marker[fieldName]
	if (value == nil) then
		value = marker[legacyFieldName]
	end
	return IsNull(value,defaultValue)
end

function ffxiv_marker_mgr.GrindDraw(marker)
	local fields = marker.fields
	local changed, dowrite = false, false
	
	GUI:PushItemWidth(75)
	GUI:Text(GetString("Grind Time"));
	fields.duration, changed = GUI:InputInt("##duration",fields.duration,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()

	GUI:PushItemWidth(75)
	GUI:Text(GetString("Monster Level"));
	fields.mincontentlevel, changed = GUI:InputInt("##mincontentlevel",fields.mincontentlevel,0,0); GUI:SameLine(0,10); if (changed) then dowrite = true end
	GUI:Text(GetString(" - ")); GUI:SameLine(0,10)
	fields.maxcontentlevel, changed = GUI:InputInt("##maxcontentlevel",fields.maxcontentlevel,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(200)
	GUI:Text(GetString("Whitelist"));
	fields.whitelist, changed = GUI:InputText("##whitelist",fields.whitelist); if (changed) then dowrite = true end
	if (GUI:Button(GetString("Whitelist Target"))) then
		local target = Player:GetTarget()
		if (table.valid(target)) then
			fields.whitelist = ffxiv_marker_mgr.AppendContentID(fields.whitelist,target.contentid)
			dowrite = true
		end
	end
	
	GUI:Text(GetString("Blacklist"));
	fields.blacklist, changed = GUI:InputText("##blacklist",fields.blacklist); if (changed) then dowrite = true end
	if (GUI:Button(GetString("Blacklist Target"))) then
		local target = Player:GetTarget()
		if (table.valid(target)) then
			fields.blacklist = ffxiv_marker_mgr.AppendContentID(fields.blacklist,target.contentid)
			dowrite = true
		end
	end
	GUI:PopItemWidth()
	
	if (dowrite) then
		ml_marker_mgr.WriteMarkerFile()
	end
end

function ffxiv_marker_mgr.BuildGrind()	
	local fields = {
		minlevel = 1,
		maxlevel = ffxivminion.maxlevel,
		maxradius = 100,
		mincontentlevel = 0,
		maxcontentlevel = 0,
		whitelist = "",
		blacklist = "",
	}
	
	local grindTemplate = ml_marker:new("Grind", fields, ffxiv_marker_mgr.DrawGrind)
	
	ml_marker_mgr.AddMarkerTemplate(grindTemplate)	
	ffxiv_marker_mgr.templates["Grind"] = grindTemplate
end

function ffxiv_marker_mgr.DrawGrind(marker)
	ffxiv_marker_mgr.BasicDraw(marker)
	ffxiv_marker_mgr.GrindDraw(marker)
end

function ffxiv_marker_mgr.GatherDraw(marker)
	local fields = marker.fields
	local changed, dowrite, newindex = false, false, nil
	
	GUI:PushItemWidth(75)
	GUI:Text(GetString("Max Gather Time"));
	GUI:SameLine(0,10)
	fields.duration, changed = GUI:InputInt("##duration",fields.duration,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()

	GUI:PushItemWidth(75)
	GUI:Text(GetString("Node Level"));
	fields.mincontentlevel, changed = GUI:InputInt("##mincontentlevel",fields.mincontentlevel,0,0); GUI:SameLine(0,10); if (changed) then dowrite = true end
	GUI:Text(GetString(" - ")); GUI:SameLine(0,10)
	fields.maxcontentlevel, changed = GUI:InputInt("##maxcontentlevel",fields.maxcontentlevel,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	local oldindex = GetKeyByValue(fields.skillprofile, SkillMgr.profiles)
	newindex, changed = GUI:Combo(GetString("Skill Profile"), oldindex, SkillMgr.profiles)
	if (changed) then
		fields.skillprofile = SkillMgr.profiles[newindex]
		dowrite = true
	end
	
	GUI:PushItemWidth(200)
	GUI:Text(GetString("Gather Items"));
	GUI:Text(GetString("Item 1")); GUI:SameLine(0,5); 
	fields.item1, changed = GUI:InputText("##item1",fields.item1); if (changed) then dowrite = true end
	GUI:Text(GetString("Item 2")); GUI:SameLine(0,5); 
	fields.item2, changed = GUI:InputText("##item2",fields.item2); if (changed) then dowrite = true end
	GUI:Text(GetString("Item 3")); GUI:SameLine(0,5); 
	fields.item3, changed = GUI:InputText("##item3",fields.item3); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(75)
	fields.usecordials, changed = GUI:Checkbox(GetString("Use Cordials"),fields.usecordials); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	if (GUI:CollapsingHeader(GetString("Settings"),"gathersettings")) then
		GUI:PushItemWidth(75)
		fields.gardening, changed = GUI:Checkbox(GetString("Gardening Items"),fields.gardening); if (changed) then dowrite = true end
		fields.chocofood, changed = GUI:Checkbox(GetString("Chocobo Food"),fields.chocofood); if (changed) then dowrite = true end
		fields.rares, changed = GUI:Checkbox(GetString("Rare Items"),fields.rares); if (changed) then dowrite = true end
		fields.specialrares, changed = GUI:Checkbox(GetString("Special Rare Items"),fields.specialrares); if (changed) then dowrite = true end
		GUI:SameLine(0,10)
		fields.dangerousarea, changed = GUI:Checkbox(GetString("Dangerous"),fields.dangerousarea); if (changed) then dowrite = true end
		GUI:PopItemWidth()
	end
	
	if (GUI:CollapsingHeader(GetString("Whitelist"),"gatherwhitelist")) then
		GUI:PushItemWidth(200)
		GUI:Text(GetString("Node Whitelist"));
		fields.whitelist, changed = GUI:InputText("##whitelist",fields.whitelist); if (changed) then dowrite = true end
		if (GUI:Button(GetString("Whitelist Node"))) then
			local target = Player:GetTarget()
			if (table.valid(target)) then
				fields.whitelist = ffxiv_marker_mgr.AppendContentID(fields.whitelist,target.contentid)
				dowrite = true
			end
		end
		GUI:PopItemWidth()
	end
	
	if (GUI:CollapsingHeader(GetString("Blacklist"),"gatherblacklist")) then
		GUI:PushItemWidth(200)
		GUI:Text(GetString("Node Blacklist"));
		fields.blacklist, changed = GUI:InputText("##blacklist",fields.blacklist); if (changed) then dowrite = true end
		if (GUI:Button(GetString("Blacklist Node"))) then
			local target = Player:GetTarget()
			if (table.valid(target)) then
				fields.blacklist = ffxiv_marker_mgr.AppendContentID(fields.blacklist,target.contentid)
				dowrite = true
			end
		end
		GUI:PopItemWidth()
	end
	
	if (dowrite) then
		ml_marker_mgr.WriteMarkerFile()
	end
end

function ffxiv_marker_mgr.BuildGather()
	local fields = {
		minlevel = 1,
		maxlevel = ffxivminion.maxlevel,
		maxradius = 100,
		mincontentlevel = 1,
		maxcontentlevel = ffxivminion.maxlevel,
		item1 = "",
		item2 = "",
		item3 = "",
		whitelist = "",
		blacklist = "",
		maps = "Any",
		gardening = false,
		chocofood = false,
		rares = false,
		specialrares = false,
		favoritem = 0,
		dangerousarea = false,
		skillprofile = GetString("none"),
		mingp = 0,
		usecordials = false,
		nogpitem = "",
		timeout = 2,
	}
	
	local botanyTemplate = ml_marker:new("Botany", fields, ffxiv_marker_mgr.DrawGather)
	local miningTemplate = ml_marker:new("Mining", fields, ffxiv_marker_mgr.DrawGather)
	
	ml_marker_mgr.AddMarkerTemplate(botanyTemplate)
	ml_marker_mgr.AddMarkerTemplate(miningTemplate)
	
	ffxiv_marker_mgr.templates["Botany"] = botanyTemplate
	ffxiv_marker_mgr.templates["Mining"] = miningTemplate
end

function ffxiv_marker_mgr.DrawGather(marker)
	ffxiv_marker_mgr.BasicDraw(marker)
	ffxiv_marker_mgr.GatherDraw(marker)
end

function ffxiv_marker_mgr.FishingDraw(marker)
	local fields = marker.fields
	local changed, dowrite = false, false
	
	GUI:PushItemWidth(75)
	GUI:Text(GetString("Fish Time"));
	fields.duration, changed = GUI:InputInt("##duration",fields.duration,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:Text(GetString("Bait Choice(s)"));
	fields.baitname, changed = GUI:InputText("##baitname",fields.baitname); if (changed) then dowrite = true end
	
	if (GUI:CollapsingHeader(GetString("Settings").."##fish","fishsettings")) then
		GUI:PushItemWidth(75)
		fields.usemooch, changed = GUI:Checkbox(GetString("Use Mooch"),fields.usemooch); if (changed) then dowrite = true end
		fields.usemooch2, changed = GUI:Checkbox(GetString("Use Mooch II"),fields.usemooch2); if (changed) then dowrite = true end
		fields.usepatience, changed = GUI:Checkbox(GetString("Use Patience I"),fields.usepatience); if (changed) then dowrite = true end
		fields.usepatience2, changed = GUI:Checkbox(GetString("Use Patience II"),fields.usepatience2); if (changed) then dowrite = true end
		fields.usefisheyes, changed = GUI:Checkbox(GetString("Use Fish Eyes"),fields.usefisheyes); if (changed) then dowrite = true end
		fields.usesnagging, changed = GUI:Checkbox(GetString("Use Snagging"),fields.usesnagging); if (changed) then dowrite = true end
		fields.usechum, changed = GUI:Checkbox(GetString("Use Chum"),fields.usechum); if (changed) then dowrite = true end
		fields.usedoublehook, changed = GUI:Checkbox(GetString("Use Double Hook"),fields.usedoublehook); if (changed) then dowrite = true end
		GUI:SameLine(0,10)
		fields.dangerousarea, changed = GUI:Checkbox(GetString("Dangerous"),fields.dangerousarea); if (changed) then dowrite = true end
		GUI:PopItemWidth()
	end
	
	if (GUI:CollapsingHeader(GetString("Lists").."##fish","fishsettings2")) then
		GUI:PushItemWidth(200)
		GUI:Text(GetString("Moochable Fish"));
		fields.moochables, changed = GUI:InputText("##moochables",fields.moochables); if (changed) then dowrite = true end
		GUI:Text(GetString("Identical Cast Fish"));
		fields.identicalcastables, changed = GUI:InputText("##identicalcastables",fields.identicalcastables); if (changed) then dowrite = true end
		GUI:Text(GetString("Surface Slap Fish"));
		fields.surfaceslaplist, changed = GUI:InputText("##surfaceslaplist",fields.surfaceslaplist); if (changed) then dowrite = true end
		GUI:PopItemWidth()
	end
	
	if (GUI:CollapsingHeader(GetString("Whitelist").."##fish","fishWhitelist")) then
	GUI:Text(GetString("Whitelist Fish"));
	GUI:Text(GetString("NQ")); GUI:SameLine(0,5); 
	fields.whitelist, changed = GUI:InputText("##whitelist",fields.whitelist); if (changed) then dowrite = true end
	GUI:Text(GetString("HQ")); GUI:SameLine(0,5);
	fields.whitelistHQ, changed = GUI:InputText("##whitelistHQ",fields.whitelistHQ); if (changed) then dowrite = true end
	end
	
	if (GUI:CollapsingHeader(GetString("Blacklist").."##fish","fishBlacklist")) then
	GUI:Text(GetString("Blacklist Fish"));
	GUI:Text(GetString("NQ")); GUI:SameLine(0,5); 
	fields.blacklist, changed = GUI:InputText("##blacklist",fields.blacklist); if (changed) then dowrite = true end
	GUI:Text(GetString("HQ")); GUI:SameLine(0,5);
	fields.blacklistHQ, changed = GUI:InputText("##blacklistHQ",fields.blacklistHQ); if (changed) then dowrite = true end
	end
	
	if (dowrite) then
		ml_marker_mgr.WriteMarkerFile()
	end
end

function ffxiv_marker_mgr.BuildFishing()
	local fields = {
		minlevel = 1,
		maxlevel = ffxivminion.maxlevel,
		maxradius = 100,
		baitname = "",
		usefisheyes = false,
		usemooch = true,
		usemooch2 = false,
		usepatience = false,
		usepatience2 = false,
		usesnagging = false,
		usechum = false,
		usedoublehook = false,
		moochables = "",
		identicalcastables = "",
		surfaceslaplist = "",
		whitelist = "",
		whitelistHQ = "",
		blacklist = "",
		blacklistHQ = "",
		dangerousarea = false,
	}
	
	local fishingTemplate = ml_marker:new("Fishing", fields, ffxiv_marker_mgr.DrawFishing)
	
	ml_marker_mgr.AddMarkerTemplate(fishingTemplate)	
	ffxiv_marker_mgr.templates["Fishing"] = fishingTemplate
end

function ffxiv_marker_mgr.DrawFishing(marker)
	ffxiv_marker_mgr.BasicDraw(marker)
	ffxiv_marker_mgr.FishingDraw(marker)
end

function ffxiv_marker_mgr.AddMarker(strType, fields)
	local selectedTemplate = ml_marker_mgr.templates[strType]
	if (selectedTemplate) then
		local suppliedFields = type(fields) == "table" and fields or {}
		local defaultFields = table.shallowcopy(selectedTemplate.fields)
		defaultFields.mapid = ml_marker_mgr.activeMap
		
		local pos = Player.pos
		defaultFields.pos = {}
		if (pos) then
			if (pos.x) then defaultFields.pos.x = pos.x end
			if (pos.y) then defaultFields.pos.y = pos.y end
			if (pos.z) then defaultFields.pos.z = pos.z end
			if (pos.h) then defaultFields.pos.h = pos.h end
			if (pos.xh) then defaultFields.pos.xh = pos.xh end
			if (pos.yh) then defaultFields.pos.yh = pos.yh end
			if (pos.zh) then defaultFields.pos.zh = pos.zh end
		end
		
		if (table.valid(suppliedFields)) then
			for k,v in pairs(suppliedFields) do
				if (k == "pos" and type(v) == "table") then
					defaultFields.pos = table.shallowcopy(v)
				else
					defaultFields[k] = v
				end
			end
		end
		
		local markerName = suppliedFields.name or "New "..selectedTemplate.fields.type.." Marker"
		local newMarker = selectedTemplate:Create(markerName,defaultFields)
		ml_marker_mgr.WriteMarkerFile()
		ml_marker_mgr.UpdateMarkerSelector()
		return newMarker
	end
	return nil
end

RegisterEventHandler("Module.Initalize",ffxiv_marker_mgr.HandleInit,"ffxiv_marker_mgr.HandleInit")

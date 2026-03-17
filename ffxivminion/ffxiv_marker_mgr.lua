ffxiv_marker_mgr = {}
ffxiv_marker_mgr.templates = {}

function ffxiv_marker_mgr.HandleInit()	
	ffxiv_marker_mgr.BuildGrind()
	ffxiv_marker_mgr.BuildGather()
	ffxiv_marker_mgr.BuildFishing()
	ml_gui.ui_mgr:AddMember({ id = "FFXIVMINION##MENU_MARKERS", name = GetString("Markers"), onClick = function() ml_marker_mgr.GUI.main_window.open = not ml_marker_mgr.GUI.main_window.open end, tooltip = "Open the Marker Manager."},"FFXIVMINION##MENU_HEADER")
end

function ffxiv_marker_mgr.BasicDraw(marker)
	local vars = marker.GUI.vars
	local fields = marker.fields
	local changed, dowrite = false, false

	GUI:PushItemWidth(200)
	GUI:Text(GetString("Name"));
	marker.fields.name, changed = GUI:InputText("##name", marker.fields.name); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(75)
	GUI:Text(GetString("Player Level"));
	marker.fields.minlevel, changed = GUI:InputInt("##minlevel",marker.fields.minlevel,0,0); GUI:SameLine(0,10); if (changed) then dowrite = true end
	GUI:Text(GetString(" - ")); GUI:SameLine(0,10)
	marker.fields.maxlevel, changed = GUI:InputInt("##maxlevel",marker.fields.maxlevel,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(75)
	GUI:Text(GetString("Radius"));
	GUI:SameLine(0,10);
	marker.fields.maxradius, changed = GUI:InputInt("##maxradius",marker.fields.maxradius,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(150)
	GUI:Text(GetString("Position"));
	GUI:Text(GetString(" X ")); GUI:SameLine(0,10)
	marker.fields.pos.x, changed = GUI:InputFloat("##posx",marker.fields.pos.x,0,0,3); if (changed) then dowrite = true end
	GUI:Text(GetString(" Y ")); GUI:SameLine(0,10)
	marker.fields.pos.y, changed = GUI:InputFloat("##posy",marker.fields.pos.y,0,0,3); if (changed) then dowrite = true end
	GUI:Text(GetString(" Z ")); GUI:SameLine(0,10)
	marker.fields.pos.z, changed = GUI:InputFloat("##posz",marker.fields.pos.z,0,0,3); if (changed) then dowrite = true end
	GUI:Text(GetString(" H ")); GUI:SameLine(0,10)
	marker.fields.pos.h, changed = GUI:InputFloat("##posh",marker.fields.pos.h,0,0,3); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	if (GUI:Button(GetString("Set New Position"),180,20)) then
		local myPos = Player.pos
		marker.fields.pos.x, marker.fields.pos.y, marker.fields.pos.z, marker.fields.pos.h = myPos.x, myPos.y, myPos.z, myPos.h
		dowrite = true
	end
	GUI:Separator();
	GUI:Spacing()
	GUI:Spacing()
	
	if (dowrite) then
		ml_marker_mgr.WriteMarkerFile()
	end
end

function ffxiv_marker_mgr.GrindDraw(marker)
	local vars = marker.GUI.vars
	local fields = marker.fields
	local changed, dowrite = false, false
	
	GUI:PushItemWidth(75)
	GUI:Text(GetString("Grind Time"));
	marker.fields.duration, changed = GUI:InputInt("##duration",marker.fields.duration,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()

	GUI:PushItemWidth(75)
	GUI:Text(GetString("Monster Level"));
	marker.fields.mincontentlevel, changed = GUI:InputInt("##mincontentlevel",marker.fields.mincontentlevel,0,0); GUI:SameLine(0,10); if (changed) then dowrite = true end
	GUI:Text(GetString(" - ")); GUI:SameLine(0,10)
	marker.fields.maxcontentlevel, changed = GUI:InputInt("##maxcontentlevel",marker.fields.maxcontentlevel,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(200)
	GUI:Text(GetString("Whitelist"));
	marker.fields.whitelist, changed = GUI:InputText("##whitelist",marker.fields.whitelist); if (changed) then dowrite = true end
	if (GUI:Button(GetString("Whitelist Target"))) then
		local target = Player:GetTarget()
		if (table.valid(target)) then
			if (marker.fields.whitelist == "") then
				marker.fields.whitelist = tostring(target.contentid)
			else
				if (not string.contains(marker.fields.whitelist,tostring(target.contentid))) then
					marker.fields.whitelist = marker.fields.whitelist..";"..tostring(target.contentid)
				end
			end
			dowrite = true
		end
	end
	
	GUI:Text(GetString("Blacklist"));
	marker.fields.blacklist, changed = GUI:InputText("##blacklist",marker.fields.blacklist); if (changed) then dowrite = true end
	if (GUI:Button(GetString("Blacklist Target"))) then
		local target = Player:GetTarget()
		if (table.valid(target)) then
			if (marker.fields.blacklist == "") then
				marker.fields.blacklist = tostring(target.contentid)
			else
				if (not string.contains(marker.fields.blacklist,tostring(target.contentid))) then
					marker.fields.blacklist = marker.fields.blacklist..";"..tostring(target.contentid)
				end
			end
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
		maxlevel = 70,
		maxradius = 100,
		mincontentlevel = 0,
		maxcontentlevel = 0,
		whitelist = "",
		blacklist = "",
	}
	
	local draw = function (self)
		ffxiv_marker_mgr.BasicDraw(self)
		ffxiv_marker_mgr.GrindDraw(self)
	end
	
	local grindTemplate = ml_marker:new("Grind", fields, draw)
	
	ml_marker_mgr.AddMarkerTemplate(grindTemplate)	
	ffxiv_marker_mgr.templates["Grind"] = grindTemplate
end

function ffxiv_marker_mgr.GatherDraw(marker)
	local vars = marker.GUI.vars
	local fields = marker.fields
	local changed, dowrite, newindex = false, false, nil
	
	GUI:PushItemWidth(75)
	GUI:Text(GetString("Max Gather Time"));
	GUI:SameLine(0,10)
	marker.fields.duration, changed = GUI:InputInt("##duration",marker.fields.duration,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()

	GUI:PushItemWidth(75)
	GUI:Text(GetString("Node Level"));
	marker.fields.mincontentlevel, changed = GUI:InputInt("##mincontentlevel",marker.fields.mincontentlevel,0,0); GUI:SameLine(0,10); if (changed) then dowrite = true end
	GUI:Text(GetString(" - ")); GUI:SameLine(0,10)
	marker.fields.maxcontentlevel, changed = GUI:InputInt("##maxcontentlevel",marker.fields.maxcontentlevel,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	local oldindex = GetKeyByValue(marker.fields.skillprofile, SkillMgr.profiles)
	newindex, changed = GUI:Combo(GetString("Skill Profile"), oldindex, SkillMgr.profiles)
	if (changed) then
		marker.fields.skillprofile = SkillMgr.profiles[newindex]
	end
	
	GUI:PushItemWidth(200)
	GUI:Text(GetString("Gather Items"));
	GUI:Text(GetString("Item 1")); GUI:SameLine(0,5); 
	marker.fields.item1, changed = GUI:InputText("##item1",marker.fields.item1); if (changed) then dowrite = true end
	GUI:Text(GetString("Item 2")); GUI:SameLine(0,5); 
	marker.fields.item2, changed = GUI:InputText("##item2",marker.fields.item2); if (changed) then dowrite = true end
	GUI:Text(GetString("Item 3")); GUI:SameLine(0,5); 
	marker.fields.item3, changed = GUI:InputText("##item3",marker.fields.item3); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(75)
	marker.fields.usecordials, changed = GUI:Checkbox(GetString("Use Cordials"),marker.fields.usecordials); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	if (GUI:CollapsingHeader(GetString("Settings"),"gathersettings")) then
		GUI:PushItemWidth(75)
		marker.fields.gardening, changed = GUI:Checkbox(GetString("Gardening Items"),marker.fields.gardening); if (changed) then dowrite = true end
		marker.fields.chocofood, changed = GUI:Checkbox(GetString("Chocobo Food"),marker.fields.chocofood); if (changed) then dowrite = true end
		marker.fields.rares, changed = GUI:Checkbox(GetString("Rare Items"),marker.fields.rares); if (changed) then dowrite = true end
		marker.fields.specialrares, changed = GUI:Checkbox(GetString("Special Rare Items"),marker.fields.specialrares); if (changed) then dowrite = true end
		GUI:SameLine(0,10)
		marker.fields.dangerousarea, changed = GUI:Checkbox(GetString("Dangerous"),marker.fields.dangerousarea); if (changed) then dowrite = true end
		GUI:PopItemWidth()
	end
	
	if (GUI:CollapsingHeader(GetString("Whitelist"),"gatherwhitelist")) then
		GUI:PushItemWidth(200)
		GUI:Text(GetString("Node Whitelist"));
		marker.fields.whitelist, changed = GUI:InputText("##whitelist",marker.fields.whitelist); if (changed) then dowrite = true end
		if (GUI:Button(GetString("Whitelist Node"))) then
			local target = Player:GetTarget()
			if (table.valid(target)) then
				if (marker.fields.whitelist == "") then
					marker.fields.whitelist = tostring(target.contentid)
				else
					if (not string.contains(marker.fields.whitelist,tostring(target.contentid))) then
						marker.fields.whitelist = marker.fields.whitelist..";"..tostring(target.contentid)
					end
				end
				dowrite = true
			end
		end
		GUI:PopItemWidth()
	end
	
	if (GUI:CollapsingHeader(GetString("Blacklist"),"gatherblacklist")) then
		GUI:PushItemWidth(200)
		GUI:Text(GetString("Node Blacklist"));
		marker.fields.blacklist, changed = GUI:InputText("##blacklist",marker.fields.blacklist); if (changed) then dowrite = true end
		if (GUI:Button(GetString("Blacklist Node"))) then
			local target = Player:GetTarget()
			if (table.valid(target)) then
				if (marker.fields.blacklist == "") then
					marker.fields.blacklist = tostring(target.contentid)
				else
					if (not string.contains(marker.fields.blacklist,tostring(target.contentid))) then
						marker.fields.blacklist = marker.fields.blacklist..";"..tostring(target.contentid)
					end
				end
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
		maxlevel = 80,
		maxradius = 100,
		mincontentlevel = 1,
		maxcontentlevel = 80,
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
	
	local draw = function (self)
		ffxiv_marker_mgr.BasicDraw(self)
		ffxiv_marker_mgr.GatherDraw(self)
	end
	
	local botanyTemplate = ml_marker:new("Botany", fields, draw)
	local miningTemplate = ml_marker:new("Mining", fields, draw)
	
	ml_marker_mgr.AddMarkerTemplate(botanyTemplate)
	ml_marker_mgr.AddMarkerTemplate(miningTemplate)
	
	ffxiv_marker_mgr.templates["Botany"] = botanyTemplate
	ffxiv_marker_mgr.templates["Mining"] = miningTemplate
end

function ffxiv_marker_mgr.FishingDraw(marker)
	local vars = marker.GUI.vars
	local fields = marker.fields
	local changed, dowrite = false, false
	
	GUI:PushItemWidth(75)
	GUI:Text(GetString("Fish Time"));
	marker.fields.duration, changed = GUI:InputInt("##duration",marker.fields.duration,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:Text(GetString("Bait Choice(s)"));
	marker.fields.baitname, changed = GUI:InputText("##baitname",marker.fields.baitname); if (changed) then dowrite = true end
	
	if (GUI:CollapsingHeader(GetString("Settings").."##fish","fishsettings")) then
		GUI:PushItemWidth(75)
		marker.fields.usemooch, changed = GUI:Checkbox(GetString("Use Mooch"),marker.fields.usemooch); if (changed) then dowrite = true end
		marker.fields.usemooch2, changed = GUI:Checkbox(GetString("Use Mooch II"),marker.fields.usemooch2); if (changed) then dowrite = true end
		marker.fields.usepatience, changed = GUI:Checkbox(GetString("Use Patience I"),marker.fields.usepatience); if (changed) then dowrite = true end
		marker.fields.usepatience2, changed = GUI:Checkbox(GetString("Use Patience II"),marker.fields.usepatience2); if (changed) then dowrite = true end
		marker.fields.usefisheyes, changed = GUI:Checkbox(GetString("Use Fish Eyes"),marker.fields.usefisheyes); if (changed) then dowrite = true end
		marker.fields.usesnagging, changed = GUI:Checkbox(GetString("Use Snagging"),marker.fields.usesnagging); if (changed) then dowrite = true end
		marker.fields.usechum, changed = GUI:Checkbox(GetString("Use Chum"),marker.fields.usechum); if (changed) then dowrite = true end
		marker.fields.usedoublehook, changed = GUI:Checkbox(GetString("Use Double Hook"),marker.fields.usedoublehook); if (changed) then dowrite = true end
		GUI:SameLine(0,10)
		marker.fields.dangerousarea, changed = GUI:Checkbox(GetString("Dangerous"),marker.fields.dangerousarea); if (changed) then dowrite = true end
		GUI:PopItemWidth()
	end
	
	if (GUI:CollapsingHeader(GetString("Lists").."##fish","fishsettings2")) then
		GUI:PushItemWidth(200)
		GUI:Text(GetString("Moochable Fish"));
		marker.fields.moochables, changed = GUI:InputText("##moochables",marker.fields.moochables); if (changed) then dowrite = true end
		GUI:Text(GetString("Identical Cast Fish"));
		marker.fields.identicalcastables, changed = GUI:InputText("##identicalcastables",marker.fields.identicalcastables); if (changed) then dowrite = true end
		GUI:Text(GetString("Surface Slap Fish"));
		marker.fields.surfaceslaplist, changed = GUI:InputText("##surfaceslaplist",marker.fields.surfaceslaplist); if (changed) then dowrite = true end
		GUI:PopItemWidth()
	end
	
	if (GUI:CollapsingHeader(GetString("Whitelist").."##fish","fishWhitelist")) then
	GUI:Text(GetString("Whitelist Fish"));
	GUI:Text(GetString("NQ")); GUI:SameLine(0,5); 
	marker.fields.whitelist, changed = GUI:InputText("##whitelist",marker.fields.whitelist); if (changed) then dowrite = true end
	GUI:Text(GetString("HQ")); GUI:SameLine(0,5);
	marker.fields.whitelistHQ, changed = GUI:InputText("##whitelistHQ",marker.fields.whitelistHQ); if (changed) then dowrite = true end
	end
	
	if (GUI:CollapsingHeader(GetString("Blacklist").."##fish","fishBlacklist")) then
	GUI:Text(GetString("Blacklist Fish"));
	GUI:Text(GetString("NQ")); GUI:SameLine(0,5); 
	marker.fields.blacklist, changed = GUI:InputText("##blacklist",marker.fields.blacklist); if (changed) then dowrite = true end
	GUI:Text(GetString("HQ")); GUI:SameLine(0,5);
	marker.fields.blacklistHQ, changed = GUI:InputText("##blacklistHQ",marker.fields.blacklistHQ); if (changed) then dowrite = true end
	end
	
	if (dowrite) then
		ml_marker_mgr.WriteMarkerFile()
	end
end

function ffxiv_marker_mgr.BuildFishing()
	local fields = {
		minlevel = 1,
		maxlevel = 80,
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
	
	local draw = function (self)
		ffxiv_marker_mgr.BasicDraw(self)
		ffxiv_marker_mgr.FishingDraw(self)
	end
	
	local fishingTemplate = ml_marker:new("Fishing", fields, draw)
	
	ml_marker_mgr.AddMarkerTemplate(fishingTemplate)	
	ffxiv_marker_mgr.templates["Fishing"] = fishingTemplate
end

function ffxiv_marker_mgr.AddMarker(strType, fields)
	local templates = ml_marker_mgr.templates
	local selectedTemplate = templates[strType]
	if (selectedTemplate) then
		local defaultFields = selectedTemplate.fields
		defaultFields.name = varname
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
		
		if (table.valid(fields)) then
			for k,v in pairs(fields) do
				defaultFields[k] = v
			end
		end
		
		local newMarker = selectedTemplate:Create(fields.name,defaultFields)
		ml_marker_mgr.WriteMarkerFile()
	end
end

RegisterEventHandler("Module.Initalize",ffxiv_marker_mgr.HandleInit,"ffxiv_marker_mgr.HandleInit")
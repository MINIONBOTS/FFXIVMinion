ffxiv_marker_mgr = {}
ffxiv_marker_mgr.templates = {}

function ffxiv_marker_mgr.HandleInit()	
	ffxiv_marker_mgr.BuildGrind()
	ffxiv_marker_mgr.BuildGather()
	ffxiv_marker_mgr.BuildFishing()
	ml_gui.ui_mgr:AddMember({ id = "FFXIVMINION##MENU_MARKERS", name = "Markers", onClick = function() ml_marker_mgr.GUI.main_window.open = not ml_marker_mgr.GUI.main_window.open end, tooltip = "Open the Marker Manager."},"FFXIVMINION##MENU_HEADER")
end

function ffxiv_marker_mgr.BasicDraw(marker)
	local vars = marker.GUI.vars
	local fields = marker.fields

	GUI:PushItemWidth(200)
	local changed, dowrite = false, false
	GUI:Text("Name");
	marker.fields.name, changed = GUI:InputText("##name", marker.fields.name); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(75)
	GUI:Text("Player Level");
	marker.fields.minlevel, changed = GUI:InputInt("##minlevel",marker.fields.minlevel,0,0); GUI:SameLine(0,10); if (changed) then dowrite = true end
	GUI:Text(" - "); GUI:SameLine(0,10)
	marker.fields.maxlevel, changed = GUI:InputInt("##maxlevel",marker.fields.maxlevel,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(75)
	GUI:Text("Radius");
	marker.fields.maxradius, changed = GUI:InputInt("##maxradius",marker.fields.maxradius,0,0); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(150)
	GUI:Text("Position");
	GUI:Text(" X "); GUI:SameLine(0,10)
	marker.fields.pos.x, changed = GUI:InputFloat("##posx",marker.fields.pos.x,0,0,3); if (changed) then dowrite = true end
	GUI:Text(" Y "); GUI:SameLine(0,10)
	marker.fields.pos.y, changed = GUI:InputFloat("##posy",marker.fields.pos.y,0,0,3); if (changed) then dowrite = true end
	GUI:Text(" Z "); GUI:SameLine(0,10)
	marker.fields.pos.z, changed = GUI:InputFloat("##posz",marker.fields.pos.z,0,0,3); if (changed) then dowrite = true end
	GUI:Text(" H "); GUI:SameLine(0,10)
	marker.fields.pos.h, changed = GUI:InputFloat("##posh",marker.fields.pos.h,0,0,3); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	if (GUI:Button("Set New Position")) then
		local myPos = Player.pos
		marker.fields.pos.x, marker.fields.pos.y, marker.fields.pos.z, marker.fields.pos.h = myPos.x, myPos.y, myPos.z, myPos.h
		dowrite = true
	end
	
	if (dowrite) then
		ml_marker_mgr.WriteMarkerFile()
	end
end

function ffxiv_marker_mgr.GrindDraw(marker)
	local vars = marker.GUI.vars
	local fields = marker.fields
	
	GUI:PushItemWidth(75)
	GUI:Text("Grind Time");
	marker.fields.duration, changed = GUI:InputText("##duration",marker.fields.duration); if (changed) then dowrite = true end
	GUI:PopItemWidth()

	GUI:PushItemWidth(75)
	GUI:Text("Monster Level");
	marker.fields.mincontentlevel, changed = GUI:InputText("##mincontentlevel",marker.fields.mincontentlevel); GUI:SameLine(0,10); if (changed) then dowrite = true end
	GUI:Text(" - "); GUI:SameLine(0,10)
	marker.fields.maxcontentlevel, changed = GUI:InputText("##maxcontentlevel",marker.fields.maxcontentlevel); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(200)
	GUI:Text("Whitelist");
	marker.fields.whitelist, changed = GUI:InputText("##whitelist",marker.fields.whitelist); if (changed) then dowrite = true end
	if (GUI:Button("Whitelist Target")) then
		local target = Player:GetTarget()
		if (table.valid(target)) then
			if (marker.fields.whitelist == "") then
				marker.fields.whitelist = tostring(target.contentid)
			else
				if (not string.find(marker.fields.whitelist,tostring(target.contentid))) then
					marker.fields.whitelist = marker.fields.whitelist..";"..tostring(target.contentid)
				end
			end
			dowrite = true
		end
	end
	
	GUI:Text("Blacklist");
	marker.fields.blacklist, changed = GUI:InputText("##blacklist",marker.fields.blacklist); if (changed) then dowrite = true end
	if (GUI:Button("Blacklist Target")) then
		local target = Player:GetTarget()
		if (table.valid(target)) then
			if (marker.fields.blacklist == "") then
				marker.fields.blacklist = tostring(target.contentid)
			else
				if (not string.find(marker.fields.blacklist,tostring(target.contentid))) then
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
		maxlevel = 60,
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
	
	GUI:PushItemWidth(75)
	GUI:Text("Gather Time");
	marker.fields.duration, changed = GUI:InputText("##duration",marker.fields.duration); if (changed) then dowrite = true end
	GUI:PopItemWidth()

	GUI:PushItemWidth(75)
	GUI:Text("Node Level");
	marker.fields.mincontentlevel, changed = GUI:InputText("##mincontentlevel",marker.fields.mincontentlevel); GUI:SameLine(0,10); if (changed) then dowrite = true end
	GUI:Text(" - "); GUI:SameLine(0,10)
	marker.fields.maxcontentlevel, changed = GUI:InputText("##maxcontentlevel",marker.fields.maxcontentlevel); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(200)
	GUI:Text("Gather Items");
	marker.fields.item1, changed = GUI:InputText("##item1",marker.fields.item1); if (changed) then dowrite = true end
	marker.fields.item2, changed = GUI:InputText("##item2",marker.fields.item2); if (changed) then dowrite = true end
	marker.fields.item3, changed = GUI:InputText("##item3",marker.fields.item3); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(75)
	marker.fields.gardening, changed = GUI:Checkbox("Gardening Items",marker.fields.gardening); if (changed) then dowrite = true end
	marker.fields.chocofood, changed = GUI:Checkbox("Chocobo Food",marker.fields.chocofood); if (changed) then dowrite = true end
	marker.fields.rares, changed = GUI:Checkbox("Gardening Items",marker.fields.rares); if (changed) then dowrite = true end
	marker.fields.specialrares, changed = GUI:Checkbox("Gardening Items",marker.fields.specialrares); if (changed) then dowrite = true end
	
	marker.fields.usestealth, changed = GUI:Checkbox("Stealth",marker.fields.usestealth); if (changed) then dowrite = true end
	GUI:SameLine(0,10)
	marker.fields.dangerousarea, changed = GUI:Checkbox("Dangerous",marker.fields.dangerousarea); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(200)
	GUI:Text("Node Whitelist");
	marker.fields.whitelist, changed = GUI:InputText("##whitelist",marker.fields.whitelist); if (changed) then dowrite = true end
	if (GUI:Button("Whitelist Node")) then
		local target = Player:GetTarget()
		if (table.valid(target)) then
			if (marker.fields.whitelist == "") then
				marker.fields.whitelist = tostring(target.contentid)
			else
				if (not string.find(marker.fields.whitelist,tostring(target.contentid))) then
					marker.fields.whitelist = marker.fields.whitelist..";"..tostring(target.contentid)
				end
			end
			dowrite = true
		end
	end
	
	GUI:Text("Node Blacklist");
	marker.fields.blacklist, changed = GUI:InputText("##blacklist",marker.fields.blacklist); if (changed) then dowrite = true end
	if (GUI:Button("Blacklist Node")) then
		local target = Player:GetTarget()
		if (table.valid(target)) then
			if (marker.fields.blacklist == "") then
				marker.fields.blacklist = tostring(target.contentid)
			else
				if (not string.find(marker.fields.blacklist,tostring(target.contentid))) then
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

function ffxiv_marker_mgr.BuildGather()
	local fields = {
		minlevel = 1,
		maxlevel = 60,
		maxradius = 100,
		mincontentlevel = 1,
		maxcontentlevel = 60,
		maxradius = 0,
		item1 = "",
		item2 = "",
		item3 = "",
		whitelist = "",
		blacklist = "",
		maps = "Any",
		gardening = true,
		chocofood = true,
		rares = true,
		specialrares = true,
		favoritem = 0,
		usestealth = true,
		dangerousarea = false,
		skillprofile = GetString("None"),
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
	
	GUI:PushItemWidth(75)
	GUI:Text("Fish Time");
	marker.fields.duration, changed = GUI:InputText("##duration",marker.fields.duration); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(75)
	marker.fields.usemooch, changed = GUI:Checkbox("Use Mooch",marker.fields.usemooch); if (changed) then dowrite = true end
	marker.fields.usepatience, changed = GUI:Checkbox("Use Patience I",marker.fields.usepatience); if (changed) then dowrite = true end
	marker.fields.usepatience2, changed = GUI:Checkbox("Use Patience II",marker.fields.usepatience2); if (changed) then dowrite = true end
	marker.fields.usechum, changed = GUI:Checkbox("Use Chum",marker.fields.usechum); if (changed) then dowrite = true end
	
	marker.fields.usestealth, changed = GUI:Checkbox("Stealth",marker.fields.usestealth); if (changed) then dowrite = true end
	GUI:SameLine(0,10)
	marker.fields.dangerousarea, changed = GUI:Checkbox("Dangerous",marker.fields.dangerousarea); if (changed) then dowrite = true end
	GUI:PopItemWidth()
	
	GUI:PushItemWidth(200)
	GUI:Text("Moochable Fish");
	marker.fields.moochables, changed = GUI:InputText("##moochables",marker.fields.moochables); if (changed) then dowrite = true end
	
	GUI:Text("Whitelist Fish");
	marker.fields.whitelist, changed = GUI:InputText("##whitelist",marker.fields.whitelist); if (changed) then dowrite = true end
	marker.fields.whitelistHQ, changed = GUI:InputText("##whitelistHQ",marker.fields.whitelistHQ); if (changed) then dowrite = true end
	
	GUI:Text("Blacklist Fish");
	marker.fields.blacklist, changed = GUI:InputText("##blacklist",marker.fields.blacklist); if (changed) then dowrite = true end
	marker.fields.blacklistHQ, changed = GUI:InputText("##blacklistHQ",marker.fields.blacklistHQ); if (changed) then dowrite = true end

	GUI:PopItemWidth()
	
	if (dowrite) then
		ml_marker_mgr.WriteMarkerFile()
	end
end

function ffxiv_marker_mgr.BuildFishing()
	local fields = {
		minlevel = 1,
		maxlevel = 60,
		maxradius = 100,
		bait = "",
		usemooch = true,
		usepatience = false,
		usepatience2 = false,
		usechum = false,
		moochables = "",
		whitelist = "",
		whitelistHQ = "",
		blacklist = "",
		blacklistHQ = "",
		usestealth = true,
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

RegisterEventHandler("Module.Initalize",ffxiv_marker_mgr.HandleInit)
-- Main config file of GW2Minion
ffxiv_radar = {}
ffxiv_radar.GUI = {
	open = false,
	visible = true,
}
ffxiv_radar.lastUpdate = 0
ffxiv_radar.lastList = {}

-- Module Event Handler
function ffxiv_radar.ModuleInit()	
	gRadar3d = ffxivminion.GetSetting("gRadar3d",false)
	gRadar3dHP = ffxivminion.GetSetting("gRadar3d",true)
	gRadarCustomFilter = ffxivminion.GetSetting("gRadarCustomFilter","")	
	gRadarAllObjects = ffxivminion.GetSetting("gRadarAllObjects",true)
	gRadarHuntSRankHW = ffxivminion.GetSetting("gRadarHuntSRankHW",true)
	gRadarHuntARankHW = ffxivminion.GetSetting("gRadarHuntARankHW",true)
	gRadarHuntBRankHW = ffxivminion.GetSetting("gRadarHuntBRankHW",true)
	gRadarHuntSRankARR = ffxivminion.GetSetting("gRadarHuntSRankARR",true)
	gRadarHuntARankARR = ffxivminion.GetSetting("gRadarHuntARankARR",true)
	gRadarHuntBRankARR = ffxivminion.GetSetting("gRadarHuntBRankARR",true)
	gRadarAttackables = ffxivminion.GetSetting("gRadarAttackables",true)
	gRadarGatherables = ffxivminion.GetSetting("gRadarGatherables",true)
	gRadarFriendlies = ffxivminion.GetSetting("gRadarFriendlies",true)
	gRadarEventObjects = ffxivminion.GetSetting("gRadarEventObjects",true)
end

function ffxiv_radar.Draw(event, ticks )
	local gamestate = GetGameState()
	if (gamestate ~= FFXIV.GAMESTATE.INGAME ) then
		return false
	end
	
	if ( ffxiv_radar.GUI.open  ) then 
		GUI:SetNextWindowPosCenter(GUI.SetCond_Appearing)
		GUI:SetNextWindowSize(500,400,GUI.SetCond_FirstUseEver) --set the next window size, only on first ever
		ffxiv_radar.GUI.visible, ffxiv_radar.GUI.open = GUI:Begin("Radar", ffxiv_radar.GUI.open)
		if ( ffxiv_radar.GUI.visible ) then 
			GUI_Capture(GUI:Checkbox("Enable Radar",gRadar3d),"gRadar3d");
			GUI_Capture(GUI:Checkbox("Enable HP Bars",gRadar3dHP),"gRadar3dHP");
			GUI:Separator()
			GUI_Capture(GUI:Checkbox("All Entities",gRadarAllObjects),"gRadarAllObjects")			
			GUI_Capture(GUI:Checkbox("Attackables",gRadarAttackables),"gRadarAttackables")
			GUI_Capture(GUI:Checkbox("Gatherables",gRadarGatherables),"gRadarGatherables")
			GUI_Capture(GUI:Checkbox("Friendlies",gRadarFriendlies),"gRadarFriendlies")
			GUI_Capture(GUI:Checkbox("Event Objects",gRadarEventObjects),"gRadarEventObjects")
			
			GUI:Separator()
			GUI:Columns(4)
			GUI:SetColumnOffset(1,125); GUI:SetColumnOffset(2,250); GUI:SetColumnOffset(3,375); GUI:SetColumnOffset(4,500); 
			GUI:Text("Hunt - HW"); GUI:NextColumn()
			GUI_Capture(GUI:Checkbox("S Ranks##HW",gRadarHuntSRankHW),"gRadarHuntSRankHW"); GUI:NextColumn()
			GUI_Capture(GUI:Checkbox("A Ranks##HW",gRadarHuntARankHW),"gRadarHuntARankHW"); GUI:NextColumn()
			GUI_Capture(GUI:Checkbox("B Ranks##HW",gRadarHuntBRankHW),"gRadarHuntBRankHW"); GUI:NextColumn()
			
			GUI:Text("Hunt - ARR"); GUI:NextColumn()
			GUI_Capture(GUI:Checkbox("S Ranks##ARR",gRadarHuntSRankARR),"gRadarHuntSRankARR"); GUI:NextColumn()
			GUI_Capture(GUI:Checkbox("A Ranks##ARR",gRadarHuntARankARR),"gRadarHuntARankARR"); GUI:NextColumn()
			GUI_Capture(GUI:Checkbox("B Ranks##ARR",gRadarHuntBRankARR),"gRadarHuntBRankARR"); GUI:NextColumn()

			GUI:Columns(1)
			GUI:Separator()
		end
		GUI:End()
	end
	
	if (gRadar3d) then
		local drawables = ffxiv_radar.GetDrawableEntities()
		if (table.valid(drawables)) then
			local maxWidth, maxHeight = GUI:GetScreenSize()
			
			local tags = {
				red = GUI:ColorConvertFloat4ToU32(0.9,0.1,0.1,1),
				black = GUI:ColorConvertFloat4ToU32(0,0,0,1),
				white = GUI:ColorConvertFloat4ToU32(1,1,1,1),
				blue = GUI:ColorConvertFloat4ToU32(0.2,0.2,1,1),
				purple = GUI:ColorConvertFloat4ToU32(0.8,0.2,1,1),
				pink = GUI:ColorConvertFloat4ToU32(1,0.4,1,1),
				green = GUI:ColorConvertFloat4ToU32(0.8,1,0.4,1),
				yellow = GUI:ColorConvertFloat4ToU32(1,1,0.5,1),
			}
			
			GUI:SetNextWindowPos(0, 0, GUI.SetCond_Always)
			GUI:SetNextWindowSize(maxWidth,maxHeight,GUI.SetCond_Always) --set the next window size
			local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
			GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], 0)
			flags = (GUI.WindowFlags_NoInputs + GUI.WindowFlags_NoBringToFrontOnFocus + GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
			GUI:Begin("Radar - 3D - Draw Space", true, flags)	
			
			for i, entity in pairs(drawables) do
				local screenPos = RenderManager:WorldToScreen(entity.pos)
				if (table.valid(screenPos)) then
					GUI:AddCircleFilled(screenPos.x - 8, screenPos.y + 8, 5, tags[entity.tag])
					GUI:AddText(screenPos.x, screenPos.y, tags.yellow, "["..entity.name.."]["..tostring(round(entity.distance2d,1)).."]")
					if (gRadar3dHP and table.valid(entity.hp) and entity.hp.max > 0 and entity.targetable) then
						GUI:AddRect(screenPos.x, screenPos.y + 15, screenPos.x + 100, screenPos.y + 25, tags.white)
						GUI:AddRectFilled(screenPos.x + 2, screenPos.y + 17, (screenPos.x + (100 * (entity.hp.percent/100)) - 2), screenPos.y + 23, tags.green)
						GUI:AddText(screenPos.x + 100, screenPos.y + 13, tags.white, tostring(entity.hp.percent).."%")
					end
				end
			end
			
			GUI:End()
			GUI:PopStyleColor()
		end
	end
end

function ffxiv_radar.GetDrawableEntities()
	if (Now() > ffxiv_radar.lastUpdate + 25) then
		ffxiv_radar.lastList = {}
		ffxiv_radar.lastUpdate = Now()
		local scan = MEntityList("")
		if (table.valid(scan)) then
			if (table.size(scan) > 30) then
				ffxiv_radar.lastUpdate = ffxiv_radar.lastUpdate + 275
				ffxiv_radar.lastUpdate = ffxiv_radar.lastUpdate + (3 * table.size(scan))
			end
			
			for i, entity in pairs(scan) do
				local tag = ""
				local doDraw = false
				
				if ((gRadarAllObjects or gRadarAttackables) and entity.attackable) then
					doDraw = true
					tag = "red"
					if (entity.fateid ~= 0) then
						tag = "pink"
					end
				elseif ((gRadarAllObjects or gRadarGatherables) and entity.gatherable) then
					doDraw = true
					tag = "yellow"
				elseif (((gRadarAllObjects or gRadarHuntSRankHW) and MultiComp(entity.contentid,"4374,4375,4376,4377,4378,4380")) or 
					((gRadarAllObjects or gRadarHuntBRankHW) and MultiComp(entity.contentid,"4362,4363,4364,4365,4366,4367,4368,4369,4370,4371,4372,4373")) or 
					((gRadarAllObjects or gRadarHuntARankHW) and MultiComp(entity.contentid,"4350,4351,4352,4353,4354,4355,4356,4357,4358,4359,4360,4361")) or 
					((gRadarAllObjects or gRadarHuntSRankARR) and MultiComp(entity.contentid,"2953,2954,2955,2956,2957,2958,2959,2960,2961,2962,2963,2964,2965,2966,2967,2968,2969")) or
					((gRadarAllObjects or gRadarHuntARankARR) and MultiComp(entity.contentid,"2936,2937,2938,2939,2940,2941,2942,2943,2944,2945,2946,2947,2948,2949,2950,2951,2952")) or 
					((gRadarAllObjects or gRadarHuntBRankARR) and MultiComp(entity.contentid,"2919,2920,2921,2922,2923,2924,2925,2926,2927,2928,2929,2930,2931,2932,2933,2934,2935")))
				then
					tag = "purple"
					doDraw = true
				elseif ((gRadarAllObjects or gRadarFriendlies) and entity.friendly and (entity.type == 1 or entity.type == 3)) then
					if (entity.type == 1) then
						tag = "blue"
					else
						tag = "green"
					end
					doDraw = true
				elseif ((gRadarAllObjects or gRadarEventObjects) and (entity.type == 0 or entity.type == 5 or entity.type == 7)) then
					tag = "white"
					doDraw = true
				elseif (gRadarAllObjects) then
					tag = "black"
					doDraw = true
				end
					
				
				if (doDraw) then
					local dataset = { id = entity.id, contentid = entity.contentid, name = entity.name, pos = entity.pos, attackable = entity.attackable, gatherable = entity.gatherable, targetable = entity.targetable,
						distance2d = entity.distance2d, distance = entity.distance, ["type"] = entity.type, chartype = entity.chartype, fateid = entity.fateid, hp = entity.hp, tag = tag }
					table.insert(ffxiv_radar.lastList, dataset)
				end
			end
		end
	end
	return ffxiv_radar.lastList
end

function ffxiv_radar.ToggleMenu()
	ffxiv_radar.GUI.open = not ffxiv_radar.GUI.open
end

-- Register Event Handlers
RegisterEventHandler("Module.Initalize",ffxiv_radar.ModuleInit)
RegisterEventHandler("Gameloop.Draw", ffxiv_radar.Draw)
RegisterEventHandler("Radar.toggle", ffxiv_radar.ToggleMenu)
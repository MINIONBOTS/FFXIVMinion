--[[
	PoTD Traps/Hoards will only show with a pomander active since SE patched them. 
	To add to the Custom list use the ContentID this can be found using the dev window or from another source like xivdb.
	You can also get this info automaticly using the Get target option.
	If you have any important/helpful ContentID's please let me know so I can add it into the preset list :D
	Made by HusbandoMax
]]--
ffxiv_radar = {}
ffxiv_radar.GUI = {
	open = false,
	visible = true,
}
-- Check and load Custom List + Preset data.
local ColourAlpha = 0.8 -- Alpha value for transparent colours.
local lastupdate = 0
local RadarTable = {}
-- Colour Data
local Colours = {}
local CustomTransparency = {}
local CloseColourR,CloseColourG,CloseColourB = 1,0,0

local HPBarStyles = {"New", "Original"}
local MainWindowPosx, MainWindowPosy, MainWindowSizex, MainWindowSizey

ffxiv_radar.Tabs = {
	["CurrentSelected"] = 1,
	["CurrentHovered"] = 0,
	["TabData"] = {"Filters","Custom List","Settings"},
	["SelectedColour"] = { ["r"] = 0, ["g"] = 1, ["b"] = 0, ["a"] = 1 },
	["StandardColour"] = { ["r"] = 1, ["g"] = 0, ["b"] = 0, ["a"] = 1 },
	["HoveredColour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 0, ["a"] = 1 },
}

function ffxiv_radar.Init()
	ffxiv_radar.SetData()
	ffxiv_radar.SetColours()
	ffxiv_radar.Settings()
	ffxiv_radar.UpdateColours()
end

function ffxiv_radar.DrawCall(event, ticks )
	if not(GUI_NewWindow) then
		local gamestate = GetGameState()
		if ( gamestate == FFXIV.GAMESTATE.INGAME ) then 
			if ( ffxiv_radar.GUI.open  ) then 
				GUI:SetNextWindowSize(580,340,GUI.SetCond_FirstUseEver) --SetCond_FirstUseEver
				ffxiv_radar.GUI.visible, ffxiv_radar.GUI.open = GUI:Begin("FFXIV Radar", ffxiv_radar.GUI.open)
				if ( ffxiv_radar.GUI.visible ) then
					MainWindowPosx, MainWindowPosy = GUI:GetWindowPos()
					MainWindowSizex, MainWindowSizey = GUI:GetWindowSize()
					-- GUI Start.
					GUI:Columns(2,"Main Tab") GUI:SetColumnOffset(1, MainWindowSizex/2)
					GUI:AlignFirstTextHeightToWidgets() GUI:Text("Show 3D Radar:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Show 3D radar." ) end
					GUI:SameLine()
					ffxiv_radar.Enable3D, changed  = GUI:Checkbox("##Enable3D", ffxiv_radar.Enable3D) if (changed) then Settings.ffxiv_radar.Enable3D = ffxiv_radar.Enable3D end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Show 3D radar." ) end
					GUI:NextColumn()
					GUI:AlignFirstTextHeightToWidgets() GUI:Text("Show 2D Radar:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Show 2D radar." ) end
					GUI:SameLine()
					ffxiv_radar.Enable2D, changed  = GUI:Checkbox("##Enable2D", ffxiv_radar.Enable2D) if (changed) then Settings.ffxiv_radar.Enable2D = ffxiv_radar.Enable2D end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Show 2D radar." ) end
					GUI:Columns()
					GUI:Separator()
					-- Tabs.
					local Tabs = ffxiv_radar.Tabs
					if table.valid(Tabs) then
						local TotalTabCount = table.size(Tabs.TabData)
						for i,e in pairs(Tabs.TabData) do
							if i == Tabs.CurrentSelected then 
								GUI:TextColored(Tabs.SelectedColour.r,Tabs.SelectedColour.g,Tabs.SelectedColour.b,Tabs.SelectedColour.a,e)
							elseif i == Tabs.CurrentHovered then 
								GUI:TextColored(Tabs.HoveredColour.r,Tabs.HoveredColour.g,Tabs.HoveredColour.b,Tabs.HoveredColour.a,e)
								if (GUI:IsItemHovered()) then 
									Tabs.CurrentHovered = i
									if (GUI:IsMouseClicked(0)) then Tabs.CurrentSelected = i end
								else
									Tabs.CurrentHovered = 0
								end
							else
								GUI:TextColored(Tabs.StandardColour.r,Tabs.StandardColour.g,Tabs.StandardColour.b,Tabs.StandardColour.a,e)
								if (GUI:IsItemHovered()) then 
									Tabs.CurrentHovered = i
									if (GUI:IsMouseClicked(0)) then Tabs.CurrentSelected = i end
								end
							end
							if i < TotalTabCount then GUI:SameLine() GUI:Text("|") GUI:SameLine() end
						end
						GUI:Separator()	
						-- Tab Contents.
						if Tabs.CurrentSelected == 1 then -- Filters Tab
							for i,e in ipairs(ffxiv_radar.Options) do
								if GUI:TreeNode(e.CategoryName.."##RadarFilter") then
									GUI:Separator()
									GUI:Columns(3)
									for k,v in ipairs(e) do
										v.Enabled, changed = GUI:Checkbox("##Enabled_"..v.Name,v.Enabled) if (changed) then Settings.ffxiv_radar.Options = ffxiv_radar.Options RadarTable = {} end
										GUI:SameLine()
										GUI:ColorEditMode(GUI.ColorEditMode_NoInputs+GUI.ColorEditMode_AlphaBar)
										v.Colour.r,v.Colour.g,v.Colour.b,v.Colour.a,changed = GUI:ColorEdit4("##Colour_"..v.Name,v.Colour.r,v.Colour.g,v.Colour.b,v.Colour.a) 
										if (changed) then v.ColourU32 = GUI:ColorConvertFloat4ToU32(v.Colour.r,v.Colour.g,v.Colour.b,v.Colour.a) Settings.ffxiv_radar.Options = ffxiv_radar.Options RadarTable = {} end
										GUI:SameLine()
										GUI:AlignFirstTextHeightToWidgets() GUI:Text(v.Name)
										GUI:NextColumn()
									end
									GUI:Columns()
									GUI:TreePop()
								end
								GUI:Separator()
							end
						elseif Tabs.CurrentSelected == 2 then -- Custom List Tab.
							-- Add to custom list.
							-- Column names.
							GUI:Columns(5) GUI:SetColumnOffset(1, 100) GUI:SetColumnOffset(2, 160) GUI:SetColumnOffset(3, MainWindowSizex-185) GUI:SetColumnOffset(4, MainWindowSizex-100) 	GUI:Text("ContentID") GUI:NextColumn() GUI:Text("Colour") GUI:NextColumn() GUI:Text("Custom Name") GUI:NextColumn() GUI:Text("Get Target") GUI:NextColumn() GUI:Text("Add")
							GUI:NextColumn() -- Column data.
							GUI:PushItemWidth(85) ffxiv_radar.ContentID = GUI:InputText("##ContentID", ffxiv_radar.ContentID) GUI:PopItemWidth() GUI:NextColumn()
							GUI:ColorEditMode(GUI.ColorEditMode_NoInputs+GUI.ColorEditMode_AlphaBar)
							ffxiv_radar.AddColour.Colour.r,ffxiv_radar.AddColour.Colour.g,ffxiv_radar.AddColour.Colour.b,ffxiv_radar.AddColour.Colour.a,changed = GUI:ColorEdit4("##AddColour",ffxiv_radar.AddColour.Colour.r,ffxiv_radar.AddColour.Colour.g,ffxiv_radar.AddColour.Colour.b,ffxiv_radar.AddColour.Colour.a) 
							if (changed) then ffxiv_radar.AddColour.ColourU32 = GUI:ColorConvertFloat4ToU32(ffxiv_radar.AddColour.Colour.r,ffxiv_radar.AddColour.Colour.g,ffxiv_radar.AddColour.Colour.b,ffxiv_radar.AddColour.Colour.a) end
							GUI:NextColumn()
							local Size = GUI:GetContentRegionAvail()
							GUI:PushItemWidth(Size) ffxiv_radar.CustomName = GUI:InputText("##CustomName", ffxiv_radar.CustomName) GUI:PopItemWidth() GUI:NextColumn()
							if GUI:Button("Get", 40, 20) then 
								local playerTarget = Player:GetTarget()
								if playerTarget ~= nil then
									ffxiv_radar.ContentID = playerTarget.contentid
								end
							end
							GUI:NextColumn()
							if GUI:Button("Add", 70, 20) then 
								if ffxiv_radar.ContentID ~= "" then
									ffxiv_radar.CustomList[tonumber(ffxiv_radar.ContentID)] = { ["Name"] = ffxiv_radar.CustomName, ["Enabled"] = true, ["Colour"] = ffxiv_radar.AddColour.Colour, ["ColourU32"] = ffxiv_radar.AddColour.ColourU32 }
									Settings.ffxiv_radar.CustomList = ffxiv_radar.CustomList
									RadarTable = {}
								end
							end
							GUI:Columns()
							-- Custom list.
							GUI:Separator() -- Column names.
							GUI:Columns(5) GUI:SetColumnOffset(1, 100) GUI:SetColumnOffset(2, 160) GUI:SetColumnOffset(3, MainWindowSizex-185) GUI:SetColumnOffset(4, MainWindowSizex-100) GUI:Text("ContentID") GUI:NextColumn() GUI:Text("Colour") GUI:NextColumn() GUI:Text("Custom Name") GUI:NextColumn() GUI:Text("Enabled") GUI:NextColumn() GUI:Text("Delete") GUI:Columns()
							GUI:Separator()-- Column data.
							GUI:Columns(5) GUI:SetColumnOffset(1, 100) GUI:SetColumnOffset(2, 160) GUI:SetColumnOffset(3, MainWindowSizex-185) GUI:SetColumnOffset(4, MainWindowSizex-100)
							for i,e in pairs(ffxiv_radar.CustomList) do
								GUI:AlignFirstTextHeightToWidgets() GUI:Text(i) GUI:NextColumn()
								-- Current colours.
								e.Colour.r,e.Colour.g,e.Colour.b,e.Colour.a,changed = GUI:ColorEdit4("##AddColour"..i,e.Colour.r,e.Colour.g,e.Colour.b,e.Colour.a) 
								if (changed) then e.ColourU32 = GUI:ColorConvertFloat4ToU32(e.Colour.r,e.Colour.g,e.Colour.b,e.Colour.a) Settings.ffxiv_radar.CustomList = ffxiv_radar.CustomList RadarTable = {} end
								GUI:NextColumn()
								-- Set custom name.
								GUI:PushItemWidth(Size) 
								e.Name, changed = GUI:InputText("##CustomName"..i, e.Name) if (changed) then Settings.ffxiv_radar.CustomList = ffxiv_radar.CustomList RadarTable = {} end 
								GUI:PopItemWidth() 
								GUI:NextColumn()
								-- Toggles.
								e.Enabled, changed = GUI:Checkbox("##Enabled"..i, e.Enabled) if (changed) then Settings.ffxiv_radar.CustomList = ffxiv_radar.CustomList RadarTable = {} end 
								GUI:NextColumn()
								-- Delete entry.
								if GUI:Button("Delete##"..i, 70, 20) then ffxiv_radar.CustomList[i] = nil Settings.ffxiv_radar.CustomList = ffxiv_radar.CustomList RadarTable = {} end 
								GUI:NextColumn()
							end
							GUI:Columns()
							GUI:TreePop()
						elseif Tabs.CurrentSelected == 3 then -- Settings Tab
							GUI:Columns(2) GUI:SetColumnOffset(1, 250) -- Column names.
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("3D - Show HP Bars:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Show HP bars on the 3D radar." ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("3D - Black Behind Names:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Puts a Transparent black bar behind the names for easy reading." ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("3D - HP Bar Style:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Change the style of the HP Bars used on the 3D radar." ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("3D - Toggle Scan Distance:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Toggle Max Distance to show on 3D radar. (Distance Set Below)" ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("3D - Scan Distance:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Max Distance to show on 3D radar. (About 120 is the max for normal entities)" ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("3D - Custom String:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Enable Custom Strings to be used on the 3D radar" ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("3D - Custom String Format:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Custom Strings formatted as below.\nName,ContentID,ID,Distance,Distance2D,Type,HP" ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("2D - Show Names:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Show entity names on the 2D radar." ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("2D - Marker Shapes:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Change the shape of the markers used within the 2D radar." ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("2D - Enable Click Through:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Allow clickthrough of the 2D radar.(Must be disabled to move radar)" ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("2D - Radar Scale (%%):") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Scale the size of the 2D radar." ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("2D - Scan Distance:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Max Distance to show on 2D radar. (About 120 is the max for normal entities)" ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("2D - Radar Opacity:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Change the Opacity/Transparency of the 2D radar." ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("Text Scale:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Change the Text Scale for the 2D and 3D radar." ) end
							GUI:AlignFirstTextHeightToWidgets() GUI:Text("Add Presets to Custom List:") if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Add Presets into the Custom List, this will not overwrite existing entries." ) end
							GUI:NextColumn() -- Settings stuff.
							local Size = GUI:GetContentRegionAvail()
							ffxiv_radar.ShowHPBars, changed = GUI:Checkbox("##ShowHPBars", ffxiv_radar.ShowHPBars) if (changed) then Settings.ffxiv_radar.ShowHPBars = ffxiv_radar.ShowHPBars end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Show HP bars on the 3D radar." ) end
							ffxiv_radar.BlackBars, changed = GUI:Checkbox("##BlackBars", ffxiv_radar.BlackBars) if (changed) then Settings.ffxiv_radar.BlackBars = ffxiv_radar.BlackBars end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Puts a Transparent black bar behind the names for easy reading." ) end
							GUI:PushItemWidth(Size) ffxiv_radar.HPBarStyle, changed = GUI:Combo("##HPBarStyle", ffxiv_radar.HPBarStyle, HPBarStyles) if (changed) then Settings.ffxiv_radar.HPBarStyle = ffxiv_radar.HPBarStyle end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Change the style of the HP Bars used on the 3D radar." ) end GUI:PopItemWidth()
							ffxiv_radar.EnableRadarDistance3D, changed = GUI:Checkbox("##EnableRadarDistance3D", ffxiv_radar.EnableRadarDistance3D) if (changed) then Settings.ffxiv_radar.EnableRadarDistance3D = ffxiv_radar.EnableRadarDistance3D end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Toggle Max Distance to show on 3D radar. (Distance Set Below)" ) end
							GUI:PushItemWidth(Size) ffxiv_radar.RadarDistance3D, changed = GUI:SliderInt("##RadarDistance3D", ffxiv_radar.RadarDistance3D,0,300) if (changed) then Settings.ffxiv_radar.RadarDistance3D = ffxiv_radar.RadarDistance3D end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Max Distance to show on 3D radar. (About 120 is the max for normal entities)" ) end GUI:PopItemWidth()
							ffxiv_radar.CustomStringEnabled, changed = GUI:Checkbox("##CustomStringEnabled",ffxiv_radar.CustomStringEnabled) if (changed) then Settings.ffxiv_radar.CustomStringEnabled = ffxiv_radar.CustomStringEnabled end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Enable Custom Strings to be used on the 3D radar" ) end
							GUI:PushItemWidth(Size) ffxiv_radar.CustomString, changed = GUI:InputText("##CustomString", ffxiv_radar.CustomString) if (changed) then Settings.ffxiv_radar.CustomString = ffxiv_radar.CustomString end  if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Custom Strings formatted as below.\nName,ContentID,ID,Distance,Distance2D,Type,HP" ) end GUI:PopItemWidth()
							ffxiv_radar.MiniRadarNames, changed = GUI:Checkbox("##MiniRadarNames", ffxiv_radar.MiniRadarNames) if (changed) then Settings.ffxiv_radar.MiniRadarNames = ffxiv_radar.MiniRadarNames end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Show entity names on the 2D radar." ) end
							ffxiv_radar.Shape, changed = GUI:RadioButton("Circle##Shape", ffxiv_radar.Shape,1) GUI:SameLine() if (changed) then Settings.ffxiv_radar.Shape = ffxiv_radar.Shape end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Change the shape of the markers used within the 2D radar to a Cricle." ) end
							ffxiv_radar.Shape, changed = GUI:RadioButton("Square##Shape", ffxiv_radar.Shape,2) if (changed) then Settings.ffxiv_radar.Shape = ffxiv_radar.Shape end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Change the shape of the markers used within the 2D radar to a Square." ) end
							ffxiv_radar.ClickThrough, changed = GUI:Checkbox("##ClickThrough", ffxiv_radar.ClickThrough) if (changed) then Settings.ffxiv_radar.ClickThrough = ffxiv_radar.ClickThrough end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Allow clickthrough of the 2D radar.(Must be disabled to move radar)" ) end
							GUI:PushItemWidth(Size) ffxiv_radar.RadarSize, changed = GUI:SliderInt("##RadarSize", ffxiv_radar.RadarSize,20,1000) if (changed) then Settings.ffxiv_radar.RadarSize = ffxiv_radar.RadarSize end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Scale the size of the 2D radar." ) end GUI:PopItemWidth()
							GUI:PushItemWidth(Size) ffxiv_radar.RadarDistance2D, changed = GUI:SliderInt("##RadarDistance2D", ffxiv_radar.RadarDistance2D,0,300) if (changed) then Settings.ffxiv_radar.RadarDistance2D = ffxiv_radar.RadarDistance2D end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Max Distance to show on 2D radar. (About 120 is the max for normal entities)" ) end GUI:PopItemWidth()
							GUI:PushItemWidth(Size) ffxiv_radar.Opacity, changed = GUI:SliderInt("##Opacity", ffxiv_radar.Opacity,0,100) if (changed) then Settings.ffxiv_radar.Opacity = ffxiv_radar.Opacity ffxiv_radar.UpdateColours() end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Change the Opacity/Transparency of the 2D radar." ) end GUI:PopItemWidth()
							GUI:PushItemWidth(Size) ffxiv_radar.TextScale, changed = GUI:SliderInt("##TextScale", ffxiv_radar.TextScale,50,250) if (changed) then Settings.ffxiv_radar.TextScale = ffxiv_radar.TextScale end if ( GUI:IsItemHovered() ) then GUI:SetTooltip( "Change the Text Scale for the 2D and 3D radar." ) end GUI:PopItemWidth()
							if GUI:Button("Add Preset Data",Size,20) then ffxiv_radar.AddPreset() end
							GUI:Columns()
						end
					end
				end 
				GUI:End()
			end -- End of main GUI.
			
			-- Check radar toggles and form list.
			-- Overlay/Radar GUI.
			if ffxiv_radar.Enable3D or ffxiv_radar.Enable2D then
				ffxiv_radar.Radar() -- Check table
				if ffxiv_radar.Enable3D == true then -- 3D Overlay.
					-- GUI Data.
					local maxWidth, maxHeight = GUI:GetScreenSize()
					GUI:SetNextWindowPos(0, 0, GUI.SetCond_Always)
					GUI:SetNextWindowSize(maxWidth,maxHeight,GUI.SetCond_Always)
					local winBG = GUI:GetStyle().colors[GUI.Col_WindowBg]
					GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], 0)
					flags = (GUI.WindowFlags_NoInputs + GUI.WindowFlags_NoBringToFrontOnFocus + GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
					GUI:Begin("ffxiv_radar 3D Overlay", true, flags)	
					if ValidTable(RadarTable) then -- Check Radar table is valid and write to screen.
						for i,e in pairs(RadarTable) do
						local eColour = e.Colour
						local eHP = e.hp
						local eType = e.type
						local eDistance = math.round(e.distance,0)
						local eDistance2D = string.format("%.1f",e.distance2d)
						-- Limit render distance if enabled.
						if ffxiv_radar.EnableRadarDistance3D and eDistance <= (ffxiv_radar.RadarDistance3D-4) or not ffxiv_radar.EnableRadarDistance3D then
							local Scale
							Scale = (0.9-math.round((eDistance/250),3))
							if Scale < 0.5 then Scale = (0.5*(ffxiv_radar.TextScale/100)) else Scale = (Scale*(ffxiv_radar.TextScale/100)) end
							GUI:SetWindowFontScale(Scale)
							local RoundedPos = { x = math.round(e.pos.x,2), y = math.round(e.pos.y,2), z = math.round(e.pos.z,2) }
							local screenPos = RenderManager:WorldToScreen(RoundedPos)
							if (table.valid(screenPos)) then
								local EntityString = ""
								if ffxiv_radar.CustomStringEnabled then
									EntityString = ""
									StringTable = string.totable(ffxiv_radar.CustomString,",")
									if ValidTable(StringTable) then
										for stringindex,stringval in pairs(StringTable) do
											local StringLower = string.lower(stringval)
											if StringLower == "name" then EntityString = EntityString.."["..e.name.."]"
											elseif StringLower == "distance" then EntityString = EntityString.."["..eDistance.."]"
											elseif StringLower == "id" then EntityString = EntityString.."["..e.id.."]"
											elseif StringLower == "contentid" then EntityString = EntityString.."["..e.contentid.."]"
											elseif StringLower == "distance2d" then EntityString = EntityString.."["..eDistance2D.."]"
											elseif StringLower == "type" then EntityString = EntityString.."["..eType.."]"
											elseif StringLower == "hp" then EntityString = EntityString.."["..eHP.current.."/"..eHP.max.."]"
											end
										end
									end
								else
									EntityString = "["..e.name.."]".."["..tostring(math.round(eDistance,0)).."]"
								end
								local stringsize = (GUI:CalcTextSize(EntityString))
								local stringheight = GUI:GetWindowFontSize()+2
								-- Render GUI.
								if ffxiv_radar.BlackBars then GUI:AddRectFilled((screenPos.x-(stringsize/2)), screenPos.y, (screenPos.x+(stringsize/2))+2, screenPos.y + stringheight, Colours.Transparent.black.colourval,3) end -- Black Behind Name.
									GUI:AddCircleFilled(screenPos.x-((stringsize)/2) - 8*Scale, screenPos.y + (stringheight/2), 5*Scale, eColour) -- Filled Point Marker (Transparent).
									GUI:AddCircle(screenPos.x-((stringsize)/2) - 8*Scale, screenPos.y + (stringheight/2), 5*Scale,eColour) -- Point Marker Outline (Solid).
									GUI:AddText(screenPos.x-((stringsize)/2), screenPos.y-1, eColour, EntityString) -- Name Text
									if (ffxiv_radar.ShowHPBars and table.valid(eHP) and eHP.max > 0 and eHP.percent <= 100 and e.targetable and e.alive and (eType == 1 or eType == 2 or eType == 3)) then -- HP bar stuff.
										if ffxiv_radar.HPBarStyle == 1 then
											-- Colour HP bar
											local Rectangle = {
												x1 = math.round((screenPos.x - (62*Scale)),0),
												y1 = math.round((screenPos.y + (14*Scale)+(2*Scale)),0),
												x2 = math.round((screenPos.x + (62*Scale)),0),
												y2 = math.round((screenPos.y + (30*Scale)+(2*Scale)),0),
											}
											local Rectangle2 = {
												x1 = math.round((screenPos.x - (62 * Scale)),0),
												y1 = math.round((screenPos.y + (14 * Scale)+(2*Scale)),0),
												x2 = math.round((screenPos.x + (-62 + (124 * (eHP.percent/100))) * Scale),0),
												y2 = math.round((screenPos.y + (30 * Scale)+(2*Scale)),0),
											}
											local HPBar = GUI:ColorConvertFloat4ToU32(0,1,0,0.6)
											--local HPBar = GUI:ColorConvertFloat4ToU32(math.abs((-100+eHP.percent)/100), eHP.percent/100, 0, 1) -- Different Colouring.
											if eHP.percent >= 50 then
												HPBar = GUI:ColorConvertFloat4ToU32(2-((eHP.percent/100)*2),1,0,ColourAlpha-0.2)
											else
												HPBar = GUI:ColorConvertFloat4ToU32(1,((eHP.percent*2)/100),0,ColourAlpha-0.2)
											end
											GUI:AddRectFilled(Rectangle2.x1, Rectangle2.y1, Rectangle2.x2, Rectangle2.y2, HPBar,3) -- HP Bar Coloured.
											GUI:AddRect(Rectangle.x1, Rectangle.y1, Rectangle.x2, Rectangle.y2, Colours.Transparent.white.colourval,3) -- HP Bar Outline.
											local hpsize = GUI:CalcTextSize(tostring(eHP.percent))
											GUI:AddText(screenPos.x-(hpsize/2), screenPos.y + (15*Scale)+(2*Scale), eColour, tostring(eHP.percent).."%") -- Percentage Text. eColour.colourval
										elseif ffxiv_radar.HPBarStyle == 2 then
											-- Colour HP bar
											local Rectangle = {
												x1 = math.round((screenPos.x - (82*Scale)),0),
												y1 = math.round((screenPos.y + (17*Scale)+(2*Scale)),0),
												x2 = math.round((screenPos.x + (42*Scale)),0),
												y2 = math.round((screenPos.y + (23*Scale)+(2*Scale)),0),
											}
											local Rectangle2 = {
												x1 = math.round((screenPos.x - (82 * Scale)),0),
												y1 = math.round((screenPos.y + (17 * Scale)+(2*Scale)),0),
												x2 = math.round((screenPos.x + (-82 + (124 * (eHP.percent/100))) * Scale),0),
												y2 = math.round((screenPos.y + (23 * Scale)+(2*Scale)),0),
											}
											local HPBar = GUI:ColorConvertFloat4ToU32(0,1,0,0.6)
											--local HPBar = GUI:ColorConvertFloat4ToU32(math.abs((-100+eHP.percent)/100), eHP.percent/100, 0, 1) -- Different Colouring.
											if eHP.percent >= 50 then
												HPBar = GUI:ColorConvertFloat4ToU32(2-((eHP.percent/100)*2),1,0,ColourAlpha)
											else
												HPBar = GUI:ColorConvertFloat4ToU32(1,((eHP.percent*2)/100),0,ColourAlpha)
											end
											GUI:AddRectFilled(Rectangle2.x1, Rectangle2.y1, Rectangle2.x2, Rectangle2.y2, HPBar) -- HP Bar Coloured.
											GUI:AddRect(Rectangle.x1, Rectangle.y1, Rectangle.x2, Rectangle.y2, Colours.Transparent.white.colourval) -- HP Bar Outline.
											--if ffxiv_radar.BlackBars then local hpsize = GUI:CalcTextSize(tostring(eHP.percent.."%%")) GUI:AddRectFilled(screenPos.x+(50*Scale), screenPos.y+(16*Scale),screenPos.x+(47*Scale)+hpsize, screenPos.y+(13*Scale)+stringheight, Colours.Transparent.black.colourval,3) end -- Black Behind Name.
											GUI:AddText(screenPos.x+(45*Scale)+2, screenPos.y+(13*Scale)+(2*Scale), eColour, tostring(eHP.percent).."%") -- Percentage Text. eColour.colourval
										end
									end
								end
							end
							GUI:SetWindowFontScale(1)
						end
					end
					GUI:End()
					GUI:PopStyleColor()
				end -- End of 3D radar GUI.
				-- 2D Radar.
				if ffxiv_radar.Enable2D == true then
					-- GUI Data
					local maxWidth, maxHeight = GUI:GetScreenSize()
					GUI:SetNextWindowPos(0, 0, GUI.SetCond_FirstUseEver)
					GUI:SetNextWindowSize(200*(ffxiv_radar.RadarSize/100)+100,200*(ffxiv_radar.RadarSize/100)+100,GUI.SetCond_Always) -- Scalable GUI.
					local winBG = GUI:GetStyle().colors[GUI.Col_WindowBg]
					GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], 0)
					if ffxiv_radar.ClickThrough == true then -- 2D Radar Clickthrough toggle check.
						flags = (GUI.WindowFlags_NoInputs + GUI.WindowFlags_NoBringToFrontOnFocus + GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
					else
						flags = (GUI.WindowFlags_NoBringToFrontOnFocus + GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
					end
					GUI:Begin("ffxiv_radar 2D Overlay", true, flags)	
					-- Radar Math.
					local PlayerPOS = Player.pos
					local WindowPosx, WindowPosy = GUI:GetWindowPos()
					local WindowSizex, WindowSizey = GUI:GetWindowSize()
					WindowPosx, WindowPosy = WindowPosx+25, WindowPosy+50 -- Gives a little extra room to allow for names
					WindowSizex, WindowSizey = WindowSizex-100, WindowSizey-100
					local CenterX = WindowPosx+(WindowSizex/2)
					local CenterY = WindowPosy+(WindowSizey/2)
					local angle = ConvertHeading(PlayerPOS.h)+1.5708 -- Weird compass rotation (90° Clockwise fix) o.O
					local headingx = (math.cos(angle)*-1) -- More weird compass shit (Anticlockwise fix)...
					local headingy = (math.sin(angle)) -- More weird compass shit...
					-- Radar Render.
					GUI:AddCircleFilled(CenterX, CenterY, ((WindowSizex/2)-4), CustomTransparency.black.colourval, 200) -- 2D Radar Fill (Transparent with slider).
					GUI:AddLine(WindowPosx+(WindowSizex/2), WindowPosy+4, WindowPosx+(WindowSizex/2), WindowPosy+WindowSizey-4, Colours.Transparent.red.colourval, 2.0) -- Y Axis Line (Transparent)
					GUI:AddLine(WindowPosx+4, WindowPosy+(WindowSizey/2), WindowPosx+WindowSizex-4, WindowPosy+(WindowSizey/2), Colours.Transparent.red.colourval, 2.0) -- X Axis Line (Transparent)
					GUI:AddCircle(CenterX, CenterY, ((WindowSizex/2)-4), Colours.Transparent.lightgrey.colourval, 200) -- 2D Radar Outline (Transparent).
					GUI:AddCircle(CenterX, CenterY, ((WindowSizex/2)-5), Colours.Transparent.lightgrey.colourval, 201) -- 2D Radar Outline (Transparent).
					local MouseX,MouseY = GUI:GetMousePos()
					--d("Mouse:"..MouseX..":"..MouseY)
					if ValidTable(RadarTable) then -- Check Radar table is valid and write to screen.
						for i,e in pairs(RadarTable) do
							local MouseOver = false
							local eColour = e.Colour
							local ePOS = e.pos
							local edistance2d = e.distance2d
							-- Limit render distance slider.
							local EntityPosX = math.round(((ePOS.x-PlayerPOS.x)/ffxiv_radar.RadarDistance2D)*(WindowSizex/2),0) + CenterX -- Entity X POS within GUI
							local EntityPosY = math.round(((ePOS.z-PlayerPOS.z)/ffxiv_radar.RadarDistance2D)*(WindowSizey/2),0) + CenterY -- Entity Y POS within GUI
							if edistance2d > (ffxiv_radar.RadarDistance2D) then 
							
							EntityPosX = (((ePOS.x-PlayerPOS.x)/edistance2d)*(WindowSizex/2)) + CenterX -- Entity X POS within GUI
							EntityPosY = (((ePOS.z-PlayerPOS.z)/edistance2d)*(WindowSizey/2)) + CenterY -- Entity Y POS within GUI
							end
							local PointCalculation = math.sqrt(math.pow(MouseX-EntityPosX,2) + math.pow(MouseY-EntityPosY,2))
							--if PointCalculation < (4*(ffxiv_radar.TextScale/100)) then d("YESSS") end
							--d(EntityPosX..":"..EntityPosY)
							if ffxiv_radar.Shape == 1 then
								GUI:AddCircleFilled(EntityPosX,EntityPosY, (4*(ffxiv_radar.TextScale/100)), eColour) -- Filled Point Marker (Transparent).
								GUI:AddCircle(EntityPosX,EntityPosY, (4*(ffxiv_radar.TextScale/100)), eColour) -- Point Marker Outline (Transparent).
								if PointCalculation <= (4*(ffxiv_radar.TextScale/100)) then MouseOver = true end
							elseif ffxiv_radar.Shape == 2 then
								local RectScale = math.round((4*(ffxiv_radar.TextScale/100)),0)
								local Rectx1,Recty1,Rectx2,Recty2,Rectx3,Recty3,Rectx4,Recty4 = EntityPosX-RectScale, EntityPosY-RectScale, EntityPosX+RectScale, EntityPosY-RectScale, EntityPosX-RectScale, EntityPosY+RectScale, EntityPosX+RectScale, EntityPosY+RectScale
								local Pos1Dist,Pos2Dist,Pos3Dist,Pos4Dist = math.sqrt(math.pow(MouseX-Rectx1,2) + math.pow(MouseY-Recty1,2)), math.sqrt(math.pow(MouseX-Rectx2,2) + math.pow(MouseY-Recty2,2)), math.sqrt(math.pow(MouseX-Rectx3,2) + math.pow(MouseY-Recty3,2)), math.sqrt(math.pow(Rectx1-Rectx4,2) + math.pow(MouseY-Recty4,2))
								local RectHypot = math.sqrt(math.pow(Rectx1-Rectx4,2) + math.pow(Recty1-Recty4,2))
								GUI:AddRectFilled(EntityPosX-RectScale, EntityPosY-RectScale, EntityPosX+RectScale, EntityPosY+RectScale, eColour)
								GUI:AddRect(EntityPosX-RectScale, EntityPosY-RectScale, EntityPosX+RectScale, EntityPosY+RectScale, eColour)
								if Pos1Dist <= RectHypot and Pos2Dist <= RectHypot and Pos3Dist <= RectHypot and Pos4Dist <= RectHypot then MouseOver = true end
							end
							-- Name Toggle.
							if ffxiv_radar.MiniRadarNames or (ffxiv_radar.Shape and MouseOver) or (not ffxiv_radar.Shape and MouseOver) then
								GUI:SetWindowFontScale((0.8*(ffxiv_radar.TextScale/100)))
								GUI:AddText(EntityPosX+(8*(ffxiv_radar.TextScale/100)), EntityPosY-(5*(ffxiv_radar.TextScale/100)), eColour, e.name) -- Entity name (Transparent).
								GUI:SetWindowFontScale(1)
							end
						end
					end
					GUI:AddLine(CenterX, CenterY, CenterX+(headingx*((WindowSizex/2)-4)), CenterY+(headingy*((WindowSizey/2)-4)), Colours.Transparent.yellow.colourval, 2.0) -- Heading Line (Transparent)
					GUI:End()
					GUI:PopStyleColor()
				end -- End of 2D radar.
			end
		end
	end
end

function ffxiv_radar.Radar() -- Table
	--if Now() > lastupdate + 25 then
	--lastupdate = Now()
		local EntityTable = EntityList("")
		if ValidTable(EntityTable) then
			-- Update/Clean table.
			if ValidTable(RadarTable) then
				for radarindex,radardata in pairs(RadarTable) do
					local GetEntityList = EntityList:Get(radardata.id)
					if ValidTable(GetEntityList) then -- Update Data.
						-- Fix for attackable targets not being attackable until closer range.
						if not radardata.attackable and GetEntityList.attackable then RadarTable[radarindex] = nil end 
						-- Fix for all nodes returning cangather regardless of class when first loaded. 
						if radardata.cangather ~= GetEntityList.cangather then RadarTable[radarindex] = nil end 
						-- Fix for friendly targets not being friendly until closer range.
						if not radardata.friendly and GetEntityList.friendly then RadarTable[radarindex] = nil end 
						-- Fix for names not showing on NPC's right away...
						if not radardata.CustomName and radardata.name ~= GetEntityList.name then radardata.name = GetEntityList.name end
						radardata.hp = GetEntityList.hp
						radardata.pos = GetEntityList.pos
						radardata.distance2d = GetEntityList.distance2d
						radardata.distance = GetEntityList.distance
						radardata.alive = GetEntityList.alive
					else -- Remove Old Data.
						RadarTable[radarindex] = nil
					end
				end
			end
			-- Add New Data.
			for i,e in pairs(EntityTable) do
				local ID = e.id
				if RadarTable[ID] == nil then
					local Colour = ""
					local Draw = false
					local CustomName = false
					local econtentid = e.contentid
					local eattackable = e.attackable
					local efriendly = e.friendly
					local etype = e.type
					local ename
					--if ffxiv_radar.InvalidNames and ename ~= "?" and ename ~= "" or not ffxiv_radar.InvalidNames then
						if ffxiv_radar.CustomList[econtentid] ~= nil and ffxiv_radar.CustomList[econtentid].Enabled then -- Custom List
							Colour = ffxiv_radar.CustomList[econtentid].ColourU32
							if ffxiv_radar.CustomList[econtentid].Name ~= "" then d("Updating Name") ename = ffxiv_radar.CustomList[econtentid].Name end -- Custom name overwite.
							Draw = true
							CustomName = true
						-- Hunts.
						elseif ((ffxiv_radar.Options[1][1].Enabled or ffxiv_radar.Options[2][3].Enabled) and ffxiv_radar.HuntFilters.ARR.S[econtentid] == true) then -- ARR S Rank.
							Colour = ffxiv_radar.Options[2][3].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][1].Enabled or ffxiv_radar.Options[2][2].Enabled) and ffxiv_radar.HuntFilters.ARR.A[econtentid] == true) then -- ARR A Rank.
							Colour = ffxiv_radar.Options[2][2].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][1].Enabled or ffxiv_radar.Options[2][1].Enabled) and ffxiv_radar.HuntFilters.ARR.B[econtentid] == true) then -- ARR B Rank.
							Colour = ffxiv_radar.Options[2][1].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][1].Enabled or ffxiv_radar.Options[2][6].Enabled) and ffxiv_radar.HuntFilters.HW.S[econtentid] == true) then -- HW S Rank.
							Colour = ffxiv_radar.Options[2][6].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][1].Enabled or ffxiv_radar.Options[2][5].Enabled) and ffxiv_radar.HuntFilters.HW.A[econtentid] == true) then -- HW A Rank.
							Colour = ffxiv_radar.Options[2][5].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][1].Enabled or ffxiv_radar.Options[2][4].Enabled) and ffxiv_radar.HuntFilters.HW.B[econtentid] == true) then -- HW B Rank.
							Colour = ffxiv_radar.Options[2][4].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][1].Enabled or ffxiv_radar.Options[2][9].Enabled) and ffxiv_radar.HuntFilters.StB.S[econtentid] == true) then -- StB S Rank.
							Colour = ffxiv_radar.Options[2][9].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][1].Enabled or ffxiv_radar.Options[2][8].Enabled) and ffxiv_radar.HuntFilters.StB.A[econtentid] == true) then -- StB A Rank.
							Colour = ffxiv_radar.Options[2][8].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][1].Enabled or ffxiv_radar.Options[2][7].Enabled) and ffxiv_radar.HuntFilters.StB.B[econtentid] == true) then -- StB B Rank.
							Colour = ffxiv_radar.Options[2][7].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][1].Enabled or ffxiv_radar.Options[2][12].Enabled) and ffxiv_radar.HuntFilters.ShB.S[econtentid] == true) then -- ShB S/SS Rank.
							Colour = ffxiv_radar.Options[2][12].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][1].Enabled or ffxiv_radar.Options[2][11].Enabled) and ffxiv_radar.HuntFilters.ShB.A[econtentid] == true) then -- ShB A Rank.
							Colour = ffxiv_radar.Options[2][11].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][1].Enabled or ffxiv_radar.Options[2][10].Enabled) and ffxiv_radar.HuntFilters.ShB.B[econtentid] == true) then -- ShB B Rank.
							Colour = ffxiv_radar.Options[2][10].ColourU32
							Draw = true
						-- End of hunts.
						-- Start Of Deep Dungeon
						elseif (ffxiv_radar.Options[3][1].Enabled and ffxiv_radar.DeepDungeonFilters.Passage[econtentid] == true) then -- Passage
							Colour = ffxiv_radar.Options[3][1].ColourU32
							Draw = true
						elseif (ffxiv_radar.Options[3][2].Enabled and ffxiv_radar.DeepDungeonFilters.Return[econtentid] == true) then -- Return
							Colour = ffxiv_radar.Options[3][2].ColourU32
							Draw = true
						elseif (ffxiv_radar.Options[3][3].Enabled and ffxiv_radar.DeepDungeonFilters.SilverChest[econtentid] == true) then -- Silver Chest
							Colour = ffxiv_radar.Options[3][3].ColourU32
							Draw = true
						elseif (ffxiv_radar.Options[3][4].Enabled and ffxiv_radar.DeepDungeonFilters.GoldChest[econtentid] == true) then -- Gold Chest
							Colour = ffxiv_radar.Options[3][4].ColourU32
							Draw = true
						elseif (ffxiv_radar.Options[3][5].Enabled and ffxiv_radar.DeepDungeonFilters.BronzeChest[econtentid] == true) then -- Bronze Chest
							Colour = ffxiv_radar.Options[3][5].ColourU32
							Draw = true
						elseif (ffxiv_radar.Options[3][6].Enabled and ffxiv_radar.DeepDungeonFilters.BandedCoffer[econtentid] == true) then -- Banded Coffer
							Colour = ffxiv_radar.Options[3][6].ColourU32
							Draw = true
						elseif (ffxiv_radar.Options[3][7].Enabled and ffxiv_radar.DeepDungeonFilters.Hoard[econtentid] == true) then -- Hoard
							Colour = ffxiv_radar.Options[3][7].ColourU32
							Draw = true
						elseif (ffxiv_radar.Options[3][8].Enabled and ffxiv_radar.DeepDungeonFilters.Traps[econtentid] == true) then -- Traps
							Colour = ffxiv_radar.Options[3][8].ColourU32
							Draw = true
						-- End Of Deep Dungeon
						elseif ((ffxiv_radar.Options[1][8].Enabled or ffxiv_radar.Options[1][2].Enabled) and eattackable and e.fateid ~= 0) then -- Attackable Fates.
							Colour = ffxiv_radar.Options[1][2].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][8].Enabled or ffxiv_radar.Options[1][1].Enabled) and eattackable) then -- Attackable.
							Colour = ffxiv_radar.Options[1][1].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][8].Enabled or ffxiv_radar.Options[1][3].Enabled) and e.cangather) then -- Gatherable.
							Colour = ffxiv_radar.Options[1][3].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][8].Enabled or ffxiv_radar.Options[1][4].Enabled) and efriendly and etype == 1) then -- Players.
							Colour = ffxiv_radar.Options[1][4].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][8].Enabled or ffxiv_radar.Options[1][5].Enabled) and efriendly and etype == 3) then -- NPCs.
							Colour = ffxiv_radar.Options[1][5].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][8].Enabled or ffxiv_radar.Options[1][7].Enabled) and ((econtentid >= 2007965 and econtentid <= 2008024) or (econtentid >= 2006186 and econtentid <= 2006234) or (econtentid >= 2006186 and econtentid <= 2006234))) then -- Event objects.
							Colour = ffxiv_radar.Options[1][7].ColourU32
							Draw = true
						elseif ((ffxiv_radar.Options[1][8].Enabled or ffxiv_radar.Options[1][6].Enabled) and (etype == 0 or etype == 5 or etype == 7)) then -- Event objects.
							Colour = ffxiv_radar.Options[1][6].ColourU32
							Draw = true
						elseif ffxiv_radar.Options[1][8].Enabled then -- All remaining entities.
							Colour = ffxiv_radar.Options[1][8].ColourU32
							Draw = true
						end
						if Draw then -- Write to table.
							ename = ename or e.name
							local dataset = { CustomName = CustomName, id = ID, attackable = eattackable, contentid = econtentid, name = ename, pos = e.pos, distance2d = e.distance2d, distance = e.distance, alive = e.alive, hp = e.hp, ["type"] = etype, Colour = Colour, targetable = e.targetable, friendly = e.friendly, cangather = e.cangather }
							RadarTable[ID] = dataset
						end
					--end
				end 
			end
		end
	--end
end

function ffxiv_radar.AddPreset()
	local PresetData = {
		[2007744] = { ["Name"] = "[Diadem] Buried Coffer", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2005808] = { ["Name"] = "[PoTD] Treasure Coffer - Trap", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2006020] = { ["Name"] = "[PoTD] Treasure Coffer Silver - Mimic", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2006022] = { ["Name"] = "[PoTD] Treasure Coffer Gold - Mimic", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007182] = { ["Name"] = "[PoTD] Trap - Landmine", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007183] = { ["Name"] = "[PoTD] Trap - Luring", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007184] = { ["Name"] = "[PoTD] Trap - Enfeebling", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007186] = { ["Name"] = "[PoTD] Trap - Toading", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007357] = { ["Name"] = "[PoTD] Treasure Coffer Silver", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007358] = { ["Name"] = "[PoTD] Treasure Coffer Gold", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007542] = { ["Name"] = "[PoTD] Accursed Hoard", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007188] = { ["Name"] = "[PoTD] Cairn of Passage", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007187] = { ["Name"] = "[PoTD] Cairn of Return", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
	}
	for i,e in pairs(PresetData) do
		if ffxiv_radar.CustomList[i] == nil then ffxiv_radar.CustomList[i] = e end
	end
	Settings.ffxiv_radar.CustomList = ffxiv_radar.CustomList
end

function ffxiv_radar.SetColours()
	Colours = {
		Solid = {
			white = { r = 1.0, g = 1.0, b = 1.0, a = 1.0, name = white, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,1.0,1.0,1.0), radar = GUI:ColorConvertFloat4ToU32(1.0,1.0,1.0,0.7) },
			lightgrey = { r = 0.8, g = 0.8, b = 0.8, a = 1.0, name = lightgrey, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.8,0.8,0.8,1.0), radar = GUI:ColorConvertFloat4ToU32(0.8,0.8,0.8,0.7) },
			silver = { r = 0.8, g = 0.8, b = 0.8, a = 1.0, name = silver, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.8,0.8,0.8,1.0), radar = GUI:ColorConvertFloat4ToU32(0.8,0.8,0.8,0.7) },
			gray = { r = 0.5, g = 0.5, b = 0.5, a = 1.0, name = gray, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.5,0.5,0.5,1.0), radar = GUI:ColorConvertFloat4ToU32(0.5,0.5,0.5,0.7) },
			black = { r = 0.0, g = 0.0, b = 0.0, a = 1.0, name = black, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.0,0.0,1.0), radar = GUI:ColorConvertFloat4ToU32(0.0,0.0,0.0,0.7) },
			maroon = { r = 0.5, g = 0.0, b = 0.0, a = 1.0, name = maroon, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.5,0.0,0.0,1.0), radar = GUI:ColorConvertFloat4ToU32(0.5,0.0,0.0,0.7) },
			brown = { r = 0.6, g = 0.2, b = 0.2, a = 1.0, name = brown, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.6,0.2,0.2,1.0), radar = GUI:ColorConvertFloat4ToU32(0.6,0.2,0.2,0.7) },
			red = { r = 1.0, g = 0.0, b = 0.0, a = 1.0, name = red, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.0,0.0,1.0), radar = GUI:ColorConvertFloat4ToU32(1.0,0.0,0.0,0.7) },
			orange = { r = 1.0, g = 0.5, b = 0.0, a = 1.0, name = orange, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.5,0.0,1.0), radar = GUI:ColorConvertFloat4ToU32(1.0,0.5,0.0,0.7) },
			gold = { r = 1.0, g = 0.8, b = 0.0, a = 1.0, name = gold, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.8,0.0,1.0), radar = GUI:ColorConvertFloat4ToU32(1.0,0.8,0.0,0.7) },
			yellow = { r = 1.0, g = 1.0, b = 0.0, a = 1.0, name = yellow, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,1.0,0.0,1.0), radar = GUI:ColorConvertFloat4ToU32(1.0,1.0,0.0,0.7) },
			limegreen = { r = 0.0, g = 1.0, b = 0.0, a = 1.0, name = limegreen, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,1.0,0.0,1.0), radar = GUI:ColorConvertFloat4ToU32(0.0,1.0,0.0,0.7) },
			emeraldgreen = { r = 0.0, g = 0.8, b = 0.3, a = 1.0, name = emeraldgreen, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.8,0.3,1.0), radar = GUI:ColorConvertFloat4ToU32(0.0,0.8,0.3,0.7) },
			green = { r = 0.0, g = 0.5, b = 0.0, a = 1.0, name = green, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.5,0.0,1.0), radar = GUI:ColorConvertFloat4ToU32(0.0,0.5,0.0,0.7) },
			forestgreen = { r = 0.1, g = 0.5, b = 0.1, a = 1.0, name = forestgreen, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.1,0.5,0.1,1.0), radar = GUI:ColorConvertFloat4ToU32(0.1,0.5,0.1,0.7) },
			manganeseblue = { r = 0.0, g = 0.7, b = 0.6, a = 1.0, name = manganeseblue, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.7,0.6,1.0), radar = GUI:ColorConvertFloat4ToU32(0.0,0.7,0.6,0.7) },
			turquoise = { r = 0.3, g = 0.9, b = 0.8, a = 1.0, name = turquoise, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.3,0.9,0.8,1.0), radar = GUI:ColorConvertFloat4ToU32(0.3,0.9,0.8,0.7) },
			cyan = { r = 0.0, g = 1.0, b = 1.0, a = 1.0, name = cyan, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,1.0,1.0,1.0), radar = GUI:ColorConvertFloat4ToU32(0.0,1.0,1.0,0.7) },
			blue = { r = 0.0, g = 0.0, b = 1.0, a = 1.0, name = blue, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.0,1.0,1.0), radar = GUI:ColorConvertFloat4ToU32(0.0,0.0,1.0,0.7) },
			navy = { r = 0.0, g = 0.0, b = 0.5, a = 1.0, name = navy, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.0,0.5,1.0), radar = GUI:ColorConvertFloat4ToU32(0.0,0.0,0.5,0.7) },
			indigo = { r = 0.3, g = 0.0, b = 0.5, a = 1.0, name = indigo, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.3,0.0,0.5,1.0), radar = GUI:ColorConvertFloat4ToU32(0.3,0.0,0.5,0.7) },
			blueviolet = { r = 0.5, g = 0.2, b = 0.9, a = 1.0, name = blueviolet, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.5,0.2,0.9,1.0), radar = GUI:ColorConvertFloat4ToU32(0.5,0.2,0.9,0.7) },
			darkviolet = { r = 0.6, g = 0.0, b = 0.8, a = 1.0, name = darkviolet, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.6,0.0,0.8,1.0), radar = GUI:ColorConvertFloat4ToU32(0.6,0.0,0.8,0.7) },
			purple = { r = 0.5, g = 0.0, b = 0.5, a = 1.0, name = purple, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.5,0.0,0.5,1.0), radar = GUI:ColorConvertFloat4ToU32(0.5,0.0,0.5,0.7) },
			magenta = { r = 1.0, g = 0.0, b = 1.0, a = 1.0, name = magenta, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.0,1.0,1.0), radar = GUI:ColorConvertFloat4ToU32(1.0,0.0,1.0,0.7) },
			hotpink = { r = 1.0, g = 0.4, b = 0.7, a = 1.0, name = hotpink, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.4,0.7,1.0), radar = GUI:ColorConvertFloat4ToU32(1.0,0.4,0.7,0.7) },
			pink = { r = 1.0, g = 0.8, b = 0.8, a = 1.0, name = pink, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.8,0.8,1.0), radar = GUI:ColorConvertFloat4ToU32(1.0,0.8,0.8,0.7) },
		},
		Transparent = {
			white = { r = 1.0, g = 1.0, b = 1.0, a = ColourAlpha, name = white, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,1.0,1.0,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(1.0,1.0,1.0,ColourAlpha-0.2) },
			lightgrey = { r = 0.8, g = 0.8, b = 0.8, a = ColourAlpha, name = lightgrey, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.8,0.8,0.8,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.8,0.8,0.8,ColourAlpha-0.2) },
			silver = { r = 0.8, g = 0.8, b = 0.8, a = ColourAlpha, name = silver, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.8,0.8,0.8,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.8,0.8,0.8,ColourAlpha-0.2) },
			gray = { r = 0.5, g = 0.5, b = 0.5, a = ColourAlpha, name = gray, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.5,0.5,0.5,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.5,0.5,0.5,ColourAlpha-0.2) },
			black = { r = 0.0, g = 0.0, b = 0.0, a = ColourAlpha, name = black, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.0,0.0,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.0,0.0,0.0,ColourAlpha-0.2) },
			maroon = { r = 0.5, g = 0.0, b = 0.0, a = ColourAlpha, name = maroon, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.5,0.0,0.0,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.5,0.0,0.0,ColourAlpha-0.2) },
			brown = { r = 0.6, g = 0.2, b = 0.2, a = ColourAlpha, name = brown, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.6,0.2,0.2,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.6,0.2,0.2,ColourAlpha-0.2) },
			red = { r = 1.0, g = 0.0, b = 0.0, a = ColourAlpha, name = red, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.0,0.0,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(1.0,0.0,0.0,ColourAlpha-0.2) },
			orange = { r = 1.0, g = 0.5, b = 0.0, a = ColourAlpha, name = orange, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.5,0.0,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(1.0,0.5,0.0,ColourAlpha-0.2) },
			gold = { r = 1.0, g = 0.8, b = 0.0, a = ColourAlpha, name = gold, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.8,0.0,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(1.0,0.8,0.0,ColourAlpha-0.2) },
			yellow = { r = 1.0, g = 1.0, b = 0.0, a = ColourAlpha, name = yellow, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,1.0,0.0,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(1.0,1.0,0.0,ColourAlpha-0.2) },
			limegreen = { r = 0.0, g = 1.0, b = 0.0, a = ColourAlpha, name = limegreen, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,1.0,0.0,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.0,1.0,0.0,ColourAlpha-0.2) },
			emeraldgreen = { r = 0.0, g = 0.8, b = 0.3, a = ColourAlpha, name = emeraldgreen, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.8,0.3,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.0,0.8,0.3,ColourAlpha-0.2) },
			green = { r = 0.0, g = 0.5, b = 0.0, a = ColourAlpha, name = green, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.5,0.0,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.0,0.5,0.0,ColourAlpha-0.2) },
			forestgreen = { r = 0.1, g = 0.5, b = 0.1, a = ColourAlpha, name = forestgreen, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.1,0.5,0.1,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.1,0.5,0.1,ColourAlpha-0.2) },
			manganeseblue = { r = 0.0, g = 0.7, b = 0.6, a = ColourAlpha, name = manganeseblue, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.7,0.6,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.0,0.7,0.6,ColourAlpha-0.2) },
			turquoise = { r = 0.3, g = 0.9, b = 0.8, a = ColourAlpha, name = turquoise, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.3,0.9,0.8,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.3,0.9,0.8,ColourAlpha-0.2) },
			cyan = { r = 0.0, g = 1.0, b = 1.0, a = ColourAlpha, name = cyan, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,1.0,1.0,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.0,1.0,1.0,ColourAlpha-0.2) },
			blue = { r = 0.0, g = 0.0, b = 1.0, a = ColourAlpha, name = blue, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.0,1.0,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.0,0.0,1.0,ColourAlpha-0.2) },
			navy = { r = 0.0, g = 0.0, b = 0.5, a = ColourAlpha, name = navy, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.0,0.5,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.0,0.0,0.5,ColourAlpha-0.2) },
			indigo = { r = 0.3, g = 0.0, b = 0.5, a = ColourAlpha, name = indigo, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.3,0.0,0.5,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.3,0.0,0.5,ColourAlpha-0.2) },
			blueviolet = { r = 0.5, g = 0.2, b = 0.9, a = ColourAlpha, name = blueviolet, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.5,0.2,0.9,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.5,0.2,0.9,ColourAlpha-0.2) },
			darkviolet = { r = 0.6, g = 0.0, b = 0.8, a = ColourAlpha, name = darkviolet, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.6,0.0,0.8,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.6,0.0,0.8,ColourAlpha-0.2) },
			purple = { r = 0.5, g = 0.0, b = 0.5, a = ColourAlpha, name = purple, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.5,0.0,0.5,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(0.5,0.0,0.5,ColourAlpha-0.2) },
			magenta = { r = 1.0, g = 0.0, b = 1.0, a = ColourAlpha, name = magenta, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.0,1.0,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(1.0,0.0,1.0,ColourAlpha-0.2) },
			hotpink = { r = 1.0, g = 0.4, b = 0.7, a = ColourAlpha, name = hotpink, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.4,0.7,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(1.0,0.4,0.7,ColourAlpha-0.2) },
			pink = { r = 1.0, g = 0.8, b = 0.8, a = ColourAlpha, name = pink, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.8,0.8,ColourAlpha), radar = GUI:ColorConvertFloat4ToU32(1.0,0.8,0.8,ColourAlpha-0.2) },
		},
	}
end

function ffxiv_radar.UpdateColours() -- Transparency Slider Colours (Only used on 2D Radar background atm).
	local CustomTransparencyAlpha = (tonumber(ffxiv_radar.Opacity)/100)
	CustomTransparency = {
		white = { r = 1.0, g = 1.0, b = 1.0, a = 1.0, name = white, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,1.0,1.0,CustomTransparencyAlpha) },
		lightgrey = { r = 0.8, g = 0.8, b = 0.8, a = 1.0, name = lightgrey, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.8,0.8,0.8,CustomTransparencyAlpha) },
		silver = { r = 0.8, g = 0.8, b = 0.8, a = 1.0, name = silver, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.8,0.8,0.8,CustomTransparencyAlpha) },
		gray = { r = 0.5, g = 0.5, b = 0.5, a = 1.0, name = gray, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.5,0.5,0.5,CustomTransparencyAlpha) },
		black = { r = 0.0, g = 0.0, b = 0.0, a = 1.0, name = black, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.0,0.0,CustomTransparencyAlpha) },
		maroon = { r = 0.5, g = 0.0, b = 0.0, a = 1.0, name = maroon, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.5,0.0,0.0,CustomTransparencyAlpha) },
		brown = { r = 0.6, g = 0.2, b = 0.2, a = 1.0, name = brown, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.6,0.2,0.2,CustomTransparencyAlpha) },
		red = { r = 1.0, g = 0.0, b = 0.0, a = 1.0, name = red, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.0,0.0,CustomTransparencyAlpha) },
		orange = { r = 1.0, g = 0.5, b = 0.0, a = 1.0, name = orange, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.5,0.0,CustomTransparencyAlpha) },
		gold = { r = 1.0, g = 0.8, b = 0.0, a = 1.0, name = gold, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.8,0.0,CustomTransparencyAlpha) },
		yellow = { r = 1.0, g = 1.0, b = 0.0, a = 1.0, name = yellow, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,1.0,0.0,CustomTransparencyAlpha) },
		limegreen = { r = 0.0, g = 1.0, b = 0.0, a = 1.0, name = limegreen, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,1.0,0.0,CustomTransparencyAlpha) },
		emeraldgreen = { r = 0.0, g = 0.8, b = 0.3, a = 1.0, name = emeraldgreen, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.8,0.3,CustomTransparencyAlpha) },
		green = { r = 0.0, g = 0.5, b = 0.0, a = 1.0, name = green, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.5,0.0,CustomTransparencyAlpha) },
		forestgreen = { r = 0.1, g = 0.5, b = 0.1, a = 1.0, name = forestgreen, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.1,0.5,0.1,CustomTransparencyAlpha) },
		manganeseblue = { r = 0.0, g = 0.7, b = 0.6, a = 1.0, name = manganeseblue, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.7,0.6,CustomTransparencyAlpha) },
		turquoise = { r = 0.3, g = 0.9, b = 0.8, a = 1.0, name = turquoise, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.3,0.9,0.8,CustomTransparencyAlpha) },
		cyan = { r = 0.0, g = 1.0, b = 1.0, a = 1.0, name = cyan, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,1.0,1.0,CustomTransparencyAlpha) },
		blue = { r = 0.0, g = 0.0, b = 1.0, a = 1.0, name = blue, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.0,1.0,CustomTransparencyAlpha) },
		navy = { r = 0.0, g = 0.0, b = 0.5, a = 1.0, name = navy, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.0,0.0,0.5,CustomTransparencyAlpha) },
		indigo = { r = 0.3, g = 0.0, b = 0.5, a = 1.0, name = indigo, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.3,0.0,0.5,CustomTransparencyAlpha) },
		blueviolet = { r = 0.5, g = 0.2, b = 0.9, a = 1.0, name = blueviolet, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.5,0.2,0.9,CustomTransparencyAlpha) },
		darkviolet = { r = 0.6, g = 0.0, b = 0.8, a = 1.0, name = darkviolet, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.6,0.0,0.8,CustomTransparencyAlpha) },
		purple = { r = 0.5, g = 0.0, b = 0.5, a = 1.0, name = purple, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(0.5,0.0,0.5,CustomTransparencyAlpha) },
		magenta = { r = 1.0, g = 0.0, b = 1.0, a = 1.0, name = magenta, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.0,1.0,CustomTransparencyAlpha) },
		hotpink = { r = 1.0, g = 0.4, b = 0.7, a = 1.0, name = hotpink, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.4,0.7,CustomTransparencyAlpha) },
		pink = { r = 1.0, g = 0.8, b = 0.8, a = 1.0, name = pink, colourtype = solid, colourval = GUI:ColorConvertFloat4ToU32(1.0,0.8,0.8,CustomTransparencyAlpha) },
	}
end

function ffxiv_radar.Settings()
	AddColour = Colours.Solid.white
	-- Radar Settings.
	if Settings.ffxiv_radar.ShowHPBars == nil then Settings.ffxiv_radar.ShowHPBars = true end
	ffxiv_radar.ShowHPBars = Settings.ffxiv_radar.ShowHPBars
	if Settings.ffxiv_radar.BlackBars == nil then Settings.ffxiv_radar.BlackBars = true end
	ffxiv_radar.BlackBars = Settings.ffxiv_radar.BlackBars
	ffxiv_radar.EnableRadarDistance3D = Settings.ffxiv_radar.EnableRadarDistance3D or false
	ffxiv_radar.RadarDistance3D = Settings.ffxiv_radar.RadarDistance3D or 100
	ffxiv_radar.MiniRadarNames = Settings.ffxiv_radar.MiniRadarNames or false
	ffxiv_radar.Shape = Settings.ffxiv_radar.Shape or 1
	ffxiv_radar.ClickThrough = Settings.ffxiv_radar.ClickThrough or false
	ffxiv_radar.RadarSize = Settings.ffxiv_radar.RadarSize or 100
	ffxiv_radar.RadarDistance2D = Settings.ffxiv_radar.RadarDistance2D or 100
	ffxiv_radar.Opacity = Settings.ffxiv_radar.Opacity or 70
	ffxiv_radar.TextScale = Settings.ffxiv_radar.TextScale or 100
	ffxiv_radar.HPBarStyle = Settings.ffxiv_radar.HPBarStyle or 1
	ffxiv_radar.CustomStringEnabled = Settings.ffxiv_radar.CustomStringEnabled or false
	ffxiv_radar.CustomString = Settings.ffxiv_radar.CustomString or "Name,Distance"
	-- General Filter Toggles.
	ffxiv_radar.Attackables = Settings.ffxiv_radar.Attackables or false
	ffxiv_radar.Fates = Settings.ffxiv_radar.Fates or false
	ffxiv_radar.Gatherables = Settings.ffxiv_radar.Gatherables or false
	ffxiv_radar.Players = Settings.ffxiv_radar.Players or false
	ffxiv_radar.NPCs = Settings.ffxiv_radar.NPCs or false
	ffxiv_radar.EventObjects = Settings.ffxiv_radar.EventObjects or false
	ffxiv_radar.AetherCurrents = Settings.ffxiv_radar.AetherCurrents or false
	ffxiv_radar.All = Settings.ffxiv_radar.All or false
	-- Radar Togglea.
	ffxiv_radar.Enable3D = Settings.ffxiv_radar.Enable3D or false
	ffxiv_radar.Enable2D = Settings.ffxiv_radar.Enable2D or false
	-- General Filter Colour Values.
	ffxiv_radar.AttackablesColour = Settings.ffxiv_radar.AttackablesColour or Colours.Solid.red
	ffxiv_radar.FatesColour = Settings.ffxiv_radar.FatesColour or Colours.Solid.pink
	ffxiv_radar.GatherablesColour = Settings.ffxiv_radar.GatherablesColour or Colours.Solid.green 
	ffxiv_radar.PlayersColour = Settings.ffxiv_radar.PlayersColour or Colours.Solid.blue
	ffxiv_radar.NPCsColour = Settings.ffxiv_radar.NPCsColour or Colours.Solid.yellow
	ffxiv_radar.EventObjectsColour = Settings.ffxiv_radar.EventObjectsColour or Colours.Solid.cyan
	ffxiv_radar.AetherCurrentsColour = Settings.ffxiv_radar.AetherCurrentsColour or Colours.Solid.white
	ffxiv_radar.AllColour = Settings.ffxiv_radar.AllColour or Colours.Solid.gray
	-- Hunt Filter Toggles.
	ffxiv_radar.HuntBRankARR = Settings.ffxiv_radar.HuntBRankARR or false
	ffxiv_radar.HuntARankARR = Settings.ffxiv_radar.HuntARankARR or false
	ffxiv_radar.HuntSRankARR = Settings.ffxiv_radar.HuntSRankARR or false
	ffxiv_radar.HuntBRankHW = Settings.ffxiv_radar.HuntBRankHW or false
	ffxiv_radar.HuntARankHW = Settings.ffxiv_radar.HuntARankHW or false
	ffxiv_radar.HuntSRankHW = Settings.ffxiv_radar.HuntSRankHW or false
	ffxiv_radar.HuntBRankSB = Settings.ffxiv_radar.HuntBRankSB or false
	ffxiv_radar.HuntARankSB = Settings.ffxiv_radar.HuntARankSB or false
	ffxiv_radar.HuntSRankSB = Settings.ffxiv_radar.HuntSRankSB or false
	-- Hunt Filter Colour Values.
	ffxiv_radar.HuntBRankARRColour = Settings.ffxiv_radar.HuntBRankARRColour or Colours.Solid.orange
	ffxiv_radar.HuntARankARRColour = Settings.ffxiv_radar.HuntARankARRColour or Colours.Solid.magenta
	ffxiv_radar.HuntSRankARRColour = Settings.ffxiv_radar.HuntSRankARRColour or Colours.Solid.white
	ffxiv_radar.HuntBRankHWColour = Settings.ffxiv_radar.HuntBRankHWColour or Colours.Solid.orange
	ffxiv_radar.HuntARankHWColour = Settings.ffxiv_radar.HuntARankHWColour or Colours.Solid.magenta
	ffxiv_radar.HuntSRankHWColour = Settings.ffxiv_radar.HuntSRankHWColour or Colours.Solid.white
	ffxiv_radar.HuntBRankSBColour = Settings.ffxiv_radar.HuntBRankSBColour or Colours.Solid.orange
	ffxiv_radar.HuntARankSBColour = Settings.ffxiv_radar.HuntARankSBColour or Colours.Solid.magenta
	ffxiv_radar.HuntSRankSBColour = Settings.ffxiv_radar.HuntSRankSBColour or Colours.Solid.white
end

function ffxiv_radar.SetData()
	ffxiv_radar.HuntFilters = {
		["ARR"] = {
			["S"] = {
				[2953] = true,
				[2954] = true,
				[2955] = true,
				[2956] = true,
				[2957] = true,
				[2958] = true,
				[2959] = true,
				[2960] = true,
				[2961] = true,
				[2962] = true,
				[2963] = true,
				[2964] = true,
				[2965] = true,
				[2966] = true,
				[2967] = true,
				[2968] = true,
				[2969] = true,
			},
			["A"] = {
				[2936] = true,
				[2937] = true,
				[2938] = true,
				[2939] = true,
				[2940] = true,
				[2941] = true,
				[2942] = true,
				[2943] = true,
				[2944] = true,
				[2945] = true,
				[2946] = true,
				[2947] = true,
				[2948] = true,
				[2949] = true,
				[2950] = true,
				[2951] = true,
				[2952] = true,
			},
			["B"] = {
				[2919] = true,
				[2920] = true,
				[2921] = true,
				[2922] = true,
				[2923] = true,
				[2924] = true,
				[2925] = true,
				[2926] = true,
				[2927] = true,
				[2928] = true,
				[2929] = true,
				[2930] = true,
				[2931] = true,
				[2932] = true,
				[2933] = true,
				[2934] = true,
				[2935] = true,
			},
		},
		["HW"] = {
			["S"] = {
				[4374] = true,
				[4375] = true,
				[4376] = true,
				[4377] = true,
				[4378] = true,
				[4380] = true,
			},
			["A"] = {
				[4362] = true,
				[4363] = true,
				[4364] = true,
				[4365] = true,
				[4366] = true,
				[4367] = true,
				[4368] = true,
				[4369] = true,
				[4370] = true,
				[4371] = true,
				[4372] = true,
				[4373] = true,
			},
			["B"] = {
				[4350] = true,
				[4351] = true,
				[4352] = true,
				[4353] = true,
				[4354] = true,
				[4355] = true,
				[4356] = true,
				[4357] = true,
				[4358] = true,
				[4359] = true,
				[4360] = true,
				[4361] = true,
			},
		},
		["StB"] = {
			["S"] = {
				[5984] = true,
				[5985] = true,
				[5986] = true,
				[5987] = true,
				[5988] = true,
				[5989] = true,
			},
			["A"] = {
				[5990] = true,
				[5991] = true,
				[5992] = true,
				[5993] = true,
				[5994] = true,
				[5995] = true,
				[5996] = true,
				[5997] = true,
				[5998] = true,
				[5999] = true,
				[6000] = true,
				[6001] = true,
			},
			["B"] = {
				[6002] = true,
				[6003] = true,
				[6004] = true,
				[6005] = true,
				[6006] = true,
				[6007] = true,
				[6008] = true,
				[6009] = true,
				[6010] = true,
				[6011] = true,
				[6012] = true,
				[6013] = true,
			},
		},
		["ShB"] = {
			["SS"] = {
				[8915] = true,
				[8916] = true,
			},
			["S"] = {
				[8915] = true, -- SS
				[8653] = true,
				[8890] = true,
				[8895] = true,
				[8900] = true,
				[8905] = true,
				[8910] = true,
			},
			["A"] = {
				[8654] = true,
				[8655] = true,
				[8891] = true,
				[8892] = true,
				[8896] = true,
				[8897] = true,
				[8901] = true,
				[8902] = true,
				[8906] = true,
				[8907] = true,
				[8911] = true,
				[8912] = true,
			},
			["B"] = {
				[8656] = true,
				[8657] = true,
				[8893] = true,
				[8894] = true,
				[8898] = true,
				[8899] = true,
				[8903] = true,
				[8904] = true,
				[8908] = true,
				[8909] = true,
				[8913] = true,
				[8914] = true,
			},
		}
	}
	ffxiv_radar.DeepDungeonFilters = {
		["Traps"] = { 
			[2007182] = true, -- Landmine
			[2007183] = true, -- Mobs
			[2007184] = true, -- Enervation
			[2007185] = true, -- Pacification
			[2009504] = true, -- Odder
			
			[2007182] = true, -- Landmine
			[2007183] = true, -- Mobs
			[2007184] = true, -- Enervation
			[2007185] = true, -- Pacification
			[2007185] = true, -- Unknown?
		},
		["Return"] = { 
			[2009506] = true,
			
			[2007187] = true,
		},
		["Passage"] = { 
			[2009507] = true,
			
			[2007188] = true,
		},
		["SilverChest"] = { 
			[2007357] = true,
			
			[2007357] = true,
		},
		["GoldChest"] = { 
			[2007358] = true,
			
			[2007358] = true,
		},
		["BronzeChest"] = { 
			[1036] = true,
			[1037] = true,
			[1038] = true,
			[1039] = true,
			[1040] = true,
			[1041] = true,
			[1042] = true,
			[1043] = true,
			[1044] = true,
			[1045] = true,
			[1046] = true,
			[1047] = true,
			[1048] = true,
			[1049] = true,
			[1050] = true,
			[1051] = true,
			
			[782] = true,
			[783] = true,
			[784] = true,
			[785] = true,
			[786] = true,
			[787] = true,
			[788] = true,
			[789] = true,
			[790] = true,
			[802] = true,
			[803] = true,
		},
		["BandedCoffer"] = { 
			[2007543] = true,
			
			[2007543] = true,
		},
		["Hoard"] = { 
			[2007542] = true,
			
			[2007542] = true,
		},
	}
	ffxiv_radar.AddColour = { ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 }
	ffxiv_radar.ContentID = ""
	ffxiv_radar.CustomName = ""
	ffxiv_radar.CustomList = {
		[2007744] = { ["Name"] = "[Diadem] Buried Coffer", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2005808] = { ["Name"] = "[PoTD] Treasure Coffer - Trap", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2006020] = { ["Name"] = "[PoTD] Treasure Coffer Silver - Mimic", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2006022] = { ["Name"] = "[PoTD] Treasure Coffer Gold - Mimic", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007182] = { ["Name"] = "[PoTD] Trap - Landmine", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007183] = { ["Name"] = "[PoTD] Trap - Luring", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007184] = { ["Name"] = "[PoTD] Trap - Enfeebling", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007186] = { ["Name"] = "[PoTD] Trap - Toading", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007357] = { ["Name"] = "[PoTD] Treasure Coffer Silver", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007358] = { ["Name"] = "[PoTD] Treasure Coffer Gold", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007542] = { ["Name"] = "[PoTD] Accursed Hoard", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007188] = { ["Name"] = "[PoTD] Cairn of Passage", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		[2007187] = { ["Name"] = "[PoTD] Cairn of Return", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
	}
	-- New Options List
	ffxiv_radar.Options = {
		[1] = {
			["CategoryName"] = "General",
			[1] = { ["Name"] = "Attackables", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[2] = { ["Name"] = "Fates", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[3] = { ["Name"] = "Gatherables", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[4] = { ["Name"] = "Players", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[5] = { ["Name"] = "NPC's", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[6] = { ["Name"] = "Event Objects", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[7] = { ["Name"] = "Aether Currents", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[8] = { ["Name"] = "All", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 }
		},
		[2] = {
			["CategoryName"] = "Hunts",
			[1] = { ["Name"] = "ARR - B", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[2] = { ["Name"] = "ARR - A", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[3] = { ["Name"] = "ARR - S", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[4] = { ["Name"] = "HW - B", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[5] = { ["Name"] = "HW - A", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[6] = { ["Name"] = "HW - S", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[7] = { ["Name"] = "StB - B", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[8] = { ["Name"] = "StB - A", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[9] = { ["Name"] = "StB - S", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[10] = { ["Name"] = "ShB - B", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[11] = { ["Name"] = "ShB - A", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[12] = { ["Name"] = "ShB - S/SS", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 }
		},
		[3] = {
			["CategoryName"] = "Deep Dungeon",
			[1] = { ["Name"] = "Passage", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[2] = { ["Name"] = "Return", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[3] = { ["Name"] = "Silver Chest", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[4] = { ["Name"] = "Gold Chest", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[5] = { ["Name"] = "Bronze Chest", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[6] = { ["Name"] = "Banded Coffer", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[7] = { ["Name"] = "Hoard", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
			[8] = { ["Name"] = "Traps", ["Enabled"] = false, ["Colour"] = { ["r"] = 1, ["g"] = 1, ["b"] = 1, ["a"] = 1 }, ["ColourU32"] = 4294967295 },
		}
	}
	if Settings.ffxiv_radar.Options == nil then 
		Settings.ffxiv_radar.Options = ffxiv_radar.Options 
	else
		for i,e in pairs(ffxiv_radar.Options) do
			if Settings.ffxiv_radar.Options[i] == nil then
				Settings.ffxiv_radar.Options[i] = e
				d("[Radar] - Settings Missing Group, Adding...")
			else
				for k,v in pairs(e) do
					if Settings.ffxiv_radar.Options[i][k] == nil then
						Settings.ffxiv_radar.Options[i][k] = v
						d("[Radar] - Settings Missing Data, Adding...")
					end
				end
			end
		end
	end
	ffxiv_radar.Options = Settings.ffxiv_radar.Options
	if Settings.ffxiv_radar.CustomList == nil then Settings.ffxiv_radar.CustomList = ffxiv_radar.CustomList end
	-- Import Old RadarList
	if table.valid(Settings.ffxiv_radar.RadarList) == true then
		d("[Radar] - Importing Old Custom Radar List...")
		for i,e in pairs(Settings.ffxiv_radar.RadarList) do
			local CurrentData = table.deepcopy(e)
			Settings.ffxiv_radar.CustomList[i] = { ["Name"] = e.CustomName, ["Enabled"] = e.Enabled, ["Colour"] = { ["r"] = e.Colour.r, ["g"] = e.Colour.g, ["b"] = e.Colour.b, ["a"] = e.Colour.a }, ["ColourU32"] = e.Colour.colourval }
		end
		Settings.ffxiv_radar.CustomList = Settings.ffxiv_radar.CustomList
		Settings.ffxiv_radar.RadarList = {}
	end
	ffxiv_radar.CustomList = Settings.ffxiv_radar.CustomList
end

function ffxiv_radar.ToggleMenu()
	ffxiv_radar.GUI.open = not ffxiv_radar.GUI.open
end

-- Register Event Handlers
RegisterEventHandler("Module.Initalize",ffxiv_radar.Init,"ffxiv_radar.Init")
RegisterEventHandler("Gameloop.Draw", ffxiv_radar.DrawCall,"ffxiv_radar.DrawCall")
RegisterEventHandler("Radar.toggle", ffxiv_radar.ToggleMenu,"ffxiv_radar.ToggleMenu")

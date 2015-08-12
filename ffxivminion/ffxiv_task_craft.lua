ffxiv_task_craft = inheritsFrom(ml_task)
ffxiv_task_craft.name = "LT_CRAFT"

function ffxiv_task_craft.Create()
    local newinst = inheritsFrom(ffxiv_task_craft)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_craft members
	newinst.networkLatency = 0
	newinst.synthStarted = false
	newinst.attemptedStarts = 0
	newinst.itemsCrafted = 0
	newinst.allowWindowOpen = true
	newinst.maxItems = tonumber(gCraftMaxItems) or 0
    
    return newinst
end

c_craftlimit = inheritsFrom( ml_cause )
e_craftlimit  = inheritsFrom( ml_effect )
function c_craftlimit:evaluate()
	if ( Now() < ml_task_hub:ThisTask().networkLatency ) then
		return false
	end
	
    local synth = Crafting:SynthInfo()
	if ( not synth and (
		(ml_task_hub:CurrentTask().maxItems > 0 and ml_task_hub:ThisTask().itemsCrafted == ml_task_hub:ThisTask().maxItems) or 
		ml_task_hub:CurrentTask().attemptedStarts > 2)) 
	then
		return true
	end	
	
    return false
end
function e_craftlimit:execute()
	ml_task_hub:ToggleRun()
end

c_opencraftwnd = inheritsFrom( ml_cause )
e_opencraftwnd  = inheritsFrom( ml_effect )
function c_opencraftwnd:evaluate()
	if ( Now() < ml_task_hub:ThisTask().networkLatency or ActionList:IsCasting() or not ml_task_hub:CurrentTask().allowWindowOpen ) then
		return false
	end
	
    local synth = Crafting:SynthInfo()
	if ( not synth and not Crafting:IsCraftingLogOpen() ) then
		return true
	end	
	
    return false
end

function e_opencraftwnd:execute()
    Crafting:ToggleCraftingLog()
	ml_task_hub:ThisTask().networkLatency = Now() + 1500
end

c_selectitem = inheritsFrom( ml_cause )
e_selectitem = inheritsFrom( ml_effect )
function c_selectitem:evaluate()
	local minCP = tonumber(gCraftMinCP) or 0
	if (Now() < ml_task_hub:ThisTask().networkLatency or Player.cp.current < minCP) then
		return false
	end

    local synth = Crafting:SynthInfo()
	if ( not synth and Crafting:IsCraftingLogOpen()) then
		if ( Crafting:CanCraftSelectedItem() ) then
			return true
		end
	end	
	
    return false
end
function e_selectitem:execute()
	Crafting:CraftSelectedItem()
	Crafting:ToggleCraftingLog()
	ml_task_hub:ThisTask().attemptedStarts = ml_task_hub:ThisTask().attemptedStarts + 1
	SkillMgr.newCraft = true
	ml_task_hub:ThisTask().networkLatency = Now() + 2500
	ml_task_hub:CurrentTask().allowWindowOpen = false
end

c_precraftbuff = inheritsFrom( ml_cause )
e_precraftbuff = inheritsFrom( ml_effect )
e_precraftbuff.id = 0
function c_precraftbuff:evaluate()
	if ( Now() < ml_task_hub:ThisTask().networkLatency ) then
		return false
	end
	
	local synth = Crafting:SynthInfo()	
	if (not synth) then
		Repair()
	end
	
	if (not synth) then	
		local foodID = 0
		if (gFoodHQ ~= "None") then
			foodID = ffxivminion.foodsHQ[gFoodHQ]
		elseif (gFood ~= "None") then
			foodID = ffxivminion.foods[gFood]
		end

		if foodID ~= 0 then
			local food = Inventory:Get(foodID)
			if (ValidTable(food) and MissingBuffs(Player,"48")) then
				e_precraftbuff.id = foodID
				return true
			end
		end
	end
	
	return false
end
function e_precraftbuff:execute()
	if ( Crafting:IsCraftingLogOpen()) then
		Crafting:ToggleCraftingLog()
		ml_task_hub:CurrentTask().networkLatency = Now() + 1500
		return
	end
	
	if (Now() > ml_task_hub:CurrentTask().networkLatency) then
		local food = Inventory:Get(e_precraftbuff.id)
		if (food) then
			food:Use()
			ml_task_hub:CurrentTask().networkLatency = Now() + 3000
		end	
	end
	
	ml_task_hub:CurrentTask().allowWindowOpen = true
end

c_craft = inheritsFrom( ml_cause )
e_craft = inheritsFrom( ml_effect )
function c_craft:evaluate()
	if ( Now() < ml_task_hub:ThisTask().networkLatency ) then
		return false
	end

    local synth = Crafting:SynthInfo()
	if ( synth ) then		
		return true	
	end
    return false
end
function e_craft:execute()
	if (ml_task_hub:ThisTask().attemptedStarts > 0) then
		ml_task_hub:ThisTask().attemptedStarts = 0
		ml_task_hub:ThisTask().synthStarted = true
		ml_task_hub:ThisTask().itemsCrafted = ml_task_hub:ThisTask().itemsCrafted + 1
	end
    SkillMgr.Craft()
	ml_task_hub:ThisTask().networkLatency = Now() + 1000
end

c_collectibleaddoncraft = inheritsFrom( ml_cause )
e_collectibleaddoncraft = inheritsFrom( ml_effect )
function c_collectibleaddoncraft:evaluate()
	if (ControlVisible("SelectYesNoItem")) then
		local info = Player:GetYesNoItemInfo()
		if (ValidTable(info)) then
			local validCollectible = false
			
			local variables = {}
			for i=8,15 do
				local var = _G["gCraftCollectibleName"..tostring(i)]
				local valuevar = _G["gCraftCollectibleValue"..tostring(i-7)]
				if (var and valuevar and var ~= "") then
					local id = AceLib.API.Items.GetRecipeIDByName(var,i)
					if (id) then
						variables[i] = { ["id"] = id, ["value"] = tonumber(valuevar) }
					else
						d("Could not find recipe ID for value-pair ["..tostring(var)..","..tostring(i).."]")
					end
				end
			end
			
			if (ValidTable(variables)) then
				for job,collectible in pairs(variables) do
					if (info.itemid == collectible.id) then
						if (info.collectability >= collectible.value) then
							validCollectible = true
						else
							d("Collectibility was too low ["..tostring(info.collectability).."].")
						end
					end
				end
			else
				d("No collectible value pairs are set up.")
			end
			
			if (not validCollectible) then
				PressYesNoItem(false) 
				return true
			else
				PressYesNoItem(true) 
				return true
			end
		end
	end
	return false
end
function e_collectibleaddoncraft:execute()
	ml_task_hub:ThisTask().preserveSubtasks = true
end

function ffxiv_task_craft:Init()
    --init Process() cnes
	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 50 )
    self:add( ke_inventoryFull, self.overwatch_elements)
	
	local ke_collectible = ml_element:create( "Collectible", c_collectibleaddoncraft, e_collectibleaddoncraft, 35 )
    self:add( ke_collectible, self.overwatch_elements)
	
	local ke_reachedCraftLimit = ml_element:create( "ReachedCraftLimit", c_craftlimit, e_craftlimit, 25 )
    self:add(ke_reachedCraftLimit, self.process_elements)
	
	local ke_precraftbuff = ml_element:create( "PreCraftBuff", c_precraftbuff, e_precraftbuff, 20 )
    self:add(ke_precraftbuff, self.process_elements)

	local ke_selectitem = ml_element:create( "SelectItem", c_selectitem, e_selectitem, 15 )
    self:add(ke_selectitem, self.process_elements)
	
    local ke_craft = ml_element:create( "Crafting", c_craft, e_craft, 10 )
    self:add(ke_craft, self.process_elements)   
	
	local ke_opencraftlog = ml_element:create( "OpenCraftingLog", c_opencraftwnd, e_opencraftwnd, 9 )
    self:add(ke_opencraftlog, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_craft.UIInit()
	if ( not ffxivminion.Windows) then
		ffxivminion.Windows = {}
	end
    ffxivminion.Windows.Craft = { id = strings["us"].craftMode, Name = GetString("craftMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Craft)

	if ( Settings.FFXIVMINION.gCraftMinCP == nil ) then
        Settings.FFXIVMINION.gCraftMinCP = 0
    end
	if ( Settings.FFXIVMINION.gCraftMaxItems == nil ) then
        Settings.FFXIVMINION.gCraftMaxItems = 0
    end
	if (Settings.FFXIVMINION.gCraftCollectibleName8 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleName8 = ""
	end
	if (Settings.FFXIVMINION.gCraftCollectibleValue1 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleValue1 = 0
	end
	if (Settings.FFXIVMINION.gCraftCollectibleName9 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleName9 = ""
	end
	if (Settings.FFXIVMINION.gCraftCollectibleValue2 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleValue2 = 0
	end
	if (Settings.FFXIVMINION.gCraftCollectibleName10 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleName10 = ""
	end
	if (Settings.FFXIVMINION.gCraftCollectibleValue3 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleValue3 = 0
	end
	if (Settings.FFXIVMINION.gCraftCollectibleName11 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleName11 = ""
	end
	if (Settings.FFXIVMINION.gCraftCollectibleValue4 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleValue4 = 0
	end
	if (Settings.FFXIVMINION.gCraftCollectibleName12 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleName12 = ""
	end
	if (Settings.FFXIVMINION.gCraftCollectibleValue5 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleValue5 = 0
	end
	if (Settings.FFXIVMINION.gCraftCollectibleName13 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleName13 = ""
	end
	if (Settings.FFXIVMINION.gCraftCollectibleValue6 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleValue6 = 0
	end
	if (Settings.FFXIVMINION.gCraftCollectibleName14 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleName14 = ""
	end
	if (Settings.FFXIVMINION.gCraftCollectibleValue7 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleValue7 = 0
	end
	if (Settings.FFXIVMINION.gCraftCollectibleName15 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleName15 = ""
	end
	if (Settings.FFXIVMINION.gCraftCollectibleValue8 == nil) then
		Settings.FFXIVMINION.gCraftCollectibleValue8 = 0
	end
	
	local winName = GetString("craftMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
    GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
	
	group = GetString("settings")
	GUI_NewField(winName,GetString("craftAmount"),"gCraftMaxItems",group)
    GUI_NewField(winName,GetString("minimumCP"),"gCraftMinCP",group)
	
	group = "Collectible"
	local collectStringCraft1 = AceLib.API.Items.BuildRecipeString(FFXIV.JOBS.CARPENTER,0,51)
	local collectStringCraft2 = AceLib.API.Items.BuildRecipeString(FFXIV.JOBS.BLACKSMITH,0,51)
	local collectStringCraft3 = AceLib.API.Items.BuildRecipeString(FFXIV.JOBS.ARMORER,0,51)
	local collectStringCraft4 = AceLib.API.Items.BuildRecipeString(FFXIV.JOBS.GOLDSMITH,0,51)
	local collectStringCraft5 = AceLib.API.Items.BuildRecipeString(FFXIV.JOBS.LEATHERWORKER,0,51)
	local collectStringCraft6 = AceLib.API.Items.BuildRecipeString(FFXIV.JOBS.WEAVER,0,51)
	local collectStringCraft7 = AceLib.API.Items.BuildRecipeString(FFXIV.JOBS.ALCHEMIST,0,51)
	local collectStringCraft8 = AceLib.API.Items.BuildRecipeString(FFXIV.JOBS.CULINARIAN,0,51)
	
	--local id = AceLib.API.Items.GetRecipeIDByName(v,job)
	
	GUI_NewComboBox(winName,"Collectible","gCraftCollectibleName8",group,collectStringCraft1)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue1",group)
	GUI_NewComboBox(winName,"Collectible","gCraftCollectibleName9",group,collectStringCraft2)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue2",group)
	GUI_NewComboBox(winName,"Collectible","gCraftCollectibleName10",group,collectStringCraft3)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue3",group)
	GUI_NewComboBox(winName,"Collectible","gCraftCollectibleName11",group,collectStringCraft4)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue4",group)
	GUI_NewComboBox(winName,"Collectible","gCraftCollectibleName12",group,collectStringCraft5)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue5",group)
	GUI_NewComboBox(winName,"Collectible","gCraftCollectibleName13",group,collectStringCraft6)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue6",group)
	GUI_NewComboBox(winName,"Collectible","gCraftCollectibleName14",group,collectStringCraft7)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue7",group)
	GUI_NewComboBox(winName,"Collectible","gCraftCollectibleName15",group,collectStringCraft8)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue8",group)
	
	GUI_UnFoldGroup(winName,GetString("status"))
	GUI_UnFoldGroup(winName,GetString("settings"))
	GUI_UnFoldGroup(winName,"Collectible")
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gCraftMinCP = Settings.FFXIVMINION.gCraftMinCP
    gCraftMaxItems = Settings.FFXIVMINION.gCraftMaxItems
	gCraftCollectibleName8 = Settings.FFXIVMINION.gCraftCollectibleName8
	gCraftCollectibleName9 = Settings.FFXIVMINION.gCraftCollectibleName9
	gCraftCollectibleName10 = Settings.FFXIVMINION.gCraftCollectibleName10
	gCraftCollectibleName11 = Settings.FFXIVMINION.gCraftCollectibleName11
	gCraftCollectibleName12 = Settings.FFXIVMINION.gCraftCollectibleName12
	gCraftCollectibleName13 = Settings.FFXIVMINION.gCraftCollectibleName13
	gCraftCollectibleName14 = Settings.FFXIVMINION.gCraftCollectibleName14
	gCraftCollectibleName15 = Settings.FFXIVMINION.gCraftCollectibleName15
	gCraftCollectibleValue1 = Settings.FFXIVMINION.gCraftCollectibleValue1
	gCraftCollectibleValue2 = Settings.FFXIVMINION.gCraftCollectibleValue2
	gCraftCollectibleValue3 = Settings.FFXIVMINION.gCraftCollectibleValue3
	gCraftCollectibleValue4 = Settings.FFXIVMINION.gCraftCollectibleValue4
	gCraftCollectibleValue5 = Settings.FFXIVMINION.gCraftCollectibleValue5
	gCraftCollectibleValue6 = Settings.FFXIVMINION.gCraftCollectibleValue6
	gCraftCollectibleValue7 = Settings.FFXIVMINION.gCraftCollectibleValue7
	gCraftCollectibleValue8 = Settings.FFXIVMINION.gCraftCollectibleValue8
	
    RegisterEventHandler("GUI.Update",ffxiv_task_craft.GUIVarUpdate)
end

function ffxiv_task_craft.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if 	( 	k == "gCraftMinCP" or 
				k == "gCraftMaxItems" or
				string.find(tostring(k),"gCraftCollectible"))				
		then
            SafeSetVar(tostring(k),v)
        end
    end
    GUI_RefreshWindow(GetString("craftMode"))
end
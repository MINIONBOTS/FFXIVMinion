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
	newinst.maxItems = tonumber(gCraftMaxItems)
    
    return newinst
end

c_craftlimit = inheritsFrom( ml_cause )
e_craftlimit  = inheritsFrom( ml_effect )
function c_craftlimit:evaluate()
	if ( Now() < ml_task_hub:ThisTask().networkLatency ) then
		return false
	end
	
    local synth = Crafting:SynthInfo()
	if ( not synth and
		((ml_task_hub:ThisTask().maxItems > 0 and ml_task_hub:ThisTask().itemsCrafted == ml_task_hub:ThisTask().maxItems) or ml_task_hub:ThisTask().attemptedStarts > 2)) 
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
	if ( Now() < ml_task_hub:ThisTask().networkLatency ) then
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
	if (Now() < ml_task_hub:ThisTask().networkLatency or Player.cp.current < tonumber(gCraftMinCP)) then
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
	SkillMgr.currentIQStack = 0 
	SkillMgr.lastquality = 0
	ml_task_hub:ThisTask().networkLatency = Now() + 1500
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
			ml_task_hub:CurrentTask().networkLatency = Now() + 1500
		end	
	end
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

function ffxiv_task_craft:Init()
    --init Process() cnes
	local ke_reachedCraftLimit = ml_element:create( "ReachedCraftLimit", c_craftlimit, e_craftlimit, 25 )
    self:add(ke_reachedCraftLimit, self.process_elements)
	
	local ke_precraftbuff = ml_element:create( "PreCraftBuff", c_precraftbuff, e_precraftbuff, 20 )
    self:add(ke_precraftbuff, self.process_elements)

	local ke_opencraftlog = ml_element:create( "OpenCraftingLog", c_opencraftwnd, e_opencraftwnd, 15 )
    self:add(ke_opencraftlog, self.process_elements)		
	
	local ke_selectitem = ml_element:create( "SelectItem", c_selectitem, e_selectitem, 10 )
    self:add(ke_selectitem, self.process_elements)
	
    local ke_craft = ml_element:create( "Crafting", c_craft, e_craft, 5 )
    self:add(ke_craft, self.process_elements)   
    
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
	
	local winName = GetString("craftMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].botMode,"gBotMode",group,"None")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].skillProfile,"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
    GUI_NewCheckbox(winName,strings[gCurrentLanguage].botEnabled,"gBotRunning",group)
	local group = GetString("settings")
	GUI_NewField(winName,strings[gCurrentLanguage].craftAmount,"gCraftMaxItems",group)
    GUI_NewField(winName,strings[gCurrentLanguage].minimumCP,"gCraftMinCP",group)
	
	GUI_UnFoldGroup(winName,GetString("status"))
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gCraftMinCP = Settings.FFXIVMINION.gCraftMinCP
    gCraftMaxItems = Settings.FFXIVMINION.gCraftMaxItems
	
    RegisterEventHandler("GUI.Update",ffxiv_task_craft.GUIVarUpdate)
end

function ffxiv_task_craft.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if 	( 	k == "gCraftMinCP" or 
				k == "gCraftMaxItems" ) 
		then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(GetString("craftMode"))
end
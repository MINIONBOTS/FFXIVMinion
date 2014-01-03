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

    
    return newinst
end

-- repairs gear automatically
c_repair = inheritsFrom( ml_cause )
e_repair = inheritsFrom( ml_effect )
c_repair.throttle = 30000
function c_repair:evaluate()
	d("Checking items for needed repair..")
	local eq = Inventory("type=1000")
	if (eq) then
		local i,e = next (eq)
		while ( i and e ) do
			if ( e.condition < math.random (1,50) ) then
				return true
			end
			i,e = next (eq,i)
		end		
	end
    return false
end
function e_repair:execute()
	d("Repairing items ..")
    local eq = Inventory("type=1000")
	if (eq) then
		local i,e = next (eq)
		while ( i and e ) do
			if ( e.condition < 50 ) then
				e:Repair()
			end
			i,e = next (eq,i)
		end		
	end
end

c_opencraftwnd = inheritsFrom( ml_cause )
e_opencraftwnd  = inheritsFrom( ml_effect )
c_opencraftwnd.throttle = 1500
function c_opencraftwnd:evaluate()
    local synth = Crafting:SynthInfo()
	if ( not synth and not Crafting:IsCraftingLogOpen()) then
		return true
	end	
    return false
end
function e_opencraftwnd:execute()
    Crafting:ToggleCraftingLog()
end

c_selectitem = inheritsFrom( ml_cause )
e_selectitem = inheritsFrom( ml_effect )
c_selectitem.throttle = 1500
function c_selectitem:evaluate()
    local synth = Crafting:SynthInfo()
	if ( not synth and Crafting:IsCraftingLogOpen()) then
		d("Can craft selected Item? : "..tostring(Crafting:CanCraftSelectedItem()))
		if ( Crafting:CanCraftSelectedItem() ) then
			return true
		end
	end	
    return false
end
function e_selectitem:execute()
    Crafting:CraftSelectedItem()
	Crafting:ToggleCraftingLog()
	SkillMgr.currentIQStack = 0 
	SkillMgr.lastquality = 0
end


c_craft = inheritsFrom( ml_cause )
e_craft = inheritsFrom( ml_effect )
e_craft.throttle = 1000
function c_craft:evaluate()
    local synth = Crafting:SynthInfo()
	if ( synth ) then		
		return true	
	end
    return false
end
function e_craft:execute()
    SkillMgr.Craft()
end

function ffxiv_task_craft:Init()
    --init Process() cnes
    	
	local ke_repair = ml_element:create( "RepairingGear", c_repair, e_repair, 20 )
    self:add(ke_repair, self.process_elements)

	local ke_opencraftlog = ml_element:create( "OpenCraftingLog", c_opencraftwnd, e_opencraftwnd, 15 )
    self:add(ke_opencraftlog, self.process_elements)		
	
	local ke_selectitem = ml_element:create( "SelectItem", c_selectitem, e_selectitem, 10 )
    self:add(ke_selectitem, self.process_elements)
	
    local ke_craft = ml_element:create( "Crafting", c_craft, e_craft, 5 )
    self:add(ke_craft, self.process_elements)   
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_craft:OnSleep()

end

function ffxiv_task_craft:OnTerminate()

end

function ffxiv_task_craft:IsGoodToAbort()

end

--[[ UI settings etc
function ffxiv_task_craft.UIInit()
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].ignoreMarkerLevels, "gIgnoreFishLvl",strings[gCurrentLanguage].fishMode)
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].useMooch, "gUseMooch",strings[gCurrentLanguage].fishMode)
    GUI_SizeWindow(ml_global_information.MainWindow.Name,250,400)
    
    if (Settings.FFXIVMINION.gIgnoreFishLvl == nil) then
        Settings.FFXIVMINION.gIgnoreFishLvl = "0"
    end
	
	if (Settings.FFXIVMINION.gUseMooch == nil) then
        Settings.FFXIVMINION.gUseMooch = "1"
    end
    gIgnoreFishLvl = Settings.FFXIVMINION.gIgnoreFishLvl
	gUseMooch = Settings.FFXIVMINION.gUseMooch
    
    RegisterEventHandler("GUI.Update",ffxiv_task_craft.GUIVarUpdate)
end

function ffxiv_task_craft.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if 	( k == "gIgnoreFishLvl" ) or
			( k == "gUseMooch" )then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end]]
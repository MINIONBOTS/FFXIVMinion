ffxiv_craft = {}
ffxiv_craft.crafts = {
	["CRP"] = 8,	["BSM"] = 9,	["ARM"] = 10,	["GSM"] = 11,
	["LTW"] = 12,	["WVR"] = 13,	["ALC"] = 14,	["CUL"] = 15,
}
ffxiv_craft.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\CraftProfiles\]]
ffxiv_craft.orders = {}
ffxiv_craft.ordersVisible = false
ffxiv_craft.orderSelectorVisible = false

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
	ffxiv_craft.ResetOrders()
    
    return newinst
end

function cd(var,level)
	local level = tonumber(level) or 3

	if ( gCraftDebug ) then
		if ( level <= tonumber(gCraftDebugLevel)) then
			if (type(var) == "string") then
				d("[L"..tostring(level).."]["..tostring(Now()).."]: "..var)
			elseif (type(var) == "number" or type(var) == "boolean") then
				d("[L"..tostring(level).."]["..tostring(Now()).."]: "..tostring(var))
			elseif (type(var) == "table") then
				outputTable(var)
			end
		end
	end
end

c_craftlimit = inheritsFrom( ml_cause )
e_craftlimit = inheritsFrom( ml_effect )
function c_craftlimit:evaluate()
	if ( Now() < ml_task_hub:CurrentTask().networkLatency) then
		return false
	end
	
	local synth = Crafting:SynthInfo()
	if (synth == nil) then
		if (ffxiv_craft.UsingProfile()) then
			local recipe = ml_task_hub:CurrentTask().recipe
			local itemid = ml_task_hub:CurrentTask().itemid
			local requireHQ = ml_task_hub:CurrentTask().requireHQ
			local countHQ = ml_task_hub:CurrentTask().countHQ
			local requiredItems = ml_task_hub:CurrentTask().requiredItems
			local startingCount = ml_task_hub:CurrentTask().startingCount 
			
			local itemcount = ItemCount(itemid,countHQ,requireHQ)
			local canCraft = AceLib.API.Items.CanCraft(recipe.id)			
			if (not canCraft) then
				cd("[CraftLimit]: We can no longer craft this item, complete the order.",3)
				return true
			else
				if (requiredItems > 0 and itemcount >= (requiredItems + startingCount))	then
					cd("[CraftLimit]: Current item count ["..tostring(itemcount).."] is more than ["..tostring(requiredItems + startingCount).."], no need to start more.",3)
					return true
				end
			end
		else
			if ((ml_task_hub:CurrentTask().maxItems > 0 and ml_task_hub:CurrentTask().itemsCrafted == ml_task_hub:CurrentTask().maxItems) or 
				ml_task_hub:CurrentTask().attemptedStarts > 2)
			then
				return true
			end
		end
	end
	
    return false
end
function e_craftlimit:execute()
	cd("[CraftLimit]: Profile has reached the preset requirements.",3)
	if (ffxiv_craft.UsingProfile()) then
		local recipeid = ml_task_hub:CurrentTask().recipe.id
		ffxiv_craft.orders[recipeid].completed = true
		
		cd("[CraftLimit]: Setting order with recipe ID ["..tostring(recipeid).."] to complete.",3)
		ml_task_hub:CurrentTask().completed = true
	else
		ml_task_hub:ToggleRun()
	end
end

c_opencraftwnd = inheritsFrom( ml_cause )
e_opencraftwnd  = inheritsFrom( ml_effect )
function c_opencraftwnd:evaluate()
	if ( Now() < ml_task_hub:ThisTask().networkLatency or MIsCasting() or not ml_task_hub:CurrentTask().allowWindowOpen ) then
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

c_startcraft = inheritsFrom( ml_cause )
e_startcraft = inheritsFrom( ml_effect )
function c_startcraft:evaluate()
	local minCP = tonumber(gCraftMinCP) or 0
	if (Now() < ml_task_hub:ThisTask().networkLatency or Player.cp.current < minCP) then
		return false
	end

    local synth = Crafting:SynthInfo()
	if ( synth == nil and Crafting:IsCraftingLogOpen()) then
		
		if (ffxiv_craft.UsingProfile()) then
			local recipe = ml_task_hub:CurrentTask().recipe
			local jobRequired = recipe.class + 8
			
			if (Player.job == jobRequired) then
				local itemid = ml_task_hub:CurrentTask().itemid
				local requireHQ = ml_task_hub:CurrentTask().requireHQ
				local countHQ = ml_task_hub:CurrentTask().countHQ
				local canCraft,maxAmount = AceLib.API.Items.CanCraft(recipe.id)
				
				local itemcount = ItemCount(itemid,countHQ,requireHQ)				
				local requiredItems = ml_task_hub:CurrentTask().requiredItems
				local startingCount = ml_task_hub:CurrentTask().startingCount 
				
				if (canCraft) then
					if (requiredItems == 0 or (requiredItems > 0 and itemcount < (requiredItems + startingCount))) then
						return true
					else
						cd("[StartCraft]: Current item count ["..tostring(itemcount).."] is more than ["..tostring(requiredItems + startingCount).."], no need to start more.",3)
					end
				else
					cd("[StartCraft]: Detected that we cannot craft anymore of item ["..tostring(recipe.id).."].",3)
				end
			end
		else
			if ( Crafting:CanCraftSelectedItem() ) then
				return true
			end
		end
	end	
	
    return false
end

function e_startcraft:execute()
	if (ffxiv_craft.UsingProfile()) then
		local recipe = ml_task_hub:CurrentTask().recipe
		local itemid = ml_task_hub:CurrentTask().itemid
		if (not ml_task_hub:CurrentTask().recipeSelected) then
			cd("Recipe phase 1, set to: ["..tostring(recipe.class)..","..tostring(recipe.page)..","..tostring(itemid).."].",3)
			Crafting:SetRecipe(recipe.class,recipe.page,itemid)
			ml_task_hub:CurrentTask().recipeSelected = true
			
			local skillProfile = ml_task_hub:CurrentTask().skillProfile
			if (skillProfile ~= "" and gSkillProfile ~= skillProfile) then
				if (SkillMgr.HasProfile(skillProfile)) then
					SkillMgr.UseProfile(skillProfile)
				end
			end
			
			ml_global_information.Await(1000)
			return
		else
			local usehq = ml_task_hub:CurrentTask().useHQ
			cd("[StartCraft]: Order HQ Status :"..tostring(usehq)..".",3)
			Crafting:UseHQMats(usehq)
			
			if (Crafting:CanCraftSelectedItem()) then
			--if (true) then
				ml_task_hub:CurrentTask().failedAttempts = 0
				local usequick = ml_task_hub:CurrentTask().useQuick
				if (usequick) then
					local itemid = ml_task_hub:CurrentTask().itemid
					local canCraft,maxAmount = AceLib.API.Items.CanCraft(recipe.id)
					local wantedAmount = ml_task_hub:ThisTask().requiredItems
					if (wantedAmount > 0 and wantedAmount <= maxAmount and wantedAmount <= 99) then
						Crafting:CraftSelectedItem(wantedAmount)
					else
						if (maxAmount > 99) then
							Crafting:CraftSelectedItem(99)
						else
							Crafting:CraftSelectedItem(maxAmount)
						end
					end
					Crafting:ToggleCraftingLog()
					SkillMgr.newCraft = true
					ml_task_hub:CurrentTask().allowWindowOpen = false
				else
					Crafting:CraftSelectedItem()
					Crafting:ToggleCraftingLog()
					SkillMgr.newCraft = true
					ml_task_hub:CurrentTask().allowWindowOpen = false
				end
				ml_global_information.Await(2500)
				return
			else
				if (ml_task_hub:CurrentTask().failedAttempts < 3) then
					cd("[StartCraft]: API Detected that we cannot craft anymore of item ["..tostring(recipe.id).."], but we will try a couple more times to be sure.",3)
					ml_task_hub:CurrentTask().failedAttempts = ml_task_hub:CurrentTask().failedAttempts + 1
					ml_global_information.Await(1000)
					return
				else
					cd("[StartCraft]: API Detected that we cannot craft anymore of item ["..tostring(recipe.id).."].",3)
					ffxiv_craft.orders[recipe.id].completed = true
					ml_task_hub:CurrentTask().completed = true
				end
			end			
		end
	else
		Crafting:CraftSelectedItem()
		Crafting:ToggleCraftingLog()
		ml_task_hub:ThisTask().attemptedStarts = ml_task_hub:ThisTask().attemptedStarts + 1
		SkillMgr.newCraft = true
		ml_task_hub:ThisTask().networkLatency = Now() + 2500
		ml_task_hub:CurrentTask().allowWindowOpen = false
	end
end

c_precraftbuff = inheritsFrom( ml_cause )
e_precraftbuff = inheritsFrom( ml_effect )
e_precraftbuff.id = 0
e_precraftbuff.activity = ""
e_precraftbuff.item = nil
e_precraftbuff.requiresLogClose = false
function c_precraftbuff:evaluate()
	if ( Now() < ml_task_hub:ThisTask().networkLatency ) then
		return false
	end
	
	e_precraftbuff.id = 0
	e_precraftbuff.item = nil
	e_precraftbuff.activity = ""
	e_precraftbuff.requiresLogClose = false
	
	local synth = Crafting:SynthInfo()	
	if (not synth) then
		if (NeedsRepair()) then
			cd("[PreCraftBuff]: Need to repair.",3)
			e_precraftbuff.activity = "repair"
			e_precraftbuff.requiresLogClose = false
			return true
		end
		
		if (gFood ~= "None") then
			local foodID = ffxivminion.foods[gFood]
			local food, action = GetItem(foodID)
			if (food and food:IsReady(Player.id) and action and MissingBuffs(Player,"48",60)) then
				cd("[PreCraftBuff]: Need to eat.",3)
				e_precraftbuff.activity = "eat"
				e_precraftbuff.id = foodID
				e_precraftbuff.requiresLogClose = true
				return true
			end
		end
		
		local canUse,manualItem = CanUseExpManual()
		if (canUse and table.valid(manualItem)) then
			d("[NodePreBuff]: Need to use an exp manual.")
			e_precraftbuff.activity = "usemanual"
			e_precraftbuff.item = manualItem
			e_precraftbuff.requiresLogClose = true
			return true
		end
		
		if (ffxiv_craft.UsingProfile()) then
			local recipe = ml_task_hub:CurrentTask().recipe
			local jobRequired = recipe.class + 8
			if (Player.job ~= jobRequired) then
				cd("[PreCraftBuff]: Need to switch class.",3)
				e_precraftbuff.activity = "switchclass"
				e_precraftbuff.requiresLogClose = true
				return true
			end
		end		
	end

	return false
end
function e_precraftbuff:execute()
	local activityItem = e_precraftbuff.item
	
	if (e_precraftbuff.requiresLogClose) then
		if ( Crafting:IsCraftingLogOpen()) then
			Crafting:ToggleCraftingLog()
			ml_task_hub:CurrentTask().allowWindowOpen = true
			ml_global_information.Await(1500)
			return
		end
	end
	
	local activity = e_precraftbuff.activity
	if (activity == "repair") then
		cd("[PreCraftBuff]: Attempting repairs.",3)
		Repair()
		ml_global_information.Await(500)
	elseif (activity == "eat") then
		local food, action = GetItem(e_precraftbuff.id)
		if (food and action and food:IsReady(Player.id)) then
			cd("[PreCraftBuff]: Attempting to eat.",3)
			food:Cast(Player.id)
			local castid = action.id
			ml_global_information.Await(5000, function () return Player.castinginfo.lastcastid == castid end)
		end	
	elseif (activity == "switchclass") then
		local recipe = ml_task_hub:CurrentTask().recipe
		local jobRequired = recipe.class + 8
		local gearset = _G["gCraftGearset"..tostring(jobRequired)]
		cd("[PreCraftBuff]: Attempting to switch to gearset ["..tostring(gearset).."].",3)
		local commandString = "/gearset change "..tostring(gearset)
		SendTextCommand(commandString)
		ml_global_information.Await(3000)
	elseif (activity == "usemanual") then
		local manual, action = activityItem
		if (manual and action and manual:IsReady(Player.id)) then
			manual:Cast(Player.id)
			local castid = action.id
			ml_global_information.Await(5000, function () return Player.castinginfo.lastcastid == castid end)
			return
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
	if ( synth or IsControlOpen("Synthesis")) then		
		return true	
	end
    return false
end
function e_craft:execute()
	ml_task_hub:CurrentTask().recipeSelected = false
	ml_task_hub:CurrentTask().recipeSelected2 = false
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
	if (IsControlOpen("SelectYesNoItem") or IsControlOpen("SelectYesNoCountItem")) then
		local info = Player:GetYesNoItemInfo()
		if (table.valid(info)) then
			local validCollectible = false
			
			local variables = {}
			for i=8,15 do
				local var = _G["gCraftCollectibleName"..tostring(i)]
				local valuevar = _G["gCraftCollectibleValue"..tostring(i-7)]
				
				--d("Checking selection [gCraftCollectibleName"..tostring(i).."], value:"..tostring(var))
				--d("Checking selection [gCraftCollectibleValue"..tostring(i-7).."], value:"..tostring(valuevar))
				
				if (var and valuevar and var ~= "") then
					local recipeid,itemid = AceLib.API.Items.GetRecipeIDByName(var,i)
					if (itemid) then
						d("Setting variables[" .. i .. "] to use value-pair ["..tostring(var)..","..tostring(valuevar).."]")
						variables[i] = { ["id"] = itemid, ["value"] = tonumber(valuevar) }
					else
						d("Could not find recipe ID for value-pair ["..tostring(var)..","..tostring(i).."]")
					end
				end
			end
			
			if (table.valid(variables)) then
				for job,collectible in pairs(variables) do
					--d("Checking variable ["..tostring(job).."]")
					--d("id ["..tostring(collectible.id).."], value ["..tostring(collectible.value).."]")
					if (string.find(tostring(info.itemid),tostring(collectible.id))) then
						if (info.collectability >= collectible.value) then
							validCollectible = true
						else
							d("Collectibility was too low ["..tostring(info.collectability).."].")
						end
					else
						d("ItemID ["..tostring(info.itemid).."] does not match collectible ID.")
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

c_quicksynth = inheritsFrom( ml_cause )
e_quicksynth = inheritsFrom( ml_effect )
function c_quicksynth:evaluate()
	return IsControlOpen("SynthesisSimple")
end
function e_quicksynth:execute()
	if (ml_task_hub:CurrentTask().quickTimer > 0 and TimeSince(ml_task_hub:CurrentTask().quickTimer) > 7000) then
		Crafting:EndSynthesis(true)
		ml_global_information.Await(6000)
		return true
	end
	
	if (Player.action == 241) then
		ml_task_hub:CurrentTask().quickTimer = Now()
	end
end

c_selectcraft = inheritsFrom( ml_cause )
e_selectcraft = inheritsFrom( ml_effect )
function c_selectcraft:evaluate()
	if ( Now() < ml_task_hub:ThisTask().networkLatency ) then
		return false
	end
	
	if (ffxiv_craft.UsingProfile()) then
		local orders = ffxiv_craft.orders
		for id,order in pairs(orders) do
			if (order.completed == nil) then
				cd("[SelectCraft]: Initializing the completion status for id ["..tostring(id).."].",3)
				orders[id].completed = false
			end
			if (order.completed == false) then
				cd("[SelectCraft]: Found an incomplete order ["..tostring(id).."], select a new craft.",3)
				return true
			end
		end
	else
		return true
	end

	return false
end
function e_selectcraft:execute()
	ml_task_hub:ThisTask().networkLatency = Now() + 2500
	
	local newTask = ffxiv_task_craftitems.Create()
	
	if (ffxiv_craft.UsingProfile()) then
		local orders = ffxiv_craft.orders
		
		local sortfunc = function(orders,a,b) 
			return (orders[a].page < orders[b].page) or (orders[a].page == orders[b].page and orders[a].level < orders[b].level) 
		end
		
		local foundSelection = false
		for id,order in spairs(orders, sortfunc) do
			if (not order.completed) then
				local canCraft = AceLib.API.Items.CanCraft(id)
				if (canCraft) then
					
					local itemcount = ItemCount(itemid,order.counthq,order.requirehq)
					
					newTask.startingCount = itemcount
					cd("[SelectCraft]: Starting Amount :"..tostring(itemcount)..".",3)
					newTask.requiredItems = order.amount
					cd("[SelectCraft]: Required Amount :"..tostring(order.amount)..".",3)
					newTask.requireHQ = order.requirehq
					newTask.countHQ = order.counthq
					newTask.itemid = order.item
					newTask.useQuick = order.usequick
					newTask.useHQ = order.usehq
					cd("[SelectCraft]: Order HQ Status :"..tostring(order.usehq)..".",3)
					newTask.skillProfile = order.profile
					newTask.recipe = { id = order.id, class = order.class, page = order.page }
					
					cd("[SelectCraft]: Can craft id ["..tostring(id).."], recipe details [ id = "..tostring(order.id).."].",2)
					cd("[SelectCraft]: RecipeDetails ["..tostring(order.class)..","..tostring(order.page).."].",2)
					
					foundSelection = true
				else
					cd("[SelectCraft]: Cannot undertake ["..tostring(id).."], not craftable.",3)
				end
			else
				cd("[SelectCraft]: Cannot undertake ["..tostring(id).."] as it has been completed.",3)
			end
			
			if (foundSelection) then
				break
			end
		end
		
		if (foundSelection) then
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		end
	else
		newTask.maxItems = tonumber(gCraftMaxItems) or 0
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	end
end

ffxiv_task_craftitems = inheritsFrom(ml_task)
ffxiv_task_craftitems.name = "LT_CRAFTITEMS"
function ffxiv_task_craftitems.Create()
    local newinst = inheritsFrom(ffxiv_task_craftitems)
    
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
	newinst.maxItems = 0
	
	newinst.startingCount = 0
	newinst.requiredItems = 0
	newinst.requireHQ = false
	newinst.countHQ = false
	newinst.itemid = 0
	newinst.useQuick = false
	newinst.useHQ = (FFXIV_Craft_UseHQMats == "1")
	newinst.recipe = {}
	newinst.recipeSelected = false
	newinst.skillProfile = ""
	newinst.quickTimer = 0
	
	newinst.failedAttempts = 0
    
    return newinst
end

function ffxiv_task_craftitems:Init()
	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 150 )
    self:add( ke_inventoryFull, self.process_elements)
	
	local ke_reachedCraftLimit = ml_element:create( "ReachedCraftLimit", c_craftlimit, e_craftlimit, 140 )
    self:add(ke_reachedCraftLimit, self.process_elements)
	
	local ke_precraftbuff = ml_element:create( "PreCraftBuff", c_precraftbuff, e_precraftbuff, 120 )
    self:add(ke_precraftbuff, self.process_elements)
	
	local ke_quickSynth = ml_element:create( "QuickSynth", c_quicksynth, e_quicksynth, 80 )
    self:add( ke_quickSynth, self.process_elements)

	local ke_startCraft = ml_element:create( "StartCraft", c_startcraft, e_startcraft, 70 )
    self:add(ke_startCraft, self.process_elements)
	
	local ke_craft = ml_element:create( "Crafting", c_craft, e_craft, 60 )
    self:add(ke_craft, self.process_elements)   
	
	local ke_opencraftlog = ml_element:create( "OpenCraftingLog", c_opencraftwnd, e_opencraftwnd, 50 )
    self:add(ke_opencraftlog, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_craftitems:task_complete_eval()
	return false
end

function ffxiv_task_craftitems:task_complete_execute()
	self.completed = true
end

function ffxiv_task_craftitems:task_fail_eval()
	return false
end

function ffxiv_task_craftitems:task_fail_execute()
    self.valid = false
end

function ffxiv_task_craft:Init()
    --init Process() cnes
	local ke_collectible = ml_element:create( "Collectible", c_collectibleaddoncraft, e_collectibleaddoncraft, 150 )
    self:add( ke_collectible, self.overwatch_elements)
	
	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 140 )
    self:add( ke_inventoryFull, self.process_elements)
	
	local ke_autoEquip = ml_element:create( "AutoEquip", c_autoequip, e_autoequip, 130 )
    self:add( ke_autoEquip, self.process_elements)
	
	local ke_selectCraft = ml_element:create( "SelectCraft", c_selectcraft, e_selectcraft, 100 )
    self:add(ke_selectCraft, self.process_elements)
end

function ffxiv_task_craft.SetModeOptions()
	gTeleportHack = Settings.FFXIVMINION.gTeleportHack
	gTeleportHackParanoid = Settings.FFXIVMINION.gTeleportHackParanoid
	gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
	gSkipCutscene = Settings.FFXIVMINION.gSkipCutscene
	gSkipTalk = Settings.FFXIVMINION.gSkipTalk
	Hacks:SkipCutscene(gSkipCutscene)
	Hacks:SkipDialogue(gSkipTalk)
	Hacks:Disable3DRendering(gDisableDrawing)
	gAvoidAOE = Settings.FFXIVMINION.gAvoidAOE
	ffxiv_craft.UpdateProfiles()
	gAutoEquip = Settings.FFXIVMINION.gAutoEquip
end

function ffxiv_task_craft.UIInit()
	if ( not ffxivminion.Windows) then
		ffxivminion.Windows = {}
	end
    ffxivminion.Windows.Craft = { id = strings["us"].craftMode, Name = GetString("craftMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Craft)

    Settings.FFXIVMINION.gLastCraftProfile = IsNull(Settings.FFXIVMINION.gLastCraftProfile,GetString("none"))
	
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
	if (Settings.FFXIVMINION.gCraftDebug == nil) then
		Settings.FFXIVMINION.gCraftDebug = "0"
	end
	if (Settings.FFXIVMINION.gCraftDebugLevel == nil) then
		Settings.FFXIVMINION.gCraftDebugLevel = "1"
	end	
	
	Settings.FFXIVMINION.gCraftGearset8 = Settings.FFXIVMINION.gCraftGearset8 or ""
	Settings.FFXIVMINION.gCraftGearset9 = Settings.FFXIVMINION.gCraftGearset9 or ""
	Settings.FFXIVMINION.gCraftGearset10 = Settings.FFXIVMINION.gCraftGearset10 or ""
	Settings.FFXIVMINION.gCraftGearset11 = Settings.FFXIVMINION.gCraftGearset11 or ""
	Settings.FFXIVMINION.gCraftGearset12 = Settings.FFXIVMINION.gCraftGearset12 or ""
	Settings.FFXIVMINION.gCraftGearset13 = Settings.FFXIVMINION.gCraftGearset13 or ""
	Settings.FFXIVMINION.gCraftGearset14 = Settings.FFXIVMINION.gCraftGearset14 or ""
	Settings.FFXIVMINION.gCraftGearset15 = Settings.FFXIVMINION.gCraftGearset15 or ""
	Settings.FFXIVMINION.gCraftOrderSelect = Settings.FFXIVMINION.gCraftOrderSelect or "CRP"
	
	local winName = GetString("craftMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	
	GUI_NewButton(winName, "Add Craft Orders","ffxiv_craft.SwitchCraftWindow")
	GUI_NewButton(winName, "View Craft Orders","ffxiv_craft.ShowCraftOrders")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("profile"),"gProfile",group,"None")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSkillProfile",group,ffxivminion.Strings.SKMProfiles())
    GUI_NewCheckbox(winName,GetString("botEnabled"),"FFXIV_Common_BotRunning",group)
	GUI_NewCheckbox(winName,"Craft Debug","gCraftDebug",group)
	GUI_NewComboBox(winName,"Debug Level","gCraftDebugLevel",group,"1,2,3")
	
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
	
	GUI_NewComboBox(winName,"CRP","gCraftCollectibleName8",group,collectStringCraft1)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue1",group)
	GUI_NewComboBox(winName,"BSM","gCraftCollectibleName9",group,collectStringCraft2)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue2",group)
	GUI_NewComboBox(winName,"ARM","gCraftCollectibleName10",group,collectStringCraft3)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue3",group)
	GUI_NewComboBox(winName,"GSM","gCraftCollectibleName11",group,collectStringCraft4)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue4",group)
	GUI_NewComboBox(winName,"LTW","gCraftCollectibleName12",group,collectStringCraft5)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue5",group)
	GUI_NewComboBox(winName,"WVR","gCraftCollectibleName13",group,collectStringCraft6)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue6",group)
	GUI_NewComboBox(winName,"ALC","gCraftCollectibleName14",group,collectStringCraft7)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue7",group)
	GUI_NewComboBox(winName,"CUL","gCraftCollectibleName15",group,collectStringCraft8)
	GUI_NewField(winName,"Min Value","gCraftCollectibleValue8",group)
	
	group = "Gearsets"
	GUI_NewNumeric(winName,"CRP","gCraftGearset8",group,"1","50")
	GUI_NewNumeric(winName,"BSM","gCraftGearset9",group,"1","50")
	GUI_NewNumeric(winName,"ARM","gCraftGearset10",group,"1","50")
	GUI_NewNumeric(winName,"GSM","gCraftGearset11",group,"1","50")
	GUI_NewNumeric(winName,"LTW","gCraftGearset12",group,"1","50")
	GUI_NewNumeric(winName,"WVR","gCraftGearset13",group,"1","50")
	GUI_NewNumeric(winName,"ALC","gCraftGearset14",group,"1","50")
	GUI_NewNumeric(winName,"CUL","gCraftGearset15",group,"1","50")
	
	GUI_UnFoldGroup(winName,GetString("status"))
	GUI_UnFoldGroup(winName,GetString("settings"))
	GUI_UnFoldGroup(winName,"Collectible")
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gCraftMinCP = Settings.FFXIVMINION.gCraftMinCP
    gCraftMaxItems = Settings.FFXIVMINION.gCraftMaxItems
	gCraftDebug = Settings.FFXIVMINION.gCraftDebug
	gCraftDebugLevel = Settings.FFXIVMINION.gCraftDebugLevel
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
	
	gCraftGearset8 = Settings.FFXIVMINION.gCraftGearset8
	gCraftGearset9 = Settings.FFXIVMINION.gCraftGearset9
	gCraftGearset10 = Settings.FFXIVMINION.gCraftGearset10
	gCraftGearset11 = Settings.FFXIVMINION.gCraftGearset11
	gCraftGearset12 = Settings.FFXIVMINION.gCraftGearset12
	gCraftGearset13 = Settings.FFXIVMINION.gCraftGearset13
	gCraftGearset14 = Settings.FFXIVMINION.gCraftGearset14
	gCraftGearset15 = Settings.FFXIVMINION.gCraftGearset15
	
	ffxiv_craft.CreateSubWindows()	
	gCraftOrderSelect = Settings.FFXIVMINION.gCraftOrderSelect
end

function ffxiv_craft.CreateSubWindows()
	ffxivminion.Windows.CraftOrders = { id = "CraftOrders", Name = "Craft Orders", x=50, y=50, width=350, height=300, hideModule = true }
	ffxivminion.CreateWindow(ffxivminion.Windows.CraftOrders)
	winName = ffxivminion.Windows.CraftOrders.Name
	GUI_NewButton(winName,"Save Profile","ffxiv_craft.SaveProfile")
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	ffxivminion.Windows.CraftOrderSaveDialog = { id = "CraftOrderSaveDialog", Name = "Craft - Save As..", x=50, y=50, width=250, height=100, hideModule = true }
	ffxivminion.CreateWindow(ffxivminion.Windows.CraftOrderSaveDialog)
	winName = ffxivminion.Windows.CraftOrderSaveDialog.Name
	
	GUI_NewButton(winName,"Create New Profile","ffxiv_craft.CreateNewProfile")
	
	local group = GetString("details")
	GUI_NewField(winName,"New Order List","gCraftOrderNewProfile",group)
	
	GUI_UnFoldGroup(winName,group)
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	ffxivminion.Windows.CraftOrderEdit = { id = "CraftOrderEdit", Name = "Craft Order Edit", x=50, y=50, width=350, height=300, hideModule = true }
	ffxivminion.CreateWindow(ffxivminion.Windows.CraftOrderEdit)
	winName = ffxivminion.Windows.CraftOrderEdit.Name
	
	local group = GetString("details")	
	GUI_NewNumeric(winName,"Amount","gCraftOrderEditAmount",group)
	GUI_NewCheckbox(winName,"Count HQ Only","gCraftOrderEditRequireHQ",group)
	GUI_NewCheckbox(winName,"Count HQ","gCraftOrderEditCountHQ",group)
	GUI_NewCheckbox(winName,"Use QuickSynth","gCraftOrderEditQuick",group)
	GUI_NewCheckbox(winName,"Use HQ Mats","gCraftOrderEditHQ",group)
	GUI_NewComboBox(winName,GetString("skillProfile"),"gCraftOrderEditProfile",group,ffxivminion.Strings.SKMProfiles())
	
	GUI_NewButton(winName,"Delete Order","ffxiv_craft.DeleteOrder")
	
	gCraftOrderEditID = ""
	gCraftOrderEditAmount = 1
	gCraftOrderEditRequireHQ = "0"
	gCraftOrderEditCountHQ = "0"
	gCraftOrderEditQuick = "0"
	gCraftOrderEditHQ = "0"
	gCraftOrderEditProfile = GetString("none")
	
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	ffxivminion.Windows.CraftRecipes8 = { id = "CraftRecipes8", Name = "Carpenter Recipes", x=50, y=50, width=350, height=300, hideModule = true }
	ffxivminion.CreateWindow(ffxivminion.Windows.CraftRecipes8)
	winName = ffxivminion.Windows.CraftRecipes8.Name
	local group = GetString("settings")
	GUI_NewComboBox(winName,"Craft","gCraftOrderSelect",group,"CRP,BSM,ARM,GSM,LTW,WVR,ALC,CUL")
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	ffxivminion.Windows.CraftRecipes9 = { id = "CraftRecipes9", Name = "Blacksmith Recipes", x=50, y=50, width=350, height=300, hideModule = true }
	ffxivminion.CreateWindow(ffxivminion.Windows.CraftRecipes9)
	winName = ffxivminion.Windows.CraftRecipes9.Name
	local group = GetString("settings")
	GUI_NewComboBox(winName,"Craft","gCraftOrderSelect",group,"CRP,BSM,ARM,GSM,LTW,WVR,ALC,CUL")
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	ffxivminion.Windows.CraftRecipes10 = { id = "CraftRecipes10", Name = "Armorer Recipes", x=50, y=50, width=350, height=300, hideModule = true }
	ffxivminion.CreateWindow(ffxivminion.Windows.CraftRecipes10)
	winName = ffxivminion.Windows.CraftRecipes10.Name
	local group = GetString("settings")
	GUI_NewComboBox(winName,"Craft","gCraftOrderSelect",group,"CRP,BSM,ARM,GSM,LTW,WVR,ALC,CUL")
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	ffxivminion.Windows.CraftRecipes11 = { id = "CraftRecipes11", Name = "Goldsmith Recipes", x=50, y=50, width=350, height=300, hideModule = true }
	ffxivminion.CreateWindow(ffxivminion.Windows.CraftRecipes11)
	winName = ffxivminion.Windows.CraftRecipes11.Name
	local group = GetString("settings")
	GUI_NewComboBox(winName,"Craft","gCraftOrderSelect",group,"CRP,BSM,ARM,GSM,LTW,WVR,ALC,CUL")
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	ffxivminion.Windows.CraftRecipes12 = { id = "CraftRecipes12", Name = "Leatherworker Recipes", x=50, y=50, width=350, height=300, hideModule = true }
	ffxivminion.CreateWindow(ffxivminion.Windows.CraftRecipes12)
	winName = ffxivminion.Windows.CraftRecipes12.Name
	local group = GetString("settings")
	GUI_NewComboBox(winName,"Craft","gCraftOrderSelect",group,"CRP,BSM,ARM,GSM,LTW,WVR,ALC,CUL")
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	ffxivminion.Windows.CraftRecipes13 = { id = "CraftRecipes13", Name = "Weaver Recipes", x=50, y=50, width=350, height=300, hideModule = true }
	ffxivminion.CreateWindow(ffxivminion.Windows.CraftRecipes13)
	winName = ffxivminion.Windows.CraftRecipes13.Name
	local group = GetString("settings")
	GUI_NewComboBox(winName,"Craft","gCraftOrderSelect",group,"CRP,BSM,ARM,GSM,LTW,WVR,ALC,CUL")
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	ffxivminion.Windows.CraftRecipes14 = { id = "CraftRecipes14", Name = "Alchemy Recipes", x=50, y=50, width=350, height=300, hideModule = true }
	ffxivminion.CreateWindow(ffxivminion.Windows.CraftRecipes14)
	winName = ffxivminion.Windows.CraftRecipes14.Name
	local group = GetString("settings")
	GUI_NewComboBox(winName,"Craft","gCraftOrderSelect",group,"CRP,BSM,ARM,GSM,LTW,WVR,ALC,CUL")
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	ffxivminion.Windows.CraftRecipes15 = { id = "CraftRecipes15", Name = "Culinarian Recipes", x=50, y=50, width=350, height=300, hideModule = true }
	ffxivminion.CreateWindow(ffxivminion.Windows.CraftRecipes15)
	winName = ffxivminion.Windows.CraftRecipes15.Name
	local group = GetString("settings")
	GUI_NewComboBox(winName,"Craft","gCraftOrderSelect",group,"CRP,BSM,ARM,GSM,LTW,WVR,ALC,CUL")
	GUI_UnFoldGroup(winName,GetString("settings"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	ffxivminion.Windows.CraftRecipesInspect = { id = "Inspect Recipe", Name = "Inspect Recipe", x=50, y=50, width=250, height=400, hideModule = true }
	ffxivminion.CreateWindow(ffxivminion.Windows.CraftRecipesInspect)
	winName = ffxivminion.Windows.CraftRecipesInspect.Name
	
	local group = "Elements"
	GUI_NewField(winName,"Recipe ID","gCraftInspectID",group)
	GUI_NewField(winName,"Progress","gCraftInspectProgress",group)
	GUI_NewField(winName,"Durability","gCraftInspectDurability",group)
	GUI_NewField(winName,"Craftsmanship","gCraftInspectCraftsmanship",group)
	GUI_NewField(winName,"Control","gCraftInspectControl",group)
	GUI_NewField(winName,"Required Equip","gCraftInspectREquip",group)
	GUI_NewField(winName,"Crystal 1","gCraftInspectCrystal1",group)
	GUI_NewField(winName,"Amount","gCraftInspectCAmount1",group)
	GUI_NewField(winName,"Crystal 2","gCraftInspectCrystal2",group)
	GUI_NewField(winName,"Amount","gCraftInspectCAmount2",group)
	GUI_NewField(winName,"Ingredient 1","gCraftInspectIngredient1",group)
	GUI_NewField(winName,"Amount","gCraftInspectIAmount1",group)
	GUI_NewField(winName,"Ingredient 2","gCraftInspectIngredient2",group)
	GUI_NewField(winName,"Amount","gCraftInspectIAmount2",group)
	GUI_NewField(winName,"Ingredient 3","gCraftInspectIngredient3",group)
	GUI_NewField(winName,"Amount","gCraftInspectIAmount3",group)
	GUI_NewField(winName,"Ingredient 4","gCraftInspectIngredient4",group)
	GUI_NewField(winName,"Amount","gCraftInspectIAmount4",group)
	GUI_NewField(winName,"Ingredient 5","gCraftInspectIngredient5",group)
	GUI_NewField(winName,"Amount","gCraftInspectIAmount5",group)
	GUI_NewField(winName,"Ingredient 6","gCraftInspectIngredient6",group)
	GUI_NewField(winName,"Amount","gCraftInspectIAmount6",group)
	GUI_NewField(winName,"Can Craft","gCraftInspectCanCraft",group)
	GUI_NewField(winName,"Craftable","gCraftInspectCraftable",group)
	
	GUI_NewButton(winName, "Refresh","ffxiv_craft.RefreshRecipe",group)
	
	GUI_NewButton(winName, "Add to Orders","ffxiv_craft.AddToOrders")
	
	gCraftInspectProgress = ""
	gCraftInspectDurability = ""
	gCraftInspectCraftsmanship = ""
	gCraftInspectControl = ""
	gCraftInspectREquip = ""
	gCraftInspectCrystal1 = ""
	gCraftInspectCAmount1 = ""
	gCraftInspectCrystal2 = ""
	gCraftInspectCAmount2 = ""
	gCraftInspectIngredient1 = ""
	gCraftInspectIAmount1 = ""
	gCraftInspectIngredient2 = ""
	gCraftInspectIAmount2 = ""
	gCraftInspectIngredient3 = ""
	gCraftInspectIAmount3 = ""
	gCraftInspectIngredient4 = ""
	gCraftInspectIAmount4 = ""
	gCraftInspectIngredient5 = ""
	gCraftInspectIAmount5 = ""
	gCraftInspectIngredient6 = ""
	gCraftInspectIAmount6 = ""
	
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
end

function ffxiv_craft.UpdateProfiles(doload)
	doload = IsNull(doload,true)
	
    local profiles = GetString("none")
    local found = GetString("none")	
    local profilelist = dirlist(ffxiv_craft.profilePath,".*lua")
    if ( TableSize(profilelist) > 0) then
		for i,profile in pairs(profilelist) do			
            profile = string.gsub(profile, ".lua", "")
            profiles = profiles..","..profile
			if (doload) then
				if ( Settings.FFXIVMINION.gLastCraftProfile ~= nil and Settings.FFXIVMINION.gLastCraftProfile == profile ) then
					found = profile
				end
			end
        end		
    end
	
    gProfile_listitems = profiles
	GUI_RefreshWindow(GetString("craftMode"))
	
	if (doload) then
		gProfile = found
		ffxiv_craft.LoadProfile(gProfile)
	end
end

function ffxiv_craft.LoadProfile(strName)
	if (strName ~= GetString("none")) then
		if (FileExists(ffxiv_craft.profilePath..strName..".lua")) then
			local info,e = persistence.load(ffxiv_craft.profilePath..strName..".lua")
			if (table.valid(info)) then
				ffxiv_craft.orders = info.orders
				ffxiv_craft.ResetOrders()
			else
				if (e) then
					d("Encountered error loading crafting profile ["..e.."].")
				end
			end
		end
	else
		ffxiv_craft.orders = {}
	end
	
	ffxiv_craft.RefreshOrders(false)
end

function ffxiv_craft.ResetOrders()
	local orders = ffxiv_craft.orders
	if (table.valid(orders)) then
		for id,order in pairs(orders) do
			orders[id].completed = false
		end
	end
end

function ffxiv_craft.SaveProfile(strName)
	strName = IsNull(strName,"")
	
	local info = {}
	if (table.valid(ffxiv_craft.orders)) then
		info.orders = ffxiv_craft.orders
	else
		info.orders = {}
	end
	
	if (strName ~= "") then
		persistence.store(ffxiv_craft.profilePath..strName..".lua",info)
		ffxiv_craft.UpdateProfiles(false)
		gProfile = strName
	elseif (gProfile == GetString("none")) then
		d("No profile currently selected, asking user for new selection name.")
		ffxiv_craft.SaveProfileDialog()
	else
		persistence.store(ffxiv_craft.profilePath..gProfile..".lua",info)
	end
end

function ffxiv_craft.SaveProfileDialog()
	local winName = ffxivminion.Windows.CraftOrderSaveDialog.Name
	local wnd = GUI_GetWindowInfo(ffxivminion.Windows.CraftOrders.Name)
	if (wnd) then
		GUI_MoveWindow( winName, wnd.x,wnd.y) 
	end
	gCraftOrderNewProfile = ""
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName,true)
end

function ffxiv_craft.CreateNewProfile()
	if (ValidString(gCraftOrderNewProfile)) then
		local winName = ffxivminion.Windows.CraftOrderSaveDialog.Name
		GUI_WindowVisible(winName,false)
		d("Creating new profile ["..tostring(gCraftOrderNewProfile).."].")
		ffxiv_craft.SaveProfile(gCraftOrderNewProfile)
	end
end

function ffxiv_craft.ShowCraftOrders()
	local winName = ffxivminion.Windows.CraftOrders.Name
	
	if (ffxiv_craft.ordersVisible ) then
        GUI_WindowVisible(winName,false)	
        ffxiv_craft.ordersVisible = false
    else
        local wnd = GUI_GetWindowInfo(ffxivminion.Windows.Craft.Name)
		GUI_MoveWindow( winName, wnd.x+wnd.width,wnd.y) 
		ffxivminion.SizeWindow(winName)
		GUI_WindowVisible(winName, true)
        ffxiv_craft.ordersVisible  = true
    end
end

function ffxiv_craft.SwitchCraftWindow()
	local crafts = ffxiv_craft.crafts
	
	local craftid = crafts[tostring(gCraftOrderSelect)]
	if (not craftid) then
		Settings.FFXIVMINION.gCraftOrderSelect = "CRP"
		gCraftOrderSelect = Settings.FFXIVMINION.gCraftOrderSelect
		craftid = crafts[tostring(gCraftOrderSelect)]
	end
	
	for craftstring,craftnum in pairs(crafts) do
		if (craftnum ~= craftid) then
			local windowid = "CraftRecipes"..tostring(craftnum)
			local window = ffxivminion.Windows[windowid]
			if (window) then
				local winName = window.Name
				GUI_WindowVisible(winName, false)
			end
		end
	end
	
	local windowid = "CraftRecipes"..tostring(craftid)
	local window = ffxivminion.Windows[windowid]
	if (window) then
		local winName = window.Name
		local wnd = GUI_GetWindowInfo(ffxivminion.Windows.Craft.Name)
		GUI_MoveWindow( winName, wnd.x+wnd.width,wnd.y) 
		ffxiv_craft.RefreshItems(craftid)
		ffxivminion.SizeWindow(winName)
		GUI_WindowVisible(winName, true)
	end
end

function ffxiv_craft.AddToOrders()
	local recipeid = tonumber(gCraftInspectID) or 0
	
	if (recipeid ~= 0) then
		local orders = ffxiv_craft.orders
		if (orders[recipeid] == nil) then
			local recipeDetails = AceLib.API.Items.GetRecipeDetails(recipeid)
			local neworder = { 	id = recipeid, item = recipeDetails.id, amount = 0, usequick = false, usehq = false, profile = "",
								requirehq = false, counthq = false,
								name = recipeDetails.name, level = recipeDetails.attemptlevel,
								class = recipeDetails.class, page = recipeDetails.page}
			orders[recipeid] = neworder
			
			ffxiv_craft.RefreshOrders()
		end
	end
end

function ffxiv_craft.UsingProfile()
	return table.valid(ffxiv_craft.orders)
end

function ffxiv_craft.RefreshOrders(doshow)
	doshow = IsNull(doshow,true)
	
	local winName = ffxivminion.Windows.CraftOrders.Name
	local group = "Orders"
	GUI_DeleteGroup(winName,group)
		
	local orders = ffxiv_craft.orders
	if (table.valid(orders)) then
		local sortfunc = function(orders,a,b) 
			return (orders[a].page < orders[b].page) or (orders[a].page == orders[b].page and orders[a].level < orders[b].level) 
		end
		for id,order in spairs(orders, sortfunc) do
			GUI_NewButton(winName,order.name.."["..tostring(id).."]","ffxiv_craft_EditOrder"..tostring(id),group)
		end
		GUI_UnFoldGroup(winName,group)
	end
	
	ffxivminion.SizeWindow(winName)
	if (doshow) then
		GUI_WindowVisible(winName, true)
	end
end

function ffxiv_craft.RefreshRecipe()
	ffxiv_craft.InspectRecipe(gCraftInspectID)
end

function ffxiv_craft.EditOrder(key)
	local key = tonumber(key) or 0
	
	local orders = ffxiv_craft.orders
	if (table.valid(orders)) then
		local thisOrder = orders[key]
		if (thisOrder) then
			local winName = ffxivminion.Windows.CraftOrderEdit.Name
				
			gCraftOrderEditID = thisOrder.id
			gCraftOrderEditAmount = thisOrder.amount
			gCraftOrderEditRequireHQ = IIF(thisOrder.requirehq,"1","0")
			gCraftOrderEditCountHQ = IIF(thisOrder.counthq,"1","0")
			gCraftOrderEditQuick = IIF(thisOrder.usequick,"1","0")
			gCraftOrderEditHQ = IIF(thisOrder.usehq,"1","0")
			gCraftOrderEditProfile = IsNull(thisOrder.profile,GetString("none"))
			
			GUI_UnFoldGroup(winName,GetString("details"))
			ffxivminion.SizeWindow(winName)
			GUI_WindowVisible(winName, true)
		end
	end
end

function ffxiv_craft.DeleteOrder()
	local key = tonumber(gCraftOrderEditID) or 0
	
	local orders = ffxiv_craft.orders
	if (orders and orders[key]) then
		if (TableSize(orders) > 1) then
			orders[key] = nil
		else
			ffxiv_craft.orders = {}
		end
		GUI_WindowVisible(ffxivminion.Windows.CraftOrderEdit.Name, false)
		ffxiv_craft.RefreshOrders()
	end
end

function ffxiv_craft.EditOrderElement(elem,newval)
	local key = tonumber(gCraftOrderEditID) or 0
	
	local orders = ffxiv_craft.orders
	if (table.valid(orders)) then
		local thisOrder = orders[key]
		if (thisOrder) then
			if (elem == "gCraftOrderEditAmount") then
				thisOrder["amount"] = tonumber(newval)
			elseif (elem == "gCraftOrderEditRequireHQ") then
				thisOrder["requirehq"] = (newval == "1")
			elseif (elem == "gCraftOrderEditCountHQ") then
				thisOrder["counthq"] = (newval == "1")
			elseif (elem == "gCraftOrderEditQuick") then
				thisOrder["usequick"] = (newval == "1")
			elseif (elem == "gCraftOrderEditHQ") then
				thisOrder["usehq"] = (newval == "1")
			elseif (elem == "gCraftOrderEditProfile") then
				thisOrder["profile"] = newval
			end
		end
	end
end

function ffxiv_craft.InspectRecipe(key)
	local key = tonumber(key) or 0
	local crafts = ffxiv_craft.crafts
	
	local craftid = crafts[tostring(gCraftOrderSelect)]
	local winName = ffxivminion.Windows.CraftRecipesInspect.Name
	
	local recipeDetails = AceLib.API.Items.GetRecipeDetails(key)
	gCraftInspectID = key
	gCraftInspectProgress = recipeDetails.progress or ""
	gCraftInspectDurability = recipeDetails.durability or ""
	gCraftInspectCraftsmanship = recipeDetails.craftsmanship or ""
	gCraftInspectControl = recipeDetails.control or ""
	gCraftInspectREquip = IIF(recipeDetails.requiredequip ~= 0,IsNull(recipeDetails.requipname,"").."["..IsNull(recipeDetails.requiredequip,"").."]","")
	gCraftInspectCrystal1 = IIF(recipeDetails.crystal1 ~= 0,IsNull(recipeDetails.c1name,"").."["..IsNull(recipeDetails.crystal1,"").."]","")
	gCraftInspectCAmount1 = IIF(recipeDetails.crystal1 ~= 0,tostring(IsNull(recipeDetails.camount1,0)).."("..IsNull(ItemCount(recipeDetails.crystal1),0)..")","")
	gCraftInspectCrystal2 = IIF(recipeDetails.crystal2 ~= 0,IsNull(recipeDetails.c2name,"").."["..IsNull(recipeDetails.crystal2,"").."]","")
	gCraftInspectCAmount2 = IIF(recipeDetails.crystal2 ~= 0,tostring(IsNull(recipeDetails.camount2,0)).."("..IsNull(ItemCount(recipeDetails.crystal2),0)..")","")
	gCraftInspectIngredient1 = IIF(recipeDetails.ingredient1 ~= 0,IsNull(recipeDetails.ing1name,"").."["..IsNull(recipeDetails.ingredient1,"").."]","")
	gCraftInspectIAmount1 = IIF(recipeDetails.iamount1 > 0,tostring(IsNull(recipeDetails.iamount1,0)).."("..IsNull(ItemCount(recipeDetails.ingredient1,true),0)..")","")
	gCraftInspectIngredient2 = IIF(recipeDetails.ingredient2 ~= 0,IsNull(recipeDetails.ing2name,"").."["..IsNull(recipeDetails.ingredient2,"").."]","")
	gCraftInspectIAmount2 = IIF(recipeDetails.iamount2 > 0,tostring(IsNull(recipeDetails.iamount2,0)).."("..IsNull(ItemCount(recipeDetails.ingredient2,true),0)..")","")
	gCraftInspectIngredient3 = IIF(recipeDetails.ingredient3 ~= 0,IsNull(recipeDetails.ing3name,"").."["..IsNull(recipeDetails.ingredient3,"").."]","")
	gCraftInspectIAmount3 = IIF(recipeDetails.iamount3 > 0,tostring(IsNull(recipeDetails.iamount3,0)).."("..IsNull(ItemCount(recipeDetails.ingredient3,true),0)..")","")
	gCraftInspectIngredient4 = IIF(recipeDetails.ingredient4 ~= 0,IsNull(recipeDetails.ing4name,"").."["..IsNull(recipeDetails.ingredient4,"").."]","")
	gCraftInspectIAmount4 = IIF(recipeDetails.iamount4 > 0,tostring(IsNull(recipeDetails.iamount4,0)).."("..IsNull(ItemCount(recipeDetails.ingredient4,true),0)..")","")
	gCraftInspectIngredient5 = IIF(recipeDetails.ingredient5 ~= 0,IsNull(recipeDetails.ing5name,"").."["..IsNull(recipeDetails.ingredient5,"").."]","")
	gCraftInspectIAmount5 = IIF(recipeDetails.iamount5 > 0,tostring(IsNull(recipeDetails.iamount5,0)).."("..IsNull(ItemCount(recipeDetails.ingredient5,true),0)..")","")
	gCraftInspectIngredient6 = IIF(recipeDetails.ingredient6 ~= 0,IsNull(recipeDetails.ing6name,"").."["..IsNull(recipeDetails.ingredient6,"").."]","")
	gCraftInspectIAmount6 = IIF(recipeDetails.iamount6 > 0,tostring(IsNull(recipeDetails.iamount6,0)).."("..IsNull(ItemCount(recipeDetails.ingredient6,true),0)..")","")

	local canCraft,maxAmount = AceLib.API.Items.CanCraft(key)
	gCraftInspectCanCraft = tostring(canCraft)
	gCraftInspectCraftable = maxAmount
	
	local windowid = "CraftRecipes"..tostring(craftid)
	local window = ffxivminion.Windows[windowid]
	if (window) then
		local wnd = GUI_GetWindowInfo(window.Name)
		GUI_MoveWindow( winName, wnd.x+wnd.width,wnd.y) 
	end
	GUI_UnFoldGroup(winName,"Elements")
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, true)
end

function ffxiv_craft.RefreshItems(craftid)
	local crafts = ffxiv_craft.crafts
	
	local craftid = crafts[tostring(gCraftOrderSelect)]
	local windowid = "CraftRecipes"..tostring(craftid)
	local window = ffxivminion.Windows[windowid]
	if (window) then
		local winName = window.Name
		for k = 10,60,10 do
			local group = tostring(k-9).."-"..tostring(k)
			local recipes,dictionary = AceLib.API.Items.BuildRecipeString(craftid,0,(k-9),k)
			if (dictionary) then
				local sortfunc = function(dictionary,a,b) 
					return (dictionary[a].name < dictionary[b].name)
				end
				for _,data in spairs(dictionary, sortfunc) do
					GUI_NewButton(winName,data.name,"ffxiv_craft_InspectRecipe"..tostring(data.recipeid),group)
				end
			end
		end
	end
end

function ffxiv_craft.GUIVarUpdate(Event, NewVals, OldVals)
	local backupVals = {}
	for k,v in pairs(OldVals) do
		backupVals[k] = v
	end
    for k,v in pairs(NewVals) do
        if 	( 	k == "gCraftMinCP" or 
				k == "gCraftMaxItems" or
				k == "gCraftDebug" or
				k == "gCraftDebugLevel" or
				string.find(tostring(k),"gCraftCollectible") or
				string.find(tostring(k),"gCraftGearset"))				
		then
            SafeSetVar(tostring(k),v)
		elseif (k == "gCraftOrderSelect") then
			SafeSetVar(tostring(k),v)
			ffxiv_craft.SwitchCraftWindow()
		elseif (string.find(tostring(k),"gCraftOrderEdit")) then
			ffxiv_craft.EditOrderElement(k,v)
		elseif ( k == "gProfile" and gBotMode == GetString("craftMode")) then
			ffxiv_craft.LoadProfile(v)
			Settings.FFXIVMINION["gLastCraftProfile"] = v
        end
    end
    GUI_RefreshWindow(GetString("craftMode"))
end

function ffxiv_craft.HandleButtons( Event, Button )	
	if ( Event == "GUI.Item" ) then
		if (string.find(Button,"ffxiv_craft_InspectRecipe")) then
			ffxiv_craft.InspectRecipe(string.gsub(Button,"ffxiv_craft_InspectRecipe",""))
		elseif (string.find(Button,"ffxiv_craft_EditOrder")) then
			ffxiv_craft.EditOrder(string.gsub(Button,"ffxiv_craft_EditOrder",""))	
		elseif (string.find(Button,"ffxiv_craft%.")) then
			ExecuteFunction(Button)
		end
	end
end

RegisterEventHandler("GUI.Update",ffxiv_craft.GUIVarUpdate)
RegisterEventHandler("GUI.Item", ffxiv_craft.HandleButtons )
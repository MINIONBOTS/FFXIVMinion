ffxiv_craft = {}
ffxiv_craft.crafts = {
	["CRP"] = 8,	["BSM"] = 9,	["ARM"] = 10,	["GSM"] = 11,
	["LTW"] = 12,	["WVR"] = 13,	["ALC"] = 14,	["CUL"] = 15,
}
ffxiv_craft.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\CraftProfiles\]]
ffxiv_craft.profiles = {}
ffxiv_craft.profilesDisplay = {}
ffxiv_craft.profileData = {}
ffxiv_craft.orders = {}
ffxiv_craft.ordersVisible = false
ffxiv_craft.orderSelectorVisible = false
ffxiv_craft.dictionaries = {}
ffxiv_craft.dictionariesDisplay = {}

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
	if (not ffxiv_craft.IsCrafting()) then
		if (ffxiv_craft.UsingProfile()) then
			local recipe = ml_task_hub:CurrentTask().recipe
			local itemid = ml_task_hub:CurrentTask().itemid
			local requireHQ = ml_task_hub:CurrentTask().requireHQ
			local countHQ = ml_task_hub:CurrentTask().countHQ
			local requiredItems = ml_task_hub:CurrentTask().requiredItems
			local startingCount = ml_task_hub:CurrentTask().startingCount 
			
			local itemcount = 0
			if (requireHQ or countHQ) then
				itemcount = itemcount + ItemCount(itemid + 1000000)
			elseif (not requireHQ) then
				itemcount = itemcount + ItemCount(itemid)
			end
			
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
		ml_global_information:ToggleRun()
	end
end

c_opencraftwnd = inheritsFrom( ml_cause )
e_opencraftwnd  = inheritsFrom( ml_effect )
function c_opencraftwnd:evaluate()
	if (MIsCasting() or not ml_task_hub:CurrentTask().allowWindowOpen ) then
		return false
	end
	
	if (not IsControlOpen("Synthesis") and not IsControlOpen("SynthesisSimple") and not IsControlOpen("RecipeNote")) then
		local logOpen = ActionList:Get(10,9)
		if (logOpen and logOpen.usable) then
			logOpen:Cast(Player.id)
			ml_global_information.Await(1000, 1500, function () return IsControlOpen("RecipeNote") end)
		end
		return true
	end
	
    return false
end

function e_opencraftwnd:execute()
end

c_startcraft = inheritsFrom( ml_cause )
e_startcraft = inheritsFrom( ml_effect )
function c_startcraft:evaluate()
	if (not ffxiv_craft.IsCrafting() and IsControlOpen("RecipeNote")) then
		
		if (ffxiv_craft.UsingProfile()) then
			local recipe = ml_task_hub:CurrentTask().recipe
			local jobRequired = recipe.class + 8
			
			if (Player.job == jobRequired) then
				local itemid = ml_task_hub:CurrentTask().itemid
				local requireHQ = ml_task_hub:CurrentTask().requireHQ
				local countHQ = ml_task_hub:CurrentTask().countHQ
				local canCraft,maxAmount = AceLib.API.Items.CanCraft(recipe.id)
				
				local itemcount = 0
				if (requireHQ or countHQ) then
					itemcount = itemcount + ItemCount(itemid + 1000000)
				elseif (not requireHQ) then
					itemcount = itemcount + ItemCount(itemid)
				end
					
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
			local minCP = tonumber(gCraftMinCP) or 0
			if (Player.cp.current < minCP) then
				return false
			end
			
			local mats = Crafting:GetCraftingMats()
			if (table.valid(mats)) then
				for i = 1,6 do
					local ingredient = mats[i]
					if (ingredient) then
						if (gCraftUseHQ) then
							if (ingredient.needed <= ingredient.inventoryhq) then
								Crafting:SetCraftingMats(i-1,ingredient.needed)
							else
								Crafting:SetCraftingMats(i-1,ingredient.inventoryhq)
							end
						else
							if (ingredient.needed > ingredient.inventorynq) then
								ffxiv_dialog_manager.IssueStopNotice("Need HQ", "Cannot craft this item without using HQ mats.", "okonly")
								return false
							end
						end
					end
				end
			end	
			
			if ( Crafting:CanCraftSelectedItem() ) then
				return true
			end
		end
	end	
	
    return false
end

function e_startcraft:execute()
	SkillMgr.prevSkillList = {}
	
	if (ffxiv_craft.UsingProfile()) then
		local recipe = ml_task_hub:CurrentTask().recipe
		local itemid = ml_task_hub:CurrentTask().itemid
		if (not ml_task_hub:CurrentTask().recipeSelected) then
			cd("Recipe phase 1, set to: ["..tostring(recipe.class)..","..tostring(recipe.page)..","..tostring(recipe.id).."].",3)
			Crafting:SetRecipe(recipe.class,recipe.page,recipe.id)
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
			if (not ml_task_hub:CurrentTask().matsSet) then
				local useHQ = ml_task_hub:CurrentTask().useHQ
				local mats = Crafting:GetCraftingMats()
				if (table.valid(mats) and useHQ) then
					for i = 1,6 do
						local ingredient = mats[i]
						local hqAmount = ml_task_hub:CurrentTask()["hq"..tostring(i)]
						if (hqAmount > 0) then
							if (ingredient.inventoryhq >= hqAmount) then
								Crafting:SetCraftingMats(i-1,hqAmount)
							else
								d("Stop crafting item, not enough HQ.")
								e_craftlimit:execute()
								return false
							end
						end
					end
					ml_task_hub:CurrentTask().matsSet = true
				end				
			else
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
						if (IsControlOpen("RecipeNote")) then
							ffxiv_craft.ToggleCraftingLog()
						end
						SkillMgr.newCraft = true
						ml_task_hub:CurrentTask().allowWindowOpen = false
					else
						Crafting:CraftSelectedItem()
						if (IsControlOpen("RecipeNote")) then
							ffxiv_craft.ToggleCraftingLog()
						end
						SkillMgr.newCraft = true
						ml_task_hub:CurrentTask().allowWindowOpen = false
					end
					ml_global_information.Await(2500)
					return
				else
					if (ml_task_hub:CurrentTask().failedAttempts < 2) then
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
		end
	else				
		Crafting:CraftSelectedItem()
		if (IsControlOpen("RecipeNote")) then
			ffxiv_craft.ToggleCraftingLog()
		end
		ml_task_hub:ThisTask().attemptedStarts = ml_task_hub:ThisTask().attemptedStarts + 1
		SkillMgr.newCraft = true
		ml_global_information.Await(2500)
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

	e_precraftbuff.id = 0
	e_precraftbuff.item = nil
	e_precraftbuff.activity = ""
	e_precraftbuff.requiresLogClose = false
	
	if (not ffxiv_craft.IsCrafting()) then
		if (NeedsRepair()) then
			cd("[PreCraftBuff]: Need to repair.",3)
			e_precraftbuff.activity = "repair"
			e_precraftbuff.requiresLogClose = false
			return true
		end
		
		if (ffxiv_craft.UsingProfile()) then
			if (gCraftFood ~= GetString("None")) then
				local foodDetails = ml_global_information.foods[gCraftFood]
				if (foodDetails) then
					local foodID = foodDetails.id
					local foodStack = foodDetails.buffstackid
					
					local food, action = GetItem(foodID)
					if (food and food:IsReady(Player.id) and action and MissingBuffX(Player,48,foodStack,60)) then
						cd("[PreCraftBuff]: Need to eat, using override food choice.",3)
						e_precraftbuff.activity = "eat"
						e_precraftbuff.id = foodID
						e_precraftbuff.requiresLogClose = true
						return true
					end
				end
			else
				local requiredFood = ml_task_hub:CurrentTask().requiredFood
				if (requiredFood) then
					local foodDetails = ml_global_information.foods[requiredFood]
					if (foodDetails) then
						local foodID = foodDetails.id
						local foodStack = foodDetails.buffstackid
						
						local food, action = GetItem(foodID)
						if (food and food:IsReady(Player.id) and action and MissingBuffX(Player,48,foodStack,60)) then
							cd("[PreCraftBuff]: Need to eat, using order specific food.",3)
							e_precraftbuff.activity = "eat"
							e_precraftbuff.id = foodID
							e_precraftbuff.requiresLogClose = true
							return true
						end
					end
				end
			end
		else
			if (gFood ~= "None") then
				local foodID = ml_global_information.foods[gFood]
				local food, action = GetItem(foodID)
				if (food and food:IsReady(Player.id) and action and MissingBuff(Player,48,60)) then
					cd("[PreCraftBuff]: Need to eat.",3)
					e_precraftbuff.activity = "eat"
					e_precraftbuff.id = foodID
					e_precraftbuff.requiresLogClose = true
					return true
				end
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
		if (IsControlOpen("RecipeNote")) then
			ffxiv_craft.ToggleCraftingLog()
			ml_task_hub:CurrentTask().allowWindowOpen = true
			ml_global_information.Await(5000, function () return (not IsControlOpen("RecipeNote") and not IsLocked()) end)
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
	if ( ffxiv_craft.IsCrafting() or IsControlOpen("Synthesis")) then		
		return true	
	end
    return false
end
function e_craft:execute()
	ml_task_hub:CurrentTask().recipeSelected = false
	ml_task_hub:CurrentTask().matsSet = false
	if (ml_task_hub:ThisTask().attemptedStarts > 0) then
		ml_task_hub:ThisTask().attemptedStarts = 0
		ml_task_hub:ThisTask().synthStarted = true
		ml_task_hub:ThisTask().itemsCrafted = ml_task_hub:ThisTask().itemsCrafted + 1
	end
    SkillMgr.Craft()
	ml_global_information.Await(1000)
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
					if (string.contains(tostring(info.itemid),tostring(collectible.id))) then
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
				d("Cannot collect item ["..info.name.."], collectibility rating not approved.",2)
				UseControlAction("SelectYesNoCountItem","No")
			else
				d("Attempting to collect item ["..info.name.."], collectibility rating approved.",2)
				UseControlAction("SelectYesNoCountItem","Yes")
			end
			ml_global_information.Await(3000, function () return not IsControlOpen("SelectYesNoCountItem") end)				
			return true
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
		if (UseControlAction("SynthesisSimple","Quit")) then
			ml_global_information.Await(6000)
			return true
		end
	end
	
	if (Player.action == 241) then
		ml_task_hub:CurrentTask().quickTimer = Now()
	end
end

c_selectcraft = inheritsFrom( ml_cause )
e_selectcraft = inheritsFrom( ml_effect )
function c_selectcraft:evaluate()
	if (ffxiv_craft.UsingProfile()) then
		local orders = ffxiv_craft.orders
		for id,order in pairs(orders) do
			if (order.completed == nil) then
				cd("[SelectCraft]: Initializing the completion status for id ["..tostring(id).."].",3)
				orders[id].completed = false
			end
			if (order.completed == false and order.skip ~= true) then
				local canCraft = AceLib.API.Items.CanCraft(id)
				if (canCraft) then
					cd("[SelectCraft]: Found an incomplete order ["..tostring(id).."], select a new craft.",3)
					return true
				end
			end
		end
		
		ffxiv_dialog_manager.IssueStopNotice("Nothing Craftable", "You cannot craft any of the items in the profile.", "okonly")
	else
		return true
	end
	return false
end
function e_selectcraft:execute()
	local newTask = ffxiv_task_craftitems.Create()
	if (ffxiv_craft.UsingProfile()) then
		local orders = ffxiv_craft.orders
		
		local sortfunc = function(orders,a,b) 
			return (orders[a].page < orders[b].page) or (orders[a].page == orders[b].page and orders[a].level < orders[b].level) 
		end
		
		local foundSelection = false
		for id,order in spairs(orders, sortfunc) do
			if (not order.completed and not order.skip) then
				local canCraft = AceLib.API.Items.CanCraft(id)
				if (canCraft) then
					
					local itemid = order.item
					local itemcount = 0
					if (order.requirehq or order.counthq) then
						itemcount = itemcount + ItemCount(itemid + 1000000)
					elseif (not order.requirehq) then
						itemcount = itemcount + ItemCount(itemid)
					end
					
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
					newTask.requiredFood = order.requiredfood
					
					for i = 1,6 do
						newTask["hq"..tostring(i)] = IsNull(order["hq"..tostring(i)],0)
					end
					
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
	ml_global_information.Await(2500)
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
	newinst.useHQ = false
	newinst.recipe = {}
	newinst.recipeSelected = false
	newinst.matsSet = false
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
	Hacks:Disable3DRendering(gDisableDrawing)
	gAvoidAOE = Settings.FFXIVMINION.gAvoidAOE
	gAutoEquip = Settings.FFXIVMINION.gAutoEquip
end

-- New GUI.
function ffxiv_task_craft:UIInit()
	gCrafts = {"CRP","BSM","ARM","GSM","LTW","WVR","ALC","CUL"}
	ffxiv_craft.profiles, ffxiv_craft.profilesDisplay = GetPublicProfiles(ffxiv_craft.profilePath,".*lua")
	
	local uuid = GetUUID()
	if (Settings.FFXIVMINION.gLastCraftProfiles == nil) then
		Settings.FFXIVMINION.gLastCraftProfiles = {}
	end
	if (Settings.FFXIVMINION.gLastCraftProfiles[uuid] == nil) then
		Settings.FFXIVMINION.gLastCraftProfiles[uuid] = {}
	end
	
	_G["gCraftProfile"] = Settings.FFXIVMINION.gLastCraftProfiles[uuid] or ffxiv_craft.profilesDisplay[1]
	_G["gCraftProfileIndex"] = GetKeyByValue(gCraftProfile,ffxiv_craft.profilesDisplay) or 1
	if (ffxiv_craft.profilesDisplay[gCraftProfileIndex] ~= gCraftProfile) then
		_G["gCraftProfile"] = ffxiv_craft.profilesDisplay[gCraftProfileIndex]
	end
	ffxiv_craft.profileData = ffxiv_craft.profiles[gCraftProfile] or {}
	if (table.valid(ffxiv_craft.profileData)) then
		ffxiv_craft.orders = ffxiv_craft.profileData.orders
		ffxiv_craft.ResetOrders()
	end
	
	gCraftDebug = ffxivminion.GetSetting("gCraftDebug",false)
	local debugLevels = { 1, 2, 3 }
	gCraftDebugLevel = ffxivminion.GetSetting("gCraftDebugLevel",1)
	gCraftDebugLevelIndex = GetKeyByValue(gCraftDebugLevel,debugLevels)
	
	gCraftMinCP = ffxivminion.GetSetting("gCraftMinCP",0)
	gCraftMaxItems = ffxivminion.GetSetting("gCraftMaxItems",0)
	gCraftUseHQ = ffxivminion.GetSetting("gCraftUseHQ",false)
	
	for i = 8,15 do
		_G["gCraftGearset"..tostring(i)] = ffxivminion.GetSetting("gCraftGearset"..tostring(i),0)
	end
	
	gCraftOrderSelectIndex = 1
	gCraftOrderSelect = ffxivminion.GetSetting("gCraftOrderSelect","CRP")	
	gCraftCollectablePresets = ffxivminion.GetSetting("gCraftCollectablePresets",{})	
	
	gCraftFood = ffxivminion.GetSetting("gCraftFood",GetString("none"))
	gCraftFoodIndex = 1
	
	-- Order Stuff
	
	--Add
	gCraftOrderAddID = 0
	gCraftOrderAddAmount = 1
	gCraftOrderAddRequireHQ = false
	gCraftOrderAddCountHQ = false
	gCraftOrderAddQuick = false
	gCraftOrderAddHQ = false
	gCraftOrderAddSkillProfileIndex = 1
	gCraftOrderAddSkillProfile = GetString("None")
	gCraftOrderAddFoodIndex = 1
	gCraftOrderAddFood = GetString("None")
	
	--Edit
	gCraftOrderEditID = 0
	gCraftOrderEditAmount = 1
	gCraftOrderEditRequireHQ = false
	gCraftOrderEditCountHQ = false
	gCraftOrderEditQuick = false
	gCraftOrderEditHQ = false
	gCraftOrderEditSkillProfileIndex = 1
	gCraftOrderEditSkillProfile = GetString("None")
	gCraftOrderEditFoodIndex = 1
	gCraftOrderEditFood = GetString("None")
	
	gCraftNewProfileName = ""
	
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
	gCraftInspectCanCraft = ""
	gCraftInspectCraftable = ""
	
	for i = 1,6 do
		_G["gCraftOrderAddHQIngredient"..tostring(i)] = 0
		_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"] = false
	end
	
	for i = 1,6 do
		_G["gCraftOrderEditHQIngredient"..tostring(i)] = 0
		_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = false
	end
	
	for k = 10,60,10 do
		_G["gCraftDictionarySelectIndex"..tostring(k)] = 1
		_G["gCraftDictionarySelect"..tostring(k)] = GetString("None")				
	end
	
	self.GUI.main_tabs = GUI_CreateTabs("status,Collectable,Gearsets",true)
end

ffxiv_task_craft.GUI = {
	x = 0,
	y = 0, 
	height = 0,
	width = 0,
	
	orders = {
		open = false,
		visible = true,
		name = "Craft - Order Management",
		main_tabs = GUI_CreateTabs("Manage,Add,Edit",true),
	},
}

function ffxiv_task_craft:Draw()
	local fontSize = GUI:GetWindowFontSize()
	local windowPaddingY = ml_gui.style.current.windowpadding.y
	local framePaddingY = ml_gui.style.current.framepadding.y
	local itemSpacingY = ml_gui.style.current.itemspacing.y
	
	local profileChanged = GUI_Combo(GetString("profile"), "gCraftProfileIndex", "gCraftProfile", ffxiv_craft.profilesDisplay)
	if (profileChanged) then
		ffxiv_craft.profileData = ffxiv_craft.profiles[gCraftProfile]
		local uuid = GetUUID()
		Settings.FFXIVMINION.gLastCraftProfiles[uuid] = gCraftProfile
		ffxiv_craft.orders = ffxiv_craft.profileData.orders
		ffxiv_craft.ResetOrders()
	end
	
	GUI:SameLine(0,5)
	if (GUI:ImageButton("##main-order-edit",ml_global_information.path.."\\GUI\\UI_Textures\\w_eye.png", 16, 16)) then
		if (gCraftProfile ~= GetString("None")) then
			ffxiv_task_craft.GUI.orders.open = not ffxiv_task_craft.GUI.orders.open
		end
	end
	GUI:SameLine(0,5)
	if (GUI:ImageButton("##main-order-add",ml_global_information.path.."\\GUI\\UI_Textures\\addon.png", 16, 16)) then
		local vars = {
			{
				["type"] = "string",
				["var"] = "gCraftNewProfileName",
				["display"] = "##new-profile",
				["width"] = 300,
			},
			{
				["type"] = "spacing",
				["amount"] = 3,
			},
			{
				["type"] = "button",
				["display"] = "OK",
				["isdefault"] = true,
				["sameline"] = true,
				["amount"] = 50,
				["width"] = 100,
				["onclick"] = function ()
					GUI:CloseCurrentPopup()
					ffxiv_craft.CreateNewProfile()
				end,
			},
			{
				["type"] = "button",
				["display"] = "Cancel",
				["width"] = 100,
				["onclick"] = function ()
					GUI:CloseCurrentPopup()
				end,
			},
		}
		ffxiv_dialog_manager.IssueNotice("New Profile", "Please pick a name for the new profile.", "none", vars)
	end
	
	GUI_DrawTabs(self.GUI.main_tabs)
	local tabs = self.GUI.main_tabs
	
	if (tabs.tabs[1].isselected) then
		GUI:PushItemWidth(120)					
		
		GUI:Checkbox(GetString("botEnabled"),FFXIV_Common_BotRunning)
		GUI_Capture(GUI:Checkbox("Craft Debug",gCraftDebug),"gCraftDebug")
		local debugLevels = { 1, 2, 3}
		GUI_Combo("Debug Level", "gCraftDebugLevelIndex", "gCraftDebugLevel", debugLevels)
		
		GUI:Separator()
		GUI:Text("For Single Crafts Only")
		GUI_Capture(GUI:InputInt(GetString("craftAmount"),gCraftMaxItems,0,0),"gCraftMaxItems")
		GUI_Capture(GUI:InputInt(GetString("minimumCP"),gCraftMinCP,0,0),"gCraftMinCP")
		GUI_Capture(GUI:Checkbox(GetString("Use HQ Mats"),gCraftUseHQ),"gCraftUseHQ")
		GUI:Separator()
		
		GUI:PopItemWidth()
	end
	
	if (tabs.tabs[2].isselected) then
		if (GUI:Button("Add Collectable",150,20)) then
			local newCollectable = { name = "", value = 0 }
			table.insert(gCraftCollectablePresets,newCollectable)
			GUI_Set("gCraftCollectablePresets",gCraftCollectablePresets)
		end
		
		if (table.valid(gCraftCollectablePresets)) then
			for i,collectable in pairsByKeys(gCraftCollectablePresets) do
				GUI:AlignFirstTextHeightToWidgets()
				GUI:PushItemWidth(200)
				local newName = GUI:InputText("##craft-collectablepair-name"..tostring(i),collectable.name)
				if (newName ~= collectable.name) then
					gCraftCollectablePresets[i].name = newName
					GUI_Set("gCraftCollectablePresets",gCraftCollectablePresets)
				end
				GUI:PopItemWidth()
				GUI:PushItemWidth(40)
				GUI:SameLine()
				local newValue = GUI:InputInt("##craft-collectablepair-value"..tostring(i),collectable.value,0,0)
				if (newValue ~= collectable.value) then
					gCraftCollectablePresets[i].value = newValue
					GUI_Set("gCraftCollectablePresets",gCraftCollectablePresets)
				end
				GUI:PopItemWidth()
				GUI:SameLine()
				
				GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
				--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
				GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
				if (GUI:ImageButton("##craft-collectablepair-delete"..tostring(i),ml_global_information.path.."\\GUI\\UI_Textures\\bt_alwaysfail_fail.png", 14, 14)) then
					gCraftCollectablePresets[i] = nil
					GUI_Set("gCraftCollectablePresets",gCraftCollectablePresets)
				end
				GUI:PopStyleColor(2)
			end
		end
	end
	
	if (tabs.tabs[3].isselected) then
		GUI:PushItemWidth(40)
		for i = 8,15 do
			GUI:AlignFirstTextHeightToWidgets()
			GUI:Text(gCrafts[i-7])
			GUI:SameLine()
			GUI_Capture(GUI:InputInt("##craft-gearset"..tostring(i),_G["gCraftGearset"..tostring(i)],0,0),"gCraftGearset"..tostring(i))
			if (i ~= 11 and i ~= 15) then
				GUI:SameLine()
			end
		end
		GUI:PopItemWidth()
	end
end

function ffxiv_craft.IsCrafting()
	return (IsControlOpen("Synthesis") or IsControlOpen("SynthesisSimple"))
end

function ffxiv_craft.ToggleCraftingLog()
	if (IsControlOpen("RecipeNote")) then
		if (UseControlAction("RecipeNote","Close")) then
			return true
		end
	else
		local logOpen = ActionList:Get(10,9)
		if (logOpen and logOpen.usable) then
			if (logOpen:Cast(Player.id)) then
				ml_global_information.Await(1000, 1500, function () return IsControlOpen("RecipeNote") end)
			end
		end
	end
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
	else
		persistence.store(ffxiv_craft.profilePath..gCraftProfile..".lua",info)
	end
end

function ffxiv_craft.CreateNewProfile()
	if (ValidString(gCraftNewProfileName)) then
		d("Creating new profile ["..tostring(gCraftNewProfileName).."].")
		ffxiv_craft.SaveProfile(gCraftNewProfileName)
		ffxiv_craft.profiles, ffxiv_craft.profilesDisplay = GetPublicProfiles(ffxiv_craft.profilePath,".*lua")
	end
end

function ffxiv_craft.AddToProfile()
	local recipeid = tonumber(gCraftOrderAddID) or 0
	
	if (recipeid ~= 0) then
		local orders = ffxiv_craft.orders
		if (orders[recipeid] == nil) then
			local recipeDetails = AceLib.API.Items.GetRecipeDetails(recipeid)
			local thisOrder = { 	
				id = recipeid, 
				item = recipeDetails.id, 
				name = recipeDetails.name, 
				level = recipeDetails.attemptlevel,
				class = recipeDetails.class, 
				page = recipeDetails.page,
				amount = gCraftOrderAddAmount, 
				usequick = gCraftOrderAddQuick, 
				usehq = gCraftOrderAddHQ, 
				skillprofile = gCraftOrderAddSkillProfile,
				requirehq = gCraftOrderAddRequireHQ, 
				counthq = gCraftOrderAddCountHQ,
				skip = false,
				completed = false,
			}
			
			for i = 1,6 do
				thisOrder["hq"..tostring(i).."max"] = IsNull(_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"],false)
				thisOrder["hq"..tostring(i)] = IsNull(_G["gCraftOrderAddHQIngredient"..tostring(i)],0)
			end
			
			orders[recipeid] = thisOrder
			ffxiv_craft.SaveProfile()
		end
	end
end

function ffxiv_craft.UsingProfile()
	return table.valid(ffxiv_craft.orders)
end

function ffxiv_craft.DeleteOrder(key)
	local key = (tonumber(key) or tonumber(gCraftOrderEditID) or 0)
	
	local orders = ffxiv_craft.orders
	if (orders and orders[key]) then
		if (TableSize(orders) > 1) then
			orders[key] = nil
		else
			ffxiv_craft.orders = {}
		end
		ffxiv_craft.SaveProfile()
	end
end

function ffxiv_craft.UpdateOrderElement()
	local key = tonumber(gCraftOrderEditID) or 0
	local orders = ffxiv_craft.orders
	if (table.valid(orders)) then
		local thisOrder = orders[key]
		if (thisOrder) then
			thisOrder["amount"] = gCraftOrderEditAmount
			thisOrder["requirehq"] = gCraftOrderEditRequireHQ
			thisOrder["counthq"] = gCraftOrderEditCountHQ
			thisOrder["usequick"] = gCraftOrderEditQuick
			thisOrder["usehq"] = gCraftOrderEditHQ
			thisOrder["skillprofile"] = IsNull(gCraftOrderEditSkillProfile,GetString("None"))
			thisOrder["requiredfood"] = gCraftOrderEditFood
			
			for i = 1,6 do
				thisOrder["hq"..tostring(i).."max"] = IsNull(_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"],false)
				thisOrder["hq"..tostring(i)] = IsNull(_G["gCraftOrderEditHQIngredient"..tostring(i)],0)
			end
			
			ffxiv_craft.SaveProfile()
		end
	end
end

function ffxiv_craft.InspectRecipe(key)
	local key = tonumber(key) or 0
	local recipeDetails = AceLib.API.Items.GetRecipeDetails(key)
	gCraftInspectProgress = recipeDetails.progress or ""
	gCraftInspectDurability = recipeDetails.durability or ""
	gCraftInspectCraftsmanship = recipeDetails.craftsmanship or ""
	gCraftInspectControl = recipeDetails.control or ""
	gCraftInspectREquip = IIF(recipeDetails.requiredequip ~= 0,IsNull(recipeDetails.requipname,"").."["..IsNull(recipeDetails.requiredequip,"").."]","")
	gCraftInspectCrystal1 = IIF(recipeDetails.crystal1 ~= 0,IsNull(recipeDetails.c1name,"").."["..IsNull(recipeDetails.crystal1,"").."]","")
	gCraftInspectCAmount1 = IIF(recipeDetails.crystal1 ~= 0,tostring(IsNull(recipeDetails.camount1,0)).."("..IsNull(ItemCount(recipeDetails.crystal1,{2001},true),0)..")","")
	gCraftInspectCrystal2 = IIF(recipeDetails.crystal2 ~= 0,IsNull(recipeDetails.c2name,"").."["..IsNull(recipeDetails.crystal2,"").."]","")
	gCraftInspectCAmount2 = IIF(recipeDetails.crystal2 ~= 0,tostring(IsNull(recipeDetails.camount2,0)).."("..IsNull(ItemCount(recipeDetails.crystal2,{2001},true),0)..")","")
	gCraftInspectIngredient1 = IIF(recipeDetails.ingredient1 ~= 0,IsNull(recipeDetails.ing1name,"").."["..IsNull(recipeDetails.ingredient1,"").."]","")
	gCraftInspectIAmount1 = IIF(recipeDetails.iamount1 > 0,tostring(IsNull(recipeDetails.iamount1,0)).."("..IsNull(ItemCount(recipeDetails.ingredient1,{0,1,2,3},true),0)..")","")
	gCraftInspectIngredient2 = IIF(recipeDetails.ingredient2 ~= 0,IsNull(recipeDetails.ing2name,"").."["..IsNull(recipeDetails.ingredient2,"").."]","")
	gCraftInspectIAmount2 = IIF(recipeDetails.iamount2 > 0,tostring(IsNull(recipeDetails.iamount2,0)).."("..IsNull(ItemCount(recipeDetails.ingredient2,{0,1,2,3},true),0)..")","")
	gCraftInspectIngredient3 = IIF(recipeDetails.ingredient3 ~= 0,IsNull(recipeDetails.ing3name,"").."["..IsNull(recipeDetails.ingredient3,"").."]","")
	gCraftInspectIAmount3 = IIF(recipeDetails.iamount3 > 0,tostring(IsNull(recipeDetails.iamount3,0)).."("..IsNull(ItemCount(recipeDetails.ingredient3,{0,1,2,3},true),0)..")","")
	gCraftInspectIngredient4 = IIF(recipeDetails.ingredient4 ~= 0,IsNull(recipeDetails.ing4name,"").."["..IsNull(recipeDetails.ingredient4,"").."]","")
	gCraftInspectIAmount4 = IIF(recipeDetails.iamount4 > 0,tostring(IsNull(recipeDetails.iamount4,0)).."("..IsNull(ItemCount(recipeDetails.ingredient4,{0,1,2,3},true),0)..")","")
	gCraftInspectIngredient5 = IIF(recipeDetails.ingredient5 ~= 0,IsNull(recipeDetails.ing5name,"").."["..IsNull(recipeDetails.ingredient5,"").."]","")
	gCraftInspectIAmount5 = IIF(recipeDetails.iamount5 > 0,tostring(IsNull(recipeDetails.iamount5,0)).."("..IsNull(ItemCount(recipeDetails.ingredient5,{0,1,2,3},true),0)..")","")
	gCraftInspectIngredient6 = IIF(recipeDetails.ingredient6 ~= 0,IsNull(recipeDetails.ing6name,"").."["..IsNull(recipeDetails.ingredient6,"").."]","")
	gCraftInspectIAmount6 = IIF(recipeDetails.iamount6 > 0,tostring(IsNull(recipeDetails.iamount6,0)).."("..IsNull(ItemCount(recipeDetails.ingredient6,{0,1,2,3},true),0)..")","")

	local canCraft,maxAmount = AceLib.API.Items.CanCraft(key)
	gCraftInspectCanCraft = tostring(canCraft)
	gCraftInspectCraftable = maxAmount
	
	GUI:Columns(2, "##craft-recipe-inspection", true)
	GUI:SetColumnOffset(1, 200); GUI:SetColumnOffset(2, 400)
	GUI:Text("Can Craft"); GUI:NextColumn(); GUI:Text(gCraftInspectCanCraft); GUI:NextColumn();
	GUI:Text("Amount Craftable"); GUI:NextColumn(); GUI:Text(gCraftInspectCraftable); GUI:NextColumn();
	
	GUI:Text("Progress"); GUI:NextColumn(); GUI:Text(gCraftInspectProgress); GUI:NextColumn();
	GUI:Text("Durability"); GUI:NextColumn(); GUI:Text(gCraftInspectDurability); GUI:NextColumn();
	GUI:Text("Craftsmanship"); GUI:NextColumn(); GUI:Text(gCraftInspectCraftsmanship); GUI:NextColumn();
	GUI:Text("Control"); GUI:NextColumn(); GUI:Text(gCraftInspectControl); GUI:NextColumn();
	GUI:Text("Equipment"); GUI:NextColumn(); GUI:Text(gCraftInspectREquip); GUI:NextColumn();
	if (gCraftInspectCrystal1 ~= "") then
		GUI:Text(gCraftInspectCrystal1); GUI:NextColumn(); GUI:Text(gCraftInspectCAmount1); GUI:NextColumn();
	end
	if (gCraftInspectCrystal2 ~= "") then
		GUI:Text(gCraftInspectCrystal2); GUI:NextColumn(); GUI:Text(gCraftInspectCAmount2); GUI:NextColumn();
	end
	if (gCraftInspectIngredient1 ~= "") then
		GUI:Text(gCraftInspectIngredient1); GUI:NextColumn(); GUI:Text(gCraftInspectIAmount1); GUI:NextColumn();
	end
	if (gCraftInspectIngredient2 ~= "") then
		GUI:Text(gCraftInspectIngredient2); GUI:NextColumn(); GUI:Text(gCraftInspectIAmount2); GUI:NextColumn();
	end
	if (gCraftInspectIngredient3 ~= "") then
		GUI:Text(gCraftInspectIngredient3); GUI:NextColumn(); GUI:Text(gCraftInspectIAmount3); GUI:NextColumn();
	end
	if (gCraftInspectIngredient4 ~= "") then
		GUI:Text(gCraftInspectIngredient4); GUI:NextColumn(); GUI:Text(gCraftInspectIAmount4); GUI:NextColumn();
	end
	if (gCraftInspectIngredient5 ~= "") then
		GUI:Text(gCraftInspectIngredient5); GUI:NextColumn(); GUI:Text(gCraftInspectIAmount5); GUI:NextColumn();
	end
	if (gCraftInspectIngredient6 ~= "") then
		GUI:Text(gCraftInspectIngredient6); GUI:NextColumn(); GUI:Text(gCraftInspectIAmount6); GUI:NextColumn();
	end	
	GUI:Columns(1)
end

function ffxiv_craft.GetDictionary(maxattemptlevel, craftid)
	local craftid = IsNull(craftid,0)
	local maxattemptlevel = IsNull(maxattemptlevel,10)
	if (craftid == 0) then
		local crafts = ffxiv_craft.crafts
		craftid = crafts[gCraftOrderSelect]
	end
	
	if (craftid) then
		if (ffxiv_craft.dictionaries[craftid] and ffxiv_craft.dictionariesDisplay[craftid]) then
			if (ffxiv_craft.dictionaries[craftid][maxattemptlevel] and ffxiv_craft.dictionariesDisplay[craftid][maxattemptlevel]) then
				return ffxiv_craft.dictionaries[craftid][maxattemptlevel], ffxiv_craft.dictionariesDisplay[craftid][maxattemptlevel]
			end
		end
			
		local recipes,dictionary = AceLib.API.Items.BuildRecipeString(craftid,0,(maxattemptlevel-9),maxattemptlevel)
		if (dictionary) then
			if (not ffxiv_craft.dictionaries[craftid] or not not ffxiv_craft.dictionariesDisplay[craftid]) then
				ffxiv_craft.dictionaries[craftid] = {}
				ffxiv_craft.dictionariesDisplay[craftid] = {}
			end
			ffxiv_craft.dictionaries[craftid][maxattemptlevel] = {}
			ffxiv_craft.dictionariesDisplay[craftid][maxattemptlevel]  = {}
			
			local newDictionary = { [1] = {recipeid = 0, itemid = 0, name = GetString("None")} }
			local newDisplayDictionary = { [1] = GetString("None") }
			
			local sortfunc = function(dictionary,a,b) 
				return (dictionary[a].name < dictionary[b].name)
			end
			for _,data in spairs(dictionary, sortfunc) do
				table.insert(newDictionary, {recipeid = data.recipeid, itemid = data.itemid, name = data.name})
				table.insert(newDisplayDictionary, data.name.." ["..tostring(data.recipeid).."]")
			end
			
			ffxiv_craft.dictionaries[craftid][maxattemptlevel] = newDictionary
			ffxiv_craft.dictionariesDisplay[craftid][maxattemptlevel] = newDisplayDictionary
		
			return ffxiv_craft.dictionaries[craftid][maxattemptlevel], ffxiv_craft.dictionariesDisplay[craftid][maxattemptlevel]
		end
	end
	
	return nil, nil
end

--[[
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
				string.contains(tostring(k),"gCraftCollectible") or
				string.contains(tostring(k),"gCraftGearset"))				
		then
            SafeSetVar(tostring(k),v)
		elseif (k == "gCraftOrderSelect") then
			SafeSetVar(tostring(k),v)
			ffxiv_craft.SwitchCraftWindow()
		elseif (string.contains(tostring(k),"gCraftOrderEdit")) then
			ffxiv_craft.EditOrderElement(k,v)
		elseif ( k == "gProfile" and gBotMode == GetString("craftMode")) then
			ffxiv_craft.LoadProfile(v)
			Settings.FFXIVMINION["gLastCraftProfile"] = v
        end
    end
    GUI_RefreshWindow(GetString("craftMode"))
end
--]]

function ffxiv_craft.Draw( event, ticks ) 
	if (ffxiv_task_craft.GUI.orders.open) then
		GUI:SetNextWindowSize(500,200,GUI.SetCond_FirstUseEver) --set the next window size, only on first ever	
		GUI:SetNextWindowCollapsed(false,GUI.SetCond_Always)
		
		local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
		GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
		
		ffxiv_task_craft.GUI.orders.visible, ffxiv_task_craft.GUI.orders.open = GUI:Begin(ffxiv_task_craft.GUI.orders.name, ffxiv_task_craft.GUI.orders.open)
		if ( ffxiv_task_craft.GUI.orders.visible ) then 
		
			GUI_DrawTabs(ffxiv_task_craft.GUI.orders.main_tabs)
			local tabs = ffxiv_task_craft.GUI.orders.main_tabs
			
			if (tabs.tabs[1].isselected) then
				local width, height = GUI:GetWindowSize()		
				local cwidth, cheight = GUI:GetContentRegionAvail()
				
				if (GUI:CollapsingHeader("Overrides","craft-overrides",true,true)) then
					GUI:Separator()				
					GUI:BeginChild("##craft-overrides-frame",0,GUI_GetFrameHeight(2), true)
					GUI:PushItemWidth(250)
					GUI_Combo(GetString("food"), "gCraftFoodIndex", "gCraftFood", gFoods)
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip("This option will override any profile-specific food choices.")
					end
					GUI:PopItemWidth()
					GUI:SameLine(0,5)
					GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
					GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
					if (GUI:ImageButton("##craft-food-refresh",ml_global_information.path.."\\GUI\\UI_Textures\\change.png", 16, 16)) then
						ffxivminion.FillFoodOptions()
					end
					GUI:PopStyleColor(2)
					GUI:EndChild()
				end
				
				GUI:Spacing();
				
				local orders = ffxiv_craft.orders
				if (table.valid(orders)) then
					
					GUI:Separator();
					GUI:Columns(6, "#craft-manage-orders", true)
					GUI:SetColumnOffset(1, 125); GUI:SetColumnOffset(2, 225); GUI:SetColumnOffset(3, 300); GUI:SetColumnOffset(4, 400); GUI:SetColumnOffset(5, 500); GUI:SetColumnOffset(6, 600);				
					GUI:Text("Item"); GUI:NextColumn();
					GUI:Text("Recipe"); GUI:NextColumn();
					GUI:Text("Amount"); GUI:NextColumn();
					GUI:Text("Skip"); GUI:NextColumn();
					GUI:Text("Edit"); GUI:NextColumn();
					GUI:Text("Remove"); GUI:NextColumn();
					GUI:Separator();
				
					local sortfunc = function(orders,a,b) 
						return (orders[a].page < orders[b].page) or (orders[a].page == orders[b].page and orders[a].level < orders[b].level) 
					end
					for id,order in spairs(orders, sortfunc) do
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(order.name); 
						if (GUI:IsItemHovered()) then
							GUI:BeginTooltip()
							ffxiv_craft.InspectRecipe(id)
							GUI:EndTooltip()
						end						
						GUI:NextColumn()
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(id); GUI:NextColumn()
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(order.amount); GUI:NextColumn()
						
						if (order.skip == nil) then
							orders[id].skip = false
							ffxiv_craft.SaveProfile()
						end
						local newVal, changed = GUI:Checkbox("##skip-"..tostring(id),order.skip)
						if (changed) then
							orders[id].skip = newVal
						end
						GUI:NextColumn()
						
						GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
						--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
						GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
						
						if (GUI:ImageButton("##craft-manage-edit"..tostring(id),ml_global_information.path.."\\GUI\\UI_Textures\\w_edit.png", 16, 16)) then
							gCraftOrderEditID = id
							gCraftOrderEditAmount = order["amount"]
							gCraftOrderEditRequireHQ = order["requirehq"]
							gCraftOrderEditCountHQ = order["counthq"]
							gCraftOrderEditQuick = order["usequick"]
							gCraftOrderEditHQ = order["usehq"]
							gCraftOrderEditSkillProfile = IsNull(order["skillprofile"],GetString("None"))
							gCraftOrderEditFood = IsNull(order["requiredfood"],GetString("None"))
							
							for i = 1,6 do
								if (not order["hq"..tostring(i)]) then
									_G["gCraftOrderEditHQIngredient"..tostring(i)] = 0
									_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = false
									ffxiv_craft.UpdateOrderElement()
								else
									_G["gCraftOrderEditHQIngredient"..tostring(i)] = order["hq"..tostring(i)]
									_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = order["hq"..tostring(i).."max"]
								end
							end
							
							GUI_SwitchTab(ffxiv_task_craft.GUI.orders.main_tabs,3)
						end
						GUI:NextColumn()
						if (GUI:ImageButton("##craft-manage-delete"..tostring(id),ml_global_information.path.."\\GUI\\UI_Textures\\bt_alwaysfail_fail.png", 16, 16)) then
							ffxiv_craft.DeleteOrder(id)
						end
						GUI:NextColumn()
						GUI:PopStyleColor(2)
					end
					
					GUI:Columns(1)
				end
			end
			
			if (tabs.tabs[2].isselected) then	
				GUI:PushItemWidth(50)
				GUI_Combo("Class", "gCraftOrderSelectIndex", "gCraftOrderSelect", gCrafts)
				GUI:PopItemWidth()
				
				for k = 10,60,10 do
					local dictionary, dictionaryDisplay = ffxiv_craft.GetDictionary(k)
					if (dictionary and dictionaryDisplay) then
						GUI:PushItemWidth(300)
						local selectionChanged = GUI_Combo(tostring(k-9).."-"..tostring(k), "gCraftDictionarySelectIndex"..tostring(k), "gCraftDictionarySelect"..tostring(k), dictionaryDisplay)
						if (selectionChanged) then
							local thisRecipe = dictionary[_G["gCraftDictionarySelectIndex"..tostring(k)]]
							if (thisRecipe) then
								gCraftOrderAddID = thisRecipe.recipeid
								gCraftOrderAddAmount = 1
								gCraftOrderAddRequireHQ = false
								gCraftOrderAddCountHQ = false
								gCraftOrderAddQuick = false
								gCraftOrderAddHQ = false
								gCraftOrderAddSkillProfileIndex = 1
								gCraftOrderAddSkillProfile = GetString("None")
								gCraftOrderAddFoodIndex = 1
								gCraftOrderAddFood = GetString("None")
							end
							for j = 10,60,10 do
								if (j ~= k) then
									_G["gCraftDictionarySelectIndex"..tostring(j)] = 1
									_G["gCraftDictionarySelect"..tostring(j)] = GetString("None")		
								end
							end
						end
						GUI:PopItemWidth()
					else
						GUI:Text("Could not find display dictionary for ["..gCraftOrderSelect.."] with attempt level ["..tostring(k).."]")
					end					
				end
				
				if (gCraftOrderAddID ~= 0) then
					
					GUI:Separator()
				
					GUI:PushItemWidth(50)
					GUI_Capture(GUI:InputInt("Amount to Craft",gCraftOrderAddAmount,0,0),"gCraftOrderAddAmount")
					GUI:PopItemWidth()
					GUI_Capture(GUI:Checkbox("Require HQ",gCraftOrderAddRequireHQ),"gCraftOrderAddRequireHQ")
					GUI_Capture(GUI:Checkbox("Count HQ",gCraftOrderAddCountHQ),"gCraftOrderAddCountHQ")
					GUI_Capture(GUI:Checkbox("Use QuickSynth",gCraftOrderAddQuick),"gCraftOrderAddQuick")
					if (not gCraftOrderAddQuick) then
						GUI:PushItemWidth(200)
						GUI_Combo(GetString("skillProfile"), "gCraftOrderAddSkillProfileIndex", "gCraftOrderAddSkillProfile", SkillMgr.profiles)
						GUI:PopItemWidth()
					end
					GUI_Capture(GUI:Checkbox("Use HQ Items",gCraftOrderAddHQ),"gCraftOrderAddHQ")
					if (gCraftOrderAddHQ) then						
						local recipeDetails = AceLib.API.Items.GetRecipeDetails(gCraftOrderAddID)
						if (recipeDetails) then
							
							GUI:Columns(4, "#craft-add-hq", true)
							GUI:SetColumnOffset(1, 250); GUI:SetColumnOffset(2, 350); GUI:SetColumnOffset(3, 475); GUI:SetColumnOffset(4, 600);
							GUI:AlignFirstTextHeightToWidgets()
							
							GUI:Text("Ingredient"); GUI:NextColumn();
							GUI:Text("Required"); GUI:NextColumn();
							GUI:Text("Choose HQ Amount"); GUI:NextColumn();
							GUI:Text("Use All HQ"); GUI:NextColumn();
							
							GUI:Separator();
							
							for i = 1,6 do
								local ing = recipeDetails["ingredient"..tostring(i)]
								if (ing and ing ~= 0) then
									GUI:AlignFirstTextHeightToWidgets()
									GUI:Text(recipeDetails["ing"..tostring(i).."name"]); GUI:Dummy(); GUI:NextColumn();
									GUI:AlignFirstTextHeightToWidgets()
									GUI:Text(tostring(recipeDetails["iamount"..tostring(i)])); GUI:Dummy(); GUI:NextColumn();
									
									GUI:PushItemWidth(50)
									local newVal, changed = GUI:InputInt("##HQ Amount"..tostring(i),_G["gCraftOrderAddHQIngredient"..tostring(i)],0,0)
									if (changed and not GUI:IsItemActive()) then
										if (newVal > recipeDetails["iamount"..tostring(i)]) then
											newVal = recipeDetails["iamount"..tostring(i)]
										elseif (newVal < 0) then
											newVal = 0
										end
										if (newVal == recipeDetails["iamount"..tostring(i)]) then
											_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"] = true
										else
											_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"] = false
										end
										_G["gCraftOrderAddHQIngredient"..tostring(i)] = newVal
										ffxiv_craft.UpdateOrderElement()
									end
									GUI:PopItemWidth()
									GUI:NextColumn();
									
									local newVal, changed = GUI:Checkbox("##Max-"..tostring(i),_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"])
									if (changed) then
										if (newVal == false) then
											if (_G["gCraftOrderAddHQIngredient"..tostring(i)] == recipeDetails["iamount"..tostring(i)]) then
												_G["gCraftOrderAddHQIngredient"..tostring(i)] = 0
											end
										elseif (newVal == true) then
											_G["gCraftOrderAddHQIngredient"..tostring(i)] = recipeDetails["iamount"..tostring(i)]
										end
										_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"] = newVal
										ffxiv_craft.UpdateOrderElement()
									end
									GUI:NextColumn();
								end
							end
							
							GUI:Columns(1)
						else
							GUI:Text("Could not find recipe details.")
						end					
					end
					
					GUI:Spacing()
					GUI:Separator()
					GUI:Spacing()
					
					if (GUI:Button("Add to Profile",200,20)) then
						ffxiv_craft.AddToProfile()
					end
				end
			end
			
			if (tabs.tabs[3].isselected) then
				if (ffxiv_craft.orders[gCraftOrderEditID] ~= nil) then
					local orders = ffxiv_craft.orders[gCraftOrderEditID]
					GUI:PushItemWidth(50)
					GUI_Capture(GUI:InputInt("Amount to Craft",gCraftOrderEditAmount,0,0),"gCraftOrderEditAmount", function () ffxiv_craft.UpdateOrderElement()  end)
					GUI:PopItemWidth()
					GUI_Capture(GUI:Checkbox("Require HQ",gCraftOrderEditRequireHQ),"gCraftOrderEditRequireHQ", function () ffxiv_craft.UpdateOrderElement() end)
					GUI_Capture(GUI:Checkbox("Count HQ",gCraftOrderEditCountHQ),"gCraftOrderEditCountHQ", function () ffxiv_craft.UpdateOrderElement() end)
					GUI_Capture(GUI:Checkbox("Use QuickSynth",gCraftOrderEditQuick),"gCraftOrderEditQuick", function () ffxiv_craft.UpdateOrderElement() end)
					if (not gCraftOrderEditQuick) then
						GUI:PushItemWidth(200)
						local skillsChanged = GUI_Combo(GetString("skillProfile"), "gCraftOrderEditSkillProfileIndex", "gCraftOrderEditSkillProfile", SkillMgr.profiles)
						if (skillsChanged) then
							ffxiv_craft.UpdateOrderElement()
						end
						GUI:PopItemWidth()
					end
					
					GUI_Capture(GUI:Checkbox("Use HQ Items",gCraftOrderEditHQ),"gCraftOrderEditHQ", function () ffxiv_craft.UpdateOrderElement() end)
					if (gCraftOrderEditHQ) then
						GUI:Separator()
						local recipeDetails = AceLib.API.Items.GetRecipeDetails(gCraftOrderEditID)
						if (recipeDetails) then
							
							GUI:Columns(4, "#craft-edit-hq", true)
							GUI:SetColumnOffset(1, 250); GUI:SetColumnOffset(2, 350); GUI:SetColumnOffset(3, 475); GUI:SetColumnOffset(4, 600);
							GUI:AlignFirstTextHeightToWidgets()
							
							GUI:Text("Ingredient"); GUI:NextColumn();
							GUI:Text("Required"); GUI:NextColumn();
							GUI:Text("Choose HQ Amount"); GUI:NextColumn();
							GUI:Text("Use All HQ"); GUI:NextColumn();
							GUI:Separator();
							
							for i = 1,6 do
								local ing = recipeDetails["ingredient"..tostring(i)]
								if (ing and ing ~= 0) then
									GUI:AlignFirstTextHeightToWidgets()
									GUI:Text(recipeDetails["ing"..tostring(i).."name"]); GUI:Dummy();GUI:NextColumn();
									GUI:AlignFirstTextHeightToWidgets()
									GUI:Text(recipeDetails["iamount"..tostring(i)]); GUI:Dummy();GUI:NextColumn();
									GUI:PushItemWidth(50)
									GUI:AlignFirstTextHeightToWidgets()
									local newVal, changed = GUI:InputInt("##HQ Amount-"..tostring(i),_G["gCraftOrderEditHQIngredient"..tostring(i)],0,0)
									if (changed and not GUI:IsItemActive()) then
										if (newVal > recipeDetails["iamount"..tostring(i)]) then
											newVal = recipeDetails["iamount"..tostring(i)]
										elseif (newVal < 0) then
											newVal = 0
										end
										if (newVal == recipeDetails["iamount"..tostring(i)]) then
											_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = true
										else
											_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = false
										end
										_G["gCraftOrderEditHQIngredient"..tostring(i)] = newVal
										ffxiv_craft.UpdateOrderElement()
									end
									GUI:PopItemWidth()
									GUI:NextColumn();
									GUI:AlignFirstTextHeightToWidgets()
									local newVal, changed = GUI:Checkbox("##Max-"..tostring(i),_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"])
									if (changed) then
										if (newVal == false) then
											if (_G["gCraftOrderEditHQIngredient"..tostring(i)] == recipeDetails["iamount"..tostring(i)]) then
												_G["gCraftOrderEditHQIngredient"..tostring(i)] = 0
											end
										elseif (newVal == true) then
											_G["gCraftOrderEditHQIngredient"..tostring(i)] = recipeDetails["iamount"..tostring(i)]
										end
										_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = newVal
										ffxiv_craft.UpdateOrderElement()
									end
									GUI:NextColumn();
								end
							end
							
							GUI:Columns(1)
						else
							GUI:Text("Could not find recipe details.")
						end					
					end
				end
			end
		end
		GUI:End()
	end
end

RegisterEventHandler("Gameloop.Draw", ffxiv_craft.Draw)
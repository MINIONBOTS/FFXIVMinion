ffxiv_craft = {}

ffxiv_craft.resetRecipe = false
ffxiv_craft.tracking = {
	measurementDelay = 0,
	quickTimer = 0,
	lastSetRecipe = 0,
}
ffxiv_craft.crafts = {
	["CRP"] = 8,	["BSM"] = 9,	["ARM"] = 10,	["GSM"] = 11,
	["LTW"] = 12,	["WVR"] = 13,	["ALC"] = 14,	["CUL"] = 15,
}
ffxiv_craft.itemCounts = {}
ffxiv_craft.profilePath = GetStartupPath()..[[\LuaMods\ffxivminion\CraftProfiles\]]
ffxiv_craft.profiles = {}
ffxiv_craft.profilesDisplay = {}
ffxiv_craft.profileData = {}
ffxiv_craft.orders = {}
ffxiv_craft.ordersVisible = false
ffxiv_craft.orderSelectorVisible = false
ffxiv_craft.dictionaries = {}
ffxiv_craft.dictionariesDisplay = {}
ffxiv_craft.lastCraft = {}
ffxiv_craft.collectors = {
	[8] = 4560,
	[9] = 4561,
	[10] = 4562,
	[11] = 4563,
	[12] = 4565,
	[13] = 4564,
	[14] = 4566,
	[15] = 4567,
}
ffxiv_craft.collectibles = {
	-- Weekly (Custom Delivery)
	-- Zhloe Alipoh
	{ name = FFXIVLib.API.Items.GetNameByID(17549), minimum = 55 },	--	Near Eastern Antique
	{ name = FFXIVLib.API.Items.GetNameByID(17550), minimum = 57 },	--	Coerthan Souvenir	
	{ name = FFXIVLib.API.Items.GetNameByID(17551), minimum = 59 },	--	Maelstrom Materiel	
	{ name = FFXIVLib.API.Items.GetNameByID(17552), minimum = 63 },	--	Heartfelt Gift	
	{ name = FFXIVLib.API.Items.GetNameByID(17553), minimum = 68 },	--	Orphanage Donation	
	-- M 'naago
	{ name = FFXIVLib.API.Items.GetNameByID(20775), minimum = 157 },	--	Gyr Abanian Souvenir
	{ name = FFXIVLib.API.Items.GetNameByID(20776), minimum = 167 },	--	Far Eastern Antique	
	{ name = FFXIVLib.API.Items.GetNameByID(20777), minimum = 130 },	--	Gold Saucer Consolation Prize	
	{ name = FFXIVLib.API.Items.GetNameByID(20778), minimum = 130 },	--	M Tribe Sundries	
	{ name = FFXIVLib.API.Items.GetNameByID(20779), minimum = 104 },	--	Resistance Materiel
	-- Kurenai
	{ name = FFXIVLib.API.Items.GetNameByID(23143), minimum = 195 },	--	Gyr Abanian Remedies	
	{ name = FFXIVLib.API.Items.GetNameByID(23144), minimum = 195 },	--	Anti-shark Harpoon
	{ name = FFXIVLib.API.Items.GetNameByID(23145), minimum = 130 },	--	Coerthan Cold-weather Gear
	{ name = FFXIVLib.API.Items.GetNameByID(23146), minimum = 130 },	--	Sui-no-Sato Special
	{ name = FFXIVLib.API.Items.GetNameByID(23147), minimum = 110 },	--	Cloud Pearl
	-- Adkiragh
	{ name = FFXIVLib.API.Items.GetNameByID(24562), minimum = 233 },	--	Ishgardian Culinary Essentials
	{ name = FFXIVLib.API.Items.GetNameByID(24563), minimum = 233 },	--	Fermented Juice
	{ name = FFXIVLib.API.Items.GetNameByID(24564), minimum = 161 },	--	Signature Buuz Cookware
	{ name = FFXIVLib.API.Items.GetNameByID(24565), minimum = 161 },	--	Hard Place Decorative Furnishings 
	{ name = FFXIVLib.API.Items.GetNameByID(24566), minimum = 125 },	--	Arkhi Brewing Set
}

ffxiv_task_craft = inheritsFrom(ml_task)
ffxiv_task_craft.name = "LT_CRAFT"
ffxiv_task_craft.addon_process_elements = {}
ffxiv_task_craft.addon_overwatch_elements = {}
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
function ffxiv_craft.CanUseTea()
	if (IsCrafter(Player.job) and MissingBuff(Player.id,49,0,30)) then
		if gCraftTeaTypeIndex == 2 or gCraftTeaTypeIndex == 5 then
			-- "Cunning Craftsman's Tisane",
			local teahq, action = GetItem(1044169)
			if (teahq and action and not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(44169)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
			-- "Cunning Craftsman's Draught",
			local teahq, action = GetItem(1036116)
			if (teahq and action and not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(36116)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
			-- "Cunning Craftsman's Syrup",
			local teahq, action = GetItem(1027959)
			if (teahq and action and not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(27959)
			if (tea and action and not action.isoncd) then
				return true, tea
			end		
			-- "Cunning Craftsman's Tea",
			local teahq, action = GetItem(1019884)
			if (teahq and action and not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(19884)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
		end
		if gCraftTeaTypeIndex == 3 or gCraftTeaTypeIndex == 5 then
			-- "Commanding Craftsman's Tisane",
			local teahq, action = GetItem(1044168)
			if (teahq and action and not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(44168)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
			-- "Commanding Craftsman's Draught",
			local teahq, action = GetItem(1036115)
			if (teahq and action and not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(36115)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
			-- "Commanding Craftsman's Syrup",
			local teahq, action = GetItem(1027958)
			if (teahq and action and not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(27958)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
			-- "Commanding Craftsman's Tea",
			local teahq, action = GetItem(1019883)
			if (teahq and action and not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(19883)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
		end
		if gCraftTeaTypeIndex == 4 or gCraftTeaTypeIndex == 5 then
			-- "Competent Craftsman's Tisane",
			local teahq, action = GetItem(1044167)
			if (teahq and action and  not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(44167)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
			-- "Competent Craftsman's Draught",
			local teahq, action = GetItem(1036114)
			if (teahq and action and not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(36114)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
			-- "Competent Craftsman's Syrup",
			local teahq, action = GetItem(1027957)
			if (teahq and action and  not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(27957)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
			-- "Competent Craftsman's Tea",
			local teahq, action = GetItem(1019882)
			if (teahq and action and  not action.isoncd) then
				return true, teahq
			end
			local tea, action = GetItem(19882)
			if (tea and action and not action.isoncd) then
				return true, tea
			end
		end
	end
	
	return false, nil
end

function ffxiv_craft.Canextractmateria()
	local bag = Inventory:Get(1000)
	if (table.valid(bag)) then
		local ilist = bag:GetList()
		if (table.valid(ilist)) then
			for slot, items in pairs(ilist) do 			
				if (items.spiritbond == 100) then
					--items:Convert()
					return true
				end
			end
		end
	end
return false
end

function ffxiv_craft.extractmateria()
	local bag = Inventory:Get(1000)
	if (table.valid(bag)) then
		local ilist = bag:GetList()
		if (table.valid(ilist)) then
			for slot, items in pairs(ilist) do 			
				if (items.spiritbond == 100) then
					items:Convert()
					return true
				end
			end
		end
	end
return false
end

c_waitlog = inheritsFrom( ml_cause )
e_waitlog = inheritsFrom( ml_effect )
function c_waitlog:evaluate()
	if (IsControlOpen("RecipeNote")) then
		local logData = GetControlData("RecipeNote")
		if (logData and IsNull(logData.class,-1) < 0) then
			ml_global_information.Await(1000)
			return true
		end
	end
		
	return false
end

function e_waitlog:execute()
end

c_closelog = inheritsFrom( ml_cause )
e_closelog = inheritsFrom( ml_effect )
function c_closelog:evaluate()
	if (ml_task_hub:CurrentTask().allowWindowOpen ) then
		return false
	end
	if (IsControlOpen("Synthesis") or IsControlOpen("SynthesisSimple") or IsControlOpen("SynthesisSimpleDialog") or IsControlOpen("SelectYesno") or IsControlOpen("SelectYesNoCountItem") or MIsLoading() or IsControlOpen("Talk") or IsControlOpen("Request")) then	
		--d("Cannot clear inventory, basic reasons.")
		return false
	end
	if (IsControlOpen("RecipeNote")) then
		if (IsInventoryFull()) then
			return true
		end
	end
		
	return false
end

function e_closelog:execute()
	if (IsControlOpen("RecipeNote")) then
		ffxiv_craft.ToggleCraftingLog()
		ml_task_hub:CurrentTask().allowWindowOpen = true
	end
end

c_craftlimit = inheritsFrom( ml_cause )
e_craftlimit = inheritsFrom( ml_effect )
function c_craftlimit:evaluate()
	if (not ffxiv_craft.IsCrafting()) then
		if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
			local recipe = ml_task_hub:CurrentTask().recipe
			local itemid = ml_task_hub:CurrentTask().itemid
			local requireHQ = ml_task_hub:CurrentTask().requireHQ
			local requireCollect = ml_task_hub:CurrentTask().requireCollect
			local countHQ = ml_task_hub:CurrentTask().countHQ
			local requiredItems = ml_task_hub:CurrentTask().requiredItems
			local startingCount = ml_task_hub:CurrentTask().startingCount 

			local getcounts = {}
			local orders = ffxiv_craft.orders
			if table.valid(orders) then
				for id,order in pairs(orders) do
					local itemid = order.item
					getcounts[itemid] = true
					getcounts[itemid + 1000000] = true
					getcounts[itemid + 500000] = true
				end
			end
			
			local getcountsorted = {}
			for itemid,_ in pairs(getcounts) do
				table.insert(getcountsorted,itemid)
			end
			
			ffxiv_craft.itemCounts = ItemCounts(getcountsorted)
			local itemcounts = ffxiv_craft.itemCounts
			
			local itemcountnorm = IsNull(itemcounts[itemid].count,0)
			local itemcountHQ = IsNull(itemcounts[itemid + 1000000].count,0)
			local itemcountCollectable = IsNull(itemcounts[itemid + 500000].count,0)
			if In(ffxivminion.gameRegion,1) then
				itemcountnorm = itemcountnorm + itemcountCollectable
				itemcountCollectable = 0
			end
			local itemcount = itemcountnorm + itemcountHQ + itemcountCollectable
			
			if (requireCollect) then
				itemcount = itemcountCollectable
			elseif (requireHQ) then
				itemcount = itemcountHQ
			elseif (countHQ) then
				itemcount = itemcountnorm + itemcountHQ
			end
			
			local taskDetails = ml_task_hub:CurrentTask()
			local canCraft,maxAmount = FFXIVLib.API.Items.CanCraft(recipe.id,taskDetails.useHQ,taskDetails)
			if (not canCraft) then
				cd("[CraftLimit]: We can no longer craft this item, complete the order.",3)
				return true
			else
				if (requiredItems > 0 and itemcount >= (requiredItems + startingCount))	then
					cd("[CraftLimit]: Current item count ["..tostring(itemcount).."] is more than ["..tostring(requiredItems + startingCount).."], no need to start more.",3)
					return true
				end
			end
			
			
		elseif gCraftMarkerOrProfileIndex == 2 then
			cd("Max Items = "..tostring(ml_task_hub:CurrentTask().maxItems))
			cd("Craft Attempts = "..tostring(ml_task_hub:CurrentTask().itemsCrafted))
			if ((ml_task_hub:CurrentTask().maxItems > 0 and ml_task_hub:CurrentTask().itemsCrafted == ml_task_hub:CurrentTask().maxItems) or 
				ml_task_hub:CurrentTask().attemptedStarts > 5) then
				return true
			end
		end
	end
	
    return false
end
function e_craftlimit:execute()
	cd("[CraftLimit]: Profile has reached the preset requirements.",3)
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local recipeid = ml_task_hub:CurrentTask().recipe.id
		local key = ml_task_hub:CurrentTask().key
		ffxiv_craft.orders[key].completed = true
		ffxiv_craft.tracking.measurementDelay = Now()
		
		cd("[CraftLimit]: Setting order with recipe ID ["..tostring(recipeid).."] to complete.",3)
		ml_task_hub:CurrentTask().completed = true
	end
	if gCraftMarkerOrProfileIndex == 2 then
		if (IsControlOpen("RecipeNote")) then
			ffxiv_craft.ToggleCraftingLog()
			ml_task_hub:CurrentTask().allowWindowOpen = true
		end
		ml_global_information:ToggleRun()
	end
end

c_opencraftwnd = inheritsFrom( ml_cause )
e_opencraftwnd  = inheritsFrom( ml_effect )
c_opencraftwnd.fallbackCounter = 0
function c_opencraftwnd:evaluate()
	if not ml_task_hub:CurrentTask().allowWindowOpen then
		c_opencraftwnd.fallbackCounter = IsNull(c_opencraftwnd.fallbackCounter,0) + 1
		d("fall back counter = "..tostring(c_opencraftwnd.fallbackCounter))
	end
	if c_opencraftwnd.fallbackCounter > 20 then
		ml_task_hub:CurrentTask().allowWindowOpen = true
		c_opencraftwnd.fallbackCounter = 0
	end
	if (MIsCasting() or not ml_task_hub:CurrentTask().allowWindowOpen or MIsLocked()) then
		return false
	end
	
	if (not IsControlOpen("Synthesis") and not IsControlOpen("SynthesisSimple") and not IsControlOpen("SynthesisSimpleDialog") and not IsControlOpen("RecipeNote")) then
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
e_startcraft.blocktime = 0
function c_startcraft:evaluate()
	e_startcraft.blocktime = 0
	
	if (not ffxiv_craft.IsCrafting() and (IsControlOpen("RecipeNote") or IsControlOpen("SynthesisSimpleDialog"))) then
		
		if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
			local recipe = ml_task_hub:CurrentTask().recipe
			local jobRequired = recipe.class + 8
			
			if (Player.job == jobRequired) then
				local minCP = ml_task_hub:CurrentTask().requiredCP
				local itemid = ml_task_hub:CurrentTask().itemid
				local requireHQ = ml_task_hub:CurrentTask().requireHQ
				local requireCollect = ml_task_hub:CurrentTask().requireCollect
				local countHQ = ml_task_hub:CurrentTask().countHQ
				local canCraft,maxAmount = FFXIVLib.API.Items.CanCraft(recipe.id,ml_task_hub:CurrentTask().useHQ)
				
				local itemcounts = ffxiv_craft.itemCounts
				local itemcountnorm = IsNull(itemcounts[itemid].count,0)
				local itemcountHQ = IsNull(itemcounts[itemid + 1000000].count,0)
				local itemcountCollectable = IsNull(itemcounts[itemid + 500000].count,0)
				if In(ffxivminion.gameRegion,1) then
					itemcountnorm = itemcountnorm + itemcountCollectable
					itemcountCollectable = 0
				end
				local itemcount = itemcountnorm + itemcountHQ + itemcountCollectable
				
				if (requireCollect) then
					itemcount = itemcountCollectable
				elseif (requireHQ) then
					itemcount = itemcountHQ
				elseif (countHQ) then
					itemcount = itemcountnorm + itemcountHQ
				end
					
				local requiredItems = ml_task_hub:CurrentTask().requiredItems
				local startingCount = ml_task_hub:CurrentTask().startingCount 
				
				local quickCraft = ml_task_hub:CurrentTask().useQuick
				if (canCraft or ml_task_hub:CurrentTask().ifNecessary) then
					if (requiredItems == 0 or (requiredItems > 0 and itemcount < (requiredItems + startingCount))) then
						if (Player.cp.max >= minCP) or (quickCraft and not requireCollect) then
							return true
						else 
							d("[StartCraft]: CP to Low for item ["..tostring(recipe.id).."].",2)
						end
					else
						cd("[StartCraft]: Current item count ["..tostring(itemcount).."] is more than ["..tostring(requiredItems + startingCount).."], no need to start more.",2)
						
					end
				else
					cd("[StartCraft]: We cannot craft anymore of item ["..tostring(recipe.id).."].",2)
				end
			end
		elseif gCraftMarkerOrProfileIndex ~= 1 then
			local minCP = tonumber(gCraftMinCP) or 0
			if (Player.cp.max < minCP) then
				d("[StartCraft]: Current CP < Minimum CP.")
				ml_global_information:ToggleRun()
				return false
			end
			
			local mats = Crafting:GetCraftingMats()
			if (table.valid(mats)) then
				for i = 1,6 do
					local ingredient = mats[i]
					if (ingredient) then
						if (gCraftUseHQ) then
							if (gCraftUseHQBackup) then
								if ((ingredient.selectedhq + ingredient.selectednq) < ingredient.needed) then
									if ((ingredient.inventorynq + ingredient.inventoryhq) >= ingredient.needed) then
										d("[Craft]: This craft requires use of ["..tostring((ingredient.needed - ingredient.inventorynq)).."] HQ of ["..ingredient.name.."] to have enough materials.")
										Crafting:SetCraftingMats(i-1,(ingredient.needed - ingredient.inventorynq))
										e_startcraft.blocktime = math.random(150,300)
										return true
									else
										ffxiv_dialog_manager.IssueStopNotice("Need More Items", "Cannot craft this item, not enough materials.", "okonly")
										return false
									end
								end
							else
								if (ingredient.needed <= ingredient.inventoryhq and (ingredient.selectedhq < ingredient.needed)) then
									d("[Craft]: This craft prefers the use of ["..tostring(ingredient.needed).."] HQ of ["..ingredient.name.."], per options.")
									Crafting:SetCraftingMats(i-1,ingredient.needed)
									e_startcraft.blocktime = math.random(150,300)
									return true
								elseif (ingredient.needed > ingredient.inventoryhq) then
									if (ingredient.selectedhq < ingredient.inventoryhq) then
										d("[Craft]: This craft will use ["..tostring(ingredient.needed).."] HQ of ["..ingredient.name.."], since we can't use 100% HQ.")
										Crafting:SetCraftingMats(i-1,ingredient.inventoryhq)
										e_startcraft.blocktime = math.random(150,300)
										return true
									elseif (ingredient.needed > (ingredient.selectednq + ingredient.selectedhq) and ingredient.needed <= (ingredient.inventoryhq + ingredient.inventorynq)) then -- ghetto fix, can't manually update nq mats atm
										--ml_global_information:ToggleRun()
										ffxiv_craft:ToggleCraftingLog()
										ml_task_hub:CurrentTask().allowWindowOpen = true
										return false
									end
								end
							end
						else
							if (ingredient.needed > ingredient.inventorynq) then
								ffxiv_dialog_manager.IssueStopNotice("Need HQ", "Cannot craft this item without using HQ mats.", "okonly")
								return false
							end
						end
					end
				end
			else
				d("[Craft]: Need to wait for materials control feedback.")
				return false
			end	
				
			if ( Crafting:CanCraftSelectedItem(ml_task_hub:CurrentTask().useQuick) ) then
				return true
			else 
				ml_task_hub:ThisTask().attemptedStarts = ml_task_hub:ThisTask().attemptedStarts + 1
			end
		end
	end	
	
    return false
end

function e_startcraft:execute()
	if (e_startcraft.blocktime > 0) then
		ml_global_information.Await(e_startcraft.blocktime)
		return
	end

	SkillMgr.prevSkillList = {}
	SkillMgr.tempPrevSkillList = {}
	
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local recipe = ml_task_hub:CurrentTask().recipe
		local itemid = ml_task_hub:CurrentTask().itemid
		local indexInfo = Crafting:GetSelectedCraftInfo(recipe.id)
		local skillProfile = ml_task_hub:CurrentTask().skillProfile
		local key = ml_task_hub:CurrentTask().key
		
		if (table.valid(indexInfo)) then
			if indexInfo.iscorrectindex ~= true then 
				d("Recipe phase 1, set to: ["..tostring(recipe.class)..","..tostring(recipe.page)..","..tostring(recipe.id).."].",3)
				Crafting:SetRecipe(recipe.class,recipe.page,recipe.id)
				ml_task_hub:CurrentTask().recipeSelected = true
				ffxiv_craft.tracking.lastSetRecipe = Now()
				ml_task_hub:CurrentTask().matsSet = false
				
				ml_global_information.Await(1000)
				return
			elseif (skillProfile ~= "" and gSkillProfile ~= skillProfile and skillProfile ~= GetString("none")) then
				if (SkillMgr.HasProfile(skillProfile)) then
					SkillMgr.UseProfile(skillProfile)
				end
				
				ml_global_information.Await(1000)
				return
			else
				if (not ml_task_hub:CurrentTask().matsSet) then
					local useHQ = ml_task_hub:CurrentTask().useHQ
					local ifNecessary = ml_task_hub:CurrentTask().ifNecessary
					local mats = Crafting:GetCraftingMats()
					if (table.valid(mats)) then
						if (useHQ) then
							for i = 1,6 do
								local ingredient = mats[i]
								if (ingredient) then
								
									local hqAmountMax = ml_task_hub:CurrentTask()["hq"..tostring(i)]
									if hqAmountMax > ingredient.needed then
										hqAmountMax = ingredient.needed
									end
									local hqAmountMin = ml_task_hub:CurrentTask()["hq"..tostring(i).."min"]
									if not ifNecessary then
										if ((ingredient.inventoryhq >= hqAmountMax) and (hqAmountMax >= hqAmountMin) and (ingredient.selectedhq < hqAmountMax)) then -- set max hq material
											d("[Craft]: Order is set to use Maximum ["..tostring(hqAmountMax).."] HQ of ["..ingredient.name.."].")
											Crafting:SetCraftingMats(i-1,hqAmountMax) -- set max
											ml_global_information.Await(math.random(150,300))
											return
										elseif ((ingredient.inventoryhq >= hqAmountMin) and (ingredient.inventoryhq < hqAmountMax) and (ingredient.selectedhq < ingredient.inventoryhq)) then -- set as much as currently possible
											d("[Craft]: Order is set use as much HQ as I Currently have of ["..tostring(ingredient.inventoryhq).."] HQ of ["..ingredient.name.."].")
											Crafting:SetCraftingMats(i-1,ingredient.inventoryhq) -- set what i have
											ml_global_information.Await(math.random(150,300))
											return
										elseif ((ingredient.selectedhq + ingredient.selectednq) < ingredient.needed) and ((ingredient.inventoryhq + ingredient.inventorynq) >= ingredient.needed) then 
											d("[Craft]: Backup selection")
											Crafting:SetCraftingMats(i-1,math.min(ingredient.needed,ingredient.inventoryhq))
											ml_global_information.Await(math.random(150,300))
											return
										elseif (ingredient.inventoryhq < hqAmountMin) then
											d("[Craft]: Stop crafting item, not enough HQ Items of ["..ingredient.name.."].")
											e_craftlimit:execute()
											return false
										elseif ((ingredient.selectedhq + ingredient.inventorynq) < ingredient.needed) then
											d("[Craft]: Stop crafting item, not enough ingrediends of ["..ingredient.name.."].")
											e_craftlimit:execute()
											return false
										end
									else
										if ((ingredient.selectedhq + ingredient.selectednq) < ingredient.needed) then
											if ((ingredient.inventorynq + ingredient.inventoryhq) >= ingredient.needed and ingredient.selectedhq < (ingredient.needed - ingredient.selectednq)) then
												d("[Craft]: Order is set to use HQ mats if necessary, need ["..tostring((ingredient.needed - ingredient.inventorynq)).."] of ["..ingredient.name.."].")
												Crafting:SetCraftingMats(i-1,(ingredient.needed - ingredient.inventorynq))
												ml_global_information.Await(math.random(150,300))
												return
											else
												d("[Craft]: Not enough materials including HQ.")
												e_craftlimit:execute()
												return false
											end
										end
									end
								end
							end
						end
						ml_task_hub:CurrentTask().matsSet = true
					else
						d("[Craft]: Need to wait for materials control feedback.")
						return false
					end				
				else
					if (Crafting:CanCraftSelectedItem(ml_task_hub:CurrentTask().useQuick)) then
						ml_task_hub:CurrentTask().failedAttempts = 0
						local usequick = ml_task_hub:CurrentTask().useQuick
						local requireCollect = ml_task_hub:CurrentTask().requireCollect
						if (usequick and not requireCollect) then
							local itemid = ml_task_hub:CurrentTask().itemid
							local canCraft,maxAmount = FFXIVLib.API.Items.CanCraft(recipe.id,ml_task_hub:CurrentTask().useHQ)
							local wantedAmount = ml_task_hub:ThisTask().requiredItems
							local yield = FFXIVLib.API.Items.GetRecipeDetails(recipe.id).yield
							local craftAmount = math.ceil(wantedAmount / yield)
							if (craftAmount > 0 and craftAmount <= (maxAmount / yield) and craftAmount <= 99) then
								if (IsControlOpen("SynthesisSimpleDialog")) then
									d("using control with craftamount :"..tostring(craftAmount))
									UseControlAction("SynthesisSimpleDialog","Synthesize",{craftAmount, ml_task_hub:CurrentTask().useHQ})
								else
									d("using quick synth again")
									UseControlAction("RecipeNote","QuickSynthesis",{craftAmount, ml_task_hub:CurrentTask().useHQ})
									ml_global_information.Await(1000, 5000, function () return (IsControlOpen("SynthesisSimpleDialog") and not IsControlOpen("RecipeNote")) end)
									return
								end
							else
								if ((maxAmount / yield) > 99) then
									if (IsControlOpen("SynthesisSimpleDialog")) then
										d("using control with 99 :"..tostring(craftAmount))
										UseControlAction("SynthesisSimpleDialog","Synthesize",{99, ml_task_hub:CurrentTask().useHQ})
									else
										UseControlAction("RecipeNote","QuickSynthesis",{craftAmount, ml_task_hub:CurrentTask().useHQ})
										ml_global_information.Await(1000, 5000, function () return (IsControlOpen("SynthesisSimpleDialog") and not IsControlOpen("RecipeNote")) end)
										return
									end
								else
									if (IsControlOpen("SynthesisSimpleDialog")) then
										d("using control with max yield :"..tostring(craftAmount))
										UseControlAction("SynthesisSimpleDialog","Synthesize",{(maxAmount / yield), ml_task_hub:CurrentTask().useHQ})
									else
										UseControlAction("RecipeNote","QuickSynthesis",{craftAmount, ml_task_hub:CurrentTask().useHQ})
										ml_global_information.Await(1000, 5000, function () return (IsControlOpen("SynthesisSimpleDialog") and not IsControlOpen("RecipeNote")) end)
										return
									end
								end
							end
							SkillMgr.newCraft = true
							ml_task_hub:CurrentTask().allowWindowOpen = false
							ml_global_information.Await(5000, function () return (IsControlOpen("SynthesisSimple") and not IsControlOpen("RecipeNote")) end)
							return true
						else
							UseControlAction("RecipeNote","Synthesize")	
							SkillMgr.newCraft = true
							ml_task_hub:CurrentTask().matsSet = false
							ml_task_hub:CurrentTask().allowWindowOpen = false
							ml_global_information.Await(5000, function () return (IsControlOpen("Synthesis") and not IsControlOpen("RecipeNote")) end)
							return true
						end
						return
					else
						if (ml_task_hub:CurrentTask().failedAttempts < 10) then
							d("[StartCraft]: We cannot craft anymore of item ["..tostring(recipe.id).."], but we will try a couple more times to be sure.",3)
							ml_task_hub:CurrentTask().failedAttempts = ml_task_hub:CurrentTask().failedAttempts + 1
							ml_task_hub:CurrentTask().matsSet = false
							ml_task_hub:CurrentTask().recipeSelected = false
							ffxiv_craft.resetRecipe = true
							ml_task_hub:CurrentTask().allowWindowOpen = true
							ml_global_information.Await(2500)
							return
						else
							cd("[StartCraft]: We cannot craft anymore of item ["..tostring(recipe.id).."].",3)
							ffxiv_craft.orders[key].completed = true
							ml_task_hub:CurrentTask().completed = true
						end
					end			
				end
			end
		end
	elseif gCraftMarkerOrProfileIndex ~= 1 then				
		UseControlAction("RecipeNote","Synthesize")	
		ml_task_hub:ThisTask().attemptedStarts = ml_task_hub:ThisTask().attemptedStarts + 1
		SkillMgr.newCraft = true
		ml_global_information.Await(5000, function () return (IsControlOpen("Synthesis") and not IsControlOpen("RecipeNote")) end)
		--ml_task_hub:CurrentTask().allowWindowOpen = false
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
		
		if Player.ismounted and not IsFlying() then
			cd("[PreCraftBuff]: Need to Dismount.",3)
			e_precraftbuff.activity = "dismount"
			e_precraftbuff.requiresLogClose = false
			return true
		end
		
		if (NeedsRepair()) then
			cd("[PreCraftBuff]: Need to repair.",3)
			e_precraftbuff.activity = "repair"
			e_precraftbuff.requiresLogClose = false
			return true
		end
		
		local canUseTea,teaItem = ffxiv_craft.CanUseTea()
		if (canUseTea and table.valid(teaItem)) then
			d("[NodePreBuff]: Need to use a Tea.")
			e_precraftbuff.activity = "usetea"
			e_precraftbuff.item = teaItem
			e_precraftbuff.requiresLogClose = true
			return true
		end
		
		if (ffxiv_craft.Canextractmateria() and gextractmateria) then
			d("[NodePreBuff]: Need to extract materia.")
			e_precraftbuff.activity = "extractmateria"
			e_precraftbuff.requiresLogClose = true
			return true
		end		
		
		if (gCraftFood ~= GetString("none")) then
			local foodDetails = ml_global_information.foods[gCraftFood]
			if (foodDetails) then
				local foodID = foodDetails.id
				local foodStack = foodDetails.buffstackid
				
				local food, action = GetItem(foodID)
				local timer = 180
				if (ffxivminion.gameRegion == 3) then
					timer = 30
				end
				if (food and action and not action.isoncd and MissingBuffX(Player,48,foodStack,timer)) then
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
		
		local hasCollect = HasBuffs(Player,"903")
		
		local isCollectable = gCraftCollectable
		if gCraftMarkerOrProfileIndex == 1 then
			isCollectable = ml_task_hub:CurrentTask().useCollect
		end
		if GetPatchLevel() < 5.3 then 
			if Player.level >= 50 and ((hasCollect and not isCollectable) or (not hasCollect and isCollectable)) then
				local collect = ActionList:Get(1,ffxiv_craft.collectors[Player.job])
				if (collect) then
					e_precraftbuff.activity = "usecollect"
					e_precraftbuff.requiresLogClose = true
					return true
				end
			end
		end
		
		if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
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
	local activity = e_precraftbuff.activity
	
	if (e_precraftbuff.requiresLogClose) then
		if (IsControlOpen("RecipeNote")) then
			ffxiv_craft.ToggleCraftingLog()
			ml_task_hub:CurrentTask().allowWindowOpen = true
			return
		end
	end
	
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
			ml_global_information.AwaitSuccess(5000, function () return Player.castinginfo.lastcastid == castid end)
		end	
	elseif (activity == "switchclass") then
		local recipe = ml_task_hub:CurrentTask().recipe
		local jobRequired = recipe.class + 8
		local gearset = _G["gGearset"..tostring(jobRequired)]
		d("[PreCraftBuff]: Attempting to switch to gearset ["..tostring(gearset).."].",3)
		local commandString = "/gearset change "..tostring(gearset)
		SendTextCommand(commandString)
		ml_global_information.Await(3000)
	elseif (activity == "usemanual") then
		local manual = activityItem
		if (manual and manual:IsReady(Player.id)) then
			manual:Cast(Player.id)
			ml_global_information.AwaitSuccess(2000, 4000, function () return HasBuff(Player.id, 46) end)
			return
		end
	elseif (activity == "usetea") then
		local tea = activityItem
		if (tea and tea:IsReady(Player.id)) then
			tea:Cast(Player.id)
			ml_global_information.AwaitSuccess(2000, 4000, function () return HasBuff(Player.id, 49) end)
			return
		end
	elseif (activity == "extractmateria") then
		ffxiv_craft.extractmateria()
		ml_global_information.Await(4000)
	elseif (activity == "usecollect") then
		local collect = ActionList:Get(1,ffxiv_craft.collectors[Player.job])
		local hasCollect = HasBuffs(Player,"903")
		if (collect and collect:IsReady(Player.id)) then
			if (collect:Cast()) then
				if (not hasCollect) then
					ml_global_information.AwaitSuccess(2500, function () return HasBuff(Player.id,903) end)
				else
					ml_global_information.AwaitSuccess(2500, function () return MissingBuff(Player.id,903) end)
				end
			end
		end
	elseif (activity == "dismount") then
		Dismount()
		ml_global_information.AwaitSuccess(2000, 4000, function () return not Player.ismounted end)
	end
end

c_craftend = inheritsFrom( ml_cause )
e_craftend = inheritsFrom( ml_effect )
function c_craftend:evaluate()
	if (IsControlOpen("Synthesis")) then
		local synthData = GetControlData("Synthesis")
		if (synthData and synthData.progress == synthData.progressmax) then
			ml_global_information.AwaitSuccess(1000, 3000, function () return IsControlOpen("RecipeNote") end)
			return true
		end
	end
    return false
end
function e_craftend:execute()
end

c_craft = inheritsFrom( ml_cause )
e_craft = inheritsFrom( ml_effect )
function c_craft:evaluate()
	if ( ffxiv_craft.IsCrafting() ) then	
		if (IsControlOpen("Synthesis")) then
			local synthData = GetControlData("Synthesis")
			if (synthData and IsNull(synthData.itemid,0) ~= 0 and IsNull(synthData.name,"") ~= "") then
				ffxiv_craft.lastCraft = { id = synthData.itemid, name = synthData.name }
			end
		end	
		
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
end

c_collectibleaddoncraft = inheritsFrom( ml_cause )
e_collectibleaddoncraft = inheritsFrom( ml_effect )
function c_collectibleaddoncraft:evaluate()
	local addonName = "SelectYesno"
	--if (ffxivminion.gameRegion == 3) then
		--addonName = "SelectYesNoCountItem"
	--end
	if (IsControlOpen("SelectYesNoItem") or IsControlOpen(addonName)) then
		local info = GetControlData(addonName)
		if (info and IsNull(info.collectability,-1) >= 0) then
			local validCollectible = false
			
			local job = Player.job
			local lastCraft = ffxiv_craft.lastCraft --= { id = synthData.itemid, name = synthData.name }
			
			local reqValue = 0
			local thisCraft = ""
				d("info.itemid = "..tostring(info.itemid))
			
			if (table.valid(gCraftCollectablePresets)) then
				local thisCollectable = gCraftCollectablePresets[info.itemid]
				
				if (info.itemid > 500000) and (info.itemid < 1000000) then
					thisCollectable = gCraftCollectablePresets[info.itemid - 500000]
					d("new info.itemid = "..tostring(info.itemid - 500000))
				end
				
				if thisCollectable then
					d("Item trating = "..tostring(info.collectability))
					d("Min trating = "..tostring(thisCollectable.value))
					thisCraft = thisCollectable.name
					reqValue = tonumber(thisCollectable.value)
					if (info.collectability >= reqValue) then
						validCollectible = true
					end
				end
			end

			if (not validCollectible) then
				d("Cannot collect item ["..info.name.."]["..tostring(info.collectability).."], collectibility rating not approved ("..tostring(reqValue).." required for "..thisCraft..").",2)
				UseControlAction(addonName,"No",0,500)
			else
				d("Attempting to collect item ["..info.name.."]["..tostring(info.collectability).."], collectibility rating approved ("..tostring(reqValue).." required for "..thisCraft..").",2)
				UseControlAction(addonName,"Yes",0,500)
			end
			ml_global_information.Await(2000, 3000, function () return not IsControlOpen("Synthesis") end)						
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
			ml_task_hub:CurrentTask().quickTimer = 0
			ml_global_information.Await(6000)
			return true
		end
	end
	
	if (Player.action == 241 or Player.action == 248) then
		ml_task_hub:CurrentTask().quickTimer = Now()
	end
end

c_selectcraft = inheritsFrom( ml_cause )
e_selectcraft = inheritsFrom( ml_effect )
function c_selectcraft:evaluate()
	if ( ffxiv_craft.IsCrafting() ) then	
		return false
	end
	
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local orders = ffxiv_craft.orders
		for id,order in pairs(orders) do
			if (order.completed == nil) then
				cd("[SelectCraft]: Initializing the completion status for id ["..tostring(id).."].",3)
				orders[id].completed = false
			end
			if (order.completed == false and order.skip ~= true) then
				local canCraft,maxAmount = FFXIVLib.API.Items.CanCraft(order.id,order.usehq)
				if (canCraft) or (order.ifnecessary) then
					cd("[SelectCraft]: Found an incomplete order ["..tostring(id).."], select a new craft.",3)
					return true
				else
					d("Can't Craft:"..tostring(order.name))
				end
			end
		end
		ffxiv_craft.ToggleCraftingLog()
		ffxiv_dialog_manager.IssueStopNotice("Nothing Craftable", "You cannot craft any of the items in the profile.", "okonly")
	elseif  gCraftMarkerOrProfileIndex ~= 1 then
		return true
	end
	return false
end
function e_selectcraft:execute()

	local newTask = ffxiv_task_craftitems.Create()
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local orders = ffxiv_craft.orders
		
		local foundSelection = false
		for id,order in spairs(orders) do
		
			if (not order.completed and not order.skip) then
				local canCraft,maxAmount = FFXIVLib.API.Items.CanCraft(order.id,order.usehq)

				if (canCraft) or (order.ifnecessary) then
					local itemid = order.item
					local collectable = order.collect and In(ffxivminion.gameRegion,2,3)
					
				
					local itemcounts = ffxiv_craft.itemCounts
					local itemcountnorm = IsNull(itemcounts[itemid].count,0)
					local itemcountHQ = IsNull(itemcounts[itemid + 1000000].count,0)
					local itemcountCollectable = IsNull(itemcounts[itemid + 500000].count,0)
					if In(ffxivminion.gameRegion,1) then
						itemcountnorm = itemcountnorm + itemcountCollectable
						itemcountCollectable = 0
					end
					local itemcount = itemcountnorm + itemcountHQ + itemcountCollectable
					if (collectable) then
						itemcount = itemcountCollectable
					elseif (requireHQ) then
						itemcount = itemcountHQ
					elseif (countHQ) then
						itemcount = itemcountnorm + itemcountHQ
					end
					
					newTask.startingCount = itemcount
					cd("[SelectCraft]: Starting Amount :"..tostring(itemcount)..".",3)
					newTask.requiredItems = order.amount
					cd("[SelectCraft]: Required Amount :"..tostring(order.amount)..".",3)
					newTask.requireHQ = order.requirehq
					newTask.requireCollect = collectable
					newTask.requiredCP = order.requiredcp
					cd("[SelectCraft]: Required requiredcp :"..tostring(order.requiredcp)..".",2)
					newTask.countHQ = order.counthq
					newTask.itemid = order.item
					newTask.useQuick = order.usequick
					newTask.useCollect = collectable
					newTask.useHQ = order.usehq
					newTask.ifNecessary = order.ifnecessary
					cd("[SelectCraft]: Order HQ Status :"..tostring(order.usehq)..".",3)
					newTask.skillProfile = order.skillprofile
					newTask.key = id
					
					for i = 1,6 do
						newTask["hq"..tostring(i)] = IsNull(order["hq"..tostring(i)],0)
						newTask["hq"..tostring(i).."min"] = IsNull(order["hq"..tostring(i).."min"],0)
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
	elseif  gCraftMarkerOrProfileIndex ~= 1 then
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
	newinst.synthStarted = false
	newinst.attemptedStarts = 0
	newinst.itemsCrafted = 0
	newinst.allowWindowOpen = true
	newinst.maxItems = 0
	
	newinst.startingCount = 0
	newinst.requiredItems = 0
	newinst.requiredCP = 0
	newinst.requireHQ = false
	newinst.requireCollect = false
	newinst.countHQ = true
	newinst.itemid = 0
	newinst.useQuick = false
	newinst.useCollect = false
	newinst.useHQ = false
	newinst.ifNecessary = false
	newinst.recipe = {}
	newinst.recipeSelected = false
	newinst.matsSet = false
	newinst.skillProfile = ""
	newinst.key = 0
	newinst.quickTimer = 0
	
	newinst.failedAttempts = 0
    
    return newinst
end

function ffxiv_task_craftitems:Init()
	local ke_badLog = ml_element:create( "BadLogState", c_waitlog, e_waitlog, 170 )
    self:add( ke_badLog, self.process_elements)

	local ke_closeLog = ml_element:create( "CloseLog", c_closelog, e_closelog, 160 )
    self:add( ke_closeLog, self.process_elements)
	
	local ke_craftend = ml_element:create( "CraftComplete", c_craftend, e_craftend, 61 )
    self:add(ke_craftend, self.process_elements)  
	
	local ke_inventoryFull = ml_element:create( "InventoryFull", c_inventoryfull, e_inventoryfull, 150 )
    self:add( ke_inventoryFull, self.process_elements)
	
	local ke_reachedCraftLimit = ml_element:create( "ReachedCraftLimit", c_craftlimit, e_craftlimit, 140 )
    self:add(ke_reachedCraftLimit, self.process_elements)
	
	local ke_repair = ml_element:create( "Repair", cf_needsrepair, ef_needsrepair, 121 )
    self:add( ke_repair, self.process_elements)
	
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
			
	local ke_resetCraft = ml_element:create( "ResetCraft", c_resetcraft, e_resetcraft, 1000 )
    self:add(ke_resetCraft, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_craftitems:task_complete_eval()
	return false
end

function ffxiv_task_craftitems:task_complete_execute()
	if (IsControlOpen("RecipeNote")) then
		ffxiv_craft.ToggleCraftingLog()
		ml_task_hub:CurrentTask().allowWindowOpen = true
	end
	
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
	
	self:InitExtras()
end

function ffxiv_task_craft:InitExtras()
	local overwatch_elements = self.addon_overwatch_elements
	if (table.valid(overwatch_elements)) then
		for i,element in pairs(overwatch_elements) do
			self:add(element, self.overwatch_elements)
		end
	end
	
	local process_elements = self.addon_process_elements
	if (table.valid(process_elements)) then
		for i,element in pairs(process_elements) do
			self:add(element, self.process_elements)
		end
	end
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
		Settings.FFXIVMINION.gLastCraftProfiles = Settings.FFXIVMINION.gLastCraftProfiles
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
	gCraftCollectable = ffxivminion.GetSetting("gCraftCollectable",false)
	gCraftUseHQBackup = ffxivminion.GetSetting("gCraftUseHQBackup",false)
	
	--for i = 8,15 do
	--	_G["gGearset"..tostring(i)] = ffxivminion.GetSetting("gGearset"..tostring(i),0)
	--end
	
	gCraftOrderSelectIndex = 1
	gCraftOrderSelect = "CRP"
	gCraftDictionarySelectKeepSettings = false
	gCraftCollectablePresets = ffxivminion.GetSetting("gCraftCollectablePresets",{})	
	gRefreshCollectables = ffxivminion.GetSetting("gRefreshCollectables",0)
	
	if gRefreshCollectables < 20200807 then
		gCraftCollectablePresets = {}
		GUI_Set("gCraftCollectablePresets",{})
		for k,v in pairs(ffxiv_craft.collectibles) do
			local newID = FFXIVLib.API.Items.GetIDByName(v.name)
			if newID then
				gCraftCollectablePresets[FFXIVLib.API.Items.GetIDByName(v.name)] =  { name = v.name, value = v.minimum }
			end
		end
		
		FFXIVLib.API.Items.UpdateCollectablePresets() -- Updates all basic class items, region specific.
		Settings.FFXIVMINION.gCraftCollectablePresets = gCraftCollectablePresets
		
		gRefreshCollectables = 20200807
		Settings.FFXIVMINION.gRefreshCollectables = gRefreshCollectables
		d("[Craft] Collectables Updated")
	end
	
		
	gTeaSelection = {GetString("none"),GetString("CP"),GetString("Control"),GetString("Craftmanship"),GetString("Any")}
	gCraftTeaList = ffxivminion.GetSetting("gCraftTeaList",GetString("none"))
	gCraftTeaTypeIndex = IsNull(GetKeyByValue(gCraftTeaList,gTeaSelection),1)
	
	gCraftFood = ffxivminion.GetSetting("gCraftFood",GetString("none"))
	gCraftFoodIndex = IsNull(GetKeyByValue(gCraftFood,gFoods),1)
	
	gextractmateria = ffxivminion.GetSetting("gextractmateria",true)
	
	local currentFood = gFoods[gCraftFoodIndex]
	if (gCraftFood ~= currentfood) then
		if (table.valid(gFoods)) then
			for i,food in pairs(gFoods) do
				if (food == gCraftFood) then
					gCraftFoodIndex = i
					gCraftFood =  gFoods[gCraftFoodIndex]
				end
			end
		end
	end
		
	glastAlertUpdate = 0
	gUseCPTea = ffxivminion.GetSetting("gUseCPTea",false)
	-- Order Stuff
	
	--Add
	gCraftOrderAddID = 0
	gCraftOrderAddRecipeID = 0
	gCraftOrderAddAmount = 1
	gCraftOrderAddRequireHQ = false
	gCraftOrderAddRequireCP = 0
	gCraftOrderAddCountHQ = true
	gCraftOrderAddQuick = false
	gCraftOrderAddCollect = false
	gCraftOrderAddHQ = false
	gCraftOrderAddIfNecessary = false
	gCraftOrderAddSkillProfileIndex = 1
	gCraftOrderAddSkillProfile = GetString("none")
	
	--Edit
	gCraftOrderEditID = 0
	gCraftOrderEditRecipeID = 0
	gCraftOrderEditAmount = 1
	gCraftOrderEditRequireHQ = false
	gCraftOrderEditRequiredCP = 0
	gCraftOrderEditCountHQ = true
	gCraftOrderEditQuick = false
	gCraftOrderEditCollect = false
	gCraftOrderEditHQ = false
	gCraftOrderEditIfNecessary = false
	gCraftOrderEditSkillProfileIndex = 1
	gCraftOrderEditSkillProfile = GetString("none")
	gCraftOrderEditSkip = false
	
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
		_G["gCraftOrderAddHQIngredient"..tostring(i).."Min"] = 0
		_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"] = false
	end
	
	for i = 1,6 do
		_G["gCraftOrderEditHQIngredient"..tostring(i)] = 0
		_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"] = 0
		_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = false
	end
	
	for k = 5,100,5 do
		_G["gCraftDictionarySelectIndex"..tostring(k)] = 1
		_G["gCraftDictionarySelect"..tostring(k)] = GetString("none")				
	end
	
	-- New Marker/Profile Settings
	gCraftMarkerOrProfileOptions = { GetString("Profile"), GetString("Quick Start Mode") }
	gCraftMarkerOrProfile = ffxivminion.GetSetting("gCraftMarkerOrProfile",GetString("Markers"))
	gCraftMarkerOrProfileIndex = ffxivminion.GetSetting("gCraftMarkerOrProfileIndex",1)
	
	if gCraftMarkerOrProfileIndex == 1 then
		self.GUI.main_tabs = GUI_CreateTabs("Craft List,Settings,Collectable,Debug",true)
	elseif gCraftMarkerOrProfileIndex == 2 then
		self.GUI.main_tabs = GUI_CreateTabs("Settings,Collectable,Debug",true)
	end
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
	local tabindex, tabname = GUI_DrawTabs(self.GUI.main_tabs)
	local tabs = self.GUI.main_tabs
	-- Craft Mode Selections.
	GUI:Separator()
	local MarkerOrProfileWidth = (GUI:GetContentRegionAvail() - 10)
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Craft Mode"))
	GUI:SameLine(110)
	GUI:PushItemWidth(MarkerOrProfileWidth - 110)
	local MarkerOrProfile = GUI_Combo("##MarkerOrProfile", "gCraftMarkerOrProfileIndex", "gCraftMarkerOrProfile", gCraftMarkerOrProfileOptions)
	if (MarkerOrProfile) then
		-- Update tabs on change.
		if gCraftMarkerOrProfileIndex == 1 then
			self.GUI.main_tabs = GUI_CreateTabs("Craft List,Settings,Collectable,Gearsets,Debug",true)
		elseif gCraftMarkerOrProfileIndex == 2 then
			self.GUI.main_tabs = GUI_CreateTabs("Settings,Collectable,Gearsets,Debug",true)
		end
	end
	GUI:PopItemWidth()
	
	if  (gCraftMarkerOrProfileIndex == 1) then
	
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Profile")) 
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Profile Tooltip")) end
		GUI:SameLine(110)
		
		local newButtonWidth = (MarkerOrProfileWidth - 10) / 2
		GUI:PushItemWidth(MarkerOrProfileWidth - 110)
		local profileChanged = GUI_Combo("##"..GetString("Profile"), "gCraftProfileIndex", "gCraftProfile", ffxiv_craft.profilesDisplay)
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Profile Tooltip")) end
		GUI:PopItemWidth()
		if (profileChanged) then
			ffxiv_craft.profileData = ffxiv_craft.profiles[gCraftProfile]
			local uuid = GetUUID()
			Settings.FFXIVMINION.gLastCraftProfiles[uuid] = gCraftProfile
			Settings.FFXIVMINION.gLastCraftProfiles = Settings.FFXIVMINION.gLastCraftProfiles
			ffxiv_craft.orders = ffxiv_craft.profileData.orders
			ffxiv_craft.ResetOrders()
		end
		GUI:PopItemWidth()
		--GUI:SameLine()
		
		if (GUI:Button(GetString("Craft Orders"),newButtonWidth,20)) and gCraftProfile ~= GetString("none") then
			ffxiv_task_craft.GUI.orders.open = not ffxiv_task_craft.GUI.orders.open
		end
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Opens the Crafting Order Editor.")) end
		GUI:SameLine()
		
		if (GUI:Button(GetString("New Profile"),newButtonWidth ,20)) then
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
						gCraftProfile = gCraftNewProfileName
						gCraftProfileIndex = GetKeyByValue(gCraftProfile,ffxiv_craft.profilesDisplay)
						local uuid = GetUUID()
						Settings.FFXIVMINION.gLastCraftProfiles[uuid] = gCraftProfile
						Settings.FFXIVMINION.gLastCraftProfiles = Settings.FFXIVMINION.gLastCraftProfiles
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
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Creates a New Crafting Order profile.")) end
	end
	
	-- Orders List
	if (tabname == GetString("Craft List")) then
		ffxiv_craft.UpdateAlertElement()
		
		if FFXIV_Common_BotRunning and (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
			if (ml_task_hub:CurrentTask() and ml_task_hub:CurrentTask().itemid ~= nil) then
				local itemid = ml_task_hub:CurrentTask().itemid
				local requiredItems = ml_task_hub:CurrentTask().requiredItems
				local requireCollect = ml_task_hub:CurrentTask().requireCollect
				local startingCount = ml_task_hub:CurrentTask().startingCount 
				local requireHQ = ml_task_hub:CurrentTask().requireHQ
				local countHQ = ml_task_hub:CurrentTask().countHQ
				
				local itemcount = 0
				if (requireCollect) then
					itemcount = itemcount + ItemCount(itemid + 500000)
				elseif (requireHQ) then
					itemcount = itemcount + ItemCount(itemid + 1000000)
				elseif (countHQ) then
					itemcount = itemcount + ItemCount(itemid,true)
				else
					itemcount = itemcount + ItemCount(itemid)
				end
				local remainingCount = 0
				if (requiredItems > 0) then
					remainingCount = (requiredItems - (itemcount - startingCount))
					GUI:PushItemWidth(50)
					GUI:Text(GetString("Remaining Count of Current Item: ")); GUI:SameLine(); GUI:InputText("##remainingCount",remainingCount,GUI.InputTextFlags_ReadOnly)
					GUI:PopItemWidth()
				else
					local orders = ffxiv_craft.orders
					if (table.valid(orders)) then
						local maxCount = IsNull(orders[ml_task_hub:CurrentTask().key].maxcount,"Inf")
						GUI:PushItemWidth(50)
						GUI:Text(GetString("Remaining Count of Current Item: ")); GUI:SameLine(); GUI:InputText("##CountRemaining",maxCount,GUI.InputTextFlags_ReadOnly) 
						if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Based from total item count only.")) end
				
						GUI:PopItemWidth()
					end
				end
			end
		end
	
		GUI:Separator();
		GUI:Columns(10, "#craft-manage-orders", true)
			GUI:SetColumnOffset(1, 260);
			GUI:SetColumnOffset(2, 310);
			GUI:SetColumnOffset(3, 360);
			GUI:SetColumnOffset(4, 410);
			GUI:SetColumnOffset(5, 460);
			GUI:SetColumnOffset(6, 500);
			GUI:SetColumnOffset(7, 530); -- up icon
			GUI:SetColumnOffset(8, 560); -- down icon
			GUI:SetColumnOffset(9, 605);
			GUI:SetColumnOffset(10, 680);
		
		GUI:Text(GetString("Item")); GUI:NextColumn();
		GUI:Text(GetString("Total")); GUI:NextColumn();
		GUI:Text(GetString("Norm")); GUI:NextColumn();
		GUI:Text(GetString("HQ")); GUI:NextColumn();
		GUI:Text(GetString("COL")); GUI:NextColumn();
		GUI:Text(GetString("Edit")); GUI:NextColumn();
		GUI:NextColumn(); -- up icon
		GUI:NextColumn(); -- down icon
		GUI:Text(GetString("Skip")); GUI:NextColumn();
		GUI:Text(GetString("Alert")); GUI:NextColumn();
		GUI:Separator();
		
		local orders = ffxiv_craft.orders
		if (table.valid(orders)) then
			for id,order in spairs(orders) do
			GUI:AlignFirstTextHeightToWidgets(); 
			local collectable = order.collect and In(ffxivminion.gameRegion,2,3)
			if (collectable) then
				if gCraftCollectablePresets[order.item] then
					GUI:TextColored(.1,1,.2,1,"(C) " .. tostring(order.name))
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Has Collectable Info")) end
				else
					GUI:TextColored(1,.1,.2,1,"(C) " .. tostring(order.name))
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Collectable Info Missing")) end
				end
			else
				GUI:AlignFirstTextHeightToWidgets(); GUI:Text(order.name);
			end	
				itemcount = order["itemcount"]
				itemcountNorm = order["itemcountnorm"]
				itemcountHQ = order["itemcounthq"]
				itemcountCollectable = order["itemcountcollectable"]
				GUI:NextColumn()
				GUI:AlignFirstTextHeightToWidgets(); GUI:InputText("##itemcount",itemcount,GUI.InputTextFlags_ReadOnly) ; 
				GUI:NextColumn()
				GUI:AlignFirstTextHeightToWidgets(); GUI:InputText("##itemcountNorm",itemcountNorm,GUI.InputTextFlags_ReadOnly) ; 
				GUI:NextColumn()
				GUI:AlignFirstTextHeightToWidgets(); GUI:InputText("##itemcountHQ",itemcountHQ,GUI.InputTextFlags_ReadOnly) ; 
				GUI:NextColumn()
				GUI:AlignFirstTextHeightToWidgets(); GUI:InputText("##itemcountCollectable",itemcountCollectable,GUI.InputTextFlags_ReadOnly) ; 
				GUI:NextColumn()
				
				GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
				--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
				GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
				
				if (GUI:ImageButton("##craft-manage-edit"..tostring(id),ml_global_information.path.."\\GUI\\UI_Textures\\w_edit.png", 16, 16)) then
					gCraftOrderEditID = id
					gCraftOrderEditRecipeID = order.id
						
					gCraftOrderEditAmount = IsNull(order["amount"],0)
					gCraftOrderEditRequiredCP = IsNull(order["requiredcp"],0)
					gCraftOrderEditRequireHQ = IsNull(order["requirehq"],false)
					gCraftOrderEditCountHQ = IsNull(order["counthq"],true)
					gCraftOrderEditCollect = IsNull(order["collect"],false)
					if gCraftOrderEditCollect == true then
						gCraftOrderEditQuick = false
					else
						gCraftOrderEditQuick = IsNull(order["usequick"],false)
					end
					gCraftOrderEditHQ = IsNull(order["usehq"],false)
					gCraftOrderEditIfNecessary = IsNull(order["ifnecessary"],false)

					gCraftOrderEditSkillProfile = IsNull(order["skillprofile"],GetString("none"))
					gCraftOrderEditSkillProfileIndex = GetKeyByValue(gCraftOrderEditSkillProfile,SkillMgr.profiles)
					for i = 1,6 do
						if (not order["hq"..tostring(i)]) then
							_G["gCraftOrderEditHQIngredient"..tostring(i)] = 0
							_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"] = 0
							_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = false
							ffxiv_craft.UpdateOrderElement()
						else
							_G["gCraftOrderEditHQIngredient"..tostring(i)] = IsNull(order["hq"..tostring(i)],0)
							_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"] = IsNull(order["hq"..tostring(i).."min"],0)
							_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = IsNull(order["hq"..tostring(i).."max"],false)
						end
					end
							
					ffxiv_craft.UpdateOrderElement()		
					ffxiv_task_craft.GUI.orders.open = true
					GUI_SwitchTab(ffxiv_task_craft.GUI.orders.main_tabs,3)
				end
				
				GUI:PopStyleColor(2)
				GUI:NextColumn()
				
				local doPriorityUp = 0
				local doPriorityDown = 0
				local doPriorityTop = 0
					
				GUI:Image(ml_global_information.path.."\\GUI\\UI_Textures\\w_up.png",16,16); GUI:SameLine(0,15);
				if (GUI:IsItemHovered()) then
					if (GUI:IsMouseClicked(0)) then
						doPriorityUp = id
					elseif (GUI:IsMouseClicked(1)) then
						doPriorityTop = id
					end
					GUI:SetTooltip(GetString("Right click will update old profile task numbering on move."))
				end
				if (doPriorityUp ~= 0 and doPriorityUp ~= 1) then
					
					local currentPos = doPriorityUp
					local newPos = doPriorityUp - 1
					
					local temp = orders[newPos]
					orders[newPos] = orders[currentPos]
					orders[currentPos] = temp	
										
					ffxiv_craft.SaveProfile()
				end
				if (doPriorityTop ~= 0 and doPriorityTop ~= 1) then
					
					local currentPos = doPriorityTop
					local newPos = doPriorityTop
					
					while currentPos > 1 do
						local temp = orders[newPos]
						orders[newPos] = orders[currentPos]
						orders[currentPos] = temp	
						currentPos = newPos
						newPos = newPos - 1
					end
										
					ffxiv_craft.SaveProfile()
				end
					
				GUI:NextColumn()
				
				GUI:Image(ml_global_information.path.."\\GUI\\UI_Textures\\w_down.png",16,16); GUI:SameLine(0,15);
				if (GUI:IsItemHovered()) then
					if (GUI:IsMouseClicked(0)) then
						doPriorityDown = id
					end
				end
				if (doPriorityDown ~= 0 and doPriorityDown < TableSize(orders)) then
					
					local currentPos = doPriorityDown
					local newPos = doPriorityDown + 1
					
					local temp = orders[newPos]
					orders[newPos] = orders[currentPos]
					orders[currentPos] = temp	
										
					ffxiv_craft.SaveProfile()
				end
				
				GUI:NextColumn()
				
				gCraftOrderEditSkip = IsNull(order.skip,false)
				local newVal, changed = GUI:Checkbox("##skip-"..tostring(id),gCraftOrderEditSkip)
				if (changed) then
					orders[id].skip = newVal
					if orders[id].skip == true then
						orders[id].uialert = "skip"
					end
				end
				
				GUI:NextColumn()
				GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
				--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
				GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
				
				local acrEnabled = false					
				if (IsGatherer(Player.job)) then
					if (gACREnabledGather) then
						acrEnabled = true
					end
				elseif (IsCrafter(Player.job)) then
					if (gACREnabledCraft) then
						acrEnabled = true
					end
				elseif (IsFighter(Player.job)) then
					if (gACREnabled) then
						acrEnabled = true
					end
				end
				local uiAlert = IsNull(order["uialert"],nil)
				local acrValid = (acrEnabled and table.valid(gACRSelectedProfiles) and gACRSelectedProfiles[Player.job])
				if uiAlert == "skip" then
					local child_color = { r = 1, g = .90, b = .33, a = .0 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##skip-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text(GetString("Skip"))
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Recipie Set to Skip.")) end
				elseif uiAlert == "skillprofile" and not acrValid then
					local child_color = { r = 1, g = .90, b = .33, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##skillprofile-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text(GetString("Skill"))
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("No Skill Profile Set.")) end
				elseif uiAlert == "lowmats" then
					local child_color = { r = .95, g = .69, b = .2, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##lowmats-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text(GetString("Mats"))
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Full Order not craftable. Will craft partial order.")) end
				elseif uiAlert == "lowcp" then
					local child_color = { r = .95, g = .69, b = .2, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##lowcp-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text(GetString("CP"))
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Not Craftable. CP Below Task Requirement.")) end
				elseif uiAlert == "cantCraft" then
					local child_color = { r = .50, g = 0.05, b = .2, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##cantCraft-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text(GetString("Alert"))
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Not Craftable. May be missing materials or level to low.")) end
				elseif uiAlert == "canCraft" then
					local child_color = { r = .02, g = .79, b = .24, a = .75 }
					GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
					GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
					GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
					GUI:BeginChild("##canCraft-"..tostring(id),50,20,true)
					GUI:AlignFirstTextHeightToWidgets()
					GUI:Text(GetString("OK"))
					GUI:EndChild()
					GUI:PopStyleColor()
					GUI:PopStyleVar()
					GUI:PopStyleVar()
					if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Craftable.")) end
				end
						
				GUI:PopStyleColor(2)
				GUI:NextColumn()
			end
		end
		GUI:Columns(1)
	end
	
	
	-- Crafting Settings
	if (tabname == GetString("Settings")) then
		
		GUI:Separator()
		-- Label Column
		GUI:Columns(2)
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use Exp Manuals"))		
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow use of Experience boost manuals.")) end
		GUI:NextColumn()
		GUI_Capture(GUI:Checkbox("##"..GetString("Use Exp Manuals"),gUseExpManuals),"gUseExpManuals")
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow use of Experience boost manuals.")) end
		GUI:Columns()
		
		GUI:Separator()
		GUI:Columns(2)		
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use Tea Type"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow use of Tea Boosts.")) end
		GUI:NextColumn()
		if (gTeaSelection ~= gCraftTeaList) then
			gCraftTeaList = gTeaSelection
		end
		GUI_Combo("##tea", "gCraftTeaTypeIndex", "gCraftTeaList", gTeaSelection)
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow use of CP boost Tea.")) end
		GUI:Columns()
		
		GUI:Separator()
		GUI:Columns(2)		
		
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Current Active Food"))
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Food"))
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Show Usable Only"))
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Extract Materia"))
		GUI:NextColumn()
		
		-- Data column
		local CraftStatusWidth = GUI:GetContentRegionAvail()
		GUI:PushItemWidth(CraftStatusWidth-8)
			
		GUI:InputText("##Current Active Food",gCraftFood,GUI.InputTextFlags_ReadOnly)
		GUI_Combo("##food", "gCraftFoodIndex", "gCraftFood", gFoods)
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip(GetString("This option will override any Profile food choice."))
		end
		GUI_Capture(GUI:Checkbox("##Show Usable Onlyfood",gFoodAvailableOnly),"gFoodAvailableOnly");
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip(GetString("If this option is on, only available items will be shown."))
		end
		GUI:SameLine(0,5)

		
		local buttonBG = GUI:GetStyle().colors[GUI.Col_Button]
		GUI:PushStyleColor(GUI.Col_Button, buttonBG[1], buttonBG[2], buttonBG[3], 1)
		GUI:PushStyleColor(GUI.Col_ButtonActive, buttonBG[1], buttonBG[2], buttonBG[3], 1)
		if (GUI:ImageButton("##craft-food-refresh",ml_global_information.path.."\\GUI\\UI_Textures\\change.png", 14, 14)) then
			ffxivminion.FillFoodOptions(gFoodAvailableOnly)
		end
		GUI:PopStyleColor(2)

		GUI_Capture(GUI:Checkbox("##extractmateria", gextractmateria), "gextractmateria")
		if (GUI:IsItemHovered()) then
			GUI:SetTooltip("Extract materia from spiritbonded equipment")
		end
		
		
		GUI:Columns()
		

		
		if gCraftMarkerOrProfileIndex ~= 1 then
			GUI:Columns(2)
			GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Collectable"))
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Enable Collectable Synthesis")) end
			GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Craft Attempts"))
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("How many crafts to complete, (or fail) before stopping.")) end
			GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Minimum CP"))
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("CP required before starting the craft. (Useful for CP food)")) end
			GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use HQ Mats"))
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow the use of HQ materials while crafting.")) end
			if gCraftUseHQ then
				GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Only If Necessary"))
				if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Only use HQ materials if there are no NQ materials left.")) end
			end
			GUI:NextColumn()
			local CraftStatusWidth2 = GUI:GetContentRegionAvail()
			GUI:PushItemWidth(CraftStatusWidth2-8)
			GUI_Capture(GUI:Checkbox("##Collectable",gCraftCollectable),"gCraftCollectable")
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Enable Collectable Synthesis")) end
			GUI_Capture(GUI:InputInt("##"..GetString("Craft Amount"),gCraftMaxItems,0,0),"gCraftMaxItems")
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("How many crafts to complete before stopping.")) end
			GUI_Capture(GUI:InputInt("##"..GetString("Minimum CP"),gCraftMinCP,0,0),"gCraftMinCP")
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("CP required before starting the craft. (Useful for CP food)")) end
			GUI_Capture(GUI:Checkbox("##"..GetString("Use HQ Mats"),gCraftUseHQ),"gCraftUseHQ")
			if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Allow the use of HQ materials while crafting.")) end
			if gCraftUseHQ then
				GUI_Capture(GUI:Checkbox("##"..GetString("Only If Necessary"),gCraftUseHQBackup),"gCraftUseHQBackup")
				if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Only use HQ materials if there are no NQ materials left.")) end
			end	
			GUI:PopItemWidth()
			GUI:Columns()
		end
		GUI:Separator()
	end
	-- Collectable Table
	if (tabname == GetString("Collectable")) then
		local CollectableFullWidth = GUI:GetContentRegionAvail()-8
		if (GUI:Button(GetString("Use Known Defaults"),CollectableFullWidth,20)) then
			gCraftCollectablePresets = {}
			FFXIVLib.API.Items.UpdateCollectablePresets() -- Updates all basic class items, region specific.
			Settings.FFXIVMINION.gCraftCollectablePresets = gCraftCollectablePresets
		end
		if (GUI:Button(GetString("Add Collectable"),CollectableFullWidth,20)) then
			local newCollectable = { name = "", value = 0 }
			table.insert(gCraftCollectablePresets,newCollectable)
			GUI_Set("gCraftCollectablePresets",gCraftCollectablePresets)
		end
		
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Add a new Collectable to the list below.")) end
		GUI:Columns(2)
		local CollectableWidth1 = GUI:GetContentRegionAvail()
		GUI:Text(GetString("Item Name"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Case-sensitive item name for the item to become a collectable.")) end
		GUI:NextColumn()
		local CollectableWidth2 = GUI:GetContentRegionAvail()
		GUI:Text(GetString("Minimum Value"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Minimum Value for Item")) end
		GUI:Columns()
		GUI:Separator()
		if (table.valid(gCraftCollectablePresets)) then
		GUI:Columns(2)
			for i,collectable in pairsByKeys(gCraftCollectablePresets) do
				GUI:PushItemWidth(CollectableWidth1-8)
				local newName = GUI:InputText("##craft-collectablepair-name"..tostring(i),collectable.name)
				if (newName ~= collectable.name) then
					local newValue = gCraftCollectablePresets[i].value
					local newIndex = IsNull(FFXIVLib.API.Items.GetIDByName(newName),i)
					if newIndex ~= i then
						gCraftCollectablePresets[i] = nil
					end
					gCraftCollectablePresets[newIndex] = { name = newName, value = newValue }
					GUI_Set("gCraftCollectablePresets",gCraftCollectablePresets)
				end
				if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Case-sensitive item name for the item to become a collectable.")) end
				GUI:PopItemWidth()
				GUI:NextColumn()
				GUI:PushItemWidth(CollectableWidth2-28)
				local newValue = GUI:InputInt("##craft-collectablepair-value"..tostring(i),collectable.value,0,0)
				if (newValue ~= collectable.value) then
					gCraftCollectablePresets[i].value = newValue
					GUI_Set("gCraftCollectablePresets",gCraftCollectablePresets)
				end
				if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Minimum Value for Item")) end
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
				GUI:NextColumn()
			end
		GUI:Columns()
		end
	end
	if (tabname == GetString("Debug")) then
		GUI:Columns(2)
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Craft Debug"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Enable Debug messages in console.")) end
		GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Debug Level"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Change the Debug message level. (The higher the number the more detailed the messages)")) end
		GUI:NextColumn()
		local CraftStatusWidth = GUI:GetContentRegionAvail()
		GUI:PushItemWidth(CraftStatusWidth-8)
		GUI_Capture(GUI:Checkbox("##"..GetString("Craft Debug"),gCraftDebug),"gCraftDebug")
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Enable Debug messages in console.")) end
		
		local debugLevels = { 1, 2, 3}
		gCraftDebugLevelIndex = GetKeyByValue(gCraftDebugLevel,debugLevels) or 1
		if (debugLevels[gCraftDebugLevelIndex] ~= gCraftDebugLevel) then
			gCraftDebugLevel = debugLevels[gCraftDebugLevelIndex]
		end
		GUI_Combo("##Debug Level", "gCraftDebugLevelIndex", "gCraftDebugLevel", debugLevels)
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Change the Debug message level. (The higher the number the more detailed the messages)")) end
		
		GUI:PopItemWidth()
		GUI:Columns()
	end
end

function ffxiv_craft.IsCrafting()
	return (IsControlOpen("Synthesis") or IsControlOpen("SynthesisSimple"))
end

function ffxiv_craft.ToggleCraftingLog()
	if (IsControlOpen("RecipeNote")) then
		if (UseControlAction("RecipeNote","Close")) then
			ml_global_information.Await(1000, 3000, function () return (not IsControlOpen("RecipeNote") and not MIsLocked()) end)
			return true
		end
	else
		local logOpen = ActionList:Get(10,9)
		if (logOpen and logOpen.usable) then
			logOpen:Cast(Player.id)
			ml_global_information.Await(1000, 3000, function () return IsControlOpen("RecipeNote") end)
			return true
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
	
	if (table.valid(info)) then
		if (strName ~= "") then
			persistence.store(ffxiv_craft.profilePath..strName..".lua",info)
		else
			persistence.store(ffxiv_craft.profilePath..gCraftProfile..".lua",info)
		end
	else
		d("[Craft]: Orders table was invalid.")
	end
	
	ffxiv_craft.profiles, ffxiv_craft.profilesDisplay = GetPublicProfiles(ffxiv_craft.profilePath,".*lua")
end

function ffxiv_craft.CreateNewProfile()
	if (ValidString(gCraftNewProfileName)) then
		d("Creating new profile ["..tostring(gCraftNewProfileName).."].")
		ffxiv_craft.SaveProfile(gCraftNewProfileName)
		ffxiv_craft.profiles, ffxiv_craft.profilesDisplay = GetPublicProfiles(ffxiv_craft.profilePath,".*lua")
	end
end

function ffxiv_craft.AddToProfile()
	local recipeid = tonumber(gCraftOrderAddRecipeID) or 0
	if not ffxiv_craft.orders then
		ffxiv_craft.orders = {}
	end
	if (recipeid ~= 0) then
		local orders = ffxiv_craft.orders
		local recipeDetails = FFXIVLib.API.Items.GetRecipeDetails(recipeid)
		local thisOrder = { 	
			id = recipeid, 
			item = recipeDetails.id, 
			name = recipeDetails.name, 
			level = recipeDetails.attemptlevel,
			class = recipeDetails.class, 
			page = recipeDetails.page,
			amount = gCraftOrderAddAmount, 
			usequick = gCraftOrderAddQuick, 
			collect = gCraftOrderAddCollect, 
			usehq = gCraftOrderAddHQ, 
			ifnecessary = gCraftOrderAddIfNecessary,
			skillprofile = gCraftOrderAddSkillProfile,
			requirehq = gCraftOrderAddRequireHQ, 
			requiredcp = gCraftOrderAddRequireCP, 
			counthq = gCraftOrderAddCountHQ,
			skip = false,
			completed = false,
		}
		
		for i = 1,6 do
			thisOrder["hq"..tostring(i).."max"] = IsNull(_G["gCraftOrderAddHQIngredient"..tostring(i).."Max"],false)
			thisOrder["hq"..tostring(i).."min"] = IsNull(_G["gCraftOrderAddHQIngredient"..tostring(i).."Min"],0)
			thisOrder["hq"..tostring(i)] = IsNull(_G["gCraftOrderAddHQIngredient"..tostring(i)],0)
		end
		
		table.insert(ffxiv_craft.orders,thisOrder)
		ffxiv_craft.SaveProfile()
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
			ffxiv_craft.orders[key] = nil
		else
			ffxiv_craft.orders = {}
		end
		ffxiv_craft.SaveProfile()
	end
end
	
function ffxiv_craft.UpdateAlertElement()
	if (ffxiv_craft.IsCrafting() or (gBotMode == GetString("craftMode") and gCraftMarkerOrProfileIndex ~= 1) or 
		gBotMode ~= GetString("craftMode") or 
		(Now() < ffxiv_craft.tracking.measurementDelay))
	then
		return false
	end
	
	if (ffxiv_craft.UsingProfile() and gCraftMarkerOrProfileIndex == 1) then
		local playercp = Player.cp.max
		local orders = ffxiv_craft.orders
		local foundSelection = false
		if (table.valid(orders)) then
		
			local getcounts = {}
			for id,order in pairs(orders) do
				local itemid = order.item
				getcounts[itemid] = true
				getcounts[itemid + 1000000] = true
				getcounts[itemid + 500000] = true
			end
			
			local getcountsorted = {}
			for itemid,_ in pairs(getcounts) do
				table.insert(getcountsorted,itemid)
			end
			
			ffxiv_craft.itemCounts = ItemCounts(getcountsorted)
			local itemcounts = ffxiv_craft.itemCounts
			
			for id,order in pairs(orders) do
			
				if order["uialert"] == nil then
					order["uialert"] = "None"
				end
				if order["itemcount"] == nil then
					order["itemcount"] = 0
				end
				if order["itemcountnorm"] == nil then
					order["itemcountnorm"] = 0
				end
				if order["itemcounthq"] == nil then
					order["itemcounthq"] = 0
				end
				if order["itemcountcollectable"] == nil then
					order["itemcountcollectable"] = 0
				end
				if order["skillprofile"] == nil then
					order["skillprofile"] = GetString("none")
				end
				if order["requiredcp"] == nil then
					order["requiredcp"] = 0
				end
				if order["collect"] == nil then
					order["collect"] = false
				end
				if order["maxcount"] == nil then
					order["maxcount"] = 0
				end
				if order["ifnecessary"] == nil then
					order["ifnecessary"] = false
				end
					
				local canCraft,maxAmount,yield = FFXIVLib.API.Items.CanCraft(order.id,order["usehq"])

				if order["maxcount"] ~= maxAmount then
					order["maxcount"]= maxAmount
				end
				local lowMats = false
				if order.amount ~= 0 then
					if maxAmount > 0 then
						if (maxAmount * yield) < order.amount then
							lowMats = true
						end
					end
				end
					
				local okCP = (order["requiredcp"] ~= nil and (playercp >= order["requiredcp"])) or (order["usequick"] == true)
				if order["skip"] == true then
					order["uialert"] = "skip"
				elseif (order["skillprofile"] == "None") and (order["usequick"] == false) then
					order["uialert"] = "skillprofile"
				elseif not okCP then
					order["uialert"] = "lowcp"
				elseif lowMats then
					order["uialert"] = "lowmats"
				elseif maxAmount == 0 then
					order["uialert"] = "cantCraft"
				elseif maxAmount > 0 then
					order["uialert"] = "canCraft"
				end
				
				local itemid = order.item
				
				local itemcountnorm = IsNull(itemcounts[itemid].count,0)
				local itemcountHQ = IsNull(itemcounts[itemid + 1000000].count,0)
				local itemcountCollectable = IsNull(itemcounts[itemid + 500000].count,0)
				if In(ffxivminion.gameRegion,1) then
					itemcountnorm = itemcountnorm + itemcountCollectable
					itemcountCollectable = 0
				end
				local itemcount = itemcountnorm + itemcountHQ + itemcountCollectable
				
				if order["itemcount"] ~= itemcount then
					order["itemcount"]= itemcount
				end
				if order["itemcountnorm"] ~= itemcountnorm then
					order["itemcountnorm"]= itemcountnorm
				end
				if order["itemcounthq"] ~= itemcountHQ then
					order["itemcounthq"]= itemcountHQ
				end
				if order["itemcountcollectable"] ~= itemcountCollectable then
					order["itemcountcollectable"]= itemcountCollectable
				end
			end
		end
		--ffxiv_craft.SaveProfile()
		ffxiv_craft.tracking.measurementDelay = Now() + 1000
	end
end	

function ffxiv_craft.UpdateOrderElement()
	local key = tonumber(gCraftOrderEditID) or 0
	local orders = ffxiv_craft.orders
	if (table.valid(orders)) then
		local thisOrder = orders[key]
		if (thisOrder) then
			thisOrder["amount"] = gCraftOrderEditAmount
			thisOrder["requiredcp"] = gCraftOrderEditRequiredCP
			thisOrder["requirehq"] = gCraftOrderEditRequireHQ
			thisOrder["counthq"] = gCraftOrderEditCountHQ
			thisOrder["usequick"] = gCraftOrderEditQuick
			thisOrder["collect"] = gCraftOrderEditCollect
			thisOrder["usehq"] = gCraftOrderEditHQ
			thisOrder["ifnecessary"] = gCraftOrderEditIfNecessary
			thisOrder["skillprofile"] = IsNull(gCraftOrderEditSkillProfile,GetString("none"))
			
			for i = 1,6 do
				thisOrder["hq"..tostring(i).."max"] = IsNull(_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"],false)
				thisOrder["hq"..tostring(i).."min"] = IsNull(_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"],0)
				thisOrder["hq"..tostring(i)] = IsNull(_G["gCraftOrderEditHQIngredient"..tostring(i)],0)
			end
			
			ffxiv_craft.SaveProfile()
			ffxiv_craft.tracking.measurementDelay = Now()
		end
	end
end

function ffxiv_craft.InspectRecipe(key)
	local key = tonumber(key) or 0
	local recipeDetails = FFXIVLib.API.Items.GetRecipeDetails(key)
	gCraftInspectProgress = recipeDetails.progress or ""
	gCraftInspectDurability = recipeDetails.durability or ""
	gCraftInspectCraftsmanship = recipeDetails.craftsmanship or ""
	gCraftInspectControl = recipeDetails.control or ""
	gCraftInspectREquip = IIF(recipeDetails.requiredequip ~= 0,IsNull(recipeDetails.requipname,"").."["..IsNull(recipeDetails.requiredequip,"").."]","")
	gCraftInspectCrystal1 = IIF(recipeDetails.crystal1 ~= 0,IsNull(recipeDetails.c1name,"").."["..IsNull(recipeDetails.crystal1,"").."]","")
	gCraftInspectCAmount1 = IIF(recipeDetails.crystal1 ~= 0,tostring(IsNull(recipeDetails.camount1,0)).."("..IsNull(ItemCount(recipeDetails.crystal1,{2001 },true),0)..")","")
	gCraftInspectCrystal2 = IIF(recipeDetails.crystal2 ~= 0,IsNull(recipeDetails.c2name,"").."["..IsNull(recipeDetails.crystal2,"").."]","")
	gCraftInspectCAmount2 = IIF(recipeDetails.crystal2 ~= 0,tostring(IsNull(recipeDetails.camount2,0)).."("..IsNull(ItemCount(recipeDetails.crystal2,{2001 },true),0)..")","")
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

	local canCraft,maxAmount = FFXIVLib.API.Items.CanCraft(key)
	gCraftInspectCanCraft = tostring(canCraft)
	gCraftInspectCraftable = maxAmount
	
	GUI:Columns(2, "##craft-recipe-inspection", true)
	GUI:SetColumnOffset(1, 200); GUI:SetColumnOffset(2, 400)
	GUI:Text(GetString("Can Craft")); GUI:NextColumn(); GUI:Text(gCraftInspectCanCraft); GUI:NextColumn();
	GUI:Text(GetString("Amount Craftable")); GUI:NextColumn(); GUI:Text(gCraftInspectCraftable); GUI:NextColumn();
	
	GUI:Text(GetString("Progress")); GUI:NextColumn(); GUI:Text(gCraftInspectProgress); GUI:NextColumn();
	GUI:Text(GetString("Durability")); GUI:NextColumn(); GUI:Text(gCraftInspectDurability); GUI:NextColumn();
	GUI:Text(GetString("Craftsmanship")); GUI:NextColumn(); GUI:Text(gCraftInspectCraftsmanship); GUI:NextColumn();
	GUI:Text(GetString("Control")); GUI:NextColumn(); GUI:Text(gCraftInspectControl); GUI:NextColumn();
	GUI:Text(GetString("Equipment")); GUI:NextColumn(); GUI:Text(gCraftInspectREquip); GUI:NextColumn();
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
	local maxattemptlevel = IsNull(maxattemptlevel,5)
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
			
		local recipes,dictionary = FFXIVLib.API.Items.BuildRecipeString(craftid,0,(maxattemptlevel-4),maxattemptlevel)
		if (dictionary) then
			if (not ffxiv_craft.dictionaries[craftid] or not ffxiv_craft.dictionariesDisplay[craftid]) then
				ffxiv_craft.dictionaries[craftid] = {}
				ffxiv_craft.dictionariesDisplay[craftid] = {}
			end
			ffxiv_craft.dictionaries[craftid][maxattemptlevel] = {}
			ffxiv_craft.dictionariesDisplay[craftid][maxattemptlevel]  = {}
			
			local newDictionary = { [1] = {recipeid = 0, itemid = 0, name = GetString("none")} }
			local newDisplayDictionary = { [1] = GetString("none") }
			
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
				string.contains(tostring(k),"gGearset"))				
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
		
		local winBG = GUI:GetStyle().colors[GUI.Col_WindowBg]
		GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], .75)
		
		ffxiv_task_craft.GUI.orders.visible, ffxiv_task_craft.GUI.orders.open = GUI:Begin(ffxiv_task_craft.GUI.orders.name, ffxiv_task_craft.GUI.orders.open)
		if ( ffxiv_task_craft.GUI.orders.visible ) then 
		
			GUI_DrawTabs(ffxiv_task_craft.GUI.orders.main_tabs)
			local tabs = ffxiv_task_craft.GUI.orders.main_tabs
			
			if (tabs.tabs[1].isselected) then
				ffxiv_craft.UpdateAlertElement()
				
				local width, height = GUI:GetWindowSize()		
				local cwidth, cheight = GUI:GetContentRegionAvail()
				
				local orders = ffxiv_craft.orders
				if (table.valid(orders)) then
					
					GUI:Separator();
					GUI:Columns(7, "#craft-manage-orders", true)
					GUI:SetColumnOffset(1, 125); GUI:SetColumnOffset(2, 225); GUI:SetColumnOffset(3, 300); GUI:SetColumnOffset(4, 340); GUI:SetColumnOffset(5, 380); GUI:SetColumnOffset(6, 440);  GUI:SetColumnOffset(7, 650);	 			
					GUI:Text(GetString("Item")); GUI:NextColumn();
					GUI:Text(GetString("Recipe")); GUI:NextColumn();
					GUI:Text(GetString("Amount")); GUI:NextColumn();
					GUI:Text(GetString("Skip")); GUI:NextColumn();
					GUI:Text(GetString("Edit")); GUI:NextColumn();
					GUI:Text(GetString("Remove")); GUI:NextColumn();
					GUI:Text(GetString("Alert")); GUI:NextColumn();
					GUI:Separator();
										
					for id,order in spairs(orders) do
						local collectable = order.collect and In(ffxivminion.gameRegion,2,3)
						if (collectable) then
							if gCraftCollectablePresets[order.item] then
								GUI:TextColored(.1,1,.2,1,"(C) " .. tostring(order.name))
								if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Has Collectable Info")) end
							else
								GUI:TextColored(1,.1,.2,1,"(C) " .. tostring(order.name))
								if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Collectable Info Missing")) end
							end
						else
							GUI:AlignFirstTextHeightToWidgets(); GUI:Text(order.name);
						end
						GUI:NextColumn()
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(order.id); GUI:NextColumn()
						GUI:AlignFirstTextHeightToWidgets(); GUI:Text(order.amount); GUI:NextColumn()
						
						if (order.skip == nil) then
							orders[id].skip = false
							ffxiv_craft.SaveProfile()
						end						
						
						gCraftOrderEditSkip = IsNull(order.skip,false)
						local newVal, changed = GUI:Checkbox("##skip-"..tostring(id),gCraftOrderEditSkip)
						if (changed) then
							orders[id].skip = newVal
							if orders[id].skip == true then
								orders[id].uialert = "skip"
							end
						end
						
						GUI:NextColumn()
						
						GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
						--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
						GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
						
						if (GUI:ImageButton("##craft-manage-edit"..tostring(id),ml_global_information.path.."\\GUI\\UI_Textures\\w_edit.png", 16, 16)) then
							gCraftOrderEditID = id
							gCraftOrderEditRecipeID = order.id
							
							gCraftOrderEditAmount = IsNull(order["amount"],0)
							gCraftOrderEditCollect = IsNull(order["collect"],false)
							gCraftOrderEditRequiredCP = IsNull(order["requiredcp"],0)
							gCraftOrderEditRequireHQ = IsNull(order["requirehq"],false)
							gCraftOrderEditCountHQ = IsNull(order["counthq"],true)
							if gCraftOrderEditCollect == true then
								gCraftOrderEditQuick = false
							else
								gCraftOrderEditQuick = IsNull(order["usequick"],false)
							end
							gCraftOrderEditHQ = IsNull(order["usehq"],false)
							gCraftOrderEditIfNecessary = IsNull(order["ifnecessary"],false)
							gCraftOrderEditSkillProfile = IsNull(order["skillprofile"],GetString("none"))
							gCraftOrderEditSkillProfileIndex = GetKeyByValue(gCraftOrderEditSkillProfile,SkillMgr.profiles)

							for i = 1,6 do
								if (not order["hq"..tostring(i)]) then
									_G["gCraftOrderEditHQIngredient"..tostring(i)] = 0
									_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"] = 0
									_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = false
									ffxiv_craft.UpdateOrderElement()
								else
									_G["gCraftOrderEditHQIngredient"..tostring(i)] = IsNull(order["hq"..tostring(i)],0)
									_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"] = IsNull(order["hq"..tostring(i).."min"],0)
									_G["gCraftOrderEditHQIngredient"..tostring(i).."Max"] = IsNull(order["hq"..tostring(i).."max"],false)
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
						GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
						--GUI:PushStyleColor(GUI.Col_ButtonHovered, 0, 0, 0, 0)
						GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
						local gACREnabledCraft = false					
						if (IsGatherer(Player.job)) then
							if (ggACREnabledCraftGather) then
								gACREnabledCraft = true
							end
						elseif (IsCrafter(Player.job)) then
							if (ggACREnabledCraftCraft) then
								gACREnabledCraft = true
							end
						elseif (IsFighter(Player.job)) then
							if (ggACREnabledCraft) then
								gACREnabledCraft = true
							end
						end
						local acrValid = (gACREnabledCraft and table.valid(gACRSelectedProfiles) and gACRSelectedProfiles[Player.job])
						local uiAlert = IsNull(order["uialert"],GetString("skillprofile"))
						if uiAlert == "skip" then
							local child_color = { r = 1, g = .90, b = .33, a = .0 }
							GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
							GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
							GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
							GUI:BeginChild("##skip-"..tostring(id),50,20,true)
							GUI:AlignFirstTextHeightToWidgets()
							GUI:Text(GetString("Skip"))
							GUI:EndChild()
							GUI:PopStyleColor()
							GUI:PopStyleVar()
							GUI:PopStyleVar()
							if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Recipie Set to Skip.")) end
						elseif uiAlert == "skillprofile" and not acrValid then
							local child_color = { r = 1, g = .90, b = .33, a = .75 }
							GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
							GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
							GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
							GUI:BeginChild("##skillprofile-"..tostring(id),50,20,true)
							GUI:AlignFirstTextHeightToWidgets()
							GUI:Text(GetString("Skill"))
							GUI:EndChild()
							GUI:PopStyleColor()
							GUI:PopStyleVar()
							GUI:PopStyleVar()
							if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("No Skill Profile Set.")) end
						elseif uiAlert == "lowmats" then
							local child_color = { r = .95, g = .69, b = .2, a = .75 }
							GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
							GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
							GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
							GUI:BeginChild("##lowmats-"..tostring(id),50,20,true)
							GUI:AlignFirstTextHeightToWidgets()
							GUI:Text(GetString("Mats"))
							GUI:EndChild()
							GUI:PopStyleColor()
							GUI:PopStyleVar()
							GUI:PopStyleVar()
							if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Full Order not craftable. Will craft partial order.")) end
						elseif uiAlert == "lowcp" then
							local child_color = { r = .95, g = .69, b = .2, a = .75 }
							GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
							GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
							GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
							GUI:BeginChild("##lowcp-"..tostring(id),50,20,true)
							GUI:AlignFirstTextHeightToWidgets()
							GUI:Text(GetString("CP"))
							GUI:EndChild()
							GUI:PopStyleColor()
							GUI:PopStyleVar()
							GUI:PopStyleVar()
							if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Not Craftable. CP Below Task Requirement.")) end
						elseif uiAlert == "cantCraft" then
							local child_color = { r = .50, g = 0.05, b = .2, a = .75 }
							GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
							GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
							GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
							GUI:BeginChild("##cantCraft-"..tostring(id),50,20,true)
							GUI:AlignFirstTextHeightToWidgets()
							GUI:Text(GetString("Alert"))
							GUI:EndChild()
							GUI:PopStyleColor()
							GUI:PopStyleVar()
							GUI:PopStyleVar()
							if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Not Craftable. May be missing materials or level to low.")) end
						elseif uiAlert == "canCraft" then
							local child_color = { r = .02, g = .79, b = .24, a = .75 }
							GUI:PushStyleVar(GUI.StyleVar_ChildWindowRounding,1)
							GUI:PushStyleVar(GUI.StyleVar_WindowPadding,6,0)
							GUI:PushStyleColor(GUI.Col_ChildWindowBg, child_color.r, child_color.g, child_color.b, child_color.a)
							GUI:BeginChild("##canCraft-"..tostring(id),50,20,true)
							GUI:AlignFirstTextHeightToWidgets()
							GUI:Text(GetString("OK"))
							GUI:EndChild()
							GUI:PopStyleColor()
							GUI:PopStyleVar()
							GUI:PopStyleVar()
							if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Craftable.")) end
						end
							
						GUI:PopStyleColor(2)
						GUI:NextColumn()
					end
					
					GUI:Columns(1)
				end
			end
			
			if (tabs.tabs[2].isselected) then	
				GUI:PushItemWidth(60)
				GUI_Combo("Class", "gCraftOrderSelectIndex", "gCraftOrderSelect", gCrafts)
				GUI:PopItemWidth()
				
				for k = 5,100,5 do
					local dictionary, dictionaryDisplay = ffxiv_craft.GetDictionary(k)
					if (dictionary and dictionaryDisplay) then
						--d("found dictionary for k = "..tostring(k))
						GUI:PushItemWidth(300)
						local selectionChanged = GUI_Combo(tostring(k-4).."-"..tostring(k), "gCraftDictionarySelectIndex"..tostring(k), "gCraftDictionarySelect"..tostring(k), dictionaryDisplay)
						if (selectionChanged) then
							local thisRecipe = dictionary[_G["gCraftDictionarySelectIndex"..tostring(k)]]
							if (thisRecipe) then
								gCraftOrderAddID = thisRecipe.recipeid
								gCraftOrderAddRecipeID = thisRecipe.recipeid
								if not gCraftDictionarySelectKeepSettings then
									gCraftOrderAddAmount = 1
									gCraftOrderAddCollect = false
									gCraftOrderAddRequireHQ = false
									gCraftOrderAddRequireCP = 0
									gCraftOrderAddCountHQ = true
									gCraftOrderAddQuick = false
									gCraftOrderAddHQ = false
									gCraftOrderAddIfNecessary = false
									gCraftOrderAddSkillProfileIndex = 1
									gCraftOrderAddSkillProfile = GetString("none")
								end
							end
							for j = 5,100,5 do
								if (j ~= k) then
									_G["gCraftDictionarySelectIndex"..tostring(j)] = 1
									_G["gCraftDictionarySelect"..tostring(j)] = GetString("none")		
								end
							end
						end
						GUI:PopItemWidth()
					else
						GUI:Text(GetString("Could not find display dictionary for [")..gCraftOrderSelect.."] with attempt level ["..tostring(k).."]")
					end					
				end
				if (gCraftOrderAddRecipeID ~= 0) then
					local gACREnabledCraft = false					
					if (IsGatherer(Player.job)) then
						if (ggACREnabledCraftGather) then
							gACREnabledCraft = true
						end
					elseif (IsCrafter(Player.job)) then
						if (ggACREnabledCraftCraft) then
							gACREnabledCraft = true
						end
					elseif (IsFighter(Player.job)) then
						if (ggACREnabledCraft) then
							gACREnabledCraft = true
						end
					end
					local acrValid = (gACREnabledCraft and table.valid(gACRSelectedProfiles) and gACRSelectedProfiles[Player.job])
					
					GUI:Separator()
				
					GUI:Columns(2)
					
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Amount to Craft")); 
					if (In(ffxivminion.gameRegion,2,3)) then
						GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use Collect")); 
					end
					if (not gCraftOrderAddQuick) and not acrValid then
						GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Skill Profile")); 
					end
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Required CP")); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Require HQ")); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Count HQ")); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use QuickSynth")); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use HQ Items")); 
					if gCraftOrderAddHQ then
						GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Only If Necessary")); 
					end
					GUI:NextColumn()
					
					GUI:PushItemWidth(250)
					GUI_Capture(GUI:InputInt("##Amount to Craft",gCraftOrderAddAmount,0,0),"gCraftOrderAddAmount")
					GUI:PopItemWidth()
					if (In(ffxivminion.gameRegion,2,3)) then
						GUI_Capture(GUI:Checkbox("##Use Collect",gCraftOrderAddCollect),"gCraftOrderAddCollect")
					end
					if (not gCraftOrderAddQuick) and not acrValid then
						GUI:PushItemWidth(250)
						
						gCraftOrderAddSkillProfileIndex = IsNull(GetKeyByValue(gCraftOrderAddSkillProfile,SkillMgr.profiles),1)
						GUI_Combo(GetString("##skillProfile1"), "gCraftOrderAddSkillProfileIndex", "gCraftOrderAddSkillProfile", SkillMgr.profiles)
						
						
						GUI:PopItemWidth()
					end
					
					GUI:PushItemWidth(250)
					GUI_Capture(GUI:InputInt("##RequiredCP",gCraftOrderAddRequireCP,0,0),"gCraftOrderAddRequireCP")
					GUI_Capture(GUI:Checkbox("##Require HQ",gCraftOrderAddRequireHQ),"gCraftOrderAddRequireHQ")
					GUI_Capture(GUI:Checkbox("##Count HQ",gCraftOrderAddCountHQ),"gCraftOrderAddCountHQ")
					if gCraftOrderAddCollect then 
						gCraftOrderAddQuick = false
					end
					GUI_Capture(GUI:Checkbox("##Use QuickSynth",gCraftOrderAddQuick),"gCraftOrderAddQuick")
					GUI_Capture(GUI:Checkbox("##Use HQ Items",gCraftOrderAddHQ),"gCraftOrderAddHQ")
					GUI:PopItemWidth()
					if (gCraftOrderAddHQ) then						
						
						GUI_Capture(GUI:Checkbox("##AddIfNecessary",gCraftOrderAddIfNecessary),"gCraftOrderAddIfNecessary")
						if (GUI:IsItemHovered()) then
							GUI:SetTooltip(GetString("Only use HQ materials if there are no NQ materials left."))
						end
					end	
					
					GUI:Columns()
					if (gCraftOrderAddHQ) and not gCraftOrderAddIfNecessary then	
						local recipeDetails = FFXIVLib.API.Items.GetRecipeDetails(gCraftOrderAddRecipeID)
						if (recipeDetails) then
							
							GUI:Columns(5, "#craft-add-hq", true)
							GUI:SetColumnOffset(1, 250); GUI:SetColumnOffset(2, 325); GUI:SetColumnOffset(3, 425); GUI:SetColumnOffset(4, 525);
							GUI:AlignFirstTextHeightToWidgets()
							
							GUI:Text(GetString("Ingredient")); GUI:NextColumn();
							GUI:Text(GetString("Required")); GUI:NextColumn();
							GUI:Text(GetString("Min HQ Amount")); GUI:NextColumn();
							GUI:Text(GetString("Max HQ Amount")); GUI:NextColumn();
							GUI:Text(GetString("Use All HQ")); GUI:NextColumn();
							
							GUI:Separator();
							
							for i = 1,6 do
								local ing = recipeDetails["ingredient"..tostring(i)]
								if (ing and ing ~= 0) then
									GUI:AlignFirstTextHeightToWidgets()
									GUI:Text(recipeDetails["ing"..tostring(i).."name"]); GUI:Dummy(); GUI:NextColumn();
									GUI:AlignFirstTextHeightToWidgets()
									GUI:Text(tostring(recipeDetails["iamount"..tostring(i)])); GUI:Dummy(); GUI:NextColumn();
									
									
									
									GUI:PushItemWidth(50)
									local newVal, changed = GUI:InputInt("##HQ MinAmount"..tostring(i),_G["gCraftOrderAddHQIngredient"..tostring(i).."Min"],0,0)
									if (changed) then
									
										if (newVal > recipeDetails["iamount"..tostring(i)]) then
											newVal = recipeDetails["iamount"..tostring(i)]
										ffxiv_craft.UpdateOrderElement()
										elseif (newVal < 0) then
											newVal = 0
										ffxiv_craft.UpdateOrderElement()
										end
											
										_G["gCraftOrderAddHQIngredient"..tostring(i).."Min"] = newVal
										ffxiv_craft.UpdateOrderElement()
									end
									if (GUI:IsItemHovered()) then
										GUI:SetTooltip(GetString("Minimum amount of HQ items to use for this item in the craft."))
									end
									GUI:PopItemWidth()
									GUI:NextColumn();
									
									GUI:PushItemWidth(50)
									local newVal, changed = GUI:InputInt("##HQ Amount"..tostring(i),_G["gCraftOrderAddHQIngredient"..tostring(i)],0,0)
									if (changed) then
									
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
									if (GUI:IsItemHovered()) then
										GUI:SetTooltip(GetString("Max amount of HQ items to use for this item in the craft."))
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
							GUI:Text(GetString("Could not find recipe details."))
						end					
					end
					
					GUI:Spacing()
					GUI:Separator()
					GUI:Spacing()
					local newVal, changed = GUI:Checkbox(GetString("Keep settings on change"),gCraftDictionarySelectKeepSettings)
					if (changed) then
						gCraftDictionarySelectKeepSettings = newVal
						Settings.FFXIVMINION.gCraftDictionarySelectKeepSettings = gCraftDictionarySelectKeepSettings
					end
					if (GUI:Button(GetString("Add to Profile"),250,20)) then
					
						d("Adding Recipe id ["..gCraftOrderAddRecipeID.."]")
						ffxiv_craft.AddToProfile()
						ffxiv_craft.tracking.measurementDelay = Now()
					end
				end
			end
			
			if (tabs.tabs[3].isselected) then
				if (ffxiv_craft.orders[gCraftOrderEditID] ~= nil) then
					local orders = ffxiv_craft.orders[gCraftOrderEditID]
					
					GUI:Columns(2)
					
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Amount to Craft")); 
					if (In(ffxivminion.gameRegion,2,3)) then
						GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use Collect"));  
					end
					local acrValid = (gACREnabledCraft and table.valid(gACRSelectedProfiles) and gACRSelectedProfiles[Player.job])
					if (not gCraftOrderEditQuick) and not acrValid then
						GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Skill Profile")); 
					end  
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Required CP"));   
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Require HQ"));  
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Count HQ"));  
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use QuickSynth")); 
					GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Use HQ Items"));  
					if (gCraftOrderEditHQ) then
						GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("Only If Necessary")); 
					end
					GUI:NextColumn()
					
					GUI:PushItemWidth(250)
					
							
					
					GUI_Capture(GUI:InputInt("##Amount to Craft",gCraftOrderEditAmount,0,0),"gCraftOrderEditAmount")
					GUI:PopItemWidth()
					if (orders.amount ~= gCraftOrderEditAmount) then
						orders.amount = gCraftOrderEditAmount
						ffxiv_craft.UpdateOrderElement()
					end
					if (In(ffxivminion.gameRegion,2,3)) then
						GUI_Capture(GUI:Checkbox("##Use Collect",gCraftOrderEditCollect),"gCraftOrderEditCollect")
					end
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip(GetString("Use Collect Synth Buff."))
					end 
					if In(ffxivminion.gameRegion,2,3) then
						if (orders.collect ~= gCraftOrderEditCollect) then
							orders.collect = gCraftOrderEditCollect
							ffxiv_craft.UpdateOrderElement()
						end
						if gCraftOrderEditCollect == true then
							gCraftOrderEditQuick = false
						end
					else
						orders.collect = false
					end
					
					if (not gCraftOrderEditQuick) and not acrValid then
					
						GUI:PushItemWidth(250)
						local checkvalue = GUI_Combo("##tea", "gCraftOrderEditSkillProfileIndex", "gCraftOrderEditSkillProfile", SkillMgr.profiles)
						if (checkvalue) then
							orders.skillprofile = gCraftOrderEditSkillProfile
							ffxiv_craft.SaveProfile()
						end
						GUI:PopItemWidth()
					end
					
					GUI_Capture(GUI:InputInt("##RequiredCP1",gCraftOrderEditRequiredCP,0,0),"gCraftOrderEditRequiredCP")
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip(GetString("Min Cp to craft Item."))
					end
					if (orders.requiredcp ~= gCraftOrderEditRequiredCP) then
						orders.requiredcp = gCraftOrderEditRequiredCP
						ffxiv_craft.UpdateOrderElement()
					end
					
					GUI_Capture(GUI:Checkbox("##RequireHQ2",gCraftOrderEditRequireHQ),"gCraftOrderEditRequireHQ")
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip(GetString("Only count if item Was HQ."))
					end
					if (orders.requirehq ~= gCraftOrderEditRequireHQ) then
						orders.requirehq = gCraftOrderEditRequireHQ
						ffxiv_craft.UpdateOrderElement()
					end
					
					
					GUI_Capture(GUI:Checkbox("##Count HQ",gCraftOrderEditCountHQ),"gCraftOrderEditCountHQ")
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip(GetString("Count if HQ and Normal items."))
					end
					if (orders.counthq ~= gCraftOrderEditCountHQ) then
						orders.counthq = gCraftOrderEditCountHQ
						ffxiv_craft.UpdateOrderElement()
					end
					GUI_Capture(GUI:Checkbox("##Use QuickSynth",gCraftOrderEditQuick),"gCraftOrderEditQuick")
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip(GetString("Quicksynth Items."))
					end
					if (orders.usequick ~= gCraftOrderEditQuick) then
						orders.usequick = gCraftOrderEditQuick
						ffxiv_craft.UpdateOrderElement()
					end
					
					GUI_Capture(GUI:Checkbox("##Use HQ Items",gCraftOrderEditHQ),"gCraftOrderEditHQ")
					if (GUI:IsItemHovered()) then
						GUI:SetTooltip(GetString("Use Hq materials. (Advanced)"))
					end
					if (orders.usehq ~= gCraftOrderEditHQ) then
						orders.usehq = gCraftOrderEditHQ
						ffxiv_craft.UpdateOrderElement()
					end
					
					if (gCraftOrderEditHQ) then
					
						GUI_Capture(GUI:Checkbox("##EditIfNecessary",gCraftOrderEditIfNecessary),"gCraftOrderEditIfNecessary")
						if 	(GUI:IsItemHovered()) then
							GUI:SetTooltip(GetString("Only use HQ materials if there are no NQ materials left."))
						end
						if (orders.ifnecessary ~= gCraftOrderEditIfNecessary) then
							orders.ifnecessary = gCraftOrderEditIfNecessary
							ffxiv_craft.UpdateOrderElement()
						end
					end
					
					GUI:Columns()
					if (gCraftOrderEditHQ) and not gCraftOrderEditIfNecessary then
						GUI:Separator()
						local recipeDetails = FFXIVLib.API.Items.GetRecipeDetails(gCraftOrderEditRecipeID)
						if (recipeDetails) then
							
							GUI:Columns(5, "#craft-edit-hq", true)
							GUI:SetColumnOffset(1, 250); GUI:SetColumnOffset(2, 325); GUI:SetColumnOffset(3, 425); GUI:SetColumnOffset(4, 525);
							GUI:AlignFirstTextHeightToWidgets()
							
							GUI:Text(GetString("Ingredient")); GUI:NextColumn();
							GUI:Text(GetString("Required")); GUI:NextColumn();
							GUI:Text(GetString("Min HQ Amount")); GUI:NextColumn();
							GUI:Text(GetString("Max HQ Amount")); GUI:NextColumn();
							GUI:Text(GetString("Use All HQ")); GUI:NextColumn();
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
									local newVal, changed = GUI:InputInt("##HQ MinAmount-"..tostring(i),_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"],0,0)
									if (changed) then
									
										if (newVal > recipeDetails["iamount"..tostring(i)]) then
											newVal = recipeDetails["iamount"..tostring(i)]
										elseif (newVal < 0) then
											newVal = 0
										end
										
										_G["gCraftOrderEditHQIngredient"..tostring(i).."Min"] = newVal
										ffxiv_craft.UpdateOrderElement()
									end
									if (GUI:IsItemHovered()) then
										GUI:SetTooltip(GetString("Minimum amount of HQ items to use for this item in the craft."))
									end
									GUI:PopItemWidth()
									GUI:NextColumn();
									
									GUI:PushItemWidth(50)
									GUI:AlignFirstTextHeightToWidgets()
									local newVal, changed = GUI:InputInt("##HQ Amount-"..tostring(i),_G["gCraftOrderEditHQIngredient"..tostring(i)],0,0)
									if (changed) then
									
										if (newVal ~= recipeDetails["iamount"..tostring(i)]) then
											recipeDetails["iamount"..tostring(i)] = newVal
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
									if (GUI:IsItemHovered()) then
										GUI:SetTooltip(GetString("Max amount of HQ items to use for this item in the craft."))
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
							GUI:Text(GetString("Could not find recipe details."))
						end					
					end
				end
			end
		end
		GUI:End()
	end
end

c_resetcraft = inheritsFrom( ml_cause )
e_resetcraft = inheritsFrom( ml_effect )
function c_resetcraft:evaluate()
	if ffxiv_craft.resetRecipe then
		if (IsControlOpen("RecipeNote")) then
			ffxiv_craft.ToggleCraftingLog()
			ffxiv_craft.resetRecipe = false
			return true
		end
	end
	return false
end

function e_resetcraft:execute()
end
RegisterEventHandler("Gameloop.Draw", ffxiv_craft.Draw, "ffxiv_craft.Draw")

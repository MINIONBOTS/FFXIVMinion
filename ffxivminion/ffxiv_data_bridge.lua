------------------------------------------------------------
-- FFXIVLib Data Bridge for ffxivminion
--
-- Nil-safe wrapper functions that sit between the ffxivminion
-- CNE system and FFXIVLib's async data access layer.
--
-- Every function here returns nil (or false) gracefully when
-- async data is not yet cached, allowing the CNE loop to
-- retry on the next tick with zero errors.
--
-- GC impact: Zero allocations. No closures. No temp tables.
-- All functions are plain global accessors.
------------------------------------------------------------

------------------------------------------------------------
-- Gate condition: Is FFXIVLib data ready?
--
-- Use as a CNE cause at priority 255 (highest) in any task
-- to block processing until pre-warm data has arrived.
------------------------------------------------------------
c_ffxivlib_dataready = inheritsFrom( ml_cause )
e_ffxivlib_dataready = inheritsFrom( ml_effect )

function c_ffxivlib_dataready:evaluate()
    -- If FFXIVLib is not loaded, skip the gate (backward compat)
    if not FFXIVLib then return false end
    if not FFXIVLib.PreWarm then return false end

    -- Fire pre-warm if not yet done
    if not FFXIVLib.PreWarm._ready then
        FFXIVLib.PreWarm.PreWarmAll()
    end

    -- Block if essential data hasn't arrived yet
    if not FFXIVLib.PreWarm.IsPreWarmReady() then
        return true  -- condition is met = we need to block
    end

    return false  -- data is ready, don't block
end

function e_ffxivlib_dataready:execute()
    -- Do nothing; just blocks the tick while we wait for data.
    -- The async callbacks will populate the caches in the background.
end

------------------------------------------------------------
-- Status Bridge
------------------------------------------------------------

--- Get status effect info by ID. Returns nil if pending.
-- @param statusId (number)
-- @return (table|nil)
function FFXIVData_GetStatus(statusId)
    if not FFXIVLib or not statusId then return nil end
    return FFXIVLib.API.Status.GetStatusById(statusId)
end

--- Get status name by ID. Returns nil if pending.
-- @param statusId (number)
-- @param language (string|nil)
-- @return (string|nil)
function FFXIVData_GetStatusName(statusId, language)
    if not FFXIVLib or not statusId then return nil end
    local row = FFXIVLib.API.Status.GetStatusById(statusId)
    if not row then return nil end
    if language then
        return row["name_" .. language] or row.name
    end
    return row.name
end

------------------------------------------------------------
-- Action Bridge
------------------------------------------------------------

--- Get action info by ID. Returns nil if pending.
-- @param actionId (number)
-- @return (table|nil)
function FFXIVData_GetAction(actionId)
    if not FFXIVLib or not actionId then return nil end
    return FFXIVLib.API.Action.GetActionById(actionId)
end

--- Get localized action name. Returns nil if pending.
-- @param actionId (number)
-- @param language (string|nil)
-- @return (string|nil)
function FFXIVData_GetActionName(actionId, language)
    if not FFXIVLib or not actionId then return nil end
    return FFXIVLib.API.Action.GetActionName(actionId, language)
end

--- Get all actions for a class/job. Returns nil if pending.
-- @param classJobId (number)
-- @return (table|nil)
function FFXIVData_GetClassActions(classJobId)
    if not FFXIVLib or not classJobId then return nil end
    return FFXIVLib.API.Action.GetActionsByClassJob(classJobId)
end

------------------------------------------------------------
-- Item Bridge
------------------------------------------------------------

--- Get item info by ID. Returns nil if pending.
-- @param itemId (number)
-- @return (table|nil)
function FFXIVData_GetItem(itemId)
    if not FFXIVLib or not itemId then return nil end
    return FFXIVLib.API.Items.GetItemById(itemId)
end

--- Get localized item name. Returns nil if pending.
-- @param itemId (number)
-- @param language (string|nil)
-- @return (string|nil)
function FFXIVData_GetItemName(itemId, language)
    if not FFXIVLib or not itemId then return nil end
    return FFXIVLib.API.Items.GetItemName(itemId, language)
end

--- Get item ID by name. Returns nil if pending.
-- @param name (string)
-- @param language (string|nil)
-- @return (number|nil)
function FFXIVData_GetItemIdByName(name, language)
    if not FFXIVLib or not name then return nil end
    return FFXIVLib.API.Items.GetItemIdByName(name, language)
end

------------------------------------------------------------
-- Repair Bridge
------------------------------------------------------------

--- Get repair info for an item. Returns nil if pending.
-- @param itemId (number)
-- @return (table|nil)
function FFXIVData_GetRepairInfo(itemId)
    if not FFXIVLib or not itemId then return nil end
    return FFXIVLib.API.Repair.GetRepairInfo(itemId)
end

--- Get masterpiece threshold info for a collectable item.
-- Returns nil if pending.
-- @param itemId (number)
-- @return (table|nil)
function FFXIVData_GetMasterpieceInfo(itemId)
    if not FFXIVLib or not itemId then return nil end
    return FFXIVLib.API.Repair.GetMasterpieceInfo(itemId)
end

------------------------------------------------------------
-- Recipe Bridge
------------------------------------------------------------

--- Get recipe by ID. Returns nil if pending.
-- @param recipeId (number)
-- @return (table|nil)
function FFXIVData_GetRecipe(recipeId)
    if not FFXIVLib or not recipeId then return nil end
    return FFXIVLib.API.Recipe.GetRecipeById(recipeId)
end

--- Get recipe by name. Returns nil if pending.
-- @param name (string)
-- @param language (string|nil)
-- @return (table|nil)
function FFXIVData_GetRecipeByName(name, language)
    if not FFXIVLib or not name then return nil end
    return FFXIVLib.API.Recipe.GetRecipeByName(name, language)
end

--- Get recipes for a crafting class. Returns nil if pending.
-- @param classId (number)
-- @param page (number|nil)
-- @return (table|nil)
function FFXIVData_GetRecipesByClass(classId, page)
    if not FFXIVLib or not classId then return nil end
    return FFXIVLib.API.Recipe.GetRecipesByClass(classId, page)
end

--- Get recipe level info. Returns nil if pending.
-- @param recipeLevel (number)
-- @return (table|nil)
function FFXIVData_GetRecipeLevelInfo(recipeLevel)
    if not FFXIVLib or not recipeLevel then return nil end
    return FFXIVLib.API.Recipe.GetRecipeLevelInfo(recipeLevel)
end

------------------------------------------------------------
-- Map Bridge
------------------------------------------------------------

--- Get map info by ID. Returns nil if pending.
-- @param mapId (number)
-- @return (table|nil)
function FFXIVData_GetMap(mapId)
    if not FFXIVLib or not mapId then return nil end
    return FFXIVLib.API.Map.GetMapById(mapId)
end

--- Get aetherytes for a map. Returns nil if pending.
-- @param mapId (number)
-- @return (table|nil)
function FFXIVData_GetAetherytes(mapId)
    if not FFXIVLib or not mapId then return nil end
    return FFXIVLib.API.Map.GetAetherytesByMapId(mapId)
end

------------------------------------------------------------
-- NPC Bridge
------------------------------------------------------------

--- Get NPC info by ID. Returns nil if pending.
-- @param bnpcId (number)
-- @return (table|nil)
function FFXIVData_GetNPC(bnpcId)
    if not FFXIVLib or not bnpcId then return nil end
    return FFXIVLib.API.NPC.GetBNpcById(bnpcId)
end

------------------------------------------------------------
-- Shop Bridge
------------------------------------------------------------

--- Get shops for an NPC. Returns nil if pending.
-- @param npcId (number)
-- @return (table|nil)
function FFXIVData_GetShopsByNPC(npcId)
    if not FFXIVLib or not npcId then return nil end
    return FFXIVLib.API.Shop.GetShopsByNpcId(npcId)
end

--- Find shops that sell a specific item. Returns nil if pending.
-- @param itemId (number)
-- @return (table|nil)
function FFXIVData_FindShopsForItem(itemId)
    if not FFXIVLib or not itemId then return nil end
    return FFXIVLib.API.Shop.FindShopsByItemId(itemId)
end

--- Get vendor data. Returns nil if pending.
-- @param vendorId (number)
-- @return (table|nil)
function FFXIVData_GetVendor(vendorId)
    if not FFXIVLib or not vendorId then return nil end
    return FFXIVLib.API.Shop.GetVendorData(vendorId)
end

------------------------------------------------------------
-- Weather Bridge
------------------------------------------------------------

--- Get weather rate for a map. Returns nil if pending.
-- @param mapId (number)
-- @return (table|nil)
function FFXIVData_GetWeatherRate(mapId)
    if not FFXIVLib or not mapId then return nil end
    return FFXIVLib.API.Weather.GetWeatherRateByMapId(mapId)
end

------------------------------------------------------------
-- Avoidance Bridge
------------------------------------------------------------

--- Get avoidance info for an enemy action. Returns nil if pending.
-- @param actionId (number)
-- @return (table|nil)
function FFXIVData_GetAvoidance(actionId)
    if not FFXIVLib or not actionId then return nil end
    return FFXIVLib.API.Avoidance.GetAvoidanceByActionId(actionId)
end

--- Get all avoidances for a BNPC. Returns nil if pending.
-- @param bnpcId (number)
-- @return (table|nil)
function FFXIVData_GetAvoidancesByBNPC(bnpcId)
    if not FFXIVLib or not bnpcId then return nil end
    return FFXIVLib.API.Avoidance.GetAvoidancesByBNpcId(bnpcId)
end

------------------------------------------------------------
-- Firmament Bridge
------------------------------------------------------------

--- Get firmament recipes for a crafting class. Returns nil if pending.
-- @param classId (number)
-- @return (table|nil)
function FFXIVData_GetFirmamentRecipes(classId)
    if not FFXIVLib or not classId then return nil end
    return FFXIVLib.API.Firmament.GetFirmamentRecipes(classId)
end

------------------------------------------------------------
-- Quest Bridge
------------------------------------------------------------

--- Get quest info by ID. Returns nil if pending.
-- @param questId (number)
-- @return (table|nil)
function FFXIVData_GetQuest(questId)
    if not FFXIVLib or not questId then return nil end
    return FFXIVLib.API.Quest.GetQuestById(questId)
end

--- Get quest name by ID. Returns nil if pending.
-- @param questId (number)
-- @param language (string|nil)
-- @return (string|nil)
function FFXIVData_GetQuestName(questId, language)
    if not FFXIVLib or not questId then return nil end
    return FFXIVLib.API.Quest.GetQuestName(questId, language)
end

------------------------------------------------------------
-- FATE Bridge
------------------------------------------------------------

--- Get FATE info by ID. Returns nil if pending.
-- @param fateId (number)
-- @return (table|nil)
function FFXIVData_GetFate(fateId)
    if not FFXIVLib or not fateId then return nil end
    return FFXIVLib.API.Fate.GetFateById(fateId)
end

------------------------------------------------------------
-- Huntlog Bridge
------------------------------------------------------------

--- Get hunt log entries. Returns nil if pending.
-- @param classId (number)
-- @param rank (number)
-- @return (table|nil)
function FFXIVData_GetHuntLogEntries(classId, rank)
    if not FFXIVLib or not classId or not rank then return nil end
    return FFXIVLib.API.Huntlog.GetHuntLogEntries(classId, rank)
end

------------------------------------------------------------
-- Translation Bridge
------------------------------------------------------------

--- Get a translated string. Returns nil if pending.
-- @param key (string)
-- @param language (string|nil)
-- @return (string|nil)
function FFXIVData_GetTranslation(key, language)
    if not FFXIVLib or not key then return nil end
    return FFXIVLib.API.Translations.GetTranslation(key, language)
end

------------------------------------------------------------
-- Pre-Warm Utilities
--
-- These are convenience functions for task code to trigger
-- pre-warming of specific data sets relevant to their domain.
------------------------------------------------------------

--- Pre-warm recipe data for the current crafting class.
-- Call from crafting task setup.
-- @param classId (number) Crafting class index (0=CRP..7=CUL)
function FFXIVData_PreWarmCraft(classId)
    if not FFXIVLib or not classId then return end
    FFXIVLib.PreWarm.PreWarmRecipeData(classId)
end

--- Pre-warm masterpiece thresholds for a set of collectable items.
-- Call from gathering task setup for collectable profiles.
-- @param itemIds (table) Array of item IDs
function FFXIVData_PreWarmCollectables(itemIds)
    if not FFXIVLib or not itemIds then return end
    FFXIVLib.PreWarm.PreWarmCollectableData(itemIds)
end

--- Pre-warm action data for a specific class/job.
-- Call when the skill manager loads a new profile.
-- @param classJobId (number)
function FFXIVData_PreWarmActions(classJobId)
    if not FFXIVLib or not classJobId then return end
    FFXIVLib.PreWarm.PreWarmClassActions(classJobId)
end

--- Pre-warm map/weather/aetheryte data for a specific map.
-- Call when a task selects a new destination map.
-- @param mapId (number)
function FFXIVData_PreWarmMap(mapId)
    if not FFXIVLib or not mapId then return end
    FFXIVLib.PreWarm.PreWarmCurrentMap(mapId)
end

--- Pre-warm equipped gear repair info.
-- Call after equipping new gear.
function FFXIVData_PreWarmGear()
    if not FFXIVLib then return end
    FFXIVLib.PreWarm.PreWarmEquippedGear()
end

--- Trigger the full pre-warm sweep (called once at login).
function FFXIVData_PreWarmAll()
    if not FFXIVLib then return end
    FFXIVLib.PreWarm.PreWarmAll()
end

--- Check if minimum pre-warm data is ready.
-- @return (boolean)
function FFXIVData_IsReady()
    if not FFXIVLib then return true end -- no FFXIVLib = no gate
    if not FFXIVLib.PreWarm then return true end
    return FFXIVLib.PreWarm.IsPreWarmReady()
end

------------------------------------------------------------
-- FFXIVLib Data Bridge for ffxivminion
--
-- CNE gate and pre-warm utilities that sit between the
-- ffxivminion task system and FFXIVLib's async data layer.
--
-- All data access goes directly through FFXIVLib.API.*
-- from consumer code -- no wrapper layer needed.
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

local function FFXIVData_IsOptiFineMode()
    return FFXIVLib
        and FFXIVLib.IsOptiFineMode
        and FFXIVLib.IsOptiFineMode()
end

local function FFXIVData_ShouldDeferSpeculative()
    return FFXIVData_IsOptiFineMode()
        and FFXIV_Common_BotRunning ~= true
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
    if not FFXIVLib or not classId then return nil end
    FFXIVLib.PreWarm.PreWarmRecipeData(classId)
end

--- Pre-warm masterpiece thresholds for a set of collectable items.
-- Call from gathering task setup for collectable profiles.
-- @param itemIds (table) Array of item IDs
function FFXIVData_PreWarmCollectables(itemIds)
    if not FFXIVLib or not itemIds then return nil end
    FFXIVLib.PreWarm.PreWarmCollectableData(itemIds)
end

--- Pre-warm action data for a specific class/job.
-- Call when the skill manager loads a new profile.
-- @param classJobId (number)
function FFXIVData_PreWarmActions(classJobId)
    if not FFXIVLib or not classJobId then return nil end
    if FFXIVData_ShouldDeferSpeculative() then return nil end
    FFXIVLib.PreWarm.PreWarmClassActions(classJobId)
end

--- Pre-warm map/weather/aetheryte data for a specific map.
-- Call when a task selects a new destination map.
-- @param mapId (number)
function FFXIVData_PreWarmMap(mapId)
    if not FFXIVLib or not mapId then return nil end
    if FFXIVData_ShouldDeferSpeculative() then return nil end
    FFXIVLib.PreWarm.PreWarmCurrentMap(mapId)
end

--- Pre-warm equipped gear repair info.
-- Call after equipping new gear.
function FFXIVData_PreWarmGear()
    if not FFXIVLib then return nil end
    if FFXIVData_ShouldDeferSpeculative() then return nil end
    FFXIVLib.PreWarm.PreWarmEquippedGear()
end

--- Pre-warm World/DC data for login screen.
-- Call before auto-login needs datacenter/server lists.
-- @param gameRegion (number) The gameRegion constant (1-4)
function FFXIVData_PreWarmWorld(gameRegion)
    if not FFXIVLib or not gameRegion then return nil end
    FFXIVLib.PreWarm.PreWarmWorld(gameRegion)
end

--- Trigger the full pre-warm sweep (called once at login).
function FFXIVData_PreWarmAll()
    if not FFXIVLib then return nil end
    FFXIVLib.PreWarm.PreWarmAll()
end

--- Check if minimum pre-warm data is ready.
-- @return (boolean)
function FFXIVData_IsReady()
    if not FFXIVLib then return true end -- no FFXIVLib = no gate
    if not FFXIVLib._initialized then return true end -- not activated = no gate
    return true
end

------------------------------------------------------------
-- Nav Data Discovery, Enrichment & Resolution
--
-- Driven from the game loop:
--   1. DiscoverConnections - bulk SQL to find NPC/EObj warps
--   2. Enrichment - populate conversation strings
--   3. Resolution - tag entries with pos/dest source info
------------------------------------------------------------
ml_global_information._nav_enrich_done = false
ml_global_information._nav_resolve_done = false

local FFXIVDATA_NAV_TICK_NORMAL_MS = 35
local FFXIVDATA_NAV_TICK_OPTIFINE_MS = 250
local ffxivDataNavLastTick = 0

local function FFXIVData_NavDiscoveryDone()
    return FFXIVLib and FFXIVLib.API.Nav and FFXIVLib.API.Nav._discoveryDone
end

local function FFXIVData_ShouldDeferAutomaticNav()
    return FFXIVData_IsOptiFineMode()
        and FFXIV_Common_BotRunning ~= true
end

--- Tick nav discovery (bulk SQL warp scanning).
-- Call periodically until it returns true.
-- @return (boolean) true when discovery is complete.
function FFXIVData_NavDiscoverTick()
    if FFXIVData_NavDiscoveryDone() then return true end
    if FFXIVData_ShouldDeferAutomaticNav() then return false end
    if not FFXIVLib or not FFXIVLib.API.Nav or not FFXIVLib.API.Nav.DiscoverConnections then return false end
    if FFXIVLib.EnsureDomain and not FFXIVLib.EnsureDomain("Nav") then return false end
    return FFXIVLib.API.Nav.DiscoverConnections()
end

--- Tick nav enrichment (conversation strings from Warp SQL).
-- Call periodically until it returns true.
-- @return (boolean) true when all entries are enriched.
function FFXIVData_NavEnrichTick()
    if ml_global_information._nav_enrich_done then return true end
    if FFXIVData_ShouldDeferAutomaticNav() then return false end
    if not FFXIVLib or not FFXIVLib.API.Nav then return false end
    -- Wait for discovery before enriching
    if not FFXIVData_NavDiscoveryDone() then return false end
    local done = FFXIVLib.API.Nav.EnrichAll()
    if done then
        ml_global_information._nav_enrich_done = true
        navd("[Nav] Enrichment complete - all conversation strings populated.")
    end
    return done
end

--- Tick nav resolution (on-demand data vs static comparison).
-- Call periodically until it returns true.
-- @return (boolean) true when all entries are resolved.
function FFXIVData_NavResolveTick()
    if ml_global_information._nav_resolve_done then return true end
    if FFXIVData_ShouldDeferAutomaticNav() then return false end
    if not FFXIVLib or not FFXIVLib.API.Nav then return false end
    -- Wait for discovery before resolving
    if not FFXIVData_NavDiscoveryDone() then return false end
    local done = FFXIVLib.API.Nav.ResolveAll()
    if done then
        ml_global_information._nav_resolve_done = true
        navd("[Nav] Resolution complete - all entries tagged with source.")
    end
    return done
end

--- Independently drives FFXIVLib Nav discovery.
-- Optifine replaces ml_global_information.InGameOnUpdate, so this must be
-- registered directly instead of relying on the replaceable base function.
function FFXIVData_NavOnUpdate(event, tickcount)
    if not Player
        or MGetGameState() ~= FFXIV.GAMESTATE.INGAME
        or FFXIVData_ShouldDeferAutomaticNav()
        or (ml_global_information.IsYielding and ml_global_information.IsYielding())
    then
        return
    end
    if FFXIVData_NavDiscoveryDone()
        and ml_global_information._nav_enrich_done
        and ml_global_information._nav_resolve_done
    then
        return
    end

    local now = tonumber(tickcount) or Now()
    local interval = FFXIVData_IsOptiFineMode()
        and FFXIVDATA_NAV_TICK_OPTIFINE_MS
        or FFXIVDATA_NAV_TICK_NORMAL_MS
    if ffxivDataNavLastTick > 0 and (now - ffxivDataNavLastTick) < interval then
        return
    end
    ffxivDataNavLastTick = now

    FFXIVData_NavDiscoverTick()
    FFXIVData_NavEnrichTick()
    FFXIVData_NavResolveTick()
end

RegisterEventHandler(
    "Gameloop.Update",
    FFXIVData_NavOnUpdate,
    "FFXIVData.NavOnUpdate"
)

ffxiv_task_test = inheritsFrom(ml_task)
ffxiv_task_test.lastTick = 0
ffxiv_task_test.lastPathCheck = 0
ffxiv_task_test.flightMesh = {}
ffxiv_task_test.lastTaskSet = {}
ffxiv_task_test.lastRect = {}
ffxiv_task_test.lastMetricUpdate = 0
ffxiv_task_test.metricDist2d = 0
ffxiv_task_test.metricDist3d = 0
ffxiv_task_test.metricReachableText = "pending"
ffxiv_task_test.metricLastResolvedDist3d = nil
ffxiv_task_test.metricLastResolvedReachable = nil
ffxiv_task_test.metricAsyncQuery = {
	pending = false,
	from = nil,
	to = nil,
	startedAt = 0,
	timeoutMs = 1500,
}
ffxiv_task_test.contexts = {
	"Direct",
	"Quest Navigate",
	"Quest Interact",
	"Grind ReturnToMarker",
}

local function _NavTestContextIndex(context)
	for i,name in ipairs(ffxiv_task_test.contexts) do
		if (context == name) then
			return i
		end
	end
	return 1
end

local function _NavTestNormalizeContext()
	gTestTaskContextIndex = tonumber(gTestTaskContextIndex) or _NavTestContextIndex(gTestTaskContext)
	if (not ffxiv_task_test.contexts[gTestTaskContextIndex]) then
		gTestTaskContextIndex = _NavTestContextIndex(gTestTaskContext)
	end
	if (not ffxiv_task_test.contexts[gTestTaskContextIndex]) then
		gTestTaskContextIndex = 1
	end
	gTestTaskContext = ffxiv_task_test.contexts[gTestTaskContextIndex] or "Direct"
	if (Settings and Settings.FFXIVMINION) then
		Settings.FFXIVMINION["gTestTaskContextIndex"] = gTestTaskContextIndex
		Settings.FFXIVMINION["gTestTaskContext"] = gTestTaskContext
	end
	return gTestTaskContext
end

local function _NavTestContext()
	if (gTestTaskContext ~= nil or gTestTaskContextIndex ~= nil) then
		return _NavTestNormalizeContext()
	end
	return "Direct"
end

local function _NavTestPosFromFields()
	return {
		x = tonumber(gTestMapX) or 0,
		y = tonumber(gTestMapY) or 0,
		z = tonumber(gTestMapZ) or 0,
	}
end

local function _NavTestScenarioKey(context, mapID, npcID, pos)
	return tostring(context).."|"..tostring(mapID).."|"..tostring(npcID).."|"
		..tostring(pos.x).."|"..tostring(pos.y).."|"..tostring(pos.z).."|"
		..tostring(gTestNavRange).."|"..tostring(gTestNoFly).."|"..tostring(gTestNoMount).."|"
		..tostring(gTestRemainMounted)
end

function ffxiv_task_test.ResetLaunchGuards()
	if (c_gotopostest) then
		c_gotopostest.reached = false
	end
	if (c_gotonpctest) then
		c_gotonpctest.started = false
		c_gotonpctest.reached = false
		c_gotonpctest.lastKey = nil
	end
	if (c_navtestscenario) then
		c_navtestscenario.started = false
		c_navtestscenario.lastKey = nil
	end
end

local function _PosEquals(a, b)
	return (a and b and a.x == b.x and a.y == b.y and a.z == b.z)
end

local function _NavTestPathDistance(path)
	if (not table.valid(path)) then return nil end
	local keys = {}
	for k,v in pairs(path) do
		if (type(k) == "number" and type(v) == "table") then
			table.insert(keys, k)
		end
	end
	if (#keys < 2) then return nil end
	table.sort(keys)
	local dist = 0
	for i = 2, #keys do
		local a = path[keys[i - 1]]
		local b = path[keys[i]]
		if (a and b and a.x and a.y and a.z and b.x and b.y and b.z) then
			dist = dist + Distance3D(a.x, a.y, a.z, b.x, b.y, b.z)
		end
	end
	return (dist > 0) and dist or nil
end

local function _NavTestPathCacheID(pos1, pos2)
	local mapId = (Player and Player.localmapid) and tostring(Player.localmapid) or "0"
	local floorFlags = NavigationManager:GetExcludeFilter(GLOBAL.NODETYPE.FLOOR) or 0
	local cubeFlags = NavigationManager:GetExcludeFilter(GLOBAL.NODETYPE.CUBE) or 0
	local key = string.format("%s|%d|%d|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f",
		mapId, floorFlags, cubeFlags,
		pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z)
	local hash = 5381
	for i = 1, #key do
		hash = ((hash * 33) + string.byte(key, i)) % 2147483647
	end
	if (hash <= 0) then hash = 1 end
	return hash
end

local function _NavTestGetPathDistanceAsync(pos1, pos2)
	local dist = math.distance3d(pos1, pos2)
	local cacheID = _NavTestPathCacheID(pos1, pos2)
	local result = NavigationManager:GetPathAsync(pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z, cacheID, true)
	if (type(result) == "table" and table.valid(result)) then
		local pathdist = _NavTestPathDistance(result)
		if (pathdist ~= nil) then
			return pathdist, true
		end
		local convertedDist = NavigationManager:GetPathDistance(pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z, cacheID)
		if (type(convertedDist) == "number" and convertedDist > 0 and convertedDist < 1000000000) then
			return convertedDist, true
		end
		return nil, true
	elseif (type(result) == "number") then
		if (result < 0) then
			return nil, true
		end
		return dist, false
	end
	return dist, false
end

function ffxiv_task_test.UpdateNavMetrics()
	local now = Now()
	if (TimeSince(ffxiv_task_test.lastMetricUpdate) < 200) then
		return
	end
	ffxiv_task_test.lastMetricUpdate = now

	local ppos = Player.pos
	local tx = IsNull(tonumber(gTestMapX), 0)
	local ty = IsNull(tonumber(gTestMapY), 0)
	local tz = IsNull(tonumber(gTestMapZ), 0)
	local targetPos = { x = tx, y = ty, z = tz }

	ffxiv_task_test.metricDist2d = Distance2D(ppos.x, ppos.z, tx, tz)
	local euclideanDist3d = Distance3D(ppos.x, ppos.y, ppos.z, tx, ty, tz)

	local query = ffxiv_task_test.metricAsyncQuery
	if (query.pending) then
		if (not _PosEquals(query.to, targetPos)) then
			query.pending = false
			query.from = nil
			query.to = nil
		end
	end

	local asyncDist, resolved = nil, false
	if (query.pending and table.valid(query.from) and table.valid(query.to)) then
		asyncDist, resolved = _NavTestGetPathDistanceAsync(query.from, query.to)
		if (resolved == true) then
			query.pending = false
			query.from = nil
			query.to = nil
		elseif (TimeSince(query.startedAt) > query.timeoutMs) then
			query.pending = false
			query.from = nil
			query.to = nil
		end
	else
		query.from = { x = ppos.x, y = ppos.y, z = ppos.z }
		query.to = targetPos
		query.startedAt = now
		asyncDist, resolved = _NavTestGetPathDistanceAsync(query.from, query.to)
		if (resolved ~= true) then
			query.pending = true
		end
	end

	if (resolved == true) then
		local resolvedReachable = (asyncDist ~= nil)
		ffxiv_task_test.metricLastResolvedReachable = resolvedReachable
		ffxiv_task_test.metricLastResolvedDist3d = resolvedReachable and asyncDist or euclideanDist3d
		ffxiv_task_test.metricDist3d = ffxiv_task_test.metricLastResolvedDist3d
		ffxiv_task_test.metricReachableText = resolvedReachable and "true" or "false"
	else
		-- Keep the last resolved values while async path query is still warming.
		if (ffxiv_task_test.metricLastResolvedDist3d ~= nil) then
			ffxiv_task_test.metricDist3d = ffxiv_task_test.metricLastResolvedDist3d
			if (ffxiv_task_test.metricLastResolvedReachable ~= nil) then
				ffxiv_task_test.metricReachableText = (ffxiv_task_test.metricLastResolvedReachable and "true" or "false") .. " (pending)"
			else
				ffxiv_task_test.metricReachableText = "pending"
			end
		else
			ffxiv_task_test.metricDist3d = euclideanDist3d
			ffxiv_task_test.metricReachableText = "pending"
		end
	end
end

function ffxiv_task_test.Create()
    local newinst = inheritsFrom(ffxiv_task_test)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_movetomap members
    newinst.name = "TEST"
	newinst.taskCreated = false
	newinst.moveCreated = false
	if (c_gotonpctest) then
		c_gotonpctest.started = false
		c_gotonpctest.reached = false
		c_gotonpctest.lastKey = nil
	end
	if (c_navtestscenario) then
		c_navtestscenario.started = false
		c_navtestscenario.lastKey = nil
	end
   
    return newinst
end

c_gotomaptest = inheritsFrom( ml_cause )
e_gotomaptest = inheritsFrom( ml_effect )
function c_gotomaptest:evaluate()
	local mapID = tonumber(gTestMapID)
	if (Player.localmapid ~= mapID) then
		if (CanAccessMap(mapID)) then
			return true
		else
			d("Can't access map.")
		end
	end
	
	return false
end
function e_gotomaptest:execute()
	local mapID = tonumber(gTestMapID)
	local task = ffxiv_task_movetomap.Create()
	local pos = {}
	pos.x = tonumber(gTestMapX) or 0
	pos.y = tonumber(gTestMapY) or 0
	pos.z = tonumber(gTestMapZ) or 0
	
	task.pos = pos
	task.destMapID = mapID
	task.setHomepoint = gTestSetHomepoint
	task.disableTeleport = gTestDisableTeleport
	ml_task_hub:CurrentTask():AddSubTask(task)
end

ffxiv_task_navtest_grindmarker = inheritsFrom(ml_task)
function ffxiv_task_navtest_grindmarker.Create(pos)
	local newinst = inheritsFrom(ffxiv_task_navtest_grindmarker)

	newinst.valid = true
	newinst.completed = false
	newinst.subtask = nil
	newinst.auxiliary = false
	newinst.process_elements = {}
	newinst.overwatch_elements = {}

	newinst.name = "LT_GRIND"
	newinst.pos = pos
	newinst.previousMarker = ml_marker_mgr.currentMarker
	newinst.targetFunction = function() return nil end
	newinst.killFunction = nil

	return newinst
end
function ffxiv_task_navtest_grindmarker:Init()
	ml_marker_mgr.currentMarker = {
		name = "NavTest Grind Marker",
		type = GetString("grindMarker"),
		pos = self.pos,
		maxradius = tonumber(gTestNavRange) or 4,
	}

	local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 25 )
	self:add(ke_returnToMarker, self.process_elements)
	self:AddTaskCheckCEs()
end
function ffxiv_task_navtest_grindmarker:task_complete_eval()
	if (self.subtask ~= nil) then
		return false
	end
	local ppos = Player.pos
	local pos = self.pos
	local range = tonumber(gTestNavRange) or 4
	return Distance3D(ppos.x, ppos.y, ppos.z, pos.x, pos.y, pos.z) <= math.max(range + 2, 10)
end
function ffxiv_task_navtest_grindmarker:task_complete_execute()
	Player:Stop()
	ml_marker_mgr.currentMarker = self.previousMarker
	self.completed = true
end
function ffxiv_task_navtest_grindmarker:task_fail_eval()
	return not Player.alive
end
function ffxiv_task_navtest_grindmarker:task_fail_execute()
	ml_marker_mgr.currentMarker = self.previousMarker
	self.valid = false
end

c_navtestscenario = inheritsFrom( ml_cause )
e_navtestscenario = inheritsFrom( ml_effect )
c_navtestscenario.pos = {}
c_navtestscenario.context = "Direct"
c_navtestscenario.key = nil
c_navtestscenario.started = false
c_navtestscenario.lastKey = nil
function c_navtestscenario:evaluate()
	c_navtestscenario.pos = {}
	c_navtestscenario.context = _NavTestContext()
	c_navtestscenario.key = nil

	local context = c_navtestscenario.context
	if (context == "Direct") then
		return false
	end

	local mapID = tonumber(gTestMapID)
	local npcID = tonumber(gTestNPCID) or 0
	if (Player.localmapid ~= mapID) then
		c_navtestscenario.started = false
		return false
	end
	if (context == "Quest Interact" and npcID == 0) then
		return false
	end

	local pos = _NavTestPosFromFields()
	local key = _NavTestScenarioKey(context, mapID, npcID, pos)
	if (c_navtestscenario.lastKey ~= key) then
		c_navtestscenario.started = false
		c_navtestscenario.lastKey = key
	end
	if (c_navtestscenario.started) then
		return false
	end

	if (context ~= "Quest Interact") then
		local ppos = Player.pos
		local range = tonumber(gTestNavRange) or 4
		local dist = Distance3D(ppos.x, ppos.y, ppos.z, pos.x, pos.y, pos.z)
		local triggerDist = (context == "Grind ReturnToMarker") and 10 or (range + 2)
		if (dist <= triggerDist) then
			return false
		end
	end

	c_navtestscenario.pos = pos
	c_navtestscenario.key = key
	return true
end
function e_navtestscenario:execute()
	local context = c_navtestscenario.context
	local pos = c_navtestscenario.pos
	local mapID = tonumber(gTestMapID) or Player.localmapid
	local npcID = tonumber(gTestNPCID) or 0
	local range = tonumber(gTestNavRange) or 4
	local newTask = nil

	if (context == "Quest Navigate" or context == "Quest Interact") then
		if (not FFXIVLib or not FFXIVLib.Questing or not FFXIVLib.Questing.NavTest
			or not FFXIVLib.Questing.NavTest.CreateScenarioTask) then
			d("[NavTest] Questing NavTest adapter is unavailable.")
			return
		end

		local kind = (context == "Quest Navigate") and "nav" or "interact"
		local params = {
			type = kind,
			mapid = mapID,
			pos = pos,
			range = range,
			noflight = gTestNoFly,
			nomount = gTestNoMount,
			remainmounted = gTestRemainMounted,
		}
		if (npcID ~= 0) then
			params.id = npcID
		end
		if (kind == "interact") then
			params.type = "interact"
			params.interactrange = range
			params.interactrange3d = range + 3
		end

		local err = nil
		newTask, err = FFXIVLib.Questing.NavTest.CreateScenarioTask(kind, params)
		if (not newTask) then
			d("[NavTest] Failed to create Questing scenario task: "..tostring(err))
			return
		end
	elseif (context == "Grind ReturnToMarker") then
		newTask = ffxiv_task_navtest_grindmarker.Create(pos)
	end

	if (newTask) then
		d("[NavTest] Starting task-context scenario ["..tostring(context).."].")
		ml_task_hub:CurrentTask():AddSubTask(newTask)
		c_navtestscenario.started = true
	end
end

c_gotopostest = inheritsFrom( ml_cause )
e_gotopostest = inheritsFrom( ml_effect )
c_gotopostest.pos = {}
function c_gotopostest:evaluate()
	c_gotopostest.pos = {}

	if (_NavTestContext() ~= "Direct") then
		return false
	end

	local mapID = tonumber(gTestMapID)
	if (Player.localmapid == mapID and tonumber(gTestNPCID) == 0) then
		local ppos = Player.pos
		local pos = {}
		pos.x = tonumber(gTestMapX)
		pos.y = tonumber(gTestMapY)
		pos.z = tonumber(gTestMapZ)
		
		-- MoveToExact mode: use its own active state instead of task-based distance
		if (gTestUseMoveToExact) then
			if (not FFXIV_Common_BotRunning) then
				return false -- bot is stopping, don't re-trigger
			end
			if (Player:IsExactMoving()) then
				return false -- already moving, let Navigate handle it
			end
			-- Navigate finished - stop the bot
			if (ml_navigation_exact.completed) then
				ml_navigation_exact.completed = false
				c_gotopostest.reached = true
				ml_task_hub.shouldRun = false
				FFXIV_Common_BotRunning = false
				d("[NavTest] MoveToExact destination reached — bot stopped.")
				return false
			end
			local dist = Distance3D(ppos.x, ppos.y, ppos.z, pos.x, pos.y, pos.z)
			local thresh = tonumber(gTestNavRange) or 0.1
			if (dist > thresh) then
				c_gotopostest.pos = pos
				return true
			end
			return false
		end
		
		local range = tonumber(gTestNavRange) or 4
		local dist = Distance3D(ppos.x, ppos.y, ppos.z, pos.x, pos.y, pos.z)
		local triggerDist = (range + 2)
		if (dist > triggerDist) then
			c_gotopostest.reached = false
			c_gotopostest.pos = pos
			return true
		else
			if (not c_gotopostest.reached) then
				c_gotopostest.reached = true
				Player:Stop()
			end
		end
	end
	return false
end
function e_gotopostest:execute()
	-- MoveToExact mode: call directly instead of spawning a subtask
	if (gTestUseMoveToExact) then
		local pos = c_gotopostest.pos
		local thresh = tonumber(gTestNavRange) or 0.1
		local ret = Player:MoveToExact(pos.x, pos.y, pos.z, thresh)
		if (ret == -1) then
			d("[NavTest] MoveToExact failed — position unreachable.")
		end
		return
	end
	
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = c_gotopostest.pos 
	newTask.cubefilters = gTestNoFly and 1 or 0
	newTask.range = tonumber(gTestNavRange) or 4
	newTask.remainMounted = gTestRemainMounted
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_gotonpctest = inheritsFrom( ml_cause )
e_gotonpctest = inheritsFrom( ml_effect )
c_gotonpctest.pos = {}
c_gotonpctest.started = false
c_gotonpctest.reached = false
c_gotonpctest.lastKey = nil
function c_gotonpctest:evaluate()
	c_gotonpctest.pos = {}
	c_gotonpctest.path = {}

	if (_NavTestContext() ~= "Direct") then
		return false
	end

	local mapID = tonumber(gTestMapID)
	if (Player.localmapid == mapID and tonumber(gTestNPCID) ~= 0) then
		local pos = {}
		pos.x = tonumber(gTestMapX)
		pos.y = tonumber(gTestMapY)
		pos.z = tonumber(gTestMapZ)
		local key = tostring(mapID).."|"..tostring(gTestNPCID).."|"..tostring(pos.x).."|"..tostring(pos.y).."|"..tostring(pos.z)
		if (c_gotonpctest.lastKey ~= key) then
			c_gotonpctest.started = false
			c_gotonpctest.reached = false
			c_gotonpctest.lastKey = key
		end
		if (c_gotonpctest.reached or c_gotonpctest.started) then
			return false
		end
		
		c_gotonpctest.pos = pos
		return true
	end
	c_gotonpctest.started = false
	c_gotonpctest.reached = false
	c_gotonpctest.lastKey = nil
	return false
end
function e_gotonpctest:execute()
	local newTask = ffxiv_task_movetointeract.Create()
	newTask.interact = gTestNPCID
	newTask.navid = gTestNPCID
	newTask.pos = c_gotonpctest.pos
	--newTask.interactRange = 1
	
	ml_task_hub:CurrentTask():AddSubTask(newTask)
	c_gotonpctest.started = true
	c_gotonpctest.reached = true
end

function ffxiv_task_test.ResetInstructions()
	ml_mesh_mgr.receivedInstructions = {}
end

function ffxiv_task_test.TestInstructions()
	local instructions = {
		{"Stop", {}},
		{"Wait", { 100 }},
		{"MoveStraightTo", { -118.38, 55.99, -29.816 }},
		{"MoveStraightTo", { -118.34, 55.90, -28.25 }},
		{"MoveStraightTo", { -111.06, 55.90, -28.35 }},
		{"MoveStraightTo", { -112.85, 55.90, -27.408 }},
		{"MoveStraightTo", { -121.67, 61.74, -27.375 }},
		{"MoveStraightTo", { -121.28, 61.74, -28.419 }},
		{"MoveStraightTo", { -112.59, 67.495, -28.479 }},
		{"MoveStraightTo", { -113.62, 67.495, -27.39 }},
		{"MoveStraightTo", { -122.21, 73.236, -27.697 }},
		{"MoveStraightTo", { -122.187, 74.102, -18.53 }},
		{"MoveStraightToContinue", { -116.38, 74.102, -19.514}},
		{"CheckIfNear", { -116.38, 74.102, -19.514}},
		{"Jump", {}},
		{"Wait", { 1000 }},
		{"MoveStraightToContinue", { -107.79, 74.102, -20.839 }},
		{"MoveStraightToContinue", { -97.80, 74.102, -23.060 }},
		{"MoveStraightToContinue", { -88.98, 74.102, -25.882 }},
		{"MoveStraightToContinue", { -83.737, 74.102, -27.945}},
		{"CheckIfNear", { -83.737, 74.102, -27.945}},
		{"Jump", {}},
		{"Wait", { 1000 }},
		{"MoveStraightToContinue", { -75.20, 74.102, -31.68 }},
		{"MoveStraightToContinue", { -68.85, 74.102, -35.03 }},
		{"MoveStraightToContinue", { -61.16, 74.102, -39.84 }},
		{"MoveStraightToContinue", { -54.872, 74.102, -44.542}},
		{"CheckIfNear", { -54.872, 74.102, -44.542}},
		{"Jump", {}},
		{"Wait", { 1000 }},
		{"Stop"},
	}
	ml_mesh_mgr.ParseInstructions(instructions)
end

function ffxiv_task_test:Init()
	local ke_startMapTest = ml_element:create( "GoToMapTest", c_gotomaptest, e_gotomaptest, 20 )
    self:add(ke_startMapTest, self.process_elements)

	local ke_startScenarioTest = ml_element:create( "TaskContextTest", c_navtestscenario, e_navtestscenario, 18 )
    self:add(ke_startScenarioTest, self.process_elements)
	
	local ke_startMoveTest = ml_element:create( "GoToNPCTest", c_gotonpctest, e_gotonpctest, 15 )
    self:add(ke_startMoveTest, self.process_elements)
	
	local ke_startMoveTest = ml_element:create( "GoToPosTest", c_gotopostest, e_gotopostest, 15 )
    self:add(ke_startMoveTest, self.process_elements)
	
	--local ke_flightTest = ml_element:create( "FlightTest", c_flighttest, e_flighttest, 15 )
    --self:add(ke_flightTest, self.process_elements)
end

-- New GUI.
function ffxiv_task_test:UIInit()	
	gTestMapID = ffxivminion.GetSetting("gTestMapID","")
	gTestNPCID = ffxivminion.GetSetting("gTestNPCID",0)
	gTestMapX = ffxivminion.GetSetting("gTestMapX","")
	gTestMapY = ffxivminion.GetSetting("gTestMapY","")
	gTestMapZ = ffxivminion.GetSetting("gTestMapZ","")
	gTestNoFly = ffxivminion.GetSetting("gTestNoFly",false)
	gTestNoMount = ffxivminion.GetSetting("gTestNoMount",false)
	gTestNavRange = ffxivminion.GetSetting("gTestNavRange",4)
	gTestRemainMounted = ffxivminion.GetSetting("gTestRemainMounted",true)
	gTestUseMoveToExact = ffxivminion.GetSetting("gTestUseMoveToExact",false)
	gTestSetHomepoint = ffxivminion.GetSetting("gTestSetHomepoint",false)
	gTestDisableTeleport = ffxivminion.GetSetting("gTestDisableTeleport",false)
	gTestTaskContext = ffxivminion.GetSetting("gTestTaskContext","Direct")
	gTestTaskContextIndex = ffxivminion.GetSetting("gTestTaskContextIndex",_NavTestContextIndex(gTestTaskContext))
	_NavTestNormalizeContext()
end

ffxiv_task_test.GUI = {
	x = 0,
	y = 0, 
	height = 0,
	width = 0,
}

function ffxiv_task_test:Draw()
	ffxiv_task_test.UpdateNavMetrics()

	local fontSize = GUI:GetWindowFontSize()
	local windowPaddingY = GUI:GetStyle().windowpadding.y
	local framePaddingY = GUI:GetStyle().framepadding.y
	local itemSpacingY = GUI:GetStyle().itemspacing.y
	
	GUI:BeginChild("##header-status",0,GUI_GetFrameHeight(20),true)
	GUI:Columns(2)
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("No Fly")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("No Mount")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Remain Mounted")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Use MoveToExact")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Set Home Point")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Disable Teleport")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Nav Range")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Map ID")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("NPC ID")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("X")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Y")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Z")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Distance 2d")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Distance 3d")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Is Reachable")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("Player Sec")
	GUI:AlignFirstTextHeightToWidgets() GUI:Text("End Sec")
	GUI:NextColumn()
	local ColumnWidth = GUI:GetContentRegionAvail()
	GUI:PushItemWidth(ColumnWidth)
	if gTestMapX == "" then
		gTestMapX = 0
	end
	if gTestMapY == "" then
		gTestMapY = 0
	end
	if gTestMapZ == "" then
		gTestMapZ = 0
	end
	GUI:AlignFirstTextHeightToWidgets() GUI_Capture(GUI:Checkbox("##No Fly",gTestNoFly),"gTestNoFly")
	GUI:AlignFirstTextHeightToWidgets() GUI_Capture(GUI:Checkbox("##No Mount",gTestNoMount),"gTestNoMount")
	GUI:AlignFirstTextHeightToWidgets() GUI_Capture(GUI:Checkbox("##Remain Mounted",gTestRemainMounted),"gTestRemainMounted")
	GUI:AlignFirstTextHeightToWidgets() GUI_Capture(GUI:Checkbox("##Use MoveToExact",gTestUseMoveToExact),"gTestUseMoveToExact")
	GUI:AlignFirstTextHeightToWidgets() GUI_Capture(GUI:Checkbox("##Set Home Point",gTestSetHomepoint),"gTestSetHomepoint")
	GUI:AlignFirstTextHeightToWidgets() GUI_Capture(GUI:Checkbox("##Disable Teleport",gTestDisableTeleport),"gTestDisableTeleport")
	GUI:AlignFirstTextHeightToWidgets() GUI_Capture(GUI:InputText("##Required Range",gTestNavRange),"gTestNavRange");
	GUI:AlignFirstTextHeightToWidgets() GUI_Capture(GUI:InputText("##Map ID",gTestMapID),"gTestMapID");
	GUI:AlignFirstTextHeightToWidgets() GUI_Capture(GUI:InputText("##NPC ID",gTestNPCID),"gTestNPCID");
	GUI:AlignFirstTextHeightToWidgets() GUI_Capture(GUI:InputText("##X",gTestMapX),"gTestMapX");
	GUI:AlignFirstTextHeightToWidgets() GUI_Capture(GUI:InputText("##Y",gTestMapY),"gTestMapY");
	GUI:AlignFirstTextHeightToWidgets() GUI_Capture(GUI:InputText("##Z",gTestMapZ),"gTestMapZ");
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(tonumber(ffxiv_task_test.metricDist2d))
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(tonumber(ffxiv_task_test.metricDist3d))
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(ffxiv_task_test.metricReachableText)
	
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(tostring(GetMapSection(Player.localmapid, Player.pos)))
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(tostring(GetMapSection(Player.localmapid, {x = tonumber(gTestMapX), y = tonumber(gTestMapY), z = tonumber(gTestMapZ)})))
					
	GUI:PopItemWidth()
	GUI:Columns()
	local FullWidth = GUI:GetContentRegionAvail()
	local itemSpacingX = GUI:GetStyle().itemspacing.x
	local halfWidth = (FullWidth - itemSpacingX) / 2
	if (halfWidth < 80) then
		halfWidth = FullWidth
	end
	_NavTestNormalizeContext()
	GUI:PushItemWidth(halfWidth)
	if (GUI_Combo("##Task Context", "gTestTaskContextIndex", "gTestTaskContext", ffxiv_task_test.contexts)) then
		_NavTestNormalizeContext()
		ffxiv_task_test.ResetLaunchGuards()
	end
	GUI:PopItemWidth()
	if (halfWidth < FullWidth) then
		GUI:SameLine()
	end
	if (GUI:Button("Get Current Pos",halfWidth,20)) then
		ffxiv_task_test.GetCurrentPosition()
	end
	if (GUI:Button("Get Target Pos",FullWidth,20)) then
		ffxiv_task_test.GetTargetPosition()
	end
	if (GUI:Button("Get Random Pos",FullWidth,20)) then
		ffxiv_task_test.GetRandomPosition()
	end
	if (GUI:Button("Get Closest Mesh Pos",FullWidth,20)) then
		local newpos = FindClosestMesh({x = gTestMapX, y = gTestMapY, z = gTestMapZ},100,true)
		 gTestMapX = IsNull(newpos.x,gTestMapX)
		 gTestMapY = IsNull(newpos.y,gTestMapY)
		 gTestMapZ = IsNull(newpos.z,gTestMapZ)
		 ffxiv_task_test.ResetLaunchGuards()
	end
	GUI:EndChild()
end

function ffxiv_task_test.GetCurrentPosition()
	local mapid = Player.localmapid
	local pos = Player.pos
	local savePos = { x = pos.x, y = pos.y, z = pos.z }
	local meshPos = FindClosestMesh(savePos, 4, true)
	if (meshPos and meshPos.x ~= nil and meshPos.y ~= nil and meshPos.z ~= nil and meshPos.distance ~= nil and meshPos.distance < 2) then
		savePos = { x = meshPos.x, y = meshPos.y, z = meshPos.z }
	end
	
	gTestMapX = savePos.x
	gTestMapY = savePos.y
	gTestMapZ = savePos.z
	gTestMapID = mapid
	ffxiv_task_test.ResetLaunchGuards()
	
	GUI_Set("gTestMapID",gTestMapID)
	GUI_Set("gTestNPCID",0)
	GUI_Set("gTestMapX",gTestMapX)
	GUI_Set("gTestMapY",gTestMapY)
	GUI_Set("gTestMapZ",gTestMapZ)
end

function ffxiv_task_test.GetTargetPosition()
	local target = Player:GetTarget()
	if (target) then
		local mapid = Player.localmapid
		local pos = target.pos
		
		gTestNPCID = target.id
		gTestMapX = pos.x
		gTestMapY = pos.y
		gTestMapZ = pos.z
		gTestMapID = mapid
		ffxiv_task_test.ResetLaunchGuards()
		
		GUI_Set("gTestMapID",gTestMapID)
		GUI_Set("gTestNPCID",gTestNPCID)
		GUI_Set("gTestMapX",gTestMapX)
		GUI_Set("gTestMapY",gTestMapY)
		GUI_Set("gTestMapZ",gTestMapZ)
	end
end

function ffxiv_task_test.GetRandomPosition()
	local mapid = Player.localmapid
	local pos = NavigationManager:GetRandomPoint()
	if (table.size(pos) > 0 ) then
	
		gTestMapX = pos.x
		gTestMapY = pos.y
		gTestMapZ = pos.z
		gTestMapID = mapid
		ffxiv_task_test.ResetLaunchGuards()
		
		GUI_Set("gTestMapID",gTestMapID)
		GUI_Set("gTestMapX",gTestMapX)
		GUI_Set("gTestMapY",gTestMapY)
		GUI_Set("gTestMapZ",gTestMapZ)
	end
end

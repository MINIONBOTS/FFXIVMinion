ffxiv_task_test = inheritsFrom(ml_task)
ffxiv_task_test.lastTick = 0
ffxiv_task_test.lastPathCheck = 0
ffxiv_task_test.flightMesh = {}
ffxiv_task_test.lastTaskSet = {}
ffxiv_task_test.lastRect = {}

local INF = 1/0
local cachedPaths = nil
local insert = table.insert
local atan2 = math.atan2
local asin = math.asin
local dist_3d = PDistance3D

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
	ml_task_hub:CurrentTask():AddSubTask(task)
end

c_gotopostest = inheritsFrom( ml_cause )
e_gotopostest = inheritsFrom( ml_effect )
c_gotopostest.pos = {}
c_gotopostest.path = {}
function c_gotopostest:evaluate()
	c_gotopostest.pos = {}
	c_gotopostest.path = {}

	local mapID = tonumber(gTestMapID)
	if (Player.localmapid == mapID) then
		local ppos = Player.pos
		local pos = {}
		pos.x = tonumber(gTestMapX)
		pos.y = tonumber(gTestMapY)
		pos.z = tonumber(gTestMapZ)
		
		local dist = Distance3D(ppos.x, ppos.y, ppos.z, pos.x, pos.y, pos.z)
		if (dist > 3) then
			c_gotopostest.pos = pos
			return true
		end
	end
	return false
end
function e_gotopostest:execute()
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = c_gotopostest.pos 
	newTask.range = 1
	newTask.remainMounted = true
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_gotonpctest = inheritsFrom( ml_cause )
e_gotonpctest = inheritsFrom( ml_effect )
c_gotonpctest.pos = {}
function c_gotonpctest:evaluate()
	c_gotonpctest.pos = {}
	c_gotonpctest.path = {}

	local mapID = 397
	if (Player.localmapid == mapID) then
		local ppos = Player.pos
		local pos = {}
		pos.x = 474.8
		pos.y = 217.9
		pos.z = 708.5
		
		c_gotonpctest.pos = pos
		return true
	end
	return false
end
function e_gotonpctest:execute()
	local newTask = ffxiv_task_movetointeract.Create()
	newTask.contentid = 71
	newTask.pos = c_gotonpctest.pos
	newTask.use3d = true
	--newTask.interactRange = 1
	
	ml_task_hub:CurrentTask():AddSubTask(newTask)
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
	gTestMapX = ffxivminion.GetSetting("gTestMapX","")
	gTestMapY = ffxivminion.GetSetting("gTestMapY","")
	gTestMapZ = ffxivminion.GetSetting("gTestMapZ","")
end

ffxiv_task_test.GUI = {
	x = 0,
	y = 0, 
	height = 0,
	width = 0,
}

function ffxiv_task_test:Draw()
	local fontSize = GUI:GetWindowFontSize()
	local windowPaddingY = ml_gui.style.current.windowpadding.y
	local framePaddingY = ml_gui.style.current.framepadding.y
	local itemSpacingY = ml_gui.style.current.itemspacing.y
	
	GUI:BeginChild("##header-status",0,GUI_GetFrameHeight(6),true)
	GUI:PushItemWidth(120)					
	
	GUI:Checkbox(GetString("botEnabled"),FFXIV_Common_BotRunning)
	GUI_Capture(GUI:InputText("Map ID",gTestMapID),"gTestMapID");
	GUI_Capture(GUI:InputText("X",gTestMapX),"gTestMapX");
	GUI_Capture(GUI:InputText("Y",gTestMapY),"gTestMapY");
	GUI_Capture(GUI:InputText("Z",gTestMapZ),"gTestMapZ");	
	if (GUI:Button("Get Current Pos")) then
		ffxiv_task_test.GetCurrentPosition()
	end
	
	GUI:PopItemWidth()
	GUI:EndChild()
end

function ffxiv_task_test.GetCurrentPosition()
	local mapid = Player.localmapid
	local pos = Player.pos
	
	gTestMapX = pos.x
	gTestMapY = pos.y
	gTestMapZ = pos.z
	gTestMapID = mapid
	
	GUI_Set("gTestMapID",gTestMapID)
	GUI_Set("gTestMapX",gTestMapX)
	GUI_Set("gTestMapY",gTestMapY)
	GUI_Set("gTestMapZ",gTestMapZ)
end

function ffxiv_task_test.TestShopVendor()
	local vendor = AceLib.API.Items.FindNearestPurchaseLocation(2586)
	if (vendor) then
		local mapid = vendor.mapid
		local pos = vendor.pos
		
		gTestMapX = pos.x
		gTestMapY = pos.y
		gTestMapZ = pos.z
		gTestMapID = mapid
		
		Settings.FFXIVMINION.gTestMapID = gTestMapID
		Settings.FFXIVMINION.gTestMapX = gTestMapX
		Settings.FFXIVMINION.gTestMapY = gTestMapY
		Settings.FFXIVMINION.gTestMapZ = gTestMapZ
		
		local newTask = ffxiv_task_test.Create()
		ml_task_hub:ClearQueues()
		ml_task_hub.shouldRun = true
		FFXIV_Common_BotRunning = "1"
		ml_task_hub:Add(newTask, LONG_TERM_GOAL, TP_ASAP)
	else
		d("Did not find a vendor for the item.")
	end
end
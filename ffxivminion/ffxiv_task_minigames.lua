ffxiv_task_minigames = {}
MiniGames = {}
MiniGames.lastTick = 0
MiniGames.gameDetails = {}
MiniGames.restPositions = {
	{x = -0.1, y = 3.4, z = -0.1, minrad = 4.3, maxrad = 13},
	{x = -46.96, y = 1.6, z = 29.87, minrad = 5, maxrad = 23},
}
MiniGames.vendors = {
	["cuff"] = {
		{id = 2005029, mapid = 388, x = 9.75, y = 0.03, z = -33.43},
		{id = 2005029, mapid = 144, x = 25.17, y = -5, z = -48.85},
		{id = 2005029, mapid = 144, x = 14.35, y = -5, z = -54.01},
	},
	["toss"] = {
		{id = 2004804, mapid = 144, x = 41.39, y = 4, z = 18},
		{id = 2004804, mapid = 144, x = 37.18, y = 4, z = 17.70},
	},
	["striker"] = {
		{ id = 2005035, mapid = 144, x = 25.28, y = 4, z = 89.28},
		{ id = 2005035, mapid = 144, x = 24.55, y = 4, z = 99.63},
	},
}
MiniGames.optionGroups = {
	[1] = {
		["gMGOptionPunch"] = { id = 2005029, x = 25.17, y = -5, z = -48.85},
		["gMGOptionToss"] = { id = 2004804, x = 37.18, y = 4, z = 17.70},
		["gMGOptionHammer"] = { id = 2005035, x = 25.28, y = 4, z = 89.28},
	}
}

function MiniGames.ModuleInit()
	ffxivminion.AddMode("MiniGames", ffxiv_task_minigames)
end
function MiniGames.OnUpdate( event, tickcount )
	if (TimeSince(MiniGames.lastTick) >= 10) then
		MiniGames.lastTick = tickcount
		if (FFXIV_Common_BotRunning == true) then
			if (ml_task_hub:CurrentTask() and ml_task_hub:CurrentTask().awaitingWin and 
				(IsControlOpen("GoldSaucerReward") or TimeSince(ml_task_hub:CurrentTask().lastPlay) > 45000)) 
			then
				local delay = tonumber(gMGGameDelay)
				local mindelay = delay - (delay * .20)
				local maxdelay = delay + (delay * .10)
				ml_global_information.Await(math.random(mindelay,maxdelay))
				ml_task_hub:CurrentTask().catchWin = false
				ml_task_hub:CurrentTask().awaitingWin = false
				return
			end
			
			if (ml_task_hub:CurrentTask() and ml_task_hub:CurrentTask().catchWin) then
				local result = nil
				if (gMGOptionPunch == true) then
					result = Hacks:WinMiniGame()
				elseif (gMGOptionToss == true) then
					result = Hacks:WinMiniGame()
				elseif (gMGOptionHammer == true) then
					result = Hacks:WinMiniGame()
					if (result == 2) then
						ml_task_hub:CurrentTask().catchWin = false
					end
				end
			end
		end
	end
end

ffxiv_task_minigames = inheritsFrom(ml_task)
ffxiv_task_minigames.name = "LT_MINIGAMES"
function ffxiv_task_minigames.Create()
    local newinst = inheritsFrom(ffxiv_task_minigames)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    newinst.name = "LT_MINIGAMES"
	newinst.delay = 0
	newinst.awaitingWin = false
	newinst.catchWin = false
	newinst.randomizeTimer = Now()
	newinst.lastRest = Now()
	newinst.invalidState = 0
    
    return newinst
end

-- New GUI.
function ffxiv_task_minigames:UIInit()
	gMGOptionPunch = ffxivminion.GetSetting("gMGOptionPunch",true)
	gMGOptionToss = ffxivminion.GetSetting("gMGOptionToss",false)
	gMGOptionHammer = ffxivminion.GetSetting("gMGOptionHammer",false)
	gMGRandomize = ffxivminion.GetSetting("gMGRandomize",false)
	gMGRandomizeTimeMin = ffxivminion.GetSetting("gMGRandomizeTimeMin",2)
	gMGRandomizeTimeMax = ffxivminion.GetSetting("gMGRandomizeTimeMax",15)
	gMGPlayTime = ffxivminion.GetSetting("gMGPlayTime",15)
	gMGRestTime = ffxivminion.GetSetting("gMGRestTime",1)
	gMGGameDelay = ffxivminion.GetSetting("gMGGameDelay",1000)
	
	self.GUI.main_tabs = GUI_CreateTabs(GetString("status")..",Games,Safety",false)
end

ffxiv_task_minigames.GUI = {
	x = 0,
	y = 0, 
	height = 0,
	width = 0,
}

function ffxiv_task_minigames:Draw()
	local fontSize = GUI:GetWindowFontSize()
	local windowPaddingY = ml_gui.style.current.windowpadding.y
	local framePaddingY = ml_gui.style.current.framepadding.y
	local itemSpacingY = ml_gui.style.current.itemspacing.y
	
	GUI_DrawTabs(self.GUI.main_tabs)
	local tabs = self.GUI.main_tabs
	
	if (tabs.tabs[1].isselected) then
		GUI:BeginChild("##header-status",0,GUI_GetFrameHeight(5),true)
		GUI:PushItemWidth(120)	

		GUI:Checkbox(GetString("botEnabled"),FFXIV_Common_BotRunning)
		
		GUI:PopItemWidth()
		GUI:EndChild()
	end
	
	if (tabs.tabs[2].isselected) then
		GUI:BeginChild("##header-games",0,GUI_GetFrameHeight(6),true)
		GUI:PushItemWidth(120)				

		GUI_Capture(GUI:Checkbox("Cuff-a-Cur",gMGOptionPunch),"gMGOptionPunch", 
			function ()
				GUI_Set("gMGOptionToss",false)
				GUI_Set("gMGOptionHammer",false)
			end
		);
		GUI_Capture(GUI:Checkbox("Monster Toss",gMGOptionToss),"gMGOptionToss", 
			function ()
				GUI_Set("gMGOptionPunch",false)
				GUI_Set("gMGOptionHammer",false)
			end
		);
		GUI_Capture(GUI:Checkbox("Tower Striker",gMGOptionHammer),"gMGOptionHammer", 
			function ()
				GUI_Set("gMGOptionPunch",false)
				GUI_Set("gMGOptionToss",false)
			end
		);
		
		GUI:PopItemWidth()
		GUI:EndChild()
	end
	
	if (tabs.tabs[3].isselected) then
		GUI:BeginChild("##header-safety",0,GUI_GetFrameHeight(6),true)
		GUI:PushItemWidth(120)		

		GUI_Capture(GUI:Checkbox("Randomize Game",gMGRandomize),"gMGRandomize");
		GUI_DrawIntMinMax("Random Time Min (m)","gMGRandomizeTimeMin",1,5,0,120)
		GUI_DrawIntMinMax("Random Time Max (m)","gMGRandomizeTimeMax",1,5,0,120)
		GUI_DrawIntMinMax("Play Time (m)","gMGPlayTime",1,5,0,360)
		GUI_DrawIntMinMax("Rest Time (m)","gMGRestTime",1,5,0,360)
		GUI_DrawIntMinMax("Post-Game Delay (ms)","gMGRestTime",100,500,0,10000)
		
		GUI:PopItemWidth()
		GUI:EndChild()
	end
end

function ffxiv_task_minigames:Init()
    --init Process() cnes
	local ke_rest = ml_element:create( "RestBreak", c_restbreak, e_restbreak, 50 )
    self:add(ke_rest, self.process_elements)
	
	local ke_randomizeGame = ml_element:create( "RandomizeGame", c_randomizegame, e_randomizegame, 40 )
    self:add(ke_randomizeGame, self.process_elements)
	
	local ke_selectPlay = ml_element:create( "SelectPlay", c_selectplay, e_selectplay, 30 )
    self:add(ke_selectPlay, self.process_elements)
	
	local ke_interactGameVendor = ml_element:create( "InteractGameVendor", c_interactgamevendor, e_interactgamevendor, 20 )
    self:add(ke_interactGameVendor, self.process_elements)
	
	local ke_moveToVendor = ml_element:create( "MoveToVendor", c_movegamevendor, e_movegamevendor, 15 )
    self:add(ke_moveToVendor, self.process_elements)
	
	local ke_moveToVendorArea = ml_element:create( "MoveToVendorArea", c_movegamevendorarea, e_movegamevendorarea, 10 )
    self:add(ke_moveToVendorArea, self.process_elements)

    self:AddTaskCheckCEs()
end

function ffxiv_task_minigames:task_complete_eval()
	if (MIsLocked() or MIsLoading()) then
		return false
	end
	
	if (Player.localmapid ~= 144 and Player.localmapid ~= 388) then
		self.invalidState = 1
		return true
	end
	
	local noGamesSelected = true
	local gamesGroup = MiniGames.optionGroups[1]
	for varName,venID in pairs(gamesGroup) do
		if (_G[varName] == true) then
			noGamesSelected = false
		end
		if (not noGamesSelected) then
			break
		end
	end
	if (noGamesSelected) then
		self.invalidState = 2
		return true
	end
	
	return false
end

function ffxiv_task_minigames:task_complete_execute()
	if (FFXIV_Common_BotRunning == true) then
		ml_global_information:ToggleRun()
	end
end

function ffxiv_task_minigames.IsVendorTargetable()
	local vendorID = nil
	local gamesGroup = MiniGames.optionGroups[1]
	for varName,gameData in pairs(gamesGroup) do
		if (_G[varName] == true) then
			vendorID = gameData.id
		end
		if (vendorID) then
			break
		end
	end
	
	local vendors = EntityList("shortestpath,contentid="..tostring(vendorID))
	if (ValidTable(vendors)) then
		local i,entity = next(vendors)
		if (entity and entity.targetable) then
			return true
		end
	end
	
	return false
end

c_movegamevendorarea = inheritsFrom( ml_cause )
e_movegamevendorarea = inheritsFrom( ml_effect )
c_movegamevendorarea.pos = {}
function c_movegamevendorarea:evaluate()
	if (ml_task_hub:CurrentTask().awaitingWin or Now() < ml_task_hub:CurrentTask().delay) then
		return false
	end
	
	c_movegamevendorarea.pos = {}
	
	local pos = nil
	local gamesGroup = MiniGames.optionGroups[1]
	for varName,gameData in pairs(gamesGroup) do
		if (_G[varName] == true) then
			pos = { x = gameData.x, y = gameData.y, z = gameData.z }
		end
		if (pos) then
			break
		end
	end
	
	if (pos) then
		local ppos = Player.pos
		local dist = Distance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
		if (dist > 20) then
			c_movegamevendorarea.pos = pos
			return true
		end
	end
	
	return false
end
function e_movegamevendorarea:execute()
	local newTask = ffxiv_task_movetopos.Create()
	newTask.pos = c_movegamevendorarea.pos
	newTask.use3d = true

	if (gTeleport == true) then
		newTask.useTeleport = true
	end
	
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_movegamevendor = inheritsFrom( ml_cause )
e_movegamevendor = inheritsFrom( ml_effect )
c_movegamevendor.id = 0
c_movegamevendor.pos = {}
function c_movegamevendor:evaluate()
	if (ml_task_hub:CurrentTask().awaitingWin or Now() < ml_task_hub:CurrentTask().delay) then
		return false
	end
	
	c_movegamevendor.id = 0
	c_movegamevendor.pos = {}
	
	local vendorID = nil
	local gamesGroup = MiniGames.optionGroups[1]
	for varName,gameData in pairs(gamesGroup) do
		if (_G[varName] == true) then
			vendorID = gameData.id
		end
		if (vendorID) then
			break
		end
	end
	
	local vendors = EntityList("shortestpath,contentid="..tostring(vendorID))
	if (ValidTable(vendors)) then
		local i,entity = next(vendors)
		if (entity and entity.targetable) then
			
			local ppos = Player.pos
			local epos = entity.pos
			local dist3d = Distance3D(ppos.x,ppos.y,ppos.z,epos.x,epos.y,epos.z)
			
			if (dist3d >= 3.7) then
				c_movegamevendor.id = entity.contentid
				c_movegamevendor.pos = entity.pos
				return true
			end
		end
	end
	
	return false
end
function e_movegamevendor:execute()
	local newTask = ffxiv_task_movetointeract.Create()
	newTask.contentid = c_movegamevendor.id
	newTask.pos = c_movegamevendor.pos
	newTask.use3d = true
	newTask.interactRange = 3.7
	
	if (gTeleport == true) then
		newTask.useTeleport = true
	end
	
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_restbreak = inheritsFrom( ml_cause )
e_restbreak = inheritsFrom( ml_effect )
function c_restbreak:evaluate()
	if (gMGRestTime ~= 0) then
		if (ml_task_hub:CurrentTask().awaitingWin or IsControlOpen("SelectString") or 
			TimeSince(ml_task_hub:CurrentTask().lastRest) < ((tonumber(gMGPlayTime) * 60 * 1000))) then
			return false
		else
			return true
		end
	end
	
	return false
end
function e_restbreak:execute()
	local randomSeed = math.random(1,2)
	local restPosition = MiniGames.restPositions[randomSeed]
	
	local newPos = NavigationManager:GetRandomPointOnCircle(restPosition.x,restPosition.y,restPosition.z,restPosition.minrad,restPosition.maxrad)
	if (ValidTable(newPos)) then
		local p = NavigationManager:GetClosestPointOnMesh(newPos)
		if (p) then
			local newTask = ffxiv_task_movetopos.Create()
			newTask.pos = p
			newTask.use3d = true
			
			if (gTeleport == true) then
				newTask.useTeleport = true
			end
			
			newTask.task_complete_execute = function()
				ml_task_hub:CurrentTask().completed = true
				ml_global_information.Await(tonumber(gMGRestTime) * 60 * 1000)
				ml_task_hub:CurrentTask():ParentTask().lastRest = Now() + (tonumber(gMGRestTime) * 60 * 1000)
			end
			
			ml_task_hub:CurrentTask():AddSubTask(newTask)
		else
			ml_global_information.Await(tonumber(gMGRestTime) * 60 * 1000)
			ml_task_hub:CurrentTask().lastRest = Now() + (tonumber(gMGRestTime) * 60 * 1000)
		end
	end	
end

c_randomizegame = inheritsFrom( ml_cause )
e_randomizegame = inheritsFrom( ml_effect )
function c_randomizegame:evaluate()
	local minRandom = tonumber(gMGRandomizeTimeMin) * 60 * 1000
	local maxRandom = tonumber(gMGRandomizeTimeMax) * 60 * 1000
	
	local randomizeSeed = math.random(minRandom,maxRandom)
	if (ml_task_hub:CurrentTask().awaitingWin or IsControlOpen("SelectString") or TimeSince(ml_task_hub:CurrentTask().randomizeTimer) < randomizeSeed) then
		return false
	end
	
	if (gMGRandomize == true) then
		return true
	end
	
	return false
end
function e_randomizegame:execute()
	local choices = {}
	local gamesGroup = MiniGames.optionGroups[1]
	for varName,gameData in pairs(gamesGroup) do
		if (_G[varName] == false) then
			table.insert(choices,varName)
		end
	end
	
	local randomSeed = math.random(1,2)
	local newGame = choices[randomSeed]
	
	for varName,gameData in pairs(gamesGroup) do
		if (newGame == varName) then
			_G[varName] = true
		else
			_G[varName] = false
		end
	end
	ml_task_hub:CurrentTask().randomizeTimer = Now()
end

c_selectplay = inheritsFrom( ml_cause )
e_selectplay = inheritsFrom( ml_effect )
function c_selectplay:evaluate()
	if (ml_task_hub:CurrentTask().awaitingWin or Now() < ml_task_hub:CurrentTask().delay) then
		return false
	end
	
	if (IsControlOpen("SelectString")) then
		return true
	end
	
	return false
end
function e_selectplay:execute()
	if (SelectConversationIndex(1)) then
		ml_task_hub:CurrentTask().awaitingWin = true
		ml_task_hub:CurrentTask().catchWin = true
	end
	ml_task_hub:CurrentTask().lastPlay = Now()
	ml_task_hub:CurrentTask().delay = Now() + 100
end

c_interactgamevendor = inheritsFrom( ml_cause )
e_interactgamevendor = inheritsFrom( ml_effect )
e_interactgamevendor.id = 0
function c_interactgamevendor:evaluate()
	if (ml_task_hub:CurrentTask().awaitingWin or IsControlOpen("SelectString") or Now() < ml_task_hub:CurrentTask().delay) then
		return false
	end
	
	local vendorID = nil
	local gamesGroup = MiniGames.optionGroups[1]
	for varName,gameData in pairs(gamesGroup) do
		if (_G[varName] == true) then
			vendorID = gameData.id
		end
		if (vendorID) then
			break
		end
	end
	
	local vendors = EntityList("shortestpath,contentid="..tostring(vendorID))
	if (ValidTable(vendors)) then
		local i,entity = next(vendors)
		if (entity and entity.targetable) then
			
			local ppos = Player.pos
			local epos = entity.pos
			local dist3d = Distance3D(ppos.x,ppos.y,ppos.z,epos.x,epos.y,epos.z)
			
			if (dist3d < 3.8) then
				e_interactgamevendor.id = entity.id
				return true
			end
		end
	end
	
	return false
end
function e_interactgamevendor:execute()
	Player:Interact(e_interactgamevendor.id)
	ml_task_hub:CurrentTask().delay = Now() + math.random(1000,1500)
end

RegisterEventHandler("Module.Initalize",MiniGames.ModuleInit)
RegisterEventHandler("Gameloop.Update",MiniGames.OnUpdate)
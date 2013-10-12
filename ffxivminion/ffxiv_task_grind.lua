ffxiv_task_grind = inheritsFrom(ml_task)
ffxiv_task_grind.name = "LT_GRIND"
ffxiv_task_grind.evacPoint = {0, 0, 0}
ffxiv_task_grind.ticks = 0
ffxiv_task_grind.blTicks = 0
gFateID = 0
gFateBlacklist = {}

function ffxiv_task_grind:Create()
    local newinst = inheritsFrom(ffxiv_task_grind)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_grind members
    newinst.name = "LT_GRIND"
    newinst.targetid = 0
    newinst.markerTime = 0
    newinst.currentMarker = false
    newinst.previousMarker = false
    
    --this is the targeting function that will be used for the generic KillTarget task
    newinst.targetFunction = GetNearestGrindAttackable
    
    return newinst
end

function ffxiv_task_grind:Init()
    --init ProcessOverWatch() elements
	
	local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 20 )
	self:add( ke_dead, self.overwatch_elements)
	
	local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 15 )
	self:add( ke_flee, self.overwatch_elements)
	
    --init Process() cnes
	local ke_addFate = ml_element:create( "AddFate", c_add_fate, e_add_fate, 25 )
	self:add(ke_addFate, self.process_elements)

	local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_killtarget, e_add_killtarget, 15 )
	self:add(ke_addKillTarget, self.process_elements)
   
    --nextmarker defined in ffxiv_task_gather.lua
    local ke_nextMarker = ml_element:create( "NextMarker", c_nextmarker, e_nextmarker, 20 )
	self:add( ke_nextMarker, self.process_elements)
    
    local ke_fateWait = ml_element:create( "FateWait", c_fatewait, e_fatewait, 10 )
	self:add(ke_fateWait, self.process_elements)
	
	local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 30 )
	self:add( ke_rest, self.process_elements)
	
	local ke_mobAggro = ml_element:create( "MobAggro", c_mobaggro, e_mobaggro, 35 )
	--self:add(ke_mobAggro, self.process_elements)
	
	local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 25 )
	self:add( ke_returnToMarker, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_grind:OnSleep()

end

function ffxiv_task_grind:OnTerminate()

end

function ffxiv_task_grind:IsGoodToAbort()

end

function ffxiv_task_grind.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		if ( 	k == "gDoFates" or
				k == "gFatesOnly" or
                k == "gIgnoreGrindLvl" or
                k == "gMinFateLevel" or
                k == "gMaxFateLevel" or
                k == "gMinMobLevel" or
                k == "gMaxMobLevel" or                 
				k == "gRestHP" or
				k == "gRestMP" or
				k == "gFleeHP" or
                k == "gFleeMP" or
                k == "gFateWaitPercent" or
                k == "gFateBLTimer")
        then
			Settings.FFXIVMINION[tostring(k)] = v
		end
	end
	GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

function ffxiv_task_grind.OnUpdateHandler( event, tickcount )
	if ( tickcount - ffxiv_task_grind.ticks > 500 ) then
	    -- update fate name in gui
		ffxiv_task_grind.ticks = tickcount
	    local fafound = false
        local falist = MapObject:GetFateList()
		if ( falist ) then
            local f = falist[tonumber(gFateIndex)]
            if ( f ) then
                fafound = true
                gFateName = f.name
                gFateID = f.id
            end
        end
        if (not fafound) then
            gFateName = ""
            gFateID = 0
        end
	end
	if (tickcount - ffxiv_task_grind.blTicks > 1000) then
        -- clear out temporarily blacklisted fates
        ffxiv_task_grind.blTicks = tickcount
        for id, timer in pairs(gFateBlacklist) do
			if id and timer and timer ~= true then
				if os.difftime(os.time(), timer) > 300 then
					gFateBlacklist[id] = nil
				end
			end
        end
    end
end

function ffxiv_task_grind.SetEvacPoint()
	if (gmeshname ~= "" and Player.onmesh) then
		mm.evacPoint = Player.pos
		mm.WriteMarkerList(gmeshname)
	end
end

function ffxiv_task_grind.BlacklistFate(arg)
    if (gFateName ~= "") then
        if (arg == "gBlacklistFateAddEvent") then
            gFateBlacklist[tonumber(gFateID)] = true
        elseif (arg == "gBlacklistFateRemEvent") then
            gFateBlacklist[tonumber(gFateID)] = nil
        end
        Settings.FFXIVMINION.gFateBlacklist = gFateBlacklist
    else
        ml_debug("No valid fate selected")
    end
end

-- UI settings etc
function ffxiv_task_grind.UIInit()
    -- Grind
	GUI_NewNumeric(ml_global_information.MainWindow.Name, "MaxMobLvl: +", "gMaxMobLevel", "Grind", "0", "10")
	GUI_NewNumeric(ml_global_information.MainWindow.Name, "MinMobLvl: -", "gMinMobLevel", "Grind", "0", "10")
	GUI_NewNumeric(ml_global_information.MainWindow.Name, "Rest HP%: ", "gRestHP", "Grind", "0", "100")
	GUI_NewNumeric(ml_global_information.MainWindow.Name, "Rest MP%: ", "gRestMP", "Grind", "0", "100")
	GUI_NewNumeric(ml_global_information.MainWindow.Name, "Flee HP%: ", "gFleeHP", "Grind", "0", "100")
	GUI_NewNumeric(ml_global_information.MainWindow.Name, "Flee MP%: ", "gFleeMP", "Grind", "0", "100")
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Do Fates", "gDoFates","Fates")
	GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Fates Only", "gFatesOnly","Fates")
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, "Ignore Marker Lvl", "gIgnoreGrindLvl","Grind")
	GUI_NewButton(ml_global_information.MainWindow.Name, "SetEvacPoint", "setEvacPointEvent","Grind")
    RegisterEventHandler("setEvacPointEvent",ffxiv_task_grind.SetEvacPoint)
    
    -- Fates
	GUI_NewNumeric(ml_global_information.MainWindow.Name, "MaxFateLvl: +", "gMaxFateLevel", "Fates", "0", "50")
	GUI_NewNumeric(ml_global_information.MainWindow.Name, "MinFateLvl: -", "gMinFateLevel", "Fates", "0", "50")
    GUI_NewNumeric(ml_global_information.MainWindow.Name, "WaitForComplete%: ", "gFateWaitPercent", "Fates", "0", "99")
	GUI_NewNumeric(ml_global_information.MainWindow.Name, "BlacklistTimer (s)", "gFateBLTimer", "Fates", "30","600")
    GUI_NewNumeric(ml_global_information.MainWindow.Name,"FateIndex","gFateIndex","Fates","1","5")
	GUI_NewField(ml_global_information.MainWindow.Name,"FateName","gFateName","Fates")
    GUI_NewButton(ml_global_information.MainWindow.Name, "BlacklistAdd", "gBlacklistFateAddEvent", "Fates")
    GUI_NewButton(ml_global_information.MainWindow.Name, "BlacklistRem", "gBlacklistFateRemEvent", "Fates")
	RegisterEventHandler("gBlacklistFateAddEvent", ffxiv_task_grind.BlacklistFate)
	RegisterEventHandler("gBlacklistFateRemEvent", ffxiv_task_grind.BlacklistFate)
    
	GUI_SizeWindow(ml_global_information.MainWindow.Name,250,400)
	
	if (Settings.FFXIVMINION.gDoFates == nil) then
		Settings.FFXIVMINION.gDoFates = "0"
	end
	
	if (Settings.FFXIVMINION.gFatesOnly == nil) then
		Settings.FFXIVMINION.gFatesOnly = "0"
	end
	
	if (Settings.FFXIVMINION.gMaxFateLevel == nil) then
		Settings.FFXIVMINION.gMaxFateLevel = "5"
	end
	
	if (Settings.FFXIVMINION.gMinFateLevel == nil) then
		Settings.FFXIVMINION.gMinFateLevel = "5"
	end
    
    if (Settings.FFXIVMINION.gMaxMobLevel == nil) then
		Settings.FFXIVMINION.gMaxMobLevel = "3"
	end
	
	if (Settings.FFXIVMINION.gMinMobLevel == nil) then
		Settings.FFXIVMINION.gMinMobLevel = "3"
	end
    
    if (Settings.FFXIVMINION.gIgnoreGrindLvl == nil) then
		Settings.FFXIVMINION.gIgnoreGrindLvl = "0"
	end
	
	if (Settings.FFXIVMINION.gRestHP == nil) then
		Settings.FFXIVMINION.gRestHP = "70"
	end
	
	if (Settings.FFXIVMINION.gRestMP == nil) then
		Settings.FFXIVMINION.gRestMP = "0"
	end
	
	if (Settings.FFXIVMINION.gFleeHP == nil) then
		Settings.FFXIVMINION.gFleeHP = "50"
	end
    
    if (Settings.FFXIVMINION.gFleeMP == nil) then
		Settings.FFXIVMINION.gFleeMP = "0"
	end
    
    if (Settings.FFXIVMINION.gFateWaitPercent == nil) then
		Settings.FFXIVMINION.gFateWaitPercent = "0"
	end
    
    if (Settings.FFXIVMINION.gFateBLTimer == nil) then
		Settings.FFXIVMINION.gFateBLTimer = "120"
	end
	
    if (Settings.FFXIVMINION.gFateBlacklist == nil) then
		Settings.FFXIVMINION.gFateBlacklist = {}
	end
    
	gDoFates = Settings.FFXIVMINION.gDoFates
	gFatesOnly = Settings.FFXIVMINION.gFatesOnly
	gMaxFateLevel = Settings.FFXIVMINION.gMaxFateLevel
	gMinFateLevel = Settings.FFXIVMINION.gMinFateLevel
    gMaxMobLevel = Settings.FFXIVMINION.gMaxMobLevel
	gMinMobLevel = Settings.FFXIVMINION.gMinMobLevel
	ffxiv_task_grind.evacPoint = Settings.FFXIVMINION.evacPoint
    gIgnoreGrindLvl = Settings.FFXIVMINION.gIgnoreGrindLvl
	gRestHP = Settings.FFXIVMINION.gRestHP
	gRestMP = Settings.FFXIVMINION.gRestMP
	gFleeHP = Settings.FFXIVMINION.gFleeHP
	gFleeMP = Settings.FFXIVMINION.gFleeMP
	gFateWaitPercent = Settings.FFXIVMINION.gFateWaitPercent
    gFateBLTimer = Settings.FFXIVMINION.gFateBLTimer
    gFateBlacklist = Settings.FFXIVMINION.gFateBlacklist
end

RegisterEventHandler("GUI.Update",ffxiv_task_grind.GUIVarUpdate)
RegisterEventHandler("Gameloop.Update",ffxiv_task_grind.OnUpdateHandler)
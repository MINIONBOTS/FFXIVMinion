ffxiv_task_fish = inheritsFrom(ml_task)
ffxiv_task_fish.name = "LT_FISH"
ffxiv_task_fish.pauseTimer = 0
ffxiv_task_fish.moveTimer = 0

function ffxiv_task_fish:Create()
    local newinst = inheritsFrom(ffxiv_task_fish)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
	
    return newinst
end

function ffxiv_task_fish:Init()
    --init Process() cnes
	
	--init ProcessOverWatch() cnes
	--local ke_killTask = ml_element:create( "AddKillTask", c_add_killtarget, e_add_killtarget, ml_effect.priorities.interrupt )
	--self:add(ke_killTask, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_fish:Process()
    -- move to the nearest fish spot
    if (not Player:IsMoving()) then
        local onPos = false
        for i, pos in pairs(mm.MarkerList["fishingSpot"]) do
            if Distance3D(Player.pos.x, Player.pos.y, Player.pos.z, pos.x, pos.y, pos.z) < 2 then
                onPos = true
            end
        end
        
        if (not onPos) then
            local destPos = mm.GetClosestMarkerPos(Player.pos, "fishingSpot")
            if (destPos ~= nil) then
                local newTask = ffxiv_task_movetopos:Create()
                newTask.pos = destPos
                newTask.range = 1.5
                newTask.doFacing = true
                ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_ASAP)
                gFishCC = "false"
                return
            end
        end
    end

	-- pause here after casting/hooking so we don't spam cast
	if (ml_global_information.Now >= self.pauseTimer) then    
		gFishState = tostring(Player:GetFishingState())	
		gFishCC = tostring(Skillbar:CanCast(289,Player.id))
		gFishBait = Player:GetBait()
        if (gFishBaitId == "0") then
            gFishBaitId = tostring(gFishBait)
        end

		local fs = tonumber(Player:GetFishingState())
		if (fs == 0 or fs == 4 and not Player:IsMoving() and gFishCC == "true") then
			if (fs == 0) then
				if (ffxiv_task_fish.moveTimer == 0) then
					ffxiv_task_fish.moveTimer = ml_global_information.Now + 3000
				else
					if (ffxiv_task_fish.moveTimer < ml_global_information.Now) then
						ffxiv_task_fish.moveTimer = 0
                        local destPos = mm.GetClosestMarkerPos(Player.pos, "fishSpot")
                        if (destPos ~= nil) then
                            local newTask = ffxiv_task_movetopos:Create()
                            newTask.pos = destPos
                            newTask.range = 1.5
                            newTask.doFacing = true
                            ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_ASAP)
                            return
                        end
						return
					end
				end
			end
			if(gFishBaitId ~= tostring(Player:GetBait())) then
                Player:SetBait(tonumber(gFishBaitId))
			end
			Skillbar:Cast(289) --fish skillid 2
			ffxiv_task_fish.pauseTimer = ml_global_information.Now + 2000
		elseif( fs == 5 ) then -- FISHSTATE_BITE
			Skillbar:Cast(296) -- Hook, skill 3   (129 is some other hook skillid ??
			ffxiv_task_fish.pauseTimer = ml_global_information.Now + 2000
			ffxiv_task_fish.moveTimer = 0
		end
	end
end

function ffxiv_task_fish:OnSleep()

end

function ffxiv_task_fish:OnTerminate()

end

function ffxiv_task_fish:IsGoodToAbort()

end

function ffxiv_task_fish.MoveNext()
    if (not Player:IsMoving()) then
        local destPos = mm.GetClosestMarkerPos(Player.pos, "fishingSpot")
        if (destPos ~= nil) then
            local newTask = ffxiv_task_movetopos:Create()
            newTask.pos = destPos
            newTask.range = 1.5
            newTask.doFacing = true
            ml_task_hub:Add(newTask, REACTIVE_GOAL, TP_ASAP)
            gFishCC = "false"
            return
        end
    end
end

-- UI settings etc
function ffxiv_task_fish.UIInit()
	GUI_NewField(ml_global_information.MainWindow.Name,"CurrentBaitID","gFishBait","Fish")
	GUI_NewField(ml_global_information.MainWindow.Name,"SetBaitID","gFishBaitId","Fish")
	GUI_NewField(ml_global_information.MainWindow.Name,"FishingState","gFishState","Fish")
	GUI_NewField(ml_global_information.MainWindow.Name,"CanCast","gFishCC","Fish")
	GUI_NewButton(ml_global_information.MainWindow.Name, "MoveToNextSpot", "ffxiv_task_fish.MoveNextEvent","Fish")
	RegisterEventHandler("ffxiv_task_fish.MoveNextEvent", ffxiv_task_fish.MoveNext)
	GUI_SizeWindow(ml_global_information.MainWindow.Name,250,400)
	
	if (Settings.FFXIVMINION.gFishBaitId == nil) then
		Settings.FFXIVMINION.gFishBaitId = 0
	end
	
	gFishBaitId = Settings.FFXIVMINION.gFishBaitId
	
	RegisterEventHandler("GUI.Update",ffxiv_task_fish.GUIVarUpdate)
end

function ffxiv_task_fish.GUIVarUpdate(Event, NewVals, OldVals)
	for k,v in pairs(NewVals) do
		if ( k == "gFishBaitId" ) then
			Settings.FFXIVMINION[tostring(k)] = v
		end
	end
	GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end
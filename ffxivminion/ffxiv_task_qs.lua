ffxiv_task_qs_wrapper = inheritsFrom(ml_task)
function ffxiv_task_qs_wrapper.Create()
	if (IsFighter(Player.job)) then
		ffxiv_task_qs_wrapper.Init = ffxiv_task_qs_grind.Init
		return ffxiv_task_qs_grind.Create()
	elseif (IsGatherer(Player.job)) then
		ffxiv_task_qs_wrapper.Init = ffxiv_task_qs_gather.Init
		return ffxiv_task_qs_gather.Create()
	elseif (IsCrafter(Player.job)) then
		ffxiv_task_qs_wrapper.Init = ffxiv_task_qs_craft.Init
		return ffxiv_task_qs_craft.Create()
	elseif (IsFisher(Player.job)) then
		ffxiv_task_qs_wrapper.Init = ffxiv_task_qs_fish.Init
		return ffxiv_task_qs_fish.Create()
	end
end

function ffxiv_task_qs_wrapper:Init()
	--to be overridden during Create()
end

function ffxiv_task_qs_wrapper.UIInit()
	--Add it to the main tracking table, so that we can save positions for it.
	ffxivminion.Windows.QuickStart = { id = "QuickStart", Name = GetString("quickStartMode"), x=50, y=50, width=210, height=350 }
	ffxivminion.CreateWindow(ffxivminion.Windows.QuickStart)

	if ( Settings.FFXIVMINION.gQSGrindMinLevel == nil ) then
        Settings.FFXIVMINION.gQSGrindMinLevel = "1"
    end
    if ( Settings.FFXIVMINION.gQSGrindMaxLevel == nil ) then
        Settings.FFXIVMINION.gQSGrindMaxLevel = "50"
    end
	if (Settings.FFXIVMINION.gQSGrindContent == nil) then
        Settings.FFXIVMINION.gQSGrindContent = ""
    end
	if (Settings.FFXIVMINION.gQSGatherNodeLevel == nil) then
        Settings.FFXIVMINION.gQSGatherNodeLevel = "5"
    end
	if (Settings.FFXIVMINION.gQSGatherContent == nil) then
        Settings.FFXIVMINION.gQSGatherContent = ""
    end
	if (Settings.FFXIVMINION.gQSGatherItem1 == nil) then
        Settings.FFXIVMINION.gQSGatherItem1 = ""
    end
	if (Settings.FFXIVMINION.gQSGatherItem2 == nil) then
        Settings.FFXIVMINION.gQSGatherItem2 = ""
    end
	if (Settings.FFXIVMINION.gUseMooch == nil) then
		Settings.FFXIVMINION.gUseMooch = "0"
	end
	
	local winName = GetString("quickStartMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].botMode,"gBotMode",group,"None")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].skillProfile,"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,strings[gCurrentLanguage].navmesh ,"gmeshname",group,ffxivminion.Strings.Meshes())
	GUI_NewCheckbox(winName,strings[gCurrentLanguage].botEnabled,"gBotRunning",group)
    
	local group = "Attack Settings"
    GUI_NewNumeric(winName,GetString("minLevel"),"gQSGrindMinLevel",group,"1","50")
    GUI_NewNumeric(winName,GetString("maxLevel"),"gQSGrindMaxLevel",group,"1","50")
    GUI_NewField(winName,GetString("contentIDEquals"),"gQSGrindContent",group)
	
	local group = "Fish Settings"
	GUI_NewCheckbox(winName,GetString("useMooch"),"gUseMooch",group)
	
	local group = "Gather Settings"
	GUI_NewNumeric(winName,GetString("minLevel"),"gQSGatherNodeLevel",group,"1","50")
	GUI_NewField(winName,GetString("selectItem1"),"gQSGatherItem1",group)	
	GUI_NewField(winName,GetString("selectItem2"),"gQSGatherItem2",group)	
    GUI_NewField(winName,GetString("contentIDEquals"),"gQSGatherContent",group)	
	
    gQSGrindMinLevel = Settings.FFXIVMINION.gQSGrindMinLevel
    gQSGrindMaxLevel = Settings.FFXIVMINION.gQSGrindMaxLevel
    gQSGrindContent = Settings.FFXIVMINION.gQSGrindContent
    gQSGatherNodeLevel = Settings.FFXIVMINION.gQSGatherNodeLevel
    gQSGatherContent = Settings.FFXIVMINION.gQSGatherContent
	gQSGatherItem1 = Settings.FFXIVMINION.gQSGatherItem1
	gQSGatherItem2 = Settings.FFXIVMINION.gQSGatherItem2
	gUseMooch =	Settings.FFXIVMINION.gUseMooch
	
	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	RegisterEventHandler("GUI.Update",ffxiv_task_qs_wrapper.GUIVarUpdate)
end

function ffxiv_task_qs_wrapper.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gQSGrindMinLevel" or
				k == "gQSGrindMaxLevel" or
				k == "gQSGrindContent" or
				k == "gQSGatherNodeLevel" or
				k == "gQSGatherContent" or
				k == "gQSGatherItem1" or
				k == "gQSGatherItem2" or
				k == "gUseMooch") 
		then
			SafeSetVar(tostring(k),v)
        end
    end
end

c_qskilltarget = inheritsFrom( ml_cause )
e_qskilltarget = inheritsFrom( ml_effect )
c_qskilltarget.targetid = 0
function c_qskilltarget:evaluate()
	if (ml_task_hub:CurrentTask().name == "LT_QS_GRIND" or ml_task_hub:CurrentTask().name == "MOVETOPOS") then
		local aggro = GetNearestAggro()
		if ValidTable(aggro) then
			if (aggro.hp.current > 0 and aggro.distance <= 30) then
				c_qskilltarget.targetid = aggro.id
				return true
			end
		end 
	end
	
	local target = ml_task_hub:ThisTask().targetFunction()
    if (ValidTable(target)) then
        if(target.hp.current > 0 and target.id ~= nil and target.id ~= 0) then
            c_qskilltarget.targetid = target.id
            return true
        end
    end
    
    return false
end
function e_qskilltarget:execute()
	local newTask = ml_task_hub:ThisTask().killFunction.Create()
	newTask.targetid = c_qskilltarget.targetid
	ml_task_hub:CurrentTask():AddSubTask(newTask)
end

c_returntoposition = inheritsFrom( ml_cause )
e_returntoposition = inheritsFrom( ml_effect )
function c_returntoposition:evaluate()	
    if (ml_task_hub:ThisTask().startingPosition) then
        local myPos = shallowcopy(Player.pos)
        local pos = ml_task_hub:ThisTask().startingPosition
        local distance = Distance2D(myPos.x, myPos.z, pos.x, pos.z)
		
		if (ml_task_hub:ThisTask().name == "LT_QS_GRIND") then
			local target = ml_task_hub:ThisTask().targetFunction()
			if (distance > 200 or (target == nil and distance > 15)) then
				return true
			end
		elseif (ml_task_hub:ThisTask().name == "LT_QS_GATHER") then
			local list = Player:GetGatherableSlotList()
			if (list ~= nil) then
				return false
			end
			local gatherable = EntityList:Get(ml_task_hub:ThisTask().gatherid)
			if (distance > 30 and (not gatherable or (gatherable and not gatherable.targetable))) then
				return true
			end
		end
    end
    
    return false
end
function e_returntoposition:execute()	
    local newTask = ffxiv_task_movetopos.Create()
    newTask.pos = ml_task_hub:ThisTask().startingPosition
    newTask.range = math.random(5,25)
    ml_task_hub:CurrentTask():AddSubTask(newTask)
end

function GetQuickGrindTarget()
	local huntString = gQSGrindContent
	local excludeString = GetBlacklistIDString()
	local block = 0
	local el = nil
	local nearestGrind = nil
	local nearestDistance = 9999
	local minLevel = gQSGrindMinLevel
	local maxLevel = gQSGrindMaxLevel
    
	if (not IsNullString(excludeString)) then
		el = EntityList("shortestpath,alive,attackable,onmesh,targetingme,fateid=0,exclude_contentid="..excludeString..",maxpathdistance=30") 
	else
		el = EntityList("shortestpath,alive,attackable,onmesh,targetingme,fateid=0,maxpathdistance=30") 
	end
	
	if ( el ) then
		local i,e = next(el)
		if (ValidTable(e) and e.uniqueid ~= 541) then
			return e
		end
	end	
	
	--Lowest health with aggro on anybody in player's party, non-fate mobs.
	--Can't use aggrolist for party because chocobo doesn't get included, will eventually get railroaded.
	local party = EntityList("myparty")
	if ( party ) then
		for i, member in pairs(party) do
			if (member.id and member.id ~= 0) then
				if (not IsNullString(excludeString)) then
					el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",fateid=0,exclude_contentid="..excludeString..",maxdistance=30")
				else
					el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(member.id)..",fateid=0,maxdistance=30")
				end
				
				if ( el ) then
					local i,e = next(el)
					if (ValidTable(e) and e.uniqueid ~= 541) then
						return e
					end
				end
			end
		end
	end
	
	if (ValidTable(Player.pet)) then
		if (not IsNullString(excludeString)) then
			el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(Player.pet.id)..",fateid=0,exclude_contentid="..excludeString..",maxdistance="..tostring(ml_global_information.AttackRange))
		else
			el = EntityList("lowesthealth,alive,attackable,onmesh,targeting="..tostring(Player.pet.id)..",fateid=0,maxdistance="..tostring(ml_global_information.AttackRange))
		end
		
		if ( el ) then
			local i,e = next(el)
			if (ValidTable(e) and e.uniqueid ~= 541) then
				return e
			end
		end
	end
	
	if (not IsNullString(huntString)) then
		el = EntityList("contentid="..huntString..",shortestpath,fateid=0,alive,attackable,onmesh")
		
		if ( el ) then
			local i,e = next(el)
			if (ValidTable(e) and e.uniqueid ~= 541) then
				if (e.targetid == 0 or e.targetid == Player.id) then
					return e
				end
			end
		end
	end
	
	if (IsNullString(huntString)) then
		if (not IsNullString(excludeString)) then
			el = EntityList("shortestpath,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0,exclude_contentid="..excludeString)
		else
			el = EntityList("shortestpath,alive,attackable,onmesh,maxdistance="..tostring(ml_global_information.AttackRange)..",minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0")
		end
		
		if ( el ) then
			local i,e = next(el)
			if (ValidTable(e) and e.uniqueid ~= 541) then
				return e
			end
		end
	
		if (not IsNullString(excludeString)) then
			el = EntityList("shortestpath,alive,attackable,onmesh,minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0,exclude_contentid="..excludeString)
		else
			el = EntityList("shortestpath,alive,attackable,onmesh,minlevel="..minLevel..",maxlevel="..maxLevel..",targeting=0,fateid=0")
		end
		
		if ( el ) then
			local i,e = next(el)
			if (ValidTable(e) and e.uniqueid ~= 541) then
				return e
			end
		end
	end
	
    return nil
end

ffxiv_task_qs_grind = inheritsFrom(ml_task)
function ffxiv_task_qs_grind.Create()
    local newinst = inheritsFrom(ffxiv_task_qs_grind)
	
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_grind members
    newinst.name = "LT_QS_GRIND"
    newinst.targetid = 0
	newinst.correctMap = Player.localmapid
	newinst.startingPosition = shallowcopy(Player.pos)
	newinst.killFunction = ffxiv_task_grindCombat
	newinst.targetFunction = GetQuickGrindTarget

    return newinst
end

function ffxiv_task_qs_grind:Init()
    --init ProcessOverWatch() elements
	local ke_returnToMap = ml_element:create( "ReturnToMap", c_returntomap, e_returntomap, 30 )
    self:add(ke_returnToMap, self.overwatch_elements)
	
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 25 )
    self:add(ke_dead, self.overwatch_elements)
    
    local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 15 )
    self:add(ke_flee, self.overwatch_elements)
    
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 14 )
    self:add(ke_rest, self.overwatch_elements)
    
    --local ke_addFate = ml_element:create( "AddFate", c_add_fate, e_add_fate, 10 )
    --self:add(ke_addFate, self.overwatch_elements)

    local ke_returnToPosition = ml_element:create( "ReturnToPosition", c_returntoposition, e_returntoposition, 25 )
    self:add(ke_returnToPosition, self.process_elements)
	
    local ke_addKillTarget = ml_element:create( "AddKillTarget", c_qskilltarget, e_qskilltarget, 15 )
    self:add(ke_addKillTarget, self.process_elements)
	
    --local ke_fateWait = ml_element:create( "FateWait", c_fatewait, e_fatewait, 10 )
    --self:add(ke_fateWait, self.process_elements)
  
    self:AddTaskCheckCEs()
end

function ffxiv_task_qs_grind:Process()
	if (IsLoading() or ml_mesh_mgr.meshLoading) then
		return false
	end
	
	if (TableSize(ml_task_hub:CurrentTask().process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(ml_task_hub:CurrentTask().process_elements)
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end

c_gathersimple = inheritsFrom( ml_cause )
e_gathersimple = inheritsFrom( ml_effect )
function c_gathersimple:evaluate()
    local list = Player:GetGatherableSlotList()
	if (list and ActionIsReady(1,10)) then
		return true
	end
	
	local node = EntityList:Get(ml_task_hub:ThisTask().gatherid)
    if (node and node.cangather and node.distance2d <= 2.5) then
		return true
    end
	
    return false
end
function e_gathersimple:execute()
	ffxiv_task_gather.timer = Now() + 2000
	
	if (Player.ismounted) then
		Dismount()
		return
	end
	
    local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
		local node = Player:GetTarget()
		if (not ValidTable(node) or not node.cangather) then
			return
		end
        
		-- reset fail timer
        if (ml_task_hub:CurrentTask().failedTimer ~= 0) then
            ml_task_hub:CurrentTask().failedTimer = 0
        end
		
        if ( gSMactive == "1") then
			if (ActionList:IsCasting()) then return end
            if (SkillMgr.Gather()) then
				ml_task_hub:CurrentTask().failedTimer = Now()
                return
            end
        end
		
		if (Now() > ml_task_hub:CurrentTask().interactTimer) then
			-- do 2 loops to allow prioritization of first item
			local item1 = gQSGatherItem1
			local item2 = gQSGatherItem2
			
			if (item1 ~= "") then
				for i, item in pairs(list) do
					local n = tonumber(item1)
					if (n ~= nil) then
						if (item.index == (n-1) and item.id ~= nil) then
							if (IsGardening(item.id) or IsMap(item.id)) then
								ml_error("Use the GatherGardening option for this marker to gather gardening items.")
								ml_error("Use the GatherMaps option for this marker to gather map items.")
								ml_error("Gardening and Map items set to slots will be ignored.")
							end
							if (not IsGardening(item.id) and not IsMap(item.id)) then
								Player:Gather(n-1)
								ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
								ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
								return
							end
						end
					else						
						if (item.name == item1) then
							if (IsGardening(item.id) or IsMap(item.id)) then
								ml_error("Use the GatherGardening option for this marker to gather gardening items.")
								ml_error("Use the GatherMaps option for this marker to gather map items.")
								ml_error("Gardening and Map items set to slots will be ignored.")
							end
							if (not IsGardening(item.id) and not IsMap(item.id)) then
								Player:Gather(item.index)
								ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
								ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
								return
							end
						end
					end
				end
			end
			
			if (item2 ~= "") then
				for i, item in pairs(list) do
					local n = tonumber(item2)
					if (n ~= nil) then
						if (item.index == (n-1) and item.id ~= nil) then
							if (IsGardening(item.id) or IsMap(item.id)) then
								ml_error("Use the GatherGardening option for this marker to gather gardening items.")
								ml_error("Use the GatherMaps option for this marker to gather map items.")
								ml_error("Gardening and Map items set to slots will be ignored.")
							end
							if (not IsGardening(item.id) and not IsMap(item.id)) then
								Player:Gather(n-1)
								ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
								ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
								return
							end
						end
					else
						if (item.name == item2) then
							if (IsGardening(item.id) or IsMap(item.id)) then
								ml_error("Use the GatherGardening option for this marker to gather gardening items.")
								ml_error("Use the GatherMaps option for this marker to gather map items.")
								ml_error("Gardening and Map items set to slots will be ignored.")
							end
							if (not IsGardening(item.id) and not IsMap(item.id)) then
								Player:Gather(item.index)
								ml_task_hub:CurrentTask().swingCount = ml_task_hub:CurrentTask().swingCount + 1
								ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
								return
							end
						end
					end
				end
			end
			
			-- just grab a random item otherwise
			for i, item in pairs(list) do
				if item.chance > 50 and not IsGardening(item.id) and not IsMap(item.id) then
					if (Player:Gather(item.index)) then
						ml_task_hub:CurrentTask().gatherTimer = ml_global_information.Now
						return
					end
				end
			end
		end
    else
        local node = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
        if ( node and node.cangather ) then
            local target = Player:GetTarget()
            if ( not ValidTable(target) or (target.id ~= node.id)) then
                Player:SetTarget(node.id)
            else
				Eat()
				if (ValidTable(ml_task_hub:ThisTask().currentMarker)) then
					local profile = ml_task_hub:CurrentTask().currentMarker:GetFieldValue(strings[gCurrentLanguage].skillProfile)
					if (profile and profile ~= "None") then
						SkillMgr.UseProfile(profile)
					end
				end
                Player:Interact(node.id)
				ffxiv_task_gather.gatherStarted = true
				ml_task_hub:CurrentTask().interactTimer = Now() + 1000
				ml_task_hub:CurrentTask().gatheredGardening = false
				ml_task_hub:CurrentTask().gatheredMap = false
				ml_task_hub:CurrentTask().rareCount = -1
				ml_task_hub:CurrentTask().mapCount = -1
				ml_task_hub:CurrentTask().swingCount = 0
				ml_task_hub:CurrentTask().itemsUncovered = false
				SkillMgr.prevSkillList = {}
                -- start fail timer
                if (ml_task_hub:CurrentTask().failedTimer == 0) then
                    ml_task_hub:CurrentTask().failedTimer = Now() + 12000
                elseif (Now() > ml_task_hub:CurrentTask().failedTimer) then
					ml_blacklist.AddBlacklistEntry(strings[gCurrentLanguage].gatherMode, node.id, node.name, Now() + 300*1000)
					ml_task_hub:CurrentTask().gatherid = 0
					ml_task_hub:CurrentTask().failedTimer = 0
				end
            end
        else
            --ml_debug(" EntityList:Get(ml_task_hub:CurrentTask().gatherid) returned no node!")
        end
    end
end

c_qsmovetogatherable = inheritsFrom( ml_cause )
e_qsmovetogatherable = inheritsFrom( ml_effect )
function c_qsmovetogatherable:evaluate()
	if (Now() < ffxiv_task_gather.timer) then
		return false
	end

	local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
        return false
    end
	
    if ( TimeSince(ml_task_hub:CurrentTask().gatherTimer) < 1500 ) then
        return false
    end
    
    if ( ml_task_hub:CurrentTask().gatherid ~= nil and ml_task_hub:CurrentTask().gatherid ~= 0 ) then
        local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
        if (gatherable and gatherable.cangather) then
            return true
        end
    end
    
    return false
end
function e_qsmovetogatherable:execute()
    -- reset idle timer
    ml_task_hub:CurrentTask().idleTimer = 0
    local pos = EntityList:Get(ml_task_hub:CurrentTask().gatherid).pos
    if (pos ~= nil and pos ~= 0) then
		--local newTask = ffxiv_task_movetopos.Create()
		local ppos = shallowcopy(Player.pos)
		local dist3d = Distance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
		if (gTeleport == "1" and dist3d > 10 and ShouldTeleport(pos)) then
			local eh = ConvertHeading(pos.h)
			local nodeFront = ConvertHeading((eh + (math.pi)))%(2*math.pi)
			local telePos = GetPosFromDistanceHeading(pos, 5, nodeFront)
			local p,dist = NavigationManager:GetClosestPointOnMesh(telePos,false)
			if (dist < 5) then
				GameHacks:TeleportToXYZ(tonumber(p.x),tonumber(p.y),tonumber(p.z))
				Player:SetFacing(pos.x,pos.y,pos.z)
				return
			end
		end
		
		local newTask = ffxiv_task_movetointeract.Create()
		newTask.pos = pos
		newTask.useTeleport = false
		newTask.interact = ml_task_hub:CurrentTask().gatherid
		newTask.use3d = true
		newTask.range = 3
		newTask.task_complete_execute = function()
			Player:Stop()
			ffxiv_task_gather.gatherStarted = true
			ffxiv_task_gather.timer = Now() + 500
			ml_task_hub:CurrentTask():ParentTask().interactTimer = Now() + 1000
			ml_task_hub:CurrentTask():ParentTask().failedTimer = Now()
			ml_task_hub:CurrentTask():ParentTask().gatheredGardening = false
			ml_task_hub:CurrentTask():ParentTask().gatheredMap = false
			ml_task_hub:CurrentTask():ParentTask().gatheredChocoFood = false
			ml_task_hub:CurrentTask():ParentTask().rareCount = -1
			ml_task_hub:CurrentTask():ParentTask().rareCount2 = -1
			ml_task_hub:CurrentTask():ParentTask().mapCount = -1
			ml_task_hub:CurrentTask():ParentTask().swingCount = 0
			ml_task_hub:CurrentTask():ParentTask().itemsUncovered = false
			SkillMgr.prevSkillList = {}
			ml_task_hub:ThisTask().completed = true
		end
		ml_task_hub:CurrentTask():AddSubTask(newTask)	
    end
end

c_qsfindgatherable = inheritsFrom( ml_cause )
e_qsfindgatherable = inheritsFrom( ml_effect )
function c_qsfindgatherable:evaluate()
	if (Now() < ffxiv_task_gather.timer) then
		return false
	end
	
	local list = Player:GetGatherableSlotList()
    if (list ~= nil) then
        return false
    end

    if ( ml_task_hub:CurrentTask().gatherid == nil or ml_task_hub:CurrentTask().gatherid == 0 ) then
        return true
    end
    
    local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
    if (gatherable) then
        if (not gatherable.cangather) then
            return true 
        end
	else
        return true
    end
    
    return false
end
function e_qsfindgatherable:execute()
    local minlevel = tonumber(gQSGatherNodeLevel)
    local maxlevel = tonumber(gQSGatherNodeLevel)
	if (minlevel and minlevel < 50) then
		minlevel = RoundUp(minlevel,5)
	end
	if (maxlevel and maxlevel < 50) then
		maxlevel = RoundUp(maxlevel,5)
	end
	
	ffxiv_task_gather.gatherStarted = false
    
    local gatherable = GetNearestGatherable(minlevel,maxlevel)
    if (gatherable ~= nil) then
		-- reset blacklist vars for a new node
		ml_task_hub:CurrentTask().failedTimer = 0		
		ml_task_hub:CurrentTask().gatheredMap = false
        ml_task_hub:CurrentTask().gatherid = gatherable.id
		ml_task_hub:CurrentTask().gatheruniqueid = gatherable.uniqueid		
    else
		d("No gatherable entities found nearby.")
    end
end

ffxiv_task_qs_gather = inheritsFrom(ml_task)
function ffxiv_task_qs_gather.Create()
    local newinst = inheritsFrom(ffxiv_task_qs_gather)
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_gather members
    newinst.name = "LT_QS_GATHER"
    newinst.gatherid = 0
	newinst.startingPosition = shallowcopy(Player.pos)
	
    newinst.gatherTimer = 0
	newinst.gatherDistance = 1.5
	newinst.maxGatherDistance = 100 -- for setting the range when the character is beeing considered "too far away from the gathermarker" where it would make him run back to the marker
	newinst.gatheredMap = false
	newinst.gatheredGardening = false
    newinst.idleTimer = 0
	newinst.swingCount = 0
	newinst.slotsTried = {}
	newinst.interactTimer = 0
	newinst.rareCount = -1
	newinst.mapCount = -1
    
    newinst.failedTimer = 0
    
    return newinst
end

function ffxiv_task_qs_gather:Init()
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 25 )
    self:add( ke_dead, self.overwatch_elements)
	
	local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 24 )
    self:add( ke_flee, self.overwatch_elements)
    
    local ke_stealth = ml_element:create( "Stealth", c_stealth, e_stealth, 23 )
    self:add( ke_stealth, self.overwatch_elements)
	
    local ke_findGatherable = ml_element:create( "FindGatherable", c_qsfindgatherable, e_qsfindgatherable, 15 )
    self:add(ke_findGatherable, self.process_elements)
	
    local ke_moveToGatherable = ml_element:create( "MoveToGatherable", c_qsmovetogatherable, e_qsmovetogatherable, 12 )
    self:add( ke_moveToGatherable, self.process_elements)
	
	local ke_returnToPosition = ml_element:create( "ReturnToPosition", c_returntoposition, e_returntoposition, 10)
    self:add(ke_returnToPosition, self.process_elements)
    
    local ke_gatherSimple = ml_element:create( "Gather", c_gathersimple, e_gathersimple, 5 )
    self:add(ke_gatherSimple, self.process_elements)
	
    self:AddTaskCheckCEs()
end

ffxiv_task_qs_fish = inheritsFrom(ml_task)
function ffxiv_task_qs_fish.Create()
    local newinst = inheritsFrom(ffxiv_task_qs_fish)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "LT_FISH_ASSISTONLY"
	
    --ffxiv_task_fish_assisted members
    newinst.castTimer = 0
    newinst.baitName = ""
    newinst.castFailTimer = 0
    newinst.missingBait = false
	newinst.networkLatency = 0
    
    return newinst
end

function ffxiv_task_qs_fish:Init()

    local ke_setbait = ml_element:create( "SetBait", c_setbait, e_setbait, 10 )
    self:add(ke_setbait, self.process_elements)
	
	local ke_precast = ml_element:create( "PreCast", c_precastbuff, e_precastbuff, 7 )
    self:add(ke_precast, self.process_elements)
    
    local ke_cast = ml_element:create( "Cast", c_cast, e_cast, 5 )
    self:add(ke_cast, self.process_elements)
    
    local ke_bite = ml_element:create( "Bite", c_bite, e_bite, 5 )
    self:add(ke_bite, self.process_elements)
    
    self:AddTaskCheckCEs()
end
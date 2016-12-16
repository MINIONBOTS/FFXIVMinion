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
        Settings.FFXIVMINION.gQSGrindMaxLevel = "60"
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
	GUI_NewComboBox(winName,GetString("botMode"),"gBotMode",group,"None")
	GUI_NewComboBox(winName,GetString("skillProfile"),"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,GetString("navmesh") ,"gmeshname",group,ffxivminion.Strings.Meshes())
	GUI_NewCheckbox(winName,GetString("botEnabled"),"gBotRunning",group)
    
	local group = "Attack Settings"
    GUI_NewNumeric(winName,GetString("minLevel"),"gQSGrindMinLevel",group,"1","60")
    GUI_NewNumeric(winName,GetString("maxLevel"),"gQSGrindMaxLevel",group,"1","60")
    GUI_NewField(winName,GetString("contentIDEquals"),"gQSGrindContent",group)
	
	local group = "Fish Settings"
	GUI_NewCheckbox(winName,GetString("useMooch"),"gUseMooch",group)
	
	local group = "Gather Settings"
	GUI_NewNumeric(winName,GetString("minLevel"),"gQSGatherNodeLevel",group,"1","60")
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
c_returntoposition.timer = 0
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
			if (distance > 30 and (not gatherable or (gatherable and not gatherable.cangather))) then
				if (c_returntoposition.timer == 0) then
					c_returntoposition.timer = Now() + 6000
					return false
				elseif (Now() > c_returntoposition.timer) then
					c_returntoposition.timer = 0
					return true
				else
					d("Time until reset:"..tostring((c_returntoposition.timer - Now()) / 1000).." seconds.")
				end
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
		if (ValidTable(e) and e.contentid ~= 541) then
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
					if (ValidTable(e) and e.contentid ~= 541) then
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
			if (ValidTable(e) and e.contentid ~= 541) then
				return e
			end
		end
	end
	
	if (not IsNullString(huntString)) then
		el = EntityList("contentid="..huntString..",shortestpath,fateid=0,alive,attackable,onmesh")
		
		if ( el ) then
			local i,e = next(el)
			if (ValidTable(e) and e.contentid ~= 541) then
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
			if (ValidTable(e) and e.contentid ~= 541) then
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
			if (ValidTable(e) and e.contentid ~= 541) then
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
	if (IsLoading() or ml_mesh_mgr.loadingMesh) then
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

function DoGatheringSimple(item)
	if (SkillMgr.Gather(item)) then
		ml_task_hub:CurrentTask():SetDelay(500)
		return 1
	end

	if (CheckBuffsSimple) then
		ml_task_hub:CurrentTask():SetDelay(1500)
		return 2
	end

	Player:Gather(item.index)
	return 3
end

function CheckBuffsSimple()	
	local hasCollect = HasBuffs(Player,"805")	
	if (hasCollect) then
		local collect = MGetAction(ffxiv_gather.collectors[Player.job],1)
		if (collect and collect.isready) then
			collect:Cast()
		end
		return true
	end
	
	return false
end

c_gathersimple = inheritsFrom( ml_cause )
e_gathersimple = inheritsFrom( ml_effect )
function c_gathersimple:evaluate()	
    if (ControlVisible("Gathering")) then
		return true
	end
	
    return false
end
function e_gathersimple:execute()
	if (Player.action ~= 264 and Player.action ~= 256 and not MIsGCDLocked()) then
		ml_task_hub:CurrentTask().idleTimer = Now()
		ml_debug("Gathering ability is not ready yet.")
		return false
	end

	local thisNode = MGetEntity(ml_global_information.gatherid)
	if (not ValidTable(thisNode) or not thisNode.cangather) then
		return
	end

    local list = MGatherableSlotList()
    if (list ~= nil) then

		-- 5th pass, ixali rare items
		for i, item in pairs(list) do
			if (IsIxaliRare(item.id)) then
				local itemCount = ItemCount(item.id,true)
				if (itemCount < 5) then
					return DoGathering(item)
				end
			end
		end
		
		--d("Checking ixali semi-rare item section.")

		-- 6th pass, semi-rare ixali items
		for i, item in pairs(list) do
			if (IsIxaliSemiRare(item.id)) then
				local itemCount = ItemCount(item.id,true)
				if (itemCount < 15) then
					return DoGathering(item)
				end
			end
		end
		
		local item1 = gQSGatherItem1
		local item2 = gQSGatherItem2
		
		local itemid1 = 0
		local itemid2 = 0
		local itemslot1 = 0
		local itemslot2 = 0
		
		--d(AceLib.API.Items.GetIDByName("Silkworm Cocoon"))
		
		if (item1 and item1 ~= "" and item1 ~= GetString("none")) then
			itemid1 = AceLib.API.Items.GetIDByName(item1) or 0
			if (itemid1 == 0) then
				gd("[Gather]: Could not find a valid item ID for Item 1 - ["..tostring(item1).."].",3)
			end
		end
		if (tonumber(item1) ~= nil) then
			itemslot1 = tonumber(item1)
		end
		
		if (item2 and item2 ~= "" and item2 ~= GetString("none")) then
			itemid2 = AceLib.API.Items.GetIDByName(item2) or 0
			if (itemid2 == 0) then
				gd("[Gather]: Could not find a valid item ID for Item 2 - ["..tostring(item2).."].",3)
			end
		end
		if (tonumber(item2) ~= nil) then
			itemslot2 = tonumber(item2)
		end
		
		for i, item in pairs(list) do
			if (itemid1 ~= 0) then
				if (item.id == itemid1) then
					return DoGathering(item)
				end
			end
					
			if (itemslot1 ~= 0) then
				if (item.index == (itemslot1-1) and item.id ~= nil) then
					return DoGathering(item)
				end
			end
		end
		
		for i, item in pairs(list) do
			if (itemid2 ~= 0) then
				if (item.id == itemid2) then
					return DoGathering(item)
				end
			end
				
			if (itemslot2 ~= 0) then
				if (item.index == (itemslot2-1) and item.id ~= nil) then
					return DoGathering(item)
				end
			end
		end
		
		--d("Checking unknown items, couldn't find any regular items.")
			
		-- Gather unknown items to unlock them.
		for i,item in pairs(list) do
			if (item.isunknown or (IsUnspoiled(thisNode.contentid) and item.chance == 25 and (item.name == "" or item.name == nil))) then
				return DoGathering(item)
			end
		end
			
		-- Gather unknown items to unlock them.
		for i,item in pairs(list) do
			if (item.isunknown or (IsUnspoiled(thisNode.contentid) and item.chance == 25 and (item.name == "" or item.name == nil))) then
				return DoGathering(item)
			end
		end
		
		--d("Checking random items with good chance.")
			
		-- just grab a random item with good chance
		for i, item in pairs(list) do
			if (item.chance > 50) then
				return DoGathering(item)
			end
		end
		
		--d("Checking random items.")
		
		-- just grab a random item - last resort
		for i, item in pairs(list) do
			return DoGathering(item)
		end
	end
end

c_qsmovetogatherable = inheritsFrom( ml_cause )
e_qsmovetogatherable = inheritsFrom( ml_effect )
e_qsmovetogatherable.blockOnly = false
function c_qsmovetogatherable:evaluate()
	if (ControlVisible("Gathering")) then
		return false
	end
	
	if ( ml_task_hub:CurrentTask().gatherid ~= nil and ml_task_hub:CurrentTask().gatherid ~= 0 ) then
        local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
        if (gatherable and gatherable.cangather) then
			local gpos = gatherable.pos
			if (gatherable.distance > 3.3) then
				return true
			else
				Player:SetTarget(gatherable.id)
				Player:SetFacing(gpos.x,gpos.y,gpos.z)
				
				local myTarget = MGetTarget()
				if (myTarget and myTarget.id == gatherable.id) then
					Player:Interact(gatherable.id)
				end
				
				ml_task_hub:CurrentTask():SetDelay(500)
				e_qsmovetogatherable.blockOnly = true
				return true
			end
        end
    end
    
    return false
end
function e_qsmovetogatherable:execute()
    if (e_qsmovetogatherable.blockOnly) then
		return
	end

    -- reset idle timer
    ml_task_hub:CurrentTask().idleTimer = 0
	local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
	if (ValidTable(gatherable)) then
		local gpos = gatherable.pos
		local eh = ConvertHeading(gpos.h)
		local nodeFront = ConvertHeading((eh + (math.pi)))%(2*math.pi)
		local adjustedPos = GetPosFromDistanceHeading(gpos, 1.5, nodeFront)
		
		local pos;
		if (ValidTable(adjustedPos)) then
			pos = NavigationManager:GetClosestPointOnMesh(adjustedPos,false)
		end
		
		if (not ValidTable(pos)) then
			pos = NavigationManager:GetClosestPointOnMesh(gpos,false)
		end

		local ppos = ml_global_information.Player_Position
		if (ValidTable(pos)) then
			local dist3d = PDistance3D(ppos.x,ppos.y,ppos.z,pos.x,pos.y,pos.z)
			
			local newTask = ffxiv_task_movetointeract.Create()
			newTask.pos = pos
			newTask.useTeleport = false
			
			if (CanUseCordial() or CanUseExpManual()) then
				if (dist3d > 8 or IsFlying()) then
					local telePos = GetPosFromDistanceHeading(pos, 5, nodeFront)
					local p,dist = NavigationManager:GetClosestPointOnMesh(telePos,false)
					if (p) then
						local alternateTask = ffxiv_task_movetopos.Create()
						alternateTask.pos = p
						alternateTask.useTeleport = (gTeleport == "1")
						alternateTask.range = 3
						alternateTask.remainMounted = true
						alternateTask.stealthFunction = ffxiv_gather.NeedsStealth
						ml_task_hub:CurrentTask():AddSubTask(alternateTask)
					end
				end
				return
			end
			
			if (gTeleport == "1" and dist3d > 8 and ShouldTeleport(pos)) then
				local telePos = GetPosFromDistanceHeading(pos, 5, nodeFront)
				local p,dist = NavigationManager:GetClosestPointOnMesh(telePos,false)
				if (p and dist ~= 0) then
					newTask.pos = p
					newTask.useTeleport = true
				end
			end
			
			newTask.interact = ml_task_hub:CurrentTask().gatherid
			newTask.use3d = true
			newTask.interactRange = 3.3
			newTask.pathRange = 5
			newTask.stealthFunction = ffxiv_gather.NeedsStealth
			ml_task_hub:CurrentTask():AddSubTask(newTask)	
		end
	end
end

c_qsfindgatherable = inheritsFrom( ml_cause )
e_qsfindgatherable = inheritsFrom( ml_effect )
function c_qsfindgatherable:evaluate()
	if (ControlVisible("Gathering")) then
		return false
	end

    local needsUpdate = false
	if ( ml_task_hub:CurrentTask().gatherid == nil or ml_task_hub:CurrentTask().gatherid == 0 ) then
		needsUpdate = true
	else
		local gatherable = EntityList:Get(ml_task_hub:CurrentTask().gatherid)
		if (ValidTable(gatherable)) then
			if (not gatherable.cangather) then
				needsUpdate = true
			end
		elseif (gatherable == nil) then
			needsUpdate = true
		end
	end
	
	if (needsUpdate) then
		ml_task_hub:CurrentTask().gatherid = 0
		ml_global_information.gatherid = 0
		
		local minlevel = tonumber(gQSGatherNodeLevel)
		local maxlevel = tonumber(gQSGatherNodeLevel)
		if (minlevel and minlevel < 60) then
			minlevel = RoundUp(minlevel,5)
		end
		if (maxlevel and maxlevel < 60) then
			maxlevel = RoundUp(maxlevel,5)
		end
		
		local gatherable = GetNearestGatherable(minlevel,maxlevel)
		if (gatherable ~= nil) then
			if (c_returntoposition.timer ~= 0) then
				c_returntoposition.timer = 0
			end
			-- reset blacklist vars for a new node
			ml_task_hub:CurrentTask().failedTimer = 0		
			ml_task_hub:CurrentTask().gatherid = gatherable.id	
			ml_global_information.gatherid = gatherable.id	
			SkillMgr.prevSkillList = {}
			
			return true
		end
	end
	
    return false
end
function e_qsfindgatherable:execute()	
   d("Found new gatherable.")
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

	newinst.interactTimer = 0    
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
	
	local ke_returnToPosition = ml_element:create( "ReturnToPosition", c_returntoposition, e_returntoposition, 20)
    self:add(ke_returnToPosition, self.process_elements)
	
    local ke_findGatherable = ml_element:create( "FindGatherable", c_qsfindgatherable, e_qsfindgatherable, 15 )
    self:add(ke_findGatherable, self.process_elements)
	
    local ke_moveToGatherable = ml_element:create( "MoveToGatherable", c_qsmovetogatherable, e_qsmovetogatherable, 12 )
    self:add( ke_moveToGatherable, self.process_elements)
    
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
    
    local ke_cast = ml_element:create( "Cast", c_qscast, e_qscast, 5 )
    self:add(ke_cast, self.process_elements)
    
    local ke_bite = ml_element:create( "Bite", c_bite, e_bite, 5 )
    self:add(ke_bite, self.process_elements)
    
    self:AddTaskCheckCEs()
end

c_qscast = inheritsFrom( ml_cause )
e_qscast = inheritsFrom( ml_effect )
function c_qscast:evaluate()
	if (Now() < ml_task_hub:CurrentTask().networkLatency) then
		return false
	end
	
    local castTimer = ml_task_hub:CurrentTask().castTimer
    if (Now() > castTimer) then
        local fs = tonumber(Player:GetFishingState())
        if (fs == 0 or fs == 4) then
            return true
        end
    end
    return false
end
function e_qscast:execute()
	local marker = ml_task_hub:CurrentTask().currentMarker
	local useMooch = (gUseMooch == "1")
	
    local mooch = ActionList:Get(297,1)
    if (mooch) and Player.level > 24 and (mooch.isready) and useMooch then
        mooch:Cast()
		ml_task_hub:CurrentTask().castTimer = Now() + 1500
    else
        local cast = ActionList:Get(289,1)
        if (cast and cast.isready) then	
            cast:Cast()
			ml_task_hub:CurrentTask().castTimer = Now() + 1500
        end
    end
end
ffxiv_task_party = inheritsFrom(ml_task)
ffxiv_task_party.name = "LT_PARTY"
ffxiv_task_party.evacPoint = {0, 0, 0}
ffxiv_task_party.isPL = false
ffxiv_task_party.extraMembers = {}

c_partysyncfatelevel = inheritsFrom( ml_cause )
e_partysyncfatelevel = inheritsFrom( ml_effect )
function c_partysyncfatelevel:evaluate()
    if ( IsLeader() or Player:GetSyncLevel() ~= 0 ) then
        return false
    end
	
	local leader = GetPartyLeader()
	if (not leader or not IsInParty(leader.id)) then
		return false
	end
    
    local myPos = Player.pos
    local fate = GetClosestFate(myPos)
	if (ValidTable(fate)) then
		local plevel = Player.level
		if (fate.level < (plevel - 5)) then
			local distance = Distance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z)
			if (distance < fate.radius) then				
				return true
			end
		end
	end
    return false
end
function e_partysyncfatelevel:execute()
    ml_debug( "Current Sync Fatelevel: "..tostring(Player:GetSyncLevel() ))
    ml_debug( "Syncing Fatelevel Result: "..tostring(Player:SyncLevel())) 
	ml_task_hub:ThisTask().preserveSubtasks = true
end

function ffxiv_task_party.Create()
    local newinst = inheritsFrom(ffxiv_task_party)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_party members
    newinst.name = "LT_PARTY"
    newinst.targetid = 0
    newinst.markerTime = 0
    newinst.currentMarker = false
    newinst.previousMarker = false
    
    --this is the targeting function that will be used for the generic KillTarget task
    newinst.targetFunction = GetNearestGrindAttackable
    
    return newinst
end

function ffxiv_task_party:Init()
    --init ProcessOverWatch() elements
    
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 30 )
    self:add( ke_dead, self.overwatch_elements)
    
    local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 27 )
    self:add( ke_flee, self.overwatch_elements)
    
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 24 )
    self:add( ke_rest, self.overwatch_elements)
    
    local ke_psyncFate = ml_element:create( "PSyncFateLevel", c_partysyncfatelevel, e_partysyncfatelevel, 21 ) --minion only
    self:add( ke_psyncFate, self.overwatch_elements)
    
    local ke_addFate = ml_element:create( "AddFate", c_add_fate, e_add_fate, 18 ) --leader only
    self:add(ke_addFate, self.overwatch_elements)
	
	local ke_followleader = ml_element:create( "FollowLeader", c_followleader, e_followleader, 14 )--minion only
    self:add( ke_followleader, self.overwatch_elements )
    
    local ke_assistleader = ml_element:create( "AssistLeader", c_assistleader, e_assistleader, 11 )--minion only
    self:add( ke_assistleader, self.overwatch_elements )
	
    local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 30 )--leader only
    self:add( ke_returnToMarker, self.process_elements)
	
    local ke_nextMarker = ml_element:create( "NextMarker", c_nextmarker, e_nextmarker, 27 )--leader only
    self:add( ke_nextMarker, self.process_elements)

    local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_killtarget, e_add_killtarget, 15 ) --leader only
    self:add(ke_addKillTarget, self.process_elements)
	
	local ke_killAggroTarget = ml_element:create( "KillAggroTarget", c_killaggrotarget, e_killaggrotarget, 13 ) --minion only
    self:add(ke_killAggroTarget, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_party:Process()

    local target = Player:GetTarget()
	if ( target == nil and not ActionList:IsCasting()) then
		SkillMgr.Cast( Player, true )
	end

    if (TableSize(self.process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(self.process_elements)
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end



function ffxiv_task_party.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gBotMode" or  
				k == "gPartyLeaderName" or 
				k == "gPartyGrindUsePartyLeader") 
		then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(GetString("partyMode"))
end

function ffxiv_task_party.ButtonHandler(arg)
    d("Button :"..arg)
end

function ffxiv_task_party.SetLeaderFromTarget()
	local t = Player:GetTarget()
	if (t~=nil) then
		if (t.type == 1) then
			gPartyLeaderName = t.name
			Settings.FFXIVMINION.gPartyLeaderName = gPartyLeaderName
		end
	else
		gPartyLeaderName = ""
		Settings.FFXIVMINION.gPartyLeaderName = ""
	end
end

function ffxiv_task_party.AddExtraMember()
	local i = TableSize(ffxiv_task_party.extraMembers) + 1
	ffxiv_task_party.extraMembers[i] = gPartyExtraMember
end

-- UI settings etc
function ffxiv_task_party.UIInit()	

	ffxivminion.Windows.Party = { id = strings["us"].partyMode, Name = GetString("partyMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Party)

	if (Settings.FFXIVMINION.gPartyLeaderName == nil) then
        Settings.FFXIVMINION.gPartyLeaderName = ""
    end
	if (Settings.FFXIVMINION.gPartyExtraMember == nil) then
        Settings.FFXIVMINION.gPartyExtraMember = ""
    end
    if (Settings.FFXIVMINION.gPartyGrindUsePartyLeader == nil) then
        Settings.FFXIVMINION.gPartyGrindUsePartyLeader = "1"
    end
	
	local winName = GetString("partyMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, GetString("advancedSettings"), "ffxivminion.OpenSettings")
	GUI_NewButton(winName, strings[gCurrentLanguage].markerManager, "ToggleMarkerMgr")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].botMode,"gBotMode",group,"None")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].skillProfile,"gSMprofile",group,ffxivminion.Strings.SKMProfiles())
	GUI_NewComboBox(winName,strings[gCurrentLanguage].navmesh ,"gmeshname",group,ffxivminion.Strings.Meshes())
    GUI_NewCheckbox(winName,strings[gCurrentLanguage].botEnabled,"gBotRunning",group)
	GUI_NewField(winName,strings[gCurrentLanguage].markerName,"gStatusMarkerName",group )
	GUI_NewField(winName,strings[gCurrentLanguage].markerTime,"gStatusMarkerTime",group )
	
	local group = GetString("settings")
	GUI_NewButton(winName, strings[gCurrentLanguage].GetPartyLeader, "setLeaderFromTarget",group)
    RegisterEventHandler("setLeaderFromTarget",ffxiv_task_party.SetLeaderFromTarget)
    GUI_NewField(winName, strings[gCurrentLanguage].PartyLeader, "gPartyLeaderName", group)
    GUI_NewCheckbox(winName, strings[gCurrentLanguage].UseGamePartyLeader, "gPartyGrindUsePartyLeader",group)
	GUI_NewField(winName, "Extra Member", "gPartyExtraMember", group)
    GUI_NewButton(winName, "Add Member", "partyAddExtraMember",group)
	RegisterEventHandler("partyAddExtraMember",ffxiv_task_party.AddExtraMember)

	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gPartyLeaderName = Settings.FFXIVMINION.gPartyLeaderName
	gPartyGrindUsePartyLeader = Settings.FFXIVMINION.gPartyGrindUsePartyLeader
end

RegisterEventHandler("GUI.Update",ffxiv_task_party.GUIVarUpdate)
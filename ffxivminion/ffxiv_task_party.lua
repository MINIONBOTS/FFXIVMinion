ffxiv_task_party = inheritsFrom(ml_task)
ffxiv_task_party.name = "LT_PARTY"
ffxiv_task_party.evacPoint = {0, 0, 0}

c_partysyncfatelevel = inheritsFrom( ml_cause )
e_partysyncfatelevel = inheritsFrom( ml_effect )
function c_partysyncfatelevel:evaluate()
    if ( IsLeader()) then
        return false
    end
    
    local myPos = Player.pos
    local fate = GetClosestFate(myPos)
	if ( fate and TableSize(fate)) then
		local plevel = Player.level
		if ( ( fate.level > plevel +5 or fate.level < plevel - 5) and Player:GetSyncLevel() == 0 )then
			local distance = Distance2D(myPos.x, myPos.z, fate.x, fate.z)
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
    
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 20 )
    self:add( ke_dead, self.overwatch_elements)
    
    local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 15 )
    self:add( ke_flee, self.overwatch_elements)
    
    local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 14 )
    self:add( ke_rest, self.overwatch_elements)
    
    local ke_psyncFate = ml_element:create( "PSyncFateLevel", c_partysyncfatelevel, e_partysyncfatelevel, 12 ) --minion only
    self:add( ke_psyncFate, self.overwatch_elements)
    
    local ke_addFate = ml_element:create( "AddFate", c_add_fate, e_add_fate, 10 ) --leader only
    self:add(ke_addFate, self.overwatch_elements)
    
    local ke_updateleaderdata = ml_element:create("UpdateLeaderData", c_updateleaderdata, e_updateleaderdata, 5)
    self:add( ke_updateleaderdata, self.overwatch_elements)
    
    --init Process() cnes
    local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 35 )--leader only
    self:add( ke_returnToMarker, self.process_elements)
    
    --nextmarker defined in ffxiv_task_gather.lua
    local ke_nextMarker = ml_element:create( "NextMarker", c_nextmarker, e_nextmarker, 35 )--leader only
    self:add( ke_nextMarker, self.process_elements)
    
    local ke_assistleader = ml_element:create( "AssistLeader", c_assistleader, e_assistleader, 25 )--minion only
    self:add( ke_assistleader, self.process_elements)

    local ke_followleader = ml_element:create( "FollowLeader", c_followleader, e_followleader, 20 )--minion only
    self:add( ke_followleader, self.process_elements)

    local ke_reacttoleader = ml_element:create( "ReactToLeader", c_reactonleaderaction, e_reactonleaderaction, 20 )--minion only
    self:add( ke_reacttoleader, self.process_elements)

    local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_killtarget, e_add_killtarget, 15 ) --leader only
    self:add(ke_addKillTarget, self.process_elements)
    
	local ke_KillAggroTarget = ml_element:create( "KillAggroTarget", c_killaggrotarget, e_killaggrotarget, 10 )
	self:add(ke_KillAggroTarget, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_party:OnSleep()

end

function ffxiv_task_party:OnTerminate()

end

function ffxiv_task_party:IsGoodToAbort()

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

-- UI settings etc
function ffxiv_task_party.UIInit()	

	ffxivminion.Windows.Party = { Name = GetString("partyMode"), x=50, y=50, width=210, height=300 }
	ffxivminion.CreateWindow(ffxivminion.Windows.Party)

	if (Settings.FFXIVMINION.gPartyLeaderName == nil) then
        Settings.FFXIVMINION.gPartyLeaderName = ""
    else
		gPartyLeaderName = Settings.FFXIVMINION.gPartyLeaderName
    end
    if (Settings.FFXIVMINION.gPartyGrindUsePartyLeader == nil) then
        Settings.FFXIVMINION.gPartyGrindUsePartyLeader = "0"
    else
        gPartyGrindUsePartyLeader = Settings.FFXIVMINION.gPartyGrindUsePartyLeader
    end
	
	local winName = GetString("partyMode")
	GUI_NewButton(winName, ml_global_information.BtnStart.Name , ml_global_information.BtnStart.Event)
	GUI_NewButton(winName, "Open Settings", "ffxivminion.OpenSettings")
	
	local group = GetString("status")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].botMode,"gBotMode",group,"None")
	GUI_NewComboBox(winName,strings[gCurrentLanguage].profile,"gProfile",group,"None")
    GUI_NewCheckbox(winName,strings[gCurrentLanguage].botEnabled,"gBotRunning",group)
	local group = GetString("settings")
	GUI_NewButton(winName, strings[gCurrentLanguage].GetPartyLeader, "setLeaderFromTarget",group)
    RegisterEventHandler("setLeaderFromTarget",ffxiv_task_party.SetLeaderFromTarget)
    GUI_NewField(winName, strings[gCurrentLanguage].PartyLeader, "gPartyLeaderName", group)
    GUI_NewCheckbox(winName, strings[gCurrentLanguage].UseGamePartyLeader, "gPartyGrindUsePartyLeader",group)

	GUI_UnFoldGroup(winName,GetString("status"))
	ffxivminion.SizeWindow(winName)
	GUI_WindowVisible(winName, false)
	
	gPartyLeaderName = Settings.FFXIVMINION.gPartyLeaderName
	gPartyGrindUsePartyLeader = gPartyGrindUsePartyLeader
end

RegisterEventHandler("GUI.Update",ffxiv_task_party.GUIVarUpdate)
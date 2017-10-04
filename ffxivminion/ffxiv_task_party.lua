ffxiv_task_party = inheritsFrom(ml_task)
ffxiv_task_party.name = "LT_PARTY"
ffxiv_task_party.evacPoint = {0, 0, 0}
ffxiv_task_party.isPL = false
ffxiv_task_party.extraMembers = {}

c_partysyncfatelevel = inheritsFrom( ml_cause )
e_partysyncfatelevel = inheritsFrom( ml_effect )
function c_partysyncfatelevel:evaluate()
    if ( IsLeader() or Player:GetSyncLevel() ~= 0 or not gPartyGrindFateSync) then
        return false
    end
	
	local leader = GetPartyLeader()
	if (not leader or not IsInParty(leader.id)) then
		return false
	end
    
    local myPos = Player.pos
    local fate = GetClosestFate(myPos)
	if (table.valid(fate)) then
		if (AceLib.API.Fate.RequiresSync(fate.id)) then
			local distance = PDistance3D(myPos.x, myPos.y, myPos.z, fate.x, fate.y, fate.z)
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
    
    newinst.targetFunction = GetNearestGrindAttackable
    
    return newinst
end

function ffxiv_task_party:Init()
    --init ProcessOverWatch() elements
    local ke_dead = ml_element:create( "Dead", c_dead, e_dead, 100 )
    self:add( ke_dead, self.overwatch_elements)
    
    local ke_flee = ml_element:create( "Flee", c_flee, e_flee, 95 )
    self:add( ke_flee, self.overwatch_elements)
	
	local ke_rest = ml_element:create( "Rest", c_rest, e_rest, 90 )
    self:add( ke_rest, self.overwatch_elements)
	
	local ke_dutyConfirm = ml_element:create( "PressConfirm", c_dutyconfirm, e_dutyconfirm, 85 )
    self:add(ke_dutyConfirm, self.overwatch_elements)
	
	local ke_psyncFate = ml_element:create( "PSyncFateLevel", c_partysyncfatelevel, e_partysyncfatelevel, 80 ) --minion only
    self:add( ke_psyncFate, self.overwatch_elements)
	
	local ke_followleader = ml_element:create( "FollowLeader", c_followleader, e_followleader, 75 ) --minion only
    self:add( ke_followleader, self.overwatch_elements )
	
	local ke_assistleader = ml_element:create( "AssistLeader", c_assistleader, e_assistleader, 70 )--minion only
    self:add( ke_assistleader, self.overwatch_elements )
	
	local ke_recommendEquip = ml_element:create( "RecommendEquip", c_recommendequip, e_recommendequip, 130 )
    self:add( ke_recommendEquip, self.process_elements)
	
	local ke_eat = ml_element:create( "Eat", c_eat, e_eat, 120 )
    self:add( ke_eat, self.process_elements)
	
	local ke_killAggroTarget = ml_element:create( "KillAggroTarget", c_killaggrotarget, e_killaggrotarget, 20 ) --minion only
    self:add(ke_killAggroTarget, self.process_elements)
    
    local ke_addFate = ml_element:create( "AddFate", c_add_fate, e_add_fate, 70 ) --leader only
    self:add(ke_addFate, self.process_elements)
	
	local ke_returnToMarker = ml_element:create( "ReturnToMarker", c_returntomarker, e_returntomarker, 50 )--leader only
    self:add( ke_returnToMarker, self.process_elements)
	
    local ke_nextMarker = ml_element:create( "NextMarker", c_nextmarker, e_nextmarker, 40 )--leader only
    self:add( ke_nextMarker, self.process_elements)

    local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_killtarget, e_add_killtarget, 30 ) --leader only
    self:add(ke_addKillTarget, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_party:Process()
    local target = MGetTarget()
	if ( target == nil and not IsPlayerCasting()) then
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

function ffxiv_task_party.SetLeaderFromTarget()
	local t = Player:GetTarget()
	if (t~=nil) then
		if (t.type == 1) then
			GUI_Set("gPartyLeaderName",t.name)
			GUI_Set("gPartyGrindUsePartyLeader",false)
		end
	end
end

function ffxiv_task_party.AddExtraMember()
	local i = TableSize(ffxiv_task_party.extraMembers) + 1
	ffxiv_task_party.extraMembers[i] = gPartyExtraMember
end

function ffxiv_task_party.SetModeOptions()
	gTeleportHack = Settings.FFXIVMINION.gTeleportHack
	gTeleportHackParanoid = Settings.FFXIVMINION.gTeleportHackParanoid
	gGrindDoHuntlog = Settings.FFXIVMINION.gGrindDoHuntlog
	gGrindDoFates = Settings.FFXIVMINION.gGrindDoFates
	gGrindFatesOnly = Settings.FFXIVMINION.gGrindFatesOnly
	gGrindFatesMinLevel = Settings.FFXIVMINION.gGrindFatesMinLevel
	gGrindFatesMaxLevel = Settings.FFXIVMINION.gGrindFatesMaxLevel
	gGrindDoBattleFates = Settings.FFXIVMINION.gGrindDoBattleFates
	gGrindDoBossFates = Settings.FFXIVMINION.gGrindDoBossFates
	gGrindDoGatherFates = Settings.FFXIVMINION.gGrindDoGatherFates
	gGrindDoDefenseFates = Settings.FFXIVMINION.gGrindDoDefenseFates
	gGrindDoEscortFates = Settings.FFXIVMINION.gGrindDoEscortFates
	gFateBattleWaitPercent = Settings.FFXIVMINION.gFateBattleWaitPercent
	gFateGatherWaitPercent = Settings.FFXIVMINION.gFateGatherWaitPercent
	gFateBossWaitPercent = Settings.FFXIVMINION.gFateBossWaitPercent
	gFateDefenseWaitPercent = Settings.FFXIVMINION.gFateDefenseWaitPercent
	gSkipCutscene = Settings.FFXIVMINION.gSkipCutscene
	gSkipTalk = Settings.FFXIVMINION.gSkipTalk
	gDisableDrawing = Settings.FFXIVMINION.gDisableDrawing
	Hacks:SkipCutscene(gSkipCutscene)
	Hacks:Disable3DRendering(gDisableDrawing)
	gAvoidAOE = true
	FFXIV_Common_Profile = "NA"
	FFXIV_Common_ProfileIndex = 1
	FFXIV_Common_ProfileList = { "NA" }
	gAutoEquip = Settings.FFXIVMINION.gAutoEquip
end

-- New GUI.
function ffxiv_task_party:UIInit()
	gPartyLeaderName = ffxivminion.GetSetting("gPartyLeaderName","")
	gPartyGrindUsePartyLeader = ffxivminion.GetSetting("gPartyGrindUsePartyLeader",true)
	gPartyGrindFateSync = ffxivminion.GetSetting("gPartyGrindFateSync",true)
	
	self.GUI.main_tabs = GUI_CreateTabs("status",true)
end

ffxiv_task_party.GUI = {
	x = 0,
	y = 0, 
	height = 0,
	width = 0,
}

function ffxiv_task_party:Draw()
	local fontSize = GUI:GetWindowFontSize()
	local windowPaddingY = ml_gui.style.current.windowpadding.y
	local framePaddingY = ml_gui.style.current.framepadding.y
	local itemSpacingY = ml_gui.style.current.itemspacing.y
	GUI:BeginChild("##header-status",0,GUI_GetFrameHeight(4),true)
	GUI:Columns(2)
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("UseGamePartyLeader"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("UseGamePartyLeaderTooltip")) end
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("SynctoFates"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("SynctoFatesTooltip")) end
	GUI:AlignFirstTextHeightToWidgets() GUI:Text(GetString("PartyLeader"))
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("PartyLeaderTooltip")) end
	GUI:NextColumn()
	local ColumnWidth = GUI:GetContentRegionAvail()
	GUI:PushItemWidth(ColumnWidth)
	GUI_Capture(GUI:Checkbox("##UseGamePartyLeader",gPartyGrindUsePartyLeader),"gPartyGrindUsePartyLeader")
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("UseGamePartyLeaderTooltip")) end
	GUI_Capture(GUI:Checkbox("##SynctoFates",gPartyGrindFateSync),"gPartyGrindFateSync")
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("SynctoFatesTooltip")) end
	GUI_Capture(GUI:InputText("##PartyLeader",gPartyLeaderName),"gPartyLeaderName");
		if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("PartyLeaderTooltip")) end
	GUI:PopItemWidth()
	GUI:Columns()	
	local FullWidth = GUI:GetContentRegionAvail()	
	if (GUI:Button(GetString("GetPartyLeader"),FullWidth,20)) then
		ffxiv_task_party.SetLeaderFromTarget()
	end
	if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("GetPartyLeaderTooltip")) end
	GUI:EndChild()
end
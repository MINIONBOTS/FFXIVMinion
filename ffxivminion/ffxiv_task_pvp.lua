ffxiv_task_pvp = inheritsFrom(ml_task)
ffxiv_task_pvp.name = "LT_PVP"

function ffxiv_task_pvp:Create()
    local newinst = inheritsFrom(ffxiv_task_pvp)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_pvp members
    newinst.name = "LT_PVP"
    newinst.targetid = 0
    
    --this is the targeting function that will be used for the generic KillTarget task
    newinst.targetFunction = GetPVPTarget
    
    return newinst
end

c_joinqueue = inheritsFrom( ml_cause )
e_joinqueue = inheritsFrom( ml_effect )
function c_joinqueue:evaluate() 
    -- check if current map is not equal to wolves den and df is not currently queued
end
function e_joinqueue:execute()
    -- join df queue
end

c_pressconfirm = inheritsFrom( ml_cause )
e_pressconfirm = inheritsFrom( ml_effect )
function c_pressconfirm:evaluate() 
    -- check if df queue window is open
	-- added function DutyReady() but it's not returnign a bool?
end
function e_pressconfirm:execute()
    PressDutyConfirm(true)
end

c_pressleave = inheritsFrom( ml_cause )
e_pressleave = inheritsFrom( ml_effect )
function c_pressleave:evaluate() 
    -- check if map is wolves den (175) and colosseum record is open
end
function e_pressleave:execute()
    PressLeaveColosseum()
end

c_pvpBetterTarget = inheritsFrom( ml_cause )
e_pvpBetterTarget = inheritsFrom( ml_effect )
function c_pvpBetterTarget:evaluate()
    -- check if our current target is no longer valid or a better target exists
    if (ml_task_hub:ThisTask().targetid~=nil and ml_task_hub:ThisTask().targetid~=0)then		
        local bettertarget = ml_task_hub:ThisTask().targetFunction()
        if ( bettertarget ~= nil and bettertarget.id ~= ml_task_hub:ThisTask().targetid ) then
            e_pvpBetterTarget.id = bettertarget.id
            return true			
        end		
    end	
end
function e_pvpBetterTarget:execute()
    ml_task_hub:ThisTask().targetid = e_pvpBetterTarget.id
    Player:SetTarget(e_pvpBetterTarget.id)
end

function ffxiv_task_pvp:Init()
    --init ProcessOverWatch() elements
    local ke_pvpBetterTarget = ml_element:create( "PVPBetterTarget", c_pvpBetterTarget, e_pvpBetterTarget, 15 )
    self:add(ke_pvpBetterTarget, self.process_elements)
   
    --init Process() cnes
    local ke_addKillTarget = ml_element:create( "AddKillTarget", c_add_killtarget, e_add_killtarget, 15 )
    self:add(ke_addKillTarget, self.process_elements)
	
	local ke_pressConfirm = ml_element:create( "ConfirmDuty", c_pressconfirm, e_pressconfirm, 10 )
    self:add(ke_pressConfirm, self.process_elements)
	
	local ke_pressLeave = ml_element:create( "LeaveColosseum", c_pressleave, e_pressleave, 10 )
    self:add(ke_pressLeave, self.process_elements)
  
    self:AddTaskCheckCEs()
end

function ffxiv_task_pvp:OnSleep()

end

function ffxiv_task_pvp:OnTerminate()

end

function ffxiv_task_pvp:IsGoodToAbort()

end

-- UI settings etc
function ffxiv_task_pvp.UIInit()
   --[[ GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].pvpTargetOne,"gPVPTargetOne",strings[gCurrentLanguage].pvpMode,"")
    GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].pvpTargetTwo,"gPVPTargetTwo",strings[gCurrentLanguage].pvpMode,"")
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].prioritizeRanged, "gPrioritizeRanged",strings[gCurrentLanguage].pvpMode)

    --init combo boxes
    local targetTypeList = strings[gCurrentLanguage].healer..","..strings[gCurrentLanguage].dps..","..strings[gCurrentLanguage].tank..","..strings[gCurrentLanguage].nearest..","..strings[gCurrentLanguage].lowestHealth
    gPVPTargetOne_listitems = targetTypeList
    gPVPTargetTwo_listitems = targetTypeList
    
    if (Settings.FFXIVMINION.gPVPTargetOne == nil) then
        Settings.FFXIVMINION.gPVPTargetOne = "Healer"
    end
    
    if (Settings.FFXIVMINION.gPVPTargetTwo == nil) then
        Settings.FFXIVMINION.gPVPTargetTwo = "Lowest Health"
    end
    
    if (Settings.FFXIVMINION.gPrioritizeRanged == nil) then
        Settings.FFXIVMINION.gPrioritizeRanged = "0"
    end
    
    GUI_SizeWindow(ml_global_information.MainWindow.Name,250,400)
	
    gPVPTargetOne = Settings.FFXIVMINION.gPVPTargetOne
    gPVPTargetTwo = Settings.FFXIVMINION.gPVPTargetTwo
    gPrioritizeRanged = Settings.FFXIVMINION.gPrioritizeRanged]]
end

function ffxiv_task_pvp.GUIVarUpdate(Event, NewVals, OldVals)
    for k,v in pairs(NewVals) do
        if ( 	k == "gPVPTargetOne" or
                k == "gPVPTargetTwo" or
                k == "gPrioritizeRanged" )
        then
            Settings.FFXIVMINION[tostring(k)] = v
        end
    end
    GUI_RefreshWindow(ml_global_information.MainWindow.Name)
end

RegisterEventHandler("GUI.Update",ffxiv_task_pvp.GUIVarUpdate)

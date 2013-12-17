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

c_acceptqueue = inheritsFrom( ml_cause )
e_acceptqueue = inheritsFrom( ml_effect )
function c_acceptqueue:evaluate() 
    -- check if df queue window is open
end
function e_acceptqueue:execute()
    -- click "Commence"
end

c_leavepvp = inheritsFrom( ml_cause )
e_leavepvp = inheritsFrom( ml_effect )
function c_leavepvp:evaluate() 
    -- check if leave pvp window is open
end
function e_leavepvp:execute()
    -- click "Leave"
end

c_pvpBetterTarget = inheritsFrom( ml_cause )
e_pvpBetterTarget = inheritsFrom( ml_effect )
function c_pvpBetterTarget:evaluate() 
    -- check if our current target is no longer valid or a better target exists
    if (ml_task_hub:ThisTask().targetid~=nil and ml_task_hub:ThisTask().targetid~=0)then		
        local bettertarget = ml_task_hub:ThisTask().targetFunction()
        if ( bettertarget ~= nil and bettertarget.id ~= ml_task_hub:ThisTask().targetid ) then
            ml_task_hub:ThisTask().targetid = bettertarget.id
            Player:SetTarget(bettertarget.id)
            return true			
        end		
    end	
end
function e_pvpBetterTarget:execute()
    -- click "Leave"
end

function ffxiv_task_pvp:Init()
    --init ProcessOverWatch() elements
   
    
    --not sure if we need this, taking it out for now
    --init Process() cnes
    --local ke_mobAggro = ml_element:create( "MobAggro", c_mobaggro, e_mobaggro, 35 )
    --self:add(ke_mobAggro, self.process_elements)

  
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
    GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].pvpTargetOne,"gPVPTargetOne",strings[gCurrentLanguage].pvpMode,"")
    GUI_NewComboBox(ml_global_information.MainWindow.Name,strings[gCurrentLanguage].pvpTargetTwo,"gPVPTargetTwo",strings[gCurrentLanguage].pvpMode,"")
    GUI_NewCheckbox(ml_global_information.MainWindow.Name, strings[gCurrentLanguage].prioritizeRanged, "gPrioritizeRanged",strings[gCurrentLanguage].pvpMode)

    --init combo boxes
    local targetTypeList = strings[gCurrentLanguage].healer..","..strings[gCurrentLanguage].dps..","..strings[gCurrentLanguage].tank..","..strings[gCurrentLanguage].nearest..","..strings[gCurrentLanguage].lowestHealth
    gPVPTargetOne_listitems = targetTypeList
    gPVPTargetTwo_listitems = targetTypeList
    
    if (Settings.FFXIVMINION.gPVPTargetOne == nil) then
        Settings.FFXIVMINION.gPVPTargetOne = "1"
    end
    
    if (Settings.FFXIVMINION.gPVPTargetTwo == nil) then
        Settings.FFXIVMINION.gPVPTargetTwo = "2"
    end
    
    if (Settings.FFXIVMINION.gPrioritizeRanged == nil) then
        Settings.FFXIVMINION.gPrioritizeRanged = "0"
    end
    
    GUI_SizeWindow(ml_global_information.MainWindow.Name,250,400)
	
    gPVPTargetOne = Settings.FFXIVMINION.gPVPTargetOne
    gPVPTargetTwo = Settings.FFXIVMINION.gPVPTargetTwo
    gPrioritizeRanged = Settings.FFXIVMINION.gPrioritizeRanged
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

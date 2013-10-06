ffxiv_task_assist = inheritsFrom(ml_task)
ffxiv_task_assist.name = "LT_ASSIST"

function ffxiv_task_assist:Create()
    local newinst = inheritsFrom(ffxiv_task_assist)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_assist members
    newinst.name = "LT_ASSIST"
    newinst.targetid = 0
    
    return newinst
end

---------------------------------------------------------------------------------------------
--COMBATASSIST_TASK: If (current target is attackable) Then (add combat task)
--Adds a combat task if the current player target is attackable
---------------------------------------------------------------------------------------------

c_combatassist_task = inheritsFrom( ml_cause )
e_combatassist_task = inheritsFrom( ml_effect )
function c_combatassist_task:evaluate()
	local target = Player:GetTarget()
	if (target ~= nil and target ~= {}) then
		if(target.attackable and target.hp.current > 0 and target.id ~= nil and target.id ~= 0 and target.distance < ml_global_information.AttackRange + target.hitradius) then
			ml_task_hub:CurrentTask().targetid = target.id
			return true
		end
	end
    
    return false
end
function e_combatassist_task:execute()
	if ( gSMactive == "1" ) then
		local newTask = ffxiv_task_skillmgrAttack:Create()
		newTask.targetid = ml_task_hub:CurrentTask().targetid
		ml_task_hub:CurrentTask():AddSubTask(newTask)
	else
		local newTask = ml_global_information.CurrentClass:Create()
		newTask.targetid = ml_task_hub:CurrentTask().targetid
		ml_task_hub.CurrentTask():AddSubTask(newTask)
	end
end

c_validtarget = inheritsFrom( ml_cause )
e_validtarget = inheritsFrom( ml_effect )
function c_validtarget:evaluate()
	local target = Player:GetTarget()
	if 	(target == nil or target == {} or not target.attackable or not InCombatRange(target.id)  or 
		(target.id ~= ml_task_hub:CurrentTask().targetid and ml_task_hub:CurrentTask().targetid ~= 0))
	then
		return true
	end
    
    return false
end
function e_validtarget:execute()
	local target = Player:GetTarget()
	if (target ~= nil and target ~= {}) then
		ml_task_hub:CurrentTask().targetid = target.id
	else
		ml_task_hub:CurrentTask().targetid = 0
	end
	
	ml_task_hub.queues[3].rootTask:DeleteSubTasks()
end

function ffxiv_task_assist:Init()
	--init ProcessOverWatch() cnes
	local ke_validTarget = ml_element:create( "ValidTarget", c_validtarget, e_validtarget, ml_effect.priorities.interrupt )
	self:add(ke_validTarget, self.overwatch_elements)

    --init Process() cnes
	local ke_combatAssist = ml_element:create( "AddCombatAssistTask", c_combatassist_task, e_combatassist_task, ml_effect.priorities.interrupt )
	self:add(ke_combatAssist, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_assist:OnSleep()

end

function ffxiv_task_assist:OnTerminate()

end

function ffxiv_task_assist:IsGoodToAbort()

end

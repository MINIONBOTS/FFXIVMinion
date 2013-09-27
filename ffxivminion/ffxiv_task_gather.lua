ffxiv_task_gather = inheritsFrom(ml_task)
ffxiv_task_gather.name = "LT_GATHER"

function ffxiv_task_gather:Create()
    local newinst = inheritsFrom(ffxiv_task_gather)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_gather members
    newinst.name = "LT_GATHER"
    newinst.targetid = 0
	
    return newinst
end

---------------------------------------------------------------------------------------------
--FINDGATHERABLE: If (no current gathering target) Then (find the nearest gatherable target)
--Gets a gathering target by searching entity list for objectType = 6?
---------------------------------------------------------------------------------------------

c_findgatherable = inheritsFrom( ml_cause )
e_findgatherable = inheritsFrom( ml_effect )
function c_findgatherable:evaluate()
	if ( ml_task_hub.CurrentTask().targetid == nil or ml_task_hub.CurrentTask().targetid == 0 ) then
		return true
    end
    
    local target = EntityList:Get(ml_task_hub.CurrentTask().targetid)
    if (target ~= nil) then
        if (target.cangather == 0) then
            return true
        end
    elseif (target == nil) then
        return true
    end
    
    return false
end
function e_findgatherable:execute()
	ml_debug( "Getting new gatherable target" )
	local target = GetNearestGatherable()
	if (target ~= nil) then
		Player:SetTarget(target.id)
		ml_task_hub.CurrentTask().targetid = target.id
	end
end

c_gather = inheritsFrom( ml_cause )
e_gather = inheritsFrom( ml_effect )
function c_gather:evaluate()
	local node = Player:GetTarget()
	if (node ~= nil and node.distance < 2.5) then
		local list = Player:GetGatherableSlotList()
		if (list ~= nil) then
			e_gather.list = list
			return true
		else
			Player:Interact(node.id)
		end
	else
		Player:SetTarget(ml_task_hub.CurrentTask().targetid)
	end
	
	return false
end
function e_gather:execute()
	if (e_gather.list ~= nil and TableSize(e_gather.list) > 0) then
		for i, item in pairs(e_gather.list) do
			if item.chance > 50 then
				Player:Gather(i)
			end
		end
	end
end

function ffxiv_task_gather:Init()
	-- init ProcessOverWatch cnes
    local ke_findGatherable = ml_element:create( "FindGatherable", c_findgatherable, e_findgatherable, 10 )
	self:add(ke_findGatherable, self.overwatch_elements)
	
    -- We're using the MoveToTarget task here since we can target the gathering nodes and this way
    -- we don't have to define a separate Add_MoveToPos task specific to the gathering task
	local ke_moveToTarget = ml_element:create( "MoveToTarget", c_add_movetotarget, e_add_movetotarget, 5 )
	self:add( ke_moveToTarget, self.overwatch_elements)
	
	--init Process cnes
	local ke_gather = ml_element:create( "Gather", c_gather, e_gather, 5 )
	self:add(ke_gather, self.process_elements)
    
    self:AddTaskCheckCEs()
end

function ffxiv_task_gather:OnSleep()

end

function ffxiv_task_gather:OnTerminate()

end

function ffxiv_task_gather:IsGoodToAbort()

end

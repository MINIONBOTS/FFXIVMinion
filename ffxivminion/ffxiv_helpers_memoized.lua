function InitializeMemoize()
	if (not memoize) then
		memoize = {}
	end
	return true
end

function GetMemoized(key)
	if (memoize[key] == "nil") then
		return nil
	else
		if (memoize[key]) then
			return memoize[key]
		end
	end
	return nil
end

function SetMemoized(key,variant)
	InitializeMemoize()
	memoize[key] = variant
end

function MLoadstring(strEval)
	local memString = "MLoadstring;"..tostring(strEval)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local f = assert(loadstring(strEval))()
		SetMemoized(memString,f)
		return f
	end
end

function MGetAction(actionid,actiontype,targetid)
	actionid = tonumber(actionid) or 0
	actiontype = tonumber(actiontype) or 1
	targetid = tonumber(targetid) or Player.id
	
	local memString = "MGetAction;"..tostring(actionid)..";"..tostring(actiontype)..";"..tostring(targetid)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local savedAction = nil
		local action = ActionList:Get(actionid,actiontype,targetid)
		
		if (action) then
			savedAction = {}
			savedAction.name = action.name
			savedAction.id = action.id
			savedAction.isready = action.isready
			savedAction.isfacing = action.isfacing
			savedAction.combospellid = action.combospellid
			savedAction.type = action.type
			savedAction.job = action.job
			savedAction.level = action.level
			savedAction.cost = action.cost
			savedAction.cd = action.cd
			savedAction.cdmax = action.cdmax
			savedAction.isoncd = action.isoncd
			savedAction.range = action.range
			savedAction.radius = action.radius
			savedAction.casttime = action.casttime
			savedAction.recasttime = action.recasttime
			savedAction.Cast = action.Cast
		--else
			--d("Action ["..tostring(actionid).."] - ["..tostring(actiontype).."] - ["..tostring(targetid).."] was not found.")
		end
		
		SetMemoized(memString,savedAction)
		return action
	end
end

function MActionList(typestring)
	typestring = typestring or ""
	
	local memString = "MActionList;"..tostring(typestring)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local al = ActionList(typestring)
		SetMemoized(memString,al)
		return al
	end
end

function MGetActionFromList(actionid,actiontype)
	actionid = tonumber(actionid) or 0
	actiontype = tonumber(actiontype) or 1
	
	local memString = "MGetActionFromList;"..tostring(actionid)..";"..tostring(actiontype)
	local memoized = GetMemoized(memString)
	if (memoized) then
		--d("returning memoized action for ["..memString.."].")
		return memoized
	else
		local al = MActionList("type="..tostring(actiontype))
		if (ValidTable(al)) then
			for id,action in pairs(al) do
				if (action.id == actionid) then
					SetMemoized(memString,action)
					return action
				end
			end
		end
	end
	
	SetMemoized(memString,"nil")
	return nil
end

function MGetEntity(entityid)
	entityid = tonumber(entityid) or 0
	
	local memString = "MGetEntity;"..tostring(entityid)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local entity = EntityList:Get(entityid)
		SetMemoized(memString,entity)
		return entity
	end
end

function MIsLoading()
	local memString = "MIsLoading"
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local ret = IsLoading()
		SetMemoized(memString,ret)
		return ret
	end
end

function MIsLocked()
	local memString = "MIsLocked"
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local ret = IsPositionLocked()
		SetMemoized(memString,ret)
		return ret
	end
end

function MIsCasting(fullcheck)
	fullcheck = IsNull(fullcheck,false)
	
	local memString = "MIsCasting;"..tostring(fullcheck)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		--local ret = IsPlayerCasting(fullcheck)
		local ret = ActionList:IsCasting()
		SetMemoized(memString,ret)
		return ret
	end
end

function MIsGCDLocked()	
	local memString = "MIsGCDLocked"
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local ret = ActionList:IsOnGlobalCooldown()
		SetMemoized(memString,ret)
		return ret
	end
end

function MGetTarget()
	local memString = "MGetTarget"
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local target = Player:GetTarget()
		SetMemoized(memString,target)
		return target
	end
end

function MEntityList(elstring)
	elstring = elstring or ""
	
	local memString = "MEntityList;"..tostring(elstring)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local el = EntityList(elstring)
		SetMemoized(memString,el)
		return el
	end
end

function MInventory(invstring)
	invstring = invstring or ""
	
	local memString = "MInventory;"..tostring(invstring)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local inventory = Inventory(invstring)
		SetMemoized(memString,inventory)
		return inventory
	end
end

function MGetItem(hqid,includehq,requirehq)
	local memString = "MGetItem;"..tostring(itemid)..";"..tostring(includehq)..";"..tostring(requirehq)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		--local item = GetItem(itemid,includehq,requirehq)
		local item = GetItem(hqid)
		if (item) then
			SetMemoized(memString,item)
		else
			SetMemoized(memString,"nil")
		end	
		return item
	end
end

function MGatherableSlotList()
	local memString = "MGatherableSlotList"
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local list = Player:GetGatherableSlotList()
		SetMemoized(memString,list)
		return list
	end
end

function MPartyMemberWithBuff(ptbuff, ptnbuff, maxrange)
	local memString = "MPartyMemberWithBuff;"..tostring(ptbuff).."-"..tostring(ptnbuff).."-"..tostring(maxrange)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local ret = PartyMemberWithBuff(ptbuff, ptnbuff, maxrange)
		SetMemoized(memString,ret)
		return ret
	end
end

function MGetBestTankHealTarget( maxrange )
	local memString = "GetBestTankHealTarget;"..tostring(maxrange)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local ret = GetBestTankHealTarget( maxrange )
		SetMemoized(memString,ret)
		return ret
	end
end

function MGetBestPartyHealTarget(npc, maxrange)
	local memString = "GetBestPartyHealTarget;"..tostring(npc)..";"..tostring(maxrange)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local ret = GetBestPartyHealTarget( npc, maxrange )
		SetMemoized(memString,ret)
		return ret
	end
end

function MGetBestHealTarget(npc, maxrange, requiredHP)
	local memString = "GetBestHealTarget;"..tostring(npc)..";"..tostring(maxrange)..";"..tostring(requiredHP)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local ret = GetBestHealTarget( npc, maxrange, requiredHP )
		SetMemoized(memString,ret)
		return ret
	end
end

function MPartySMemberWithBuff(ptbuff, ptnbuff, maxrange)
	local memString = "MPartySMemberWithBuff;"..tostring(ptbuff).."-"..tostring(ptnbuff).."-"..tostring(maxrange)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local ret = PartySMemberWithBuff(ptbuff, ptnbuff, maxrange)
		SetMemoized(memString,ret)
		return ret
	end
end

function MGetFateByID(fateID)
	local memString = "MGetFateByID;"..tostring(fateID)
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local fate = GetFateByID(fateID)
		SetMemoized(memString,fate)
		return fate
	end
end

function MFateList()
	local memString = "MFateList"
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local fateList = MapObject:GetFateList()
		SetMemoized(memString,fateList)
		return fateList
	end
end
			
-- Functions below pertain to permanent memoize, never-changing data.

function GetPermaMemoized(key)
	return pmemoize[key]
end

function SetPermaMemoized(key,variant)
	pmemoize[key] = variant
end

function PDistance3D(x1,y1,z1,x2,y2,z2)
	x1 = round(x1, 1)
	y1 = round(y1, 1)
	z1 = round(z1, 1)
	x2 = round(x2, 1)
	y2 = round(y2, 1)
	z2 = round(z2, 1)
	
	return Distance3D(x1,y1,z1,x2,y2,z2)
end

function loadcondition(strInput)
	if (strInput ~= nil and type(strInput) == "string") then
		
		local memString = "loadcondition;"..strInput
		local memoized = GetPermaMemoized(memString)
		if (memoized) then
			return memoized
		else
			local ret = loadstring(strInput)
			SetPermaMemoized(memString,ret)
			return ret
		end		
	end
	
	return nil
end
pmemoize = {}
pmemoize.loadedfunctions = {}

function MUsingAutoFace()
	local memString = "MUsingAutoFace"
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local using = UsingAutoFace()
		SetMemoized(memString,using)
		return using
	end
end

function MPlayerDriving()
	local memString = "MPlayerDriving"
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local driving = PlayerDriving()
		SetMemoized(memString,driving)
		return driving
	end
end

function MGetGameState()
	local memoized = memoize.gamestate
	if (table.valid(memoized)) then
		return memoized
	else
		memoize.gamestate = GetGameState()
		return memoize.gamestate
	end
end

function MGetEorzeaTime()
	local memoized = memoize.etime
	if (table.valid(memoized)) then
		return memoized
	else
		memoize.etime = GetEorzeaTime()
		return memoize.etime
	end
end

function MGetControls()
	return GetControls2() -- new function indexed by name
	--[=[
	local memoized = memoize.controls
	local lastcontroltick = IsNull(memoize.lastcontroltick,0)
	if (table.valid(memoized) and lastcontroltick == Now()) then
		return memoized
	else
		memoize.controls = GetControls()
		memoize.lastcontroltick = Now()
		if (table.valid(memoize.controls)) then
			for id,e in pairs(memoize.controls) do
				memoize.controls[e.name] = e
			end
		end
		return memoize.controls
	end
	]=]
end

function LoadString(str)
	local ok, ret;
	if (pmemoize.loadedfunctions[str] and type(pmemoize.loadedfunctions[str]) == "function") then
		ok, ret = pcall(pmemoize.loadedfunctions[str])
		if (ok and ret ~= nil) then
			return ok, ret
		end
	elseif (type(str) == "string") then
		local func = loadstring(str)
		pmemoize.loadedfunctions[str] = func
		ok, ret = pcall(func)
		if (ok and ret ~= nil) then
			return ok, ret
		end
	end
	
	return ok, ret
end

function InitializeMemoize()
	if (not memoize) then
		memoize = {}
	end
	if (not memoize.entities) then
		memoize.entities = {}
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

function AddMemoizedEntity(id,entity)
	memoize.entities[id] = entity
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

function MIsMoving()
	local memString = "MIsMoving"
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local ret = Player:IsMoving()
		SetMemoized(memString,ret)
		return ret
	end
end

function MGetDirectorIndex()
	local memString = "DirectorIndex"
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local activeDuty = Duty:GetActiveDutyInfo()
		if (not table.isa(activeDuty)) then
			SetMemoized(memString,0)
			return ret
		else
			local activeDirector = Director:GetActiveDirector()
			if (not table.isa(activeDirector)) then
				SetMemoized(memString,0)
				return ret
			else
				local ret = IsNull(activeDirector.textindex,0)
				SetMemoized(memString,ret)
				return ret
			end
		end
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
		InitializeMemoize()
		local el = EntityList(elstring)
		if (table.valid(el)) then
			SetMemoized(memString,el)
			return el
		end
	end
end

function MGetParty()
	local memString = "MGetParty"
	local memoized = GetMemoized(memString)
	if (memoized) then
		return memoized
	else
		local party = GetParty()
		SetMemoized(memString,party)
		return party
	end
end

function MGetItem(hqid,includehq,requirehq)
	local memString = "MGetItem;"..tostring(hqid)..";"..tostring(includehq)..";"..tostring(requirehq)
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
		local fateList = GetFateList()
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
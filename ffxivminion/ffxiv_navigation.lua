------------------------------------------------------------
-- FFXIV Navigation — AutoFollow-Only
-- All movement dispatched via SetAutoFollowPos + SetAutoFollowOn.
-- 
------------------------------------------------------------

--*** Distance to the next node in the path at which ml_navigation.pathindex is iterated
ml_navigation.NavPointReachedDistances = {
	["3dwalk"] = 2,
	["2dwalk"] = .5,
	["3dmount"] = 5,
	["2dmount"] = 1,
	["3dswim"] = 5,
	["2dswim"] = .75,
	["3ddive"] = 2.5,
	["2ddive"] = 1.25,
	["3dfly"] = 5,
	["2dfly"] = 1.5,
}

-- Distance to the next node in the path, in case it is an OffMeshConnection
ml_navigation.OMCReachedDistances = {
	["3dwalk"] = 2,
	["2dwalk"] = 0.4,
	["3dmount"] = 5,
	["2dmount"] = 0.6,
	["3dswim"] = 5,
	["2dswim"] = 0.5,
	["3ddive"] = 5,
	["2ddive"] = 1,
	["3dfly"] = 5,
	["2dfly"] = 1,
}

------------------------------------------------------------
-- MoveToExact: separate lightweight state machine for precise combat movement
------------------------------------------------------------
ml_navigation_exact = {
	path = {},
	pathindex = 0,
	targetposition = nil,
	active = false,
	pending = false,
	pendingGoal = nil,
	pendingCacheId = nil,
	threshold = 0.2,
	omc_id = nil,
	omc_details = nil,
	omc_direction = 0,
	omc_starttimer = 0,
	omc_traveltimer = nil,
	omc_traveldist = 0,
	omc_startheight = nil,
	ensureposition = nil,
	ensurepositionstarttime = nil,
	lastupdate = 0,
	autoFollowNodeKey = nil,
	autoFollowLastSet = 0,
	autoFollowRefreshMs = 200,
	maxDispatchYDelta = 8,
	verticalThreshold = 1.5,
	reachedLogged = false,
	completed = false,
	lastOptimize = 0,
	requestSeq = 0,
	lastRequestId = nil,
}

local function BuildMoveToExactCacheId(startPos, goalPos)
	ml_navigation_exact.requestSeq = (ml_navigation_exact.requestSeq or 0) + 1
	local mapId = (Player and Player.localmapid) and tostring(Player.localmapid) or "0"
	local key = string.format("exact|%s|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%d",
		mapId,
		startPos.x, startPos.y, startPos.z,
		goalPos.x, goalPos.y, goalPos.z,
		ml_navigation_exact.requestSeq)
	local hash = 5381
	for i = 1, #key do
		hash = ((hash * 33) + string.byte(key, i)) % 2147483647
	end
	if (hash <= 0) then hash = 1 end
	return hash
end

------------------------------------------------------------
-- Instructions System
------------------------------------------------------------
ml_navigation.receivedInstructions = {}
ml_navigation.instructionThrottle = 0
function ml_navigation.ParseInstructions(data)
	d("Received instruction set.")
	ml_navigation.receivedInstructions = {}

	if (ValidTable(data)) then
		local itype,iparams = nil,nil
		for i,instruction in pairsByKeys(data) do
			itype,iparams = instruction[1],instruction[2]
			if (itype == "Stop") then
				table.insert(ml_navigation.receivedInstructions,
					function ()
						if (Player:IsMoving()) then
							Player:PauseMovement()
							ml_global_information.Await(1000, function () return not Player:IsMoving() end)
							return false
						else
							return true
						end
					end
				)
			elseif (itype == "Mount") then
				table.insert(ml_navigation.receivedInstructions,
					function ()
						if (not Player.ismounted) then
							Mount()
							return false
						else
							return true
						end
					end
				)
			elseif (itype == "Dismount") then
				table.insert(ml_navigation.receivedInstructions,
					function ()
						if (Player.ismounted) then
							Dismount()
							ml_global_information.Await(1000, function () return not Player.ismounted end)
							return false
						else
							return true
						end
					end
				)
			elseif (itype == "Dive") then
				table.insert(ml_navigation.receivedInstructions,
					function ()
						if (Player.diving.isswimming) then
							Player:Dive()
							ml_global_information.Await(1000, function () return not Player.diving.isswimming end)
							return false
						else
							return true
						end
					end
				)
			elseif (itype == "RefreshMesh") then
				table.insert(ml_navigation.receivedInstructions,
					function ()
						ml_mesh_mgr.lastmapid = 0
						return true
					end
				)
			elseif (itype == "Wait") then
				local length = tonumber(iparams[1]) or 150
				table.insert(ml_navigation.receivedInstructions,
					function ()
						ml_global_information.Await(length)
						return true
					end
				)
			elseif (itype == "Interact") then
				local interactid = tonumber(iparams[1]) or 0
				local complete = tonumber(iparams[2]) or ""
				table.insert(ml_navigation.receivedInstructions,
					function ()
						if (interactid ~= 0) then
							local interacts = EntityList("targetable,contentid="..tostring(interactid)..",maxdistance=15")
							if (table.valid(interacts)) then
								local i,interactable = next(interacts)
								if (table.valid(interactable) and interactable.interactable) then
									local currentTarget = Player:GetTarget()
									if (not currentTarget or currentTarget.id ~= interactable.id) then
										Player:SetTarget(interactable.id)
										return false
									end

									if (Player:IsMoving()) then
										Player:PauseMovement()
										ml_global_information.Await(1000, function () return not Player:IsMoving() end)
										return false
									end

									Player:Interact(interactable.id)
									if (string.valid(complete)) then
										local f = assert(loadstring("return " .. complete))()
										if (f ~= nil) then
											return f
										end
									end
								end
							end
						end
						return true
					end
				)
			elseif (itype == "Jump") then
				table.insert(ml_navigation.receivedInstructions,
					function ()
						if (Player:IsJumping()) then
							return true
						else
							Player:Jump()
							ml_global_information.Await(500, 2000, function () return Player:IsJumping() end)
							return false
						end
					end
				)
			elseif (itype == "FacePosition") then
				local pos = { x = iparams[1] or nil, y = iparams[2] or nil, z = iparams[3] or nil}
				if (pos.x ~= nil) then
					if (pos.y ~= nil and pos.z ~= nil) then
						table.insert(ml_navigation.receivedInstructions,
							function ()
								-- AutoFollow handles facing, skip
								return true
							end
						)
					else
						table.insert(ml_navigation.receivedInstructions,
							function ()
								-- AutoFollow handles facing, skip
								return true
							end
						)
					end
				end
			elseif (itype == "MoveForward") then
				table.insert(ml_navigation.receivedInstructions,
					function ()
						-- Legacy instruction, autofollow handles movement
						return true
					end
				)
			elseif (itype == "MoveForward2") then
				table.insert(ml_navigation.receivedInstructions,
					function ()
						-- Legacy instruction, autofollow handles movement
						return true
					end
				)
			elseif (itype == "CheckIfLocked") then
				table.insert(ml_navigation.receivedInstructions,
					function ()
						return IsPositionLocked()
					end
				)
			elseif (itype == "CheckIfMoveable") then
				table.insert(ml_navigation.receivedInstructions,
					function ()
						return not IsPositionLocked()
					end
				)
			elseif (itype == "Action") then
				local actionid = iparams[1] or 0
				local actiontype = iparams[2] or 0
				local targetid = iparams[3] or 0

				table.insert(ml_navigation.receivedInstructions,
					function ()
						if (action) then
							if (action.isoncd and ((action.cd - action.cdmax) > 2.5)) then
								return true
							else
								if (action:Cast(targetid)) then
									return true
								end
							end
						end
						return false
					end
				)
			elseif (itype == "Teleport") then
				local aetheryteid = iparams[1] or 0
				table.insert(ml_navigation.receivedInstructions,
					function ()
						if (not Player:IsMoving()) then
							if (Player:Teleport(aetheryteid)) then
								ml_global_information.Await(10000, function () return MIsLoading() end)
								return true
							end
						else
							Player:Stop()
							ml_global_information.Await(3000, function () return (not Player:IsMoving()) end)
						end
						return false
					end
				)
			elseif (itype == "Return") then
				table.insert(ml_navigation.receivedInstructions,
					function ()
						if (not Player:IsMoving()) then
							local casting = Player.castinginfo.channelingid
							local returnHome = ActionList:Get(6)

							if (returnHome and returnHome.isready) then
								if (returnHome:Cast()) then
									ml_global_information.Await(10000, function () return MIsLoading() end)
									return true
								end
							elseif (not returnHome) then
								return true
							end
						else
							Player:Stop()
							ml_global_information.Await(3000, function () return (not Player:IsMoving()) end)
						end
						return false
					end
				)
			elseif (itype == "CheckIfNear") then
				local pos = { x = iparams[1] or nil, y = iparams[2] or nil, z = iparams[3] or nil }
				local dist3d = ((iparams[4] and iparams[4] ~= 0) and iparams[4]) or 2
				local dist2d = ((iparams[5] and iparams[5] ~= 0) and iparams[5]) or 0.55

				if (pos.x ~= nil and pos.y ~= nil and pos.z ~= nil) then
					table.insert(ml_navigation.receivedInstructions,
						function ()
							local myPos = Player.pos
							return (Distance3DT(pos,myPos) <= dist3d and Distance2DT(pos,myPos) <= dist2d)
						end
					)
				end
			elseif (itype == "MoveStraightTo") then
				local pos = { x = iparams[1] or nil, y = iparams[2] or nil, z = iparams[3] or nil }
				local dist3d = ((iparams[4] and iparams[4] ~= 0) and iparams[4]) or 2
				local dist2d = ((iparams[5] and iparams[5] ~= 0) and iparams[5]) or 0.55

				local jumps = {}
				if (TableSize(iparams) > 5) then
					for i = 6,TableSize(iparams) do
						if (table.valid(iparams[i])) then
							table.insert(jumps,iparams[i])
						end
					end
				end

				if (pos.x ~= nil and pos.y ~= nil and pos.z ~= nil) then
					table.insert(ml_navigation.receivedInstructions,
						function ()
							ml_navigation:DispatchAutoFollowNode(pos, true)
							ml_global_information.AwaitDo(100, 120000,
								function ()
									if (not Player:IsMoving()) then
										return true
									end
									local myPos = Player.pos
									return (Distance3DT(pos,myPos) <= dist3d and Distance2DT(pos,myPos) <= dist2d)
								end,
								function ()
									if (not Player:IsJumping()) then
										if (table.valid(jumps)) then
											for i,jump in pairs(jumps) do
												if (Distance3DT(pos,myPos) <= 2 and Distance2DT(pos,myPos) <= 0.55) then
													Player:Jump()
												end
											end
										end
									end
								end,
								function ()
									if (Player:IsMoving()) then
										Player:PauseMovement()
										ml_global_information.Await(1000, function () return (not Player:IsMoving()) end)
									end
								end
							)
							return true
						end
					)
				end
			elseif (itype == "MoveStraightToContinue") then
				local pos = { x = iparams[1] or nil, y = iparams[2] or nil, z = iparams[3] or nil }
				local dist3d = ((iparams[4] and iparams[4] ~= 0) and iparams[4]) or 2
				local dist2d = ((iparams[5] and iparams[5] ~= 0) and iparams[5]) or 0.4

				local jumps = {}
				if (TableSize(iparams) > 5) then
					for i = 6,TableSize(iparams) do
						if (table.valid(iparams[i])) then
							table.insert(jumps,iparams[i])
						end
					end
				end

				if (pos.x ~= nil and pos.y ~= nil and pos.z ~= nil) then
					table.insert(ml_navigation.receivedInstructions,
						function ()
							ml_navigation:DispatchAutoFollowNode(pos, true)
							ml_global_information.AwaitDo(100, 120000,
								function ()
									if (not Player:IsMoving()) then
										return true
									end
									local myPos = Player.pos
									return (Distance3DT(pos,myPos) <= dist3d and Distance2DT(pos,myPos) <= dist2d)
								end,
								function ()
									if (not Player:IsJumping()) then
										if (table.valid(jumps)) then
											for i,jump in pairs(jumps) do
												if (Distance3DT(pos,myPos) <= 2 and Distance2DT(pos,myPos) <= 0.5) then
													Player:Jump()
												end
											end
										end
									end
								end
							)
							return true
						end
					)
				end
			elseif (itype == "FlyStraightTo") then
				local pos = { x = iparams[1] or nil, y = iparams[2] or nil, z = iparams[3] or nil }
				local dist3d = ((iparams[4] and iparams[4] ~= 0) and iparams[4]) or 5
				local dist2d = ((iparams[5] and iparams[5] ~= 0) and iparams[5]) or 0.75

				if (pos.x ~= nil and pos.y ~= nil and pos.z ~= nil) then
					table.insert(ml_navigation.receivedInstructions,
						function ()
							ml_navigation:DispatchAutoFollowNode(pos, true)
							ml_global_information.AwaitDo(100, 120000,
								function ()
									if (not Player:IsMoving()) then
										return true
									end
									local myPos = Player.pos
									return (Distance3DT(pos,myPos) <= dist3d and Distance2DT(pos,myPos) <= dist2d)
								end,
								function ()
									ml_navigation.SmoothFaceTarget(pos.x,pos.y,pos.z)
								end,
								function ()
									if (Player:IsMoving()) then
										Player:PauseMovement()
										ml_global_information.Await(1000, function () return (not Player:IsMoving()) end)
									end
								end
							)
							return true
						end
					)
				end
			elseif (itype == "FlyStraightToContinue") then
				local pos = { x = iparams[1] or nil, y = iparams[2] or nil, z = iparams[3] or nil }
				local dist3d = ((iparams[4] and iparams[4] ~= 0) and iparams[4]) or 5
				local dist2d = ((iparams[5] and iparams[5] ~= 0) and iparams[5]) or 0.75

				if (pos.x ~= nil and pos.y ~= nil and pos.z ~= nil) then
					table.insert(ml_navigation.receivedInstructions,
						function ()
							ml_navigation:DispatchAutoFollowNode(pos, true)
							ml_global_information.AwaitDo(100, 120000,
								function ()
									if (not Player:IsMoving()) then
										return true
									end
									local myPos = Player.pos
									return (Distance3DT(pos,myPos) <= dist3d and Distance2DT(pos,myPos) <= dist2d)
								end,
								function ()
									ml_navigation.SmoothFaceTarget(pos.x,pos.y,pos.z)
								end
							)
							return true
						end
					)
				end
			end
		end
	end
end

function ml_navigation.IsHandlingInstructions(tickcount)
	if (MPlayerDriving()) then
		ml_navigation.receivedInstructions = {}
	end

	if (ValidTable(ml_navigation.receivedInstructions)) then
		if (Now() > ml_navigation.instructionThrottle) then
			ffxivminion.UpdateGlobals()

			local newInstruction = ml_navigation.receivedInstructions[1]
			if (newInstruction and type(newInstruction) == "function") then
				local retval = newInstruction()
				if (retval == true) then
					table.remove(ml_navigation.receivedInstructions,1)
				end
			end
		end
		return true
	end
	return false
end

function ml_navigation.IsHandlingOMC(tickcount)
	if ( table.valid(ml_navigation.path) and ml_navigation.path[ml_navigation.pathindex] ~= nil) then
		if (ml_navigation.omc_id ~= nil) then
			return true
		end
	end
	return false
end

------------------------------------------------------------
-- Movement Type Helpers
------------------------------------------------------------
function ml_navigation.GetMovementType()
	if ( Player.flying.isflying ) then
		return "3dfly"
	elseif (Player.diving.isdiving) then
		return "3ddive"
	elseif (Player.diving.isswimming) then
		return "3dswim"
	elseif (Player.ismounted) then
		return "2dmount"
	else
		return "2dwalk"
	end
end

function ml_navigation.GetMovementThresholds()
	if ( Player.flying.isflying ) then
		return ml_navigation.NavPointReachedDistances["2dfly"],ml_navigation.NavPointReachedDistances["3dfly"]
	elseif (Player.diving.isdiving) then
		return ml_navigation.NavPointReachedDistances["2ddive"],ml_navigation.NavPointReachedDistances["3ddive"]
	elseif (Player.diving.isswimming) then
		return ml_navigation.NavPointReachedDistances["2dswim"],ml_navigation.NavPointReachedDistances["3dswim"]
	elseif (Player.ismounted) then
		return ml_navigation.NavPointReachedDistances["2dmount"],ml_navigation.NavPointReachedDistances["3dmount"]
	else
		return ml_navigation.NavPointReachedDistances["2dwalk"],ml_navigation.NavPointReachedDistances["3dwalk"]
	end
end

------------------------------------------------------------
-- AutoFollow Dispatch — The Single Movement Mechanism
------------------------------------------------------------
ml_navigation.canPath = false
ml_navigation.useAutoFollowPath = true
ml_navigation.autoFollowRefreshMs = 350
ml_navigation.autoFollowNodeKey = nil
ml_navigation.autoFollowLastSet = 0
ml_navigation.navAutoFollowOwned = false
ml_navigation.navAutoFollowOwner = nil

ml_navigation.EnablePathing = function (self)
	if (not self.canPath) then
		self.canPath = true
		return true
	end
	return false
end

ml_navigation.DisablePathing = function (self)
	if (self.canPath) then
		self.canPath = false
		ml_navigation:DisableAutoFollow(nil, "DisablePathing")
		return true
	end
	return false
end

ml_navigation.HasPath = function (self)
	return (table.valid(self.path))
end

ml_navigation.CanRun = function()
	return (GetGameState() == FFXIV.GAMESTATE.INGAME and not MIsLoading() and Player.alive)
end

ml_navigation.StopMovement = function()
	if (Player and Player.SetAutoFollowOn) then
		Player:SetAutoFollowOn(false)
	end
end

ml_navigation.IsMoving = function() return Player:IsMoving() end

function ml_navigation:UseAutoFollowPathing()
	return true
end

function ml_navigation:IsAutoFollowActive()
	return (Player and Player.IsAutoFollowOn and Player:IsAutoFollowOn())
end

function ml_navigation:ResetAutoFollowState()
	self.autoFollowNodeKey = nil
	self.autoFollowLastSet = 0
	self.navAutoFollowOwned = false
	self.navAutoFollowOwner = nil
end

function ml_navigation:DisableAutoFollow(force, source)
	if (Player and Player.SetAutoFollowOn) then
		if (force or self.navAutoFollowOwned) then
			Player:SetAutoFollowOn(false)
		end
	end
	self:ResetAutoFollowState()
end

function ml_navigation:DispatchAutoFollowNode(node, force)
	if (not node or not Player or not Player.SetAutoFollowPos or not Player.SetAutoFollowOn) then
		return false
	end

	local now = Now()
	local key = tostring(math.round(node.x, 2)) .. ":" .. tostring(math.round(node.y, 2)) .. ":" .. tostring(math.round(node.z, 2)) .. ":" .. tostring(self.pathindex)
	if (force or key ~= self.autoFollowNodeKey or TimeSince(self.autoFollowLastSet) >= self.autoFollowRefreshMs) then
		Player:SetAutoFollowPos(node.x, node.y, node.z)
		self.autoFollowNodeKey = key
		self.autoFollowLastSet = now
		self.navAutoFollowOwned = true
		self.navAutoFollowOwner = "moveto"
	end

	if (not Player.IsAutoFollowOn or not Player:IsAutoFollowOn()) then
		Player:SetAutoFollowOn(true)
	end
	return true
end

------------------------------------------------------------
-- Camera Follow System
------------------------------------------------------------
ml_navigation.avoidanceareasize = 2
ml_navigation.flightFollowCam = true
ml_navigation.flightFollowCamRatio = 0.015
ml_navigation.flightFollowCamPitch = -0.50
ml_navigation.flightFollowCamPitchDownRatio = 0.50
ml_navigation.followCamPitchReleaseUntil = 0
ml_navigation.followCamLastCameraPitch = nil
ml_navigation.followCamLastTargetPitch = nil
ml_navigation._lastCamApplyTime = 0

function ml_navigation:UseFlightFollowCam()
	local flightFollowCamEnabled = (gFlightFollowCam ~= nil and gFlightFollowCam) or self.flightFollowCam
	return (flightFollowCamEnabled and IsFlying())
end

function ml_navigation:UseFollowCamPitch()
	local followCamEnabled = (gFlightFollowCam ~= nil and gFlightFollowCam) or self.flightFollowCam
	return followCamEnabled
end

function ml_navigation:ApplyFollowCamPitch(targetY)
	if (not (Player and self:UseFollowCamPitch())) then
		return false
	end

	local isGround = (not IsFlying() and not IsDiving())
	local targetPitch = ml_navigation.flightFollowCamPitch or -0.50
	local pitchDownRatio = ml_navigation.flightFollowCamPitchDownRatio or 0.0
	if ((not isGround) and pitchDownRatio ~= 0 and Player and Player.flying and Player.flying.pitch and Player.pos and Player.pos.y and targetY ~= nil and targetY < Player.pos.y) then
		local downwardFlightPitch = math.abs(Player.flying.pitch)
		targetPitch = targetPitch - (downwardFlightPitch * pitchDownRatio)
	end
	targetPitch = math.max(-1.5, math.min(0.20, targetPitch))

	local cam = Player.camera
	local now = Now()
	if (isGround and table.valid(cam) and cam.pitch ~= nil) then
		local currentPitch = cam.pitch
		local diff = targetPitch - currentPitch
		if (math.abs(diff) < 0.01) then
			return true
		end
		-- User override detection: if the camera moved away from our last-set target, the user
		-- is actively moving the camera. Release for a short window so they don't fight us.
		if (self.followCamLastCameraPitch ~= nil and self.followCamLastTargetPitch ~= nil) then
			local expectedDelta = math.abs(currentPitch - self.followCamLastTargetPitch)
			local pitchMovedAway = math.abs(currentPitch - self.followCamLastCameraPitch)
			if (expectedDelta > 0.1 and pitchMovedAway > 0.05) then
				self.followCamPitchReleaseUntil = now + 3000
				self.followCamLastCameraPitch = currentPitch
				return true
			end
		end
		if (now < self.followCamPitchReleaseUntil) then
			self.followCamLastCameraPitch = currentPitch
			return true
		end
		self.followCamLastCameraPitch = currentPitch
		self.followCamLastTargetPitch = targetPitch
		if (Player.SetCamPitchSmooth) then
			Player:SetCamPitchSmooth(targetPitch)
			self._lastCamApplyTime = now
			return true
		end
		if (Player.SetCamPitch) then
			Player:SetCamPitch(targetPitch)
			self._lastCamApplyTime = now
			return true
		end
		return true
	end

	-- flight / diving: smooth cam handles it natively
	if (Player.SetCamPitchSmooth) then
		Player:SetCamPitchSmooth(targetPitch)
		self._lastCamApplyTime = now
		return true
	end
	if (Player.SetCamPitch) then
		Player:SetCamPitch(targetPitch)
		self._lastCamApplyTime = now
		return true
	end
	return true
end

function ml_navigation:ApplyFlightFollowCam(targetX, targetY, targetZ)
	if (not (Player and Player.SetCamHSmooth)) then
		return false
	end
	local cam = Player.camera
	if (not table.valid(cam) or cam.x == nil or cam.z == nil or cam.h == nil) then
		return false
	end

	local targetHeading = math.atan2((targetX - cam.x), (targetZ - cam.z))
	if (targetHeading == nil) then
		return false
	end
	targetHeading = ConvertHeading(targetHeading + math.pi) % (2 * math.pi)
	Player:SetCamHSmooth(targetHeading)

	if (Player.SetCamPitchSmooth and cam.y ~= nil) then
		local targetPitch = ml_navigation.flightFollowCamPitch or -0.50
		local pitchDownRatio = ml_navigation.flightFollowCamPitchDownRatio or 0.0
		if (pitchDownRatio ~= 0 and targetY < cam.y) then
			local downwardFlightPitch = math.abs(Player.flying.pitch or 0)
			targetPitch = targetPitch - (downwardFlightPitch * pitchDownRatio)
		end
		Player:SetCamPitchSmooth(targetPitch)
	end
	return true
end

function ml_navigation:CancelFlightFollowCam()
	self.followCamPitchReleaseUntil = 0
	self.followCamLastCameraPitch = nil
	self.followCamLastTargetPitch = nil
	self._lastCamApplyTime = 0
	if (not Player) then
		return
	end
	if (Player.SetCamHSmooth) then
		Player:SetCamHSmooth(false)
	end
	if (Player.SetCamPitchSmooth) then
		Player:SetCamPitchSmooth(false)
	end
end

function ml_navigation:EnforceGroundFollowCamPitch()
	if (not self:UseFollowCamPitch() or IsFlying() or IsDiving()) then
		return
	end
	if (not self.canPath or self.debug or not table.valid(self.path)) then
		return
	end
	local nextnode = self.path[self.pathindex]
	if (nextnode and nextnode.y ~= nil) then
		self:ApplyFollowCamPitch()
	end
end

function ml_navigation.SyncFlightFollowCamSettings()
	if gFlightFollowCam ~= nil then
		ml_navigation.flightFollowCam = gFlightFollowCam
	end
	if gFlightFollowCamRatio ~= nil then
		if (gFlightFollowCamRatio > 0 and gFlightFollowCamRatio < 1) then
			ml_navigation.flightFollowCamRatio = gFlightFollowCamRatio
		end
	end
	if gFlightFollowCamPitch ~= nil then
		ml_navigation.flightFollowCamPitch = gFlightFollowCamPitch
	end
	if gFlightFollowCamPitchDownRatio ~= nil then
		ml_navigation.flightFollowCamPitchDownRatio = gFlightFollowCamPitchDownRatio
	end
end
RegisterEventHandler("Module.Initalize", ml_navigation.SyncFlightFollowCamSettings, "ml_navigation.SyncFlightFollowCamSettings")

------------------------------------------------------------
-- Facing Utilities (external API for skills/interactions)
------------------------------------------------------------
function ml_navigation:GetHeadingDeltaAbs(currentHeading, targetHeading)
	if (currentHeading == nil or targetHeading == nil) then
		return math.huge
	end
	local diff = targetHeading - currentHeading
	while (diff > math.pi) do
		diff = diff - (2 * math.pi)
	end
	while (diff < -math.pi) do
		diff = diff + (2 * math.pi)
	end
	return math.abs(diff)
end

function ml_navigation:IsFacingHeading(targetHeading, epsilon)
	if (not Player or not Player.pos or targetHeading == nil) then
		return false
	end
	return self:GetHeadingDeltaAbs(Player.pos.h, targetHeading) <= (epsilon or 0.01)
end

function ml_navigation:IsFacingTarget(targetX, targetY, targetZ, angleEpsilon)
	if (not Player or not Player.pos) then
		return false
	end
	local ppos = Player.pos
	local dx = targetX - ppos.x
	local dz = targetZ - ppos.z
	if (math.abs(dx) < 0.001 and math.abs(dz) < 0.001) then
		return true
	end
	local angleDiff = math.angle({x = math.sin(ppos.h), y = 0, z = math.cos(ppos.h)}, {x = dx, y = 0, z = dz})
	return angleDiff <= (angleEpsilon or 2)
end

function ml_navigation:TryFaceHeading(targetHeading, epsilon)
	if (self:IsAutoFollowActive() or targetHeading == nil) then
		return false
	end
	if (self:IsFacingHeading(targetHeading, epsilon)) then
		return false
	end
	Player:SetFacing(targetHeading)
	return true
end

function ml_navigation:TryFaceTarget(targetX, targetY, targetZ, angleEpsilon)
	if (self:IsAutoFollowActive()) then
		return false
	end
	if (self:IsFacingTarget(targetX, targetY, targetZ, angleEpsilon)) then
		return false
	end
	Player:SetFacing(targetX, targetY, targetZ)
	return true
end

function ml_navigation.SmoothFaceTarget(targetX, targetY, targetZ)
	if (ml_navigation:UseFlightFollowCam()) then
		ml_navigation:ApplyFlightFollowCam(targetX, targetY, targetZ)
		return
	end
	if (not IsFlying() and not IsDiving()) then
		ml_navigation:ApplyFollowCamPitch()
	end
end

-- Flight-context raycast wrapper.

-- Only the first return value (hit bool) is used here; Raycast2 also returns
-- hit pos, triangle, raw flags, and distance if needed.
function ml_navigation.FlyRayCast(sx, sy, sz, ex, ey, ez)
	local hit = Raycast2(sx, sy, sz, ex, ey, ez, 0x4000, 0x4000)
	return hit
end

function ml_navigation:IsDirectFlightCorridorClear(fromPos, toPos, maxDistance)
	if (not table.valid(fromPos) or not table.valid(toPos)) then
		return false
	end

	local maxRange = maxDistance or 100
	local dist = math.distance3d(fromPos, toPos)
	if (not dist or dist <= 0 or dist > maxRange) then
		return false
	end

	local baseFromY = fromPos.y + 1.0
	local baseToY = toPos.y + 1.0

	-- Centerline clearance at body height.
	if (ml_navigation.FlyRayCast(fromPos.x, baseFromY, fromPos.z, toPos.x, baseToY, toPos.z)) then
		return false
	end

	-- Upper-body/head clearance.
	if (ml_navigation.FlyRayCast(fromPos.x, baseFromY + 1.5, fromPos.z, toPos.x, baseToY + 1.5, toPos.z)) then
		return false
	end

	-- Side clearance to reduce clipping on narrow diagonals.
	local dx = toPos.x - fromPos.x
	local dz = toPos.z - fromPos.z
	local mag = math.sqrt((dx * dx) + (dz * dz))
	if (mag and mag > 0.001) then
		local ox = (-dz / mag) * 0.4
		local oz = (dx / mag) * 0.4
		if (ml_navigation.FlyRayCast(fromPos.x + ox, baseFromY, fromPos.z + oz, toPos.x + ox, baseToY, toPos.z + oz)) then
			return false
		end
		if (ml_navigation.FlyRayCast(fromPos.x - ox, baseFromY, fromPos.z - oz, toPos.x - ox, baseToY, toPos.z - oz)) then
			return false
		end
	end

	return true
end

function ml_navigation:ApplyLandingFallbackToCurrentPath(fallbackX, fallbackY, fallbackZ)
	if (not table.valid(self.path) or not self.pathindex) then
		return false
	end

	local node = self.path[self.pathindex]
	if (not node) then
		return false
	end

	node.x = fallbackX
	node.y = fallbackY
	node.z = fallbackZ
	ml_navigation.ScrubToGroundEndpoint(node)

	for ri = self.pathindex + 1, self.pathindex + 50 do
		if (self.path[ri] == nil) then break end
		self.path[ri] = nil
	end

	return true
end

------------------------------------------------------------
-- GUI state
------------------------------------------------------------
ml_navigation.GUI = {
	pathHops = 0,
	currentIndex = 0,
	nextNodeDistance = 0,
	lastAction = "",
}

------------------------------------------------------------
-- Distance & Goal Checks
------------------------------------------------------------
function ml_navigation:GetRaycast_Player_Node_Distance(ppos,nodepos)
	local dist = math.distance3d(ppos,nodepos)
	local dist2d = math.distance2d(ppos,nodepos)
	if ( not IsFlying() ) then
		if ( dist2d < 5 ) then
			local hit, hitx, hity, hitz = RayCast(nodepos.x,nodepos.y+2,nodepos.z,nodepos.x,nodepos.y-3,nodepos.z)
			if ( hit ) then
				local noderealpos = { x = nodepos.x, y = hity + 0.1, z = nodepos.z }
				dist = math.distance3d(ppos,noderealpos)
			end
			hit, hitx, hity, hitz = RayCast(ppos.x,ppos.y+2,ppos.z,ppos.x,ppos.y-3,ppos.z)
			if ( hit ) then
				local playerrealpos = { x = ppos.x, y = hity + 0.1, z = ppos.z }
				local noderealpos = { x = nodepos.x, y = nodepos.y, z = nodepos.z }
				local hit2, hitx2, hity2, hitz2 = RayCast(nodepos.x,nodepos.y+2,nodepos.z,nodepos.x,nodepos.y-3,nodepos.z)
				if ( hit2 ) then
					noderealpos = { x = nodepos.x, y = hity2 + 0.1, z = nodepos.z }
				end
				dist = math.distance3d(playerrealpos,noderealpos)
			end
		end
	end
	return dist,dist2d
end

function ml_navigation:IsGoalClose(ppos,node,lastnode)
	local goaldist,goaldist2d = ml_navigation:GetRaycast_Player_Node_Distance(ppos,node)
	local lastdist,lastdist2d,lastgoal,lastgoal2d;
	if (table.valid(lastnode)) then
		lastdist,lastdist2d = ml_navigation:GetRaycast_Player_Node_Distance(lastnode,ppos)
		lastgoal,lastgoal2d = ml_navigation:GetRaycast_Player_Node_Distance(lastnode,node)
	end
	local isLast = (ml_navigation.path[ml_navigation.pathindex+1]==nil)

	-- Floor2Cube connections have a radius in which the player is allowed to traverse
	local nc
	local ncsubtype
	local ncdirectionFromA
	if (node.navconnectionid and node.navconnectionid ~= 0) then
		if (NavigationManager.ShowCells == nil ) then
			if (table.valid(ml_mesh_mgr.navconnections)) then
				nc = ml_mesh_mgr.navconnections[node.navconnectionid]
			end
			ncsubtype = nc.subtype
		else
			nc = NavigationManager:GetNavConnection(node.navconnectionid)
			if (nc.details and nc.details.subtype) then
				ncsubtype = nc.details.subtype
			end
		end
		if (nc and nc.type ~= 5) then -- Type 5 == MacroMesh
			local ncradius
			if(node.navconnectionsideA ~= nil ) then
				if(node.navconnectionsideA == true) then
					ncradius = nc.sideA.radius
					ncdirectionFromA = true
				else
					ncradius = nc.sideB.radius
					ncdirectionFromA = false
				end
			else
				ncradius = nc.radius
			end

			if (nc.type == 3) then
				goaldist2d = goaldist2d - ncradius
				if (math.abs(ppos.y-node.y) < 3) then
					goaldist = goaldist - ncradius
				end
			else
				goaldist = goaldist - ncradius
				goaldist2d = goaldist2d - ncradius
			end
		end
	end

	if (Player.flying.isflying) then
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dfly"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dfly"]) then
			self:ResetOMCHandler()
			if ( nc and In(ncsubtype,1,2,3,4)) then
				self.omc_id = nc.id
				self.omc_details = nc
				if(ncdirectionFromA~=nil) then
					self.omc_direction = ncdirectionFromA == true and 1 or 2
				end
			end
			return true
		end
	elseif (Player.diving.isdiving) then
		if (goaldist <= ml_navigation.NavPointReachedDistances["3ddive"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2ddive"]) then
			self:ResetOMCHandler()
			if ( nc and In(ncsubtype,1,2,3,4)) then
				self.omc_id = nc.id
				self.omc_details = nc
				if(ncdirectionFromA~=nil) then
					self.omc_direction = ncdirectionFromA == true and 1 or 2
				end
			end
			return true
		end
	elseif (Player.diving.isswimming) then
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dswim"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dswim"]) then
			self:ResetOMCHandler()
			if ( nc and In(ncsubtype,1,2,3,4)) then
				self.omc_id = nc.id
				self.omc_details = nc
				if(ncdirectionFromA~=nil) then
					self.omc_direction = ncdirectionFromA == true and 1 or 2
				end
			end
			return true
		end
	elseif (Player.ismounted) then
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dmount"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dmount"]) then
			if (isLast or lastdist == nil or lastdist >= lastgoal or goaldist <= 1.0) then
				self:ResetOMCHandler()
				if ( nc and In(ncsubtype,1,2,3,4)) then
					self.omc_id = nc.id
					self.omc_details = nc
					if(ncdirectionFromA~=nil) then
						self.omc_direction = ncdirectionFromA == true and 1 or 2
					end
				end
				return true
			end
		end
	else
		if (goaldist <= ml_navigation.NavPointReachedDistances["3dwalk"] and goaldist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
			if (isLast or lastdist == nil or lastdist >= lastgoal or goaldist <= 1.0) then
				self:ResetOMCHandler()
				if ( nc and In(ncsubtype,1,2,3,4)) then
					self.omc_id = nc.id
					self.omc_details = nc
					if(ncdirectionFromA~=nil) then
						self.omc_direction = ncdirectionFromA == true and 1 or 2
					end
				end
				return true
			end
		end
	end
	self.omc_direction = 0
	return false
end

------------------------------------------------------------
-- Flight Helpers
------------------------------------------------------------
function ml_navigation:CanContinueFlying()
	if (table.valid(self.path)) then
		local dist = math.distance3d(Player.pos,ml_navigation.targetposition)
		local pathsize = table.size(self.path)
		if (dist > 15) then
			for index,node in pairsByKeys(self.path) do
				if (index > self.pathindex and (node.type == GLOBAL.NODETYPE.CUBE) and
					(dist > 30 or IsNull(node.flags,0) == 0 or (node.flags and bit.band(node.flags, GLOBAL.CUBE.AIR) ~= 0)))
				then
					return true
				end
			end
		end
	end
	return false
end

function ml_navigation:GetConnection(node)
	local navcon
	if (node.navconnectionid and node.navconnectionid ~= 0) then
		if (NavigationManager.ShowCells == nil) then
			navcon = ml_mesh_mgr.navconnections[node.navconnectionid]
		else
			navcon = NavigationManager:GetNavConnection(node.navconnectionid)
		end
	end
	return navcon
end

function ml_navigation:IsUsingConnection()
	if (self.omc_id and self.omc_details) then
		return true
	end
	local lastnode = self.path[self.pathindex - 1]
	if (table.valid(lastnode)) then
		if (lastnode.navconnectionid and lastnode.navconnectionid ~= 0) then
			local nc = self:GetConnection(lastnode)
			if (nc) then
				if (nc.type == 3) then
					local nodeAfter = self.path[self.pathindex]
					if (nodeAfter and nodeAfter.is_cube) then
						return true
					end
				end
				if (nc.type == 1 or nc.type == 2 or nc.type == 4) then
					return true
				end
			end
		end
	end
	return false
end

------------------------------------------------------------
-- Node Tagging
------------------------------------------------------------
function ml_navigation.TagNode(node)
	if (table.valid(node) and not node.is_tagged) then
		node.is_start = (bit.band(node.type2, 1) ~= 0)
		node.is_end = (bit.band(node.type2, 2) ~= 0)
		node.is_omc = (bit.band(node.type2, 4) ~= 0)

		node.is_floor = (node.type == GLOBAL.NODETYPE.FLOOR)
		node.is_cube = (node.type == GLOBAL.NODETYPE.CUBE)

		local flags = node.flags

		node.ground, node.ground_water, node.ground_border, node.ground_avoid, node.air, node.water, node.air_avoid = false, false, false, false, false, false, false
		if (node.is_floor) then
			node.ground = (bit.band(flags, GLOBAL.FLOOR.GROUND) ~= 0 or (flags == 0 and (not node.is_start or not IsFlying())))
			node.ground_water = (bit.band(flags, GLOBAL.FLOOR.WATER) ~= 0)
			node.ground_border = (bit.band(flags, GLOBAL.FLOOR.BORDER) ~= 0)
			node.ground_avoid = (bit.band(flags, GLOBAL.FLOOR.AVOID) ~= 0)
			node.air = false
			node.water = false
			node.air_avoid = false
		elseif (node.is_cube) then
			node.air = (bit.band(flags, GLOBAL.CUBE.AIR) ~= 0 or IsNull(flags,0) == 0)
			node.water = (bit.band(flags, GLOBAL.CUBE.WATER) ~= 0)
			node.air_avoid = (bit.band(flags, GLOBAL.CUBE.AVOID) ~= 0)
			node.ground = false
			node.ground_water = false
			node.ground_border = false
			node.ground_avoid = false
		end

		node.cubecube = false
		node.floorfloor = false
		node.floorcube = false

		if (node.navconnectionid and node.navconnectionid ~= 0) then
			local navcon = NavigationManager:GetNavConnection(node.navconnectionid)
			if (navcon) then
				node.cubecube = (navcon.type == 1)
				node.floorfloor = (navcon.type == 2)
				node.floorcube = (navcon.type == 3)
			end
		end

		node.is_tagged = true
	end
end

-- Turn a node into a plain ground-floor endpoint. Used after an in-place
-- landing-fallback rewrite so ground navigation treats the rewritten node as
-- a regular arrival point (no nav-connection, no cube/floorcube/air/water
-- flags, no remount-for-flight trigger, no engine-owned raycast-down fixups).
function ml_navigation.ScrubToGroundEndpoint(node)
	if (not node) then return end
	node.navconnectionid = 0
	node.type = GLOBAL.NODETYPE.FLOOR
	node.type2 = 2 -- is_end bit only
	node.flags = 0
	node.is_start = false
	node.is_end = true
	node.is_omc = false
	node.is_floor = true
	node.is_cube = false
	node.ground = true
	node.ground_water = false
	node.ground_border = false
	node.ground_avoid = false
	node.air = false
	node.water = false
	node.air_avoid = false
	node.cubecube = false
	node.floorfloor = false
	node.floorcube = false
	node.is_tagged = true
end

------------------------------------------------------------
-- Flight Transition Guards
------------------------------------------------------------
function ml_navigation:GetFlightTransitionKey(pathindex, nextnode, nextnextnode)
	local n1 = nextnode or {}
	local n2 = nextnextnode or {}
	local n1tags = string.format("fc:%d,a:%d,g:%d,c:%d", n1.floorcube and 1 or 0, n1.air and 1 or 0, n1.ground and 1 or 0, n1.is_cube and 1 or 0)
	local n2tags = string.format("fc:%d,a:%d,g:%d,c:%d", n2.floorcube and 1 or 0, n2.air and 1 or 0, n2.ground and 1 or 0, n2.is_cube and 1 or 0)
	return tostring(pathindex) .. "|" .. tostring(n1.navconnectionid or 0) .. "|" .. tostring(n2.navconnectionid or 0) .. "|" .. n1tags .. "|" .. n2tags
end

function ml_navigation:IsUnstableFlightTransition(nextnode, nextnextnode)
	if (not nextnode) then
		return false
	end
	local nextAir = (nextnode.air == true)
	local nextGround = (nextnode.ground == true)
	local nextFloorCube = (nextnode.floorcube == true)
	local n2Air = (nextnextnode and nextnextnode.air == true) or false
	local n2Ground = (nextnextnode and nextnextnode.ground == true) or false
	local n2FloorCube = (nextnextnode and nextnextnode.floorcube == true) or false

	if (nextFloorCube and nextAir and nextGround) then
		return true
	end
	if (nextFloorCube and nextAir and n2FloorCube and n2Ground and not n2Air) then
		return true
	end
	return false
end

function ml_navigation:IsFlightActionThrottled(action, pathindex, nextnode, nextnextnode)
	if (not ffnav.flightLoopGuard) then
		ffnav.flightLoopGuard = { key = nil, lastAction = nil, lastTime = 0, count = 0, lockUntil = 0 }
	end

	local guard = ffnav.flightLoopGuard
	local now = Now()
	if (now < (guard.lockUntil or 0)) then
		return true
	end

	local key = self:GetFlightTransitionKey(pathindex, nextnode, nextnextnode)
	if (guard.key == key and TimeSince(guard.lastTime or 0) < 3500) then
		if (guard.lastAction ~= action or action == "mount_fail") then
			guard.count = (guard.count or 0) + 1
		end
	else
		guard.count = 0
	end

	guard.key = key
	guard.lastAction = action
	guard.lastTime = now

	if ((guard.count or 0) >= 4) then
		guard.lockUntil = now + 2500
		guard.count = 0
		d("[Navigation] - Flight transition loop detected, throttling actions for 2500ms.")
		return true
	end
	return false
end

function ml_navigation:ResetFlightActionThrottle(clearLock)
	if (not ffnav.flightLoopGuard) then
		ffnav.flightLoopGuard = { key = nil, lastAction = nil, lastTime = 0, count = 0, lockUntil = 0 }
		return
	end
	ffnav.flightLoopGuard.key = nil
	ffnav.flightLoopGuard.lastAction = nil
	ffnav.flightLoopGuard.lastTime = 0
	ffnav.flightLoopGuard.count = 0
	if (clearLock) then
		ffnav.flightLoopGuard.lockUntil = 0
	end
end

------------------------------------------------------------
-- OMC State Management
------------------------------------------------------------
function ml_navigation:SetEnsureStartPosition(nextnode, playerpos, navconnection, nearsidepos, farsidepos, nearheading)
	local nearside, farside
	if( not nearsidepos ) then
		if (math.distance3d(playerpos, navconnection.from) < math.distance3d(playerpos, navconnection.to) ) then
			nearside = navconnection.from
			farside = navconnection.to
		else
			nearside = navconnection.to
			farside = navconnection.from
		end
	else
		nearside = nearsidepos
		nearside.hx = nearheading
		farside = farsidepos
	end

	self.ensureposition = {x = nearside.x, y = nearside.y, z = nearside.z}
	-- AutoFollow handles facing, skip heading enforcement
	self.ensureheading = nil
	self.ensureheadingtargetpos = nil
	d("[OMC-DBG] SetEnsureStartPos target=" .. tostring(nearside.x) .. "," .. tostring(nearside.y) .. "," .. tostring(nearside.z) .. " ppos=" .. tostring(playerpos.x) .. "," .. tostring(playerpos.y) .. "," .. tostring(playerpos.z))
	return self:EnsurePosition(playerpos)
end

function ml_navigation:EnsurePosition(ppos)
	if ( not self.ensurepositionstarttime ) then self.ensurepositionstarttime = ml_global_information.Now end

	local dist = self:GetRaycast_Player_Node_Distance(ppos,self.ensureposition)
	d("[OMC-DBG] EnsurePos dist=" .. tostring(dist) .. " elapsed=" .. tostring(ml_global_information.Now - self.ensurepositionstarttime) .. " moving=" .. tostring(Player:IsMoving()) .. " jumping=" .. tostring(Player:IsJumping()))

	if ( (ml_global_information.Now - self.ensurepositionstarttime) < 1000) then
		if ( not Player:IsMoving () and dist > 0.5 and dist < 3.0 ) then
			if ( Player:IsJumping() ) then
				return true
			else
				Hacks:TeleportToXYZ(self.ensureposition.x,self.ensureposition.y,self.ensureposition.z)
				d("[Navigation:EnsurePosition]: TP to correct Start Position.")
			end
		end
	else
		d("[Navigation]: [EnsurePosition] - ResetOMCHandler, we waited longer than 1 second..")
		self:ResetOMCHandler()
		return false
	end

	if ( (ml_global_information.Now - self.ensurepositionstarttime) < 400) then
		return true
	else
		self.ensureposition = nil
		return false
	end
end

function ml_navigation:ResetOMCHandler()
	self.ensureposition = nil
	self.ensureheading = nil
	self.ensureheadingtargetpos = nil
	self.ensurepositionstarttime = nil
	self.omc_id = nil
	self.omc_traveltimer = nil
	self.omc_starttimer = 0
	self.omc_startheight = nil
	self.omc_details = nil
	self.omc_traveldist = 0
	self.omc_traveltimer = nil
	self.omc_direction = 0
	self.omc_jumpretries = nil
	self.omc_interact_pos = nil
	self.lastupdate = 0
end

------------------------------------------------------------
-- Path Checking & Building
------------------------------------------------------------
function ml_navigation:CheckPath(pos2,floorfilters,cubefilters)
	local pos = Player.pos
	if (not table.valid(pos2)) then
		return false
	end

	local floorfilters = IsNull(floorfilters,0,true)
	local cubefilters = IsNull(cubefilters,0,true)

	if (not IsFlying() and not IsDiving() and ((Player.incombat and not Player.ismounted) or IsTransporting())) then
		cubefilters = bit.bor(cubefilters, GLOBAL.CUBE.AIR)
	end
	NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.CUBE, cubefilters)
	NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.FLOOR, floorfilters)
	if In(Player.localmapid,1237) then
		local retval = Transport1237(pos,pos2)
		if (retval == true) then
			reachable = true
		end
	end

	local reachable = NavigationManager:IsReachable(pos2)
	if (not reachable) then
		local transportFunction = _G["Transport"..tostring(Player.localmapid)]
		if (transportFunction ~= nil and type(transportFunction) == "function") then
			local retval = transportFunction(pos,pos2)
			if (retval == true) then
				reachable = true
			end
		end
	end

	return reachable
end

function Player:MoveTo(x, y, z, dist, floorfilters, cubefilters, targetid)
	local floorfilters = IsNull(floorfilters,0,true)
	local cubefilters = IsNull(cubefilters,0,true)

	-- Cancel any active MoveToExact when normal MoveTo is called
	if (ml_navigation_exact.active) then
		Player:StopExact()
	end

	if (MPlayerDriving()) then
		d("[NAVIGATION]: Releasing control to Player..")
		ml_navigation:ResetCurrentPath()
		return -1337
	end

	local ret = Player:BuildPath(x, y, z, floorfilters, cubefilters, targetid)
	if (ml_navigation:HasPath()) then
		if (ml_navigation:EnablePathing()) then
		end
	else
		if (ml_navigation:DisablePathing()) then
		end
	end
	return ret
end

ml_navigation.lastPathUpdate = 0
ml_navigation.pathchanged = false
ml_navigation.lastBuildCall = 0
ml_navigation.lastpos = {x=0, y=0, z=0}

-- Temporary floor-cube connections created on-demand for transitions
ml_navigation.tempFloorCubeConnections = {}

function ml_navigation:CleanupTempConnections()
	for _, connId in ipairs(self.tempFloorCubeConnections) do
		NavigationManager:RemoveNavConnection(connId)
	end
	self.tempFloorCubeConnections = {}
end

function ml_navigation:CreateTempFloorCubeConnection(pos, direction)
	local result = NavigationManager:FindFloorCubeConnectionPoint(pos.x, pos.y, pos.z, direction)
	if result then
		local connId = NavigationManager:CreateNavConnection({
			type = 3, -- NC_POLY_TO_CUBE
			radius = result.radius or 3,
			bidirectional = true,
			from = result.floor,
			to = result.cube,
		})
		if connId then
			table.insert(self.tempFloorCubeConnections, connId)
			return connId
		end
	end
	return nil
end

function Player:BuildPath(x, y, z, floorfilters, cubefilters, targetid, force)
	ml_navigation.debug = nil
	local floorfilters = IsNull(floorfilters,0,true)
	local cubefilters = IsNull(cubefilters,0,true)

	if (targetid == 0) then
		targetid = nil
	end

	if (MPlayerDriving()) then
		d("[NAVIGATION]: Releasing control to Player..")
		ml_navigation:ResetCurrentPath()
		return -1337
	end

	if (x == nil or y == nil or z == nil) then
		d("[NAVIGATION]: Invalid Move To Position :["..tostring(x)..","..tostring(y)..","..tostring(z).."]")
		return 0
	end

	local ppos = Player.pos
	local newGoal = { x = x, y = y, z = z }

	local hasCurrentPath = table.valid(ml_navigation.path)
	local currentPathSize = table.size(ml_navigation.path)
	local sametarget = ml_navigation.lasttargetid and targetid and ml_navigation.lasttargetid == targetid
	local hasPreviousPath = hasCurrentPath and table.valid(newGoal) and table.valid(ml_navigation.targetposition) and ( (not sametarget and math.distance3d(newGoal,ml_navigation.targetposition) < 1) or sametarget )
	if (hasPreviousPath and (ml_navigation.lastconnectionid ~= 0 or ffnav.isascending or ffnav.isdescending) and (TimeSince(ml_navigation.lastconnectiontimer) < 5000)) then
		d("[NAVIGATION]: We are currently using a Navconnection / ascending / descending, wait until we finish to pull a new path.")
		return currentPathSize
	end
	if not force and (((newGoal.x == ml_navigation.lastpos.x and newGoal.z == ml_navigation.lastpos.z) or ((IsFlying() or IsDiving()) and targetid ~= nil and targetid == ml_navigation.lasttargetid))
		 and (hasPreviousPath and (TimeSince(ml_navigation.lastBuildCall) < 2000))) then
		return currentPathSize
	end

	local distanceToGoal = math.distance2d(newGoal.x,newGoal.z,ppos.x,ppos.z)

	-- Landing clearance: if a fallback is active, redirect the path goal.
	if (ffnav.landingFallbackActive and ffnav.landingFallbackPos) then
		if (ffnav.landingFallbackOrigin and math.distance3d(ffnav.landingFallbackOrigin, newGoal) < 3) then
			newGoal = { x = ffnav.landingFallbackPos.x, y = ffnav.landingFallbackPos.y, z = ffnav.landingFallbackPos.z }
			x, y, z = newGoal.x, newGoal.y, newGoal.z
		elseif (math.distance3d(ffnav.landingFallbackPos, newGoal) < 1) then
			-- Already targeting fallback
		else
			ffnav.landingFallbackActive = false
			ffnav.landingFallbackPos = nil
			ffnav.landingFallbackOrigin = nil
			ffnav.landingFallbackSmoothed = false
		end
	end

	-- If the current path was already smoothed in-place toward the fallback
	-- landing spot and the incoming goal resolves to that same fallback,
	-- keep the existing path instead of rebuilding. A rebuild here would
	-- create temp floor-cube NavConnections at the flying player's position
	-- and route the approach up through a cube detour (the "up into the air
	-- then down again" behaviour), and would also dirty NavConnectionMgr.
	if (not force and ffnav.landingFallbackActive and ffnav.landingFallbackSmoothed
		and ffnav.landingFallbackPos and hasCurrentPath
		and math.distance3d(ffnav.landingFallbackPos, newGoal) < 2) then
		d("[NAVIGATION]: Landing fallback is smoothed in-place, skipping rebuild.")
		return currentPathSize
	end

	-- Filter things for special tasks/circumstances
	if ((not IsFlying() and not IsDiving() and ((Player.incombat and (not Player.ismounted)) or IsTransporting())) or
		not CanFlyInZone())
	then
		cubefilters = bit.bor(cubefilters, GLOBAL.CUBE.AIR)
	end
	if (not CanDiveInZone()) then
		cubefilters = bit.bor(cubefilters, GLOBAL.CUBE.WATER)
	end

	-- Unfilter things that we need
	if (IsDiving() and bit.band(cubefilters, GLOBAL.CUBE.WATER) ~= 0) then
		cubefilters = bit.bxor(cubefilters, GLOBAL.CUBE.WATER)
	elseif (IsFlying() and bit.band(cubefilters, GLOBAL.CUBE.AIR) ~= 0) then
		cubefilters = bit.bxor(cubefilters, GLOBAL.CUBE.AIR)
	end

	NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.CUBE, cubefilters)
	NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.FLOOR, floorfilters)

	-- Create temporary floor-cube connections on-demand if transitioning between floor and cube
	ml_navigation:CleanupTempConnections()
	local canUseCubes = (bit.band(cubefilters, GLOBAL.CUBE.AIR) == 0) or (bit.band(cubefilters, GLOBAL.CUBE.WATER) == 0)
	if canUseCubes then
		local playerOnFloor = not IsFlying() and not IsDiving()
		local goalOnFloor = NavigationManager:IsOnMesh(newGoal.x, newGoal.y, newGoal.z)
		local goalInCubes = NavigationManager:GetClosestPointInCubes(newGoal)
		local goalInAir = goalInCubes and goalInCubes.distance and goalInCubes.distance < 5

		-- Player on floor, goal in air/water → landing side may still need a temporary "down" connection near the goal.
		if playerOnFloor and goalInAir and not goalOnFloor then
			ml_navigation:CreateTempFloorCubeConnection(newGoal, "down")
		end
		-- Player in air/water, goal on floor → need "down" connection near goal
		if not playerOnFloor and goalOnFloor and not goalInAir then
			ml_navigation:CreateTempFloorCubeConnection(newGoal, "down")
			ml_navigation:CreateTempFloorCubeConnection(ppos, "down")
		end
	end

	local ret = ml_navigation:MoveTo(newGoal.x,newGoal.y,newGoal.z, targetid)

	ml_navigation.lastPathUpdate = Now()
	ml_navigation.lastconnectionid = 0
	ml_navigation.lastconnectiontimer = 0

	if (ret <= 0) then
		if ((IsFlying() or IsDiving()) and hasPreviousPath) then
			d("[NAVIGATION]: Encountered an issue on path pull, using previous path, errors may be encountered here.")
			return currentPathSize
		else
			ml_navigation:ResetCurrentPath()
		end
		local ppos = Player.pos
		ml_navigation.startposition = { x=0, y=0, z=0 }
		ml_navigation.targetposition = { x=0, y=0, z=0 }
		ml_navigation.lasttargetid = nil
	else
		ml_navigation.startposition = { x=ppos.x, y=ppos.y, z=ppos.z }
		ml_navigation.targetposition = newGoal
		ml_navigation.lasttargetid = targetid
	end

	if (ret > 0 and hasCurrentPath) then
		for _,node in pairs(ml_navigation.path) do
			ml_navigation.TagNode(node)
		end
	end

	-- Straighten takeoff path: realign the floor approach node (before the first cube node)
	-- to the player's current ground position, removing the lateral detour that temp
	-- floor-cube navcon anchors introduce.
	if (ret > 0 and canUseCubes and not IsFlying() and not IsDiving()) then
		local cacheId = ml_navigation.path[1] and ml_navigation.path[1].id or 0
		if cacheId ~= 0 then
			local straightPath = NavigationManager:StraightenTakeoffPath(cacheId, ppos.x, ppos.y, ppos.z)
			if table.valid(straightPath) then
				ml_navigation.path = straightPath
				for _,node in pairs(ml_navigation.path) do
					ml_navigation.TagNode(node)
				end
			end
		end
	end

	ml_navigation.lastBuildCall = Now()
	ml_navigation.lastpos = newGoal
	return ret
end

------------------------------------------------------------
-- MoveToExact System
------------------------------------------------------------
function Player:MoveToExact(x, y, z, threshold, disableSmoothing)
	if (not x or not y or not z) then return -1 end

	local thresh = threshold or 0.2
	local noSmoothing = (disableSmoothing == true)

	local ep = ml_navigation_exact
	if (ep.active and ep.path ~= nil) then
		local enddata = ep.path[#ep.path]
		if (enddata~=nil) then
			local endpos = {x=enddata.x,y=enddata.y,z=enddata.z}
			if (math.distance3d(endpos,{x=x,y=y,z=z})<= thresh) then
				d("path requested for same destination, ignore request and keep naving")
				return
			end
		end
	end

    if (not ml_navigation_exact.active) then
        -- Clean slate
        ml_navigation:DisableAutoFollow(true, "MoveToExact start")

        if (ml_navigation.canPath) then
            ml_navigation:DisablePathing()
        end

        ml_navigation_exact.Reset()
    end

	ml_navigation_exact.Reset()

	local ppos = Player.pos
	if (not ppos) then return -1 end
	local goal = { x = x, y = y, z = z }
	local cacheId = BuildMoveToExactCacheId(ppos, goal)

	-- Exclude AIR and WATER cubes — ground only
	if (GLOBAL and GLOBAL.CUBE) then
		local cubeExclude = 0
		if (GLOBAL.CUBE.AIR) then cubeExclude = bit.bor(cubeExclude, GLOBAL.CUBE.AIR) end
		if (GLOBAL.CUBE.WATER) then cubeExclude = bit.bor(cubeExclude, GLOBAL.CUBE.WATER) end
		if (cubeExclude ~= 0) then
			NavigationManager:SetExcludeFilter(GLOBAL.NODETYPE.CUBE, cubeExclude)
		end
	end

	d("[MoveToExact]: Requesting fresh path. cacheId=" .. tostring(cacheId))
	local result = NavigationManager:GetPathAsync(ppos.x, ppos.y, ppos.z, x, y, z, cacheId, false, true)

	if (type(result) == "table" and table.valid(result)) then
		ml_navigation_exact.path = result
		ml_navigation_exact.pathindex = 1
		ml_navigation_exact.active = true
		ml_navigation_exact.pending = false
		ml_navigation_exact.pendingCacheId = nil
		ml_navigation_exact.threshold = thresh
		ml_navigation_exact.disableSmoothing = noSmoothing
		ml_navigation_exact.targetposition = goal
		ml_navigation_exact.lastRequestId = cacheId
		for _, node in pairs(ml_navigation_exact.path) do
			ml_navigation.TagNode(node)
		end
		ml_navigation_exact.OptimizeCachedPath(ppos, noSmoothing)
		return table.size(ml_navigation_exact.path)
	elseif (type(result) == "number" and result > 0) then
		ml_navigation_exact.active = true
		ml_navigation_exact.pending = true
		ml_navigation_exact.pendingGoal = goal
		ml_navigation_exact.pendingCacheId = cacheId
		ml_navigation_exact.threshold = thresh
		ml_navigation_exact.disableSmoothing = noSmoothing
		ml_navigation_exact.targetposition = goal
		ml_navigation_exact.lastRequestId = cacheId
		d("[MoveToExact]: Path queued. cacheId=" .. tostring(cacheId))
		return 0
	else
		d("[MoveToExact]: Path request failed. cacheId=" .. tostring(cacheId))
		return -1
	end
end

function Player:StopExact()
	local wasActive = ml_navigation_exact.active
	ml_navigation_exact.Reset()
	if (wasActive) then
		Player:StopMovement()
		ml_navigation:DisableAutoFollow(true, "StopExact")
	end
end

function Player:IsExactMoving()
	return ml_navigation_exact.active
end

function ml_navigation_exact.Reset()
	ml_navigation_exact.path = {}
	ml_navigation_exact.pathindex = 0
	ml_navigation_exact.targetposition = nil
	ml_navigation_exact.active = false
	ml_navigation_exact.pending = false
	ml_navigation_exact.pendingGoal = nil
	ml_navigation_exact.pendingCacheId = nil
	ml_navigation_exact.threshold = 0.2
	ml_navigation_exact.omc_id = nil
	ml_navigation_exact.omc_details = nil
	ml_navigation_exact.omc_direction = 0
	ml_navigation_exact.omc_starttimer = 0
	ml_navigation_exact.omc_traveltimer = nil
	ml_navigation_exact.omc_traveldist = 0
	ml_navigation_exact.omc_startheight = nil
	ml_navigation_exact.ensureposition = nil
	ml_navigation_exact.ensurepositionstarttime = nil
	ml_navigation_exact.lastupdate = 0
	ml_navigation_exact.autoFollowNodeKey = nil
	ml_navigation_exact.autoFollowLastSet = 0
	ml_navigation_exact.reachedLogged = false
	ml_navigation_exact.completed = false
	ml_navigation_exact.lastOptimize = 0
	ml_navigation_exact.lastRequestId = nil
	ml_navigation_exact.disableSmoothing = false
end

function ml_navigation_exact.ResetOMCState()
	ml_navigation_exact.omc_id = nil
	ml_navigation_exact.omc_details = nil
	ml_navigation_exact.omc_direction = 0
	ml_navigation_exact.omc_starttimer = 0
	ml_navigation_exact.omc_traveltimer = nil
	ml_navigation_exact.omc_traveldist = 0
	ml_navigation_exact.omc_startheight = nil
	ml_navigation_exact.omc_jumpretries = nil
	ml_navigation_exact.ensureposition = nil
	ml_navigation_exact.ensurepositionstarttime = nil
end

function ml_navigation_exact.ResetAutoFollowState()
	ml_navigation_exact.autoFollowNodeKey = nil
	ml_navigation_exact.autoFollowLastSet = 0
end

function ml_navigation_exact.OptimizeCachedPath(ppos, disableSmoothing)
	local self = ml_navigation_exact
	local tp = self.targetposition
	if (not tp or not ppos or not table.valid(self.path)) then return false end

	-- Pass the cache ID so OptimizePath can find the MoveToExact path cache.
	local cacheId = self.lastRequestId or 0
	local optimized = NavigationManager:OptimizePath(ppos.x, ppos.y, ppos.z, tp.x, tp.y, tp.z, cacheId)
	if (type(optimized) == "table" and table.valid(optimized)) then
		for _, node in pairs(optimized) do
			ml_navigation.TagNode(node)
		end
		self.path = optimized
		self.pathindex = 1
		self.lastOptimize = Now()
	end

	-- Second pass: smoothing
	if (not disableSmoothing and cacheId ~= 0 and NavigationManager.SmoothPath) then
		local smoothed = NavigationManager:SmoothPath(cacheId, ppos.x, ppos.y, ppos.z)
		if (type(smoothed) == "table" and table.valid(smoothed)) then
			local removed = smoothed[1] and smoothed[1].smoothed or 0
			for _, node in pairs(smoothed) do
				ml_navigation.TagNode(node)
			end
			self.path = smoothed
			self.pathindex = 1
			if (removed > 0) then
				d("[MoveToExact]: SmoothPath removed " .. tostring(removed) .. " nodes")
			end
		end
	elseif (disableSmoothing) then
		d("[MoveToExact]: SmoothPath skipped (disableSmoothing=true)")
	end

	return true
end

function ml_navigation_exact.GetDispatchTargetY(node, ppos)
	if (not node) then
		return (ppos and ppos.y) or nil
	end
	local targetY = node.y or (ppos and ppos.y)
	if (targetY and ppos and ppos.y and math.abs(targetY - ppos.y) > (ml_navigation_exact.maxDispatchYDelta or 8)) then
		targetY = ppos.y
	end
	return targetY
end

function ml_navigation_exact.DispatchAutoFollow(node, ppos, force)
	if (not node or not Player or not Player.SetAutoFollowPos or not Player.SetAutoFollowOn) then
		return false
	end
	local now = Now()
	local key = tostring(math.round(node.x, 2)) .. ":" .. tostring(math.round(node.z, 2)) .. ":" .. tostring(ml_navigation_exact.pathindex)
	local targetY = ml_navigation_exact.GetDispatchTargetY(node, ppos)
	if (force or key ~= ml_navigation_exact.autoFollowNodeKey or TimeSince(ml_navigation_exact.autoFollowLastSet) >= ml_navigation_exact.autoFollowRefreshMs) then
		Player:SetAutoFollowPos(node.x, targetY, node.z)
		ml_navigation_exact.autoFollowNodeKey = key
		ml_navigation_exact.autoFollowLastSet = now
		ml_navigation.navAutoFollowOwned = true
		ml_navigation.navAutoFollowOwner = "movetoexact"
	end

	if (not Player.IsAutoFollowOn or not Player:IsAutoFollowOn()) then
		Player:SetAutoFollowPos(node.x, targetY, node.z)
		ml_navigation_exact.autoFollowNodeKey = key
		ml_navigation_exact.autoFollowLastSet = now
		Player:SetAutoFollowOn(true)
	end
	return true
end

------------------------------------------------------------
-- Player:Stop / PauseMovement
------------------------------------------------------------
function Player:Stop(resetpath)
	ml_navigation:CancelFlightFollowCam()

	-- StopMovement MUST run before DisableAutoFollow so the C++ sees AutoFollow
	-- still active and properly halts the player (including flight momentum).
	Player:StopMovement()
	ml_navigation:DisableAutoFollow(true, "Stop")

	ffnav.isascending = false
	ffnav.isdescending = false
	ffnav.descentAttempts = 0
	-- Preserve landing fallback state across mid-air Stop() calls. The
	-- parent movetopos task completes when autofollow reaches the
	-- rewritten fallback endpoint; Stop() fires while the player is still
	-- airborne above the fallback spot, and the subtask then builds a
	-- fresh path. Clearing state here forces a full re-probe (lookahead +
	-- BuildPath) before the dismount can trigger, adding ~0.5-1.5s of
	-- hover. The ground-nav branch clears these once the player lands.
	if (not IsFlying()) then
		ffnav.landingProbeCache = {}
		ffnav.landingFallbackActive = false
		ffnav.landingFallbackPos = nil
		ffnav.landingFallbackOrigin = nil
		ffnav.landingFallbackSmoothed = false
	end
	ml_navigation.lastconnectionid = 0
	ml_navigation.lastconnectiontimer = 0
	ml_navigation:ResetFlightActionThrottle(true)
	ml_navigation.lasttargetid = nil
	NavigationManager:ResetPath()
	ml_navigation:ResetCurrentPath()
	ml_navigation.receivedInstructions = {}
	ml_navigation:ResetOMCHandler()
	ml_navigation.canPath = false
	ffnav.yield = {}
	ffnav.process = {}
end

function Player:PauseMovement(param1, param2, param3, param4, param5)
	local param1 = IsNull(param1, 1500)
	local param2 = IsNull(param2, function () return not Player:IsMoving() end)

	ml_navigation.canPath = false
	ml_navigation:CancelFlightFollowCam()
	Player:StopMovement()

	ffnav.Await(param1, param2, param3, param4, param5)
end

------------------------------------------------------------
-- Main Navigation State
------------------------------------------------------------
ml_navigation.lastconnectionid = 0
ml_navigation.lastconnectiontimer = 0
ml_navigation.lasttargetid = nil
ml_navigation.path = {}
ml_navigation.pathindex = 0
ml_navigation.lastindexgoal = {}

------------------------------------------------------------
-- Main Navigate() Loop — AutoFollow Only
------------------------------------------------------------
function ml_navigation.Navigate(event, ticks)
	-- MoveToExact priority guard
	if (ml_navigation_exact.active) then
		ml_navigation_exact.Navigate(event, ticks)
		return
	end

	local self = ml_navigation
	if ((ticks - (ml_navigation.lastupdate or 0)) > 50) then
		ml_navigation.lastupdate = ticks
		if (not (ml_navigation.CanRun() and ml_navigation.canPath and not ml_navigation.debug)) then
			ml_navigation:DisableAutoFollow(nil, "NavGuard:CanRun="..tostring(ml_navigation.CanRun()).." canPath="..tostring(ml_navigation.canPath))
			return
		end

		if ( ml_navigation.CanRun() and ml_navigation.canPath and not ml_navigation.debug) then

			local ppos = Player.pos

			ml_navigation.GUI = {
				pathHops = 0,
				currentIndex = 0,
				nextNodeDistance = 0,
				lastAction = "",
			}

			-- Normal Navigation Mode
			if (not ffnav.IsProcessing()) then

				ml_navigation.pathindex = NavigationManager.NavPathNode

				if ( table.valid(ml_navigation.path) and ml_navigation.path[ml_navigation.pathindex] ~= nil) then

					ml_global_information.GetMovementInfo(true)

					-- Skip the periodic path rebuild while a smoothed landing fallback is in flight.
					-- Rebuilding here would re-create temp floor-cube NavConnections at the player's
					-- current air position and route the path up through a cube detour, undoing the
					-- in-place smoothing and dirtying NavConnectionMgr state ("modified" indicator).
					local fallbackSmoothed = (ffnav.landingFallbackActive and ffnav.landingFallbackSmoothed) == true

					if (not fallbackSmoothed and not ml_navigation:IsUsingConnection() and TimeSince(ml_navigation.lastPathUpdate) >= 2000) then
						Player:BuildPath(ml_navigation.targetposition.x, ml_navigation.targetposition.y, ml_navigation.targetposition.z, NavigationManager:GetExcludeFilter(GLOBAL.NODETYPE.FLOOR), NavigationManager:GetExcludeFilter(GLOBAL.NODETYPE.CUBE), ml_navigation.lasttargetid)
						ml_navigation.lastPathUpdate = Now()
						ml_navigation._refreshPrefetched = false
						return
					end
					if (not fallbackSmoothed and not ml_navigation:IsUsingConnection() and TimeSince(ml_navigation.lastPathUpdate) >= 1000 and not ml_navigation._refreshPrefetched) then
						ml_navigation._refreshPrefetched = true
						local tp = ml_navigation.targetposition
						if (tp) then
							NavigationManager:GetPathAsync(ppos.x, ppos.y, ppos.z, tp.x, tp.y, tp.z, 0, true)
						end
					end

					if IsControlOpen("Talk") then
						UseControlAction("Talk","Click")
						ml_navigation.lastupdate = ml_navigation.lastupdate + 1500
						return
					end

					if (IsControlOpen("SelectYesno")) then
						PressYesNo(true)
						ml_navigation.lastupdate = ml_navigation.lastupdate + 1500
						return
					end

					local lastnode = ml_navigation.path[ml_navigation.pathindex - 1]
					if (lastnode == nil) then
						lastnode = ml_navigation.startposition
					end
					local nextnode = ml_navigation.path[ml_navigation.pathindex]
					local nextnextnode = ml_navigation.path[ml_navigation.pathindex + 1]

					ml_navigation.TagNode(nextnode)
					ml_navigation.TagNode(nextnextnode)

					ml_navigation.GUI.pathHops = table.size(ml_navigation.path)
					ml_navigation.GUI.currentIndex = ml_navigation.pathindex
					ml_navigation.GUI.nextNodeDistance = math.distance3d(ppos,nextnode)

					-- Ensure Position for OMCs
					if (table.valid(ml_navigation.ensureposition) and (ml_navigation:EnsurePosition(ppos))) then
						return
					end

					----------------------------------------------------
					-- OMC Branch: Active off-mesh connection
					----------------------------------------------------
					local nc = self.omc_details
					if ( self.omc_id ) then
						local from_pos = nc.from
						local to_pos = nc.to
						local ncradius
						local ncsubtype
						local from_heading

						if (nc.sideA ~= nil) then
							from_pos = nc.sideA
							to_pos = nc.sideB
						end

						if (self.omc_direction == 0) then
							if (math.distance3d(ppos, from_pos) < math.distance3d(ppos, to_pos)) then
								self.omc_direction = 1
							else
								self.omc_direction = 2
							end
						end

						if (nc.sideA ~= nil) then
							if (self.omc_direction == 1) then
								from_pos = nc.sideA
								to_pos = nc.sideB
								ncradius = nc.sideA.radius
								from_heading = nc.details.headingA_x
							else
								from_pos = nc.sideB
								to_pos = nc.sideA
								ncradius = nc.sideB.radius
								from_heading = nc.details.headingB_x
							end
							ncsubtype = nc.details.subtype
						else
							if (self.omc_direction == 1) then
								from_pos = nc.from
								to_pos = nc.to
							else
								from_pos = nc.to
								to_pos = nc.from
							end
							ncradius = nc.radius
							ncsubtype = nc.subtype
						end

						if (not MIsLocked() and ncsubtype ~= 4) then
							if (ml_navigation.omc_traveltimer == nil) then
								ml_navigation.omc_traveltimer = ticks
							end
							local timepassed = ticks - ml_navigation.omc_traveltimer
							local dist = math.distance3d(ppos,nextnode)
							if (ml_navigation.omc_traveldist == 0) then
								ml_navigation.omc_traveldist = dist
							end
							if ( timepassed < 3000) then
								if ( timepassed > 2000 and ml_navigation.omc_traveldist > dist) then
									ml_navigation.omc_traveldist = dist
									ml_navigation.omc_traveltimer = ticks
								end
							else
								d("[Navigation] - Not getting closer to NavConnection END node. We are most likely stuck.")
								ml_navigation.StopMovement()
								return
							end
						end

						if ( ml_navigation.omc_starttimer ~= 0 and ticks - ml_navigation.omc_starttimer > 10000 ) then
							d("[Navigation] - Could not reach NavConnection END in ~10 seconds, something went wrong..")
							ml_navigation.StopMovement()
							return
						end

						-- OMC Jump (subtype 1)
						if ( ncsubtype == 1 ) then
							ml_navigation.GUI.lastAction = "Jump NavConnection"

							if ( not ml_navigation.omc_startheight ) then
								if ( ncradius <= 0.5 ) then
									d("[OMC-DBG] MoveTo:ensure-start pidx=" .. tostring(ml_navigation.pathindex) .. " radius=" .. tostring(ncradius) .. " ppos=" .. tostring(ppos.x) .. "," .. tostring(ppos.y) .. "," .. tostring(ppos.z) .. " from=" .. tostring(from_pos.x) .. "," .. tostring(from_pos.y) .. "," .. tostring(from_pos.z) .. " to=" .. tostring(to_pos.x) .. "," .. tostring(to_pos.y) .. "," .. tostring(to_pos.z))
									if ( ml_navigation:SetEnsureStartPosition(from_pos, ppos, nc, from_pos, to_pos, from_heading) ) then
										return
									end
								end

								if ( ml_navigation.omc_starttimer == 0 ) then
									ml_navigation.omc_starttimer = ticks
									d("[OMC-DBG] MoveTo:timer-start moving=" .. tostring(Player:IsMoving()) .. " af=" .. tostring(Player:IsAutoFollowOn()) .. " jumping=" .. tostring(Player:IsJumping()) .. " NavPathNode=" .. tostring(NavigationManager.NavPathNode))
									if (not Player:IsMoving()) then
										d("[OMC-DBG] MoveTo:dispatch-to-pos+await af=" .. tostring(Player:IsAutoFollowOn()))
										ml_navigation:DispatchAutoFollowNode(to_pos, true)
										ffnav.Await(1000, function () return Player:IsMoving() end)
									end
								elseif ( Player:IsMoving() and ticks - ml_navigation.omc_starttimer > 100 ) then
									-- Redirect autofollow toward landing target (Y-clamped) before jumping,
									-- so the player has lateral momentum in the correct direction when Jump() fires.
									-- Without this, autofollow may still point at an earlier path node and Jump()
									-- can intermittently kill autofollow, leaving the player airborne with no lateral velocity.
									local preJumpY = to_pos.y
									if (math.abs(to_pos.y - ppos.y) > 8) then
										preJumpY = ppos.y
									end
									ml_navigation:DispatchAutoFollowNode({ x = to_pos.x, y = preJumpY, z = to_pos.z }, true)
									ml_navigation.omc_startheight = ppos.y
									d("[OMC-DBG] MoveTo:JUMP startheight=" .. tostring(ppos.y) .. " moving=" .. tostring(Player:IsMoving()) .. " af=" .. tostring(Player:IsAutoFollowOn()) .. " tElapsed=" .. tostring(ticks - ml_navigation.omc_starttimer))
									Player:Jump()
									d("[Navigation]: Starting to Jump for NavConnection.")
								end

							else
								local todist,todist2d = ml_navigation:GetRaycast_Player_Node_Distance(ppos,to_pos)
								d("[OMC-DBG] MoveTo:in-air todist=" .. tostring(todist) .. " todist2d=" .. tostring(todist2d) .. " y=" .. tostring(ppos.y) .. " moving=" .. tostring(Player:IsMoving()) .. " jumping=" .. tostring(Player:IsJumping()) .. " af=" .. tostring(Player:IsAutoFollowOn()))

								-- Stall detection: if player hasn't descended from start height after 1500ms, jump failed
								-- (re-arm gave no lateral momentum; player is stuck at ledge edge)
								if ( ticks - ml_navigation.omc_starttimer > 1500 and ppos.y > ml_navigation.omc_startheight - 1.0 ) then
									ml_navigation.omc_jumpretries = (ml_navigation.omc_jumpretries or 0) + 1
									d("[OMC-DBG] MoveTo:STALL-RETRY #" .. tostring(ml_navigation.omc_jumpretries) .. " ppos_y=" .. tostring(ppos.y) .. " startheight=" .. tostring(ml_navigation.omc_startheight) .. " elapsed=" .. tostring(ticks - ml_navigation.omc_starttimer))
									if ( ml_navigation.omc_jumpretries > 3 ) then
										d("[Navigation]: OMC jump stalled after 3 retries, giving up.")
										Player:Stop()
										return
									end
									ml_navigation.omc_startheight = nil
									ml_navigation.omc_starttimer = ticks
									return
								end

								if ( todist2d <= ml_navigation.NavPointReachedDistances[ml_navigation.GetMovementType()]) then
									if ( ncradius <= 0.5 ) then
										if (Player:IsMoving() or Player:IsJumping() ) then
											Player:StopMovement()
											ffnav.Await(1000, function () return not Player:IsMoving() and not Player:IsJumping() end)
											return
										else
											d("[OMC-DBG] MoveTo:LANDED (teleport) todist2d=" .. tostring(todist2d))
											Hacks:TeleportToXYZ(to_pos.x, to_pos.y, to_pos.z)
											ml_navigation.lastupdate = ml_navigation.lastupdate + math.random(500,1500)
											ml_navigation.pathindex = ml_navigation.pathindex + 1
											NavigationManager.NavPathNode = ml_navigation.pathindex
											ml_navigation:ResetAutoFollowState()
											ml_navigation:ResetOMCHandler()
											d("[Navigation]: [Jumping] - Landed at End of Navconnection.")
										end
									else
										d("[OMC-DBG] MoveTo:LANDED todist2d=" .. tostring(todist2d))
										ml_navigation.pathindex = ml_navigation.pathindex + 1
										NavigationManager.NavPathNode = ml_navigation.pathindex
										ml_navigation:ResetAutoFollowState()
										ml_navigation:ResetOMCHandler()
										d("[Navigation]: [Jumping] - Landed at End of Navconnection.")
									end
								else
									if ( from_pos.y > (ppos.y + 1) and to_pos.y > (ppos.y + 1) ) then
										if ( ncradius <= 0.5 ) then
											if (Player:IsMoving() or Player:IsJumping() ) then
												Player:StopMovement()
												ffnav.Await(1000, function () return not Player:IsMoving() and not Player:IsJumping() end)
												return
											else
												d("[OMC-DBG] MoveTo:LANDED-below (teleport) todist2d=" .. tostring(todist2d))
												Hacks:TeleportToXYZ(to_pos.x, to_pos.y, to_pos.z)
												ml_navigation.lastupdate = ml_navigation.lastupdate + math.random(500,1500)
												ml_navigation.pathindex = ml_navigation.pathindex + 1
												NavigationManager.NavPathNode = ml_navigation.pathindex
												ml_navigation:ResetAutoFollowState()
												ml_navigation:ResetOMCHandler()
												d("[Navigation]: [Jumping] - Landed at End of Navconnection.")
											end
										else
											d("[OMC-DBG] MoveTo:FAIL-below from_y=" .. tostring(from_pos.y) .. " to_y=" .. tostring(to_pos.y) .. " ppos_y=" .. tostring(ppos.y))
											d("[Navigation]: [Jumping] - Failed to Reach End of Navconnection.")
											Player:Stop()
										end
									else
										-- Clamp target Y to near player height during jump arc,
										-- so autofollow drives lateral movement instead of vertical descent.
										-- This mirrors MoveToExact's GetDispatchTargetY() behaviour.
										local clampedY = to_pos.y
										if (math.abs(to_pos.y - ppos.y) > 8) then
											clampedY = ppos.y
										end
										local clampedTarget = { x = to_pos.x, y = clampedY, z = to_pos.z }
										ml_navigation:DispatchAutoFollowNode(clampedTarget, true)
									end
								end
							end
							return
						end

						-- OMC Walk (subtype 2)
						if ( ncsubtype == 2 ) then
							if (ml_navigation.omc_starttimer == 0 ) then
								ml_navigation.omc_starttimer = ticks
							end
							ml_navigation.GUI.lastAction = "Walk NavConnection"
							-- Simple: dispatch autofollow, check arrival
							if (ml_navigation:IsGoalClose(ppos,nextnode,lastnode)) then
								ml_navigation.lastconnectionid = nextnode.navconnectionid
								ml_navigation.lastconnectiontimer = Now()
								ml_navigation.pathindex = ml_navigation.pathindex + 1
								NavigationManager.NavPathNode = ml_navigation.pathindex
								ml_navigation:ResetAutoFollowState()
							else
								ml_navigation:DispatchAutoFollowNode(nextnode, true)
							end
							return
						end

						-- OMC Teleport (subtype 3)
						if ( ncsubtype == 3 ) then
							ml_navigation.GUI.lastAction = "Teleport NavConnection"
							if (Player:IsMoving() or Player:IsJumping() ) then
								Player:StopMovement()
								ffnav.Await(1000, function () return not Player:IsMoving() and not Player:IsJumping() end)
								return
							else
								if gTeleportHack then
									Hacks:TeleportToXYZ(to_pos.x, to_pos.y, to_pos.z)
									ml_navigation.lastupdate = ml_navigation.lastupdate + math.random(500,1500)
								else
									NavigationManager:DisableNavConnection(nc.id)
								end
							end
							ml_navigation.pathindex = ml_navigation.pathindex + 1
							NavigationManager.NavPathNode = ml_navigation.pathindex
							ml_navigation:ResetOMCHandler()
							return
						end

						-- OMC Interact (subtype 4)
						if ( ncsubtype == 4 ) then
							ml_navigation.GUI.lastAction = "Interact NavConnection"
							if (Player:IsMoving()) then
								Player:StopMovement()
								ffnav.Await(1000, function () return not Player:IsMoving() end)
								return
							end

							if (Player.ismounted) then
								Dismount()
								ffnav.Await(2000, function () return not Player.ismounted end)
								return
							end

							if (MIsLoading()) then
								ml_navigation.lastupdate = ml_navigation.lastupdate + 1500
								ml_navigation.pathindex = ml_navigation.pathindex + 1
								NavigationManager.NavPathNode = ml_navigation.pathindex
								ml_navigation:ResetOMCHandler()
								return
							end

							-- Detect position change after zone transition (interact caused a teleport/load)
							if (ml_navigation.omc_interact_pos) then
								local posdelta = math.distance3d(ppos, ml_navigation.omc_interact_pos)
								if (posdelta > 2) then
									ml_navigation.pathindex = ml_navigation.pathindex + 1
									NavigationManager.NavPathNode = ml_navigation.pathindex
									ml_navigation:ResetOMCHandler()
									return
								end
							end

							if (IsControlOpen("SelectString") or IsControlOpen("SelectIconString")) then
								SelectConversationIndex(1)
								ml_navigation.lastupdate = ml_navigation.lastupdate + 1000
								return
							end

							if (IsPositionLocked()) then
								ml_navigation.lastupdate = ml_navigation.lastupdate + 500
								return
							end

							local todist,todist2d = ml_navigation:GetRaycast_Player_Node_Distance(ppos,nextnode)
							if ( todist <= ml_navigation.NavPointReachedDistances["3dwalk"] and todist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
								d("[Navigation] - OMC_END - Interact Node reached")
								ml_navigation.pathindex = ml_navigation.pathindex + 1
								NavigationManager.NavPathNode = ml_navigation.pathindex
								ml_navigation:ResetOMCHandler()
							end

							local interactnpc
							local elist = MEntityList("nearest,targetable,type=7,chartype=0,maxdistance=5")
							if ( table.valid(elist)) then interactnpc = select(2,next(elist)) end

							if ( not interactnpc ) then
								elist = MEntityList("nearest,targetable,type=3,chartype=0,maxdistance=5")
								if ( table.valid(elist)) then interactnpc = select(2,next(elist)) end
							end

							if ( not interactnpc ) then
								elist = MEntityList("nearest,targetable,maxdistance=7")
								if ( table.valid(elist)) then interactnpc = select(2,next(elist)) end
							end

							if ( interactnpc ) then
								local target = MGetTarget()
								local interactid = interactnpc.id
								if (not target or (target and target.id ~= interactid)) then
									d("Setting target for interaction : "..interactnpc.name)
									Player:SetTarget(interactid)
									ffnav.Await(1500, function () return (Player:GetTarget() and Player:GetTarget().id == interactid) end)
								elseif (target.interactable) then
									ml_navigation.omc_interact_pos = { x = ppos.x, y = ppos.y, z = ppos.z }
									Player:Interact(interactnpc.id)
									d("Interacting with target : "..interactnpc.name)
									ffnav.Await(2000, function () return (MIsLoading() or IsControlOpen("SelectYesno") or table.valid(GetConversationList())) end)
								end
							end
							return
						end

						-- OMC Portal (subtype 5)
						if ( ncsubtype == 5 ) then
							ml_navigation.GUI.lastAction = "Portal OMC"
							if (ml_navigation:IsGoalClose(ppos,nextnode,lastnode)) then
								ml_navigation.lastconnectionid = nextnode.navconnectionid
								ml_navigation.lastconnectiontimer = Now()
								ml_navigation.pathindex = ml_navigation.pathindex + 1
								NavigationManager.NavPathNode = ml_navigation.pathindex
								ml_navigation:ResetAutoFollowState()
							else
								ml_navigation:DispatchAutoFollowNode(nextnode, true)
							end
							return
						end

						-- OMC Custom (subtype 6)
						if ( ncsubtype == 6 ) then
							ml_navigation.GUI.lastAction = "Custom OMC"
							if (ml_navigation:IsGoalClose(ppos,nextnode,lastnode)) then
								ml_navigation.lastconnectionid = nextnode.navconnectionid
								ml_navigation.lastconnectiontimer = Now()
								ml_navigation.pathindex = ml_navigation.pathindex + 1
								NavigationManager.NavPathNode = ml_navigation.pathindex
								ml_navigation:ResetAutoFollowState()
							else
								ml_navigation:DispatchAutoFollowNode(nextnode, true)
							end
							return
						end
					end

					if (MIsLocked()) then
						ml_navigation:DisableAutoFollow(true, "MIsLocked")
						return
					end

					----------------------------------------------------
					-- Dive/Swim Navigation
					----------------------------------------------------
					if (IsDiving()) then
						local target = Player:GetTarget()
						if (target and target.los and target.distance2d < 15) then
							if (target.interactable) and (target.distance < 2.5) then
								Player:Stop()
								return false
							end
							-- Close-range target: dispatch autofollow directly to target
							local tpos = target.pos
							local modifiedNode = { x = tpos.x, y = (tpos.y - 2), z = tpos.z }
							local hit = RayCast(ppos.x,ppos.y,ppos.z,modifiedNode.x,modifiedNode.y,modifiedNode.z)
							if (hit) then
								modifiedNode = { x = tpos.x, y = tpos.y, z = tpos.z }
							end

							ml_navigation:DispatchAutoFollowNode(modifiedNode, true)
						else
							ml_navigation.GUI.lastAction = "Swimming underwater to Node"

							if ( ml_navigation:IsGoalClose(ppos,nextnode,lastnode)) then
								ml_navigation.lastconnectionid = nextnode.navconnectionid
								ml_navigation.lastconnectiontimer = Now()
								ml_navigation.pathindex = ml_navigation.pathindex + 1
								NavigationManager.NavPathNode = ml_navigation.pathindex
								ml_navigation:ResetAutoFollowState()
							else
								local modifiedNode = { x = nextnode.x, y = (nextnode.y - 2), z = nextnode.z }
								local hit = RayCast(ppos.x,ppos.y,ppos.z,modifiedNode.x,modifiedNode.y,modifiedNode.z)
								if (hit) then
									modifiedNode = nextnode
								end
								ml_navigation:DispatchAutoFollowNode(modifiedNode, true)
							end
						end
					end

					----------------------------------------------------
					-- Flying Navigation
					----------------------------------------------------
					if (IsFlying()) then
						ml_navigation.GUI.lastAction = "Flying to Node"

						-- Camera follow
						if (ml_navigation:UseFlightFollowCam()) then
							ml_navigation.SmoothFaceTarget(nextnode.x,nextnode.y,nextnode.z)
						end

						local dist2D = math.distance2d(nextnode,ppos)
						local dist3D = math.distance3d(nextnode,ppos)
						local height = 0
						if (Player and Player.meshpos and Player.meshpos.meshdistance) then
							height = Player.meshpos.meshdistance
						end

						local targetnode = shallowcopy(nextnode)
						local nextnextGround = (nextnextnode and nextnextnode.ground == true) or false
						local isDescentCon = (nextnode.floorcube == true and (nextnode.ground == true or nextnextGround))
						local unstableTransition = ml_navigation:IsUnstableFlightTransition(nextnode, nextnextnode)

						if ((not isDescentCon or not ml_navigation:IsGoalClose(ppos,targetnode,lastnode)) and not nextnode.is_cube and ml_navigation:CanContinueFlying()) then
							for i = 3,5,1 do
								local hit = ml_navigation.FlyRayCast(targetnode.x,targetnode.y+i+1,targetnode.z,targetnode.x,targetnode.y+i-2,targetnode.z)
								if (not hit) then
									targetnode.y = (targetnode.y + i)
									break
								end
							end
						end

						-- Dispatch autofollow to fly toward target node
						ml_navigation:DispatchAutoFollowNode(targetnode, true)

						-- Landing zone lookahead
						--
						-- Fires when a candidate landing node (floorcube transition, or
						-- a path-end node, even one lacking the ground flag — gather nodes
						-- on raised props often do) is within raycast range (~landingLookaheadDist).
						--
						-- Two outcomes rewrite the endpoint:
						--   1. Clear  -> project endpoint down to real ground via FindClosestMesh,
						--                so autofollow flies to ground (no mid-path descent needed).
						--   2. Blocked+fallback -> reroute to the fallback spot (existing behaviour).
						--
						-- landingProbeCache[idx] is set only when a rewrite is actually applied
						-- (or the node is already on ground). If we probe too early and the result
						-- is inconclusive, we re-probe next tick as we get closer.
						if (not ffnav.landingFallbackActive) then
							local lookaheadIdx = nil
							local lookaheadNode = nil
							for li = ml_navigation.pathindex, ml_navigation.pathindex + 15 do
								local ln = ml_navigation.path[li]
								if (not ln) then break end
								local lnNext = ml_navigation.path[li + 1]
								local lnNextGround = (lnNext and lnNext.ground == true) or false
								local lnIsFlyToWalk = (ln.floorcube == true and (ln.ground == true or lnNextGround))
									or (ln.is_end and ln.ground)
								-- Accept any path-end as a landing candidate (elevated gather
								-- nodes may not carry the ground flag; we still want to land
								-- near them by projecting to ground below).
								local lnIsEndCandidate = (ln.is_end == true) and not ln.is_cube
								if (lnIsFlyToWalk or lnIsEndCandidate) then
									lookaheadIdx = li
									lookaheadNode = ln
									break
								end
							end
							if (lookaheadNode and not ffnav.landingProbeCache[lookaheadIdx]) then
								local distToLanding = math.distance3d(lookaheadNode, ppos)
								if (distToLanding <= ffnav.landingLookaheadDist and distToLanding > 5) then
									local mountRadius = math.max((Player and Player.hitradius) or 0.5, 3)
									local clear, fbX, fbY, fbZ = CheckLandingZone(
										lookaheadNode.x, lookaheadNode.y, lookaheadNode.z, mountRadius)
									if (clear) then
										-- Project endpoint down to real ground. CheckLandingZone
										-- only confirmed the spot is landable from above; the
										-- node Y itself may be on top of a prop/node geometry
										-- that rays pass through. FindClosestMesh gives us the
										-- actual walkable mesh position below.
										local probe = {
											x = lookaheadNode.x,
											y = lookaheadNode.y,
											z = lookaheadNode.z,
										}
										local ground = FindClosestMesh(probe, 20, false, false)
										if (ground and math.abs(ground.y - lookaheadNode.y) > 0.25) then
											local drop = lookaheadNode.y - ground.y
											d("[Navigation] Lookahead: projecting endpoint to ground at node "
												.. lookaheadIdx
												.. " dist=" .. string.format("%.0f", distToLanding)
												.. " drop=" .. string.format("%.2f", drop)
												.. " (" .. string.format("%.1f, %.1f, %.1f",
													ground.x, ground.y, ground.z) .. ")")
											lookaheadNode.x = ground.x
											lookaheadNode.y = ground.y
											lookaheadNode.z = ground.z
											ml_navigation.ScrubToGroundEndpoint(lookaheadNode)
											for ri = lookaheadIdx + 1, lookaheadIdx + 50 do
												if (ml_navigation.path[ri] == nil) then break end
												ml_navigation.path[ri] = nil
											end
											-- Freeze periodic refresh so BuildPath does not
											-- undo the ground projection.
											ffnav.landingFallbackPos = { x = ground.x, y = ground.y, z = ground.z }
											ffnav.landingFallbackOrigin = ml_navigation.targetposition and
												{ x = ml_navigation.targetposition.x,
												  y = ml_navigation.targetposition.y,
												  z = ml_navigation.targetposition.z } or nil
											ffnav.landingFallbackActive = true
											ffnav.landingFallbackSmoothed = true
											ffnav.landingProbeCache[lookaheadIdx] = true
										elseif (ground) then
											-- Already essentially on ground, nothing to rewrite.
											ffnav.landingProbeCache[lookaheadIdx] = true
										end
										-- If no ground found yet (out of mesh range), leave
										-- cache unset so we retry once closer.
									elseif (fbX) then
										local fallbackPos = { x = fbX, y = fbY, z = fbZ }
										-- The engine-produced path already approves flight up to
										-- lookaheadNode. When the fallback is a tiny horizontal shift
										-- off that same node, the existing approach is inherently valid
										-- and we can safely smooth in place. A player-origin raycast
										-- is too strict here (side-probes graze cliff walls around
										-- the landing) and causes needless BuildPath rebuilds that
										-- route up through a cube detour.
										local shiftDist = math.distance3d(lookaheadNode, fallbackPos)
										local smallShift = (shiftDist <= 8)
										local canFlyDirect = smallShift
											or ml_navigation:IsDirectFlightCorridorClear(ppos, fallbackPos, 100)
										d("[Navigation] Lookahead: landing blocked at node " .. lookaheadIdx
											.. ", rerouting early to ("
											.. string.format("%.1f, %.1f, %.1f", fbX, fbY, fbZ) .. ")"
											.. " dist=" .. string.format("%.0f", distToLanding)
											.. " shift=" .. string.format("%.1f", shiftDist)
											.. " directClear=" .. tostring(canFlyDirect))
										lookaheadNode.x = fbX
										lookaheadNode.y = fbY
										lookaheadNode.z = fbZ
										ml_navigation.ScrubToGroundEndpoint(lookaheadNode)
										for ri = lookaheadIdx + 1, lookaheadIdx + 50 do
											if (ml_navigation.path[ri] == nil) then break end
											ml_navigation.path[ri] = nil
										end
										ffnav.landingFallbackPos = fallbackPos
										ffnav.landingFallbackOrigin = ml_navigation.targetposition and
											{ x = ml_navigation.targetposition.x,
											  y = ml_navigation.targetposition.y,
											  z = ml_navigation.targetposition.z } or nil
										ffnav.landingFallbackActive = true
										-- In-place rewrite preserved the current path; when the shift
										-- is small or the direct corridor is clear, freeze the
										-- periodic refresh so BuildPath does not rebuild the approach
										-- through a cube detour.
										ffnav.landingFallbackSmoothed = canFlyDirect
										ffnav.landingProbeCache[lookaheadIdx] = true
									end
									-- No fallback available and not clear: leave cache unset and
									-- re-probe next tick; the engine will have a better answer
									-- as we close distance.
								end
							end
						end

						if ( ml_navigation:IsGoalClose(ppos,targetnode,lastnode) or ml_navigation:IsGoalClose(ppos,nextnode,lastnode)) then
							-- Legacy Descend() trigger removed. Landing is now handled by:
							--   1. Lookahead block above (rewrites endpoint to ground Y,
							--      or reroutes to fallback on blocked spots).
							--   2. Autofollow flies the bot to that rewritten ground endpoint.
							--   3. c_mount's flying dismount gate (dist3d <= dismountDistance+10)
							--      fires the dismount cast, landing the player.
							-- No mid-path manual descent is needed.

							-- Node reached, advance path
							ml_navigation.lastconnectionid = nextnode.navconnectionid
							ml_navigation.lastconnectiontimer = Now()
							ml_navigation.pathindex = ml_navigation.pathindex + 1
							NavigationManager.NavPathNode = ml_navigation.pathindex
							ml_navigation:ResetFlightActionThrottle(false)
							ml_navigation:ResetAutoFollowState()
						end

					----------------------------------------------------
					-- Ground Navigation
					----------------------------------------------------
					elseif (not IsFlying() and not IsDiving()) then
						ffnav.isascending = false
						ffnav.isdescending = false
						ffnav.descentAttempts = 0
						ffnav.landingFallbackActive = false
						ffnav.landingFallbackPos = nil
						ffnav.landingFallbackOrigin = nil
						ffnav.landingFallbackSmoothed = false
						ffnav.landingProbeCache = {}

						local navcon = ml_navigation:GetConnection(nextnode)
						local isGoalCloseForCon = (navcon ~= nil and navcon.type == 3 and ml_navigation:IsGoalClose(ppos,nextnode,lastnode))
						local isCubeCon = isGoalCloseForCon

						if (nextnode.type == GLOBAL.NODETYPE.CUBE or isCubeCon) then
							if ( navcon ) then
								ml_navigation.lastconnectionid = nextnode.navconnectionid
								ml_navigation.lastconnectiontimer = Now()
							end

							ml_navigation.GUI.lastAction = "Walk to Cube Node"

							if (IsSwimming() and (nextnode.y < (ppos.y - 15))) then
								if (IsSwimming()) then
									d("[Navigation] - Dive into water (swimming), using connection ["..tostring(isCubeCon).."].")
								else
									d("[Navigation] - Dive into water (node position), using connection ["..tostring(isCubeCon).."].")
								end
								ffnav.isdescending = isCubeCon
								if (Player:IsMoving()) then
									Player:StopMovement()
									return false
								end
								Dive()
								return

							elseif (nextnode.water or (navcon and navcon.type == 3 and (nextnextnode and nextnextnode.water))) then
								-- Navigate to underwater connection
								if (ml_navigation:IsGoalClose(ppos,nextnode,lastnode)) then
									ml_navigation.lastconnectionid = nextnode.navconnectionid
									ml_navigation.lastconnectiontimer = Now()
									ml_navigation.pathindex = ml_navigation.pathindex + 1
									NavigationManager.NavPathNode = ml_navigation.pathindex
									ml_navigation:ResetAutoFollowState()
								else
									ml_navigation:DispatchAutoFollowNode(nextnode, true)
								end
								return

							elseif (not IsFlying() and CanFlyInZone()) then
								if (not Player.ismounted) then
									if (Player:IsMoving()) then
										d("[Navigation] - Mount for flight, stopping first.")
										Player:StopMovement()
										ffnav.AwaitDo(3000, function () return not Player:IsMoving() end, function () Player:StopMovement() end)
										ml_global_information.Await(10000, function () return not ffnav.IsYielding() end)
										return
									else
										if (ml_navigation:IsFlightActionThrottled("mount", ml_navigation.pathindex, nextnode, nextnextnode)) then
											return
										end
										if (Mount()) then
											d("[Navigation] - Mount for flight.")
											ffnav.AwaitSuccess(1000,
												function ()
													return (IsMounting() or UsingBattleItem())
												end,
												function ()
													ffnav.Await(3000, function () return Player.ismounted end)
												end
											)
											ml_global_information.Await(10000, function () return not ffnav.IsYielding() end)
										else
											ml_navigation:IsFlightActionThrottled("mount_fail", ml_navigation.pathindex, nextnode, nextnextnode)
											d("[Navigation] - Mount for flight failed, retrying...")
											ffnav.Await(1000)
											ml_global_information.Await(10000, function () return not ffnav.IsYielding() end)
										end
										return
									end

								else
									if (Player:IsMoving()) then
										Player:StopMovement()
										ffnav.AwaitDo(3000, function () return not Player:IsMoving() end, function () Player:StopMovement() end)
										return
									else
										local nextnextAir = (nextnextnode and nextnextnode.air == true) or false
										local isFlightCon = (nextnode.floorcube == true and (nextnode.air == true or nextnextAir) and not ml_navigation:IsUnstableFlightTransition(nextnode, nextnextnode))
										local shouldAscend = isFlightCon or (nextnode.is_cube and not nextnode.floorcube)
										if (not shouldAscend) then
											if (ml_navigation:IsGoalClose(ppos,nextnode,lastnode)) then
												ml_navigation.lastconnectionid = nextnode.navconnectionid
												ml_navigation.lastconnectiontimer = Now()
												ml_navigation.pathindex = ml_navigation.pathindex + 1
												NavigationManager.NavPathNode = ml_navigation.pathindex
												ml_navigation:ResetAutoFollowState()
											else
												ml_navigation:DispatchAutoFollowNode(nextnode, true)
											end
											return
										end
										if (ml_navigation:IsFlightActionThrottled("ascend", ml_navigation.pathindex, nextnode, nextnextnode)) then
											return
										end

										d("[Navigation] - Ascend for flight, using connection ["..tostring(isFlightCon).."].")
										ffnav.isascending = isFlightCon
										Player:Jump()
										ffnav.AwaitSuccess(500, 2000, function ()
											local ascended = Player:IsJumping() or IsFlying()
											if (ffnav.isascending and ascended) then
												ffnav.isascending = false
												local ppos2 = Player.pos
												local cnode = ml_navigation.path[ml_navigation.pathindex]
												if (cnode and math.distance2d(ppos2, cnode) < 10) then
													ml_navigation.pathindex = ml_navigation.pathindex + 1
													NavigationManager.NavPathNode = ml_navigation.pathindex
													ml_navigation:ResetFlightActionThrottle(false)
													d("[Navigation]: finished ascending near connection, newpathindex ["..tostring(NavigationManager.NavPathNode).."]")
												else
													d("[Navigation]: finished ascending, flying toward connection node ["..tostring(ml_navigation.pathindex).."]")
												end
											end
											return ascended
										end, function ()
											Player:TakeOff()
										end)
										return
									end
								end
							end
						else
							-- Normal ground navigation: dispatch autofollow, check arrival
							ml_navigation.GUI.lastAction = "Walk to Node"
							if (ml_navigation:IsGoalClose(ppos,nextnode,lastnode)) then
								ml_navigation.lastconnectionid = nextnode.navconnectionid
								ml_navigation.lastconnectiontimer = Now()
								ml_navigation.pathindex = ml_navigation.pathindex + 1
								NavigationManager.NavPathNode = ml_navigation.pathindex
								ml_navigation:ResetAutoFollowState()
							else
								ml_navigation:DispatchAutoFollowNode(nextnode, true)
								if (not IsFlying() and not IsDiving()) then
									ml_navigation:ApplyFollowCamPitch()
								end
							end
						end
					end
				else
					-- Path exhausted. If we were running a smoothed landing fallback,
					-- clear its flags so subsequent BuildPath calls are not suppressed
					-- by the in-place-smoothing gate (we've already arrived / dismounted).
					if (ffnav.landingFallbackActive or ffnav.landingFallbackSmoothed) then
						ffnav.landingFallbackActive = false
						ffnav.landingFallbackPos = nil
						ffnav.landingFallbackOrigin = nil
						ffnav.landingFallbackSmoothed = false
						ffnav.landingProbeCache = {}
					end
					ml_navigation.StopMovement()
				end
			end
		end
	end
end

-- Wrapper for event handler
function ml_navigation.NavWrapper(event, ticks)
	ml_navigation.Navigate(event,ticks)
end
RegisterEventHandler("Gameloop.Draw", ml_navigation.NavWrapper, "ml_navigation.NavWrapper")

function ml_navigation.GroundFollowCamWrapper(event, ticks)
	ml_navigation:EnforceGroundFollowCamPitch()
end
RegisterEventHandler("Gameloop.Update", ml_navigation.GroundFollowCamWrapper, "ml_navigation.GroundFollowCamWrapper")

function ml_navigation.DebugDraw(event, ticks)
	if (ml_navigation.debug) then
		if (table.valid(ml_navigation.path)) then
			for i,node in pairs(ml_navigation.path) do
				if RenderManager and RenderManager.AddObject3D then
					RenderManager:AddObject3D(node,1,1)
				end
			end
		end
	end
end
RegisterEventHandler("Gameloop.Draw", ml_navigation.DebugDraw, "ml_navigation.DebugDraw")

------------------------------------------------------------
-- MoveToExact Navigation Tick Handler
------------------------------------------------------------
function ml_navigation_exact.Navigate(event, ticks)
	if (not ml_navigation_exact.active) then return end

	if ((ticks - ml_navigation_exact.lastupdate) < 16) then return end
	ml_navigation_exact.lastupdate = ticks

	local ppos = Player.pos
	if (not ppos) then return end

	-- Handle pending async path
	if (ml_navigation_exact.pending) then
		local goal = ml_navigation_exact.pendingGoal
		local cacheId = ml_navigation_exact.pendingCacheId
		if (not goal) then
			Player:StopExact()
			return
		end
		if (not cacheId or cacheId <= 0) then
			cacheId = BuildMoveToExactCacheId(ppos, goal)
			ml_navigation_exact.pendingCacheId = cacheId
		end
		local result = NavigationManager:GetPathAsync(ppos.x, ppos.y, ppos.z, goal.x, goal.y, goal.z, cacheId, false, true)
		if (type(result) == "table" and table.valid(result)) then
			ml_navigation_exact.path = result
			ml_navigation_exact.pathindex = 1
			ml_navigation_exact.pending = false
			ml_navigation_exact.pendingGoal = nil
			ml_navigation_exact.pendingCacheId = nil
			for _, node in pairs(ml_navigation_exact.path) do
				ml_navigation.TagNode(node)
			end
			ml_navigation_exact.OptimizeCachedPath(ppos, ml_navigation_exact.disableSmoothing)
			d("[MoveToExact]: Path resolved. cacheId=" .. tostring(cacheId) .. ", nodes=" .. tostring(table.size(ml_navigation_exact.path)))
		elseif (type(result) == "number" and result > 0) then
			return
		else
			d("[MoveToExact]: Path request failed during pending poll. cacheId=" .. tostring(cacheId))
			Player:StopExact()
			return
		end
	end

	local self = ml_navigation_exact
	local nextnode = self.path[self.pathindex]

	-- No more nodes — destination reached
	if (not nextnode) then
		if (not self.reachedLogged) then
			d("[MoveToExact]: Destination reached.")
			self.reachedLogged = true
			self.active = false
			self.completed = true
			ml_navigation:DisableAutoFollow(true, "MoveToExact complete")
		end
		return
	end

	-- OMC handling
	if (self.omc_id and self.omc_details) then
		ml_navigation_exact.HandleOMC(ppos, ticks)
		return
	end

	-- Check if current node is reached
	local dist2d = math.distance2d(ppos, nextnode)
	local yDelta = (nextnode.y and ppos.y) and math.abs(ppos.y - nextnode.y) or 0
	local withinVertical = (nextnode.y == nil or ppos.y == nil or yDelta <= (self.verticalThreshold or 1.5))

	if (dist2d <= self.threshold and withinVertical) then
		-- Node reached — check for OMC setup
		if (nextnode.navconnectionid and nextnode.navconnectionid ~= 0) then
			local nc = NavigationManager:GetNavConnection(nextnode.navconnectionid)
			if (nc and nc.type ~= 5 and nc.details and In(nc.details.subtype, 1, 2, 3, 4)) then
				self.omc_id = nc.id
				self.omc_details = nc
				if (nc.sideA ~= nil) then
					if (nextnode.navconnectionsideA == true) then
						self.omc_direction = 1
					else
						self.omc_direction = 2
					end
				else
					if (math.distance3d(ppos, nc.from) < math.distance3d(ppos, nc.to)) then
						self.omc_direction = 1
					else
						self.omc_direction = 2
					end
				end
			end
		end

		self.pathindex = self.pathindex + 1
		ml_navigation_exact.ResetAutoFollowState()

		if (not self.path[self.pathindex]) then
			if (not self.reachedLogged) then
				d("[MoveToExact]: Destination reached.")
				self.reachedLogged = true
				self.active = false
				self.completed = true
				ml_navigation:DisableAutoFollow(true, "MoveToExact complete")
			end
			return
		end
		ml_navigation_exact.DispatchAutoFollow(self.path[self.pathindex], ppos, true)
		return
	end

	-- Not reached — dispatch autofollow toward next node
	ml_navigation_exact.DispatchAutoFollow(nextnode, ppos, false)
end

------------------------------------------------------------
-- MoveToExact OMC Handler
------------------------------------------------------------
function ml_navigation_exact.HandleOMC(ppos, ticks)
	local self = ml_navigation_exact
	local nc = self.omc_details
	local nextnode = self.path[self.pathindex]
	local nextnextnode = self.path[self.pathindex + 1]

	if (not nc or not nextnode) then
		ml_navigation_exact.ResetOMCState()
		return
	end

	local from_pos, to_pos, ncradius, ncsubtype, from_heading

	if (nc.sideA ~= nil) then
		if (self.omc_direction == 1) then
			from_pos = nc.sideA
			to_pos = nc.sideB
			ncradius = nc.sideA.radius
			from_heading = nc.details.headingA_x
		else
			from_pos = nc.sideB
			to_pos = nc.sideA
			ncradius = nc.sideB.radius
			from_heading = nc.details.headingB_x
		end
		ncsubtype = nc.details.subtype
	else
		if (self.omc_direction == 1) then
			from_pos = nc.from
			to_pos = nc.to
		else
			from_pos = nc.to
			to_pos = nc.from
		end
		ncradius = nc.radius
		ncsubtype = nc.subtype
	end

	-- Stuck detection
	if (not MIsLocked()) then
		if (self.omc_traveltimer == nil) then
			self.omc_traveltimer = ticks
		end
		local timepassed = ticks - self.omc_traveltimer
		local dist = math.distance3d(ppos, nextnode)
		if (self.omc_traveldist == 0) then
			self.omc_traveldist = dist
		end
		if (timepassed < 3000) then
			if (timepassed > 2000 and self.omc_traveldist > dist) then
				self.omc_traveldist = dist
				self.omc_traveltimer = ticks
			end
		else
			d("[MoveToExact]: OMC stuck — not getting closer.")
			Player:StopExact()
			return
		end
	end

	if (self.omc_starttimer ~= 0 and ticks - self.omc_starttimer > 10000) then
		d("[MoveToExact]: OMC timeout (10s).")
		Player:StopExact()
		return
	end

	-- OMC Jump (subtype 1)
	if (ncsubtype == 1) then
		if (not self.omc_startheight) then
			if (self.omc_starttimer == 0) then
				self.omc_starttimer = ticks
				d("[OMC-DBG] Exact:timer-start moving=" .. tostring(Player:IsMoving()) .. " af=" .. tostring(Player:IsAutoFollowOn()) .. " jumping=" .. tostring(Player:IsJumping()) .. " pidx=" .. tostring(self.pathindex) .. " from=" .. tostring(from_pos.x) .. "," .. tostring(from_pos.y) .. "," .. tostring(from_pos.z) .. " to=" .. tostring(to_pos.x) .. "," .. tostring(to_pos.y) .. "," .. tostring(to_pos.z))
				if (not Player:IsMoving()) then
					d("[OMC-DBG] Exact:dispatch moving=false af=" .. tostring(Player:IsAutoFollowOn()))
					ml_navigation_exact.DispatchAutoFollow(to_pos, ppos, true)
				end
			elseif (Player:IsMoving() and ticks - self.omc_starttimer > 100) then
				self.omc_startheight = ppos.y
				d("[OMC-DBG] Exact:JUMP startheight=" .. tostring(ppos.y) .. " moving=" .. tostring(Player:IsMoving()) .. " af=" .. tostring(Player:IsAutoFollowOn()) .. " tElapsed=" .. tostring(ticks - self.omc_starttimer))
				Player:Jump()
				d("[MoveToExact]: OMC Jump started.")
			end
		else
			local todist2d = math.distance2d(ppos, to_pos)
			d("[OMC-DBG] Exact:in-air todist2d=" .. tostring(todist2d) .. " y=" .. tostring(ppos.y) .. " moving=" .. tostring(Player:IsMoving()) .. " jumping=" .. tostring(Player:IsJumping()) .. " af=" .. tostring(Player:IsAutoFollowOn()))

			-- Stall detection: player hasn't descended after 1500ms, retry jump
			if (ticks - self.omc_starttimer > 1500 and ppos.y > self.omc_startheight - 1.0) then
				self.omc_jumpretries = (self.omc_jumpretries or 0) + 1
				d("[OMC-DBG] Exact:STALL-RETRY #" .. tostring(self.omc_jumpretries) .. " ppos_y=" .. tostring(ppos.y) .. " startheight=" .. tostring(self.omc_startheight) .. " elapsed=" .. tostring(ticks - self.omc_starttimer))
				if (self.omc_jumpretries > 3) then
					d("[MoveToExact]: OMC jump stalled after 3 retries, giving up.")
					Player:StopExact()
					return
				end
				self.omc_startheight = nil
				self.omc_starttimer = ticks
				return
			end

			if (todist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
				d("[OMC-DBG] Exact:LANDED todist2d=" .. tostring(todist2d))
				self.pathindex = self.pathindex + 1
				ml_navigation_exact.ResetAutoFollowState()
				ml_navigation_exact.ResetOMCState()
				d("[MoveToExact]: OMC Jump landed.")
			else
				if (from_pos.y > (ppos.y + 1) and to_pos.y > (ppos.y + 1)) then
					d("[OMC-DBG] Exact:FAIL-below from_y=" .. tostring(from_pos.y) .. " to_y=" .. tostring(to_pos.y) .. " ppos_y=" .. tostring(ppos.y))
					d("[MoveToExact]: OMC Jump failed — fell below both endpoints.")
					Player:StopExact()
					return
				end
				ml_navigation_exact.DispatchAutoFollow(to_pos, ppos, true)
			end
		end
		return
	end

	-- OMC Walk (subtype 2)
	if (ncsubtype == 2) then
		if (self.omc_starttimer == 0) then
			self.omc_starttimer = ticks
		end
		local todist2d = math.distance2d(ppos, nextnode)
		if (todist2d <= self.threshold) then
			self.pathindex = self.pathindex + 1
			ml_navigation_exact.ResetAutoFollowState()
			ml_navigation_exact.ResetOMCState()
			d("[MoveToExact]: OMC Walk complete.")
		else
			ml_navigation_exact.DispatchAutoFollow(nextnode, ppos, true)
		end
		return
	end

	-- OMC Teleport (subtype 3)
	if (ncsubtype == 3) then
		if (Player:IsMoving() or Player:IsJumping()) then
			Player:StopMovement()
			return
		end
		if (gTeleportHack) then
			Hacks:TeleportToXYZ(to_pos.x, to_pos.y, to_pos.z)
			d("[MoveToExact]: OMC Teleport.")
		else
			NavigationManager:DisableNavConnection(nc.id)
		end
		self.pathindex = self.pathindex + 1
		ml_navigation_exact.ResetAutoFollowState()
		ml_navigation_exact.ResetOMCState()
		return
	end

	-- OMC Interact (subtype 4)
	if (ncsubtype == 4) then
		if (Player:IsMoving()) then
			Player:StopMovement()
			return
		end

		if (MIsLoading()) then
			self.lastupdate = self.lastupdate + 1500
			self.pathindex = self.pathindex + 1
			ml_navigation_exact.ResetAutoFollowState()
			ml_navigation_exact.ResetOMCState()
			return
		end

		if (IsControlOpen("SelectString") or IsControlOpen("SelectIconString")) then
			SelectConversationIndex(1)
			self.lastupdate = self.lastupdate + 1000
			return
		end

		if (IsPositionLocked()) then
			self.lastupdate = self.lastupdate + 500
			return
		end

		local todist = math.distance3d(ppos, nextnode)
		local todist2d = math.distance2d(ppos, nextnode)
		if (todist <= ml_navigation.NavPointReachedDistances["3dwalk"] and todist2d <= ml_navigation.NavPointReachedDistances["2dwalk"]) then
			self.pathindex = self.pathindex + 1
			ml_navigation_exact.ResetAutoFollowState()
			ml_navigation_exact.ResetOMCState()
			d("[MoveToExact]: OMC Interact node reached.")
			return
		end

		local interactnpc
		local elist = MEntityList("nearest,targetable,type=7,chartype=0,maxdistance=5")
		if (table.valid(elist)) then interactnpc = select(2, next(elist)) end

		if (not interactnpc) then
			elist = MEntityList("nearest,targetable,type=3,chartype=0,maxdistance=5")
			if (table.valid(elist)) then interactnpc = select(2, next(elist)) end
		end

		if (not interactnpc) then
			elist = MEntityList("nearest,targetable,maxdistance=7")
			if (table.valid(elist)) then interactnpc = select(2, next(elist)) end
		end

		if (interactnpc) then
			if (not Player:IsInteracting()) then
				Player:Interact(interactnpc.id)
				self.lastupdate = self.lastupdate + 1000
			end
		end
		return
	end

	-- Unknown subtype — skip
	d("[MoveToExact]: Unknown OMC subtype " .. tostring(ncsubtype) .. ", skipping.")
	self.pathindex = self.pathindex + 1
	ml_navigation_exact.ResetAutoFollowState()
	ml_navigation_exact.ResetOMCState()
end

------------------------------------------------------------
-- ffnav — Async State Machine for Flight Transitions
------------------------------------------------------------
ffnav = {}
ffnav.yield = {}
ffnav.process = {}
ffnav.alteredGoal = {}
ffnav.lastGoal = {}
ffnav.currentParams = {}
ffnav.lastGoalResult = false
ffnav.lastGoalCheck = 0
ffnav.lastPathTime = 0
ffnav.ascendTime = 0
ffnav.lastCubeSwap = 0
ffnav.lastTrim = 0
ffnav.forceDescent = 0
ffnav.descentPos = {}
ffnav.isascending = false
ffnav.isdescending = false
ffnav.descentAttempts = 0
ffnav.lastDescentTime = 0
ffnav.landingProbeCache = {}
ffnav.landingFallbackActive = false
ffnav.landingFallbackPos = nil
ffnav.landingFallbackOrigin = nil
ffnav.landingFallbackSmoothed = false
ffnav.landingLookaheadDist = 40
ffnav.flightLoopGuard = { key = nil, lastAction = nil, lastTime = 0, count = 0, lockUntil = 0 }

function ffnav.CompactPath()
	local newPath = {}
	if (table.valid(ml_navigation.path)) then
		for i,node in pairsByKeys(ml_navigation.path) do
			if (table.size(newPath) > 0) then
				table.insert(newPath,node)
			else
				newPath[0] = node
			end
		end
	end
	ml_navigation.path = newPath
end

function ffnav.IsProcessing()
	if (ffnav.IsYielding()) then
		return true
	end

	if (table.valid(ffnav.process)) then
		local process = ffnav.process

		local successTimer = false
		local successEval = false

		if (process.dowhile ~= nil and type(process.dowhile) == "function") then
			process.dowhile()
		end
		if (process.mintimer and process.mintimer ~= 0) then
			if (Now() < process.mintimer) then
				return true
			end
		end
		if (process.maxtimer and process.maxtimer ~= 0 and Now() >= process.maxtimer) then
			successTimer = true
		end

		if (process.evaluator ~= nil and type(process.evaluator) == "function") then
			local ret = process.evaluator()
			if (ret == true) then
				ffnav.process = {}

				if (process.followsuccess ~= nil and type(process.followsuccess) == "function") then
					process.followsuccess()
					return true
				end

				if (process.followall ~= nil and type(process.followall) == "function") then
					process.followall()
					return true
				end
			end
		end

		local failed = false
		if (process.failure ~= nil and type(process.failure) == "function") then
			local ret = process.failure()
			if (ret == true) then
				failed = true
			end
		end

		if (successTimer or failed) then
			ffnav.process = {}
			if (successTimer and process.followfail ~= nil and type(process.followfail) == "function") then
				process.followfail()
			end
			if (process.followall ~= nil and type(process.followall) == "function") then
				process.followall()
			end
		end
		return true
	end
	return false
end

function ffnav.IsYielding()
	if (table.valid(ffnav.yield)) then
		local yield = ffnav.yield

		local successTimer = false
		local successEval = false

		if (yield.dowhile ~= nil and type(yield.dowhile) == "function") then
			yield.dowhile()
		end

		if (yield.mintimer ~= 0) then
			if (Now() < yield.mintimer) then
				return true
			end
		end

		if (yield.evaluator ~= nil and type(yield.evaluator) == "function") then
			local ret = yield.evaluator()
			if (ret == true) then
				successEval = true
			end
		end
		if (yield.maxtimer ~= 0 and Now() >= yield.maxtimer) then
			successTimer = true
		end

		if (successTimer or successEval) then
			ffnav.yield = {}

			if (successEval and yield.followsuccess ~= nil and type(yield.followsuccess) == "function") then
				yield.followsuccess()
				return true
			end

			if (successTimer and yield.followfail ~= nil and type(yield.followfail) == "function") then
				yield.followfail()
				return true
			end

			if (yield.followall ~= nil and type(yield.followall) == "function") then
				yield.followall()
				return true
			end

			return false
		end

		return true
	end
	return false
end

function ffnav.Await(param1, param2, param3, param4, param5)
	if (param1 and type(param1) == "number") then
		if (param2 and type(param2) == "number") then
			ffnav.yield = {
				mintimer = IIF(param1 ~= 0,Now() + param1,0),
				maxtimer = IIF(param2 ~= 0,Now() + param2,0),
				evaluator = param3,
				followall = param4,
				both = IsNull(param5,false),
			}
		else
			ffnav.yield = {
				mintimer = 0,
				maxtimer = Now() + param1,
				evaluator = param2,
				followall = param3,
				both = IsNull(param4,false),
			}
		end
	end
end

function ffnav.AwaitDo(param1, param2, param3, param4, param5)
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
		ffnav.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			dowhile = param4,
			followall = param5,
		}
	else
		ffnav.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			dowhile = param3,
			followall = param4,
		}
	end
end

function ffnav.AwaitFail(param1, param2, param3, param4, param5)
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
		ffnav.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			both = IsNull(param4,false),
			followfail = param5,
		}
	else
		ffnav.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			followfail = param3,
			both = IsNull(param4,false),
		}
	end
end

function ffnav.AwaitSuccess(param1, param2, param3, param4, param5)
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
		ffnav.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			followsuccess = param4,
			both = IsNull(param5,false),
		}
	else
		ffnav.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			followsuccess = param3,
			both = IsNull(param4,false),
		}
	end
end

function ffnav.AwaitSuccessFail(param1, param2, param3, param4, param5, param6)
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
		ffnav.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			failure = param4,
			followsuccess = param5,
			followfail = param6,
		}
	else
		ffnav.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			failure = param3,
			followsuccess = param4,
			followfail = param5,
		}
	end
end

function ffnav.AwaitThen(param1, param2, param3, param4)
	if (param1 and type(param1) == "number" and param2 and type(param2) == "number") then
		if (param4 ~= nil and type(param4) == "function") then
			ffnav.yield = {
				mintimer = IIF(param1 ~= 0,Now() + param1,0),
				maxtimer = IIF(param2 ~= 0,Now() + param2,0),
				evaluator = param3,
				followall = param4,
			}
		else
			ffnav.yield = {
				mintimer = IIF(param1 ~= 0,Now() + param1,0),
				maxtimer = IIF(param2 ~= 0,Now() + param2,0),
				followall = param3,
			}
		end
	else
		if (param3 ~= nil and type(param3) == "function") then
			ffnav.yield = {
				mintimer = 0,
				maxtimer = Now() + param1,
				evaluator = param2,
				followall = param3,
			}
		else
			ffnav.yield = {
				mintimer = 0,
				maxtimer = Now() + param1,
				followall = param2,
			}
		end
	end
end

------------------------------------------------------------
-- Path Drawing
------------------------------------------------------------
function ml_navigation.DrawPath(event, ticks)
	if ( gNavShowPath and table.size(ml_navigation.path) > 1 ) then
		local maxWidth, maxHeight = GUI:GetScreenSize()
		GUI:SetNextWindowPos(0, 0, GUI.SetCond_Always)
		GUI:SetNextWindowSize(maxWidth,maxHeight,GUI.SetCond_Always)
		local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
		GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], 0)
		flags = (GUI.WindowFlags_NoInputs + GUI.WindowFlags_NoBringToFrontOnFocus + GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
		GUI:Begin("Show Nav Space", true, flags)

		local nodemap = {}
		for id, node in pairsByKeys(ml_navigation.path) do
			local nodePos = RenderManager:WorldToScreen({ x = node.x, y = node.y, z = node.z })
			if (table.valid(nodePos)) then
				GUI:AddCircleFilled(nodePos.x,nodePos.y,7,GUI:ColorConvertFloat4ToU32(1,.2,.2,1))
				table.insert(nodemap,nodePos)
			end
		end

		for i = 1,#nodemap do
			local thisnode = nodemap[i]
			local nextnode = nodemap[i+1]
			if (thisnode and nextnode) then
				GUI:AddLine(thisnode.x, thisnode.y, nextnode.x, nextnode.y, GUI:ColorConvertFloat4ToU32(.2,1,.2,1), 6)
			end
		end

		GUI:End()
		GUI:PopStyleColor()
	end
end

-- MoveToExact path drawing (cyan nodes, yellow lines)
function ml_navigation_exact.DrawPath(event, ticks)
	if (not table.valid(ml_navigation_exact.path)) then return end
	local ppos = Player.pos

	local maxWidth, maxHeight = GUI:GetScreenSize()
	GUI:SetNextWindowPos(0, 0, GUI.SetCond_Always)
	GUI:SetNextWindowSize(maxWidth, maxHeight, GUI.SetCond_Always)
	local winBG = ml_gui.style.current.colors[GUI.Col_WindowBg]
	GUI:PushStyleColor(GUI.Col_WindowBg, winBG[1], winBG[2], winBG[3], 0)
	local flags = (GUI.WindowFlags_NoInputs + GUI.WindowFlags_NoBringToFrontOnFocus + GUI.WindowFlags_NoTitleBar + GUI.WindowFlags_NoResize + GUI.WindowFlags_NoScrollbar + GUI.WindowFlags_NoCollapse)
	GUI:Begin("Show Exact Nav Space", true, flags)

	local screenNodes = {}
	local drawKeys = {}
	local pathindex = ml_navigation_exact.pathindex or 1
	local orderedKeys = {}
	for id in pairsByKeys(ml_navigation_exact.path) do
		table.insert(orderedKeys, id)
	end
	for order, id in ipairs(orderedKeys) do
		local node = ml_navigation_exact.path[id]
		local shouldDraw = true
		if (order <= 2 and ppos and node) then
			local nearPlayer2D = math.distance2d(ppos, node) <= 0.35
			local nearPlayerY = (not node.y or not ppos.y or math.abs(node.y - ppos.y) <= 1.5)
			if ((node.is_start or nearPlayer2D) and nearPlayer2D and nearPlayerY) then
				shouldDraw = false
			end
		end
		local nodePos = RenderManager:WorldToScreen({ x = node.x, y = node.y + 0.15, z = node.z })
		if (shouldDraw and table.valid(nodePos)) then
			screenNodes[id] = nodePos
			table.insert(drawKeys, id)
			local alpha = (id >= pathindex) and 1 or 0.3
			GUI:AddCircleFilled(nodePos.x, nodePos.y, 7, GUI:ColorConvertFloat4ToU32(0, .9, .9, alpha))
		end
	end

	local activeNode = ml_navigation_exact.path[pathindex]
	if (activeNode and ppos) then
		local dispatchY = ml_navigation_exact.GetDispatchTargetY(activeNode, ppos)
		if (dispatchY) then
			local dispatchPos = RenderManager:WorldToScreen({ x = activeNode.x, y = dispatchY + 0.2, z = activeNode.z })
			if (table.valid(dispatchPos)) then
				GUI:AddCircle(dispatchPos.x, dispatchPos.y, 9, GUI:ColorConvertFloat4ToU32(1, .5, 0, 1), 24, 2)
			end
		end
	end

	for i = 1, #drawKeys - 1 do
		local thisId = drawKeys[i]
		local nextId = drawKeys[i + 1]
		local thisScreen = screenNodes[thisId]
		local nextScreen = screenNodes[nextId]
		local thisNode = ml_navigation_exact.path[thisId]
		local nextNode = ml_navigation_exact.path[nextId]
		local skipAnchorStub = false
		if (thisNode and nextNode) then
			local seg2d = math.distance2d(thisNode, nextNode)
			local segY = (thisNode.y and nextNode.y) and math.abs(thisNode.y - nextNode.y) or 0
			if (seg2d <= 0.30 and segY <= 1.25) then
				skipAnchorStub = true
			end
		end
		if (thisScreen and nextScreen and not skipAnchorStub) then
			GUI:AddLine(thisScreen.x, thisScreen.y, nextScreen.x, nextScreen.y, GUI:ColorConvertFloat4ToU32(1, 1, .2, 1), 3)
		end
	end

	GUI:End()
	GUI:PopStyleColor()
end
RegisterEventHandler("Gameloop.Draw", ml_navigation_exact.DrawPath, "ml_navigation_exact.DrawPath")

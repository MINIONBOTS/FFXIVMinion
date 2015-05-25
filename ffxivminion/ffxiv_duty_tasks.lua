c_dutyavoid = inheritsFrom( ml_cause )
e_dutyavoid = inheritsFrom( ml_effect )
c_dutyavoid.avoidTime = nil
c_dutyavoid.facing = 0
function c_dutyavoid:evaluate()
	if (ml_task_hub:ThisTask().name ~= "DUTY_KILL") then
		return false
	end
	
	if (not ml_task_hub:ThisTask().encounterData["avoid"] or 
		not ml_task_hub:ThisTask().encounterData["avoidpos"]) 
	then
		return false
	end
	
	for uniqueid in StringSplit(ml_task_hub:ThisTask().encounterData.bossIDs,";") do
		local el = EntityList("alive,contentid="..uniqueid..",maxdistance="..tostring(ml_task_hub:ThisTask().encounterData.radius))
		if (ml_task_hub:ThisTask().encounterData["avoidAll"]) then
			el = EntityList("alive,maxdistance=300")
		end
		if (ValidTable(el)) then
			for id, target in pairs(el) do
				if (target.castinginfo) then
					for spell in StringSplit(ml_task_hub:ThisTask().encounterData["avoid"],";") do
						if (tonumber(spell) == target.castinginfo.channelingid or tonumber(spell) == target.castinginfo.castingid) then
							c_dutyavoid.avoidTime = target.castinginfo.casttime + 1000
							c_dutyavoid.facing = target.pos.h
							return true
						end
					end
				end
			end
		end		
	end
	
    return false
end
function e_dutyavoid:execute() 
	d("Kicking off duty avoid.")
	local avoidpos = ml_task_hub:ThisTask().encounterData["avoidpos"]
	local avoidtime = ml_task_hub:ThisTask().encounterData["avoidTime"] or c_dutyavoid.avoidTime
	
	GameHacks:TeleportToXYZ(avoidpos.x, avoidpos.y, avoidpos.z)
	Player:SetFacing(c_dutyavoid.facing)
	ml_task_hub:ThisTask().immunePulses = 0
	ml_task_hub:ThisTask().failTimer = 0
	ml_task_hub:CurrentTask():SetDelay(avoidtime)
	--[[
	local newTask = ffxiv_task_duty_avoid.Create()
	newTask.pos = ml_task_hub:ThisTask().encounterData["avoidpos"]
	newTask.targetid = target.id
	newTask.interruptCasting = true
	newTask.maxTime = tonumber(target.castinginfo.casttime) + 500
	ml_task_hub:ThisTask().preserveSubtasks = true
	ml_task_hub:Add(newTask, IMMEDIATE_GOAL, TP_IMMEDIATE)
	--]]
end

ffxiv_duty_kill_task = inheritsFrom(ml_task)
function ffxiv_duty_kill_task.Create()
    local newinst = inheritsFrom(ffxiv_duty_kill_task)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
	newinst.name = "DUTY_KILL"
	newinst.timer = 0
	newinst.failed = false
	newinst.failTimer = 0
	newinst.encounterData = {}
	newinst.suppressFollow = false
	newinst.suppressFollowTimer = 0
	newinst.suppressAssist = false
	newinst.pullHandled = false
	newinst.hasSynced = false
	
	newinst.immunePulses = 0
	newinst.lastEntity = nil
	newinst.lastHPPercent = 100
	newinst.immuneMax = 80
	newinst.currentPos = nil
	
	--Reset the tempvars.
	ffxiv_task_duty.tempvars = {}
	
    return newinst
end

function ffxiv_duty_kill_task:Process()	
	local tempvars = ffxiv_task_duty.tempvars
	
	if (tempvars["reactionprocesstime"]) then
		if (Now() < tempvars["reactionprocesstime"]) then
			d("Waiting on reaction processing.")
			return false
		else
			d("Found a process reaction time, but the time has elapsed.")
		end
	end
	
	if (not self.hasSynced) then
		Player:SetFacingSynced(Player.pos.h)
		self.hasSynced = true
	end
	
	if (self.encounterData["immuneMax"]) then
		local immunity = tonumber(self.encounterData["immuneMax"]) or 80
		self.immuneMax = immunity
	end
	
	local killPercent = nil
	if ( self.encounterData["killto%"]) then
		killPercent = tonumber(self.encounterData["killto%"])
	end

	local entity = GetDutyTarget(killPercent)
	
	local myPos = shallowcopy(Player.pos)
	local fightPos = nil
	if (self.encounterData.fightPos) then
		fightPos = self.encounterData.fightPos["General"]
	end
	
	local startPos = nil
	if (self.encounterData.startPos) then
		startPos = self.encounterData.startPos["General"]
	end
	
	if (fightPos and self.pullHandled) then
		self.currentPos = fightPos
	else
		self.currentPos = startPos
	end
	
	if (fightPos and self.pullHandled and Distance3D(myPos.x,myPos.y,myPos.z,fightPos.x,fightPos.y,fightPos.z) > 1) then
		GameHacks:TeleportToXYZ(fightPos.x, fightPos.y, fightPos.z)
		if (ValidTable(entity)) then
			SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
		else
			Player:SetFacing(Player.pos.h)
		end
	elseif (startPos and fightPos == nil and Distance3D(myPos.x,myPos.y,myPos.z,startPos.x,startPos.y,startPos.z) > 1 and TableSize(SkillMgr.teleBack) == 0) then
		GameHacks:TeleportToXYZ(startPos.x, startPos.y, startPos.z)
		if (ValidTable(entity)) then
			SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
		else
			Player:SetFacing(Player.pos.h)
		end
	end
	
	local usedReaction = false
	if (self.encounterData.condition and self.encounterData.reaction) then
		local reactionIndex = 0
		local conditionsTable = shallowcopy(self.encounterData.condition)
		local needsReaction = true
		for id, conditions in pairs(conditionsTable) do
			needsReaction = true
			for condition,value in pairs(conditions) do
				local f = assert(loadstring("return " .. condition))()
				if (f ~= nil) then
					if (f ~= value) then
						needsReaction = false
					end
				end
			end
			if (needsReaction) then
				reactionIndex = id
				break
			end			
		end
		
		if (needsReaction) then
			local reactionTable = self.encounterData.reaction
			local reaction = reactionTable[reactionIndex]
			
			local targetAdjustments = self.encounterData.telehackAdjustments or {}
			
			local reactionType = reaction.type
			if (reactionType == "gotoPos") then
				local myPos = Player.pos
				local gotoPos = reaction.pos
				if (Distance3D(myPos.x,myPos.y,myPos.z,gotoPos.x,gotoPos.y,gotoPos.z) > 1.5) then
					GameHacks:TeleportToXYZ(gotoPos.x, gotoPos.y, gotoPos.z)
					Player:SetFacingSynced(gotoPos.h)
				end
				usedReaction = true
			elseif (reactionType == "avoidSpell") then
				local myPos = Player.pos
				local gotoPos = reaction.pos
				if (Distance3D(myPos.x,myPos.y,myPos.z,gotoPos.x,gotoPos.y,gotoPos.z) > 1.5) then
					GameHacks:TeleportToXYZ(gotoPos.x, gotoPos.y, gotoPos.z)
					Player:SetFacingSynced(gotoPos.h)
					local delayTime = reaction.waitTime or 4000
					tempvars["reactionprocesstime"] = Now() + delayTime
				end
				usedReaction = true
			elseif (reactionType == "gotoTarget") then
				local reactionTarget = reaction.id or 0
				if (reactionTarget and reactionTarget ~= 0) then
					local el = EntityList("nearest,contentid="..tostring(reactionTarget))
					if (ValidTable(el)) then
						local id, target = next(el)
						if (target) then
							local myPos = shallowcopy(Player.pos)
							local gotoPos = target.pos
							if (Distance3D(myPos.x,myPos.y,myPos.z,gotoPos.x,gotoPos.y,gotoPos.z) > 3) then
								GameHacks:TeleportToXYZ(gotoPos.x, gotoPos.y, gotoPos.z)
								Player:SetFacingSynced(gotoPos.h)
							end
						end
					end
				end
				usedReaction = true
			elseif (reactionType == "interactTarget") then
				local reactionTarget = reaction.id or 0
				if (reactionTarget and reactionTarget ~= 0) then
					if (not tempvars["interactprocesslist"]) then
						tempvars["interactprocesslist"] = {}
					end
					local processlist = tempvars["interactprocesslist"]
					
					local inprocessid = 0
					local blockedids = {}
					local availableids = {}
					local processlist = tempvars["interactprocesslist"]
					if (ValidTable(processlist)) then
						for id,interact in pairs(processlist) do
							if (interact.blocked ~= 0 and Now() < interact.blocked) then
								blockedids[id] = true
								d("[interactTarget]: ID : "..tostring(id).." is temporarily blocked due to cooldown usage.")
							end
							if (interact.inprocess) then
								inprocessid = id
								d("[interactTarget]: ID : "..tostring(id).." is in process currently so it will be used.")
							end
						end
					end
					
					local interactid = nil
					if (inprocessid == 0) then
						local el = EntityList("targetable,contentid="..tostring(reactionTarget))
						if (ValidTable(el)) then
							local closest = nil
							local closestDistance = 999
							for id,target in pairs(el) do
								local skip = false
								if (ValidTable(blockedids) and blockedids[id]) then
									skip = true
								end
								if (not skip) then
									if (not closest or (closest and target.distance < closestDistance)) then
										closest = target.id
									end
								end
							end
							interactid = closest
						end
					else
						interactid = inprocessid
					end
					
					if (interactid) then
						local target = EntityList:Get(interactid)
						if (ValidTable(target)) then
							local myPos = Player.pos
							local tpos = target.pos
							local dist = Distance3D(myPos.x,myPos.y,myPos.z,tpos.x,tpos.y,tpos.z)
							
							if (processlist[target.id] and Now() < processlist[target.id].blocked) then
								d("[interactTarget]: ID : "..tostring(target.id).." is currently blocked, should not have reached this point.")
								return
							end
							
							if (dist > 3 and not ActionList:IsCasting() and not IsPositionLocked()) then
								GameHacks:TeleportToXYZ(tpos.x, tpos.y, tpos.z)
								if (dist > 50) then
									Player:SetFacingSynced(tpos.x, tpos.y, tpos.z)
								end
								Player:Jump()
							end
							
							Player:SetFacing(tpos.x,tpos.y,tpos.z)
							Player:SetTarget(target.id)
							Player:Interact(target.id)
							local cooldownTime = tonumber(reaction.cooldownTime) or 1000
							processlist[target.id] = {inprocess = false, blocked = (Now() + cooldownTime)}
							local delayTime = reaction.waitTime or 150
							tempvars["reactionprocesstime"] = Now() + delayTime
						end
					end
				end
				usedReaction = true
			elseif (reactionType == "useCannon") then
				local reactionTarget = reaction.id or 0
				if (reactionTarget and reactionTarget ~= 0) then
					if (not tempvars["cannonprocesslist"]) then
						tempvars["cannonprocesslist"] = {}
					end
					
					local inprocessid = 0
					local blockedids = {}
					local availableids = {}
					local processlist = tempvars["cannonprocesslist"]
					if (ValidTable(processlist)) then
						for id,cannon in pairs(processlist) do
							if (cannon.blocked ~= 0 and Now() < cannon.blocked) then
								blockedids[id] = true
								d("[useCannon]: ID : "..tostring(id).." is temporarily blocked because it has been fired.")
							end
							if (cannon.inprocess) then
								inprocessid = id
								d("[useCannon]: ID : "..tostring(id).." is in process currently so it will be fired.")
							end
						end
					end
					
					local cannonid = nil
					if (inprocessid == 0) then
						local el = EntityList("targetable,contentid="..tostring(reactionTarget))
						if (ValidTable(el)) then
							local closest = nil
							local closestDistance = 999
							for id,target in pairs(el) do
								local skip = false
								if (ValidTable(blockedids) and blockedids[id]) then
									skip = true
								end
								if (not skip) then
									if (not closest or (closest and target.distance < closestDistance)) then
										closest = target.id
									end
								end
							end
							cannonid = closest
						end
					else
						cannonid = inprocessid
					end
					
					if (cannonid) then
						local cannon = EntityList:Get(cannonid)
						if (ValidTable(cannon)) then
							local myPos = Player.pos
							local tpos = cannon.pos
							local dist = Distance3D(myPos.x,myPos.y,myPos.z,tpos.x,tpos.y,tpos.z)
							if (dist > 3 and not ActionList:IsCasting()) then
								GameHacks:TeleportToXYZ(tpos.x, tpos.y, tpos.z)
								if (dist > 50) then
									Player:SetFacingSynced(tpos.x, tpos.y, tpos.z)
								end
								Player:Jump()
							end
							Player:SetFacing(tpos.x,tpos.y,tpos.z)
							Player:SetTarget(cannon.id)
							Player:Interact(cannon.id)
							processlist[cannon.id] = { inprocess = true, blocked = 0 }
							tempvars["reactionprocesstime"] = Now() + 2500
							d("[useCannon]: Interacting with target id :"..tostring(cannon.id))
							
							local newTask = ffxiv_duty_firecannon.Create()

							local shootPos = nil
							if (reaction.shootTarget) then
								local shootid = reaction.shootTarget
								local el = EntityList("targetable,contentid="..tostring(shootid))
								if (ValidTable(el)) then
									local id, target = next(el)
									if (target) then
										shootPos = target.pos
										d("[useCannon]: Collected target position for cannon fire.")
									end
								end
							elseif (ValidTable(reaction.shootPos)) then
								shootPos = reaction.shootPos
							end
							
							newTask.cannonid = cannonid
							newTask.shootPos = shootPos
							newTask.skillid = reaction.skillid
							newTask.delayTime = tonumber(reaction.waitTime) or 2000
							newTask.cooldownTime = tonumber(reaction.cooldownTime) or 10000
							ml_task_hub:CurrentTask():AddSubTask(newTask)
						end
					end
				end
				usedReaction = true
			elseif (reactionType == "useAction") then
				local reactionTarget = reaction.id or 0
				if (reactionTarget and reactionTarget ~= 0) then
					
					local targetid = nil
					local el = EntityList("nearest,targetable,contentid="..tostring(reactionTarget))
					if (ValidTable(el)) then
						local i,target = next(el)
						if (ValidTable(target)) then
							targetid = target.id
						end
					end
					
					if (targetid) then
						local target = EntityList:Get(targetid)
						if (ValidTable(target)) then
							local myPos = Player.pos
							local tpos = target.pos
							
							Player:SetFacing(tpos.x,tpos.y,tpos.z)
							Player:SetTarget(target.id)
							
							local action = nil
							if (reaction.skilltype and tonumber(reaction.skilltype) ~= nil) then
								action = ActionList:Get(reaction.skillid,reaction.skilltype)
							else
								action = ActionList:Get(reaction.skillid)
							end
							
							if (ValidTable(action) and action.isready) then
								if (reaction.groundTarget) then
									local shootPos = tpos
									d("[useAction]: FIRING POSITION [X:"..tostring(shootPos.x).."][Y:"..tostring(shootPos.y).."][Z:"..tostring(shootPos.z).."]")
									if (action:Cast(shootPos.x, shootPos.y, shootPos.z)) then
										d("[useAction]: SKILL FIRED.")
										tempvars["reactionprocesstime"] = Now() + 500
									end
								else 
									if (action:Cast(target.id)) then
										d("[useAction]: SKILL FIRED.")
										tempvars["reactionprocesstime"] = Now() + 500
									end
								end
							end
						end
					end
				end
				usedReaction = true
			elseif (reactionType == "killTarget" or reactionType == "killFromPosition") then
				local reactionTarget = reaction.id or 0
				if (reactionTarget and reactionTarget ~= 0) then
				
					local el = nil
					if (reaction.prioritize ~= nil and reaction.prioritize == true) then
						local bossids = tostring(reactionTarget)
						for uniqueid in StringSplit(bossids,";") do
							if uniqueid ~= "" then
								el = EntityList("lowesthealth,alive,attackable,contentid="..uniqueid)
								if (ValidTable(el)) then
									break
								end
						
								el = EntityList("nearest,alive,attackable,contentid="..uniqueid)
								if (ValidTable(el)) then
									break
								end	
							end
						end
					end
	
					if (not ValidTable(el)) then
						el = EntityList("nearest,alive,attackable,contentid="..tostring(reactionTarget))
					end
					
					if (ValidTable(el)) then
						local id, target = next(el)
						if (target) then
							local myPos = Player.pos
							local returnPos = self.currentPos
							
							if (reactionType == "killFromPosition") then
								d("Adjusting fight and return position.")
								local fightPos = reaction.fightPos
								local range = reaction.range or 15
								if (Distance3D(myPos.x,myPos.y,myPos.z,fightPos.x,fightPos.y,fightPos.z) > range) then
									returnPos = {x = fightPos.x, y = fightPos.y, z = fightPos.z}
									GameHacks:TeleportToXYZ(fightPos.x, fightPos.y, fightPos.z)
									Player:SetFacingSynced(fightPos.h)
								end
							end
							
							local pos = target.pos
							Player:SetTarget(target.id)
						
							--Telecasting, teleport to mob portion.
							if (ml_global_information.AttackRange < 5 and 
								gUseTelecast == "1" and 
								target.castinginfo.channelingid == 0 and
								gTeleport == "1" and 
								SkillMgr.teleCastTimer == 0 and 
								SkillMgr.IsGCDReady() and 
								(target.targetid ~= Player.id or self.encounterData.telecastAlways) and 
								Player.hp.percent > 30) 
							then
								
								self.suppressFollow = true
								self.suppressFollowTimer = Now() + 2000
								
								SkillMgr.teleBack = returnPos
								
								if (self.encounterData.telecastPos) then
									d("Using hardcoded telecast position.")
									local telePos = self.encounterData.telecastPos
									GameHacks:TeleportToXYZ(telePos.x,telePos.y,telePos.z)
									Player:SetFacingSynced(pos.x,pos.y,pos.z)
									Player:SetFacing(pos.x,pos.y,pos.z)
								elseif (ValidTable(targetAdjustments)) then
									d("Using adjusted telehack position.")
									local newPos = {x = pos.x, y = pos.y, z = pos.z}
									if (targetAdjustments[target.contentid]) then
										local thisAdjustment = targetAdjustments[target.contentid]
										for k,v in pairs(thisAdjustment) do
											newPos[k] = newPos[k] + v
										end
									end
									GameHacks:TeleportToXYZ(newPos.x,newPos.y, newPos.z)
									Player:SetFacingSynced(pos.x,pos.y,pos.z)
									Player:SetFacing(pos.x,pos.y,pos.z)
								else
									d("Using normal telecast pos.")
									GameHacks:TeleportToXYZ(pos.x + 1,pos.y, pos.z)
									Player:SetFacingSynced(pos.x,pos.y,pos.z)
									Player:SetFacing(pos.x,pos.y,pos.z)
								end
								
								SkillMgr.teleCastTimer = Now() + 1500
							end
							
							SetFacing(pos.x, pos.y, pos.z)
							SkillMgr.Cast( target )
							
							if (TableSize(SkillMgr.teleBack) > 0) then
								returnable = false
								if (Now() > SkillMgr.teleCastTimer) then
									returnable = true
								end
								if (target.castinginfo.channelingid ~= 0) then
									returnable = true
								end
								if (target.targetid == Player.id and not self.encounterData.telecastAlways) then
									returnable = true
								end
								if (Player.hp.percent < 30) then
									returnable = true
								end
								if (Distance3D(Player.pos.x,Player.pos.y,Player.pos.z,pos.x,pos.y,pos.z) > (entity.hitradius + 5)) then
									returnable = true
								end
								if (returnable) then
									local back = SkillMgr.teleBack
									GameHacks:TeleportToXYZ(back.x, back.y, back.z)
									Player:SetFacingSynced(back.h)
									SkillMgr.teleBack = {}
									SkillMgr.teleCastTimer = 0
								end
							end
						end
					end
				end
				usedReaction = true
				self.hasFailed = false
			end
		end
	end

	if (not usedReaction) then
		if (ValidTable(entity)) then
			--d("Attacking current entity:"..tostring(entity.name)..",id:"..tostring(entity.id)..",contentid:"..tostring(entity.uniqueid)..",attackable:"..tostring(entity.attackable))
			if (self.lastEntity == nil or self.lastEntity ~= entity.id) then
				self.lastEntity = entity.id
				self.lastHPPercent = entity.hp.percent
				self.immunePulses = 0
			elseif (self.lastEntity == entity.id) then
				if (self.lastHPPercent == entity.hp.percent) then
					self.immunePulses = self.immunePulses + 1
				elseif (self.lastHPPercent > entity.hp.percent) then
					self.lastHPPercent = entity.hp.percent
					self.immunePulses = 0
				end
			end
			
			if (fightPos and not self.pullHandled) then
				--fightPos is for handling pull situations
				if (entity.targetid == 0) then
					Player:SetTarget(entity.id)
					SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
					SkillMgr.Cast( entity )
					self.hasFailed = false
				else
					GameHacks:TeleportToXYZ(fightPos.x, fightPos.y, fightPos.z)
					SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
					self.pullHandled = true
				end
			elseif (ml_task_hub:CurrentTask().encounterData.doKill ~= nil and 
					ml_task_hub:CurrentTask().encounterData.doKill == false ) then
						if (entity.targetid == 0) then
							Player:SetTarget(entity.id)
							SetFacing(entity.pos.x, entity.pos.y, entity.pos.z)
							SkillMgr.Cast( entity )
							self.hasFailed = false
						else
							self.hasFailed = true
						end
			elseif (ml_task_hub:CurrentTask().encounterData.doKill == nil or 
					ml_task_hub:CurrentTask().encounterData.doKill == true) then
						self.hasFailed = false
						
						local pos = entity.pos
						Player:SetTarget(entity.id)
						
						--Telecasting, teleport to mob portion.
						if (ml_global_information.AttackRange < 5 and 
							gUseTelecast == "1" and 
							entity.castinginfo.channelingid == 0 and
							gTeleport == "1" and 
							SkillMgr.teleCastTimer == 0 and 
							SkillMgr.IsGCDReady() and 
							(entity.targetid ~= Player.id or self.encounterData.telecastAlways) and 
							Player.hp.percent > 30) 
						then
							
							self.suppressFollow = true
							self.suppressFollowTimer = Now() + 2000
							
							SkillMgr.teleBack = self.currentPos
							
							if (self.encounterData.telecastPos) then
								d("Using telecast pos.")
								local telePos = self.encounterData.telecastPos
								GameHacks:TeleportToXYZ(telePos.x,telePos.y,telePos.z)
								Player:SetFacingSynced(pos.x,pos.y,pos.z)
								Player:SetFacing(pos.x,pos.y,pos.z)
							elseif (ValidTable(self.encounterData.telehackAdjustments)) then
								local targetAdjustments = self.encounterData.telehackAdjustments
								d("Using adjusted telehack position.")
								local newPos = {x = pos.x, y = pos.y, z = pos.z}
								if (targetAdjustments[entity.contentid]) then
									local thisAdjustment = targetAdjustments[entity.contentid]
									for k,v in pairs(thisAdjustment) do
										newPos[k] = newPos[k] + v
									end
								end
								GameHacks:TeleportToXYZ(newPos.x,newPos.y, newPos.z)
								Player:SetFacingSynced(pos.x,pos.y,pos.z)
								Player:SetFacing(pos.x,pos.y,pos.z)
							else
								d("Using normal telecast pos.")
								GameHacks:TeleportToXYZ(pos.x + 1,pos.y, pos.z)
								Player:SetFacingSynced(pos.x,pos.y,pos.z)
								Player:SetFacing(pos.x,pos.y,pos.z)
							end
							
							SkillMgr.teleCastTimer = Now() + 1500
						end
						
						SetFacing(pos.x, pos.y, pos.z)
						SkillMgr.Cast( entity )
						
						if (TableSize(SkillMgr.teleBack) > 0) then
							returnable = false
							
							if (Now() > SkillMgr.teleCastTimer) then
								returnable = true
								--d("setting returnable in clause 1 - timer is up")
							end
							
							if (entity.castinginfo.channelingid ~= 0) then
								returnable = true
								--d("setting returnable in clause 2 - enemy is casting")
							end
							
							if (entity.targetid == Player.id and not self.encounterData.telecastAlways) then
								returnable = true
								--d("setting returnable in clause 3 - enemy is targeting player and telecast always is not set")
							end
							
							if (Player.hp.percent < 30) then
								returnable = true
								--d("setting returnable in clause 4 - player has less than 30% hp")
							end
							
							if (Distance3D(Player.pos.x,Player.pos.y,Player.pos.z,pos.x,pos.y,pos.z) > (entity.hitradius + 5)) then
								returnable = true
								--d("setting returnable in clause 5 - distance from entity too far")
							end
							
							if (returnable) then
								local back = SkillMgr.teleBack
								--d("teleporting back")
								GameHacks:TeleportToXYZ(back.x, back.y, back.z)
								Player:SetFacingSynced(back.h)
								SkillMgr.teleBack = {}
								SkillMgr.teleCastTimer = 0
							end
						end
						
			end
		else
			if (Distance3D(Player.pos.x,Player.pos.y,Player.pos.z,self.currentPos.x,self.currentPos.y,self.currentPos.z) > 1) then
				SkillMgr.teleBack = {}
				SkillMgr.teleCastTimer = 0
				GameHacks:TeleportToXYZ(self.currentPos.x, self.currentPos.y, self.currentPos.z)
				Player:SetFacingSynced(self.currentPos.h)
			end
			SkillMgr.Cast( Player, true )
			self.hasFailed = true
		end
	else
		self.hasFailed = false
	end
	
	if (TableSize(ml_task_hub:CurrentTask().process_elements) > 0) then
		ml_cne_hub.clear_queue()
		ml_cne_hub.eval_elements(ml_task_hub:CurrentTask().process_elements)
		ml_cne_hub.queue_to_execute()
		ml_cne_hub.execute()
		return false
	else
		ml_debug("no elements in process table")
	end
end

function ffxiv_duty_kill_task:task_complete_eval()
	-- If the task has failed and we haven't yet started the countdown, start it.
	if (not self.encounterData.noImmune) then
		if (self.immunePulses > self.immuneMax) then
			d("Immune pulses reached "..tostring(self.immunePulses).." which exceeds the max of "..tostring(self.immuneMax)) 
			return true
		end
	end
	
	if (ffxiv_task_duty.preventFail and Now() < ffxiv_task_duty.preventFail) then
		return false
	end
	
	if (self.hasFailed and self.failTimer == 0) then
		if (self.encounterData.failTime and self.encounterData.failTime > 0) then
			self.failTimer = Now() + self.encounterData.failTime
		else
			return true
		end
	end
	
	-- If the task had started counting down, but is no longer failing, reset the state.
	if (not self.hasFailed and self.failTimer ~= 0) then
		self.failTimer = 0
	end
	
	-- If the failTimer is not 0 (starting value) and we've exceeded the time, end the task.
	if (self.failTimer > 0 and Now() > self.failTimer) then
		return true
	end
	
    return false
end
function ffxiv_duty_kill_task:task_complete_execute()
	d("Kill task completing.")
    ml_task_hub:CurrentTask().completed = true
	ml_task_hub:CurrentTask():ParentTask().encounterCompleted = true
end

function ffxiv_duty_kill_task:Init()	
	local ke_dutyAvoid = ml_element:create( "DutyAvoid", c_dutyavoid, e_dutyavoid, 35 )
    self:add( ke_dutyAvoid, self.overwatch_elements)
	
    self:AddTaskCheckCEs()
end

--=================================================================
--Interact Task - Can be used for doors, keys, other interactables. 
-- Leader Only
--=================================================================

c_dutyAtInteract = inheritsFrom( ml_cause )
e_dutyAtInteract = inheritsFrom( ml_effect )
function c_dutyAtInteract:evaluate()
	if (ml_task_hub:ThisTask().name ~= "LT_LOOT" and ml_task_hub:ThisTask().name ~= "LT_INTERACT") then
		return false
	end
	
	if (not ml_task_hub:CurrentTask().encounterData["lootid"] and 
		not ml_task_hub:CurrentTask().encounterData["interactid"]) 
	then
		return false
	end
	
	if (not ml_task_hub:CurrentTask().attarget) then
		local tpos = {}
		local ppos = {}
		
		local searchid = 0
		local lootid = tonumber(ml_task_hub:CurrentTask().encounterData.lootid) or 0
		local interactid = tonumber(ml_task_hub:CurrentTask().encounterData.interactid) or 0
		if (lootid ~= 0) then
			searchid = lootid
		elseif (interactid ~= 0) then
			searchid = interactid
		end
		
		if (searchid == 0) then
			return false
		end
		
		local interacts = EntityList("type=7,chartype=0")
		for i, interactable in pairs(interacts) do
			if interactable.uniqueid == searchid then
				tpos = interactable.pos
				ppos = Player.pos
				local dist = Distance3D(ppos.x,ppos.y,ppos.z,tpos.x,tpos.y,tpos.z)
				if (dist <= 5) then
					return true
				end
			end
		end
		
		local chests = EntityList("type=4,chartype=0")
		for i, interactable in pairs(chests) do
			if interactable.uniqueid == searchid then
				tpos = interactable.pos
				ppos = Player.pos
				local dist = Distance3D(ppos.x,ppos.y,ppos.z,tpos.x,tpos.y,tpos.z)
				if (dist <= 5) then
					return true
				end
			end
		end
		
		local npcs = EntityList("type=3,chartype=0")
		for i, interactable in pairs(npcs) do
			if interactable.uniqueid == searchid then
				tpos = interactable.pos
				ppos = Player.pos
				local dist = Distance3D(ppos.x,ppos.y,ppos.z,tpos.x,tpos.y,tpos.z)
				if (dist <= 5) then
					return true
				end
			end
		end
		
		if (not ml_task_hub:CurrentTask().repositioned) then
			GameHacks:TeleportToXYZ(tpos.x,tpos.y,tpos.z)
			Player:SetFacingSynced(tpos.x,tpos.y,tpos.z)
			ml_task_hub:CurrentTask().repositioned = true
			--[[ Need a mesh to make this work.
			local ppos = Player.pos
			if (not NavigationManager:IsOnMesh(ppos.x,ppos.y,ppos.z)) then
				local p,dist = NavigationManager:GetClosestPointOnMesh(tpos)
				GameHacks:TeleportToXYZ(p.x,p.y,p.z)
				ml_task_hub:CurrentTask().repositioned = true
			end	
			--]]
		end
		
		--[[
		if (TimeSince(ml_task_hub:CurrentTask().throttle) > 1500) then
			local PathSize = Player:MoveTo(tpos.x,tpos.y,tpos.z,2,false,false)
			ml_task_hub:CurrentTask().throttle = Now()
		end
		--]]
	end
	
	return false
end
function e_dutyAtInteract:execute()
	ml_task_hub:CurrentTask().attarget = true
end

c_interact = inheritsFrom( ml_cause )
e_interact = inheritsFrom( ml_effect )
c_interact.id = 0
function c_interact:evaluate()
	if (ml_task_hub:ThisTask().name ~= "LT_LOOT" and ml_task_hub:ThisTask().name ~= "LT_INTERACT") then
		return false
	end
	
	if (not ml_task_hub:CurrentTask().encounterData["lootid"] and 
		not ml_task_hub:CurrentTask().encounterData["interactid"]) 
	then
		return false
	end
	
	if (not ml_task_hub:CurrentTask().attarget) then
		return false
	end
	
	if (Now() < ml_task_hub:CurrentTask().latencyTimer) then
		return false
	end
	ml_task_hub:CurrentTask().latencyTimer = Now() + 1500
	
	local searchid = 0
	local lootid = tonumber(ml_task_hub:CurrentTask().encounterData.lootid) or 0
	local interactid = tonumber(ml_task_hub:CurrentTask().encounterData.interactid) or 0
	if (lootid ~= 0) then
		searchid = lootid
	elseif (interactid ~= 0) then
		searchid = interactid
	end
	
	if (searchid == 0) then
		return false
	end
	
	local interacts = EntityList("type=7,chartype=0,maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
	for i, interactable in pairs(interacts) do
		if interactable.uniqueid == searchid then
			if (interactable.targetable) then
				c_interact.id = interactable.id
				return true
			end
		end
	end
	
	local chests = EntityList("type=4,chartype=0,maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
	for i, interactable in pairs(chests) do
		if interactable.uniqueid == searchid then
			if (interactable.targetable) then
				c_interact.id = interactable.id
				return true
			end
		end
	end
	
	local npcs = EntityList("type=3,chartype=0,maxdistance="..tostring(ml_task_hub:CurrentTask().encounterData.radius))
	for i, interactable in pairs(npcs) do
		if interactable.uniqueid == searchid then
			if (interactable.targetable) then
				c_interact.id = interactable.id
				return true
			end
		end
	end
	
	ml_task_hub:CurrentTask().hasInteract = false
    return false
end
----------------------------------------------------------------------------------------------------------------------------------------
function e_interact:execute()
	local interact = EntityList:Get(c_interact.id)
	Player:SetTarget(interact.id)
	local pos = interact.pos
	SetFacing(pos.x,pos.y,pos.z)
	Player:Interact(interact.id)
	ml_task_hub:CurrentTask().latencyTimer = Now() + 500
end
----------------------------------------------------------------------------------------------------------------------------------------
ffxiv_task_interact = inheritsFrom(ml_task)
function ffxiv_task_interact.Create()
    local newinst = inheritsFrom(ffxiv_task_interact)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
   
	newinst.name = "LT_INTERACT"
	newinst.encounterData = {}
	newinst.failTimer = 0
	
	newinst.repositioned = false
	newinst.attarget = false
	newinst.latencyTimer = 0
	newinst.hasInteract = true
	newinst.isComplete = false
	newinst.maxTime = 0
	
    return newinst
end
----------------------------------------------------------------------------------------------------------------------------------------
function ffxiv_task_interact:Init()
	local ke_atInteract = ml_element:create( "AtInteract", c_dutyAtInteract, e_dutyAtInteract, 10 )
    self:add( ke_atInteract, self.process_elements)
	
	local ke_yesnoQuest = ml_element:create( "QuestYesNo", c_questyesno, e_questyesno, 6 )
    self:add(ke_yesnoQuest, self.process_elements)
	
    local ke_interact = ml_element:create( "Interact", c_interact, e_interact, 5 )
    self:add(ke_interact, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_interact:task_complete_eval()
	if (self.maxTime == 0) then
		if (self.encounterData.maxTime and self.encounterData.maxTime > 0) then
			self.maxTime = Now() + self.encounterData.maxTime
		else
			self.maxTime = Now() + 10000
		end
	end
	
	if (Player.castinginfo.channelingid == 24) then
		return false
	end
	
	if (Now() > self.maxTime) then
		return true
	end
	
	if (not ml_task_hub:CurrentTask().hasInteract and not self.isComplete) then
		self.isComplete = true
		if (self.encounterData.failTime and self.encounterData.failTime > 0) then
			self.failTimer = Now() + self.encounterData.failTime
		else
			self.failTimer = Now() + 1000
		end
		return false
	end
	
	-- If the task had started counting down, but is no longer failing, reset the state.
	if (not self.isComplete and self.failTimer ~= 0) then
		self.failTimer = 0
		return false
	end
	
	-- If the failTimer is not 0 (starting value) and we've exceeded the time, end the task.
	if (self.failTimer > 0 and Now() > self.failTimer) then
		return true
	end
	
	return false
end

function ffxiv_task_interact:task_complete_execute()
	self.completed = true
	self:ParentTask().encounterCompleted = true
end

--===================================================
--Loot Task
--===================================================
ffxiv_task_loot = inheritsFrom(ml_task)
function ffxiv_task_loot.Create()
    local newinst = inheritsFrom(ffxiv_task_loot)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
   
	newinst.name = "LT_LOOT"
	newinst.encounterData = {}
	newinst.failTimer = 0
	
	newinst.repositioned = false
	newinst.attarget = false
	newinst.latencyTimer = 0
	newinst.isComplete = false
	newinst.maxTime = 0
	
    return newinst
end
----------------------------------------------------------------------------------------------------------------------------------------
function ffxiv_task_loot:Init()
	local ke_atInteract = ml_element:create( "AtInteract", c_dutyAtInteract, e_dutyAtInteract, 10 )
    self:add( ke_atInteract, self.process_elements)
	
	local ke_yesnoQuest = ml_element:create( "QuestYesNo", c_questyesno, e_questyesno, 6 )
    self:add(ke_yesnoQuest, self.process_elements)
	
    local ke_interact = ml_element:create( "Interact", c_interact, e_interact, 5 )
    self:add(ke_interact, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_loot:task_complete_eval()
	if (self.maxTime == 0) then
		if (self.encounterData.maxTime and self.encounterData.maxTime > 0) then
			self.maxTime = Now() + self.encounterData.maxTime
		else
			self.maxTime = Now() + 10000
		end
	end
	
	if (Player.castinginfo.channelingid == 24) then
		return false
	end
	
	if (Now() > self.maxTime) then
		return true
	end
	
	if (Inventory:HasLoot()) then
		return true
	end
	
	return false
end

function ffxiv_task_loot:task_complete_execute()
	self.completed = true
	self:ParentTask().encounterCompleted = true
end


--Loot Roll task
c_roll = inheritsFrom( ml_cause )
e_roll = inheritsFrom( ml_effect )
function c_roll:evaluate()
	if (not Inventory:HasLoot()) then
		return false	
	end
	
	if (Now() < ml_task_hub:CurrentTask().latencyTimer) then
		return false
	end
	
	local loot = Inventory:GetLootList()
	if (loot and ml_task_hub:CurrentTask().rollstate ~= "Complete") then
		return true
	end
	
    return false
end
function e_roll:execute()
	ml_task_hub:CurrentTask().isComplete = false
	local loot = Inventory:GetLootList()
	if (loot) then
		if (not ControlVisible("NeedGreed")) then
			for i,e in pairs(loot) do
				if (ml_task_hub:CurrentTask().rollstate == "Need") then
					e:Need()
				elseif (ml_task_hub:CurrentTask().rollstate == "Greed") then
					e:Greed()
				else
					e:Pass()
				end
				ml_task_hub:CurrentTask().latencyTimer = Now() + 1000
				return
			end
		end
		
		if (ml_task_hub:CurrentTask().rollstate == "Need") then
			for i, e in pairs(loot) do 
				d("Attempting to need on loot, result was:"..tostring(e:Need()))
			end
			ml_task_hub:CurrentTask().latencyTimer = Now() + (150 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
			ml_task_hub:CurrentTask().rollstate = "Greed"
			return
		end
		
		if (ml_task_hub:CurrentTask().rollstate == "Greed") then
			for i, e in pairs(loot) do
				d("Attempting to greed on loot, result was:"..tostring(e:Greed()))			
			end
			ml_task_hub:CurrentTask().latencyTimer = Now() + (150 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
			ml_task_hub:CurrentTask().rollstate = "Pass"
			return
		end
		
		if (ml_task_hub:CurrentTask().rollstate == "Pass") then
			for i, e in pairs(loot) do
				d("Attempting to pass on loot, result was:"..tostring(e:Pass()))
			end
			ml_task_hub:CurrentTask().latencyTimer = Now()
			ml_task_hub:CurrentTask().rollstate = "Complete"
		end
	end
end


ffxiv_task_lootroll = inheritsFrom(ml_task)
function ffxiv_task_lootroll.Create()
    local newinst = inheritsFrom(ffxiv_task_lootroll)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
	newinst.encounterData = {}
   
    newinst.name = "LT_LOOTROLL"
	
	local startingStates = {
		["Need"] = "Need",
		["Greed"] = "Greed",
		["Pass"] = "Pass",
		["Any"] = "Need",
	}
	newinst.rollstate = startingStates[gLootOption]
	newinst.failTimer = 0
	newinst.isComplete = false
	newinst.latencyTimer = 0
	newinst.maxTime = 0
    
    return newinst
end

function ffxiv_task_lootroll:Init() 
	local ke_lootroll = ml_element:create( "Roll", c_roll, e_roll, 10 )
    self:add(ke_lootroll, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_lootroll:task_complete_eval()
	if (self.maxTime == 0) then
		self.maxTime = Now() + (2000 * ffxiv_task_duty.performanceLevels[gPerformanceLevel])
	end
	
	if (Now() > self.maxTime) then
		return true
	end
	
	if (not Inventory:HasLoot()) then
		return true
	end
	
	return false
end
function ffxiv_task_lootroll:task_complete_execute()
    self.completed = true
end


ffxiv_duty_task_exit = inheritsFrom(ml_task)
function ffxiv_duty_task_exit.Create()
	local newTask = ffxiv_task_movetointeract.Create()
	newTask.name = "DUTY_MOVETOEXIT"
	if (gTeleport == "1") then
		newTask.useTeleport = true
	end
	newTask.task_complete_execute = function()
		newTask.completed = true
		newTask:ParentTask().encounterCompleted = true
		newTask:ParentTask().state = "DUTY_EXIT"
		newTask:ParentTask().leaveTimer = Now() + 2000
	end
	newTask.encounterData = {}
	
	return newTask
end

ffxiv_duty_firecannon = inheritsFrom(ml_task)
ffxiv_duty_firecannon.name = "DUTY_FIRECANNON"
function ffxiv_duty_firecannon.Create()
    local newinst = inheritsFrom(ffxiv_duty_firecannon)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    newinst.name = "DUTY_FIRECANNON"
    
	newinst.shootPos = {}
	newinst.skillid = 0
	newinst.delayTime = 0
	newinst.cooldownTime = 0
	newinst.fireTimer = 0
	newinst.maxTimer = Now() + 15000
    
    return newinst
end

function ffxiv_duty_firecannon:Init()
	self:AddTaskCheckCEs()
end

function ffxiv_duty_firecannon:task_complete_eval()
	local tempvars = ffxiv_task_duty.tempvars
	if (tempvars["reactionprocesstime"]) then
		if (Now() < tempvars["reactionprocesstime"]) then
			d("[fireCannon]: Waiting on reaction processing.")
			return false
		else
			d("[fireCannon]: Found a process reaction time, but the time has elapsed.")
		end
	end
	
	if (ActionList:IsCasting() or Now() > self.maxTimer) then
		return true
	end
	
	local shootPos = self.shootPos
	local skillid = self.skillid
	
	if (self.fireTimer == 0 or Now() > self.fireTimer) then
		local misc = ActionList("type=1,level=0")
		if (ValidTable(misc)) then
			for i,skill in pairsByKeys(misc) do
				if (skill.id == skillid and skill.isready) then
					d("[fireCannon]: FIRING POSITION [X:"..tostring(shootPos.x).."][Y:"..tostring(shootPos.y).."][Z:"..tostring(shootPos.z).."]")
					if (skill:Cast(shootPos.x, shootPos.y, shootPos.z)) then
						self.fireTimer = Now() + 1000
						d("[fireCannon]: SHOTS FIRED.")
					end
				end
			end
		end
	end
	
	return false
end

function ffxiv_duty_firecannon:task_complete_execute()
	local tempvars = ffxiv_task_duty.tempvars
	local processlist = tempvars["cannonprocesslist"]
	
	local delayTime = self.delayTime
	local cdTime = self.cooldownTime
	tempvars["reactionprocesstime"] = Now() + delayTime
	processlist[self.cannonid] = {inprocess = false, blocked = (Now() + cdTime)}
	
	ml_task_hub:CurrentTask():ParentTask():SetDelay(delayTime)
    self.completed = true
end


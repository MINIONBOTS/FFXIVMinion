-- Skillmanager for adv. skill customization
SkillMgr = {}
SkillMgr.lastTick = 0
SkillMgr.profilePath = GetStartupPath() .. [[\LuaMods\ffxivminion\SkillManagerProfiles\]]
SkillMgr.defaultProfilePath = SkillMgr.profilePath .. [[Defaults\]]
SkillMgr.yield = {}
SkillMgr.monitor = {}
SkillMgr.gcdTime = 2.5

SkillMgr.ConditionList = {}
SkillMgr.CurrentSkill = {}
SkillMgr.CurrentSkillData = {}
SkillMgr.CurrentTarget = {}
SkillMgr.CurrentTID = 0
SkillMgr.CurrentPet = {}

SkillMgr.GUI = {
	skillbook = {
		name = GetString("Skill Book"),
		visible = true,
		open = false,
		height = 0, width = 350, x = 0, y = 0,
	},
	manager = {
		name = GetString("Skill Manager"),
		visible = true,
		open = false,
		height = 0, width = 0, x = 0, y = 0,
	},
	editor = {
		name = GetString("Skill Editor"),
		visible = true,
		open = false,
		height = 0, width = 350, x = 0, y = 0,
	},
	filters = {
		name = GetString("Skill Filters"),
		visible = true,
		open = false,
		height = 0, width = 0, x = 0, y = 0,
	},
}

SkillMgr.ClassJob = {
	[19] = 1,
	[20] = 2,
	[21] = 3,
	[22] = 4,
	[23] = 5,
	[24] = 6,
	[25] = 7,
	[27] = 26,
	[28] = 26,
	[30] = 29,
}

SkillMgr.SkillBook = {}
SkillMgr.lastBookUpdate = 0
SkillMgr.lastBookClass = 0
SkillMgr.lastGPStart = 0
SkillMgr.ProfileRaw = {}
SkillMgr.SkillProfile = {}
SkillMgr.EditingSkill = 0

SkillMgr.lastQueued = 0
SkillMgr.queuedPrio = 0
SkillMgr.currentChain = ""
SkillMgr.prevSkillID = ""
SkillMgr.prevGatherSkillID = ""
SkillMgr.prevSkillTimestamp = 0
SkillMgr.prevGCDSkillID = ""
SkillMgr.prevSkillList = {}
SkillMgr.pathMark = ""
SkillMgr.tempPrevSkillList = {}
SkillMgr.nextSkillID = ""
SkillMgr.nextSkillPrio = ""
SkillMgr.failTimer = 0
SkillMgr.teleCastTimer = 0
SkillMgr.teleBack = {}
SkillMgr.copiedSkill = {}
SkillMgr.bestAOE = 0
SkillMgr.MacroThrottle = 0
SkillMgr.recoverTarget = {}

SkillMgr.highestRange = 0
SkillMgr.highestRangeSkills = {}

SkillMgr.actionWatch = {}
SkillMgr.actionWatchResult = false

SkillMgr.lastCast = 0
SkillMgr.lastCastUnique = 0
SkillMgr.throw = {}

SkillMgr.profiles = {}

SkillMgr.latencyTimer = 0
SkillMgr.forceStop = false
SkillMgr.preCombat = false
SkillMgr.knownDebuffs = "1,3,4,5,6,7,9,10,14,15,17,18,19,20,26,28,30,32,34,36,38,54,55,58,59,62,67,181,19​3,210,213,215,216,240,250,267,275,280,284,268,285,235,269,270,271,272,273,283,28​6,287,288,320,339,343,407,442,48​2,485,503,509,530,532,533,534,535,559,560,561,5​64,569,571,605,610,619,620,642,643,666,677,686,723,785,801,893,910,926"
SkillMgr.doLoad = true

SkillMgr.StartingProfiles = {
	[FFXIV.JOBS.GLADIATOR] = "Paladin_SHB",
	[FFXIV.JOBS.PALADIN] = "Paladin_SHB",
	[FFXIV.JOBS.MARAUDER] = "Warrior_SHB",
	[FFXIV.JOBS.WARRIOR] = "Warrior_SHB",
	[FFXIV.JOBS.PUGILIST] = "Monk",
	[FFXIV.JOBS.MONK] = "Monk",
	[FFXIV.JOBS.LANCER] = "Dragoon_SHB",
	[FFXIV.JOBS.DRAGOON] = "Dragoon_SHB",
	[FFXIV.JOBS.ARCHER] = "Bard_SHB",
	[FFXIV.JOBS.BARD] = "Bard_SHB",
	[FFXIV.JOBS.CONJURER] = "Whitemage_SHB",
	[FFXIV.JOBS.WHITEMAGE] = "Whitemage_SHB",
	[FFXIV.JOBS.THAUMATURGE] = "Blackmage_SHB",
	[FFXIV.JOBS.BLACKMAGE] = "Blackmage_SHB",
	[FFXIV.JOBS.ARCANIST] = "Summoner_SHB",
	[FFXIV.JOBS.SUMMONER] = "Summoner_SHB",
	[FFXIV.JOBS.SCHOLAR] = "Scholar_SHB",
	[FFXIV.JOBS.BOTANIST] = "Gathering_Leveling",
	[FFXIV.JOBS.MINER] = "Gathering_Leveling",
	[FFXIV.JOBS.ROGUE] = "Ninja52",
	[FFXIV.JOBS.NINJA] = "Ninja52",
	[FFXIV.JOBS.MACHINIST] = "Machinist_SHB",
	[FFXIV.JOBS.ASTROLOGIAN] = "Astrologian_SHB",
	[FFXIV.JOBS.DARKKNIGHT] = "DarkKnight_SHB",
	[FFXIV.JOBS.SAMURAI] = "Samurai_SHB",
	[FFXIV.JOBS.REDMAGE] = "Redmage_SHB",
	[FFXIV.JOBS.BLUEMAGE] = "BlueMage",
	[FFXIV.JOBS.DANCER] = "Dancer",
	[FFXIV.JOBS.GUNBREAKER] = "Gunbreaker",
	
	[39] = "Reaper",
	[40] = "Sage",
}

SkillMgr.ExtraProfiles = {
	"Aetherial_Gathering",
	"Gathering_Multi",
	"Gathering_530",
	"Gathering_Clusters",
	"Gathering_Collectables",
	"Gathering_Collectables_2",
	"Gathering_Crystals",
	"Gathering_Custom",
	"Gathering_Favors",
	"Gathering_SB_3_Swings",
	"Gathering_SB_4_Swings",
	"Gathering_HQ",
	"Gathering_Leveling",
	"Gathering_Scrips",	
	"Gathering_Shards",	
	"Custom_Task",
	"Aetherial_Gathering_SHB",
	
	"[Craft] Leveling",
	"[Craft] 30+ 1 Skill Complete",
	"[Craft] 70+ 1 Skill Complete",
	
	"[Craft] 30+ 2 Skill Complete",
	"[Craft] 70+ 2 Skill Complete",
	"Ninja52",
}

SkillMgr.lastCheckDetails = {}
SkillMgr.lastCheckTime = 0
function SkillMgr.CheckTestSkill(jobid, target, pvp)
	local jobid = IsNull(jobid,Player.job)
	local pvp = IsNull(pvp,false)
	if (not target) then
		return false
	end
	
	local targetid = target.id
	
	local testSkills = {}
	if (not pvp) then
		testSkills = {
			[FFXIV.JOBS.GLADIATOR] = 9,
			[FFXIV.JOBS.PALADIN] = 9,
			[FFXIV.JOBS.MARAUDER] = 31,
			[FFXIV.JOBS.WARRIOR] = 31,
			[FFXIV.JOBS.PUGILIST] = 53,
			[FFXIV.JOBS.MONK] = 53,
			[FFXIV.JOBS.LANCER] = 75,
			[FFXIV.JOBS.DRAGOON] = 75,
			[FFXIV.JOBS.ARCHER] = {98, 97},
			[FFXIV.JOBS.BARD] = {98, 97},
			[FFXIV.JOBS.CONJURER] = { 132, 127, 121, 119 },
			[FFXIV.JOBS.WHITEMAGE] = { 7431, 3568, 132, 127, 121, 119 },
			[FFXIV.JOBS.THAUMATURGE] = {156, 142},
			[FFXIV.JOBS.BLACKMAGE] = {156, 142},
			[FFXIV.JOBS.ARCANIST] = {178, 164, 163},
			[FFXIV.JOBS.SUMMONER] = { 7424, 3579, 178, 164, 163 },
			[FFXIV.JOBS.SCHOLAR] = { 7435, 3584, 178, 164, 163},
			[FFXIV.JOBS.BOTANIST] = 218,
			[FFXIV.JOBS.MINER] = 235,
			[FFXIV.JOBS.ROGUE] = 2240,
			[FFXIV.JOBS.NINJA] = 2240,
			[FFXIV.JOBS.MACHINIST] = { 7411, 2866 },
			[FFXIV.JOBS.ASTROLOGIAN] = { 7442, 3598, 3596 },
			[FFXIV.JOBS.DARKKNIGHT] = 3617,
			[FFXIV.JOBS.SAMURAI] = 7477,
			[FFXIV.JOBS.REDMAGE] = { 7503, 7504 },
			[FFXIV.JOBS.BLUEMAGE] = 11385,
			[FFXIV.JOBS.DANCER] = 15989,
			[FFXIV.JOBS.GUNBREAKER] = 16137,
		}
	else
		testSkills = {
			[FFXIV.JOBS.GLADIATOR] = 8718,
			[FFXIV.JOBS.PALADIN] = 8718,
			[FFXIV.JOBS.MARAUDER] = 8758,
			[FFXIV.JOBS.WARRIOR] = 8758,
			[FFXIV.JOBS.PUGILIST] = 8780,
			[FFXIV.JOBS.MONK] = 8780,
			[FFXIV.JOBS.LANCER] = 8791,
			[FFXIV.JOBS.DRAGOON] = 8791,
			[FFXIV.JOBS.ARCHER] = 8834,
			[FFXIV.JOBS.BARD] = 8834,
			[FFXIV.JOBS.CONJURER] = 8895,
			[FFXIV.JOBS.WHITEMAGE] = 8895,
			[FFXIV.JOBS.THAUMATURGE] = 8858,
			[FFXIV.JOBS.BLACKMAGE] = 8858,
			[FFXIV.JOBS.ARCANIST] = 8904,
			[FFXIV.JOBS.SUMMONER] = 8872,
			[FFXIV.JOBS.SCHOLAR] = 8904,
			[FFXIV.JOBS.ROGUE] = 8807,
			[FFXIV.JOBS.NINJA] = 8807,
			[FFXIV.JOBS.MACHINIST] = 8845,
			[FFXIV.JOBS.ASTROLOGIAN] = 8912,
			[FFXIV.JOBS.DARKKNIGHT] = 8769,
			[FFXIV.JOBS.SAMURAI] = 8821,
			[FFXIV.JOBS.REDMAGE] = 8882,
			[FFXIV.JOBS.DANCER] = 17756,
			[FFXIV.JOBS.GUNBREAKER] = 17703,
			[39] = 24373,
			[40] = 24283,
		}
	end
	
	local testSkill = testSkills[Player.job]
	if (testSkill) then
		if (type(testSkill) == "number") then
			local action = ActionList:Get(1,testSkill)
			if (action and (action:IsReady(targetid) or (target.distance2d < action.range and target.los))) then
				SkillMgr.lastCheckDetails = {
					tpos = target.pos,
					ppos = Player.pos,
				}
				SkillMgr.lastCheckTime = Now()
				return true
			elseif (action and action.usable and not action.isoncd and not action:IsReady(targetid)) then
				return false
			end	
		elseif (type(testSkill) == "table") then
			local found = false
			for i = 1,table.size(testSkill) do
				local action = ActionList:Get(1,testSkill[i])
				if (action and (action:IsReady(targetid) or (target.distance2d < action.range and target.los))) then
					SkillMgr.lastCheckDetails = {
						tpos = target.pos,
						ppos = Player.pos,
					}
					SkillMgr.lastCheckTime = Now()
					return true
				elseif (action and action.usable and not action.isoncd and not action:IsReady(targetid)) then
					found = true
				end	
			end
			if (found) then
				return false
			end
		end
	end
	
	if (TimeSince(SkillMgr.lastCheckTime) < 3000 and table.valid(SkillMgr.lastCheckDetails) and table.valid(SkillMgr.lastCheckDetails.tpos) and table.valid(SkillMgr.lastCheckDetails.ppos)) then
		local details = SkillMgr.lastCheckDetails
		if (math.distance3d(Player.pos,details.ppos) < 1 and math.distance3d(target.pos,details.tpos) < 1) then
			return true
		else
			d("target or player has moved too far, cannot equivocate")
		end
	end
			
	return nil
end

function SkillMgr.UpdateBasicSkills()
	SkillMgr.GCDSkills = {
		[FFXIV.JOBS.GLADIATOR] = 9,
		[FFXIV.JOBS.PALADIN] = 9,
		[FFXIV.JOBS.MARAUDER] = 31,
		[FFXIV.JOBS.WARRIOR] = 31,
		[FFXIV.JOBS.PUGILIST] = 53,
		[FFXIV.JOBS.MONK] = 53,
		[FFXIV.JOBS.LANCER] = 75,
		[FFXIV.JOBS.DRAGOON] = 75,
		[FFXIV.JOBS.ARCHER] = 97,
		[FFXIV.JOBS.BARD] = 97,
		[FFXIV.JOBS.CONJURER] = 119,
		[FFXIV.JOBS.WHITEMAGE] = 119,
		[FFXIV.JOBS.THAUMATURGE] = 142,
		[FFXIV.JOBS.BLACKMAGE] = 142,
		[FFXIV.JOBS.ARCANIST] = 163,
		[FFXIV.JOBS.SUMMONER] = 163,
		[FFXIV.JOBS.SCHOLAR] = 163,
		[FFXIV.JOBS.BOTANIST] = 218,
		[FFXIV.JOBS.MINER] = 235,
		[FFXIV.JOBS.ROGUE] = 2240,
		[FFXIV.JOBS.NINJA] = 2240,
		[FFXIV.JOBS.MACHINIST] = 2866,
		[FFXIV.JOBS.ASTROLOGIAN] = 3596,
		[FFXIV.JOBS.DARKKNIGHT] = 3617,
		[FFXIV.JOBS.SAMURAI] = 7477,
		[FFXIV.JOBS.REDMAGE] = IIF(Player.level > 1,7503,7504),
		[FFXIV.JOBS.BLUEMAGE] = 11385,
		[FFXIV.JOBS.DANCER] = 15989,
		[FFXIV.JOBS.GUNBREAKER] = 16137,
		[39] = 24373,
		[40] = 24283,
	}
	
	SkillMgr.GCDSkillsPVP = {
		[FFXIV.JOBS.GLADIATOR] = 8718,
		[FFXIV.JOBS.PALADIN] = 8718,
		[FFXIV.JOBS.MARAUDER] = 8758,
		[FFXIV.JOBS.WARRIOR] = 8758,
		[FFXIV.JOBS.PUGILIST] = 8780,
		[FFXIV.JOBS.MONK] = 8780,
		[FFXIV.JOBS.LANCER] = 8791,
		[FFXIV.JOBS.DRAGOON] = 8791,
		[FFXIV.JOBS.ARCHER] = 8834,
		[FFXIV.JOBS.BARD] = 8834,
		[FFXIV.JOBS.CONJURER] = 8895,
		[FFXIV.JOBS.WHITEMAGE] = 8895,
		[FFXIV.JOBS.THAUMATURGE] = 8858,
		[FFXIV.JOBS.BLACKMAGE] = 8858,
		[FFXIV.JOBS.ARCANIST] = 8904,
		[FFXIV.JOBS.SUMMONER] = 8872,
		[FFXIV.JOBS.SCHOLAR] = 8904,
		[FFXIV.JOBS.ROGUE] = 8807,
		[FFXIV.JOBS.NINJA] = 8807,
		[FFXIV.JOBS.MACHINIST] = 8845,
		[FFXIV.JOBS.ASTROLOGIAN] = 8912,
		[FFXIV.JOBS.DARKKNIGHT] = 8769,
		[FFXIV.JOBS.SAMURAI] = 8821,
		[FFXIV.JOBS.REDMAGE] = 8882,
		[FFXIV.JOBS.DANCER] = 17756,
		[FFXIV.JOBS.GUNBREAKER] = 17703,
	}
end

function SkillMgr.UpdateDefaultProfiles()
	-- Strip default field values for reading clarity.
	local profileList = FolderList(SkillMgr.defaultProfilePath,[[(.*)lua$]])
    if (table.valid(profileList)) then		
		for i,profile in pairs(profileList) do
			local defaultFileData = persistence.load(profile)
			if (defaultFileData) then
				if (table.valid(defaultFileData.skills)) then
					local fieldDefaults = {}
					for fieldid, defaults in pairs(SkillMgr.Variables) do
						fieldDefaults[defaults.profile] = defaults.default
					end
					
					local requiredUpdate = false
					for prio,skill in pairs(defaultFileData.skills) do
						for field,fieldvalue in pairs(skill) do
							if (fieldvalue == fieldDefaults[field] or fieldDefaults[field] == nil) then
								defaultFileData.skills[prio][field] = nil
								requiredUpdate = true
							end
						end
					end
					if (requiredUpdate) then
						persistence.store(defaultPath, defaultFileData)
						--d("Updated default profile ["..tostring(profile).."].")
					end
				end
            end
        end	
    end

	for _,profile in pairs(SkillMgr.StartingProfiles) do
		local filePath = SkillMgr.profilePath..profile..".lua"
		local defaultPath = SkillMgr.defaultProfilePath..profile..".lua"
		if FileExists(defaultPath) then
			local defaultFileData = persistence.load(defaultPath)
			if (defaultFileData) then
				local currentFileData = persistence.load(filePath)
				if (not FileExists(filePath)) then
					persistence.store(filePath, defaultFileData)
				elseif IsNull(defaultFileData.update,0) > IsNull(currentFileData.update,0) then
					persistence.store(filePath, defaultFileData)
					d("Updated Profile ".. tostring(profile) .. " to version " ..tostring(defaultFileData.update))
				end
			end
		end
	end
	
	for _,profile in pairs(SkillMgr.ExtraProfiles) do
		local filePath = SkillMgr.profilePath..profile..".lua"
		local defaultPath = SkillMgr.defaultProfilePath..profile..".lua"
		if FileExists(defaultPath) then
			local defaultFileData = persistence.load(defaultPath)
			if (defaultFileData) then
				local currentFileData = persistence.load(filePath)
				if (not FileExists(filePath)) then
					persistence.store(filePath, defaultFileData)
				elseif IsNull(defaultFileData.update,0) > IsNull(currentFileData.update,0) then
					persistence.store(filePath, defaultFileData)
					d("Updated Profile ".. tostring(profile) .. " to version " ..tostring(defaultFileData.update))
				end
			end
		end
	end
end

SkillMgr.ActionTypes = {
	ACTIONS = 1,
	CRAFT = 9,
	PET = 11,
}

SkillMgr.Variables = {
	SKM_NAME = { default = "", cast = "string", profile = "name", readable = "", section = "main"},
	SKM_ALIAS = { default = "", cast = "string", profile = "alias", readable = "", section = "main"},
	SKM_ID = { default = 0, cast = "number", profile = "id", readable = "", section = "main"},
	SKM_TYPE = { default = 1, cast = "number", profile = "type", readable = "", section = "main", useData = "type" },
	SKM_ON = { default = true, cast = "boolean", profile = "used", readable = "", section = "main"},
	SKM_Prio = { default = 0, cast = "number", profile = "prio", readable = "", section = "main"},
	
	SKM_STYPE = { default = "Action", cast = "string", profile = "stype", readable = "", section = "fighting", group = ""},
	SKM_CHARGE = { default = false, cast = "boolean", profile = "charge", readable = "", section = "fighting", group = "" },
	SKM_DOBUFF = { default = false, cast = "boolean", profile = "dobuff", readable = "", section = "fighting", group = "" },
	SKM_REMOVESBUFF = { default = false, cast = "boolean", profile = "removebuff", readable = "", section = "fighting", group = "" },
	SKM_DOPREV = { default = false, cast = "boolean", profile = "doprev", readable = "", section = "fighting", group = ""  },
	SKM_LevelMin = { default = 0, cast = "number", profile = "levelmin", readable = "", section = "fighting", group = "", useData = "level" },
	SKM_LevelMax = { default = 0, cast = "number", profile = "levelmax", readable = "", section = "fighting", group = ""   },
	SKM_Combat = { default = "In Combat", cast = "string", profile = "combat", readable = "", section = "fighting", group = ""  },
	SKM_PVEPVP = { default = "Both", cast = "string", profile = "pvepvp", readable = "", section = "fighting", group = "" },
	SKM_OnlySolo = { default = false, cast = "boolean", profile = "onlysolo", readable = "", section = "fighting", group = ""  },
	SKM_OnlyParty = { default = false, cast = "boolean", profile = "onlyparty", readable = "", section = "fighting", group = ""  },
	SKM_PartySizeLT = { default = 0, cast = "number", profile = "partysizelt", readable = "", section = "fighting", group = ""  },
	SKM_FilterOne = { default = GetString("Ignore"), cast = "string", profile = "filterone", readable = "", section = "fighting", group = ""  },
	SKM_FilterTwo = { default = GetString("Ignore"), cast = "string", profile = "filtertwo", section = "fighting", group = ""  },
	SKM_FilterThree = { default = GetString("Ignore"), cast = "string", profile = "filterthree", readable = "", section = "fighting", group = ""  },
	SKM_FilterFour = { default = GetString("Ignore"), cast = "string", profile = "filterfour", readable = "", section = "fighting", group = ""  },
	SKM_FilterFive = { default = GetString("Ignore"), cast = "string", profile = "filterfive", readable = "", section = "fighting", group = ""  },
	SKM_ComboSkill = { default = GetString("Auto"), cast = "string", profile = "comboskill", readable = "", section = "fighting", group = ""  },
	--SKM_MPLock = { default = false, cast = "boolean", profile = "mplock", section = "fighting" },
	--SKM_MPLocked = { default = false, cast = "boolean", profile = "mplocked", section = "fighting" },
	--SKM_MPLockPer = { default = 0, cast = "number", profile = "mplockper", section = "fighting" },
	SKM_TRG = { default = GetString("Target"), cast = "string", profile = "trg", readable = "", section = "fighting", group = ""  },
	SKM_TRGTYPE = { default = GetString("Any"), cast = "string", profile = "trgtype", readable = "", section = "fighting", group = ""  },
	SKM_TRGSELF = { default = false, cast = "boolean", profile = "trgself", readable = "", section = "fighting", group = "" },
	SKM_NPC = { default = false, cast = "boolean", profile = "npc", readable = "", section = "fighting", group = ""  },
	SKM_PTRG = { default = GetString("Any"), cast = "string", profile = "ptrg", readable = "", section = "fighting", group = "" },
	SKM_PGTRG = { default = GetString("Direct"), cast = "string", profile = "pgtrg", readable = "", section = "fighting", group = ""  },
	SKM_HPRIOHP = { default = 0, cast = "number", profile = "hpriohp", readable = "", section = "fighting", group = ""  },
	SKM_HPRIO1 = { default = GetString("none"), cast = "string", profile = "hprio1", readable = "", section = "fighting", group = ""  },
	SKM_HPRIO2 = { default = GetString("none"), cast = "string", profile = "hprio2", readable = "", section = "fighting", group = ""  },
	SKM_HPRIO3 = { default = GetString("none"), cast = "string", profile = "hprio3", readable = "", section = "fighting", group = ""  },
	SKM_HPRIO4 = { default = GetString("none"), cast = "string", profile = "hprio4", readable = "", section = "fighting", group = ""  },
	SKM_MinR = { default = 0, cast = "number", profile = "minRange", readable = "", section = "fighting", group = ""  },
	SKM_MaxR = { default = 24, cast = "number", profile = "maxRange", readable = "", section = "fighting", group = "", useData = "range" },
	SKM_PHPL = { default = 0, cast = "number", profile = "phpl", readable = "", section = "fighting", group = ""   },
	SKM_PHPB = { default = 0, cast = "number", profile = "phpb", readable = "", section = "fighting", group = ""   },
	SKM_PUnderAttack = { default = false, cast = "boolean", profile = "punderattack", readable = "", section = "fighting", group = ""  },
	SKM_PUnderAttackMelee = { default = false, cast = "boolean", profile = "punderattackmelee", readable = "", section = "fighting", group = ""  },
	SKM_PPowL = { default = 0, cast = "number", profile = "ppowl", readable = "", section = "fighting", group = ""   },
	SKM_PPowB = { default = 0, cast = "number", profile = "ppowb", readable = "", section = "fighting", group = ""   },
	SKM_PMPPL = { default = 0, cast = "number", profile = "pmppl", readable = "", section = "fighting", group = ""   },
	SKM_PMPPB = { default = 0, cast = "number", profile = "pmppb", readable = "", section = "fighting", group = ""   },
	
	SKM_PMPRGT = { default = 0, cast = "number", profile = "pmprgt", readable = "", section = "fighting", group = ""  },
	SKM_PMPRLT = { default = 0, cast = "number", profile = "pmprlt", readable = "", section = "fighting", group = ""   },
	SKM_PMPPRGT = { default = 0, cast = "number", profile = "pmpprgt", readable = "", section = "fighting", group = ""   },
	SKM_PMPPRLT = { default = 0, cast = "number", profile = "pmpprlt", readable = "", section = "fighting", group = ""   },
	SKM_PMPRSGT = { default = "", cast = "string", profile = "pmprsgt", readable = "", section = "fighting", group = ""   },
	SKM_PMPRSLT = { default = "", cast = "string", profile = "pmprslt", readable = "", section = "fighting", group = ""   },
	
	SKM_PTPL = { default = 0, cast = "number", profile = "ptpl", readable = "", section = "fighting", group = ""  },
	SKM_PTPB = { default = 0, cast = "number", profile = "ptpb", readable = "", section = "fighting", group = ""  },
	SKM_THPL = { default = 0, cast = "number", profile = "thpl", readable = "", section = "fighting", group = ""  },
	SKM_THPB = { default = 0, cast = "number", profile = "thpb", readable = "", section = "fighting", group = ""  },
	SKM_THPADV = { default = 0, cast = "number", profile = "thpadv", readable = "", section = "fighting", group = ""  },
	SKM_TTPL = { default = 0, cast = "number", profile = "ttpl", readable = "", section = "fighting", group = ""  },
	SKM_TMPL = { default = 0, cast = "number", profile = "tmpl", readable = "", section = "fighting", group = ""  },
	SKM_PTCount = { default = 0, cast = "number", profile = "ptcount", readable = "", section = "fighting", group = ""   },
	SKM_PTHPL = { default = 0, cast = "number", profile = "pthpl", readable = "", section = "fighting", group = ""   },
	SKM_PTHPB = { default = 0, cast = "number", profile = "pthpb", readable = "", section = "fighting", group = ""   },
	SKM_PTMPL = { default = 0, cast = "number", profile = "ptmpl", readable = "", section = "fighting", group = ""   },
	SKM_PTMPB = { default = 0, cast = "number", profile = "ptmpb", readable = "", section = "fighting", group = ""   },
	SKM_PTTPL = { default = 0, cast = "number", profile = "pttpl", readable = "", section = "fighting" , group = ""  },
	SKM_PTTPB = { default = 0, cast = "number", profile = "pttpb", readable = "", section = "fighting", group = ""   },
	SKM_PTBuff = { default = "", cast = "string", profile = "ptbuff", readable = "", section = "fighting", group = ""  },
	SKM_PTKBuff = { default = false, cast = "boolean", profile = "ptkbuff", readable = "", section = "fighting", group = ""  },
	SKM_PTNBuff = { default = "", cast = "string", profile = "ptnbuff", readable = "", section = "fighting", group = ""  },
	SKM_THPCL = { default = 0, cast = "number", profile = "thpcl", readable = "", section = "fighting", group = ""   },
	SKM_THPCB = { default = 0, cast = "number", profile = "thpcb", readable = "", section = "fighting", group = ""   },
	SKM_TCONTIDS = { default = "", cast = "string", profile = "tcontids", readable = "", section = "fighting", group = ""  },
	SKM_TNCONTIDS = { default = "", cast = "string", profile = "tncontids", readable = "", section = "fighting", group = ""  },
	SKM_TCASTID = { default = "", cast = "string", profile = "tcastids", readable = "", section = "fighting", group = ""  },
	SKM_TCASTTM = { default = false, cast = "boolean", profile = "tcastonme", readable = "", section = "fighting", group = ""  },
	SKM_TCASTTIME = { default = "0.0", cast = "string", profile = "tcasttime", readable = "", section = "fighting", group = ""  },
	SKM_TECount = { default = 0, cast = "number", profile = "tecount", readable = "", section = "fighting", group = ""   },
	SKM_TECount2 = { default = 0, cast = "number", profile = "tecount2", readable = "", section = "fighting", group = ""   },
	
	SKM_EnmityAOE = { default = false, cast = "boolean", profile = "enmityaoe", readable = "", section = "fighting", group = ""   },
	SKM_FrontalConeAOE = { default = false, cast = "boolean", profile = "frontalconeaoe", readable = "", section = "fighting", group = ""   },
	SKM_TankedOnly = { default = false, cast = "boolean", profile = "tankedonlyaoe", readable = "", section = "fighting", group = ""   },
	SKM_TEHPAvgGT = { default = 0, cast = "number", profile = "tehpavggt", readable = "", section = "fighting", group = ""   },
	
	SKM_TERange = { default = 0, cast = "number", profile = "terange", readable = "", section = "fighting", group = "" , useData = "radius" },
	SKM_TECenter = { default = GetString("Auto"), cast = "string", profile = "tecenter", readable = "", section = "fighting", group = ""  },
	SKM_TELevel = { default = GetString("Any"), cast = "string", profile = "televel", readable = "", section = "fighting", group = ""  },
	SKM_TACount = { default = 0, cast = "number", profile = "tacount", readable = "", section = "fighting", group = ""   },
	SKM_TARange = { default = 0, cast = "number", profile = "tarange", readable = "", section = "fighting", group = "", useData = "radius" },
	SKM_TAHPL = { default = 0, cast = "number", profile = "tahpl", readable = "", section = "fighting", group = ""   },
	SKM_PBuff = { default = "", cast = "string", profile = "pbuff", readable = "", section = "fighting", group = ""  },
	SKM_PBuffDura = { default = 0, cast = "number", profile = "pbuffdura", readable = "", section = "fighting", group = "" },
	SKM_PNBuff = { default = "", cast = "string", profile = "pnbuff", readable = "", section = "fighting", group = ""  },
	SKM_PNBuffDura = { default = 0, cast = "number", profile = "pnbuffdura", readable = "", section = "fighting", group = ""   },
	
	SKM_TBuffOwner = { default = GetString("Player"), cast = "string", profile = "tbuffowner", readable = "", section = "fighting", group = ""  },
	SKM_TBuff = { default = "", cast = "string", profile = "tbuff", readable = "", section = "fighting", group = ""  },
	SKM_TBuffDura = { default = 0, cast = "number", profile = "tbuffdura", readable = "", section = "fighting", group = ""   },
	SKM_TNBuffOwner = { default = GetString("Player"), cast = "string", profile = "tnbuffowner", readable = "", section = "fighting", group = ""  },
	SKM_TNBuff = { default = "", cast = "string", profile = "tnbuff", readable = "", section = "fighting", group = ""  },
	SKM_TNBuffDura = { default = 0, cast = "number", profile = "tnbuffdura", readable = "", section = "fighting", group = ""   },
	
	SKM_PetBuff = { default = "", cast = "string", profile = "petbuff", readable = "", section = "fighting", group = ""  },
	SKM_PetBuffDura = { default = 0, cast = "number", profile = "petbuffdura", readable = "", section = "fighting", group = "" },
	SKM_PetNBuff = { default = "", cast = "string", profile = "petnbuff", readable = "", section = "fighting", group = ""  },
	SKM_PetNBuffDura = { default = 0, cast = "number", profile = "petnbuffdura", readable = "", section = "fighting", group = ""   },
	
	SKM_PSkillID = { default = "", cast = "string", profile = "pskill", readable = "", section = "fighting", group = ""  },
	SKM_NPSkillID = { default = "", cast = "string", profile = "npskill", readable = "", section = "fighting", group = ""  },
	SKM_PCSkillID = { default = "", cast = "string", profile = "pcskill", readable = "", section = "fighting", group = ""  },
	SKM_NPCSkillID = { default = "", cast = "string", profile = "npcskill", readable = "", section = "fighting", group = ""  },
	SKM_PGSkillID = { default = "", cast = "string", profile = "pgskill", readable = "", section = "fighting", group = ""  },
	SKM_NPGSkillID = { default = "", cast = "string", profile = "npgskill", readable = "", section = "fighting", group = ""  },
	--SKM_NSkillID = { default = "", cast = "string", profile = "nskill", section = "fighting"  },
	--SKM_NSkillPrio = { default = "", cast = "string", profile = "nskillprio", section = "fighting"  },
	
	SKM_SecsPassed = { default = 0, cast = "number", profile = "secspassed", readable = "", section = "fighting", group = ""   },
	SKM_SecsPassedUnique = { default = 0, cast = "number", profile = "secspassedu", readable = "", section = "fighting", group = ""   },
	SKM_PPos = { default = GetString("none"), cast = "string", profile = "ppos", readable = "", section = "fighting", group = "" },
	SKM_OffGCD = { default = GetString("Auto"), cast = "string", profile = "gcd", readable = "", section = "fighting", group = "" },
	SKM_OffGCDTime = { default = 1.5, cast = "number", profile = "gcdtime", readable = "", section = "fighting", group = "" },
	SKM_OffGCDTimeLT = { default = 2.5, cast = "number", profile = "gcdtimelt", readable = "", section = "fighting", group = "" },
	
	SKM_SKREADY = { default = "", cast = "string", profile = "skready", readable = "", section = "fighting", group = "" },
	SKM_SKOFFCD = { default = "", cast = "string", profile = "skoffcd", readable = "", section = "fighting", group = "" },
	SKM_SKNREADY = { default = "", cast = "string", profile = "sknready", readable = "", section = "fighting", group = "" },
	SKM_SKNOFFCD = { default = "", cast = "string", profile = "sknoffcd", readable = "", section = "fighting", group = "" },
	SKM_SKNCDTIMEMIN = { default = 0, cast = "number", profile = "skncdtimemin", readable = "", section = "fighting", group = "" },
	SKM_SKNCDTIMEMAX = { default = 0, cast = "number", profile = "skncdtimemax", readable = "", section = "fighting", group = "" },
	SKM_SKTYPE = { default = "Action", cast = "string", profile = "sktype", readable = "", section = "fighting", group = ""},
	SKM_NCURRENTACTION = { default = "", cast = "string", profile = "ncurrentaction", readable = "", section = "fighting", group = "" },
	
	SKM_CHAINSTART = { default = false, cast = "boolean", profile = "chainstart", readable = "", section = "fighting", group = "" },
	SKM_CHAINNAME = { default = "", cast = "string", profile = "chainname", readable = "", section = "fighting", group = "" },
	SKM_CHAINEND = { default = false, cast = "boolean", profile = "chainend", readable = "", section = "fighting", group = "" },
	
	SKM_GAUGE1LT = { default = 0, cast = "number", profile = "gauge1lt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE1GT = { default = 0, cast = "number", profile = "gauge1gt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE1EQ = { default = 0, cast = "number", profile = "gauge1eq", readable = "", section = "fighting", group = "" },
	SKM_GAUGE1OR = { default = "", cast = "string", profile = "gauge1or", readable = "", section = "fighting", group = "" },
	
	SKM_GAUGE2LT = { default = 0, cast = "number", profile = "gauge2lt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE2GT = { default = 0, cast = "number", profile = "gauge2gt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE2EQ = { default = 0, cast = "number", profile = "gauge2eq", readable = "", section = "fighting", group = "" },
	SKM_GAUGE2OR = { default = "", cast = "string", profile = "gauge2or", readable = "", section = "fighting", group = "" },
	
	SKM_GAUGE3LT = { default = 0, cast = "number", profile = "gauge3lt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE3GT = { default = 0, cast = "number", profile = "gauge3gt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE3EQ = { default = 0, cast = "number", profile = "gauge3eq", readable = "", section = "fighting", group = "" },
	SKM_GAUGE3OR = { default = "", cast = "string", profile = "gauge3or", readable = "", section = "fighting", group = "" },
	
	SKM_GAUGE4LT = { default = 0, cast = "number", profile = "gauge4lt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE4GT = { default = 0, cast = "number", profile = "gauge4gt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE4EQ = { default = 0, cast = "number", profile = "gauge4eq", readable = "", section = "fighting", group = "" },
	SKM_GAUGE4OR = { default = "", cast = "string", profile = "gauge4or", readable = "", section = "fighting", group = "" },
	
	SKM_GAUGE5LT = { default = 0, cast = "number", profile = "gauge5lt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE5GT = { default = 0, cast = "number", profile = "gauge5gt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE5EQ = { default = 0, cast = "number", profile = "gauge5eq", readable = "", section = "fighting", group = "" },
	SKM_GAUGE5OR = { default = "", cast = "string", profile = "gauge5or", readable = "", section = "fighting", group = "" },
	
	SKM_GAUGE6LT = { default = 0, cast = "number", profile = "gauge6lt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE6GT = { default = 0, cast = "number", profile = "gauge6gt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE6EQ = { default = 0, cast = "number", profile = "gauge6eq", readable = "", section = "fighting", group = "" },
	SKM_GAUGE6OR = { default = "", cast = "string", profile = "gauge6or", readable = "", section = "fighting", group = "" },
	
	SKM_GAUGE7LT = { default = 0, cast = "number", profile = "gauge7lt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE7GT = { default = 0, cast = "number", profile = "gauge7gt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE7EQ = { default = 0, cast = "number", profile = "gauge7eq", readable = "", section = "fighting", group = "" },
	SKM_GAUGE7OR = { default = "", cast = "string", profile = "gauge7or", readable = "", section = "fighting", group = "" },
	
	SKM_GAUGE8LT = { default = 0, cast = "number", profile = "gauge8lt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE8GT = { default = 0, cast = "number", profile = "gauge8gt", readable = "", section = "fighting", group = "" },
	SKM_GAUGE8EQ = { default = 0, cast = "number", profile = "gauge8eq", readable = "", section = "fighting", group = "" },
	SKM_GAUGE8OR = { default = "", cast = "string", profile = "gauge8or", readable = "", section = "fighting", group = "" },
	
	-- Macro Vars.
	SKM_M1ACTIONTYPE = { default = "Action", cast = "string", profile = "m1actiontype", readable = "", section = "fighting" },
	SKM_M1ACTIONID = { default = 0, cast = "number", profile = "m1actionid", readable = "", section = "fighting" },
	SKM_M1ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m1actiontarget", readable = "", section = "fighting" },
	SKM_M1ACTIONWAIT = { default = 100, cast = "number", profile = "m1actionwait", readable = "", section = "fighting" },
	SKM_M1ACTIONMSG = { default = "", cast = "string", profile = "m1actionmsg", readable = "", section = "fighting" },
	SKM_M1ACTIONCOMPLETE = { default = "", cast = "string", profile = "m1actioncomplete", readable = "", section = "fighting" },

	SKM_M2ACTIONTYPE = { default = "Action", cast = "string", profile = "m2actiontype", readable = "", section = "fighting" },
	SKM_M2ACTIONID = { default = 0, cast = "number", profile = "m2actionid", readable = "", section = "fighting" },
	SKM_M2ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m2actiontarget", readable = "", section = "fighting" },
	SKM_M2ACTIONWAIT = { default = 100, cast = "number", profile = "m2actionwait", readable = "", section = "fighting" },
	SKM_M2ACTIONMSG = { default = "", cast = "string", profile = "m2actionmsg", readable = "", section = "fighting" },
	SKM_M2ACTIONCOMPLETE = { default = "", cast = "string", profile = "m2actioncomplete", readable = "", section = "fighting" },

	SKM_M3ACTIONTYPE = { default = "Action", cast = "string", profile = "m3actiontype", readable = "", section = "fighting" },
	SKM_M3ACTIONID = { default = 0, cast = "number", profile = "m3actionid", readable = "", section = "fighting" },
	SKM_M3ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m3actiontarget", readable = "", section = "fighting" },
	SKM_M3ACTIONWAIT = { default = 100, cast = "number", profile = "m3actionwait", readable = "", section = "fighting" },
	SKM_M3ACTIONMSG = { default = "", cast = "string", profile = "m3actionmsg", readable = "", section = "fighting" },
	SKM_M3ACTIONCOMPLETE = { default = "", cast = "string", profile = "m3actioncomplete", readable = "", section = "fighting" },

	SKM_M4ACTIONTYPE = { default = "Action", cast = "string", profile = "m4actiontype", readable = "", section = "fighting" },
	SKM_M4ACTIONID = { default = 0, cast = "number", profile = "m4actionid", readable = "", section = "fighting" },
	SKM_M4ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m4actiontarget", readable = "", section = "fighting" },
	SKM_M4ACTIONWAIT = { default = 100, cast = "number", profile = "m4actionwait", readable = "", section = "fighting" },
	SKM_M4ACTIONMSG = { default = "", cast = "string", profile = "m4actionmsg", readable = "", section = "fighting" },
	SKM_M4ACTIONCOMPLETE = { default = "", cast = "string", profile = "m4actioncomplete", readable = "", section = "fighting" },

	SKM_M5ACTIONTYPE = { default = "Action", cast = "string", profile = "m5actiontype", readable = "", section = "fighting" },
	SKM_M5ACTIONID = { default = 0, cast = "number", profile = "m5actionid", readable = "", section = "fighting" },
	SKM_M5ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m5actiontarget", readable = "", section = "fighting" },
	SKM_M5ACTIONWAIT = { default = 100, cast = "number", profile = "m5actionwait", readable = "", section = "fighting" },
	SKM_M5ACTIONMSG = { default = "", cast = "string", profile = "m5actionmsg", readable = "", section = "fighting" },
	SKM_M5ACTIONCOMPLETE = { default = "", cast = "string", profile = "m5actioncomplete", readable = "", section = "fighting" },

	SKM_M6ACTIONTYPE = { default = "Action", cast = "string", profile = "m6actiontype", readable = "", section = "fighting" },
	SKM_M6ACTIONID = { default = 0, cast = "number", profile = "m6actionid", readable = "", section = "fighting" },
	SKM_M6ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m6actiontarget", readable = "", section = "fighting" },
	SKM_M6ACTIONWAIT = { default = 100, cast = "number", profile = "m6actionwait", readable = "", section = "fighting" },
	SKM_M6ACTIONMSG = { default = "", cast = "string", profile = "m6actionmsg", readable = "", section = "fighting" },
	SKM_M6ACTIONCOMPLETE = { default = "", cast = "string", profile = "m6actioncomplete", readable = "", section = "fighting" },

	SKM_M7ACTIONTYPE = { default = "Action", cast = "string", profile = "m7actiontype", readable = "", section = "fighting" },
	SKM_M7ACTIONID = { default = 0, cast = "number", profile = "m7actionid", readable = "", section = "fighting" },
	SKM_M7ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m7actiontarget", readable = "", section = "fighting" },
	SKM_M7ACTIONWAIT = { default = 100, cast = "number", profile = "m7actionwait", readable = "", section = "fighting" },
	SKM_M7ACTIONMSG = { default = "", cast = "string", profile = "m7actionmsg", readable = "", section = "fighting" },
	SKM_M7ACTIONCOMPLETE = { default = "", cast = "string", profile = "m7actioncomplete", readable = "", section = "fighting" },

	SKM_M8ACTIONTYPE = { default = "Action", cast = "string", profile = "m8actiontype", readable = "", section = "fighting" },
	SKM_M8ACTIONID = { default = 0, cast = "number", profile = "m8actionid", readable = "", section = "fighting" },
	SKM_M8ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m8actiontarget", readable = "", section = "fighting" },
	SKM_M8ACTIONWAIT = { default = 100, cast = "number", profile = "m8actionwait", readable = "", section = "fighting" },
	SKM_M8ACTIONMSG = { default = "", cast = "string", profile = "m8actionmsg", readable = "", section = "fighting" },
	SKM_M8ACTIONCOMPLETE = { default = "", cast = "string", profile = "m8actioncomplete", readable = "", section = "fighting" },

	SKM_M9ACTIONTYPE = { default = "Action", cast = "string", profile = "m9actiontype", readable = "", section = "fighting" },
	SKM_M9ACTIONID = { default = 0, cast = "number", profile = "m9actionid", readable = "", section = "fighting" },
	SKM_M9ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m9actiontarget", readable = "", section = "fighting" },
	SKM_M9ACTIONWAIT = { default = 100, cast = "number", profile = "m9actionwait", readable = "", section = "fighting" },
	SKM_M9ACTIONMSG = { default = "", cast = "string", profile = "m9actionmsg", readable = "", section = "fighting" },
	SKM_M9ACTIONCOMPLETE = { default = "", cast = "string", profile = "m9actioncomplete", readable = "", section = "fighting" },

	SKM_M10ACTIONTYPE = { default = "Action", cast = "string", profile = "m10actiontype", readable = "", section = "fighting" },
	SKM_M10ACTIONID = { default = 0, cast = "number", profile = "m10actionid", readable = "", section = "fighting" },
	SKM_M10ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m10actiontarget", readable = "", section = "fighting" },
	SKM_M10ACTIONWAIT = { default = 100, cast = "number", profile = "m10actionwait", readable = "", section = "fighting" },
	SKM_M10ACTIONMSG = { default = "", cast = "string", profile = "m10actionmsg", readable = "", section = "fighting" },
	SKM_M10ACTIONCOMPLETE = { default = "", cast = "string", profile = "m10actioncomplete", readable = "", section = "fighting" },

	SKM_M11ACTIONTYPE = { default = "Action", cast = "string", profile = "m11actiontype", readable = "", section = "fighting" },
	SKM_M11ACTIONID = { default = 0, cast = "number", profile = "m11actionid", readable = "", section = "fighting" },
	SKM_M11ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m11actiontarget", readable = "", section = "fighting" },
	SKM_M11ACTIONWAIT = { default = 100, cast = "number", profile = "m11actionwait", readable = "", section = "fighting" },
	SKM_M11ACTIONMSG = { default = "", cast = "string", profile = "m11actionmsg", readable = "", section = "fighting" },
	SKM_M11ACTIONCOMPLETE = { default = "", cast = "string", profile = "m11actioncomplete", readable = "", section = "fighting" },

	SKM_M12ACTIONTYPE = { default = "Action", cast = "string", profile = "m12actiontype", readable = "", section = "fighting" },
	SKM_M12ACTIONID = { default = 0, cast = "number", profile = "m12actionid", readable = "", section = "fighting" },
	SKM_M12ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m12actiontarget", readable = "", section = "fighting" },
	SKM_M12ACTIONWAIT = { default = 100, cast = "number", profile = "m12actionwait", readable = "", section = "fighting" },
	SKM_M12ACTIONMSG = { default = "", cast = "string", profile = "m12actionmsg", readable = "", section = "fighting" },
	SKM_M12ACTIONCOMPLETE = { default = "", cast = "string", profile = "m12actioncomplete", readable = "", section = "fighting" },

	SKM_M13ACTIONTYPE = { default = "Action", cast = "string", profile = "m13actiontype", readable = "", section = "fighting" },
	SKM_M13ACTIONID = { default = 0, cast = "number", profile = "m13actionid", readable = "", section = "fighting" },
	SKM_M13ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m13actiontarget", readable = "", section = "fighting" },
	SKM_M13ACTIONWAIT = { default = 100, cast = "number", profile = "m13actionwait", readable = "", section = "fighting" },
	SKM_M13ACTIONMSG = { default = "", cast = "string", profile = "m13actionmsg", readable = "", section = "fighting" },
	SKM_M13ACTIONCOMPLETE = { default = "", cast = "string", profile = "m13actioncomplete", readable = "", section = "fighting" },

	SKM_M14ACTIONTYPE = { default = "Action", cast = "string", profile = "m14actiontype", readable = "", section = "fighting" },
	SKM_M14ACTIONID = { default = 0, cast = "number", profile = "m14actionid", readable = "", section = "fighting" },
	SKM_M14ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m14actiontarget", readable = "", section = "fighting" },
	SKM_M14ACTIONWAIT = { default = 100, cast = "number", profile = "m14actionwait", readable = "", section = "fighting" },
	SKM_M14ACTIONMSG = { default = "", cast = "string", profile = "m14actionmsg", readable = "", section = "fighting" },
	SKM_M14ACTIONCOMPLETE = { default = "", cast = "string", profile = "m14actioncomplete", readable = "", section = "fighting" },

	SKM_M15ACTIONTYPE = { default = "Action", cast = "string", profile = "m15actiontype", readable = "", section = "fighting" },
	SKM_M15ACTIONID = { default = 0, cast = "number", profile = "m15actionid", readable = "", section = "fighting" },
	SKM_M15ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m15actiontarget", readable = "", section = "fighting" },
	SKM_M15ACTIONWAIT = { default = 100, cast = "number", profile = "m15actionwait", readable = "", section = "fighting" },
	SKM_M15ACTIONMSG = { default = "", cast = "string", profile = "m15actionmsg", readable = "", section = "fighting" },
	SKM_M15ACTIONCOMPLETE = { default = "", cast = "string", profile = "m15actioncomplete", readable = "", section = "fighting" },

	SKM_M16ACTIONTYPE = { default = "Action", cast = "string", profile = "m16actiontype", readable = "", section = "fighting" },
	SKM_M16ACTIONID = { default = 0, cast = "number", profile = "m16actionid", readable = "", section = "fighting" },
	SKM_M16ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m16actiontarget", readable = "", section = "fighting" },
	SKM_M16ACTIONWAIT = { default = 100, cast = "number", profile = "m16actionwait", readable = "", section = "fighting" },
	SKM_M16ACTIONMSG = { default = "", cast = "string", profile = "m16actionmsg", readable = "", section = "fighting" },
	SKM_M16ACTIONCOMPLETE = { default = "", cast = "string", profile = "m16actioncomplete", readable = "", section = "fighting" },

	SKM_M17ACTIONTYPE = { default = "Action", cast = "string", profile = "m17actiontype", readable = "", section = "fighting" },
	SKM_M17ACTIONID = { default = 0, cast = "number", profile = "m17actionid", readable = "", section = "fighting" },
	SKM_M17ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m17actiontarget", readable = "", section = "fighting" },
	SKM_M17ACTIONWAIT = { default = 100, cast = "number", profile = "m17actionwait", readable = "", section = "fighting" },
	SKM_M17ACTIONMSG = { default = "", cast = "string", profile = "m17actionmsg", readable = "", section = "fighting" },
	SKM_M17ACTIONCOMPLETE = { default = "", cast = "string", profile = "m17actioncomplete", readable = "", section = "fighting" },

	SKM_M18ACTIONTYPE = { default = "Action", cast = "string", profile = "m18actiontype", readable = "", section = "fighting" },
	SKM_M18ACTIONID = { default = 0, cast = "number", profile = "m18actionid", readable = "", section = "fighting" },
	SKM_M18ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m18actiontarget", readable = "", section = "fighting" },
	SKM_M18ACTIONWAIT = { default = 100, cast = "number", profile = "m18actionwait", readable = "", section = "fighting" },
	SKM_M18ACTIONMSG = { default = "", cast = "string", profile = "m18actionmsg", readable = "", section = "fighting" },
	SKM_M18ACTIONCOMPLETE = { default = "", cast = "string", profile = "m18actioncomplete", readable = "", section = "fighting" },

	SKM_M19ACTIONTYPE = { default = "Action", cast = "string", profile = "m19actiontype", readable = "", section = "fighting" },
	SKM_M19ACTIONID = { default = 0, cast = "number", profile = "m19actionid", readable = "", section = "fighting" },
	SKM_M19ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m19actiontarget", readable = "", section = "fighting" },
	SKM_M19ACTIONWAIT = { default = 100, cast = "number", profile = "m19actionwait", readable = "", section = "fighting" },
	SKM_M19ACTIONMSG = { default = "", cast = "string", profile = "m19actionmsg", readable = "", section = "fighting" },
	SKM_M19ACTIONCOMPLETE = { default = "", cast = "string", profile = "m19actioncomplete", readable = "", section = "fighting" },

	SKM_M20ACTIONTYPE = { default = "Action", cast = "string", profile = "m20actiontype", readable = "", section = "fighting" },
	SKM_M20ACTIONID = { default = 0, cast = "number", profile = "m20actionid", readable = "", section = "fighting" },
	SKM_M20ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m20actiontarget", readable = "", section = "fighting" },
	SKM_M20ACTIONWAIT = { default = 100, cast = "number", profile = "m20actionwait", readable = "", section = "fighting" },
	SKM_M20ACTIONMSG = { default = "", cast = "string", profile = "m20actionmsg", readable = "", section = "fighting" },
	SKM_M20ACTIONCOMPLETE = { default = "", cast = "string", profile = "m20actioncomplete", readable = "", section = "fighting" },
	
	-- Buff Vars.
	--SKM_B1TARGET = { default = GetString("Target"), cast = "string", profile = "b1target", readable = "", section = "fighting" },
	--SKM_B1QUALIFIER = { default = "HasBuff", cast = "string", profile = "b1qualifier", readable = "", section = "fighting" },
	
	--[[
	SKM_PBuff = { default = "", cast = "string", profile = "pbuff", readable = "", section = "fighting"  },
	SKM_PBuffDura = { default = 0, cast = "number", profile = "pbuffdura", readable = "", section = "fighting" },
	SKM_PNBuff = { default = "", cast = "string", profile = "pnbuff", readable = "", section = "fighting"  },
	SKM_PNBuffDura = { default = 0, cast = "number", profile = "pnbuffdura", readable = "", section = "fighting"   },
	
	SKM_B1TARGET = { default = GetString("Target"), cast = "string", profile = "b1target", readable = "", section = "fighting" },
	SKM_M1ACTIONID = { default = 0, cast = "number", profile = "m1actionid", readable = "", section = "fighting" },
	SKM_M1ACTIONTARGET = { default = GetString("Target"), cast = "string", profile = "m1actiontarget", readable = "", section = "fighting" },
	SKM_M1ACTIONWAIT = { default = 100, cast = "number", profile = "m1actionwait", readable = "", section = "fighting" },
	SKM_M1ACTIONMSG = { default = "", cast = "string", profile = "m1actionmsg", readable = "", section = "fighting" },
	SKM_M1ACTIONCOMPLETE = { default = "", cast = "string", profile = "m1actioncomplete", readable = "", section = "fighting" },
	--]]
	SKM_IgnoreMoving = { default = false, cast = "boolean", profile = "ignoremoving", readable = "", section = "fighting" },
	
	SKM_SingleUseCraft = { default = true, cast = "boolean", profile = "singleuseonly", readable = "", section = "crafting"},
	SKM_ConsecutiveUseCraft = { default = false, cast = "boolean", profile = "consecutiveuseonly", readable = "", section = "crafting"},
	
	SKM_CLevelMin = { default = 0, cast = "number", profile = "playerlevelmin", readable = "", section = "crafting", group = "", useData = "level" },
	SKM_CLevelMax = { default = 0, cast = "number", profile = "playerlevelmax", readable = "", section = "crafting", group = ""   },
	
	SKM_STMIN = { default = 0, cast = "number", profile = "stepmin", readable = "", section = "crafting"},
	SKM_STMAX = { default = 0, cast = "number", profile = "stepmax", readable = "", section = "crafting"},
	SKM_CPMIN = { default = 0, cast = "number", profile = "cpmin", readable = "", section = "crafting"},
	SKM_CPMAX = { default = 0, cast = "number", profile = "cpmax", readable = "", section = "crafting"},
	SKM_DURMIN = { default = 0, cast = "number", profile = "durabmin", readable = "", section = "crafting"},
	SKM_DURMAX = { default = 0, cast = "number", profile = "durabmax", readable = "", section = "crafting"},
	SKM_MAXDURMIN = { default = 0, cast = "number", profile = "maxdurabmin", readable = "", section = "crafting"},
	SKM_MAXDURMAX = { default = 0, cast = "number", profile = "maxdurabmax", readable = "", section = "crafting"},
	SKM_PROGMIN = { default = 0, cast = "number", profile = "progrmin", readable = "", section = "crafting"},
	SKM_PROGMAX = { default = 0, cast = "number", profile = "progrmax", readable = "", section = "crafting"},

	SKM_MAXPROGMIN = { default = 0, cast = "number", profile = "maxprogrmin", readable = "", section = "crafting"},
	SKM_MAXPROGMAX = { default = 0, cast = "number", profile = "maxprogrmax", readable = "", section = "crafting"},
	
	SKM_CRAFTMIN = { default = 0, cast = "number", profile = "craftmin", readable = "", section = "crafting"},
	SKM_CRAFTMAX = { default = 0, cast = "number", profile = "craftmax", readable = "", section = "crafting"},
	SKM_CONTROLMIN = { default = 0, cast = "number", profile = "controlmin", readable = "", section = "crafting"},
	SKM_CONTROLMAX = { default = 0, cast = "number", profile = "controlmax", readable = "", section = "crafting"},
	SKM_QUALMIN = { default = 0, cast = "number", profile = "qualitymin", readable = "", section = "crafting"},
	SKM_QUALMAX = { default = 0, cast = "number", profile = "qualitymax", readable = "", section = "crafting"},
	SKM_QUALMINPer = { default = 0, cast = "number", profile = "qualityminper", readable = "", section = "crafting"},
	SKM_QUALMAXPer = { default = 0, cast = "number", profile = "qualitymaxper", readable = "", section = "crafting"},
	SKM_CONDITION = { default = GetString("notused"), cast = "string", list = true, profile = "condition", readable = "", section = "crafting"},
	
	SKM_CPBuff = { default = "", cast = "string", profile = "cpbuff", readable = "", section = "crafting"},
	SKM_CPNBuff = { default = "", cast = "string", profile = "cpnbuff", readable = "", section = "crafting"},
	SKM_IQSTACKMAX = { default = 0, cast = "number", profile = "iqstackmax", readable = "", section = "crafting"},
	SKM_IQSTACK = { default = 0, cast = "number", profile = "iqstack", readable = "", section = "crafting"},
	SKM_GSSTACKMIN = { default = 0, cast = "number", profile = "gsstackmin", readable = "", section = "crafting"},
	SKM_WNSTACKMIN = { default = 0, cast = "number", profile = "wnstackmin", readable = "", section = "crafting"},
	SKM_WN2STACKMIN = { default = 0, cast = "number", profile = "wn2stackmin", readable = "", section = "crafting"},
	SKM_MANIPSTACKMIN = { default = 0, cast = "number", profile = "manipstackmin", readable = "", section = "crafting"},
	SKM_MANIPSTACKMAX = { default = 0, cast = "number", profile = "manipstackmax", readable = "", section = "crafting"},
	SKM_INNOSTACKMIN = { default = 0, cast = "number", profile = "innostackmin", readable = "", section = "crafting"},
	SKM_TOTMIN = { default = 0, cast = "number", profile = "totmin", readable = "", section = "crafting"},
	SKM_TOTMAX = { default = 0, cast = "number", profile = "totmax", readable = "", section = "crafting"},
	SKM_HTSUCCEED = { default = 0, cast = "number", profile = "htsucceed", readable = "", section = "crafting"},
	SKM_MANIPMAX = { default = 0, cast = "number", profile = "manipmax", readable = "", section = "crafting"},	
	
	SKM_SingleUse = { default = true, cast = "boolean", profile = "singleuseonly", readable = "", section = "gathering"},
	SKM_AddsBuff = { default = "", cast = "string", profile = "gatheraddsbuff", readable = "", section = "gathering"},
	SKM_AddsMark = { default = "", cast = "string", profile = "gatheraddsmark", readable = "", section = "gathering"},
	SKM_RequiresMark = { default = "", cast = "string", profile = "gatherrequiresmark", readable = "", section = "gathering"},
	SKM_GatherMax = { default = false, cast = "boolean", profile = "gathermax", readable = "", section = "gathering"},
	SKM_GPStart = { default = 0, cast = "number", profile = "gpstart", readable = "", section = "gathering"},
	SKM_GPMIN = { default = 0, cast = "number", profile = "gpmin", readable = "", section = "gathering"},
	SKM_GPMAX = { default = 0, cast = "number", profile = "gpmax", readable = "", section = "gathering"},
	SKM_GAttemptsMin = { default = 0, cast = "number", profile = "gatherattempts", readable = "", section = "gathering"},
	SKM_GAttemptsMax = { default = 0, cast = "number", profile = "gatherattemptsmax", readable = "", section = "gathering"},
	SKM_GMaxAttemptsMin = { default = 0, cast = "number", profile = "maxgatherattemptsmin", readable = "", section = "gathering"},
	SKM_GMaxAttempts = { default = 0, cast = "number", profile = "maxgatherattempts", readable = "", section = "gathering"},
	SKM_HasItem = { default = "", cast = "string", profile = "hasitem", readable = "", section = "gathering"},
	SKM_IsItem = { default = "", cast = "string", profile = "isitem", readable = "", section = "gathering"},
	SKM_QTY = { default = 0, cast = "number", profile = "quantity", readable = "", section = "gathering"},
	SKM_UNSP = { default = false, cast = "boolean", profile = "isunspoiled", readable = "", section = "gathering"},
	SKM_EPHE = { default = false, cast = "boolean", profile = "isephemeral", readable = "", section = "gathering"},
	SKM_LGND = { default = false, cast = "boolean", profile = "islegendary", readable = "", section = "gathering"},
	SKM_CNCLD = { default = false, cast = "boolean", profile = "isconcealed", readable = "", section = "gathering"},
	SKM_GSecsPassed = { default = 0, cast = "number", profile = "gsecspassed", readable = "", section = "gathering"},
	SKM_ItemChanceMax = { default = 0, cast = "number", profile = "itemchancemax", readable = "", section = "gathering"},
	SKM_ItemHQChanceMin = { default = 0, cast = "number", profile = "itemhqchancemin", readable = "", section = "gathering"},
	SKM_CollRarityLT = { default = 0, cast = "number", profile = "collraritylt", readable = "", section = "gathering"},
	SKM_CollRarityGT = { default = 0, cast = "number", profile = "collraritygt", readable = "", section = "gathering"},
	SKM_CollWearLT = { default = 0, cast = "number", profile = "collwearlt", readable = "", section = "gathering"},
	SKM_CollWearGT = { default = 0, cast = "number", profile = "collweargt", readable = "", section = "gathering"},
	SKM_CollWearEQ = { default = 0, cast = "number", profile = "collweareq", readable = "", section = "gathering"},
	SKM_GPBuff = { default = "", cast = "string", profile = "gpbuff", readable = "", section = "gathering"},
	SKM_GPNBuff = { default = "", cast = "string", profile = "gpnbuff", readable = "", section = "gathering"},
	SKM_PSkillIDG = { default = "", cast = "string", profile = "pskillg", readable = "", section = "gathering"},
}

SkillMgr.UpdateDefaultProfiles()

function SkillMgr.ModuleInit() 	
	SkillMgr.GUI.manager.main_tabs = GUI_CreateTabs("Edit,Add,Debug",false)
	
	for varname,info in pairs(SkillMgr.Variables) do
		_G[varname] = info.default
	end
	


	local uuid = GetUUID()
	if (Settings.FFXIVMINION.gSMDefaultProfiles == nil) then
		Settings.FFXIVMINION.gSMDefaultProfiles = {}
	end
	if (Settings.FFXIVMINION.gSMDefaultProfiles[uuid] == nil) then
		Settings.FFXIVMINION.gSMDefaultProfiles[uuid] = {}
		Settings.FFXIVMINION.gSMDefaultProfiles = Settings.FFXIVMINION.gSMDefaultProfiles
	end	

	gSMDefaultProfiles = Settings.FFXIVMINION.gSMDefaultProfiles[uuid]
	gSMProfileUpdates = ffxivminion.GetSetting("gSMProfileUpdates",0)

	if gSMProfileUpdates < 20200805 then
		if In(gSMDefaultProfiles[FFXIV.JOBS.GLADIATOR],"Paladin",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.GLADIATOR] = "Paladin_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.MARAUDER],"Warrior",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.MARAUDER] = "Warrior_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.LANCER],"Dragoon",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.LANCER] = "Dragoon_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.ARCHER],"Bard",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.ARCHER] = "Bard_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.CONJURER],"Whitemage",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.CONJURER] = "Whitemage_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.THAUMATURGE],"Blackmage",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.THAUMATURGE] = "Blackmage_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.PALADIN],"Paladin",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.PALADIN] = "Paladin_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.WARRIOR],"Warrior",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.WARRIOR] = "Warrior_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.DRAGOON],"Dragoon",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.DRAGOON] = "Dragoon_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.BARD],"Bard",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.BARD] = "Bard_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.WHITEMAGE],"Whitemage",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.WHITEMAGE] = "Whitemage_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.BLACKMAGE],"Blackmage",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.BLACKMAGE] = "Blackmage_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.ARCANIST],"Summoner",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.ARCANIST] = "Summoner_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.SUMMONER],"Summoner",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.SUMMONER] = "Summoner_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.SCHOLAR],"Scholar",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.SCHOLAR] = "Scholar_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.DARKKNIGHT],"DarkKnight",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.DARKKNIGHT] = "DarkKnight_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.MACHINIST],"Machinist",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.MACHINIST] = "Machinist_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.ASTROLOGIAN],"Astrologian",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.ASTROLOGIAN] = "Astrologian_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.SAMURAI],"Samurai",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.SAMURAI] = "Samurai_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.REDMAGE],"Redmage",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.REDMAGE] = "Redmage_SHB"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.DANCER],"None",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.DANCER] = "Dancer"
		end
		if In(gSMDefaultProfiles[FFXIV.JOBS.GUNBREAKER],"None",nil) then
			gSMDefaultProfiles[FFXIV.JOBS.GUNBREAKER] = "Gunbreaker"
		end
		if In(gSMDefaultProfiles[39],"None",nil) then
			gSMDefaultProfiles[39] = "Reaper"
		end
		if In(gSMDefaultProfiles[40],"None",nil) then
			gSMDefaultProfiles[40] = "Sage"
		end
		if In(GetGameRegion(),1,2) then
			if In(gSMDefaultProfiles[FFXIV.JOBS.ROGUE],"Ninja","Rogue",nil) then
				gSMDefaultProfiles[FFXIV.JOBS.ROGUE] = "Ninja52"
			end
			if In(gSMDefaultProfiles[FFXIV.JOBS.NINJA],"Ninja","Rogue",nil) then
				gSMDefaultProfiles[FFXIV.JOBS.NINJA] = "Ninja52"
			end
		end
		Settings.FFXIVMINION.gSMProfileUpdates = 20200805
	end
	
	gSkillManagerQueueing = ffxivminion.GetSetting("gSkillManagerQueueing",false)
	gSkillManagerDebug = ffxivminion.GetSetting("gSkillManagerDebug",false)
	gSkillManagerDebugPriorities = ffxivminion.GetSetting("gSkillManagerDebugPriorities","")
	gSkillManagerNewProfile = ""
	
	gSkillMgrFilterJob = ffxivminion.GetSetting("gSkillMgrFilterJob",true)
	gSkillMgrFilterUsable = ffxivminion.GetSetting("gSkillMgrFilterUsable",true)
	
	gAssistFilter1 = ffxivminion.GetSetting("gAssistFilter1",false)
	gAssistFilter2 = ffxivminion.GetSetting("gAssistFilter2",false)
	gAssistFilter3 = ffxivminion.GetSetting("gAssistFilter3",false)
	gAssistFilter4 = ffxivminion.GetSetting("gAssistFilter4",false)
	gAssistFilter5 = ffxivminion.GetSetting("gAssistFilter5",false)
	
	gSMCraftConditions = { GetString("notused"), GetString("excellent"), GetString("good"), GetString("normal"), GetString("poor"), GetString("centered"), GetString("sturdy"), GetString("pliant"), GetString("primed"), GetString("malleable") }
	gSMCraftConditionIndex = 1
	gSMCraftConditionsCache = {}

	gSMBattleStatuses = { GetString("In Combat"), GetString("Out of Combat"), GetString("Any") }
	gSMBattleStatusIndex = 1
	
	gSMFilterStatuses = { GetString("Ignore"),GetString("On"),GetString("Off") }
	gSMFilter1Index = 1
	gSMFilter2Index = 1
	gSMFilter3Index = 1
	gSMFilter4Index = 1
	gSMFilter5Index = 1
	
	gSMHealPriorities = { GetString("Self"),GetString("Tank"),GetString("Party"),GetString("Any"),GetString("none") }
	gSMHealPriority1 = 1
	gSMHealPriority2 = 1
	gSMHealPriority3 = 1
	gSMHealPriority4 = 1
	
	gSMBuffOwners = { GetString("Player"),GetString("Any") }
	gSMBuffOwner = 1
	gSMBuffOwnerN = 1
	
	gSMOffGCDSettings = { GetString("Auto"),GetString("True"),GetString("False") }
	gSMOffGCDSetting = 1
	
	gSMTargets = { GetString("Target"),GetString("Ground Target"),GetString("Player"),GetString("Cast Target"),GetString("Party"),GetString("PartyS"),GetString("Low TP"),GetString("Low MP"),GetString("Pet"),GetString("Ally"),GetString("Tank"),GetString("Tankable Target"),GetString("Tanked Target"),GetString("Heal Priority"),GetString("Dead Ally"),GetString("Dead Party") }
	gSMTarget = 1
	
	gSMTargetTypes = { GetString("Any"),GetString("Tank"),GetString("DPS"),GetString("Caster"),GetString("Healer"),GetString("RangeDPS"),GetString("MeleeDPS") }
	gSMTargetType = 1
	
	gSMPlayerTargets = { GetString("Any"),GetString("Enemy"),GetString("Player") }
	gSMPlayerTarget = 1
	
	gSMPlayerGroundTargetPositions = { GetString("Direct"),GetString("Behind"),GetString("Near") }
	gSMPlayerGroundTargetPosition = 1
	
	gSMPlayerPositions = { GetString("none"),GetString("Front"),GetString("Flanking"),GetString("Behind") }
	gSMPlayerPosition = 1
	
	gSMAOECenters = { GetString("Auto"),GetString("Self"),GetString("Target") }
	gSMAOECenter = 1
	
	gSMAOELevels = { "0","2","4","6",GetString("Any") }
	gSMAOELevel = 1
	
	for i = 1,5 do
		if (type(_G["gAssistFilter"..tostring(i)]) ~= "boolean") then
			_G["gAssistFilter"..tostring(i)] = toboolean(_G["gAssistFilter"..tostring(i)])
			Settings.FFXIVMINION["gAssistFilter"..tostring(i)] = _G["gAssistFilter"..tostring(i)]
		end
	end
	
	gSkillProfileValidGLD = false
	gSkillProfileValidPLD = false
	gSkillProfileValidPUG = false
	gSkillProfileValidMNK = false
	gSkillProfileValidMRD = false
	gSkillProfileValidWAR = false
	gSkillProfileValidLNC = false
	gSkillProfileValidDRG = false
	gSkillProfileValidARC = false
	gSkillProfileValidBRD = false
	gSkillProfileValidCNJ = false
	gSkillProfileValidWHM = false
	gSkillProfileValidTHM = false
	gSkillProfileValidBLM = false
	gSkillProfileValidACN = false
	gSkillProfileValidSMN = false
	gSkillProfileValidSCH = false
	gSkillProfileValidROG = false
	gSkillProfileValidNIN = false
	gSkillProfileValidDRK = false
	gSkillProfileValidMCH = false
	gSkillProfileValidAST = false
	gSkillProfileValidSAM = false
	gSkillProfileValidRDM = false
	gSkillProfileValidBLU = false
	gSkillProfileValidGNB = false
	gSkillProfileValidDNC = false
	
	gSkillProfileValidMIN = false
	gSkillProfileValidBTN = false
	gSkillProfileValidFSH = false
	
	gSkillProfileValidCRP = false
	gSkillProfileValidBSM = false
	gSkillProfileValidARM = false
	gSkillProfileValidGSM = false
	gSkillProfileValidLTW = false
	gSkillProfileValidWVR = false
	gSkillProfileValidALC = false
	gSkillProfileValidCUL = false
	
	SkillMgr.UpdateProfiles()
	SkillMgr.AddDefaultConditions()
end

function SkillMgr.LoadInit()
	gSkillProfile = gSMDefaultProfiles[Player.job]
	if (not gSkillProfile) then
		local starterDefault = SkillMgr.StartingProfiles[Player.job]
		if ( starterDefault ) then
			local filePath = SkillMgr.profilePath..starterDefault..".lua"
			if (FileExists(filePath)) then
				gSkillProfile = gSMDefaultProfiles[Player.job]
				local uuid = GetUUID()
				Settings.FFXIVMINION.gSMDefaultProfiles[uuid] = gSMDefaultProfiles
				Settings.FFXIVMINION.gSMDefaultProfiles = Settings.FFXIVMINION.gSMDefaultProfiles
			end
		end
	end

	gSkillProfileIndex = GetKeyByValue(gSkillProfile,SkillMgr.profiles) or 1
	if (SkillMgr.profiles[gSkillProfileIndex] ~= gSkillProfile) then
		gSkillProfile = SkillMgr.profiles[gSkillProfileIndex]
	end
end

function GetVersion()
	if (GUI_NewWindow) then
		return 32
	else
		return 64
	end
end

function SkillMgr.GetAction(actionid,actiontype,target)
	local target = IsNull(target,Player)
	local actiontype = IsNull(actiontype,1)
	local targetid;
	if (type(target) == "table") then
		targetid = target.id
	elseif (type(target) == "number") then
		targetid = target
	end
	
	if (GetVersion() == 32) then
		return ActionList:Get(actionid,actiontype,targetid)
	else
		--d("performing a lookup on ["..tostring(actiontype).."], ["..tostring(actionid).."]")
		local action = ActionList:Get(actiontype,actionid)
		if (action) then
			if (not action.usable) then
				action = nil
			else
				action.isready = action:IsReady(targetid)
			end
		end
		return action
	end
end

function SkillMgr.CheckMonitor()
	if (ValidTable(SkillMgr.monitor)) then
		local monitor = SkillMgr.monitor
		
		local checkBoth = IsNull(monitor.both,false)
		local successTimer = false
		local successEval = false
		
		if (monitor.dowhile ~= nil and type(monitor.dowhile) == "function") then
			monitor.dowhile()
		end
		
		if (monitor.mintimer ~= 0) then
			if (Now() < monitor.mintimer) then
				return true
			end
		end
		
		if (monitor.maxtimer ~= 0 and Now() >= monitor.maxtimer) then
			successTimer = true
		end
		if (monitor.evaluator ~= nil and type(monitor.evaluator) == "function") then
			local ret = monitor.evaluator()
			if (ret == true) then
				successEval = true
			end
		end
		
		if ((not checkBoth and (successTimer or successEval)) or
			(checkBoth and successTimer and successEval)) 
		then		
			SkillMgr.monitor = {}
			
			if (successEval and monitor.followsuccess ~= nil and type(monitor.followsuccess) == "function") then
				monitor.followsuccess()
				return true
			end
			
			if (successTimer and monitor.followfail ~= nil and type(monitor.followfail) == "function") then
				monitor.followfail()
				return true
			end
			
			if (monitor.followall ~= nil and type(monitor.followall) == "function") then
				monitor.followall()
				return true
			end
			
			return false
		end
		
		return true
	end
	return false
end

function SkillMgr.IsYielding()
	if (ValidTable(SkillMgr.yield)) then
		local yield = SkillMgr.yield
		
		local checkBoth = IsNull(yield.both,false)
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
		
		if (yield.maxtimer ~= 0 and Now() >= yield.maxtimer) then
			successTimer = true
		end
		if (yield.evaluator ~= nil and type(yield.evaluator) == "function") then
			local ret = yield.evaluator()
			if (ret == true) then
				successEval = true
			end
		end
		if (yield.failure ~= nil and type(yield.failure) == "function") then
			local ret = yield.failure()
			if (ret == true) then
				SkillMgr.yield = {}
				
				if (yield.followfail ~= nil and type(yield.followfail) == "function") then
					yield.followfail()
					return true
				end
				
				if (yield.followall ~= nil and type(yield.followall) == "function") then
					yield.followall()
					return true
				end
				
				return false
			end
		end
		
		if ((not checkBoth and (successTimer or successEval)) or
			(checkBoth and successTimer and successEval)) 
		then		
			SkillMgr.yield = {}
			
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

function SkillMgr.Await(param1, param2, param3, param4, param5)
	if (param1 and type(param2) == "number" and param2 and type(param2) == "number") then
		SkillMgr.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			followall = param4,
			both = IsNull(param5,false),
		}
	else
		SkillMgr.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			followall = param3,
			both = IsNull(param4,false),
		}
	end
end

function SkillMgr.Monitor(param1, param2, param3, param4, param5)
	if (param1 and type(param2) == "number" and param2 and type(param2) == "number") then
		SkillMgr.monitor = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			followall = param4,
			both = IsNull(param5,false),
		}
	else
		SkillMgr.monitor = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			followall = param3,
			both = IsNull(param4,false),
		}
	end
end

function SkillMgr.AwaitDo(param1, param2, param3, param4, param5)
	if (param1 and type(param2) == "number" and param2 and type(param2) == "number") then
		SkillMgr.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			dowhile = param4,
			followall = param5,
		}
	else
		SkillMgr.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			dowhile = param3,
			followall = param4
		}
	end
end

function SkillMgr.AwaitFail(param1, param2, param3, param4, param5)
	if (param1 and type(param2) == "number" and param2 and type(param2) == "number") then
		SkillMgr.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			both = IsNull(param4,false),
			followfail = param5,
		}
	else
		SkillMgr.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			followfail = param3,
			both = IsNull(param4,false),
		}
	end
end

function SkillMgr.AwaitSuccess(param1, param2, param3, param4, param5)
	if (param1 and type(param2) == "number" and param2 and type(param2) == "number") then
		SkillMgr.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			followsuccess = param4,
			both = IsNull(param5,false),
		}
	else
		SkillMgr.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			followsuccess = param3,
			both = IsNull(param4,false),
		}
	end
end

function SkillMgr.AwaitSuccessFail(param1, param2, param3, param4, param5, param6)
	if (param1 and type(param2) == "number" and param2 and type(param2) == "number") then
		SkillMgr.yield = {
			mintimer = IIF(param1 ~= 0,Now() + param1,0),
			maxtimer = IIF(param2 ~= 0,Now() + param2,0),
			evaluator = param3,
			failure = param4,
			followsuccess = param5,
			followfail = param6,
		}
	else
		SkillMgr.yield = {
			mintimer = 0,
			maxtimer = Now() + param1,
			evaluator = param2,
			failure = param3,
			followsuccess = param4,
			followfail = param5,
		}
	end
end

SkillMgr.receivedMacro = {}
SkillMgr.macroCasted = false
SkillMgr.macroAttempts = 0
SkillMgr.failTimer = 0
SkillMgr.recastTimer = 0
function SkillMgr.ParseMacro(data)
	SkillMgr.receivedMacro = {}
	
	if (table.valid(data)) then
		local itype,iparams = nil,nil
		for i,instruction in pairsByKeys(data) do
			itype,iparams = instruction[1],instruction[2]
			if (itype == "Wait") then
				local length = tonumber(iparams[1]) or 150
				table.insert(SkillMgr.receivedMacro, 
					function () 
						SkillMgr.AddThrottleTime(length)
						return true						
					end
				)
			elseif (itype == "Item") then
				local itemid = IsNull(iparams[1],0)
				table.insert(SkillMgr.receivedMacro, 
					function ()
						local item, action = GetItem(itemid)
						if (not item or not action or (item and not item:IsReady(Player.id))) then	
							return true			
						elseif (item and item:IsReady(Player.id)) then
							if (item:Cast(Player.id)) then
								local castid = action.id
								ml_global_information.Await(5000, function () return Player.castinginfo.lastcastid == castid end)
								return true
							end
							return false
						end
					end
				)
			elseif (itype == "Action") then
				local actionid = IsNull(iparams[1],0)
				local actiontype = IsNull(iparams[2],0)
				local targetidentifier = IsNull(iparams[3],GetString("Target"))
				local msg = IsNull(iparams[4],"")
				local completion = IsNull(iparams[5],"")
				local actionwait = IsNull(iparams[6],false)
				
				--d("Received Action Macro.")
				--d("ActionID:"..tostring(actionid))
				--d("ActionType:"..tostring(actiontype))
				--d("TargetIdentifier:"..tostring(targetidentifier))
				--d("Msg:"..tostring(msg))
				--d("ActionWait:"..tostring(actionwait))
				
				table.insert(SkillMgr.receivedMacro, 
					function () 										
						local actionid = actionid
						local actiontype = actiontype
						local targetidentifier = targetidentifier
						local msg = msg
						local completion = completion
						local actionwait = actionwait
						
						if (SkillMgr.failTimer == 0) then
							SkillMgr.failTimer = SkillMgr.lastTick + 3000
						end
						if (SkillMgr.recastTimer == 0) then
							SkillMgr.recastTimer = SkillMgr.lastTick + 750
						end
						
						if (SkillMgr.lastTick > SkillMgr.failTimer) then
							return true
						end
						
						local target;
						local targetid;
						if (targetidentifier == GetString("Target") or targetidentifer == GetString("Ground Target")) then
							local myTarget = Player:GetTarget()
							if (myTarget) then
								target = myTarget
								targetid = myTarget.id
							else
								--d("Fail out of this action, no target.")
								return false
							end
						elseif (targetidentifier == GetString("Player") or targetidentifer == "Ground Player") then
							target = Player
							targetid = Player.id
						end

						--local action = SkillMgr.GetAction(actionid,actiontype,targetid)
						local action = SkillMgr.GetAction(actionid,actiontype)
						if (action) then

							if (targetidentifer == GetString("Ground Target") or targetidentifer == "Ground Player") then
								local tpos = target.pos
								local eh = AceLib.API.Math.ConvertHeading(tpos.h)
								
								local randomFront = (math.random(1,5) / 100)
								local randomRearFlank = (math.random(65,80) / 100)
								local randomFrontFlank = (math.random(20,35) / 100)
								local randomFlank = (math.random(40,60) / 100)
								local randomRear = (math.random(90,100) / 100)
								
								local positions = {
									AceLib.API.Math.ConvertHeading((eh) + (math.pi * randomFront))%(2*math.pi),
									AceLib.API.Math.ConvertHeading((eh) + (math.pi * randomFront))%(2*math.pi),
									AceLib.API.Math.ConvertHeading((eh) - (math.pi * randomFront))%(2*math.pi),
									AceLib.API.Math.ConvertHeading((eh - (math.pi * randomFlank)))%(2*math.pi),
									AceLib.API.Math.ConvertHeading((eh + (math.pi * randomFlank)))%(2*math.pi),
									AceLib.API.Math.ConvertHeading((eh - (math.pi * randomRearFlank)))%(2*math.pi),
									AceLib.API.Math.ConvertHeading((eh + (math.pi * randomRearFlank)))%(2*math.pi),
									AceLib.API.Math.ConvertHeading((eh - (math.pi * randomRear)))%(2*math.pi),
									AceLib.API.Math.ConvertHeading((eh + (math.pi * randomRear)))%(2*math.pi),
									AceLib.API.Math.ConvertHeading((eh + (math.pi * randomFrontFlank)))%(2*math.pi),
									AceLib.API.Math.ConvertHeading((eh - (math.pi * randomFrontFlank)))%(2*math.pi),
								}
								
								local draw = math.random(1,11)
								local range = (math.random(30,110) / 100)
								local newpos = AceLib.API.Math.GetPosFromDistanceHeading(tpos, range, positions[draw])
								if (newpos) then
									tpos = newpos
								end
							
								if (action:Cast(tpos.x, tpos.y, tpos.z)) then
									return true
								elseif (math.abs(SkillMgr.gcdTime - action.recasttime) > .1 and action.isoncd and ((action.cdmax - action.cd) > 2.5)) then
									if (msg ~= "") then
										SendTextCommand(msg)
									end
									
									return true
								else
									if (Player.castinginfo.channelingid == 0) then
										SkillMgr.macroAttempts = SkillMgr.macroAttempts + 1
										
										if (SkillMgr.macroAttempts > 4) then
											return true
										end
									end
									SkillMgr.AddThrottleTime(100)
								end
							else
								if (SkillMgr.macroCasted) then									
									local canComplete = false
									if (completion ~= "") then
										local f = assert(loadstring("return " .. completion))()
										if (f ~= nil and f == true) then
											canComplete = true
										end
									else
										canComplete = (action.isoncd or Player.castinginfo.castingid == action.id)
									end		
									
									if (canComplete) then
										if (msg ~= "") then
											SendTextCommand(msg)
										end
										
										d("Action ["..tostring(action.name).."] is on cooldown and has been casted, kick it out.")
										return true
									end
									
									if (SkillMgr.lastTick > SkillMgr.recastTimer) then
										if (Player.castinginfo.channelingid == 0) then
											if (action:IsReady(targetid) or action.id == 2260) then
												d("Action ["..tostring(action.name).."] is being reattempted.")
												action:Cast(targetid)	
											end
										end
									end
								else
									if (Player.castinginfo.channelingid == 0) then
										if (action:IsReady(targetid) or action.id == 2260) then
											if (action:Cast(targetid)) then		
												SkillMgr.macroCasted = true
											end
										end
										
										SkillMgr.macroAttempts = SkillMgr.macroAttempts + 1
										if (SkillMgr.macroAttempts > 4) then
											d("Action ["..tostring(action.name).."] has been attempted 5 times or more, kick it out.")
											return true
										end
									end
									
									SkillMgr.AddThrottleTime(100)
								end
							end
						else
							--d("Couldn't find action.")
							return true
						end
						return false
					end
				)				
			end
		end
	end
end

function SkillMgr.AddThrottleTime(t)
	SkillMgr.MacroThrottle = SkillMgr.lastTick + t
end

--[[
function SkillMgr.FoldMacroGroups()
	for i = 1,4 do
		local unfoldvar = _G["gSkillManagerFoldMacro"..tostring(i)]
		if (unfoldvar ) then
			GUI_UnFoldGroup(SkillMgr.editwindow_macro.name,"Macro Group "..tostring(i))
		else
			GUI_FoldGroup(SkillMgr.editwindow_macro.name,"Macro Group "..tostring(i))
		end
	end
end
--]]

--[[
function SkillMgr.FoldBuffGroups()
	for i = 1,2 do
		local unfoldvar = _G["gSkillManagerFoldBuff"..tostring(i)]
		if (unfoldvar ) then
			GUI_UnFoldGroup(SkillMgr.editwindow_macro.name,"Buff Group "..tostring(i))
		else
			GUI_FoldGroup(SkillMgr.editwindow_macro.name,"Buff Group "..tostring(i))
		end
	end
end
--]]

function SkillMgr.OnGameUpdate(event, tickcount)
	SkillMgr.lastTick = tickcount
	
	if (table.valid(SkillMgr.receivedMacro)) then
		--d("Macro table size:"..tostring(TableSize(SkillMgr.receivedMacro)))
		if (SkillMgr.lastTick > SkillMgr.MacroThrottle) then
		
			local newInstruction = SkillMgr.receivedMacro[1]
			if (newInstruction and type(newInstruction) == "function") then
				local retval = newInstruction()
				if (retval == true) then
					table.remove(SkillMgr.receivedMacro,1)
					SkillMgr.macroCasted = false
					SkillMgr.macroAttempts = 0
					SkillMgr.failTimer = 0
					SkillMgr.recastTimer = 0
				end
			end			
		end
		--d("Recieved a macro, exit out early.")
		return
	end
end

function SkillMgr.OnUpdate()
	
	if (SkillMgr.doLoad == true) then
		SkillMgr.LoadInit()
		SkillMgr.UpdateCurrentProfileData()
		SkillMgr.doLoad = false
	end
	
	local pcast = Player.castinginfo
	
	local job = Player.job
	if (pcast.channelingid ~= 0) then
		local channelingskill = pcast.channelingid
		SkillMgr.UpdateLastCast(channelingskill)
	end
	
	local actionWatch = SkillMgr.actionWatch
	if (table.valid(actionWatch)) then
		if (Now() > actionWatch.expiration) then
			actionWatch = {}
		else
			local action = actionWatch.action
			if (Player.action == action) then
				SkillMgr.actionWatchResult = true
				SkillMgr.actionWatch = {}
			end
		end
	end
	
	if (pcast.lastcastid ~= 0) then
		local castingskill = pcast.lastcastid

		local caughtMudra = 0
		if (Player.action == 235 and SkillMgr.prevSkillID ~= 2263) then
			--d("Detected Jin.")
			caughtMudra = 2263
		elseif (Player.action == 234 and SkillMgr.prevSkillID ~= 2261) then
			--d("Detected Chi.")
			caughtMudra = 2261
		elseif (Player.action == 233 and SkillMgr.prevSkillID ~= 2259) then
			--d("Detected Ten.")
			caughtMudra = 2259
		end
		
		if (caughtMudra ~= 0) then
			SkillMgr.prevSkillID = caughtMudra
			SkillMgr.prevSkillTimestamp = Now()
			
			if (SkillMgr.queuedPrio ~= 0) then
				if (SkillMgr.UpdateChain(SkillMgr.queuedPrio,caughtMudra)) then
					SkillMgr.queuedPrio = 0
				end
			end
			SkillMgr.UpdateLastCast(caughtMudra)
			SkillMgr.failTimer = Now() + 6000
		else
			if (SkillMgr.prevSkillID ~= castingskill) then
				local action = SkillMgr.GetAction(castingskill,1)
				if (action) then
					--d("Setting previous skill ID to :"..tostring(castingskill).."["..action.name.."]")
					SkillMgr.prevSkillID = castingskill
					SkillMgr.prevSkillTimestamp = Now()
					if (math.abs(SkillMgr.gcdTime - action.recasttime) <= .1) then
						SkillMgr.prevGCDSkillID = castingskill
					end
					SkillMgr.UpdateLastCast(castingskill)
					SkillMgr.failTimer = Now() + 6000
				end
			end
			if (SkillMgr.queuedPrio ~= 0) then
				local action = SkillMgr.GetAction(castingskill,1)
				if (action) then
					if (SkillMgr.UpdateChain(SkillMgr.queuedPrio,castingskill)) then
						--d("Updating chain information.")
						SkillMgr.queuedPrio = 0
					end
				end
			end
		end
	end
	
	if (SkillMgr.failTimer ~= 0 and Now() > SkillMgr.failTimer) then
		--d("Resetting failTimer.")
		SkillMgr.prevGCDSkillID = ""
		SkillMgr.currentChain = ""
		SkillMgr.failTimer = 0
		SkillMgr.queuedPrio = 0
	end
end

--This is the only function that should actually read from the file.
function SkillMgr.ReadFile(strFile)
	assert(type(strFile) == "string" and strFile ~= "", "[SkillMgr.ReadFile]: File target is not valid")
	local filename = SkillMgr.profilePath..strFile..".lua"
	local validJob = true
	
	--Load the file, which should only be the new type.
	local profile, e = persistence.load(filename)
	if (table.valid(profile)) then
		SkillMgr.ProfileRaw = profile
		if (table.valid(profile.classes)) then
			validJob = false
			for jobid,validity in pairs(profile.classes) do
				if (jobid == Player.job) then
					validJob = true
				end
			end
		end
		if (validJob) then			
			SkillMgr.SkillProfile = profile.skills
		end
		gSkillManagerMingp = IsNull(profile.mingp,0)
		gSkillManagerPrioSystem = IsNull(profile.priosystem,false)
	else
		SkillMgr.ProfileRaw = {}
		return false
	end
	
	SkillMgr.ResetSkillTracking()
	local filters = IsNull(profile.filters,{})
	gSkillManagerFilter1 = IsNull(filters[1],"")
	gSkillManagerFilter2 = IsNull(filters[2],"")
	gSkillManagerFilter3 = IsNull(filters[3],"")
	gSkillManagerFilter4 = IsNull(filters[4],"")
	gSkillManagerFilter5 = IsNull(filters[5],"")
	
	local classes = IsNull(profile.classes,{})
	gSkillProfileValidGLD = IsNull(classes[FFXIV.JOBS.GLADIATOR],false)
	gSkillProfileValidPLD = IsNull(classes[FFXIV.JOBS.PALADIN],false) 
	gSkillProfileValidPUG = IsNull(classes[FFXIV.JOBS.PUGILIST],false)
	gSkillProfileValidMNK = IsNull(classes[FFXIV.JOBS.MONK],false)
	gSkillProfileValidMRD = IsNull(classes[FFXIV.JOBS.MARAUDER],false) 
	gSkillProfileValidWAR = IsNull(classes[FFXIV.JOBS.WARRIOR],false) 
	gSkillProfileValidLNC = IsNull(classes[FFXIV.JOBS.LANCER],false) 
	gSkillProfileValidDRG = IsNull(classes[FFXIV.JOBS.DRAGOON],false) 
	gSkillProfileValidARC = IsNull(classes[FFXIV.JOBS.ARCHER],false) 
	gSkillProfileValidBRD = IsNull(classes[FFXIV.JOBS.BARD],false) 
	gSkillProfileValidCNJ = IsNull(classes[FFXIV.JOBS.CONJURER],false) 
	gSkillProfileValidWHM = IsNull(classes[FFXIV.JOBS.WHITEMAGE],false) 
	gSkillProfileValidTHM = IsNull(classes[FFXIV.JOBS.THAUMATURGE],false) 
	gSkillProfileValidBLM = IsNull(classes[FFXIV.JOBS.BLACKMAGE],false) 
	gSkillProfileValidACN = IsNull(classes[FFXIV.JOBS.ARCANIST],false) 
	gSkillProfileValidSMN = IsNull(classes[FFXIV.JOBS.SUMMONER],false) 
	gSkillProfileValidSCH = IsNull(classes[FFXIV.JOBS.SCHOLAR],false) 
	gSkillProfileValidROG = IsNull(classes[FFXIV.JOBS.ROGUE],false) 
	gSkillProfileValidNIN = IsNull(classes[FFXIV.JOBS.NINJA],false)
	gSkillProfileValidDRK = IsNull(classes[FFXIV.JOBS.DARKKNIGHT],false) 
	gSkillProfileValidMCH = IsNull(classes[FFXIV.JOBS.MACHINIST],false) 
	gSkillProfileValidAST = IsNull(classes[FFXIV.JOBS.ASTROLOGIAN],false) 
	gSkillProfileValidRDM = IsNull(classes[FFXIV.JOBS.REDMAGE],false) 
	gSkillProfileValidSAM = IsNull(classes[FFXIV.JOBS.SAMURAI],false) 
	gSkillProfileValidBLU = IsNull(classes[FFXIV.JOBS.BLUEMAGE],false) 
	gSkillProfileValidGNB = IsNull(classes[FFXIV.JOBS.GUNBREAKER],false) 
	gSkillProfileValidDNC = IsNull(classes[FFXIV.JOBS.DANCER],false) 
	
	gSkillProfileValidRPR = IsNull(classes[39],false) 
	gSkillProfileValidSGE = IsNull(classes[40],false) 
	
	gSkillProfileValidMIN = IsNull(classes[FFXIV.JOBS.MINER],false) 
	gSkillProfileValidBTN = IsNull(classes[FFXIV.JOBS.BOTANIST],false) 
	gSkillProfileValidFSH = IsNull(classes[FFXIV.JOBS.FISHER],false) 
	
	gSkillProfileValidCRP = IsNull(classes[FFXIV.JOBS.CARPENTER],false) 
	gSkillProfileValidBSM = IsNull(classes[FFXIV.JOBS.BLACKSMITH],false) 
	gSkillProfileValidARM = IsNull(classes[FFXIV.JOBS.ARMORER],false) 
	gSkillProfileValidGSM = IsNull(classes[FFXIV.JOBS.GOLDSMITH],false) 
	gSkillProfileValidLTW = IsNull(classes[FFXIV.JOBS.LEATHERWORKER],false) 
	gSkillProfileValidWVR = IsNull(classes[FFXIV.JOBS.WEAVER],false) 
	gSkillProfileValidALC = IsNull(classes[FFXIV.JOBS.ALCHEMIST],false) 
	gSkillProfileValidCUL = IsNull(classes[FFXIV.JOBS.CULINARIAN],false) 
	 
	local isdefault = false
	local startingProfiles = SkillMgr.StartingProfiles
	for job,name in pairs(startingProfiles) do
		if (strFile == name) then
			isdefault = true
			break
		end		
	end
	
	local extraProfiles = SkillMgr.ExtraProfiles
	for i,name in pairs(extraProfiles) do
		if (strFile == name) then
			isdefault = true
			break
		end		
	end

	SkillMgr.CheckProfileValidity()
	--[[if needsSave then
		SkillMgr.WriteToFile(gSkillProfile)
		d("saved")
	end]]
end

--All writes to the profiles should come through this function.
function SkillMgr.WriteToFile(strFile)
	assert(strFile and type(strFile) == "string" and strFile ~= "", "[SkillMgr.WriteToFile]: File target is not valid.")
	assert(not string.contains(strFile,"\\"), "[SkillMgr.WriteToFile]: File contains illegal characters.")
	
	local filename = SkillMgr.profilePath ..strFile..".lua"
	
	local info = {}
	info.version = 3
	SkillMgr.ResetSkillTracking()
	info.skills = deepcopy(SkillMgr.SkillProfile,true) or {}	
	if (table.valid(info.skills)) then
		
		local fieldDefaults = {}
		for fieldid, defaults in pairs(SkillMgr.Variables) do
			--d("checking field id ["..tostring(fieldid).."], ["..tostring(defaults.profile).."] ["..tostring(defaults.default).."]")
			fieldDefaults[defaults.profile] = defaults.default
		end
	
		for prio,skill in pairs(info.skills) do
			for field,fieldvalue in pairs(skill) do
				if (fieldvalue == fieldDefaults[field] or fieldDefaults[field] == nil) then
					--d("prio:"..tostring(prio)..", field:"..tostring(field)..", value:"..tostring(fieldvalue)..", default:"..tostring(fieldDefaults[field]))
					info.skills[prio][field] = nil
				end
			end
		end
	end
	info.mingp = gSkillManagerMingp
	info.priosystem = gSkillManagerPrioSystem
	info.filters = {
		[1] = gSkillManagerFilter1,
		[2] = gSkillManagerFilter2,
		[3] = gSkillManagerFilter3,
		[4] = gSkillManagerFilter4,
		[5] = gSkillManagerFilter5,
	}
	info.classes = {
		[FFXIV.JOBS.GLADIATOR] = IsNull(gSkillProfileValidGLD,false),
		[FFXIV.JOBS.PALADIN] = IsNull(gSkillProfileValidPLD,false),
		[FFXIV.JOBS.PUGILIST] = IsNull(gSkillProfileValidPUG,false),
		[FFXIV.JOBS.MONK] = IsNull(gSkillProfileValidMNK,false),
		[FFXIV.JOBS.MARAUDER] = IsNull(gSkillProfileValidMRD,false),
		[FFXIV.JOBS.WARRIOR] = IsNull(gSkillProfileValidWAR,false),
		[FFXIV.JOBS.LANCER] = IsNull(gSkillProfileValidLNC,false),
		[FFXIV.JOBS.DRAGOON] = IsNull(gSkillProfileValidDRG,false),
		[FFXIV.JOBS.ARCHER] = IsNull(gSkillProfileValidARC,false),
		[FFXIV.JOBS.BARD] = IsNull(gSkillProfileValidBRD,false),
		[FFXIV.JOBS.CONJURER] = IsNull(gSkillProfileValidCNJ,false),
		[FFXIV.JOBS.WHITEMAGE] = IsNull(gSkillProfileValidWHM,false),
		[FFXIV.JOBS.THAUMATURGE] = IsNull(gSkillProfileValidTHM,false),
		[FFXIV.JOBS.BLACKMAGE] = IsNull(gSkillProfileValidBLM,false),
		[FFXIV.JOBS.ARCANIST] = IsNull(gSkillProfileValidACN,false),
		[FFXIV.JOBS.SUMMONER] = IsNull(gSkillProfileValidSMN,false),
		[FFXIV.JOBS.SCHOLAR] = IsNull(gSkillProfileValidSCH,false),
		[FFXIV.JOBS.ROGUE] = IsNull(gSkillProfileValidROG,false),
		[FFXIV.JOBS.NINJA] = IsNull(gSkillProfileValidNIN,false),
		[FFXIV.JOBS.DARKKNIGHT] = IsNull(gSkillProfileValidDRK,false),
		[FFXIV.JOBS.MACHINIST] = IsNull(gSkillProfileValidMCH,false),
		[FFXIV.JOBS.ASTROLOGIAN] = IsNull(gSkillProfileValidAST,false),
		[FFXIV.JOBS.SAMURAI] = IsNull(gSkillProfileValidSAM,false),
		[FFXIV.JOBS.REDMAGE] = IsNull(gSkillProfileValidRDM,false),
		[FFXIV.JOBS.BLUEMAGE] = IsNull(gSkillProfileValidBLU,false),
		[FFXIV.JOBS.GUNBREAKER] = IsNull(gSkillProfileValidGNB,false),
		[FFXIV.JOBS.DANCER] = IsNull(gSkillProfileValidDNC,false), 
		
		[39] = IsNull(gSkillProfileValidRPR,false),
		[40] = IsNull(gSkillProfileValidSGE,false), 
		
		[FFXIV.JOBS.MINER] = IsNull(gSkillProfileValidMIN,false),
		[FFXIV.JOBS.BOTANIST] = IsNull(gSkillProfileValidBTN,false),
		[FFXIV.JOBS.FISHER] = IsNull(gSkillProfileValidFSH,false),
		
		[FFXIV.JOBS.CARPENTER] = IsNull(gSkillProfileValidCRP,false),
		[FFXIV.JOBS.BLACKSMITH] = IsNull(gSkillProfileValidBSM,false),
		[FFXIV.JOBS.ARMORER] = IsNull(gSkillProfileValidARM,false),
		[FFXIV.JOBS.GOLDSMITH] = IsNull(gSkillProfileValidGSM,false),
		[FFXIV.JOBS.LEATHERWORKER] = IsNull(gSkillProfileValidLTW,false),
		[FFXIV.JOBS.WEAVER] = IsNull(gSkillProfileValidWVR,false),
		[FFXIV.JOBS.ALCHEMIST] = IsNull(gSkillProfileValidALC,false),
		[FFXIV.JOBS.CULINARIAN] = IsNull(gSkillProfileValidCUL,false),
	}
	
	if (table.valid(SkillMgr.ProfileRaw)) then
		for k,v in pairs(SkillMgr.ProfileRaw) do
			if (info[k] == nil) then
				info[k] = v
			end
		end
	end
	
	persistence.store(filename,info)
end

-- For converting old messed up 32-bit crafting profiles to 64-bit.
function SkillMgr.LegacyConversion()
	--durabmin, durabmax, qualitymaxper, qualityminper, cpmax, cpmin, stepmin, stepmax, progrmax, progrmin, craftmax, craftmin, controlmax, controlmin, qualitymax, qualitymin, 
	
	local skills = SkillMgr.SkillProfile
	if (table.valid(skills)) then
		for prio,skill in pairsByKeys(skills) do
			
			local swap = skill.durabmin
			skill.durabmin = skill.durabmax
			skill.durabmax = swap
			
			local swap = skill.qualityminper
			skill.qualityminper = skill.qualitymaxper
			skill.qualitymaxper = swap
			
			local swap = skill.cpmin
			skill.cpmin = skill.cpmax
			skill.cpmax = swap
			
			local swap = skill.stepmin
			skill.stepmin = skill.stepmax
			skill.stepmax = swap
			
			local swap = skill.progrmin
			skill.progrmin = skill.progrmax
			skill.progrmax = swap
			
			local swap = skill.craftmin
			skill.craftmin = skill.craftmax
			skill.craftmax = swap
			
			local swap = skill.controlmin
			skill.controlmin = skill.controlmax
			skill.controlmax = swap
			
			local swap = skill.qualitymin
			skill.qualitymin = skill.qualitymax
			skill.qualitymax = swap
			
			skill.singleuseonly = false
			skill.consecutiveuseonly = false			
		end
	end
	
	SkillMgr.WriteToFile(gSkillProfile)
end

--[[
function SkillMgr.AceOnly()
	local startingProfiles = SkillMgr.StartingProfiles
	if (table.valid(startingProfiles)) then
		for jobid,profilename in pairs(startingProfiles) do
			d("Checking profile ["..tostring(profilename).."]")
			gSkillProfile = profilename
			local filename = SkillMgr.profilePath..profilename..".lua"
			local profile,e = persistence.load(filename)
			if (table.valid(profile)) then
				SkillMgr.SkillProfile = profile.skills
			end
			SkillMgr.ResetSkillTracking()
			SkillMgr.CheckProfileValidity()
		end
	end
	
	local extraProfiles = SkillMgr.ExtraProfiles
	if (table.valid(extraProfiles)) then
		for k,profilename in pairs(extraProfiles) do
			d("Checking profile ["..tostring(profilename).."]")
			gSkillProfile = profilename
			local filename = SkillMgr.profilePath..profilename..".lua"
			local profile,e = persistence.load(filename)
			if (table.valid(profile)) then
				SkillMgr.SkillProfile = profile.skills
			end
			SkillMgr.ResetSkillTracking()
			SkillMgr.CheckProfileValidity()
		end
	end
end
--]]

function SkillMgr.CheckProfileValidity()
	local profile = SkillMgr.SkillProfile
	
	local job = Player.job
	local requiredUpdate = false
	if (table.valid(profile)) then
		for prio,skill in pairsByKeys(profile) do
			local skID = tonumber(skill.id)
			local skType = tonumber(skill.type)
			local realskilldata = SkillMgr.GetAction(skID,skType)
			
			if (tonumber(skill.prio) ~= tonumber(prio)) then
				skill.prio = tonumber(prio)
				requiredUpdate = true
			end
			
			--First pass, make sure the profile has all the required conditionals.
			if (job >= 8 and job <= 15) then
				for k,v in pairs(SkillMgr.Variables) do
					if (v.section == "crafting" or v.section == "main") then
						if (skill[v.profile] == nil) then
							--d("missing ["..tostring(v.profile).."] on prio ["..tostring(prio).."]")
							if (v.useData ~= nil and realskilldata ~= nil) then
								skill[v.profile] = realskilldata[v.useData] or v.default
							else
								skill[v.profile] = v.default
							end
							requiredUpdate = true							
						end
					end
				end
			elseif (job >=16 and job <=17) then
				for k,v in pairs(SkillMgr.Variables) do
					if (v.section == "gathering" or v.section == "main") then
						if (skill[v.profile] == nil) then
							if (v.useData ~= nil and realskilldata ~= nil) then
								skill[v.profile] = realskilldata[v.useData] or v.default
							else
								skill[v.profile] = v.default
							end
							requiredUpdate = true
						end
					end
				end
			else
				for k,v in pairs(SkillMgr.Variables) do
					if (v.section == "fighting" or v.section == "main") then
						if (skill[v.profile] == nil) then
							if (v.useData ~= nil and realskilldata ~= nil) then
								skill[v.profile] = realskilldata[v.useData] or v.default
							else
								skill[v.profile] = v.default
							end
							requiredUpdate = true
						end
					end
				end
			end		
			
			--Second pass, make sure they are the correct types.
			for k,v in pairs(SkillMgr.Variables) do
				if (skill[v.profile] ~= nil) then
					if (type(skill[v.profile]) ~= v.cast) then
						if (v.cast == "number" and type(skill[v.profile]) ~= "number") then
							skill[v.profile] = IsNull(tonumber(skill[v.profile]),v.default)
							requiredUpdate = true
						elseif (v.cast == "string" and type(skill[v.profile]) ~= "string") then
							skill[v.profile] = IsNull(tostring(skill[v.profile]),v.default)
							requiredUpdate = true
						elseif (v.cast == "boolean" and type(skill[v.profile]) ~= "boolean") then
							skill[v.profile] = toboolean(skill[v.profile])
							requiredUpdate = true
						end
					end
				end
			end
		end
	end
	
	if (not deepcompare(SkillMgr.SkillProfile,profile,true)) then
		SkillMgr.SkillProfile = profile
	end
	
	-- No longer writing all defaults.
	--if (requiredUpdate) then
		--d("Profile required an update, resaving.")
		--SkillMgr.SaveProfile()
	--end
end

function SkillMgr.HasProfile(strName)
	if (table.valid(SkillMgr.profiles)) then
		for i,profileName in pairs(SkillMgr.profiles) do
			if (profileName == strName) then
				return true
			end
		end
	end
	return false
end

function SkillMgr.UseProfile(strName)
	gSkillProfile = strName
	gSkillProfileIndex = GetKeyByValue(gSkillProfile,SkillMgr.profiles) or 1
	if (SkillMgr.profiles[gSkillProfileIndex] ~= gSkillProfile) then
		gSkillProfile = SkillMgr.profiles[gSkillProfileIndex]
	end
	SkillMgr.UpdateCurrentProfileData()
end

--[[
function SkillMgr.ButtonHandler(event, Button)
    gSMRecactive = "0"
	if (event == "GUI.Item" and (string.contains(Button,"SKM") ~= nil or string.contains(Button,"SM") ~= nil )) then
	
		if (string.contains(Button,"SMDeleteEvent") ~= nil) then
			-- Delete the currently selected Profile - file from the HDD
			if (gSkillProfile ~= nil and gSkillProfile ~= "None" and gSkillProfile ~= "") then
				d("Deleting current Profile: "..gSkillProfile)
				os.remove(SkillMgr.profilePath ..gSkillProfile..".lua")	
				SkillMgr.UpdateProfiles()	
			end
		end
		
		if (string.contains(Button,"SMRefreshSkillbookEvent") ~= nil) then
			SkillMgr.SkillBook = {}
			GUI_DeleteGroup(SkillMgr.skillbook.name,"AvailableSkills")
			GUI_DeleteGroup(SkillMgr.skillbook.name,"MiscSkills")	
			SkillMgr.RefreshSkillBook()		
		end
        
		if (string.contains(Button,"SMEDeleteEvent") ~= nil) then
			if ( TableSize(SkillMgr.SkillProfile) > 0 ) then
				GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
				SkillMgr.SkillProfile = TableRemoveSort(SkillMgr.SkillProfile,tonumber(SKM_Prio))

				SkillMgr.RefreshSkillList()	
				GUI_WindowVisible(SkillMgr.editwindow.name,false)
				GUI_WindowVisible(SkillMgr.editwindow_crafting.name,false)	
				GUI_WindowVisible(SkillMgr.editwindow_gathering.name,false)
			end
		end

		if (string.contains(Button,"SMESkillUPEvent") ~= nil) then
			if ( TableSize(SkillMgr.SkillProfile) > 0 ) then
				if ( SKM_Prio > 1) then
					GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
					local tmp = SkillMgr.SkillProfile[SKM_Prio-1]
					SkillMgr.SkillProfile[SKM_Prio-1] = SkillMgr.SkillProfile[SKM_Prio]
					SkillMgr.SkillProfile[SKM_Prio-1].prio = SkillMgr.SkillProfile[SKM_Prio-1].prio - 1
					SkillMgr.SkillProfile[SKM_Prio] = tmp
					SkillMgr.SkillProfile[SKM_Prio].prio = SkillMgr.SkillProfile[SKM_Prio].prio + 1
					SKM_Prio = SKM_Prio-1
					SkillMgr.RefreshSkillList()				
				end
			end
		end
	
		if (string.contains(Button,"SMESkillDOWNEvent") ~= nil) then
			if ( TableSize(SkillMgr.SkillProfile) > 0 ) then
				if ( SKM_Prio < TableSize(SkillMgr.SkillProfile)) then
					GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")		
					local tmp = SkillMgr.SkillProfile[SKM_Prio+1]
					SkillMgr.SkillProfile[SKM_Prio+1] = SkillMgr.SkillProfile[SKM_Prio]
					SkillMgr.SkillProfile[SKM_Prio+1].prio = SkillMgr.SkillProfile[SKM_Prio+1].prio + 1
					SkillMgr.SkillProfile[SKM_Prio] = tmp
					SkillMgr.SkillProfile[SKM_Prio].prio = SkillMgr.SkillProfile[SKM_Prio].prio - 1
					SKM_Prio = SKM_Prio+1
					SkillMgr.RefreshSkillList()						
				end
			end
		end
	
		if (string.contains(Button,"SKMEditSkill") ~= nil) then
			local key = Button:gsub("SKMEditSkill", "")
			SkillMgr.EditSkill(key)
		end
		if (string.contains(Button,"SKMClearProfile") ~= nil) then
			local key = Button:gsub("SKMClearProfile", "")
			SkillMgr.ClearProfile(key)
		end
		if (string.contains(Button,"SKMAddSkill") ~= nil) then
			local key = Button:gsub("SKMAddSkill", "")
			SkillMgr.AddSkillToProfile(1,key)
		end
		if (string.contains(Button,"SKMAddPetSkill") ~= nil) then
			local key = Button:gsub("SKMAddPetSkill", "")
			SkillMgr.AddSkillToProfile(11,key)
		end
		if (string.contains(Button,"SKMAddCraftSkill") ~= nil) then
			local key = Button:gsub("SKMAddCraftSkill", "")
			SkillMgr.AddSkillToProfile(9,key)
		end
		if (string.contains(Button,"SKMCopySkill") ~= nil) then
			SkillMgr.CopySkill()
		end
		if (string.contains(Button,"SKMPasteSkill") ~= nil) then
			SkillMgr.PasteSkill()
		end
		
		if (string.contains(Button,"SMToggleBuffs") ~= nil) then	
			SkillMgr.ToggleBuffMenu()		
		end
		if (string.contains(Button,"SMToggleMacro") ~= nil) then	
			SkillMgr.ToggleMacroMenu()		
		end
	elseif (string.contains(Button,"SkillMgr%.")) then
		ExecuteFunction(Button)
	end
end
--]]

function SkillMgr.SaveProfile()
    local filename = ""
    if (gSkillProfile ~= nil and gSkillProfile ~= "None" and gSkillProfile ~= "") then
        filename = gSkillProfile
        gSMnewname = ""		
		
		SkillMgr.WriteToFile(filename)
    end
end

function SkillMgr.SetDefaultProfile(strName)
	local uuid = GetUUID()
	local profile = strName or gSkillProfile
	
	Settings.FFXIVMINION.gSMDefaultProfiles[uuid][Player.job] = profile
	gSMDefaultProfiles = Settings.FFXIVMINION.gSMDefaultProfiles[uuid]
end

function SkillMgr.UseDefaultProfile()
	local defaultTable = gSMDefaultProfiles
	local default = nil
	
	--Try default profile first.
	if (table.valid(defaultTable)) then
		default = defaultTable[Player.job]
	end
	
	if (not default) then
		local starterDefault = SkillMgr.StartingProfiles[Player.job]
		if ( starterDefault ) then
			local filePath = SkillMgr.profilePath..starterDefault..".lua"
			if (FileExists(filePath)) then
				d("No default profile set, using start default ["..tostring(starterDefault).."]")
				SkillMgr.SetDefaultProfile(starterDefault)
				default = starterDefault
			end
		end
	end
	
	local profileName = IsNull(default,"None")
	SkillMgr.UseProfile(profileName)
end

--Grasb all Profiles and enlist them in the dropdown field
function SkillMgr.UpdateProfiles()
	SkillMgr.profiles = {GetString("none")}
    local profileList = FolderList(SkillMgr.profilePath,[[(.*)lua$]])
    if (table.valid(profileList)) then		
		for i,profile in pairs(profileList) do
            profileName = string.gsub(profile, ".lua", "")
			table.insert(SkillMgr.profiles,profileName)
			
			-- Don't uncomment unless you want to run a mass update.
			--[[
			SkillMgr.ReadFile(profileName)
			SkillMgr.WriteToFile(profileName)
			--]]
        end	
    end
	--table.print(SkillMgr.profiles)
end

function SkillMgr.CopySkill(prio)
	d("COPYING SKILL #:"..tostring(prio))
	local source = SkillMgr.SkillProfile[tonumber(prio)]
	SkillMgr.copiedSkill = {}
	local temp = {}
	for k,v in pairs(SkillMgr.Variables) do
		if (v.section ~= "main" and source[v.profile] ~= nil) then
			temp[k] = source[v.profile]
		end
	end
	SkillMgr.copiedSkill = temp
end

function SkillMgr.PasteSkill(prio)
	d("PASTING INTO SKILL #:"..tostring(prio))
	local source = SkillMgr.copiedSkill
	for k,v in pairs(SkillMgr.copiedSkill) do
		if (SkillMgr.Variables[k] ~= nil) then
			skillVar = SkillMgr.Variables[varName]
			SkillMgr.SkillProfile[prio][skillVar.profile] = v
		end
	end
	SkillMgr.SaveProfile()
end

function SkillMgr.UpdateCurrentProfileData()
	SkillMgr.SkillProfile = {}
	if (gSkillProfile ~= GetString("none")) then
		SkillMgr.ReadFile(gSkillProfile)
	end
end

--+Rebuilds the UI Entries for the SkillbookList

--[[
function SkillMgr.RefreshSkillBook()
	local job = Player.job
	
    local SkillList = ActionList("type=1,minlevel=1")
    if ( table.valid( SkillList ) ) then
		for i,skill in spairs(SkillList, function( skill,a,b ) return skill[a].name < skill[b].name end) do
			SkillMgr.CreateNewSkillBookEntry(i)
		end
    end
	
	local SkillList = ActionList("type=1,level=0")
    if ( table.valid( SkillList ) ) then
		for i,skill in spairs(SkillList, function( skill,a,b ) return skill[a].name < skill[b].name end) do
			if (skill.level == 0) then
				SkillMgr.CreateNewSkillBookEntry(i, 1, "MiscSkills")
			end
		end
    end
 
	--summoning pet skills
	if ( job >= 26 ) then
		SkillList = ActionList("type=11")
		if ( table.valid( SkillList) ) then
			for i,skill in spairs(SkillList, function( skill,a,b ) return skill[a].name < skill[b].name end) do
				local actionlvl = skill.level
				if (actionlvl == nil or actionlvl < 0) then actionlvl = 0 end
				if (Player.level >= actionlvl) then
					SkillMgr.CreateNewSkillBookEntry(i, 11, "Pets")
				end
			end
		end	
	end
	
	--craftingskills
    if ( job >= 8 and job <=15 ) then
		local SkillList = ActionList("type=9")
		if ( table.valid( SkillList ) ) then
			for i,skill in spairs(SkillList, function( skill,a,b ) return skill[a].name < skill[b].name end) do
				SkillMgr.CreateNewSkillBookEntry(i, 9)
			end
		end
    end

    GUI_UnFoldGroup(SkillMgr.skillbook.name,"AvailableSkills")
end
--]]

--+Rebuilds the UI Entries for the Profile-SkillList
--[[
function SkillMgr.RefreshSkillList()
	GUI_DeleteGroup(SkillMgr.mainwindow.name,"ProfileSkills")
    if ( TableSize( SkillMgr.SkillProfile ) > 0 ) then
		for prio,skill in pairsByKeys(SkillMgr.SkillProfile) do
			local viewString = ""
			if (skill.id ~= nil and tonumber(skill.id) ~= nil) then
				local clientSkill = nil;
				if (skill.type ~= nil) then
					clientSkill = SkillMgr.GetAction(skill.id,skill.type)
				end
				local skillFound = table.valid(clientSkill)
				
				if (not IsNullString(skill.alias)) then
					viewString = tostring(prio)..": "..skill.alias.." ["..tostring(TranslateAction(skill.id,skill.type)).."]["..tostring(skill.id).."]"
				else
					viewString = tostring(prio)..": "..tostring(TranslateAction(skill.id,skill.type)).." ["..tostring(skill.id).."]"
				end
				if (not skillFound) then
					viewString = "***"..viewString.."***"
				end
			else
				if (not IsNullString(skill.alias)) then
					viewString = tostring(prio)..": "..skill.alias.." ["..tostring(skill.id).."]"
				else
					if (skill.name ~= nil) then
						viewString = tostring(prio)..": "..skill.name.." ["..tostring(skill.id).."]"
					else
						viewString = "#ERROR#"
					end
				end
			end
			GUI_NewButton(SkillMgr.mainwindow.name, viewString, "SKMEditSkill"..tostring(prio),"ProfileSkills")
		end
		GUI_UnFoldGroup(SkillMgr.mainwindow.name,"ProfileSkills")
		
		SkillMgr.highestRange = 0
		SkillMgr.highestRangeSkills = {}
		
		for prio,skill in pairs(SkillMgr.SkillProfile) do
			if (skill.used  and skill.stype == "Action") then
				local levelmin = tonumber(skill.levelmin) or 0
				local levelmax = tonumber(skill.levelmax) or 0
				local mylevel = Player.level
				
				if ((levelmin == 0 or (levelmin > 0 and levelmin <= mylevel)) and
					(levelmax == 0 or (levelmax > 0 and levelmax >= mylevel)))
				then
					local skilldata = SkillMgr.GetAction(tonumber(skill.id),1)
					if (skilldata) then
						--d("do nothing")
						if (skilldata.range > 0) then
							if (skilldata.range > SkillMgr.highestRange) then
								SkillMgr.highestRange = skilldata.range
								SkillMgr.highestRangeSkills = {}
								table.insert(SkillMgr.highestRangeSkills,tonumber(skill.id))
							elseif (skilldata.range == SkillMgr.highestRange) then
								table.insert(SkillMgr.highestRangeSkills,tonumber(skill.id))
							end							
						end						
					end
				end
			end
		end
    end
end
--]]

function SkillMgr.ResetSkillTracking()
	local skills = SkillMgr.SkillProfile
	if (table.valid(skills)) then
		for prio,skill in pairs(skills) do
			skill.lastcast = 0
			skill.lastcastunique = {}
		end
	end
end

function SkillMgr.AddSkillToProfile(skill)
	assert(type(skill) == "table", "AddSkillToProfile was called with a non-table value.")
	
	if (not skill.name or not skill.id or not skill.type) then
		return false
	end
	
	local skName = skill.name
	local skID = tonumber(skill.id)
	local skType = tonumber(skill.type) or 1
	local realskilldata = skill
	local job = Player.job
	local newskillprio = TableSize(SkillMgr.SkillProfile)+1

	SkillMgr.SkillProfile[newskillprio] = {	["id"] = skID, ["prio"] = newskillprio, ["name"] = skName, ["used"] = true, ["alias"] = "", ["type"] = skType }
	if (job >= 8 and job <= 15) then
		for k,v in pairs(SkillMgr.Variables) do
			if (v.section == "crafting") then
				if (v.useData) then
					SkillMgr.SkillProfile[newskillprio][v.profile] = realskilldata[v.useData] or v.default
				else
					SkillMgr.SkillProfile[newskillprio][v.profile] = skill[v.profile] or v.default
				end
			end
		end
	elseif (job >=16 and job <=17) then
		for k,v in pairs(SkillMgr.Variables) do
			if (v.section == "gathering") then
				if (v.useData) then
					SkillMgr.SkillProfile[newskillprio][v.profile] = realskilldata[v.useData] or v.default
				else
					SkillMgr.SkillProfile[newskillprio][v.profile] = skill[v.profile] or v.default
				end
			end
		end
	else
		for k,v in pairs(SkillMgr.Variables) do
			if (v.section == "fighting") then
				if (v.profile == "stype") then
					if (skType == 11) then
						SkillMgr.SkillProfile[newskillprio][v.profile] = GetString("Pet")
					else
						SkillMgr.SkillProfile[newskillprio][v.profile] = "Action"
					end
				else
					if (v.useData) then
						SkillMgr.SkillProfile[newskillprio][v.profile] = realskilldata[v.useData] or v.default
					else
						SkillMgr.SkillProfile[newskillprio][v.profile] = skill[v.profile] or v.default
					end
				end
			end
		end
	end	
	
	SkillMgr.SaveProfile()
end	

--[[
function SkillMgr.AddItemToSkills()
	local job = Player.job
	local newskillprio = TableSize(SkillMgr.SkillProfile)+1

	SkillMgr.SkillProfile[newskillprio] = {	["id"] = 0, ["prio"] = newskillprio, ["name"] = "", ["used"] = "1", ["alias"] = "", ["type"] = -1 }
	if (job >= 8 and job <= 15) then
		return
	elseif (job >=16 and job <=17) then
		return
	else
		for k,v in pairs(SkillMgr.Variables) do
			if (v.section == "fighting") then
				if (v.profile == "stype") then
					SkillMgr.SkillProfile[newskillprio][v.profile] = "Item"
				else
					SkillMgr.SkillProfile[newskillprio][v.profile] = skill[v.profile] or v.default
				end
			end
		end
	end	
	SkillMgr.RefreshSkillList()
end	
--]]

--[[
function SkillMgr.AddTextCommandToSkills()
	local job = Player.job
	local newskillprio = TableSize(SkillMgr.SkillProfile)+1

	SkillMgr.SkillProfile[newskillprio] = {	["id"] = 0, ["prio"] = newskillprio, ["name"] = "", ["used"] = "1", ["alias"] = "", ["type"] = -2 }
	if (job >= 8 and job <= 15) then
		return
	elseif (job >=16 and job <=17) then
		return
	else
		for k,v in pairs(SkillMgr.Variables) do
			if (v.section == "fighting") then
				if (v.profile == "stype") then
					SkillMgr.SkillProfile[newskillprio][v.profile] = "Text Command"
				else
					SkillMgr.SkillProfile[newskillprio][v.profile] = skill[v.profile] or v.default
				end
			end
		end
	end	
	SkillMgr.RefreshSkillList()
end	
--]]

--+	Button Handler for ProfileList Skills
--[[
function SkillMgr.EditSkill(event)
    local wnd = GUI_GetWindowInfo(SkillMgr.mainwindow.name)		
	
    local job = Player.job
    if ( job >= 8 and job <=15 ) then
        -- Crafting Editor 
        GUI_MoveWindow( SkillMgr.editwindow_crafting.name, wnd.x+wnd.width,wnd.y) 
        GUI_WindowVisible(SkillMgr.editwindow_crafting.name,true)
        -- Update EditorData
        local skill = SkillMgr.SkillProfile[tonumber(event)]        
        if ( skill ) then
			for k,v in pairs(SkillMgr.Variables) do
				if (v.section == "main") then
					_G[k] = skill[v.profile] or v.default
				end
			end
			for k,v in pairs(SkillMgr.Variables) do
				if (v.section == "crafting") then
					_G[k] = skill[v.profile] or v.default
				end
			end
        end        
    elseif ( job >= 16 and job <=17 ) then
        -- Gathering Editor 
        GUI_MoveWindow( SkillMgr.editwindow_gathering.name, wnd.x+wnd.width,wnd.y) 
        GUI_WindowVisible(SkillMgr.editwindow_gathering.name,true)
        -- Update EditorData
        local skill = SkillMgr.SkillProfile[tonumber(event)]        
        if ( skill ) then                
            for k,v in pairs(SkillMgr.Variables) do
				if (v.section == "main") then
					_G[k] = skill[v.profile] or v.default
				end
			end
			for k,v in pairs(SkillMgr.Variables) do
				if (v.section == "gathering") then
					_G[k] = skill[v.profile] or v.default
				end
			end
        end        
    else        
        -- Normal Editor 
        GUI_MoveWindow( SkillMgr.editwindow.name, wnd.x+wnd.width,wnd.y) 
        GUI_WindowVisible(SkillMgr.editwindow.name,true)
        -- Update EditorData
        local skill = SkillMgr.SkillProfile[tonumber(event)]	
        if ( skill ) then		
            for k,v in pairs(SkillMgr.Variables) do
				if (v.section == "main") then
					_G[k] = skill[v.profile] or v.default
				end
			end
			for k,v in pairs(SkillMgr.Variables) do
				if (v.section == "fighting") then
					_G[k] = skill[v.profile] or v.default
				end
			end
        end
    end
	
	SKM_Prio = tonumber(event)
end
--]]

--[[
function SkillMgr.ToggleMenu()
    if (SkillMgr.visible) then
        GUI_WindowVisible(SkillMgr.mainwindow.name,false)	
        GUI_WindowVisible(SkillMgr.skillbook.name,false)	
        GUI_WindowVisible(SkillMgr.editwindow.name,false)	
        GUI_WindowVisible(SkillMgr.editwindow_crafting.name,false)
        GUI_WindowVisible(SkillMgr.editwindow_gathering.name,false)	
		GUI_WindowVisible(SkillMgr.confirmwindow.name,false)
        SkillMgr.visible = false
    else
		SkillMgr.RefreshSkillBook()
		GUI_SizeWindow(SkillMgr.skillbook.name,SkillMgr.skillbook.w,SkillMgr.skillbook.h)
		SkillMgr.RefreshSkillList()
		GUI_SizeWindow(SkillMgr.mainwindow.name,SkillMgr.mainwindow.w,SkillMgr.mainwindow.h)
        GUI_WindowVisible(SkillMgr.skillbook.name,true)
        GUI_WindowVisible(SkillMgr.mainwindow.name,true)	
        SkillMgr.visible = true
    end
end

function SkillMgr.ToggleMacroMenu()
    if (SkillMgr.editwindow_macro.visible) then
		local wnd = GUI_GetWindowInfo(SkillMgr.editwindow.name)	
		GUI_MoveWindow(SkillMgr.editwindow_macro.name, wnd.x+wnd.width,wnd.y) 
        GUI_WindowVisible(SkillMgr.editwindow_macro.name,false)	
        SkillMgr.editwindow_macro.visible = false
    else
		GUI_WindowVisible(SkillMgr.editwindow_macro.name,true)		
        SkillMgr.editwindow_macro.visible = true
    end
end

function SkillMgr.ToggleBuffMenu()
    if (SkillMgr.editwindow_buff.visible) then
		local wnd = GUI_GetWindowInfo(SkillMgr.editwindow.name)	
		GUI_MoveWindow(SkillMgr.editwindow_buff.name, wnd.x+wnd.width,wnd.y) 
        GUI_WindowVisible(SkillMgr.editwindow_buff.name,false)	
        SkillMgr.editwindow_buff.visible = false
    else
		GUI_WindowVisible(SkillMgr.editwindow_buff.name,true)		
        SkillMgr.editwindow_buff.visible = true
    end
end
--]]
function SkillMgr.ShowFilterWindow()
	SkillMgr.GUI.filters.open = true		
end

function SkillMgr.GetCooldown(action)
	if (action) then
		if (GetVersion() == 32) then
			return (action.cd - action.cdmax)
		else
			return (action.cdmax - action.cd)
		end
	end
	return nil
end

function SkillMgr.IsPetSummonSkill(skillID)
    if (skillID == 165 or
		skillID == 150 or
        skillID == 170 or
        skillID == 180 or
		skillID == 2864 or
		skillID == 2865) 
	then
        return true
    end
    return false
end

function SkillMgr.IsPetSummonActive(skillID)
	local contentids = {
		[2864] = "3666",
		[2865] = "3667",
		[165] = "1404;1398;1401",
		[170] = "1403;1399;1400",
		[180] = "1402",
	}
	
	if (table.valid(Player.pet)) then
		return true
	end
	
	local petstring = contentids[skillID]
	if (petstring) then
		local el = EntityList("ownerid="..tostring(Player.id)..",contentid="..petstring)
		if (table.valid(el)) then
			local i,entity = next(el)
			if (i and entity) then
				return true
			end
		end
	end

    return false
end

function SkillMgr.IsSummoningPet()
	if (Player.action == 188 or Player.action == 189) then
		return true
	end
	return false
end

function SkillMgr.IsReviveSkill(skillID)
    if (skillID == 173 or skillID == 125 or skillID == 3603 or skillID == 18317) then
        return true
    end
    return false
end

function SkillMgr.UpdateLastCast(skillid)
	local skillid = tonumber(skillid) or 0
	
	if (table.valid(SkillMgr.SkillProfile)) then
		for prio,skill in pairsByKeys(SkillMgr.SkillProfile) do
			if (tonumber(skill.id) == skillid) then
				SkillMgr.SkillProfile[prio].lastcast = Now()
				
				if (SkillMgr.throw[skillid]) then
					local catch = SkillMgr.throw[skillid]
					if (Now() < catch.expiration) then
						if (not table.valid(SkillMgr.SkillProfile[prio].lastcastunique)) then
							SkillMgr.SkillProfile[prio].lastcastunique = {}
						end
						SkillMgr.SkillProfile[prio].lastcastunique[catch.targetid] = Now()
					else
						SkillMgr.throw[skillid] = nil
					end
				end
			end
		end
	end
end

function SkillMgr.IsMinuetAffected(skillid)
	local skillid = tonumber(skillid) or 0
	local affectedSkills = {
		[97] = "HeavyShot",
		[98] = "StraightShot",
		[100] = "VenomousBite",
		[106] = "QuickNock",
		[111] = "WideVolley",
		[113] = "Windbite",
		[3558] = "EmpyrealArrow",
		[3560] = "IronJaws"
	}
	
	return affectedSkills[skillid]
end

function SkillMgr.IsGaussAffected(skillid)
	local skillid = tonumber(skillid) or 0
	local affectedSkills = {
		[2866] = "Split Shot",
		[2872] = "Hot Shot",
		[2869] = "Lead Shot",
		[2870] = "Spread Shot",
		[2871] = "Grenado Shot"
	}
	
	return affectedSkills[skillid]
end

function SkillMgr.IsCasting(entity, actionIDs , minCasttime , targetid) 
	local ci = entity.castinginfo 
	local minCasttime = minCasttime or 0
	
	if ( ci == nil or ci.channelingid == 0 ) then return false end
	
	if ( minCasttime > 0 ) then
		if (ci.channeltime < minCasttime ) then 
			return false 
		elseif (ci.channeltime >= minCasttime and actionIDs == "") then
			return true
		end
	end
	if ( targetid ~= nil and ci.channeltargetid ~= targetid ) then return false end
	
	if (IsNull(actionIDs,"") ~= "") then
		for _orids in StringSplit(actionIDs,",") do
			if (tonumber(_orids) == ci.channelingid) then
				return true
			end
		end
	end

	return false
end

function SkillMgr.UpdateChain(prio,castedskill)
	local prio = tonumber(prio) or 0
	local castedskill = tonumber(castedskill) or 0
	
	if (prio ~= 0 and castedskill ~= 0) then
		if (table.valid(SkillMgr.SkillProfile)) then
			local thisSkill = SkillMgr.SkillProfile[prio]
			if (table.valid(thisSkill) and (thisSkill.id == castedskill or (IsNinjutsuSkill(thisSkill.id) and IsNinjutsuSkill(castedskill)))) then
				if (thisSkill.chainstart ) then
					SkillMgr.currentChain = thisSkill.chainname
					d("Starting chain ["..tostring(SkillMgr.currentChain).."]")
					return true
				elseif (thisSkill.chainend ) then
					d("Ending chain ["..tostring(SkillMgr.currentChain).."]")
					SkillMgr.currentChain = ""
					return true
				end
			else
				return false
			end
		end
	end
	
	return false
end

function SkillMgr.GetTankableTarget( range )
	local range = range or ml_global_information.AttackRange
	local closest = nil
	local closestRange = 100
	local targets = {}
	
	local party = EntityList("myparty,chartype=4")
	if (table.valid(party)) then
		for i,member in pairs(party) do
			if (member.id ~= Player.id) then
				local list = EntityList("nearest,alive,attackable,targeting="..tostring(member.id)..",maxdistance2d="..tostring(range))
				if (table.valid(list)) then
					for k,entity in pairs(list) do
						targets[k] = entity
					end
				end
			end
		end
	end
	
	if (table.valid(targets)) then
		for k,entity in pairs(targets) do
			if (not closest or (closest and entity.distance2d < closestRange)) then
				closest = entity
				closestRange = entity.distance2d
			end
		end
		
		return closest
	end
	
	return nil
end

function SkillMgr.GetTankedTarget( range )
	local range = range or ml_global_information.AttackRange
	local closest = nil
	local closestRange = 100
	local tanks = {}
	local targets = {}

    local party = EntityList("chartype=4,myparty")
    if ( table.valid(party) ) then
		for i,e in pairs(party) do
			if (IsTank(e.job)) then
				tanks[i] = e
			end
        end
    end
	
	if (table.valid(tanks)) then
		for i,tank in pairs(tanks) do
			local list = EntityList("nearest,alive,attackable,targeting="..tostring(tank.id)..",maxdistance2d="..tostring(range))
			if (table.valid(list)) then
				for k,entity in pairs(list) do
					targets[k] = entity
				end
			end
		end
	end
	
	if (table.valid(targets)) then
		for i,target in pairs(targets) do
			if (not closest or (closest and closest.distance2d < closestRange)) then
				closest = target
				closestRange = target.distance2d
			end
		end
		
		return closest
	end
	
	return nil
end

function SkillMgr.Cast( entity , preCombat, forceStop )
	preCombat = IsNull(preCombat,false)
	forceStop = IsNull(forceStop,false)
	
	if (SkillMgr.IsYielding()) then
		return false
	end
	
	SkillMgr.CheckMonitor()
	
	if (not entity or IsFlying() or table.valid(SkillMgr.receivedMacro)) then
		return false
	end
	
	--This call is here to refresh the action list in case new skills are equipped.
	if (SkillMgr.SkillProfile) then
		
		local testSkill = SkillMgr.GetAction(SkillMgr.GCDSkills[Player.job],1)
		local testSkillPVP = SkillMgr.GetAction(SkillMgr.GCDSkillsPVP[Player.job],1)
		if (testSkill) then
			SkillMgr.gcdTime = testSkill.recasttime
		elseif (testSkillPVP) then
			SkillMgr.gcdTime = testSkillPVP.recasttime
		end
	
		-- Start Main Loop
		local casted = false
		for prio,skill in pairsByKeys(SkillMgr.SkillProfile) do
			
			if (skill.stype == "Macro" or skill.stype == "Action") then
				local result = SkillMgr.CanCast(prio, entity, preCombat)
				if (result ~= 0) then
					local TID = result
					
					if (skill.stype == "Macro") then
						local macro = {}
						
						for i=1,20 do
							local mid = skill["m"..tostring(i).."actionid"]
							if (tonumber(mid) and tonumber(mid) ~= 0) then
							
								local mtargetfunc = skill["m"..tostring(i).."actiontarget"]
								local mtargetmsg = skill["m"..tostring(i).."actionmsg"] or ""
								local mtargetcomplete = skill["m"..tostring(i).."actioncomplete"] or ""
								
								local instruction = { "Action", {mid, 1, mtargetfunc, mtargetmsg, mtargetcomplete }}
								local mwait = tonumber(skill["m"..tostring(i).."actionwait"]) or 100
								local waitInstruction = { "Wait", { mwait }}
								table.insert(macro,instruction)
								table.insert(macro,waitInstruction)
							else
								break
							end
						end
						
						SkillMgr.ParseMacro(macro)
						
						casted = true
						break
						
					elseif (skill.stype == "Action") then
						if (skill.trg == GetString("Ground Target")) then
						
							local action = SkillMgr.GetAction(skill.id,1)
							local entity = MGetEntity(TID)
							local tpos = entity.pos
							if (entity) then
								if (action:Cast(tpos.x, tpos.y, tpos.z)) then
									SkillMgr.latencyTimer = Now()
									
									local castingskill = Player.castinginfo.lastcastid
									if (castingskill == action.id or (IsNinjutsuSkill(castingskill) and IsNinjutsuSkill(action.id))) then
										SkillMgr.prevSkillID = castingskill
										SkillMgr.prevSkillTimestamp = Now()
										if (math.abs(SkillMgr.gcdTime - action.recasttime) <= .1) then
											SkillMgr.prevGCDSkillID = castingskill
										end
										SkillMgr.UpdateLastCast(castingskill)
										if (SkillMgr.UpdateChain(prio,castingskill)) then
											SkillMgr.queuedPrio = 0
										end
										SkillMgr.failTimer = Now() + 6000
									else
										if (skill.chainstart  or skill.chainend ) then
											SkillMgr.queuedPrio = prio
										end
									end
									
									casted = true
									break
								end
							end
						else
							local action = SkillMgr.GetAction(skill.id,1)
							local entity = MGetEntity(TID)
							
							if (table.valid(action)) then
								--d("Attempting to cast skill ["..tostring(prio).."]:"..tostring(action.name).." on "..tostring(entity.name))
								--if (gSkillManagerQueueing ) then
									--SkillMgr.DebugOutput(prio, "Attempting to cast skill:"..tostring(action.name))
								--end
								--if (ActionList:Cast(skill.id,TID,1)) then
								if (action:Cast(TID)) then
									SkillMgr.latencyTimer = Now()
									
									-- If we want to try the unique last cast, throw it to the stack.
									if (IsNull(tonumber(skill.secspassedu),0) > 0) then
										SkillMgr.throw[action.id] = { 
											expiration = Now() + 2500,  
											targetid = TID,
											prio = prio,
										}
									end
								
									local castingskill = Player.castinginfo.lastcastid
									if (castingskill == action.id or (IsNinjutsuSkill(castingskill) and IsNinjutsuSkill(action.id))) then
										--d(tostring(action.name).." was detected immediately.")
										--d("Setting previous skill ID to :"..tostring(castingskill).."["..action.name.."]")
										SkillMgr.prevSkillID = castingskill
										SkillMgr.prevSkillTimestamp = Now()
										if (math.abs(SkillMgr.gcdTime - action.recasttime) <= .1) then
											SkillMgr.prevGCDSkillID = castingskill
										end
										SkillMgr.UpdateLastCast(castingskill)
										if (SkillMgr.UpdateChain(prio,castingskill)) then
											SkillMgr.queuedPrio = 0
										end
										SkillMgr.failTimer = Now() + 6000
									else
										if (skill.chainstart or skill.chainend ) then
											SkillMgr.queuedPrio = prio
										end
									end
									
									casted = true
									break
								--else
									--if (gSkillManagerQueueing ) then
										--SkillMgr.DebugOutput(prio, "Skill failed to cast.")
									--end
								end
							end
						end
					end
					
					break
				end
			end
		end
		-- End Main Loop
		
		-- Start Pet Loop
		for prio,skill in pairsByKeys(SkillMgr.SkillProfile) do
			if (skill.stype == GetString("Pet")) then	
			
				local result = SkillMgr.CanCast(prio, entity, preCombat)
				if (result ~= 0) then
					local TID = result
					
					if (skill.trg == GetString("Ground Target")) then
					
						local s = SkillMgr.GetAction(skill.id,11)
						local entity = MGetEntity(TID)
						
						if (entity) then
							local tpos = entity.pos							
							if (s:Cast(tpos.x, tpos.y, tpos.z)) then
								if (SkillMgr.SkillProfile[prio]) then
									SkillMgr.SkillProfile[prio].lastcast = Now()
								else
									d("An error occurred setting last cast.  Priority " .. prio .. " seems to be missing.")
								end
							end
						end
					else
						local s = SkillMgr.GetAction(skill.id,11)
						SkillMgr.DebugOutput(prio, "Grabbed pet skill:"..tostring(s.name).." to cast on target ID :"..tostring(TID))
						if (s:Cast(TID)) then
							if (SkillMgr.SkillProfile[prio]) then
								SkillMgr.SkillProfile[prio].lastcast = Now()
							else
								d("An error occurred setting last cast.  Priority " .. prio .. " seems to be missing.")
							end
						end
					end
				end
			end
		end		
		
		return casted
		-- End Pet Loop
	end
end

if (GetGameRegion() == 1) then
	SkillMgr.MatchingCraftSkills = {
		["Basic Synthesis"] = { [8] = 100001, [9] = 100015, [10] = 100030, [11] = 100075, [12] = 100045, [13] = 100060, [14] = 100090, [15] = 100105, },
		["Basic Touch"] = { [8] = 100002, [9] = 100016, [10] = 100031, [11] = 100076, [12] = 100046, [13] = 100061, [14] = 100091, [15] = 100106, },
		["Brand of the Elements"] = { [8] = 100331, [9] = 100332, [10] = 100333, [11] = 100334, [12] = 100335, [13] = 100336, [14] = 100337, [15] = 100338, },
		["Byregot's Blessing"] = { [8] = 100339, [9] = 100340, [10] = 100341, [11] = 100342, [12] = 100343, [13] = 100344, [14] = 100345, [15] = 100346, },
		["Careful Observation"] = { [8] = 100395, [9] = 100396, [10] = 100397, [11] = 100398, [12] = 100399, [13] = 100400, [14] = 100401, [15] = 100402, },
		["Careful Synthesis"] = { [8] = 100203, [9] = 100204, [10] = 100205, [11] = 100206, [12] = 100207, [13] = 100208, [14] = 100209, [15] = 100210, },
		["Delicate Synthesis"] = { [8] = 100323, [9] = 100324, [10] = 100325, [11] = 100326, [12] = 100327, [13] = 100328, [14] = 100329, [15] = 100330, },
		["Final Appraisal"] = { [8] = 19012, [9] = 19013, [10] = 19014, [11] = 19015, [12] = 19016, [13] = 19017, [14] = 19018, [15] = 19019, },
		["Focused Synthesis"] = { [8] = 100235, [9] = 100236, [10] = 100237, [11] = 100238, [12] = 100239, [13] = 100240, [14] = 100241, [15] = 100242, },
		["Focused Touch"] = { [8] = 100243, [9] = 100244, [10] = 100245, [11] = 100246, [12] = 100247, [13] = 100248, [14] = 100249, [15] = 100250, },
		["Great Strides"] = { [8] = 260, [9] = 261, [10] = 262, [11] = 263, [12] = 265, [13] = 264, [14] = 266, [15] = 267, },
		["Hasty Touch"] = { [8] = 100355, [9] = 100356, [10] = 100357, [11] = 100358, [12] = 100359, [13] = 100360, [14] = 100361, [15] = 100362, },
		["Inner Quiet"] = { [8] = 252, [9] = 253, [10] = 254, [11] = 255, [12] = 257, [13] = 256, [14] = 258, [15] = 259, },
		["Innovation"] = { [8] = 19004, [9] = 19005, [10] = 19006, [11] = 19007, [12] = 19008, [13] = 19009, [14] = 19010, [15] = 19011, },
		["Intensive Synthesis"] = { [8] = 100315, [9] = 100316, [10] = 100317, [11] = 100318, [12] = 100319, [13] = 100320, [14] = 100321, [15] = 100322, },
		["Manipulation"] = { [8] = 4574, [9] = 4575, [10] = 4576, [11] = 4577, [12] = 4578, [13] = 4579, [14] = 4580, [15] = 4581, },
		["Master's Mend"] = { [8] = 100003, [9] = 100017, [10] = 100032, [11] = 100077, [12] = 100047, [13] = 100062, [14] = 100092, [15] = 100107, },
		["Muscle Memory"] = { [8] = 100379, [9] = 100380, [10] = 100381, [11] = 100382, [12] = 100383, [13] = 100384, [14] = 100385, [15] = 100386, },
		["Name of the Elements"] = { [8] = 4615, [9] = 4616, [10] = 4617, [11] = 4618, [12] = 4620, [13] = 4619, [14] = 4621, [15] = 4622, },
		["Observe"] = { [8] = 100010, [9] = 100023, [10] = 100040, [11] = 100082, [12] = 100053, [13] = 100070, [14] = 100099, [15] = 100113, },
		["Patient Touch"] = { [8] = 100219, [9] = 100220, [10] = 100221, [11] = 100222, [12] = 100223, [13] = 100224, [14] = 100225, [15] = 100226, },
		["Precise Touch"] = { [8] = 100128, [9] = 100129, [10] = 100130, [11] = 100131, [12] = 100132, [13] = 100133, [14] = 100134, [15] = 100135, },
		["Preparatory Touch"] = { [8] = 100299, [9] =100300, [10] = 100301, [11] = 100302, [12] = 100303, [13] = 100304, [14] = 100305, [15] = 100306, },
		["Prudent Touch"] = { [8] = 100227, [9] = 100228, [10] = 100229, [11] = 100230, [12] = 100231, [13] = 100232, [14] = 100233, [15] = 100234, },
		["Rapid Synthesis"] = { [8] = 100363, [9] = 100364, [10] = 100365, [11] = 100366, [12] = 100367, [13] = 100368, [14] = 100369, [15] = 100370, },
		["Reflect"] = { [8] = 100387, [9] = 100388, [10] = 100389, [11] = 100390, [12] = 100391, [13] = 100392, [14] = 100393, [15] = 100394, },
		["Standard Touch"] = { [8] = 100004, [9] = 100018, [10] = 100034, [11] = 100078, [12] = 100048, [13] = 100064, [14] = 100093, [15] = 100109, },
		["Trained Eye"] = { [8] = 100283, [9] = 100284, [10] = 100285, [11] = 100286, [12] = 100287, [13] =100288, [14] = 100289, [15] = 100290, },
		["Tricks of the Trade"] = { [8] = 100371, [9] = 100372, [10] = 100373, [11] = 100374, [12] = 100375, [13] = 100376, [14] = 100377, [15] = 100378, },
		["Waste Not"] = { [8] = 4631, [9] = 4632, [10] = 4633, [11] = 4634, [12] = 4635, [13] = 4636, [14] = 4637, [15] = 4638, },
		["Waste Not II"] = { [8] = 4639, [9] = 4640, [10] = 4641, [11] = 4642, [12] = 4643, [13] = 4644, [14] = 19002, [15] = 19003, },
		["Veneration"] = { [8] = 19297, [9] = 19298, [10] = 19299, [11] = 19300, [12] = 19301, [13] = 19302, [14] = 19303, [15] = 19304, },
		["Groundwork"] = { [8] = 100403, [9] = 100404, [10] = 100405, [11] = 100406, [12] = 100407, [13] = 100408, [14] = 100409, [15] = 100410, },
	}
else
	SkillMgr.MatchingCraftSkills = {
		--Basic Skills
		-- CRP,BSM,ARM,GSM,LTW,WVR,ALC,CUL
		["Basic Synthesis"] = { [8] = 100001, [9] = 100015, [10] = 100030, [11] = 100075, [12] = 100045, [13] = 100060, [14] = 100090, [15] = 100105, },
		["Basic Touch"] = { [8] = 100002, [9] = 100016, [10] = 100031, [11] = 100076, [12] = 100046, [13] = 100061, [14] = 100091, [15] = 100106, },
		["Brand of the Elements"] = { [8] = 100331, [9] = 100332, [10] = 100333, [11] = 100334, [12] = 100335, [13] = 100336, [14] = 100337, [15] = 100338, },
		["Byregot's Blessing"] = { [8] = 100339, [9] = 100340, [10] = 100341, [11] = 100342, [12] = 100343, [13] = 100344, [14] = 100345, [15] = 100346, },
		["Careful Observation"] = { [8] = 100395, [9] = 100396, [10] = 100397, [11] = 100398, [12] = 100399, [13] = 100400, [14] = 100401, [15] = 100402, },
		["Careful Synthesis"] = { [8] = 100203, [9] = 100204, [10] = 100205, [11] = 100206, [12] = 100207, [13] = 100208, [14] = 100209, [15] = 100210, },
		["Delicate Synthesis"] = { [8] = 100323, [9] = 100324, [10] = 100325, [11] = 100326, [12] = 100327, [13] = 100328, [14] = 100329, [15] = 100330, },
		["Final Appraisal"] = { [8] = 19012, [9] = 19013, [10] = 19014, [11] = 19015, [12] = 19016, [13] = 19017, [14] = 19018, [15] = 19019, },
		["Focused Synthesis"] = { [8] = 100235, [9] = 100236, [10] = 100237, [11] = 100238, [12] = 100239, [13] = 100240, [14] = 100241, [15] = 100242, },
		["Focused Touch"] = { [8] = 100243, [9] = 100244, [10] = 100245, [11] = 100246, [12] = 100247, [13] = 100248, [14] = 100249, [15] = 100250, },
		["Great Strides"] = { [8] = 260, [9] = 261, [10] = 262, [11] = 263, [12] = 265, [13] = 264, [14] = 266, [15] = 267, },
		["Hasty Touch"] = { [8] = 100355, [9] = 100356, [10] = 100357, [11] = 100358, [12] = 100359, [13] = 100360, [14] = 100361, [15] = 100362, },
		["Inner Quiet"] = { [8] = 252, [9] = 253, [10] = 254, [11] = 255, [12] = 257, [13] = 256, [14] = 258, [15] = 259, },
		["Innovation"] = { [8] = 19004, [9] = 19005, [10] = 19006, [11] = 19007, [12] = 19008, [13] = 19009, [14] = 19010, [15] = 19011, },
		["Intensive Synthesis"] = { [8] = 100315, [9] = 100316, [10] = 100317, [11] = 100318, [12] = 100319, [13] = 100320, [14] = 100321, [15] = 100322, },
		["Manipulation"] = { [8] = 4574, [9] = 4575, [10] = 4576, [11] = 4577, [12] = 4578, [13] = 4579, [14] = 4580, [15] = 4581, },
		["Master's Mend"] = { [8] = 100003, [9] = 100017, [10] = 100032, [11] = 100077, [12] = 100047, [13] = 100062, [14] = 100092, [15] = 100107, },
		["Muscle Memory"] = { [8] = 100379, [9] = 100380, [10] = 100381, [11] = 100382, [12] = 100383, [13] = 100384, [14] = 100385, [15] = 100386, },
		["Name of the Elements"] = { [8] = 4615, [9] = 4616, [10] = 4617, [11] = 4618, [12] = 4620, [13] = 4619, [14] = 4621, [15] = 4622, },
		["Observe"] = { [8] = 100010, [9] = 100023, [10] = 100040, [11] = 100082, [12] = 100053, [13] = 100070, [14] = 100099, [15] = 100113, },
		["Patient Touch"] = { [8] = 100219, [9] = 100220, [10] = 100221, [11] = 100222, [12] = 100223, [13] = 100224, [14] = 100225, [15] = 100226, },
		["Precise Touch"] = { [8] = 100128, [9] = 100129, [10] = 100130, [11] = 100131, [12] = 100132, [13] = 100133, [14] = 100134, [15] = 100135, },
		["Preparatory Touch"] = { [8] = 100299, [9] =100300, [10] = 100301, [11] = 100302, [12] = 100303, [13] = 100304, [14] = 100305, [15] = 100306, },
		["Prudent Touch"] = { [8] = 100227, [9] = 100228, [10] = 100229, [11] = 100230, [12] = 100231, [13] = 100232, [14] = 100233, [15] = 100234, },
		["Rapid Synthesis"] = { [8] = 100363, [9] = 100364, [10] = 100365, [11] = 100366, [12] = 100367, [13] = 100368, [14] = 100369, [15] = 100370, },
		["Reflect"] = { [8] = 100387, [9] = 100388, [10] = 100389, [11] = 100390, [12] = 100391, [13] = 100392, [14] = 100393, [15] = 100394, },
		["Standard Touch"] = { [8] = 100004, [9] = 100018, [10] = 100034, [11] = 100078, [12] = 100048, [13] = 100064, [14] = 100093, [15] = 100109, },
		["Trained Eye"] = { [8] = 100283, [9] = 100284, [10] = 100285, [11] = 100286, [12] = 100287, [13] =100288, [14] = 100289, [15] = 100290, },
		["Tricks of the Trade"] = { [8] = 100371, [9] = 100372, [10] = 100373, [11] = 100374, [12] = 100375, [13] = 100376, [14] = 100377, [15] = 100378, },
		["Waste Not"] = { [8] = 4631, [9] = 4632, [10] = 4633, [11] = 4634, [12] = 4635, [13] = 4636, [14] = 4637, [15] = 4638, },
		["Waste Not II"] = { [8] = 4639, [9] = 4640, [10] = 4641, [11] = 4642, [12] = 4643, [13] = 4644, [14] = 19002, [15] = 19003, },
		["Veneration"] = { [8] = 19297, [9] = 19298, [10] = 19299, [11] = 19300, [12] = 19301, [13] = 19302, [14] = 19303, [15] = 19304, },
		["Groundwork"] = { [8] = 100403, [9] = 100404, [10] = 100405, [11] = 100406, [12] = 100407, [13] = 100408, [14] = 100409, [15] = 100410, },
		["Collectable Synthesis"] = {[8] = 4560, [9] = 4561, [10] = 4562, [11] = 4563, [12] = 4565, [13] = 4564, [14] = 4566, [15] = 4567},
	}
end

SkillMgr.lastquality = 0
SkillMgr.currentIQStack = 0
SkillMgr.currentWasteNotStack = 0
SkillMgr.currentWasteNot2Stack = 0
SkillMgr.currentGSStack = 0
SkillMgr.currentManipStack = 0
SkillMgr.currentInnoStack = 0

SkillMgr.currentToTUses = 0
SkillMgr.currentHTSuccesses = 0
SkillMgr.manipulationUses = 0
SkillMgr.checkHT = false
SkillMgr.newCraft = true

function SkillMgr.Craft()
	if (SkillMgr.IsYielding() or not IsControlOpen("Synthesis")) then
		return false
	end
	
	SkillMgr.CheckMonitor()
	
    local synth = GetControlData("Synthesis")
    if ( synth and IsNull(synth.progress,-1) ~= -1 and table.valid(SkillMgr.SkillProfile)) then -- added a little more sanity checking here
		
		if (SkillMgr.newCraft) then
			SkillMgr.currentIQStack = 0
			SkillMgr.currentWasteNotStack = 0
			SkillMgr.currentWasteNot2Stack = 0
			SkillMgr.currentGSStack = 0
			SkillMgr.currentManipStack = 0
			SkillMgr.currentInnoStack = 0
			SkillMgr.currentHTSuccesses = 0
			SkillMgr.currentToTUses = 0
			SkillMgr.manipulationUses = 0
			SkillMgr.lastquality = synth.quality
			SkillMgr.newCraft = false
		end
		
		-- Update HT Successes
		if (SkillMgr.checkHT) then
			if (synth.quality > SkillMgr.lastquality) then
				SkillMgr.currentHTSuccesses = SkillMgr.currentHTSuccesses + 1
			end
			SkillMgr.checkHT = false
		end
		
		local pbuffs = Player.buffs
		
		-- Update Stacks
		
		SkillMgr.currentIQStack = SkillMgr.GetBuffStacks(pbuffs,251)
		SkillMgr.currentWasteNotStack = SkillMgr.GetBuffStacks(pbuffs,252)
		SkillMgr.currentGSStack = SkillMgr.GetBuffStacks(pbuffs,254)
		SkillMgr.currentWasteNot2Stack = SkillMgr.GetBuffStacks(pbuffs,257)
		SkillMgr.currentManipStack = SkillMgr.GetBuffStacks(pbuffs,1164)
		SkillMgr.currentInnoStack = SkillMgr.GetBuffStacks(pbuffs,2189)

        for prio,skill in pairsByKeys(SkillMgr.SkillProfile) do
			local skillid = tonumber(skill.id)
			
            if ( skill.used  ) then
				SkillMgr.DebugOutput(prio, "["..skill.name.."] performing lookup based on ID ["..tostring(skillid).."] and type ["..tostring(skill.type).."].")
                local realskilldata = SkillMgr.GetAction(skillid,skill.type)
				--if skill is not found, see if we can find it
				if (not realskilldata) then
					for skillname,data in pairs(SkillMgr.MatchingCraftSkills) do
						for job, sid in pairs(data) do
							if (sid == skill.id) then
								skillid = tonumber(data[Player.job]) or 0
								realskilldata = SkillMgr.GetAction(skillid,skill.type)
							end
							if (realskilldata) then
								break
							end
						end
						if (realskilldata) then
							break
						end
					end
				end
				if (not realskilldata) then
					local oppositetype = (skill.type == 1 and 9) or 1
					realskilldata = SkillMgr.GetAction(skillid,oppositetype)
					if (not realskilldata) then
						for skillname,data in pairs(SkillMgr.MatchingCraftSkills) do
							for job, sid in pairs(data) do
								if (sid == skill.id) then
									skillid = tonumber(data[Player.job]) or 0
									realskilldata = SkillMgr.GetAction(skillid,oppositetype)
								end
								if (realskilldata) then
									break
								end
							end
							if (realskilldata) then
								break
							end
						end
					end
				end
				
				local castable = true
				
				--Single use check
				if (skill.singleuseonly and SkillMgr.prevSkillList[prio]) then
					SkillMgr.DebugOutput(prio, "["..skill.name.."] is marked single use only and has already been used.")
					castable = false
				end
				
				--Consecutive use check
				if (skill.consecutiveuseonly and SkillMgr.prevSkillList[prio]) then
					SkillMgr.DebugOutput(prio, "["..skill.name.."] is marked for consecutive use only and has already been used.")
					castable = false
				end

                if ( realskilldata and realskilldata:IsReady(Player.id) ) then
					SkillMgr.DebugOutput(prio, "["..skill.name.."] is ready.")
					
					local stats = Player.stats
					local cp = Player.cp
					local step = synth.step
					local durabilitymax = synth.durabilitymax
					local durability = synth.durability
					local progressmax = synth.progressmax
					local progress = synth.progress
					local quality = synth.quality
					local qualitypercent = synth.hqchance
					
                    if ((tonumber(skill.stepmin) > 0 and synth.step < tonumber(skill.stepmin)) or
                        (tonumber(skill.stepmax) > 0 and synth.step >= tonumber(skill.stepmax)) or
                        (tonumber(skill.cpmin) > 0 and Player.cp.current < tonumber(skill.cpmin)) or
                        (tonumber(skill.cpmax) > 0 and Player.cp.current >= tonumber(skill.cpmax)) or
						
						(tonumber(skill.maxdurabmin) > 0 and durabilitymax < tonumber(skill.maxdurabmin)) or
                        (tonumber(skill.maxdurabmax) > 0 and durabilitymax >= tonumber(skill.maxdurabmax)) or
						
                        (tonumber(skill.durabmin) > 0 and synth.durability < tonumber(skill.durabmin)) or
                        (tonumber(skill.durabmax) > 0 and synth.durability >= tonumber(skill.durabmax)) or
						
						(tonumber(skill.maxprogrmin) > 0 and progressmax < tonumber(skill.maxprogrmin)) or
                        (tonumber(skill.maxprogrmax) > 0 and progressmax >= tonumber(skill.maxprogrmax)) or
						
                        (tonumber(skill.progrmin) > 0 and synth.progress < tonumber(skill.progrmin)) or
                        (tonumber(skill.progrmax) > 0 and synth.progress >= tonumber(skill.progrmax)) or
						
						(tonumber(skill.craftmin) > 0 and Player.stats.craftmanship < tonumber(skill.craftmin)) or
                        (tonumber(skill.craftmax) > 0 and Player.stats.craftmanship >= tonumber(skill.craftmax)) or
                        (tonumber(skill.controlmin) > 0 and Player.stats.control < tonumber(skill.controlmin)) or
                        (tonumber(skill.controlmax) > 0 and Player.stats.control >= tonumber(skill.controlmax)) or
                        (tonumber(skill.qualitymin) > 0 and synth.quality < tonumber(skill.qualitymin)) or
                        (tonumber(skill.qualitymax) > 0 and synth.quality >= tonumber(skill.qualitymax)) or
                        (tonumber(skill.qualityminper) > 0 and synth.qualitypercent < tonumber(skill.qualityminper)) or
                        (tonumber(skill.qualitymaxper) > 0 and synth.qualitypercent >= tonumber(skill.qualitymaxper)))							 
                    then 						
						if tonumber(skill.stepmin) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(step).." < "..tonumber(skill.stepmin).."]") end
						if tonumber(skill.stepmax) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(step).." >= "..tonumber(skill.stepmax).."]") end
						if tonumber(skill.durabmin) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(durability).." < "..tonumber(skill.durabmin).."]") end
						if tonumber(skill.durabmax) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(durability).." >= "..tonumber(skill.durabmax).."]") end
						if tonumber(skill.progrmin) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(progress).." < "..tonumber(skill.progrmin).."]") end
						if tonumber(skill.progrmax) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(progress).." >= "..tonumber(skill.progrmax).."]") end
						if tonumber(skill.qualitymin) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(quality).." < "..tonumber(skill.qualitymin).."]") end
						if tonumber(skill.qualitymax) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(quality).." >= "..tonumber(skill.qualitymax).."]") end
						if tonumber(skill.qualityminper) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(qualitypercent).." < "..tonumber(skill.qualityminper).."]") end
						if tonumber(skill.qualitymaxper) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(qualitypercent).." >= "..tonumber(skill.qualitymaxper).."]") end
						if tonumber(skill.cpmin) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(cp.current).." < "..tonumber(skill.cpmin).."]") end
						if tonumber(skill.cpmax) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(cp.current).." >=  "..tonumber(skill.cpmax).."]") end
						if tonumber(skill.craftmin) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(stats.craftmanship).." < "..tonumber(skill.craftmin).."]") end
						if tonumber(skill.craftmax) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(stats.craftmanship).." >=  "..tonumber(skill.craftmax).."]") end
						if tonumber(skill.controlmin) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(stats.control).." < "..tonumber(skill.controlmin).."]") end
						if tonumber(skill.controlmax) > 0 then SkillMgr.DebugOutput(prio, "["..skill.name.."] ["..tostring(stats.control).." >=  "..tonumber(skill.controlmax).."]") end
						
						castable = false 
                    end

					local translatedCondition
					local translatedRequirement
					if (table.valid(gSMCraftConditionsCache)) then
						translatedCondition = gSMCraftConditionsCache[synth.condition]
						translatedRequirement = gSMCraftConditionsCache[skill.condition]
					end
					if (not translatedCondition) then
						translatedCondition = GetStringKey(synth.condition)
						if (type(translatedCondition) == "string" and translatedCondition ~= "") then
							gSMCraftConditionsCache[synth.condition] = translatedCondition
						end
					end
					if (not translatedRequirement) then
						translatedRequirement = GetStringKey(skill.condition)
						if (type(translatedRequirement) == "string" and translatedRequirement ~= "") then
							gSMCraftConditionsCache[skill.condition] = translatedRequirement
						end
					end

					if (translatedRequirement ~= "" and translatedRequirement ~= "notused") then
						if (translatedCondition ~= translatedRequirement) then
							SkillMgr.DebugOutput(prio, "["..skill.name.."] condition requirement was not met.")
							castable = false
						end
					end

					if ((tonumber(skill.totmin) > 0 and SkillMgr.currentToTUses < tonumber(skill.totmin)) or
						(tonumber(skill.totmax) > 0 and SkillMgr.currentToTUses >= tonumber(skill.totmax)))
					then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] did not meet trick of the trade usage requirements.")
						castable = false
					end
					
					if (tonumber(skill.htsucceed) > 0 and SkillMgr.currentHTSuccesses > tonumber(skill.htsucceed)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] did not meet hasty touch success count requirements.")
						castable = false
					end
					
					if (tonumber(skill.iqstackmax) > 0 and SkillMgr.currentIQStack >= tonumber(skill.iqstackmax)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] did not meet max IQ stack requirements.")
						castable = false
					end
					
					if (tonumber(skill.iqstack) > 0 and SkillMgr.currentIQStack < tonumber(skill.iqstack)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] did not meet minimum IQ stack requirements.")
						castable = false
					end
					if (tonumber(skill.gsstackmin) > 0 and SkillMgr.currentGSStack < tonumber(skill.gsstackmin)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] did not meet great strides stack requirements.")
						castable = false
					end
					if (tonumber(skill.wnstackmin) > 0 and SkillMgr.currentWasteNotStack < tonumber(skill.wnstackmin)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] did not meet waste not requirements.")
						castable = false
					end
					if (tonumber(skill.wn2stackmin) > 0 and SkillMgr.currentWasteNot2Stack < tonumber(skill.wn2stackmin)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] did not meet waste not 2 requirements.")
						castable = false
					end
					if (tonumber(skill.manipstackmax) > 0 and SkillMgr.currentManipStack >= tonumber(skill.manipstackmax)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] did not meet max manipulation stack requirements.")
						castable = false
					end
					if (tonumber(skill.manipstackmin) > 0 and SkillMgr.currentManipStack < tonumber(skill.manipstackmin)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] did not meet manipulation stack requirements.")
						castable = false
					end
					if (tonumber(skill.innostackmin) > 0 and SkillMgr.currentInnoStack < tonumber(skill.innostackmin)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] did not meet innovation stack requirements.")
						castable = false
					end
					if (tonumber(skill.manipmax) > 0 and SkillMgr.manipulationUses >= tonumber(skill.manipmax)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] did not meet manipulation uses requirements.")
						castable = false
					end
					
					-- buff checks
                    if ( skill.cpbuff ~= "" ) then
						if not HasBuffs(Player, skill.cpbuff) then
							SkillMgr.DebugOutput(prio, "["..skill.name.."] did not meet has buff requirements.")
							castable = false 
						end
                    end						
                    
                    if (skill.cpnbuff ~= "" ) then
						if not MissingBuffs(Player, skill.cpnbuff) then
							SkillMgr.DebugOutput(prio, "["..skill.name.."] did not meet missing buff requirements.")
							castable = false 
						end								
                    end	
					
					local currentQuality = synth.quality
					if ( castable ) then
					
						d("CASTING(Crafting): ["..tostring(prio).."] : "..tostring(skill.name).." : "..tostring(skillid))	
						SkillMgr.lastquality = currentQuality
						local thisPrio = prio
						local singleuseonly = skill.singleuseonly
						local consecutiveuseonly = skill.consecutiveuseonly
						
						local ret = realskilldata:Cast(Player.id)
						local successFunction = function ()
							if (In(skillid, 100371, 100372, 100373, 100374, 100375, 100376, 100377, 100378)) then
								SkillMgr.currentToTUses = SkillMgr.currentToTUses + 1
							elseif (In(skillid, 100355, 100356, 100357, 100358, 100359, 100360, 100361, 100362)) then
								SkillMgr.checkHT = true
							elseif (In(skillid, 4574, 4575, 4576, 4577, 4578, 4579, 4580, 4581)) then
								SkillMgr.manipulationUses = SkillMgr.manipulationUses + 1
							end

							if (singleuseonly) then
								SkillMgr.prevSkillList[thisPrio] = true
							end
							
							if (consecutiveuseonly) then
								SkillMgr.tempPrevSkillList[thisPrio] = true
							end
							
							if (table.valid(SkillMgr.tempPrevSkillList)) then
								for kprio,kskillid in pairsByKeys(SkillMgr.tempPrevSkillList) do
									if (kprio < thisPrio) then
										SkillMgr.prevSkillList[kprio] = true
									end
								end								
							end							
							SkillMgr.SkillProfile[thisPrio].lastcast = Now()
							SkillMgr.prevSkillID = tostring(skillid)
						end
							
						if (ret == true) then
							successFunction()
						else
							ml_global_information.AwaitSuccess(3000, 
								function () 
									--d("checking if ["..tostring(Player.castinginfo.lastcastid).."] = ["..tostring(skillid).."]")
									return (Player.castinginfo.lastcastid == skillid)
								end,
								successFunction
							)			
						end

						return true
					end
				else
					if (realskilldata) then
						if (not realskilldata:IsReady(Player.id)) then
							SkillMgr.DebugOutput(prio, "["..skill.name.."] was not ready for use.")
						end
					else
						SkillMgr.DebugOutput(prio, "["..skill.name.."] could not be found as a valid skill.")
					end
                end
            end
        end
    end
	return false
end

SkillMgr.MatchingGatherSkills = {
	--Basic Skills
	-- MIN/BTN
	["Prospect"] 				={ [16] = 227, [17] = 210 },
	["Preparation"] 			={ [16] = 230, [17] = 213 },
	["Sharp Vision"] 			={ [16] = 235, [17] = 218 },
	["Sharp Vision 2"] 			={ [16] = 237, [17] = 220 },
	["Sharp Vision 3"] 			={ [16] = 295, [17] = 294 },
	["HQ Chance Up"] 			={ [16] = 242, [17] = 225 },
	["HQ Chance Up 2"] 			={ [16] = 243, [17] = 226 },
	["HQ Chance Up 3"] 			={ [16] = 270, [17] = 271 },
	["Toil"] 					={ [16] = 231, [17] = 214 },
	["Luck"] 					={ [16] = 4081, [17] = 4095 },
	["Discerning Eye"] 			={ [16] = 4078, [17] = 4092 },
	["Methodical Appraisal"] 	={ [16] = 4075, [17] = 4089 },
	["Collector's Glove"] 		={ [16] = 4074, [17] = 4088 },
	["Utmost Caution"] 			={ [16] = 4079, [17] = 4093 },
	["Instinctual Appraisal"] 	={ [16] = 4076, [17] = 4090 },
	["Impulsive Appraisal"] 	={ [16] = 4077, [17] = 4091 },
	["Impulsive Appraisal 2"] 	={ [16] = 301, [17] = 302 },
	["Single Mind"] 			={ [16] = 4084, [17] = 4098 },
	["Dredge / Prune"] 			={ [16] = 4082, [17] = 4096 },
	["Dredge 2 / Prune 2"] 		={ [16] = 4083, [17] = 4097 },
	["Counsel"] 				={ [16] = 274, [17] = 275 },
	["Solid / Ageless"] 		={ [16] = 232, [17] = 215 },
	["Vigor / Brunt"] 			={ [16] = 233, [17] = 216 },
	["Clear / Flora"] 			={ [16] = 4072, [17] = 4086 },
	["King / Blessed"] 			={ [16] = 239, [17] = 222 },
	["King 2/ Blessed 2"] 		={ [16] = 241, [17] = 224 },
	["Bountiful"] 				={ [16] = 4073, [17] = 4087 },
	["Bountiful 2"] 			={ [16] = 272, [17] = 273 },
	["Stickler"] 				={ [16] = 4593, [17] = 4594 },
	["The Giving Land"] 		={ [16] = 4589, [17] = 4590 },
	["Pick Clean"] 				={ [16] = 4587, [17] = 4588 },
	["Mountaineer / Pioneer"] 	={ [16] = 4605, [17] = 4606 },
	["Twelve Bounty"] 			={ [16] = 280, [17] = 282 },
	
	["Scour"] 					={ [16] = 22182, [17] = 22186 },
	["Brazen Prospector"] 		={ [16] = 22183, [17] = 22187 },
	["Meticulous Prospector"] 	={ [16] = 22184, [17] = 22188 },
	["Scrutiny"] 				={ [16] = 22185, [17] = 22189 },
}

function SkillMgr.Gather(item)
	if (SkillMgr.IsYielding()) then
		d("[SkillManager]: Wait a bit, yielding..")
		return false
	end
	
	SkillMgr.CheckMonitor()
	
    local node = MGetTarget()
    if ( table.valid(node) and table.valid(SkillMgr.SkillProfile)) then
	
		if (Player.gp.current > SkillMgr.lastGPStart) then
			SkillMgr.lastGPStart = Player.gp.current
		end
        
		local doHalt = false
		for prio,skill in pairsByKeys(SkillMgr.SkillProfile) do
			local skillid = tonumber(skill.id)
            if ( skill.used  ) then		-- takes care of los, range, facing target and valid target		
                local realskilldata = SkillMgr.GetAction(skillid,1)
				--if skill is not found, see if we can find it
				if (not realskilldata) then
					local found = false
					for skillname,data in pairs(SkillMgr.MatchingGatherSkills) do
						for job, sid in pairs(data) do
							if (sid == skill.id) then
								skillid = tonumber(data[Player.job]) or 0
								realskilldata = SkillMgr.GetAction(skillid,1)
								found = true
								break
							end
						end
						if (found) then
							break
						end
					end
				end

				if ( realskilldata and realskilldata.cost <= Player.gp.current ) then 
					SkillMgr.DebugOutput(prio, "["..skill.name.."] has available GP, check the other factors.")
					
					local castable = true
					
					if (Player.action == 264 or Player.action == 256) then
						if (not realskilldata:IsReady(Player.id)) then
							SkillMgr.DebugOutput(prio, "["..skill.name.."] failed the idling ready check.")
							castable = false
						end
					end
					
					if ( tonumber(skill.gsecspassed) > 0 and skill.lastcast ) then
						if (TimeSince(skill.lastcast) < (tonumber(skill.gsecspassed) * 1000)) then
							SkillMgr.DebugOutput(prio, "["..skill.name.."] failed the last cast check.")
							castable = false
						end
					end
					
					if (table.valid(item)) then
						if (toboolean(item.isunknown) and (skillid == 4074 or skillid == 4088)) then
							SkillMgr.DebugOutput(prio, "["..skill.name.."] was prevented from use due to object's unknown status.")
							castable = false
						end
						if (IsNull(skill.isitem,"") ~= "") then
							if (not MultiComp(item.name,skill.isitem)) then
								castable = false
							end
						end
						if (tonumber(skill.quantity) > 0 and item.quantity < tonumber(skill.quantity)) 	then 
							SkillMgr.DebugOutput(prio, "["..skill.name.."] quantity."..tonumber(skill.quantity).."")
							SkillMgr.DebugOutput(prio, "["..skill.name.."] item quantity."..tonumber(item.quantity).."")
							castable = false 
						end
					end
					if (toboolean(skill.isunspoiled) and not IsUnspoiled(node.contentid)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] was prevented from use due to object's unspoiled status.")
						castable = false
					end
					if (toboolean(skill.isephemeral) and not IsEphemeral(node.contentid)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] was prevented from use due to object's ephemeral status.")
						castable = false
					end
					if (toboolean(skill.islegendary) and not IsLegendary(node.contentid)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] was prevented from use due to object's legendary status.")
						castable = false
					end
					if (toboolean(skill.isconcealed) and not IsConcealed(node.contentid)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] was prevented from use due to object's concealed status.")
						castable = false
					end
					
					--d("starting GP was ["..tostring(SkillMgr.lastGPStart).."]")
					if (tonumber(skill.gpstart) > 0 and IsNull(SkillMgr.lastGPStart,0) < tonumber(skill.gpstart)) then 
						castable = false 
					end
					
					if (tonumber(skill.gpmin) > 0 and Player.gp.current < tonumber(skill.gpmin)) then 
						SkillMgr.DebugOutput(prio, "[Player GP]"..tostring(Player.gp.current).."")
						SkillMgr.DebugOutput(prio, "["..skill.name.."] minGP."..tonumber(skill.gpmin).."")
						castable = false 
					end
					if 	(tonumber(skill.gpmax) > 0 and Player.gp.current > tonumber(skill.gpmax)) then 
						SkillMgr.DebugOutput(prio, "["..Player.gp.current.."] GP."..tostring(Player.gp.current).."")
						SkillMgr.DebugOutput(prio, "["..skill.name.."] maxGP."..tonumber(skill.gpmax).."")
						castable = false 
					end
					if (tonumber(skill.gatherattempts) > 0 and node.gatherattempts <= tonumber(skill.gatherattempts)) 	then 
						SkillMgr.DebugOutput(prio, "["..skill.name.."] gatherattempts."..tonumber(skill.gatherattempts).."")
						SkillMgr.DebugOutput(prio, "["..skill.name.."] node gatherattempts."..tonumber(node.gatherattempts).."")
						castable = false 
					end
					if skill.gathermax and (node.gatherattempts < node.gatherattemptsmax) then 
						SkillMgr.DebugOutput(prio, "["..skill.name.."] Node gatherattempts = "..tonumber(node.gatherattempts).."")
						SkillMgr.DebugOutput(prio, "["..skill.name.."] Node gatherattemptsmax = "..tonumber(node.gatherattemptsmax).."")
						castable = false 
					end
					if (tonumber(skill.gatherattemptsmax) > 0 and node.gatherattempts > tonumber(skill.gatherattemptsmax))	then 
						SkillMgr.DebugOutput(prio, "["..skill.name.."] gatherattemptsmax."..tonumber(skill.gatherattemptsmax).."")
						SkillMgr.DebugOutput(prio, "["..skill.name.."] node gatherattemptsmax."..tonumber(node.gatherattempts).."")
						castable = false 
					end
					if (tonumber(skill.maxgatherattemptsmin) > 0 and node.gatherattemptsmax <= tonumber(skill.maxgatherattemptsmin)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] failed the max gather attempts minimum check.")
						castable = false
					end
					if (tonumber(skill.maxgatherattempts) > 0 and node.gatherattemptsmax ~= tonumber(skill.maxgatherattempts)) then
						SkillMgr.DebugOutput(prio, "["..skill.name.."] failed the max gather attempts equality check.")
						castable = false
					end
					
					--Previous gathering skill check
					if (not IsNullString(skill.pskillg)) then
						local found = false
						for pskill in StringSplit(skill.pskillg,",") do
							if (tonumber(SkillMgr.prevGatherSkillID) == tonumber(pskill)) then
								found = true
							else
								--d("prev skillid:"..tostring(SkillMgr.prevGatherSkillID)..",pskill:"..tostring(pskill))
							end
						end
						if (not found) then
							SkillMgr.DebugOutput(prio, "["..skill.name.."] failed previous gathering skill check.")
							castable = false
						end
					end
					
					if (IsControlOpen("GatheringMasterpiece")) then
						local info = GetControlData("GatheringMasterpiece")
						
						
						if (table.valid(info)) then
							local collectableRarity = info.rarity
							local collectableWear = info.wear
							
							if GetPatchLevel() >= 5.4 then
								info = GetControlRawData("GatheringMasterpiece")
								collectableRarity = info[5].value
								collectableAttemptsRemaining = info[41].value	
								collectableAttemptsMax = info[42].value	
								collectableWear = collectableAttemptsMax - collectableAttemptsRemaining
							end
						
							if (tonumber(skill.collraritylt) > 0 and collectableRarity >= tonumber(skill.collraritylt)) then
								SkillMgr.DebugOutput(prio, "["..skill.name.."] failed the collectible rarity max check.")
								castable = false
							end
							if (tonumber(skill.collraritygt) > 0 and collectableRarity < tonumber(skill.collraritygt)) then
								SkillMgr.DebugOutput(prio, "["..skill.name.."] failed the collectible rarity min check.")
								castable = false
							end
							if (tonumber(skill.collwearlt) > 0 and collectableWear >= tonumber(skill.collwearlt)) then
								SkillMgr.DebugOutput(prio, "["..skill.name.."] failed the collectible wear max check.")
								castable = false
							end
							if (tonumber(skill.collweargt) > 0 and collectableWear < tonumber(skill.collweargt)) then
								SkillMgr.DebugOutput(prio, "["..skill.name.."] failed the collectible wear min check.")
								castable = false
							end
							if (tonumber(skill.collweareq) > 0 and collectableWear ~= tonumber(skill.collweareq)) then
								SkillMgr.DebugOutput(prio, "["..skill.name.."] failed the collectible wear equality check.")
								castable = false
							end
						end
					else
						if (table.valid(item)) then
							if (tonumber(skill.itemchancemax) > 0 and item and item.chance > tonumber(skill.itemchancemax)) then
								SkillMgr.DebugOutput(prio, "["..skill.name.."] failed the item chance max check.")
								castable = false
							end
							
							if (tonumber(skill.itemhqchancemin) > 0 and item and (item.hqchance == 255 or item.hqchance < tonumber(skill.itemhqchancemin))) then
								SkillMgr.DebugOutput(prio, "["..skill.name.."] failed the hq chance max check.")
								castable = false
							end
						end
					end
					
					if ( skill.gpbuff and skill.gpbuff ~= "" ) then
						local gbfound = HasBuffs(Player,skill.gpbuff)
						if not gbfound then
							SkillMgr.DebugOutput(prio, "["..skill.name.."] failed HasBuff check.")
							castable = false 
						end
					end

					if (skill.gpnbuff ~= "" ) then
						if not MissingBuffs(Player, skill.gpnbuff) then
							SkillMgr.DebugOutput(prio, "["..skill.name.."] failed MissingBuff check.")
							castable = false 
						end								
                    end	
					
					--Single use check
					if not gSkillManagerPrioSystem then
						if (skill.singleuseonly and SkillMgr.prevSkillList[skillid]) then
							SkillMgr.DebugOutput(prio, "["..skill.name.."] is marked single use only and has already been used.")
							castable = false
						end
					else
						if (skill.singleuseonly and SkillMgr.prevSkillList[prio]) then
							SkillMgr.DebugOutput(prio, "["..skill.name.."] is marked single use only and has already been used.")
							castable = false
						end
					end
					
					if (IsNull(skill.gatherrequiresmark,"") ~= "") then
						if (skill.gatherrequiresmark ~= SkillMgr.pathMark) then
							SkillMgr.DebugOutput(prio, "["..skill.name.."] requires mark ["..tostring(skill.gatherrequiresmark).."] does not match ["..tostring(SkillMgr.pathMark).."].")
							castable = false
						end
					end
					
					if ( castable ) then
						if (realskilldata:IsReady(Player.id)) then
							doHalt = true
							if ( realskilldata:Cast(Player.id)) then	
								d("CASTING (gathering) : "..tostring(prio).." : "..tostring(skill.name))
								SkillMgr.SkillProfile[prio].lastcast = Now()
								SkillMgr.prevGatherSkillID = tostring(skillid)
								--After a skill is used here, mark it unusable for the rest of the duration of the node.
								if not gSkillManagerPrioSystem then
									SkillMgr.prevSkillList[skillid] = true
								else
									SkillMgr.prevSkillList[prio] = true
								end
								if (IsNull(skill.gatheraddsmark,"") ~= "") then
									SkillMgr.pathMark = skill.gatheraddsmark
								end

								if IsUncoverSkill(skillid) then
									ml_task_hub:CurrentTask().itemsUncovered = true
								end
								
								if (IsNull(skill.gatheraddsbuff,"") ~= "") then
									ml_global_information.Await(2500,4000, 
										function () 
											return HasBuffs(Player, skill.gatheraddsbuff)
										end
									)
								end
								SkillMgr.DebugOutput(prio, "["..skill.name.."] was cast.")
								return true
							end	
						else
							SkillMgr.DebugOutput(prio, "["..skill.name.."] was prevented from use because it is not ready.")
						end
					end	
                end
            end
        end
		if (doHalt) then
			return true
		end
    end
    return false
end

function SkillMgr.GetBuffStacks(buffs,buffID,ownerid)
	local buffID = tonumber(buffID) or 0
	local ownerid = tonumber(ownerid) or 0
	
	if (table.valid(buffs)) then
		for i, buff in pairs(buffs) do
			if (buff.id == buffID) then
				if (ownerid == 0 or buff.ownerid == ownerid) then
					return buff.stacks
				end
			end
		end
	end
    
    return 0
end

function SkillMgr.GCDTimeLT(mintime)
	local mintime = tonumber(mintime) or 2.5
	local castable = false
	local actionID = SkillMgr.GCDSkills[Player.job]
	local actionIDPVP = SkillMgr.GCDSkillsPVP[Player.job]
	
	if (actionID) then
		local action = SkillMgr.GetAction(actionID,1) or SkillMgr.GetAction(actionIDPVP,1)
		if (action) then
			if (action.cdmax - action.cd) < mintime then
				return true
			end
		end
	end
	
	return false
end

function SkillMgr.IsGCDReady(maxtime)
	local maxtime = tonumber(maxtime) or .5
	local castable = false
	local timediff = 0
	
	local actionID = SkillMgr.GCDSkills[Player.job]
	local actionIDPVP = SkillMgr.GCDSkillsPVP[Player.job]
	
	if (actionID) then
		local action = SkillMgr.GetAction(actionID,1) or SkillMgr.GetAction(actionIDPVP,1)
		if (action) then
			timediff = (action.cdmax - action.cd)
			if (action.cdmax - action.cd) < maxtime then
				castable = true
			end
		end
	else
		castable = true
	end
	
	return castable, timediff
end

function SkillMgr.IsReady( actionid, actiontype, targetid )
	actionid = tonumber(actionid)
	actiontype = actiontype or 1
	
	local actionself = SkillMgr.GetAction(actionid,actiontype,Player.id)
	if (actionself and actionself.isready) then
		return true
	end
	
	local actiontarget =  SkillMgr.GetAction(actionid,actiontype,targetid)
	if (actiontarget and actiontarget.isready) then
		return true
	end
	
	return false
end

function SkillMgr.GetCDTime( actionid, actiontype )
	local actionid = tonumber(actionid)
	local actiontype = actiontype or 1
	
	local action = SkillMgr.GetAction(actionid,actiontype)
	if (action) then
		return (action.cdmax - action.cd)
	end
	
	return nil
end

function SkillMgr.Use( actionid, targetid, actiontype )
	actiontype = actiontype or 1
	local tid = targetid or Player.id
	
	local target = MGetEntity(targetid)
	if (target and target.los) then
		local action = SkillMgr.GetAction(actionid,actiontype,tid)
		if (action and action.isready and action:IsFacing(tid)) then
			if (action.range == 0 or (action.range >= target.distance2d)) then
				action:Cast(tid)
			end
		end
	end
end

function SkillMgr.DebugOutput( prio, message )
	local prio = tonumber(prio) or 0
	local message = tostring(message)
	
	if (gSkillManagerDebug ) then
		if (not gSkillManagerDebugPriorities or gSkillManagerDebugPriorities == "") then
			d("[SkillManager] : " .. message)
		elseif (IsNull(gSkillManagerDebugPriorities,"") ~= "") then
			local priorityChecks = {}
			for priority in StringSplit(gSkillManagerDebugPriorities,",") do
				priorityChecks[tonumber(priority)] = true
			end
			if (priorityChecks[prio]) then
				d("[SkillManager] : " .. message)
			end
		end
	end
end

-- Need to return a table containing the target, the cast TID, and the buffs table for the target.
function SkillMgr.GetSkillTarget(skill, entity, maxrange)
	if (not skill or not entity) then
		return nil
	end
	
	local PID = Player.id
	local pet = Player.pet
	local target = entity
	local TID = entity.id
	local maxrange = tonumber(maxrange) or 0
	
	local targetTable = {}
	
	local skillid = tonumber(skill.id) or 0
	if (skillid == 0) then
		d("There is a problem with the skill ID for : "..tostring(skill.name))
		return nil
	end
	
	if (skill.trg == GetString("Target")) then
		if (target.id == Player.id) then
			return nil
		end
	elseif ( skill.trg == GetString("Tankable Target")) then
		local newtarget = SkillMgr.GetTankableTarget(maxrange)
		if (newtarget) then
			target = newtarget
			TID = newtarget.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("Tanked Target")) then
		local newtarget = SkillMgr.GetTankedTarget(maxrange)
		if (newtarget) then
			target = newtarget
			TID = newtarget.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("Pet") ) then
		local valid = false
		if (SkillMgr.IsPetSummonActive(skillid)) then
			if (table.valid(pet)) then
				if (not SkillMgr.IsPetSummonSkill(skillid)) then
					valid = true
					target = pet
					TID = pet.id
				end
			end
		else
			if ( SkillMgr.IsPetSummonSkill(skillid) and (SkillMgr.IsPetSummonActive(skillid) or SkillMgr.IsSummoningPet())) then 
				return nil
			else
				valid = true
				TID = PID
			end
		end
		if (not valid) then
			return nil
		end
	elseif ( skill.trg == GetString("Party") ) then
		if ( not IsNullString(skill.ptbuff) or not IsNullString(skill.ptnbuff)) then
			local newtarget = MPartyMemberWithBuff(skill.ptbuff, skill.ptnbuff, maxrange)
			if (newtarget) then
				target = newtarget
				TID = newtarget.id
			 else
				return nil
			end
		elseif (skill.ptkbuff ) then
			local newtarget = MPartyMemberWithBuff(SkillMgr.knownDebuffs, skill.ptnbuff, maxrange)
			if (newtarget) then
				target = newtarget
				TID = newtarget.id
			 else
				return nil
			end
		else
			local ally = nil
			if ( skill.npc  ) then
				ally = MGetBestPartyHealTarget( true, maxrange )
			else
				ally = MGetBestPartyHealTarget( false, maxrange )
			end
			
			if ( ally ) then
				target = ally
				TID = ally.id
			else
				return nil
			end
		end
	elseif ( skill.trg == GetString("PartyS") ) then
		if (not IsNullString(skill.ptbuff) or not IsNullString(skill.ptnbuff)) then
			local newtarget = MPartySMemberWithBuff(skill.ptbuff, skill.ptnbuff, maxrange)
			if (newtarget) then
				target = newtarget
				TID = newtarget.id
			else
				return nil
			end
		elseif (skill.ptkbuff ) then
			local newtarget = MPartySMemberWithBuff(SkillMgr.knownDebuffs, skill.ptnbuff, maxrange)
			if (newtarget) then
				target = newtarget
				TID = newtarget.id
			else
				return nil
			end
		else
			local ally = GetLowestHPParty( skill )
			if ( ally ) then
				target = ally
				TID = ally.id
			else
				return nil
			end
		end
	elseif ( skill.trg == GetString("Tank") ) then
		local ally = MGetBestTankHealTarget( maxrange )
		if ( ally and ally.id ~= PID) then
			target = ally
			TID = ally.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("Ally") ) then
		local ally = nil
		if ( skill.npc  ) then
			ally = MGetBestHealTarget( true, maxrange )
		else
			ally = MGetBestHealTarget( false, maxrange )
		end
		
		if ( ally and ally.id ~= PID) then
			target = ally
			TID = ally.id
		end	
	elseif ( skill.trg == GetString("Dead Party") or skill.trg == GetString("Dead Ally")) then
		local ally = nil
		if (skill.trg == GetString("Dead Party")) then
			ally = GetBestRevive( true, skill.trgtype )
		else
			ally = GetBestRevive( false, skill.trgtype )
			if (ally) then
				d("Dead ally: ["..tostring(ally.name).."].")
			end
		end 
		
		if ( ally and ally.id ~= PID ) then
			if SkillMgr.IsReviveSkill(skillid) then
				target = ally
				TID = ally.id
			else
				TID = PID
			end
		else
			return nil
		end
	elseif ( skill.trg == GetString("Casting Target") ) then
		local ci = entity.castinginfo
		if ( ci ) then
			target = EntityList:Get(ci.channeltargetid)
			TID = ci.channeltargetid
		else
			return nil
		end
	elseif ( skill.trg == GetString("SMN DoT") ) then
		local newtarget = GetBestDoTTarget()
		if (newtarget) then
			target = newtarget
			TID = newtarget.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("SMN Bane") ) then
		local newtarget = GetBestBaneTarget()
		if (newtarget) then
			target = newtarget
			TID = newtarget.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("Player") ) then
		TID = PID
	elseif ( skill.trg == GetString("Low TP") ) then
		local ally = GetLowestTPParty( maxrange, skill.trgtype, skill.trgself )
		if ( ally ) then
			target = ally
			TID = ally.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("Low MP") ) then
		local ally = GetLowestMPParty( maxrange, skill.trgtype, skill.trgself )
		if ( ally ) then
			target = ally
			TID = ally.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("Heal Priority") and tonumber(skill.hpriohp) > 0 ) then
		local priorities = {
			[1] = skill.hprio1,
			[2] = skill.hprio2,
			[3] = skill.hprio3,
			[4] = skill.hprio4,
		}
		
		local requiredHP = tonumber(skill.hpriohp)
		
		local healTargets = {}
		healTargets[GetString("Self")] = Player
		healTargets[GetString("Tank")] = MGetBestTankHealTarget( maxrange )
		if ( skill.npc  ) then
			healTargets[GetString("Party")] = MGetBestPartyHealTarget( true, maxrange )
			healTargets[GetString("Any")] = MGetBestHealTarget( true, maxrange, requiredHP )
		else
			healTargets[GetString("Party")] = MGetBestPartyHealTarget( false, maxrange )
			healTargets[GetString("Any")] = MGetBestHealTarget( false, maxrange, requiredHP ) 
		end
		
		SkillMgr.DebugOutput( skill.prio, "Heal Priority: [Self] Contains : "..(healTargets[GetString("Self")] and healTargets[GetString("Self")].name or "nil")..".")
		SkillMgr.DebugOutput( skill.prio, "Heal Priority: [Tank] Contains : "..(healTargets[GetString("Tank")] and healTargets[GetString("Tank")].name or "nil")..".")
		SkillMgr.DebugOutput( skill.prio, "Heal Priority: [Party] Contains : "..(healTargets[GetString("Party")] and healTargets[GetString("Party")].name or "nil")..".")
		SkillMgr.DebugOutput( skill.prio, "Heal Priority: [Any] Contains : "..(healTargets[GetString("Any")] and healTargets[GetString("Any")].name or "nil")..".")
		
		local ally = nil
		for i,trgstring in ipairs(priorities) do
			if (healTargets[trgstring]) then
				local htarget = healTargets[trgstring]
				if (tonumber(skill.hpriohp) > htarget.hp.percent) then
					
					local buffCheckPassed = true
					if (not IsNullString(skill.tbuff)) then
						local owner = (skill.tbuffowner == GetString("Player")) and PID or nil
						local duration = tonumber(skill.tbuffdura) or 0
						if not HasBuffs(htarget, skill.tbuff, duration, owner) then 
							buffCheckPassed = false
						end 
					end
					
					if (not IsNullString(skill.tnbuff)) then
						local owner = (skill.tnbuffowner == GetString("Player")) and PID or nil
						local duration = tonumber(skill.tnbuffdura) or 0
						if not MissingBuffs(htarget, skill.tnbuff, duration, owner) then 
							buffCheckPassed = false
						end 
					end	
					
					if (buffCheckPassed) then
						ally = htarget
					end
				end
			end
			if (ally) then
				break
			end
		end
		
		if ( ally ) then
			SkillMgr.DebugOutput( skill.prio, "Heal Priority: Target Selection : "..ally.name)
			target = ally
			TID = ally.id
		else
			SkillMgr.DebugOutput( skill.prio, "Heal Priority: Target Selection : nil")
			return nil
		end
	end
	
	if (table.valid(target) and TID ~= 0) then
		targetTable.target = target
		targetTable.TID = TID
		return targetTable
	end
	
	return nil
end

-- Need to return a table containing the target, the cast TID, and the buffs table for the target.
function SkillMgr.GetMacroTarget(skill, entity, maxrange)
	if (not skill or not entity) then
		return nil
	end
	
	local PID = Player.id
	local pet = Player.pet
	local target = entity
	local TID = entity.id
	local maxrange = tonumber(maxrange) or 0
	
	local targetTable = {}
	
	local skillid = tonumber(skill.id) or 0
	if (skillid == 0) then
		d("There is a problem with the skill ID for : "..tostring(skill.name))
		return nil
	end
	
	if (skill.trg == GetString("Target")) then
		if (target.id == Player.id) then
			return nil
		end
	elseif ( skill.trg == GetString("Tankable Target")) then
		local newtarget = SkillMgr.GetTankableTarget(maxrange)
		if (newtarget) then
			target = newtarget
			TID = newtarget.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("Tanked Target")) then
		local newtarget = SkillMgr.GetTankedTarget(maxrange)
		if (newtarget) then
			target = newtarget
			TID = newtarget.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("Pet") ) then
		if ( pet ) then
			if ( SkillMgr.IsPetSummonSkill(skillid) and SkillMgr.IsPetSummonActive(skillid) ) then 
				return nil 
			else
				target = pet
				TID = pet.id
			end
		else
			TID = PID
		end
	elseif ( skill.trg == GetString("Party") ) then
		if ( not IsNullString(skill.ptbuff) or not IsNullString(skill.ptnbuff)) then
			local newtarget = MPartyMemberWithBuff(skill.ptbuff, skill.ptnbuff, maxrange)
			if (newtarget) then
				target = newtarget
				TID = newtarget.id
			 else
				return nil
			end
		elseif (skill.ptkbuff ) then
			local newtarget = MPartyMemberWithBuff(SkillMgr.knownDebuffs, skill.ptnbuff, maxrange)
			if (newtarget) then
				target = newtarget
				TID = newtarget.id
			 else
				return nil
			end
		else
			local ally = nil
			if ( skill.npc  ) then
				ally = MGetBestPartyHealTarget( true, maxrange )
			else
				ally = MGetBestPartyHealTarget( false, maxrange )
			end
			
			if ( ally ) then
				target = ally
				TID = ally.id
			else
				return nil
			end
		end
	elseif ( skill.trg == GetString("PartyS") ) then
		if (not IsNullString(skill.ptbuff) or not IsNullString(skill.ptnbuff)) then
			local newtarget = MPartySMemberWithBuff(skill.ptbuff, skill.ptnbuff, maxrange)
			if (newtarget) then
				target = newtarget
				TID = newtarget.id
			else
				return nil
			end
		elseif (skill.ptkbuff ) then
			local newtarget = MPartySMemberWithBuff(SkillMgr.knownDebuffs, skill.ptnbuff, maxrange)
			if (newtarget) then
				target = newtarget
				TID = newtarget.id
			else
				return nil
			end
		else
			local ally = GetLowestHPParty( skill )
			if ( ally ) then
				target = ally
				TID = ally.id
			else
				return nil
			end
		end
	elseif ( skill.trg == GetString("Tank") ) then
		local ally = MGetBestTankHealTarget( maxrange )
		if ( ally and ally.id ~= PID) then
			target = ally
			TID = ally.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("Ally") ) then
		local ally = nil
		if ( skill.npc  ) then
			ally = MGetBestHealTarget( true, maxrange )
		else
			ally = MGetBestHealTarget( false, maxrange )
		end
		
		if ( ally and ally.id ~= PID) then
			target = ally
			TID = ally.id
		end	
	elseif ( skill.trg == GetString("Dead Party") or skill.trg == GetString("Dead Ally")) then
		local ally = nil
		if (skill.trg == GetString("Dead Party")) then
			ally = GetBestRevive( true, skill.trgtype )
		else
			ally = GetBestRevive( false, skill.trgtype )
			if (ally) then
				d("Dead ally: ["..tostring(ally.name).."].")
			end
		end 
		
		if ( ally and ally.id ~= PID ) then
			if SkillMgr.IsReviveSkill(skillid) then
				target = ally
				TID = ally.id
			else
				TID = PID
			end
		else
			return nil
		end
	elseif ( skill.trg == GetString("Casting Target") ) then
		local ci = entity.castinginfo
		if ( ci ) then
			target = EntityList:Get(ci.channeltargetid)
			TID = ci.channeltargetid
		else
			return nil
		end
	elseif ( skill.trg == GetString("SMN DoT") ) then
		local newtarget = GetBestDoTTarget()
		if (newtarget) then
			target = newtarget
			TID = newtarget.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("SMN Bane") ) then
		local newtarget = GetBestBaneTarget()
		if (newtarget) then
			target = newtarget
			TID = newtarget.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("Player") ) then
		TID = PID
	elseif ( skill.trg == GetString("Low TP") ) then
		local ally = GetLowestTPParty( maxrange, skill.trgtype )
		if ( ally ) then
			target = ally
			TID = ally.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("Low MP") ) then
		local ally = GetLowestMPParty( maxrange, skill.trgtype )
		if ( ally ) then
			target = ally
			TID = ally.id
		else
			return nil
		end
	elseif ( skill.trg == GetString("Heal Priority") and tonumber(skill.hpriohp) > 0 ) then
		local priorities = {
			[1] = skill.hprio1,
			[2] = skill.hprio2,
			[3] = skill.hprio3,
			[4] = skill.hprio4,
		}
		
		local requiredHP = tonumber(skill.hpriohp)
		
		local healTargets = {}
		healTargets[GetString("Self")] = Player
		healTargets[GetString("Tank")] = MGetBestTankHealTarget( maxrange )
		if ( skill.npc  ) then
			healTargets[GetString("Party")] = MGetBestPartyHealTarget( true, maxrange )
			healTargets[GetString("Any")] = MGetBestHealTarget( true, maxrange, requiredHP )
		else
			healTargets[GetString("Party")] = MGetBestPartyHealTarget( false, maxrange )
			healTargets[GetString("Any")] = MGetBestHealTarget( false, maxrange, requiredHP ) 
		end
		
		SkillMgr.DebugOutput( skill.prio, "Heal Priority: [Self] Contains : "..(healTargets[GetString("Self")] and healTargets[GetString("Self")].name or "nil")..".")
		SkillMgr.DebugOutput( skill.prio, "Heal Priority: [Tank] Contains : "..(healTargets[GetString("Tank")] and healTargets[GetString("Tank")].name or "nil")..".")
		SkillMgr.DebugOutput( skill.prio, "Heal Priority: [Party] Contains : "..(healTargets[GetString("Party")] and healTargets[GetString("Party")].name or "nil")..".")
		SkillMgr.DebugOutput( skill.prio, "Heal Priority: [Any] Contains : "..(healTargets[GetString("Any")] and healTargets[GetString("Any")].name or "nil")..".")
		
		local ally = nil
		for i,trgstring in ipairs(priorities) do
			if (healTargets[trgstring]) then
				local htarget = healTargets[trgstring]
				if (tonumber(skill.hpriohp) > htarget.hp.percent) then
					ally = htarget
				end
			end
			if (ally) then
				break
			end
		end
		
		if ( ally ) then
			SkillMgr.DebugOutput( skill.prio, "Heal Priority: Target Selection : "..ally.name)
			target = ally
			TID = ally.id
		else
			SkillMgr.DebugOutput( skill.prio, "Heal Priority: Target Selection : nil")
			return nil
		end
	end
	
	if (table.valid(target) and TID ~= 0) then
		targetTable.target = target
		targetTable.TID = TID
		return targetTable
	end
	
	return nil
end

function SkillMgr.CanCast(prio, entity, outofcombat)
	if (not entity) then
		SkillMgr.DebugOutput( prio, "Missing entity." )
		return 0
	end
	
	--Check for buffs on the player that prevent using weaponskills
	if (not ActionList:IsReady()) then
		SkillMgr.DebugOutput( prio, "Hotbar is locked, no skills are usable." )
		return 0
	end
	
	local outofcombat = IsNull(outofcombat,false)
	SkillMgr.preCombat = outofcombat
	
	local prio = tonumber(prio) or 0
	if (prio == 0) then
		return 0
	end
	
	local skill = SkillMgr.SkillProfile[prio]
	if (not skill) then
		SkillMgr.DebugOutput( prio, "Skill is missing.. weird error." )
		return 0
	elseif (skill and not IsNull(skill.used ,true)) then
		SkillMgr.DebugOutput( prio, tostring("Skill ["..prio.."] is not used.") )
		return 0
	end
	
	local skillid = tonumber(skill.id) or -1
	if (skillid == -1) then
		SkillMgr.DebugOutput( prio, "Skill ID doesn't exist." )
		return 0
	end
	
	--Pull the real skilldata, if we can't find it, consider it uncastable.
	local realskilldata = nil	
	if (skill.stype == GetString("Pet")) then 
		realskilldata = SkillMgr.GetAction(skillid,11) 
	else
		realskilldata = SkillMgr.GetAction(skillid,1)
	end
	
	if (not realskilldata) then
		SkillMgr.DebugOutput( prio, "Could not find skill, doesn't exist." )
		return 0
	end
	
	if (Player.ismounted) then
		return 0
	end
	
	if (math.abs(SkillMgr.gcdTime - realskilldata.recasttime) > .1) then
		if (TimeSince(SkillMgr.latencyTimer) < 150 or (SkillMgr.queuedPrio ~= 0 and TimeSince(SkillMgr.latencyTimer) < 1000)) then
			SkillMgr.DebugOutput( prio, "Skill cannot be casted due to latency timer." )
			return 0
		end
	end
	
	--Check the latency timer to see if casting is currently allowed.
	if (Now() < SkillMgr.latencyTimer) then
		return 0
	end
	
	--if ( realskilldata.isready or (realskilldata.recasttime == 2.5 and SkillMgr.IsGCDReady()) or (IsCaster(Player.job) and SkillMgr.IsGCDReady())) then
	local castable = true
	
	local maxrange = realskilldata.range
	if (skill.stype == GetString("Pet")) then
		petRangeRadius = GetPetSkillRangeRadius(skill.id)
		if (petRangeRadius) then
			maxrange = petRangeRadius.range
		end
	end
	
	SkillMgr.DebugOutput( prio, "Current target entity : "..tostring(entity.name))
	local targetTable = SkillMgr.GetSkillTarget(skill, entity, maxrange)
	if (not targetTable) then
		SkillMgr.DebugOutput( prio, "Target function returned no valid target for "..tostring(realskilldata.name).." ["..tostring(prio).."]")
		return 0
	end
	
	-- Just in case, these shouldn't happen.
	if (not table.valid(targetTable.target)) then
		SkillMgr.DebugOutput( prio, "Target function returned an invalid target, should never happen.")
		return 0
	elseif (targetTable.TID == 0) then
		SkillMgr.DebugOutput( prio, "Target function returned 0, should never happen.")
		return 0
	end	
	
	--Secondary Get() with proper target ID.
	if (skill.stype == "Macro" or skill.stype == "Action") then 
		realskilldata = SkillMgr.GetAction(skillid,1) --targetTable.TID) 
		if (realskilldata) then
			realskilldata.isready = realskilldata:IsReady(targetTable.TID)
			realskilldata.isfacing = realskilldata:IsFacing(targetTable.TID)
		end
	elseif (skill.stype == GetString("Pet")) then
		realskilldata = SkillMgr.GetAction(skillid,11) --targetTable.TID) 
		if (realskilldata) then
			realskilldata.isready = realskilldata:IsReady(targetTable.TID)
			realskilldata.isfacing = realskilldata:IsFacing(targetTable.TID)
		end
	end
	
	SkillMgr.CurrentSkill = skill
	SkillMgr.CurrentSkillData = realskilldata
	SkillMgr.CurrentPet = Player.pet	
	SkillMgr.CurrentTarget = targetTable.target
	SkillMgr.CurrentTID = targetTable.TID
	
	-- Verify that condition list is valid, and that castable hasn't already been flagged false, just to save processing time.
	if (SkillMgr.ConditionList) then
		for i,condition in pairsByKeys(SkillMgr.ConditionList) do
			if (type(condition.eval) == "function") then
				if (condition.eval()) then
					castable = false		
					SkillMgr.DebugOutput( prio, "Condition ["..condition.name.."] failed its check for "..skill.name.." ["..tostring(prio).."]" )
				end
			end
			if (not castable) then
				break
			end
		end
	end
							
	-- If skill matches the nextskillprio, force it.
	if ( SkillMgr.nextSkillPrio ~= "" ) then
		if ( tonumber(SkillMgr.nextSkillPrio) == tonumber(skill.prio) ) then
			castable = true
		end
	end
					
	-- Some more specialty checking for ninjutsu and mudras.
	-- If the skill is a ninjutsu, and we don't have the mudra buff, it won't succeed.
	-- If the skill is a mudra, and we cast it less than 600ms ago, don't recast.
	if (castable) then
		if (IsMudraSkill(skillid) and TimeSince(skill.lastcast) < 150) then
			SkillMgr.DebugOutput( prio, "Mudra cannot be cast, it was cast too recently.")
			castable = false
		elseif (IsMudraSkill(SkillMgr.SkillProfile[SkillMgr.queuedPrio])) then
			SkillMgr.DebugOutput( prio, "Cannot cast anything, there is still a mudra queued.")
			castable = false
		end
	end
	
	if (castable) then
		SkillMgr.DebugOutput(prio, "Skill ["..tostring(prio).."] was castable.")
		return targetTable.TID
	end
	
	return 0
end

-- Skillmanager Task for the mainbot & assistmode
ffxiv_task_skillmgrAttack = inheritsFrom(ml_task)
function ffxiv_task_skillmgrAttack.Create()
    local newinst = inheritsFrom(ffxiv_task_skillmgrAttack)
    
    --ml_task members
    newinst.valid = true
    newinst.completed = false
    newinst.subtask = nil
    newinst.auxiliary = false
    newinst.process_elements = {}
    newinst.overwatch_elements = {}
    
    --ffxiv_task_grind members
    newinst.name = "LT_SM_KILLTARGET"
    newinst.targetid = 0
	newinst.suppressFollow = false
	newinst.suppressFollowTimer = 0
	newinst.safePos = {}
    
    return newinst
end

function ffxiv_task_skillmgrAttack:Init() 	
	local ke_resetSuppress = ml_element:create( "ResetSuppress", c_resetsuppressions, e_resetsuppressions, 10 )
    self:add(ke_resetSuppress, self.process_elements)
	
	local ke_triggerSuppress = ml_element:create( "TriggerSuppress", c_triggersuppressions, e_triggersuppressions, 5 )
    self:add(ke_triggerSuppress, self.process_elements)
	
    self:AddTaskCheckCEs()
end

function ffxiv_task_skillmgrAttack:Process()
    local target = EntityList:Get(ml_task_hub:CurrentTask().targetid)
    if (target ~= nil and target.alive and InCombatRange(target.id)) then
        
        local pos = target.pos
        Player:SetTarget(target.id)
		
		--[[
		d("Condition1:"..tostring(ml_global_information.AttackRange < 5))
		d("Condition2:"..tostring(gBotMode == GetString("dutyMode")))
		d("Condition3:"..tostring(target.castinginfo.channelingid == 0))
		d("Condition4:"..tostring(gTeleportHack))
		d("Condition5:"..tostring(not IsDutyLeader() or ffxiv_task_duty.independentMode))
		d("not IsDutyLeader():"..tostring(not IsDutyLeader()))
		d("independent:"..tostring(ffxiv_task_duty.independentMode))
		d("Condition6:"..tostring(SkillMgr.teleCastTimer == 0))
		d("Now():"..tostring(Now()))
		d("castTimer:"..tostring(SkillMgr.teleCastTimer))
		d("Condition7:"..tostring(SkillMgr.IsGCDReady()))
		d("Condition8:"..tostring(target.targetid ~= Player.id))
		--]]
		
		if (ml_global_information.AttackRange < 5 and gUseTelecast  and
			gBotMode == GetString("dutyMode") and target.castinginfo and target.castinginfo.channelingid == 0 and
			gTeleportHack and (not IsDutyLeader() or ffxiv_task_duty.independentMode) and SkillMgr.teleCastTimer == 0 and SkillMgr.IsGCDReady()
			and target.targetid ~= Player.id) then
			
			ml_task_hub:CurrentTask().suppressFollow = true
			ml_task_hub:CurrentTask().suppressFollowTimer = Now() + 2500
			
			SkillMgr.teleBack = self.safePos
			Player:Stop()
			Hacks:TeleportToXYZ(pos.x + 1,pos.y, pos.z)
			SkillMgr.teleCastTimer = Now() + 1600
		end
		
		SetFacing(pos.x,pos.y,pos.z)
		SkillMgr.Cast( target )
		
		if (TableSize(SkillMgr.teleBack) > 0 and 
			gBotMode == GetString("dutyMode") and 
			(Now() > SkillMgr.teleCastTimer or (target.castinginfo and target.castinginfo.channelingid ~= 0))) then
			local back = SkillMgr.teleBack
			Hacks:TeleportToXYZ(back.x, back.y, back.z)
			SkillMgr.teleBack = {}
			SkillMgr.teleCastTimer = 0
		end
    else
        self.targetid = 0
        self.completed = true
    end
end

function ffxiv_task_skillmgrAttack:task_complete_eval()
    local target = MGetTarget()
    if (target == nil or not target.alive or not target.attackable or (not InCombatRange(target.id) and Player.castinginfo.channelingid == 0)) then
		ml_task_hub:CurrentTask().suppressFollow = false
        return true
    end
    
    return false
end

function ffxiv_task_skillmgrAttack:task_complete_execute()
    self.targetid = 0
    self.completed = true
end

c_triggersuppressions = inheritsFrom( ml_cause )
e_triggersuppressions = inheritsFrom( ml_effect )
function c_triggersuppressions:evaluate()
	if (gBotMode ~= GetString("dutyMode")) then
		return false
	end
	
	if (not IsDutyLeader() and OnDutyMap() and not MIsLoading() and Player.incombat and not ml_task_hub:CurrentTask().suppressFollow) then
		local leader = GetDutyLeader()
		if leader.dead then
			return true
		end
	end
    return false
end
function e_triggersuppressions:execute()
	ml_task_hub:CurrentTask().suppressFollow = true
	ml_task_hub:CurrentTask().suppressFollowTimer = Now() + 15000
end

c_resetsuppressions = inheritsFrom( ml_cause )
e_resetsuppressions = inheritsFrom( ml_effect )
function c_resetsuppressions:evaluate()
	if (ml_task_hub:CurrentTask().suppressFollow and Now() > ml_task_hub:CurrentTask().suppressFollowTimer) then
		return true
	end
    return false
end
function e_resetsuppressions:execute()
	ml_task_hub:CurrentTask().suppressFollow = false
end

function SkillMgr.AddConditional(conditional)
	assert(type(conditional) == "table","Expected table for conditional,received type "..tostring(type(conditional)))
	table.insert(SkillMgr.ConditionList,conditional)
end

function SkillMgr.IsFacing(skilldata,autoface,target)
	local hasPet = table.valid(Player.pet)
	return (skilldata.isfacing == true or autoface or target.id == Player.id or (hasPet and target.id == Player.pet.id) or IsHealingSkill(skilldata.id) or IsFriendlyBuff(skilldata.id))
end

function SkillMgr.CanBeQueued(skilldata)
	return (math.abs(SkillMgr.gcdTime - skilldata.recasttime) <= .1 and not skilldata.isoncd)
end

function SkillMgr.AddDefaultConditions()	

	conditional = { name = "Chain Check"
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
	
		if (not skill.chainstart) then
			if (SkillMgr.currentChain ~= "") then
				if (skill.chainname ~= "" and string.valid(skill.chainname)) then
					local found = false
					for chain in StringSplit(skill.chainname,",") do
						if (chain == SkillMgr.currentChain) then
							found = true
							break
						end
					end
					if (not found) then
						return true
					end
				else
					return true
				end
			else
				if (skill.chainname ~= "") then
					return true
				end
			end
		else
			if (SkillMgr.currentChain ~= "") then
				return true
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Ready Check (System Defined)"
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		if (realskilldata.isready and SkillMgr.IsFacing(realskilldata,MUsingAutoFace(),target)) then
			return false
		elseif (IsNinjutsuSkill(realskilldata.id) and skill.stype == "Macro") then
			if (not realskilldata.isoncd) then
				return false
			end
		elseif (skill.trg == GetString("Ground Target") and realskilldata.isready) then
			return false
		elseif (skill.type == 11 and realskilldata.isready) then
			return false
		end
		
		SkillMgr.DebugOutput( skill.prio, "[ReadyCheck]: Target: ["..tostring(target.name).."], realskilldata.isready: ["..tostring(realskilldata.isready).."], IsFacing: ["..tostring(SkillMgr.IsFacing(realskilldata,MUsingAutoFace(),target)).."]")
		return true
	end
	}
	SkillMgr.AddConditional(conditional)

	conditional = { name = "OffGCD Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if (skill.gcd == GetString("Auto")) then
			if (math.abs(SkillMgr.gcdTime - realskilldata.recasttime) > .1) then
				--SkillMgr.DebugOutput( skill.prio, "skill.gcdtime = "..tostring(skill.gcdtime)..", IsGCDReady: "..tostring(SkillMgr.IsGCDReady(skill.gcdtime)))
				if (SkillMgr.IsGCDReady(skill.gcdtime) and not IsCaster(Player.job)) then
					return true
				end
				local gcdtimelt = tonumber(skill.gcdtimelt)
				--SkillMgr.DebugOutput( skill.prio, "skill.gcdtimelt = "..tostring(skill.gcdtimelt)..", GCDTimeLT: "..tostring(SkillMgr.GCDTimeLT(skill.gcdtimelt)))
				if (not SkillMgr.GCDTimeLT(gcdtimelt)) then
					return true
				end
			end
		elseif (skill.gcd == GetString("True")) then
			if ((SkillMgr.IsGCDReady(skill.gcdtime) and not IsCaster(Player.job))) then
				return true
			end
		end
		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Valid Target Check"
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		if (skill.trg == GetString("Target")) then
			if (IsHealingSkill(skill.id) or IsFriendlyBuff(skill.id)) then
				if (not IsValidHealTarget(target)) then
					return true
				end
			end
			if not (IsHealingSkill(skill.id) or IsFriendlyBuff(skill.id)) then
				if (not target.attackable) then
					return true
				end
			end
			
			--d("skill:"..tostring(skill.name))
			--local validtarget, inrangeforspell, inlos = ActionList:CanCast(skill.id,target.id,target.type)
			--d("validtarget = "..tostring(validtarget))
			--d("inrangeforspell = "..tostring(inrangeforspell))
			--d("inlos = "..tostring(inlos))			
		end
		return false
	end
	}
	--SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Min/Max Range Check (User Defined)"
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		local minRange = tonumber(skill.minRange)
		local maxRange = tonumber(skill.maxRange)
		
		local dist = target.distance2d		
		if (minRange > 0 and dist < minRange) then 
			return true
		elseif (maxRange > 0 and maxRange ~= realskilldata.range and dist > maxRange) then
			return true
		--elseif (realskilldata.range > 0 and target.id ~= Player.id and ((dist - hitradius) > realskilldata.range)) then
			--return true
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Debuff/Buff Latency Check"
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if ( skill.dobuff  and skill.lastcast) then
			if ((skill.lastcast + 1000) > Now()) then
				return true
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	--[[
	conditional = { name = "Debuff/Buff Latency Check"
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		---removebuff
		if ( skill.dobuff  and skill.lastcast) then
			if ((skill.lastcast + 1000) > Now()) then
				return true
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	--]]
	
	conditional = { name = "Other Skill Ready Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		if ( not IsNullString(skill.skready) ) then

			for _orids in StringSplit(skill.skready,",") do
				local ready = false
				
				for _andid in StringSplit(_orids,"+") do
					ready = false
					local actiontype = (skill.sktype == "Action") and 1 or 11
					if ( SkillMgr.IsReady( tonumber(_andid), actiontype, target.id)) then
						ready = true
					end
					if (not ready) then 
						break
					end
				end
				if (ready) then 
					return false
				end
			end
			
			return true
		end
		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Other Skill Off Cooldown."	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		if ( not IsNullString(skill.skoffcd)) then
			for _orids in StringSplit(skill.skoffcd,",") do
				local ready = false
				
				for _andid in StringSplit(_orids,"+") do
					ready = false
					local actiontype = (skill.sktype == "Action") and 1 or 11
					local cdTime = SkillMgr.GetCDTime(tonumber(_andid), actiontype)
					
					if (cdTime and cdTime == 0) then
						ready = true
					end
				
					if (not ready) then 
						break
					end
				end
				if (ready) then 
					return false
				end
			end
			
			-- If we get here, none of the checks was ready, so it fails castable.
			return true
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Other Skill On Cooldown"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		if ( not IsNullString(skill.sknoffcd)) then
			local actiontype = (skill.sktype == "Action") and 1 or 11
			local minCDTime = tonumber(skill.skncdtimemin) or 0
			local maxCDTime = tonumber(skill.skncdtimemax) or 0
			local cdTime = SkillMgr.GetCDTime(tonumber(skill.sknoffcd), actiontype)
			
			if (not cdTime or 
				(minCDTime > 0 and cdTime <= minCDTime) or 
				(maxCDTime > 0 and cdTime >= maxCDTime) or
				(minCDTime == 0 and maxCDTime == 0 and cdTime > 0)) 
			then							
				return true
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Other Skill Not Ready"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		if ( not IsNullString(skill.sknready)) then
			local actiontype = (skill.sktype == "Action") and 1 or 11
			if ( SkillMgr.IsReady( tonumber(skill.sknready), actiontype, target.id)) then
				return true
			end
		end		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)

	conditional = { name = "Previous Combo Skill ID Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if ( not IsNullString(skill.pcskill)) then
			for skillid in StringSplit(skill.pcskill,",") do
				if (Player.lastcomboid == tonumber(skillid) and Player.combotimeremain > .5) then
					return false
				end
			end
			return true
		end
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Previous Combo Skill NOT ID Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		if (not IsNullString(skill.npcskill)) then
			for skillid in StringSplit(skill.npcskill,",") do
				if (Player.lastcomboid == tonumber(skillid) and Player.combotimeremain > .5) then
					return true
				end
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
		
	conditional = { name = "Previous Skill ID Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if ( not IsNullString(skill.pskill)) then
			if (not IsNullString(SkillMgr.prevSkillID) and TimeSince(SkillMgr.prevSkillTimestamp) < 6000) then
				for skillid in StringSplit(skill.pskill,",") do
					if (tonumber(SkillMgr.prevSkillID) == tonumber(skillid)) then
						return false
					end
				end
			end
			return true
		end
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Previous Skill NOT ID Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		if (not IsNullString(skill.npskill)) then
			if (not IsNullString(SkillMgr.prevSkillID) and TimeSince(SkillMgr.prevSkillTimestamp) < 6000) then
				for skillid in StringSplit(skill.npskill,",") do
					if (tonumber(SkillMgr.prevSkillID) == tonumber(skillid)) then
						return true
					end
				end
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Previous GCD Skill ID Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if ( not IsNullString(skill.pgskill)) then
			if (not IsNullString(SkillMgr.prevGCDSkillID)) then
				for skillid in StringSplit(skill.pgskill,",") do
					if (tonumber(SkillMgr.prevGCDSkillID) == tonumber(skillid)) then
						return false
					end
				end
			end
			return true
		end
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Previous GCD Skill NOT ID Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if (not IsNullString(skill.npgskill)) then
			if (not IsNullString(SkillMgr.prevGCDSkillID)) then
				for skillid in StringSplit(skill.npgskill,",") do
					if (tonumber(SkillMgr.prevGCDSkillID) == tonumber(skillid)) then
						return true
					end
				end
			end
		end
		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Current Action NOT Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if ( not IsNullString(skill.ncurrentaction)) then
			for actionid in StringSplit(skill.ncurrentaction,",") do
				if (tonumber(actionid) == Player.action) then
					return true
				end
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)

	conditional = { name = "Player Target Type Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = MGetTarget()
		
		if ( skill.ptrg ~= GetString("Any") ) then
			if (( skill.ptrg == GetString("Enemy") and (not target or not target.attackable)) or 
				( skill.ptrg == GetString("Player") and (not target or target.type ~= 1))) 
			then 
				return true 
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Only Solo/Party Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		local plist = EntityList("myparty")
		local partySize = TableSize(plist)
		local npcTeam = TableSize(MEntityList("alive,chartype=9,targetable,maxdistance2d=100"))
		
		if (skill.onlysolo) then
			if (partySize > 0) then
				if (IsCompanionSummoned()) then
					return (partySize - 1) > 0
				else
					return true
				end
			elseif (npcTeam > 0) then
				return true
			end
		elseif ( skill.onlyparty) then
			if (ml_task_hub:CurrentTask() and ml_task_hub:CurrentTask():ParentTask()) then
				if (ml_task_hub:CurrentTask():ParentTask().name == "QUEST_DUTYKILL") then
					return false
				end				
			end
			if (partySize == 0 and npcTeam == 0) then
				return true
			end
		end
		
		if ( tonumber(skill.partysizelt) > 0 ) then
			if ((partySize + 1) > tonumber(skill.partysizelt)) then
				return true
			end
			if (npcTeam > tonumber(skill.partysizelt)) then
				return true
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Player Under Attack Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if (skill.punderattack ) then
			local list = EntityList("nearest,alive,attackable,targetingme,maxdistance=20")
			if (list) then
				for i,e in pairs(list) do
					if (i and e) then
						return false
					end
				end
			end
			return true
		end
		
		if (skill.punderattackmelee ) then
			local list = EntityList("nearest,alive,attackable,targetingme,maxdistance=6")
			if (list) then
				for i,e in pairs(list) do
					if (i and e) then
						return false
					end
				end
			end
			return true
		end
		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)

	conditional = { name = "Combat Status Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		local preCombat = SkillMgr.preCombat
		
		if (((skill.combat == "Out of Combat") and Player.incombat) or
			((skill.combat == "In Combat") and (preCombat == true)) or
			((skill.combat == "In Combat") and not Player.incombat and skill.trg ~= GetString("Target")) or
			((skill.combat == "In Combat") and not Player.incombat and not target.attackable))
		then 
			return true
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Filter Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		
		if 	((gAssistFilter1 and skill.filterone == GetString("Off")) or 
			(not gAssistFilter1 and skill.filterone == GetString("On") ) or 
			(gAssistFilter2 and skill.filtertwo == GetString("Off")) or
			(not gAssistFilter2 and skill.filtertwo == GetString("On") ) or
			(gAssistFilter3 and skill.filterthree == GetString("Off")) or
			(not gAssistFilter3 and skill.filterthree == GetString("On") ) or
			(gAssistFilter4 and skill.filterfour == GetString("Off")) or
			(not gAssistFilter4 and skill.filterfour == GetString("On") ) or
			(gAssistFilter5 and skill.filterfive == GetString("Off")) or
			(not gAssistFilter5 and skill.filterfive == GetString("On") ))
		then
			return true
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Secs Passed Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		local secspassed = tonumber(skill.secspassed) or 0
		if ( secspassed > 0 and skill.lastcast and (TimeSince(skill.lastcast) < (secspassed * 1000))) then 
			return true
		elseif (SkillMgr.IsPetSummonSkill(skill.id) and skill.lastcast and TimeSince(skill.lastcast) < (8000)) then
			return true
		end
		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Secs Passed Unique Check"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		local secspassedu = tonumber(skill.secspassedu) or 0
		if ( secspassedu > 0 and table.valid(skill.lastcastunique)) then
			local entry = skill.lastcastunique[target.id]
			if (entry and entry > 0) then
				if (TimeSince(entry) < (secspassedu * 1000)) then 
					return true
				end
			end
		end
		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Player level checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		local mapid = Player.localmapid
		local syncLevel = Player:GetSyncLevel()
		
		if (tonumber(skill.levelmin) > 0 and 
			((tonumber(skill.levelmin) > Player.level) or (not IsEurekaMap(mapid) and syncLevel > 0 and (tonumber(skill.levelmin) > syncLevel))))
		then
			return true
		elseif (tonumber(skill.levelmax) > 0 and
			((tonumber(skill.levelmax) < Player.level) or (not IsEurekaMap(mapid) and syncLevel > 0 and (tonumber(skill.levelmax) < syncLevel))))
		then
			return true
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Player HP/TP Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		if ((tonumber(skill.phpl) > 0 and tonumber(skill.phpl) > Player.hp.percent)	or 
			(tonumber(skill.phpb) > 0 and tonumber(skill.phpb) < Player.hp.percent)	or 
			(tonumber(skill.ptpl) > 0 and tonumber(skill.ptpl) > Player.tp)	or 
			(tonumber(skill.ptpb) > 0 and tonumber(skill.ptpb) < Player.tp)) 
		then 
			return true
		end				
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Player MP Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		local pmp = Player.mp
		local resultpercentage = math.floor(((pmp.current - realskilldata.cost) / pmp.max) * 100)
		
		if ((tonumber(skill.ppowl) > 0 and tonumber(skill.ppowl) > pmp.current) or 
			(tonumber(skill.pmppl) > 0 and tonumber(skill.pmppl) > pmp.percent)) 
		then 
			return true
		elseif ((tonumber(skill.ppowb) > 0 and tonumber(skill.ppowb) < pmp.current) or
				(tonumber(skill.pmppb) > 0 and tonumber(skill.pmppb) < pmp.percent)) 
		then 
			return true 
		elseif ((tonumber(skill.pmprgt) > 0 and (tonumber(skill.pmprgt) < (pmp.current - realskilldata.cost))) or
				--(tonumber(skill.pmprlt) > 0 and (tonumber(skill.pmprlt) > (pmp.current - realskilldata.cost))) or
				(tonumber(skill.pmpprgt) > 0 and (tonumber(skill.pmpprgt) < resultpercentage)))
				--(tonumber(skill.pmpprlt) > 0 and (tonumber(skill.pmpprlt) > resultpercentage)))
		then
			SkillMgr.DebugOutput(skill.prio, "[Resultant MP]:"..tostring((pmp.current - realskilldata.cost)).." is < "..tostring(skill.pmprgt))
			return true
		elseif (IsNull(tonumber(skill.pmprsgt),0) > 0) then -- or tonumber(skill.pmprslt) > 0) then
			local otherskilldata = SkillMgr.GetAction(tonumber(skill.pmprsgt),1)
			if (otherskilldata) then
				local otherskillcost = otherskilldata.cost
				if ((tonumber(skill.pmprsgt) > 0 and (pmp.current - realskilldata.cost) < otherskillcost)) then
					--(tonumber(skill.pmprsgt) > 0 and (pmp.current - realskilldata.cost) > otherskillcost))
				--then
					SkillMgr.DebugOutput(skill.prio, "[Resultant MP]:"..tostring((pmp.current - realskilldata.cost)).." is < skill cost of ["..tostring(otherskillcost).."].")
					return true
				end
			else
				SkillMgr.DebugOutput(skill.prio, "[Resultant MP]: Could not find data for other skill.")
			end
		end			
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Party HP/MP/TP Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		local allyHP = nil
		local allyMP = nil
		local allyTP = nil
		
		local ptcount = tonumber(skill.ptcount) or 0
		local pthpl = tonumber(skill.pthpl) or 0
		local pthpb = tonumber(skill.pthpb) or 0
		if (pthpl ~= 0 or skill.pthpb ~= 0 ) then
			allyHP = GetLowestHPParty( skill )
			
			if ( ptcount == 0 and allyHP ~= nil ) then
				if ((pthpl > 0 and pthpl > allyHP.hp.percent ) or
					(pthpb > 0 and pthpb < allyHP.hp.percent )) 
				then 
					return true
				end
			elseif (ptcount > 0 and not allyHP) then
				return true
			else
				return true
			end
		end
		
		local ptmpl = tonumber(skill.ptmpl) or 0
		local ptmpb = tonumber(skill.ptmpb) or 0
		if (ptmpl ~= 0 or ptmpb ~= 0 ) then
			allyMP = GetLowestMPParty()
			if ( allyMP ~= nil ) then
				if ((ptmpl > 0 and ptmpl > allyMP.mp.percent ) or
					(ptmpb > 0 and ptmpb < allyMP.mp.percent )) 
				then 
					return true
				end
			else
				return true
			end
		end
		
		local pttpl = tonumber(skill.pttpl) or 0
		local pttpb = tonumber(skill.pttpb) or 0
		if (pttpl ~= 0 or pttpb ~= 0 ) then
			allyTP = GetLowestTPParty()
			if ( allyTP ~= nil ) then
				if ((pttpl > 0 and pttpl > allyTP.tp ) or
					(pttpb > 0 and pttpb < allyTP.tp )) 
				then 
					return true
				end
			else
				return true
			end
		end				
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Player Buff Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		if (not IsNullString(skill.pbuff)) then
			local duration = tonumber(skill.pbuffdura) or 0
			if not HasBuffs(Player, skill.pbuff, duration) then 
				return true
			end 
		end
		if (not IsNullString(skill.pnbuff)) then
			local duration = tonumber(skill.pnbuffdura) or 0
			if not MissingBuffs(Player, skill.pnbuff, duration) then 
				return true 
			end 
		end			
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Pet Buff Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		local pet = SkillMgr.CurrentPet
		
		if (pet and pet ~= 0) then
			if (not IsNullString(skill.petbuff)) then
				local duration = tonumber(skill.petbuffdura) or 0
				if not HasBuffs(pet, skill.petbuff, duration) then 
					return true 
				end 
			end
			if (not IsNullString(skill.petnbuff)) then
				local duration = tonumber(skill.petnbuffdura) or 0
				if not MissingBuffs(pet, skill.petnbuff, duration) then 
					return true 
				end 
			end	
		end		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Party Buff Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		if ( skill.trg == GetString("Player") ) then								
			if ( not IsNullString(skill.ptbuff) or not IsNullString(skill.ptnbuff)) then
				local partymemberlist = EntityList("myparty,type=1")
				if ( partymemberlist) then
				   for i,entity in pairs(partymemberlist) do
						if ((skill.ptbuff=="" or not HasBuffs(entity,skill.ptbuff)) and
							(skill.ptnbuff=="" or HasBuffs(entity,skill.ptnbuff))) 
						then
							return true
						end
				   end 
				end
				
				if ((skill.ptbuff=="" or not HasBuffs(Player,skill.ptbuff)) and
					(skill.ptnbuff=="" or MissingBuffs(Player,skill.ptnbuff))) 
				then
					return true
				end	
			end
		end		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Target HP/MP/TP Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		local thpl = tonumber(skill.thpl) or 0
		local thpb = tonumber(skill.thpb) or 0
		local thpcl = tonumber(skill.thpcl) or 0
		local thpcb = tonumber(skill.thpcb) or 0
		local thpadv = tonumber(skill.thpadv) or 0
		local ttpl = tonumber(skill.ttpl) or 0
		local tmpl = tonumber(skill.tmpl) or 0
		
		if ((thpl > 0 and thpl > target.hp.percent) or
			(thpb > 0 and thpb < target.hp.percent) or
			(thpcl > 0 and thpcl > target.hp.current) or
			(thpcb > 0 and thpcb < target.hp.current) or
			(ttpl > 0 and ttpl > target.tp) or
			(tmpl > 0 and tmpl > target.mp.percent) or
			(thpadv > 0 and (((Player.hp.max * thpadv) > target.hp.max) and target.contentid ~= 541))) 
		then 
			return true 
		end
		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	
	conditional = { name = "Target Job Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		
		if (GetString(skill.trgtype) ~= GetString("Any") and target.job ~= nil) then
			local found = true
			local roleString = GetRoleString(target.job)
			if not skill.trgtype ~= roleString then 
				found = false
			end
			if skill.trgtype == GetString("Caster") and IsCaster(target.job) then
				found = true
			end
			if not found then 
				return true 
			end
		end						

		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Dead Target Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		if (skill.trg ~= GetString("Dead Ally") and skill.trg ~= GetString("Dead Party")) then
			if ( target.hp.current == 0 ) then
				return true
			end
		end						
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Positional Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		
		if ( skill.ppos ~= GetString("none") ) then 
			if ((skill.ppos == GetString("Flanking") and not IsFlanking(target)) or
				(skill.ppos == GetString("Behind") and not IsBehind(target)) or
				(skill.ppos == GetString("Front") and not IsFront(target)))
			then
				return true
			end						
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Unattackable Fate Target Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local TID = SkillMgr.CurrentTID
		
		if (gBotMode ~= GetString("assistMode")) then
			local target = EntityList:Get(TID)
			if (target and target.fateid ~= 0) then
				
				SkillMgr.DebugOutput(skill.prio, "Target has a FATE ID of ["..tostring(target.fateid).."].")
				local fate = GetFateByID(target.fateid)
				if (table.valid(fate)) then
					if (fate.status == 2) then
						if (Player:GetSyncLevel() == 0 and Player.level > fate.maxlevel) then
							SkillMgr.DebugOutput(skill.prio, "Player's sync level ["..tostring(Player.level).."] is too high for the target FATE ["..tostring(fate.maxlevel).."].")
							return true
						end
					end
				else
					SkillMgr.DebugOutput(skill.prio, "Could not find the active FATE ["..tostring(target.fateid).."].")
					return true
				end
			end
		end
		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Target Buff Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		local TID = SkillMgr.CurrentTID
		local PID = Player.id
		
		if (not IsNullString(skill.tbuff)) then
			local owner = (skill.tbuffowner == GetString("Player")) and PID or nil
			local duration = tonumber(skill.tbuffdura) or 0
			if not HasBuffs(target, skill.tbuff, duration, owner) then 
				return true 
			end 
		end
		
		if (not IsNullString(skill.tnbuff)) then
			local owner = (skill.tnbuffowner == GetString("Player")) and PID or nil
			local duration = tonumber(skill.tnbuffdura) or 0
			if not MissingBuffs(target, skill.tnbuff, duration, owner) then 
				return true 
			end 
		end	
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Target Casting Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		local TID = SkillMgr.CurrentTID
		
		local casttime = tonumber(skill.tcasttime)
		if casttime == nil then casttime = 0 end
		
		if (( casttime > 0 or skill.tcastids ~= "")) then
			if (TableSize(target.castinginfo) == 0) then
				return true
			elseif target.castinginfo.channeltime == 0 then
				return true
			elseif (skill.tcastids == "" and casttime ~= nil) then
				if target.castinginfo.channeltime < casttime then
					return true
				end
			elseif (skill.tcastids ~= "") then								
				local ctid = (skill.tcastonme  and Player.id or nil)
				if ( not SkillMgr.IsCasting(target, skill.tcastids, casttime, ctid ) ) then
					return true
				end
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Target ContentID Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		local TID = SkillMgr.CurrentTID
		
		if ( not IsNullString(skill.tcontids) and not HasContentID(target, skill.tcontids ) ) then
			return true
		end
		if ( not IsNullString(skill.tncontids) and HasContentID(target, skill.tncontids) ) then
			return true
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Target AOE Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		local TID = SkillMgr.CurrentTID
		
		if (skill.tecenter == GetString("Auto")) then
			if (skill.frontalconeaoe ) then
				TID = Player.id
			elseif ((realskilldata.casttime == 0 and realskilldata.recasttime > 2.5) or skill.frontalconeaoe ) then
				TID = target.id
			end
		else
			if (skill.tecenter == GetString("Self")) then
				TID = Player.id
			elseif (skill.tecenter == GetString("Target")) then
				TID = target.id
			end
		end
		
		local tecount = tonumber(skill.tecount) or 0
		local tecount2 = tonumber(skill.tecount2) or 0
		local terange = tonumber(skill.terange) or 5
		
		local tlistAE = nil
		if (tecount > 0 or tecount2 > 0) then
			local targets = {}
			tlistAE = EntityList("alive,attackable,maxdistance2d="..tostring(terange)..",distanceto="..tostring(TID))
			for i,entity in pairs(tlistAE) do
				table.insert(targets,entity)
			end
			
			--Remove all that are targeting me if it's an enmity AOE.
			for i,entity in pairs(targets) do
				if (skill.enmityaoe  and entity.aggropercentage == 100) then
					targets[i] = nil
				elseif (skill.frontalconeaoe  and not EntityIsFrontWide(entity)) then
					targets[i] = nil
				elseif (skill.tankedonlyaoe  and entity.targetid == 0) then
					targets[i] = nil
				end
			end
			
			tlistAE = targets
			local attackTable = TableSize(tlistAE) or 0
			
			if (tlistAE) then
				for i,nearby in pairs(tlistAE) do
					if ( skill.tcontids ~="" and not HasContentID(nearby, skill.tcontids ) ) then
						return true
					end
					if ( skill.tncontids ~="" and HasContentID(nearby, skill.tncontids) ) then
						return true
					end
				end
			end
			if (tecount > 0 and ( attackTable < tecount)) then
				return true
			end
			if (tecount2 > 0 and ( attackTable > tecount2)) then
				return true
			end
		end	
		
		if (table.valid(tlistAE) and skill.televel ~= GetString("Any")) then
			local level = tonumber(Player.level) + tonumber(skill.televel)
			for _, entity in pairs(tlistAE) do
				if entity.level > level then
					return true
				end
			end
		end
		
		if (table.valid(tlistAE) and IsNull(tonumber(skill.tehpavggt),0) > 0) then
			local enemies = TableSize(tlistAE)
			local hptotal = 0
			
			for _, entity in pairs(tlistAE) do
				hptotal = hptotal + entity.hp.percent
			end
			
			local avghp = hptotal / enemies
			if (avghp < tonumber(skill.tehpavggt)) then
				SkillMgr.DebugOutput(skill.prio, "Average HP was reported as ["..tostring(avghp).."], this does not pass the check requirement ["..tostring(skill.tehpavggt).."].")
				return true
			end
		end
		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Ally AOE Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		local TID = SkillMgr.CurrentTID
		
		if (realskilldata.casttime == 0) then
			TID = target.id
		end
		
		local tacount = tonumber(skill.tacount) or 0
		local tarange = tonumber(skill.tarange) or 5
		
		local plistAE = nil
		if (skill.tacount > 0) then
			plistAE = EntityList("alive,myparty,maxdistance="..tostring(tarange)..",distanceto="..tostring(TID))
			if (TableSize(plistAE) < tacount) then 
				return true 
			end
		end
		
		local tahpl = tonumber(skill.tahpl) or 0
		if (tahpl > 0) then
			local count = 0
			if (table.valid(plistAE)) then
				for id, entity in pairs(plistAE) do
					if (entity.alive and entity.targetable and (entity.hp.percent < tahpl)) then
						count = count + 1
					end
				end
			end
			
			if count < tacount then 
				return true 
			end		
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "IsMoving Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		local realskilldata = SkillMgr.CurrentSkillData
		local target = SkillMgr.CurrentTarget
		local TID = SkillMgr.CurrentTID
		
		if (Player:IsMoving() and not skill.ignoremoving) then
			if (realskilldata.casttime > 0) then
				if (MissingBuffs(Player,"167+1249",1)) then
					return true
				end
			else
				if ((HasBuffs(Player,"865") and SkillMgr.IsMinuetAffected(skill.id)) or (HasBuffs(Player,"858") and SkillMgr.IsGaussAffected(skill.id)))  then
					return true
				end
			end
		end
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
	conditional = { name = "Gauge Checks"	
	, eval = function()	
		local skill = SkillMgr.CurrentSkill
		
		for i = 1,8 do
			local g = Player.gauge
			
			if (table.valid(g) and g[i] ~= nil and tonumber(g[i]) ~= nil) then
				if (skill["gauge"..tostring(1).."or"] == "Gauge") or (skill["gauge"..tostring(2).."or"] == "Gauge") then
					if (skill["gauge"..tostring(1).."or"] == "Gauge") then
						if (g[1] > g[2]) then
							--d(tostring(skill.name).." returned false because... Gauge 1 ["..tostring(g[1]).."] > Gauge 2 ["..tostring(g[2]).."]")
							return true
						end
					end
					if (skill["gauge"..tostring(2).."or"] == "Gauge") then
						if (g[2] > g[1]) then
							--d(tostring(skill.name).." returned false because... Gauge 2 ["..tostring(g[2]).."] > Gauge 1 ["..tostring(g[1]).."]")
							return true
						end
					end	
				else
					if (skill["gauge"..tostring(i).."lt"] ~= 0) then
						if (g[i] > skill["gauge"..tostring(i).."lt"]) then
							return true
						end
					end	
					if (skill["gauge"..tostring(i).."gt"] ~= 0) then
						if (g[i] < skill["gauge"..tostring(i).."gt"]) then
							return true
						end
					end		
					if (skill["gauge"..tostring(i).."eq"] ~= 0) then
						if (g[i] ~= skill["gauge"..tostring(i).."eq"]) then
							return true
						end
					end		
					if (skill["gauge"..tostring(i).."or"] ~= "") then
						local foundVal = false
						for val in StringSplit(skill["gauge"..tostring(i).."or"],",") do
							if (tonumber(val) == g[i]) then
								foundVal = true
								break
							end
						end					
						if (not foundVal) then
							return true
						end
					end		
				end
			end
		end
		
		return false
	end
	}
	SkillMgr.AddConditional(conditional)
	
end

function SkillMgr.Capture(newVal,varName)
	local forceSave = IsNull(forceSave,false)
	local needsSave = false
	
	local currentVal = _G[varName]
	if (currentVal ~= newVal or (type(newVal) == "table" and not deepcompare(currentVal,newVal))) then
		_G[varName] = newVal
		needsSave = true
	end
		
	if (needsSave) then
		SkillMgr.WriteToFile(gSkillProfile)
	end

	return newVal
end

function SkillMgr.CaptureElement(newVal, varName)
	local needsSave = false
	
	local currentVal = _G[varName]
	--d("varName:"..varName..",currentVal:"..tostring(_G[varName]))
	if (currentVal ~= newVal or (type(newVal) == "table" and not deepcompare(currentVal,newVal))) then
		--d("set ["..varName.."] to ["..tostring(newVal).."]")
		_G[varName] = newVal
		needsSave = true
	end
		
	if (needsSave) then
		local prio = SkillMgr.EditingSkill
		if (SkillMgr.Variables[varName] ~= nil) then	
			skillVar = SkillMgr.Variables[varName]
			SkillMgr.SkillProfile[prio][skillVar.profile] = newVal
		end
		SkillMgr.SaveProfile()
	end
end

function SKM_Combo(label, varindex, varval, itemlist, height)
	_G[varindex] = GetKeyByValue(_G[varval],itemlist)
	
	local changed = false
	local newIndex = GUI:Combo(label, _G[varindex], itemlist, height)
	if (newIndex ~= _G[varindex]) then
		changed = true
		
		_G[varindex] = newIndex
		_G[varval] = itemlist[_G[varindex]]
		
		local prio = SkillMgr.EditingSkill
		if (SkillMgr.Variables[varval] ~= nil) then	
			skillVar = SkillMgr.Variables[varval]
			SkillMgr.SkillProfile[prio][skillVar.profile] = _G[varval]
		end
		SkillMgr.SaveProfile()
	end
	
	return changed, _G[varindex], _G[varval]
end

function SkillMgr.FillSkillBook()
	if (TimeSince(SkillMgr.lastBookUpdate) > 10000 or Player.job ~= SkillMgr.lastBookClass) then
		SkillMgr.SkillBook = {[1] = {}, [9] = {}, [11] = {}}
		
		local types = {[1] = "Actions",[9] = "Crafting", [11] = "Pets"}
		for actiontype,actiondesc in pairsByKeys(types) do
			local actionlist = ActionList:Get(actiontype)
			if (table.valid(actionlist)) then
				for actionid, action in pairs(actionlist) do
					if ((actiontype ~= 1 or action.job ~= 0) and 
						(not gSkillMgrFilterJob or actiontype ~= 1 or (action.job == Player.job or (SkillMgr.ClassJob[Player.job] and action.job == SkillMgr.ClassJob[Player.job])))) 
					then
						if (not gSkillMgrFilterUsable or action.usable == true) then
							SkillMgr.SkillBook[actiontype][actionid] = { 
								name = action.name, id = action.id, usable = action.usable, type = actiontype, job = action.job,
								cost = action.cost, skilltype = action.skilltype, casttime = action.casttime, recasttime = action.recasttime, 
								range = action.range, radius = action.radius, level = action.level, combospellid = action.combospellid,
								cd = action.cd, cdmax = action.cdmax, isgroundtargeted = action.isgroundtargeted
							}
						end
					end
				end
			end
		end
		
		SkillMgr.lastBookUpdate = Now()
		SkillMgr.lastBookClass = Player.job
	end
end

function SkillMgr.DrawSkillBook()
	--if (SkillMgr.GUI.skillbook.open) then	
		GUI:SetNextWindowPos((SkillMgr.GUI.manager.x - SkillMgr.GUI.skillbook.width),SkillMgr.GUI.manager.y,GUI.SetCond_Appearing)
		GUI:SetNextWindowSize(350,450,GUI.SetCond_Appearing)
		SkillMgr.GUI.skillbook.visible, SkillMgr.GUI.skillbook.open = GUI:Begin(SkillMgr.GUI.skillbook.name, true, GUI.WindowFlags_NoTitleBar)
		if ( SkillMgr.GUI.skillbook.visible ) then 
			
			local x, y = GUI:GetWindowPos()
			local width, height = GUI:GetWindowSize()
			local contentwidth = GUI:GetContentRegionAvailWidth()
			
			SkillMgr.GUI.skillbook.x = x; SkillMgr.GUI.skillbook.y = y; SkillMgr.GUI.skillbook.width = width; SkillMgr.GUI.skillbook.height = height;
			
			GUI_Capture(GUI:Checkbox("This Job Only",gSkillMgrFilterJob),"gSkillMgrFilterJob")
			GUI_Capture(GUI:Checkbox("Usable Only",gSkillMgrFilterUsable),"gSkillMgrFilterUsable")
			
			SkillMgr.FillSkillBook()
			
			if (table.valid(SkillMgr.SkillBook)) then
				local types = {[1] = "Actions",[9] = "Crafting", [11] = "Pets"}
				for actiontype,actiondesc in spairs(types) do
					if (GUI:TreeNode(tostring(actiontype).." - "..tostring(actiondesc))) then
						--local actionlist = ActionList:Get(actiontype)
						local actionlist = SkillMgr.SkillBook[actiontype]
						if (table.valid(actionlist)) then
							for actionid, action in spairs(actionlist) do
								if ( GUI:Button(action.name.." ["..tostring(action.id).."]",width,20)) then
									SkillMgr.AddSkillToProfile(action)
								end
							end
						end
						GUI:TreePop()
					end
				end
			end
		end
		GUI:End()
	--end
end

function SkillMgr.DrawSkillEditor(prio)
	if (SkillMgr.GUI.editor.open) then	
		GUI:SetNextWindowPos(SkillMgr.GUI.manager.x + SkillMgr.GUI.manager.width,SkillMgr.GUI.manager.y,GUI.SetCond_Appearing)
		GUI:SetNextWindowSize(350,600,GUI.SetCond_FirstUseEver) --set the next window size, only on first ever
		SkillMgr.GUI.editor.visible, SkillMgr.GUI.editor.open = GUI:Begin(SkillMgr.GUI.editor.name, SkillMgr.GUI.editor.open)
		if ( SkillMgr.GUI.editor.visible ) then 
			local skill = SkillMgr.SkillProfile[SkillMgr.EditingSkill]
			if (table.valid(skill)) then
				
				GUI:Columns(2,"#table-main",false)
				GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,300);
				
				GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Name")); GUI:NextColumn(); GUI:Text(skill.name); GUI:NextColumn();
				GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Alias")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_ALIAS",SKM_ALIAS),"SKM_ALIAS"); GUI:NextColumn();
				GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("ID")); GUI:NextColumn(); GUI:Text(skill.id); GUI:NextColumn();
				GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Type")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TYPE",SKM_TYPE,0,0),"SKM_TYPE"); GUI:NextColumn();
				GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Used")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_ON",SKM_ON),"SKM_ON"); GUI:NextColumn();		
				
				GUI:Columns(1)
				
				-- Check which type of conditionals to show.
				local fighting, gathering, crafting = false, false, false
				local classes = {"GLD","PLD","PUG","MNK","MRD","WAR","LNC","DRG","ARC","BRD","CNJ","WHM","THM","BLM","ACN","SMN","SCH","ROG","NIN","DRK","MCH","AST","SAM","RDM","BLU","GNB","DNC",
					"MIN","BTN","FSH","CRP","BSM","ARM","GSM","LTW","WVR","ALC","CUL"}
				
				for i,abrev in pairsByKeys(classes) do
					if (_G["gSkillProfileValid"..abrev] == true) then
						if (i <= 27) then
							fighting = true
							break
						elseif (i >= 28 and i <= 30) then
							gathering = true
							break
						elseif (i >= 31 and i <= 38) then
							crafting = true
							break
						end
					end
				end
				
				if (fighting) then
					SkillMgr.DrawBattleEditor(skill)
				elseif (crafting) then
					SkillMgr.DrawCraftEditor(skill)
				elseif (gathering) then
					SkillMgr.DrawGatherEditor(skill)
				end				
			end
		end
		GUI:End()
	end
end

function SkillMgr.DrawMacroEditor()
	-- ========= Macro Window =============
	--[[
	
	GUI_NewWindow(SkillMgr.editwindow_macro.name, SkillMgr.editwindow_macro.x, SkillMgr.editwindow_macro.y, SkillMgr.editwindow_macro.w, SkillMgr.editwindow_macro.h,"",true)
	
	GUI_NewCheckbox(SkillMgr.editwindow_macro.name,"Expand Group 1","gSkillManagerFoldMacro1",GetString("generalSettings"))
	GUI_NewCheckbox(SkillMgr.editwindow_macro.name,"Expand Group 2","gSkillManagerFoldMacro2",GetString("generalSettings"))
	GUI_NewCheckbox(SkillMgr.editwindow_macro.name,"Expand Group 3","gSkillManagerFoldMacro3",GetString("generalSettings"))
	GUI_NewCheckbox(SkillMgr.editwindow_macro.name,"Expand Group 4","gSkillManagerFoldMacro4",GetString("generalSettings"))
	
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M1 Type","SKM_M1ACTIONTYPE","Macro Group 1","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M1 ID","SKM_M1ACTIONID","Macro Group 1")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M1 Target","SKM_M1ACTIONTARGET","Macro Group 1","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M1 Wait (ms)","SKM_M1ACTIONWAIT","Macro Group 1")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M1 Message","SKM_M1ACTIONMSG","Macro Group 1")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M1 Completion","SKM_M1ACTIONCOMPLETE","Macro Group 1")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M2 Type","SKM_M2ACTIONTYPE","Macro Group 1","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M2 ID","SKM_M2ACTIONID","Macro Group 1")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M2 Target","SKM_M2ACTIONTARGET","Macro Group 1","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M2 Wait (ms)","SKM_M2ACTIONWAIT","Macro Group 1")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M2 Message","SKM_M2ACTIONMSG","Macro Group 1")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M2 Completion","SKM_M2ACTIONCOMPLETE","Macro Group 1")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M3 Type","SKM_M3ACTIONTYPE","Macro Group 1","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M3 ID","SKM_M3ACTIONID","Macro Group 1")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M3 Target","SKM_M3ACTIONTARGET","Macro Group 1","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M3 Wait (ms)","SKM_M3ACTIONWAIT","Macro Group 1")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M3 Message","SKM_M3ACTIONMSG","Macro Group 1")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M3 Completion","SKM_M3ACTIONCOMPLETE","Macro Group 1")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M4 Type","SKM_M4ACTIONTYPE","Macro Group 1","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M4 ID","SKM_M4ACTIONID","Macro Group 1")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M4 Target","SKM_M4ACTIONTARGET","Macro Group 1","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M4 Wait (ms)","SKM_M4ACTIONWAIT","Macro Group 1")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M4 Message","SKM_M4ACTIONMSG","Macro Group 1")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M4 Completion","SKM_M4ACTIONCOMPLETE","Macro Group 1")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M5 Type","SKM_M5ACTIONTYPE","Macro Group 1","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M5 ID","SKM_M5ACTIONID","Macro Group 1")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M5 Target","SKM_M5ACTIONTARGET","Macro Group 1","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M5 Wait (ms)","SKM_M5ACTIONWAIT","Macro Group 1")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M5 Message","SKM_M5ACTIONMSG","Macro Group 1")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M5 Completion","SKM_M5ACTIONCOMPLETE","Macro Group 1")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M6 Type","SKM_M6ACTIONTYPE","Macro Group 2","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M6 ID","SKM_M6ACTIONID","Macro Group 2")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M6 Target","SKM_M6ACTIONTARGET","Macro Group 2","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M6 Wait (ms)","SKM_M6ACTIONWAIT","Macro Group 2")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M6 Message","SKM_M6ACTIONMSG","Macro Group 2")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M6 Completion","SKM_M6ACTIONCOMPLETE","Macro Group 2")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M7 Type","SKM_M7ACTIONTYPE","Macro Group 2","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M7 ID","SKM_M7ACTIONID","Macro Group 2")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M7 Target","SKM_M7ACTIONTARGET","Macro Group 2","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M7 Wait (ms)","SKM_M7ACTIONWAIT","Macro Group 2")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M7 Message","SKM_M7ACTIONMSG","Macro Group 2")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M7 Completion","SKM_M7ACTIONCOMPLETE","Macro Group 2")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M8 Type","SKM_M8ACTIONTYPE","Macro Group 2","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M8 ID","SKM_M8ACTIONID","Macro Group 2")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M8 Target","SKM_M8ACTIONTARGET","Macro Group 2","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M8 Wait (ms)","SKM_M8ACTIONWAIT","Macro Group 2")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M8 Message","SKM_M8ACTIONMSG","Macro Group 2")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M8 Completion","SKM_M8ACTIONCOMPLETE","Macro Group 2")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M9 Type","SKM_M9ACTIONTYPE","Macro Group 2","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M9 ID","SKM_M9ACTIONID","Macro Group 2")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M9 Target","SKM_M9ACTIONTARGET","Macro Group 2","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M9 Wait (ms)","SKM_M9ACTIONWAIT","Macro Group 2")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M9 Message","SKM_M9ACTIONMSG","Macro Group 2")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M9 Completion","SKM_M9ACTIONCOMPLETE","Macro Group 2")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M10 Type","SKM_M10ACTIONTYPE","Macro Group 2","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M10 ID","SKM_M10ACTIONID","Macro Group 2")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M10 Target","SKM_M10ACTIONTARGET","Macro Group 2","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M10 Wait (ms)","SKM_M10ACTIONWAIT","Macro Group 2")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M10 Message","SKM_M10ACTIONMSG","Macro Group 2")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M10 Completion","SKM_M10ACTIONCOMPLETE","Macro Group 2")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M11 Type","SKM_M11ACTIONTYPE","Macro Group 3","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M11 ID","SKM_M11ACTIONID","Macro Group 3")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M11 Target","SKM_M11ACTIONTARGET","Macro Group 3","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M11 Wait (ms)","SKM_M11ACTIONWAIT","Macro Group 3")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M11 Message","SKM_M11ACTIONMSG","Macro Group 3")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M11 Completion","SKM_M11ACTIONCOMPLETE","Macro Group 3")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M12 Type","SKM_M12ACTIONTYPE","Macro Group 3","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M12 ID","SKM_M12ACTIONID","Macro Group 3")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M12 Target","SKM_M12ACTIONTARGET","Macro Group 3","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M12 Wait (ms)","SKM_M12ACTIONWAIT","Macro Group 3")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M12 Message","SKM_M12ACTIONMSG","Macro Group 3")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M12 Completion","SKM_M12ACTIONCOMPLETE","Macro Group 3")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M13 Type","SKM_M13ACTIONTYPE","Macro Group 3","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M13 ID","SKM_M13ACTIONID","Macro Group 3")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M13 Target","SKM_M13ACTIONTARGET","Macro Group 3","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M13 Wait (ms)","SKM_M13ACTIONWAIT","Macro Group 3")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M13 Message","SKM_M13ACTIONMSG","Macro Group 3")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M13 Completion","SKM_M13ACTIONCOMPLETE","Macro Group 3")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M14 Type","SKM_M14ACTIONTYPE","Macro Group 3","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M14 ID","SKM_M14ACTIONID","Macro Group 3")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M14 Target","SKM_M14ACTIONTARGET","Macro Group 3","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M14 Wait (ms)","SKM_M14ACTIONWAIT","Macro Group 3")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M14 Message","SKM_M14ACTIONMSG","Macro Group 3")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M14 Completion","SKM_M14ACTIONCOMPLETE","Macro Group 3")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M15 Type","SKM_M15ACTIONTYPE","Macro Group 3","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M15 ID","SKM_M15ACTIONID","Macro Group 3")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M15 Target","SKM_M15ACTIONTARGET","Macro Group 3","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M15 Wait (ms)","SKM_M15ACTIONWAIT","Macro Group 3")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M15 Message","SKM_M15ACTIONMSG","Macro Group 3")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M15 Completion","SKM_M15ACTIONCOMPLETE","Macro Group 3")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M16 Type","SKM_M16ACTIONTYPE","Macro Group 4","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M16 ID","SKM_M16ACTIONID","Macro Group 4")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M16 Target","SKM_M16ACTIONTARGET","Macro Group 4","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M16 Wait (ms)","SKM_M16ACTIONWAIT","Macro Group 4")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M16 Message","SKM_M16ACTIONMSG","Macro Group 4")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M16 Completion","SKM_M16ACTIONCOMPLETE","Macro Group 4")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M17 Type","SKM_M17ACTIONTYPE","Macro Group 4","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M17 ID","SKM_M17ACTIONID","Macro Group 4")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M17 Target","SKM_M17ACTIONTARGET","Macro Group 4","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M17 Wait (ms)","SKM_M17ACTIONWAIT","Macro Group 4")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M17 Message","SKM_M17ACTIONMSG","Macro Group 4")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M17 Completion","SKM_M17ACTIONCOMPLETE","Macro Group 4")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M18 Type","SKM_M18ACTIONTYPE","Macro Group 4","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M18 ID","SKM_M18ACTIONID","Macro Group 4")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M18 Target","SKM_M18ACTIONTARGET","Macro Group 4","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M18 Wait (ms)","SKM_M18ACTIONWAIT","Macro Group 4")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M18 Message","SKM_M18ACTIONMSG","Macro Group 4")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M18 Completion","SKM_M18ACTIONCOMPLETE","Macro Group 4")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M19 Type","SKM_M19ACTIONTYPE","Macro Group 4","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M19 ID","SKM_M19ACTIONID","Macro Group 4")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M19 Target","SKM_M19ACTIONTARGET","Macro Group 4","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M19 Wait (ms)","SKM_M19ACTIONWAIT","Macro Group 4")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M19 Message","SKM_M19ACTIONMSG","Macro Group 4")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M19 Completion","SKM_M19ACTIONCOMPLETE","Macro Group 4")

	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M20 Type","SKM_M20ACTIONTYPE","Macro Group 4","Action,ActionWait,Item")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M20 ID","SKM_M20ACTIONID","Macro Group 4")
	GUI_NewComboBox(SkillMgr.editwindow_macro.name,"M20 Target","SKM_M20ACTIONTARGET","Macro Group 4","Target,Player,Ground Target,Ground Player")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M20 Wait (ms)","SKM_M20ACTIONWAIT","Macro Group 4")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M20 Message","SKM_M20ACTIONMSG","Macro Group 4")
	GUI_NewField(SkillMgr.editwindow_macro.name,"M20 Completion","SKM_M20ACTIONCOMPLETE","Macro Group 4")
	
	gSkillManagerFoldMacro1 = ffxivminion.GetSetting("gSkillManagerFoldMacro1","1")
	gSkillManagerFoldMacro2 = ffxivminion.GetSetting("gSkillManagerFoldMacro2","0")
	gSkillManagerFoldMacro3 = ffxivminion.GetSetting("gSkillManagerFoldMacro3","0")
	gSkillManagerFoldMacro4 = ffxivminion.GetSetting("gSkillManagerFoldMacro4","0")
	
	GUI_UnFoldGroup(SkillMgr.editwindow_macro.name,GetString("generalSettings"))
	SkillMgr.FoldMacroGroups()
	
	GUI_WindowVisible(SkillMgr.editwindow_macro.name,false)
	--]]
end

function SkillMgr.DrawLineItem(options)
    local control = options.control
    local name = options.name
    local var = options.variable
    local indexvar = options.indexvar
    local tablevar = options.tablevar
    local width = options.width
    local tooltip = IsNull(options.tooltip,"")
    
    local width = IsNull(width,0)
    GUI:AlignFirstTextHeightToWidgets()
    GUI:Text(GetString(name)); GUI:SameLine(); GUI:InvisibleButton("##"..tostring(var),5,20);
    GUI:NextColumn();
    
    if (width ~= 0) then
        GUI:PushItemWidth(width)
    end

    if (control == "combobox") then
        SKM_Combo("##"..var,indexvar,var,tablevar)
    elseif (control == "float") then
        SkillMgr.CaptureElement(GUI:InputFloat("##"..var,_G[var],0,0,precision),var)
    elseif (control == "int") then
        SkillMgr.CaptureElement(GUI:InputInt("##"..var,_G[var],0,0),var)
    elseif (control == "text") then
        SkillMgr.CaptureElement(GUI:InputText("##"..var,_G[var]),var)
    elseif (control == "checkbox") then
        
    end
    
    if (width ~= 0) then
        GUI:PopItemWidth()
    end
    
    if (tooltip ~= "") then
        if (GUI:IsItemHovered()) then
            GUI:SetTooltip(tooltip)
        end
    end
    
    GUI:NextColumn();
end

function SkillMgr.DrawBattleEditor()
	
	if (GUI:CollapsingHeader("Basic","battle-basic-header")) then
		GUI:Columns(2,"#battle-basic-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Combat Status")); GUI:NextColumn(); SKM_Combo("##SKM_Combat","gSMBattleStatusIndex","SKM_Combat",gSMBattleStatuses); GUI:NextColumn();
		--SkillMgr.DrawLineItem{control = "combobox", name = "Combat Status", variable = "SKM_Combat", indexvar = "gSMBattleStatusIndex", tablevar = gSMBattleStatuses, width = 200}
		
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("skmCHARGE")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("When selected, this skill will be considered a 'gap closer', like Shoulder Tackle or Plunge.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_CHARGE",SKM_CHARGE),"SKM_CHARGE"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("appliesBuff")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Check this box if the skill applies a Buff or Debuff.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_DOBUFF",SKM_DOBUFF),"SKM_DOBUFF"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("removesBuff")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Check this box if the skill removes a Buff.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_REMOVESBUFF",SKM_REMOVESBUFF),"SKM_REMOVESBUFF"); GUI:NextColumn();
		
		GUI:AlignFirstTextHeightToWidgets(); SkillMgr.DrawLineItem{control = "int", name = "skmLevelMin", variable = "SKM_LevelMin", width = 50, tooltip = "Use this skill when the character is at or above a certain level (Set to 0 to ignore)."}
		GUI:AlignFirstTextHeightToWidgets(); SkillMgr.DrawLineItem{control = "int", name = "skmLevelMax", variable = "SKM_LevelMax", width = 50, tooltip = "Use this skill when the character is at or below a certain level (Set to 0 to ignore)."}
		GUI:AlignFirstTextHeightToWidgets(); SkillMgr.DrawLineItem{control = "int", name = "minRange", variable = "SKM_MinR", width = 50, tooltip = "Minimum range the skill can be used (For most skills, this will stay at 0)."}
		GUI:AlignFirstTextHeightToWidgets(); SkillMgr.DrawLineItem{control = "int", name = "maxRange", variable = "SKM_MaxR", width = 50, tooltip = "Maximum range the skill can be used."}
		
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("prevComboSkill")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("If this skill is part of a combo, enter the ID of the skill that should be executed immediately before this one.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_PCSkillID",SKM_PCSkillID),"SKM_PCSkillID"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("prevComboSkillNot")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("If this skill is part of a combo, enter the ID of the skill that should NOT be executed immediately before this one.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_NPCSkillID",SKM_NPCSkillID),"SKM_NPCSkillID"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Previous GCD Skill")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("If this skill should be used immediately after another skill on the GCD, put the ID of that skill here.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_PGSkillID",SKM_PGSkillID),"SKM_PGSkillID"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Previous GCD Skill NOT")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("If this skill should NOT be used immediately after another skill on the GCD, put the ID of that skill here.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_NPGSkillID",SKM_NPGSkillID),"SKM_NPGSkillID"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Previous Skill")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("If this skill should be used immediately after another skill that is not on the GCD, put the ID of that skill here.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_PSkillID",SKM_PSkillID),"SKM_PSkillID"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Previous Skill NOT")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("If this skill should NOT be used immediately after another skill that is not on the GCD, put the ID of that skill here.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_NPSkillID",SKM_NPSkillID),"SKM_NPSkillID"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Current Action NOT")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("If this skill should NOT be used while the character is in a particular animation, put the ID of that animation here.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_NCURRENTACTION",SKM_NCURRENTACTION),"SKM_NCURRENTACTION"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("filter1")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Quick 'switches' used to adjust what skills can or can't be used.")) end GUI:NextColumn(); SKM_Combo("##SKM_FilterOne","gSMFilter1Index","SKM_FilterOne",gSMFilterStatuses); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("filter2")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Quick 'switches' used to adjust what skills can or can't be used.")) end GUI:NextColumn(); SKM_Combo("##SKM_FilterTwo","gSMFilter2Index","SKM_FilterTwo",gSMFilterStatuses); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("filter3")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Quick 'switches' used to adjust what skills can or can't be used.")) end GUI:NextColumn(); SKM_Combo("##SKM_FilterThree","gSMFilter3Index","SKM_FilterThree",gSMFilterStatuses); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("filter4")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Quick 'switches' used to adjust what skills can or can't be used.")) end GUI:NextColumn(); SKM_Combo("##SKM_FilterFour","gSMFilter4Index","SKM_FilterFour",gSMFilterStatuses); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("filter5")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Quick 'switches' used to adjust what skills can or can't be used.")) end GUI:NextColumn(); SKM_Combo("##SKM_FilterFive","gSMFilter5Index","SKM_FilterFive",gSMFilterStatuses); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("onlySolo")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("When checked, this skill will only be used when the character is solo or with only their chocobo.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_OnlySolo",SKM_OnlySolo),"SKM_OnlySolo"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("onlyParty")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("When checked, this skill will only be used when the character is in a Party.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_OnlyParty",SKM_OnlyParty),"SKM_OnlyParty"); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("When checked, this skill will only be used when the character is in a Party.")) end GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Party Size <=")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("When checked, this skill will only be used when the character is in a Party of less than or equal to this number of characters (Set to 0 to ignore).")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PartySizeLT",SKM_PartySizeLT,0,0),"SKM_PartySizeLT"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("secsSinceLastCast")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Set this to ensure that the skill is used at least this many seconds since the last time it was used on this mob.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputFloat("##SKM_SecsPassed",SKM_SecsPassed,0,0,3),"SKM_SecsPassed"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Secs Passed Unique")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Set this to ensure that the skill is used at least this many seconds since the last time it was used irrespective of mob.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputFloat("##SKM_SecsPassedUnique",SKM_SecsPassedUnique,0,0,3),"SKM_SecsPassedUnique"); GUI:NextColumn();
		
		GUI:Columns(1)
	end
	
	if (GUI:CollapsingHeader("Chain","battle-chain-header")) then
		GUI:Columns(2,"#battle-chain-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Chain Name")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("If this skill is part of a custom chain, enter that name here.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_CHAINNAME",SKM_CHAINNAME),"SKM_CHAINNAME"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Chain Start")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("When checked, this skill will be considered the first skill in the custom chain.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_CHAINSTART",SKM_CHAINSTART),"SKM_CHAINSTART"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Chain End")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("When checked, this skill will be considered the last skill in the custom chain.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_CHAINEND",SKM_CHAINEND),"SKM_CHAINEND"); GUI:NextColumn();
		
		GUI:Columns(1)
	end
	
	if (GUI:CollapsingHeader("Other Skill Checks","battle-otherskills-header")) then
		GUI:Columns(2,"#battle-otherskills-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Is Ready")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("The ID of any skill that should be available for use before this skill is used.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_SKREADY",SKM_SKREADY),"SKM_SKREADY"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("CD Ready")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString(" The ID of any skill off the global cooldown that should be ready before this skill is used.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_SKOFFCD",SKM_SKOFFCD),"SKM_SKOFFCD"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Is Not Ready")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString(" The ID of any skill that should NOT be ready before this skill is used.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_SKNREADY",SKM_SKNREADY),"SKM_SKNREADY"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("CD Not Ready")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("The ID of any skill off the global cooldown that should NOT be ready before this skill is used.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_SKNOFFCD",SKM_SKNOFFCD),"SKM_SKNOFFCD"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("CD Time >=")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("This is in reference to 'CD Not Ready' - Use this and the following skill to set advanced usage instructions, such as 'Use this skill when Skill 'X' has between 2 and 6 seconds left on cooldown'.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputFloat("##SKM_SKNCDTIMEMIN",SKM_SKNCDTIMEMIN,0,0,3),"SKM_SKNCDTIMEMIN"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("CD Time <=")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("This is in reference to 'CD Not Ready' - Use this and the preceeding skill to set advanced usage instructions, such as 'Use this skill when Skill 'X' has between 2 and 6 seconds left on cooldown'.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputFloat("##SKM_SKNCDTIMEMAX",SKM_SKNCDTIMEMAX,0,0,3),"SKM_SKNCDTIMEMAX"); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("What is this?")) end GUI:NextColumn();
		
		GUI:Columns(1)
	end
	
	if (GUI:CollapsingHeader(GetString("playerHPMPTP"),"battle-playerhp-header")) then
		GUI:Columns(2,"#battle-playerhp-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("playerHPGT",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when Player HP is greater than this percent.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PHPL",SKM_PHPL,0,0),"SKM_PHPL"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("playerHPLT",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when Player HP is less than this percent.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PHPB",SKM_PHPB,0,0),"SKM_PHPB"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("underAttack")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when Player is under attack from Ranged or Melee targets.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_PUnderAttack",SKM_PUnderAttack),"SKM_PUnderAttack"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("underAttackMelee")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when Player is under attack from Melee targets only.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_PUnderAttackMelee",SKM_PUnderAttackMelee),"SKM_PUnderAttackMelee"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("playerPowerGT",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when Player MP is more than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PPowL",SKM_PPowL,0,0),"SKM_PPowL"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("playerPowerLT",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when Player MP is less than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PPowB",SKM_PPowB,0,0),"SKM_PPowB"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("skmPMPPL",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when Player MP is greater than this percent.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PMPPL",SKM_PMPPL,0,0),"SKM_PMPPL"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("skmPMPPB",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("TUse this skill when Player MP is less than this percent.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PMPPB",SKM_PMPPB,0,0),"SKM_PMPPB"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Result MP >=")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when Player MP after casting the skill will be more than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PMPRGT",SKM_PMPRGT,0,0),"SKM_PMPRGT"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Result MP %% >=")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when Player MP after casting the skill will be more than this percent.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PMPPRGT",SKM_PMPPRGT,0,0),"SKM_PMPPRGT"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("Result MP >= Cost of [ID]")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when Player MP after casting the skill will be greater than or equal to the MP required to cast the spell whose ID is in this field.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_PMPRSGT",SKM_PMPRSGT),"SKM_PMPRSGT"); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("The ID of any skill that should be available for use before this skill is used.")) end GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("skmPTPL",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when Player TP is greater than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PTPL",SKM_PTPL,0,0),"SKM_PTPL"); GUI:NextColumn();
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("skmPTPB",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when Player TP is less than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PTPB",SKM_PTPB,0,0),"SKM_PTPB"); GUI:NextColumn();
		
		GUI:Columns(1)
	end
	
	if (GUI:CollapsingHeader(GetString("Party"),"battle-party-header")) then
		GUI:Columns(2,"#battle-party-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		
		GUI:PushItemWidth(100)
		GUI:Text(GetString("skmPTCount")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PTCount",SKM_PTCount,0,0),"SKM_PTCount"); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the number of party members is more or equal to this number.")) end GUI:NextColumn();
		GUI:Text(GetString("skmPTHPL",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when a party members' HP is greater than this percentage.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PTHPL",SKM_PTHPL,0,0),"SKM_PTHPL"); GUI:NextColumn();
		GUI:Text(GetString("skmPTHPB",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when a party members' HP is less than this percentage.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PTHPB",SKM_PTHPB,0,0),"SKM_PTHPB"); GUI:NextColumn();
		GUI:Text(GetString("skmPTMPL",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when a party members' MP is greater than this percentage.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PTMPL",SKM_PTMPL,0,0),"SKM_PTMPL"); GUI:NextColumn();
		GUI:Text(GetString("skmPTMPB",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when a party members' MP is less than this percentage.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PTMPB",SKM_PTMPB,0,0),"SKM_PTMPB"); GUI:NextColumn();
		GUI:Text(GetString("skmPTTPL",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when a party members' TP is greater than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PTTPL",SKM_PTTPL,0,0),"SKM_PTTPL"); GUI:NextColumn();
		GUI:Text(GetString("skmPTTPB",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when a party members' TP is less than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PTTPB",SKM_PTTPB,0,0),"SKM_PTTPB"); GUI:NextColumn();
		GUI:Text(GetString("skmHasBuffs")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill if a party member is being affected by buffs with the ID entered.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_PTBuff",SKM_PTBuff),"SKM_PTBuff"); GUI:NextColumn();
		GUI:Text(GetString("Known Debuffs")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("When selected, use this skill when being affected by a Minion-maintained list of debuffs (helpful for Esuna skills).")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_PTKBuff",SKM_PTKBuff),"SKM_PTKBuff"); GUI:NextColumn();
		GUI:Text(GetString("skmMissBuffs")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill if a party member is missing a buff with the ID entered.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_PTNBuff",SKM_PTNBuff),"SKM_PTNBuff"); GUI:NextColumn();
		GUI:Columns(1)
	end
	
	if (GUI:CollapsingHeader(GetString("Target"),"battle-target-header")) then
		GUI:Columns(2,"#battle-target-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		
		GUI:PushItemWidth(100)
		GUI:AlignFirstTextHeightToWidgets(); GUI:Text(GetString("skmTRG")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Select the target of the skill, including Ground Target, Tankable Enemy, etc.")) end GUI:NextColumn(); SKM_Combo("##SKM_TRG","gSMTarget","SKM_TRG",gSMTargets); GUI:NextColumn();
		GUI:Text(GetString("skmTRGTYPE")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Select the role of the character that this spell should be used on.")) end GUI:NextColumn(); SKM_Combo("##SKM_TRGTYPE","gSMTargetType","SKM_TRGTYPE",gSMTargetTypes); GUI:NextColumn();
		GUI:Text(GetString("Include Self")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("When checked, the skill will be used on yourself if you meet the conditions.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_TRGSELF",SKM_TRGSELF),"SKM_TRGSELF"); GUI:NextColumn();
		GUI:Text(GetString("skmNPC")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("When checked, the skill will be used on NPCs who meet the conditions.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_NPC",SKM_NPC),"SKM_NPC"); GUI:NextColumn();
		GUI:Text(GetString("skmPTRG")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Select the Target of the Player casting the spell- Enemy or Player.")) end GUI:NextColumn(); SKM_Combo("##SKM_PTRG","gSMPlayerTarget","SKM_PTRG",gSMPlayerTargets); GUI:NextColumn();
		GUI:Text(GetString("skmPGTRG")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Select how 'accurate' the Ground Target effect should be- directly on the target, behind it, or near it.")) end GUI:NextColumn(); SKM_Combo("##SKM_PGTRG","gSMPlayerGroundTargetPosition","SKM_PGTRG",gSMPlayerGroundTargetPositions); GUI:NextColumn();
		GUI:Text(GetString("skmPPos")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("If the skill has a positional, select it here.")) end GUI:NextColumn(); SKM_Combo("##SKM_PPos","gSMPlayerPosition","SKM_PPos",gSMPlayerPositions); GUI:NextColumn();
		
		GUI:Text(GetString("targetHPGT",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the HP of the Target is greater than this percentage.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_THPL",SKM_THPL,0,0),"SKM_THPL"); GUI:NextColumn();
		GUI:Text(GetString("targetHPLT",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the HP of the Target is less than this percentage.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_THPB",SKM_THPB,0,0),"SKM_THPB"); GUI:NextColumn();
		GUI:Text(GetString("skmTHPCL",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the HP of the Target is greater than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_THPCL",SKM_THPCL,0,0),"SKM_THPCL"); GUI:NextColumn();
		GUI:Text(GetString("skmTHPCB",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the HP of the Target is less than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_THPCB",SKM_THPCB,0,0),"SKM_THPCB"); GUI:NextColumn();
		
		GUI:Text(GetString("hpAdvantage")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the difference of Max HP between you and an enemy is greater than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputFloat("##SKM_THPADV",SKM_THPADV,0,0,2),"SKM_THPADV"); GUI:NextColumn();
		GUI:Text(GetString("targetTPLE",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the TP of the Target is less than this amount.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TTPL",SKM_TTPL,0,0),"SKM_TTPL"); GUI:NextColumn();
		GUI:Text(GetString("targetMPLE",true)); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the TP of the Target is more than this amount.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TMPL",SKM_TMPL,0,0),"SKM_TMPL"); GUI:NextColumn();
		GUI:Text(GetString("skmTCONTIDS")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Target must have one of the listed contentids (comma-separated list).")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_TCONTIDS",SKM_TCONTIDS),"SKM_TCONTIDS"); GUI:NextColumn();
		GUI:Text(GetString("skmTNCONTIDS")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Target must NOT have one of the listed contentids (comma-separated list).")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_TNCONTIDS",SKM_TNCONTIDS),"SKM_TNCONTIDS"); GUI:NextColumn();

		GUI:Columns(1)
	end
	
	if (GUI:CollapsingHeader(GetString("Gauges"),"battle-gauges-header")) then
		GUI:Columns(2,"#battle-gauges-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		
		for i = 1,8 do
			GUI:Text(GetString("Gauge Indicator "..tostring(i))); GUI:NextColumn(); GUI:NextColumn();
			GUI:Text(GetString("Value <=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_GAUGE"..tostring(i).."LT",_G["SKM_GAUGE"..tostring(i).."LT"],0,0),"SKM_GAUGE"..tostring(i).."LT"); GUI:NextColumn();
			GUI:Text(GetString("Value >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_GAUGE"..tostring(i).."GT",_G["SKM_GAUGE"..tostring(i).."GT"],0,0),"SKM_GAUGE"..tostring(i).."GT"); GUI:NextColumn();
			GUI:Text(GetString("Value =")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_GAUGE"..tostring(i).."EQ",_G["SKM_GAUGE"..tostring(i).."EQ"],0,0),"SKM_GAUGE"..tostring(i).."EQ"); GUI:NextColumn();
			GUI:Text(GetString("Value In")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_GAUGE"..tostring(i).."OR",_G["SKM_GAUGE"..tostring(i).."OR"]),"SKM_GAUGE"..tostring(i).."OR"); 
			if (GUI:IsItemHovered()) then
				GUI:SetTooltip(GetString("Ex: [0,16,32,48] if the value needs to be 0 or 16 or 32 or 48 (do not include brackets)."))
			end
			GUI:NextColumn();	
		end
			
		GUI:Columns(1)
	end
	
	if (GUI:CollapsingHeader(GetString("casting"),"battle-casting-header")) then
		GUI:Columns(2,"#battle-casting-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		GUI:Text(GetString("skmTCASTID")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Target must be channelling one of the listed spell IDs (comma-separated list).")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_TCASTID",SKM_TCASTID),"SKM_TCASTID"); GUI:NextColumn();
		GUI:Text(GetString("skmTCASTTM")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Target must be casting the spell on me (self).")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_TCASTTM",SKM_TCASTTM),"SKM_TCASTTM"); GUI:NextColumn();
		GUI:Text(GetString("skmTCASTTIME")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Cast time left on the current spell must be greater than or equal to (>=) this time in seconds.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_TCASTTIME",SKM_TCASTTIME),"SKM_TCASTTIME"); GUI:NextColumn();		
		GUI:Columns(1)
	end
	
	if (GUI:CollapsingHeader(GetString("healPriority"),"battle-healPriority-header")) then
		GUI:Columns(2,"#battle-healPriority-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		
		GUI:PushItemWidth(100)
		GUI:Text(GetString("skmHPRIOHP")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("HP percentage (%) must be lesser or equal to (<=) this number for the spell to apply.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_HPRIOHP",SKM_HPRIOHP,0,0),"SKM_HPRIOHP"); GUI:NextColumn();		
		GUI:Text(GetString("skmHPRIO1")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Heals will target the applicable groups in this priority order. Possible values: Self, Tank, Party, Any.")) end GUI:NextColumn(); SKM_Combo("##SKM_HPRIO1","gSMHealPriority1","SKM_HPRIO1",gSMHealPriorities); GUI:NextColumn();
		GUI:Text(GetString("skmHPRIO2")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Heals will target the applicable groups in this priority order. Possible values: Self, Tank, Party, Any.")) end GUI:NextColumn(); SKM_Combo("##SKM_HPRIO2","gSMHealPriority2","SKM_HPRIO2",gSMHealPriorities); GUI:NextColumn();
		GUI:Text(GetString("skmHPRIO3")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Heals will target the applicable groups in this priority order. Possible values: Self, Tank, Party, Any.")) end GUI:NextColumn(); SKM_Combo("##SKM_HPRIO3","gSMHealPriority3","SKM_HPRIO3",gSMHealPriorities); GUI:NextColumn();
		GUI:Text(GetString("skmHPRIO4")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Heals will target the applicable groups in this priority order. Possible values: Self, Tank, Party, Any.")) end GUI:NextColumn(); SKM_Combo("##SKM_HPRIO4","gSMHealPriority4","SKM_HPRIO4",gSMHealPriorities); GUI:NextColumn();
		GUI:PopItemWidth()
		
		GUI:Columns(1)
	end
	
	if (GUI:CollapsingHeader(GetString("aoe"),"battle-aoe-header")) then
		GUI:Columns(2,"#battle-aoe-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		
		GUI:PushItemWidth(100)
		GUI:Text(GetString("enmityAOE")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Select this option if the skill is an Area-of-Effect skill that generates enmity.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_EnmityAOE",SKM_EnmityAOE),"SKM_EnmityAOE"); GUI:NextColumn();
		GUI:Text(GetString("frontalCone")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Select this option if the skill has a frontal cone effect.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_FrontalConeAOE",SKM_FrontalConeAOE),"SKM_FrontalConeAOE"); GUI:NextColumn();
		GUI:Text(GetString("tankedTargetsOnly")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Select this option if the skill should only be used on enemies being tanked.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_TankedOnly",SKM_TankedOnly),"SKM_TankedOnly"); GUI:NextColumn();
		GUI:Text(GetString("Average HP %% >=")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the average HP of the enemies is greater than or equal to this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TEHPAvgGT",SKM_TEHPAvgGT,0,0),"SKM_TEHPAvgGT"); GUI:NextColumn();
		GUI:Text(GetString("skmTECount")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the number of enemies is greater than or equal to this number.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TECount",SKM_TECount,0,0),"SKM_TECount"); GUI:NextColumn();
		GUI:Text(GetString("skmTECount2")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the number of enemies is less than or equal to this number.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TECount2",SKM_TECount2,0,0),"SKM_TECount2"); GUI:NextColumn();
		GUI:Text(GetString("skmTERange")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when enemies are within this range (150 = size of the minimap).")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TERange",SKM_TERange,0,0),"SKM_TERange"); GUI:NextColumn();
		GUI:Text(GetString("aoeCenter")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this dropdown to select where the AOE should be centered. Possible values: Target, Self.")) end GUI:NextColumn(); SKM_Combo("##SKM_TECenter","gSMAOECenter","SKM_TECenter",gSMAOECenters); GUI:NextColumn();
		GUI:Text(GetString("skmTELevel")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when there is a level difference between you and the target. Possible values: 2, 4, 6.")) end GUI:NextColumn(); SKM_Combo("##SKM_TELevel","gSMAOELevel","SKM_TELevel",gSMAOELevels); GUI:NextColumn();
		GUI:Text(GetString("skmTACount")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the number of allies near you is greater or equal to this number.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TACount",SKM_TACount,0,0),"SKM_TACount"); GUI:NextColumn();
		GUI:Text(GetString("skmTARange")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when allies are within this range (150 = size of the minimap).")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TARange",SKM_TARange,0,0),"SKM_TARange"); GUI:NextColumn();
		GUI:Text(GetString("alliesNearHPLT")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the HP of an ally is less than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TAHPL",SKM_TAHPL,0,0),"SKM_TAHPL"); GUI:NextColumn();
		GUI:PopItemWidth()
		
		GUI:Columns(1)
	end
	
	if (GUI:CollapsingHeader(GetString("playerBuffs"),"battle-playerbuffs-header")) then
		GUI:Columns(2,"#battle-playerbuffs-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		
		GUI:PushItemWidth(100)
		GUI:Text(GetString("skmHasBuffs")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the Player is being affected by a buff with the ID entered.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_PBuff",SKM_PBuff),"SKM_PBuff"); GUI:NextColumn();
		GUI:Text(GetString("skmAndBuffDura")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the duration remaining of one of the buffs above is greater than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PBuffDura",SKM_PBuffDura,0,0),"SKM_PBuffDura"); GUI:NextColumn();
		GUI:Text(GetString("skmMissBuffs")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the Player is not being affected by a buff with the ID entered.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_PNBuff",SKM_PNBuff),"SKM_PNBuff"); GUI:NextColumn();
		GUI:Text(GetString("skmOrBuffDura")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the duration remaining of one of the buffs above is less than or equal to this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PNBuffDura",SKM_PNBuffDura,0,0),"SKM_PNBuffDura"); GUI:NextColumn();
		GUI:PopItemWidth()
		
		GUI:Columns(1)
	end
	
	if (GUI:CollapsingHeader(GetString("targetBuffs"),"battle-targetbuffs-header")) then
		GUI:Columns(2,"#battle-targetbuffs-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		
		GUI:PushItemWidth(100)
		GUI:Text(GetString("skmTBuffOwner")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Select the entity who will have the buff for this condition. Possible values: Player, Any.")) end GUI:NextColumn(); SKM_Combo("##SKM_TBuffOwner","gSMBuffOwner","SKM_TBuffOwner",gSMBuffOwners); GUI:NextColumn();
		GUI:Text(GetString("skmHasBuffs")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the Target is being affected by a buff with the ID entered.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_TBuff",SKM_TBuff),"SKM_TBuff"); GUI:NextColumn();
		GUI:Text(GetString("skmAndBuffDura")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the duration remaining of one of the buffs above is greater than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TBuffDura",SKM_TBuffDura,0,0),"SKM_TBuffDura"); GUI:NextColumn();
		GUI:Text(GetString("skmTBuffOwner")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Select the entity who will be missing the buff for this condition. Possible values: Player, Any.")) end GUI:NextColumn(); SKM_Combo("##SKM_TNBuffOwner","gSMBuffOwnerN","SKM_TNBuffOwner",gSMBuffOwners); GUI:NextColumn();
		GUI:Text(GetString("skmMissBuffs")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the Target is not being affected by a buff with the ID entered.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_TNBuff",SKM_TNBuff),"SKM_TNBuff"); GUI:NextColumn();
		GUI:Text(GetString("skmOrBuffDura")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the duration remaining of one of the buffs above is less than or equal to this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TNBuffDura",SKM_TNBuffDura,0,0),"SKM_TNBuffDura"); GUI:NextColumn();	
		GUI:PopItemWidth()
		
		GUI:Columns(1)
	end
	
	if (GUI:CollapsingHeader(GetString("Pet Buffs"),"battle-petbuffs-header")) then
		GUI:Columns(2,"#battle-petbuffs-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		
		GUI:PushItemWidth(100)
		GUI:Text(GetString("skmHasBuffs")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when your pet is being affected by a buff with the ID entered.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_PetBuff",SKM_PetBuff),"SKM_PetBuff"); GUI:NextColumn();
		GUI:Text(GetString("skmAndBuffDura")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the duration remaining of one of the buffs above is greater than this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PetBuffDura",SKM_PetBuffDura,0,0),"SKM_PetBuffDura"); GUI:NextColumn();
		GUI:Text(GetString("skmMissBuffs")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when your pet is not being affected by a buff with the ID entered.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_PetNBuff",SKM_PetNBuff),"SKM_PetNBuff"); GUI:NextColumn();
		GUI:Text(GetString("skmOrBuffDura")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this skill when the duration remaining of one of the buffs above is less than or equal to this value.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PetNBuffDura",SKM_PetNBuffDura,0,0),"SKM_PetNBuffDura"); GUI:NextColumn();
		GUI:PopItemWidth()
		
		GUI:Columns(1)
	end
	
	if (GUI:CollapsingHeader(GetString("advancedSettings"),"battle-advanced-header")) then
		GUI:Columns(2,"#battle-advanced-main",false)
		GUI:SetColumnOffset(1,150); GUI:SetColumnOffset(2,450);
		
		GUI:PushItemWidth(100)
		GUI:Text(GetString("offGCDSkill")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Use this dropdown to tell FFXIVMinion explicitly if the skill is off the global cooldown.")) end GUI:NextColumn(); SKM_Combo("##SKM_OffGCD","gSMOffGCDSetting","SKM_OffGCD",gSMOffGCDSettings); GUI:NextColumn();
		GUI:Text(GetString("Off GCD Time >=")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Global cooldown time remaining must be greater or equal to this number in seconds.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputFloat("##SKM_OffGCDTime",SKM_OffGCDTime,0,0,2),"SKM_OffGCDTime"); GUI:NextColumn();	
		GUI:Text(GetString("Off GCD Time <=")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("Global cooldown time remaining must be lesser or equal to this number in seconds.")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputFloat("##SKM_OffGCDTimeLT",SKM_OffGCDTimeLT,0,0,2),"SKM_OffGCDTimeLT"); GUI:NextColumn();	
		GUI:Text(GetString("Ignore Moving")); if (GUI:IsItemHovered()) then GUI:SetTooltip(GetString("When checked, the skill will be used whether or not the character is moving. ")) end GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_IgnoreMoving",SKM_IgnoreMoving),"SKM_IgnoreMoving"); GUI:NextColumn();
		GUI:PopItemWidth()
		
		GUI:Columns(1)
	end
	
	--[[		
	GUI_NewButton(SkillMgr.editwindow.name,"Build Macro","SMToggleMacro","Macro")
	--]]
end

function SkillMgr.FillCraftVars()
	
end

function SkillMgr.DrawCraftEditor()
	
	if (GUI:CollapsingHeader("Crafting","crafting-header")) then
		GUI:Columns(2,"#craft-main",false)
		GUI:SetColumnOffset(1,155); GUI:SetColumnOffset(2,500);
		
		GUI:Text(GetString("Single Use")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_SingleUseCraft",SKM_SingleUseCraft),"SKM_SingleUseCraft"); GUI:NextColumn();
		GUI:Text(GetString("Consecutive Use")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_ConsecutiveUseCraft",SKM_ConsecutiveUseCraft),"SKM_ConsecutiveUseCraft"); GUI:NextColumn();
		GUI:Separator();
		GUI:Text(GetString("Player Level >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_CLevelMin",SKM_CLevelMin,0,0),"SKM_CLevelMin"); GUI:NextColumn();	
		GUI:Text(GetString("Player Level <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_CLevelMax",SKM_CLevelMax,0,0),"SKM_CLevelMax"); GUI:NextColumn();
		GUI:Separator();		
		GUI:Text(GetString("Step >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_STMIN",SKM_STMIN,0,0),"SKM_STMIN"); GUI:NextColumn();	
		GUI:Text(GetString("Step <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_STMAX",SKM_STMAX,0,0),"SKM_STMAX"); GUI:NextColumn();	
		GUI:Separator()
		GUI:Text(GetString("Condition")); GUI:NextColumn(); SKM_Combo("##SKM_CONDITION","gSMCraftConditionIndex","SKM_CONDITION",gSMCraftConditions); GUI:NextColumn();
		GUI:Text(GetString("Has Buff")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_CPBuff",SKM_CPBuff),"SKM_CPBuff"); GUI:NextColumn();	
		GUI:Text(GetString("Missing Buff")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_CPNBuff",SKM_CPNBuff),"SKM_CPNBuff"); GUI:NextColumn();	
		GUI:Separator();
		GUI:Text(GetString("CP >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_CPMIN",SKM_CPMIN,0,0),"SKM_CPMIN"); GUI:NextColumn();	
		GUI:Text(GetString("CP <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_CPMAX",SKM_CPMAX,0,0),"SKM_CPMAX"); GUI:NextColumn();	
		GUI:Separator();
		GUI:Text(GetString("Durability >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_DURMIN",SKM_DURMIN,0,0),"SKM_DURMIN"); GUI:NextColumn();	
		GUI:Text(GetString("Durability <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_DURMAX",SKM_DURMAX,0,0),"SKM_DURMAX"); GUI:NextColumn();
		GUI:Separator();
		GUI:Text(GetString("Max Durability >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_MAXDURMIN",SKM_MAXDURMIN,0,0),"SKM_MAXDURMIN"); GUI:NextColumn();	
		GUI:Text(GetString("Max Durability <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_MAXDURMAX",SKM_MAXDURMAX,0,0),"SKM_MAXDURMAX"); GUI:NextColumn();
		GUI:Separator();
		GUI:Text(GetString("Progress >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PROGMIN",SKM_PROGMIN,0,0),"SKM_PROGMIN"); GUI:NextColumn();	
		GUI:Text(GetString("Progress <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_PROGMAX",SKM_PROGMAX,0,0),"SKM_PROGMAX"); GUI:NextColumn();
		GUI:Separator();
		GUI:Text(GetString("Max Progress >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_MAXPROGMIN",SKM_MAXPROGMIN,0,0),"SKM_MAXPROGMIN"); GUI:NextColumn();	
		GUI:Text(GetString("Max Progress <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_MAXPROGMAX",SKM_MAXPROGMAX,0,0),"SKM_MAXPROGMAX"); GUI:NextColumn();
		GUI:Separator();
		GUI:Text(GetString("Quality >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_QUALMIN",SKM_QUALMIN,0,0),"SKM_QUALMIN"); GUI:NextColumn();	
		GUI:Text(GetString("Quality <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_QUALMAX",SKM_QUALMAX,0,0),"SKM_QUALMAX"); GUI:NextColumn();
		GUI:Separator();
		GUI:Text(GetString("Quality %% >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_QUALMINPer",SKM_QUALMINPer,0,0),"SKM_QUALMINPer"); GUI:NextColumn();	
		GUI:Text(GetString("Quality %% <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_QUALMAXPer",SKM_QUALMAXPer,0,0),"SKM_QUALMAXPer"); GUI:NextColumn();
		GUI:Separator();
		GUI:Text(GetString("Craftsmanship >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_CRAFTMIN",SKM_CRAFTMIN,0,0),"SKM_CRAFTMIN"); GUI:NextColumn();	
		GUI:Text(GetString("Craftsmanship <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_CRAFTMAX",SKM_CRAFTMAX,0,0),"SKM_CRAFTMAX"); GUI:NextColumn();
		GUI:Separator();
		GUI:Text(GetString("Control >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_CONTROLMIN",SKM_CONTROLMIN,0,0),"SKM_CONTROLMIN"); GUI:NextColumn();	
		GUI:Text(GetString("Control <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_CONTROLMAX",SKM_CONTROLMAX,0,0),"SKM_CONTROLMAX"); GUI:NextColumn();
		GUI:Separator();
		GUI:Text(GetString("ToT Used >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TOTMIN",SKM_TOTMIN,0,0),"SKM_TOTMIN"); GUI:NextColumn();	
		GUI:Text(GetString("ToT Used <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_TOTMAX",SKM_TOTMAX,0,0),"SKM_TOTMAX"); GUI:NextColumn();
		GUI:Separator();
		GUI:Text(GetString("Hasty Touch Successes >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_HTSUCCEED",SKM_HTSUCCEED,0,0),"SKM_HTSUCCEED"); GUI:NextColumn();	
		GUI:Text(GetString("Manipulation Uses <=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_MANIPMAX",SKM_MANIPMAX,0,0),"SKM_MANIPMAX"); GUI:NextColumn();
		GUI:Text(GetString("IQ Stack >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_IQSTACK",SKM_IQSTACK,0,0),"SKM_IQSTACK"); GUI:NextColumn();	
		GUI:Text(GetString("IQ Stack <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_IQSTACKMAX",SKM_IQSTACKMAX,0,0),"SKM_IQSTACKMAX"); GUI:NextColumn();	
		GUI:Text(GetString("Great Strides Stack >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_GSSTACKMIN",SKM_GSSTACKMIN,0,0),"SKM_GSSTACKMIN"); GUI:NextColumn();
		GUI:Text(GetString("Waste Not Stack >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_WNSTACKMIN",SKM_WNSTACKMIN,0,0),"SKM_WNSTACKMIN"); GUI:NextColumn();
		GUI:Text(GetString("Waste Not 2 Stack >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_WN2STACKMIN",SKM_WN2STACKMIN,0,0),"SKM_WN2STACKMIN"); GUI:NextColumn();
		GUI:Text(GetString("Manipulation Stack >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_MANIPSTACKMIN",SKM_MANIPSTACKMIN,0,0),"SKM_MANIPSTACKMIN"); GUI:NextColumn();
		GUI:Text(GetString("Manipulation Stack <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_MANIPSTACKMAX",SKM_MANIPSTACKMAX,0,0),"SKM_MANIPSTACKMAX"); GUI:NextColumn();
		GUI:Text(GetString("Innovation Stack >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_INNOSTACKMIN",SKM_INNOSTACKMIN,0,0),"SKM_INNOSTACKMIN"); GUI:NextColumn();
		
		GUI:Columns(1)
	end
end

function SkillMgr.DrawGatherEditor()
	if (GUI:CollapsingHeader("Gathering","gathering-header")) then
		GUI:Columns(2,"#gathering-main",false)
		GUI:SetColumnOffset(1,180); GUI:SetColumnOffset(2,300);
		
		GUI:Text(GetString("Single Use")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_SingleUse",SKM_SingleUse),"SKM_SingleUse"); GUI:NextColumn();
		GUI:Text(GetString("Adds Buff")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_AddsBuff",SKM_AddsBuff),"SKM_AddsBuff"); GUI:NextColumn();	
		GUI:Text(GetString("Add Chain Mark")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_AddsMark",SKM_AddsMark),"SKM_AddsMark"); GUI:NextColumn();	
		GUI:Text(GetString("Require Chain Mark")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_RequiresMark",SKM_RequiresMark),"SKM_RequiresMark"); GUI:NextColumn();		
		GUI:Text(GetString("Unspoiled Node")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_UNSP",SKM_UNSP),"SKM_UNSP"); GUI:NextColumn();	
		GUI:Text(GetString("Ephemeral Node")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_EPHE",SKM_EPHE),"SKM_EPHE"); GUI:NextColumn();	
		GUI:Text(GetString("Legendary Node")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_LGND",SKM_LGND),"SKM_LGND"); GUI:NextColumn();	
		GUI:Text(GetString("Concealed Node")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_CNCLD",SKM_CNCLD),"SKM_CNCLD"); GUI:NextColumn();	
		GUI:Separator();
		GUI:Text(GetString("Gather Attempts Full")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:Checkbox("##SKM_GatherMax",SKM_GatherMax),"SKM_GatherMax"); GUI:NextColumn();
		GUI:Text(GetString("Gather Attempts >")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_GAttemptsMin",SKM_GAttemptsMin,0,0),"SKM_GAttemptsMin"); GUI:NextColumn();	
		GUI:Text(GetString("Gather Attempts <=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_GAttemptsMax",SKM_GAttemptsMax,0,0),"SKM_GAttemptsMax"); GUI:NextColumn();
		GUI:Text(GetString("Max Gather Attempts >")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_GMaxAttemptsMin",SKM_GMaxAttemptsMin,0,0),"SKM_GMaxAttemptsMin"); GUI:NextColumn();	
		GUI:Text(GetString("Max Gather Attempts =")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_GMaxAttempts",SKM_GMaxAttempts,0,0),"SKM_GMaxAttempts"); GUI:NextColumn();
		GUI:Separator();		
		GUI:Text(GetString("GP Start >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_GPStart",SKM_GPStart,0,0),"SKM_GPStart"); GUI:NextColumn();
		GUI:Text(GetString("GP >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_GPMIN",SKM_GPMIN,0,0),"SKM_GPMIN"); GUI:NextColumn();	
		GUI:Text(GetString("GP <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_GPMAX",SKM_GPMAX,0,0),"SKM_GPMAX"); GUI:NextColumn();	
		GUI:Separator();
		GUI:Text(GetString("Quantity >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_QTY",SKM_QTY,0,0),"SKM_QTY"); GUI:NextColumn();
		GUI:Text(GetString("Has Item")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_HasItem",SKM_HasItem),"SKM_HasItem"); GUI:NextColumn();	
		GUI:Text(GetString("Is Item")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_IsItem",SKM_IsItem),"SKM_IsItem"); GUI:NextColumn();
		GUI:Separator();
		GUI:Text(GetString("Rarity <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_CollRarityLT",SKM_CollRarityLT,0,0),"SKM_CollRarityLT"); GUI:NextColumn();	
		GUI:Text(GetString("Rarity >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_CollRarityGT",SKM_CollRarityGT,0,0),"SKM_CollRarityGT"); GUI:NextColumn();	
		GUI:Text(GetString("Wear >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_CollWearGT",SKM_CollWearGT,0,0),"SKM_CollWearGT"); GUI:NextColumn();
		GUI:Text(GetString("Wear <")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_CollWearLT",SKM_CollWearLT,0,0),"SKM_CollWearLT"); GUI:NextColumn();
		GUI:Text(GetString("Wear =")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_CollWearEQ",SKM_CollWearEQ,0,0),"SKM_CollWearEQ"); GUI:NextColumn();
		GUI:Text(GetString("Chance <=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_ItemChanceMax",SKM_ItemChanceMax,0,0),"SKM_ItemChanceMax"); GUI:NextColumn();	
		GUI:Text(GetString("HQ Chance >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputInt("##SKM_ItemHQChanceMin",SKM_ItemHQChanceMin,0,0),"SKM_ItemHQChanceMin"); GUI:NextColumn();
		GUI:Separator();
		GUI:Text(GetString("Time Since Last Cast(s) >=")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputFloat("##SKM_GSecsPassed",SKM_GSecsPassed,0,0,2),"SKM_GSecsPassed"); GUI:NextColumn();
		GUI:Text(GetString("Has Buffs")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_GPBuff",SKM_GPBuff),"SKM_GPBuff"); GUI:NextColumn();	
		GUI:Text(GetString("Missing Buffs")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_GPNBuff",SKM_GPNBuff),"SKM_GPNBuff"); GUI:NextColumn();
		GUI:Text(GetString("Previous Skill ID")); GUI:NextColumn(); SkillMgr.CaptureElement(GUI:InputText("##SKM_PSkillIDG",SKM_PSkillIDG),"SKM_PSkillIDG"); GUI:NextColumn();
		GUI:Columns(1)
	end
end

function SkillMgr.DrawManager()
	if (SkillMgr.GUI.manager.open) then	
		GUI:SetNextWindowPosCenter(GUI.SetCond_Appearing)
		GUI:SetNextWindowSize(350,450,GUI.SetCond_FirstUseEver) --set the next window size, only on first ever
		SkillMgr.GUI.manager.visible, SkillMgr.GUI.manager.open = GUI:Begin(SkillMgr.GUI.manager.name, SkillMgr.GUI.manager.open)
		if ( SkillMgr.GUI.manager.visible ) then 
		
			local x, y = GUI:GetWindowPos()
			local width, height = GUI:GetWindowSize()
			local contentwidth = GUI:GetContentRegionAvailWidth()
			
			SkillMgr.GUI.manager.x = x; SkillMgr.GUI.manager.y = y; SkillMgr.GUI.manager.width = width; SkillMgr.GUI.manager.height = height;
			
			GUI_DrawTabs(SkillMgr.GUI.manager.main_tabs)
			local tabs = SkillMgr.GUI.manager.main_tabs
			if (tabs.tabs[1].isselected) then
				SkillMgr.DrawSkillBook()
				
				GUI:PushItemWidth(50)
				local val,changed = GUI:InputInt(GetString("Profile Node Min GP"),IsNull(gSkillManagerMingp,0),0,0)
				if (gSkillManagerMingp ~= val) then
					gSkillManagerMingp = val
					SkillMgr.SaveProfile()
				end
				GUI:PopItemWidth()
								
				local val, changed = GUI:Checkbox(GetString("Gathering Single Use Exclude by prio. (New System)"),gSkillManagerPrioSystem)
				if (changed) then
					gSkillManagerPrioSystem = val
					SkillMgr.SaveProfile()
				end
				
				if (GUI:Button(GetString("Retranslate Profile"),200,25)) then
					local skills = SkillMgr.SkillProfile
					if (table.valid(skills)) then
						for prio,skilldata in pairs(skills) do
							if table.valid(skilldata) then
								for i,e in pairs(skilldata) do
									if type(e) == "string" and e ~= "" then
										--d("changing file data from "..tostring(e).." to ".. tostring(Retranslate(e)))
										skilldata[i] = Retranslate(e)
									end
								end
							end
						end
					end
					SkillMgr.SaveProfile()
				end
					
				if (GUI:CollapsingHeader("Valid Classes","classes-header")) then
					local fighters = {"GLD","PLD","PUG","MNK","MRD","WAR","LNC","DRG","ARC","BRD","CNJ","WHM","THM","BLM","ACN","SMN","SCH","ROG","NIN","DRK","MCH","AST","SAM","RDM","BLU","GNB","DNC"}
					local crafters = {"CRP","BSM","ARM","GSM","LTW","WVR","ALC","CUL"}
					local gatherers = {"MIN","BTN","FSH"}
					
					local count = 1
					for i,abrev in pairsByKeys(fighters) do
						SkillMgr.Capture(GUI:Checkbox(abrev,_G["gSkillProfileValid"..abrev]),"gSkillProfileValid"..abrev)
						GUI:SameLine(0,10)
						if (count % 4) == 0 and count ~= table.size(fighters) then GUI:NewLine() end
						count = count + 1
					end
					GUI:NewLine(2);
					GUI:Separator();
					GUI:Spacing(2)
					
					count = 1
					for i,abrev in pairsByKeys(crafters) do
						SkillMgr.Capture(GUI:Checkbox(abrev,_G["gSkillProfileValid"..abrev]),"gSkillProfileValid"..abrev)
						GUI:SameLine(0,10)
						if (count % 4) == 0 and count ~= table.size(crafters) then GUI:NewLine() end
						count = count + 1
					end
					GUI:NewLine(2);
					GUI:Separator();
					GUI:Spacing(); GUI:Spacing();
					
					for i,abrev in pairsByKeys(gatherers) do
						SkillMgr.Capture(GUI:Checkbox(abrev,_G["gSkillProfileValid"..abrev]),"gSkillProfileValid"..abrev)
						GUI:SameLine(0,10)
					end
					GUI:NewLine();
					GUI:Spacing(2)
				end
				if (GUI:CollapsingHeader("Extra Filters","filters-header")) then
					for i = 1, 5 do
						SkillMgr.Capture(GUI:InputText("Filter "..tostring(i),_G["gSkillManagerFilter"..tostring(i)]),"gSkillManagerFilter"..tostring(i))
					end
				end
				if (GUI:CollapsingHeader("Profile Skills","skills-header")) then
					local skills = SkillMgr.SkillProfile
					if (table.valid(skills)) then
						
						local doDelete = 0
						local doPriorityUp = 0
						local doPriorityDown = 0
						local doPriorityTop = 0
						local doPriorityBottom = 0
						
						for prio,skill in pairsByKeys(skills) do
							local alias = IsNull(skill.name,"No Name")
							if (IsNull(skill.alias,"") ~= "") then
								alias = skill.alias
							end							
							if ( GUI:Button(tostring(prio)..": "..alias.." ["..tostring(skill.id).."]",250,20)) then
								--if (SkillMgr.EditingSkill ~= prio) then
									local classCheck = false
									local classes = {"GLD","PLD","PUG","MNK","MRD","WAR","LNC","DRG","ARC","BRD","CNJ","WHM","THM","BLM","ACN","SMN","SCH","ROG","NIN","DRK","MCH","AST","SAM","RDM","BLU","GNB","DNC",
										"MIN","BTN","FSH","CRP","BSM","ARM","GSM","LTW","WVR","ALC","CUL"}
									
									for i,abrev in pairsByKeys(classes) do
										if (_G["gSkillProfileValid"..abrev] == true) then
											classCheck = true
										end
									end
									
									SkillMgr.EditingSkill = prio
									local requiredUpdate = false
									if (classCheck) then
										for varname,info in pairsByKeys(SkillMgr.Variables) do
											if (skill[info.profile] ~= nil) then
												if (info.cast == type(skill[info.profile])) then
													if (varname == "SKM_CONDITION") then
														--d("setting ["..tostring(varname).."] to ["..tostring(skill[info.profile]).."]")
													end
													_G[varname] = skill[info.profile]
												else
													_G[varname] = info.default
													skill[info.profile] = info.default
													requiredUpdate = true
												end
											end
										end
										if (requiredUpdate) then
											SkillMgr.WriteToFile(gSkillProfile)
										end
										SkillMgr.GUI.editor.open = true
									else
										ffxiv_dialog_manager.IssueNotice("Class Selection Required", "You must select at least one valid class before editing skills.")
									end
								--end
							end
							
							GUI:SameLine(0,5)
							
							GUI:PushStyleColor(GUI.Col_Button, 0, 0, 0, 0)
							GUI:PushStyleColor(GUI.Col_ButtonActive, 0, 0, 0, 0)
							if (GUI:ImageButton("##skillmgr-manage-prioup-"..tostring(prio),ml_global_information.path.."\\GUI\\UI_Textures\\w_up.png", 16, 16)) then	
								doPriorityUp = prio
							end
							if (GUI:IsItemHovered()) then
								if (GUI:IsMouseClicked(1)) then
									doPriorityTop = prio
								end
							end							
							GUI:SameLine(0,5)
							if (GUI:ImageButton("##skillmgr-manage-priodown-"..tostring(prio),ml_global_information.path.."\\GUI\\UI_Textures\\w_down.png", 16, 16)) then
								doPriorityDown = prio
							end
							if (GUI:IsItemHovered()) then
								if (GUI:IsMouseClicked(1)) then
									doPriorityBottom = prio
								end
							end	
							GUI:SameLine(0,5)
							if (GUI:ImageButton("##skillmgr-manage-delete-"..tostring(prio),ml_global_information.path.."\\GUI\\UI_Textures\\bt_alwaysfail_fail.png", 16, 16)) then
								doDelete = prio
							end
							
							GUI:PopStyleColor(2)
						end
					
					
						if (doPriorityUp ~= 0 and doPriorityUp ~= 1) then
							local currentPos = doPriorityUp
							local newPos = doPriorityUp - 1
							
							local temp = SkillMgr.SkillProfile[newPos]
							SkillMgr.SkillProfile[newPos] = SkillMgr.SkillProfile[currentPos]
							SkillMgr.SkillProfile[currentPos] = temp	
							
							SkillMgr.SaveProfile()
						end
						
						if (doPriorityTop ~= 0 and doPriorityTop ~= 1) then
							local currentPos = doPriorityTop
							local newPos = doPriorityTop
							
							while currentPos > 1 do
								local temp = SkillMgr.SkillProfile[newPos]
								SkillMgr.SkillProfile[newPos] = SkillMgr.SkillProfile[currentPos]
								SkillMgr.SkillProfile[currentPos] = temp	
								currentPos = newPos
								newPos = newPos - 1
							end
							
							SkillMgr.SaveProfile()
						end
						
						if (doPriorityDown ~= 0 and doPriorityDown < TableSize(SkillMgr.SkillProfile)) then
							local currentPos = doPriorityDown
							local newPos = doPriorityDown + 1
							
							local temp = SkillMgr.SkillProfile[newPos]
							SkillMgr.SkillProfile[newPos] = SkillMgr.SkillProfile[currentPos]
							SkillMgr.SkillProfile[currentPos] = temp
							
							SkillMgr.SaveProfile()
						end
						
						local profSize = TableSize(SkillMgr.SkillProfile)
						if (doPriorityBottom ~= 0 and doPriorityBottom < profSize) then
						
							local currentPos = doPriorityBottom
							local newPos = doPriorityBottom + 1
							
							while currentPos < profSize do
								local temp = SkillMgr.SkillProfile[newPos]
								SkillMgr.SkillProfile[newPos] = SkillMgr.SkillProfile[currentPos]
								SkillMgr.SkillProfile[currentPos] = temp	
								currentPos = newPos
								newPos = newPos + 1
							end
							
							SkillMgr.SaveProfile()
						end
						
						if (doDelete ~= 0) then
							SkillMgr.SkillProfile = TableRemoveSort(SkillMgr.SkillProfile,doDelete)
							for prio,skill in pairsByKeys(SkillMgr.SkillProfile) do
								if (skill.prio ~= prio) then
									SkillMgr.SkillProfile[prio].prio = prio
								end
							end
							SkillMgr.SaveProfile()
						end
					end
				end
			end			
			if (tabs.tabs[2].isselected) then
				GUI_Capture(GUI:InputText(GetString("name"),gSkillManagerNewProfile),"gSkillManagerNewProfile");
				if ( GUI:Button("Create Profile")) then
					SkillMgr.SkillProfile = {}
					SkillMgr.WriteToFile(gSkillManagerNewProfile)
					SkillMgr.UpdateProfiles()
					gSkillProfile = gSkillManagerNewProfile
					gSkillProfileIndex = GetKeyByValue(gSkillProfile,SkillMgr.profiles)
					local uuid = GetUUID()
					Settings.FFXIVMINION.gSMDefaultProfiles[uuid][Player.job] = gSkillProfile
					Settings.FFXIVMINION.gSMDefaultProfiles = Settings.FFXIVMINION.gSMDefaultProfiles
					SkillMgr.UseProfile(gSkillProfile)
					
					
					
					GUI_SwitchTab(tabs,1)
				end
			end
			if (tabs.tabs[3].isselected) then
				GUI_Capture(GUI:Checkbox(GetString("debugging"),gSkillManagerDebug),"gSkillManagerDebug");
				GUI_Capture(GUI:InputText(GetString("debugItems"),gSkillManagerDebugPriorities),"gSkillManagerDebugPriorities");
			end	
			
		end
		GUI:End()
	else
		if (SkillMgr.GUI.editor.open) then
			SkillMgr.GUI.editor.open = false
		end
	end
end

function SkillMgr.DrawSkillFilters()
	if (SkillMgr.GUI.filters.open) then	
		GUI:SetNextWindowPosCenter(GUI.SetCond_FirstUseEver)
		GUI:SetNextWindowSize(350,300,GUI.SetCond_FirstUseEver) --set the next window size, only on first ever
		SkillMgr.GUI.filters.visible, SkillMgr.GUI.filters.open = GUI:Begin(SkillMgr.GUI.filters.name, SkillMgr.GUI.filters.open)
		if ( SkillMgr.GUI.filters.visible ) then 
			GUI_Capture(GUI:Checkbox(gSkillManagerFilter1,gAssistFilter1),"gAssistFilter1");
			GUI_Capture(GUI:Checkbox(gSkillManagerFilter2,gAssistFilter2),"gAssistFilter2");
			GUI_Capture(GUI:Checkbox(gSkillManagerFilter3,gAssistFilter3),"gAssistFilter3");
			GUI_Capture(GUI:Checkbox(gSkillManagerFilter4,gAssistFilter4),"gAssistFilter4");
			GUI_Capture(GUI:Checkbox(gSkillManagerFilter5,gAssistFilter5),"gAssistFilter5");
		end
		GUI:End()
	end
end

function SkillMgr.Draw( event, ticks ) 
	local gamestate;
	if (GetGameState and GetGameState()) then
		gamestate = GetGameState()
	else
		gamestate = 3
	end
	
	-- Switch according to the gamestate
	if ( gamestate == FFXIV.GAMESTATE.INGAME ) then
		SkillMgr.DrawManager()
		SkillMgr.DrawSkillEditor()
		SkillMgr.DrawSkillFilters()
	end
end

RegisterEventHandler("Gameloop.Update",SkillMgr.OnGameUpdate,"SkillMgr.OnGameUpdate")
RegisterEventHandler("Module.Initalize",SkillMgr.ModuleInit,"SkillMgr.ModuleInit")
RegisterEventHandler("Gameloop.Draw", SkillMgr.Draw,"SkillMgr.Draw")
